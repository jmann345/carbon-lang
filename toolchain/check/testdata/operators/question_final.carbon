// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/operators/question_final.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/operators/question_final.carbon

// The W-072 dissolution probes, positive half (fork/w072/plan.md §3, W72a;
// probes P-1..P-3 and P-8): under the ratified doc's own `final impl`
// spelling (docs/design/error_handling.md `Try` impl sketches;
// docs/design/generics/details.md, "`final` impl declarations"), impl
// lookup under a SYMBOLIC query may apply the impl's `where` rewrites
// (eval_inst.cpp `ImplWitness` arm via `EvalLookupSingleFinalWitness`), so
// the `?` continue value on a symbolic choice-specific operand binds `: T`
// — the shape the non-final idiom cannot spell BY UPSTREAM DESIGN
// (specialization soundness; the permanent negative pins are
// question.carbon's generic.carbon subfile and upstream's
// impl/lookup/specialization_with_symbolic_rewrite.carbon). Impl bodies
// keep the match-reconstruct + `Diverge` idiom (fork/b1/plan.md §2.6): the
// in-body path is NOT expected to change under `final` (plan §2.2,
// correctness F-2); the in-body observation probe is
// fail_question_final.carbon's fail_inbody_recursive_branch.carbon.

// --- thread.carbon
library "[[@TEST_NAME]]";

choice MyResult(T: type, E: type) {
  Ok(v: T),
  Err(e: E)
}

// Returns a value of any type by never returning — the unreachable
// trailing-return helper for generic match-reconstruct bodies
// (fork/b1/plan.md §2.6, dated correction). The explicit generic type
// param + self-recursion is the arbiter-verified
// function/generic/deduce.carbon `ExplicitGenericParam` shape.
fn Diverge(generic T2: type) -> T2 { return Diverge(T2); }

// The doc's sanctioned spelling: `final` exempts this impl from
// specialization, which is exactly what licenses impl lookup to apply
// `.ContinueType = T and .BreakType = E` under a symbolic query
// (details.md; proposals p000983/p002868/p005337).
final impl forall [T: type, E: type] MyResult(T, E) as Core.Try
    where .ContinueType = T and .BreakType = E {
  fn Branch(self) -> Core.ControlFlow(T, E) {
    match (self) {
      case .Ok(v: T) => { return Core.ControlFlow(T, E).Continue(v); }
      case .Err(e: E) => { return Core.ControlFlow(T, E).Break(e); }
    }
    // Unreachable-terminator idiom (fork/b1/plan.md §2.6): in-body
    // lookups already treated the being-defined impl as final
    // (impl_lookup.cpp `TreatImplAsFinal`), so the B1b in-body
    // non-collapse is expected unchanged by the `final` modifier — the
    // observation probe lives in fail_question_final.carbon.
    return Diverge(Core.ControlFlow(T, E));
  }
  fn FromBreak(e: E) -> Self { return MyResult(T, E).Err(e); }
}

// An explicitly `T2`-typed sink (explicit generic argument, NOT deduced
// from the value): P-2's pass-as-`T` pin — a deduced sink would accept the
// unreduced projection too (the P-4 wart shape), so deduction here would
// not distinguish the outcomes.
// CHECK:STDERR: thread.carbon:[[@LINE+4]]:30: warning: binding `x` unused [UnusedBinding]
// CHECK:STDERR: fn Consume(generic T2: type, x: T2) {}
// CHECK:STDERR:                              ^~~~~
// CHECK:STDERR:
fn Consume(generic T2: type, x: T2) {}

//@dump-sem-ir-begin
// P-1: the core prediction — the continue value of `mr?` on the SYMBOLIC
// operand `mr: MyResult(T, E)` binds `: T`, because the final impl's
// rewrite reduces the carrier to `Core.ControlFlow(T, E)` at check time.
// P-2: the bound value passes where `T` is expected (explicit-argument
// sink) and wraps back through `Ok` — the full threading round trip.
fn Thread[T: type, E: type](mr: MyResult(T, E)) -> MyResult(T, E) {
  let v: T = mr?;
  Consume(T, v);
  return MyResult(T, E).Ok(v);
}
//@dump-sem-ir-end

// --- mixed.carbon
library "[[@TEST_NAME]]";

choice MyResult(T: type, E: type) {
  Ok(v: T),
  Err(e: E)
}

// Returns a value of any type by never returning — the unreachable
// trailing-return helper for generic match-reconstruct bodies
// (fork/b1/plan.md §2.6, dated correction). The explicit generic type
// param + self-recursion is the arbiter-verified
// function/generic/deduce.carbon `ExplicitGenericParam` shape.
fn Diverge(generic T2: type) -> T2 { return Diverge(T2); }

final impl forall [T: type, E: type] MyResult(T, E) as Core.Try
    where .ContinueType = T and .BreakType = E {
  fn Branch(self) -> Core.ControlFlow(T, E) {
    match (self) {
      case .Ok(v: T) => { return Core.ControlFlow(T, E).Continue(v); }
      case .Err(e: E) => { return Core.ControlFlow(T, E).Break(e); }
    }
    // Unreachable-terminator idiom (fork/b1/plan.md §2.6).
    return Diverge(Core.ControlFlow(T, E));
  }
  fn FromBreak(e: E) -> Self { return MyResult(T, E).Err(e); }
}

//@dump-sem-ir-begin
// P-3: the MIXED specific `MyResult(T, i32)` — one symbolic and one
// concrete argument. Deduction against the final impl must produce the
// partially-concrete specific (`T`, `i32`); operand and return are the
// SAME specific so the break path's `FromBreak` ImplicitAs conversion
// stays aligned projection-for-projection (the `PropagateChoice`
// configuration, now with the continue value threaded rather than sunk).
// Falsifier: deduction failure on the partially-concrete query
// (fork/w072/plan.md §2.4 step 2).
fn ThreadMixed[T: type](mr: MyResult(T, i32)) -> MyResult(T, i32) {
  let v: T = mr?;
  return MyResult(T, i32).Ok(v);
}
//@dump-sem-ir-end

// --- lib.carbon
library "[[@TEST_NAME]]";

choice MyResult(T: type, E: type) {
  Ok(v: T),
  Err(e: E)
}

// Returns a value of any type by never returning — the unreachable
// trailing-return helper for generic match-reconstruct bodies
// (fork/b1/plan.md §2.6, dated correction). The explicit generic type
// param + self-recursion is the arbiter-verified
// function/generic/deduce.carbon `ExplicitGenericParam` shape.
fn Diverge(generic T2: type) -> T2 { return Diverge(T2); }

// P-8 setup: choice + final impl in ONE file (the same-file requirement,
// impl_validation.cpp `FinalImplInvalidFile`), consumed from the importing
// file below.
final impl forall [T: type, E: type] MyResult(T, E) as Core.Try
    where .ContinueType = T and .BreakType = E {
  fn Branch(self) -> Core.ControlFlow(T, E) {
    match (self) {
      case .Ok(v: T) => { return Core.ControlFlow(T, E).Continue(v); }
      case .Err(e: E) => { return Core.ControlFlow(T, E).Break(e); }
    }
    // Unreachable-terminator idiom (fork/b1/plan.md §2.6).
    return Diverge(Core.ControlFlow(T, E));
  }
  fn FromBreak(e: E) -> Self { return MyResult(T, E).Err(e); }
}

// --- use.carbon
library "[[@TEST_NAME]]";

import library "lib";

//@dump-sem-ir-begin
// P-8: import parity — the final impl's reduction must survive import
// (the impl/lookup/import_final.carbon precedent; the W-069 family is the
// named falsifier, fork/w072/plan.md §2.4 step 2). Same threading shape
// as thread.carbon, operand type imported.
fn ThreadImported[T: type, E: type](mr: MyResult(T, E)) -> MyResult(T, E) {
  let v: T = mr?;
  return MyResult(T, E).Ok(v);
}
//@dump-sem-ir-end

