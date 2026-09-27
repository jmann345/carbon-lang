// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/parse/testdata/let/let_else.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/parse/testdata/let/let_else.carbon

// `let`-`else` declarations (W-012, fork/design-sprint/if-let.md Option A):
// a `let` or `var` declaration followed by `else` and a code block. The
// introducer is re-kinded to `LetElseIntroducer` when the `else` is reached,
// the `else` is a `LetElse` leaf hooking the block, and `LetElseDecl` closes
// the declaration at the introducer token. No trailing `;`.

// --- basic.carbon

fn F(y: i32) -> i32 {
  let x: i32 = y else { return 0; }
  return x;
}

// --- alternative_payload.carbon

fn F(opt: Opt) -> i32 {
  let .Some(port: i32) = opt else { return -1; }
  return port;
}

// --- alternative_bare.carbon

fn F(opt: Opt) -> i32 {
  let .None = opt else { return -1; }
  return 0;
}

// --- var_else.carbon

fn F(opt: Opt) -> i32 {
  var .Some(v: i32) = opt else { return 0; }
  v = v + 1;
  return v;
}

// --- tuple.carbon

fn F(pair: (i32, i32)) -> i32 {
  let (0, n: i32) = pair else { return -1; }
  return n;
}

// --- with_modifier.carbon

fn F(opt: Opt) -> i32 {
  private let .Some(n: i32) = opt else { return -1; }
  return n;
}

// --- returned_var_else.carbon

fn F(opt: Opt) -> i32 {
  returned var .Some(v: i32) = opt else { return 0; }
  return var;
}

// --- if_expr_struct_literal_else.carbon

fn F(c: bool, t: {.a: i32}, u: {}) {
  var s: {.a: i32} = if c then t else {.a = 1};
  var e: {} = if c then u else {};
}
