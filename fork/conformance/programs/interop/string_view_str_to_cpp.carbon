// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Stdlib C++ interop: transparent non-owning string mapping
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   7
//   11
//   2
//   1
//
// Carbon -> C++ direction of the transparent str <-> std::string_view
// mapping (check/cpp/custom_type_mapping.cpp, proposal p006177): Carbon
// `str` values — both string literals and `str` variables — pass directly
// to C++ functions whose parameter type is `std::string_view`, with no
// explicit conversion, and the C++ side observes the same bytes through the
// non-owning view (size, contents). Call/mapping shapes proven in
// check/testdata/interop/cpp/stdlib/string_view.carbon (pass_and_return:
// `Cpp.Consume("hello")` with `Consume(std::string_view)`); inline-import
// syntax from check/testdata/interop/cpp/basics/inline/import.carbon; char
// params take Carbon char literals per check/testdata/interop/cpp/function/
// import/arithmetic_types_bridged.carbon (char_param).

import Core library "io";
import Cpp inline '''c++

#include <string_view>

inline auto Length(std::string_view sv) -> int {
  return static_cast<int>(sv.size());
}

inline auto CountChar(std::string_view sv, char c) -> int {
  int n = 0;
  for (char x : sv) {
    if (x == c) { ++n; }
  }
  return n;
}

inline auto FirstChar(std::string_view sv) -> char { return sv.front(); }

''';

fn Run() -> i32 {
  // A Carbon string literal passes straight into a std::string_view param.
  Core.Print(Cpp.Length("interop"));

  // So does a `str`-typed value; C++ sees the same non-owning view.
  let s: str = "transparent";
  Core.Print(Cpp.Length(s));
  Core.Print(Cpp.CountChar(s, 'a'));
  Core.Print(if Cpp.FirstChar(s) == 't' then 1 else 0);
  return 0;
}
