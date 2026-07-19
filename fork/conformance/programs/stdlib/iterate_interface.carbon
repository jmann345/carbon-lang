// CONFORMANCE-BULLET: Stdlib: interfaces powering language syntax (operators, conversions)
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   4
//   3
//   2
//   1
//   10
//
// The Core.Iterate interface (core/prelude/iterate.carbon) powering
// range-based `for` syntax over a user type. Impl shape verbatim from
// core/prelude/range.carbon (class IntRange's `impl as Iterate where
// .CursorType = ... and .ElementType = ...`, cursor-advance-and-return-
// Optional Next) and toolchain/lower/testdata/for/bindings.carbon (a
// user-defined Core.Iterate impl driving `for` through lowering; `unused
// self`; Core.Optional Some/None). Factory shape from
// fork/conformance/programs/types/classes.carbon.

import Core library "io";

class Countdown {
  fn Make(start: i32) -> Countdown {
    return {.start = start};
  }

  impl as Core.Iterate where .CursorType = i32 and .ElementType = i32 {
    fn NewCursor(self) -> i32 {
      return self.start;
    }
    fn Next(unused self, cursor: i32*) -> Core.Optional(i32) {
      var value: i32 = *cursor;
      if (value > 0) {
        *cursor -= 1;
        return Core.Optional(i32).Some(value);
      } else {
        return Core.Optional(i32).None();
      }
    }
  }

  var start: i32;
}

fn Run() -> i32 {
  var total: i32 = 0;
  for (n: i32 in Countdown.Make(4)) {
    Core.Print(n);
    total += n;
  }
  Core.Print(total);
  return 0;
}
