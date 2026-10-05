// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --dump-cpp-ast
// SET-CHECK-SUBSET
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/function/export/overload_set_ast.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/function/export/overload_set_ast.carbon
// CHECK:STDOUT: TranslationUnitDecl {{0x[a-f0-9]+}} <<invalid sloc>> <invalid sloc>
// CHECK:STDOUT: |-EmptyDecl {{0x[a-f0-9]+}} <<carbon Cpp imports>:1:1> col:1
// CHECK:STDOUT: |-NamespaceDecl {{0x[a-f0-9]+}} <<invalid sloc>> <invalid sloc> referenced Carbon external-linkage

// The C++ AST an exported Carbon `overload fn` set produces (fork decision
// F-009; fork/overload/plan.md OV-3): C++ name lookup receives one declaration
// per member under the shared name — two `FunctionDecl`s in `namespace
// Carbon`, or two `CXXMethodDecl`s of the exported class, lvalue-ref-qualified
// (`&`) for `ref self` members — each an inline function whose body calls the
// member's own Carbon thunk (`F__carbon_thunk`, two same-named declarations
// told apart by their parameter types and by the asm labels
// `_CF__carbon_thunk:overload<N>...`). The sibling `overload_set.carbon` pins
// the Carbon side's selections; this file pins what Clang is handed.

// --- overload_set.carbon

library "[[@TEST_NAME]]";

import Cpp;

overload fn F(unused x: i64) -> i32 { return 1; }
// CHECK:STDOUT: | |-FunctionDecl {{0x[a-f0-9]+}} <overload_set.carbon:[[@LINE-1]]:37> col:37 used F 'int (long)' inline internal-linkage
// CHECK:STDOUT: | | |-ParmVarDecl {{0x[a-f0-9]+}} <col:37> col:37 used 'long'
// CHECK:STDOUT: | | |-CompoundStmt {{0x[a-f0-9]+}} <col:37>
// CHECK:STDOUT: | | | |-DeclStmt {{0x[a-f0-9]+}} <col:37>
// CHECK:STDOUT: | | | | `-VarDecl {{0x[a-f0-9]+}} <col:37> col:37 used return_storage 'int' nrvo
// CHECK:STDOUT: | | | |-CallExpr {{0x[a-f0-9]+}} <col:37> 'void'
// CHECK:STDOUT: | | | | |-ImplicitCastExpr {{0x[a-f0-9]+}} <col:37> 'void (*)(const long &, const int &)' <FunctionToPointerDecay>
// CHECK:STDOUT: | | | | | `-DeclRefExpr {{0x[a-f0-9]+}} <col:37> 'void (const long &, const int &)' Function {{0x[a-f0-9]+}} 'F__carbon_thunk' 'void (const long &, const int &)'
// CHECK:STDOUT: | | | | |-ImplicitCastExpr {{0x[a-f0-9]+}} <col:37> 'const long' lvalue <NoOp>
// CHECK:STDOUT: | | | | | `-DeclRefExpr {{0x[a-f0-9]+}} <col:37> 'long' lvalue ParmVar {{0x[a-f0-9]+}} depth 0 index 0 'long'
// CHECK:STDOUT: | | | | `-ImplicitCastExpr {{0x[a-f0-9]+}} <col:37> 'const int' lvalue <NoOp>
// CHECK:STDOUT: | | | |   `-DeclRefExpr {{0x[a-f0-9]+}} <col:37> 'int' lvalue Var {{0x[a-f0-9]+}} 'return_storage' 'int'
// CHECK:STDOUT: | | | `-ReturnStmt {{0x[a-f0-9]+}} <col:37> nrvo_candidate(Var {{0x[a-f0-9]+}} 'return_storage' 'int')
// CHECK:STDOUT: | | |   `-DeclRefExpr {{0x[a-f0-9]+}} <col:37> 'int' lvalue Var {{0x[a-f0-9]+}} 'return_storage' 'int'
// CHECK:STDOUT: | | |-AlwaysInlineAttr {{0x[a-f0-9]+}} <<invalid sloc>> Implicit always_inline
// CHECK:STDOUT: | | `-InternalLinkageAttr {{0x[a-f0-9]+}} <<invalid sloc>> Implicit
// CHECK:STDOUT: | `-FunctionDecl {{0x[a-f0-9]+}} <line:102:38> col:38 used F 'int (bool)' inline internal-linkage
// CHECK:STDOUT: |   |-ParmVarDecl {{0x[a-f0-9]+}} <col:38> col:38 used 'bool'
// CHECK:STDOUT: |   |-CompoundStmt {{0x[a-f0-9]+}} <col:38>
// CHECK:STDOUT: |   | |-DeclStmt {{0x[a-f0-9]+}} <col:38>
// CHECK:STDOUT: |   | | `-VarDecl {{0x[a-f0-9]+}} <col:38> col:38 used return_storage 'int' nrvo
// CHECK:STDOUT: |   | |-CallExpr {{0x[a-f0-9]+}} <col:38> 'void'
// CHECK:STDOUT: |   | | |-ImplicitCastExpr {{0x[a-f0-9]+}} <col:38> 'void (*)(const bool &, const int &)' <FunctionToPointerDecay>
// CHECK:STDOUT: |   | | | `-DeclRefExpr {{0x[a-f0-9]+}} <col:38> 'void (const bool &, const int &)' Function {{0x[a-f0-9]+}} 'F__carbon_thunk' 'void (const bool &, const int &)'
// CHECK:STDOUT: |   | | |-ImplicitCastExpr {{0x[a-f0-9]+}} <col:38> 'const bool' lvalue <NoOp>
// CHECK:STDOUT: |   | | | `-DeclRefExpr {{0x[a-f0-9]+}} <col:38> 'bool' lvalue ParmVar {{0x[a-f0-9]+}} depth 0 index 0 'bool'
// CHECK:STDOUT: |   | | `-ImplicitCastExpr {{0x[a-f0-9]+}} <col:38> 'const int' lvalue <NoOp>
// CHECK:STDOUT: |   | |   `-DeclRefExpr {{0x[a-f0-9]+}} <col:38> 'int' lvalue Var {{0x[a-f0-9]+}} 'return_storage' 'int'
// CHECK:STDOUT: |   | `-ReturnStmt {{0x[a-f0-9]+}} <col:38> nrvo_candidate(Var {{0x[a-f0-9]+}} 'return_storage' 'int')
// CHECK:STDOUT: |   |   `-DeclRefExpr {{0x[a-f0-9]+}} <col:38> 'int' lvalue Var {{0x[a-f0-9]+}} 'return_storage' 'int'
// CHECK:STDOUT: |   |-AlwaysInlineAttr {{0x[a-f0-9]+}} <<invalid sloc>> Implicit always_inline
// CHECK:STDOUT: |   `-InternalLinkageAttr {{0x[a-f0-9]+}} <<invalid sloc>> Implicit
// CHECK:STDOUT: |-FunctionDecl {{0x[a-f0-9]+}} <line:105:1, col:49> col:12 in overload_set.carbon hidden used CallBool 'int ()' inline external-linkage
// CHECK:STDOUT: | `-CompoundStmt {{0x[a-f0-9]+}} <col:23, col:49>
// CHECK:STDOUT: |   `-ReturnStmt {{0x[a-f0-9]+}} <col:25, col:46>
// CHECK:STDOUT: |     `-CallExpr {{0x[a-f0-9]+}} <col:32, col:46> 'int'
// CHECK:STDOUT: |       |-ImplicitCastExpr {{0x[a-f0-9]+}} <col:32, col:40> 'int (*)(bool)' <FunctionToPointerDecay>
// CHECK:STDOUT: |       | `-DeclRefExpr {{0x[a-f0-9]+}} <col:32, col:40> 'int (bool)' lvalue Function {{0x[a-f0-9]+}} 'F' 'int (bool)'
// CHECK:STDOUT: |       |   `-NestedNameSpecifier Namespace {{0x[a-f0-9]+}} 'Carbon'
// CHECK:STDOUT: |       `-CXXBoolLiteralExpr {{0x[a-f0-9]+}} <col:42> 'bool' true
// CHECK:STDOUT: |-FunctionDecl {{0x[a-f0-9]+}} <line:106:1, col:51> col:12 in overload_set.carbon hidden used CallWithLong 'int ()' inline external-linkage
// CHECK:STDOUT: | `-CompoundStmt {{0x[a-f0-9]+}} <col:27, col:51>
// CHECK:STDOUT: |   `-ReturnStmt {{0x[a-f0-9]+}} <col:29, col:48>
// CHECK:STDOUT: |     `-CallExpr {{0x[a-f0-9]+}} <col:36, col:48> 'int'
// CHECK:STDOUT: |       |-ImplicitCastExpr {{0x[a-f0-9]+}} <col:36, col:44> 'int (*)(long)' <FunctionToPointerDecay>
// CHECK:STDOUT: |       | `-DeclRefExpr {{0x[a-f0-9]+}} <col:36, col:44> 'int (long)' lvalue Function {{0x[a-f0-9]+}} 'F' 'int (long)'
// CHECK:STDOUT: |       |   `-NestedNameSpecifier Namespace {{0x[a-f0-9]+}} 'Carbon'
// CHECK:STDOUT: |       `-IntegerLiteral {{0x[a-f0-9]+}} <col:46> 'long' 7
// CHECK:STDOUT: |-FunctionDecl {{0x[a-f0-9]+}} <line:105:12> col:12 in overload_set.carbon hidden CallBool__carbon_thunk 'int () noexcept' inline internal-linkage
// CHECK:STDOUT: | |-CXXTryStmt {{0x[a-f0-9]+}} <col:12>
// CHECK:STDOUT: | | |-CompoundStmt {{0x[a-f0-9]+}} <col:12>
// CHECK:STDOUT: | | | `-ReturnStmt {{0x[a-f0-9]+}} <col:12>
// CHECK:STDOUT: | | |   `-CallExpr {{0x[a-f0-9]+}} <col:12> 'int'
// CHECK:STDOUT: | | |     `-ImplicitCastExpr {{0x[a-f0-9]+}} <col:12> 'int (*)()' <FunctionToPointerDecay>
// CHECK:STDOUT: | | |       `-DeclRefExpr {{0x[a-f0-9]+}} <col:12> 'int ()' Function {{0x[a-f0-9]+}} 'CallBool' 'int ()'
// CHECK:STDOUT: | | `-CXXCatchStmt {{0x[a-f0-9]+}} <col:12>
// CHECK:STDOUT: | |   |-<<<NULL>>>
// CHECK:STDOUT: | |   `-CompoundStmt {{0x[a-f0-9]+}} <col:12>
// CHECK:STDOUT: | |     |-CallExpr {{0x[a-f0-9]+}} <col:12> 'long'
// CHECK:STDOUT: | |     | |-IntegerLiteral {{0x[a-f0-9]+}} <col:12> 'int' 2
// CHECK:STDOUT: | |     | |-ImplicitCastExpr {{0x[a-f0-9]+}} <col:12> 'const void *' <BitCast>
// CHECK:STDOUT: | |     | | `-ImplicitCastExpr {{0x[a-f0-9]+}} <col:12> 'const char *' <ArrayToPointerDecay>
// CHECK:STDOUT: | |     | |   `-StringLiteral {{0x[a-f0-9]+}} <col:12> 'const char[75]' lvalue "carbon: C++ exception escaped into Carbon through `CallBool`; terminating\n"
// CHECK:STDOUT: | |     |   `-IntegerLiteral {{0x[a-f0-9]+}} <col:12> 'int' 74
// CHECK:STDOUT: | |     `-CXXThrowExpr {{0x[a-f0-9]+}} <col:12> 'void'
// CHECK:STDOUT: | |-AlwaysInlineAttr {{0x[a-f0-9]+}} <<invalid sloc>> Implicit always_inline
// CHECK:STDOUT: | |-InternalLinkageAttr {{0x[a-f0-9]+}} <<invalid sloc>> Implicit
// CHECK:STDOUT: | `-AsmLabelAttr {{0x[a-f0-9]+}} <col:12> Implicit "_Z8CallBoolv.carbon_thunk."
// CHECK:STDOUT: | |-ParmVarDecl {{0x[a-f0-9]+}} <col:12> col:12 in overload_set.carbon hidden 'int'
// CHECK:STDOUT: | |-ParmVarDecl {{0x[a-f0-9]+}} <col:12> col:12 in overload_set.carbon hidden 'const void *'
// CHECK:STDOUT: | `-AsmLabelAttr {{0x[a-f0-9]+}} <col:12> Implicit "write"
// CHECK:STDOUT: |-FunctionDecl {{0x[a-f0-9]+}} <line:106:12> col:12 in overload_set.carbon hidden CallWithLong__carbon_thunk 'int () noexcept' inline internal-linkage
// CHECK:STDOUT: | |-CXXTryStmt {{0x[a-f0-9]+}} <col:12>
// CHECK:STDOUT: | | |-CompoundStmt {{0x[a-f0-9]+}} <col:12>
// CHECK:STDOUT: | | | `-ReturnStmt {{0x[a-f0-9]+}} <col:12>
// CHECK:STDOUT: | | |   `-CallExpr {{0x[a-f0-9]+}} <col:12> 'int'
// CHECK:STDOUT: | | |     `-ImplicitCastExpr {{0x[a-f0-9]+}} <col:12> 'int (*)()' <FunctionToPointerDecay>
// CHECK:STDOUT: | | |       `-DeclRefExpr {{0x[a-f0-9]+}} <col:12> 'int ()' Function {{0x[a-f0-9]+}} 'CallWithLong' 'int ()'
// CHECK:STDOUT: | | `-CXXCatchStmt {{0x[a-f0-9]+}} <col:12>
// CHECK:STDOUT: | |   |-<<<NULL>>>
// CHECK:STDOUT: | |   `-CompoundStmt {{0x[a-f0-9]+}} <col:12>
// CHECK:STDOUT: | |     |-CallExpr {{0x[a-f0-9]+}} <col:12> 'long'
// CHECK:STDOUT: | |     | |-IntegerLiteral {{0x[a-f0-9]+}} <col:12> 'int' 2
// CHECK:STDOUT: | |     | |-ImplicitCastExpr {{0x[a-f0-9]+}} <col:12> 'const void *' <BitCast>
// CHECK:STDOUT: | |     | | `-ImplicitCastExpr {{0x[a-f0-9]+}} <col:12> 'const char *' <ArrayToPointerDecay>
// CHECK:STDOUT: | |     | |   `-StringLiteral {{0x[a-f0-9]+}} <col:12> 'const char[79]' lvalue "carbon: C++ exception escaped into Carbon through `CallWithLong`; terminating\n"
// CHECK:STDOUT: | |     |   `-IntegerLiteral {{0x[a-f0-9]+}} <col:12> 'int' 78
// CHECK:STDOUT: | |     `-CXXThrowExpr {{0x[a-f0-9]+}} <col:12> 'void'
// CHECK:STDOUT: | |-AlwaysInlineAttr {{0x[a-f0-9]+}} <<invalid sloc>> Implicit always_inline
// CHECK:STDOUT: | |-InternalLinkageAttr {{0x[a-f0-9]+}} <<invalid sloc>> Implicit
// CHECK:STDOUT: | `-AsmLabelAttr {{0x[a-f0-9]+}} <col:12> Implicit "_Z12CallWithLongv.carbon_thunk."
// CHECK:STDOUT: `-ImportDecl {{0x[a-f0-9]+}} <line:109:64> col:64 in overload_set.carbon implicit overload_set.carbon
// CHECK:STDOUT: TranslationUnitDecl {{0x[a-f0-9]+}} <<invalid sloc>> <invalid sloc>
// CHECK:STDOUT: |-EmptyDecl {{0x[a-f0-9]+}} <<carbon Cpp imports>:1:1> col:1
// CHECK:STDOUT: |-NamespaceDecl {{0x[a-f0-9]+}} <<invalid sloc>> <invalid sloc> referenced Carbon external-linkage
overload fn F(unused b: bool) -> i32 { return 2; }

