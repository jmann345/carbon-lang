// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --dump-sem-ir-ranges=only
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/function/overload/generic.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/function/overload/generic.carbon

// Generic members of `overload fn` sets (fork/overload/plan.md OV-2, §1.B.4).
// A generic member is probed by non-diagnosing deduction inside the same
// discard scope as the conversion probe (D-OV-4 step 2(d)); the committed call
// re-deduces diagnosing and names a specific of the member. Declaration-order
// first-match over mixed generic and non-generic members is pure order: a
// generic member declared first accepts every call it can deduce.

// --- generic_second.carbon

library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
overload fn Kind(unused x: i32) -> i32 { return 1; }
overload fn Kind[T: type](unused x: T) -> i32 { return 2; }

// `Kind(5)` selects member 0 (the literal converts to `i32`); `Kind(true)`
// is rejected by member 0 and deduces `T = bool` for member 1.
fn Use() -> i32 { return Kind(5) + Kind(true); }
//@dump-sem-ir-end

// --- generic_first.carbon

library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
overload fn Kind[T: type](unused x: T) -> i32 { return 2; }
overload fn Kind(unused x: i32) -> i32 { return 1; }

// Pure declaration order: the generic member swallows the call with
// `T = Core.IntLiteral`; the exact non-generic member is never reached.
fn Use() -> i32 { return Kind(5); }
//@dump-sem-ir-end

// --- fail_deduce_all.carbon

library "[[@TEST_NAME]]";

overload fn Only[T: Core.ImplicitAs(i32)](unused x: T) -> i32 { return 1; }
overload fn Only[T: Core.ImplicitAs(i64)](unused x: T) -> i32 { return 2; }

// `bool` satisfies neither constraint, so both members are rejected by
// deduction (reason 2) and nothing is diagnosed by the probes themselves.
// CHECK:STDERR: fail_deduce_all.carbon:[[@LINE+10]]:26: error: no member of overload set `Only` accepts this call [OverloadNoMatch]
// CHECK:STDERR: fn Use() -> i32 { return Only(true); }
// CHECK:STDERR:                          ^~~~~~~~~~
// CHECK:STDERR: fail_deduce_all.carbon:[[@LINE-8]]:1: note: candidate has generic parameters that could not be deduced [OverloadCandidateRejected]
// CHECK:STDERR: overload fn Only[T: Core.ImplicitAs(i32)](unused x: T) -> i32 { return 1; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_deduce_all.carbon:[[@LINE-10]]:1: note: candidate has generic parameters that could not be deduced [OverloadCandidateRejected]
// CHECK:STDERR: overload fn Only[T: Core.ImplicitAs(i64)](unused x: T) -> i32 { return 2; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn Use() -> i32 { return Only(true); }

