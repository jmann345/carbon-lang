// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/choice/unit_payload.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/choice/unit_payload.carbon
// CHECK:STDERR: {{.*}}/prelude/types/cpp/slice.carbon:69:9: error: cannot access member of interface `Destroy` in type `C.(CppContiguousRange.SizeType)` that does not implement that interface [MissingImplInMemberAccess]
// CHECK:STDERR:         self.Size().(ImplicitAs(u64).Convert)().(As(i64).Convert)());
// CHECK:STDERR:         ^~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: {{.*}}/prelude/types/cpp/slice.carbon:68:9: error: cannot access member of interface `Destroy` in type `C.(CppContiguousRange.DataType)` that does not implement that interface [MissingImplInMemberAccess]
// CHECK:STDERR:         self.Data().(CppDataPointer.Raw)(),
// CHECK:STDERR:         ^~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: {{.*}}/prelude/types/cpp/slice.carbon:64:1: error: orphan `impl` found; something in the self-type or constraint must be defined in the same file [ImplIsOrphan]
// CHECK:STDERR: impl forall [C: CppContiguous where .Element impls Copy & Destroy]
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:

// The zero-sized empty tuple `()` as a choice payload element (W-070 option
// (a), fork/eh/plan.md D-EH-2): `IsInSliceChoicePayloadType` admits it, on
// the definition path (`U` below) and on the per-specific evaluation path
// (`Core.ControlFlow(i32, ())`, the unit break carrier `Optional`'s `Try`
// impl needs — decision D9 of docs/design/error_handling.md). The second
// subfile is the positive flip of fail_question_preflight.carbon's former
// unit-break-type rejection pin. A `((),)` payload tuple has size 0, so neither
// choice's layout gains any payload bytes from it.

// --- unit_payload.carbon
library "[[@TEST_NAME]]";

fn Sink(unused u: ()) {}

//@dump-sem-ir-begin
choice U {
  A(x: ()),
  B(y: i32)
}

fn MakeA() -> U { return U.A(()); }
fn MakeB(n: i32) -> U { return U.B(n); }

fn Classify(u: U) -> i32 {
  match (u) {
    case .A(x: ()) => {
      Sink(x);
      return 0;
    }
    case .B(y: i32) => { return y; }
  }
  // Unreachable trailing return: reachability doesn't consult match
  // exhaustiveness.
  return -1;
}
//@dump-sem-ir-end

// --- control_flow_unit.carbon
library "[[@TEST_NAME]]";

fn Sink(unused u: ()) {}

//@dump-sem-ir-begin
fn MakeBreak() -> Core.ControlFlow(i32, ()) {
  return Core.ControlFlow(i32, ()).Break(());
}

fn MakeContinue(n: i32) -> Core.ControlFlow(i32, ()) {
  return Core.ControlFlow(i32, ()).Continue(n);
}

fn Classify(c: Core.ControlFlow(i32, ())) -> i32 {
  match (c) {
    case .Continue(v: i32) => { return v; }
    case .Break(b: ()) => {
      Sink(b);
      return -1;
    }
  }
  // Unreachable trailing return: reachability doesn't consult match
  // exhaustiveness.
  return -2;
}
//@dump-sem-ir-end

