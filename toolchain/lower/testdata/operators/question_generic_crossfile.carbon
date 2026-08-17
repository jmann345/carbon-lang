// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/operators/question_generic_crossfile.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/operators/question_generic_crossfile.carbon

// The CROSS-FILE mixed-width instantiated-generic `?` golden (the
// question_generic_diff runtime divergence, round 2, H-ZERO): the generic
// chain lives in an imported library while BOTH width instantiations —
// narrow (i32) first, then wide (i64) — happen in the importing file, and
// every `?` operand is a CALL-RESULT temporary (`Step(x, ...)?` through
// the proven `Discard` sink), the two properties that separate the failing
// conformance program from the correct single-file golden
// (question_generic_mixed.carbon). Under multi-file lowering the specific
// coalescer's per-file fingerprint stores can be queried at slots that
// were never written — a specific whose `llvm::Function` was created while
// lowering a different file is never fingerprinted in this file's store,
// and callee specific ids recorded from another file's SemIR index this
// file's stores — and an ABSENT fingerprint reads as the default
// (all-zero) value, so an absent/absent pair compares EQUAL and commits.
// What this pins, in use.carbon's module: every function of the chain
// (Chain, Step, the Try impl's Branch/FromBreak, the Err/Ok constructors,
// the ControlFlow constructors) must have TWO distinct lowered defines
// with correct per-width shapes — the i64 leg's carrier and result objects
// 16 bytes (`<{ <{ i1, [7 x i8] }>, [8 x i8] }>`, payload at byte 8,
// covering copies of 16), the i32 leg's 8 bytes — and every wide call site
// (Call64's chain, MakeErr64, ReadErr64) must address only wide defines.
// Falsification (the pre-fix signature): any cross-width pair resolving to
// ONE lowered body — a wide call site calling a define whose sret pointee
// or GEP shapes are the narrow 8-byte object — or a missing wide define,
// or a covering memcpy shorter than the specific's object size.

// --- lib.carbon
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

// A generic step: passes `x` through, or fails with the given tag — the
// maker whose call results are the `?` operand temporaries below.
fn Step[T: type](x: T, fail: bool, tag: i32) -> MyResult(T, i32) {
  if (fail) { return MyResult(T, i32).Err(tag); }
  return MyResult(T, i32).Ok(x);
}

// Payload sink — the check golden's proven deduced-sink shape
// (toolchain/check/testdata/operators/question.carbon `Discard`).
fn Discard[U: type](_: U) {}

// The generic `?` chain with CALL-RESULT-temporary operands (the failing
// conformance program's shape, fork/conformance/programs/error_handling/
// question_generic_diff.carbon `Chain`).
fn Chain[T: type](x: T, failA: bool, failB: bool) -> MyResult(T, i32) {
  Discard(Step(x, failA, 101)?);
  Discard(Step(x, failB, 202)?);
  return MyResult(T, i32).Ok(x);
}

// The library's own narrow instantiation: the narrow specifics' LLVM
// functions exist in lib's module under their canonical mangled names, so
// the importing file's references to the SAME specifics take the
// already-created path.
fn LibCall32(x: i32, failA: bool, failB: bool) -> MyResult(i32, i32) {
  return Chain(x, failA, failB);
}

// --- use.carbon
library "[[@TEST_NAME]]";

import library "lib";

// Narrow first, wide second — the failing program's instantiation order.
fn Call32(x: i32, failA: bool, failB: bool) -> MyResult(i32, i32) {
  return Chain(x, failA, failB);
}

fn Call64(x: i64, failA: bool, failB: bool) -> MyResult(i64, i32) {
  return Chain(x, failA, failB);
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
