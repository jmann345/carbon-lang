// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/primitives.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/class/import/base.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/class/import/base.carbon

// --- derived_to_base_conversion.h

class Base {};
class Derived : public Base {};

// --- use_derived_to_base_conversion.carbon

library "[[@TEST_NAME]]";

import Cpp library "derived_to_base_conversion.h";

//@dump-sem-ir-begin
fn ConvertPtr(d: Cpp.Derived*) -> Cpp.Base* {
  return d;
}
//@dump-sem-ir-end

fn AcceptVal(b: Cpp.Base);

//@dump-sem-ir-begin
fn ConvertVal(d: Cpp.Derived) {
  AcceptVal(d);
}
//@dump-sem-ir-end

// --- static_member.h

class StaticBase {
 public:
  static auto base_fn() -> void;
};

class StaticDerived : public StaticBase {
 public:
  static auto derived_fn() -> void;
};

// --- use_static_member.carbon

library "[[@TEST_NAME]]";

import Cpp library "static_member.h";

fn MyF() {
  //@dump-sem-ir-begin
  Cpp.StaticBase.base_fn();
  Cpp.StaticDerived.base_fn();
  Cpp.StaticDerived.derived_fn();
  //@dump-sem-ir-end
}

// --- base_field.h

struct FieldBase {
  int a;
  int b;
};

struct FieldDerived : FieldBase {
  int b;
};

// --- use_base_field.carbon

library "[[@TEST_NAME]]";

import Cpp library "base_field.h";

fn AccessDirect(d: Cpp.FieldDerived) -> i32 {
  //@dump-sem-ir-begin
  return d.a;
  //@dump-sem-ir-end
}

fn AccessQualified(d: Cpp.FieldDerived) -> i32 {
  //@dump-sem-ir-begin
  return d.(Cpp.FieldBase.b);
  //@dump-sem-ir-end
}

// --- base_method.h

struct MethodBase {
  void f() const;
  void g() const;
};

struct MethodDerived : MethodBase {
  void g() const;
};

// --- use_base_method.carbon

library "[[@TEST_NAME]]";

import Cpp library "base_method.h";

fn CallDirect(d: Cpp.MethodDerived) {
  //@dump-sem-ir-begin
  d.f();
  //@dump-sem-ir-end
}

fn CallQualified(d: Cpp.MethodDerived) {
  //@dump-sem-ir-begin
  d.(Cpp.MethodBase.g)();
  //@dump-sem-ir-end
}

fn CallBaseQualifiedByDerived(d: Cpp.MethodDerived, b: Cpp.MethodBase) {
  //@dump-sem-ir-begin
  // `Cpp.MethodDerived.f` names a member of `Cpp.MethodBase`, so we allow
  // that to be used when `self` is a `Cpp.MethodBase` or anything that
  // implicitly converts to `Cpp.MethodBase`, such as `Cpp.MethodDerived`.
  d.(Cpp.MethodDerived.f)();
  b.(Cpp.MethodDerived.f)();
  //@dump-sem-ir-end
}

// --- multiple_inheritance.h

struct A { int a; };
struct B { int b; };
struct C : A, B {};

struct Empty1 {};
struct Empty2 {};
struct OneNonEmptyBase : Empty1, A, Empty2 {};
struct TwoNonEmptyBases : Empty1, A, B, Empty2 {};

struct Polymorphic1 {
  virtual void f();
};
struct Polymorphic2 {
  virtual void g();
};
struct OnePolymorphicBase : A, B, Polymorphic1, Empty1 {};
struct TwoPolymorphicBases : Polymorphic1, Polymorphic2 {};

// --- fail_todo_use_multiple_inheritance.carbon

library "[[@TEST_NAME]]";

import Cpp library "multiple_inheritance.h";

fn ConvertA(p: Cpp.C*) -> Cpp.A* {
  return p;
}

fn ConvertB(p: Cpp.C*) -> Cpp.B* {
  return p;
}

fn ConvertOneNonEmptyBaseToEmpty1(p: Cpp.OneNonEmptyBase*) -> Cpp.Empty1* {
  return p;
}

