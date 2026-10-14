// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: generic functions and types
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   25
//   10
//   42
//   1
//
// Documentation-sync program (fork/designdocs/plan.md D-DD-5): the code after
// this comment block is the P05 code block of docs/design/metaprogramming.md,
// section "Compile-time evaluation in the 0.1 toolchain", byte for byte
// (fork/designdocs/check_samples.py, rulebook R27). Expected output derived by
// hand in fork/designdocs/plan.md section 4 (R16(d)). Runs on this fork's
// toolchain and on the upstream nightly. A PASS shows that the documented
// sample runs as documented; the design-docs bullet itself is arbitrated by
// document review.

import Core library "io";

// An `eval fn` may be called during compilation, here for an array bound.
eval fn Square(n: i32) -> i32 { return n * n; }

var table: array(i32, Square(2)) = (1, 2, 3, 4);

// Compile-time evaluation can compute types, and may recurse.
eval fn IntOfWidth(wide: bool) -> type {
  if (wide) {
    return i64;
  }
  return i32;
}

eval fn Factorial(n: i32) -> i32 {
  if (n <= 1) {
    return 1;
  }
  return n * Factorial(n - 1);
}

var slots: array(i32, Factorial(3)) = (0, 0, 0, 0, 0, 6);

// A `musteval fn` may only be called with constant arguments.
musteval fn Twice(n: i32) -> i32 { return n * 2; }

fn Run() -> i32 {
  // An `eval fn` can also be called at run time.
  var n: i32 = 5;
  Core.Print(Square(n));
  Core.Print(table[3] + slots[5]);
  var big: IntOfWidth(true) = 1;
  big = big << 40;
  let small: IntOfWidth(false) = Twice(21);
  // `typeof` names the type of an expression.
  let copy: typeof(small) = small;
  Core.Print(copy);
  if (big > 1000) {
    Core.Print(1);
  }
  return 0;
}
