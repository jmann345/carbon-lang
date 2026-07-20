// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Control flow: conditions
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   0
//   1
//
// if / else if / else statements, early return, and the `if ... then ... else`
// expression form. Shapes verbatim from examples/advent2024/day1_part1.carbon
// (`fn Abs(n: i32) -> i32 { return if n < 0 then -n else n; }`),
// day14_common.carbon (if-expression in a let), and sort.carbon
// (`if (...) { return; }` early return, else-if chains).

import Core library "io";

fn Classify(n: i32) -> i32 {
  if (n < 0) {
    return -1;
  } else if (n == 0) {
    return 0;
  }
  return 1;
}

fn Run() -> i32 {
  Core.Print(Classify(-5) + Classify(0) + Classify(7));
  // if-expression with i32-typed branches, as in day1_part1's Abs.
  let one: i32 = 1;
  let two: i32 = 2;
  let sign: i32 = if Classify(9) > 0 then one else two;
  Core.Print(sign);
  if (Classify(3) != 1) { return 1; }
  return 0;
}