fn ConvertOneNonEmptyBaseToEmpty2(p: Cpp.OneNonEmptyBase*) -> Cpp.Empty2* {
  return p;
}

fn ConvertTwoNonEmptyBasesToA(p: Cpp.TwoNonEmptyBases*) -> Cpp.A* {
  return p;
}

fn ConvertTwoNonEmptyBasesToB(p: Cpp.TwoNonEmptyBases*) -> Cpp.B* {
  return p;
}

fn ConvertOnePolymorphicBaseToA(p: Cpp.OnePolymorphicBase*) -> Cpp.A* {
  return p;
}

fn ConvertOnePolymorphicBaseToB(p: Cpp.OnePolymorphicBase*) -> Cpp.B* {
  return p;
}

fn ConvertTwoPolymorphicBasesToPolymorphic1(p: Cpp.TwoPolymorphicBases*) -> Cpp.Polymorphic1* {
  return p;
}

fn ConvertTwoPolymorphicBasesToPolymorphic2(p: Cpp.TwoPolymorphicBases*) -> Cpp.Polymorphic2* {
  return p;
}

// --- multiple_inheritance_with_preferred_base.carbon

library "[[@TEST_NAME]]";

import Cpp library "multiple_inheritance.h";

// If there's only one non-empty base, that's our preferred base class. We can
// convert to that.
fn ConvertOneNonEmptyBaseToA(p: Cpp.OneNonEmptyBase*) -> Cpp.A* {
  return p;
}

// If there's only one polymorphic base, that's our preferred base class. We can
// convert to that.
fn ConvertOnePolymorphicBaseToPolymorphic1(p: Cpp.OnePolymorphicBase*) -> Cpp.Polymorphic1* {
  return p;
}

// --- virtual_inheritance.h

struct VirtA { int a; };
struct VirtB : virtual VirtA {};

void UseB(VirtB * _Nonnull p);

// --- use_virtual_inheritance_incomplete.carbon

library "[[@TEST_NAME]]";

import Cpp library "virtual_inheritance.h";

fn Convert(p: Cpp.VirtB*) {
  // OK, doesn't require `Cpp.VirtB` to be a complete type.
  Cpp.UseB(p);
}

// --- fail_todo_use_virtual_inheritance.carbon

library "[[@TEST_NAME]]";

import Cpp library "virtual_inheritance.h";

fn Convert(p: Cpp.VirtB*) -> Cpp.VirtA* {
  return p;
}

// --- diamond.h

struct DiamondA {
  int a;
};

struct DiamondB : virtual DiamondA {
  int b;
};

struct DiamondC : virtual DiamondA {
  int c;
};

struct DiamondD : DiamondB, DiamondC {
  int d;
};

// --- fail_todo_use_diamond.carbon

library "[[@TEST_NAME]]";

import Cpp library "diamond.h";

fn ConvertBA(p: Cpp.DiamondB*) -> Cpp.DiamondA* {
  return p;
}

fn ConvertCA(p: Cpp.DiamondC*) -> Cpp.DiamondA* {
  return p;
}

fn ConvertDB(p: Cpp.DiamondD*) -> Cpp.DiamondB* {
  return p;
}

fn ConvertDC(p: Cpp.DiamondD*) -> Cpp.DiamondC* {
  return p;
}

fn AccessBA(d: Cpp.DiamondD) -> i32 {
  return (d as Cpp.DiamondB).b;
}

fn AccessCA(d: Cpp.DiamondD) -> i32 {
  return (d as Cpp.DiamondC).b;
}

fn AccessDB(d: Cpp.DiamondD) -> i32 {
  return d.b;
}

fn AccessDC(d: Cpp.DiamondD) -> i32 {
  return d.c;
}

// --- final.h

struct FinalA final {};

// --- fail_derive_from_final.carbon

library "[[@TEST_NAME]]";

import Cpp library "final.h";

class B {
  extend base: Cpp.FinalA;
}

// --- union.h

union U {};

// --- fail_derive_from_union.carbon

library "[[@TEST_NAME]]";

import Cpp library "union.h";

class V {
  extend base: Cpp.U;
}
