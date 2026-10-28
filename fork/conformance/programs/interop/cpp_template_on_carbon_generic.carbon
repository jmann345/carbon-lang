// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Type system: C++ interop — importing C++ types / exporting Carbon types
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   7
//
// An imported C++ class template instantiated on a symbolic Carbon generic
// parameter and, at the specific, on an exported Carbon class: MakeBox's
// Cpp.Box(T) becomes Box<Pt> for MakeBox(p), with Pt exported to C++ as the
// argument (CT-1, fork/cpp-templates/plan.md). b.value.x reads back 7. Pt
// implements Core.Copy because `b.value = x` copies a Pt value, which the same
// body written with Cpp.Box(Pt) and no generic needs on every toolchain.

import Core library "io";
import Cpp inline '''

template <typename T> struct Box {
  T value;
};

''';

class Pt {
  var x: i32;
  impl as Core.Copy {
    fn Op(self) -> Self { return {.x = self.x}; }
  }
}

fn MakeBox[T: type](x: T) -> Cpp.Box(T) {
  var b: Cpp.Box(T);
  b.value = x;
  return b;
}

fn Run() -> i32 {
  var p: Pt = {.x = 7};
  var b: Cpp.Box(Pt) = MakeBox(p);
  Core.Print(b.value.x);
  return 0;
}
