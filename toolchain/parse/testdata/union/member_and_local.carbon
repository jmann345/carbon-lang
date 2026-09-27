// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/parse/testdata/union/member_and_local.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/parse/testdata/union/member_and_local.carbon

// A union as a class member.
class Outer {
  union Inner {
    var a: i32;
  }
  var u: Inner;
}

// A union declared inside a function body takes the statement-context
// declaration dispatch.
fn F() {
  union Local {
    var b: i64;
  }
}
