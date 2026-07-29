// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/parse/testdata/match/alternative_pattern.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/parse/testdata/match/alternative_pattern.carbon

// Choice alternative patterns at the root of a `case`: bare `.Name`, a
// single-subpattern payload list, a multi-subpattern payload list (with and
// without a trailing comma), and empty parentheses for a zero-payload
// function-like alternative. A leading-dot pattern is only an alternative
// pattern at the case root; `.Err` inside parentheses stays an ordinary
// (expression) pattern.
fn F(x: i32) -> i32 {
  match (x) {
    case .Err => { return 0; }
    case .Ok(value: i32) => { return 1; }
    case .Pair(a: i32, b: i32) => { return 2; }
    case .Single(a: i32,) => { return 3; }
    case .On() => { return 4; }
    case (.Err) => { return 5; }
    default => { return 6; }
  }
  return -1;
}

// CHECK:STDOUT: - filename: alternative_pattern.carbon
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
// CHECK:STDOUT:                 {kind: 'IdentifierNameNotBeforeSignature', text: 'Err'},
// CHECK:STDOUT:               {kind: 'AlternativePattern', text: '.', subtree_size: 3},
// CHECK:STDOUT:             {kind: 'MatchCase', text: '=>', subtree_size: 5},
// CHECK:STDOUT:           {kind: 'MatchHandlerStart', text: '{', subtree_size: 6},
// CHECK:STDOUT:             {kind: 'ReturnStatementStart', text: 'return'},
// CHECK:STDOUT:             {kind: 'IntLiteral', text: '0'},
// CHECK:STDOUT:           {kind: 'ReturnStatement', text: ';', subtree_size: 3},
// CHECK:STDOUT:         {kind: 'MatchHandler', text: '}', subtree_size: 10},
// CHECK:STDOUT:               {kind: 'MatchCaseIntroducer', text: 'case'},
// CHECK:STDOUT:                 {kind: 'AlternativePatternStart', text: '.'},
// CHECK:STDOUT:                 {kind: 'IdentifierNameNotBeforeSignature', text: 'Ok'},
// CHECK:STDOUT:                   {kind: 'TuplePatternStart', text: '('},
// CHECK:STDOUT:                     {kind: 'IdentifierNameNotBeforeSignature', text: 'value'},
// CHECK:STDOUT:                     {kind: 'BindingPatternTypeStart', text: ':'},
// CHECK:STDOUT:                     {kind: 'IntTypeLiteral', text: 'i32'},
// CHECK:STDOUT:                   {kind: 'LetBindingPattern', text: ':', subtree_size: 4},
// CHECK:STDOUT:                 {kind: 'ParenPattern', text: ')', subtree_size: 6},
// CHECK:STDOUT:               {kind: 'AlternativePattern', text: '.', subtree_size: 9},
// CHECK:STDOUT:             {kind: 'MatchCase', text: '=>', subtree_size: 11},
// CHECK:STDOUT:           {kind: 'MatchHandlerStart', text: '{', subtree_size: 12},
// CHECK:STDOUT:             {kind: 'ReturnStatementStart', text: 'return'},
// CHECK:STDOUT:             {kind: 'IntLiteral', text: '1'},
// CHECK:STDOUT:           {kind: 'ReturnStatement', text: ';', subtree_size: 3},
// CHECK:STDOUT:         {kind: 'MatchHandler', text: '}', subtree_size: 16},
// CHECK:STDOUT:               {kind: 'MatchCaseIntroducer', text: 'case'},
// CHECK:STDOUT:                 {kind: 'AlternativePatternStart', text: '.'},
// CHECK:STDOUT:                 {kind: 'IdentifierNameNotBeforeSignature', text: 'Pair'},
// CHECK:STDOUT:                   {kind: 'TuplePatternStart', text: '('},
// CHECK:STDOUT:                     {kind: 'IdentifierNameNotBeforeSignature', text: 'a'},
// CHECK:STDOUT:                     {kind: 'BindingPatternTypeStart', text: ':'},
// CHECK:STDOUT:                     {kind: 'IntTypeLiteral', text: 'i32'},
// CHECK:STDOUT:                   {kind: 'LetBindingPattern', text: ':', subtree_size: 4},
// CHECK:STDOUT:                   {kind: 'PatternListComma', text: ','},
// CHECK:STDOUT:                     {kind: 'IdentifierNameNotBeforeSignature', text: 'b'},
// CHECK:STDOUT:                     {kind: 'BindingPatternTypeStart', text: ':'},
// CHECK:STDOUT:                     {kind: 'IntTypeLiteral', text: 'i32'},
// CHECK:STDOUT:                   {kind: 'LetBindingPattern', text: ':', subtree_size: 4},
// CHECK:STDOUT:                 {kind: 'TuplePattern', text: ')', subtree_size: 11},
// CHECK:STDOUT:               {kind: 'AlternativePattern', text: '.', subtree_size: 14},
// CHECK:STDOUT:             {kind: 'MatchCase', text: '=>', subtree_size: 16},
// CHECK:STDOUT:           {kind: 'MatchHandlerStart', text: '{', subtree_size: 17},
// CHECK:STDOUT:             {kind: 'ReturnStatementStart', text: 'return'},
// CHECK:STDOUT:             {kind: 'IntLiteral', text: '2'},
// CHECK:STDOUT:           {kind: 'ReturnStatement', text: ';', subtree_size: 3},
// CHECK:STDOUT:         {kind: 'MatchHandler', text: '}', subtree_size: 21},
// CHECK:STDOUT:               {kind: 'MatchCaseIntroducer', text: 'case'},
// CHECK:STDOUT:                 {kind: 'AlternativePatternStart', text: '.'},
// CHECK:STDOUT:                 {kind: 'IdentifierNameNotBeforeSignature', text: 'Single'},
// CHECK:STDOUT:                   {kind: 'TuplePatternStart', text: '('},
// CHECK:STDOUT:                     {kind: 'IdentifierNameNotBeforeSignature', text: 'a'},
// CHECK:STDOUT:                     {kind: 'BindingPatternTypeStart', text: ':'},
// CHECK:STDOUT:                     {kind: 'IntTypeLiteral', text: 'i32'},
// CHECK:STDOUT:                   {kind: 'LetBindingPattern', text: ':', subtree_size: 4},
// CHECK:STDOUT:                   {kind: 'PatternListComma', text: ','},
// CHECK:STDOUT:                 {kind: 'TuplePattern', text: ')', subtree_size: 7},
// CHECK:STDOUT:               {kind: 'AlternativePattern', text: '.', subtree_size: 10},
// CHECK:STDOUT:             {kind: 'MatchCase', text: '=>', subtree_size: 12},
// CHECK:STDOUT:           {kind: 'MatchHandlerStart', text: '{', subtree_size: 13},
// CHECK:STDOUT:             {kind: 'ReturnStatementStart', text: 'return'},
// CHECK:STDOUT:             {kind: 'IntLiteral', text: '3'},
// CHECK:STDOUT:           {kind: 'ReturnStatement', text: ';', subtree_size: 3},
// CHECK:STDOUT:         {kind: 'MatchHandler', text: '}', subtree_size: 17},
// CHECK:STDOUT:               {kind: 'MatchCaseIntroducer', text: 'case'},
// CHECK:STDOUT:                 {kind: 'AlternativePatternStart', text: '.'},
// CHECK:STDOUT:                 {kind: 'IdentifierNameNotBeforeSignature', text: 'On'},
// CHECK:STDOUT:                   {kind: 'TuplePatternStart', text: '('},
// CHECK:STDOUT:                 {kind: 'TuplePattern', text: ')', subtree_size: 2},
// CHECK:STDOUT:               {kind: 'AlternativePattern', text: '.', subtree_size: 5},
// CHECK:STDOUT:             {kind: 'MatchCase', text: '=>', subtree_size: 7},
// CHECK:STDOUT:           {kind: 'MatchHandlerStart', text: '{', subtree_size: 8},
// CHECK:STDOUT:             {kind: 'ReturnStatementStart', text: 'return'},
// CHECK:STDOUT:             {kind: 'IntLiteral', text: '4'},
// CHECK:STDOUT:           {kind: 'ReturnStatement', text: ';', subtree_size: 3},
// CHECK:STDOUT:         {kind: 'MatchHandler', text: '}', subtree_size: 12},
// CHECK:STDOUT:               {kind: 'MatchCaseIntroducer', text: 'case'},
// CHECK:STDOUT:                 {kind: 'TuplePatternStart', text: '('},
// CHECK:STDOUT:                   {kind: 'IdentifierNameNotBeforeSignature', text: 'Err'},
// CHECK:STDOUT:                 {kind: 'DesignatorExpr', text: '.', subtree_size: 2},
// CHECK:STDOUT:               {kind: 'ParenPattern', text: ')', subtree_size: 4},
// CHECK:STDOUT:             {kind: 'MatchCase', text: '=>', subtree_size: 6},
// CHECK:STDOUT:           {kind: 'MatchHandlerStart', text: '{', subtree_size: 7},
// CHECK:STDOUT:             {kind: 'ReturnStatementStart', text: 'return'},
// CHECK:STDOUT:             {kind: 'IntLiteral', text: '5'},
// CHECK:STDOUT:           {kind: 'ReturnStatement', text: ';', subtree_size: 3},
// CHECK:STDOUT:         {kind: 'MatchHandler', text: '}', subtree_size: 11},
// CHECK:STDOUT:               {kind: 'MatchDefaultIntroducer', text: 'default'},
// CHECK:STDOUT:             {kind: 'MatchDefault', text: '=>', subtree_size: 2},
// CHECK:STDOUT:           {kind: 'MatchHandlerStart', text: '{', subtree_size: 3},
// CHECK:STDOUT:             {kind: 'ReturnStatementStart', text: 'return'},
// CHECK:STDOUT:             {kind: 'IntLiteral', text: '6'},
// CHECK:STDOUT:           {kind: 'ReturnStatement', text: ';', subtree_size: 3},
// CHECK:STDOUT:         {kind: 'MatchHandler', text: '}', subtree_size: 7},
// CHECK:STDOUT:       {kind: 'MatchStatement', text: '}', subtree_size: 100},
// CHECK:STDOUT:         {kind: 'ReturnStatementStart', text: 'return'},
// CHECK:STDOUT:           {kind: 'IntLiteral', text: '1'},
// CHECK:STDOUT:         {kind: 'PrefixOperatorMinus', text: '-', subtree_size: 2},
// CHECK:STDOUT:       {kind: 'ReturnStatement', text: ';', subtree_size: 4},
// CHECK:STDOUT:     {kind: 'FunctionDefinition', text: '}', subtree_size: 116},
// CHECK:STDOUT:     {kind: 'FileEnd', text: ''},
// CHECK:STDOUT:   ]
