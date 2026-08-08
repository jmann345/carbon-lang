// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/operators/fail_question.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/operators/fail_question.carbon
// CHECK:STDERR: {{.*}}/prelude/try.carbon:20:1: error: name `Core.ImplicitAs` implicitly referenced here, but not found [CoreNameNotFound]
// CHECK:STDERR: choice ControlFlow(C: type, B: type) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: {{.*}}/prelude/try.carbon:20:1: error: name `Core.ImplicitAs` implicitly referenced here, but not found [CoreNameNotFound]
// CHECK:STDERR: choice ControlFlow(C: type, B: type) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:

// Postfix `?` rejections that need a user `Core.Try` impl in scope
// (fork/b1/plan.md §3 B1b): the operand rejection, the three
// captured-region positions (the §2.4 region-position policy, risk R-2's
// falsifiers), the D3 no-conversion pin, and the §2.6 no-choice-copy pin.
// The pre-flight shapes that need no impl are in
// fail_question_preflight.carbon.

// --- fail_operand_not_try.carbon
library "[[@TEST_NAME]]";

choice MyResult(T: type, E: type) {
  Ok(v: T),
  Err(e: E)
}

impl forall [T: type, E: type] MyResult(T, E) as Core.Try
    where .ContinueType = T and .BreakType = E {
  fn Branch(self) -> Core.ControlFlow(T, E) {
    match (self) {
      case .Ok(v: T) => { return Core.ControlFlow(T, E).Continue(v); }
      case .Err(e: E) => { return Core.ControlFlow(T, E).Break(e); }
    }
  // CHECK:STDERR: fail_operand_not_try.carbon:[[@LINE+4]]:3: error: missing `return` at end of function with declared return type [MissingReturnStatement]
  // CHECK:STDERR:   }
  // CHECK:STDERR:   ^
  // CHECK:STDERR:
  }
  fn FromBreak(e: E) -> Self { return MyResult(T, E).Err(e); }
}

fn Operand(x: i32) -> MyResult(i32, i32) {
  // CHECK:STDERR: fail_operand_not_try.carbon:[[@LINE+7]]:3: error: operand of `?` does not implement `Core.Try` [QuestionOperandNotTry]
  // CHECK:STDERR:   x?;
  // CHECK:STDERR:   ^~
  // CHECK:STDERR: fail_operand_not_try.carbon:[[@LINE+4]]:3: note: type `i32` does not implement interface `Core.Try` [MissingImplInMemberAccessInContext]
  // CHECK:STDERR:   x?;
  // CHECK:STDERR:   ^~
  // CHECK:STDERR:
  x?;
  return MyResult(i32, i32).Ok(x);
}

// Type-position `?` at region depth 1: the operand is the TYPE `i32`, so
// this is the ordinary missing-impl rejection (`type` does not implement
// `Core.Try`) — fork/b1/plan.md §2.3, approval-gate item 7. Annotation
// positions are captured regions and take the region-policy rejection
// instead (fail_pattern_positions.carbon).
fn TypePosition() -> MyResult(i32, i32) {
  // CHECK:STDERR: fail_operand_not_try.carbon:[[@LINE+7]]:3: error: operand of `?` does not implement `Core.Try` [QuestionOperandNotTry]
  // CHECK:STDERR:   i32?;
  // CHECK:STDERR:   ^~~~
  // CHECK:STDERR: fail_operand_not_try.carbon:[[@LINE+4]]:3: note: type `type` does not implement interface `Core.Try` [MissingImplInMemberAccessInContext]
  // CHECK:STDERR:   i32?;
  // CHECK:STDERR:   ^~~~
  // CHECK:STDERR:
  i32?;
  return MyResult(i32, i32).Ok(0);
}

// --- fail_pattern_positions.carbon
library "[[@TEST_NAME]]";

choice MyResult(T: type, E: type) {
  Ok(v: T),
  Err(e: E)
}

