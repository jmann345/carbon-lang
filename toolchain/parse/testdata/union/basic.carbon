// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/parse/testdata/union/basic.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/parse/testdata/union/basic.carbon

// The design's canonical declaration shape (docs/design/unions.md, "Declaring
// a union" and "Union members"): `var` fields and a method with `self`.
union IntOrBytes {
  var word: u32;
  var bytes: array(u8, 4);

  fn LowByte(self) -> u8 { return self.bytes[0]; }
}

// CHECK:STDOUT: - filename: basic.carbon
// CHECK:STDOUT:   ╭─FileStart ''
// CHECK:STDOUT:   │   ╭─UnionIntroducer 'union'
// CHECK:STDOUT:   │   ├─IdentifierNameNotBeforeSignature 'IntOrBytes'
// CHECK:STDOUT:   │ ╭─UnionDefinitionStart '{'
// CHECK:STDOUT:   │ │ ╭─VariableIntroducer 'var'
// CHECK:STDOUT:   │ │ │   ╭─IdentifierNameNotBeforeSignature 'word'
// CHECK:STDOUT:   │ │ │   ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │ │ │   ├─UnsignedIntTypeLiteral 'u32'
// CHECK:STDOUT:   │ │ │ ╭─VarBindingPattern ':'
// CHECK:STDOUT:   │ │ ├─VariablePattern 'var'
// CHECK:STDOUT:   │ ├─VariableDecl ';'
// CHECK:STDOUT:   │ │ ╭─VariableIntroducer 'var'
// CHECK:STDOUT:   │ │ │   ╭─IdentifierNameNotBeforeSignature 'bytes'
// CHECK:STDOUT:   │ │ │   ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │ │ │   │ ╭─ArrayExprKeyword 'array'
// CHECK:STDOUT:   │ │ │   │ ├─ArrayExprOpenParen '('
// CHECK:STDOUT:   │ │ │   │ ├─UnsignedIntTypeLiteral 'u8'
// CHECK:STDOUT:   │ │ │   │ ├─ArrayExprComma ','
// CHECK:STDOUT:   │ │ │   │ ├─IntLiteral '4'
// CHECK:STDOUT:   │ │ │   ├─ArrayExpr ')'
// CHECK:STDOUT:   │ │ │ ╭─VarBindingPattern ':'
// CHECK:STDOUT:   │ │ ├─VariablePattern 'var'
// CHECK:STDOUT:   │ ├─VariableDecl ';'
// CHECK:STDOUT:   │ │   ╭─FunctionIntroducer 'fn'
// CHECK:STDOUT:   │ │   ├─IdentifierNameMaybeBeforeSignature 'LowByte'
// CHECK:STDOUT:   │ │   │ ╭─ExplicitParamListStart '('
// CHECK:STDOUT:   │ │   │ │ ╭─SelfValueName 'self'
// CHECK:STDOUT:   │ │   │ ├─SelfBindingPattern 'self'
// CHECK:STDOUT:   │ │   ├─ExplicitParamList ')'
// CHECK:STDOUT:   │ │   │ ╭─UnsignedIntTypeLiteral 'u8'
// CHECK:STDOUT:   │ │   ├─ReturnType '->'
// CHECK:STDOUT:   │ │ ╭─FunctionDefinitionStart '{'
// CHECK:STDOUT:   │ │ │ ╭─ReturnStatementStart 'return'
// CHECK:STDOUT:   │ │ │ │     ╭─SelfValueNameExpr 'self'
// CHECK:STDOUT:   │ │ │ │     ├─IdentifierNameNotBeforeSignature 'bytes'
// CHECK:STDOUT:   │ │ │ │   ╭─MemberAccessExpr '.'
// CHECK:STDOUT:   │ │ │ │ ╭─IndexExprStart '['
// CHECK:STDOUT:   │ │ │ │ ├─IntLiteral '0'
// CHECK:STDOUT:   │ │ │ ├─IndexExpr ']'
// CHECK:STDOUT:   │ │ ├─ReturnStatement ';'
// CHECK:STDOUT:   │ ├─FunctionDefinition '}'
// CHECK:STDOUT:   ├─UnionDefinition '}'
// CHECK:STDOUT:   ├─FileEnd ''
// CHECK:STDOUT:   (root)
