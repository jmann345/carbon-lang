// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/function/import/pointer.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/function/import/pointer.carbon

// ============================================================================
// Non-nullable pointer as a parameter type
// ============================================================================

// --- non_nullable_pointer_param.h

struct NonNullableParamS {};

auto non_nullable_param_foo(NonNullableParamS* _Nonnull) -> void;

// --- import_non_nullable_pointer_param.carbon

library "[[@TEST_NAME]]";

import Cpp library "non_nullable_pointer_param.h";

fn F() {
  //@dump-sem-ir-begin
  var s: Cpp.NonNullableParamS = {};
  Cpp.non_nullable_param_foo(&s);
  //@dump-sem-ir-end
}

// --- fail_import_non_nullable_pointer_param_using_const_value.carbon

library "[[@TEST_NAME]]";

import Cpp library "non_nullable_pointer_param.h";

fn G() -> const Cpp.NonNullableParamS;

fn F() {
  var s: const Cpp.NonNullableParamS = G();
  Cpp.non_nullable_param_foo(&s);
}

// --- import_non_nullable_pointer_param_using_const_pointer.carbon

library "[[@TEST_NAME]]";

import Cpp library "non_nullable_pointer_param.h";

fn G() -> const (Cpp.NonNullableParamS*);

fn F() {
  //@dump-sem-ir-begin
  var p: const (Cpp.NonNullableParamS*) = G();
  Cpp.non_nullable_param_foo(p);
  //@dump-sem-ir-end
}

// ============================================================================
// Double non-nullable pointer as a parameter type
// ============================================================================

// --- double_non_nullable_pointer_param.h

struct DoubleNonNullableParamS {};

auto double_non_nullable_param_foo(DoubleNonNullableParamS* _Nonnull * _Nonnull) -> void;

// --- import_double_non_nullable_pointer_param.carbon

library "[[@TEST_NAME]]";

import Cpp library "double_non_nullable_pointer_param.h";

fn F() {
  //@dump-sem-ir-begin
  var s: Cpp.DoubleNonNullableParamS = {};
  var p: Cpp.DoubleNonNullableParamS* = &s;
  Cpp.double_non_nullable_param_foo(&p);
  //@dump-sem-ir-end
}

// ============================================================================
// Non-nullable pointer to const as a parameter type
// ============================================================================

// --- non_nullable_pointer_to_const_param.h

struct NonNullablePointerToConstParamS {};

auto non_nullable_to_const_foo(const NonNullablePointerToConstParamS* _Nonnull) -> void;

// --- import_non_nullable_pointer_to_const_param_using_const.carbon

library "[[@TEST_NAME]]";

import Cpp library "non_nullable_pointer_to_const_param.h";

fn G() -> const Cpp.NonNullablePointerToConstParamS;

fn F() {
  //@dump-sem-ir-begin
  var s: const Cpp.NonNullablePointerToConstParamS = G();
  Cpp.non_nullable_to_const_foo(&s);
  //@dump-sem-ir-end
}

// --- import_non_nullable_pointer_to_const_param_using_non_const.carbon

import Cpp library "non_nullable_pointer_to_const_param.h";

fn G() -> Cpp.NonNullablePointerToConstParamS;

fn F() {
  //@dump-sem-ir-begin
  var s: Cpp.NonNullablePointerToConstParamS = G();
  Cpp.non_nullable_to_const_foo(&s);
  //@dump-sem-ir-end
}

// ============================================================================
// Const non-nullable pointer as a parameter type
// ============================================================================

// --- const_non_nullable_pointer_param.h

struct ConstNonNullableParamS {};

auto const_non_nullable_foo(ConstNonNullableParamS* _Nonnull const) -> void;

// --- import_const_non_nullable_pointer_param_using_const.carbon

library "[[@TEST_NAME]]";

import Cpp library "const_non_nullable_pointer_param.h";

fn G() -> const (Cpp.ConstNonNullableParamS*);

fn F() {
  //@dump-sem-ir-begin
  var p: const (Cpp.ConstNonNullableParamS*) = G();
  Cpp.const_non_nullable_foo(p);
  //@dump-sem-ir-end
}

// --- import_const_non_nullable_pointer_param_using_non_const.carbon

library "[[@TEST_NAME]]";

import Cpp library "const_non_nullable_pointer_param.h";

fn G() -> Cpp.ConstNonNullableParamS*;

fn F() {
  //@dump-sem-ir-begin
  var p: Cpp.ConstNonNullableParamS* = G();
  Cpp.const_non_nullable_foo(p);
  //@dump-sem-ir-end
}

// ============================================================================
// Const nullable pointer as a parameter type
// ============================================================================

// --- const_nullable_pointer_param.h

struct ConstNullableParamS {};

auto const_nullable_foo(ConstNullableParamS* const) -> void;

// --- import_const_nullable_pointer_param_using_const.carbon

library "[[@TEST_NAME]]";

import Cpp library "const_nullable_pointer_param.h";

fn G() -> const (Cpp.ConstNullableParamS*);

fn F() {
  //@dump-sem-ir-begin
  var p: const (Cpp.ConstNullableParamS*) = G();
  Cpp.const_nullable_foo(p);
  //@dump-sem-ir-end
}

// --- import_const_nullable_pointer_param_using_non_const.carbon

library "[[@TEST_NAME]]";

import Cpp library "const_nullable_pointer_param.h";

fn G() -> Cpp.ConstNullableParamS*;

fn F() {
  //@dump-sem-ir-begin
  var p: Cpp.ConstNullableParamS* = G();
  Cpp.const_nullable_foo(p);
  //@dump-sem-ir-end
}

// ============================================================================
// Non-nullable pointer as a return value
// ============================================================================

