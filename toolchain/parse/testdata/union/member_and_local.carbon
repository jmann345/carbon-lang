// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/parse/testdata/union/member_and_local.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/parse/testdata/union/member_and_local.carbon

// A union as a class member.
class Outer {
  union Inner {
    var a: i32;
  }
  var u: Inner;
}

// A union declared inside a function body takes the statement-context
// declaration dispatch.
fn F() {
  union Local {
    var b: i64;
  }
}

// CHECK:STDOUT: - filename: member_and_local.carbon
// CHECK:STDOUT:   ╭─FileStart ''
// CHECK:STDOUT:   │   ╭─ClassIntroducer 'class'
// CHECK:STDOUT:   │   ├─IdentifierNameNotBeforeSignature 'Outer'
// CHECK:STDOUT:   │ ╭─ClassDefinitionStart '{'
// CHECK:STDOUT:   │ │   ╭─UnionIntroducer 'union'
// CHECK:STDOUT:   │ │   ├─IdentifierNameNotBeforeSignature 'Inner'
// CHECK:STDOUT:   │ │ ╭─UnionDefinitionStart '{'
// CHECK:STDOUT:   │ │ │ ╭─VariableIntroducer 'var'
// CHECK:STDOUT:   │ │ │ │   ╭─IdentifierNameNotBeforeSignature 'a'
// CHECK:STDOUT:   │ │ │ │   ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │ │ │ │   ├─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │ │ │ │ ╭─VarBindingPattern ':'
// CHECK:STDOUT:   │ │ │ ├─VariablePattern 'var'
// CHECK:STDOUT:   │ │ ├─VariableDecl ';'
// CHECK:STDOUT:   │ ├─UnionDefinition '}'
// CHECK:STDOUT:   │ │ ╭─VariableIntroducer 'var'
// CHECK:STDOUT:   │ │ │   ╭─IdentifierNameNotBeforeSignature 'u'
// CHECK:STDOUT:   │ │ │   ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │ │ │   ├─IdentifierNameExpr 'Inner'
// CHECK:STDOUT:   │ │ │ ╭─VarBindingPattern ':'
// CHECK:STDOUT:   │ │ ├─VariablePattern 'var'
// CHECK:STDOUT:   │ ├─VariableDecl ';'
// CHECK:STDOUT:   ├─ClassDefinition '}'
// CHECK:STDOUT:   │   ╭─FunctionIntroducer 'fn'
// CHECK:STDOUT:   │   ├─IdentifierNameMaybeBeforeSignature 'F'
// CHECK:STDOUT:   │   │ ╭─ExplicitParamListStart '('
// CHECK:STDOUT:   │   ├─ExplicitParamList ')'
// CHECK:STDOUT:   │ ╭─FunctionDefinitionStart '{'
// CHECK:STDOUT:   │ │   ╭─UnionIntroducer 'union'
// CHECK:STDOUT:   │ │   ├─IdentifierNameNotBeforeSignature 'Local'
// CHECK:STDOUT:   │ │ ╭─UnionDefinitionStart '{'
// CHECK:STDOUT:   │ │ │ ╭─VariableIntroducer 'var'
// CHECK:STDOUT:   │ │ │ │   ╭─IdentifierNameNotBeforeSignature 'b'
// CHECK:STDOUT:   │ │ │ │   ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │ │ │ │   ├─IntTypeLiteral 'i64'
// CHECK:STDOUT:   │ │ │ │ ╭─VarBindingPattern ':'
// CHECK:STDOUT:   │ │ │ ├─VariablePattern 'var'
// CHECK:STDOUT:   │ │ ├─VariableDecl ';'
// CHECK:STDOUT:   │ ├─UnionDefinition '}'
// CHECK:STDOUT:   ├─FunctionDefinition '}'
// CHECK:STDOUT:   ├─FileEnd ''
// CHECK:STDOUT:   (root)
