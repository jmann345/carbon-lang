// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Control flow: matching — if-let / let-else combined match+declaration
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   4
//   6
//   3
//   7
//
// while-let (W-012; fork decision F-011): the pattern condition is the loop
// condition — the initializer is re-evaluated and the pattern re-tested each
// iteration, with the binding rebound in the body — and `break` from the
// body exits the loop. The iteration counter would be 1 if the header ran
// once. Payload values go through RuntimeSeed(x) = x + 20 so the
// discriminant tests are real runtime compares, not constant folds.

import Core library "io";

choice OptInt {
  Some(x: i32),
  None
}

fn RuntimeSeed(x: i32) -> i32 { return x + 20; }

fn Next(n: i32) -> OptInt {
  if (n > 0) { return OptInt.Some(n - 1); }
  return OptInt.None;
}

fn Run() -> i32 {
  var cur: i32 = RuntimeSeed(-16);   // 4
  var total: i32 = 0;
  var iterations: i32 = 0;
  while (let .Some(m: i32) = Next(cur)) {   // m: 3, 2, 1, 0; then None
    cur = m; total = total + m; iterations = iterations + 1;
  }
  Core.Print(iterations);            // 4
  Core.Print(total);                 // 3+2+1+0 = 6
  var k: i32 = RuntimeSeed(-10);     // 10
  var stops: i32 = 0;
  while (let .Some(m: i32) = Next(k)) {     // m: 9, 8, 7 (break)
    k = m; stops = stops + 1;
    if (m == 7) { break; }
  }
  Core.Print(stops);                 // 3
  Core.Print(k);                     // 7
  return 0;
}
