// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/parse/testdata/match/fail_default_guard_recovery_midlist.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/parse/testdata/match/fail_default_guard_recovery_midlist.carbon

// A malformed guarded `default` in the MIDDLE of the arm list: recovery
// skips past the broken arm and the loop continues, so the arms after it
// (a guarded `case` and a trailing unguarded `default`) still parse.

fn f() -> i32 {
  match (true) {
    // CHECK:STDERR: fail_default_guard_recovery_midlist.carbon:[[@LINE+4]]:16: error: expected `(` after `if` [ExpectedMatchCaseGuardOpenParen]
    // CHECK:STDERR:     default if true => { return 1; }
    // CHECK:STDERR:                ^~~~
    // CHECK:STDERR:
    default if true => { return 1; }
    case x: bool if (x) => { return 2; }
    default => { return 3; }
  }
  return 0;
}

// CHECK:STDOUT: - filename: fail_default_guard_recovery_midlist.carbon
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
// CHECK:STDOUT:   │ │ │     │ ├─MatchCaseGuardStart 'true' has_error
// CHECK:STDOUT:   │ │ │     │ ├─InvalidParse 'true' has_error
// CHECK:STDOUT:   │ │ │     ├─MatchCaseGuard 'true' has_error
// CHECK:STDOUT:   │ │ │   ╭─MatchGuardedDefault 'true' has_error
// CHECK:STDOUT:   │ │ │ ╭─MatchHandlerStart 'true' has_error
// CHECK:STDOUT:   │ │ ├─MatchHandler 'true' has_error
// CHECK:STDOUT:   │ │ │     ╭─MatchCaseIntroducer 'case'
// CHECK:STDOUT:   │ │ │     │ ╭─IdentifierNameNotBeforeSignature 'x'
// CHECK:STDOUT:   │ │ │     │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │ │ │     │ ├─BoolTypeLiteral 'bool'
// CHECK:STDOUT:   │ │ │     ├─LetBindingPattern ':'
// CHECK:STDOUT:   │ │ │     │ ╭─MatchCaseGuardIntroducer 'if'
// CHECK:STDOUT:   │ │ │     │ ├─MatchCaseGuardStart '('
// CHECK:STDOUT:   │ │ │     │ ├─IdentifierNameExpr 'x'
// CHECK:STDOUT:   │ │ │     ├─MatchCaseGuard ')'
// CHECK:STDOUT:   │ │ │   ╭─MatchCase '=>'
// CHECK:STDOUT:   │ │ │ ╭─MatchHandlerStart '{'
// CHECK:STDOUT:   │ │ │ │ ╭─ReturnStatementStart 'return'
// CHECK:STDOUT:   │ │ │ │ ├─IntLiteral '2'
// CHECK:STDOUT:   │ │ │ ├─ReturnStatement ';'
// CHECK:STDOUT:   │ │ ├─MatchHandler '}'
// CHECK:STDOUT:   │ │ │     ╭─MatchDefaultIntroducer 'default'
// CHECK:STDOUT:   │ │ │   ╭─MatchDefault '=>'
// CHECK:STDOUT:   │ │ │ ╭─MatchHandlerStart '{'
// CHECK:STDOUT:   │ │ │ │ ╭─ReturnStatementStart 'return'
// CHECK:STDOUT:   │ │ │ │ ├─IntLiteral '3'
// CHECK:STDOUT:   │ │ │ ├─ReturnStatement ';'
// CHECK:STDOUT:   │ │ ├─MatchHandler '}'
// CHECK:STDOUT:   │ ├─MatchStatement '}'
// CHECK:STDOUT:   │ │ ╭─ReturnStatementStart 'return'
// CHECK:STDOUT:   │ │ ├─IntLiteral '0'
// CHECK:STDOUT:   │ ├─ReturnStatement ';'
// CHECK:STDOUT:   ├─FunctionDefinition '}'
// CHECK:STDOUT:   ├─FileEnd ''
// CHECK:STDOUT:   (root)
