// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/var_alternative.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/var_alternative.carbon

// A `var`-wrapped alternative root in a `case` (the var-alternative lane,
// fork/w012/plan.md §1.1, decision R29a): the discriminant test through the
// alternative, then one payload-tuple-typed on-demand `VarStorage` in the
// arm's body block, bound elementwise. The arm records its ALTERNATIVE for
// exhaustiveness, never an irrefutable arm: a trailing `default` is not
// dead, and the arm alone is not exhaustive (fail_var_alternative.carbon).
// Payload-level `var` (`.Some(var n: i32)`) is the alternative-payload lane
// with on-demand storage for the element.

// --- root_var.carbon
library "[[@TEST_NAME]]";

choice OptInt {
  Some(x: i32),
  None
}

//@dump-sem-ir-begin
fn F(o: OptInt) -> i32 {
  match (o) {
    case var .Some(n: i32) => { n = n + 1; return n; }
    case .None => { return 0; }
  }
  return -1;
}
//@dump-sem-ir-end

// --- payload_var.carbon
library "[[@TEST_NAME]]";

choice OptInt {
  Some(x: i32),
  None
}

//@dump-sem-ir-begin
fn F(o: OptInt) -> i32 {
  match (o) {
    case .Some(var n: i32) => { n = n + 2; return n; }
    case .None => { return 0; }
  }
  return -1;
}
//@dump-sem-ir-end

// --- var_alternative_then_default.carbon
library "[[@TEST_NAME]]";

// The `default` is NOT dead: the arm covers `.Some` only.
choice OptInt {
  Some(x: i32),
  None
}

fn Use(n: i32) {}

//@dump-sem-ir-begin
fn F(o: OptInt) -> i32 {
  match (o) {
    case var .Some(n: i32) => { Use(n); }
    default => { return 0; }
  }
  return -1;
}
//@dump-sem-ir-end
