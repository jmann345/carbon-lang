// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/class/export/union_by_value.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/class/export/union_by_value.carbon

// PROBE (fork/unions/plan.md §4.B, rev B F-5): an exported Carbon union passed
// BY VALUE into a C++ function. No landed golden exercises a C++ function
// taking an exported Carbon class by value; the hand trace says it works
// (`Carbon::Wide` maps back to the Carbon class through `MapTagType`'s
// `clang_decls` lookup exactly as the by-pointer parameter and the by-value
// return of union.carbon do, and `IsCppThunkRequired` routes the non-simple
// parameter through the same thunk an imported union takes in
// function/import/union.carbon, the callee argument passed by address). If
// the fill instead shows a `SemanticsTodo`, this file is renamed with the
// `fail_` prefix, the residue "exported union passed by value into C++" is
// filed and the gap row stays PARTIAL (§8.6).

// --- by_value_param.carbon
library "[[@TEST_NAME]]";
import Cpp;

union Wide {
  // CHECK:STDERR: by_value_param.carbon:[[@LINE+4]]:7: error: union field `lo` has type `i32`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var lo: i32;
  // CHECK:STDERR:       ^~~~~~~
  // CHECK:STDERR:
  var lo: i32;
  // CHECK:STDERR: by_value_param.carbon:[[@LINE+4]]:7: error: union field `both` has type `i64`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var both: i64;
  // CHECK:STDERR:       ^~~~~~~~~
  // CHECK:STDERR:
  var both: i64;
}

inline Cpp '''
// CHECK:STDERR: by_value_param.carbon:[[@LINE+4]]:38: error: no member named 'lo' in 'Carbon::Wide' [CppInteropParseError]
// CHECK:STDERR:    22 | int SumLo(Carbon::Wide w) { return w.lo + 1; }
// CHECK:STDERR:       |                                    ~ ^
// CHECK:STDERR:
int SumLo(Carbon::Wide w) { return w.lo + 1; }
''';

fn F(w: Wide) -> i32 {
  //@dump-sem-ir-begin
  return Cpp.SumLo(w);
  //@dump-sem-ir-end
}

// CHECK:STDOUT: --- by_value_param.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %Wide: type = class_type @Wide [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %SumLo.cpp_overload_set.type: type = cpp_overload_set_type @SumLo.cpp_overload_set [concrete]
// CHECK:STDOUT:   %SumLo.cpp_overload_set.value: %SumLo.cpp_overload_set.type = cpp_overload_set_value @SumLo.cpp_overload_set [concrete]
// CHECK:STDOUT:   %ptr: type = ptr_type %Wide [concrete]
// CHECK:STDOUT:   %SumLo__carbon_thunk.type: type = fn_type @SumLo__carbon_thunk [concrete]
// CHECK:STDOUT:   %SumLo__carbon_thunk: %SumLo__carbon_thunk.type = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Cpp: <namespace> = namespace file.%Cpp.import_cpp, [concrete] {
// CHECK:STDOUT:     .SumLo = %SumLo.cpp_overload_set.value
// CHECK:STDOUT:     import Cpp//...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %SumLo.cpp_overload_set.value: %SumLo.cpp_overload_set.type = cpp_overload_set_value @SumLo.cpp_overload_set [concrete = constants.%SumLo.cpp_overload_set.value]
// CHECK:STDOUT:   %SumLo__carbon_thunk.decl: %SumLo__carbon_thunk.type = fn_decl @SumLo__carbon_thunk [concrete = constants.%SumLo__carbon_thunk] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @F(%w.param: %Wide) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Cpp.ref: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:   %SumLo.ref: %SumLo.cpp_overload_set.type = name_ref SumLo, imports.%SumLo.cpp_overload_set.value [concrete = constants.%SumLo.cpp_overload_set.value]
// CHECK:STDOUT:   %w.ref: %Wide = name_ref w, %w
// CHECK:STDOUT:   %.loc27: ref %Wide = value_as_ref %w.ref
// CHECK:STDOUT:   %addr: %ptr = addr_of %.loc27
// CHECK:STDOUT:   %SumLo__carbon_thunk.call: init %i32 = call imports.%SumLo__carbon_thunk.decl(%addr)
// CHECK:STDOUT:   return %SumLo__carbon_thunk.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
