// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Stdlib: Optional
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   2
//   0
//   1
//   0
//   2
//   1
//   2
//   2
//
// Comparing `Core.Optional(T)` values never moves or destroys the values they
// hold (fork design F-015, docs/design/optional.md): a comparison reads each
// held value through `Get()`, which returns a copy, and each copy is destroyed
// by the end of the comparison. `Tracked` counts its live copies through a
// pointer: its `Copy` adds one and its `Destroy` removes one. Expected, from
// F-015's rules: `Some` stores a copy of its argument, so two values are held
// (2); `Some(1) == Some(2)` is 0 and `Some(1) < Some(2)` is 1; comparing an
// empty value reads no storage (0); the comparisons left no copy alive, so the
// count is still 2; the held values are unchanged (1 and 2); and each `Get()`
// copy above died with its statement, so the count is 2 again. The held
// values are destroyed with their Optionals (W-170, landed at OP-2,
// arbitrated by optional_destroys_value.carbon), after the last count is
// printed, so no line here observes it.

import Core library "io";

class Tracked {
  var v: i32;
  var live: i32*;
  impl as Core.Copy {
    fn Op(self) -> Self {
      ++*self.live;
      return {.v = self.v, .live = self.live};
    }
  }
  impl as Core.Destroy {
    fn Op(ref self) {
      --*self.live;
    }
  }
}

impl Tracked as Core.EqWith(Tracked) {
  fn Equal(self, other: Tracked) -> bool { return self.v == other.v; }
  fn NotEqual(self, other: Tracked) -> bool { return self.v != other.v; }
}

impl Tracked as Core.OrderedWith(Tracked) {
  fn Less(self, other: Tracked) -> bool { return self.v < other.v; }
  fn LessOrEquivalent(self, other: Tracked) -> bool {
    return self.v <= other.v;
  }
  fn Greater(self, other: Tracked) -> bool { return self.v > other.v; }
  fn GreaterOrEquivalent(self, other: Tracked) -> bool {
    return self.v >= other.v;
  }
}

fn B(b: bool) -> i32 { return if b then 1 else 0; }

fn Run() -> i32 {
  var live: i32 = 0;
  var t1: Tracked = {.v = 1, .live = &live};
  var t2: Tracked = {.v = 2, .live = &live};
  var a: Core.Optional(Tracked) = Core.Optional(Tracked).Some(t1);
  var b: Core.Optional(Tracked) = Core.Optional(Tracked).Some(t2);
  var n: Core.Optional(Tracked) = Core.Optional(Tracked).None();
  Core.Print(live);
  Core.Print(B(a == b));
  Core.Print(B(a < b));
  Core.Print(B(n == a));
  Core.Print(live);
  Core.Print(a.Get().v);
  Core.Print(b.Get().v);
  Core.Print(live);
  return 0;
}
