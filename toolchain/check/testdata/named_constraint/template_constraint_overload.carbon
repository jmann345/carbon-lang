// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/named_constraint/template_constraint_overload.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/named_constraint/template_constraint_overload.carbon

// A `template T: HasGet` member of an `overload fn` set is probed without
// diagnostics; an unsatisfied structural member is skipped silently and
// first-match resolution is unchanged (fork decision F-010 / SC-1,
// fork/structural/plan.md D-SC-12; fork/overload/plan.md D-OV-4).

// --- overload.carbon
library "[[@TEST_NAME]]";

template constraint HasGet {
  fn Get(self) -> i32;
}

class C {
  fn Get(unused self) -> i32 { return 1; }
}

overload fn F[template T: HasGet](x: T) -> i32 { return x.Get(); }
overload fn F(unused x: i32) -> i32 { return 2; }

fn Test(c: C) -> i32 { return F(c) + F(3); }

// --- overload_catch_all.carbon
library "[[@TEST_NAME]]";

// The §5.A conformance shape (review fold B2): member 1 is viable only for a
// type that satisfies `HasGet`; member 2 accepts any type.
template constraint HasGet {
  fn Get(self) -> i32;
}

class C {
  fn Get(unused self) -> i32 { return 42; }
}

class Lacking {
  fn Other(unused self) -> i32 { return 0; }
}

overload fn Pick[template T: HasGet](x: T) -> i32 { return x.Get(); }
overload fn Pick[template T: type](unused x: T) -> i32 { return 7; }

//@dump-sem-ir-begin
fn Test(c: C, l: Lacking) -> i32 { return Pick(c) + Pick(l); }
//@dump-sem-ir-end

