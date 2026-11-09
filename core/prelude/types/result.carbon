// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

package Core library "prelude/types/result";

// The choice's discriminant type and construction need the unsigned
// integer types.
import library "prelude/operators/as";
import library "prelude/types/uint";
// `match` on a choice tests the discriminant through `Core.EqWith`
// (`EmitChoiceDiscriminantTest`, toolchain/check/pattern_match.cpp). Inside
// package `Core` that implicit `Core.<name>` lookup resolves against this
// file's own package scope, and `prelude/types/uint` imports
// `prelude/operators` without re-exporting it, so the comparison library
// must be imported here explicitly.
import library "prelude/operators/comparison";
import library "prelude/try";

// The vocabulary type for fallible operations (docs/design/error_handling.md,
// "The `Core.Result` type"): `Success` carries the success value, `Failure`
// the error value, upstream's spellings (docs/design/README.md, the
// choice-types section and "Generic choice types"; the history is at the end
// of this file). The alternative order fixes the discriminants — `Success` =
// 0, `Failure` = 1 — which the entry point's exit-code epilogue
// (toolchain/lower/handle.cpp) and the C++ `Carbon::expected` layout mirror
// rely on. `E` is unconstrained in 0.1; `Result((), E)` is the unit shape.
choice Result(T: type, E: type) {
  Success(value: T),
  Failure(error: E)
}

// `Result` is a `Try` operand and a `Try` return type: `expr?` continues with
// the `Success` payload and propagates a `Failure` payload through
// `FromBreak` on the enclosing function's return type (the `ImplicitAs` error
// conversion is the ordinary argument conversion of that call). The sketch is
// the design's (docs/design/error_handling.md, "The `Core.Try` interface");
// `final` licenses impl lookup to apply the `where` rewrites under a symbolic
// query, so `r?` on a `Result(T, E)` operand in a generic body has type `T`.
final impl forall [T: type, E: type] Result(T, E) as Try
    where .ContinueType = T and .BreakType = E {
  fn Branch(self) -> ControlFlow(T, E) {
    match (self) {
      case .Success(v: T) => { return ControlFlow(T, E).Continue(v); }
      case .Failure(e: E) => { return ControlFlow(T, E).Break(e); }
    }
    // Unreachable trailing return: reachability doesn't consult match
    // exhaustiveness; under `final` the recursive call type-collapses.
    return self.(Try.Branch)();
  }
  fn FromBreak(b: E) -> Self { return Result(T, E).Failure(b); }
}

// History (EH-C, W-346, 2026-11-09; fork/eh/ehc-plan.md D-EHC-1): from fork
// decision F-006a (user, 2026-07-19) until EH-C the alternatives were spelled
// `Ok`/`Err`, chosen over the README's `Success`/`Failure` as illustrative.
// RG-1 (2026-10-28, D-RG-5) classified that a second spelling of upstream's
// mechanism under fork/rulebook.md R32 (d): upstream's docs/design/README.md
// (ca1898506) names `Result` as the error representation (:3858-3860) and
// spells the result choice `Success(value: i32)` / `Failure(error: String)`
// (:2176-2177) and `Success(value: T)` / `Failure(error: Error)`
// (:3165-3166). No alias remains; the user may veto the reversal (R29).
