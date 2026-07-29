// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/guard.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/guard.carbon

// Case guards (`case P if (E) => ...`, re-platform plan S2d): the guard
// expression is checked in the arm's scope with the pattern's bindings in
// scope (docs/design/pattern_matching.md, "Guards"), evaluated in the arm's
// body block after the pattern's test and bind passes, and a failed guard
// falls through to the next arm (or `default`), preserving
// first-match-wins.

//@dump-sem-ir-begin
// A guard on a literal arm, referencing the enclosing scope.
fn Literal(x: i32) -> i32 {
  match (x) {
    case 0 if (x > -1) => { return 1; }
    default => { return 0; }
  }
  return -1;
}

// Guards using the arms' own bindings, in the guard and in the body. Both
// arms are irrefutable binding patterns, so only the guards discriminate:
// a failed first guard falls through to the second arm, and a failed
// second guard falls through to `default`.
fn Binding(x: i32) -> i32 {
  match (x) {
    case a: i32 if (a < 0) => { return a; }
    case b: i32 if (b > 10) => { return b; }
    default => { return 0; }
  }
  return -1;
}

// A side-effect-free compound guard: `and` short-circuits, so the guard's
// captured expression region is multi-block and splices into the arm's
// body block with branches rather than a `splice_block`.
fn Compound(x: i32) -> i32 {
  match (x) {
    case c: i32 if (c > 0 and c < 10) => { return 1; }
    default => { return 0; }
  }
  return -1;
}

// A guarded arm whose binding's declared type converts from the
// scrutinee's (`n: i64` from an `i32` scrutinee): the bind pass's
// conversion runs before the guard, its objects are deferred to the arm
// scope's cleanups, and the guard's failure edge discharges them before
// falling through to `default`.
fn Converting(x: i32) -> i64 {
  match (x) {
    case n: i64 if (n > 0) => { return n; }
    default => { return 0; }
  }
  return -1;
}
//@dump-sem-ir-end
