// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/parse/testdata/union/fail_members.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/parse/testdata/union/fail_members.carbon

// Each excluded member sits on its own indented line so that recovery
// (`SkipPastLikelyEnd`) consumes only that member and the union's `}` still
// closes the tree.

// --- fail_nested_class.carbon

union U {
  var a: i32;
  // CHECK:STDERR: fail_nested_class.carbon:[[@LINE+4]]:3: error: unrecognized declaration introducer [UnrecognizedDecl]
  // CHECK:STDERR:   class C {}
  // CHECK:STDERR:   ^~~~~
  // CHECK:STDERR:
  class C {}
}

// --- fail_nested_choice.carbon

union U {
  var a: i32;
  // CHECK:STDERR: fail_nested_choice.carbon:[[@LINE+4]]:3: error: unrecognized declaration introducer [UnrecognizedDecl]
  // CHECK:STDERR:   choice C { X }
  // CHECK:STDERR:   ^~~~~~
  // CHECK:STDERR:
  choice C { X }
}

// --- fail_nested_union.carbon

union U {
  var a: i32;
  // CHECK:STDERR: fail_nested_union.carbon:[[@LINE+4]]:3: error: unrecognized declaration introducer [UnrecognizedDecl]
  // CHECK:STDERR:   union Inner { var b: i32; }
  // CHECK:STDERR:   ^~~~~
  // CHECK:STDERR:
  union Inner { var b: i32; }
}

// --- fail_adapt.carbon

union U {
  var a: i32;
  // CHECK:STDERR: fail_adapt.carbon:[[@LINE+4]]:3: error: unrecognized declaration introducer [UnrecognizedDecl]
  // CHECK:STDERR:   adapt i32;
  // CHECK:STDERR:   ^~~~~
  // CHECK:STDERR:
  adapt i32;
}

// --- fail_base.carbon

base class B {}

union U {
  var a: i32;
  // CHECK:STDERR: fail_base.carbon:[[@LINE+4]]:10: error: unrecognized declaration introducer [UnrecognizedDecl]
  // CHECK:STDERR:   extend base: B;
  // CHECK:STDERR:          ^~~~
  // CHECK:STDERR:
  extend base: B;
}

// --- fail_interface.carbon

union U {
  var a: i32;
  // CHECK:STDERR: fail_interface.carbon:[[@LINE+4]]:3: error: unrecognized declaration introducer [UnrecognizedDecl]
  // CHECK:STDERR:   interface I {}
  // CHECK:STDERR:   ^~~~~~~~~
  // CHECK:STDERR:
  interface I {}
}

