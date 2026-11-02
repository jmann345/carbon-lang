// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: C++ interop — importing C++ templates, instantiating on Carbon types
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   42
//   7
//   7
//
// A specialization of an imported C++ class template on a symbolic Carbon type
// passed to and returned from C++ functions whose signatures name it (CT-1,
// fork/cpp-templates/plan.md). RoundTrip(41): MakeBox<int>(41) returns a
// Box<int> holding 41, Bump<int>(&b) adds 1 through a pointer, Unbox<int>(b)
// takes it by value and returns 42. Make(7) returns MakeBox<int>(7) from the
// generic; the non-template UnboxInt(Box<int>) reads 7 from it, and its
// member function Get() returns 7.

import Core library "io";
import Cpp inline '''
template<typename T> struct Box {
  T value;
  T Get() const { return value; }
};
template<typename T> Box<T> MakeBox(T v) { Box<T> b; b.value = v; return b; }
template<typename T> T Unbox(Box<T> b) { return b.value; }
template<typename T> void Bump(Box<T>* b) { b->value = b->value + 1; }
inline int UnboxInt(Box<int> b) { return b.value; }
''';

fn RoundTrip[T: type](v: T) -> T {
  var b: Cpp.Box(T) = Cpp.MakeBox(v);
  Cpp.Bump(&b);
  return Cpp.Unbox(b);
}

fn Make[T: type](v: T) -> Cpp.Box(T) {
  return Cpp.MakeBox(v);
}

fn Run() -> i32 {
  Core.Print(RoundTrip(41 as i32));
  var b: Cpp.Box(i32) = Make(7 as i32);
  Core.Print(Cpp.UnboxInt(b));
  Core.Print(b.Get());
  return 0;
}
