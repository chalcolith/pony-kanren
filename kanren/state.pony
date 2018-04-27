
use "collections/persistent"

type Index is USize

class Var
  var _n: USize

  new create() =>
    _n = 0

  fun ref _bind(n: USize) =>
    _n = n

type Binding[T] is (Index | T! | None)

type UnifyStruct[T] is {(a: T, b: T, s: State[T]): Iterator[State[T]]}

primitive UnifyIs[T]
  fun apply(a: T, b: T, s: State[T]): Iterator[State[T]] =>
    if a is b then
      [s].values()
    else
      [].values()
    end

class box State[T]
  let _bindings: MapIs[Index, Binding[T]]
  let _unify_struct: UnifyStruct[T]

  new create(unify_struct: UnifyStruct[T] = UnifyIs[T]) =>
    _bindings = MapIs[Index, Binding[T]].update(0, None)

  new _create(bindings: MapIs[Index, Binding[T]], us: UnifyStruct[T]) =>
    _bindings = bindings
    _unify_struct = us;

  fun apply(v: Var): (T! | None) =>
    var n = v._n
    while true do
      match _bindings.get_or_else(n, None)
      | None =>
        return None
      | let n': Index =>
        n = n'
      | let t': T =>
        return t'
      end
    end

  fun update(v: Var, value: (Index | T)): State[T]^ =>
    State[T]._create(_bindings(v) = value, _unify_struct)

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
            [this(vb) = ta].values() // bind b to the value already bound to a
          end
        else // a is not bound
          match this(vb)
          | let tb: T! => // if b is bound
            [this(va) = tb].values()
          else // b is not bound
            [this(va) = vb._n] // point a at b
          end
        end
      | let tb: T => // b is a value
        match this(va)
        | let ta: T! => // if a is bound
          _unify_struct(ta, tb, this) // return the structural unification
        else
          [this(va) = tb].values() // bind a to b
        end
      end
    | let ta: T => // if a is a value
      match b
      | let vb: Var => // if b is a variable
        match this(vb)
        | let tb: T! => // if b is bound
          _unify_struct(ta, tb, this)
        else // if b is not bound
          [this(vb) = ta] // bind b to a
        end
      | let tb: T => // if b is a value
        _unify_struct(ta, tb, this)
      end
    end
