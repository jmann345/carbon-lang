// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: C++ interop — exporting Carbon templates/checked generics as C++ templates
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   34
//
// The bullet's working slice: a type-parameter checked generic exported as a
// C++ function template (check/cpp/export.cpp, ExportGenericFunctionToCpp
// creates a clang::FunctionTemplateDecl). Shape verbatim from the check+lower
// testdata interop/cpp/function/export/generic.carbon
// (generic_type_impls_interface: `fn F[T: I](t: T)` called as `Carbon::F(a)`
// / `Carbon::F(b)` from inline C++). C++ instantiates the exported template
// on two different Carbon classes; each specialization dispatches through
// that class's interface impl. Results flow out via an `i32*` out-param
// because the export path only supports void-returning generics on this
// toolchain: BuildCppFunctionDeclForCarbonFn CARBON_CHECKs
// `function.return_type_inst_id == SemIR::TypeInstId::None` and a `-> i32`
// generic crashes the nightly 2026.07.19 compiler (verified).

import Core library "io";
import Cpp;

interface HasId {
  fn Id(self) -> i32;
}

class A {
  impl as HasId {
    fn Id(unused self) -> i32 { return 3; }
  }
}
class B {
  impl as HasId {
    fn Id(unused self) -> i32 { return 4; }
  }
}

fn StoreId[T: HasId](t: T, out: i32*) {
  *out = t.Id();
}

inline Cpp '''
auto UseIds() -> int {
  Carbon::A a;
  Carbon::B b;
  int ra = 0;
  int rb = 0;
  Carbon::StoreId(a, &ra);
  Carbon::StoreId(b, &rb);
  return ra * 10 + rb;
}
''';

fn Run() -> i32 {
  Core.Print(Cpp.UseIds());
  return 0;
}