inline Cpp '''
inline int CallBool() { return Carbon::F(true); }
inline int CallWithLong() { return Carbon::F(7L); }
''';

fn Use() -> i32 { return Cpp.CallBool() + Cpp.CallWithLong(); }

// --- method_set.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Acc {
// CHECK:STDOUT: | `-CXXRecordDecl {{0x[a-f0-9]+}} <method_set.carbon:[[@LINE-1]]:11> col:11 <undeserialized declarations> class Acc definition external-linkage
// CHECK:STDOUT: |   |-DefinitionData pass_in_registers aggregate standard_layout trivially_copyable pod trivial literal has_mutable_fields can_const_default_init
// CHECK:STDOUT: |   | |-DefaultConstructor exists trivial needs_implicit
// CHECK:STDOUT: |   | |-CopyConstructor simple trivial has_const_param needs_implicit implicit_has_const_param
// CHECK:STDOUT: |   | |-MoveConstructor exists simple trivial needs_implicit
// CHECK:STDOUT: |   | |-CopyAssignment simple trivial has_const_param needs_implicit implicit_has_const_param
// CHECK:STDOUT: |   | |-MoveAssignment exists simple trivial needs_implicit
// CHECK:STDOUT: |   | `-Destructor simple irrelevant trivial
// CHECK:STDOUT: |   |-FinalAttr {{0x[a-f0-9]+}} <col:11> final
// CHECK:STDOUT: |   |-FieldDecl {{0x[a-f0-9]+}} <line:117:12> col:12 total 'int' mutable
// CHECK:STDOUT: |   |-CXXMethodDecl {{0x[a-f0-9]+}} <line:118:20> col:20 used Make 'Carbon::Acc ()' static inline internal-linkage
// CHECK:STDOUT: |   | |-CompoundStmt {{0x[a-f0-9]+}} <col:20>
// CHECK:STDOUT: |   | | |-DeclStmt {{0x[a-f0-9]+}} <col:20>
// CHECK:STDOUT: |   | | | `-VarDecl {{0x[a-f0-9]+}} <col:20> col:20 used return_storage 'Carbon::Acc' nrvo
// CHECK:STDOUT: |   | | |-CallExpr {{0x[a-f0-9]+}} <col:20> 'void'
// CHECK:STDOUT: |   | | | |-ImplicitCastExpr {{0x[a-f0-9]+}} <col:20> 'void (*)(const Carbon::Acc &)' <FunctionToPointerDecay>
// CHECK:STDOUT: |   | | | | `-DeclRefExpr {{0x[a-f0-9]+}} <col:20> 'void (const Carbon::Acc &)' Function {{0x[a-f0-9]+}} 'Make__carbon_thunk' 'void (const Carbon::Acc &)'
// CHECK:STDOUT: |   | | | `-ImplicitCastExpr {{0x[a-f0-9]+}} <col:20> 'const Carbon::Acc' lvalue <NoOp>
// CHECK:STDOUT: |   | | |   `-DeclRefExpr {{0x[a-f0-9]+}} <col:20> 'Carbon::Acc' lvalue Var {{0x[a-f0-9]+}} 'return_storage' 'Carbon::Acc'
// CHECK:STDOUT: |   | | `-ReturnStmt {{0x[a-f0-9]+}} <col:20> nrvo_candidate(Var {{0x[a-f0-9]+}} 'return_storage' 'Carbon::Acc')
// CHECK:STDOUT: |   | |   `-DeclRefExpr {{0x[a-f0-9]+}} <col:20> 'Carbon::Acc' lvalue Var {{0x[a-f0-9]+}} 'return_storage' 'Carbon::Acc'
// CHECK:STDOUT: |   | |-AlwaysInlineAttr {{0x[a-f0-9]+}} <<invalid sloc>> Implicit always_inline
// CHECK:STDOUT: |   | `-InternalLinkageAttr {{0x[a-f0-9]+}} <<invalid sloc>> Implicit
// CHECK:STDOUT: |   |-CXXDestructorDecl {{0x[a-f0-9]+}} <line:6:11> col:11 implicit referenced ~Acc 'void () noexcept' inline default trivial external-linkage
// CHECK:STDOUT: |   |-CXXMethodDecl {{0x[a-f0-9]+}} <line:119:37> col:37 used Add 'void (int) &' inline internal-linkage
// CHECK:STDOUT: |   | |-ParmVarDecl {{0x[a-f0-9]+}} <col:37> col:37 used 'int'
// CHECK:STDOUT: |   | |-CompoundStmt {{0x[a-f0-9]+}} <col:37>
// CHECK:STDOUT: |   | | `-CallExpr {{0x[a-f0-9]+}} <col:37> 'void'
// CHECK:STDOUT: |   | |   |-ImplicitCastExpr {{0x[a-f0-9]+}} <col:37> 'void (*)(const Carbon::Acc &, const int &)' <FunctionToPointerDecay>
// CHECK:STDOUT: |   | |   | `-DeclRefExpr {{0x[a-f0-9]+}} <col:37> 'void (const Carbon::Acc &, const int &)' Function {{0x[a-f0-9]+}} 'Add__carbon_thunk' 'void (const Carbon::Acc &, const int &)'
// CHECK:STDOUT: |   | |   |-ImplicitCastExpr {{0x[a-f0-9]+}} <col:37> 'const Carbon::Acc' lvalue <NoOp>
// CHECK:STDOUT: |   | |   | `-UnaryOperator {{0x[a-f0-9]+}} <col:37> 'Carbon::Acc' lvalue prefix '*' cannot overflow
// CHECK:STDOUT: |   | |   |   `-CXXThisExpr {{0x[a-f0-9]+}} <col:37> 'Carbon::Acc *' implicit this
// CHECK:STDOUT: |   | |   `-ImplicitCastExpr {{0x[a-f0-9]+}} <col:37> 'const int' lvalue <NoOp>
// CHECK:STDOUT: |   | |     `-DeclRefExpr {{0x[a-f0-9]+}} <col:37> 'int' lvalue ParmVar {{0x[a-f0-9]+}} depth 0 index 0 'int'
// CHECK:STDOUT: |   | |-AlwaysInlineAttr {{0x[a-f0-9]+}} <<invalid sloc>> Implicit always_inline
// CHECK:STDOUT: |   | `-InternalLinkageAttr {{0x[a-f0-9]+}} <<invalid sloc>> Implicit
// CHECK:STDOUT: |   |-CXXMethodDecl {{0x[a-f0-9]+}} <line:120:41> col:41 used Add 'void (bool) &' inline internal-linkage
// CHECK:STDOUT: |   | |-ParmVarDecl {{0x[a-f0-9]+}} <col:41> col:41 used 'bool'
// CHECK:STDOUT: |   | |-CompoundStmt {{0x[a-f0-9]+}} <col:41>
// CHECK:STDOUT: |   | | `-CallExpr {{0x[a-f0-9]+}} <col:41> 'void'
// CHECK:STDOUT: |   | |   |-ImplicitCastExpr {{0x[a-f0-9]+}} <col:41> 'void (*)(const Carbon::Acc &, const bool &)' <FunctionToPointerDecay>
// CHECK:STDOUT: |   | |   | `-DeclRefExpr {{0x[a-f0-9]+}} <col:41> 'void (const Carbon::Acc &, const bool &)' Function {{0x[a-f0-9]+}} 'Add__carbon_thunk' 'void (const Carbon::Acc &, const bool &)'
// CHECK:STDOUT: |   | |   |-ImplicitCastExpr {{0x[a-f0-9]+}} <col:41> 'const Carbon::Acc' lvalue <NoOp>
// CHECK:STDOUT: |   | |   | `-UnaryOperator {{0x[a-f0-9]+}} <col:41> 'Carbon::Acc' lvalue prefix '*' cannot overflow
// CHECK:STDOUT: |   | |   |   `-CXXThisExpr {{0x[a-f0-9]+}} <col:41> 'Carbon::Acc *' implicit this
// CHECK:STDOUT: |   | |   `-ImplicitCastExpr {{0x[a-f0-9]+}} <col:41> 'const bool' lvalue <NoOp>
// CHECK:STDOUT: |   | |     `-DeclRefExpr {{0x[a-f0-9]+}} <col:41> 'bool' lvalue ParmVar {{0x[a-f0-9]+}} depth 0 index 0 'bool'
// CHECK:STDOUT: |   | |-AlwaysInlineAttr {{0x[a-f0-9]+}} <<invalid sloc>> Implicit always_inline
// CHECK:STDOUT: |   | `-InternalLinkageAttr {{0x[a-f0-9]+}} <<invalid sloc>> Implicit
// CHECK:STDOUT: |   `-CXXMethodDecl {{0x[a-f0-9]+}} <line:123:23> col:23 used Get 'int () const' inline internal-linkage
// CHECK:STDOUT: |     |-CompoundStmt {{0x[a-f0-9]+}} <col:23>
// CHECK:STDOUT: |     | |-DeclStmt {{0x[a-f0-9]+}} <col:23>
// CHECK:STDOUT: |     | | `-VarDecl {{0x[a-f0-9]+}} <col:23> col:23 used return_storage 'int' nrvo
// CHECK:STDOUT: |     | |-CallExpr {{0x[a-f0-9]+}} <col:23> 'void'
// CHECK:STDOUT: |     | | |-ImplicitCastExpr {{0x[a-f0-9]+}} <col:23> 'void (*)(const Carbon::Acc &, const int &)' <FunctionToPointerDecay>
// CHECK:STDOUT: |     | | | `-DeclRefExpr {{0x[a-f0-9]+}} <col:23> 'void (const Carbon::Acc &, const int &)' Function {{0x[a-f0-9]+}} 'Get__carbon_thunk' 'void (const Carbon::Acc &, const int &)'
// CHECK:STDOUT: |     | | |-UnaryOperator {{0x[a-f0-9]+}} <col:23> 'const Carbon::Acc' lvalue prefix '*' cannot overflow
// CHECK:STDOUT: |     | | | `-CXXThisExpr {{0x[a-f0-9]+}} <col:23> 'const Carbon::Acc *' implicit this
// CHECK:STDOUT: |     | | `-ImplicitCastExpr {{0x[a-f0-9]+}} <col:23> 'const int' lvalue <NoOp>
// CHECK:STDOUT: |     | |   `-DeclRefExpr {{0x[a-f0-9]+}} <col:23> 'int' lvalue Var {{0x[a-f0-9]+}} 'return_storage' 'int'
// CHECK:STDOUT: |     | `-ReturnStmt {{0x[a-f0-9]+}} <col:23> nrvo_candidate(Var {{0x[a-f0-9]+}} 'return_storage' 'int')
// CHECK:STDOUT: |     |   `-DeclRefExpr {{0x[a-f0-9]+}} <col:23> 'int' lvalue Var {{0x[a-f0-9]+}} 'return_storage' 'int'
// CHECK:STDOUT: |     |-AlwaysInlineAttr {{0x[a-f0-9]+}} <<invalid sloc>> Implicit always_inline
// CHECK:STDOUT: |     `-InternalLinkageAttr {{0x[a-f0-9]+}} <<invalid sloc>> Implicit
// CHECK:STDOUT: |-FunctionDecl {{0x[a-f0-9]+}} <line:127:1, line:132:1> line:127:12 in method_set.carbon hidden used Drive 'int ()' inline external-linkage
// CHECK:STDOUT: | `-CompoundStmt {{0x[a-f0-9]+}} <col:20, line:132:1>
// CHECK:STDOUT: |   |-DeclStmt {{0x[a-f0-9]+}} <line:128:3, col:31>
// CHECK:STDOUT: |   | `-VarDecl {{0x[a-f0-9]+}} <col:3, col:30> col:8 in method_set.carbon hidden used a 'Carbon::Acc' cinit
// CHECK:STDOUT: |   |   `-CallExpr {{0x[a-f0-9]+}} <col:12, col:30> 'Carbon::Acc'
// CHECK:STDOUT: |   |     `-ImplicitCastExpr {{0x[a-f0-9]+}} <col:12, col:25> 'Carbon::Acc (*)()' <FunctionToPointerDecay>
// CHECK:STDOUT: |   |       `-DeclRefExpr {{0x[a-f0-9]+}} <col:12, col:25> 'Carbon::Acc ()' lvalue CXXMethod {{0x[a-f0-9]+}} 'Make' 'Carbon::Acc ()'
// CHECK:STDOUT: |   |         `-NestedNameSpecifier TypeSpec 'Carbon::Acc'
// CHECK:STDOUT: |   |-CXXMemberCallExpr {{0x[a-f0-9]+}} <line:129:3, col:10> 'void'
// CHECK:STDOUT: |   | |-MemberExpr {{0x[a-f0-9]+}} <col:3, col:5> '<bound member function type>' .Add 0x7f5b79a99308
// CHECK:STDOUT: |   | | `-DeclRefExpr {{0x[a-f0-9]+}} <col:3> 'Carbon::Acc' lvalue Var {{0x[a-f0-9]+}} 'a' 'Carbon::Acc'
// CHECK:STDOUT: |   | `-IntegerLiteral {{0x[a-f0-9]+}} <col:9> 'int' 1
// CHECK:STDOUT: |   |-CXXMemberCallExpr {{0x[a-f0-9]+}} <line:130:3, col:13> 'void'
// CHECK:STDOUT: |   | |-MemberExpr {{0x[a-f0-9]+}} <col:3, col:5> '<bound member function type>' .Add 0x7f5b79a99a08
// CHECK:STDOUT: |   | | `-DeclRefExpr {{0x[a-f0-9]+}} <col:3> 'Carbon::Acc' lvalue Var {{0x[a-f0-9]+}} 'a' 'Carbon::Acc'
// CHECK:STDOUT: |   | `-CXXBoolLiteralExpr {{0x[a-f0-9]+}} <col:9> 'bool' true
// CHECK:STDOUT: |   `-ReturnStmt {{0x[a-f0-9]+}} <line:131:3, col:16>
// CHECK:STDOUT: |     `-CXXMemberCallExpr {{0x[a-f0-9]+}} <col:10, col:16> 'int'
// CHECK:STDOUT: |       `-MemberExpr {{0x[a-f0-9]+}} <col:10, col:12> '<bound member function type>' .Get 0x7f5b79a9cbd0
// CHECK:STDOUT: |         `-ImplicitCastExpr {{0x[a-f0-9]+}} <col:10> 'const Carbon::Acc' lvalue <NoOp>
// CHECK:STDOUT: |           `-DeclRefExpr {{0x[a-f0-9]+}} <col:10> 'Carbon::Acc' lvalue Var {{0x[a-f0-9]+}} 'a' 'Carbon::Acc'
// CHECK:STDOUT: |-FunctionDecl {{0x[a-f0-9]+}} <line:127:12> col:12 in method_set.carbon hidden Drive__carbon_thunk 'int () noexcept' inline internal-linkage
// CHECK:STDOUT: | |-CXXTryStmt {{0x[a-f0-9]+}} <col:12>
// CHECK:STDOUT: | | |-CompoundStmt {{0x[a-f0-9]+}} <col:12>
// CHECK:STDOUT: | | | `-ReturnStmt {{0x[a-f0-9]+}} <col:12>
// CHECK:STDOUT: | | |   `-CallExpr {{0x[a-f0-9]+}} <col:12> 'int'
// CHECK:STDOUT: | | |     `-ImplicitCastExpr {{0x[a-f0-9]+}} <col:12> 'int (*)()' <FunctionToPointerDecay>
// CHECK:STDOUT: | | |       `-DeclRefExpr {{0x[a-f0-9]+}} <col:12> 'int ()' Function {{0x[a-f0-9]+}} 'Drive' 'int ()'
// CHECK:STDOUT: | | `-CXXCatchStmt {{0x[a-f0-9]+}} <col:12>
// CHECK:STDOUT: | |   |-<<<NULL>>>
// CHECK:STDOUT: | |   `-CompoundStmt {{0x[a-f0-9]+}} <col:12>
// CHECK:STDOUT: | |     |-CallExpr {{0x[a-f0-9]+}} <col:12> 'long'
// CHECK:STDOUT: | |     | |-IntegerLiteral {{0x[a-f0-9]+}} <col:12> 'int' 2
// CHECK:STDOUT: | |     | |-ImplicitCastExpr {{0x[a-f0-9]+}} <col:12> 'const void *' <BitCast>
// CHECK:STDOUT: | |     | | `-ImplicitCastExpr {{0x[a-f0-9]+}} <col:12> 'const char *' <ArrayToPointerDecay>
// CHECK:STDOUT: | |     | |   `-StringLiteral {{0x[a-f0-9]+}} <col:12> 'const char[72]' lvalue "carbon: C++ exception escaped into Carbon through `Drive`; terminating\n"
// CHECK:STDOUT: | |     |   `-IntegerLiteral {{0x[a-f0-9]+}} <col:12> 'int' 71
// CHECK:STDOUT: | |     `-CXXThrowExpr {{0x[a-f0-9]+}} <col:12> 'void'
// CHECK:STDOUT: | |-AlwaysInlineAttr {{0x[a-f0-9]+}} <<invalid sloc>> Implicit always_inline
// CHECK:STDOUT: | |-InternalLinkageAttr {{0x[a-f0-9]+}} <<invalid sloc>> Implicit
// CHECK:STDOUT: | `-AsmLabelAttr {{0x[a-f0-9]+}} <col:12> Implicit "_Z5Drivev.carbon_thunk."
// CHECK:STDOUT: | |-ParmVarDecl {{0x[a-f0-9]+}} <col:12> col:12 in method_set.carbon hidden 'int'
// CHECK:STDOUT: | |-ParmVarDecl {{0x[a-f0-9]+}} <col:12> col:12 in method_set.carbon hidden 'const void *'
// CHECK:STDOUT: | `-AsmLabelAttr {{0x[a-f0-9]+}} <col:12> Implicit "write"
// CHECK:STDOUT: `-ImportDecl {{0x[a-f0-9]+}} <line:135:39> col:39 in method_set.carbon implicit method_set.carbon
  var total: i32;
  fn Make() -> Acc { return {.total = 0}; }
  overload fn Add(ref self, x: i32) { self.total = self.total + x; }
  overload fn Add(ref self, flag: bool) {
    if (flag) { self.total = self.total + 100; }
  }
  fn Get(self) -> i32 { return self.total; }
}

inline Cpp '''
inline int Drive() {
  auto a = Carbon::Acc::Make();
  a.Add(1);
  a.Add(true);
  return a.Get();
}
''';

fn Use() -> i32 { return Cpp.Drive(); }
