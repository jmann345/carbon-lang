// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/uint.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/choice/payload_construct.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/choice/payload_construct.carbon

// --- payload_construct.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
choice IntResult {
  Ok(value: i32),
  Err
}

// A payload-free alternative constant of a payload-carrying choice: the
// constant covers the payload region with an uninitialized value.
let err: IntResult = IntResult.Err;

// Function-like construction of a payload alternative.
fn Make(n: i32) -> IntResult {
  return IntResult.Ok(n);
}

fn Use(n: i32) {
  // A local of a payload-carrying choice type; its scope exit exercises the
  // destroy-witness path for the payload region.
  var r: IntResult = Make(n);
}
//@dump-sem-ir-end
