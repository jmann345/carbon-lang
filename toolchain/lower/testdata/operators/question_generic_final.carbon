// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/operators/question_generic_final.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/operators/question_generic_final.carbon

// The W72a instantiated-THREADING lower golden (fork/w072/plan.md §3, W72a
// exit criteria): the generic `?` chain under the `final impl` spelling,
// monomorphized at a concrete argument. What this pins: the monomorphized
// continue value FLOWS — the first `?`'s continue value is the second
// `Step` call's argument, and the second's is the final `Ok`
// construction's payload — falsified by a `Discard`-shaped dead value or
// absent flow. Contrast question_generic.carbon and
// question_generic_crossfile.carbon, whose continue values go through the
// deduced `Discard` sink (the non-final idiom's only spelling — the
// permanent negative pins). The destroy-call shape must stay the SAME
// no-op shape as the B2a baseline (question_generic.carbon's falsification
// triad: no non-empty destroy body, no user `Destroy` impl on the
// propagation path, no absent destroy call where the baseline has one) —
// nothing in the destroy path keys on finality (plan §2.2, risk R-4).

// --- thread.carbon
library "[[@TEST_NAME]]";

choice MyResult(T: type, E: type) {
  Ok(v: T),
  Err(e: E)
}

// Returns a value of any type by never returning — the unreachable
// trailing-return helper for generic match-reconstruct bodies
// (fork/b1/plan.md §2.6, dated correction).
fn Diverge(generic T2: type) -> T2 { return Diverge(T2); }

// The doc's own `final` spelling (docs/design/error_handling.md sketches;
// fork/w072/plan.md §0.1 candidate (d)) — what licenses the `: T`
// bindings in `Chain` below.
final impl forall [T: type, E: type] MyResult(T, E) as Core.Try
    where .ContinueType = T and .BreakType = E {
  fn Branch(self) -> Core.ControlFlow(T, E) {
    match (self) {
      case .Ok(v: T) => { return Core.ControlFlow(T, E).Continue(v); }
      case .Err(e: E) => { return Core.ControlFlow(T, E).Break(e); }
    }
    // Unreachable-terminator idiom (fork/b1/plan.md §2.6).
    return Diverge(Core.ControlFlow(T, E));
  }
  fn FromBreak(e: E) -> Self { return MyResult(T, E).Err(e); }
}

// A generic step: passes `x` through, or fails with the given tag.
fn Step[T: type](x: T, fail: bool, tag: i32) -> MyResult(T, i32) {
  if (fail) { return MyResult(T, i32).Err(tag); }
  return MyResult(T, i32).Ok(x);
}

// The threading chain: each step's input is the PREVIOUS step's threaded
// continue value bound `: T` — the shape the non-final idiom could not
// spell (W-072; the W72b runtime pair arbitrates the same shape with
// payload arithmetic).
fn Chain[T: type](x: T, failA: bool, failB: bool) -> MyResult(T, i32) {
  let a: T = Step(x, failA, 101)?;
  let b: T = Step(a, failB, 202)?;
  return MyResult(T, i32).Ok(b);
}

// The concrete instantiation that lowers the specific's CFG: discriminant
// tests, payload accesses, the threaded value's flow into the second call
// and the `Ok` construction, `FromBreak` calls and early `ret`s on the
// break edges.
fn Call(x: i32, failA: bool, failB: bool) -> MyResult(i32, i32) {
  return Chain(x, failA, failB);
}
