// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/fail_var_alternative.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/fail_var_alternative.carbon

// A `var`-wrapped alternative arm covers its alternative only: alone on a
// two-alternative choice it is nonexhaustive, naming `.None` (fork/w012/
// plan.md §1.1, re-review M1 — without the `is_irrefutable_var_arm`
// exclusion the arm would have marked the `match` exhaustive).

// --- fail_nonexhaustive_var_alternative.carbon
library "[[@TEST_NAME]]";

choice OptInt {
  Some(x: i32),
  None
}

// CHECK:STDERR: fail_nonexhaustive_var_alternative.carbon:[[@LINE+4]]:8: warning: binding `n` unused [UnusedBinding]
// CHECK:STDERR: fn Use(n: i32) {}
// CHECK:STDERR:        ^~~~~~
// CHECK:STDERR:
fn Use(n: i32) {}

fn F(o: OptInt) -> i32 {
  // CHECK:STDERR: fail_nonexhaustive_var_alternative.carbon:[[@LINE+4]]:3: error: `match` on choice `OptInt` has no `default` arm and does not cover alternative `.None` [MatchNonexhaustive]
  // CHECK:STDERR:   match (o) {
  // CHECK:STDERR:   ^~~~~~~~~~~
  // CHECK:STDERR:
  match (o) {
    case var .Some(n: i32) => { Use(n); }
  }
  return -1;
}
