// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/int.carbon
// EXTRA-ARGS: --clang-arg=-std=c++23
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/class/import/method.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/class/import/method.carbon

// --- object_param_qualifiers.h

struct HasQualifiers {
  void plain();
  void const_this() const;
  void volatile_this() volatile;

  void ref_this() &;
  void const_ref_this() const&;

  void ref_ref_this() &&;
  void const_ref_ref_this() const&&;
};

// --- use_object_param_qualifiers.carbon

library "[[@TEST_NAME]]";

import Cpp library "object_param_qualifiers.h";

fn Make() -> Cpp.HasQualifiers;

fn F(v: Cpp.HasQualifiers, p: Cpp.HasQualifiers*) {
  //@dump-sem-ir-begin
  v.const_this();
  v.const_ref_this();
  v.const_ref_ref_this();

  p->plain();
  p->ref_this();
  p->const_this();
  p->const_ref_this();

  Make().plain();
  Make().const_this();
  Make().const_ref_this();
  Make().ref_ref_this();
  Make().const_ref_ref_this();
  //@dump-sem-ir-end
}

// --- fail_bad_object_param_qualifiers_by_value.carbon

library "[[@TEST_NAME]]";

import Cpp library "object_param_qualifiers.h";

fn Value(v: Cpp.HasQualifiers) {
  v.plain();

  // TODO: This should remain invalid once we support `volatile`.
  v.volatile_this();

  v.ref_this();

  v.ref_ref_this();
}

// --- fail_todo_bad_object_param_qualifiers_by_ref.carbon

library "[[@TEST_NAME]]";

import Cpp library "object_param_qualifiers.h";

fn Ref(p: Cpp.HasQualifiers*) {
  // TODO: This should eventually be accepted if we support `volatile`.
  p->volatile_this();
}

// --- fail_bad_object_param_qualifiers_ref_ref.carbon

library "[[@TEST_NAME]]";

import Cpp library "object_param_qualifiers.h";

fn Ref(p: Cpp.HasQualifiers*) {
  p->ref_ref_this();

  p->const_ref_ref_this();
}

// --- fail_bad_object_param_qualifiers_for_temporary.carbon

library "[[@TEST_NAME]]";

import Cpp library "object_param_qualifiers.h";

fn Make() -> Cpp.HasQualifiers;

fn F() {
  Make().ref_this();
}

// --- object_param_qualifiers_overloaded.h

struct NoRefQualifier {
  int* _Nonnull F();
  int F() const;
  void F() volatile;
};

struct WithRefQualifier {
  int* _Nonnull F() &;
  int F() const &;
  void F() volatile &;
};

// --- use_object_param_qualifiers_overloaded.carbon

library "[[@TEST_NAME]]";

import Cpp library "object_param_qualifiers_overloaded.h";

fn CallFNoRefQualifier(v: Cpp.NoRefQualifier, p: Cpp.NoRefQualifier*) {
  //@dump-sem-ir-begin
  var unused a: i32 = v.F();
  var unused b: i32* = p->F();
  //@dump-sem-ir-end
}

fn CallFWithRefQualifier(v: Cpp.WithRefQualifier, p: Cpp.WithRefQualifier*) {
  //@dump-sem-ir-begin
  var unused a: i32 = v.F();
  var unused b: i32* = p->F();
  //@dump-sem-ir-end
}

// --- explicit_object_param.h

struct Another {
};

struct ExplicitObjectParam {
  void F(this ExplicitObjectParam);
  void G(this int);
  void H(this Another);
};

// --- call_explicit_object_param.carbon

library "[[@TEST_NAME]]";

import Cpp library "explicit_object_param.h";

fn Call(e: Cpp.ExplicitObjectParam, n: i32, a: Cpp.Another) {
  //@dump-sem-ir-begin
  e.F();
  n.(Cpp.ExplicitObjectParam.G)();
  a.(Cpp.ExplicitObjectParam.H)();
  //@dump-sem-ir-end
}

// --- fail_call_explicit_object_param_with_unsupported_type_param.carbon

library "[[@TEST_NAME]]";

import Cpp inline '''
struct ExplicitObjectParamUnsupported {
  void F(this ExplicitObjectParamUnsupported, _BitInt(23) x);
};
''';

fn Call(e: Cpp.ExplicitObjectParamUnsupported) {
  e.(Cpp.ExplicitObjectParamUnsupported.F)(1);
}

// --- explicit_object_param_overloaded.h

struct AnotherOverloaded {
};

struct ExplicitObjectParamOverloaded {
  void F(this ExplicitObjectParamOverloaded);
  void F(this int);
  void F(this AnotherOverloaded);
};

// --- call_explicit_object_param_overloaded.carbon

library "[[@TEST_NAME]]";

import Cpp library "explicit_object_param_overloaded.h";

fn Call(e: Cpp.ExplicitObjectParamOverloaded, n: i32, a: Cpp.AnotherOverloaded) {
  //@dump-sem-ir-begin
  e.F();
  n.(Cpp.ExplicitObjectParamOverloaded.F)();
  a.(Cpp.ExplicitObjectParamOverloaded.F)();
  //@dump-sem-ir-end
}