// CHECK:STDOUT: --- generic_second.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %x.param_patt.cee: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %x.patt.e3b: %pattern_type.6b6 = wrapper_binding_pattern x, %x.param_patt.cee [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %Kind.type.49b37c.1: type = fn_type @Kind.loc5 [concrete]
// CHECK:STDOUT:   %Kind.b34fea.1: %Kind.type.49b37c.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Kind.overload_set.type: type = overload_set_type @Kind.overload_set [concrete]
// CHECK:STDOUT:   %Kind.overload_set.value: %Kind.overload_set.type = overload_set_value @Kind.overload_set [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %pattern_type.9a5: type = pattern_type type [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %To: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %T.67d: type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %T.patt.3a0: %pattern_type.9a5 = symbolic_binding_pattern T, 0 [symbolic]
// CHECK:STDOUT:   %pattern_type.51d1c4.2: type = pattern_type %T.67d [symbolic]
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
// CHECK:STDOUT:   %.Self.frozen.e58: type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %x.param_patt.91d: %pattern_type.51d1c4.2 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %x.patt.26065e.1: %pattern_type.51d1c4.2 = wrapper_binding_pattern x, %x.param_patt.91d [symbolic]
// CHECK:STDOUT:   %x.patt.26065e.2: %pattern_type.51d1c4.2 = wrapper_binding_pattern x, %x.param_patt.91d [symbolic]
// CHECK:STDOUT:   %Kind.type.49b37c.2: type = fn_type @Kind.loc6 [concrete]
// CHECK:STDOUT:   %Kind.b34fea.2: %Kind.type.49b37c.2 = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete.944: <witness> = require_complete_type %T.67d [symbolic]
// CHECK:STDOUT:   %int_2.ecc: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.9f3: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.3cb: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_2.295: %i32 = int_value 2 [concrete]
// CHECK:STDOUT:   %Use.type: type = fn_type @Use [concrete]
// CHECK:STDOUT:   %Use: %Use.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_5.64b: Core.IntLiteral = int_value 5 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.f6c: <bound method> = bound_method %int_5.64b, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.c9d: <bound method> = bound_method %int_5.64b, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_5.eef: %i32 = int_value 5 [concrete]
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete]
// CHECK:STDOUT:   %pattern_type.831: type = pattern_type bool [concrete]
// CHECK:STDOUT:   %x.param_patt.37d: %pattern_type.831 = value_param_pattern [concrete]
// CHECK:STDOUT:   %x.patt.e47: %pattern_type.831 = wrapper_binding_pattern x, %x.param_patt.37d [concrete]
// CHECK:STDOUT:   %Kind.specific_fn: <specific function> = specific_function %Kind.b34fea.2, @Kind.loc6(bool) [concrete]
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
// CHECK:STDOUT:   %complete_type.127: <witness> = complete_type_witness bool [concrete]
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
// CHECK:STDOUT:   %Kind.decl.loc5: %Kind.type.49b37c.1 = fn_decl @Kind.loc5 [concrete = constants.%Kind.b34fea.1] {
// CHECK:STDOUT:     %x.param_patt: %pattern_type.6b6 = value_param_pattern [concrete = constants.%x.param_patt.cee]
// CHECK:STDOUT:     %x.patt: %pattern_type.6b6 = wrapper_binding_pattern x, %x.param_patt [concrete = constants.%x.patt.e3b]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc5_36 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc5_36: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc5_36: Core.Form = init_form %i32.loc5_36 [concrete = constants.%.795f]
// CHECK:STDOUT:     %x.param: %i32 = value_param call_param0
// CHECK:STDOUT:     %i32.loc5_28: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %x: %i32 = wrapper_binding x, %x.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Kind.overload_set.value: %Kind.overload_set.type = overload_set_value @Kind.overload_set [concrete = constants.%Kind.overload_set.value]
// CHECK:STDOUT:   %Kind.decl.loc6: %Kind.type.49b37c.2 = fn_decl @Kind.loc6 [concrete = constants.%Kind.b34fea.2] {
// CHECK:STDOUT:     %T.patt.loc6_19.1: %pattern_type.9a5 = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc6_19.2 (constants.%T.patt.3a0)]
// CHECK:STDOUT:     %x.param_patt.loc6_35.1: @Kind.loc6.%pattern_type (%pattern_type.51d1c4.2) = value_param_pattern [symbolic = %x.param_patt.loc6_35.2 (constants.%x.param_patt.91d)]
// CHECK:STDOUT:     %x.patt.loc6_35.1: @Kind.loc6.%pattern_type (%pattern_type.51d1c4.2) = wrapper_binding_pattern x, %x.param_patt.loc6_35.1 [symbolic = %x.patt.loc6_35.2 (constants.%x.patt.26065e.1)]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc6_43: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %.loc6_21.1: type = splice_block %.loc6_21.2 [concrete = type] {
// CHECK:STDOUT:       %.Self.frozen: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen.e58]
// CHECK:STDOUT:       %.loc6_21.2: type = type_literal type [concrete = type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc6_19.2: type = symbolic_binding T, 0 [symbolic = %T.loc6_19.1 (constants.%T.67d)]
// CHECK:STDOUT:     %x.param: @Kind.loc6.%T.loc6_19.1 (%T.67d) = value_param call_param0
// CHECK:STDOUT:     %T.ref: type = name_ref T, %T.loc6_19.2 [symbolic = %T.loc6_19.1 (constants.%T.67d)]
// CHECK:STDOUT:     %x: @Kind.loc6.%T.loc6_19.1 (%T.67d) = wrapper_binding x, %x.param
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
// CHECK:STDOUT: fn @Kind.loc5(%x.param: %i32) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc5_50.1: <bound method> = bound_method %int_1, %impl.elem0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn: <specific function> = specific_function %impl.elem0, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc5_50.2: <bound method> = bound_method %int_1, %specific_fn [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %i32 = call %bound_method.loc5_50.2(%int_1) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc5_50: init %i32 = converted %int_1, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   return %.loc5_50
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @Kind.loc6(%T.loc6_19.2: type) {
// CHECK:STDOUT:   %T.patt.loc6_19.2: %pattern_type.9a5 = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc6_19.2 (constants.%T.patt.3a0)]
// CHECK:STDOUT:   %T.loc6_19.1: type = symbolic_binding T, 0 [symbolic = %T.loc6_19.1 (constants.%T.67d)]
// CHECK:STDOUT:   %pattern_type: type = pattern_type %T.loc6_19.1 [symbolic = %pattern_type (constants.%pattern_type.51d1c4.2)]
// CHECK:STDOUT:   %x.param_patt.loc6_35.2: @Kind.loc6.%pattern_type (%pattern_type.51d1c4.2) = value_param_pattern [symbolic = %x.param_patt.loc6_35.2 (constants.%x.param_patt.91d)]
// CHECK:STDOUT:   %x.patt.loc6_35.2: @Kind.loc6.%pattern_type (%pattern_type.51d1c4.2) = wrapper_binding_pattern x, %x.param_patt.loc6_35.2 [symbolic = %x.patt.loc6_35.2 (constants.%x.patt.26065e.1)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete: <witness> = require_complete_type %T.loc6_19.1 [symbolic = %require_complete (constants.%require_complete.944)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%x.param: @Kind.loc6.%T.loc6_19.1 (%T.67d)) -> out %return.param: %i32 {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %int_2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:     %impl.elem0: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:     %bound_method.loc6_57.1: <bound method> = bound_method %int_2, %impl.elem0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.9f3]
// CHECK:STDOUT:     %specific_fn: <specific function> = specific_function %impl.elem0, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:     %bound_method.loc6_57.2: <bound method> = bound_method %int_2, %specific_fn [concrete = constants.%bound_method.3cb]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %i32 = call %bound_method.loc6_57.2(%int_2) [concrete = constants.%int_2.295]
// CHECK:STDOUT:     %.loc6_57: init %i32 = converted %int_2, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_2.295]
// CHECK:STDOUT:     return %.loc6_57
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Use() -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Kind.ref.loc10_26: %Kind.overload_set.type = name_ref Kind, file.%Kind.overload_set.value [concrete = constants.%Kind.overload_set.value]
// CHECK:STDOUT:   %int_5: Core.IntLiteral = int_value 5 [concrete = constants.%int_5.64b]
// CHECK:STDOUT:   %Kind.ref.loc10_32: %Kind.type.49b37c.1 = name_ref Kind, file.%Kind.decl.loc5 [concrete = constants.%Kind.b34fea.1]
// CHECK:STDOUT:   %impl.elem0: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc10_31.1: <bound method> = bound_method %int_5, %impl.elem0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.f6c]
// CHECK:STDOUT:   %specific_fn.loc10_31: <specific function> = specific_function %impl.elem0, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc10_31.2: <bound method> = bound_method %int_5, %specific_fn.loc10_31 [concrete = constants.%bound_method.c9d]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %i32 = call %bound_method.loc10_31.2(%int_5) [concrete = constants.%int_5.eef]
// CHECK:STDOUT:   %.loc10_31.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_5.eef]
// CHECK:STDOUT:   %.loc10_31.2: %i32 = converted %int_5, %.loc10_31.1 [concrete = constants.%int_5.eef]
// CHECK:STDOUT:   %Kind.call.loc10_32: init %i32 = call %Kind.ref.loc10_32(%.loc10_31.2)
// CHECK:STDOUT:   %Kind.ref.loc10_36: %Kind.overload_set.type = name_ref Kind, file.%Kind.overload_set.value [concrete = constants.%Kind.overload_set.value]
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:   %Kind.ref.loc10_45: %Kind.type.49b37c.2 = name_ref Kind, file.%Kind.decl.loc6 [concrete = constants.%Kind.b34fea.2]
// CHECK:STDOUT:   %Kind.specific_fn: <specific function> = specific_function %Kind.ref.loc10_45, @Kind.loc6(bool) [concrete = constants.%Kind.specific_fn]
// CHECK:STDOUT:   %Kind.call.loc10_45: init %i32 = call %Kind.specific_fn(%true)
// CHECK:STDOUT:   %impl.elem1: %.d47 = impl_witness_access constants.%AddWith.impl_witness.833, element1 [concrete = constants.%Int.as.AddWith.impl.Op.365]
// CHECK:STDOUT:   %bound_method.loc10_34.1: <bound method> = bound_method %Kind.call.loc10_32, %impl.elem1
// CHECK:STDOUT:   %specific_fn.loc10_34: <specific function> = specific_function %impl.elem1, @Int.as.AddWith.impl.Op.1(constants.%int_32) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.f25]
// CHECK:STDOUT:   %bound_method.loc10_34.2: <bound method> = bound_method %Kind.call.loc10_32, %specific_fn.loc10_34
// CHECK:STDOUT:   %.loc10_32.1: %i32 = value_of_initializer %Kind.call.loc10_32
// CHECK:STDOUT:   %.loc10_32.2: %i32 = converted %Kind.call.loc10_32, %.loc10_32.1
// CHECK:STDOUT:   %.loc10_45.1: %i32 = value_of_initializer %Kind.call.loc10_45
// CHECK:STDOUT:   %.loc10_45.2: %i32 = converted %Kind.call.loc10_45, %.loc10_45.1
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call: init %i32 = call %bound_method.loc10_34.2(%.loc10_32.2, %.loc10_45.2)
// CHECK:STDOUT:   return %Int.as.AddWith.impl.Op.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Kind.loc6(constants.%T.67d) {
// CHECK:STDOUT:   %T.patt.loc6_19.2 => constants.%T.patt.3a0
// CHECK:STDOUT:   %T.loc6_19.1 => constants.%T.67d
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.51d1c4.2
// CHECK:STDOUT:   %x.param_patt.loc6_35.2 => constants.%x.param_patt.91d
// CHECK:STDOUT:   %x.patt.loc6_35.2 => constants.%x.patt.26065e.2
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Kind.loc6(bool) {
// CHECK:STDOUT:   %T.patt.loc6_19.2 => constants.%T.patt.3a0
// CHECK:STDOUT:   %T.loc6_19.1 => bool
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.831
// CHECK:STDOUT:   %x.param_patt.loc6_35.2 => constants.%x.param_patt.37d
// CHECK:STDOUT:   %x.patt.loc6_35.2 => constants.%x.patt.e47
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete => constants.%complete_type.127
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- generic_first.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %.Self.frozen: type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %pattern_type.9a5: type = pattern_type type [concrete]
// CHECK:STDOUT:   %T.patt.3a0: %pattern_type.9a5 = symbolic_binding_pattern T, 0 [symbolic]
// CHECK:STDOUT:   %T.67d: type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %pattern_type.51d1c4.1: type = pattern_type %T.67d [symbolic]
// CHECK:STDOUT:   %x.param_patt.91d: %pattern_type.51d1c4.1 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %x.patt.260: %pattern_type.51d1c4.1 = wrapper_binding_pattern x, %x.param_patt.91d [symbolic]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %pattern_type.dc0: type = pattern_type Core.IntLiteral [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %Kind.type.49b37c.1: type = fn_type @Kind.loc5 [concrete]
// CHECK:STDOUT:   %Kind.b34fea.1: %Kind.type.49b37c.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Kind.overload_set.type: type = overload_set_type @Kind.overload_set [concrete]
// CHECK:STDOUT:   %Kind.overload_set.value: %Kind.overload_set.type = overload_set_value @Kind.overload_set [concrete]
// CHECK:STDOUT:   %require_complete.944: <witness> = require_complete_type %T.67d [symbolic]
// CHECK:STDOUT:   %int_2.ecc: Core.IntLiteral = int_value 2 [concrete]
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
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.9f3: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.3cb: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_2.295: %i32 = int_value 2 [concrete]
// CHECK:STDOUT:   %x.param_patt.cee: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %x.patt.e3b: %pattern_type.6b6 = wrapper_binding_pattern x, %x.param_patt.cee [concrete]
// CHECK:STDOUT:   %Kind.type.49b37c.2: type = fn_type @Kind.loc6 [concrete]
// CHECK:STDOUT:   %Kind.b34fea.2: %Kind.type.49b37c.2 = struct_value () [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.953: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT:   %Use.type: type = fn_type @Use [concrete]
// CHECK:STDOUT:   %Use: %Use.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_5: Core.IntLiteral = int_value 5 [concrete]
// CHECK:STDOUT:   %x.param_patt.a39: %pattern_type.dc0 = value_param_pattern [concrete]
// CHECK:STDOUT:   %x.patt.3f3: %pattern_type.dc0 = wrapper_binding_pattern x, %x.param_patt.a39 [concrete]
// CHECK:STDOUT:   %Kind.specific_fn: <specific function> = specific_function %Kind.b34fea.1, @Kind.loc5(Core.IntLiteral) [concrete]
// CHECK:STDOUT:   %complete_type.972: <witness> = complete_type_witness Core.IntLiteral [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Kind.decl.loc5: %Kind.type.49b37c.1 = fn_decl @Kind.loc5 [concrete = constants.%Kind.b34fea.1] {
// CHECK:STDOUT:     %T.patt.loc5_19.1: %pattern_type.9a5 = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc5_19.2 (constants.%T.patt.3a0)]
// CHECK:STDOUT:     %x.param_patt.loc5_35.1: @Kind.loc5.%pattern_type (%pattern_type.51d1c4.1) = value_param_pattern [symbolic = %x.param_patt.loc5_35.2 (constants.%x.param_patt.91d)]
// CHECK:STDOUT:     %x.patt.loc5_35.1: @Kind.loc5.%pattern_type (%pattern_type.51d1c4.1) = wrapper_binding_pattern x, %x.param_patt.loc5_35.1 [symbolic = %x.patt.loc5_35.2 (constants.%x.patt.260)]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc5_43: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %.loc5_21.1: type = splice_block %.loc5_21.2 [concrete = type] {
// CHECK:STDOUT:       %.Self.frozen: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %.loc5_21.2: type = type_literal type [concrete = type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc5_19.2: type = symbolic_binding T, 0 [symbolic = %T.loc5_19.1 (constants.%T.67d)]
// CHECK:STDOUT:     %x.param: @Kind.loc5.%T.loc5_19.1 (%T.67d) = value_param call_param0
// CHECK:STDOUT:     %T.ref: type = name_ref T, %T.loc5_19.2 [symbolic = %T.loc5_19.1 (constants.%T.67d)]
// CHECK:STDOUT:     %x: @Kind.loc5.%T.loc5_19.1 (%T.67d) = wrapper_binding x, %x.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Kind.overload_set.value: %Kind.overload_set.type = overload_set_value @Kind.overload_set [concrete = constants.%Kind.overload_set.value]
// CHECK:STDOUT:   %Kind.decl.loc6: %Kind.type.49b37c.2 = fn_decl @Kind.loc6 [concrete = constants.%Kind.b34fea.2] {
// CHECK:STDOUT:     %x.param_patt: %pattern_type.6b6 = value_param_pattern [concrete = constants.%x.param_patt.cee]
// CHECK:STDOUT:     %x.patt: %pattern_type.6b6 = wrapper_binding_pattern x, %x.param_patt [concrete = constants.%x.patt.e3b]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc6_36 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc6_36: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc6_36: Core.Form = init_form %i32.loc6_36 [concrete = constants.%.795f]
// CHECK:STDOUT:     %x.param: %i32 = value_param call_param0
// CHECK:STDOUT:     %i32.loc6_28: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %x: %i32 = wrapper_binding x, %x.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Use.decl: %Use.type = fn_decl @Use [concrete = constants.%Use] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc10: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param0
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @Kind.loc5(%T.loc5_19.2: type) {
// CHECK:STDOUT:   %T.patt.loc5_19.2: %pattern_type.9a5 = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc5_19.2 (constants.%T.patt.3a0)]
// CHECK:STDOUT:   %T.loc5_19.1: type = symbolic_binding T, 0 [symbolic = %T.loc5_19.1 (constants.%T.67d)]
// CHECK:STDOUT:   %pattern_type: type = pattern_type %T.loc5_19.1 [symbolic = %pattern_type (constants.%pattern_type.51d1c4.1)]
// CHECK:STDOUT:   %x.param_patt.loc5_35.2: @Kind.loc5.%pattern_type (%pattern_type.51d1c4.1) = value_param_pattern [symbolic = %x.param_patt.loc5_35.2 (constants.%x.param_patt.91d)]
// CHECK:STDOUT:   %x.patt.loc5_35.2: @Kind.loc5.%pattern_type (%pattern_type.51d1c4.1) = wrapper_binding_pattern x, %x.param_patt.loc5_35.2 [symbolic = %x.patt.loc5_35.2 (constants.%x.patt.260)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete: <witness> = require_complete_type %T.loc5_19.1 [symbolic = %require_complete (constants.%require_complete.944)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%x.param: @Kind.loc5.%T.loc5_19.1 (%T.67d)) -> out %return.param: %i32 {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %int_2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:     %impl.elem0: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:     %bound_method.loc5_57.1: <bound method> = bound_method %int_2, %impl.elem0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.9f3]
// CHECK:STDOUT:     %specific_fn: <specific function> = specific_function %impl.elem0, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:     %bound_method.loc5_57.2: <bound method> = bound_method %int_2, %specific_fn [concrete = constants.%bound_method.3cb]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %i32 = call %bound_method.loc5_57.2(%int_2) [concrete = constants.%int_2.295]
// CHECK:STDOUT:     %.loc5_57: init %i32 = converted %int_2, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_2.295]
// CHECK:STDOUT:     return %.loc5_57
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Kind.loc6(%x.param: %i32) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc6_50.1: <bound method> = bound_method %int_1, %impl.elem0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn: <specific function> = specific_function %impl.elem0, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc6_50.2: <bound method> = bound_method %int_1, %specific_fn [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %i32 = call %bound_method.loc6_50.2(%int_1) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc6_50: init %i32 = converted %int_1, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   return %.loc6_50
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Use() -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Kind.ref.loc10_26: %Kind.overload_set.type = name_ref Kind, file.%Kind.overload_set.value [concrete = constants.%Kind.overload_set.value]
// CHECK:STDOUT:   %int_5: Core.IntLiteral = int_value 5 [concrete = constants.%int_5]
// CHECK:STDOUT:   %Kind.ref.loc10_32: %Kind.type.49b37c.1 = name_ref Kind, file.%Kind.decl.loc5 [concrete = constants.%Kind.b34fea.1]
// CHECK:STDOUT:   %Kind.specific_fn: <specific function> = specific_function %Kind.ref.loc10_32, @Kind.loc5(Core.IntLiteral) [concrete = constants.%Kind.specific_fn]
// CHECK:STDOUT:   %Kind.call: init %i32 = call %Kind.specific_fn(%int_5)
// CHECK:STDOUT:   return %Kind.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Kind.loc5(constants.%T.67d) {
// CHECK:STDOUT:   %T.patt.loc5_19.2 => constants.%T.patt.3a0
// CHECK:STDOUT:   %T.loc5_19.1 => constants.%T.67d
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.51d1c4.1
// CHECK:STDOUT:   %x.param_patt.loc5_35.2 => constants.%x.param_patt.91d
// CHECK:STDOUT:   %x.patt.loc5_35.2 => constants.%x.patt.260
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Kind.loc5(Core.IntLiteral) {
// CHECK:STDOUT:   %T.patt.loc5_19.2 => constants.%T.patt.3a0
// CHECK:STDOUT:   %T.loc5_19.1 => Core.IntLiteral
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.dc0
// CHECK:STDOUT:   %x.param_patt.loc5_35.2 => constants.%x.param_patt.a39
// CHECK:STDOUT:   %x.patt.loc5_35.2 => constants.%x.patt.3f3
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete => constants.%complete_type.972
// CHECK:STDOUT: }
// CHECK:STDOUT:
