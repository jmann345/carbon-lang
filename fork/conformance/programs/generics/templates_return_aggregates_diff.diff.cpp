// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// Differential oracle for templates_return_aggregates_diff.carbon: the same
// templates in C++17, printing as Core.Print does (printf "%d\n").

#include <array>
#include <cstdio>
#include <tuple>

struct AB {
  int a;
  int b;
};

struct XY {
  int x;
  int y;
};

template <typename T>
auto Dup(T x) -> std::tuple<T, T> {
  return {x, x};
}

template <typename T>
auto Mk(T x) -> AB {
  return {x, x};
}

template <typename T>
auto Two(T x) -> std::array<T, 2> {
  return {x, x};
}

template <typename T>
struct H {
  T a;
  auto Both() const -> std::tuple<T, T> { return {a, a}; }
};

template <typename T>
auto Sum(T p) -> int {
  auto [a, b] = p;
  return a + b;
}

template <typename T>
auto Id(T p) -> T {
  return p;
}

template <typename T>
auto Pair(T x) -> std::tuple<T, T> {
  return {x, x};
}

template <typename T>
auto G(T x) -> std::tuple<std::tuple<T, T>, int> {
  return {Pair(x), 1};
}

auto main() -> int {
  auto t = Dup(4);
  std::printf("%d\n", std::get<0>(t) + std::get<1>(t));
  AB s = Mk(5);
  std::printf("%d\n", s.a + s.b);
  auto a = Two(4);
  std::printf("%d\n", a[0] + a[1]);
  H<int> h = {3};
  auto u = h.Both();
  std::printf("%d\n", std::get<0>(u) + std::get<1>(u));
  std::tuple<int, int> p = {4, 5};
  std::printf("%d\n", Sum(p));
  auto r = Id(p);
  std::printf("%d\n", std::get<0>(r));
  std::printf("%d\n", std::get<1>(r));
  XY q = {6, 7};
  std::printf("%d\n", Id(q).y);
  auto n = G(3);
  std::printf("%d\n", std::get<0>(std::get<0>(n)) +
                          std::get<1>(std::get<0>(n)) + std::get<1>(n));
  return 0;
}
