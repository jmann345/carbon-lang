// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/choice_generic_payload_scrutinee.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/choice_generic_payload_scrutinee.carbon

// Risk R-2's counter-programs: scrutinee values of a payload-carrying generic
// choice produced by paths that complete NOTHING on the way in. The match
// gate's forced completion (`RequireCompleteType` at `MatchCondition`,
// W5-S3a) is what resolves the specific — with its payload-layout recompute
// and SF-6 check — before any repr read; without the forcing, `GetObjectRepr`
// on the unresolved specific would die on the value-block CHECK
// (sem_ir/generic.cpp).

// --- pointer_deref.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
choice P(T: type) {
  Both(x: T, y: T),
  Neither
}

// A pointer dereference completes nothing: completion has no nested
// `PointerType` case, a pointer's value representation is a copy, and
// `PerformPointerDereference` reads no representation. Only the match's own
// forcing establishes the pointee specific's layout.
fn F(p: P(i64)*) -> i32 {
  match (*p) {
    case .Neither => { return 0; }
    default => { return 1; }
  }
}
//@dump-sem-ir-end

// --- plib.carbon
library "plib";

choice P(T: type) {
  Both(x: T, y: T),
  Neither
}

fn MakeRuntime() -> P(i64) { return P(i64).Both(1, 2); }

// The RESTORED cross-file split's defining side (the W-069 ledger
// acceptance shape, upgraded to the RUNTIME-bound form per fork/w069/plan.md
// §8-A OQ-3): `g` binds through a function call, so its bound value has no
// constant and the importer's reference is served only by the promoted
// backing global at lowering (the W69b pointer-value-rep arm; lower-side pin
// in lower/testdata/let/import_choice.carbon).
//@dump-sem-ir-begin
let g: P(i64) = MakeRuntime();
//@dump-sem-ir-end

// The half-(b) boundary pin: a CONSTANT-bound sibling keeps importing as
// the alternative's constant (import_ref.cpp's non-constant-binding branch,
// landed at W5-S3b), never the promoted global.
//@dump-sem-ir-begin
let gc: P(i64) = P(i64).Neither;
//@dump-sem-ir-end

// --- imported_global.carbon
library "[[@TEST_NAME]]";

import library "plib";

// The importing side of the restored split: `g` is bound in plib to a
// runtime `MakeRuntime()` call and matched here. This split previously
// CRASHED lowering (function_context.cpp's missing-value CHECK — the W-069
// ledger item); check has always accepted it, which this golden pins. The
// choice and its specific are imported, so the R-2 question stands: nothing
// in this file defines `P`, and the match gate's forcing resolves the
// specific's definition — with the payload recompute — here.

//@dump-sem-ir-begin
fn F() -> i32 {
  match (g) {
    case .Neither => { return 0; }
    default => { return 1; }
  }
}
//@dump-sem-ir-end

// --- imported_global_constant.carbon
library "[[@TEST_NAME]]";

import library "plib";

// The constant-bound sibling consumed cross-file: `gc` imports with a
// `[concrete = ...]` constant (half (b)) and rides the constant path — the
// explicit boundary showing that the RUNTIME restoration above, not the
// constant binding, is what arbitrates the W-069 residue.

//@dump-sem-ir-begin
fn G() -> i32 {
  match (gc) {
    case .Neither => { return 0; }
    default => { return 1; }
  }
}
//@dump-sem-ir-end

// --- fail_all_payloads_rejected.carbon
library "[[@TEST_NAME]]";

// Plan §2.5(ii): a specific ALL of whose payloads are rejected degrades at
// the SCRUTINEE gate, not the exhaustiveness bail — the error witness makes
// `GetObjectRepr` return the error type, so `GetChoiceDiscriminantType`
// returns no discriminant and the match keeps the scrutinee TODO.
class C {}

choice P(T: type) {
  A(x: T),
  B(y: T)
}

// CHECK:STDERR: fail_all_payloads_rejected.carbon:[[@LINE+7]]:6: error: parameter has incomplete type `P(C)` in function definition [IncompleteTypeInFunctionParam]
// CHECK:STDERR: fn F(p: P(C)) -> i32 {
// CHECK:STDERR:      ^~~~~~~
// CHECK:STDERR: fail_all_payloads_rejected.carbon:[[@LINE-8]]:1: note: choice alternative payload type `C` is not trivially copyable and destructible in this specific [ChoicePayloadNotTrivialInSpecific]
// CHECK:STDERR: choice P(T: type) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn F(p: P(C)) -> i32 {
  // CHECK:STDERR: fail_all_payloads_rejected.carbon:[[@LINE+4]]:9: error: semantics TODO: `match on unsupported scrutinee type` [SemanticsTodo]
  // CHECK:STDERR:   match (p) {
  // CHECK:STDERR:         ^~~
  // CHECK:STDERR:
  match (p) {
    default => { return 0; }
  }
  return -1;
}

// --- by_value_param.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
choice P(T: type) {
  Both(x: T, y: T),
  Neither
}

// The by-value-param PASSING pin (not a falsifier): parameter setup already
// completes the type, and the match's forcing is then a no-op.
fn F(p: P(i32)) -> i32 {
  match (p) {
    case .Neither => { return 0; }
    default => { return 1; }
  }
}

fn Call() -> i32 {
  let n: P(i32) = P(i32).Neither;
  return F(n);
}
//@dump-sem-ir-end

