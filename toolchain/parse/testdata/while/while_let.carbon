// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/parse/testdata/while/while_let.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/parse/testdata/while/while_let.carbon

// Pattern conditions in `while` (W-012): the same prefix as `if`, under
// `WhileCondition`.

// --- let_binding.carbon

fn F(x: i32) {
  while (let n: i32 = x) {}
}

// --- var_binding.carbon

fn F(x: i32) {
  while (var n: i32 = x) {}
}

// --- alternative_payload.carbon

fn F(opt: Opt) {
  while (let .Some(n: i32) = opt) {}
}

// CHECK:STDOUT: - filename: let_binding.carbon
// CHECK:STDOUT:   ╭─FileStart ''
// CHECK:STDOUT:   │   ╭─FunctionIntroducer 'fn'
// CHECK:STDOUT:   │   ├─IdentifierNameMaybeBeforeSignature 'F'
// CHECK:STDOUT:   │   │ ╭─ExplicitParamListStart '('
// CHECK:STDOUT:   │   │ │ ╭─IdentifierNameNotBeforeSignature 'x'
// CHECK:STDOUT:   │   │ │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │   │ │ ├─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │   │ ├─LetBindingPattern ':'
// CHECK:STDOUT:   │   ├─ExplicitParamList ')'
// CHECK:STDOUT:   │ ╭─FunctionDefinitionStart '{'
// CHECK:STDOUT:   │ │   ╭─WhileConditionStart '('
// CHECK:STDOUT:   │ │   ├─PatternConditionIntroducer 'let'
// CHECK:STDOUT:   │ │   │ ╭─IdentifierNameNotBeforeSignature 'n'
// CHECK:STDOUT:   │ │   │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │ │   │ ├─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │ │   ├─LetBindingPattern ':'
// CHECK:STDOUT:   │ │   ├─PatternConditionInitializer '='
// CHECK:STDOUT:   │ │   ├─IdentifierNameExpr 'x'
// CHECK:STDOUT:   │ │ ╭─WhileCondition ')'
// CHECK:STDOUT:   │ │ │ ╭─CodeBlockStart '{'
// CHECK:STDOUT:   │ │ ├─CodeBlock '}'
// CHECK:STDOUT:   │ ├─WhileStatement 'while'
// CHECK:STDOUT:   ├─FunctionDefinition '}'
// CHECK:STDOUT:   ├─FileEnd ''
// CHECK:STDOUT:   (root)
// CHECK:STDOUT: - filename: var_binding.carbon
// CHECK:STDOUT:   ╭─FileStart ''
// CHECK:STDOUT:   │   ╭─FunctionIntroducer 'fn'
// CHECK:STDOUT:   │   ├─IdentifierNameMaybeBeforeSignature 'F'
// CHECK:STDOUT:   │   │ ╭─ExplicitParamListStart '('
// CHECK:STDOUT:   │   │ │ ╭─IdentifierNameNotBeforeSignature 'x'
// CHECK:STDOUT:   │   │ │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │   │ │ ├─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │   │ ├─LetBindingPattern ':'
// CHECK:STDOUT:   │   ├─ExplicitParamList ')'
// CHECK:STDOUT:   │ ╭─FunctionDefinitionStart '{'
// CHECK:STDOUT:   │ │   ╭─WhileConditionStart '('
// CHECK:STDOUT:   │ │   ├─PatternConditionIntroducer 'var'
// CHECK:STDOUT:   │ │   │   ╭─IdentifierNameNotBeforeSignature 'n'
// CHECK:STDOUT:   │ │   │   ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │ │   │   ├─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │ │   │ ╭─VarBindingPattern ':'
// CHECK:STDOUT:   │ │   ├─VariablePattern 'var'
// CHECK:STDOUT:   │ │   ├─PatternConditionInitializer '='
// CHECK:STDOUT:   │ │   ├─IdentifierNameExpr 'x'
// CHECK:STDOUT:   │ │ ╭─WhileCondition ')'
// CHECK:STDOUT:   │ │ │ ╭─CodeBlockStart '{'
// CHECK:STDOUT:   │ │ ├─CodeBlock '}'
// CHECK:STDOUT:   │ ├─WhileStatement 'while'
// CHECK:STDOUT:   ├─FunctionDefinition '}'
// CHECK:STDOUT:   ├─FileEnd ''
// CHECK:STDOUT:   (root)
// CHECK:STDOUT: - filename: alternative_payload.carbon
// CHECK:STDOUT:   ╭─FileStart ''
// CHECK:STDOUT:   │   ╭─FunctionIntroducer 'fn'
// CHECK:STDOUT:   │   ├─IdentifierNameMaybeBeforeSignature 'F'
// CHECK:STDOUT:   │   │ ╭─ExplicitParamListStart '('
// CHECK:STDOUT:   │   │ │ ╭─IdentifierNameNotBeforeSignature 'opt'
// CHECK:STDOUT:   │   │ │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │   │ │ ├─IdentifierNameExpr 'Opt'
// CHECK:STDOUT:   │   │ ├─LetBindingPattern ':'
// CHECK:STDOUT:   │   ├─ExplicitParamList ')'
// CHECK:STDOUT:   │ ╭─FunctionDefinitionStart '{'
// CHECK:STDOUT:   │ │   ╭─WhileConditionStart '('
// CHECK:STDOUT:   │ │   ├─PatternConditionIntroducer 'let'
// CHECK:STDOUT:   │ │   │ ╭─AlternativePatternStart '.'
// CHECK:STDOUT:   │ │   │ ├─IdentifierNameNotBeforeSignature 'Some'
// CHECK:STDOUT:   │ │   │ │ ╭─TuplePatternStart '('
// CHECK:STDOUT:   │ │   │ │ │ ╭─IdentifierNameNotBeforeSignature 'n'
// CHECK:STDOUT:   │ │   │ │ │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │ │   │ │ │ ├─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │ │   │ │ ├─LetBindingPattern ':'
// CHECK:STDOUT:   │ │   │ ├─ParenPattern ')'
// CHECK:STDOUT:   │ │   ├─AlternativePattern '.'
// CHECK:STDOUT:   │ │   ├─PatternConditionInitializer '='
// CHECK:STDOUT:   │ │   ├─IdentifierNameExpr 'opt'
// CHECK:STDOUT:   │ │ ╭─WhileCondition ')'
// CHECK:STDOUT:   │ │ │ ╭─CodeBlockStart '{'
// CHECK:STDOUT:   │ │ ├─CodeBlock '}'
// CHECK:STDOUT:   │ ├─WhileStatement 'while'
// CHECK:STDOUT:   ├─FunctionDefinition '}'
// CHECK:STDOUT:   ├─FileEnd ''
// CHECK:STDOUT:   (root)
