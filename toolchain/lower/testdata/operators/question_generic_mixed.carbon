// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/operators/question_generic_mixed.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/operators/question_generic_mixed.carbon

// The mixed-width instantiated-generic `?` golden (the
// question_generic_diff runtime divergence, 2026-08-09): one generic `?`
// body monomorphized at BOTH `MyResult(i32, i32)` and `MyResult(i64, i32)`
// in one module, so the narrow (i32) `Err` payload lowers inside the WIDE
// max-of-fields region of the i64 specific (F-007k). What this pins:
// every writer and reader of `MyResult(i64, i32)`'s `Err` payload — the
// `Err` constructor's whole-object covering copy plus element stores, the
// desugar's Break-arm extraction, and the concrete `match` read — must
// address the SAME 16-byte object (`[8 x i8]` payload region at byte
// offset 8, covering copy of 16). Falsification: any i64-specific
// Err-path store or load through a NARROW object shape (the divergence's
// candidate W2 — per-specific layout reuse in instantiated bodies, which
// is ORDER-dependent: Call32 below deliberately precedes Call64), a
// covering memcpy shorter than the specific's object size, or a
// cross-width pair resolving to ONE lowered body. Payload-touching
// bodies fingerprint width-distinct types, so only forwarder-shaped
// pairs (`Diverge`) could coalesce cross-width pre-gate; the sret type
// gate pins that split, and the runtime arbiter for the divergence
// stays the conformance pair.

// --- mixed.carbon
library "[[@TEST_NAME]]";

choice MyResult(T: type, E: type) {
  Ok(v: T),
  Err(e: E)
}

// Returns a value of any type by never returning — the unreachable
// trailing-return helper for generic match-reconstruct bodies
// (fork/b1/plan.md §2.6, dated correction).
fn Diverge(generic T2: type) -> T2 { return Diverge(T2); }

impl forall [T: type, E: type] MyResult(T, E) as Core.Try
    where .ContinueType = T and .BreakType = E {
  fn Branch(self) -> Core.ControlFlow(T, E) {
    match (self) {
      case .Ok(v: T) => { return Core.ControlFlow(T, E).Continue(v); }
      case .Err(e: E) => { return Core.ControlFlow(T, E).Break(e); }
    }
    // Unreachable-terminator idiom (fork/b1/plan.md §2.6, dated
    // correction).
    return Diverge(Core.ControlFlow(T, E));
  }
  fn FromBreak(e: E) -> Self { return MyResult(T, E).Err(e); }
}

// The proven generic `?` body shape (lower/testdata/operators/
// question_generic.carbon): carrier `Core.ControlFlow(R.ContinueType, i32)`,
// symbolic at check time, concrete per instantiation below.
fn PropagateOnly[R: Core.Try where .BreakType = i32](r: R) -> R {
  let unused c: R.ContinueType = r?;
  return R.FromBreak(0);
}

// Both widths instantiated side by side: distinct specifics, distinct
// layouts, one module.
fn Call32(r: MyResult(i32, i32)) -> MyResult(i32, i32) {
  return PropagateOnly(r);
}

fn Call64(r: MyResult(i64, i32)) -> MyResult(i64, i32) {
  return PropagateOnly(r);
}

// Concrete narrow-alternative writer for the wide specific: the `Err`
// constructor call whose covering copy and element stores this golden
// pins.
fn MakeErr64(tag: i32) -> MyResult(i64, i32) {
  return MyResult(i64, i32).Err(tag);
}

// Concrete reader: the payload load must address the same 16-byte object
// the writer initialized.
fn ReadErr64(r: MyResult(i64, i32)) -> i32 {
  match (r) {
    case .Ok(v: i64) => { return 0; }
    case .Err(e: i32) => { return e; }
  }
  // Unreachable: every arm returns.
  return -1;
}
