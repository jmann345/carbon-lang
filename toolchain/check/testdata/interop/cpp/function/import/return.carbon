// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/function/import/return.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/function/import/return.carbon

// ============================================================================
// Multiple function with a return value
// ============================================================================

// --- multiple.h

auto foo1() -> short;
auto foo2() -> int;

// --- import_multiple.carbon

library "[[@TEST_NAME]]";

import Cpp library "multiple.h";

fn IngestI16(x: i16);
fn IngestI32(x: i32);

fn F() {
  //@dump-sem-ir-begin
  IngestI16(Cpp.foo1());
  IngestI32(Cpp.foo2());
  //@dump-sem-ir-end
}

// ============================================================================
// Undeduced return type
// ============================================================================

// --- fail_return_undeduced_auto.carbon

library "[[@TEST_NAME]]";

import Cpp inline '''
auto UndeducedReturn();
''';

fn Call() {
  Cpp.UndeducedReturn();
}

// ============================================================================
// Initialize a variable from a thunk output parameter
// ============================================================================

// --- var_from_thunk_param.carbon

library "[[@TEST_NAME]]";

import Cpp inline '''
using nullptr_t = decltype(nullptr);
auto ReturnNullPtr() -> nullptr_t;
''';

fn InitializeFromReturn() {
  //@dump-sem-ir-begin
  var unused c: Cpp.nullptr_t = Cpp.ReturnNullPtr();
  //@dump-sem-ir-end
}

// ============================================================================
// Return from a thunk output parameter
// ============================================================================

// --- return_from_thunk_param.carbon
//@include-in-dumps
library "[[@TEST_NAME]]";

import Cpp inline '''
unsigned char ReturnU8();
''';

fn GetU8() -> u8 { return Cpp.ReturnU8(); }

// ============================================================================
// Initialize a variable from a thunk with no output parameter
// ============================================================================

// --- var_from_thunk_by_value.carbon
//@include-in-dumps
library "[[@TEST_NAME]]";

import Cpp inline '''
unsigned int ReturnU32();
''';

fn Var() {
  var unused my_u32: u32 = Cpp.ReturnU32();
}
