// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/choice_scrutinee.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/choice_scrutinee.carbon

// --- choice_scrutinee.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
choice Signal {
  Go(speed: i32),
  Stop,
  Wait
}

// Leading-dot payload-free alternative patterns compare the alternative's
// index against the scrutinee's discriminant; `default` covers the payload
// alternative until slice-2 destructuring and exhaustiveness land.
fn Classify(s: Signal) -> i32 {
  match (s) {
    case .Stop => { return 0; }
    case .Wait => { return 1; }
    default => { return 2; }
  }
  return -1;
}
//@dump-sem-ir-end

// --- payload_free_scrutinee.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
// A payload-free choice scrutinee: same dispatch, no payload region.
choice Flag {
  On,
  Off
}

fn IsOn(f: Flag) -> i32 {
  match (f) {
    case .On => { return 1; }
    default => { return 0; }
  }
  return -1;
}
//@dump-sem-ir-end
