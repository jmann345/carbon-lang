// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/choice_scrutinee_reexported.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/choice_scrutinee_reexported.carbon

// --- signal.carbon
library "signal";

choice Signal {
  Go(speed: i32),
  Stop,
  Wait
}

// --- relay.carbon
library "relay";

export import library "signal";

// --- use.carbon
library "use";

import library "relay";

//@dump-sem-ir-begin
// Matching over a choice that reaches this file through an `export import`
// hop: the alternative constant's canonical definition lives two files away,
// pinning `GetAlternativeDiscriminant`'s `GetCanonicalFileAndInstId`
// multi-hop path (handle_match.cpp).
fn Classify(s: Signal) -> i32 {
  match (s) {
    case .Stop => { return 0; }
    default => { return 2; }
  }
  return -1;
}

fn Construct(n: i32) -> Signal {
  return Signal.Go(n);
}
//@dump-sem-ir-end
