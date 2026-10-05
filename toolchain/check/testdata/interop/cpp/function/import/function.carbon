// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/primitives.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/function/import/function.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/function/import/function.carbon

// ============================================================================
// Global
// ============================================================================

// --- global.h

auto global_foo() -> void;

// --- import_global.carbon

library "[[@TEST_NAME]]";

import Cpp library "global.h";

fn MyF() {
  //@dump-sem-ir-begin
  Cpp.global_foo();
  //@dump-sem-ir-end
}

// --- fail_import_global_use_different_name.carbon

library "[[@TEST_NAME]]";

import Cpp library "global.h";

fn MyF() {
  Cpp.bar();
}

// ============================================================================
// Carbon keyword name
// ============================================================================

// --- special_name.h

auto base() -> void;

// --- fail_import_special_name_call_unescaped.carbon

library "[[@TEST_NAME]]";

import Cpp library "special_name.h";

fn MyF() {
  Cpp.base();
}

// --- import_special_name_call_escaped.carbon

library "[[@TEST_NAME]]";

import Cpp library "special_name.h";

fn MyF() {
  //@dump-sem-ir-begin
  Cpp.r#base();
  //@dump-sem-ir-end
}

// --- fail_import_special_name_call_escaped_no_match.carbon

library "[[@TEST_NAME]]";

import Cpp library "special_name.h";

fn MyF() {
  Cpp.r#base(1);
}

// ============================================================================
// Overloaded
// ============================================================================

// --- overloaded.h

auto overloaded_foo() -> void;
auto overloaded_foo(int value) -> void;

// --- import_overloaded.carbon

library "[[@TEST_NAME]]";

import Cpp library "overloaded.h";

fn F() {
  //@dump-sem-ir-begin
  Cpp.overloaded_foo();
  //@dump-sem-ir-end
}

// ============================================================================
// Variadic arguments
// ============================================================================

// --- variadic.h

auto variadic_foo(int x, ...) -> void;

// --- fail_todo_import_variadic.carbon

library "[[@TEST_NAME]]";

import Cpp library "variadic.h";

fn F() {
  //@dump-sem-ir-begin
  Cpp.variadic_foo(8);
  //@dump-sem-ir-end
}

// ============================================================================
// Static
// ============================================================================

// --- static.h

// TODO: Promote this warning to an error by default.
static auto static_foo() -> void;

// --- todo_fail_import_static.carbon

library "[[@TEST_NAME]]";

import Cpp library "static.h";

fn F() {
  //@dump-sem-ir-begin
  Cpp.static_foo();
  //@dump-sem-ir-end
}

// --- template_function.h

template<typename T>
auto template_foo(T a) -> void;

template<typename T>
auto template_bar(T a) -> T;

// --- import_template_function.carbon

library "[[@TEST_NAME]]";

import Cpp library "template_function.h";

fn F() {
  //@dump-sem-ir-begin
  Cpp.template_foo(1 as i32);
  //@dump-sem-ir-end
}

fn G() -> i32 {
  //@dump-sem-ir-begin
  return Cpp.template_bar(1 as i32);
  //@dump-sem-ir-end
}

// TODO: Add a test per unsupported param type. See https://github.com/carbon-language/carbon-lang/pull/5477/files/4321e21ed27d987fd71be182d292973fd9849df8#r2094655176

// TODO: Add a test per unsupported return type. See https://github.com/carbon-language/carbon-lang/pull/5477/files/4321e21ed27d987fd71be182d292973fd9849df8#r2094655176
