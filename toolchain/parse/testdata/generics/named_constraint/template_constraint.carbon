// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/parse/testdata/generics/named_constraint/template_constraint.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/parse/testdata/generics/named_constraint/template_constraint.carbon

// --- template_constraint.carbon

template constraint Foo {
  // TODO: Add a require statement.
  fn DeclaredMethod();
  fn DefinedMethod() {}
}

template constraint ForwardDeclared;

// CHECK:STDOUT: - filename: template_constraint.carbon
// CHECK:STDOUT:   ╭─FileStart ''
// CHECK:STDOUT:   │   ╭─NamedConstraintIntroducer 'constraint'
// CHECK:STDOUT:   │   ├─TemplateModifier 'template'
// CHECK:STDOUT:   │   ├─IdentifierNameNotBeforeSignature 'Foo'
// CHECK:STDOUT:   │ ╭─NamedConstraintDefinitionStart '{'
// CHECK:STDOUT:   │ │ ╭─FunctionIntroducer 'fn'
// CHECK:STDOUT:   │ │ ├─IdentifierNameMaybeBeforeSignature 'DeclaredMethod'
// CHECK:STDOUT:   │ │ │ ╭─ExplicitParamListStart '('
// CHECK:STDOUT:   │ │ ├─ExplicitParamList ')'
// CHECK:STDOUT:   │ ├─FunctionDecl ';'
// CHECK:STDOUT:   │ │   ╭─FunctionIntroducer 'fn'
// CHECK:STDOUT:   │ │   ├─IdentifierNameMaybeBeforeSignature 'DefinedMethod'
// CHECK:STDOUT:   │ │   │ ╭─ExplicitParamListStart '('
// CHECK:STDOUT:   │ │   ├─ExplicitParamList ')'
// CHECK:STDOUT:   │ │ ╭─FunctionDefinitionStart '{'
// CHECK:STDOUT:   │ ├─FunctionDefinition '}'
// CHECK:STDOUT:   ├─NamedConstraintDefinition '}'
// CHECK:STDOUT:   │ ╭─NamedConstraintIntroducer 'constraint'
// CHECK:STDOUT:   │ ├─TemplateModifier 'template'
// CHECK:STDOUT:   │ ├─IdentifierNameNotBeforeSignature 'ForwardDeclared'
// CHECK:STDOUT:   ├─NamedConstraintDecl ';'
// CHECK:STDOUT:   ├─FileEnd ''
// CHECK:STDOUT:   (root)
