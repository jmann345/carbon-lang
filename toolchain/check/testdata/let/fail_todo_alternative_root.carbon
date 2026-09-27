// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/let/fail_todo_alternative_root.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/let/fail_todo_alternative_root.carbon

// A root `.Name` in a plain `let`/`var` parses as an alternative pattern
// (the parser cannot know whether an `else` follows) and stays behind a TODO
// outside a refutable pattern context — the disposition a refutable
// expression pattern root such as `let 5 = x;` has today (fork/w012/plan.md
// §1.13). Each TODO aborts the file, so one row per split file.

// --- fail_let_root.carbon
library "[[@TEST_NAME]]";

choice OptInt {
  Some(x: i32),
  None
}

fn F(opt: OptInt) {
  let .Some(n: i32) = opt;
}

// --- fail_var_root.carbon
library "[[@TEST_NAME]]";

choice OptInt {
  Some(x: i32),
  None
}

fn F(opt: OptInt) {
  var .None = opt;
}
