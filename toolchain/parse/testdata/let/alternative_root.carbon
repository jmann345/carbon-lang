// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/parse/testdata/let/alternative_root.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/parse/testdata/let/alternative_root.carbon

// A root `.Name` in a plain `let`/`var` parses as an alternative pattern
// (the same root peek `let`-`else` needs; the parser cannot know about the
// `else` yet). Check gates the refutable root outside a refutable context.

// --- let_root.carbon

fn F(opt: Opt) {
  let .Some(n: i32) = opt;
}

// --- var_root.carbon

fn F(opt: Opt) {
  var .None = opt;
}
