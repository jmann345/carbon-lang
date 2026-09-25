// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/tuple_pattern.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/tuple_pattern.carbon

// Tuple case patterns over tuple scrutinees (W-008 W8a): elements are
// constant-integer expressions, bindings, and nested tuples of those. The
// test pass compares refutable elements against the scrutinee's own tuple
// type and folds the conditions into one bool; bindings initialize in the
// bind pass, in the arm's body block.

// --- literal_scrutinee.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn F() -> i32 {
  match ((1, 2)) {
    case (1, 2) => { return 1; }
    default => { return 0; }
  }
  return -1;
}
//@dump-sem-ir-end

// --- all_expr.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn F(p: (i32, i32)) -> i32 {
  match (p) {
    case (1, 2) => { return 1; }
    default => { return 0; }
  }
  return -1;
}
//@dump-sem-ir-end

// --- all_binding.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn F(p: (i32, i32)) -> i32 {
  match (p) {
    case (a: i32, b: i32) => { return a + b; }
    default => { return 0; }
  }
  return -1;
}
//@dump-sem-ir-end

// --- mixed.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn F(p: (i32, i32)) -> i32 {
  match (p) {
    case (1, b: i32) => { return b; }
    default => { return 0; }
  }
  return -1;
}
//@dump-sem-ir-end

// --- expr_element_conversion.carbon
library "[[@TEST_NAME]]";

// An initializing expression element (`2 + 3` returns through a return
// slot): the expression region value-converts the result at region close
// (`EndExprRegionForPattern`, W8a fix round 3), so splices stay values.
//@dump-sem-ir-begin
fn F(p: (i32, i32)) -> i32 {
  match (p) {
    case (2 + 3, b: i32) => { return b; }
    default => { return 0; }
  }
  return -1;
}
//@dump-sem-ir-end

// --- nested_tuple.carbon
library "[[@TEST_NAME]]";

// The design's flagship mixed shape (docs/design/pattern_matching.md,
// `case (42, (x: f32, y: f32))`), on integer tuples.
//@dump-sem-ir-begin
fn F(p: (i32, (i32, i32))) -> i32 {
  match (p) {
    case (42, (x: i32, y: i32)) => { return x + y; }
    case (n: i32, (1, 2)) => { return n; }
    default => { return 0; }
  }
  return -1;
}
//@dump-sem-ir-end

// --- var_scrutinee.carbon
library "[[@TEST_NAME]]";

// A NON-literal tuple scrutinee (a `var` local): both passes must walk the
// scrutinee's own tuple type — converting to the pattern's tuple type would
// reject this design-valid shape (W-008 plan §2.1(d)).
//@dump-sem-ir-begin
fn F() -> i32 {
  var t: (i32, i32) = (1, 2);
  match (t) {
    case (1, b: i32) => { return b; }
    default => { return 0; }
  }
  return -1;
}
//@dump-sem-ir-end

// --- fail_arity_literal_scrutinee.carbon
library "[[@TEST_NAME]]";

// The scrutinee is converted to a value at `MatchCondition`, so even a
// tuple-literal scrutinee reaches the engine as a tuple value and arity
// mismatches diagnose against the scrutinee's tuple type.
fn F() -> i32 {
  match ((1, 2)) {
    // CHECK:STDERR: fail_arity_literal_scrutinee.carbon:[[@LINE+4]]:10: error: tuple pattern expects 3 elements, but match scrutinee has 2 [MatchCaseTuplePatternWrongArity]
    // CHECK:STDERR:     case (1, 2, 3) => { return 1; }
    // CHECK:STDERR:          ^~~~~~~~~
    // CHECK:STDERR:
    case (1, 2, 3) => { return 1; }
    default => { return 0; }
  }
  return -1;
}

// --- fail_arity_var_scrutinee.carbon
library "[[@TEST_NAME]]";

fn F() -> i32 {
  var t: (i32, i32) = (1, 2);
  match (t) {
    // CHECK:STDERR: fail_arity_var_scrutinee.carbon:[[@LINE+4]]:10: error: tuple pattern expects 1 element, but match scrutinee has 2 [MatchCaseTuplePatternWrongArity]
    // CHECK:STDERR:     case (1,) => { return 1; }
    // CHECK:STDERR:          ^~~~
    // CHECK:STDERR:
    case (1,) => { return 1; }
    default => { return 0; }
  }
  return -1;
}

// --- fail_error_element_recovery.carbon
library "[[@TEST_NAME]]";

// An error-typed expression ELEMENT is below the arm's root, so it recovers
// (W-008 W8a review fix F1): the NameNotFound poisons the arm's condition,
// checking continues past the `match`, and the constant-integer TODO — the
// legacy abort path, which stays pinned for ROOT case expressions by
// operators/fail_question.carbon — must not fire.
fn F(p: (i32, i32)) -> i32 {
  match (p) {
    // CHECK:STDERR: fail_error_element_recovery.carbon:[[@LINE+4]]:11: error: name `undeclared` not found [NameNotFound]
    // CHECK:STDERR:     case (undeclared, 1) => { return 1; }
    // CHECK:STDERR:           ^~~~~~~~~~
    // CHECK:STDERR:
    case (undeclared, 1) => { return 1; }
    default => { return 0; }
  }
  return -1;
}

// --- fail_todo_non_tuple_scrutinee.carbon
library "[[@TEST_NAME]]";

// A tuple pattern against a non-tuple scrutinee stays behind the W4
// slice-gate fallback in `MatchCase` — the shape that still reaches it
// after W8a's classification.
fn F(x: i32) -> i32 {
  match (x) {
    // CHECK:STDERR: fail_todo_non_tuple_scrutinee.carbon:[[@LINE+4]]:5: error: semantics TODO: `match `case` pattern other than an integer literal, or a case guard` [SemanticsTodo]
    // CHECK:STDERR:     case (1, 2) => { return 1; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR:
    case (1, 2) => { return 1; }
    default => { return 0; }
  }
  return -1;
}

// --- fail_todo_nested_non_tuple.carbon
library "[[@TEST_NAME]]";

// A nested tuple pattern against a non-tuple element hits the same gate,
// from inside the engine's scrutinee-typed walk.
fn F(p: (i32, i32)) -> i32 {
  match (p) {
    // CHECK:STDERR: fail_todo_nested_non_tuple.carbon:[[@LINE+4]]:5: error: semantics TODO: `match `case` pattern other than an integer literal, or a case guard` [SemanticsTodo]
    // CHECK:STDERR:     case (1, (2, 3)) => { return 1; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR:
    case (1, (2, 3)) => { return 1; }
    default => { return 0; }
  }
  return -1;
}

// --- fail_pruned_subtree_shape_error.carbon
library "[[@TEST_NAME]]";

// A wholly-irrefutable nested tuple against a non-tuple element: the TEST
// pass prunes the subtree (it contributes no condition and never
// shape-checks it), so the BIND pass — which would otherwise silently bind
// nothing — emits the shape gate's diagnostic (W-008 W8a review fix round
// 2). The bind-pass diagnostic is located at the offending subpattern: the
// arm's case context is popped before the bind pass runs.
fn F(p: (i32, i32)) -> i32 {
  match (p) {
    // CHECK:STDERR: fail_pruned_subtree_shape_error.carbon:[[@LINE+8]]:14: error: semantics TODO: `match `case` pattern other than an integer literal, or a case guard` [SemanticsTodo]
    // CHECK:STDERR:     case (1, (b: i32,)) => { return 1; }
    // CHECK:STDERR:              ^~~~~~~~~
    // CHECK:STDERR:
    // CHECK:STDERR: fail_pruned_subtree_shape_error.carbon:[[@LINE+4]]:15: warning: binding `b` unused [UnusedBinding]
    // CHECK:STDERR:     case (1, (b: i32,)) => { return 1; }
    // CHECK:STDERR:               ^~~~~~
    // CHECK:STDERR:
    case (1, (b: i32,)) => { return 1; }
    default => { return 0; }
  }
  return -1;
}

