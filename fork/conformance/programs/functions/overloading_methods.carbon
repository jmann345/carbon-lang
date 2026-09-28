// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Functions: function overloading (Carbon-native)
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   105
//   210
//   6
//   0
//
// Overloaded method sets in a class body (resolution over the bound receiver,
// by parameter type and by arity) and a file-scope `alias` of a set, which
// names the whole set (fork decision F-009, fork/overload/plan.md D-OV-10).
// Syntax from working code: `fn F(self)` / `fn G(ref self)` and `{.total = 0}`
// (toolchain/check/testdata/class/method/method.carbon and the class init
// goldens), `alias` of a function (name_poisoning.carbon).
//
// EXPECT values, hand-derived:
//   105  `a.Add(5)` selects `Add(ref self, x: i32)` (0 + 5); `a.Add(true)`
//        selects `Add(ref self, flag: bool)` (+100).
//   210  `a.Get(2)` selects the two-parameter member: 105 * 2.
//   6    `Double(3)` resolves through the alias to `Twice(x: i32)`: 3 * 2.
//   0    `Double(false)` resolves to `Twice(b: bool)`.
// Runtime inputs go through `RuntimeSeed` so nothing constant-folds.

import Core library "io";

class Acc {
  var total: i32;
  fn Make() -> Acc { return {.total = 0}; }
  overload fn Add(ref self, x: i32) { self.total = self.total + x; }
  overload fn Add(ref self, flag: bool) {
    if (flag) { self.total = self.total + 100; }
  }
  overload fn Get(self) -> i32 { return self.total; }
  overload fn Get(self, scale: i32) -> i32 { return self.total * scale; }
}

overload fn Twice(x: i32) -> i32 { return x * 2; }
overload fn Twice(b: bool) -> i32 { if (b) { return 2; } return 0; }
alias Double = Twice;

fn RuntimeSeed(x: i32) -> i32 { return x + 20; }

fn Run() -> i32 {
  var a: Acc = Acc.Make();
  a.Add(RuntimeSeed(-15));
  a.Add(true);
  Core.Print(a.Get());
  Core.Print(a.Get(RuntimeSeed(-18)));
  Core.Print(Double(RuntimeSeed(-17)));
  Core.Print(Double(false));
  return 0;
}
