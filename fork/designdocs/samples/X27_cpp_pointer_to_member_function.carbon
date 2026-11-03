// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/interoperability/README.md, "Accessing C++ classes, structs, and members", quote
// EXPECT-ERROR: member name of type `<C++ type int (A::*)(void)>` in compound member access is not an instance member or an interface member
// QUOTE: member name of type `<C++ type int (A::*)(void)>` in compound member access is not an instance member or an interface member
// Pins the page's sentence on the call through a pointer to member function,
// `a.(Cpp.q)()`, proposal 7697's second form: the first error, on the fork
// toolchain and the nightly, is on the compound member access (fork work item
// W-194). The page block, block fixture R35, uses `p` first, so its first
// error is the one for the pointer to data member.

import Cpp inline '''c++
struct A {
  int m;
  int F() { return 3; }
};
int (A::* q)() = &A::F;
''';

fn G(ref a: Cpp.A) -> i32 {
  return a.(Cpp.q)();
}
