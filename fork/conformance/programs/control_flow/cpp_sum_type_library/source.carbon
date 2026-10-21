// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// The library unit of cpp_sum_type_library: it imports the C++ and converts
// at its own API, so its importer sees only the Carbon sum type.

library "source";

import Cpp inline '''c++
#include <optional>
#include <variant>

inline auto MaybeSquare(int n) -> std::optional<int> {
  if (n > 0) {
    return n * n;
  }
  return std::nullopt;
}

inline auto CountOrFlag(int n) -> std::variant<int, bool> {
  if (n > 0) {
    return n + 1;
  }
  return n == 0;
}
''';

fn Fetch(n: i32) -> Core.CppCompat.StdOptional(i32) {
  return Cpp.MaybeSquare(n);
}

fn Classify(n: i32) -> Core.CppCompat.StdVariant2(i32, bool) {
  return Cpp.CountOrFlag(n);
}
