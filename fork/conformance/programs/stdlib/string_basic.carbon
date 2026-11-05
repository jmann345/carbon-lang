// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Stdlib: String and string-literal types
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   Carbon
//   6
//   1
//   1
//
// Working slice of the String bullet: string literals have type `str`
// (Core.String, a non-owning {Char*, i64} — core/prelude/types/string.carbon),
// `.Size()` returns i64, `s[i]` returns `char` through the `String as
// IndexWith` impl ("string.at" builtin, toolchain/check/testdata/operators/
// overloaded/string_indexing.carbon), and `str` is Copy. Chars print one at a
// time with Core.PrintChar (inline putchar), the same loop as Core.PrintStr's
// body (core/io.impl.carbon), because PrintStr itself does not link here
// (README).
//
// The indexes below are `i64`-typed, as written before ST-1, when a bare
// literal subscript on a runtime `str` crashed lowering; since ST-1 the
// subscript converts to `i64` first (fork/string/plan.md D-ST-9,
// string_subscripts.carbon). Comparison, concatenation and the owning
// `Core.StringBuf` are exercised by string_missing_ops.carbon and the other
// string_* programs.

import Core library "io";

fn PrintString(s: str) {
  let n: i64 = s.Size() as i64;
  var i: i64 = 0;
  while (i < n) {
    Core.PrintChar(s[i]);
    ++i;
  }
  Core.PrintChar('\n');
}

fn Run() -> i32 {
  let s: str = "Carbon";
  PrintString(s);
  Core.Print(s.Size() as i32);

  // Indexing yields `char`, which supports `==` against char literals.
  Core.Print(if s[0 as i64] == 'C' and s[5 as i64] == 'n' then 1 else 0);

  // `str` is Copy: the copy sees the same size and contents.
  var t: str = s;
  Core.Print(if t.Size() == s.Size() and t[1 as i64] == 'a' then 1 else 0);
  return 0;
}
