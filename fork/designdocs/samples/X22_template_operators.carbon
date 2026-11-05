// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Templates in the 0.1 toolchain", quote
// EXPECT-STDOUT:
//   -4
//   17
//   14
//   1
//   3
// QUOTE: and the arithmetic, bitwise, comparison, and logical operators, including compound assignment, `++`, and `--`,
// Pins the page's sentence on the operators that are resolved per
// instantiation: every operand below is a member of a template-dependent
// value or has a template parameter's type. With `a` = 3 and `b` = 5:
// (8 x -2) / 2 = -8, -8 % 7 = -1, -1 + -3 = -4; (3 & 5) | (3 ^ 5) = 1 | 6 = 7,
// plus 3 << 2 = 12, 5 >> 1 = 2 and ^3 = -4, gives 17; !=, < and <= hold, 2 + 4
// + 8 = 14; true and not false, or false, gives 1; 4 + 3 - 1 = 6, x 4 = 24,
// / 2 = 12, % 5 = 2, then ++, -- and ++ give 3.

import Core library "io";

class Pair {
  var a: i32;
  var b: i32;
  var on: bool;
}

fn Arith[template T: type](p: T) -> i32 {
  return ((((p.a + p.b) * (p.a - p.b)) / 2) % 7) + (-p.a);
}

fn Bits[template T: type](p: T) -> i32 {
  return ((p.a & p.b) | (p.a ^ p.b)) + (p.a << 2) + (p.b >> 1) + (^p.a);
}

fn Compare[template T: type](p: T) -> i32 {
  var n: i32 = 0;
  if (p.a == p.b) { n += 1; }
  if (p.a != p.b) { n += 2; }
  if (p.a < p.b) { n += 4; }
  if (p.a <= p.b) { n += 8; }
  if (p.a > p.b) { n += 16; }
  if (p.a >= p.b) { n += 32; }
  return n;
}

fn Logic[template T: type](p: T) -> i32 {
  if ((p.on and not (p.a > p.b)) or false) { return 1; }
  return 0;
}

fn Compound[template T: type](x: T) -> T {
  var y: T = x;
  y += 3;
  y -= 1;
  y *= 4;
  y /= 2;
  y %= 5;
  ++y;
  --y;
  ++y;
  return y;
}

fn Run() -> i32 {
  let p: Pair = {.a = 3, .b = 5, .on = true};
  Core.Print(Arith(p));
  Core.Print(Bits(p));
  Core.Print(Compare(p));
  Core.Print(Logic(p));
  Core.Print(Compound(4 as i32));
  return 0;
}