// --- non_nullable_pointer_return.h

struct NonNullableReturnS {};

auto non_nullable_return_foo() -> NonNullableReturnS* _Nonnull;

// --- import_non_nullable_pointer_return.carbon

library "[[@TEST_NAME]]";

import Cpp library "non_nullable_pointer_return.h";

fn IngestDoublePointer(s: Cpp.NonNullableReturnS*);

fn F() {
  //@dump-sem-ir-begin
  IngestDoublePointer(Cpp.non_nullable_return_foo());
  Cpp.non_nullable_return_foo();
  //@dump-sem-ir-end
}

// ============================================================================
// Double non-nullable pointer as a return value
// ============================================================================

// --- double_non_nullable_pointer_return.h

struct DoubleNonNullableReturnS {};

auto double_non_nullable_return_foo() -> DoubleNonNullableReturnS* _Nonnull * _Nonnull;

// --- import_double_pointer_return.carbon

library "[[@TEST_NAME]]";

import Cpp library "double_non_nullable_pointer_return.h";

fn IngestDoublePointer(s: Cpp.DoubleNonNullableReturnS**);

fn F() {
  //@dump-sem-ir-begin
  IngestDoublePointer(Cpp.double_non_nullable_return_foo());
  Cpp.double_non_nullable_return_foo();
  //@dump-sem-ir-end
}

// ============================================================================
// Const non-nullable pointer as a return value
// ============================================================================

// --- const_non_nullable_pointer_return.h

struct ConstNonNullableReturnS {};

auto const_non_nullable_return_foo() -> const ConstNonNullableReturnS* _Nonnull;

// --- import_const_non_nullable_pointer_return.carbon

library "[[@TEST_NAME]]";

import Cpp library "const_non_nullable_pointer_return.h";

fn IngestConstPointer(s: const Cpp.ConstNonNullableReturnS*);

fn F() {
  //@dump-sem-ir-begin
  IngestConstPointer(Cpp.const_non_nullable_return_foo());
  Cpp.const_non_nullable_return_foo();
  //@dump-sem-ir-end
}

// ============================================================================
// Nullable pointer
// ============================================================================

// --- nullable_pointer_param.h

struct NullableParamS {};

auto nullable_param_foo(NullableParamS*) -> void;

auto nullable_param_get() -> NullableParamS*;

// --- non_nullable_pointer_arg_to_pointer_param.carbon

library "[[@TEST_NAME]]";

import Cpp library "nullable_pointer_param.h";

fn F() {
  //@dump-sem-ir-begin
  var s: Cpp.NullableParamS = {};
  Cpp.nullable_param_foo(&s);
  //@dump-sem-ir-end
}

// --- null_pointer_arg_to_pointer_param.carbon

library "[[@TEST_NAME]]";

import Cpp library "nullable_pointer_param.h";

fn F() {
  //@dump-sem-ir-begin
  Cpp.nullable_param_foo(Core.Optional(Cpp.NullableParamS*).None());
  //@dump-sem-ir-end
}

// --- nonnull_pointer_arg_to_pointer_param.carbon

library "[[@TEST_NAME]]";

import Cpp library "nullable_pointer_param.h";

fn F() {
  //@dump-sem-ir-begin
  var s: Cpp.NullableParamS = {};
  Cpp.nullable_param_foo(Core.Optional(Cpp.NullableParamS*).Some(&s));
  //@dump-sem-ir-end
}

// --- forward_nullable_pointer.carbon

library "[[@TEST_NAME]]";

import Cpp library "nullable_pointer_param.h";

fn F() {
  //@dump-sem-ir-begin
  Cpp.nullable_param_foo(Cpp.nullable_param_get());
  //@dump-sem-ir-end
}

// ============================================================================
// Deduced pointer type as template argument
// ============================================================================

// --- deduced_any_param.h

struct DeducedAnyS {};

template<typename T>
auto deduced_any_foo(T) -> T;

// --- import_deduced_any_param_as_pointer.carbon

library "[[@TEST_NAME]]";

import Cpp library "deduced_any_param.h";

fn F() {
  //@dump-sem-ir-begin
  var s: Cpp.DeducedAnyS = {};

  // We assume that this cannot return a null pointer, because the function is
  // generic in the type `T`.
  // TODO: This isn't guaranteed; is this the behavior we want?
  let unused p: Cpp.DeducedAnyS* = Cpp.deduced_any_foo(&s);
  //@dump-sem-ir-end
}

// --- deduced_pointer_param.h

struct DeducedPointerS {};

template<typename T>
auto Direct(T*) -> T*;

template<typename T>
using Wrap = T;

template<typename U>
using AddPointer = Wrap<U*>;

template<typename V>
auto Indirect(V) -> AddPointer<V>;

// --- import_deduced_pointer_param_as_pointer.carbon

library "[[@TEST_NAME]]";

import Cpp library "deduced_pointer_param.h";

fn F() {
  // These pass or return an Optional(DeducedPointerS*), not a DeducedPointerS*.

  //@dump-sem-ir-begin
  var s: Cpp.DeducedPointerS = {};
  Cpp.Direct(&s);

  let unused a: Core.Optional(Cpp.DeducedPointerS*) = Cpp.Indirect({} as Cpp.DeducedPointerS);
  //@dump-sem-ir-end
}

// --- fail_import_deduced_pointer_param_as_optional_pointer.carbon

library "[[@TEST_NAME]]";

import Cpp library "deduced_pointer_param.h";

fn F() {
  // This could return a null pointer, so should not be given the type `Cpp.DeducedPointerS*`.
  let unused a: Cpp.DeducedPointerS* = Cpp.Indirect({} as Cpp.DeducedPointerS);
}
