// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/parse/testdata/if/if_let.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/parse/testdata/if/if_let.carbon

// Pattern conditions (W-012, fork/design-sprint/if-let.md Option A): `if (`
// followed by `let` or `var` makes the condition a refutable pattern binding.
// The prefix lives directly under `IfCondition`: a `PatternConditionIntroducer`
// leaf, the pattern (a `VariablePattern` wrapper for the `var` spelling), a
// `PatternConditionInitializer` leaf at the `=`, then the initializer
// expression where the boolean condition would be.

// --- let_binding.carbon

fn F(x: i32) {
  if (let n: i32 = x) {}
}

// --- var_binding.carbon

fn F(x: i32) {
  if (var n: i32 = x) {}
}

// --- alternative_bare.carbon

fn F(opt: Opt) {
  if (let .None = opt) {}
}

// --- alternative_payload.carbon

fn F(opt: Opt) {
  if (let .Some(n: i32) = opt) {}
}

// --- var_alternative.carbon

fn F(opt: Opt) {
  if (var .Some(n: i32) = opt) {}
}

// --- tuple.carbon

fn F(pair: (i32, i32)) {
  if (let (0, n: i32) = pair) {}
}

// --- else_if_chain.carbon

fn F(pair: (i32, i32)) {
  if (let (0, n: i32) = pair) {
  } else if (let (n: i32, 0) = pair) {
  } else {
  }
}

// --- nested_in_match_arm.carbon

fn F(opt: Opt, x: i32) {
  match (x) {
    case 0 => {
      if (let .Some(n: i32) = opt) {}
    }
    default => {}
  }
}

// --- parenthesized_and.carbon

fn F(x: bool, y: bool) {
  if (let b: bool = (x and y)) {}
}
