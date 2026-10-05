// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/convert.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/function/import/class.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/function/import/class.carbon

// ============================================================================
// Forward-declared class as parameter type
// ============================================================================

// --- decl_value_param_type.h

class ForwardDeclaredClass;

auto foo_decl_param1(ForwardDeclaredClass) -> void;
auto foo_decl_param2(ForwardDeclaredClass) -> void;

// --- fail_import_decl_value_param_type.carbon

library "[[@TEST_NAME]]";

import Cpp library "decl_value_param_type.h";

fn F(p: Cpp.ForwardDeclaredClass*) {
  Cpp.foo_decl_param1(*p);
  Cpp.foo_decl_param2(*p);
}

// ============================================================================
// Defined class without data members as parameter type
// ============================================================================

// --- definition_no_data_members_value_param_type.h

class EmptyClass {};

auto foo_empty_param(EmptyClass) -> void;

// --- import_definition_no_data_members_value_param_type.carbon

library "[[@TEST_NAME]]";

import Cpp library "definition_no_data_members_value_param_type.h";

fn F(c: Cpp.EmptyClass) {
  //@dump-sem-ir-begin
  Cpp.foo_empty_param(c);
  //@dump-sem-ir-end
}

// ============================================================================
// Non copyable class as parameter type
// ============================================================================

// --- non_copyable_param_type.h

class NonCopyableClass {
  NonCopyableClass(const NonCopyableClass&) = delete;
};

auto foo_non_copyable_param(NonCopyableClass) -> void;

// --- fail_import_non_copyable_param_type.carbon

library "[[@TEST_NAME]]";

import Cpp library "non_copyable_param_type.h";

fn F(c: Cpp.NonCopyableClass) {
  //@dump-sem-ir-begin
  Cpp.foo_non_copyable_param(c);
  //@dump-sem-ir-end
}

// ============================================================================
// Move-only class as parameter type
// ============================================================================

// --- move_only_param_type.h

struct MoveOnlyClass {
  MoveOnlyClass(MoveOnlyClass&&);
};

auto foo_move_only_param(MoveOnlyClass) -> void;
auto make_move_only() -> MoveOnlyClass;
auto move_move_only(MoveOnlyClass&) -> MoveOnlyClass&&;

// --- pass_move_only_param_temporary.carbon

library "[[@TEST_NAME]]";

import Cpp library "move_only_param_type.h";

fn F() {
  //@dump-sem-ir-begin
  Cpp.foo_move_only_param(Cpp.make_move_only());
  //@dump-sem-ir-end
}

// --- fail_pass_move_only_param_value.carbon

library "[[@TEST_NAME]]";

import Cpp library "move_only_param_type.h";

fn F(c: Cpp.MoveOnlyClass) {
  Cpp.foo_move_only_param(c);
}

// --- fail_pass_move_only_param_ref.carbon

library "[[@TEST_NAME]]";

import Cpp library "move_only_param_type.h";

fn F(ref c: Cpp.MoveOnlyClass) {
  Cpp.foo_move_only_param(c);
}

// --- fail_todo_pass_move_only_param_ref_by_move.carbon

library "[[@TEST_NAME]]";

import Cpp library "move_only_param_type.h";

fn F(ref c: Cpp.MoveOnlyClass) {
  Cpp.foo_move_only_param(Cpp.move_move_only(ref c));
}

// ============================================================================
// Defined class with a single data member as parameter type
// ============================================================================

// --- definition_single_data_member_value_param_type.h

class SingleMemberD {};

class SingleMemberClass {
  SingleMemberD d;
};

auto foo_single_member_param(SingleMemberClass) -> void;

// --- import_definition_single_data_member_value_param_type.carbon

library "[[@TEST_NAME]]";

import Cpp library "definition_single_data_member_value_param_type.h";

fn F(c: Cpp.SingleMemberClass) {
  //@dump-sem-ir-begin
  Cpp.foo_single_member_param(c);
  //@dump-sem-ir-end
}

// ============================================================================
// Defined class with multiple data members as parameter type
// ============================================================================

// --- definition_multiple_data_members_value_param_type.h

class MultipleMembersD {};

class MultipleMembersClass {
  MultipleMembersD d1;
  MultipleMembersD d2;
  MultipleMembersD d3;
};

auto foo_multiple_members_param(MultipleMembersClass) -> void;

// --- import_definition_multiple_data_members_value_param_type.carbon

library "[[@TEST_NAME]]";

import Cpp library "definition_multiple_data_members_value_param_type.h";

fn F(c: Cpp.MultipleMembersClass) {
  //@dump-sem-ir-begin
  Cpp.foo_multiple_members_param(c);
  //@dump-sem-ir-end
}

// ============================================================================
// Defined class in namespace
// ============================================================================

// --- definition_in_namespace_value_param_type.h

namespace N { class InNamespaceClass {}; }

auto foo_in_namespace_param(N::InNamespaceClass) -> void;

// --- import_definition_in_namespace_value_param_type.carbon

library "[[@TEST_NAME]]";

import Cpp library "definition_in_namespace_value_param_type.h";

fn F(c: Cpp.N.InNamespaceClass) {
  //@dump-sem-ir-begin
  Cpp.foo_in_namespace_param(c);
  // Check that the parameter type was imported correctly.
  var unused x: Cpp.N.InNamespaceClass;
  //@dump-sem-ir-end
}

// ============================================================================
// Defined class in relative namespace
// ============================================================================

// --- definition_in_relative_namespace_value_param_type.h

