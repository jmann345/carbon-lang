// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/bool_scrutinee.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/bool_scrutinee.carbon

// Bool scrutinees (W-076): the design treats `bool` like a choice type
// whose alternatives are `false` and `true`
// (docs/design/pattern_matching.md), so `case true`/`case false` dispatch
// through the expression-pattern `==` lane (`bool as EqWith(Self)`, hence
// the full prelude) and covering both values discharges the `default`
// requirement.

// --- exhaustive.carbon
library "[[@TEST_NAME]]";

// The design's own worked example shape (pattern_matching.md, `IsTrue`):
// `case false` + `case true` with no `default` is considered exhaustive.
// CAVEAT: the design also marks code after such a match unreachable; that
// half is not delivered — the resumption block stays CFG-reachable, so
// the trailing `return` is required, parity with exhaustive_choice
// .carbon's trailing `return -1;` (shared pre-existing residue, not
// W-076 scope).
//@dump-sem-ir-begin
fn IsTrue(b: bool) -> i32 {
  match (b) {
    case false => { return 0; }
    case true => { return 1; }
  }
  return -1;
}
//@dump-sem-ir-end

// --- with_default.carbon
library "[[@TEST_NAME]]";

// One value covered plus `default`: `has_default` short-circuits the
// exhaustiveness check, no bool-specific code runs.
//@dump-sem-ir-begin
fn F(b: bool) -> i32 {
  match (b) {
    case true => { return 1; }
    default => { return 0; }
  }
  return -1;
}
//@dump-sem-ir-end

// --- constant_expr_case.carbon
library "[[@TEST_NAME]]";

// A constant bool expression `case` classifies by its evaluated constant
// (a concrete `BoolLiteral`), never its syntax: `case 1 == 1` covers
// `true` (eval's builtin `IntLiteral` comparison folds it), and together
// with `case false` the match is exhaustive without `default`.
//@dump-sem-ir-begin
fn G(b: bool) -> i32 {
  match (b) {
    // CHECK:STDERR: constant_expr_case.carbon:[[@LINE+8]]:12: error: expected `=>` introducing statement block [ExpectedMatchCaseArrow]
    // CHECK:STDERR:     case 1 == 1 => { return 1; }
    // CHECK:STDERR:            ^~
    // CHECK:STDERR:
    // CHECK:STDERR: constant_expr_case.carbon:[[@LINE+4]]:5: error: semantics TODO: `handle invalid parse trees in `check`` [SemanticsTodo]
    // CHECK:STDERR:     case 1 == 1 => { return 1; }
    // CHECK:STDERR:     ^~~~~~~~~
    // CHECK:STDERR:
    case 1 == 1 => { return 1; }
    case false => { return 0; }
  }
  return -1;
}
//@dump-sem-ir-end

// --- constant_scrutinee.carbon
library "[[@TEST_NAME]]";

// A constant bool scrutinee: each arm's comparison constant-folds through
// eval's builtin `bool.eq` (`BuiltinFunctionKind::BoolEq`), mirroring
// match/constant_scrutinee.carbon's integer shape.
//@dump-sem-ir-begin
fn H() -> i32 {
  match (true) {
    case false => { return 0; }
    case true => { return 1; }
  }
  return -1;
}
//@dump-sem-ir-end

// --- compose.carbon
library "[[@TEST_NAME]]";

// Guards and binding arms compose with a bool scrutinee for free: the
// guarded arm records nothing toward coverage (every guard can fail), the
// binding arm is irrefutable, and the `default` arm stays accepted.
//@dump-sem-ir-begin
fn Compose(b: bool, c: bool) -> i32 {
  match (b) {
    case true if (c) => { return 2; }
    case b2: bool => { if (b2) { return 1; } return 0; }
    default => { return -2; }
  }
  return -1;
}
//@dump-sem-ir-end

// --- var_ref_binding.carbon
library "[[@TEST_NAME]]";

// `var` and `ref` case bindings on a bool scrutinee ride the W8b
// machinery unchanged: per-arm `var` storage, and a `ref` binding
// aliasing a durable scrutinee.
//@dump-sem-ir-begin
fn VarBinding(b: bool) -> i32 {
  match (b) {
    case var v: bool => { v = false; if (v) { return 1; } return 0; }
    default => { return -2; }
  }
  return -1;
}

fn RefBinding() -> i32 {
  var x: bool = true;
  match (x) {
    case ref r: bool => { r = false; }
    default => { return -2; }
  }
  if (x) { return 1; }
  return 0;
}
//@dump-sem-ir-end

// --- order.carbon
library "[[@TEST_NAME]]";

// Coverage is order-irrelevant: `case true` first, then `case false`, is
// exhaustive the same way exhaustive.carbon's domain order is.
//@dump-sem-ir-begin
fn TrueFirst(b: bool) -> i32 {
  match (b) {
    case true => { return 1; }
    case false => { return 0; }
  }
  return -1;
}
//@dump-sem-ir-end

