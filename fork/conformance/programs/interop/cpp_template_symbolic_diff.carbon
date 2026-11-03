// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: C++ interop — importing C++ templates, instantiating on Carbon types
// EXPECT-EXIT: 0
//
// C++ class and function templates used from a Carbon checked generic and a
// Carbon template with symbolic type arguments (CT-1,
// fork/cpp-templates/plan.md). Differential pair:
// cpp_template_symbolic_diff.diff.cpp runs the same templates from C++
// function templates of the same shape (no EXPECT-STDOUT). SumThree of three
// 20000s accumulates 60000 in an Acc<int>; on i16 the same sum wraps in an
// Acc<short>'s `short` total (C++'s conversion, -5536 with Clang), so the two
// specializations differ; CountThree, with a template binding, reads the
// accumulator's member n, 3.

import Core library "io";
import Cpp inline '''
template<typename T> struct Acc {
  T total;
  int n;
};
template<typename T> Acc<T> Start(T v) { Acc<T> a; a.total = v; a.n = 1; return a; }
template<typename T> void Add(Acc<T>* a, T v) { a->total = a->total + v; a->n = a->n + 1; }
template<typename T> T Total(const Acc<T>& a) { return a.total; }
''';

fn SumThree[T: type](a: T, b: T, c: T) -> T {
  var acc: Cpp.Acc(T) = Cpp.Start(a);
  Cpp.Add(&acc, b);
  Cpp.Add(&acc, c);
  return Cpp.Total(acc);
}

fn CountThree[template T: type](a: T, b: T, c: T) -> i32 {
  var acc: Cpp.Acc(T) = Cpp.Start(a);
  Cpp.Add(&acc, b);
  Cpp.Add(&acc, c);
  return acc.n;
}

fn Run() -> i32 {
  Core.Print(SumThree(20000 as i32, 20000 as i32, 20000 as i32));
  Core.Print(SumThree(20000 as i16, 20000 as i16, 20000 as i16));
  Core.Print(CountThree(4 as i32, 5 as i32, 6 as i32));
  return 0;
}
