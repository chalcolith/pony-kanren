
use "collections/persistent"

class val Var
  """
  Represents a variable in a logical expression.
  """
  let name: String

  new val create(name': String = "?") =>
    name = name'


type UnifyStruct[T] is {(val->T, val->T, State[T]): Iterator[State[T]]} val
"""
A functor that take two values and returns a sequence of states representing
possible unifications for them.  This is used to be able to unify custom
data types that may include variables in their fields.
"""

type _Index is USize
type _Vars is MapIs[Var, _Index]
type _Redirects is MapIs[_Index, _Index]
type _Bindings is MapIs[_Index, USize]
type _Values[T] is List[T]

class box State[T]
  """
  Represents the state of solving a particular expression.  It holds information
  about which variables are in use, which are bound to other variables, and
  which are bound to values.
  """
  let _vars: _Vars           // maps variables to indices
  let _redirects: _Redirects // variables that point to other variables
  let _bindings: _Bindings   // variables that point to values
  let _values: _Values[T]    // all the values we know about
  let _unify: UnifyStruct[T] // function to do structural unification
  let _errors: List[String]  // errors we have collected

  new create(unify: UnifyStruct[T]) =>
    _vars = _Vars
    _redirects = _Redirects
    _bindings = _Bindings
    _values = Lists[T].empty()
    _unify = unify
    _errors = Lists[String].empty()

  new _create(vars: _Vars, redirects: _Redirects, bindings: _Bindings,
    values: _Values[T], unify: UnifyStruct[T], errors: List[String])
  =>
    _vars = vars
    _redirects = redirects
    _bindings = bindings
    _values = values
    _unify = unify
    _errors = errors

  fun apply(v: Var): (val->T | None) =>
    """
    Queries the state for the value that this variable is (transitively) bound
    to.  A return value of `None` either means that the state does not know
    about the variable, or it is not bound.
    """
    try
      let index = _walk(_vars(v)?)
      _values(_values.size() - _bindings(index)?)?
    end

  fun exists(v: Var): Bool =>
    """
    Returns `true` if the state knows about the variable.
    """
    _vars.contains(v)

  fun is_bound(v: Var): Bool =>
    try
      let index = _walk(_vars(v)?)
      _bindings.contains(index)
    else
      false
    end

  fun has_error(): Bool =>
    """
    Returns `true` if the state has recorded an error.
    """
    _errors.size() > 0

  fun get_errors(): List[String] =>
    """
    Returns the list of errors that the state has recorded, newest first.
    """
    _errors

  fun fresh(v: Var): State[T]^ =>
    """
    Returns a new state that knows about the variable, unless the state has an
    error (in which case the state is unchanged), or the state already knows
    about the variable (in which case the new state will contain an error).
    """
    if has_error() then
      this
    elseif _vars.contains(v) then
      State[T]._create(_vars, _redirects, _bindings, _values, _unify,
        _errors.prepend("duplicate variable " + v.name))
    else
      let index = _vars.size() + 1
      let vars = _vars.update(v, index)
      State[T]._create(vars, _redirects, _bindings, _values, _unify, _errors)
    end

  fun unify_vars(a: Var, b: Var): Iterator[State[T]] =>
    """
    Attempts to unify the two variables, returning a sequence of states
    representing possible bindings for them.
    """
    if has_error() then
      [this].values()
    elseif not _vars.contains(a) then
      [State[T]._create(_vars, _redirects, _bindings, _values, _unify,
        _errors.prepend("unknown variable " + a.name))].values()
    elseif not _vars.contains(b) then
      [State[T]._create(_vars, _redirects, _bindings, _values, _unify,
        _errors.prepend("unknown variable " + b.name))].values()
    else
      match this(a)
      | let ta: val->T => // if a is bound
        match this(b)
        | let tb: val->T => // if b is bound
          _unify(consume ta, consume tb, this) // try to structurally unify
        else // b is not bound
          [_bind(b, consume ta)].values() // bind b to the value of a
        end
      else // a is not bound
        match this(b)
        | let tb: val->T => // if b is bound
          [_bind(a, consume tb)].values() // bind a to the value of b
        else // b is not bound
          [_redirect(a, b)].values() // unify variables
        end
      end
    end

  fun unify_vals(a: val->T, b: val->T): Iterator[State[T]] =>
    """
    Attempts to unify two values using the functor the state was given on
    initialization.  Returns a sequence of states representing possible
    bindings for any variables in the values.
    """
    if has_error() then
      [this].values()
    else
      _unify(consume a, consume b, this)
    end

  fun unify_val(a: Var, t: val->T): Iterator[State[T]] =>
    """
    Attempts to unify and bind a variable to a value.
    """
    if has_error() then
      [this].values()
    elseif not _vars.contains(a) then
      [State[T]._create(_vars, _redirects, _bindings, _values, _unify,
        _errors.prepend("unknown variable " + a.name))].values()
    else
      match this(a)
      | let ta: val->T => // if a is bound
        _unify(ta, consume t, this) // structurally unify
      else
        [_bind(a, t)].values()
      end
    end

  fun _walk(index: _Index): _Index =>
    var cur = index
    while true do
      match _redirects.get_or_else(cur, 0)
      | 0 =>
        break
      | let index': _Index =>
        cur = index'
      end
    end
    cur

  fun _redirect(from: Var, to: Var): State[T]^ =>
    try
      let ifrom = _walk(_vars(from)?)
      let ito = _walk(_vars(to)?)
      let redirects = _redirects.update(ifrom, ito)
      State[T]._create(_vars, redirects, _bindings, _values, _unify, _errors)
    else
      State[T]._create(_vars, _redirects, _bindings, _values, _unify,
        _errors.prepend("unknown error redirecting " + from.name + " to "
        + to.name))
    end

  fun _bind(v: Var, to: val->T): State[T]^ =>
    try
      let index = _walk(_vars(v)?)
      let valpos = _values.size() + 1
      let bindings = _bindings.update(index, valpos)
      let values = _values.prepend(to)
      State[T]._create(_vars, _redirects, bindings, values, _unify, _errors)
    else
      State[T]._create(_vars, _redirects, _bindings, _values, _unify,
        _errors.prepend("unknown error binding " + v.name))
    end


primitive UnifyIs[T]
  """
  A structural unifier for primitive values that compares them using object
  identity.
  """
  fun apply(a: T, b: T, s: State[T]): Iterator[State[T]] =>
    if a is b then
      [s].values()
    else
      [].values()
    end


primitive UnifyEq[T: Equatable[T] #read]
  """
  A structural unifier for primitive values that simply compares them using
  the equality operator.
  """

  fun apply(a: T, b: T, s: State[T]): Iterator[State[T]] =>
    if a == b then
      [s].values()
    else
      [].values()
    end
