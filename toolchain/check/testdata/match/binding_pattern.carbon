// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// TODO: Extend the "int" min_prelude to support basic integer operations, so we
// can use it here.
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/binding_pattern.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/binding_pattern.carbon

// A bare `name: type` binding in a `case` pattern is irrefutable: the arm
// always matches, and the binding binds the scrutinee's value in the arm's
// scope (re-platform plan S2b).
//@dump-sem-ir-begin
fn F(x: i32) -> i32 {
  match (x) {
    case a: i32 => { return a; }
    default => { return 0; }
  }
  return -1;
}

// A binding arm after a literal arm: the literal arm tests first
// (first-match-wins) and the binding arm catches everything else. `default`
// stays required even when a binding arm makes it unreachable
// (exhaustiveness is a later slice).
fn G(x: i32) -> i32 {
  match (x) {
    case 5 => { return 100; }
    case b: i32 => { return b; }
    default => { return 0; }
  }
  return -1;
}

// The `unused` pattern modifier under the arm's implicit `let` introducer:
// a binding marked `unused` and not used produces no diagnostic.
fn H(x: i32) -> i32 {
  match (x) {
    case unused c: i32 => { return 9; }
    default => { return 0; }
  }
  return -1;
}
//@dump-sem-ir-end
