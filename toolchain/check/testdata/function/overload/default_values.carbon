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
// CHECK:STDERR: fail_redecl_default_differs.carbon:[[@LINE+7]]:23: error: redeclaration differs at parameter 2 [RedeclParamDiffers]
// CHECK:STDERR: overload fn F(x: i32, y: i32);
// CHECK:STDERR:                       ^~~~~~
// CHECK:STDERR: fail_redecl_default_differs.carbon:[[@LINE-4]]:23: note: previous declaration's corresponding parameter here [RedeclParamPrevious]
// CHECK:STDERR: overload fn F(x: i32, y: i32 = 2);
// CHECK:STDERR:                       ^~~~~~~~~~
// CHECK:STDERR:
overload fn F(x: i32, y: i32);

overload fn G(x: i32, y: i32 = 2);
// CHECK:STDERR: fail_redecl_default_differs.carbon:[[@LINE+7]]:23: error: redeclaration differs at parameter 2 [RedeclParamDiffers]
// CHECK:STDERR: overload fn G(x: i32, y: i32 = 3);
// CHECK:STDERR:                       ^~~~~~~~~~
// CHECK:STDERR: fail_redecl_default_differs.carbon:[[@LINE-4]]:23: note: previous declaration's corresponding parameter here [RedeclParamPrevious]
// CHECK:STDERR: overload fn G(x: i32, y: i32 = 2);
// CHECK:STDERR:                       ^~~~~~~~~~
// CHECK:STDERR:
overload fn G(x: i32, y: i32 = 3);

overload fn H(x: i32, y: i32 = 2) -> i32;
// CHECK:STDERR: fail_redecl_default_differs.carbon:[[@LINE+7]]:23: error: redeclaration differs at parameter 2 [RedeclParamDiffers]
// CHECK:STDERR: overload fn H(x: i32, y: i32) -> i32 { return x + y; }
// CHECK:STDERR:                       ^~~~~~
// CHECK:STDERR: fail_redecl_default_differs.carbon:[[@LINE-4]]:23: note: previous declaration's corresponding parameter here [RedeclParamPrevious]
// CHECK:STDERR: overload fn H(x: i32, y: i32 = 2) -> i32;
// CHECK:STDERR:                       ^~~~~~~~~~
// CHECK:STDERR:
overload fn H(x: i32, y: i32) -> i32 { return x + y; }

// --- fail_too_few.carbon

library "[[@TEST_NAME]]";

overload fn F(unused x: i32, unused y: i32 = 2) -> i32 { return 1; }
overload fn F(unused b: bool) -> i32 { return 2; }

// Below member 0's minimum of one argument: every member is rejected by the
// arity step.
// CHECK:STDERR: fail_too_few.carbon:[[@LINE+10]]:26: error: no member of overload set `F` accepts this call [OverloadNoMatch]
// CHECK:STDERR: fn Use() -> i32 { return F(); }
// CHECK:STDERR:                          ^~~
// CHECK:STDERR: fail_too_few.carbon:[[@LINE-8]]:1: note: candidate takes a different number of arguments [OverloadCandidateRejected]
// CHECK:STDERR: overload fn F(unused x: i32, unused y: i32 = 2) -> i32 { return 1; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_too_few.carbon:[[@LINE-10]]:1: note: candidate takes a different number of arguments [OverloadCandidateRejected]
// CHECK:STDERR: overload fn F(unused b: bool) -> i32 { return 2; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn Use() -> i32 { return F(); }

// --- fail_supplied_argument_rejected.carbon

library "[[@TEST_NAME]]";

overload fn F(unused x: i32, unused y: i32 = 2) -> i32 { return 1; }
overload fn F(unused b: bool, unused c: bool) -> i32 { return 2; }

// Member 0 admits one argument but its supplied argument does not convert;
// member 1 needs two.
// CHECK:STDERR: fail_supplied_argument_rejected.carbon:[[@LINE+10]]:26: error: no member of overload set `F` accepts this call [OverloadNoMatch]
// CHECK:STDERR: fn Use() -> i32 { return F(true); }
// CHECK:STDERR:                          ^~~~~~~
// CHECK:STDERR: fail_supplied_argument_rejected.carbon:[[@LINE-8]]:1: note: candidate has a parameter its argument cannot implicitly convert to [OverloadCandidateRejected]
// CHECK:STDERR: overload fn F(unused x: i32, unused y: i32 = 2) -> i32 { return 1; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_supplied_argument_rejected.carbon:[[@LINE-10]]:1: note: candidate takes a different number of arguments [OverloadCandidateRejected]
// CHECK:STDERR: overload fn F(unused b: bool, unused c: bool) -> i32 { return 2; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn Use() -> i32 { return F(true); }

// --- fail_default_not_trailing.carbon

library "[[@TEST_NAME]]";

// A declaration whose default is not trailing is diagnosed and counts only
// the defaults after its last parameter that has none: a call that omits an
// argument for a parameter with no default is an arity mismatch, for a set
// member and for a plain function alike, and a call that omits only trailing
// defaulted arguments is still accepted (`Q(5, 6)`). The parameter without a
// default may be a tuple pattern: `R((1, 2))` is a mismatch too.
// CHECK:STDERR: fail_default_not_trailing.carbon:[[@LINE+7]]:41: error: this pattern is missing a required default value. [RequiredPatternDefaultValueMissing]
// CHECK:STDERR: overload fn F(unused x: i32 = 1, unused y: i32) -> i32 { return 1; }
// CHECK:STDERR:                                         ^~~~~~
// CHECK:STDERR: fail_default_not_trailing.carbon:[[@LINE+4]]:22: note: all patterns to the right of this first pattern with a default value must also specify a default value. [RequiredPatternDefaultValueFirstDefault]
// CHECK:STDERR: overload fn F(unused x: i32 = 1, unused y: i32) -> i32 { return 1; }
// CHECK:STDERR:                      ^~~~~~
// CHECK:STDERR:
overload fn F(unused x: i32 = 1, unused y: i32) -> i32 { return 1; }
overload fn F(unused b: bool) -> i32 { return 2; }

// CHECK:STDERR: fail_default_not_trailing.carbon:[[@LINE+7]]:32: error: this pattern is missing a required default value. [RequiredPatternDefaultValueMissing]
// CHECK:STDERR: fn P(unused x: i32 = 1, unused y: i32) -> i32 { return 1; }
// CHECK:STDERR:                                ^~~~~~
// CHECK:STDERR: fail_default_not_trailing.carbon:[[@LINE+4]]:13: note: all patterns to the right of this first pattern with a default value must also specify a default value. [RequiredPatternDefaultValueFirstDefault]
// CHECK:STDERR: fn P(unused x: i32 = 1, unused y: i32) -> i32 { return 1; }
// CHECK:STDERR:             ^~~~~~
// CHECK:STDERR:
fn P(unused x: i32 = 1, unused y: i32) -> i32 { return 1; }

// CHECK:STDERR: fail_default_not_trailing.carbon:[[@LINE+7]]:18: error: this pattern is missing a required default value. [RequiredPatternDefaultValueMissing]
// CHECK:STDERR: fn Q(x: i32 = 1, y: i32, z: i32 = 3) -> i32 { return x + y + z; }
// CHECK:STDERR:                  ^~~~~~
// CHECK:STDERR: fail_default_not_trailing.carbon:[[@LINE+4]]:6: note: all patterns to the right of this first pattern with a default value must also specify a default value. [RequiredPatternDefaultValueFirstDefault]
// CHECK:STDERR: fn Q(x: i32 = 1, y: i32, z: i32 = 3) -> i32 { return x + y + z; }
// CHECK:STDERR:      ^~~~~~
// CHECK:STDERR:
fn Q(x: i32 = 1, y: i32, z: i32 = 3) -> i32 { return x + y + z; }

// CHECK:STDERR: fail_default_not_trailing.carbon:[[@LINE+7]]:18: error: this pattern is missing a required default value. [RequiredPatternDefaultValueMissing]
// CHECK:STDERR: fn R(x: i32 = 1, (a: i32, b: i32), z: i32 = 3) -> i32 { return x + a + b + z; }
// CHECK:STDERR:                  ^~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_default_not_trailing.carbon:[[@LINE+4]]:6: note: all patterns to the right of this first pattern with a default value must also specify a default value. [RequiredPatternDefaultValueFirstDefault]
// CHECK:STDERR: fn R(x: i32 = 1, (a: i32, b: i32), z: i32 = 3) -> i32 { return x + a + b + z; }
// CHECK:STDERR:      ^~~~~~
// CHECK:STDERR:
fn R(x: i32 = 1, (a: i32, b: i32), z: i32 = 3) -> i32 { return x + a + b + z; }

// CHECK:STDERR: fail_default_not_trailing.carbon:[[@LINE+31]]:26: error: no member of overload set `F` accepts this call [OverloadNoMatch]
// CHECK:STDERR: fn Use() -> i32 { return F(5) + P(5) + Q(5, 6) + Q(5) + R((1, 2)); }
// CHECK:STDERR:                          ^~~~
// CHECK:STDERR: fail_default_not_trailing.carbon:[[@LINE-33]]:1: note: candidate takes a different number of arguments [OverloadCandidateRejected]
// CHECK:STDERR: overload fn F(unused x: i32 = 1, unused y: i32) -> i32 { return 1; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_default_not_trailing.carbon:[[@LINE-35]]:1: note: candidate has a parameter its argument cannot implicitly convert to [OverloadCandidateRejected]
// CHECK:STDERR: overload fn F(unused b: bool) -> i32 { return 2; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: fail_default_not_trailing.carbon:[[@LINE+21]]:33: error: 1 argument passed to function expecting 2 arguments [CallArgCountMismatch]
// CHECK:STDERR: fn Use() -> i32 { return F(5) + P(5) + Q(5, 6) + Q(5) + R((1, 2)); }
// CHECK:STDERR:                                 ^~~~
// CHECK:STDERR: fail_default_not_trailing.carbon:[[@LINE-33]]:1: note: calling function declared here [InCallToEntity]
// CHECK:STDERR: fn P(unused x: i32 = 1, unused y: i32) -> i32 { return 1; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: fail_default_not_trailing.carbon:[[@LINE+14]]:50: error: 1 argument passed to function expecting 3 arguments [CallArgCountMismatch]
// CHECK:STDERR: fn Use() -> i32 { return F(5) + P(5) + Q(5, 6) + Q(5) + R((1, 2)); }
// CHECK:STDERR:                                                  ^~~~
// CHECK:STDERR: fail_default_not_trailing.carbon:[[@LINE-31]]:1: note: calling function declared here [InCallToEntity]
// CHECK:STDERR: fn Q(x: i32 = 1, y: i32, z: i32 = 3) -> i32 { return x + y + z; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: fail_default_not_trailing.carbon:[[@LINE+7]]:57: error: 1 argument passed to function expecting 3 arguments [CallArgCountMismatch]
// CHECK:STDERR: fn Use() -> i32 { return F(5) + P(5) + Q(5, 6) + Q(5) + R((1, 2)); }
// CHECK:STDERR:                                                         ^~~~~~~~~
// CHECK:STDERR: fail_default_not_trailing.carbon:[[@LINE-29]]:1: note: calling function declared here [InCallToEntity]
// CHECK:STDERR: fn R(x: i32 = 1, (a: i32, b: i32), z: i32 = 3) -> i32 { return x + a + b + z; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn Use() -> i32 { return F(5) + P(5) + Q(5, 6) + Q(5) + R((1, 2)); }

// --- fail_todo_non_value_default.carbon

library "[[@TEST_NAME]]";

// D-OV-6 gate (iii) looks through a default value to the parameter it wraps:
// a defaulted `var` parameter or a defaulted tuple pattern is still a
// non-value explicit parameter.
// CHECK:STDERR: fail_todo_non_value_default.carbon:[[@LINE+4]]:30: error: semantics TODO: ``overload fn` with a non-value explicit parameter` [SemanticsTodo]
// CHECK:STDERR: overload fn F(unused x: i32, var y: i32 = 2) -> i32 { return y; }
// CHECK:STDERR:                              ^~~~~~~~~~~~~~
// CHECK:STDERR:
overload fn F(unused x: i32, var y: i32 = 2) -> i32 { return y; }
// CHECK:STDERR: fail_todo_non_value_default.carbon:[[@LINE+4]]:23: error: semantics TODO: ``overload fn` with a non-value explicit parameter` [SemanticsTodo]
// CHECK:STDERR: overload fn G(x: i32, (a: i32, b: i32) = (3, 4)) -> i32 { return x + a + b; }
// CHECK:STDERR:                       ^~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
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
  // CHECK:STDERR: fail_template_default_specific.carbon:[[@LINE+10]]:27: error: unable to monomorphize specific `Get(bool)` [ResolvingSpecificHere]
  // CHECK:STDERR:   return Box(i32).Get() + Box(bool).Get() + Box2(bool).Get() + Box2(i32).Get(5);
  // CHECK:STDERR:                           ^~~~~~~~~~~~~~~
  // CHECK:STDERR: fail_template_default_specific.carbon:[[@LINE-13]]:33: note: cannot implicitly convert expression of type `Core.IntLiteral` to `bool` [ConversionFailure]
  // CHECK:STDERR:   overload fn Get(unused y: T = 0) -> i32 { return 1; }
  // CHECK:STDERR:                                 ^
  // CHECK:STDERR: fail_template_default_specific.carbon:[[@LINE-16]]:33: note: type `Core.IntLiteral` does not implement interface `Core.ImplicitAs(bool)` [MissingImplInMemberAccessInContext]
  // CHECK:STDERR:   overload fn Get(unused y: T = 0) -> i32 { return 1; }
  // CHECK:STDERR:                                 ^
  // CHECK:STDERR:
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

