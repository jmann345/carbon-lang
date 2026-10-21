// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/match/constant_choice_scrutinee.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/match/constant_choice_scrutinee.carbon

// Fork (SV-1, fork/sumtype-interop/plan.md D-SV-9): a `match` directly on a
// constant choice value with a payload arm. The payload access folds to the
// payload region's constant, which lowering now gives an address (a private
// constant global) before indexing into it; trunk built a load from a
// non-pointer constant and failed LLVM verification.

choice Opt(T: type) {
  Some(value: T),
  None
}

fn Sink(unused n: i32) {}

fn F() -> i32 {
  match (Opt(i32).None) {
    case .Some(v: i32) => {
      Sink(v);
      return v;
    }
    case .None => {
      return -1;
    }
  }
  return -2;
}

