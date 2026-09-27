// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/union/layout.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/union/layout.carbon

// The layout rule (docs/design/unions.md, "Layout"): every field at offset
// 0, alignment the maximum field alignment, size the maximum field size
// rounded up to that alignment.

//@dump-sem-ir-begin
union Wide {
  var lo: i32;
  var both: i64;
}

union Odd {
  var a: i8;
  var b: i16;
  var c: array(i8, 3);
}

union OneByte {
  var b: bool;
}

union Ptr {
  var p: i32*;
  var n: i64;
}
//@dump-sem-ir-end