impl forall [T: type, E: type] MyResult(T, E) as Core.Try
    where .ContinueType = T and .BreakType = E {
  fn Branch(self) -> Core.ControlFlow(T, E) {
    match (self) {
      case .Ok(v: T) => { return Core.ControlFlow(T, E).Continue(v); }
      case .Err(e: E) => { return Core.ControlFlow(T, E).Break(e); }
    }
  // CHECK:STDERR: fail_pattern_positions.carbon:[[@LINE+4]]:3: error: missing `return` at end of function with declared return type [MissingReturnStatement]
  // CHECK:STDERR:   }
  // CHECK:STDERR:   ^
  // CHECK:STDERR:
  }
  fn FromBreak(e: E) -> Self { return MyResult(T, E).Err(e); }
}

fn H(n: i32) -> MyResult(i32, i32) { return MyResult(i32, i32).Ok(n); }

// The three captured-region positions (fork/b1/plan.md §2.4's
// region-position policy): the operand H(...) and the enclosing return
// type both implement `Core.Try`, so each rejection below is provably the
// region policy, not a missing impl. A verifier crash, an orphaned
// return-terminated block, or a silent compile here falsifies the
// region-depth detection (risk R-2).
fn Guard(r: MyResult(i32, i32)) -> MyResult(i32, i32) {
  match (r) {
    // CHECK:STDERR: fail_pattern_positions.carbon:[[@LINE+4]]:26: error: `?` cannot be used inside a pattern, a `case` guard, or a binding's type expression [QuestionInPatternContext]
    // CHECK:STDERR:     case .Ok(v: i32) if (H(v)? > 0) => { return MyResult(i32, i32).Ok(v); }
    // CHECK:STDERR:                          ^~~~~
    // CHECK:STDERR:
    case .Ok(v: i32) if (H(v)? > 0) => { return MyResult(i32, i32).Ok(v); }
    case .Ok(w: i32) => { return MyResult(i32, i32).Ok(w); }
    case .Err(e: i32) => { return MyResult(i32, i32).Err(e); }
  }
// CHECK:STDERR: fail_pattern_positions.carbon:[[@LINE+4]]:1: error: missing `return` at end of function with declared return type [MissingReturnStatement]
// CHECK:STDERR: }
// CHECK:STDERR: ^
// CHECK:STDERR:
}

fn ExprPattern(n: i32) -> MyResult(i32, i32) {
  match (n) {
    // CHECK:STDERR: fail_pattern_positions.carbon:[[@LINE+8]]:10: error: `?` cannot be used inside a pattern, a `case` guard, or a binding's type expression [QuestionInPatternContext]
    // CHECK:STDERR:     case H(0)? => { return MyResult(i32, i32).Ok(n); }
    // CHECK:STDERR:          ^~~~~
    // CHECK:STDERR:
    // CHECK:STDERR: fail_pattern_positions.carbon:[[@LINE+4]]:5: error: semantics TODO: `match case expression pattern that is not a constant integer` [SemanticsTodo]
    // CHECK:STDERR:     case H(0)? => { return MyResult(i32, i32).Ok(n); }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR:
    case H(0)? => { return MyResult(i32, i32).Ok(n); }
    default => { return MyResult(i32, i32).Err(n); }
  }
}

fn Annotation(r: MyResult(i32, i32)) -> MyResult(i32, i32) {
  var y: r? = 0;
  return MyResult(i32, i32).Ok(y);
}

// Migrated from the B1a gate pin (fail_todo_question.carbon's type
// position): a type annotation is a captured region, so `var p: i32?`
// takes the region-policy rejection — recorded as superseding §2.3's
// missing-impl expectation for annotation positions (see the plan's dated
// divergence clause). The depth-1 type-position shape keeps the
// missing-impl rejection (fail_operand_not_try.carbon).
fn TypeAnnotation() -> MyResult(i32, i32) {
  var p: i32? = 0;
  return MyResult(i32, i32).Ok(p);
}

// --- fail_no_conversion.carbon
library "[[@TEST_NAME]]";