// CHECK:STDOUT: --- thread.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %.Self.frozen.197: %type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %pattern_type.98f: type = pattern_type type [concrete]
// CHECK:STDOUT:   %T.patt.d47: %pattern_type.98f = symbolic_binding_pattern T, 0 [symbolic]
// CHECK:STDOUT:   %T.67d: type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %E.patt: %pattern_type.98f = symbolic_binding_pattern E, 1 [symbolic]
// CHECK:STDOUT:   %E: type = symbolic_binding E, 1 [symbolic]
// CHECK:STDOUT:   %MyResult.type: type = generic_class_type @MyResult [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %MyResult.generic: %MyResult.type = struct_value () [concrete]
// CHECK:STDOUT:   %MyResult: type = class_type @MyResult, @MyResult(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %pattern_type.51d1c4.1: type = pattern_type %T.67d [symbolic]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %u1: type = class_type @UInt, @UInt(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %require_complete.9443dd.1: <witness> = require_complete_type %T.67d [symbolic]
// CHECK:STDOUT:   %tuple.type.026b76.1: type = tuple_type (%T.67d) [symbolic]
// CHECK:STDOUT:   %require_complete.441886.1: <witness> = require_complete_type %E [symbolic]
// CHECK:STDOUT:   %tuple.type.17989b.1: type = tuple_type (%E) [symbolic]
// CHECK:STDOUT:   %.6c7: Core.Form = init_form %MyResult [symbolic]
// CHECK:STDOUT:   %pattern_type.6db: type = pattern_type %MyResult [symbolic]
// CHECK:STDOUT:   %return.param_patt.296: %pattern_type.6db = out_param_pattern [symbolic]
// CHECK:STDOUT:   %return.patt.971e: %pattern_type.6db = return_slot_pattern %return.param_patt.296, %MyResult [symbolic]
// CHECK:STDOUT:   %MyResult.Ok.type: type = fn_type @MyResult.Ok, @MyResult(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %MyResult.Ok: %MyResult.Ok.type = struct_value () [symbolic]
// CHECK:STDOUT:   %require_complete.090: <witness> = require_complete_type %MyResult [symbolic]
// CHECK:STDOUT:   %ImplicitAs.type.ca1: type = facet_type <@ImplicitAs, @ImplicitAs(%u1)> [concrete]
// CHECK:STDOUT:   %To.fe9: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.b68(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.170: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.f4c: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.f01, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet: %ImplicitAs.type.ca1 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.f4c) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.77c: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%u1, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.e74: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.77c, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %bound_method.d7a: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_1.233: %u1 = int_value 1 [concrete]
// CHECK:STDOUT:   %Try.type: type = facet_type <@Try> [concrete]
// CHECK:STDOUT:   %Try.impl_witness: <witness> = impl_witness @MyResult.as.Try.impl.%Try.impl_witness_table, @MyResult.as.Try.impl(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %ControlFlow.eda317.2: type = class_type @ControlFlow, @ControlFlow(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %MyResult.as.Try.impl.Branch.type: type = fn_type @MyResult.as.Try.impl.Branch, @MyResult.as.Try.impl(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %MyResult.as.Try.impl.Branch: %MyResult.as.Try.impl.Branch.type = struct_value () [symbolic]
// CHECK:STDOUT:   %MyResult.as.Try.impl.FromBreak.type: type = fn_type @MyResult.as.Try.impl.FromBreak, @MyResult.as.Try.impl(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %MyResult.as.Try.impl.FromBreak: %MyResult.as.Try.impl.FromBreak.type = struct_value () [symbolic]
// CHECK:STDOUT:   %Try.facet: %Try.type = facet_value %MyResult, (%Try.impl_witness) [symbolic]
// CHECK:STDOUT:   %Try.WithSelf.Branch.type.415: type = fn_type @Try.WithSelf.Branch, @Try.WithSelf(%Try.facet) [symbolic]
// CHECK:STDOUT:   %Try.WithSelf.FromBreak.type.d1a: type = fn_type @Try.WithSelf.FromBreak, @Try.WithSelf(%Try.facet) [symbolic]
// CHECK:STDOUT:   %.bef625.2: type = custom_layout_type {size=0, align=0, .Continue@0: %tuple.type.026b76.1, .Break@0: %tuple.type.17989b.1} [symbolic]
// CHECK:STDOUT:   %require_complete.a4d899.2: <witness> = require_complete_type %ControlFlow.eda317.2 [symbolic]
// CHECK:STDOUT:   %v.patt.291: %pattern_type.51d1c4.1 = value_binding_pattern v [symbolic]
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
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.specific_fn.6b6: <specific function> = specific_function %UInt.as.EqWith.impl.Equal.ba4, @UInt.as.EqWith.impl.Equal.1(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound.22c: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %bound_method.a82: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
// CHECK:STDOUT:   %Consume.type: type = fn_type @Consume [concrete]
// CHECK:STDOUT:   %Consume: %Consume.type = struct_value () [concrete]
// CHECK:STDOUT:   %mr.param_patt: %pattern_type.6db = value_param_pattern [symbolic]
// CHECK:STDOUT:   %mr.patt: %pattern_type.6db = at_binding_pattern mr, %mr.param_patt [symbolic]
// CHECK:STDOUT:   %Thread.type: type = fn_type @Thread [concrete]
// CHECK:STDOUT:   %Thread: %Thread.type = struct_value () [concrete]
// CHECK:STDOUT:   %.bb0: type = fn_type_with_self_type %Try.WithSelf.Branch.type.415, %Try.facet [symbolic]
// CHECK:STDOUT:   %MyResult.as.Try.impl.Branch.specific_fn: <specific function> = specific_function %MyResult.as.Try.impl.Branch, @MyResult.as.Try.impl.Branch(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %.226: type = fn_type_with_self_type %Try.WithSelf.FromBreak.type.d1a, %Try.facet [symbolic]
// CHECK:STDOUT:   %MyResult.as.Try.impl.FromBreak.specific_fn: <specific function> = specific_function %MyResult.as.Try.impl.FromBreak, @MyResult.as.Try.impl.FromBreak(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %Destroy.type: type = facet_type <@Destroy> [concrete]
// CHECK:STDOUT:   %Destroy.lookup_impl_witness: <witness> = lookup_impl_witness %ControlFlow.eda317.2, @Destroy [symbolic]
// CHECK:STDOUT:   %Destroy.facet: %Destroy.type = facet_value %ControlFlow.eda317.2, (%Destroy.lookup_impl_witness) [symbolic]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.16c: type = fn_type @Destroy.WithSelf.Op, @Destroy.WithSelf(%Destroy.facet) [symbolic]
// CHECK:STDOUT:   %.9db: type = fn_type_with_self_type %Destroy.WithSelf.Op.type.16c, %Destroy.facet [symbolic]
// CHECK:STDOUT:   %impl.elem0.ae8: %.9db = impl_witness_access %Destroy.lookup_impl_witness, element0 [symbolic]
// CHECK:STDOUT:   %specific_impl_fn.8f1: <specific function> = specific_impl_function %impl.elem0.ae8, @Destroy.WithSelf.Op(%Destroy.facet) [symbolic]
// CHECK:STDOUT:   %Consume.specific_fn: <specific function> = specific_function %Consume, @Consume(%T.67d) [symbolic]
// CHECK:STDOUT:   %MyResult.Ok.specific_fn: <specific function> = specific_function %MyResult.Ok, @MyResult.Ok(%T.67d, %E) [symbolic]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.aa5: @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.170)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.f01 = impl_witness_table (%Core.import_ref.aa5), @Core.IntLiteral.as.ImplicitAs.impl.b68 [concrete]
// CHECK:STDOUT:   %Core.import_ref.b92: @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal.type (%UInt.as.EqWith.impl.Equal.type.544) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal (constants.%UInt.as.EqWith.impl.Equal.c67)]
// CHECK:STDOUT:   %Core.import_ref.b44 = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.166 = impl_witness_table (%Core.import_ref.b92, %Core.import_ref.b44), @UInt.as.EqWith.impl.f13 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %MyResult.Ok.decl: @MyResult.%MyResult.Ok.type (%MyResult.Ok.type) = fn_decl @MyResult.Ok [symbolic = @MyResult.%MyResult.Ok (constants.%MyResult.Ok)] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Thread.decl: %Thread.type = fn_decl @Thread [concrete = constants.%Thread] {
// CHECK:STDOUT:     %T.patt.loc48_12.1: %pattern_type.98f = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc48_12.2 (constants.%T.patt.d47)]
// CHECK:STDOUT:     %E.patt.loc48_21.1: %pattern_type.98f = symbolic_binding_pattern E, 1 [symbolic = %E.patt.loc48_21.2 (constants.%E.patt)]
// CHECK:STDOUT:     %mr.param_patt.loc48_31.1: @Thread.%pattern_type.loc48 (%pattern_type.6db) = value_param_pattern [symbolic = %mr.param_patt.loc48_31.2 (constants.%mr.param_patt)]
// CHECK:STDOUT:     %mr.patt.loc48_31.1: @Thread.%pattern_type.loc48 (%pattern_type.6db) = at_binding_pattern mr, %mr.param_patt.loc48_31.1 [symbolic = %mr.patt.loc48_31.2 (constants.%mr.patt)]
// CHECK:STDOUT:     %return.param_patt.loc48_65.1: @Thread.%pattern_type.loc48 (%pattern_type.6db) = out_param_pattern [symbolic = %return.param_patt.loc48_65.2 (constants.%return.param_patt.296)]
// CHECK:STDOUT:     %return.patt.loc48_49.1: @Thread.%pattern_type.loc48 (%pattern_type.6db) = return_slot_pattern %return.param_patt.loc48_65.1, %MyResult.loc48_65 [symbolic = %return.patt.loc48_49.2 (constants.%return.patt.971e)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %MyResult.ref.loc48_52: %MyResult.type = name_ref MyResult, file.%MyResult.decl [concrete = constants.%MyResult.generic]
// CHECK:STDOUT:     %T.ref.loc48_61: type = name_ref T, %T.loc48_12.2 [symbolic = %T.loc48_12.1 (constants.%T.67d)]
// CHECK:STDOUT:     %E.ref.loc48_64: type = name_ref E, %E.loc48_21.2 [symbolic = %E.loc48_21.1 (constants.%E)]
// CHECK:STDOUT:     %MyResult.loc48_65: type = class_type @MyResult, @MyResult(constants.%T.67d, constants.%E) [symbolic = %MyResult.loc48_46.1 (constants.%MyResult)]
// CHECK:STDOUT:     %.loc48_65.4: Core.Form = init_form %MyResult.loc48_65 [symbolic = %.loc48_65.3 (constants.%.6c7)]
// CHECK:STDOUT:     %.loc48_14.1: type = splice_block %.loc48_14.2 [concrete = type] {
// CHECK:STDOUT:       %.Self.frozen.loc48_12: %type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen.197]
// CHECK:STDOUT:       %.loc48_14.2: type = type_literal type [concrete = type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc48_12.2: type = symbolic_binding T, 0 [symbolic = %T.loc48_12.1 (constants.%T.67d)]
// CHECK:STDOUT:     %.loc48_23.1: type = splice_block %.loc48_23.2 [concrete = type] {
// CHECK:STDOUT:       %.Self.frozen.loc48_21: %type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen.197]
// CHECK:STDOUT:       %.loc48_23.2: type = type_literal type [concrete = type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %E.loc48_21.2: type = symbolic_binding E, 1 [symbolic = %E.loc48_21.1 (constants.%E)]
// CHECK:STDOUT:     %mr.param: @Thread.%MyResult.loc48_46.1 (%MyResult) = value_param call_param0
// CHECK:STDOUT:     %.loc48_46: type = splice_block %MyResult.loc48_46.2 [symbolic = %MyResult.loc48_46.1 (constants.%MyResult)] {
// CHECK:STDOUT:       %MyResult.ref.loc48_33: %MyResult.type = name_ref MyResult, file.%MyResult.decl [concrete = constants.%MyResult.generic]
// CHECK:STDOUT:       %T.ref.loc48_42: type = name_ref T, %T.loc48_12.2 [symbolic = %T.loc48_12.1 (constants.%T.67d)]
// CHECK:STDOUT:       %E.ref.loc48_45: type = name_ref E, %E.loc48_21.2 [symbolic = %E.loc48_21.1 (constants.%E)]
// CHECK:STDOUT:       %MyResult.loc48_46.2: type = class_type @MyResult, @MyResult(constants.%T.67d, constants.%E) [symbolic = %MyResult.loc48_46.1 (constants.%MyResult)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %mr: @Thread.%MyResult.loc48_46.1 (%MyResult) = wrapper_binding mr, %mr.param
// CHECK:STDOUT:     %return.param: ref @Thread.%MyResult.loc48_46.1 (%MyResult) = out_param call_param1
// CHECK:STDOUT:     %return: ref @Thread.%MyResult.loc48_46.1 (%MyResult) = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @Thread(%T.loc48_12.2: type, %E.loc48_21.2: type) {
// CHECK:STDOUT:   %T.patt.loc48_12.2: %pattern_type.98f = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc48_12.2 (constants.%T.patt.d47)]
// CHECK:STDOUT:   %T.loc48_12.1: type = symbolic_binding T, 0 [symbolic = %T.loc48_12.1 (constants.%T.67d)]
// CHECK:STDOUT:   %E.patt.loc48_21.2: %pattern_type.98f = symbolic_binding_pattern E, 1 [symbolic = %E.patt.loc48_21.2 (constants.%E.patt)]
// CHECK:STDOUT:   %E.loc48_21.1: type = symbolic_binding E, 1 [symbolic = %E.loc48_21.1 (constants.%E)]
// CHECK:STDOUT:   %MyResult.loc48_46.1: type = class_type @MyResult, @MyResult(%T.loc48_12.1, %E.loc48_21.1) [symbolic = %MyResult.loc48_46.1 (constants.%MyResult)]
// CHECK:STDOUT:   %pattern_type.loc48: type = pattern_type %MyResult.loc48_46.1 [symbolic = %pattern_type.loc48 (constants.%pattern_type.6db)]
// CHECK:STDOUT:   %mr.param_patt.loc48_31.2: @Thread.%pattern_type.loc48 (%pattern_type.6db) = value_param_pattern [symbolic = %mr.param_patt.loc48_31.2 (constants.%mr.param_patt)]
// CHECK:STDOUT:   %mr.patt.loc48_31.2: @Thread.%pattern_type.loc48 (%pattern_type.6db) = at_binding_pattern mr, %mr.param_patt.loc48_31.2 [symbolic = %mr.patt.loc48_31.2 (constants.%mr.patt)]
// CHECK:STDOUT:   %.loc48_65.3: Core.Form = init_form %MyResult.loc48_46.1 [symbolic = %.loc48_65.3 (constants.%.6c7)]
// CHECK:STDOUT:   %return.param_patt.loc48_65.2: @Thread.%pattern_type.loc48 (%pattern_type.6db) = out_param_pattern [symbolic = %return.param_patt.loc48_65.2 (constants.%return.param_patt.296)]
// CHECK:STDOUT:   %return.patt.loc48_49.2: @Thread.%pattern_type.loc48 (%pattern_type.6db) = return_slot_pattern %return.param_patt.loc48_65.2, %MyResult.loc48_46.1 [symbolic = %return.patt.loc48_49.2 (constants.%return.patt.971e)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc48: <witness> = require_complete_type %MyResult.loc48_46.1 [symbolic = %require_complete.loc48 (constants.%require_complete.090)]
// CHECK:STDOUT:   %require_complete.loc49_10: <witness> = require_complete_type %T.loc48_12.1 [symbolic = %require_complete.loc49_10 (constants.%require_complete.9443dd.1)]
// CHECK:STDOUT:   %pattern_type.loc49: type = pattern_type %T.loc48_12.1 [symbolic = %pattern_type.loc49 (constants.%pattern_type.51d1c4.1)]
// CHECK:STDOUT:   %v.patt.loc49_8.2: @Thread.%pattern_type.loc49 (%pattern_type.51d1c4.1) = value_binding_pattern v [symbolic = %v.patt.loc49_8.2 (constants.%v.patt.291)]
// CHECK:STDOUT:   %Try.impl_witness: <witness> = impl_witness @MyResult.as.Try.impl.%Try.impl_witness_table, @MyResult.as.Try.impl(%T.loc48_12.1, %E.loc48_21.1) [symbolic = %Try.impl_witness (constants.%Try.impl_witness)]
// CHECK:STDOUT:   %Try.facet.loc49_16.2: %Try.type = facet_value %MyResult.loc48_46.1, (%Try.impl_witness) [symbolic = %Try.facet.loc49_16.2 (constants.%Try.facet)]
// CHECK:STDOUT:   %Try.WithSelf.Branch.type: type = fn_type @Try.WithSelf.Branch, @Try.WithSelf(%Try.facet.loc49_16.2) [symbolic = %Try.WithSelf.Branch.type (constants.%Try.WithSelf.Branch.type.415)]
// CHECK:STDOUT:   %.loc49_16.20: type = fn_type_with_self_type %Try.WithSelf.Branch.type, %Try.facet.loc49_16.2 [symbolic = %.loc49_16.20 (constants.%.bb0)]
// CHECK:STDOUT:   %MyResult.as.Try.impl.Branch.type: type = fn_type @MyResult.as.Try.impl.Branch, @MyResult.as.Try.impl(%T.loc48_12.1, %E.loc48_21.1) [symbolic = %MyResult.as.Try.impl.Branch.type (constants.%MyResult.as.Try.impl.Branch.type)]
// CHECK:STDOUT:   %MyResult.as.Try.impl.Branch: @Thread.%MyResult.as.Try.impl.Branch.type (%MyResult.as.Try.impl.Branch.type) = struct_value () [symbolic = %MyResult.as.Try.impl.Branch (constants.%MyResult.as.Try.impl.Branch)]
// CHECK:STDOUT:   %MyResult.as.Try.impl.Branch.specific_fn: <specific function> = specific_function %MyResult.as.Try.impl.Branch, @MyResult.as.Try.impl.Branch(%T.loc48_12.1, %E.loc48_21.1) [symbolic = %MyResult.as.Try.impl.Branch.specific_fn (constants.%MyResult.as.Try.impl.Branch.specific_fn)]
// CHECK:STDOUT:   %ControlFlow: type = class_type @ControlFlow, @ControlFlow(%T.loc48_12.1, %E.loc48_21.1) [symbolic = %ControlFlow (constants.%ControlFlow.eda317.2)]
// CHECK:STDOUT:   %require_complete.loc49_16.1: <witness> = require_complete_type %ControlFlow [symbolic = %require_complete.loc49_16.1 (constants.%require_complete.a4d899.2)]
// CHECK:STDOUT:   %tuple.type.loc49_16.1: type = tuple_type (%T.loc48_12.1) [symbolic = %tuple.type.loc49_16.1 (constants.%tuple.type.026b76.1)]
// CHECK:STDOUT:   %tuple.type.loc49_16.2: type = tuple_type (%E.loc48_21.1) [symbolic = %tuple.type.loc49_16.2 (constants.%tuple.type.17989b.1)]
// CHECK:STDOUT:   %.loc49_16.21: type = custom_layout_type {size=0, align=0, .Continue@0: @Thread.%tuple.type.loc49_16.1 (%tuple.type.026b76.1), .Break@0: @Thread.%tuple.type.loc49_16.2 (%tuple.type.17989b.1)} [symbolic = %.loc49_16.21 (constants.%.bef625.2)]
// CHECK:STDOUT:   %require_complete.loc49_16.2: <witness> = require_complete_type %E.loc48_21.1 [symbolic = %require_complete.loc49_16.2 (constants.%require_complete.441886.1)]
// CHECK:STDOUT:   %Try.WithSelf.FromBreak.type: type = fn_type @Try.WithSelf.FromBreak, @Try.WithSelf(%Try.facet.loc49_16.2) [symbolic = %Try.WithSelf.FromBreak.type (constants.%Try.WithSelf.FromBreak.type.d1a)]
// CHECK:STDOUT:   %.loc49_16.22: type = fn_type_with_self_type %Try.WithSelf.FromBreak.type, %Try.facet.loc49_16.2 [symbolic = %.loc49_16.22 (constants.%.226)]
// CHECK:STDOUT:   %MyResult.as.Try.impl.FromBreak.type: type = fn_type @MyResult.as.Try.impl.FromBreak, @MyResult.as.Try.impl(%T.loc48_12.1, %E.loc48_21.1) [symbolic = %MyResult.as.Try.impl.FromBreak.type (constants.%MyResult.as.Try.impl.FromBreak.type)]
// CHECK:STDOUT:   %MyResult.as.Try.impl.FromBreak: @Thread.%MyResult.as.Try.impl.FromBreak.type (%MyResult.as.Try.impl.FromBreak.type) = struct_value () [symbolic = %MyResult.as.Try.impl.FromBreak (constants.%MyResult.as.Try.impl.FromBreak)]
// CHECK:STDOUT:   %MyResult.as.Try.impl.FromBreak.specific_fn: <specific function> = specific_function %MyResult.as.Try.impl.FromBreak, @MyResult.as.Try.impl.FromBreak(%T.loc48_12.1, %E.loc48_21.1) [symbolic = %MyResult.as.Try.impl.FromBreak.specific_fn (constants.%MyResult.as.Try.impl.FromBreak.specific_fn)]
// CHECK:STDOUT:   %Destroy.lookup_impl_witness: <witness> = lookup_impl_witness %ControlFlow, @Destroy [symbolic = %Destroy.lookup_impl_witness (constants.%Destroy.lookup_impl_witness)]
// CHECK:STDOUT:   %Destroy.facet.loc49_16.5: %Destroy.type = facet_value %ControlFlow, (%Destroy.lookup_impl_witness) [symbolic = %Destroy.facet.loc49_16.5 (constants.%Destroy.facet)]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type: type = fn_type @Destroy.WithSelf.Op, @Destroy.WithSelf(%Destroy.facet.loc49_16.5) [symbolic = %Destroy.WithSelf.Op.type (constants.%Destroy.WithSelf.Op.type.16c)]
// CHECK:STDOUT:   %.loc49_16.23: type = fn_type_with_self_type %Destroy.WithSelf.Op.type, %Destroy.facet.loc49_16.5 [symbolic = %.loc49_16.23 (constants.%.9db)]
// CHECK:STDOUT:   %impl.elem0.loc49_16.5: @Thread.%.loc49_16.23 (%.9db) = impl_witness_access %Destroy.lookup_impl_witness, element0 [symbolic = %impl.elem0.loc49_16.5 (constants.%impl.elem0.ae8)]
// CHECK:STDOUT:   %specific_impl_fn.loc49_16.3: <specific function> = specific_impl_function %impl.elem0.loc49_16.5, @Destroy.WithSelf.Op(%Destroy.facet.loc49_16.5) [symbolic = %specific_impl_fn.loc49_16.3 (constants.%specific_impl_fn.8f1)]
// CHECK:STDOUT:   %Consume.specific_fn.loc50_3.2: <specific function> = specific_function constants.%Consume, @Consume(%T.loc48_12.1) [symbolic = %Consume.specific_fn.loc50_3.2 (constants.%Consume.specific_fn)]
// CHECK:STDOUT:   %MyResult.Ok.type: type = fn_type @MyResult.Ok, @MyResult(%T.loc48_12.1, %E.loc48_21.1) [symbolic = %MyResult.Ok.type (constants.%MyResult.Ok.type)]
// CHECK:STDOUT:   %MyResult.Ok: @Thread.%MyResult.Ok.type (%MyResult.Ok.type) = struct_value () [symbolic = %MyResult.Ok (constants.%MyResult.Ok)]
// CHECK:STDOUT:   %MyResult.Ok.specific_fn.loc51_24.2: <specific function> = specific_function %MyResult.Ok, @MyResult.Ok(%T.loc48_12.1, %E.loc48_21.1) [symbolic = %MyResult.Ok.specific_fn.loc51_24.2 (constants.%MyResult.Ok.specific_fn)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%mr.param: @Thread.%MyResult.loc48_46.1 (%MyResult)) -> out %return.param: @Thread.%MyResult.loc48_46.1 (%MyResult) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %mr.ref: @Thread.%MyResult.loc48_46.1 (%MyResult) = name_ref mr, %mr
// CHECK:STDOUT:     %impl.elem2: @Thread.%.loc49_16.20 (%.bb0) = impl_witness_access constants.%Try.impl_witness, element2 [symbolic = %MyResult.as.Try.impl.Branch (constants.%MyResult.as.Try.impl.Branch)]
// CHECK:STDOUT:     %bound_method.loc49_16.1: <bound method> = bound_method %mr.ref, %impl.elem2
// CHECK:STDOUT:     %specific_fn.loc49_16.1: <specific function> = specific_function %impl.elem2, @MyResult.as.Try.impl.Branch(constants.%T.67d, constants.%E) [symbolic = %MyResult.as.Try.impl.Branch.specific_fn (constants.%MyResult.as.Try.impl.Branch.specific_fn)]
// CHECK:STDOUT:     %bound_method.loc49_16.2: <bound method> = bound_method %mr.ref, %specific_fn.loc49_16.1
// CHECK:STDOUT:     %.loc49_16.1: ref @Thread.%ControlFlow (%ControlFlow.eda317.2) = temporary_storage
// CHECK:STDOUT:     %MyResult.as.Try.impl.Branch.call: init @Thread.%ControlFlow (%ControlFlow.eda317.2) to %.loc49_16.1 = call %bound_method.loc49_16.2(%mr.ref)
// CHECK:STDOUT:     %.loc49_16.2: ref @Thread.%ControlFlow (%ControlFlow.eda317.2) = temporary %.loc49_16.1, %MyResult.as.Try.impl.Branch.call
// CHECK:STDOUT:     %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:     %impl.elem0.loc49_16.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:     %bound_method.loc49_16.3: <bound method> = bound_method %int_1, %impl.elem0.loc49_16.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:     %specific_fn.loc49_16.2: <specific function> = specific_function %impl.elem0.loc49_16.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:     %bound_method.loc49_16.4: <bound method> = bound_method %int_1, %specific_fn.loc49_16.2 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %u1 = call %bound_method.loc49_16.4(%int_1) [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc49_16.3: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc49_16.4: %u1 = converted %int_1, %.loc49_16.3 [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc49_16.5: ref %u1 = class_element_access %.loc49_16.2, element0
// CHECK:STDOUT:     %impl.elem0.loc49_16.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:     %bound_method.loc49_16.5: <bound method> = bound_method %.loc49_16.4, %impl.elem0.loc49_16.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.22c]
// CHECK:STDOUT:     %specific_fn.loc49_16.3: <specific function> = specific_function %impl.elem0.loc49_16.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:     %bound_method.loc49_16.6: <bound method> = bound_method %.loc49_16.4, %specific_fn.loc49_16.3 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:     %.loc49_16.6: %u1 = acquire_value %.loc49_16.5
// CHECK:STDOUT:     %UInt.as.EqWith.impl.Equal.call: init bool = call %bound_method.loc49_16.6(%.loc49_16.4, %.loc49_16.6)
// CHECK:STDOUT:     %.loc49_16.7: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call
// CHECK:STDOUT:     %.loc49_16.8: bool = converted %UInt.as.EqWith.impl.Equal.call, %.loc49_16.7
// CHECK:STDOUT:     if %.loc49_16.8 br !.loc49_16.1 else br !.loc49_16.2
// CHECK:STDOUT:
// CHECK:STDOUT:   !.loc49_16.1:
// CHECK:STDOUT:     %.loc49_16.9: ref @Thread.%.loc49_16.21 (%.bef625.2) = class_element_access %.loc49_16.2, element1
// CHECK:STDOUT:     %.loc49_16.10: ref @Thread.%tuple.type.loc49_16.2 (%tuple.type.17989b.1) = class_element_access %.loc49_16.9, element1
// CHECK:STDOUT:     %tuple.elem0.loc49_16.1: ref @Thread.%E.loc48_21.1 (%E) = tuple_access %.loc49_16.10, element0
// CHECK:STDOUT:     %.loc49_16.11: @Thread.%E.loc48_21.1 (%E) = acquire_value %tuple.elem0.loc49_16.1
// CHECK:STDOUT:     %Try.facet.loc49_16.1: %Try.type = facet_value constants.%MyResult, (constants.%Try.impl_witness) [symbolic = %Try.facet.loc49_16.2 (constants.%Try.facet)]
// CHECK:STDOUT:     %.loc49_16.12: %Try.type = converted constants.%MyResult, %Try.facet.loc49_16.1 [symbolic = %Try.facet.loc49_16.2 (constants.%Try.facet)]
// CHECK:STDOUT:     %impl.elem3: @Thread.%.loc49_16.22 (%.226) = impl_witness_access constants.%Try.impl_witness, element3 [symbolic = %MyResult.as.Try.impl.FromBreak (constants.%MyResult.as.Try.impl.FromBreak)]
// CHECK:STDOUT:     %specific_fn.loc49_16.4: <specific function> = specific_function %impl.elem3, @MyResult.as.Try.impl.FromBreak(constants.%T.67d, constants.%E) [symbolic = %MyResult.as.Try.impl.FromBreak.specific_fn (constants.%MyResult.as.Try.impl.FromBreak.specific_fn)]
// CHECK:STDOUT:     %.loc48_65.1: ref @Thread.%MyResult.loc48_46.1 (%MyResult) = splice_block %return.param {}
// CHECK:STDOUT:     %MyResult.as.Try.impl.FromBreak.call: init @Thread.%MyResult.loc48_46.1 (%MyResult) to %.loc48_65.1 = call %specific_fn.loc49_16.4(%.loc49_16.11)
// CHECK:STDOUT:     %impl.elem0.loc49_16.3: @Thread.%.loc49_16.23 (%.9db) = impl_witness_access constants.%Destroy.lookup_impl_witness, element0 [symbolic = %impl.elem0.loc49_16.5 (constants.%impl.elem0.ae8)]
// CHECK:STDOUT:     %bound_method.loc49_16.7: <bound method> = bound_method %.loc49_16.2, %impl.elem0.loc49_16.3
// CHECK:STDOUT:     %Destroy.facet.loc49_16.1: %Destroy.type = facet_value constants.%ControlFlow.eda317.2, (constants.%Destroy.lookup_impl_witness) [symbolic = %Destroy.facet.loc49_16.5 (constants.%Destroy.facet)]
// CHECK:STDOUT:     %.loc49_16.13: %Destroy.type = converted constants.%ControlFlow.eda317.2, %Destroy.facet.loc49_16.1 [symbolic = %Destroy.facet.loc49_16.5 (constants.%Destroy.facet)]
// CHECK:STDOUT:     %Destroy.facet.loc49_16.2: %Destroy.type = facet_value constants.%ControlFlow.eda317.2, (constants.%Destroy.lookup_impl_witness) [symbolic = %Destroy.facet.loc49_16.5 (constants.%Destroy.facet)]
// CHECK:STDOUT:     %.loc49_16.14: %Destroy.type = converted constants.%ControlFlow.eda317.2, %Destroy.facet.loc49_16.2 [symbolic = %Destroy.facet.loc49_16.5 (constants.%Destroy.facet)]
// CHECK:STDOUT:     %specific_impl_fn.loc49_16.1: <specific function> = specific_impl_function %impl.elem0.loc49_16.3, @Destroy.WithSelf.Op(constants.%Destroy.facet) [symbolic = %specific_impl_fn.loc49_16.3 (constants.%specific_impl_fn.8f1)]
// CHECK:STDOUT:     %bound_method.loc49_16.8: <bound method> = bound_method %.loc49_16.2, %specific_impl_fn.loc49_16.1
// CHECK:STDOUT:     %Destroy.WithSelf.Op.call.loc49_16.1: init %empty_tuple.type = call %bound_method.loc49_16.8(%.loc49_16.2)
// CHECK:STDOUT:     return %MyResult.as.Try.impl.FromBreak.call to %return.param
// CHECK:STDOUT:
// CHECK:STDOUT:   !.loc49_16.2:
// CHECK:STDOUT:     %.loc49_16.15: ref @Thread.%.loc49_16.21 (%.bef625.2) = class_element_access %.loc49_16.2, element1
// CHECK:STDOUT:     %.loc49_16.16: ref @Thread.%tuple.type.loc49_16.1 (%tuple.type.026b76.1) = class_element_access %.loc49_16.15, element0
// CHECK:STDOUT:     %tuple.elem0.loc49_16.2: ref @Thread.%T.loc48_12.1 (%T.67d) = tuple_access %.loc49_16.16, element0
// CHECK:STDOUT:     %.loc49_16.17: @Thread.%T.loc48_12.1 (%T.67d) = acquire_value %tuple.elem0.loc49_16.2
// CHECK:STDOUT:     %T.ref.loc49: type = name_ref T, %T.loc48_12.2 [symbolic = %T.loc48_12.1 (constants.%T.67d)]
// CHECK:STDOUT:     %v: @Thread.%T.loc48_12.1 (%T.67d) = wrapper_binding v, %.loc49_16.17
// CHECK:STDOUT:     name_binding_decl {
// CHECK:STDOUT:       %v.patt.loc49_8.1: @Thread.%pattern_type.loc49 (%pattern_type.51d1c4.1) = value_binding_pattern v [symbolic = %v.patt.loc49_8.2 (constants.%v.patt.291)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %Consume.ref: %Consume.type = name_ref Consume, file.%Consume.decl [concrete = constants.%Consume]
// CHECK:STDOUT:     %T.ref.loc50: type = name_ref T, %T.loc48_12.2 [symbolic = %T.loc48_12.1 (constants.%T.67d)]
// CHECK:STDOUT:     %v.ref.loc50: @Thread.%T.loc48_12.1 (%T.67d) = name_ref v, %v
// CHECK:STDOUT:     %Consume.specific_fn.loc50_3.1: <specific function> = specific_function %Consume.ref, @Consume(constants.%T.67d) [symbolic = %Consume.specific_fn.loc50_3.2 (constants.%Consume.specific_fn)]
// CHECK:STDOUT:     %Consume.call: init %empty_tuple.type = call %Consume.specific_fn.loc50_3.1(%v.ref.loc50)
// CHECK:STDOUT:     %MyResult.ref.loc51: %MyResult.type = name_ref MyResult, file.%MyResult.decl [concrete = constants.%MyResult.generic]
// CHECK:STDOUT:     %T.ref.loc51: type = name_ref T, %T.loc48_12.2 [symbolic = %T.loc48_12.1 (constants.%T.67d)]
// CHECK:STDOUT:     %E.ref.loc51: type = name_ref E, %E.loc48_21.2 [symbolic = %E.loc48_21.1 (constants.%E)]
// CHECK:STDOUT:     %MyResult.loc51: type = class_type @MyResult, @MyResult(constants.%T.67d, constants.%E) [symbolic = %MyResult.loc48_46.1 (constants.%MyResult)]
// CHECK:STDOUT:     %.loc51: @Thread.%MyResult.Ok.type (%MyResult.Ok.type) = specific_constant generated.%MyResult.Ok.decl, @MyResult(constants.%T.67d, constants.%E) [symbolic = %MyResult.Ok (constants.%MyResult.Ok)]
// CHECK:STDOUT:     %Ok.ref: @Thread.%MyResult.Ok.type (%MyResult.Ok.type) = name_ref Ok, %.loc51 [symbolic = %MyResult.Ok (constants.%MyResult.Ok)]
// CHECK:STDOUT:     %v.ref.loc51: @Thread.%T.loc48_12.1 (%T.67d) = name_ref v, %v
// CHECK:STDOUT:     %MyResult.Ok.specific_fn.loc51_24.1: <specific function> = specific_function %Ok.ref, @MyResult.Ok(constants.%T.67d, constants.%E) [symbolic = %MyResult.Ok.specific_fn.loc51_24.2 (constants.%MyResult.Ok.specific_fn)]
// CHECK:STDOUT:     %.loc48_65.2: ref @Thread.%MyResult.loc48_46.1 (%MyResult) = splice_block %return.param {}
// CHECK:STDOUT:     %MyResult.Ok.call: init @Thread.%MyResult.loc48_46.1 (%MyResult) to %.loc48_65.2 = call %MyResult.Ok.specific_fn.loc51_24.1(%v.ref.loc51)
// CHECK:STDOUT:     %impl.elem0.loc49_16.4: @Thread.%.loc49_16.23 (%.9db) = impl_witness_access constants.%Destroy.lookup_impl_witness, element0 [symbolic = %impl.elem0.loc49_16.5 (constants.%impl.elem0.ae8)]
// CHECK:STDOUT:     %bound_method.loc49_16.9: <bound method> = bound_method %.loc49_16.2, %impl.elem0.loc49_16.4
// CHECK:STDOUT:     %Destroy.facet.loc49_16.3: %Destroy.type = facet_value constants.%ControlFlow.eda317.2, (constants.%Destroy.lookup_impl_witness) [symbolic = %Destroy.facet.loc49_16.5 (constants.%Destroy.facet)]
// CHECK:STDOUT:     %.loc49_16.18: %Destroy.type = converted constants.%ControlFlow.eda317.2, %Destroy.facet.loc49_16.3 [symbolic = %Destroy.facet.loc49_16.5 (constants.%Destroy.facet)]
// CHECK:STDOUT:     %Destroy.facet.loc49_16.4: %Destroy.type = facet_value constants.%ControlFlow.eda317.2, (constants.%Destroy.lookup_impl_witness) [symbolic = %Destroy.facet.loc49_16.5 (constants.%Destroy.facet)]
// CHECK:STDOUT:     %.loc49_16.19: %Destroy.type = converted constants.%ControlFlow.eda317.2, %Destroy.facet.loc49_16.4 [symbolic = %Destroy.facet.loc49_16.5 (constants.%Destroy.facet)]
// CHECK:STDOUT:     %specific_impl_fn.loc49_16.2: <specific function> = specific_impl_function %impl.elem0.loc49_16.4, @Destroy.WithSelf.Op(constants.%Destroy.facet) [symbolic = %specific_impl_fn.loc49_16.3 (constants.%specific_impl_fn.8f1)]
// CHECK:STDOUT:     %bound_method.loc49_16.10: <bound method> = bound_method %.loc49_16.2, %specific_impl_fn.loc49_16.2
// CHECK:STDOUT:     %Destroy.WithSelf.Op.call.loc49_16.2: init %empty_tuple.type = call %bound_method.loc49_16.10(%.loc49_16.2)
// CHECK:STDOUT:     return %MyResult.Ok.call to %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Thread(constants.%T.67d, constants.%E) {
// CHECK:STDOUT:   %T.patt.loc48_12.2 => constants.%T.patt.d47
// CHECK:STDOUT:   %T.loc48_12.1 => constants.%T.67d
// CHECK:STDOUT:   %E.patt.loc48_21.2 => constants.%E.patt
// CHECK:STDOUT:   %E.loc48_21.1 => constants.%E
// CHECK:STDOUT:   %MyResult.loc48_46.1 => constants.%MyResult
// CHECK:STDOUT:   %pattern_type.loc48 => constants.%pattern_type.6db
// CHECK:STDOUT:   %mr.param_patt.loc48_31.2 => constants.%mr.param_patt
// CHECK:STDOUT:   %mr.patt.loc48_31.2 => constants.%mr.patt
// CHECK:STDOUT:   %.loc48_65.3 => constants.%.6c7
// CHECK:STDOUT:   %return.param_patt.loc48_65.2 => constants.%return.param_patt.296
// CHECK:STDOUT:   %return.patt.loc48_49.2 => constants.%return.patt.971e
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- mixed.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %.Self.frozen.197: %type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %pattern_type.98f: type = pattern_type type [concrete]
// CHECK:STDOUT:   %T.patt.d47: %pattern_type.98f = symbolic_binding_pattern T, 0 [symbolic]
// CHECK:STDOUT:   %T.67d: type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %E: type = symbolic_binding E, 1 [symbolic]
// CHECK:STDOUT:   %MyResult.type: type = generic_class_type @MyResult [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %MyResult.generic: %MyResult.type = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.51d1c4.1: type = pattern_type %T.67d [symbolic]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %u1: type = class_type @UInt, @UInt(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %require_complete.9443dd.1: <witness> = require_complete_type %T.67d [symbolic]
// CHECK:STDOUT:   %tuple.type.026b76.1: type = tuple_type (%T.67d) [symbolic]
// CHECK:STDOUT:   %MyResult.Ok.type.fd7: type = fn_type @MyResult.Ok, @MyResult(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %MyResult.Ok.460: %MyResult.Ok.type.fd7 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.type.ca1: type = facet_type <@ImplicitAs, @ImplicitAs(%u1)> [concrete]
// CHECK:STDOUT:   %To.fe9: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.b68(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.170: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.f4c: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.f01, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet: %ImplicitAs.type.ca1 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.f4c) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.77c: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%u1, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.e74: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.77c, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %bound_method.d7a: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_1.233: %u1 = int_value 1 [concrete]
// CHECK:STDOUT:   %Try.type: type = facet_type <@Try> [concrete]
// CHECK:STDOUT:   %v.patt.291: %pattern_type.51d1c4.1 = value_binding_pattern v [symbolic]
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
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.specific_fn.6b6: <specific function> = specific_function %UInt.as.EqWith.impl.Equal.ba4, @UInt.as.EqWith.impl.Equal.1(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound.22c: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %bound_method.a82: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %MyResult.f7e: type = class_type @MyResult, @MyResult(%T.67d, %i32) [symbolic]
// CHECK:STDOUT:   %pattern_type.071: type = pattern_type %MyResult.f7e [symbolic]
// CHECK:STDOUT:   %mr.param_patt: %pattern_type.071 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %mr.patt: %pattern_type.071 = at_binding_pattern mr, %mr.param_patt [symbolic]
// CHECK:STDOUT:   %.ff9: Core.Form = init_form %MyResult.f7e [symbolic]
// CHECK:STDOUT:   %return.param_patt.d89: %pattern_type.071 = out_param_pattern [symbolic]
// CHECK:STDOUT:   %return.patt.300: %pattern_type.071 = return_slot_pattern %return.param_patt.d89, %MyResult.f7e [symbolic]
// CHECK:STDOUT:   %ThreadMixed.type: type = fn_type @ThreadMixed [concrete]
// CHECK:STDOUT:   %ThreadMixed: %ThreadMixed.type = struct_value () [concrete]
// CHECK:STDOUT:   %tuple.type.a8a: type = tuple_type (%i32) [concrete]
// CHECK:STDOUT:   %MyResult.Ok.type.64e: type = fn_type @MyResult.Ok, @MyResult(%T.67d, %i32) [symbolic]
// CHECK:STDOUT:   %MyResult.Ok.2d0: %MyResult.Ok.type.64e = struct_value () [symbolic]
// CHECK:STDOUT:   %require_complete.dd6: <witness> = require_complete_type %MyResult.f7e [symbolic]
// CHECK:STDOUT:   %Try.impl_witness.2ae: <witness> = impl_witness @MyResult.as.Try.impl.%Try.impl_witness_table, @MyResult.as.Try.impl(%T.67d, %i32) [symbolic]
// CHECK:STDOUT:   %MyResult.as.Try.impl.Branch.type.9f1: type = fn_type @MyResult.as.Try.impl.Branch, @MyResult.as.Try.impl(%T.67d, %i32) [symbolic]
// CHECK:STDOUT:   %MyResult.as.Try.impl.Branch.629: %MyResult.as.Try.impl.Branch.type.9f1 = struct_value () [symbolic]
// CHECK:STDOUT:   %MyResult.as.Try.impl.FromBreak.type.22a: type = fn_type @MyResult.as.Try.impl.FromBreak, @MyResult.as.Try.impl(%T.67d, %i32) [symbolic]
// CHECK:STDOUT:   %MyResult.as.Try.impl.FromBreak.908: %MyResult.as.Try.impl.FromBreak.type.22a = struct_value () [symbolic]
// CHECK:STDOUT:   %Try.facet.95f: %Try.type = facet_value %MyResult.f7e, (%Try.impl_witness.2ae) [symbolic]
// CHECK:STDOUT:   %Try.WithSelf.Branch.type.dab: type = fn_type @Try.WithSelf.Branch, @Try.WithSelf(%Try.facet.95f) [symbolic]
// CHECK:STDOUT:   %Try.WithSelf.FromBreak.type.f5b: type = fn_type @Try.WithSelf.FromBreak, @Try.WithSelf(%Try.facet.95f) [symbolic]
// CHECK:STDOUT:   %.17f: type = fn_type_with_self_type %Try.WithSelf.Branch.type.dab, %Try.facet.95f [symbolic]
// CHECK:STDOUT:   %ControlFlow.10a: type = class_type @ControlFlow, @ControlFlow(%T.67d, %i32) [symbolic]
// CHECK:STDOUT:   %MyResult.as.Try.impl.Branch.specific_fn: <specific function> = specific_function %MyResult.as.Try.impl.Branch.629, @MyResult.as.Try.impl.Branch(%T.67d, %i32) [symbolic]
// CHECK:STDOUT:   %.c43: type = custom_layout_type {size=0, align=0, .Continue@0: %tuple.type.026b76.1, .Break@0: %tuple.type.a8a} [symbolic]
// CHECK:STDOUT:   %.be6: type = fn_type_with_self_type %Try.WithSelf.FromBreak.type.f5b, %Try.facet.95f [symbolic]
// CHECK:STDOUT:   %MyResult.as.Try.impl.FromBreak.specific_fn: <specific function> = specific_function %MyResult.as.Try.impl.FromBreak.908, @MyResult.as.Try.impl.FromBreak(%T.67d, %i32) [symbolic]
// CHECK:STDOUT:   %Destroy.type: type = facet_type <@Destroy> [concrete]
// CHECK:STDOUT:   %Destroy.lookup_impl_witness: <witness> = lookup_impl_witness %ControlFlow.10a, @Destroy [symbolic]
// CHECK:STDOUT:   %Destroy.facet: %Destroy.type = facet_value %ControlFlow.10a, (%Destroy.lookup_impl_witness) [symbolic]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.bd7: type = fn_type @Destroy.WithSelf.Op, @Destroy.WithSelf(%Destroy.facet) [symbolic]
// CHECK:STDOUT:   %.314: type = fn_type_with_self_type %Destroy.WithSelf.Op.type.bd7, %Destroy.facet [symbolic]
// CHECK:STDOUT:   %impl.elem0.a9c: %.314 = impl_witness_access %Destroy.lookup_impl_witness, element0 [symbolic]
// CHECK:STDOUT:   %specific_impl_fn.5fb: <specific function> = specific_impl_function %impl.elem0.a9c, @Destroy.WithSelf.Op(%Destroy.facet) [symbolic]
// CHECK:STDOUT:   %MyResult.Ok.specific_fn: <specific function> = specific_function %MyResult.Ok.2d0, @MyResult.Ok(%T.67d, %i32) [symbolic]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.aa5: @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.170)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.f01 = impl_witness_table (%Core.import_ref.aa5), @Core.IntLiteral.as.ImplicitAs.impl.b68 [concrete]
// CHECK:STDOUT:   %Core.import_ref.b92: @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal.type (%UInt.as.EqWith.impl.Equal.type.544) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal (constants.%UInt.as.EqWith.impl.Equal.c67)]
// CHECK:STDOUT:   %Core.import_ref.b44 = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.166 = impl_witness_table (%Core.import_ref.b92, %Core.import_ref.b44), @UInt.as.EqWith.impl.f13 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %MyResult.Ok.decl: @MyResult.%MyResult.Ok.type (%MyResult.Ok.type.fd7) = fn_decl @MyResult.Ok [symbolic = @MyResult.%MyResult.Ok (constants.%MyResult.Ok.460)] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %ThreadMixed.decl: %ThreadMixed.type = fn_decl @ThreadMixed [concrete = constants.%ThreadMixed] {
// CHECK:STDOUT:     %T.patt.loc37_17.1: %pattern_type.98f = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc37_17.2 (constants.%T.patt.d47)]
// CHECK:STDOUT:     %mr.param_patt.loc37_27.1: @ThreadMixed.%pattern_type.loc37 (%pattern_type.071) = value_param_pattern [symbolic = %mr.param_patt.loc37_27.2 (constants.%mr.param_patt)]
// CHECK:STDOUT:     %mr.patt.loc37_27.1: @ThreadMixed.%pattern_type.loc37 (%pattern_type.071) = at_binding_pattern mr, %mr.param_patt.loc37_27.1 [symbolic = %mr.patt.loc37_27.2 (constants.%mr.patt)]
// CHECK:STDOUT:     %return.param_patt.loc37_65.1: @ThreadMixed.%pattern_type.loc37 (%pattern_type.071) = out_param_pattern [symbolic = %return.param_patt.loc37_65.2 (constants.%return.param_patt.d89)]
// CHECK:STDOUT:     %return.patt.loc37_47.1: @ThreadMixed.%pattern_type.loc37 (%pattern_type.071) = return_slot_pattern %return.param_patt.loc37_65.1, %MyResult.loc37_65 [symbolic = %return.patt.loc37_47.2 (constants.%return.patt.300)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %MyResult.ref.loc37_50: %MyResult.type = name_ref MyResult, file.%MyResult.decl [concrete = constants.%MyResult.generic]
// CHECK:STDOUT:     %T.ref.loc37_59: type = name_ref T, %T.loc37_17.2 [symbolic = %T.loc37_17.1 (constants.%T.67d)]
// CHECK:STDOUT:     %i32.loc37_62: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %MyResult.loc37_65: type = class_type @MyResult, @MyResult(constants.%T.67d, constants.%i32) [symbolic = %MyResult.loc37_44.1 (constants.%MyResult.f7e)]
// CHECK:STDOUT:     %.loc37_65.4: Core.Form = init_form %MyResult.loc37_65 [symbolic = %.loc37_65.3 (constants.%.ff9)]
// CHECK:STDOUT:     %.loc37_19.1: type = splice_block %.loc37_19.2 [concrete = type] {
// CHECK:STDOUT:       %.Self.frozen: %type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen.197]
// CHECK:STDOUT:       %.loc37_19.2: type = type_literal type [concrete = type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc37_17.2: type = symbolic_binding T, 0 [symbolic = %T.loc37_17.1 (constants.%T.67d)]
// CHECK:STDOUT:     %mr.param: @ThreadMixed.%MyResult.loc37_44.1 (%MyResult.f7e) = value_param call_param0
// CHECK:STDOUT:     %.loc37_44: type = splice_block %MyResult.loc37_44.2 [symbolic = %MyResult.loc37_44.1 (constants.%MyResult.f7e)] {
// CHECK:STDOUT:       %MyResult.ref.loc37_29: %MyResult.type = name_ref MyResult, file.%MyResult.decl [concrete = constants.%MyResult.generic]
// CHECK:STDOUT:       %T.ref.loc37_38: type = name_ref T, %T.loc37_17.2 [symbolic = %T.loc37_17.1 (constants.%T.67d)]
// CHECK:STDOUT:       %i32.loc37_41: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %MyResult.loc37_44.2: type = class_type @MyResult, @MyResult(constants.%T.67d, constants.%i32) [symbolic = %MyResult.loc37_44.1 (constants.%MyResult.f7e)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %mr: @ThreadMixed.%MyResult.loc37_44.1 (%MyResult.f7e) = wrapper_binding mr, %mr.param
// CHECK:STDOUT:     %return.param: ref @ThreadMixed.%MyResult.loc37_44.1 (%MyResult.f7e) = out_param call_param1
// CHECK:STDOUT:     %return: ref @ThreadMixed.%MyResult.loc37_44.1 (%MyResult.f7e) = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @ThreadMixed(%T.loc37_17.2: type) {
// CHECK:STDOUT:   %T.patt.loc37_17.2: %pattern_type.98f = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc37_17.2 (constants.%T.patt.d47)]
// CHECK:STDOUT:   %T.loc37_17.1: type = symbolic_binding T, 0 [symbolic = %T.loc37_17.1 (constants.%T.67d)]
// CHECK:STDOUT:   %MyResult.loc37_44.1: type = class_type @MyResult, @MyResult(%T.loc37_17.1, constants.%i32) [symbolic = %MyResult.loc37_44.1 (constants.%MyResult.f7e)]
// CHECK:STDOUT:   %pattern_type.loc37: type = pattern_type %MyResult.loc37_44.1 [symbolic = %pattern_type.loc37 (constants.%pattern_type.071)]
// CHECK:STDOUT:   %mr.param_patt.loc37_27.2: @ThreadMixed.%pattern_type.loc37 (%pattern_type.071) = value_param_pattern [symbolic = %mr.param_patt.loc37_27.2 (constants.%mr.param_patt)]
// CHECK:STDOUT:   %mr.patt.loc37_27.2: @ThreadMixed.%pattern_type.loc37 (%pattern_type.071) = at_binding_pattern mr, %mr.param_patt.loc37_27.2 [symbolic = %mr.patt.loc37_27.2 (constants.%mr.patt)]
// CHECK:STDOUT:   %.loc37_65.3: Core.Form = init_form %MyResult.loc37_44.1 [symbolic = %.loc37_65.3 (constants.%.ff9)]
// CHECK:STDOUT:   %return.param_patt.loc37_65.2: @ThreadMixed.%pattern_type.loc37 (%pattern_type.071) = out_param_pattern [symbolic = %return.param_patt.loc37_65.2 (constants.%return.param_patt.d89)]
// CHECK:STDOUT:   %return.patt.loc37_47.2: @ThreadMixed.%pattern_type.loc37 (%pattern_type.071) = return_slot_pattern %return.param_patt.loc37_65.2, %MyResult.loc37_44.1 [symbolic = %return.patt.loc37_47.2 (constants.%return.patt.300)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc37: <witness> = require_complete_type %MyResult.loc37_44.1 [symbolic = %require_complete.loc37 (constants.%require_complete.dd6)]
// CHECK:STDOUT:   %require_complete.loc38: <witness> = require_complete_type %T.loc37_17.1 [symbolic = %require_complete.loc38 (constants.%require_complete.9443dd.1)]
// CHECK:STDOUT:   %pattern_type.loc38: type = pattern_type %T.loc37_17.1 [symbolic = %pattern_type.loc38 (constants.%pattern_type.51d1c4.1)]
// CHECK:STDOUT:   %v.patt.loc38_8.2: @ThreadMixed.%pattern_type.loc38 (%pattern_type.51d1c4.1) = value_binding_pattern v [symbolic = %v.patt.loc38_8.2 (constants.%v.patt.291)]
// CHECK:STDOUT:   %Try.impl_witness: <witness> = impl_witness @MyResult.as.Try.impl.%Try.impl_witness_table, @MyResult.as.Try.impl(%T.loc37_17.1, constants.%i32) [symbolic = %Try.impl_witness (constants.%Try.impl_witness.2ae)]
// CHECK:STDOUT:   %Try.facet.loc38_16.2: %Try.type = facet_value %MyResult.loc37_44.1, (%Try.impl_witness) [symbolic = %Try.facet.loc38_16.2 (constants.%Try.facet.95f)]
// CHECK:STDOUT:   %Try.WithSelf.Branch.type: type = fn_type @Try.WithSelf.Branch, @Try.WithSelf(%Try.facet.loc38_16.2) [symbolic = %Try.WithSelf.Branch.type (constants.%Try.WithSelf.Branch.type.dab)]
// CHECK:STDOUT:   %.loc38_16.20: type = fn_type_with_self_type %Try.WithSelf.Branch.type, %Try.facet.loc38_16.2 [symbolic = %.loc38_16.20 (constants.%.17f)]
// CHECK:STDOUT:   %MyResult.as.Try.impl.Branch.type: type = fn_type @MyResult.as.Try.impl.Branch, @MyResult.as.Try.impl(%T.loc37_17.1, constants.%i32) [symbolic = %MyResult.as.Try.impl.Branch.type (constants.%MyResult.as.Try.impl.Branch.type.9f1)]
// CHECK:STDOUT:   %MyResult.as.Try.impl.Branch: @ThreadMixed.%MyResult.as.Try.impl.Branch.type (%MyResult.as.Try.impl.Branch.type.9f1) = struct_value () [symbolic = %MyResult.as.Try.impl.Branch (constants.%MyResult.as.Try.impl.Branch.629)]
// CHECK:STDOUT:   %MyResult.as.Try.impl.Branch.specific_fn: <specific function> = specific_function %MyResult.as.Try.impl.Branch, @MyResult.as.Try.impl.Branch(%T.loc37_17.1, constants.%i32) [symbolic = %MyResult.as.Try.impl.Branch.specific_fn (constants.%MyResult.as.Try.impl.Branch.specific_fn)]
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:   %tuple.type: type = tuple_type (%T.loc37_17.1) [symbolic = %tuple.type (constants.%tuple.type.026b76.1)]
// CHECK:STDOUT:   %.loc38_16.21: type = custom_layout_type {size=0, align=0, .Continue@0: @ThreadMixed.%tuple.type (%tuple.type.026b76.1), .Break@0: %tuple.type.a8a} [symbolic = %.loc38_16.21 (constants.%.c43)]
// CHECK:STDOUT:   %Try.WithSelf.FromBreak.type: type = fn_type @Try.WithSelf.FromBreak, @Try.WithSelf(%Try.facet.loc38_16.2) [symbolic = %Try.WithSelf.FromBreak.type (constants.%Try.WithSelf.FromBreak.type.f5b)]
// CHECK:STDOUT:   %.loc38_16.22: type = fn_type_with_self_type %Try.WithSelf.FromBreak.type, %Try.facet.loc38_16.2 [symbolic = %.loc38_16.22 (constants.%.be6)]
// CHECK:STDOUT:   %MyResult.as.Try.impl.FromBreak.type: type = fn_type @MyResult.as.Try.impl.FromBreak, @MyResult.as.Try.impl(%T.loc37_17.1, constants.%i32) [symbolic = %MyResult.as.Try.impl.FromBreak.type (constants.%MyResult.as.Try.impl.FromBreak.type.22a)]
// CHECK:STDOUT:   %MyResult.as.Try.impl.FromBreak: @ThreadMixed.%MyResult.as.Try.impl.FromBreak.type (%MyResult.as.Try.impl.FromBreak.type.22a) = struct_value () [symbolic = %MyResult.as.Try.impl.FromBreak (constants.%MyResult.as.Try.impl.FromBreak.908)]
// CHECK:STDOUT:   %MyResult.as.Try.impl.FromBreak.specific_fn: <specific function> = specific_function %MyResult.as.Try.impl.FromBreak, @MyResult.as.Try.impl.FromBreak(%T.loc37_17.1, constants.%i32) [symbolic = %MyResult.as.Try.impl.FromBreak.specific_fn (constants.%MyResult.as.Try.impl.FromBreak.specific_fn)]
// CHECK:STDOUT:   %Destroy.lookup_impl_witness: <witness> = lookup_impl_witness %ControlFlow, @Destroy [symbolic = %Destroy.lookup_impl_witness (constants.%Destroy.lookup_impl_witness)]
// CHECK:STDOUT:   %Destroy.facet.loc38_16.5: %Destroy.type = facet_value %ControlFlow, (%Destroy.lookup_impl_witness) [symbolic = %Destroy.facet.loc38_16.5 (constants.%Destroy.facet)]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type: type = fn_type @Destroy.WithSelf.Op, @Destroy.WithSelf(%Destroy.facet.loc38_16.5) [symbolic = %Destroy.WithSelf.Op.type (constants.%Destroy.WithSelf.Op.type.bd7)]
// CHECK:STDOUT:   %.loc38_16.23: type = fn_type_with_self_type %Destroy.WithSelf.Op.type, %Destroy.facet.loc38_16.5 [symbolic = %.loc38_16.23 (constants.%.314)]
// CHECK:STDOUT:   %impl.elem0.loc38_16.5: @ThreadMixed.%.loc38_16.23 (%.314) = impl_witness_access %Destroy.lookup_impl_witness, element0 [symbolic = %impl.elem0.loc38_16.5 (constants.%impl.elem0.a9c)]
// CHECK:STDOUT:   %specific_impl_fn.loc38_16.3: <specific function> = specific_impl_function %impl.elem0.loc38_16.5, @Destroy.WithSelf.Op(%Destroy.facet.loc38_16.5) [symbolic = %specific_impl_fn.loc38_16.3 (constants.%specific_impl_fn.5fb)]
// CHECK:STDOUT:   %MyResult.Ok.type: type = fn_type @MyResult.Ok, @MyResult(%T.loc37_17.1, constants.%i32) [symbolic = %MyResult.Ok.type (constants.%MyResult.Ok.type.64e)]
// CHECK:STDOUT:   %MyResult.Ok: @ThreadMixed.%MyResult.Ok.type (%MyResult.Ok.type.64e) = struct_value () [symbolic = %MyResult.Ok (constants.%MyResult.Ok.2d0)]
// CHECK:STDOUT:   %MyResult.Ok.specific_fn.loc39_26.2: <specific function> = specific_function %MyResult.Ok, @MyResult.Ok(%T.loc37_17.1, constants.%i32) [symbolic = %MyResult.Ok.specific_fn.loc39_26.2 (constants.%MyResult.Ok.specific_fn)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%mr.param: @ThreadMixed.%MyResult.loc37_44.1 (%MyResult.f7e)) -> out %return.param: @ThreadMixed.%MyResult.loc37_44.1 (%MyResult.f7e) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %mr.ref: @ThreadMixed.%MyResult.loc37_44.1 (%MyResult.f7e) = name_ref mr, %mr
// CHECK:STDOUT:     %impl.elem2: @ThreadMixed.%.loc38_16.20 (%.17f) = impl_witness_access constants.%Try.impl_witness.2ae, element2 [symbolic = %MyResult.as.Try.impl.Branch (constants.%MyResult.as.Try.impl.Branch.629)]
// CHECK:STDOUT:     %bound_method.loc38_16.1: <bound method> = bound_method %mr.ref, %impl.elem2
// CHECK:STDOUT:     %specific_fn.loc38_16.1: <specific function> = specific_function %impl.elem2, @MyResult.as.Try.impl.Branch(constants.%T.67d, constants.%i32) [symbolic = %MyResult.as.Try.impl.Branch.specific_fn (constants.%MyResult.as.Try.impl.Branch.specific_fn)]
// CHECK:STDOUT:     %bound_method.loc38_16.2: <bound method> = bound_method %mr.ref, %specific_fn.loc38_16.1
// CHECK:STDOUT:     %.loc38_16.1: ref @ThreadMixed.%ControlFlow (%ControlFlow.10a) = temporary_storage
// CHECK:STDOUT:     %MyResult.as.Try.impl.Branch.call: init @ThreadMixed.%ControlFlow (%ControlFlow.10a) to %.loc38_16.1 = call %bound_method.loc38_16.2(%mr.ref)
// CHECK:STDOUT:     %.loc38_16.2: ref @ThreadMixed.%ControlFlow (%ControlFlow.10a) = temporary %.loc38_16.1, %MyResult.as.Try.impl.Branch.call
// CHECK:STDOUT:     %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:     %impl.elem0.loc38_16.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:     %bound_method.loc38_16.3: <bound method> = bound_method %int_1, %impl.elem0.loc38_16.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:     %specific_fn.loc38_16.2: <specific function> = specific_function %impl.elem0.loc38_16.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:     %bound_method.loc38_16.4: <bound method> = bound_method %int_1, %specific_fn.loc38_16.2 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %u1 = call %bound_method.loc38_16.4(%int_1) [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc38_16.3: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc38_16.4: %u1 = converted %int_1, %.loc38_16.3 [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc38_16.5: ref %u1 = class_element_access %.loc38_16.2, element0
// CHECK:STDOUT:     %impl.elem0.loc38_16.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:     %bound_method.loc38_16.5: <bound method> = bound_method %.loc38_16.4, %impl.elem0.loc38_16.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.22c]
// CHECK:STDOUT:     %specific_fn.loc38_16.3: <specific function> = specific_function %impl.elem0.loc38_16.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:     %bound_method.loc38_16.6: <bound method> = bound_method %.loc38_16.4, %specific_fn.loc38_16.3 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:     %.loc38_16.6: %u1 = acquire_value %.loc38_16.5
// CHECK:STDOUT:     %UInt.as.EqWith.impl.Equal.call: init bool = call %bound_method.loc38_16.6(%.loc38_16.4, %.loc38_16.6)
// CHECK:STDOUT:     %.loc38_16.7: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call
// CHECK:STDOUT:     %.loc38_16.8: bool = converted %UInt.as.EqWith.impl.Equal.call, %.loc38_16.7
// CHECK:STDOUT:     if %.loc38_16.8 br !.loc38_16.1 else br !.loc38_16.2
// CHECK:STDOUT:
// CHECK:STDOUT:   !.loc38_16.1:
// CHECK:STDOUT:     %.loc38_16.9: ref @ThreadMixed.%.loc38_16.21 (%.c43) = class_element_access %.loc38_16.2, element1
// CHECK:STDOUT:     %.loc38_16.10: ref %tuple.type.a8a = class_element_access %.loc38_16.9, element1
// CHECK:STDOUT:     %tuple.elem0.loc38_16.1: ref %i32 = tuple_access %.loc38_16.10, element0
// CHECK:STDOUT:     %.loc38_16.11: %i32 = acquire_value %tuple.elem0.loc38_16.1
// CHECK:STDOUT:     %Try.facet.loc38_16.1: %Try.type = facet_value constants.%MyResult.f7e, (constants.%Try.impl_witness.2ae) [symbolic = %Try.facet.loc38_16.2 (constants.%Try.facet.95f)]
// CHECK:STDOUT:     %.loc38_16.12: %Try.type = converted constants.%MyResult.f7e, %Try.facet.loc38_16.1 [symbolic = %Try.facet.loc38_16.2 (constants.%Try.facet.95f)]
// CHECK:STDOUT:     %impl.elem3: @ThreadMixed.%.loc38_16.22 (%.be6) = impl_witness_access constants.%Try.impl_witness.2ae, element3 [symbolic = %MyResult.as.Try.impl.FromBreak (constants.%MyResult.as.Try.impl.FromBreak.908)]
// CHECK:STDOUT:     %specific_fn.loc38_16.4: <specific function> = specific_function %impl.elem3, @MyResult.as.Try.impl.FromBreak(constants.%T.67d, constants.%i32) [symbolic = %MyResult.as.Try.impl.FromBreak.specific_fn (constants.%MyResult.as.Try.impl.FromBreak.specific_fn)]
// CHECK:STDOUT:     %.loc37_65.1: ref @ThreadMixed.%MyResult.loc37_44.1 (%MyResult.f7e) = splice_block %return.param {}
// CHECK:STDOUT:     %MyResult.as.Try.impl.FromBreak.call: init @ThreadMixed.%MyResult.loc37_44.1 (%MyResult.f7e) to %.loc37_65.1 = call %specific_fn.loc38_16.4(%.loc38_16.11)
// CHECK:STDOUT:     %impl.elem0.loc38_16.3: @ThreadMixed.%.loc38_16.23 (%.314) = impl_witness_access constants.%Destroy.lookup_impl_witness, element0 [symbolic = %impl.elem0.loc38_16.5 (constants.%impl.elem0.a9c)]
// CHECK:STDOUT:     %bound_method.loc38_16.7: <bound method> = bound_method %.loc38_16.2, %impl.elem0.loc38_16.3
// CHECK:STDOUT:     %Destroy.facet.loc38_16.1: %Destroy.type = facet_value constants.%ControlFlow.10a, (constants.%Destroy.lookup_impl_witness) [symbolic = %Destroy.facet.loc38_16.5 (constants.%Destroy.facet)]
// CHECK:STDOUT:     %.loc38_16.13: %Destroy.type = converted constants.%ControlFlow.10a, %Destroy.facet.loc38_16.1 [symbolic = %Destroy.facet.loc38_16.5 (constants.%Destroy.facet)]
// CHECK:STDOUT:     %Destroy.facet.loc38_16.2: %Destroy.type = facet_value constants.%ControlFlow.10a, (constants.%Destroy.lookup_impl_witness) [symbolic = %Destroy.facet.loc38_16.5 (constants.%Destroy.facet)]
// CHECK:STDOUT:     %.loc38_16.14: %Destroy.type = converted constants.%ControlFlow.10a, %Destroy.facet.loc38_16.2 [symbolic = %Destroy.facet.loc38_16.5 (constants.%Destroy.facet)]
// CHECK:STDOUT:     %specific_impl_fn.loc38_16.1: <specific function> = specific_impl_function %impl.elem0.loc38_16.3, @Destroy.WithSelf.Op(constants.%Destroy.facet) [symbolic = %specific_impl_fn.loc38_16.3 (constants.%specific_impl_fn.5fb)]
// CHECK:STDOUT:     %bound_method.loc38_16.8: <bound method> = bound_method %.loc38_16.2, %specific_impl_fn.loc38_16.1
// CHECK:STDOUT:     %Destroy.WithSelf.Op.call.loc38_16.1: init %empty_tuple.type = call %bound_method.loc38_16.8(%.loc38_16.2)
// CHECK:STDOUT:     return %MyResult.as.Try.impl.FromBreak.call to %return.param
// CHECK:STDOUT:
// CHECK:STDOUT:   !.loc38_16.2:
// CHECK:STDOUT:     %.loc38_16.15: ref @ThreadMixed.%.loc38_16.21 (%.c43) = class_element_access %.loc38_16.2, element1
// CHECK:STDOUT:     %.loc38_16.16: ref @ThreadMixed.%tuple.type (%tuple.type.026b76.1) = class_element_access %.loc38_16.15, element0
// CHECK:STDOUT:     %tuple.elem0.loc38_16.2: ref @ThreadMixed.%T.loc37_17.1 (%T.67d) = tuple_access %.loc38_16.16, element0
// CHECK:STDOUT:     %.loc38_16.17: @ThreadMixed.%T.loc37_17.1 (%T.67d) = acquire_value %tuple.elem0.loc38_16.2
// CHECK:STDOUT:     %T.ref.loc38: type = name_ref T, %T.loc37_17.2 [symbolic = %T.loc37_17.1 (constants.%T.67d)]
// CHECK:STDOUT:     %v: @ThreadMixed.%T.loc37_17.1 (%T.67d) = wrapper_binding v, %.loc38_16.17
// CHECK:STDOUT:     name_binding_decl {
// CHECK:STDOUT:       %v.patt.loc38_8.1: @ThreadMixed.%pattern_type.loc38 (%pattern_type.51d1c4.1) = value_binding_pattern v [symbolic = %v.patt.loc38_8.2 (constants.%v.patt.291)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %MyResult.ref.loc39: %MyResult.type = name_ref MyResult, file.%MyResult.decl [concrete = constants.%MyResult.generic]
// CHECK:STDOUT:     %T.ref.loc39: type = name_ref T, %T.loc37_17.2 [symbolic = %T.loc37_17.1 (constants.%T.67d)]
// CHECK:STDOUT:     %i32.loc39: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %MyResult.loc39: type = class_type @MyResult, @MyResult(constants.%T.67d, constants.%i32) [symbolic = %MyResult.loc37_44.1 (constants.%MyResult.f7e)]
// CHECK:STDOUT:     %.loc39: @ThreadMixed.%MyResult.Ok.type (%MyResult.Ok.type.64e) = specific_constant generated.%MyResult.Ok.decl, @MyResult(constants.%T.67d, constants.%i32) [symbolic = %MyResult.Ok (constants.%MyResult.Ok.2d0)]
// CHECK:STDOUT:     %Ok.ref: @ThreadMixed.%MyResult.Ok.type (%MyResult.Ok.type.64e) = name_ref Ok, %.loc39 [symbolic = %MyResult.Ok (constants.%MyResult.Ok.2d0)]
// CHECK:STDOUT:     %v.ref: @ThreadMixed.%T.loc37_17.1 (%T.67d) = name_ref v, %v
// CHECK:STDOUT:     %MyResult.Ok.specific_fn.loc39_26.1: <specific function> = specific_function %Ok.ref, @MyResult.Ok(constants.%T.67d, constants.%i32) [symbolic = %MyResult.Ok.specific_fn.loc39_26.2 (constants.%MyResult.Ok.specific_fn)]
// CHECK:STDOUT:     %.loc37_65.2: ref @ThreadMixed.%MyResult.loc37_44.1 (%MyResult.f7e) = splice_block %return.param {}
// CHECK:STDOUT:     %MyResult.Ok.call: init @ThreadMixed.%MyResult.loc37_44.1 (%MyResult.f7e) to %.loc37_65.2 = call %MyResult.Ok.specific_fn.loc39_26.1(%v.ref)
// CHECK:STDOUT:     %impl.elem0.loc38_16.4: @ThreadMixed.%.loc38_16.23 (%.314) = impl_witness_access constants.%Destroy.lookup_impl_witness, element0 [symbolic = %impl.elem0.loc38_16.5 (constants.%impl.elem0.a9c)]
// CHECK:STDOUT:     %bound_method.loc38_16.9: <bound method> = bound_method %.loc38_16.2, %impl.elem0.loc38_16.4
// CHECK:STDOUT:     %Destroy.facet.loc38_16.3: %Destroy.type = facet_value constants.%ControlFlow.10a, (constants.%Destroy.lookup_impl_witness) [symbolic = %Destroy.facet.loc38_16.5 (constants.%Destroy.facet)]
// CHECK:STDOUT:     %.loc38_16.18: %Destroy.type = converted constants.%ControlFlow.10a, %Destroy.facet.loc38_16.3 [symbolic = %Destroy.facet.loc38_16.5 (constants.%Destroy.facet)]
// CHECK:STDOUT:     %Destroy.facet.loc38_16.4: %Destroy.type = facet_value constants.%ControlFlow.10a, (constants.%Destroy.lookup_impl_witness) [symbolic = %Destroy.facet.loc38_16.5 (constants.%Destroy.facet)]
// CHECK:STDOUT:     %.loc38_16.19: %Destroy.type = converted constants.%ControlFlow.10a, %Destroy.facet.loc38_16.4 [symbolic = %Destroy.facet.loc38_16.5 (constants.%Destroy.facet)]
// CHECK:STDOUT:     %specific_impl_fn.loc38_16.2: <specific function> = specific_impl_function %impl.elem0.loc38_16.4, @Destroy.WithSelf.Op(constants.%Destroy.facet) [symbolic = %specific_impl_fn.loc38_16.3 (constants.%specific_impl_fn.5fb)]
// CHECK:STDOUT:     %bound_method.loc38_16.10: <bound method> = bound_method %.loc38_16.2, %specific_impl_fn.loc38_16.2
// CHECK:STDOUT:     %Destroy.WithSelf.Op.call.loc38_16.2: init %empty_tuple.type = call %bound_method.loc38_16.10(%.loc38_16.2)
// CHECK:STDOUT:     return %MyResult.Ok.call to %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @ThreadMixed(constants.%T.67d) {
// CHECK:STDOUT:   %T.patt.loc37_17.2 => constants.%T.patt.d47
// CHECK:STDOUT:   %T.loc37_17.1 => constants.%T.67d
// CHECK:STDOUT:   %MyResult.loc37_44.1 => constants.%MyResult.f7e
// CHECK:STDOUT:   %pattern_type.loc37 => constants.%pattern_type.071
// CHECK:STDOUT:   %mr.param_patt.loc37_27.2 => constants.%mr.param_patt
// CHECK:STDOUT:   %mr.patt.loc37_27.2 => constants.%mr.patt
// CHECK:STDOUT:   %.loc37_65.3 => constants.%.ff9
// CHECK:STDOUT:   %return.param_patt.loc37_65.2 => constants.%return.param_patt.d89
// CHECK:STDOUT:   %return.patt.loc37_47.2 => constants.%return.patt.300
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- use.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %.Self.frozen: %type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %pattern_type.98f: type = pattern_type type [concrete]
// CHECK:STDOUT:   %T.patt.d47: %pattern_type.98f = symbolic_binding_pattern T, 0 [symbolic]
// CHECK:STDOUT:   %T.67d: type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %E.patt: %pattern_type.98f = symbolic_binding_pattern E, 1 [symbolic]
// CHECK:STDOUT:   %E: type = symbolic_binding E, 1 [symbolic]
// CHECK:STDOUT:   %MyResult.type: type = generic_class_type @MyResult [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %MyResult.generic: %MyResult.type = struct_value () [concrete]
// CHECK:STDOUT:   %tuple.type.17989b.1: type = tuple_type (%E) [symbolic]
// CHECK:STDOUT:   %tuple.type.026b76.1: type = tuple_type (%T.67d) [symbolic]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %u1: type = class_type @UInt, @UInt(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %MyResult: type = class_type @MyResult, @MyResult(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %pattern_type.6db: type = pattern_type %MyResult [symbolic]
// CHECK:STDOUT:   %return.param_patt.296: %pattern_type.6db = out_param_pattern [symbolic]
// CHECK:STDOUT:   %MyResult.Ok.type: type = fn_type @MyResult.Ok, @MyResult(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %MyResult.Ok: %MyResult.Ok.type = struct_value () [symbolic]
// CHECK:STDOUT:   %require_complete.441886.1: <witness> = require_complete_type %E [symbolic]
// CHECK:STDOUT:   %require_complete.9443dd.1: <witness> = require_complete_type %T.67d [symbolic]
// CHECK:STDOUT:   %pattern_type.51d1c4.1: type = pattern_type %T.67d [symbolic]
// CHECK:STDOUT:   %.6c7: Core.Form = init_form %MyResult [symbolic]
// CHECK:STDOUT:   %require_complete.090: <witness> = require_complete_type %MyResult [symbolic]
// CHECK:STDOUT:   %int_1.233: %u1 = int_value 1 [concrete]
// CHECK:STDOUT:   %mr.param_patt: %pattern_type.6db = value_param_pattern [symbolic]
// CHECK:STDOUT:   %mr.patt: %pattern_type.6db = at_binding_pattern mr, %mr.param_patt [symbolic]
// CHECK:STDOUT:   %return.patt.971e: %pattern_type.6db = return_slot_pattern %return.param_patt.296, %MyResult [symbolic]
// CHECK:STDOUT:   %ThreadImported.type: type = fn_type @ThreadImported [concrete]
// CHECK:STDOUT:   %ThreadImported: %ThreadImported.type = struct_value () [concrete]
// CHECK:STDOUT:   %v.patt.291: %pattern_type.51d1c4.1 = value_binding_pattern v [symbolic]
// CHECK:STDOUT:   %Try.type: type = facet_type <@Try> [concrete]
// CHECK:STDOUT:   %Try.impl_witness: <witness> = impl_witness imports.%Try.impl_witness_table, @MyResult.as.Try.impl(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %MyResult.as.Try.impl.FromBreak.type: type = fn_type @MyResult.as.Try.impl.FromBreak, @MyResult.as.Try.impl(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %MyResult.as.Try.impl.FromBreak: %MyResult.as.Try.impl.FromBreak.type = struct_value () [symbolic]
// CHECK:STDOUT:   %MyResult.as.Try.impl.Branch.type: type = fn_type @MyResult.as.Try.impl.Branch, @MyResult.as.Try.impl(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %MyResult.as.Try.impl.Branch: %MyResult.as.Try.impl.Branch.type = struct_value () [symbolic]
// CHECK:STDOUT:   %ControlFlow.eda317.2: type = class_type @ControlFlow, @ControlFlow(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %.bef625.2: type = custom_layout_type {size=0, align=0, .Continue@0: %tuple.type.026b76.1, .Break@0: %tuple.type.17989b.1} [symbolic]
// CHECK:STDOUT:   %Try.facet: %Try.type = facet_value %MyResult, (%Try.impl_witness) [symbolic]
// CHECK:STDOUT:   %Try.WithSelf.Branch.type.8c8: type = fn_type @Try.WithSelf.Branch, @Try.WithSelf(%Try.facet) [symbolic]
// CHECK:STDOUT:   %Try.WithSelf.FromBreak.type.012: type = fn_type @Try.WithSelf.FromBreak, @Try.WithSelf(%Try.facet) [symbolic]
// CHECK:STDOUT:   %.3c0: type = fn_type_with_self_type %Try.WithSelf.Branch.type.8c8, %Try.facet [symbolic]
// CHECK:STDOUT:   %MyResult.as.Try.impl.Branch.specific_fn: <specific function> = specific_function %MyResult.as.Try.impl.Branch, @MyResult.as.Try.impl.Branch(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %ImplicitAs.type.ca1: type = facet_type <@ImplicitAs, @ImplicitAs(%u1)> [concrete]
// CHECK:STDOUT:   %To.fe9: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.b68(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.170: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.f4c: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.f01, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet: %ImplicitAs.type.ca1 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.f4c) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.77c: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%u1, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.e74: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.77c, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.d7a: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
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
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.specific_fn.6b6: <specific function> = specific_function %UInt.as.EqWith.impl.Equal.ba4, @UInt.as.EqWith.impl.Equal.1(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.a82: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
// CHECK:STDOUT:   %.1b2: type = fn_type_with_self_type %Try.WithSelf.FromBreak.type.012, %Try.facet [symbolic]
// CHECK:STDOUT:   %MyResult.as.Try.impl.FromBreak.specific_fn: <specific function> = specific_function %MyResult.as.Try.impl.FromBreak, @MyResult.as.Try.impl.FromBreak(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %Destroy.type: type = facet_type <@Destroy> [concrete]
// CHECK:STDOUT:   %Destroy.lookup_impl_witness: <witness> = lookup_impl_witness %ControlFlow.eda317.2, @Destroy [symbolic]
// CHECK:STDOUT:   %Destroy.facet: %Destroy.type = facet_value %ControlFlow.eda317.2, (%Destroy.lookup_impl_witness) [symbolic]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.16c: type = fn_type @Destroy.WithSelf.Op, @Destroy.WithSelf(%Destroy.facet) [symbolic]
// CHECK:STDOUT:   %.9db: type = fn_type_with_self_type %Destroy.WithSelf.Op.type.16c, %Destroy.facet [symbolic]
// CHECK:STDOUT:   %impl.elem0.ae8: %.9db = impl_witness_access %Destroy.lookup_impl_witness, element0 [symbolic]
// CHECK:STDOUT:   %specific_impl_fn.8f1: <specific function> = specific_impl_function %impl.elem0.ae8, @Destroy.WithSelf.Op(%Destroy.facet) [symbolic]
// CHECK:STDOUT:   %MyResult.Ok.specific_fn: <specific function> = specific_function %MyResult.Ok, @MyResult.Ok(%T.67d, %E) [symbolic]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Main.MyResult: %MyResult.type = import_ref Main//lib, MyResult, loaded [concrete = constants.%MyResult.generic]
// CHECK:STDOUT:   %Main.import_ref.610: @MyResult.%MyResult.Ok.type (%MyResult.Ok.type) = import_ref Main//lib, loc3_35, loaded [symbolic = @MyResult.%MyResult.Ok (constants.%MyResult.Ok)]
// CHECK:STDOUT:   %Main.import_ref.0b3 = import_ref Main//lib, loc19_48, unloaded
// CHECK:STDOUT:   %Main.import_ref.6e9 = import_ref Main//lib, loc19_48, unloaded
// CHECK:STDOUT:   %Main.import_ref.c58: @MyResult.as.Try.impl.%MyResult.as.Try.impl.Branch.type (%MyResult.as.Try.impl.Branch.type) = import_ref Main//lib, loc20_45, loaded [symbolic = @MyResult.as.Try.impl.%MyResult.as.Try.impl.Branch (constants.%MyResult.as.Try.impl.Branch)]
// CHECK:STDOUT:   %Main.import_ref.06a: @MyResult.as.Try.impl.%MyResult.as.Try.impl.FromBreak.type (%MyResult.as.Try.impl.FromBreak.type) = import_ref Main//lib, loc28_30, loaded [symbolic = @MyResult.as.Try.impl.%MyResult.as.Try.impl.FromBreak (constants.%MyResult.as.Try.impl.FromBreak)]
// CHECK:STDOUT:   %Try.impl_witness_table = impl_witness_table (%Main.import_ref.0b3, %Main.import_ref.6e9, %Main.import_ref.c58, %Main.import_ref.06a), @MyResult.as.Try.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.aa5: @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.170)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.f01 = impl_witness_table (%Core.import_ref.aa5), @Core.IntLiteral.as.ImplicitAs.impl.b68 [concrete]
// CHECK:STDOUT:   %Core.import_ref.b92: @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal.type (%UInt.as.EqWith.impl.Equal.type.544) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal (constants.%UInt.as.EqWith.impl.Equal.c67)]
// CHECK:STDOUT:   %Core.import_ref.b44 = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.166 = impl_witness_table (%Core.import_ref.b92, %Core.import_ref.b44), @UInt.as.EqWith.impl.f13 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %ThreadImported.decl: %ThreadImported.type = fn_decl @ThreadImported [concrete = constants.%ThreadImported] {
// CHECK:STDOUT:     %T.patt.loc10_20.1: %pattern_type.98f = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc10_20.2 (constants.%T.patt.d47)]
// CHECK:STDOUT:     %E.patt.loc10_29.1: %pattern_type.98f = symbolic_binding_pattern E, 1 [symbolic = %E.patt.loc10_29.2 (constants.%E.patt)]
// CHECK:STDOUT:     %mr.param_patt.loc10_39.1: @ThreadImported.%pattern_type.loc10 (%pattern_type.6db) = value_param_pattern [symbolic = %mr.param_patt.loc10_39.2 (constants.%mr.param_patt)]
// CHECK:STDOUT:     %mr.patt.loc10_39.1: @ThreadImported.%pattern_type.loc10 (%pattern_type.6db) = at_binding_pattern mr, %mr.param_patt.loc10_39.1 [symbolic = %mr.patt.loc10_39.2 (constants.%mr.patt)]
// CHECK:STDOUT:     %return.param_patt.loc10_73.1: @ThreadImported.%pattern_type.loc10 (%pattern_type.6db) = out_param_pattern [symbolic = %return.param_patt.loc10_73.2 (constants.%return.param_patt.296)]
// CHECK:STDOUT:     %return.patt.loc10_57.1: @ThreadImported.%pattern_type.loc10 (%pattern_type.6db) = return_slot_pattern %return.param_patt.loc10_73.1, %MyResult.loc10_73 [symbolic = %return.patt.loc10_57.2 (constants.%return.patt.971e)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %MyResult.ref.loc10_60: %MyResult.type = name_ref MyResult, imports.%Main.MyResult [concrete = constants.%MyResult.generic]
// CHECK:STDOUT:     %T.ref.loc10_69: type = name_ref T, %T.loc10_20.2 [symbolic = %T.loc10_20.1 (constants.%T.67d)]
// CHECK:STDOUT:     %E.ref.loc10_72: type = name_ref E, %E.loc10_29.2 [symbolic = %E.loc10_29.1 (constants.%E)]
// CHECK:STDOUT:     %MyResult.loc10_73: type = class_type @MyResult, @MyResult(constants.%T.67d, constants.%E) [symbolic = %MyResult.loc10_54.1 (constants.%MyResult)]
// CHECK:STDOUT:     %.loc10_73.4: Core.Form = init_form %MyResult.loc10_73 [symbolic = %.loc10_73.3 (constants.%.6c7)]
// CHECK:STDOUT:     %.loc10_22.1: type = splice_block %.loc10_22.2 [concrete = type] {
// CHECK:STDOUT:       %.Self.frozen.loc10_20: %type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %.loc10_22.2: type = type_literal type [concrete = type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc10_20.2: type = symbolic_binding T, 0 [symbolic = %T.loc10_20.1 (constants.%T.67d)]
// CHECK:STDOUT:     %.loc10_31.1: type = splice_block %.loc10_31.2 [concrete = type] {
// CHECK:STDOUT:       %.Self.frozen.loc10_29: %type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %.loc10_31.2: type = type_literal type [concrete = type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %E.loc10_29.2: type = symbolic_binding E, 1 [symbolic = %E.loc10_29.1 (constants.%E)]
// CHECK:STDOUT:     %mr.param: @ThreadImported.%MyResult.loc10_54.1 (%MyResult) = value_param call_param0
// CHECK:STDOUT:     %.loc10_54: type = splice_block %MyResult.loc10_54.2 [symbolic = %MyResult.loc10_54.1 (constants.%MyResult)] {
// CHECK:STDOUT:       %MyResult.ref.loc10_41: %MyResult.type = name_ref MyResult, imports.%Main.MyResult [concrete = constants.%MyResult.generic]
// CHECK:STDOUT:       %T.ref.loc10_50: type = name_ref T, %T.loc10_20.2 [symbolic = %T.loc10_20.1 (constants.%T.67d)]
// CHECK:STDOUT:       %E.ref.loc10_53: type = name_ref E, %E.loc10_29.2 [symbolic = %E.loc10_29.1 (constants.%E)]
// CHECK:STDOUT:       %MyResult.loc10_54.2: type = class_type @MyResult, @MyResult(constants.%T.67d, constants.%E) [symbolic = %MyResult.loc10_54.1 (constants.%MyResult)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %mr: @ThreadImported.%MyResult.loc10_54.1 (%MyResult) = wrapper_binding mr, %mr.param
// CHECK:STDOUT:     %return.param: ref @ThreadImported.%MyResult.loc10_54.1 (%MyResult) = out_param call_param1
// CHECK:STDOUT:     %return: ref @ThreadImported.%MyResult.loc10_54.1 (%MyResult) = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @ThreadImported(%T.loc10_20.2: type, %E.loc10_29.2: type) {
// CHECK:STDOUT:   %T.patt.loc10_20.2: %pattern_type.98f = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc10_20.2 (constants.%T.patt.d47)]
// CHECK:STDOUT:   %T.loc10_20.1: type = symbolic_binding T, 0 [symbolic = %T.loc10_20.1 (constants.%T.67d)]
// CHECK:STDOUT:   %E.patt.loc10_29.2: %pattern_type.98f = symbolic_binding_pattern E, 1 [symbolic = %E.patt.loc10_29.2 (constants.%E.patt)]
// CHECK:STDOUT:   %E.loc10_29.1: type = symbolic_binding E, 1 [symbolic = %E.loc10_29.1 (constants.%E)]
// CHECK:STDOUT:   %MyResult.loc10_54.1: type = class_type @MyResult, @MyResult(%T.loc10_20.1, %E.loc10_29.1) [symbolic = %MyResult.loc10_54.1 (constants.%MyResult)]
// CHECK:STDOUT:   %pattern_type.loc10: type = pattern_type %MyResult.loc10_54.1 [symbolic = %pattern_type.loc10 (constants.%pattern_type.6db)]
// CHECK:STDOUT:   %mr.param_patt.loc10_39.2: @ThreadImported.%pattern_type.loc10 (%pattern_type.6db) = value_param_pattern [symbolic = %mr.param_patt.loc10_39.2 (constants.%mr.param_patt)]
// CHECK:STDOUT:   %mr.patt.loc10_39.2: @ThreadImported.%pattern_type.loc10 (%pattern_type.6db) = at_binding_pattern mr, %mr.param_patt.loc10_39.2 [symbolic = %mr.patt.loc10_39.2 (constants.%mr.patt)]
// CHECK:STDOUT:   %.loc10_73.3: Core.Form = init_form %MyResult.loc10_54.1 [symbolic = %.loc10_73.3 (constants.%.6c7)]
// CHECK:STDOUT:   %return.param_patt.loc10_73.2: @ThreadImported.%pattern_type.loc10 (%pattern_type.6db) = out_param_pattern [symbolic = %return.param_patt.loc10_73.2 (constants.%return.param_patt.296)]
// CHECK:STDOUT:   %return.patt.loc10_57.2: @ThreadImported.%pattern_type.loc10 (%pattern_type.6db) = return_slot_pattern %return.param_patt.loc10_73.2, %MyResult.loc10_54.1 [symbolic = %return.patt.loc10_57.2 (constants.%return.patt.971e)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc10: <witness> = require_complete_type %MyResult.loc10_54.1 [symbolic = %require_complete.loc10 (constants.%require_complete.090)]
// CHECK:STDOUT:   %require_complete.loc11_10: <witness> = require_complete_type %T.loc10_20.1 [symbolic = %require_complete.loc11_10 (constants.%require_complete.9443dd.1)]
// CHECK:STDOUT:   %pattern_type.loc11: type = pattern_type %T.loc10_20.1 [symbolic = %pattern_type.loc11 (constants.%pattern_type.51d1c4.1)]
// CHECK:STDOUT:   %v.patt.loc11_8.2: @ThreadImported.%pattern_type.loc11 (%pattern_type.51d1c4.1) = value_binding_pattern v [symbolic = %v.patt.loc11_8.2 (constants.%v.patt.291)]
// CHECK:STDOUT:   %Try.impl_witness: <witness> = impl_witness imports.%Try.impl_witness_table, @MyResult.as.Try.impl(%T.loc10_20.1, %E.loc10_29.1) [symbolic = %Try.impl_witness (constants.%Try.impl_witness)]
// CHECK:STDOUT:   %Try.facet.loc11_16.2: %Try.type = facet_value %MyResult.loc10_54.1, (%Try.impl_witness) [symbolic = %Try.facet.loc11_16.2 (constants.%Try.facet)]
// CHECK:STDOUT:   %Try.WithSelf.Branch.type: type = fn_type @Try.WithSelf.Branch, @Try.WithSelf(%Try.facet.loc11_16.2) [symbolic = %Try.WithSelf.Branch.type (constants.%Try.WithSelf.Branch.type.8c8)]
// CHECK:STDOUT:   %.loc11_16.20: type = fn_type_with_self_type %Try.WithSelf.Branch.type, %Try.facet.loc11_16.2 [symbolic = %.loc11_16.20 (constants.%.3c0)]
// CHECK:STDOUT:   %MyResult.as.Try.impl.Branch.type: type = fn_type @MyResult.as.Try.impl.Branch, @MyResult.as.Try.impl(%T.loc10_20.1, %E.loc10_29.1) [symbolic = %MyResult.as.Try.impl.Branch.type (constants.%MyResult.as.Try.impl.Branch.type)]
// CHECK:STDOUT:   %MyResult.as.Try.impl.Branch: @ThreadImported.%MyResult.as.Try.impl.Branch.type (%MyResult.as.Try.impl.Branch.type) = struct_value () [symbolic = %MyResult.as.Try.impl.Branch (constants.%MyResult.as.Try.impl.Branch)]
// CHECK:STDOUT:   %MyResult.as.Try.impl.Branch.specific_fn: <specific function> = specific_function %MyResult.as.Try.impl.Branch, @MyResult.as.Try.impl.Branch(%T.loc10_20.1, %E.loc10_29.1) [symbolic = %MyResult.as.Try.impl.Branch.specific_fn (constants.%MyResult.as.Try.impl.Branch.specific_fn)]
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:   %tuple.type.loc11_16.1: type = tuple_type (%T.loc10_20.1) [symbolic = %tuple.type.loc11_16.1 (constants.%tuple.type.026b76.1)]
// CHECK:STDOUT:   %tuple.type.loc11_16.2: type = tuple_type (%E.loc10_29.1) [symbolic = %tuple.type.loc11_16.2 (constants.%tuple.type.17989b.1)]
// CHECK:STDOUT:   %.loc11_16.21: type = custom_layout_type {size=0, align=0, .Continue@0: @ThreadImported.%tuple.type.loc11_16.1 (%tuple.type.026b76.1), .Break@0: @ThreadImported.%tuple.type.loc11_16.2 (%tuple.type.17989b.1)} [symbolic = %.loc11_16.21 (constants.%.bef625.2)]
// CHECK:STDOUT:   %require_complete.loc11_16: <witness> = require_complete_type %E.loc10_29.1 [symbolic = %require_complete.loc11_16 (constants.%require_complete.441886.1)]
// CHECK:STDOUT:   %Try.WithSelf.FromBreak.type: type = fn_type @Try.WithSelf.FromBreak, @Try.WithSelf(%Try.facet.loc11_16.2) [symbolic = %Try.WithSelf.FromBreak.type (constants.%Try.WithSelf.FromBreak.type.012)]
// CHECK:STDOUT:   %.loc11_16.22: type = fn_type_with_self_type %Try.WithSelf.FromBreak.type, %Try.facet.loc11_16.2 [symbolic = %.loc11_16.22 (constants.%.1b2)]
// CHECK:STDOUT:   %MyResult.as.Try.impl.FromBreak.type: type = fn_type @MyResult.as.Try.impl.FromBreak, @MyResult.as.Try.impl(%T.loc10_20.1, %E.loc10_29.1) [symbolic = %MyResult.as.Try.impl.FromBreak.type (constants.%MyResult.as.Try.impl.FromBreak.type)]
// CHECK:STDOUT:   %MyResult.as.Try.impl.FromBreak: @ThreadImported.%MyResult.as.Try.impl.FromBreak.type (%MyResult.as.Try.impl.FromBreak.type) = struct_value () [symbolic = %MyResult.as.Try.impl.FromBreak (constants.%MyResult.as.Try.impl.FromBreak)]
// CHECK:STDOUT:   %MyResult.as.Try.impl.FromBreak.specific_fn: <specific function> = specific_function %MyResult.as.Try.impl.FromBreak, @MyResult.as.Try.impl.FromBreak(%T.loc10_20.1, %E.loc10_29.1) [symbolic = %MyResult.as.Try.impl.FromBreak.specific_fn (constants.%MyResult.as.Try.impl.FromBreak.specific_fn)]
// CHECK:STDOUT:   %Destroy.lookup_impl_witness: <witness> = lookup_impl_witness %ControlFlow, @Destroy [symbolic = %Destroy.lookup_impl_witness (constants.%Destroy.lookup_impl_witness)]
// CHECK:STDOUT:   %Destroy.facet.loc11_16.5: %Destroy.type = facet_value %ControlFlow, (%Destroy.lookup_impl_witness) [symbolic = %Destroy.facet.loc11_16.5 (constants.%Destroy.facet)]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type: type = fn_type @Destroy.WithSelf.Op, @Destroy.WithSelf(%Destroy.facet.loc11_16.5) [symbolic = %Destroy.WithSelf.Op.type (constants.%Destroy.WithSelf.Op.type.16c)]
// CHECK:STDOUT:   %.loc11_16.23: type = fn_type_with_self_type %Destroy.WithSelf.Op.type, %Destroy.facet.loc11_16.5 [symbolic = %.loc11_16.23 (constants.%.9db)]
// CHECK:STDOUT:   %impl.elem0.loc11_16.5: @ThreadImported.%.loc11_16.23 (%.9db) = impl_witness_access %Destroy.lookup_impl_witness, element0 [symbolic = %impl.elem0.loc11_16.5 (constants.%impl.elem0.ae8)]
// CHECK:STDOUT:   %specific_impl_fn.loc11_16.3: <specific function> = specific_impl_function %impl.elem0.loc11_16.5, @Destroy.WithSelf.Op(%Destroy.facet.loc11_16.5) [symbolic = %specific_impl_fn.loc11_16.3 (constants.%specific_impl_fn.8f1)]
// CHECK:STDOUT:   %MyResult.Ok.type: type = fn_type @MyResult.Ok, @MyResult(%T.loc10_20.1, %E.loc10_29.1) [symbolic = %MyResult.Ok.type (constants.%MyResult.Ok.type)]
// CHECK:STDOUT:   %MyResult.Ok: @ThreadImported.%MyResult.Ok.type (%MyResult.Ok.type) = struct_value () [symbolic = %MyResult.Ok (constants.%MyResult.Ok)]
// CHECK:STDOUT:   %MyResult.Ok.specific_fn.loc12_24.2: <specific function> = specific_function %MyResult.Ok, @MyResult.Ok(%T.loc10_20.1, %E.loc10_29.1) [symbolic = %MyResult.Ok.specific_fn.loc12_24.2 (constants.%MyResult.Ok.specific_fn)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%mr.param: @ThreadImported.%MyResult.loc10_54.1 (%MyResult)) -> out %return.param: @ThreadImported.%MyResult.loc10_54.1 (%MyResult) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %mr.ref: @ThreadImported.%MyResult.loc10_54.1 (%MyResult) = name_ref mr, %mr
// CHECK:STDOUT:     %impl.elem2: @ThreadImported.%.loc11_16.20 (%.3c0) = impl_witness_access constants.%Try.impl_witness, element2 [symbolic = %MyResult.as.Try.impl.Branch (constants.%MyResult.as.Try.impl.Branch)]
// CHECK:STDOUT:     %bound_method.loc11_16.1: <bound method> = bound_method %mr.ref, %impl.elem2
// CHECK:STDOUT:     %specific_fn.loc11_16.1: <specific function> = specific_function %impl.elem2, @MyResult.as.Try.impl.Branch(constants.%T.67d, constants.%E) [symbolic = %MyResult.as.Try.impl.Branch.specific_fn (constants.%MyResult.as.Try.impl.Branch.specific_fn)]
// CHECK:STDOUT:     %bound_method.loc11_16.2: <bound method> = bound_method %mr.ref, %specific_fn.loc11_16.1
// CHECK:STDOUT:     %.loc11_16.1: ref @ThreadImported.%ControlFlow (%ControlFlow.eda317.2) = temporary_storage
// CHECK:STDOUT:     %MyResult.as.Try.impl.Branch.call: init @ThreadImported.%ControlFlow (%ControlFlow.eda317.2) to %.loc11_16.1 = call %bound_method.loc11_16.2(%mr.ref)
// CHECK:STDOUT:     %.loc11_16.2: ref @ThreadImported.%ControlFlow (%ControlFlow.eda317.2) = temporary %.loc11_16.1, %MyResult.as.Try.impl.Branch.call
// CHECK:STDOUT:     %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:     %impl.elem0.loc11_16.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:     %bound_method.loc11_16.3: <bound method> = bound_method %int_1, %impl.elem0.loc11_16.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound]
// CHECK:STDOUT:     %specific_fn.loc11_16.2: <specific function> = specific_function %impl.elem0.loc11_16.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:     %bound_method.loc11_16.4: <bound method> = bound_method %int_1, %specific_fn.loc11_16.2 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %u1 = call %bound_method.loc11_16.4(%int_1) [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc11_16.3: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc11_16.4: %u1 = converted %int_1, %.loc11_16.3 [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc11_16.5: ref %u1 = class_element_access %.loc11_16.2, element0
// CHECK:STDOUT:     %impl.elem0.loc11_16.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:     %bound_method.loc11_16.5: <bound method> = bound_method %.loc11_16.4, %impl.elem0.loc11_16.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound]
// CHECK:STDOUT:     %specific_fn.loc11_16.3: <specific function> = specific_function %impl.elem0.loc11_16.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:     %bound_method.loc11_16.6: <bound method> = bound_method %.loc11_16.4, %specific_fn.loc11_16.3 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:     %.loc11_16.6: %u1 = acquire_value %.loc11_16.5
// CHECK:STDOUT:     %UInt.as.EqWith.impl.Equal.call: init bool = call %bound_method.loc11_16.6(%.loc11_16.4, %.loc11_16.6)
// CHECK:STDOUT:     %.loc11_16.7: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call
// CHECK:STDOUT:     %.loc11_16.8: bool = converted %UInt.as.EqWith.impl.Equal.call, %.loc11_16.7
// CHECK:STDOUT:     if %.loc11_16.8 br !.loc11_16.1 else br !.loc11_16.2
// CHECK:STDOUT:
// CHECK:STDOUT:   !.loc11_16.1:
// CHECK:STDOUT:     %.loc11_16.9: ref @ThreadImported.%.loc11_16.21 (%.bef625.2) = class_element_access %.loc11_16.2, element1
// CHECK:STDOUT:     %.loc11_16.10: ref @ThreadImported.%tuple.type.loc11_16.2 (%tuple.type.17989b.1) = class_element_access %.loc11_16.9, element1
// CHECK:STDOUT:     %tuple.elem0.loc11_16.1: ref @ThreadImported.%E.loc10_29.1 (%E) = tuple_access %.loc11_16.10, element0
// CHECK:STDOUT:     %.loc11_16.11: @ThreadImported.%E.loc10_29.1 (%E) = acquire_value %tuple.elem0.loc11_16.1
// CHECK:STDOUT:     %Try.facet.loc11_16.1: %Try.type = facet_value constants.%MyResult, (constants.%Try.impl_witness) [symbolic = %Try.facet.loc11_16.2 (constants.%Try.facet)]
// CHECK:STDOUT:     %.loc11_16.12: %Try.type = converted constants.%MyResult, %Try.facet.loc11_16.1 [symbolic = %Try.facet.loc11_16.2 (constants.%Try.facet)]
// CHECK:STDOUT:     %impl.elem3: @ThreadImported.%.loc11_16.22 (%.1b2) = impl_witness_access constants.%Try.impl_witness, element3 [symbolic = %MyResult.as.Try.impl.FromBreak (constants.%MyResult.as.Try.impl.FromBreak)]
// CHECK:STDOUT:     %specific_fn.loc11_16.4: <specific function> = specific_function %impl.elem3, @MyResult.as.Try.impl.FromBreak(constants.%T.67d, constants.%E) [symbolic = %MyResult.as.Try.impl.FromBreak.specific_fn (constants.%MyResult.as.Try.impl.FromBreak.specific_fn)]
// CHECK:STDOUT:     %.loc10_73.1: ref @ThreadImported.%MyResult.loc10_54.1 (%MyResult) = splice_block %return.param {}
// CHECK:STDOUT:     %MyResult.as.Try.impl.FromBreak.call: init @ThreadImported.%MyResult.loc10_54.1 (%MyResult) to %.loc10_73.1 = call %specific_fn.loc11_16.4(%.loc11_16.11)
// CHECK:STDOUT:     %impl.elem0.loc11_16.3: @ThreadImported.%.loc11_16.23 (%.9db) = impl_witness_access constants.%Destroy.lookup_impl_witness, element0 [symbolic = %impl.elem0.loc11_16.5 (constants.%impl.elem0.ae8)]
// CHECK:STDOUT:     %bound_method.loc11_16.7: <bound method> = bound_method %.loc11_16.2, %impl.elem0.loc11_16.3
// CHECK:STDOUT:     %Destroy.facet.loc11_16.1: %Destroy.type = facet_value constants.%ControlFlow.eda317.2, (constants.%Destroy.lookup_impl_witness) [symbolic = %Destroy.facet.loc11_16.5 (constants.%Destroy.facet)]
// CHECK:STDOUT:     %.loc11_16.13: %Destroy.type = converted constants.%ControlFlow.eda317.2, %Destroy.facet.loc11_16.1 [symbolic = %Destroy.facet.loc11_16.5 (constants.%Destroy.facet)]
// CHECK:STDOUT:     %Destroy.facet.loc11_16.2: %Destroy.type = facet_value constants.%ControlFlow.eda317.2, (constants.%Destroy.lookup_impl_witness) [symbolic = %Destroy.facet.loc11_16.5 (constants.%Destroy.facet)]
// CHECK:STDOUT:     %.loc11_16.14: %Destroy.type = converted constants.%ControlFlow.eda317.2, %Destroy.facet.loc11_16.2 [symbolic = %Destroy.facet.loc11_16.5 (constants.%Destroy.facet)]
// CHECK:STDOUT:     %specific_impl_fn.loc11_16.1: <specific function> = specific_impl_function %impl.elem0.loc11_16.3, @Destroy.WithSelf.Op(constants.%Destroy.facet) [symbolic = %specific_impl_fn.loc11_16.3 (constants.%specific_impl_fn.8f1)]
// CHECK:STDOUT:     %bound_method.loc11_16.8: <bound method> = bound_method %.loc11_16.2, %specific_impl_fn.loc11_16.1
// CHECK:STDOUT:     %Destroy.WithSelf.Op.call.loc11_16.1: init %empty_tuple.type = call %bound_method.loc11_16.8(%.loc11_16.2)
// CHECK:STDOUT:     return %MyResult.as.Try.impl.FromBreak.call to %return.param
// CHECK:STDOUT:
// CHECK:STDOUT:   !.loc11_16.2:
// CHECK:STDOUT:     %.loc11_16.15: ref @ThreadImported.%.loc11_16.21 (%.bef625.2) = class_element_access %.loc11_16.2, element1
// CHECK:STDOUT:     %.loc11_16.16: ref @ThreadImported.%tuple.type.loc11_16.1 (%tuple.type.026b76.1) = class_element_access %.loc11_16.15, element0
// CHECK:STDOUT:     %tuple.elem0.loc11_16.2: ref @ThreadImported.%T.loc10_20.1 (%T.67d) = tuple_access %.loc11_16.16, element0
// CHECK:STDOUT:     %.loc11_16.17: @ThreadImported.%T.loc10_20.1 (%T.67d) = acquire_value %tuple.elem0.loc11_16.2
// CHECK:STDOUT:     %T.ref.loc11: type = name_ref T, %T.loc10_20.2 [symbolic = %T.loc10_20.1 (constants.%T.67d)]
// CHECK:STDOUT:     %v: @ThreadImported.%T.loc10_20.1 (%T.67d) = wrapper_binding v, %.loc11_16.17
// CHECK:STDOUT:     name_binding_decl {
// CHECK:STDOUT:       %v.patt.loc11_8.1: @ThreadImported.%pattern_type.loc11 (%pattern_type.51d1c4.1) = value_binding_pattern v [symbolic = %v.patt.loc11_8.2 (constants.%v.patt.291)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %MyResult.ref.loc12: %MyResult.type = name_ref MyResult, imports.%Main.MyResult [concrete = constants.%MyResult.generic]
// CHECK:STDOUT:     %T.ref.loc12: type = name_ref T, %T.loc10_20.2 [symbolic = %T.loc10_20.1 (constants.%T.67d)]
// CHECK:STDOUT:     %E.ref.loc12: type = name_ref E, %E.loc10_29.2 [symbolic = %E.loc10_29.1 (constants.%E)]
// CHECK:STDOUT:     %MyResult.loc12: type = class_type @MyResult, @MyResult(constants.%T.67d, constants.%E) [symbolic = %MyResult.loc10_54.1 (constants.%MyResult)]
// CHECK:STDOUT:     %.loc12: @ThreadImported.%MyResult.Ok.type (%MyResult.Ok.type) = specific_constant imports.%Main.import_ref.610, @MyResult(constants.%T.67d, constants.%E) [symbolic = %MyResult.Ok (constants.%MyResult.Ok)]
// CHECK:STDOUT:     %Ok.ref: @ThreadImported.%MyResult.Ok.type (%MyResult.Ok.type) = name_ref Ok, %.loc12 [symbolic = %MyResult.Ok (constants.%MyResult.Ok)]
// CHECK:STDOUT:     %v.ref: @ThreadImported.%T.loc10_20.1 (%T.67d) = name_ref v, %v
// CHECK:STDOUT:     %MyResult.Ok.specific_fn.loc12_24.1: <specific function> = specific_function %Ok.ref, @MyResult.Ok(constants.%T.67d, constants.%E) [symbolic = %MyResult.Ok.specific_fn.loc12_24.2 (constants.%MyResult.Ok.specific_fn)]
// CHECK:STDOUT:     %.loc10_73.2: ref @ThreadImported.%MyResult.loc10_54.1 (%MyResult) = splice_block %return.param {}
// CHECK:STDOUT:     %MyResult.Ok.call: init @ThreadImported.%MyResult.loc10_54.1 (%MyResult) to %.loc10_73.2 = call %MyResult.Ok.specific_fn.loc12_24.1(%v.ref)
// CHECK:STDOUT:     %impl.elem0.loc11_16.4: @ThreadImported.%.loc11_16.23 (%.9db) = impl_witness_access constants.%Destroy.lookup_impl_witness, element0 [symbolic = %impl.elem0.loc11_16.5 (constants.%impl.elem0.ae8)]
// CHECK:STDOUT:     %bound_method.loc11_16.9: <bound method> = bound_method %.loc11_16.2, %impl.elem0.loc11_16.4
// CHECK:STDOUT:     %Destroy.facet.loc11_16.3: %Destroy.type = facet_value constants.%ControlFlow.eda317.2, (constants.%Destroy.lookup_impl_witness) [symbolic = %Destroy.facet.loc11_16.5 (constants.%Destroy.facet)]
// CHECK:STDOUT:     %.loc11_16.18: %Destroy.type = converted constants.%ControlFlow.eda317.2, %Destroy.facet.loc11_16.3 [symbolic = %Destroy.facet.loc11_16.5 (constants.%Destroy.facet)]
// CHECK:STDOUT:     %Destroy.facet.loc11_16.4: %Destroy.type = facet_value constants.%ControlFlow.eda317.2, (constants.%Destroy.lookup_impl_witness) [symbolic = %Destroy.facet.loc11_16.5 (constants.%Destroy.facet)]
// CHECK:STDOUT:     %.loc11_16.19: %Destroy.type = converted constants.%ControlFlow.eda317.2, %Destroy.facet.loc11_16.4 [symbolic = %Destroy.facet.loc11_16.5 (constants.%Destroy.facet)]
// CHECK:STDOUT:     %specific_impl_fn.loc11_16.2: <specific function> = specific_impl_function %impl.elem0.loc11_16.4, @Destroy.WithSelf.Op(constants.%Destroy.facet) [symbolic = %specific_impl_fn.loc11_16.3 (constants.%specific_impl_fn.8f1)]
// CHECK:STDOUT:     %bound_method.loc11_16.10: <bound method> = bound_method %.loc11_16.2, %specific_impl_fn.loc11_16.2
// CHECK:STDOUT:     %Destroy.WithSelf.Op.call.loc11_16.2: init %empty_tuple.type = call %bound_method.loc11_16.10(%.loc11_16.2)
// CHECK:STDOUT:     return %MyResult.Ok.call to %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @ThreadImported(constants.%T.67d, constants.%E) {
// CHECK:STDOUT:   %T.patt.loc10_20.2 => constants.%T.patt.d47
// CHECK:STDOUT:   %T.loc10_20.1 => constants.%T.67d
// CHECK:STDOUT:   %E.patt.loc10_29.2 => constants.%E.patt
// CHECK:STDOUT:   %E.loc10_29.1 => constants.%E
// CHECK:STDOUT:   %MyResult.loc10_54.1 => constants.%MyResult
// CHECK:STDOUT:   %pattern_type.loc10 => constants.%pattern_type.6db
// CHECK:STDOUT:   %mr.param_patt.loc10_39.2 => constants.%mr.param_patt
// CHECK:STDOUT:   %mr.patt.loc10_39.2 => constants.%mr.patt
// CHECK:STDOUT:   %.loc10_73.3 => constants.%.6c7
// CHECK:STDOUT:   %return.param_patt.loc10_73.2 => constants.%return.param_patt.296
// CHECK:STDOUT:   %return.patt.loc10_57.2 => constants.%return.patt.971e
// CHECK:STDOUT: }
// CHECK:STDOUT:
