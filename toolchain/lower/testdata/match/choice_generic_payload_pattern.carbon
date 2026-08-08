// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/match/choice_generic_payload_pattern.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/match/choice_generic_payload_pattern.carbon
// CHECK:STDERR: {{.*}}/prelude/try.carbon:20:1: error: name `Core.ImplicitAs` implicitly referenced here, but not found [CoreNameNotFound]
// CHECK:STDERR: choice ControlFlow(C: type, B: type) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: {{.*}}/prelude/try.carbon:20:1: error: name `Core.ImplicitAs` implicitly referenced here, but not found [CoreNameNotFound]
// CHECK:STDERR: choice ControlFlow(C: type, B: type) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:

// What this pins beyond the S3b lower goldens (W5-S3c): ELEMENT extraction
// from the payload region per specific. S3b's destructure subfile
// (lower/testdata/choice/generic_payload.carbon) extracts a single-element
// payload from one specific; here the same generic choice destructures in
// two specifics with multi-element payloads, so the second element's
// offset differs per specific — `Pair(i32)`'s `(i32, i32)` reads at byte
// offsets 0 and 4 inside `[8 x i8]`, and `Pair(i64)`'s `(i64, i64)` at 0
// and 8 inside `[16 x i8]` (F-007k; risk R-1's derived numbers). Equal
// offsets across the specifics, or extraction through a stale region
// type, falsify the per-specific resolution. The symbolic subfile pins the
// R-8 lowering shape: a generic BODY's destructure instantiated at a
// concrete specific extracts through the substituted layout.

// --- two_sizes_destructure.carbon
library "[[@TEST_NAME]]";

choice Pair(T: type) {
  Both(x: T, y: T),
  Neither
}

fn Sum32(p: Pair(i32)) -> i32 {
  match (p) {
    case .Both(x: i32, y: i32) => { return x + y; }
    case .Neither => { return 0; }
  }
  // Unreachable: every arm returns.
  return -1;
}

fn Sum64(p: Pair(i64)) -> i64 {
  match (p) {
    case .Both(x: i64, y: i64) => { return x + y; }
    case .Neither => { return 0; }
  }
  // Unreachable: every arm returns.
  return -1;
}

fn Run() -> i32 {
  let a: Pair(i32) = Pair(i32).Both(1, 2);
  let b: Pair(i64) = Pair(i64).Both(3, 4);
  if (Sum64(b) != 7) {
    return 1;
  }
  return Sum32(a) - 3;
}

// --- symbolic.carbon
library "[[@TEST_NAME]]";

// The check-side symbolic subfile's lower counterpart
// (check/testdata/match/choice_generic_payload_pattern.carbon): the generic
// body's destructure is checked against the symbolic payload tuple, and
// `Call`'s `Classify(Pair-shaped P(i32))` instantiation lowers the element
// accesses through the specific's recomputed `[8 x i8]` region.
choice P(T: type) {
  Both(x: T, y: T),
  Neither
}

fn Discard[U: type](_: U, _: U) {}

fn Classify[T: type](p: P(T)) -> i32 {
  match (p) {
    case .Both(a: T, b: T) => {
      Discard(a, b);
      return 1;
    }
    case .Neither => { return 0; }
  }
  // Unreachable: every arm returns.
  return -1;
}

fn Call(p: P(i32)) -> i32 {
  return Classify(p);
}

