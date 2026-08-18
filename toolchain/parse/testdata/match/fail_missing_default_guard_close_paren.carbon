// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/parse/testdata/match/fail_missing_default_guard_close_paren.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/parse/testdata/match/fail_missing_default_guard_close_paren.carbon

fn f() -> i32 {
  match (true) {
    // CHECK:STDERR: fail_missing_default_guard_close_paren.carbon:[[@LINE+8]]:16: error: opening symbol without a corresponding closing symbol [UnmatchedOpening]
    // CHECK:STDERR:     default if (false => { return 1; }
    // CHECK:STDERR:                ^
    // CHECK:STDERR:
    // CHECK:STDERR: fail_missing_default_guard_close_paren.carbon:[[@LINE+4]]:23: error: expected `)` [ExpectedMatchCaseGuardCloseParen]
    // CHECK:STDERR:     default if (false => { return 1; }
    // CHECK:STDERR:                       ^~
    // CHECK:STDERR:
    default if (false => { return 1; }
  }
  return 0;
}

// CHECK:STDOUT: - filename: fail_missing_default_guard_close_paren.carbon
// CHECK:STDOUT:   ╭─FileStart ''
// CHECK:STDOUT:   │   ╭─FunctionIntroducer 'fn'
// CHECK:STDOUT:   │   ├─IdentifierNameMaybeBeforeSignature 'f'
// CHECK:STDOUT:   │   │ ╭─ExplicitParamListStart '('
// CHECK:STDOUT:   │   ├─ExplicitParamList ')'
// CHECK:STDOUT:   │   │ ╭─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │   ├─ReturnType '->'
// CHECK:STDOUT:   │ ╭─FunctionDefinitionStart '{'
// CHECK:STDOUT:   │ │   ╭─MatchIntroducer 'match'
// CHECK:STDOUT:   │ │   │ ╭─MatchConditionStart '('
// CHECK:STDOUT:   │ │   │ ├─BoolLiteralTrue 'true'
// CHECK:STDOUT:   │ │   ├─MatchCondition ')'
// CHECK:STDOUT:   │ │ ╭─MatchStatementStart '{'
// CHECK:STDOUT:   │ │ │     ╭─MatchDefaultIntroducer 'default'
// CHECK:STDOUT:   │ │ │     │ ╭─MatchCaseGuardIntroducer 'if'
// CHECK:STDOUT:   │ │ │     │ ├─MatchCaseGuardStart '('
// CHECK:STDOUT:   │ │ │     │ ├─BoolLiteralFalse 'false'
// CHECK:STDOUT:   │ │ │     ├─MatchCaseGuard '=>' has_error
// CHECK:STDOUT:   │ │ │   ╭─MatchGuardedDefault '}' has_error
// CHECK:STDOUT:   │ │ │ ╭─MatchHandlerStart '}' has_error
// CHECK:STDOUT:   │ │ ├─MatchHandler '}' has_error
// CHECK:STDOUT:   │ ├─MatchStatement '}'
// CHECK:STDOUT:   │ │ ╭─ReturnStatementStart 'return'
// CHECK:STDOUT:   │ │ ├─IntLiteral '0'
// CHECK:STDOUT:   │ ├─ReturnStatement ';'
// CHECK:STDOUT:   ├─FunctionDefinition '}'
// CHECK:STDOUT:   ├─FileEnd ''
// CHECK:STDOUT:   (root)