// CHECK:STDOUT: --- exhaustive.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %pattern_type.831: type = pattern_type bool [concrete]
// CHECK:STDOUT:   %b.param_patt: %pattern_type.831 = value_param_pattern [concrete]
// CHECK:STDOUT:   %b.patt: %pattern_type.831 = wrapper_binding_pattern b, %b.param_patt [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %IsTrue.type: type = fn_type @IsTrue [concrete]
// CHECK:STDOUT:   %IsTrue: %IsTrue.type = struct_value () [concrete]
// CHECK:STDOUT:   %false: bool = bool_literal false [concrete]
// CHECK:STDOUT:   %EqWith.type.539: type = facet_type <@EqWith, @EqWith(bool)> [concrete]
// CHECK:STDOUT:   %EqWith.impl_witness: <witness> = impl_witness imports.%EqWith.impl_witness_table [concrete]
// CHECK:STDOUT:   %EqWith.facet: %EqWith.type.539 = facet_value bool, (%EqWith.impl_witness) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.f71: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(bool, %EqWith.facet) [concrete]
// CHECK:STDOUT:   %.4ef: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.f71, %EqWith.facet [concrete]
// CHECK:STDOUT:   %bool.as.EqWith.impl.Equal.type: type = fn_type @bool.as.EqWith.impl.Equal [concrete]
// CHECK:STDOUT:   %bool.as.EqWith.impl.Equal: %bool.as.EqWith.impl.Equal.type = struct_value () [concrete]
// CHECK:STDOUT:   %bool.as.EqWith.impl.Equal.bound.ed3: <bound method> = bound_method %false, %bool.as.EqWith.impl.Equal [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
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
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.6e0: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_0.3c0: %i32 = int_value 0 [concrete]
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete]
// CHECK:STDOUT:   %bool.as.EqWith.impl.Equal.bound.e7c: <bound method> = bound_method %true, %bool.as.EqWith.impl.Equal [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.953: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
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
// CHECK:STDOUT:   %bound_method.a65: <bound method> = bound_method %int_-1.638, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_-1.4ef: %i32 = int_value -1 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.a87: %bool.as.EqWith.impl.Equal.type = import_ref Core//prelude/operators/comparison, loc{{\d+_\d+}}, loaded [concrete = constants.%bool.as.EqWith.impl.Equal]
// CHECK:STDOUT:   %Core.import_ref.e3a = import_ref Core//prelude/operators/comparison, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table = impl_witness_table (%Core.import_ref.a87, %Core.import_ref.e3a), @bool.as.EqWith.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.abd = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9c3: %Core.IntLiteral.as.Negate.impl.Op.type = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, loaded [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %Negate.impl_witness_table = impl_witness_table (%Core.import_ref.abd, %Core.import_ref.9c3), @Core.IntLiteral.as.Negate.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %IsTrue.decl: %IsTrue.type = fn_decl @IsTrue [concrete = constants.%IsTrue] {
// CHECK:STDOUT:     %b.param_patt: %pattern_type.831 = value_param_pattern [concrete = constants.%b.param_patt]
// CHECK:STDOUT:     %b.patt: %pattern_type.831 = wrapper_binding_pattern b, %b.param_patt [concrete = constants.%b.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc11_23: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %b.param: bool = value_param call_param0
// CHECK:STDOUT:     %.loc11_14: type = type_literal bool [concrete = bool]
// CHECK:STDOUT:     %b: bool = wrapper_binding b, %b.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @IsTrue(%b.param: bool) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %b.ref: bool = name_ref b, %b
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt.loc13: %pattern_type.831 = expr_pattern %false in [concrete] {
// CHECK:STDOUT:       %false: bool = bool_literal false [concrete = constants.%false]
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %false: bool = bool_literal false [concrete = constants.%false]
// CHECK:STDOUT:   %impl.elem0.loc13_16: %.4ef = impl_witness_access constants.%EqWith.impl_witness, element0 [concrete = constants.%bool.as.EqWith.impl.Equal]
// CHECK:STDOUT:   %bound_method.loc13_16: <bound method> = bound_method %false, %impl.elem0.loc13_16 [concrete = constants.%bool.as.EqWith.impl.Equal.bound.ed3]
// CHECK:STDOUT:   %bool.as.EqWith.impl.Equal.call.loc13: init bool = call %bound_method.loc13_16(%false, %b.ref)
// CHECK:STDOUT:   %.loc13_16.1: bool = value_of_initializer %bool.as.EqWith.impl.Equal.call.loc13
// CHECK:STDOUT:   %.loc13_16.2: bool = converted %bool.as.EqWith.impl.Equal.call.loc13, %.loc13_16.1
// CHECK:STDOUT:   if %.loc13_16.2 br !match.case.then.loc13 else br !match.case.else.loc13
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc13:
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc13_29: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc13_29.1: <bound method> = bound_method %int_0, %impl.elem0.loc13_29 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc13: <specific function> = specific_function %impl.elem0.loc13_29, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc13_29.2: <bound method> = bound_method %int_0, %specific_fn.loc13 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13: init %i32 = call %bound_method.loc13_29.2(%int_0) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc13_29: init %i32 = converted %int_0, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   return %.loc13_29
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc13:
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt.loc14: %pattern_type.831 = expr_pattern %true in [concrete] {
// CHECK:STDOUT:       %true: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:   %impl.elem0.loc14_15: %.4ef = impl_witness_access constants.%EqWith.impl_witness, element0 [concrete = constants.%bool.as.EqWith.impl.Equal]
// CHECK:STDOUT:   %bound_method.loc14_15: <bound method> = bound_method %true, %impl.elem0.loc14_15 [concrete = constants.%bool.as.EqWith.impl.Equal.bound.e7c]
// CHECK:STDOUT:   %bool.as.EqWith.impl.Equal.call.loc14: init bool = call %bound_method.loc14_15(%true, %b.ref)
// CHECK:STDOUT:   %.loc14_15.1: bool = value_of_initializer %bool.as.EqWith.impl.Equal.call.loc14
// CHECK:STDOUT:   %.loc14_15.2: bool = converted %bool.as.EqWith.impl.Equal.call.loc14, %.loc14_15.1
// CHECK:STDOUT:   if %.loc14_15.2 br !match.case.then.loc14 else br !match.case.else.loc14
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc14:
// CHECK:STDOUT:   %int_1.loc14: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc14_28: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc14_28.1: <bound method> = bound_method %int_1.loc14, %impl.elem0.loc14_28 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc14: <specific function> = specific_function %impl.elem0.loc14_28, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc14_28.2: <bound method> = bound_method %int_1.loc14, %specific_fn.loc14 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14: init %i32 = call %bound_method.loc14_28.2(%int_1.loc14) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc14_28: init %i32 = converted %int_1.loc14, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   return %.loc14_28
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc14:
// CHECK:STDOUT:   br !match.done
// CHECK:STDOUT:
// CHECK:STDOUT: !match.done:
// CHECK:STDOUT:   %int_1.loc16: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem1: %.758 = impl_witness_access constants.%Negate.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %bound_method.loc16_10: <bound method> = bound_method %int_1.loc16, %impl.elem1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op.bound]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.call: init Core.IntLiteral = call %bound_method.loc16_10(%int_1.loc16) [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %impl.elem0.loc16: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc16_12.1: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %impl.elem0.loc16 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.65e]
// CHECK:STDOUT:   %specific_fn.loc16: <specific function> = specific_function %impl.elem0.loc16, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc16_12.2: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %specific_fn.loc16 [concrete = constants.%bound_method.a65]
// CHECK:STDOUT:   %.loc16_10.1: Core.IntLiteral = value_of_initializer %Core.IntLiteral.as.Negate.impl.Op.call [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %.loc16_10.2: Core.IntLiteral = converted %Core.IntLiteral.as.Negate.impl.Op.call, %.loc16_10.1 [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16: init %i32 = call %bound_method.loc16_12.2(%.loc16_10.2) [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   %.loc16_12: init %i32 = converted %Core.IntLiteral.as.Negate.impl.Op.call, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16 [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   return %.loc16_12
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- with_default.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %pattern_type.831: type = pattern_type bool [concrete]
// CHECK:STDOUT:   %b.param_patt: %pattern_type.831 = value_param_pattern [concrete]
// CHECK:STDOUT:   %b.patt: %pattern_type.831 = wrapper_binding_pattern b, %b.param_patt [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete]
// CHECK:STDOUT:   %EqWith.type.539: type = facet_type <@EqWith, @EqWith(bool)> [concrete]
// CHECK:STDOUT:   %EqWith.impl_witness: <witness> = impl_witness imports.%EqWith.impl_witness_table [concrete]
// CHECK:STDOUT:   %EqWith.facet: %EqWith.type.539 = facet_value bool, (%EqWith.impl_witness) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.f71: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(bool, %EqWith.facet) [concrete]
// CHECK:STDOUT:   %.4ef: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.f71, %EqWith.facet [concrete]
// CHECK:STDOUT:   %bool.as.EqWith.impl.Equal.type: type = fn_type @bool.as.EqWith.impl.Equal [concrete]
// CHECK:STDOUT:   %bool.as.EqWith.impl.Equal: %bool.as.EqWith.impl.Equal.type = struct_value () [concrete]
// CHECK:STDOUT:   %bool.as.EqWith.impl.Equal.bound: <bound method> = bound_method %true, %bool.as.EqWith.impl.Equal [concrete]
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
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.6e0: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_0.3c0: %i32 = int_value 0 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.a87: %bool.as.EqWith.impl.Equal.type = import_ref Core//prelude/operators/comparison, loc{{\d+_\d+}}, loaded [concrete = constants.%bool.as.EqWith.impl.Equal]
// CHECK:STDOUT:   %Core.import_ref.e3a = import_ref Core//prelude/operators/comparison, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table = impl_witness_table (%Core.import_ref.a87, %Core.import_ref.e3a), @bool.as.EqWith.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %F.decl: %F.type = fn_decl @F [concrete = constants.%F] {
// CHECK:STDOUT:     %b.param_patt: %pattern_type.831 = value_param_pattern [concrete = constants.%b.param_patt]
// CHECK:STDOUT:     %b.patt: %pattern_type.831 = wrapper_binding_pattern b, %b.param_patt [concrete = constants.%b.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc6_18: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %b.param: bool = value_param call_param0
// CHECK:STDOUT:     %.loc6_9: type = type_literal bool [concrete = bool]
// CHECK:STDOUT:     %b: bool = wrapper_binding b, %b.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @F(%b.param: bool) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %b.ref: bool = name_ref b, %b
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt: %pattern_type.831 = expr_pattern %true in [concrete] {
// CHECK:STDOUT:       %true: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:   %impl.elem0.loc8_15: %.4ef = impl_witness_access constants.%EqWith.impl_witness, element0 [concrete = constants.%bool.as.EqWith.impl.Equal]
// CHECK:STDOUT:   %bound_method.loc8_15: <bound method> = bound_method %true, %impl.elem0.loc8_15 [concrete = constants.%bool.as.EqWith.impl.Equal.bound]
// CHECK:STDOUT:   %bool.as.EqWith.impl.Equal.call: init bool = call %bound_method.loc8_15(%true, %b.ref)
// CHECK:STDOUT:   %.loc8_15.1: bool = value_of_initializer %bool.as.EqWith.impl.Equal.call
// CHECK:STDOUT:   %.loc8_15.2: bool = converted %bool.as.EqWith.impl.Equal.call, %.loc8_15.1
// CHECK:STDOUT:   if %.loc8_15.2 br !match.case.then else br !match.case.else
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then:
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc8_28: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc8_28.1: <bound method> = bound_method %int_1, %impl.elem0.loc8_28 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc8: <specific function> = specific_function %impl.elem0.loc8_28, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc8_28.2: <bound method> = bound_method %int_1, %specific_fn.loc8 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc8: init %i32 = call %bound_method.loc8_28.2(%int_1) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc8_28: init %i32 = converted %int_1, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc8 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   return %.loc8_28
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else:
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc9: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc9_26.1: <bound method> = bound_method %int_0, %impl.elem0.loc9 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc9: <specific function> = specific_function %impl.elem0.loc9, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc9_26.2: <bound method> = bound_method %int_0, %specific_fn.loc9 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc9: init %i32 = call %bound_method.loc9_26.2(%int_0) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc9: init %i32 = converted %int_0, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc9 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   return %.loc9
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- constant_expr_case.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @G(%b.param: bool) -> out %return.param: %i32;
// CHECK:STDOUT:
// CHECK:STDOUT: --- constant_scrutinee.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %H.type: type = fn_type @H [concrete]
// CHECK:STDOUT:   %H: %H.type = struct_value () [concrete]
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete]
// CHECK:STDOUT:   %false: bool = bool_literal false [concrete]
// CHECK:STDOUT:   %pattern_type.831: type = pattern_type bool [concrete]
// CHECK:STDOUT:   %EqWith.type.539: type = facet_type <@EqWith, @EqWith(bool)> [concrete]
// CHECK:STDOUT:   %EqWith.impl_witness: <witness> = impl_witness imports.%EqWith.impl_witness_table [concrete]
// CHECK:STDOUT:   %EqWith.facet: %EqWith.type.539 = facet_value bool, (%EqWith.impl_witness) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.f71: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(bool, %EqWith.facet) [concrete]
// CHECK:STDOUT:   %.4ef: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.f71, %EqWith.facet [concrete]
// CHECK:STDOUT:   %bool.as.EqWith.impl.Equal.type: type = fn_type @bool.as.EqWith.impl.Equal [concrete]
// CHECK:STDOUT:   %bool.as.EqWith.impl.Equal: %bool.as.EqWith.impl.Equal.type = struct_value () [concrete]
// CHECK:STDOUT:   %bool.as.EqWith.impl.Equal.bound.ed3: <bound method> = bound_method %false, %bool.as.EqWith.impl.Equal [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
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
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.6e0: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_0.3c0: %i32 = int_value 0 [concrete]
// CHECK:STDOUT:   %bool.as.EqWith.impl.Equal.bound.e7c: <bound method> = bound_method %true, %bool.as.EqWith.impl.Equal [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.953: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
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
// CHECK:STDOUT:   %bound_method.a65: <bound method> = bound_method %int_-1.638, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_-1.4ef: %i32 = int_value -1 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.a87: %bool.as.EqWith.impl.Equal.type = import_ref Core//prelude/operators/comparison, loc{{\d+_\d+}}, loaded [concrete = constants.%bool.as.EqWith.impl.Equal]
// CHECK:STDOUT:   %Core.import_ref.e3a = import_ref Core//prelude/operators/comparison, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table = impl_witness_table (%Core.import_ref.a87, %Core.import_ref.e3a), @bool.as.EqWith.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.abd = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9c3: %Core.IntLiteral.as.Negate.impl.Op.type = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, loaded [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %Negate.impl_witness_table = impl_witness_table (%Core.import_ref.abd, %Core.import_ref.9c3), @Core.IntLiteral.as.Negate.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %H.decl: %H.type = fn_decl @H [concrete = constants.%H] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc7: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param0
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @H() -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %true.loc8: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt.loc9: %pattern_type.831 = expr_pattern %false in [concrete] {
// CHECK:STDOUT:       %false: bool = bool_literal false [concrete = constants.%false]
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %false: bool = bool_literal false [concrete = constants.%false]
// CHECK:STDOUT:   %impl.elem0.loc9_16: %.4ef = impl_witness_access constants.%EqWith.impl_witness, element0 [concrete = constants.%bool.as.EqWith.impl.Equal]
// CHECK:STDOUT:   %bound_method.loc9_16: <bound method> = bound_method %false, %impl.elem0.loc9_16 [concrete = constants.%bool.as.EqWith.impl.Equal.bound.ed3]
// CHECK:STDOUT:   %bool.as.EqWith.impl.Equal.call.loc9: init bool = call %bound_method.loc9_16(%false, %true.loc8) [concrete = constants.%false]
// CHECK:STDOUT:   %.loc9_16.1: bool = value_of_initializer %bool.as.EqWith.impl.Equal.call.loc9 [concrete = constants.%false]
// CHECK:STDOUT:   %.loc9_16.2: bool = converted %bool.as.EqWith.impl.Equal.call.loc9, %.loc9_16.1 [concrete = constants.%false]
// CHECK:STDOUT:   if %.loc9_16.2 br !match.case.then.loc9 else br !match.case.else.loc9
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc9:
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc9_29: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc9_29.1: <bound method> = bound_method %int_0, %impl.elem0.loc9_29 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc9: <specific function> = specific_function %impl.elem0.loc9_29, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc9_29.2: <bound method> = bound_method %int_0, %specific_fn.loc9 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc9: init %i32 = call %bound_method.loc9_29.2(%int_0) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc9_29: init %i32 = converted %int_0, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc9 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   return %.loc9_29
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc9:
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt.loc10: %pattern_type.831 = expr_pattern %true.loc10 in [concrete] {
// CHECK:STDOUT:       %true.loc10: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %true.loc10: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:   %impl.elem0.loc10_15: %.4ef = impl_witness_access constants.%EqWith.impl_witness, element0 [concrete = constants.%bool.as.EqWith.impl.Equal]
// CHECK:STDOUT:   %bound_method.loc10_15: <bound method> = bound_method %true.loc10, %impl.elem0.loc10_15 [concrete = constants.%bool.as.EqWith.impl.Equal.bound.e7c]
// CHECK:STDOUT:   %bool.as.EqWith.impl.Equal.call.loc10: init bool = call %bound_method.loc10_15(%true.loc10, %true.loc8) [concrete = constants.%true]
// CHECK:STDOUT:   %.loc10_15.1: bool = value_of_initializer %bool.as.EqWith.impl.Equal.call.loc10 [concrete = constants.%true]
// CHECK:STDOUT:   %.loc10_15.2: bool = converted %bool.as.EqWith.impl.Equal.call.loc10, %.loc10_15.1 [concrete = constants.%true]
// CHECK:STDOUT:   if %.loc10_15.2 br !match.case.then.loc10 else br !match.case.else.loc10
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc10:
// CHECK:STDOUT:   %int_1.loc10: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc10_28: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc10_28.1: <bound method> = bound_method %int_1.loc10, %impl.elem0.loc10_28 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc10: <specific function> = specific_function %impl.elem0.loc10_28, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc10_28.2: <bound method> = bound_method %int_1.loc10, %specific_fn.loc10 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc10: init %i32 = call %bound_method.loc10_28.2(%int_1.loc10) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc10_28: init %i32 = converted %int_1.loc10, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc10 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   return %.loc10_28
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc10:
// CHECK:STDOUT:   br !match.done
// CHECK:STDOUT:
// CHECK:STDOUT: !match.done:
// CHECK:STDOUT:   %int_1.loc12: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem1: %.758 = impl_witness_access constants.%Negate.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %bound_method.loc12_10: <bound method> = bound_method %int_1.loc12, %impl.elem1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op.bound]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.call: init Core.IntLiteral = call %bound_method.loc12_10(%int_1.loc12) [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %impl.elem0.loc12: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc12_12.1: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %impl.elem0.loc12 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.65e]
// CHECK:STDOUT:   %specific_fn.loc12: <specific function> = specific_function %impl.elem0.loc12, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc12_12.2: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %specific_fn.loc12 [concrete = constants.%bound_method.a65]
// CHECK:STDOUT:   %.loc12_10.1: Core.IntLiteral = value_of_initializer %Core.IntLiteral.as.Negate.impl.Op.call [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %.loc12_10.2: Core.IntLiteral = converted %Core.IntLiteral.as.Negate.impl.Op.call, %.loc12_10.1 [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc12: init %i32 = call %bound_method.loc12_12.2(%.loc12_10.2) [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   %.loc12_12: init %i32 = converted %Core.IntLiteral.as.Negate.impl.Op.call, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc12 [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   return %.loc12_12
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- compose.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %pattern_type.831: type = pattern_type bool [concrete]
// CHECK:STDOUT:   %b.param_patt: %pattern_type.831 = value_param_pattern [concrete]
// CHECK:STDOUT:   %b.patt: %pattern_type.831 = wrapper_binding_pattern b, %b.param_patt [concrete]
// CHECK:STDOUT:   %c.param_patt: %pattern_type.831 = value_param_pattern [concrete]
// CHECK:STDOUT:   %c.patt: %pattern_type.831 = wrapper_binding_pattern c, %c.param_patt [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %Compose.type: type = fn_type @Compose [concrete]
// CHECK:STDOUT:   %Compose: %Compose.type = struct_value () [concrete]
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete]
// CHECK:STDOUT:   %EqWith.type.539: type = facet_type <@EqWith, @EqWith(bool)> [concrete]
// CHECK:STDOUT:   %EqWith.impl_witness: <witness> = impl_witness imports.%EqWith.impl_witness_table [concrete]
// CHECK:STDOUT:   %EqWith.facet: %EqWith.type.539 = facet_value bool, (%EqWith.impl_witness) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.f71: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(bool, %EqWith.facet) [concrete]
// CHECK:STDOUT:   %.4ef: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.f71, %EqWith.facet [concrete]
// CHECK:STDOUT:   %bool.as.EqWith.impl.Equal.type: type = fn_type @bool.as.EqWith.impl.Equal [concrete]
// CHECK:STDOUT:   %bool.as.EqWith.impl.Equal: %bool.as.EqWith.impl.Equal.type = struct_value () [concrete]
// CHECK:STDOUT:   %bool.as.EqWith.impl.Equal.bound: <bound method> = bound_method %true, %bool.as.EqWith.impl.Equal [concrete]
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
// CHECK:STDOUT:   %b2.patt: %pattern_type.831 = value_binding_pattern b2 [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.953: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.6e0: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_0.3c0: %i32 = int_value 0 [concrete]
// CHECK:STDOUT:   %Negate.type: type = facet_type <@Negate> [concrete]
// CHECK:STDOUT:   %Negate.impl_witness: <witness> = impl_witness imports.%Negate.impl_witness_table [concrete]
// CHECK:STDOUT:   %Negate.facet: %Negate.type = facet_value Core.IntLiteral, (%Negate.impl_witness) [concrete]
// CHECK:STDOUT:   %Negate.WithSelf.Op.type.e85: type = fn_type @Negate.WithSelf.Op, @Negate.WithSelf(%Negate.facet) [concrete]
// CHECK:STDOUT:   %.758: type = fn_type_with_self_type %Negate.WithSelf.Op.type.e85, %Negate.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.type: type = fn_type @Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op: %Core.IntLiteral.as.Negate.impl.Op.type = struct_value () [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.bound.e21: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %int_-2.962: Core.IntLiteral = int_value -2 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.2a0: <bound method> = bound_method %int_-2.962, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.33f: <bound method> = bound_method %int_-2.962, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_-2.c83: %i32 = int_value -2 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.a87: %bool.as.EqWith.impl.Equal.type = import_ref Core//prelude/operators/comparison, loc{{\d+_\d+}}, loaded [concrete = constants.%bool.as.EqWith.impl.Equal]
// CHECK:STDOUT:   %Core.import_ref.e3a = import_ref Core//prelude/operators/comparison, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table = impl_witness_table (%Core.import_ref.a87, %Core.import_ref.e3a), @bool.as.EqWith.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.abd = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9c3: %Core.IntLiteral.as.Negate.impl.Op.type = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, loaded [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %Negate.impl_witness_table = impl_witness_table (%Core.import_ref.abd, %Core.import_ref.9c3), @Core.IntLiteral.as.Negate.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Compose.decl: %Compose.type = fn_decl @Compose [concrete = constants.%Compose] {
// CHECK:STDOUT:     %b.param_patt: %pattern_type.831 = value_param_pattern [concrete = constants.%b.param_patt]
// CHECK:STDOUT:     %b.patt: %pattern_type.831 = wrapper_binding_pattern b, %b.param_patt [concrete = constants.%b.patt]
// CHECK:STDOUT:     %c.param_patt: %pattern_type.831 = value_param_pattern [concrete = constants.%c.param_patt]
// CHECK:STDOUT:     %c.patt: %pattern_type.831 = wrapper_binding_pattern c, %c.param_patt [concrete = constants.%c.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc7_33: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %b.param: bool = value_param call_param0
// CHECK:STDOUT:     %.loc7_15: type = type_literal bool [concrete = bool]
// CHECK:STDOUT:     %b: bool = wrapper_binding b, %b.param
// CHECK:STDOUT:     %c.param: bool = value_param call_param1
// CHECK:STDOUT:     %.loc7_24: type = type_literal bool [concrete = bool]
// CHECK:STDOUT:     %c: bool = wrapper_binding c, %c.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param2
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Compose(%b.param: bool, %c.param: bool) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %b.ref: bool = name_ref b, %b
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt: %pattern_type.831 = expr_pattern %true.loc9 in [concrete] {
// CHECK:STDOUT:       %true.loc9: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %true.loc9: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:   %impl.elem0.loc9_15: %.4ef = impl_witness_access constants.%EqWith.impl_witness, element0 [concrete = constants.%bool.as.EqWith.impl.Equal]
// CHECK:STDOUT:   %bound_method.loc9_15: <bound method> = bound_method %true.loc9, %impl.elem0.loc9_15 [concrete = constants.%bool.as.EqWith.impl.Equal.bound]
// CHECK:STDOUT:   %bool.as.EqWith.impl.Equal.call: init bool = call %bound_method.loc9_15(%true.loc9, %b.ref)
// CHECK:STDOUT:   %.loc9_15.1: bool = value_of_initializer %bool.as.EqWith.impl.Equal.call
// CHECK:STDOUT:   %.loc9_15.2: bool = converted %bool.as.EqWith.impl.Equal.call, %.loc9_15.1
// CHECK:STDOUT:   if %.loc9_15.2 br !.loc9_15.1 else br !.loc9_15.2
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc9_15.1:
// CHECK:STDOUT:   %c.ref: bool = name_ref c, %c
// CHECK:STDOUT:   if %c.ref br !.loc9_20 else br !.loc9_15.2
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc9_20:
// CHECK:STDOUT:   %int_2.loc9: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:   %impl.elem0.loc9_35: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc9_35.1: <bound method> = bound_method %int_2.loc9, %impl.elem0.loc9_35 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.9f3]
// CHECK:STDOUT:   %specific_fn.loc9: <specific function> = specific_function %impl.elem0.loc9_35, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc9_35.2: <bound method> = bound_method %int_2.loc9, %specific_fn.loc9 [concrete = constants.%bound_method.3cb]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc9: init %i32 = call %bound_method.loc9_35.2(%int_2.loc9) [concrete = constants.%int_2.295]
// CHECK:STDOUT:   %.loc9_35: init %i32 = converted %int_2.loc9, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc9 [concrete = constants.%int_2.295]
// CHECK:STDOUT:   return %.loc9_35
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc9_15.2:
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %b2.patt: %pattern_type.831 = value_binding_pattern b2 [concrete = constants.%b2.patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %true.loc10: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:   if %true.loc10 br !match.case.then else br !match.case.else
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then:
// CHECK:STDOUT:   %.loc10_14: type = type_literal bool [concrete = bool]
// CHECK:STDOUT:   %b2: bool = wrapper_binding b2, %b.ref
// CHECK:STDOUT:   %b2.ref: bool = name_ref b2, %b2
// CHECK:STDOUT:   if %b2.ref br !if.then else br !if.else
// CHECK:STDOUT:
// CHECK:STDOUT: !if.then:
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc10_42: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc10_42.1: <bound method> = bound_method %int_1, %impl.elem0.loc10_42 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc10_42: <specific function> = specific_function %impl.elem0.loc10_42, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc10_42.2: <bound method> = bound_method %int_1, %specific_fn.loc10_42 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc10_42: init %i32 = call %bound_method.loc10_42.2(%int_1) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc10_42: init %i32 = converted %int_1, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc10_42 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   return %.loc10_42
// CHECK:STDOUT:
// CHECK:STDOUT: !if.else:
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc10_54: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc10_54.1: <bound method> = bound_method %int_0, %impl.elem0.loc10_54 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc10_54: <specific function> = specific_function %impl.elem0.loc10_54, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc10_54.2: <bound method> = bound_method %int_0, %specific_fn.loc10_54 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc10_54: init %i32 = call %bound_method.loc10_54.2(%int_0) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc10_54: init %i32 = converted %int_0, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc10_54 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   return %.loc10_54
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else:
// CHECK:STDOUT:   %int_2.loc11: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:   %impl.elem1: %.758 = impl_witness_access constants.%Negate.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %bound_method.loc11_25: <bound method> = bound_method %int_2.loc11, %impl.elem1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op.bound.e21]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.call: init Core.IntLiteral = call %bound_method.loc11_25(%int_2.loc11) [concrete = constants.%int_-2.962]
// CHECK:STDOUT:   %impl.elem0.loc11: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc11_27.1: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %impl.elem0.loc11 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.2a0]
// CHECK:STDOUT:   %specific_fn.loc11: <specific function> = specific_function %impl.elem0.loc11, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc11_27.2: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %specific_fn.loc11 [concrete = constants.%bound_method.33f]
// CHECK:STDOUT:   %.loc11_25.1: Core.IntLiteral = value_of_initializer %Core.IntLiteral.as.Negate.impl.Op.call [concrete = constants.%int_-2.962]
// CHECK:STDOUT:   %.loc11_25.2: Core.IntLiteral = converted %Core.IntLiteral.as.Negate.impl.Op.call, %.loc11_25.1 [concrete = constants.%int_-2.962]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc11: init %i32 = call %bound_method.loc11_27.2(%.loc11_25.2) [concrete = constants.%int_-2.c83]
// CHECK:STDOUT:   %.loc11_27: init %i32 = converted %Core.IntLiteral.as.Negate.impl.Op.call, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc11 [concrete = constants.%int_-2.c83]
// CHECK:STDOUT:   return %.loc11_27
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- var_ref_binding.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %pattern_type.831: type = pattern_type bool [concrete]
// CHECK:STDOUT:   %b.param_patt: %pattern_type.831 = value_param_pattern [concrete]
// CHECK:STDOUT:   %b.patt: %pattern_type.831 = wrapper_binding_pattern b, %b.param_patt [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %VarBinding.type: type = fn_type @VarBinding [concrete]
// CHECK:STDOUT:   %VarBinding: %VarBinding.type = struct_value () [concrete]
// CHECK:STDOUT:   %v.patt: %pattern_type.831 = ref_binding_pattern v [concrete]
// CHECK:STDOUT:   %v.var_patt: %pattern_type.831 = var_pattern %v.patt [concrete]
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %Copy.impl_witness.5e1: <witness> = impl_witness imports.%Copy.impl_witness_table.bda [concrete]
// CHECK:STDOUT:   %Copy.facet: %Copy.type = facet_value bool, (%Copy.impl_witness.5e1) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.d02: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet) [concrete]
// CHECK:STDOUT:   %.e28: type = fn_type_with_self_type %Copy.WithSelf.Op.type.d02, %Copy.facet [concrete]
// CHECK:STDOUT:   %bool.as.Copy.impl.Op.type: type = fn_type @bool.as.Copy.impl.Op [concrete]
// CHECK:STDOUT:   %bool.as.Copy.impl.Op: %bool.as.Copy.impl.Op.type = struct_value () [concrete]
// CHECK:STDOUT:   %false: bool = bool_literal false [concrete]
// CHECK:STDOUT:   %bool.as.Copy.impl.Op.bound.84b: <bound method> = bound_method %false, %bool.as.Copy.impl.Op [concrete]
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
// CHECK:STDOUT:   %Destroy.Op.type: type = fn_type @Destroy.Op [concrete]
// CHECK:STDOUT:   %Destroy.Op: %Destroy.Op.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.6e0: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_0.3c0: %i32 = int_value 0 [concrete]
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %Negate.type: type = facet_type <@Negate> [concrete]
// CHECK:STDOUT:   %Negate.impl_witness: <witness> = impl_witness imports.%Negate.impl_witness_table [concrete]
// CHECK:STDOUT:   %Negate.facet: %Negate.type = facet_value Core.IntLiteral, (%Negate.impl_witness) [concrete]
// CHECK:STDOUT:   %Negate.WithSelf.Op.type.e85: type = fn_type @Negate.WithSelf.Op, @Negate.WithSelf(%Negate.facet) [concrete]
// CHECK:STDOUT:   %.758: type = fn_type_with_self_type %Negate.WithSelf.Op.type.e85, %Negate.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.type: type = fn_type @Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op: %Core.IntLiteral.as.Negate.impl.Op.type = struct_value () [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.bound.e21: <bound method> = bound_method %int_2, %Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %int_-2.962: Core.IntLiteral = int_value -2 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.2a0: <bound method> = bound_method %int_-2.962, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.33f: <bound method> = bound_method %int_-2.962, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_-2.c83: %i32 = int_value -2 [concrete]
// CHECK:STDOUT:   %RefBinding.type: type = fn_type @RefBinding [concrete]
// CHECK:STDOUT:   %RefBinding: %RefBinding.type = struct_value () [concrete]
// CHECK:STDOUT:   %x.patt: %pattern_type.831 = ref_binding_pattern x [concrete]
// CHECK:STDOUT:   %x.var_patt: %pattern_type.831 = var_pattern %x.patt [concrete]
// CHECK:STDOUT:   %bool.as.Copy.impl.Op.bound.1b3: <bound method> = bound_method %true, %bool.as.Copy.impl.Op [concrete]
// CHECK:STDOUT:   %r.patt: %pattern_type.831 = ref_binding_pattern r [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.9c3475.1: %bool.as.Copy.impl.Op.type = import_ref Core//prelude/copy, loc{{\d+_\d+}}, loaded [concrete = constants.%bool.as.Copy.impl.Op]
// CHECK:STDOUT:   %Copy.impl_witness_table.bda = impl_witness_table (%Core.import_ref.9c3475.1), @bool.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.abd = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9c3475.2: %Core.IntLiteral.as.Negate.impl.Op.type = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, loaded [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %Negate.impl_witness_table = impl_witness_table (%Core.import_ref.abd, %Core.import_ref.9c3475.2), @Core.IntLiteral.as.Negate.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %VarBinding.decl: %VarBinding.type = fn_decl @VarBinding [concrete = constants.%VarBinding] {
// CHECK:STDOUT:     %b.param_patt: %pattern_type.831 = value_param_pattern [concrete = constants.%b.param_patt]
// CHECK:STDOUT:     %b.patt: %pattern_type.831 = wrapper_binding_pattern b, %b.param_patt [concrete = constants.%b.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc7_27: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %b.param: bool = value_param call_param0
// CHECK:STDOUT:     %.loc7_18: type = type_literal bool [concrete = bool]
// CHECK:STDOUT:     %b: bool = wrapper_binding b, %b.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %RefBinding.decl: %RefBinding.type = fn_decl @RefBinding [concrete = constants.%RefBinding] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc15: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param0
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @VarBinding(%b.param: bool) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %b.ref: bool = name_ref b, %b
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %v.patt: %pattern_type.831 = ref_binding_pattern v [concrete = constants.%v.patt]
// CHECK:STDOUT:     %v.var_patt: %pattern_type.831 = var_pattern %v.patt [concrete = constants.%v.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:   if %true br !match.case.then else br !match.case.else
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then:
// CHECK:STDOUT:   %v.var: ref bool = var_storage %v.var_patt
// CHECK:STDOUT:   %impl.elem0.loc8: %.e28 = impl_witness_access constants.%Copy.impl_witness.5e1, element0 [concrete = constants.%bool.as.Copy.impl.Op]
// CHECK:STDOUT:   %bound_method.loc8: <bound method> = bound_method %b.ref, %impl.elem0.loc8
// CHECK:STDOUT:   %bool.as.Copy.impl.Op.call.loc8: init bool = call %bound_method.loc8(%b.ref)
// CHECK:STDOUT:   assign %v.var, %bool.as.Copy.impl.Op.call.loc8
// CHECK:STDOUT:   %.loc9_17: type = type_literal bool [concrete = bool]
// CHECK:STDOUT:   %v: ref bool = wrapper_binding v, %v.var
// CHECK:STDOUT:   %v.ref.loc9_27: ref bool = name_ref v, %v
// CHECK:STDOUT:   %false: bool = bool_literal false [concrete = constants.%false]
// CHECK:STDOUT:   %impl.elem0.loc9_31: %.e28 = impl_witness_access constants.%Copy.impl_witness.5e1, element0 [concrete = constants.%bool.as.Copy.impl.Op]
// CHECK:STDOUT:   %bound_method.loc9_31: <bound method> = bound_method %false, %impl.elem0.loc9_31 [concrete = constants.%bool.as.Copy.impl.Op.bound.84b]
// CHECK:STDOUT:   %bool.as.Copy.impl.Op.call.loc9: init bool = call %bound_method.loc9_31(%false) [concrete = constants.%false]
// CHECK:STDOUT:   assign %v.ref.loc9_27, %bool.as.Copy.impl.Op.call.loc9
// CHECK:STDOUT:   %v.ref.loc9_42: ref bool = name_ref v, %v
// CHECK:STDOUT:   %.loc9_42: bool = acquire_value %v.ref.loc9_42
// CHECK:STDOUT:   if %.loc9_42 br !if.then else br !if.else
// CHECK:STDOUT:
// CHECK:STDOUT: !if.then:
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc9_55: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc9_55.1: <bound method> = bound_method %int_1, %impl.elem0.loc9_55 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc9_55: <specific function> = specific_function %impl.elem0.loc9_55, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc9_55.2: <bound method> = bound_method %int_1, %specific_fn.loc9_55 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc9_55: init %i32 = call %bound_method.loc9_55.2(%int_1) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc9_55: init %i32 = converted %int_1, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc9_55 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %Destroy.Op.bound.loc9_10.1: <bound method> = bound_method %v.var, constants.%Destroy.Op
// CHECK:STDOUT:   %Destroy.Op.call.loc9_10.1: init %empty_tuple.type = call %Destroy.Op.bound.loc9_10.1(%v.var)
// CHECK:STDOUT:   return %.loc9_55
// CHECK:STDOUT:
// CHECK:STDOUT: !if.else:
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc9_67: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc9_67.1: <bound method> = bound_method %int_0, %impl.elem0.loc9_67 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc9_67: <specific function> = specific_function %impl.elem0.loc9_67, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc9_67.2: <bound method> = bound_method %int_0, %specific_fn.loc9_67 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc9_67: init %i32 = call %bound_method.loc9_67.2(%int_0) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc9_67: init %i32 = converted %int_0, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc9_67 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %Destroy.Op.bound.loc9_10.2: <bound method> = bound_method %v.var, constants.%Destroy.Op
// CHECK:STDOUT:   %Destroy.Op.call.loc9_10.2: init %empty_tuple.type = call %Destroy.Op.bound.loc9_10.2(%v.var)
// CHECK:STDOUT:   return %.loc9_67
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else:
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2]
// CHECK:STDOUT:   %impl.elem1: %.758 = impl_witness_access constants.%Negate.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %bound_method.loc10_25: <bound method> = bound_method %int_2, %impl.elem1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op.bound.e21]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.call: init Core.IntLiteral = call %bound_method.loc10_25(%int_2) [concrete = constants.%int_-2.962]
// CHECK:STDOUT:   %impl.elem0.loc10: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc10_27.1: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %impl.elem0.loc10 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.2a0]
// CHECK:STDOUT:   %specific_fn.loc10: <specific function> = specific_function %impl.elem0.loc10, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc10_27.2: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %specific_fn.loc10 [concrete = constants.%bound_method.33f]
// CHECK:STDOUT:   %.loc10_25.1: Core.IntLiteral = value_of_initializer %Core.IntLiteral.as.Negate.impl.Op.call [concrete = constants.%int_-2.962]
// CHECK:STDOUT:   %.loc10_25.2: Core.IntLiteral = converted %Core.IntLiteral.as.Negate.impl.Op.call, %.loc10_25.1 [concrete = constants.%int_-2.962]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc10: init %i32 = call %bound_method.loc10_27.2(%.loc10_25.2) [concrete = constants.%int_-2.c83]
// CHECK:STDOUT:   %.loc10_27: init %i32 = converted %Core.IntLiteral.as.Negate.impl.Op.call, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc10 [concrete = constants.%int_-2.c83]
// CHECK:STDOUT:   return %.loc10_27
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op(%self.param: ref bool) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @RefBinding() -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %x.var: ref bool = var_storage %x.var_patt
// CHECK:STDOUT:   %true.loc16: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:   %impl.elem0.loc16: %.e28 = impl_witness_access constants.%Copy.impl_witness.5e1, element0 [concrete = constants.%bool.as.Copy.impl.Op]
// CHECK:STDOUT:   %bound_method.loc16: <bound method> = bound_method %true.loc16, %impl.elem0.loc16 [concrete = constants.%bool.as.Copy.impl.Op.bound.1b3]
// CHECK:STDOUT:   %bool.as.Copy.impl.Op.call.loc16: init bool = call %bound_method.loc16(%true.loc16) [concrete = constants.%true]
// CHECK:STDOUT:   assign %x.var, %bool.as.Copy.impl.Op.call.loc16
// CHECK:STDOUT:   %.loc16: type = type_literal bool [concrete = bool]
// CHECK:STDOUT:   %x: ref bool = wrapper_binding x, %x.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %x.patt: %pattern_type.831 = ref_binding_pattern x [concrete = constants.%x.patt]
// CHECK:STDOUT:     %x.var_patt: %pattern_type.831 = var_pattern %x.patt [concrete = constants.%x.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %x.ref.loc17: ref bool = name_ref x, %x
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %r.patt: %pattern_type.831 = ref_binding_pattern r [concrete = constants.%r.patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %true.loc18: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:   if %true.loc18 br !match.case.then else br !match.case.else
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then:
// CHECK:STDOUT:   %.loc18: type = type_literal bool [concrete = bool]
// CHECK:STDOUT:   %r: ref bool = wrapper_binding r, %x.ref.loc17
// CHECK:STDOUT:   %r.ref: ref bool = name_ref r, %r
// CHECK:STDOUT:   %false: bool = bool_literal false [concrete = constants.%false]
// CHECK:STDOUT:   %impl.elem0.loc18: %.e28 = impl_witness_access constants.%Copy.impl_witness.5e1, element0 [concrete = constants.%bool.as.Copy.impl.Op]
// CHECK:STDOUT:   %bound_method.loc18: <bound method> = bound_method %false, %impl.elem0.loc18 [concrete = constants.%bool.as.Copy.impl.Op.bound.84b]
// CHECK:STDOUT:   %bool.as.Copy.impl.Op.call.loc18: init bool = call %bound_method.loc18(%false) [concrete = constants.%false]
// CHECK:STDOUT:   assign %r.ref, %bool.as.Copy.impl.Op.call.loc18
// CHECK:STDOUT:   br !match.done
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else:
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2]
// CHECK:STDOUT:   %impl.elem1: %.758 = impl_witness_access constants.%Negate.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %bound_method.loc19_25: <bound method> = bound_method %int_2, %impl.elem1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op.bound.e21]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.call: init Core.IntLiteral = call %bound_method.loc19_25(%int_2) [concrete = constants.%int_-2.962]
// CHECK:STDOUT:   %impl.elem0.loc19: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc19_27.1: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %impl.elem0.loc19 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.2a0]
// CHECK:STDOUT:   %specific_fn.loc19: <specific function> = specific_function %impl.elem0.loc19, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc19_27.2: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %specific_fn.loc19 [concrete = constants.%bound_method.33f]
// CHECK:STDOUT:   %.loc19_25.1: Core.IntLiteral = value_of_initializer %Core.IntLiteral.as.Negate.impl.Op.call [concrete = constants.%int_-2.962]
// CHECK:STDOUT:   %.loc19_25.2: Core.IntLiteral = converted %Core.IntLiteral.as.Negate.impl.Op.call, %.loc19_25.1 [concrete = constants.%int_-2.962]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc19: init %i32 = call %bound_method.loc19_27.2(%.loc19_25.2) [concrete = constants.%int_-2.c83]
// CHECK:STDOUT:   %.loc19_27: init %i32 = converted %Core.IntLiteral.as.Negate.impl.Op.call, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc19 [concrete = constants.%int_-2.c83]
// CHECK:STDOUT:   %Destroy.Op.bound.loc16_3.1: <bound method> = bound_method %x.var, constants.%Destroy.Op
// CHECK:STDOUT:   %Destroy.Op.call.loc16_3.1: init %empty_tuple.type = call %Destroy.Op.bound.loc16_3.1(%x.var)
// CHECK:STDOUT:   return %.loc19_27
// CHECK:STDOUT:
// CHECK:STDOUT: !match.done:
// CHECK:STDOUT:   %x.ref.loc21: ref bool = name_ref x, %x
// CHECK:STDOUT:   %.loc21_7: bool = acquire_value %x.ref.loc21
// CHECK:STDOUT:   if %.loc21_7 br !if.then else br !if.else
// CHECK:STDOUT:
// CHECK:STDOUT: !if.then:
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc21: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc21_20.1: <bound method> = bound_method %int_1, %impl.elem0.loc21 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc21: <specific function> = specific_function %impl.elem0.loc21, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc21_20.2: <bound method> = bound_method %int_1, %specific_fn.loc21 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc21: init %i32 = call %bound_method.loc21_20.2(%int_1) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc21_20: init %i32 = converted %int_1, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc21 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %Destroy.Op.bound.loc16_3.2: <bound method> = bound_method %x.var, constants.%Destroy.Op
// CHECK:STDOUT:   %Destroy.Op.call.loc16_3.2: init %empty_tuple.type = call %Destroy.Op.bound.loc16_3.2(%x.var)
// CHECK:STDOUT:   return %.loc21_20
// CHECK:STDOUT:
// CHECK:STDOUT: !if.else:
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc22: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc22_11.1: <bound method> = bound_method %int_0, %impl.elem0.loc22 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc22: <specific function> = specific_function %impl.elem0.loc22, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc22_11.2: <bound method> = bound_method %int_0, %specific_fn.loc22 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc22: init %i32 = call %bound_method.loc22_11.2(%int_0) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc22: init %i32 = converted %int_0, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc22 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %Destroy.Op.bound.loc16_3.3: <bound method> = bound_method %x.var, constants.%Destroy.Op
// CHECK:STDOUT:   %Destroy.Op.call.loc16_3.3: init %empty_tuple.type = call %Destroy.Op.bound.loc16_3.3(%x.var)
// CHECK:STDOUT:   return %.loc22
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- order.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %pattern_type.831: type = pattern_type bool [concrete]
// CHECK:STDOUT:   %b.param_patt: %pattern_type.831 = value_param_pattern [concrete]
// CHECK:STDOUT:   %b.patt: %pattern_type.831 = wrapper_binding_pattern b, %b.param_patt [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %TrueFirst.type: type = fn_type @TrueFirst [concrete]
// CHECK:STDOUT:   %TrueFirst: %TrueFirst.type = struct_value () [concrete]
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete]
// CHECK:STDOUT:   %EqWith.type.539: type = facet_type <@EqWith, @EqWith(bool)> [concrete]
// CHECK:STDOUT:   %EqWith.impl_witness: <witness> = impl_witness imports.%EqWith.impl_witness_table [concrete]
// CHECK:STDOUT:   %EqWith.facet: %EqWith.type.539 = facet_value bool, (%EqWith.impl_witness) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.f71: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(bool, %EqWith.facet) [concrete]
// CHECK:STDOUT:   %.4ef: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.f71, %EqWith.facet [concrete]
// CHECK:STDOUT:   %bool.as.EqWith.impl.Equal.type: type = fn_type @bool.as.EqWith.impl.Equal [concrete]
// CHECK:STDOUT:   %bool.as.EqWith.impl.Equal: %bool.as.EqWith.impl.Equal.type = struct_value () [concrete]
// CHECK:STDOUT:   %bool.as.EqWith.impl.Equal.bound.e7c: <bound method> = bound_method %true, %bool.as.EqWith.impl.Equal [concrete]
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
// CHECK:STDOUT:   %false: bool = bool_literal false [concrete]
// CHECK:STDOUT:   %bool.as.EqWith.impl.Equal.bound.ed3: <bound method> = bound_method %false, %bool.as.EqWith.impl.Equal [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.6e0: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_0.3c0: %i32 = int_value 0 [concrete]
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
// CHECK:STDOUT:   %bound_method.a65: <bound method> = bound_method %int_-1.638, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_-1.4ef: %i32 = int_value -1 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.a87: %bool.as.EqWith.impl.Equal.type = import_ref Core//prelude/operators/comparison, loc{{\d+_\d+}}, loaded [concrete = constants.%bool.as.EqWith.impl.Equal]
// CHECK:STDOUT:   %Core.import_ref.e3a = import_ref Core//prelude/operators/comparison, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table = impl_witness_table (%Core.import_ref.a87, %Core.import_ref.e3a), @bool.as.EqWith.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.abd = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9c3: %Core.IntLiteral.as.Negate.impl.Op.type = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, loaded [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %Negate.impl_witness_table = impl_witness_table (%Core.import_ref.abd, %Core.import_ref.9c3), @Core.IntLiteral.as.Negate.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %TrueFirst.decl: %TrueFirst.type = fn_decl @TrueFirst [concrete = constants.%TrueFirst] {
// CHECK:STDOUT:     %b.param_patt: %pattern_type.831 = value_param_pattern [concrete = constants.%b.param_patt]
// CHECK:STDOUT:     %b.patt: %pattern_type.831 = wrapper_binding_pattern b, %b.param_patt [concrete = constants.%b.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc6_26: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %b.param: bool = value_param call_param0
// CHECK:STDOUT:     %.loc6_17: type = type_literal bool [concrete = bool]
// CHECK:STDOUT:     %b: bool = wrapper_binding b, %b.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @TrueFirst(%b.param: bool) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %b.ref: bool = name_ref b, %b
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt.loc8: %pattern_type.831 = expr_pattern %true in [concrete] {
// CHECK:STDOUT:       %true: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:   %impl.elem0.loc8_15: %.4ef = impl_witness_access constants.%EqWith.impl_witness, element0 [concrete = constants.%bool.as.EqWith.impl.Equal]
// CHECK:STDOUT:   %bound_method.loc8_15: <bound method> = bound_method %true, %impl.elem0.loc8_15 [concrete = constants.%bool.as.EqWith.impl.Equal.bound.e7c]
// CHECK:STDOUT:   %bool.as.EqWith.impl.Equal.call.loc8: init bool = call %bound_method.loc8_15(%true, %b.ref)
// CHECK:STDOUT:   %.loc8_15.1: bool = value_of_initializer %bool.as.EqWith.impl.Equal.call.loc8
// CHECK:STDOUT:   %.loc8_15.2: bool = converted %bool.as.EqWith.impl.Equal.call.loc8, %.loc8_15.1
// CHECK:STDOUT:   if %.loc8_15.2 br !match.case.then.loc8 else br !match.case.else.loc8
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc8:
// CHECK:STDOUT:   %int_1.loc8: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc8_28: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc8_28.1: <bound method> = bound_method %int_1.loc8, %impl.elem0.loc8_28 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc8: <specific function> = specific_function %impl.elem0.loc8_28, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc8_28.2: <bound method> = bound_method %int_1.loc8, %specific_fn.loc8 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc8: init %i32 = call %bound_method.loc8_28.2(%int_1.loc8) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc8_28: init %i32 = converted %int_1.loc8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc8 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   return %.loc8_28
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc8:
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt.loc9: %pattern_type.831 = expr_pattern %false in [concrete] {
// CHECK:STDOUT:       %false: bool = bool_literal false [concrete = constants.%false]
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %false: bool = bool_literal false [concrete = constants.%false]
// CHECK:STDOUT:   %impl.elem0.loc9_16: %.4ef = impl_witness_access constants.%EqWith.impl_witness, element0 [concrete = constants.%bool.as.EqWith.impl.Equal]
// CHECK:STDOUT:   %bound_method.loc9_16: <bound method> = bound_method %false, %impl.elem0.loc9_16 [concrete = constants.%bool.as.EqWith.impl.Equal.bound.ed3]
// CHECK:STDOUT:   %bool.as.EqWith.impl.Equal.call.loc9: init bool = call %bound_method.loc9_16(%false, %b.ref)
// CHECK:STDOUT:   %.loc9_16.1: bool = value_of_initializer %bool.as.EqWith.impl.Equal.call.loc9
// CHECK:STDOUT:   %.loc9_16.2: bool = converted %bool.as.EqWith.impl.Equal.call.loc9, %.loc9_16.1
// CHECK:STDOUT:   if %.loc9_16.2 br !match.case.then.loc9 else br !match.case.else.loc9
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc9:
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc9_29: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc9_29.1: <bound method> = bound_method %int_0, %impl.elem0.loc9_29 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc9: <specific function> = specific_function %impl.elem0.loc9_29, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc9_29.2: <bound method> = bound_method %int_0, %specific_fn.loc9 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc9: init %i32 = call %bound_method.loc9_29.2(%int_0) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc9_29: init %i32 = converted %int_0, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc9 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   return %.loc9_29
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc9:
// CHECK:STDOUT:   br !match.done
// CHECK:STDOUT:
// CHECK:STDOUT: !match.done:
// CHECK:STDOUT:   %int_1.loc11: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem1: %.758 = impl_witness_access constants.%Negate.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %bound_method.loc11_10: <bound method> = bound_method %int_1.loc11, %impl.elem1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op.bound]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.call: init Core.IntLiteral = call %bound_method.loc11_10(%int_1.loc11) [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %impl.elem0.loc11: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc11_12.1: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %impl.elem0.loc11 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.65e]
// CHECK:STDOUT:   %specific_fn.loc11: <specific function> = specific_function %impl.elem0.loc11, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc11_12.2: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %specific_fn.loc11 [concrete = constants.%bound_method.a65]
// CHECK:STDOUT:   %.loc11_10.1: Core.IntLiteral = value_of_initializer %Core.IntLiteral.as.Negate.impl.Op.call [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %.loc11_10.2: Core.IntLiteral = converted %Core.IntLiteral.as.Negate.impl.Op.call, %.loc11_10.1 [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc11: init %i32 = call %bound_method.loc11_12.2(%.loc11_10.2) [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   %.loc11_12: init %i32 = converted %Core.IntLiteral.as.Negate.impl.Op.call, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc11 [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   return %.loc11_12
// CHECK:STDOUT: }
// CHECK:STDOUT:
