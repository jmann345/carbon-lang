// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: C++ interop — importing C++ templates, instantiating on Carbon types
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   7
//
// A Carbon checked generic's symbolic type parameter T as the argument of an
// imported C++ class template, Cpp.Box(T), in the generic's body: the
// specialization is formed for each specific when T is known (here Box<Point>,
// Point exported to C++), and its default initialization, the assignment to
// its field and its copy on return are performed there (CT-1,
// fork/cpp-templates/plan.md). Wrap({.x = 7} as Point).value.x reads back 7.
// Point implements Core.Copy because `b.value = v` copies a Point value: the
// same body without the generic, with Cpp.Box(Point), is rejected by every
// toolchain without it ("cannot copy value of type `Point`"), so the program
// before CT-1 could not have passed for that reason either.

import Core library "io";
import Cpp inline '''
template<typename T> struct Box {
  T value;
};
''';

class Point {
  var x: i32;
  impl as Core.Copy {
    fn Op(self) -> Self { return {.x = self.x}; }
  }
}

fn Wrap[T: type](v: T) -> Cpp.Box(T) {
  var b: Cpp.Box(T);
  b.value = v;
  return b;
}

fn Run() -> i32 {
  Core.Print(Wrap({.x = 7} as Point).value.x);
  return 0;
}