choice MyResult(T: type, E: type) {
  Ok(v: T),
  Err(e: E)
}

impl forall [T: type, E: type] MyResult(T, E) as Core.Try
    where .ContinueType = T and .BreakType = E {
  fn Branch(self) -> Core.ControlFlow(T, E) {
    match (self) {
      case .Ok(v: T) => { return Core.ControlFlow(T, E).Continue(v); }
      case .Err(e: E) => { return Core.ControlFlow(T, E).Break(e); }
    }
  // CHECK:STDERR: fail_no_conversion.carbon:[[@LINE+4]]:3: error: missing `return` at end of function with declared return type [MissingReturnStatement]
  // CHECK:STDERR:   }
  // CHECK:STDERR:   ^
  // CHECK:STDERR:
  }
  fn FromBreak(e: E) -> Self { return MyResult(T, E).Err(e); }
}

// The D3 negative: with no user `ImplicitAs` from the operand's break
// type to the return type's break type, the `FromBreak` argument
// conversion — the ordinary call machinery — is what fails; no
// `?`-specific conversion path exists (fork/b1/plan.md §2.4 step 5).
class ErrA {
  adapt i32;
}

class ErrC {
  adapt i32;
}

fn Inner(n: i32) -> MyResult(i32, ErrA) {
  return MyResult(i32, ErrA).Err(n as ErrA);
}

fn Outer(n: i32) -> MyResult(i32, ErrC) {
  // CHECK:STDERR: fail_no_conversion.carbon:[[@LINE+10]]:16: error: cannot implicitly convert expression of type `ErrA` to `ErrC` [ConversionFailure]
  // CHECK:STDERR:   var v: i32 = Inner(n)?;
  // CHECK:STDERR:                ^~~~~~~~~
  // CHECK:STDERR: fail_no_conversion.carbon:[[@LINE+7]]:16: note: type `ErrA` does not implement interface `Core.ImplicitAs(ErrC)` [MissingImplInMemberAccessInContext]
  // CHECK:STDERR:   var v: i32 = Inner(n)?;
  // CHECK:STDERR:                ^~~~~~~~~
  // CHECK:STDERR: fail_no_conversion.carbon:[[@LINE-26]]:16: note: initializing function parameter [InCallToFunctionParam]
  // CHECK:STDERR:   fn FromBreak(e: E) -> Self { return MyResult(T, E).Err(e); }
  // CHECK:STDERR:                ^~~~
  // CHECK:STDERR:
  var v: i32 = Inner(n)?;
  return MyResult(i32, ErrC).Ok(v);
}

// --- fail_return_choice_binding.carbon
library "[[@TEST_NAME]]";

choice MyResult(T: type, E: type) {
  Ok(v: T),
  Err(e: E)
}

// The §2.6 bound (risk R-5): returning a choice-typed BINDING value-copies
// the choice, and choices implement no `Core.Copy`. This is why every
// `Branch` impl body uses the match-reconstruct style — and why the design
// doc's original `fn Branch(self) -> Result(T, E) { return self; }` sketch
// is amended: against the `ControlFlow` carrier that body is a type
// mismatch, and the underlying copy bound it relied on is pinned here. If
// this ever compiles, choices gained copyability and §2.6 needs
// re-derivation.
fn Passthrough(r: MyResult(i32, i32)) -> MyResult(i32, i32) {
  // CHECK:STDERR: fail_return_choice_binding.carbon:[[@LINE+7]]:10: error: cannot copy value of type `MyResult(i32, i32)` [CopyOfUncopyableType]
  // CHECK:STDERR:   return r;
  // CHECK:STDERR:          ^
  // CHECK:STDERR: fail_return_choice_binding.carbon:[[@LINE+4]]:10: note: type `MyResult(i32, i32)` does not implement interface `Core.Copy` [MissingImplInMemberAccessInContext]
  // CHECK:STDERR:   return r;
  // CHECK:STDERR:          ^
  // CHECK:STDERR:
  return r;
}
