// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/convert.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/function/import/reference.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/function/import/reference.carbon

// ============================================================================
// Lvalue reference as a parameter type
// ============================================================================

// --- param_lvalue_ref.h

struct S {};
struct T {};

auto TakesLValue(S&) -> void;

// --- call_param_lvalue_ref.carbon

library "[[@TEST_NAME]]";

import Cpp library "param_lvalue_ref.h";

fn F() {
  //@dump-sem-ir-begin
  var s: Cpp.S = {};
  Cpp.TakesLValue(ref s);
  //@dump-sem-ir-end
}

// --- fail_param_lvalue_ref.carbon

library "[[@TEST_NAME]]";

import Cpp library "param_lvalue_ref.h";

fn F() {
  //@dump-sem-ir-begin
  var v: Cpp.S;
  let s: Cpp.S = v;
  Cpp.TakesLValue(s);

  Cpp.TakesLValue(s as const Cpp.S);

  var t: Cpp.T;
  Cpp.TakesLValue(t);

  var u: Cpp.S;
  Cpp.TakesLValue(u as const Cpp.S);
  //@dump-sem-ir-end
}

// --- derived_to_base.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
struct Base { Base(const Base&) = delete; };
struct Derived : Base {};
void f(Base &b);
''';

fn F(ref r: Cpp.Derived) {
  Cpp.f(ref r);
}

// ============================================================================
// Rvalue reference as a parameter type
// ============================================================================

// --- param_rvalue_ref.h

struct S {};
struct T {};

auto TakesRValue(S&&) -> void;

// --- call_param_rvalue_ref.carbon

library "[[@TEST_NAME]]";

import Cpp library "param_rvalue_ref.h";

fn F() {
  //@dump-sem-ir-begin
  Cpp.TakesRValue({} as Cpp.S);
  //@dump-sem-ir-end
}

// --- fail_param_value_arg_for_rvalue_ref.carbon

library "[[@TEST_NAME]]";

import Cpp library "param_rvalue_ref.h";

fn F() {
  let s: Cpp.S = {};
  Cpp.TakesRValue(s);
}

// --- fail_param_rvalue_ref.carbon

library "[[@TEST_NAME]]";

import Cpp library "param_rvalue_ref.h";

fn F() {
  //@dump-sem-ir-begin
  var s: Cpp.S;
  Cpp.TakesRValue(s);

  var t: Cpp.T;
  Cpp.TakesRValue(t);

  Cpp.TakesRValue(({} as Cpp.S) as const Cpp.S);
  //@dump-sem-ir-end
}

// ============================================================================
// Const reference as a parameter type
// ============================================================================

// --- param_const_lvalue_ref.h

struct S {};
struct T {};

auto TakesConstLValue(const S&) -> void;

// --- call_param_const_lvalue_ref_with_ref.carbon

library "[[@TEST_NAME]]";

import Cpp library "param_const_lvalue_ref.h";

fn F() {
  //@dump-sem-ir-begin
  var s: Cpp.S = {};
  Cpp.TakesConstLValue(s as const Cpp.S);

  Cpp.TakesConstLValue(s);
  //@dump-sem-ir-end
}

// --- call_param_const_lvalue_ref_with_value.carbon

library "[[@TEST_NAME]]";

import Cpp library "param_const_lvalue_ref.h";

fn F() {
  //@dump-sem-ir-begin
  let s: Cpp.S = {};
  Cpp.TakesConstLValue(s);

  Cpp.TakesConstLValue(s as const Cpp.S);
  //@dump-sem-ir-end
}

// --- fail_call_param_const_lvalue_ref_with_wrong_type.carbon

library "[[@TEST_NAME]]";

import Cpp library "param_const_lvalue_ref.h";

fn F() {
  var t: Cpp.T;
  Cpp.TakesConstLValue(t);
}

// ============================================================================
// Const rvalue reference as a parameter type
// ============================================================================

// --- param_const_rvalue_ref.h

struct S {};
struct T {};

auto TakesConstRValue(const S&&) -> void;

// --- param_value_arg_for_const_rvalue_ref.carbon

library "[[@TEST_NAME]]";

import Cpp library "param_const_rvalue_ref.h";

fn F(v: Cpp.S, cv: const Cpp.S) {
  //@dump-sem-ir-begin
  Cpp.TakesConstRValue(v);
  Cpp.TakesConstRValue(cv);
  //@dump-sem-ir-end
}

// --- param_init_arg_for_const_rvalue_ref.carbon

library "[[@TEST_NAME]]";

import Cpp library "param_const_rvalue_ref.h";

fn Make() -> Cpp.S;

fn F() {
  Cpp.TakesConstRValue({});
  Cpp.TakesConstRValue({} as Cpp.S);
  Cpp.TakesConstRValue(({} as Cpp.S) as const Cpp.S);
  Cpp.TakesConstRValue(Make());
}

// --- fail_param_lvalue_ref_arg_const_rvalue_ref.carbon

library "[[@TEST_NAME]]";

import Cpp library "param_const_rvalue_ref.h";

fn F() {
  //@dump-sem-ir-begin
  var s: Cpp.S;
  Cpp.TakesConstRValue(s);

  var t: Cpp.T;
  Cpp.TakesConstRValue(t);
  //@dump-sem-ir-end
}

// ============================================================================
// Lvalue reference as return type
// ============================================================================

// --- return_lvalue_ref.h

struct S {};

auto ReturnsLValue() -> S&;

// --- call_return_lvalue_ref.carbon

library "[[@TEST_NAME]]";

import Cpp library "return_lvalue_ref.h";

fn F() {
  //@dump-sem-ir-begin
  let unused ref s: Cpp.S = Cpp.ReturnsLValue();
  //@dump-sem-ir-end
}

// ============================================================================
// Rvalue reference as return type
// ============================================================================

// --- return_rvalue_ref.h

struct S {};

auto ReturnsRValue() -> S&&;

// --- call_return_rvalue_ref.carbon

library "[[@TEST_NAME]]";

import Cpp library "return_rvalue_ref.h";

fn F() {
  //@dump-sem-ir-begin
  let unused ref s: Cpp.S = Cpp.ReturnsRValue();
  //@dump-sem-ir-end
}

// ============================================================================
// Const reference as return type
// ============================================================================

// --- return_const_lvalue_ref.h

struct S {};

auto ReturnConstLValue() -> const S&;

// --- call_return_const_lvalue_ref.carbon

library "[[@TEST_NAME]]";

import Cpp library "return_const_lvalue_ref.h";

fn F() {
  //@dump-sem-ir-begin
  let unused ref s: const Cpp.S = Cpp.ReturnConstLValue();
  //@dump-sem-ir-end
}

// --- fail_call_return_const_lvalue_ref_const_correctness.carbon

library "[[@TEST_NAME]]";

import Cpp library "return_const_lvalue_ref.h";

fn F() {
  let unused ref s: Cpp.S = Cpp.ReturnConstLValue();
}

// ============================================================================
// Forwarding references
// ============================================================================

// --- forwarding_reference.carbon

library "[[@TEST_NAME]]";

import Cpp;

class X {}

inline Cpp '''c++
template<typename T> void TakeAnything_ExpectLRef(T&&) {
  static_assert(__is_same(T, Carbon::X&));
}
template<typename T> void TakeAnything_ExpectConstLRef(T&&) {
  static_assert(__is_same(T, const Carbon::X&));
}
template<typename T> void TakeAnything_ExpectRRef(T&&) {
  static_assert(__is_same(T, Carbon::X));
}
template<typename T> void TakeAnything_ExpectConstRRef(T&&) {
  static_assert(__is_same(T, const Carbon::X));
}
''';

fn Make() -> X;

fn PassValue(x: X) {
  //@dump-sem-ir-begin
  // TODO: Is a `const X&&` the right choice here?
  Cpp.TakeAnything_ExpectConstRRef(x);
  //@dump-sem-ir-end
}

fn PassRef(ref x: X) {
  //@dump-sem-ir-begin
  Cpp.TakeAnything_ExpectLRef(ref x);
  //@dump-sem-ir-end
}

fn PassConstRef(ref x: const X) {
  //@dump-sem-ir-begin
  Cpp.TakeAnything_ExpectConstLRef(x);
  //@dump-sem-ir-end
}

fn PassInit() {
  //@dump-sem-ir-begin
  Cpp.TakeAnything_ExpectRRef(Make());
  //@dump-sem-ir-end
}

// --- fail_todo_forwarding_reference_by_ref.carbon

library "[[@TEST_NAME]]";

import Cpp;

class XByRef {}

inline Cpp '''c++
template<typename T> void TakeAnything_ExpectConstLRef_ByRef(T&&) {
  static_assert(__is_same(T, const Carbon::XByRef&));
}
''';

fn PassConstRef(ref x: const XByRef) {
  Cpp.TakeAnything_ExpectConstLRef_ByRef(ref x);
}
