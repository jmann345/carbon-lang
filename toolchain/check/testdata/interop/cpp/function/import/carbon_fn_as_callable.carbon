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

// A concrete, non-generic Carbon function passed as a C++ callable — to a
// mock thread-like constructor template and to a plain function-pointer
// parameter (defect TA-D1, fork/f008/plan.md §2.4; fixed by F8d, whose
// embedding was retired for upstream's mechanism at UA-1, fork/upstream/
// plan.md D-UA-8). The call-argument path (`InventPrimitiveClangArg`,
// check/cpp/type_mapping.cpp) maps the function's `SemIR::FunctionType` to a
// `_Nonnull` pointer to its exported declaration's C++ function type
// (`TryMapType`), overload resolution deduces on it, and the chosen
// parameter's conversion (`ExportFunctionToCppPointerConversion`,
// check/cpp/export.cpp) passes the function pointer as a runtime argument
// (`CppAddrOfFunction`). Generic functions stay unsupported on both paths:
// they export as a `clang::FunctionTemplateDecl`, which has no function type
// to point to, so `TryMapType` maps them to a null type (the call argument is
// diagnosed `CppCallArgTypeNotSupported`) and the conversion path emits a
// semantics TODO — the fail_todo splits below pin both (the first was the
// UA-1 fill crash, run 37385396872: upstream's arm called
// `getPointerType(null)` on the template's null function type). Method
// values are mapped to member pointers by upstream (#7881), so passing one to
// a function-pointer parameter is rejected by C++ overload resolution; its
// split pins that diagnosis.

// --- callable.h

struct thread {
  template <typename F> thread(F f);
  void join();
};

void invoke(void (*f)());

using Callback = void (*)();

// --- carbon_fn_as_callable.carbon

library "[[@TEST_NAME]]";

import Cpp library "callable.h";

fn Work() {}

fn F() {
  //@dump-sem-ir-begin
  // The measured D1 shape: the constructor template deduces `F = void(*)()`
  // from the `_Nonnull` function-pointer argument type.
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
  // `thread::thread<void(*)()>` instantiation). The function pointer crosses
  // the boundary as a runtime argument (`CppAddrOfFunction`), so the two
  // calls share one imported callee and one thunk; the pointer values below
  // must still name the two DISTINCT Carbon functions. (F8d's embedding
  // instead needed two thunk symbols, `.argN.<mangled>`-suffixed; that
  // collision class is gone by construction with D-UA-8.)
  Cpp.thread.thread(Work);
  Cpp.thread.thread(Work2);
  //@dump-sem-ir-end
}

// --- fail_todo_generic_fn_as_callable.carbon

library "[[@TEST_NAME]]";

import Cpp library "callable.h";

fn GenericWork(unused generic T: type) {}

fn G() {
  // A generic Carbon function stays unsupported: it exports as a function
  // template, which has no function-pointer form, so the argument type maps
  // to null and is diagnosed here rather than deduced on (plan §5 R-7). This
  // is the UA-1 fill crash shape (run 37385396872).
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
  // A method value maps to a pointer to member function (upstream #7881),
  // which does not convert to the function-pointer parameter: the call is
  // rejected by C++ overload resolution rather than by the type mapping.
  // CHECK:STDERR: fail_todo_method_as_callable.carbon:[[@LINE+8]]:24: error: no matching function for call to 'invoke' [CppInteropParseError]
  // CHECK:STDERR:    22 |   Cpp.invoke(Widget.Get);
  // CHECK:STDERR:       |                        ^
  // CHECK:STDERR: fail_todo_method_as_callable.carbon:[[@LINE-13]]:10: in file included here [InCppInclude]
  // CHECK:STDERR: ./callable.h:7:6: note: candidate function not viable: no known conversion from 'void (Carbon::Widget::* _Nonnull)() const' to 'void (*)()' for 1st argument [CppInteropParseNote]
  // CHECK:STDERR:     7 | void invoke(void (*f)());
  // CHECK:STDERR:       |      ^      ~~~~~~~~~~~
  // CHECK:STDERR:
  Cpp.invoke(Widget.Get);
}

// --- fail_todo_generic_fn_to_fn_ptr.carbon

library "[[@TEST_NAME]]";

import Cpp library "callable.h";

fn GenericWork(unused generic T: type) {}

