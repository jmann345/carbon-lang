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
  fn Get(unused self) -> i32 { return 1; }
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
  fn Get(unused ref self) -> i32 { return 1; }
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

//@dump-sem-ir-begin
fn MakeIt(template T: HasMake) -> T { return T.Make(); }

fn Test() -> C { return MakeIt(C); }
//@dump-sem-ir-end

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
    fn F(unused self) {}
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
  fn Get(unused self) -> i32 { return 1; }
}

class Box(template T: HasGet) {
  fn Call(unused self, x: T) -> i32 { return x.Get(); }
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
// member's own specific, formed from the arguments of its enclosing specific
// `Box(i32)`, so that it equals the requirement's `Self := Box(i32)`. Spelling
// from class/method/generic_method.carbon.
template constraint HasGet {
  fn Get(self) -> i32;
}

class Box(T: type) {
  fn Get(unused self) -> i32 { return 1; }
}

fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }

fn Test(b: Box(i32)) -> i32 { return CallGet(b); }

// --- nested_generic.carbon
library "[[@TEST_NAME]]";

// A member of a class nested in a generic class (fill round 2, review finding
// MINOR-4): `Outer(i32).Inner(bool).Get` is generic over both classes'
// parameters, and its own specific is formed from the arguments of
// `Outer(i32).Inner(bool)`.
template constraint HasGet {
  fn Get(self) -> i32;
}

class Outer(T: type) {
  class Inner(U: type) {
    fn Get(unused self) -> i32 { return 1; }
  }
}

fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }

fn Test(b: Outer(i32).Inner(bool)) -> i32 { return CallGet(b); }

// --- as_facet.carbon
library "[[@TEST_NAME]]";

// An associated-function requirement named on a concrete facet value outside
// any template: the lookup finds the requirement with `Self := C` and names
// `C`'s own `Make` instead (D-SC-4; fill round 1, fix 3).
template constraint HasMake {
  fn Make() -> Self;
}

class C {
  fn Make() -> C { return {}; }
}

//@dump-sem-ir-begin
fn Test() -> C { return (C as HasMake).Make(); }
//@dump-sem-ir-end

// --- fail_todo_ambiguous_with_interface.carbon
library "[[@TEST_NAME]]";

// p002200:385-399: a name that lookup finds both through a template constraint
// and through an interface, where both resolve to the type's same function, is
// not ambiguous. Lookup decides ambiguity across extended scopes
// (name_lookup.cpp:589) before the D-SC-4 redirect resolves the requirement to
// `C.Make` (and, for the interface, before impl lookup: upstream's own TODO at
// member_access.cpp:430-432), so it is still diagnosed (fill round 2, review
// finding MINOR-3; residue in fork/structural/plan.md, "Landed notes (SC-1 fill
// rounds, 2026-10-13)", ledger id pending).
template constraint HasMake {
  fn Make() -> Self;
}

interface J {
  fn Make() -> Self;
}

class C {
  extend impl as J {
    fn Make() -> C { return {}; }
  }
}

fn ViaT(template T: HasMake & J) -> T { return T.Make(); }

// CHECK:STDERR: fail_todo_ambiguous_with_interface.carbon:[[@LINE+7]]:25: error: unable to monomorphize specific `ViaT(C as J & HasMake)` [ResolvingSpecificHere]
// CHECK:STDERR: fn Test() -> C { return ViaT(C); }
// CHECK:STDERR:                         ^~~~
// CHECK:STDERR: fail_todo_ambiguous_with_interface.carbon:[[@LINE-5]]:48: note: ambiguous use of name `Make` found in multiple extended scopes [NameAmbiguousDueToExtend]
// CHECK:STDERR: fn ViaT(template T: HasMake & J) -> T { return T.Make(); }
// CHECK:STDERR:                                                ^~~~~~
// CHECK:STDERR:
fn Test() -> C { return ViaT(C); }

