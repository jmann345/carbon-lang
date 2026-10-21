// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Control flow: matching — sum-type consumption incl. std::variant/std::optional interop
// EXPECT-EXIT: 0

// SV-1 (fork/sumtype-interop/plan.md, fork decision F-020): a C++
// `std::optional<T>` stays an imported C++ class, and is matched as the
// Carbon sum type it maps to by value, `Core.CppCompat.StdOptional(T)` --
// the docs/design/sum_types.md `Optional(T)` declaration, alternatives
// `.Some(value: T)` and `.None`. The conversion reads the C++ object through
// its accessors (`has_value()`, `value()`); it never reinterprets libc++'s
// bytes. Every payload is computed at run time from a seed the C++ side
// cannot see in advance (R16d). Covered: an exhaustive match without
// `default` on a call result (SF-7); `if (let .Some(...) = ...)`; a pointer
// payload, `std::optional<int*>`, whose engaged null pointer is distinct
// from `None` (the payload is the nullable `Core.Optional(i32*)`, D-SV-8); a
// 64-bit payload; a generic Carbon function over the mapped type; and the
// implicit one-step conversion of a C++ `std::optional<int>` to
// `Core.Optional(i32)`.
// Differential pair: match_std_optional_diff.diff.cpp computes the same
// values with `std::optional` and prints the same lines (DIFF-1).

import Core library "io";
import Cpp inline '''c++
#include <cstdint>
#include <optional>

inline int target = 0;

inline auto MaybeTwice(int n) -> std::optional<int> {
  if (n > 0) {
    return n * 2;
  }
  return std::nullopt;
}

inline auto MaybeAddress(int n) -> std::optional<int*> {
  target = n * 3;
  if (n > 0) {
    return &target;
  }
  if (n == 0) {
    return nullptr;
  }
  return std::nullopt;
}

inline auto MaybeWide(int n) -> std::optional<std::int64_t> {
  if (n > 0) {
    return static_cast<std::int64_t>(n) * 1000000000;
  }
  return std::nullopt;
}
''';

fn Seed(x: i32) -> i32 { return x + 4; }

fn Unwrap[T: Core.Copy & Core.Destroy](o: Core.CppCompat.StdOptional(T),
                                       fallback: T) -> T {
  var result: T = fallback;
  match (o) {
    case .Some(value: T) => {
      result = value;
    }
    case .None => {}
  }
  return result;
}

fn Show(n: i32) {
  match (Cpp.MaybeTwice(n)) {
    case .Some(value: i32) => {
      Core.Print(value);
    }
    case .None => {
      Core.Print(-1);
    }
  }
}

fn ShowPointer(n: i32) {
  match (Cpp.MaybeAddress(n)) {
    case .Some(p: Core.Optional(i32*)) => {
      if (p.HasValue()) {
        Core.Print(*p.Get());
      } else {
        Core.Print(0);
      }
    }
    case .None => {
      Core.Print(-1);
    }
  }
}

fn ShowWide(n: i32) {
  match (Cpp.MaybeWide(n)) {
    case .Some(value: i64) => {
      Core.Print((value / 1000000000) as i32);
    }
    case .None => {
      Core.Print(-1);
    }
  }
}

fn Run() -> i32 {
  Show(Seed(3));
  Show(Seed(-7));
  if (let .Some(value: i32) = Cpp.MaybeTwice(Seed(1))) {
    Core.Print(value);
  }
  ShowPointer(Seed(1));
  ShowPointer(Seed(-4));
  ShowPointer(Seed(-9));
  ShowWide(Seed(5));
  ShowWide(Seed(-5));
  let some: Core.CppCompat.StdOptional(i32) = Cpp.MaybeTwice(Seed(17));
  let none: Core.CppCompat.StdOptional(i32) = Cpp.MaybeTwice(Seed(-17));
  let fallback: i32 = Seed(-11);
  Core.Print(Unwrap(some, fallback));
  Core.Print(Unwrap(none, fallback));
  let carbon_optional: Core.Optional(i32) = Cpp.MaybeTwice(Seed(17));
  if (carbon_optional.HasValue()) {
    Core.Print(carbon_optional.Get());
  }
  return 0;
}
