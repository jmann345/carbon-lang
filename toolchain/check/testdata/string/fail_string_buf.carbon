// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/string/fail_string_buf.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/string/fail_string_buf.carbon

// Fork (ST-1, fork/string/plan.md §4): the pinned 0.1 limits of
// `Core.StringBuf` (D-ST-5, D-ST-6).

// --- fail_copy.carbon

library "[[@TEST_NAME]]";

fn C(s: Core.StringBuf) {
  // CHECK:STDERR: fail_copy.carbon:[[@LINE+7]]:34: error: cannot copy value of type `StringBuf` [CopyOfUncopyableType]
  // CHECK:STDERR:   var unused t: Core.StringBuf = s;
  // CHECK:STDERR:                                  ^
  // CHECK:STDERR: fail_copy.carbon:[[@LINE+4]]:34: note: type `Core.StringBuf` does not implement interface `Core.Copy` [MissingImplInMemberAccessInContext]
  // CHECK:STDERR:   var unused t: Core.StringBuf = s;
  // CHECK:STDERR:                                  ^
  // CHECK:STDERR:
  var unused t: Core.StringBuf = s;
}

// --- fail_return_var.carbon

library "[[@TEST_NAME]]";

fn R() -> Core.StringBuf {
  var s: Core.StringBuf = Core.StringBuf.Make("x");
  // CHECK:STDERR: fail_return_var.carbon:[[@LINE+7]]:10: error: cannot copy value of type `StringBuf` [CopyOfUncopyableType]
  // CHECK:STDERR:   return s;
  // CHECK:STDERR:          ^
  // CHECK:STDERR: fail_return_var.carbon:[[@LINE+4]]:10: note: type `Core.StringBuf` does not implement interface `Core.Copy` [MissingImplInMemberAccessInContext]
  // CHECK:STDERR:   return s;
  // CHECK:STDERR:          ^
  // CHECK:STDERR:
  return s;
}

// --- fail_unformed.carbon

library "[[@TEST_NAME]]";

fn U() {
  // CHECK:STDERR: fail_unformed.carbon:[[@LINE+4]]:3: error: cannot convert type `Core.StringBuf` into type implementing `Core.DefaultOrUnformed` [ConversionFailureTypeToFacet]
  // CHECK:STDERR:   var unused u: Core.StringBuf;
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  var unused u: Core.StringBuf;
}

// --- fail_view_to_owned.carbon

library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_view_to_owned.carbon:[[@LINE+7]]:34: error: cannot implicitly convert expression of type `str` to `Core.StringBuf` [ConversionFailure]
// CHECK:STDERR: fn V(v: str) -> Core.StringBuf { return v; }
// CHECK:STDERR:                                  ^~~~~~~~~
// CHECK:STDERR: fail_view_to_owned.carbon:[[@LINE+4]]:34: note: type `str` does not implement interface `Core.ImplicitAs(Core.StringBuf)` [MissingImplInMemberAccessInContext]
// CHECK:STDERR: fn V(v: str) -> Core.StringBuf { return v; }
// CHECK:STDERR:                                  ^~~~~~~~~
// CHECK:STDERR:
fn V(v: str) -> Core.StringBuf { return v; }
