
use "itertools"

interface val Goal[T]
  """
  A goal represents a logical expression.  It is a functor that takes a state
  and returns a sequence of states that represents possible bindings for the
  variables in the goal.
  """
  fun apply(s: State[T]): Iterator[State[T]]

primitive Goals
  fun fresh[T](v: Var, g: Goal[T]): Goal[T] =>
    """
    Returns a goal that will register the given variable with the input
    state and then return the results of solving its subgoal `g`.

    You can register the same variable more than once if the scopes are
    disjoint.
    """
    {(s: State[T]): Iterator[State[T]] => g(s.fresh(v)) }

  fun unify_vars[T](a: Var, b: Var): Goal[T] =>
    """
    Returns a goal that attempts to unify two variables and returns a
    sequence of states that represents possible bindings in the expression.
    """
    {(s: State[T]): Iterator[State[T]] => s.unify_vars(a, b)}

  fun unify_vals[T](a: val->T, b: val->T): Goal[T] =>
    """
    Returns a goal that attempts to structurally unify two values, and returns
    a sequence of states that represents possible variable bindings in the
    expression.
    """
    {(s: State[T]): Iterator[State[T]] => s.unify_vals(a, b)}

  fun unify_val[T](a: Var, t: val->T): Goal[T] =>
    """
    Returns a goal that attempts to unify and bind a variable to a value, and
    returns a sequence of states that represents possible variable bindings in
    the expression.
    """
    {(s: State[T]): Iterator[State[T]] => s.unify_val(a, t)}

  fun fail[T](): Goal[T] =>
    """
    Returns a goal that enacts failure; i.e. it returns an empty sequence of
    states.
    """
    {(s: State[T]): Iterator[State[T]] => [].values()}

  fun conj[T](a: Goal[T], b: Goal[T]): Goal[T] =>
    """
    Returns a goal that for each solution for `a`, returns the solutions
    that result in solving `b` in that context.
    """
    {(s: State[T])(a, b): Iterator[State[T]] =>
      object
        let ia: Iterator[State[T]] = a(s)
        var ib: (Iterator[State[T]] | None) = None

        fun ref has_next(): Bool =>
          match ib
          | let ib': Iterator[State[T]] =>
            if ib'.has_next() then
              return true
            elseif not ia.has_next() then
              return false
            end
          end

          try
            let ib' = b(ia.next()?)
            ib = ib'
            ib'.has_next()
          else
            false
          end

        fun ref next(): State[T] ? =>
          match ib
          | let ib': Iterator[State[T]] =>
            if ib'.has_next() then
              return ib'.next()?
            elseif not ia.has_next() then
              error
            end
          end

          let ib' = b(ia.next()?)
          ib = ib'
          ib'.next()?
      end
    }

  fun disj[T](a: Goal[T], b: Goal[T]): Goal[T] =>
    """
    Returns a goal that interleaves solutions of `a` with solutions of `b`.
    """
    {(s: State[T])(a, b): Iterator[State[T]] =>
      object
        let iters: Array[Iterator[State[T]]] = [a(s); b(s)]
        var index: USize = 0

        fun ref has_next(): Bool =>
          try
            iters(0)?.has_next() or iters(1)?.has_next()
          else
            false
          end

        fun ref next(): State[T] ? =>
          if iters(index)?.has_next() then
            iters(index = 1 - index)?.next()?
          elseif iters(1 - index)?.has_next() then
            iters(1 - (index = 1 - index))?.next()?
          else
            error
          end
      end
    }
