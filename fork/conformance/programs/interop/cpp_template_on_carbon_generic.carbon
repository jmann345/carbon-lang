// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Type system: C++ interop — importing C++ types / exporting Carbon types
// SKIP: known-missing slice — instantiating an imported C++ template on a symbolic Carbon generic parameter fails to compile on nightly 2026.07.19 with: "error: semantics TODO: `unsupported type used as template argument`" (both uses of Cpp.Box(T) below; same TODO as check/testdata/interop/cpp/template/generic_call.carbon). Concrete Carbon class types as template args DO work — arbitrated by cpp_type_import_class_enum.carbon.
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   7
//
// Encodes the missing slice of this PARTIAL bullet precisely: the audit
// evidence says "C++ templates cannot instantiate on Carbon class types",
// but on this toolchain the concrete case (`var b: Cpp.Box(Pt);`) compiles,
// links, and runs. What still fails is naming `Cpp.Box(T)` with `T` a
// checked-generic parameter — instantiation is not deferred to
// monomorphization (explicit TODO in check/testdata/interop/cpp/template/
// generic_call.carbon). Un-SKIP this program when that lands; it should
// then print 7 and exit 0.

import Core library "io";
import Cpp inline '''

template <typename T> struct Box {
  T value;
};

''';

class Pt {
  var x: i32;
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
