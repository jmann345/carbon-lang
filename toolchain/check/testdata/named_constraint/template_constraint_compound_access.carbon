// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/named_constraint/template_constraint_compound_access.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/named_constraint/template_constraint_compound_access.carbon

// Compound member access through a `template constraint` requirement
// (`x.(HasGet.Get)`) binds the base type's OWN member after the structural
// check; there is no witness table (fork decision F-010 / SC-1,
// fork/structural/plan.md D-SC-4, §1.B.3).

// --- compound.carbon
library "[[@TEST_NAME]]";

template constraint HasGet {
  fn Get(self) -> i32;
}

class C {
  fn Get(unused self) -> i32 { return 1; }
}

//@dump-sem-ir-begin
fn F[template T: HasGet](x: T) -> i32 { return x.(HasGet.Get)(); }

fn Test(c: C) -> i32 { return F(c); }
//@dump-sem-ir-end

// --- fail_compound_unsatisfied.carbon
library "[[@TEST_NAME]]";

// The binding itself is unconstrained, so the compound access is what checks
// the base type against `HasGet`.
template constraint HasGet {
  fn Get(self) -> i32;
}

class D {
  // CHECK:STDERR: fail_compound_unsatisfied.carbon:[[@LINE+4]]:12: warning: binding `self` unused [UnusedBinding]
  // CHECK:STDERR:   fn Other(self) -> i32 { return 0; }
  // CHECK:STDERR:            ^~~~
  // CHECK:STDERR:
  fn Other(self) -> i32 { return 0; }
}

fn F[template T: type](x: T) -> i32 { return x.(HasGet.Get)(); }

fn Test(d: D) -> i32 {
  // CHECK:STDERR: fail_compound_unsatisfied.carbon:[[@LINE+13]]:10: error: unable to monomorphize specific `F(D)` [ResolvingSpecificHere]
  // CHECK:STDERR:   return F(d);
  // CHECK:STDERR:          ^
  // CHECK:STDERR: fail_compound_unsatisfied.carbon:[[@LINE-6]]:46: note: cannot convert type `D` into type implementing `HasGet` [ConversionFailureTypeToFacet]
  // CHECK:STDERR: fn F[template T: type](x: T) -> i32 { return x.(HasGet.Get)(); }
  // CHECK:STDERR:                                              ^~~~~~~~~~~~~~
  // CHECK:STDERR: fail_compound_unsatisfied.carbon:[[@LINE-9]]:46: note: type `D` has no member named `Get` required by template constraint `HasGet` [StructuralMemberMissing]
  // CHECK:STDERR: fn F[template T: type](x: T) -> i32 { return x.(HasGet.Get)(); }
  // CHECK:STDERR:                                              ^~~~~~~~~~~~~~
  // CHECK:STDERR: fail_compound_unsatisfied.carbon:[[@LINE-23]]:3: note: requirement declared here [StructuralRequirementHere]
  // CHECK:STDERR:   fn Get(self) -> i32;
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  return F(d);
}

// --- assoc_fn_compound.carbon
library "[[@TEST_NAME]]";

// An associated-function requirement through compound access: the base itself,
// a type or a facet, is converted to the constraint, as for an interface's
// non-instance member (fill round 2, review finding MAJOR-1).
template constraint HasMake {
  fn Make() -> Self;
}

class C {
  fn Make() -> C { return {}; }
}

//@dump-sem-ir-begin
fn ViaT(template T: HasMake) -> T { return T.(HasMake.Make)(); }

fn ViaType() -> C { return C.(HasMake.Make)(); }

fn ViaFacet() -> C { return (C as HasMake).(HasMake.Make)(); }

fn Test() -> C { return ViaT(C); }
//@dump-sem-ir-end

// --- fail_assoc_fn_compound_unsatisfied.carbon
library "[[@TEST_NAME]]";

// The negative of `assoc_fn_compound`: the type base `D` is converted to the
// constraint and fails, with `ConversionFailureTypeToFacet`,
// `StructuralMemberMissing` and `StructuralRequirementHere` at the compound
// access (fill round 2, review finding MAJOR-1; comment added at fill round 3,
// review finding F9).
template constraint HasMake {
  fn Make() -> Self;
}

class D {}

fn Test() -> D {
  // CHECK:STDERR: fail_assoc_fn_compound_unsatisfied.carbon:[[@LINE+10]]:10: error: cannot convert type `D` into type implementing `HasMake` [ConversionFailureTypeToFacet]
  // CHECK:STDERR:   return D.(HasMake.Make)();
  // CHECK:STDERR:          ^~~~~~~~~~~~~~~~
  // CHECK:STDERR: fail_assoc_fn_compound_unsatisfied.carbon:[[@LINE+7]]:10: note: type `D` has no member named `Make` required by template constraint `HasMake` [StructuralMemberMissing]
  // CHECK:STDERR:   return D.(HasMake.Make)();
  // CHECK:STDERR:          ^~~~~~~~~~~~~~~~
  // CHECK:STDERR: fail_assoc_fn_compound_unsatisfied.carbon:[[@LINE-12]]:3: note: requirement declared here [StructuralRequirementHere]
  // CHECK:STDERR:   fn Make() -> Self;
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  return D.(HasMake.Make)();
}

// --- checked_generic_name.carbon
library "[[@TEST_NAME]]";

// A requirement named through its facet type has `Self := .Self` of the
// constraint's facet type (D-SC-20): naming it in a checked generic attaches
// nothing to that generic's eval block, and in a non-generic function the
// compound access is not template-dependent (fill round 1, fix 2; fill round 2,
// review findings F3 / F4).
template constraint HasGet {
  fn Get(self) -> i32;
}

class C {
  fn Get(unused self) -> i32 { return 1; }
}

//@dump-sem-ir-begin
fn G[T: type](unused x: T) { HasGet.Get; }

fn Test(c: C) -> i32 {
  G(c);
  return c.(HasGet.Get)();
}
//@dump-sem-ir-end

