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
// "The `Core.Result` type"; decision F-006a): `Ok` carries the success
// value, `Err` the error value. The alternative order fixes the
// discriminants — `Ok` = 0, `Err` = 1 — which the entry point's exit-code
// epilogue (toolchain/lower/handle.cpp) and the C++ `Carbon::expected`
// layout mirror rely on. `E` is not constrained to implement any error
// interface in 0.1; `Result((), E)` is the conventional shape for operations
// with no interesting success value.
choice Result(T: type, E: type) {
  Ok(value: T),
  Err(error: E)
}

// `Result` is a `Try` operand and a `Try` return type: `expr?` continues with
// the `Ok` payload and propagates an `Err` payload through `FromBreak` on the
// enclosing function's return type (the `ImplicitAs` error conversion is the
// ordinary argument conversion of that call). The sketch is the design's
// (docs/design/error_handling.md, "The `Core.Try` interface"); `final`
// licenses impl lookup to apply the `where` rewrites under a symbolic query,
// so `r?` on a `Result(T, E)` operand in a generic body has type `T`.
final impl forall [T: type, E: type] Result(T, E) as Try
    where .ContinueType = T and .BreakType = E {
  fn Branch(self) -> ControlFlow(T, E) {
    match (self) {
      case .Ok(v: T) => { return ControlFlow(T, E).Continue(v); }
      case .Err(e: E) => { return ControlFlow(T, E).Break(e); }
    }
    // Unreachable trailing return: reachability doesn't consult match
    // exhaustiveness; under `final` the recursive call type-collapses.
    return self.(Try.Branch)();
  }
  fn FromBreak(b: E) -> Self { return Result(T, E).Err(b); }
}
