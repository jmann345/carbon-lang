// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/convert.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/function/import/struct.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/function/import/struct.carbon

// ============================================================================
// Forward-declared struct as parameter type
// ============================================================================

// --- decl_value_param_type.h

struct ForwardDeclaredStruct;

auto foo1(ForwardDeclaredStruct) -> void;
auto foo2(ForwardDeclaredStruct) -> void;

// --- fail_import_decl_value_param_type.carbon

library "[[@TEST_NAME]]";

import Cpp library "decl_value_param_type.h";

fn F(p: Cpp.ForwardDeclaredStruct*) {
  Cpp.foo1(*p);
  Cpp.foo2(*p);
}

// ============================================================================
// Defined struct without data members as parameter type
// ============================================================================

// --- definition_no_data_members_value_param_type.h

struct EmptyStruct {};

auto foo_empty(EmptyStruct) -> void;

// --- import_definition_no_data_members_value_param_type.carbon

library "[[@TEST_NAME]]";

import Cpp library "definition_no_data_members_value_param_type.h";

fn F(s: Cpp.EmptyStruct) {
  //@dump-sem-ir-begin
  Cpp.foo_empty(s);
  //@dump-sem-ir-end
}

// ============================================================================
// Non copyable struct as parameter type
// ============================================================================

// --- non_copyable_param_type.h

struct NonCopyableStruct {
  NonCopyableStruct(const NonCopyableStruct&) = delete;
};

auto foo_non_copyable(NonCopyableStruct) -> void;

// --- fail_import_non_copyable_param_type.carbon

library "[[@TEST_NAME]]";

import Cpp library "non_copyable_param_type.h";

fn F(s: Cpp.NonCopyableStruct) {
  //@dump-sem-ir-begin
  Cpp.foo_non_copyable(s);
  //@dump-sem-ir-end
}

// ============================================================================
// Defined struct with a single data member as parameter type
// ============================================================================

// --- definition_single_data_member_value_param_type.h

struct SingleMemberD {};

struct SingleMemberStruct {
  SingleMemberD d;
};

auto foo_single_member(SingleMemberStruct) -> void;

// --- definition_single_data_member_value_param_type.carbon

library "[[@TEST_NAME]]";

import Cpp library "definition_single_data_member_value_param_type.h";

fn F(s: Cpp.SingleMemberStruct) {
  //@dump-sem-ir-begin
  Cpp.foo_single_member(s);
  //@dump-sem-ir-end
}

// ============================================================================
// Defined struct with multiple data members as parameter type
// ============================================================================

// --- definition_multiple_data_members_value_param_type.h

struct MultipleMembersD {};

struct MultipleMembersStruct {
  MultipleMembersD d1;
  MultipleMembersD d2;
  MultipleMembersD d3;
};

auto foo_multiple_members(MultipleMembersStruct) -> void;

// --- definition_multiple_data_members_value_param_type.carbon

library "[[@TEST_NAME]]";

import Cpp library "definition_multiple_data_members_value_param_type.h";

fn F(s: Cpp.MultipleMembersStruct) {
  //@dump-sem-ir-begin
  Cpp.foo_multiple_members(s);
  //@dump-sem-ir-end
}

// ============================================================================
// Defined struct in namespace
// ============================================================================

// --- definition_in_namespace_value_param_type.h

namespace N { struct InNamespaceStruct {}; }

auto foo_in_namespace(N::InNamespaceStruct) -> void;

// --- import_definition_in_namespace_value_param_type.carbon

library "[[@TEST_NAME]]";

import Cpp library "definition_in_namespace_value_param_type.h";

fn F(s: Cpp.N.InNamespaceStruct) {
  //@dump-sem-ir-begin
  Cpp.foo_in_namespace(s);
  // Check that the parameter type was imported correctly.
  var unused x: Cpp.N.InNamespaceStruct;
  //@dump-sem-ir-end
}

// ============================================================================
// Defined struct in relative namespace
// ============================================================================

// --- definition_in_relative_namespace_value_param_type.h

namespace N1 {
  namespace N2 { struct InRelativeNamespaceStruct {}; }
  auto foo(N2::InRelativeNamespaceStruct) -> void;
}

// --- import_definition_in_relative_namespace_value_param_type.carbon

library "[[@TEST_NAME]]";

import Cpp library "definition_in_relative_namespace_value_param_type.h";

fn F(s: Cpp.N1.N2.InRelativeNamespaceStruct) {
  //@dump-sem-ir-begin
  Cpp.N1.foo(s);
  //@dump-sem-ir-end
}

// ============================================================================
// Defined struct in struct
// ============================================================================

// --- definition_in_outer_definition.h

struct OuterStruct {
  struct InnerStruct {};
};

auto foo_in_outer(OuterStruct::InnerStruct) -> void;

