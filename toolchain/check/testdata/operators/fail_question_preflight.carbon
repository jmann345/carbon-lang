// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/try.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/operators/fail_question_preflight.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/operators/fail_question_preflight.carbon

// The postfix `?` rejections that need no `Core.Try` impl (fork/b1/plan.md
// §2.4 step 1, §2.5): the pre-flight shapes — each diagnosed before the
// desugar emits a single inst — plus the R-4 per-specific carrier rejection
// (fail_unit_break_type, which pins the SF-6 eval hook and is NOT a
// pre-flight diagnostic). All run on the minimal `try` prelude, which has
// no `Try` impls at all — so the pre-flight rejections demonstrably fire
// before any impl lookup — and omits `EqWith`, so the desugar's
// discriminant test is never reached. The shapes needing a Try-implementing
// operand or a return type with a user `Core.Try` impl are in
// fail_question.carbon.

// --- fail_no_declared_return_type.carbon
library "[[@TEST_NAME]]";

// D4: `?` is unavailable in auto-return functions.
fn NoReturnType(x: i32) {
  // CHECK:STDERR: fail_no_declared_return_type.carbon:[[@LINE+7]]:3: error: `?` requires the enclosing function to have a declared return type that implements `Core.Try` [QuestionNoDeclaredReturnType]
  // CHECK:STDERR:   x?;
  // CHECK:STDERR:   ^~
  // CHECK:STDERR: fail_no_declared_return_type.carbon:[[@LINE-4]]:1: note: there was no return type provided [ReturnTypeOmittedNote]
  // CHECK:STDERR: fn NoReturnType(x: i32) {
  // CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  x?;
}

// --- fail_file_scope.carbon
library "[[@TEST_NAME]]";

fn Get() -> i32 { return 1; }

// D4: file scope and global initializers have no function scope.
// CHECK:STDERR: fail_file_scope.carbon:[[@LINE+4]]:14: error: `?` can only be used inside a function body [QuestionOutsideFunction]
// CHECK:STDERR: var g: i32 = Get()?;
// CHECK:STDERR:              ^~~~~~
// CHECK:STDERR:
var g: i32 = Get()?;

// --- fail_non_try_return_type.carbon
library "[[@TEST_NAME]]";

// The pre-flight witness lookup (fork/b1/plan.md §2.4, the A-1 correction):
// a non-`Try` return type is a targeted Error at the `?` with the
// return-type-here note — not a facet-conversion cascade at the `FromBreak`
// access.
fn Passthrough(x: i32) -> i32 {
  // CHECK:STDERR: fail_non_try_return_type.carbon:[[@LINE+7]]:10: error: return type `i32` of the enclosing function does not implement `Core.Try` [QuestionReturnTypeNotTry]
  // CHECK:STDERR:   return x? + 1;
  // CHECK:STDERR:          ^~
  // CHECK:STDERR: fail_non_try_return_type.carbon:[[@LINE-4]]:27: note: return type of function is `i32` [ReturnTypeHereNote]
  // CHECK:STDERR: fn Passthrough(x: i32) -> i32 {
  // CHECK:STDERR:                           ^~~
  // CHECK:STDERR:
  return x? + 1;
}

// --- fail_ref_return_form.carbon
library "[[@TEST_NAME]]";

// The desugar returns through the `InitForm` path only; `ref` (and other
// non-initializing) return forms are rejected up front.
fn RefReturn(p: i32*) -> ref i32 {
  // CHECK:STDERR: fail_ref_return_form.carbon:[[@LINE+7]]:3: error: `?` cannot be used in a function whose return uses a `ref` form or a symbolic form [QuestionNonInitReturnForm]
  // CHECK:STDERR:   (*p)?;
  // CHECK:STDERR:   ^~~~~
  // CHECK:STDERR: fail_ref_return_form.carbon:[[@LINE-4]]:26: note: return form declared here [ReturnFormHereNote]
  // CHECK:STDERR: fn RefReturn(p: i32*) -> ref i32 {
  // CHECK:STDERR:                          ^~~~~~~
  // CHECK:STDERR:
  (*p)?;
  return *p;
}

// --- fail_returned_var_scope.carbon
library "[[@TEST_NAME]]";

// A `returned var` in scope makes `return <expr>;` unavailable, and the `?`
// break path returns through exactly that initializing-expression form —
// rejected by the pre-flight (before the return-type `Try` check, so no
// impl is consulted: `i32` not implementing `Try` is never mentioned), not
// mid-desugar by return.cpp's "can only `return var;`" message.
fn WithReturnedVar(x: i32) -> i32 {
  returned var r: i32 = 0;
  // CHECK:STDERR: fail_returned_var_scope.carbon:[[@LINE+7]]:3: error: `?` cannot be used in the scope of a `returned var`; `?` returns through an initializing expression [QuestionInReturnedVarScope]
  // CHECK:STDERR:   x?;
  // CHECK:STDERR:   ^~
  // CHECK:STDERR: fail_returned_var_scope.carbon:[[@LINE-4]]:16: note: `returned var` was declared here [ReturnedVarHere]
  // CHECK:STDERR:   returned var r: i32 = 0;
  // CHECK:STDERR:                ^~~~~~
  // CHECK:STDERR:
  x?;
  return var;
}

// --- fail_unit_break_type.carbon
library "[[@TEST_NAME]]";

// NOT a pre-flight rejection — no `?` appears in this program; the pin
// exercises the SF-6 per-specific eval hook on the carrier type itself, and
// rides this file for the shared min_prelude/try combo.
//
// The unit-break-type bound (fork/b1/plan.md §2.7, risk R-4): `BreakType =
// ()` needs a `ControlFlow(C, ())` specific, and the SF-6 per-specific
// payload check rejects tuples including `()`. Pinned so the bound is
// arbitrated, not assumed; if this ever compiles, §2.7's premise is wrong
// and the S3p boundary item is re-scoped.
// CHECK:STDERR: fail_unit_break_type.carbon:[[@LINE+7]]:26: error: parameter has incomplete type `Core.ControlFlow(i32, ())` in function definition [IncompleteTypeInFunctionParam]
// CHECK:STDERR: fn TakesUnitBreak(unused c: Core.ControlFlow(i32, ())) {}
// CHECK:STDERR:                          ^~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: min_prelude/parts/try.carbon:10:1: note: choice alternative payload type `()` is not trivially copyable and destructible in this specific [ChoicePayloadNotTrivialInSpecific]
// CHECK:STDERR: choice ControlFlow(C: type, B: type) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn TakesUnitBreak(unused c: Core.ControlFlow(i32, ())) {}
