// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/guarded_default.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/guarded_default.carbon

// Guards on `default` clauses (`default if (E) => ...`, W-067): `default`
// is equivalent to `case _: auto`, and "this facility is also available for
// `default` clauses" (docs/design/pattern_matching.md, "Guards";
// p2188:552-553). A guarded `default` arm reuses the case-guard
// capture-splice-branch shape with no pattern test and no bindings: a
// constant-true condition enters the arm, the spliced guard branches into
// the arm's body or on to the else block, and a failed guard falls through
// to a following arm or `default` — so, unlike an unguarded `default`,
// arms after it are reachable and permitted.

// --- basic.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
// A guarded `default` between other arms, its guard referencing the
// enclosing scope. Expected SemIR shape per arm: the guarded `default`'s
// test block holds a constant-`true` `BranchIf` into the arm-entry block,
// where the guard's converted-to-`bool` region is spliced
// (`splice_block`), followed by `BranchIf` into the body and a branch to
// the else block — the guarded-irrefutable-arm CFG from guard.carbon's
// `Binding`, minus the `NameBindingDecl`'s bindings and the bind pass.
// A failed guard falls through to `case 1`, then to the trailing guarded
// `default`, then to the final unguarded `default`.
fn Classify(x: i32) -> i32 {
  match (x) {
    case 0 => { return 0; }
    default if (x < 0) => { return 1; }
    case 1 => { return 2; }
    default if (x > 10) => { return 3; }
    default => { return 4; }
  }
  return -1;
}
//@dump-sem-ir-end

// --- compound_guard.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
// A short-circuiting guard on a `default`: the captured region is
// multi-block, so the splice is a branch into the region's blocks rather
// than a `splice_block` (guard.carbon's `Compound` shape, on the
// `default` path).
fn InRange(x: i32) -> i32 {
  match (x) {
    default if (x > 0 and x < 10) => { return 1; }
    default => { return 0; }
  }
  return -1;
}
//@dump-sem-ir-end

// --- choice_coverage.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
choice Flag {
  Off,
  On
}

// A guarded `default` records nothing toward exhaustiveness (guarded arms
// never count toward coverage), but it also does not interrupt it: the
// unguarded `.Off` and `.On` arms around it cover the choice, so no
// unguarded `default` is required even though the guarded `default` can
// fail (S2e; the negative pin is fail_guarded_default.carbon).
fn Classify(f: Flag, x: i32) -> i32 {
  match (f) {
    case .Off => { return 0; }
    default if (x > 0) => { return 2; }
    case .On => { return 1; }
  }
  return -1;
}
//@dump-sem-ir-end

// --- trailing_guarded_default.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
choice Flag {
  Off,
  On
}

// A choice FULLY covered by unguarded case arms with a TRAILING guarded
// `default`: legal, because coverage is already complete without the
// guarded arm (which records nothing toward exhaustiveness). This pins
// the guarded `default`'s else edge when no arm follows it: the
// guard-failure edge branches to the match statement's top empty else
// block, converging with the other arms.
fn Classify(f: Flag, x: i32) -> i32 {
  match (f) {
    case .Off => { return 0; }
    case .On => { return 1; }
    default if (x > 0) => { return 2; }
  }
  return -1;
}
//@dump-sem-ir-end

// CHECK:STDOUT: --- basic.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %Int.67af24.1: type = class_type @Int, @Int(%N) [symbolic]
// CHECK:STDOUT:   %pattern_type.dc0: type = pattern_type Core.IntLiteral [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %x.param_patt: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %x.patt: %pattern_type.6b6 = at_binding_pattern x, %x.param_patt [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %Classify.type: type = fn_type @Classify [concrete]
// CHECK:STDOUT:   %Classify: %Classify.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %EqWith.type.8ee: type = facet_type <@EqWith, @EqWith(%i32)> [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.f7de31.1: type = facet_type <@ImplicitAs, @ImplicitAs(%Int.67af24.1)> [symbolic]
// CHECK:STDOUT:   %T.4e6: %ImplicitAs.type.f7de31.1 = symbolic_binding T, 1 [symbolic]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.type.8af025.1: type = fn_type @T.as_type.as.EqWith.impl.Equal.1, @T.as_type.as.EqWith.impl(%N, %T.4e6) [symbolic]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.c477d6.1: %T.as_type.as.EqWith.impl.Equal.type.8af025.1 = struct_value () [symbolic]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.type.8af025.2: type = fn_type @T.as_type.as.EqWith.impl.Equal.2, @T.as_type.as.EqWith.impl(%N, %T.4e6) [symbolic]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.c477d6.2: %T.as_type.as.EqWith.impl.Equal.type.8af025.2 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %To: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %EqWith.impl_witness.bde: <witness> = impl_witness imports.%EqWith.impl_witness_table.532, @T.as_type.as.EqWith.impl(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.1: type = fn_type @T.as_type.as.EqWith.impl.Equal.2, @T.as_type.as.EqWith.impl(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.57b831.1: %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.1 = struct_value () [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.2: type = fn_type @T.as_type.as.EqWith.impl.Equal.1, @T.as_type.as.EqWith.impl(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.57b831.2: %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.2 = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.eb2: %EqWith.type.8ee = facet_value Core.IntLiteral, (%EqWith.impl_witness.bde) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.a21: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%i32, %EqWith.facet.eb2) [concrete]
// CHECK:STDOUT:   %.025: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.a21, %EqWith.facet.eb2 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound.e051da.1: <bound method> = bound_method %int_0.5c6, %T.as_type.as.EqWith.impl.Equal.57b831.2 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.1: <specific function> = specific_function %T.as_type.as.EqWith.impl.Equal.57b831.2, @T.as_type.as.EqWith.impl.Equal.1(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %bound_method.b3bca7.1: <bound method> = bound_method %int_0.5c6, %T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.1 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound.e051da.2: <bound method> = bound_method %int_0.5c6, %T.as_type.as.EqWith.impl.Equal.57b831.1 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.2: <specific function> = specific_function %T.as_type.as.EqWith.impl.Equal.57b831.1, @T.as_type.as.EqWith.impl.Equal.2(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %bound_method.b3bca7.2: <bound method> = bound_method %int_0.5c6, %T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.2 [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.6e0: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_0.3c0: %i32 = int_value 0 [concrete]
// CHECK:STDOUT:   %OrderedWith.type.975: type = facet_type <@OrderedWith, @OrderedWith(Core.IntLiteral)> [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.type.18c27f.1: type = fn_type @Int.as.OrderedWith.impl.Greater.2, @Int.as.OrderedWith.impl.f36(%N, %T.4e6) [symbolic]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.cbccb6.1: %Int.as.OrderedWith.impl.Greater.type.18c27f.1 = struct_value () [symbolic]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Less.type.6605e2.1: type = fn_type @Int.as.OrderedWith.impl.Less.2, @Int.as.OrderedWith.impl.f36(%N, %T.4e6) [symbolic]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Less.59643b.1: %Int.as.OrderedWith.impl.Less.type.6605e2.1 = struct_value () [symbolic]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.type.18c27f.2: type = fn_type @Int.as.OrderedWith.impl.Greater.3, @Int.as.OrderedWith.impl.f36(%N, %T.4e6) [symbolic]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.cbccb6.2: %Int.as.OrderedWith.impl.Greater.type.18c27f.2 = struct_value () [symbolic]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Less.type.6605e2.2: type = fn_type @Int.as.OrderedWith.impl.Less.3, @Int.as.OrderedWith.impl.f36(%N, %T.4e6) [symbolic]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Less.59643b.2: %Int.as.OrderedWith.impl.Less.type.6605e2.2 = struct_value () [symbolic]
// CHECK:STDOUT:   %OrderedWith.impl_witness.480: <witness> = impl_witness imports.%OrderedWith.impl_witness_table.100, @Int.as.OrderedWith.impl.f36(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Less.type.4f4a1d.1: type = fn_type @Int.as.OrderedWith.impl.Less.3, @Int.as.OrderedWith.impl.f36(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Less.164caf.1: %Int.as.OrderedWith.impl.Less.type.4f4a1d.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.type.a79f39.1: type = fn_type @Int.as.OrderedWith.impl.Greater.3, @Int.as.OrderedWith.impl.f36(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.e68ae3.1: %Int.as.OrderedWith.impl.Greater.type.a79f39.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Less.type.4f4a1d.2: type = fn_type @Int.as.OrderedWith.impl.Less.2, @Int.as.OrderedWith.impl.f36(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Less.164caf.2: %Int.as.OrderedWith.impl.Less.type.4f4a1d.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.type.a79f39.2: type = fn_type @Int.as.OrderedWith.impl.Greater.2, @Int.as.OrderedWith.impl.f36(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.e68ae3.2: %Int.as.OrderedWith.impl.Greater.type.a79f39.2 = struct_value () [concrete]
// CHECK:STDOUT:   %OrderedWith.facet.e90: %OrderedWith.type.975 = facet_value %i32, (%OrderedWith.impl_witness.480) [concrete]
// CHECK:STDOUT:   %OrderedWith.WithSelf.Less.type.3dc: type = fn_type @OrderedWith.WithSelf.Less, @OrderedWith.WithSelf(Core.IntLiteral, %OrderedWith.facet.e90) [concrete]
// CHECK:STDOUT:   %OrderedWith.WithSelf.Greater.type.e1c: type = fn_type @OrderedWith.WithSelf.Greater, @OrderedWith.WithSelf(Core.IntLiteral, %OrderedWith.facet.e90) [concrete]
// CHECK:STDOUT:   %.c7f: type = fn_type_with_self_type %OrderedWith.WithSelf.Less.type.3dc, %OrderedWith.facet.e90 [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Less.specific_fn.30cd42.1: <specific function> = specific_function %Int.as.OrderedWith.impl.Less.164caf.2, @Int.as.OrderedWith.impl.Less.2(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Less.specific_fn.30cd42.2: <specific function> = specific_function %Int.as.OrderedWith.impl.Less.164caf.1, @Int.as.OrderedWith.impl.Less.3(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.953: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound.29e975.1: <bound method> = bound_method %int_1.5b8, %T.as_type.as.EqWith.impl.Equal.57b831.2 [concrete]
// CHECK:STDOUT:   %bound_method.42af37.1: <bound method> = bound_method %int_1.5b8, %T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.1 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound.29e975.2: <bound method> = bound_method %int_1.5b8, %T.as_type.as.EqWith.impl.Equal.57b831.1 [concrete]
// CHECK:STDOUT:   %bound_method.42af37.2: <bound method> = bound_method %int_1.5b8, %T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.2 [concrete]
// CHECK:STDOUT:   %int_2.ecc: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.9f3: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.3cb: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_2.295: %i32 = int_value 2 [concrete]
// CHECK:STDOUT:   %int_10.64f: Core.IntLiteral = int_value 10 [concrete]
// CHECK:STDOUT:   %.029: type = fn_type_with_self_type %OrderedWith.WithSelf.Greater.type.e1c, %OrderedWith.facet.e90 [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.specific_fn.e2f732.1: <specific function> = specific_function %Int.as.OrderedWith.impl.Greater.e68ae3.2, @Int.as.OrderedWith.impl.Greater.2(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.specific_fn.e2f732.2: <specific function> = specific_function %Int.as.OrderedWith.impl.Greater.e68ae3.1, @Int.as.OrderedWith.impl.Greater.3(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.dcb: <bound method> = bound_method %int_10.64f, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.1b6: <bound method> = bound_method %int_10.64f, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_10.6bf: %i32 = int_value 10 [concrete]
// CHECK:STDOUT:   %int_3.1ba: Core.IntLiteral = int_value 3 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.485: <bound method> = bound_method %int_3.1ba, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.763: <bound method> = bound_method %int_3.1ba, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_3.410: %i32 = int_value 3 [concrete]
// CHECK:STDOUT:   %int_4.0c1: Core.IntLiteral = int_value 4 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.aad: <bound method> = bound_method %int_4.0c1, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.b7a: <bound method> = bound_method %int_4.0c1, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_4.4eb: %i32 = int_value 4 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.a9a: @T.as_type.as.EqWith.impl.%T.as_type.as.EqWith.impl.Equal.type.2 (%T.as_type.as.EqWith.impl.Equal.type.8af025.1) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @T.as_type.as.EqWith.impl.%T.as_type.as.EqWith.impl.Equal.2 (constants.%T.as_type.as.EqWith.impl.Equal.c477d6.1)]
// CHECK:STDOUT:   %Core.import_ref.712 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.532 = impl_witness_table (%Core.import_ref.a9a, %Core.import_ref.712), @T.as_type.as.EqWith.impl [concrete]
// CHECK:STDOUT:   %Core.Equal.970: @T.as_type.as.EqWith.impl.%T.as_type.as.EqWith.impl.Equal.type.1 (%T.as_type.as.EqWith.impl.Equal.type.8af025.2) = import_ref Core//prelude/types/int, Equal, loaded [symbolic = @T.as_type.as.EqWith.impl.%T.as_type.as.EqWith.impl.Equal.1 (constants.%T.as_type.as.EqWith.impl.Equal.c477d6.2)]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.1dc: @Int.as.OrderedWith.impl.f36.%Int.as.OrderedWith.impl.Less.type.2 (%Int.as.OrderedWith.impl.Less.type.6605e2.1) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.OrderedWith.impl.f36.%Int.as.OrderedWith.impl.Less.2 (constants.%Int.as.OrderedWith.impl.Less.59643b.1)]
// CHECK:STDOUT:   %Core.import_ref.f9d = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.0ab: @Int.as.OrderedWith.impl.f36.%Int.as.OrderedWith.impl.Greater.type.2 (%Int.as.OrderedWith.impl.Greater.type.18c27f.1) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.OrderedWith.impl.f36.%Int.as.OrderedWith.impl.Greater.2 (constants.%Int.as.OrderedWith.impl.Greater.cbccb6.1)]
// CHECK:STDOUT:   %Core.import_ref.b56 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %OrderedWith.impl_witness_table.100 = impl_witness_table (%Core.import_ref.1dc, %Core.import_ref.f9d, %Core.import_ref.0ab, %Core.import_ref.b56), @Int.as.OrderedWith.impl.f36 [concrete]
// CHECK:STDOUT:   %Core.Less.80e: @Int.as.OrderedWith.impl.f36.%Int.as.OrderedWith.impl.Less.type.1 (%Int.as.OrderedWith.impl.Less.type.6605e2.2) = import_ref Core//prelude/types/int, Less, loaded [symbolic = @Int.as.OrderedWith.impl.f36.%Int.as.OrderedWith.impl.Less.1 (constants.%Int.as.OrderedWith.impl.Less.59643b.2)]
// CHECK:STDOUT:   %Core.Greater.28d: @Int.as.OrderedWith.impl.f36.%Int.as.OrderedWith.impl.Greater.type.1 (%Int.as.OrderedWith.impl.Greater.type.18c27f.2) = import_ref Core//prelude/types/int, Greater, loaded [symbolic = @Int.as.OrderedWith.impl.f36.%Int.as.OrderedWith.impl.Greater.1 (constants.%Int.as.OrderedWith.impl.Greater.cbccb6.2)]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Classify.decl: %Classify.type = fn_decl @Classify [concrete = constants.%Classify] {
// CHECK:STDOUT:     %x.param_patt: %pattern_type.6b6 = value_param_pattern [concrete = constants.%x.param_patt]
// CHECK:STDOUT:     %x.patt: %pattern_type.6b6 = at_binding_pattern x, %x.param_patt [concrete = constants.%x.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc13_24 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc13_24: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc13: Core.Form = init_form %i32.loc13_24 [concrete = constants.%.795f]
// CHECK:STDOUT:     %x.param: %i32 = value_param call_param0
// CHECK:STDOUT:     %i32.loc13_16: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %x: %i32 = wrapper_binding x, %x.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Classify(%x.param: %i32) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %x.ref.loc14: %i32 = name_ref x, %x
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt.loc15: %pattern_type.dc0 = expr_pattern %int_0.loc15_10 in [concrete] {
// CHECK:STDOUT:       %int_0.loc15_10: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_0.loc15_10: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc15_12: %.025 = impl_witness_access constants.%EqWith.impl_witness.bde, element0 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.57b831.2]
// CHECK:STDOUT:   %bound_method.loc15_12.1: <bound method> = bound_method %int_0.loc15_10, %impl.elem0.loc15_12 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.bound.e051da.1]
// CHECK:STDOUT:   %specific_fn.loc15_12: <specific function> = specific_function %impl.elem0.loc15_12, @T.as_type.as.EqWith.impl.Equal.1(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.1]
// CHECK:STDOUT:   %bound_method.loc15_12.2: <bound method> = bound_method %int_0.loc15_10, %specific_fn.loc15_12 [concrete = constants.%bound_method.b3bca7.1]
// CHECK:STDOUT:   %.loc15_12.1: %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.1 = specific_constant imports.%Core.Equal.970, @T.as_type.as.EqWith.impl(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.57b831.1]
// CHECK:STDOUT:   %Equal.ref.loc15: %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.1 = name_ref Equal, %.loc15_12.1 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.57b831.1]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound.loc15: <bound method> = bound_method %int_0.loc15_10, %Equal.ref.loc15 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.bound.e051da.2]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.specific_fn.loc15: <specific function> = specific_function %Equal.ref.loc15, @T.as_type.as.EqWith.impl.Equal.2(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.2]
// CHECK:STDOUT:   %bound_method.loc15_12.3: <bound method> = bound_method %int_0.loc15_10, %T.as_type.as.EqWith.impl.Equal.specific_fn.loc15 [concrete = constants.%bound_method.b3bca7.2]
// CHECK:STDOUT:   %impl.elem0.loc15_10: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc15_10.1: <bound method> = bound_method %int_0.loc15_10, %impl.elem0.loc15_10 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc15_10: <specific function> = specific_function %impl.elem0.loc15_10, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc15_10.2: <bound method> = bound_method %int_0.loc15_10, %specific_fn.loc15_10 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc15_10: init %i32 = call %bound_method.loc15_10.2(%int_0.loc15_10) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc15_10.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc15_10 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc15_10.2: %i32 = converted %int_0.loc15_10, %.loc15_10.1 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.call.loc15: init bool = call %bound_method.loc15_12.3(%.loc15_10.2, %x.ref.loc14)
// CHECK:STDOUT:   %.loc15_12.2: bool = value_of_initializer %T.as_type.as.EqWith.impl.Equal.call.loc15
// CHECK:STDOUT:   %.loc15_12.3: bool = converted %T.as_type.as.EqWith.impl.Equal.call.loc15, %.loc15_12.2
// CHECK:STDOUT:   if %.loc15_12.3 br !match.case.then.loc15 else br !match.case.else.loc15
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc15:
// CHECK:STDOUT:   %int_0.loc15_24: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc15_25: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc15_25.1: <bound method> = bound_method %int_0.loc15_24, %impl.elem0.loc15_25 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc15_25: <specific function> = specific_function %impl.elem0.loc15_25, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc15_25.2: <bound method> = bound_method %int_0.loc15_24, %specific_fn.loc15_25 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc15_25: init %i32 = call %bound_method.loc15_25.2(%int_0.loc15_24) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc15_25: init %i32 = converted %int_0.loc15_24, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc15_25 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   return %.loc15_25
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc15:
// CHECK:STDOUT:   %true.loc16: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:   if %true.loc16 br !match.default.then.loc16_24.1 else br !match.default.else.loc16
// CHECK:STDOUT:
// CHECK:STDOUT: !match.default.then.loc16_24.1:
// CHECK:STDOUT:   %.loc16_19.1: bool = splice_block %.loc16_19.4 {
// CHECK:STDOUT:     %x.ref.loc16: %i32 = name_ref x, %x
// CHECK:STDOUT:     %int_0.loc16: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:     %impl.elem0.loc16_19: %.c7f = impl_witness_access constants.%OrderedWith.impl_witness.480, element0 [concrete = constants.%Int.as.OrderedWith.impl.Less.164caf.2]
// CHECK:STDOUT:     %bound_method.loc16_19.1: <bound method> = bound_method %x.ref.loc16, %impl.elem0.loc16_19
// CHECK:STDOUT:     %specific_fn.loc16_19: <specific function> = specific_function %impl.elem0.loc16_19, @Int.as.OrderedWith.impl.Less.2(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%Int.as.OrderedWith.impl.Less.specific_fn.30cd42.1]
// CHECK:STDOUT:     %bound_method.loc16_19.2: <bound method> = bound_method %x.ref.loc16, %specific_fn.loc16_19
// CHECK:STDOUT:     %.loc16_19.2: %Int.as.OrderedWith.impl.Less.type.4f4a1d.1 = specific_constant imports.%Core.Less.80e, @Int.as.OrderedWith.impl.f36(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%Int.as.OrderedWith.impl.Less.164caf.1]
// CHECK:STDOUT:     %Less.ref: %Int.as.OrderedWith.impl.Less.type.4f4a1d.1 = name_ref Less, %.loc16_19.2 [concrete = constants.%Int.as.OrderedWith.impl.Less.164caf.1]
// CHECK:STDOUT:     %Int.as.OrderedWith.impl.Less.bound: <bound method> = bound_method %x.ref.loc16, %Less.ref
// CHECK:STDOUT:     %Int.as.OrderedWith.impl.Less.specific_fn: <specific function> = specific_function %Less.ref, @Int.as.OrderedWith.impl.Less.3(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%Int.as.OrderedWith.impl.Less.specific_fn.30cd42.2]
// CHECK:STDOUT:     %bound_method.loc16_19.3: <bound method> = bound_method %x.ref.loc16, %Int.as.OrderedWith.impl.Less.specific_fn
// CHECK:STDOUT:     %impl.elem0.loc16_21: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:     %bound_method.loc16_21.1: <bound method> = bound_method %int_0.loc16, %impl.elem0.loc16_21 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:     %specific_fn.loc16_21: <specific function> = specific_function %impl.elem0.loc16_21, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:     %bound_method.loc16_21.2: <bound method> = bound_method %int_0.loc16, %specific_fn.loc16_21 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16_21: init %i32 = call %bound_method.loc16_21.2(%int_0.loc16) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:     %.loc16_21.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16_21 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:     %.loc16_21.2: %i32 = converted %int_0.loc16, %.loc16_21.1 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:     %Int.as.OrderedWith.impl.Less.call: init bool = call %bound_method.loc16_19.3(%x.ref.loc16, %.loc16_21.2)
// CHECK:STDOUT:     %.loc16_19.3: bool = value_of_initializer %Int.as.OrderedWith.impl.Less.call
// CHECK:STDOUT:     %.loc16_19.4: bool = converted %Int.as.OrderedWith.impl.Less.call, %.loc16_19.3
// CHECK:STDOUT:   }
// CHECK:STDOUT:   if %.loc16_19.1 br !match.default.then.loc16_24.2 else br !match.default.else.loc16
// CHECK:STDOUT:
// CHECK:STDOUT: !match.default.then.loc16_24.2:
// CHECK:STDOUT:   %int_1.loc16: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc16_37: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc16_37.1: <bound method> = bound_method %int_1.loc16, %impl.elem0.loc16_37 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc16_37: <specific function> = specific_function %impl.elem0.loc16_37, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc16_37.2: <bound method> = bound_method %int_1.loc16, %specific_fn.loc16_37 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16_37: init %i32 = call %bound_method.loc16_37.2(%int_1.loc16) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc16_37: init %i32 = converted %int_1.loc16, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16_37 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   return %.loc16_37
// CHECK:STDOUT:
// CHECK:STDOUT: !match.default.else.loc16:
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt.loc17: %pattern_type.dc0 = expr_pattern %int_1.loc17 in [concrete] {
// CHECK:STDOUT:       %int_1.loc17: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_1.loc17: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc17_12: %.025 = impl_witness_access constants.%EqWith.impl_witness.bde, element0 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.57b831.2]
// CHECK:STDOUT:   %bound_method.loc17_12.1: <bound method> = bound_method %int_1.loc17, %impl.elem0.loc17_12 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.bound.29e975.1]
// CHECK:STDOUT:   %specific_fn.loc17_12: <specific function> = specific_function %impl.elem0.loc17_12, @T.as_type.as.EqWith.impl.Equal.1(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.1]
// CHECK:STDOUT:   %bound_method.loc17_12.2: <bound method> = bound_method %int_1.loc17, %specific_fn.loc17_12 [concrete = constants.%bound_method.42af37.1]
// CHECK:STDOUT:   %.loc17_12.1: %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.1 = specific_constant imports.%Core.Equal.970, @T.as_type.as.EqWith.impl(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.57b831.1]
// CHECK:STDOUT:   %Equal.ref.loc17: %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.1 = name_ref Equal, %.loc17_12.1 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.57b831.1]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound.loc17: <bound method> = bound_method %int_1.loc17, %Equal.ref.loc17 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.bound.29e975.2]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.specific_fn.loc17: <specific function> = specific_function %Equal.ref.loc17, @T.as_type.as.EqWith.impl.Equal.2(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.2]
// CHECK:STDOUT:   %bound_method.loc17_12.3: <bound method> = bound_method %int_1.loc17, %T.as_type.as.EqWith.impl.Equal.specific_fn.loc17 [concrete = constants.%bound_method.42af37.2]
// CHECK:STDOUT:   %impl.elem0.loc17_10: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc17_10.1: <bound method> = bound_method %int_1.loc17, %impl.elem0.loc17_10 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc17_10: <specific function> = specific_function %impl.elem0.loc17_10, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc17_10.2: <bound method> = bound_method %int_1.loc17, %specific_fn.loc17_10 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc17_10: init %i32 = call %bound_method.loc17_10.2(%int_1.loc17) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc17_10.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc17_10 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc17_10.2: %i32 = converted %int_1.loc17, %.loc17_10.1 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.call.loc17: init bool = call %bound_method.loc17_12.3(%.loc17_10.2, %x.ref.loc14)
// CHECK:STDOUT:   %.loc17_12.2: bool = value_of_initializer %T.as_type.as.EqWith.impl.Equal.call.loc17
// CHECK:STDOUT:   %.loc17_12.3: bool = converted %T.as_type.as.EqWith.impl.Equal.call.loc17, %.loc17_12.2
// CHECK:STDOUT:   if %.loc17_12.3 br !match.case.then.loc17 else br !match.case.else.loc17
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc17:
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:   %impl.elem0.loc17_25: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc17_25.1: <bound method> = bound_method %int_2, %impl.elem0.loc17_25 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.9f3]
// CHECK:STDOUT:   %specific_fn.loc17_25: <specific function> = specific_function %impl.elem0.loc17_25, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc17_25.2: <bound method> = bound_method %int_2, %specific_fn.loc17_25 [concrete = constants.%bound_method.3cb]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc17_25: init %i32 = call %bound_method.loc17_25.2(%int_2) [concrete = constants.%int_2.295]
// CHECK:STDOUT:   %.loc17_25: init %i32 = converted %int_2, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc17_25 [concrete = constants.%int_2.295]
// CHECK:STDOUT:   return %.loc17_25
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc17:
// CHECK:STDOUT:   %true.loc18: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:   if %true.loc18 br !match.default.then.loc18_25.1 else br !match.default.else.loc18
// CHECK:STDOUT:
// CHECK:STDOUT: !match.default.then.loc18_25.1:
// CHECK:STDOUT:   %.loc18_19.1: bool = splice_block %.loc18_19.4 {
// CHECK:STDOUT:     %x.ref.loc18: %i32 = name_ref x, %x
// CHECK:STDOUT:     %int_10: Core.IntLiteral = int_value 10 [concrete = constants.%int_10.64f]
// CHECK:STDOUT:     %impl.elem2: %.029 = impl_witness_access constants.%OrderedWith.impl_witness.480, element2 [concrete = constants.%Int.as.OrderedWith.impl.Greater.e68ae3.2]
// CHECK:STDOUT:     %bound_method.loc18_19.1: <bound method> = bound_method %x.ref.loc18, %impl.elem2
// CHECK:STDOUT:     %specific_fn.loc18_19: <specific function> = specific_function %impl.elem2, @Int.as.OrderedWith.impl.Greater.2(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%Int.as.OrderedWith.impl.Greater.specific_fn.e2f732.1]
// CHECK:STDOUT:     %bound_method.loc18_19.2: <bound method> = bound_method %x.ref.loc18, %specific_fn.loc18_19
// CHECK:STDOUT:     %.loc18_19.2: %Int.as.OrderedWith.impl.Greater.type.a79f39.1 = specific_constant imports.%Core.Greater.28d, @Int.as.OrderedWith.impl.f36(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%Int.as.OrderedWith.impl.Greater.e68ae3.1]
// CHECK:STDOUT:     %Greater.ref: %Int.as.OrderedWith.impl.Greater.type.a79f39.1 = name_ref Greater, %.loc18_19.2 [concrete = constants.%Int.as.OrderedWith.impl.Greater.e68ae3.1]
// CHECK:STDOUT:     %Int.as.OrderedWith.impl.Greater.bound: <bound method> = bound_method %x.ref.loc18, %Greater.ref
// CHECK:STDOUT:     %Int.as.OrderedWith.impl.Greater.specific_fn: <specific function> = specific_function %Greater.ref, @Int.as.OrderedWith.impl.Greater.3(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%Int.as.OrderedWith.impl.Greater.specific_fn.e2f732.2]
// CHECK:STDOUT:     %bound_method.loc18_19.3: <bound method> = bound_method %x.ref.loc18, %Int.as.OrderedWith.impl.Greater.specific_fn
// CHECK:STDOUT:     %impl.elem0.loc18_21: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:     %bound_method.loc18_21.1: <bound method> = bound_method %int_10, %impl.elem0.loc18_21 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.dcb]
// CHECK:STDOUT:     %specific_fn.loc18_21: <specific function> = specific_function %impl.elem0.loc18_21, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:     %bound_method.loc18_21.2: <bound method> = bound_method %int_10, %specific_fn.loc18_21 [concrete = constants.%bound_method.1b6]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc18_21: init %i32 = call %bound_method.loc18_21.2(%int_10) [concrete = constants.%int_10.6bf]
// CHECK:STDOUT:     %.loc18_21.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc18_21 [concrete = constants.%int_10.6bf]
// CHECK:STDOUT:     %.loc18_21.2: %i32 = converted %int_10, %.loc18_21.1 [concrete = constants.%int_10.6bf]
// CHECK:STDOUT:     %Int.as.OrderedWith.impl.Greater.call: init bool = call %bound_method.loc18_19.3(%x.ref.loc18, %.loc18_21.2)
// CHECK:STDOUT:     %.loc18_19.3: bool = value_of_initializer %Int.as.OrderedWith.impl.Greater.call
// CHECK:STDOUT:     %.loc18_19.4: bool = converted %Int.as.OrderedWith.impl.Greater.call, %.loc18_19.3
// CHECK:STDOUT:   }
// CHECK:STDOUT:   if %.loc18_19.1 br !match.default.then.loc18_25.2 else br !match.default.else.loc18
// CHECK:STDOUT:
// CHECK:STDOUT: !match.default.then.loc18_25.2:
// CHECK:STDOUT:   %int_3: Core.IntLiteral = int_value 3 [concrete = constants.%int_3.1ba]
// CHECK:STDOUT:   %impl.elem0.loc18_38: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc18_38.1: <bound method> = bound_method %int_3, %impl.elem0.loc18_38 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.485]
// CHECK:STDOUT:   %specific_fn.loc18_38: <specific function> = specific_function %impl.elem0.loc18_38, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc18_38.2: <bound method> = bound_method %int_3, %specific_fn.loc18_38 [concrete = constants.%bound_method.763]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc18_38: init %i32 = call %bound_method.loc18_38.2(%int_3) [concrete = constants.%int_3.410]
// CHECK:STDOUT:   %.loc18_38: init %i32 = converted %int_3, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc18_38 [concrete = constants.%int_3.410]
// CHECK:STDOUT:   return %.loc18_38
// CHECK:STDOUT:
// CHECK:STDOUT: !match.default.else.loc18:
// CHECK:STDOUT:   %int_4: Core.IntLiteral = int_value 4 [concrete = constants.%int_4.0c1]
// CHECK:STDOUT:   %impl.elem0.loc19: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc19_26.1: <bound method> = bound_method %int_4, %impl.elem0.loc19 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.aad]
// CHECK:STDOUT:   %specific_fn.loc19: <specific function> = specific_function %impl.elem0.loc19, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc19_26.2: <bound method> = bound_method %int_4, %specific_fn.loc19 [concrete = constants.%bound_method.b7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc19: init %i32 = call %bound_method.loc19_26.2(%int_4) [concrete = constants.%int_4.4eb]
// CHECK:STDOUT:   %.loc19: init %i32 = converted %int_4, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc19 [concrete = constants.%int_4.4eb]
// CHECK:STDOUT:   return %.loc19
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- compound_guard.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %Int.67af24.1: type = class_type @Int, @Int(%N) [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %x.param_patt: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %x.patt: %pattern_type.6b6 = at_binding_pattern x, %x.param_patt [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %InRange.type: type = fn_type @InRange [concrete]
// CHECK:STDOUT:   %InRange: %InRange.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %OrderedWith.type.975: type = facet_type <@OrderedWith, @OrderedWith(Core.IntLiteral)> [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.f7de31.1: type = facet_type <@ImplicitAs, @ImplicitAs(%Int.67af24.1)> [symbolic]
// CHECK:STDOUT:   %T.4e6: %ImplicitAs.type.f7de31.1 = symbolic_binding T, 1 [symbolic]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.type.18c27f.1: type = fn_type @Int.as.OrderedWith.impl.Greater.2, @Int.as.OrderedWith.impl.f36(%N, %T.4e6) [symbolic]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.cbccb6.1: %Int.as.OrderedWith.impl.Greater.type.18c27f.1 = struct_value () [symbolic]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Less.type.6605e2.1: type = fn_type @Int.as.OrderedWith.impl.Less.2, @Int.as.OrderedWith.impl.f36(%N, %T.4e6) [symbolic]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Less.59643b.1: %Int.as.OrderedWith.impl.Less.type.6605e2.1 = struct_value () [symbolic]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.type.18c27f.2: type = fn_type @Int.as.OrderedWith.impl.Greater.3, @Int.as.OrderedWith.impl.f36(%N, %T.4e6) [symbolic]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.cbccb6.2: %Int.as.OrderedWith.impl.Greater.type.18c27f.2 = struct_value () [symbolic]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Less.type.6605e2.2: type = fn_type @Int.as.OrderedWith.impl.Less.3, @Int.as.OrderedWith.impl.f36(%N, %T.4e6) [symbolic]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Less.59643b.2: %Int.as.OrderedWith.impl.Less.type.6605e2.2 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %To: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %OrderedWith.impl_witness.480: <witness> = impl_witness imports.%OrderedWith.impl_witness_table.100, @Int.as.OrderedWith.impl.f36(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Less.type.4f4a1d.1: type = fn_type @Int.as.OrderedWith.impl.Less.3, @Int.as.OrderedWith.impl.f36(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Less.164caf.1: %Int.as.OrderedWith.impl.Less.type.4f4a1d.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.type.a79f39.1: type = fn_type @Int.as.OrderedWith.impl.Greater.3, @Int.as.OrderedWith.impl.f36(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.e68ae3.1: %Int.as.OrderedWith.impl.Greater.type.a79f39.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Less.type.4f4a1d.2: type = fn_type @Int.as.OrderedWith.impl.Less.2, @Int.as.OrderedWith.impl.f36(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Less.164caf.2: %Int.as.OrderedWith.impl.Less.type.4f4a1d.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.type.a79f39.2: type = fn_type @Int.as.OrderedWith.impl.Greater.2, @Int.as.OrderedWith.impl.f36(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.e68ae3.2: %Int.as.OrderedWith.impl.Greater.type.a79f39.2 = struct_value () [concrete]
// CHECK:STDOUT:   %OrderedWith.facet.e90: %OrderedWith.type.975 = facet_value %i32, (%OrderedWith.impl_witness.480) [concrete]
// CHECK:STDOUT:   %OrderedWith.WithSelf.Less.type.3dc: type = fn_type @OrderedWith.WithSelf.Less, @OrderedWith.WithSelf(Core.IntLiteral, %OrderedWith.facet.e90) [concrete]
// CHECK:STDOUT:   %OrderedWith.WithSelf.Greater.type.e1c: type = fn_type @OrderedWith.WithSelf.Greater, @OrderedWith.WithSelf(Core.IntLiteral, %OrderedWith.facet.e90) [concrete]
// CHECK:STDOUT:   %.029: type = fn_type_with_self_type %OrderedWith.WithSelf.Greater.type.e1c, %OrderedWith.facet.e90 [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.specific_fn.e2f732.1: <specific function> = specific_function %Int.as.OrderedWith.impl.Greater.e68ae3.2, @Int.as.OrderedWith.impl.Greater.2(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.specific_fn.e2f732.2: <specific function> = specific_function %Int.as.OrderedWith.impl.Greater.e68ae3.1, @Int.as.OrderedWith.impl.Greater.3(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.6e0: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_0.3c0: %i32 = int_value 0 [concrete]
// CHECK:STDOUT:   %false: bool = bool_literal false [concrete]
// CHECK:STDOUT:   %int_10.64f: Core.IntLiteral = int_value 10 [concrete]
// CHECK:STDOUT:   %.c7f: type = fn_type_with_self_type %OrderedWith.WithSelf.Less.type.3dc, %OrderedWith.facet.e90 [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Less.specific_fn.30cd42.1: <specific function> = specific_function %Int.as.OrderedWith.impl.Less.164caf.2, @Int.as.OrderedWith.impl.Less.2(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Less.specific_fn.30cd42.2: <specific function> = specific_function %Int.as.OrderedWith.impl.Less.164caf.1, @Int.as.OrderedWith.impl.Less.3(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.dcb: <bound method> = bound_method %int_10.64f, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.1b6: <bound method> = bound_method %int_10.64f, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_10.6bf: %i32 = int_value 10 [concrete]
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.953: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.1dc: @Int.as.OrderedWith.impl.f36.%Int.as.OrderedWith.impl.Less.type.2 (%Int.as.OrderedWith.impl.Less.type.6605e2.1) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.OrderedWith.impl.f36.%Int.as.OrderedWith.impl.Less.2 (constants.%Int.as.OrderedWith.impl.Less.59643b.1)]
// CHECK:STDOUT:   %Core.import_ref.f9d = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.0ab: @Int.as.OrderedWith.impl.f36.%Int.as.OrderedWith.impl.Greater.type.2 (%Int.as.OrderedWith.impl.Greater.type.18c27f.1) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.OrderedWith.impl.f36.%Int.as.OrderedWith.impl.Greater.2 (constants.%Int.as.OrderedWith.impl.Greater.cbccb6.1)]
// CHECK:STDOUT:   %Core.import_ref.b56 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %OrderedWith.impl_witness_table.100 = impl_witness_table (%Core.import_ref.1dc, %Core.import_ref.f9d, %Core.import_ref.0ab, %Core.import_ref.b56), @Int.as.OrderedWith.impl.f36 [concrete]
// CHECK:STDOUT:   %Core.Less.80e: @Int.as.OrderedWith.impl.f36.%Int.as.OrderedWith.impl.Less.type.1 (%Int.as.OrderedWith.impl.Less.type.6605e2.2) = import_ref Core//prelude/types/int, Less, loaded [symbolic = @Int.as.OrderedWith.impl.f36.%Int.as.OrderedWith.impl.Less.1 (constants.%Int.as.OrderedWith.impl.Less.59643b.2)]
// CHECK:STDOUT:   %Core.Greater.28d: @Int.as.OrderedWith.impl.f36.%Int.as.OrderedWith.impl.Greater.type.1 (%Int.as.OrderedWith.impl.Greater.type.18c27f.2) = import_ref Core//prelude/types/int, Greater, loaded [symbolic = @Int.as.OrderedWith.impl.f36.%Int.as.OrderedWith.impl.Greater.1 (constants.%Int.as.OrderedWith.impl.Greater.cbccb6.2)]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %InRange.decl: %InRange.type = fn_decl @InRange [concrete = constants.%InRange] {
// CHECK:STDOUT:     %x.param_patt: %pattern_type.6b6 = value_param_pattern [concrete = constants.%x.param_patt]
// CHECK:STDOUT:     %x.patt: %pattern_type.6b6 = at_binding_pattern x, %x.param_patt [concrete = constants.%x.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc8_23 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc8_23: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc8: Core.Form = init_form %i32.loc8_23 [concrete = constants.%.795f]
// CHECK:STDOUT:     %x.param: %i32 = value_param call_param0
// CHECK:STDOUT:     %i32.loc8_15: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %x: %i32 = wrapper_binding x, %x.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @InRange(%x.param: %i32) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %x.ref.loc9: %i32 = name_ref x, %x
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:   if %true br !match.default.then.loc10_35.1 else br !match.default.else
// CHECK:STDOUT:
// CHECK:STDOUT: !match.default.then.loc10_35.1:
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc10_17:
// CHECK:STDOUT:   %x.ref.loc10_17: %i32 = name_ref x, %x
// CHECK:STDOUT:   %int_0.loc10: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem2: %.029 = impl_witness_access constants.%OrderedWith.impl_witness.480, element2 [concrete = constants.%Int.as.OrderedWith.impl.Greater.e68ae3.2]
// CHECK:STDOUT:   %bound_method.loc10_19.1: <bound method> = bound_method %x.ref.loc10_17, %impl.elem2
// CHECK:STDOUT:   %specific_fn.loc10_19: <specific function> = specific_function %impl.elem2, @Int.as.OrderedWith.impl.Greater.2(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%Int.as.OrderedWith.impl.Greater.specific_fn.e2f732.1]
// CHECK:STDOUT:   %bound_method.loc10_19.2: <bound method> = bound_method %x.ref.loc10_17, %specific_fn.loc10_19
// CHECK:STDOUT:   %.loc10_19: %Int.as.OrderedWith.impl.Greater.type.a79f39.1 = specific_constant imports.%Core.Greater.28d, @Int.as.OrderedWith.impl.f36(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%Int.as.OrderedWith.impl.Greater.e68ae3.1]
// CHECK:STDOUT:   %Greater.ref: %Int.as.OrderedWith.impl.Greater.type.a79f39.1 = name_ref Greater, %.loc10_19 [concrete = constants.%Int.as.OrderedWith.impl.Greater.e68ae3.1]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.bound: <bound method> = bound_method %x.ref.loc10_17, %Greater.ref
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.specific_fn: <specific function> = specific_function %Greater.ref, @Int.as.OrderedWith.impl.Greater.3(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%Int.as.OrderedWith.impl.Greater.specific_fn.e2f732.2]
// CHECK:STDOUT:   %bound_method.loc10_19.3: <bound method> = bound_method %x.ref.loc10_17, %Int.as.OrderedWith.impl.Greater.specific_fn
// CHECK:STDOUT:   %impl.elem0.loc10_21: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc10_21.1: <bound method> = bound_method %int_0.loc10, %impl.elem0.loc10_21 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc10_21: <specific function> = specific_function %impl.elem0.loc10_21, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc10_21.2: <bound method> = bound_method %int_0.loc10, %specific_fn.loc10_21 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc10_21: init %i32 = call %bound_method.loc10_21.2(%int_0.loc10) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc10_21.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc10_21 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc10_21.2: %i32 = converted %int_0.loc10, %.loc10_21.1 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.call: init bool = call %bound_method.loc10_19.3(%x.ref.loc10_17, %.loc10_21.2)
// CHECK:STDOUT:   %.loc10_23.1: bool = value_of_initializer %Int.as.OrderedWith.impl.Greater.call
// CHECK:STDOUT:   %.loc10_23.2: bool = converted %Int.as.OrderedWith.impl.Greater.call, %.loc10_23.1
// CHECK:STDOUT:   %false: bool = bool_literal false [concrete = constants.%false]
// CHECK:STDOUT:   if %.loc10_23.2 br !and.rhs else br !and.result(%false)
// CHECK:STDOUT:
// CHECK:STDOUT: !and.rhs:
// CHECK:STDOUT:   %x.ref.loc10_27: %i32 = name_ref x, %x
// CHECK:STDOUT:   %int_10: Core.IntLiteral = int_value 10 [concrete = constants.%int_10.64f]
// CHECK:STDOUT:   %impl.elem0.loc10_29: %.c7f = impl_witness_access constants.%OrderedWith.impl_witness.480, element0 [concrete = constants.%Int.as.OrderedWith.impl.Less.164caf.2]
// CHECK:STDOUT:   %bound_method.loc10_29.1: <bound method> = bound_method %x.ref.loc10_27, %impl.elem0.loc10_29
// CHECK:STDOUT:   %specific_fn.loc10_29: <specific function> = specific_function %impl.elem0.loc10_29, @Int.as.OrderedWith.impl.Less.2(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%Int.as.OrderedWith.impl.Less.specific_fn.30cd42.1]
// CHECK:STDOUT:   %bound_method.loc10_29.2: <bound method> = bound_method %x.ref.loc10_27, %specific_fn.loc10_29
// CHECK:STDOUT:   %.loc10_29: %Int.as.OrderedWith.impl.Less.type.4f4a1d.1 = specific_constant imports.%Core.Less.80e, @Int.as.OrderedWith.impl.f36(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%Int.as.OrderedWith.impl.Less.164caf.1]
// CHECK:STDOUT:   %Less.ref: %Int.as.OrderedWith.impl.Less.type.4f4a1d.1 = name_ref Less, %.loc10_29 [concrete = constants.%Int.as.OrderedWith.impl.Less.164caf.1]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Less.bound: <bound method> = bound_method %x.ref.loc10_27, %Less.ref
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Less.specific_fn: <specific function> = specific_function %Less.ref, @Int.as.OrderedWith.impl.Less.3(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%Int.as.OrderedWith.impl.Less.specific_fn.30cd42.2]
// CHECK:STDOUT:   %bound_method.loc10_29.3: <bound method> = bound_method %x.ref.loc10_27, %Int.as.OrderedWith.impl.Less.specific_fn
// CHECK:STDOUT:   %impl.elem0.loc10_31: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc10_31.1: <bound method> = bound_method %int_10, %impl.elem0.loc10_31 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.dcb]
// CHECK:STDOUT:   %specific_fn.loc10_31: <specific function> = specific_function %impl.elem0.loc10_31, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc10_31.2: <bound method> = bound_method %int_10, %specific_fn.loc10_31 [concrete = constants.%bound_method.1b6]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc10_31: init %i32 = call %bound_method.loc10_31.2(%int_10) [concrete = constants.%int_10.6bf]
// CHECK:STDOUT:   %.loc10_31.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc10_31 [concrete = constants.%int_10.6bf]
// CHECK:STDOUT:   %.loc10_31.2: %i32 = converted %int_10, %.loc10_31.1 [concrete = constants.%int_10.6bf]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Less.call: init bool = call %bound_method.loc10_29.3(%x.ref.loc10_27, %.loc10_31.2)
// CHECK:STDOUT:   %.loc10_23.3: bool = value_of_initializer %Int.as.OrderedWith.impl.Less.call
// CHECK:STDOUT:   %.loc10_23.4: bool = converted %Int.as.OrderedWith.impl.Less.call, %.loc10_23.3
// CHECK:STDOUT:   br !and.result(%.loc10_23.4)
// CHECK:STDOUT:
// CHECK:STDOUT: !and.result:
// CHECK:STDOUT:   %.loc10_23.5: bool = block_arg !and.result
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc10_35:
// CHECK:STDOUT:   if %.loc10_23.5 br !match.default.then.loc10_35.2 else br !match.default.else
// CHECK:STDOUT:
// CHECK:STDOUT: !match.default.then.loc10_35.2:
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc10_48: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc10_48.1: <bound method> = bound_method %int_1, %impl.elem0.loc10_48 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc10_48: <specific function> = specific_function %impl.elem0.loc10_48, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc10_48.2: <bound method> = bound_method %int_1, %specific_fn.loc10_48 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc10_48: init %i32 = call %bound_method.loc10_48.2(%int_1) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc10_48: init %i32 = converted %int_1, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc10_48 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   return %.loc10_48
// CHECK:STDOUT:
// CHECK:STDOUT: !match.default.else:
// CHECK:STDOUT:   %int_0.loc11: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc11: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc11_26.1: <bound method> = bound_method %int_0.loc11, %impl.elem0.loc11 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc11: <specific function> = specific_function %impl.elem0.loc11, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc11_26.2: <bound method> = bound_method %int_0.loc11, %specific_fn.loc11 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc11: init %i32 = call %bound_method.loc11_26.2(%int_0.loc11) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc11: init %i32 = converted %int_0.loc11, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc11 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   return %.loc11
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- choice_coverage.carbon
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
// CHECK:STDOUT:   %struct.249: %struct_type.discriminant = struct_value (%int_0.1a7) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.type.0c5: type = fn_type @UInt.as.Copy.impl.Op, @UInt.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.38a: %UInt.as.Copy.impl.Op.type.0c5 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.334: <witness> = impl_witness imports.%Copy.impl_witness_table.ae7, @UInt.as.Copy.impl(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.type.c97: type = fn_type @UInt.as.Copy.impl.Op, @UInt.as.Copy.impl(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.d9c: %UInt.as.Copy.impl.Op.type.c97 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet: %Copy.type = facet_value %u1, (%Copy.impl_witness.334) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.703: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet) [concrete]
// CHECK:STDOUT:   %.952: type = fn_type_with_self_type %Copy.WithSelf.Op.type.703, %Copy.facet [concrete]
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
// CHECK:STDOUT:   %Int.67af24.1: type = class_type @Int, @Int(%N) [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %x.param_patt: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %x.patt: %pattern_type.6b6 = at_binding_pattern x, %x.param_patt [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %Classify.type: type = fn_type @Classify [concrete]
// CHECK:STDOUT:   %Classify: %Classify.type = struct_value () [concrete]
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
// CHECK:STDOUT:   %OrderedWith.type.975: type = facet_type <@OrderedWith, @OrderedWith(Core.IntLiteral)> [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.f7de31.2: type = facet_type <@ImplicitAs, @ImplicitAs(%Int.67af24.1)> [symbolic]
// CHECK:STDOUT:   %T.4e6: %ImplicitAs.type.f7de31.2 = symbolic_binding T, 1 [symbolic]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.type.18c27f.1: type = fn_type @Int.as.OrderedWith.impl.Greater.2, @Int.as.OrderedWith.impl.f36(%N, %T.4e6) [symbolic]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.cbccb6.1: %Int.as.OrderedWith.impl.Greater.type.18c27f.1 = struct_value () [symbolic]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.type.18c27f.2: type = fn_type @Int.as.OrderedWith.impl.Greater.3, @Int.as.OrderedWith.impl.f36(%N, %T.4e6) [symbolic]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.cbccb6.2: %Int.as.OrderedWith.impl.Greater.type.18c27f.2 = struct_value () [symbolic]
// CHECK:STDOUT:   %OrderedWith.impl_witness.480: <witness> = impl_witness imports.%OrderedWith.impl_witness_table.100, @Int.as.OrderedWith.impl.f36(%int_32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.type.a79f39.1: type = fn_type @Int.as.OrderedWith.impl.Greater.3, @Int.as.OrderedWith.impl.f36(%int_32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.e68ae3.1: %Int.as.OrderedWith.impl.Greater.type.a79f39.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.type.a79f39.2: type = fn_type @Int.as.OrderedWith.impl.Greater.2, @Int.as.OrderedWith.impl.f36(%int_32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.e68ae3.2: %Int.as.OrderedWith.impl.Greater.type.a79f39.2 = struct_value () [concrete]
// CHECK:STDOUT:   %OrderedWith.facet.e90: %OrderedWith.type.975 = facet_value %i32, (%OrderedWith.impl_witness.480) [concrete]
// CHECK:STDOUT:   %OrderedWith.WithSelf.Greater.type.e1c: type = fn_type @OrderedWith.WithSelf.Greater, @OrderedWith.WithSelf(Core.IntLiteral, %OrderedWith.facet.e90) [concrete]
// CHECK:STDOUT:   %.029: type = fn_type_with_self_type %OrderedWith.WithSelf.Greater.type.e1c, %OrderedWith.facet.e90 [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.specific_fn.e2f732.1: <specific function> = specific_function %Int.as.OrderedWith.impl.Greater.e68ae3.2, @Int.as.OrderedWith.impl.Greater.2(%int_32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.specific_fn.e2f732.2: <specific function> = specific_function %Int.as.OrderedWith.impl.Greater.e68ae3.1, @Int.as.OrderedWith.impl.Greater.3(%int_32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete]
// CHECK:STDOUT:   %int_2.ecc: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.9f3: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.3cb: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_2.295: %i32 = int_value 2 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound.22c: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %bound_method.a82: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.953: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
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
// CHECK:STDOUT:   %Core.import_ref.791: @UInt.as.Copy.impl.%UInt.as.Copy.impl.Op.type (%UInt.as.Copy.impl.Op.type.0c5) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.Copy.impl.%UInt.as.Copy.impl.Op (constants.%UInt.as.Copy.impl.Op.38a)]
// CHECK:STDOUT:   %Copy.impl_witness_table.ae7 = impl_witness_table (%Core.import_ref.791), @UInt.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.b929: @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal.type (%UInt.as.EqWith.impl.Equal.type.544) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal (constants.%UInt.as.EqWith.impl.Equal.c67)]
// CHECK:STDOUT:   %Core.import_ref.b44 = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.166 = impl_witness_table (%Core.import_ref.b929, %Core.import_ref.b44), @UInt.as.EqWith.impl.f13 [concrete]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.0e6 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.f9df = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.0ab: @Int.as.OrderedWith.impl.f36.%Int.as.OrderedWith.impl.Greater.type.2 (%Int.as.OrderedWith.impl.Greater.type.18c27f.1) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.OrderedWith.impl.f36.%Int.as.OrderedWith.impl.Greater.2 (constants.%Int.as.OrderedWith.impl.Greater.cbccb6.1)]
// CHECK:STDOUT:   %Core.import_ref.b56 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %OrderedWith.impl_witness_table.100 = impl_witness_table (%Core.import_ref.0e6, %Core.import_ref.f9df, %Core.import_ref.0ab, %Core.import_ref.b56), @Int.as.OrderedWith.impl.f36 [concrete]
// CHECK:STDOUT:   %Core.Greater.28d: @Int.as.OrderedWith.impl.f36.%Int.as.OrderedWith.impl.Greater.type.1 (%Int.as.OrderedWith.impl.Greater.type.18c27f.2) = import_ref Core//prelude/types/int, Greater, loaded [symbolic = @Int.as.OrderedWith.impl.f36.%Int.as.OrderedWith.impl.Greater.1 (constants.%Int.as.OrderedWith.impl.Greater.cbccb6.2)]
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
// CHECK:STDOUT:     %x.param_patt: %pattern_type.6b6 = value_param_pattern [concrete = constants.%x.param_patt]
// CHECK:STDOUT:     %x.patt: %pattern_type.6b6 = at_binding_pattern x, %x.param_patt [concrete = constants.%x.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc14_33 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc14_33: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc14: Core.Form = init_form %i32.loc14_33 [concrete = constants.%.795f]
// CHECK:STDOUT:     %f.param: %Flag = value_param call_param0
// CHECK:STDOUT:     %Flag.ref: type = name_ref Flag, file.%Flag.decl [concrete = constants.%Flag]
// CHECK:STDOUT:     %f: %Flag = wrapper_binding f, %f.param
// CHECK:STDOUT:     %x.param: %i32 = value_param call_param1
// CHECK:STDOUT:     %i32.loc14_25: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %x: %i32 = wrapper_binding x, %x.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param2
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: class @Flag {
// CHECK:STDOUT:   %complete_type: <witness> = complete_type_witness constants.%struct_type.discriminant [concrete = constants.%complete_type.3a6]
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc5_6.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc5_6.1: <bound method> = bound_method %int_0, %impl.elem0.loc5_6.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:   %specific_fn.loc5_6.1: <specific function> = specific_function %impl.elem0.loc5_6.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc5_6.2: <bound method> = bound_method %int_0, %specific_fn.loc5_6.1 [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc5: init %u1 = call %bound_method.loc5_6.2(%int_0) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc5_6.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc5 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc5_6.2: %u1 = converted %int_0, %.loc5_6.1 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc5_6.3: %struct_type.discriminant = struct_literal (%.loc5_6.2) [concrete = constants.%struct.249]
// CHECK:STDOUT:   %impl.elem0.loc5_6.2: %.952 = impl_witness_access constants.%Copy.impl_witness.334, element0 [concrete = constants.%UInt.as.Copy.impl.Op.d9c]
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
// CHECK:STDOUT:   %impl.elem0.loc7_1.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc7_1.1: <bound method> = bound_method %int_1, %impl.elem0.loc7_1.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc7_1.1: <specific function> = specific_function %impl.elem0.loc7_1.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc7_1.2: <bound method> = bound_method %int_1, %specific_fn.loc7_1.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc7: init %u1 = call %bound_method.loc7_1.2(%int_1) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc7_1.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc7 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc7_1.2: %u1 = converted %int_1, %.loc7_1.1 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc7_1.3: %struct_type.discriminant = struct_literal (%.loc7_1.2) [concrete = constants.%struct.a79]
// CHECK:STDOUT:   %impl.elem0.loc7_1.2: %.952 = impl_witness_access constants.%Copy.impl_witness.334, element0 [concrete = constants.%UInt.as.Copy.impl.Op.d9c]
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
// CHECK:STDOUT: fn @Classify(%f.param: %Flag, %x.param: %i32) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %f.ref: %Flag = name_ref f, %f
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt.loc16: %pattern_type.5bc = expr_pattern %Off.ref in [concrete] {
// CHECK:STDOUT:       %Off.ref: %Flag = name_ref Off, @Flag.%Off
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Off.ref: %Flag = name_ref Off, @Flag.%Off
// CHECK:STDOUT:   %int_0.loc16_15: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc16_15.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc16_15.1: <bound method> = bound_method %int_0.loc16_15, %impl.elem0.loc16_15.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:   %specific_fn.loc16_15.1: <specific function> = specific_function %impl.elem0.loc16_15.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc16_15.2: <bound method> = bound_method %int_0.loc16_15, %specific_fn.loc16_15.1 [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16_15: init %u1 = call %bound_method.loc16_15.2(%int_0.loc16_15) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc16_15.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16_15 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc16_15.2: %u1 = converted %int_0.loc16_15, %.loc16_15.1 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc16_15.3: ref %u1 = class_element_access %f.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc16_15.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc16_15.3: <bound method> = bound_method %.loc16_15.2, %impl.elem0.loc16_15.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.f34]
// CHECK:STDOUT:   %specific_fn.loc16_15.2: <specific function> = specific_function %impl.elem0.loc16_15.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc16_15.4: <bound method> = bound_method %.loc16_15.2, %specific_fn.loc16_15.2 [concrete = constants.%bound_method.53a]
// CHECK:STDOUT:   %.loc16_15.4: %u1 = acquire_value %.loc16_15.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc16: init bool = call %bound_method.loc16_15.4(%.loc16_15.2, %.loc16_15.4)
// CHECK:STDOUT:   %.loc16_15.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc16
// CHECK:STDOUT:   %.loc16_15.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc16, %.loc16_15.5
// CHECK:STDOUT:   if %.loc16_15.6 br !match.case.then.loc16 else br !match.case.else.loc16
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc16:
// CHECK:STDOUT:   %int_0.loc16_27: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc16_28: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc16_28.1: <bound method> = bound_method %int_0.loc16_27, %impl.elem0.loc16_28 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc16_28: <specific function> = specific_function %impl.elem0.loc16_28, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc16_28.2: <bound method> = bound_method %int_0.loc16_27, %specific_fn.loc16_28 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16_28: init %i32 = call %bound_method.loc16_28.2(%int_0.loc16_27) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc16_28: init %i32 = converted %int_0.loc16_27, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16_28 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   return %.loc16_28
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc16:
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:   if %true br !match.default.then.loc17_24.1 else br !match.default.else
// CHECK:STDOUT:
// CHECK:STDOUT: !match.default.then.loc17_24.1:
// CHECK:STDOUT:   %.loc17_19.1: bool = splice_block %.loc17_19.4 {
// CHECK:STDOUT:     %x.ref: %i32 = name_ref x, %x
// CHECK:STDOUT:     %int_0.loc17: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:     %impl.elem2: %.029 = impl_witness_access constants.%OrderedWith.impl_witness.480, element2 [concrete = constants.%Int.as.OrderedWith.impl.Greater.e68ae3.2]
// CHECK:STDOUT:     %bound_method.loc17_19.1: <bound method> = bound_method %x.ref, %impl.elem2
// CHECK:STDOUT:     %specific_fn.loc17_19: <specific function> = specific_function %impl.elem2, @Int.as.OrderedWith.impl.Greater.2(constants.%int_32, constants.%ImplicitAs.facet.48f) [concrete = constants.%Int.as.OrderedWith.impl.Greater.specific_fn.e2f732.1]
// CHECK:STDOUT:     %bound_method.loc17_19.2: <bound method> = bound_method %x.ref, %specific_fn.loc17_19
// CHECK:STDOUT:     %.loc17_19.2: %Int.as.OrderedWith.impl.Greater.type.a79f39.1 = specific_constant imports.%Core.Greater.28d, @Int.as.OrderedWith.impl.f36(constants.%int_32, constants.%ImplicitAs.facet.48f) [concrete = constants.%Int.as.OrderedWith.impl.Greater.e68ae3.1]
// CHECK:STDOUT:     %Greater.ref: %Int.as.OrderedWith.impl.Greater.type.a79f39.1 = name_ref Greater, %.loc17_19.2 [concrete = constants.%Int.as.OrderedWith.impl.Greater.e68ae3.1]
// CHECK:STDOUT:     %Int.as.OrderedWith.impl.Greater.bound: <bound method> = bound_method %x.ref, %Greater.ref
// CHECK:STDOUT:     %Int.as.OrderedWith.impl.Greater.specific_fn: <specific function> = specific_function %Greater.ref, @Int.as.OrderedWith.impl.Greater.3(constants.%int_32, constants.%ImplicitAs.facet.48f) [concrete = constants.%Int.as.OrderedWith.impl.Greater.specific_fn.e2f732.2]
// CHECK:STDOUT:     %bound_method.loc17_19.3: <bound method> = bound_method %x.ref, %Int.as.OrderedWith.impl.Greater.specific_fn
// CHECK:STDOUT:     %impl.elem0.loc17_21: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:     %bound_method.loc17_21.1: <bound method> = bound_method %int_0.loc17, %impl.elem0.loc17_21 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:     %specific_fn.loc17_21: <specific function> = specific_function %impl.elem0.loc17_21, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:     %bound_method.loc17_21.2: <bound method> = bound_method %int_0.loc17, %specific_fn.loc17_21 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc17_21: init %i32 = call %bound_method.loc17_21.2(%int_0.loc17) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:     %.loc17_21.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc17_21 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:     %.loc17_21.2: %i32 = converted %int_0.loc17, %.loc17_21.1 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:     %Int.as.OrderedWith.impl.Greater.call: init bool = call %bound_method.loc17_19.3(%x.ref, %.loc17_21.2)
// CHECK:STDOUT:     %.loc17_19.3: bool = value_of_initializer %Int.as.OrderedWith.impl.Greater.call
// CHECK:STDOUT:     %.loc17_19.4: bool = converted %Int.as.OrderedWith.impl.Greater.call, %.loc17_19.3
// CHECK:STDOUT:   }
// CHECK:STDOUT:   if %.loc17_19.1 br !match.default.then.loc17_24.2 else br !match.default.else
// CHECK:STDOUT:
// CHECK:STDOUT: !match.default.then.loc17_24.2:
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:   %impl.elem0.loc17_37: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc17_37.1: <bound method> = bound_method %int_2, %impl.elem0.loc17_37 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.9f3]
// CHECK:STDOUT:   %specific_fn.loc17_37: <specific function> = specific_function %impl.elem0.loc17_37, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc17_37.2: <bound method> = bound_method %int_2, %specific_fn.loc17_37 [concrete = constants.%bound_method.3cb]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc17_37: init %i32 = call %bound_method.loc17_37.2(%int_2) [concrete = constants.%int_2.295]
// CHECK:STDOUT:   %.loc17_37: init %i32 = converted %int_2, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc17_37 [concrete = constants.%int_2.295]
// CHECK:STDOUT:   return %.loc17_37
// CHECK:STDOUT:
// CHECK:STDOUT: !match.default.else:
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt.loc18: %pattern_type.5bc = expr_pattern %On.ref in [concrete] {
// CHECK:STDOUT:       %On.ref: %Flag = name_ref On, @Flag.%On
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %On.ref: %Flag = name_ref On, @Flag.%On
// CHECK:STDOUT:   %int_1.loc18_14: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc18_14.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc18_14.1: <bound method> = bound_method %int_1.loc18_14, %impl.elem0.loc18_14.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc18_14.1: <specific function> = specific_function %impl.elem0.loc18_14.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc18_14.2: <bound method> = bound_method %int_1.loc18_14, %specific_fn.loc18_14.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc18_14: init %u1 = call %bound_method.loc18_14.2(%int_1.loc18_14) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc18_14.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc18_14 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc18_14.2: %u1 = converted %int_1.loc18_14, %.loc18_14.1 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc18_14.3: ref %u1 = class_element_access %f.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc18_14.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc18_14.3: <bound method> = bound_method %.loc18_14.2, %impl.elem0.loc18_14.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.22c]
// CHECK:STDOUT:   %specific_fn.loc18_14.2: <specific function> = specific_function %impl.elem0.loc18_14.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc18_14.4: <bound method> = bound_method %.loc18_14.2, %specific_fn.loc18_14.2 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc18_14.4: %u1 = acquire_value %.loc18_14.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc18: init bool = call %bound_method.loc18_14.4(%.loc18_14.2, %.loc18_14.4)
// CHECK:STDOUT:   %.loc18_14.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc18
// CHECK:STDOUT:   %.loc18_14.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc18, %.loc18_14.5
// CHECK:STDOUT:   if %.loc18_14.6 br !match.case.then.loc18 else br !match.case.else.loc18
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc18:
// CHECK:STDOUT:   %int_1.loc18_26: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc18_27: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc18_27.1: <bound method> = bound_method %int_1.loc18_26, %impl.elem0.loc18_27 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc18_27: <specific function> = specific_function %impl.elem0.loc18_27, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc18_27.2: <bound method> = bound_method %int_1.loc18_26, %specific_fn.loc18_27 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc18_27: init %i32 = call %bound_method.loc18_27.2(%int_1.loc18_26) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc18_27: init %i32 = converted %int_1.loc18_26, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc18_27 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   return %.loc18_27
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc18:
// CHECK:STDOUT:   br !match.done
// CHECK:STDOUT:
// CHECK:STDOUT: !match.done:
// CHECK:STDOUT:   %int_1.loc20: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem1: %.758 = impl_witness_access constants.%Negate.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %bound_method.loc20_10: <bound method> = bound_method %int_1.loc20, %impl.elem1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op.bound]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.call: init Core.IntLiteral = call %bound_method.loc20_10(%int_1.loc20) [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %impl.elem0.loc20: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc20_12.1: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %impl.elem0.loc20 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.65e]
// CHECK:STDOUT:   %specific_fn.loc20: <specific function> = specific_function %impl.elem0.loc20, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc20_12.2: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %specific_fn.loc20 [concrete = constants.%bound_method.a65]
// CHECK:STDOUT:   %.loc20_10.1: Core.IntLiteral = value_of_initializer %Core.IntLiteral.as.Negate.impl.Op.call [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %.loc20_10.2: Core.IntLiteral = converted %Core.IntLiteral.as.Negate.impl.Op.call, %.loc20_10.1 [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc20: init %i32 = call %bound_method.loc20_12.2(%.loc20_10.2) [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   %.loc20_12: init %i32 = converted %Core.IntLiteral.as.Negate.impl.Op.call, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc20 [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   return %.loc20_12
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- trailing_guarded_default.carbon
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
// CHECK:STDOUT:   %struct.249: %struct_type.discriminant = struct_value (%int_0.1a7) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.type.0c5: type = fn_type @UInt.as.Copy.impl.Op, @UInt.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.38a: %UInt.as.Copy.impl.Op.type.0c5 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.334: <witness> = impl_witness imports.%Copy.impl_witness_table.ae7, @UInt.as.Copy.impl(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.type.c97: type = fn_type @UInt.as.Copy.impl.Op, @UInt.as.Copy.impl(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.d9c: %UInt.as.Copy.impl.Op.type.c97 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet: %Copy.type = facet_value %u1, (%Copy.impl_witness.334) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.703: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet) [concrete]
// CHECK:STDOUT:   %.952: type = fn_type_with_self_type %Copy.WithSelf.Op.type.703, %Copy.facet [concrete]
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
// CHECK:STDOUT:   %Int.67af24.1: type = class_type @Int, @Int(%N) [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %x.param_patt: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %x.patt: %pattern_type.6b6 = at_binding_pattern x, %x.param_patt [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %Classify.type: type = fn_type @Classify [concrete]
// CHECK:STDOUT:   %Classify: %Classify.type = struct_value () [concrete]
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
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound.22c: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %bound_method.a82: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.953: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT:   %OrderedWith.type.975: type = facet_type <@OrderedWith, @OrderedWith(Core.IntLiteral)> [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.f7de31.2: type = facet_type <@ImplicitAs, @ImplicitAs(%Int.67af24.1)> [symbolic]
// CHECK:STDOUT:   %T.4e6: %ImplicitAs.type.f7de31.2 = symbolic_binding T, 1 [symbolic]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.type.18c27f.1: type = fn_type @Int.as.OrderedWith.impl.Greater.2, @Int.as.OrderedWith.impl.f36(%N, %T.4e6) [symbolic]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.cbccb6.1: %Int.as.OrderedWith.impl.Greater.type.18c27f.1 = struct_value () [symbolic]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.type.18c27f.2: type = fn_type @Int.as.OrderedWith.impl.Greater.3, @Int.as.OrderedWith.impl.f36(%N, %T.4e6) [symbolic]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.cbccb6.2: %Int.as.OrderedWith.impl.Greater.type.18c27f.2 = struct_value () [symbolic]
// CHECK:STDOUT:   %OrderedWith.impl_witness.480: <witness> = impl_witness imports.%OrderedWith.impl_witness_table.100, @Int.as.OrderedWith.impl.f36(%int_32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.type.a79f39.1: type = fn_type @Int.as.OrderedWith.impl.Greater.3, @Int.as.OrderedWith.impl.f36(%int_32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.e68ae3.1: %Int.as.OrderedWith.impl.Greater.type.a79f39.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.type.a79f39.2: type = fn_type @Int.as.OrderedWith.impl.Greater.2, @Int.as.OrderedWith.impl.f36(%int_32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.e68ae3.2: %Int.as.OrderedWith.impl.Greater.type.a79f39.2 = struct_value () [concrete]
// CHECK:STDOUT:   %OrderedWith.facet.e90: %OrderedWith.type.975 = facet_value %i32, (%OrderedWith.impl_witness.480) [concrete]
// CHECK:STDOUT:   %OrderedWith.WithSelf.Greater.type.e1c: type = fn_type @OrderedWith.WithSelf.Greater, @OrderedWith.WithSelf(Core.IntLiteral, %OrderedWith.facet.e90) [concrete]
// CHECK:STDOUT:   %.029: type = fn_type_with_self_type %OrderedWith.WithSelf.Greater.type.e1c, %OrderedWith.facet.e90 [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.specific_fn.e2f732.1: <specific function> = specific_function %Int.as.OrderedWith.impl.Greater.e68ae3.2, @Int.as.OrderedWith.impl.Greater.2(%int_32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.specific_fn.e2f732.2: <specific function> = specific_function %Int.as.OrderedWith.impl.Greater.e68ae3.1, @Int.as.OrderedWith.impl.Greater.3(%int_32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete]
// CHECK:STDOUT:   %int_2.ecc: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.9f3: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.3cb: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_2.295: %i32 = int_value 2 [concrete]
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
// CHECK:STDOUT:   %Core.import_ref.791: @UInt.as.Copy.impl.%UInt.as.Copy.impl.Op.type (%UInt.as.Copy.impl.Op.type.0c5) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.Copy.impl.%UInt.as.Copy.impl.Op (constants.%UInt.as.Copy.impl.Op.38a)]
// CHECK:STDOUT:   %Copy.impl_witness_table.ae7 = impl_witness_table (%Core.import_ref.791), @UInt.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.b929: @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal.type (%UInt.as.EqWith.impl.Equal.type.544) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal (constants.%UInt.as.EqWith.impl.Equal.c67)]
// CHECK:STDOUT:   %Core.import_ref.b44 = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.166 = impl_witness_table (%Core.import_ref.b929, %Core.import_ref.b44), @UInt.as.EqWith.impl.f13 [concrete]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.0e6 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.f9df = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.0ab: @Int.as.OrderedWith.impl.f36.%Int.as.OrderedWith.impl.Greater.type.2 (%Int.as.OrderedWith.impl.Greater.type.18c27f.1) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.OrderedWith.impl.f36.%Int.as.OrderedWith.impl.Greater.2 (constants.%Int.as.OrderedWith.impl.Greater.cbccb6.1)]
// CHECK:STDOUT:   %Core.import_ref.b56 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %OrderedWith.impl_witness_table.100 = impl_witness_table (%Core.import_ref.0e6, %Core.import_ref.f9df, %Core.import_ref.0ab, %Core.import_ref.b56), @Int.as.OrderedWith.impl.f36 [concrete]
// CHECK:STDOUT:   %Core.Greater.28d: @Int.as.OrderedWith.impl.f36.%Int.as.OrderedWith.impl.Greater.type.1 (%Int.as.OrderedWith.impl.Greater.type.18c27f.2) = import_ref Core//prelude/types/int, Greater, loaded [symbolic = @Int.as.OrderedWith.impl.f36.%Int.as.OrderedWith.impl.Greater.1 (constants.%Int.as.OrderedWith.impl.Greater.cbccb6.2)]
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
// CHECK:STDOUT:     %x.param_patt: %pattern_type.6b6 = value_param_pattern [concrete = constants.%x.param_patt]
// CHECK:STDOUT:     %x.patt: %pattern_type.6b6 = at_binding_pattern x, %x.param_patt [concrete = constants.%x.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc15_33 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc15_33: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc15: Core.Form = init_form %i32.loc15_33 [concrete = constants.%.795f]
// CHECK:STDOUT:     %f.param: %Flag = value_param call_param0
// CHECK:STDOUT:     %Flag.ref: type = name_ref Flag, file.%Flag.decl [concrete = constants.%Flag]
// CHECK:STDOUT:     %f: %Flag = wrapper_binding f, %f.param
// CHECK:STDOUT:     %x.param: %i32 = value_param call_param1
// CHECK:STDOUT:     %i32.loc15_25: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %x: %i32 = wrapper_binding x, %x.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param2
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: class @Flag {
// CHECK:STDOUT:   %complete_type: <witness> = complete_type_witness constants.%struct_type.discriminant [concrete = constants.%complete_type.3a6]
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc5_6.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc5_6.1: <bound method> = bound_method %int_0, %impl.elem0.loc5_6.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:   %specific_fn.loc5_6.1: <specific function> = specific_function %impl.elem0.loc5_6.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc5_6.2: <bound method> = bound_method %int_0, %specific_fn.loc5_6.1 [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc5: init %u1 = call %bound_method.loc5_6.2(%int_0) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc5_6.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc5 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc5_6.2: %u1 = converted %int_0, %.loc5_6.1 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc5_6.3: %struct_type.discriminant = struct_literal (%.loc5_6.2) [concrete = constants.%struct.249]
// CHECK:STDOUT:   %impl.elem0.loc5_6.2: %.952 = impl_witness_access constants.%Copy.impl_witness.334, element0 [concrete = constants.%UInt.as.Copy.impl.Op.d9c]
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
// CHECK:STDOUT:   %impl.elem0.loc7_1.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc7_1.1: <bound method> = bound_method %int_1, %impl.elem0.loc7_1.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc7_1.1: <specific function> = specific_function %impl.elem0.loc7_1.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc7_1.2: <bound method> = bound_method %int_1, %specific_fn.loc7_1.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc7: init %u1 = call %bound_method.loc7_1.2(%int_1) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc7_1.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc7 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc7_1.2: %u1 = converted %int_1, %.loc7_1.1 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc7_1.3: %struct_type.discriminant = struct_literal (%.loc7_1.2) [concrete = constants.%struct.a79]
// CHECK:STDOUT:   %impl.elem0.loc7_1.2: %.952 = impl_witness_access constants.%Copy.impl_witness.334, element0 [concrete = constants.%UInt.as.Copy.impl.Op.d9c]
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
// CHECK:STDOUT: fn @Classify(%f.param: %Flag, %x.param: %i32) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %f.ref: %Flag = name_ref f, %f
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt.loc17: %pattern_type.5bc = expr_pattern %Off.ref in [concrete] {
// CHECK:STDOUT:       %Off.ref: %Flag = name_ref Off, @Flag.%Off
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Off.ref: %Flag = name_ref Off, @Flag.%Off
// CHECK:STDOUT:   %int_0.loc17_15: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc17_15.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc17_15.1: <bound method> = bound_method %int_0.loc17_15, %impl.elem0.loc17_15.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:   %specific_fn.loc17_15.1: <specific function> = specific_function %impl.elem0.loc17_15.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc17_15.2: <bound method> = bound_method %int_0.loc17_15, %specific_fn.loc17_15.1 [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc17_15: init %u1 = call %bound_method.loc17_15.2(%int_0.loc17_15) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc17_15.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc17_15 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc17_15.2: %u1 = converted %int_0.loc17_15, %.loc17_15.1 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc17_15.3: ref %u1 = class_element_access %f.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc17_15.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc17_15.3: <bound method> = bound_method %.loc17_15.2, %impl.elem0.loc17_15.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.f34]
// CHECK:STDOUT:   %specific_fn.loc17_15.2: <specific function> = specific_function %impl.elem0.loc17_15.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc17_15.4: <bound method> = bound_method %.loc17_15.2, %specific_fn.loc17_15.2 [concrete = constants.%bound_method.53a]
// CHECK:STDOUT:   %.loc17_15.4: %u1 = acquire_value %.loc17_15.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc17: init bool = call %bound_method.loc17_15.4(%.loc17_15.2, %.loc17_15.4)
// CHECK:STDOUT:   %.loc17_15.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc17
// CHECK:STDOUT:   %.loc17_15.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc17, %.loc17_15.5
// CHECK:STDOUT:   if %.loc17_15.6 br !match.case.then.loc17 else br !match.case.else.loc17
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc17:
// CHECK:STDOUT:   %int_0.loc17_27: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc17_28: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc17_28.1: <bound method> = bound_method %int_0.loc17_27, %impl.elem0.loc17_28 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc17_28: <specific function> = specific_function %impl.elem0.loc17_28, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc17_28.2: <bound method> = bound_method %int_0.loc17_27, %specific_fn.loc17_28 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc17_28: init %i32 = call %bound_method.loc17_28.2(%int_0.loc17_27) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc17_28: init %i32 = converted %int_0.loc17_27, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc17_28 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   return %.loc17_28
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc17:
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt.loc18: %pattern_type.5bc = expr_pattern %On.ref in [concrete] {
// CHECK:STDOUT:       %On.ref: %Flag = name_ref On, @Flag.%On
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %On.ref: %Flag = name_ref On, @Flag.%On
// CHECK:STDOUT:   %int_1.loc18_14: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc18_14.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc18_14.1: <bound method> = bound_method %int_1.loc18_14, %impl.elem0.loc18_14.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc18_14.1: <specific function> = specific_function %impl.elem0.loc18_14.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc18_14.2: <bound method> = bound_method %int_1.loc18_14, %specific_fn.loc18_14.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc18_14: init %u1 = call %bound_method.loc18_14.2(%int_1.loc18_14) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc18_14.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc18_14 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc18_14.2: %u1 = converted %int_1.loc18_14, %.loc18_14.1 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc18_14.3: ref %u1 = class_element_access %f.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc18_14.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc18_14.3: <bound method> = bound_method %.loc18_14.2, %impl.elem0.loc18_14.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.22c]
// CHECK:STDOUT:   %specific_fn.loc18_14.2: <specific function> = specific_function %impl.elem0.loc18_14.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc18_14.4: <bound method> = bound_method %.loc18_14.2, %specific_fn.loc18_14.2 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc18_14.4: %u1 = acquire_value %.loc18_14.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc18: init bool = call %bound_method.loc18_14.4(%.loc18_14.2, %.loc18_14.4)
// CHECK:STDOUT:   %.loc18_14.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc18
// CHECK:STDOUT:   %.loc18_14.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc18, %.loc18_14.5
// CHECK:STDOUT:   if %.loc18_14.6 br !match.case.then.loc18 else br !match.case.else.loc18
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc18:
// CHECK:STDOUT:   %int_1.loc18_26: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc18_27: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc18_27.1: <bound method> = bound_method %int_1.loc18_26, %impl.elem0.loc18_27 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc18_27: <specific function> = specific_function %impl.elem0.loc18_27, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc18_27.2: <bound method> = bound_method %int_1.loc18_26, %specific_fn.loc18_27 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc18_27: init %i32 = call %bound_method.loc18_27.2(%int_1.loc18_26) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc18_27: init %i32 = converted %int_1.loc18_26, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc18_27 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   return %.loc18_27
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc18:
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:   if %true br !match.default.then.loc19_24.1 else br !match.default.else
// CHECK:STDOUT:
// CHECK:STDOUT: !match.default.then.loc19_24.1:
// CHECK:STDOUT:   %.loc19_19.1: bool = splice_block %.loc19_19.4 {
// CHECK:STDOUT:     %x.ref: %i32 = name_ref x, %x
// CHECK:STDOUT:     %int_0.loc19: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:     %impl.elem2: %.029 = impl_witness_access constants.%OrderedWith.impl_witness.480, element2 [concrete = constants.%Int.as.OrderedWith.impl.Greater.e68ae3.2]
// CHECK:STDOUT:     %bound_method.loc19_19.1: <bound method> = bound_method %x.ref, %impl.elem2
// CHECK:STDOUT:     %specific_fn.loc19_19: <specific function> = specific_function %impl.elem2, @Int.as.OrderedWith.impl.Greater.2(constants.%int_32, constants.%ImplicitAs.facet.48f) [concrete = constants.%Int.as.OrderedWith.impl.Greater.specific_fn.e2f732.1]
// CHECK:STDOUT:     %bound_method.loc19_19.2: <bound method> = bound_method %x.ref, %specific_fn.loc19_19
// CHECK:STDOUT:     %.loc19_19.2: %Int.as.OrderedWith.impl.Greater.type.a79f39.1 = specific_constant imports.%Core.Greater.28d, @Int.as.OrderedWith.impl.f36(constants.%int_32, constants.%ImplicitAs.facet.48f) [concrete = constants.%Int.as.OrderedWith.impl.Greater.e68ae3.1]
// CHECK:STDOUT:     %Greater.ref: %Int.as.OrderedWith.impl.Greater.type.a79f39.1 = name_ref Greater, %.loc19_19.2 [concrete = constants.%Int.as.OrderedWith.impl.Greater.e68ae3.1]
// CHECK:STDOUT:     %Int.as.OrderedWith.impl.Greater.bound: <bound method> = bound_method %x.ref, %Greater.ref
// CHECK:STDOUT:     %Int.as.OrderedWith.impl.Greater.specific_fn: <specific function> = specific_function %Greater.ref, @Int.as.OrderedWith.impl.Greater.3(constants.%int_32, constants.%ImplicitAs.facet.48f) [concrete = constants.%Int.as.OrderedWith.impl.Greater.specific_fn.e2f732.2]
// CHECK:STDOUT:     %bound_method.loc19_19.3: <bound method> = bound_method %x.ref, %Int.as.OrderedWith.impl.Greater.specific_fn
// CHECK:STDOUT:     %impl.elem0.loc19_21: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:     %bound_method.loc19_21.1: <bound method> = bound_method %int_0.loc19, %impl.elem0.loc19_21 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:     %specific_fn.loc19_21: <specific function> = specific_function %impl.elem0.loc19_21, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:     %bound_method.loc19_21.2: <bound method> = bound_method %int_0.loc19, %specific_fn.loc19_21 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc19_21: init %i32 = call %bound_method.loc19_21.2(%int_0.loc19) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:     %.loc19_21.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc19_21 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:     %.loc19_21.2: %i32 = converted %int_0.loc19, %.loc19_21.1 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:     %Int.as.OrderedWith.impl.Greater.call: init bool = call %bound_method.loc19_19.3(%x.ref, %.loc19_21.2)
// CHECK:STDOUT:     %.loc19_19.3: bool = value_of_initializer %Int.as.OrderedWith.impl.Greater.call
// CHECK:STDOUT:     %.loc19_19.4: bool = converted %Int.as.OrderedWith.impl.Greater.call, %.loc19_19.3
// CHECK:STDOUT:   }
// CHECK:STDOUT:   if %.loc19_19.1 br !match.default.then.loc19_24.2 else br !match.default.else
// CHECK:STDOUT:
// CHECK:STDOUT: !match.default.then.loc19_24.2:
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:   %impl.elem0.loc19_37: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc19_37.1: <bound method> = bound_method %int_2, %impl.elem0.loc19_37 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.9f3]
// CHECK:STDOUT:   %specific_fn.loc19_37: <specific function> = specific_function %impl.elem0.loc19_37, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc19_37.2: <bound method> = bound_method %int_2, %specific_fn.loc19_37 [concrete = constants.%bound_method.3cb]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc19_37: init %i32 = call %bound_method.loc19_37.2(%int_2) [concrete = constants.%int_2.295]
// CHECK:STDOUT:   %.loc19_37: init %i32 = converted %int_2, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc19_37 [concrete = constants.%int_2.295]
// CHECK:STDOUT:   return %.loc19_37
// CHECK:STDOUT:
// CHECK:STDOUT: !match.default.else:
// CHECK:STDOUT:   br !match.done
// CHECK:STDOUT:
// CHECK:STDOUT: !match.done:
// CHECK:STDOUT:   %int_1.loc21: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem1: %.758 = impl_witness_access constants.%Negate.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %bound_method.loc21_10: <bound method> = bound_method %int_1.loc21, %impl.elem1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op.bound]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.call: init Core.IntLiteral = call %bound_method.loc21_10(%int_1.loc21) [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %impl.elem0.loc21: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc21_12.1: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %impl.elem0.loc21 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.65e]
// CHECK:STDOUT:   %specific_fn.loc21: <specific function> = specific_function %impl.elem0.loc21, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc21_12.2: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %specific_fn.loc21 [concrete = constants.%bound_method.a65]
// CHECK:STDOUT:   %.loc21_10.1: Core.IntLiteral = value_of_initializer %Core.IntLiteral.as.Negate.impl.Op.call [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %.loc21_10.2: Core.IntLiteral = converted %Core.IntLiteral.as.Negate.impl.Op.call, %.loc21_10.1 [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc21: init %i32 = call %bound_method.loc21_12.2(%.loc21_10.2) [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   %.loc21_12: init %i32 = converted %Core.IntLiteral.as.Negate.impl.Op.call, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc21 [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   return %.loc21_12
// CHECK:STDOUT: }
// CHECK:STDOUT:
