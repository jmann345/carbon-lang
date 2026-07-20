// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Stdlib: fundamental types (bool, iN, fN)
// EXPECT-EXIT: 0
//
// Differential pair: arith_widths_diff.diff.cpp is the equivalent C++17
// program; the runner requires byte-identical exit code and stdout, making
// clang-compiled C++ the oracle for the printed values (no EXPECT-STDOUT
// here on purpose — the C++ side computes the expectation instead of this
// header asserting it). Exercises i32 arithmetic including C++-style
// truncating division/remainder on negative operands, i64 arithmetic
// narrowed with `as`, and u8/i16 width conversions. Syntax per
// stdlib/fundamental_types.carbon (in-range `as` conversions from
// core/prelude/types/int.carbon / uint.carbon); Core.Print lowers to
// printf("%d\n", x) (toolchain/lower/handle_call.cpp), mirrored exactly by
// the C++ side.

import Core library "io";

fn Run() -> i32 {
  let a: i32 = -7;
  let b: i32 = 2;
  Core.Print(a + b);
  Core.Print(a - b);
  Core.Print(a * b);
  // Division truncates toward zero; remainder keeps the dividend's sign
  // (same as C++).
  Core.Print(a / b);
  Core.Print(a % b);

  let big: i64 = 6000000000;
  let off: i64 = 5999999879;
  Core.Print((big - off) as i32);

  let byte: u8 = 200;
  Core.Print((byte as i32) * 3);

  let narrow: i16 = 300;
  Core.Print((narrow as i32) - 45);
  return 0;
}
