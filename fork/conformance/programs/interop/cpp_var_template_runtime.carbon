// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: C++ interop — importing C++ templates, instantiating on Carbon types
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   5
//   8
//   20
//   9
//
// Imported C++ variable templates and a static data member template read at
// run time, on concrete and on symbolic Carbon type arguments: each
// specialization is instantiated and defined when Carbon names it (CT-1,
// fork/cpp-templates/plan.md). Plain<int> is sizeof(int) + 1 = 5;
// SizeOf<long> is 8 (i64 maps to long on x86-64 Linux); Holder::count<short>
// is sizeof(short) * 10 = 20; PlainOf(1 as i64) reads Plain<long> in a checked
// generic, 8 + 1 = 9.

import Core library "io";
import Cpp inline '''
template<typename T> int Plain = sizeof(T) + 1;
template<typename T> constexpr int SizeOf = sizeof(T);
struct Holder {
  template<typename T> static inline int count = sizeof(T) * 10;
};
''';

fn PlainOf[T: type](unused v: T) -> i32 {
  return Cpp.Plain(T);
}

fn Run() -> i32 {
  Core.Print(Cpp.Plain(i32));
  Core.Print(Cpp.SizeOf(i64));
  Core.Print(Cpp.Holder.count(i16));
  Core.Print(PlainOf(1 as i64));
  return 0;
}
