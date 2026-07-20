// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Stdlib: pointer types
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   42
//   14
//
// Address-of, dereference, mutation through a pointer parameter, pointer to
// a class object with `->` member access and assignment. Shapes verbatim
// from toolchain/lower/testdata/pointer/basic.carbon (`fn G(p: i32*)`,
// `G(&n)`), toolchain/check/testdata/operators/overloaded/add.carbon
// (`*a += b`), examples/advent2024/day14_common.carbon (`&me.p`,
// `xy->0`), and toolchain/lower/testdata/class/virtual.carbon (method/member
// access through an object pointer with `->`).

import Core library "io";

fn AddOne(p: i32*) {
  *p += 1;
}

class Point {
  var x: i32;
  var y: i32;
}

fn Run() -> i32 {
  var n: i32 = 41;
  AddOne(&n);
  Core.Print(n);

  var pt: Point = {.x = 3, .y = 4};
  let pp: Point* = &pt;
  pp->x = 10;
  Core.Print(pp->x + pp->y);
  return 0;
}
