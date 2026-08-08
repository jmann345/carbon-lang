// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/choice/generic_payload.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/choice/generic_payload.carbon

// Payload synthesis in generic choices (W5-S3b, fork/w5-s3/plan.md §2.2/§2.4):
// a symbolic payload type leaves the payload region's layout dependent at the
// definition — the `custom_layout_type` carries the zero-alignment sentinel —
// and monomorphization rebuilds it from the substituted field types by the
// max-of-fields rule (F-007k). Alternative constructors of a generic choice
// are themselves generic and resolve per specific. Matching is by
// discriminant here (`case` on constant alternatives plus `default`, the S1
// honesty minimum); payload destructuring on specifics is W5-S3c.

// --- optional.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
// The doc's shape (docs/design/sum_types.md): constructing and matching by
// discriminant. `Optional(i32)`'s payload region is 4 bytes ([4 x i8] in the
// lower golden): the single payload tuple `(i32,)`.
// CHECK:STDERR: optional.carbon:[[@LINE+7]]:1: error: cannot copy value of type `T` [CopyOfUncopyableType]
// CHECK:STDERR: choice Optional(T: type) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: optional.carbon:[[@LINE+4]]:1: note: type `T` does not implement interface `Core.Copy` [MissingImplInMemberAccessInContext]
// CHECK:STDERR: choice Optional(T: type) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
choice Optional(T: type) {
  Some(value: T),
  None
}

fn IsPresent(o: Optional(i32)) -> i32 {
  match (o) {
    case .None => { return 0; }
    default => { return 1; }
  }
}

fn Run() -> i32 {
  let n: Optional(i32) = Optional(i32).None;
  if (IsPresent(n) != 0) {
    return 1;
  }
  // CHECK:STDERR: optional.carbon:[[@LINE+7]]:26: error: cannot implicitly convert expression of type `Optional(T)` to `Optional(i32)` [ConversionFailure]
  // CHECK:STDERR:   let s: Optional(i32) = Optional(i32).Some(42);
  // CHECK:STDERR:                          ^~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR: optional.carbon:[[@LINE+4]]:26: note: type `Optional(T)` does not implement interface `Core.ImplicitAs(Optional(i32))` [MissingImplInMemberAccessInContext]
  // CHECK:STDERR:   let s: Optional(i32) = Optional(i32).Some(42);
  // CHECK:STDERR:                          ^~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  let s: Optional(i32) = Optional(i32).Some(42);
  return IsPresent(s) - 1;
}
//@dump-sem-ir-end

// --- destructure.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
// Payload destructuring on a CONCRETE specific became reachable at S3b — the
// parameterized alternative now has its table row, and `case .Some(v: i32)`
// resolves the payload tuple through `GetChoicePayloadInfo`'s
// specific-resolved reads (the S2c machinery under Option B) — so this
// minimal positive subfile pins the newly reachable surface. The full S3c
// scope — symbolic-payload destructuring inside a generic body, substituted
// binding conversions, imported pairs, and the sum_types.md example verbatim
// — stays S3c.
// CHECK:STDERR: destructure.carbon:[[@LINE+7]]:1: error: cannot copy value of type `T` [CopyOfUncopyableType]
// CHECK:STDERR: choice Opt(T: type) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: destructure.carbon:[[@LINE+4]]:1: note: type `T` does not implement interface `Core.Copy` [MissingImplInMemberAccessInContext]
// CHECK:STDERR: choice Opt(T: type) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
choice Opt(T: type) {
  Some(value: T),
  None
}

fn Get(o: Opt(i32)) -> i32 {
  match (o) {
    case .Some(v: i32) => { return v; }
    case .None => { return -1; }
  }
// CHECK:STDERR: destructure.carbon:[[@LINE+4]]:1: error: missing `return` at end of function with declared return type [MissingReturnStatement]
// CHECK:STDERR: }
// CHECK:STDERR: ^
// CHECK:STDERR:
}

fn Run() -> i32 {
  // CHECK:STDERR: destructure.carbon:[[@LINE+7]]:21: error: cannot implicitly convert expression of type `Opt(T)` to `Opt(i32)` [ConversionFailure]
  // CHECK:STDERR:   let s: Opt(i32) = Opt(i32).Some(42);
  // CHECK:STDERR:                     ^~~~~~~~~~~~~~~~~
  // CHECK:STDERR: destructure.carbon:[[@LINE+4]]:21: note: type `Opt(T)` does not implement interface `Core.ImplicitAs(Opt(i32))` [MissingImplInMemberAccessInContext]
  // CHECK:STDERR:   let s: Opt(i32) = Opt(i32).Some(42);
  // CHECK:STDERR:                     ^~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  let s: Opt(i32) = Opt(i32).Some(42);
  return Get(s) - 42;
}
//@dump-sem-ir-end

// --- two_sizes.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
// Two specifics of one generic choice with different payload sizes (risk
// R-1's derived numbers): `Pair(i32)`'s payload tuple is `(i32, i32)` — 8
// bytes, align 4 — and `Pair(i64)`'s is `(i64, i64)` — 16 bytes, align 8. The
// two `custom_layout_type` constants must carry distinct, recomputed numbers;
// equal or zero-sized regions (a leaked sentinel) falsify the recompute.
// CHECK:STDERR: two_sizes.carbon:[[@LINE+7]]:1: error: cannot copy value of type `T` [CopyOfUncopyableType]
// CHECK:STDERR: choice Pair(T: type) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: two_sizes.carbon:[[@LINE+4]]:1: note: type `T` does not implement interface `Core.Copy` [MissingImplInMemberAccessInContext]
// CHECK:STDERR: choice Pair(T: type) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
choice Pair(T: type) {
  Both(x: T, y: T),
  Neither
}

fn Classify32(p: Pair(i32)) -> i32 {
  match (p) {
    case .Neither => { return 0; }
    default => { return 1; }
  }
}

fn Classify64(p: Pair(i64)) -> i32 {
  match (p) {
    case .Neither => { return 0; }
    default => { return 1; }
  }
}

// Both specifics' constructors called from one function: each resolves,
// checks, and lowers per specific (risk R-3's falsifier is the pair of
// specific function bodies in the lower golden).
fn Run() -> i32 {
  // CHECK:STDERR: two_sizes.carbon:[[@LINE+7]]:22: error: cannot implicitly convert expression of type `Pair(T)` to `Pair(i32)` [ConversionFailure]
  // CHECK:STDERR:   let a: Pair(i32) = Pair(i32).Both(1, 2);
  // CHECK:STDERR:                      ^~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR: two_sizes.carbon:[[@LINE+4]]:22: note: type `Pair(T)` does not implement interface `Core.ImplicitAs(Pair(i32))` [MissingImplInMemberAccessInContext]
  // CHECK:STDERR:   let a: Pair(i32) = Pair(i32).Both(1, 2);
  // CHECK:STDERR:                      ^~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  let a: Pair(i32) = Pair(i32).Both(1, 2);
  // CHECK:STDERR: two_sizes.carbon:[[@LINE+7]]:22: error: cannot implicitly convert expression of type `Pair(T)` to `Pair(i64)` [ConversionFailure]
  // CHECK:STDERR:   let b: Pair(i64) = Pair(i64).Both(3, 4);
  // CHECK:STDERR:                      ^~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR: two_sizes.carbon:[[@LINE+4]]:22: note: type `Pair(T)` does not implement interface `Core.ImplicitAs(Pair(i64))` [MissingImplInMemberAccessInContext]
  // CHECK:STDERR:   let b: Pair(i64) = Pair(i64).Both(3, 4);
  // CHECK:STDERR:                      ^~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  let b: Pair(i64) = Pair(i64).Both(3, 4);
  return Classify32(a) + Classify64(b) - 2;
}
//@dump-sem-ir-end

// --- mixed.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
// The mixed-alternative max-of-fields pin: one concrete-payload alternative
// beside one symbolic-payload alternative. Which alternative is largest flips
// between the two pinned specifics: in `M(i8)` the concrete `(i32,)` wins — 4
// bytes, align 4 — and in `M(i64)` the substituted `(i64, i64)` wins — 16
// bytes, align 8. The constant alternative `None` adds no payload field.
// CHECK:STDERR: mixed.carbon:[[@LINE+7]]:1: error: cannot copy value of type `T` [CopyOfUncopyableType]
// CHECK:STDERR: choice M(T: type) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: mixed.carbon:[[@LINE+4]]:1: note: type `T` does not implement interface `Core.Copy` [MissingImplInMemberAccessInContext]
// CHECK:STDERR: choice M(T: type) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
choice M(T: type) {
  Small(a: i32),
  Big(x: T, y: T),
  None
}

fn F8(m: M(i8)) -> i32 {
  match (m) {
    case .None => { return 0; }
    default => { return 1; }
  }
}

fn F64(m: M(i64)) -> i32 {
  match (m) {
    case .None => { return 0; }
    default => { return 1; }
  }
}

fn Run() -> i32 {
  // CHECK:STDERR: mixed.carbon:[[@LINE+7]]:18: error: cannot implicitly convert expression of type `M(T)` to `M(i8)` [ConversionFailure]
  // CHECK:STDERR:   let s: M(i8) = M(i8).Small(1);
  // CHECK:STDERR:                  ^~~~~~~~~~~~~~
  // CHECK:STDERR: mixed.carbon:[[@LINE+4]]:18: note: type `M(T)` does not implement interface `Core.ImplicitAs(M(i8))` [MissingImplInMemberAccessInContext]
  // CHECK:STDERR:   let s: M(i8) = M(i8).Small(1);
  // CHECK:STDERR:                  ^~~~~~~~~~~~~~
  // CHECK:STDERR:
  let s: M(i8) = M(i8).Small(1);
  // CHECK:STDERR: mixed.carbon:[[@LINE+7]]:19: error: cannot implicitly convert expression of type `M(T)` to `M(i64)` [ConversionFailure]
  // CHECK:STDERR:   let b: M(i64) = M(i64).Big(3, 4);
  // CHECK:STDERR:                   ^~~~~~~~~~~~~~~~
  // CHECK:STDERR: mixed.carbon:[[@LINE+4]]:19: note: type `M(T)` does not implement interface `Core.ImplicitAs(M(i64))` [MissingImplInMemberAccessInContext]
  // CHECK:STDERR:   let b: M(i64) = M(i64).Big(3, 4);
  // CHECK:STDERR:                   ^~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  let b: M(i64) = M(i64).Big(3, 4);
  return F8(s) + F64(b) - 2;
}
//@dump-sem-ir-end

// --- concrete_payload_in_generic.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
// A generic choice whose payload types are all concrete: the layout is
// computable at the definition — no sentinel — and SF-6 validates `(i32,)`
// there, exactly as in a non-generic choice. The zero-payload `Empty()`
// alternative of a payload-carrying generic choice covers the payload field
// with an uninitialized value, as in the concrete mixed_payload_alternatives
// shape.
choice P(T: type) {
  Tag(n: i32),
  Empty(),
  None
}

fn F(p: P(bool)) -> i32 {
  match (p) {
    case .None => { return 0; }
    default => { return 1; }
  }
}

fn Run() -> i32 {
  // CHECK:STDERR: concrete_payload_in_generic.carbon:[[@LINE+7]]:20: error: cannot implicitly convert expression of type `P(T)` to `P(bool)` [ConversionFailure]
  // CHECK:STDERR:   let t: P(bool) = P(bool).Tag(7);
  // CHECK:STDERR:                    ^~~~~~~~~~~~~~
  // CHECK:STDERR: concrete_payload_in_generic.carbon:[[@LINE+4]]:20: note: type `P(T)` does not implement interface `Core.ImplicitAs(P(bool))` [MissingImplInMemberAccessInContext]
  // CHECK:STDERR:   let t: P(bool) = P(bool).Tag(7);
  // CHECK:STDERR:                    ^~~~~~~~~~~~~~
  // CHECK:STDERR:
  let t: P(bool) = P(bool).Tag(7);
  // CHECK:STDERR: concrete_payload_in_generic.carbon:[[@LINE+7]]:20: error: cannot implicitly convert expression of type `P(T)` to `P(bool)` [ConversionFailure]
  // CHECK:STDERR:   let e: P(bool) = P(bool).Empty();
  // CHECK:STDERR:                    ^~~~~~~~~~~~~~~
  // CHECK:STDERR: concrete_payload_in_generic.carbon:[[@LINE+4]]:20: note: type `P(T)` does not implement interface `Core.ImplicitAs(P(bool))` [MissingImplInMemberAccessInContext]
  // CHECK:STDERR:   let e: P(bool) = P(bool).Empty();
  // CHECK:STDERR:                    ^~~~~~~~~~~~~~~
  // CHECK:STDERR:
  let e: P(bool) = P(bool).Empty();
  return F(t) + F(e) - 2;
}
//@dump-sem-ir-end

