
use "ponytest"
use ".."

actor Main is TestList
  new create(env: Env) =>
    PonyTest(env, this)

  fun tag tests(test: PonyTest) =>
    test(_TestUnifyValSimpleEqual)
    test(_TestConjLateBindingSimpleEqual)
    test(_TestDisjLateBindingSimpleEqual)
    test(_TestFailSimpleEqual)


class iso _TestUnifyValSimpleEqual is UnitTest
  fun name(): String => "Unify_Val_Simple_Equal"

  fun apply(h: TestHelper) =>
    let expected: USize = 123

    // A = 123
    let a = Var("a")
    let g = Goals.fresh[USize](a, Goals.unify_val[USize](a, expected))

    let results = g(State[USize](UnifyEq[USize]))
    h.assert_true(results.has_next())
    try
      let s = results.next()?
      h.assert_false(s.has_error())
      match s(a)
      | let actual: USize =>
        h.assert_eq[USize](expected, actual)
      else
        h.fail()
      end
    else
      h.fail()
    end
    h.assert_false(results.has_next())


class iso _TestConjLateBindingSimpleEqual is UnitTest
  fun name(): String => "Conj_LateBinding_Simple_Equal"

  fun apply(h: TestHelper) =>
    let expected: USize = 123

    // A = B && B = 123
    // -> A = 123
    let a = Var("a")
    let b = Var("b")
    let g =
      Goals.fresh[USize](a,
        Goals.fresh[USize](b,
          Goals.conj[USize](
            Goals.unify_vars[USize](a, b),
            Goals.unify_val[USize](b, expected)
          )))

    let results = g(State[USize](UnifyEq[USize]))
    h.assert_true(results.has_next())
    try
      let s = results.next()?
      h.assert_false(s.has_error())
      match s(a)
      | let actual: USize =>
        h.assert_eq[USize](expected, actual)
      else
        h.fail()
      end
      match s(b)
      | let actual: USize =>
        h.assert_eq[USize](expected, actual)
      else
        h.fail()
      end
    else
      h.fail()
    end
    h.assert_false(results.has_next())


class iso _TestDisjLateBindingSimpleEqual is UnitTest
  fun name(): String => "Disj_LateBinding_Simple_Equal"

  fun apply(h: TestHelper) =>
    try
      let expected = [as USize: 123; 456]

      // A = B && (B = 123 || B = 456)
      // A = 123; A = 456
      let a = Var("A")
      let b = Var("B")
      let g =
        Goals.fresh[USize](a,
          Goals.fresh[USize](b,
            Goals.conj[USize](
              Goals.unify_vars[USize](b, a),
              Goals.disj[USize](
                Goals.unify_val[USize](b, expected(0)?),
                Goals.unify_val[USize](b, expected(1)?)
              ))))

      let results = g(State[USize](UnifyEq[USize]))
      for exp in expected.values() do
        h.assert_true(results.has_next())
        let s = results.next()?
        h.assert_false(s.has_error())
        match s(a)
        | let actual: USize =>
          h.assert_eq[USize](exp, actual)
        else
          h.fail()
        end
        match s(b)
        | let actual: USize =>
          h.assert_eq[USize](exp, actual)
        else
          h.fail()
        end
      end
      h.assert_false(results.has_next())
    else
      h.fail()
    end


class iso _TestFailSimpleEqual is UnitTest
  fun name(): String => "Fail_Simple_Equal"

  fun apply(h: TestHelper) =>
    let unexpected: USize = 123
    let a = Var("a")
    let g = Goals.fresh[USize](a,
      Goals.conj[USize](
        Goals.unify_val[USize](a, unexpected),
        Goals.fail[USize]()
      ))

    let results = g(State[USize](UnifyEq[USize]))
    h.assert_false(results.has_next())
