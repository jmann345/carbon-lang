// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --dump-sem-ir-ranges=only
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/function/overload/default_values.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/function/overload/default_values.carbon

// `overload fn` members with default parameter values (fork/overload/ov4-plan.md
// OV-4, W-341). A member accepts a call that supplies from its parameter count
// less its trailing defaulted parameters up to its parameter count, exactly as
// the ordinary call of the same function does (`default_value_arity`); the
// resolution probe converts only the supplied arguments, and the committed
// ordinary call fills each omitted parameter with its default value. Between
// two members that both accept a call, the first in declaration order is
// selected (D-OV-4): a default is not a ranking criterion.

// --- omitted_and_supplied.carbon

library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
overload fn Scale(x: i32, factor: i32 = 10) -> i32 { return x * factor; }
overload fn Scale(unused b: bool) -> i32 { return 0; }

// `Scale(1)` omits `factor`: member 0 accepts one or two arguments, and the
// committed call passes the default `10`. `Scale(2, 3)` supplies it.
fn Use() -> i32 { return Scale(1) + Scale(2, 3); }
//@dump-sem-ir-end

// --- all_defaulted.carbon

library "[[@TEST_NAME]]";

overload fn Count(a: i32 = 1, b: i32 = 2) -> i32 { return a + b; }
overload fn Count(unused flag: bool) -> i32 { return 0; }

// Member 0 accepts zero, one or two arguments; `Count(true)` is rejected by
// member 0's conversion probe of its one supplied argument and selects
// member 1.
//@dump-sem-ir-begin
fn Use() -> i32 { return Count() + Count(5) + Count(5, 6) + Count(true); }
//@dump-sem-ir-end

// --- first_member_needs_default.carbon

library "[[@TEST_NAME]]";

// Both members accept `Pick(5)`: member 0 through its default, member 1
// exactly. Declaration order decides (D-OV-4), so member 0 is selected; there
// is no ranking by exactness or by the number of defaults used.
overload fn Pick(unused x: i32, unused y: i32 = 2) -> i32 { return 1; }
overload fn Pick(unused x: i32) -> i32 { return 2; }

//@dump-sem-ir-begin
fn Use() -> i32 { return Pick(5) + Pick(5, 6); }
//@dump-sem-ir-end

// --- exact_member_first.carbon

library "[[@TEST_NAME]]";

// The reverse order: member 0 matches `Pick(5)` exactly and is selected;
// member 1 is reached only by the two-argument call.
overload fn Pick(unused x: i32) -> i32 { return 2; }
overload fn Pick(unused x: i32, unused y: i32 = 2) -> i32 { return 1; }

//@dump-sem-ir-begin
fn Use() -> i32 { return Pick(5) + Pick(5, 6); }
//@dump-sem-ir-end

// --- method_default.carbon

library "[[@TEST_NAME]]";

// The arity range is keyed on the call's receiver: through the object the
// explicit arguments after `self` count, and through the class scope the
// receiver is argument 0 (`Counter.Plus(c)`), matched against `self`.
class Counter {
  var start: i32;
  overload fn Plus(self, n: i32 = 1) -> i32 { return self.start + n; }
  overload fn Plus(unused self, unused b: bool) -> i32 { return 0; }
}

//@dump-sem-ir-begin
fn Use(c: Counter) -> i32 {
  return c.Plus() + c.Plus(5) + Counter.Plus(c) + Counter.Plus(c, 7);
}
//@dump-sem-ir-end

// --- defaulted_self_is_not_a_receiver.carbon

library "[[@TEST_NAME]]";

// A parameter named `self` that has a default value does not make a method:
// the function has no `self` parameter, so `c.P()` binds no receiver and fills
// `self` from its default. A set treats such a member as one without `self`,
// exactly as the ordinary call does (D-OV4-8), beside the selfless `M(b)`.
class C {
  fn P(self: i32 = 1) -> i32 { return self; }
  overload fn M(self: i32 = 1) -> i32 { return self; }
  overload fn M(unused b: bool) -> i32 { return -1; }
}

//@dump-sem-ir-begin
fn Use(c: C) -> i32 {
  return c.P() + C.M() + C.M(4) + c.M() + C.M(true);
}
//@dump-sem-ir-end

// --- generic_class_member_default.carbon

library "[[@TEST_NAME]]";

// A set in a generic class: the members are non-generic within the specific
// (the enclosing specific supplies the class's bindings), so the defaulted
// member is selected and filled as in a non-generic scope.
class Box(T: type) {
  overload fn Get(y: i32 = 2) -> i32 { return y; }
  overload fn Get(unused b: bool) -> i32 { return -1; }
}

//@dump-sem-ir-begin
fn Use() -> i32 { return Box(bool).Get() + Box(bool).Get(9); }
//@dump-sem-ir-end

// --- template_dependent_default.carbon

library "[[@TEST_NAME]]";

overload fn F(unused x: i32, unused y: i32 = 2) -> i32 { return 1; }
overload fn F(unused b: bool) -> i32 { return 2; }

// The call is deferred at the definition and resolved for each specific; at
// instantiation the arity rule admits the one-argument call for member 0.
fn T(template U: type, u: U) -> i32 { return F(u); }

//@dump-sem-ir-begin
fn Use() -> i32 { return T(i32, 1) + T(bool, true); }
//@dump-sem-ir-end

// --- redecl_same_default.carbon

library "[[@TEST_NAME]]";

