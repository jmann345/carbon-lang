// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Type system: C++ interop — bi-directional inheritance, hierarchy roots, abstract/final/virtual mapping
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   5
//   7
// SKIP: multiple-inheritance mapping is the bullet's known-missing slice: derived-to-base conversion for a C++ class with two bases fails on the 2026.07.19 toolchain with `error: cannot implicitly convert expression of type `Cpp.C*` to `Cpp.A*`` / note: type `Cpp.C*` does not implement interface `Core.ImplicitAs(Cpp.A*)` (and likewise for `Cpp.B*`), matching fail_todo_use_multiple_inheritance.carbon in toolchain/check/testdata/interop/cpp/class/import/base.carbon; virtual/diamond bases fail the same way (fail_todo_use_virtual_inheritance, fail_todo_use_diamond). Un-SKIP when multiple-base conversion lands.
//
// Encodes the missing slice of this PARTIAL bullet, written ahead of the
// feature per process.md step 1: a C++ class with two non-empty bases is
// imported, an object is built in C++, and Carbon converts the derived
// pointer to each base to read both fields. Only classes with a single
// (preferred) base convert today (multiple_inheritance_with_preferred_base
// in the same testdata file); general multiple/virtual/diamond bases are
// fail_todo.

import Core library "io";
import Cpp;

inline Cpp '''
struct A { int a; };
struct B { int b; };
struct C : A, B {};

auto MakeC() -> C {
  C c;
  c.a = 5;
  c.b = 7;
  return c;
}
''';

fn Run() -> i32 {
  var c: Cpp.C = Cpp.MakeC();
  let pa: Cpp.A* = &c;
  let pb: Cpp.B* = &c;
  Core.Print(pa->a);
  Core.Print(pb->b);
  return 0;
}
