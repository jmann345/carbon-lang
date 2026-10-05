// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/convert.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/class/import/union.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/class/import/union.carbon

// ============================================================================
// Declaration
// ============================================================================

// --- declaration.h

union DeclBar;

// --- import_declaration.carbon

library "[[@TEST_NAME]]";

import Cpp library "declaration.h";

//@dump-sem-ir-begin
fn MyF(bar: Cpp.DeclBar*);
//@dump-sem-ir-end

// --- fail_use_declaration_as_definition.carbon

library "[[@TEST_NAME]]";

import Cpp library "declaration.h";

fn MyF() {
  var unused bar: Cpp.DeclBar;
}

// ============================================================================
// Definition
// ============================================================================

// --- definition.h

union DefBar {};

// --- import_definition.carbon

library "[[@TEST_NAME]]";

import Cpp library "definition.h";

//@dump-sem-ir-begin
fn MyF(bar: Cpp.DefBar*);
//@dump-sem-ir-end

// ============================================================================
// Declaration and definition
// ============================================================================

// --- declaration_and_definition.h

union DeclDefBar;
union DeclDefBar {};

// --- import_declaration_and_definition.carbon

library "[[@TEST_NAME]]";

import Cpp library "declaration_and_definition.h";

//@dump-sem-ir-begin
fn MyF(bar: Cpp.DeclDefBar*);
//@dump-sem-ir-end

// ============================================================================
// Static member function
// ============================================================================

// --- static_member_function.h

union StaticMemberFnBar {
 public:
  static auto foo() -> void;
};

// --- import_static_member_function.carbon

library "[[@TEST_NAME]]";

import Cpp library "static_member_function.h";

fn MyF() {
  //@dump-sem-ir-begin
  Cpp.StaticMemberFnBar.foo();
  //@dump-sem-ir-end
}

// ============================================================================
// Static data member
// ============================================================================

// --- static_data_member.h

union StaticDataMemberBar {
 public:
  static StaticDataMemberBar* _Nonnull foo;
};

// --- import_static_data_member.carbon

library "[[@TEST_NAME]]";

import Cpp library "static_data_member.h";

fn MyF() {
  //@dump-sem-ir-begin
  let unused bar: Cpp.StaticDataMemberBar* = Cpp.StaticDataMemberBar.foo;
  //@dump-sem-ir-end
}

// ============================================================================
// Data member
// ============================================================================

// --- data_member.h

union DataMemberBar {
 public:
  DataMemberBar* _Nonnull foo;
};

// --- import_data_member.carbon

library "[[@TEST_NAME]]";

import Cpp library "data_member.h";

//@dump-sem-ir-begin
fn MyF(bar : Cpp.DataMemberBar*) {
  let unused foo_bar: Cpp.DataMemberBar* = bar->foo;
}
//@dump-sem-ir-end

// ============================================================================
// Template
// ============================================================================

// --- template.h

struct X {};

template<typename T>
union TemplateBar {};

// --- import_template.carbon

library "[[@TEST_NAME]]";

import Cpp library "template.h";

//@dump-sem-ir-begin
fn MyF(bar: Cpp.TemplateBar(Cpp.X)*);
//@dump-sem-ir-end
