// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/choice_payload_imported.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/choice_payload_imported.carbon

// --- signal.carbon
library "signal";

choice Signal {
  Go(speed: i32),
  Stop,
  Wait
}

// --- use.carbon
library "use";

import library "signal";

//@dump-sem-ir-begin
// Destructuring the payload of a choice declared in another library: the
// alternatives' name-to-index metadata (discriminant value and payload
// field position) must arrive through the class import for the pattern to
// resolve `.Go` and extract its payload.
fn Speed(s: Signal) -> i32 {
  match (s) {
    case .Go(speed: i32) => { return speed; }
    case .Stop => { return 0; }
    default => { return -1; }
  }
  return -2;
}
//@dump-sem-ir-end