// CHECK:STDOUT: --- optional.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %.Self.frozen.197: %type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %pattern_type.98f: type = pattern_type type [concrete]
// CHECK:STDOUT:   %T.patt.d47: %pattern_type.98f = symbolic_binding_pattern T, 0 [symbolic]
// CHECK:STDOUT:   %T.67d: type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %Optional.type: type = generic_class_type @Optional [concrete]
// CHECK:STDOUT:   %Optional.generic: %Optional.type = struct_value () [concrete]
// CHECK:STDOUT:   %Optional.b33: type = class_type @Optional, @Optional(%T.67d) [symbolic]
// CHECK:STDOUT:   %pattern_type.51d1c4.1: type = pattern_type %T.67d [symbolic]
// CHECK:STDOUT:   %value.param_patt.98e: %pattern_type.51d1c4.1 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %value.patt.864: %pattern_type.51d1c4.1 = at_binding_pattern value, %value.param_patt.98e [symbolic]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %u1: type = class_type @UInt, @UInt(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %require_complete.944: <witness> = require_complete_type %T.67d [symbolic]
// CHECK:STDOUT:   %tuple.type.026: type = tuple_type (%T.67d) [symbolic]
// CHECK:STDOUT:   %.a2d: type = custom_layout_type {size=0, align=0, .Some@0: %tuple.type.026} [symbolic]
// CHECK:STDOUT:   %struct_type.discriminant.payload.508: type = struct_type {.discriminant: %u1, .payload: %.a2d} [symbolic]
// CHECK:STDOUT:   %complete_type.abf: <witness> = complete_type_witness %struct_type.discriminant.payload.508 [symbolic]
// CHECK:STDOUT:   %struct_type.discriminant: type = struct_type {.discriminant: %u1} [concrete]
// CHECK:STDOUT:   %_.param_patt.339: %pattern_type.51d1c4.1 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %_.patt.fd3: %pattern_type.51d1c4.1 = at_binding_pattern _, %_.param_patt.339 [symbolic]
// CHECK:STDOUT:   %.104: Core.Form = init_form %Optional.b33 [symbolic]
// CHECK:STDOUT:   %pattern_type.385: type = pattern_type %Optional.b33 [symbolic]
// CHECK:STDOUT:   %return.param_patt.2f8: %pattern_type.385 = out_param_pattern [symbolic]
// CHECK:STDOUT:   %return.patt.847: %pattern_type.385 = return_slot_pattern %return.param_patt.2f8, %Optional.b33 [symbolic]
// CHECK:STDOUT:   %Optional.Some.type.d69: type = fn_type @Optional.Some, @Optional(%T.67d) [symbolic]
// CHECK:STDOUT:   %Optional.Some.424: %Optional.Some.type.d69 = struct_value () [symbolic]
// CHECK:STDOUT:   %require_complete.85c: <witness> = require_complete_type %Optional.b33 [symbolic]
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
// CHECK:STDOUT:   %require_complete.48b: <witness> = require_complete_type %tuple.type.026 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %bound_method.d7a: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
// CHECK:STDOUT:   %int_1.233: %u1 = int_value 1 [concrete]
// CHECK:STDOUT:   %struct: %struct_type.discriminant = struct_value (%int_1.233) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.type.0c5: type = fn_type @UInt.as.Copy.impl.Op, @UInt.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.38a: %UInt.as.Copy.impl.Op.type.0c5 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.fb7: <witness> = impl_witness imports.%Copy.impl_witness_table.fe3, @UInt.as.Copy.impl(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.type.c97: type = fn_type @UInt.as.Copy.impl.Op, @UInt.as.Copy.impl(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.d9c: %UInt.as.Copy.impl.Op.type.c97 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet: %Copy.type = facet_value %u1, (%Copy.impl_witness.fb7) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.4d4: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet) [concrete]
// CHECK:STDOUT:   %.37a: type = fn_type_with_self_type %Copy.WithSelf.Op.type.4d4, %Copy.facet [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.bound: <bound method> = bound_method %int_1.233, %UInt.as.Copy.impl.Op.d9c [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %UInt.as.Copy.impl.Op.d9c, @UInt.as.Copy.impl.Op(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.edd: <bound method> = bound_method %int_1.233, %UInt.as.Copy.impl.Op.specific_fn [concrete]
// CHECK:STDOUT:   %uninit.37a: %.a2d = uninitialized_value [symbolic]
// CHECK:STDOUT:   %Optional.val.035: %Optional.b33 = struct_value (%int_1.233, %uninit.37a) [symbolic]
// CHECK:STDOUT:   %.fcc: ref %Optional.b33 = temporary invalid, %Optional.val.035 [symbolic]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %Int.67af24.1: type = class_type @Int, @Int(%N) [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %Optional.d7e: type = class_type @Optional, @Optional(%i32) [concrete]
// CHECK:STDOUT:   %pattern_type.e8f: type = pattern_type %Optional.d7e [concrete]
// CHECK:STDOUT:   %o.param_patt: %pattern_type.e8f = value_param_pattern [concrete]
// CHECK:STDOUT:   %o.patt: %pattern_type.e8f = at_binding_pattern o, %o.param_patt [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %IsPresent.type: type = fn_type @IsPresent [concrete]
// CHECK:STDOUT:   %IsPresent: %IsPresent.type = struct_value () [concrete]
// CHECK:STDOUT:   %value.param_patt.34f: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %value.patt.f6a: %pattern_type.6b6 = at_binding_pattern value, %value.param_patt.34f [concrete]
// CHECK:STDOUT:   %i32.builtin: type = int_type signed, %int_32 [concrete]
// CHECK:STDOUT:   %complete_type.f8a: <witness> = complete_type_witness %i32.builtin [concrete]
// CHECK:STDOUT:   %tuple.type.a8a: type = tuple_type (%i32) [concrete]
// CHECK:STDOUT:   %.e8e: type = custom_layout_type {size=4, align=4, .Some@0: %tuple.type.a8a} [concrete]
// CHECK:STDOUT:   %struct_type.discriminant.payload.e99: type = struct_type {.discriminant: %u1, .payload: %.e8e} [concrete]
// CHECK:STDOUT:   %complete_type.378: <witness> = complete_type_witness %struct_type.discriminant.payload.e99 [concrete]
// CHECK:STDOUT:   %Optional.Some.type.fb9: type = fn_type @Optional.Some, @Optional(%i32) [concrete]
// CHECK:STDOUT:   %Optional.Some.f27: %Optional.Some.type.fb9 = struct_value () [concrete]
// CHECK:STDOUT:   %uninit.060: %.e8e = uninitialized_value [concrete]
// CHECK:STDOUT:   %Optional.val.dae: %Optional.d7e = struct_value (%int_1.233, %uninit.060) [concrete]
// CHECK:STDOUT:   %.236: ref %Optional.d7e = temporary invalid, %Optional.val.dae [concrete]
// CHECK:STDOUT:   %EqWith.type.c25: type = facet_type <@EqWith, @EqWith(%u1)> [concrete]
// CHECK:STDOUT:   %M: Core.IntLiteral = symbolic_binding M, 1 [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.544: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%N, %M) [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.c67: %UInt.as.EqWith.impl.Equal.type.544 = struct_value () [symbolic]
// CHECK:STDOUT:   %EqWith.type.aee: type = facet_type <@EqWith, @EqWith(Core.IntLiteral)> [concrete]
// CHECK:STDOUT:   %EqWith.impl_witness.d63: <witness> = impl_witness imports.%EqWith.impl_witness_table.cbd, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.29b: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.ba4: %UInt.as.EqWith.impl.Equal.type.29b = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.3b6: %EqWith.type.c25 = facet_value %u1, (%EqWith.impl_witness.d63) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.922: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%u1, %EqWith.facet.3b6) [concrete]
// CHECK:STDOUT:   %.9ed: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.922, %EqWith.facet.3b6 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.specific_fn.6b6: <specific function> = specific_function %UInt.as.EqWith.impl.Equal.ba4, @UInt.as.EqWith.impl.Equal.1(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.a82: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
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
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.953: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT:   %Run.type: type = fn_type @Run [concrete]
// CHECK:STDOUT:   %Run: %Run.type = struct_value () [concrete]
// CHECK:STDOUT:   %n.patt: %pattern_type.e8f = value_binding_pattern n [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.f7de31.2: type = facet_type <@ImplicitAs, @ImplicitAs(%Int.67af24.1)> [symbolic]
// CHECK:STDOUT:   %T.4e6: %ImplicitAs.type.f7de31.2 = symbolic_binding T, 1 [symbolic]
// CHECK:STDOUT:   %Int.as.EqWith.impl.NotEqual.type.97ec42.1: type = fn_type @Int.as.EqWith.impl.NotEqual.3, @Int.as.EqWith.impl.2b8(%N, %T.4e6) [symbolic]
// CHECK:STDOUT:   %Int.as.EqWith.impl.NotEqual.c6c584.1: %Int.as.EqWith.impl.NotEqual.type.97ec42.1 = struct_value () [symbolic]
// CHECK:STDOUT:   %Int.as.EqWith.impl.NotEqual.type.97ec42.2: type = fn_type @Int.as.EqWith.impl.NotEqual.4, @Int.as.EqWith.impl.2b8(%N, %T.4e6) [symbolic]
// CHECK:STDOUT:   %Int.as.EqWith.impl.NotEqual.c6c584.2: %Int.as.EqWith.impl.NotEqual.type.97ec42.2 = struct_value () [symbolic]
// CHECK:STDOUT:   %EqWith.impl_witness.d35: <witness> = impl_witness imports.%EqWith.impl_witness_table.fec, @Int.as.EqWith.impl.2b8(%int_32, %ImplicitAs.facet.9f1) [concrete]
// CHECK:STDOUT:   %Int.as.EqWith.impl.NotEqual.type.2f6aaa.1: type = fn_type @Int.as.EqWith.impl.NotEqual.4, @Int.as.EqWith.impl.2b8(%int_32, %ImplicitAs.facet.9f1) [concrete]
// CHECK:STDOUT:   %Int.as.EqWith.impl.NotEqual.48041c.1: %Int.as.EqWith.impl.NotEqual.type.2f6aaa.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Int.as.EqWith.impl.NotEqual.type.2f6aaa.2: type = fn_type @Int.as.EqWith.impl.NotEqual.3, @Int.as.EqWith.impl.2b8(%int_32, %ImplicitAs.facet.9f1) [concrete]
// CHECK:STDOUT:   %Int.as.EqWith.impl.NotEqual.48041c.2: %Int.as.EqWith.impl.NotEqual.type.2f6aaa.2 = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.1db: %EqWith.type.aee = facet_value %i32, (%EqWith.impl_witness.d35) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.NotEqual.type.865: type = fn_type @EqWith.WithSelf.NotEqual, @EqWith.WithSelf(Core.IntLiteral, %EqWith.facet.1db) [concrete]
// CHECK:STDOUT:   %.abf9: type = fn_type_with_self_type %EqWith.WithSelf.NotEqual.type.865, %EqWith.facet.1db [concrete]
// CHECK:STDOUT:   %Int.as.EqWith.impl.NotEqual.specific_fn.3df7ac.1: <specific function> = specific_function %Int.as.EqWith.impl.NotEqual.48041c.2, @Int.as.EqWith.impl.NotEqual.3(%int_32, %ImplicitAs.facet.9f1) [concrete]
// CHECK:STDOUT:   %Int.as.EqWith.impl.NotEqual.specific_fn.3df7ac.2: <specific function> = specific_function %Int.as.EqWith.impl.NotEqual.48041c.1, @Int.as.EqWith.impl.NotEqual.4(%int_32, %ImplicitAs.facet.9f1) [concrete]
// CHECK:STDOUT:   %s.patt: %pattern_type.e8f = value_binding_pattern s [concrete]
// CHECK:STDOUT:   %int_42.20e: Core.IntLiteral = int_value 42 [concrete]
// CHECK:STDOUT:   %_.param_patt.fb2: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %_.patt.b75: %pattern_type.6b6 = at_binding_pattern _, %_.param_patt.fb2 [concrete]
// CHECK:STDOUT:   %.da75: Core.Form = init_form %Optional.d7e [concrete]
// CHECK:STDOUT:   %return.param_patt.f4f: %pattern_type.e8f = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.882: %pattern_type.e8f = return_slot_pattern %return.param_patt.f4f, %Optional.d7e [concrete]
// CHECK:STDOUT:   %Optional.Some.specific_fn: <specific function> = specific_function %Optional.Some.f27, @Optional.Some(%i32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.bf3: <bound method> = bound_method %int_42.20e, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.098: <bound method> = bound_method %int_42.20e, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_42.ac4: %i32 = int_value 42 [concrete]
// CHECK:STDOUT:   %SubWith.type.4c2: type = facet_type <@SubWith, @SubWith(Core.IntLiteral)> [concrete]
// CHECK:STDOUT:   %U.4e6: %ImplicitAs.type.f7de31.2 = symbolic_binding U, 1 [symbolic]
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
// CHECK:STDOUT:   %complete_type.147: <witness> = complete_type_witness %tuple.type.a8a [concrete]
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
// CHECK:STDOUT:   %Core.import_ref.7a7 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.fb5: @Int.as.EqWith.impl.2b8.%Int.as.EqWith.impl.NotEqual.type.2 (%Int.as.EqWith.impl.NotEqual.type.97ec42.1) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.EqWith.impl.2b8.%Int.as.EqWith.impl.NotEqual.2 (constants.%Int.as.EqWith.impl.NotEqual.c6c584.1)]
// CHECK:STDOUT:   %EqWith.impl_witness_table.fec = impl_witness_table (%Core.import_ref.7a7, %Core.import_ref.fb5), @Int.as.EqWith.impl.2b8 [concrete]
// CHECK:STDOUT:   %Core.NotEqual.c83: @Int.as.EqWith.impl.2b8.%Int.as.EqWith.impl.NotEqual.type.1 (%Int.as.EqWith.impl.NotEqual.type.97ec42.2) = import_ref Core//prelude/types/int, NotEqual, loaded [symbolic = @Int.as.EqWith.impl.2b8.%Int.as.EqWith.impl.NotEqual.1 (constants.%Int.as.EqWith.impl.NotEqual.c6c584.2)]
// CHECK:STDOUT:   %Core.import_ref.b4fd3a.2 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.6fa: @Int.as.SubWith.impl.dc8.%Int.as.SubWith.impl.Op.type.2 (%Int.as.SubWith.impl.Op.type.6f3321.1) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.SubWith.impl.dc8.%Int.as.SubWith.impl.Op.2 (constants.%Int.as.SubWith.impl.Op.a37528.1)]
// CHECK:STDOUT:   %SubWith.impl_witness_table.dc9 = impl_witness_table (%Core.import_ref.b4fd3a.2, %Core.import_ref.6fa), @Int.as.SubWith.impl.dc8 [concrete]
// CHECK:STDOUT:   %Core.Op.9ff: @Int.as.SubWith.impl.dc8.%Int.as.SubWith.impl.Op.type.1 (%Int.as.SubWith.impl.Op.type.6f3321.2) = import_ref Core//prelude/types/int, Op, loaded [symbolic = @Int.as.SubWith.impl.dc8.%Int.as.SubWith.impl.Op.1 (constants.%Int.as.SubWith.impl.Op.a37528.2)]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %Optional.Some.decl: @Optional.%Optional.Some.type (%Optional.Some.type.d69) = fn_decl @Optional.Some [symbolic = @Optional.%Optional.Some (constants.%Optional.Some.424)] {
// CHECK:STDOUT:     %_.param_patt.loc7_26.1: @Optional.Some.%pattern_type.loc7_26.1 (%pattern_type.51d1c4.1) = value_param_pattern [symbolic = %_.param_patt.loc7_26.2 (constants.%_.param_patt.339)]
// CHECK:STDOUT:     %_.patt.loc7_26.1: @Optional.Some.%pattern_type.loc7_26.1 (%pattern_type.51d1c4.1) = at_binding_pattern _, %_.param_patt.loc7_26.1 [symbolic = %_.patt.loc7_26.2 (constants.%_.patt.fd3)]
// CHECK:STDOUT:     %return.param_patt.loc7_26.1: @Optional.Some.%pattern_type.loc7_26.2 (%pattern_type.385) = out_param_pattern [symbolic = %return.param_patt.loc7_26.2 (constants.%return.param_patt.2f8)]
// CHECK:STDOUT:     %return.patt.loc7_26.1: @Optional.Some.%pattern_type.loc7_26.2 (%pattern_type.385) = return_slot_pattern %return.param_patt.loc7_26.1, constants.%Optional.b33 [symbolic = %return.patt.loc7_26.2 (constants.%return.patt.847)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc7_26.9: Core.Form = init_form constants.%Optional.b33 [symbolic = %.loc7_26.7 (constants.%.104)]
// CHECK:STDOUT:     %_.param: @Optional.Some.%T (%T.67d) = value_param call_param0
// CHECK:STDOUT:     %_: @Optional.Some.%T (%T.67d) = wrapper_binding _, %_.param
// CHECK:STDOUT:     %return.param: ref @Optional.Some.%Optional (%Optional.b33) = out_param call_param1
// CHECK:STDOUT:     %return: ref @Optional.Some.%Optional (%Optional.b33) = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Optional.decl: %Optional.type = class_decl @Optional [concrete = constants.%Optional.generic] {
// CHECK:STDOUT:     %T.patt.loc7_18.1: %pattern_type.98f = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc7_18.2 (constants.%T.patt.d47)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc7_20.1: type = splice_block %.loc7_20.2 [concrete = type] {
// CHECK:STDOUT:       %.Self.frozen: %type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen.197]
// CHECK:STDOUT:       %.loc7_20.2: type = type_literal type [concrete = type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc7_18.2: type = symbolic_binding T, 0 [symbolic = %T.loc7_18.1 (constants.%T.67d)]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %IsPresent.decl: %IsPresent.type = fn_decl @IsPresent [concrete = constants.%IsPresent] {
// CHECK:STDOUT:     %o.param_patt: %pattern_type.e8f = value_param_pattern [concrete = constants.%o.param_patt]
// CHECK:STDOUT:     %o.patt: %pattern_type.e8f = at_binding_pattern o, %o.param_patt [concrete = constants.%o.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc12_35 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc12_35: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc12_35: Core.Form = init_form %i32.loc12_35 [concrete = constants.%.795f]
// CHECK:STDOUT:     %o.param: %Optional.d7e = value_param call_param0
// CHECK:STDOUT:     %.loc12_29: type = splice_block %Optional [concrete = constants.%Optional.d7e] {
// CHECK:STDOUT:       %Optional.ref: %Optional.type = name_ref Optional, file.%Optional.decl [concrete = constants.%Optional.generic]
// CHECK:STDOUT:       %i32.loc12_26: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %Optional: type = class_type @Optional, @Optional(constants.%i32) [concrete = constants.%Optional.d7e]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %o: %Optional.d7e = wrapper_binding o, %o.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Run.decl: %Run.type = fn_decl @Run [concrete = constants.%Run] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc19 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc19: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc19: Core.Form = init_form %i32.loc19 [concrete = constants.%.795f]
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param0
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic class @Optional(%T.loc7_18.2: type) {
// CHECK:STDOUT:   %T.patt.loc7_18.2: %pattern_type.98f = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc7_18.2 (constants.%T.patt.d47)]
// CHECK:STDOUT:   %T.loc7_18.1: type = symbolic_binding T, 0 [symbolic = %T.loc7_18.1 (constants.%T.67d)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %pattern_type: type = pattern_type %T.loc7_18.1 [symbolic = %pattern_type (constants.%pattern_type.51d1c4.1)]
// CHECK:STDOUT:   %value.param_patt: @Optional.%pattern_type (%pattern_type.51d1c4.1) = value_param_pattern [symbolic = %value.param_patt (constants.%value.param_patt.98e)]
// CHECK:STDOUT:   %value.patt: @Optional.%pattern_type (%pattern_type.51d1c4.1) = at_binding_pattern value, %value.param_patt [symbolic = %value.patt (constants.%value.patt.864)]
// CHECK:STDOUT:   %require_complete.loc8: <witness> = require_complete_type %T.loc7_18.1 [symbolic = %require_complete.loc8 (constants.%require_complete.944)]
// CHECK:STDOUT:   %tuple.type: type = tuple_type (%T.loc7_18.1) [symbolic = %tuple.type (constants.%tuple.type.026)]
// CHECK:STDOUT:   %.loc10_1.14: type = custom_layout_type {size=0, align=0, .Some@0: @Optional.%tuple.type (%tuple.type.026)} [symbolic = %.loc10_1.14 (constants.%.a2d)]
// CHECK:STDOUT:   %struct_type.discriminant.payload: type = struct_type {.discriminant: %u1, .payload: @Optional.%.loc10_1.14 (%.a2d)} [symbolic = %struct_type.discriminant.payload (constants.%struct_type.discriminant.payload.508)]
// CHECK:STDOUT:   %complete_type.loc10_1.2: <witness> = complete_type_witness %struct_type.discriminant.payload [symbolic = %complete_type.loc10_1.2 (constants.%complete_type.abf)]
// CHECK:STDOUT:   %Optional.Some.type: type = fn_type @Optional.Some, @Optional(%T.loc7_18.1) [symbolic = %Optional.Some.type (constants.%Optional.Some.type.d69)]
// CHECK:STDOUT:   %Optional.Some: @Optional.%Optional.Some.type (%Optional.Some.type.d69) = struct_value () [symbolic = %Optional.Some (constants.%Optional.Some.424)]
// CHECK:STDOUT:   %Optional: type = class_type @Optional, @Optional(%T.loc7_18.1) [symbolic = %Optional (constants.%Optional.b33)]
// CHECK:STDOUT:   %require_complete.loc10: <witness> = require_complete_type %Optional [symbolic = %require_complete.loc10 (constants.%require_complete.85c)]
// CHECK:STDOUT:   %uninit.loc10_1.2: @Optional.%.loc10_1.14 (%.a2d) = uninitialized_value [symbolic = %uninit.loc10_1.2 (constants.%uninit.37a)]
// CHECK:STDOUT:   %Optional.val: @Optional.%Optional (%Optional.b33) = struct_value (constants.%int_1.233, %uninit.loc10_1.2) [symbolic = %Optional.val (constants.%Optional.val.035)]
// CHECK:STDOUT:   %.loc10_1.15: ref @Optional.%Optional (%Optional.b33) = temporary invalid, %Optional.val [symbolic = %.loc10_1.15 (constants.%.fcc)]
// CHECK:STDOUT:
// CHECK:STDOUT:   class {
// CHECK:STDOUT:     %value.param: @Optional.%T.loc7_18.1 (%T.67d) = value_param call_param0
// CHECK:STDOUT:     %T.ref: type = name_ref T, %T.loc7_18.2 [symbolic = %T.loc7_18.1 (constants.%T.67d)]
// CHECK:STDOUT:     %value: @Optional.%T.loc7_18.1 (%T.67d) = wrapper_binding value, %value.param
// CHECK:STDOUT:     %.loc10_1.1: type = custom_layout_type {size=0, align=0, .Some@0: %tuple.type.026} [symbolic = %.loc10_1.14 (constants.%.a2d)]
// CHECK:STDOUT:     %complete_type.loc10_1.1: <witness> = complete_type_witness constants.%struct_type.discriminant.payload.508 [symbolic = %complete_type.loc10_1.2 (constants.%complete_type.abf)]
// CHECK:STDOUT:     %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:     %impl.elem0.loc10_1.1: %.e60 = impl_witness_access constants.%ImplicitAs.impl_witness.9a9, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:     %bound_method.loc10_1.1: <bound method> = bound_method %int_1, %impl.elem0.loc10_1.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:     %specific_fn.loc10_1.1: <specific function> = specific_function %impl.elem0.loc10_1.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:     %bound_method.loc10_1.2: <bound method> = bound_method %int_1, %specific_fn.loc10_1.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %u1 = call %bound_method.loc10_1.2(%int_1) [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc10_1.2: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc10_1.3: %u1 = converted %int_1, %.loc10_1.2 [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc10_1.4: %struct_type.discriminant = struct_literal (%.loc10_1.3) [concrete = constants.%struct]
// CHECK:STDOUT:     %impl.elem0.loc10_1.2: %.37a = impl_witness_access constants.%Copy.impl_witness.fb7, element0 [concrete = constants.%UInt.as.Copy.impl.Op.d9c]
// CHECK:STDOUT:     %bound_method.loc10_1.3: <bound method> = bound_method %.loc10_1.3, %impl.elem0.loc10_1.2 [concrete = constants.%UInt.as.Copy.impl.Op.bound]
// CHECK:STDOUT:     %specific_fn.loc10_1.2: <specific function> = specific_function %impl.elem0.loc10_1.2, @UInt.as.Copy.impl.Op(constants.%int_1.5b8) [concrete = constants.%UInt.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:     %bound_method.loc10_1.4: <bound method> = bound_method %.loc10_1.3, %specific_fn.loc10_1.2 [concrete = constants.%bound_method.edd]
// CHECK:STDOUT:     %UInt.as.Copy.impl.Op.call: init %u1 = call %bound_method.loc10_1.4(%.loc10_1.3) [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc10_1.5: ref @Optional.%Optional (%Optional.b33) = temporary_storage
// CHECK:STDOUT:     %.loc10_1.6: ref %u1 = class_element_access %.loc10_1.5, element0
// CHECK:STDOUT:     %.loc10_1.7: init %u1 to %.loc10_1.6 = in_place_init %UInt.as.Copy.impl.Op.call [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc10_1.8: ref @Optional.%.loc10_1.14 (%.a2d) = class_element_access %.loc10_1.5, element1
// CHECK:STDOUT:     %uninit.loc10_1.1: @Optional.%.loc10_1.14 (%.a2d) = uninitialized_value [symbolic = %uninit.loc10_1.2 (constants.%uninit.37a)]
// CHECK:STDOUT:     %.loc10_1.9: init @Optional.%.loc10_1.14 (%.a2d) to %.loc10_1.8 = in_place_init %uninit.loc10_1.1 [symbolic = %uninit.loc10_1.2 (constants.%uninit.37a)]
// CHECK:STDOUT:     %.loc10_1.10: init @Optional.%Optional (%Optional.b33) to %.loc10_1.5 = class_init (%.loc10_1.7, %.loc10_1.9) [symbolic = %Optional.val (constants.%Optional.val.035)]
// CHECK:STDOUT:     %.loc10_1.11: init @Optional.%Optional (%Optional.b33) = converted %.loc10_1.4, %.loc10_1.10 [symbolic = %Optional.val (constants.%Optional.val.035)]
// CHECK:STDOUT:     %.loc10_1.12: ref @Optional.%Optional (%Optional.b33) = temporary %.loc10_1.5, %.loc10_1.11 [symbolic = %.loc10_1.15 (constants.%.fcc)]
// CHECK:STDOUT:     %.loc10_1.13: @Optional.%Optional (%Optional.b33) = acquire_value %.loc10_1.12 [symbolic = %Optional.val (constants.%Optional.val.035)]
// CHECK:STDOUT:     %None: @Optional.%Optional (%Optional.b33) = wrapper_binding None, %.loc10_1.13
// CHECK:STDOUT:     complete_type_witness = %complete_type.loc10_1.1
// CHECK:STDOUT:
// CHECK:STDOUT:   !members:
// CHECK:STDOUT:     .Self = constants.%Optional.b33
// CHECK:STDOUT:     .T = <poisoned>
// CHECK:STDOUT:     .Some = generated.%Optional.Some.decl
// CHECK:STDOUT:     .None = %None
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @Optional.Some(@Optional.%T.loc7_18.2: type) {
// CHECK:STDOUT:   %T: type = symbolic_binding T, 0 [symbolic = %T (constants.%T.67d)]
// CHECK:STDOUT:   %pattern_type.loc7_26.1: type = pattern_type %T [symbolic = %pattern_type.loc7_26.1 (constants.%pattern_type.51d1c4.1)]
// CHECK:STDOUT:   %_.param_patt.loc7_26.2: @Optional.Some.%pattern_type.loc7_26.1 (%pattern_type.51d1c4.1) = value_param_pattern [symbolic = %_.param_patt.loc7_26.2 (constants.%_.param_patt.339)]
// CHECK:STDOUT:   %_.patt.loc7_26.2: @Optional.Some.%pattern_type.loc7_26.1 (%pattern_type.51d1c4.1) = at_binding_pattern _, %_.param_patt.loc7_26.2 [symbolic = %_.patt.loc7_26.2 (constants.%_.patt.fd3)]
// CHECK:STDOUT:   %Optional: type = class_type @Optional, @Optional(%T) [symbolic = %Optional (constants.%Optional.b33)]
// CHECK:STDOUT:   %.loc7_26.7: Core.Form = init_form %Optional [symbolic = %.loc7_26.7 (constants.%.104)]
// CHECK:STDOUT:   %pattern_type.loc7_26.2: type = pattern_type %Optional [symbolic = %pattern_type.loc7_26.2 (constants.%pattern_type.385)]
// CHECK:STDOUT:   %return.param_patt.loc7_26.2: @Optional.Some.%pattern_type.loc7_26.2 (%pattern_type.385) = out_param_pattern [symbolic = %return.param_patt.loc7_26.2 (constants.%return.param_patt.2f8)]
// CHECK:STDOUT:   %return.patt.loc7_26.2: @Optional.Some.%pattern_type.loc7_26.2 (%pattern_type.385) = return_slot_pattern %return.param_patt.loc7_26.2, %Optional [symbolic = %return.patt.loc7_26.2 (constants.%return.patt.847)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc7_26.1: <witness> = require_complete_type %T [symbolic = %require_complete.loc7_26.1 (constants.%require_complete.944)]
// CHECK:STDOUT:   %require_complete.loc7_26.2: <witness> = require_complete_type %Optional [symbolic = %require_complete.loc7_26.2 (constants.%require_complete.85c)]
// CHECK:STDOUT:   %tuple.type: type = tuple_type (%T) [symbolic = %tuple.type (constants.%tuple.type.026)]
// CHECK:STDOUT:   %.loc7_26.8: type = custom_layout_type {size=0, align=0, .Some@0: @Optional.Some.%tuple.type (%tuple.type.026)} [symbolic = %.loc7_26.8 (constants.%.a2d)]
// CHECK:STDOUT:   %require_complete.loc7_26.3: <witness> = require_complete_type %tuple.type [symbolic = %require_complete.loc7_26.3 (constants.%require_complete.48b)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%_.param: @Optional.Some.%T (%T.67d)) -> out %return.param: @Optional.Some.%Optional (%Optional.b33) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %.loc7_26.1: ref %u1 = class_element_access %return.param, element0
// CHECK:STDOUT:     %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:     %impl.elem0: %.e60 = impl_witness_access constants.%ImplicitAs.impl_witness.9a9, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:     %bound_method.loc7_26.1: <bound method> = bound_method %int_0, %impl.elem0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:     %specific_fn: <specific function> = specific_function %impl.elem0, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:     %bound_method.loc7_26.2: <bound method> = bound_method %int_0, %specific_fn [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %u1 = call %bound_method.loc7_26.2(%int_0) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:     %.loc7_26.2: init %u1 = converted %int_0, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:     %.loc7_26.3: init %u1 to %.loc7_26.1 = in_place_init %.loc7_26.2 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:     %.loc7_26.4: ref @Optional.Some.%.loc7_26.8 (%.a2d) = class_element_access %return.param, element1
// CHECK:STDOUT:     %.loc7_26.5: ref @Optional.Some.%tuple.type (%tuple.type.026) = class_element_access %.loc7_26.4, element0
// CHECK:STDOUT:     %.loc8: @Optional.Some.%tuple.type (%tuple.type.026) = tuple_literal (%_.param)
// CHECK:STDOUT:     %.loc7_26.6: init @Optional.Some.%Optional (%Optional.b33) to %return.param = class_init (%.loc7_26.3, <error>) [concrete = <error>]
// CHECK:STDOUT:     return %.loc7_26.6 to %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @IsPresent(%o.param: %Optional.d7e) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %o.ref: %Optional.d7e = name_ref o, %o
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt: %pattern_type.e8f = expr_pattern %None.ref in [concrete] {
// CHECK:STDOUT:       %.loc14_10.2: %Optional.d7e = specific_constant @Optional.%.loc10_1.13, @Optional(constants.%i32) [concrete = constants.%Optional.val.dae]
// CHECK:STDOUT:       %None.ref: %Optional.d7e = name_ref None, %.loc14_10.2 [concrete = constants.%Optional.val.dae]
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %.loc14_10.1: %Optional.d7e = splice_block %None.ref [concrete = constants.%Optional.val.dae] {
// CHECK:STDOUT:     %.loc14_10.2: %Optional.d7e = specific_constant @Optional.%.loc10_1.13, @Optional(constants.%i32) [concrete = constants.%Optional.val.dae]
// CHECK:STDOUT:     %None.ref: %Optional.d7e = name_ref None, %.loc14_10.2 [concrete = constants.%Optional.val.dae]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_1.loc14: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc14_16.1: %.e60 = impl_witness_access constants.%ImplicitAs.impl_witness.9a9, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc14_16.1: <bound method> = bound_method %int_1.loc14, %impl.elem0.loc14_16.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc14_16.1: <specific function> = specific_function %impl.elem0.loc14_16.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc14_16.2: <bound method> = bound_method %int_1.loc14, %specific_fn.loc14_16.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14_16: init %u1 = call %bound_method.loc14_16.2(%int_1.loc14) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc14_16.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14_16 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc14_16.2: %u1 = converted %int_1.loc14, %.loc14_16.1 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc14_16.3: ref %u1 = class_element_access %o.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc14_16.2: %.9ed = impl_witness_access constants.%EqWith.impl_witness.d63, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc14_16.3: <bound method> = bound_method %.loc14_16.2, %impl.elem0.loc14_16.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound]
// CHECK:STDOUT:   %specific_fn.loc14_16.2: <specific function> = specific_function %impl.elem0.loc14_16.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc14_16.4: <bound method> = bound_method %.loc14_16.2, %specific_fn.loc14_16.2 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc14_16.4: %u1 = acquire_value %.loc14_16.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call: init bool = call %bound_method.loc14_16.4(%.loc14_16.2, %.loc14_16.4)
// CHECK:STDOUT:   %.loc14_16.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call
// CHECK:STDOUT:   %.loc14_16.6: bool = converted %UInt.as.EqWith.impl.Equal.call, %.loc14_16.5
// CHECK:STDOUT:   if %.loc14_16.6 br !match.case.then else br !match.case.else
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then:
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc14_29: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc14_29.1: <bound method> = bound_method %int_0, %impl.elem0.loc14_29 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc14_29: <specific function> = specific_function %impl.elem0.loc14_29, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc14_29.2: <bound method> = bound_method %int_0, %specific_fn.loc14_29 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14_29: init %i32 = call %bound_method.loc14_29.2(%int_0) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc14_29: init %i32 = converted %int_0, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14_29 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   return %.loc14_29
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else:
// CHECK:STDOUT:   %int_1.loc15: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc15: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc15_26.1: <bound method> = bound_method %int_1.loc15, %impl.elem0.loc15 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc15: <specific function> = specific_function %impl.elem0.loc15, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc15_26.2: <bound method> = bound_method %int_1.loc15, %specific_fn.loc15 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc15: init %i32 = call %bound_method.loc15_26.2(%int_1.loc15) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc15: init %i32 = converted %int_1.loc15, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc15 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   return %.loc15
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Run() -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Optional.ref.loc20_26: %Optional.type = name_ref Optional, file.%Optional.decl [concrete = constants.%Optional.generic]
// CHECK:STDOUT:   %i32.loc20_35: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %Optional.loc20_38: type = class_type @Optional, @Optional(constants.%i32) [concrete = constants.%Optional.d7e]
// CHECK:STDOUT:   %.loc20_39: %Optional.d7e = specific_constant @Optional.%.loc10_1.13, @Optional(constants.%i32) [concrete = constants.%Optional.val.dae]
// CHECK:STDOUT:   %None.ref: %Optional.d7e = name_ref None, %.loc20_39 [concrete = constants.%Optional.val.dae]
// CHECK:STDOUT:   %.loc20_22: type = splice_block %Optional.loc20_22 [concrete = constants.%Optional.d7e] {
// CHECK:STDOUT:     %Optional.ref.loc20_10: %Optional.type = name_ref Optional, file.%Optional.decl [concrete = constants.%Optional.generic]
// CHECK:STDOUT:     %i32.loc20_19: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %Optional.loc20_22: type = class_type @Optional, @Optional(constants.%i32) [concrete = constants.%Optional.d7e]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %n: %Optional.d7e = wrapper_binding n, %None.ref
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %n.patt: %pattern_type.e8f = value_binding_pattern n [concrete = constants.%n.patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %IsPresent.ref.loc21: %IsPresent.type = name_ref IsPresent, file.%IsPresent.decl [concrete = constants.%IsPresent]
// CHECK:STDOUT:   %n.ref: %Optional.d7e = name_ref n, %n
// CHECK:STDOUT:   %IsPresent.call.loc21: init %i32 = call %IsPresent.ref.loc21(%n.ref)
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem1.loc21: %.abf9 = impl_witness_access constants.%EqWith.impl_witness.d35, element1 [concrete = constants.%Int.as.EqWith.impl.NotEqual.48041c.2]
// CHECK:STDOUT:   %bound_method.loc21_20.1: <bound method> = bound_method %IsPresent.call.loc21, %impl.elem1.loc21
// CHECK:STDOUT:   %specific_fn.loc21_20: <specific function> = specific_function %impl.elem1.loc21, @Int.as.EqWith.impl.NotEqual.3(constants.%int_32, constants.%ImplicitAs.facet.9f1) [concrete = constants.%Int.as.EqWith.impl.NotEqual.specific_fn.3df7ac.1]
// CHECK:STDOUT:   %bound_method.loc21_20.2: <bound method> = bound_method %IsPresent.call.loc21, %specific_fn.loc21_20
// CHECK:STDOUT:   %.loc21_18.1: %i32 = value_of_initializer %IsPresent.call.loc21
// CHECK:STDOUT:   %.loc21_18.2: %i32 = converted %IsPresent.call.loc21, %.loc21_18.1
// CHECK:STDOUT:   %.loc21_20: %Int.as.EqWith.impl.NotEqual.type.2f6aaa.1 = specific_constant imports.%Core.NotEqual.c83, @Int.as.EqWith.impl.2b8(constants.%int_32, constants.%ImplicitAs.facet.9f1) [concrete = constants.%Int.as.EqWith.impl.NotEqual.48041c.1]
// CHECK:STDOUT:   %NotEqual.ref: %Int.as.EqWith.impl.NotEqual.type.2f6aaa.1 = name_ref NotEqual, %.loc21_20 [concrete = constants.%Int.as.EqWith.impl.NotEqual.48041c.1]
// CHECK:STDOUT:   %Int.as.EqWith.impl.NotEqual.bound: <bound method> = bound_method %.loc21_18.2, %NotEqual.ref
// CHECK:STDOUT:   %Int.as.EqWith.impl.NotEqual.specific_fn: <specific function> = specific_function %NotEqual.ref, @Int.as.EqWith.impl.NotEqual.4(constants.%int_32, constants.%ImplicitAs.facet.9f1) [concrete = constants.%Int.as.EqWith.impl.NotEqual.specific_fn.3df7ac.2]
// CHECK:STDOUT:   %bound_method.loc21_20.3: <bound method> = bound_method %.loc21_18.2, %Int.as.EqWith.impl.NotEqual.specific_fn
// CHECK:STDOUT:   %impl.elem0.loc21: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc21_23.1: <bound method> = bound_method %int_0, %impl.elem0.loc21 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc21_23: <specific function> = specific_function %impl.elem0.loc21, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc21_23.2: <bound method> = bound_method %int_0, %specific_fn.loc21_23 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc21: init %i32 = call %bound_method.loc21_23.2(%int_0) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc21_23.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc21 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc21_23.2: %i32 = converted %int_0, %.loc21_23.1 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %Int.as.EqWith.impl.NotEqual.call: init bool = call %bound_method.loc21_20.3(%.loc21_18.2, %.loc21_23.2)
// CHECK:STDOUT:   %.loc21_24.1: bool = value_of_initializer %Int.as.EqWith.impl.NotEqual.call
// CHECK:STDOUT:   %.loc21_24.2: bool = converted %Int.as.EqWith.impl.NotEqual.call, %.loc21_24.1
// CHECK:STDOUT:   if %.loc21_24.2 br !if.then else br !if.else
// CHECK:STDOUT:
// CHECK:STDOUT: !if.then:
// CHECK:STDOUT:   %int_1.loc22: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc22: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc22_13.1: <bound method> = bound_method %int_1.loc22, %impl.elem0.loc22 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc22: <specific function> = specific_function %impl.elem0.loc22, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc22_13.2: <bound method> = bound_method %int_1.loc22, %specific_fn.loc22 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc22: init %i32 = call %bound_method.loc22_13.2(%int_1.loc22) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc22: init %i32 = converted %int_1.loc22, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc22 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   return %.loc22
// CHECK:STDOUT:
// CHECK:STDOUT: !if.else:
// CHECK:STDOUT:   %Optional.ref.loc24_26: %Optional.type = name_ref Optional, file.%Optional.decl [concrete = constants.%Optional.generic]
// CHECK:STDOUT:   %i32.loc24_35: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %Optional.loc24_38: type = class_type @Optional, @Optional(constants.%i32) [concrete = constants.%Optional.d7e]
// CHECK:STDOUT:   %.loc24_39: %Optional.Some.type.fb9 = specific_constant generated.%Optional.Some.decl, @Optional(constants.%i32) [concrete = constants.%Optional.Some.f27]
// CHECK:STDOUT:   %Some.ref: %Optional.Some.type.fb9 = name_ref Some, %.loc24_39 [concrete = constants.%Optional.Some.f27]
// CHECK:STDOUT:   %int_42: Core.IntLiteral = int_value 42 [concrete = constants.%int_42.20e]
// CHECK:STDOUT:   %Optional.Some.specific_fn: <specific function> = specific_function %Some.ref, @Optional.Some(constants.%i32) [concrete = constants.%Optional.Some.specific_fn]
// CHECK:STDOUT:   %.loc24_47.1: ref %Optional.d7e = temporary_storage
// CHECK:STDOUT:   %impl.elem0.loc24: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc24_45.1: <bound method> = bound_method %int_42, %impl.elem0.loc24 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.bf3]
// CHECK:STDOUT:   %specific_fn.loc24: <specific function> = specific_function %impl.elem0.loc24, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc24_45.2: <bound method> = bound_method %int_42, %specific_fn.loc24 [concrete = constants.%bound_method.098]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc24: init %i32 = call %bound_method.loc24_45.2(%int_42) [concrete = constants.%int_42.ac4]
// CHECK:STDOUT:   %.loc24_45.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc24 [concrete = constants.%int_42.ac4]
// CHECK:STDOUT:   %.loc24_45.2: %i32 = converted %int_42, %.loc24_45.1 [concrete = constants.%int_42.ac4]
// CHECK:STDOUT:   %Optional.Some.call: init %Optional.b33 to %.loc24_47.1 = call %Optional.Some.specific_fn(%.loc24_45.2)
// CHECK:STDOUT:   %.loc24_47.2: %Optional.d7e = converted %Optional.Some.call, <error> [concrete = <error>]
// CHECK:STDOUT:   %.loc24_22: type = splice_block %Optional.loc24_22 [concrete = constants.%Optional.d7e] {
// CHECK:STDOUT:     %Optional.ref.loc24_10: %Optional.type = name_ref Optional, file.%Optional.decl [concrete = constants.%Optional.generic]
// CHECK:STDOUT:     %i32.loc24_19: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %Optional.loc24_22: type = class_type @Optional, @Optional(constants.%i32) [concrete = constants.%Optional.d7e]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %s: %Optional.d7e = wrapper_binding s, <error> [concrete = <error>]
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %s.patt: %pattern_type.e8f = value_binding_pattern s [concrete = constants.%s.patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %IsPresent.ref.loc25: %IsPresent.type = name_ref IsPresent, file.%IsPresent.decl [concrete = constants.%IsPresent]
// CHECK:STDOUT:   %s.ref: %Optional.d7e = name_ref s, %s [concrete = <error>]
// CHECK:STDOUT:   %IsPresent.call.loc25: init %i32 = call %IsPresent.ref.loc25(<error>)
// CHECK:STDOUT:   %int_1.loc25: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem1.loc25: %.e15 = impl_witness_access constants.%SubWith.impl_witness.d78, element1 [concrete = constants.%Int.as.SubWith.impl.Op.49baee.2]
// CHECK:STDOUT:   %bound_method.loc25_23.1: <bound method> = bound_method %IsPresent.call.loc25, %impl.elem1.loc25
// CHECK:STDOUT:   %specific_fn.loc25_23: <specific function> = specific_function %impl.elem1.loc25, @Int.as.SubWith.impl.Op.2(constants.%int_32, constants.%ImplicitAs.facet.9f1) [concrete = constants.%Int.as.SubWith.impl.Op.specific_fn.4cc768.1]
// CHECK:STDOUT:   %bound_method.loc25_23.2: <bound method> = bound_method %IsPresent.call.loc25, %specific_fn.loc25_23
// CHECK:STDOUT:   %.loc25_21.1: %i32 = value_of_initializer %IsPresent.call.loc25
// CHECK:STDOUT:   %.loc25_21.2: %i32 = converted %IsPresent.call.loc25, %.loc25_21.1
// CHECK:STDOUT:   %.loc25_23: %Int.as.SubWith.impl.Op.type.745d60.1 = specific_constant imports.%Core.Op.9ff, @Int.as.SubWith.impl.dc8(constants.%int_32, constants.%ImplicitAs.facet.9f1) [concrete = constants.%Int.as.SubWith.impl.Op.49baee.1]
// CHECK:STDOUT:   %Op.ref: %Int.as.SubWith.impl.Op.type.745d60.1 = name_ref Op, %.loc25_23 [concrete = constants.%Int.as.SubWith.impl.Op.49baee.1]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.bound: <bound method> = bound_method %.loc25_21.2, %Op.ref
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.specific_fn: <specific function> = specific_function %Op.ref, @Int.as.SubWith.impl.Op.3(constants.%int_32, constants.%ImplicitAs.facet.9f1) [concrete = constants.%Int.as.SubWith.impl.Op.specific_fn.4cc768.2]
// CHECK:STDOUT:   %bound_method.loc25_23.3: <bound method> = bound_method %.loc25_21.2, %Int.as.SubWith.impl.Op.specific_fn
// CHECK:STDOUT:   %impl.elem0.loc25: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc25_25.1: <bound method> = bound_method %int_1.loc25, %impl.elem0.loc25 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc25_25: <specific function> = specific_function %impl.elem0.loc25, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc25_25.2: <bound method> = bound_method %int_1.loc25, %specific_fn.loc25_25 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc25: init %i32 = call %bound_method.loc25_25.2(%int_1.loc25) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc25_25.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc25 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc25_25.2: %i32 = converted %int_1.loc25, %.loc25_25.1 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.call: init %i32 = call %bound_method.loc25_23.3(%.loc25_21.2, %.loc25_25.2)
// CHECK:STDOUT:   return %Int.as.SubWith.impl.Op.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Optional(constants.%T.67d) {
// CHECK:STDOUT:   %T.patt.loc7_18.2 => constants.%T.patt.d47
// CHECK:STDOUT:   %T.loc7_18.1 => constants.%T.67d
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.51d1c4.1
// CHECK:STDOUT:   %value.param_patt => constants.%value.param_patt.98e
// CHECK:STDOUT:   %value.patt => constants.%value.patt.864
// CHECK:STDOUT:   %require_complete.loc8 => constants.%require_complete.944
// CHECK:STDOUT:   %tuple.type => constants.%tuple.type.026
// CHECK:STDOUT:   %.loc10_1.14 => constants.%.a2d
// CHECK:STDOUT:   %struct_type.discriminant.payload => constants.%struct_type.discriminant.payload.508
// CHECK:STDOUT:   %complete_type.loc10_1.2 => constants.%complete_type.abf
// CHECK:STDOUT:   %Optional.Some.type => constants.%Optional.Some.type.d69
// CHECK:STDOUT:   %Optional.Some => constants.%Optional.Some.424
// CHECK:STDOUT:   %Optional => constants.%Optional.b33
// CHECK:STDOUT:   %require_complete.loc10 => constants.%require_complete.85c
// CHECK:STDOUT:   %uninit.loc10_1.2 => constants.%uninit.37a
// CHECK:STDOUT:   %Optional.val => constants.%Optional.val.035
// CHECK:STDOUT:   %.loc10_1.15 => constants.%.fcc
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Optional.Some(constants.%T.67d) {
// CHECK:STDOUT:   %T => constants.%T.67d
// CHECK:STDOUT:   %pattern_type.loc7_26.1 => constants.%pattern_type.51d1c4.1
// CHECK:STDOUT:   %_.param_patt.loc7_26.2 => constants.%_.param_patt.339
// CHECK:STDOUT:   %_.patt.loc7_26.2 => constants.%_.patt.fd3
// CHECK:STDOUT:   %Optional => constants.%Optional.b33
// CHECK:STDOUT:   %.loc7_26.7 => constants.%.104
// CHECK:STDOUT:   %pattern_type.loc7_26.2 => constants.%pattern_type.385
// CHECK:STDOUT:   %return.param_patt.loc7_26.2 => constants.%return.param_patt.2f8
// CHECK:STDOUT:   %return.patt.loc7_26.2 => constants.%return.patt.847
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Optional(constants.%i32) {
// CHECK:STDOUT:   %T.patt.loc7_18.2 => constants.%T.patt.d47
// CHECK:STDOUT:   %T.loc7_18.1 => constants.%i32
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.6b6
// CHECK:STDOUT:   %value.param_patt => constants.%value.param_patt.34f
// CHECK:STDOUT:   %value.patt => constants.%value.patt.f6a
// CHECK:STDOUT:   %require_complete.loc8 => constants.%complete_type.f8a
// CHECK:STDOUT:   %tuple.type => constants.%tuple.type.a8a
// CHECK:STDOUT:   %.loc10_1.14 => constants.%.e8e
// CHECK:STDOUT:   %struct_type.discriminant.payload => constants.%struct_type.discriminant.payload.e99
// CHECK:STDOUT:   %complete_type.loc10_1.2 => constants.%complete_type.378
// CHECK:STDOUT:   %Optional.Some.type => constants.%Optional.Some.type.fb9
// CHECK:STDOUT:   %Optional.Some => constants.%Optional.Some.f27
// CHECK:STDOUT:   %Optional => constants.%Optional.d7e
// CHECK:STDOUT:   %require_complete.loc10 => constants.%complete_type.378
// CHECK:STDOUT:   %uninit.loc10_1.2 => constants.%uninit.060
// CHECK:STDOUT:   %Optional.val => constants.%Optional.val.dae
// CHECK:STDOUT:   %.loc10_1.15 => constants.%.236
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Optional.Some(constants.%i32) {
// CHECK:STDOUT:   %T => constants.%i32
// CHECK:STDOUT:   %pattern_type.loc7_26.1 => constants.%pattern_type.6b6
// CHECK:STDOUT:   %_.param_patt.loc7_26.2 => constants.%_.param_patt.fb2
// CHECK:STDOUT:   %_.patt.loc7_26.2 => constants.%_.patt.b75
// CHECK:STDOUT:   %Optional => constants.%Optional.d7e
// CHECK:STDOUT:   %.loc7_26.7 => constants.%.da75
// CHECK:STDOUT:   %pattern_type.loc7_26.2 => constants.%pattern_type.e8f
// CHECK:STDOUT:   %return.param_patt.loc7_26.2 => constants.%return.param_patt.f4f
// CHECK:STDOUT:   %return.patt.loc7_26.2 => constants.%return.patt.882
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc7_26.1 => constants.%complete_type.f8a
// CHECK:STDOUT:   %require_complete.loc7_26.2 => constants.%complete_type.378
// CHECK:STDOUT:   %tuple.type => constants.%tuple.type.a8a
// CHECK:STDOUT:   %.loc7_26.8 => constants.%.e8e
// CHECK:STDOUT:   %require_complete.loc7_26.3 => constants.%complete_type.147
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- destructure.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %.Self.frozen.197: %type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %pattern_type.98f: type = pattern_type type [concrete]
// CHECK:STDOUT:   %T.patt.d47: %pattern_type.98f = symbolic_binding_pattern T, 0 [symbolic]
// CHECK:STDOUT:   %T.67d: type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %Opt.type: type = generic_class_type @Opt [concrete]
// CHECK:STDOUT:   %Opt.generic: %Opt.type = struct_value () [concrete]
// CHECK:STDOUT:   %Opt.ba7: type = class_type @Opt, @Opt(%T.67d) [symbolic]
// CHECK:STDOUT:   %pattern_type.51d1c4.1: type = pattern_type %T.67d [symbolic]
// CHECK:STDOUT:   %value.param_patt.98e: %pattern_type.51d1c4.1 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %value.patt.864: %pattern_type.51d1c4.1 = at_binding_pattern value, %value.param_patt.98e [symbolic]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %u1: type = class_type @UInt, @UInt(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %require_complete.944: <witness> = require_complete_type %T.67d [symbolic]
// CHECK:STDOUT:   %tuple.type.026: type = tuple_type (%T.67d) [symbolic]
// CHECK:STDOUT:   %.a2d: type = custom_layout_type {size=0, align=0, .Some@0: %tuple.type.026} [symbolic]
// CHECK:STDOUT:   %struct_type.discriminant.payload.508: type = struct_type {.discriminant: %u1, .payload: %.a2d} [symbolic]
// CHECK:STDOUT:   %complete_type.abf: <witness> = complete_type_witness %struct_type.discriminant.payload.508 [symbolic]
// CHECK:STDOUT:   %struct_type.discriminant: type = struct_type {.discriminant: %u1} [concrete]
// CHECK:STDOUT:   %_.param_patt.339: %pattern_type.51d1c4.1 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %_.patt.fd3: %pattern_type.51d1c4.1 = at_binding_pattern _, %_.param_patt.339 [symbolic]
// CHECK:STDOUT:   %.3c3: Core.Form = init_form %Opt.ba7 [symbolic]
// CHECK:STDOUT:   %pattern_type.86b: type = pattern_type %Opt.ba7 [symbolic]
// CHECK:STDOUT:   %return.param_patt.e2a: %pattern_type.86b = out_param_pattern [symbolic]
// CHECK:STDOUT:   %return.patt.ac3: %pattern_type.86b = return_slot_pattern %return.param_patt.e2a, %Opt.ba7 [symbolic]
// CHECK:STDOUT:   %Opt.Some.type.d0c: type = fn_type @Opt.Some, @Opt(%T.67d) [symbolic]
// CHECK:STDOUT:   %Opt.Some.821: %Opt.Some.type.d0c = struct_value () [symbolic]
// CHECK:STDOUT:   %require_complete.dd1: <witness> = require_complete_type %Opt.ba7 [symbolic]
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
// CHECK:STDOUT:   %require_complete.48b: <witness> = require_complete_type %tuple.type.026 [symbolic]
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
// CHECK:STDOUT:   %uninit.37a: %.a2d = uninitialized_value [symbolic]
// CHECK:STDOUT:   %Opt.val.a5e: %Opt.ba7 = struct_value (%int_1.233, %uninit.37a) [symbolic]
// CHECK:STDOUT:   %.9a0: ref %Opt.ba7 = temporary invalid, %Opt.val.a5e [symbolic]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %Int.67af24.1: type = class_type @Int, @Int(%N) [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %Opt.46d: type = class_type @Opt, @Opt(%i32) [concrete]
// CHECK:STDOUT:   %pattern_type.25d: type = pattern_type %Opt.46d [concrete]
// CHECK:STDOUT:   %o.param_patt: %pattern_type.25d = value_param_pattern [concrete]
// CHECK:STDOUT:   %o.patt: %pattern_type.25d = at_binding_pattern o, %o.param_patt [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %Get.type: type = fn_type @Get [concrete]
// CHECK:STDOUT:   %Get: %Get.type = struct_value () [concrete]
// CHECK:STDOUT:   %value.param_patt.34f: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %value.patt.f6a: %pattern_type.6b6 = at_binding_pattern value, %value.param_patt.34f [concrete]
// CHECK:STDOUT:   %i32.builtin: type = int_type signed, %int_32 [concrete]
// CHECK:STDOUT:   %complete_type.f8a: <witness> = complete_type_witness %i32.builtin [concrete]
// CHECK:STDOUT:   %tuple.type.a8a: type = tuple_type (%i32) [concrete]
// CHECK:STDOUT:   %.e8e: type = custom_layout_type {size=4, align=4, .Some@0: %tuple.type.a8a} [concrete]
// CHECK:STDOUT:   %struct_type.discriminant.payload.e99: type = struct_type {.discriminant: %u1, .payload: %.e8e} [concrete]
// CHECK:STDOUT:   %complete_type.378: <witness> = complete_type_witness %struct_type.discriminant.payload.e99 [concrete]
// CHECK:STDOUT:   %Opt.Some.type.39e: type = fn_type @Opt.Some, @Opt(%i32) [concrete]
// CHECK:STDOUT:   %Opt.Some.733: %Opt.Some.type.39e = struct_value () [concrete]
// CHECK:STDOUT:   %uninit.060: %.e8e = uninitialized_value [concrete]
// CHECK:STDOUT:   %Opt.val.b51: %Opt.46d = struct_value (%int_1.233, %uninit.060) [concrete]
// CHECK:STDOUT:   %.b5c: ref %Opt.46d = temporary invalid, %Opt.val.b51 [concrete]
// CHECK:STDOUT:   %v.patt: %pattern_type.6b6 = value_binding_pattern v [concrete]
// CHECK:STDOUT:   %pattern_type.e71: type = pattern_type %tuple.type.a8a [concrete]
// CHECK:STDOUT:   %.13b: %pattern_type.e71 = tuple_pattern (%v.patt) [concrete]
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
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.0e0: <witness> = impl_witness imports.%Copy.impl_witness_table.367, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet.987: %Copy.type = facet_value %i32, (%Copy.impl_witness.0e0) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.d09: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.987) [concrete]
// CHECK:STDOUT:   %.7a6: type = fn_type_with_self_type %Copy.WithSelf.Op.type.d09, %Copy.facet.987 [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound.22c: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %bound_method.a82: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
// CHECK:STDOUT:   %Negate.type: type = facet_type <@Negate> [concrete]
// CHECK:STDOUT:   %Negate.impl_witness: <witness> = impl_witness imports.%Negate.impl_witness_table [concrete]
// CHECK:STDOUT:   %Negate.facet: %Negate.type = facet_value Core.IntLiteral, (%Negate.impl_witness) [concrete]
// CHECK:STDOUT:   %Negate.WithSelf.Op.type.db1: type = fn_type @Negate.WithSelf.Op, @Negate.WithSelf(%Negate.facet) [concrete]
// CHECK:STDOUT:   %.e9b: type = fn_type_with_self_type %Negate.WithSelf.Op.type.db1, %Negate.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.type: type = fn_type @Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op: %Core.IntLiteral.as.Negate.impl.Op.type = struct_value () [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.bound: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.Negate.impl.Op [concrete]
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
// CHECK:STDOUT:   %Run.type: type = fn_type @Run [concrete]
// CHECK:STDOUT:   %Run: %Run.type = struct_value () [concrete]
// CHECK:STDOUT:   %s.patt: %pattern_type.25d = value_binding_pattern s [concrete]
// CHECK:STDOUT:   %int_42.20e: Core.IntLiteral = int_value 42 [concrete]
// CHECK:STDOUT:   %_.param_patt.fb2: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %_.patt.b75: %pattern_type.6b6 = at_binding_pattern _, %_.param_patt.fb2 [concrete]
// CHECK:STDOUT:   %.bda: Core.Form = init_form %Opt.46d [concrete]
// CHECK:STDOUT:   %return.param_patt.63c: %pattern_type.25d = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.c82: %pattern_type.25d = return_slot_pattern %return.param_patt.63c, %Opt.46d [concrete]
// CHECK:STDOUT:   %Opt.Some.specific_fn: <specific function> = specific_function %Opt.Some.733, @Opt.Some(%i32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.bf3: <bound method> = bound_method %int_42.20e, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.098: <bound method> = bound_method %int_42.20e, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_42.ac4: %i32 = int_value 42 [concrete]
// CHECK:STDOUT:   %SubWith.type.4c2: type = facet_type <@SubWith, @SubWith(Core.IntLiteral)> [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.f7de31.2: type = facet_type <@ImplicitAs, @ImplicitAs(%Int.67af24.1)> [symbolic]
// CHECK:STDOUT:   %U.4e6: %ImplicitAs.type.f7de31.2 = symbolic_binding U, 1 [symbolic]
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
// CHECK:STDOUT:   %complete_type.147: <witness> = complete_type_witness %tuple.type.a8a [concrete]
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
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.367 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.abd = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9c3: %Core.IntLiteral.as.Negate.impl.Op.type = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, loaded [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %Negate.impl_witness_table = impl_witness_table (%Core.import_ref.abd, %Core.import_ref.9c3), @Core.IntLiteral.as.Negate.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.b3c = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.b4fd3a.2 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.6fa: @Int.as.SubWith.impl.dc8.%Int.as.SubWith.impl.Op.type.2 (%Int.as.SubWith.impl.Op.type.6f3321.1) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.SubWith.impl.dc8.%Int.as.SubWith.impl.Op.2 (constants.%Int.as.SubWith.impl.Op.a37528.1)]
// CHECK:STDOUT:   %SubWith.impl_witness_table.dc9 = impl_witness_table (%Core.import_ref.b4fd3a.2, %Core.import_ref.6fa), @Int.as.SubWith.impl.dc8 [concrete]
// CHECK:STDOUT:   %Core.Op.9ff: @Int.as.SubWith.impl.dc8.%Int.as.SubWith.impl.Op.type.1 (%Int.as.SubWith.impl.Op.type.6f3321.2) = import_ref Core//prelude/types/int, Op, loaded [symbolic = @Int.as.SubWith.impl.dc8.%Int.as.SubWith.impl.Op.1 (constants.%Int.as.SubWith.impl.Op.a37528.2)]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %Opt.Some.decl: @Opt.%Opt.Some.type (%Opt.Some.type.d0c) = fn_decl @Opt.Some [symbolic = @Opt.%Opt.Some (constants.%Opt.Some.821)] {
// CHECK:STDOUT:     %_.param_patt.loc12_21.1: @Opt.Some.%pattern_type.loc12_21.1 (%pattern_type.51d1c4.1) = value_param_pattern [symbolic = %_.param_patt.loc12_21.2 (constants.%_.param_patt.339)]
// CHECK:STDOUT:     %_.patt.loc12_21.1: @Opt.Some.%pattern_type.loc12_21.1 (%pattern_type.51d1c4.1) = at_binding_pattern _, %_.param_patt.loc12_21.1 [symbolic = %_.patt.loc12_21.2 (constants.%_.patt.fd3)]
// CHECK:STDOUT:     %return.param_patt.loc12_21.1: @Opt.Some.%pattern_type.loc12_21.2 (%pattern_type.86b) = out_param_pattern [symbolic = %return.param_patt.loc12_21.2 (constants.%return.param_patt.e2a)]
// CHECK:STDOUT:     %return.patt.loc12_21.1: @Opt.Some.%pattern_type.loc12_21.2 (%pattern_type.86b) = return_slot_pattern %return.param_patt.loc12_21.1, constants.%Opt.ba7 [symbolic = %return.patt.loc12_21.2 (constants.%return.patt.ac3)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc12_21.9: Core.Form = init_form constants.%Opt.ba7 [symbolic = %.loc12_21.7 (constants.%.3c3)]
// CHECK:STDOUT:     %_.param: @Opt.Some.%T (%T.67d) = value_param call_param0
// CHECK:STDOUT:     %_: @Opt.Some.%T (%T.67d) = wrapper_binding _, %_.param
// CHECK:STDOUT:     %return.param: ref @Opt.Some.%Opt (%Opt.ba7) = out_param call_param1
// CHECK:STDOUT:     %return: ref @Opt.Some.%Opt (%Opt.ba7) = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Opt.decl: %Opt.type = class_decl @Opt [concrete = constants.%Opt.generic] {
// CHECK:STDOUT:     %T.patt.loc12_13.1: %pattern_type.98f = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc12_13.2 (constants.%T.patt.d47)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc12_15.1: type = splice_block %.loc12_15.2 [concrete = type] {
// CHECK:STDOUT:       %.Self.frozen: %type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen.197]
// CHECK:STDOUT:       %.loc12_15.2: type = type_literal type [concrete = type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc12_13.2: type = symbolic_binding T, 0 [symbolic = %T.loc12_13.1 (constants.%T.67d)]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Get.decl: %Get.type = fn_decl @Get [concrete = constants.%Get] {
// CHECK:STDOUT:     %o.param_patt: %pattern_type.25d = value_param_pattern [concrete = constants.%o.param_patt]
// CHECK:STDOUT:     %o.patt: %pattern_type.25d = at_binding_pattern o, %o.param_patt [concrete = constants.%o.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc17_24 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc17_24: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc17_24: Core.Form = init_form %i32.loc17_24 [concrete = constants.%.795f]
// CHECK:STDOUT:     %o.param: %Opt.46d = value_param call_param0
// CHECK:STDOUT:     %.loc17_18: type = splice_block %Opt [concrete = constants.%Opt.46d] {
// CHECK:STDOUT:       %Opt.ref: %Opt.type = name_ref Opt, file.%Opt.decl [concrete = constants.%Opt.generic]
// CHECK:STDOUT:       %i32.loc17_15: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %Opt: type = class_type @Opt, @Opt(constants.%i32) [concrete = constants.%Opt.46d]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %o: %Opt.46d = wrapper_binding o, %o.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Run.decl: %Run.type = fn_decl @Run [concrete = constants.%Run] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc24 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc24: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc24: Core.Form = init_form %i32.loc24 [concrete = constants.%.795f]
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param0
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic class @Opt(%T.loc12_13.2: type) {
// CHECK:STDOUT:   %T.patt.loc12_13.2: %pattern_type.98f = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc12_13.2 (constants.%T.patt.d47)]
// CHECK:STDOUT:   %T.loc12_13.1: type = symbolic_binding T, 0 [symbolic = %T.loc12_13.1 (constants.%T.67d)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %pattern_type: type = pattern_type %T.loc12_13.1 [symbolic = %pattern_type (constants.%pattern_type.51d1c4.1)]
// CHECK:STDOUT:   %value.param_patt: @Opt.%pattern_type (%pattern_type.51d1c4.1) = value_param_pattern [symbolic = %value.param_patt (constants.%value.param_patt.98e)]
// CHECK:STDOUT:   %value.patt: @Opt.%pattern_type (%pattern_type.51d1c4.1) = at_binding_pattern value, %value.param_patt [symbolic = %value.patt (constants.%value.patt.864)]
// CHECK:STDOUT:   %require_complete.loc13: <witness> = require_complete_type %T.loc12_13.1 [symbolic = %require_complete.loc13 (constants.%require_complete.944)]
// CHECK:STDOUT:   %tuple.type: type = tuple_type (%T.loc12_13.1) [symbolic = %tuple.type (constants.%tuple.type.026)]
// CHECK:STDOUT:   %.loc15_1.14: type = custom_layout_type {size=0, align=0, .Some@0: @Opt.%tuple.type (%tuple.type.026)} [symbolic = %.loc15_1.14 (constants.%.a2d)]
// CHECK:STDOUT:   %struct_type.discriminant.payload: type = struct_type {.discriminant: %u1, .payload: @Opt.%.loc15_1.14 (%.a2d)} [symbolic = %struct_type.discriminant.payload (constants.%struct_type.discriminant.payload.508)]
// CHECK:STDOUT:   %complete_type.loc15_1.2: <witness> = complete_type_witness %struct_type.discriminant.payload [symbolic = %complete_type.loc15_1.2 (constants.%complete_type.abf)]
// CHECK:STDOUT:   %Opt.Some.type: type = fn_type @Opt.Some, @Opt(%T.loc12_13.1) [symbolic = %Opt.Some.type (constants.%Opt.Some.type.d0c)]
// CHECK:STDOUT:   %Opt.Some: @Opt.%Opt.Some.type (%Opt.Some.type.d0c) = struct_value () [symbolic = %Opt.Some (constants.%Opt.Some.821)]
// CHECK:STDOUT:   %Opt: type = class_type @Opt, @Opt(%T.loc12_13.1) [symbolic = %Opt (constants.%Opt.ba7)]
// CHECK:STDOUT:   %require_complete.loc15: <witness> = require_complete_type %Opt [symbolic = %require_complete.loc15 (constants.%require_complete.dd1)]
// CHECK:STDOUT:   %uninit.loc15_1.2: @Opt.%.loc15_1.14 (%.a2d) = uninitialized_value [symbolic = %uninit.loc15_1.2 (constants.%uninit.37a)]
// CHECK:STDOUT:   %Opt.val: @Opt.%Opt (%Opt.ba7) = struct_value (constants.%int_1.233, %uninit.loc15_1.2) [symbolic = %Opt.val (constants.%Opt.val.a5e)]
// CHECK:STDOUT:   %.loc15_1.15: ref @Opt.%Opt (%Opt.ba7) = temporary invalid, %Opt.val [symbolic = %.loc15_1.15 (constants.%.9a0)]
// CHECK:STDOUT:
// CHECK:STDOUT:   class {
// CHECK:STDOUT:     %value.param: @Opt.%T.loc12_13.1 (%T.67d) = value_param call_param0
// CHECK:STDOUT:     %T.ref: type = name_ref T, %T.loc12_13.2 [symbolic = %T.loc12_13.1 (constants.%T.67d)]
// CHECK:STDOUT:     %value: @Opt.%T.loc12_13.1 (%T.67d) = wrapper_binding value, %value.param
// CHECK:STDOUT:     %.loc15_1.1: type = custom_layout_type {size=0, align=0, .Some@0: %tuple.type.026} [symbolic = %.loc15_1.14 (constants.%.a2d)]
// CHECK:STDOUT:     %complete_type.loc15_1.1: <witness> = complete_type_witness constants.%struct_type.discriminant.payload.508 [symbolic = %complete_type.loc15_1.2 (constants.%complete_type.abf)]
// CHECK:STDOUT:     %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:     %impl.elem0.loc15_1.1: %.e60 = impl_witness_access constants.%ImplicitAs.impl_witness.9a9, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:     %bound_method.loc15_1.1: <bound method> = bound_method %int_1, %impl.elem0.loc15_1.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:     %specific_fn.loc15_1.1: <specific function> = specific_function %impl.elem0.loc15_1.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:     %bound_method.loc15_1.2: <bound method> = bound_method %int_1, %specific_fn.loc15_1.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %u1 = call %bound_method.loc15_1.2(%int_1) [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc15_1.2: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc15_1.3: %u1 = converted %int_1, %.loc15_1.2 [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc15_1.4: %struct_type.discriminant = struct_literal (%.loc15_1.3) [concrete = constants.%struct]
// CHECK:STDOUT:     %impl.elem0.loc15_1.2: %.37a = impl_witness_access constants.%Copy.impl_witness.fb7, element0 [concrete = constants.%UInt.as.Copy.impl.Op.d9c]
// CHECK:STDOUT:     %bound_method.loc15_1.3: <bound method> = bound_method %.loc15_1.3, %impl.elem0.loc15_1.2 [concrete = constants.%UInt.as.Copy.impl.Op.bound]
// CHECK:STDOUT:     %specific_fn.loc15_1.2: <specific function> = specific_function %impl.elem0.loc15_1.2, @UInt.as.Copy.impl.Op(constants.%int_1.5b8) [concrete = constants.%UInt.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:     %bound_method.loc15_1.4: <bound method> = bound_method %.loc15_1.3, %specific_fn.loc15_1.2 [concrete = constants.%bound_method.edd]
// CHECK:STDOUT:     %UInt.as.Copy.impl.Op.call: init %u1 = call %bound_method.loc15_1.4(%.loc15_1.3) [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc15_1.5: ref @Opt.%Opt (%Opt.ba7) = temporary_storage
// CHECK:STDOUT:     %.loc15_1.6: ref %u1 = class_element_access %.loc15_1.5, element0
// CHECK:STDOUT:     %.loc15_1.7: init %u1 to %.loc15_1.6 = in_place_init %UInt.as.Copy.impl.Op.call [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc15_1.8: ref @Opt.%.loc15_1.14 (%.a2d) = class_element_access %.loc15_1.5, element1
// CHECK:STDOUT:     %uninit.loc15_1.1: @Opt.%.loc15_1.14 (%.a2d) = uninitialized_value [symbolic = %uninit.loc15_1.2 (constants.%uninit.37a)]
// CHECK:STDOUT:     %.loc15_1.9: init @Opt.%.loc15_1.14 (%.a2d) to %.loc15_1.8 = in_place_init %uninit.loc15_1.1 [symbolic = %uninit.loc15_1.2 (constants.%uninit.37a)]
// CHECK:STDOUT:     %.loc15_1.10: init @Opt.%Opt (%Opt.ba7) to %.loc15_1.5 = class_init (%.loc15_1.7, %.loc15_1.9) [symbolic = %Opt.val (constants.%Opt.val.a5e)]
// CHECK:STDOUT:     %.loc15_1.11: init @Opt.%Opt (%Opt.ba7) = converted %.loc15_1.4, %.loc15_1.10 [symbolic = %Opt.val (constants.%Opt.val.a5e)]
// CHECK:STDOUT:     %.loc15_1.12: ref @Opt.%Opt (%Opt.ba7) = temporary %.loc15_1.5, %.loc15_1.11 [symbolic = %.loc15_1.15 (constants.%.9a0)]
// CHECK:STDOUT:     %.loc15_1.13: @Opt.%Opt (%Opt.ba7) = acquire_value %.loc15_1.12 [symbolic = %Opt.val (constants.%Opt.val.a5e)]
// CHECK:STDOUT:     %None: @Opt.%Opt (%Opt.ba7) = wrapper_binding None, %.loc15_1.13
// CHECK:STDOUT:     complete_type_witness = %complete_type.loc15_1.1
// CHECK:STDOUT:
// CHECK:STDOUT:   !members:
// CHECK:STDOUT:     .Self = constants.%Opt.ba7
// CHECK:STDOUT:     .T = <poisoned>
// CHECK:STDOUT:     .Some = generated.%Opt.Some.decl
// CHECK:STDOUT:     .None = %None
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @Opt.Some(@Opt.%T.loc12_13.2: type) {
// CHECK:STDOUT:   %T: type = symbolic_binding T, 0 [symbolic = %T (constants.%T.67d)]
// CHECK:STDOUT:   %pattern_type.loc12_21.1: type = pattern_type %T [symbolic = %pattern_type.loc12_21.1 (constants.%pattern_type.51d1c4.1)]
// CHECK:STDOUT:   %_.param_patt.loc12_21.2: @Opt.Some.%pattern_type.loc12_21.1 (%pattern_type.51d1c4.1) = value_param_pattern [symbolic = %_.param_patt.loc12_21.2 (constants.%_.param_patt.339)]
// CHECK:STDOUT:   %_.patt.loc12_21.2: @Opt.Some.%pattern_type.loc12_21.1 (%pattern_type.51d1c4.1) = at_binding_pattern _, %_.param_patt.loc12_21.2 [symbolic = %_.patt.loc12_21.2 (constants.%_.patt.fd3)]
// CHECK:STDOUT:   %Opt: type = class_type @Opt, @Opt(%T) [symbolic = %Opt (constants.%Opt.ba7)]
// CHECK:STDOUT:   %.loc12_21.7: Core.Form = init_form %Opt [symbolic = %.loc12_21.7 (constants.%.3c3)]
// CHECK:STDOUT:   %pattern_type.loc12_21.2: type = pattern_type %Opt [symbolic = %pattern_type.loc12_21.2 (constants.%pattern_type.86b)]
// CHECK:STDOUT:   %return.param_patt.loc12_21.2: @Opt.Some.%pattern_type.loc12_21.2 (%pattern_type.86b) = out_param_pattern [symbolic = %return.param_patt.loc12_21.2 (constants.%return.param_patt.e2a)]
// CHECK:STDOUT:   %return.patt.loc12_21.2: @Opt.Some.%pattern_type.loc12_21.2 (%pattern_type.86b) = return_slot_pattern %return.param_patt.loc12_21.2, %Opt [symbolic = %return.patt.loc12_21.2 (constants.%return.patt.ac3)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc12_21.1: <witness> = require_complete_type %T [symbolic = %require_complete.loc12_21.1 (constants.%require_complete.944)]
// CHECK:STDOUT:   %require_complete.loc12_21.2: <witness> = require_complete_type %Opt [symbolic = %require_complete.loc12_21.2 (constants.%require_complete.dd1)]
// CHECK:STDOUT:   %tuple.type: type = tuple_type (%T) [symbolic = %tuple.type (constants.%tuple.type.026)]
// CHECK:STDOUT:   %.loc12_21.8: type = custom_layout_type {size=0, align=0, .Some@0: @Opt.Some.%tuple.type (%tuple.type.026)} [symbolic = %.loc12_21.8 (constants.%.a2d)]
// CHECK:STDOUT:   %require_complete.loc12_21.3: <witness> = require_complete_type %tuple.type [symbolic = %require_complete.loc12_21.3 (constants.%require_complete.48b)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%_.param: @Opt.Some.%T (%T.67d)) -> out %return.param: @Opt.Some.%Opt (%Opt.ba7) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %.loc12_21.1: ref %u1 = class_element_access %return.param, element0
// CHECK:STDOUT:     %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:     %impl.elem0: %.e60 = impl_witness_access constants.%ImplicitAs.impl_witness.9a9, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:     %bound_method.loc12_21.1: <bound method> = bound_method %int_0, %impl.elem0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:     %specific_fn: <specific function> = specific_function %impl.elem0, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:     %bound_method.loc12_21.2: <bound method> = bound_method %int_0, %specific_fn [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %u1 = call %bound_method.loc12_21.2(%int_0) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:     %.loc12_21.2: init %u1 = converted %int_0, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:     %.loc12_21.3: init %u1 to %.loc12_21.1 = in_place_init %.loc12_21.2 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:     %.loc12_21.4: ref @Opt.Some.%.loc12_21.8 (%.a2d) = class_element_access %return.param, element1
// CHECK:STDOUT:     %.loc12_21.5: ref @Opt.Some.%tuple.type (%tuple.type.026) = class_element_access %.loc12_21.4, element0
// CHECK:STDOUT:     %.loc13: @Opt.Some.%tuple.type (%tuple.type.026) = tuple_literal (%_.param)
// CHECK:STDOUT:     %.loc12_21.6: init @Opt.Some.%Opt (%Opt.ba7) to %return.param = class_init (%.loc12_21.3, <error>) [concrete = <error>]
// CHECK:STDOUT:     return %.loc12_21.6 to %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Get(%o.param: %Opt.46d) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %o.ref: %Opt.46d = name_ref o, %o
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %v.patt: %pattern_type.6b6 = value_binding_pattern v [concrete = constants.%v.patt]
// CHECK:STDOUT:     %.loc19_17: %pattern_type.e71 = tuple_pattern (%v.patt) [concrete = constants.%.13b]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc19_24.1: %.e60 = impl_witness_access constants.%ImplicitAs.impl_witness.9a9, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc19_24.1: <bound method> = bound_method %int_0, %impl.elem0.loc19_24.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:   %specific_fn.loc19_24.1: <specific function> = specific_function %impl.elem0.loc19_24.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc19_24.2: <bound method> = bound_method %int_0, %specific_fn.loc19_24.1 [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc19: init %u1 = call %bound_method.loc19_24.2(%int_0) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc19_24.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc19 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc19_24.2: %u1 = converted %int_0, %.loc19_24.1 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc19_24.3: ref %u1 = class_element_access %o.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc19_24.2: %.9ed = impl_witness_access constants.%EqWith.impl_witness.d63, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc19_24.3: <bound method> = bound_method %.loc19_24.2, %impl.elem0.loc19_24.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.f34]
// CHECK:STDOUT:   %specific_fn.loc19_24.2: <specific function> = specific_function %impl.elem0.loc19_24.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc19_24.4: <bound method> = bound_method %.loc19_24.2, %specific_fn.loc19_24.2 [concrete = constants.%bound_method.53a]
// CHECK:STDOUT:   %.loc19_24.4: %u1 = acquire_value %.loc19_24.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc19: init bool = call %bound_method.loc19_24.4(%.loc19_24.2, %.loc19_24.4)
// CHECK:STDOUT:   %.loc19_24.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc19
// CHECK:STDOUT:   %.loc19_24.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc19, %.loc19_24.5
// CHECK:STDOUT:   if %.loc19_24.6 br !match.case.then.loc19 else br !match.case.else.loc19
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc19:
// CHECK:STDOUT:   %.loc19_24.7: ref %.e8e = class_element_access %o.ref, element1
// CHECK:STDOUT:   %.loc19_24.8: ref %tuple.type.a8a = class_element_access %.loc19_24.7, element0
// CHECK:STDOUT:   %tuple.elem0: ref %i32 = tuple_access %.loc19_24.8, element0
// CHECK:STDOUT:   %.loc19_24.9: %i32 = acquire_value %tuple.elem0
// CHECK:STDOUT:   %i32.loc19: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %v: %i32 = wrapper_binding v, %.loc19_24.9
// CHECK:STDOUT:   %v.ref: %i32 = name_ref v, %v
// CHECK:STDOUT:   %impl.elem0.loc19_36: %.7a6 = impl_witness_access constants.%Copy.impl_witness.0e0, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc19_36.1: <bound method> = bound_method %v.ref, %impl.elem0.loc19_36
// CHECK:STDOUT:   %specific_fn.loc19_36: <specific function> = specific_function %impl.elem0.loc19_36, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc19_36.2: <bound method> = bound_method %v.ref, %specific_fn.loc19_36
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc19_36.2(%v.ref)
// CHECK:STDOUT:   return %Int.as.Copy.impl.Op.call
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc19:
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt: %pattern_type.25d = expr_pattern %None.ref in [concrete] {
// CHECK:STDOUT:       %.loc20_10.2: %Opt.46d = specific_constant @Opt.%.loc15_1.13, @Opt(constants.%i32) [concrete = constants.%Opt.val.b51]
// CHECK:STDOUT:       %None.ref: %Opt.46d = name_ref None, %.loc20_10.2 [concrete = constants.%Opt.val.b51]
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %.loc20_10.1: %Opt.46d = splice_block %None.ref [concrete = constants.%Opt.val.b51] {
// CHECK:STDOUT:     %.loc20_10.2: %Opt.46d = specific_constant @Opt.%.loc15_1.13, @Opt(constants.%i32) [concrete = constants.%Opt.val.b51]
// CHECK:STDOUT:     %None.ref: %Opt.46d = name_ref None, %.loc20_10.2 [concrete = constants.%Opt.val.b51]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_1.loc20_16: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc20_16.1: %.e60 = impl_witness_access constants.%ImplicitAs.impl_witness.9a9, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc20_16.1: <bound method> = bound_method %int_1.loc20_16, %impl.elem0.loc20_16.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc20_16.1: <specific function> = specific_function %impl.elem0.loc20_16.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc20_16.2: <bound method> = bound_method %int_1.loc20_16, %specific_fn.loc20_16.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc20_16: init %u1 = call %bound_method.loc20_16.2(%int_1.loc20_16) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc20_16.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc20_16 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc20_16.2: %u1 = converted %int_1.loc20_16, %.loc20_16.1 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc20_16.3: ref %u1 = class_element_access %o.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc20_16.2: %.9ed = impl_witness_access constants.%EqWith.impl_witness.d63, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc20_16.3: <bound method> = bound_method %.loc20_16.2, %impl.elem0.loc20_16.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.22c]
// CHECK:STDOUT:   %specific_fn.loc20_16.2: <specific function> = specific_function %impl.elem0.loc20_16.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc20_16.4: <bound method> = bound_method %.loc20_16.2, %specific_fn.loc20_16.2 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc20_16.4: %u1 = acquire_value %.loc20_16.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc20: init bool = call %bound_method.loc20_16.4(%.loc20_16.2, %.loc20_16.4)
// CHECK:STDOUT:   %.loc20_16.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc20
// CHECK:STDOUT:   %.loc20_16.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc20, %.loc20_16.5
// CHECK:STDOUT:   if %.loc20_16.6 br !match.case.then.loc20 else br !match.case.else.loc20
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc20:
// CHECK:STDOUT:   %int_1.loc20_29: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem1: %.e9b = impl_witness_access constants.%Negate.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %bound_method.loc20_28: <bound method> = bound_method %int_1.loc20_29, %impl.elem1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op.bound]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.call: init Core.IntLiteral = call %bound_method.loc20_28(%int_1.loc20_29) [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %impl.elem0.loc20_30: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc20_30.1: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %impl.elem0.loc20_30 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.65e]
// CHECK:STDOUT:   %specific_fn.loc20_30: <specific function> = specific_function %impl.elem0.loc20_30, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc20_30.2: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %specific_fn.loc20_30 [concrete = constants.%bound_method.a65]
// CHECK:STDOUT:   %.loc20_28.1: Core.IntLiteral = value_of_initializer %Core.IntLiteral.as.Negate.impl.Op.call [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %.loc20_28.2: Core.IntLiteral = converted %Core.IntLiteral.as.Negate.impl.Op.call, %.loc20_28.1 [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc20_30: init %i32 = call %bound_method.loc20_30.2(%.loc20_28.2) [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   %.loc20_30: init %i32 = converted %Core.IntLiteral.as.Negate.impl.Op.call, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc20_30 [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   return %.loc20_30
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc20:
// CHECK:STDOUT:   br !match.done
// CHECK:STDOUT:
// CHECK:STDOUT: !match.done:
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Run() -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Opt.ref.loc25_21: %Opt.type = name_ref Opt, file.%Opt.decl [concrete = constants.%Opt.generic]
// CHECK:STDOUT:   %i32.loc25_25: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %Opt.loc25_28: type = class_type @Opt, @Opt(constants.%i32) [concrete = constants.%Opt.46d]
// CHECK:STDOUT:   %.loc25_29: %Opt.Some.type.39e = specific_constant generated.%Opt.Some.decl, @Opt(constants.%i32) [concrete = constants.%Opt.Some.733]
// CHECK:STDOUT:   %Some.ref: %Opt.Some.type.39e = name_ref Some, %.loc25_29 [concrete = constants.%Opt.Some.733]
// CHECK:STDOUT:   %int_42.loc25: Core.IntLiteral = int_value 42 [concrete = constants.%int_42.20e]
// CHECK:STDOUT:   %Opt.Some.specific_fn: <specific function> = specific_function %Some.ref, @Opt.Some(constants.%i32) [concrete = constants.%Opt.Some.specific_fn]
// CHECK:STDOUT:   %.loc25_37.1: ref %Opt.46d = temporary_storage
// CHECK:STDOUT:   %impl.elem0.loc25: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc25_35.1: <bound method> = bound_method %int_42.loc25, %impl.elem0.loc25 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.bf3]
// CHECK:STDOUT:   %specific_fn.loc25: <specific function> = specific_function %impl.elem0.loc25, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc25_35.2: <bound method> = bound_method %int_42.loc25, %specific_fn.loc25 [concrete = constants.%bound_method.098]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc25: init %i32 = call %bound_method.loc25_35.2(%int_42.loc25) [concrete = constants.%int_42.ac4]
// CHECK:STDOUT:   %.loc25_35.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc25 [concrete = constants.%int_42.ac4]
// CHECK:STDOUT:   %.loc25_35.2: %i32 = converted %int_42.loc25, %.loc25_35.1 [concrete = constants.%int_42.ac4]
// CHECK:STDOUT:   %Opt.Some.call: init %Opt.ba7 to %.loc25_37.1 = call %Opt.Some.specific_fn(%.loc25_35.2)
// CHECK:STDOUT:   %.loc25_37.2: %Opt.46d = converted %Opt.Some.call, <error> [concrete = <error>]
// CHECK:STDOUT:   %.loc25_17: type = splice_block %Opt.loc25_17 [concrete = constants.%Opt.46d] {
// CHECK:STDOUT:     %Opt.ref.loc25_10: %Opt.type = name_ref Opt, file.%Opt.decl [concrete = constants.%Opt.generic]
// CHECK:STDOUT:     %i32.loc25_14: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %Opt.loc25_17: type = class_type @Opt, @Opt(constants.%i32) [concrete = constants.%Opt.46d]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %s: %Opt.46d = wrapper_binding s, <error> [concrete = <error>]
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %s.patt: %pattern_type.25d = value_binding_pattern s [concrete = constants.%s.patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Get.ref: %Get.type = name_ref Get, file.%Get.decl [concrete = constants.%Get]
// CHECK:STDOUT:   %s.ref: %Opt.46d = name_ref s, %s [concrete = <error>]
// CHECK:STDOUT:   %Get.call: init %i32 = call %Get.ref(<error>)
// CHECK:STDOUT:   %int_42.loc26: Core.IntLiteral = int_value 42 [concrete = constants.%int_42.20e]
// CHECK:STDOUT:   %impl.elem1: %.e15 = impl_witness_access constants.%SubWith.impl_witness.d78, element1 [concrete = constants.%Int.as.SubWith.impl.Op.49baee.2]
// CHECK:STDOUT:   %bound_method.loc26_17.1: <bound method> = bound_method %Get.call, %impl.elem1
// CHECK:STDOUT:   %specific_fn.loc26_17: <specific function> = specific_function %impl.elem1, @Int.as.SubWith.impl.Op.2(constants.%int_32, constants.%ImplicitAs.facet.9f1) [concrete = constants.%Int.as.SubWith.impl.Op.specific_fn.4cc768.1]
// CHECK:STDOUT:   %bound_method.loc26_17.2: <bound method> = bound_method %Get.call, %specific_fn.loc26_17
// CHECK:STDOUT:   %.loc26_15.1: %i32 = value_of_initializer %Get.call
// CHECK:STDOUT:   %.loc26_15.2: %i32 = converted %Get.call, %.loc26_15.1
// CHECK:STDOUT:   %.loc26_17: %Int.as.SubWith.impl.Op.type.745d60.1 = specific_constant imports.%Core.Op.9ff, @Int.as.SubWith.impl.dc8(constants.%int_32, constants.%ImplicitAs.facet.9f1) [concrete = constants.%Int.as.SubWith.impl.Op.49baee.1]
// CHECK:STDOUT:   %Op.ref: %Int.as.SubWith.impl.Op.type.745d60.1 = name_ref Op, %.loc26_17 [concrete = constants.%Int.as.SubWith.impl.Op.49baee.1]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.bound: <bound method> = bound_method %.loc26_15.2, %Op.ref
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.specific_fn: <specific function> = specific_function %Op.ref, @Int.as.SubWith.impl.Op.3(constants.%int_32, constants.%ImplicitAs.facet.9f1) [concrete = constants.%Int.as.SubWith.impl.Op.specific_fn.4cc768.2]
// CHECK:STDOUT:   %bound_method.loc26_17.3: <bound method> = bound_method %.loc26_15.2, %Int.as.SubWith.impl.Op.specific_fn
// CHECK:STDOUT:   %impl.elem0.loc26: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc26_19.1: <bound method> = bound_method %int_42.loc26, %impl.elem0.loc26 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.bf3]
// CHECK:STDOUT:   %specific_fn.loc26_19: <specific function> = specific_function %impl.elem0.loc26, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc26_19.2: <bound method> = bound_method %int_42.loc26, %specific_fn.loc26_19 [concrete = constants.%bound_method.098]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc26: init %i32 = call %bound_method.loc26_19.2(%int_42.loc26) [concrete = constants.%int_42.ac4]
// CHECK:STDOUT:   %.loc26_19.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc26 [concrete = constants.%int_42.ac4]
// CHECK:STDOUT:   %.loc26_19.2: %i32 = converted %int_42.loc26, %.loc26_19.1 [concrete = constants.%int_42.ac4]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.call: init %i32 = call %bound_method.loc26_17.3(%.loc26_15.2, %.loc26_19.2)
// CHECK:STDOUT:   return %Int.as.SubWith.impl.Op.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Opt(constants.%T.67d) {
// CHECK:STDOUT:   %T.patt.loc12_13.2 => constants.%T.patt.d47
// CHECK:STDOUT:   %T.loc12_13.1 => constants.%T.67d
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.51d1c4.1
// CHECK:STDOUT:   %value.param_patt => constants.%value.param_patt.98e
// CHECK:STDOUT:   %value.patt => constants.%value.patt.864
// CHECK:STDOUT:   %require_complete.loc13 => constants.%require_complete.944
// CHECK:STDOUT:   %tuple.type => constants.%tuple.type.026
// CHECK:STDOUT:   %.loc15_1.14 => constants.%.a2d
// CHECK:STDOUT:   %struct_type.discriminant.payload => constants.%struct_type.discriminant.payload.508
// CHECK:STDOUT:   %complete_type.loc15_1.2 => constants.%complete_type.abf
// CHECK:STDOUT:   %Opt.Some.type => constants.%Opt.Some.type.d0c
// CHECK:STDOUT:   %Opt.Some => constants.%Opt.Some.821
// CHECK:STDOUT:   %Opt => constants.%Opt.ba7
// CHECK:STDOUT:   %require_complete.loc15 => constants.%require_complete.dd1
// CHECK:STDOUT:   %uninit.loc15_1.2 => constants.%uninit.37a
// CHECK:STDOUT:   %Opt.val => constants.%Opt.val.a5e
// CHECK:STDOUT:   %.loc15_1.15 => constants.%.9a0
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Opt.Some(constants.%T.67d) {
// CHECK:STDOUT:   %T => constants.%T.67d
// CHECK:STDOUT:   %pattern_type.loc12_21.1 => constants.%pattern_type.51d1c4.1
// CHECK:STDOUT:   %_.param_patt.loc12_21.2 => constants.%_.param_patt.339
// CHECK:STDOUT:   %_.patt.loc12_21.2 => constants.%_.patt.fd3
// CHECK:STDOUT:   %Opt => constants.%Opt.ba7
// CHECK:STDOUT:   %.loc12_21.7 => constants.%.3c3
// CHECK:STDOUT:   %pattern_type.loc12_21.2 => constants.%pattern_type.86b
// CHECK:STDOUT:   %return.param_patt.loc12_21.2 => constants.%return.param_patt.e2a
// CHECK:STDOUT:   %return.patt.loc12_21.2 => constants.%return.patt.ac3
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Opt(constants.%i32) {
// CHECK:STDOUT:   %T.patt.loc12_13.2 => constants.%T.patt.d47
// CHECK:STDOUT:   %T.loc12_13.1 => constants.%i32
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.6b6
// CHECK:STDOUT:   %value.param_patt => constants.%value.param_patt.34f
// CHECK:STDOUT:   %value.patt => constants.%value.patt.f6a
// CHECK:STDOUT:   %require_complete.loc13 => constants.%complete_type.f8a
// CHECK:STDOUT:   %tuple.type => constants.%tuple.type.a8a
// CHECK:STDOUT:   %.loc15_1.14 => constants.%.e8e
// CHECK:STDOUT:   %struct_type.discriminant.payload => constants.%struct_type.discriminant.payload.e99
// CHECK:STDOUT:   %complete_type.loc15_1.2 => constants.%complete_type.378
// CHECK:STDOUT:   %Opt.Some.type => constants.%Opt.Some.type.39e
// CHECK:STDOUT:   %Opt.Some => constants.%Opt.Some.733
// CHECK:STDOUT:   %Opt => constants.%Opt.46d
// CHECK:STDOUT:   %require_complete.loc15 => constants.%complete_type.378
// CHECK:STDOUT:   %uninit.loc15_1.2 => constants.%uninit.060
// CHECK:STDOUT:   %Opt.val => constants.%Opt.val.b51
// CHECK:STDOUT:   %.loc15_1.15 => constants.%.b5c
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Opt.Some(constants.%i32) {
// CHECK:STDOUT:   %T => constants.%i32
// CHECK:STDOUT:   %pattern_type.loc12_21.1 => constants.%pattern_type.6b6
// CHECK:STDOUT:   %_.param_patt.loc12_21.2 => constants.%_.param_patt.fb2
// CHECK:STDOUT:   %_.patt.loc12_21.2 => constants.%_.patt.b75
// CHECK:STDOUT:   %Opt => constants.%Opt.46d
// CHECK:STDOUT:   %.loc12_21.7 => constants.%.bda
// CHECK:STDOUT:   %pattern_type.loc12_21.2 => constants.%pattern_type.25d
// CHECK:STDOUT:   %return.param_patt.loc12_21.2 => constants.%return.param_patt.63c
// CHECK:STDOUT:   %return.patt.loc12_21.2 => constants.%return.patt.c82
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc12_21.1 => constants.%complete_type.f8a
// CHECK:STDOUT:   %require_complete.loc12_21.2 => constants.%complete_type.378
// CHECK:STDOUT:   %tuple.type => constants.%tuple.type.a8a
// CHECK:STDOUT:   %.loc12_21.8 => constants.%.e8e
// CHECK:STDOUT:   %require_complete.loc12_21.3 => constants.%complete_type.147
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- two_sizes.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %.Self.frozen.197: %type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %pattern_type.98f: type = pattern_type type [concrete]
// CHECK:STDOUT:   %T.patt.d47: %pattern_type.98f = symbolic_binding_pattern T, 0 [symbolic]
// CHECK:STDOUT:   %T.67d: type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %Pair.type: type = generic_class_type @Pair [concrete]
// CHECK:STDOUT:   %Pair.generic: %Pair.type = struct_value () [concrete]
// CHECK:STDOUT:   %Pair.66e: type = class_type @Pair, @Pair(%T.67d) [symbolic]
// CHECK:STDOUT:   %pattern_type.51d1c4.1: type = pattern_type %T.67d [symbolic]
// CHECK:STDOUT:   %x.param_patt.91d: %pattern_type.51d1c4.1 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %x.patt.800: %pattern_type.51d1c4.1 = at_binding_pattern x, %x.param_patt.91d [symbolic]
// CHECK:STDOUT:   %y.param_patt.be3: %pattern_type.51d1c4.1 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %y.patt.b85: %pattern_type.51d1c4.1 = at_binding_pattern y, %y.param_patt.be3 [symbolic]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %u1: type = class_type @UInt, @UInt(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %require_complete.944: <witness> = require_complete_type %T.67d [symbolic]
// CHECK:STDOUT:   %tuple.type.07a: type = tuple_type (%T.67d, %T.67d) [symbolic]
// CHECK:STDOUT:   %.d27: type = custom_layout_type {size=0, align=0, .Both@0: %tuple.type.07a} [symbolic]
// CHECK:STDOUT:   %struct_type.discriminant.payload.1ec: type = struct_type {.discriminant: %u1, .payload: %.d27} [symbolic]
// CHECK:STDOUT:   %complete_type.d2c: <witness> = complete_type_witness %struct_type.discriminant.payload.1ec [symbolic]
// CHECK:STDOUT:   %struct_type.discriminant: type = struct_type {.discriminant: %u1} [concrete]
// CHECK:STDOUT:   %_.param_patt.339: %pattern_type.51d1c4.1 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %_.patt.fd3: %pattern_type.51d1c4.1 = at_binding_pattern _, %_.param_patt.339 [symbolic]
// CHECK:STDOUT:   %.f65: Core.Form = init_form %Pair.66e [symbolic]
// CHECK:STDOUT:   %pattern_type.b6c: type = pattern_type %Pair.66e [symbolic]
// CHECK:STDOUT:   %return.param_patt.4f6: %pattern_type.b6c = out_param_pattern [symbolic]
// CHECK:STDOUT:   %return.patt.8b5: %pattern_type.b6c = return_slot_pattern %return.param_patt.4f6, %Pair.66e [symbolic]
// CHECK:STDOUT:   %Pair.Both.type.9e9: type = fn_type @Pair.Both, @Pair(%T.67d) [symbolic]
// CHECK:STDOUT:   %Pair.Both.4cf: %Pair.Both.type.9e9 = struct_value () [symbolic]
// CHECK:STDOUT:   %require_complete.9bb: <witness> = require_complete_type %Pair.66e [symbolic]
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
// CHECK:STDOUT:   %require_complete.22a: <witness> = require_complete_type %tuple.type.07a [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %bound_method.d7a: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
// CHECK:STDOUT:   %int_1.233: %u1 = int_value 1 [concrete]
// CHECK:STDOUT:   %struct: %struct_type.discriminant = struct_value (%int_1.233) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.type.0c5: type = fn_type @UInt.as.Copy.impl.Op, @UInt.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.38a: %UInt.as.Copy.impl.Op.type.0c5 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.fb7: <witness> = impl_witness imports.%Copy.impl_witness_table.fe3, @UInt.as.Copy.impl(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.type.c97: type = fn_type @UInt.as.Copy.impl.Op, @UInt.as.Copy.impl(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.d9c: %UInt.as.Copy.impl.Op.type.c97 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet: %Copy.type = facet_value %u1, (%Copy.impl_witness.fb7) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.4d4: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet) [concrete]
// CHECK:STDOUT:   %.37a: type = fn_type_with_self_type %Copy.WithSelf.Op.type.4d4, %Copy.facet [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.bound: <bound method> = bound_method %int_1.233, %UInt.as.Copy.impl.Op.d9c [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %UInt.as.Copy.impl.Op.d9c, @UInt.as.Copy.impl.Op(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.edd: <bound method> = bound_method %int_1.233, %UInt.as.Copy.impl.Op.specific_fn [concrete]
// CHECK:STDOUT:   %uninit.216: %.d27 = uninitialized_value [symbolic]
// CHECK:STDOUT:   %Pair.val.0a4: %Pair.66e = struct_value (%int_1.233, %uninit.216) [symbolic]
// CHECK:STDOUT:   %.f95: ref %Pair.66e = temporary invalid, %Pair.val.0a4 [symbolic]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %Int.67af24.1: type = class_type @Int, @Int(%N) [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %Pair.1ee: type = class_type @Pair, @Pair(%i32) [concrete]
// CHECK:STDOUT:   %pattern_type.b73: type = pattern_type %Pair.1ee [concrete]
// CHECK:STDOUT:   %p.param_patt.b74: %pattern_type.b73 = value_param_pattern [concrete]
// CHECK:STDOUT:   %p.patt.fb2: %pattern_type.b73 = at_binding_pattern p, %p.param_patt.b74 [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %Classify32.type: type = fn_type @Classify32 [concrete]
// CHECK:STDOUT:   %Classify32: %Classify32.type = struct_value () [concrete]
// CHECK:STDOUT:   %x.param_patt.cee: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %x.patt.fbe: %pattern_type.6b6 = at_binding_pattern x, %x.param_patt.cee [concrete]
// CHECK:STDOUT:   %y.param_patt.673: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %y.patt.b43: %pattern_type.6b6 = at_binding_pattern y, %y.param_patt.673 [concrete]
// CHECK:STDOUT:   %i32.builtin: type = int_type signed, %int_32 [concrete]
// CHECK:STDOUT:   %complete_type.f8a: <witness> = complete_type_witness %i32.builtin [concrete]
// CHECK:STDOUT:   %tuple.type.e55: type = tuple_type (%i32, %i32) [concrete]
// CHECK:STDOUT:   %.20c: type = custom_layout_type {size=8, align=4, .Both@0: %tuple.type.e55} [concrete]
// CHECK:STDOUT:   %struct_type.discriminant.payload.92c: type = struct_type {.discriminant: %u1, .payload: %.20c} [concrete]
// CHECK:STDOUT:   %complete_type.ea6: <witness> = complete_type_witness %struct_type.discriminant.payload.92c [concrete]
// CHECK:STDOUT:   %Pair.Both.type.9d6: type = fn_type @Pair.Both, @Pair(%i32) [concrete]
// CHECK:STDOUT:   %Pair.Both.c82: %Pair.Both.type.9d6 = struct_value () [concrete]
// CHECK:STDOUT:   %uninit.525: %.20c = uninitialized_value [concrete]
// CHECK:STDOUT:   %Pair.val.6e7: %Pair.1ee = struct_value (%int_1.233, %uninit.525) [concrete]
// CHECK:STDOUT:   %.343: ref %Pair.1ee = temporary invalid, %Pair.val.6e7 [concrete]
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
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.specific_fn.6b6: <specific function> = specific_function %UInt.as.EqWith.impl.Equal.ba4, @UInt.as.EqWith.impl.Equal.1(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.a82: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
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
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.953: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %Pair.01a: type = class_type @Pair, @Pair(%i64) [concrete]
// CHECK:STDOUT:   %pattern_type.fc3: type = pattern_type %Pair.01a [concrete]
// CHECK:STDOUT:   %p.param_patt.fb6: %pattern_type.fc3 = value_param_pattern [concrete]
// CHECK:STDOUT:   %p.patt.684: %pattern_type.fc3 = at_binding_pattern p, %p.param_patt.fb6 [concrete]
// CHECK:STDOUT:   %Classify64.type: type = fn_type @Classify64 [concrete]
// CHECK:STDOUT:   %Classify64: %Classify64.type = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.f57: type = pattern_type %i64 [concrete]
// CHECK:STDOUT:   %x.param_patt.7b8: %pattern_type.f57 = value_param_pattern [concrete]
// CHECK:STDOUT:   %x.patt.451: %pattern_type.f57 = at_binding_pattern x, %x.param_patt.7b8 [concrete]
// CHECK:STDOUT:   %y.param_patt.83d: %pattern_type.f57 = value_param_pattern [concrete]
// CHECK:STDOUT:   %y.patt.d31: %pattern_type.f57 = at_binding_pattern y, %y.param_patt.83d [concrete]
// CHECK:STDOUT:   %i64.builtin: type = int_type signed, %int_64 [concrete]
// CHECK:STDOUT:   %complete_type.4a1: <witness> = complete_type_witness %i64.builtin [concrete]
// CHECK:STDOUT:   %tuple.type.1ac: type = tuple_type (%i64, %i64) [concrete]
// CHECK:STDOUT:   %.58e: type = custom_layout_type {size=16, align=8, .Both@0: %tuple.type.1ac} [concrete]
// CHECK:STDOUT:   %struct_type.discriminant.payload.8ac: type = struct_type {.discriminant: %u1, .payload: %.58e} [concrete]
// CHECK:STDOUT:   %complete_type.ab0: <witness> = complete_type_witness %struct_type.discriminant.payload.8ac [concrete]
// CHECK:STDOUT:   %Pair.Both.type.1a5: type = fn_type @Pair.Both, @Pair(%i64) [concrete]
// CHECK:STDOUT:   %Pair.Both.56a: %Pair.Both.type.1a5 = struct_value () [concrete]
// CHECK:STDOUT:   %uninit.ccc: %.58e = uninitialized_value [concrete]
// CHECK:STDOUT:   %Pair.val.765: %Pair.01a = struct_value (%int_1.233, %uninit.ccc) [concrete]
// CHECK:STDOUT:   %.4a7: ref %Pair.01a = temporary invalid, %Pair.val.765 [concrete]
// CHECK:STDOUT:   %Run.type: type = fn_type @Run [concrete]
// CHECK:STDOUT:   %Run: %Run.type = struct_value () [concrete]
// CHECK:STDOUT:   %a.patt: %pattern_type.b73 = value_binding_pattern a [concrete]
// CHECK:STDOUT:   %int_2.ecc: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %_.param_patt.fb2: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %_.patt.b75: %pattern_type.6b6 = at_binding_pattern _, %_.param_patt.fb2 [concrete]
// CHECK:STDOUT:   %.b22: Core.Form = init_form %Pair.1ee [concrete]
// CHECK:STDOUT:   %return.param_patt.7fa: %pattern_type.b73 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.52d: %pattern_type.b73 = return_slot_pattern %return.param_patt.7fa, %Pair.1ee [concrete]
// CHECK:STDOUT:   %Pair.Both.specific_fn.212: <specific function> = specific_function %Pair.Both.c82, @Pair.Both(%i32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.9f3: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.3cb: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_2.295: %i32 = int_value 2 [concrete]
// CHECK:STDOUT:   %b.patt: %pattern_type.fc3 = value_binding_pattern b [concrete]
// CHECK:STDOUT:   %int_3.1ba: Core.IntLiteral = int_value 3 [concrete]
// CHECK:STDOUT:   %int_4.0c1: Core.IntLiteral = int_value 4 [concrete]
// CHECK:STDOUT:   %_.param_patt.2f0: %pattern_type.f57 = value_param_pattern [concrete]
// CHECK:STDOUT:   %_.patt.233: %pattern_type.f57 = at_binding_pattern _, %_.param_patt.2f0 [concrete]
// CHECK:STDOUT:   %.02d: Core.Form = init_form %Pair.01a [concrete]
// CHECK:STDOUT:   %return.param_patt.fa2: %pattern_type.fc3 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.c93: %pattern_type.fc3 = return_slot_pattern %return.param_patt.fa2, %Pair.01a [concrete]
// CHECK:STDOUT:   %Pair.Both.specific_fn.471: <specific function> = specific_function %Pair.Both.56a, @Pair.Both(%i64) [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.221: type = facet_type <@ImplicitAs, @ImplicitAs(%i64)> [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.091: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.b3c, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_64) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.55a: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_64) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.55a = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.6e8: %ImplicitAs.type.221 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.091) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.a04: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i64, %ImplicitAs.facet.6e8) [concrete]
// CHECK:STDOUT:   %.f349: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.a04, %ImplicitAs.facet.6e8 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.e9c: <bound method> = bound_method %int_3.1ba, %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.f33: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(%int_64) [concrete]
// CHECK:STDOUT:   %bound_method.740: <bound method> = bound_method %int_3.1ba, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.f33 [concrete]
// CHECK:STDOUT:   %int_3.bd2: %i64 = int_value 3 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.b50: <bound method> = bound_method %int_4.0c1, %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b [concrete]
// CHECK:STDOUT:   %bound_method.912: <bound method> = bound_method %int_4.0c1, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.f33 [concrete]
// CHECK:STDOUT:   %int_4.825: %i64 = int_value 4 [concrete]
// CHECK:STDOUT:   %AddWith.type.be9: type = facet_type <@AddWith, @AddWith(%i32)> [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.610: type = fn_type @Int.as.AddWith.impl.Op.1, @Int.as.AddWith.impl.3af(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.732: %Int.as.AddWith.impl.Op.type.610 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.type.f7de31.2: type = facet_type <@ImplicitAs, @ImplicitAs(%Int.67af24.1)> [symbolic]
// CHECK:STDOUT:   %U.4e6: %ImplicitAs.type.f7de31.2 = symbolic_binding U, 1 [symbolic]
// CHECK:STDOUT:   %AddWith.impl_witness.3af: <witness> = impl_witness imports.%AddWith.impl_witness_table.9d9, @Int.as.AddWith.impl.3af(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.056: type = fn_type @Int.as.AddWith.impl.Op.1, @Int.as.AddWith.impl.3af(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.365: %Int.as.AddWith.impl.Op.type.056 = struct_value () [concrete]
// CHECK:STDOUT:   %AddWith.facet.b8a: %AddWith.type.be9 = facet_value %i32, (%AddWith.impl_witness.3af) [concrete]
// CHECK:STDOUT:   %AddWith.WithSelf.Op.type.e15: type = fn_type @AddWith.WithSelf.Op, @AddWith.WithSelf(%i32, %AddWith.facet.b8a) [concrete]
// CHECK:STDOUT:   %.516: type = fn_type_with_self_type %AddWith.WithSelf.Op.type.e15, %AddWith.facet.b8a [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.specific_fn.f25: <specific function> = specific_function %Int.as.AddWith.impl.Op.365, @Int.as.AddWith.impl.Op.1(%int_32) [concrete]
// CHECK:STDOUT:   %SubWith.type.4c2: type = facet_type <@SubWith, @SubWith(Core.IntLiteral)> [concrete]
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
// CHECK:STDOUT:   %complete_type.6c4: <witness> = complete_type_witness %tuple.type.e55 [concrete]
// CHECK:STDOUT:   %complete_type.3d3: <witness> = complete_type_witness %tuple.type.1ac [concrete]
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
// CHECK:STDOUT:   %Core.import_ref.b4fd3a.1 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.6842: @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op.type (%Int.as.AddWith.impl.Op.type.610) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op (constants.%Int.as.AddWith.impl.Op.732)]
// CHECK:STDOUT:   %AddWith.impl_witness_table.9d9 = impl_witness_table (%Core.import_ref.b4fd3a.1, %Core.import_ref.6842), @Int.as.AddWith.impl.3af [concrete]
// CHECK:STDOUT:   %Core.import_ref.b4fd3a.5 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.6fa8: @Int.as.SubWith.impl.dc8.%Int.as.SubWith.impl.Op.type.2 (%Int.as.SubWith.impl.Op.type.6f3321.1) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.SubWith.impl.dc8.%Int.as.SubWith.impl.Op.2 (constants.%Int.as.SubWith.impl.Op.a37528.1)]
// CHECK:STDOUT:   %SubWith.impl_witness_table.dc9 = impl_witness_table (%Core.import_ref.b4fd3a.5, %Core.import_ref.6fa8), @Int.as.SubWith.impl.dc8 [concrete]
// CHECK:STDOUT:   %Core.Op.9ff: @Int.as.SubWith.impl.dc8.%Int.as.SubWith.impl.Op.type.1 (%Int.as.SubWith.impl.Op.type.6f3321.2) = import_ref Core//prelude/types/int, Op, loaded [symbolic = @Int.as.SubWith.impl.dc8.%Int.as.SubWith.impl.Op.1 (constants.%Int.as.SubWith.impl.Op.a37528.2)]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %Pair.Both.decl: @Pair.%Pair.Both.type (%Pair.Both.type.9e9) = fn_decl @Pair.Both [symbolic = @Pair.%Pair.Both (constants.%Pair.Both.4cf)] {
// CHECK:STDOUT:     %_.param_patt.loc9_22.1: @Pair.Both.%pattern_type.loc9_22.1 (%pattern_type.51d1c4.1) = value_param_pattern [symbolic = %_.param_patt.loc9_22.3 (constants.%_.param_patt.339)]
// CHECK:STDOUT:     %_.patt.loc9_22.1: @Pair.Both.%pattern_type.loc9_22.1 (%pattern_type.51d1c4.1) = at_binding_pattern _, %_.param_patt.loc9_22.1 [symbolic = %_.patt.loc9_22.3 (constants.%_.patt.fd3)]
// CHECK:STDOUT:     %_.param_patt.loc9_22.2: @Pair.Both.%pattern_type.loc9_22.1 (%pattern_type.51d1c4.1) = value_param_pattern [symbolic = %_.param_patt.loc9_22.3 (constants.%_.param_patt.339)]
// CHECK:STDOUT:     %_.patt.loc9_22.2: @Pair.Both.%pattern_type.loc9_22.1 (%pattern_type.51d1c4.1) = at_binding_pattern _, %_.param_patt.loc9_22.2 [symbolic = %_.patt.loc9_22.3 (constants.%_.patt.fd3)]
// CHECK:STDOUT:     %return.param_patt.loc9_22.1: @Pair.Both.%pattern_type.loc9_22.2 (%pattern_type.b6c) = out_param_pattern [symbolic = %return.param_patt.loc9_22.2 (constants.%return.param_patt.4f6)]
// CHECK:STDOUT:     %return.patt.loc9_22.1: @Pair.Both.%pattern_type.loc9_22.2 (%pattern_type.b6c) = return_slot_pattern %return.param_patt.loc9_22.1, constants.%Pair.66e [symbolic = %return.patt.loc9_22.2 (constants.%return.patt.8b5)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc9_22.9: Core.Form = init_form constants.%Pair.66e [symbolic = %.loc9_22.7 (constants.%.f65)]
// CHECK:STDOUT:     %_.param.loc9_22.1: @Pair.Both.%T (%T.67d) = value_param call_param0
// CHECK:STDOUT:     %_.loc9_22.1: @Pair.Both.%T (%T.67d) = wrapper_binding _, %_.param.loc9_22.1
// CHECK:STDOUT:     %_.param.loc9_22.2: @Pair.Both.%T (%T.67d) = value_param call_param1
// CHECK:STDOUT:     %_.loc9_22.2: @Pair.Both.%T (%T.67d) = wrapper_binding _, %_.param.loc9_22.2
// CHECK:STDOUT:     %return.param: ref @Pair.Both.%Pair (%Pair.66e) = out_param call_param2
// CHECK:STDOUT:     %return: ref @Pair.Both.%Pair (%Pair.66e) = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Pair.decl: %Pair.type = class_decl @Pair [concrete = constants.%Pair.generic] {
// CHECK:STDOUT:     %T.patt.loc9_14.1: %pattern_type.98f = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc9_14.2 (constants.%T.patt.d47)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc9_16.1: type = splice_block %.loc9_16.2 [concrete = type] {
// CHECK:STDOUT:       %.Self.frozen: %type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen.197]
// CHECK:STDOUT:       %.loc9_16.2: type = type_literal type [concrete = type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc9_14.2: type = symbolic_binding T, 0 [symbolic = %T.loc9_14.1 (constants.%T.67d)]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Classify32.decl: %Classify32.type = fn_decl @Classify32 [concrete = constants.%Classify32] {
// CHECK:STDOUT:     %p.param_patt: %pattern_type.b73 = value_param_pattern [concrete = constants.%p.param_patt.b74]
// CHECK:STDOUT:     %p.patt: %pattern_type.b73 = at_binding_pattern p, %p.param_patt [concrete = constants.%p.patt.fb2]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc14_32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc14_32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc14_32: Core.Form = init_form %i32.loc14_32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %p.param: %Pair.1ee = value_param call_param0
// CHECK:STDOUT:     %.loc14_26: type = splice_block %Pair [concrete = constants.%Pair.1ee] {
// CHECK:STDOUT:       %Pair.ref: %Pair.type = name_ref Pair, file.%Pair.decl [concrete = constants.%Pair.generic]
// CHECK:STDOUT:       %i32.loc14_23: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %Pair: type = class_type @Pair, @Pair(constants.%i32) [concrete = constants.%Pair.1ee]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %p: %Pair.1ee = wrapper_binding p, %p.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Classify64.decl: %Classify64.type = fn_decl @Classify64 [concrete = constants.%Classify64] {
// CHECK:STDOUT:     %p.param_patt: %pattern_type.fc3 = value_param_pattern [concrete = constants.%p.param_patt.fb6]
// CHECK:STDOUT:     %p.patt: %pattern_type.fc3 = at_binding_pattern p, %p.param_patt [concrete = constants.%p.patt.684]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc21_32: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %p.param: %Pair.01a = value_param call_param0
// CHECK:STDOUT:     %.loc21_26: type = splice_block %Pair [concrete = constants.%Pair.01a] {
// CHECK:STDOUT:       %Pair.ref: %Pair.type = name_ref Pair, file.%Pair.decl [concrete = constants.%Pair.generic]
// CHECK:STDOUT:       %i64: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:       %Pair: type = class_type @Pair, @Pair(constants.%i64) [concrete = constants.%Pair.01a]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %p: %Pair.01a = wrapper_binding p, %p.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Run.decl: %Run.type = fn_decl @Run [concrete = constants.%Run] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc31 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc31: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc31: Core.Form = init_form %i32.loc31 [concrete = constants.%.795f]
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param0
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic class @Pair(%T.loc9_14.2: type) {
// CHECK:STDOUT:   %T.patt.loc9_14.2: %pattern_type.98f = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc9_14.2 (constants.%T.patt.d47)]
// CHECK:STDOUT:   %T.loc9_14.1: type = symbolic_binding T, 0 [symbolic = %T.loc9_14.1 (constants.%T.67d)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %pattern_type: type = pattern_type %T.loc9_14.1 [symbolic = %pattern_type (constants.%pattern_type.51d1c4.1)]
// CHECK:STDOUT:   %x.param_patt: @Pair.%pattern_type (%pattern_type.51d1c4.1) = value_param_pattern [symbolic = %x.param_patt (constants.%x.param_patt.91d)]
// CHECK:STDOUT:   %x.patt: @Pair.%pattern_type (%pattern_type.51d1c4.1) = at_binding_pattern x, %x.param_patt [symbolic = %x.patt (constants.%x.patt.800)]
// CHECK:STDOUT:   %y.param_patt: @Pair.%pattern_type (%pattern_type.51d1c4.1) = value_param_pattern [symbolic = %y.param_patt (constants.%y.param_patt.be3)]
// CHECK:STDOUT:   %y.patt: @Pair.%pattern_type (%pattern_type.51d1c4.1) = at_binding_pattern y, %y.param_patt [symbolic = %y.patt (constants.%y.patt.b85)]
// CHECK:STDOUT:   %require_complete.loc10: <witness> = require_complete_type %T.loc9_14.1 [symbolic = %require_complete.loc10 (constants.%require_complete.944)]
// CHECK:STDOUT:   %tuple.type: type = tuple_type (%T.loc9_14.1, %T.loc9_14.1) [symbolic = %tuple.type (constants.%tuple.type.07a)]
// CHECK:STDOUT:   %.loc12_1.14: type = custom_layout_type {size=0, align=0, .Both@0: @Pair.%tuple.type (%tuple.type.07a)} [symbolic = %.loc12_1.14 (constants.%.d27)]
// CHECK:STDOUT:   %struct_type.discriminant.payload: type = struct_type {.discriminant: %u1, .payload: @Pair.%.loc12_1.14 (%.d27)} [symbolic = %struct_type.discriminant.payload (constants.%struct_type.discriminant.payload.1ec)]
// CHECK:STDOUT:   %complete_type.loc12_1.2: <witness> = complete_type_witness %struct_type.discriminant.payload [symbolic = %complete_type.loc12_1.2 (constants.%complete_type.d2c)]
// CHECK:STDOUT:   %Pair.Both.type: type = fn_type @Pair.Both, @Pair(%T.loc9_14.1) [symbolic = %Pair.Both.type (constants.%Pair.Both.type.9e9)]
// CHECK:STDOUT:   %Pair.Both: @Pair.%Pair.Both.type (%Pair.Both.type.9e9) = struct_value () [symbolic = %Pair.Both (constants.%Pair.Both.4cf)]
// CHECK:STDOUT:   %Pair: type = class_type @Pair, @Pair(%T.loc9_14.1) [symbolic = %Pair (constants.%Pair.66e)]
// CHECK:STDOUT:   %require_complete.loc12: <witness> = require_complete_type %Pair [symbolic = %require_complete.loc12 (constants.%require_complete.9bb)]
// CHECK:STDOUT:   %uninit.loc12_1.2: @Pair.%.loc12_1.14 (%.d27) = uninitialized_value [symbolic = %uninit.loc12_1.2 (constants.%uninit.216)]
// CHECK:STDOUT:   %Pair.val: @Pair.%Pair (%Pair.66e) = struct_value (constants.%int_1.233, %uninit.loc12_1.2) [symbolic = %Pair.val (constants.%Pair.val.0a4)]
// CHECK:STDOUT:   %.loc12_1.15: ref @Pair.%Pair (%Pair.66e) = temporary invalid, %Pair.val [symbolic = %.loc12_1.15 (constants.%.f95)]
// CHECK:STDOUT:
// CHECK:STDOUT:   class {
// CHECK:STDOUT:     %x.param: @Pair.%T.loc9_14.1 (%T.67d) = value_param call_param0
// CHECK:STDOUT:     %T.ref.loc10_11: type = name_ref T, %T.loc9_14.2 [symbolic = %T.loc9_14.1 (constants.%T.67d)]
// CHECK:STDOUT:     %x: @Pair.%T.loc9_14.1 (%T.67d) = wrapper_binding x, %x.param
// CHECK:STDOUT:     %y.param: @Pair.%T.loc9_14.1 (%T.67d) = value_param call_param1
// CHECK:STDOUT:     %T.ref.loc10_17: type = name_ref T, %T.loc9_14.2 [symbolic = %T.loc9_14.1 (constants.%T.67d)]
// CHECK:STDOUT:     %y: @Pair.%T.loc9_14.1 (%T.67d) = wrapper_binding y, %y.param
// CHECK:STDOUT:     %.loc12_1.1: type = custom_layout_type {size=0, align=0, .Both@0: %tuple.type.07a} [symbolic = %.loc12_1.14 (constants.%.d27)]
// CHECK:STDOUT:     %complete_type.loc12_1.1: <witness> = complete_type_witness constants.%struct_type.discriminant.payload.1ec [symbolic = %complete_type.loc12_1.2 (constants.%complete_type.d2c)]
// CHECK:STDOUT:     %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:     %impl.elem0.loc12_1.1: %.e60 = impl_witness_access constants.%ImplicitAs.impl_witness.9a9, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:     %bound_method.loc12_1.1: <bound method> = bound_method %int_1, %impl.elem0.loc12_1.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:     %specific_fn.loc12_1.1: <specific function> = specific_function %impl.elem0.loc12_1.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:     %bound_method.loc12_1.2: <bound method> = bound_method %int_1, %specific_fn.loc12_1.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %u1 = call %bound_method.loc12_1.2(%int_1) [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc12_1.2: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc12_1.3: %u1 = converted %int_1, %.loc12_1.2 [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc12_1.4: %struct_type.discriminant = struct_literal (%.loc12_1.3) [concrete = constants.%struct]
// CHECK:STDOUT:     %impl.elem0.loc12_1.2: %.37a = impl_witness_access constants.%Copy.impl_witness.fb7, element0 [concrete = constants.%UInt.as.Copy.impl.Op.d9c]
// CHECK:STDOUT:     %bound_method.loc12_1.3: <bound method> = bound_method %.loc12_1.3, %impl.elem0.loc12_1.2 [concrete = constants.%UInt.as.Copy.impl.Op.bound]
// CHECK:STDOUT:     %specific_fn.loc12_1.2: <specific function> = specific_function %impl.elem0.loc12_1.2, @UInt.as.Copy.impl.Op(constants.%int_1.5b8) [concrete = constants.%UInt.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:     %bound_method.loc12_1.4: <bound method> = bound_method %.loc12_1.3, %specific_fn.loc12_1.2 [concrete = constants.%bound_method.edd]
// CHECK:STDOUT:     %UInt.as.Copy.impl.Op.call: init %u1 = call %bound_method.loc12_1.4(%.loc12_1.3) [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc12_1.5: ref @Pair.%Pair (%Pair.66e) = temporary_storage
// CHECK:STDOUT:     %.loc12_1.6: ref %u1 = class_element_access %.loc12_1.5, element0
// CHECK:STDOUT:     %.loc12_1.7: init %u1 to %.loc12_1.6 = in_place_init %UInt.as.Copy.impl.Op.call [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc12_1.8: ref @Pair.%.loc12_1.14 (%.d27) = class_element_access %.loc12_1.5, element1
// CHECK:STDOUT:     %uninit.loc12_1.1: @Pair.%.loc12_1.14 (%.d27) = uninitialized_value [symbolic = %uninit.loc12_1.2 (constants.%uninit.216)]
// CHECK:STDOUT:     %.loc12_1.9: init @Pair.%.loc12_1.14 (%.d27) to %.loc12_1.8 = in_place_init %uninit.loc12_1.1 [symbolic = %uninit.loc12_1.2 (constants.%uninit.216)]
// CHECK:STDOUT:     %.loc12_1.10: init @Pair.%Pair (%Pair.66e) to %.loc12_1.5 = class_init (%.loc12_1.7, %.loc12_1.9) [symbolic = %Pair.val (constants.%Pair.val.0a4)]
// CHECK:STDOUT:     %.loc12_1.11: init @Pair.%Pair (%Pair.66e) = converted %.loc12_1.4, %.loc12_1.10 [symbolic = %Pair.val (constants.%Pair.val.0a4)]
// CHECK:STDOUT:     %.loc12_1.12: ref @Pair.%Pair (%Pair.66e) = temporary %.loc12_1.5, %.loc12_1.11 [symbolic = %.loc12_1.15 (constants.%.f95)]
// CHECK:STDOUT:     %.loc12_1.13: @Pair.%Pair (%Pair.66e) = acquire_value %.loc12_1.12 [symbolic = %Pair.val (constants.%Pair.val.0a4)]
// CHECK:STDOUT:     %Neither: @Pair.%Pair (%Pair.66e) = wrapper_binding Neither, %.loc12_1.13
// CHECK:STDOUT:     complete_type_witness = %complete_type.loc12_1.1
// CHECK:STDOUT:
// CHECK:STDOUT:   !members:
// CHECK:STDOUT:     .Self = constants.%Pair.66e
// CHECK:STDOUT:     .T = <poisoned>
// CHECK:STDOUT:     .Both = generated.%Pair.Both.decl
// CHECK:STDOUT:     .Neither = %Neither
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @Pair.Both(@Pair.%T.loc9_14.2: type) {
// CHECK:STDOUT:   %T: type = symbolic_binding T, 0 [symbolic = %T (constants.%T.67d)]
// CHECK:STDOUT:   %pattern_type.loc9_22.1: type = pattern_type %T [symbolic = %pattern_type.loc9_22.1 (constants.%pattern_type.51d1c4.1)]
// CHECK:STDOUT:   %_.param_patt.loc9_22.3: @Pair.Both.%pattern_type.loc9_22.1 (%pattern_type.51d1c4.1) = value_param_pattern [symbolic = %_.param_patt.loc9_22.3 (constants.%_.param_patt.339)]
// CHECK:STDOUT:   %_.patt.loc9_22.3: @Pair.Both.%pattern_type.loc9_22.1 (%pattern_type.51d1c4.1) = at_binding_pattern _, %_.param_patt.loc9_22.3 [symbolic = %_.patt.loc9_22.3 (constants.%_.patt.fd3)]
// CHECK:STDOUT:   %Pair: type = class_type @Pair, @Pair(%T) [symbolic = %Pair (constants.%Pair.66e)]
// CHECK:STDOUT:   %.loc9_22.7: Core.Form = init_form %Pair [symbolic = %.loc9_22.7 (constants.%.f65)]
// CHECK:STDOUT:   %pattern_type.loc9_22.2: type = pattern_type %Pair [symbolic = %pattern_type.loc9_22.2 (constants.%pattern_type.b6c)]
// CHECK:STDOUT:   %return.param_patt.loc9_22.2: @Pair.Both.%pattern_type.loc9_22.2 (%pattern_type.b6c) = out_param_pattern [symbolic = %return.param_patt.loc9_22.2 (constants.%return.param_patt.4f6)]
// CHECK:STDOUT:   %return.patt.loc9_22.2: @Pair.Both.%pattern_type.loc9_22.2 (%pattern_type.b6c) = return_slot_pattern %return.param_patt.loc9_22.2, %Pair [symbolic = %return.patt.loc9_22.2 (constants.%return.patt.8b5)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc9_22.1: <witness> = require_complete_type %T [symbolic = %require_complete.loc9_22.1 (constants.%require_complete.944)]
// CHECK:STDOUT:   %require_complete.loc9_22.2: <witness> = require_complete_type %Pair [symbolic = %require_complete.loc9_22.2 (constants.%require_complete.9bb)]
// CHECK:STDOUT:   %tuple.type: type = tuple_type (%T, %T) [symbolic = %tuple.type (constants.%tuple.type.07a)]
// CHECK:STDOUT:   %.loc9_22.8: type = custom_layout_type {size=0, align=0, .Both@0: @Pair.Both.%tuple.type (%tuple.type.07a)} [symbolic = %.loc9_22.8 (constants.%.d27)]
// CHECK:STDOUT:   %require_complete.loc9_22.3: <witness> = require_complete_type %tuple.type [symbolic = %require_complete.loc9_22.3 (constants.%require_complete.22a)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%_.param.loc9_22.1: @Pair.Both.%T (%T.67d), %_.param.loc9_22.2: @Pair.Both.%T (%T.67d)) -> out %return.param: @Pair.Both.%Pair (%Pair.66e) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %.loc9_22.1: ref %u1 = class_element_access %return.param, element0
// CHECK:STDOUT:     %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:     %impl.elem0: %.e60 = impl_witness_access constants.%ImplicitAs.impl_witness.9a9, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:     %bound_method.loc9_22.1: <bound method> = bound_method %int_0, %impl.elem0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:     %specific_fn: <specific function> = specific_function %impl.elem0, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:     %bound_method.loc9_22.2: <bound method> = bound_method %int_0, %specific_fn [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %u1 = call %bound_method.loc9_22.2(%int_0) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:     %.loc9_22.2: init %u1 = converted %int_0, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:     %.loc9_22.3: init %u1 to %.loc9_22.1 = in_place_init %.loc9_22.2 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:     %.loc9_22.4: ref @Pair.Both.%.loc9_22.8 (%.d27) = class_element_access %return.param, element1
// CHECK:STDOUT:     %.loc9_22.5: ref @Pair.Both.%tuple.type (%tuple.type.07a) = class_element_access %.loc9_22.4, element0
// CHECK:STDOUT:     %.loc10: @Pair.Both.%tuple.type (%tuple.type.07a) = tuple_literal (%_.param.loc9_22.1, %_.param.loc9_22.2)
// CHECK:STDOUT:     %.loc9_22.6: init @Pair.Both.%Pair (%Pair.66e) to %return.param = class_init (%.loc9_22.3, <error>) [concrete = <error>]
// CHECK:STDOUT:     return %.loc9_22.6 to %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Classify32(%p.param: %Pair.1ee) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %p.ref: %Pair.1ee = name_ref p, %p
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt: %pattern_type.b73 = expr_pattern %Neither.ref in [concrete] {
// CHECK:STDOUT:       %.loc16_10.2: %Pair.1ee = specific_constant @Pair.%.loc12_1.13, @Pair(constants.%i32) [concrete = constants.%Pair.val.6e7]
// CHECK:STDOUT:       %Neither.ref: %Pair.1ee = name_ref Neither, %.loc16_10.2 [concrete = constants.%Pair.val.6e7]
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %.loc16_10.1: %Pair.1ee = splice_block %Neither.ref [concrete = constants.%Pair.val.6e7] {
// CHECK:STDOUT:     %.loc16_10.2: %Pair.1ee = specific_constant @Pair.%.loc12_1.13, @Pair(constants.%i32) [concrete = constants.%Pair.val.6e7]
// CHECK:STDOUT:     %Neither.ref: %Pair.1ee = name_ref Neither, %.loc16_10.2 [concrete = constants.%Pair.val.6e7]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_1.loc16: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc16_19.1: %.e60 = impl_witness_access constants.%ImplicitAs.impl_witness.9a9, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc16_19.1: <bound method> = bound_method %int_1.loc16, %impl.elem0.loc16_19.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc16_19.1: <specific function> = specific_function %impl.elem0.loc16_19.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc16_19.2: <bound method> = bound_method %int_1.loc16, %specific_fn.loc16_19.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16_19: init %u1 = call %bound_method.loc16_19.2(%int_1.loc16) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc16_19.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16_19 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc16_19.2: %u1 = converted %int_1.loc16, %.loc16_19.1 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc16_19.3: ref %u1 = class_element_access %p.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc16_19.2: %.9ed = impl_witness_access constants.%EqWith.impl_witness.d63, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
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
// CHECK:STDOUT:   %impl.elem0.loc16_32: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc16_32.1: <bound method> = bound_method %int_0, %impl.elem0.loc16_32 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc16_32: <specific function> = specific_function %impl.elem0.loc16_32, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc16_32.2: <bound method> = bound_method %int_0, %specific_fn.loc16_32 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16_32: init %i32 = call %bound_method.loc16_32.2(%int_0) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc16_32: init %i32 = converted %int_0, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16_32 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   return %.loc16_32
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else:
// CHECK:STDOUT:   %int_1.loc17: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc17: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc17_26.1: <bound method> = bound_method %int_1.loc17, %impl.elem0.loc17 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc17: <specific function> = specific_function %impl.elem0.loc17, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc17_26.2: <bound method> = bound_method %int_1.loc17, %specific_fn.loc17 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc17: init %i32 = call %bound_method.loc17_26.2(%int_1.loc17) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc17: init %i32 = converted %int_1.loc17, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc17 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   return %.loc17
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Classify64(%p.param: %Pair.01a) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %p.ref: %Pair.01a = name_ref p, %p
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt: %pattern_type.fc3 = expr_pattern %Neither.ref in [concrete] {
// CHECK:STDOUT:       %.loc23_10.2: %Pair.01a = specific_constant @Pair.%.loc12_1.13, @Pair(constants.%i64) [concrete = constants.%Pair.val.765]
// CHECK:STDOUT:       %Neither.ref: %Pair.01a = name_ref Neither, %.loc23_10.2 [concrete = constants.%Pair.val.765]
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %.loc23_10.1: %Pair.01a = splice_block %Neither.ref [concrete = constants.%Pair.val.765] {
// CHECK:STDOUT:     %.loc23_10.2: %Pair.01a = specific_constant @Pair.%.loc12_1.13, @Pair(constants.%i64) [concrete = constants.%Pair.val.765]
// CHECK:STDOUT:     %Neither.ref: %Pair.01a = name_ref Neither, %.loc23_10.2 [concrete = constants.%Pair.val.765]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_1.loc23: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc23_19.1: %.e60 = impl_witness_access constants.%ImplicitAs.impl_witness.9a9, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc23_19.1: <bound method> = bound_method %int_1.loc23, %impl.elem0.loc23_19.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc23_19.1: <specific function> = specific_function %impl.elem0.loc23_19.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc23_19.2: <bound method> = bound_method %int_1.loc23, %specific_fn.loc23_19.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc23_19: init %u1 = call %bound_method.loc23_19.2(%int_1.loc23) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc23_19.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc23_19 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc23_19.2: %u1 = converted %int_1.loc23, %.loc23_19.1 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc23_19.3: ref %u1 = class_element_access %p.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc23_19.2: %.9ed = impl_witness_access constants.%EqWith.impl_witness.d63, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc23_19.3: <bound method> = bound_method %.loc23_19.2, %impl.elem0.loc23_19.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound]
// CHECK:STDOUT:   %specific_fn.loc23_19.2: <specific function> = specific_function %impl.elem0.loc23_19.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc23_19.4: <bound method> = bound_method %.loc23_19.2, %specific_fn.loc23_19.2 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc23_19.4: %u1 = acquire_value %.loc23_19.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call: init bool = call %bound_method.loc23_19.4(%.loc23_19.2, %.loc23_19.4)
// CHECK:STDOUT:   %.loc23_19.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call
// CHECK:STDOUT:   %.loc23_19.6: bool = converted %UInt.as.EqWith.impl.Equal.call, %.loc23_19.5
// CHECK:STDOUT:   if %.loc23_19.6 br !match.case.then else br !match.case.else
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then:
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc23_32: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc23_32.1: <bound method> = bound_method %int_0, %impl.elem0.loc23_32 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc23_32: <specific function> = specific_function %impl.elem0.loc23_32, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc23_32.2: <bound method> = bound_method %int_0, %specific_fn.loc23_32 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc23_32: init %i32 = call %bound_method.loc23_32.2(%int_0) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc23_32: init %i32 = converted %int_0, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc23_32 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   return %.loc23_32
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else:
// CHECK:STDOUT:   %int_1.loc24: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc24: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc24_26.1: <bound method> = bound_method %int_1.loc24, %impl.elem0.loc24 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc24: <specific function> = specific_function %impl.elem0.loc24, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc24_26.2: <bound method> = bound_method %int_1.loc24, %specific_fn.loc24 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc24: init %i32 = call %bound_method.loc24_26.2(%int_1.loc24) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc24: init %i32 = converted %int_1.loc24, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc24 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   return %.loc24
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Run() -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Pair.ref.loc32_22: %Pair.type = name_ref Pair, file.%Pair.decl [concrete = constants.%Pair.generic]
// CHECK:STDOUT:   %i32.loc32_27: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %Pair.loc32_30: type = class_type @Pair, @Pair(constants.%i32) [concrete = constants.%Pair.1ee]
// CHECK:STDOUT:   %.loc32_31: %Pair.Both.type.9d6 = specific_constant generated.%Pair.Both.decl, @Pair(constants.%i32) [concrete = constants.%Pair.Both.c82]
// CHECK:STDOUT:   %Both.ref.loc32: %Pair.Both.type.9d6 = name_ref Both, %.loc32_31 [concrete = constants.%Pair.Both.c82]
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %int_2.loc32: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:   %Pair.Both.specific_fn.loc32: <specific function> = specific_function %Both.ref.loc32, @Pair.Both(constants.%i32) [concrete = constants.%Pair.Both.specific_fn.212]
// CHECK:STDOUT:   %.loc32_41.1: ref %Pair.1ee = temporary_storage
// CHECK:STDOUT:   %impl.elem0.loc32_37: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc32_37.1: <bound method> = bound_method %int_1, %impl.elem0.loc32_37 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc32_37: <specific function> = specific_function %impl.elem0.loc32_37, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc32_37.2: <bound method> = bound_method %int_1, %specific_fn.loc32_37 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc32_37: init %i32 = call %bound_method.loc32_37.2(%int_1) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc32_37.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc32_37 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc32_37.2: %i32 = converted %int_1, %.loc32_37.1 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %impl.elem0.loc32_40: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc32_40.1: <bound method> = bound_method %int_2.loc32, %impl.elem0.loc32_40 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.9f3]
// CHECK:STDOUT:   %specific_fn.loc32_40: <specific function> = specific_function %impl.elem0.loc32_40, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc32_40.2: <bound method> = bound_method %int_2.loc32, %specific_fn.loc32_40 [concrete = constants.%bound_method.3cb]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc32_40: init %i32 = call %bound_method.loc32_40.2(%int_2.loc32) [concrete = constants.%int_2.295]
// CHECK:STDOUT:   %.loc32_40.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc32_40 [concrete = constants.%int_2.295]
// CHECK:STDOUT:   %.loc32_40.2: %i32 = converted %int_2.loc32, %.loc32_40.1 [concrete = constants.%int_2.295]
// CHECK:STDOUT:   %Pair.Both.call.loc32: init %Pair.66e to %.loc32_41.1 = call %Pair.Both.specific_fn.loc32(%.loc32_37.2, %.loc32_40.2)
// CHECK:STDOUT:   %.loc32_41.2: %Pair.1ee = converted %Pair.Both.call.loc32, <error> [concrete = <error>]
// CHECK:STDOUT:   %.loc32_18: type = splice_block %Pair.loc32_18 [concrete = constants.%Pair.1ee] {
// CHECK:STDOUT:     %Pair.ref.loc32_10: %Pair.type = name_ref Pair, file.%Pair.decl [concrete = constants.%Pair.generic]
// CHECK:STDOUT:     %i32.loc32_15: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %Pair.loc32_18: type = class_type @Pair, @Pair(constants.%i32) [concrete = constants.%Pair.1ee]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %a: %Pair.1ee = wrapper_binding a, <error> [concrete = <error>]
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %a.patt: %pattern_type.b73 = value_binding_pattern a [concrete = constants.%a.patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Pair.ref.loc33_22: %Pair.type = name_ref Pair, file.%Pair.decl [concrete = constants.%Pair.generic]
// CHECK:STDOUT:   %i64.loc33_27: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:   %Pair.loc33_30: type = class_type @Pair, @Pair(constants.%i64) [concrete = constants.%Pair.01a]
// CHECK:STDOUT:   %.loc33_31: %Pair.Both.type.1a5 = specific_constant generated.%Pair.Both.decl, @Pair(constants.%i64) [concrete = constants.%Pair.Both.56a]
// CHECK:STDOUT:   %Both.ref.loc33: %Pair.Both.type.1a5 = name_ref Both, %.loc33_31 [concrete = constants.%Pair.Both.56a]
// CHECK:STDOUT:   %int_3: Core.IntLiteral = int_value 3 [concrete = constants.%int_3.1ba]
// CHECK:STDOUT:   %int_4: Core.IntLiteral = int_value 4 [concrete = constants.%int_4.0c1]
// CHECK:STDOUT:   %Pair.Both.specific_fn.loc33: <specific function> = specific_function %Both.ref.loc33, @Pair.Both(constants.%i64) [concrete = constants.%Pair.Both.specific_fn.471]
// CHECK:STDOUT:   %.loc33_41.1: ref %Pair.01a = temporary_storage
// CHECK:STDOUT:   %impl.elem0.loc33_37: %.f349 = impl_witness_access constants.%ImplicitAs.impl_witness.091, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b]
// CHECK:STDOUT:   %bound_method.loc33_37.1: <bound method> = bound_method %int_3, %impl.elem0.loc33_37 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.e9c]
// CHECK:STDOUT:   %specific_fn.loc33_37: <specific function> = specific_function %impl.elem0.loc33_37, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.f33]
// CHECK:STDOUT:   %bound_method.loc33_37.2: <bound method> = bound_method %int_3, %specific_fn.loc33_37 [concrete = constants.%bound_method.740]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc33_37: init %i64 = call %bound_method.loc33_37.2(%int_3) [concrete = constants.%int_3.bd2]
// CHECK:STDOUT:   %.loc33_37.1: %i64 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc33_37 [concrete = constants.%int_3.bd2]
// CHECK:STDOUT:   %.loc33_37.2: %i64 = converted %int_3, %.loc33_37.1 [concrete = constants.%int_3.bd2]
// CHECK:STDOUT:   %impl.elem0.loc33_40: %.f349 = impl_witness_access constants.%ImplicitAs.impl_witness.091, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b]
// CHECK:STDOUT:   %bound_method.loc33_40.1: <bound method> = bound_method %int_4, %impl.elem0.loc33_40 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.b50]
// CHECK:STDOUT:   %specific_fn.loc33_40: <specific function> = specific_function %impl.elem0.loc33_40, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.f33]
// CHECK:STDOUT:   %bound_method.loc33_40.2: <bound method> = bound_method %int_4, %specific_fn.loc33_40 [concrete = constants.%bound_method.912]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc33_40: init %i64 = call %bound_method.loc33_40.2(%int_4) [concrete = constants.%int_4.825]
// CHECK:STDOUT:   %.loc33_40.1: %i64 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc33_40 [concrete = constants.%int_4.825]
// CHECK:STDOUT:   %.loc33_40.2: %i64 = converted %int_4, %.loc33_40.1 [concrete = constants.%int_4.825]
// CHECK:STDOUT:   %Pair.Both.call.loc33: init %Pair.66e to %.loc33_41.1 = call %Pair.Both.specific_fn.loc33(%.loc33_37.2, %.loc33_40.2)
// CHECK:STDOUT:   %.loc33_41.2: %Pair.01a = converted %Pair.Both.call.loc33, <error> [concrete = <error>]
// CHECK:STDOUT:   %.loc33_18: type = splice_block %Pair.loc33_18 [concrete = constants.%Pair.01a] {
// CHECK:STDOUT:     %Pair.ref.loc33_10: %Pair.type = name_ref Pair, file.%Pair.decl [concrete = constants.%Pair.generic]
// CHECK:STDOUT:     %i64.loc33_15: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:     %Pair.loc33_18: type = class_type @Pair, @Pair(constants.%i64) [concrete = constants.%Pair.01a]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %b: %Pair.01a = wrapper_binding b, <error> [concrete = <error>]
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %b.patt: %pattern_type.fc3 = value_binding_pattern b [concrete = constants.%b.patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Classify32.ref: %Classify32.type = name_ref Classify32, file.%Classify32.decl [concrete = constants.%Classify32]
// CHECK:STDOUT:   %a.ref: %Pair.1ee = name_ref a, %a [concrete = <error>]
// CHECK:STDOUT:   %Classify32.call: init %i32 = call %Classify32.ref(<error>)
// CHECK:STDOUT:   %Classify64.ref: %Classify64.type = name_ref Classify64, file.%Classify64.decl [concrete = constants.%Classify64]
// CHECK:STDOUT:   %b.ref: %Pair.01a = name_ref b, %b [concrete = <error>]
// CHECK:STDOUT:   %Classify64.call: init %i32 = call %Classify64.ref(<error>)
// CHECK:STDOUT:   %impl.elem1.loc34_24: %.516 = impl_witness_access constants.%AddWith.impl_witness.3af, element1 [concrete = constants.%Int.as.AddWith.impl.Op.365]
// CHECK:STDOUT:   %bound_method.loc34_24.1: <bound method> = bound_method %Classify32.call, %impl.elem1.loc34_24
// CHECK:STDOUT:   %specific_fn.loc34_24: <specific function> = specific_function %impl.elem1.loc34_24, @Int.as.AddWith.impl.Op.1(constants.%int_32) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.f25]
// CHECK:STDOUT:   %bound_method.loc34_24.2: <bound method> = bound_method %Classify32.call, %specific_fn.loc34_24
// CHECK:STDOUT:   %.loc34_22.1: %i32 = value_of_initializer %Classify32.call
// CHECK:STDOUT:   %.loc34_22.2: %i32 = converted %Classify32.call, %.loc34_22.1
// CHECK:STDOUT:   %.loc34_38.1: %i32 = value_of_initializer %Classify64.call
// CHECK:STDOUT:   %.loc34_38.2: %i32 = converted %Classify64.call, %.loc34_38.1
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call: init %i32 = call %bound_method.loc34_24.2(%.loc34_22.2, %.loc34_38.2)
// CHECK:STDOUT:   %int_2.loc34: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:   %impl.elem1.loc34_40: %.e15 = impl_witness_access constants.%SubWith.impl_witness.d78, element1 [concrete = constants.%Int.as.SubWith.impl.Op.49baee.2]
// CHECK:STDOUT:   %bound_method.loc34_40.1: <bound method> = bound_method %Int.as.AddWith.impl.Op.call, %impl.elem1.loc34_40
// CHECK:STDOUT:   %specific_fn.loc34_40: <specific function> = specific_function %impl.elem1.loc34_40, @Int.as.SubWith.impl.Op.2(constants.%int_32, constants.%ImplicitAs.facet.9f1) [concrete = constants.%Int.as.SubWith.impl.Op.specific_fn.4cc768.1]
// CHECK:STDOUT:   %bound_method.loc34_40.2: <bound method> = bound_method %Int.as.AddWith.impl.Op.call, %specific_fn.loc34_40
// CHECK:STDOUT:   %.loc34_24.1: %i32 = value_of_initializer %Int.as.AddWith.impl.Op.call
// CHECK:STDOUT:   %.loc34_24.2: %i32 = converted %Int.as.AddWith.impl.Op.call, %.loc34_24.1
// CHECK:STDOUT:   %.loc34_40: %Int.as.SubWith.impl.Op.type.745d60.1 = specific_constant imports.%Core.Op.9ff, @Int.as.SubWith.impl.dc8(constants.%int_32, constants.%ImplicitAs.facet.9f1) [concrete = constants.%Int.as.SubWith.impl.Op.49baee.1]
// CHECK:STDOUT:   %Op.ref: %Int.as.SubWith.impl.Op.type.745d60.1 = name_ref Op, %.loc34_40 [concrete = constants.%Int.as.SubWith.impl.Op.49baee.1]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.bound: <bound method> = bound_method %.loc34_24.2, %Op.ref
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.specific_fn: <specific function> = specific_function %Op.ref, @Int.as.SubWith.impl.Op.3(constants.%int_32, constants.%ImplicitAs.facet.9f1) [concrete = constants.%Int.as.SubWith.impl.Op.specific_fn.4cc768.2]
// CHECK:STDOUT:   %bound_method.loc34_40.3: <bound method> = bound_method %.loc34_24.2, %Int.as.SubWith.impl.Op.specific_fn
// CHECK:STDOUT:   %impl.elem0.loc34: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc34_42.1: <bound method> = bound_method %int_2.loc34, %impl.elem0.loc34 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.9f3]
// CHECK:STDOUT:   %specific_fn.loc34_42: <specific function> = specific_function %impl.elem0.loc34, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc34_42.2: <bound method> = bound_method %int_2.loc34, %specific_fn.loc34_42 [concrete = constants.%bound_method.3cb]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc34: init %i32 = call %bound_method.loc34_42.2(%int_2.loc34) [concrete = constants.%int_2.295]
// CHECK:STDOUT:   %.loc34_42.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc34 [concrete = constants.%int_2.295]
// CHECK:STDOUT:   %.loc34_42.2: %i32 = converted %int_2.loc34, %.loc34_42.1 [concrete = constants.%int_2.295]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.call: init %i32 = call %bound_method.loc34_40.3(%.loc34_24.2, %.loc34_42.2)
// CHECK:STDOUT:   return %Int.as.SubWith.impl.Op.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Pair(constants.%T.67d) {
// CHECK:STDOUT:   %T.patt.loc9_14.2 => constants.%T.patt.d47
// CHECK:STDOUT:   %T.loc9_14.1 => constants.%T.67d
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.51d1c4.1
// CHECK:STDOUT:   %x.param_patt => constants.%x.param_patt.91d
// CHECK:STDOUT:   %x.patt => constants.%x.patt.800
// CHECK:STDOUT:   %y.param_patt => constants.%y.param_patt.be3
// CHECK:STDOUT:   %y.patt => constants.%y.patt.b85
// CHECK:STDOUT:   %require_complete.loc10 => constants.%require_complete.944
// CHECK:STDOUT:   %tuple.type => constants.%tuple.type.07a
// CHECK:STDOUT:   %.loc12_1.14 => constants.%.d27
// CHECK:STDOUT:   %struct_type.discriminant.payload => constants.%struct_type.discriminant.payload.1ec
// CHECK:STDOUT:   %complete_type.loc12_1.2 => constants.%complete_type.d2c
// CHECK:STDOUT:   %Pair.Both.type => constants.%Pair.Both.type.9e9
// CHECK:STDOUT:   %Pair.Both => constants.%Pair.Both.4cf
// CHECK:STDOUT:   %Pair => constants.%Pair.66e
// CHECK:STDOUT:   %require_complete.loc12 => constants.%require_complete.9bb
// CHECK:STDOUT:   %uninit.loc12_1.2 => constants.%uninit.216
// CHECK:STDOUT:   %Pair.val => constants.%Pair.val.0a4
// CHECK:STDOUT:   %.loc12_1.15 => constants.%.f95
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Pair.Both(constants.%T.67d) {
// CHECK:STDOUT:   %T => constants.%T.67d
// CHECK:STDOUT:   %pattern_type.loc9_22.1 => constants.%pattern_type.51d1c4.1
// CHECK:STDOUT:   %_.param_patt.loc9_22.3 => constants.%_.param_patt.339
// CHECK:STDOUT:   %_.patt.loc9_22.3 => constants.%_.patt.fd3
// CHECK:STDOUT:   %Pair => constants.%Pair.66e
// CHECK:STDOUT:   %.loc9_22.7 => constants.%.f65
// CHECK:STDOUT:   %pattern_type.loc9_22.2 => constants.%pattern_type.b6c
// CHECK:STDOUT:   %return.param_patt.loc9_22.2 => constants.%return.param_patt.4f6
// CHECK:STDOUT:   %return.patt.loc9_22.2 => constants.%return.patt.8b5
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Pair(constants.%i32) {
// CHECK:STDOUT:   %T.patt.loc9_14.2 => constants.%T.patt.d47
// CHECK:STDOUT:   %T.loc9_14.1 => constants.%i32
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.6b6
// CHECK:STDOUT:   %x.param_patt => constants.%x.param_patt.cee
// CHECK:STDOUT:   %x.patt => constants.%x.patt.fbe
// CHECK:STDOUT:   %y.param_patt => constants.%y.param_patt.673
// CHECK:STDOUT:   %y.patt => constants.%y.patt.b43
// CHECK:STDOUT:   %require_complete.loc10 => constants.%complete_type.f8a
// CHECK:STDOUT:   %tuple.type => constants.%tuple.type.e55
// CHECK:STDOUT:   %.loc12_1.14 => constants.%.20c
// CHECK:STDOUT:   %struct_type.discriminant.payload => constants.%struct_type.discriminant.payload.92c
// CHECK:STDOUT:   %complete_type.loc12_1.2 => constants.%complete_type.ea6
// CHECK:STDOUT:   %Pair.Both.type => constants.%Pair.Both.type.9d6
// CHECK:STDOUT:   %Pair.Both => constants.%Pair.Both.c82
// CHECK:STDOUT:   %Pair => constants.%Pair.1ee
// CHECK:STDOUT:   %require_complete.loc12 => constants.%complete_type.ea6
// CHECK:STDOUT:   %uninit.loc12_1.2 => constants.%uninit.525
// CHECK:STDOUT:   %Pair.val => constants.%Pair.val.6e7
// CHECK:STDOUT:   %.loc12_1.15 => constants.%.343
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Pair(constants.%i64) {
// CHECK:STDOUT:   %T.patt.loc9_14.2 => constants.%T.patt.d47
// CHECK:STDOUT:   %T.loc9_14.1 => constants.%i64
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.f57
// CHECK:STDOUT:   %x.param_patt => constants.%x.param_patt.7b8
// CHECK:STDOUT:   %x.patt => constants.%x.patt.451
// CHECK:STDOUT:   %y.param_patt => constants.%y.param_patt.83d
// CHECK:STDOUT:   %y.patt => constants.%y.patt.d31
// CHECK:STDOUT:   %require_complete.loc10 => constants.%complete_type.4a1
// CHECK:STDOUT:   %tuple.type => constants.%tuple.type.1ac
// CHECK:STDOUT:   %.loc12_1.14 => constants.%.58e
// CHECK:STDOUT:   %struct_type.discriminant.payload => constants.%struct_type.discriminant.payload.8ac
// CHECK:STDOUT:   %complete_type.loc12_1.2 => constants.%complete_type.ab0
// CHECK:STDOUT:   %Pair.Both.type => constants.%Pair.Both.type.1a5
// CHECK:STDOUT:   %Pair.Both => constants.%Pair.Both.56a
// CHECK:STDOUT:   %Pair => constants.%Pair.01a
// CHECK:STDOUT:   %require_complete.loc12 => constants.%complete_type.ab0
// CHECK:STDOUT:   %uninit.loc12_1.2 => constants.%uninit.ccc
// CHECK:STDOUT:   %Pair.val => constants.%Pair.val.765
// CHECK:STDOUT:   %.loc12_1.15 => constants.%.4a7
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Pair.Both(constants.%i32) {
// CHECK:STDOUT:   %T => constants.%i32
// CHECK:STDOUT:   %pattern_type.loc9_22.1 => constants.%pattern_type.6b6
// CHECK:STDOUT:   %_.param_patt.loc9_22.3 => constants.%_.param_patt.fb2
// CHECK:STDOUT:   %_.patt.loc9_22.3 => constants.%_.patt.b75
// CHECK:STDOUT:   %Pair => constants.%Pair.1ee
// CHECK:STDOUT:   %.loc9_22.7 => constants.%.b22
// CHECK:STDOUT:   %pattern_type.loc9_22.2 => constants.%pattern_type.b73
// CHECK:STDOUT:   %return.param_patt.loc9_22.2 => constants.%return.param_patt.7fa
// CHECK:STDOUT:   %return.patt.loc9_22.2 => constants.%return.patt.52d
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc9_22.1 => constants.%complete_type.f8a
// CHECK:STDOUT:   %require_complete.loc9_22.2 => constants.%complete_type.ea6
// CHECK:STDOUT:   %tuple.type => constants.%tuple.type.e55
// CHECK:STDOUT:   %.loc9_22.8 => constants.%.20c
// CHECK:STDOUT:   %require_complete.loc9_22.3 => constants.%complete_type.6c4
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Pair.Both(constants.%i64) {
// CHECK:STDOUT:   %T => constants.%i64
// CHECK:STDOUT:   %pattern_type.loc9_22.1 => constants.%pattern_type.f57
// CHECK:STDOUT:   %_.param_patt.loc9_22.3 => constants.%_.param_patt.2f0
// CHECK:STDOUT:   %_.patt.loc9_22.3 => constants.%_.patt.233
// CHECK:STDOUT:   %Pair => constants.%Pair.01a
// CHECK:STDOUT:   %.loc9_22.7 => constants.%.02d
// CHECK:STDOUT:   %pattern_type.loc9_22.2 => constants.%pattern_type.fc3
// CHECK:STDOUT:   %return.param_patt.loc9_22.2 => constants.%return.param_patt.fa2
// CHECK:STDOUT:   %return.patt.loc9_22.2 => constants.%return.patt.c93
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc9_22.1 => constants.%complete_type.4a1
// CHECK:STDOUT:   %require_complete.loc9_22.2 => constants.%complete_type.ab0
// CHECK:STDOUT:   %tuple.type => constants.%tuple.type.1ac
// CHECK:STDOUT:   %.loc9_22.8 => constants.%.58e
// CHECK:STDOUT:   %require_complete.loc9_22.3 => constants.%complete_type.3d3
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
// CHECK:STDOUT:   %M.type: type = generic_class_type @M [concrete]
// CHECK:STDOUT:   %M.generic: %M.type = struct_value () [concrete]
// CHECK:STDOUT:   %M.a09: type = class_type @M, @M(%T.67d) [symbolic]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %Int.67af24.1: type = class_type @Int, @Int(%N) [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.51d1c4.1: type = pattern_type %T.67d [symbolic]
// CHECK:STDOUT:   %x.param_patt.91d: %pattern_type.51d1c4.1 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %x.patt.800: %pattern_type.51d1c4.1 = at_binding_pattern x, %x.param_patt.91d [symbolic]
// CHECK:STDOUT:   %y.param_patt.be3: %pattern_type.51d1c4.1 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %y.patt.b85: %pattern_type.51d1c4.1 = at_binding_pattern y, %y.param_patt.be3 [symbolic]
// CHECK:STDOUT:   %int_2.ecc: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %u2: type = class_type @UInt, @UInt(%int_2.ecc) [concrete]
// CHECK:STDOUT:   %tuple.type.a8a: type = tuple_type (%i32) [concrete]
// CHECK:STDOUT:   %require_complete.944: <witness> = require_complete_type %T.67d [symbolic]
// CHECK:STDOUT:   %tuple.type.07a: type = tuple_type (%T.67d, %T.67d) [symbolic]
// CHECK:STDOUT:   %.94d: type = custom_layout_type {size=0, align=0, .Small@0: %tuple.type.a8a, .Big@0: %tuple.type.07a} [symbolic]
// CHECK:STDOUT:   %struct_type.discriminant.payload.865: type = struct_type {.discriminant: %u2, .payload: %.94d} [symbolic]
// CHECK:STDOUT:   %complete_type.c6f: <witness> = complete_type_witness %struct_type.discriminant.payload.865 [symbolic]
// CHECK:STDOUT:   %struct_type.discriminant: type = struct_type {.discriminant: %u2} [concrete]
// CHECK:STDOUT:   %_.param_patt.fb2: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %_.patt.b75: %pattern_type.6b6 = at_binding_pattern _, %_.param_patt.fb2 [concrete]
// CHECK:STDOUT:   %.2eb: Core.Form = init_form %M.a09 [symbolic]
// CHECK:STDOUT:   %pattern_type.161: type = pattern_type %M.a09 [symbolic]
// CHECK:STDOUT:   %return.param_patt.9bc: %pattern_type.161 = out_param_pattern [symbolic]
// CHECK:STDOUT:   %return.patt.1f2: %pattern_type.161 = return_slot_pattern %return.param_patt.9bc, %M.a09 [symbolic]
// CHECK:STDOUT:   %M.Small.type.e5f: type = fn_type @M.Small, @M(%T.67d) [symbolic]
// CHECK:STDOUT:   %M.Small.c29: %M.Small.type.e5f = struct_value () [symbolic]
// CHECK:STDOUT:   %require_complete.cae: <witness> = require_complete_type %M.a09 [symbolic]
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
// CHECK:STDOUT:   %_.param_patt.339: %pattern_type.51d1c4.1 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %_.patt.fd3: %pattern_type.51d1c4.1 = at_binding_pattern _, %_.param_patt.339 [symbolic]
// CHECK:STDOUT:   %M.Big.type.702: type = fn_type @M.Big, @M(%T.67d) [symbolic]
// CHECK:STDOUT:   %M.Big.566: %M.Big.type.702 = struct_value () [symbolic]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.48e: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.409 [concrete]
// CHECK:STDOUT:   %bound_method.0f5: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.a72 [concrete]
// CHECK:STDOUT:   %int_1.508: %u2 = int_value 1 [concrete]
// CHECK:STDOUT:   %require_complete.22a: <witness> = require_complete_type %tuple.type.07a [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.6c9: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.409 [concrete]
// CHECK:STDOUT:   %bound_method.135: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.a72 [concrete]
// CHECK:STDOUT:   %int_2.996: %u2 = int_value 2 [concrete]
// CHECK:STDOUT:   %struct: %struct_type.discriminant = struct_value (%int_2.996) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.type.0c5: type = fn_type @UInt.as.Copy.impl.Op, @UInt.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.38a: %UInt.as.Copy.impl.Op.type.0c5 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.f92: <witness> = impl_witness imports.%Copy.impl_witness_table.fe3, @UInt.as.Copy.impl(%int_2.ecc) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.type.d68: type = fn_type @UInt.as.Copy.impl.Op, @UInt.as.Copy.impl(%int_2.ecc) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.4d1: %UInt.as.Copy.impl.Op.type.d68 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet.842: %Copy.type = facet_value %u2, (%Copy.impl_witness.f92) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.21e: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.842) [concrete]
// CHECK:STDOUT:   %.594: type = fn_type_with_self_type %Copy.WithSelf.Op.type.21e, %Copy.facet.842 [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.bound: <bound method> = bound_method %int_2.996, %UInt.as.Copy.impl.Op.4d1 [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %UInt.as.Copy.impl.Op.4d1, @UInt.as.Copy.impl.Op(%int_2.ecc) [concrete]
// CHECK:STDOUT:   %bound_method.f90: <bound method> = bound_method %int_2.996, %UInt.as.Copy.impl.Op.specific_fn [concrete]
// CHECK:STDOUT:   %uninit.c79: %.94d = uninitialized_value [symbolic]
// CHECK:STDOUT:   %M.val.c49: %M.a09 = struct_value (%int_2.996, %uninit.c79) [symbolic]
// CHECK:STDOUT:   %.fd4: ref %M.a09 = temporary invalid, %M.val.c49 [symbolic]
// CHECK:STDOUT:   %int_8: Core.IntLiteral = int_value 8 [concrete]
// CHECK:STDOUT:   %i8: type = class_type @Int, @Int(%int_8) [concrete]
// CHECK:STDOUT:   %M.d77: type = class_type @M, @M(%i8) [concrete]
// CHECK:STDOUT:   %pattern_type.134: type = pattern_type %M.d77 [concrete]
// CHECK:STDOUT:   %m.param_patt.cb3: %pattern_type.134 = value_param_pattern [concrete]
// CHECK:STDOUT:   %m.patt.0cc: %pattern_type.134 = at_binding_pattern m, %m.param_patt.cb3 [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %F8.type: type = fn_type @F8 [concrete]
// CHECK:STDOUT:   %F8: %F8.type = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.0cf: type = pattern_type %i8 [concrete]
// CHECK:STDOUT:   %x.param_patt.c89: %pattern_type.0cf = value_param_pattern [concrete]
// CHECK:STDOUT:   %x.patt.9fb: %pattern_type.0cf = at_binding_pattern x, %x.param_patt.c89 [concrete]
// CHECK:STDOUT:   %y.param_patt.9a0: %pattern_type.0cf = value_param_pattern [concrete]
// CHECK:STDOUT:   %y.patt.b9f: %pattern_type.0cf = at_binding_pattern y, %y.param_patt.9a0 [concrete]
// CHECK:STDOUT:   %i8.builtin: type = int_type signed, %int_8 [concrete]
// CHECK:STDOUT:   %complete_type.58c: <witness> = complete_type_witness %i8.builtin [concrete]
// CHECK:STDOUT:   %tuple.type.f88: type = tuple_type (%i8, %i8) [concrete]
// CHECK:STDOUT:   %.c87: type = custom_layout_type {size=4, align=4, .Small@0: %tuple.type.a8a, .Big@0: %tuple.type.f88} [concrete]
// CHECK:STDOUT:   %struct_type.discriminant.payload.59d: type = struct_type {.discriminant: %u2, .payload: %.c87} [concrete]
// CHECK:STDOUT:   %complete_type.27a: <witness> = complete_type_witness %struct_type.discriminant.payload.59d [concrete]
// CHECK:STDOUT:   %M.Small.type.b1f: type = fn_type @M.Small, @M(%i8) [concrete]
// CHECK:STDOUT:   %M.Small.afb: %M.Small.type.b1f = struct_value () [concrete]
// CHECK:STDOUT:   %M.Big.type.848: type = fn_type @M.Big, @M(%i8) [concrete]
// CHECK:STDOUT:   %M.Big.87b: %M.Big.type.848 = struct_value () [concrete]
// CHECK:STDOUT:   %uninit.b30: %.c87 = uninitialized_value [concrete]
// CHECK:STDOUT:   %M.val.de4: %M.d77 = struct_value (%int_2.996, %uninit.b30) [concrete]
// CHECK:STDOUT:   %.f27: ref %M.d77 = temporary invalid, %M.val.de4 [concrete]
// CHECK:STDOUT:   %EqWith.type.f24: type = facet_type <@EqWith, @EqWith(%u2)> [concrete]
// CHECK:STDOUT:   %M.d23: Core.IntLiteral = symbolic_binding M, 1 [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.544: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%N, %M.d23) [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.c67: %UInt.as.EqWith.impl.Equal.type.544 = struct_value () [symbolic]
// CHECK:STDOUT:   %EqWith.impl_witness.454: <witness> = impl_witness imports.%EqWith.impl_witness_table.cbd, @UInt.as.EqWith.impl.f13(%int_2.ecc, %int_2.ecc) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.5fc: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%int_2.ecc, %int_2.ecc) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.e76: %UInt.as.EqWith.impl.Equal.type.5fc = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.16f: %EqWith.type.f24 = facet_value %u2, (%EqWith.impl_witness.454) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.c65: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%u2, %EqWith.facet.16f) [concrete]
// CHECK:STDOUT:   %.7a0: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.c65, %EqWith.facet.16f [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound: <bound method> = bound_method %int_2.996, %UInt.as.EqWith.impl.Equal.e76 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.specific_fn.149: <specific function> = specific_function %UInt.as.EqWith.impl.Equal.e76, @UInt.as.EqWith.impl.Equal.1(%int_2.ecc, %int_2.ecc) [concrete]
// CHECK:STDOUT:   %bound_method.64f: <bound method> = bound_method %int_2.996, %UInt.as.EqWith.impl.Equal.specific_fn.149 [concrete]
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
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.953: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %M.6b7: type = class_type @M, @M(%i64) [concrete]
// CHECK:STDOUT:   %pattern_type.e57: type = pattern_type %M.6b7 [concrete]
// CHECK:STDOUT:   %m.param_patt.762: %pattern_type.e57 = value_param_pattern [concrete]
// CHECK:STDOUT:   %m.patt.a07: %pattern_type.e57 = at_binding_pattern m, %m.param_patt.762 [concrete]
// CHECK:STDOUT:   %F64.type: type = fn_type @F64 [concrete]
// CHECK:STDOUT:   %F64: %F64.type = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.f57: type = pattern_type %i64 [concrete]
// CHECK:STDOUT:   %x.param_patt.7b8: %pattern_type.f57 = value_param_pattern [concrete]
// CHECK:STDOUT:   %x.patt.451: %pattern_type.f57 = at_binding_pattern x, %x.param_patt.7b8 [concrete]
// CHECK:STDOUT:   %y.param_patt.83d: %pattern_type.f57 = value_param_pattern [concrete]
// CHECK:STDOUT:   %y.patt.d31: %pattern_type.f57 = at_binding_pattern y, %y.param_patt.83d [concrete]
// CHECK:STDOUT:   %i64.builtin: type = int_type signed, %int_64 [concrete]
// CHECK:STDOUT:   %complete_type.4a1: <witness> = complete_type_witness %i64.builtin [concrete]
// CHECK:STDOUT:   %tuple.type.1ac: type = tuple_type (%i64, %i64) [concrete]
// CHECK:STDOUT:   %.050: type = custom_layout_type {size=16, align=8, .Small@0: %tuple.type.a8a, .Big@0: %tuple.type.1ac} [concrete]
// CHECK:STDOUT:   %struct_type.discriminant.payload.764: type = struct_type {.discriminant: %u2, .payload: %.050} [concrete]
// CHECK:STDOUT:   %complete_type.90c: <witness> = complete_type_witness %struct_type.discriminant.payload.764 [concrete]
// CHECK:STDOUT:   %M.Small.type.22f: type = fn_type @M.Small, @M(%i64) [concrete]
// CHECK:STDOUT:   %M.Small.0ed: %M.Small.type.22f = struct_value () [concrete]
// CHECK:STDOUT:   %M.Big.type.50c: type = fn_type @M.Big, @M(%i64) [concrete]
// CHECK:STDOUT:   %M.Big.8b3: %M.Big.type.50c = struct_value () [concrete]
// CHECK:STDOUT:   %uninit.8ce: %.050 = uninitialized_value [concrete]
// CHECK:STDOUT:   %M.val.7cc: %M.6b7 = struct_value (%int_2.996, %uninit.8ce) [concrete]
// CHECK:STDOUT:   %.10f: ref %M.6b7 = temporary invalid, %M.val.7cc [concrete]
// CHECK:STDOUT:   %Run.type: type = fn_type @Run [concrete]
// CHECK:STDOUT:   %Run: %Run.type = struct_value () [concrete]
// CHECK:STDOUT:   %s.patt: %pattern_type.134 = value_binding_pattern s [concrete]
// CHECK:STDOUT:   %.3fb: Core.Form = init_form %M.d77 [concrete]
// CHECK:STDOUT:   %return.param_patt.2a6: %pattern_type.134 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.28a: %pattern_type.134 = return_slot_pattern %return.param_patt.2a6, %M.d77 [concrete]
// CHECK:STDOUT:   %M.Small.specific_fn: <specific function> = specific_function %M.Small.afb, @M.Small(%i8) [concrete]
// CHECK:STDOUT:   %b.patt: %pattern_type.e57 = value_binding_pattern b [concrete]
// CHECK:STDOUT:   %int_3.1ba: Core.IntLiteral = int_value 3 [concrete]
// CHECK:STDOUT:   %int_4.0c1: Core.IntLiteral = int_value 4 [concrete]
// CHECK:STDOUT:   %_.param_patt.2f0: %pattern_type.f57 = value_param_pattern [concrete]
// CHECK:STDOUT:   %_.patt.233: %pattern_type.f57 = at_binding_pattern _, %_.param_patt.2f0 [concrete]
// CHECK:STDOUT:   %.af2: Core.Form = init_form %M.6b7 [concrete]
// CHECK:STDOUT:   %return.param_patt.0b0: %pattern_type.e57 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.b25: %pattern_type.e57 = return_slot_pattern %return.param_patt.0b0, %M.6b7 [concrete]
// CHECK:STDOUT:   %M.Big.specific_fn: <specific function> = specific_function %M.Big.8b3, @M.Big(%i64) [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.221: type = facet_type <@ImplicitAs, @ImplicitAs(%i64)> [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.091: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.b3c, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_64) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.55a: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_64) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.55a = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.6e8: %ImplicitAs.type.221 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.091) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.a04: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i64, %ImplicitAs.facet.6e8) [concrete]
// CHECK:STDOUT:   %.f349: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.a04, %ImplicitAs.facet.6e8 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.e9c: <bound method> = bound_method %int_3.1ba, %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.f33: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(%int_64) [concrete]
// CHECK:STDOUT:   %bound_method.740: <bound method> = bound_method %int_3.1ba, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.f33 [concrete]
// CHECK:STDOUT:   %int_3.bd2: %i64 = int_value 3 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.b50: <bound method> = bound_method %int_4.0c1, %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b [concrete]
// CHECK:STDOUT:   %bound_method.912: <bound method> = bound_method %int_4.0c1, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.f33 [concrete]
// CHECK:STDOUT:   %int_4.825: %i64 = int_value 4 [concrete]
// CHECK:STDOUT:   %AddWith.type.be9: type = facet_type <@AddWith, @AddWith(%i32)> [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.610: type = fn_type @Int.as.AddWith.impl.Op.1, @Int.as.AddWith.impl.3af(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.732: %Int.as.AddWith.impl.Op.type.610 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.type.f7de31.2: type = facet_type <@ImplicitAs, @ImplicitAs(%Int.67af24.1)> [symbolic]
// CHECK:STDOUT:   %U.4e6: %ImplicitAs.type.f7de31.2 = symbolic_binding U, 1 [symbolic]
// CHECK:STDOUT:   %AddWith.impl_witness.3af: <witness> = impl_witness imports.%AddWith.impl_witness_table.9d9, @Int.as.AddWith.impl.3af(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.056: type = fn_type @Int.as.AddWith.impl.Op.1, @Int.as.AddWith.impl.3af(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.365: %Int.as.AddWith.impl.Op.type.056 = struct_value () [concrete]
// CHECK:STDOUT:   %AddWith.facet.b8a: %AddWith.type.be9 = facet_value %i32, (%AddWith.impl_witness.3af) [concrete]
// CHECK:STDOUT:   %AddWith.WithSelf.Op.type.e15: type = fn_type @AddWith.WithSelf.Op, @AddWith.WithSelf(%i32, %AddWith.facet.b8a) [concrete]
// CHECK:STDOUT:   %.516: type = fn_type_with_self_type %AddWith.WithSelf.Op.type.e15, %AddWith.facet.b8a [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.specific_fn.f25: <specific function> = specific_function %Int.as.AddWith.impl.Op.365, @Int.as.AddWith.impl.Op.1(%int_32) [concrete]
// CHECK:STDOUT:   %SubWith.type.4c2: type = facet_type <@SubWith, @SubWith(Core.IntLiteral)> [concrete]
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
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.9f3: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.3cb: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_2.295: %i32 = int_value 2 [concrete]
// CHECK:STDOUT:   %complete_type.3d3: <witness> = complete_type_witness %tuple.type.1ac [concrete]
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
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.b3c = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.b4fd3a.1 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.6842: @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op.type (%Int.as.AddWith.impl.Op.type.610) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op (constants.%Int.as.AddWith.impl.Op.732)]
// CHECK:STDOUT:   %AddWith.impl_witness_table.9d9 = impl_witness_table (%Core.import_ref.b4fd3a.1, %Core.import_ref.6842), @Int.as.AddWith.impl.3af [concrete]
// CHECK:STDOUT:   %Core.import_ref.b4fd3a.5 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.6fa8: @Int.as.SubWith.impl.dc8.%Int.as.SubWith.impl.Op.type.2 (%Int.as.SubWith.impl.Op.type.6f3321.1) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.SubWith.impl.dc8.%Int.as.SubWith.impl.Op.2 (constants.%Int.as.SubWith.impl.Op.a37528.1)]
// CHECK:STDOUT:   %SubWith.impl_witness_table.dc9 = impl_witness_table (%Core.import_ref.b4fd3a.5, %Core.import_ref.6fa8), @Int.as.SubWith.impl.dc8 [concrete]
// CHECK:STDOUT:   %Core.Op.9ff: @Int.as.SubWith.impl.dc8.%Int.as.SubWith.impl.Op.type.1 (%Int.as.SubWith.impl.Op.type.6f3321.2) = import_ref Core//prelude/types/int, Op, loaded [symbolic = @Int.as.SubWith.impl.dc8.%Int.as.SubWith.impl.Op.1 (constants.%Int.as.SubWith.impl.Op.a37528.2)]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %M.Small.decl: @M.%M.Small.type (%M.Small.type.e5f) = fn_decl @M.Small [symbolic = @M.%M.Small (constants.%M.Small.c29)] {
// CHECK:STDOUT:     %_.param_patt: %pattern_type.6b6 = value_param_pattern [concrete = constants.%_.param_patt.fb2]
// CHECK:STDOUT:     %_.patt: %pattern_type.6b6 = at_binding_pattern _, %_.param_patt [concrete = constants.%_.patt.b75]
// CHECK:STDOUT:     %return.param_patt.loc9_19.1: @M.Small.%pattern_type (%pattern_type.161) = out_param_pattern [symbolic = %return.param_patt.loc9_19.2 (constants.%return.param_patt.9bc)]
// CHECK:STDOUT:     %return.patt.loc9_19.1: @M.Small.%pattern_type (%pattern_type.161) = return_slot_pattern %return.param_patt.loc9_19.1, constants.%M.a09 [symbolic = %return.patt.loc9_19.2 (constants.%return.patt.1f2)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc9_19.11: Core.Form = init_form constants.%M.a09 [symbolic = %.loc9_19.9 (constants.%.2eb)]
// CHECK:STDOUT:     %_.param: %i32 = value_param call_param0
// CHECK:STDOUT:     %_: %i32 = wrapper_binding _, %_.param
// CHECK:STDOUT:     %return.param: ref @M.Small.%M (%M.a09) = out_param call_param1
// CHECK:STDOUT:     %return: ref @M.Small.%M (%M.a09) = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %M.Big.decl: @M.%M.Big.type (%M.Big.type.702) = fn_decl @M.Big [symbolic = @M.%M.Big (constants.%M.Big.566)] {
// CHECK:STDOUT:     %_.param_patt.loc9_19.1: @M.Big.%pattern_type.loc9_19.1 (%pattern_type.51d1c4.1) = value_param_pattern [symbolic = %_.param_patt.loc9_19.3 (constants.%_.param_patt.339)]
// CHECK:STDOUT:     %_.patt.loc9_19.1: @M.Big.%pattern_type.loc9_19.1 (%pattern_type.51d1c4.1) = at_binding_pattern _, %_.param_patt.loc9_19.1 [symbolic = %_.patt.loc9_19.3 (constants.%_.patt.fd3)]
// CHECK:STDOUT:     %_.param_patt.loc9_19.2: @M.Big.%pattern_type.loc9_19.1 (%pattern_type.51d1c4.1) = value_param_pattern [symbolic = %_.param_patt.loc9_19.3 (constants.%_.param_patt.339)]
// CHECK:STDOUT:     %_.patt.loc9_19.2: @M.Big.%pattern_type.loc9_19.1 (%pattern_type.51d1c4.1) = at_binding_pattern _, %_.param_patt.loc9_19.2 [symbolic = %_.patt.loc9_19.3 (constants.%_.patt.fd3)]
// CHECK:STDOUT:     %return.param_patt.loc9_19.1: @M.Big.%pattern_type.loc9_19.2 (%pattern_type.161) = out_param_pattern [symbolic = %return.param_patt.loc9_19.2 (constants.%return.param_patt.9bc)]
// CHECK:STDOUT:     %return.patt.loc9_19.1: @M.Big.%pattern_type.loc9_19.2 (%pattern_type.161) = return_slot_pattern %return.param_patt.loc9_19.1, constants.%M.a09 [symbolic = %return.patt.loc9_19.2 (constants.%return.patt.1f2)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc9_19.9: Core.Form = init_form constants.%M.a09 [symbolic = %.loc9_19.7 (constants.%.2eb)]
// CHECK:STDOUT:     %_.param.loc9_19.1: @M.Big.%T (%T.67d) = value_param call_param0
// CHECK:STDOUT:     %_.loc9_19.1: @M.Big.%T (%T.67d) = wrapper_binding _, %_.param.loc9_19.1
// CHECK:STDOUT:     %_.param.loc9_19.2: @M.Big.%T (%T.67d) = value_param call_param1
// CHECK:STDOUT:     %_.loc9_19.2: @M.Big.%T (%T.67d) = wrapper_binding _, %_.param.loc9_19.2
// CHECK:STDOUT:     %return.param: ref @M.Big.%M (%M.a09) = out_param call_param2
// CHECK:STDOUT:     %return: ref @M.Big.%M (%M.a09) = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %M.decl: %M.type = class_decl @M [concrete = constants.%M.generic] {
// CHECK:STDOUT:     %T.patt.loc9_11.1: %pattern_type.98f = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc9_11.2 (constants.%T.patt.d47)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc9_13.1: type = splice_block %.loc9_13.2 [concrete = type] {
// CHECK:STDOUT:       %.Self.frozen: %type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen.197]
// CHECK:STDOUT:       %.loc9_13.2: type = type_literal type [concrete = type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc9_11.2: type = symbolic_binding T, 0 [symbolic = %T.loc9_11.1 (constants.%T.67d)]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %F8.decl: %F8.type = fn_decl @F8 [concrete = constants.%F8] {
// CHECK:STDOUT:     %m.param_patt: %pattern_type.134 = value_param_pattern [concrete = constants.%m.param_patt.cb3]
// CHECK:STDOUT:     %m.patt: %pattern_type.134 = at_binding_pattern m, %m.param_patt [concrete = constants.%m.patt.0cc]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc15_20: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %m.param: %M.d77 = value_param call_param0
// CHECK:STDOUT:     %.loc15_14: type = splice_block %M [concrete = constants.%M.d77] {
// CHECK:STDOUT:       %M.ref: %M.type = name_ref M, file.%M.decl [concrete = constants.%M.generic]
// CHECK:STDOUT:       %i8: type = type_literal constants.%i8 [concrete = constants.%i8]
// CHECK:STDOUT:       %M: type = class_type @M, @M(constants.%i8) [concrete = constants.%M.d77]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %m: %M.d77 = wrapper_binding m, %m.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %F64.decl: %F64.type = fn_decl @F64 [concrete = constants.%F64] {
// CHECK:STDOUT:     %m.param_patt: %pattern_type.e57 = value_param_pattern [concrete = constants.%m.param_patt.762]
// CHECK:STDOUT:     %m.patt: %pattern_type.e57 = at_binding_pattern m, %m.param_patt [concrete = constants.%m.patt.a07]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc22_22: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %m.param: %M.6b7 = value_param call_param0
// CHECK:STDOUT:     %.loc22_16: type = splice_block %M [concrete = constants.%M.6b7] {
// CHECK:STDOUT:       %M.ref: %M.type = name_ref M, file.%M.decl [concrete = constants.%M.generic]
// CHECK:STDOUT:       %i64: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:       %M: type = class_type @M, @M(constants.%i64) [concrete = constants.%M.6b7]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %m: %M.6b7 = wrapper_binding m, %m.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Run.decl: %Run.type = fn_decl @Run [concrete = constants.%Run] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc29: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param0
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic class @M(%T.loc9_11.2: type) {
// CHECK:STDOUT:   %T.patt.loc9_11.2: %pattern_type.98f = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc9_11.2 (constants.%T.patt.d47)]
// CHECK:STDOUT:   %T.loc9_11.1: type = symbolic_binding T, 0 [symbolic = %T.loc9_11.1 (constants.%T.67d)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %pattern_type: type = pattern_type %T.loc9_11.1 [symbolic = %pattern_type (constants.%pattern_type.51d1c4.1)]
// CHECK:STDOUT:   %x.param_patt: @M.%pattern_type (%pattern_type.51d1c4.1) = value_param_pattern [symbolic = %x.param_patt (constants.%x.param_patt.91d)]
// CHECK:STDOUT:   %x.patt: @M.%pattern_type (%pattern_type.51d1c4.1) = at_binding_pattern x, %x.param_patt [symbolic = %x.patt (constants.%x.patt.800)]
// CHECK:STDOUT:   %y.param_patt: @M.%pattern_type (%pattern_type.51d1c4.1) = value_param_pattern [symbolic = %y.param_patt (constants.%y.param_patt.be3)]
// CHECK:STDOUT:   %y.patt: @M.%pattern_type (%pattern_type.51d1c4.1) = at_binding_pattern y, %y.param_patt [symbolic = %y.patt (constants.%y.patt.b85)]
// CHECK:STDOUT:   %require_complete.loc11: <witness> = require_complete_type %T.loc9_11.1 [symbolic = %require_complete.loc11 (constants.%require_complete.944)]
// CHECK:STDOUT:   %tuple.type: type = tuple_type (%T.loc9_11.1, %T.loc9_11.1) [symbolic = %tuple.type (constants.%tuple.type.07a)]
// CHECK:STDOUT:   %.loc13_1.14: type = custom_layout_type {size=0, align=0, .Small@0: %tuple.type.a8a, .Big@0: @M.%tuple.type (%tuple.type.07a)} [symbolic = %.loc13_1.14 (constants.%.94d)]
// CHECK:STDOUT:   %struct_type.discriminant.payload: type = struct_type {.discriminant: %u2, .payload: @M.%.loc13_1.14 (%.94d)} [symbolic = %struct_type.discriminant.payload (constants.%struct_type.discriminant.payload.865)]
// CHECK:STDOUT:   %complete_type.loc13_1.2: <witness> = complete_type_witness %struct_type.discriminant.payload [symbolic = %complete_type.loc13_1.2 (constants.%complete_type.c6f)]
// CHECK:STDOUT:   %M.Small.type: type = fn_type @M.Small, @M(%T.loc9_11.1) [symbolic = %M.Small.type (constants.%M.Small.type.e5f)]
// CHECK:STDOUT:   %M.Small: @M.%M.Small.type (%M.Small.type.e5f) = struct_value () [symbolic = %M.Small (constants.%M.Small.c29)]
// CHECK:STDOUT:   %M.Big.type: type = fn_type @M.Big, @M(%T.loc9_11.1) [symbolic = %M.Big.type (constants.%M.Big.type.702)]
// CHECK:STDOUT:   %M.Big: @M.%M.Big.type (%M.Big.type.702) = struct_value () [symbolic = %M.Big (constants.%M.Big.566)]
// CHECK:STDOUT:   %M: type = class_type @M, @M(%T.loc9_11.1) [symbolic = %M (constants.%M.a09)]
// CHECK:STDOUT:   %require_complete.loc13: <witness> = require_complete_type %M [symbolic = %require_complete.loc13 (constants.%require_complete.cae)]
// CHECK:STDOUT:   %uninit.loc13_1.2: @M.%.loc13_1.14 (%.94d) = uninitialized_value [symbolic = %uninit.loc13_1.2 (constants.%uninit.c79)]
// CHECK:STDOUT:   %M.val: @M.%M (%M.a09) = struct_value (constants.%int_2.996, %uninit.loc13_1.2) [symbolic = %M.val (constants.%M.val.c49)]
// CHECK:STDOUT:   %.loc13_1.15: ref @M.%M (%M.a09) = temporary invalid, %M.val [symbolic = %.loc13_1.15 (constants.%.fd4)]
// CHECK:STDOUT:
// CHECK:STDOUT:   class {
// CHECK:STDOUT:     %a.param: %i32 = value_param call_param0
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %a: %i32 = wrapper_binding a, %a.param
// CHECK:STDOUT:     %x.param: @M.%T.loc9_11.1 (%T.67d) = value_param call_param0
// CHECK:STDOUT:     %T.ref.loc11_10: type = name_ref T, %T.loc9_11.2 [symbolic = %T.loc9_11.1 (constants.%T.67d)]
// CHECK:STDOUT:     %x: @M.%T.loc9_11.1 (%T.67d) = wrapper_binding x, %x.param
// CHECK:STDOUT:     %y.param: @M.%T.loc9_11.1 (%T.67d) = value_param call_param1
// CHECK:STDOUT:     %T.ref.loc11_16: type = name_ref T, %T.loc9_11.2 [symbolic = %T.loc9_11.1 (constants.%T.67d)]
// CHECK:STDOUT:     %y: @M.%T.loc9_11.1 (%T.67d) = wrapper_binding y, %y.param
// CHECK:STDOUT:     %.loc13_1.1: type = custom_layout_type {size=0, align=0, .Small@0: %tuple.type.a8a, .Big@0: %tuple.type.07a} [symbolic = %.loc13_1.14 (constants.%.94d)]
// CHECK:STDOUT:     %complete_type.loc13_1.1: <witness> = complete_type_witness constants.%struct_type.discriminant.payload.865 [symbolic = %complete_type.loc13_1.2 (constants.%complete_type.c6f)]
// CHECK:STDOUT:     %int_2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:     %impl.elem0.loc13_1.1: %.66c = impl_witness_access constants.%ImplicitAs.impl_witness.e93, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.409]
// CHECK:STDOUT:     %bound_method.loc13_1.1: <bound method> = bound_method %int_2, %impl.elem0.loc13_1.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.6c9]
// CHECK:STDOUT:     %specific_fn.loc13_1.1: <specific function> = specific_function %impl.elem0.loc13_1.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_2.ecc) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.a72]
// CHECK:STDOUT:     %bound_method.loc13_1.2: <bound method> = bound_method %int_2, %specific_fn.loc13_1.1 [concrete = constants.%bound_method.135]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %u2 = call %bound_method.loc13_1.2(%int_2) [concrete = constants.%int_2.996]
// CHECK:STDOUT:     %.loc13_1.2: %u2 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_2.996]
// CHECK:STDOUT:     %.loc13_1.3: %u2 = converted %int_2, %.loc13_1.2 [concrete = constants.%int_2.996]
// CHECK:STDOUT:     %.loc13_1.4: %struct_type.discriminant = struct_literal (%.loc13_1.3) [concrete = constants.%struct]
// CHECK:STDOUT:     %impl.elem0.loc13_1.2: %.594 = impl_witness_access constants.%Copy.impl_witness.f92, element0 [concrete = constants.%UInt.as.Copy.impl.Op.4d1]
// CHECK:STDOUT:     %bound_method.loc13_1.3: <bound method> = bound_method %.loc13_1.3, %impl.elem0.loc13_1.2 [concrete = constants.%UInt.as.Copy.impl.Op.bound]
// CHECK:STDOUT:     %specific_fn.loc13_1.2: <specific function> = specific_function %impl.elem0.loc13_1.2, @UInt.as.Copy.impl.Op(constants.%int_2.ecc) [concrete = constants.%UInt.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:     %bound_method.loc13_1.4: <bound method> = bound_method %.loc13_1.3, %specific_fn.loc13_1.2 [concrete = constants.%bound_method.f90]
// CHECK:STDOUT:     %UInt.as.Copy.impl.Op.call: init %u2 = call %bound_method.loc13_1.4(%.loc13_1.3) [concrete = constants.%int_2.996]
// CHECK:STDOUT:     %.loc13_1.5: ref @M.%M (%M.a09) = temporary_storage
// CHECK:STDOUT:     %.loc13_1.6: ref %u2 = class_element_access %.loc13_1.5, element0
// CHECK:STDOUT:     %.loc13_1.7: init %u2 to %.loc13_1.6 = in_place_init %UInt.as.Copy.impl.Op.call [concrete = constants.%int_2.996]
// CHECK:STDOUT:     %.loc13_1.8: ref @M.%.loc13_1.14 (%.94d) = class_element_access %.loc13_1.5, element1
// CHECK:STDOUT:     %uninit.loc13_1.1: @M.%.loc13_1.14 (%.94d) = uninitialized_value [symbolic = %uninit.loc13_1.2 (constants.%uninit.c79)]
// CHECK:STDOUT:     %.loc13_1.9: init @M.%.loc13_1.14 (%.94d) to %.loc13_1.8 = in_place_init %uninit.loc13_1.1 [symbolic = %uninit.loc13_1.2 (constants.%uninit.c79)]
// CHECK:STDOUT:     %.loc13_1.10: init @M.%M (%M.a09) to %.loc13_1.5 = class_init (%.loc13_1.7, %.loc13_1.9) [symbolic = %M.val (constants.%M.val.c49)]
// CHECK:STDOUT:     %.loc13_1.11: init @M.%M (%M.a09) = converted %.loc13_1.4, %.loc13_1.10 [symbolic = %M.val (constants.%M.val.c49)]
// CHECK:STDOUT:     %.loc13_1.12: ref @M.%M (%M.a09) = temporary %.loc13_1.5, %.loc13_1.11 [symbolic = %.loc13_1.15 (constants.%.fd4)]
// CHECK:STDOUT:     %.loc13_1.13: @M.%M (%M.a09) = acquire_value %.loc13_1.12 [symbolic = %M.val (constants.%M.val.c49)]
// CHECK:STDOUT:     %None: @M.%M (%M.a09) = wrapper_binding None, %.loc13_1.13
// CHECK:STDOUT:     complete_type_witness = %complete_type.loc13_1.1
// CHECK:STDOUT:
// CHECK:STDOUT:   !members:
// CHECK:STDOUT:     .Self = constants.%M.a09
// CHECK:STDOUT:     .T = <poisoned>
// CHECK:STDOUT:     .Small = generated.%M.Small.decl
// CHECK:STDOUT:     .Big = generated.%M.Big.decl
// CHECK:STDOUT:     .None = %None
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @M.Small(@M.%T.loc9_11.2: type) {
// CHECK:STDOUT:   %T: type = symbolic_binding T, 0 [symbolic = %T (constants.%T.67d)]
// CHECK:STDOUT:   %M: type = class_type @M, @M(%T) [symbolic = %M (constants.%M.a09)]
// CHECK:STDOUT:   %.loc9_19.9: Core.Form = init_form %M [symbolic = %.loc9_19.9 (constants.%.2eb)]
// CHECK:STDOUT:   %pattern_type: type = pattern_type %M [symbolic = %pattern_type (constants.%pattern_type.161)]
// CHECK:STDOUT:   %return.param_patt.loc9_19.2: @M.Small.%pattern_type (%pattern_type.161) = out_param_pattern [symbolic = %return.param_patt.loc9_19.2 (constants.%return.param_patt.9bc)]
// CHECK:STDOUT:   %return.patt.loc9_19.2: @M.Small.%pattern_type (%pattern_type.161) = return_slot_pattern %return.param_patt.loc9_19.2, %M [symbolic = %return.patt.loc9_19.2 (constants.%return.patt.1f2)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete: <witness> = require_complete_type %M [symbolic = %require_complete (constants.%require_complete.cae)]
// CHECK:STDOUT:   %tuple.type: type = tuple_type (%T, %T) [symbolic = %tuple.type (constants.%tuple.type.07a)]
// CHECK:STDOUT:   %.loc9_19.10: type = custom_layout_type {size=0, align=0, .Small@0: %tuple.type.a8a, .Big@0: @M.Small.%tuple.type (%tuple.type.07a)} [symbolic = %.loc9_19.10 (constants.%.94d)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%_.param: %i32) -> out %return.param: @M.Small.%M (%M.a09) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %.loc9_19.1: ref %u2 = class_element_access %return.param, element0
// CHECK:STDOUT:     %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:     %impl.elem0.loc9_19.1: %.66c = impl_witness_access constants.%ImplicitAs.impl_witness.e93, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.409]
// CHECK:STDOUT:     %bound_method.loc9_19.1: <bound method> = bound_method %int_0, %impl.elem0.loc9_19.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.941]
// CHECK:STDOUT:     %specific_fn.loc9_19.1: <specific function> = specific_function %impl.elem0.loc9_19.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_2.ecc) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.a72]
// CHECK:STDOUT:     %bound_method.loc9_19.2: <bound method> = bound_method %int_0, %specific_fn.loc9_19.1 [concrete = constants.%bound_method.6ef]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %u2 = call %bound_method.loc9_19.2(%int_0) [concrete = constants.%int_0.336]
// CHECK:STDOUT:     %.loc9_19.2: init %u2 = converted %int_0, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_0.336]
// CHECK:STDOUT:     %.loc9_19.3: init %u2 to %.loc9_19.1 = in_place_init %.loc9_19.2 [concrete = constants.%int_0.336]
// CHECK:STDOUT:     %.loc9_19.4: ref @M.Small.%.loc9_19.10 (%.94d) = class_element_access %return.param, element1
// CHECK:STDOUT:     %.loc9_19.5: ref %tuple.type.a8a = class_element_access %.loc9_19.4, element0
// CHECK:STDOUT:     %.loc10_16.1: %tuple.type.a8a = tuple_literal (%_.param)
// CHECK:STDOUT:     %impl.elem0.loc9_19.2: %.7a6 = impl_witness_access constants.%Copy.impl_witness.0e0, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:     %bound_method.loc9_19.3: <bound method> = bound_method %_.param, %impl.elem0.loc9_19.2
// CHECK:STDOUT:     %specific_fn.loc9_19.2: <specific function> = specific_function %impl.elem0.loc9_19.2, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:     %bound_method.loc9_19.4: <bound method> = bound_method %_.param, %specific_fn.loc9_19.2
// CHECK:STDOUT:     %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc9_19.4(%_.param)
// CHECK:STDOUT:     %.loc10_16.2: init %tuple.type.a8a to %.loc9_19.5 = tuple_init (%Int.as.Copy.impl.Op.call)
// CHECK:STDOUT:     %.loc9_19.6: init %tuple.type.a8a = converted %.loc10_16.1, %.loc10_16.2
// CHECK:STDOUT:     %.loc9_19.7: init %tuple.type.a8a to %.loc9_19.5 = in_place_init %.loc9_19.6
// CHECK:STDOUT:     %.loc9_19.8: init @M.Small.%M (%M.a09) to %return.param = class_init (%.loc9_19.3, %.loc9_19.7)
// CHECK:STDOUT:     return %.loc9_19.8 to %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @M.Big(@M.%T.loc9_11.2: type) {
// CHECK:STDOUT:   %T: type = symbolic_binding T, 0 [symbolic = %T (constants.%T.67d)]
// CHECK:STDOUT:   %pattern_type.loc9_19.1: type = pattern_type %T [symbolic = %pattern_type.loc9_19.1 (constants.%pattern_type.51d1c4.1)]
// CHECK:STDOUT:   %_.param_patt.loc9_19.3: @M.Big.%pattern_type.loc9_19.1 (%pattern_type.51d1c4.1) = value_param_pattern [symbolic = %_.param_patt.loc9_19.3 (constants.%_.param_patt.339)]
// CHECK:STDOUT:   %_.patt.loc9_19.3: @M.Big.%pattern_type.loc9_19.1 (%pattern_type.51d1c4.1) = at_binding_pattern _, %_.param_patt.loc9_19.3 [symbolic = %_.patt.loc9_19.3 (constants.%_.patt.fd3)]
// CHECK:STDOUT:   %M: type = class_type @M, @M(%T) [symbolic = %M (constants.%M.a09)]
// CHECK:STDOUT:   %.loc9_19.7: Core.Form = init_form %M [symbolic = %.loc9_19.7 (constants.%.2eb)]
// CHECK:STDOUT:   %pattern_type.loc9_19.2: type = pattern_type %M [symbolic = %pattern_type.loc9_19.2 (constants.%pattern_type.161)]
// CHECK:STDOUT:   %return.param_patt.loc9_19.2: @M.Big.%pattern_type.loc9_19.2 (%pattern_type.161) = out_param_pattern [symbolic = %return.param_patt.loc9_19.2 (constants.%return.param_patt.9bc)]
// CHECK:STDOUT:   %return.patt.loc9_19.2: @M.Big.%pattern_type.loc9_19.2 (%pattern_type.161) = return_slot_pattern %return.param_patt.loc9_19.2, %M [symbolic = %return.patt.loc9_19.2 (constants.%return.patt.1f2)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc9_19.1: <witness> = require_complete_type %T [symbolic = %require_complete.loc9_19.1 (constants.%require_complete.944)]
// CHECK:STDOUT:   %tuple.type: type = tuple_type (%T, %T) [symbolic = %tuple.type (constants.%tuple.type.07a)]
// CHECK:STDOUT:   %.loc9_19.8: type = custom_layout_type {size=0, align=0, .Small@0: %tuple.type.a8a, .Big@0: @M.Big.%tuple.type (%tuple.type.07a)} [symbolic = %.loc9_19.8 (constants.%.94d)]
// CHECK:STDOUT:   %require_complete.loc9_19.2: <witness> = require_complete_type %tuple.type [symbolic = %require_complete.loc9_19.2 (constants.%require_complete.22a)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%_.param.loc9_19.1: @M.Big.%T (%T.67d), %_.param.loc9_19.2: @M.Big.%T (%T.67d)) -> out %return.param: @M.Big.%M (%M.a09) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %.loc9_19.1: ref %u2 = class_element_access %return.param, element0
// CHECK:STDOUT:     %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:     %impl.elem0: %.66c = impl_witness_access constants.%ImplicitAs.impl_witness.e93, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.409]
// CHECK:STDOUT:     %bound_method.loc9_19.1: <bound method> = bound_method %int_1, %impl.elem0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.48e]
// CHECK:STDOUT:     %specific_fn: <specific function> = specific_function %impl.elem0, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_2.ecc) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.a72]
// CHECK:STDOUT:     %bound_method.loc9_19.2: <bound method> = bound_method %int_1, %specific_fn [concrete = constants.%bound_method.0f5]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %u2 = call %bound_method.loc9_19.2(%int_1) [concrete = constants.%int_1.508]
// CHECK:STDOUT:     %.loc9_19.2: init %u2 = converted %int_1, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_1.508]
// CHECK:STDOUT:     %.loc9_19.3: init %u2 to %.loc9_19.1 = in_place_init %.loc9_19.2 [concrete = constants.%int_1.508]
// CHECK:STDOUT:     %.loc9_19.4: ref @M.Big.%.loc9_19.8 (%.94d) = class_element_access %return.param, element1
// CHECK:STDOUT:     %.loc9_19.5: ref @M.Big.%tuple.type (%tuple.type.07a) = class_element_access %.loc9_19.4, element1
// CHECK:STDOUT:     %.loc11: @M.Big.%tuple.type (%tuple.type.07a) = tuple_literal (%_.param.loc9_19.1, %_.param.loc9_19.2)
// CHECK:STDOUT:     %.loc9_19.6: init @M.Big.%M (%M.a09) to %return.param = class_init (%.loc9_19.3, <error>) [concrete = <error>]
// CHECK:STDOUT:     return %.loc9_19.6 to %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @F8(%m.param: %M.d77) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %m.ref: %M.d77 = name_ref m, %m
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt: %pattern_type.134 = expr_pattern %None.ref in [concrete] {
// CHECK:STDOUT:       %.loc17_10.2: %M.d77 = specific_constant @M.%.loc13_1.13, @M(constants.%i8) [concrete = constants.%M.val.de4]
// CHECK:STDOUT:       %None.ref: %M.d77 = name_ref None, %.loc17_10.2 [concrete = constants.%M.val.de4]
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %.loc17_10.1: %M.d77 = splice_block %None.ref [concrete = constants.%M.val.de4] {
// CHECK:STDOUT:     %.loc17_10.2: %M.d77 = specific_constant @M.%.loc13_1.13, @M(constants.%i8) [concrete = constants.%M.val.de4]
// CHECK:STDOUT:     %None.ref: %M.d77 = name_ref None, %.loc17_10.2 [concrete = constants.%M.val.de4]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:   %impl.elem0.loc17_16.1: %.66c = impl_witness_access constants.%ImplicitAs.impl_witness.e93, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.409]
// CHECK:STDOUT:   %bound_method.loc17_16.1: <bound method> = bound_method %int_2, %impl.elem0.loc17_16.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.6c9]
// CHECK:STDOUT:   %specific_fn.loc17_16.1: <specific function> = specific_function %impl.elem0.loc17_16.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_2.ecc) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.a72]
// CHECK:STDOUT:   %bound_method.loc17_16.2: <bound method> = bound_method %int_2, %specific_fn.loc17_16.1 [concrete = constants.%bound_method.135]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc17_16: init %u2 = call %bound_method.loc17_16.2(%int_2) [concrete = constants.%int_2.996]
// CHECK:STDOUT:   %.loc17_16.1: %u2 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc17_16 [concrete = constants.%int_2.996]
// CHECK:STDOUT:   %.loc17_16.2: %u2 = converted %int_2, %.loc17_16.1 [concrete = constants.%int_2.996]
// CHECK:STDOUT:   %.loc17_16.3: ref %u2 = class_element_access %m.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc17_16.2: %.7a0 = impl_witness_access constants.%EqWith.impl_witness.454, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.e76]
// CHECK:STDOUT:   %bound_method.loc17_16.3: <bound method> = bound_method %.loc17_16.2, %impl.elem0.loc17_16.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound]
// CHECK:STDOUT:   %specific_fn.loc17_16.2: <specific function> = specific_function %impl.elem0.loc17_16.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_2.ecc, constants.%int_2.ecc) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.149]
// CHECK:STDOUT:   %bound_method.loc17_16.4: <bound method> = bound_method %.loc17_16.2, %specific_fn.loc17_16.2 [concrete = constants.%bound_method.64f]
// CHECK:STDOUT:   %.loc17_16.4: %u2 = acquire_value %.loc17_16.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call: init bool = call %bound_method.loc17_16.4(%.loc17_16.2, %.loc17_16.4)
// CHECK:STDOUT:   %.loc17_16.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call
// CHECK:STDOUT:   %.loc17_16.6: bool = converted %UInt.as.EqWith.impl.Equal.call, %.loc17_16.5
// CHECK:STDOUT:   if %.loc17_16.6 br !match.case.then else br !match.case.else
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then:
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc17_29: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc17_29.1: <bound method> = bound_method %int_0, %impl.elem0.loc17_29 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc17_29: <specific function> = specific_function %impl.elem0.loc17_29, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc17_29.2: <bound method> = bound_method %int_0, %specific_fn.loc17_29 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc17_29: init %i32 = call %bound_method.loc17_29.2(%int_0) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc17_29: init %i32 = converted %int_0, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc17_29 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   return %.loc17_29
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else:
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc18: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc18_26.1: <bound method> = bound_method %int_1, %impl.elem0.loc18 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc18: <specific function> = specific_function %impl.elem0.loc18, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc18_26.2: <bound method> = bound_method %int_1, %specific_fn.loc18 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc18: init %i32 = call %bound_method.loc18_26.2(%int_1) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc18: init %i32 = converted %int_1, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc18 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   return %.loc18
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @F64(%m.param: %M.6b7) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %m.ref: %M.6b7 = name_ref m, %m
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt: %pattern_type.e57 = expr_pattern %None.ref in [concrete] {
// CHECK:STDOUT:       %.loc24_10.2: %M.6b7 = specific_constant @M.%.loc13_1.13, @M(constants.%i64) [concrete = constants.%M.val.7cc]
// CHECK:STDOUT:       %None.ref: %M.6b7 = name_ref None, %.loc24_10.2 [concrete = constants.%M.val.7cc]
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %.loc24_10.1: %M.6b7 = splice_block %None.ref [concrete = constants.%M.val.7cc] {
// CHECK:STDOUT:     %.loc24_10.2: %M.6b7 = specific_constant @M.%.loc13_1.13, @M(constants.%i64) [concrete = constants.%M.val.7cc]
// CHECK:STDOUT:     %None.ref: %M.6b7 = name_ref None, %.loc24_10.2 [concrete = constants.%M.val.7cc]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:   %impl.elem0.loc24_16.1: %.66c = impl_witness_access constants.%ImplicitAs.impl_witness.e93, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.409]
// CHECK:STDOUT:   %bound_method.loc24_16.1: <bound method> = bound_method %int_2, %impl.elem0.loc24_16.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.6c9]
// CHECK:STDOUT:   %specific_fn.loc24_16.1: <specific function> = specific_function %impl.elem0.loc24_16.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_2.ecc) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.a72]
// CHECK:STDOUT:   %bound_method.loc24_16.2: <bound method> = bound_method %int_2, %specific_fn.loc24_16.1 [concrete = constants.%bound_method.135]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc24_16: init %u2 = call %bound_method.loc24_16.2(%int_2) [concrete = constants.%int_2.996]
// CHECK:STDOUT:   %.loc24_16.1: %u2 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc24_16 [concrete = constants.%int_2.996]
// CHECK:STDOUT:   %.loc24_16.2: %u2 = converted %int_2, %.loc24_16.1 [concrete = constants.%int_2.996]
// CHECK:STDOUT:   %.loc24_16.3: ref %u2 = class_element_access %m.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc24_16.2: %.7a0 = impl_witness_access constants.%EqWith.impl_witness.454, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.e76]
// CHECK:STDOUT:   %bound_method.loc24_16.3: <bound method> = bound_method %.loc24_16.2, %impl.elem0.loc24_16.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound]
// CHECK:STDOUT:   %specific_fn.loc24_16.2: <specific function> = specific_function %impl.elem0.loc24_16.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_2.ecc, constants.%int_2.ecc) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.149]
// CHECK:STDOUT:   %bound_method.loc24_16.4: <bound method> = bound_method %.loc24_16.2, %specific_fn.loc24_16.2 [concrete = constants.%bound_method.64f]
// CHECK:STDOUT:   %.loc24_16.4: %u2 = acquire_value %.loc24_16.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call: init bool = call %bound_method.loc24_16.4(%.loc24_16.2, %.loc24_16.4)
// CHECK:STDOUT:   %.loc24_16.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call
// CHECK:STDOUT:   %.loc24_16.6: bool = converted %UInt.as.EqWith.impl.Equal.call, %.loc24_16.5
// CHECK:STDOUT:   if %.loc24_16.6 br !match.case.then else br !match.case.else
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then:
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc24_29: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc24_29.1: <bound method> = bound_method %int_0, %impl.elem0.loc24_29 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc24_29: <specific function> = specific_function %impl.elem0.loc24_29, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc24_29.2: <bound method> = bound_method %int_0, %specific_fn.loc24_29 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc24_29: init %i32 = call %bound_method.loc24_29.2(%int_0) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc24_29: init %i32 = converted %int_0, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc24_29 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   return %.loc24_29
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else:
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc25: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc25_26.1: <bound method> = bound_method %int_1, %impl.elem0.loc25 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc25: <specific function> = specific_function %impl.elem0.loc25, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc25_26.2: <bound method> = bound_method %int_1, %specific_fn.loc25 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc25: init %i32 = call %bound_method.loc25_26.2(%int_1) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc25: init %i32 = converted %int_1, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc25 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   return %.loc25
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Run() -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %M.ref.loc30_18: %M.type = name_ref M, file.%M.decl [concrete = constants.%M.generic]
// CHECK:STDOUT:   %i8.loc30_20: type = type_literal constants.%i8 [concrete = constants.%i8]
// CHECK:STDOUT:   %M.loc30_22: type = class_type @M, @M(constants.%i8) [concrete = constants.%M.d77]
// CHECK:STDOUT:   %.loc30_23: %M.Small.type.b1f = specific_constant generated.%M.Small.decl, @M(constants.%i8) [concrete = constants.%M.Small.afb]
// CHECK:STDOUT:   %Small.ref: %M.Small.type.b1f = name_ref Small, %.loc30_23 [concrete = constants.%M.Small.afb]
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %M.Small.specific_fn: <specific function> = specific_function %Small.ref, @M.Small(constants.%i8) [concrete = constants.%M.Small.specific_fn]
// CHECK:STDOUT:   %.loc30_31.1: ref %M.d77 = temporary_storage
// CHECK:STDOUT:   %impl.elem0.loc30: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc30_30.1: <bound method> = bound_method %int_1, %impl.elem0.loc30 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc30: <specific function> = specific_function %impl.elem0.loc30, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc30_30.2: <bound method> = bound_method %int_1, %specific_fn.loc30 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc30: init %i32 = call %bound_method.loc30_30.2(%int_1) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc30_30.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc30 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc30_30.2: %i32 = converted %int_1, %.loc30_30.1 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %M.Small.call: init %M.a09 to %.loc30_31.1 = call %M.Small.specific_fn(%.loc30_30.2)
// CHECK:STDOUT:   %.loc30_31.2: %M.d77 = converted %M.Small.call, <error> [concrete = <error>]
// CHECK:STDOUT:   %.loc30_14: type = splice_block %M.loc30_14 [concrete = constants.%M.d77] {
// CHECK:STDOUT:     %M.ref.loc30_10: %M.type = name_ref M, file.%M.decl [concrete = constants.%M.generic]
// CHECK:STDOUT:     %i8.loc30_12: type = type_literal constants.%i8 [concrete = constants.%i8]
// CHECK:STDOUT:     %M.loc30_14: type = class_type @M, @M(constants.%i8) [concrete = constants.%M.d77]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %s: %M.d77 = wrapper_binding s, <error> [concrete = <error>]
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %s.patt: %pattern_type.134 = value_binding_pattern s [concrete = constants.%s.patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %M.ref.loc31_19: %M.type = name_ref M, file.%M.decl [concrete = constants.%M.generic]
// CHECK:STDOUT:   %i64.loc31_21: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:   %M.loc31_24: type = class_type @M, @M(constants.%i64) [concrete = constants.%M.6b7]
// CHECK:STDOUT:   %.loc31_25: %M.Big.type.50c = specific_constant generated.%M.Big.decl, @M(constants.%i64) [concrete = constants.%M.Big.8b3]
// CHECK:STDOUT:   %Big.ref: %M.Big.type.50c = name_ref Big, %.loc31_25 [concrete = constants.%M.Big.8b3]
// CHECK:STDOUT:   %int_3: Core.IntLiteral = int_value 3 [concrete = constants.%int_3.1ba]
// CHECK:STDOUT:   %int_4: Core.IntLiteral = int_value 4 [concrete = constants.%int_4.0c1]
// CHECK:STDOUT:   %M.Big.specific_fn: <specific function> = specific_function %Big.ref, @M.Big(constants.%i64) [concrete = constants.%M.Big.specific_fn]
// CHECK:STDOUT:   %.loc31_34.1: ref %M.6b7 = temporary_storage
// CHECK:STDOUT:   %impl.elem0.loc31_30: %.f349 = impl_witness_access constants.%ImplicitAs.impl_witness.091, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b]
// CHECK:STDOUT:   %bound_method.loc31_30.1: <bound method> = bound_method %int_3, %impl.elem0.loc31_30 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.e9c]
// CHECK:STDOUT:   %specific_fn.loc31_30: <specific function> = specific_function %impl.elem0.loc31_30, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.f33]
// CHECK:STDOUT:   %bound_method.loc31_30.2: <bound method> = bound_method %int_3, %specific_fn.loc31_30 [concrete = constants.%bound_method.740]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc31_30: init %i64 = call %bound_method.loc31_30.2(%int_3) [concrete = constants.%int_3.bd2]
// CHECK:STDOUT:   %.loc31_30.1: %i64 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc31_30 [concrete = constants.%int_3.bd2]
// CHECK:STDOUT:   %.loc31_30.2: %i64 = converted %int_3, %.loc31_30.1 [concrete = constants.%int_3.bd2]
// CHECK:STDOUT:   %impl.elem0.loc31_33: %.f349 = impl_witness_access constants.%ImplicitAs.impl_witness.091, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b]
// CHECK:STDOUT:   %bound_method.loc31_33.1: <bound method> = bound_method %int_4, %impl.elem0.loc31_33 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.b50]
// CHECK:STDOUT:   %specific_fn.loc31_33: <specific function> = specific_function %impl.elem0.loc31_33, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.f33]
// CHECK:STDOUT:   %bound_method.loc31_33.2: <bound method> = bound_method %int_4, %specific_fn.loc31_33 [concrete = constants.%bound_method.912]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc31_33: init %i64 = call %bound_method.loc31_33.2(%int_4) [concrete = constants.%int_4.825]
// CHECK:STDOUT:   %.loc31_33.1: %i64 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc31_33 [concrete = constants.%int_4.825]
// CHECK:STDOUT:   %.loc31_33.2: %i64 = converted %int_4, %.loc31_33.1 [concrete = constants.%int_4.825]
// CHECK:STDOUT:   %M.Big.call: init %M.a09 to %.loc31_34.1 = call %M.Big.specific_fn(%.loc31_30.2, %.loc31_33.2)
// CHECK:STDOUT:   %.loc31_34.2: %M.6b7 = converted %M.Big.call, <error> [concrete = <error>]
// CHECK:STDOUT:   %.loc31_15: type = splice_block %M.loc31_15 [concrete = constants.%M.6b7] {
// CHECK:STDOUT:     %M.ref.loc31_10: %M.type = name_ref M, file.%M.decl [concrete = constants.%M.generic]
// CHECK:STDOUT:     %i64.loc31_12: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:     %M.loc31_15: type = class_type @M, @M(constants.%i64) [concrete = constants.%M.6b7]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %b: %M.6b7 = wrapper_binding b, <error> [concrete = <error>]
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %b.patt: %pattern_type.e57 = value_binding_pattern b [concrete = constants.%b.patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %F8.ref: %F8.type = name_ref F8, file.%F8.decl [concrete = constants.%F8]
// CHECK:STDOUT:   %s.ref: %M.d77 = name_ref s, %s [concrete = <error>]
// CHECK:STDOUT:   %F8.call: init %i32 = call %F8.ref(<error>)
// CHECK:STDOUT:   %F64.ref: %F64.type = name_ref F64, file.%F64.decl [concrete = constants.%F64]
// CHECK:STDOUT:   %b.ref: %M.6b7 = name_ref b, %b [concrete = <error>]
// CHECK:STDOUT:   %F64.call: init %i32 = call %F64.ref(<error>)
// CHECK:STDOUT:   %impl.elem1.loc32_16: %.516 = impl_witness_access constants.%AddWith.impl_witness.3af, element1 [concrete = constants.%Int.as.AddWith.impl.Op.365]
// CHECK:STDOUT:   %bound_method.loc32_16.1: <bound method> = bound_method %F8.call, %impl.elem1.loc32_16
// CHECK:STDOUT:   %specific_fn.loc32_16: <specific function> = specific_function %impl.elem1.loc32_16, @Int.as.AddWith.impl.Op.1(constants.%int_32) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.f25]
// CHECK:STDOUT:   %bound_method.loc32_16.2: <bound method> = bound_method %F8.call, %specific_fn.loc32_16
// CHECK:STDOUT:   %.loc32_14.1: %i32 = value_of_initializer %F8.call
// CHECK:STDOUT:   %.loc32_14.2: %i32 = converted %F8.call, %.loc32_14.1
// CHECK:STDOUT:   %.loc32_23.1: %i32 = value_of_initializer %F64.call
// CHECK:STDOUT:   %.loc32_23.2: %i32 = converted %F64.call, %.loc32_23.1
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call: init %i32 = call %bound_method.loc32_16.2(%.loc32_14.2, %.loc32_23.2)
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:   %impl.elem1.loc32_25: %.e15 = impl_witness_access constants.%SubWith.impl_witness.d78, element1 [concrete = constants.%Int.as.SubWith.impl.Op.49baee.2]
// CHECK:STDOUT:   %bound_method.loc32_25.1: <bound method> = bound_method %Int.as.AddWith.impl.Op.call, %impl.elem1.loc32_25
// CHECK:STDOUT:   %specific_fn.loc32_25: <specific function> = specific_function %impl.elem1.loc32_25, @Int.as.SubWith.impl.Op.2(constants.%int_32, constants.%ImplicitAs.facet.9f1) [concrete = constants.%Int.as.SubWith.impl.Op.specific_fn.4cc768.1]
// CHECK:STDOUT:   %bound_method.loc32_25.2: <bound method> = bound_method %Int.as.AddWith.impl.Op.call, %specific_fn.loc32_25
// CHECK:STDOUT:   %.loc32_16.1: %i32 = value_of_initializer %Int.as.AddWith.impl.Op.call
// CHECK:STDOUT:   %.loc32_16.2: %i32 = converted %Int.as.AddWith.impl.Op.call, %.loc32_16.1
// CHECK:STDOUT:   %.loc32_25: %Int.as.SubWith.impl.Op.type.745d60.1 = specific_constant imports.%Core.Op.9ff, @Int.as.SubWith.impl.dc8(constants.%int_32, constants.%ImplicitAs.facet.9f1) [concrete = constants.%Int.as.SubWith.impl.Op.49baee.1]
// CHECK:STDOUT:   %Op.ref: %Int.as.SubWith.impl.Op.type.745d60.1 = name_ref Op, %.loc32_25 [concrete = constants.%Int.as.SubWith.impl.Op.49baee.1]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.bound: <bound method> = bound_method %.loc32_16.2, %Op.ref
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.specific_fn: <specific function> = specific_function %Op.ref, @Int.as.SubWith.impl.Op.3(constants.%int_32, constants.%ImplicitAs.facet.9f1) [concrete = constants.%Int.as.SubWith.impl.Op.specific_fn.4cc768.2]
// CHECK:STDOUT:   %bound_method.loc32_25.3: <bound method> = bound_method %.loc32_16.2, %Int.as.SubWith.impl.Op.specific_fn
// CHECK:STDOUT:   %impl.elem0.loc32: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc32_27.1: <bound method> = bound_method %int_2, %impl.elem0.loc32 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.9f3]
// CHECK:STDOUT:   %specific_fn.loc32_27: <specific function> = specific_function %impl.elem0.loc32, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc32_27.2: <bound method> = bound_method %int_2, %specific_fn.loc32_27 [concrete = constants.%bound_method.3cb]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc32: init %i32 = call %bound_method.loc32_27.2(%int_2) [concrete = constants.%int_2.295]
// CHECK:STDOUT:   %.loc32_27.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc32 [concrete = constants.%int_2.295]
// CHECK:STDOUT:   %.loc32_27.2: %i32 = converted %int_2, %.loc32_27.1 [concrete = constants.%int_2.295]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.call: init %i32 = call %bound_method.loc32_25.3(%.loc32_16.2, %.loc32_27.2)
// CHECK:STDOUT:   return %Int.as.SubWith.impl.Op.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @M(constants.%T.67d) {
// CHECK:STDOUT:   %T.patt.loc9_11.2 => constants.%T.patt.d47
// CHECK:STDOUT:   %T.loc9_11.1 => constants.%T.67d
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.51d1c4.1
// CHECK:STDOUT:   %x.param_patt => constants.%x.param_patt.91d
// CHECK:STDOUT:   %x.patt => constants.%x.patt.800
// CHECK:STDOUT:   %y.param_patt => constants.%y.param_patt.be3
// CHECK:STDOUT:   %y.patt => constants.%y.patt.b85
// CHECK:STDOUT:   %require_complete.loc11 => constants.%require_complete.944
// CHECK:STDOUT:   %tuple.type => constants.%tuple.type.07a
// CHECK:STDOUT:   %.loc13_1.14 => constants.%.94d
// CHECK:STDOUT:   %struct_type.discriminant.payload => constants.%struct_type.discriminant.payload.865
// CHECK:STDOUT:   %complete_type.loc13_1.2 => constants.%complete_type.c6f
// CHECK:STDOUT:   %M.Small.type => constants.%M.Small.type.e5f
// CHECK:STDOUT:   %M.Small => constants.%M.Small.c29
// CHECK:STDOUT:   %M.Big.type => constants.%M.Big.type.702
// CHECK:STDOUT:   %M.Big => constants.%M.Big.566
// CHECK:STDOUT:   %M => constants.%M.a09
// CHECK:STDOUT:   %require_complete.loc13 => constants.%require_complete.cae
// CHECK:STDOUT:   %uninit.loc13_1.2 => constants.%uninit.c79
// CHECK:STDOUT:   %M.val => constants.%M.val.c49
// CHECK:STDOUT:   %.loc13_1.15 => constants.%.fd4
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @M.Small(constants.%T.67d) {
// CHECK:STDOUT:   %T => constants.%T.67d
// CHECK:STDOUT:   %M => constants.%M.a09
// CHECK:STDOUT:   %.loc9_19.9 => constants.%.2eb
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.161
// CHECK:STDOUT:   %return.param_patt.loc9_19.2 => constants.%return.param_patt.9bc
// CHECK:STDOUT:   %return.patt.loc9_19.2 => constants.%return.patt.1f2
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @M.Big(constants.%T.67d) {
// CHECK:STDOUT:   %T => constants.%T.67d
// CHECK:STDOUT:   %pattern_type.loc9_19.1 => constants.%pattern_type.51d1c4.1
// CHECK:STDOUT:   %_.param_patt.loc9_19.3 => constants.%_.param_patt.339
// CHECK:STDOUT:   %_.patt.loc9_19.3 => constants.%_.patt.fd3
// CHECK:STDOUT:   %M => constants.%M.a09
// CHECK:STDOUT:   %.loc9_19.7 => constants.%.2eb
// CHECK:STDOUT:   %pattern_type.loc9_19.2 => constants.%pattern_type.161
// CHECK:STDOUT:   %return.param_patt.loc9_19.2 => constants.%return.param_patt.9bc
// CHECK:STDOUT:   %return.patt.loc9_19.2 => constants.%return.patt.1f2
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @M(constants.%i8) {
// CHECK:STDOUT:   %T.patt.loc9_11.2 => constants.%T.patt.d47
// CHECK:STDOUT:   %T.loc9_11.1 => constants.%i8
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.0cf
// CHECK:STDOUT:   %x.param_patt => constants.%x.param_patt.c89
// CHECK:STDOUT:   %x.patt => constants.%x.patt.9fb
// CHECK:STDOUT:   %y.param_patt => constants.%y.param_patt.9a0
// CHECK:STDOUT:   %y.patt => constants.%y.patt.b9f
// CHECK:STDOUT:   %require_complete.loc11 => constants.%complete_type.58c
// CHECK:STDOUT:   %tuple.type => constants.%tuple.type.f88
// CHECK:STDOUT:   %.loc13_1.14 => constants.%.c87
// CHECK:STDOUT:   %struct_type.discriminant.payload => constants.%struct_type.discriminant.payload.59d
// CHECK:STDOUT:   %complete_type.loc13_1.2 => constants.%complete_type.27a
// CHECK:STDOUT:   %M.Small.type => constants.%M.Small.type.b1f
// CHECK:STDOUT:   %M.Small => constants.%M.Small.afb
// CHECK:STDOUT:   %M.Big.type => constants.%M.Big.type.848
// CHECK:STDOUT:   %M.Big => constants.%M.Big.87b
// CHECK:STDOUT:   %M => constants.%M.d77
// CHECK:STDOUT:   %require_complete.loc13 => constants.%complete_type.27a
// CHECK:STDOUT:   %uninit.loc13_1.2 => constants.%uninit.b30
// CHECK:STDOUT:   %M.val => constants.%M.val.de4
// CHECK:STDOUT:   %.loc13_1.15 => constants.%.f27
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @M(constants.%i64) {
// CHECK:STDOUT:   %T.patt.loc9_11.2 => constants.%T.patt.d47
// CHECK:STDOUT:   %T.loc9_11.1 => constants.%i64
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.f57
// CHECK:STDOUT:   %x.param_patt => constants.%x.param_patt.7b8
// CHECK:STDOUT:   %x.patt => constants.%x.patt.451
// CHECK:STDOUT:   %y.param_patt => constants.%y.param_patt.83d
// CHECK:STDOUT:   %y.patt => constants.%y.patt.d31
// CHECK:STDOUT:   %require_complete.loc11 => constants.%complete_type.4a1
// CHECK:STDOUT:   %tuple.type => constants.%tuple.type.1ac
// CHECK:STDOUT:   %.loc13_1.14 => constants.%.050
// CHECK:STDOUT:   %struct_type.discriminant.payload => constants.%struct_type.discriminant.payload.764
// CHECK:STDOUT:   %complete_type.loc13_1.2 => constants.%complete_type.90c
// CHECK:STDOUT:   %M.Small.type => constants.%M.Small.type.22f
// CHECK:STDOUT:   %M.Small => constants.%M.Small.0ed
// CHECK:STDOUT:   %M.Big.type => constants.%M.Big.type.50c
// CHECK:STDOUT:   %M.Big => constants.%M.Big.8b3
// CHECK:STDOUT:   %M => constants.%M.6b7
// CHECK:STDOUT:   %require_complete.loc13 => constants.%complete_type.90c
// CHECK:STDOUT:   %uninit.loc13_1.2 => constants.%uninit.8ce
// CHECK:STDOUT:   %M.val => constants.%M.val.7cc
// CHECK:STDOUT:   %.loc13_1.15 => constants.%.10f
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @M.Small(constants.%i8) {
// CHECK:STDOUT:   %T => constants.%i8
// CHECK:STDOUT:   %M => constants.%M.d77
// CHECK:STDOUT:   %.loc9_19.9 => constants.%.3fb
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.134
// CHECK:STDOUT:   %return.param_patt.loc9_19.2 => constants.%return.param_patt.2a6
// CHECK:STDOUT:   %return.patt.loc9_19.2 => constants.%return.patt.28a
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete => constants.%complete_type.27a
// CHECK:STDOUT:   %tuple.type => constants.%tuple.type.f88
// CHECK:STDOUT:   %.loc9_19.10 => constants.%.c87
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @M.Big(constants.%i64) {
// CHECK:STDOUT:   %T => constants.%i64
// CHECK:STDOUT:   %pattern_type.loc9_19.1 => constants.%pattern_type.f57
// CHECK:STDOUT:   %_.param_patt.loc9_19.3 => constants.%_.param_patt.2f0
// CHECK:STDOUT:   %_.patt.loc9_19.3 => constants.%_.patt.233
// CHECK:STDOUT:   %M => constants.%M.6b7
// CHECK:STDOUT:   %.loc9_19.7 => constants.%.af2
// CHECK:STDOUT:   %pattern_type.loc9_19.2 => constants.%pattern_type.e57
// CHECK:STDOUT:   %return.param_patt.loc9_19.2 => constants.%return.param_patt.0b0
// CHECK:STDOUT:   %return.patt.loc9_19.2 => constants.%return.patt.b25
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc9_19.1 => constants.%complete_type.4a1
// CHECK:STDOUT:   %tuple.type => constants.%tuple.type.1ac
// CHECK:STDOUT:   %.loc9_19.8 => constants.%.050
// CHECK:STDOUT:   %require_complete.loc9_19.2 => constants.%complete_type.3d3
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- concrete_payload_in_generic.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %.Self.frozen.197: %type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %pattern_type.98f: type = pattern_type type [concrete]
// CHECK:STDOUT:   %T.patt.d47: %pattern_type.98f = symbolic_binding_pattern T, 0 [symbolic]
// CHECK:STDOUT:   %T.67d: type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %P.type: type = generic_class_type @P [concrete]
// CHECK:STDOUT:   %P.generic: %P.type = struct_value () [concrete]
// CHECK:STDOUT:   %P.f86: type = class_type @P, @P(%T.67d) [symbolic]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %Int.67af24.1: type = class_type @Int, @Int(%N) [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %int_2.ecc: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %u2: type = class_type @UInt, @UInt(%int_2.ecc) [concrete]
// CHECK:STDOUT:   %tuple.type.a8a: type = tuple_type (%i32) [concrete]
// CHECK:STDOUT:   %.4d9: type = custom_layout_type {size=4, align=4, .Tag@0: %tuple.type.a8a} [concrete]
// CHECK:STDOUT:   %struct_type.discriminant.payload.677: type = struct_type {.discriminant: %u2, .payload: %.4d9} [concrete]
// CHECK:STDOUT:   %complete_type.0f8: <witness> = complete_type_witness %struct_type.discriminant.payload.677 [concrete]
// CHECK:STDOUT:   %struct_type.discriminant: type = struct_type {.discriminant: %u2} [concrete]
// CHECK:STDOUT:   %_.param_patt: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %_.patt: %pattern_type.6b6 = at_binding_pattern _, %_.param_patt [concrete]
// CHECK:STDOUT:   %.3a8: Core.Form = init_form %P.f86 [symbolic]
// CHECK:STDOUT:   %pattern_type.6d3: type = pattern_type %P.f86 [symbolic]
// CHECK:STDOUT:   %return.param_patt.3b8: %pattern_type.6d3 = out_param_pattern [symbolic]
// CHECK:STDOUT:   %return.patt.ec6: %pattern_type.6d3 = return_slot_pattern %return.param_patt.3b8, %P.f86 [symbolic]
// CHECK:STDOUT:   %P.Tag.type.7cd: type = fn_type @P.Tag, @P(%T.67d) [symbolic]
// CHECK:STDOUT:   %P.Tag.bd4: %P.Tag.type.7cd = struct_value () [symbolic]
// CHECK:STDOUT:   %require_complete.657: <witness> = require_complete_type %P.f86 [symbolic]
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
// CHECK:STDOUT:   %P.Empty.type.e43: type = fn_type @P.Empty, @P(%T.67d) [symbolic]
// CHECK:STDOUT:   %P.Empty.cdc: %P.Empty.type.e43 = struct_value () [symbolic]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.48e: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.409 [concrete]
// CHECK:STDOUT:   %bound_method.0f5: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.a72 [concrete]
// CHECK:STDOUT:   %int_1.508: %u2 = int_value 1 [concrete]
// CHECK:STDOUT:   %uninit: %.4d9 = uninitialized_value [concrete]
// CHECK:STDOUT:   %P.val.b59: %P.f86 = struct_value (%int_1.508, %uninit) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.6c9: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.409 [concrete]
// CHECK:STDOUT:   %bound_method.135: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.a72 [concrete]
// CHECK:STDOUT:   %int_2.996: %u2 = int_value 2 [concrete]
// CHECK:STDOUT:   %struct: %struct_type.discriminant = struct_value (%int_2.996) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.type.0c5: type = fn_type @UInt.as.Copy.impl.Op, @UInt.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.38a: %UInt.as.Copy.impl.Op.type.0c5 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.f92: <witness> = impl_witness imports.%Copy.impl_witness_table.fe3, @UInt.as.Copy.impl(%int_2.ecc) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.type.d68: type = fn_type @UInt.as.Copy.impl.Op, @UInt.as.Copy.impl(%int_2.ecc) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.4d1: %UInt.as.Copy.impl.Op.type.d68 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet.842: %Copy.type = facet_value %u2, (%Copy.impl_witness.f92) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.21e: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.842) [concrete]
// CHECK:STDOUT:   %.594: type = fn_type_with_self_type %Copy.WithSelf.Op.type.21e, %Copy.facet.842 [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.bound: <bound method> = bound_method %int_2.996, %UInt.as.Copy.impl.Op.4d1 [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %UInt.as.Copy.impl.Op.4d1, @UInt.as.Copy.impl.Op(%int_2.ecc) [concrete]
// CHECK:STDOUT:   %bound_method.f90: <bound method> = bound_method %int_2.996, %UInt.as.Copy.impl.Op.specific_fn [concrete]
// CHECK:STDOUT:   %P.val.610: %P.f86 = struct_value (%int_2.996, %uninit) [symbolic]
// CHECK:STDOUT:   %.ddf: ref %P.f86 = temporary invalid, %P.val.610 [symbolic]
// CHECK:STDOUT:   %P.94c: type = class_type @P, @P(bool) [concrete]
// CHECK:STDOUT:   %pattern_type.b3c: type = pattern_type %P.94c [concrete]
// CHECK:STDOUT:   %p.param_patt: %pattern_type.b3c = value_param_pattern [concrete]
// CHECK:STDOUT:   %p.patt: %pattern_type.b3c = at_binding_pattern p, %p.param_patt [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT:   %P.Tag.type.a29: type = fn_type @P.Tag, @P(bool) [concrete]
// CHECK:STDOUT:   %P.Tag.de0: %P.Tag.type.a29 = struct_value () [concrete]
// CHECK:STDOUT:   %P.Empty.type.1bf: type = fn_type @P.Empty, @P(bool) [concrete]
// CHECK:STDOUT:   %P.Empty.a5f: %P.Empty.type.1bf = struct_value () [concrete]
// CHECK:STDOUT:   %P.val.44c: %P.94c = struct_value (%int_2.996, %uninit) [concrete]
// CHECK:STDOUT:   %.cf7: ref %P.94c = temporary invalid, %P.val.44c [concrete]
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
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound: <bound method> = bound_method %int_2.996, %UInt.as.EqWith.impl.Equal.e76 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.specific_fn.149: <specific function> = specific_function %UInt.as.EqWith.impl.Equal.e76, @UInt.as.EqWith.impl.Equal.1(%int_2.ecc, %int_2.ecc) [concrete]
// CHECK:STDOUT:   %bound_method.64f: <bound method> = bound_method %int_2.996, %UInt.as.EqWith.impl.Equal.specific_fn.149 [concrete]
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
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.953: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT:   %Run.type: type = fn_type @Run [concrete]
// CHECK:STDOUT:   %Run: %Run.type = struct_value () [concrete]
// CHECK:STDOUT:   %t.patt: %pattern_type.b3c = value_binding_pattern t [concrete]
// CHECK:STDOUT:   %int_7.29f: Core.IntLiteral = int_value 7 [concrete]
// CHECK:STDOUT:   %.744: Core.Form = init_form %P.94c [concrete]
// CHECK:STDOUT:   %return.param_patt.ce7: %pattern_type.b3c = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.b6f: %pattern_type.b3c = return_slot_pattern %return.param_patt.ce7, %P.94c [concrete]
// CHECK:STDOUT:   %P.Tag.specific_fn: <specific function> = specific_function %P.Tag.de0, @P.Tag(bool) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.66b: <bound method> = bound_method %int_7.29f, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.7ff: <bound method> = bound_method %int_7.29f, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_7.690: %i32 = int_value 7 [concrete]
// CHECK:STDOUT:   %e.patt: %pattern_type.b3c = value_binding_pattern e [concrete]
// CHECK:STDOUT:   %P.Empty.specific_fn: <specific function> = specific_function %P.Empty.a5f, @P.Empty(bool) [concrete]
// CHECK:STDOUT:   %AddWith.type.be9: type = facet_type <@AddWith, @AddWith(%i32)> [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.610: type = fn_type @Int.as.AddWith.impl.Op.1, @Int.as.AddWith.impl.3af(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.732: %Int.as.AddWith.impl.Op.type.610 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.type.f7de31.2: type = facet_type <@ImplicitAs, @ImplicitAs(%Int.67af24.1)> [symbolic]
// CHECK:STDOUT:   %U.4e6: %ImplicitAs.type.f7de31.2 = symbolic_binding U, 1 [symbolic]
// CHECK:STDOUT:   %AddWith.impl_witness.3af: <witness> = impl_witness imports.%AddWith.impl_witness_table.9d9, @Int.as.AddWith.impl.3af(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.056: type = fn_type @Int.as.AddWith.impl.Op.1, @Int.as.AddWith.impl.3af(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.365: %Int.as.AddWith.impl.Op.type.056 = struct_value () [concrete]
// CHECK:STDOUT:   %AddWith.facet.b8a: %AddWith.type.be9 = facet_value %i32, (%AddWith.impl_witness.3af) [concrete]
// CHECK:STDOUT:   %AddWith.WithSelf.Op.type.e15: type = fn_type @AddWith.WithSelf.Op, @AddWith.WithSelf(%i32, %AddWith.facet.b8a) [concrete]
// CHECK:STDOUT:   %.516: type = fn_type_with_self_type %AddWith.WithSelf.Op.type.e15, %AddWith.facet.b8a [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.specific_fn.f25: <specific function> = specific_function %Int.as.AddWith.impl.Op.365, @Int.as.AddWith.impl.Op.1(%int_32) [concrete]
// CHECK:STDOUT:   %SubWith.type.4c2: type = facet_type <@SubWith, @SubWith(Core.IntLiteral)> [concrete]
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
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.9f3: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.3cb: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_2.295: %i32 = int_value 2 [concrete]
// CHECK:STDOUT:   %P.val.695: %P.94c = struct_value (%int_1.508, %uninit) [concrete]
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
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.b3c = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.b4fd3a.1 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.6842: @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op.type (%Int.as.AddWith.impl.Op.type.610) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op (constants.%Int.as.AddWith.impl.Op.732)]
// CHECK:STDOUT:   %AddWith.impl_witness_table.9d9 = impl_witness_table (%Core.import_ref.b4fd3a.1, %Core.import_ref.6842), @Int.as.AddWith.impl.3af [concrete]
// CHECK:STDOUT:   %Core.import_ref.b4fd3a.5 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.6fa8: @Int.as.SubWith.impl.dc8.%Int.as.SubWith.impl.Op.type.2 (%Int.as.SubWith.impl.Op.type.6f3321.1) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.SubWith.impl.dc8.%Int.as.SubWith.impl.Op.2 (constants.%Int.as.SubWith.impl.Op.a37528.1)]
// CHECK:STDOUT:   %SubWith.impl_witness_table.dc9 = impl_witness_table (%Core.import_ref.b4fd3a.5, %Core.import_ref.6fa8), @Int.as.SubWith.impl.dc8 [concrete]
// CHECK:STDOUT:   %Core.Op.9ff: @Int.as.SubWith.impl.dc8.%Int.as.SubWith.impl.Op.type.1 (%Int.as.SubWith.impl.Op.type.6f3321.2) = import_ref Core//prelude/types/int, Op, loaded [symbolic = @Int.as.SubWith.impl.dc8.%Int.as.SubWith.impl.Op.1 (constants.%Int.as.SubWith.impl.Op.a37528.2)]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %P.Tag.decl: @P.%P.Tag.type (%P.Tag.type.7cd) = fn_decl @P.Tag [symbolic = @P.%P.Tag (constants.%P.Tag.bd4)] {
// CHECK:STDOUT:     %_.param_patt: %pattern_type.6b6 = value_param_pattern [concrete = constants.%_.param_patt]
// CHECK:STDOUT:     %_.patt: %pattern_type.6b6 = at_binding_pattern _, %_.param_patt [concrete = constants.%_.patt]
// CHECK:STDOUT:     %return.param_patt.loc10_19.1: @P.Tag.%pattern_type (%pattern_type.6d3) = out_param_pattern [symbolic = %return.param_patt.loc10_19.2 (constants.%return.param_patt.3b8)]
// CHECK:STDOUT:     %return.patt.loc10_19.1: @P.Tag.%pattern_type (%pattern_type.6d3) = return_slot_pattern %return.param_patt.loc10_19.1, constants.%P.f86 [symbolic = %return.patt.loc10_19.2 (constants.%return.patt.ec6)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc10_19.10: Core.Form = init_form constants.%P.f86 [symbolic = %.loc10_19.9 (constants.%.3a8)]
// CHECK:STDOUT:     %_.param: %i32 = value_param call_param0
// CHECK:STDOUT:     %_: %i32 = wrapper_binding _, %_.param
// CHECK:STDOUT:     %return.param: ref @P.Tag.%P (%P.f86) = out_param call_param1
// CHECK:STDOUT:     %return: ref @P.Tag.%P (%P.f86) = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %P.Empty.decl: @P.%P.Empty.type (%P.Empty.type.e43) = fn_decl @P.Empty [symbolic = @P.%P.Empty (constants.%P.Empty.cdc)] {
// CHECK:STDOUT:     %return.param_patt.loc10_19.1: @P.Empty.%pattern_type (%pattern_type.6d3) = out_param_pattern [symbolic = %return.param_patt.loc10_19.2 (constants.%return.param_patt.3b8)]
// CHECK:STDOUT:     %return.patt.loc10_19.1: @P.Empty.%pattern_type (%pattern_type.6d3) = return_slot_pattern %return.param_patt.loc10_19.1, constants.%P.f86 [symbolic = %return.patt.loc10_19.2 (constants.%return.patt.ec6)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc10_19.8: Core.Form = init_form constants.%P.f86 [symbolic = %.loc10_19.7 (constants.%.3a8)]
// CHECK:STDOUT:     %return.param: ref @P.Empty.%P (%P.f86) = out_param call_param0
// CHECK:STDOUT:     %return: ref @P.Empty.%P (%P.f86) = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %P.decl: %P.type = class_decl @P [concrete = constants.%P.generic] {
// CHECK:STDOUT:     %T.patt.loc10_11.1: %pattern_type.98f = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc10_11.2 (constants.%T.patt.d47)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc10_13.1: type = splice_block %.loc10_13.2 [concrete = type] {
// CHECK:STDOUT:       %.Self.frozen: %type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen.197]
// CHECK:STDOUT:       %.loc10_13.2: type = type_literal type [concrete = type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc10_11.2: type = symbolic_binding T, 0 [symbolic = %T.loc10_11.1 (constants.%T.67d)]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %F.decl: %F.type = fn_decl @F [concrete = constants.%F] {
// CHECK:STDOUT:     %p.param_patt: %pattern_type.b3c = value_param_pattern [concrete = constants.%p.param_patt]
// CHECK:STDOUT:     %p.patt: %pattern_type.b3c = at_binding_pattern p, %p.param_patt [concrete = constants.%p.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc16_21: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %p.param: %P.94c = value_param call_param0
// CHECK:STDOUT:     %.loc16_15: type = splice_block %P [concrete = constants.%P.94c] {
// CHECK:STDOUT:       %P.ref: %P.type = name_ref P, file.%P.decl [concrete = constants.%P.generic]
// CHECK:STDOUT:       %.loc16_11: type = type_literal bool [concrete = bool]
// CHECK:STDOUT:       %P: type = class_type @P, @P(bool) [concrete = constants.%P.94c]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %p: %P.94c = wrapper_binding p, %p.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Run.decl: %Run.type = fn_decl @Run [concrete = constants.%Run] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc23: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param0
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic class @P(%T.loc10_11.2: type) {
// CHECK:STDOUT:   %T.patt.loc10_11.2: %pattern_type.98f = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc10_11.2 (constants.%T.patt.d47)]
// CHECK:STDOUT:   %T.loc10_11.1: type = symbolic_binding T, 0 [symbolic = %T.loc10_11.1 (constants.%T.67d)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %P.Tag.type: type = fn_type @P.Tag, @P(%T.loc10_11.1) [symbolic = %P.Tag.type (constants.%P.Tag.type.7cd)]
// CHECK:STDOUT:   %P.Tag: @P.%P.Tag.type (%P.Tag.type.7cd) = struct_value () [symbolic = %P.Tag (constants.%P.Tag.bd4)]
// CHECK:STDOUT:   %P.Empty.type: type = fn_type @P.Empty, @P(%T.loc10_11.1) [symbolic = %P.Empty.type (constants.%P.Empty.type.e43)]
// CHECK:STDOUT:   %P.Empty: @P.%P.Empty.type (%P.Empty.type.e43) = struct_value () [symbolic = %P.Empty (constants.%P.Empty.cdc)]
// CHECK:STDOUT:   %P: type = class_type @P, @P(%T.loc10_11.1) [symbolic = %P (constants.%P.f86)]
// CHECK:STDOUT:   %require_complete: <witness> = require_complete_type %P [symbolic = %require_complete (constants.%require_complete.657)]
// CHECK:STDOUT:   %P.val: @P.%P (%P.f86) = struct_value (constants.%int_2.996, constants.%uninit) [symbolic = %P.val (constants.%P.val.610)]
// CHECK:STDOUT:   %.loc14_1.14: ref @P.%P (%P.f86) = temporary invalid, %P.val [symbolic = %.loc14_1.14 (constants.%.ddf)]
// CHECK:STDOUT:
// CHECK:STDOUT:   class {
// CHECK:STDOUT:     %n.param: %i32 = value_param call_param0
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %n: %i32 = wrapper_binding n, %n.param
// CHECK:STDOUT:     %.loc14_1.1: type = custom_layout_type {size=4, align=4, .Tag@0: %tuple.type.a8a} [concrete = constants.%.4d9]
// CHECK:STDOUT:     %complete_type: <witness> = complete_type_witness constants.%struct_type.discriminant.payload.677 [concrete = constants.%complete_type.0f8]
// CHECK:STDOUT:     %int_2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:     %impl.elem0.loc14_1.1: %.66c = impl_witness_access constants.%ImplicitAs.impl_witness.e93, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.409]
// CHECK:STDOUT:     %bound_method.loc14_1.1: <bound method> = bound_method %int_2, %impl.elem0.loc14_1.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.6c9]
// CHECK:STDOUT:     %specific_fn.loc14_1.1: <specific function> = specific_function %impl.elem0.loc14_1.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_2.ecc) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.a72]
// CHECK:STDOUT:     %bound_method.loc14_1.2: <bound method> = bound_method %int_2, %specific_fn.loc14_1.1 [concrete = constants.%bound_method.135]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %u2 = call %bound_method.loc14_1.2(%int_2) [concrete = constants.%int_2.996]
// CHECK:STDOUT:     %.loc14_1.2: %u2 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_2.996]
// CHECK:STDOUT:     %.loc14_1.3: %u2 = converted %int_2, %.loc14_1.2 [concrete = constants.%int_2.996]
// CHECK:STDOUT:     %.loc14_1.4: %struct_type.discriminant = struct_literal (%.loc14_1.3) [concrete = constants.%struct]
// CHECK:STDOUT:     %impl.elem0.loc14_1.2: %.594 = impl_witness_access constants.%Copy.impl_witness.f92, element0 [concrete = constants.%UInt.as.Copy.impl.Op.4d1]
// CHECK:STDOUT:     %bound_method.loc14_1.3: <bound method> = bound_method %.loc14_1.3, %impl.elem0.loc14_1.2 [concrete = constants.%UInt.as.Copy.impl.Op.bound]
// CHECK:STDOUT:     %specific_fn.loc14_1.2: <specific function> = specific_function %impl.elem0.loc14_1.2, @UInt.as.Copy.impl.Op(constants.%int_2.ecc) [concrete = constants.%UInt.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:     %bound_method.loc14_1.4: <bound method> = bound_method %.loc14_1.3, %specific_fn.loc14_1.2 [concrete = constants.%bound_method.f90]
// CHECK:STDOUT:     %UInt.as.Copy.impl.Op.call: init %u2 = call %bound_method.loc14_1.4(%.loc14_1.3) [concrete = constants.%int_2.996]
// CHECK:STDOUT:     %.loc14_1.5: ref @P.%P (%P.f86) = temporary_storage
// CHECK:STDOUT:     %.loc14_1.6: ref %u2 = class_element_access %.loc14_1.5, element0
// CHECK:STDOUT:     %.loc14_1.7: init %u2 to %.loc14_1.6 = in_place_init %UInt.as.Copy.impl.Op.call [concrete = constants.%int_2.996]
// CHECK:STDOUT:     %.loc14_1.8: ref %.4d9 = class_element_access %.loc14_1.5, element1
// CHECK:STDOUT:     %uninit: %.4d9 = uninitialized_value [concrete = constants.%uninit]
// CHECK:STDOUT:     %.loc14_1.9: init %.4d9 to %.loc14_1.8 = in_place_init %uninit [concrete = constants.%uninit]
// CHECK:STDOUT:     %.loc14_1.10: init @P.%P (%P.f86) to %.loc14_1.5 = class_init (%.loc14_1.7, %.loc14_1.9) [symbolic = %P.val (constants.%P.val.610)]
// CHECK:STDOUT:     %.loc14_1.11: init @P.%P (%P.f86) = converted %.loc14_1.4, %.loc14_1.10 [symbolic = %P.val (constants.%P.val.610)]
// CHECK:STDOUT:     %.loc14_1.12: ref @P.%P (%P.f86) = temporary %.loc14_1.5, %.loc14_1.11 [symbolic = %.loc14_1.14 (constants.%.ddf)]
// CHECK:STDOUT:     %.loc14_1.13: @P.%P (%P.f86) = acquire_value %.loc14_1.12 [symbolic = %P.val (constants.%P.val.610)]
// CHECK:STDOUT:     %None: @P.%P (%P.f86) = wrapper_binding None, %.loc14_1.13
// CHECK:STDOUT:     complete_type_witness = %complete_type
// CHECK:STDOUT:
// CHECK:STDOUT:   !members:
// CHECK:STDOUT:     .Self = constants.%P.f86
// CHECK:STDOUT:     .Tag = generated.%P.Tag.decl
// CHECK:STDOUT:     .Empty = generated.%P.Empty.decl
// CHECK:STDOUT:     .None = %None
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @P.Tag(@P.%T.loc10_11.2: type) {
// CHECK:STDOUT:   %T: type = symbolic_binding T, 0 [symbolic = %T (constants.%T.67d)]
// CHECK:STDOUT:   %P: type = class_type @P, @P(%T) [symbolic = %P (constants.%P.f86)]
// CHECK:STDOUT:   %.loc10_19.9: Core.Form = init_form %P [symbolic = %.loc10_19.9 (constants.%.3a8)]
// CHECK:STDOUT:   %pattern_type: type = pattern_type %P [symbolic = %pattern_type (constants.%pattern_type.6d3)]
// CHECK:STDOUT:   %return.param_patt.loc10_19.2: @P.Tag.%pattern_type (%pattern_type.6d3) = out_param_pattern [symbolic = %return.param_patt.loc10_19.2 (constants.%return.param_patt.3b8)]
// CHECK:STDOUT:   %return.patt.loc10_19.2: @P.Tag.%pattern_type (%pattern_type.6d3) = return_slot_pattern %return.param_patt.loc10_19.2, %P [symbolic = %return.patt.loc10_19.2 (constants.%return.patt.ec6)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete: <witness> = require_complete_type %P [symbolic = %require_complete (constants.%require_complete.657)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%_.param: %i32) -> out %return.param: @P.Tag.%P (%P.f86) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %.loc10_19.1: ref %u2 = class_element_access %return.param, element0
// CHECK:STDOUT:     %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:     %impl.elem0.loc10_19.1: %.66c = impl_witness_access constants.%ImplicitAs.impl_witness.e93, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.409]
// CHECK:STDOUT:     %bound_method.loc10_19.1: <bound method> = bound_method %int_0, %impl.elem0.loc10_19.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.941]
// CHECK:STDOUT:     %specific_fn.loc10_19.1: <specific function> = specific_function %impl.elem0.loc10_19.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_2.ecc) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.a72]
// CHECK:STDOUT:     %bound_method.loc10_19.2: <bound method> = bound_method %int_0, %specific_fn.loc10_19.1 [concrete = constants.%bound_method.6ef]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %u2 = call %bound_method.loc10_19.2(%int_0) [concrete = constants.%int_0.336]
// CHECK:STDOUT:     %.loc10_19.2: init %u2 = converted %int_0, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_0.336]
// CHECK:STDOUT:     %.loc10_19.3: init %u2 to %.loc10_19.1 = in_place_init %.loc10_19.2 [concrete = constants.%int_0.336]
// CHECK:STDOUT:     %.loc10_19.4: ref %.4d9 = class_element_access %return.param, element1
// CHECK:STDOUT:     %.loc10_19.5: ref %tuple.type.a8a = class_element_access %.loc10_19.4, element0
// CHECK:STDOUT:     %.loc11_14.1: %tuple.type.a8a = tuple_literal (%_.param)
// CHECK:STDOUT:     %impl.elem0.loc10_19.2: %.7a6 = impl_witness_access constants.%Copy.impl_witness.0e0, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:     %bound_method.loc10_19.3: <bound method> = bound_method %_.param, %impl.elem0.loc10_19.2
// CHECK:STDOUT:     %specific_fn.loc10_19.2: <specific function> = specific_function %impl.elem0.loc10_19.2, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:     %bound_method.loc10_19.4: <bound method> = bound_method %_.param, %specific_fn.loc10_19.2
// CHECK:STDOUT:     %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc10_19.4(%_.param)
// CHECK:STDOUT:     %.loc11_14.2: init %tuple.type.a8a to %.loc10_19.5 = tuple_init (%Int.as.Copy.impl.Op.call)
// CHECK:STDOUT:     %.loc10_19.6: init %tuple.type.a8a = converted %.loc11_14.1, %.loc11_14.2
// CHECK:STDOUT:     %.loc10_19.7: init %tuple.type.a8a to %.loc10_19.5 = in_place_init %.loc10_19.6
// CHECK:STDOUT:     %.loc10_19.8: init @P.Tag.%P (%P.f86) to %return.param = class_init (%.loc10_19.3, %.loc10_19.7)
// CHECK:STDOUT:     return %.loc10_19.8 to %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @P.Empty(@P.%T.loc10_11.2: type) {
// CHECK:STDOUT:   %T: type = symbolic_binding T, 0 [symbolic = %T (constants.%T.67d)]
// CHECK:STDOUT:   %P: type = class_type @P, @P(%T) [symbolic = %P (constants.%P.f86)]
// CHECK:STDOUT:   %.loc10_19.7: Core.Form = init_form %P [symbolic = %.loc10_19.7 (constants.%.3a8)]
// CHECK:STDOUT:   %pattern_type: type = pattern_type %P [symbolic = %pattern_type (constants.%pattern_type.6d3)]
// CHECK:STDOUT:   %return.param_patt.loc10_19.2: @P.Empty.%pattern_type (%pattern_type.6d3) = out_param_pattern [symbolic = %return.param_patt.loc10_19.2 (constants.%return.param_patt.3b8)]
// CHECK:STDOUT:   %return.patt.loc10_19.2: @P.Empty.%pattern_type (%pattern_type.6d3) = return_slot_pattern %return.param_patt.loc10_19.2, %P [symbolic = %return.patt.loc10_19.2 (constants.%return.patt.ec6)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %P.val: @P.Empty.%P (%P.f86) = struct_value (constants.%int_1.508, constants.%uninit) [symbolic = %P.val (constants.%P.val.b59)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn() -> out %return.param: @P.Empty.%P (%P.f86) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %.loc10_19.1: ref %u2 = class_element_access %return.param, element0
// CHECK:STDOUT:     %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:     %impl.elem0: %.66c = impl_witness_access constants.%ImplicitAs.impl_witness.e93, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.409]
// CHECK:STDOUT:     %bound_method.loc10_19.1: <bound method> = bound_method %int_1, %impl.elem0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.48e]
// CHECK:STDOUT:     %specific_fn: <specific function> = specific_function %impl.elem0, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_2.ecc) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.a72]
// CHECK:STDOUT:     %bound_method.loc10_19.2: <bound method> = bound_method %int_1, %specific_fn [concrete = constants.%bound_method.0f5]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %u2 = call %bound_method.loc10_19.2(%int_1) [concrete = constants.%int_1.508]
// CHECK:STDOUT:     %.loc10_19.2: init %u2 = converted %int_1, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_1.508]
// CHECK:STDOUT:     %.loc10_19.3: init %u2 to %.loc10_19.1 = in_place_init %.loc10_19.2 [concrete = constants.%int_1.508]
// CHECK:STDOUT:     %.loc10_19.4: ref %.4d9 = class_element_access %return.param, element1
// CHECK:STDOUT:     %uninit: %.4d9 = uninitialized_value [concrete = constants.%uninit]
// CHECK:STDOUT:     %.loc10_19.5: init %.4d9 to %.loc10_19.4 = in_place_init %uninit [concrete = constants.%uninit]
// CHECK:STDOUT:     %.loc10_19.6: init @P.Empty.%P (%P.f86) to %return.param = class_init (%.loc10_19.3, %.loc10_19.5) [symbolic = %P.val (constants.%P.val.b59)]
// CHECK:STDOUT:     return %.loc10_19.6 to %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @F(%p.param: %P.94c) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %p.ref: %P.94c = name_ref p, %p
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt: %pattern_type.b3c = expr_pattern %None.ref in [concrete] {
// CHECK:STDOUT:       %.loc18_10.2: %P.94c = specific_constant @P.%.loc14_1.13, @P(bool) [concrete = constants.%P.val.44c]
// CHECK:STDOUT:       %None.ref: %P.94c = name_ref None, %.loc18_10.2 [concrete = constants.%P.val.44c]
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %.loc18_10.1: %P.94c = splice_block %None.ref [concrete = constants.%P.val.44c] {
// CHECK:STDOUT:     %.loc18_10.2: %P.94c = specific_constant @P.%.loc14_1.13, @P(bool) [concrete = constants.%P.val.44c]
// CHECK:STDOUT:     %None.ref: %P.94c = name_ref None, %.loc18_10.2 [concrete = constants.%P.val.44c]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:   %impl.elem0.loc18_16.1: %.66c = impl_witness_access constants.%ImplicitAs.impl_witness.e93, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.409]
// CHECK:STDOUT:   %bound_method.loc18_16.1: <bound method> = bound_method %int_2, %impl.elem0.loc18_16.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.6c9]
// CHECK:STDOUT:   %specific_fn.loc18_16.1: <specific function> = specific_function %impl.elem0.loc18_16.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_2.ecc) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.a72]
// CHECK:STDOUT:   %bound_method.loc18_16.2: <bound method> = bound_method %int_2, %specific_fn.loc18_16.1 [concrete = constants.%bound_method.135]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc18_16: init %u2 = call %bound_method.loc18_16.2(%int_2) [concrete = constants.%int_2.996]
// CHECK:STDOUT:   %.loc18_16.1: %u2 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc18_16 [concrete = constants.%int_2.996]
// CHECK:STDOUT:   %.loc18_16.2: %u2 = converted %int_2, %.loc18_16.1 [concrete = constants.%int_2.996]
// CHECK:STDOUT:   %.loc18_16.3: ref %u2 = class_element_access %p.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc18_16.2: %.7a0 = impl_witness_access constants.%EqWith.impl_witness.454, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.e76]
// CHECK:STDOUT:   %bound_method.loc18_16.3: <bound method> = bound_method %.loc18_16.2, %impl.elem0.loc18_16.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound]
// CHECK:STDOUT:   %specific_fn.loc18_16.2: <specific function> = specific_function %impl.elem0.loc18_16.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_2.ecc, constants.%int_2.ecc) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.149]
// CHECK:STDOUT:   %bound_method.loc18_16.4: <bound method> = bound_method %.loc18_16.2, %specific_fn.loc18_16.2 [concrete = constants.%bound_method.64f]
// CHECK:STDOUT:   %.loc18_16.4: %u2 = acquire_value %.loc18_16.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call: init bool = call %bound_method.loc18_16.4(%.loc18_16.2, %.loc18_16.4)
// CHECK:STDOUT:   %.loc18_16.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call
// CHECK:STDOUT:   %.loc18_16.6: bool = converted %UInt.as.EqWith.impl.Equal.call, %.loc18_16.5
// CHECK:STDOUT:   if %.loc18_16.6 br !match.case.then else br !match.case.else
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then:
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc18_29: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc18_29.1: <bound method> = bound_method %int_0, %impl.elem0.loc18_29 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc18_29: <specific function> = specific_function %impl.elem0.loc18_29, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc18_29.2: <bound method> = bound_method %int_0, %specific_fn.loc18_29 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc18_29: init %i32 = call %bound_method.loc18_29.2(%int_0) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc18_29: init %i32 = converted %int_0, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc18_29 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   return %.loc18_29
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else:
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc19: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc19_26.1: <bound method> = bound_method %int_1, %impl.elem0.loc19 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc19: <specific function> = specific_function %impl.elem0.loc19, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc19_26.2: <bound method> = bound_method %int_1, %specific_fn.loc19 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc19: init %i32 = call %bound_method.loc19_26.2(%int_1) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc19: init %i32 = converted %int_1, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc19 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   return %.loc19
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Run() -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %P.ref.loc24_20: %P.type = name_ref P, file.%P.decl [concrete = constants.%P.generic]
// CHECK:STDOUT:   %.loc24_22: type = type_literal bool [concrete = bool]
// CHECK:STDOUT:   %P.loc24_26: type = class_type @P, @P(bool) [concrete = constants.%P.94c]
// CHECK:STDOUT:   %.loc24_27: %P.Tag.type.a29 = specific_constant generated.%P.Tag.decl, @P(bool) [concrete = constants.%P.Tag.de0]
// CHECK:STDOUT:   %Tag.ref: %P.Tag.type.a29 = name_ref Tag, %.loc24_27 [concrete = constants.%P.Tag.de0]
// CHECK:STDOUT:   %int_7: Core.IntLiteral = int_value 7 [concrete = constants.%int_7.29f]
// CHECK:STDOUT:   %P.Tag.specific_fn: <specific function> = specific_function %Tag.ref, @P.Tag(bool) [concrete = constants.%P.Tag.specific_fn]
// CHECK:STDOUT:   %.loc24_33.1: ref %P.94c = temporary_storage
// CHECK:STDOUT:   %impl.elem0.loc24: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc24_32.1: <bound method> = bound_method %int_7, %impl.elem0.loc24 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.66b]
// CHECK:STDOUT:   %specific_fn.loc24: <specific function> = specific_function %impl.elem0.loc24, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc24_32.2: <bound method> = bound_method %int_7, %specific_fn.loc24 [concrete = constants.%bound_method.7ff]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc24: init %i32 = call %bound_method.loc24_32.2(%int_7) [concrete = constants.%int_7.690]
// CHECK:STDOUT:   %.loc24_32.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc24 [concrete = constants.%int_7.690]
// CHECK:STDOUT:   %.loc24_32.2: %i32 = converted %int_7, %.loc24_32.1 [concrete = constants.%int_7.690]
// CHECK:STDOUT:   %P.Tag.call: init %P.f86 to %.loc24_33.1 = call %P.Tag.specific_fn(%.loc24_32.2)
// CHECK:STDOUT:   %.loc24_33.2: %P.94c = converted %P.Tag.call, <error> [concrete = <error>]
// CHECK:STDOUT:   %.loc24_16: type = splice_block %P.loc24_16 [concrete = constants.%P.94c] {
// CHECK:STDOUT:     %P.ref.loc24_10: %P.type = name_ref P, file.%P.decl [concrete = constants.%P.generic]
// CHECK:STDOUT:     %.loc24_12: type = type_literal bool [concrete = bool]
// CHECK:STDOUT:     %P.loc24_16: type = class_type @P, @P(bool) [concrete = constants.%P.94c]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %t: %P.94c = wrapper_binding t, <error> [concrete = <error>]
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %t.patt: %pattern_type.b3c = value_binding_pattern t [concrete = constants.%t.patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %P.ref.loc25_20: %P.type = name_ref P, file.%P.decl [concrete = constants.%P.generic]
// CHECK:STDOUT:   %.loc25_22: type = type_literal bool [concrete = bool]
// CHECK:STDOUT:   %P.loc25_26: type = class_type @P, @P(bool) [concrete = constants.%P.94c]
// CHECK:STDOUT:   %.loc25_27: %P.Empty.type.1bf = specific_constant generated.%P.Empty.decl, @P(bool) [concrete = constants.%P.Empty.a5f]
// CHECK:STDOUT:   %Empty.ref: %P.Empty.type.1bf = name_ref Empty, %.loc25_27 [concrete = constants.%P.Empty.a5f]
// CHECK:STDOUT:   %P.Empty.specific_fn: <specific function> = specific_function %Empty.ref, @P.Empty(bool) [concrete = constants.%P.Empty.specific_fn]
// CHECK:STDOUT:   %.loc25_34.1: ref %P.94c = temporary_storage
// CHECK:STDOUT:   %P.Empty.call: init %P.f86 to %.loc25_34.1 = call %P.Empty.specific_fn()
// CHECK:STDOUT:   %.loc25_34.2: %P.94c = converted %P.Empty.call, <error> [concrete = <error>]
// CHECK:STDOUT:   %.loc25_16: type = splice_block %P.loc25_16 [concrete = constants.%P.94c] {
// CHECK:STDOUT:     %P.ref.loc25_10: %P.type = name_ref P, file.%P.decl [concrete = constants.%P.generic]
// CHECK:STDOUT:     %.loc25_12: type = type_literal bool [concrete = bool]
// CHECK:STDOUT:     %P.loc25_16: type = class_type @P, @P(bool) [concrete = constants.%P.94c]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %e: %P.94c = wrapper_binding e, <error> [concrete = <error>]
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %e.patt: %pattern_type.b3c = value_binding_pattern e [concrete = constants.%e.patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %F.ref.loc26_10: %F.type = name_ref F, file.%F.decl [concrete = constants.%F]
// CHECK:STDOUT:   %t.ref: %P.94c = name_ref t, %t [concrete = <error>]
// CHECK:STDOUT:   %F.call.loc26_13: init %i32 = call %F.ref.loc26_10(<error>)
// CHECK:STDOUT:   %F.ref.loc26_17: %F.type = name_ref F, file.%F.decl [concrete = constants.%F]
// CHECK:STDOUT:   %e.ref: %P.94c = name_ref e, %e [concrete = <error>]
// CHECK:STDOUT:   %F.call.loc26_20: init %i32 = call %F.ref.loc26_17(<error>)
// CHECK:STDOUT:   %impl.elem1.loc26_15: %.516 = impl_witness_access constants.%AddWith.impl_witness.3af, element1 [concrete = constants.%Int.as.AddWith.impl.Op.365]
// CHECK:STDOUT:   %bound_method.loc26_15.1: <bound method> = bound_method %F.call.loc26_13, %impl.elem1.loc26_15
// CHECK:STDOUT:   %specific_fn.loc26_15: <specific function> = specific_function %impl.elem1.loc26_15, @Int.as.AddWith.impl.Op.1(constants.%int_32) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.f25]
// CHECK:STDOUT:   %bound_method.loc26_15.2: <bound method> = bound_method %F.call.loc26_13, %specific_fn.loc26_15
// CHECK:STDOUT:   %.loc26_13.1: %i32 = value_of_initializer %F.call.loc26_13
// CHECK:STDOUT:   %.loc26_13.2: %i32 = converted %F.call.loc26_13, %.loc26_13.1
// CHECK:STDOUT:   %.loc26_20.1: %i32 = value_of_initializer %F.call.loc26_20
// CHECK:STDOUT:   %.loc26_20.2: %i32 = converted %F.call.loc26_20, %.loc26_20.1
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call: init %i32 = call %bound_method.loc26_15.2(%.loc26_13.2, %.loc26_20.2)
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:   %impl.elem1.loc26_22: %.e15 = impl_witness_access constants.%SubWith.impl_witness.d78, element1 [concrete = constants.%Int.as.SubWith.impl.Op.49baee.2]
// CHECK:STDOUT:   %bound_method.loc26_22.1: <bound method> = bound_method %Int.as.AddWith.impl.Op.call, %impl.elem1.loc26_22
// CHECK:STDOUT:   %specific_fn.loc26_22: <specific function> = specific_function %impl.elem1.loc26_22, @Int.as.SubWith.impl.Op.2(constants.%int_32, constants.%ImplicitAs.facet.9f1) [concrete = constants.%Int.as.SubWith.impl.Op.specific_fn.4cc768.1]
// CHECK:STDOUT:   %bound_method.loc26_22.2: <bound method> = bound_method %Int.as.AddWith.impl.Op.call, %specific_fn.loc26_22
// CHECK:STDOUT:   %.loc26_15.1: %i32 = value_of_initializer %Int.as.AddWith.impl.Op.call
// CHECK:STDOUT:   %.loc26_15.2: %i32 = converted %Int.as.AddWith.impl.Op.call, %.loc26_15.1
// CHECK:STDOUT:   %.loc26_22: %Int.as.SubWith.impl.Op.type.745d60.1 = specific_constant imports.%Core.Op.9ff, @Int.as.SubWith.impl.dc8(constants.%int_32, constants.%ImplicitAs.facet.9f1) [concrete = constants.%Int.as.SubWith.impl.Op.49baee.1]
// CHECK:STDOUT:   %Op.ref: %Int.as.SubWith.impl.Op.type.745d60.1 = name_ref Op, %.loc26_22 [concrete = constants.%Int.as.SubWith.impl.Op.49baee.1]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.bound: <bound method> = bound_method %.loc26_15.2, %Op.ref
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.specific_fn: <specific function> = specific_function %Op.ref, @Int.as.SubWith.impl.Op.3(constants.%int_32, constants.%ImplicitAs.facet.9f1) [concrete = constants.%Int.as.SubWith.impl.Op.specific_fn.4cc768.2]
// CHECK:STDOUT:   %bound_method.loc26_22.3: <bound method> = bound_method %.loc26_15.2, %Int.as.SubWith.impl.Op.specific_fn
// CHECK:STDOUT:   %impl.elem0.loc26: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc26_24.1: <bound method> = bound_method %int_2, %impl.elem0.loc26 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.9f3]
// CHECK:STDOUT:   %specific_fn.loc26_24: <specific function> = specific_function %impl.elem0.loc26, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc26_24.2: <bound method> = bound_method %int_2, %specific_fn.loc26_24 [concrete = constants.%bound_method.3cb]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc26: init %i32 = call %bound_method.loc26_24.2(%int_2) [concrete = constants.%int_2.295]
// CHECK:STDOUT:   %.loc26_24.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc26 [concrete = constants.%int_2.295]
// CHECK:STDOUT:   %.loc26_24.2: %i32 = converted %int_2, %.loc26_24.1 [concrete = constants.%int_2.295]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.call: init %i32 = call %bound_method.loc26_22.3(%.loc26_15.2, %.loc26_24.2)
// CHECK:STDOUT:   return %Int.as.SubWith.impl.Op.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @P(constants.%T.67d) {
// CHECK:STDOUT:   %T.patt.loc10_11.2 => constants.%T.patt.d47
// CHECK:STDOUT:   %T.loc10_11.1 => constants.%T.67d
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %P.Tag.type => constants.%P.Tag.type.7cd
// CHECK:STDOUT:   %P.Tag => constants.%P.Tag.bd4
// CHECK:STDOUT:   %P.Empty.type => constants.%P.Empty.type.e43
// CHECK:STDOUT:   %P.Empty => constants.%P.Empty.cdc
// CHECK:STDOUT:   %P => constants.%P.f86
// CHECK:STDOUT:   %require_complete => constants.%require_complete.657
// CHECK:STDOUT:   %P.val => constants.%P.val.610
// CHECK:STDOUT:   %.loc14_1.14 => constants.%.ddf
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @P.Tag(constants.%T.67d) {
// CHECK:STDOUT:   %T => constants.%T.67d
// CHECK:STDOUT:   %P => constants.%P.f86
// CHECK:STDOUT:   %.loc10_19.9 => constants.%.3a8
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.6d3
// CHECK:STDOUT:   %return.param_patt.loc10_19.2 => constants.%return.param_patt.3b8
// CHECK:STDOUT:   %return.patt.loc10_19.2 => constants.%return.patt.ec6
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @P.Empty(constants.%T.67d) {
// CHECK:STDOUT:   %T => constants.%T.67d
// CHECK:STDOUT:   %P => constants.%P.f86
// CHECK:STDOUT:   %.loc10_19.7 => constants.%.3a8
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.6d3
// CHECK:STDOUT:   %return.param_patt.loc10_19.2 => constants.%return.param_patt.3b8
// CHECK:STDOUT:   %return.patt.loc10_19.2 => constants.%return.patt.ec6
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @P(bool) {
// CHECK:STDOUT:   %T.patt.loc10_11.2 => constants.%T.patt.d47
// CHECK:STDOUT:   %T.loc10_11.1 => bool
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %P.Tag.type => constants.%P.Tag.type.a29
// CHECK:STDOUT:   %P.Tag => constants.%P.Tag.de0
// CHECK:STDOUT:   %P.Empty.type => constants.%P.Empty.type.1bf
// CHECK:STDOUT:   %P.Empty => constants.%P.Empty.a5f
// CHECK:STDOUT:   %P => constants.%P.94c
// CHECK:STDOUT:   %require_complete => constants.%complete_type.0f8
// CHECK:STDOUT:   %P.val => constants.%P.val.44c
// CHECK:STDOUT:   %.loc14_1.14 => constants.%.cf7
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @P.Tag(bool) {
// CHECK:STDOUT:   %T => bool
// CHECK:STDOUT:   %P => constants.%P.94c
// CHECK:STDOUT:   %.loc10_19.9 => constants.%.744
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.b3c
// CHECK:STDOUT:   %return.param_patt.loc10_19.2 => constants.%return.param_patt.ce7
// CHECK:STDOUT:   %return.patt.loc10_19.2 => constants.%return.patt.b6f
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete => constants.%complete_type.0f8
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @P.Empty(bool) {
// CHECK:STDOUT:   %T => bool
// CHECK:STDOUT:   %P => constants.%P.94c
// CHECK:STDOUT:   %.loc10_19.7 => constants.%.744
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.b3c
// CHECK:STDOUT:   %return.param_patt.loc10_19.2 => constants.%return.param_patt.ce7
// CHECK:STDOUT:   %return.patt.loc10_19.2 => constants.%return.patt.b6f
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %P.val => constants.%P.val.695
// CHECK:STDOUT: }
// CHECK:STDOUT:
