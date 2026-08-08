// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/exhaustive_choice.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/exhaustive_choice.carbon
// CHECK:STDERR: {{.*}}/prelude/try.carbon:20:1: error: name `Core.ImplicitAs` implicitly referenced here, but not found [CoreNameNotFound]
// CHECK:STDERR: choice ControlFlow(C: type, B: type) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: {{.*}}/prelude/try.carbon:20:1: error: name `Core.ImplicitAs` implicitly referenced here, but not found [CoreNameNotFound]
// CHECK:STDERR: choice ControlFlow(C: type, B: type) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:

// A choice scrutinee's alternatives are a closed set, so a `match` whose
// unguarded arms cover every alternative needs no `default` arm (SF-7;
// re-platform plan S2e). The last arm's else edge — dynamically dead when
// the arms are exhaustive — branches to the resumption block, the same
// shape an empty `default` arm produces.

// --- payload_free.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
choice Flag {
  Off,
  On
}

// Every payload-free alternative is covered by an unguarded arm, so no
// `default` arm is required.
fn Classify(f: Flag) -> i32 {
  match (f) {
    case .Off => { return 0; }
    case .On => { return 1; }
  }
  return -1;
}
//@dump-sem-ir-end

// --- payload.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
choice IntResult {
  Ok(value: i32),
  Err
}

// The docs/design/sum_types.md `match` example's shape (with a concrete
// choice; generic choices are out of slice): a payload-destructuring arm
// and a constant arm cover both alternatives, so no `default` is required.
fn Consume(r: IntResult) -> i32 {
  match (r) {
    case .Ok(value: i32) => { return value; }
    case .Err => { return -1; }
  }
  return -2;
}
//@dump-sem-ir-end

// --- guarded_duplicate.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
choice IntResult {
  Ok(value: i32),
  Err
}

// A guarded arm never counts toward coverage, but the same alternative
// covered again by an unguarded arm does: `.Ok` values split on the guard,
// and the match is still exhaustive without a `default` arm.
fn Consume(r: IntResult) -> i32 {
  match (r) {
    case .Ok(v: i32) if (v > 0) => { return v; }
    case .Ok(w: i32) => { return w - 1; }
    case .Err => { return -10; }
  }
  return -20;
}
//@dump-sem-ir-end

// --- with_default.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
choice Flag {
  Off,
  On
}

// A `default` arm on an exhaustive match stays accepted; it can never be
// taken. Diagnosing it as useless is future work (see
// docs/design/pattern_matching.md on usefulness).
fn Classify(f: Flag) -> i32 {
  match (f) {
    case .Off => { return 0; }
    case .On => { return 1; }
    default => { return -1; }
  }
  return -2;
}
//@dump-sem-ir-end

// --- signal.carbon
library "signal";

choice Signal {
  Go(speed: i32),
  Stop,
  Wait
}

// --- use_imported.carbon
library "use_imported";

import library "signal";

//@dump-sem-ir-begin
// Matching over a choice declared in another library: the alternative table
// (the S2c `SemIR::ChoiceAlternative` metadata on the class) arrives through
// import, so covering every alternative discharges the `default` requirement
// exactly as for a same-file choice.
fn Classify(s: Signal) -> i32 {
  match (s) {
    case .Go(speed: i32) => { return speed; }
    case .Stop => { return 0; }
    case .Wait => { return 1; }
  }
  return -1;
}
//@dump-sem-ir-end

// CHECK:STDOUT: --- payload_free.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %Flag: type = class_type @Flag [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %u1: type = class_type @UInt, @UInt(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %struct_type.discriminant: type = struct_type {.discriminant: %u1} [concrete]
// CHECK:STDOUT:   %complete_type.3a6: <witness> = complete_type_witness %struct_type.discriminant [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.ca1: type = facet_type <@ImplicitAs, @ImplicitAs(%u1)> [concrete]
// CHECK:STDOUT:   %To.fe9: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.170: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.9a9: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.42f, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.115: %ImplicitAs.type.ca1 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.9a9) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.19e: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%u1, %ImplicitAs.facet.115) [concrete]
// CHECK:STDOUT:   %.e60: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.19e, %ImplicitAs.facet.115 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.0e8: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
// CHECK:STDOUT:   %int_0.1a7: %u1 = int_value 0 [concrete]
// CHECK:STDOUT:   %struct.249: %struct_type.discriminant = struct_value (%int_0.1a7) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.type.0c5: type = fn_type @UInt.as.Copy.impl.Op, @UInt.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.38a: %UInt.as.Copy.impl.Op.type.0c5 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.fb7: <witness> = impl_witness imports.%Copy.impl_witness_table.fe3, @UInt.as.Copy.impl(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.type.c97: type = fn_type @UInt.as.Copy.impl.Op, @UInt.as.Copy.impl(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.d9c: %UInt.as.Copy.impl.Op.type.c97 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet: %Copy.type = facet_value %u1, (%Copy.impl_witness.fb7) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.4d4: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet) [concrete]
// CHECK:STDOUT:   %.37a: type = fn_type_with_self_type %Copy.WithSelf.Op.type.4d4, %Copy.facet [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.bound.bd0: <bound method> = bound_method %int_0.1a7, %UInt.as.Copy.impl.Op.d9c [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %UInt.as.Copy.impl.Op.d9c, @UInt.as.Copy.impl.Op(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.61c: <bound method> = bound_method %int_0.1a7, %UInt.as.Copy.impl.Op.specific_fn [concrete]
// CHECK:STDOUT:   %Flag.val.246: %Flag = struct_value (%int_0.1a7) [concrete]
// CHECK:STDOUT:   %.a8b: ref %Flag = temporary invalid, %Flag.val.246 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %bound_method.d7a: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
// CHECK:STDOUT:   %int_1.233: %u1 = int_value 1 [concrete]
// CHECK:STDOUT:   %struct.a79: %struct_type.discriminant = struct_value (%int_1.233) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.bound.332: <bound method> = bound_method %int_1.233, %UInt.as.Copy.impl.Op.d9c [concrete]
// CHECK:STDOUT:   %bound_method.edd: <bound method> = bound_method %int_1.233, %UInt.as.Copy.impl.Op.specific_fn [concrete]
// CHECK:STDOUT:   %Flag.val.cba: %Flag = struct_value (%int_1.233) [concrete]
// CHECK:STDOUT:   %.c9b: ref %Flag = temporary invalid, %Flag.val.cba [concrete]
// CHECK:STDOUT:   %pattern_type.5bc: type = pattern_type %Flag [concrete]
// CHECK:STDOUT:   %f.param_patt: %pattern_type.5bc = value_param_pattern [concrete]
// CHECK:STDOUT:   %f.patt: %pattern_type.5bc = at_binding_pattern f, %f.param_patt [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %Classify.type: type = fn_type @Classify [concrete]
// CHECK:STDOUT:   %Classify: %Classify.type = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.type.c25: type = facet_type <@EqWith, @EqWith(%u1)> [concrete]
// CHECK:STDOUT:   %M: Core.IntLiteral = symbolic_binding M, 1 [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.544: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%N, %M) [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.c67: %UInt.as.EqWith.impl.Equal.type.544 = struct_value () [symbolic]
// CHECK:STDOUT:   %EqWith.impl_witness.d63: <witness> = impl_witness imports.%EqWith.impl_witness_table.cbd, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.29b: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.ba4: %UInt.as.EqWith.impl.Equal.type.29b = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.3b6: %EqWith.type.c25 = facet_value %u1, (%EqWith.impl_witness.d63) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.922: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%u1, %EqWith.facet.3b6) [concrete]
// CHECK:STDOUT:   %.9ed: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.922, %EqWith.facet.3b6 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound.f34: <bound method> = bound_method %int_0.1a7, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.specific_fn.6b6: <specific function> = specific_function %UInt.as.EqWith.impl.Equal.ba4, @UInt.as.EqWith.impl.Equal.1(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.53a: <bound method> = bound_method %int_0.1a7, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a23: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.b3c, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.9f1: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a23) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.740: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet.9f1) [concrete]
// CHECK:STDOUT:   %.1c5: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.740, %ImplicitAs.facet.9f1 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.6e0: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_0.3c0: %i32 = int_value 0 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound.22c: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %bound_method.a82: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.953: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT:   %Negate.type: type = facet_type <@Negate> [concrete]
// CHECK:STDOUT:   %Negate.impl_witness: <witness> = impl_witness imports.%Negate.impl_witness_table [concrete]
// CHECK:STDOUT:   %Negate.facet: %Negate.type = facet_value Core.IntLiteral, (%Negate.impl_witness) [concrete]
// CHECK:STDOUT:   %Negate.WithSelf.Op.type.db1: type = fn_type @Negate.WithSelf.Op, @Negate.WithSelf(%Negate.facet) [concrete]
// CHECK:STDOUT:   %.e9b: type = fn_type_with_self_type %Negate.WithSelf.Op.type.db1, %Negate.facet [concrete]
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
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.42f = impl_witness_table (%Core.import_ref.aa5), @Core.IntLiteral.as.ImplicitAs.impl.b68 [concrete]
// CHECK:STDOUT:   %Core.import_ref.791: @UInt.as.Copy.impl.%UInt.as.Copy.impl.Op.type (%UInt.as.Copy.impl.Op.type.0c5) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.Copy.impl.%UInt.as.Copy.impl.Op (constants.%UInt.as.Copy.impl.Op.38a)]
// CHECK:STDOUT:   %Copy.impl_witness_table.fe3 = impl_witness_table (%Core.import_ref.791), @UInt.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.b92: @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal.type (%UInt.as.EqWith.impl.Equal.type.544) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal (constants.%UInt.as.EqWith.impl.Equal.c67)]
// CHECK:STDOUT:   %Core.import_ref.b44 = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.cbd = impl_witness_table (%Core.import_ref.b92, %Core.import_ref.b44), @UInt.as.EqWith.impl.f13 [concrete]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.b3c = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.abd = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9c3: %Core.IntLiteral.as.Negate.impl.Op.type = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, loaded [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %Negate.impl_witness_table = impl_witness_table (%Core.import_ref.abd, %Core.import_ref.9c3), @Core.IntLiteral.as.Negate.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Flag.decl: type = class_decl @Flag [concrete = constants.%Flag] {} {}
// CHECK:STDOUT:   %Classify.decl: %Classify.type = fn_decl @Classify [concrete = constants.%Classify] {
// CHECK:STDOUT:     %f.param_patt: %pattern_type.5bc = value_param_pattern [concrete = constants.%f.param_patt]
// CHECK:STDOUT:     %f.patt: %pattern_type.5bc = at_binding_pattern f, %f.param_patt [concrete = constants.%f.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc11: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %f.param: %Flag = value_param call_param0
// CHECK:STDOUT:     %Flag.ref: type = name_ref Flag, file.%Flag.decl [concrete = constants.%Flag]
// CHECK:STDOUT:     %f: %Flag = wrapper_binding f, %f.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: class @Flag {
// CHECK:STDOUT:   %complete_type: <witness> = complete_type_witness constants.%struct_type.discriminant [concrete = constants.%complete_type.3a6]
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc5_6.1: %.e60 = impl_witness_access constants.%ImplicitAs.impl_witness.9a9, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc5_6.1: <bound method> = bound_method %int_0, %impl.elem0.loc5_6.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:   %specific_fn.loc5_6.1: <specific function> = specific_function %impl.elem0.loc5_6.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc5_6.2: <bound method> = bound_method %int_0, %specific_fn.loc5_6.1 [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc5: init %u1 = call %bound_method.loc5_6.2(%int_0) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc5_6.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc5 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc5_6.2: %u1 = converted %int_0, %.loc5_6.1 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc5_6.3: %struct_type.discriminant = struct_literal (%.loc5_6.2) [concrete = constants.%struct.249]
// CHECK:STDOUT:   %impl.elem0.loc5_6.2: %.37a = impl_witness_access constants.%Copy.impl_witness.fb7, element0 [concrete = constants.%UInt.as.Copy.impl.Op.d9c]
// CHECK:STDOUT:   %bound_method.loc5_6.3: <bound method> = bound_method %.loc5_6.2, %impl.elem0.loc5_6.2 [concrete = constants.%UInt.as.Copy.impl.Op.bound.bd0]
// CHECK:STDOUT:   %specific_fn.loc5_6.2: <specific function> = specific_function %impl.elem0.loc5_6.2, @UInt.as.Copy.impl.Op(constants.%int_1.5b8) [concrete = constants.%UInt.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc5_6.4: <bound method> = bound_method %.loc5_6.2, %specific_fn.loc5_6.2 [concrete = constants.%bound_method.61c]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.call.loc5: init %u1 = call %bound_method.loc5_6.4(%.loc5_6.2) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc5_6.4: ref %Flag = temporary_storage
// CHECK:STDOUT:   %.loc5_6.5: ref %u1 = class_element_access %.loc5_6.4, element0
// CHECK:STDOUT:   %.loc5_6.6: init %u1 to %.loc5_6.5 = in_place_init %UInt.as.Copy.impl.Op.call.loc5 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc5_6.7: init %Flag to %.loc5_6.4 = class_init (%.loc5_6.6) [concrete = constants.%Flag.val.246]
// CHECK:STDOUT:   %.loc5_6.8: init %Flag = converted %.loc5_6.3, %.loc5_6.7 [concrete = constants.%Flag.val.246]
// CHECK:STDOUT:   %.loc5_6.9: ref %Flag = temporary %.loc5_6.4, %.loc5_6.8 [concrete = constants.%.a8b]
// CHECK:STDOUT:   %.loc5_6.10: %Flag = acquire_value %.loc5_6.9 [concrete = constants.%Flag.val.246]
// CHECK:STDOUT:   %Off: %Flag = wrapper_binding Off, %.loc5_6.10
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc7_1.1: %.e60 = impl_witness_access constants.%ImplicitAs.impl_witness.9a9, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc7_1.1: <bound method> = bound_method %int_1, %impl.elem0.loc7_1.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc7_1.1: <specific function> = specific_function %impl.elem0.loc7_1.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc7_1.2: <bound method> = bound_method %int_1, %specific_fn.loc7_1.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc7: init %u1 = call %bound_method.loc7_1.2(%int_1) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc7_1.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc7 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc7_1.2: %u1 = converted %int_1, %.loc7_1.1 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc7_1.3: %struct_type.discriminant = struct_literal (%.loc7_1.2) [concrete = constants.%struct.a79]
// CHECK:STDOUT:   %impl.elem0.loc7_1.2: %.37a = impl_witness_access constants.%Copy.impl_witness.fb7, element0 [concrete = constants.%UInt.as.Copy.impl.Op.d9c]
// CHECK:STDOUT:   %bound_method.loc7_1.3: <bound method> = bound_method %.loc7_1.2, %impl.elem0.loc7_1.2 [concrete = constants.%UInt.as.Copy.impl.Op.bound.332]
// CHECK:STDOUT:   %specific_fn.loc7_1.2: <specific function> = specific_function %impl.elem0.loc7_1.2, @UInt.as.Copy.impl.Op(constants.%int_1.5b8) [concrete = constants.%UInt.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc7_1.4: <bound method> = bound_method %.loc7_1.2, %specific_fn.loc7_1.2 [concrete = constants.%bound_method.edd]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.call.loc7: init %u1 = call %bound_method.loc7_1.4(%.loc7_1.2) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc7_1.4: ref %Flag = temporary_storage
// CHECK:STDOUT:   %.loc7_1.5: ref %u1 = class_element_access %.loc7_1.4, element0
// CHECK:STDOUT:   %.loc7_1.6: init %u1 to %.loc7_1.5 = in_place_init %UInt.as.Copy.impl.Op.call.loc7 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc7_1.7: init %Flag to %.loc7_1.4 = class_init (%.loc7_1.6) [concrete = constants.%Flag.val.cba]
// CHECK:STDOUT:   %.loc7_1.8: init %Flag = converted %.loc7_1.3, %.loc7_1.7 [concrete = constants.%Flag.val.cba]
// CHECK:STDOUT:   %.loc7_1.9: ref %Flag = temporary %.loc7_1.4, %.loc7_1.8 [concrete = constants.%.c9b]
// CHECK:STDOUT:   %.loc7_1.10: %Flag = acquire_value %.loc7_1.9 [concrete = constants.%Flag.val.cba]
// CHECK:STDOUT:   %On: %Flag = wrapper_binding On, %.loc7_1.10
// CHECK:STDOUT:   complete_type_witness = %complete_type
// CHECK:STDOUT:
// CHECK:STDOUT: !members:
// CHECK:STDOUT:   .Self = constants.%Flag
// CHECK:STDOUT:   .Off = %Off
// CHECK:STDOUT:   .On = %On
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Classify(%f.param: %Flag) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %f.ref: %Flag = name_ref f, %f
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt.loc13: %pattern_type.5bc = expr_pattern %Off.ref in [concrete] {
// CHECK:STDOUT:       %Off.ref: %Flag = name_ref Off, @Flag.%Off
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Off.ref: %Flag = name_ref Off, @Flag.%Off
// CHECK:STDOUT:   %int_0.loc13_15: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc13_15.1: %.e60 = impl_witness_access constants.%ImplicitAs.impl_witness.9a9, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc13_15.1: <bound method> = bound_method %int_0.loc13_15, %impl.elem0.loc13_15.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:   %specific_fn.loc13_15.1: <specific function> = specific_function %impl.elem0.loc13_15.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc13_15.2: <bound method> = bound_method %int_0.loc13_15, %specific_fn.loc13_15.1 [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13_15: init %u1 = call %bound_method.loc13_15.2(%int_0.loc13_15) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc13_15.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13_15 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc13_15.2: %u1 = converted %int_0.loc13_15, %.loc13_15.1 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc13_15.3: ref %u1 = class_element_access %f.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc13_15.2: %.9ed = impl_witness_access constants.%EqWith.impl_witness.d63, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc13_15.3: <bound method> = bound_method %.loc13_15.2, %impl.elem0.loc13_15.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.f34]
// CHECK:STDOUT:   %specific_fn.loc13_15.2: <specific function> = specific_function %impl.elem0.loc13_15.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc13_15.4: <bound method> = bound_method %.loc13_15.2, %specific_fn.loc13_15.2 [concrete = constants.%bound_method.53a]
// CHECK:STDOUT:   %.loc13_15.4: %u1 = acquire_value %.loc13_15.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc13: init bool = call %bound_method.loc13_15.4(%.loc13_15.2, %.loc13_15.4)
// CHECK:STDOUT:   %.loc13_15.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc13
// CHECK:STDOUT:   %.loc13_15.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc13, %.loc13_15.5
// CHECK:STDOUT:   if %.loc13_15.6 br !match.case.then.loc13 else br !match.case.else.loc13
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc13:
// CHECK:STDOUT:   %int_0.loc13_27: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc13_28: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc13_28.1: <bound method> = bound_method %int_0.loc13_27, %impl.elem0.loc13_28 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc13_28: <specific function> = specific_function %impl.elem0.loc13_28, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc13_28.2: <bound method> = bound_method %int_0.loc13_27, %specific_fn.loc13_28 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13_28: init %i32 = call %bound_method.loc13_28.2(%int_0.loc13_27) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc13_28: init %i32 = converted %int_0.loc13_27, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13_28 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   return %.loc13_28
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc13:
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt.loc14: %pattern_type.5bc = expr_pattern %On.ref in [concrete] {
// CHECK:STDOUT:       %On.ref: %Flag = name_ref On, @Flag.%On
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %On.ref: %Flag = name_ref On, @Flag.%On
// CHECK:STDOUT:   %int_1.loc14_14: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc14_14.1: %.e60 = impl_witness_access constants.%ImplicitAs.impl_witness.9a9, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc14_14.1: <bound method> = bound_method %int_1.loc14_14, %impl.elem0.loc14_14.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc14_14.1: <specific function> = specific_function %impl.elem0.loc14_14.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc14_14.2: <bound method> = bound_method %int_1.loc14_14, %specific_fn.loc14_14.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14_14: init %u1 = call %bound_method.loc14_14.2(%int_1.loc14_14) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc14_14.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14_14 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc14_14.2: %u1 = converted %int_1.loc14_14, %.loc14_14.1 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc14_14.3: ref %u1 = class_element_access %f.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc14_14.2: %.9ed = impl_witness_access constants.%EqWith.impl_witness.d63, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc14_14.3: <bound method> = bound_method %.loc14_14.2, %impl.elem0.loc14_14.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.22c]
// CHECK:STDOUT:   %specific_fn.loc14_14.2: <specific function> = specific_function %impl.elem0.loc14_14.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc14_14.4: <bound method> = bound_method %.loc14_14.2, %specific_fn.loc14_14.2 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc14_14.4: %u1 = acquire_value %.loc14_14.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc14: init bool = call %bound_method.loc14_14.4(%.loc14_14.2, %.loc14_14.4)
// CHECK:STDOUT:   %.loc14_14.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc14
// CHECK:STDOUT:   %.loc14_14.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc14, %.loc14_14.5
// CHECK:STDOUT:   if %.loc14_14.6 br !match.case.then.loc14 else br !match.case.else.loc14
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc14:
// CHECK:STDOUT:   %int_1.loc14_26: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc14_27: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc14_27.1: <bound method> = bound_method %int_1.loc14_26, %impl.elem0.loc14_27 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc14_27: <specific function> = specific_function %impl.elem0.loc14_27, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc14_27.2: <bound method> = bound_method %int_1.loc14_26, %specific_fn.loc14_27 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14_27: init %i32 = call %bound_method.loc14_27.2(%int_1.loc14_26) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc14_27: init %i32 = converted %int_1.loc14_26, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14_27 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   return %.loc14_27
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc14:
// CHECK:STDOUT:   br !match.done
// CHECK:STDOUT:
// CHECK:STDOUT: !match.done:
// CHECK:STDOUT:   %int_1.loc16: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem1: %.e9b = impl_witness_access constants.%Negate.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %bound_method.loc16_10: <bound method> = bound_method %int_1.loc16, %impl.elem1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op.bound]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.call: init Core.IntLiteral = call %bound_method.loc16_10(%int_1.loc16) [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %impl.elem0.loc16: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc16_12.1: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %impl.elem0.loc16 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.65e]
// CHECK:STDOUT:   %specific_fn.loc16: <specific function> = specific_function %impl.elem0.loc16, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc16_12.2: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %specific_fn.loc16 [concrete = constants.%bound_method.a65]
// CHECK:STDOUT:   %.loc16_10.1: Core.IntLiteral = value_of_initializer %Core.IntLiteral.as.Negate.impl.Op.call [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %.loc16_10.2: Core.IntLiteral = converted %Core.IntLiteral.as.Negate.impl.Op.call, %.loc16_10.1 [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16: init %i32 = call %bound_method.loc16_12.2(%.loc16_10.2) [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   %.loc16_12: init %i32 = converted %Core.IntLiteral.as.Negate.impl.Op.call, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16 [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   return %.loc16_12
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- payload.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %IntResult: type = class_type @IntResult [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %u1: type = class_type @UInt, @UInt(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %tuple.type.a8a: type = tuple_type (%i32) [concrete]
// CHECK:STDOUT:   %.2a5: type = custom_layout_type {size=4, align=4, .Ok@0: %tuple.type.a8a} [concrete]
// CHECK:STDOUT:   %struct_type.discriminant.payload.898: type = struct_type {.discriminant: %u1, .payload: %.2a5} [concrete]
// CHECK:STDOUT:   %complete_type.697: <witness> = complete_type_witness %struct_type.discriminant.payload.898 [concrete]
// CHECK:STDOUT:   %struct_type.discriminant: type = struct_type {.discriminant: %u1} [concrete]
// CHECK:STDOUT:   %_.param_patt: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %_.patt: %pattern_type.6b6 = at_binding_pattern _, %_.param_patt [concrete]
// CHECK:STDOUT:   %.918: Core.Form = init_form %IntResult [concrete]
// CHECK:STDOUT:   %pattern_type.e14: type = pattern_type %IntResult [concrete]
// CHECK:STDOUT:   %return.param_patt.3e8: %pattern_type.e14 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.437: %pattern_type.e14 = return_slot_pattern %return.param_patt.3e8, %IntResult [concrete]
// CHECK:STDOUT:   %IntResult.Ok.type: type = fn_type @IntResult.Ok [concrete]
// CHECK:STDOUT:   %IntResult.Ok: %IntResult.Ok.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.ca1: type = facet_type <@ImplicitAs, @ImplicitAs(%u1)> [concrete]
// CHECK:STDOUT:   %To.fe9: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.170: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.9a9: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.42f, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.115: %ImplicitAs.type.ca1 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.9a9) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.19e: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%u1, %ImplicitAs.facet.115) [concrete]
// CHECK:STDOUT:   %.e60: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.19e, %ImplicitAs.facet.115 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.0e8: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
// CHECK:STDOUT:   %int_0.1a7: %u1 = int_value 0 [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.0e0: <witness> = impl_witness imports.%Copy.impl_witness_table.367, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet.987: %Copy.type = facet_value %i32, (%Copy.impl_witness.0e0) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.d09: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.987) [concrete]
// CHECK:STDOUT:   %.7a6: type = fn_type_with_self_type %Copy.WithSelf.Op.type.d09, %Copy.facet.987 [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %bound_method.d7a: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
// CHECK:STDOUT:   %int_1.233: %u1 = int_value 1 [concrete]
// CHECK:STDOUT:   %struct: %struct_type.discriminant = struct_value (%int_1.233) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.type.0c5: type = fn_type @UInt.as.Copy.impl.Op, @UInt.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.38a: %UInt.as.Copy.impl.Op.type.0c5 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.fb7: <witness> = impl_witness imports.%Copy.impl_witness_table.fe3, @UInt.as.Copy.impl(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.type.c97: type = fn_type @UInt.as.Copy.impl.Op, @UInt.as.Copy.impl(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.d9c: %UInt.as.Copy.impl.Op.type.c97 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet.771: %Copy.type = facet_value %u1, (%Copy.impl_witness.fb7) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.4d4: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.771) [concrete]
// CHECK:STDOUT:   %.37a: type = fn_type_with_self_type %Copy.WithSelf.Op.type.4d4, %Copy.facet.771 [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.bound: <bound method> = bound_method %int_1.233, %UInt.as.Copy.impl.Op.d9c [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %UInt.as.Copy.impl.Op.d9c, @UInt.as.Copy.impl.Op(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.edd: <bound method> = bound_method %int_1.233, %UInt.as.Copy.impl.Op.specific_fn [concrete]
// CHECK:STDOUT:   %uninit: %.2a5 = uninitialized_value [concrete]
// CHECK:STDOUT:   %IntResult.val: %IntResult = struct_value (%int_1.233, %uninit) [concrete]
// CHECK:STDOUT:   %.942: ref %IntResult = temporary invalid, %IntResult.val [concrete]
// CHECK:STDOUT:   %r.param_patt: %pattern_type.e14 = value_param_pattern [concrete]
// CHECK:STDOUT:   %r.patt: %pattern_type.e14 = at_binding_pattern r, %r.param_patt [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %Consume.type: type = fn_type @Consume [concrete]
// CHECK:STDOUT:   %Consume: %Consume.type = struct_value () [concrete]
// CHECK:STDOUT:   %value.patt.d86: %pattern_type.6b6 = value_binding_pattern value [concrete]
// CHECK:STDOUT:   %pattern_type.e71: type = pattern_type %tuple.type.a8a [concrete]
// CHECK:STDOUT:   %.af8: %pattern_type.e71 = tuple_pattern (%value.patt.d86) [concrete]
// CHECK:STDOUT:   %EqWith.type.c25: type = facet_type <@EqWith, @EqWith(%u1)> [concrete]
// CHECK:STDOUT:   %M: Core.IntLiteral = symbolic_binding M, 1 [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.544: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%N, %M) [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.c67: %UInt.as.EqWith.impl.Equal.type.544 = struct_value () [symbolic]
// CHECK:STDOUT:   %EqWith.impl_witness.d63: <witness> = impl_witness imports.%EqWith.impl_witness_table.cbd, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.29b: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.ba4: %UInt.as.EqWith.impl.Equal.type.29b = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.3b6: %EqWith.type.c25 = facet_value %u1, (%EqWith.impl_witness.d63) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.922: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%u1, %EqWith.facet.3b6) [concrete]
// CHECK:STDOUT:   %.9ed: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.922, %EqWith.facet.3b6 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound.f34: <bound method> = bound_method %int_0.1a7, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.specific_fn.6b6: <specific function> = specific_function %UInt.as.EqWith.impl.Equal.ba4, @UInt.as.EqWith.impl.Equal.1(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.53a: <bound method> = bound_method %int_0.1a7, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound.22c: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %bound_method.a82: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
// CHECK:STDOUT:   %Negate.type: type = facet_type <@Negate> [concrete]
// CHECK:STDOUT:   %Negate.impl_witness: <witness> = impl_witness imports.%Negate.impl_witness_table [concrete]
// CHECK:STDOUT:   %Negate.facet: %Negate.type = facet_value Core.IntLiteral, (%Negate.impl_witness) [concrete]
// CHECK:STDOUT:   %Negate.WithSelf.Op.type.db1: type = fn_type @Negate.WithSelf.Op, @Negate.WithSelf(%Negate.facet) [concrete]
// CHECK:STDOUT:   %.e9b: type = fn_type_with_self_type %Negate.WithSelf.Op.type.db1, %Negate.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.type: type = fn_type @Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op: %Core.IntLiteral.as.Negate.impl.Op.type = struct_value () [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.bound.6a0: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %int_-1.638: Core.IntLiteral = int_value -1 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a23: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.b3c, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.9f1: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a23) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.740: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet.9f1) [concrete]
// CHECK:STDOUT:   %.1c5: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.740, %ImplicitAs.facet.9f1 [concrete]
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
// CHECK:STDOUT:   %Core.import_ref.aa5: @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.170)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.42f = impl_witness_table (%Core.import_ref.aa5), @Core.IntLiteral.as.ImplicitAs.impl.b68 [concrete]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.367 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.791: @UInt.as.Copy.impl.%UInt.as.Copy.impl.Op.type (%UInt.as.Copy.impl.Op.type.0c5) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.Copy.impl.%UInt.as.Copy.impl.Op (constants.%UInt.as.Copy.impl.Op.38a)]
// CHECK:STDOUT:   %Copy.impl_witness_table.fe3 = impl_witness_table (%Core.import_ref.791), @UInt.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.b92: @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal.type (%UInt.as.EqWith.impl.Equal.type.544) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal (constants.%UInt.as.EqWith.impl.Equal.c67)]
// CHECK:STDOUT:   %Core.import_ref.b44 = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.cbd = impl_witness_table (%Core.import_ref.b92, %Core.import_ref.b44), @UInt.as.EqWith.impl.f13 [concrete]
// CHECK:STDOUT:   %Core.import_ref.abd = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9c3: %Core.IntLiteral.as.Negate.impl.Op.type = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, loaded [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %Negate.impl_witness_table = impl_witness_table (%Core.import_ref.abd, %Core.import_ref.9c3), @Core.IntLiteral.as.Negate.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.b3c = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %IntResult.Ok.decl: %IntResult.Ok.type = fn_decl @IntResult.Ok [concrete = constants.%IntResult.Ok] {
// CHECK:STDOUT:     %_.param_patt: %pattern_type.6b6 = value_param_pattern [concrete = constants.%_.param_patt]
// CHECK:STDOUT:     %_.patt: %pattern_type.6b6 = at_binding_pattern _, %_.param_patt [concrete = constants.%_.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.e14 = out_param_pattern [concrete = constants.%return.param_patt.3e8]
// CHECK:STDOUT:     %return.patt: %pattern_type.e14 = return_slot_pattern %return.param_patt, constants.%IntResult [concrete = constants.%return.patt.437]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc4_18.9: Core.Form = init_form constants.%IntResult [concrete = constants.%.918]
// CHECK:STDOUT:     %_.param: %i32 = value_param call_param0
// CHECK:STDOUT:     %_: %i32 = wrapper_binding _, %_.param
// CHECK:STDOUT:     %return.param: ref %IntResult = out_param call_param1
// CHECK:STDOUT:     %return: ref %IntResult = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %IntResult.decl: type = class_decl @IntResult [concrete = constants.%IntResult] {} {}
// CHECK:STDOUT:   %Consume.decl: %Consume.type = fn_decl @Consume [concrete = constants.%Consume] {
// CHECK:STDOUT:     %r.param_patt: %pattern_type.e14 = value_param_pattern [concrete = constants.%r.param_patt]
// CHECK:STDOUT:     %r.patt: %pattern_type.e14 = at_binding_pattern r, %r.param_patt [concrete = constants.%r.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc12 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc12: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc12: Core.Form = init_form %i32.loc12 [concrete = constants.%.795f]
// CHECK:STDOUT:     %r.param: %IntResult = value_param call_param0
// CHECK:STDOUT:     %IntResult.ref: type = name_ref IntResult, file.%IntResult.decl [concrete = constants.%IntResult]
// CHECK:STDOUT:     %r: %IntResult = wrapper_binding r, %r.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: class @IntResult {
// CHECK:STDOUT:   %value.param: %i32 = value_param call_param0
// CHECK:STDOUT:   %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %value: %i32 = wrapper_binding value, %value.param
// CHECK:STDOUT:   %.loc7_1.1: type = custom_layout_type {size=4, align=4, .Ok@0: %tuple.type.a8a} [concrete = constants.%.2a5]
// CHECK:STDOUT:   %complete_type: <witness> = complete_type_witness constants.%struct_type.discriminant.payload.898 [concrete = constants.%complete_type.697]
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc7_1.1: %.e60 = impl_witness_access constants.%ImplicitAs.impl_witness.9a9, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc7_1.1: <bound method> = bound_method %int_1, %impl.elem0.loc7_1.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc7_1.1: <specific function> = specific_function %impl.elem0.loc7_1.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc7_1.2: <bound method> = bound_method %int_1, %specific_fn.loc7_1.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %u1 = call %bound_method.loc7_1.2(%int_1) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc7_1.2: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc7_1.3: %u1 = converted %int_1, %.loc7_1.2 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc7_1.4: %struct_type.discriminant = struct_literal (%.loc7_1.3) [concrete = constants.%struct]
// CHECK:STDOUT:   %impl.elem0.loc7_1.2: %.37a = impl_witness_access constants.%Copy.impl_witness.fb7, element0 [concrete = constants.%UInt.as.Copy.impl.Op.d9c]
// CHECK:STDOUT:   %bound_method.loc7_1.3: <bound method> = bound_method %.loc7_1.3, %impl.elem0.loc7_1.2 [concrete = constants.%UInt.as.Copy.impl.Op.bound]
// CHECK:STDOUT:   %specific_fn.loc7_1.2: <specific function> = specific_function %impl.elem0.loc7_1.2, @UInt.as.Copy.impl.Op(constants.%int_1.5b8) [concrete = constants.%UInt.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc7_1.4: <bound method> = bound_method %.loc7_1.3, %specific_fn.loc7_1.2 [concrete = constants.%bound_method.edd]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.call: init %u1 = call %bound_method.loc7_1.4(%.loc7_1.3) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc7_1.5: ref %IntResult = temporary_storage
// CHECK:STDOUT:   %.loc7_1.6: ref %u1 = class_element_access %.loc7_1.5, element0
// CHECK:STDOUT:   %.loc7_1.7: init %u1 to %.loc7_1.6 = in_place_init %UInt.as.Copy.impl.Op.call [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc7_1.8: ref %.2a5 = class_element_access %.loc7_1.5, element1
// CHECK:STDOUT:   %uninit: %.2a5 = uninitialized_value [concrete = constants.%uninit]
// CHECK:STDOUT:   %.loc7_1.9: init %.2a5 to %.loc7_1.8 = in_place_init %uninit [concrete = constants.%uninit]
// CHECK:STDOUT:   %.loc7_1.10: init %IntResult to %.loc7_1.5 = class_init (%.loc7_1.7, %.loc7_1.9) [concrete = constants.%IntResult.val]
// CHECK:STDOUT:   %.loc7_1.11: init %IntResult = converted %.loc7_1.4, %.loc7_1.10 [concrete = constants.%IntResult.val]
// CHECK:STDOUT:   %.loc7_1.12: ref %IntResult = temporary %.loc7_1.5, %.loc7_1.11 [concrete = constants.%.942]
// CHECK:STDOUT:   %.loc7_1.13: %IntResult = acquire_value %.loc7_1.12 [concrete = constants.%IntResult.val]
// CHECK:STDOUT:   %Err: %IntResult = wrapper_binding Err, %.loc7_1.13
// CHECK:STDOUT:   complete_type_witness = %complete_type
// CHECK:STDOUT:
// CHECK:STDOUT: !members:
// CHECK:STDOUT:   .Self = constants.%IntResult
// CHECK:STDOUT:   .Ok = generated.%IntResult.Ok.decl
// CHECK:STDOUT:   .Err = %Err
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @IntResult.Ok(%_.param: %i32) -> out %return.param: %IntResult {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %.loc4_18.1: ref %u1 = class_element_access %return.param, element0
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc4_18.1: %.e60 = impl_witness_access constants.%ImplicitAs.impl_witness.9a9, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc4_18.1: <bound method> = bound_method %int_0, %impl.elem0.loc4_18.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:   %specific_fn.loc4_18.1: <specific function> = specific_function %impl.elem0.loc4_18.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc4_18.2: <bound method> = bound_method %int_0, %specific_fn.loc4_18.1 [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %u1 = call %bound_method.loc4_18.2(%int_0) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc4_18.2: init %u1 = converted %int_0, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc4_18.3: init %u1 to %.loc4_18.1 = in_place_init %.loc4_18.2 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc4_18.4: ref %.2a5 = class_element_access %return.param, element1
// CHECK:STDOUT:   %.loc4_18.5: ref %tuple.type.a8a = class_element_access %.loc4_18.4, element0
// CHECK:STDOUT:   %.loc5_17.1: %tuple.type.a8a = tuple_literal (%_.param)
// CHECK:STDOUT:   %impl.elem0.loc4_18.2: %.7a6 = impl_witness_access constants.%Copy.impl_witness.0e0, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc4_18.3: <bound method> = bound_method %_.param, %impl.elem0.loc4_18.2
// CHECK:STDOUT:   %specific_fn.loc4_18.2: <specific function> = specific_function %impl.elem0.loc4_18.2, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc4_18.4: <bound method> = bound_method %_.param, %specific_fn.loc4_18.2
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc4_18.4(%_.param)
// CHECK:STDOUT:   %.loc5_17.2: init %tuple.type.a8a to %.loc4_18.5 = tuple_init (%Int.as.Copy.impl.Op.call)
// CHECK:STDOUT:   %.loc4_18.6: init %tuple.type.a8a = converted %.loc5_17.1, %.loc5_17.2
// CHECK:STDOUT:   %.loc4_18.7: init %tuple.type.a8a to %.loc4_18.5 = in_place_init %.loc4_18.6
// CHECK:STDOUT:   %.loc4_18.8: init %IntResult to %return.param = class_init (%.loc4_18.3, %.loc4_18.7)
// CHECK:STDOUT:   return %.loc4_18.8 to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Consume(%r.param: %IntResult) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %r.ref: %IntResult = name_ref r, %r
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %value.patt: %pattern_type.6b6 = value_binding_pattern value [concrete = constants.%value.patt.d86]
// CHECK:STDOUT:     %.loc14_19: %pattern_type.e71 = tuple_pattern (%value.patt) [concrete = constants.%.af8]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc14_26.1: %.e60 = impl_witness_access constants.%ImplicitAs.impl_witness.9a9, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc14_26.1: <bound method> = bound_method %int_0, %impl.elem0.loc14_26.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:   %specific_fn.loc14_26.1: <specific function> = specific_function %impl.elem0.loc14_26.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc14_26.2: <bound method> = bound_method %int_0, %specific_fn.loc14_26.1 [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14: init %u1 = call %bound_method.loc14_26.2(%int_0) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc14_26.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc14_26.2: %u1 = converted %int_0, %.loc14_26.1 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc14_26.3: ref %u1 = class_element_access %r.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc14_26.2: %.9ed = impl_witness_access constants.%EqWith.impl_witness.d63, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc14_26.3: <bound method> = bound_method %.loc14_26.2, %impl.elem0.loc14_26.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.f34]
// CHECK:STDOUT:   %specific_fn.loc14_26.2: <specific function> = specific_function %impl.elem0.loc14_26.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc14_26.4: <bound method> = bound_method %.loc14_26.2, %specific_fn.loc14_26.2 [concrete = constants.%bound_method.53a]
// CHECK:STDOUT:   %.loc14_26.4: %u1 = acquire_value %.loc14_26.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc14: init bool = call %bound_method.loc14_26.4(%.loc14_26.2, %.loc14_26.4)
// CHECK:STDOUT:   %.loc14_26.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc14
// CHECK:STDOUT:   %.loc14_26.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc14, %.loc14_26.5
// CHECK:STDOUT:   if %.loc14_26.6 br !match.case.then.loc14 else br !match.case.else.loc14
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc14:
// CHECK:STDOUT:   %.loc14_26.7: ref %.2a5 = class_element_access %r.ref, element1
// CHECK:STDOUT:   %.loc14_26.8: ref %tuple.type.a8a = class_element_access %.loc14_26.7, element0
// CHECK:STDOUT:   %tuple.elem0: ref %i32 = tuple_access %.loc14_26.8, element0
// CHECK:STDOUT:   %.loc14_26.9: %i32 = acquire_value %tuple.elem0
// CHECK:STDOUT:   %i32.loc14: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %value: %i32 = wrapper_binding value, %.loc14_26.9
// CHECK:STDOUT:   %value.ref: %i32 = name_ref value, %value
// CHECK:STDOUT:   %impl.elem0.loc14_38: %.7a6 = impl_witness_access constants.%Copy.impl_witness.0e0, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc14_38.1: <bound method> = bound_method %value.ref, %impl.elem0.loc14_38
// CHECK:STDOUT:   %specific_fn.loc14_38: <specific function> = specific_function %impl.elem0.loc14_38, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc14_38.2: <bound method> = bound_method %value.ref, %specific_fn.loc14_38
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc14_38.2(%value.ref)
// CHECK:STDOUT:   return %Int.as.Copy.impl.Op.call
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc14:
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt: %pattern_type.e14 = expr_pattern %Err.ref in [concrete] {
// CHECK:STDOUT:       %Err.ref: %IntResult = name_ref Err, @IntResult.%Err
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Err.ref: %IntResult = name_ref Err, @IntResult.%Err
// CHECK:STDOUT:   %int_1.loc15_15: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc15_15.1: %.e60 = impl_witness_access constants.%ImplicitAs.impl_witness.9a9, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc15_15.1: <bound method> = bound_method %int_1.loc15_15, %impl.elem0.loc15_15.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc15_15.1: <specific function> = specific_function %impl.elem0.loc15_15.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc15_15.2: <bound method> = bound_method %int_1.loc15_15, %specific_fn.loc15_15.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc15_15: init %u1 = call %bound_method.loc15_15.2(%int_1.loc15_15) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc15_15.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc15_15 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc15_15.2: %u1 = converted %int_1.loc15_15, %.loc15_15.1 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc15_15.3: ref %u1 = class_element_access %r.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc15_15.2: %.9ed = impl_witness_access constants.%EqWith.impl_witness.d63, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc15_15.3: <bound method> = bound_method %.loc15_15.2, %impl.elem0.loc15_15.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.22c]
// CHECK:STDOUT:   %specific_fn.loc15_15.2: <specific function> = specific_function %impl.elem0.loc15_15.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc15_15.4: <bound method> = bound_method %.loc15_15.2, %specific_fn.loc15_15.2 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc15_15.4: %u1 = acquire_value %.loc15_15.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc15: init bool = call %bound_method.loc15_15.4(%.loc15_15.2, %.loc15_15.4)
// CHECK:STDOUT:   %.loc15_15.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc15
// CHECK:STDOUT:   %.loc15_15.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc15, %.loc15_15.5
// CHECK:STDOUT:   if %.loc15_15.6 br !match.case.then.loc15 else br !match.case.else.loc15
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc15:
// CHECK:STDOUT:   %int_1.loc15_28: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem1.loc15: %.e9b = impl_witness_access constants.%Negate.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %bound_method.loc15_27: <bound method> = bound_method %int_1.loc15_28, %impl.elem1.loc15 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op.bound.6a0]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.call.loc15: init Core.IntLiteral = call %bound_method.loc15_27(%int_1.loc15_28) [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %impl.elem0.loc15_29: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc15_29.1: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call.loc15, %impl.elem0.loc15_29 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.65e]
// CHECK:STDOUT:   %specific_fn.loc15_29: <specific function> = specific_function %impl.elem0.loc15_29, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc15_29.2: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call.loc15, %specific_fn.loc15_29 [concrete = constants.%bound_method.a65]
// CHECK:STDOUT:   %.loc15_27.1: Core.IntLiteral = value_of_initializer %Core.IntLiteral.as.Negate.impl.Op.call.loc15 [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %.loc15_27.2: Core.IntLiteral = converted %Core.IntLiteral.as.Negate.impl.Op.call.loc15, %.loc15_27.1 [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc15_29: init %i32 = call %bound_method.loc15_29.2(%.loc15_27.2) [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   %.loc15_29: init %i32 = converted %Core.IntLiteral.as.Negate.impl.Op.call.loc15, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc15_29 [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   return %.loc15_29
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc15:
// CHECK:STDOUT:   br !match.done
// CHECK:STDOUT:
// CHECK:STDOUT: !match.done:
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2]
// CHECK:STDOUT:   %impl.elem1.loc17: %.e9b = impl_witness_access constants.%Negate.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %bound_method.loc17_10: <bound method> = bound_method %int_2, %impl.elem1.loc17 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op.bound.e21]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.call.loc17: init Core.IntLiteral = call %bound_method.loc17_10(%int_2) [concrete = constants.%int_-2.962]
// CHECK:STDOUT:   %impl.elem0.loc17: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc17_12.1: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call.loc17, %impl.elem0.loc17 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.2a0]
// CHECK:STDOUT:   %specific_fn.loc17: <specific function> = specific_function %impl.elem0.loc17, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc17_12.2: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call.loc17, %specific_fn.loc17 [concrete = constants.%bound_method.33f]
// CHECK:STDOUT:   %.loc17_10.1: Core.IntLiteral = value_of_initializer %Core.IntLiteral.as.Negate.impl.Op.call.loc17 [concrete = constants.%int_-2.962]
// CHECK:STDOUT:   %.loc17_10.2: Core.IntLiteral = converted %Core.IntLiteral.as.Negate.impl.Op.call.loc17, %.loc17_10.1 [concrete = constants.%int_-2.962]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc17: init %i32 = call %bound_method.loc17_12.2(%.loc17_10.2) [concrete = constants.%int_-2.c83]
// CHECK:STDOUT:   %.loc17_12: init %i32 = converted %Core.IntLiteral.as.Negate.impl.Op.call.loc17, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc17 [concrete = constants.%int_-2.c83]
// CHECK:STDOUT:   return %.loc17_12
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- guarded_duplicate.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %IntResult: type = class_type @IntResult [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %Int.67af24.1: type = class_type @Int, @Int(%N) [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %u1: type = class_type @UInt, @UInt(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %tuple.type.a8a: type = tuple_type (%i32) [concrete]
// CHECK:STDOUT:   %.2a5: type = custom_layout_type {size=4, align=4, .Ok@0: %tuple.type.a8a} [concrete]
// CHECK:STDOUT:   %struct_type.discriminant.payload.898: type = struct_type {.discriminant: %u1, .payload: %.2a5} [concrete]
// CHECK:STDOUT:   %complete_type.697: <witness> = complete_type_witness %struct_type.discriminant.payload.898 [concrete]
// CHECK:STDOUT:   %struct_type.discriminant: type = struct_type {.discriminant: %u1} [concrete]
// CHECK:STDOUT:   %_.param_patt: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %_.patt: %pattern_type.6b6 = at_binding_pattern _, %_.param_patt [concrete]
// CHECK:STDOUT:   %.918: Core.Form = init_form %IntResult [concrete]
// CHECK:STDOUT:   %pattern_type.e14: type = pattern_type %IntResult [concrete]
// CHECK:STDOUT:   %return.param_patt.3e8: %pattern_type.e14 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.437: %pattern_type.e14 = return_slot_pattern %return.param_patt.3e8, %IntResult [concrete]
// CHECK:STDOUT:   %IntResult.Ok.type: type = fn_type @IntResult.Ok [concrete]
// CHECK:STDOUT:   %IntResult.Ok: %IntResult.Ok.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.ca1: type = facet_type <@ImplicitAs, @ImplicitAs(%u1)> [concrete]
// CHECK:STDOUT:   %To.fe9: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.170: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.9a9: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.42f, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.115: %ImplicitAs.type.ca1 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.9a9) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.19e: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%u1, %ImplicitAs.facet.115) [concrete]
// CHECK:STDOUT:   %.e60: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.19e, %ImplicitAs.facet.115 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.0e8: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
// CHECK:STDOUT:   %int_0.1a7: %u1 = int_value 0 [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.0e0: <witness> = impl_witness imports.%Copy.impl_witness_table.367, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet.987: %Copy.type = facet_value %i32, (%Copy.impl_witness.0e0) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.d09: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.987) [concrete]
// CHECK:STDOUT:   %.7a6: type = fn_type_with_self_type %Copy.WithSelf.Op.type.d09, %Copy.facet.987 [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %bound_method.d7a: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
// CHECK:STDOUT:   %int_1.233: %u1 = int_value 1 [concrete]
// CHECK:STDOUT:   %struct: %struct_type.discriminant = struct_value (%int_1.233) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.type.0c5: type = fn_type @UInt.as.Copy.impl.Op, @UInt.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.38a: %UInt.as.Copy.impl.Op.type.0c5 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.fb7: <witness> = impl_witness imports.%Copy.impl_witness_table.fe3, @UInt.as.Copy.impl(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.type.c97: type = fn_type @UInt.as.Copy.impl.Op, @UInt.as.Copy.impl(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.d9c: %UInt.as.Copy.impl.Op.type.c97 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet.771: %Copy.type = facet_value %u1, (%Copy.impl_witness.fb7) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.4d4: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.771) [concrete]
// CHECK:STDOUT:   %.37a: type = fn_type_with_self_type %Copy.WithSelf.Op.type.4d4, %Copy.facet.771 [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.bound: <bound method> = bound_method %int_1.233, %UInt.as.Copy.impl.Op.d9c [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %UInt.as.Copy.impl.Op.d9c, @UInt.as.Copy.impl.Op(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.edd: <bound method> = bound_method %int_1.233, %UInt.as.Copy.impl.Op.specific_fn [concrete]
// CHECK:STDOUT:   %uninit: %.2a5 = uninitialized_value [concrete]
// CHECK:STDOUT:   %IntResult.val: %IntResult = struct_value (%int_1.233, %uninit) [concrete]
// CHECK:STDOUT:   %.942: ref %IntResult = temporary invalid, %IntResult.val [concrete]
// CHECK:STDOUT:   %r.param_patt: %pattern_type.e14 = value_param_pattern [concrete]
// CHECK:STDOUT:   %r.patt: %pattern_type.e14 = at_binding_pattern r, %r.param_patt [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %Consume.type: type = fn_type @Consume [concrete]
// CHECK:STDOUT:   %Consume: %Consume.type = struct_value () [concrete]
// CHECK:STDOUT:   %v.patt: %pattern_type.6b6 = value_binding_pattern v [concrete]
// CHECK:STDOUT:   %pattern_type.e71: type = pattern_type %tuple.type.a8a [concrete]
// CHECK:STDOUT:   %.13b: %pattern_type.e71 = tuple_pattern (%v.patt) [concrete]
// CHECK:STDOUT:   %OrderedWith.type.975: type = facet_type <@OrderedWith, @OrderedWith(Core.IntLiteral)> [concrete]
// CHECK:STDOUT:   %M: Core.IntLiteral = symbolic_binding M, 1 [symbolic]
// CHECK:STDOUT:   %ImplicitAs.type.f7de31.1: type = facet_type <@ImplicitAs, @ImplicitAs(%Int.67af24.1)> [symbolic]
// CHECK:STDOUT:   %T.4e6: %ImplicitAs.type.f7de31.1 = symbolic_binding T, 1 [symbolic]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.type.18c27f.1: type = fn_type @Int.as.OrderedWith.impl.Greater.2, @Int.as.OrderedWith.impl.f36(%N, %T.4e6) [symbolic]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.cbccb6.1: %Int.as.OrderedWith.impl.Greater.type.18c27f.1 = struct_value () [symbolic]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.type.18c27f.2: type = fn_type @Int.as.OrderedWith.impl.Greater.3, @Int.as.OrderedWith.impl.f36(%N, %T.4e6) [symbolic]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.cbccb6.2: %Int.as.OrderedWith.impl.Greater.type.18c27f.2 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a23: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.b3c, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.9f1: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a23) [concrete]
// CHECK:STDOUT:   %OrderedWith.impl_witness.a3c: <witness> = impl_witness imports.%OrderedWith.impl_witness_table.091, @Int.as.OrderedWith.impl.f36(%int_32, %ImplicitAs.facet.9f1) [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.type.c37381.1: type = fn_type @Int.as.OrderedWith.impl.Greater.3, @Int.as.OrderedWith.impl.f36(%int_32, %ImplicitAs.facet.9f1) [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.3fec66.1: %Int.as.OrderedWith.impl.Greater.type.c37381.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.type.c37381.2: type = fn_type @Int.as.OrderedWith.impl.Greater.2, @Int.as.OrderedWith.impl.f36(%int_32, %ImplicitAs.facet.9f1) [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.3fec66.2: %Int.as.OrderedWith.impl.Greater.type.c37381.2 = struct_value () [concrete]
// CHECK:STDOUT:   %OrderedWith.facet.14b: %OrderedWith.type.975 = facet_value %i32, (%OrderedWith.impl_witness.a3c) [concrete]
// CHECK:STDOUT:   %OrderedWith.WithSelf.Greater.type.a92: type = fn_type @OrderedWith.WithSelf.Greater, @OrderedWith.WithSelf(Core.IntLiteral, %OrderedWith.facet.14b) [concrete]
// CHECK:STDOUT:   %.1d6: type = fn_type_with_self_type %OrderedWith.WithSelf.Greater.type.a92, %OrderedWith.facet.14b [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.specific_fn.a67ca5.1: <specific function> = specific_function %Int.as.OrderedWith.impl.Greater.3fec66.2, @Int.as.OrderedWith.impl.Greater.2(%int_32, %ImplicitAs.facet.9f1) [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.specific_fn.a67ca5.2: <specific function> = specific_function %Int.as.OrderedWith.impl.Greater.3fec66.1, @Int.as.OrderedWith.impl.Greater.3(%int_32, %ImplicitAs.facet.9f1) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.740: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet.9f1) [concrete]
// CHECK:STDOUT:   %.1c5: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.740, %ImplicitAs.facet.9f1 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.6e0: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_0.3c0: %i32 = int_value 0 [concrete]
// CHECK:STDOUT:   %EqWith.type.c25: type = facet_type <@EqWith, @EqWith(%u1)> [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.544: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%N, %M) [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.c67: %UInt.as.EqWith.impl.Equal.type.544 = struct_value () [symbolic]
// CHECK:STDOUT:   %EqWith.impl_witness.d63: <witness> = impl_witness imports.%EqWith.impl_witness_table.cbd, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.29b: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.ba4: %UInt.as.EqWith.impl.Equal.type.29b = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.3b6: %EqWith.type.c25 = facet_value %u1, (%EqWith.impl_witness.d63) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.922: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%u1, %EqWith.facet.3b6) [concrete]
// CHECK:STDOUT:   %.9ed: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.922, %EqWith.facet.3b6 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound.f34: <bound method> = bound_method %int_0.1a7, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.specific_fn.6b6: <specific function> = specific_function %UInt.as.EqWith.impl.Equal.ba4, @UInt.as.EqWith.impl.Equal.1(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.53a: <bound method> = bound_method %int_0.1a7, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
// CHECK:STDOUT:   %w.patt: %pattern_type.6b6 = value_binding_pattern w [concrete]
// CHECK:STDOUT:   %.849: %pattern_type.e71 = tuple_pattern (%w.patt) [concrete]
// CHECK:STDOUT:   %SubWith.type.4c2: type = facet_type <@SubWith, @SubWith(Core.IntLiteral)> [concrete]
// CHECK:STDOUT:   %U.4e6: %ImplicitAs.type.f7de31.1 = symbolic_binding U, 1 [symbolic]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.type.6f3321.1: type = fn_type @Int.as.SubWith.impl.Op.2, @Int.as.SubWith.impl.dc8(%N, %U.4e6) [symbolic]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.a37528.1: %Int.as.SubWith.impl.Op.type.6f3321.1 = struct_value () [symbolic]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.type.6f3321.2: type = fn_type @Int.as.SubWith.impl.Op.3, @Int.as.SubWith.impl.dc8(%N, %U.4e6) [symbolic]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.a37528.2: %Int.as.SubWith.impl.Op.type.6f3321.2 = struct_value () [symbolic]
// CHECK:STDOUT:   %SubWith.impl_witness.d78: <witness> = impl_witness imports.%SubWith.impl_witness_table.dc9, @Int.as.SubWith.impl.dc8(%int_32, %ImplicitAs.facet.9f1) [concrete]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.type.745d60.1: type = fn_type @Int.as.SubWith.impl.Op.3, @Int.as.SubWith.impl.dc8(%int_32, %ImplicitAs.facet.9f1) [concrete]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.49baee.1: %Int.as.SubWith.impl.Op.type.745d60.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.type.745d60.2: type = fn_type @Int.as.SubWith.impl.Op.2, @Int.as.SubWith.impl.dc8(%int_32, %ImplicitAs.facet.9f1) [concrete]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.49baee.2: %Int.as.SubWith.impl.Op.type.745d60.2 = struct_value () [concrete]
// CHECK:STDOUT:   %SubWith.facet.d48: %SubWith.type.4c2 = facet_value %i32, (%SubWith.impl_witness.d78) [concrete]
// CHECK:STDOUT:   %SubWith.WithSelf.Op.type.d3c: type = fn_type @SubWith.WithSelf.Op, @SubWith.WithSelf(Core.IntLiteral, %SubWith.facet.d48) [concrete]
// CHECK:STDOUT:   %.e15: type = fn_type_with_self_type %SubWith.WithSelf.Op.type.d3c, %SubWith.facet.d48 [concrete]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.specific_fn.4cc768.1: <specific function> = specific_function %Int.as.SubWith.impl.Op.49baee.2, @Int.as.SubWith.impl.Op.2(%int_32, %ImplicitAs.facet.9f1) [concrete]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.specific_fn.4cc768.2: <specific function> = specific_function %Int.as.SubWith.impl.Op.49baee.1, @Int.as.SubWith.impl.Op.3(%int_32, %ImplicitAs.facet.9f1) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.953: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound.22c: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %bound_method.a82: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
// CHECK:STDOUT:   %int_10: Core.IntLiteral = int_value 10 [concrete]
// CHECK:STDOUT:   %Negate.type: type = facet_type <@Negate> [concrete]
// CHECK:STDOUT:   %Negate.impl_witness: <witness> = impl_witness imports.%Negate.impl_witness_table [concrete]
// CHECK:STDOUT:   %Negate.facet: %Negate.type = facet_value Core.IntLiteral, (%Negate.impl_witness) [concrete]
// CHECK:STDOUT:   %Negate.WithSelf.Op.type.db1: type = fn_type @Negate.WithSelf.Op, @Negate.WithSelf(%Negate.facet) [concrete]
// CHECK:STDOUT:   %.e9b: type = fn_type_with_self_type %Negate.WithSelf.Op.type.db1, %Negate.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.type: type = fn_type @Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op: %Core.IntLiteral.as.Negate.impl.Op.type = struct_value () [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.bound.599: <bound method> = bound_method %int_10, %Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %int_-10.06d: Core.IntLiteral = int_value -10 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.f93: <bound method> = bound_method %int_-10.06d, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.27d: <bound method> = bound_method %int_-10.06d, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_-10.642: %i32 = int_value -10 [concrete]
// CHECK:STDOUT:   %int_20: Core.IntLiteral = int_value 20 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.bound.6ab: <bound method> = bound_method %int_20, %Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %int_-20.28d: Core.IntLiteral = int_value -20 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.503: <bound method> = bound_method %int_-20.28d, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.4c6: <bound method> = bound_method %int_-20.28d, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_-20.6ef: %i32 = int_value -20 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.aa5: @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.170)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.42f = impl_witness_table (%Core.import_ref.aa5), @Core.IntLiteral.as.ImplicitAs.impl.b68 [concrete]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.367 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.791: @UInt.as.Copy.impl.%UInt.as.Copy.impl.Op.type (%UInt.as.Copy.impl.Op.type.0c5) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.Copy.impl.%UInt.as.Copy.impl.Op (constants.%UInt.as.Copy.impl.Op.38a)]
// CHECK:STDOUT:   %Copy.impl_witness_table.fe3 = impl_witness_table (%Core.import_ref.791), @UInt.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.0e6 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.f9df = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.0ab: @Int.as.OrderedWith.impl.f36.%Int.as.OrderedWith.impl.Greater.type.2 (%Int.as.OrderedWith.impl.Greater.type.18c27f.1) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.OrderedWith.impl.f36.%Int.as.OrderedWith.impl.Greater.2 (constants.%Int.as.OrderedWith.impl.Greater.cbccb6.1)]
// CHECK:STDOUT:   %Core.import_ref.b56 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %OrderedWith.impl_witness_table.091 = impl_witness_table (%Core.import_ref.0e6, %Core.import_ref.f9df, %Core.import_ref.0ab, %Core.import_ref.b56), @Int.as.OrderedWith.impl.f36 [concrete]
// CHECK:STDOUT:   %Core.Greater.28d: @Int.as.OrderedWith.impl.f36.%Int.as.OrderedWith.impl.Greater.type.1 (%Int.as.OrderedWith.impl.Greater.type.18c27f.2) = import_ref Core//prelude/types/int, Greater, loaded [symbolic = @Int.as.OrderedWith.impl.f36.%Int.as.OrderedWith.impl.Greater.1 (constants.%Int.as.OrderedWith.impl.Greater.cbccb6.2)]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.b3c = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.b92: @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal.type (%UInt.as.EqWith.impl.Equal.type.544) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal (constants.%UInt.as.EqWith.impl.Equal.c67)]
// CHECK:STDOUT:   %Core.import_ref.b44 = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.cbd = impl_witness_table (%Core.import_ref.b92, %Core.import_ref.b44), @UInt.as.EqWith.impl.f13 [concrete]
// CHECK:STDOUT:   %Core.import_ref.b4fd3a.2 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.6fa: @Int.as.SubWith.impl.dc8.%Int.as.SubWith.impl.Op.type.2 (%Int.as.SubWith.impl.Op.type.6f3321.1) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.SubWith.impl.dc8.%Int.as.SubWith.impl.Op.2 (constants.%Int.as.SubWith.impl.Op.a37528.1)]
// CHECK:STDOUT:   %SubWith.impl_witness_table.dc9 = impl_witness_table (%Core.import_ref.b4fd3a.2, %Core.import_ref.6fa), @Int.as.SubWith.impl.dc8 [concrete]
// CHECK:STDOUT:   %Core.Op.9ff: @Int.as.SubWith.impl.dc8.%Int.as.SubWith.impl.Op.type.1 (%Int.as.SubWith.impl.Op.type.6f3321.2) = import_ref Core//prelude/types/int, Op, loaded [symbolic = @Int.as.SubWith.impl.dc8.%Int.as.SubWith.impl.Op.1 (constants.%Int.as.SubWith.impl.Op.a37528.2)]
// CHECK:STDOUT:   %Core.import_ref.abd = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9c3: %Core.IntLiteral.as.Negate.impl.Op.type = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, loaded [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %Negate.impl_witness_table = impl_witness_table (%Core.import_ref.abd, %Core.import_ref.9c3), @Core.IntLiteral.as.Negate.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %IntResult.Ok.decl: %IntResult.Ok.type = fn_decl @IntResult.Ok [concrete = constants.%IntResult.Ok] {
// CHECK:STDOUT:     %_.param_patt: %pattern_type.6b6 = value_param_pattern [concrete = constants.%_.param_patt]
// CHECK:STDOUT:     %_.patt: %pattern_type.6b6 = at_binding_pattern _, %_.param_patt [concrete = constants.%_.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.e14 = out_param_pattern [concrete = constants.%return.param_patt.3e8]
// CHECK:STDOUT:     %return.patt: %pattern_type.e14 = return_slot_pattern %return.param_patt, constants.%IntResult [concrete = constants.%return.patt.437]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc4_18.9: Core.Form = init_form constants.%IntResult [concrete = constants.%.918]
// CHECK:STDOUT:     %_.param: %i32 = value_param call_param0
// CHECK:STDOUT:     %_: %i32 = wrapper_binding _, %_.param
// CHECK:STDOUT:     %return.param: ref %IntResult = out_param call_param1
// CHECK:STDOUT:     %return: ref %IntResult = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %IntResult.decl: type = class_decl @IntResult [concrete = constants.%IntResult] {} {}
// CHECK:STDOUT:   %Consume.decl: %Consume.type = fn_decl @Consume [concrete = constants.%Consume] {
// CHECK:STDOUT:     %r.param_patt: %pattern_type.e14 = value_param_pattern [concrete = constants.%r.param_patt]
// CHECK:STDOUT:     %r.patt: %pattern_type.e14 = at_binding_pattern r, %r.param_patt [concrete = constants.%r.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc12 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc12: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc12: Core.Form = init_form %i32.loc12 [concrete = constants.%.795f]
// CHECK:STDOUT:     %r.param: %IntResult = value_param call_param0
// CHECK:STDOUT:     %IntResult.ref: type = name_ref IntResult, file.%IntResult.decl [concrete = constants.%IntResult]
// CHECK:STDOUT:     %r: %IntResult = wrapper_binding r, %r.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: class @IntResult {
// CHECK:STDOUT:   %value.param: %i32 = value_param call_param0
// CHECK:STDOUT:   %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %value: %i32 = wrapper_binding value, %value.param
// CHECK:STDOUT:   %.loc7_1.1: type = custom_layout_type {size=4, align=4, .Ok@0: %tuple.type.a8a} [concrete = constants.%.2a5]
// CHECK:STDOUT:   %complete_type: <witness> = complete_type_witness constants.%struct_type.discriminant.payload.898 [concrete = constants.%complete_type.697]
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc7_1.1: %.e60 = impl_witness_access constants.%ImplicitAs.impl_witness.9a9, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc7_1.1: <bound method> = bound_method %int_1, %impl.elem0.loc7_1.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc7_1.1: <specific function> = specific_function %impl.elem0.loc7_1.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc7_1.2: <bound method> = bound_method %int_1, %specific_fn.loc7_1.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %u1 = call %bound_method.loc7_1.2(%int_1) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc7_1.2: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc7_1.3: %u1 = converted %int_1, %.loc7_1.2 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc7_1.4: %struct_type.discriminant = struct_literal (%.loc7_1.3) [concrete = constants.%struct]
// CHECK:STDOUT:   %impl.elem0.loc7_1.2: %.37a = impl_witness_access constants.%Copy.impl_witness.fb7, element0 [concrete = constants.%UInt.as.Copy.impl.Op.d9c]
// CHECK:STDOUT:   %bound_method.loc7_1.3: <bound method> = bound_method %.loc7_1.3, %impl.elem0.loc7_1.2 [concrete = constants.%UInt.as.Copy.impl.Op.bound]
// CHECK:STDOUT:   %specific_fn.loc7_1.2: <specific function> = specific_function %impl.elem0.loc7_1.2, @UInt.as.Copy.impl.Op(constants.%int_1.5b8) [concrete = constants.%UInt.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc7_1.4: <bound method> = bound_method %.loc7_1.3, %specific_fn.loc7_1.2 [concrete = constants.%bound_method.edd]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.call: init %u1 = call %bound_method.loc7_1.4(%.loc7_1.3) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc7_1.5: ref %IntResult = temporary_storage
// CHECK:STDOUT:   %.loc7_1.6: ref %u1 = class_element_access %.loc7_1.5, element0
// CHECK:STDOUT:   %.loc7_1.7: init %u1 to %.loc7_1.6 = in_place_init %UInt.as.Copy.impl.Op.call [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc7_1.8: ref %.2a5 = class_element_access %.loc7_1.5, element1
// CHECK:STDOUT:   %uninit: %.2a5 = uninitialized_value [concrete = constants.%uninit]
// CHECK:STDOUT:   %.loc7_1.9: init %.2a5 to %.loc7_1.8 = in_place_init %uninit [concrete = constants.%uninit]
// CHECK:STDOUT:   %.loc7_1.10: init %IntResult to %.loc7_1.5 = class_init (%.loc7_1.7, %.loc7_1.9) [concrete = constants.%IntResult.val]
// CHECK:STDOUT:   %.loc7_1.11: init %IntResult = converted %.loc7_1.4, %.loc7_1.10 [concrete = constants.%IntResult.val]
// CHECK:STDOUT:   %.loc7_1.12: ref %IntResult = temporary %.loc7_1.5, %.loc7_1.11 [concrete = constants.%.942]
// CHECK:STDOUT:   %.loc7_1.13: %IntResult = acquire_value %.loc7_1.12 [concrete = constants.%IntResult.val]
// CHECK:STDOUT:   %Err: %IntResult = wrapper_binding Err, %.loc7_1.13
// CHECK:STDOUT:   complete_type_witness = %complete_type
// CHECK:STDOUT:
// CHECK:STDOUT: !members:
// CHECK:STDOUT:   .Self = constants.%IntResult
// CHECK:STDOUT:   .Ok = generated.%IntResult.Ok.decl
// CHECK:STDOUT:   .Err = %Err
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @IntResult.Ok(%_.param: %i32) -> out %return.param: %IntResult {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %.loc4_18.1: ref %u1 = class_element_access %return.param, element0
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc4_18.1: %.e60 = impl_witness_access constants.%ImplicitAs.impl_witness.9a9, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc4_18.1: <bound method> = bound_method %int_0, %impl.elem0.loc4_18.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:   %specific_fn.loc4_18.1: <specific function> = specific_function %impl.elem0.loc4_18.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc4_18.2: <bound method> = bound_method %int_0, %specific_fn.loc4_18.1 [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %u1 = call %bound_method.loc4_18.2(%int_0) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc4_18.2: init %u1 = converted %int_0, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc4_18.3: init %u1 to %.loc4_18.1 = in_place_init %.loc4_18.2 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc4_18.4: ref %.2a5 = class_element_access %return.param, element1
// CHECK:STDOUT:   %.loc4_18.5: ref %tuple.type.a8a = class_element_access %.loc4_18.4, element0
// CHECK:STDOUT:   %.loc5_17.1: %tuple.type.a8a = tuple_literal (%_.param)
// CHECK:STDOUT:   %impl.elem0.loc4_18.2: %.7a6 = impl_witness_access constants.%Copy.impl_witness.0e0, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc4_18.3: <bound method> = bound_method %_.param, %impl.elem0.loc4_18.2
// CHECK:STDOUT:   %specific_fn.loc4_18.2: <specific function> = specific_function %impl.elem0.loc4_18.2, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc4_18.4: <bound method> = bound_method %_.param, %specific_fn.loc4_18.2
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc4_18.4(%_.param)
// CHECK:STDOUT:   %.loc5_17.2: init %tuple.type.a8a to %.loc4_18.5 = tuple_init (%Int.as.Copy.impl.Op.call)
// CHECK:STDOUT:   %.loc4_18.6: init %tuple.type.a8a = converted %.loc5_17.1, %.loc5_17.2
// CHECK:STDOUT:   %.loc4_18.7: init %tuple.type.a8a to %.loc4_18.5 = in_place_init %.loc4_18.6
// CHECK:STDOUT:   %.loc4_18.8: init %IntResult to %return.param = class_init (%.loc4_18.3, %.loc4_18.7)
// CHECK:STDOUT:   return %.loc4_18.8 to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Consume(%r.param: %IntResult) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %r.ref: %IntResult = name_ref r, %r
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %v.patt: %pattern_type.6b6 = value_binding_pattern v [concrete = constants.%v.patt]
// CHECK:STDOUT:     %.loc14_15: %pattern_type.e71 = tuple_pattern (%v.patt) [concrete = constants.%.13b]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_0.loc14_33: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc14_33.1: %.e60 = impl_witness_access constants.%ImplicitAs.impl_witness.9a9, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc14_33.1: <bound method> = bound_method %int_0.loc14_33, %impl.elem0.loc14_33.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:   %specific_fn.loc14_33.1: <specific function> = specific_function %impl.elem0.loc14_33.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc14_33.2: <bound method> = bound_method %int_0.loc14_33, %specific_fn.loc14_33.1 [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14_33: init %u1 = call %bound_method.loc14_33.2(%int_0.loc14_33) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc14_33.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14_33 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc14_33.2: %u1 = converted %int_0.loc14_33, %.loc14_33.1 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc14_33.3: ref %u1 = class_element_access %r.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc14_33.2: %.9ed = impl_witness_access constants.%EqWith.impl_witness.d63, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc14_33.3: <bound method> = bound_method %.loc14_33.2, %impl.elem0.loc14_33.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.f34]
// CHECK:STDOUT:   %specific_fn.loc14_33.2: <specific function> = specific_function %impl.elem0.loc14_33.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc14_33.4: <bound method> = bound_method %.loc14_33.2, %specific_fn.loc14_33.2 [concrete = constants.%bound_method.53a]
// CHECK:STDOUT:   %.loc14_33.4: %u1 = acquire_value %.loc14_33.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc14: init bool = call %bound_method.loc14_33.4(%.loc14_33.2, %.loc14_33.4)
// CHECK:STDOUT:   %.loc14_33.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc14
// CHECK:STDOUT:   %.loc14_33.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc14, %.loc14_33.5
// CHECK:STDOUT:   if %.loc14_33.6 br !match.case.then.loc14_33.1 else br !match.case.else.loc14
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc14_33.1:
// CHECK:STDOUT:   %.loc14_33.7: ref %.2a5 = class_element_access %r.ref, element1
// CHECK:STDOUT:   %.loc14_33.8: ref %tuple.type.a8a = class_element_access %.loc14_33.7, element0
// CHECK:STDOUT:   %tuple.elem0.loc14: ref %i32 = tuple_access %.loc14_33.8, element0
// CHECK:STDOUT:   %.loc14_33.9: %i32 = acquire_value %tuple.elem0.loc14
// CHECK:STDOUT:   %i32.loc14: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %v: %i32 = wrapper_binding v, %.loc14_33.9
// CHECK:STDOUT:   %.loc14_28.1: bool = splice_block %.loc14_28.4 {
// CHECK:STDOUT:     %v.ref.loc14_26: %i32 = name_ref v, %v
// CHECK:STDOUT:     %int_0.loc14_30: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:     %impl.elem2: %.1d6 = impl_witness_access constants.%OrderedWith.impl_witness.a3c, element2 [concrete = constants.%Int.as.OrderedWith.impl.Greater.3fec66.2]
// CHECK:STDOUT:     %bound_method.loc14_28.1: <bound method> = bound_method %v.ref.loc14_26, %impl.elem2
// CHECK:STDOUT:     %specific_fn.loc14_28: <specific function> = specific_function %impl.elem2, @Int.as.OrderedWith.impl.Greater.2(constants.%int_32, constants.%ImplicitAs.facet.9f1) [concrete = constants.%Int.as.OrderedWith.impl.Greater.specific_fn.a67ca5.1]
// CHECK:STDOUT:     %bound_method.loc14_28.2: <bound method> = bound_method %v.ref.loc14_26, %specific_fn.loc14_28
// CHECK:STDOUT:     %.loc14_28.2: %Int.as.OrderedWith.impl.Greater.type.c37381.1 = specific_constant imports.%Core.Greater.28d, @Int.as.OrderedWith.impl.f36(constants.%int_32, constants.%ImplicitAs.facet.9f1) [concrete = constants.%Int.as.OrderedWith.impl.Greater.3fec66.1]
// CHECK:STDOUT:     %Greater.ref: %Int.as.OrderedWith.impl.Greater.type.c37381.1 = name_ref Greater, %.loc14_28.2 [concrete = constants.%Int.as.OrderedWith.impl.Greater.3fec66.1]
// CHECK:STDOUT:     %Int.as.OrderedWith.impl.Greater.bound: <bound method> = bound_method %v.ref.loc14_26, %Greater.ref
// CHECK:STDOUT:     %Int.as.OrderedWith.impl.Greater.specific_fn: <specific function> = specific_function %Greater.ref, @Int.as.OrderedWith.impl.Greater.3(constants.%int_32, constants.%ImplicitAs.facet.9f1) [concrete = constants.%Int.as.OrderedWith.impl.Greater.specific_fn.a67ca5.2]
// CHECK:STDOUT:     %bound_method.loc14_28.3: <bound method> = bound_method %v.ref.loc14_26, %Int.as.OrderedWith.impl.Greater.specific_fn
// CHECK:STDOUT:     %impl.elem0.loc14_30: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:     %bound_method.loc14_30.1: <bound method> = bound_method %int_0.loc14_30, %impl.elem0.loc14_30 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:     %specific_fn.loc14_30: <specific function> = specific_function %impl.elem0.loc14_30, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:     %bound_method.loc14_30.2: <bound method> = bound_method %int_0.loc14_30, %specific_fn.loc14_30 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14_30: init %i32 = call %bound_method.loc14_30.2(%int_0.loc14_30) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:     %.loc14_30.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14_30 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:     %.loc14_30.2: %i32 = converted %int_0.loc14_30, %.loc14_30.1 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:     %Int.as.OrderedWith.impl.Greater.call: init bool = call %bound_method.loc14_28.3(%v.ref.loc14_26, %.loc14_30.2)
// CHECK:STDOUT:     %.loc14_28.3: bool = value_of_initializer %Int.as.OrderedWith.impl.Greater.call
// CHECK:STDOUT:     %.loc14_28.4: bool = converted %Int.as.OrderedWith.impl.Greater.call, %.loc14_28.3
// CHECK:STDOUT:   }
// CHECK:STDOUT:   if %.loc14_28.1 br !match.case.then.loc14_33.2 else br !match.case.else.loc14
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc14_33.2:
// CHECK:STDOUT:   %v.ref.loc14_45: %i32 = name_ref v, %v
// CHECK:STDOUT:   %impl.elem0.loc14_45: %.7a6 = impl_witness_access constants.%Copy.impl_witness.0e0, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc14_45.1: <bound method> = bound_method %v.ref.loc14_45, %impl.elem0.loc14_45
// CHECK:STDOUT:   %specific_fn.loc14_45: <specific function> = specific_function %impl.elem0.loc14_45, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc14_45.2: <bound method> = bound_method %v.ref.loc14_45, %specific_fn.loc14_45
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc14_45.2(%v.ref.loc14_45)
// CHECK:STDOUT:   return %Int.as.Copy.impl.Op.call
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc14:
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %w.patt: %pattern_type.6b6 = value_binding_pattern w [concrete = constants.%w.patt]
// CHECK:STDOUT:     %.loc15_15: %pattern_type.e71 = tuple_pattern (%w.patt) [concrete = constants.%.849]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_0.loc15: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc15_22.1: %.e60 = impl_witness_access constants.%ImplicitAs.impl_witness.9a9, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc15_22.1: <bound method> = bound_method %int_0.loc15, %impl.elem0.loc15_22.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:   %specific_fn.loc15_22.1: <specific function> = specific_function %impl.elem0.loc15_22.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc15_22.2: <bound method> = bound_method %int_0.loc15, %specific_fn.loc15_22.1 [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc15_22: init %u1 = call %bound_method.loc15_22.2(%int_0.loc15) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc15_22.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc15_22 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc15_22.2: %u1 = converted %int_0.loc15, %.loc15_22.1 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc15_22.3: ref %u1 = class_element_access %r.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc15_22.2: %.9ed = impl_witness_access constants.%EqWith.impl_witness.d63, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc15_22.3: <bound method> = bound_method %.loc15_22.2, %impl.elem0.loc15_22.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.f34]
// CHECK:STDOUT:   %specific_fn.loc15_22.2: <specific function> = specific_function %impl.elem0.loc15_22.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc15_22.4: <bound method> = bound_method %.loc15_22.2, %specific_fn.loc15_22.2 [concrete = constants.%bound_method.53a]
// CHECK:STDOUT:   %.loc15_22.4: %u1 = acquire_value %.loc15_22.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc15: init bool = call %bound_method.loc15_22.4(%.loc15_22.2, %.loc15_22.4)
// CHECK:STDOUT:   %.loc15_22.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc15
// CHECK:STDOUT:   %.loc15_22.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc15, %.loc15_22.5
// CHECK:STDOUT:   if %.loc15_22.6 br !match.case.then.loc15 else br !match.case.else.loc15
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc15:
// CHECK:STDOUT:   %.loc15_22.7: ref %.2a5 = class_element_access %r.ref, element1
// CHECK:STDOUT:   %.loc15_22.8: ref %tuple.type.a8a = class_element_access %.loc15_22.7, element0
// CHECK:STDOUT:   %tuple.elem0.loc15: ref %i32 = tuple_access %.loc15_22.8, element0
// CHECK:STDOUT:   %.loc15_22.9: %i32 = acquire_value %tuple.elem0.loc15
// CHECK:STDOUT:   %i32.loc15: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %w: %i32 = wrapper_binding w, %.loc15_22.9
// CHECK:STDOUT:   %w.ref: %i32 = name_ref w, %w
// CHECK:STDOUT:   %int_1.loc15: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem1.loc15: %.e15 = impl_witness_access constants.%SubWith.impl_witness.d78, element1 [concrete = constants.%Int.as.SubWith.impl.Op.49baee.2]
// CHECK:STDOUT:   %bound_method.loc15_36.1: <bound method> = bound_method %w.ref, %impl.elem1.loc15
// CHECK:STDOUT:   %specific_fn.loc15_36: <specific function> = specific_function %impl.elem1.loc15, @Int.as.SubWith.impl.Op.2(constants.%int_32, constants.%ImplicitAs.facet.9f1) [concrete = constants.%Int.as.SubWith.impl.Op.specific_fn.4cc768.1]
// CHECK:STDOUT:   %bound_method.loc15_36.2: <bound method> = bound_method %w.ref, %specific_fn.loc15_36
// CHECK:STDOUT:   %.loc15_36: %Int.as.SubWith.impl.Op.type.745d60.1 = specific_constant imports.%Core.Op.9ff, @Int.as.SubWith.impl.dc8(constants.%int_32, constants.%ImplicitAs.facet.9f1) [concrete = constants.%Int.as.SubWith.impl.Op.49baee.1]
// CHECK:STDOUT:   %Op.ref: %Int.as.SubWith.impl.Op.type.745d60.1 = name_ref Op, %.loc15_36 [concrete = constants.%Int.as.SubWith.impl.Op.49baee.1]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.bound: <bound method> = bound_method %w.ref, %Op.ref
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.specific_fn: <specific function> = specific_function %Op.ref, @Int.as.SubWith.impl.Op.3(constants.%int_32, constants.%ImplicitAs.facet.9f1) [concrete = constants.%Int.as.SubWith.impl.Op.specific_fn.4cc768.2]
// CHECK:STDOUT:   %bound_method.loc15_36.3: <bound method> = bound_method %w.ref, %Int.as.SubWith.impl.Op.specific_fn
// CHECK:STDOUT:   %impl.elem0.loc15_38: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc15_38.1: <bound method> = bound_method %int_1.loc15, %impl.elem0.loc15_38 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc15_38: <specific function> = specific_function %impl.elem0.loc15_38, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc15_38.2: <bound method> = bound_method %int_1.loc15, %specific_fn.loc15_38 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc15_38: init %i32 = call %bound_method.loc15_38.2(%int_1.loc15) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc15_38.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc15_38 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc15_38.2: %i32 = converted %int_1.loc15, %.loc15_38.1 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.call: init %i32 = call %bound_method.loc15_36.3(%w.ref, %.loc15_38.2)
// CHECK:STDOUT:   return %Int.as.SubWith.impl.Op.call
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc15:
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt: %pattern_type.e14 = expr_pattern %Err.ref in [concrete] {
// CHECK:STDOUT:       %Err.ref: %IntResult = name_ref Err, @IntResult.%Err
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Err.ref: %IntResult = name_ref Err, @IntResult.%Err
// CHECK:STDOUT:   %int_1.loc16: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc16_15.1: %.e60 = impl_witness_access constants.%ImplicitAs.impl_witness.9a9, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc16_15.1: <bound method> = bound_method %int_1.loc16, %impl.elem0.loc16_15.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc16_15.1: <specific function> = specific_function %impl.elem0.loc16_15.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc16_15.2: <bound method> = bound_method %int_1.loc16, %specific_fn.loc16_15.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16_15: init %u1 = call %bound_method.loc16_15.2(%int_1.loc16) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc16_15.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16_15 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc16_15.2: %u1 = converted %int_1.loc16, %.loc16_15.1 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc16_15.3: ref %u1 = class_element_access %r.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc16_15.2: %.9ed = impl_witness_access constants.%EqWith.impl_witness.d63, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc16_15.3: <bound method> = bound_method %.loc16_15.2, %impl.elem0.loc16_15.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.22c]
// CHECK:STDOUT:   %specific_fn.loc16_15.2: <specific function> = specific_function %impl.elem0.loc16_15.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc16_15.4: <bound method> = bound_method %.loc16_15.2, %specific_fn.loc16_15.2 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc16_15.4: %u1 = acquire_value %.loc16_15.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc16: init bool = call %bound_method.loc16_15.4(%.loc16_15.2, %.loc16_15.4)
// CHECK:STDOUT:   %.loc16_15.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc16
// CHECK:STDOUT:   %.loc16_15.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc16, %.loc16_15.5
// CHECK:STDOUT:   if %.loc16_15.6 br !match.case.then.loc16 else br !match.case.else.loc16
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc16:
// CHECK:STDOUT:   %int_10: Core.IntLiteral = int_value 10 [concrete = constants.%int_10]
// CHECK:STDOUT:   %impl.elem1.loc16: %.e9b = impl_witness_access constants.%Negate.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %bound_method.loc16_27: <bound method> = bound_method %int_10, %impl.elem1.loc16 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op.bound.599]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.call.loc16: init Core.IntLiteral = call %bound_method.loc16_27(%int_10) [concrete = constants.%int_-10.06d]
// CHECK:STDOUT:   %impl.elem0.loc16_30: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc16_30.1: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call.loc16, %impl.elem0.loc16_30 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.f93]
// CHECK:STDOUT:   %specific_fn.loc16_30: <specific function> = specific_function %impl.elem0.loc16_30, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc16_30.2: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call.loc16, %specific_fn.loc16_30 [concrete = constants.%bound_method.27d]
// CHECK:STDOUT:   %.loc16_27.1: Core.IntLiteral = value_of_initializer %Core.IntLiteral.as.Negate.impl.Op.call.loc16 [concrete = constants.%int_-10.06d]
// CHECK:STDOUT:   %.loc16_27.2: Core.IntLiteral = converted %Core.IntLiteral.as.Negate.impl.Op.call.loc16, %.loc16_27.1 [concrete = constants.%int_-10.06d]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16_30: init %i32 = call %bound_method.loc16_30.2(%.loc16_27.2) [concrete = constants.%int_-10.642]
// CHECK:STDOUT:   %.loc16_30: init %i32 = converted %Core.IntLiteral.as.Negate.impl.Op.call.loc16, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16_30 [concrete = constants.%int_-10.642]
// CHECK:STDOUT:   return %.loc16_30
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc16:
// CHECK:STDOUT:   br !match.done
// CHECK:STDOUT:
// CHECK:STDOUT: !match.done:
// CHECK:STDOUT:   %int_20: Core.IntLiteral = int_value 20 [concrete = constants.%int_20]
// CHECK:STDOUT:   %impl.elem1.loc18: %.e9b = impl_witness_access constants.%Negate.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %bound_method.loc18_10: <bound method> = bound_method %int_20, %impl.elem1.loc18 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op.bound.6ab]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.call.loc18: init Core.IntLiteral = call %bound_method.loc18_10(%int_20) [concrete = constants.%int_-20.28d]
// CHECK:STDOUT:   %impl.elem0.loc18: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc18_13.1: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call.loc18, %impl.elem0.loc18 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.503]
// CHECK:STDOUT:   %specific_fn.loc18: <specific function> = specific_function %impl.elem0.loc18, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc18_13.2: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call.loc18, %specific_fn.loc18 [concrete = constants.%bound_method.4c6]
// CHECK:STDOUT:   %.loc18_10.1: Core.IntLiteral = value_of_initializer %Core.IntLiteral.as.Negate.impl.Op.call.loc18 [concrete = constants.%int_-20.28d]
// CHECK:STDOUT:   %.loc18_10.2: Core.IntLiteral = converted %Core.IntLiteral.as.Negate.impl.Op.call.loc18, %.loc18_10.1 [concrete = constants.%int_-20.28d]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc18: init %i32 = call %bound_method.loc18_13.2(%.loc18_10.2) [concrete = constants.%int_-20.6ef]
// CHECK:STDOUT:   %.loc18_13: init %i32 = converted %Core.IntLiteral.as.Negate.impl.Op.call.loc18, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc18 [concrete = constants.%int_-20.6ef]
// CHECK:STDOUT:   return %.loc18_13
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- with_default.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %Flag: type = class_type @Flag [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %u1: type = class_type @UInt, @UInt(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %struct_type.discriminant: type = struct_type {.discriminant: %u1} [concrete]
// CHECK:STDOUT:   %complete_type.3a6: <witness> = complete_type_witness %struct_type.discriminant [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.ca1: type = facet_type <@ImplicitAs, @ImplicitAs(%u1)> [concrete]
// CHECK:STDOUT:   %To.fe9: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.170: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.9a9: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.42f, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.115: %ImplicitAs.type.ca1 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.9a9) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.19e: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%u1, %ImplicitAs.facet.115) [concrete]
// CHECK:STDOUT:   %.e60: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.19e, %ImplicitAs.facet.115 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.0e8: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
// CHECK:STDOUT:   %int_0.1a7: %u1 = int_value 0 [concrete]
// CHECK:STDOUT:   %struct.249: %struct_type.discriminant = struct_value (%int_0.1a7) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.type.0c5: type = fn_type @UInt.as.Copy.impl.Op, @UInt.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.38a: %UInt.as.Copy.impl.Op.type.0c5 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.fb7: <witness> = impl_witness imports.%Copy.impl_witness_table.fe3, @UInt.as.Copy.impl(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.type.c97: type = fn_type @UInt.as.Copy.impl.Op, @UInt.as.Copy.impl(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.d9c: %UInt.as.Copy.impl.Op.type.c97 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet: %Copy.type = facet_value %u1, (%Copy.impl_witness.fb7) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.4d4: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet) [concrete]
// CHECK:STDOUT:   %.37a: type = fn_type_with_self_type %Copy.WithSelf.Op.type.4d4, %Copy.facet [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.bound.bd0: <bound method> = bound_method %int_0.1a7, %UInt.as.Copy.impl.Op.d9c [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %UInt.as.Copy.impl.Op.d9c, @UInt.as.Copy.impl.Op(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.61c: <bound method> = bound_method %int_0.1a7, %UInt.as.Copy.impl.Op.specific_fn [concrete]
// CHECK:STDOUT:   %Flag.val.246: %Flag = struct_value (%int_0.1a7) [concrete]
// CHECK:STDOUT:   %.a8b: ref %Flag = temporary invalid, %Flag.val.246 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %bound_method.d7a: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
// CHECK:STDOUT:   %int_1.233: %u1 = int_value 1 [concrete]
// CHECK:STDOUT:   %struct.a79: %struct_type.discriminant = struct_value (%int_1.233) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.bound.332: <bound method> = bound_method %int_1.233, %UInt.as.Copy.impl.Op.d9c [concrete]
// CHECK:STDOUT:   %bound_method.edd: <bound method> = bound_method %int_1.233, %UInt.as.Copy.impl.Op.specific_fn [concrete]
// CHECK:STDOUT:   %Flag.val.cba: %Flag = struct_value (%int_1.233) [concrete]
// CHECK:STDOUT:   %.c9b: ref %Flag = temporary invalid, %Flag.val.cba [concrete]
// CHECK:STDOUT:   %pattern_type.5bc: type = pattern_type %Flag [concrete]
// CHECK:STDOUT:   %f.param_patt: %pattern_type.5bc = value_param_pattern [concrete]
// CHECK:STDOUT:   %f.patt: %pattern_type.5bc = at_binding_pattern f, %f.param_patt [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %Classify.type: type = fn_type @Classify [concrete]
// CHECK:STDOUT:   %Classify: %Classify.type = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.type.c25: type = facet_type <@EqWith, @EqWith(%u1)> [concrete]
// CHECK:STDOUT:   %M: Core.IntLiteral = symbolic_binding M, 1 [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.544: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%N, %M) [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.c67: %UInt.as.EqWith.impl.Equal.type.544 = struct_value () [symbolic]
// CHECK:STDOUT:   %EqWith.impl_witness.d63: <witness> = impl_witness imports.%EqWith.impl_witness_table.cbd, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.29b: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.ba4: %UInt.as.EqWith.impl.Equal.type.29b = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.3b6: %EqWith.type.c25 = facet_value %u1, (%EqWith.impl_witness.d63) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.922: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%u1, %EqWith.facet.3b6) [concrete]
// CHECK:STDOUT:   %.9ed: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.922, %EqWith.facet.3b6 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound.f34: <bound method> = bound_method %int_0.1a7, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.specific_fn.6b6: <specific function> = specific_function %UInt.as.EqWith.impl.Equal.ba4, @UInt.as.EqWith.impl.Equal.1(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.53a: <bound method> = bound_method %int_0.1a7, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a23: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.b3c, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.9f1: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a23) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.740: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet.9f1) [concrete]
// CHECK:STDOUT:   %.1c5: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.740, %ImplicitAs.facet.9f1 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.6e0: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_0.3c0: %i32 = int_value 0 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound.22c: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %bound_method.a82: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.953: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT:   %Negate.type: type = facet_type <@Negate> [concrete]
// CHECK:STDOUT:   %Negate.impl_witness: <witness> = impl_witness imports.%Negate.impl_witness_table [concrete]
// CHECK:STDOUT:   %Negate.facet: %Negate.type = facet_value Core.IntLiteral, (%Negate.impl_witness) [concrete]
// CHECK:STDOUT:   %Negate.WithSelf.Op.type.db1: type = fn_type @Negate.WithSelf.Op, @Negate.WithSelf(%Negate.facet) [concrete]
// CHECK:STDOUT:   %.e9b: type = fn_type_with_self_type %Negate.WithSelf.Op.type.db1, %Negate.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.type: type = fn_type @Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op: %Core.IntLiteral.as.Negate.impl.Op.type = struct_value () [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.bound.6a0: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %int_-1.638: Core.IntLiteral = int_value -1 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.65e: <bound method> = bound_method %int_-1.638, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.a65: <bound method> = bound_method %int_-1.638, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_-1.4ef: %i32 = int_value -1 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.aa5: @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.170)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.42f = impl_witness_table (%Core.import_ref.aa5), @Core.IntLiteral.as.ImplicitAs.impl.b68 [concrete]
// CHECK:STDOUT:   %Core.import_ref.791: @UInt.as.Copy.impl.%UInt.as.Copy.impl.Op.type (%UInt.as.Copy.impl.Op.type.0c5) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.Copy.impl.%UInt.as.Copy.impl.Op (constants.%UInt.as.Copy.impl.Op.38a)]
// CHECK:STDOUT:   %Copy.impl_witness_table.fe3 = impl_witness_table (%Core.import_ref.791), @UInt.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.b92: @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal.type (%UInt.as.EqWith.impl.Equal.type.544) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal (constants.%UInt.as.EqWith.impl.Equal.c67)]
// CHECK:STDOUT:   %Core.import_ref.b44 = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.cbd = impl_witness_table (%Core.import_ref.b92, %Core.import_ref.b44), @UInt.as.EqWith.impl.f13 [concrete]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.b3c = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.abd = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9c3: %Core.IntLiteral.as.Negate.impl.Op.type = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, loaded [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %Negate.impl_witness_table = impl_witness_table (%Core.import_ref.abd, %Core.import_ref.9c3), @Core.IntLiteral.as.Negate.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Flag.decl: type = class_decl @Flag [concrete = constants.%Flag] {} {}
// CHECK:STDOUT:   %Classify.decl: %Classify.type = fn_decl @Classify [concrete = constants.%Classify] {
// CHECK:STDOUT:     %f.param_patt: %pattern_type.5bc = value_param_pattern [concrete = constants.%f.param_patt]
// CHECK:STDOUT:     %f.patt: %pattern_type.5bc = at_binding_pattern f, %f.param_patt [concrete = constants.%f.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc12: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %f.param: %Flag = value_param call_param0
// CHECK:STDOUT:     %Flag.ref: type = name_ref Flag, file.%Flag.decl [concrete = constants.%Flag]
// CHECK:STDOUT:     %f: %Flag = wrapper_binding f, %f.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: class @Flag {
// CHECK:STDOUT:   %complete_type: <witness> = complete_type_witness constants.%struct_type.discriminant [concrete = constants.%complete_type.3a6]
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc5_6.1: %.e60 = impl_witness_access constants.%ImplicitAs.impl_witness.9a9, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc5_6.1: <bound method> = bound_method %int_0, %impl.elem0.loc5_6.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:   %specific_fn.loc5_6.1: <specific function> = specific_function %impl.elem0.loc5_6.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc5_6.2: <bound method> = bound_method %int_0, %specific_fn.loc5_6.1 [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc5: init %u1 = call %bound_method.loc5_6.2(%int_0) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc5_6.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc5 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc5_6.2: %u1 = converted %int_0, %.loc5_6.1 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc5_6.3: %struct_type.discriminant = struct_literal (%.loc5_6.2) [concrete = constants.%struct.249]
// CHECK:STDOUT:   %impl.elem0.loc5_6.2: %.37a = impl_witness_access constants.%Copy.impl_witness.fb7, element0 [concrete = constants.%UInt.as.Copy.impl.Op.d9c]
// CHECK:STDOUT:   %bound_method.loc5_6.3: <bound method> = bound_method %.loc5_6.2, %impl.elem0.loc5_6.2 [concrete = constants.%UInt.as.Copy.impl.Op.bound.bd0]
// CHECK:STDOUT:   %specific_fn.loc5_6.2: <specific function> = specific_function %impl.elem0.loc5_6.2, @UInt.as.Copy.impl.Op(constants.%int_1.5b8) [concrete = constants.%UInt.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc5_6.4: <bound method> = bound_method %.loc5_6.2, %specific_fn.loc5_6.2 [concrete = constants.%bound_method.61c]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.call.loc5: init %u1 = call %bound_method.loc5_6.4(%.loc5_6.2) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc5_6.4: ref %Flag = temporary_storage
// CHECK:STDOUT:   %.loc5_6.5: ref %u1 = class_element_access %.loc5_6.4, element0
// CHECK:STDOUT:   %.loc5_6.6: init %u1 to %.loc5_6.5 = in_place_init %UInt.as.Copy.impl.Op.call.loc5 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc5_6.7: init %Flag to %.loc5_6.4 = class_init (%.loc5_6.6) [concrete = constants.%Flag.val.246]
// CHECK:STDOUT:   %.loc5_6.8: init %Flag = converted %.loc5_6.3, %.loc5_6.7 [concrete = constants.%Flag.val.246]
// CHECK:STDOUT:   %.loc5_6.9: ref %Flag = temporary %.loc5_6.4, %.loc5_6.8 [concrete = constants.%.a8b]
// CHECK:STDOUT:   %.loc5_6.10: %Flag = acquire_value %.loc5_6.9 [concrete = constants.%Flag.val.246]
// CHECK:STDOUT:   %Off: %Flag = wrapper_binding Off, %.loc5_6.10
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc7_1.1: %.e60 = impl_witness_access constants.%ImplicitAs.impl_witness.9a9, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc7_1.1: <bound method> = bound_method %int_1, %impl.elem0.loc7_1.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc7_1.1: <specific function> = specific_function %impl.elem0.loc7_1.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc7_1.2: <bound method> = bound_method %int_1, %specific_fn.loc7_1.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc7: init %u1 = call %bound_method.loc7_1.2(%int_1) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc7_1.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc7 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc7_1.2: %u1 = converted %int_1, %.loc7_1.1 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc7_1.3: %struct_type.discriminant = struct_literal (%.loc7_1.2) [concrete = constants.%struct.a79]
// CHECK:STDOUT:   %impl.elem0.loc7_1.2: %.37a = impl_witness_access constants.%Copy.impl_witness.fb7, element0 [concrete = constants.%UInt.as.Copy.impl.Op.d9c]
// CHECK:STDOUT:   %bound_method.loc7_1.3: <bound method> = bound_method %.loc7_1.2, %impl.elem0.loc7_1.2 [concrete = constants.%UInt.as.Copy.impl.Op.bound.332]
// CHECK:STDOUT:   %specific_fn.loc7_1.2: <specific function> = specific_function %impl.elem0.loc7_1.2, @UInt.as.Copy.impl.Op(constants.%int_1.5b8) [concrete = constants.%UInt.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc7_1.4: <bound method> = bound_method %.loc7_1.2, %specific_fn.loc7_1.2 [concrete = constants.%bound_method.edd]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.call.loc7: init %u1 = call %bound_method.loc7_1.4(%.loc7_1.2) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc7_1.4: ref %Flag = temporary_storage
// CHECK:STDOUT:   %.loc7_1.5: ref %u1 = class_element_access %.loc7_1.4, element0
// CHECK:STDOUT:   %.loc7_1.6: init %u1 to %.loc7_1.5 = in_place_init %UInt.as.Copy.impl.Op.call.loc7 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc7_1.7: init %Flag to %.loc7_1.4 = class_init (%.loc7_1.6) [concrete = constants.%Flag.val.cba]
// CHECK:STDOUT:   %.loc7_1.8: init %Flag = converted %.loc7_1.3, %.loc7_1.7 [concrete = constants.%Flag.val.cba]
// CHECK:STDOUT:   %.loc7_1.9: ref %Flag = temporary %.loc7_1.4, %.loc7_1.8 [concrete = constants.%.c9b]
// CHECK:STDOUT:   %.loc7_1.10: %Flag = acquire_value %.loc7_1.9 [concrete = constants.%Flag.val.cba]
// CHECK:STDOUT:   %On: %Flag = wrapper_binding On, %.loc7_1.10
// CHECK:STDOUT:   complete_type_witness = %complete_type
// CHECK:STDOUT:
// CHECK:STDOUT: !members:
// CHECK:STDOUT:   .Self = constants.%Flag
// CHECK:STDOUT:   .Off = %Off
// CHECK:STDOUT:   .On = %On
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Classify(%f.param: %Flag) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %f.ref: %Flag = name_ref f, %f
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt.loc14: %pattern_type.5bc = expr_pattern %Off.ref in [concrete] {
// CHECK:STDOUT:       %Off.ref: %Flag = name_ref Off, @Flag.%Off
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Off.ref: %Flag = name_ref Off, @Flag.%Off
// CHECK:STDOUT:   %int_0.loc14_15: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc14_15.1: %.e60 = impl_witness_access constants.%ImplicitAs.impl_witness.9a9, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc14_15.1: <bound method> = bound_method %int_0.loc14_15, %impl.elem0.loc14_15.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:   %specific_fn.loc14_15.1: <specific function> = specific_function %impl.elem0.loc14_15.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc14_15.2: <bound method> = bound_method %int_0.loc14_15, %specific_fn.loc14_15.1 [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14_15: init %u1 = call %bound_method.loc14_15.2(%int_0.loc14_15) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc14_15.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14_15 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc14_15.2: %u1 = converted %int_0.loc14_15, %.loc14_15.1 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc14_15.3: ref %u1 = class_element_access %f.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc14_15.2: %.9ed = impl_witness_access constants.%EqWith.impl_witness.d63, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc14_15.3: <bound method> = bound_method %.loc14_15.2, %impl.elem0.loc14_15.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.f34]
// CHECK:STDOUT:   %specific_fn.loc14_15.2: <specific function> = specific_function %impl.elem0.loc14_15.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc14_15.4: <bound method> = bound_method %.loc14_15.2, %specific_fn.loc14_15.2 [concrete = constants.%bound_method.53a]
// CHECK:STDOUT:   %.loc14_15.4: %u1 = acquire_value %.loc14_15.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc14: init bool = call %bound_method.loc14_15.4(%.loc14_15.2, %.loc14_15.4)
// CHECK:STDOUT:   %.loc14_15.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc14
// CHECK:STDOUT:   %.loc14_15.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc14, %.loc14_15.5
// CHECK:STDOUT:   if %.loc14_15.6 br !match.case.then.loc14 else br !match.case.else.loc14
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc14:
// CHECK:STDOUT:   %int_0.loc14_27: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc14_28: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc14_28.1: <bound method> = bound_method %int_0.loc14_27, %impl.elem0.loc14_28 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc14_28: <specific function> = specific_function %impl.elem0.loc14_28, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc14_28.2: <bound method> = bound_method %int_0.loc14_27, %specific_fn.loc14_28 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14_28: init %i32 = call %bound_method.loc14_28.2(%int_0.loc14_27) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc14_28: init %i32 = converted %int_0.loc14_27, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14_28 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   return %.loc14_28
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc14:
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt.loc15: %pattern_type.5bc = expr_pattern %On.ref in [concrete] {
// CHECK:STDOUT:       %On.ref: %Flag = name_ref On, @Flag.%On
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %On.ref: %Flag = name_ref On, @Flag.%On
// CHECK:STDOUT:   %int_1.loc15_14: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc15_14.1: %.e60 = impl_witness_access constants.%ImplicitAs.impl_witness.9a9, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc15_14.1: <bound method> = bound_method %int_1.loc15_14, %impl.elem0.loc15_14.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc15_14.1: <specific function> = specific_function %impl.elem0.loc15_14.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc15_14.2: <bound method> = bound_method %int_1.loc15_14, %specific_fn.loc15_14.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc15_14: init %u1 = call %bound_method.loc15_14.2(%int_1.loc15_14) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc15_14.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc15_14 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc15_14.2: %u1 = converted %int_1.loc15_14, %.loc15_14.1 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc15_14.3: ref %u1 = class_element_access %f.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc15_14.2: %.9ed = impl_witness_access constants.%EqWith.impl_witness.d63, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc15_14.3: <bound method> = bound_method %.loc15_14.2, %impl.elem0.loc15_14.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.22c]
// CHECK:STDOUT:   %specific_fn.loc15_14.2: <specific function> = specific_function %impl.elem0.loc15_14.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc15_14.4: <bound method> = bound_method %.loc15_14.2, %specific_fn.loc15_14.2 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc15_14.4: %u1 = acquire_value %.loc15_14.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc15: init bool = call %bound_method.loc15_14.4(%.loc15_14.2, %.loc15_14.4)
// CHECK:STDOUT:   %.loc15_14.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc15
// CHECK:STDOUT:   %.loc15_14.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc15, %.loc15_14.5
// CHECK:STDOUT:   if %.loc15_14.6 br !match.case.then.loc15 else br !match.case.else.loc15
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc15:
// CHECK:STDOUT:   %int_1.loc15_26: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc15_27: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc15_27.1: <bound method> = bound_method %int_1.loc15_26, %impl.elem0.loc15_27 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc15_27: <specific function> = specific_function %impl.elem0.loc15_27, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc15_27.2: <bound method> = bound_method %int_1.loc15_26, %specific_fn.loc15_27 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc15_27: init %i32 = call %bound_method.loc15_27.2(%int_1.loc15_26) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc15_27: init %i32 = converted %int_1.loc15_26, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc15_27 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   return %.loc15_27
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc15:
// CHECK:STDOUT:   %int_1.loc16: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem1: %.e9b = impl_witness_access constants.%Negate.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %bound_method.loc16_25: <bound method> = bound_method %int_1.loc16, %impl.elem1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op.bound.6a0]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.call: init Core.IntLiteral = call %bound_method.loc16_25(%int_1.loc16) [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %impl.elem0.loc16: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc16_27.1: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %impl.elem0.loc16 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.65e]
// CHECK:STDOUT:   %specific_fn.loc16: <specific function> = specific_function %impl.elem0.loc16, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc16_27.2: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %specific_fn.loc16 [concrete = constants.%bound_method.a65]
// CHECK:STDOUT:   %.loc16_25.1: Core.IntLiteral = value_of_initializer %Core.IntLiteral.as.Negate.impl.Op.call [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %.loc16_25.2: Core.IntLiteral = converted %Core.IntLiteral.as.Negate.impl.Op.call, %.loc16_25.1 [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16: init %i32 = call %bound_method.loc16_27.2(%.loc16_25.2) [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   %.loc16_27: init %i32 = converted %Core.IntLiteral.as.Negate.impl.Op.call, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16 [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   return %.loc16_27
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- use_imported.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %Signal: type = class_type @Signal [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %tuple.type.a8a: type = tuple_type (%i32) [concrete]
// CHECK:STDOUT:   %.0fa: type = custom_layout_type {size=4, align=4, .Go@0: %tuple.type.a8a} [concrete]
// CHECK:STDOUT:   %int_2.ecc: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %u2: type = class_type @UInt, @UInt(%int_2.ecc) [concrete]
// CHECK:STDOUT:   %pattern_type.1de: type = pattern_type %Signal [concrete]
// CHECK:STDOUT:   %s.param_patt: %pattern_type.1de = value_param_pattern [concrete]
// CHECK:STDOUT:   %s.patt: %pattern_type.1de = at_binding_pattern s, %s.param_patt [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %Classify.type: type = fn_type @Classify [concrete]
// CHECK:STDOUT:   %Classify: %Classify.type = struct_value () [concrete]
// CHECK:STDOUT:   %speed.patt: %pattern_type.6b6 = value_binding_pattern speed [concrete]
// CHECK:STDOUT:   %pattern_type.e71: type = pattern_type %tuple.type.a8a [concrete]
// CHECK:STDOUT:   %.908: %pattern_type.e71 = tuple_pattern (%speed.patt) [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.452: type = facet_type <@ImplicitAs, @ImplicitAs(%u2)> [concrete]
// CHECK:STDOUT:   %To.fe9: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.170: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.e93: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.42f, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_2.ecc) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.d95: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_2.ecc) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.409: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.d95 = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.955: %ImplicitAs.type.452 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.e93) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.119: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%u2, %ImplicitAs.facet.955) [concrete]
// CHECK:STDOUT:   %.66c: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.119, %ImplicitAs.facet.955 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.941: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.409 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.a72: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.409, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(%int_2.ecc) [concrete]
// CHECK:STDOUT:   %bound_method.6ef: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.a72 [concrete]
// CHECK:STDOUT:   %int_0.336: %u2 = int_value 0 [concrete]
// CHECK:STDOUT:   %EqWith.type.f24: type = facet_type <@EqWith, @EqWith(%u2)> [concrete]
// CHECK:STDOUT:   %M: Core.IntLiteral = symbolic_binding M, 1 [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.544: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%N, %M) [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.c67: %UInt.as.EqWith.impl.Equal.type.544 = struct_value () [symbolic]
// CHECK:STDOUT:   %EqWith.impl_witness.454: <witness> = impl_witness imports.%EqWith.impl_witness_table.cbd, @UInt.as.EqWith.impl.f13(%int_2.ecc, %int_2.ecc) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.5fc: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%int_2.ecc, %int_2.ecc) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.e76: %UInt.as.EqWith.impl.Equal.type.5fc = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.16f: %EqWith.type.f24 = facet_value %u2, (%EqWith.impl_witness.454) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.c65: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%u2, %EqWith.facet.16f) [concrete]
// CHECK:STDOUT:   %.7a0: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.c65, %EqWith.facet.16f [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound.dac: <bound method> = bound_method %int_0.336, %UInt.as.EqWith.impl.Equal.e76 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.specific_fn.149: <specific function> = specific_function %UInt.as.EqWith.impl.Equal.e76, @UInt.as.EqWith.impl.Equal.1(%int_2.ecc, %int_2.ecc) [concrete]
// CHECK:STDOUT:   %bound_method.dad: <bound method> = bound_method %int_0.336, %UInt.as.EqWith.impl.Equal.specific_fn.149 [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.0e0: <witness> = impl_witness imports.%Copy.impl_witness_table.367, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet: %Copy.type = facet_value %i32, (%Copy.impl_witness.0e0) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.d09: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet) [concrete]
// CHECK:STDOUT:   %.7a6: type = fn_type_with_self_type %Copy.WithSelf.Op.type.d09, %Copy.facet [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %uninit: %.0fa = uninitialized_value [concrete]
// CHECK:STDOUT:   %int_1.508: %u2 = int_value 1 [concrete]
// CHECK:STDOUT:   %Signal.val.b94: %Signal = struct_value (%int_1.508, %uninit) [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.48e: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.409 [concrete]
// CHECK:STDOUT:   %bound_method.0f5: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.a72 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound.f51: <bound method> = bound_method %int_1.508, %UInt.as.EqWith.impl.Equal.e76 [concrete]
// CHECK:STDOUT:   %bound_method.1da: <bound method> = bound_method %int_1.508, %UInt.as.EqWith.impl.Equal.specific_fn.149 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a23: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.b3c, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.9f1: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a23) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.740: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet.9f1) [concrete]
// CHECK:STDOUT:   %.1c5: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.740, %ImplicitAs.facet.9f1 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.6e0: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_0.3c0: %i32 = int_value 0 [concrete]
// CHECK:STDOUT:   %int_2.996: %u2 = int_value 2 [concrete]
// CHECK:STDOUT:   %Signal.val.4b5: %Signal = struct_value (%int_2.996, %uninit) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.6c9: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.409 [concrete]
// CHECK:STDOUT:   %bound_method.135: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.a72 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound.99a: <bound method> = bound_method %int_2.996, %UInt.as.EqWith.impl.Equal.e76 [concrete]
// CHECK:STDOUT:   %bound_method.64f: <bound method> = bound_method %int_2.996, %UInt.as.EqWith.impl.Equal.specific_fn.149 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.953: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT:   %Negate.type: type = facet_type <@Negate> [concrete]
// CHECK:STDOUT:   %Negate.impl_witness: <witness> = impl_witness imports.%Negate.impl_witness_table [concrete]
// CHECK:STDOUT:   %Negate.facet: %Negate.type = facet_value Core.IntLiteral, (%Negate.impl_witness) [concrete]
// CHECK:STDOUT:   %Negate.WithSelf.Op.type.db1: type = fn_type @Negate.WithSelf.Op, @Negate.WithSelf(%Negate.facet) [concrete]
// CHECK:STDOUT:   %.e9b: type = fn_type_with_self_type %Negate.WithSelf.Op.type.db1, %Negate.facet [concrete]
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
// CHECK:STDOUT:   %Main.Signal: type = import_ref Main//signal, Signal, loaded [concrete = constants.%Signal]
// CHECK:STDOUT:   %Main.import_ref.f4b: %Signal = import_ref Main//signal, loc5_7, loaded [concrete = constants.%Signal.val.b94]
// CHECK:STDOUT:   %Main.import_ref.4f3: %Signal = import_ref Main//signal, loc7_1, loaded [concrete = constants.%Signal.val.4b5]
// CHECK:STDOUT:   %Core.import_ref.aa5: @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.170)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.42f = impl_witness_table (%Core.import_ref.aa5), @Core.IntLiteral.as.ImplicitAs.impl.b68 [concrete]
// CHECK:STDOUT:   %Core.import_ref.b92: @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal.type (%UInt.as.EqWith.impl.Equal.type.544) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal (constants.%UInt.as.EqWith.impl.Equal.c67)]
// CHECK:STDOUT:   %Core.import_ref.b44 = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.cbd = impl_witness_table (%Core.import_ref.b92, %Core.import_ref.b44), @UInt.as.EqWith.impl.f13 [concrete]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.367 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.b3c = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.abd = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9c3: %Core.IntLiteral.as.Negate.impl.Op.type = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, loaded [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %Negate.impl_witness_table = impl_witness_table (%Core.import_ref.abd, %Core.import_ref.9c3), @Core.IntLiteral.as.Negate.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Classify.decl: %Classify.type = fn_decl @Classify [concrete = constants.%Classify] {
// CHECK:STDOUT:     %s.param_patt: %pattern_type.1de = value_param_pattern [concrete = constants.%s.param_patt]
// CHECK:STDOUT:     %s.patt: %pattern_type.1de = at_binding_pattern s, %s.param_patt [concrete = constants.%s.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc10 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc10: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc10: Core.Form = init_form %i32.loc10 [concrete = constants.%.795f]
// CHECK:STDOUT:     %s.param: %Signal = value_param call_param0
// CHECK:STDOUT:     %Signal.ref: type = name_ref Signal, imports.%Main.Signal [concrete = constants.%Signal]
// CHECK:STDOUT:     %s: %Signal = wrapper_binding s, %s.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Classify(%s.param: %Signal) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %s.ref: %Signal = name_ref s, %s
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %speed.patt: %pattern_type.6b6 = value_binding_pattern speed [concrete = constants.%speed.patt]
// CHECK:STDOUT:     %.loc12_19: %pattern_type.e71 = tuple_pattern (%speed.patt) [concrete = constants.%.908]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_0.loc12: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc12_26.1: %.66c = impl_witness_access constants.%ImplicitAs.impl_witness.e93, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.409]
// CHECK:STDOUT:   %bound_method.loc12_26.1: <bound method> = bound_method %int_0.loc12, %impl.elem0.loc12_26.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.941]
// CHECK:STDOUT:   %specific_fn.loc12_26.1: <specific function> = specific_function %impl.elem0.loc12_26.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_2.ecc) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.a72]
// CHECK:STDOUT:   %bound_method.loc12_26.2: <bound method> = bound_method %int_0.loc12, %specific_fn.loc12_26.1 [concrete = constants.%bound_method.6ef]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc12: init %u2 = call %bound_method.loc12_26.2(%int_0.loc12) [concrete = constants.%int_0.336]
// CHECK:STDOUT:   %.loc12_26.1: %u2 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc12 [concrete = constants.%int_0.336]
// CHECK:STDOUT:   %.loc12_26.2: %u2 = converted %int_0.loc12, %.loc12_26.1 [concrete = constants.%int_0.336]
// CHECK:STDOUT:   %.loc12_26.3: ref %u2 = class_element_access %s.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc12_26.2: %.7a0 = impl_witness_access constants.%EqWith.impl_witness.454, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.e76]
// CHECK:STDOUT:   %bound_method.loc12_26.3: <bound method> = bound_method %.loc12_26.2, %impl.elem0.loc12_26.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.dac]
// CHECK:STDOUT:   %specific_fn.loc12_26.2: <specific function> = specific_function %impl.elem0.loc12_26.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_2.ecc, constants.%int_2.ecc) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.149]
// CHECK:STDOUT:   %bound_method.loc12_26.4: <bound method> = bound_method %.loc12_26.2, %specific_fn.loc12_26.2 [concrete = constants.%bound_method.dad]
// CHECK:STDOUT:   %.loc12_26.4: %u2 = acquire_value %.loc12_26.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc12: init bool = call %bound_method.loc12_26.4(%.loc12_26.2, %.loc12_26.4)
// CHECK:STDOUT:   %.loc12_26.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc12
// CHECK:STDOUT:   %.loc12_26.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc12, %.loc12_26.5
// CHECK:STDOUT:   if %.loc12_26.6 br !match.case.then.loc12 else br !match.case.else.loc12
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc12:
// CHECK:STDOUT:   %.loc12_26.7: ref %.0fa = class_element_access %s.ref, element1
// CHECK:STDOUT:   %.loc12_26.8: ref %tuple.type.a8a = class_element_access %.loc12_26.7, element0
// CHECK:STDOUT:   %tuple.elem0: ref %i32 = tuple_access %.loc12_26.8, element0
// CHECK:STDOUT:   %.loc12_26.9: %i32 = acquire_value %tuple.elem0
// CHECK:STDOUT:   %i32.loc12: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %speed: %i32 = wrapper_binding speed, %.loc12_26.9
// CHECK:STDOUT:   %speed.ref: %i32 = name_ref speed, %speed
// CHECK:STDOUT:   %impl.elem0.loc12_38: %.7a6 = impl_witness_access constants.%Copy.impl_witness.0e0, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc12_38.1: <bound method> = bound_method %speed.ref, %impl.elem0.loc12_38
// CHECK:STDOUT:   %specific_fn.loc12_38: <specific function> = specific_function %impl.elem0.loc12_38, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc12_38.2: <bound method> = bound_method %speed.ref, %specific_fn.loc12_38
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc12_38.2(%speed.ref)
// CHECK:STDOUT:   return %Int.as.Copy.impl.Op.call
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc12:
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt.loc13: %pattern_type.1de = expr_pattern %Stop.ref in [concrete] {
// CHECK:STDOUT:       %Stop.ref: %Signal = name_ref Stop, imports.%Main.import_ref.f4b [concrete = constants.%Signal.val.b94]
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Stop.ref: %Signal = name_ref Stop, imports.%Main.import_ref.f4b [concrete = constants.%Signal.val.b94]
// CHECK:STDOUT:   %int_1.loc13: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc13_16.1: %.66c = impl_witness_access constants.%ImplicitAs.impl_witness.e93, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.409]
// CHECK:STDOUT:   %bound_method.loc13_16.1: <bound method> = bound_method %int_1.loc13, %impl.elem0.loc13_16.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.48e]
// CHECK:STDOUT:   %specific_fn.loc13_16.1: <specific function> = specific_function %impl.elem0.loc13_16.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_2.ecc) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.a72]
// CHECK:STDOUT:   %bound_method.loc13_16.2: <bound method> = bound_method %int_1.loc13, %specific_fn.loc13_16.1 [concrete = constants.%bound_method.0f5]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13_16: init %u2 = call %bound_method.loc13_16.2(%int_1.loc13) [concrete = constants.%int_1.508]
// CHECK:STDOUT:   %.loc13_16.1: %u2 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13_16 [concrete = constants.%int_1.508]
// CHECK:STDOUT:   %.loc13_16.2: %u2 = converted %int_1.loc13, %.loc13_16.1 [concrete = constants.%int_1.508]
// CHECK:STDOUT:   %.loc13_16.3: ref %u2 = class_element_access %s.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc13_16.2: %.7a0 = impl_witness_access constants.%EqWith.impl_witness.454, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.e76]
// CHECK:STDOUT:   %bound_method.loc13_16.3: <bound method> = bound_method %.loc13_16.2, %impl.elem0.loc13_16.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.f51]
// CHECK:STDOUT:   %specific_fn.loc13_16.2: <specific function> = specific_function %impl.elem0.loc13_16.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_2.ecc, constants.%int_2.ecc) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.149]
// CHECK:STDOUT:   %bound_method.loc13_16.4: <bound method> = bound_method %.loc13_16.2, %specific_fn.loc13_16.2 [concrete = constants.%bound_method.1da]
// CHECK:STDOUT:   %.loc13_16.4: %u2 = acquire_value %.loc13_16.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc13: init bool = call %bound_method.loc13_16.4(%.loc13_16.2, %.loc13_16.4)
// CHECK:STDOUT:   %.loc13_16.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc13
// CHECK:STDOUT:   %.loc13_16.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc13, %.loc13_16.5
// CHECK:STDOUT:   if %.loc13_16.6 br !match.case.then.loc13 else br !match.case.else.loc13
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc13:
// CHECK:STDOUT:   %int_0.loc13: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc13_29: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc13_29.1: <bound method> = bound_method %int_0.loc13, %impl.elem0.loc13_29 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc13_29: <specific function> = specific_function %impl.elem0.loc13_29, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc13_29.2: <bound method> = bound_method %int_0.loc13, %specific_fn.loc13_29 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13_29: init %i32 = call %bound_method.loc13_29.2(%int_0.loc13) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc13_29: init %i32 = converted %int_0.loc13, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13_29 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   return %.loc13_29
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc13:
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt.loc14: %pattern_type.1de = expr_pattern %Wait.ref in [concrete] {
// CHECK:STDOUT:       %Wait.ref: %Signal = name_ref Wait, imports.%Main.import_ref.4f3 [concrete = constants.%Signal.val.4b5]
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Wait.ref: %Signal = name_ref Wait, imports.%Main.import_ref.4f3 [concrete = constants.%Signal.val.4b5]
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:   %impl.elem0.loc14_16.1: %.66c = impl_witness_access constants.%ImplicitAs.impl_witness.e93, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.409]
// CHECK:STDOUT:   %bound_method.loc14_16.1: <bound method> = bound_method %int_2, %impl.elem0.loc14_16.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.6c9]
// CHECK:STDOUT:   %specific_fn.loc14_16.1: <specific function> = specific_function %impl.elem0.loc14_16.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_2.ecc) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.a72]
// CHECK:STDOUT:   %bound_method.loc14_16.2: <bound method> = bound_method %int_2, %specific_fn.loc14_16.1 [concrete = constants.%bound_method.135]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14_16: init %u2 = call %bound_method.loc14_16.2(%int_2) [concrete = constants.%int_2.996]
// CHECK:STDOUT:   %.loc14_16.1: %u2 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14_16 [concrete = constants.%int_2.996]
// CHECK:STDOUT:   %.loc14_16.2: %u2 = converted %int_2, %.loc14_16.1 [concrete = constants.%int_2.996]
// CHECK:STDOUT:   %.loc14_16.3: ref %u2 = class_element_access %s.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc14_16.2: %.7a0 = impl_witness_access constants.%EqWith.impl_witness.454, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.e76]
// CHECK:STDOUT:   %bound_method.loc14_16.3: <bound method> = bound_method %.loc14_16.2, %impl.elem0.loc14_16.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.99a]
// CHECK:STDOUT:   %specific_fn.loc14_16.2: <specific function> = specific_function %impl.elem0.loc14_16.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_2.ecc, constants.%int_2.ecc) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.149]
// CHECK:STDOUT:   %bound_method.loc14_16.4: <bound method> = bound_method %.loc14_16.2, %specific_fn.loc14_16.2 [concrete = constants.%bound_method.64f]
// CHECK:STDOUT:   %.loc14_16.4: %u2 = acquire_value %.loc14_16.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc14: init bool = call %bound_method.loc14_16.4(%.loc14_16.2, %.loc14_16.4)
// CHECK:STDOUT:   %.loc14_16.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc14
// CHECK:STDOUT:   %.loc14_16.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc14, %.loc14_16.5
// CHECK:STDOUT:   if %.loc14_16.6 br !match.case.then.loc14 else br !match.case.else.loc14
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc14:
// CHECK:STDOUT:   %int_1.loc14: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc14_29: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc14_29.1: <bound method> = bound_method %int_1.loc14, %impl.elem0.loc14_29 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc14_29: <specific function> = specific_function %impl.elem0.loc14_29, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc14_29.2: <bound method> = bound_method %int_1.loc14, %specific_fn.loc14_29 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14_29: init %i32 = call %bound_method.loc14_29.2(%int_1.loc14) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc14_29: init %i32 = converted %int_1.loc14, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14_29 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   return %.loc14_29
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc14:
// CHECK:STDOUT:   br !match.done
// CHECK:STDOUT:
// CHECK:STDOUT: !match.done:
// CHECK:STDOUT:   %int_1.loc16: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem1: %.e9b = impl_witness_access constants.%Negate.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %bound_method.loc16_10: <bound method> = bound_method %int_1.loc16, %impl.elem1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op.bound]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.call: init Core.IntLiteral = call %bound_method.loc16_10(%int_1.loc16) [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %impl.elem0.loc16: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc16_12.1: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %impl.elem0.loc16 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.65e]
// CHECK:STDOUT:   %specific_fn.loc16: <specific function> = specific_function %impl.elem0.loc16, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc16_12.2: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %specific_fn.loc16 [concrete = constants.%bound_method.a65]
// CHECK:STDOUT:   %.loc16_10.1: Core.IntLiteral = value_of_initializer %Core.IntLiteral.as.Negate.impl.Op.call [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %.loc16_10.2: Core.IntLiteral = converted %Core.IntLiteral.as.Negate.impl.Op.call, %.loc16_10.1 [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16: init %i32 = call %bound_method.loc16_12.2(%.loc16_10.2) [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   %.loc16_12: init %i32 = converted %Core.IntLiteral.as.Negate.impl.Op.call, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16 [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   return %.loc16_12
// CHECK:STDOUT: }
// CHECK:STDOUT:
