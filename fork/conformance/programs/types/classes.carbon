// CONFORMANCE-BULLET: Type system: User-defined types (classes)
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   4
//   2
//
// A class with fields, a static factory function, a mutating `ref self`
// method, and a read-only value-`self` method. Shapes verbatim from
// examples/sieve.carbon (methods on `var`), examples/advent2024/
// day15_common.carbon (`fn Signature(self) -> i32` on a class with no Copy
// impl), and toolchain/lower/testdata/class/base.carbon (returning a struct
// literal to initialize a class).

import Core library "io";

class Counter {
  fn Make() -> Counter {
    return {.count = 0, .step = 2};
  }

  fn Bump(ref self) {
    self.count += self.step;
  }

  fn Get(self) -> i32 {
    return self.count;
  }

  var count: i32;
  var step: i32;
}

fn Run() -> i32 {
  var c: Counter = Counter.Make();
  c.Bump();
  c.Bump();
  Core.Print(c.Get());
  Core.Print(c.step);
  return 0;
}
