// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Stdlib: String and string-literal types
// EXPECT-EXIT: 0
//
// Differential pair: string_ordering_diff.diff.cpp is the equivalent C++17
// program over `std::string_view` and `std::string`, whose comparisons are
// `char_traits<char>::compare`, a byte-wise comparison of `unsigned char`
// values and then of lengths; the runner requires byte-identical exit code
// and stdout, so C++ is the oracle for every line (no EXPECT-STDOUT here, the
// arith_widths_diff precedent). Carbon side: `==`/`!=` are `String as
// EqWith(String)` and `<`/`<=`/`>`/`>=` are `String as OrderedWith(String)`,
// lexicographic on bytes compared as unsigned values with a proper prefix
// first; `+` builds a `Core.StringBuf`, which compares with `str` in both
// operand orders (core/prelude/types/string.carbon, fork/string/plan.md).
// Core.Print lowers to printf("%d\n", x), mirrored by the C++ side.

import Core library "io";

fn B(b: bool) -> i32 { return if b then 1 else 0; }

fn Run() -> i32 {
  // Equality: the same bytes, one differing byte, different lengths, empty.
  Core.Print(B("carbon" == "carbon"));
  Core.Print(B("carbon" == "carbOn"));
  Core.Print(B("carbon" != "carbo"));
  Core.Print(B("" == ""));
  // Ordering: the first differing byte decides, else the shorter is first.
  Core.Print(B("apple" < "apricot"));
  Core.Print(B("app" < "apple"));
  Core.Print(B("apple" <= "app"));
  Core.Print(B("Zebra" < "apple"));
  Core.Print(B("b" > "abc"));
  Core.Print(B("abc" >= "abc"));
  // Bytes are unsigned: 0xC3, the first byte of UTF-8 "é", sorts after 'z'.
  Core.Print(B("\xC3\xA9" > "z"));
  // An owning concatenation compares with views in both operand orders.
  var joined: Core.StringBuf = "app" + "le";
  Core.Print(joined.Size() as i32);
  Core.Print(B(joined == "apple"));
  Core.Print(B("apricot" > joined));
  Core.Print(B(joined < Core.StringBuf.Make("apples")));
  return 0;
}
