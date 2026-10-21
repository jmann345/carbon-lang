// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Control flow: matching — sum-type consumption incl. std::variant/std::optional interop
// EXPECT-EXIT: 0

// SV-1 (fork/sumtype-interop/plan.md, fork decision F-020): a C++
// `std::variant<T0, ..., Tn>` stays an imported C++ class, and is matched as
// the Carbon sum type it maps to by value, `Core.CppCompat.StdVariant<N>`,
// whose alternatives are named by C++ index: `.Alt0` holds the value when
// `index() == 0`. The conversion reads `index()` and then `std::get<I>`; it
// never reinterprets libc++'s bytes. Covered, every payload computed at run
// time (R16d): `std::variant<int, double>`; a `std::monostate` alternative,
// whose payload is `()`; duplicate alternative types,
// `std::variant<int, int>`, told apart by index; four alternatives of
// `bool`, `long`, `double` and `int*`; and a nested shape, a variant holding
// a pointer to a `std::optional<int>`, matched again through the pointer.
// Each match is exhaustive and has no `default` (SF-7). Differential pair:
// match_std_variant_diff.diff.cpp (DIFF-1).

import Core library "io";
import Cpp inline '''c++
#include <optional>
#include <variant>

inline auto IntOrHalf(int n) -> std::variant<int, double> {
  if (n > 0) {
    return n * 3;
  }
  return n * 0.5;
}

inline auto Tenths(double d) -> int { return static_cast<int>(d * 10); }

inline auto MaybeEmpty(int n) -> std::variant<std::monostate, int> {
  if (n > 0) {
    return n + 100;
  }
  return std::monostate();
}

inline auto LeftOrRight(int n) -> std::variant<int, int> {
  if (n > 0) {
    return std::variant<int, int>(std::in_place_index<1>, n);
  }
  return std::variant<int, int>(std::in_place_index<0>, -n);
}

inline int cell = 0;

inline auto Mixed(int n) -> std::variant<bool, long, double, int*> {
  switch (n % 4) {
    case 0:
      return n > 4;
    case 1:
      return static_cast<long>(n) * 7;
    case 2:
      return n * 0.25;
    default:
      cell = n;
      return &cell;
  }
}

inline std::optional<int> inner;

inline auto Nested(int n) -> std::variant<std::optional<int>*, int> {
  if (n > 0) {
    inner = n * 11;
    return &inner;
  }
  if (n == 0) {
    inner = std::nullopt;
    return &inner;
  }
  return n;
}
''';

fn Seed(x: i32) -> i32 { return x + 2; }

fn ShowIntOrHalf(n: i32) {
  match (Cpp.IntOrHalf(n)) {
    case .Alt0(i: i32) => {
      Core.Print(i);
    }
    case .Alt1(d: f64) => {
      Core.Print(Cpp.Tenths(d));
    }
  }
}

fn ShowMaybeEmpty(n: i32) {
  match (Cpp.MaybeEmpty(n)) {
    case .Alt0(unused empty: ()) => {
      Core.Print(0);
    }
    case .Alt1(i: i32) => {
      Core.Print(i);
    }
  }
}

fn ShowLeftOrRight(n: i32) {
  match (Cpp.LeftOrRight(n)) {
    case .Alt0(left: i32) => {
      Core.Print(1000 + left);
    }
    case .Alt1(right: i32) => {
      Core.Print(2000 + right);
    }
  }
}

fn ShowMixed(n: i32) {
  match (Cpp.Mixed(n)) {
    case .Alt0(b: bool) => {
      if (b) {
        Core.Print(1);
      } else {
        Core.Print(0);
      }
    }
    case .Alt1(l: i64) => {
      Core.Print(l as i32);
    }
    case .Alt2(d: f64) => {
      Core.Print(Cpp.Tenths(d));
    }
    case .Alt3(p: Core.Optional(i32*)) => {
      Core.Print(*p.Get());
    }
  }
}

fn ShowNested(n: i32) {
  match (Cpp.Nested(n)) {
    case .Alt0(p: Core.Optional(Cpp.std.optional(i32)*)) => {
      match (*p.Get()) {
        case .Some(v: i32) => {
          Core.Print(v);
        }
        case .None => {
          Core.Print(-1);
        }
      }
    }
    case .Alt1(i: i32) => {
      Core.Print(i);
    }
  }
}

fn Run() -> i32 {
  ShowIntOrHalf(Seed(2));
  ShowIntOrHalf(Seed(-5));
  ShowMaybeEmpty(Seed(1));
  ShowMaybeEmpty(Seed(-3));
  ShowLeftOrRight(Seed(5));
  ShowLeftOrRight(Seed(-9));
  ShowMixed(Seed(6));
  ShowMixed(Seed(7));
  ShowMixed(Seed(8));
  ShowMixed(Seed(9));
  ShowMixed(Seed(10));
  ShowNested(Seed(1));
  ShowNested(Seed(-2));
  ShowNested(Seed(-6));
  return 0;
}
