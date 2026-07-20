// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: C++ interop — importing C++ templates, instantiating on Carbon types
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   7
// SKIP: a symbolic checked-generic type parameter as a C++ template argument still fails to compile on nightly 2026.07.19: "error: semantics TODO: `unsupported type used as template argument`" at `var b: Cpp.Box(T);` — the exact TODO tracked in toolchain/check/testdata/interop/cpp/template/generic_call.carbon (fail_todo_generic_call); enable when template instantiation is deferred to monomorphization.
//
// The known-missing slice of this PARTIAL bullet: using a Carbon checked
// generic's symbolic type parameter T as an argument to an imported C++
// template (Cpp.Box(T)) inside the generic's body. Concrete Carbon types in
// the same position work (cpp_template_builtins.carbon,
// cpp_template_carbon_class.carbon); the symbolic case requires deferring
// C++ template instantiation until monomorphization.

import Core library "io";
import Cpp inline '''
template<typename T> struct Box {
  T value;
};
''';

class Point {
  var x: i32;
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
