// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Stdlib C++ interop: transparent non-owning contiguous container mapping (incl. owning->view)
// COMPILE-ARGS: --clang-arg=-std=c++20
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   2
//   2
//   18
//
// Round trip of the `std::span` <-> `Core.Slice` mapping with a C++ oracle
// (SL-2, fork/slices/plan.md §5.B.2; D-SL-8, D-SL-10): a Carbon view crosses
// INTO C++ (`Tail` takes and returns `std::span<const int>`; the `Slice(i32)`
// argument converts to `Slice(const i32)` through the prelude's
// `ImplicitAs(Slice(const T))` impl, and the returned span imports as
// `Core.Slice(const i32)`), and a C++-made span crosses OUT to the EXPORTED
// Carbon `Sum`, whose `Core.Slice(const i32)` parameter maps to
// `std::span<const int>`. `fn Sum` is forward-declared before the `inline
// Cpp` block that names `Carbon::Sum` (imports must precede declarations, so
// the export reference lives in a post-declaration block --
// cpp_atomic_global_counter_diff.carbon's shape). The sibling `.diff.cpp`
// oracle computes the same three values in plain C++17 with pointer+size
// arithmetic; DIFF-MISMATCH is the falsifier for any value drift.
//
// Hand-derived expectations (R16(d)): `a` is {RuntimeSeed(-19), 2, 3} =
// {1, 2, 3}; `Tail` drops the first element, so `t.Size()` prints 2 and
// `t[0]` prints `a[1]` = 2; `CallSum` sums {5, 6, 7} through the exported
// `Sum` and prints 18.

import Core library "io";
import Cpp inline '''c++
#include <span>

// The layout premise of the transparent mapping (plan D-SL-1, R-6).
static_assert(sizeof(std::span<const int>) == 16,
              "std::span<T> must be a pointer and a size");

inline std::span<const int> Tail(std::span<const int> s) {
  return s.subspan(1);
}
''';

// Forward declaration: the `inline Cpp` block below references
// `Carbon::Sum`, and imports must precede every declaration.
fn Sum(s: Core.Slice(const i32)) -> i32;

inline Cpp '''
inline int CallSum() {
  int arr[3] = {5, 6, 7};
  return Carbon::Sum(std::span<const int>(arr));
}
''';

fn Sum(s: Core.Slice(const i32)) -> i32 {
  var total: i32 = 0;
  var i: i64 = 0;
  while (i < s.Size()) {
    total += s[i];
    ++i;
  }
  return total;
}

fn RuntimeSeed(x: i32) -> i32 { return x + 20; }

fn Run() -> i32 {
  var a: array(i32, 3) = (RuntimeSeed(-19), 2, 3);
  let t: Core.Slice(const i32) = Cpp.Tail(Core.Slice(i32).FromArray(&a));
  Core.Print(t.Size() as i32);
  Core.Print(t[0]);
  Core.Print(Cpp.CallSum());
  return 0;
}
