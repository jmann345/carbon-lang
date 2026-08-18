// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/function/import/carbon_fn_as_callable.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/function/import/carbon_fn_as_callable.carbon

// The F8d flip of the F8a red baseline for defect TA-D1 (fork/f008/plan.md
// §2.4): a concrete, non-generic Carbon function passed as a C++ callable —
// to a mock thread-like constructor template and to a plain function-pointer
// parameter. The mapping is confined to the call-argument path:
// `InventPrimitiveClangArg` (check/cpp/type_mapping.cpp) maps the function's
// `SemIR::FunctionType` via `TryMapFunctionType` to a pointer to its exported
// declaration's type, the invented argument is an AST-embedded `DeclRefExpr`
// to that declaration with function-to-pointer decay, and the C++ thunk
// embeds the reference instead of taking a runtime parameter
// (check/cpp/thunk.cpp). The general `MapToCppType` still rejects function
// types (export-direction returns/globals keep their "failed to map"
// diagnosis). Generic functions and methods stay diagnosed with
// `CppCallArgTypeNotSupported` — the negative partition (plan §5 R-7) pinned
// by the fail_todo splits below. The two_carbon_fns_one_callee split pins the
// same-signature collision fix: two functions into one callee must import two
// DISTINCT thunk symbols (the `.argN.<mangled>` suffixes differ).

// --- callable.h

struct thread {
  template <typename F> thread(F f);
  void join();
};

void invoke(void (*f)());

// --- carbon_fn_as_callable.carbon

library "[[@TEST_NAME]]";

import Cpp library "callable.h";

fn Work() {}

fn F() {
  //@dump-sem-ir-begin
  // The measured D1 shape, now resolving: the constructor template deduces
  // `F = void(*)()` from the embedded function pointer constant.
  Cpp.thread.thread(Work);

  // The same mapping with no template in sight: a plain function-pointer
  // parameter.
  Cpp.invoke(Work);
  //@dump-sem-ir-end
}

// --- two_carbon_fns_one_callee.carbon

library "[[@TEST_NAME]]";

import Cpp library "callable.h";

fn Work() {}
fn Work2() {}

fn I() {
  //@dump-sem-ir-begin
  // Two SAME-SIGNATURE Carbon functions passed to the SAME C++ callee (one
  // `thread::thread<void(*)()>` instantiation): each import must carry its
  // own thunk — the embedded constant is part of the canonical signature key
  // (`ClangDeclSignature::constant_function_args`) and the thunk's asm label
  // gains the constant's mangled name (`.argN.<mangled>`), so the two dumped
  // thunk symbols below must be DISTINCT. One shared symbol would be the
  // same-signature collision miscompile (two call sites bound to one body).
  Cpp.thread.thread(Work);
  Cpp.thread.thread(Work2);
  //@dump-sem-ir-end
}

// --- fail_todo_generic_fn_as_callable.carbon

library "[[@TEST_NAME]]";

import Cpp library "callable.h";

fn GenericWork(unused generic T: type) {}

fn G() {
  // A generic Carbon function stays unsupported: deduction on an unexported
  // symbol would be a miscompile risk (plan §5 R-7).
  // CHECK:STDERR: fail_todo_generic_fn_as_callable.carbon:[[@LINE+4]]:14: error: call argument of type `<type of GenericWork>` is not supported [CppCallArgTypeNotSupported]
  // CHECK:STDERR:   Cpp.invoke(GenericWork);
  // CHECK:STDERR:              ^~~~~~~~~~~
  // CHECK:STDERR:
  Cpp.invoke(GenericWork);
}

// --- fail_todo_method_as_callable.carbon

library "[[@TEST_NAME]]";

import Cpp library "callable.h";

class Widget {
  fn Get(unused self) {}
}

fn H() {
  // A method value stays unsupported: self-parameter functions (and
  // `FunctionTypeWithSelfType` values) have no function-pointer form
  // (plan §2.4).
  // CHECK:STDERR: fail_todo_method_as_callable.carbon:[[@LINE+4]]:14: error: call argument of type `<type of Get>` is not supported [CppCallArgTypeNotSupported]
  // CHECK:STDERR:   Cpp.invoke(Widget.Get);
  // CHECK:STDERR:              ^~~~~~~~~~
  // CHECK:STDERR:
  Cpp.invoke(Widget.Get);
}