// CHECK:STDOUT: --- overload_catch_all.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %HasGet.type: type = facet_type <@HasGet> [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %C: type = class_type @C [concrete]
// CHECK:STDOUT:   %pattern_type.98b: type = pattern_type %C [concrete]
// CHECK:STDOUT:   %Lacking: type = class_type @Lacking [concrete]
// CHECK:STDOUT:   %pattern_type.3e9: type = pattern_type %Lacking [concrete]
// CHECK:STDOUT:   %Pick.type.113fcf.1: type = fn_type @Pick.loc17 [concrete]
// CHECK:STDOUT:   %Pick.bd7a10.1: %Pick.type.113fcf.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Pick.overload_set.type: type = overload_set_type @Pick.overload_set [concrete]
// CHECK:STDOUT:   %Pick.overload_set.value: %Pick.overload_set.type = overload_set_value @Pick.overload_set [concrete]
// CHECK:STDOUT:   %Pick.type.113fcf.2: type = fn_type @Pick.loc18 [concrete]
// CHECK:STDOUT:   %Pick.bd7a10.2: %Pick.type.113fcf.2 = struct_value () [concrete]
// CHECK:STDOUT:   %c.param_patt: %pattern_type.98b = value_param_pattern [concrete]
// CHECK:STDOUT:   %c.patt: %pattern_type.98b = wrapper_binding_pattern c, %c.param_patt [concrete]
// CHECK:STDOUT:   %l.param_patt: %pattern_type.3e9 = value_param_pattern [concrete]
// CHECK:STDOUT:   %l.patt: %pattern_type.3e9 = wrapper_binding_pattern l, %l.param_patt [concrete]
// CHECK:STDOUT:   %Test.type: type = fn_type @Test [concrete]
// CHECK:STDOUT:   %Test: %Test.type = struct_value () [concrete]
// CHECK:STDOUT:   %HasGet.facet: %HasGet.type = facet_value %C, () [concrete]
// CHECK:STDOUT:   %Pick.specific_fn.cf8: <specific function> = specific_function %Pick.bd7a10.1, @Pick.loc17(%HasGet.facet) [concrete]
// CHECK:STDOUT:   %Pick.specific_fn.e53: <specific function> = specific_function %Pick.bd7a10.2, @Pick.loc18(%Lacking) [concrete]
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
// CHECK:STDOUT:   %Core.import_ref.b4fd3a.1 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.684: @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op.type (%Int.as.AddWith.impl.Op.type.610) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op (constants.%Int.as.AddWith.impl.Op.732)]
// CHECK:STDOUT:   %AddWith.impl_witness_table.6b4 = impl_witness_table (%Core.import_ref.b4fd3a.1, %Core.import_ref.684), @Int.as.AddWith.impl.3af [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Test.decl: %Test.type = fn_decl @Test [concrete = constants.%Test] {
// CHECK:STDOUT:     %c.param_patt: %pattern_type.98b = value_param_pattern [concrete = constants.%c.param_patt]
// CHECK:STDOUT:     %c.patt: %pattern_type.98b = wrapper_binding_pattern c, %c.param_patt [concrete = constants.%c.patt]
// CHECK:STDOUT:     %l.param_patt: %pattern_type.3e9 = value_param_pattern [concrete = constants.%l.param_patt]
// CHECK:STDOUT:     %l.patt: %pattern_type.3e9 = wrapper_binding_pattern l, %l.param_patt [concrete = constants.%l.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc21_30: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %c.param: %C = value_param call_param0
// CHECK:STDOUT:     %C.ref: type = name_ref C, file.%C.decl [concrete = constants.%C]
// CHECK:STDOUT:     %c: %C = wrapper_binding c, %c.param
// CHECK:STDOUT:     %l.param: %Lacking = value_param call_param1
// CHECK:STDOUT:     %Lacking.ref: type = name_ref Lacking, file.%Lacking.decl [concrete = constants.%Lacking]
// CHECK:STDOUT:     %l: %Lacking = wrapper_binding l, %l.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param2
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Test(%c.param: %C, %l.param: %Lacking) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Pick.ref.loc21_43: %Pick.overload_set.type = name_ref Pick, file.%Pick.overload_set.value [concrete = constants.%Pick.overload_set.value]
// CHECK:STDOUT:   %c.ref: %C = name_ref c, %c
// CHECK:STDOUT:   %Pick.ref.loc21_49: %Pick.type.113fcf.1 = name_ref Pick, file.%Pick.decl.loc17 [concrete = constants.%Pick.bd7a10.1]
// CHECK:STDOUT:   %HasGet.facet.loc21_49.1: %HasGet.type = facet_value constants.%C, () [concrete = constants.%HasGet.facet]
// CHECK:STDOUT:   %.loc21_49.1: %HasGet.type = converted constants.%C, %HasGet.facet.loc21_49.1 [concrete = constants.%HasGet.facet]
// CHECK:STDOUT:   %HasGet.facet.loc21_49.2: %HasGet.type = facet_value constants.%C, () [concrete = constants.%HasGet.facet]
// CHECK:STDOUT:   %.loc21_49.2: %HasGet.type = converted constants.%C, %HasGet.facet.loc21_49.2 [concrete = constants.%HasGet.facet]
// CHECK:STDOUT:   %Pick.specific_fn.loc21_49: <specific function> = specific_function %Pick.ref.loc21_49, @Pick.loc17(constants.%HasGet.facet) [concrete = constants.%Pick.specific_fn.cf8]
// CHECK:STDOUT:   %Pick.call.loc21_49: init %i32 = call %Pick.specific_fn.loc21_49(%c.ref)
// CHECK:STDOUT:   %Pick.ref.loc21_53: %Pick.overload_set.type = name_ref Pick, file.%Pick.overload_set.value [concrete = constants.%Pick.overload_set.value]
// CHECK:STDOUT:   %l.ref: %Lacking = name_ref l, %l
// CHECK:STDOUT:   %Pick.ref.loc21_59: %Pick.type.113fcf.2 = name_ref Pick, file.%Pick.decl.loc18 [concrete = constants.%Pick.bd7a10.2]
// CHECK:STDOUT:   %Pick.specific_fn.loc21_59: <specific function> = specific_function %Pick.ref.loc21_59, @Pick.loc18(constants.%Lacking) [concrete = constants.%Pick.specific_fn.e53]
// CHECK:STDOUT:   %Pick.call.loc21_59: init %i32 = call %Pick.specific_fn.loc21_59(%l.ref)
// CHECK:STDOUT:   %impl.elem1: %.d47 = impl_witness_access constants.%AddWith.impl_witness.833, element1 [concrete = constants.%Int.as.AddWith.impl.Op.365]
// CHECK:STDOUT:   %bound_method.loc21_51.1: <bound method> = bound_method %Pick.call.loc21_49, %impl.elem1
// CHECK:STDOUT:   %specific_fn: <specific function> = specific_function %impl.elem1, @Int.as.AddWith.impl.Op.1(constants.%int_32) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.f25]
// CHECK:STDOUT:   %bound_method.loc21_51.2: <bound method> = bound_method %Pick.call.loc21_49, %specific_fn
// CHECK:STDOUT:   %.loc21_49.3: %i32 = value_of_initializer %Pick.call.loc21_49
// CHECK:STDOUT:   %.loc21_49.4: %i32 = converted %Pick.call.loc21_49, %.loc21_49.3
// CHECK:STDOUT:   %.loc21_59.1: %i32 = value_of_initializer %Pick.call.loc21_59
// CHECK:STDOUT:   %.loc21_59.2: %i32 = converted %Pick.call.loc21_59, %.loc21_59.1
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call: init %i32 = call %bound_method.loc21_51.2(%.loc21_49.4, %.loc21_59.2)
// CHECK:STDOUT:   return %Int.as.AddWith.impl.Op.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
