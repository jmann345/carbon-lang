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
  var unused p: Cpp.Callback = GenericWork;
}
