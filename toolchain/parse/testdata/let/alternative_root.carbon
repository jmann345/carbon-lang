// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/parse/testdata/let/alternative_root.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/parse/testdata/let/alternative_root.carbon

// A root `.Name` in a plain `let`/`var` parses as an alternative pattern
// (the same root peek `let`-`else` needs; the parser cannot know about the
// `else` yet). Check gates the refutable root outside a refutable context.

// --- let_root.carbon

fn F(opt: Opt) {
  let .Some(n: i32) = opt;
}

// --- var_root.carbon

fn F(opt: Opt) {
  var .None = opt;
}

// CHECK:STDOUT: - filename: let_root.carbon
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
// CHECK:STDOUT:   │ │ ╭─LetIntroducer 'let'
// CHECK:STDOUT:   │ │ │ ╭─AlternativePatternStart '.'
// CHECK:STDOUT:   │ │ │ ├─IdentifierNameNotBeforeSignature 'Some'
// CHECK:STDOUT:   │ │ │ │ ╭─TuplePatternStart '('
// CHECK:STDOUT:   │ │ │ │ │ ╭─IdentifierNameNotBeforeSignature 'n'
// CHECK:STDOUT:   │ │ │ │ │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │ │ │ │ │ ├─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │ │ │ │ ├─LetBindingPattern ':'
// CHECK:STDOUT:   │ │ │ ├─ParenPattern ')'
// CHECK:STDOUT:   │ │ ├─AlternativePattern '.'
// CHECK:STDOUT:   │ │ ├─LetInitializer '='
// CHECK:STDOUT:   │ │ ├─IdentifierNameExpr 'opt'
// CHECK:STDOUT:   │ ├─LetDecl ';'
// CHECK:STDOUT:   ├─FunctionDefinition '}'
// CHECK:STDOUT:   ├─FileEnd ''
// CHECK:STDOUT:   (root)
// CHECK:STDOUT: - filename: var_root.carbon
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
// CHECK:STDOUT:   │ │ ╭─VariableIntroducer 'var'
// CHECK:STDOUT:   │ │ │   ╭─AlternativePatternStart '.'
// CHECK:STDOUT:   │ │ │   ├─IdentifierNameNotBeforeSignature 'None'
// CHECK:STDOUT:   │ │ │ ╭─AlternativePattern '.'
// CHECK:STDOUT:   │ │ ├─VariablePattern 'var'
// CHECK:STDOUT:   │ │ ├─VariableInitializer '='
// CHECK:STDOUT:   │ │ ├─IdentifierNameExpr 'opt'
// CHECK:STDOUT:   │ ├─VariableDecl ';'
// CHECK:STDOUT:   ├─FunctionDefinition '}'
// CHECK:STDOUT:   ├─FileEnd ''
// CHECK:STDOUT:   (root)
