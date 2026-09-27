// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/parse/testdata/let/let_else_missing_initializer.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/parse/testdata/let/let_else_missing_initializer.carbon

// `let P else {...}` with no `= e` parses (W-012): `LetElseDecl::init` is
// optional, so the tree verifies; check diagnoses the missing initializer
// (`ExpectedInitializerAfterLet`, check/testdata/let/fail_let_else.carbon).
choice OptInt {
  Some(x: i32),
  None
}

fn F(o: OptInt) -> i32 {
  let .Some(n: i32) else { return 0; }
  return n;
}

// CHECK:STDOUT: - filename: let_else_missing_initializer.carbon
// CHECK:STDOUT:   ╭─FileStart ''
// CHECK:STDOUT:   │   ╭─ChoiceIntroducer 'choice'
// CHECK:STDOUT:   │   ├─IdentifierNameNotBeforeSignature 'OptInt'
// CHECK:STDOUT:   │ ╭─ChoiceDefinitionStart '{'
// CHECK:STDOUT:   │ ├─IdentifierNameMaybeBeforeSignature 'Some'
// CHECK:STDOUT:   │ │ ╭─ExplicitParamListStart '('
// CHECK:STDOUT:   │ │ │ ╭─IdentifierNameNotBeforeSignature 'x'
// CHECK:STDOUT:   │ │ │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │ │ │ ├─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │ │ ├─LetBindingPattern ':'
// CHECK:STDOUT:   │ ├─ExplicitParamList ')'
// CHECK:STDOUT:   │ ├─ChoiceAlternativeListComma ','
// CHECK:STDOUT:   │ ├─IdentifierNameNotBeforeSignature 'None'
// CHECK:STDOUT:   ├─ChoiceDefinition '}'
// CHECK:STDOUT:   │   ╭─FunctionIntroducer 'fn'
// CHECK:STDOUT:   │   ├─IdentifierNameMaybeBeforeSignature 'F'
// CHECK:STDOUT:   │   │ ╭─ExplicitParamListStart '('
// CHECK:STDOUT:   │   │ │ ╭─IdentifierNameNotBeforeSignature 'o'
// CHECK:STDOUT:   │   │ │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │   │ │ ├─IdentifierNameExpr 'OptInt'
// CHECK:STDOUT:   │   │ ├─LetBindingPattern ':'
// CHECK:STDOUT:   │   ├─ExplicitParamList ')'
// CHECK:STDOUT:   │   │ ╭─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │   ├─ReturnType '->'
// CHECK:STDOUT:   │ ╭─FunctionDefinitionStart '{'
// CHECK:STDOUT:   │ │ ╭─LetElseIntroducer 'let'
// CHECK:STDOUT:   │ │ │ ╭─AlternativePatternStart '.'
// CHECK:STDOUT:   │ │ │ ├─IdentifierNameNotBeforeSignature 'Some'
// CHECK:STDOUT:   │ │ │ │ ╭─TuplePatternStart '('
// CHECK:STDOUT:   │ │ │ │ │ ╭─IdentifierNameNotBeforeSignature 'n'
// CHECK:STDOUT:   │ │ │ │ │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │ │ │ │ │ ├─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │ │ │ │ ├─LetBindingPattern ':'
// CHECK:STDOUT:   │ │ │ ├─ParenPattern ')'
// CHECK:STDOUT:   │ │ ├─AlternativePattern '.'
// CHECK:STDOUT:   │ │ ├─LetElse 'else'
// CHECK:STDOUT:   │ │ │ ╭─CodeBlockStart '{'
// CHECK:STDOUT:   │ │ │ │ ╭─ReturnStatementStart 'return'
// CHECK:STDOUT:   │ │ │ │ ├─IntLiteral '0'
// CHECK:STDOUT:   │ │ │ ├─ReturnStatement ';'
// CHECK:STDOUT:   │ │ ├─CodeBlock '}'
// CHECK:STDOUT:   │ ├─LetElseDecl 'let'
// CHECK:STDOUT:   │ │ ╭─ReturnStatementStart 'return'
// CHECK:STDOUT:   │ │ ├─IdentifierNameExpr 'n'
// CHECK:STDOUT:   │ ├─ReturnStatement ';'
// CHECK:STDOUT:   ├─FunctionDefinition '}'
// CHECK:STDOUT:   ├─FileEnd ''
// CHECK:STDOUT:   (root)
