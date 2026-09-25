// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/fail_case_never_matches_struct.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/fail_case_never_matches_struct.carbon

// Usefulness diagnostics for struct `case` patterns (W-066 + W-077):
// struct keys are NORMALIZED to the scrutinee's full field set in the
// scrutinee's canonical field order, with synthetic wildcards for omitted
// fields, so duplicates are order-free, a subset+`_` prior subsumes the
// full-set constant, and per-field bindings act as wildcards. Where no arm
// is irrefutable the trailing `default` arms are live (W-078b).

// --- fail_duplicate_exact.carbon
library "[[@TEST_NAME]]";

// A duplicate constant field vector.
fn F(p: {.a: i32, .b: i32}) -> i32 {
  match (p) {
    case {.a = 1, .b = 2} => { return 1; }
    case {.a = 1, .b = 2} => { return 2; }
    default => { return 0; }
  }
  return -1;
}

// --- fail_reordered_duplicate.carbon
library "[[@TEST_NAME]]";

// The normalization is order-free: a reordered spelling of the same
// constraint set is dead.
fn F(p: {.a: i32, .b: i32}) -> i32 {
  match (p) {
    case {.a = 1, .b = 2} => { return 1; }
    case {.b = 2, .a = 1} => { return 2; }
    default => { return 0; }
  }
  return -1;
}

// --- fail_subset_subsumes.carbon
library "[[@TEST_NAME]]";

// A subset+`_` prior's omitted field keys as a wildcard, which subsumes
// the later full-set constant.
fn F(p: {.a: i32, .b: i32}) -> i32 {
  match (p) {
    case {.a = 1, _} => { return 1; }
    case {.a = 1, .b = 2} => { return 2; }
    default => { return 0; }
  }
  return -1;
}

// --- fail_after_irrefutable_struct.carbon
library "[[@TEST_NAME]]";

// An all-binding struct arm keys as the single `{Wildcard}`, killing any
// later struct constant arm (and discharging exhaustiveness, so there is
// no `default`).
fn F(p: {.a: i32, .b: i32}) -> i32 {
  match (p) {
    case {a: i32, b: i32} => { return a + b; }
    case {.a = 1, .b = 2} => { return 2; }
  }
  return -1;
}

// --- fail_wildcard_field.carbon
library "[[@TEST_NAME]]";

// A per-field binding is a per-field wildcard: `{.a = 1, .b = b: i32, _}`
// matches every `{.a = 1, ...}`, so the later constant pair is dead.
fn F(p: {.a: i32, .b: i32}) -> i32 {
  match (p) {
    case {.a = 1, .b = b: i32, _} => { return b; }
    case {.a = 1, .b = 2} => { return 2; }
    default => { return 0; }
  }
  return -1;
}
