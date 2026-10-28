// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: C++ interop — importing C++ templates, instantiating on Carbon types
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   6
//   64
//   65
//
// A specific of a Carbon generic class as the argument of an imported C++
// class template, Cpp.Box(List(T)), and a Carbon generic class whose field is
// a C++ specialization of its parameter, Holder(T) with Cpp.Box(T), each
// formed for the specific (CT-1, fork/cpp-templates/plan.md). Wrap(5) stores
// {.head = 5, .count = 1} in a Box<List(i32)>, read back as 5 + 1 = 6;
// Holder(i32).Get() returns the 64 its box holds, and Next(h) reads it in a
// checked generic and adds 1, 65.

import Core library "io";
import Cpp inline '''
template<typename T> struct Box {
  T value;
};
template<typename T> Box<T> MakeBox(T v) { Box<T> b; b.value = v; return b; }
''';

class List(T: type) {
  var head: T;
  var count: i32;
}

class Holder(T: type) {
  var b: Cpp.Box(T);
  fn Get(self) -> T { return self.b.value; }
}

fn Wrap[T: type](v: T) -> Cpp.Box(List(T)) {
  var b: Cpp.Box(List(T));
  b.value = {.head = v, .count = 1};
  return b;
}

fn Next[T: type](h: Holder(T), one: T) -> T {
  return h.b.value + one;
}

fn Run() -> i32 {
  var b: Cpp.Box(List(i32)) = Wrap(5 as i32);
  Core.Print(b.value.head + b.value.count);
  var h: Holder(i32) = {.b = Cpp.MakeBox(64 as i32)};
  Core.Print(h.Get());
  Core.Print(Next(h, 1 as i32));
  return 0;
}