namespace N1 {
  namespace N2 { class InRelativeNamespaceClass {}; }
  auto foo(N2::InRelativeNamespaceClass) -> void;
}

// --- import_definition_in_relative_namespace_value_param_type.carbon

library "[[@TEST_NAME]]";

import Cpp library "definition_in_relative_namespace_value_param_type.h";

fn F(c: Cpp.N1.N2.InRelativeNamespaceClass) {
  //@dump-sem-ir-begin
  Cpp.N1.foo(c);
  //@dump-sem-ir-end
}

// ============================================================================
// Defined class in class
// ============================================================================

// --- definition_in_outer_definition.h

class OuterClass {
 public:
  class InnerClass {};
};

auto foo_in_outer_param(OuterClass::InnerClass) -> void;

// --- import_definition_in_outer_definition.carbon

library "[[@TEST_NAME]]";

import Cpp library "definition_in_outer_definition.h";

fn F(c: Cpp.OuterClass.InnerClass) {
  //@dump-sem-ir-begin
  Cpp.foo_in_outer_param(c);
  var unused x: Cpp.OuterClass;
  //@dump-sem-ir-end
}

// ============================================================================
// Defined class and explicitly used
// ============================================================================

// --- definition_with_static_method.h

class StaticMethodClass {
 public:
  static void bar();
};

auto foo_static_method_param(StaticMethodClass) -> void;

// --- import_definition_and_static_method_call_before.carbon

library "[[@TEST_NAME]]";

import Cpp library "definition_with_static_method.h";

fn F(c: Cpp.StaticMethodClass) {
  //@dump-sem-ir-begin
  Cpp.StaticMethodClass.bar();
  Cpp.foo_static_method_param(c);
  //@dump-sem-ir-end
}

// --- import_definition_and_static_method_call_after.carbon

library "[[@TEST_NAME]]";

import Cpp library "definition_with_static_method.h";

fn F(c: Cpp.StaticMethodClass) {
  //@dump-sem-ir-begin
  Cpp.foo_static_method_param(c);
  Cpp.StaticMethodClass.bar();
  //@dump-sem-ir-end
}

// ============================================================================
// Incomplete class
// ============================================================================

// --- incomplete.h

class Incomplete;

// --- fail_import_incomplete.carbon

library "[[@TEST_NAME]]";

import Cpp library "incomplete.h";

fn F() {
  Cpp.Incomplete.foo();
}

// ============================================================================
// Pointer to forward-declared class as parameter type
// ============================================================================

// --- decl_pointer_param_type.h

class DeclPointerParamClass;

auto foo_decl_pointer_param(DeclPointerParamClass* _Nonnull) -> void;

// --- import_decl_pointer_param_type.carbon

library "[[@TEST_NAME]]";

import Cpp library "decl_pointer_param_type.h";

fn F(c: Cpp.DeclPointerParamClass*) {
  //@dump-sem-ir-begin
  Cpp.foo_decl_pointer_param(c);
  //@dump-sem-ir-end
}

// ============================================================================
// Pointer to defined class as parameter type
// ============================================================================

// --- definition_pointer_param_type.h

class DefPointerParamClass {};

auto foo_def_pointer_param(DefPointerParamClass* _Nonnull) -> void;

// --- import_definition_pointer_param_type.carbon

library "[[@TEST_NAME]]";

import Cpp library "definition_pointer_param_type.h";

fn F(c: Cpp.DefPointerParamClass*) {
  //@dump-sem-ir-begin
  Cpp.foo_def_pointer_param(c);
  //@dump-sem-ir-end
}

// ============================================================================
// Forward-declared class as return type
// ============================================================================

// --- decl_value_return_type.h

class DeclValueReturnClass;

auto foo_decl_value_return() -> DeclValueReturnClass;

// --- fail_import_decl_value_return_type.carbon

library "[[@TEST_NAME]]";

import Cpp library "decl_value_return_type.h";

fn F() {
  Cpp.foo_decl_value_return();
}

// ============================================================================
// Defined class as return type
// ============================================================================

// --- definition_value_return_type.h

class DefValueReturnClass {};

auto foo_def_value_return() -> DefValueReturnClass;

// --- import_definition_value_return_type.carbon

library "[[@TEST_NAME]]";

import Cpp library "definition_value_return_type.h";

fn F() {
  //@dump-sem-ir-begin
  Cpp.foo_def_value_return();
  //@dump-sem-ir-end
}

// ============================================================================
// Pointer to forward-declared class as return type
// ============================================================================

// --- decl_pointer_return_type.h

class DeclPointerReturnClass;

auto foo_decl_pointer_return() -> DeclPointerReturnClass* _Nonnull;

// --- import_decl_pointer_return_type.carbon

library "[[@TEST_NAME]]";

import Cpp library "decl_pointer_return_type.h";

fn F() {
  //@dump-sem-ir-begin
  Cpp.foo_decl_pointer_return();
  //@dump-sem-ir-end
}

// ============================================================================
// Pointer to defined class as return type
// ============================================================================

// --- definition_pointer_return_type.h

class DefPointerReturnClass {};

auto foo_def_pointer_return() -> DefPointerReturnClass* _Nonnull;

// --- import_definition_pointer_return_type.carbon

library "[[@TEST_NAME]]";

import Cpp library "definition_pointer_return_type.h";

fn F() {
  //@dump-sem-ir-begin
  Cpp.foo_def_pointer_return();
  //@dump-sem-ir-end
}
