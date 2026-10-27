// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// Differential C++17 equivalent of tuple_ordered_diff.carbon: each Carbon
// tuple is a std::tuple of the same element types, and `<`, `<=`, `>` and
// `>=` are std::tuple's, which compare lexicographically using only the
// elements' `<` (`t <= u` is `!(u < t)`), so a 1-tuple of a NaN is
// equivalent to itself although the NaN's own `<=` is false.
// printf("%d\n", ...) mirrors Core.Print's lowering.

#include <cstdint>
#include <cstdio>
#include <tuple>

static auto Show(bool b) -> void { std::printf("%d\n", b ? 1 : 0); }

using Three = std::tuple<int32_t, int32_t, int32_t>;
using Pair = std::tuple<int32_t, int32_t>;

auto main() -> int {
  Three a{1, 2, 3};
  Three b{1, 3, 0};
  Show(a < b);
  Show(a <= b);
  Show(a > b);
  Show(a >= b);
  Three c{1, 2, 3};
  Show(a < c);
  Show(a > c);
  Show(a <= c);
  Show(a >= c);
  std::tuple<> e1;
  std::tuple<> e2;
  Show(e1 < e2);
  Show(e1 <= e2);
  std::tuple<Pair, int64_t> n{Pair{2, 1}, 0};
  std::tuple<Pair, int64_t> m{Pair{1, 9}, 5};
  Show(n > m);
  Show(n < m);
  double z = 0.0;
  double nan = z / z;
  std::tuple<double> t{nan};
  Show(t < t);
  Show(t <= t);
  Show(t >= t);
  Show(nan <= nan);
  return 0;
}
