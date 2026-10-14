// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/parse/testdata/variadics/each.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/parse/testdata/variadics/each.carbon

// --- binding.carbon

fn F(... each x: i32);

// --- binding_modifiers.carbon

fn F[... template each T: type](... ref each x: i32, ... var each y: i32);

// --- expr.carbon

fn F() {
  ... G(each x, each x.y, each x.f(), -each x);
}

// --- fail_each_without_name.carbon

fn F() {
  // CHECK:STDERR: fail_each_without_name.carbon:[[@LINE+4]]:9: error: expected identifier after `each` [ExpectedIdentifierAfterEach]
  // CHECK:STDERR:   G(each);
  // CHECK:STDERR:         ^
  // CHECK:STDERR:
  G(each);
}

// --- fail_each_binding_without_name.carbon

// CHECK:STDERR: fail_each_binding_without_name.carbon:[[@LINE+4]]:10: error: expected identifier after `each` [ExpectedIdentifierAfterEachInBinding]
// CHECK:STDERR: fn F(... each _: i32);
// CHECK:STDERR:          ^~~~
// CHECK:STDERR:
fn F(... each _: i32);

// CHECK:STDOUT: - filename: binding.carbon
// CHECK:STDOUT:   ╭─FileStart ''
// CHECK:STDOUT:   │ ╭─FunctionIntroducer 'fn'
// CHECK:STDOUT:   │ ├─IdentifierNameMaybeBeforeSignature 'F'
// CHECK:STDOUT:   │ │ ╭─ExplicitParamListStart '('
// CHECK:STDOUT:   │ │ │ ╭─PackExpansionStart '...'
// CHECK:STDOUT:   │ │ │ │   ╭─IdentifierNameNotBeforeSignature 'x'
// CHECK:STDOUT:   │ │ │ │ ╭─EachBindingName 'each'
// CHECK:STDOUT:   │ │ │ │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │ │ │ │ ├─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │ │ │ ├─LetBindingPattern ':'
// CHECK:STDOUT:   │ │ ├─PackExpansionPattern '...'
// CHECK:STDOUT:   │ ├─ExplicitParamList ')'
// CHECK:STDOUT:   ├─FunctionDecl ';'
// CHECK:STDOUT:   ├─FileEnd ''
// CHECK:STDOUT:   (root)
// CHECK:STDOUT: - filename: binding_modifiers.carbon
// CHECK:STDOUT:   ╭─FileStart ''
// CHECK:STDOUT:   │ ╭─FunctionIntroducer 'fn'
// CHECK:STDOUT:   │ ├─IdentifierNameMaybeBeforeSignature 'F'
// CHECK:STDOUT:   │ │ ╭─ImplicitParamListStart '['
// CHECK:STDOUT:   │ │ │ ╭─PackExpansionStart '...'
// CHECK:STDOUT:   │ │ │ │     ╭─IdentifierNameNotBeforeSignature 'T'
// CHECK:STDOUT:   │ │ │ │   ╭─EachBindingName 'each'
// CHECK:STDOUT:   │ │ │ │ ╭─TemplateBindingName 'template'
// CHECK:STDOUT:   │ │ │ │ ├─CompileTimeBindingPatternTypeStart ':'
// CHECK:STDOUT:   │ │ │ │ ├─TypeTypeLiteral 'type'
// CHECK:STDOUT:   │ │ │ ├─CompileTimeBindingPattern ':'
// CHECK:STDOUT:   │ │ ├─PackExpansionPattern '...'
// CHECK:STDOUT:   │ ├─ImplicitParamList ']'
// CHECK:STDOUT:   │ │ ╭─ExplicitParamListStart '('
// CHECK:STDOUT:   │ │ │ ╭─PackExpansionStart '...'
// CHECK:STDOUT:   │ │ │ │     ╭─IdentifierNameNotBeforeSignature 'x'
// CHECK:STDOUT:   │ │ │ │   ╭─EachBindingName 'each'
// CHECK:STDOUT:   │ │ │ │ ╭─RefBindingName 'ref'
// CHECK:STDOUT:   │ │ │ │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │ │ │ │ ├─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │ │ │ ├─LetBindingPattern ':'
// CHECK:STDOUT:   │ │ ├─PackExpansionPattern '...'
// CHECK:STDOUT:   │ │ ├─PatternListComma ','
// CHECK:STDOUT:   │ │ │ ╭─PackExpansionStart '...'
// CHECK:STDOUT:   │ │ │ │     ╭─IdentifierNameNotBeforeSignature 'y'
// CHECK:STDOUT:   │ │ │ │   ╭─EachBindingName 'each'
// CHECK:STDOUT:   │ │ │ │   ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │ │ │ │   ├─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │ │ │ │ ╭─VarBindingPattern ':'
// CHECK:STDOUT:   │ │ │ ├─VariablePattern 'var'
// CHECK:STDOUT:   │ │ ├─PackExpansionPattern '...'
// CHECK:STDOUT:   │ ├─ExplicitParamList ')'
// CHECK:STDOUT:   ├─FunctionDecl ';'
// CHECK:STDOUT:   ├─FileEnd ''
// CHECK:STDOUT:   (root)
// CHECK:STDOUT: - filename: expr.carbon
// CHECK:STDOUT:   ╭─FileStart ''
// CHECK:STDOUT:   │   ╭─FunctionIntroducer 'fn'
// CHECK:STDOUT:   │   ├─IdentifierNameMaybeBeforeSignature 'F'
// CHECK:STDOUT:   │   │ ╭─ExplicitParamListStart '('
// CHECK:STDOUT:   │   ├─ExplicitParamList ')'
// CHECK:STDOUT:   │ ╭─FunctionDefinitionStart '{'
// CHECK:STDOUT:   │ │ ╭─PackExpansionStart '...'
// CHECK:STDOUT:   │ │ │     ╭─IdentifierNameExpr 'G'
// CHECK:STDOUT:   │ │ │   ╭─CallExprStart '('
// CHECK:STDOUT:   │ │ │   │ ╭─IdentifierNameNotBeforeSignature 'x'
// CHECK:STDOUT:   │ │ │   ├─EachNameExpr 'each'
// CHECK:STDOUT:   │ │ │   ├─TupleLiteralComma ','
// CHECK:STDOUT:   │ │ │   │   ╭─IdentifierNameNotBeforeSignature 'x'
// CHECK:STDOUT:   │ │ │   │ ╭─EachNameExpr 'each'
// CHECK:STDOUT:   │ │ │   │ ├─IdentifierNameNotBeforeSignature 'y'
// CHECK:STDOUT:   │ │ │   ├─MemberAccessExpr '.'
// CHECK:STDOUT:   │ │ │   ├─TupleLiteralComma ','
// CHECK:STDOUT:   │ │ │   │       ╭─IdentifierNameNotBeforeSignature 'x'
// CHECK:STDOUT:   │ │ │   │     ╭─EachNameExpr 'each'
// CHECK:STDOUT:   │ │ │   │     ├─IdentifierNameNotBeforeSignature 'f'
// CHECK:STDOUT:   │ │ │   │   ╭─MemberAccessExpr '.'
// CHECK:STDOUT:   │ │ │   │ ╭─CallExprStart '('
// CHECK:STDOUT:   │ │ │   ├─CallExpr ')'
// CHECK:STDOUT:   │ │ │   ├─TupleLiteralComma ','
// CHECK:STDOUT:   │ │ │   │   ╭─IdentifierNameNotBeforeSignature 'x'
// CHECK:STDOUT:   │ │ │   │ ╭─EachNameExpr 'each'
// CHECK:STDOUT:   │ │ │   ├─PrefixOperatorMinus '-'
// CHECK:STDOUT:   │ │ │ ╭─CallExpr ')'
// CHECK:STDOUT:   │ │ ├─ExprStatement ';'
// CHECK:STDOUT:   │ ├─PackExpansionStatement '...'
// CHECK:STDOUT:   ├─FunctionDefinition '}'
// CHECK:STDOUT:   ├─FileEnd ''
// CHECK:STDOUT:   (root)
// CHECK:STDOUT: - filename: fail_each_without_name.carbon
// CHECK:STDOUT:   ╭─FileStart ''
// CHECK:STDOUT:   │   ╭─FunctionIntroducer 'fn'
// CHECK:STDOUT:   │   ├─IdentifierNameMaybeBeforeSignature 'F'
// CHECK:STDOUT:   │   │ ╭─ExplicitParamListStart '('
// CHECK:STDOUT:   │   ├─ExplicitParamList ')'
// CHECK:STDOUT:   │ ╭─FunctionDefinitionStart '{'
// CHECK:STDOUT:   │ │     ╭─IdentifierNameExpr 'G'
// CHECK:STDOUT:   │ │   ╭─CallExprStart '('
// CHECK:STDOUT:   │ │   │ ╭─InvalidParse ')' has_error
// CHECK:STDOUT:   │ │   ├─EachNameExpr 'each' has_error
// CHECK:STDOUT:   │ │ ╭─CallExpr ')' has_error
// CHECK:STDOUT:   │ ├─ExprStatement ';'
// CHECK:STDOUT:   ├─FunctionDefinition '}'
// CHECK:STDOUT:   ├─FileEnd ''
// CHECK:STDOUT:   (root)
// CHECK:STDOUT: - filename: fail_each_binding_without_name.carbon
// CHECK:STDOUT:   ╭─FileStart ''
// CHECK:STDOUT:   │ ╭─FunctionIntroducer 'fn'
// CHECK:STDOUT:   │ ├─IdentifierNameMaybeBeforeSignature 'F'
// CHECK:STDOUT:   │ │ ╭─ExplicitParamListStart '('
// CHECK:STDOUT:   │ │ │ ╭─PackExpansionStart '...'
// CHECK:STDOUT:   │ │ │ │   ╭─UnderscoreName '_'
// CHECK:STDOUT:   │ │ │ │ ╭─EachBindingName 'each' has_error
// CHECK:STDOUT:   │ │ │ │ ├─BindingPatternTypeStart ':' has_error
// CHECK:STDOUT:   │ │ │ │ ├─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │ │ │ ├─LetBindingPattern ':' has_error
// CHECK:STDOUT:   │ │ ├─PackExpansionPattern '...' has_error
// CHECK:STDOUT:   │ ├─ExplicitParamList ')' has_error
// CHECK:STDOUT:   ├─FunctionDecl ';'
// CHECK:STDOUT:   ├─FileEnd ''
// CHECK:STDOUT:   (root)
