// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Functions: function overloading (Carbon-native)
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   107
//   5
//
// An overloaded method set of a GENERIC class (fork decision F-009;
// docs/design/functions_overloading.md; fork/overload/plan.md OV-2 §5.B.3,
// the canonical migration shape of rev B B5). The set's type records the
// class's self specific, naming it through `Box(i32)` substitutes that
// specific, and the members resolve by first-match exactly as in a
// non-generic class; the generic parameter types only the inert `tag` field.
//
// EXPECT values, hand-derived from the member bodies (`Add(i32)` adds its
// argument; `Add(bool)` adds 100 when true; no `bool -> i32` implicit
// conversion, so `Add(true)` never selects the `i32` member):
//   107  Make(5): 5, then Add(2) -> 7, then Add(true) -> 107.
//   5    Make(5), then Add(false): the `bool` member is selected and adds
//        nothing.
// Runtime inputs go through `RuntimeSeed` so nothing constant-folds:
// RuntimeSeed(-15) = 5 and RuntimeSeed(-18) = 2. Spelling per R3: the class
// parameter is `T: Core.Copy`, as `Make` copies its `t: T` parameter into the
// `tag` field (toolchain/check/testdata/class/generic/member_type.carbon).

import Core library "io";

class Box(T: Core.Copy) {
  var tag: T;
  var total: i32;
  fn Make(x: i32, t: T) -> Box(T) { return {.tag = t, .total = x}; }
  overload fn Add(ref self, n: i32) { self.total = self.total + n; }
  overload fn Add(ref self, b: bool) {
    if (b) { self.total = self.total + 100; }
  }
  fn Get(self) -> i32 { return self.total; }
}

fn RuntimeSeed(x: i32) -> i32 { return x + 20; }

fn Run() -> i32 {
  var b: Box(i32) = Box(i32).Make(RuntimeSeed(-15), 0);
  b.Add(RuntimeSeed(-18));
  b.Add(true);
  Core.Print(b.Get());

  var c: Box(i32) = Box(i32).Make(RuntimeSeed(-15), 0);
  c.Add(false);
  Core.Print(c.Get());
  return 0;
}
