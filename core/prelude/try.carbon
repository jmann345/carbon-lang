// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

package Core library "prelude/try";

// The choice's discriminant type and construction need the unsigned
// integer types.
import library "prelude/operators/as";
import library "prelude/types/uint";

// The branch carrier returned by `Try.Branch`: the value either continues
// evaluation of the enclosing expression (`Continue`) or propagates to the
// caller (`Break`). This is the postfix `?` operator's dispatch subject
// (fork/b1/plan.md §2.2 option B): the alternative order fixes the
// discriminants — `Continue` = 0, `Break` = 1 — which the `?` desugar's
// discriminant test depends on. The parameter order is continue-first,
// matching `Try`'s `(ContinueType, BreakType)` reading; this deliberately
// diverges from Rust's break-first `ControlFlow<B, C>` (recorded in the B1
// landing note's divergence-risk entries, fork/decision-log.md).
choice ControlFlow(C: type, B: type) {
  Continue(value: C),
  Break(value: B)
}

// The protocol behind the postfix `?` operator (docs/design/error_handling.md,
// "The `Core.Try` interface"). `expr?` calls `Branch` on `expr`'s value; a
// `Continue` payload becomes the value of `expr?`, and a `Break` payload is
// converted to the enclosing function's break type and returned through
// `FromBreak` on the enclosing function's return type.
//
// An implementation must uphold: `Branch` consumes `self` and returns exactly
// one alternative; `FromBreak` produces a value whose own `Branch` takes the
// `Break` path with an equal break value. The compiler does not verify these
// laws; they are the documented contract, like the expectations on comparison
// operators.
interface Try {
  // The type produced by `expr?` on the success path.
  let ContinueType: type;
  // The type propagated to the caller on the failure path.
  let BreakType: type;

  // Splits `self` into continue-or-break.
  fn Branch(self) -> ControlFlow(ContinueType, BreakType);
  // Rebuilds a value of `Self` from a propagated break value. Used on the
  // *return type* of the enclosing function.
  fn FromBreak(b: BreakType) -> Self;
}
