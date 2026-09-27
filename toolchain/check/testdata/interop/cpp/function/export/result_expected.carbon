// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/function/export/result_expected.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/function/export/result_expected.carbon

// Exporting a `Core.Result(T, E)`-returning Carbon function to C++
// (docs/design/error_handling.md, "Exporting fallible Carbon functions:
// `Carbon::expected`"; fork/eh/plan.md §1.B.5-1.B.7, §4.B): the return type
// maps to the class template `Carbon::expected<T', E'>` found BY NAME in the
// TU. Goldens never include the installed `<carbon/expected.h>` (file_test's
// data are the clang headers only), so each split declares a local
// layout-compatible skeleton in its inline C++ — the skeleton needs no
// methods, the golden pins the export mapping, not C++ semantics.
// `fail_no_header` has no skeleton and gets the header-required diagnostic.

// --- result_expected.carbon

library "[[@TEST_NAME]]";

import Cpp;

fn F(n: i32) -> Core.Result(i32, i32) {
  if (n < 0) { return Core.Result(i32, i32).Err(n); }
  return Core.Result(i32, i32).Ok(n);
}

inline Cpp '''
namespace Carbon {
template <typename T, typename E>
struct expected {
  unsigned char disc;
  union {
    T ok;
    E err;
  };
};
template <typename E>
struct expected<void, E> {
  unsigned char disc;
  union {
    E err;
  };
};
struct Exception {
  void* p;
};
}  // namespace Carbon

inline int Use() { return Carbon::F(1).disc; }
''';

//@dump-sem-ir-begin
fn G() -> i32 { return Cpp.Use(); }
//@dump-sem-ir-end

// --- void_success.carbon

library "[[@TEST_NAME]]";

import Cpp;

fn U(n: i32) -> Core.Result((), i32) {
  if (n < 0) { return Core.Result((), i32).Err(n); }
  return Core.Result((), i32).Ok(());
}

inline Cpp '''
namespace Carbon {
template <typename T, typename E>
struct expected {
  unsigned char disc;
  union {
    T ok;
    E err;
  };
};
template <typename E>
struct expected<void, E> {
  unsigned char disc;
  union {
    E err;
  };
};
}  // namespace Carbon

// `Core.Result((), i32)` maps to `Carbon::expected<void, int>`.
inline int UseUnit() { return Carbon::U(1).disc; }
''';

//@dump-sem-ir-begin
fn G() -> i32 { return Cpp.UseUnit(); }
//@dump-sem-ir-end

// --- exception_error.carbon

library "[[@TEST_NAME]]";

import Cpp;

fn X() -> Core.Result(i32, Cpp.Exception) {
  return Core.Result(i32, Cpp.Exception).Ok(1);
}

inline Cpp '''
namespace Carbon {
template <typename T, typename E>
struct expected {
  unsigned char disc;
  union {
    T ok;
    E err;
  };
};
struct Exception {
  void* p;
};
}  // namespace Carbon

// `Core.Result(i32, Cpp.Exception)` maps to
// `Carbon::expected<int, Carbon::Exception>`.
inline int UseX() { return Carbon::X().disc; }
''';

//@dump-sem-ir-begin
fn G() -> i32 { return Cpp.UseX(); }
//@dump-sem-ir-end

// --- fail_no_header.carbon

library "[[@TEST_NAME]]";

import Cpp;

// CHECK:STDERR: fail_no_header.carbon:[[@LINE+4]]:1: error: exporting `Core.Result(i32, i32)` to C++ requires `#include <carbon/expected.h>` in the C++ code [CppExportResultNeedsExpectedHeader]
// CHECK:STDERR: fn F(n: i32) -> Core.Result(i32, i32) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn F(n: i32) -> Core.Result(i32, i32) {
  return Core.Result(i32, i32).Ok(n);
}

inline Cpp '''
// CHECK:STDERR: fail_no_header.carbon:[[@LINE+4]]:35: error: no member named 'F' in namespace 'Carbon' [CppInteropParseError]
// CHECK:STDERR:    11 | inline int Use() { return Carbon::F(1).disc; }
// CHECK:STDERR:       |                                   ^
// CHECK:STDERR:
inline int Use() { return Carbon::F(1).disc; }
''';

