// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: C++ interop — importing C++ templates, instantiating on Carbon types
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   42
//   42
//   100
//
// Imports C++ class, alias, and function templates with `import Cpp inline`
// and instantiates them on the Carbon builtin i32: an alias-template
// instantiation used as a type (Cpp.BoxAlias(i32)), a member call on the
// resulting instantiation, and function-template calls with both a deduced
// and an explicit template argument. Shapes verbatim from
// toolchain/check/testdata/interop/cpp/function/import/template.carbon
// (deduced_or_explicit: `Cpp.min(a, b)`, `Cpp.min(i32, a, b)`) and
// toolchain/check/testdata/interop/cpp/class/import/template.carbon
// (use_indirect_class_template: `var v: Cpp.vector(i32);`).

import Core library "io";
import Cpp inline '''
template<typename T> struct Box {
  T value;
  T Get() const { return value; }
};
template<typename T> using BoxAlias = Box<T>;
template<typename T> T Twice(T x) { return x + x; }
''';

fn Run() -> i32 {
  var a: Cpp.BoxAlias(i32);
  a.value = 21;
  Core.Print(a.Get() + a.value);
  Core.Print(Cpp.Twice(a.value));
  Core.Print(Cpp.Twice(i32, 50));
  return 0;
}
