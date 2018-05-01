
interface Goal[T: Any #share]
  fun apply(s: State[T]): Iterator[State[T]]

primitive Goals[T: Any #share]
  fun fresh(v: Var, g: Goal[T]): Goal[T] =>
    {(s: State[T]): Iterator[State[T]] => g(s.fresh(v)) }

  fun unify(a: (Var | T), b: (Var | T)): Goal[T] =>
    {(s: State[T]): Iterator[State[T]] => s.unify(a, b)}
