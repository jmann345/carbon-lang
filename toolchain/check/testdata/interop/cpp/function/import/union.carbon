// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/convert.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/function/import/union.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/function/import/union.carbon

// ============================================================================
// Forward-declared union as parameter type
// ============================================================================

// --- decl_value_param_type.h

union ForwardDeclaredUnion;

auto foo1(ForwardDeclaredUnion) -> void;
auto foo2(ForwardDeclaredUnion) -> void;

// --- fail_import_decl_value_param_type.carbon

library "[[@TEST_NAME]]";

import Cpp library "decl_value_param_type.h";

fn F(p: Cpp.ForwardDeclaredUnion*) {
  Cpp.foo1(*p);
  Cpp.foo2(*p);
}

// ============================================================================
// Defined union without data members as parameter type
// ============================================================================

// --- definition_no_data_members_value_param_type.h

union EmptyUnion {};

auto foo_empty(EmptyUnion) -> void;

// --- import_definition_no_data_members_value_param_type.carbon

library "[[@TEST_NAME]]";

import Cpp library "definition_no_data_members_value_param_type.h";

fn F(u: Cpp.EmptyUnion) {
  //@dump-sem-ir-begin
  Cpp.foo_empty(u);
  //@dump-sem-ir-end
}

// ============================================================================
// Defined union with a single data member as parameter type
// ============================================================================

// --- definition_single_data_member_value_param_type.h

struct SingleMemberS {};

union SingleMemberUnion {
  SingleMemberS s;
};

auto foo_single_member(SingleMemberUnion) -> void;

// --- import_definition_single_data_member_value_param_type.carbon

library "[[@TEST_NAME]]";

import Cpp library "definition_single_data_member_value_param_type.h";

fn F(u: Cpp.SingleMemberUnion) {
  //@dump-sem-ir-begin
  Cpp.foo_single_member(u);
  //@dump-sem-ir-end
}

// ============================================================================
// Defined union with multiple data members as parameter type
// ============================================================================

// --- definition_multiple_data_members_value_param_type.h

struct MultipleMembersS {};

union MultipleMembersUnion {
  MultipleMembersS s1;
  MultipleMembersS s2;
  MultipleMembersS s3;
};

auto foo_multiple_members(MultipleMembersUnion) -> void;

// --- import_definition_multiple_data_members_value_param_type.carbon

library "[[@TEST_NAME]]";

import Cpp library "definition_multiple_data_members_value_param_type.h";

fn F(u: Cpp.MultipleMembersUnion) {
  //@dump-sem-ir-begin
  Cpp.foo_multiple_members(u);
  //@dump-sem-ir-end
}

// ============================================================================
// Defined union in namespace
// ============================================================================

// --- definition_in_namespace_value_param_type.h

namespace N { union InNamespaceUnion {}; }

auto foo_in_namespace(N::InNamespaceUnion) -> void;

// --- import_definition_in_namespace_value_param_type.carbon

library "[[@TEST_NAME]]";

import Cpp library "definition_in_namespace_value_param_type.h";

fn F(u: Cpp.N.InNamespaceUnion) {
  //@dump-sem-ir-begin
  Cpp.foo_in_namespace(u);
  // Check that the parameter type was imported correctly.
  var unused x: Cpp.N.InNamespaceUnion;
  //@dump-sem-ir-end
}

// ============================================================================
// Defined union in relative namespace
// ============================================================================

// --- definition_in_relative_namespace_value_param_type.h

namespace N1 {
  namespace N2 { union InRelativeNamespaceUnion {}; }
  auto foo(N2::InRelativeNamespaceUnion) -> void;
}

// --- import_definition_in_relative_namespace_value_param_type.carbon

library "[[@TEST_NAME]]";

import Cpp library "definition_in_relative_namespace_value_param_type.h";

fn F(u: Cpp.N1.N2.InRelativeNamespaceUnion) {
  //@dump-sem-ir-begin
  Cpp.N1.foo(u);
  //@dump-sem-ir-end
}

// ============================================================================
// Defined union in union
// ============================================================================

// --- definition_in_outer_definition.h

union OuterUnion {
 public:
  union InnerUnion {};
};

auto foo_in_outer(OuterUnion::InnerUnion) -> void;

// --- import_definition_in_outer_definition.carbon

library "[[@TEST_NAME]]";

import Cpp library "definition_in_outer_definition.h";