fn J() {
  // The conversion path for the same generic function: its export is a
  // function template, which has no function type to point to, so the
  // conversion is diagnosed (a semantics TODO) instead of asserting.
  // CHECK:STDERR: fail_todo_generic_fn_to_fn_ptr.carbon:[[@LINE+4]]:32: error: semantics TODO: `can't convert generic function to a C++ function pointer` [SemanticsTodo]
  // CHECK:STDERR:   var unused p: Cpp.Callback = GenericWork;
  // CHECK:STDERR:                                ^~~~~~~~~~~
  // CHECK:STDERR:
  var unused p: Cpp.Callback = GenericWork;
}

// CHECK:STDOUT: --- carbon_fn_as_callable.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %Work.type: type = fn_type @Work [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %Work: %Work.type = struct_value () [concrete]
// CHECK:STDOUT:   %thread: type = class_type @thread [concrete]
// CHECK:STDOUT:   %thread.thread.cpp_overload_set.type: type = cpp_overload_set_type @thread.thread.cpp_overload_set [concrete]
// CHECK:STDOUT:   %thread.thread.cpp_overload_set.value: %thread.thread.cpp_overload_set.type = cpp_overload_set_value @thread.thread.cpp_overload_set [concrete]
// CHECK:STDOUT:   %.659: type = cpp_fn_ptr_type clang_function_pointer_type49000000 [concrete]
// CHECK:STDOUT:   %pattern_type.0d0: type = pattern_type %thread [concrete]
// CHECK:STDOUT:   %ptr.16e: type = ptr_type %thread [concrete]
// CHECK:STDOUT:   %thread__carbon_thunk.type: type = fn_type @thread__carbon_thunk [concrete]
// CHECK:STDOUT:   %thread__carbon_thunk: %thread__carbon_thunk.type = struct_value () [concrete]
// CHECK:STDOUT:   %.bdc: %.659 = cpp_addr_of_fn %Work, @Work [concrete]
// CHECK:STDOUT:   %self.param_patt.66c: %pattern_type.0d0 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.981: %pattern_type.0d0 = wrapper_binding_pattern self, %self.param_patt.66c [concrete]
// CHECK:STDOUT:   %thread.cpp_destructor.type: type = fn_type @thread.cpp_destructor [concrete]
// CHECK:STDOUT:   %thread.cpp_destructor: %thread.cpp_destructor.type = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef0: type = fn_type @Destroy.WithSelf.Op.loc12 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403: %Destroy.WithSelf.Op.type.ef0 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbc: type = fn_type @Destroy.WithSelf.SelfDestruct.loc12 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3: %Destroy.WithSelf.SelfDestruct.type.fbc = struct_value () [concrete]
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
// CHECK:STDOUT:   %thread.cpp_destructor.decl: %thread.cpp_destructor.type = fn_decl @thread.cpp_destructor [concrete = constants.%thread.cpp_destructor] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %invoke.cpp_overload_set.value: %invoke.cpp_overload_set.type = cpp_overload_set_value @invoke.cpp_overload_set [concrete = constants.%invoke.cpp_overload_set.value]
// CHECK:STDOUT:   %invoke__carbon_thunk.decl: %invoke__carbon_thunk.type = fn_decl @invoke__carbon_thunk [concrete = constants.%invoke__carbon_thunk] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl: %Destroy.WithSelf.Op.type.ef0 = fn_decl @Destroy.WithSelf.Op.loc12 [concrete = constants.%Destroy.WithSelf.Op.403] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.0d0 = ref_param_pattern [concrete = constants.%self.param_patt.66c]
// CHECK:STDOUT:     %self.patt: %pattern_type.0d0 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.981]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %thread = ref_param call_param0
// CHECK:STDOUT:     %self: ref %thread = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @F() {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Cpp.ref.loc12: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:   %thread.ref.loc12_6: type = name_ref thread, imports.%thread.decl [concrete = constants.%thread]
// CHECK:STDOUT:   %thread.ref.loc12_13: %thread.thread.cpp_overload_set.type = name_ref thread, imports.%thread.thread.cpp_overload_set.value [concrete = constants.%thread.thread.cpp_overload_set.value]
// CHECK:STDOUT:   %Work.ref.loc12: %Work.type = name_ref Work, file.%Work.decl [concrete = constants.%Work]
// CHECK:STDOUT:   %.loc12_25.1: ref %thread = temporary_storage
// CHECK:STDOUT:   %.loc12_21.1: %.659 = cpp_addr_of_fn %Work.ref.loc12, @Work [concrete = constants.%.bdc]
// CHECK:STDOUT:   %.loc12_21.2: %.659 = converted %Work.ref.loc12, %.loc12_21.1 [concrete = constants.%.bdc]
// CHECK:STDOUT:   %addr: %ptr.16e = addr_of %.loc12_25.1
// CHECK:STDOUT:   %thread__carbon_thunk.call: init %empty_tuple.type = call imports.%thread__carbon_thunk.decl(%.loc12_21.2, %addr)
// CHECK:STDOUT:   %.loc12_25.2: init %thread to %.loc12_25.1 = mark_in_place_init %thread__carbon_thunk.call
// CHECK:STDOUT:   %.loc12_25.3: ref %thread = temporary %.loc12_25.1, %.loc12_25.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound: <bound method> = bound_method %.loc12_25.3, constants.%Destroy.WithSelf.SelfDestruct.db3
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound(%.loc12_25.3)
// CHECK:STDOUT:   %Cpp.ref.loc16: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:   %invoke.ref: %invoke.cpp_overload_set.type = name_ref invoke, imports.%invoke.cpp_overload_set.value [concrete = constants.%invoke.cpp_overload_set.value]
// CHECK:STDOUT:   %Work.ref.loc16: %Work.type = name_ref Work, file.%Work.decl [concrete = constants.%Work]
// CHECK:STDOUT:   %.loc16_14.1: %.659 = cpp_addr_of_fn %Work.ref.loc16, @Work [concrete = constants.%.bdc]
// CHECK:STDOUT:   %.loc16_14.2: %.659 = converted %Work.ref.loc16, %.loc16_14.1 [concrete = constants.%.bdc]
// CHECK:STDOUT:   %invoke__carbon_thunk.call: init %empty_tuple.type = call imports.%invoke__carbon_thunk.decl(%.loc16_14.2)
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc12(%self.param: ref %thread) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc12(%self.param: ref %thread) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl(%self.param)
// CHECK:STDOUT:   %thread.cpp_destructor.call: init %empty_tuple.type = call imports.%thread.cpp_destructor.decl(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- two_carbon_fns_one_callee.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %Work.type: type = fn_type @Work [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %Work: %Work.type = struct_value () [concrete]
// CHECK:STDOUT:   %Work2.type: type = fn_type @Work2 [concrete]
// CHECK:STDOUT:   %Work2: %Work2.type = struct_value () [concrete]
// CHECK:STDOUT:   %thread: type = class_type @thread [concrete]
// CHECK:STDOUT:   %thread.thread.cpp_overload_set.type: type = cpp_overload_set_type @thread.thread.cpp_overload_set [concrete]
// CHECK:STDOUT:   %thread.thread.cpp_overload_set.value: %thread.thread.cpp_overload_set.type = cpp_overload_set_value @thread.thread.cpp_overload_set [concrete]
// CHECK:STDOUT:   %.659: type = cpp_fn_ptr_type clang_function_pointer_type69000000 [concrete]
// CHECK:STDOUT:   %pattern_type.0d0: type = pattern_type %thread [concrete]
// CHECK:STDOUT:   %ptr.16e: type = ptr_type %thread [concrete]
// CHECK:STDOUT:   %thread__carbon_thunk.type: type = fn_type @thread__carbon_thunk [concrete]
// CHECK:STDOUT:   %thread__carbon_thunk: %thread__carbon_thunk.type = struct_value () [concrete]
// CHECK:STDOUT:   %.bdc: %.659 = cpp_addr_of_fn %Work, @Work [concrete]
// CHECK:STDOUT:   %self.param_patt.66c: %pattern_type.0d0 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.981: %pattern_type.0d0 = wrapper_binding_pattern self, %self.param_patt.66c [concrete]
// CHECK:STDOUT:   %thread.cpp_destructor.type: type = fn_type @thread.cpp_destructor [concrete]
// CHECK:STDOUT:   %thread.cpp_destructor: %thread.cpp_destructor.type = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef0: type = fn_type @Destroy.WithSelf.Op.loc18 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403: %Destroy.WithSelf.Op.type.ef0 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbc: type = fn_type @Destroy.WithSelf.SelfDestruct.loc18 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3: %Destroy.WithSelf.SelfDestruct.type.fbc = struct_value () [concrete]
// CHECK:STDOUT:   %.c6f: %.659 = cpp_addr_of_fn %Work2, @Work2 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Cpp: <namespace> = namespace file.%Cpp.import_cpp, [concrete] {
// CHECK:STDOUT:     .thread = %thread.decl
// CHECK:STDOUT:     import Cpp//...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %thread.decl: type = class_decl @thread [concrete = constants.%thread] {} {}
// CHECK:STDOUT:   %thread.thread.cpp_overload_set.value: %thread.thread.cpp_overload_set.type = cpp_overload_set_value @thread.thread.cpp_overload_set [concrete = constants.%thread.thread.cpp_overload_set.value]
// CHECK:STDOUT:   %thread__carbon_thunk.decl: %thread__carbon_thunk.type = fn_decl @thread__carbon_thunk [concrete = constants.%thread__carbon_thunk] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %thread.cpp_destructor.decl: %thread.cpp_destructor.type = fn_decl @thread.cpp_destructor [concrete = constants.%thread.cpp_destructor] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl: %Destroy.WithSelf.Op.type.ef0 = fn_decl @Destroy.WithSelf.Op.loc18 [concrete = constants.%Destroy.WithSelf.Op.403] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.0d0 = ref_param_pattern [concrete = constants.%self.param_patt.66c]
// CHECK:STDOUT:     %self.patt: %pattern_type.0d0 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.981]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %thread = ref_param call_param0
// CHECK:STDOUT:     %self: ref %thread = wrapper_binding self, %self.param
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
// CHECK:STDOUT:   %.loc18_21.1: %.659 = cpp_addr_of_fn %Work.ref, @Work [concrete = constants.%.bdc]
// CHECK:STDOUT:   %.loc18_21.2: %.659 = converted %Work.ref, %.loc18_21.1 [concrete = constants.%.bdc]
// CHECK:STDOUT:   %addr.loc18: %ptr.16e = addr_of %.loc18_25.1
// CHECK:STDOUT:   %thread__carbon_thunk.call.loc18: init %empty_tuple.type = call imports.%thread__carbon_thunk.decl(%.loc18_21.2, %addr.loc18)
// CHECK:STDOUT:   %.loc18_25.2: init %thread to %.loc18_25.1 = mark_in_place_init %thread__carbon_thunk.call.loc18
// CHECK:STDOUT:   %.loc18_25.3: ref %thread = temporary %.loc18_25.1, %.loc18_25.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc18: <bound method> = bound_method %.loc18_25.3, constants.%Destroy.WithSelf.SelfDestruct.db3
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc18: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc18(%.loc18_25.3)
// CHECK:STDOUT:   %Cpp.ref.loc19: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:   %thread.ref.loc19_6: type = name_ref thread, imports.%thread.decl [concrete = constants.%thread]
// CHECK:STDOUT:   %thread.ref.loc19_13: %thread.thread.cpp_overload_set.type = name_ref thread, imports.%thread.thread.cpp_overload_set.value [concrete = constants.%thread.thread.cpp_overload_set.value]
// CHECK:STDOUT:   %Work2.ref: %Work2.type = name_ref Work2, file.%Work2.decl [concrete = constants.%Work2]
// CHECK:STDOUT:   %.loc19_26.1: ref %thread = temporary_storage
// CHECK:STDOUT:   %.loc19_21.1: %.659 = cpp_addr_of_fn %Work2.ref, @Work2 [concrete = constants.%.c6f]
// CHECK:STDOUT:   %.loc19_21.2: %.659 = converted %Work2.ref, %.loc19_21.1 [concrete = constants.%.c6f]
// CHECK:STDOUT:   %addr.loc19: %ptr.16e = addr_of %.loc19_26.1
// CHECK:STDOUT:   %thread__carbon_thunk.call.loc19: init %empty_tuple.type = call imports.%thread__carbon_thunk.decl(%.loc19_21.2, %addr.loc19)
// CHECK:STDOUT:   %.loc19_26.2: init %thread to %.loc19_26.1 = mark_in_place_init %thread__carbon_thunk.call.loc19
// CHECK:STDOUT:   %.loc19_26.3: ref %thread = temporary %.loc19_26.1, %.loc19_26.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc19: <bound method> = bound_method %.loc19_26.3, constants.%Destroy.WithSelf.SelfDestruct.db3
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc19: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc19(%.loc19_26.3)
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc18(%self.param: ref %thread) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc18(%self.param: ref %thread) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl(%self.param)
// CHECK:STDOUT:   %thread.cpp_destructor.call: init %empty_tuple.type = call imports.%thread.cpp_destructor.decl(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
