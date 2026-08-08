// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/exhaustive_choice_binding.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/exhaustive_choice_binding.carbon

// An unguarded binding-pattern arm is irrefutable — it covers every
// scrutinee value — so a choice `match` containing one is exhaustive
// without a `default` arm and without covering each alternative (SF-7;
// re-platform plan S2e).

// --- final_binding_arm.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
choice Signal {
  Go(speed: i32),
  Stop,
  Wait
}

// `.Stop` is covered by an alternative arm; everything else falls to the
// irrefutable binding arm, which discharges the `default` requirement.
fn Classify(s: Signal) -> i32 {
  match (s) {
    case .Stop => { return 0; }
    case other: Signal => { return 1; }
  }
  return -1;
}
//@dump-sem-ir-end

// --- only_binding_arm.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
choice Flag {
  Off,
  On
}

// A single irrefutable arm alone is exhaustive.
fn Consume(f: Flag) -> i32 {
  match (f) {
    case whole: Flag => { return 7; }
  }
  return -1;
}
//@dump-sem-ir-end