// CHECK:STDOUT: --- result_expected.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
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
// CHECK:STDOUT:     %.loc37: Core.Form = init_form %i32 [concrete = constants.%.795f]
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
// CHECK:STDOUT: --- void_success.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %G.type: type = fn_type @G [concrete]
// CHECK:STDOUT:   %G: %G.type = struct_value () [concrete]
// CHECK:STDOUT:   %UseUnit.cpp_overload_set.type: type = cpp_overload_set_type @UseUnit.cpp_overload_set [concrete]
// CHECK:STDOUT:   %UseUnit.cpp_overload_set.value: %UseUnit.cpp_overload_set.type = cpp_overload_set_value @UseUnit.cpp_overload_set [concrete]
// CHECK:STDOUT:   %UseUnit__carbon_thunk.type: type = fn_type @UseUnit__carbon_thunk [concrete]
// CHECK:STDOUT:   %UseUnit__carbon_thunk: %UseUnit__carbon_thunk.type = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Cpp: <namespace> = namespace file.%Cpp.import_cpp, [concrete] {
// CHECK:STDOUT:     .UseUnit = %UseUnit.cpp_overload_set.value
// CHECK:STDOUT:     import Cpp//...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %UseUnit.cpp_overload_set.value: %UseUnit.cpp_overload_set.type = cpp_overload_set_value @UseUnit.cpp_overload_set [concrete = constants.%UseUnit.cpp_overload_set.value]
// CHECK:STDOUT:   %UseUnit__carbon_thunk.decl: %UseUnit__carbon_thunk.type = fn_decl @UseUnit__carbon_thunk [concrete = constants.%UseUnit__carbon_thunk] {
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
// CHECK:STDOUT:     %.loc35: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param0
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @G() -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Cpp.ref: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:   %UseUnit.ref: %UseUnit.cpp_overload_set.type = name_ref UseUnit, imports.%UseUnit.cpp_overload_set.value [concrete = constants.%UseUnit.cpp_overload_set.value]
// CHECK:STDOUT:   %UseUnit__carbon_thunk.call: init %i32 = call imports.%UseUnit__carbon_thunk.decl()
// CHECK:STDOUT:   return %UseUnit__carbon_thunk.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- exception_error.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %Cpp.Exception: type = class_type @Exception [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %G.type: type = fn_type @G [concrete]
// CHECK:STDOUT:   %G: %G.type = struct_value () [concrete]
// CHECK:STDOUT:   %UseX.cpp_overload_set.type: type = cpp_overload_set_type @UseX.cpp_overload_set [concrete]
// CHECK:STDOUT:   %UseX.cpp_overload_set.value: %UseX.cpp_overload_set.type = cpp_overload_set_value @UseX.cpp_overload_set [concrete]
// CHECK:STDOUT:   %UseX__carbon_thunk.type: type = fn_type @UseX__carbon_thunk [concrete]
// CHECK:STDOUT:   %UseX__carbon_thunk: %UseX__carbon_thunk.type = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Cpp: <namespace> = namespace file.%Cpp.import_cpp, [concrete] {
// CHECK:STDOUT:     .Exception = constants.%Cpp.Exception
// CHECK:STDOUT:     .UseX = %UseX.cpp_overload_set.value
// CHECK:STDOUT:     import Cpp//...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %UseX.cpp_overload_set.value: %UseX.cpp_overload_set.type = cpp_overload_set_value @UseX.cpp_overload_set [concrete = constants.%UseX.cpp_overload_set.value]
// CHECK:STDOUT:   %UseX__carbon_thunk.decl: %UseX__carbon_thunk.type = fn_decl @UseX__carbon_thunk [concrete = constants.%UseX__carbon_thunk] {
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
// CHECK:STDOUT:     %.loc31: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param0
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @G() -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Cpp.ref: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:   %UseX.ref: %UseX.cpp_overload_set.type = name_ref UseX, imports.%UseX.cpp_overload_set.value [concrete = constants.%UseX.cpp_overload_set.value]
// CHECK:STDOUT:   %UseX__carbon_thunk.call: init %i32 = call imports.%UseX__carbon_thunk.decl()
// CHECK:STDOUT:   return %UseX__carbon_thunk.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
