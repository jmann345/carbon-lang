// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/interoperability/README.md, "Accessing C++ classes, structs, and members", block
// EXPECT-ERROR: semantics TODO: `Unsupported: var type: int A::*`

import Cpp inline '''c++
struct A {
  int m;
  int F() { return 3; }
};
int A::* p = &A::m;
int (A::* q)() = &A::F;
''';

fn G(ref a: Cpp.A) -> i32 {
  return a.(Cpp.p) + a.(Cpp.q)();
}
