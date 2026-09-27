// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/parse/testdata/let/let_else.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/parse/testdata/let/let_else.carbon

// `let`-`else` declarations (W-012, fork/design-sprint/if-let.md Option A):
// a `let` or `var` declaration followed by `else` and a code block. The
// introducer is re-kinded to `LetElseIntroducer` when the `else` is reached,
// the `else` is a `LetElse` leaf hooking the block, and `LetElseDecl` closes
// the declaration at the introducer token. No trailing `;`.

// --- basic.carbon

fn F(y: i32) -> i32 {
  let x: i32 = y else { return 0; }
  return x;
}

// --- alternative_payload.carbon

fn F(opt: Opt) -> i32 {
  let .Some(port: i32) = opt else { return -1; }
  return port;
}

// --- alternative_bare.carbon

fn F(opt: Opt) -> i32 {
  let .None = opt else { return -1; }
  return 0;
}

// --- var_else.carbon

fn F(opt: Opt) -> i32 {
  var .Some(v: i32) = opt else { return 0; }
  v = v + 1;
  return v;
}

// --- tuple.carbon

fn F(pair: (i32, i32)) -> i32 {
  let (0, n: i32) = pair else { return -1; }
  return n;
}

// --- with_modifier.carbon

fn F(opt: Opt) -> i32 {
  private let .Some(n: i32) = opt else { return -1; }
  return n;
}

// --- returned_var_else.carbon

fn F(opt: Opt) -> i32 {
  returned var .Some(v: i32) = opt else { return 0; }
  return var;
}

// --- if_expr_struct_literal_else.carbon

fn F(c: bool, t: {.a: i32}, u: {}) {
  var s: {.a: i32} = if c then t else {.a = 1};
  var e: {} = if c then u else {};
}

// CHECK:STDOUT: - filename: basic.carbon
// CHECK:STDOUT:   ╭─FileStart ''
// CHECK:STDOUT:   │   ╭─FunctionIntroducer 'fn'
// CHECK:STDOUT:   │   ├─IdentifierNameMaybeBeforeSignature 'F'
// CHECK:STDOUT:   │   │ ╭─ExplicitParamListStart '('
// CHECK:STDOUT:   │   │ │ ╭─IdentifierNameNotBeforeSignature 'y'
// CHECK:STDOUT:   │   │ │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │   │ │ ├─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │   │ ├─LetBindingPattern ':'
// CHECK:STDOUT:   │   ├─ExplicitParamList ')'
// CHECK:STDOUT:   │   │ ╭─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │   ├─ReturnType '->'
// CHECK:STDOUT:   │ ╭─FunctionDefinitionStart '{'
// CHECK:STDOUT:   │ │ ╭─LetElseIntroducer 'let'
// CHECK:STDOUT:   │ │ │ ╭─IdentifierNameNotBeforeSignature 'x'
// CHECK:STDOUT:   │ │ │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │ │ │ ├─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │ │ ├─LetBindingPattern ':'
// CHECK:STDOUT:   │ │ ├─LetInitializer '='
// CHECK:STDOUT:   │ │ ├─IdentifierNameExpr 'y'
// CHECK:STDOUT:   │ │ ├─LetElse 'else'
// CHECK:STDOUT:   │ │ │ ╭─CodeBlockStart '{'
// CHECK:STDOUT:   │ │ │ │ ╭─ReturnStatementStart 'return'
// CHECK:STDOUT:   │ │ │ │ ├─IntLiteral '0'
// CHECK:STDOUT:   │ │ │ ├─ReturnStatement ';'
// CHECK:STDOUT:   │ │ ├─CodeBlock '}'
// CHECK:STDOUT:   │ ├─LetElseDecl 'let'
// CHECK:STDOUT:   │ │ ╭─ReturnStatementStart 'return'
// CHECK:STDOUT:   │ │ ├─IdentifierNameExpr 'x'
// CHECK:STDOUT:   │ ├─ReturnStatement ';'
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
// CHECK:STDOUT:   │   │ ╭─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │   ├─ReturnType '->'
// CHECK:STDOUT:   │ ╭─FunctionDefinitionStart '{'
// CHECK:STDOUT:   │ │ ╭─LetElseIntroducer 'let'
// CHECK:STDOUT:   │ │ │ ╭─AlternativePatternStart '.'
// CHECK:STDOUT:   │ │ │ ├─IdentifierNameNotBeforeSignature 'Some'
// CHECK:STDOUT:   │ │ │ │ ╭─TuplePatternStart '('
// CHECK:STDOUT:   │ │ │ │ │ ╭─IdentifierNameNotBeforeSignature 'port'
// CHECK:STDOUT:   │ │ │ │ │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │ │ │ │ │ ├─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │ │ │ │ ├─LetBindingPattern ':'
// CHECK:STDOUT:   │ │ │ ├─ParenPattern ')'
// CHECK:STDOUT:   │ │ ├─AlternativePattern '.'
// CHECK:STDOUT:   │ │ ├─LetInitializer '='
// CHECK:STDOUT:   │ │ ├─IdentifierNameExpr 'opt'
// CHECK:STDOUT:   │ │ ├─LetElse 'else'
// CHECK:STDOUT:   │ │ │ ╭─CodeBlockStart '{'
// CHECK:STDOUT:   │ │ │ │ ╭─ReturnStatementStart 'return'
// CHECK:STDOUT:   │ │ │ │ │ ╭─IntLiteral '1'
// CHECK:STDOUT:   │ │ │ │ ├─PrefixOperatorMinus '-'
// CHECK:STDOUT:   │ │ │ ├─ReturnStatement ';'
// CHECK:STDOUT:   │ │ ├─CodeBlock '}'
// CHECK:STDOUT:   │ ├─LetElseDecl 'let'
// CHECK:STDOUT:   │ │ ╭─ReturnStatementStart 'return'
// CHECK:STDOUT:   │ │ ├─IdentifierNameExpr 'port'
// CHECK:STDOUT:   │ ├─ReturnStatement ';'
// CHECK:STDOUT:   ├─FunctionDefinition '}'
// CHECK:STDOUT:   ├─FileEnd ''
// CHECK:STDOUT:   (root)
// CHECK:STDOUT: - filename: alternative_bare.carbon
// CHECK:STDOUT:   ╭─FileStart ''
// CHECK:STDOUT:   │   ╭─FunctionIntroducer 'fn'
// CHECK:STDOUT:   │   ├─IdentifierNameMaybeBeforeSignature 'F'
// CHECK:STDOUT:   │   │ ╭─ExplicitParamListStart '('
// CHECK:STDOUT:   │   │ │ ╭─IdentifierNameNotBeforeSignature 'opt'
// CHECK:STDOUT:   │   │ │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │   │ │ ├─IdentifierNameExpr 'Opt'
// CHECK:STDOUT:   │   │ ├─LetBindingPattern ':'
// CHECK:STDOUT:   │   ├─ExplicitParamList ')'
// CHECK:STDOUT:   │   │ ╭─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │   ├─ReturnType '->'
// CHECK:STDOUT:   │ ╭─FunctionDefinitionStart '{'
// CHECK:STDOUT:   │ │ ╭─LetElseIntroducer 'let'
// CHECK:STDOUT:   │ │ │ ╭─AlternativePatternStart '.'
// CHECK:STDOUT:   │ │ │ ├─IdentifierNameNotBeforeSignature 'None'
// CHECK:STDOUT:   │ │ ├─AlternativePattern '.'
// CHECK:STDOUT:   │ │ ├─LetInitializer '='
// CHECK:STDOUT:   │ │ ├─IdentifierNameExpr 'opt'
// CHECK:STDOUT:   │ │ ├─LetElse 'else'
// CHECK:STDOUT:   │ │ │ ╭─CodeBlockStart '{'
// CHECK:STDOUT:   │ │ │ │ ╭─ReturnStatementStart 'return'
// CHECK:STDOUT:   │ │ │ │ │ ╭─IntLiteral '1'
// CHECK:STDOUT:   │ │ │ │ ├─PrefixOperatorMinus '-'
// CHECK:STDOUT:   │ │ │ ├─ReturnStatement ';'
// CHECK:STDOUT:   │ │ ├─CodeBlock '}'
// CHECK:STDOUT:   │ ├─LetElseDecl 'let'
// CHECK:STDOUT:   │ │ ╭─ReturnStatementStart 'return'
// CHECK:STDOUT:   │ │ ├─IntLiteral '0'
// CHECK:STDOUT:   │ ├─ReturnStatement ';'
// CHECK:STDOUT:   ├─FunctionDefinition '}'
// CHECK:STDOUT:   ├─FileEnd ''
// CHECK:STDOUT:   (root)
// CHECK:STDOUT: - filename: var_else.carbon
// CHECK:STDOUT:   ╭─FileStart ''
// CHECK:STDOUT:   │   ╭─FunctionIntroducer 'fn'
// CHECK:STDOUT:   │   ├─IdentifierNameMaybeBeforeSignature 'F'
// CHECK:STDOUT:   │   │ ╭─ExplicitParamListStart '('
// CHECK:STDOUT:   │   │ │ ╭─IdentifierNameNotBeforeSignature 'opt'
// CHECK:STDOUT:   │   │ │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │   │ │ ├─IdentifierNameExpr 'Opt'
// CHECK:STDOUT:   │   │ ├─LetBindingPattern ':'
// CHECK:STDOUT:   │   ├─ExplicitParamList ')'
// CHECK:STDOUT:   │   │ ╭─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │   ├─ReturnType '->'
// CHECK:STDOUT:   │ ╭─FunctionDefinitionStart '{'
// CHECK:STDOUT:   │ │ ╭─LetElseIntroducer 'var'
// CHECK:STDOUT:   │ │ │   ╭─AlternativePatternStart '.'
// CHECK:STDOUT:   │ │ │   ├─IdentifierNameNotBeforeSignature 'Some'
// CHECK:STDOUT:   │ │ │   │ ╭─TuplePatternStart '('
// CHECK:STDOUT:   │ │ │   │ │ ╭─IdentifierNameNotBeforeSignature 'v'
// CHECK:STDOUT:   │ │ │   │ │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │ │ │   │ │ ├─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │ │ │   │ ├─VarBindingPattern ':'
// CHECK:STDOUT:   │ │ │   ├─ParenPattern ')'
// CHECK:STDOUT:   │ │ │ ╭─AlternativePattern '.'
// CHECK:STDOUT:   │ │ ├─VariablePattern 'var'
// CHECK:STDOUT:   │ │ ├─VariableInitializer '='
// CHECK:STDOUT:   │ │ ├─IdentifierNameExpr 'opt'
// CHECK:STDOUT:   │ │ ├─LetElse 'else'
// CHECK:STDOUT:   │ │ │ ╭─CodeBlockStart '{'
// CHECK:STDOUT:   │ │ │ │ ╭─ReturnStatementStart 'return'
// CHECK:STDOUT:   │ │ │ │ ├─IntLiteral '0'
// CHECK:STDOUT:   │ │ │ ├─ReturnStatement ';'
// CHECK:STDOUT:   │ │ ├─CodeBlock '}'
// CHECK:STDOUT:   │ ├─LetElseDecl 'var'
// CHECK:STDOUT:   │ │   ╭─IdentifierNameExpr 'v'
// CHECK:STDOUT:   │ │   │ ╭─IdentifierNameExpr 'v'
// CHECK:STDOUT:   │ │   │ ├─IntLiteral '1'
// CHECK:STDOUT:   │ │   ├─InfixOperatorPlus '+'
// CHECK:STDOUT:   │ │ ╭─InfixOperatorEqual '='
// CHECK:STDOUT:   │ ├─ExprStatement ';'
// CHECK:STDOUT:   │ │ ╭─ReturnStatementStart 'return'
// CHECK:STDOUT:   │ │ ├─IdentifierNameExpr 'v'
// CHECK:STDOUT:   │ ├─ReturnStatement ';'
// CHECK:STDOUT:   ├─FunctionDefinition '}'
// CHECK:STDOUT:   ├─FileEnd ''
// CHECK:STDOUT:   (root)
// CHECK:STDOUT: - filename: tuple.carbon
// CHECK:STDOUT:   ╭─FileStart ''
// CHECK:STDOUT:   │   ╭─FunctionIntroducer 'fn'
// CHECK:STDOUT:   │   ├─IdentifierNameMaybeBeforeSignature 'F'
// CHECK:STDOUT:   │   │ ╭─ExplicitParamListStart '('
// CHECK:STDOUT:   │   │ │ ╭─IdentifierNameNotBeforeSignature 'pair'
// CHECK:STDOUT:   │   │ │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │   │ │ │ ╭─TupleLiteralStart '('
// CHECK:STDOUT:   │   │ │ │ ├─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │   │ │ │ ├─TupleLiteralComma ','
// CHECK:STDOUT:   │   │ │ │ ├─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │   │ │ ├─TupleLiteral ')'
// CHECK:STDOUT:   │   │ ├─LetBindingPattern ':'
// CHECK:STDOUT:   │   ├─ExplicitParamList ')'
// CHECK:STDOUT:   │   │ ╭─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │   ├─ReturnType '->'
// CHECK:STDOUT:   │ ╭─FunctionDefinitionStart '{'
// CHECK:STDOUT:   │ │ ╭─LetElseIntroducer 'let'
// CHECK:STDOUT:   │ │ │ ╭─TuplePatternStart '('
// CHECK:STDOUT:   │ │ │ ├─IntLiteral '0'
// CHECK:STDOUT:   │ │ │ ├─PatternListComma ','
// CHECK:STDOUT:   │ │ │ │ ╭─IdentifierNameNotBeforeSignature 'n'
// CHECK:STDOUT:   │ │ │ │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │ │ │ │ ├─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │ │ │ ├─LetBindingPattern ':'
// CHECK:STDOUT:   │ │ ├─TuplePattern ')'
// CHECK:STDOUT:   │ │ ├─LetInitializer '='
// CHECK:STDOUT:   │ │ ├─IdentifierNameExpr 'pair'
// CHECK:STDOUT:   │ │ ├─LetElse 'else'
// CHECK:STDOUT:   │ │ │ ╭─CodeBlockStart '{'
// CHECK:STDOUT:   │ │ │ │ ╭─ReturnStatementStart 'return'
// CHECK:STDOUT:   │ │ │ │ │ ╭─IntLiteral '1'
// CHECK:STDOUT:   │ │ │ │ ├─PrefixOperatorMinus '-'
// CHECK:STDOUT:   │ │ │ ├─ReturnStatement ';'
// CHECK:STDOUT:   │ │ ├─CodeBlock '}'
// CHECK:STDOUT:   │ ├─LetElseDecl 'let'
// CHECK:STDOUT:   │ │ ╭─ReturnStatementStart 'return'
// CHECK:STDOUT:   │ │ ├─IdentifierNameExpr 'n'
// CHECK:STDOUT:   │ ├─ReturnStatement ';'
// CHECK:STDOUT:   ├─FunctionDefinition '}'
// CHECK:STDOUT:   ├─FileEnd ''
// CHECK:STDOUT:   (root)
// CHECK:STDOUT: - filename: with_modifier.carbon
// CHECK:STDOUT:   ╭─FileStart ''
// CHECK:STDOUT:   │   ╭─FunctionIntroducer 'fn'
// CHECK:STDOUT:   │   ├─IdentifierNameMaybeBeforeSignature 'F'
// CHECK:STDOUT:   │   │ ╭─ExplicitParamListStart '('
// CHECK:STDOUT:   │   │ │ ╭─IdentifierNameNotBeforeSignature 'opt'
// CHECK:STDOUT:   │   │ │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │   │ │ ├─IdentifierNameExpr 'Opt'
// CHECK:STDOUT:   │   │ ├─LetBindingPattern ':'
// CHECK:STDOUT:   │   ├─ExplicitParamList ')'
// CHECK:STDOUT:   │   │ ╭─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │   ├─ReturnType '->'
// CHECK:STDOUT:   │ ╭─FunctionDefinitionStart '{'
// CHECK:STDOUT:   │ │ ╭─LetElseIntroducer 'let'
// CHECK:STDOUT:   │ │ ├─PrivateModifier 'private'
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
// CHECK:STDOUT:   │ │ ├─LetElse 'else'
// CHECK:STDOUT:   │ │ │ ╭─CodeBlockStart '{'
// CHECK:STDOUT:   │ │ │ │ ╭─ReturnStatementStart 'return'
// CHECK:STDOUT:   │ │ │ │ │ ╭─IntLiteral '1'
// CHECK:STDOUT:   │ │ │ │ ├─PrefixOperatorMinus '-'
// CHECK:STDOUT:   │ │ │ ├─ReturnStatement ';'
// CHECK:STDOUT:   │ │ ├─CodeBlock '}'
// CHECK:STDOUT:   │ ├─LetElseDecl 'let'
// CHECK:STDOUT:   │ │ ╭─ReturnStatementStart 'return'
// CHECK:STDOUT:   │ │ ├─IdentifierNameExpr 'n'
// CHECK:STDOUT:   │ ├─ReturnStatement ';'
// CHECK:STDOUT:   ├─FunctionDefinition '}'
// CHECK:STDOUT:   ├─FileEnd ''
// CHECK:STDOUT:   (root)
// CHECK:STDOUT: - filename: returned_var_else.carbon
// CHECK:STDOUT:   ╭─FileStart ''
// CHECK:STDOUT:   │   ╭─FunctionIntroducer 'fn'
// CHECK:STDOUT:   │   ├─IdentifierNameMaybeBeforeSignature 'F'
// CHECK:STDOUT:   │   │ ╭─ExplicitParamListStart '('
// CHECK:STDOUT:   │   │ │ ╭─IdentifierNameNotBeforeSignature 'opt'
// CHECK:STDOUT:   │   │ │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │   │ │ ├─IdentifierNameExpr 'Opt'
// CHECK:STDOUT:   │   │ ├─LetBindingPattern ':'
// CHECK:STDOUT:   │   ├─ExplicitParamList ')'
// CHECK:STDOUT:   │   │ ╭─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │   ├─ReturnType '->'
// CHECK:STDOUT:   │ ╭─FunctionDefinitionStart '{'
// CHECK:STDOUT:   │ │ ╭─LetElseIntroducer 'var'
// CHECK:STDOUT:   │ │ ├─ReturnedModifier 'returned'
// CHECK:STDOUT:   │ │ │   ╭─AlternativePatternStart '.'
// CHECK:STDOUT:   │ │ │   ├─IdentifierNameNotBeforeSignature 'Some'
// CHECK:STDOUT:   │ │ │   │ ╭─TuplePatternStart '('
// CHECK:STDOUT:   │ │ │   │ │ ╭─IdentifierNameNotBeforeSignature 'v'
// CHECK:STDOUT:   │ │ │   │ │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │ │ │   │ │ ├─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │ │ │   │ ├─VarBindingPattern ':'
// CHECK:STDOUT:   │ │ │   ├─ParenPattern ')'
// CHECK:STDOUT:   │ │ │ ╭─AlternativePattern '.'
// CHECK:STDOUT:   │ │ ├─VariablePattern 'var'
// CHECK:STDOUT:   │ │ ├─VariableInitializer '='
// CHECK:STDOUT:   │ │ ├─IdentifierNameExpr 'opt'
// CHECK:STDOUT:   │ │ ├─LetElse 'else'
// CHECK:STDOUT:   │ │ │ ╭─CodeBlockStart '{'
// CHECK:STDOUT:   │ │ │ │ ╭─ReturnStatementStart 'return'
// CHECK:STDOUT:   │ │ │ │ ├─IntLiteral '0'
// CHECK:STDOUT:   │ │ │ ├─ReturnStatement ';'
// CHECK:STDOUT:   │ │ ├─CodeBlock '}'
// CHECK:STDOUT:   │ ├─LetElseDecl 'var'
// CHECK:STDOUT:   │ │ ╭─ReturnStatementStart 'return'
// CHECK:STDOUT:   │ │ ├─ReturnVarModifier 'var'
// CHECK:STDOUT:   │ ├─ReturnStatement ';'
// CHECK:STDOUT:   ├─FunctionDefinition '}'
// CHECK:STDOUT:   ├─FileEnd ''
// CHECK:STDOUT:   (root)
// CHECK:STDOUT: - filename: if_expr_struct_literal_else.carbon
// CHECK:STDOUT:   ╭─FileStart ''
// CHECK:STDOUT:   │   ╭─FunctionIntroducer 'fn'
// CHECK:STDOUT:   │   ├─IdentifierNameMaybeBeforeSignature 'F'
// CHECK:STDOUT:   │   │ ╭─ExplicitParamListStart '('
// CHECK:STDOUT:   │   │ │ ╭─IdentifierNameNotBeforeSignature 'c'
// CHECK:STDOUT:   │   │ │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │   │ │ ├─BoolTypeLiteral 'bool'
// CHECK:STDOUT:   │   │ ├─LetBindingPattern ':'
// CHECK:STDOUT:   │   │ ├─PatternListComma ','
// CHECK:STDOUT:   │   │ │ ╭─IdentifierNameNotBeforeSignature 't'
// CHECK:STDOUT:   │   │ │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │   │ │ │ ╭─StructTypeLiteralStart '{'
// CHECK:STDOUT:   │   │ │ │ │   ╭─IdentifierNameNotBeforeSignature 'a'
// CHECK:STDOUT:   │   │ │ │ │ ╭─StructFieldDesignator '.'
// CHECK:STDOUT:   │   │ │ │ │ ├─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │   │ │ │ ├─StructTypeLiteralField ':'
// CHECK:STDOUT:   │   │ │ ├─StructTypeLiteral '}'
// CHECK:STDOUT:   │   │ ├─LetBindingPattern ':'
// CHECK:STDOUT:   │   │ ├─PatternListComma ','
// CHECK:STDOUT:   │   │ │ ╭─IdentifierNameNotBeforeSignature 'u'
// CHECK:STDOUT:   │   │ │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │   │ │ │ ╭─StructLiteralStart '{'
// CHECK:STDOUT:   │   │ │ ├─StructLiteral '}'
// CHECK:STDOUT:   │   │ ├─LetBindingPattern ':'
// CHECK:STDOUT:   │   ├─ExplicitParamList ')'
// CHECK:STDOUT:   │ ╭─FunctionDefinitionStart '{'
// CHECK:STDOUT:   │ │ ╭─VariableIntroducer 'var'
// CHECK:STDOUT:   │ │ │   ╭─IdentifierNameNotBeforeSignature 's'
// CHECK:STDOUT:   │ │ │   ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │ │ │   │ ╭─StructTypeLiteralStart '{'
// CHECK:STDOUT:   │ │ │   │ │   ╭─IdentifierNameNotBeforeSignature 'a'
// CHECK:STDOUT:   │ │ │   │ │ ╭─StructFieldDesignator '.'
// CHECK:STDOUT:   │ │ │   │ │ ├─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │ │ │   │ ├─StructTypeLiteralField ':'
// CHECK:STDOUT:   │ │ │   ├─StructTypeLiteral '}'
// CHECK:STDOUT:   │ │ │ ╭─VarBindingPattern ':'
// CHECK:STDOUT:   │ │ ├─VariablePattern 'var'
// CHECK:STDOUT:   │ │ ├─VariableInitializer '='
// CHECK:STDOUT:   │ │ │   ╭─IdentifierNameExpr 'c'
// CHECK:STDOUT:   │ │ │ ╭─IfExprIf 'if'
// CHECK:STDOUT:   │ │ │ │ ╭─IdentifierNameExpr 't'
// CHECK:STDOUT:   │ │ │ ├─IfExprThen 'then'
// CHECK:STDOUT:   │ │ │ │ ╭─StructLiteralStart '{'
// CHECK:STDOUT:   │ │ │ │ │   ╭─IdentifierNameNotBeforeSignature 'a'
// CHECK:STDOUT:   │ │ │ │ │ ╭─StructFieldDesignator '.'
// CHECK:STDOUT:   │ │ │ │ │ ├─IntLiteral '1'
// CHECK:STDOUT:   │ │ │ │ ├─StructLiteralField '='
// CHECK:STDOUT:   │ │ │ ├─StructLiteral '}'
// CHECK:STDOUT:   │ │ ├─IfExprElse 'else'
// CHECK:STDOUT:   │ ├─VariableDecl ';'
// CHECK:STDOUT:   │ │ ╭─VariableIntroducer 'var'
// CHECK:STDOUT:   │ │ │   ╭─IdentifierNameNotBeforeSignature 'e'
// CHECK:STDOUT:   │ │ │   ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │ │ │   │ ╭─StructLiteralStart '{'
// CHECK:STDOUT:   │ │ │   ├─StructLiteral '}'
// CHECK:STDOUT:   │ │ │ ╭─VarBindingPattern ':'
// CHECK:STDOUT:   │ │ ├─VariablePattern 'var'
// CHECK:STDOUT:   │ │ ├─VariableInitializer '='
// CHECK:STDOUT:   │ │ │   ╭─IdentifierNameExpr 'c'
// CHECK:STDOUT:   │ │ │ ╭─IfExprIf 'if'
// CHECK:STDOUT:   │ │ │ │ ╭─IdentifierNameExpr 'u'
// CHECK:STDOUT:   │ │ │ ├─IfExprThen 'then'
// CHECK:STDOUT:   │ │ │ │ ╭─StructLiteralStart '{'
// CHECK:STDOUT:   │ │ │ ├─StructLiteral '}'
// CHECK:STDOUT:   │ │ ├─IfExprElse 'else'
// CHECK:STDOUT:   │ ├─VariableDecl ';'
// CHECK:STDOUT:   ├─FunctionDefinition '}'
// CHECK:STDOUT:   ├─FileEnd ''
// CHECK:STDOUT:   (root)
