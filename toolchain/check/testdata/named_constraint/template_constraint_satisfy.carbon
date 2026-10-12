// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/named_constraint/template_constraint_satisfy.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/named_constraint/template_constraint_satisfy.carbon

// Structural satisfaction of `template constraint` member requirements (fork
// decision F-010 / SC-1, fork/structural/plan.md D-SC-4, D-SC-5): a type
// satisfies the constraint through its OWN members, with no `impl`. The facet
// value carries no witnesses.

// --- method.carbon
library "[[@TEST_NAME]]";

template constraint HasGet {
  fn Get(self) -> i32;
}

class C {
  fn Get(self) -> i32 { return 1; }
}

fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }

//@dump-sem-ir-begin
fn Test(c: C) -> i32 { return CallGet(c); }
//@dump-sem-ir-end

// --- ref_self.carbon
library "[[@TEST_NAME]]";

// A `ref self` requirement is satisfied by a `ref self` method, called on a
// `var` through a pointer.
template constraint HasGet {
  fn Get(ref self) -> i32;
}

class C {
  fn Get(ref self) -> i32 { return 1; }
}

fn CallGet[template T: HasGet](p: T*) -> i32 { return p->Get(); }

fn Test() -> i32 {
  var c: C = {};
  return CallGet(&c);
}

// --- assoc_fn.carbon
library "[[@TEST_NAME]]";

// An associated-function requirement (no `self`), satisfied by a class
// function whose return type is the class (`Self := C`).
template constraint HasMake {
  fn Make() -> Self;
}

class C {
  fn Make() -> C { return {}; }
}

fn MakeIt(template T: HasMake) -> T { return T.Make(); }

fn Test() -> C { return MakeIt(C); }

// --- alias_member.carbon
library "[[@TEST_NAME]]";

// p002200's class `D`: an `alias` of an interface member resolves through the
// class's own `impl` to the impl's function, which satisfies the requirement
// (review fold A10: the member is an `ImplWitnessAccess`, not a `FunctionDecl`).
interface A {
  fn F(self);
}

template constraint HasF {
  fn F(self);
}

class D {
  impl as A {
    fn F(self) {}
  }
  alias F = A.F;
}

fn CallF[template T: HasF](x: T) { x.F(); }

fn Test(d: D) { CallF(d); }

// --- class_param.carbon
library "[[@TEST_NAME]]";

// The class-parameter site: the conversion of the class argument runs the
// check (review fold B6).
template constraint HasGet {
  fn Get(self) -> i32;
}

class C {
  fn Get(self) -> i32 { return 1; }
}

class Box(template T: HasGet) {
  fn Call(self, x: T) -> i32 { return x.Get(); }
}

//@dump-sem-ir-begin
fn Test(c: C) -> i32 {
  var b: Box(C) = {};
  return b.Call(c);
}
//@dump-sem-ir-end

// --- generic_self.carbon
library "[[@TEST_NAME]]";

// A member of a GENERIC class specific (commit-2 review, MAJOR finding):
// `Box(i32).Get` declares `self: Box(T)`, and the matcher reads it in the
// member's enclosing specific so that it equals the requirement's
// `Self := Box(i32)`. Spelling from class/method/generic_method.carbon.
template constraint HasGet {
  fn Get(self) -> i32;
}

class Box(T: type) {
  fn Get(self) -> i32 { return 1; }
}

fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }

fn Test(b: Box(i32)) -> i32 { return CallGet(b); }