// CHECK:STDOUT: --- compound.carbon
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
// CHECK:STDOUT:   %C.Get.type: type = fn_type @C.Get [concrete]
// CHECK:STDOUT:   %C.Get: %C.Get.type = struct_value () [concrete]
// CHECK:STDOUT:   %empty_struct_type: type = struct_type {} [concrete]
// CHECK:STDOUT:   %complete_type.357: <witness> = complete_type_witness %empty_struct_type [concrete]
// CHECK:STDOUT:   %.Self.frozen: type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %pattern_type.9a587c.2: type = pattern_type %HasGet.type [concrete]
// CHECK:STDOUT:   %T.patt.3a0592.2: %pattern_type.9a587c.2 = symbolic_binding_pattern T, 0, template [template]
// CHECK:STDOUT:   %T.f45: %HasGet.type = symbolic_binding T, 0, template [template]
// CHECK:STDOUT:   %T.as_type.190: type = facet_access_type %T.f45 [template]
// CHECK:STDOUT:   %pattern_type.86a: type = pattern_type %T.as_type.190 [template]
// CHECK:STDOUT:   %x.param_patt.9a2: %pattern_type.86a = value_param_pattern [template]
// CHECK:STDOUT:   %x.patt.37f: %pattern_type.86a = wrapper_binding_pattern x, %x.param_patt.9a2 [template]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete.5ef: <witness> = require_complete_type %T.as_type.190 [template]
// CHECK:STDOUT:   %.Self: %HasGet.type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %HasGet.WithSelf.Get.type.c2e: type = fn_type @HasGet.WithSelf.Get, @HasGet.WithSelf(%.Self) [symbolic_self]
// CHECK:STDOUT:   %HasGet.WithSelf.Get.14c: %HasGet.WithSelf.Get.type.c2e = struct_value () [symbolic_self]
// CHECK:STDOUT:   %.8cb: type = type_of_inst @F.%.loc12_49.3 [template]
// CHECK:STDOUT:   %.c23: %.8cb = splice_inst @F.%.loc12_49.3 [template]
// CHECK:STDOUT:   %.3a3: type = type_of_inst @F.%.loc12_63.3 [template]
// CHECK:STDOUT:   %.e29: %.3a3 = splice_inst @F.%.loc12_63.3 [template]
// CHECK:STDOUT:   %.28a: %i32 = splice_inst @F.%.loc12_64.2 [template]
// CHECK:STDOUT:   %c.param_patt: %pattern_type.98b = value_param_pattern [concrete]
// CHECK:STDOUT:   %c.patt: %pattern_type.98b = wrapper_binding_pattern c, %c.param_patt [concrete]
// CHECK:STDOUT:   %Test.type: type = fn_type @Test [concrete]
// CHECK:STDOUT:   %Test: %Test.type = struct_value () [concrete]
// CHECK:STDOUT:   %HasGet.facet.f83123.1: %HasGet.type = facet_value %C, () [concrete]
// CHECK:STDOUT:   %x.param_patt.0f9: %pattern_type.98b = value_param_pattern [concrete]
// CHECK:STDOUT:   %x.patt.953: %pattern_type.98b = wrapper_binding_pattern x, %x.param_patt.0f9 [concrete]
// CHECK:STDOUT:   %F.specific_fn: <specific function> = specific_function %F, @F(%HasGet.facet.f83123.1) [concrete]
// CHECK:STDOUT:   %inst.splice_block.426619.1: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.294: <bound method> = splice_block %C.Get.bound {
// CHECK:STDOUT:       %.fa1: %C = specific_inst @F.%x.ref, @F(%HasGet.facet.f83123.1)
// CHECK:STDOUT:       <elided>
// CHECK:STDOUT:       %HasGet.facet.f83123.2: %HasGet.type = facet_value %C, () [concrete = %HasGet.facet.f83123.1]
// CHECK:STDOUT:       %.549: %HasGet.type = converted %C, %HasGet.facet.f83123.2 [concrete = %HasGet.facet.f83123.1]
// CHECK:STDOUT:       %Get.ref: %C.Get.type = name_ref Get, @C.%C.Get.decl [concrete = %C.Get]
// CHECK:STDOUT:       %C.Get.bound: <bound method> = bound_method %.fa1, %Get.ref
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %inst.call: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %C.Get.call: init %i32 = call %.294(%.fa1)
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %inst.splice_block.426619.2: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.543: init %i32 = splice_block %C.Get.call {}
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %F.decl: %F.type = fn_decl @F [concrete = constants.%F] {
// CHECK:STDOUT:     %T.patt.loc12_16.1: %pattern_type.9a587c.2 = symbolic_binding_pattern T, 0, template [template = %T.patt.loc12_16.2 (constants.%T.patt.3a0592.2)]
// CHECK:STDOUT:     %x.param_patt.loc12_27.1: @F.%pattern_type (%pattern_type.86a) = value_param_pattern [template = %x.param_patt.loc12_27.2 (constants.%x.param_patt.9a2)]
// CHECK:STDOUT:     %x.patt.loc12_27.1: @F.%pattern_type (%pattern_type.86a) = wrapper_binding_pattern x, %x.param_patt.loc12_27.1 [template = %x.patt.loc12_27.2 (constants.%x.patt.37f)]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc12_35: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %.loc12_18: type = splice_block %HasGet.ref.loc12_18 [concrete = constants.%HasGet.type] {
// CHECK:STDOUT:       %.Self.frozen: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %HasGet.ref.loc12_18: type = name_ref HasGet, file.%HasGet.decl [concrete = constants.%HasGet.type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc12_16.2: %HasGet.type = symbolic_binding T, 0, template [template = %T.loc12_16.1 (constants.%T.f45)]
// CHECK:STDOUT:     %x.param: @F.%T.as_type.loc12_29.1 (%T.as_type.190) = value_param call_param0
// CHECK:STDOUT:     %.loc12_29.1: type = splice_block %.loc12_29.2 [template = %T.as_type.loc12_29.1 (constants.%T.as_type.190)] {
// CHECK:STDOUT:       %T.ref: %HasGet.type = name_ref T, %T.loc12_16.2 [template = %T.loc12_16.1 (constants.%T.f45)]
// CHECK:STDOUT:       %T.as_type.loc12_29.2: type = facet_access_type %T.ref [template = %T.as_type.loc12_29.1 (constants.%T.as_type.190)]
// CHECK:STDOUT:       %.loc12_29.2: type = converted %T.ref, %T.as_type.loc12_29.2 [template = %T.as_type.loc12_29.1 (constants.%T.as_type.190)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %x: @F.%T.as_type.loc12_29.1 (%T.as_type.190) = wrapper_binding x, %x.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
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
// CHECK:STDOUT: generic fn @F(%T.loc12_16.2: %HasGet.type) {
// CHECK:STDOUT:   %T.patt.loc12_16.2: %pattern_type.9a587c.2 = symbolic_binding_pattern T, 0, template [template = %T.patt.loc12_16.2 (constants.%T.patt.3a0592.2)]
// CHECK:STDOUT:   %T.loc12_16.1: %HasGet.type = symbolic_binding T, 0, template [template = %T.loc12_16.1 (constants.%T.f45)]
// CHECK:STDOUT:   %T.as_type.loc12_29.1: type = facet_access_type %T.loc12_16.1 [template = %T.as_type.loc12_29.1 (constants.%T.as_type.190)]
// CHECK:STDOUT:   %pattern_type: type = pattern_type %T.as_type.loc12_29.1 [template = %pattern_type (constants.%pattern_type.86a)]
// CHECK:STDOUT:   %x.param_patt.loc12_27.2: @F.%pattern_type (%pattern_type.86a) = value_param_pattern [template = %x.param_patt.loc12_27.2 (constants.%x.param_patt.9a2)]
// CHECK:STDOUT:   %x.patt.loc12_27.2: @F.%pattern_type (%pattern_type.86a) = wrapper_binding_pattern x, %x.param_patt.loc12_27.2 [template = %x.patt.loc12_27.2 (constants.%x.patt.37f)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete: <witness> = require_complete_type %T.as_type.loc12_29.1 [template = %require_complete (constants.%require_complete.5ef)]
// CHECK:STDOUT:   %.loc12_49.3: <instruction> = compound_member_access_action %x.ref, %Get.ref [template]
// CHECK:STDOUT:   %.loc12_49.4: type = type_of_inst %.loc12_49.3 [template = %.loc12_49.4 (constants.%.8cb)]
// CHECK:STDOUT:   %.loc12_49.5: @F.%.loc12_49.4 (%.8cb) = splice_inst %.loc12_49.3 [template = %.loc12_49.5 (constants.%.c23)]
// CHECK:STDOUT:   %.loc12_63.3: <instruction> = call_action (%.loc12_49.2), false [template]
// CHECK:STDOUT:   %.loc12_63.4: type = type_of_inst %.loc12_63.3 [template = %.loc12_63.4 (constants.%.3a3)]
// CHECK:STDOUT:   %.loc12_63.5: @F.%.loc12_63.4 (%.3a3) = splice_inst %.loc12_63.3 [template = %.loc12_63.5 (constants.%.e29)]
// CHECK:STDOUT:   %.loc12_64.2: <instruction> = convert_action %.loc12_63.2, constants.%i32, element10 [template]
// CHECK:STDOUT:   %.loc12_64.3: %i32 = splice_inst %.loc12_64.2 [template = %.loc12_64.3 (constants.%.28a)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%x.param: @F.%T.as_type.loc12_29.1 (%T.as_type.190)) -> out %return.param: %i32 {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %x.ref: @F.%T.as_type.loc12_29.1 (%T.as_type.190) = name_ref x, %x
// CHECK:STDOUT:     %HasGet.ref.loc12_51: type = name_ref HasGet, file.%HasGet.decl [concrete = constants.%HasGet.type]
// CHECK:STDOUT:     %.loc12_57: %HasGet.WithSelf.Get.type.c2e = specific_constant @HasGet.WithSelf.%HasGet.WithSelf.Get.decl, @HasGet.WithSelf(constants.%.Self) [symbolic_self = constants.%HasGet.WithSelf.Get.14c]
// CHECK:STDOUT:     %Get.ref: %HasGet.WithSelf.Get.type.c2e = name_ref Get, %.loc12_57 [symbolic_self = constants.%HasGet.WithSelf.Get.14c]
// CHECK:STDOUT:     %.loc12_49.1: type = type_of_inst %.loc12_49.3 [template = %.loc12_49.4 (constants.%.8cb)]
// CHECK:STDOUT:     %.loc12_49.2: @F.%.loc12_49.4 (%.8cb) = splice_inst %.loc12_49.3 [template = %.loc12_49.5 (constants.%.c23)]
// CHECK:STDOUT:     %.loc12_63.1: type = type_of_inst %.loc12_63.3 [template = %.loc12_63.4 (constants.%.3a3)]
// CHECK:STDOUT:     %.loc12_63.2: @F.%.loc12_63.4 (%.3a3) = splice_inst %.loc12_63.3 [template = %.loc12_63.5 (constants.%.e29)]
// CHECK:STDOUT:     %.loc12_64.1: %i32 = splice_inst %.loc12_64.2 [template = %.loc12_64.3 (constants.%.28a)]
// CHECK:STDOUT:     return %.loc12_64.1
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Test(%c.param: %C) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %F.ref: %F.type = name_ref F, file.%F.decl [concrete = constants.%F]
// CHECK:STDOUT:   %c.ref: %C = name_ref c, %c
// CHECK:STDOUT:   %HasGet.facet.loc14_34.1: %HasGet.type = facet_value constants.%C, () [concrete = constants.%HasGet.facet.f83123.1]
// CHECK:STDOUT:   %.loc14_34.1: %HasGet.type = converted constants.%C, %HasGet.facet.loc14_34.1 [concrete = constants.%HasGet.facet.f83123.1]
// CHECK:STDOUT:   %HasGet.facet.loc14_34.2: %HasGet.type = facet_value constants.%C, () [concrete = constants.%HasGet.facet.f83123.1]
// CHECK:STDOUT:   %.loc14_34.2: %HasGet.type = converted constants.%C, %HasGet.facet.loc14_34.2 [concrete = constants.%HasGet.facet.f83123.1]
// CHECK:STDOUT:   %F.specific_fn: <specific function> = specific_function %F.ref, @F(constants.%HasGet.facet.f83123.1) [concrete = constants.%F.specific_fn]
// CHECK:STDOUT:   %F.call: init %i32 = call %F.specific_fn(%c.ref)
// CHECK:STDOUT:   return %F.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @F(constants.%T.f45) {
// CHECK:STDOUT:   %T.patt.loc12_16.2 => constants.%T.patt.3a0592.2
// CHECK:STDOUT:   %T.loc12_16.1 => constants.%T.f45
// CHECK:STDOUT:   %T.as_type.loc12_29.1 => constants.%T.as_type.190
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.86a
// CHECK:STDOUT:   %x.param_patt.loc12_27.2 => constants.%x.param_patt.9a2
// CHECK:STDOUT:   %x.patt.loc12_27.2 => constants.%x.patt.37f
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @F(constants.%HasGet.facet.f83123.1) {
// CHECK:STDOUT:   %T.patt.loc12_16.2 => constants.%T.patt.3a0592.2
// CHECK:STDOUT:   %T.loc12_16.1 => constants.%HasGet.facet.f83123.1
// CHECK:STDOUT:   %T.as_type.loc12_29.1 => constants.%C
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.98b
// CHECK:STDOUT:   %x.param_patt.loc12_27.2 => constants.%x.param_patt.0f9
// CHECK:STDOUT:   %x.patt.loc12_27.2 => constants.%x.patt.953
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete => constants.%complete_type.357
// CHECK:STDOUT:   %.loc12_49.3 => constants.%inst.splice_block.426619.1
// CHECK:STDOUT:   %.loc12_49.4 => <bound method>
// CHECK:STDOUT:   %.loc12_49.5 => <not constant>
// CHECK:STDOUT:   %.loc12_63.3 => constants.%inst.call
// CHECK:STDOUT:   %.loc12_63.4 => constants.%i32
// CHECK:STDOUT:   %.loc12_63.5 => <not constant>
// CHECK:STDOUT:   %.loc12_64.2 => constants.%inst.splice_block.426619.2
// CHECK:STDOUT:   %.loc12_64.3 => <not constant>
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- assoc_fn_compound.carbon
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
// CHECK:STDOUT:   %ViaT.type: type = fn_type @ViaT [concrete]
// CHECK:STDOUT:   %ViaT: %ViaT.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete: <witness> = require_complete_type %T.as_type [template]
// CHECK:STDOUT:   %.Self: %HasMake.type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %HasMake.WithSelf.Make.type.ef4: type = fn_type @HasMake.WithSelf.Make, @HasMake.WithSelf(%.Self) [symbolic_self]
// CHECK:STDOUT:   %HasMake.WithSelf.Make.7a9: %HasMake.WithSelf.Make.type.ef4 = struct_value () [symbolic_self]
// CHECK:STDOUT:   %.8cb: type = type_of_inst @ViaT.%.loc15_45.3 [template]
// CHECK:STDOUT:   %.c23: %.8cb = splice_inst @ViaT.%.loc15_45.3 [template]
// CHECK:STDOUT:   %.3a3: type = type_of_inst @ViaT.%.loc15_61.3 [template]
// CHECK:STDOUT:   %.e29: %.3a3 = splice_inst @ViaT.%.loc15_61.3 [template]
// CHECK:STDOUT:   %tuple.type: type = tuple_type (<instruction>) [concrete]
// CHECK:STDOUT:   %.762: %T.as_type = splice_inst @ViaT.%tuple.elem0 [template]
// CHECK:STDOUT:   %ViaType.type: type = fn_type @ViaType [concrete]
// CHECK:STDOUT:   %ViaType: %ViaType.type = struct_value () [concrete]
// CHECK:STDOUT:   %HasMake.facet: %HasMake.type = facet_value %C, () [concrete]
// CHECK:STDOUT:   %ViaFacet.type: type = fn_type @ViaFacet [concrete]
// CHECK:STDOUT:   %ViaFacet: %ViaFacet.type = struct_value () [concrete]
// CHECK:STDOUT:   %Test.type: type = fn_type @Test [concrete]
// CHECK:STDOUT:   %Test: %Test.type = struct_value () [concrete]
// CHECK:STDOUT:   %ViaT.specific_fn: <specific function> = specific_function %ViaT, @ViaT(%HasMake.facet) [concrete]
// CHECK:STDOUT:   %inst.splice_block.426619.1: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.80f: %C.Make.type = splice_block %Make.ref [concrete = %C.Make] {
// CHECK:STDOUT:       <elided>
// CHECK:STDOUT:       %Make.ref: %C.Make.type = name_ref Make, @C.%C.Make.decl [concrete = %C.Make]
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %inst.splice_block.426619.2: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.4b9: init %C = splice_block %C.Make.call {
// CHECK:STDOUT:       %.973: ref %C = specific_inst @ViaT.%return.param, @ViaT(%HasMake.facet)
// CHECK:STDOUT:       %C.Make.call: init %C to %.973 = call %C.Make()
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %inst.splice_block.426619.3: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.ddb: init %C = splice_block %.4b9 {}
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %tuple: %tuple.type = tuple_value (%inst.splice_block.426619.3) [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %ViaT.decl: %ViaT.type = fn_decl @ViaT [concrete = constants.%ViaT] {
// CHECK:STDOUT:     %T.patt.loc15_19.1: %pattern_type.9a5 = symbolic_binding_pattern T, 0, template [template = %T.patt.loc15_19.2 (constants.%T.patt)]
// CHECK:STDOUT:     %return.param_patt.loc15_33.1: @ViaT.%pattern_type (%pattern_type.86a) = out_param_pattern [template = %return.param_patt.loc15_33.2 (constants.%return.param_patt.5f6)]
// CHECK:STDOUT:     %return.patt.loc15_30.1: @ViaT.%pattern_type (%pattern_type.86a) = return_slot_pattern %return.param_patt.loc15_33.1, %.loc15_33.2 [template = %return.patt.loc15_30.2 (constants.%return.patt.96a)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %T.ref.loc15_33: %HasMake.type = name_ref T, %T.loc15_19.2 [template = %T.loc15_19.1 (constants.%T)]
// CHECK:STDOUT:     %T.as_type.loc15_33.2: type = facet_access_type %T.ref.loc15_33 [template = %T.as_type.loc15_33.1 (constants.%T.as_type)]
// CHECK:STDOUT:     %.loc15_33.2: type = converted %T.ref.loc15_33, %T.as_type.loc15_33.2 [template = %T.as_type.loc15_33.1 (constants.%T.as_type)]
// CHECK:STDOUT:     %.loc15_33.3: Core.Form = init_form %.loc15_33.2 [template = %.loc15_33.1 (constants.%.1f0)]
// CHECK:STDOUT:     %.loc15_21: type = splice_block %HasMake.ref.loc15_21 [concrete = constants.%HasMake.type] {
// CHECK:STDOUT:       %.Self.frozen: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %HasMake.ref.loc15_21: type = name_ref HasMake, file.%HasMake.decl [concrete = constants.%HasMake.type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc15_19.2: %HasMake.type = symbolic_binding T, 0, template [template = %T.loc15_19.1 (constants.%T)]
// CHECK:STDOUT:     %return.param: ref @ViaT.%T.as_type.loc15_33.1 (%T.as_type) = out_param call_param0
// CHECK:STDOUT:     %return: ref @ViaT.%T.as_type.loc15_33.1 (%T.as_type) = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %ViaType.decl: %ViaType.type = fn_decl @ViaType [concrete = constants.%ViaType] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.98b = out_param_pattern [concrete = constants.%return.param_patt.89a]
// CHECK:STDOUT:     %return.patt: %pattern_type.98b = return_slot_pattern %return.param_patt, %C.ref.loc17_17 [concrete = constants.%return.patt.e4a]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %C.ref.loc17_17: type = name_ref C, file.%C.decl [concrete = constants.%C]
// CHECK:STDOUT:     %.loc17_17.2: Core.Form = init_form %C.ref.loc17_17 [concrete = constants.%.a44]
// CHECK:STDOUT:     %return.param: ref %C = out_param call_param0
// CHECK:STDOUT:     %return: ref %C = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %ViaFacet.decl: %ViaFacet.type = fn_decl @ViaFacet [concrete = constants.%ViaFacet] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.98b = out_param_pattern [concrete = constants.%return.param_patt.89a]
// CHECK:STDOUT:     %return.patt: %pattern_type.98b = return_slot_pattern %return.param_patt, %C.ref.loc19_18 [concrete = constants.%return.patt.e4a]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %C.ref.loc19_18: type = name_ref C, file.%C.decl [concrete = constants.%C]
// CHECK:STDOUT:     %.loc19_18.2: Core.Form = init_form %C.ref.loc19_18 [concrete = constants.%.a44]
// CHECK:STDOUT:     %return.param: ref %C = out_param call_param0
// CHECK:STDOUT:     %return: ref %C = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Test.decl: %Test.type = fn_decl @Test [concrete = constants.%Test] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.98b = out_param_pattern [concrete = constants.%return.param_patt.89a]
// CHECK:STDOUT:     %return.patt: %pattern_type.98b = return_slot_pattern %return.param_patt, %C.ref.loc21_14 [concrete = constants.%return.patt.e4a]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %C.ref.loc21_14: type = name_ref C, file.%C.decl [concrete = constants.%C]
// CHECK:STDOUT:     %.loc21_14.2: Core.Form = init_form %C.ref.loc21_14 [concrete = constants.%.a44]
// CHECK:STDOUT:     %return.param: ref %C = out_param call_param0
// CHECK:STDOUT:     %return: ref %C = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @ViaT(%T.loc15_19.2: %HasMake.type) {
// CHECK:STDOUT:   %T.patt.loc15_19.2: %pattern_type.9a5 = symbolic_binding_pattern T, 0, template [template = %T.patt.loc15_19.2 (constants.%T.patt)]
// CHECK:STDOUT:   %T.loc15_19.1: %HasMake.type = symbolic_binding T, 0, template [template = %T.loc15_19.1 (constants.%T)]
// CHECK:STDOUT:   %T.as_type.loc15_33.1: type = facet_access_type %T.loc15_19.1 [template = %T.as_type.loc15_33.1 (constants.%T.as_type)]
// CHECK:STDOUT:   %.loc15_33.1: Core.Form = init_form %T.as_type.loc15_33.1 [template = %.loc15_33.1 (constants.%.1f0)]
// CHECK:STDOUT:   %pattern_type: type = pattern_type %T.as_type.loc15_33.1 [template = %pattern_type (constants.%pattern_type.86a)]
// CHECK:STDOUT:   %return.param_patt.loc15_33.2: @ViaT.%pattern_type (%pattern_type.86a) = out_param_pattern [template = %return.param_patt.loc15_33.2 (constants.%return.param_patt.5f6)]
// CHECK:STDOUT:   %return.patt.loc15_30.2: @ViaT.%pattern_type (%pattern_type.86a) = return_slot_pattern %return.param_patt.loc15_33.2, %T.as_type.loc15_33.1 [template = %return.patt.loc15_30.2 (constants.%return.patt.96a)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete: <witness> = require_complete_type %T.as_type.loc15_33.1 [template = %require_complete (constants.%require_complete)]
// CHECK:STDOUT:   %.loc15_45.3: <instruction> = compound_member_access_action %T.ref.loc15_44, %Make.ref [template]
// CHECK:STDOUT:   %.loc15_45.4: type = type_of_inst %.loc15_45.3 [template = %.loc15_45.4 (constants.%.8cb)]
// CHECK:STDOUT:   %.loc15_45.5: @ViaT.%.loc15_45.4 (%.8cb) = splice_inst %.loc15_45.3 [template = %.loc15_45.5 (constants.%.c23)]
// CHECK:STDOUT:   %.loc15_61.3: <instruction> = call_action (%.loc15_45.2), false [template]
// CHECK:STDOUT:   %.loc15_61.4: type = type_of_inst %.loc15_61.3 [template = %.loc15_61.4 (constants.%.3a3)]
// CHECK:STDOUT:   %.loc15_61.5: @ViaT.%.loc15_61.4 (%.3a3) = splice_inst %.loc15_61.3 [template = %.loc15_61.5 (constants.%.e29)]
// CHECK:STDOUT:   %.loc15_62.2: %tuple.type = initialize_action %.loc15_61.2, %T.as_type.loc15_33.1, %return.param, false [template]
// CHECK:STDOUT:   %tuple.elem0: <instruction> = tuple_access %.loc15_62.2, element0 [template]
// CHECK:STDOUT:   %.loc15_62.3: @ViaT.%T.as_type.loc15_33.1 (%T.as_type) = splice_inst %tuple.elem0 [template = %.loc15_62.3 (constants.%.762)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn() -> out %return.param: @ViaT.%T.as_type.loc15_33.1 (%T.as_type) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %T.ref.loc15_44: %HasMake.type = name_ref T, %T.loc15_19.2 [template = %T.loc15_19.1 (constants.%T)]
// CHECK:STDOUT:     %HasMake.ref.loc15_47: type = name_ref HasMake, file.%HasMake.decl [concrete = constants.%HasMake.type]
// CHECK:STDOUT:     %.loc15_54: %HasMake.WithSelf.Make.type.ef4 = specific_constant @HasMake.WithSelf.%HasMake.WithSelf.Make.decl, @HasMake.WithSelf(constants.%.Self) [symbolic_self = constants.%HasMake.WithSelf.Make.7a9]
// CHECK:STDOUT:     %Make.ref: %HasMake.WithSelf.Make.type.ef4 = name_ref Make, %.loc15_54 [symbolic_self = constants.%HasMake.WithSelf.Make.7a9]
// CHECK:STDOUT:     %.loc15_45.1: type = type_of_inst %.loc15_45.3 [template = %.loc15_45.4 (constants.%.8cb)]
// CHECK:STDOUT:     %.loc15_45.2: @ViaT.%.loc15_45.4 (%.8cb) = splice_inst %.loc15_45.3 [template = %.loc15_45.5 (constants.%.c23)]
// CHECK:STDOUT:     %.loc15_61.1: type = type_of_inst %.loc15_61.3 [template = %.loc15_61.4 (constants.%.3a3)]
// CHECK:STDOUT:     %.loc15_61.2: @ViaT.%.loc15_61.4 (%.3a3) = splice_inst %.loc15_61.3 [template = %.loc15_61.5 (constants.%.e29)]
// CHECK:STDOUT:     %.loc15_62.1: @ViaT.%T.as_type.loc15_33.1 (%T.as_type) = splice_inst %tuple.elem0 [template = %.loc15_62.3 (constants.%.762)]
// CHECK:STDOUT:     return %.loc15_62.1 to %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @ViaType() -> out %return.param: %C {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %C.ref.loc17_28: type = name_ref C, file.%C.decl [concrete = constants.%C]
// CHECK:STDOUT:   %HasMake.ref: type = name_ref HasMake, file.%HasMake.decl [concrete = constants.%HasMake.type]
// CHECK:STDOUT:   %.loc17_38: %HasMake.WithSelf.Make.type.ef4 = specific_constant @HasMake.WithSelf.%HasMake.WithSelf.Make.decl, @HasMake.WithSelf(constants.%.Self) [symbolic_self = constants.%HasMake.WithSelf.Make.7a9]
// CHECK:STDOUT:   %Make.ref.loc17_38: %HasMake.WithSelf.Make.type.ef4 = name_ref Make, %.loc17_38 [symbolic_self = constants.%HasMake.WithSelf.Make.7a9]
// CHECK:STDOUT:   %HasMake.facet: %HasMake.type = facet_value %C.ref.loc17_28, () [concrete = constants.%HasMake.facet]
// CHECK:STDOUT:   %.loc17_29: %HasMake.type = converted %C.ref.loc17_28, %HasMake.facet [concrete = constants.%HasMake.facet]
// CHECK:STDOUT:   %Make.ref.loc17_29: %C.Make.type = name_ref Make, @C.%C.Make.decl [concrete = constants.%C.Make]
// CHECK:STDOUT:   %.loc17_17.1: ref %C = splice_block %return.param {}
// CHECK:STDOUT:   %C.Make.call: init %C to %.loc17_17.1 = call %Make.ref.loc17_29()
// CHECK:STDOUT:   return %C.Make.call to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @ViaFacet() -> out %return.param: %C {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %C.ref.loc19_30: type = name_ref C, file.%C.decl [concrete = constants.%C]
// CHECK:STDOUT:   %HasMake.ref.loc19_35: type = name_ref HasMake, file.%HasMake.decl [concrete = constants.%HasMake.type]
// CHECK:STDOUT:   %HasMake.facet: %HasMake.type = facet_value %C.ref.loc19_30, () [concrete = constants.%HasMake.facet]
// CHECK:STDOUT:   %.loc19_32: %HasMake.type = converted %C.ref.loc19_30, %HasMake.facet [concrete = constants.%HasMake.facet]
// CHECK:STDOUT:   %HasMake.ref.loc19_45: type = name_ref HasMake, file.%HasMake.decl [concrete = constants.%HasMake.type]
// CHECK:STDOUT:   %.loc19_52: %HasMake.WithSelf.Make.type.ef4 = specific_constant @HasMake.WithSelf.%HasMake.WithSelf.Make.decl, @HasMake.WithSelf(constants.%.Self) [symbolic_self = constants.%HasMake.WithSelf.Make.7a9]
// CHECK:STDOUT:   %Make.ref.loc19_52: %HasMake.WithSelf.Make.type.ef4 = name_ref Make, %.loc19_52 [symbolic_self = constants.%HasMake.WithSelf.Make.7a9]
// CHECK:STDOUT:   %Make.ref.loc19_43: %C.Make.type = name_ref Make, @C.%C.Make.decl [concrete = constants.%C.Make]
// CHECK:STDOUT:   %.loc19_18.1: ref %C = splice_block %return.param {}
// CHECK:STDOUT:   %C.Make.call: init %C to %.loc19_18.1 = call %Make.ref.loc19_43()
// CHECK:STDOUT:   return %C.Make.call to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Test() -> out %return.param: %C {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %ViaT.ref: %ViaT.type = name_ref ViaT, file.%ViaT.decl [concrete = constants.%ViaT]
// CHECK:STDOUT:   %C.ref.loc21_30: type = name_ref C, file.%C.decl [concrete = constants.%C]
// CHECK:STDOUT:   %HasMake.facet: %HasMake.type = facet_value %C.ref.loc21_30, () [concrete = constants.%HasMake.facet]
// CHECK:STDOUT:   %.loc21_31: %HasMake.type = converted %C.ref.loc21_30, %HasMake.facet [concrete = constants.%HasMake.facet]
// CHECK:STDOUT:   %ViaT.specific_fn: <specific function> = specific_function %ViaT.ref, @ViaT(constants.%HasMake.facet) [concrete = constants.%ViaT.specific_fn]
// CHECK:STDOUT:   %.loc21_14.1: ref %C = splice_block %return.param {}
// CHECK:STDOUT:   %ViaT.call: init %C to %.loc21_14.1 = call %ViaT.specific_fn()
// CHECK:STDOUT:   return %ViaT.call to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @ViaT(constants.%T) {
// CHECK:STDOUT:   %T.patt.loc15_19.2 => constants.%T.patt
// CHECK:STDOUT:   %T.loc15_19.1 => constants.%T
// CHECK:STDOUT:   %T.as_type.loc15_33.1 => constants.%T.as_type
// CHECK:STDOUT:   %.loc15_33.1 => constants.%.1f0
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.86a
// CHECK:STDOUT:   %return.param_patt.loc15_33.2 => constants.%return.param_patt.5f6
// CHECK:STDOUT:   %return.patt.loc15_30.2 => constants.%return.patt.96a
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @ViaT(constants.%HasMake.facet) {
// CHECK:STDOUT:   %T.patt.loc15_19.2 => constants.%T.patt
// CHECK:STDOUT:   %T.loc15_19.1 => constants.%HasMake.facet
// CHECK:STDOUT:   %T.as_type.loc15_33.1 => constants.%C
// CHECK:STDOUT:   %.loc15_33.1 => constants.%.a44
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.98b
// CHECK:STDOUT:   %return.param_patt.loc15_33.2 => constants.%return.param_patt.89a
// CHECK:STDOUT:   %return.patt.loc15_30.2 => constants.%return.patt.e4a
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete => constants.%complete_type
// CHECK:STDOUT:   %.loc15_45.3 => constants.%inst.splice_block.426619.1
// CHECK:STDOUT:   %.loc15_45.4 => constants.%C.Make.type
// CHECK:STDOUT:   %.loc15_45.5 => constants.%C.Make
// CHECK:STDOUT:   %.loc15_61.3 => constants.%inst.splice_block.426619.2
// CHECK:STDOUT:   %.loc15_61.4 => constants.%C
// CHECK:STDOUT:   %.loc15_61.5 => <not constant>
// CHECK:STDOUT:   %.loc15_62.2 => constants.%tuple
// CHECK:STDOUT:   %tuple.elem0 => constants.%inst.splice_block.426619.3
// CHECK:STDOUT:   %.loc15_62.3 => <not constant>
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- checked_generic_name.carbon
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
// CHECK:STDOUT:   %C.Get.type: type = fn_type @C.Get [concrete]
// CHECK:STDOUT:   %C.Get: %C.Get.type = struct_value () [concrete]
// CHECK:STDOUT:   %empty_struct_type: type = struct_type {} [concrete]
// CHECK:STDOUT:   %complete_type.357: <witness> = complete_type_witness %empty_struct_type [concrete]
// CHECK:STDOUT:   %pattern_type.9a5: type = pattern_type type [concrete]
// CHECK:STDOUT:   %T.67d: type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %T.patt.3a0: %pattern_type.9a5 = symbolic_binding_pattern T, 0 [symbolic]
// CHECK:STDOUT:   %pattern_type.51d1c4.2: type = pattern_type %T.67d [symbolic]
// CHECK:STDOUT:   %.Self.frozen: type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %x.param_patt.91d: %pattern_type.51d1c4.2 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %x.patt.260: %pattern_type.51d1c4.2 = wrapper_binding_pattern x, %x.param_patt.91d [symbolic]
// CHECK:STDOUT:   %G.type: type = fn_type @G [concrete]
// CHECK:STDOUT:   %G: %G.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete.944: <witness> = require_complete_type %T.67d [symbolic]
// CHECK:STDOUT:   %.Self: %HasGet.type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %HasGet.WithSelf.Get.type.c2e: type = fn_type @HasGet.WithSelf.Get, @HasGet.WithSelf(%.Self) [symbolic_self]
// CHECK:STDOUT:   %HasGet.WithSelf.Get.14c: %HasGet.WithSelf.Get.type.c2e = struct_value () [symbolic_self]
// CHECK:STDOUT:   %c.param_patt: %pattern_type.98b = value_param_pattern [concrete]
// CHECK:STDOUT:   %c.patt: %pattern_type.98b = wrapper_binding_pattern c, %c.param_patt [concrete]
// CHECK:STDOUT:   %Test.type: type = fn_type @Test [concrete]
// CHECK:STDOUT:   %Test: %Test.type = struct_value () [concrete]
// CHECK:STDOUT:   %x.param_patt.0f9: %pattern_type.98b = value_param_pattern [concrete]
// CHECK:STDOUT:   %x.patt.953: %pattern_type.98b = wrapper_binding_pattern x, %x.param_patt.0f9 [concrete]
// CHECK:STDOUT:   %G.specific_fn: <specific function> = specific_function %G, @G(%C) [concrete]
// CHECK:STDOUT:   %HasGet.facet: %HasGet.type = facet_value %C, () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %G.decl: %G.type = fn_decl @G [concrete = constants.%G] {
// CHECK:STDOUT:     %T.patt.loc17_7.1: %pattern_type.9a5 = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc17_7.2 (constants.%T.patt.3a0)]
// CHECK:STDOUT:     %x.param_patt.loc17_23.1: @G.%pattern_type (%pattern_type.51d1c4.2) = value_param_pattern [symbolic = %x.param_patt.loc17_23.2 (constants.%x.param_patt.91d)]
// CHECK:STDOUT:     %x.patt.loc17_23.1: @G.%pattern_type (%pattern_type.51d1c4.2) = wrapper_binding_pattern x, %x.param_patt.loc17_23.1 [symbolic = %x.patt.loc17_23.2 (constants.%x.patt.260)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc17_9.1: type = splice_block %.loc17_9.2 [concrete = type] {
// CHECK:STDOUT:       %.Self.frozen: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %.loc17_9.2: type = type_literal type [concrete = type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc17_7.2: type = symbolic_binding T, 0 [symbolic = %T.loc17_7.1 (constants.%T.67d)]
// CHECK:STDOUT:     %x.param: @G.%T.loc17_7.1 (%T.67d) = value_param call_param0
// CHECK:STDOUT:     %T.ref: type = name_ref T, %T.loc17_7.2 [symbolic = %T.loc17_7.1 (constants.%T.67d)]
// CHECK:STDOUT:     %x: @G.%T.loc17_7.1 (%T.67d) = wrapper_binding x, %x.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Test.decl: %Test.type = fn_decl @Test [concrete = constants.%Test] {
// CHECK:STDOUT:     %c.param_patt: %pattern_type.98b = value_param_pattern [concrete = constants.%c.param_patt]
// CHECK:STDOUT:     %c.patt: %pattern_type.98b = wrapper_binding_pattern c, %c.param_patt [concrete = constants.%c.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc19: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %c.param: %C = value_param call_param0
// CHECK:STDOUT:     %C.ref: type = name_ref C, file.%C.decl [concrete = constants.%C]
// CHECK:STDOUT:     %c: %C = wrapper_binding c, %c.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @G(%T.loc17_7.2: type) {
// CHECK:STDOUT:   %T.patt.loc17_7.2: %pattern_type.9a5 = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc17_7.2 (constants.%T.patt.3a0)]
// CHECK:STDOUT:   %T.loc17_7.1: type = symbolic_binding T, 0 [symbolic = %T.loc17_7.1 (constants.%T.67d)]
// CHECK:STDOUT:   %pattern_type: type = pattern_type %T.loc17_7.1 [symbolic = %pattern_type (constants.%pattern_type.51d1c4.2)]
// CHECK:STDOUT:   %x.param_patt.loc17_23.2: @G.%pattern_type (%pattern_type.51d1c4.2) = value_param_pattern [symbolic = %x.param_patt.loc17_23.2 (constants.%x.param_patt.91d)]
// CHECK:STDOUT:   %x.patt.loc17_23.2: @G.%pattern_type (%pattern_type.51d1c4.2) = wrapper_binding_pattern x, %x.param_patt.loc17_23.2 [symbolic = %x.patt.loc17_23.2 (constants.%x.patt.260)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete: <witness> = require_complete_type %T.loc17_7.1 [symbolic = %require_complete (constants.%require_complete.944)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%x.param: @G.%T.loc17_7.1 (%T.67d)) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %HasGet.ref: type = name_ref HasGet, file.%HasGet.decl [concrete = constants.%HasGet.type]
// CHECK:STDOUT:     %.loc17_36: %HasGet.WithSelf.Get.type.c2e = specific_constant @HasGet.WithSelf.%HasGet.WithSelf.Get.decl, @HasGet.WithSelf(constants.%.Self) [symbolic_self = constants.%HasGet.WithSelf.Get.14c]
// CHECK:STDOUT:     %Get.ref: %HasGet.WithSelf.Get.type.c2e = name_ref Get, %.loc17_36 [symbolic_self = constants.%HasGet.WithSelf.Get.14c]
// CHECK:STDOUT:     return
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Test(%c.param: %C) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %G.ref: %G.type = name_ref G, file.%G.decl [concrete = constants.%G]
// CHECK:STDOUT:   %c.ref.loc20: %C = name_ref c, %c
// CHECK:STDOUT:   %G.specific_fn: <specific function> = specific_function %G.ref, @G(constants.%C) [concrete = constants.%G.specific_fn]
// CHECK:STDOUT:   %G.call: init %empty_tuple.type = call %G.specific_fn(%c.ref.loc20)
// CHECK:STDOUT:   %c.ref.loc21: %C = name_ref c, %c
// CHECK:STDOUT:   %HasGet.ref: type = name_ref HasGet, file.%HasGet.decl [concrete = constants.%HasGet.type]
// CHECK:STDOUT:   %.loc21_19: %HasGet.WithSelf.Get.type.c2e = specific_constant @HasGet.WithSelf.%HasGet.WithSelf.Get.decl, @HasGet.WithSelf(constants.%.Self) [symbolic_self = constants.%HasGet.WithSelf.Get.14c]
// CHECK:STDOUT:   %Get.ref.loc21_19: %HasGet.WithSelf.Get.type.c2e = name_ref Get, %.loc21_19 [symbolic_self = constants.%HasGet.WithSelf.Get.14c]
// CHECK:STDOUT:   %HasGet.facet: %HasGet.type = facet_value constants.%C, () [concrete = constants.%HasGet.facet]
// CHECK:STDOUT:   %.loc21_11: %HasGet.type = converted constants.%C, %HasGet.facet [concrete = constants.%HasGet.facet]
// CHECK:STDOUT:   %Get.ref.loc21_11: %C.Get.type = name_ref Get, @C.%C.Get.decl [concrete = constants.%C.Get]
// CHECK:STDOUT:   %C.Get.bound: <bound method> = bound_method %c.ref.loc21, %Get.ref.loc21_11
// CHECK:STDOUT:   %C.Get.call: init %i32 = call %C.Get.bound(%c.ref.loc21)
// CHECK:STDOUT:   return %C.Get.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @G(constants.%T.67d) {
// CHECK:STDOUT:   %T.patt.loc17_7.2 => constants.%T.patt.3a0
// CHECK:STDOUT:   %T.loc17_7.1 => constants.%T.67d
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.51d1c4.2
// CHECK:STDOUT:   %x.param_patt.loc17_23.2 => constants.%x.param_patt.91d
// CHECK:STDOUT:   %x.patt.loc17_23.2 => constants.%x.patt.260
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @G(constants.%C) {
// CHECK:STDOUT:   %T.patt.loc17_7.2 => constants.%T.patt.3a0
// CHECK:STDOUT:   %T.loc17_7.1 => constants.%C
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.98b
// CHECK:STDOUT:   %x.param_patt.loc17_23.2 => constants.%x.param_patt.0f9
// CHECK:STDOUT:   %x.patt.loc17_23.2 => constants.%x.patt.953
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete => constants.%complete_type.357
// CHECK:STDOUT: }
// CHECK:STDOUT:
