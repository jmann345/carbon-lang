// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/function/import/fail_todo_carbon_fn_as_callable.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/function/import/fail_todo_carbon_fn_as_callable.carbon

// The F8a red baseline for defect TA-D1 (fork/f008/plan.md §2.1): a
// concrete, non-generic Carbon function passed as a C++ callable — to a
// mock thread-like constructor template and to a plain function-pointer
// parameter. Both die in argument invention: `TryMapType`
// (check/cpp/type_mapping.cpp) has no `SemIR::FunctionType` case, so the
// argument falls to `default:` and `InventPrimitiveClangArg` reports
// `CppCallArgTypeNotSupported` — the diagnostic measured against real
// `<thread>` in fork/design-sprint/threading-atomics.md:101. F8d flips the
// concrete case (plan §2.4); generic and method callables stay diagnosed.

// --- callable.h

struct thread {
  template <typename F> thread(F f);
  void join();
};

void invoke(void (*f)());

// --- fail_todo_carbon_fn_as_callable.carbon

library "[[@TEST_NAME]]";

import Cpp library "callable.h";

fn Work() {}

fn F() {
  // The measured D1 shape: a Carbon function as the callable argument of a
  // constructor template (deduction never starts — the argument has no
  // Clang mapping).
  // CHECK:STDERR: fail_todo_carbon_fn_as_callable.carbon:[[@LINE+4]]:21: error: call argument of type `<type of Work>` is not supported [CppCallArgTypeNotSupported]
  // CHECK:STDERR:   Cpp.thread.thread(Work);
  // CHECK:STDERR:                     ^~~~
  // CHECK:STDERR:
  Cpp.thread.thread(Work);

  // The same failure with no template in sight: a plain
  // function-pointer parameter.
  // CHECK:STDERR: fail_todo_carbon_fn_as_callable.carbon:[[@LINE+4]]:14: error: call argument of type `<type of Work>` is not supported [CppCallArgTypeNotSupported]
  // CHECK:STDERR:   Cpp.invoke(Work);
  // CHECK:STDERR:              ^~~~
  // CHECK:STDERR:
  Cpp.invoke(Work);
}
