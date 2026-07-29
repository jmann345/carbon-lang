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
// CHECK:STDOUT:   parse_tree: [
// CHECK:STDOUT:     {kind: 'FileStart', text: ''},
// CHECK:STDOUT:         {kind: 'FunctionIntroducer', text: 'fn'},
// CHECK:STDOUT:         {kind: 'IdentifierNameMaybeBeforeSignature', text: 'F'},
// CHECK:STDOUT:           {kind: 'ExplicitParamListStart', text: '('},
// CHECK:STDOUT:             {kind: 'IdentifierNameNotBeforeSignature', text: 'x'},
// CHECK:STDOUT:             {kind: 'BindingPatternTypeStart', text: ':'},
// CHECK:STDOUT:             {kind: 'IntTypeLiteral', text: 'i32'},
// CHECK:STDOUT:           {kind: 'LetBindingPattern', text: ':', subtree_size: 4},
// CHECK:STDOUT:         {kind: 'ExplicitParamList', text: ')', subtree_size: 6},
// CHECK:STDOUT:           {kind: 'IntTypeLiteral', text: 'i32'},
// CHECK:STDOUT:         {kind: 'ReturnType', text: '->', subtree_size: 2},
// CHECK:STDOUT:       {kind: 'FunctionDefinitionStart', text: '{', subtree_size: 11},
// CHECK:STDOUT:           {kind: 'MatchIntroducer', text: 'match'},
// CHECK:STDOUT:             {kind: 'MatchConditionStart', text: '('},
// CHECK:STDOUT:             {kind: 'IdentifierNameExpr', text: 'x'},
// CHECK:STDOUT:           {kind: 'MatchCondition', text: ')', subtree_size: 3},
// CHECK:STDOUT:         {kind: 'MatchStatementStart', text: '{', subtree_size: 5},
// CHECK:STDOUT:               {kind: 'MatchCaseIntroducer', text: 'case'},
// CHECK:STDOUT:                 {kind: 'AlternativePatternStart', text: '.'},
// CHECK:STDOUT:                 {kind: 'IdentifierNameNotBeforeSignature', text: 'Ok'},
// CHECK:STDOUT:                   {kind: 'TuplePatternStart', text: '('},
// CHECK:STDOUT:                     {kind: 'IdentifierNameNotBeforeSignature', text: 'value'},
// CHECK:STDOUT:                     {kind: 'BindingPatternTypeStart', text: ':'},
// CHECK:STDOUT:                     {kind: 'IntTypeLiteral', text: 'i32'},
// CHECK:STDOUT:                   {kind: 'LetBindingPattern', text: ':', subtree_size: 4},
// CHECK:STDOUT:                 {kind: 'ParenPattern', text: ')', has_error: yes, subtree_size: 6},
// CHECK:STDOUT:               {kind: 'AlternativePattern', text: '.', subtree_size: 9},
// CHECK:STDOUT:             {kind: 'MatchCase', text: '}', has_error: yes, subtree_size: 11},
// CHECK:STDOUT:           {kind: 'MatchHandlerStart', text: '}', has_error: yes, subtree_size: 12},
// CHECK:STDOUT:         {kind: 'MatchHandler', text: '}', has_error: yes, subtree_size: 13},
// CHECK:STDOUT:       {kind: 'MatchStatement', text: '}', subtree_size: 19},
// CHECK:STDOUT:         {kind: 'ReturnStatementStart', text: 'return'},
// CHECK:STDOUT:           {kind: 'IntLiteral', text: '1'},
// CHECK:STDOUT:         {kind: 'PrefixOperatorMinus', text: '-', subtree_size: 2},
// CHECK:STDOUT:       {kind: 'ReturnStatement', text: ';', subtree_size: 4},
// CHECK:STDOUT:     {kind: 'FunctionDefinition', text: '}', subtree_size: 35},
// CHECK:STDOUT:     {kind: 'FileEnd', text: ''},
// CHECK:STDOUT:   ]
