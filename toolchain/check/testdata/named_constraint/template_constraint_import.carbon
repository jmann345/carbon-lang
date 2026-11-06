// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/named_constraint/template_constraint_import.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/named_constraint/template_constraint_import.carbon

// A `template constraint` declared in one library satisfies in another: the
// requirement block is imported with the constraint (fork decision F-010 /
// SC-1, fork/structural/plan.md D-SC-15, review fold A2).

// --- a.carbon
library "[[@TEST_NAME]]";

template constraint HasGet {
  fn Get(self) -> i32;
}

// --- b.carbon
library "[[@TEST_NAME]]";

import library "a";

class C {
  fn Get(unused self) -> i32 { return 1; }
}

fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }

fn Test(c: C) -> i32 { return CallGet(c); }

// --- requirement_type_a.carbon
library "[[@TEST_NAME]]";

// A requirement's type, an alias of a requirement and an impl for the type,
// exported for the two splits below (D-SC-20; fill round 6, both reviews'
// finding MINOR-2: the import of `StructuralRequirementType`,
// check/import_ref.cpp `TryResolveTypedInst`, had no golden).
template constraint HasN {
  fn N() -> i32;
}

template constraint Has(X: type) {
  fn N() -> X;
}

interface Z {
  fn F() -> i32;
}

alias A = HasN.N;

fn P(unused p: typeof(HasN.N)*) -> i32 { return 3; }

impl typeof(Has(i32).N) as Z {
  fn F() -> i32 { return 9; }
}

fn Take[T: type](unused f: T) -> i32 { return 1; }

// --- requirement_type_b.carbon
library "[[@TEST_NAME]]";

import library "requirement_type_a";

class C {
  fn N() -> i32 { return 5; }
}

// The imported alias's type is the imported `typeof(HasN.N)`; the imported
// impl is found for `typeof(Has(i32).N)`; `C.(A)` is `C`'s own `N` (D-SC-4).
//@dump-sem-ir-begin
fn Use(p: typeof(A)*) -> i32 {
  return P(p) + typeof(Has(i32).N).(Z.F)() + C.(A)();
}
//@dump-sem-ir-end

// --- fail_requirement_type_value.carbon
library "[[@TEST_NAME]]";

import library "requirement_type_a";

// An imported requirement is refused as a value as in its own library; an
// imported requirement's type prints as `<type of Has(i32).N>`.
// CHECK:STDERR: fail_requirement_type_value.carbon:[[@LINE+12]]:36: error: requirement `N` of template constraint `HasN` can only be used through a type that satisfies it [StructuralRequirementUsed]
// CHECK:STDERR: fn TakeName() -> i32 { return Take(A); }
// CHECK:STDERR:                                    ^
// CHECK:STDERR: fail_requirement_type_value.carbon:[[@LINE-7]]:1: in import [InImport]
// CHECK:STDERR: requirement_type_a.carbon:8:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn N() -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~
// CHECK:STDERR: fail_requirement_type_value.carbon:[[@LINE-11]]:1: in import [InImport]
// CHECK:STDERR: requirement_type_a.carbon:27:25: note: initializing function parameter [InCallToFunctionParam]
// CHECK:STDERR: fn Take[T: type](unused f: T) -> i32 { return 1; }
// CHECK:STDERR:                         ^~~~
// CHECK:STDERR:
fn TakeName() -> i32 { return Take(A); }

// CHECK:STDERR: fail_requirement_type_value.carbon:[[@LINE+11]]:55: error: cannot implicitly convert expression of type `<type of Has(i32).N>*` to `<type of HasN.N>*` [ConversionFailure]
// CHECK:STDERR: fn Mismatch(p: typeof(Has(i32).N)*) -> i32 { return P(p); }
// CHECK:STDERR:                                                       ^
// CHECK:STDERR: fail_requirement_type_value.carbon:[[@LINE+8]]:55: note: type `<type of Has(i32).N>*` does not implement interface `Core.ImplicitAs(<type of HasN.N>*)` [MissingImplInMemberAccessInContext]
// CHECK:STDERR: fn Mismatch(p: typeof(Has(i32).N)*) -> i32 { return P(p); }
// CHECK:STDERR:                                                       ^
// CHECK:STDERR: fail_requirement_type_value.carbon:[[@LINE-24]]:1: in import [InImport]
// CHECK:STDERR: requirement_type_a.carbon:21:13: note: initializing function parameter [InCallToFunctionParam]
// CHECK:STDERR: fn P(unused p: typeof(HasN.N)*) -> i32 { return 3; }
// CHECK:STDERR:             ^~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn Mismatch(p: typeof(Has(i32).N)*) -> i32 { return P(p); }