fn F(u: Cpp.OuterUnion.InnerUnion) {
  //@dump-sem-ir-begin
  Cpp.foo_in_outer(u);
  var unused x: Cpp.OuterUnion;
  //@dump-sem-ir-end
}

// ============================================================================
// Defined union and explicitly used
// ============================================================================

// --- definition_with_static_method.h

union StaticMethodUnion {
  static void bar();
};

auto foo_static_method(StaticMethodUnion) -> void;

// --- import_definition_and_static_method_call_before.carbon

library "[[@TEST_NAME]]";

import Cpp library "definition_with_static_method.h";

fn F(u: Cpp.StaticMethodUnion) {
  //@dump-sem-ir-begin
  Cpp.StaticMethodUnion.bar();
  Cpp.foo_static_method(u);
  //@dump-sem-ir-end
}

// --- import_definition_and_static_method_call_after.carbon

library "[[@TEST_NAME]]";

import Cpp library "definition_with_static_method.h";

fn F(u: Cpp.StaticMethodUnion) {
  //@dump-sem-ir-begin
  Cpp.foo_static_method(u);
  Cpp.StaticMethodUnion.bar();
  //@dump-sem-ir-end
}

// ============================================================================
// Incomplete union
// ============================================================================

// --- incomplete.h

union IncompleteUnion;

// --- fail_import_incomplete.carbon

library "[[@TEST_NAME]]";

import Cpp library "incomplete.h";

fn F() {
  Cpp.IncompleteUnion.foo();
}

// ============================================================================
// Pointer to forward-declared union as parameter type
// ============================================================================

// --- decl_pointer_param_type.h

union DeclPointerParamUnion;

auto foo_decl_pointer_param(DeclPointerParamUnion* _Nonnull) -> void;

// --- import_decl_pointer_param_type.carbon

library "[[@TEST_NAME]]";

import Cpp library "decl_pointer_param_type.h";

fn F(u: Cpp.DeclPointerParamUnion*) {
  //@dump-sem-ir-begin
  Cpp.foo_decl_pointer_param(u);
  //@dump-sem-ir-end
}

// ============================================================================
// Pointer to defined union as parameter type
// ============================================================================

// --- definition_pointer_param_type.h

union DefPointerParamUnion {};

auto foo_def_pointer_param(DefPointerParamUnion* _Nonnull) -> void;

// --- import_definition_pointer_param_type.carbon

library "[[@TEST_NAME]]";

import Cpp library "definition_pointer_param_type.h";

fn F(u: Cpp.DefPointerParamUnion*) {
  //@dump-sem-ir-begin
  Cpp.foo_def_pointer_param(u);
  //@dump-sem-ir-end
}

// ============================================================================
// Forward-declared union as return type
// ============================================================================

// --- decl_value_return_type.h

union DeclValueReturnUnion;

auto foo_decl_value_return() -> DeclValueReturnUnion;

// --- fail_import_decl_value_return_type.carbon

library "[[@TEST_NAME]]";

import Cpp library "decl_value_return_type.h";

fn F() {
  Cpp.foo_decl_value_return();
}

// ============================================================================
// Defined union as return type
// ============================================================================

// --- definition_value_return_type.h

union DefValueReturnUnion {};

auto foo_def_value_return() -> DefValueReturnUnion;

// --- import_definition_value_return_type.carbon

library "[[@TEST_NAME]]";

import Cpp library "definition_value_return_type.h";

fn F() {
  //@dump-sem-ir-begin
  Cpp.foo_def_value_return();
  //@dump-sem-ir-end
}

// ============================================================================
// Pointer to forward-declared union as return type
// ============================================================================

// --- decl_pointer_return_type.h

union DeclPointerReturnUnion;

auto foo_decl_pointer_return() -> DeclPointerReturnUnion* _Nonnull;

// --- import_decl_pointer_return_type.carbon

library "[[@TEST_NAME]]";

import Cpp library "decl_pointer_return_type.h";

fn F() {
  //@dump-sem-ir-begin
  Cpp.foo_decl_pointer_return();
  //@dump-sem-ir-end
}

// ============================================================================
// Pointer to defined union as return type
// ============================================================================

// --- definition_pointer_return_type.h

union DefPointerReturnUnion {};

auto foo_def_pointer_return() -> DefPointerReturnUnion* _Nonnull;

// --- import_definition_pointer_return_type.carbon

library "[[@TEST_NAME]]";

import Cpp library "definition_pointer_return_type.h";

fn F() {
  //@dump-sem-ir-begin
  Cpp.foo_def_pointer_return();
  //@dump-sem-ir-end
}