// CHECK:STDOUT: --- method.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %HasGet.type: type = facet_type <@HasGet> [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %C: type = class_type @C [concrete]
// CHECK:STDOUT:   %pattern_type.98b: type = pattern_type %C [concrete]
// CHECK:STDOUT:   %CallGet.type: type = fn_type @CallGet [concrete]
// CHECK:STDOUT:   %CallGet: %CallGet.type = struct_value () [concrete]
// CHECK:STDOUT:   %c.param_patt: %pattern_type.98b = value_param_pattern [concrete]
// CHECK:STDOUT:   %c.patt: %pattern_type.98b = wrapper_binding_pattern c, %c.param_patt [concrete]
// CHECK:STDOUT:   %Test.type: type = fn_type @Test [concrete]
// CHECK:STDOUT:   %Test: %Test.type = struct_value () [concrete]
// CHECK:STDOUT:   %HasGet.facet: %HasGet.type = facet_value %C, () [concrete]
// CHECK:STDOUT:   %CallGet.specific_fn: <specific function> = specific_function %CallGet, @CallGet(%HasGet.facet) [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Test.decl: %Test.type = fn_decl @Test [concrete = constants.%Test] {
// CHECK:STDOUT:     %c.param_patt: %pattern_type.98b = value_param_pattern [concrete = constants.%c.param_patt]
// CHECK:STDOUT:     %c.patt: %pattern_type.98b = wrapper_binding_pattern c, %c.param_patt [concrete = constants.%c.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc14_18: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %c.param: %C = value_param call_param0
// CHECK:STDOUT:     %C.ref: type = name_ref C, file.%C.decl [concrete = constants.%C]
// CHECK:STDOUT:     %c: %C = wrapper_binding c, %c.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Test(%c.param: %C) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %CallGet.ref: %CallGet.type = name_ref CallGet, file.%CallGet.decl [concrete = constants.%CallGet]
// CHECK:STDOUT:   %c.ref: %C = name_ref c, %c
// CHECK:STDOUT:   %HasGet.facet.loc14_40.1: %HasGet.type = facet_value constants.%C, () [concrete = constants.%HasGet.facet]
// CHECK:STDOUT:   %.loc14_40.1: %HasGet.type = converted constants.%C, %HasGet.facet.loc14_40.1 [concrete = constants.%HasGet.facet]
// CHECK:STDOUT:   %HasGet.facet.loc14_40.2: %HasGet.type = facet_value constants.%C, () [concrete = constants.%HasGet.facet]
// CHECK:STDOUT:   %.loc14_40.2: %HasGet.type = converted constants.%C, %HasGet.facet.loc14_40.2 [concrete = constants.%HasGet.facet]
// CHECK:STDOUT:   %CallGet.specific_fn: <specific function> = specific_function %CallGet.ref, @CallGet(constants.%HasGet.facet) [concrete = constants.%CallGet.specific_fn]
// CHECK:STDOUT:   %CallGet.call: init %i32 = call %CallGet.specific_fn(%c.ref)
// CHECK:STDOUT:   return %CallGet.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- assoc_fn.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %HasMake.type: type = facet_type <@HasMake> [concrete]
// CHECK:STDOUT:   %C: type = class_type @C [concrete]
// CHECK:STDOUT:   %.a44: Core.Form = init_form %C [concrete]
// CHECK:STDOUT:   %pattern_type.98b: type = pattern_type %C [concrete]
// CHECK:STDOUT:   %return.param_patt.89a: %pattern_type.98b = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e4a: %pattern_type.98b = return_slot_pattern %return.param_patt.89a, %C [concrete]
// CHECK:STDOUT:   %C.Make.type: type = fn_type @C.Make [concrete]
// CHECK:STDOUT:   %C.Make: %C.Make.type = struct_value () [concrete]
// CHECK:STDOUT:   %empty_struct_type: type = struct_type {} [concrete]
// CHECK:STDOUT:   %complete_type: <witness> = complete_type_witness %empty_struct_type [concrete]
// CHECK:STDOUT:   %.Self.frozen: type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %pattern_type.9a5: type = pattern_type %HasMake.type [concrete]
// CHECK:STDOUT:   %T.patt: %pattern_type.9a5 = symbolic_binding_pattern T, 0, template [template]
// CHECK:STDOUT:   %T: %HasMake.type = symbolic_binding T, 0, template [template]
// CHECK:STDOUT:   %T.as_type: type = facet_access_type %T [template]
// CHECK:STDOUT:   %.1f0: Core.Form = init_form %T.as_type [template]
// CHECK:STDOUT:   %pattern_type.86a: type = pattern_type %T.as_type [template]
// CHECK:STDOUT:   %return.param_patt.5f6: %pattern_type.86a = out_param_pattern [template]
// CHECK:STDOUT:   %return.patt.96a: %pattern_type.86a = return_slot_pattern %return.param_patt.5f6, %T.as_type [template]
// CHECK:STDOUT:   %MakeIt.type: type = fn_type @MakeIt [concrete]
// CHECK:STDOUT:   %MakeIt: %MakeIt.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete: <witness> = require_complete_type %T.as_type [template]
// CHECK:STDOUT:   %.695: type = type_of_inst @MakeIt.%.loc14_47.3 [template]
// CHECK:STDOUT:   %.e6b: %.695 = splice_inst @MakeIt.%.loc14_47.3 [template]
// CHECK:STDOUT:   %.5e1: type = type_of_inst @MakeIt.%.loc14_53.3 [template]
// CHECK:STDOUT:   %.03f: %.5e1 = splice_inst @MakeIt.%.loc14_53.3 [template]
// CHECK:STDOUT:   %tuple.type: type = tuple_type (<instruction>) [concrete]
// CHECK:STDOUT:   %.762: %T.as_type = splice_inst @MakeIt.%tuple.elem0 [template]
// CHECK:STDOUT:   %Test.type: type = fn_type @Test [concrete]
// CHECK:STDOUT:   %Test: %Test.type = struct_value () [concrete]
// CHECK:STDOUT:   %HasMake.facet: %HasMake.type = facet_value %C, () [concrete]
// CHECK:STDOUT:   %MakeIt.specific_fn: <specific function> = specific_function %MakeIt, @MakeIt(%HasMake.facet) [concrete]
// CHECK:STDOUT:   %HasMake.WithSelf.Make.type.197: type = fn_type @HasMake.WithSelf.Make, @HasMake.WithSelf(%HasMake.facet) [concrete]
// CHECK:STDOUT:   %HasMake.WithSelf.Make.efd: %HasMake.WithSelf.Make.type.197 = struct_value () [concrete]
// CHECK:STDOUT:   %inst.splice_block.426619.1: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.871: %C.Make.type = splice_block %Make.ref.b85 [concrete = %C.Make] {
// CHECK:STDOUT:       %as_type: type = facet_access_type %HasMake.facet [concrete = %C]
// CHECK:STDOUT:       %.398: type = converted %HasMake.facet, %as_type [concrete = %C]
// CHECK:STDOUT:       %.f87: %HasMake.WithSelf.Make.type.197 = specific_constant @HasMake.WithSelf.%HasMake.WithSelf.Make.decl, @HasMake.WithSelf(%HasMake.facet) [concrete = %HasMake.WithSelf.Make.efd]
// CHECK:STDOUT:       %Make.ref.e0b: %HasMake.WithSelf.Make.type.197 = name_ref Make, %.f87 [concrete = %HasMake.WithSelf.Make.efd]
// CHECK:STDOUT:       %Make.ref.b85: %C.Make.type = name_ref Make, @C.%C.Make.decl [concrete = %C.Make]
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %inst.splice_block.426619.2: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.06d: init %C = splice_block %C.Make.call {
// CHECK:STDOUT:       %.016: ref %C = specific_inst @MakeIt.%return.param, @MakeIt(%HasMake.facet)
// CHECK:STDOUT:       %C.Make.call: init %C to %.016 = call %C.Make()
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %inst.splice_block.426619.3: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.3a5: init %C = splice_block %.06d {}
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %tuple: %tuple.type = tuple_value (%inst.splice_block.426619.3) [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %MakeIt.decl: %MakeIt.type = fn_decl @MakeIt [concrete = constants.%MakeIt] {
// CHECK:STDOUT:     %T.patt.loc14_21.1: %pattern_type.9a5 = symbolic_binding_pattern T, 0, template [template = %T.patt.loc14_21.2 (constants.%T.patt)]
// CHECK:STDOUT:     %return.param_patt.loc14_35.1: @MakeIt.%pattern_type (%pattern_type.86a) = out_param_pattern [template = %return.param_patt.loc14_35.2 (constants.%return.param_patt.5f6)]
// CHECK:STDOUT:     %return.patt.loc14_32.1: @MakeIt.%pattern_type (%pattern_type.86a) = return_slot_pattern %return.param_patt.loc14_35.1, %.loc14_35.2 [template = %return.patt.loc14_32.2 (constants.%return.patt.96a)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %T.ref.loc14_35: %HasMake.type = name_ref T, %T.loc14_21.2 [template = %T.loc14_21.1 (constants.%T)]
// CHECK:STDOUT:     %T.as_type.loc14_35.2: type = facet_access_type %T.ref.loc14_35 [template = %T.as_type.loc14_35.1 (constants.%T.as_type)]
// CHECK:STDOUT:     %.loc14_35.2: type = converted %T.ref.loc14_35, %T.as_type.loc14_35.2 [template = %T.as_type.loc14_35.1 (constants.%T.as_type)]
// CHECK:STDOUT:     %.loc14_35.3: Core.Form = init_form %.loc14_35.2 [template = %.loc14_35.1 (constants.%.1f0)]
// CHECK:STDOUT:     %.loc14_23: type = splice_block %HasMake.ref [concrete = constants.%HasMake.type] {
// CHECK:STDOUT:       %.Self.frozen: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %HasMake.ref: type = name_ref HasMake, file.%HasMake.decl [concrete = constants.%HasMake.type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc14_21.2: %HasMake.type = symbolic_binding T, 0, template [template = %T.loc14_21.1 (constants.%T)]
// CHECK:STDOUT:     %return.param: ref @MakeIt.%T.as_type.loc14_35.1 (%T.as_type) = out_param call_param0
// CHECK:STDOUT:     %return: ref @MakeIt.%T.as_type.loc14_35.1 (%T.as_type) = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Test.decl: %Test.type = fn_decl @Test [concrete = constants.%Test] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.98b = out_param_pattern [concrete = constants.%return.param_patt.89a]
// CHECK:STDOUT:     %return.patt: %pattern_type.98b = return_slot_pattern %return.param_patt, %C.ref.loc16_14 [concrete = constants.%return.patt.e4a]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %C.ref.loc16_14: type = name_ref C, file.%C.decl [concrete = constants.%C]
// CHECK:STDOUT:     %.loc16_14.2: Core.Form = init_form %C.ref.loc16_14 [concrete = constants.%.a44]
// CHECK:STDOUT:     %return.param: ref %C = out_param call_param0
// CHECK:STDOUT:     %return: ref %C = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @MakeIt(%T.loc14_21.2: %HasMake.type) {
// CHECK:STDOUT:   %T.patt.loc14_21.2: %pattern_type.9a5 = symbolic_binding_pattern T, 0, template [template = %T.patt.loc14_21.2 (constants.%T.patt)]
// CHECK:STDOUT:   %T.loc14_21.1: %HasMake.type = symbolic_binding T, 0, template [template = %T.loc14_21.1 (constants.%T)]
// CHECK:STDOUT:   %T.as_type.loc14_35.1: type = facet_access_type %T.loc14_21.1 [template = %T.as_type.loc14_35.1 (constants.%T.as_type)]
// CHECK:STDOUT:   %.loc14_35.1: Core.Form = init_form %T.as_type.loc14_35.1 [template = %.loc14_35.1 (constants.%.1f0)]
// CHECK:STDOUT:   %pattern_type: type = pattern_type %T.as_type.loc14_35.1 [template = %pattern_type (constants.%pattern_type.86a)]
// CHECK:STDOUT:   %return.param_patt.loc14_35.2: @MakeIt.%pattern_type (%pattern_type.86a) = out_param_pattern [template = %return.param_patt.loc14_35.2 (constants.%return.param_patt.5f6)]
// CHECK:STDOUT:   %return.patt.loc14_32.2: @MakeIt.%pattern_type (%pattern_type.86a) = return_slot_pattern %return.param_patt.loc14_35.2, %T.as_type.loc14_35.1 [template = %return.patt.loc14_32.2 (constants.%return.patt.96a)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete: <witness> = require_complete_type %T.as_type.loc14_35.1 [template = %require_complete (constants.%require_complete)]
// CHECK:STDOUT:   %.loc14_47.3: <instruction> = access_member_action %T.ref.loc14_46, Make [template]
// CHECK:STDOUT:   %.loc14_47.4: type = type_of_inst %.loc14_47.3 [template = %.loc14_47.4 (constants.%.695)]
// CHECK:STDOUT:   %.loc14_47.5: @MakeIt.%.loc14_47.4 (%.695) = splice_inst %.loc14_47.3 [template = %.loc14_47.5 (constants.%.e6b)]
// CHECK:STDOUT:   %.loc14_53.3: <instruction> = call_action (%.loc14_47.2), false [template]
// CHECK:STDOUT:   %.loc14_53.4: type = type_of_inst %.loc14_53.3 [template = %.loc14_53.4 (constants.%.5e1)]
// CHECK:STDOUT:   %.loc14_53.5: @MakeIt.%.loc14_53.4 (%.5e1) = splice_inst %.loc14_53.3 [template = %.loc14_53.5 (constants.%.03f)]
// CHECK:STDOUT:   %.loc14_54.2: %tuple.type = initialize_action %.loc14_53.2, %T.as_type.loc14_35.1, %return.param, false [template]
// CHECK:STDOUT:   %tuple.elem0: <instruction> = tuple_access %.loc14_54.2, element0 [template]
// CHECK:STDOUT:   %.loc14_54.3: @MakeIt.%T.as_type.loc14_35.1 (%T.as_type) = splice_inst %tuple.elem0 [template = %.loc14_54.3 (constants.%.762)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn() -> out %return.param: @MakeIt.%T.as_type.loc14_35.1 (%T.as_type) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %T.ref.loc14_46: %HasMake.type = name_ref T, %T.loc14_21.2 [template = %T.loc14_21.1 (constants.%T)]
// CHECK:STDOUT:     %.loc14_47.1: type = type_of_inst %.loc14_47.3 [template = %.loc14_47.4 (constants.%.695)]
// CHECK:STDOUT:     %.loc14_47.2: @MakeIt.%.loc14_47.4 (%.695) = splice_inst %.loc14_47.3 [template = %.loc14_47.5 (constants.%.e6b)]
// CHECK:STDOUT:     %.loc14_53.1: type = type_of_inst %.loc14_53.3 [template = %.loc14_53.4 (constants.%.5e1)]
// CHECK:STDOUT:     %.loc14_53.2: @MakeIt.%.loc14_53.4 (%.5e1) = splice_inst %.loc14_53.3 [template = %.loc14_53.5 (constants.%.03f)]
// CHECK:STDOUT:     %.loc14_54.1: @MakeIt.%T.as_type.loc14_35.1 (%T.as_type) = splice_inst %tuple.elem0 [template = %.loc14_54.3 (constants.%.762)]
// CHECK:STDOUT:     return %.loc14_54.1 to %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Test() -> out %return.param: %C {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %MakeIt.ref: %MakeIt.type = name_ref MakeIt, file.%MakeIt.decl [concrete = constants.%MakeIt]
// CHECK:STDOUT:   %C.ref.loc16_32: type = name_ref C, file.%C.decl [concrete = constants.%C]
// CHECK:STDOUT:   %HasMake.facet: %HasMake.type = facet_value %C.ref.loc16_32, () [concrete = constants.%HasMake.facet]
// CHECK:STDOUT:   %.loc16_33: %HasMake.type = converted %C.ref.loc16_32, %HasMake.facet [concrete = constants.%HasMake.facet]
// CHECK:STDOUT:   %MakeIt.specific_fn: <specific function> = specific_function %MakeIt.ref, @MakeIt(constants.%HasMake.facet) [concrete = constants.%MakeIt.specific_fn]
// CHECK:STDOUT:   %.loc16_14.1: ref %C = splice_block %return.param {}
// CHECK:STDOUT:   %MakeIt.call: init %C to %.loc16_14.1 = call %MakeIt.specific_fn()
// CHECK:STDOUT:   return %MakeIt.call to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @MakeIt(constants.%T) {
// CHECK:STDOUT:   %T.patt.loc14_21.2 => constants.%T.patt
// CHECK:STDOUT:   %T.loc14_21.1 => constants.%T
// CHECK:STDOUT:   %T.as_type.loc14_35.1 => constants.%T.as_type
// CHECK:STDOUT:   %.loc14_35.1 => constants.%.1f0
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.86a
// CHECK:STDOUT:   %return.param_patt.loc14_35.2 => constants.%return.param_patt.5f6
// CHECK:STDOUT:   %return.patt.loc14_32.2 => constants.%return.patt.96a
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @MakeIt(constants.%HasMake.facet) {
// CHECK:STDOUT:   %T.patt.loc14_21.2 => constants.%T.patt
// CHECK:STDOUT:   %T.loc14_21.1 => constants.%HasMake.facet
// CHECK:STDOUT:   %T.as_type.loc14_35.1 => constants.%C
// CHECK:STDOUT:   %.loc14_35.1 => constants.%.a44
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.98b
// CHECK:STDOUT:   %return.param_patt.loc14_35.2 => constants.%return.param_patt.89a
// CHECK:STDOUT:   %return.patt.loc14_32.2 => constants.%return.patt.e4a
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete => constants.%complete_type
// CHECK:STDOUT:   %.loc14_47.3 => constants.%inst.splice_block.426619.1
// CHECK:STDOUT:   %.loc14_47.4 => constants.%C.Make.type
// CHECK:STDOUT:   %.loc14_47.5 => constants.%C.Make
// CHECK:STDOUT:   %.loc14_53.3 => constants.%inst.splice_block.426619.2
// CHECK:STDOUT:   %.loc14_53.4 => constants.%C
// CHECK:STDOUT:   %.loc14_53.5 => <not constant>
// CHECK:STDOUT:   %.loc14_54.2 => constants.%tuple
// CHECK:STDOUT:   %tuple.elem0 => constants.%inst.splice_block.426619.3
// CHECK:STDOUT:   %.loc14_54.3 => <not constant>
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- class_param.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %HasGet.type: type = facet_type <@HasGet> [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %C: type = class_type @C [concrete]
// CHECK:STDOUT:   %pattern_type.98b: type = pattern_type %C [concrete]
// CHECK:STDOUT:   %empty_struct_type: type = struct_type {} [concrete]
// CHECK:STDOUT:   %Box.type: type = generic_class_type @Box [concrete]
// CHECK:STDOUT:   %Box.generic: %Box.type = struct_value () [concrete]
// CHECK:STDOUT:   %c.param_patt: %pattern_type.98b = value_param_pattern [concrete]
// CHECK:STDOUT:   %c.patt: %pattern_type.98b = wrapper_binding_pattern c, %c.param_patt [concrete]
// CHECK:STDOUT:   %Test.type: type = fn_type @Test [concrete]
// CHECK:STDOUT:   %Test: %Test.type = struct_value () [concrete]
// CHECK:STDOUT:   %HasGet.facet: %HasGet.type = facet_value %C, () [concrete]
// CHECK:STDOUT:   %Box.dfa: type = class_type @Box, @Box(%HasGet.facet) [concrete]
// CHECK:STDOUT:   %Box.Call.type.bcf: type = fn_type @Box.Call, @Box(%HasGet.facet) [concrete]
// CHECK:STDOUT:   %Box.Call.921: %Box.Call.type.bcf = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.7d4: type = pattern_type %Box.dfa [concrete]
// CHECK:STDOUT:   %b.patt: %pattern_type.7d4 = ref_binding_pattern b [concrete]
// CHECK:STDOUT:   %b.var_patt: %pattern_type.7d4 = var_pattern %b.patt [concrete]
// CHECK:STDOUT:   %empty_struct: %empty_struct_type = struct_value () [concrete]
// CHECK:STDOUT:   %Box.val: %Box.dfa = struct_value () [concrete]
// CHECK:STDOUT:   %Box.Call.specific_fn: <specific function> = specific_function %Box.Call.921, @Box.Call(%HasGet.facet) [concrete]
// CHECK:STDOUT:   %pattern_type.a96: type = pattern_type %empty_struct_type [concrete]
// CHECK:STDOUT:   %self.param_patt.52f: %pattern_type.a96 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.4b1: %pattern_type.a96 = wrapper_binding_pattern self, %self.param_patt.52f [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc19_3.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.1: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.1: type = fn_type @Destroy.WithSelf.Op.loc19_3.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.1: %Destroy.WithSelf.Op.type.ef016f.1 = struct_value () [concrete]
// CHECK:STDOUT:   %self.param_patt.66a: %pattern_type.7d4 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.a68: %pattern_type.7d4 = wrapper_binding_pattern self, %self.param_patt.66a [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc19_3.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.2: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.2: type = fn_type @Destroy.WithSelf.Op.loc19_3.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.2: %Destroy.WithSelf.Op.type.ef016f.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.2: type = fn_type @Destroy.WithSelf.SelfDestruct.loc19_3.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.2: %Destroy.WithSelf.SelfDestruct.type.fbceb5.2 = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.1: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc19_3.1 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.1] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.a96 = ref_param_pattern [concrete = constants.%self.param_patt.52f]
// CHECK:STDOUT:     %self.patt: %pattern_type.a96 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.4b1]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %empty_struct_type = ref_param call_param0
// CHECK:STDOUT:     %self: ref %empty_struct_type = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.1: %Destroy.WithSelf.Op.type.ef016f.1 = fn_decl @Destroy.WithSelf.Op.loc19_3.1 [concrete = constants.%Destroy.WithSelf.Op.403171.1] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.a96 = ref_param_pattern [concrete = constants.%self.param_patt.52f]
// CHECK:STDOUT:     %self.patt: %pattern_type.a96 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.4b1]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %empty_struct_type = ref_param call_param0
// CHECK:STDOUT:     %self: ref %empty_struct_type = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.2: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc19_3.2 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.2] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.7d4 = ref_param_pattern [concrete = constants.%self.param_patt.66a]
// CHECK:STDOUT:     %self.patt: %pattern_type.7d4 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.a68]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %Box.dfa = ref_param call_param0
// CHECK:STDOUT:     %self: ref %Box.dfa = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.2: %Destroy.WithSelf.Op.type.ef016f.2 = fn_decl @Destroy.WithSelf.Op.loc19_3.2 [concrete = constants.%Destroy.WithSelf.Op.403171.2] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.7d4 = ref_param_pattern [concrete = constants.%self.param_patt.66a]
// CHECK:STDOUT:     %self.patt: %pattern_type.7d4 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.a68]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %Box.dfa = ref_param call_param0
// CHECK:STDOUT:     %self: ref %Box.dfa = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Test.decl: %Test.type = fn_decl @Test [concrete = constants.%Test] {
// CHECK:STDOUT:     %c.param_patt: %pattern_type.98b = value_param_pattern [concrete = constants.%c.param_patt]
// CHECK:STDOUT:     %c.patt: %pattern_type.98b = wrapper_binding_pattern c, %c.param_patt [concrete = constants.%c.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc18: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %c.param: %C = value_param call_param0
// CHECK:STDOUT:     %C.ref.loc18: type = name_ref C, file.%C.decl [concrete = constants.%C]
// CHECK:STDOUT:     %c: %C = wrapper_binding c, %c.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Test(%c.param: %C) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %b.var: ref %Box.dfa = var_storage %b.var_patt
// CHECK:STDOUT:   %.loc19_20.1: %empty_struct_type = struct_literal () [concrete = constants.%empty_struct]
// CHECK:STDOUT:   %.loc19_20.2: init %Box.dfa to %b.var = class_init () [concrete = constants.%Box.val]
// CHECK:STDOUT:   %.loc19_3: init %Box.dfa = converted %.loc19_20.1, %.loc19_20.2 [concrete = constants.%Box.val]
// CHECK:STDOUT:   assign %b.var, %.loc19_3
// CHECK:STDOUT:   %.loc19_15.1: type = splice_block %Box [concrete = constants.%Box.dfa] {
// CHECK:STDOUT:     %Box.ref: %Box.type = name_ref Box, file.%Box.decl [concrete = constants.%Box.generic]
// CHECK:STDOUT:     %C.ref.loc19: type = name_ref C, file.%C.decl [concrete = constants.%C]
// CHECK:STDOUT:     %HasGet.facet.loc19: %HasGet.type = facet_value %C.ref.loc19, () [concrete = constants.%HasGet.facet]
// CHECK:STDOUT:     %.loc19_15.2: %HasGet.type = converted %C.ref.loc19, %HasGet.facet.loc19 [concrete = constants.%HasGet.facet]
// CHECK:STDOUT:     %Box: type = class_type @Box, @Box(constants.%HasGet.facet) [concrete = constants.%Box.dfa]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %b: ref %Box.dfa = wrapper_binding b, %b.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %b.patt: %pattern_type.7d4 = ref_binding_pattern b [concrete = constants.%b.patt]
// CHECK:STDOUT:     %b.var_patt: %pattern_type.7d4 = var_pattern %b.patt [concrete = constants.%b.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %b.ref: ref %Box.dfa = name_ref b, %b
// CHECK:STDOUT:   %.loc20_11: %Box.Call.type.bcf = specific_constant @Box.%Box.Call.decl, @Box(constants.%HasGet.facet) [concrete = constants.%Box.Call.921]
// CHECK:STDOUT:   %Call.ref: %Box.Call.type.bcf = name_ref Call, %.loc20_11 [concrete = constants.%Box.Call.921]
// CHECK:STDOUT:   %Box.Call.bound: <bound method> = bound_method %b.ref, %Call.ref
// CHECK:STDOUT:   %c.ref: %C = name_ref c, %c
// CHECK:STDOUT:   %HasGet.facet.loc20_18.1: %HasGet.type = facet_value constants.%C, () [concrete = constants.%HasGet.facet]
// CHECK:STDOUT:   %.loc20_18.1: %HasGet.type = converted constants.%C, %HasGet.facet.loc20_18.1 [concrete = constants.%HasGet.facet]
// CHECK:STDOUT:   %HasGet.facet.loc20_18.2: %HasGet.type = facet_value constants.%C, () [concrete = constants.%HasGet.facet]
// CHECK:STDOUT:   %.loc20_18.2: %HasGet.type = converted constants.%C, %HasGet.facet.loc20_18.2 [concrete = constants.%HasGet.facet]
// CHECK:STDOUT:   %Box.Call.specific_fn: <specific function> = specific_function %Call.ref, @Box.Call(constants.%HasGet.facet) [concrete = constants.%Box.Call.specific_fn]
// CHECK:STDOUT:   %bound_method: <bound method> = bound_method %b.ref, %Box.Call.specific_fn
// CHECK:STDOUT:   %.loc20_10: %Box.dfa = acquire_value %b.ref
// CHECK:STDOUT:   %Box.Call.call: init %i32 = call %bound_method(%.loc20_10, %c.ref)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound: <bound method> = bound_method %b.var, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound(%b.var)
// CHECK:STDOUT:   return %Box.Call.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc19_3.1(%self.param: ref %empty_struct_type) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc19_3.1(%self.param: ref %empty_struct_type) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc19_3.1(%self.param: ref %empty_struct_type) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.1(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.1(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc19_3.2(%self.param: ref %Box.dfa) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc19_3.2(%self.param: ref %Box.dfa) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc19_3.2(%self.param: ref %Box.dfa) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.2(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.2(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- as_facet.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %HasMake.type: type = facet_type <@HasMake> [concrete]
// CHECK:STDOUT:   %C: type = class_type @C [concrete]
// CHECK:STDOUT:   %.a44: Core.Form = init_form %C [concrete]
// CHECK:STDOUT:   %pattern_type.98b: type = pattern_type %C [concrete]
// CHECK:STDOUT:   %return.param_patt.89a: %pattern_type.98b = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e4a: %pattern_type.98b = return_slot_pattern %return.param_patt.89a, %C [concrete]
// CHECK:STDOUT:   %C.Make.type: type = fn_type @C.Make [concrete]
// CHECK:STDOUT:   %C.Make: %C.Make.type = struct_value () [concrete]
// CHECK:STDOUT:   %Test.type: type = fn_type @Test [concrete]
// CHECK:STDOUT:   %Test: %Test.type = struct_value () [concrete]
// CHECK:STDOUT:   %HasMake.facet: %HasMake.type = facet_value %C, () [concrete]
// CHECK:STDOUT:   %HasMake.WithSelf.Make.type.197: type = fn_type @HasMake.WithSelf.Make, @HasMake.WithSelf(%HasMake.facet) [concrete]
// CHECK:STDOUT:   %HasMake.WithSelf.Make.efd: %HasMake.WithSelf.Make.type.197 = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Test.decl: %Test.type = fn_decl @Test [concrete = constants.%Test] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.98b = out_param_pattern [concrete = constants.%return.param_patt.89a]
// CHECK:STDOUT:     %return.patt: %pattern_type.98b = return_slot_pattern %return.param_patt, %C.ref.loc15_14 [concrete = constants.%return.patt.e4a]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %C.ref.loc15_14: type = name_ref C, file.%C.decl [concrete = constants.%C]
// CHECK:STDOUT:     %.loc15_14.2: Core.Form = init_form %C.ref.loc15_14 [concrete = constants.%.a44]
// CHECK:STDOUT:     %return.param: ref %C = out_param call_param0
// CHECK:STDOUT:     %return: ref %C = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Test() -> out %return.param: %C {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %C.ref.loc15_26: type = name_ref C, file.%C.decl [concrete = constants.%C]
// CHECK:STDOUT:   %HasMake.ref: type = name_ref HasMake, file.%HasMake.decl [concrete = constants.%HasMake.type]
// CHECK:STDOUT:   %HasMake.facet: %HasMake.type = facet_value %C.ref.loc15_26, () [concrete = constants.%HasMake.facet]
// CHECK:STDOUT:   %.loc15_28: %HasMake.type = converted %C.ref.loc15_26, %HasMake.facet [concrete = constants.%HasMake.facet]
// CHECK:STDOUT:   %as_type: type = facet_access_type %.loc15_28 [concrete = constants.%C]
// CHECK:STDOUT:   %.loc15_39.1: type = converted %.loc15_28, %as_type [concrete = constants.%C]
// CHECK:STDOUT:   %.loc15_39.2: %HasMake.WithSelf.Make.type.197 = specific_constant @HasMake.WithSelf.%HasMake.WithSelf.Make.decl, @HasMake.WithSelf(constants.%HasMake.facet) [concrete = constants.%HasMake.WithSelf.Make.efd]
// CHECK:STDOUT:   %Make.ref.loc15_39.1: %HasMake.WithSelf.Make.type.197 = name_ref Make, %.loc15_39.2 [concrete = constants.%HasMake.WithSelf.Make.efd]
// CHECK:STDOUT:   %Make.ref.loc15_39.2: %C.Make.type = name_ref Make, @C.%C.Make.decl [concrete = constants.%C.Make]
// CHECK:STDOUT:   %.loc15_14.1: ref %C = splice_block %return.param {}
// CHECK:STDOUT:   %C.Make.call: init %C to %.loc15_14.1 = call %Make.ref.loc15_39.2()
// CHECK:STDOUT:   return %C.Make.call to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
