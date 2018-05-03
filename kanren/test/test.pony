
use "ponytest"
use ".."

actor Main is TestList
  new create(env: Env) =>
    PonyTest(env, this)

  fun tag tests(test: PonyTest) =>
    test(_TestUnifyValSimpleEqual)


class iso _TestUnifyValSimpleEqual is UnitTest
  fun name(): String => "Unify_Val_Simple_Equal"

  fun apply(h: TestHelper) =>
    let expected: USize = 123

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
      | None =>
        h.fail()
      end
    else
      h.fail()
    end
    h.assert_false(results.has_next())
