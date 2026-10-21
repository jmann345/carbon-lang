// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// Differential oracle for cpp_template_symbolic_diff.carbon: the Carbon
// generic and template written as C++ function templates over the same C++
// templates, printing as Core.Print does (printf "%d\n").

#include <cstdio>

template <typename T>
struct Acc {
  T total;
  int n;
};
template <typename T>
Acc<T> Start(T v) {
  Acc<T> a;
  a.total = v;
  a.n = 1;
  return a;
}
template <typename T>
void Add(Acc<T>* a, T v) {
  a->total = a->total + v;
  a->n = a->n + 1;
}
template <typename T>
T Total(const Acc<T>& a) {
  return a.total;
}

template <typename T>
T SumThree(T a, T b, T c) {
  Acc<T> acc = Start(a);
  Add(&acc, b);
  Add(&acc, c);
  return Total(acc);
}

template <typename T>
int CountThree(T a, T b, T c) {
  Acc<T> acc = Start(a);
  Add(&acc, b);
  Add(&acc, c);
  return acc.n;
}

auto main() -> int {
  std::printf("%d\n", SumThree<int>(20000, 20000, 20000));
  std::printf("%d\n", SumThree<short>(20000, 20000, 20000));
  std::printf("%d\n", CountThree<int>(4, 5, 6));
  return 0;
}