// CHECK:STDOUT: - filename: fail_nested_class.carbon
// CHECK:STDOUT:   ╭─FileStart ''
// CHECK:STDOUT:   │   ╭─UnionIntroducer 'union'
// CHECK:STDOUT:   │   ├─IdentifierNameNotBeforeSignature 'U'
// CHECK:STDOUT:   │ ╭─UnionDefinitionStart '{'
// CHECK:STDOUT:   │ │ ╭─VariableIntroducer 'var'
// CHECK:STDOUT:   │ │ │   ╭─IdentifierNameNotBeforeSignature 'a'
// CHECK:STDOUT:   │ │ │   ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │ │ │   ├─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │ │ │ ╭─VarBindingPattern ':'
// CHECK:STDOUT:   │ │ ├─VariablePattern 'var'
// CHECK:STDOUT:   │ ├─VariableDecl ';'
// CHECK:STDOUT:   │ │ ╭─InvalidParseStart 'class' has_error
// CHECK:STDOUT:   │ ├─InvalidParseSubtree '}' has_error
// CHECK:STDOUT:   ├─UnionDefinition '}'
// CHECK:STDOUT:   ├─FileEnd ''
// CHECK:STDOUT:   (root)
// CHECK:STDOUT: - filename: fail_nested_choice.carbon
// CHECK:STDOUT:   ╭─FileStart ''
// CHECK:STDOUT:   │   ╭─UnionIntroducer 'union'
// CHECK:STDOUT:   │   ├─IdentifierNameNotBeforeSignature 'U'
// CHECK:STDOUT:   │ ╭─UnionDefinitionStart '{'
// CHECK:STDOUT:   │ │ ╭─VariableIntroducer 'var'
// CHECK:STDOUT:   │ │ │   ╭─IdentifierNameNotBeforeSignature 'a'
// CHECK:STDOUT:   │ │ │   ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │ │ │   ├─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │ │ │ ╭─VarBindingPattern ':'
// CHECK:STDOUT:   │ │ ├─VariablePattern 'var'
// CHECK:STDOUT:   │ ├─VariableDecl ';'
// CHECK:STDOUT:   │ │ ╭─InvalidParseStart 'choice' has_error
// CHECK:STDOUT:   │ ├─InvalidParseSubtree '}' has_error
// CHECK:STDOUT:   ├─UnionDefinition '}'
// CHECK:STDOUT:   ├─FileEnd ''
// CHECK:STDOUT:   (root)
// CHECK:STDOUT: - filename: fail_nested_union.carbon
// CHECK:STDOUT:   ╭─FileStart ''
// CHECK:STDOUT:   │   ╭─UnionIntroducer 'union'
// CHECK:STDOUT:   │   ├─IdentifierNameNotBeforeSignature 'U'
// CHECK:STDOUT:   │ ╭─UnionDefinitionStart '{'
// CHECK:STDOUT:   │ │ ╭─VariableIntroducer 'var'
// CHECK:STDOUT:   │ │ │   ╭─IdentifierNameNotBeforeSignature 'a'
// CHECK:STDOUT:   │ │ │   ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │ │ │   ├─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │ │ │ ╭─VarBindingPattern ':'
// CHECK:STDOUT:   │ │ ├─VariablePattern 'var'
// CHECK:STDOUT:   │ ├─VariableDecl ';'
// CHECK:STDOUT:   │ │ ╭─InvalidParseStart 'union' has_error
// CHECK:STDOUT:   │ ├─InvalidParseSubtree '}' has_error
// CHECK:STDOUT:   ├─UnionDefinition '}'
// CHECK:STDOUT:   ├─FileEnd ''
// CHECK:STDOUT:   (root)
// CHECK:STDOUT: - filename: fail_adapt.carbon
// CHECK:STDOUT:   ╭─FileStart ''
// CHECK:STDOUT:   │   ╭─UnionIntroducer 'union'
// CHECK:STDOUT:   │   ├─IdentifierNameNotBeforeSignature 'U'
// CHECK:STDOUT:   │ ╭─UnionDefinitionStart '{'
// CHECK:STDOUT:   │ │ ╭─VariableIntroducer 'var'
// CHECK:STDOUT:   │ │ │   ╭─IdentifierNameNotBeforeSignature 'a'
// CHECK:STDOUT:   │ │ │   ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │ │ │   ├─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │ │ │ ╭─VarBindingPattern ':'
// CHECK:STDOUT:   │ │ ├─VariablePattern 'var'
// CHECK:STDOUT:   │ ├─VariableDecl ';'
// CHECK:STDOUT:   │ │ ╭─InvalidParseStart 'adapt' has_error
// CHECK:STDOUT:   │ ├─InvalidParseSubtree ';' has_error
// CHECK:STDOUT:   ├─UnionDefinition '}'
// CHECK:STDOUT:   ├─FileEnd ''
// CHECK:STDOUT:   (root)
// CHECK:STDOUT: - filename: fail_base.carbon
// CHECK:STDOUT:   ╭─FileStart ''
// CHECK:STDOUT:   │   ╭─ClassIntroducer 'class'
// CHECK:STDOUT:   │   ├─BaseModifier 'base'
// CHECK:STDOUT:   │   ├─IdentifierNameNotBeforeSignature 'B'
// CHECK:STDOUT:   │ ╭─ClassDefinitionStart '{'
// CHECK:STDOUT:   ├─ClassDefinition '}'
// CHECK:STDOUT:   │   ╭─UnionIntroducer 'union'
// CHECK:STDOUT:   │   ├─IdentifierNameNotBeforeSignature 'U'
// CHECK:STDOUT:   │ ╭─UnionDefinitionStart '{'
// CHECK:STDOUT:   │ │ ╭─VariableIntroducer 'var'
// CHECK:STDOUT:   │ │ │   ╭─IdentifierNameNotBeforeSignature 'a'
// CHECK:STDOUT:   │ │ │   ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │ │ │   ├─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │ │ │ ╭─VarBindingPattern ':'
// CHECK:STDOUT:   │ │ ├─VariablePattern 'var'
// CHECK:STDOUT:   │ ├─VariableDecl ';'
// CHECK:STDOUT:   │ │ ╭─InvalidParseStart 'base' has_error
// CHECK:STDOUT:   │ │ ├─ExtendModifier 'extend'
// CHECK:STDOUT:   │ ├─InvalidParseSubtree ';' has_error
// CHECK:STDOUT:   ├─UnionDefinition '}'
// CHECK:STDOUT:   ├─FileEnd ''
// CHECK:STDOUT:   (root)
// CHECK:STDOUT: - filename: fail_interface.carbon
// CHECK:STDOUT:   ╭─FileStart ''
// CHECK:STDOUT:   │   ╭─UnionIntroducer 'union'
// CHECK:STDOUT:   │   ├─IdentifierNameNotBeforeSignature 'U'
// CHECK:STDOUT:   │ ╭─UnionDefinitionStart '{'
// CHECK:STDOUT:   │ │ ╭─VariableIntroducer 'var'
// CHECK:STDOUT:   │ │ │   ╭─IdentifierNameNotBeforeSignature 'a'
// CHECK:STDOUT:   │ │ │   ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │ │ │   ├─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │ │ │ ╭─VarBindingPattern ':'
// CHECK:STDOUT:   │ │ ├─VariablePattern 'var'
// CHECK:STDOUT:   │ ├─VariableDecl ';'
// CHECK:STDOUT:   │ │ ╭─InvalidParseStart 'interface' has_error
// CHECK:STDOUT:   │ ├─InvalidParseSubtree '}' has_error
// CHECK:STDOUT:   ├─UnionDefinition '}'
// CHECK:STDOUT:   ├─FileEnd ''
// CHECK:STDOUT:   (root)
