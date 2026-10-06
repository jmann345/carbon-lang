// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/int.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/function/export/carbon_namespace_cpp_class.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/function/export/carbon_namespace_cpp_class.carbon

// A C++-declared class nested in `namespace Carbon` — the toolchain's export
// namespace, whose name lookup is answered by the Carbon external AST source
// (toolchain/check/cpp/generate_ast.cpp) — with an inline member function and
// a constructor. Their declarators run Clang's unqualified redeclaration
// lookup up through the namespace, so the external source is asked about the
// NAMESPACE with a constructor name (not a class) and with member names no
// Carbon entity has; it must answer "no external declarations", never crash
// (the shape `<carbon/expected.h>`'s `unexpected(E)` reaches, EH-B conformance
// run 36311899697). Prediction: the file compiles cleanly; the dumped SemIR is
// the plain call `Cpp.Use()` through `Use`'s fenced thunk, and `Carbon::F` is
// exported and called from inside the same block.

// --- carbon_namespace_cpp_class.carbon

library "[[@TEST_NAME]]";

import Cpp;

fn F(n: i32) -> i32 { return n; }

inline Cpp '''
namespace Carbon {
struct Holder {
  int v;
  int get() const { return v; }
  Holder(int n) : v(n) {}
};
}  // namespace Carbon

inline int Use() { return Carbon::Holder(Carbon::F(1)).get(); }
''';

//@dump-sem-ir-begin
fn G() -> i32 { return Cpp.Use(); }
//@dump-sem-ir-end

// CHECK:STDOUT: --- carbon_namespace_cpp_class.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %.795: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %G.type: type = fn_type @G [concrete]
// CHECK:STDOUT:   %G: %G.type = struct_value () [concrete]
// CHECK:STDOUT:   %Use.cpp_overload_set.type: type = cpp_overload_set_type @Use.cpp_overload_set [concrete]
// CHECK:STDOUT:   %Use.cpp_overload_set.value: %Use.cpp_overload_set.type = cpp_overload_set_value @Use.cpp_overload_set [concrete]
// CHECK:STDOUT:   %Use__carbon_thunk.type: type = fn_type @Use__carbon_thunk [concrete]
// CHECK:STDOUT:   %Use__carbon_thunk: %Use__carbon_thunk.type = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Cpp: <namespace> = namespace file.%Cpp.import_cpp, [concrete] {
// CHECK:STDOUT:     .Use = %Use.cpp_overload_set.value
// CHECK:STDOUT:     import Cpp//...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Use.cpp_overload_set.value: %Use.cpp_overload_set.type = cpp_overload_set_value @Use.cpp_overload_set [concrete = constants.%Use.cpp_overload_set.value]
// CHECK:STDOUT:   %Use__carbon_thunk.decl: %Use__carbon_thunk.type = fn_decl @Use__carbon_thunk [concrete = constants.%Use__carbon_thunk] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %G.decl: %G.type = fn_decl @G [concrete = constants.%G] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc21: Core.Form = init_form %i32 [concrete = constants.%.795]
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param0
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @G() -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Cpp.ref: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:   %Use.ref: %Use.cpp_overload_set.type = name_ref Use, imports.%Use.cpp_overload_set.value [concrete = constants.%Use.cpp_overload_set.value]
// CHECK:STDOUT:   %Use__carbon_thunk.call: init %i32 = call imports.%Use__carbon_thunk.decl()
// CHECK:STDOUT:   return %Use__carbon_thunk.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
