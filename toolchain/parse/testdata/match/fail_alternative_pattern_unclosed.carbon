// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/parse/testdata/match/fail_alternative_pattern_unclosed.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/parse/testdata/match/fail_alternative_pattern_unclosed.carbon

// Error recovery inside an alternative pattern's payload list rides the
// shared pattern-list machinery; the alternative pattern wrapper node still
// closes with an error.
fn F(x: i32) -> i32 {
  match (x) {
    // CHECK:STDERR: fail_alternative_pattern_unclosed.carbon:[[@LINE+8]]:13: error: opening symbol without a corresponding closing symbol [UnmatchedOpening]
    // CHECK:STDERR:     case .Ok(value: i32 => { return 1; }
    // CHECK:STDERR:             ^
    // CHECK:STDERR:
    // CHECK:STDERR: fail_alternative_pattern_unclosed.carbon:[[@LINE+4]]:25: error: expected `,` or `)` [UnexpectedTokenAfterListElement]
    // CHECK:STDERR:     case .Ok(value: i32 => { return 1; }
    // CHECK:STDERR:                         ^~
    // CHECK:STDERR:
    case .Ok(value: i32 => { return 1; }
    default => { return 0; }
  // CHECK:STDERR: fail_alternative_pattern_unclosed.carbon:[[@LINE+4]]:3: error: expected `=>` introducing statement block [ExpectedMatchCaseArrow]
  // CHECK:STDERR:   }
  // CHECK:STDERR:   ^
  // CHECK:STDERR:
  }
  return -1;
}

// CHECK:STDOUT: - filename: fail_alternative_pattern_unclosed.carbon
// CHECK:STDOUT:   ╭─FileStart ''
// CHECK:STDOUT:   │   ╭─FunctionIntroducer 'fn'
// CHECK:STDOUT:   │   ├─IdentifierNameMaybeBeforeSignature 'F'
// CHECK:STDOUT:   │   │ ╭─ExplicitParamListStart '('
// CHECK:STDOUT:   │   │ │ ╭─IdentifierNameNotBeforeSignature 'x'
// CHECK:STDOUT:   │   │ │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │   │ │ ├─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │   │ ├─LetBindingPattern ':'
// CHECK:STDOUT:   │   ├─ExplicitParamList ')'
// CHECK:STDOUT:   │   │ ╭─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │   ├─ReturnType '->'
// CHECK:STDOUT:   │ ╭─FunctionDefinitionStart '{'
// CHECK:STDOUT:   │ │   ╭─MatchIntroducer 'match'
// CHECK:STDOUT:   │ │   │ ╭─MatchConditionStart '('
// CHECK:STDOUT:   │ │   │ ├─IdentifierNameExpr 'x'
// CHECK:STDOUT:   │ │   ├─MatchCondition ')'
// CHECK:STDOUT:   │ │ ╭─MatchStatementStart '{'
// CHECK:STDOUT:   │ │ │     ╭─MatchCaseIntroducer 'case'
// CHECK:STDOUT:   │ │ │     │ ╭─AlternativePatternStart '.'
// CHECK:STDOUT:   │ │ │     │ ├─IdentifierNameNotBeforeSignature 'Ok'
// CHECK:STDOUT:   │ │ │     │ │ ╭─TuplePatternStart '('
// CHECK:STDOUT:   │ │ │     │ │ │ ╭─IdentifierNameNotBeforeSignature 'value'
// CHECK:STDOUT:   │ │ │     │ │ │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │ │ │     │ │ │ ├─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │ │ │     │ │ ├─LetBindingPattern ':'
// CHECK:STDOUT:   │ │ │     │ ├─ParenPattern ')' has_error
// CHECK:STDOUT:   │ │ │     ├─AlternativePattern '.'
// CHECK:STDOUT:   │ │ │   ╭─MatchCase '}' has_error
// CHECK:STDOUT:   │ │ │ ╭─MatchHandlerStart '}' has_error
// CHECK:STDOUT:   │ │ ├─MatchHandler '}' has_error
// CHECK:STDOUT:   │ ├─MatchStatement '}'
// CHECK:STDOUT:   │ │ ╭─ReturnStatementStart 'return'
// CHECK:STDOUT:   │ │ │ ╭─IntLiteral '1'
// CHECK:STDOUT:   │ │ ├─PrefixOperatorMinus '-'
// CHECK:STDOUT:   │ ├─ReturnStatement ';'
// CHECK:STDOUT:   ├─FunctionDefinition '}'
// CHECK:STDOUT:   ├─FileEnd ''
// CHECK:STDOUT:   (root)
