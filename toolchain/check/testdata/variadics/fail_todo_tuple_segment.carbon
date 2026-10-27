// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/primitives.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/variadics/fail_todo_tuple_segment.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/variadics/fail_todo_tuple_segment.carbon

// --- fail_todo_two_segments.carbon
library "[[@TEST_NAME]]";

fn F[... each T: type](t: (... each T, ... each T));

// --- fail_todo_elements_beside_segment.carbon
library "[[@TEST_NAME]]";

fn F[... each T: Core.Copy](... each x: each T) -> (i64, ... each T) {
  return (0, ... each x);
}

// --- fail_todo_segment_to_elements.carbon
library "[[@TEST_NAME]]";

fn F[... each T: Core.Copy](... each x: each T) {
  let unused t: (i64, i64) = (... each x);
}