// A forward declaration and a definition with the same default are one member.
overload fn F(x: i32, y: i32 = 2) -> i32;
overload fn F(unused b: bool) -> i32 { return -1; }
overload fn F(x: i32, y: i32 = 2) -> i32 { return x * 10 + y; }

//@dump-sem-ir-begin
fn Use() -> i32 { return F(1); }
//@dump-sem-ir-end

// --- fail_redecl_default_differs.carbon

library "[[@TEST_NAME]]";

// Member identity is parameter-type equality (D-OV-3) and a default value is
// not part of a parameter's type: each second declaration redeclares the
// type-equal member, and the ordinary redeclaration check diagnoses the
// differing default, rather than forming a member no call could reach. The
// `F` and `G` pairs are the design page's example, spelled as it spells them
// (rulebook R27).
overload fn F(x: i32, y: i32 = 2);
overload fn F(x: i32, y: i32);

overload fn G(x: i32, y: i32 = 2);
overload fn G(x: i32, y: i32 = 3);

overload fn H(x: i32, y: i32 = 2) -> i32;
overload fn H(x: i32, y: i32) -> i32 { return x + y; }

// --- fail_too_few.carbon

library "[[@TEST_NAME]]";

overload fn F(unused x: i32, unused y: i32 = 2) -> i32 { return 1; }
overload fn F(unused b: bool) -> i32 { return 2; }

// Below member 0's minimum of one argument: every member is rejected by the
// arity step.
fn Use() -> i32 { return F(); }

// --- fail_supplied_argument_rejected.carbon

library "[[@TEST_NAME]]";

overload fn F(unused x: i32, unused y: i32 = 2) -> i32 { return 1; }
overload fn F(unused b: bool, unused c: bool) -> i32 { return 2; }

// Member 0 admits one argument but its supplied argument does not convert;
// member 1 needs two.
fn Use() -> i32 { return F(true); }

// --- fail_default_not_trailing.carbon

library "[[@TEST_NAME]]";

// A declaration whose default is not trailing is diagnosed and counts only
// the defaults after its last parameter that has none: a call that omits an
// argument for a parameter with no default is an arity mismatch, for a set
// member and for a plain function alike, and a call that omits only trailing
// defaulted arguments is still accepted (`Q(5, 6)`). The parameter without a
// default may be a tuple pattern: `R((1, 2))` is a mismatch too.
overload fn F(unused x: i32 = 1, unused y: i32) -> i32 { return 1; }
overload fn F(unused b: bool) -> i32 { return 2; }

fn P(unused x: i32 = 1, unused y: i32) -> i32 { return 1; }

fn Q(x: i32 = 1, y: i32, z: i32 = 3) -> i32 { return x + y + z; }

fn R(x: i32 = 1, (a: i32, b: i32), z: i32 = 3) -> i32 { return x + a + b + z; }

fn Use() -> i32 { return F(5) + P(5) + Q(5, 6) + Q(5) + R((1, 2)); }

// --- fail_todo_non_value_default.carbon

library "[[@TEST_NAME]]";

// D-OV-6 gate (iii) looks through a default value to the parameter it wraps:
// a defaulted `var` parameter or a defaulted tuple pattern is still a
// non-value explicit parameter.
overload fn F(unused x: i32, var y: i32 = 2) -> i32 { return y; }
overload fn G(x: i32, (a: i32, b: i32) = (3, 4)) -> i32 { return x + a + b; }

// --- fail_template_default_specific.carbon

library "[[@TEST_NAME]]";

// A default value whose type is template-dependent is converted in each
// specific of the member's declaration, as it is for the ordinary call of the
// same function, whose `Box(bool)` declaration fails to monomorphize even when
// the call supplies `y`. Substitution failure is an error (proposal p2200, no
// SFINAE): resolution forms the specific of each member it reaches, in
// declaration order, so `Box(bool).Get()` is diagnosed at member 0 and does
// not fall through to member 1. A member that resolution never reaches is
// never substituted: `Box2(bool).Get()` selects its member 0 first.
class Box(template T: type) {
  overload fn Get(unused y: T = 0) -> i32 { return 1; }
  overload fn Get() -> i32 { return 2; }
}

class Box2(template T: type) {
  overload fn Get() -> i32 { return 2; }
  overload fn Get(unused y: T = 0) -> i32 { return 1; }
}

fn Use() -> i32 {
  return Box(i32).Get() + Box(bool).Get() + Box2(bool).Get() + Box2(i32).Get(5);
}

// --- fail_todo_generic_member_default.carbon

library "[[@TEST_NAME]]";

// TODO(UA-3, W-360): a generic member's defaulted non-generic parameter is
// supplied to deduction by upstream 503f09037, which this trunk predates.
// Until then deduction against a short argument list deduces nothing, so the
// set rejects the member with the deduction reason exactly where the plain
// call of the same generic function fails to deduce.
overload fn G[T: type](unused x: T, y: i32 = 2) -> i32 { return y; }

fn P[T: type](unused x: T, y: i32 = 2) -> i32 { return y; }

fn Use() -> i32 { return G(true, 5) + G(true) + P(true); }

// --- import_lib.carbon

library "[[@TEST_NAME]]";

overload fn F(x: i32, y: i32 = 2) -> i32 { return x * 10 + y; }
overload fn F(unused b: bool) -> i32 { return -1; }

// --- import_use.carbon

library "[[@TEST_NAME]]";

import library "import_lib";

// The imported member carries its `default_value_arity` and its default value
// pattern, so the set accepts the omitted argument through an import.
//@dump-sem-ir-begin
fn Use() -> i32 { return F(1) + F(1, 5); }
//@dump-sem-ir-end
