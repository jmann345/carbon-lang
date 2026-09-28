// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/builtins/failstop.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/builtins/failstop.carbon

// Fork (SL-1, fork/slices/plan.md §4.A): the `fail_stop` builtin. The file is
// named after the builtin without the `fail_` prefix, which file_test reserves
// for diagnosing files.

// --- call.carbon

library "[[@TEST_NAME]]";

fn Stop(message: str) = "fail_stop";

//@dump-sem-ir-begin
fn F() {
  Stop("x");
}
//@dump-sem-ir-end

// --- fail_returns_value.carbon

library "[[@TEST_NAME]]";

// Predicted: `InvalidBuiltinSignature` "invalid signature for builtin function
// \"fail_stop\"" — the builtin returns `()`.
fn Bad(message: str) -> i32 = "fail_stop";
