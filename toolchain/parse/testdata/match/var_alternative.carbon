// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/parse/testdata/match/var_alternative.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/parse/testdata/match/var_alternative.carbon

// A root `var` before a choice alternative pattern in a `case`: the
// `VariablePattern` at the `var` token wraps the `AlternativePattern` root
// (the payload bindings are `var` bindings). Before the root-`var` peek this
// shape misparsed as a `VariablePattern` over an expression pattern.

fn F(opt: Opt) -> i32 {
  match (opt) {
    case var .Some(n: i32) => { n = n + 1; return n; }
    case var .None => { return 0; }
  }
  return -1;
}
