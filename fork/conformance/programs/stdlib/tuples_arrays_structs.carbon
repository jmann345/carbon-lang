// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Stdlib: tuple/array library parts
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   8
//   21
//   42
//
// Tuples (literals, element access, element assignment, tuple-typed
// parameters), fixed-size arrays (literal init, indexing via iteration), and
// structural struct types. Shapes verbatim from examples/advent2024/
// day15_common.carbon (`d: (i32, i32)` params, `.0`/`.1` access,
// `self.robot.0 += d.0`), toolchain/lower/testdata/array/iterate.carbon
// (`let a: array(i32, 6) = (1, 2, 3, 4, 5, 6);` + range-based for), and
// toolchain/lower/testdata/struct/member_access.carbon (struct locals).

import Core library "io";

fn SumTuple(t: (i32, i32)) -> i32 {
  return t.0 + t.1;
}

fn Run() -> i32 {
  var t: (i32, i32) = (3, 4);
  t.1 += 1;
  Core.Print(SumTuple(t));

  let a: array(i32, 6) = (1, 2, 3, 4, 5, 6);
  var total: i32 = 0;
  for (n: i32 in a) {
    total += n;
  }
  Core.Print(total);

  var s: {.x: i32, .y: i32} = {.x = 10, .y = 32};
  Core.Print(s.x + s.y);
  return 0;
}
