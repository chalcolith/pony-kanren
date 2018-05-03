
interface Goal[T]
  fun apply(s: State[T]): Iterator[State[T]]

primitive Goals
  fun fresh[T](v: Var, g: Goal[T]): Goal[T] =>
    {(s: State[T]): Iterator[State[T]] => g(s.fresh(v)) }

  fun unify_vars[T](a: Var, b: Var): Goal[T] =>
    {(s: State[T]): Iterator[State[T]] => s.unify_vars(a, b)}

  fun unify_vals[T](a: val->T, b: val->T): Goal[T] =>
    {(s: State[T]): Iterator[State[T]] => s.unify_vals(a, b)}

  fun unify_val[T](a: Var, t: val->T): Goal[T] =>
    {(s: State[T]): Iterator[State[T]] => s.unify_val(a, t)}