// CHECK:STDOUT: --- unit_payload.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %empty_tuple: %empty_tuple.type = tuple_value () [concrete]
// CHECK:STDOUT:   %pattern_type.cb1: type = pattern_type %empty_tuple.type [concrete]
// CHECK:STDOUT:   %Sink.type: type = fn_type @Sink [concrete]
// CHECK:STDOUT:   %Sink: %Sink.type = struct_value () [concrete]
// CHECK:STDOUT:   %U.951: type = class_type @U [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %u1: type = class_type @UInt, @UInt(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %tuple.type.9fb: type = tuple_type (%empty_tuple.type) [concrete]
// CHECK:STDOUT:   %tuple.type.a8a: type = tuple_type (%i32) [concrete]
// CHECK:STDOUT:   %.dbf: type = custom_layout_type {size=4, align=4, .A@0: %tuple.type.9fb, .B@0: %tuple.type.a8a} [concrete]
// CHECK:STDOUT:   %struct_type.discriminant.payload.932: type = struct_type {.discriminant: %u1, .payload: %.dbf} [concrete]
// CHECK:STDOUT:   %complete_type.c92: <witness> = complete_type_witness %struct_type.discriminant.payload.932 [concrete]
// CHECK:STDOUT:   %_.param_patt.e01: %pattern_type.cb1 = value_param_pattern [concrete]
// CHECK:STDOUT:   %_.patt.a40: %pattern_type.cb1 = wrapper_binding_pattern _, %_.param_patt.e01 [concrete]
// CHECK:STDOUT:   %.0f7: Core.Form = init_form %U.951 [concrete]
// CHECK:STDOUT:   %pattern_type.3db: type = pattern_type %U.951 [concrete]
// CHECK:STDOUT:   %return.param_patt.818: %pattern_type.3db = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.460: %pattern_type.3db = return_slot_pattern %return.param_patt.818, %U.951 [concrete]
// CHECK:STDOUT:   %U.A.type: type = fn_type @U.A [concrete]
// CHECK:STDOUT:   %U.A: %U.A.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.ca1: type = facet_type <@ImplicitAs, @ImplicitAs(%u1)> [concrete]
// CHECK:STDOUT:   %To.fe9: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.170: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.f4c: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.f01, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.46b: %ImplicitAs.type.ca1 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.f4c) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.77c: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%u1, %ImplicitAs.facet.46b) [concrete]
// CHECK:STDOUT:   %.e74: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.77c, %ImplicitAs.facet.46b [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.0e8: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
// CHECK:STDOUT:   %int_0.1a7: %u1 = int_value 0 [concrete]
// CHECK:STDOUT:   %tuple.f41: %tuple.type.9fb = tuple_value (%empty_tuple) [concrete]
// CHECK:STDOUT:   %U.val: %U.951 = struct_value (%int_0.1a7, %tuple.f41) [concrete]
// CHECK:STDOUT:   %_.param_patt.fb2: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %_.patt.c1e: %pattern_type.6b6 = wrapper_binding_pattern _, %_.param_patt.fb2 [concrete]
// CHECK:STDOUT:   %U.B.type: type = fn_type @U.B [concrete]
// CHECK:STDOUT:   %U.B: %U.B.type = struct_value () [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %bound_method.d7a: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
// CHECK:STDOUT:   %int_1.233: %u1 = int_value 1 [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet: %Copy.type = facet_value %i32, (%Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.381: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet) [concrete]
// CHECK:STDOUT:   %.737: type = fn_type_with_self_type %Copy.WithSelf.Op.type.381, %Copy.facet [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %MakeA.type: type = fn_type @MakeA [concrete]
// CHECK:STDOUT:   %MakeA: %MakeA.type = struct_value () [concrete]
// CHECK:STDOUT:   %n.param_patt: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %n.patt: %pattern_type.6b6 = wrapper_binding_pattern n, %n.param_patt [concrete]
// CHECK:STDOUT:   %MakeB.type: type = fn_type @MakeB [concrete]
// CHECK:STDOUT:   %MakeB: %MakeB.type = struct_value () [concrete]
// CHECK:STDOUT:   %u.param_patt.5d6: %pattern_type.3db = value_param_pattern [concrete]
// CHECK:STDOUT:   %u.patt.eb2: %pattern_type.3db = wrapper_binding_pattern u, %u.param_patt.5d6 [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %Classify.type: type = fn_type @Classify [concrete]
// CHECK:STDOUT:   %Classify: %Classify.type = struct_value () [concrete]
// CHECK:STDOUT:   %x.patt.e8b: %pattern_type.cb1 = value_binding_pattern x [concrete]
// CHECK:STDOUT:   %pattern_type.559: type = pattern_type %tuple.type.9fb [concrete]
// CHECK:STDOUT:   %.59f: %pattern_type.559 = tuple_pattern (%x.patt.e8b) [concrete]
// CHECK:STDOUT:   %EqWith.type.c25: type = facet_type <@EqWith, @EqWith(%u1)> [concrete]
// CHECK:STDOUT:   %M: Core.IntLiteral = symbolic_binding M, 1 [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.544: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%N, %M) [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.c67: %UInt.as.EqWith.impl.Equal.type.544 = struct_value () [symbolic]
// CHECK:STDOUT:   %EqWith.impl_witness.7b3: <witness> = impl_witness imports.%EqWith.impl_witness_table.166, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.29b: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.ba4: %UInt.as.EqWith.impl.Equal.type.29b = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.4d0: %EqWith.type.c25 = facet_value %u1, (%EqWith.impl_witness.7b3) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.e3c: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%u1, %EqWith.facet.4d0) [concrete]
// CHECK:STDOUT:   %.9eb: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.e3c, %EqWith.facet.4d0 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound.f34: <bound method> = bound_method %int_0.1a7, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.specific_fn.6b6: <specific function> = specific_function %UInt.as.EqWith.impl.Equal.ba4, @UInt.as.EqWith.impl.Equal.1(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.53a: <bound method> = bound_method %int_0.1a7, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.48f: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet.48f [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.6e0: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_0.3c0: %i32 = int_value 0 [concrete]
// CHECK:STDOUT:   %y.patt.489: %pattern_type.6b6 = value_binding_pattern y [concrete]
// CHECK:STDOUT:   %pattern_type.e71: type = pattern_type %tuple.type.a8a [concrete]
// CHECK:STDOUT:   %.54b: %pattern_type.e71 = tuple_pattern (%y.patt.489) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound.22c: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %bound_method.a82: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
// CHECK:STDOUT:   %Negate.type: type = facet_type <@Negate> [concrete]
// CHECK:STDOUT:   %Negate.impl_witness: <witness> = impl_witness imports.%Negate.impl_witness_table [concrete]
// CHECK:STDOUT:   %Negate.facet: %Negate.type = facet_value Core.IntLiteral, (%Negate.impl_witness) [concrete]
// CHECK:STDOUT:   %Negate.WithSelf.Op.type.e85: type = fn_type @Negate.WithSelf.Op, @Negate.WithSelf(%Negate.facet) [concrete]
// CHECK:STDOUT:   %.758: type = fn_type_with_self_type %Negate.WithSelf.Op.type.e85, %Negate.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.type: type = fn_type @Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op: %Core.IntLiteral.as.Negate.impl.Op.type = struct_value () [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.bound: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %int_-1.638: Core.IntLiteral = int_value -1 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.65e: <bound method> = bound_method %int_-1.638, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.a65: <bound method> = bound_method %int_-1.638, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_-1.4ef: %i32 = int_value -1 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.aa5: @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.170)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.f01 = impl_witness_table (%Core.import_ref.aa5), @Core.IntLiteral.as.ImplicitAs.impl.b68 [concrete]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.b92: @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal.type (%UInt.as.EqWith.impl.Equal.type.544) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal (constants.%UInt.as.EqWith.impl.Equal.c67)]
// CHECK:STDOUT:   %Core.import_ref.b44 = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.166 = impl_witness_table (%Core.import_ref.b92, %Core.import_ref.b44), @UInt.as.EqWith.impl.f13 [concrete]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.abd = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9c3: %Core.IntLiteral.as.Negate.impl.Op.type = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, loaded [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %Negate.impl_witness_table = impl_witness_table (%Core.import_ref.abd, %Core.import_ref.9c3), @Core.IntLiteral.as.Negate.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %U.A.decl: %U.A.type = fn_decl @U.A [concrete = constants.%U.A] {
// CHECK:STDOUT:     %_.param_patt: %pattern_type.cb1 = value_param_pattern [concrete = constants.%_.param_patt.e01]
// CHECK:STDOUT:     %_.patt: %pattern_type.cb1 = wrapper_binding_pattern _, %_.param_patt [concrete = constants.%_.patt.a40]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.3db = out_param_pattern [concrete = constants.%return.param_patt.818]
// CHECK:STDOUT:     %return.patt: %pattern_type.3db = return_slot_pattern %return.param_patt, constants.%U.951 [concrete = constants.%return.patt.460]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc6_10.10: Core.Form = init_form constants.%U.951 [concrete = constants.%.0f7]
// CHECK:STDOUT:     %_.param: %empty_tuple.type = value_param call_param0
// CHECK:STDOUT:     %_: %empty_tuple.type = wrapper_binding _, %_.param
// CHECK:STDOUT:     %return.param: ref %U.951 = out_param call_param1
// CHECK:STDOUT:     %return: ref %U.951 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %U.B.decl: %U.B.type = fn_decl @U.B [concrete = constants.%U.B] {
// CHECK:STDOUT:     %_.param_patt: %pattern_type.6b6 = value_param_pattern [concrete = constants.%_.param_patt.fb2]
// CHECK:STDOUT:     %_.patt: %pattern_type.6b6 = wrapper_binding_pattern _, %_.param_patt [concrete = constants.%_.patt.c1e]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.3db = out_param_pattern [concrete = constants.%return.param_patt.818]
// CHECK:STDOUT:     %return.patt: %pattern_type.3db = return_slot_pattern %return.param_patt, constants.%U.951 [concrete = constants.%return.patt.460]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc6_10.9: Core.Form = init_form constants.%U.951 [concrete = constants.%.0f7]
// CHECK:STDOUT:     %_.param: %i32 = value_param call_param0
// CHECK:STDOUT:     %_: %i32 = wrapper_binding _, %_.param
// CHECK:STDOUT:     %return.param: ref %U.951 = out_param call_param1
// CHECK:STDOUT:     %return: ref %U.951 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %U.decl: type = class_decl @U [concrete = constants.%U.951] {} {}
// CHECK:STDOUT:   %MakeA.decl: %MakeA.type = fn_decl @MakeA [concrete = constants.%MakeA] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.3db = out_param_pattern [concrete = constants.%return.param_patt.818]
// CHECK:STDOUT:     %return.patt: %pattern_type.3db = return_slot_pattern %return.param_patt, %U.ref.loc11_15 [concrete = constants.%return.patt.460]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %U.ref.loc11_15: type = name_ref U, file.%U.decl [concrete = constants.%U.951]
// CHECK:STDOUT:     %.loc11_15.2: Core.Form = init_form %U.ref.loc11_15 [concrete = constants.%.0f7]
// CHECK:STDOUT:     %return.param: ref %U.951 = out_param call_param0
// CHECK:STDOUT:     %return: ref %U.951 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %MakeB.decl: %MakeB.type = fn_decl @MakeB [concrete = constants.%MakeB] {
// CHECK:STDOUT:     %n.param_patt: %pattern_type.6b6 = value_param_pattern [concrete = constants.%n.param_patt]
// CHECK:STDOUT:     %n.patt: %pattern_type.6b6 = wrapper_binding_pattern n, %n.param_patt [concrete = constants.%n.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.3db = out_param_pattern [concrete = constants.%return.param_patt.818]
// CHECK:STDOUT:     %return.patt: %pattern_type.3db = return_slot_pattern %return.param_patt, %U.ref.loc12_21 [concrete = constants.%return.patt.460]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %U.ref.loc12_21: type = name_ref U, file.%U.decl [concrete = constants.%U.951]
// CHECK:STDOUT:     %.loc12_21.2: Core.Form = init_form %U.ref.loc12_21 [concrete = constants.%.0f7]
// CHECK:STDOUT:     %n.param: %i32 = value_param call_param0
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %n: %i32 = wrapper_binding n, %n.param
// CHECK:STDOUT:     %return.param: ref %U.951 = out_param call_param1
// CHECK:STDOUT:     %return: ref %U.951 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Classify.decl: %Classify.type = fn_decl @Classify [concrete = constants.%Classify] {
// CHECK:STDOUT:     %u.param_patt: %pattern_type.3db = value_param_pattern [concrete = constants.%u.param_patt.5d6]
// CHECK:STDOUT:     %u.patt: %pattern_type.3db = wrapper_binding_pattern u, %u.param_patt [concrete = constants.%u.patt.eb2]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc14 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc14: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc14: Core.Form = init_form %i32.loc14 [concrete = constants.%.795f]
// CHECK:STDOUT:     %u.param: %U.951 = value_param call_param0
// CHECK:STDOUT:     %U.ref: type = name_ref U, file.%U.decl [concrete = constants.%U.951]
// CHECK:STDOUT:     %u: %U.951 = wrapper_binding u, %u.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: class @U {
// CHECK:STDOUT:   %x.param: %empty_tuple.type = value_param call_param0
// CHECK:STDOUT:   %.loc7_9.1: type = splice_block %.loc7_9.3 [concrete = constants.%empty_tuple.type] {
// CHECK:STDOUT:     %.loc7_9.2: %empty_tuple.type = tuple_literal () [concrete = constants.%empty_tuple]
// CHECK:STDOUT:     %.loc7_9.3: type = converted %.loc7_9.2, constants.%empty_tuple.type [concrete = constants.%empty_tuple.type]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %x: %empty_tuple.type = wrapper_binding x, %x.param
// CHECK:STDOUT:   %y.param: %i32 = value_param call_param0
// CHECK:STDOUT:   %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %y: %i32 = wrapper_binding y, %y.param
// CHECK:STDOUT:   %.loc9: type = custom_layout_type {size=4, align=4, .A@0: %tuple.type.9fb, .B@0: %tuple.type.a8a} [concrete = constants.%.dbf]
// CHECK:STDOUT:   %complete_type: <witness> = complete_type_witness constants.%struct_type.discriminant.payload.932 [concrete = constants.%complete_type.c92]
// CHECK:STDOUT:   complete_type_witness = %complete_type
// CHECK:STDOUT:
// CHECK:STDOUT: !members:
// CHECK:STDOUT:   .Self = constants.%U.951
// CHECK:STDOUT:   .A = generated.%U.A.decl
// CHECK:STDOUT:   .B = generated.%U.B.decl
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @U.A(%_.param: %empty_tuple.type) -> out %return.param: %U.951 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %.loc6_10.1: ref %u1 = class_element_access %return.param, element0
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc6_10.1: <bound method> = bound_method %int_0, %impl.elem0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:   %specific_fn: <specific function> = specific_function %impl.elem0, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc6_10.2: <bound method> = bound_method %int_0, %specific_fn [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %u1 = call %bound_method.loc6_10.2(%int_0) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc6_10.2: init %u1 = converted %int_0, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc6_10.3: init %u1 to %.loc6_10.1 = in_place_init %.loc6_10.2 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc6_10.4: ref %.dbf = class_element_access %return.param, element1
// CHECK:STDOUT:   %.loc6_10.5: ref %tuple.type.9fb = class_element_access %.loc6_10.4, element0
// CHECK:STDOUT:   %.loc7_11.1: %tuple.type.9fb = tuple_literal (%_.param)
// CHECK:STDOUT:   %tuple.elem0: ref %empty_tuple.type = tuple_access %.loc6_10.5, element0
// CHECK:STDOUT:   %.loc6_10.6: init %empty_tuple.type = tuple_init () [concrete = constants.%empty_tuple]
// CHECK:STDOUT:   %.loc7_11.2: init %empty_tuple.type = converted %_.param, %.loc6_10.6 [concrete = constants.%empty_tuple]
// CHECK:STDOUT:   %.loc7_11.3: init %tuple.type.9fb to %.loc6_10.5 = tuple_init (%.loc7_11.2) [concrete = constants.%tuple.f41]
// CHECK:STDOUT:   %.loc6_10.7: init %tuple.type.9fb = converted %.loc7_11.1, %.loc7_11.3 [concrete = constants.%tuple.f41]
// CHECK:STDOUT:   %.loc6_10.8: init %tuple.type.9fb to %.loc6_10.5 = in_place_init %.loc6_10.7 [concrete = constants.%tuple.f41]
// CHECK:STDOUT:   %.loc6_10.9: init %U.951 to %return.param = class_init (%.loc6_10.3, %.loc6_10.8) [concrete = constants.%U.val]
// CHECK:STDOUT:   return %.loc6_10.9 to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @U.B(%_.param: %i32) -> out %return.param: %U.951 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %.loc6_10.1: ref %u1 = class_element_access %return.param, element0
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc6_10.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc6_10.1: <bound method> = bound_method %int_1, %impl.elem0.loc6_10.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc6_10.1: <specific function> = specific_function %impl.elem0.loc6_10.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc6_10.2: <bound method> = bound_method %int_1, %specific_fn.loc6_10.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %u1 = call %bound_method.loc6_10.2(%int_1) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc6_10.2: init %u1 = converted %int_1, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc6_10.3: init %u1 to %.loc6_10.1 = in_place_init %.loc6_10.2 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc6_10.4: ref %.dbf = class_element_access %return.param, element1
// CHECK:STDOUT:   %.loc6_10.5: ref %tuple.type.a8a = class_element_access %.loc6_10.4, element1
// CHECK:STDOUT:   %.loc9_1.1: %tuple.type.a8a = tuple_literal (%_.param)
// CHECK:STDOUT:   %impl.elem0.loc6_10.2: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc6_10.3: <bound method> = bound_method %_.param, %impl.elem0.loc6_10.2
// CHECK:STDOUT:   %specific_fn.loc6_10.2: <specific function> = specific_function %impl.elem0.loc6_10.2, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc6_10.4: <bound method> = bound_method %_.param, %specific_fn.loc6_10.2
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc6_10.4(%_.param)
// CHECK:STDOUT:   %.loc9_1.2: init %tuple.type.a8a to %.loc6_10.5 = tuple_init (%Int.as.Copy.impl.Op.call)
// CHECK:STDOUT:   %.loc6_10.6: init %tuple.type.a8a = converted %.loc9_1.1, %.loc9_1.2
// CHECK:STDOUT:   %.loc6_10.7: init %tuple.type.a8a to %.loc6_10.5 = in_place_init %.loc6_10.6
// CHECK:STDOUT:   %.loc6_10.8: init %U.951 to %return.param = class_init (%.loc6_10.3, %.loc6_10.7)
// CHECK:STDOUT:   return %.loc6_10.8 to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @MakeA() -> out %return.param: %U.951 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %U.ref.loc11_26: type = name_ref U, file.%U.decl [concrete = constants.%U.951]
// CHECK:STDOUT:   %A.ref: %U.A.type = name_ref A, generated.%U.A.decl [concrete = constants.%U.A]
// CHECK:STDOUT:   %.loc11_31.1: %empty_tuple.type = tuple_literal () [concrete = constants.%empty_tuple]
// CHECK:STDOUT:   %.loc11_15.1: ref %U.951 = splice_block %return.param {}
// CHECK:STDOUT:   %empty_tuple: %empty_tuple.type = tuple_value () [concrete = constants.%empty_tuple]
// CHECK:STDOUT:   %.loc11_31.2: %empty_tuple.type = converted %.loc11_31.1, %empty_tuple [concrete = constants.%empty_tuple]
// CHECK:STDOUT:   %U.A.call: init %U.951 to %.loc11_15.1 = call %A.ref(%.loc11_31.2)
// CHECK:STDOUT:   return %U.A.call to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @MakeB(%n.param: %i32) -> out %return.param: %U.951 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %U.ref.loc12_32: type = name_ref U, file.%U.decl [concrete = constants.%U.951]
// CHECK:STDOUT:   %B.ref: %U.B.type = name_ref B, generated.%U.B.decl [concrete = constants.%U.B]
// CHECK:STDOUT:   %n.ref: %i32 = name_ref n, %n
// CHECK:STDOUT:   %.loc12_21.1: ref %U.951 = splice_block %return.param {}
// CHECK:STDOUT:   %U.B.call: init %U.951 to %.loc12_21.1 = call %B.ref(%n.ref)
// CHECK:STDOUT:   return %U.B.call to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Classify(%u.param: %U.951) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %u.ref: %U.951 = name_ref u, %u
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %x.patt: %pattern_type.cb1 = value_binding_pattern x [concrete = constants.%x.patt.e8b]
// CHECK:STDOUT:     %.loc16_14: %pattern_type.559 = tuple_pattern (%x.patt) [concrete = constants.%.59f]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_0.loc16: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc16_20.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc16_20.1: <bound method> = bound_method %int_0.loc16, %impl.elem0.loc16_20.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:   %specific_fn.loc16_20.1: <specific function> = specific_function %impl.elem0.loc16_20.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc16_20.2: <bound method> = bound_method %int_0.loc16, %specific_fn.loc16_20.1 [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16: init %u1 = call %bound_method.loc16_20.2(%int_0.loc16) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc16_20.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc16_20.2: %u1 = converted %int_0.loc16, %.loc16_20.1 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc16_20.3: ref %u1 = class_element_access %u.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc16_20.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc16_20.3: <bound method> = bound_method %.loc16_20.2, %impl.elem0.loc16_20.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.f34]
// CHECK:STDOUT:   %specific_fn.loc16_20.2: <specific function> = specific_function %impl.elem0.loc16_20.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc16_20.4: <bound method> = bound_method %.loc16_20.2, %specific_fn.loc16_20.2 [concrete = constants.%bound_method.53a]
// CHECK:STDOUT:   %.loc16_20.4: %u1 = acquire_value %.loc16_20.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc16: init bool = call %bound_method.loc16_20.4(%.loc16_20.2, %.loc16_20.4)
// CHECK:STDOUT:   %.loc16_20.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc16
// CHECK:STDOUT:   %.loc16_20.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc16, %.loc16_20.5
// CHECK:STDOUT:   if %.loc16_20.6 br !match.case.then.loc16 else br !match.case.else.loc16
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc16:
// CHECK:STDOUT:   %.loc16_20.7: ref %.dbf = class_element_access %u.ref, element1
// CHECK:STDOUT:   %.loc16_20.8: ref %tuple.type.9fb = class_element_access %.loc16_20.7, element0
// CHECK:STDOUT:   %tuple.elem0.loc16: ref %empty_tuple.type = tuple_access %.loc16_20.8, element0
// CHECK:STDOUT:   %tuple: %empty_tuple.type = tuple_value () [concrete = constants.%empty_tuple]
// CHECK:STDOUT:   %.loc16_20.9: %empty_tuple.type = converted %tuple.elem0.loc16, %tuple [concrete = constants.%empty_tuple]
// CHECK:STDOUT:   %.loc16_17.1: type = splice_block %.loc16_17.3 [concrete = constants.%empty_tuple.type] {
// CHECK:STDOUT:     %.loc16_17.2: %empty_tuple.type = tuple_literal () [concrete = constants.%empty_tuple]
// CHECK:STDOUT:     %.loc16_17.3: type = converted %.loc16_17.2, constants.%empty_tuple.type [concrete = constants.%empty_tuple.type]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %x: %empty_tuple.type = wrapper_binding x, %.loc16_20.9
// CHECK:STDOUT:   %Sink.ref: %Sink.type = name_ref Sink, file.%Sink.decl [concrete = constants.%Sink]
// CHECK:STDOUT:   %x.ref: %empty_tuple.type = name_ref x, %x
// CHECK:STDOUT:   %Sink.call: init %empty_tuple.type = call %Sink.ref(%x.ref)
// CHECK:STDOUT:   %int_0.loc18: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc18: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc18_15.1: <bound method> = bound_method %int_0.loc18, %impl.elem0.loc18 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc18: <specific function> = specific_function %impl.elem0.loc18, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc18_15.2: <bound method> = bound_method %int_0.loc18, %specific_fn.loc18 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc18: init %i32 = call %bound_method.loc18_15.2(%int_0.loc18) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc18: init %i32 = converted %int_0.loc18, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc18 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   return %.loc18
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc16:
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %y.patt: %pattern_type.6b6 = value_binding_pattern y [concrete = constants.%y.patt.489]
// CHECK:STDOUT:     %.loc20_14: %pattern_type.e71 = tuple_pattern (%y.patt) [concrete = constants.%.54b]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_1.loc20: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc20_21.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc20_21.1: <bound method> = bound_method %int_1.loc20, %impl.elem0.loc20_21.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc20_21.1: <specific function> = specific_function %impl.elem0.loc20_21.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc20_21.2: <bound method> = bound_method %int_1.loc20, %specific_fn.loc20_21.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc20: init %u1 = call %bound_method.loc20_21.2(%int_1.loc20) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc20_21.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc20 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc20_21.2: %u1 = converted %int_1.loc20, %.loc20_21.1 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc20_21.3: ref %u1 = class_element_access %u.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc20_21.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc20_21.3: <bound method> = bound_method %.loc20_21.2, %impl.elem0.loc20_21.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.22c]
// CHECK:STDOUT:   %specific_fn.loc20_21.2: <specific function> = specific_function %impl.elem0.loc20_21.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc20_21.4: <bound method> = bound_method %.loc20_21.2, %specific_fn.loc20_21.2 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc20_21.4: %u1 = acquire_value %.loc20_21.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc20: init bool = call %bound_method.loc20_21.4(%.loc20_21.2, %.loc20_21.4)
// CHECK:STDOUT:   %.loc20_21.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc20
// CHECK:STDOUT:   %.loc20_21.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc20, %.loc20_21.5
// CHECK:STDOUT:   if %.loc20_21.6 br !match.case.then.loc20 else br !match.case.else.loc20
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc20:
// CHECK:STDOUT:   %.loc20_21.7: ref %.dbf = class_element_access %u.ref, element1
// CHECK:STDOUT:   %.loc20_21.8: ref %tuple.type.a8a = class_element_access %.loc20_21.7, element1
// CHECK:STDOUT:   %tuple.elem0.loc20: ref %i32 = tuple_access %.loc20_21.8, element0
// CHECK:STDOUT:   %.loc20_21.9: %i32 = acquire_value %tuple.elem0.loc20
// CHECK:STDOUT:   %i32.loc20: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %y: %i32 = wrapper_binding y, %.loc20_21.9
// CHECK:STDOUT:   %y.ref: %i32 = name_ref y, %y
// CHECK:STDOUT:   %impl.elem0.loc20_33: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc20_33.1: <bound method> = bound_method %y.ref, %impl.elem0.loc20_33
// CHECK:STDOUT:   %specific_fn.loc20_33: <specific function> = specific_function %impl.elem0.loc20_33, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc20_33.2: <bound method> = bound_method %y.ref, %specific_fn.loc20_33
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc20_33.2(%y.ref)
// CHECK:STDOUT:   return %Int.as.Copy.impl.Op.call
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc20:
// CHECK:STDOUT:   br !match.done
// CHECK:STDOUT:
// CHECK:STDOUT: !match.done:
// CHECK:STDOUT:   %int_1.loc24: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem1: %.758 = impl_witness_access constants.%Negate.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %bound_method.loc24_10: <bound method> = bound_method %int_1.loc24, %impl.elem1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op.bound]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.call: init Core.IntLiteral = call %bound_method.loc24_10(%int_1.loc24) [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %impl.elem0.loc24: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc24_12.1: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %impl.elem0.loc24 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.65e]
// CHECK:STDOUT:   %specific_fn.loc24: <specific function> = specific_function %impl.elem0.loc24, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc24_12.2: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %specific_fn.loc24 [concrete = constants.%bound_method.a65]
// CHECK:STDOUT:   %.loc24_10.1: Core.IntLiteral = value_of_initializer %Core.IntLiteral.as.Negate.impl.Op.call [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %.loc24_10.2: Core.IntLiteral = converted %Core.IntLiteral.as.Negate.impl.Op.call, %.loc24_10.1 [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc24: init %i32 = call %bound_method.loc24_12.2(%.loc24_10.2) [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   %.loc24_12: init %i32 = converted %Core.IntLiteral.as.Negate.impl.Op.call, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc24 [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   return %.loc24_12
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- control_flow_unit.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %empty_tuple: %empty_tuple.type = tuple_value () [concrete]
// CHECK:STDOUT:   %pattern_type.cb1: type = pattern_type %empty_tuple.type [concrete]
// CHECK:STDOUT:   %Sink.type: type = fn_type @Sink [concrete]
// CHECK:STDOUT:   %Sink: %Sink.type = struct_value () [concrete]
// CHECK:STDOUT:   %ControlFlow.type: type = generic_class_type @ControlFlow [concrete]
// CHECK:STDOUT:   %ControlFlow.generic: %ControlFlow.type = struct_value () [concrete]
// CHECK:STDOUT:   %B: type = symbolic_binding B, 1 [symbolic]
// CHECK:STDOUT:   %C: type = symbolic_binding C, 0 [symbolic]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %u1: type = class_type @UInt, @UInt(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %ControlFlow.Break.type.a62: type = fn_type @ControlFlow.Break, @ControlFlow(%C, %B) [symbolic]
// CHECK:STDOUT:   %ControlFlow.Break.071: %ControlFlow.Break.type.a62 = struct_value () [symbolic]
// CHECK:STDOUT:   %int_1.233: %u1 = int_value 1 [concrete]
// CHECK:STDOUT:   %ControlFlow.Continue.type.ebc: type = fn_type @ControlFlow.Continue, @ControlFlow(%C, %B) [symbolic]
// CHECK:STDOUT:   %ControlFlow.Continue.533: %ControlFlow.Continue.type.ebc = struct_value () [symbolic]
// CHECK:STDOUT:   %int_0.1a7: %u1 = int_value 0 [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %Int.type: type = generic_class_type @Int [concrete]
// CHECK:STDOUT:   %Int.generic: %Int.type = struct_value () [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %ControlFlow.59f: type = class_type @ControlFlow, @ControlFlow(%i32, %empty_tuple.type) [concrete]
// CHECK:STDOUT:   %.8cb: Core.Form = init_form %ControlFlow.59f [concrete]
// CHECK:STDOUT:   %pattern_type.3c2: type = pattern_type %ControlFlow.59f [concrete]
// CHECK:STDOUT:   %return.param_patt.787: %pattern_type.3c2 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e6d: %pattern_type.3c2 = return_slot_pattern %return.param_patt.787, %ControlFlow.59f [concrete]
// CHECK:STDOUT:   %MakeBreak.type: type = fn_type @MakeBreak [concrete]
// CHECK:STDOUT:   %MakeBreak: %MakeBreak.type = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %tuple.type.a8a: type = tuple_type (%i32) [concrete]
// CHECK:STDOUT:   %tuple.type.9fb: type = tuple_type (%empty_tuple.type) [concrete]
// CHECK:STDOUT:   %.96b: type = custom_layout_type {size=4, align=4, .Continue@0: %tuple.type.a8a, .Break@0: %tuple.type.9fb} [concrete]
// CHECK:STDOUT:   %ControlFlow.Continue.type.886: type = fn_type @ControlFlow.Continue, @ControlFlow(%i32, %empty_tuple.type) [concrete]
// CHECK:STDOUT:   %ControlFlow.Continue.441: %ControlFlow.Continue.type.886 = struct_value () [concrete]
// CHECK:STDOUT:   %ControlFlow.Break.type.907: type = fn_type @ControlFlow.Break, @ControlFlow(%i32, %empty_tuple.type) [concrete]
// CHECK:STDOUT:   %ControlFlow.Break.a23: %ControlFlow.Break.type.907 = struct_value () [concrete]
// CHECK:STDOUT:   %ControlFlow.Break.specific_fn: <specific function> = specific_function %ControlFlow.Break.a23, @ControlFlow.Break(%i32, %empty_tuple.type) [concrete]
// CHECK:STDOUT:   %n.param_patt: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %n.patt: %pattern_type.6b6 = wrapper_binding_pattern n, %n.param_patt [concrete]
// CHECK:STDOUT:   %MakeContinue.type: type = fn_type @MakeContinue [concrete]
// CHECK:STDOUT:   %MakeContinue: %MakeContinue.type = struct_value () [concrete]
// CHECK:STDOUT:   %ControlFlow.Continue.specific_fn: <specific function> = specific_function %ControlFlow.Continue.441, @ControlFlow.Continue(%i32, %empty_tuple.type) [concrete]
// CHECK:STDOUT:   %c.param_patt: %pattern_type.3c2 = value_param_pattern [concrete]
// CHECK:STDOUT:   %c.patt: %pattern_type.3c2 = wrapper_binding_pattern c, %c.param_patt [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %Classify.type: type = fn_type @Classify [concrete]
// CHECK:STDOUT:   %Classify: %Classify.type = struct_value () [concrete]
// CHECK:STDOUT:   %v.patt: %pattern_type.6b6 = value_binding_pattern v [concrete]
// CHECK:STDOUT:   %pattern_type.e71: type = pattern_type %tuple.type.a8a [concrete]
// CHECK:STDOUT:   %.13b: %pattern_type.e71 = tuple_pattern (%v.patt) [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.0ff: type = generic_interface_type @ImplicitAs [concrete]
// CHECK:STDOUT:   %ImplicitAs.generic: %ImplicitAs.type.0ff = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.ca1: type = facet_type <@ImplicitAs, @ImplicitAs(%u1)> [concrete]
// CHECK:STDOUT:   %To.fe9: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.170: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.f4c: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.f01, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.46b: %ImplicitAs.type.ca1 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.f4c) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.77c: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%u1, %ImplicitAs.facet.46b) [concrete]
// CHECK:STDOUT:   %.e74: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.77c, %ImplicitAs.facet.46b [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.0e8: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
// CHECK:STDOUT:   %EqWith.type.f77: type = generic_interface_type @EqWith [concrete]
// CHECK:STDOUT:   %EqWith.generic: %EqWith.type.f77 = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.type.c25: type = facet_type <@EqWith, @EqWith(%u1)> [concrete]
// CHECK:STDOUT:   %M: Core.IntLiteral = symbolic_binding M, 1 [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.544: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%N, %M) [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.c67: %UInt.as.EqWith.impl.Equal.type.544 = struct_value () [symbolic]
// CHECK:STDOUT:   %EqWith.impl_witness.7b3: <witness> = impl_witness imports.%EqWith.impl_witness_table.166, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.29b: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.ba4: %UInt.as.EqWith.impl.Equal.type.29b = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.4d0: %EqWith.type.c25 = facet_value %u1, (%EqWith.impl_witness.7b3) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.e3c: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%u1, %EqWith.facet.4d0) [concrete]
// CHECK:STDOUT:   %.9eb: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.e3c, %EqWith.facet.4d0 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound.f34: <bound method> = bound_method %int_0.1a7, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.specific_fn.6b6: <specific function> = specific_function %UInt.as.EqWith.impl.Equal.ba4, @UInt.as.EqWith.impl.Equal.1(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.53a: <bound method> = bound_method %int_0.1a7, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet: %Copy.type = facet_value %i32, (%Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.381: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet) [concrete]
// CHECK:STDOUT:   %.737: type = fn_type_with_self_type %Copy.WithSelf.Op.type.381, %Copy.facet [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %b.patt: %pattern_type.cb1 = value_binding_pattern b [concrete]
// CHECK:STDOUT:   %pattern_type.559: type = pattern_type %tuple.type.9fb [concrete]
// CHECK:STDOUT:   %.c3c: %pattern_type.559 = tuple_pattern (%b.patt) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %bound_method.d7a: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound.22c: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %bound_method.a82: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
// CHECK:STDOUT:   %Negate.type: type = facet_type <@Negate> [concrete]
// CHECK:STDOUT:   %Negate.impl_witness: <witness> = impl_witness imports.%Negate.impl_witness_table [concrete]
// CHECK:STDOUT:   %Negate.facet: %Negate.type = facet_value Core.IntLiteral, (%Negate.impl_witness) [concrete]
// CHECK:STDOUT:   %Negate.WithSelf.Op.type.e85: type = fn_type @Negate.WithSelf.Op, @Negate.WithSelf(%Negate.facet) [concrete]
// CHECK:STDOUT:   %.758: type = fn_type_with_self_type %Negate.WithSelf.Op.type.e85, %Negate.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.type: type = fn_type @Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op: %Core.IntLiteral.as.Negate.impl.Op.type = struct_value () [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.bound.6a0: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %int_-1.638: Core.IntLiteral = int_value -1 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.48f: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet.48f [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.65e: <bound method> = bound_method %int_-1.638, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.a65: <bound method> = bound_method %int_-1.638, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_-1.4ef: %i32 = int_value -1 [concrete]
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.bound.e21: <bound method> = bound_method %int_2, %Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %int_-2.962: Core.IntLiteral = int_value -2 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.2a0: <bound method> = bound_method %int_-2.962, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.33f: <bound method> = bound_method %int_-2.962, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_-2.c83: %i32 = int_value -2 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .ControlFlow = %Core.ControlFlow
// CHECK:STDOUT:     .Int = %Core.Int
// CHECK:STDOUT:     .ImplicitAs = %Core.ImplicitAs
// CHECK:STDOUT:     .EqWith = %Core.EqWith
// CHECK:STDOUT:     .Copy = %Core.Copy
// CHECK:STDOUT:     .Negate = %Core.Negate
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.ControlFlow: %ControlFlow.type = import_ref Core//prelude/try, ControlFlow, loaded [concrete = constants.%ControlFlow.generic]
// CHECK:STDOUT:   %Core.import_ref.903: @ControlFlow.%ControlFlow.Continue.type (%ControlFlow.Continue.type.ebc) = import_ref Core//prelude/try, loc{{\d+_\d+}}, loaded [symbolic = @ControlFlow.%ControlFlow.Continue (constants.%ControlFlow.Continue.533)]
// CHECK:STDOUT:   %Core.import_ref.72c: @ControlFlow.%ControlFlow.Break.type (%ControlFlow.Break.type.a62) = import_ref Core//prelude/try, loc{{\d+_\d+}}, loaded [symbolic = @ControlFlow.%ControlFlow.Break (constants.%ControlFlow.Break.071)]
// CHECK:STDOUT:   %Core.Int: %Int.type = import_ref Core//prelude/types/int, Int, loaded [concrete = constants.%Int.generic]
// CHECK:STDOUT:   %Core.ImplicitAs: %ImplicitAs.type.0ff = import_ref Core//prelude/operators/as, ImplicitAs, loaded [concrete = constants.%ImplicitAs.generic]
// CHECK:STDOUT:   %Core.import_ref.aa5: @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.170)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.f01 = impl_witness_table (%Core.import_ref.aa5), @Core.IntLiteral.as.ImplicitAs.impl.b68 [concrete]
// CHECK:STDOUT:   %Core.EqWith: %EqWith.type.f77 = import_ref Core//prelude/operators/comparison, EqWith, loaded [concrete = constants.%EqWith.generic]
// CHECK:STDOUT:   %Core.import_ref.b92: @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal.type (%UInt.as.EqWith.impl.Equal.type.544) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal (constants.%UInt.as.EqWith.impl.Equal.c67)]
// CHECK:STDOUT:   %Core.import_ref.b44 = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.166 = impl_witness_table (%Core.import_ref.b92, %Core.import_ref.b44), @UInt.as.EqWith.impl.f13 [concrete]
// CHECK:STDOUT:   %Core.Copy: type = import_ref Core//prelude/copy, Copy, loaded [concrete = constants.%Copy.type]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.Negate: type = import_ref Core//prelude/operators/arithmetic, Negate, loaded [concrete = constants.%Negate.type]
// CHECK:STDOUT:   %Core.import_ref.abd = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9c3: %Core.IntLiteral.as.Negate.impl.Op.type = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, loaded [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %Negate.impl_witness_table = impl_witness_table (%Core.import_ref.abd, %Core.import_ref.9c3), @Core.IntLiteral.as.Negate.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %MakeBreak.decl: %MakeBreak.type = fn_decl @MakeBreak [concrete = constants.%MakeBreak] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.3c2 = out_param_pattern [concrete = constants.%return.param_patt.787]
// CHECK:STDOUT:     %return.patt: %pattern_type.3c2 = return_slot_pattern %return.param_patt, %ControlFlow.loc6 [concrete = constants.%return.patt.e6d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %Core.ref.loc6: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:     %ControlFlow.ref.loc6: %ControlFlow.type = name_ref ControlFlow, imports.%Core.ControlFlow [concrete = constants.%ControlFlow.generic]
// CHECK:STDOUT:     %i32.loc6: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc6_42: %empty_tuple.type = tuple_literal () [concrete = constants.%empty_tuple]
// CHECK:STDOUT:     %.loc6_43.2: type = converted %.loc6_42, constants.%empty_tuple.type [concrete = constants.%empty_tuple.type]
// CHECK:STDOUT:     %ControlFlow.loc6: type = class_type @ControlFlow, @ControlFlow(constants.%i32, constants.%empty_tuple.type) [concrete = constants.%ControlFlow.59f]
// CHECK:STDOUT:     %.loc6_43.3: Core.Form = init_form %ControlFlow.loc6 [concrete = constants.%.8cb]
// CHECK:STDOUT:     %return.param: ref %ControlFlow.59f = out_param call_param0
// CHECK:STDOUT:     %return: ref %ControlFlow.59f = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %MakeContinue.decl: %MakeContinue.type = fn_decl @MakeContinue [concrete = constants.%MakeContinue] {
// CHECK:STDOUT:     %n.param_patt: %pattern_type.6b6 = value_param_pattern [concrete = constants.%n.param_patt]
// CHECK:STDOUT:     %n.patt: %pattern_type.6b6 = wrapper_binding_pattern n, %n.param_patt [concrete = constants.%n.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.3c2 = out_param_pattern [concrete = constants.%return.param_patt.787]
// CHECK:STDOUT:     %return.patt: %pattern_type.3c2 = return_slot_pattern %return.param_patt, %ControlFlow.loc10 [concrete = constants.%return.patt.e6d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %Core.ref.loc10: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:     %ControlFlow.ref.loc10: %ControlFlow.type = name_ref ControlFlow, imports.%Core.ControlFlow [concrete = constants.%ControlFlow.generic]
// CHECK:STDOUT:     %i32.loc10_45: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc10_51: %empty_tuple.type = tuple_literal () [concrete = constants.%empty_tuple]
// CHECK:STDOUT:     %.loc10_52.2: type = converted %.loc10_51, constants.%empty_tuple.type [concrete = constants.%empty_tuple.type]
// CHECK:STDOUT:     %ControlFlow.loc10: type = class_type @ControlFlow, @ControlFlow(constants.%i32, constants.%empty_tuple.type) [concrete = constants.%ControlFlow.59f]
// CHECK:STDOUT:     %.loc10_52.3: Core.Form = init_form %ControlFlow.loc10 [concrete = constants.%.8cb]
// CHECK:STDOUT:     %n.param: %i32 = value_param call_param0
// CHECK:STDOUT:     %i32.loc10_20: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %n: %i32 = wrapper_binding n, %n.param
// CHECK:STDOUT:     %return.param: ref %ControlFlow.59f = out_param call_param1
// CHECK:STDOUT:     %return: ref %ControlFlow.59f = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Classify.decl: %Classify.type = fn_decl @Classify [concrete = constants.%Classify] {
// CHECK:STDOUT:     %c.param_patt: %pattern_type.3c2 = value_param_pattern [concrete = constants.%c.param_patt]
// CHECK:STDOUT:     %c.patt: %pattern_type.3c2 = wrapper_binding_pattern c, %c.param_patt [concrete = constants.%c.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc14_46 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc14_46: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc14_46: Core.Form = init_form %i32.loc14_46 [concrete = constants.%.795f]
// CHECK:STDOUT:     %c.param: %ControlFlow.59f = value_param call_param0
// CHECK:STDOUT:     %.loc14_40.1: type = splice_block %ControlFlow [concrete = constants.%ControlFlow.59f] {
// CHECK:STDOUT:       %Core.ref: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %ControlFlow.ref: %ControlFlow.type = name_ref ControlFlow, imports.%Core.ControlFlow [concrete = constants.%ControlFlow.generic]
// CHECK:STDOUT:       %i32.loc14_33: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %.loc14_39: %empty_tuple.type = tuple_literal () [concrete = constants.%empty_tuple]
// CHECK:STDOUT:       %.loc14_40.2: type = converted %.loc14_39, constants.%empty_tuple.type [concrete = constants.%empty_tuple.type]
// CHECK:STDOUT:       %ControlFlow: type = class_type @ControlFlow, @ControlFlow(constants.%i32, constants.%empty_tuple.type) [concrete = constants.%ControlFlow.59f]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %c: %ControlFlow.59f = wrapper_binding c, %c.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @MakeBreak() -> out %return.param: %ControlFlow.59f {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Core.ref.loc7: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:   %ControlFlow.ref.loc7: %ControlFlow.type = name_ref ControlFlow, imports.%Core.ControlFlow [concrete = constants.%ControlFlow.generic]
// CHECK:STDOUT:   %i32.loc7: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %.loc7_33: %empty_tuple.type = tuple_literal () [concrete = constants.%empty_tuple]
// CHECK:STDOUT:   %.loc7_34: type = converted %.loc7_33, constants.%empty_tuple.type [concrete = constants.%empty_tuple.type]
// CHECK:STDOUT:   %ControlFlow.loc7: type = class_type @ControlFlow, @ControlFlow(constants.%i32, constants.%empty_tuple.type) [concrete = constants.%ControlFlow.59f]
// CHECK:STDOUT:   %.loc7_35: %ControlFlow.Break.type.907 = specific_constant imports.%Core.import_ref.72c, @ControlFlow(constants.%i32, constants.%empty_tuple.type) [concrete = constants.%ControlFlow.Break.a23]
// CHECK:STDOUT:   %Break.ref: %ControlFlow.Break.type.907 = name_ref Break, %.loc7_35 [concrete = constants.%ControlFlow.Break.a23]
// CHECK:STDOUT:   %.loc7_43.1: %empty_tuple.type = tuple_literal () [concrete = constants.%empty_tuple]
// CHECK:STDOUT:   %ControlFlow.Break.specific_fn: <specific function> = specific_function %Break.ref, @ControlFlow.Break(constants.%i32, constants.%empty_tuple.type) [concrete = constants.%ControlFlow.Break.specific_fn]
// CHECK:STDOUT:   %.loc6_43.1: ref %ControlFlow.59f = splice_block %return.param {}
// CHECK:STDOUT:   %empty_tuple: %empty_tuple.type = tuple_value () [concrete = constants.%empty_tuple]
// CHECK:STDOUT:   %.loc7_43.2: %empty_tuple.type = converted %.loc7_43.1, %empty_tuple [concrete = constants.%empty_tuple]
// CHECK:STDOUT:   %ControlFlow.Break.call: init %ControlFlow.59f to %.loc6_43.1 = call %ControlFlow.Break.specific_fn(%.loc7_43.2)
// CHECK:STDOUT:   return %ControlFlow.Break.call to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @MakeContinue(%n.param: %i32) -> out %return.param: %ControlFlow.59f {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Core.ref.loc11: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:   %ControlFlow.ref.loc11: %ControlFlow.type = name_ref ControlFlow, imports.%Core.ControlFlow [concrete = constants.%ControlFlow.generic]
// CHECK:STDOUT:   %i32.loc11: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %.loc11_33: %empty_tuple.type = tuple_literal () [concrete = constants.%empty_tuple]
// CHECK:STDOUT:   %.loc11_34: type = converted %.loc11_33, constants.%empty_tuple.type [concrete = constants.%empty_tuple.type]
// CHECK:STDOUT:   %ControlFlow.loc11: type = class_type @ControlFlow, @ControlFlow(constants.%i32, constants.%empty_tuple.type) [concrete = constants.%ControlFlow.59f]
// CHECK:STDOUT:   %.loc11_35: %ControlFlow.Continue.type.886 = specific_constant imports.%Core.import_ref.903, @ControlFlow(constants.%i32, constants.%empty_tuple.type) [concrete = constants.%ControlFlow.Continue.441]
// CHECK:STDOUT:   %Continue.ref: %ControlFlow.Continue.type.886 = name_ref Continue, %.loc11_35 [concrete = constants.%ControlFlow.Continue.441]
// CHECK:STDOUT:   %n.ref: %i32 = name_ref n, %n
// CHECK:STDOUT:   %ControlFlow.Continue.specific_fn: <specific function> = specific_function %Continue.ref, @ControlFlow.Continue(constants.%i32, constants.%empty_tuple.type) [concrete = constants.%ControlFlow.Continue.specific_fn]
// CHECK:STDOUT:   %.loc10_52.1: ref %ControlFlow.59f = splice_block %return.param {}
// CHECK:STDOUT:   %ControlFlow.Continue.call: init %ControlFlow.59f to %.loc10_52.1 = call %ControlFlow.Continue.specific_fn(%n.ref)
// CHECK:STDOUT:   return %ControlFlow.Continue.call to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Classify(%c.param: %ControlFlow.59f) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %c.ref: %ControlFlow.59f = name_ref c, %c
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %v.patt: %pattern_type.6b6 = value_binding_pattern v [concrete = constants.%v.patt]
// CHECK:STDOUT:     %.loc16_21: %pattern_type.e71 = tuple_pattern (%v.patt) [concrete = constants.%.13b]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc16_28.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc16_28.1: <bound method> = bound_method %int_0, %impl.elem0.loc16_28.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:   %specific_fn.loc16_28.1: <specific function> = specific_function %impl.elem0.loc16_28.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc16_28.2: <bound method> = bound_method %int_0, %specific_fn.loc16_28.1 [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16: init %u1 = call %bound_method.loc16_28.2(%int_0) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc16_28.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc16_28.2: %u1 = converted %int_0, %.loc16_28.1 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc16_28.3: ref %u1 = class_element_access %c.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc16_28.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc16_28.3: <bound method> = bound_method %.loc16_28.2, %impl.elem0.loc16_28.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.f34]
// CHECK:STDOUT:   %specific_fn.loc16_28.2: <specific function> = specific_function %impl.elem0.loc16_28.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc16_28.4: <bound method> = bound_method %.loc16_28.2, %specific_fn.loc16_28.2 [concrete = constants.%bound_method.53a]
// CHECK:STDOUT:   %.loc16_28.4: %u1 = acquire_value %.loc16_28.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc16: init bool = call %bound_method.loc16_28.4(%.loc16_28.2, %.loc16_28.4)
// CHECK:STDOUT:   %.loc16_28.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc16
// CHECK:STDOUT:   %.loc16_28.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc16, %.loc16_28.5
// CHECK:STDOUT:   if %.loc16_28.6 br !match.case.then.loc16 else br !match.case.else.loc16
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc16:
// CHECK:STDOUT:   %.loc16_28.7: ref %.96b = class_element_access %c.ref, element1
// CHECK:STDOUT:   %.loc16_28.8: ref %tuple.type.a8a = class_element_access %.loc16_28.7, element0
// CHECK:STDOUT:   %tuple.elem0.loc16: ref %i32 = tuple_access %.loc16_28.8, element0
// CHECK:STDOUT:   %.loc16_28.9: %i32 = acquire_value %tuple.elem0.loc16
// CHECK:STDOUT:   %i32.loc16: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %v: %i32 = wrapper_binding v, %.loc16_28.9
// CHECK:STDOUT:   %v.ref: %i32 = name_ref v, %v
// CHECK:STDOUT:   %impl.elem0.loc16_40: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc16_40.1: <bound method> = bound_method %v.ref, %impl.elem0.loc16_40
// CHECK:STDOUT:   %specific_fn.loc16_40: <specific function> = specific_function %impl.elem0.loc16_40, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc16_40.2: <bound method> = bound_method %v.ref, %specific_fn.loc16_40
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc16_40.2(%v.ref)
// CHECK:STDOUT:   return %Int.as.Copy.impl.Op.call
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc16:
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %b.patt: %pattern_type.cb1 = value_binding_pattern b [concrete = constants.%b.patt]
// CHECK:STDOUT:     %.loc17_18: %pattern_type.559 = tuple_pattern (%b.patt) [concrete = constants.%.c3c]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_1.loc17: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc17_24.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc17_24.1: <bound method> = bound_method %int_1.loc17, %impl.elem0.loc17_24.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc17_24.1: <specific function> = specific_function %impl.elem0.loc17_24.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc17_24.2: <bound method> = bound_method %int_1.loc17, %specific_fn.loc17_24.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc17: init %u1 = call %bound_method.loc17_24.2(%int_1.loc17) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc17_24.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc17 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc17_24.2: %u1 = converted %int_1.loc17, %.loc17_24.1 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc17_24.3: ref %u1 = class_element_access %c.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc17_24.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc17_24.3: <bound method> = bound_method %.loc17_24.2, %impl.elem0.loc17_24.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.22c]
// CHECK:STDOUT:   %specific_fn.loc17_24.2: <specific function> = specific_function %impl.elem0.loc17_24.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc17_24.4: <bound method> = bound_method %.loc17_24.2, %specific_fn.loc17_24.2 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc17_24.4: %u1 = acquire_value %.loc17_24.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc17: init bool = call %bound_method.loc17_24.4(%.loc17_24.2, %.loc17_24.4)
// CHECK:STDOUT:   %.loc17_24.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc17
// CHECK:STDOUT:   %.loc17_24.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc17, %.loc17_24.5
// CHECK:STDOUT:   if %.loc17_24.6 br !match.case.then.loc17 else br !match.case.else.loc17
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc17:
// CHECK:STDOUT:   %.loc17_24.7: ref %.96b = class_element_access %c.ref, element1
// CHECK:STDOUT:   %.loc17_24.8: ref %tuple.type.9fb = class_element_access %.loc17_24.7, element1
// CHECK:STDOUT:   %tuple.elem0.loc17: ref %empty_tuple.type = tuple_access %.loc17_24.8, element0
// CHECK:STDOUT:   %tuple: %empty_tuple.type = tuple_value () [concrete = constants.%empty_tuple]
// CHECK:STDOUT:   %.loc17_24.9: %empty_tuple.type = converted %tuple.elem0.loc17, %tuple [concrete = constants.%empty_tuple]
// CHECK:STDOUT:   %.loc17_21.1: type = splice_block %.loc17_21.3 [concrete = constants.%empty_tuple.type] {
// CHECK:STDOUT:     %.loc17_21.2: %empty_tuple.type = tuple_literal () [concrete = constants.%empty_tuple]
// CHECK:STDOUT:     %.loc17_21.3: type = converted %.loc17_21.2, constants.%empty_tuple.type [concrete = constants.%empty_tuple.type]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %b: %empty_tuple.type = wrapper_binding b, %.loc17_24.9
// CHECK:STDOUT:   %Sink.ref: %Sink.type = name_ref Sink, file.%Sink.decl [concrete = constants.%Sink]
// CHECK:STDOUT:   %b.ref: %empty_tuple.type = name_ref b, %b
// CHECK:STDOUT:   %Sink.call: init %empty_tuple.type = call %Sink.ref(%b.ref)
// CHECK:STDOUT:   %int_1.loc19: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem1.loc19: %.758 = impl_witness_access constants.%Negate.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %bound_method.loc19_14: <bound method> = bound_method %int_1.loc19, %impl.elem1.loc19 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op.bound.6a0]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.call.loc19: init Core.IntLiteral = call %bound_method.loc19_14(%int_1.loc19) [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %impl.elem0.loc19: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc19_16.1: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call.loc19, %impl.elem0.loc19 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.65e]
// CHECK:STDOUT:   %specific_fn.loc19: <specific function> = specific_function %impl.elem0.loc19, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc19_16.2: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call.loc19, %specific_fn.loc19 [concrete = constants.%bound_method.a65]
// CHECK:STDOUT:   %.loc19_14.1: Core.IntLiteral = value_of_initializer %Core.IntLiteral.as.Negate.impl.Op.call.loc19 [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %.loc19_14.2: Core.IntLiteral = converted %Core.IntLiteral.as.Negate.impl.Op.call.loc19, %.loc19_14.1 [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc19: init %i32 = call %bound_method.loc19_16.2(%.loc19_14.2) [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   %.loc19_16: init %i32 = converted %Core.IntLiteral.as.Negate.impl.Op.call.loc19, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc19 [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   return %.loc19_16
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc17:
// CHECK:STDOUT:   br !match.done
// CHECK:STDOUT:
// CHECK:STDOUT: !match.done:
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2]
// CHECK:STDOUT:   %impl.elem1.loc24: %.758 = impl_witness_access constants.%Negate.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %bound_method.loc24_10: <bound method> = bound_method %int_2, %impl.elem1.loc24 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op.bound.e21]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.call.loc24: init Core.IntLiteral = call %bound_method.loc24_10(%int_2) [concrete = constants.%int_-2.962]
// CHECK:STDOUT:   %impl.elem0.loc24: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc24_12.1: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call.loc24, %impl.elem0.loc24 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.2a0]
// CHECK:STDOUT:   %specific_fn.loc24: <specific function> = specific_function %impl.elem0.loc24, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc24_12.2: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call.loc24, %specific_fn.loc24 [concrete = constants.%bound_method.33f]
// CHECK:STDOUT:   %.loc24_10.1: Core.IntLiteral = value_of_initializer %Core.IntLiteral.as.Negate.impl.Op.call.loc24 [concrete = constants.%int_-2.962]
// CHECK:STDOUT:   %.loc24_10.2: Core.IntLiteral = converted %Core.IntLiteral.as.Negate.impl.Op.call.loc24, %.loc24_10.1 [concrete = constants.%int_-2.962]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc24: init %i32 = call %bound_method.loc24_12.2(%.loc24_10.2) [concrete = constants.%int_-2.c83]
// CHECK:STDOUT:   %.loc24_12: init %i32 = converted %Core.IntLiteral.as.Negate.impl.Op.call.loc24, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc24 [concrete = constants.%int_-2.c83]
// CHECK:STDOUT:   return %.loc24_12
// CHECK:STDOUT: }
// CHECK:STDOUT:
