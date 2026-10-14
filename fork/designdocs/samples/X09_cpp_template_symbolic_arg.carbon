// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/interoperability/README.md, "Using C++ templates", quote
// EXPECT-STDOUT:
//   7
//   8
//   4
// QUOTE: the body `let b: Cpp.Box(T) = Cpp.Box(T).Make(x); return b.Get();` compiles, and the template is instantiated for each specific
// Pins the page's sentence on a checked generic's type parameter as a C++
// template argument: `F(7 as i32)` instantiates `Box<int>` and returns 7, and
// `SizeOf` instantiates `Box<long>` and `Box<int>` for its two specifics,
// whose `sizeof(T)` is 8 and 4 on 64-bit Linux. The form the page states as
// the limit, `var b: Cpp.Box(T);` with no initializer, is the plan's probe
// PR-T (section 4.3; fork work item W-043).

import Core library "io";

import Cpp inline '''c++
template <typename T>
struct Box {
  T value;
  T Get() const { return value; }
  static Box Make(T v) { return Box{v}; }
  static int Size() { return sizeof(T); }
};
''';

fn F[T: Core.Copy](x: T) -> T {
  let b: Cpp.Box(T) = Cpp.Box(T).Make(x);
  return b.Get();
}

fn SizeOf[T: type](unused x: T) -> i32 {
  return Cpp.Box(T).Size();
}

fn Run() -> i32 {
  Core.Print(F(7 as i32));
  Core.Print(SizeOf(1 as i64));
  Core.Print(SizeOf(1 as i32));
  return 0;
}
