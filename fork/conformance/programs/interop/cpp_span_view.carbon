// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Stdlib C++ interop: transparent non-owning contiguous container mapping (incl. owning->view)
// COMPILE-ARGS: --clang-arg=-std=c++20
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   10
//   6
//
// Both directions of the transparent mapping (SL-2, fork/slices/plan.md
// §5.B.1; D-SL-8, D-SL-9, D-SL-14): (1) a Carbon array reaches a C++
// `std::span<const int>` parameter through an explicit view,
// `Core.Slice(i32).FromArray(&a)`, which imports/exports as `std::span` with
// no copy; (2) owning -> view: a `std::vector<int>` made in C++ converts
// implicitly to `Core.Slice(const i32)` (the synthesized
// `Core.CppContiguousRange` witness over its `data()`/`size()` members plus
// the prelude's blanket `ImplicitAs` impl, core/prelude/types/cpp/slice.carbon)
// and an element is read through the view. `<span>` needs C++20
// (COMPILE-ARGS; the toolchain's Clang defaults to gnu++17).
//
// Un-SKIPped from the write-tests-first stub; two strawman rewrites are
// disclosed (plan §0.2 item 7): `Cpp.SumSpan(a)` on an array VALUE became
// `Cpp.SumSpan(Core.Slice(i32).FromArray(&a))` -- views are formed from a
// pointer to the array, never from a value (D-SL-2) -- and `v.AsSlice()`
// (Carbon cannot add methods to an imported class) became the conversion
// `let view: Core.Slice(const i32) = v;` (D-SL-9).
//
// Hand-derived expectations (R16(d)): `a` is {1, 2, 3, 4}, so
// `std::accumulate` over the span prints 1 + 2 + 3 + 4 = 10; `MakeVector()`
// is {2, 4, 6}, so `view[2]` prints 6 (`const i32` -> `i32` for `Core.Print`
// by the prelude's `const U as ImplicitAs(T)` impl).

import Core library "io";
import Cpp inline '''c++
#include <numeric>
#include <span>
#include <vector>

// The layout premise of the transparent mapping (plan D-SL-1, R-6):
// `Core.Slice(T)` is `{T*, i64}`, 16 bytes, and so is a dynamic-extent span.
static_assert(sizeof(std::span<const int>) == 16,
              "std::span<T> must be a pointer and a size");

inline int SumSpan(std::span<const int> s) {
  return std::accumulate(s.begin(), s.end(), 0);
}

inline std::vector<int> MakeVector() { return {2, 4, 6}; }
''';

fn Run() -> i32 {
  var a: array(i32, 4) = (1, 2, 3, 4);
  // The view is formed explicitly (`&a`) and crosses as std::span.
  Core.Print(Cpp.SumSpan(Core.Slice(i32).FromArray(&a)));
  // Owning -> view: the vector converts to a slice of its elements.
  var v: Cpp.std.vector(i32) = Cpp.MakeVector();
  let view: Core.Slice(const i32) = v;
  Core.Print(view[2]);
  return 0;
}
