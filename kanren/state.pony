
use mut = "collections"
use "collections/persistent"

class tag Var

type UnifyStruct[T] is {(T, T, State[T]): Iterator[State[T]]} val

type RedirectMap is HashMap[Var,Var,mut.HashIs[Var]]
type BindingMap[T: Any #share] is HashMap[Var,T,mut.HashIs[Var]]

class box State[T: Any #share]
  let _redirects: RedirectMap
  let _bindings: BindingMap[T]
  let _unify_struct: UnifyStruct[T]

  new create(unify_struct: UnifyStruct[T]) =>
    _redirects = RedirectMap
    _bindings = BindingMap[T]
    _unify_struct = unify_struct

  new _create(redirects: RedirectMap, bindings: BindingMap[T],
    unify_struct: UnifyStruct[T])
  =>
    _redirects = redirects
    _bindings = bindings
    _unify_struct = unify_struct

  fun apply(v: Var): (T! | None) =>
    try
      var cur = v
      while _redirects.contains(cur) do
        cur = _redirects(cur)?
      end
      if _bindings.contains(cur) then
        _bindings(cur)?
      end
    end

  fun _redirect(from: Var, to: Var): State[T]^ =>
    State[T]._create(_redirects.update(from, to), _bindings, _unify_struct)

  fun _bind(v: Var, to: T): State[T]^ =>
    State[T]._create(_redirects, _bindings.update(v, to), _unify_struct)

  fun unify(a: (Var | T), b: (Var | T)): Iterator[State[T]] =>
    match a
    | let va: Var => // if a is a variable
      match b
      | let vb: Var => // and b is a variable
        match this(va)
        | let ta: T! => // and a is bound
          match this(vb)
          | let tb: T! => // and b is bound
            _unify_struct(ta, tb, this) // return the structural unification
          else // if b is not bound
            [_bind(vb, ta)].values() // bind b to the value already bound to a
          end
        else // a is not bound
          match this(vb)
          | let tb: T! => // if b is bound
            [_bind(va, tb)].values()
          else // b is not bound
            [_redirect(va, vb)] // point a at b
          end
        end
      | let tb: T => // b is a value
        match this(va)
        | let ta: T! => // if a is bound
          _unify_struct(ta, tb, this) // return the structural unification
        else
          [_bind(va, tb)].values() // bind a to b
        end
      end
    | let ta: T => // if a is a value
      match b
      | let vb: Var => // if b is a variable
        match this(vb)
        | let tb: T! => // if b is bound
          _unify_struct(ta, tb, this)
        else // if b is not bound
          [_bind(vb, ta)] // bind b to a
        end
      | let tb: T => // if b is a value
        _unify_struct(ta, tb, this)
      end
    end

primitive UnifyEq[T: Equatable[T]]
  fun apply(a: T, b: T, s: State[T]): Iterator[State[T]] =>
    if a == b then
      [s].values()
    else
      [].values()
    end
