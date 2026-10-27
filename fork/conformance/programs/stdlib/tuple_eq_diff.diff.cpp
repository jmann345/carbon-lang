// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// Differential C++17 equivalent of tuple_eq_diff.carbon: each Carbon tuple is
// a std::tuple of the same element types, and `==` and `!=` are std::tuple's,
// which compare element by element with the elements' `==`, in order,
// stopping at the first element that differs, and define `!=` as the
// negation of `==`. Counted's `==` prints 10 plus its field, as the Carbon
// program's Equal does. printf("%d\n", ...) mirrors Core.Print's lowering.

#include <cstdint>
#include <cstdio>
#include <tuple>

static auto Show(bool b) -> void { std::printf("%d\n", b ? 1 : 0); }

struct Counted {
  int32_t v;
};

static auto operator==(const Counted& self, const Counted& other) -> bool {
  std::printf("%d\n", 10 + self.v);
  return self.v == other.v;
}

using Pair = std::tuple<int32_t, int32_t>;
using Five = std::tuple<int32_t, int32_t, int32_t, int32_t, int32_t>;
using Three = std::tuple<Counted, Counted, Counted>;

auto main() -> int {
  std::tuple<int32_t, int64_t, bool> a{1, 2, true};
  std::tuple<int32_t, int64_t, bool> b{1, 2, true};
  std::tuple<int32_t, int64_t, bool> c{1, 3, true};
  Show(a == b);
  Show(a == c);
  Show(a != c);
  std::tuple<> e1;
  std::tuple<> e2;
  Show(e1 == e2);
  std::tuple<Pair, int32_t> n{Pair{1, 2}, 3};
  std::tuple<Pair, int32_t> m{Pair{1, 4}, 3};
  Show(n == m);
  std::tuple<Pair, int32_t> n2{Pair{1, 2}, 3};
  Show(n != n2);
  Five w{1, 2, 3, 4, 5};
  Five w2{1, 2, 3, 4, 5};
  Show(w == w2);
  Counted c1{1};
  Counted c2{2};
  Counted c3{3};
  Counted c5{5};
  Three p{c1, c2, c3};
  Three q{c1, c5, c3};
  Show(p == q);
  Show(p != q);
  Show(p == p);
  return 0;
}
