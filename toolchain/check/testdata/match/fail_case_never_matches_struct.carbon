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
// CHECK:STDERR: {{.*}}/prelude/types/cpp/slice.carbon:69:9: error: cannot access member of interface `Destroy` in type `C.(CppContiguousRange.SizeType)` that does not implement that interface [MissingImplInMemberAccess]
// CHECK:STDERR:         self.Size().(ImplicitAs(u64).Convert)().(As(i64).Convert)());
// CHECK:STDERR:         ^~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: {{.*}}/prelude/types/cpp/slice.carbon:68:9: error: cannot access member of interface `Destroy` in type `C.(CppContiguousRange.DataType)` that does not implement that interface [MissingImplInMemberAccess]
// CHECK:STDERR:         self.Data().(CppDataPointer.Raw)(),
// CHECK:STDERR:         ^~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: {{.*}}/prelude/types/cpp/slice.carbon:64:1: error: orphan `impl` found; something in the self-type or constraint must be defined in the same file [ImplIsOrphan]
// CHECK:STDERR: impl forall [C: CppContiguous where .Element impls Copy & Destroy]
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:

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
    // CHECK:STDERR: fail_duplicate_exact.carbon:[[@LINE+7]]:5: error: `case` pattern never matches; every value it can match is matched by a prior arm [MatchCaseNeverMatches]
    // CHECK:STDERR:     case {.a = 1, .b = 2} => { return 2; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR: fail_duplicate_exact.carbon:[[@LINE-4]]:5: note: pattern is fully covered by this prior arm [MatchCaseNeverMatchesPriorArm]
    // CHECK:STDERR:     case {.a = 1, .b = 2} => { return 1; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR:
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
    // CHECK:STDERR: fail_reordered_duplicate.carbon:[[@LINE+7]]:5: error: `case` pattern never matches; every value it can match is matched by a prior arm [MatchCaseNeverMatches]
    // CHECK:STDERR:     case {.b = 2, .a = 1} => { return 2; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR: fail_reordered_duplicate.carbon:[[@LINE-4]]:5: note: pattern is fully covered by this prior arm [MatchCaseNeverMatchesPriorArm]
    // CHECK:STDERR:     case {.a = 1, .b = 2} => { return 1; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR:
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
    // CHECK:STDERR: fail_subset_subsumes.carbon:[[@LINE+7]]:5: error: `case` pattern never matches; every value it can match is matched by a prior arm [MatchCaseNeverMatches]
    // CHECK:STDERR:     case {.a = 1, .b = 2} => { return 2; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR: fail_subset_subsumes.carbon:[[@LINE-4]]:5: note: pattern is fully covered by this prior arm [MatchCaseNeverMatchesPriorArm]
    // CHECK:STDERR:     case {.a = 1, _} => { return 1; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR:
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
    // CHECK:STDERR: fail_after_irrefutable_struct.carbon:[[@LINE+7]]:5: error: `case` pattern never matches; every value it can match is matched by a prior arm [MatchCaseNeverMatches]
    // CHECK:STDERR:     case {.a = 1, .b = 2} => { return 2; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR: fail_after_irrefutable_struct.carbon:[[@LINE-4]]:5: note: pattern is fully covered by this prior arm [MatchCaseNeverMatchesPriorArm]
    // CHECK:STDERR:     case {a: i32, b: i32} => { return a + b; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR:
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
    // CHECK:STDERR: fail_wildcard_field.carbon:[[@LINE+7]]:5: error: `case` pattern never matches; every value it can match is matched by a prior arm [MatchCaseNeverMatches]
    // CHECK:STDERR:     case {.a = 1, .b = 2} => { return 2; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR: fail_wildcard_field.carbon:[[@LINE-4]]:5: note: pattern is fully covered by this prior arm [MatchCaseNeverMatchesPriorArm]
    // CHECK:STDERR:     case {.a = 1, .b = b: i32, _} => { return b; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR:
    case {.a = 1, .b = 2} => { return 2; }
    default => { return 0; }
  }
  return -1;
}
