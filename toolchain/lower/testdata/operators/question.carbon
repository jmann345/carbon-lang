// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/operators/question.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/operators/question.carbon

// The postfix `?` desugar's CFG, lowered (fork/b1/plan.md §3 B1b): a Branch
// call materializing the `Core.ControlFlow` carrier, the discriminant load
// and compare against `Break`'s discriminant (1, fixed by the prelude's
// alternative order), a conditional branch, the break path's payload load +
// `FromBreak` call + early `ret` through the return slot, and the continue
// path's payload load as the expression's value. No new inst kinds lower
// here — branch/return/call/element-access only — and NO copy or memcpy
// exists on the propagation path beyond the in-place return-slot init (the
// §2.6 no-copy trace, risk R-5's falsifier). `Basic` and `Wide` must
// resolve DISTINCT `ControlFlow` specifics — `ControlFlow(i32, i32)` and
// `ControlFlow(i64, i32)` — with their own payload region layouts (risk
// R-3).

// --- propagate.carbon
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
    // Unreachable-terminator idiom (fork/b1/plan.md §2.6): reachability
    // doesn't consult match exhaustiveness; no generic `ControlFlow(T, E)`
    // value is conjurable, so recurse through the interface.
    // CHECK:STDERR: propagate.carbon:[[@LINE+7]]:5: error: cannot implicitly convert expression of type `Core.ControlFlow(MyResult(T, E).(Core.Try.ContinueType), MyResult(T, E).(Core.Try.BreakType))` to `Core.ControlFlow(T, E)` [ConversionFailure]
    // CHECK:STDERR:     return self.(Core.Try.Branch)();
    // CHECK:STDERR:     ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // CHECK:STDERR: propagate.carbon:[[@LINE+4]]:5: note: type `Core.ControlFlow(MyResult(T, E).(Core.Try.ContinueType), MyResult(T, E).(Core.Try.BreakType))` does not implement interface `Core.ImplicitAs(Core.ControlFlow(T, E))` [MissingImplInMemberAccessInContext]
    // CHECK:STDERR:     return self.(Core.Try.Branch)();
    // CHECK:STDERR:     ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // CHECK:STDERR:
    return self.(Core.Try.Branch)();
  }
  fn FromBreak(e: E) -> Self { return MyResult(T, E).Err(e); }
}

fn Open(n: i32) -> MyResult(i32, i32) {
  if (n > 0) { return MyResult(i32, i32).Ok(n); }
  return MyResult(i32, i32).Err(n);
}

fn Wide(n: i64) -> MyResult(i64, i32) {
  if (n > 0) { return MyResult(i64, i32).Ok(n); }
  return MyResult(i64, i32).Err(0);
}

fn Basic(n: i32) -> MyResult(i32, i32) {
  var f: i32 = Open(n)?;
  return MyResult(i32, i32).Ok(f + 1);
}

fn Both(n: i32, m: i64) -> MyResult(i64, i32) {
  var x: i32 = Open(n)?;
  var y: i64 = Wide(m)?;
  return MyResult(i64, i32).Ok(y + (x as i64));
}
