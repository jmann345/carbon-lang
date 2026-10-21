// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Stdlib C++ interop: transparent non-owning contiguous container mapping (incl. owning->view)
// COMPILE-ARGS: --clang-arg=-std=c++20
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   18
//
// A write through `s[0]` is seen by C++ through the `std::span<int>` the
// slice maps to (DR-1 D-DR-7, SL-2's mapping). Hand-derived: (1, 2, 3)
// becomes (10, 2, 3); `Bump` adds one to each element, (11, 3, 4); `Sum` is
// 18. Differential pair: cpp_span_write_through_diff.diff.cpp (DIFF-1).

import Core library "io";
import Cpp inline '''
#include <span>
inline auto Sum(std::span<int> s) -> int {
  int t = 0;
  for (int x : s) t += x;
  return t;
}
inline auto Bump(std::span<int> s) -> void {
  for (int& x : s) x += 1;
}
''';

fn Run() -> i32 {
  var a: array(i32, 3) = (1, 2, 3);
  let s: Core.Slice(i32) = Core.Slice(i32).FromArray(&a);
  s[0] = 10;
  Cpp.Bump(s);
  Core.Print(Cpp.Sum(s));
  return 0;
}
