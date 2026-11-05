// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: C++ interop — importing C++ templates, instantiating on Carbon types
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   34
//   9
//
// A nested specialization, Cpp.Pair(Cpp.Box(T)), named in a checked generic
// with a symbolic T and formed for each specific (CT-1,
// fork/cpp-templates/plan.md). Both(3, 4) stores 3 and 4 in the two boxes of a
// Pair<Box<int>>, read back as 3 * 10 + 4 = 34; Sum(p) adds the two values
// read through the generic, 4 + 5 = 9.

import Core library "io";
import Cpp inline '''
template<typename T> struct Box {
  T value;
};
template<typename T> struct Pair {
  T first;
  T second;
};
''';

fn Both[T: type](a: T, b: T) -> Cpp.Pair(Cpp.Box(T)) {
  var p: Cpp.Pair(Cpp.Box(T));
  p.first.value = a;
  p.second.value = b;
  return p;
}

fn Sum[T: type](unused w: T, p: Cpp.Pair(Cpp.Box(T))) -> T {
  return p.first.value + p.second.value;
}

fn Run() -> i32 {
  var p: Cpp.Pair(Cpp.Box(i32)) = Both(3 as i32, 4 as i32);
  Core.Print(p.first.value * 10 + p.second.value);
  Core.Print(Sum(0 as i32, Both(4 as i32, 5 as i32)));
  return 0;
}
