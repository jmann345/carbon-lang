// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Stdlib: String and string-literal types
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   Cn
//   X
//   h
//
// `str` subscripts after ST-1 (fork/string/plan.md): `String as IndexWith(T)`
// for every `T: ImplicitAs(i64)` now takes its subscript as `i64`, so the
// subscript converts before the "string.at" builtin sees it. Two shapes this
// pins: an integer literal subscript on a runtime `str` (`s[0]`), which used
// to crash lowering ("GEP indexes must be integers"; string_basic.carbon's
// caution), and a `u8` subscript above 127, which used to reach the
// `getelementptr` as an 8-bit index that LLVM sign-extends, so `s[200 as u8]`
// read 56 bytes BEFORE the string. Expected lines: "Carbon"[0] and [5]; byte
// 200 of 25 copies of "abcdefgh" followed by "X" is the "X"; byte 199 is the
// last "h".

import Core library "io";

fn At(s: str, i: u8) -> char { return s[i]; }

fn Run() -> i32 {
  let s: str = "Carbon";
  Core.PrintChar(s[0]);
  Core.PrintChar(s[5]);
  Core.PrintChar('\n');

  var long: Core.StringBuf = Core.StringBuf.Make("");
  var k: i32 = 0;
  while (k < 25) {
    long += "abcdefgh";
    ++k;
  }
  long += "X";
  let i: u8 = 200;
  Core.PrintChar(At(long, i));
  Core.PrintChar('\n');
  let j: u8 = 199;
  Core.PrintChar(At(long, j));
  Core.PrintChar('\n');
  return 0;
}
