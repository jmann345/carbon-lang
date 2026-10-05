// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/union/layout.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/union/layout.carbon

// The lowered storage and stores follow the layout rule: `Wide` is
// `[8 x i8]` aligned to 8 with both fields stored at offset 0; `Odd` is
// `[4 x i8]` aligned to 2.

// --- wide.carbon
library "[[@TEST_NAME]]";

union Wide {
  // CHECK:STDERR: wide.carbon:[[@LINE+4]]:7: error: union field `lo` has type `i32`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var lo: i32;
  // CHECK:STDERR:       ^~~~~~~
  // CHECK:STDERR:
  var lo: i32;
  // CHECK:STDERR: wide.carbon:[[@LINE+4]]:7: error: union field `both` has type `i64`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var both: i64;
  // CHECK:STDERR:       ^~~~~~~~~
  // CHECK:STDERR:
  var both: i64;
}

fn UseWide() -> i32 {
  var w: Wide;
  w.both = 5;
  w.lo = 7;
  return w.lo;
}

// --- odd.carbon
library "[[@TEST_NAME]]";

union Odd {
  // CHECK:STDERR: odd.carbon:[[@LINE+4]]:7: error: union field `a` has type `i8`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var a: i8;
  // CHECK:STDERR:       ^~~~~
  // CHECK:STDERR:
  var a: i8;
  // CHECK:STDERR: odd.carbon:[[@LINE+4]]:7: error: union field `b` has type `i16`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var b: i16;
  // CHECK:STDERR:       ^~~~~~
  // CHECK:STDERR:
  var b: i16;
  // CHECK:STDERR: odd.carbon:[[@LINE+4]]:7: error: union field `c` has type `array(i8, 3)`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var c: array(i8, 3);
  // CHECK:STDERR:       ^~~~~~~~~~~~~~~
  // CHECK:STDERR:
  var c: array(i8, 3);
}

fn UseOdd() -> i16 {
  var o: Odd;
  o.b = 3;
  return o.b;
}

