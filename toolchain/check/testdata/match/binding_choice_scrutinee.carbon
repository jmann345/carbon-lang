// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/binding_choice_scrutinee.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/binding_choice_scrutinee.carbon

// A `case` binding pattern also binds a choice-typed scrutinee's value, and
// the bound value can itself be matched again in the arm's body — a nested
// match through a case binding (re-platform plan S2b; nested-match stack
// discipline per risks R-2/R-8).
//@dump-sem-ir-begin
choice Signal {
  Go(speed: i32),
  Stop,
  Wait
}

fn Classify(s: Signal) -> i32 {
  match (s) {
    case .Stop => { return 0; }
    case c: Signal => {
      match (c) {
        case .Wait => { return 1; }
        default => { return 2; }
      }
    }
    default => { return 3; }
  }
  return -1;
}
//@dump-sem-ir-end
