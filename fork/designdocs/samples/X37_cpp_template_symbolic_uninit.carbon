// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/interoperability/README.md, "Using C++ templates", quote
// EXPECT-STDOUT:
//   42
//   10
// QUOTE: A `var` of such a specialization can be declared without an initializer, `var b: Cpp.Box(T);`
// Pins the page's sentence on an uninitialized `var` of a C++ specialization
// of a checked generic's type parameter and a C++ function template called
// with an argument of that type: `G(21 as i32)` stores `Twice<int>(21)` in a
// `Box<int>` and returns 42, and `G(5 as i16)` does the same with `Box<short>`
// and returns 10.

import Core library "io";

import Cpp inline '''c++
template <typename T>
struct Box {
  T value;
};

template <typename T>
T Twice(T x) { return x + x; }
''';

fn G[T: type](x: T) -> T {
  var b: Cpp.Box(T);
  b.value = Cpp.Twice(x);
  return b.value;
}

fn Run() -> i32 {
  Core.Print(G(21 as i32));
  Core.Print(G(5 as i16));
  return 0;
}
