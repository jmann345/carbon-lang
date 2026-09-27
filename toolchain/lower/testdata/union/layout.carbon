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
  var lo: i32;
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
  var a: i8;
  var b: i16;
  var c: array(i8, 3);
}

fn UseOdd() -> i16 {
  var o: Odd;
  o.b = 3;
  return o.b;
}