// CHECK:STDOUT: --- literal_scrutinee.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %pattern_type.dc0: type = pattern_type Core.IntLiteral [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %tuple.type: type = tuple_type (Core.IntLiteral, Core.IntLiteral) [concrete]
// CHECK:STDOUT:   %tuple: %tuple.type = tuple_value (%int_1.5b8, %int_2) [concrete]
// CHECK:STDOUT:   %pattern_type.82e: type = pattern_type %tuple.type [concrete]
// CHECK:STDOUT:   %.0e9: %pattern_type.82e = tuple_pattern (@F.%expr_patt.loc6_11, @F.%expr_patt.loc6_14) [concrete]
// CHECK:STDOUT:   %EqWith.type.aee: type = facet_type <@EqWith, @EqWith(Core.IntLiteral)> [concrete]
// CHECK:STDOUT:   %EqWith.impl_witness: <witness> = impl_witness imports.%EqWith.impl_witness_table [concrete]
// CHECK:STDOUT:   %EqWith.facet: %EqWith.type.aee = facet_value Core.IntLiteral, (%EqWith.impl_witness) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.4b8: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(Core.IntLiteral, %EqWith.facet) [concrete]
// CHECK:STDOUT:   %.afe: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.4b8, %EqWith.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.EqWith.impl.Equal.type: type = fn_type @Core.IntLiteral.as.EqWith.impl.Equal [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.EqWith.impl.Equal: %Core.IntLiteral.as.EqWith.impl.Equal.type = struct_value () [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.EqWith.impl.Equal.bound.75f: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.EqWith.impl.Equal [concrete]
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.EqWith.impl.Equal.bound.313: <bound method> = bound_method %int_2, %Core.IntLiteral.as.EqWith.impl.Equal [concrete]
// CHECK:STDOUT:   %false: bool = bool_literal false [concrete]
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
// CHECK:STDOUT:   %Core.import_ref.a87: %Core.IntLiteral.as.EqWith.impl.Equal.type = import_ref Core//prelude/operators/comparison, loc{{\d+_\d+}}, loaded [concrete = constants.%Core.IntLiteral.as.EqWith.impl.Equal]
// CHECK:STDOUT:   %Core.import_ref.e3a = import_ref Core//prelude/operators/comparison, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table = impl_witness_table (%Core.import_ref.a87, %Core.import_ref.e3a), @Core.IntLiteral.as.EqWith.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %F.decl: %F.type = fn_decl @F [concrete = constants.%F] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc4: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param0
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @F() -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %int_1.loc5: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %int_2.loc5: Core.IntLiteral = int_value 2 [concrete = constants.%int_2]
// CHECK:STDOUT:   %.loc5_15.1: %tuple.type = tuple_literal (%int_1.loc5, %int_2.loc5) [concrete = constants.%tuple]
// CHECK:STDOUT:   %tuple: %tuple.type = tuple_value (%int_1.loc5, %int_2.loc5) [concrete = constants.%tuple]
// CHECK:STDOUT:   %.loc5_15.2: %tuple.type = converted %.loc5_15.1, %tuple [concrete = constants.%tuple]
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt.loc6_11: %pattern_type.dc0 = expr_pattern %int_1.loc6_11 in [concrete] {
// CHECK:STDOUT:       %int_1.loc6_11: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %expr_patt.loc6_14: %pattern_type.dc0 = expr_pattern %int_2.loc6 in [concrete] {
// CHECK:STDOUT:       %int_2.loc6: Core.IntLiteral = int_value 2 [concrete = constants.%int_2]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %.loc6_15: %pattern_type.82e = tuple_pattern (%expr_patt.loc6_11, %expr_patt.loc6_14) [concrete = constants.%.0e9]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %tuple.elem0: Core.IntLiteral = tuple_access %.loc5_15.2, element0 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %tuple.elem1: Core.IntLiteral = tuple_access %.loc5_15.2, element1 [concrete = constants.%int_2]
// CHECK:STDOUT:   %int_1.loc6_11: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc6_17.1: %.afe = impl_witness_access constants.%EqWith.impl_witness, element0 [concrete = constants.%Core.IntLiteral.as.EqWith.impl.Equal]
// CHECK:STDOUT:   %bound_method.loc6_17.1: <bound method> = bound_method %int_1.loc6_11, %impl.elem0.loc6_17.1 [concrete = constants.%Core.IntLiteral.as.EqWith.impl.Equal.bound.75f]
// CHECK:STDOUT:   %Core.IntLiteral.as.EqWith.impl.Equal.call.loc6_17.1: init bool = call %bound_method.loc6_17.1(%int_1.loc6_11, %tuple.elem0) [concrete = constants.%true]
// CHECK:STDOUT:   %.loc6_17.1: bool = value_of_initializer %Core.IntLiteral.as.EqWith.impl.Equal.call.loc6_17.1 [concrete = constants.%true]
// CHECK:STDOUT:   %.loc6_17.2: bool = converted %Core.IntLiteral.as.EqWith.impl.Equal.call.loc6_17.1, %.loc6_17.1 [concrete = constants.%true]
// CHECK:STDOUT:   %int_2.loc6: Core.IntLiteral = int_value 2 [concrete = constants.%int_2]
// CHECK:STDOUT:   %impl.elem0.loc6_17.2: %.afe = impl_witness_access constants.%EqWith.impl_witness, element0 [concrete = constants.%Core.IntLiteral.as.EqWith.impl.Equal]
// CHECK:STDOUT:   %bound_method.loc6_17.2: <bound method> = bound_method %int_2.loc6, %impl.elem0.loc6_17.2 [concrete = constants.%Core.IntLiteral.as.EqWith.impl.Equal.bound.313]
// CHECK:STDOUT:   %Core.IntLiteral.as.EqWith.impl.Equal.call.loc6_17.2: init bool = call %bound_method.loc6_17.2(%int_2.loc6, %tuple.elem1) [concrete = constants.%true]
// CHECK:STDOUT:   %.loc6_17.3: bool = value_of_initializer %Core.IntLiteral.as.EqWith.impl.Equal.call.loc6_17.2 [concrete = constants.%true]
// CHECK:STDOUT:   %.loc6_17.4: bool = converted %Core.IntLiteral.as.EqWith.impl.Equal.call.loc6_17.2, %.loc6_17.3 [concrete = constants.%true]
// CHECK:STDOUT:   %false: bool = bool_literal false [concrete = constants.%false]
// CHECK:STDOUT:   if %.loc6_17.2 br !match.case.then.loc6_17.1 else br !match.<unexpected BranchWithArg>(%false)
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc6_17.1:
// CHECK:STDOUT:   br !match.<unexpected BranchWithArg>(%.loc6_17.4)
// CHECK:STDOUT:
// CHECK:STDOUT: !match.<unexpected BranchWithArg>:
// CHECK:STDOUT:   %.loc6_17.5: bool = block_arg !match.<unexpected BranchWithArg> [concrete = constants.%true]
// CHECK:STDOUT:   if %.loc6_17.5 br !match.case.then.loc6_17.2 else br !match.case.else
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc6_17.2:
// CHECK:STDOUT:   %int_1.loc6_29: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc6_30: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc6_30.1: <bound method> = bound_method %int_1.loc6_29, %impl.elem0.loc6_30 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc6: <specific function> = specific_function %impl.elem0.loc6_30, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc6_30.2: <bound method> = bound_method %int_1.loc6_29, %specific_fn.loc6 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc6: init %i32 = call %bound_method.loc6_30.2(%int_1.loc6_29) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc6_30: init %i32 = converted %int_1.loc6_29, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc6 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   return %.loc6_30
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else:
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc7: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc7_26.1: <bound method> = bound_method %int_0, %impl.elem0.loc7 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc7: <specific function> = specific_function %impl.elem0.loc7, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc7_26.2: <bound method> = bound_method %int_0, %specific_fn.loc7 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc7: init %i32 = call %bound_method.loc7_26.2(%int_0) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc7: init %i32 = converted %int_0, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc7 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   return %.loc7
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- all_expr.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %Int.67af24.1: type = class_type @Int, @Int(%N) [symbolic]
// CHECK:STDOUT:   %pattern_type.dc0: type = pattern_type Core.IntLiteral [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %tuple.type.24b: type = tuple_type (type, type) [concrete]
// CHECK:STDOUT:   %tuple: %tuple.type.24b = tuple_value (%i32, %i32) [concrete]
// CHECK:STDOUT:   %tuple.type.e55: type = tuple_type (%i32, %i32) [concrete]
// CHECK:STDOUT:   %pattern_type.394: type = pattern_type %tuple.type.e55 [concrete]
// CHECK:STDOUT:   %p.param_patt: %pattern_type.394 = value_param_pattern [concrete]
// CHECK:STDOUT:   %p.patt: %pattern_type.394 = wrapper_binding_pattern p, %p.param_patt [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %int_2.ecc: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %tuple.type.f94: type = tuple_type (Core.IntLiteral, Core.IntLiteral) [concrete]
// CHECK:STDOUT:   %pattern_type.82e: type = pattern_type %tuple.type.f94 [concrete]
// CHECK:STDOUT:   %.0e9: %pattern_type.82e = tuple_pattern (@F.%expr_patt.loc6_11, @F.%expr_patt.loc6_14) [concrete]
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
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound.29e975.1: <bound method> = bound_method %int_1.5b8, %T.as_type.as.EqWith.impl.Equal.57b831.2 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.1: <specific function> = specific_function %T.as_type.as.EqWith.impl.Equal.57b831.2, @T.as_type.as.EqWith.impl.Equal.1(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %bound_method.42af37.1: <bound method> = bound_method %int_1.5b8, %T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.1 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound.29e975.2: <bound method> = bound_method %int_1.5b8, %T.as_type.as.EqWith.impl.Equal.57b831.1 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.2: <specific function> = specific_function %T.as_type.as.EqWith.impl.Equal.57b831.1, @T.as_type.as.EqWith.impl.Equal.2(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %bound_method.42af37.2: <bound method> = bound_method %int_1.5b8, %T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.2 [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.953: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound.811140.1: <bound method> = bound_method %int_2.ecc, %T.as_type.as.EqWith.impl.Equal.57b831.2 [concrete]
// CHECK:STDOUT:   %bound_method.ee93db.1: <bound method> = bound_method %int_2.ecc, %T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.1 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound.811140.2: <bound method> = bound_method %int_2.ecc, %T.as_type.as.EqWith.impl.Equal.57b831.1 [concrete]
// CHECK:STDOUT:   %bound_method.ee93db.2: <bound method> = bound_method %int_2.ecc, %T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.2 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.9f3: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.3cb: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_2.295: %i32 = int_value 2 [concrete]
// CHECK:STDOUT:   %false: bool = bool_literal false [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.6e0: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_0.3c0: %i32 = int_value 0 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.a9a: @T.as_type.as.EqWith.impl.%T.as_type.as.EqWith.impl.Equal.type.2 (%T.as_type.as.EqWith.impl.Equal.type.8af025.1) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @T.as_type.as.EqWith.impl.%T.as_type.as.EqWith.impl.Equal.2 (constants.%T.as_type.as.EqWith.impl.Equal.c477d6.1)]
// CHECK:STDOUT:   %Core.import_ref.712 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.532 = impl_witness_table (%Core.import_ref.a9a, %Core.import_ref.712), @T.as_type.as.EqWith.impl [concrete]
// CHECK:STDOUT:   %Core.Equal.970: @T.as_type.as.EqWith.impl.%T.as_type.as.EqWith.impl.Equal.type.1 (%T.as_type.as.EqWith.impl.Equal.type.8af025.2) = import_ref Core//prelude/types/int, Equal, loaded [symbolic = @T.as_type.as.EqWith.impl.%T.as_type.as.EqWith.impl.Equal.1 (constants.%T.as_type.as.EqWith.impl.Equal.c477d6.2)]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %F.decl: %F.type = fn_decl @F [concrete = constants.%F] {
// CHECK:STDOUT:     %p.param_patt: %pattern_type.394 = value_param_pattern [concrete = constants.%p.param_patt]
// CHECK:STDOUT:     %p.patt: %pattern_type.394 = wrapper_binding_pattern p, %p.param_patt [concrete = constants.%p.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc4_24 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc4_24: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc4_24: Core.Form = init_form %i32.loc4_24 [concrete = constants.%.795f]
// CHECK:STDOUT:     %p.param: %tuple.type.e55 = value_param call_param0
// CHECK:STDOUT:     %.loc4_18.1: type = splice_block %.loc4_18.3 [concrete = constants.%tuple.type.e55] {
// CHECK:STDOUT:       %i32.loc4_10: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %i32.loc4_15: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %.loc4_18.2: %tuple.type.24b = tuple_literal (%i32.loc4_10, %i32.loc4_15) [concrete = constants.%tuple]
// CHECK:STDOUT:       %.loc4_18.3: type = converted %.loc4_18.2, constants.%tuple.type.e55 [concrete = constants.%tuple.type.e55]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %p: %tuple.type.e55 = wrapper_binding p, %p.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @F(%p.param: %tuple.type.e55) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %p.ref: %tuple.type.e55 = name_ref p, %p
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt.loc6_11: %pattern_type.dc0 = expr_pattern %int_1.loc6_11 in [concrete] {
// CHECK:STDOUT:       %int_1.loc6_11: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %expr_patt.loc6_14: %pattern_type.dc0 = expr_pattern %int_2 in [concrete] {
// CHECK:STDOUT:       %int_2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %.loc6_15: %pattern_type.82e = tuple_pattern (%expr_patt.loc6_11, %expr_patt.loc6_14) [concrete = constants.%.0e9]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %tuple.elem0: %i32 = tuple_access %p.ref, element0
// CHECK:STDOUT:   %tuple.elem1: %i32 = tuple_access %p.ref, element1
// CHECK:STDOUT:   %int_1.loc6_11: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc6_17.1: %.025 = impl_witness_access constants.%EqWith.impl_witness.bde, element0 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.57b831.2]
// CHECK:STDOUT:   %bound_method.loc6_17.1: <bound method> = bound_method %int_1.loc6_11, %impl.elem0.loc6_17.1 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.bound.29e975.1]
// CHECK:STDOUT:   %specific_fn.loc6_17.1: <specific function> = specific_function %impl.elem0.loc6_17.1, @T.as_type.as.EqWith.impl.Equal.1(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.1]
// CHECK:STDOUT:   %bound_method.loc6_17.2: <bound method> = bound_method %int_1.loc6_11, %specific_fn.loc6_17.1 [concrete = constants.%bound_method.42af37.1]
// CHECK:STDOUT:   %.loc6_17.1: %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.1 = specific_constant imports.%Core.Equal.970, @T.as_type.as.EqWith.impl(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.57b831.1]
// CHECK:STDOUT:   %Equal.ref.loc6_17.1: %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.1 = name_ref Equal, %.loc6_17.1 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.57b831.1]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound.loc6_17.1: <bound method> = bound_method %int_1.loc6_11, %Equal.ref.loc6_17.1 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.bound.29e975.2]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.specific_fn.loc6_17.1: <specific function> = specific_function %Equal.ref.loc6_17.1, @T.as_type.as.EqWith.impl.Equal.2(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.2]
// CHECK:STDOUT:   %bound_method.loc6_17.3: <bound method> = bound_method %int_1.loc6_11, %T.as_type.as.EqWith.impl.Equal.specific_fn.loc6_17.1 [concrete = constants.%bound_method.42af37.2]
// CHECK:STDOUT:   %impl.elem0.loc6_11: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc6_11.1: <bound method> = bound_method %int_1.loc6_11, %impl.elem0.loc6_11 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc6_11: <specific function> = specific_function %impl.elem0.loc6_11, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc6_11.2: <bound method> = bound_method %int_1.loc6_11, %specific_fn.loc6_11 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc6_11: init %i32 = call %bound_method.loc6_11.2(%int_1.loc6_11) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc6_11.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc6_11 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc6_11.2: %i32 = converted %int_1.loc6_11, %.loc6_11.1 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.call.loc6_17.1: init bool = call %bound_method.loc6_17.3(%.loc6_11.2, %tuple.elem0)
// CHECK:STDOUT:   %.loc6_17.2: bool = value_of_initializer %T.as_type.as.EqWith.impl.Equal.call.loc6_17.1
// CHECK:STDOUT:   %.loc6_17.3: bool = converted %T.as_type.as.EqWith.impl.Equal.call.loc6_17.1, %.loc6_17.2
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:   %impl.elem0.loc6_17.2: %.025 = impl_witness_access constants.%EqWith.impl_witness.bde, element0 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.57b831.2]
// CHECK:STDOUT:   %bound_method.loc6_17.4: <bound method> = bound_method %int_2, %impl.elem0.loc6_17.2 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.bound.811140.1]
// CHECK:STDOUT:   %specific_fn.loc6_17.2: <specific function> = specific_function %impl.elem0.loc6_17.2, @T.as_type.as.EqWith.impl.Equal.1(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.1]
// CHECK:STDOUT:   %bound_method.loc6_17.5: <bound method> = bound_method %int_2, %specific_fn.loc6_17.2 [concrete = constants.%bound_method.ee93db.1]
// CHECK:STDOUT:   %.loc6_17.4: %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.1 = specific_constant imports.%Core.Equal.970, @T.as_type.as.EqWith.impl(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.57b831.1]
// CHECK:STDOUT:   %Equal.ref.loc6_17.2: %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.1 = name_ref Equal, %.loc6_17.4 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.57b831.1]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound.loc6_17.2: <bound method> = bound_method %int_2, %Equal.ref.loc6_17.2 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.bound.811140.2]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.specific_fn.loc6_17.2: <specific function> = specific_function %Equal.ref.loc6_17.2, @T.as_type.as.EqWith.impl.Equal.2(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.2]
// CHECK:STDOUT:   %bound_method.loc6_17.6: <bound method> = bound_method %int_2, %T.as_type.as.EqWith.impl.Equal.specific_fn.loc6_17.2 [concrete = constants.%bound_method.ee93db.2]
// CHECK:STDOUT:   %impl.elem0.loc6_14: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc6_14.1: <bound method> = bound_method %int_2, %impl.elem0.loc6_14 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.9f3]
// CHECK:STDOUT:   %specific_fn.loc6_14: <specific function> = specific_function %impl.elem0.loc6_14, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc6_14.2: <bound method> = bound_method %int_2, %specific_fn.loc6_14 [concrete = constants.%bound_method.3cb]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc6_14: init %i32 = call %bound_method.loc6_14.2(%int_2) [concrete = constants.%int_2.295]
// CHECK:STDOUT:   %.loc6_14.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc6_14 [concrete = constants.%int_2.295]
// CHECK:STDOUT:   %.loc6_14.2: %i32 = converted %int_2, %.loc6_14.1 [concrete = constants.%int_2.295]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.call.loc6_17.2: init bool = call %bound_method.loc6_17.6(%.loc6_14.2, %tuple.elem1)
// CHECK:STDOUT:   %.loc6_17.5: bool = value_of_initializer %T.as_type.as.EqWith.impl.Equal.call.loc6_17.2
// CHECK:STDOUT:   %.loc6_17.6: bool = converted %T.as_type.as.EqWith.impl.Equal.call.loc6_17.2, %.loc6_17.5
// CHECK:STDOUT:   %false: bool = bool_literal false [concrete = constants.%false]
// CHECK:STDOUT:   if %.loc6_17.3 br !match.case.then.loc6_17.1 else br !match.<unexpected BranchWithArg>(%false)
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc6_17.1:
// CHECK:STDOUT:   br !match.<unexpected BranchWithArg>(%.loc6_17.6)
// CHECK:STDOUT:
// CHECK:STDOUT: !match.<unexpected BranchWithArg>:
// CHECK:STDOUT:   %.loc6_17.7: bool = block_arg !match.<unexpected BranchWithArg>
// CHECK:STDOUT:   if %.loc6_17.7 br !match.case.then.loc6_17.2 else br !match.case.else
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc6_17.2:
// CHECK:STDOUT:   %int_1.loc6_29: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc6_30: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc6_30.1: <bound method> = bound_method %int_1.loc6_29, %impl.elem0.loc6_30 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc6_30: <specific function> = specific_function %impl.elem0.loc6_30, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc6_30.2: <bound method> = bound_method %int_1.loc6_29, %specific_fn.loc6_30 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc6_30: init %i32 = call %bound_method.loc6_30.2(%int_1.loc6_29) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc6_30: init %i32 = converted %int_1.loc6_29, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc6_30 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   return %.loc6_30
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else:
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc7: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc7_26.1: <bound method> = bound_method %int_0, %impl.elem0.loc7 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc7: <specific function> = specific_function %impl.elem0.loc7, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc7_26.2: <bound method> = bound_method %int_0, %specific_fn.loc7 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc7: init %i32 = call %bound_method.loc7_26.2(%int_0) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc7: init %i32 = converted %int_0, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc7 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   return %.loc7
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- all_binding.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %tuple.type.24b: type = tuple_type (type, type) [concrete]
// CHECK:STDOUT:   %tuple: %tuple.type.24b = tuple_value (%i32, %i32) [concrete]
// CHECK:STDOUT:   %tuple.type.e55: type = tuple_type (%i32, %i32) [concrete]
// CHECK:STDOUT:   %pattern_type.394: type = pattern_type %tuple.type.e55 [concrete]
// CHECK:STDOUT:   %p.param_patt: %pattern_type.394 = value_param_pattern [concrete]
// CHECK:STDOUT:   %p.patt: %pattern_type.394 = wrapper_binding_pattern p, %p.param_patt [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT:   %a.patt: %pattern_type.6b6 = value_binding_pattern a [concrete]
// CHECK:STDOUT:   %b.patt: %pattern_type.6b6 = value_binding_pattern b [concrete]
// CHECK:STDOUT:   %.d82: %pattern_type.394 = tuple_pattern (%a.patt, %b.patt) [concrete]
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete]
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
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.b4fd3a.1 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.684: @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op.type (%Int.as.AddWith.impl.Op.type.610) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op (constants.%Int.as.AddWith.impl.Op.732)]
// CHECK:STDOUT:   %AddWith.impl_witness_table.6b4 = impl_witness_table (%Core.import_ref.b4fd3a.1, %Core.import_ref.684), @Int.as.AddWith.impl.3af [concrete]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %F.decl: %F.type = fn_decl @F [concrete = constants.%F] {
// CHECK:STDOUT:     %p.param_patt: %pattern_type.394 = value_param_pattern [concrete = constants.%p.param_patt]
// CHECK:STDOUT:     %p.patt: %pattern_type.394 = wrapper_binding_pattern p, %p.param_patt [concrete = constants.%p.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc4_24 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc4_24: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc4_24: Core.Form = init_form %i32.loc4_24 [concrete = constants.%.795f]
// CHECK:STDOUT:     %p.param: %tuple.type.e55 = value_param call_param0
// CHECK:STDOUT:     %.loc4_18.1: type = splice_block %.loc4_18.3 [concrete = constants.%tuple.type.e55] {
// CHECK:STDOUT:       %i32.loc4_10: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %i32.loc4_15: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %.loc4_18.2: %tuple.type.24b = tuple_literal (%i32.loc4_10, %i32.loc4_15) [concrete = constants.%tuple]
// CHECK:STDOUT:       %.loc4_18.3: type = converted %.loc4_18.2, constants.%tuple.type.e55 [concrete = constants.%tuple.type.e55]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %p: %tuple.type.e55 = wrapper_binding p, %p.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @F(%p.param: %tuple.type.e55) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %p.ref: %tuple.type.e55 = name_ref p, %p
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %a.patt: %pattern_type.6b6 = value_binding_pattern a [concrete = constants.%a.patt]
// CHECK:STDOUT:     %b.patt: %pattern_type.6b6 = value_binding_pattern b [concrete = constants.%b.patt]
// CHECK:STDOUT:     %.loc6: %pattern_type.394 = tuple_pattern (%a.patt, %b.patt) [concrete = constants.%.d82]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:   if %true br !match.case.then else br !match.case.else
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then:
// CHECK:STDOUT:   %tuple.elem0: %i32 = tuple_access %p.ref, element0
// CHECK:STDOUT:   %tuple.elem1: %i32 = tuple_access %p.ref, element1
// CHECK:STDOUT:   %i32.loc6_14: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %a: %i32 = wrapper_binding a, %tuple.elem0
// CHECK:STDOUT:   %i32.loc6_22: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %b: %i32 = wrapper_binding b, %tuple.elem1
// CHECK:STDOUT:   %a.ref: %i32 = name_ref a, %a
// CHECK:STDOUT:   %b.ref: %i32 = name_ref b, %b
// CHECK:STDOUT:   %impl.elem1: %.d47 = impl_witness_access constants.%AddWith.impl_witness.833, element1 [concrete = constants.%Int.as.AddWith.impl.Op.365]
// CHECK:STDOUT:   %bound_method.loc6_41.1: <bound method> = bound_method %a.ref, %impl.elem1
// CHECK:STDOUT:   %specific_fn.loc6: <specific function> = specific_function %impl.elem1, @Int.as.AddWith.impl.Op.1(constants.%int_32) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.f25]
// CHECK:STDOUT:   %bound_method.loc6_41.2: <bound method> = bound_method %a.ref, %specific_fn.loc6
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call: init %i32 = call %bound_method.loc6_41.2(%a.ref, %b.ref)
// CHECK:STDOUT:   return %Int.as.AddWith.impl.Op.call
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else:
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc7_26.1: <bound method> = bound_method %int_0, %impl.elem0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc7: <specific function> = specific_function %impl.elem0, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc7_26.2: <bound method> = bound_method %int_0, %specific_fn.loc7 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %i32 = call %bound_method.loc7_26.2(%int_0) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc7: init %i32 = converted %int_0, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   return %.loc7
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- mixed.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %Int.67af24.1: type = class_type @Int, @Int(%N) [symbolic]
// CHECK:STDOUT:   %pattern_type.dc0: type = pattern_type Core.IntLiteral [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %tuple.type.24b: type = tuple_type (type, type) [concrete]
// CHECK:STDOUT:   %tuple.b59: %tuple.type.24b = tuple_value (%i32, %i32) [concrete]
// CHECK:STDOUT:   %tuple.type.e55: type = tuple_type (%i32, %i32) [concrete]
// CHECK:STDOUT:   %pattern_type.394: type = pattern_type %tuple.type.e55 [concrete]
// CHECK:STDOUT:   %p.param_patt: %pattern_type.394 = value_param_pattern [concrete]
// CHECK:STDOUT:   %p.patt: %pattern_type.394 = wrapper_binding_pattern p, %p.param_patt [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %b.patt: %pattern_type.6b6 = value_binding_pattern b [concrete]
// CHECK:STDOUT:   %tuple.type.94b: type = tuple_type (Core.IntLiteral, %i32) [concrete]
// CHECK:STDOUT:   %pattern_type.106: type = pattern_type %tuple.type.94b [concrete]
// CHECK:STDOUT:   %.e63: %pattern_type.106 = tuple_pattern (@F.%expr_patt, %b.patt) [concrete]
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
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
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
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound.29e975.1: <bound method> = bound_method %int_1.5b8, %T.as_type.as.EqWith.impl.Equal.57b831.2 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.1: <specific function> = specific_function %T.as_type.as.EqWith.impl.Equal.57b831.2, @T.as_type.as.EqWith.impl.Equal.1(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %bound_method.42af37.1: <bound method> = bound_method %int_1.5b8, %T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.1 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound.29e975.2: <bound method> = bound_method %int_1.5b8, %T.as_type.as.EqWith.impl.Equal.57b831.1 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.2: <specific function> = specific_function %T.as_type.as.EqWith.impl.Equal.57b831.1, @T.as_type.as.EqWith.impl.Equal.2(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %bound_method.42af37.2: <bound method> = bound_method %int_1.5b8, %T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.2 [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.953: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet: %Copy.type = facet_value %i32, (%Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.381: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet) [concrete]
// CHECK:STDOUT:   %.737: type = fn_type_with_self_type %Copy.WithSelf.Op.type.381, %Copy.facet [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.6e0: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_0.3c0: %i32 = int_value 0 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.a9a: @T.as_type.as.EqWith.impl.%T.as_type.as.EqWith.impl.Equal.type.2 (%T.as_type.as.EqWith.impl.Equal.type.8af025.1) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @T.as_type.as.EqWith.impl.%T.as_type.as.EqWith.impl.Equal.2 (constants.%T.as_type.as.EqWith.impl.Equal.c477d6.1)]
// CHECK:STDOUT:   %Core.import_ref.712 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.532 = impl_witness_table (%Core.import_ref.a9a, %Core.import_ref.712), @T.as_type.as.EqWith.impl [concrete]
// CHECK:STDOUT:   %Core.Equal.970: @T.as_type.as.EqWith.impl.%T.as_type.as.EqWith.impl.Equal.type.1 (%T.as_type.as.EqWith.impl.Equal.type.8af025.2) = import_ref Core//prelude/types/int, Equal, loaded [symbolic = @T.as_type.as.EqWith.impl.%T.as_type.as.EqWith.impl.Equal.1 (constants.%T.as_type.as.EqWith.impl.Equal.c477d6.2)]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %F.decl: %F.type = fn_decl @F [concrete = constants.%F] {
// CHECK:STDOUT:     %p.param_patt: %pattern_type.394 = value_param_pattern [concrete = constants.%p.param_patt]
// CHECK:STDOUT:     %p.patt: %pattern_type.394 = wrapper_binding_pattern p, %p.param_patt [concrete = constants.%p.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc4_24 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc4_24: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc4_24: Core.Form = init_form %i32.loc4_24 [concrete = constants.%.795f]
// CHECK:STDOUT:     %p.param: %tuple.type.e55 = value_param call_param0
// CHECK:STDOUT:     %.loc4_18.1: type = splice_block %.loc4_18.3 [concrete = constants.%tuple.type.e55] {
// CHECK:STDOUT:       %i32.loc4_10: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %i32.loc4_15: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %.loc4_18.2: %tuple.type.24b = tuple_literal (%i32.loc4_10, %i32.loc4_15) [concrete = constants.%tuple.b59]
// CHECK:STDOUT:       %.loc4_18.3: type = converted %.loc4_18.2, constants.%tuple.type.e55 [concrete = constants.%tuple.type.e55]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %p: %tuple.type.e55 = wrapper_binding p, %p.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @F(%p.param: %tuple.type.e55) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %p.ref: %tuple.type.e55 = name_ref p, %p
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt: %pattern_type.dc0 = expr_pattern %int_1 in [concrete] {
// CHECK:STDOUT:       %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %b.patt: %pattern_type.6b6 = value_binding_pattern b [concrete = constants.%b.patt]
// CHECK:STDOUT:     %.loc6_20: %pattern_type.106 = tuple_pattern (%expr_patt, %b.patt) [concrete = constants.%.e63]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %tuple.elem0: %i32 = tuple_access %p.ref, element0
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc6_22: %.025 = impl_witness_access constants.%EqWith.impl_witness.bde, element0 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.57b831.2]
// CHECK:STDOUT:   %bound_method.loc6_22.1: <bound method> = bound_method %int_1, %impl.elem0.loc6_22 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.bound.29e975.1]
// CHECK:STDOUT:   %specific_fn.loc6_22: <specific function> = specific_function %impl.elem0.loc6_22, @T.as_type.as.EqWith.impl.Equal.1(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.1]
// CHECK:STDOUT:   %bound_method.loc6_22.2: <bound method> = bound_method %int_1, %specific_fn.loc6_22 [concrete = constants.%bound_method.42af37.1]
// CHECK:STDOUT:   %.loc6_22.1: %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.1 = specific_constant imports.%Core.Equal.970, @T.as_type.as.EqWith.impl(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.57b831.1]
// CHECK:STDOUT:   %Equal.ref: %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.1 = name_ref Equal, %.loc6_22.1 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.57b831.1]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound: <bound method> = bound_method %int_1, %Equal.ref [concrete = constants.%T.as_type.as.EqWith.impl.Equal.bound.29e975.2]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.specific_fn: <specific function> = specific_function %Equal.ref, @T.as_type.as.EqWith.impl.Equal.2(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.2]
// CHECK:STDOUT:   %bound_method.loc6_22.3: <bound method> = bound_method %int_1, %T.as_type.as.EqWith.impl.Equal.specific_fn [concrete = constants.%bound_method.42af37.2]
// CHECK:STDOUT:   %impl.elem0.loc6_11: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc6_11.1: <bound method> = bound_method %int_1, %impl.elem0.loc6_11 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc6_11: <specific function> = specific_function %impl.elem0.loc6_11, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc6_11.2: <bound method> = bound_method %int_1, %specific_fn.loc6_11 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc6: init %i32 = call %bound_method.loc6_11.2(%int_1) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc6_11.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc6 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc6_11.2: %i32 = converted %int_1, %.loc6_11.1 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.call: init bool = call %bound_method.loc6_22.3(%.loc6_11.2, %tuple.elem0)
// CHECK:STDOUT:   %.loc6_22.2: bool = value_of_initializer %T.as_type.as.EqWith.impl.Equal.call
// CHECK:STDOUT:   %.loc6_22.3: bool = converted %T.as_type.as.EqWith.impl.Equal.call, %.loc6_22.2
// CHECK:STDOUT:   if %.loc6_22.3 br !match.case.then else br !match.case.else
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then:
// CHECK:STDOUT:   %tuple.elem1: %i32 = tuple_access %p.ref, element1
// CHECK:STDOUT:   %i32.loc6: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %b: %i32 = wrapper_binding b, %tuple.elem1
// CHECK:STDOUT:   %b.ref: %i32 = name_ref b, %b
// CHECK:STDOUT:   %impl.elem0.loc6_34: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc6_34.1: <bound method> = bound_method %b.ref, %impl.elem0.loc6_34
// CHECK:STDOUT:   %specific_fn.loc6_34: <specific function> = specific_function %impl.elem0.loc6_34, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc6_34.2: <bound method> = bound_method %b.ref, %specific_fn.loc6_34
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc6_34.2(%b.ref)
// CHECK:STDOUT:   return %Int.as.Copy.impl.Op.call
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else:
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc7: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc7_26.1: <bound method> = bound_method %int_0, %impl.elem0.loc7 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc7: <specific function> = specific_function %impl.elem0.loc7, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc7_26.2: <bound method> = bound_method %int_0, %specific_fn.loc7 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc7: init %i32 = call %bound_method.loc7_26.2(%int_0) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc7: init %i32 = converted %int_0, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc7 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   return %.loc7
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- expr_element_conversion.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %Int.67af24.1: type = class_type @Int, @Int(%N) [symbolic]
// CHECK:STDOUT:   %pattern_type.dc0: type = pattern_type Core.IntLiteral [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %tuple.type.24b: type = tuple_type (type, type) [concrete]
// CHECK:STDOUT:   %tuple.b59: %tuple.type.24b = tuple_value (%i32, %i32) [concrete]
// CHECK:STDOUT:   %tuple.type.e55: type = tuple_type (%i32, %i32) [concrete]
// CHECK:STDOUT:   %pattern_type.394: type = pattern_type %tuple.type.e55 [concrete]
// CHECK:STDOUT:   %p.param_patt: %pattern_type.394 = value_param_pattern [concrete]
// CHECK:STDOUT:   %p.patt: %pattern_type.394 = wrapper_binding_pattern p, %p.param_patt [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %int_3: Core.IntLiteral = int_value 3 [concrete]
// CHECK:STDOUT:   %AddWith.type.832: type = facet_type <@AddWith, @AddWith(Core.IntLiteral)> [concrete]
// CHECK:STDOUT:   %AddWith.impl_witness: <witness> = impl_witness imports.%AddWith.impl_witness_table [concrete]
// CHECK:STDOUT:   %AddWith.facet: %AddWith.type.832 = facet_value Core.IntLiteral, (%AddWith.impl_witness) [concrete]
// CHECK:STDOUT:   %AddWith.WithSelf.Op.type.a21: type = fn_type @AddWith.WithSelf.Op, @AddWith.WithSelf(Core.IntLiteral, %AddWith.facet) [concrete]
// CHECK:STDOUT:   %.fbc: type = fn_type_with_self_type %AddWith.WithSelf.Op.type.a21, %AddWith.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.AddWith.impl.Op.type: type = fn_type @Core.IntLiteral.as.AddWith.impl.Op [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.AddWith.impl.Op: %Core.IntLiteral.as.AddWith.impl.Op.type = struct_value () [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.AddWith.impl.Op.bound: <bound method> = bound_method %int_2, %Core.IntLiteral.as.AddWith.impl.Op [concrete]
// CHECK:STDOUT:   %int_5.64b: Core.IntLiteral = int_value 5 [concrete]
// CHECK:STDOUT:   %b.patt: %pattern_type.6b6 = value_binding_pattern b [concrete]
// CHECK:STDOUT:   %tuple.type.94b: type = tuple_type (Core.IntLiteral, %i32) [concrete]
// CHECK:STDOUT:   %pattern_type.106: type = pattern_type %tuple.type.94b [concrete]
// CHECK:STDOUT:   %.e47: %pattern_type.106 = tuple_pattern (@F.%expr_patt, %b.patt) [concrete]
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
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
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
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound.eb3ec9.1: <bound method> = bound_method %int_5.64b, %T.as_type.as.EqWith.impl.Equal.57b831.2 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.1: <specific function> = specific_function %T.as_type.as.EqWith.impl.Equal.57b831.2, @T.as_type.as.EqWith.impl.Equal.1(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %bound_method.7e6b34.1: <bound method> = bound_method %int_5.64b, %T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.1 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound.eb3ec9.2: <bound method> = bound_method %int_5.64b, %T.as_type.as.EqWith.impl.Equal.57b831.1 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.2: <specific function> = specific_function %T.as_type.as.EqWith.impl.Equal.57b831.1, @T.as_type.as.EqWith.impl.Equal.2(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %bound_method.7e6b34.2: <bound method> = bound_method %int_5.64b, %T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.2 [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.f6c: <bound method> = bound_method %int_5.64b, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.c9d: <bound method> = bound_method %int_5.64b, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_5.eef: %i32 = int_value 5 [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet: %Copy.type = facet_value %i32, (%Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.381: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet) [concrete]
// CHECK:STDOUT:   %.737: type = fn_type_with_self_type %Copy.WithSelf.Op.type.381, %Copy.facet [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.6e0: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_0.3c0: %i32 = int_value 0 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.abd97d.1 = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9c3475.1: %Core.IntLiteral.as.AddWith.impl.Op.type = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, loaded [concrete = constants.%Core.IntLiteral.as.AddWith.impl.Op]
// CHECK:STDOUT:   %AddWith.impl_witness_table = impl_witness_table (%Core.import_ref.abd97d.1, %Core.import_ref.9c3475.1), @Core.IntLiteral.as.AddWith.impl.8f4 [concrete]
// CHECK:STDOUT:   %Core.import_ref.a9a: @T.as_type.as.EqWith.impl.%T.as_type.as.EqWith.impl.Equal.type.2 (%T.as_type.as.EqWith.impl.Equal.type.8af025.1) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @T.as_type.as.EqWith.impl.%T.as_type.as.EqWith.impl.Equal.2 (constants.%T.as_type.as.EqWith.impl.Equal.c477d6.1)]
// CHECK:STDOUT:   %Core.import_ref.712 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.532 = impl_witness_table (%Core.import_ref.a9a, %Core.import_ref.712), @T.as_type.as.EqWith.impl [concrete]
// CHECK:STDOUT:   %Core.Equal.970: @T.as_type.as.EqWith.impl.%T.as_type.as.EqWith.impl.Equal.type.1 (%T.as_type.as.EqWith.impl.Equal.type.8af025.2) = import_ref Core//prelude/types/int, Equal, loaded [symbolic = @T.as_type.as.EqWith.impl.%T.as_type.as.EqWith.impl.Equal.1 (constants.%T.as_type.as.EqWith.impl.Equal.c477d6.2)]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %F.decl: %F.type = fn_decl @F [concrete = constants.%F] {
// CHECK:STDOUT:     %p.param_patt: %pattern_type.394 = value_param_pattern [concrete = constants.%p.param_patt]
// CHECK:STDOUT:     %p.patt: %pattern_type.394 = wrapper_binding_pattern p, %p.param_patt [concrete = constants.%p.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc7_24 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc7_24: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc7_24: Core.Form = init_form %i32.loc7_24 [concrete = constants.%.795f]
// CHECK:STDOUT:     %p.param: %tuple.type.e55 = value_param call_param0
// CHECK:STDOUT:     %.loc7_18.1: type = splice_block %.loc7_18.3 [concrete = constants.%tuple.type.e55] {
// CHECK:STDOUT:       %i32.loc7_10: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %i32.loc7_15: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %.loc7_18.2: %tuple.type.24b = tuple_literal (%i32.loc7_10, %i32.loc7_15) [concrete = constants.%tuple.b59]
// CHECK:STDOUT:       %.loc7_18.3: type = converted %.loc7_18.2, constants.%tuple.type.e55 [concrete = constants.%tuple.type.e55]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %p: %tuple.type.e55 = wrapper_binding p, %p.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @F(%p.param: %tuple.type.e55) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %p.ref: %tuple.type.e55 = name_ref p, %p
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt: %pattern_type.dc0 = expr_pattern %.loc9_13.5 in [concrete] {
// CHECK:STDOUT:       %int_2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2]
// CHECK:STDOUT:       %int_3: Core.IntLiteral = int_value 3 [concrete = constants.%int_3]
// CHECK:STDOUT:       %impl.elem1: %.fbc = impl_witness_access constants.%AddWith.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.AddWith.impl.Op]
// CHECK:STDOUT:       %bound_method.loc9_13.3: <bound method> = bound_method %int_2, %impl.elem1 [concrete = constants.%Core.IntLiteral.as.AddWith.impl.Op.bound]
// CHECK:STDOUT:       %Core.IntLiteral.as.AddWith.impl.Op.call: init Core.IntLiteral = call %bound_method.loc9_13.3(%int_2, %int_3) [concrete = constants.%int_5.64b]
// CHECK:STDOUT:       %.loc9_13.4: Core.IntLiteral = value_of_initializer %Core.IntLiteral.as.AddWith.impl.Op.call [concrete = constants.%int_5.64b]
// CHECK:STDOUT:       %.loc9_13.5: Core.IntLiteral = converted %Core.IntLiteral.as.AddWith.impl.Op.call, %.loc9_13.4 [concrete = constants.%int_5.64b]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %b.patt: %pattern_type.6b6 = value_binding_pattern b [concrete = constants.%b.patt]
// CHECK:STDOUT:     %.loc9_24: %pattern_type.106 = tuple_pattern (%expr_patt, %b.patt) [concrete = constants.%.e47]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %tuple.elem0: %i32 = tuple_access %p.ref, element0
// CHECK:STDOUT:   %.loc9_13.1: Core.IntLiteral = splice_block %.loc9_13.5 [concrete = constants.%int_5.64b] {
// CHECK:STDOUT:     %int_2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2]
// CHECK:STDOUT:     %int_3: Core.IntLiteral = int_value 3 [concrete = constants.%int_3]
// CHECK:STDOUT:     %impl.elem1: %.fbc = impl_witness_access constants.%AddWith.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.AddWith.impl.Op]
// CHECK:STDOUT:     %bound_method.loc9_13.3: <bound method> = bound_method %int_2, %impl.elem1 [concrete = constants.%Core.IntLiteral.as.AddWith.impl.Op.bound]
// CHECK:STDOUT:     %Core.IntLiteral.as.AddWith.impl.Op.call: init Core.IntLiteral = call %bound_method.loc9_13.3(%int_2, %int_3) [concrete = constants.%int_5.64b]
// CHECK:STDOUT:     %.loc9_13.4: Core.IntLiteral = value_of_initializer %Core.IntLiteral.as.AddWith.impl.Op.call [concrete = constants.%int_5.64b]
// CHECK:STDOUT:     %.loc9_13.5: Core.IntLiteral = converted %Core.IntLiteral.as.AddWith.impl.Op.call, %.loc9_13.4 [concrete = constants.%int_5.64b]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %impl.elem0.loc9_26: %.025 = impl_witness_access constants.%EqWith.impl_witness.bde, element0 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.57b831.2]
// CHECK:STDOUT:   %bound_method.loc9_26.1: <bound method> = bound_method %.loc9_13.1, %impl.elem0.loc9_26 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.bound.eb3ec9.1]
// CHECK:STDOUT:   %specific_fn.loc9_26: <specific function> = specific_function %impl.elem0.loc9_26, @T.as_type.as.EqWith.impl.Equal.1(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.1]
// CHECK:STDOUT:   %bound_method.loc9_26.2: <bound method> = bound_method %.loc9_13.1, %specific_fn.loc9_26 [concrete = constants.%bound_method.7e6b34.1]
// CHECK:STDOUT:   %.loc9_26.1: %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.1 = specific_constant imports.%Core.Equal.970, @T.as_type.as.EqWith.impl(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.57b831.1]
// CHECK:STDOUT:   %Equal.ref: %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.1 = name_ref Equal, %.loc9_26.1 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.57b831.1]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound: <bound method> = bound_method %.loc9_13.1, %Equal.ref [concrete = constants.%T.as_type.as.EqWith.impl.Equal.bound.eb3ec9.2]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.specific_fn: <specific function> = specific_function %Equal.ref, @T.as_type.as.EqWith.impl.Equal.2(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.2]
// CHECK:STDOUT:   %bound_method.loc9_26.3: <bound method> = bound_method %.loc9_13.1, %T.as_type.as.EqWith.impl.Equal.specific_fn [concrete = constants.%bound_method.7e6b34.2]
// CHECK:STDOUT:   %impl.elem0.loc9_13: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc9_13.1: <bound method> = bound_method %.loc9_13.1, %impl.elem0.loc9_13 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.f6c]
// CHECK:STDOUT:   %specific_fn.loc9_13: <specific function> = specific_function %impl.elem0.loc9_13, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc9_13.2: <bound method> = bound_method %.loc9_13.1, %specific_fn.loc9_13 [concrete = constants.%bound_method.c9d]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc9: init %i32 = call %bound_method.loc9_13.2(%.loc9_13.1) [concrete = constants.%int_5.eef]
// CHECK:STDOUT:   %.loc9_13.2: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc9 [concrete = constants.%int_5.eef]
// CHECK:STDOUT:   %.loc9_13.3: %i32 = converted %.loc9_13.1, %.loc9_13.2 [concrete = constants.%int_5.eef]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.call: init bool = call %bound_method.loc9_26.3(%.loc9_13.3, %tuple.elem0)
// CHECK:STDOUT:   %.loc9_26.2: bool = value_of_initializer %T.as_type.as.EqWith.impl.Equal.call
// CHECK:STDOUT:   %.loc9_26.3: bool = converted %T.as_type.as.EqWith.impl.Equal.call, %.loc9_26.2
// CHECK:STDOUT:   if %.loc9_26.3 br !match.case.then else br !match.case.else
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then:
// CHECK:STDOUT:   %tuple.elem1: %i32 = tuple_access %p.ref, element1
// CHECK:STDOUT:   %i32.loc9: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %b: %i32 = wrapper_binding b, %tuple.elem1
// CHECK:STDOUT:   %b.ref: %i32 = name_ref b, %b
// CHECK:STDOUT:   %impl.elem0.loc9_38: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc9_38.1: <bound method> = bound_method %b.ref, %impl.elem0.loc9_38
// CHECK:STDOUT:   %specific_fn.loc9_38: <specific function> = specific_function %impl.elem0.loc9_38, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc9_38.2: <bound method> = bound_method %b.ref, %specific_fn.loc9_38
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc9_38.2(%b.ref)
// CHECK:STDOUT:   return %Int.as.Copy.impl.Op.call
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else:
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc10: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc10_26.1: <bound method> = bound_method %int_0, %impl.elem0.loc10 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc10: <specific function> = specific_function %impl.elem0.loc10, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc10_26.2: <bound method> = bound_method %int_0, %specific_fn.loc10 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc10: init %i32 = call %bound_method.loc10_26.2(%int_0) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc10: init %i32 = converted %int_0, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc10 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   return %.loc10
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- nested_tuple.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %Int.67af24.1: type = class_type @Int, @Int(%N) [symbolic]
// CHECK:STDOUT:   %pattern_type.dc0: type = pattern_type Core.IntLiteral [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %tuple.type.24b: type = tuple_type (type, type) [concrete]
// CHECK:STDOUT:   %tuple.b59: %tuple.type.24b = tuple_value (%i32, %i32) [concrete]
// CHECK:STDOUT:   %tuple.type.3eb: type = tuple_type (type, %tuple.type.24b) [concrete]
// CHECK:STDOUT:   %tuple.4b7: %tuple.type.3eb = tuple_value (%i32, %tuple.b59) [concrete]
// CHECK:STDOUT:   %tuple.type.e55: type = tuple_type (%i32, %i32) [concrete]
// CHECK:STDOUT:   %tuple.type.920: type = tuple_type (%i32, %tuple.type.e55) [concrete]
// CHECK:STDOUT:   %pattern_type.e87: type = pattern_type %tuple.type.920 [concrete]
// CHECK:STDOUT:   %p.param_patt: %pattern_type.e87 = value_param_pattern [concrete]
// CHECK:STDOUT:   %p.patt: %pattern_type.e87 = wrapper_binding_pattern p, %p.param_patt [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_42.20e: Core.IntLiteral = int_value 42 [concrete]
// CHECK:STDOUT:   %x.patt: %pattern_type.6b6 = value_binding_pattern x [concrete]
// CHECK:STDOUT:   %y.patt: %pattern_type.6b6 = value_binding_pattern y [concrete]
// CHECK:STDOUT:   %pattern_type.394: type = pattern_type %tuple.type.e55 [concrete]
// CHECK:STDOUT:   %.692: %pattern_type.394 = tuple_pattern (%x.patt, %y.patt) [concrete]
// CHECK:STDOUT:   %tuple.type.795: type = tuple_type (Core.IntLiteral, %tuple.type.e55) [concrete]
// CHECK:STDOUT:   %pattern_type.d5e: type = pattern_type %tuple.type.795 [concrete]
// CHECK:STDOUT:   %.6b1: %pattern_type.d5e = tuple_pattern (@F.%expr_patt.loc8, %.692) [concrete]
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
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
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
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound.ce8afa.1: <bound method> = bound_method %int_42.20e, %T.as_type.as.EqWith.impl.Equal.57b831.2 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.1: <specific function> = specific_function %T.as_type.as.EqWith.impl.Equal.57b831.2, @T.as_type.as.EqWith.impl.Equal.1(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %bound_method.908f65.1: <bound method> = bound_method %int_42.20e, %T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.1 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound.ce8afa.2: <bound method> = bound_method %int_42.20e, %T.as_type.as.EqWith.impl.Equal.57b831.1 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.2: <specific function> = specific_function %T.as_type.as.EqWith.impl.Equal.57b831.1, @T.as_type.as.EqWith.impl.Equal.2(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %bound_method.908f65.2: <bound method> = bound_method %int_42.20e, %T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.2 [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.bf3: <bound method> = bound_method %int_42.20e, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.098: <bound method> = bound_method %int_42.20e, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_42.ac4: %i32 = int_value 42 [concrete]
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
// CHECK:STDOUT:   %n.patt: %pattern_type.6b6 = value_binding_pattern n [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %int_2.ecc: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %tuple.type.f94: type = tuple_type (Core.IntLiteral, Core.IntLiteral) [concrete]
// CHECK:STDOUT:   %pattern_type.82e: type = pattern_type %tuple.type.f94 [concrete]
// CHECK:STDOUT:   %.0e9: %pattern_type.82e = tuple_pattern (@F.%expr_patt.loc9_20, @F.%expr_patt.loc9_23) [concrete]
// CHECK:STDOUT:   %tuple.type.edd: type = tuple_type (%i32, %tuple.type.f94) [concrete]
// CHECK:STDOUT:   %pattern_type.bbb: type = pattern_type %tuple.type.edd [concrete]
// CHECK:STDOUT:   %.e05: %pattern_type.bbb = tuple_pattern (%n.patt, %.0e9) [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound.29e975.1: <bound method> = bound_method %int_1.5b8, %T.as_type.as.EqWith.impl.Equal.57b831.2 [concrete]
// CHECK:STDOUT:   %bound_method.42af37.1: <bound method> = bound_method %int_1.5b8, %T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.1 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound.29e975.2: <bound method> = bound_method %int_1.5b8, %T.as_type.as.EqWith.impl.Equal.57b831.1 [concrete]
// CHECK:STDOUT:   %bound_method.42af37.2: <bound method> = bound_method %int_1.5b8, %T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.2 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.953: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound.811140.1: <bound method> = bound_method %int_2.ecc, %T.as_type.as.EqWith.impl.Equal.57b831.2 [concrete]
// CHECK:STDOUT:   %bound_method.ee93db.1: <bound method> = bound_method %int_2.ecc, %T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.1 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound.811140.2: <bound method> = bound_method %int_2.ecc, %T.as_type.as.EqWith.impl.Equal.57b831.1 [concrete]
// CHECK:STDOUT:   %bound_method.ee93db.2: <bound method> = bound_method %int_2.ecc, %T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.2 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.9f3: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.3cb: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_2.295: %i32 = int_value 2 [concrete]
// CHECK:STDOUT:   %false: bool = bool_literal false [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet: %Copy.type = facet_value %i32, (%Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.381: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet) [concrete]
// CHECK:STDOUT:   %.737: type = fn_type_with_self_type %Copy.WithSelf.Op.type.381, %Copy.facet [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.6e0: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_0.3c0: %i32 = int_value 0 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.a9a: @T.as_type.as.EqWith.impl.%T.as_type.as.EqWith.impl.Equal.type.2 (%T.as_type.as.EqWith.impl.Equal.type.8af025.1) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @T.as_type.as.EqWith.impl.%T.as_type.as.EqWith.impl.Equal.2 (constants.%T.as_type.as.EqWith.impl.Equal.c477d6.1)]
// CHECK:STDOUT:   %Core.import_ref.712 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.532 = impl_witness_table (%Core.import_ref.a9a, %Core.import_ref.712), @T.as_type.as.EqWith.impl [concrete]
// CHECK:STDOUT:   %Core.Equal.970: @T.as_type.as.EqWith.impl.%T.as_type.as.EqWith.impl.Equal.type.1 (%T.as_type.as.EqWith.impl.Equal.type.8af025.2) = import_ref Core//prelude/types/int, Equal, loaded [symbolic = @T.as_type.as.EqWith.impl.%T.as_type.as.EqWith.impl.Equal.1 (constants.%T.as_type.as.EqWith.impl.Equal.c477d6.2)]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.b4fd3a.1 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.684: @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op.type (%Int.as.AddWith.impl.Op.type.610) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op (constants.%Int.as.AddWith.impl.Op.732)]
// CHECK:STDOUT:   %AddWith.impl_witness_table.6b4 = impl_witness_table (%Core.import_ref.b4fd3a.1, %Core.import_ref.684), @Int.as.AddWith.impl.3af [concrete]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %F.decl: %F.type = fn_decl @F [concrete = constants.%F] {
// CHECK:STDOUT:     %p.param_patt: %pattern_type.e87 = value_param_pattern [concrete = constants.%p.param_patt]
// CHECK:STDOUT:     %p.patt: %pattern_type.e87 = wrapper_binding_pattern p, %p.param_patt [concrete = constants.%p.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc6_31 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc6_31: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc6_31: Core.Form = init_form %i32.loc6_31 [concrete = constants.%.795f]
// CHECK:STDOUT:     %p.param: %tuple.type.920 = value_param call_param0
// CHECK:STDOUT:     %.loc6_25.1: type = splice_block %.loc6_25.4 [concrete = constants.%tuple.type.920] {
// CHECK:STDOUT:       %i32.loc6_10: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %i32.loc6_16: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %i32.loc6_21: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %.loc6_24: %tuple.type.24b = tuple_literal (%i32.loc6_16, %i32.loc6_21) [concrete = constants.%tuple.b59]
// CHECK:STDOUT:       %.loc6_25.2: %tuple.type.3eb = tuple_literal (%i32.loc6_10, %.loc6_24) [concrete = constants.%tuple.4b7]
// CHECK:STDOUT:       %.loc6_25.3: type = converted constants.%tuple.b59, constants.%tuple.type.e55 [concrete = constants.%tuple.type.e55]
// CHECK:STDOUT:       %.loc6_25.4: type = converted %.loc6_25.2, constants.%tuple.type.920 [concrete = constants.%tuple.type.920]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %p: %tuple.type.920 = wrapper_binding p, %p.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @F(%p.param: %tuple.type.920) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %p.ref: %tuple.type.920 = name_ref p, %p
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt.loc8: %pattern_type.dc0 = expr_pattern %int_42 in [concrete] {
// CHECK:STDOUT:       %int_42: Core.IntLiteral = int_value 42 [concrete = constants.%int_42.20e]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %x.patt: %pattern_type.6b6 = value_binding_pattern x [concrete = constants.%x.patt]
// CHECK:STDOUT:     %y.patt: %pattern_type.6b6 = value_binding_pattern y [concrete = constants.%y.patt]
// CHECK:STDOUT:     %.loc8_30: %pattern_type.394 = tuple_pattern (%x.patt, %y.patt) [concrete = constants.%.692]
// CHECK:STDOUT:     %.loc8_31: %pattern_type.d5e = tuple_pattern (%expr_patt.loc8, %.loc8_30) [concrete = constants.%.6b1]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %tuple.elem0.loc7_10.1: %i32 = tuple_access %p.ref, element0
// CHECK:STDOUT:   %int_42: Core.IntLiteral = int_value 42 [concrete = constants.%int_42.20e]
// CHECK:STDOUT:   %impl.elem0.loc8_33: %.025 = impl_witness_access constants.%EqWith.impl_witness.bde, element0 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.57b831.2]
// CHECK:STDOUT:   %bound_method.loc8_33.1: <bound method> = bound_method %int_42, %impl.elem0.loc8_33 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.bound.ce8afa.1]
// CHECK:STDOUT:   %specific_fn.loc8_33: <specific function> = specific_function %impl.elem0.loc8_33, @T.as_type.as.EqWith.impl.Equal.1(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.1]
// CHECK:STDOUT:   %bound_method.loc8_33.2: <bound method> = bound_method %int_42, %specific_fn.loc8_33 [concrete = constants.%bound_method.908f65.1]
// CHECK:STDOUT:   %.loc8_33.1: %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.1 = specific_constant imports.%Core.Equal.970, @T.as_type.as.EqWith.impl(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.57b831.1]
// CHECK:STDOUT:   %Equal.ref.loc8: %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.1 = name_ref Equal, %.loc8_33.1 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.57b831.1]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound.loc8: <bound method> = bound_method %int_42, %Equal.ref.loc8 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.bound.ce8afa.2]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.specific_fn.loc8: <specific function> = specific_function %Equal.ref.loc8, @T.as_type.as.EqWith.impl.Equal.2(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.2]
// CHECK:STDOUT:   %bound_method.loc8_33.3: <bound method> = bound_method %int_42, %T.as_type.as.EqWith.impl.Equal.specific_fn.loc8 [concrete = constants.%bound_method.908f65.2]
// CHECK:STDOUT:   %impl.elem0.loc8_11: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc8_11.1: <bound method> = bound_method %int_42, %impl.elem0.loc8_11 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.bf3]
// CHECK:STDOUT:   %specific_fn.loc8_11: <specific function> = specific_function %impl.elem0.loc8_11, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc8_11.2: <bound method> = bound_method %int_42, %specific_fn.loc8_11 [concrete = constants.%bound_method.098]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc8: init %i32 = call %bound_method.loc8_11.2(%int_42) [concrete = constants.%int_42.ac4]
// CHECK:STDOUT:   %.loc8_11.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc8 [concrete = constants.%int_42.ac4]
// CHECK:STDOUT:   %.loc8_11.2: %i32 = converted %int_42, %.loc8_11.1 [concrete = constants.%int_42.ac4]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.call.loc8: init bool = call %bound_method.loc8_33.3(%.loc8_11.2, %tuple.elem0.loc7_10.1)
// CHECK:STDOUT:   %.loc8_33.2: bool = value_of_initializer %T.as_type.as.EqWith.impl.Equal.call.loc8
// CHECK:STDOUT:   %.loc8_33.3: bool = converted %T.as_type.as.EqWith.impl.Equal.call.loc8, %.loc8_33.2
// CHECK:STDOUT:   if %.loc8_33.3 br !match.case.then.loc8 else br !match.case.else.loc8
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc8:
// CHECK:STDOUT:   %tuple.elem1.loc7_10.1: %tuple.type.e55 = tuple_access %p.ref, element1
// CHECK:STDOUT:   %tuple.elem0.loc7_10.2: %i32 = tuple_access %tuple.elem1.loc7_10.1, element0
// CHECK:STDOUT:   %tuple.elem1.loc7_10.2: %i32 = tuple_access %tuple.elem1.loc7_10.1, element1
// CHECK:STDOUT:   %i32.loc8_19: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %x: %i32 = wrapper_binding x, %tuple.elem0.loc7_10.2
// CHECK:STDOUT:   %i32.loc8_27: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %y: %i32 = wrapper_binding y, %tuple.elem1.loc7_10.2
// CHECK:STDOUT:   %x.ref: %i32 = name_ref x, %x
// CHECK:STDOUT:   %y.ref: %i32 = name_ref y, %y
// CHECK:STDOUT:   %impl.elem1: %.d47 = impl_witness_access constants.%AddWith.impl_witness.833, element1 [concrete = constants.%Int.as.AddWith.impl.Op.365]
// CHECK:STDOUT:   %bound_method.loc8_47.1: <bound method> = bound_method %x.ref, %impl.elem1
// CHECK:STDOUT:   %specific_fn.loc8_47: <specific function> = specific_function %impl.elem1, @Int.as.AddWith.impl.Op.1(constants.%int_32) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.f25]
// CHECK:STDOUT:   %bound_method.loc8_47.2: <bound method> = bound_method %x.ref, %specific_fn.loc8_47
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call: init %i32 = call %bound_method.loc8_47.2(%x.ref, %y.ref)
// CHECK:STDOUT:   return %Int.as.AddWith.impl.Op.call
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc8:
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %n.patt: %pattern_type.6b6 = value_binding_pattern n [concrete = constants.%n.patt]
// CHECK:STDOUT:     %expr_patt.loc9_20: %pattern_type.dc0 = expr_pattern %int_1 in [concrete] {
// CHECK:STDOUT:       %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %expr_patt.loc9_23: %pattern_type.dc0 = expr_pattern %int_2 in [concrete] {
// CHECK:STDOUT:       %int_2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %.loc9_24: %pattern_type.82e = tuple_pattern (%expr_patt.loc9_20, %expr_patt.loc9_23) [concrete = constants.%.0e9]
// CHECK:STDOUT:     %.loc9_25: %pattern_type.bbb = tuple_pattern (%n.patt, %.loc9_24) [concrete = constants.%.e05]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %tuple.elem1.loc7_10.3: %tuple.type.e55 = tuple_access %p.ref, element1
// CHECK:STDOUT:   %tuple.elem0.loc7_10.3: %i32 = tuple_access %tuple.elem1.loc7_10.3, element0
// CHECK:STDOUT:   %tuple.elem1.loc7_10.4: %i32 = tuple_access %tuple.elem1.loc7_10.3, element1
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc9_27.1: %.025 = impl_witness_access constants.%EqWith.impl_witness.bde, element0 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.57b831.2]
// CHECK:STDOUT:   %bound_method.loc9_27.1: <bound method> = bound_method %int_1, %impl.elem0.loc9_27.1 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.bound.29e975.1]
// CHECK:STDOUT:   %specific_fn.loc9_27.1: <specific function> = specific_function %impl.elem0.loc9_27.1, @T.as_type.as.EqWith.impl.Equal.1(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.1]
// CHECK:STDOUT:   %bound_method.loc9_27.2: <bound method> = bound_method %int_1, %specific_fn.loc9_27.1 [concrete = constants.%bound_method.42af37.1]
// CHECK:STDOUT:   %.loc9_27.1: %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.1 = specific_constant imports.%Core.Equal.970, @T.as_type.as.EqWith.impl(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.57b831.1]
// CHECK:STDOUT:   %Equal.ref.loc9_27.1: %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.1 = name_ref Equal, %.loc9_27.1 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.57b831.1]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound.loc9_27.1: <bound method> = bound_method %int_1, %Equal.ref.loc9_27.1 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.bound.29e975.2]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.specific_fn.loc9_27.1: <specific function> = specific_function %Equal.ref.loc9_27.1, @T.as_type.as.EqWith.impl.Equal.2(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.2]
// CHECK:STDOUT:   %bound_method.loc9_27.3: <bound method> = bound_method %int_1, %T.as_type.as.EqWith.impl.Equal.specific_fn.loc9_27.1 [concrete = constants.%bound_method.42af37.2]
// CHECK:STDOUT:   %impl.elem0.loc9_20: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc9_20.1: <bound method> = bound_method %int_1, %impl.elem0.loc9_20 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc9_20: <specific function> = specific_function %impl.elem0.loc9_20, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc9_20.2: <bound method> = bound_method %int_1, %specific_fn.loc9_20 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc9_20: init %i32 = call %bound_method.loc9_20.2(%int_1) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc9_20.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc9_20 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc9_20.2: %i32 = converted %int_1, %.loc9_20.1 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.call.loc9_27.1: init bool = call %bound_method.loc9_27.3(%.loc9_20.2, %tuple.elem0.loc7_10.3)
// CHECK:STDOUT:   %.loc9_27.2: bool = value_of_initializer %T.as_type.as.EqWith.impl.Equal.call.loc9_27.1
// CHECK:STDOUT:   %.loc9_27.3: bool = converted %T.as_type.as.EqWith.impl.Equal.call.loc9_27.1, %.loc9_27.2
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:   %impl.elem0.loc9_27.2: %.025 = impl_witness_access constants.%EqWith.impl_witness.bde, element0 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.57b831.2]
// CHECK:STDOUT:   %bound_method.loc9_27.4: <bound method> = bound_method %int_2, %impl.elem0.loc9_27.2 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.bound.811140.1]
// CHECK:STDOUT:   %specific_fn.loc9_27.2: <specific function> = specific_function %impl.elem0.loc9_27.2, @T.as_type.as.EqWith.impl.Equal.1(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.1]
// CHECK:STDOUT:   %bound_method.loc9_27.5: <bound method> = bound_method %int_2, %specific_fn.loc9_27.2 [concrete = constants.%bound_method.ee93db.1]
// CHECK:STDOUT:   %.loc9_27.4: %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.1 = specific_constant imports.%Core.Equal.970, @T.as_type.as.EqWith.impl(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.57b831.1]
// CHECK:STDOUT:   %Equal.ref.loc9_27.2: %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.1 = name_ref Equal, %.loc9_27.4 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.57b831.1]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound.loc9_27.2: <bound method> = bound_method %int_2, %Equal.ref.loc9_27.2 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.bound.811140.2]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.specific_fn.loc9_27.2: <specific function> = specific_function %Equal.ref.loc9_27.2, @T.as_type.as.EqWith.impl.Equal.2(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.2]
// CHECK:STDOUT:   %bound_method.loc9_27.6: <bound method> = bound_method %int_2, %T.as_type.as.EqWith.impl.Equal.specific_fn.loc9_27.2 [concrete = constants.%bound_method.ee93db.2]
// CHECK:STDOUT:   %impl.elem0.loc9_23: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc9_23.1: <bound method> = bound_method %int_2, %impl.elem0.loc9_23 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.9f3]
// CHECK:STDOUT:   %specific_fn.loc9_23: <specific function> = specific_function %impl.elem0.loc9_23, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc9_23.2: <bound method> = bound_method %int_2, %specific_fn.loc9_23 [concrete = constants.%bound_method.3cb]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc9_23: init %i32 = call %bound_method.loc9_23.2(%int_2) [concrete = constants.%int_2.295]
// CHECK:STDOUT:   %.loc9_23.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc9_23 [concrete = constants.%int_2.295]
// CHECK:STDOUT:   %.loc9_23.2: %i32 = converted %int_2, %.loc9_23.1 [concrete = constants.%int_2.295]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.call.loc9_27.2: init bool = call %bound_method.loc9_27.6(%.loc9_23.2, %tuple.elem1.loc7_10.4)
// CHECK:STDOUT:   %.loc9_27.5: bool = value_of_initializer %T.as_type.as.EqWith.impl.Equal.call.loc9_27.2
// CHECK:STDOUT:   %.loc9_27.6: bool = converted %T.as_type.as.EqWith.impl.Equal.call.loc9_27.2, %.loc9_27.5
// CHECK:STDOUT:   %false: bool = bool_literal false [concrete = constants.%false]
// CHECK:STDOUT:   if %.loc9_27.3 br !match.case.then.loc9_27.1 else br !match.<unexpected BranchWithArg>(%false)
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc9_27.1:
// CHECK:STDOUT:   br !match.<unexpected BranchWithArg>(%.loc9_27.6)
// CHECK:STDOUT:
// CHECK:STDOUT: !match.<unexpected BranchWithArg>:
// CHECK:STDOUT:   %.loc9_27.7: bool = block_arg !match.<unexpected BranchWithArg>
// CHECK:STDOUT:   if %.loc9_27.7 br !match.case.then.loc9_27.2 else br !match.case.else.loc9
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc9_27.2:
// CHECK:STDOUT:   %tuple.elem0.loc7_10.4: %i32 = tuple_access %p.ref, element0
// CHECK:STDOUT:   %i32.loc9: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %n: %i32 = wrapper_binding n, %tuple.elem0.loc7_10.4
// CHECK:STDOUT:   %n.ref: %i32 = name_ref n, %n
// CHECK:STDOUT:   %impl.elem0.loc9_39: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc9_39.1: <bound method> = bound_method %n.ref, %impl.elem0.loc9_39
// CHECK:STDOUT:   %specific_fn.loc9_39: <specific function> = specific_function %impl.elem0.loc9_39, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc9_39.2: <bound method> = bound_method %n.ref, %specific_fn.loc9_39
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc9_39.2(%n.ref)
// CHECK:STDOUT:   return %Int.as.Copy.impl.Op.call
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc9:
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc10: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc10_26.1: <bound method> = bound_method %int_0, %impl.elem0.loc10 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc10: <specific function> = specific_function %impl.elem0.loc10, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc10_26.2: <bound method> = bound_method %int_0, %specific_fn.loc10 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc10: init %i32 = call %bound_method.loc10_26.2(%int_0) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc10: init %i32 = converted %int_0, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc10 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   return %.loc10
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- var_scrutinee.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %Int.67af24.1: type = class_type @Int, @Int(%N) [symbolic]
// CHECK:STDOUT:   %pattern_type.dc0: type = pattern_type Core.IntLiteral [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT:   %i32.builtin: type = int_type signed, %int_32 [concrete]
// CHECK:STDOUT:   %tuple.type.24b: type = tuple_type (type, type) [concrete]
// CHECK:STDOUT:   %tuple.b59: %tuple.type.24b = tuple_value (%i32, %i32) [concrete]
// CHECK:STDOUT:   %tuple.type.e55: type = tuple_type (%i32, %i32) [concrete]
// CHECK:STDOUT:   %pattern_type.394: type = pattern_type %tuple.type.e55 [concrete]
// CHECK:STDOUT:   %t.patt: %pattern_type.394 = ref_binding_pattern t [concrete]
// CHECK:STDOUT:   %t.var_patt: %pattern_type.394 = var_pattern %t.patt [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %int_2.ecc: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %tuple.type.f94: type = tuple_type (Core.IntLiteral, Core.IntLiteral) [concrete]
// CHECK:STDOUT:   %tuple.ad8: %tuple.type.f94 = tuple_value (%int_1.5b8, %int_2.ecc) [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %To: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
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
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.9f3: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.3cb: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_2.295: %i32 = int_value 2 [concrete]
// CHECK:STDOUT:   %tuple.102: %tuple.type.e55 = tuple_value (%int_1.0c6, %int_2.295) [concrete]
// CHECK:STDOUT:   %b.patt: %pattern_type.6b6 = value_binding_pattern b [concrete]
// CHECK:STDOUT:   %tuple.type.94b: type = tuple_type (Core.IntLiteral, %i32) [concrete]
// CHECK:STDOUT:   %pattern_type.106: type = pattern_type %tuple.type.94b [concrete]
// CHECK:STDOUT:   %.e63: %pattern_type.106 = tuple_pattern (@F.%expr_patt, %b.patt) [concrete]
// CHECK:STDOUT:   %EqWith.type.8ee: type = facet_type <@EqWith, @EqWith(%i32)> [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.f7de31.2: type = facet_type <@ImplicitAs, @ImplicitAs(%Int.67af24.1)> [symbolic]
// CHECK:STDOUT:   %T.4e6: %ImplicitAs.type.f7de31.2 = symbolic_binding T, 1 [symbolic]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.type.8af025.1: type = fn_type @T.as_type.as.EqWith.impl.Equal.1, @T.as_type.as.EqWith.impl(%N, %T.4e6) [symbolic]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.c477d6.1: %T.as_type.as.EqWith.impl.Equal.type.8af025.1 = struct_value () [symbolic]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.type.8af025.2: type = fn_type @T.as_type.as.EqWith.impl.Equal.2, @T.as_type.as.EqWith.impl(%N, %T.4e6) [symbolic]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.c477d6.2: %T.as_type.as.EqWith.impl.Equal.type.8af025.2 = struct_value () [symbolic]
// CHECK:STDOUT:   %EqWith.impl_witness.bde: <witness> = impl_witness imports.%EqWith.impl_witness_table.532, @T.as_type.as.EqWith.impl(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.1: type = fn_type @T.as_type.as.EqWith.impl.Equal.2, @T.as_type.as.EqWith.impl(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.57b831.1: %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.1 = struct_value () [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.2: type = fn_type @T.as_type.as.EqWith.impl.Equal.1, @T.as_type.as.EqWith.impl(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.57b831.2: %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.2 = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.eb2: %EqWith.type.8ee = facet_value Core.IntLiteral, (%EqWith.impl_witness.bde) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.a21: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%i32, %EqWith.facet.eb2) [concrete]
// CHECK:STDOUT:   %.025: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.a21, %EqWith.facet.eb2 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound.29e975.1: <bound method> = bound_method %int_1.5b8, %T.as_type.as.EqWith.impl.Equal.57b831.2 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.1: <specific function> = specific_function %T.as_type.as.EqWith.impl.Equal.57b831.2, @T.as_type.as.EqWith.impl.Equal.1(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %bound_method.42af37.1: <bound method> = bound_method %int_1.5b8, %T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.1 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound.29e975.2: <bound method> = bound_method %int_1.5b8, %T.as_type.as.EqWith.impl.Equal.57b831.1 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.2: <specific function> = specific_function %T.as_type.as.EqWith.impl.Equal.57b831.1, @T.as_type.as.EqWith.impl.Equal.2(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %bound_method.42af37.2: <bound method> = bound_method %int_1.5b8, %T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.2 [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet: %Copy.type = facet_value %i32, (%Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.381: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet) [concrete]
// CHECK:STDOUT:   %.737: type = fn_type_with_self_type %Copy.WithSelf.Op.type.381, %Copy.facet [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.3: type = fn_type @Destroy.Op.loc8_3.3 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.3: %Destroy.Op.type.1d8f74.3 = struct_value () [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.6e0: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_0.3c0: %i32 = int_value 0 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.a9a: @T.as_type.as.EqWith.impl.%T.as_type.as.EqWith.impl.Equal.type.2 (%T.as_type.as.EqWith.impl.Equal.type.8af025.1) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @T.as_type.as.EqWith.impl.%T.as_type.as.EqWith.impl.Equal.2 (constants.%T.as_type.as.EqWith.impl.Equal.c477d6.1)]
// CHECK:STDOUT:   %Core.import_ref.712 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.532 = impl_witness_table (%Core.import_ref.a9a, %Core.import_ref.712), @T.as_type.as.EqWith.impl [concrete]
// CHECK:STDOUT:   %Core.Equal.970: @T.as_type.as.EqWith.impl.%T.as_type.as.EqWith.impl.Equal.type.1 (%T.as_type.as.EqWith.impl.Equal.type.8af025.2) = import_ref Core//prelude/types/int, Equal, loaded [symbolic = @T.as_type.as.EqWith.impl.%T.as_type.as.EqWith.impl.Equal.1 (constants.%T.as_type.as.EqWith.impl.Equal.c477d6.2)]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %F.decl: %F.type = fn_decl @F [concrete = constants.%F] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc7 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc7: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc7: Core.Form = init_form %i32.loc7 [concrete = constants.%.795f]
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param0
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @F() -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %t.var: ref %tuple.type.e55 = var_storage %t.var_patt
// CHECK:STDOUT:   %int_1.loc8: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:   %.loc8_28.1: %tuple.type.f94 = tuple_literal (%int_1.loc8, %int_2) [concrete = constants.%tuple.ad8]
// CHECK:STDOUT:   %impl.elem0.loc8_28.1: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc8_28.1: <bound method> = bound_method %int_1.loc8, %impl.elem0.loc8_28.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc8_28.1: <specific function> = specific_function %impl.elem0.loc8_28.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc8_28.2: <bound method> = bound_method %int_1.loc8, %specific_fn.loc8_28.1 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc8_28.1: init %i32 = call %bound_method.loc8_28.2(%int_1.loc8) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc8_28.2: init %i32 = converted %int_1.loc8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc8_28.1 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %tuple.elem0.loc8: ref %i32 = tuple_access %t.var, element0
// CHECK:STDOUT:   %.loc8_28.3: init %i32 to %tuple.elem0.loc8 = in_place_init %.loc8_28.2 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %impl.elem0.loc8_28.2: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc8_28.3: <bound method> = bound_method %int_2, %impl.elem0.loc8_28.2 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.9f3]
// CHECK:STDOUT:   %specific_fn.loc8_28.2: <specific function> = specific_function %impl.elem0.loc8_28.2, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc8_28.4: <bound method> = bound_method %int_2, %specific_fn.loc8_28.2 [concrete = constants.%bound_method.3cb]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc8_28.2: init %i32 = call %bound_method.loc8_28.4(%int_2) [concrete = constants.%int_2.295]
// CHECK:STDOUT:   %.loc8_28.4: init %i32 = converted %int_2, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc8_28.2 [concrete = constants.%int_2.295]
// CHECK:STDOUT:   %tuple.elem1.loc8: ref %i32 = tuple_access %t.var, element1
// CHECK:STDOUT:   %.loc8_28.5: init %i32 to %tuple.elem1.loc8 = in_place_init %.loc8_28.4 [concrete = constants.%int_2.295]
// CHECK:STDOUT:   %.loc8_28.6: init %tuple.type.e55 to %t.var = tuple_init (%.loc8_28.3, %.loc8_28.5) [concrete = constants.%tuple.102]
// CHECK:STDOUT:   %.loc8_3: init %tuple.type.e55 = converted %.loc8_28.1, %.loc8_28.6 [concrete = constants.%tuple.102]
// CHECK:STDOUT:   assign %t.var, %.loc8_3
// CHECK:STDOUT:   %.loc8_19.1: type = splice_block %.loc8_19.3 [concrete = constants.%tuple.type.e55] {
// CHECK:STDOUT:     %i32.loc8_11: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %i32.loc8_16: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc8_19.2: %tuple.type.24b = tuple_literal (%i32.loc8_11, %i32.loc8_16) [concrete = constants.%tuple.b59]
// CHECK:STDOUT:     %.loc8_19.3: type = converted %.loc8_19.2, constants.%tuple.type.e55 [concrete = constants.%tuple.type.e55]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %t: ref %tuple.type.e55 = wrapper_binding t, %t.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %t.patt: %pattern_type.394 = ref_binding_pattern t [concrete = constants.%t.patt]
// CHECK:STDOUT:     %t.var_patt: %pattern_type.394 = var_pattern %t.patt [concrete = constants.%t.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %t.ref: ref %tuple.type.e55 = name_ref t, %t
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt: %pattern_type.dc0 = expr_pattern %int_1.loc10 in [concrete] {
// CHECK:STDOUT:       %int_1.loc10: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %b.patt: %pattern_type.6b6 = value_binding_pattern b [concrete = constants.%b.patt]
// CHECK:STDOUT:     %.loc10_20: %pattern_type.106 = tuple_pattern (%expr_patt, %b.patt) [concrete = constants.%.e63]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %tuple.elem0.loc9: ref %i32 = tuple_access %t.ref, element0
// CHECK:STDOUT:   %int_1.loc10: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc10_22: %.025 = impl_witness_access constants.%EqWith.impl_witness.bde, element0 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.57b831.2]
// CHECK:STDOUT:   %bound_method.loc10_22.1: <bound method> = bound_method %int_1.loc10, %impl.elem0.loc10_22 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.bound.29e975.1]
// CHECK:STDOUT:   %specific_fn.loc10_22: <specific function> = specific_function %impl.elem0.loc10_22, @T.as_type.as.EqWith.impl.Equal.1(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.1]
// CHECK:STDOUT:   %bound_method.loc10_22.2: <bound method> = bound_method %int_1.loc10, %specific_fn.loc10_22 [concrete = constants.%bound_method.42af37.1]
// CHECK:STDOUT:   %.loc9_10.1: %i32 = acquire_value %tuple.elem0.loc9
// CHECK:STDOUT:   %.loc10_22.1: %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.1 = specific_constant imports.%Core.Equal.970, @T.as_type.as.EqWith.impl(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.57b831.1]
// CHECK:STDOUT:   %Equal.ref: %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.1 = name_ref Equal, %.loc10_22.1 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.57b831.1]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound: <bound method> = bound_method %int_1.loc10, %Equal.ref [concrete = constants.%T.as_type.as.EqWith.impl.Equal.bound.29e975.2]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.specific_fn: <specific function> = specific_function %Equal.ref, @T.as_type.as.EqWith.impl.Equal.2(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.2]
// CHECK:STDOUT:   %bound_method.loc10_22.3: <bound method> = bound_method %int_1.loc10, %T.as_type.as.EqWith.impl.Equal.specific_fn [concrete = constants.%bound_method.42af37.2]
// CHECK:STDOUT:   %impl.elem0.loc10_11: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc10_11.1: <bound method> = bound_method %int_1.loc10, %impl.elem0.loc10_11 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc10_11: <specific function> = specific_function %impl.elem0.loc10_11, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc10_11.2: <bound method> = bound_method %int_1.loc10, %specific_fn.loc10_11 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc10: init %i32 = call %bound_method.loc10_11.2(%int_1.loc10) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc10_11.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc10 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc10_11.2: %i32 = converted %int_1.loc10, %.loc10_11.1 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.call: init bool = call %bound_method.loc10_22.3(%.loc10_11.2, %.loc9_10.1)
// CHECK:STDOUT:   %.loc10_22.2: bool = value_of_initializer %T.as_type.as.EqWith.impl.Equal.call
// CHECK:STDOUT:   %.loc10_22.3: bool = converted %T.as_type.as.EqWith.impl.Equal.call, %.loc10_22.2
// CHECK:STDOUT:   if %.loc10_22.3 br !match.case.then else br !match.case.else
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then:
// CHECK:STDOUT:   %tuple.elem1.loc9: ref %i32 = tuple_access %t.ref, element1
// CHECK:STDOUT:   %.loc9_10.2: %i32 = acquire_value %tuple.elem1.loc9
// CHECK:STDOUT:   %i32.loc10: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %b: %i32 = wrapper_binding b, %.loc9_10.2
// CHECK:STDOUT:   %b.ref: %i32 = name_ref b, %b
// CHECK:STDOUT:   %impl.elem0.loc10_34: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc10_34.1: <bound method> = bound_method %b.ref, %impl.elem0.loc10_34
// CHECK:STDOUT:   %specific_fn.loc10_34: <specific function> = specific_function %impl.elem0.loc10_34, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc10_34.2: <bound method> = bound_method %b.ref, %specific_fn.loc10_34
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc10_34.2(%b.ref)
// CHECK:STDOUT:   %Destroy.Op.bound.loc8_3.1: <bound method> = bound_method %t.var, constants.%Destroy.Op.1a2547.3
// CHECK:STDOUT:   %Destroy.Op.call.loc8_3.1: init %empty_tuple.type = call %Destroy.Op.bound.loc8_3.1(%t.var)
// CHECK:STDOUT:   return %Int.as.Copy.impl.Op.call
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else:
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc11: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc11_26.1: <bound method> = bound_method %int_0, %impl.elem0.loc11 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc11: <specific function> = specific_function %impl.elem0.loc11, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc11_26.2: <bound method> = bound_method %int_0, %specific_fn.loc11 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc11: init %i32 = call %bound_method.loc11_26.2(%int_0) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc11: init %i32 = converted %int_0, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc11 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %Destroy.Op.bound.loc8_3.2: <bound method> = bound_method %t.var, constants.%Destroy.Op.1a2547.3
// CHECK:STDOUT:   %Destroy.Op.call.loc8_3.2: init %empty_tuple.type = call %Destroy.Op.bound.loc8_3.2(%t.var)
// CHECK:STDOUT:   return %.loc11
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc8_3.1(%self.param: ref %i32.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc8_3.2(%self.param: ref %i32) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc8_3.3(%self.param: ref %tuple.type.e55) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
