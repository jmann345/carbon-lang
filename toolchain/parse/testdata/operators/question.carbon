// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/parse/testdata/operators/question.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/parse/testdata/operators/question.carbon

// Postfix `?` parses in the expression postfix loop (fork/b1/plan.md §2.3):
// highest (suffix) precedence, chaining left-to-right with `.`, `->`, calls,
// and indexing, and repeatable.

fn Chain(n: i32) {
  Open(n)?.Read()?.x;
}

fn MemberAfterQuestion(x: i32) {
  x?.y;
}

fn ArrowThenQuestion(x: i32) {
  x->y?;
}

fn Repeat(x: i32) {
  x??;
}

fn IndexAfterQuestion(a: i32, i: i32) {
  a?[i];
}

fn PrefixBindsOutside(x: i32) {
  -x?;
  not x?;
}

fn InfixOperands(x: i32, y: i32) {
  x? + y?;
}

fn AsOperand(x: i32) {
  x? as T;
}

// C-1 (fork/b1/plan.md §2.3): whitespace before a postfix-loop `?` is
// accepted silently — the loop's suffix components, unlike the `ExprLoop`
// operator table, perform no fixity/whitespace check.
fn WhitespaceBeforeQuestion(x: i32) {
  x ?;
}

// The `->?` and `:?` form tokens are unaffected by postfix `?`: max munch
// already lexed each as a single token, and they still parse as form
// declaration syntax, never as `->`/`:` followed by a postfix `?`.
fn FormReturn() ->? Form;
fn FormParam(x:? Form);
