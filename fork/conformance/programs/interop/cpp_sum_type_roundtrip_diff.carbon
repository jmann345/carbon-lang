// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Control flow: matching — sum-type consumption incl. std::variant/std::optional interop
// EXPECT-EXIT: 0

// SV-1 (fork/sumtype-interop/plan.md, fork decision F-020), the Carbon-to-C++
// direction: a value of `Core.CppCompat.StdOptional(T)` or `StdVariant<N>`
// passed where C++ takes `std::optional<T>` or `std::variant<Ts...>` -- by
// value or by `const&` -- converts by value, through the C++ class's
// constructor and `emplace`; a constant alternative (`.None`) converts as a
// computed one does. A Carbon function exported to C++ names the C++ class in
// its signature (the Carbon sum types themselves are not exported, W-049
// and the plan's residue list): it returns a `std::optional<int>` built from
// the Carbon sum type on each of two paths, and it takes a `std::variant`
// and matches it. A `Core.Optional(i32)` argument reaches the same
// parameters in one implicit step (D-SV-7). Every payload is computed at run
// time from a seed (R16d).
// Differential pair: cpp_sum_type_roundtrip_diff.diff.cpp (DIFF-1).

import Core library "io";
import Cpp inline '''c++
#include <optional>
#include <variant>

inline auto TakeOptional(std::optional<int> o) -> int {
  return o.has_value() ? *o + 1 : -1;
}

inline auto TakeOptionalRef(const std::optional<int>& o) -> int {
  return o.has_value() ? *o + 2 : -2;
}

inline auto TakeVariant(std::variant<int, double> v) -> int {
  return v.index() == 0 ? std::get<0>(v) : static_cast<int>(std::get<1>(v) * 10);
}

inline auto TakePair(const std::variant<int, int>& v) -> int {
  return static_cast<int>(v.index()) * 100 +
         (v.index() == 0 ? std::get<0>(v) : std::get<1>(v));
}

inline auto TakeEmpty(std::variant<std::monostate, int> v) -> int {
  return v.index() == 0 ? -7 : std::get<1>(v);
}
''';

fn Seed(x: i32) -> i32 { return x + 5; }

fn SeedF(x: f64) -> f64 { return x + x; }

fn MakeOptional(n: i32) -> Cpp.std.optional(i32) {
  if (n > 0) {
    return Core.CppCompat.StdOptional(i32).Some(n * 4);
  }
  return Core.CppCompat.StdOptional(i32).None;
}

fn InspectVariant(v: Cpp.std.variant(i32, f64)) -> i32 {
  match (v) {
    case .Alt0(i: i32) => {
      return i + 1;
    }
    case .Alt1(d: f64) => {
      return Cpp.TakeVariant(Core.CppCompat.StdVariant2(i32, f64).Alt1(d)) + 2;
    }
  }
  return -100;
}

inline Cpp '''
inline auto UseMakeOptional(int n) -> int {
  std::optional<int> o = Carbon::MakeOptional(n);
  return o.has_value() ? *o : -3;
}

inline auto UseInspectVariant(int n) -> int {
  if (n > 0) {
    return Carbon::InspectVariant(std::variant<int, double>(n));
  }
  return Carbon::InspectVariant(std::variant<int, double>(n * 1.5));
}
''';

fn Run() -> i32 {
  let some: Core.CppCompat.StdOptional(i32) =
      Core.CppCompat.StdOptional(i32).Some(Seed(30));
  let none: Core.CppCompat.StdOptional(i32) =
      Core.CppCompat.StdOptional(i32).None;
  Core.Print(Cpp.TakeOptional(some));
  Core.Print(Cpp.TakeOptionalRef(some));
  Core.Print(Cpp.TakeOptional(none));
  Core.Print(Cpp.TakeOptional(Core.CppCompat.StdOptional(i32).None));
  Core.Print(Cpp.TakeOptional(Core.Optional(i32).Some(Seed(40))));
  Core.Print(Cpp.TakeOptionalRef(Core.Optional(i32).None()));
  let half: f64 = SeedF(1.25);
  Core.Print(Cpp.TakeVariant(Core.CppCompat.StdVariant2(i32, f64).Alt1(half)));
  Core.Print(Cpp.TakeVariant(Core.CppCompat.StdVariant2(i32, f64).Alt0(Seed(4))));
  Core.Print(Cpp.TakePair(Core.CppCompat.StdVariant2(i32, i32).Alt1(Seed(2))));
  Core.Print(Cpp.TakePair(Core.CppCompat.StdVariant2(i32, i32).Alt0(Seed(3))));
  Core.Print(Cpp.TakeEmpty(Core.CppCompat.StdVariant2((), i32).Alt0(())));
  Core.Print(Cpp.TakeEmpty(Core.CppCompat.StdVariant2((), i32).Alt1(Seed(6))));
  Core.Print(Cpp.UseMakeOptional(Seed(1)));
  Core.Print(Cpp.UseMakeOptional(Seed(-8)));
  Core.Print(Cpp.UseInspectVariant(Seed(2)));
  Core.Print(Cpp.UseInspectVariant(Seed(-7)));
  return 0;
}
