// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/exceptions/fail_catching.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/exceptions/fail_catching.carbon

// The boundaries of the catching import (docs/design/error_handling.md,
// "Catching imports"; fork/eh/plan.md §1.B.1, §4.B): a `noexcept` callee never
// gets a catching thunk, so `?` diagnoses the usual non-`Try` operand; a break
// type that rejects `Cpp.Exception` fails the `FromBreak` argument conversion
// with the catching-import context line; `?` on a binding holding the call's
// value is not the direct-call form (D-EH-4); and a callee returning a class by
// value — including a constructor, spelled in this tree's static-member form
// `Cpp.Widget.Widget(1)` — fails the SF-6 scalar payload bound BEFORE the
// `Core.Result(S, Cpp.Exception)` specific is formed: exactly one error,
// `CppCatchingImportNonScalarSuccess`, naming the C++ callee
// (`may_throw_class` / `Widget::Widget`) and `Cpp.Widget`, and nothing else —
// no specific is formed, so no monomorphization cascade follows. The `none`
// mode arm lives in fail_catching_none_mode.carbon (its `EXTRA-ARGS` is
// file-wide).

// --- fail_noexcept_callee.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
int cannot_throw() noexcept;
''';

fn F() -> Core.Result(i32, Cpp.Exception) {
  // CHECK:STDERR: fail_noexcept_callee.carbon:[[@LINE+7]]:45: error: operand of `?` does not implement `Core.Try` [QuestionOperandNotTry]
  // CHECK:STDERR:   return Core.Result(i32, Cpp.Exception).Ok(Cpp.cannot_throw()?);
  // CHECK:STDERR:                                             ^~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR: fail_noexcept_callee.carbon:[[@LINE+4]]:45: note: type `i32` does not implement interface `Core.Try` [MissingImplInMemberAccessInContext]
  // CHECK:STDERR:   return Core.Result(i32, Cpp.Exception).Ok(Cpp.cannot_throw()?);
  // CHECK:STDERR:                                             ^~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  return Core.Result(i32, Cpp.Exception).Ok(Cpp.cannot_throw()?);
}

// --- fail_break_type_mismatch.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
int may_throw_int();
''';

fn F() -> Core.Result(i32, i32) {
  // CHECK:STDERR: fail_break_type_mismatch.carbon:[[@LINE+13]]:35: error: operand of `?` is a call to potentially-throwing C++ function `may_throw_int`; a thrown exception propagates as `Cpp.Exception` [QuestionCppCatchingImportNote]
  // CHECK:STDERR:   return Core.Result(i32, i32).Ok(Cpp.may_throw_int()?);
  // CHECK:STDERR:                                   ^~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR: fail_break_type_mismatch.carbon:[[@LINE+10]]:35: note: cannot implicitly convert expression of type `Cpp.Exception` to `i32` [ConversionFailure]
  // CHECK:STDERR:   return Core.Result(i32, i32).Ok(Cpp.may_throw_int()?);
  // CHECK:STDERR:                                   ^~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR: fail_break_type_mismatch.carbon:[[@LINE+7]]:35: note: type `Cpp.Exception` does not implement interface `Core.ImplicitAs(i32)` [MissingImplInMemberAccessInContext]
  // CHECK:STDERR:   return Core.Result(i32, i32).Ok(Cpp.may_throw_int()?);
  // CHECK:STDERR:                                   ^~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR: {{.*}}/prelude/types/result.carbon:51:16: note: initializing function parameter [InCallToFunctionParam]
  // CHECK:STDERR:   fn FromBreak(b: E) -> Self { return Result(T, E).Err(b); }
  // CHECK:STDERR:                ^~~~
  // CHECK:STDERR:
  return Core.Result(i32, i32).Ok(Cpp.may_throw_int()?);
}

// --- fail_not_direct.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
int may_throw_int();
''';

fn F() -> Core.Result(i32, Cpp.Exception) {
  let x: i32 = Cpp.may_throw_int();
  // CHECK:STDERR: fail_not_direct.carbon:[[@LINE+7]]:45: error: operand of `?` does not implement `Core.Try` [QuestionOperandNotTry]
  // CHECK:STDERR:   return Core.Result(i32, Cpp.Exception).Ok(x?);
  // CHECK:STDERR:                                             ^~
  // CHECK:STDERR: fail_not_direct.carbon:[[@LINE+4]]:45: note: type `i32` does not implement interface `Core.Try` [MissingImplInMemberAccessInContext]
  // CHECK:STDERR:   return Core.Result(i32, Cpp.Exception).Ok(x?);
  // CHECK:STDERR:                                             ^~
  // CHECK:STDERR:
  return Core.Result(i32, Cpp.Exception).Ok(x?);
}

// --- fail_class_return.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
struct Widget {
  int n;
};
Widget may_throw_class();
''';

fn F() -> Core.Result(i32, Cpp.Exception) {
  Cpp.may_throw_class()?;
  return Core.Result(i32, Cpp.Exception).Ok(0);
}

// --- fail_ctor_return.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
struct Widget {
  Widget(int n);
  int n;
};
''';

fn F() -> Core.Result(i32, Cpp.Exception) {
  Cpp.Widget.Widget(1)?;
  return Core.Result(i32, Cpp.Exception).Ok(0);
}
