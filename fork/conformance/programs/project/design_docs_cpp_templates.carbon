// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: C++ interop — importing C++ templates, instantiating on Carbon types
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   7
//   5
//   4
//
// Documentation-sync program (fork/designdocs/plan.md D-DD-5): the code after
// this comment block is the P17 code block of
// docs/design/interoperability/README.md, section "Using C++ templates", byte
// for byte (fork/designdocs/check_samples.py, rulebook R27). Expected output
// derived by hand in fork/designdocs/plan.md section 4 (R16(d)). Runs on this
// fork's toolchain and on the upstream nightly. A PASS shows that the
// documented sample runs as documented; the design-docs bullet itself is
// arbitrated by document review.

import Core library "io";

import Cpp inline '''c++
template <typename T>
T Larger(T a, T b) { return a < b ? b : a; }

template <typename T>
struct Box {
  T value;
  T Get() const { return value; }
  static Box Make(T v) { return Box{v}; }
};
''';

class Point {
  var x: i32;
  var y: i32;
}

fn Run() -> i32 {
  // C++ deduces a function template's arguments from the Carbon arguments.
  Core.Print(Cpp.Larger(3, 7));
  // A class template takes its template arguments in parentheses, and each
  // argument list names a distinct type.
  let b: Cpp.Box(i32) = Cpp.Box(i32).Make(5);
  Core.Print(b.Get());
  // A C++ template can be instantiated on a Carbon class type.
  let p: Point = {.x = 3, .y = 4};
  let boxed: Cpp.Box(Point) = Cpp.Box(Point).Make(p);
  Core.Print(boxed.Get().y);
  return 0;
}
