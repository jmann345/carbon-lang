// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/exhaustive_choice.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/exhaustive_choice.carbon

// A choice scrutinee's alternatives are a closed set, so a `match` whose
// unguarded arms cover every alternative needs no `default` arm (SF-7;
// re-platform plan S2e). The last arm's else edge — dynamically dead when
// the arms are exhaustive — branches to the resumption block, the same
// shape an empty `default` arm produces.

// --- payload_free.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
choice Flag {
  Off,
  On
}

// Every payload-free alternative is covered by an unguarded arm, so no
// `default` arm is required.
fn Classify(f: Flag) -> i32 {
  match (f) {
    case .Off => { return 0; }
    case .On => { return 1; }
  }
  return -1;
}
//@dump-sem-ir-end

// --- payload.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
choice IntResult {
  Ok(value: i32),
  Err
}

// The docs/design/sum_types.md `match` example's shape (with a concrete
// choice; generic choices are out of slice): a payload-destructuring arm
// and a constant arm cover both alternatives, so no `default` is required.
fn Consume(r: IntResult) -> i32 {
  match (r) {
    case .Ok(value: i32) => { return value; }
    case .Err => { return -1; }
  }
  return -2;
}
//@dump-sem-ir-end

// --- guarded_duplicate.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
choice IntResult {
  Ok(value: i32),
  Err
}

// A guarded arm never counts toward coverage, but the same alternative
// covered again by an unguarded arm does: `.Ok` values split on the guard,
// and the match is still exhaustive without a `default` arm.
fn Consume(r: IntResult) -> i32 {
  match (r) {
    case .Ok(v: i32) if (v > 0) => { return v; }
    case .Ok(w: i32) => { return w - 1; }
    case .Err => { return -10; }
  }
  return -20;
}
//@dump-sem-ir-end

// --- with_default.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
choice Flag {
  Off,
  On
}

// A `default` arm on an exhaustive match stays accepted; it can never be
// taken. Diagnosing it as useless is future work (see
// docs/design/pattern_matching.md on usefulness).
fn Classify(f: Flag) -> i32 {
  match (f) {
    case .Off => { return 0; }
    case .On => { return 1; }
    default => { return -1; }
  }
  return -2;
}
//@dump-sem-ir-end

// --- signal.carbon
library "signal";

choice Signal {
  Go(speed: i32),
  Stop,
  Wait
}

// --- use_imported.carbon
library "use_imported";

import library "signal";

//@dump-sem-ir-begin
// Matching over a choice declared in another library: the alternative table
// (the S2c `SemIR::ChoiceAlternative` metadata on the class) arrives through
// import, so covering every alternative discharges the `default` requirement
// exactly as for a same-file choice.
fn Classify(s: Signal) -> i32 {
  match (s) {
    case .Go(speed: i32) => { return speed; }
    case .Stop => { return 0; }
    case .Wait => { return 1; }
  }
  return -1;
}
//@dump-sem-ir-end