// --- import_definition_in_outer_definition.carbon

library "[[@TEST_NAME]]";

import Cpp library "definition_in_outer_definition.h";

fn F(s: Cpp.OuterStruct.InnerStruct) {
  //@dump-sem-ir-begin
  Cpp.foo_in_outer(s);
  var unused x: Cpp.OuterStruct;
  //@dump-sem-ir-end
}

// ============================================================================
// Defined struct and explicitly used
// ============================================================================

// --- definition_with_static_method.h

struct StaticMethodStruct {
  static void bar();
};

auto foo_static_method(StaticMethodStruct) -> void;

// --- import_definition_and_static_method_call_before.carbon

library "[[@TEST_NAME]]";

import Cpp library "definition_with_static_method.h";

fn F(s: Cpp.StaticMethodStruct) {
  //@dump-sem-ir-begin
  Cpp.StaticMethodStruct.bar();
  Cpp.foo_static_method(s);
  //@dump-sem-ir-end
}

// --- import_definition_and_static_method_call_after.carbon

library "[[@TEST_NAME]]";

import Cpp library "definition_with_static_method.h";

fn F(s: Cpp.StaticMethodStruct) {
  //@dump-sem-ir-begin
  Cpp.foo_static_method(s);
  Cpp.StaticMethodStruct.bar();
  //@dump-sem-ir-end
}

// ============================================================================
// Incomplete struct
// ============================================================================

// --- incomplete.h

struct IncompleteStruct;

// --- fail_import_incomplete.carbon

library "[[@TEST_NAME]]";

import Cpp library "incomplete.h";

fn F() {
  Cpp.IncompleteStruct.foo();
}

// ============================================================================
// Pointer to forward-declared struct as parameter type
// ============================================================================

// --- decl_pointer_param_type.h

struct DeclPointerParamStruct;

auto foo_decl_pointer_param(DeclPointerParamStruct* _Nonnull) -> void;

// --- import_decl_pointer_param_type.carbon

library "[[@TEST_NAME]]";

import Cpp library "decl_pointer_param_type.h";

fn F(s: Cpp.DeclPointerParamStruct*) {
  //@dump-sem-ir-begin
  Cpp.foo_decl_pointer_param(s);
  //@dump-sem-ir-end
}

// ============================================================================
// Pointer to defined struct as parameter type
// ============================================================================

// --- definition_pointer_param_type.h

struct DefPointerParamStruct {};

auto foo_def_pointer_param(DefPointerParamStruct* _Nonnull) -> void;

// --- import_definition_pointer_param_type.carbon

library "[[@TEST_NAME]]";

import Cpp library "definition_pointer_param_type.h";

fn F(s: Cpp.DefPointerParamStruct*) {
  //@dump-sem-ir-begin
  Cpp.foo_def_pointer_param(s);
  //@dump-sem-ir-end
}

// ============================================================================
// Forward-declared struct as return type
// ============================================================================

// --- decl_value_return_type.h

struct DeclValueReturnStruct;

auto foo_decl_value_return() -> DeclValueReturnStruct;

// --- fail_import_decl_value_return_type.carbon

library "[[@TEST_NAME]]";

// TODO: We should only produce one error here.
import Cpp library "decl_value_return_type.h";

fn F() {
  Cpp.foo_decl_value_return();
}

// ============================================================================
// Defined struct as return type
// ============================================================================

// --- definition_value_return_type.h

struct DefValueReturnStruct {};

auto foo_def_value_return() -> DefValueReturnStruct;

// --- import_definition_value_return_type.carbon

library "[[@TEST_NAME]]";

import Cpp library "definition_value_return_type.h";

fn F() {
  //@dump-sem-ir-begin
  Cpp.foo_def_value_return();
  //@dump-sem-ir-end
}

// ============================================================================
// Pointer to forward-declared struct as return type
// ============================================================================

// --- decl_pointer_return_type.h

struct DeclPointerReturnStruct;

auto foo_decl_pointer_return() -> DeclPointerReturnStruct* _Nonnull;

// --- import_decl_pointer_return_type.carbon

library "[[@TEST_NAME]]";

import Cpp library "decl_pointer_return_type.h";

fn F() {
  //@dump-sem-ir-begin
  Cpp.foo_decl_pointer_return();
  //@dump-sem-ir-end
}

// ============================================================================
// Pointer to defined struct as return type
// ============================================================================

// --- definition_pointer_return_type.h

struct DefPointerReturnStruct {};

auto foo_def_pointer_return() -> DefPointerReturnStruct* _Nonnull;

// --- import_definition_pointer_return_type.carbon

library "[[@TEST_NAME]]";

import Cpp library "definition_pointer_return_type.h";

fn F() {
  //@dump-sem-ir-begin
  Cpp.foo_def_pointer_return();
  //@dump-sem-ir-end
}