// CHECK:STDOUT: --- pointer_deref.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %.Self.frozen: %type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %pattern_type.98f: type = pattern_type type [concrete]
// CHECK:STDOUT:   %T.patt.d47: %pattern_type.98f = symbolic_binding_pattern T, 0 [symbolic]
// CHECK:STDOUT:   %T.67d: type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %P.type: type = generic_class_type @P [concrete]
// CHECK:STDOUT:   %P.generic: %P.type = struct_value () [concrete]
// CHECK:STDOUT:   %P.f86: type = class_type @P, @P(%T.67d) [symbolic]
// CHECK:STDOUT:   %pattern_type.51d1c4.1: type = pattern_type %T.67d [symbolic]
// CHECK:STDOUT:   %x.param_patt.91d: %pattern_type.51d1c4.1 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %x.patt.260: %pattern_type.51d1c4.1 = wrapper_binding_pattern x, %x.param_patt.91d [symbolic]
// CHECK:STDOUT:   %y.param_patt.be3: %pattern_type.51d1c4.1 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %y.patt.678: %pattern_type.51d1c4.1 = wrapper_binding_pattern y, %y.param_patt.be3 [symbolic]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %u1: type = class_type @UInt, @UInt(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %require_complete.944: <witness> = require_complete_type %T.67d [symbolic]
// CHECK:STDOUT:   %tuple.type.07a: type = tuple_type (%T.67d, %T.67d) [symbolic]
// CHECK:STDOUT:   %.d27: type = custom_layout_type {size=0, align=0, .Both@0: %tuple.type.07a} [symbolic]
// CHECK:STDOUT:   %struct_type.discriminant.payload.1ec: type = struct_type {.discriminant: %u1, .payload: %.d27} [symbolic]
// CHECK:STDOUT:   %complete_type.d2c: <witness> = complete_type_witness %struct_type.discriminant.payload.1ec [symbolic]
// CHECK:STDOUT:   %struct_type.discriminant: type = struct_type {.discriminant: %u1} [concrete]
// CHECK:STDOUT:   %_.param_patt: %pattern_type.51d1c4.1 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %_.patt: %pattern_type.51d1c4.1 = wrapper_binding_pattern _, %_.param_patt [symbolic]
// CHECK:STDOUT:   %.3a8: Core.Form = init_form %P.f86 [symbolic]
// CHECK:STDOUT:   %pattern_type.6d3: type = pattern_type %P.f86 [symbolic]
// CHECK:STDOUT:   %return.param_patt.3b8: %pattern_type.6d3 = out_param_pattern [symbolic]
// CHECK:STDOUT:   %return.patt.ec6: %pattern_type.6d3 = return_slot_pattern %return.param_patt.3b8, %P.f86 [symbolic]
// CHECK:STDOUT:   %P.Both.type.e35: type = fn_type @P.Both, @P(%T.67d) [symbolic]
// CHECK:STDOUT:   %P.Both.862: %P.Both.type.e35 = struct_value () [symbolic]
// CHECK:STDOUT:   %require_complete.657: <witness> = require_complete_type %P.f86 [symbolic]
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
// CHECK:STDOUT:   %uninit.216: %.d27 = uninitialized_value [symbolic]
// CHECK:STDOUT:   %P.val.5d5: %P.f86 = struct_value (%int_0.1a7, %uninit.216) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %bound_method.d7a: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
// CHECK:STDOUT:   %int_1.233: %u1 = int_value 1 [concrete]
// CHECK:STDOUT:   %struct: %struct_type.discriminant = struct_value (%int_1.233) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.type.0c5: type = fn_type @UInt.as.Copy.impl.Op, @UInt.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.38a: %UInt.as.Copy.impl.Op.type.0c5 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.334: <witness> = impl_witness imports.%Copy.impl_witness_table.ae7, @UInt.as.Copy.impl(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.type.c97: type = fn_type @UInt.as.Copy.impl.Op, @UInt.as.Copy.impl(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.d9c: %UInt.as.Copy.impl.Op.type.c97 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet: %Copy.type = facet_value %u1, (%Copy.impl_witness.334) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.703: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet) [concrete]
// CHECK:STDOUT:   %.952: type = fn_type_with_self_type %Copy.WithSelf.Op.type.703, %Copy.facet [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.bound: <bound method> = bound_method %int_1.233, %UInt.as.Copy.impl.Op.d9c [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %UInt.as.Copy.impl.Op.d9c, @UInt.as.Copy.impl.Op(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.edd: <bound method> = bound_method %int_1.233, %UInt.as.Copy.impl.Op.specific_fn [concrete]
// CHECK:STDOUT:   %P.val.a40: %P.f86 = struct_value (%int_1.233, %uninit.216) [symbolic]
// CHECK:STDOUT:   %.a21: ref %P.f86 = temporary invalid, %P.val.a40 [symbolic]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %P.4ae: type = class_type @P, @P(%i64) [concrete]
// CHECK:STDOUT:   %ptr.1ec: type = ptr_type %P.4ae [concrete]
// CHECK:STDOUT:   %pattern_type.d88: type = pattern_type %ptr.1ec [concrete]
// CHECK:STDOUT:   %p.param_patt: %pattern_type.d88 = value_param_pattern [concrete]
// CHECK:STDOUT:   %p.patt: %pattern_type.d88 = wrapper_binding_pattern p, %p.param_patt [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.f57: type = pattern_type %i64 [concrete]
// CHECK:STDOUT:   %x.param_patt.7b8: %pattern_type.f57 = value_param_pattern [concrete]
// CHECK:STDOUT:   %x.patt.5d3: %pattern_type.f57 = wrapper_binding_pattern x, %x.param_patt.7b8 [concrete]
// CHECK:STDOUT:   %y.param_patt.83d: %pattern_type.f57 = value_param_pattern [concrete]
// CHECK:STDOUT:   %y.patt.fca: %pattern_type.f57 = wrapper_binding_pattern y, %y.param_patt.83d [concrete]
// CHECK:STDOUT:   %i64.builtin: type = int_type signed, %int_64 [concrete]
// CHECK:STDOUT:   %complete_type.4a1: <witness> = complete_type_witness %i64.builtin [concrete]
// CHECK:STDOUT:   %tuple.type.1ac: type = tuple_type (%i64, %i64) [concrete]
// CHECK:STDOUT:   %.58e: type = custom_layout_type {size=16, align=8, .Both@0: %tuple.type.1ac} [concrete]
// CHECK:STDOUT:   %struct_type.discriminant.payload.8ac: type = struct_type {.discriminant: %u1, .payload: %.58e} [concrete]
// CHECK:STDOUT:   %complete_type.ab0: <witness> = complete_type_witness %struct_type.discriminant.payload.8ac [concrete]
// CHECK:STDOUT:   %P.Both.type.b26: type = fn_type @P.Both, @P(%i64) [concrete]
// CHECK:STDOUT:   %P.Both.815: %P.Both.type.b26 = struct_value () [concrete]
// CHECK:STDOUT:   %uninit.ccc: %.58e = uninitialized_value [concrete]
// CHECK:STDOUT:   %P.val.c4c: %P.4ae = struct_value (%int_1.233, %uninit.ccc) [concrete]
// CHECK:STDOUT:   %.efe: ref %P.4ae = temporary invalid, %P.val.c4c [concrete]
// CHECK:STDOUT:   %pattern_type.d17: type = pattern_type %P.4ae [concrete]
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
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.953: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.aa5: @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.170)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.f01 = impl_witness_table (%Core.import_ref.aa5), @Core.IntLiteral.as.ImplicitAs.impl.b68 [concrete]
// CHECK:STDOUT:   %Core.import_ref.791: @UInt.as.Copy.impl.%UInt.as.Copy.impl.Op.type (%UInt.as.Copy.impl.Op.type.0c5) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.Copy.impl.%UInt.as.Copy.impl.Op (constants.%UInt.as.Copy.impl.Op.38a)]
// CHECK:STDOUT:   %Copy.impl_witness_table.ae7 = impl_witness_table (%Core.import_ref.791), @UInt.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.b92: @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal.type (%UInt.as.EqWith.impl.Equal.type.544) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal (constants.%UInt.as.EqWith.impl.Equal.c67)]
// CHECK:STDOUT:   %Core.import_ref.b44 = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.166 = impl_witness_table (%Core.import_ref.b92, %Core.import_ref.b44), @UInt.as.EqWith.impl.f13 [concrete]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %P.Both.decl: @P.%P.Both.type (%P.Both.type.e35) = fn_decl @P.Both [symbolic = @P.%P.Both (constants.%P.Both.862)] {
// CHECK:STDOUT:     %_.param_patt.loc4_19.1: @P.Both.%pattern_type.loc4_19.1 (%pattern_type.51d1c4.1) = value_param_pattern [symbolic = %_.param_patt.loc4_19.3 (constants.%_.param_patt)]
// CHECK:STDOUT:     %_.patt.loc4_19.1: @P.Both.%pattern_type.loc4_19.1 (%pattern_type.51d1c4.1) = wrapper_binding_pattern _, %_.param_patt.loc4_19.1 [symbolic = %_.patt.loc4_19.3 (constants.%_.patt)]
// CHECK:STDOUT:     %_.param_patt.loc4_19.2: @P.Both.%pattern_type.loc4_19.1 (%pattern_type.51d1c4.1) = value_param_pattern [symbolic = %_.param_patt.loc4_19.3 (constants.%_.param_patt)]
// CHECK:STDOUT:     %_.patt.loc4_19.2: @P.Both.%pattern_type.loc4_19.1 (%pattern_type.51d1c4.1) = wrapper_binding_pattern _, %_.param_patt.loc4_19.2 [symbolic = %_.patt.loc4_19.3 (constants.%_.patt)]
// CHECK:STDOUT:     %return.param_patt.loc4_19.1: @P.Both.%pattern_type.loc4_19.2 (%pattern_type.6d3) = out_param_pattern [symbolic = %return.param_patt.loc4_19.2 (constants.%return.param_patt.3b8)]
// CHECK:STDOUT:     %return.patt.loc4_19.1: @P.Both.%pattern_type.loc4_19.2 (%pattern_type.6d3) = return_slot_pattern %return.param_patt.loc4_19.1, %P.loc4_19.2 [symbolic = %return.patt.loc4_19.2 (constants.%return.patt.ec6)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %P.loc4_19.2: type = class_type @P, @P(constants.%T.67d) [symbolic = %P.loc4_19.1 (constants.%P.f86)]
// CHECK:STDOUT:     %.loc4_19.11: Core.Form = init_form %P.loc4_19.2 [symbolic = %.loc4_19.9 (constants.%.3a8)]
// CHECK:STDOUT:     %_.param.loc4_19.1: @P.Both.%T (%T.67d) = value_param call_param0
// CHECK:STDOUT:     %_.loc4_19.1: @P.Both.%T (%T.67d) = wrapper_binding _, %_.param.loc4_19.1
// CHECK:STDOUT:     %_.param.loc4_19.2: @P.Both.%T (%T.67d) = value_param call_param1
// CHECK:STDOUT:     %_.loc4_19.2: @P.Both.%T (%T.67d) = wrapper_binding _, %_.param.loc4_19.2
// CHECK:STDOUT:     %return.param: ref @P.Both.%P.loc4_19.1 (%P.f86) = out_param call_param2
// CHECK:STDOUT:     %return: ref @P.Both.%P.loc4_19.1 (%P.f86) = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %P.decl: %P.type = class_decl @P [concrete = constants.%P.generic] {
// CHECK:STDOUT:     %T.patt.loc4_11.1: %pattern_type.98f = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc4_11.2 (constants.%T.patt.d47)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc4_13.1: type = splice_block %.loc4_13.2 [concrete = type] {
// CHECK:STDOUT:       %.Self.frozen: %type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %.loc4_13.2: type = type_literal type [concrete = type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc4_11.2: type = symbolic_binding T, 0 [symbolic = %T.loc4_11.1 (constants.%T.67d)]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %F.decl: %F.type = fn_decl @F [concrete = constants.%F] {
// CHECK:STDOUT:     %p.param_patt: %pattern_type.d88 = value_param_pattern [concrete = constants.%p.param_patt]
// CHECK:STDOUT:     %p.patt: %pattern_type.d88 = wrapper_binding_pattern p, %p.param_patt [concrete = constants.%p.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc13_21: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %p.param: %ptr.1ec = value_param call_param0
// CHECK:STDOUT:     %.loc13_15: type = splice_block %ptr [concrete = constants.%ptr.1ec] {
// CHECK:STDOUT:       %P.ref: %P.type = name_ref P, file.%P.decl [concrete = constants.%P.generic]
// CHECK:STDOUT:       %i64: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:       %P: type = class_type @P, @P(constants.%i64) [concrete = constants.%P.4ae]
// CHECK:STDOUT:       %ptr: type = ptr_type %P [concrete = constants.%ptr.1ec]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %p: %ptr.1ec = wrapper_binding p, %p.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic class @P(%T.loc4_11.2: type) {
// CHECK:STDOUT:   %T.patt.loc4_11.2: %pattern_type.98f = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc4_11.2 (constants.%T.patt.d47)]
// CHECK:STDOUT:   %T.loc4_11.1: type = symbolic_binding T, 0 [symbolic = %T.loc4_11.1 (constants.%T.67d)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %pattern_type: type = pattern_type %T.loc4_11.1 [symbolic = %pattern_type (constants.%pattern_type.51d1c4.1)]
// CHECK:STDOUT:   %x.param_patt: @P.%pattern_type (%pattern_type.51d1c4.1) = value_param_pattern [symbolic = %x.param_patt (constants.%x.param_patt.91d)]
// CHECK:STDOUT:   %x.patt: @P.%pattern_type (%pattern_type.51d1c4.1) = wrapper_binding_pattern x, %x.param_patt [symbolic = %x.patt (constants.%x.patt.260)]
// CHECK:STDOUT:   %y.param_patt: @P.%pattern_type (%pattern_type.51d1c4.1) = value_param_pattern [symbolic = %y.param_patt (constants.%y.param_patt.be3)]
// CHECK:STDOUT:   %y.patt: @P.%pattern_type (%pattern_type.51d1c4.1) = wrapper_binding_pattern y, %y.param_patt [symbolic = %y.patt (constants.%y.patt.678)]
// CHECK:STDOUT:   %require_complete.loc5: <witness> = require_complete_type %T.loc4_11.1 [symbolic = %require_complete.loc5 (constants.%require_complete.944)]
// CHECK:STDOUT:   %tuple.type: type = tuple_type (%T.loc4_11.1, %T.loc4_11.1) [symbolic = %tuple.type (constants.%tuple.type.07a)]
// CHECK:STDOUT:   %.loc7_1.14: type = custom_layout_type {size=0, align=0, .Both@0: @P.%tuple.type (%tuple.type.07a)} [symbolic = %.loc7_1.14 (constants.%.d27)]
// CHECK:STDOUT:   %struct_type.discriminant.payload: type = struct_type {.discriminant: %u1, .payload: @P.%.loc7_1.14 (%.d27)} [symbolic = %struct_type.discriminant.payload (constants.%struct_type.discriminant.payload.1ec)]
// CHECK:STDOUT:   %complete_type.loc7_1.2: <witness> = complete_type_witness %struct_type.discriminant.payload [symbolic = %complete_type.loc7_1.2 (constants.%complete_type.d2c)]
// CHECK:STDOUT:   %P.Both.type: type = fn_type @P.Both, @P(%T.loc4_11.1) [symbolic = %P.Both.type (constants.%P.Both.type.e35)]
// CHECK:STDOUT:   %P.Both: @P.%P.Both.type (%P.Both.type.e35) = struct_value () [symbolic = %P.Both (constants.%P.Both.862)]
// CHECK:STDOUT:   %P: type = class_type @P, @P(%T.loc4_11.1) [symbolic = %P (constants.%P.f86)]
// CHECK:STDOUT:   %require_complete.loc7: <witness> = require_complete_type %P [symbolic = %require_complete.loc7 (constants.%require_complete.657)]
// CHECK:STDOUT:   %uninit.loc7_1.2: @P.%.loc7_1.14 (%.d27) = uninitialized_value [symbolic = %uninit.loc7_1.2 (constants.%uninit.216)]
// CHECK:STDOUT:   %P.val: @P.%P (%P.f86) = struct_value (constants.%int_1.233, %uninit.loc7_1.2) [symbolic = %P.val (constants.%P.val.a40)]
// CHECK:STDOUT:   %.loc7_1.15: ref @P.%P (%P.f86) = temporary invalid, %P.val [symbolic = %.loc7_1.15 (constants.%.a21)]
// CHECK:STDOUT:
// CHECK:STDOUT:   class {
// CHECK:STDOUT:     %x.param: @P.%T.loc4_11.1 (%T.67d) = value_param call_param0
// CHECK:STDOUT:     %T.ref.loc5_11: type = name_ref T, %T.loc4_11.2 [symbolic = %T.loc4_11.1 (constants.%T.67d)]
// CHECK:STDOUT:     %x: @P.%T.loc4_11.1 (%T.67d) = wrapper_binding x, %x.param
// CHECK:STDOUT:     %y.param: @P.%T.loc4_11.1 (%T.67d) = value_param call_param1
// CHECK:STDOUT:     %T.ref.loc5_17: type = name_ref T, %T.loc4_11.2 [symbolic = %T.loc4_11.1 (constants.%T.67d)]
// CHECK:STDOUT:     %y: @P.%T.loc4_11.1 (%T.67d) = wrapper_binding y, %y.param
// CHECK:STDOUT:     %.loc7_1.1: type = custom_layout_type {size=0, align=0, .Both@0: %tuple.type.07a} [symbolic = %.loc7_1.14 (constants.%.d27)]
// CHECK:STDOUT:     %complete_type.loc7_1.1: <witness> = complete_type_witness constants.%struct_type.discriminant.payload.1ec [symbolic = %complete_type.loc7_1.2 (constants.%complete_type.d2c)]
// CHECK:STDOUT:     %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:     %impl.elem0.loc7_1.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:     %bound_method.loc7_1.1: <bound method> = bound_method %int_1, %impl.elem0.loc7_1.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:     %specific_fn.loc7_1.1: <specific function> = specific_function %impl.elem0.loc7_1.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:     %bound_method.loc7_1.2: <bound method> = bound_method %int_1, %specific_fn.loc7_1.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %u1 = call %bound_method.loc7_1.2(%int_1) [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc7_1.2: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc7_1.3: %u1 = converted %int_1, %.loc7_1.2 [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc7_1.4: %struct_type.discriminant = struct_literal (%.loc7_1.3) [concrete = constants.%struct]
// CHECK:STDOUT:     %impl.elem0.loc7_1.2: %.952 = impl_witness_access constants.%Copy.impl_witness.334, element0 [concrete = constants.%UInt.as.Copy.impl.Op.d9c]
// CHECK:STDOUT:     %bound_method.loc7_1.3: <bound method> = bound_method %.loc7_1.3, %impl.elem0.loc7_1.2 [concrete = constants.%UInt.as.Copy.impl.Op.bound]
// CHECK:STDOUT:     %specific_fn.loc7_1.2: <specific function> = specific_function %impl.elem0.loc7_1.2, @UInt.as.Copy.impl.Op(constants.%int_1.5b8) [concrete = constants.%UInt.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:     %bound_method.loc7_1.4: <bound method> = bound_method %.loc7_1.3, %specific_fn.loc7_1.2 [concrete = constants.%bound_method.edd]
// CHECK:STDOUT:     %UInt.as.Copy.impl.Op.call: init %u1 = call %bound_method.loc7_1.4(%.loc7_1.3) [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc7_1.5: ref @P.%P (%P.f86) = temporary_storage
// CHECK:STDOUT:     %.loc7_1.6: ref %u1 = class_element_access %.loc7_1.5, element0
// CHECK:STDOUT:     %.loc7_1.7: init %u1 to %.loc7_1.6 = in_place_init %UInt.as.Copy.impl.Op.call [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc7_1.8: ref @P.%.loc7_1.14 (%.d27) = class_element_access %.loc7_1.5, element1
// CHECK:STDOUT:     %uninit.loc7_1.1: @P.%.loc7_1.14 (%.d27) = uninitialized_value [symbolic = %uninit.loc7_1.2 (constants.%uninit.216)]
// CHECK:STDOUT:     %.loc7_1.9: init @P.%.loc7_1.14 (%.d27) to %.loc7_1.8 = in_place_init %uninit.loc7_1.1 [symbolic = %uninit.loc7_1.2 (constants.%uninit.216)]
// CHECK:STDOUT:     %.loc7_1.10: init @P.%P (%P.f86) to %.loc7_1.5 = class_init (%.loc7_1.7, %.loc7_1.9) [symbolic = %P.val (constants.%P.val.a40)]
// CHECK:STDOUT:     %.loc7_1.11: init @P.%P (%P.f86) = converted %.loc7_1.4, %.loc7_1.10 [symbolic = %P.val (constants.%P.val.a40)]
// CHECK:STDOUT:     %.loc7_1.12: ref @P.%P (%P.f86) = temporary %.loc7_1.5, %.loc7_1.11 [symbolic = %.loc7_1.15 (constants.%.a21)]
// CHECK:STDOUT:     %.loc7_1.13: @P.%P (%P.f86) = acquire_value %.loc7_1.12 [symbolic = %P.val (constants.%P.val.a40)]
// CHECK:STDOUT:     %Neither: @P.%P (%P.f86) = wrapper_binding Neither, %.loc7_1.13
// CHECK:STDOUT:     complete_type_witness = %complete_type.loc7_1.1
// CHECK:STDOUT:
// CHECK:STDOUT:   !members:
// CHECK:STDOUT:     .Self = constants.%P.f86
// CHECK:STDOUT:     .T = <poisoned>
// CHECK:STDOUT:     .Both = generated.%P.Both.decl
// CHECK:STDOUT:     .Neither = %Neither
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @P.Both(@P.%T.loc4_11.2: type) {
// CHECK:STDOUT:   %T: type = symbolic_binding T, 0 [symbolic = %T (constants.%T.67d)]
// CHECK:STDOUT:   %pattern_type.loc4_19.1: type = pattern_type %T [symbolic = %pattern_type.loc4_19.1 (constants.%pattern_type.51d1c4.1)]
// CHECK:STDOUT:   %_.param_patt.loc4_19.3: @P.Both.%pattern_type.loc4_19.1 (%pattern_type.51d1c4.1) = value_param_pattern [symbolic = %_.param_patt.loc4_19.3 (constants.%_.param_patt)]
// CHECK:STDOUT:   %_.patt.loc4_19.3: @P.Both.%pattern_type.loc4_19.1 (%pattern_type.51d1c4.1) = wrapper_binding_pattern _, %_.param_patt.loc4_19.3 [symbolic = %_.patt.loc4_19.3 (constants.%_.patt)]
// CHECK:STDOUT:   %P.loc4_19.1: type = class_type @P, @P(%T) [symbolic = %P.loc4_19.1 (constants.%P.f86)]
// CHECK:STDOUT:   %.loc4_19.9: Core.Form = init_form %P.loc4_19.1 [symbolic = %.loc4_19.9 (constants.%.3a8)]
// CHECK:STDOUT:   %pattern_type.loc4_19.2: type = pattern_type %P.loc4_19.1 [symbolic = %pattern_type.loc4_19.2 (constants.%pattern_type.6d3)]
// CHECK:STDOUT:   %return.param_patt.loc4_19.2: @P.Both.%pattern_type.loc4_19.2 (%pattern_type.6d3) = out_param_pattern [symbolic = %return.param_patt.loc4_19.2 (constants.%return.param_patt.3b8)]
// CHECK:STDOUT:   %return.patt.loc4_19.2: @P.Both.%pattern_type.loc4_19.2 (%pattern_type.6d3) = return_slot_pattern %return.param_patt.loc4_19.2, %P.loc4_19.1 [symbolic = %return.patt.loc4_19.2 (constants.%return.patt.ec6)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc4_19.1: <witness> = require_complete_type %T [symbolic = %require_complete.loc4_19.1 (constants.%require_complete.944)]
// CHECK:STDOUT:   %require_complete.loc4_19.2: <witness> = require_complete_type %P.loc4_19.1 [symbolic = %require_complete.loc4_19.2 (constants.%require_complete.657)]
// CHECK:STDOUT:   %tuple.type: type = tuple_type (%T, %T) [symbolic = %tuple.type (constants.%tuple.type.07a)]
// CHECK:STDOUT:   %.loc4_19.10: type = custom_layout_type {size=0, align=0, .Both@0: @P.Both.%tuple.type (%tuple.type.07a)} [symbolic = %.loc4_19.10 (constants.%.d27)]
// CHECK:STDOUT:   %uninit.loc4_19.2: @P.Both.%.loc4_19.10 (%.d27) = uninitialized_value [symbolic = %uninit.loc4_19.2 (constants.%uninit.216)]
// CHECK:STDOUT:   %P.val: @P.Both.%P.loc4_19.1 (%P.f86) = struct_value (constants.%int_0.1a7, %uninit.loc4_19.2) [symbolic = %P.val (constants.%P.val.5d5)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%_.param.loc4_19.1: @P.Both.%T (%T.67d), %_.param.loc4_19.2: @P.Both.%T (%T.67d)) -> out %return.param: @P.Both.%P.loc4_19.1 (%P.f86) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %.loc4_19.1: ref %u1 = class_element_access %return.param, element0
// CHECK:STDOUT:     %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:     %impl.elem0: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:     %bound_method.loc4_19.1: <bound method> = bound_method %int_0, %impl.elem0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:     %specific_fn: <specific function> = specific_function %impl.elem0, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:     %bound_method.loc4_19.2: <bound method> = bound_method %int_0, %specific_fn [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %u1 = call %bound_method.loc4_19.2(%int_0) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:     %.loc4_19.2: init %u1 = converted %int_0, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:     %.loc4_19.3: init %u1 to %.loc4_19.1 = in_place_init %.loc4_19.2 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:     %.loc4_19.4: ref @P.Both.%.loc4_19.10 (%.d27) = class_element_access %return.param, element1
// CHECK:STDOUT:     %.loc4_19.5: ref @P.Both.%tuple.type (%tuple.type.07a) = class_element_access %.loc4_19.4, element0
// CHECK:STDOUT:     %.loc5_19.1: init @P.Both.%tuple.type (%tuple.type.07a) to %.loc4_19.5 = tuple_init (%_.param.loc4_19.1, %_.param.loc4_19.2)
// CHECK:STDOUT:     %uninit.loc4_19.1: @P.Both.%.loc4_19.10 (%.d27) = uninitialized_value [symbolic = %uninit.loc4_19.2 (constants.%uninit.216)]
// CHECK:STDOUT:     %.loc4_19.6: init @P.Both.%.loc4_19.10 (%.d27) to %.loc4_19.4 = in_place_init %uninit.loc4_19.1 [symbolic = %uninit.loc4_19.2 (constants.%uninit.216)]
// CHECK:STDOUT:     %.loc4_19.7: init @P.Both.%P.loc4_19.1 (%P.f86) to %return.param = class_init (%.loc4_19.3, %.loc4_19.6) [symbolic = %P.val (constants.%P.val.5d5)]
// CHECK:STDOUT:     %.loc4_19.8: init @P.Both.%P.loc4_19.1 (%P.f86) = update_init %.loc4_19.7, %.loc5_19.1
// CHECK:STDOUT:     %tuple.elem0: ref @P.Both.%T (%T.67d) = tuple_access %.loc4_19.5, element0
// CHECK:STDOUT:     %.loc5_19.2: init @P.Both.%T (%T.67d) to %tuple.elem0 = in_place_init %_.param.loc4_19.1
// CHECK:STDOUT:     %tuple.elem1: ref @P.Both.%T (%T.67d) = tuple_access %.loc4_19.5, element1
// CHECK:STDOUT:     %.loc5_19.3: init @P.Both.%T (%T.67d) to %tuple.elem1 = in_place_init %_.param.loc4_19.2
// CHECK:STDOUT:     return %.loc4_19.8 to %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @F(%p.param: %ptr.1ec) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %p.ref: %ptr.1ec = name_ref p, %p
// CHECK:STDOUT:   %.loc14: ref %P.4ae = deref %p.ref
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt: %pattern_type.d17 = expr_pattern %Neither.ref in [concrete] {
// CHECK:STDOUT:       %.loc15_10.2: %P.4ae = specific_constant @P.%.loc7_1.13, @P(constants.%i64) [concrete = constants.%P.val.c4c]
// CHECK:STDOUT:       %Neither.ref: %P.4ae = name_ref Neither, %.loc15_10.2 [concrete = constants.%P.val.c4c]
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %.loc15_10.1: %P.4ae = splice_block %Neither.ref [concrete = constants.%P.val.c4c] {
// CHECK:STDOUT:     %.loc15_10.2: %P.4ae = specific_constant @P.%.loc7_1.13, @P(constants.%i64) [concrete = constants.%P.val.c4c]
// CHECK:STDOUT:     %Neither.ref: %P.4ae = name_ref Neither, %.loc15_10.2 [concrete = constants.%P.val.c4c]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_1.loc15: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc15_19.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc15_19.1: <bound method> = bound_method %int_1.loc15, %impl.elem0.loc15_19.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc15_19.1: <specific function> = specific_function %impl.elem0.loc15_19.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc15_19.2: <bound method> = bound_method %int_1.loc15, %specific_fn.loc15_19.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc15_19: init %u1 = call %bound_method.loc15_19.2(%int_1.loc15) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc15_19.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc15_19 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc15_19.2: %u1 = converted %int_1.loc15, %.loc15_19.1 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc15_19.3: ref %u1 = class_element_access %.loc14, element0
// CHECK:STDOUT:   %impl.elem0.loc15_19.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc15_19.3: <bound method> = bound_method %.loc15_19.2, %impl.elem0.loc15_19.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound]
// CHECK:STDOUT:   %specific_fn.loc15_19.2: <specific function> = specific_function %impl.elem0.loc15_19.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc15_19.4: <bound method> = bound_method %.loc15_19.2, %specific_fn.loc15_19.2 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc15_19.4: %u1 = acquire_value %.loc15_19.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call: init bool = call %bound_method.loc15_19.4(%.loc15_19.2, %.loc15_19.4)
// CHECK:STDOUT:   %.loc15_19.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call
// CHECK:STDOUT:   %.loc15_19.6: bool = converted %UInt.as.EqWith.impl.Equal.call, %.loc15_19.5
// CHECK:STDOUT:   if %.loc15_19.6 br !match.case.then else br !match.case.else
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then:
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc15_32: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc15_32.1: <bound method> = bound_method %int_0, %impl.elem0.loc15_32 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc15_32: <specific function> = specific_function %impl.elem0.loc15_32, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc15_32.2: <bound method> = bound_method %int_0, %specific_fn.loc15_32 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc15_32: init %i32 = call %bound_method.loc15_32.2(%int_0) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc15_32: init %i32 = converted %int_0, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc15_32 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   return %.loc15_32
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else:
// CHECK:STDOUT:   %int_1.loc16: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc16: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc16_26.1: <bound method> = bound_method %int_1.loc16, %impl.elem0.loc16 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc16: <specific function> = specific_function %impl.elem0.loc16, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc16_26.2: <bound method> = bound_method %int_1.loc16, %specific_fn.loc16 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16: init %i32 = call %bound_method.loc16_26.2(%int_1.loc16) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc16: init %i32 = converted %int_1.loc16, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   return %.loc16
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @P(constants.%T.67d) {
// CHECK:STDOUT:   %T.patt.loc4_11.2 => constants.%T.patt.d47
// CHECK:STDOUT:   %T.loc4_11.1 => constants.%T.67d
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @P.Both(constants.%T.67d) {
// CHECK:STDOUT:   %T => constants.%T.67d
// CHECK:STDOUT:   %pattern_type.loc4_19.1 => constants.%pattern_type.51d1c4.1
// CHECK:STDOUT:   %_.param_patt.loc4_19.3 => constants.%_.param_patt
// CHECK:STDOUT:   %_.patt.loc4_19.3 => constants.%_.patt
// CHECK:STDOUT:   %P.loc4_19.1 => constants.%P.f86
// CHECK:STDOUT:   %.loc4_19.9 => constants.%.3a8
// CHECK:STDOUT:   %pattern_type.loc4_19.2 => constants.%pattern_type.6d3
// CHECK:STDOUT:   %return.param_patt.loc4_19.2 => constants.%return.param_patt.3b8
// CHECK:STDOUT:   %return.patt.loc4_19.2 => constants.%return.patt.ec6
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @P(constants.%i64) {
// CHECK:STDOUT:   %T.patt.loc4_11.2 => constants.%T.patt.d47
// CHECK:STDOUT:   %T.loc4_11.1 => constants.%i64
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.f57
// CHECK:STDOUT:   %x.param_patt => constants.%x.param_patt.7b8
// CHECK:STDOUT:   %x.patt => constants.%x.patt.5d3
// CHECK:STDOUT:   %y.param_patt => constants.%y.param_patt.83d
// CHECK:STDOUT:   %y.patt => constants.%y.patt.fca
// CHECK:STDOUT:   %require_complete.loc5 => constants.%complete_type.4a1
// CHECK:STDOUT:   %tuple.type => constants.%tuple.type.1ac
// CHECK:STDOUT:   %.loc7_1.14 => constants.%.58e
// CHECK:STDOUT:   %struct_type.discriminant.payload => constants.%struct_type.discriminant.payload.8ac
// CHECK:STDOUT:   %complete_type.loc7_1.2 => constants.%complete_type.ab0
// CHECK:STDOUT:   %P.Both.type => constants.%P.Both.type.b26
// CHECK:STDOUT:   %P.Both => constants.%P.Both.815
// CHECK:STDOUT:   %P => constants.%P.4ae
// CHECK:STDOUT:   %require_complete.loc7 => constants.%complete_type.ab0
// CHECK:STDOUT:   %uninit.loc7_1.2 => constants.%uninit.ccc
// CHECK:STDOUT:   %P.val => constants.%P.val.c4c
// CHECK:STDOUT:   %.loc7_1.15 => constants.%.efe
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- plib.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %P.type: type = generic_class_type @P [concrete]
// CHECK:STDOUT:   %P.generic: %P.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %u1: type = class_type @UInt, @UInt(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %int_1.233: %u1 = int_value 1 [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %P.4ae: type = class_type @P, @P(%i64) [concrete]
// CHECK:STDOUT:   %pattern_type.d17: type = pattern_type %P.4ae [concrete]
// CHECK:STDOUT:   %MakeRuntime.type: type = fn_type @MakeRuntime [concrete]
// CHECK:STDOUT:   %MakeRuntime: %MakeRuntime.type = struct_value () [concrete]
// CHECK:STDOUT:   %tuple.type.1ac: type = tuple_type (%i64, %i64) [concrete]
// CHECK:STDOUT:   %.58e: type = custom_layout_type {size=16, align=8, .Both@0: %tuple.type.1ac} [concrete]
// CHECK:STDOUT:   %uninit.ccc: %.58e = uninitialized_value [concrete]
// CHECK:STDOUT:   %P.val.c4c: %P.4ae = struct_value (%int_1.233, %uninit.ccc) [concrete]
// CHECK:STDOUT:   %g.patt: %pattern_type.d17 = value_binding_pattern g [concrete]
// CHECK:STDOUT:   %gc.patt: %pattern_type.d17 = value_binding_pattern gc [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %.loc17_29.1: ref %P.4ae = temporary @__global_init.%.loc17, @__global_init.%MakeRuntime.call
// CHECK:STDOUT:   %.loc17_29.2: %P.4ae = acquire_value %.loc17_29.1
// CHECK:STDOUT:   %.loc17_13: type = splice_block %P.loc17 [concrete = constants.%P.4ae] {
// CHECK:STDOUT:     %P.ref.loc17: %P.type = name_ref P, %P.decl [concrete = constants.%P.generic]
// CHECK:STDOUT:     %i64.loc17: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:     %P.loc17: type = class_type @P, @P(constants.%i64) [concrete = constants.%P.4ae]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %g: %P.4ae = wrapper_binding g, %.loc17_29.2
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %g.patt: %pattern_type.d17 = value_binding_pattern g [concrete = constants.%g.patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %.loc24: type = splice_block %P.loc24 [concrete = constants.%P.4ae] {
// CHECK:STDOUT:     %P.ref.loc24: %P.type = name_ref P, %P.decl [concrete = constants.%P.generic]
// CHECK:STDOUT:     %i64.loc24: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:     %P.loc24: type = class_type @P, @P(constants.%i64) [concrete = constants.%P.4ae]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %gc: %P.4ae = wrapper_binding gc, @__global_init.%Neither.ref
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %gc.patt: %pattern_type.d17 = value_binding_pattern gc [concrete = constants.%gc.patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @__global_init() {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %MakeRuntime.ref: %MakeRuntime.type = name_ref MakeRuntime, file.%MakeRuntime.decl [concrete = constants.%MakeRuntime]
// CHECK:STDOUT:   %.loc17: ref %P.4ae = temporary_storage
// CHECK:STDOUT:   %MakeRuntime.call: init %P.4ae to %.loc17 = call %MakeRuntime.ref()
// CHECK:STDOUT:   %P.ref: %P.type = name_ref P, file.%P.decl [concrete = constants.%P.generic]
// CHECK:STDOUT:   %i64: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:   %P: type = class_type @P, @P(constants.%i64) [concrete = constants.%P.4ae]
// CHECK:STDOUT:   %.loc24: %P.4ae = specific_constant @P.%.loc6_1.13, @P(constants.%i64) [concrete = constants.%P.val.c4c]
// CHECK:STDOUT:   %Neither.ref: %P.4ae = name_ref Neither, %.loc24 [concrete = constants.%P.val.c4c]
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- imported_global.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %T.67d: type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %tuple.type.07a: type = tuple_type (%T.67d, %T.67d) [symbolic]
// CHECK:STDOUT:   %.d27: type = custom_layout_type {size=0, align=0, .Both@0: %tuple.type.07a} [symbolic]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %u1: type = class_type @UInt, @UInt(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %P.f86: type = class_type @P, @P(%T.67d) [symbolic]
// CHECK:STDOUT:   %uninit.216: %.d27 = uninitialized_value [symbolic]
// CHECK:STDOUT:   %int_1.233: %u1 = int_value 1 [concrete]
// CHECK:STDOUT:   %P.val.a40: %P.f86 = struct_value (%int_1.233, %uninit.216) [symbolic]
// CHECK:STDOUT:   %P.4ae: type = class_type @P, @P(%i64) [concrete]
// CHECK:STDOUT:   %tuple.type.1ac: type = tuple_type (%i64, %i64) [concrete]
// CHECK:STDOUT:   %.58e: type = custom_layout_type {size=16, align=8, .Both@0: %tuple.type.1ac} [concrete]
// CHECK:STDOUT:   %uninit.ccc: %.58e = uninitialized_value [concrete]
// CHECK:STDOUT:   %P.val.c4c: %P.4ae = struct_value (%int_1.233, %uninit.ccc) [concrete]
// CHECK:STDOUT:   %pattern_type.d17: type = pattern_type %P.4ae [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.ca1: type = facet_type <@ImplicitAs, @ImplicitAs(%u1)> [concrete]
// CHECK:STDOUT:   %To.fe9: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.170: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.f4c: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.f01, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.46b: %ImplicitAs.type.ca1 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.f4c) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.77c: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%u1, %ImplicitAs.facet.46b) [concrete]
// CHECK:STDOUT:   %.e74: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.77c, %ImplicitAs.facet.46b [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.d7a: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
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
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
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
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.953: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Main.g: %P.4ae = import_ref Main//plib, g, loaded
// CHECK:STDOUT:   %Main.import_ref.3cd: @P.%P (%P.f86) = import_ref Main//plib, loc6_1, loaded [symbolic = @P.%P.val (constants.%P.val.a40)]
// CHECK:STDOUT:   %Core.import_ref.aa5: @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.170)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.f01 = impl_witness_table (%Core.import_ref.aa5), @Core.IntLiteral.as.ImplicitAs.impl.b68 [concrete]
// CHECK:STDOUT:   %Core.import_ref.b92: @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal.type (%UInt.as.EqWith.impl.Equal.type.544) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal (constants.%UInt.as.EqWith.impl.Equal.c67)]
// CHECK:STDOUT:   %Core.import_ref.b44 = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.166 = impl_witness_table (%Core.import_ref.b92, %Core.import_ref.b44), @UInt.as.EqWith.impl.f13 [concrete]
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
// CHECK:STDOUT:     %.loc14: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param0
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @F() -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %g.ref: %P.4ae = name_ref g, imports.%Main.g
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt: %pattern_type.d17 = expr_pattern %Neither.ref in [concrete] {
// CHECK:STDOUT:       %.loc16_10.2: %P.4ae = specific_constant imports.%Main.import_ref.3cd, @P(constants.%i64) [concrete = constants.%P.val.c4c]
// CHECK:STDOUT:       %Neither.ref: %P.4ae = name_ref Neither, %.loc16_10.2 [concrete = constants.%P.val.c4c]
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %.loc16_10.1: %P.4ae = splice_block %Neither.ref [concrete = constants.%P.val.c4c] {
// CHECK:STDOUT:     %.loc16_10.2: %P.4ae = specific_constant imports.%Main.import_ref.3cd, @P(constants.%i64) [concrete = constants.%P.val.c4c]
// CHECK:STDOUT:     %Neither.ref: %P.4ae = name_ref Neither, %.loc16_10.2 [concrete = constants.%P.val.c4c]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_1.loc16: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc16_19.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc16_19.1: <bound method> = bound_method %int_1.loc16, %impl.elem0.loc16_19.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc16_19.1: <specific function> = specific_function %impl.elem0.loc16_19.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc16_19.2: <bound method> = bound_method %int_1.loc16, %specific_fn.loc16_19.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16_19: init %u1 = call %bound_method.loc16_19.2(%int_1.loc16) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc16_19.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16_19 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc16_19.2: %u1 = converted %int_1.loc16, %.loc16_19.1 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc16_19.3: ref %u1 = class_element_access %g.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc16_19.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc16_19.3: <bound method> = bound_method %.loc16_19.2, %impl.elem0.loc16_19.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound]
// CHECK:STDOUT:   %specific_fn.loc16_19.2: <specific function> = specific_function %impl.elem0.loc16_19.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc16_19.4: <bound method> = bound_method %.loc16_19.2, %specific_fn.loc16_19.2 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc16_19.4: %u1 = acquire_value %.loc16_19.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call: init bool = call %bound_method.loc16_19.4(%.loc16_19.2, %.loc16_19.4)
// CHECK:STDOUT:   %.loc16_19.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call
// CHECK:STDOUT:   %.loc16_19.6: bool = converted %UInt.as.EqWith.impl.Equal.call, %.loc16_19.5
// CHECK:STDOUT:   if %.loc16_19.6 br !match.case.then else br !match.case.else
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then:
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc16_32: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc16_32.1: <bound method> = bound_method %int_0, %impl.elem0.loc16_32 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc16_32: <specific function> = specific_function %impl.elem0.loc16_32, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc16_32.2: <bound method> = bound_method %int_0, %specific_fn.loc16_32 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16_32: init %i32 = call %bound_method.loc16_32.2(%int_0) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc16_32: init %i32 = converted %int_0, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16_32 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   return %.loc16_32
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else:
// CHECK:STDOUT:   %int_1.loc17: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc17: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc17_26.1: <bound method> = bound_method %int_1.loc17, %impl.elem0.loc17 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc17: <specific function> = specific_function %impl.elem0.loc17, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc17_26.2: <bound method> = bound_method %int_1.loc17, %specific_fn.loc17 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc17: init %i32 = call %bound_method.loc17_26.2(%int_1.loc17) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc17: init %i32 = converted %int_1.loc17, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc17 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   return %.loc17
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- imported_global_constant.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %G.type: type = fn_type @G [concrete]
// CHECK:STDOUT:   %G: %G.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %T.67d: type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %tuple.type.07a: type = tuple_type (%T.67d, %T.67d) [symbolic]
// CHECK:STDOUT:   %.d27: type = custom_layout_type {size=0, align=0, .Both@0: %tuple.type.07a} [symbolic]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %u1: type = class_type @UInt, @UInt(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %P.f86: type = class_type @P, @P(%T.67d) [symbolic]
// CHECK:STDOUT:   %uninit.216: %.d27 = uninitialized_value [symbolic]
// CHECK:STDOUT:   %int_1.233: %u1 = int_value 1 [concrete]
// CHECK:STDOUT:   %P.val.a40: %P.f86 = struct_value (%int_1.233, %uninit.216) [symbolic]
// CHECK:STDOUT:   %P.4ae: type = class_type @P, @P(%i64) [concrete]
// CHECK:STDOUT:   %tuple.type.1ac: type = tuple_type (%i64, %i64) [concrete]
// CHECK:STDOUT:   %.58e: type = custom_layout_type {size=16, align=8, .Both@0: %tuple.type.1ac} [concrete]
// CHECK:STDOUT:   %uninit.ccc: %.58e = uninitialized_value [concrete]
// CHECK:STDOUT:   %P.val.c4c: %P.4ae = struct_value (%int_1.233, %uninit.ccc) [concrete]
// CHECK:STDOUT:   %pattern_type.d17: type = pattern_type %P.4ae [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.ca1: type = facet_type <@ImplicitAs, @ImplicitAs(%u1)> [concrete]
// CHECK:STDOUT:   %To.fe9: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.170: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.f4c: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.f01, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.46b: %ImplicitAs.type.ca1 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.f4c) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.77c: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%u1, %ImplicitAs.facet.46b) [concrete]
// CHECK:STDOUT:   %.e74: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.77c, %ImplicitAs.facet.46b [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.d7a: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
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
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
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
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.953: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Main.gc: %P.4ae = import_ref Main//plib, gc, loaded [concrete = constants.%P.val.c4c]
// CHECK:STDOUT:   %Main.import_ref.3cd: @P.%P (%P.f86) = import_ref Main//plib, loc6_1, loaded [symbolic = @P.%P.val (constants.%P.val.a40)]
// CHECK:STDOUT:   %Core.import_ref.aa5: @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.170)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.f01 = impl_witness_table (%Core.import_ref.aa5), @Core.IntLiteral.as.ImplicitAs.impl.b68 [concrete]
// CHECK:STDOUT:   %Core.import_ref.b92: @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal.type (%UInt.as.EqWith.impl.Equal.type.544) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal (constants.%UInt.as.EqWith.impl.Equal.c67)]
// CHECK:STDOUT:   %Core.import_ref.b44 = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.166 = impl_witness_table (%Core.import_ref.b92, %Core.import_ref.b44), @UInt.as.EqWith.impl.f13 [concrete]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %G.decl: %G.type = fn_decl @G [concrete = constants.%G] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc11: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param0
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @G() -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %gc.ref: %P.4ae = name_ref gc, imports.%Main.gc [concrete = constants.%P.val.c4c]
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt: %pattern_type.d17 = expr_pattern %Neither.ref in [concrete] {
// CHECK:STDOUT:       %.loc13_10.2: %P.4ae = specific_constant imports.%Main.import_ref.3cd, @P(constants.%i64) [concrete = constants.%P.val.c4c]
// CHECK:STDOUT:       %Neither.ref: %P.4ae = name_ref Neither, %.loc13_10.2 [concrete = constants.%P.val.c4c]
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %.loc13_10.1: %P.4ae = splice_block %Neither.ref [concrete = constants.%P.val.c4c] {
// CHECK:STDOUT:     %.loc13_10.2: %P.4ae = specific_constant imports.%Main.import_ref.3cd, @P(constants.%i64) [concrete = constants.%P.val.c4c]
// CHECK:STDOUT:     %Neither.ref: %P.4ae = name_ref Neither, %.loc13_10.2 [concrete = constants.%P.val.c4c]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_1.loc13: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc13_19.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc13_19.1: <bound method> = bound_method %int_1.loc13, %impl.elem0.loc13_19.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc13_19.1: <specific function> = specific_function %impl.elem0.loc13_19.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc13_19.2: <bound method> = bound_method %int_1.loc13, %specific_fn.loc13_19.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13_19: init %u1 = call %bound_method.loc13_19.2(%int_1.loc13) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc13_19.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13_19 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc13_19.2: %u1 = converted %int_1.loc13, %.loc13_19.1 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc13_19.3: ref %u1 = class_element_access %gc.ref, element0 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %impl.elem0.loc13_19.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc13_19.3: <bound method> = bound_method %.loc13_19.2, %impl.elem0.loc13_19.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound]
// CHECK:STDOUT:   %specific_fn.loc13_19.2: <specific function> = specific_function %impl.elem0.loc13_19.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc13_19.4: <bound method> = bound_method %.loc13_19.2, %specific_fn.loc13_19.2 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc13_19.4: %u1 = acquire_value %.loc13_19.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call: init bool = call %bound_method.loc13_19.4(%.loc13_19.2, %.loc13_19.4)
// CHECK:STDOUT:   %.loc13_19.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call
// CHECK:STDOUT:   %.loc13_19.6: bool = converted %UInt.as.EqWith.impl.Equal.call, %.loc13_19.5
// CHECK:STDOUT:   if %.loc13_19.6 br !match.case.then else br !match.case.else
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then:
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc13_32: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc13_32.1: <bound method> = bound_method %int_0, %impl.elem0.loc13_32 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc13_32: <specific function> = specific_function %impl.elem0.loc13_32, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc13_32.2: <bound method> = bound_method %int_0, %specific_fn.loc13_32 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13_32: init %i32 = call %bound_method.loc13_32.2(%int_0) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc13_32: init %i32 = converted %int_0, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13_32 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   return %.loc13_32
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else:
// CHECK:STDOUT:   %int_1.loc14: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc14: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc14_26.1: <bound method> = bound_method %int_1.loc14, %impl.elem0.loc14 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc14: <specific function> = specific_function %impl.elem0.loc14, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc14_26.2: <bound method> = bound_method %int_1.loc14, %specific_fn.loc14 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14: init %i32 = call %bound_method.loc14_26.2(%int_1.loc14) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc14: init %i32 = converted %int_1.loc14, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   return %.loc14
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- by_value_param.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %.Self.frozen: %type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %pattern_type.98f: type = pattern_type type [concrete]
// CHECK:STDOUT:   %T.patt.d47: %pattern_type.98f = symbolic_binding_pattern T, 0 [symbolic]
// CHECK:STDOUT:   %T.67d: type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %P.type: type = generic_class_type @P [concrete]
// CHECK:STDOUT:   %P.generic: %P.type = struct_value () [concrete]
// CHECK:STDOUT:   %P.f86: type = class_type @P, @P(%T.67d) [symbolic]
// CHECK:STDOUT:   %pattern_type.51d1c4.1: type = pattern_type %T.67d [symbolic]
// CHECK:STDOUT:   %x.param_patt.91d: %pattern_type.51d1c4.1 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %x.patt.260: %pattern_type.51d1c4.1 = wrapper_binding_pattern x, %x.param_patt.91d [symbolic]
// CHECK:STDOUT:   %y.param_patt.be3: %pattern_type.51d1c4.1 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %y.patt.678: %pattern_type.51d1c4.1 = wrapper_binding_pattern y, %y.param_patt.be3 [symbolic]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %u1: type = class_type @UInt, @UInt(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %require_complete.944: <witness> = require_complete_type %T.67d [symbolic]
// CHECK:STDOUT:   %tuple.type.07a: type = tuple_type (%T.67d, %T.67d) [symbolic]
// CHECK:STDOUT:   %.d27: type = custom_layout_type {size=0, align=0, .Both@0: %tuple.type.07a} [symbolic]
// CHECK:STDOUT:   %struct_type.discriminant.payload.1ec: type = struct_type {.discriminant: %u1, .payload: %.d27} [symbolic]
// CHECK:STDOUT:   %complete_type.d2c: <witness> = complete_type_witness %struct_type.discriminant.payload.1ec [symbolic]
// CHECK:STDOUT:   %struct_type.discriminant: type = struct_type {.discriminant: %u1} [concrete]
// CHECK:STDOUT:   %_.param_patt: %pattern_type.51d1c4.1 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %_.patt: %pattern_type.51d1c4.1 = wrapper_binding_pattern _, %_.param_patt [symbolic]
// CHECK:STDOUT:   %.3a8: Core.Form = init_form %P.f86 [symbolic]
// CHECK:STDOUT:   %pattern_type.6d3: type = pattern_type %P.f86 [symbolic]
// CHECK:STDOUT:   %return.param_patt.3b8: %pattern_type.6d3 = out_param_pattern [symbolic]
// CHECK:STDOUT:   %return.patt.ec6: %pattern_type.6d3 = return_slot_pattern %return.param_patt.3b8, %P.f86 [symbolic]
// CHECK:STDOUT:   %P.Both.type.e35: type = fn_type @P.Both, @P(%T.67d) [symbolic]
// CHECK:STDOUT:   %P.Both.862: %P.Both.type.e35 = struct_value () [symbolic]
// CHECK:STDOUT:   %require_complete.657: <witness> = require_complete_type %P.f86 [symbolic]
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
// CHECK:STDOUT:   %uninit.216: %.d27 = uninitialized_value [symbolic]
// CHECK:STDOUT:   %P.val.5d5: %P.f86 = struct_value (%int_0.1a7, %uninit.216) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %bound_method.d7a: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
// CHECK:STDOUT:   %int_1.233: %u1 = int_value 1 [concrete]
// CHECK:STDOUT:   %struct: %struct_type.discriminant = struct_value (%int_1.233) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.type.0c5: type = fn_type @UInt.as.Copy.impl.Op, @UInt.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.38a: %UInt.as.Copy.impl.Op.type.0c5 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.334: <witness> = impl_witness imports.%Copy.impl_witness_table.ae7, @UInt.as.Copy.impl(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.type.c97: type = fn_type @UInt.as.Copy.impl.Op, @UInt.as.Copy.impl(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.d9c: %UInt.as.Copy.impl.Op.type.c97 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet: %Copy.type = facet_value %u1, (%Copy.impl_witness.334) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.703: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet) [concrete]
// CHECK:STDOUT:   %.952: type = fn_type_with_self_type %Copy.WithSelf.Op.type.703, %Copy.facet [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.bound: <bound method> = bound_method %int_1.233, %UInt.as.Copy.impl.Op.d9c [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %UInt.as.Copy.impl.Op.d9c, @UInt.as.Copy.impl.Op(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.edd: <bound method> = bound_method %int_1.233, %UInt.as.Copy.impl.Op.specific_fn [concrete]
// CHECK:STDOUT:   %P.val.a40: %P.f86 = struct_value (%int_1.233, %uninit.216) [symbolic]
// CHECK:STDOUT:   %.a21: ref %P.f86 = temporary invalid, %P.val.a40 [symbolic]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %P.b38: type = class_type @P, @P(%i32) [concrete]
// CHECK:STDOUT:   %pattern_type.e96: type = pattern_type %P.b38 [concrete]
// CHECK:STDOUT:   %p.param_patt: %pattern_type.e96 = value_param_pattern [concrete]
// CHECK:STDOUT:   %p.patt: %pattern_type.e96 = wrapper_binding_pattern p, %p.param_patt [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT:   %x.param_patt.cee: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %x.patt.e3b: %pattern_type.6b6 = wrapper_binding_pattern x, %x.param_patt.cee [concrete]
// CHECK:STDOUT:   %y.param_patt.673: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %y.patt.547: %pattern_type.6b6 = wrapper_binding_pattern y, %y.param_patt.673 [concrete]
// CHECK:STDOUT:   %i32.builtin: type = int_type signed, %int_32 [concrete]
// CHECK:STDOUT:   %complete_type.f8a: <witness> = complete_type_witness %i32.builtin [concrete]
// CHECK:STDOUT:   %tuple.type.e55: type = tuple_type (%i32, %i32) [concrete]
// CHECK:STDOUT:   %.20c: type = custom_layout_type {size=8, align=4, .Both@0: %tuple.type.e55} [concrete]
// CHECK:STDOUT:   %struct_type.discriminant.payload.92c: type = struct_type {.discriminant: %u1, .payload: %.20c} [concrete]
// CHECK:STDOUT:   %complete_type.ea6: <witness> = complete_type_witness %struct_type.discriminant.payload.92c [concrete]
// CHECK:STDOUT:   %P.Both.type.571: type = fn_type @P.Both, @P(%i32) [concrete]
// CHECK:STDOUT:   %P.Both.ce5: %P.Both.type.571 = struct_value () [concrete]
// CHECK:STDOUT:   %uninit.525: %.20c = uninitialized_value [concrete]
// CHECK:STDOUT:   %P.val.3d1: %P.b38 = struct_value (%int_1.233, %uninit.525) [concrete]
// CHECK:STDOUT:   %.b5a: ref %P.b38 = temporary invalid, %P.val.3d1 [concrete]
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
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.953: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT:   %Call.type: type = fn_type @Call [concrete]
// CHECK:STDOUT:   %Call: %Call.type = struct_value () [concrete]
// CHECK:STDOUT:   %n.patt: %pattern_type.e96 = value_binding_pattern n [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.aa5: @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.170)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.f01 = impl_witness_table (%Core.import_ref.aa5), @Core.IntLiteral.as.ImplicitAs.impl.b68 [concrete]
// CHECK:STDOUT:   %Core.import_ref.791: @UInt.as.Copy.impl.%UInt.as.Copy.impl.Op.type (%UInt.as.Copy.impl.Op.type.0c5) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.Copy.impl.%UInt.as.Copy.impl.Op (constants.%UInt.as.Copy.impl.Op.38a)]
// CHECK:STDOUT:   %Copy.impl_witness_table.ae7 = impl_witness_table (%Core.import_ref.791), @UInt.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.b92: @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal.type (%UInt.as.EqWith.impl.Equal.type.544) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal (constants.%UInt.as.EqWith.impl.Equal.c67)]
// CHECK:STDOUT:   %Core.import_ref.b44 = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.166 = impl_witness_table (%Core.import_ref.b92, %Core.import_ref.b44), @UInt.as.EqWith.impl.f13 [concrete]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %P.Both.decl: @P.%P.Both.type (%P.Both.type.e35) = fn_decl @P.Both [symbolic = @P.%P.Both (constants.%P.Both.862)] {
// CHECK:STDOUT:     %_.param_patt.loc4_19.1: @P.Both.%pattern_type.loc4_19.1 (%pattern_type.51d1c4.1) = value_param_pattern [symbolic = %_.param_patt.loc4_19.3 (constants.%_.param_patt)]
// CHECK:STDOUT:     %_.patt.loc4_19.1: @P.Both.%pattern_type.loc4_19.1 (%pattern_type.51d1c4.1) = wrapper_binding_pattern _, %_.param_patt.loc4_19.1 [symbolic = %_.patt.loc4_19.3 (constants.%_.patt)]
// CHECK:STDOUT:     %_.param_patt.loc4_19.2: @P.Both.%pattern_type.loc4_19.1 (%pattern_type.51d1c4.1) = value_param_pattern [symbolic = %_.param_patt.loc4_19.3 (constants.%_.param_patt)]
// CHECK:STDOUT:     %_.patt.loc4_19.2: @P.Both.%pattern_type.loc4_19.1 (%pattern_type.51d1c4.1) = wrapper_binding_pattern _, %_.param_patt.loc4_19.2 [symbolic = %_.patt.loc4_19.3 (constants.%_.patt)]
// CHECK:STDOUT:     %return.param_patt.loc4_19.1: @P.Both.%pattern_type.loc4_19.2 (%pattern_type.6d3) = out_param_pattern [symbolic = %return.param_patt.loc4_19.2 (constants.%return.param_patt.3b8)]
// CHECK:STDOUT:     %return.patt.loc4_19.1: @P.Both.%pattern_type.loc4_19.2 (%pattern_type.6d3) = return_slot_pattern %return.param_patt.loc4_19.1, %P.loc4_19.2 [symbolic = %return.patt.loc4_19.2 (constants.%return.patt.ec6)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %P.loc4_19.2: type = class_type @P, @P(constants.%T.67d) [symbolic = %P.loc4_19.1 (constants.%P.f86)]
// CHECK:STDOUT:     %.loc4_19.11: Core.Form = init_form %P.loc4_19.2 [symbolic = %.loc4_19.9 (constants.%.3a8)]
// CHECK:STDOUT:     %_.param.loc4_19.1: @P.Both.%T (%T.67d) = value_param call_param0
// CHECK:STDOUT:     %_.loc4_19.1: @P.Both.%T (%T.67d) = wrapper_binding _, %_.param.loc4_19.1
// CHECK:STDOUT:     %_.param.loc4_19.2: @P.Both.%T (%T.67d) = value_param call_param1
// CHECK:STDOUT:     %_.loc4_19.2: @P.Both.%T (%T.67d) = wrapper_binding _, %_.param.loc4_19.2
// CHECK:STDOUT:     %return.param: ref @P.Both.%P.loc4_19.1 (%P.f86) = out_param call_param2
// CHECK:STDOUT:     %return: ref @P.Both.%P.loc4_19.1 (%P.f86) = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %P.decl: %P.type = class_decl @P [concrete = constants.%P.generic] {
// CHECK:STDOUT:     %T.patt.loc4_11.1: %pattern_type.98f = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc4_11.2 (constants.%T.patt.d47)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc4_13.1: type = splice_block %.loc4_13.2 [concrete = type] {
// CHECK:STDOUT:       %.Self.frozen: %type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %.loc4_13.2: type = type_literal type [concrete = type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc4_11.2: type = symbolic_binding T, 0 [symbolic = %T.loc4_11.1 (constants.%T.67d)]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %F.decl: %F.type = fn_decl @F [concrete = constants.%F] {
// CHECK:STDOUT:     %p.param_patt: %pattern_type.e96 = value_param_pattern [concrete = constants.%p.param_patt]
// CHECK:STDOUT:     %p.patt: %pattern_type.e96 = wrapper_binding_pattern p, %p.param_patt [concrete = constants.%p.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc11_20 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc11_20: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc11_20: Core.Form = init_form %i32.loc11_20 [concrete = constants.%.795f]
// CHECK:STDOUT:     %p.param: %P.b38 = value_param call_param0
// CHECK:STDOUT:     %.loc11_14: type = splice_block %P [concrete = constants.%P.b38] {
// CHECK:STDOUT:       %P.ref: %P.type = name_ref P, file.%P.decl [concrete = constants.%P.generic]
// CHECK:STDOUT:       %i32.loc11_11: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %P: type = class_type @P, @P(constants.%i32) [concrete = constants.%P.b38]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %p: %P.b38 = wrapper_binding p, %p.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Call.decl: %Call.type = fn_decl @Call [concrete = constants.%Call] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc18 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc18: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc18: Core.Form = init_form %i32.loc18 [concrete = constants.%.795f]
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param0
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic class @P(%T.loc4_11.2: type) {
// CHECK:STDOUT:   %T.patt.loc4_11.2: %pattern_type.98f = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc4_11.2 (constants.%T.patt.d47)]
// CHECK:STDOUT:   %T.loc4_11.1: type = symbolic_binding T, 0 [symbolic = %T.loc4_11.1 (constants.%T.67d)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %pattern_type: type = pattern_type %T.loc4_11.1 [symbolic = %pattern_type (constants.%pattern_type.51d1c4.1)]
// CHECK:STDOUT:   %x.param_patt: @P.%pattern_type (%pattern_type.51d1c4.1) = value_param_pattern [symbolic = %x.param_patt (constants.%x.param_patt.91d)]
// CHECK:STDOUT:   %x.patt: @P.%pattern_type (%pattern_type.51d1c4.1) = wrapper_binding_pattern x, %x.param_patt [symbolic = %x.patt (constants.%x.patt.260)]
// CHECK:STDOUT:   %y.param_patt: @P.%pattern_type (%pattern_type.51d1c4.1) = value_param_pattern [symbolic = %y.param_patt (constants.%y.param_patt.be3)]
// CHECK:STDOUT:   %y.patt: @P.%pattern_type (%pattern_type.51d1c4.1) = wrapper_binding_pattern y, %y.param_patt [symbolic = %y.patt (constants.%y.patt.678)]
// CHECK:STDOUT:   %require_complete.loc5: <witness> = require_complete_type %T.loc4_11.1 [symbolic = %require_complete.loc5 (constants.%require_complete.944)]
// CHECK:STDOUT:   %tuple.type: type = tuple_type (%T.loc4_11.1, %T.loc4_11.1) [symbolic = %tuple.type (constants.%tuple.type.07a)]
// CHECK:STDOUT:   %.loc7_1.14: type = custom_layout_type {size=0, align=0, .Both@0: @P.%tuple.type (%tuple.type.07a)} [symbolic = %.loc7_1.14 (constants.%.d27)]
// CHECK:STDOUT:   %struct_type.discriminant.payload: type = struct_type {.discriminant: %u1, .payload: @P.%.loc7_1.14 (%.d27)} [symbolic = %struct_type.discriminant.payload (constants.%struct_type.discriminant.payload.1ec)]
// CHECK:STDOUT:   %complete_type.loc7_1.2: <witness> = complete_type_witness %struct_type.discriminant.payload [symbolic = %complete_type.loc7_1.2 (constants.%complete_type.d2c)]
// CHECK:STDOUT:   %P.Both.type: type = fn_type @P.Both, @P(%T.loc4_11.1) [symbolic = %P.Both.type (constants.%P.Both.type.e35)]
// CHECK:STDOUT:   %P.Both: @P.%P.Both.type (%P.Both.type.e35) = struct_value () [symbolic = %P.Both (constants.%P.Both.862)]
// CHECK:STDOUT:   %P: type = class_type @P, @P(%T.loc4_11.1) [symbolic = %P (constants.%P.f86)]
// CHECK:STDOUT:   %require_complete.loc7: <witness> = require_complete_type %P [symbolic = %require_complete.loc7 (constants.%require_complete.657)]
// CHECK:STDOUT:   %uninit.loc7_1.2: @P.%.loc7_1.14 (%.d27) = uninitialized_value [symbolic = %uninit.loc7_1.2 (constants.%uninit.216)]
// CHECK:STDOUT:   %P.val: @P.%P (%P.f86) = struct_value (constants.%int_1.233, %uninit.loc7_1.2) [symbolic = %P.val (constants.%P.val.a40)]
// CHECK:STDOUT:   %.loc7_1.15: ref @P.%P (%P.f86) = temporary invalid, %P.val [symbolic = %.loc7_1.15 (constants.%.a21)]
// CHECK:STDOUT:
// CHECK:STDOUT:   class {
// CHECK:STDOUT:     %x.param: @P.%T.loc4_11.1 (%T.67d) = value_param call_param0
// CHECK:STDOUT:     %T.ref.loc5_11: type = name_ref T, %T.loc4_11.2 [symbolic = %T.loc4_11.1 (constants.%T.67d)]
// CHECK:STDOUT:     %x: @P.%T.loc4_11.1 (%T.67d) = wrapper_binding x, %x.param
// CHECK:STDOUT:     %y.param: @P.%T.loc4_11.1 (%T.67d) = value_param call_param1
// CHECK:STDOUT:     %T.ref.loc5_17: type = name_ref T, %T.loc4_11.2 [symbolic = %T.loc4_11.1 (constants.%T.67d)]
// CHECK:STDOUT:     %y: @P.%T.loc4_11.1 (%T.67d) = wrapper_binding y, %y.param
// CHECK:STDOUT:     %.loc7_1.1: type = custom_layout_type {size=0, align=0, .Both@0: %tuple.type.07a} [symbolic = %.loc7_1.14 (constants.%.d27)]
// CHECK:STDOUT:     %complete_type.loc7_1.1: <witness> = complete_type_witness constants.%struct_type.discriminant.payload.1ec [symbolic = %complete_type.loc7_1.2 (constants.%complete_type.d2c)]
// CHECK:STDOUT:     %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:     %impl.elem0.loc7_1.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:     %bound_method.loc7_1.1: <bound method> = bound_method %int_1, %impl.elem0.loc7_1.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:     %specific_fn.loc7_1.1: <specific function> = specific_function %impl.elem0.loc7_1.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:     %bound_method.loc7_1.2: <bound method> = bound_method %int_1, %specific_fn.loc7_1.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %u1 = call %bound_method.loc7_1.2(%int_1) [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc7_1.2: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc7_1.3: %u1 = converted %int_1, %.loc7_1.2 [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc7_1.4: %struct_type.discriminant = struct_literal (%.loc7_1.3) [concrete = constants.%struct]
// CHECK:STDOUT:     %impl.elem0.loc7_1.2: %.952 = impl_witness_access constants.%Copy.impl_witness.334, element0 [concrete = constants.%UInt.as.Copy.impl.Op.d9c]
// CHECK:STDOUT:     %bound_method.loc7_1.3: <bound method> = bound_method %.loc7_1.3, %impl.elem0.loc7_1.2 [concrete = constants.%UInt.as.Copy.impl.Op.bound]
// CHECK:STDOUT:     %specific_fn.loc7_1.2: <specific function> = specific_function %impl.elem0.loc7_1.2, @UInt.as.Copy.impl.Op(constants.%int_1.5b8) [concrete = constants.%UInt.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:     %bound_method.loc7_1.4: <bound method> = bound_method %.loc7_1.3, %specific_fn.loc7_1.2 [concrete = constants.%bound_method.edd]
// CHECK:STDOUT:     %UInt.as.Copy.impl.Op.call: init %u1 = call %bound_method.loc7_1.4(%.loc7_1.3) [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc7_1.5: ref @P.%P (%P.f86) = temporary_storage
// CHECK:STDOUT:     %.loc7_1.6: ref %u1 = class_element_access %.loc7_1.5, element0
// CHECK:STDOUT:     %.loc7_1.7: init %u1 to %.loc7_1.6 = in_place_init %UInt.as.Copy.impl.Op.call [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc7_1.8: ref @P.%.loc7_1.14 (%.d27) = class_element_access %.loc7_1.5, element1
// CHECK:STDOUT:     %uninit.loc7_1.1: @P.%.loc7_1.14 (%.d27) = uninitialized_value [symbolic = %uninit.loc7_1.2 (constants.%uninit.216)]
// CHECK:STDOUT:     %.loc7_1.9: init @P.%.loc7_1.14 (%.d27) to %.loc7_1.8 = in_place_init %uninit.loc7_1.1 [symbolic = %uninit.loc7_1.2 (constants.%uninit.216)]
// CHECK:STDOUT:     %.loc7_1.10: init @P.%P (%P.f86) to %.loc7_1.5 = class_init (%.loc7_1.7, %.loc7_1.9) [symbolic = %P.val (constants.%P.val.a40)]
// CHECK:STDOUT:     %.loc7_1.11: init @P.%P (%P.f86) = converted %.loc7_1.4, %.loc7_1.10 [symbolic = %P.val (constants.%P.val.a40)]
// CHECK:STDOUT:     %.loc7_1.12: ref @P.%P (%P.f86) = temporary %.loc7_1.5, %.loc7_1.11 [symbolic = %.loc7_1.15 (constants.%.a21)]
// CHECK:STDOUT:     %.loc7_1.13: @P.%P (%P.f86) = acquire_value %.loc7_1.12 [symbolic = %P.val (constants.%P.val.a40)]
// CHECK:STDOUT:     %Neither: @P.%P (%P.f86) = wrapper_binding Neither, %.loc7_1.13
// CHECK:STDOUT:     complete_type_witness = %complete_type.loc7_1.1
// CHECK:STDOUT:
// CHECK:STDOUT:   !members:
// CHECK:STDOUT:     .Self = constants.%P.f86
// CHECK:STDOUT:     .T = <poisoned>
// CHECK:STDOUT:     .Both = generated.%P.Both.decl
// CHECK:STDOUT:     .Neither = %Neither
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @P.Both(@P.%T.loc4_11.2: type) {
// CHECK:STDOUT:   %T: type = symbolic_binding T, 0 [symbolic = %T (constants.%T.67d)]
// CHECK:STDOUT:   %pattern_type.loc4_19.1: type = pattern_type %T [symbolic = %pattern_type.loc4_19.1 (constants.%pattern_type.51d1c4.1)]
// CHECK:STDOUT:   %_.param_patt.loc4_19.3: @P.Both.%pattern_type.loc4_19.1 (%pattern_type.51d1c4.1) = value_param_pattern [symbolic = %_.param_patt.loc4_19.3 (constants.%_.param_patt)]
// CHECK:STDOUT:   %_.patt.loc4_19.3: @P.Both.%pattern_type.loc4_19.1 (%pattern_type.51d1c4.1) = wrapper_binding_pattern _, %_.param_patt.loc4_19.3 [symbolic = %_.patt.loc4_19.3 (constants.%_.patt)]
// CHECK:STDOUT:   %P.loc4_19.1: type = class_type @P, @P(%T) [symbolic = %P.loc4_19.1 (constants.%P.f86)]
// CHECK:STDOUT:   %.loc4_19.9: Core.Form = init_form %P.loc4_19.1 [symbolic = %.loc4_19.9 (constants.%.3a8)]
// CHECK:STDOUT:   %pattern_type.loc4_19.2: type = pattern_type %P.loc4_19.1 [symbolic = %pattern_type.loc4_19.2 (constants.%pattern_type.6d3)]
// CHECK:STDOUT:   %return.param_patt.loc4_19.2: @P.Both.%pattern_type.loc4_19.2 (%pattern_type.6d3) = out_param_pattern [symbolic = %return.param_patt.loc4_19.2 (constants.%return.param_patt.3b8)]
// CHECK:STDOUT:   %return.patt.loc4_19.2: @P.Both.%pattern_type.loc4_19.2 (%pattern_type.6d3) = return_slot_pattern %return.param_patt.loc4_19.2, %P.loc4_19.1 [symbolic = %return.patt.loc4_19.2 (constants.%return.patt.ec6)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc4_19.1: <witness> = require_complete_type %T [symbolic = %require_complete.loc4_19.1 (constants.%require_complete.944)]
// CHECK:STDOUT:   %require_complete.loc4_19.2: <witness> = require_complete_type %P.loc4_19.1 [symbolic = %require_complete.loc4_19.2 (constants.%require_complete.657)]
// CHECK:STDOUT:   %tuple.type: type = tuple_type (%T, %T) [symbolic = %tuple.type (constants.%tuple.type.07a)]
// CHECK:STDOUT:   %.loc4_19.10: type = custom_layout_type {size=0, align=0, .Both@0: @P.Both.%tuple.type (%tuple.type.07a)} [symbolic = %.loc4_19.10 (constants.%.d27)]
// CHECK:STDOUT:   %uninit.loc4_19.2: @P.Both.%.loc4_19.10 (%.d27) = uninitialized_value [symbolic = %uninit.loc4_19.2 (constants.%uninit.216)]
// CHECK:STDOUT:   %P.val: @P.Both.%P.loc4_19.1 (%P.f86) = struct_value (constants.%int_0.1a7, %uninit.loc4_19.2) [symbolic = %P.val (constants.%P.val.5d5)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%_.param.loc4_19.1: @P.Both.%T (%T.67d), %_.param.loc4_19.2: @P.Both.%T (%T.67d)) -> out %return.param: @P.Both.%P.loc4_19.1 (%P.f86) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %.loc4_19.1: ref %u1 = class_element_access %return.param, element0
// CHECK:STDOUT:     %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:     %impl.elem0: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:     %bound_method.loc4_19.1: <bound method> = bound_method %int_0, %impl.elem0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:     %specific_fn: <specific function> = specific_function %impl.elem0, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:     %bound_method.loc4_19.2: <bound method> = bound_method %int_0, %specific_fn [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %u1 = call %bound_method.loc4_19.2(%int_0) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:     %.loc4_19.2: init %u1 = converted %int_0, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:     %.loc4_19.3: init %u1 to %.loc4_19.1 = in_place_init %.loc4_19.2 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:     %.loc4_19.4: ref @P.Both.%.loc4_19.10 (%.d27) = class_element_access %return.param, element1
// CHECK:STDOUT:     %.loc4_19.5: ref @P.Both.%tuple.type (%tuple.type.07a) = class_element_access %.loc4_19.4, element0
// CHECK:STDOUT:     %.loc5_19.1: init @P.Both.%tuple.type (%tuple.type.07a) to %.loc4_19.5 = tuple_init (%_.param.loc4_19.1, %_.param.loc4_19.2)
// CHECK:STDOUT:     %uninit.loc4_19.1: @P.Both.%.loc4_19.10 (%.d27) = uninitialized_value [symbolic = %uninit.loc4_19.2 (constants.%uninit.216)]
// CHECK:STDOUT:     %.loc4_19.6: init @P.Both.%.loc4_19.10 (%.d27) to %.loc4_19.4 = in_place_init %uninit.loc4_19.1 [symbolic = %uninit.loc4_19.2 (constants.%uninit.216)]
// CHECK:STDOUT:     %.loc4_19.7: init @P.Both.%P.loc4_19.1 (%P.f86) to %return.param = class_init (%.loc4_19.3, %.loc4_19.6) [symbolic = %P.val (constants.%P.val.5d5)]
// CHECK:STDOUT:     %.loc4_19.8: init @P.Both.%P.loc4_19.1 (%P.f86) = update_init %.loc4_19.7, %.loc5_19.1
// CHECK:STDOUT:     %tuple.elem0: ref @P.Both.%T (%T.67d) = tuple_access %.loc4_19.5, element0
// CHECK:STDOUT:     %.loc5_19.2: init @P.Both.%T (%T.67d) to %tuple.elem0 = in_place_init %_.param.loc4_19.1
// CHECK:STDOUT:     %tuple.elem1: ref @P.Both.%T (%T.67d) = tuple_access %.loc4_19.5, element1
// CHECK:STDOUT:     %.loc5_19.3: init @P.Both.%T (%T.67d) to %tuple.elem1 = in_place_init %_.param.loc4_19.2
// CHECK:STDOUT:     return %.loc4_19.8 to %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @F(%p.param: %P.b38) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %p.ref: %P.b38 = name_ref p, %p
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt: %pattern_type.e96 = expr_pattern %Neither.ref in [concrete] {
// CHECK:STDOUT:       %.loc13_10.2: %P.b38 = specific_constant @P.%.loc7_1.13, @P(constants.%i32) [concrete = constants.%P.val.3d1]
// CHECK:STDOUT:       %Neither.ref: %P.b38 = name_ref Neither, %.loc13_10.2 [concrete = constants.%P.val.3d1]
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %.loc13_10.1: %P.b38 = splice_block %Neither.ref [concrete = constants.%P.val.3d1] {
// CHECK:STDOUT:     %.loc13_10.2: %P.b38 = specific_constant @P.%.loc7_1.13, @P(constants.%i32) [concrete = constants.%P.val.3d1]
// CHECK:STDOUT:     %Neither.ref: %P.b38 = name_ref Neither, %.loc13_10.2 [concrete = constants.%P.val.3d1]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_1.loc13: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc13_19.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc13_19.1: <bound method> = bound_method %int_1.loc13, %impl.elem0.loc13_19.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc13_19.1: <specific function> = specific_function %impl.elem0.loc13_19.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc13_19.2: <bound method> = bound_method %int_1.loc13, %specific_fn.loc13_19.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13_19: init %u1 = call %bound_method.loc13_19.2(%int_1.loc13) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc13_19.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13_19 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc13_19.2: %u1 = converted %int_1.loc13, %.loc13_19.1 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc13_19.3: ref %u1 = class_element_access %p.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc13_19.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc13_19.3: <bound method> = bound_method %.loc13_19.2, %impl.elem0.loc13_19.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound]
// CHECK:STDOUT:   %specific_fn.loc13_19.2: <specific function> = specific_function %impl.elem0.loc13_19.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc13_19.4: <bound method> = bound_method %.loc13_19.2, %specific_fn.loc13_19.2 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc13_19.4: %u1 = acquire_value %.loc13_19.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call: init bool = call %bound_method.loc13_19.4(%.loc13_19.2, %.loc13_19.4)
// CHECK:STDOUT:   %.loc13_19.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call
// CHECK:STDOUT:   %.loc13_19.6: bool = converted %UInt.as.EqWith.impl.Equal.call, %.loc13_19.5
// CHECK:STDOUT:   if %.loc13_19.6 br !match.case.then else br !match.case.else
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then:
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc13_32: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc13_32.1: <bound method> = bound_method %int_0, %impl.elem0.loc13_32 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc13_32: <specific function> = specific_function %impl.elem0.loc13_32, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc13_32.2: <bound method> = bound_method %int_0, %specific_fn.loc13_32 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13_32: init %i32 = call %bound_method.loc13_32.2(%int_0) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc13_32: init %i32 = converted %int_0, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13_32 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   return %.loc13_32
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else:
// CHECK:STDOUT:   %int_1.loc14: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc14: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc14_26.1: <bound method> = bound_method %int_1.loc14, %impl.elem0.loc14 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc14: <specific function> = specific_function %impl.elem0.loc14, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc14_26.2: <bound method> = bound_method %int_1.loc14, %specific_fn.loc14 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14: init %i32 = call %bound_method.loc14_26.2(%int_1.loc14) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc14: init %i32 = converted %int_1.loc14, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   return %.loc14
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Call() -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %P.ref.loc19_19: %P.type = name_ref P, file.%P.decl [concrete = constants.%P.generic]
// CHECK:STDOUT:   %i32.loc19_21: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %P.loc19_24: type = class_type @P, @P(constants.%i32) [concrete = constants.%P.b38]
// CHECK:STDOUT:   %.loc19_25: %P.b38 = specific_constant @P.%.loc7_1.13, @P(constants.%i32) [concrete = constants.%P.val.3d1]
// CHECK:STDOUT:   %Neither.ref: %P.b38 = name_ref Neither, %.loc19_25 [concrete = constants.%P.val.3d1]
// CHECK:STDOUT:   %.loc19_15: type = splice_block %P.loc19_15 [concrete = constants.%P.b38] {
// CHECK:STDOUT:     %P.ref.loc19_10: %P.type = name_ref P, file.%P.decl [concrete = constants.%P.generic]
// CHECK:STDOUT:     %i32.loc19_12: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %P.loc19_15: type = class_type @P, @P(constants.%i32) [concrete = constants.%P.b38]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %n: %P.b38 = wrapper_binding n, %Neither.ref
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %n.patt: %pattern_type.e96 = value_binding_pattern n [concrete = constants.%n.patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %F.ref: %F.type = name_ref F, file.%F.decl [concrete = constants.%F]
// CHECK:STDOUT:   %n.ref: %P.b38 = name_ref n, %n
// CHECK:STDOUT:   %F.call: init %i32 = call %F.ref(%n.ref)
// CHECK:STDOUT:   return %F.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @P(constants.%T.67d) {
// CHECK:STDOUT:   %T.patt.loc4_11.2 => constants.%T.patt.d47
// CHECK:STDOUT:   %T.loc4_11.1 => constants.%T.67d
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @P.Both(constants.%T.67d) {
// CHECK:STDOUT:   %T => constants.%T.67d
// CHECK:STDOUT:   %pattern_type.loc4_19.1 => constants.%pattern_type.51d1c4.1
// CHECK:STDOUT:   %_.param_patt.loc4_19.3 => constants.%_.param_patt
// CHECK:STDOUT:   %_.patt.loc4_19.3 => constants.%_.patt
// CHECK:STDOUT:   %P.loc4_19.1 => constants.%P.f86
// CHECK:STDOUT:   %.loc4_19.9 => constants.%.3a8
// CHECK:STDOUT:   %pattern_type.loc4_19.2 => constants.%pattern_type.6d3
// CHECK:STDOUT:   %return.param_patt.loc4_19.2 => constants.%return.param_patt.3b8
// CHECK:STDOUT:   %return.patt.loc4_19.2 => constants.%return.patt.ec6
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @P(constants.%i32) {
// CHECK:STDOUT:   %T.patt.loc4_11.2 => constants.%T.patt.d47
// CHECK:STDOUT:   %T.loc4_11.1 => constants.%i32
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.6b6
// CHECK:STDOUT:   %x.param_patt => constants.%x.param_patt.cee
// CHECK:STDOUT:   %x.patt => constants.%x.patt.e3b
// CHECK:STDOUT:   %y.param_patt => constants.%y.param_patt.673
// CHECK:STDOUT:   %y.patt => constants.%y.patt.547
// CHECK:STDOUT:   %require_complete.loc5 => constants.%complete_type.f8a
// CHECK:STDOUT:   %tuple.type => constants.%tuple.type.e55
// CHECK:STDOUT:   %.loc7_1.14 => constants.%.20c
// CHECK:STDOUT:   %struct_type.discriminant.payload => constants.%struct_type.discriminant.payload.92c
// CHECK:STDOUT:   %complete_type.loc7_1.2 => constants.%complete_type.ea6
// CHECK:STDOUT:   %P.Both.type => constants.%P.Both.type.571
// CHECK:STDOUT:   %P.Both => constants.%P.Both.ce5
// CHECK:STDOUT:   %P => constants.%P.b38
// CHECK:STDOUT:   %require_complete.loc7 => constants.%complete_type.ea6
// CHECK:STDOUT:   %uninit.loc7_1.2 => constants.%uninit.525
// CHECK:STDOUT:   %P.val => constants.%P.val.3d1
// CHECK:STDOUT:   %.loc7_1.15 => constants.%.b5a
// CHECK:STDOUT: }
// CHECK:STDOUT:
