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

// CHECK:STDERR: fail_todo_two_segments.carbon:[[@LINE+4]]:27: error: semantics TODO: `tuple with more than one pack segment` [SemanticsTodo]
// CHECK:STDERR: fn F[... each T: type](t: (... each T, ... each T));
// CHECK:STDERR:                           ^~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn F[... each T: type](t: (... each T, ... each T));

// --- fail_todo_elements_beside_segment.carbon
library "[[@TEST_NAME]]";

fn F[... each T: Core.Copy](... each x: each T) -> (i64, ... each T) {
  // CHECK:STDERR: fail_todo_elements_beside_segment.carbon:[[@LINE+4]]:10: error: semantics TODO: `tuple pack segment matched with other segments` [SemanticsTodo]
  // CHECK:STDERR:   return (0, ... each x);
  // CHECK:STDERR:          ^~~~~~~~~~~~~~~
  // CHECK:STDERR:
  return (0, ... each x);
}

// --- fail_todo_segment_to_elements.carbon
library "[[@TEST_NAME]]";

fn F[... each T: Core.Copy](... each x: each T) {
  // CHECK:STDERR: fail_todo_segment_to_elements.carbon:[[@LINE+4]]:30: error: semantics TODO: `tuple pack segment matched with other segments` [SemanticsTodo]
  // CHECK:STDERR:   let unused t: (i64, i64) = (... each x);
  // CHECK:STDERR:                              ^~~~~~~~~~~~
  // CHECK:STDERR:
  let unused t: (i64, i64) = (... each x);
}

// --- fail_todo_index_segment.carbon
library "[[@TEST_NAME]]";

fn F[... each T: Core.Copy](t: (... each T)) {
  // CHECK:STDERR: fail_todo_index_segment.carbon:[[@LINE+4]]:23: error: semantics TODO: `tuple index at or after a pack segment` [SemanticsTodo]
  // CHECK:STDERR:   let unused a: i64 = t.0;
  // CHECK:STDERR:                       ^~~
  // CHECK:STDERR:
  let unused a: i64 = t.0;
}

// --- fail_todo_index_past_segment.carbon
library "[[@TEST_NAME]]";

fn F[... each T: Core.Copy](t: (i64, ... each T)) {
  // CHECK:STDERR: fail_todo_index_past_segment.carbon:[[@LINE+4]]:23: error: semantics TODO: `tuple index at or after a pack segment` [SemanticsTodo]
  // CHECK:STDERR:   let unused a: i64 = t.1;
  // CHECK:STDERR:                       ^~~
  // CHECK:STDERR:
  let unused a: i64 = t.1;
  // CHECK:STDERR: fail_todo_index_past_segment.carbon:[[@LINE+4]]:23: error: semantics TODO: `tuple index at or after a pack segment` [SemanticsTodo]
  // CHECK:STDERR:   let unused b: i64 = t.7;
  // CHECK:STDERR:                       ^~~
  // CHECK:STDERR:
  let unused b: i64 = t.7;
}

// --- fail_todo_index_rewrap.carbon
library "[[@TEST_NAME]]";

fn G[... each T: Core.Copy](unused t: (... each T)) {}

fn F[... each T: Core.Copy](t: (... each T)) {
  // CHECK:STDERR: fail_todo_index_rewrap.carbon:[[@LINE+4]]:6: error: semantics TODO: `tuple index at or after a pack segment` [SemanticsTodo]
  // CHECK:STDERR:   G((t.0,));
  // CHECK:STDERR:      ^~~
  // CHECK:STDERR:
  G((t.0,));
}
