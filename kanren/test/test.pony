
use "ponytest"
use ".."

actor Main is TestList
  new create(env: Env) =>
    PonyTest(env, this)

  fun tag tests(test: PonyTest) =>
    test(_TestUnifySimpleEqualRight)
    test(_TestUnifySimpleEqualLeft)


class iso _TestUnifySimpleEqualRight is UnitTest
  fun name(): String => "Unify_Simple_Equal_Right"

  fun apply(h: TestHelper) =>
    let a = Var
    let g = Goals[USize].unify(a, 123)
    let s = State[USize](UnifyEq[USize])
    let results = g(s)

    h.assert_true(results.has_next())
    let s' = results.next()
    match s'(a)
    | let n: USize =>
      h.assert_eq[USize](123, n)
    | None =>
      h.fail()
    end

class iso _TestUnifySimpleEqualLeft is UnitTest
  fun name(): String => "Unify_Simple_Equal_Left"

  fun apply(h: TestHelper) =>
    let a = Var
    let g = Goals[USize].unify(123, a)
    let s = State[USize](UnifyEq[USize])
    let results = g(s)

    h.assert_true(results.has_next())
    let s' = results.next()
    match s'(a)
    | let n: USize =>
      h.assert_eq[USize](123, n)
    | None =>
      h.fail()
    end
    h.assert_false(results.has_next())
