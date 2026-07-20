// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Stdlib C++ interop: transparent non-owning string mapping
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   6
//   carbon
//   interop
//   7
//
// C++ -> Carbon direction of the transparent str <-> std::string_view
// mapping (check/cpp/custom_type_mapping.cpp, proposal p006177): a C++
// function returning `std::string_view` yields a Carbon `str` with no
// explicit conversion, usable with the native str API (.Size(), s[i] —
// core/prelude/types/string.carbon). `Middle` also round-trips: it takes the
// view of a Carbon string literal and returns a substr view aliasing those
// same bytes — non-owning in both directions, no copy. Return-mapping shape
// proven in check/testdata/interop/cpp/stdlib/string_view.carbon
// (pass_and_return: `fn G() -> str { return Cpp.Produce(); }` with
// `Produce() -> std::string_view`). Chars print via Core.PrintChar (inline
// putchar) because Core.PrintStr does not link here (README); indexes are
// `i64`-typed to avoid the IntLiteral-index lowering crash documented in
// stdlib/string_basic.carbon.

import Core library "io";
import Cpp inline '''c++

#include <string_view>

inline auto Greeting() -> std::string_view { return "carbon"; }

inline auto Middle(std::string_view sv) -> std::string_view {
  return sv.substr(1, sv.size() - 2);
}

''';

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
  // A returned std::string_view arrives as a Carbon `str`.
  let g: str = Cpp.Greeting();
  Core.Print(g.Size() as i32);
  PrintString(g);

  // Round trip: C++ slices the view of a Carbon literal and hands back a
  // sub-view of the very same bytes.
  let m: str = Cpp.Middle("[interop]");
  PrintString(m);
  Core.Print(m.Size() as i32);
  return 0;
}
