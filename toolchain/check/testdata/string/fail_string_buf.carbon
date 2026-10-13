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
  var unused t: Core.StringBuf = s;
}

// --- fail_return_var.carbon

library "[[@TEST_NAME]]";

fn R() -> Core.StringBuf {
  var s: Core.StringBuf = Core.StringBuf.Make("x");
  return s;
}

// --- fail_unformed.carbon

library "[[@TEST_NAME]]";

fn U() {
  var unused u: Core.StringBuf;
}

// --- fail_view_to_owned.carbon

library "[[@TEST_NAME]]";

fn V(v: str) -> Core.StringBuf { return v; }