// CHECK:STDOUT: --- carbon_fn_as_callable.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %Work.type: type = fn_type @Work [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %Work: %Work.type = struct_value () [concrete]
// CHECK:STDOUT:   %thread: type = class_type @thread [concrete]
// CHECK:STDOUT:   %thread.thread.cpp_overload_set.type: type = cpp_overload_set_type @thread.thread.cpp_overload_set [concrete]
// CHECK:STDOUT:   %thread.thread.cpp_overload_set.value: %thread.thread.cpp_overload_set.type = cpp_overload_set_value @thread.thread.cpp_overload_set [concrete]
// CHECK:STDOUT:   %ptr.16e: type = ptr_type %thread [concrete]
// CHECK:STDOUT:   %thread__carbon_thunk.type: type = fn_type @thread__carbon_thunk [concrete]
// CHECK:STDOUT:   %thread__carbon_thunk: %thread__carbon_thunk.type = struct_value () [concrete]
// CHECK:STDOUT:   %thread.cpp_destructor.type: type = fn_type @thread.cpp_destructor [concrete]
// CHECK:STDOUT:   %thread.cpp_destructor: %thread.cpp_destructor.type = struct_value () [concrete]
// CHECK:STDOUT:   %invoke.cpp_overload_set.type: type = cpp_overload_set_type @invoke.cpp_overload_set [concrete]
// CHECK:STDOUT:   %invoke.cpp_overload_set.value: %invoke.cpp_overload_set.type = cpp_overload_set_value @invoke.cpp_overload_set [concrete]
// CHECK:STDOUT:   %invoke__carbon_thunk.type: type = fn_type @invoke__carbon_thunk [concrete]
// CHECK:STDOUT:   %invoke__carbon_thunk: %invoke__carbon_thunk.type = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Cpp: <namespace> = namespace file.%Cpp.import_cpp, [concrete] {
// CHECK:STDOUT:     .thread = %thread.decl
// CHECK:STDOUT:     .invoke = %invoke.cpp_overload_set.value
// CHECK:STDOUT:     import Cpp//...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %thread.decl: type = class_decl @thread [concrete = constants.%thread] {} {}
// CHECK:STDOUT:   %thread.thread.cpp_overload_set.value: %thread.thread.cpp_overload_set.type = cpp_overload_set_value @thread.thread.cpp_overload_set [concrete = constants.%thread.thread.cpp_overload_set.value]
// CHECK:STDOUT:   %thread__carbon_thunk.decl: %thread__carbon_thunk.type = fn_decl @thread__carbon_thunk [concrete = constants.%thread__carbon_thunk] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %invoke.cpp_overload_set.value: %invoke.cpp_overload_set.type = cpp_overload_set_value @invoke.cpp_overload_set [concrete = constants.%invoke.cpp_overload_set.value]
// CHECK:STDOUT:   %invoke__carbon_thunk.decl: %invoke__carbon_thunk.type = fn_decl @invoke__carbon_thunk [concrete = constants.%invoke__carbon_thunk] {} {}
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @F() {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Cpp.ref.loc12: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:   %thread.ref.loc12_6: type = name_ref thread, imports.%thread.decl [concrete = constants.%thread]
// CHECK:STDOUT:   %thread.ref.loc12_13: %thread.thread.cpp_overload_set.type = name_ref thread, imports.%thread.thread.cpp_overload_set.value [concrete = constants.%thread.thread.cpp_overload_set.value]
// CHECK:STDOUT:   %Work.ref.loc12: %Work.type = name_ref Work, file.%Work.decl [concrete = constants.%Work]
// CHECK:STDOUT:   %.loc12_25.1: ref %thread = temporary_storage
// CHECK:STDOUT:   %addr: %ptr.16e = addr_of %.loc12_25.1
// CHECK:STDOUT:   %thread__carbon_thunk.call: init %empty_tuple.type = call imports.%thread__carbon_thunk.decl(%addr)
// CHECK:STDOUT:   %.loc12_25.2: init %thread to %.loc12_25.1 = mark_in_place_init %thread__carbon_thunk.call
// CHECK:STDOUT:   %.loc12_25.3: ref %thread = temporary %.loc12_25.1, %.loc12_25.2
// CHECK:STDOUT:   %thread.cpp_destructor.bound: <bound method> = bound_method %.loc12_25.3, constants.%thread.cpp_destructor
// CHECK:STDOUT:   %thread.cpp_destructor.call: init %empty_tuple.type = call %thread.cpp_destructor.bound(%.loc12_25.3)
// CHECK:STDOUT:   %Cpp.ref.loc16: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:   %invoke.ref: %invoke.cpp_overload_set.type = name_ref invoke, imports.%invoke.cpp_overload_set.value [concrete = constants.%invoke.cpp_overload_set.value]
// CHECK:STDOUT:   %Work.ref.loc16: %Work.type = name_ref Work, file.%Work.decl [concrete = constants.%Work]
// CHECK:STDOUT:   %invoke__carbon_thunk.call: init %empty_tuple.type = call imports.%invoke__carbon_thunk.decl()
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- two_carbon_fns_one_callee.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %Work.type: type = fn_type @Work [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %Work: %Work.type = struct_value () [concrete]
// CHECK:STDOUT:   %Work2.type: type = fn_type @Work2 [concrete]
// CHECK:STDOUT:   %Work2: %Work2.type = struct_value () [concrete]
// CHECK:STDOUT:   %thread: type = class_type @thread [concrete]
// CHECK:STDOUT:   %thread.thread.cpp_overload_set.type: type = cpp_overload_set_type @thread.thread.cpp_overload_set [concrete]
// CHECK:STDOUT:   %thread.thread.cpp_overload_set.value: %thread.thread.cpp_overload_set.type = cpp_overload_set_value @thread.thread.cpp_overload_set [concrete]
// CHECK:STDOUT:   %ptr.16e: type = ptr_type %thread [concrete]
// CHECK:STDOUT:   %thread__carbon_thunk.type.86c9ca.1: type = fn_type @thread__carbon_thunk.1 [concrete]
// CHECK:STDOUT:   %thread__carbon_thunk.917f73.1: %thread__carbon_thunk.type.86c9ca.1 = struct_value () [concrete]
// CHECK:STDOUT:   %thread.cpp_destructor.type: type = fn_type @thread.cpp_destructor [concrete]
// CHECK:STDOUT:   %thread.cpp_destructor: %thread.cpp_destructor.type = struct_value () [concrete]
// CHECK:STDOUT:   %thread__carbon_thunk.type.86c9ca.2: type = fn_type @thread__carbon_thunk.2 [concrete]
// CHECK:STDOUT:   %thread__carbon_thunk.917f73.2: %thread__carbon_thunk.type.86c9ca.2 = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Cpp: <namespace> = namespace file.%Cpp.import_cpp, [concrete] {
// CHECK:STDOUT:     .thread = %thread.decl
// CHECK:STDOUT:     import Cpp//...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %thread.decl: type = class_decl @thread [concrete = constants.%thread] {} {}
// CHECK:STDOUT:   %thread.thread.cpp_overload_set.value: %thread.thread.cpp_overload_set.type = cpp_overload_set_value @thread.thread.cpp_overload_set [concrete = constants.%thread.thread.cpp_overload_set.value]
// CHECK:STDOUT:   %thread__carbon_thunk.decl.17608b.1: %thread__carbon_thunk.type.86c9ca.1 = fn_decl @thread__carbon_thunk.1 [concrete = constants.%thread__carbon_thunk.917f73.1] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %thread__carbon_thunk.decl.17608b.2: %thread__carbon_thunk.type.86c9ca.2 = fn_decl @thread__carbon_thunk.2 [concrete = constants.%thread__carbon_thunk.917f73.2] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @I() {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Cpp.ref.loc18: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:   %thread.ref.loc18_6: type = name_ref thread, imports.%thread.decl [concrete = constants.%thread]
// CHECK:STDOUT:   %thread.ref.loc18_13: %thread.thread.cpp_overload_set.type = name_ref thread, imports.%thread.thread.cpp_overload_set.value [concrete = constants.%thread.thread.cpp_overload_set.value]
// CHECK:STDOUT:   %Work.ref: %Work.type = name_ref Work, file.%Work.decl [concrete = constants.%Work]
// CHECK:STDOUT:   %.loc18_25.1: ref %thread = temporary_storage
// CHECK:STDOUT:   %addr.loc18: %ptr.16e = addr_of %.loc18_25.1
// CHECK:STDOUT:   %thread__carbon_thunk.call.loc18: init %empty_tuple.type = call imports.%thread__carbon_thunk.decl.17608b.1(%addr.loc18)
// CHECK:STDOUT:   %.loc18_25.2: init %thread to %.loc18_25.1 = mark_in_place_init %thread__carbon_thunk.call.loc18
// CHECK:STDOUT:   %.loc18_25.3: ref %thread = temporary %.loc18_25.1, %.loc18_25.2
// CHECK:STDOUT:   %thread.cpp_destructor.bound.loc18: <bound method> = bound_method %.loc18_25.3, constants.%thread.cpp_destructor
// CHECK:STDOUT:   %thread.cpp_destructor.call.loc18: init %empty_tuple.type = call %thread.cpp_destructor.bound.loc18(%.loc18_25.3)
// CHECK:STDOUT:   %Cpp.ref.loc19: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:   %thread.ref.loc19_6: type = name_ref thread, imports.%thread.decl [concrete = constants.%thread]
// CHECK:STDOUT:   %thread.ref.loc19_13: %thread.thread.cpp_overload_set.type = name_ref thread, imports.%thread.thread.cpp_overload_set.value [concrete = constants.%thread.thread.cpp_overload_set.value]
// CHECK:STDOUT:   %Work2.ref: %Work2.type = name_ref Work2, file.%Work2.decl [concrete = constants.%Work2]
// CHECK:STDOUT:   %.loc19_26.1: ref %thread = temporary_storage
// CHECK:STDOUT:   %addr.loc19: %ptr.16e = addr_of %.loc19_26.1
// CHECK:STDOUT:   %thread__carbon_thunk.call.loc19: init %empty_tuple.type = call imports.%thread__carbon_thunk.decl.17608b.2(%addr.loc19)
// CHECK:STDOUT:   %.loc19_26.2: init %thread to %.loc19_26.1 = mark_in_place_init %thread__carbon_thunk.call.loc19
// CHECK:STDOUT:   %.loc19_26.3: ref %thread = temporary %.loc19_26.1, %.loc19_26.2
// CHECK:STDOUT:   %thread.cpp_destructor.bound.loc19: <bound method> = bound_method %.loc19_26.3, constants.%thread.cpp_destructor
// CHECK:STDOUT:   %thread.cpp_destructor.call.loc19: init %empty_tuple.type = call %thread.cpp_destructor.bound.loc19(%.loc19_26.3)
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT: }
// CHECK:STDOUT:
