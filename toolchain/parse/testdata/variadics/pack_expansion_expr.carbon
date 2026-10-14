// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/parse/testdata/variadics/pack_expansion_expr.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/parse/testdata/variadics/pack_expansion_expr.carbon

// --- call_args.carbon

fn F() {
  G(... each x);
  G(1, ... each x, 2);
}

// --- tuple_literal.carbon

fn F() {
  let t: auto = (... each x);
  let u: auto = (1, ... each x);
  let v: auto = (... each x, ... each y,);
}

// --- expand.carbon

fn F() {
  G(...expand t);
}

// --- fail_missing_operand.carbon

fn F() {
  // CHECK:STDERR: fail_missing_operand.carbon:[[@LINE+4]]:8: error: expected expression [ExpectedExpr]
  // CHECK:STDERR:   G(...);
  // CHECK:STDERR:        ^
  // CHECK:STDERR:
  G(...);
}

// --- fail_todo_and_or.carbon

fn F() {
  // CHECK:STDERR: fail_todo_and_or.carbon:[[@LINE+8]]:17: error: expected expression [ExpectedExpr]
  // CHECK:STDERR:   let b: bool = ...and G(each x);
  // CHECK:STDERR:                 ^~~
  // CHECK:STDERR:
  // CHECK:STDERR: fail_todo_and_or.carbon:[[@LINE+4]]:17: error: `let` declarations must end with a `;` [ExpectedDeclSemi]
  // CHECK:STDERR:   let b: bool = ...and G(each x);
  // CHECK:STDERR:                 ^~~
  // CHECK:STDERR:
  let b: bool = ...and G(each x);
  // CHECK:STDERR: fail_todo_and_or.carbon:[[@LINE+8]]:17: error: expected expression [ExpectedExpr]
  // CHECK:STDERR:   let c: bool = ...or G(each x);
  // CHECK:STDERR:                 ^~~
  // CHECK:STDERR:
  // CHECK:STDERR: fail_todo_and_or.carbon:[[@LINE+4]]:17: error: `let` declarations must end with a `;` [ExpectedDeclSemi]
  // CHECK:STDERR:   let c: bool = ...or G(each x);
  // CHECK:STDERR:                 ^~~
  // CHECK:STDERR:
  let c: bool = ...or G(each x);
}

// CHECK:STDOUT: - filename: call_args.carbon
// CHECK:STDOUT:   ╭─FileStart ''
// CHECK:STDOUT:   │   ╭─FunctionIntroducer 'fn'
// CHECK:STDOUT:   │   ├─IdentifierNameMaybeBeforeSignature 'F'
// CHECK:STDOUT:   │   │ ╭─ExplicitParamListStart '('
// CHECK:STDOUT:   │   ├─ExplicitParamList ')'
// CHECK:STDOUT:   │ ╭─FunctionDefinitionStart '{'
// CHECK:STDOUT:   │ │     ╭─IdentifierNameExpr 'G'
// CHECK:STDOUT:   │ │   ╭─CallExprStart '('
// CHECK:STDOUT:   │ │   │ ╭─PackExpansionStart '...'
// CHECK:STDOUT:   │ │   │ │ ╭─IdentifierNameNotBeforeSignature 'x'
// CHECK:STDOUT:   │ │   │ ├─EachNameExpr 'each'
// CHECK:STDOUT:   │ │   ├─PackExpansionExpr '...'
// CHECK:STDOUT:   │ │ ╭─CallExpr ')'
// CHECK:STDOUT:   │ ├─ExprStatement ';'
// CHECK:STDOUT:   │ │     ╭─IdentifierNameExpr 'G'
// CHECK:STDOUT:   │ │   ╭─CallExprStart '('
// CHECK:STDOUT:   │ │   ├─IntLiteral '1'
// CHECK:STDOUT:   │ │   ├─TupleLiteralComma ','
// CHECK:STDOUT:   │ │   │ ╭─PackExpansionStart '...'
// CHECK:STDOUT:   │ │   │ │ ╭─IdentifierNameNotBeforeSignature 'x'
// CHECK:STDOUT:   │ │   │ ├─EachNameExpr 'each'
// CHECK:STDOUT:   │ │   ├─PackExpansionExpr '...'
// CHECK:STDOUT:   │ │   ├─TupleLiteralComma ','
// CHECK:STDOUT:   │ │   ├─IntLiteral '2'
// CHECK:STDOUT:   │ │ ╭─CallExpr ')'
// CHECK:STDOUT:   │ ├─ExprStatement ';'
// CHECK:STDOUT:   ├─FunctionDefinition '}'
// CHECK:STDOUT:   ├─FileEnd ''
// CHECK:STDOUT:   (root)
// CHECK:STDOUT: - filename: tuple_literal.carbon
// CHECK:STDOUT:   ╭─FileStart ''
// CHECK:STDOUT:   │   ╭─FunctionIntroducer 'fn'
// CHECK:STDOUT:   │   ├─IdentifierNameMaybeBeforeSignature 'F'
// CHECK:STDOUT:   │   │ ╭─ExplicitParamListStart '('
// CHECK:STDOUT:   │   ├─ExplicitParamList ')'
// CHECK:STDOUT:   │ ╭─FunctionDefinitionStart '{'
// CHECK:STDOUT:   │ │ ╭─LetIntroducer 'let'
// CHECK:STDOUT:   │ │ │ ╭─IdentifierNameNotBeforeSignature 't'
// CHECK:STDOUT:   │ │ │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │ │ │ ├─AutoTypeLiteral 'auto'
// CHECK:STDOUT:   │ │ ├─LetBindingPattern ':'
// CHECK:STDOUT:   │ │ ├─LetInitializer '='
// CHECK:STDOUT:   │ │ │ ╭─TupleLiteralStart '('
// CHECK:STDOUT:   │ │ │ │ ╭─PackExpansionStart '...'
// CHECK:STDOUT:   │ │ │ │ │ ╭─IdentifierNameNotBeforeSignature 'x'
// CHECK:STDOUT:   │ │ │ │ ├─EachNameExpr 'each'
// CHECK:STDOUT:   │ │ │ ├─PackExpansionExpr '...'
// CHECK:STDOUT:   │ │ ├─TupleLiteral ')'
// CHECK:STDOUT:   │ ├─LetDecl ';'
// CHECK:STDOUT:   │ │ ╭─LetIntroducer 'let'
// CHECK:STDOUT:   │ │ │ ╭─IdentifierNameNotBeforeSignature 'u'
// CHECK:STDOUT:   │ │ │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │ │ │ ├─AutoTypeLiteral 'auto'
// CHECK:STDOUT:   │ │ ├─LetBindingPattern ':'
// CHECK:STDOUT:   │ │ ├─LetInitializer '='
// CHECK:STDOUT:   │ │ │ ╭─TupleLiteralStart '('
// CHECK:STDOUT:   │ │ │ ├─IntLiteral '1'
// CHECK:STDOUT:   │ │ │ ├─TupleLiteralComma ','
// CHECK:STDOUT:   │ │ │ │ ╭─PackExpansionStart '...'
// CHECK:STDOUT:   │ │ │ │ │ ╭─IdentifierNameNotBeforeSignature 'x'
// CHECK:STDOUT:   │ │ │ │ ├─EachNameExpr 'each'
// CHECK:STDOUT:   │ │ │ ├─PackExpansionExpr '...'
// CHECK:STDOUT:   │ │ ├─TupleLiteral ')'
// CHECK:STDOUT:   │ ├─LetDecl ';'
// CHECK:STDOUT:   │ │ ╭─LetIntroducer 'let'
// CHECK:STDOUT:   │ │ │ ╭─IdentifierNameNotBeforeSignature 'v'
// CHECK:STDOUT:   │ │ │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │ │ │ ├─AutoTypeLiteral 'auto'
// CHECK:STDOUT:   │ │ ├─LetBindingPattern ':'
// CHECK:STDOUT:   │ │ ├─LetInitializer '='
// CHECK:STDOUT:   │ │ │ ╭─TupleLiteralStart '('
// CHECK:STDOUT:   │ │ │ │ ╭─PackExpansionStart '...'
// CHECK:STDOUT:   │ │ │ │ │ ╭─IdentifierNameNotBeforeSignature 'x'
// CHECK:STDOUT:   │ │ │ │ ├─EachNameExpr 'each'
// CHECK:STDOUT:   │ │ │ ├─PackExpansionExpr '...'
// CHECK:STDOUT:   │ │ │ ├─TupleLiteralComma ','
// CHECK:STDOUT:   │ │ │ │ ╭─PackExpansionStart '...'
// CHECK:STDOUT:   │ │ │ │ │ ╭─IdentifierNameNotBeforeSignature 'y'
// CHECK:STDOUT:   │ │ │ │ ├─EachNameExpr 'each'
// CHECK:STDOUT:   │ │ │ ├─PackExpansionExpr '...'
// CHECK:STDOUT:   │ │ │ ├─TupleLiteralComma ','
// CHECK:STDOUT:   │ │ ├─TupleLiteral ')'
// CHECK:STDOUT:   │ ├─LetDecl ';'
// CHECK:STDOUT:   ├─FunctionDefinition '}'
// CHECK:STDOUT:   ├─FileEnd ''
// CHECK:STDOUT:   (root)
// CHECK:STDOUT: - filename: expand.carbon
// CHECK:STDOUT:   ╭─FileStart ''
// CHECK:STDOUT:   │   ╭─FunctionIntroducer 'fn'
// CHECK:STDOUT:   │   ├─IdentifierNameMaybeBeforeSignature 'F'
// CHECK:STDOUT:   │   │ ╭─ExplicitParamListStart '('
// CHECK:STDOUT:   │   ├─ExplicitParamList ')'
// CHECK:STDOUT:   │ ╭─FunctionDefinitionStart '{'
// CHECK:STDOUT:   │ │     ╭─IdentifierNameExpr 'G'
// CHECK:STDOUT:   │ │   ╭─CallExprStart '('
// CHECK:STDOUT:   │ │   │ ╭─PackExpansionStart '...'
// CHECK:STDOUT:   │ │   │ │ ╭─IdentifierNameExpr 't'
// CHECK:STDOUT:   │ │   │ ├─PrefixOperatorExpand 'expand'
// CHECK:STDOUT:   │ │   ├─PackExpansionExpr '...'
// CHECK:STDOUT:   │ │ ╭─CallExpr ')'
// CHECK:STDOUT:   │ ├─ExprStatement ';'
// CHECK:STDOUT:   ├─FunctionDefinition '}'
// CHECK:STDOUT:   ├─FileEnd ''
// CHECK:STDOUT:   (root)
// CHECK:STDOUT: - filename: fail_missing_operand.carbon
// CHECK:STDOUT:   ╭─FileStart ''
// CHECK:STDOUT:   │   ╭─FunctionIntroducer 'fn'
// CHECK:STDOUT:   │   ├─IdentifierNameMaybeBeforeSignature 'F'
// CHECK:STDOUT:   │   │ ╭─ExplicitParamListStart '('
// CHECK:STDOUT:   │   ├─ExplicitParamList ')'
// CHECK:STDOUT:   │ ╭─FunctionDefinitionStart '{'
// CHECK:STDOUT:   │ │     ╭─IdentifierNameExpr 'G'
// CHECK:STDOUT:   │ │   ╭─CallExprStart '('
// CHECK:STDOUT:   │ │   │ ╭─PackExpansionStart '...'
// CHECK:STDOUT:   │ │   │ ├─InvalidParse ')' has_error
// CHECK:STDOUT:   │ │   ├─PackExpansionExpr '...' has_error
// CHECK:STDOUT:   │ │ ╭─CallExpr ')' has_error
// CHECK:STDOUT:   │ ├─ExprStatement ';'
// CHECK:STDOUT:   ├─FunctionDefinition '}'
// CHECK:STDOUT:   ├─FileEnd ''
// CHECK:STDOUT:   (root)
// CHECK:STDOUT: - filename: fail_todo_and_or.carbon
// CHECK:STDOUT:   ╭─FileStart ''
// CHECK:STDOUT:   │   ╭─FunctionIntroducer 'fn'
// CHECK:STDOUT:   │   ├─IdentifierNameMaybeBeforeSignature 'F'
// CHECK:STDOUT:   │   │ ╭─ExplicitParamListStart '('
// CHECK:STDOUT:   │   ├─ExplicitParamList ')'
// CHECK:STDOUT:   │ ╭─FunctionDefinitionStart '{'
// CHECK:STDOUT:   │ │ ╭─LetIntroducer 'let'
// CHECK:STDOUT:   │ │ │ ╭─IdentifierNameNotBeforeSignature 'b'
// CHECK:STDOUT:   │ │ │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │ │ │ ├─BoolTypeLiteral 'bool'
// CHECK:STDOUT:   │ │ ├─LetBindingPattern ':'
// CHECK:STDOUT:   │ │ ├─LetInitializer '='
// CHECK:STDOUT:   │ │ ├─InvalidParse '...' has_error
// CHECK:STDOUT:   │ ├─LetDecl ';' has_error
// CHECK:STDOUT:   │ │ ╭─LetIntroducer 'let'
// CHECK:STDOUT:   │ │ │ ╭─IdentifierNameNotBeforeSignature 'c'
// CHECK:STDOUT:   │ │ │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │ │ │ ├─BoolTypeLiteral 'bool'
// CHECK:STDOUT:   │ │ ├─LetBindingPattern ':'
// CHECK:STDOUT:   │ │ ├─LetInitializer '='
// CHECK:STDOUT:   │ │ ├─InvalidParse '...' has_error
// CHECK:STDOUT:   │ ├─LetDecl ';' has_error
// CHECK:STDOUT:   ├─FunctionDefinition '}'
// CHECK:STDOUT:   ├─FileEnd ''
// CHECK:STDOUT:   (root)