// CHECK:STDOUT: --- requirement_type_b.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %C: type = class_type @C [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %C.N.type: type = fn_type @C.N [concrete]
// CHECK:STDOUT:   %C.N: %C.N.type = struct_value () [concrete]
// CHECK:STDOUT:   %HasN.type: type = facet_type <@HasN> [concrete]
// CHECK:STDOUT:   %HasN.WithSelf.N.requirement.type: type = structural_requirement_type @HasN.WithSelf.N [concrete]
// CHECK:STDOUT:   %HasN.WithSelf.N.requirement: %HasN.WithSelf.N.requirement.type = struct_value () [concrete]
// CHECK:STDOUT:   %ptr.8a7: type = ptr_type %HasN.WithSelf.N.requirement.type [concrete]
// CHECK:STDOUT:   %pattern_type.df3: type = pattern_type %ptr.8a7 [concrete]
// CHECK:STDOUT:   %p.param_patt: %pattern_type.df3 = value_param_pattern [concrete]
// CHECK:STDOUT:   %p.patt: %pattern_type.df3 = wrapper_binding_pattern p, %p.param_patt [concrete]
// CHECK:STDOUT:   %Use.type: type = fn_type @Use [concrete]
// CHECK:STDOUT:   %Use: %Use.type = struct_value () [concrete]
// CHECK:STDOUT:   %P.type: type = fn_type @P [concrete]
// CHECK:STDOUT:   %P: %P.type = struct_value () [concrete]
// CHECK:STDOUT:   %Has.type.9ba: type = generic_named_constaint_type @Has [concrete]
// CHECK:STDOUT:   %empty_struct: %Has.type.9ba = struct_value () [concrete]
// CHECK:STDOUT:   %Has.type.d682d6.2: type = facet_type <@Has, @Has(%i32)> [concrete]
// CHECK:STDOUT:   %Has.WithSelf.N.requirement.type: type = structural_requirement_type @Has.WithSelf.N, @Has(%i32) [concrete]
// CHECK:STDOUT:   %Has.WithSelf.N.requirement: %Has.WithSelf.N.requirement.type = struct_value () [concrete]
// CHECK:STDOUT:   %Z.type: type = facet_type <@Z> [concrete]
// CHECK:STDOUT:   %Self.013: %Z.type = symbolic_binding Self, 0 [symbolic]
// CHECK:STDOUT:   %Z.WithSelf.F.type.d69: type = fn_type @Z.WithSelf.F, @Z.WithSelf(%Self.013) [symbolic]
// CHECK:STDOUT:   %Z.WithSelf.F.862: %Z.WithSelf.F.type.d69 = struct_value () [symbolic]
// CHECK:STDOUT:   %Z.assoc_type: type = assoc_entity_type @Z [concrete]
// CHECK:STDOUT:   %assoc0.349: %Z.assoc_type = assoc_entity element0, imports.%Main.import_ref.6d8 [concrete]
// CHECK:STDOUT:   %Z.impl_witness: <witness> = impl_witness imports.%Z.impl_witness_table [concrete]
// CHECK:STDOUT:   %Z.facet: %Z.type = facet_value %Has.WithSelf.N.requirement.type, (%Z.impl_witness) [concrete]
// CHECK:STDOUT:   %Z.WithSelf.F.type.d43: type = fn_type @Z.WithSelf.F, @Z.WithSelf(%Z.facet) [concrete]
// CHECK:STDOUT:   %.7c4: type = fn_type_with_self_type %Z.WithSelf.F.type.d43, %Z.facet [concrete]
// CHECK:STDOUT:   %Has.WithSelf.N.requirement.type.as.Z.impl.F.type: type = fn_type @Has.WithSelf.N.requirement.type.as.Z.impl.F [concrete]
// CHECK:STDOUT:   %Has.WithSelf.N.requirement.type.as.Z.impl.F: %Has.WithSelf.N.requirement.type.as.Z.impl.F.type = struct_value () [concrete]
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
// CHECK:STDOUT:   %HasN.facet: %HasN.type = facet_value %C, () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Main.Has: %Has.type.9ba = import_ref Main//requirement_type_a, Has, loaded [concrete = constants.%empty_struct]
// CHECK:STDOUT:   %Main.Z: type = import_ref Main//requirement_type_a, Z, loaded [concrete = constants.%Z.type]
// CHECK:STDOUT:   %Main.A: %HasN.WithSelf.N.requirement.type = import_ref Main//requirement_type_a, A, loaded [concrete = constants.%HasN.WithSelf.N.requirement]
// CHECK:STDOUT:   %Main.P: %P.type = import_ref Main//requirement_type_a, P, loaded [concrete = constants.%P]
// CHECK:STDOUT:   %Main.import_ref.f33: %Z.assoc_type = import_ref Main//requirement_type_a, loc16_16, loaded [concrete = constants.%assoc0.349]
// CHECK:STDOUT:   %Main.import_ref.6d8: @Z.WithSelf.%Z.WithSelf.F.type (%Z.WithSelf.F.type.d69) = import_ref Main//requirement_type_a, loc16_16, loaded [symbolic = @Z.WithSelf.%Z.WithSelf.F (constants.%Z.WithSelf.F.862)]
// CHECK:STDOUT:   %Main.import_ref.0d0: %Has.WithSelf.N.requirement.type.as.Z.impl.F.type = import_ref Main//requirement_type_a, loc24_17, loaded [concrete = constants.%Has.WithSelf.N.requirement.type.as.Z.impl.F]
// CHECK:STDOUT:   %Z.impl_witness_table = impl_witness_table (%Main.import_ref.0d0), @Has.WithSelf.N.requirement.type.as.Z.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.b4fd3a.1 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.684: @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op.type (%Int.as.AddWith.impl.Op.type.610) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op (constants.%Int.as.AddWith.impl.Op.732)]
// CHECK:STDOUT:   %AddWith.impl_witness_table.6b4 = impl_witness_table (%Core.import_ref.b4fd3a.1, %Core.import_ref.684), @Int.as.AddWith.impl.3af [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Use.decl: %Use.type = fn_decl @Use [concrete = constants.%Use] {
// CHECK:STDOUT:     %p.param_patt: %pattern_type.df3 = value_param_pattern [concrete = constants.%p.param_patt]
// CHECK:STDOUT:     %p.patt: %pattern_type.df3 = wrapper_binding_pattern p, %p.param_patt [concrete = constants.%p.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc12 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc12: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc12_26: Core.Form = init_form %i32.loc12 [concrete = constants.%.795f]
// CHECK:STDOUT:     %p.param: %ptr.8a7 = value_param call_param0
// CHECK:STDOUT:     %.loc12_20: type = splice_block %ptr [concrete = constants.%ptr.8a7] {
// CHECK:STDOUT:       %.loc12_19: type = type_of %A.ref.loc12 in [concrete = constants.%HasN.WithSelf.N.requirement.type] {
// CHECK:STDOUT:         %A.ref.loc12: %HasN.WithSelf.N.requirement.type = name_ref A, imports.%Main.A [concrete = constants.%HasN.WithSelf.N.requirement]
// CHECK:STDOUT:       }
// CHECK:STDOUT:       %ptr: type = ptr_type %.loc12_19 [concrete = constants.%ptr.8a7]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %p: %ptr.8a7 = wrapper_binding p, %p.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Use(%p.param: %ptr.8a7) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %P.ref: %P.type = name_ref P, imports.%Main.P [concrete = constants.%P]
// CHECK:STDOUT:   %p.ref: %ptr.8a7 = name_ref p, %p
// CHECK:STDOUT:   %P.call: init %i32 = call %P.ref(%p.ref)
// CHECK:STDOUT:   %.loc13_34: type = type_of %N.ref.loc13_32 in [concrete = constants.%Has.WithSelf.N.requirement.type] {
// CHECK:STDOUT:     %Has.ref: %Has.type.9ba = name_ref Has, imports.%Main.Has [concrete = constants.%empty_struct]
// CHECK:STDOUT:     %i32.loc13: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %Has.type: type = facet_type <@Has, @Has(constants.%i32)> [concrete = constants.%Has.type.d682d6.2]
// CHECK:STDOUT:     %N.ref.loc13_32: %Has.WithSelf.N.requirement.type = name_ref N, constants.%Has.WithSelf.N.requirement [concrete = constants.%Has.WithSelf.N.requirement]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Z.ref: type = name_ref Z, imports.%Main.Z [concrete = constants.%Z.type]
// CHECK:STDOUT:   %F.ref: %Z.assoc_type = name_ref F, imports.%Main.import_ref.f33 [concrete = constants.%assoc0.349]
// CHECK:STDOUT:   %Z.facet: %Z.type = facet_value %.loc13_34, (constants.%Z.impl_witness) [concrete = constants.%Z.facet]
// CHECK:STDOUT:   %.loc13_35: %Z.type = converted %.loc13_34, %Z.facet [concrete = constants.%Z.facet]
// CHECK:STDOUT:   %impl.elem0: %.7c4 = impl_witness_access constants.%Z.impl_witness, element0 [concrete = constants.%Has.WithSelf.N.requirement.type.as.Z.impl.F]
// CHECK:STDOUT:   %Has.WithSelf.N.requirement.type.as.Z.impl.F.call: init %i32 = call %impl.elem0()
// CHECK:STDOUT:   %impl.elem1.loc13_15: %.d47 = impl_witness_access constants.%AddWith.impl_witness.833, element1 [concrete = constants.%Int.as.AddWith.impl.Op.365]
// CHECK:STDOUT:   %bound_method.loc13_15.1: <bound method> = bound_method %P.call, %impl.elem1.loc13_15
// CHECK:STDOUT:   %specific_fn.loc13_15: <specific function> = specific_function %impl.elem1.loc13_15, @Int.as.AddWith.impl.Op.1(constants.%int_32) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.f25]
// CHECK:STDOUT:   %bound_method.loc13_15.2: <bound method> = bound_method %P.call, %specific_fn.loc13_15
// CHECK:STDOUT:   %.loc13_13.1: %i32 = value_of_initializer %P.call
// CHECK:STDOUT:   %.loc13_13.2: %i32 = converted %P.call, %.loc13_13.1
// CHECK:STDOUT:   %.loc13_42.1: %i32 = value_of_initializer %Has.WithSelf.N.requirement.type.as.Z.impl.F.call
// CHECK:STDOUT:   %.loc13_42.2: %i32 = converted %Has.WithSelf.N.requirement.type.as.Z.impl.F.call, %.loc13_42.1
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call.loc13_15: init %i32 = call %bound_method.loc13_15.2(%.loc13_13.2, %.loc13_42.2)
// CHECK:STDOUT:   %C.ref: type = name_ref C, file.%C.decl [concrete = constants.%C]
// CHECK:STDOUT:   %A.ref.loc13: %HasN.WithSelf.N.requirement.type = name_ref A, imports.%Main.A [concrete = constants.%HasN.WithSelf.N.requirement]
// CHECK:STDOUT:   %HasN.facet: %HasN.type = facet_value %C.ref, () [concrete = constants.%HasN.facet]
// CHECK:STDOUT:   %.loc13_47: %HasN.type = converted %C.ref, %HasN.facet [concrete = constants.%HasN.facet]
// CHECK:STDOUT:   %N.ref.loc13_47: %C.N.type = name_ref N, @C.%C.N.decl [concrete = constants.%C.N]
// CHECK:STDOUT:   %C.N.call: init %i32 = call %N.ref.loc13_47()
// CHECK:STDOUT:   %impl.elem1.loc13_44: %.d47 = impl_witness_access constants.%AddWith.impl_witness.833, element1 [concrete = constants.%Int.as.AddWith.impl.Op.365]
// CHECK:STDOUT:   %bound_method.loc13_44.1: <bound method> = bound_method %Int.as.AddWith.impl.Op.call.loc13_15, %impl.elem1.loc13_44
// CHECK:STDOUT:   %specific_fn.loc13_44: <specific function> = specific_function %impl.elem1.loc13_44, @Int.as.AddWith.impl.Op.1(constants.%int_32) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.f25]
// CHECK:STDOUT:   %bound_method.loc13_44.2: <bound method> = bound_method %Int.as.AddWith.impl.Op.call.loc13_15, %specific_fn.loc13_44
// CHECK:STDOUT:   %.loc13_15.1: %i32 = value_of_initializer %Int.as.AddWith.impl.Op.call.loc13_15
// CHECK:STDOUT:   %.loc13_15.2: %i32 = converted %Int.as.AddWith.impl.Op.call.loc13_15, %.loc13_15.1
// CHECK:STDOUT:   %.loc13_52.1: %i32 = value_of_initializer %C.N.call
// CHECK:STDOUT:   %.loc13_52.2: %i32 = converted %C.N.call, %.loc13_52.1
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call.loc13_44: init %i32 = call %bound_method.loc13_44.2(%.loc13_15.2, %.loc13_52.2)
// CHECK:STDOUT:   return %Int.as.AddWith.impl.Op.call.loc13_44
// CHECK:STDOUT: }
// CHECK:STDOUT:
