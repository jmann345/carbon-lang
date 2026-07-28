// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/nested_choice_designator.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/nested_choice_designator.carbon

// Designator patterns in a match nested inside another match's arms: the
// designator's scrutinee lookup and the node-stack scrutinee protocol must
// hold across the per-arm pattern context (re-platform plan R-8).

//@dump-sem-ir-begin
choice Color {
  Red,
  Green
}

choice Shape {
  Circle,
  Square
}

fn F(c: Color, s: Shape) -> i32 {
  match (c) {
    case .Red => {
      match (s) {
        case .Circle => { return 1; }
        default => { return 2; }
      }
    }
    default => {
      match (s) {
        case .Square => { return 3; }
        default => { return 4; }
      }
    }
  }
  return 0;
}
//@dump-sem-ir-end
