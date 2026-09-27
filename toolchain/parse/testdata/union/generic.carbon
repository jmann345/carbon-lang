// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/parse/testdata/union/generic.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/parse/testdata/union/generic.carbon

// A parameterized union parses like a generic class (the parameter list rides
// `DeclNameAndParams`); the 0.1 toolchain's `generic union` TODO is
// check-side (docs/design/unions.md, "Declaring a union").
union Slot(T: type) {
  var value: T;
  var next_free: Slot(T)*;
}

// CHECK:STDOUT: - filename: generic.carbon
// CHECK:STDOUT:   ╭─FileStart ''
// CHECK:STDOUT:   │   ╭─UnionIntroducer 'union'
// CHECK:STDOUT:   │   ├─IdentifierNameMaybeBeforeSignature 'Slot'
// CHECK:STDOUT:   │   │ ╭─ExplicitParamListStart '('
// CHECK:STDOUT:   │   │ │ ╭─IdentifierNameNotBeforeSignature 'T'
// CHECK:STDOUT:   │   │ │ ├─CompileTimeBindingPatternTypeStart ':'
// CHECK:STDOUT:   │   │ │ ├─TypeTypeLiteral 'type'
// CHECK:STDOUT:   │   │ ├─CompileTimeBindingPattern ':'
// CHECK:STDOUT:   │   ├─ExplicitParamList ')'
// CHECK:STDOUT:   │ ╭─UnionDefinitionStart '{'
// CHECK:STDOUT:   │ │ ╭─VariableIntroducer 'var'
// CHECK:STDOUT:   │ │ │   ╭─IdentifierNameNotBeforeSignature 'value'
// CHECK:STDOUT:   │ │ │   ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │ │ │   ├─IdentifierNameExpr 'T'
// CHECK:STDOUT:   │ │ │ ╭─VarBindingPattern ':'
// CHECK:STDOUT:   │ │ ├─VariablePattern 'var'
// CHECK:STDOUT:   │ ├─VariableDecl ';'
// CHECK:STDOUT:   │ │ ╭─VariableIntroducer 'var'
// CHECK:STDOUT:   │ │ │   ╭─IdentifierNameNotBeforeSignature 'next_free'
// CHECK:STDOUT:   │ │ │   ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │ │ │   │     ╭─IdentifierNameExpr 'Slot'
// CHECK:STDOUT:   │ │ │   │   ╭─CallExprStart '('
// CHECK:STDOUT:   │ │ │   │   ├─IdentifierNameExpr 'T'
// CHECK:STDOUT:   │ │ │   │ ╭─CallExpr ')'
// CHECK:STDOUT:   │ │ │   ├─PostfixOperatorStar '*'
// CHECK:STDOUT:   │ │ │ ╭─VarBindingPattern ':'
// CHECK:STDOUT:   │ │ ├─VariablePattern 'var'
// CHECK:STDOUT:   │ ├─VariableDecl ';'
// CHECK:STDOUT:   ├─UnionDefinition '}'
// CHECK:STDOUT:   ├─FileEnd ''
// CHECK:STDOUT:   (root)
