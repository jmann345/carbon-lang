// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Functions: function overloading (Carbon-native)
// EXPECT-EXIT: 0
//
// Differential pair (DIFF-1): overloading_default_values_diff.diff.cpp is the
// equivalent C++17 program with default arguments and overloads; the runner
// requires byte-identical exit code and stdout, so C++ is the oracle for the
// values. The calls are the ones where Carbon's first match
// (fork/overload/ov4-plan.md OV-4, D-OV-4) and C++'s best viable match select
// the same function: the defaulted member is the only viable one for an
// omitted argument, and `bool` arguments have an exact C++ match where Carbon
// has no `bool` to `i32` conversion. A call two members accept is not here:
// C++ rejects it as ambiguous (overloading_default_values.carbon pins
// Carbon's selection). The set is not exported, so rulebook R30 does not
// apply.

import Core library "io";

overload fn F(x: i32, y: i32 = 2) -> i32 { return x * 10 + y; }
overload fn F(b: bool) -> i32 {
  if (b) { return -1; }
  return -2;
}

class Counter {
  var start: i32;
  overload fn Plus(self, n: i32 = 1) -> i32 { return self.start + n; }
  overload fn Plus(self, b: bool) -> i32 {
    if (b) { return self.start * 2; }
    return 0;
  }
}

fn Seed(x: i32) -> i32 { return x + 20; }

fn Run() -> i32 {
  Core.Print(F(Seed(-19)));
  Core.Print(F(Seed(-19), Seed(-15)));
  Core.Print(F(true));
  Core.Print(F(false));
  let c: Counter = {.start = Seed(80)};
  Core.Print(c.Plus());
  Core.Print(c.Plus(Seed(-13)));
  Core.Print(c.Plus(true));
  return 0;
}