// CHECK:STDERR: fail_todo_generic_member_default.carbon:[[@LINE+14]]:39: error: no member of overload set `G` accepts this call [OverloadNoMatch]
// CHECK:STDERR: fn Use() -> i32 { return G(true, 5) + G(true) + P(true); }
// CHECK:STDERR:                                       ^~~~~~~
// CHECK:STDERR: fail_todo_generic_member_default.carbon:[[@LINE-7]]:1: note: candidate has generic parameters that could not be deduced [OverloadCandidateRejected]
// CHECK:STDERR: overload fn G[T: type](unused x: T, y: i32 = 2) -> i32 { return y; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: fail_todo_generic_member_default.carbon:[[@LINE+7]]:49: error: cannot deduce value for generic parameter `T` [DeductionIncomplete]
// CHECK:STDERR: fn Use() -> i32 { return G(true, 5) + G(true) + P(true); }
// CHECK:STDERR:                                                 ^~~~~~~
// CHECK:STDERR: fail_todo_generic_member_default.carbon:[[@LINE-12]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
// CHECK:STDERR: fn P[T: type](unused x: T, y: i32 = 2) -> i32 { return y; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
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

// CHECK:STDOUT: --- omitted_and_supplied.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %x.param_patt: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %x.patt: %pattern_type.6b6 = wrapper_binding_pattern x, %x.param_patt [concrete]
// CHECK:STDOUT:   %factor.param_patt: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %factor.patt: %pattern_type.6b6 = wrapper_binding_pattern factor, %factor.param_patt [concrete]
// CHECK:STDOUT:   %int_10.64f: Core.IntLiteral = int_value 10 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %To: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.dcb: <bound method> = bound_method %int_10.64f, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.1b6: <bound method> = bound_method %int_10.64f, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_10.6bf: %i32 = int_value 10 [concrete]
// CHECK:STDOUT:   %.0a4: %pattern_type.6b6 = default_value_pattern %factor.patt, %int_10.6bf [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %Scale.type.972766.1: type = fn_type @Scale.loc5 [concrete]
// CHECK:STDOUT:   %Scale.a52389.1: %Scale.type.972766.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Scale.overload_set.type: type = overload_set_type @Scale.overload_set [concrete]
// CHECK:STDOUT:   %Scale.overload_set.value: %Scale.overload_set.type = overload_set_value @Scale.overload_set [concrete]
// CHECK:STDOUT:   %MulWith.type.77d: type = facet_type <@MulWith, @MulWith(%i32)> [concrete]
// CHECK:STDOUT:   %Int.as.MulWith.impl.Op.type.110: type = fn_type @Int.as.MulWith.impl.Op.1, @Int.as.MulWith.impl.d16(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.MulWith.impl.Op.0b3: %Int.as.MulWith.impl.Op.type.110 = struct_value () [symbolic]
// CHECK:STDOUT:   %MulWith.impl_witness.2a2: <witness> = impl_witness imports.%MulWith.impl_witness_table.1e1, @Int.as.MulWith.impl.d16(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.MulWith.impl.Op.type.cb9: type = fn_type @Int.as.MulWith.impl.Op.1, @Int.as.MulWith.impl.d16(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.MulWith.impl.Op.b4e: %Int.as.MulWith.impl.Op.type.cb9 = struct_value () [concrete]
// CHECK:STDOUT:   %MulWith.facet.14b: %MulWith.type.77d = facet_value %i32, (%MulWith.impl_witness.2a2) [concrete]
// CHECK:STDOUT:   %MulWith.WithSelf.Op.type.2b2: type = fn_type @MulWith.WithSelf.Op, @MulWith.WithSelf(%i32, %MulWith.facet.14b) [concrete]
// CHECK:STDOUT:   %.4c4: type = fn_type_with_self_type %MulWith.WithSelf.Op.type.2b2, %MulWith.facet.14b [concrete]
// CHECK:STDOUT:   %Int.as.MulWith.impl.Op.specific_fn.bac: <specific function> = specific_function %Int.as.MulWith.impl.Op.b4e, @Int.as.MulWith.impl.Op.1(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.831: type = pattern_type bool [concrete]
// CHECK:STDOUT:   %b.param_patt: %pattern_type.831 = value_param_pattern [concrete]
// CHECK:STDOUT:   %b.patt: %pattern_type.831 = wrapper_binding_pattern b, %b.param_patt [concrete]
// CHECK:STDOUT:   %Scale.type.972766.2: type = fn_type @Scale.loc6 [concrete]
// CHECK:STDOUT:   %Scale.a52389.2: %Scale.type.972766.2 = struct_value () [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.6e0: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_0.3c0: %i32 = int_value 0 [concrete]
// CHECK:STDOUT:   %Use.type: type = fn_type @Use [concrete]
// CHECK:STDOUT:   %Use: %Use.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.953: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT:   %int_2.ecc: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %int_3.1ba: Core.IntLiteral = int_value 3 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.9f3: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.3cb: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_2.295: %i32 = int_value 2 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.485: <bound method> = bound_method %int_3.1ba, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.763: <bound method> = bound_method %int_3.1ba, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_3.410: %i32 = int_value 3 [concrete]
// CHECK:STDOUT:   %AddWith.type.be9: type = facet_type <@AddWith, @AddWith(%i32)> [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.610: type = fn_type @Int.as.AddWith.impl.Op.1, @Int.as.AddWith.impl.3af(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.732: %Int.as.AddWith.impl.Op.type.610 = struct_value () [symbolic]
// CHECK:STDOUT:   %AddWith.impl_witness.833: <witness> = impl_witness imports.%AddWith.impl_witness_table.6b4, @Int.as.AddWith.impl.3af(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.056: type = fn_type @Int.as.AddWith.impl.Op.1, @Int.as.AddWith.impl.3af(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.365: %Int.as.AddWith.impl.Op.type.056 = struct_value () [concrete]
// CHECK:STDOUT:   %AddWith.facet.76a: %AddWith.type.be9 = facet_value %i32, (%AddWith.impl_witness.833) [concrete]
// CHECK:STDOUT:   %AddWith.WithSelf.Op.type.02a: type = fn_type @AddWith.WithSelf.Op, @AddWith.WithSelf(%i32, %AddWith.facet.76a) [concrete]
// CHECK:STDOUT:   %.d47: type = fn_type_with_self_type %AddWith.WithSelf.Op.type.02a, %AddWith.facet.76a [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.specific_fn.f25: <specific function> = specific_function %Int.as.AddWith.impl.Op.365, @Int.as.AddWith.impl.Op.1(%int_32) [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.b4fd3a.1 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.5e5f7: @Int.as.MulWith.impl.d16.%Int.as.MulWith.impl.Op.type (%Int.as.MulWith.impl.Op.type.110) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.MulWith.impl.d16.%Int.as.MulWith.impl.Op (constants.%Int.as.MulWith.impl.Op.0b3)]
// CHECK:STDOUT:   %MulWith.impl_witness_table.1e1 = impl_witness_table (%Core.import_ref.b4fd3a.1, %Core.import_ref.5e5f7), @Int.as.MulWith.impl.d16 [concrete]
// CHECK:STDOUT:   %Core.import_ref.b4fd3a.4 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.684: @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op.type (%Int.as.AddWith.impl.Op.type.610) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op (constants.%Int.as.AddWith.impl.Op.732)]
// CHECK:STDOUT:   %AddWith.impl_witness_table.6b4 = impl_witness_table (%Core.import_ref.b4fd3a.4, %Core.import_ref.684), @Int.as.AddWith.impl.3af [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Scale.decl.loc5: %Scale.type.972766.1 = fn_decl @Scale.loc5 [concrete = constants.%Scale.a52389.1] {
// CHECK:STDOUT:     %x.param_patt: %pattern_type.6b6 = value_param_pattern [concrete = constants.%x.param_patt]
// CHECK:STDOUT:     %x.patt: %pattern_type.6b6 = wrapper_binding_pattern x, %x.param_patt [concrete = constants.%x.patt]
// CHECK:STDOUT:     %factor.param_patt: %pattern_type.6b6 = value_param_pattern [concrete = constants.%factor.param_patt]
// CHECK:STDOUT:     %factor.patt: %pattern_type.6b6 = wrapper_binding_pattern factor, %factor.param_patt [concrete = constants.%factor.patt]
// CHECK:STDOUT:     %.loc5_39: %pattern_type.6b6 = default_value_pattern %factor.patt, %.loc5_41.2 [concrete = constants.%.0a4]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc5_48 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %int_10: Core.IntLiteral = int_value 10 [concrete = constants.%int_10.64f]
// CHECK:STDOUT:     %impl.elem0: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:     %bound_method.loc5_41.1: <bound method> = bound_method %int_10, %impl.elem0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.dcb]
// CHECK:STDOUT:     %specific_fn.loc5_41: <specific function> = specific_function %impl.elem0, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:     %bound_method.loc5_41.2: <bound method> = bound_method %int_10, %specific_fn.loc5_41 [concrete = constants.%bound_method.1b6]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %i32 = call %bound_method.loc5_41.2(%int_10) [concrete = constants.%int_10.6bf]
// CHECK:STDOUT:     %.loc5_41.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_10.6bf]
// CHECK:STDOUT:     %.loc5_41.2: %i32 = converted %int_10, %.loc5_41.1 [concrete = constants.%int_10.6bf]
// CHECK:STDOUT:     %i32.loc5_48: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc5_48: Core.Form = init_form %i32.loc5_48 [concrete = constants.%.795f]
// CHECK:STDOUT:     %x.param: %i32 = value_param call_param0
// CHECK:STDOUT:     %i32.loc5_22: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %x: %i32 = wrapper_binding x, %x.param
// CHECK:STDOUT:     %factor.param: %i32 = value_param call_param1
// CHECK:STDOUT:     %i32.loc5_35: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %factor: %i32 = wrapper_binding factor, %factor.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param2
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Scale.overload_set.value: %Scale.overload_set.type = overload_set_value @Scale.overload_set [concrete = constants.%Scale.overload_set.value]
// CHECK:STDOUT:   %Scale.decl.loc6: %Scale.type.972766.2 = fn_decl @Scale.loc6 [concrete = constants.%Scale.a52389.2] {
// CHECK:STDOUT:     %b.param_patt: %pattern_type.831 = value_param_pattern [concrete = constants.%b.param_patt]
// CHECK:STDOUT:     %b.patt: %pattern_type.831 = wrapper_binding_pattern b, %b.param_patt [concrete = constants.%b.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc6_38: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %b.param: bool = value_param call_param0
// CHECK:STDOUT:     %.loc6_29: type = type_literal bool [concrete = bool]
// CHECK:STDOUT:     %b: bool = wrapper_binding b, %b.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Use.decl: %Use.type = fn_decl @Use [concrete = constants.%Use] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc10_13: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param0
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Scale.loc5(%x.param: %i32, %factor.param: %i32) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %x.ref: %i32 = name_ref x, %x
// CHECK:STDOUT:   %factor.ref: %i32 = name_ref factor, %factor
// CHECK:STDOUT:   %impl.elem1: %.4c4 = impl_witness_access constants.%MulWith.impl_witness.2a2, element1 [concrete = constants.%Int.as.MulWith.impl.Op.b4e]
// CHECK:STDOUT:   %bound_method.loc5_63.1: <bound method> = bound_method %x.ref, %impl.elem1
// CHECK:STDOUT:   %specific_fn.loc5_63: <specific function> = specific_function %impl.elem1, @Int.as.MulWith.impl.Op.1(constants.%int_32) [concrete = constants.%Int.as.MulWith.impl.Op.specific_fn.bac]
// CHECK:STDOUT:   %bound_method.loc5_63.2: <bound method> = bound_method %x.ref, %specific_fn.loc5_63
// CHECK:STDOUT:   %Int.as.MulWith.impl.Op.call: init %i32 = call %bound_method.loc5_63.2(%x.ref, %factor.ref)
// CHECK:STDOUT:   return %Int.as.MulWith.impl.Op.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Scale.loc6(%b.param: bool) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc6_52.1: <bound method> = bound_method %int_0, %impl.elem0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn: <specific function> = specific_function %impl.elem0, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc6_52.2: <bound method> = bound_method %int_0, %specific_fn [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %i32 = call %bound_method.loc6_52.2(%int_0) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc6_52: init %i32 = converted %int_0, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   return %.loc6_52
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Use() -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Scale.ref.loc10_26: %Scale.overload_set.type = name_ref Scale, file.%Scale.overload_set.value [concrete = constants.%Scale.overload_set.value]
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %Scale.ref.loc10_33: %Scale.type.972766.1 = name_ref Scale, file.%Scale.decl.loc5 [concrete = constants.%Scale.a52389.1]
// CHECK:STDOUT:   %impl.elem0.loc10_32: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc10_32.1: <bound method> = bound_method %int_1, %impl.elem0.loc10_32 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc10_32: <specific function> = specific_function %impl.elem0.loc10_32, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc10_32.2: <bound method> = bound_method %int_1, %specific_fn.loc10_32 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc10_32: init %i32 = call %bound_method.loc10_32.2(%int_1) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc10_32.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc10_32 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc10_32.2: %i32 = converted %int_1, %.loc10_32.1 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %Scale.call.loc10_33: init %i32 = call %Scale.ref.loc10_33(%.loc10_32.2, @Scale.loc5.%.loc5_41.2)
// CHECK:STDOUT:   %Scale.ref.loc10_37: %Scale.overload_set.type = name_ref Scale, file.%Scale.overload_set.value [concrete = constants.%Scale.overload_set.value]
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:   %int_3: Core.IntLiteral = int_value 3 [concrete = constants.%int_3.1ba]
// CHECK:STDOUT:   %Scale.ref.loc10_47: %Scale.type.972766.1 = name_ref Scale, file.%Scale.decl.loc5 [concrete = constants.%Scale.a52389.1]
// CHECK:STDOUT:   %impl.elem0.loc10_43: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc10_43.1: <bound method> = bound_method %int_2, %impl.elem0.loc10_43 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.9f3]
// CHECK:STDOUT:   %specific_fn.loc10_43: <specific function> = specific_function %impl.elem0.loc10_43, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc10_43.2: <bound method> = bound_method %int_2, %specific_fn.loc10_43 [concrete = constants.%bound_method.3cb]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc10_43: init %i32 = call %bound_method.loc10_43.2(%int_2) [concrete = constants.%int_2.295]
// CHECK:STDOUT:   %.loc10_43.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc10_43 [concrete = constants.%int_2.295]
// CHECK:STDOUT:   %.loc10_43.2: %i32 = converted %int_2, %.loc10_43.1 [concrete = constants.%int_2.295]
// CHECK:STDOUT:   %impl.elem0.loc10_46: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc10_46.1: <bound method> = bound_method %int_3, %impl.elem0.loc10_46 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.485]
// CHECK:STDOUT:   %specific_fn.loc10_46: <specific function> = specific_function %impl.elem0.loc10_46, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc10_46.2: <bound method> = bound_method %int_3, %specific_fn.loc10_46 [concrete = constants.%bound_method.763]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc10_46: init %i32 = call %bound_method.loc10_46.2(%int_3) [concrete = constants.%int_3.410]
// CHECK:STDOUT:   %.loc10_46.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc10_46 [concrete = constants.%int_3.410]
// CHECK:STDOUT:   %.loc10_46.2: %i32 = converted %int_3, %.loc10_46.1 [concrete = constants.%int_3.410]
// CHECK:STDOUT:   %Scale.call.loc10_47: init %i32 = call %Scale.ref.loc10_47(%.loc10_43.2, %.loc10_46.2)
// CHECK:STDOUT:   %impl.elem1: %.d47 = impl_witness_access constants.%AddWith.impl_witness.833, element1 [concrete = constants.%Int.as.AddWith.impl.Op.365]
// CHECK:STDOUT:   %bound_method.loc10_35.1: <bound method> = bound_method %Scale.call.loc10_33, %impl.elem1
// CHECK:STDOUT:   %specific_fn.loc10_35: <specific function> = specific_function %impl.elem1, @Int.as.AddWith.impl.Op.1(constants.%int_32) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.f25]
// CHECK:STDOUT:   %bound_method.loc10_35.2: <bound method> = bound_method %Scale.call.loc10_33, %specific_fn.loc10_35
// CHECK:STDOUT:   %.loc10_33.1: %i32 = value_of_initializer %Scale.call.loc10_33
// CHECK:STDOUT:   %.loc10_33.2: %i32 = converted %Scale.call.loc10_33, %.loc10_33.1
// CHECK:STDOUT:   %.loc10_47.1: %i32 = value_of_initializer %Scale.call.loc10_47
// CHECK:STDOUT:   %.loc10_47.2: %i32 = converted %Scale.call.loc10_47, %.loc10_47.1
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call: init %i32 = call %bound_method.loc10_35.2(%.loc10_33.2, %.loc10_47.2)
// CHECK:STDOUT:   return %Int.as.AddWith.impl.Op.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- all_defaulted.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %To: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %Count.type.8da65d.1: type = fn_type @Count.loc4 [concrete]
// CHECK:STDOUT:   %Count.d876ad.1: %Count.type.8da65d.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Count.overload_set.type: type = overload_set_type @Count.overload_set [concrete]
// CHECK:STDOUT:   %Count.overload_set.value: %Count.overload_set.type = overload_set_value @Count.overload_set [concrete]
// CHECK:STDOUT:   %AddWith.type.be9: type = facet_type <@AddWith, @AddWith(%i32)> [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.610: type = fn_type @Int.as.AddWith.impl.Op.1, @Int.as.AddWith.impl.3af(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.732: %Int.as.AddWith.impl.Op.type.610 = struct_value () [symbolic]
// CHECK:STDOUT:   %AddWith.impl_witness.833: <witness> = impl_witness imports.%AddWith.impl_witness_table.6b4, @Int.as.AddWith.impl.3af(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.056: type = fn_type @Int.as.AddWith.impl.Op.1, @Int.as.AddWith.impl.3af(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.365: %Int.as.AddWith.impl.Op.type.056 = struct_value () [concrete]
// CHECK:STDOUT:   %AddWith.facet.76a: %AddWith.type.be9 = facet_value %i32, (%AddWith.impl_witness.833) [concrete]
// CHECK:STDOUT:   %AddWith.WithSelf.Op.type.02a: type = fn_type @AddWith.WithSelf.Op, @AddWith.WithSelf(%i32, %AddWith.facet.76a) [concrete]
// CHECK:STDOUT:   %.d47: type = fn_type_with_self_type %AddWith.WithSelf.Op.type.02a, %AddWith.facet.76a [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.specific_fn.f25: <specific function> = specific_function %Int.as.AddWith.impl.Op.365, @Int.as.AddWith.impl.Op.1(%int_32) [concrete]
// CHECK:STDOUT:   %Count.type.8da65d.2: type = fn_type @Count.loc5 [concrete]
// CHECK:STDOUT:   %Count.d876ad.2: %Count.type.8da65d.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Use.type: type = fn_type @Use [concrete]
// CHECK:STDOUT:   %Use: %Use.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_5.64b: Core.IntLiteral = int_value 5 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.f6c: <bound method> = bound_method %int_5.64b, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.c9d: <bound method> = bound_method %int_5.64b, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_5.eef: %i32 = int_value 5 [concrete]
// CHECK:STDOUT:   %int_6.462: Core.IntLiteral = int_value 6 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.13d: <bound method> = bound_method %int_6.462, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.be9: <bound method> = bound_method %int_6.462, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_6.439: %i32 = int_value 6 [concrete]
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.b4fd3a.1 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.684: @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op.type (%Int.as.AddWith.impl.Op.type.610) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op (constants.%Int.as.AddWith.impl.Op.732)]
// CHECK:STDOUT:   %AddWith.impl_witness_table.6b4 = impl_witness_table (%Core.import_ref.b4fd3a.1, %Core.import_ref.684), @Int.as.AddWith.impl.3af [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Use.decl: %Use.type = fn_decl @Use [concrete = constants.%Use] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc11_13: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param0
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Use() -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Count.ref.loc11_26: %Count.overload_set.type = name_ref Count, file.%Count.overload_set.value [concrete = constants.%Count.overload_set.value]
// CHECK:STDOUT:   %Count.ref.loc11_32: %Count.type.8da65d.1 = name_ref Count, file.%Count.decl.loc4 [concrete = constants.%Count.d876ad.1]
// CHECK:STDOUT:   %Count.call.loc11_32: init %i32 = call %Count.ref.loc11_32(@Count.loc4.%.loc4_28.2, @Count.loc4.%.loc4_40.2)
// CHECK:STDOUT:   %Count.ref.loc11_36: %Count.overload_set.type = name_ref Count, file.%Count.overload_set.value [concrete = constants.%Count.overload_set.value]
// CHECK:STDOUT:   %int_5.loc11_42: Core.IntLiteral = int_value 5 [concrete = constants.%int_5.64b]
// CHECK:STDOUT:   %Count.ref.loc11_43: %Count.type.8da65d.1 = name_ref Count, file.%Count.decl.loc4 [concrete = constants.%Count.d876ad.1]
// CHECK:STDOUT:   %impl.elem0.loc11_42: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc11_42.1: <bound method> = bound_method %int_5.loc11_42, %impl.elem0.loc11_42 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.f6c]
// CHECK:STDOUT:   %specific_fn.loc11_42: <specific function> = specific_function %impl.elem0.loc11_42, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc11_42.2: <bound method> = bound_method %int_5.loc11_42, %specific_fn.loc11_42 [concrete = constants.%bound_method.c9d]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc11_42: init %i32 = call %bound_method.loc11_42.2(%int_5.loc11_42) [concrete = constants.%int_5.eef]
// CHECK:STDOUT:   %.loc11_42.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc11_42 [concrete = constants.%int_5.eef]
// CHECK:STDOUT:   %.loc11_42.2: %i32 = converted %int_5.loc11_42, %.loc11_42.1 [concrete = constants.%int_5.eef]
// CHECK:STDOUT:   %Count.call.loc11_43: init %i32 = call %Count.ref.loc11_43(%.loc11_42.2, @Count.loc4.%.loc4_40.2)
// CHECK:STDOUT:   %impl.elem1.loc11_34: %.d47 = impl_witness_access constants.%AddWith.impl_witness.833, element1 [concrete = constants.%Int.as.AddWith.impl.Op.365]
// CHECK:STDOUT:   %bound_method.loc11_34.1: <bound method> = bound_method %Count.call.loc11_32, %impl.elem1.loc11_34
// CHECK:STDOUT:   %specific_fn.loc11_34: <specific function> = specific_function %impl.elem1.loc11_34, @Int.as.AddWith.impl.Op.1(constants.%int_32) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.f25]
// CHECK:STDOUT:   %bound_method.loc11_34.2: <bound method> = bound_method %Count.call.loc11_32, %specific_fn.loc11_34
// CHECK:STDOUT:   %.loc11_32.1: %i32 = value_of_initializer %Count.call.loc11_32
// CHECK:STDOUT:   %.loc11_32.2: %i32 = converted %Count.call.loc11_32, %.loc11_32.1
// CHECK:STDOUT:   %.loc11_43.1: %i32 = value_of_initializer %Count.call.loc11_43
// CHECK:STDOUT:   %.loc11_43.2: %i32 = converted %Count.call.loc11_43, %.loc11_43.1
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call.loc11_34: init %i32 = call %bound_method.loc11_34.2(%.loc11_32.2, %.loc11_43.2)
// CHECK:STDOUT:   %Count.ref.loc11_47: %Count.overload_set.type = name_ref Count, file.%Count.overload_set.value [concrete = constants.%Count.overload_set.value]
// CHECK:STDOUT:   %int_5.loc11_53: Core.IntLiteral = int_value 5 [concrete = constants.%int_5.64b]
// CHECK:STDOUT:   %int_6: Core.IntLiteral = int_value 6 [concrete = constants.%int_6.462]
// CHECK:STDOUT:   %Count.ref.loc11_57: %Count.type.8da65d.1 = name_ref Count, file.%Count.decl.loc4 [concrete = constants.%Count.d876ad.1]
// CHECK:STDOUT:   %impl.elem0.loc11_53: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc11_53.1: <bound method> = bound_method %int_5.loc11_53, %impl.elem0.loc11_53 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.f6c]
// CHECK:STDOUT:   %specific_fn.loc11_53: <specific function> = specific_function %impl.elem0.loc11_53, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc11_53.2: <bound method> = bound_method %int_5.loc11_53, %specific_fn.loc11_53 [concrete = constants.%bound_method.c9d]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc11_53: init %i32 = call %bound_method.loc11_53.2(%int_5.loc11_53) [concrete = constants.%int_5.eef]
// CHECK:STDOUT:   %.loc11_53.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc11_53 [concrete = constants.%int_5.eef]
// CHECK:STDOUT:   %.loc11_53.2: %i32 = converted %int_5.loc11_53, %.loc11_53.1 [concrete = constants.%int_5.eef]
// CHECK:STDOUT:   %impl.elem0.loc11_56: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc11_56.1: <bound method> = bound_method %int_6, %impl.elem0.loc11_56 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.13d]
// CHECK:STDOUT:   %specific_fn.loc11_56: <specific function> = specific_function %impl.elem0.loc11_56, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc11_56.2: <bound method> = bound_method %int_6, %specific_fn.loc11_56 [concrete = constants.%bound_method.be9]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc11_56: init %i32 = call %bound_method.loc11_56.2(%int_6) [concrete = constants.%int_6.439]
// CHECK:STDOUT:   %.loc11_56.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc11_56 [concrete = constants.%int_6.439]
// CHECK:STDOUT:   %.loc11_56.2: %i32 = converted %int_6, %.loc11_56.1 [concrete = constants.%int_6.439]
// CHECK:STDOUT:   %Count.call.loc11_57: init %i32 = call %Count.ref.loc11_57(%.loc11_53.2, %.loc11_56.2)
// CHECK:STDOUT:   %impl.elem1.loc11_45: %.d47 = impl_witness_access constants.%AddWith.impl_witness.833, element1 [concrete = constants.%Int.as.AddWith.impl.Op.365]
// CHECK:STDOUT:   %bound_method.loc11_45.1: <bound method> = bound_method %Int.as.AddWith.impl.Op.call.loc11_34, %impl.elem1.loc11_45
// CHECK:STDOUT:   %specific_fn.loc11_45: <specific function> = specific_function %impl.elem1.loc11_45, @Int.as.AddWith.impl.Op.1(constants.%int_32) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.f25]
// CHECK:STDOUT:   %bound_method.loc11_45.2: <bound method> = bound_method %Int.as.AddWith.impl.Op.call.loc11_34, %specific_fn.loc11_45
// CHECK:STDOUT:   %.loc11_34.1: %i32 = value_of_initializer %Int.as.AddWith.impl.Op.call.loc11_34
// CHECK:STDOUT:   %.loc11_34.2: %i32 = converted %Int.as.AddWith.impl.Op.call.loc11_34, %.loc11_34.1
// CHECK:STDOUT:   %.loc11_57.1: %i32 = value_of_initializer %Count.call.loc11_57
// CHECK:STDOUT:   %.loc11_57.2: %i32 = converted %Count.call.loc11_57, %.loc11_57.1
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call.loc11_45: init %i32 = call %bound_method.loc11_45.2(%.loc11_34.2, %.loc11_57.2)
// CHECK:STDOUT:   %Count.ref.loc11_61: %Count.overload_set.type = name_ref Count, file.%Count.overload_set.value [concrete = constants.%Count.overload_set.value]
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:   %Count.ref.loc11_71: %Count.type.8da65d.2 = name_ref Count, file.%Count.decl.loc5 [concrete = constants.%Count.d876ad.2]
// CHECK:STDOUT:   %Count.call.loc11_71: init %i32 = call %Count.ref.loc11_71(%true)
// CHECK:STDOUT:   %impl.elem1.loc11_59: %.d47 = impl_witness_access constants.%AddWith.impl_witness.833, element1 [concrete = constants.%Int.as.AddWith.impl.Op.365]
// CHECK:STDOUT:   %bound_method.loc11_59.1: <bound method> = bound_method %Int.as.AddWith.impl.Op.call.loc11_45, %impl.elem1.loc11_59
// CHECK:STDOUT:   %specific_fn.loc11_59: <specific function> = specific_function %impl.elem1.loc11_59, @Int.as.AddWith.impl.Op.1(constants.%int_32) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.f25]
// CHECK:STDOUT:   %bound_method.loc11_59.2: <bound method> = bound_method %Int.as.AddWith.impl.Op.call.loc11_45, %specific_fn.loc11_59
// CHECK:STDOUT:   %.loc11_45.1: %i32 = value_of_initializer %Int.as.AddWith.impl.Op.call.loc11_45
// CHECK:STDOUT:   %.loc11_45.2: %i32 = converted %Int.as.AddWith.impl.Op.call.loc11_45, %.loc11_45.1
// CHECK:STDOUT:   %.loc11_71.1: %i32 = value_of_initializer %Count.call.loc11_71
// CHECK:STDOUT:   %.loc11_71.2: %i32 = converted %Count.call.loc11_71, %.loc11_71.1
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call.loc11_59: init %i32 = call %bound_method.loc11_59.2(%.loc11_45.2, %.loc11_71.2)
// CHECK:STDOUT:   return %Int.as.AddWith.impl.Op.call.loc11_59
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- first_member_needs_default.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %To: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %Pick.type.113fcf.1: type = fn_type @Pick.loc7 [concrete]
// CHECK:STDOUT:   %Pick.bd7a10.1: %Pick.type.113fcf.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Pick.overload_set.type: type = overload_set_type @Pick.overload_set [concrete]
// CHECK:STDOUT:   %Pick.overload_set.value: %Pick.overload_set.type = overload_set_value @Pick.overload_set [concrete]
// CHECK:STDOUT:   %Use.type: type = fn_type @Use [concrete]
// CHECK:STDOUT:   %Use: %Use.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_5.64b: Core.IntLiteral = int_value 5 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.f6c: <bound method> = bound_method %int_5.64b, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.c9d: <bound method> = bound_method %int_5.64b, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_5.eef: %i32 = int_value 5 [concrete]
// CHECK:STDOUT:   %int_6.462: Core.IntLiteral = int_value 6 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.13d: <bound method> = bound_method %int_6.462, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.be9: <bound method> = bound_method %int_6.462, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_6.439: %i32 = int_value 6 [concrete]
// CHECK:STDOUT:   %AddWith.type.be9: type = facet_type <@AddWith, @AddWith(%i32)> [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.610: type = fn_type @Int.as.AddWith.impl.Op.1, @Int.as.AddWith.impl.3af(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.732: %Int.as.AddWith.impl.Op.type.610 = struct_value () [symbolic]
// CHECK:STDOUT:   %AddWith.impl_witness.833: <witness> = impl_witness imports.%AddWith.impl_witness_table.6b4, @Int.as.AddWith.impl.3af(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.056: type = fn_type @Int.as.AddWith.impl.Op.1, @Int.as.AddWith.impl.3af(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.365: %Int.as.AddWith.impl.Op.type.056 = struct_value () [concrete]
// CHECK:STDOUT:   %AddWith.facet.76a: %AddWith.type.be9 = facet_value %i32, (%AddWith.impl_witness.833) [concrete]
// CHECK:STDOUT:   %AddWith.WithSelf.Op.type.02a: type = fn_type @AddWith.WithSelf.Op, @AddWith.WithSelf(%i32, %AddWith.facet.76a) [concrete]
// CHECK:STDOUT:   %.d47: type = fn_type_with_self_type %AddWith.WithSelf.Op.type.02a, %AddWith.facet.76a [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.specific_fn.f25: <specific function> = specific_function %Int.as.AddWith.impl.Op.365, @Int.as.AddWith.impl.Op.1(%int_32) [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.b4fd3a.1 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.684: @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op.type (%Int.as.AddWith.impl.Op.type.610) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op (constants.%Int.as.AddWith.impl.Op.732)]
// CHECK:STDOUT:   %AddWith.impl_witness_table.6b4 = impl_witness_table (%Core.import_ref.b4fd3a.1, %Core.import_ref.684), @Int.as.AddWith.impl.3af [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Use.decl: %Use.type = fn_decl @Use [concrete = constants.%Use] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc11_13: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param0
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Use() -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Pick.ref.loc11_26: %Pick.overload_set.type = name_ref Pick, file.%Pick.overload_set.value [concrete = constants.%Pick.overload_set.value]
// CHECK:STDOUT:   %int_5.loc11_31: Core.IntLiteral = int_value 5 [concrete = constants.%int_5.64b]
// CHECK:STDOUT:   %Pick.ref.loc11_32: %Pick.type.113fcf.1 = name_ref Pick, file.%Pick.decl.loc7 [concrete = constants.%Pick.bd7a10.1]
// CHECK:STDOUT:   %impl.elem0.loc11_31: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc11_31.1: <bound method> = bound_method %int_5.loc11_31, %impl.elem0.loc11_31 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.f6c]
// CHECK:STDOUT:   %specific_fn.loc11_31: <specific function> = specific_function %impl.elem0.loc11_31, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc11_31.2: <bound method> = bound_method %int_5.loc11_31, %specific_fn.loc11_31 [concrete = constants.%bound_method.c9d]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc11_31: init %i32 = call %bound_method.loc11_31.2(%int_5.loc11_31) [concrete = constants.%int_5.eef]
// CHECK:STDOUT:   %.loc11_31.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc11_31 [concrete = constants.%int_5.eef]
// CHECK:STDOUT:   %.loc11_31.2: %i32 = converted %int_5.loc11_31, %.loc11_31.1 [concrete = constants.%int_5.eef]
// CHECK:STDOUT:   %Pick.call.loc11_32: init %i32 = call %Pick.ref.loc11_32(%.loc11_31.2, @Pick.loc7.%.loc7_49.2)
// CHECK:STDOUT:   %Pick.ref.loc11_36: %Pick.overload_set.type = name_ref Pick, file.%Pick.overload_set.value [concrete = constants.%Pick.overload_set.value]
// CHECK:STDOUT:   %int_5.loc11_41: Core.IntLiteral = int_value 5 [concrete = constants.%int_5.64b]
// CHECK:STDOUT:   %int_6: Core.IntLiteral = int_value 6 [concrete = constants.%int_6.462]
// CHECK:STDOUT:   %Pick.ref.loc11_45: %Pick.type.113fcf.1 = name_ref Pick, file.%Pick.decl.loc7 [concrete = constants.%Pick.bd7a10.1]
// CHECK:STDOUT:   %impl.elem0.loc11_41: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc11_41.1: <bound method> = bound_method %int_5.loc11_41, %impl.elem0.loc11_41 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.f6c]
// CHECK:STDOUT:   %specific_fn.loc11_41: <specific function> = specific_function %impl.elem0.loc11_41, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc11_41.2: <bound method> = bound_method %int_5.loc11_41, %specific_fn.loc11_41 [concrete = constants.%bound_method.c9d]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc11_41: init %i32 = call %bound_method.loc11_41.2(%int_5.loc11_41) [concrete = constants.%int_5.eef]
// CHECK:STDOUT:   %.loc11_41.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc11_41 [concrete = constants.%int_5.eef]
// CHECK:STDOUT:   %.loc11_41.2: %i32 = converted %int_5.loc11_41, %.loc11_41.1 [concrete = constants.%int_5.eef]
// CHECK:STDOUT:   %impl.elem0.loc11_44: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc11_44.1: <bound method> = bound_method %int_6, %impl.elem0.loc11_44 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.13d]
// CHECK:STDOUT:   %specific_fn.loc11_44: <specific function> = specific_function %impl.elem0.loc11_44, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc11_44.2: <bound method> = bound_method %int_6, %specific_fn.loc11_44 [concrete = constants.%bound_method.be9]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc11_44: init %i32 = call %bound_method.loc11_44.2(%int_6) [concrete = constants.%int_6.439]
// CHECK:STDOUT:   %.loc11_44.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc11_44 [concrete = constants.%int_6.439]
// CHECK:STDOUT:   %.loc11_44.2: %i32 = converted %int_6, %.loc11_44.1 [concrete = constants.%int_6.439]
// CHECK:STDOUT:   %Pick.call.loc11_45: init %i32 = call %Pick.ref.loc11_45(%.loc11_41.2, %.loc11_44.2)
// CHECK:STDOUT:   %impl.elem1: %.d47 = impl_witness_access constants.%AddWith.impl_witness.833, element1 [concrete = constants.%Int.as.AddWith.impl.Op.365]
// CHECK:STDOUT:   %bound_method.loc11_34.1: <bound method> = bound_method %Pick.call.loc11_32, %impl.elem1
// CHECK:STDOUT:   %specific_fn.loc11_34: <specific function> = specific_function %impl.elem1, @Int.as.AddWith.impl.Op.1(constants.%int_32) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.f25]
// CHECK:STDOUT:   %bound_method.loc11_34.2: <bound method> = bound_method %Pick.call.loc11_32, %specific_fn.loc11_34
// CHECK:STDOUT:   %.loc11_32.1: %i32 = value_of_initializer %Pick.call.loc11_32
// CHECK:STDOUT:   %.loc11_32.2: %i32 = converted %Pick.call.loc11_32, %.loc11_32.1
// CHECK:STDOUT:   %.loc11_45.1: %i32 = value_of_initializer %Pick.call.loc11_45
// CHECK:STDOUT:   %.loc11_45.2: %i32 = converted %Pick.call.loc11_45, %.loc11_45.1
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call: init %i32 = call %bound_method.loc11_34.2(%.loc11_32.2, %.loc11_45.2)
// CHECK:STDOUT:   return %Int.as.AddWith.impl.Op.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- exact_member_first.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %Pick.type.113fcf.1: type = fn_type @Pick.loc6 [concrete]
// CHECK:STDOUT:   %Pick.bd7a10.1: %Pick.type.113fcf.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Pick.overload_set.type: type = overload_set_type @Pick.overload_set [concrete]
// CHECK:STDOUT:   %Pick.overload_set.value: %Pick.overload_set.type = overload_set_value @Pick.overload_set [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %To: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %Pick.type.113fcf.2: type = fn_type @Pick.loc7 [concrete]
// CHECK:STDOUT:   %Pick.bd7a10.2: %Pick.type.113fcf.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Use.type: type = fn_type @Use [concrete]
// CHECK:STDOUT:   %Use: %Use.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_5.64b: Core.IntLiteral = int_value 5 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.f6c: <bound method> = bound_method %int_5.64b, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.c9d: <bound method> = bound_method %int_5.64b, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_5.eef: %i32 = int_value 5 [concrete]
// CHECK:STDOUT:   %int_6.462: Core.IntLiteral = int_value 6 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.13d: <bound method> = bound_method %int_6.462, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.be9: <bound method> = bound_method %int_6.462, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_6.439: %i32 = int_value 6 [concrete]
// CHECK:STDOUT:   %AddWith.type.be9: type = facet_type <@AddWith, @AddWith(%i32)> [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.610: type = fn_type @Int.as.AddWith.impl.Op.1, @Int.as.AddWith.impl.3af(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.732: %Int.as.AddWith.impl.Op.type.610 = struct_value () [symbolic]
// CHECK:STDOUT:   %AddWith.impl_witness.833: <witness> = impl_witness imports.%AddWith.impl_witness_table.6b4, @Int.as.AddWith.impl.3af(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.056: type = fn_type @Int.as.AddWith.impl.Op.1, @Int.as.AddWith.impl.3af(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.365: %Int.as.AddWith.impl.Op.type.056 = struct_value () [concrete]
// CHECK:STDOUT:   %AddWith.facet.76a: %AddWith.type.be9 = facet_value %i32, (%AddWith.impl_witness.833) [concrete]
// CHECK:STDOUT:   %AddWith.WithSelf.Op.type.02a: type = fn_type @AddWith.WithSelf.Op, @AddWith.WithSelf(%i32, %AddWith.facet.76a) [concrete]
// CHECK:STDOUT:   %.d47: type = fn_type_with_self_type %AddWith.WithSelf.Op.type.02a, %AddWith.facet.76a [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.specific_fn.f25: <specific function> = specific_function %Int.as.AddWith.impl.Op.365, @Int.as.AddWith.impl.Op.1(%int_32) [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.b4fd3a.1 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.684: @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op.type (%Int.as.AddWith.impl.Op.type.610) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op (constants.%Int.as.AddWith.impl.Op.732)]
// CHECK:STDOUT:   %AddWith.impl_witness_table.6b4 = impl_witness_table (%Core.import_ref.b4fd3a.1, %Core.import_ref.684), @Int.as.AddWith.impl.3af [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Use.decl: %Use.type = fn_decl @Use [concrete = constants.%Use] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc10_13: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param0
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Use() -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Pick.ref.loc10_26: %Pick.overload_set.type = name_ref Pick, file.%Pick.overload_set.value [concrete = constants.%Pick.overload_set.value]
// CHECK:STDOUT:   %int_5.loc10_31: Core.IntLiteral = int_value 5 [concrete = constants.%int_5.64b]
// CHECK:STDOUT:   %Pick.ref.loc10_32: %Pick.type.113fcf.1 = name_ref Pick, file.%Pick.decl.loc6 [concrete = constants.%Pick.bd7a10.1]
// CHECK:STDOUT:   %impl.elem0.loc10_31: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc10_31.1: <bound method> = bound_method %int_5.loc10_31, %impl.elem0.loc10_31 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.f6c]
// CHECK:STDOUT:   %specific_fn.loc10_31: <specific function> = specific_function %impl.elem0.loc10_31, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc10_31.2: <bound method> = bound_method %int_5.loc10_31, %specific_fn.loc10_31 [concrete = constants.%bound_method.c9d]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc10_31: init %i32 = call %bound_method.loc10_31.2(%int_5.loc10_31) [concrete = constants.%int_5.eef]
// CHECK:STDOUT:   %.loc10_31.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc10_31 [concrete = constants.%int_5.eef]
// CHECK:STDOUT:   %.loc10_31.2: %i32 = converted %int_5.loc10_31, %.loc10_31.1 [concrete = constants.%int_5.eef]
// CHECK:STDOUT:   %Pick.call.loc10_32: init %i32 = call %Pick.ref.loc10_32(%.loc10_31.2)
// CHECK:STDOUT:   %Pick.ref.loc10_36: %Pick.overload_set.type = name_ref Pick, file.%Pick.overload_set.value [concrete = constants.%Pick.overload_set.value]
// CHECK:STDOUT:   %int_5.loc10_41: Core.IntLiteral = int_value 5 [concrete = constants.%int_5.64b]
// CHECK:STDOUT:   %int_6: Core.IntLiteral = int_value 6 [concrete = constants.%int_6.462]
// CHECK:STDOUT:   %Pick.ref.loc10_45: %Pick.type.113fcf.2 = name_ref Pick, file.%Pick.decl.loc7 [concrete = constants.%Pick.bd7a10.2]
// CHECK:STDOUT:   %impl.elem0.loc10_41: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc10_41.1: <bound method> = bound_method %int_5.loc10_41, %impl.elem0.loc10_41 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.f6c]
// CHECK:STDOUT:   %specific_fn.loc10_41: <specific function> = specific_function %impl.elem0.loc10_41, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc10_41.2: <bound method> = bound_method %int_5.loc10_41, %specific_fn.loc10_41 [concrete = constants.%bound_method.c9d]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc10_41: init %i32 = call %bound_method.loc10_41.2(%int_5.loc10_41) [concrete = constants.%int_5.eef]
// CHECK:STDOUT:   %.loc10_41.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc10_41 [concrete = constants.%int_5.eef]
// CHECK:STDOUT:   %.loc10_41.2: %i32 = converted %int_5.loc10_41, %.loc10_41.1 [concrete = constants.%int_5.eef]
// CHECK:STDOUT:   %impl.elem0.loc10_44: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc10_44.1: <bound method> = bound_method %int_6, %impl.elem0.loc10_44 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.13d]
// CHECK:STDOUT:   %specific_fn.loc10_44: <specific function> = specific_function %impl.elem0.loc10_44, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc10_44.2: <bound method> = bound_method %int_6, %specific_fn.loc10_44 [concrete = constants.%bound_method.be9]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc10_44: init %i32 = call %bound_method.loc10_44.2(%int_6) [concrete = constants.%int_6.439]
// CHECK:STDOUT:   %.loc10_44.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc10_44 [concrete = constants.%int_6.439]
// CHECK:STDOUT:   %.loc10_44.2: %i32 = converted %int_6, %.loc10_44.1 [concrete = constants.%int_6.439]
// CHECK:STDOUT:   %Pick.call.loc10_45: init %i32 = call %Pick.ref.loc10_45(%.loc10_41.2, %.loc10_44.2)
// CHECK:STDOUT:   %impl.elem1: %.d47 = impl_witness_access constants.%AddWith.impl_witness.833, element1 [concrete = constants.%Int.as.AddWith.impl.Op.365]
// CHECK:STDOUT:   %bound_method.loc10_34.1: <bound method> = bound_method %Pick.call.loc10_32, %impl.elem1
// CHECK:STDOUT:   %specific_fn.loc10_34: <specific function> = specific_function %impl.elem1, @Int.as.AddWith.impl.Op.1(constants.%int_32) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.f25]
// CHECK:STDOUT:   %bound_method.loc10_34.2: <bound method> = bound_method %Pick.call.loc10_32, %specific_fn.loc10_34
// CHECK:STDOUT:   %.loc10_32.1: %i32 = value_of_initializer %Pick.call.loc10_32
// CHECK:STDOUT:   %.loc10_32.2: %i32 = converted %Pick.call.loc10_32, %.loc10_32.1
// CHECK:STDOUT:   %.loc10_45.1: %i32 = value_of_initializer %Pick.call.loc10_45
// CHECK:STDOUT:   %.loc10_45.2: %i32 = converted %Pick.call.loc10_45, %.loc10_45.1
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call: init %i32 = call %bound_method.loc10_34.2(%.loc10_32.2, %.loc10_45.2)
// CHECK:STDOUT:   return %Int.as.AddWith.impl.Op.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- method_default.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %Counter: type = class_type @Counter [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.f85: type = pattern_type %Counter [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %To: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %Counter.Plus.type.0f15c2.1: type = fn_type @Counter.Plus.loc9 [concrete]
// CHECK:STDOUT:   %Counter.Plus.a81800.1: %Counter.Plus.type.0f15c2.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Counter.Plus.overload_set.type: type = overload_set_type @Counter.Plus.overload_set [concrete]
// CHECK:STDOUT:   %Counter.Plus.overload_set.value: %Counter.Plus.overload_set.type = overload_set_value @Counter.Plus.overload_set [concrete]
// CHECK:STDOUT:   %AddWith.type.be9: type = facet_type <@AddWith, @AddWith(%i32)> [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.610: type = fn_type @Int.as.AddWith.impl.Op.1, @Int.as.AddWith.impl.3af(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.732: %Int.as.AddWith.impl.Op.type.610 = struct_value () [symbolic]
// CHECK:STDOUT:   %AddWith.impl_witness.833: <witness> = impl_witness imports.%AddWith.impl_witness_table.6b4, @Int.as.AddWith.impl.3af(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.056: type = fn_type @Int.as.AddWith.impl.Op.1, @Int.as.AddWith.impl.3af(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.365: %Int.as.AddWith.impl.Op.type.056 = struct_value () [concrete]
// CHECK:STDOUT:   %AddWith.facet.76a: %AddWith.type.be9 = facet_value %i32, (%AddWith.impl_witness.833) [concrete]
// CHECK:STDOUT:   %AddWith.WithSelf.Op.type.02a: type = fn_type @AddWith.WithSelf.Op, @AddWith.WithSelf(%i32, %AddWith.facet.76a) [concrete]
// CHECK:STDOUT:   %.d47: type = fn_type_with_self_type %AddWith.WithSelf.Op.type.02a, %AddWith.facet.76a [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.specific_fn.f25: <specific function> = specific_function %Int.as.AddWith.impl.Op.365, @Int.as.AddWith.impl.Op.1(%int_32) [concrete]
// CHECK:STDOUT:   %c.param_patt: %pattern_type.f85 = value_param_pattern [concrete]
// CHECK:STDOUT:   %c.patt: %pattern_type.f85 = wrapper_binding_pattern c, %c.param_patt [concrete]
// CHECK:STDOUT:   %Use.type: type = fn_type @Use [concrete]
// CHECK:STDOUT:   %Use: %Use.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_5.64b: Core.IntLiteral = int_value 5 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.f6c: <bound method> = bound_method %int_5.64b, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.c9d: <bound method> = bound_method %int_5.64b, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_5.eef: %i32 = int_value 5 [concrete]
// CHECK:STDOUT:   %int_7.29f: Core.IntLiteral = int_value 7 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.66b: <bound method> = bound_method %int_7.29f, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.7ff: <bound method> = bound_method %int_7.29f, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_7.690: %i32 = int_value 7 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.b4fd3a.1 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.684: @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op.type (%Int.as.AddWith.impl.Op.type.610) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op (constants.%Int.as.AddWith.impl.Op.732)]
// CHECK:STDOUT:   %AddWith.impl_witness_table.6b4 = impl_witness_table (%Core.import_ref.b4fd3a.1, %Core.import_ref.684), @Int.as.AddWith.impl.3af [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Use.decl: %Use.type = fn_decl @Use [concrete = constants.%Use] {
// CHECK:STDOUT:     %c.param_patt: %pattern_type.f85 = value_param_pattern [concrete = constants.%c.param_patt]
// CHECK:STDOUT:     %c.patt: %pattern_type.f85 = wrapper_binding_pattern c, %c.param_patt [concrete = constants.%c.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc14: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %c.param: %Counter = value_param call_param0
// CHECK:STDOUT:     %Counter.ref.loc14: type = name_ref Counter, file.%Counter.decl [concrete = constants.%Counter]
// CHECK:STDOUT:     %c: %Counter = wrapper_binding c, %c.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Use(%c.param: %Counter) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %c.ref.loc15_10: %Counter = name_ref c, %c
// CHECK:STDOUT:   %Plus.ref.loc15_11: %Counter.Plus.overload_set.type = name_ref Plus, @Counter.%Counter.Plus.overload_set.value [concrete = constants.%Counter.Plus.overload_set.value]
// CHECK:STDOUT:   %bound_method.loc15_11: <bound method> = bound_method %c.ref.loc15_10, %Plus.ref.loc15_11
// CHECK:STDOUT:   %Plus.ref.loc15_17: %Counter.Plus.type.0f15c2.1 = name_ref Plus, @Counter.%Counter.Plus.decl.loc9 [concrete = constants.%Counter.Plus.a81800.1]
// CHECK:STDOUT:   %Counter.Plus.bound.loc15_17: <bound method> = bound_method %c.ref.loc15_10, %Plus.ref.loc15_17
// CHECK:STDOUT:   %Counter.Plus.call.loc15_17: init %i32 = call %Counter.Plus.bound.loc15_17(%c.ref.loc15_10, @Counter.Plus.loc9.%.loc9_35.2)
// CHECK:STDOUT:   %c.ref.loc15_21: %Counter = name_ref c, %c
// CHECK:STDOUT:   %Plus.ref.loc15_22: %Counter.Plus.overload_set.type = name_ref Plus, @Counter.%Counter.Plus.overload_set.value [concrete = constants.%Counter.Plus.overload_set.value]
// CHECK:STDOUT:   %bound_method.loc15_22: <bound method> = bound_method %c.ref.loc15_21, %Plus.ref.loc15_22
// CHECK:STDOUT:   %int_5: Core.IntLiteral = int_value 5 [concrete = constants.%int_5.64b]
// CHECK:STDOUT:   %Plus.ref.loc15_29: %Counter.Plus.type.0f15c2.1 = name_ref Plus, @Counter.%Counter.Plus.decl.loc9 [concrete = constants.%Counter.Plus.a81800.1]
// CHECK:STDOUT:   %Counter.Plus.bound.loc15_29: <bound method> = bound_method %c.ref.loc15_21, %Plus.ref.loc15_29
// CHECK:STDOUT:   %impl.elem0.loc15_28: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc15_28.1: <bound method> = bound_method %int_5, %impl.elem0.loc15_28 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.f6c]
// CHECK:STDOUT:   %specific_fn.loc15_28: <specific function> = specific_function %impl.elem0.loc15_28, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc15_28.2: <bound method> = bound_method %int_5, %specific_fn.loc15_28 [concrete = constants.%bound_method.c9d]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc15_28: init %i32 = call %bound_method.loc15_28.2(%int_5) [concrete = constants.%int_5.eef]
// CHECK:STDOUT:   %.loc15_28.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc15_28 [concrete = constants.%int_5.eef]
// CHECK:STDOUT:   %.loc15_28.2: %i32 = converted %int_5, %.loc15_28.1 [concrete = constants.%int_5.eef]
// CHECK:STDOUT:   %Counter.Plus.call.loc15_29: init %i32 = call %Counter.Plus.bound.loc15_29(%c.ref.loc15_21, %.loc15_28.2)
// CHECK:STDOUT:   %impl.elem1.loc15_19: %.d47 = impl_witness_access constants.%AddWith.impl_witness.833, element1 [concrete = constants.%Int.as.AddWith.impl.Op.365]
// CHECK:STDOUT:   %bound_method.loc15_19.1: <bound method> = bound_method %Counter.Plus.call.loc15_17, %impl.elem1.loc15_19
// CHECK:STDOUT:   %specific_fn.loc15_19: <specific function> = specific_function %impl.elem1.loc15_19, @Int.as.AddWith.impl.Op.1(constants.%int_32) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.f25]
// CHECK:STDOUT:   %bound_method.loc15_19.2: <bound method> = bound_method %Counter.Plus.call.loc15_17, %specific_fn.loc15_19
// CHECK:STDOUT:   %.loc15_17.1: %i32 = value_of_initializer %Counter.Plus.call.loc15_17
// CHECK:STDOUT:   %.loc15_17.2: %i32 = converted %Counter.Plus.call.loc15_17, %.loc15_17.1
// CHECK:STDOUT:   %.loc15_29.1: %i32 = value_of_initializer %Counter.Plus.call.loc15_29
// CHECK:STDOUT:   %.loc15_29.2: %i32 = converted %Counter.Plus.call.loc15_29, %.loc15_29.1
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call.loc15_19: init %i32 = call %bound_method.loc15_19.2(%.loc15_17.2, %.loc15_29.2)
// CHECK:STDOUT:   %Counter.ref.loc15_33: type = name_ref Counter, file.%Counter.decl [concrete = constants.%Counter]
// CHECK:STDOUT:   %Plus.ref.loc15_40: %Counter.Plus.overload_set.type = name_ref Plus, @Counter.%Counter.Plus.overload_set.value [concrete = constants.%Counter.Plus.overload_set.value]
// CHECK:STDOUT:   %c.ref.loc15_46: %Counter = name_ref c, %c
// CHECK:STDOUT:   %Plus.ref.loc15_47: %Counter.Plus.type.0f15c2.1 = name_ref Plus, @Counter.%Counter.Plus.decl.loc9 [concrete = constants.%Counter.Plus.a81800.1]
// CHECK:STDOUT:   %Counter.Plus.call.loc15_47: init %i32 = call %Plus.ref.loc15_47(%c.ref.loc15_46, @Counter.Plus.loc9.%.loc9_35.2)
// CHECK:STDOUT:   %impl.elem1.loc15_31: %.d47 = impl_witness_access constants.%AddWith.impl_witness.833, element1 [concrete = constants.%Int.as.AddWith.impl.Op.365]
// CHECK:STDOUT:   %bound_method.loc15_31.1: <bound method> = bound_method %Int.as.AddWith.impl.Op.call.loc15_19, %impl.elem1.loc15_31
// CHECK:STDOUT:   %specific_fn.loc15_31: <specific function> = specific_function %impl.elem1.loc15_31, @Int.as.AddWith.impl.Op.1(constants.%int_32) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.f25]
// CHECK:STDOUT:   %bound_method.loc15_31.2: <bound method> = bound_method %Int.as.AddWith.impl.Op.call.loc15_19, %specific_fn.loc15_31
// CHECK:STDOUT:   %.loc15_19.1: %i32 = value_of_initializer %Int.as.AddWith.impl.Op.call.loc15_19
// CHECK:STDOUT:   %.loc15_19.2: %i32 = converted %Int.as.AddWith.impl.Op.call.loc15_19, %.loc15_19.1
// CHECK:STDOUT:   %.loc15_47.1: %i32 = value_of_initializer %Counter.Plus.call.loc15_47
// CHECK:STDOUT:   %.loc15_47.2: %i32 = converted %Counter.Plus.call.loc15_47, %.loc15_47.1
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call.loc15_31: init %i32 = call %bound_method.loc15_31.2(%.loc15_19.2, %.loc15_47.2)
// CHECK:STDOUT:   %Counter.ref.loc15_51: type = name_ref Counter, file.%Counter.decl [concrete = constants.%Counter]
// CHECK:STDOUT:   %Plus.ref.loc15_58: %Counter.Plus.overload_set.type = name_ref Plus, @Counter.%Counter.Plus.overload_set.value [concrete = constants.%Counter.Plus.overload_set.value]
// CHECK:STDOUT:   %c.ref.loc15_64: %Counter = name_ref c, %c
// CHECK:STDOUT:   %int_7: Core.IntLiteral = int_value 7 [concrete = constants.%int_7.29f]
// CHECK:STDOUT:   %Plus.ref.loc15_68: %Counter.Plus.type.0f15c2.1 = name_ref Plus, @Counter.%Counter.Plus.decl.loc9 [concrete = constants.%Counter.Plus.a81800.1]
// CHECK:STDOUT:   %impl.elem0.loc15_67: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc15_67.1: <bound method> = bound_method %int_7, %impl.elem0.loc15_67 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.66b]
// CHECK:STDOUT:   %specific_fn.loc15_67: <specific function> = specific_function %impl.elem0.loc15_67, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc15_67.2: <bound method> = bound_method %int_7, %specific_fn.loc15_67 [concrete = constants.%bound_method.7ff]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc15_67: init %i32 = call %bound_method.loc15_67.2(%int_7) [concrete = constants.%int_7.690]
// CHECK:STDOUT:   %.loc15_67.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc15_67 [concrete = constants.%int_7.690]
// CHECK:STDOUT:   %.loc15_67.2: %i32 = converted %int_7, %.loc15_67.1 [concrete = constants.%int_7.690]
// CHECK:STDOUT:   %Counter.Plus.call.loc15_68: init %i32 = call %Plus.ref.loc15_68(%c.ref.loc15_64, %.loc15_67.2)
// CHECK:STDOUT:   %impl.elem1.loc15_49: %.d47 = impl_witness_access constants.%AddWith.impl_witness.833, element1 [concrete = constants.%Int.as.AddWith.impl.Op.365]
// CHECK:STDOUT:   %bound_method.loc15_49.1: <bound method> = bound_method %Int.as.AddWith.impl.Op.call.loc15_31, %impl.elem1.loc15_49
// CHECK:STDOUT:   %specific_fn.loc15_49: <specific function> = specific_function %impl.elem1.loc15_49, @Int.as.AddWith.impl.Op.1(constants.%int_32) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.f25]
// CHECK:STDOUT:   %bound_method.loc15_49.2: <bound method> = bound_method %Int.as.AddWith.impl.Op.call.loc15_31, %specific_fn.loc15_49
// CHECK:STDOUT:   %.loc15_31.1: %i32 = value_of_initializer %Int.as.AddWith.impl.Op.call.loc15_31
// CHECK:STDOUT:   %.loc15_31.2: %i32 = converted %Int.as.AddWith.impl.Op.call.loc15_31, %.loc15_31.1
// CHECK:STDOUT:   %.loc15_68.1: %i32 = value_of_initializer %Counter.Plus.call.loc15_68
// CHECK:STDOUT:   %.loc15_68.2: %i32 = converted %Counter.Plus.call.loc15_68, %.loc15_68.1
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call.loc15_49: init %i32 = call %bound_method.loc15_49.2(%.loc15_31.2, %.loc15_68.2)
// CHECK:STDOUT:   return %Int.as.AddWith.impl.Op.call.loc15_49
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- defaulted_self_is_not_a_receiver.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %C: type = class_type @C [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %To: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %C.P.type: type = fn_type @C.P [concrete]
// CHECK:STDOUT:   %C.P: %C.P.type = struct_value () [concrete]
// CHECK:STDOUT:   %C.M.type.369fc9.1: type = fn_type @C.M.loc10 [concrete]
// CHECK:STDOUT:   %C.M.72264f.1: %C.M.type.369fc9.1 = struct_value () [concrete]
// CHECK:STDOUT:   %C.M.overload_set.type: type = overload_set_type @C.M.overload_set [concrete]
// CHECK:STDOUT:   %C.M.overload_set.value: %C.M.overload_set.type = overload_set_value @C.M.overload_set [concrete]
// CHECK:STDOUT:   %C.M.type.369fc9.2: type = fn_type @C.M.loc11 [concrete]
// CHECK:STDOUT:   %C.M.72264f.2: %C.M.type.369fc9.2 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.98b: type = pattern_type %C [concrete]
// CHECK:STDOUT:   %c.param_patt: %pattern_type.98b = value_param_pattern [concrete]
// CHECK:STDOUT:   %c.patt: %pattern_type.98b = wrapper_binding_pattern c, %c.param_patt [concrete]
// CHECK:STDOUT:   %Use.type: type = fn_type @Use [concrete]
// CHECK:STDOUT:   %Use: %Use.type = struct_value () [concrete]
// CHECK:STDOUT:   %AddWith.type.be9: type = facet_type <@AddWith, @AddWith(%i32)> [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.610: type = fn_type @Int.as.AddWith.impl.Op.1, @Int.as.AddWith.impl.3af(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.732: %Int.as.AddWith.impl.Op.type.610 = struct_value () [symbolic]
// CHECK:STDOUT:   %AddWith.impl_witness.833: <witness> = impl_witness imports.%AddWith.impl_witness_table.6b4, @Int.as.AddWith.impl.3af(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.056: type = fn_type @Int.as.AddWith.impl.Op.1, @Int.as.AddWith.impl.3af(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.365: %Int.as.AddWith.impl.Op.type.056 = struct_value () [concrete]
// CHECK:STDOUT:   %AddWith.facet.76a: %AddWith.type.be9 = facet_value %i32, (%AddWith.impl_witness.833) [concrete]
// CHECK:STDOUT:   %AddWith.WithSelf.Op.type.02a: type = fn_type @AddWith.WithSelf.Op, @AddWith.WithSelf(%i32, %AddWith.facet.76a) [concrete]
// CHECK:STDOUT:   %.d47: type = fn_type_with_self_type %AddWith.WithSelf.Op.type.02a, %AddWith.facet.76a [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.specific_fn.f25: <specific function> = specific_function %Int.as.AddWith.impl.Op.365, @Int.as.AddWith.impl.Op.1(%int_32) [concrete]
// CHECK:STDOUT:   %int_4.0c1: Core.IntLiteral = int_value 4 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.aad: <bound method> = bound_method %int_4.0c1, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.b7a: <bound method> = bound_method %int_4.0c1, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_4.4eb: %i32 = int_value 4 [concrete]
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.b4fd3a.1 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.684: @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op.type (%Int.as.AddWith.impl.Op.type.610) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op (constants.%Int.as.AddWith.impl.Op.732)]
// CHECK:STDOUT:   %AddWith.impl_witness_table.6b4 = impl_witness_table (%Core.import_ref.b4fd3a.1, %Core.import_ref.684), @Int.as.AddWith.impl.3af [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Use.decl: %Use.type = fn_decl @Use [concrete = constants.%Use] {
// CHECK:STDOUT:     %c.param_patt: %pattern_type.98b = value_param_pattern [concrete = constants.%c.param_patt]
// CHECK:STDOUT:     %c.patt: %pattern_type.98b = wrapper_binding_pattern c, %c.param_patt [concrete = constants.%c.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc15: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %c.param: %C = value_param call_param0
// CHECK:STDOUT:     %C.ref.loc15: type = name_ref C, file.%C.decl [concrete = constants.%C]
// CHECK:STDOUT:     %c: %C = wrapper_binding c, %c.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Use(%c.param: %C) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %c.ref.loc16_10: %C = name_ref c, %c
// CHECK:STDOUT:   %P.ref: %C.P.type = name_ref P, @C.%C.P.decl [concrete = constants.%C.P]
// CHECK:STDOUT:   %C.P.call: init %i32 = call %P.ref(@C.P.%.loc9_20.2)
// CHECK:STDOUT:   %C.ref.loc16_18: type = name_ref C, file.%C.decl [concrete = constants.%C]
// CHECK:STDOUT:   %M.ref.loc16_19: %C.M.overload_set.type = name_ref M, @C.%C.M.overload_set.value [concrete = constants.%C.M.overload_set.value]
// CHECK:STDOUT:   %M.ref.loc16_22: %C.M.type.369fc9.1 = name_ref M, @C.%C.M.decl.loc10 [concrete = constants.%C.M.72264f.1]
// CHECK:STDOUT:   %C.M.call.loc16_22: init %i32 = call %M.ref.loc16_22(@C.M.loc10.%.loc10_29.2)
// CHECK:STDOUT:   %impl.elem1.loc16_16: %.d47 = impl_witness_access constants.%AddWith.impl_witness.833, element1 [concrete = constants.%Int.as.AddWith.impl.Op.365]
// CHECK:STDOUT:   %bound_method.loc16_16.1: <bound method> = bound_method %C.P.call, %impl.elem1.loc16_16
// CHECK:STDOUT:   %specific_fn.loc16_16: <specific function> = specific_function %impl.elem1.loc16_16, @Int.as.AddWith.impl.Op.1(constants.%int_32) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.f25]
// CHECK:STDOUT:   %bound_method.loc16_16.2: <bound method> = bound_method %C.P.call, %specific_fn.loc16_16
// CHECK:STDOUT:   %.loc16_14.1: %i32 = value_of_initializer %C.P.call
// CHECK:STDOUT:   %.loc16_14.2: %i32 = converted %C.P.call, %.loc16_14.1
// CHECK:STDOUT:   %.loc16_22.1: %i32 = value_of_initializer %C.M.call.loc16_22
// CHECK:STDOUT:   %.loc16_22.2: %i32 = converted %C.M.call.loc16_22, %.loc16_22.1
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call.loc16_16: init %i32 = call %bound_method.loc16_16.2(%.loc16_14.2, %.loc16_22.2)
// CHECK:STDOUT:   %C.ref.loc16_26: type = name_ref C, file.%C.decl [concrete = constants.%C]
// CHECK:STDOUT:   %M.ref.loc16_27: %C.M.overload_set.type = name_ref M, @C.%C.M.overload_set.value [concrete = constants.%C.M.overload_set.value]
// CHECK:STDOUT:   %int_4: Core.IntLiteral = int_value 4 [concrete = constants.%int_4.0c1]
// CHECK:STDOUT:   %M.ref.loc16_31: %C.M.type.369fc9.1 = name_ref M, @C.%C.M.decl.loc10 [concrete = constants.%C.M.72264f.1]
// CHECK:STDOUT:   %impl.elem0: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc16_30.1: <bound method> = bound_method %int_4, %impl.elem0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.aad]
// CHECK:STDOUT:   %specific_fn.loc16_30: <specific function> = specific_function %impl.elem0, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc16_30.2: <bound method> = bound_method %int_4, %specific_fn.loc16_30 [concrete = constants.%bound_method.b7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %i32 = call %bound_method.loc16_30.2(%int_4) [concrete = constants.%int_4.4eb]
// CHECK:STDOUT:   %.loc16_30.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_4.4eb]
// CHECK:STDOUT:   %.loc16_30.2: %i32 = converted %int_4, %.loc16_30.1 [concrete = constants.%int_4.4eb]
// CHECK:STDOUT:   %C.M.call.loc16_31: init %i32 = call %M.ref.loc16_31(%.loc16_30.2)
// CHECK:STDOUT:   %impl.elem1.loc16_24: %.d47 = impl_witness_access constants.%AddWith.impl_witness.833, element1 [concrete = constants.%Int.as.AddWith.impl.Op.365]
// CHECK:STDOUT:   %bound_method.loc16_24.1: <bound method> = bound_method %Int.as.AddWith.impl.Op.call.loc16_16, %impl.elem1.loc16_24
// CHECK:STDOUT:   %specific_fn.loc16_24: <specific function> = specific_function %impl.elem1.loc16_24, @Int.as.AddWith.impl.Op.1(constants.%int_32) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.f25]
// CHECK:STDOUT:   %bound_method.loc16_24.2: <bound method> = bound_method %Int.as.AddWith.impl.Op.call.loc16_16, %specific_fn.loc16_24
// CHECK:STDOUT:   %.loc16_16.1: %i32 = value_of_initializer %Int.as.AddWith.impl.Op.call.loc16_16
// CHECK:STDOUT:   %.loc16_16.2: %i32 = converted %Int.as.AddWith.impl.Op.call.loc16_16, %.loc16_16.1
// CHECK:STDOUT:   %.loc16_31.1: %i32 = value_of_initializer %C.M.call.loc16_31
// CHECK:STDOUT:   %.loc16_31.2: %i32 = converted %C.M.call.loc16_31, %.loc16_31.1
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call.loc16_24: init %i32 = call %bound_method.loc16_24.2(%.loc16_16.2, %.loc16_31.2)
// CHECK:STDOUT:   %c.ref.loc16_35: %C = name_ref c, %c
// CHECK:STDOUT:   %M.ref.loc16_36: %C.M.overload_set.type = name_ref M, @C.%C.M.overload_set.value [concrete = constants.%C.M.overload_set.value]
// CHECK:STDOUT:   %M.ref.loc16_39: %C.M.type.369fc9.1 = name_ref M, @C.%C.M.decl.loc10 [concrete = constants.%C.M.72264f.1]
// CHECK:STDOUT:   %C.M.call.loc16_39: init %i32 = call %M.ref.loc16_39(@C.M.loc10.%.loc10_29.2)
// CHECK:STDOUT:   %impl.elem1.loc16_33: %.d47 = impl_witness_access constants.%AddWith.impl_witness.833, element1 [concrete = constants.%Int.as.AddWith.impl.Op.365]
// CHECK:STDOUT:   %bound_method.loc16_33.1: <bound method> = bound_method %Int.as.AddWith.impl.Op.call.loc16_24, %impl.elem1.loc16_33
// CHECK:STDOUT:   %specific_fn.loc16_33: <specific function> = specific_function %impl.elem1.loc16_33, @Int.as.AddWith.impl.Op.1(constants.%int_32) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.f25]
// CHECK:STDOUT:   %bound_method.loc16_33.2: <bound method> = bound_method %Int.as.AddWith.impl.Op.call.loc16_24, %specific_fn.loc16_33
// CHECK:STDOUT:   %.loc16_24.1: %i32 = value_of_initializer %Int.as.AddWith.impl.Op.call.loc16_24
// CHECK:STDOUT:   %.loc16_24.2: %i32 = converted %Int.as.AddWith.impl.Op.call.loc16_24, %.loc16_24.1
// CHECK:STDOUT:   %.loc16_39.1: %i32 = value_of_initializer %C.M.call.loc16_39
// CHECK:STDOUT:   %.loc16_39.2: %i32 = converted %C.M.call.loc16_39, %.loc16_39.1
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call.loc16_33: init %i32 = call %bound_method.loc16_33.2(%.loc16_24.2, %.loc16_39.2)
// CHECK:STDOUT:   %C.ref.loc16_43: type = name_ref C, file.%C.decl [concrete = constants.%C]
// CHECK:STDOUT:   %M.ref.loc16_44: %C.M.overload_set.type = name_ref M, @C.%C.M.overload_set.value [concrete = constants.%C.M.overload_set.value]
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:   %M.ref.loc16_51: %C.M.type.369fc9.2 = name_ref M, @C.%C.M.decl.loc11 [concrete = constants.%C.M.72264f.2]
// CHECK:STDOUT:   %C.M.call.loc16_51: init %i32 = call %M.ref.loc16_51(%true)
// CHECK:STDOUT:   %impl.elem1.loc16_41: %.d47 = impl_witness_access constants.%AddWith.impl_witness.833, element1 [concrete = constants.%Int.as.AddWith.impl.Op.365]
// CHECK:STDOUT:   %bound_method.loc16_41.1: <bound method> = bound_method %Int.as.AddWith.impl.Op.call.loc16_33, %impl.elem1.loc16_41
// CHECK:STDOUT:   %specific_fn.loc16_41: <specific function> = specific_function %impl.elem1.loc16_41, @Int.as.AddWith.impl.Op.1(constants.%int_32) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.f25]
// CHECK:STDOUT:   %bound_method.loc16_41.2: <bound method> = bound_method %Int.as.AddWith.impl.Op.call.loc16_33, %specific_fn.loc16_41
// CHECK:STDOUT:   %.loc16_33.1: %i32 = value_of_initializer %Int.as.AddWith.impl.Op.call.loc16_33
// CHECK:STDOUT:   %.loc16_33.2: %i32 = converted %Int.as.AddWith.impl.Op.call.loc16_33, %.loc16_33.1
// CHECK:STDOUT:   %.loc16_51.1: %i32 = value_of_initializer %C.M.call.loc16_51
// CHECK:STDOUT:   %.loc16_51.2: %i32 = converted %C.M.call.loc16_51, %.loc16_51.1
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call.loc16_41: init %i32 = call %bound_method.loc16_41.2(%.loc16_33.2, %.loc16_51.2)
// CHECK:STDOUT:   return %Int.as.AddWith.impl.Op.call.loc16_41
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- generic_class_member_default.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %Box.type: type = generic_class_type @Box [concrete]
// CHECK:STDOUT:   %Box.generic: %Box.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %To: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %Use.type: type = fn_type @Use [concrete]
// CHECK:STDOUT:   %Use: %Use.type = struct_value () [concrete]
// CHECK:STDOUT:   %Box.c04: type = class_type @Box, @Box(bool) [concrete]
// CHECK:STDOUT:   %Box.Get.type.d0034d.1: type = fn_type @Box.Get.loc8, @Box(bool) [concrete]
// CHECK:STDOUT:   %Box.Get.e9543c.1: %Box.Get.type.d0034d.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Box.Get.overload_set.type.cd0: type = overload_set_type @Box.Get.overload_set, @Box(bool) [concrete]
// CHECK:STDOUT:   %Box.Get.overload_set.value.62e: %Box.Get.overload_set.type.cd0 = overload_set_value @Box.Get.overload_set [concrete]
// CHECK:STDOUT:   %Box.Get.specific_fn: <specific function> = specific_function %Box.Get.e9543c.1, @Box.Get.loc8(bool) [concrete]
// CHECK:STDOUT:   %int_9.988: Core.IntLiteral = int_value 9 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.f46: <bound method> = bound_method %int_9.988, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.9bf: <bound method> = bound_method %int_9.988, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_9.056: %i32 = int_value 9 [concrete]
// CHECK:STDOUT:   %AddWith.type.be9: type = facet_type <@AddWith, @AddWith(%i32)> [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.610: type = fn_type @Int.as.AddWith.impl.Op.1, @Int.as.AddWith.impl.3af(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.732: %Int.as.AddWith.impl.Op.type.610 = struct_value () [symbolic]
// CHECK:STDOUT:   %AddWith.impl_witness.833: <witness> = impl_witness imports.%AddWith.impl_witness_table.6b4, @Int.as.AddWith.impl.3af(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.056: type = fn_type @Int.as.AddWith.impl.Op.1, @Int.as.AddWith.impl.3af(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.365: %Int.as.AddWith.impl.Op.type.056 = struct_value () [concrete]
// CHECK:STDOUT:   %AddWith.facet.76a: %AddWith.type.be9 = facet_value %i32, (%AddWith.impl_witness.833) [concrete]
// CHECK:STDOUT:   %AddWith.WithSelf.Op.type.02a: type = fn_type @AddWith.WithSelf.Op, @AddWith.WithSelf(%i32, %AddWith.facet.76a) [concrete]
// CHECK:STDOUT:   %.d47: type = fn_type_with_self_type %AddWith.WithSelf.Op.type.02a, %AddWith.facet.76a [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.specific_fn.f25: <specific function> = specific_function %Int.as.AddWith.impl.Op.365, @Int.as.AddWith.impl.Op.1(%int_32) [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.b4fd3a.1 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.684: @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op.type (%Int.as.AddWith.impl.Op.type.610) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op (constants.%Int.as.AddWith.impl.Op.732)]
// CHECK:STDOUT:   %AddWith.impl_witness_table.6b4 = impl_witness_table (%Core.import_ref.b4fd3a.1, %Core.import_ref.684), @Int.as.AddWith.impl.3af [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Use.decl: %Use.type = fn_decl @Use [concrete = constants.%Use] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc13_13: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param0
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Use() -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Box.ref.loc13_26: %Box.type = name_ref Box, file.%Box.decl [concrete = constants.%Box.generic]
// CHECK:STDOUT:   %.loc13_30: type = type_literal bool [concrete = bool]
// CHECK:STDOUT:   %Box.loc13_34: type = class_type @Box, @Box(bool) [concrete = constants.%Box.c04]
// CHECK:STDOUT:   %.loc13_35: %Box.Get.overload_set.type.cd0 = specific_constant @Box.%Box.Get.overload_set.value.loc8_38.1, @Box(bool) [concrete = constants.%Box.Get.overload_set.value.62e]
// CHECK:STDOUT:   %Get.ref.loc13_35: %Box.Get.overload_set.type.cd0 = name_ref Get, %.loc13_35 [concrete = constants.%Box.Get.overload_set.value.62e]
// CHECK:STDOUT:   %.loc13_40.1: %Box.Get.type.d0034d.1 = specific_constant @Box.%Box.Get.decl.loc8, @Box(bool) [concrete = constants.%Box.Get.e9543c.1]
// CHECK:STDOUT:   %Get.ref.loc13_40: %Box.Get.type.d0034d.1 = name_ref Get, %.loc13_40.1 [concrete = constants.%Box.Get.e9543c.1]
// CHECK:STDOUT:   %Box.Get.specific_fn.loc13_40: <specific function> = specific_function %Get.ref.loc13_40, @Box.Get.loc8(bool) [concrete = constants.%Box.Get.specific_fn]
// CHECK:STDOUT:   %Box.Get.call.loc13_40: init %i32 = call %Box.Get.specific_fn.loc13_40(@Box.Get.loc8.%.loc8_28.2)
// CHECK:STDOUT:   %Box.ref.loc13_44: %Box.type = name_ref Box, file.%Box.decl [concrete = constants.%Box.generic]
// CHECK:STDOUT:   %.loc13_48: type = type_literal bool [concrete = bool]
// CHECK:STDOUT:   %Box.loc13_52: type = class_type @Box, @Box(bool) [concrete = constants.%Box.c04]
// CHECK:STDOUT:   %.loc13_53: %Box.Get.overload_set.type.cd0 = specific_constant @Box.%Box.Get.overload_set.value.loc8_38.1, @Box(bool) [concrete = constants.%Box.Get.overload_set.value.62e]
// CHECK:STDOUT:   %Get.ref.loc13_53: %Box.Get.overload_set.type.cd0 = name_ref Get, %.loc13_53 [concrete = constants.%Box.Get.overload_set.value.62e]
// CHECK:STDOUT:   %int_9: Core.IntLiteral = int_value 9 [concrete = constants.%int_9.988]
// CHECK:STDOUT:   %.loc13_59.1: %Box.Get.type.d0034d.1 = specific_constant @Box.%Box.Get.decl.loc8, @Box(bool) [concrete = constants.%Box.Get.e9543c.1]
// CHECK:STDOUT:   %Get.ref.loc13_59: %Box.Get.type.d0034d.1 = name_ref Get, %.loc13_59.1 [concrete = constants.%Box.Get.e9543c.1]
// CHECK:STDOUT:   %Box.Get.specific_fn.loc13_59: <specific function> = specific_function %Get.ref.loc13_59, @Box.Get.loc8(bool) [concrete = constants.%Box.Get.specific_fn]
// CHECK:STDOUT:   %impl.elem0: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc13_58.1: <bound method> = bound_method %int_9, %impl.elem0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.f46]
// CHECK:STDOUT:   %specific_fn.loc13_58: <specific function> = specific_function %impl.elem0, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc13_58.2: <bound method> = bound_method %int_9, %specific_fn.loc13_58 [concrete = constants.%bound_method.9bf]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %i32 = call %bound_method.loc13_58.2(%int_9) [concrete = constants.%int_9.056]
// CHECK:STDOUT:   %.loc13_58.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_9.056]
// CHECK:STDOUT:   %.loc13_58.2: %i32 = converted %int_9, %.loc13_58.1 [concrete = constants.%int_9.056]
// CHECK:STDOUT:   %Box.Get.call.loc13_59: init %i32 = call %Box.Get.specific_fn.loc13_59(%.loc13_58.2)
// CHECK:STDOUT:   %impl.elem1: %.d47 = impl_witness_access constants.%AddWith.impl_witness.833, element1 [concrete = constants.%Int.as.AddWith.impl.Op.365]
// CHECK:STDOUT:   %bound_method.loc13_42.1: <bound method> = bound_method %Box.Get.call.loc13_40, %impl.elem1
// CHECK:STDOUT:   %specific_fn.loc13_42: <specific function> = specific_function %impl.elem1, @Int.as.AddWith.impl.Op.1(constants.%int_32) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.f25]
// CHECK:STDOUT:   %bound_method.loc13_42.2: <bound method> = bound_method %Box.Get.call.loc13_40, %specific_fn.loc13_42
// CHECK:STDOUT:   %.loc13_40.2: %i32 = value_of_initializer %Box.Get.call.loc13_40
// CHECK:STDOUT:   %.loc13_40.3: %i32 = converted %Box.Get.call.loc13_40, %.loc13_40.2
// CHECK:STDOUT:   %.loc13_59.2: %i32 = value_of_initializer %Box.Get.call.loc13_59
// CHECK:STDOUT:   %.loc13_59.3: %i32 = converted %Box.Get.call.loc13_59, %.loc13_59.2
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call: init %i32 = call %bound_method.loc13_42.2(%.loc13_40.3, %.loc13_59.3)
// CHECK:STDOUT:   return %Int.as.AddWith.impl.Op.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- template_dependent_default.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %To: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.953: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT:   %T.type: type = fn_type @T [concrete]
// CHECK:STDOUT:   %T.062: %T.type = struct_value () [concrete]
// CHECK:STDOUT:   %Use.type: type = fn_type @Use [concrete]
// CHECK:STDOUT:   %Use: %Use.type = struct_value () [concrete]
// CHECK:STDOUT:   %T.specific_fn.5ae: <specific function> = specific_function %T.062, @T(%i32) [concrete]
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete]
// CHECK:STDOUT:   %T.specific_fn.878: <specific function> = specific_function %T.062, @T(bool) [concrete]
// CHECK:STDOUT:   %AddWith.type.be9: type = facet_type <@AddWith, @AddWith(%i32)> [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.610: type = fn_type @Int.as.AddWith.impl.Op.1, @Int.as.AddWith.impl.3af(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.732: %Int.as.AddWith.impl.Op.type.610 = struct_value () [symbolic]
// CHECK:STDOUT:   %AddWith.impl_witness.833: <witness> = impl_witness imports.%AddWith.impl_witness_table.6b4, @Int.as.AddWith.impl.3af(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.056: type = fn_type @Int.as.AddWith.impl.Op.1, @Int.as.AddWith.impl.3af(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.365: %Int.as.AddWith.impl.Op.type.056 = struct_value () [concrete]
// CHECK:STDOUT:   %AddWith.facet.76a: %AddWith.type.be9 = facet_value %i32, (%AddWith.impl_witness.833) [concrete]
// CHECK:STDOUT:   %AddWith.WithSelf.Op.type.02a: type = fn_type @AddWith.WithSelf.Op, @AddWith.WithSelf(%i32, %AddWith.facet.76a) [concrete]
// CHECK:STDOUT:   %.d47: type = fn_type_with_self_type %AddWith.WithSelf.Op.type.02a, %AddWith.facet.76a [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.specific_fn.f25: <specific function> = specific_function %Int.as.AddWith.impl.Op.365, @Int.as.AddWith.impl.Op.1(%int_32) [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.b4fd3a.1 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.684: @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op.type (%Int.as.AddWith.impl.Op.type.610) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op (constants.%Int.as.AddWith.impl.Op.732)]
// CHECK:STDOUT:   %AddWith.impl_witness_table.6b4 = impl_witness_table (%Core.import_ref.b4fd3a.1, %Core.import_ref.684), @Int.as.AddWith.impl.3af [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Use.decl: %Use.type = fn_decl @Use [concrete = constants.%Use] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc12_13 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc12_13: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc12_13: Core.Form = init_form %i32.loc12_13 [concrete = constants.%.795f]
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param0
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Use() -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %T.ref.loc12_26: %T.type = name_ref T, file.%T.decl [concrete = constants.%T.062]
// CHECK:STDOUT:   %i32.loc12_28: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %T.specific_fn.loc12_26: <specific function> = specific_function %T.ref.loc12_26, @T(constants.%i32) [concrete = constants.%T.specific_fn.5ae]
// CHECK:STDOUT:   %impl.elem0: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc12_33.1: <bound method> = bound_method %int_1, %impl.elem0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc12_33: <specific function> = specific_function %impl.elem0, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc12_33.2: <bound method> = bound_method %int_1, %specific_fn.loc12_33 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %i32 = call %bound_method.loc12_33.2(%int_1) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc12_33.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc12_33.2: %i32 = converted %int_1, %.loc12_33.1 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %T.call.loc12_34: init %i32 = call %T.specific_fn.loc12_26(%.loc12_33.2)
// CHECK:STDOUT:   %T.ref.loc12_38: %T.type = name_ref T, file.%T.decl [concrete = constants.%T.062]
// CHECK:STDOUT:   %.loc12_40: type = type_literal bool [concrete = bool]
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:   %T.specific_fn.loc12_38: <specific function> = specific_function %T.ref.loc12_38, @T(bool) [concrete = constants.%T.specific_fn.878]
// CHECK:STDOUT:   %T.call.loc12_50: init %i32 = call %T.specific_fn.loc12_38(%true)
// CHECK:STDOUT:   %impl.elem1: %.d47 = impl_witness_access constants.%AddWith.impl_witness.833, element1 [concrete = constants.%Int.as.AddWith.impl.Op.365]
// CHECK:STDOUT:   %bound_method.loc12_36.1: <bound method> = bound_method %T.call.loc12_34, %impl.elem1
// CHECK:STDOUT:   %specific_fn.loc12_36: <specific function> = specific_function %impl.elem1, @Int.as.AddWith.impl.Op.1(constants.%int_32) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.f25]
// CHECK:STDOUT:   %bound_method.loc12_36.2: <bound method> = bound_method %T.call.loc12_34, %specific_fn.loc12_36
// CHECK:STDOUT:   %.loc12_34.1: %i32 = value_of_initializer %T.call.loc12_34
// CHECK:STDOUT:   %.loc12_34.2: %i32 = converted %T.call.loc12_34, %.loc12_34.1
// CHECK:STDOUT:   %.loc12_50.1: %i32 = value_of_initializer %T.call.loc12_50
// CHECK:STDOUT:   %.loc12_50.2: %i32 = converted %T.call.loc12_50, %.loc12_50.1
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call: init %i32 = call %bound_method.loc12_36.2(%.loc12_34.2, %.loc12_50.2)
// CHECK:STDOUT:   return %Int.as.AddWith.impl.Op.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- redecl_same_default.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %To: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %F.type.eb3ec9.1: type = fn_type @F.loc7 [concrete]
// CHECK:STDOUT:   %F.7088cc.1: %F.type.eb3ec9.1 = struct_value () [concrete]
// CHECK:STDOUT:   %F.overload_set.type: type = overload_set_type @F.overload_set [concrete]
// CHECK:STDOUT:   %F.overload_set.value: %F.overload_set.type = overload_set_value @F.overload_set [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %Use.type: type = fn_type @Use [concrete]
// CHECK:STDOUT:   %Use: %Use.type = struct_value () [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.953: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Use.decl: %Use.type = fn_decl @Use [concrete = constants.%Use] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc10_13: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param0
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Use() -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %F.ref.loc10_26: %F.overload_set.type = name_ref F, file.%F.overload_set.value [concrete = constants.%F.overload_set.value]
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %F.ref.loc10_29: %F.type.eb3ec9.1 = name_ref F, file.%F.decl.loc5 [concrete = constants.%F.7088cc.1]
// CHECK:STDOUT:   %impl.elem0: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc10_28.1: <bound method> = bound_method %int_1, %impl.elem0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn: <specific function> = specific_function %impl.elem0, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc10_28.2: <bound method> = bound_method %int_1, %specific_fn [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %i32 = call %bound_method.loc10_28.2(%int_1) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc10_28.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc10_28.2: %i32 = converted %int_1, %.loc10_28.1 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %F.call: init %i32 = call %F.ref.loc10_29(%.loc10_28.2, @F.loc7.%.loc7_32.2)
// CHECK:STDOUT:   return %F.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- import_use.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %Use.type: type = fn_type @Use [concrete]
// CHECK:STDOUT:   %Use: %Use.type = struct_value () [concrete]
// CHECK:STDOUT:   %F.type.eb3ec9.2: type = fn_type @F.2 [concrete]
// CHECK:STDOUT:   %F.7088cc.2: %F.type.eb3ec9.2 = struct_value () [concrete]
// CHECK:STDOUT:   %int_2: %i32 = int_value 2 [concrete]
// CHECK:STDOUT:   %F.overload_set.type: type = overload_set_type @F.overload_set [concrete]
// CHECK:STDOUT:   %F.overload_set.value: %F.overload_set.type = overload_set_value @F.overload_set [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %To: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.953: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT:   %int_5.64b: Core.IntLiteral = int_value 5 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.f6c: <bound method> = bound_method %int_5.64b, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.c9d: <bound method> = bound_method %int_5.64b, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_5.eef: %i32 = int_value 5 [concrete]
// CHECK:STDOUT:   %AddWith.type.be9: type = facet_type <@AddWith, @AddWith(%i32)> [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.610: type = fn_type @Int.as.AddWith.impl.Op.1, @Int.as.AddWith.impl.3af(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.732: %Int.as.AddWith.impl.Op.type.610 = struct_value () [symbolic]
// CHECK:STDOUT:   %AddWith.impl_witness.833: <witness> = impl_witness imports.%AddWith.impl_witness_table.6b4, @Int.as.AddWith.impl.3af(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.056: type = fn_type @Int.as.AddWith.impl.Op.1, @Int.as.AddWith.impl.3af(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.365: %Int.as.AddWith.impl.Op.type.056 = struct_value () [concrete]
// CHECK:STDOUT:   %AddWith.facet.76a: %AddWith.type.be9 = facet_value %i32, (%AddWith.impl_witness.833) [concrete]
// CHECK:STDOUT:   %AddWith.WithSelf.Op.type.02a: type = fn_type @AddWith.WithSelf.Op, @AddWith.WithSelf(%i32, %AddWith.facet.76a) [concrete]
// CHECK:STDOUT:   %.d47: type = fn_type_with_self_type %AddWith.WithSelf.Op.type.02a, %AddWith.facet.76a [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.specific_fn.f25: <specific function> = specific_function %Int.as.AddWith.impl.Op.365, @Int.as.AddWith.impl.Op.1(%int_32) [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Main.F: %F.overload_set.type = import_ref Main//import_lib, F, loaded [concrete = constants.%F.overload_set.value]
// CHECK:STDOUT:   %F.decl.e70bc1.2: %F.type.eb3ec9.2 = fn_decl @F.2 [concrete = constants.%F.7088cc.2] {} {}
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.b4fd3a.1 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.684: @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op.type (%Int.as.AddWith.impl.Op.type.610) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op (constants.%Int.as.AddWith.impl.Op.732)]
// CHECK:STDOUT:   %AddWith.impl_witness_table.6b4 = impl_witness_table (%Core.import_ref.b4fd3a.1, %Core.import_ref.684), @Int.as.AddWith.impl.3af [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Use.decl: %Use.type = fn_decl @Use [concrete = constants.%Use] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc9_13: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param0
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Use() -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %F.ref.loc9_26: %F.overload_set.type = name_ref F, imports.%Main.F [concrete = constants.%F.overload_set.value]
// CHECK:STDOUT:   %int_1.loc9_28: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %F.ref.loc9_29: %F.type.eb3ec9.2 = name_ref F, imports.%F.decl.e70bc1.2 [concrete = constants.%F.7088cc.2]
// CHECK:STDOUT:   %impl.elem0.loc9_28: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc9_28.1: <bound method> = bound_method %int_1.loc9_28, %impl.elem0.loc9_28 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc9_28: <specific function> = specific_function %impl.elem0.loc9_28, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc9_28.2: <bound method> = bound_method %int_1.loc9_28, %specific_fn.loc9_28 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc9_28: init %i32 = call %bound_method.loc9_28.2(%int_1.loc9_28) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc9_28.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc9_28 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc9_28.2: %i32 = converted %int_1.loc9_28, %.loc9_28.1 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %F.call.loc9_29: init %i32 = call %F.ref.loc9_29(%.loc9_28.2, constants.%int_2)
// CHECK:STDOUT:   %F.ref.loc9_33: %F.overload_set.type = name_ref F, imports.%Main.F [concrete = constants.%F.overload_set.value]
// CHECK:STDOUT:   %int_1.loc9_35: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %int_5: Core.IntLiteral = int_value 5 [concrete = constants.%int_5.64b]
// CHECK:STDOUT:   %F.ref.loc9_39: %F.type.eb3ec9.2 = name_ref F, imports.%F.decl.e70bc1.2 [concrete = constants.%F.7088cc.2]
// CHECK:STDOUT:   %impl.elem0.loc9_35: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc9_35.1: <bound method> = bound_method %int_1.loc9_35, %impl.elem0.loc9_35 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc9_35: <specific function> = specific_function %impl.elem0.loc9_35, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc9_35.2: <bound method> = bound_method %int_1.loc9_35, %specific_fn.loc9_35 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc9_35: init %i32 = call %bound_method.loc9_35.2(%int_1.loc9_35) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc9_35.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc9_35 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc9_35.2: %i32 = converted %int_1.loc9_35, %.loc9_35.1 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %impl.elem0.loc9_38: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc9_38.1: <bound method> = bound_method %int_5, %impl.elem0.loc9_38 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.f6c]
// CHECK:STDOUT:   %specific_fn.loc9_38: <specific function> = specific_function %impl.elem0.loc9_38, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc9_38.2: <bound method> = bound_method %int_5, %specific_fn.loc9_38 [concrete = constants.%bound_method.c9d]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc9_38: init %i32 = call %bound_method.loc9_38.2(%int_5) [concrete = constants.%int_5.eef]
// CHECK:STDOUT:   %.loc9_38.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc9_38 [concrete = constants.%int_5.eef]
// CHECK:STDOUT:   %.loc9_38.2: %i32 = converted %int_5, %.loc9_38.1 [concrete = constants.%int_5.eef]
// CHECK:STDOUT:   %F.call.loc9_39: init %i32 = call %F.ref.loc9_39(%.loc9_35.2, %.loc9_38.2)
// CHECK:STDOUT:   %impl.elem1: %.d47 = impl_witness_access constants.%AddWith.impl_witness.833, element1 [concrete = constants.%Int.as.AddWith.impl.Op.365]
// CHECK:STDOUT:   %bound_method.loc9_31.1: <bound method> = bound_method %F.call.loc9_29, %impl.elem1
// CHECK:STDOUT:   %specific_fn.loc9_31: <specific function> = specific_function %impl.elem1, @Int.as.AddWith.impl.Op.1(constants.%int_32) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.f25]
// CHECK:STDOUT:   %bound_method.loc9_31.2: <bound method> = bound_method %F.call.loc9_29, %specific_fn.loc9_31
// CHECK:STDOUT:   %.loc9_29.1: %i32 = value_of_initializer %F.call.loc9_29
// CHECK:STDOUT:   %.loc9_29.2: %i32 = converted %F.call.loc9_29, %.loc9_29.1
// CHECK:STDOUT:   %.loc9_39.1: %i32 = value_of_initializer %F.call.loc9_39
// CHECK:STDOUT:   %.loc9_39.2: %i32 = converted %F.call.loc9_39, %.loc9_39.1
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call: init %i32 = call %bound_method.loc9_31.2(%.loc9_29.2, %.loc9_39.2)
// CHECK:STDOUT:   return %Int.as.AddWith.impl.Op.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
