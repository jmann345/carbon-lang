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
// parameter. `TryMapType` (check/cpp/type_mapping.cpp) maps the function's
// `SemIR::FunctionType` to a pointer to its exported declaration's type, the
// invented argument is an AST-embedded `DeclRefExpr` to that declaration with
// function-to-pointer decay, and the C++ thunk embeds the reference instead
// of taking a runtime parameter (check/cpp/thunk.cpp). Generic functions and
// methods stay diagnosed with `CppCallArgTypeNotSupported` — the negative
// partition (plan §5 R-7) pinned by the fail_todo splits below.

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
