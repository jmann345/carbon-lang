// CONFORMANCE-BULLET: Stdlib: String and string-literal types
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   Carbon
//   6
//   1
//   1
//
// Working slice of the (PARTIAL) String bullet: string literals have type
// `str` (Core.String, a non-owning {Char*, u64} — core/prelude/types/string.carbon),
// `.Size()` returns u64, `s[i]` returns `char` via the `String as IndexWith`
// impl ("string.at" builtin, toolchain/check/testdata/operators/overloaded/
// string_indexing.carbon), and `str` is Copy. Chars print one at a time with
// Core.PrintChar (inline putchar), the same loop as Core.PrintStr's body
// (core/io.impl.carbon), because PrintStr itself does not link here (README).
//
// Caution: all indexes below are `i64`-typed on purpose. Indexing a runtime
// `str` with a bare literal (`s[0]`, index type Core.IntLiteral) crashes this
// arbiter toolchain in lowering: "GEP indexes must be integers ... {}
// zeroinitializer", CHECK failure at toolchain/lower/lower.cpp:45. `as i64`
// sidesteps it. The known-missing library slice (str `==`, `+`, owning
// string) is encoded in string_missing_ops.carbon.

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
