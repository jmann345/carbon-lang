// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/choice_generic_payload_pattern.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/choice_generic_payload_pattern.carbon

// Payload destructuring on specifics of generic choices (W5-S3c,
// fork/w5-s3/plan.md §3 S3c) — everything past the S3b minimal pin
// (choice/generic_payload.carbon's destructure subfile): multi-parameter
// payloads resolved per specific, guards composing with payload bindings,
// substituted binding conversions (risk label R-7), imported generics, and
// the R-8 counterpart — destructuring from a SYMBOLIC payload tuple inside
// a generic body. Every positive match here is exhaustive without
// `default`: S2e's coverage analysis records a destructuring arm as
// covering its alternative (coverage is by alternative index, not pattern
// shape — see the recording in handle_match.cpp's `MatchCase`).

// --- multi.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
// Multi-parameter payload destructuring on concrete specifics: one
// subpattern per declared parameter, positionally, against the SUBSTITUTED
// payload tuple — `(i32, i32)` for `Pair(i32)` and `(i64, i64)` for
// `Pair(i64)`, resolved through `GetChoicePayloadInfo`'s specific-resolved
// reads at both the case check (arity) and the bind pass (element
// extraction).
choice Pair(T: type) {
  Both(x: T, y: T),
  Neither
}

fn Sum32(p: Pair(i32)) -> i32 {
  match (p) {
    case .Both(x: i32, y: i32) => { return x + y; }
    case .Neither => { return 0; }
  }
  // Unreachable: every arm returns.
  return -1;
}

fn Sum64(p: Pair(i64)) -> i64 {
  match (p) {
    case .Both(x: i64, y: i64) => { return x + y; }
    case .Neither => { return 0; }
  }
  // Unreachable: every arm returns.
  return -1;
}

fn Run() -> i32 {
  let a: Pair(i32) = Pair(i32).Both(1, 2);
  let b: Pair(i64) = Pair(i64).Both(3, 4);
  if (Sum64(b) != 7) {
    return 1;
  }
  return Sum32(a) - 3;
}
//@dump-sem-ir-end

// --- guard.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
// A guard on a payload-destructuring arm of a specific scrutinee (S2d
// composing with S3b's parameterized table rows): the arm's test compares
// the discriminant, the bind pass extracts the substituted payload and
// initializes `v`, and only then does the guard evaluate — with `v` in
// scope. A failed guard falls through to the unguarded `.Some` arm. The
// guarded arm contributes nothing to coverage, so exhaustiveness rests on
// the unguarded `.Some` and `.None` arms alone.
choice Opt(T: type) {
  Some(value: T),
  None
}

fn Sign(o: Opt(i32)) -> i32 {
  match (o) {
    case .Some(v: i32) if (v > 0) => { return v; }
    case .Some(w: i32) => { return w - 1; }
    case .None => { return -10; }
  }
  // Unreachable: every arm returns.
  return -2;
}

fn Run() -> i32 {
  let s: Opt(i32) = Opt(i32).Some(7);
  return Sign(s) - 7;
}
//@dump-sem-ir-end

// --- binding_conversion.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
// Substituted binding conversions (risk label R-7, re-derived for
// specifics): the binding's declared type differs from the substituted
// payload element type, and the bind pass converts per element — `i32`
// payload to `i64` binding through the prelude's `ImplicitAs` — with the
// conversion's temporaries deferred to the arm scope's cleanups
// (`DeferCleanups`, the S2c shape; the concrete precedent is
// choice_payload_multi.carbon). By the bind pass the specific's payload
// tuple is fully concrete, so this rides the same machinery.
choice Opt(T: type) {
  Some(value: T),
  None
}

fn Widen(o: Opt(i32)) -> i64 {
  match (o) {
    case .Some(v: i64) => { return v; }
    case .None => { return -1; }
  }
  // Unreachable: every arm returns.
  return -2;
}

fn Run() -> i32 {
  let s: Opt(i32) = Opt(i32).Some(42);
  if (Widen(s) != 42) {
    return 1;
  }
  return 0;
}
//@dump-sem-ir-end

// --- plib.carbon
library "plib";

choice P(T: type) {
  Both(x: T, y: T),
  Neither
}

// --- use_imported.carbon
library "[[@TEST_NAME]]";

import library "plib";

//@dump-sem-ir-begin
// Destructuring a specific of a generic choice declared in another
// library: the parameterized alternative's table row (name, discriminant
// index, payload field position) arrives through the class import, and the
// importing file resolves the payload region and tuple through the local
// specific (the S3b import path: canonically-minted `CustomLayoutType`
// blocks and constant-carrying alternative bindings), so both the case
// check and the bind pass read specific-resolved types here.
fn Sum(p: P(i32)) -> i32 {
  match (p) {
    case .Both(x: i32, y: i32) => { return x + y; }
    case .Neither => { return 0; }
  }
  // Unreachable: every arm returns.
  return -1;
}

fn Construct() -> i32 {
  let b: P(i32) = P(i32).Both(20, 22);
  return Sum(b) - 42;
}
//@dump-sem-ir-end

// --- symbolic.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
// The R-8 counterpart: destructuring from a SYMBOLIC payload tuple inside
// a generic body. The scrutinee gate's forced completion resolves the
// symbolic specific's definition (the completer's `ClassType` case runs
// `ResolveSpecificDefinition` even for symbolic arguments), so
// `GetChoicePayloadInfo` reads the substituted-but-symbolic payload region
// and tuple — the sentinel-layout `CustomLayoutType` and `(T, T)` — purely
// structurally, and the bind pass emits the element accesses with symbolic
// types. The payload bindings bind values of type `T` without copying
// (`let`-binding semantics); they flow into `Discard` by value for the
// same reason. Exhaustiveness is discharged symbolically too: coverage
// reads the generic's shared alternative table. Only `Call`'s concrete
// instantiation lowers.
choice P(T: type) {
  Both(x: T, y: T),
  Neither
}

fn Discard[U: type](_: U, _: U) {}

fn Classify[T: type](p: P(T)) -> i32 {
  match (p) {
    case .Both(a: T, b: T) => {
      Discard(a, b);
      return 1;
    }
    case .Neither => { return 0; }
  }
  // Unreachable: every arm returns.
  return -1;
}

fn Call(p: P(i32)) -> i32 {
  return Classify(p);
}
//@dump-sem-ir-end

// --- fail_nonexhaustive_payload.carbon
library "[[@TEST_NAME]]";

choice Pair(T: type) {
  Both(x: T, y: T),
  Neither
}

// Coverage is recorded by alternative, not pattern shape: the
// destructuring arm covers exactly `.Both`, so the missing `.Neither` is
// named. (The discharge direction — destructuring arms counting toward
// full coverage — is pinned by the exhaustive positive subfiles above.)
fn F(p: Pair(i32)) -> i32 {
  // CHECK:STDERR: fail_nonexhaustive_payload.carbon:[[@LINE+4]]:3: error: `match` on choice `Pair(i32)` has no `default` arm and does not cover alternative `.Neither` [MatchNonexhaustive]
  // CHECK:STDERR:   match (p) {
  // CHECK:STDERR:   ^~~~~~~~~~~
  // CHECK:STDERR:
  match (p) {
    case .Both(x: i32, y: i32) => { return x + y; }
  }
  return -1;
}

// CHECK:STDOUT: --- multi.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %.Self.frozen.197: %type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %pattern_type.98f: type = pattern_type type [concrete]
// CHECK:STDOUT:   %T.patt.d47: %pattern_type.98f = symbolic_binding_pattern T, 0 [symbolic]
// CHECK:STDOUT:   %T.67d: type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %Pair.type: type = generic_class_type @Pair [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
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
// CHECK:STDOUT:   %u1.builtin: type = int_type unsigned, %int_1.5b8 [concrete]
// CHECK:STDOUT:   %require_complete.9bb: <witness> = require_complete_type %Pair.66e [symbolic]
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
// CHECK:STDOUT:   %Pair.val.706: %Pair.66e = struct_value (%int_0.1a7, %uninit.216) [symbolic]
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
// CHECK:STDOUT:   %Pair.val.0a4: %Pair.66e = struct_value (%int_1.233, %uninit.216) [symbolic]
// CHECK:STDOUT:   %.f9566: ref %Pair.66e = temporary invalid, %Pair.val.0a4 [symbolic]
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
// CHECK:STDOUT:   %Sum32.type: type = fn_type @Sum32 [concrete]
// CHECK:STDOUT:   %Sum32: %Sum32.type = struct_value () [concrete]
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
// CHECK:STDOUT:   %x.patt.939: %pattern_type.6b6 = value_binding_pattern x [concrete]
// CHECK:STDOUT:   %y.patt.489: %pattern_type.6b6 = value_binding_pattern y [concrete]
// CHECK:STDOUT:   %pattern_type.394: type = pattern_type %tuple.type.e55 [concrete]
// CHECK:STDOUT:   %.692: %pattern_type.394 = tuple_pattern (%x.patt.939, %y.patt.489) [concrete]
// CHECK:STDOUT:   %EqWith.type.c25: type = facet_type <@EqWith, @EqWith(%u1)> [concrete]
// CHECK:STDOUT:   %M: Core.IntLiteral = symbolic_binding M, 1 [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.544: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%N, %M) [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.c67: %UInt.as.EqWith.impl.Equal.type.544 = struct_value () [symbolic]
// CHECK:STDOUT:   %EqWith.type.aee: type = facet_type <@EqWith, @EqWith(Core.IntLiteral)> [concrete]
// CHECK:STDOUT:   %EqWith.impl_witness.7b3: <witness> = impl_witness imports.%EqWith.impl_witness_table.166, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.29b: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.ba4: %UInt.as.EqWith.impl.Equal.type.29b = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.4d0: %EqWith.type.c25 = facet_value %u1, (%EqWith.impl_witness.7b3) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.e3c: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%u1, %EqWith.facet.4d0) [concrete]
// CHECK:STDOUT:   %.9eb: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.e3c, %EqWith.facet.4d0 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound.f34: <bound method> = bound_method %int_0.1a7, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.specific_fn.6b6: <specific function> = specific_function %UInt.as.EqWith.impl.Equal.ba4, @UInt.as.EqWith.impl.Equal.1(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.53a: <bound method> = bound_method %int_0.1a7, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
// CHECK:STDOUT:   %AddWith.type.be9: type = facet_type <@AddWith, @AddWith(%i32)> [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.610: type = fn_type @Int.as.AddWith.impl.Op.1, @Int.as.AddWith.impl.3af(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.732: %Int.as.AddWith.impl.Op.type.610 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.type.f7de31.1: type = facet_type <@ImplicitAs, @ImplicitAs(%Int.67af24.1)> [symbolic]
// CHECK:STDOUT:   %U.4e6: %ImplicitAs.type.f7de31.1 = symbolic_binding U, 1 [symbolic]
// CHECK:STDOUT:   %T.4e6: %ImplicitAs.type.f7de31.1 = symbolic_binding T, 1 [symbolic]
// CHECK:STDOUT:   %AddWith.impl_witness.833: <witness> = impl_witness imports.%AddWith.impl_witness_table.6b4, @Int.as.AddWith.impl.3af(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.056: type = fn_type @Int.as.AddWith.impl.Op.1, @Int.as.AddWith.impl.3af(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.365: %Int.as.AddWith.impl.Op.type.056 = struct_value () [concrete]
// CHECK:STDOUT:   %AddWith.facet.76a: %AddWith.type.be9 = facet_value %i32, (%AddWith.impl_witness.833) [concrete]
// CHECK:STDOUT:   %AddWith.WithSelf.Op.type.02a: type = fn_type @AddWith.WithSelf.Op, @AddWith.WithSelf(%i32, %AddWith.facet.76a) [concrete]
// CHECK:STDOUT:   %.d47: type = fn_type_with_self_type %AddWith.WithSelf.Op.type.02a, %AddWith.facet.76a [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.specific_fn.f25: <specific function> = specific_function %Int.as.AddWith.impl.Op.365, @Int.as.AddWith.impl.Op.1(%int_32) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound.22c: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
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
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %Pair.01a: type = class_type @Pair, @Pair(%i64) [concrete]
// CHECK:STDOUT:   %pattern_type.fc3: type = pattern_type %Pair.01a [concrete]
// CHECK:STDOUT:   %p.param_patt.fb6: %pattern_type.fc3 = value_param_pattern [concrete]
// CHECK:STDOUT:   %p.patt.684: %pattern_type.fc3 = at_binding_pattern p, %p.param_patt.fb6 [concrete]
// CHECK:STDOUT:   %.bc0: Core.Form = init_form %i64 [concrete]
// CHECK:STDOUT:   %pattern_type.f57: type = pattern_type %i64 [concrete]
// CHECK:STDOUT:   %return.param_patt.cfc: %pattern_type.f57 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.178: %pattern_type.f57 = return_slot_pattern %return.param_patt.cfc, %i64 [concrete]
// CHECK:STDOUT:   %Sum64.type: type = fn_type @Sum64 [concrete]
// CHECK:STDOUT:   %Sum64: %Sum64.type = struct_value () [concrete]
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
// CHECK:STDOUT:   %x.patt.73d: %pattern_type.f57 = value_binding_pattern x [concrete]
// CHECK:STDOUT:   %y.patt.676: %pattern_type.f57 = value_binding_pattern y [concrete]
// CHECK:STDOUT:   %pattern_type.037: type = pattern_type %tuple.type.1ac [concrete]
// CHECK:STDOUT:   %.73c: %pattern_type.037 = tuple_pattern (%x.patt.73d, %y.patt.676) [concrete]
// CHECK:STDOUT:   %AddWith.type.313: type = facet_type <@AddWith, @AddWith(%i64)> [concrete]
// CHECK:STDOUT:   %AddWith.impl_witness.aee: <witness> = impl_witness imports.%AddWith.impl_witness_table.6b4, @Int.as.AddWith.impl.3af(%int_64) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.6b6: type = fn_type @Int.as.AddWith.impl.Op.1, @Int.as.AddWith.impl.3af(%int_64) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.e5a: %Int.as.AddWith.impl.Op.type.6b6 = struct_value () [concrete]
// CHECK:STDOUT:   %AddWith.facet.cd2: %AddWith.type.313 = facet_value %i64, (%AddWith.impl_witness.aee) [concrete]
// CHECK:STDOUT:   %AddWith.WithSelf.Op.type.24d: type = fn_type @AddWith.WithSelf.Op, @AddWith.WithSelf(%i64, %AddWith.facet.cd2) [concrete]
// CHECK:STDOUT:   %.67a: type = fn_type_with_self_type %AddWith.WithSelf.Op.type.24d, %AddWith.facet.cd2 [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.specific_fn.f02: <specific function> = specific_function %Int.as.AddWith.impl.Op.e5a, @Int.as.AddWith.impl.Op.1(%int_64) [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.221: type = facet_type <@ImplicitAs, @ImplicitAs(%i64)> [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.227: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_64) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.55a: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_64) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.55a = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.235: %ImplicitAs.type.221 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.227) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.da7: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i64, %ImplicitAs.facet.235) [concrete]
// CHECK:STDOUT:   %.03f: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.da7, %ImplicitAs.facet.235 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.0a3: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.f33: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(%int_64) [concrete]
// CHECK:STDOUT:   %bound_method.0c1: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.f33 [concrete]
// CHECK:STDOUT:   %int_0.2e4: %i64 = int_value 0 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.bc7: <bound method> = bound_method %int_-1.638, %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b [concrete]
// CHECK:STDOUT:   %bound_method.ef0: <bound method> = bound_method %int_-1.638, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.f33 [concrete]
// CHECK:STDOUT:   %int_-1.a7e: %i64 = int_value -1 [concrete]
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
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.953: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
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
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.e9c: <bound method> = bound_method %int_3.1ba, %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b [concrete]
// CHECK:STDOUT:   %bound_method.740: <bound method> = bound_method %int_3.1ba, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.f33 [concrete]
// CHECK:STDOUT:   %int_3.bd2: %i64 = int_value 3 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.b50: <bound method> = bound_method %int_4.0c1, %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b [concrete]
// CHECK:STDOUT:   %bound_method.912: <bound method> = bound_method %int_4.0c1, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.f33 [concrete]
// CHECK:STDOUT:   %int_4.825: %i64 = int_value 4 [concrete]
// CHECK:STDOUT:   %int_7.29f: Core.IntLiteral = int_value 7 [concrete]
// CHECK:STDOUT:   %Int.as.EqWith.impl.NotEqual.type.97ec42.1: type = fn_type @Int.as.EqWith.impl.NotEqual.3, @Int.as.EqWith.impl.2b8(%N, %T.4e6) [symbolic]
// CHECK:STDOUT:   %Int.as.EqWith.impl.NotEqual.c6c584.1: %Int.as.EqWith.impl.NotEqual.type.97ec42.1 = struct_value () [symbolic]
// CHECK:STDOUT:   %Int.as.EqWith.impl.NotEqual.type.97ec42.2: type = fn_type @Int.as.EqWith.impl.NotEqual.4, @Int.as.EqWith.impl.2b8(%N, %T.4e6) [symbolic]
// CHECK:STDOUT:   %Int.as.EqWith.impl.NotEqual.c6c584.2: %Int.as.EqWith.impl.NotEqual.type.97ec42.2 = struct_value () [symbolic]
// CHECK:STDOUT:   %EqWith.impl_witness.080: <witness> = impl_witness imports.%EqWith.impl_witness_table.399, @Int.as.EqWith.impl.2b8(%int_64, %ImplicitAs.facet.235) [concrete]
// CHECK:STDOUT:   %Int.as.EqWith.impl.NotEqual.type.356690.1: type = fn_type @Int.as.EqWith.impl.NotEqual.4, @Int.as.EqWith.impl.2b8(%int_64, %ImplicitAs.facet.235) [concrete]
// CHECK:STDOUT:   %Int.as.EqWith.impl.NotEqual.6522b7.1: %Int.as.EqWith.impl.NotEqual.type.356690.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Int.as.EqWith.impl.NotEqual.type.356690.2: type = fn_type @Int.as.EqWith.impl.NotEqual.3, @Int.as.EqWith.impl.2b8(%int_64, %ImplicitAs.facet.235) [concrete]
// CHECK:STDOUT:   %Int.as.EqWith.impl.NotEqual.6522b7.2: %Int.as.EqWith.impl.NotEqual.type.356690.2 = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.401: %EqWith.type.aee = facet_value %i64, (%EqWith.impl_witness.080) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.NotEqual.type.0d6: type = fn_type @EqWith.WithSelf.NotEqual, @EqWith.WithSelf(Core.IntLiteral, %EqWith.facet.401) [concrete]
// CHECK:STDOUT:   %.446: type = fn_type_with_self_type %EqWith.WithSelf.NotEqual.type.0d6, %EqWith.facet.401 [concrete]
// CHECK:STDOUT:   %Int.as.EqWith.impl.NotEqual.specific_fn.c6b368.1: <specific function> = specific_function %Int.as.EqWith.impl.NotEqual.6522b7.2, @Int.as.EqWith.impl.NotEqual.3(%int_64, %ImplicitAs.facet.235) [concrete]
// CHECK:STDOUT:   %Int.as.EqWith.impl.NotEqual.specific_fn.c6b368.2: <specific function> = specific_function %Int.as.EqWith.impl.NotEqual.6522b7.1, @Int.as.EqWith.impl.NotEqual.4(%int_64, %ImplicitAs.facet.235) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.59d: <bound method> = bound_method %int_7.29f, %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b [concrete]
// CHECK:STDOUT:   %bound_method.9e6: <bound method> = bound_method %int_7.29f, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.f33 [concrete]
// CHECK:STDOUT:   %int_7.824: %i64 = int_value 7 [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.8: type = fn_type @Destroy.Op.loc35_41.8 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.8: %Destroy.Op.type.1d8f74.8 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.14: type = fn_type @Destroy.Op.loc34_41.6 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.14: %Destroy.Op.type.1d8f74.14 = struct_value () [concrete]
// CHECK:STDOUT:   %SubWith.type.4c2: type = facet_type <@SubWith, @SubWith(Core.IntLiteral)> [concrete]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.type.6f3321.1: type = fn_type @Int.as.SubWith.impl.Op.2, @Int.as.SubWith.impl.dc8(%N, %U.4e6) [symbolic]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.a37528.1: %Int.as.SubWith.impl.Op.type.6f3321.1 = struct_value () [symbolic]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.type.6f3321.2: type = fn_type @Int.as.SubWith.impl.Op.3, @Int.as.SubWith.impl.dc8(%N, %U.4e6) [symbolic]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.a37528.2: %Int.as.SubWith.impl.Op.type.6f3321.2 = struct_value () [symbolic]
// CHECK:STDOUT:   %SubWith.impl_witness.447: <witness> = impl_witness imports.%SubWith.impl_witness_table.038, @Int.as.SubWith.impl.dc8(%int_32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.type.657f13.1: type = fn_type @Int.as.SubWith.impl.Op.3, @Int.as.SubWith.impl.dc8(%int_32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.fa84b9.1: %Int.as.SubWith.impl.Op.type.657f13.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.type.657f13.2: type = fn_type @Int.as.SubWith.impl.Op.2, @Int.as.SubWith.impl.dc8(%int_32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.fa84b9.2: %Int.as.SubWith.impl.Op.type.657f13.2 = struct_value () [concrete]
// CHECK:STDOUT:   %SubWith.facet.775: %SubWith.type.4c2 = facet_value %i32, (%SubWith.impl_witness.447) [concrete]
// CHECK:STDOUT:   %SubWith.WithSelf.Op.type.d32: type = fn_type @SubWith.WithSelf.Op, @SubWith.WithSelf(Core.IntLiteral, %SubWith.facet.775) [concrete]
// CHECK:STDOUT:   %.ae9: type = fn_type_with_self_type %SubWith.WithSelf.Op.type.d32, %SubWith.facet.775 [concrete]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.specific_fn.13b586.1: <specific function> = specific_function %Int.as.SubWith.impl.Op.fa84b9.2, @Int.as.SubWith.impl.Op.2(%int_32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.specific_fn.13b586.2: <specific function> = specific_function %Int.as.SubWith.impl.Op.fa84b9.1, @Int.as.SubWith.impl.Op.3(%int_32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.485: <bound method> = bound_method %int_3.1ba, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.763: <bound method> = bound_method %int_3.1ba, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_3.410: %i32 = int_value 3 [concrete]
// CHECK:STDOUT:   %Pair.val.cf1: %Pair.1ee = struct_value (%int_0.1a7, %uninit.525) [concrete]
// CHECK:STDOUT:   %Pair.val.790: %Pair.01a = struct_value (%int_0.1a7, %uninit.ccc) [concrete]
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
// CHECK:STDOUT:   %Core.import_ref.b4fd3a.1 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.684: @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op.type (%Int.as.AddWith.impl.Op.type.610) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op (constants.%Int.as.AddWith.impl.Op.732)]
// CHECK:STDOUT:   %AddWith.impl_witness_table.6b4 = impl_witness_table (%Core.import_ref.b4fd3a.1, %Core.import_ref.684), @Int.as.AddWith.impl.3af [concrete]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.abd = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9c3: %Core.IntLiteral.as.Negate.impl.Op.type = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, loaded [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %Negate.impl_witness_table = impl_witness_table (%Core.import_ref.abd, %Core.import_ref.9c3), @Core.IntLiteral.as.Negate.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.7a7 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.fb5: @Int.as.EqWith.impl.2b8.%Int.as.EqWith.impl.NotEqual.type.2 (%Int.as.EqWith.impl.NotEqual.type.97ec42.1) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.EqWith.impl.2b8.%Int.as.EqWith.impl.NotEqual.2 (constants.%Int.as.EqWith.impl.NotEqual.c6c584.1)]
// CHECK:STDOUT:   %EqWith.impl_witness_table.399 = impl_witness_table (%Core.import_ref.7a7, %Core.import_ref.fb5), @Int.as.EqWith.impl.2b8 [concrete]
// CHECK:STDOUT:   %Core.NotEqual.c83: @Int.as.EqWith.impl.2b8.%Int.as.EqWith.impl.NotEqual.type.1 (%Int.as.EqWith.impl.NotEqual.type.97ec42.2) = import_ref Core//prelude/types/int, NotEqual, loaded [symbolic = @Int.as.EqWith.impl.2b8.%Int.as.EqWith.impl.NotEqual.1 (constants.%Int.as.EqWith.impl.NotEqual.c6c584.2)]
// CHECK:STDOUT:   %Core.import_ref.b4fd3a.5 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.6fa: @Int.as.SubWith.impl.dc8.%Int.as.SubWith.impl.Op.type.2 (%Int.as.SubWith.impl.Op.type.6f3321.1) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.SubWith.impl.dc8.%Int.as.SubWith.impl.Op.2 (constants.%Int.as.SubWith.impl.Op.a37528.1)]
// CHECK:STDOUT:   %SubWith.impl_witness_table.038 = impl_witness_table (%Core.import_ref.b4fd3a.5, %Core.import_ref.6fa), @Int.as.SubWith.impl.dc8 [concrete]
// CHECK:STDOUT:   %Core.Op.9ff: @Int.as.SubWith.impl.dc8.%Int.as.SubWith.impl.Op.type.1 (%Int.as.SubWith.impl.Op.type.6f3321.2) = import_ref Core//prelude/types/int, Op, loaded [symbolic = @Int.as.SubWith.impl.dc8.%Int.as.SubWith.impl.Op.1 (constants.%Int.as.SubWith.impl.Op.a37528.2)]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %Pair.Both.decl: @Pair.%Pair.Both.type (%Pair.Both.type.9e9) = fn_decl @Pair.Both [symbolic = @Pair.%Pair.Both (constants.%Pair.Both.4cf)] {
// CHECK:STDOUT:     %_.param_patt.loc10_22.1: @Pair.Both.%pattern_type.loc10_22.1 (%pattern_type.51d1c4.1) = value_param_pattern [symbolic = %_.param_patt.loc10_22.3 (constants.%_.param_patt.339)]
// CHECK:STDOUT:     %_.patt.loc10_22.1: @Pair.Both.%pattern_type.loc10_22.1 (%pattern_type.51d1c4.1) = at_binding_pattern _, %_.param_patt.loc10_22.1 [symbolic = %_.patt.loc10_22.3 (constants.%_.patt.fd3)]
// CHECK:STDOUT:     %_.param_patt.loc10_22.2: @Pair.Both.%pattern_type.loc10_22.1 (%pattern_type.51d1c4.1) = value_param_pattern [symbolic = %_.param_patt.loc10_22.3 (constants.%_.param_patt.339)]
// CHECK:STDOUT:     %_.patt.loc10_22.2: @Pair.Both.%pattern_type.loc10_22.1 (%pattern_type.51d1c4.1) = at_binding_pattern _, %_.param_patt.loc10_22.2 [symbolic = %_.patt.loc10_22.3 (constants.%_.patt.fd3)]
// CHECK:STDOUT:     %return.param_patt.loc10_22.1: @Pair.Both.%pattern_type.loc10_22.2 (%pattern_type.b6c) = out_param_pattern [symbolic = %return.param_patt.loc10_22.2 (constants.%return.param_patt.4f6)]
// CHECK:STDOUT:     %return.patt.loc10_22.1: @Pair.Both.%pattern_type.loc10_22.2 (%pattern_type.b6c) = return_slot_pattern %return.param_patt.loc10_22.1, %Pair.loc10_22.2 [symbolic = %return.patt.loc10_22.2 (constants.%return.patt.8b5)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %Pair.loc10_22.2: type = class_type @Pair, @Pair(constants.%T.67d) [symbolic = %Pair.loc10_22.1 (constants.%Pair.66e)]
// CHECK:STDOUT:     %.loc10_22.11: Core.Form = init_form %Pair.loc10_22.2 [symbolic = %.loc10_22.9 (constants.%.f65)]
// CHECK:STDOUT:     %_.param.loc10_22.1: @Pair.Both.%T (%T.67d) = value_param call_param0
// CHECK:STDOUT:     %_.loc10_22.1: @Pair.Both.%T (%T.67d) = wrapper_binding _, %_.param.loc10_22.1
// CHECK:STDOUT:     %_.param.loc10_22.2: @Pair.Both.%T (%T.67d) = value_param call_param1
// CHECK:STDOUT:     %_.loc10_22.2: @Pair.Both.%T (%T.67d) = wrapper_binding _, %_.param.loc10_22.2
// CHECK:STDOUT:     %return.param: ref @Pair.Both.%Pair.loc10_22.1 (%Pair.66e) = out_param call_param2
// CHECK:STDOUT:     %return: ref @Pair.Both.%Pair.loc10_22.1 (%Pair.66e) = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Pair.decl: %Pair.type = class_decl @Pair [concrete = constants.%Pair.generic] {
// CHECK:STDOUT:     %T.patt.loc10_14.1: %pattern_type.98f = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc10_14.2 (constants.%T.patt.d47)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc10_16.1: type = splice_block %.loc10_16.2 [concrete = type] {
// CHECK:STDOUT:       %.Self.frozen: %type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen.197]
// CHECK:STDOUT:       %.loc10_16.2: type = type_literal type [concrete = type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc10_14.2: type = symbolic_binding T, 0 [symbolic = %T.loc10_14.1 (constants.%T.67d)]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Sum32.decl: %Sum32.type = fn_decl @Sum32 [concrete = constants.%Sum32] {
// CHECK:STDOUT:     %p.param_patt: %pattern_type.b73 = value_param_pattern [concrete = constants.%p.param_patt.b74]
// CHECK:STDOUT:     %p.patt: %pattern_type.b73 = at_binding_pattern p, %p.param_patt [concrete = constants.%p.patt.fb2]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc15_27 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc15_27: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc15_27: Core.Form = init_form %i32.loc15_27 [concrete = constants.%.795f]
// CHECK:STDOUT:     %p.param: %Pair.1ee = value_param call_param0
// CHECK:STDOUT:     %.loc15_21: type = splice_block %Pair [concrete = constants.%Pair.1ee] {
// CHECK:STDOUT:       %Pair.ref: %Pair.type = name_ref Pair, file.%Pair.decl [concrete = constants.%Pair.generic]
// CHECK:STDOUT:       %i32.loc15_18: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %Pair: type = class_type @Pair, @Pair(constants.%i32) [concrete = constants.%Pair.1ee]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %p: %Pair.1ee = wrapper_binding p, %p.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Sum64.decl: %Sum64.type = fn_decl @Sum64 [concrete = constants.%Sum64] {
// CHECK:STDOUT:     %p.param_patt: %pattern_type.fc3 = value_param_pattern [concrete = constants.%p.param_patt.fb6]
// CHECK:STDOUT:     %p.patt: %pattern_type.fc3 = at_binding_pattern p, %p.param_patt [concrete = constants.%p.patt.684]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.f57 = out_param_pattern [concrete = constants.%return.param_patt.cfc]
// CHECK:STDOUT:     %return.patt: %pattern_type.f57 = return_slot_pattern %return.param_patt, %i64.loc24_27 [concrete = constants.%return.patt.178]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i64.loc24_27: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:     %.loc24_27: Core.Form = init_form %i64.loc24_27 [concrete = constants.%.bc0]
// CHECK:STDOUT:     %p.param: %Pair.01a = value_param call_param0
// CHECK:STDOUT:     %.loc24_21: type = splice_block %Pair [concrete = constants.%Pair.01a] {
// CHECK:STDOUT:       %Pair.ref: %Pair.type = name_ref Pair, file.%Pair.decl [concrete = constants.%Pair.generic]
// CHECK:STDOUT:       %i64.loc24_18: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:       %Pair: type = class_type @Pair, @Pair(constants.%i64) [concrete = constants.%Pair.01a]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %p: %Pair.01a = wrapper_binding p, %p.param
// CHECK:STDOUT:     %return.param: ref %i64 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i64 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Run.decl: %Run.type = fn_decl @Run [concrete = constants.%Run] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc33 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc33: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc33: Core.Form = init_form %i32.loc33 [concrete = constants.%.795f]
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param0
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic class @Pair(%T.loc10_14.2: type) {
// CHECK:STDOUT:   %T.patt.loc10_14.2: %pattern_type.98f = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc10_14.2 (constants.%T.patt.d47)]
// CHECK:STDOUT:   %T.loc10_14.1: type = symbolic_binding T, 0 [symbolic = %T.loc10_14.1 (constants.%T.67d)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %pattern_type: type = pattern_type %T.loc10_14.1 [symbolic = %pattern_type (constants.%pattern_type.51d1c4.1)]
// CHECK:STDOUT:   %x.param_patt: @Pair.%pattern_type (%pattern_type.51d1c4.1) = value_param_pattern [symbolic = %x.param_patt (constants.%x.param_patt.91d)]
// CHECK:STDOUT:   %x.patt: @Pair.%pattern_type (%pattern_type.51d1c4.1) = at_binding_pattern x, %x.param_patt [symbolic = %x.patt (constants.%x.patt.800)]
// CHECK:STDOUT:   %y.param_patt: @Pair.%pattern_type (%pattern_type.51d1c4.1) = value_param_pattern [symbolic = %y.param_patt (constants.%y.param_patt.be3)]
// CHECK:STDOUT:   %y.patt: @Pair.%pattern_type (%pattern_type.51d1c4.1) = at_binding_pattern y, %y.param_patt [symbolic = %y.patt (constants.%y.patt.b85)]
// CHECK:STDOUT:   %require_complete.loc11: <witness> = require_complete_type %T.loc10_14.1 [symbolic = %require_complete.loc11 (constants.%require_complete.944)]
// CHECK:STDOUT:   %tuple.type: type = tuple_type (%T.loc10_14.1, %T.loc10_14.1) [symbolic = %tuple.type (constants.%tuple.type.07a)]
// CHECK:STDOUT:   %.loc13_1.14: type = custom_layout_type {size=0, align=0, .Both@0: @Pair.%tuple.type (%tuple.type.07a)} [symbolic = %.loc13_1.14 (constants.%.d27)]
// CHECK:STDOUT:   %struct_type.discriminant.payload: type = struct_type {.discriminant: %u1, .payload: @Pair.%.loc13_1.14 (%.d27)} [symbolic = %struct_type.discriminant.payload (constants.%struct_type.discriminant.payload.1ec)]
// CHECK:STDOUT:   %complete_type.loc13_1.2: <witness> = complete_type_witness %struct_type.discriminant.payload [symbolic = %complete_type.loc13_1.2 (constants.%complete_type.d2c)]
// CHECK:STDOUT:   %Pair.Both.type: type = fn_type @Pair.Both, @Pair(%T.loc10_14.1) [symbolic = %Pair.Both.type (constants.%Pair.Both.type.9e9)]
// CHECK:STDOUT:   %Pair.Both: @Pair.%Pair.Both.type (%Pair.Both.type.9e9) = struct_value () [symbolic = %Pair.Both (constants.%Pair.Both.4cf)]
// CHECK:STDOUT:   %Pair: type = class_type @Pair, @Pair(%T.loc10_14.1) [symbolic = %Pair (constants.%Pair.66e)]
// CHECK:STDOUT:   %require_complete.loc13: <witness> = require_complete_type %Pair [symbolic = %require_complete.loc13 (constants.%require_complete.9bb)]
// CHECK:STDOUT:   %uninit.loc13_1.2: @Pair.%.loc13_1.14 (%.d27) = uninitialized_value [symbolic = %uninit.loc13_1.2 (constants.%uninit.216)]
// CHECK:STDOUT:   %Pair.val: @Pair.%Pair (%Pair.66e) = struct_value (constants.%int_1.233, %uninit.loc13_1.2) [symbolic = %Pair.val (constants.%Pair.val.0a4)]
// CHECK:STDOUT:   %.loc13_1.15: ref @Pair.%Pair (%Pair.66e) = temporary invalid, %Pair.val [symbolic = %.loc13_1.15 (constants.%.f9566)]
// CHECK:STDOUT:
// CHECK:STDOUT:   class {
// CHECK:STDOUT:     %x.param: @Pair.%T.loc10_14.1 (%T.67d) = value_param call_param0
// CHECK:STDOUT:     %T.ref.loc11_11: type = name_ref T, %T.loc10_14.2 [symbolic = %T.loc10_14.1 (constants.%T.67d)]
// CHECK:STDOUT:     %x: @Pair.%T.loc10_14.1 (%T.67d) = wrapper_binding x, %x.param
// CHECK:STDOUT:     %y.param: @Pair.%T.loc10_14.1 (%T.67d) = value_param call_param1
// CHECK:STDOUT:     %T.ref.loc11_17: type = name_ref T, %T.loc10_14.2 [symbolic = %T.loc10_14.1 (constants.%T.67d)]
// CHECK:STDOUT:     %y: @Pair.%T.loc10_14.1 (%T.67d) = wrapper_binding y, %y.param
// CHECK:STDOUT:     %.loc13_1.1: type = custom_layout_type {size=0, align=0, .Both@0: %tuple.type.07a} [symbolic = %.loc13_1.14 (constants.%.d27)]
// CHECK:STDOUT:     %complete_type.loc13_1.1: <witness> = complete_type_witness constants.%struct_type.discriminant.payload.1ec [symbolic = %complete_type.loc13_1.2 (constants.%complete_type.d2c)]
// CHECK:STDOUT:     %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:     %impl.elem0.loc13_1.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:     %bound_method.loc13_1.1: <bound method> = bound_method %int_1, %impl.elem0.loc13_1.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:     %specific_fn.loc13_1.1: <specific function> = specific_function %impl.elem0.loc13_1.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:     %bound_method.loc13_1.2: <bound method> = bound_method %int_1, %specific_fn.loc13_1.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %u1 = call %bound_method.loc13_1.2(%int_1) [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc13_1.2: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc13_1.3: %u1 = converted %int_1, %.loc13_1.2 [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc13_1.4: %struct_type.discriminant = struct_literal (%.loc13_1.3) [concrete = constants.%struct]
// CHECK:STDOUT:     %impl.elem0.loc13_1.2: %.952 = impl_witness_access constants.%Copy.impl_witness.334, element0 [concrete = constants.%UInt.as.Copy.impl.Op.d9c]
// CHECK:STDOUT:     %bound_method.loc13_1.3: <bound method> = bound_method %.loc13_1.3, %impl.elem0.loc13_1.2 [concrete = constants.%UInt.as.Copy.impl.Op.bound]
// CHECK:STDOUT:     %specific_fn.loc13_1.2: <specific function> = specific_function %impl.elem0.loc13_1.2, @UInt.as.Copy.impl.Op(constants.%int_1.5b8) [concrete = constants.%UInt.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:     %bound_method.loc13_1.4: <bound method> = bound_method %.loc13_1.3, %specific_fn.loc13_1.2 [concrete = constants.%bound_method.edd]
// CHECK:STDOUT:     %UInt.as.Copy.impl.Op.call: init %u1 = call %bound_method.loc13_1.4(%.loc13_1.3) [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc13_1.5: ref @Pair.%Pair (%Pair.66e) = temporary_storage
// CHECK:STDOUT:     %.loc13_1.6: ref %u1 = class_element_access %.loc13_1.5, element0
// CHECK:STDOUT:     %.loc13_1.7: init %u1 to %.loc13_1.6 = in_place_init %UInt.as.Copy.impl.Op.call [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc13_1.8: ref @Pair.%.loc13_1.14 (%.d27) = class_element_access %.loc13_1.5, element1
// CHECK:STDOUT:     %uninit.loc13_1.1: @Pair.%.loc13_1.14 (%.d27) = uninitialized_value [symbolic = %uninit.loc13_1.2 (constants.%uninit.216)]
// CHECK:STDOUT:     %.loc13_1.9: init @Pair.%.loc13_1.14 (%.d27) to %.loc13_1.8 = in_place_init %uninit.loc13_1.1 [symbolic = %uninit.loc13_1.2 (constants.%uninit.216)]
// CHECK:STDOUT:     %.loc13_1.10: init @Pair.%Pair (%Pair.66e) to %.loc13_1.5 = class_init (%.loc13_1.7, %.loc13_1.9) [symbolic = %Pair.val (constants.%Pair.val.0a4)]
// CHECK:STDOUT:     %.loc13_1.11: init @Pair.%Pair (%Pair.66e) = converted %.loc13_1.4, %.loc13_1.10 [symbolic = %Pair.val (constants.%Pair.val.0a4)]
// CHECK:STDOUT:     %.loc13_1.12: ref @Pair.%Pair (%Pair.66e) = temporary %.loc13_1.5, %.loc13_1.11 [symbolic = %.loc13_1.15 (constants.%.f9566)]
// CHECK:STDOUT:     %.loc13_1.13: @Pair.%Pair (%Pair.66e) = acquire_value %.loc13_1.12 [symbolic = %Pair.val (constants.%Pair.val.0a4)]
// CHECK:STDOUT:     %Neither: @Pair.%Pair (%Pair.66e) = wrapper_binding Neither, %.loc13_1.13
// CHECK:STDOUT:     complete_type_witness = %complete_type.loc13_1.1
// CHECK:STDOUT:
// CHECK:STDOUT:   !members:
// CHECK:STDOUT:     .Self = constants.%Pair.66e
// CHECK:STDOUT:     .T = <poisoned>
// CHECK:STDOUT:     .Both = generated.%Pair.Both.decl
// CHECK:STDOUT:     .Neither = %Neither
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @Pair.Both(@Pair.%T.loc10_14.2: type) {
// CHECK:STDOUT:   %T: type = symbolic_binding T, 0 [symbolic = %T (constants.%T.67d)]
// CHECK:STDOUT:   %pattern_type.loc10_22.1: type = pattern_type %T [symbolic = %pattern_type.loc10_22.1 (constants.%pattern_type.51d1c4.1)]
// CHECK:STDOUT:   %_.param_patt.loc10_22.3: @Pair.Both.%pattern_type.loc10_22.1 (%pattern_type.51d1c4.1) = value_param_pattern [symbolic = %_.param_patt.loc10_22.3 (constants.%_.param_patt.339)]
// CHECK:STDOUT:   %_.patt.loc10_22.3: @Pair.Both.%pattern_type.loc10_22.1 (%pattern_type.51d1c4.1) = at_binding_pattern _, %_.param_patt.loc10_22.3 [symbolic = %_.patt.loc10_22.3 (constants.%_.patt.fd3)]
// CHECK:STDOUT:   %Pair.loc10_22.1: type = class_type @Pair, @Pair(%T) [symbolic = %Pair.loc10_22.1 (constants.%Pair.66e)]
// CHECK:STDOUT:   %.loc10_22.9: Core.Form = init_form %Pair.loc10_22.1 [symbolic = %.loc10_22.9 (constants.%.f65)]
// CHECK:STDOUT:   %pattern_type.loc10_22.2: type = pattern_type %Pair.loc10_22.1 [symbolic = %pattern_type.loc10_22.2 (constants.%pattern_type.b6c)]
// CHECK:STDOUT:   %return.param_patt.loc10_22.2: @Pair.Both.%pattern_type.loc10_22.2 (%pattern_type.b6c) = out_param_pattern [symbolic = %return.param_patt.loc10_22.2 (constants.%return.param_patt.4f6)]
// CHECK:STDOUT:   %return.patt.loc10_22.2: @Pair.Both.%pattern_type.loc10_22.2 (%pattern_type.b6c) = return_slot_pattern %return.param_patt.loc10_22.2, %Pair.loc10_22.1 [symbolic = %return.patt.loc10_22.2 (constants.%return.patt.8b5)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc10_22.1: <witness> = require_complete_type %T [symbolic = %require_complete.loc10_22.1 (constants.%require_complete.944)]
// CHECK:STDOUT:   %require_complete.loc10_22.2: <witness> = require_complete_type %Pair.loc10_22.1 [symbolic = %require_complete.loc10_22.2 (constants.%require_complete.9bb)]
// CHECK:STDOUT:   %tuple.type: type = tuple_type (%T, %T) [symbolic = %tuple.type (constants.%tuple.type.07a)]
// CHECK:STDOUT:   %.loc10_22.10: type = custom_layout_type {size=0, align=0, .Both@0: @Pair.Both.%tuple.type (%tuple.type.07a)} [symbolic = %.loc10_22.10 (constants.%.d27)]
// CHECK:STDOUT:   %uninit.loc10_22.2: @Pair.Both.%.loc10_22.10 (%.d27) = uninitialized_value [symbolic = %uninit.loc10_22.2 (constants.%uninit.216)]
// CHECK:STDOUT:   %Pair.val: @Pair.Both.%Pair.loc10_22.1 (%Pair.66e) = struct_value (constants.%int_0.1a7, %uninit.loc10_22.2) [symbolic = %Pair.val (constants.%Pair.val.706)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%_.param.loc10_22.1: @Pair.Both.%T (%T.67d), %_.param.loc10_22.2: @Pair.Both.%T (%T.67d)) -> out %return.param: @Pair.Both.%Pair.loc10_22.1 (%Pair.66e) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %.loc10_22.1: ref %u1 = class_element_access %return.param, element0
// CHECK:STDOUT:     %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:     %impl.elem0: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:     %bound_method.loc10_22.1: <bound method> = bound_method %int_0, %impl.elem0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:     %specific_fn: <specific function> = specific_function %impl.elem0, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:     %bound_method.loc10_22.2: <bound method> = bound_method %int_0, %specific_fn [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %u1 = call %bound_method.loc10_22.2(%int_0) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:     %.loc10_22.2: init %u1 = converted %int_0, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:     %.loc10_22.3: init %u1 to %.loc10_22.1 = in_place_init %.loc10_22.2 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:     %.loc10_22.4: ref @Pair.Both.%.loc10_22.10 (%.d27) = class_element_access %return.param, element1
// CHECK:STDOUT:     %.loc10_22.5: ref @Pair.Both.%tuple.type (%tuple.type.07a) = class_element_access %.loc10_22.4, element0
// CHECK:STDOUT:     %.loc11_19.1: init @Pair.Both.%tuple.type (%tuple.type.07a) to %.loc10_22.5 = tuple_init (%_.param.loc10_22.1, %_.param.loc10_22.2)
// CHECK:STDOUT:     %uninit.loc10_22.1: @Pair.Both.%.loc10_22.10 (%.d27) = uninitialized_value [symbolic = %uninit.loc10_22.2 (constants.%uninit.216)]
// CHECK:STDOUT:     %.loc10_22.6: init @Pair.Both.%.loc10_22.10 (%.d27) to %.loc10_22.4 = in_place_init %uninit.loc10_22.1 [symbolic = %uninit.loc10_22.2 (constants.%uninit.216)]
// CHECK:STDOUT:     %.loc10_22.7: init @Pair.Both.%Pair.loc10_22.1 (%Pair.66e) to %return.param = class_init (%.loc10_22.3, %.loc10_22.6) [symbolic = %Pair.val (constants.%Pair.val.706)]
// CHECK:STDOUT:     %.loc10_22.8: init @Pair.Both.%Pair.loc10_22.1 (%Pair.66e) = update_init %.loc10_22.7, %.loc11_19.1
// CHECK:STDOUT:     %tuple.elem0: ref @Pair.Both.%T (%T.67d) = tuple_access %.loc10_22.5, element0
// CHECK:STDOUT:     %.loc11_19.2: init @Pair.Both.%T (%T.67d) to %tuple.elem0 = in_place_init %_.param.loc10_22.1
// CHECK:STDOUT:     %tuple.elem1: ref @Pair.Both.%T (%T.67d) = tuple_access %.loc10_22.5, element1
// CHECK:STDOUT:     %.loc11_19.3: init @Pair.Both.%T (%T.67d) to %tuple.elem1 = in_place_init %_.param.loc10_22.2
// CHECK:STDOUT:     return %.loc10_22.8 to %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Sum32(%p.param: %Pair.1ee) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %p.ref: %Pair.1ee = name_ref p, %p
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %x.patt: %pattern_type.6b6 = value_binding_pattern x [concrete = constants.%x.patt.939]
// CHECK:STDOUT:     %y.patt: %pattern_type.6b6 = value_binding_pattern y [concrete = constants.%y.patt.489]
// CHECK:STDOUT:     %.loc17_30: %pattern_type.394 = tuple_pattern (%x.patt, %y.patt) [concrete = constants.%.692]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_0.loc17: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc17_32.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc17_32.1: <bound method> = bound_method %int_0.loc17, %impl.elem0.loc17_32.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:   %specific_fn.loc17_32.1: <specific function> = specific_function %impl.elem0.loc17_32.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc17_32.2: <bound method> = bound_method %int_0.loc17, %specific_fn.loc17_32.1 [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc17: init %u1 = call %bound_method.loc17_32.2(%int_0.loc17) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc17_32.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc17 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc17_32.2: %u1 = converted %int_0.loc17, %.loc17_32.1 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc17_32.3: ref %u1 = class_element_access %p.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc17_32.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc17_32.3: <bound method> = bound_method %.loc17_32.2, %impl.elem0.loc17_32.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.f34]
// CHECK:STDOUT:   %specific_fn.loc17_32.2: <specific function> = specific_function %impl.elem0.loc17_32.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc17_32.4: <bound method> = bound_method %.loc17_32.2, %specific_fn.loc17_32.2 [concrete = constants.%bound_method.53a]
// CHECK:STDOUT:   %.loc17_32.4: %u1 = acquire_value %.loc17_32.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc17: init bool = call %bound_method.loc17_32.4(%.loc17_32.2, %.loc17_32.4)
// CHECK:STDOUT:   %.loc17_32.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc17
// CHECK:STDOUT:   %.loc17_32.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc17, %.loc17_32.5
// CHECK:STDOUT:   if %.loc17_32.6 br !match.case.then.loc17 else br !match.case.else.loc17
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc17:
// CHECK:STDOUT:   %.loc17_32.7: ref %.20c = class_element_access %p.ref, element1
// CHECK:STDOUT:   %.loc17_32.8: ref %tuple.type.e55 = class_element_access %.loc17_32.7, element0
// CHECK:STDOUT:   %tuple.elem0: ref %i32 = tuple_access %.loc17_32.8, element0
// CHECK:STDOUT:   %tuple.elem1: ref %i32 = tuple_access %.loc17_32.8, element1
// CHECK:STDOUT:   %.loc17_32.9: %i32 = acquire_value %tuple.elem0
// CHECK:STDOUT:   %i32.loc17_19: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %x: %i32 = wrapper_binding x, %.loc17_32.9
// CHECK:STDOUT:   %.loc17_32.10: %i32 = acquire_value %tuple.elem1
// CHECK:STDOUT:   %i32.loc17_27: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %y: %i32 = wrapper_binding y, %.loc17_32.10
// CHECK:STDOUT:   %x.ref: %i32 = name_ref x, %x
// CHECK:STDOUT:   %y.ref: %i32 = name_ref y, %y
// CHECK:STDOUT:   %impl.elem1.loc17: %.d47 = impl_witness_access constants.%AddWith.impl_witness.833, element1 [concrete = constants.%Int.as.AddWith.impl.Op.365]
// CHECK:STDOUT:   %bound_method.loc17_46.1: <bound method> = bound_method %x.ref, %impl.elem1.loc17
// CHECK:STDOUT:   %specific_fn.loc17_46: <specific function> = specific_function %impl.elem1.loc17, @Int.as.AddWith.impl.Op.1(constants.%int_32) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.f25]
// CHECK:STDOUT:   %bound_method.loc17_46.2: <bound method> = bound_method %x.ref, %specific_fn.loc17_46
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call: init %i32 = call %bound_method.loc17_46.2(%x.ref, %y.ref)
// CHECK:STDOUT:   return %Int.as.AddWith.impl.Op.call
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc17:
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt: %pattern_type.b73 = expr_pattern %Neither.ref in [concrete] {
// CHECK:STDOUT:       %.loc18_10.2: %Pair.1ee = specific_constant @Pair.%.loc13_1.13, @Pair(constants.%i32) [concrete = constants.%Pair.val.6e7]
// CHECK:STDOUT:       %Neither.ref: %Pair.1ee = name_ref Neither, %.loc18_10.2 [concrete = constants.%Pair.val.6e7]
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %.loc18_10.1: %Pair.1ee = splice_block %Neither.ref [concrete = constants.%Pair.val.6e7] {
// CHECK:STDOUT:     %.loc18_10.2: %Pair.1ee = specific_constant @Pair.%.loc13_1.13, @Pair(constants.%i32) [concrete = constants.%Pair.val.6e7]
// CHECK:STDOUT:     %Neither.ref: %Pair.1ee = name_ref Neither, %.loc18_10.2 [concrete = constants.%Pair.val.6e7]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_1.loc18: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc18_19.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc18_19.1: <bound method> = bound_method %int_1.loc18, %impl.elem0.loc18_19.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc18_19.1: <specific function> = specific_function %impl.elem0.loc18_19.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc18_19.2: <bound method> = bound_method %int_1.loc18, %specific_fn.loc18_19.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc18_19: init %u1 = call %bound_method.loc18_19.2(%int_1.loc18) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc18_19.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc18_19 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc18_19.2: %u1 = converted %int_1.loc18, %.loc18_19.1 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc18_19.3: ref %u1 = class_element_access %p.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc18_19.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc18_19.3: <bound method> = bound_method %.loc18_19.2, %impl.elem0.loc18_19.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.22c]
// CHECK:STDOUT:   %specific_fn.loc18_19.2: <specific function> = specific_function %impl.elem0.loc18_19.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc18_19.4: <bound method> = bound_method %.loc18_19.2, %specific_fn.loc18_19.2 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc18_19.4: %u1 = acquire_value %.loc18_19.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc18: init bool = call %bound_method.loc18_19.4(%.loc18_19.2, %.loc18_19.4)
// CHECK:STDOUT:   %.loc18_19.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc18
// CHECK:STDOUT:   %.loc18_19.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc18, %.loc18_19.5
// CHECK:STDOUT:   if %.loc18_19.6 br !match.case.then.loc18 else br !match.case.else.loc18
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc18:
// CHECK:STDOUT:   %int_0.loc18: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc18_32: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc18_32.1: <bound method> = bound_method %int_0.loc18, %impl.elem0.loc18_32 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc18_32: <specific function> = specific_function %impl.elem0.loc18_32, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc18_32.2: <bound method> = bound_method %int_0.loc18, %specific_fn.loc18_32 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc18_32: init %i32 = call %bound_method.loc18_32.2(%int_0.loc18) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc18_32: init %i32 = converted %int_0.loc18, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc18_32 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   return %.loc18_32
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc18:
// CHECK:STDOUT:   br !match.done
// CHECK:STDOUT:
// CHECK:STDOUT: !match.done:
// CHECK:STDOUT:   %int_1.loc21: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem1.loc21: %.758 = impl_witness_access constants.%Negate.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %bound_method.loc21_10: <bound method> = bound_method %int_1.loc21, %impl.elem1.loc21 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op.bound]
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
// CHECK:STDOUT: fn @Sum64(%p.param: %Pair.01a) -> out %return.param: %i64 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %p.ref: %Pair.01a = name_ref p, %p
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %x.patt: %pattern_type.f57 = value_binding_pattern x [concrete = constants.%x.patt.73d]
// CHECK:STDOUT:     %y.patt: %pattern_type.f57 = value_binding_pattern y [concrete = constants.%y.patt.676]
// CHECK:STDOUT:     %.loc26_30: %pattern_type.037 = tuple_pattern (%x.patt, %y.patt) [concrete = constants.%.73c]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_0.loc26: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc26_32.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc26_32.1: <bound method> = bound_method %int_0.loc26, %impl.elem0.loc26_32.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:   %specific_fn.loc26_32.1: <specific function> = specific_function %impl.elem0.loc26_32.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc26_32.2: <bound method> = bound_method %int_0.loc26, %specific_fn.loc26_32.1 [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc26: init %u1 = call %bound_method.loc26_32.2(%int_0.loc26) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc26_32.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc26 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc26_32.2: %u1 = converted %int_0.loc26, %.loc26_32.1 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc26_32.3: ref %u1 = class_element_access %p.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc26_32.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc26_32.3: <bound method> = bound_method %.loc26_32.2, %impl.elem0.loc26_32.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.f34]
// CHECK:STDOUT:   %specific_fn.loc26_32.2: <specific function> = specific_function %impl.elem0.loc26_32.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc26_32.4: <bound method> = bound_method %.loc26_32.2, %specific_fn.loc26_32.2 [concrete = constants.%bound_method.53a]
// CHECK:STDOUT:   %.loc26_32.4: %u1 = acquire_value %.loc26_32.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc26: init bool = call %bound_method.loc26_32.4(%.loc26_32.2, %.loc26_32.4)
// CHECK:STDOUT:   %.loc26_32.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc26
// CHECK:STDOUT:   %.loc26_32.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc26, %.loc26_32.5
// CHECK:STDOUT:   if %.loc26_32.6 br !match.case.then.loc26 else br !match.case.else.loc26
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc26:
// CHECK:STDOUT:   %.loc26_32.7: ref %.58e = class_element_access %p.ref, element1
// CHECK:STDOUT:   %.loc26_32.8: ref %tuple.type.1ac = class_element_access %.loc26_32.7, element0
// CHECK:STDOUT:   %tuple.elem0: ref %i64 = tuple_access %.loc26_32.8, element0
// CHECK:STDOUT:   %tuple.elem1: ref %i64 = tuple_access %.loc26_32.8, element1
// CHECK:STDOUT:   %.loc26_32.9: %i64 = acquire_value %tuple.elem0
// CHECK:STDOUT:   %i64.loc26_19: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:   %x: %i64 = wrapper_binding x, %.loc26_32.9
// CHECK:STDOUT:   %.loc26_32.10: %i64 = acquire_value %tuple.elem1
// CHECK:STDOUT:   %i64.loc26_27: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:   %y: %i64 = wrapper_binding y, %.loc26_32.10
// CHECK:STDOUT:   %x.ref: %i64 = name_ref x, %x
// CHECK:STDOUT:   %y.ref: %i64 = name_ref y, %y
// CHECK:STDOUT:   %impl.elem1.loc26: %.67a = impl_witness_access constants.%AddWith.impl_witness.aee, element1 [concrete = constants.%Int.as.AddWith.impl.Op.e5a]
// CHECK:STDOUT:   %bound_method.loc26_46.1: <bound method> = bound_method %x.ref, %impl.elem1.loc26
// CHECK:STDOUT:   %specific_fn.loc26_46: <specific function> = specific_function %impl.elem1.loc26, @Int.as.AddWith.impl.Op.1(constants.%int_64) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.f02]
// CHECK:STDOUT:   %bound_method.loc26_46.2: <bound method> = bound_method %x.ref, %specific_fn.loc26_46
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call: init %i64 = call %bound_method.loc26_46.2(%x.ref, %y.ref)
// CHECK:STDOUT:   return %Int.as.AddWith.impl.Op.call
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc26:
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt: %pattern_type.fc3 = expr_pattern %Neither.ref in [concrete] {
// CHECK:STDOUT:       %.loc27_10.2: %Pair.01a = specific_constant @Pair.%.loc13_1.13, @Pair(constants.%i64) [concrete = constants.%Pair.val.765]
// CHECK:STDOUT:       %Neither.ref: %Pair.01a = name_ref Neither, %.loc27_10.2 [concrete = constants.%Pair.val.765]
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %.loc27_10.1: %Pair.01a = splice_block %Neither.ref [concrete = constants.%Pair.val.765] {
// CHECK:STDOUT:     %.loc27_10.2: %Pair.01a = specific_constant @Pair.%.loc13_1.13, @Pair(constants.%i64) [concrete = constants.%Pair.val.765]
// CHECK:STDOUT:     %Neither.ref: %Pair.01a = name_ref Neither, %.loc27_10.2 [concrete = constants.%Pair.val.765]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_1.loc27: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc27_19.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc27_19.1: <bound method> = bound_method %int_1.loc27, %impl.elem0.loc27_19.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc27_19.1: <specific function> = specific_function %impl.elem0.loc27_19.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc27_19.2: <bound method> = bound_method %int_1.loc27, %specific_fn.loc27_19.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc27_19: init %u1 = call %bound_method.loc27_19.2(%int_1.loc27) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc27_19.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc27_19 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc27_19.2: %u1 = converted %int_1.loc27, %.loc27_19.1 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc27_19.3: ref %u1 = class_element_access %p.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc27_19.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc27_19.3: <bound method> = bound_method %.loc27_19.2, %impl.elem0.loc27_19.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.22c]
// CHECK:STDOUT:   %specific_fn.loc27_19.2: <specific function> = specific_function %impl.elem0.loc27_19.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc27_19.4: <bound method> = bound_method %.loc27_19.2, %specific_fn.loc27_19.2 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc27_19.4: %u1 = acquire_value %.loc27_19.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc27: init bool = call %bound_method.loc27_19.4(%.loc27_19.2, %.loc27_19.4)
// CHECK:STDOUT:   %.loc27_19.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc27
// CHECK:STDOUT:   %.loc27_19.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc27, %.loc27_19.5
// CHECK:STDOUT:   if %.loc27_19.6 br !match.case.then.loc27 else br !match.case.else.loc27
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc27:
// CHECK:STDOUT:   %int_0.loc27: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc27_32: %.03f = impl_witness_access constants.%ImplicitAs.impl_witness.227, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b]
// CHECK:STDOUT:   %bound_method.loc27_32.1: <bound method> = bound_method %int_0.loc27, %impl.elem0.loc27_32 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.0a3]
// CHECK:STDOUT:   %specific_fn.loc27_32: <specific function> = specific_function %impl.elem0.loc27_32, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.f33]
// CHECK:STDOUT:   %bound_method.loc27_32.2: <bound method> = bound_method %int_0.loc27, %specific_fn.loc27_32 [concrete = constants.%bound_method.0c1]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc27_32: init %i64 = call %bound_method.loc27_32.2(%int_0.loc27) [concrete = constants.%int_0.2e4]
// CHECK:STDOUT:   %.loc27_32: init %i64 = converted %int_0.loc27, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc27_32 [concrete = constants.%int_0.2e4]
// CHECK:STDOUT:   return %.loc27_32
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc27:
// CHECK:STDOUT:   br !match.done
// CHECK:STDOUT:
// CHECK:STDOUT: !match.done:
// CHECK:STDOUT:   %int_1.loc30: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem1.loc30: %.758 = impl_witness_access constants.%Negate.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %bound_method.loc30_10: <bound method> = bound_method %int_1.loc30, %impl.elem1.loc30 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op.bound]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.call: init Core.IntLiteral = call %bound_method.loc30_10(%int_1.loc30) [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %impl.elem0.loc30: %.03f = impl_witness_access constants.%ImplicitAs.impl_witness.227, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b]
// CHECK:STDOUT:   %bound_method.loc30_12.1: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %impl.elem0.loc30 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.bc7]
// CHECK:STDOUT:   %specific_fn.loc30: <specific function> = specific_function %impl.elem0.loc30, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.f33]
// CHECK:STDOUT:   %bound_method.loc30_12.2: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %specific_fn.loc30 [concrete = constants.%bound_method.ef0]
// CHECK:STDOUT:   %.loc30_10.1: Core.IntLiteral = value_of_initializer %Core.IntLiteral.as.Negate.impl.Op.call [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %.loc30_10.2: Core.IntLiteral = converted %Core.IntLiteral.as.Negate.impl.Op.call, %.loc30_10.1 [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc30: init %i64 = call %bound_method.loc30_12.2(%.loc30_10.2) [concrete = constants.%int_-1.a7e]
// CHECK:STDOUT:   %.loc30_12: init %i64 = converted %Core.IntLiteral.as.Negate.impl.Op.call, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc30 [concrete = constants.%int_-1.a7e]
// CHECK:STDOUT:   return %.loc30_12
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Run() -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Pair.ref.loc34_22: %Pair.type = name_ref Pair, file.%Pair.decl [concrete = constants.%Pair.generic]
// CHECK:STDOUT:   %i32.loc34_27: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %Pair.loc34_30: type = class_type @Pair, @Pair(constants.%i32) [concrete = constants.%Pair.1ee]
// CHECK:STDOUT:   %.loc34_31: %Pair.Both.type.9d6 = specific_constant generated.%Pair.Both.decl, @Pair(constants.%i32) [concrete = constants.%Pair.Both.c82]
// CHECK:STDOUT:   %Both.ref.loc34: %Pair.Both.type.9d6 = name_ref Both, %.loc34_31 [concrete = constants.%Pair.Both.c82]
// CHECK:STDOUT:   %int_1.loc34: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:   %Pair.Both.specific_fn.loc34: <specific function> = specific_function %Both.ref.loc34, @Pair.Both(constants.%i32) [concrete = constants.%Pair.Both.specific_fn.212]
// CHECK:STDOUT:   %.loc34_41.1: ref %Pair.1ee = temporary_storage
// CHECK:STDOUT:   %impl.elem0.loc34_37: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc34_37.1: <bound method> = bound_method %int_1.loc34, %impl.elem0.loc34_37 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc34_37: <specific function> = specific_function %impl.elem0.loc34_37, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc34_37.2: <bound method> = bound_method %int_1.loc34, %specific_fn.loc34_37 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc34_37: init %i32 = call %bound_method.loc34_37.2(%int_1.loc34) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc34_37.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc34_37 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc34_37.2: %i32 = converted %int_1.loc34, %.loc34_37.1 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %impl.elem0.loc34_40: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc34_40.1: <bound method> = bound_method %int_2, %impl.elem0.loc34_40 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.9f3]
// CHECK:STDOUT:   %specific_fn.loc34_40: <specific function> = specific_function %impl.elem0.loc34_40, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc34_40.2: <bound method> = bound_method %int_2, %specific_fn.loc34_40 [concrete = constants.%bound_method.3cb]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc34_40: init %i32 = call %bound_method.loc34_40.2(%int_2) [concrete = constants.%int_2.295]
// CHECK:STDOUT:   %.loc34_40.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc34_40 [concrete = constants.%int_2.295]
// CHECK:STDOUT:   %.loc34_40.2: %i32 = converted %int_2, %.loc34_40.1 [concrete = constants.%int_2.295]
// CHECK:STDOUT:   %Pair.Both.call.loc34: init %Pair.1ee to %.loc34_41.1 = call %Pair.Both.specific_fn.loc34(%.loc34_37.2, %.loc34_40.2)
// CHECK:STDOUT:   %.loc34_41.2: ref %Pair.1ee = temporary %.loc34_41.1, %Pair.Both.call.loc34
// CHECK:STDOUT:   %.loc34_41.3: %Pair.1ee = acquire_value %.loc34_41.2
// CHECK:STDOUT:   %.loc34_18: type = splice_block %Pair.loc34_18 [concrete = constants.%Pair.1ee] {
// CHECK:STDOUT:     %Pair.ref.loc34_10: %Pair.type = name_ref Pair, file.%Pair.decl [concrete = constants.%Pair.generic]
// CHECK:STDOUT:     %i32.loc34_15: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %Pair.loc34_18: type = class_type @Pair, @Pair(constants.%i32) [concrete = constants.%Pair.1ee]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %a: %Pair.1ee = wrapper_binding a, %.loc34_41.3
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %a.patt: %pattern_type.b73 = value_binding_pattern a [concrete = constants.%a.patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Pair.ref.loc35_22: %Pair.type = name_ref Pair, file.%Pair.decl [concrete = constants.%Pair.generic]
// CHECK:STDOUT:   %i64.loc35_27: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:   %Pair.loc35_30: type = class_type @Pair, @Pair(constants.%i64) [concrete = constants.%Pair.01a]
// CHECK:STDOUT:   %.loc35_31: %Pair.Both.type.1a5 = specific_constant generated.%Pair.Both.decl, @Pair(constants.%i64) [concrete = constants.%Pair.Both.56a]
// CHECK:STDOUT:   %Both.ref.loc35: %Pair.Both.type.1a5 = name_ref Both, %.loc35_31 [concrete = constants.%Pair.Both.56a]
// CHECK:STDOUT:   %int_3.loc35: Core.IntLiteral = int_value 3 [concrete = constants.%int_3.1ba]
// CHECK:STDOUT:   %int_4: Core.IntLiteral = int_value 4 [concrete = constants.%int_4.0c1]
// CHECK:STDOUT:   %Pair.Both.specific_fn.loc35: <specific function> = specific_function %Both.ref.loc35, @Pair.Both(constants.%i64) [concrete = constants.%Pair.Both.specific_fn.471]
// CHECK:STDOUT:   %.loc35_41.1: ref %Pair.01a = temporary_storage
// CHECK:STDOUT:   %impl.elem0.loc35_37: %.03f = impl_witness_access constants.%ImplicitAs.impl_witness.227, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b]
// CHECK:STDOUT:   %bound_method.loc35_37.1: <bound method> = bound_method %int_3.loc35, %impl.elem0.loc35_37 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.e9c]
// CHECK:STDOUT:   %specific_fn.loc35_37: <specific function> = specific_function %impl.elem0.loc35_37, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.f33]
// CHECK:STDOUT:   %bound_method.loc35_37.2: <bound method> = bound_method %int_3.loc35, %specific_fn.loc35_37 [concrete = constants.%bound_method.740]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc35_37: init %i64 = call %bound_method.loc35_37.2(%int_3.loc35) [concrete = constants.%int_3.bd2]
// CHECK:STDOUT:   %.loc35_37.1: %i64 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc35_37 [concrete = constants.%int_3.bd2]
// CHECK:STDOUT:   %.loc35_37.2: %i64 = converted %int_3.loc35, %.loc35_37.1 [concrete = constants.%int_3.bd2]
// CHECK:STDOUT:   %impl.elem0.loc35_40: %.03f = impl_witness_access constants.%ImplicitAs.impl_witness.227, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b]
// CHECK:STDOUT:   %bound_method.loc35_40.1: <bound method> = bound_method %int_4, %impl.elem0.loc35_40 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.b50]
// CHECK:STDOUT:   %specific_fn.loc35_40: <specific function> = specific_function %impl.elem0.loc35_40, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.f33]
// CHECK:STDOUT:   %bound_method.loc35_40.2: <bound method> = bound_method %int_4, %specific_fn.loc35_40 [concrete = constants.%bound_method.912]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc35_40: init %i64 = call %bound_method.loc35_40.2(%int_4) [concrete = constants.%int_4.825]
// CHECK:STDOUT:   %.loc35_40.1: %i64 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc35_40 [concrete = constants.%int_4.825]
// CHECK:STDOUT:   %.loc35_40.2: %i64 = converted %int_4, %.loc35_40.1 [concrete = constants.%int_4.825]
// CHECK:STDOUT:   %Pair.Both.call.loc35: init %Pair.01a to %.loc35_41.1 = call %Pair.Both.specific_fn.loc35(%.loc35_37.2, %.loc35_40.2)
// CHECK:STDOUT:   %.loc35_41.2: ref %Pair.01a = temporary %.loc35_41.1, %Pair.Both.call.loc35
// CHECK:STDOUT:   %.loc35_41.3: %Pair.01a = acquire_value %.loc35_41.2
// CHECK:STDOUT:   %.loc35_18: type = splice_block %Pair.loc35_18 [concrete = constants.%Pair.01a] {
// CHECK:STDOUT:     %Pair.ref.loc35_10: %Pair.type = name_ref Pair, file.%Pair.decl [concrete = constants.%Pair.generic]
// CHECK:STDOUT:     %i64.loc35_15: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:     %Pair.loc35_18: type = class_type @Pair, @Pair(constants.%i64) [concrete = constants.%Pair.01a]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %b: %Pair.01a = wrapper_binding b, %.loc35_41.3
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %b.patt: %pattern_type.fc3 = value_binding_pattern b [concrete = constants.%b.patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Sum64.ref: %Sum64.type = name_ref Sum64, file.%Sum64.decl [concrete = constants.%Sum64]
// CHECK:STDOUT:   %b.ref: %Pair.01a = name_ref b, %b
// CHECK:STDOUT:   %Sum64.call: init %i64 = call %Sum64.ref(%b.ref)
// CHECK:STDOUT:   %int_7: Core.IntLiteral = int_value 7 [concrete = constants.%int_7.29f]
// CHECK:STDOUT:   %impl.elem1.loc36: %.446 = impl_witness_access constants.%EqWith.impl_witness.080, element1 [concrete = constants.%Int.as.EqWith.impl.NotEqual.6522b7.2]
// CHECK:STDOUT:   %bound_method.loc36_16.1: <bound method> = bound_method %Sum64.call, %impl.elem1.loc36
// CHECK:STDOUT:   %specific_fn.loc36_16: <specific function> = specific_function %impl.elem1.loc36, @Int.as.EqWith.impl.NotEqual.3(constants.%int_64, constants.%ImplicitAs.facet.235) [concrete = constants.%Int.as.EqWith.impl.NotEqual.specific_fn.c6b368.1]
// CHECK:STDOUT:   %bound_method.loc36_16.2: <bound method> = bound_method %Sum64.call, %specific_fn.loc36_16
// CHECK:STDOUT:   %.loc36_14.1: %i64 = value_of_initializer %Sum64.call
// CHECK:STDOUT:   %.loc36_14.2: %i64 = converted %Sum64.call, %.loc36_14.1
// CHECK:STDOUT:   %.loc36_16: %Int.as.EqWith.impl.NotEqual.type.356690.1 = specific_constant imports.%Core.NotEqual.c83, @Int.as.EqWith.impl.2b8(constants.%int_64, constants.%ImplicitAs.facet.235) [concrete = constants.%Int.as.EqWith.impl.NotEqual.6522b7.1]
// CHECK:STDOUT:   %NotEqual.ref: %Int.as.EqWith.impl.NotEqual.type.356690.1 = name_ref NotEqual, %.loc36_16 [concrete = constants.%Int.as.EqWith.impl.NotEqual.6522b7.1]
// CHECK:STDOUT:   %Int.as.EqWith.impl.NotEqual.bound: <bound method> = bound_method %.loc36_14.2, %NotEqual.ref
// CHECK:STDOUT:   %Int.as.EqWith.impl.NotEqual.specific_fn: <specific function> = specific_function %NotEqual.ref, @Int.as.EqWith.impl.NotEqual.4(constants.%int_64, constants.%ImplicitAs.facet.235) [concrete = constants.%Int.as.EqWith.impl.NotEqual.specific_fn.c6b368.2]
// CHECK:STDOUT:   %bound_method.loc36_16.3: <bound method> = bound_method %.loc36_14.2, %Int.as.EqWith.impl.NotEqual.specific_fn
// CHECK:STDOUT:   %impl.elem0.loc36: %.03f = impl_witness_access constants.%ImplicitAs.impl_witness.227, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b]
// CHECK:STDOUT:   %bound_method.loc36_19.1: <bound method> = bound_method %int_7, %impl.elem0.loc36 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.59d]
// CHECK:STDOUT:   %specific_fn.loc36_19: <specific function> = specific_function %impl.elem0.loc36, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.f33]
// CHECK:STDOUT:   %bound_method.loc36_19.2: <bound method> = bound_method %int_7, %specific_fn.loc36_19 [concrete = constants.%bound_method.9e6]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc36: init %i64 = call %bound_method.loc36_19.2(%int_7) [concrete = constants.%int_7.824]
// CHECK:STDOUT:   %.loc36_19.1: %i64 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc36 [concrete = constants.%int_7.824]
// CHECK:STDOUT:   %.loc36_19.2: %i64 = converted %int_7, %.loc36_19.1 [concrete = constants.%int_7.824]
// CHECK:STDOUT:   %Int.as.EqWith.impl.NotEqual.call: init bool = call %bound_method.loc36_16.3(%.loc36_14.2, %.loc36_19.2)
// CHECK:STDOUT:   %.loc36_20.1: bool = value_of_initializer %Int.as.EqWith.impl.NotEqual.call
// CHECK:STDOUT:   %.loc36_20.2: bool = converted %Int.as.EqWith.impl.NotEqual.call, %.loc36_20.1
// CHECK:STDOUT:   if %.loc36_20.2 br !if.then else br !if.else
// CHECK:STDOUT:
// CHECK:STDOUT: !if.then:
// CHECK:STDOUT:   %int_1.loc37: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc37: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc37_13.1: <bound method> = bound_method %int_1.loc37, %impl.elem0.loc37 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc37: <specific function> = specific_function %impl.elem0.loc37, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc37_13.2: <bound method> = bound_method %int_1.loc37, %specific_fn.loc37 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc37: init %i32 = call %bound_method.loc37_13.2(%int_1.loc37) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc37: init %i32 = converted %int_1.loc37, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc37 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %Destroy.Op.bound.loc35_41.1: <bound method> = bound_method %.loc35_41.2, constants.%Destroy.Op.1a2547.8
// CHECK:STDOUT:   %Destroy.Op.call.loc35_41.1: init %empty_tuple.type = call %Destroy.Op.bound.loc35_41.1(%.loc35_41.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc34_41.1: <bound method> = bound_method %.loc34_41.2, constants.%Destroy.Op.1a2547.14
// CHECK:STDOUT:   %Destroy.Op.call.loc34_41.1: init %empty_tuple.type = call %Destroy.Op.bound.loc34_41.1(%.loc34_41.2)
// CHECK:STDOUT:   return %.loc37
// CHECK:STDOUT:
// CHECK:STDOUT: !if.else:
// CHECK:STDOUT:   %Sum32.ref: %Sum32.type = name_ref Sum32, file.%Sum32.decl [concrete = constants.%Sum32]
// CHECK:STDOUT:   %a.ref: %Pair.1ee = name_ref a, %a
// CHECK:STDOUT:   %Sum32.call: init %i32 = call %Sum32.ref(%a.ref)
// CHECK:STDOUT:   %int_3.loc39: Core.IntLiteral = int_value 3 [concrete = constants.%int_3.1ba]
// CHECK:STDOUT:   %impl.elem1.loc39: %.ae9 = impl_witness_access constants.%SubWith.impl_witness.447, element1 [concrete = constants.%Int.as.SubWith.impl.Op.fa84b9.2]
// CHECK:STDOUT:   %bound_method.loc39_19.1: <bound method> = bound_method %Sum32.call, %impl.elem1.loc39
// CHECK:STDOUT:   %specific_fn.loc39_19: <specific function> = specific_function %impl.elem1.loc39, @Int.as.SubWith.impl.Op.2(constants.%int_32, constants.%ImplicitAs.facet.48f) [concrete = constants.%Int.as.SubWith.impl.Op.specific_fn.13b586.1]
// CHECK:STDOUT:   %bound_method.loc39_19.2: <bound method> = bound_method %Sum32.call, %specific_fn.loc39_19
// CHECK:STDOUT:   %.loc39_17.1: %i32 = value_of_initializer %Sum32.call
// CHECK:STDOUT:   %.loc39_17.2: %i32 = converted %Sum32.call, %.loc39_17.1
// CHECK:STDOUT:   %.loc39_19: %Int.as.SubWith.impl.Op.type.657f13.1 = specific_constant imports.%Core.Op.9ff, @Int.as.SubWith.impl.dc8(constants.%int_32, constants.%ImplicitAs.facet.48f) [concrete = constants.%Int.as.SubWith.impl.Op.fa84b9.1]
// CHECK:STDOUT:   %Op.ref: %Int.as.SubWith.impl.Op.type.657f13.1 = name_ref Op, %.loc39_19 [concrete = constants.%Int.as.SubWith.impl.Op.fa84b9.1]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.bound: <bound method> = bound_method %.loc39_17.2, %Op.ref
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.specific_fn: <specific function> = specific_function %Op.ref, @Int.as.SubWith.impl.Op.3(constants.%int_32, constants.%ImplicitAs.facet.48f) [concrete = constants.%Int.as.SubWith.impl.Op.specific_fn.13b586.2]
// CHECK:STDOUT:   %bound_method.loc39_19.3: <bound method> = bound_method %.loc39_17.2, %Int.as.SubWith.impl.Op.specific_fn
// CHECK:STDOUT:   %impl.elem0.loc39: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc39_21.1: <bound method> = bound_method %int_3.loc39, %impl.elem0.loc39 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.485]
// CHECK:STDOUT:   %specific_fn.loc39_21: <specific function> = specific_function %impl.elem0.loc39, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc39_21.2: <bound method> = bound_method %int_3.loc39, %specific_fn.loc39_21 [concrete = constants.%bound_method.763]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc39: init %i32 = call %bound_method.loc39_21.2(%int_3.loc39) [concrete = constants.%int_3.410]
// CHECK:STDOUT:   %.loc39_21.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc39 [concrete = constants.%int_3.410]
// CHECK:STDOUT:   %.loc39_21.2: %i32 = converted %int_3.loc39, %.loc39_21.1 [concrete = constants.%int_3.410]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.call: init %i32 = call %bound_method.loc39_19.3(%.loc39_17.2, %.loc39_21.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc35_41.2: <bound method> = bound_method %.loc35_41.2, constants.%Destroy.Op.1a2547.8
// CHECK:STDOUT:   %Destroy.Op.call.loc35_41.2: init %empty_tuple.type = call %Destroy.Op.bound.loc35_41.2(%.loc35_41.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc34_41.2: <bound method> = bound_method %.loc34_41.2, constants.%Destroy.Op.1a2547.14
// CHECK:STDOUT:   %Destroy.Op.call.loc34_41.2: init %empty_tuple.type = call %Destroy.Op.bound.loc34_41.2(%.loc34_41.2)
// CHECK:STDOUT:   return %Int.as.SubWith.impl.Op.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc35_41.1(%self.param: ref %u1.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc35_41.2(%self.param: ref %u1) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc35_41.3(%self.param: ref %i64.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc35_41.4(%self.param: ref %i64) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc35_41.5(%self.param: ref %tuple.type.1ac) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc35_41.6(%self.param: ref %.58e) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc35_41.7(%self.param: ref %struct_type.discriminant.payload.8ac) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc35_41.8(%self.param: ref %Pair.01a) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc34_41.1(%self.param: ref %i32.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc34_41.2(%self.param: ref %i32) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc34_41.3(%self.param: ref %tuple.type.e55) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc34_41.4(%self.param: ref %.20c) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc34_41.5(%self.param: ref %struct_type.discriminant.payload.92c) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc34_41.6(%self.param: ref %Pair.1ee) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Pair(constants.%T.67d) {
// CHECK:STDOUT:   %T.patt.loc10_14.2 => constants.%T.patt.d47
// CHECK:STDOUT:   %T.loc10_14.1 => constants.%T.67d
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Pair.Both(constants.%T.67d) {
// CHECK:STDOUT:   %T => constants.%T.67d
// CHECK:STDOUT:   %pattern_type.loc10_22.1 => constants.%pattern_type.51d1c4.1
// CHECK:STDOUT:   %_.param_patt.loc10_22.3 => constants.%_.param_patt.339
// CHECK:STDOUT:   %_.patt.loc10_22.3 => constants.%_.patt.fd3
// CHECK:STDOUT:   %Pair.loc10_22.1 => constants.%Pair.66e
// CHECK:STDOUT:   %.loc10_22.9 => constants.%.f65
// CHECK:STDOUT:   %pattern_type.loc10_22.2 => constants.%pattern_type.b6c
// CHECK:STDOUT:   %return.param_patt.loc10_22.2 => constants.%return.param_patt.4f6
// CHECK:STDOUT:   %return.patt.loc10_22.2 => constants.%return.patt.8b5
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Pair(constants.%i32) {
// CHECK:STDOUT:   %T.patt.loc10_14.2 => constants.%T.patt.d47
// CHECK:STDOUT:   %T.loc10_14.1 => constants.%i32
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.6b6
// CHECK:STDOUT:   %x.param_patt => constants.%x.param_patt.cee
// CHECK:STDOUT:   %x.patt => constants.%x.patt.fbe
// CHECK:STDOUT:   %y.param_patt => constants.%y.param_patt.673
// CHECK:STDOUT:   %y.patt => constants.%y.patt.b43
// CHECK:STDOUT:   %require_complete.loc11 => constants.%complete_type.f8a
// CHECK:STDOUT:   %tuple.type => constants.%tuple.type.e55
// CHECK:STDOUT:   %.loc13_1.14 => constants.%.20c
// CHECK:STDOUT:   %struct_type.discriminant.payload => constants.%struct_type.discriminant.payload.92c
// CHECK:STDOUT:   %complete_type.loc13_1.2 => constants.%complete_type.ea6
// CHECK:STDOUT:   %Pair.Both.type => constants.%Pair.Both.type.9d6
// CHECK:STDOUT:   %Pair.Both => constants.%Pair.Both.c82
// CHECK:STDOUT:   %Pair => constants.%Pair.1ee
// CHECK:STDOUT:   %require_complete.loc13 => constants.%complete_type.ea6
// CHECK:STDOUT:   %uninit.loc13_1.2 => constants.%uninit.525
// CHECK:STDOUT:   %Pair.val => constants.%Pair.val.6e7
// CHECK:STDOUT:   %.loc13_1.15 => constants.%.343
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Pair(constants.%i64) {
// CHECK:STDOUT:   %T.patt.loc10_14.2 => constants.%T.patt.d47
// CHECK:STDOUT:   %T.loc10_14.1 => constants.%i64
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.f57
// CHECK:STDOUT:   %x.param_patt => constants.%x.param_patt.7b8
// CHECK:STDOUT:   %x.patt => constants.%x.patt.451
// CHECK:STDOUT:   %y.param_patt => constants.%y.param_patt.83d
// CHECK:STDOUT:   %y.patt => constants.%y.patt.d31
// CHECK:STDOUT:   %require_complete.loc11 => constants.%complete_type.4a1
// CHECK:STDOUT:   %tuple.type => constants.%tuple.type.1ac
// CHECK:STDOUT:   %.loc13_1.14 => constants.%.58e
// CHECK:STDOUT:   %struct_type.discriminant.payload => constants.%struct_type.discriminant.payload.8ac
// CHECK:STDOUT:   %complete_type.loc13_1.2 => constants.%complete_type.ab0
// CHECK:STDOUT:   %Pair.Both.type => constants.%Pair.Both.type.1a5
// CHECK:STDOUT:   %Pair.Both => constants.%Pair.Both.56a
// CHECK:STDOUT:   %Pair => constants.%Pair.01a
// CHECK:STDOUT:   %require_complete.loc13 => constants.%complete_type.ab0
// CHECK:STDOUT:   %uninit.loc13_1.2 => constants.%uninit.ccc
// CHECK:STDOUT:   %Pair.val => constants.%Pair.val.765
// CHECK:STDOUT:   %.loc13_1.15 => constants.%.4a7
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Pair.Both(constants.%i32) {
// CHECK:STDOUT:   %T => constants.%i32
// CHECK:STDOUT:   %pattern_type.loc10_22.1 => constants.%pattern_type.6b6
// CHECK:STDOUT:   %_.param_patt.loc10_22.3 => constants.%_.param_patt.fb2
// CHECK:STDOUT:   %_.patt.loc10_22.3 => constants.%_.patt.b75
// CHECK:STDOUT:   %Pair.loc10_22.1 => constants.%Pair.1ee
// CHECK:STDOUT:   %.loc10_22.9 => constants.%.b22
// CHECK:STDOUT:   %pattern_type.loc10_22.2 => constants.%pattern_type.b73
// CHECK:STDOUT:   %return.param_patt.loc10_22.2 => constants.%return.param_patt.7fa
// CHECK:STDOUT:   %return.patt.loc10_22.2 => constants.%return.patt.52d
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc10_22.1 => constants.%complete_type.f8a
// CHECK:STDOUT:   %require_complete.loc10_22.2 => constants.%complete_type.ea6
// CHECK:STDOUT:   %tuple.type => constants.%tuple.type.e55
// CHECK:STDOUT:   %.loc10_22.10 => constants.%.20c
// CHECK:STDOUT:   %uninit.loc10_22.2 => constants.%uninit.525
// CHECK:STDOUT:   %Pair.val => constants.%Pair.val.cf1
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Pair.Both(constants.%i64) {
// CHECK:STDOUT:   %T => constants.%i64
// CHECK:STDOUT:   %pattern_type.loc10_22.1 => constants.%pattern_type.f57
// CHECK:STDOUT:   %_.param_patt.loc10_22.3 => constants.%_.param_patt.2f0
// CHECK:STDOUT:   %_.patt.loc10_22.3 => constants.%_.patt.233
// CHECK:STDOUT:   %Pair.loc10_22.1 => constants.%Pair.01a
// CHECK:STDOUT:   %.loc10_22.9 => constants.%.02d
// CHECK:STDOUT:   %pattern_type.loc10_22.2 => constants.%pattern_type.fc3
// CHECK:STDOUT:   %return.param_patt.loc10_22.2 => constants.%return.param_patt.fa2
// CHECK:STDOUT:   %return.patt.loc10_22.2 => constants.%return.patt.c93
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc10_22.1 => constants.%complete_type.4a1
// CHECK:STDOUT:   %require_complete.loc10_22.2 => constants.%complete_type.ab0
// CHECK:STDOUT:   %tuple.type => constants.%tuple.type.1ac
// CHECK:STDOUT:   %.loc10_22.10 => constants.%.58e
// CHECK:STDOUT:   %uninit.loc10_22.2 => constants.%uninit.ccc
// CHECK:STDOUT:   %Pair.val => constants.%Pair.val.790
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- guard.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %.Self.frozen.197: %type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %pattern_type.98f: type = pattern_type type [concrete]
// CHECK:STDOUT:   %T.patt.d47: %pattern_type.98f = symbolic_binding_pattern T, 0 [symbolic]
// CHECK:STDOUT:   %T.67d: type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %Opt.type: type = generic_class_type @Opt [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
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
// CHECK:STDOUT:   %u1.builtin: type = int_type unsigned, %int_1.5b8 [concrete]
// CHECK:STDOUT:   %require_complete.dd1: <witness> = require_complete_type %Opt.ba7 [symbolic]
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
// CHECK:STDOUT:   %uninit.37a: %.a2d = uninitialized_value [symbolic]
// CHECK:STDOUT:   %Opt.val.78a: %Opt.ba7 = struct_value (%int_0.1a7, %uninit.37a) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %bound_method.d7a: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
// CHECK:STDOUT:   %int_1.233: %u1 = int_value 1 [concrete]
// CHECK:STDOUT:   %struct: %struct_type.discriminant = struct_value (%int_1.233) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.type.0c5: type = fn_type @UInt.as.Copy.impl.Op, @UInt.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.38a: %UInt.as.Copy.impl.Op.type.0c5 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.334: <witness> = impl_witness imports.%Copy.impl_witness_table.ae7, @UInt.as.Copy.impl(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.type.c97: type = fn_type @UInt.as.Copy.impl.Op, @UInt.as.Copy.impl(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.d9c: %UInt.as.Copy.impl.Op.type.c97 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet.18b: %Copy.type = facet_value %u1, (%Copy.impl_witness.334) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.703: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.18b) [concrete]
// CHECK:STDOUT:   %.952: type = fn_type_with_self_type %Copy.WithSelf.Op.type.703, %Copy.facet.18b [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.bound: <bound method> = bound_method %int_1.233, %UInt.as.Copy.impl.Op.d9c [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %UInt.as.Copy.impl.Op.d9c, @UInt.as.Copy.impl.Op(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.edd: <bound method> = bound_method %int_1.233, %UInt.as.Copy.impl.Op.specific_fn [concrete]
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
// CHECK:STDOUT:   %Sign.type: type = fn_type @Sign [concrete]
// CHECK:STDOUT:   %Sign: %Sign.type = struct_value () [concrete]
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
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.48f: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
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
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet.48f [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.6e0: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_0.3c0: %i32 = int_value 0 [concrete]
// CHECK:STDOUT:   %EqWith.type.c25: type = facet_type <@EqWith, @EqWith(%u1)> [concrete]
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
// CHECK:STDOUT:   %Copy.facet.1e1: %Copy.type = facet_value %i32, (%Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.381: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.1e1) [concrete]
// CHECK:STDOUT:   %.737: type = fn_type_with_self_type %Copy.WithSelf.Op.type.381, %Copy.facet.1e1 [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %w.patt: %pattern_type.6b6 = value_binding_pattern w [concrete]
// CHECK:STDOUT:   %.849: %pattern_type.e71 = tuple_pattern (%w.patt) [concrete]
// CHECK:STDOUT:   %SubWith.type.4c2: type = facet_type <@SubWith, @SubWith(Core.IntLiteral)> [concrete]
// CHECK:STDOUT:   %U.4e6: %ImplicitAs.type.f7de31.1 = symbolic_binding U, 1 [symbolic]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.type.6f3321.1: type = fn_type @Int.as.SubWith.impl.Op.2, @Int.as.SubWith.impl.dc8(%N, %U.4e6) [symbolic]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.a37528.1: %Int.as.SubWith.impl.Op.type.6f3321.1 = struct_value () [symbolic]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.type.6f3321.2: type = fn_type @Int.as.SubWith.impl.Op.3, @Int.as.SubWith.impl.dc8(%N, %U.4e6) [symbolic]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.a37528.2: %Int.as.SubWith.impl.Op.type.6f3321.2 = struct_value () [symbolic]
// CHECK:STDOUT:   %SubWith.impl_witness.447: <witness> = impl_witness imports.%SubWith.impl_witness_table.038, @Int.as.SubWith.impl.dc8(%int_32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.type.657f13.1: type = fn_type @Int.as.SubWith.impl.Op.3, @Int.as.SubWith.impl.dc8(%int_32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.fa84b9.1: %Int.as.SubWith.impl.Op.type.657f13.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.type.657f13.2: type = fn_type @Int.as.SubWith.impl.Op.2, @Int.as.SubWith.impl.dc8(%int_32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.fa84b9.2: %Int.as.SubWith.impl.Op.type.657f13.2 = struct_value () [concrete]
// CHECK:STDOUT:   %SubWith.facet.775: %SubWith.type.4c2 = facet_value %i32, (%SubWith.impl_witness.447) [concrete]
// CHECK:STDOUT:   %SubWith.WithSelf.Op.type.d32: type = fn_type @SubWith.WithSelf.Op, @SubWith.WithSelf(Core.IntLiteral, %SubWith.facet.775) [concrete]
// CHECK:STDOUT:   %.ae9: type = fn_type_with_self_type %SubWith.WithSelf.Op.type.d32, %SubWith.facet.775 [concrete]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.specific_fn.13b586.1: <specific function> = specific_function %Int.as.SubWith.impl.Op.fa84b9.2, @Int.as.SubWith.impl.Op.2(%int_32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.specific_fn.13b586.2: <specific function> = specific_function %Int.as.SubWith.impl.Op.fa84b9.1, @Int.as.SubWith.impl.Op.3(%int_32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.953: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound.22c: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %bound_method.a82: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
// CHECK:STDOUT:   %int_10: Core.IntLiteral = int_value 10 [concrete]
// CHECK:STDOUT:   %Negate.type: type = facet_type <@Negate> [concrete]
// CHECK:STDOUT:   %Negate.impl_witness: <witness> = impl_witness imports.%Negate.impl_witness_table [concrete]
// CHECK:STDOUT:   %Negate.facet: %Negate.type = facet_value Core.IntLiteral, (%Negate.impl_witness) [concrete]
// CHECK:STDOUT:   %Negate.WithSelf.Op.type.e85: type = fn_type @Negate.WithSelf.Op, @Negate.WithSelf(%Negate.facet) [concrete]
// CHECK:STDOUT:   %.758: type = fn_type_with_self_type %Negate.WithSelf.Op.type.e85, %Negate.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.type: type = fn_type @Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op: %Core.IntLiteral.as.Negate.impl.Op.type = struct_value () [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.bound.599: <bound method> = bound_method %int_10, %Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %int_-10.06d: Core.IntLiteral = int_value -10 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.f93: <bound method> = bound_method %int_-10.06d, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.27d: <bound method> = bound_method %int_-10.06d, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_-10.642: %i32 = int_value -10 [concrete]
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.bound.e21: <bound method> = bound_method %int_2, %Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %int_-2.962: Core.IntLiteral = int_value -2 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.2a0: <bound method> = bound_method %int_-2.962, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.33f: <bound method> = bound_method %int_-2.962, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_-2.c83: %i32 = int_value -2 [concrete]
// CHECK:STDOUT:   %Run.type: type = fn_type @Run [concrete]
// CHECK:STDOUT:   %Run: %Run.type = struct_value () [concrete]
// CHECK:STDOUT:   %s.patt: %pattern_type.25d = value_binding_pattern s [concrete]
// CHECK:STDOUT:   %int_7.29f: Core.IntLiteral = int_value 7 [concrete]
// CHECK:STDOUT:   %_.param_patt.fb2: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %_.patt.b75: %pattern_type.6b6 = at_binding_pattern _, %_.param_patt.fb2 [concrete]
// CHECK:STDOUT:   %.bda: Core.Form = init_form %Opt.46d [concrete]
// CHECK:STDOUT:   %return.param_patt.63c: %pattern_type.25d = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.c82: %pattern_type.25d = return_slot_pattern %return.param_patt.63c, %Opt.46d [concrete]
// CHECK:STDOUT:   %Opt.Some.specific_fn: <specific function> = specific_function %Opt.Some.733, @Opt.Some(%i32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.66b: <bound method> = bound_method %int_7.29f, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.7ff: <bound method> = bound_method %int_7.29f, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_7.690: %i32 = int_value 7 [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.8: type = fn_type @Destroy.Op.loc27_36.8 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.8: %Destroy.Op.type.1d8f74.8 = struct_value () [concrete]
// CHECK:STDOUT:   %Opt.val.5b3: %Opt.46d = struct_value (%int_0.1a7, %uninit.060) [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.aa5: @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.170)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.f01 = impl_witness_table (%Core.import_ref.aa5), @Core.IntLiteral.as.ImplicitAs.impl.b68 [concrete]
// CHECK:STDOUT:   %Core.import_ref.791: @UInt.as.Copy.impl.%UInt.as.Copy.impl.Op.type (%UInt.as.Copy.impl.Op.type.0c5) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.Copy.impl.%UInt.as.Copy.impl.Op (constants.%UInt.as.Copy.impl.Op.38a)]
// CHECK:STDOUT:   %Copy.impl_witness_table.ae7 = impl_witness_table (%Core.import_ref.791), @UInt.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.0e6 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.f9df = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.0ab: @Int.as.OrderedWith.impl.f36.%Int.as.OrderedWith.impl.Greater.type.2 (%Int.as.OrderedWith.impl.Greater.type.18c27f.1) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.OrderedWith.impl.f36.%Int.as.OrderedWith.impl.Greater.2 (constants.%Int.as.OrderedWith.impl.Greater.cbccb6.1)]
// CHECK:STDOUT:   %Core.import_ref.b56 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %OrderedWith.impl_witness_table.100 = impl_witness_table (%Core.import_ref.0e6, %Core.import_ref.f9df, %Core.import_ref.0ab, %Core.import_ref.b56), @Int.as.OrderedWith.impl.f36 [concrete]
// CHECK:STDOUT:   %Core.Greater.28d: @Int.as.OrderedWith.impl.f36.%Int.as.OrderedWith.impl.Greater.type.1 (%Int.as.OrderedWith.impl.Greater.type.18c27f.2) = import_ref Core//prelude/types/int, Greater, loaded [symbolic = @Int.as.OrderedWith.impl.f36.%Int.as.OrderedWith.impl.Greater.1 (constants.%Int.as.OrderedWith.impl.Greater.cbccb6.2)]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.b929: @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal.type (%UInt.as.EqWith.impl.Equal.type.544) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal (constants.%UInt.as.EqWith.impl.Equal.c67)]
// CHECK:STDOUT:   %Core.import_ref.b44 = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.166 = impl_witness_table (%Core.import_ref.b929, %Core.import_ref.b44), @UInt.as.EqWith.impl.f13 [concrete]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.b4fd3a.2 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.6fa: @Int.as.SubWith.impl.dc8.%Int.as.SubWith.impl.Op.type.2 (%Int.as.SubWith.impl.Op.type.6f3321.1) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.SubWith.impl.dc8.%Int.as.SubWith.impl.Op.2 (constants.%Int.as.SubWith.impl.Op.a37528.1)]
// CHECK:STDOUT:   %SubWith.impl_witness_table.038 = impl_witness_table (%Core.import_ref.b4fd3a.2, %Core.import_ref.6fa), @Int.as.SubWith.impl.dc8 [concrete]
// CHECK:STDOUT:   %Core.Op.9ff: @Int.as.SubWith.impl.dc8.%Int.as.SubWith.impl.Op.type.1 (%Int.as.SubWith.impl.Op.type.6f3321.2) = import_ref Core//prelude/types/int, Op, loaded [symbolic = @Int.as.SubWith.impl.dc8.%Int.as.SubWith.impl.Op.1 (constants.%Int.as.SubWith.impl.Op.a37528.2)]
// CHECK:STDOUT:   %Core.import_ref.abd = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9c3: %Core.IntLiteral.as.Negate.impl.Op.type = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, loaded [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %Negate.impl_witness_table = impl_witness_table (%Core.import_ref.abd, %Core.import_ref.9c3), @Core.IntLiteral.as.Negate.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %Opt.Some.decl: @Opt.%Opt.Some.type (%Opt.Some.type.d0c) = fn_decl @Opt.Some [symbolic = @Opt.%Opt.Some (constants.%Opt.Some.821)] {
// CHECK:STDOUT:     %_.param_patt.loc11_21.1: @Opt.Some.%pattern_type.loc11_21.1 (%pattern_type.51d1c4.1) = value_param_pattern [symbolic = %_.param_patt.loc11_21.2 (constants.%_.param_patt.339)]
// CHECK:STDOUT:     %_.patt.loc11_21.1: @Opt.Some.%pattern_type.loc11_21.1 (%pattern_type.51d1c4.1) = at_binding_pattern _, %_.param_patt.loc11_21.1 [symbolic = %_.patt.loc11_21.2 (constants.%_.patt.fd3)]
// CHECK:STDOUT:     %return.param_patt.loc11_21.1: @Opt.Some.%pattern_type.loc11_21.2 (%pattern_type.86b) = out_param_pattern [symbolic = %return.param_patt.loc11_21.2 (constants.%return.param_patt.e2a)]
// CHECK:STDOUT:     %return.patt.loc11_21.1: @Opt.Some.%pattern_type.loc11_21.2 (%pattern_type.86b) = return_slot_pattern %return.param_patt.loc11_21.1, %Opt.loc11_21.2 [symbolic = %return.patt.loc11_21.2 (constants.%return.patt.ac3)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %Opt.loc11_21.2: type = class_type @Opt, @Opt(constants.%T.67d) [symbolic = %Opt.loc11_21.1 (constants.%Opt.ba7)]
// CHECK:STDOUT:     %.loc11_21.11: Core.Form = init_form %Opt.loc11_21.2 [symbolic = %.loc11_21.9 (constants.%.3c3)]
// CHECK:STDOUT:     %_.param: @Opt.Some.%T (%T.67d) = value_param call_param0
// CHECK:STDOUT:     %_: @Opt.Some.%T (%T.67d) = wrapper_binding _, %_.param
// CHECK:STDOUT:     %return.param: ref @Opt.Some.%Opt.loc11_21.1 (%Opt.ba7) = out_param call_param1
// CHECK:STDOUT:     %return: ref @Opt.Some.%Opt.loc11_21.1 (%Opt.ba7) = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Opt.decl: %Opt.type = class_decl @Opt [concrete = constants.%Opt.generic] {
// CHECK:STDOUT:     %T.patt.loc11_13.1: %pattern_type.98f = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc11_13.2 (constants.%T.patt.d47)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc11_15.1: type = splice_block %.loc11_15.2 [concrete = type] {
// CHECK:STDOUT:       %.Self.frozen: %type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen.197]
// CHECK:STDOUT:       %.loc11_15.2: type = type_literal type [concrete = type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc11_13.2: type = symbolic_binding T, 0 [symbolic = %T.loc11_13.1 (constants.%T.67d)]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Sign.decl: %Sign.type = fn_decl @Sign [concrete = constants.%Sign] {
// CHECK:STDOUT:     %o.param_patt: %pattern_type.25d = value_param_pattern [concrete = constants.%o.param_patt]
// CHECK:STDOUT:     %o.patt: %pattern_type.25d = at_binding_pattern o, %o.param_patt [concrete = constants.%o.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc16_25 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc16_25: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc16_25: Core.Form = init_form %i32.loc16_25 [concrete = constants.%.795f]
// CHECK:STDOUT:     %o.param: %Opt.46d = value_param call_param0
// CHECK:STDOUT:     %.loc16_19: type = splice_block %Opt [concrete = constants.%Opt.46d] {
// CHECK:STDOUT:       %Opt.ref: %Opt.type = name_ref Opt, file.%Opt.decl [concrete = constants.%Opt.generic]
// CHECK:STDOUT:       %i32.loc16_16: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %Opt: type = class_type @Opt, @Opt(constants.%i32) [concrete = constants.%Opt.46d]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %o: %Opt.46d = wrapper_binding o, %o.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Run.decl: %Run.type = fn_decl @Run [concrete = constants.%Run] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc26 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc26: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc26: Core.Form = init_form %i32.loc26 [concrete = constants.%.795f]
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param0
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic class @Opt(%T.loc11_13.2: type) {
// CHECK:STDOUT:   %T.patt.loc11_13.2: %pattern_type.98f = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc11_13.2 (constants.%T.patt.d47)]
// CHECK:STDOUT:   %T.loc11_13.1: type = symbolic_binding T, 0 [symbolic = %T.loc11_13.1 (constants.%T.67d)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %pattern_type: type = pattern_type %T.loc11_13.1 [symbolic = %pattern_type (constants.%pattern_type.51d1c4.1)]
// CHECK:STDOUT:   %value.param_patt: @Opt.%pattern_type (%pattern_type.51d1c4.1) = value_param_pattern [symbolic = %value.param_patt (constants.%value.param_patt.98e)]
// CHECK:STDOUT:   %value.patt: @Opt.%pattern_type (%pattern_type.51d1c4.1) = at_binding_pattern value, %value.param_patt [symbolic = %value.patt (constants.%value.patt.864)]
// CHECK:STDOUT:   %require_complete.loc12: <witness> = require_complete_type %T.loc11_13.1 [symbolic = %require_complete.loc12 (constants.%require_complete.944)]
// CHECK:STDOUT:   %tuple.type: type = tuple_type (%T.loc11_13.1) [symbolic = %tuple.type (constants.%tuple.type.026)]
// CHECK:STDOUT:   %.loc14_1.14: type = custom_layout_type {size=0, align=0, .Some@0: @Opt.%tuple.type (%tuple.type.026)} [symbolic = %.loc14_1.14 (constants.%.a2d)]
// CHECK:STDOUT:   %struct_type.discriminant.payload: type = struct_type {.discriminant: %u1, .payload: @Opt.%.loc14_1.14 (%.a2d)} [symbolic = %struct_type.discriminant.payload (constants.%struct_type.discriminant.payload.508)]
// CHECK:STDOUT:   %complete_type.loc14_1.2: <witness> = complete_type_witness %struct_type.discriminant.payload [symbolic = %complete_type.loc14_1.2 (constants.%complete_type.abf)]
// CHECK:STDOUT:   %Opt.Some.type: type = fn_type @Opt.Some, @Opt(%T.loc11_13.1) [symbolic = %Opt.Some.type (constants.%Opt.Some.type.d0c)]
// CHECK:STDOUT:   %Opt.Some: @Opt.%Opt.Some.type (%Opt.Some.type.d0c) = struct_value () [symbolic = %Opt.Some (constants.%Opt.Some.821)]
// CHECK:STDOUT:   %Opt: type = class_type @Opt, @Opt(%T.loc11_13.1) [symbolic = %Opt (constants.%Opt.ba7)]
// CHECK:STDOUT:   %require_complete.loc14: <witness> = require_complete_type %Opt [symbolic = %require_complete.loc14 (constants.%require_complete.dd1)]
// CHECK:STDOUT:   %uninit.loc14_1.2: @Opt.%.loc14_1.14 (%.a2d) = uninitialized_value [symbolic = %uninit.loc14_1.2 (constants.%uninit.37a)]
// CHECK:STDOUT:   %Opt.val: @Opt.%Opt (%Opt.ba7) = struct_value (constants.%int_1.233, %uninit.loc14_1.2) [symbolic = %Opt.val (constants.%Opt.val.a5e)]
// CHECK:STDOUT:   %.loc14_1.15: ref @Opt.%Opt (%Opt.ba7) = temporary invalid, %Opt.val [symbolic = %.loc14_1.15 (constants.%.9a0)]
// CHECK:STDOUT:
// CHECK:STDOUT:   class {
// CHECK:STDOUT:     %value.param: @Opt.%T.loc11_13.1 (%T.67d) = value_param call_param0
// CHECK:STDOUT:     %T.ref: type = name_ref T, %T.loc11_13.2 [symbolic = %T.loc11_13.1 (constants.%T.67d)]
// CHECK:STDOUT:     %value: @Opt.%T.loc11_13.1 (%T.67d) = wrapper_binding value, %value.param
// CHECK:STDOUT:     %.loc14_1.1: type = custom_layout_type {size=0, align=0, .Some@0: %tuple.type.026} [symbolic = %.loc14_1.14 (constants.%.a2d)]
// CHECK:STDOUT:     %complete_type.loc14_1.1: <witness> = complete_type_witness constants.%struct_type.discriminant.payload.508 [symbolic = %complete_type.loc14_1.2 (constants.%complete_type.abf)]
// CHECK:STDOUT:     %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:     %impl.elem0.loc14_1.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:     %bound_method.loc14_1.1: <bound method> = bound_method %int_1, %impl.elem0.loc14_1.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:     %specific_fn.loc14_1.1: <specific function> = specific_function %impl.elem0.loc14_1.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:     %bound_method.loc14_1.2: <bound method> = bound_method %int_1, %specific_fn.loc14_1.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %u1 = call %bound_method.loc14_1.2(%int_1) [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc14_1.2: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc14_1.3: %u1 = converted %int_1, %.loc14_1.2 [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc14_1.4: %struct_type.discriminant = struct_literal (%.loc14_1.3) [concrete = constants.%struct]
// CHECK:STDOUT:     %impl.elem0.loc14_1.2: %.952 = impl_witness_access constants.%Copy.impl_witness.334, element0 [concrete = constants.%UInt.as.Copy.impl.Op.d9c]
// CHECK:STDOUT:     %bound_method.loc14_1.3: <bound method> = bound_method %.loc14_1.3, %impl.elem0.loc14_1.2 [concrete = constants.%UInt.as.Copy.impl.Op.bound]
// CHECK:STDOUT:     %specific_fn.loc14_1.2: <specific function> = specific_function %impl.elem0.loc14_1.2, @UInt.as.Copy.impl.Op(constants.%int_1.5b8) [concrete = constants.%UInt.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:     %bound_method.loc14_1.4: <bound method> = bound_method %.loc14_1.3, %specific_fn.loc14_1.2 [concrete = constants.%bound_method.edd]
// CHECK:STDOUT:     %UInt.as.Copy.impl.Op.call: init %u1 = call %bound_method.loc14_1.4(%.loc14_1.3) [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc14_1.5: ref @Opt.%Opt (%Opt.ba7) = temporary_storage
// CHECK:STDOUT:     %.loc14_1.6: ref %u1 = class_element_access %.loc14_1.5, element0
// CHECK:STDOUT:     %.loc14_1.7: init %u1 to %.loc14_1.6 = in_place_init %UInt.as.Copy.impl.Op.call [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc14_1.8: ref @Opt.%.loc14_1.14 (%.a2d) = class_element_access %.loc14_1.5, element1
// CHECK:STDOUT:     %uninit.loc14_1.1: @Opt.%.loc14_1.14 (%.a2d) = uninitialized_value [symbolic = %uninit.loc14_1.2 (constants.%uninit.37a)]
// CHECK:STDOUT:     %.loc14_1.9: init @Opt.%.loc14_1.14 (%.a2d) to %.loc14_1.8 = in_place_init %uninit.loc14_1.1 [symbolic = %uninit.loc14_1.2 (constants.%uninit.37a)]
// CHECK:STDOUT:     %.loc14_1.10: init @Opt.%Opt (%Opt.ba7) to %.loc14_1.5 = class_init (%.loc14_1.7, %.loc14_1.9) [symbolic = %Opt.val (constants.%Opt.val.a5e)]
// CHECK:STDOUT:     %.loc14_1.11: init @Opt.%Opt (%Opt.ba7) = converted %.loc14_1.4, %.loc14_1.10 [symbolic = %Opt.val (constants.%Opt.val.a5e)]
// CHECK:STDOUT:     %.loc14_1.12: ref @Opt.%Opt (%Opt.ba7) = temporary %.loc14_1.5, %.loc14_1.11 [symbolic = %.loc14_1.15 (constants.%.9a0)]
// CHECK:STDOUT:     %.loc14_1.13: @Opt.%Opt (%Opt.ba7) = acquire_value %.loc14_1.12 [symbolic = %Opt.val (constants.%Opt.val.a5e)]
// CHECK:STDOUT:     %None: @Opt.%Opt (%Opt.ba7) = wrapper_binding None, %.loc14_1.13
// CHECK:STDOUT:     complete_type_witness = %complete_type.loc14_1.1
// CHECK:STDOUT:
// CHECK:STDOUT:   !members:
// CHECK:STDOUT:     .Self = constants.%Opt.ba7
// CHECK:STDOUT:     .T = <poisoned>
// CHECK:STDOUT:     .Some = generated.%Opt.Some.decl
// CHECK:STDOUT:     .None = %None
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @Opt.Some(@Opt.%T.loc11_13.2: type) {
// CHECK:STDOUT:   %T: type = symbolic_binding T, 0 [symbolic = %T (constants.%T.67d)]
// CHECK:STDOUT:   %pattern_type.loc11_21.1: type = pattern_type %T [symbolic = %pattern_type.loc11_21.1 (constants.%pattern_type.51d1c4.1)]
// CHECK:STDOUT:   %_.param_patt.loc11_21.2: @Opt.Some.%pattern_type.loc11_21.1 (%pattern_type.51d1c4.1) = value_param_pattern [symbolic = %_.param_patt.loc11_21.2 (constants.%_.param_patt.339)]
// CHECK:STDOUT:   %_.patt.loc11_21.2: @Opt.Some.%pattern_type.loc11_21.1 (%pattern_type.51d1c4.1) = at_binding_pattern _, %_.param_patt.loc11_21.2 [symbolic = %_.patt.loc11_21.2 (constants.%_.patt.fd3)]
// CHECK:STDOUT:   %Opt.loc11_21.1: type = class_type @Opt, @Opt(%T) [symbolic = %Opt.loc11_21.1 (constants.%Opt.ba7)]
// CHECK:STDOUT:   %.loc11_21.9: Core.Form = init_form %Opt.loc11_21.1 [symbolic = %.loc11_21.9 (constants.%.3c3)]
// CHECK:STDOUT:   %pattern_type.loc11_21.2: type = pattern_type %Opt.loc11_21.1 [symbolic = %pattern_type.loc11_21.2 (constants.%pattern_type.86b)]
// CHECK:STDOUT:   %return.param_patt.loc11_21.2: @Opt.Some.%pattern_type.loc11_21.2 (%pattern_type.86b) = out_param_pattern [symbolic = %return.param_patt.loc11_21.2 (constants.%return.param_patt.e2a)]
// CHECK:STDOUT:   %return.patt.loc11_21.2: @Opt.Some.%pattern_type.loc11_21.2 (%pattern_type.86b) = return_slot_pattern %return.param_patt.loc11_21.2, %Opt.loc11_21.1 [symbolic = %return.patt.loc11_21.2 (constants.%return.patt.ac3)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc11_21.1: <witness> = require_complete_type %T [symbolic = %require_complete.loc11_21.1 (constants.%require_complete.944)]
// CHECK:STDOUT:   %require_complete.loc11_21.2: <witness> = require_complete_type %Opt.loc11_21.1 [symbolic = %require_complete.loc11_21.2 (constants.%require_complete.dd1)]
// CHECK:STDOUT:   %tuple.type: type = tuple_type (%T) [symbolic = %tuple.type (constants.%tuple.type.026)]
// CHECK:STDOUT:   %.loc11_21.10: type = custom_layout_type {size=0, align=0, .Some@0: @Opt.Some.%tuple.type (%tuple.type.026)} [symbolic = %.loc11_21.10 (constants.%.a2d)]
// CHECK:STDOUT:   %uninit.loc11_21.2: @Opt.Some.%.loc11_21.10 (%.a2d) = uninitialized_value [symbolic = %uninit.loc11_21.2 (constants.%uninit.37a)]
// CHECK:STDOUT:   %Opt.val: @Opt.Some.%Opt.loc11_21.1 (%Opt.ba7) = struct_value (constants.%int_0.1a7, %uninit.loc11_21.2) [symbolic = %Opt.val (constants.%Opt.val.78a)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%_.param: @Opt.Some.%T (%T.67d)) -> out %return.param: @Opt.Some.%Opt.loc11_21.1 (%Opt.ba7) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %.loc11_21.1: ref %u1 = class_element_access %return.param, element0
// CHECK:STDOUT:     %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:     %impl.elem0: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:     %bound_method.loc11_21.1: <bound method> = bound_method %int_0, %impl.elem0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:     %specific_fn: <specific function> = specific_function %impl.elem0, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:     %bound_method.loc11_21.2: <bound method> = bound_method %int_0, %specific_fn [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %u1 = call %bound_method.loc11_21.2(%int_0) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:     %.loc11_21.2: init %u1 = converted %int_0, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:     %.loc11_21.3: init %u1 to %.loc11_21.1 = in_place_init %.loc11_21.2 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:     %.loc11_21.4: ref @Opt.Some.%.loc11_21.10 (%.a2d) = class_element_access %return.param, element1
// CHECK:STDOUT:     %.loc11_21.5: ref @Opt.Some.%tuple.type (%tuple.type.026) = class_element_access %.loc11_21.4, element0
// CHECK:STDOUT:     %.loc12_17.1: init @Opt.Some.%tuple.type (%tuple.type.026) to %.loc11_21.5 = tuple_init (%_.param)
// CHECK:STDOUT:     %uninit.loc11_21.1: @Opt.Some.%.loc11_21.10 (%.a2d) = uninitialized_value [symbolic = %uninit.loc11_21.2 (constants.%uninit.37a)]
// CHECK:STDOUT:     %.loc11_21.6: init @Opt.Some.%.loc11_21.10 (%.a2d) to %.loc11_21.4 = in_place_init %uninit.loc11_21.1 [symbolic = %uninit.loc11_21.2 (constants.%uninit.37a)]
// CHECK:STDOUT:     %.loc11_21.7: init @Opt.Some.%Opt.loc11_21.1 (%Opt.ba7) to %return.param = class_init (%.loc11_21.3, %.loc11_21.6) [symbolic = %Opt.val (constants.%Opt.val.78a)]
// CHECK:STDOUT:     %.loc11_21.8: init @Opt.Some.%Opt.loc11_21.1 (%Opt.ba7) = update_init %.loc11_21.7, %.loc12_17.1
// CHECK:STDOUT:     %tuple.elem0: ref @Opt.Some.%T (%T.67d) = tuple_access %.loc11_21.5, element0
// CHECK:STDOUT:     %.loc12_17.2: init @Opt.Some.%T (%T.67d) to %tuple.elem0 = in_place_init %_.param
// CHECK:STDOUT:     return %.loc11_21.8 to %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Sign(%o.param: %Opt.46d) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %o.ref: %Opt.46d = name_ref o, %o
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %v.patt: %pattern_type.6b6 = value_binding_pattern v [concrete = constants.%v.patt]
// CHECK:STDOUT:     %.loc18_17: %pattern_type.e71 = tuple_pattern (%v.patt) [concrete = constants.%.13b]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_0.loc18_35: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc18_35.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc18_35.1: <bound method> = bound_method %int_0.loc18_35, %impl.elem0.loc18_35.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:   %specific_fn.loc18_35.1: <specific function> = specific_function %impl.elem0.loc18_35.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc18_35.2: <bound method> = bound_method %int_0.loc18_35, %specific_fn.loc18_35.1 [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc18_35: init %u1 = call %bound_method.loc18_35.2(%int_0.loc18_35) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc18_35.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc18_35 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc18_35.2: %u1 = converted %int_0.loc18_35, %.loc18_35.1 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc18_35.3: ref %u1 = class_element_access %o.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc18_35.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc18_35.3: <bound method> = bound_method %.loc18_35.2, %impl.elem0.loc18_35.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.f34]
// CHECK:STDOUT:   %specific_fn.loc18_35.2: <specific function> = specific_function %impl.elem0.loc18_35.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc18_35.4: <bound method> = bound_method %.loc18_35.2, %specific_fn.loc18_35.2 [concrete = constants.%bound_method.53a]
// CHECK:STDOUT:   %.loc18_35.4: %u1 = acquire_value %.loc18_35.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc18: init bool = call %bound_method.loc18_35.4(%.loc18_35.2, %.loc18_35.4)
// CHECK:STDOUT:   %.loc18_35.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc18
// CHECK:STDOUT:   %.loc18_35.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc18, %.loc18_35.5
// CHECK:STDOUT:   if %.loc18_35.6 br !match.case.then.loc18_35.1 else br !match.case.else.loc18
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc18_35.1:
// CHECK:STDOUT:   %.loc18_35.7: ref %.e8e = class_element_access %o.ref, element1
// CHECK:STDOUT:   %.loc18_35.8: ref %tuple.type.a8a = class_element_access %.loc18_35.7, element0
// CHECK:STDOUT:   %tuple.elem0.loc18: ref %i32 = tuple_access %.loc18_35.8, element0
// CHECK:STDOUT:   %.loc18_35.9: %i32 = acquire_value %tuple.elem0.loc18
// CHECK:STDOUT:   %i32.loc18: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %v: %i32 = wrapper_binding v, %.loc18_35.9
// CHECK:STDOUT:   %.loc18_30.1: bool = splice_block %.loc18_30.4 {
// CHECK:STDOUT:     %v.ref.loc18_28: %i32 = name_ref v, %v
// CHECK:STDOUT:     %int_0.loc18_32: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:     %impl.elem2: %.029 = impl_witness_access constants.%OrderedWith.impl_witness.480, element2 [concrete = constants.%Int.as.OrderedWith.impl.Greater.e68ae3.2]
// CHECK:STDOUT:     %bound_method.loc18_30.1: <bound method> = bound_method %v.ref.loc18_28, %impl.elem2
// CHECK:STDOUT:     %specific_fn.loc18_30: <specific function> = specific_function %impl.elem2, @Int.as.OrderedWith.impl.Greater.2(constants.%int_32, constants.%ImplicitAs.facet.48f) [concrete = constants.%Int.as.OrderedWith.impl.Greater.specific_fn.e2f732.1]
// CHECK:STDOUT:     %bound_method.loc18_30.2: <bound method> = bound_method %v.ref.loc18_28, %specific_fn.loc18_30
// CHECK:STDOUT:     %.loc18_30.2: %Int.as.OrderedWith.impl.Greater.type.a79f39.1 = specific_constant imports.%Core.Greater.28d, @Int.as.OrderedWith.impl.f36(constants.%int_32, constants.%ImplicitAs.facet.48f) [concrete = constants.%Int.as.OrderedWith.impl.Greater.e68ae3.1]
// CHECK:STDOUT:     %Greater.ref: %Int.as.OrderedWith.impl.Greater.type.a79f39.1 = name_ref Greater, %.loc18_30.2 [concrete = constants.%Int.as.OrderedWith.impl.Greater.e68ae3.1]
// CHECK:STDOUT:     %Int.as.OrderedWith.impl.Greater.bound: <bound method> = bound_method %v.ref.loc18_28, %Greater.ref
// CHECK:STDOUT:     %Int.as.OrderedWith.impl.Greater.specific_fn: <specific function> = specific_function %Greater.ref, @Int.as.OrderedWith.impl.Greater.3(constants.%int_32, constants.%ImplicitAs.facet.48f) [concrete = constants.%Int.as.OrderedWith.impl.Greater.specific_fn.e2f732.2]
// CHECK:STDOUT:     %bound_method.loc18_30.3: <bound method> = bound_method %v.ref.loc18_28, %Int.as.OrderedWith.impl.Greater.specific_fn
// CHECK:STDOUT:     %impl.elem0.loc18_32: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:     %bound_method.loc18_32.1: <bound method> = bound_method %int_0.loc18_32, %impl.elem0.loc18_32 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:     %specific_fn.loc18_32: <specific function> = specific_function %impl.elem0.loc18_32, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:     %bound_method.loc18_32.2: <bound method> = bound_method %int_0.loc18_32, %specific_fn.loc18_32 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc18_32: init %i32 = call %bound_method.loc18_32.2(%int_0.loc18_32) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:     %.loc18_32.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc18_32 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:     %.loc18_32.2: %i32 = converted %int_0.loc18_32, %.loc18_32.1 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:     %Int.as.OrderedWith.impl.Greater.call: init bool = call %bound_method.loc18_30.3(%v.ref.loc18_28, %.loc18_32.2)
// CHECK:STDOUT:     %.loc18_30.3: bool = value_of_initializer %Int.as.OrderedWith.impl.Greater.call
// CHECK:STDOUT:     %.loc18_30.4: bool = converted %Int.as.OrderedWith.impl.Greater.call, %.loc18_30.3
// CHECK:STDOUT:   }
// CHECK:STDOUT:   if %.loc18_30.1 br !match.case.then.loc18_35.2 else br !match.case.else.loc18
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc18_35.2:
// CHECK:STDOUT:   %v.ref.loc18_47: %i32 = name_ref v, %v
// CHECK:STDOUT:   %impl.elem0.loc18_47: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc18_47.1: <bound method> = bound_method %v.ref.loc18_47, %impl.elem0.loc18_47
// CHECK:STDOUT:   %specific_fn.loc18_47: <specific function> = specific_function %impl.elem0.loc18_47, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc18_47.2: <bound method> = bound_method %v.ref.loc18_47, %specific_fn.loc18_47
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc18_47.2(%v.ref.loc18_47)
// CHECK:STDOUT:   return %Int.as.Copy.impl.Op.call
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc18:
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %w.patt: %pattern_type.6b6 = value_binding_pattern w [concrete = constants.%w.patt]
// CHECK:STDOUT:     %.loc19_17: %pattern_type.e71 = tuple_pattern (%w.patt) [concrete = constants.%.849]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_0.loc19: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc19_24.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc19_24.1: <bound method> = bound_method %int_0.loc19, %impl.elem0.loc19_24.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:   %specific_fn.loc19_24.1: <specific function> = specific_function %impl.elem0.loc19_24.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc19_24.2: <bound method> = bound_method %int_0.loc19, %specific_fn.loc19_24.1 [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc19_24: init %u1 = call %bound_method.loc19_24.2(%int_0.loc19) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc19_24.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc19_24 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc19_24.2: %u1 = converted %int_0.loc19, %.loc19_24.1 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc19_24.3: ref %u1 = class_element_access %o.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc19_24.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
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
// CHECK:STDOUT:   %tuple.elem0.loc19: ref %i32 = tuple_access %.loc19_24.8, element0
// CHECK:STDOUT:   %.loc19_24.9: %i32 = acquire_value %tuple.elem0.loc19
// CHECK:STDOUT:   %i32.loc19: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %w: %i32 = wrapper_binding w, %.loc19_24.9
// CHECK:STDOUT:   %w.ref: %i32 = name_ref w, %w
// CHECK:STDOUT:   %int_1.loc19: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem1.loc19: %.ae9 = impl_witness_access constants.%SubWith.impl_witness.447, element1 [concrete = constants.%Int.as.SubWith.impl.Op.fa84b9.2]
// CHECK:STDOUT:   %bound_method.loc19_38.1: <bound method> = bound_method %w.ref, %impl.elem1.loc19
// CHECK:STDOUT:   %specific_fn.loc19_38: <specific function> = specific_function %impl.elem1.loc19, @Int.as.SubWith.impl.Op.2(constants.%int_32, constants.%ImplicitAs.facet.48f) [concrete = constants.%Int.as.SubWith.impl.Op.specific_fn.13b586.1]
// CHECK:STDOUT:   %bound_method.loc19_38.2: <bound method> = bound_method %w.ref, %specific_fn.loc19_38
// CHECK:STDOUT:   %.loc19_38: %Int.as.SubWith.impl.Op.type.657f13.1 = specific_constant imports.%Core.Op.9ff, @Int.as.SubWith.impl.dc8(constants.%int_32, constants.%ImplicitAs.facet.48f) [concrete = constants.%Int.as.SubWith.impl.Op.fa84b9.1]
// CHECK:STDOUT:   %Op.ref: %Int.as.SubWith.impl.Op.type.657f13.1 = name_ref Op, %.loc19_38 [concrete = constants.%Int.as.SubWith.impl.Op.fa84b9.1]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.bound: <bound method> = bound_method %w.ref, %Op.ref
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.specific_fn: <specific function> = specific_function %Op.ref, @Int.as.SubWith.impl.Op.3(constants.%int_32, constants.%ImplicitAs.facet.48f) [concrete = constants.%Int.as.SubWith.impl.Op.specific_fn.13b586.2]
// CHECK:STDOUT:   %bound_method.loc19_38.3: <bound method> = bound_method %w.ref, %Int.as.SubWith.impl.Op.specific_fn
// CHECK:STDOUT:   %impl.elem0.loc19_40: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc19_40.1: <bound method> = bound_method %int_1.loc19, %impl.elem0.loc19_40 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc19_40: <specific function> = specific_function %impl.elem0.loc19_40, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc19_40.2: <bound method> = bound_method %int_1.loc19, %specific_fn.loc19_40 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc19_40: init %i32 = call %bound_method.loc19_40.2(%int_1.loc19) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc19_40.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc19_40 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc19_40.2: %i32 = converted %int_1.loc19, %.loc19_40.1 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.call: init %i32 = call %bound_method.loc19_38.3(%w.ref, %.loc19_40.2)
// CHECK:STDOUT:   return %Int.as.SubWith.impl.Op.call
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc19:
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt: %pattern_type.25d = expr_pattern %None.ref in [concrete] {
// CHECK:STDOUT:       %.loc20_10.2: %Opt.46d = specific_constant @Opt.%.loc14_1.13, @Opt(constants.%i32) [concrete = constants.%Opt.val.b51]
// CHECK:STDOUT:       %None.ref: %Opt.46d = name_ref None, %.loc20_10.2 [concrete = constants.%Opt.val.b51]
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %.loc20_10.1: %Opt.46d = splice_block %None.ref [concrete = constants.%Opt.val.b51] {
// CHECK:STDOUT:     %.loc20_10.2: %Opt.46d = specific_constant @Opt.%.loc14_1.13, @Opt(constants.%i32) [concrete = constants.%Opt.val.b51]
// CHECK:STDOUT:     %None.ref: %Opt.46d = name_ref None, %.loc20_10.2 [concrete = constants.%Opt.val.b51]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_1.loc20: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc20_16.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc20_16.1: <bound method> = bound_method %int_1.loc20, %impl.elem0.loc20_16.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc20_16.1: <specific function> = specific_function %impl.elem0.loc20_16.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc20_16.2: <bound method> = bound_method %int_1.loc20, %specific_fn.loc20_16.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc20_16: init %u1 = call %bound_method.loc20_16.2(%int_1.loc20) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc20_16.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc20_16 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc20_16.2: %u1 = converted %int_1.loc20, %.loc20_16.1 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc20_16.3: ref %u1 = class_element_access %o.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc20_16.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
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
// CHECK:STDOUT:   %int_10: Core.IntLiteral = int_value 10 [concrete = constants.%int_10]
// CHECK:STDOUT:   %impl.elem1.loc20: %.758 = impl_witness_access constants.%Negate.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %bound_method.loc20_28: <bound method> = bound_method %int_10, %impl.elem1.loc20 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op.bound.599]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.call.loc20: init Core.IntLiteral = call %bound_method.loc20_28(%int_10) [concrete = constants.%int_-10.06d]
// CHECK:STDOUT:   %impl.elem0.loc20_31: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc20_31.1: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call.loc20, %impl.elem0.loc20_31 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.f93]
// CHECK:STDOUT:   %specific_fn.loc20_31: <specific function> = specific_function %impl.elem0.loc20_31, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc20_31.2: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call.loc20, %specific_fn.loc20_31 [concrete = constants.%bound_method.27d]
// CHECK:STDOUT:   %.loc20_28.1: Core.IntLiteral = value_of_initializer %Core.IntLiteral.as.Negate.impl.Op.call.loc20 [concrete = constants.%int_-10.06d]
// CHECK:STDOUT:   %.loc20_28.2: Core.IntLiteral = converted %Core.IntLiteral.as.Negate.impl.Op.call.loc20, %.loc20_28.1 [concrete = constants.%int_-10.06d]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc20_31: init %i32 = call %bound_method.loc20_31.2(%.loc20_28.2) [concrete = constants.%int_-10.642]
// CHECK:STDOUT:   %.loc20_31: init %i32 = converted %Core.IntLiteral.as.Negate.impl.Op.call.loc20, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc20_31 [concrete = constants.%int_-10.642]
// CHECK:STDOUT:   return %.loc20_31
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc20:
// CHECK:STDOUT:   br !match.done
// CHECK:STDOUT:
// CHECK:STDOUT: !match.done:
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2]
// CHECK:STDOUT:   %impl.elem1.loc23: %.758 = impl_witness_access constants.%Negate.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %bound_method.loc23_10: <bound method> = bound_method %int_2, %impl.elem1.loc23 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op.bound.e21]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.call.loc23: init Core.IntLiteral = call %bound_method.loc23_10(%int_2) [concrete = constants.%int_-2.962]
// CHECK:STDOUT:   %impl.elem0.loc23: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc23_12.1: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call.loc23, %impl.elem0.loc23 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.2a0]
// CHECK:STDOUT:   %specific_fn.loc23: <specific function> = specific_function %impl.elem0.loc23, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc23_12.2: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call.loc23, %specific_fn.loc23 [concrete = constants.%bound_method.33f]
// CHECK:STDOUT:   %.loc23_10.1: Core.IntLiteral = value_of_initializer %Core.IntLiteral.as.Negate.impl.Op.call.loc23 [concrete = constants.%int_-2.962]
// CHECK:STDOUT:   %.loc23_10.2: Core.IntLiteral = converted %Core.IntLiteral.as.Negate.impl.Op.call.loc23, %.loc23_10.1 [concrete = constants.%int_-2.962]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc23: init %i32 = call %bound_method.loc23_12.2(%.loc23_10.2) [concrete = constants.%int_-2.c83]
// CHECK:STDOUT:   %.loc23_12: init %i32 = converted %Core.IntLiteral.as.Negate.impl.Op.call.loc23, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc23 [concrete = constants.%int_-2.c83]
// CHECK:STDOUT:   return %.loc23_12
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Run() -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Opt.ref.loc27_21: %Opt.type = name_ref Opt, file.%Opt.decl [concrete = constants.%Opt.generic]
// CHECK:STDOUT:   %i32.loc27_25: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %Opt.loc27_28: type = class_type @Opt, @Opt(constants.%i32) [concrete = constants.%Opt.46d]
// CHECK:STDOUT:   %.loc27_29: %Opt.Some.type.39e = specific_constant generated.%Opt.Some.decl, @Opt(constants.%i32) [concrete = constants.%Opt.Some.733]
// CHECK:STDOUT:   %Some.ref: %Opt.Some.type.39e = name_ref Some, %.loc27_29 [concrete = constants.%Opt.Some.733]
// CHECK:STDOUT:   %int_7.loc27: Core.IntLiteral = int_value 7 [concrete = constants.%int_7.29f]
// CHECK:STDOUT:   %Opt.Some.specific_fn: <specific function> = specific_function %Some.ref, @Opt.Some(constants.%i32) [concrete = constants.%Opt.Some.specific_fn]
// CHECK:STDOUT:   %.loc27_36.1: ref %Opt.46d = temporary_storage
// CHECK:STDOUT:   %impl.elem0.loc27: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc27_35.1: <bound method> = bound_method %int_7.loc27, %impl.elem0.loc27 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.66b]
// CHECK:STDOUT:   %specific_fn.loc27: <specific function> = specific_function %impl.elem0.loc27, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc27_35.2: <bound method> = bound_method %int_7.loc27, %specific_fn.loc27 [concrete = constants.%bound_method.7ff]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc27: init %i32 = call %bound_method.loc27_35.2(%int_7.loc27) [concrete = constants.%int_7.690]
// CHECK:STDOUT:   %.loc27_35.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc27 [concrete = constants.%int_7.690]
// CHECK:STDOUT:   %.loc27_35.2: %i32 = converted %int_7.loc27, %.loc27_35.1 [concrete = constants.%int_7.690]
// CHECK:STDOUT:   %Opt.Some.call: init %Opt.46d to %.loc27_36.1 = call %Opt.Some.specific_fn(%.loc27_35.2)
// CHECK:STDOUT:   %.loc27_36.2: ref %Opt.46d = temporary %.loc27_36.1, %Opt.Some.call
// CHECK:STDOUT:   %.loc27_36.3: %Opt.46d = acquire_value %.loc27_36.2
// CHECK:STDOUT:   %.loc27_17: type = splice_block %Opt.loc27_17 [concrete = constants.%Opt.46d] {
// CHECK:STDOUT:     %Opt.ref.loc27_10: %Opt.type = name_ref Opt, file.%Opt.decl [concrete = constants.%Opt.generic]
// CHECK:STDOUT:     %i32.loc27_14: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %Opt.loc27_17: type = class_type @Opt, @Opt(constants.%i32) [concrete = constants.%Opt.46d]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %s: %Opt.46d = wrapper_binding s, %.loc27_36.3
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %s.patt: %pattern_type.25d = value_binding_pattern s [concrete = constants.%s.patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Sign.ref: %Sign.type = name_ref Sign, file.%Sign.decl [concrete = constants.%Sign]
// CHECK:STDOUT:   %s.ref: %Opt.46d = name_ref s, %s
// CHECK:STDOUT:   %Sign.call: init %i32 = call %Sign.ref(%s.ref)
// CHECK:STDOUT:   %int_7.loc28: Core.IntLiteral = int_value 7 [concrete = constants.%int_7.29f]
// CHECK:STDOUT:   %impl.elem1: %.ae9 = impl_witness_access constants.%SubWith.impl_witness.447, element1 [concrete = constants.%Int.as.SubWith.impl.Op.fa84b9.2]
// CHECK:STDOUT:   %bound_method.loc28_18.1: <bound method> = bound_method %Sign.call, %impl.elem1
// CHECK:STDOUT:   %specific_fn.loc28_18: <specific function> = specific_function %impl.elem1, @Int.as.SubWith.impl.Op.2(constants.%int_32, constants.%ImplicitAs.facet.48f) [concrete = constants.%Int.as.SubWith.impl.Op.specific_fn.13b586.1]
// CHECK:STDOUT:   %bound_method.loc28_18.2: <bound method> = bound_method %Sign.call, %specific_fn.loc28_18
// CHECK:STDOUT:   %.loc28_16.1: %i32 = value_of_initializer %Sign.call
// CHECK:STDOUT:   %.loc28_16.2: %i32 = converted %Sign.call, %.loc28_16.1
// CHECK:STDOUT:   %.loc28_18: %Int.as.SubWith.impl.Op.type.657f13.1 = specific_constant imports.%Core.Op.9ff, @Int.as.SubWith.impl.dc8(constants.%int_32, constants.%ImplicitAs.facet.48f) [concrete = constants.%Int.as.SubWith.impl.Op.fa84b9.1]
// CHECK:STDOUT:   %Op.ref: %Int.as.SubWith.impl.Op.type.657f13.1 = name_ref Op, %.loc28_18 [concrete = constants.%Int.as.SubWith.impl.Op.fa84b9.1]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.bound: <bound method> = bound_method %.loc28_16.2, %Op.ref
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.specific_fn: <specific function> = specific_function %Op.ref, @Int.as.SubWith.impl.Op.3(constants.%int_32, constants.%ImplicitAs.facet.48f) [concrete = constants.%Int.as.SubWith.impl.Op.specific_fn.13b586.2]
// CHECK:STDOUT:   %bound_method.loc28_18.3: <bound method> = bound_method %.loc28_16.2, %Int.as.SubWith.impl.Op.specific_fn
// CHECK:STDOUT:   %impl.elem0.loc28: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc28_20.1: <bound method> = bound_method %int_7.loc28, %impl.elem0.loc28 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.66b]
// CHECK:STDOUT:   %specific_fn.loc28_20: <specific function> = specific_function %impl.elem0.loc28, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc28_20.2: <bound method> = bound_method %int_7.loc28, %specific_fn.loc28_20 [concrete = constants.%bound_method.7ff]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc28: init %i32 = call %bound_method.loc28_20.2(%int_7.loc28) [concrete = constants.%int_7.690]
// CHECK:STDOUT:   %.loc28_20.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc28 [concrete = constants.%int_7.690]
// CHECK:STDOUT:   %.loc28_20.2: %i32 = converted %int_7.loc28, %.loc28_20.1 [concrete = constants.%int_7.690]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.call: init %i32 = call %bound_method.loc28_18.3(%.loc28_16.2, %.loc28_20.2)
// CHECK:STDOUT:   %Destroy.Op.bound: <bound method> = bound_method %.loc27_36.2, constants.%Destroy.Op.1a2547.8
// CHECK:STDOUT:   %Destroy.Op.call: init %empty_tuple.type = call %Destroy.Op.bound(%.loc27_36.2)
// CHECK:STDOUT:   return %Int.as.SubWith.impl.Op.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc27_36.1(%self.param: ref %u1.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc27_36.2(%self.param: ref %u1) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc27_36.3(%self.param: ref %i32.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc27_36.4(%self.param: ref %i32) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc27_36.5(%self.param: ref %tuple.type.a8a) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc27_36.6(%self.param: ref %.e8e) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc27_36.7(%self.param: ref %struct_type.discriminant.payload.e99) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc27_36.8(%self.param: ref %Opt.46d) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Opt(constants.%T.67d) {
// CHECK:STDOUT:   %T.patt.loc11_13.2 => constants.%T.patt.d47
// CHECK:STDOUT:   %T.loc11_13.1 => constants.%T.67d
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Opt.Some(constants.%T.67d) {
// CHECK:STDOUT:   %T => constants.%T.67d
// CHECK:STDOUT:   %pattern_type.loc11_21.1 => constants.%pattern_type.51d1c4.1
// CHECK:STDOUT:   %_.param_patt.loc11_21.2 => constants.%_.param_patt.339
// CHECK:STDOUT:   %_.patt.loc11_21.2 => constants.%_.patt.fd3
// CHECK:STDOUT:   %Opt.loc11_21.1 => constants.%Opt.ba7
// CHECK:STDOUT:   %.loc11_21.9 => constants.%.3c3
// CHECK:STDOUT:   %pattern_type.loc11_21.2 => constants.%pattern_type.86b
// CHECK:STDOUT:   %return.param_patt.loc11_21.2 => constants.%return.param_patt.e2a
// CHECK:STDOUT:   %return.patt.loc11_21.2 => constants.%return.patt.ac3
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Opt(constants.%i32) {
// CHECK:STDOUT:   %T.patt.loc11_13.2 => constants.%T.patt.d47
// CHECK:STDOUT:   %T.loc11_13.1 => constants.%i32
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.6b6
// CHECK:STDOUT:   %value.param_patt => constants.%value.param_patt.34f
// CHECK:STDOUT:   %value.patt => constants.%value.patt.f6a
// CHECK:STDOUT:   %require_complete.loc12 => constants.%complete_type.f8a
// CHECK:STDOUT:   %tuple.type => constants.%tuple.type.a8a
// CHECK:STDOUT:   %.loc14_1.14 => constants.%.e8e
// CHECK:STDOUT:   %struct_type.discriminant.payload => constants.%struct_type.discriminant.payload.e99
// CHECK:STDOUT:   %complete_type.loc14_1.2 => constants.%complete_type.378
// CHECK:STDOUT:   %Opt.Some.type => constants.%Opt.Some.type.39e
// CHECK:STDOUT:   %Opt.Some => constants.%Opt.Some.733
// CHECK:STDOUT:   %Opt => constants.%Opt.46d
// CHECK:STDOUT:   %require_complete.loc14 => constants.%complete_type.378
// CHECK:STDOUT:   %uninit.loc14_1.2 => constants.%uninit.060
// CHECK:STDOUT:   %Opt.val => constants.%Opt.val.b51
// CHECK:STDOUT:   %.loc14_1.15 => constants.%.b5c
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Opt.Some(constants.%i32) {
// CHECK:STDOUT:   %T => constants.%i32
// CHECK:STDOUT:   %pattern_type.loc11_21.1 => constants.%pattern_type.6b6
// CHECK:STDOUT:   %_.param_patt.loc11_21.2 => constants.%_.param_patt.fb2
// CHECK:STDOUT:   %_.patt.loc11_21.2 => constants.%_.patt.b75
// CHECK:STDOUT:   %Opt.loc11_21.1 => constants.%Opt.46d
// CHECK:STDOUT:   %.loc11_21.9 => constants.%.bda
// CHECK:STDOUT:   %pattern_type.loc11_21.2 => constants.%pattern_type.25d
// CHECK:STDOUT:   %return.param_patt.loc11_21.2 => constants.%return.param_patt.63c
// CHECK:STDOUT:   %return.patt.loc11_21.2 => constants.%return.patt.c82
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc11_21.1 => constants.%complete_type.f8a
// CHECK:STDOUT:   %require_complete.loc11_21.2 => constants.%complete_type.378
// CHECK:STDOUT:   %tuple.type => constants.%tuple.type.a8a
// CHECK:STDOUT:   %.loc11_21.10 => constants.%.e8e
// CHECK:STDOUT:   %uninit.loc11_21.2 => constants.%uninit.060
// CHECK:STDOUT:   %Opt.val => constants.%Opt.val.5b3
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- binding_conversion.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %.Self.frozen: %type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %pattern_type.98f: type = pattern_type type [concrete]
// CHECK:STDOUT:   %T.patt.d47: %pattern_type.98f = symbolic_binding_pattern T, 0 [symbolic]
// CHECK:STDOUT:   %T.67d: type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %Opt.type: type = generic_class_type @Opt [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
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
// CHECK:STDOUT:   %u1.builtin: type = int_type unsigned, %int_1.5b8 [concrete]
// CHECK:STDOUT:   %require_complete.dd1: <witness> = require_complete_type %Opt.ba7 [symbolic]
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
// CHECK:STDOUT:   %uninit.37a: %.a2d = uninitialized_value [symbolic]
// CHECK:STDOUT:   %Opt.val.78a: %Opt.ba7 = struct_value (%int_0.1a7, %uninit.37a) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %bound_method.d7a: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
// CHECK:STDOUT:   %int_1.233: %u1 = int_value 1 [concrete]
// CHECK:STDOUT:   %struct: %struct_type.discriminant = struct_value (%int_1.233) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.type.0c5: type = fn_type @UInt.as.Copy.impl.Op, @UInt.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.38a: %UInt.as.Copy.impl.Op.type.0c5 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.334: <witness> = impl_witness imports.%Copy.impl_witness_table.ae7, @UInt.as.Copy.impl(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.type.c97: type = fn_type @UInt.as.Copy.impl.Op, @UInt.as.Copy.impl(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.d9c: %UInt.as.Copy.impl.Op.type.c97 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet.18b: %Copy.type = facet_value %u1, (%Copy.impl_witness.334) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.703: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.18b) [concrete]
// CHECK:STDOUT:   %.952: type = fn_type_with_self_type %Copy.WithSelf.Op.type.703, %Copy.facet.18b [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.bound: <bound method> = bound_method %int_1.233, %UInt.as.Copy.impl.Op.d9c [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %UInt.as.Copy.impl.Op.d9c, @UInt.as.Copy.impl.Op(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.edd: <bound method> = bound_method %int_1.233, %UInt.as.Copy.impl.Op.specific_fn [concrete]
// CHECK:STDOUT:   %Opt.val.a5e: %Opt.ba7 = struct_value (%int_1.233, %uninit.37a) [symbolic]
// CHECK:STDOUT:   %.9a0: ref %Opt.ba7 = temporary invalid, %Opt.val.a5e [symbolic]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %Int.67af24.1: type = class_type @Int, @Int(%N) [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %Opt.46d: type = class_type @Opt, @Opt(%i32) [concrete]
// CHECK:STDOUT:   %pattern_type.25d: type = pattern_type %Opt.46d [concrete]
// CHECK:STDOUT:   %o.param_patt: %pattern_type.25d = value_param_pattern [concrete]
// CHECK:STDOUT:   %o.patt: %pattern_type.25d = at_binding_pattern o, %o.param_patt [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %.bc0: Core.Form = init_form %i64 [concrete]
// CHECK:STDOUT:   %pattern_type.f57: type = pattern_type %i64 [concrete]
// CHECK:STDOUT:   %return.param_patt.cfc: %pattern_type.f57 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.178: %pattern_type.f57 = return_slot_pattern %return.param_patt.cfc, %i64 [concrete]
// CHECK:STDOUT:   %Widen.type: type = fn_type @Widen [concrete]
// CHECK:STDOUT:   %Widen: %Widen.type = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
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
// CHECK:STDOUT:   %v.patt: %pattern_type.f57 = value_binding_pattern v [concrete]
// CHECK:STDOUT:   %tuple.type.f67: type = tuple_type (%i64) [concrete]
// CHECK:STDOUT:   %pattern_type.335: type = pattern_type %tuple.type.f67 [concrete]
// CHECK:STDOUT:   %.c36: %pattern_type.335 = tuple_pattern (%v.patt) [concrete]
// CHECK:STDOUT:   %EqWith.type.c25: type = facet_type <@EqWith, @EqWith(%u1)> [concrete]
// CHECK:STDOUT:   %M: Core.IntLiteral = symbolic_binding M, 1 [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.544: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%N, %M) [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.c67: %UInt.as.EqWith.impl.Equal.type.544 = struct_value () [symbolic]
// CHECK:STDOUT:   %EqWith.type.aee: type = facet_type <@EqWith, @EqWith(Core.IntLiteral)> [concrete]
// CHECK:STDOUT:   %EqWith.impl_witness.7b3: <witness> = impl_witness imports.%EqWith.impl_witness_table.166, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.29b: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.ba4: %UInt.as.EqWith.impl.Equal.type.29b = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.4d0: %EqWith.type.c25 = facet_value %u1, (%EqWith.impl_witness.7b3) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.e3c: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%u1, %EqWith.facet.4d0) [concrete]
// CHECK:STDOUT:   %.9eb: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.e3c, %EqWith.facet.4d0 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound.f34: <bound method> = bound_method %int_0.1a7, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.specific_fn.6b6: <specific function> = specific_function %UInt.as.EqWith.impl.Equal.ba4, @UInt.as.EqWith.impl.Equal.1(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.53a: <bound method> = bound_method %int_0.1a7, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.221: type = facet_type <@ImplicitAs, @ImplicitAs(%i64)> [concrete]
// CHECK:STDOUT:   %Int.67af24.2: type = class_type @Int, @Int(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %facet_type.037: type = facet_type <@IntFitsIn, @IntFitsIn(%Int.67af24.2) & @AnyInt> [symbolic]
// CHECK:STDOUT:   %From.6a4: %facet_type.037 = symbolic_binding From, 1 [symbolic]
// CHECK:STDOUT:   %From.as_type.as.ImplicitAs.impl.Convert.type.7fa: type = fn_type @From.as_type.as.ImplicitAs.impl.Convert, @From.as_type.as.ImplicitAs.impl(%To.fe9, %From.6a4) [symbolic]
// CHECK:STDOUT:   %From.as_type.as.ImplicitAs.impl.Convert.643: %From.as_type.as.ImplicitAs.impl.Convert.type.7fa = struct_value () [symbolic]
// CHECK:STDOUT:   %facet_type.30a: type = facet_type <@IntFitsIn, @IntFitsIn(%i64) & @AnyInt> [concrete]
// CHECK:STDOUT:   %custom_witness.eef: <witness> = custom_witness (), @IntFitsIn, @IntFitsIn(%i64) [concrete]
// CHECK:STDOUT:   %Int.as.AnyInt.impl.AsInt.type.f15: type = fn_type @Int.as.AnyInt.impl.AsInt, @Int.as.AnyInt.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.AnyInt.impl.AsInt.d10: %Int.as.AnyInt.impl.AsInt.type.f15 = struct_value () [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %AnyInt.impl_witness.48c: <witness> = impl_witness imports.%AnyInt.impl_witness_table, @Int.as.AnyInt.impl(%int_32) [concrete]
// CHECK:STDOUT:   %facet_value: %facet_type.30a = facet_value %i32, (%custom_witness.eef, %AnyInt.impl_witness.48c) [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.8d3: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.992, @From.as_type.as.ImplicitAs.impl(%int_64, %facet_value) [concrete]
// CHECK:STDOUT:   %From.as_type.as.ImplicitAs.impl.Convert.type.7ba: type = fn_type @From.as_type.as.ImplicitAs.impl.Convert, @From.as_type.as.ImplicitAs.impl(%int_64, %facet_value) [concrete]
// CHECK:STDOUT:   %From.as_type.as.ImplicitAs.impl.Convert.15a: %From.as_type.as.ImplicitAs.impl.Convert.type.7ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.4f1: %ImplicitAs.type.221 = facet_value %i32, (%ImplicitAs.impl_witness.8d3) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.ed0: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i64, %ImplicitAs.facet.4f1) [concrete]
// CHECK:STDOUT:   %.dbf: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.ed0, %ImplicitAs.facet.4f1 [concrete]
// CHECK:STDOUT:   %From.as_type.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %From.as_type.as.ImplicitAs.impl.Convert.15a, @From.as_type.as.ImplicitAs.impl.Convert(%int_64, %facet_value) [concrete]
// CHECK:STDOUT:   %Copy.impl_witness.8cc: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_64) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.494: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_64) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.d73: %Int.as.Copy.impl.Op.type.494 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet.4e9: %Copy.type = facet_value %i64, (%Copy.impl_witness.8cc) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.5c1: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.4e9) [concrete]
// CHECK:STDOUT:   %.826: type = fn_type_with_self_type %Copy.WithSelf.Op.type.5c1, %Copy.facet.4e9 [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn.b95: <specific function> = specific_function %Int.as.Copy.impl.Op.d73, @Int.as.Copy.impl.Op(%int_64) [concrete]
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
// CHECK:STDOUT:   %ImplicitAs.impl_witness.227: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_64) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.55a: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_64) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.55a = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.235: %ImplicitAs.type.221 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.227) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.da7: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i64, %ImplicitAs.facet.235) [concrete]
// CHECK:STDOUT:   %.03f: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.da7, %ImplicitAs.facet.235 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.bc7: <bound method> = bound_method %int_-1.638, %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.f33: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(%int_64) [concrete]
// CHECK:STDOUT:   %bound_method.ef0: <bound method> = bound_method %int_-1.638, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.f33 [concrete]
// CHECK:STDOUT:   %int_-1.a7e: %i64 = int_value -1 [concrete]
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.bound.e21: <bound method> = bound_method %int_2, %Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %int_-2.962: Core.IntLiteral = int_value -2 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.5da: <bound method> = bound_method %int_-2.962, %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b [concrete]
// CHECK:STDOUT:   %bound_method.865: <bound method> = bound_method %int_-2.962, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.f33 [concrete]
// CHECK:STDOUT:   %int_-2.0d7: %i64 = int_value -2 [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
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
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.48f: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet.48f [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.bf3: <bound method> = bound_method %int_42.20e, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.098: <bound method> = bound_method %int_42.20e, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_42.ac4: %i32 = int_value 42 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.f7de31.2: type = facet_type <@ImplicitAs, @ImplicitAs(%Int.67af24.1)> [symbolic]
// CHECK:STDOUT:   %T.4e6: %ImplicitAs.type.f7de31.2 = symbolic_binding T, 1 [symbolic]
// CHECK:STDOUT:   %Int.as.EqWith.impl.NotEqual.type.97ec42.1: type = fn_type @Int.as.EqWith.impl.NotEqual.3, @Int.as.EqWith.impl.2b8(%N, %T.4e6) [symbolic]
// CHECK:STDOUT:   %Int.as.EqWith.impl.NotEqual.c6c584.1: %Int.as.EqWith.impl.NotEqual.type.97ec42.1 = struct_value () [symbolic]
// CHECK:STDOUT:   %Int.as.EqWith.impl.NotEqual.type.97ec42.2: type = fn_type @Int.as.EqWith.impl.NotEqual.4, @Int.as.EqWith.impl.2b8(%N, %T.4e6) [symbolic]
// CHECK:STDOUT:   %Int.as.EqWith.impl.NotEqual.c6c584.2: %Int.as.EqWith.impl.NotEqual.type.97ec42.2 = struct_value () [symbolic]
// CHECK:STDOUT:   %EqWith.impl_witness.080: <witness> = impl_witness imports.%EqWith.impl_witness_table.399, @Int.as.EqWith.impl.2b8(%int_64, %ImplicitAs.facet.235) [concrete]
// CHECK:STDOUT:   %Int.as.EqWith.impl.NotEqual.type.356690.1: type = fn_type @Int.as.EqWith.impl.NotEqual.4, @Int.as.EqWith.impl.2b8(%int_64, %ImplicitAs.facet.235) [concrete]
// CHECK:STDOUT:   %Int.as.EqWith.impl.NotEqual.6522b7.1: %Int.as.EqWith.impl.NotEqual.type.356690.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Int.as.EqWith.impl.NotEqual.type.356690.2: type = fn_type @Int.as.EqWith.impl.NotEqual.3, @Int.as.EqWith.impl.2b8(%int_64, %ImplicitAs.facet.235) [concrete]
// CHECK:STDOUT:   %Int.as.EqWith.impl.NotEqual.6522b7.2: %Int.as.EqWith.impl.NotEqual.type.356690.2 = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.401: %EqWith.type.aee = facet_value %i64, (%EqWith.impl_witness.080) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.NotEqual.type.0d6: type = fn_type @EqWith.WithSelf.NotEqual, @EqWith.WithSelf(Core.IntLiteral, %EqWith.facet.401) [concrete]
// CHECK:STDOUT:   %.446: type = fn_type_with_self_type %EqWith.WithSelf.NotEqual.type.0d6, %EqWith.facet.401 [concrete]
// CHECK:STDOUT:   %Int.as.EqWith.impl.NotEqual.specific_fn.c6b368.1: <specific function> = specific_function %Int.as.EqWith.impl.NotEqual.6522b7.2, @Int.as.EqWith.impl.NotEqual.3(%int_64, %ImplicitAs.facet.235) [concrete]
// CHECK:STDOUT:   %Int.as.EqWith.impl.NotEqual.specific_fn.c6b368.2: <specific function> = specific_function %Int.as.EqWith.impl.NotEqual.6522b7.1, @Int.as.EqWith.impl.NotEqual.4(%int_64, %ImplicitAs.facet.235) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.c8b: <bound method> = bound_method %int_42.20e, %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b [concrete]
// CHECK:STDOUT:   %bound_method.f5c: <bound method> = bound_method %int_42.20e, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.f33 [concrete]
// CHECK:STDOUT:   %int_42.b15: %i64 = int_value 42 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.953: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.8: type = fn_type @Destroy.Op.loc27_37.8 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.8: %Destroy.Op.type.1d8f74.8 = struct_value () [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.6e0: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_0.3c0: %i32 = int_value 0 [concrete]
// CHECK:STDOUT:   %Opt.val.5b3: %Opt.46d = struct_value (%int_0.1a7, %uninit.060) [concrete]
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
// CHECK:STDOUT:   %Core.import_ref.2a4: @From.as_type.as.ImplicitAs.impl.%From.as_type.as.ImplicitAs.impl.Convert.type (%From.as_type.as.ImplicitAs.impl.Convert.type.7fa) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @From.as_type.as.ImplicitAs.impl.%From.as_type.as.ImplicitAs.impl.Convert (constants.%From.as_type.as.ImplicitAs.impl.Convert.643)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.992 = impl_witness_table (%Core.import_ref.2a4), @From.as_type.as.ImplicitAs.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.47b: Core.IntLiteral = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.AnyInt.impl.%N (constants.%N)]
// CHECK:STDOUT:   %Core.import_ref.49b: @Int.as.AnyInt.impl.%Int.as.AnyInt.impl.AsInt.type (%Int.as.AnyInt.impl.AsInt.type.f15) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.AnyInt.impl.%Int.as.AnyInt.impl.AsInt (constants.%Int.as.AnyInt.impl.AsInt.d10)]
// CHECK:STDOUT:   %AnyInt.impl_witness_table = impl_witness_table (%Core.import_ref.47b, %Core.import_ref.49b), @Int.as.AnyInt.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.abd = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9c3: %Core.IntLiteral.as.Negate.impl.Op.type = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, loaded [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %Negate.impl_witness_table = impl_witness_table (%Core.import_ref.abd, %Core.import_ref.9c3), @Core.IntLiteral.as.Negate.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.7a7 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.fb5: @Int.as.EqWith.impl.2b8.%Int.as.EqWith.impl.NotEqual.type.2 (%Int.as.EqWith.impl.NotEqual.type.97ec42.1) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.EqWith.impl.2b8.%Int.as.EqWith.impl.NotEqual.2 (constants.%Int.as.EqWith.impl.NotEqual.c6c584.1)]
// CHECK:STDOUT:   %EqWith.impl_witness_table.399 = impl_witness_table (%Core.import_ref.7a7, %Core.import_ref.fb5), @Int.as.EqWith.impl.2b8 [concrete]
// CHECK:STDOUT:   %Core.NotEqual.c83: @Int.as.EqWith.impl.2b8.%Int.as.EqWith.impl.NotEqual.type.1 (%Int.as.EqWith.impl.NotEqual.type.97ec42.2) = import_ref Core//prelude/types/int, NotEqual, loaded [symbolic = @Int.as.EqWith.impl.2b8.%Int.as.EqWith.impl.NotEqual.1 (constants.%Int.as.EqWith.impl.NotEqual.c6c584.2)]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %Opt.Some.decl: @Opt.%Opt.Some.type (%Opt.Some.type.d0c) = fn_decl @Opt.Some [symbolic = @Opt.%Opt.Some (constants.%Opt.Some.821)] {
// CHECK:STDOUT:     %_.param_patt.loc12_21.1: @Opt.Some.%pattern_type.loc12_21.1 (%pattern_type.51d1c4.1) = value_param_pattern [symbolic = %_.param_patt.loc12_21.2 (constants.%_.param_patt.339)]
// CHECK:STDOUT:     %_.patt.loc12_21.1: @Opt.Some.%pattern_type.loc12_21.1 (%pattern_type.51d1c4.1) = at_binding_pattern _, %_.param_patt.loc12_21.1 [symbolic = %_.patt.loc12_21.2 (constants.%_.patt.fd3)]
// CHECK:STDOUT:     %return.param_patt.loc12_21.1: @Opt.Some.%pattern_type.loc12_21.2 (%pattern_type.86b) = out_param_pattern [symbolic = %return.param_patt.loc12_21.2 (constants.%return.param_patt.e2a)]
// CHECK:STDOUT:     %return.patt.loc12_21.1: @Opt.Some.%pattern_type.loc12_21.2 (%pattern_type.86b) = return_slot_pattern %return.param_patt.loc12_21.1, %Opt.loc12_21.2 [symbolic = %return.patt.loc12_21.2 (constants.%return.patt.ac3)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %Opt.loc12_21.2: type = class_type @Opt, @Opt(constants.%T.67d) [symbolic = %Opt.loc12_21.1 (constants.%Opt.ba7)]
// CHECK:STDOUT:     %.loc12_21.11: Core.Form = init_form %Opt.loc12_21.2 [symbolic = %.loc12_21.9 (constants.%.3c3)]
// CHECK:STDOUT:     %_.param: @Opt.Some.%T (%T.67d) = value_param call_param0
// CHECK:STDOUT:     %_: @Opt.Some.%T (%T.67d) = wrapper_binding _, %_.param
// CHECK:STDOUT:     %return.param: ref @Opt.Some.%Opt.loc12_21.1 (%Opt.ba7) = out_param call_param1
// CHECK:STDOUT:     %return: ref @Opt.Some.%Opt.loc12_21.1 (%Opt.ba7) = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Opt.decl: %Opt.type = class_decl @Opt [concrete = constants.%Opt.generic] {
// CHECK:STDOUT:     %T.patt.loc12_13.1: %pattern_type.98f = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc12_13.2 (constants.%T.patt.d47)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc12_15.1: type = splice_block %.loc12_15.2 [concrete = type] {
// CHECK:STDOUT:       %.Self.frozen: %type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %.loc12_15.2: type = type_literal type [concrete = type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc12_13.2: type = symbolic_binding T, 0 [symbolic = %T.loc12_13.1 (constants.%T.67d)]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Widen.decl: %Widen.type = fn_decl @Widen [concrete = constants.%Widen] {
// CHECK:STDOUT:     %o.param_patt: %pattern_type.25d = value_param_pattern [concrete = constants.%o.param_patt]
// CHECK:STDOUT:     %o.patt: %pattern_type.25d = at_binding_pattern o, %o.param_patt [concrete = constants.%o.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.f57 = out_param_pattern [concrete = constants.%return.param_patt.cfc]
// CHECK:STDOUT:     %return.patt: %pattern_type.f57 = return_slot_pattern %return.param_patt, %i64.loc17 [concrete = constants.%return.patt.178]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i64.loc17: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:     %.loc17_26: Core.Form = init_form %i64.loc17 [concrete = constants.%.bc0]
// CHECK:STDOUT:     %o.param: %Opt.46d = value_param call_param0
// CHECK:STDOUT:     %.loc17_20: type = splice_block %Opt [concrete = constants.%Opt.46d] {
// CHECK:STDOUT:       %Opt.ref: %Opt.type = name_ref Opt, file.%Opt.decl [concrete = constants.%Opt.generic]
// CHECK:STDOUT:       %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %Opt: type = class_type @Opt, @Opt(constants.%i32) [concrete = constants.%Opt.46d]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %o: %Opt.46d = wrapper_binding o, %o.param
// CHECK:STDOUT:     %return.param: ref %i64 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i64 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Run.decl: %Run.type = fn_decl @Run [concrete = constants.%Run] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc26 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc26: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc26: Core.Form = init_form %i32.loc26 [concrete = constants.%.795f]
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
// CHECK:STDOUT:     %impl.elem0.loc15_1.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:     %bound_method.loc15_1.1: <bound method> = bound_method %int_1, %impl.elem0.loc15_1.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:     %specific_fn.loc15_1.1: <specific function> = specific_function %impl.elem0.loc15_1.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:     %bound_method.loc15_1.2: <bound method> = bound_method %int_1, %specific_fn.loc15_1.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %u1 = call %bound_method.loc15_1.2(%int_1) [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc15_1.2: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc15_1.3: %u1 = converted %int_1, %.loc15_1.2 [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc15_1.4: %struct_type.discriminant = struct_literal (%.loc15_1.3) [concrete = constants.%struct]
// CHECK:STDOUT:     %impl.elem0.loc15_1.2: %.952 = impl_witness_access constants.%Copy.impl_witness.334, element0 [concrete = constants.%UInt.as.Copy.impl.Op.d9c]
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
// CHECK:STDOUT:   %Opt.loc12_21.1: type = class_type @Opt, @Opt(%T) [symbolic = %Opt.loc12_21.1 (constants.%Opt.ba7)]
// CHECK:STDOUT:   %.loc12_21.9: Core.Form = init_form %Opt.loc12_21.1 [symbolic = %.loc12_21.9 (constants.%.3c3)]
// CHECK:STDOUT:   %pattern_type.loc12_21.2: type = pattern_type %Opt.loc12_21.1 [symbolic = %pattern_type.loc12_21.2 (constants.%pattern_type.86b)]
// CHECK:STDOUT:   %return.param_patt.loc12_21.2: @Opt.Some.%pattern_type.loc12_21.2 (%pattern_type.86b) = out_param_pattern [symbolic = %return.param_patt.loc12_21.2 (constants.%return.param_patt.e2a)]
// CHECK:STDOUT:   %return.patt.loc12_21.2: @Opt.Some.%pattern_type.loc12_21.2 (%pattern_type.86b) = return_slot_pattern %return.param_patt.loc12_21.2, %Opt.loc12_21.1 [symbolic = %return.patt.loc12_21.2 (constants.%return.patt.ac3)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc12_21.1: <witness> = require_complete_type %T [symbolic = %require_complete.loc12_21.1 (constants.%require_complete.944)]
// CHECK:STDOUT:   %require_complete.loc12_21.2: <witness> = require_complete_type %Opt.loc12_21.1 [symbolic = %require_complete.loc12_21.2 (constants.%require_complete.dd1)]
// CHECK:STDOUT:   %tuple.type: type = tuple_type (%T) [symbolic = %tuple.type (constants.%tuple.type.026)]
// CHECK:STDOUT:   %.loc12_21.10: type = custom_layout_type {size=0, align=0, .Some@0: @Opt.Some.%tuple.type (%tuple.type.026)} [symbolic = %.loc12_21.10 (constants.%.a2d)]
// CHECK:STDOUT:   %uninit.loc12_21.2: @Opt.Some.%.loc12_21.10 (%.a2d) = uninitialized_value [symbolic = %uninit.loc12_21.2 (constants.%uninit.37a)]
// CHECK:STDOUT:   %Opt.val: @Opt.Some.%Opt.loc12_21.1 (%Opt.ba7) = struct_value (constants.%int_0.1a7, %uninit.loc12_21.2) [symbolic = %Opt.val (constants.%Opt.val.78a)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%_.param: @Opt.Some.%T (%T.67d)) -> out %return.param: @Opt.Some.%Opt.loc12_21.1 (%Opt.ba7) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %.loc12_21.1: ref %u1 = class_element_access %return.param, element0
// CHECK:STDOUT:     %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:     %impl.elem0: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:     %bound_method.loc12_21.1: <bound method> = bound_method %int_0, %impl.elem0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:     %specific_fn: <specific function> = specific_function %impl.elem0, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:     %bound_method.loc12_21.2: <bound method> = bound_method %int_0, %specific_fn [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %u1 = call %bound_method.loc12_21.2(%int_0) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:     %.loc12_21.2: init %u1 = converted %int_0, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:     %.loc12_21.3: init %u1 to %.loc12_21.1 = in_place_init %.loc12_21.2 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:     %.loc12_21.4: ref @Opt.Some.%.loc12_21.10 (%.a2d) = class_element_access %return.param, element1
// CHECK:STDOUT:     %.loc12_21.5: ref @Opt.Some.%tuple.type (%tuple.type.026) = class_element_access %.loc12_21.4, element0
// CHECK:STDOUT:     %.loc13_17.1: init @Opt.Some.%tuple.type (%tuple.type.026) to %.loc12_21.5 = tuple_init (%_.param)
// CHECK:STDOUT:     %uninit.loc12_21.1: @Opt.Some.%.loc12_21.10 (%.a2d) = uninitialized_value [symbolic = %uninit.loc12_21.2 (constants.%uninit.37a)]
// CHECK:STDOUT:     %.loc12_21.6: init @Opt.Some.%.loc12_21.10 (%.a2d) to %.loc12_21.4 = in_place_init %uninit.loc12_21.1 [symbolic = %uninit.loc12_21.2 (constants.%uninit.37a)]
// CHECK:STDOUT:     %.loc12_21.7: init @Opt.Some.%Opt.loc12_21.1 (%Opt.ba7) to %return.param = class_init (%.loc12_21.3, %.loc12_21.6) [symbolic = %Opt.val (constants.%Opt.val.78a)]
// CHECK:STDOUT:     %.loc12_21.8: init @Opt.Some.%Opt.loc12_21.1 (%Opt.ba7) = update_init %.loc12_21.7, %.loc13_17.1
// CHECK:STDOUT:     %tuple.elem0: ref @Opt.Some.%T (%T.67d) = tuple_access %.loc12_21.5, element0
// CHECK:STDOUT:     %.loc13_17.2: init @Opt.Some.%T (%T.67d) to %tuple.elem0 = in_place_init %_.param
// CHECK:STDOUT:     return %.loc12_21.8 to %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Widen(%o.param: %Opt.46d) -> out %return.param: %i64 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %o.ref: %Opt.46d = name_ref o, %o
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %v.patt: %pattern_type.f57 = value_binding_pattern v [concrete = constants.%v.patt]
// CHECK:STDOUT:     %.loc19_17.1: %pattern_type.335 = tuple_pattern (%v.patt) [concrete = constants.%.c36]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc19_24.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc19_24.1: <bound method> = bound_method %int_0, %impl.elem0.loc19_24.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:   %specific_fn.loc19_24.1: <specific function> = specific_function %impl.elem0.loc19_24.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc19_24.2: <bound method> = bound_method %int_0, %specific_fn.loc19_24.1 [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc19: init %u1 = call %bound_method.loc19_24.2(%int_0) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc19_24.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc19 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc19_24.2: %u1 = converted %int_0, %.loc19_24.1 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc19_24.3: ref %u1 = class_element_access %o.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc19_24.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
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
// CHECK:STDOUT:   %tuple.elem0.loc19_24.1: ref %i32 = tuple_access %.loc19_24.8, element0
// CHECK:STDOUT:   %impl.elem0.loc19_24.3: %.dbf = impl_witness_access constants.%ImplicitAs.impl_witness.8d3, element0 [concrete = constants.%From.as_type.as.ImplicitAs.impl.Convert.15a]
// CHECK:STDOUT:   %bound_method.loc19_24.5: <bound method> = bound_method %tuple.elem0.loc19_24.1, %impl.elem0.loc19_24.3
// CHECK:STDOUT:   %specific_fn.loc19_24.3: <specific function> = specific_function %impl.elem0.loc19_24.3, @From.as_type.as.ImplicitAs.impl.Convert(constants.%int_64, constants.%facet_value) [concrete = constants.%From.as_type.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc19_24.6: <bound method> = bound_method %tuple.elem0.loc19_24.1, %specific_fn.loc19_24.3
// CHECK:STDOUT:   %.loc19_24.9: %i32 = acquire_value %tuple.elem0.loc19_24.1
// CHECK:STDOUT:   %From.as_type.as.ImplicitAs.impl.Convert.call: init %i64 = call %bound_method.loc19_24.6(%.loc19_24.9)
// CHECK:STDOUT:   %.loc19_24.10: %i64 = value_of_initializer %From.as_type.as.ImplicitAs.impl.Convert.call
// CHECK:STDOUT:   %.loc19_24.11: %i64 = converted %tuple.elem0.loc19_24.1, %.loc19_24.10
// CHECK:STDOUT:   %tuple: %tuple.type.f67 = tuple_value (%.loc19_24.11)
// CHECK:STDOUT:   %.loc19_17.2: %tuple.type.f67 = converted %.loc19_24.8, %tuple
// CHECK:STDOUT:   %tuple.elem0.loc19_24.2: %i64 = tuple_access %.loc19_17.2, element0
// CHECK:STDOUT:   %i64.loc19: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:   %v: %i64 = wrapper_binding v, %tuple.elem0.loc19_24.2
// CHECK:STDOUT:   %v.ref: %i64 = name_ref v, %v
// CHECK:STDOUT:   %impl.elem0.loc19_36: %.826 = impl_witness_access constants.%Copy.impl_witness.8cc, element0 [concrete = constants.%Int.as.Copy.impl.Op.d73]
// CHECK:STDOUT:   %bound_method.loc19_36.1: <bound method> = bound_method %v.ref, %impl.elem0.loc19_36
// CHECK:STDOUT:   %specific_fn.loc19_36: <specific function> = specific_function %impl.elem0.loc19_36, @Int.as.Copy.impl.Op(constants.%int_64) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn.b95]
// CHECK:STDOUT:   %bound_method.loc19_36.2: <bound method> = bound_method %v.ref, %specific_fn.loc19_36
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i64 = call %bound_method.loc19_36.2(%v.ref)
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
// CHECK:STDOUT:   %impl.elem0.loc20_16.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc20_16.1: <bound method> = bound_method %int_1.loc20_16, %impl.elem0.loc20_16.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc20_16.1: <specific function> = specific_function %impl.elem0.loc20_16.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc20_16.2: <bound method> = bound_method %int_1.loc20_16, %specific_fn.loc20_16.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc20_16: init %u1 = call %bound_method.loc20_16.2(%int_1.loc20_16) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc20_16.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc20_16 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc20_16.2: %u1 = converted %int_1.loc20_16, %.loc20_16.1 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc20_16.3: ref %u1 = class_element_access %o.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc20_16.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
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
// CHECK:STDOUT:   %impl.elem1.loc20: %.758 = impl_witness_access constants.%Negate.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %bound_method.loc20_28: <bound method> = bound_method %int_1.loc20_29, %impl.elem1.loc20 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op.bound.6a0]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.call.loc20: init Core.IntLiteral = call %bound_method.loc20_28(%int_1.loc20_29) [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %impl.elem0.loc20_30: %.03f = impl_witness_access constants.%ImplicitAs.impl_witness.227, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b]
// CHECK:STDOUT:   %bound_method.loc20_30.1: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call.loc20, %impl.elem0.loc20_30 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.bc7]
// CHECK:STDOUT:   %specific_fn.loc20_30: <specific function> = specific_function %impl.elem0.loc20_30, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.f33]
// CHECK:STDOUT:   %bound_method.loc20_30.2: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call.loc20, %specific_fn.loc20_30 [concrete = constants.%bound_method.ef0]
// CHECK:STDOUT:   %.loc20_28.1: Core.IntLiteral = value_of_initializer %Core.IntLiteral.as.Negate.impl.Op.call.loc20 [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %.loc20_28.2: Core.IntLiteral = converted %Core.IntLiteral.as.Negate.impl.Op.call.loc20, %.loc20_28.1 [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc20_30: init %i64 = call %bound_method.loc20_30.2(%.loc20_28.2) [concrete = constants.%int_-1.a7e]
// CHECK:STDOUT:   %.loc20_30: init %i64 = converted %Core.IntLiteral.as.Negate.impl.Op.call.loc20, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc20_30 [concrete = constants.%int_-1.a7e]
// CHECK:STDOUT:   return %.loc20_30
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc20:
// CHECK:STDOUT:   br !match.done
// CHECK:STDOUT:
// CHECK:STDOUT: !match.done:
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2]
// CHECK:STDOUT:   %impl.elem1.loc23: %.758 = impl_witness_access constants.%Negate.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %bound_method.loc23_10: <bound method> = bound_method %int_2, %impl.elem1.loc23 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op.bound.e21]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.call.loc23: init Core.IntLiteral = call %bound_method.loc23_10(%int_2) [concrete = constants.%int_-2.962]
// CHECK:STDOUT:   %impl.elem0.loc23: %.03f = impl_witness_access constants.%ImplicitAs.impl_witness.227, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b]
// CHECK:STDOUT:   %bound_method.loc23_12.1: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call.loc23, %impl.elem0.loc23 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.5da]
// CHECK:STDOUT:   %specific_fn.loc23: <specific function> = specific_function %impl.elem0.loc23, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.f33]
// CHECK:STDOUT:   %bound_method.loc23_12.2: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call.loc23, %specific_fn.loc23 [concrete = constants.%bound_method.865]
// CHECK:STDOUT:   %.loc23_10.1: Core.IntLiteral = value_of_initializer %Core.IntLiteral.as.Negate.impl.Op.call.loc23 [concrete = constants.%int_-2.962]
// CHECK:STDOUT:   %.loc23_10.2: Core.IntLiteral = converted %Core.IntLiteral.as.Negate.impl.Op.call.loc23, %.loc23_10.1 [concrete = constants.%int_-2.962]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc23: init %i64 = call %bound_method.loc23_12.2(%.loc23_10.2) [concrete = constants.%int_-2.0d7]
// CHECK:STDOUT:   %.loc23_12: init %i64 = converted %Core.IntLiteral.as.Negate.impl.Op.call.loc23, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc23 [concrete = constants.%int_-2.0d7]
// CHECK:STDOUT:   return %.loc23_12
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Run() -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Opt.ref.loc27_21: %Opt.type = name_ref Opt, file.%Opt.decl [concrete = constants.%Opt.generic]
// CHECK:STDOUT:   %i32.loc27_25: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %Opt.loc27_28: type = class_type @Opt, @Opt(constants.%i32) [concrete = constants.%Opt.46d]
// CHECK:STDOUT:   %.loc27_29: %Opt.Some.type.39e = specific_constant generated.%Opt.Some.decl, @Opt(constants.%i32) [concrete = constants.%Opt.Some.733]
// CHECK:STDOUT:   %Some.ref: %Opt.Some.type.39e = name_ref Some, %.loc27_29 [concrete = constants.%Opt.Some.733]
// CHECK:STDOUT:   %int_42.loc27: Core.IntLiteral = int_value 42 [concrete = constants.%int_42.20e]
// CHECK:STDOUT:   %Opt.Some.specific_fn: <specific function> = specific_function %Some.ref, @Opt.Some(constants.%i32) [concrete = constants.%Opt.Some.specific_fn]
// CHECK:STDOUT:   %.loc27_37.1: ref %Opt.46d = temporary_storage
// CHECK:STDOUT:   %impl.elem0.loc27: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc27_35.1: <bound method> = bound_method %int_42.loc27, %impl.elem0.loc27 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.bf3]
// CHECK:STDOUT:   %specific_fn.loc27: <specific function> = specific_function %impl.elem0.loc27, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc27_35.2: <bound method> = bound_method %int_42.loc27, %specific_fn.loc27 [concrete = constants.%bound_method.098]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc27: init %i32 = call %bound_method.loc27_35.2(%int_42.loc27) [concrete = constants.%int_42.ac4]
// CHECK:STDOUT:   %.loc27_35.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc27 [concrete = constants.%int_42.ac4]
// CHECK:STDOUT:   %.loc27_35.2: %i32 = converted %int_42.loc27, %.loc27_35.1 [concrete = constants.%int_42.ac4]
// CHECK:STDOUT:   %Opt.Some.call: init %Opt.46d to %.loc27_37.1 = call %Opt.Some.specific_fn(%.loc27_35.2)
// CHECK:STDOUT:   %.loc27_37.2: ref %Opt.46d = temporary %.loc27_37.1, %Opt.Some.call
// CHECK:STDOUT:   %.loc27_37.3: %Opt.46d = acquire_value %.loc27_37.2
// CHECK:STDOUT:   %.loc27_17: type = splice_block %Opt.loc27_17 [concrete = constants.%Opt.46d] {
// CHECK:STDOUT:     %Opt.ref.loc27_10: %Opt.type = name_ref Opt, file.%Opt.decl [concrete = constants.%Opt.generic]
// CHECK:STDOUT:     %i32.loc27_14: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %Opt.loc27_17: type = class_type @Opt, @Opt(constants.%i32) [concrete = constants.%Opt.46d]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %s: %Opt.46d = wrapper_binding s, %.loc27_37.3
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %s.patt: %pattern_type.25d = value_binding_pattern s [concrete = constants.%s.patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Widen.ref: %Widen.type = name_ref Widen, file.%Widen.decl [concrete = constants.%Widen]
// CHECK:STDOUT:   %s.ref: %Opt.46d = name_ref s, %s
// CHECK:STDOUT:   %Widen.call: init %i64 = call %Widen.ref(%s.ref)
// CHECK:STDOUT:   %int_42.loc28: Core.IntLiteral = int_value 42 [concrete = constants.%int_42.20e]
// CHECK:STDOUT:   %impl.elem1: %.446 = impl_witness_access constants.%EqWith.impl_witness.080, element1 [concrete = constants.%Int.as.EqWith.impl.NotEqual.6522b7.2]
// CHECK:STDOUT:   %bound_method.loc28_16.1: <bound method> = bound_method %Widen.call, %impl.elem1
// CHECK:STDOUT:   %specific_fn.loc28_16: <specific function> = specific_function %impl.elem1, @Int.as.EqWith.impl.NotEqual.3(constants.%int_64, constants.%ImplicitAs.facet.235) [concrete = constants.%Int.as.EqWith.impl.NotEqual.specific_fn.c6b368.1]
// CHECK:STDOUT:   %bound_method.loc28_16.2: <bound method> = bound_method %Widen.call, %specific_fn.loc28_16
// CHECK:STDOUT:   %.loc28_14.1: %i64 = value_of_initializer %Widen.call
// CHECK:STDOUT:   %.loc28_14.2: %i64 = converted %Widen.call, %.loc28_14.1
// CHECK:STDOUT:   %.loc28_16: %Int.as.EqWith.impl.NotEqual.type.356690.1 = specific_constant imports.%Core.NotEqual.c83, @Int.as.EqWith.impl.2b8(constants.%int_64, constants.%ImplicitAs.facet.235) [concrete = constants.%Int.as.EqWith.impl.NotEqual.6522b7.1]
// CHECK:STDOUT:   %NotEqual.ref: %Int.as.EqWith.impl.NotEqual.type.356690.1 = name_ref NotEqual, %.loc28_16 [concrete = constants.%Int.as.EqWith.impl.NotEqual.6522b7.1]
// CHECK:STDOUT:   %Int.as.EqWith.impl.NotEqual.bound: <bound method> = bound_method %.loc28_14.2, %NotEqual.ref
// CHECK:STDOUT:   %Int.as.EqWith.impl.NotEqual.specific_fn: <specific function> = specific_function %NotEqual.ref, @Int.as.EqWith.impl.NotEqual.4(constants.%int_64, constants.%ImplicitAs.facet.235) [concrete = constants.%Int.as.EqWith.impl.NotEqual.specific_fn.c6b368.2]
// CHECK:STDOUT:   %bound_method.loc28_16.3: <bound method> = bound_method %.loc28_14.2, %Int.as.EqWith.impl.NotEqual.specific_fn
// CHECK:STDOUT:   %impl.elem0.loc28: %.03f = impl_witness_access constants.%ImplicitAs.impl_witness.227, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b]
// CHECK:STDOUT:   %bound_method.loc28_19.1: <bound method> = bound_method %int_42.loc28, %impl.elem0.loc28 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.c8b]
// CHECK:STDOUT:   %specific_fn.loc28_19: <specific function> = specific_function %impl.elem0.loc28, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.f33]
// CHECK:STDOUT:   %bound_method.loc28_19.2: <bound method> = bound_method %int_42.loc28, %specific_fn.loc28_19 [concrete = constants.%bound_method.f5c]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc28: init %i64 = call %bound_method.loc28_19.2(%int_42.loc28) [concrete = constants.%int_42.b15]
// CHECK:STDOUT:   %.loc28_19.1: %i64 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc28 [concrete = constants.%int_42.b15]
// CHECK:STDOUT:   %.loc28_19.2: %i64 = converted %int_42.loc28, %.loc28_19.1 [concrete = constants.%int_42.b15]
// CHECK:STDOUT:   %Int.as.EqWith.impl.NotEqual.call: init bool = call %bound_method.loc28_16.3(%.loc28_14.2, %.loc28_19.2)
// CHECK:STDOUT:   %.loc28_21.1: bool = value_of_initializer %Int.as.EqWith.impl.NotEqual.call
// CHECK:STDOUT:   %.loc28_21.2: bool = converted %Int.as.EqWith.impl.NotEqual.call, %.loc28_21.1
// CHECK:STDOUT:   if %.loc28_21.2 br !if.then else br !if.else
// CHECK:STDOUT:
// CHECK:STDOUT: !if.then:
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc29: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc29_13.1: <bound method> = bound_method %int_1, %impl.elem0.loc29 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc29: <specific function> = specific_function %impl.elem0.loc29, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc29_13.2: <bound method> = bound_method %int_1, %specific_fn.loc29 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc29: init %i32 = call %bound_method.loc29_13.2(%int_1) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc29: init %i32 = converted %int_1, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc29 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %Destroy.Op.bound.loc27_37.1: <bound method> = bound_method %.loc27_37.2, constants.%Destroy.Op.1a2547.8
// CHECK:STDOUT:   %Destroy.Op.call.loc27_37.1: init %empty_tuple.type = call %Destroy.Op.bound.loc27_37.1(%.loc27_37.2)
// CHECK:STDOUT:   return %.loc29
// CHECK:STDOUT:
// CHECK:STDOUT: !if.else:
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc31: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc31_11.1: <bound method> = bound_method %int_0, %impl.elem0.loc31 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc31: <specific function> = specific_function %impl.elem0.loc31, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc31_11.2: <bound method> = bound_method %int_0, %specific_fn.loc31 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc31: init %i32 = call %bound_method.loc31_11.2(%int_0) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc31: init %i32 = converted %int_0, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc31 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %Destroy.Op.bound.loc27_37.2: <bound method> = bound_method %.loc27_37.2, constants.%Destroy.Op.1a2547.8
// CHECK:STDOUT:   %Destroy.Op.call.loc27_37.2: init %empty_tuple.type = call %Destroy.Op.bound.loc27_37.2(%.loc27_37.2)
// CHECK:STDOUT:   return %.loc31
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc27_37.1(%self.param: ref %u1.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc27_37.2(%self.param: ref %u1) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc27_37.3(%self.param: ref %i32.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc27_37.4(%self.param: ref %i32) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc27_37.5(%self.param: ref %tuple.type.a8a) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc27_37.6(%self.param: ref %.e8e) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc27_37.7(%self.param: ref %struct_type.discriminant.payload.e99) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc27_37.8(%self.param: ref %Opt.46d) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Opt(constants.%T.67d) {
// CHECK:STDOUT:   %T.patt.loc12_13.2 => constants.%T.patt.d47
// CHECK:STDOUT:   %T.loc12_13.1 => constants.%T.67d
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Opt.Some(constants.%T.67d) {
// CHECK:STDOUT:   %T => constants.%T.67d
// CHECK:STDOUT:   %pattern_type.loc12_21.1 => constants.%pattern_type.51d1c4.1
// CHECK:STDOUT:   %_.param_patt.loc12_21.2 => constants.%_.param_patt.339
// CHECK:STDOUT:   %_.patt.loc12_21.2 => constants.%_.patt.fd3
// CHECK:STDOUT:   %Opt.loc12_21.1 => constants.%Opt.ba7
// CHECK:STDOUT:   %.loc12_21.9 => constants.%.3c3
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
// CHECK:STDOUT:   %Opt.loc12_21.1 => constants.%Opt.46d
// CHECK:STDOUT:   %.loc12_21.9 => constants.%.bda
// CHECK:STDOUT:   %pattern_type.loc12_21.2 => constants.%pattern_type.25d
// CHECK:STDOUT:   %return.param_patt.loc12_21.2 => constants.%return.param_patt.63c
// CHECK:STDOUT:   %return.patt.loc12_21.2 => constants.%return.patt.c82
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc12_21.1 => constants.%complete_type.f8a
// CHECK:STDOUT:   %require_complete.loc12_21.2 => constants.%complete_type.378
// CHECK:STDOUT:   %tuple.type => constants.%tuple.type.a8a
// CHECK:STDOUT:   %.loc12_21.10 => constants.%.e8e
// CHECK:STDOUT:   %uninit.loc12_21.2 => constants.%uninit.060
// CHECK:STDOUT:   %Opt.val => constants.%Opt.val.5b3
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- use_imported.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %P.type: type = generic_class_type @P [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %P.generic: %P.type = struct_value () [concrete]
// CHECK:STDOUT:   %T.67d: type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %tuple.type.07a: type = tuple_type (%T.67d, %T.67d) [symbolic]
// CHECK:STDOUT:   %.d27: type = custom_layout_type {size=0, align=0, .Both@0: %tuple.type.07a} [symbolic]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %u1: type = class_type @UInt, @UInt(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %u1.builtin: type = int_type unsigned, %int_1.5b8 [concrete]
// CHECK:STDOUT:   %P.f86: type = class_type @P, @P(%T.67d) [symbolic]
// CHECK:STDOUT:   %uninit.216: %.d27 = uninitialized_value [symbolic]
// CHECK:STDOUT:   %int_1.233: %u1 = int_value 1 [concrete]
// CHECK:STDOUT:   %P.val.a40: %P.f86 = struct_value (%int_1.233, %uninit.216) [symbolic]
// CHECK:STDOUT:   %P.Both.type.e35: type = fn_type @P.Both, @P(%T.67d) [symbolic]
// CHECK:STDOUT:   %P.Both.862: %P.Both.type.e35 = struct_value () [symbolic]
// CHECK:STDOUT:   %int_0.1a7: %u1 = int_value 0 [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %Int.67af24.1: type = class_type @Int, @Int(%N) [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %P.b38: type = class_type @P, @P(%i32) [concrete]
// CHECK:STDOUT:   %pattern_type.e96: type = pattern_type %P.b38 [concrete]
// CHECK:STDOUT:   %p.param_patt: %pattern_type.e96 = value_param_pattern [concrete]
// CHECK:STDOUT:   %p.patt: %pattern_type.e96 = at_binding_pattern p, %p.param_patt [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %Sum.type: type = fn_type @Sum [concrete]
// CHECK:STDOUT:   %Sum: %Sum.type = struct_value () [concrete]
// CHECK:STDOUT:   %i32.builtin: type = int_type signed, %int_32 [concrete]
// CHECK:STDOUT:   %tuple.type.e55: type = tuple_type (%i32, %i32) [concrete]
// CHECK:STDOUT:   %.20c: type = custom_layout_type {size=8, align=4, .Both@0: %tuple.type.e55} [concrete]
// CHECK:STDOUT:   %struct_type.discriminant.payload.92c: type = struct_type {.discriminant: %u1, .payload: %.20c} [concrete]
// CHECK:STDOUT:   %P.Both.type.571: type = fn_type @P.Both, @P(%i32) [concrete]
// CHECK:STDOUT:   %P.Both.ce5: %P.Both.type.571 = struct_value () [concrete]
// CHECK:STDOUT:   %uninit.525: %.20c = uninitialized_value [concrete]
// CHECK:STDOUT:   %P.val.3d1: %P.b38 = struct_value (%int_1.233, %uninit.525) [concrete]
// CHECK:STDOUT:   %x.patt.939: %pattern_type.6b6 = value_binding_pattern x [concrete]
// CHECK:STDOUT:   %y.patt.489: %pattern_type.6b6 = value_binding_pattern y [concrete]
// CHECK:STDOUT:   %pattern_type.394: type = pattern_type %tuple.type.e55 [concrete]
// CHECK:STDOUT:   %.692: %pattern_type.394 = tuple_pattern (%x.patt.939, %y.patt.489) [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
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
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.0e8: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
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
// CHECK:STDOUT:   %AddWith.type.be9: type = facet_type <@AddWith, @AddWith(%i32)> [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.610: type = fn_type @Int.as.AddWith.impl.Op.1, @Int.as.AddWith.impl.3af(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.732: %Int.as.AddWith.impl.Op.type.610 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.type.f7de31.1: type = facet_type <@ImplicitAs, @ImplicitAs(%Int.67af24.1)> [symbolic]
// CHECK:STDOUT:   %U.4e6: %ImplicitAs.type.f7de31.1 = symbolic_binding U, 1 [symbolic]
// CHECK:STDOUT:   %AddWith.impl_witness.833: <witness> = impl_witness imports.%AddWith.impl_witness_table.6b4, @Int.as.AddWith.impl.3af(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.056: type = fn_type @Int.as.AddWith.impl.Op.1, @Int.as.AddWith.impl.3af(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.365: %Int.as.AddWith.impl.Op.type.056 = struct_value () [concrete]
// CHECK:STDOUT:   %AddWith.facet.76a: %AddWith.type.be9 = facet_value %i32, (%AddWith.impl_witness.833) [concrete]
// CHECK:STDOUT:   %AddWith.WithSelf.Op.type.02a: type = fn_type @AddWith.WithSelf.Op, @AddWith.WithSelf(%i32, %AddWith.facet.76a) [concrete]
// CHECK:STDOUT:   %.d47: type = fn_type_with_self_type %AddWith.WithSelf.Op.type.02a, %AddWith.facet.76a [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.specific_fn.f25: <specific function> = specific_function %Int.as.AddWith.impl.Op.365, @Int.as.AddWith.impl.Op.1(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %bound_method.d7a: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound.22c: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
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
// CHECK:STDOUT:   %Construct.type: type = fn_type @Construct [concrete]
// CHECK:STDOUT:   %Construct: %Construct.type = struct_value () [concrete]
// CHECK:STDOUT:   %b.patt: %pattern_type.e96 = value_binding_pattern b [concrete]
// CHECK:STDOUT:   %int_20.5cd: Core.IntLiteral = int_value 20 [concrete]
// CHECK:STDOUT:   %int_22.aa7: Core.IntLiteral = int_value 22 [concrete]
// CHECK:STDOUT:   %P.Both.specific_fn: <specific function> = specific_function %P.Both.ce5, @P.Both(%i32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.bb6: <bound method> = bound_method %int_20.5cd, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.55f: <bound method> = bound_method %int_20.5cd, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_20.aeb: %i32 = int_value 20 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.158: <bound method> = bound_method %int_22.aa7, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.bc4: <bound method> = bound_method %int_22.aa7, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_22.f93: %i32 = int_value 22 [concrete]
// CHECK:STDOUT:   %int_42.20e: Core.IntLiteral = int_value 42 [concrete]
// CHECK:STDOUT:   %SubWith.type.4c2: type = facet_type <@SubWith, @SubWith(Core.IntLiteral)> [concrete]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.type.6f3321.1: type = fn_type @Int.as.SubWith.impl.Op.2, @Int.as.SubWith.impl.dc8(%N, %U.4e6) [symbolic]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.a37528.1: %Int.as.SubWith.impl.Op.type.6f3321.1 = struct_value () [symbolic]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.type.6f3321.2: type = fn_type @Int.as.SubWith.impl.Op.3, @Int.as.SubWith.impl.dc8(%N, %U.4e6) [symbolic]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.a37528.2: %Int.as.SubWith.impl.Op.type.6f3321.2 = struct_value () [symbolic]
// CHECK:STDOUT:   %SubWith.impl_witness.447: <witness> = impl_witness imports.%SubWith.impl_witness_table.038, @Int.as.SubWith.impl.dc8(%int_32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.type.657f13.1: type = fn_type @Int.as.SubWith.impl.Op.3, @Int.as.SubWith.impl.dc8(%int_32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.fa84b9.1: %Int.as.SubWith.impl.Op.type.657f13.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.type.657f13.2: type = fn_type @Int.as.SubWith.impl.Op.2, @Int.as.SubWith.impl.dc8(%int_32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.fa84b9.2: %Int.as.SubWith.impl.Op.type.657f13.2 = struct_value () [concrete]
// CHECK:STDOUT:   %SubWith.facet.775: %SubWith.type.4c2 = facet_value %i32, (%SubWith.impl_witness.447) [concrete]
// CHECK:STDOUT:   %SubWith.WithSelf.Op.type.d32: type = fn_type @SubWith.WithSelf.Op, @SubWith.WithSelf(Core.IntLiteral, %SubWith.facet.775) [concrete]
// CHECK:STDOUT:   %.ae9: type = fn_type_with_self_type %SubWith.WithSelf.Op.type.d32, %SubWith.facet.775 [concrete]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.specific_fn.13b586.1: <specific function> = specific_function %Int.as.SubWith.impl.Op.fa84b9.2, @Int.as.SubWith.impl.Op.2(%int_32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.specific_fn.13b586.2: <specific function> = specific_function %Int.as.SubWith.impl.Op.fa84b9.1, @Int.as.SubWith.impl.Op.3(%int_32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.bf3: <bound method> = bound_method %int_42.20e, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.098: <bound method> = bound_method %int_42.20e, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_42.ac4: %i32 = int_value 42 [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.8: type = fn_type @Destroy.Op.loc23_37.8 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.8: %Destroy.Op.type.1d8f74.8 = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Main.P: %P.type = import_ref Main//plib, P, loaded [concrete = constants.%P.generic]
// CHECK:STDOUT:   %Main.import_ref.46a: @P.%P.Both.type (%P.Both.type.e35) = import_ref Main//plib, loc3_19, loaded [symbolic = @P.%P.Both (constants.%P.Both.862)]
// CHECK:STDOUT:   %Main.import_ref.3cd: @P.%P (%P.f86) = import_ref Main//plib, loc6_1, loaded [symbolic = @P.%P.val (constants.%P.val.a40)]
// CHECK:STDOUT:   %Core.import_ref.aa5: @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.170)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.f01 = impl_witness_table (%Core.import_ref.aa5), @Core.IntLiteral.as.ImplicitAs.impl.b68 [concrete]
// CHECK:STDOUT:   %Core.import_ref.b92: @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal.type (%UInt.as.EqWith.impl.Equal.type.544) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal (constants.%UInt.as.EqWith.impl.Equal.c67)]
// CHECK:STDOUT:   %Core.import_ref.b44 = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.166 = impl_witness_table (%Core.import_ref.b92, %Core.import_ref.b44), @UInt.as.EqWith.impl.f13 [concrete]
// CHECK:STDOUT:   %Core.import_ref.b4fd3a.1 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.684: @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op.type (%Int.as.AddWith.impl.Op.type.610) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op (constants.%Int.as.AddWith.impl.Op.732)]
// CHECK:STDOUT:   %AddWith.impl_witness_table.6b4 = impl_witness_table (%Core.import_ref.b4fd3a.1, %Core.import_ref.684), @Int.as.AddWith.impl.3af [concrete]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.abd = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9c3: %Core.IntLiteral.as.Negate.impl.Op.type = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, loaded [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %Negate.impl_witness_table = impl_witness_table (%Core.import_ref.abd, %Core.import_ref.9c3), @Core.IntLiteral.as.Negate.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.b4fd3a.5 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.6fa: @Int.as.SubWith.impl.dc8.%Int.as.SubWith.impl.Op.type.2 (%Int.as.SubWith.impl.Op.type.6f3321.1) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.SubWith.impl.dc8.%Int.as.SubWith.impl.Op.2 (constants.%Int.as.SubWith.impl.Op.a37528.1)]
// CHECK:STDOUT:   %SubWith.impl_witness_table.038 = impl_witness_table (%Core.import_ref.b4fd3a.5, %Core.import_ref.6fa), @Int.as.SubWith.impl.dc8 [concrete]
// CHECK:STDOUT:   %Core.Op.9ff: @Int.as.SubWith.impl.dc8.%Int.as.SubWith.impl.Op.type.1 (%Int.as.SubWith.impl.Op.type.6f3321.2) = import_ref Core//prelude/types/int, Op, loaded [symbolic = @Int.as.SubWith.impl.dc8.%Int.as.SubWith.impl.Op.1 (constants.%Int.as.SubWith.impl.Op.a37528.2)]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Sum.decl: %Sum.type = fn_decl @Sum [concrete = constants.%Sum] {
// CHECK:STDOUT:     %p.param_patt: %pattern_type.e96 = value_param_pattern [concrete = constants.%p.param_patt]
// CHECK:STDOUT:     %p.patt: %pattern_type.e96 = at_binding_pattern p, %p.param_patt [concrete = constants.%p.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc13_22 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc13_22: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc13_22: Core.Form = init_form %i32.loc13_22 [concrete = constants.%.795f]
// CHECK:STDOUT:     %p.param: %P.b38 = value_param call_param0
// CHECK:STDOUT:     %.loc13_16: type = splice_block %P [concrete = constants.%P.b38] {
// CHECK:STDOUT:       %P.ref: %P.type = name_ref P, imports.%Main.P [concrete = constants.%P.generic]
// CHECK:STDOUT:       %i32.loc13_13: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %P: type = class_type @P, @P(constants.%i32) [concrete = constants.%P.b38]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %p: %P.b38 = wrapper_binding p, %p.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Construct.decl: %Construct.type = fn_decl @Construct [concrete = constants.%Construct] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc22 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc22: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc22: Core.Form = init_form %i32.loc22 [concrete = constants.%.795f]
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param0
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Sum(%p.param: %P.b38) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %p.ref: %P.b38 = name_ref p, %p
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %x.patt: %pattern_type.6b6 = value_binding_pattern x [concrete = constants.%x.patt.939]
// CHECK:STDOUT:     %y.patt: %pattern_type.6b6 = value_binding_pattern y [concrete = constants.%y.patt.489]
// CHECK:STDOUT:     %.loc15_30: %pattern_type.394 = tuple_pattern (%x.patt, %y.patt) [concrete = constants.%.692]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_0.loc15: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc15_32.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc15_32.1: <bound method> = bound_method %int_0.loc15, %impl.elem0.loc15_32.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:   %specific_fn.loc15_32.1: <specific function> = specific_function %impl.elem0.loc15_32.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc15_32.2: <bound method> = bound_method %int_0.loc15, %specific_fn.loc15_32.1 [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc15: init %u1 = call %bound_method.loc15_32.2(%int_0.loc15) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc15_32.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc15 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc15_32.2: %u1 = converted %int_0.loc15, %.loc15_32.1 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc15_32.3: ref %u1 = class_element_access %p.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc15_32.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc15_32.3: <bound method> = bound_method %.loc15_32.2, %impl.elem0.loc15_32.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.f34]
// CHECK:STDOUT:   %specific_fn.loc15_32.2: <specific function> = specific_function %impl.elem0.loc15_32.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc15_32.4: <bound method> = bound_method %.loc15_32.2, %specific_fn.loc15_32.2 [concrete = constants.%bound_method.53a]
// CHECK:STDOUT:   %.loc15_32.4: %u1 = acquire_value %.loc15_32.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc15: init bool = call %bound_method.loc15_32.4(%.loc15_32.2, %.loc15_32.4)
// CHECK:STDOUT:   %.loc15_32.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc15
// CHECK:STDOUT:   %.loc15_32.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc15, %.loc15_32.5
// CHECK:STDOUT:   if %.loc15_32.6 br !match.case.then.loc15 else br !match.case.else.loc15
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc15:
// CHECK:STDOUT:   %.loc15_32.7: ref %.20c = class_element_access %p.ref, element1
// CHECK:STDOUT:   %.loc15_32.8: ref %tuple.type.e55 = class_element_access %.loc15_32.7, element0
// CHECK:STDOUT:   %tuple.elem0: ref %i32 = tuple_access %.loc15_32.8, element0
// CHECK:STDOUT:   %tuple.elem1: ref %i32 = tuple_access %.loc15_32.8, element1
// CHECK:STDOUT:   %.loc15_32.9: %i32 = acquire_value %tuple.elem0
// CHECK:STDOUT:   %i32.loc15_19: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %x: %i32 = wrapper_binding x, %.loc15_32.9
// CHECK:STDOUT:   %.loc15_32.10: %i32 = acquire_value %tuple.elem1
// CHECK:STDOUT:   %i32.loc15_27: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %y: %i32 = wrapper_binding y, %.loc15_32.10
// CHECK:STDOUT:   %x.ref: %i32 = name_ref x, %x
// CHECK:STDOUT:   %y.ref: %i32 = name_ref y, %y
// CHECK:STDOUT:   %impl.elem1.loc15: %.d47 = impl_witness_access constants.%AddWith.impl_witness.833, element1 [concrete = constants.%Int.as.AddWith.impl.Op.365]
// CHECK:STDOUT:   %bound_method.loc15_46.1: <bound method> = bound_method %x.ref, %impl.elem1.loc15
// CHECK:STDOUT:   %specific_fn.loc15_46: <specific function> = specific_function %impl.elem1.loc15, @Int.as.AddWith.impl.Op.1(constants.%int_32) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.f25]
// CHECK:STDOUT:   %bound_method.loc15_46.2: <bound method> = bound_method %x.ref, %specific_fn.loc15_46
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call: init %i32 = call %bound_method.loc15_46.2(%x.ref, %y.ref)
// CHECK:STDOUT:   return %Int.as.AddWith.impl.Op.call
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc15:
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt: %pattern_type.e96 = expr_pattern %Neither.ref in [concrete] {
// CHECK:STDOUT:       %.loc16_10.2: %P.b38 = specific_constant imports.%Main.import_ref.3cd, @P(constants.%i32) [concrete = constants.%P.val.3d1]
// CHECK:STDOUT:       %Neither.ref: %P.b38 = name_ref Neither, %.loc16_10.2 [concrete = constants.%P.val.3d1]
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %.loc16_10.1: %P.b38 = splice_block %Neither.ref [concrete = constants.%P.val.3d1] {
// CHECK:STDOUT:     %.loc16_10.2: %P.b38 = specific_constant imports.%Main.import_ref.3cd, @P(constants.%i32) [concrete = constants.%P.val.3d1]
// CHECK:STDOUT:     %Neither.ref: %P.b38 = name_ref Neither, %.loc16_10.2 [concrete = constants.%P.val.3d1]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_1.loc16: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc16_19.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc16_19.1: <bound method> = bound_method %int_1.loc16, %impl.elem0.loc16_19.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc16_19.1: <specific function> = specific_function %impl.elem0.loc16_19.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc16_19.2: <bound method> = bound_method %int_1.loc16, %specific_fn.loc16_19.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16_19: init %u1 = call %bound_method.loc16_19.2(%int_1.loc16) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc16_19.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16_19 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc16_19.2: %u1 = converted %int_1.loc16, %.loc16_19.1 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc16_19.3: ref %u1 = class_element_access %p.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc16_19.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc16_19.3: <bound method> = bound_method %.loc16_19.2, %impl.elem0.loc16_19.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.22c]
// CHECK:STDOUT:   %specific_fn.loc16_19.2: <specific function> = specific_function %impl.elem0.loc16_19.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc16_19.4: <bound method> = bound_method %.loc16_19.2, %specific_fn.loc16_19.2 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc16_19.4: %u1 = acquire_value %.loc16_19.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc16: init bool = call %bound_method.loc16_19.4(%.loc16_19.2, %.loc16_19.4)
// CHECK:STDOUT:   %.loc16_19.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc16
// CHECK:STDOUT:   %.loc16_19.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc16, %.loc16_19.5
// CHECK:STDOUT:   if %.loc16_19.6 br !match.case.then.loc16 else br !match.case.else.loc16
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc16:
// CHECK:STDOUT:   %int_0.loc16: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc16_32: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc16_32.1: <bound method> = bound_method %int_0.loc16, %impl.elem0.loc16_32 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc16_32: <specific function> = specific_function %impl.elem0.loc16_32, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc16_32.2: <bound method> = bound_method %int_0.loc16, %specific_fn.loc16_32 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16_32: init %i32 = call %bound_method.loc16_32.2(%int_0.loc16) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc16_32: init %i32 = converted %int_0.loc16, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16_32 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   return %.loc16_32
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc16:
// CHECK:STDOUT:   br !match.done
// CHECK:STDOUT:
// CHECK:STDOUT: !match.done:
// CHECK:STDOUT:   %int_1.loc19: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem1.loc19: %.758 = impl_witness_access constants.%Negate.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %bound_method.loc19_10: <bound method> = bound_method %int_1.loc19, %impl.elem1.loc19 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op.bound]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.call: init Core.IntLiteral = call %bound_method.loc19_10(%int_1.loc19) [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %impl.elem0.loc19: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc19_12.1: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %impl.elem0.loc19 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.65e]
// CHECK:STDOUT:   %specific_fn.loc19: <specific function> = specific_function %impl.elem0.loc19, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc19_12.2: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %specific_fn.loc19 [concrete = constants.%bound_method.a65]
// CHECK:STDOUT:   %.loc19_10.1: Core.IntLiteral = value_of_initializer %Core.IntLiteral.as.Negate.impl.Op.call [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %.loc19_10.2: Core.IntLiteral = converted %Core.IntLiteral.as.Negate.impl.Op.call, %.loc19_10.1 [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc19: init %i32 = call %bound_method.loc19_12.2(%.loc19_10.2) [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   %.loc19_12: init %i32 = converted %Core.IntLiteral.as.Negate.impl.Op.call, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc19 [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   return %.loc19_12
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Construct() -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %P.ref.loc23_19: %P.type = name_ref P, imports.%Main.P [concrete = constants.%P.generic]
// CHECK:STDOUT:   %i32.loc23_21: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %P.loc23_24: type = class_type @P, @P(constants.%i32) [concrete = constants.%P.b38]
// CHECK:STDOUT:   %.loc23_25: %P.Both.type.571 = specific_constant imports.%Main.import_ref.46a, @P(constants.%i32) [concrete = constants.%P.Both.ce5]
// CHECK:STDOUT:   %Both.ref: %P.Both.type.571 = name_ref Both, %.loc23_25 [concrete = constants.%P.Both.ce5]
// CHECK:STDOUT:   %int_20: Core.IntLiteral = int_value 20 [concrete = constants.%int_20.5cd]
// CHECK:STDOUT:   %int_22: Core.IntLiteral = int_value 22 [concrete = constants.%int_22.aa7]
// CHECK:STDOUT:   %P.Both.specific_fn: <specific function> = specific_function %Both.ref, @P.Both(constants.%i32) [concrete = constants.%P.Both.specific_fn]
// CHECK:STDOUT:   %.loc23_37.1: ref %P.b38 = temporary_storage
// CHECK:STDOUT:   %impl.elem0.loc23_31: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc23_31.1: <bound method> = bound_method %int_20, %impl.elem0.loc23_31 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.bb6]
// CHECK:STDOUT:   %specific_fn.loc23_31: <specific function> = specific_function %impl.elem0.loc23_31, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc23_31.2: <bound method> = bound_method %int_20, %specific_fn.loc23_31 [concrete = constants.%bound_method.55f]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc23_31: init %i32 = call %bound_method.loc23_31.2(%int_20) [concrete = constants.%int_20.aeb]
// CHECK:STDOUT:   %.loc23_31.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc23_31 [concrete = constants.%int_20.aeb]
// CHECK:STDOUT:   %.loc23_31.2: %i32 = converted %int_20, %.loc23_31.1 [concrete = constants.%int_20.aeb]
// CHECK:STDOUT:   %impl.elem0.loc23_35: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc23_35.1: <bound method> = bound_method %int_22, %impl.elem0.loc23_35 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.158]
// CHECK:STDOUT:   %specific_fn.loc23_35: <specific function> = specific_function %impl.elem0.loc23_35, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc23_35.2: <bound method> = bound_method %int_22, %specific_fn.loc23_35 [concrete = constants.%bound_method.bc4]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc23_35: init %i32 = call %bound_method.loc23_35.2(%int_22) [concrete = constants.%int_22.f93]
// CHECK:STDOUT:   %.loc23_35.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc23_35 [concrete = constants.%int_22.f93]
// CHECK:STDOUT:   %.loc23_35.2: %i32 = converted %int_22, %.loc23_35.1 [concrete = constants.%int_22.f93]
// CHECK:STDOUT:   %P.Both.call: init %P.b38 to %.loc23_37.1 = call %P.Both.specific_fn(%.loc23_31.2, %.loc23_35.2)
// CHECK:STDOUT:   %.loc23_37.2: ref %P.b38 = temporary %.loc23_37.1, %P.Both.call
// CHECK:STDOUT:   %.loc23_37.3: %P.b38 = acquire_value %.loc23_37.2
// CHECK:STDOUT:   %.loc23_15: type = splice_block %P.loc23_15 [concrete = constants.%P.b38] {
// CHECK:STDOUT:     %P.ref.loc23_10: %P.type = name_ref P, imports.%Main.P [concrete = constants.%P.generic]
// CHECK:STDOUT:     %i32.loc23_12: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %P.loc23_15: type = class_type @P, @P(constants.%i32) [concrete = constants.%P.b38]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %b: %P.b38 = wrapper_binding b, %.loc23_37.3
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %b.patt: %pattern_type.e96 = value_binding_pattern b [concrete = constants.%b.patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Sum.ref: %Sum.type = name_ref Sum, file.%Sum.decl [concrete = constants.%Sum]
// CHECK:STDOUT:   %b.ref: %P.b38 = name_ref b, %b
// CHECK:STDOUT:   %Sum.call: init %i32 = call %Sum.ref(%b.ref)
// CHECK:STDOUT:   %int_42: Core.IntLiteral = int_value 42 [concrete = constants.%int_42.20e]
// CHECK:STDOUT:   %impl.elem1: %.ae9 = impl_witness_access constants.%SubWith.impl_witness.447, element1 [concrete = constants.%Int.as.SubWith.impl.Op.fa84b9.2]
// CHECK:STDOUT:   %bound_method.loc24_17.1: <bound method> = bound_method %Sum.call, %impl.elem1
// CHECK:STDOUT:   %specific_fn.loc24_17: <specific function> = specific_function %impl.elem1, @Int.as.SubWith.impl.Op.2(constants.%int_32, constants.%ImplicitAs.facet.48f) [concrete = constants.%Int.as.SubWith.impl.Op.specific_fn.13b586.1]
// CHECK:STDOUT:   %bound_method.loc24_17.2: <bound method> = bound_method %Sum.call, %specific_fn.loc24_17
// CHECK:STDOUT:   %.loc24_15.1: %i32 = value_of_initializer %Sum.call
// CHECK:STDOUT:   %.loc24_15.2: %i32 = converted %Sum.call, %.loc24_15.1
// CHECK:STDOUT:   %.loc24_17: %Int.as.SubWith.impl.Op.type.657f13.1 = specific_constant imports.%Core.Op.9ff, @Int.as.SubWith.impl.dc8(constants.%int_32, constants.%ImplicitAs.facet.48f) [concrete = constants.%Int.as.SubWith.impl.Op.fa84b9.1]
// CHECK:STDOUT:   %Op.ref: %Int.as.SubWith.impl.Op.type.657f13.1 = name_ref Op, %.loc24_17 [concrete = constants.%Int.as.SubWith.impl.Op.fa84b9.1]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.bound: <bound method> = bound_method %.loc24_15.2, %Op.ref
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.specific_fn: <specific function> = specific_function %Op.ref, @Int.as.SubWith.impl.Op.3(constants.%int_32, constants.%ImplicitAs.facet.48f) [concrete = constants.%Int.as.SubWith.impl.Op.specific_fn.13b586.2]
// CHECK:STDOUT:   %bound_method.loc24_17.3: <bound method> = bound_method %.loc24_15.2, %Int.as.SubWith.impl.Op.specific_fn
// CHECK:STDOUT:   %impl.elem0.loc24: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc24_19.1: <bound method> = bound_method %int_42, %impl.elem0.loc24 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.bf3]
// CHECK:STDOUT:   %specific_fn.loc24_19: <specific function> = specific_function %impl.elem0.loc24, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc24_19.2: <bound method> = bound_method %int_42, %specific_fn.loc24_19 [concrete = constants.%bound_method.098]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc24: init %i32 = call %bound_method.loc24_19.2(%int_42) [concrete = constants.%int_42.ac4]
// CHECK:STDOUT:   %.loc24_19.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc24 [concrete = constants.%int_42.ac4]
// CHECK:STDOUT:   %.loc24_19.2: %i32 = converted %int_42, %.loc24_19.1 [concrete = constants.%int_42.ac4]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.call: init %i32 = call %bound_method.loc24_17.3(%.loc24_15.2, %.loc24_19.2)
// CHECK:STDOUT:   %Destroy.Op.bound: <bound method> = bound_method %.loc23_37.2, constants.%Destroy.Op.1a2547.8
// CHECK:STDOUT:   %Destroy.Op.call: init %empty_tuple.type = call %Destroy.Op.bound(%.loc23_37.2)
// CHECK:STDOUT:   return %Int.as.SubWith.impl.Op.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc23_37.1(%self.param: ref %u1.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc23_37.2(%self.param: ref %u1) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc23_37.3(%self.param: ref %i32.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc23_37.4(%self.param: ref %i32) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc23_37.5(%self.param: ref %tuple.type.e55) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc23_37.6(%self.param: ref %.20c) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc23_37.7(%self.param: ref %struct_type.discriminant.payload.92c) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc23_37.8(%self.param: ref %P.b38) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- symbolic.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %.Self.frozen: %type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %pattern_type.98f: type = pattern_type type [concrete]
// CHECK:STDOUT:   %T.patt.d47: %pattern_type.98f = symbolic_binding_pattern T, 0 [symbolic]
// CHECK:STDOUT:   %T.67d: type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %P.type: type = generic_class_type @P [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %P.generic: %P.type = struct_value () [concrete]
// CHECK:STDOUT:   %P.f86: type = class_type @P, @P(%T.67d) [symbolic]
// CHECK:STDOUT:   %pattern_type.51d1c4.1: type = pattern_type %T.67d [symbolic]
// CHECK:STDOUT:   %x.param_patt.91d: %pattern_type.51d1c4.1 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %x.patt.800: %pattern_type.51d1c4.1 = at_binding_pattern x, %x.param_patt.91d [symbolic]
// CHECK:STDOUT:   %y.param_patt.be3: %pattern_type.51d1c4.1 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %y.patt.b85: %pattern_type.51d1c4.1 = at_binding_pattern y, %y.param_patt.be3 [symbolic]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %u1: type = class_type @UInt, @UInt(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %require_complete.9443dd.1: <witness> = require_complete_type %T.67d [symbolic]
// CHECK:STDOUT:   %tuple.type.07a: type = tuple_type (%T.67d, %T.67d) [symbolic]
// CHECK:STDOUT:   %.d27: type = custom_layout_type {size=0, align=0, .Both@0: %tuple.type.07a} [symbolic]
// CHECK:STDOUT:   %struct_type.discriminant.payload.1ec: type = struct_type {.discriminant: %u1, .payload: %.d27} [symbolic]
// CHECK:STDOUT:   %complete_type.d2c: <witness> = complete_type_witness %struct_type.discriminant.payload.1ec [symbolic]
// CHECK:STDOUT:   %struct_type.discriminant: type = struct_type {.discriminant: %u1} [concrete]
// CHECK:STDOUT:   %_.param_patt.339927.1: %pattern_type.51d1c4.1 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %_.patt.fd3aed.1: %pattern_type.51d1c4.1 = at_binding_pattern _, %_.param_patt.339927.1 [symbolic]
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
// CHECK:STDOUT:   %U.patt.d47: %pattern_type.98f = symbolic_binding_pattern U, 0 [symbolic]
// CHECK:STDOUT:   %U.67d: type = symbolic_binding U, 0 [symbolic]
// CHECK:STDOUT:   %pattern_type.51d1c4.4: type = pattern_type %U.67d [symbolic]
// CHECK:STDOUT:   %_.param_patt.339927.2: %pattern_type.51d1c4.4 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %_.patt.fd3aed.2: %pattern_type.51d1c4.4 = at_binding_pattern _, %_.param_patt.339927.2 [symbolic]
// CHECK:STDOUT:   %Discard.type: type = fn_type @Discard [concrete]
// CHECK:STDOUT:   %Discard: %Discard.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete.9443dd.2: <witness> = require_complete_type %U.67d [symbolic]
// CHECK:STDOUT:   %p.param_patt.631: %pattern_type.6d3 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %p.patt.4ce: %pattern_type.6d3 = at_binding_pattern p, %p.param_patt.631 [symbolic]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %Classify.type: type = fn_type @Classify [concrete]
// CHECK:STDOUT:   %Classify: %Classify.type = struct_value () [concrete]
// CHECK:STDOUT:   %i32.builtin: type = int_type signed, %int_32 [concrete]
// CHECK:STDOUT:   %complete_type.f8a: <witness> = complete_type_witness %i32.builtin [concrete]
// CHECK:STDOUT:   %a.patt.54f: %pattern_type.51d1c4.1 = value_binding_pattern a [symbolic]
// CHECK:STDOUT:   %b.patt.b98: %pattern_type.51d1c4.1 = value_binding_pattern b [symbolic]
// CHECK:STDOUT:   %pattern_type.c3f: type = pattern_type %tuple.type.07a [symbolic]
// CHECK:STDOUT:   %.dcb: %pattern_type.c3f = tuple_pattern (%a.patt.54f, %b.patt.b98) [symbolic]
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
// CHECK:STDOUT:   %Discard.specific_fn.628: <specific function> = specific_function %Discard, @Discard(%T.67d) [symbolic]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.48f: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet.48f [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.953: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound.22c: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %bound_method.a82: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.6e0: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
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
// CHECK:STDOUT:   %bound_method.a65: <bound method> = bound_method %int_-1.638, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_-1.4ef: %i32 = int_value -1 [concrete]
// CHECK:STDOUT:   %P.b38: type = class_type @P, @P(%i32) [concrete]
// CHECK:STDOUT:   %pattern_type.e96: type = pattern_type %P.b38 [concrete]
// CHECK:STDOUT:   %p.param_patt.d8e: %pattern_type.e96 = value_param_pattern [concrete]
// CHECK:STDOUT:   %p.patt.38d: %pattern_type.e96 = at_binding_pattern p, %p.param_patt.d8e [concrete]
// CHECK:STDOUT:   %Call.type: type = fn_type @Call [concrete]
// CHECK:STDOUT:   %Call: %Call.type = struct_value () [concrete]
// CHECK:STDOUT:   %x.param_patt.cee: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %x.patt.fbe: %pattern_type.6b6 = at_binding_pattern x, %x.param_patt.cee [concrete]
// CHECK:STDOUT:   %y.param_patt.673: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %y.patt.b43: %pattern_type.6b6 = at_binding_pattern y, %y.param_patt.673 [concrete]
// CHECK:STDOUT:   %tuple.type.e55: type = tuple_type (%i32, %i32) [concrete]
// CHECK:STDOUT:   %.20c: type = custom_layout_type {size=8, align=4, .Both@0: %tuple.type.e55} [concrete]
// CHECK:STDOUT:   %struct_type.discriminant.payload.92c: type = struct_type {.discriminant: %u1, .payload: %.20c} [concrete]
// CHECK:STDOUT:   %complete_type.ea6: <witness> = complete_type_witness %struct_type.discriminant.payload.92c [concrete]
// CHECK:STDOUT:   %P.Both.type.571: type = fn_type @P.Both, @P(%i32) [concrete]
// CHECK:STDOUT:   %P.Both.ce5: %P.Both.type.571 = struct_value () [concrete]
// CHECK:STDOUT:   %uninit.525: %.20c = uninitialized_value [concrete]
// CHECK:STDOUT:   %P.val.3d1: %P.b38 = struct_value (%int_1.233, %uninit.525) [concrete]
// CHECK:STDOUT:   %.b5a: ref %P.b38 = temporary invalid, %P.val.3d1 [concrete]
// CHECK:STDOUT:   %Classify.specific_fn: <specific function> = specific_function %Classify, @Classify(%i32) [concrete]
// CHECK:STDOUT:   %a.patt.bb2: %pattern_type.6b6 = value_binding_pattern a [concrete]
// CHECK:STDOUT:   %b.patt.e7d: %pattern_type.6b6 = value_binding_pattern b [concrete]
// CHECK:STDOUT:   %pattern_type.394: type = pattern_type %tuple.type.e55 [concrete]
// CHECK:STDOUT:   %.d82: %pattern_type.394 = tuple_pattern (%a.patt.bb2, %b.patt.e7d) [concrete]
// CHECK:STDOUT:   %_.param_patt.fb2: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %_.patt.b75: %pattern_type.6b6 = at_binding_pattern _, %_.param_patt.fb2 [concrete]
// CHECK:STDOUT:   %Discard.specific_fn.f3f: <specific function> = specific_function %Discard, @Discard(%i32) [concrete]
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
// CHECK:STDOUT:   %Core.import_ref.abd = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9c3: %Core.IntLiteral.as.Negate.impl.Op.type = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, loaded [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %Negate.impl_witness_table = impl_witness_table (%Core.import_ref.abd, %Core.import_ref.9c3), @Core.IntLiteral.as.Negate.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %P.Both.decl: @P.%P.Both.type (%P.Both.type.e35) = fn_decl @P.Both [symbolic = @P.%P.Both (constants.%P.Both.862)] {
// CHECK:STDOUT:     %_.param_patt.loc16_19.1: @P.Both.%pattern_type.loc16_19.1 (%pattern_type.51d1c4.1) = value_param_pattern [symbolic = %_.param_patt.loc16_19.3 (constants.%_.param_patt.339927.1)]
// CHECK:STDOUT:     %_.patt.loc16_19.1: @P.Both.%pattern_type.loc16_19.1 (%pattern_type.51d1c4.1) = at_binding_pattern _, %_.param_patt.loc16_19.1 [symbolic = %_.patt.loc16_19.3 (constants.%_.patt.fd3aed.1)]
// CHECK:STDOUT:     %_.param_patt.loc16_19.2: @P.Both.%pattern_type.loc16_19.1 (%pattern_type.51d1c4.1) = value_param_pattern [symbolic = %_.param_patt.loc16_19.3 (constants.%_.param_patt.339927.1)]
// CHECK:STDOUT:     %_.patt.loc16_19.2: @P.Both.%pattern_type.loc16_19.1 (%pattern_type.51d1c4.1) = at_binding_pattern _, %_.param_patt.loc16_19.2 [symbolic = %_.patt.loc16_19.3 (constants.%_.patt.fd3aed.1)]
// CHECK:STDOUT:     %return.param_patt.loc16_19.1: @P.Both.%pattern_type.loc16_19.2 (%pattern_type.6d3) = out_param_pattern [symbolic = %return.param_patt.loc16_19.2 (constants.%return.param_patt.3b8)]
// CHECK:STDOUT:     %return.patt.loc16_19.1: @P.Both.%pattern_type.loc16_19.2 (%pattern_type.6d3) = return_slot_pattern %return.param_patt.loc16_19.1, %P.loc16_19.2 [symbolic = %return.patt.loc16_19.2 (constants.%return.patt.ec6)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %P.loc16_19.2: type = class_type @P, @P(constants.%T.67d) [symbolic = %P.loc16_19.1 (constants.%P.f86)]
// CHECK:STDOUT:     %.loc16_19.11: Core.Form = init_form %P.loc16_19.2 [symbolic = %.loc16_19.9 (constants.%.3a8)]
// CHECK:STDOUT:     %_.param.loc16_19.1: @P.Both.%T (%T.67d) = value_param call_param0
// CHECK:STDOUT:     %_.loc16_19.1: @P.Both.%T (%T.67d) = wrapper_binding _, %_.param.loc16_19.1
// CHECK:STDOUT:     %_.param.loc16_19.2: @P.Both.%T (%T.67d) = value_param call_param1
// CHECK:STDOUT:     %_.loc16_19.2: @P.Both.%T (%T.67d) = wrapper_binding _, %_.param.loc16_19.2
// CHECK:STDOUT:     %return.param: ref @P.Both.%P.loc16_19.1 (%P.f86) = out_param call_param2
// CHECK:STDOUT:     %return: ref @P.Both.%P.loc16_19.1 (%P.f86) = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %P.decl: %P.type = class_decl @P [concrete = constants.%P.generic] {
// CHECK:STDOUT:     %T.patt.loc16_11.1: %pattern_type.98f = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc16_11.2 (constants.%T.patt.d47)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc16_13.1: type = splice_block %.loc16_13.2 [concrete = type] {
// CHECK:STDOUT:       %.Self.frozen: %type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %.loc16_13.2: type = type_literal type [concrete = type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc16_11.2: type = symbolic_binding T, 0 [symbolic = %T.loc16_11.1 (constants.%T.67d)]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Discard.decl: %Discard.type = fn_decl @Discard [concrete = constants.%Discard] {
// CHECK:STDOUT:     %U.patt.loc21_13.1: %pattern_type.98f = symbolic_binding_pattern U, 0 [symbolic = %U.patt.loc21_13.2 (constants.%U.patt.d47)]
// CHECK:STDOUT:     %_.param_patt.loc21_22.1: @Discard.%pattern_type (%pattern_type.51d1c4.4) = value_param_pattern [symbolic = %_.param_patt.loc21_22.2 (constants.%_.param_patt.339927.2)]
// CHECK:STDOUT:     %_.patt.loc21_22.1: @Discard.%pattern_type (%pattern_type.51d1c4.4) = at_binding_pattern _, %_.param_patt.loc21_22.1 [symbolic = %_.patt.loc21_22.2 (constants.%_.patt.fd3aed.2)]
// CHECK:STDOUT:     %_.param_patt.loc21_28: @Discard.%pattern_type (%pattern_type.51d1c4.4) = value_param_pattern [symbolic = %_.param_patt.loc21_22.2 (constants.%_.param_patt.339927.2)]
// CHECK:STDOUT:     %_.patt.loc21_28: @Discard.%pattern_type (%pattern_type.51d1c4.4) = at_binding_pattern _, %_.param_patt.loc21_28 [symbolic = %_.patt.loc21_22.2 (constants.%_.patt.fd3aed.2)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc21_15.1: type = splice_block %.loc21_15.2 [concrete = type] {
// CHECK:STDOUT:       %.Self.frozen: %type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %.loc21_15.2: type = type_literal type [concrete = type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %U.loc21_13.2: type = symbolic_binding U, 0 [symbolic = %U.loc21_13.1 (constants.%U.67d)]
// CHECK:STDOUT:     %_.param.loc21_22: @Discard.%U.loc21_13.1 (%U.67d) = value_param call_param0
// CHECK:STDOUT:     %U.ref.loc21_24: type = name_ref U, %U.loc21_13.2 [symbolic = %U.loc21_13.1 (constants.%U.67d)]
// CHECK:STDOUT:     %_.loc21_22: @Discard.%U.loc21_13.1 (%U.67d) = wrapper_binding _, %_.param.loc21_22
// CHECK:STDOUT:     %_.param.loc21_28: @Discard.%U.loc21_13.1 (%U.67d) = value_param call_param1
// CHECK:STDOUT:     %U.ref.loc21_30: type = name_ref U, %U.loc21_13.2 [symbolic = %U.loc21_13.1 (constants.%U.67d)]
// CHECK:STDOUT:     %_.loc21_28: @Discard.%U.loc21_13.1 (%U.67d) = wrapper_binding _, %_.param.loc21_28
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Classify.decl: %Classify.type = fn_decl @Classify [concrete = constants.%Classify] {
// CHECK:STDOUT:     %T.patt.loc23_14.1: %pattern_type.98f = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc23_14.2 (constants.%T.patt.d47)]
// CHECK:STDOUT:     %p.param_patt.loc23_23.1: @Classify.%pattern_type.loc23 (%pattern_type.6d3) = value_param_pattern [symbolic = %p.param_patt.loc23_23.2 (constants.%p.param_patt.631)]
// CHECK:STDOUT:     %p.patt.loc23_23.1: @Classify.%pattern_type.loc23 (%pattern_type.6d3) = at_binding_pattern p, %p.param_patt.loc23_23.1 [symbolic = %p.patt.loc23_23.2 (constants.%p.patt.4ce)]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc23_34: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %.loc23_16.1: type = splice_block %.loc23_16.2 [concrete = type] {
// CHECK:STDOUT:       %.Self.frozen: %type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %.loc23_16.2: type = type_literal type [concrete = type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc23_14.2: type = symbolic_binding T, 0 [symbolic = %T.loc23_14.1 (constants.%T.67d)]
// CHECK:STDOUT:     %p.param: @Classify.%P.loc23_28.1 (%P.f86) = value_param call_param0
// CHECK:STDOUT:     %.loc23_28: type = splice_block %P.loc23_28.2 [symbolic = %P.loc23_28.1 (constants.%P.f86)] {
// CHECK:STDOUT:       %P.ref: %P.type = name_ref P, file.%P.decl [concrete = constants.%P.generic]
// CHECK:STDOUT:       %T.ref.loc23: type = name_ref T, %T.loc23_14.2 [symbolic = %T.loc23_14.1 (constants.%T.67d)]
// CHECK:STDOUT:       %P.loc23_28.2: type = class_type @P, @P(constants.%T.67d) [symbolic = %P.loc23_28.1 (constants.%P.f86)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %p: @Classify.%P.loc23_28.1 (%P.f86) = wrapper_binding p, %p.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Call.decl: %Call.type = fn_decl @Call [concrete = constants.%Call] {
// CHECK:STDOUT:     %p.param_patt: %pattern_type.e96 = value_param_pattern [concrete = constants.%p.param_patt.d8e]
// CHECK:STDOUT:     %p.patt: %pattern_type.e96 = at_binding_pattern p, %p.param_patt [concrete = constants.%p.patt.38d]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc35_23 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc35_23: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc35_23: Core.Form = init_form %i32.loc35_23 [concrete = constants.%.795f]
// CHECK:STDOUT:     %p.param: %P.b38 = value_param call_param0
// CHECK:STDOUT:     %.loc35_17: type = splice_block %P [concrete = constants.%P.b38] {
// CHECK:STDOUT:       %P.ref: %P.type = name_ref P, file.%P.decl [concrete = constants.%P.generic]
// CHECK:STDOUT:       %i32.loc35_14: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %P: type = class_type @P, @P(constants.%i32) [concrete = constants.%P.b38]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %p: %P.b38 = wrapper_binding p, %p.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic class @P(%T.loc16_11.2: type) {
// CHECK:STDOUT:   %T.patt.loc16_11.2: %pattern_type.98f = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc16_11.2 (constants.%T.patt.d47)]
// CHECK:STDOUT:   %T.loc16_11.1: type = symbolic_binding T, 0 [symbolic = %T.loc16_11.1 (constants.%T.67d)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %pattern_type: type = pattern_type %T.loc16_11.1 [symbolic = %pattern_type (constants.%pattern_type.51d1c4.1)]
// CHECK:STDOUT:   %x.param_patt: @P.%pattern_type (%pattern_type.51d1c4.1) = value_param_pattern [symbolic = %x.param_patt (constants.%x.param_patt.91d)]
// CHECK:STDOUT:   %x.patt: @P.%pattern_type (%pattern_type.51d1c4.1) = at_binding_pattern x, %x.param_patt [symbolic = %x.patt (constants.%x.patt.800)]
// CHECK:STDOUT:   %y.param_patt: @P.%pattern_type (%pattern_type.51d1c4.1) = value_param_pattern [symbolic = %y.param_patt (constants.%y.param_patt.be3)]
// CHECK:STDOUT:   %y.patt: @P.%pattern_type (%pattern_type.51d1c4.1) = at_binding_pattern y, %y.param_patt [symbolic = %y.patt (constants.%y.patt.b85)]
// CHECK:STDOUT:   %require_complete.loc17: <witness> = require_complete_type %T.loc16_11.1 [symbolic = %require_complete.loc17 (constants.%require_complete.9443dd.1)]
// CHECK:STDOUT:   %tuple.type: type = tuple_type (%T.loc16_11.1, %T.loc16_11.1) [symbolic = %tuple.type (constants.%tuple.type.07a)]
// CHECK:STDOUT:   %.loc19_1.14: type = custom_layout_type {size=0, align=0, .Both@0: @P.%tuple.type (%tuple.type.07a)} [symbolic = %.loc19_1.14 (constants.%.d27)]
// CHECK:STDOUT:   %struct_type.discriminant.payload: type = struct_type {.discriminant: %u1, .payload: @P.%.loc19_1.14 (%.d27)} [symbolic = %struct_type.discriminant.payload (constants.%struct_type.discriminant.payload.1ec)]
// CHECK:STDOUT:   %complete_type.loc19_1.2: <witness> = complete_type_witness %struct_type.discriminant.payload [symbolic = %complete_type.loc19_1.2 (constants.%complete_type.d2c)]
// CHECK:STDOUT:   %P.Both.type: type = fn_type @P.Both, @P(%T.loc16_11.1) [symbolic = %P.Both.type (constants.%P.Both.type.e35)]
// CHECK:STDOUT:   %P.Both: @P.%P.Both.type (%P.Both.type.e35) = struct_value () [symbolic = %P.Both (constants.%P.Both.862)]
// CHECK:STDOUT:   %P: type = class_type @P, @P(%T.loc16_11.1) [symbolic = %P (constants.%P.f86)]
// CHECK:STDOUT:   %require_complete.loc19: <witness> = require_complete_type %P [symbolic = %require_complete.loc19 (constants.%require_complete.657)]
// CHECK:STDOUT:   %uninit.loc19_1.2: @P.%.loc19_1.14 (%.d27) = uninitialized_value [symbolic = %uninit.loc19_1.2 (constants.%uninit.216)]
// CHECK:STDOUT:   %P.val: @P.%P (%P.f86) = struct_value (constants.%int_1.233, %uninit.loc19_1.2) [symbolic = %P.val (constants.%P.val.a40)]
// CHECK:STDOUT:   %.loc19_1.15: ref @P.%P (%P.f86) = temporary invalid, %P.val [symbolic = %.loc19_1.15 (constants.%.a21)]
// CHECK:STDOUT:
// CHECK:STDOUT:   class {
// CHECK:STDOUT:     %x.param: @P.%T.loc16_11.1 (%T.67d) = value_param call_param0
// CHECK:STDOUT:     %T.ref.loc17_11: type = name_ref T, %T.loc16_11.2 [symbolic = %T.loc16_11.1 (constants.%T.67d)]
// CHECK:STDOUT:     %x: @P.%T.loc16_11.1 (%T.67d) = wrapper_binding x, %x.param
// CHECK:STDOUT:     %y.param: @P.%T.loc16_11.1 (%T.67d) = value_param call_param1
// CHECK:STDOUT:     %T.ref.loc17_17: type = name_ref T, %T.loc16_11.2 [symbolic = %T.loc16_11.1 (constants.%T.67d)]
// CHECK:STDOUT:     %y: @P.%T.loc16_11.1 (%T.67d) = wrapper_binding y, %y.param
// CHECK:STDOUT:     %.loc19_1.1: type = custom_layout_type {size=0, align=0, .Both@0: %tuple.type.07a} [symbolic = %.loc19_1.14 (constants.%.d27)]
// CHECK:STDOUT:     %complete_type.loc19_1.1: <witness> = complete_type_witness constants.%struct_type.discriminant.payload.1ec [symbolic = %complete_type.loc19_1.2 (constants.%complete_type.d2c)]
// CHECK:STDOUT:     %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:     %impl.elem0.loc19_1.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:     %bound_method.loc19_1.1: <bound method> = bound_method %int_1, %impl.elem0.loc19_1.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:     %specific_fn.loc19_1.1: <specific function> = specific_function %impl.elem0.loc19_1.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:     %bound_method.loc19_1.2: <bound method> = bound_method %int_1, %specific_fn.loc19_1.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %u1 = call %bound_method.loc19_1.2(%int_1) [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc19_1.2: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc19_1.3: %u1 = converted %int_1, %.loc19_1.2 [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc19_1.4: %struct_type.discriminant = struct_literal (%.loc19_1.3) [concrete = constants.%struct]
// CHECK:STDOUT:     %impl.elem0.loc19_1.2: %.952 = impl_witness_access constants.%Copy.impl_witness.334, element0 [concrete = constants.%UInt.as.Copy.impl.Op.d9c]
// CHECK:STDOUT:     %bound_method.loc19_1.3: <bound method> = bound_method %.loc19_1.3, %impl.elem0.loc19_1.2 [concrete = constants.%UInt.as.Copy.impl.Op.bound]
// CHECK:STDOUT:     %specific_fn.loc19_1.2: <specific function> = specific_function %impl.elem0.loc19_1.2, @UInt.as.Copy.impl.Op(constants.%int_1.5b8) [concrete = constants.%UInt.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:     %bound_method.loc19_1.4: <bound method> = bound_method %.loc19_1.3, %specific_fn.loc19_1.2 [concrete = constants.%bound_method.edd]
// CHECK:STDOUT:     %UInt.as.Copy.impl.Op.call: init %u1 = call %bound_method.loc19_1.4(%.loc19_1.3) [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc19_1.5: ref @P.%P (%P.f86) = temporary_storage
// CHECK:STDOUT:     %.loc19_1.6: ref %u1 = class_element_access %.loc19_1.5, element0
// CHECK:STDOUT:     %.loc19_1.7: init %u1 to %.loc19_1.6 = in_place_init %UInt.as.Copy.impl.Op.call [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc19_1.8: ref @P.%.loc19_1.14 (%.d27) = class_element_access %.loc19_1.5, element1
// CHECK:STDOUT:     %uninit.loc19_1.1: @P.%.loc19_1.14 (%.d27) = uninitialized_value [symbolic = %uninit.loc19_1.2 (constants.%uninit.216)]
// CHECK:STDOUT:     %.loc19_1.9: init @P.%.loc19_1.14 (%.d27) to %.loc19_1.8 = in_place_init %uninit.loc19_1.1 [symbolic = %uninit.loc19_1.2 (constants.%uninit.216)]
// CHECK:STDOUT:     %.loc19_1.10: init @P.%P (%P.f86) to %.loc19_1.5 = class_init (%.loc19_1.7, %.loc19_1.9) [symbolic = %P.val (constants.%P.val.a40)]
// CHECK:STDOUT:     %.loc19_1.11: init @P.%P (%P.f86) = converted %.loc19_1.4, %.loc19_1.10 [symbolic = %P.val (constants.%P.val.a40)]
// CHECK:STDOUT:     %.loc19_1.12: ref @P.%P (%P.f86) = temporary %.loc19_1.5, %.loc19_1.11 [symbolic = %.loc19_1.15 (constants.%.a21)]
// CHECK:STDOUT:     %.loc19_1.13: @P.%P (%P.f86) = acquire_value %.loc19_1.12 [symbolic = %P.val (constants.%P.val.a40)]
// CHECK:STDOUT:     %Neither: @P.%P (%P.f86) = wrapper_binding Neither, %.loc19_1.13
// CHECK:STDOUT:     complete_type_witness = %complete_type.loc19_1.1
// CHECK:STDOUT:
// CHECK:STDOUT:   !members:
// CHECK:STDOUT:     .Self = constants.%P.f86
// CHECK:STDOUT:     .T = <poisoned>
// CHECK:STDOUT:     .Both = generated.%P.Both.decl
// CHECK:STDOUT:     .Neither = %Neither
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @P.Both(@P.%T.loc16_11.2: type) {
// CHECK:STDOUT:   %T: type = symbolic_binding T, 0 [symbolic = %T (constants.%T.67d)]
// CHECK:STDOUT:   %pattern_type.loc16_19.1: type = pattern_type %T [symbolic = %pattern_type.loc16_19.1 (constants.%pattern_type.51d1c4.1)]
// CHECK:STDOUT:   %_.param_patt.loc16_19.3: @P.Both.%pattern_type.loc16_19.1 (%pattern_type.51d1c4.1) = value_param_pattern [symbolic = %_.param_patt.loc16_19.3 (constants.%_.param_patt.339927.1)]
// CHECK:STDOUT:   %_.patt.loc16_19.3: @P.Both.%pattern_type.loc16_19.1 (%pattern_type.51d1c4.1) = at_binding_pattern _, %_.param_patt.loc16_19.3 [symbolic = %_.patt.loc16_19.3 (constants.%_.patt.fd3aed.1)]
// CHECK:STDOUT:   %P.loc16_19.1: type = class_type @P, @P(%T) [symbolic = %P.loc16_19.1 (constants.%P.f86)]
// CHECK:STDOUT:   %.loc16_19.9: Core.Form = init_form %P.loc16_19.1 [symbolic = %.loc16_19.9 (constants.%.3a8)]
// CHECK:STDOUT:   %pattern_type.loc16_19.2: type = pattern_type %P.loc16_19.1 [symbolic = %pattern_type.loc16_19.2 (constants.%pattern_type.6d3)]
// CHECK:STDOUT:   %return.param_patt.loc16_19.2: @P.Both.%pattern_type.loc16_19.2 (%pattern_type.6d3) = out_param_pattern [symbolic = %return.param_patt.loc16_19.2 (constants.%return.param_patt.3b8)]
// CHECK:STDOUT:   %return.patt.loc16_19.2: @P.Both.%pattern_type.loc16_19.2 (%pattern_type.6d3) = return_slot_pattern %return.param_patt.loc16_19.2, %P.loc16_19.1 [symbolic = %return.patt.loc16_19.2 (constants.%return.patt.ec6)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc16_19.1: <witness> = require_complete_type %T [symbolic = %require_complete.loc16_19.1 (constants.%require_complete.9443dd.1)]
// CHECK:STDOUT:   %require_complete.loc16_19.2: <witness> = require_complete_type %P.loc16_19.1 [symbolic = %require_complete.loc16_19.2 (constants.%require_complete.657)]
// CHECK:STDOUT:   %tuple.type: type = tuple_type (%T, %T) [symbolic = %tuple.type (constants.%tuple.type.07a)]
// CHECK:STDOUT:   %.loc16_19.10: type = custom_layout_type {size=0, align=0, .Both@0: @P.Both.%tuple.type (%tuple.type.07a)} [symbolic = %.loc16_19.10 (constants.%.d27)]
// CHECK:STDOUT:   %uninit.loc16_19.2: @P.Both.%.loc16_19.10 (%.d27) = uninitialized_value [symbolic = %uninit.loc16_19.2 (constants.%uninit.216)]
// CHECK:STDOUT:   %P.val: @P.Both.%P.loc16_19.1 (%P.f86) = struct_value (constants.%int_0.1a7, %uninit.loc16_19.2) [symbolic = %P.val (constants.%P.val.5d5)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%_.param.loc16_19.1: @P.Both.%T (%T.67d), %_.param.loc16_19.2: @P.Both.%T (%T.67d)) -> out %return.param: @P.Both.%P.loc16_19.1 (%P.f86) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %.loc16_19.1: ref %u1 = class_element_access %return.param, element0
// CHECK:STDOUT:     %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:     %impl.elem0: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:     %bound_method.loc16_19.1: <bound method> = bound_method %int_0, %impl.elem0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:     %specific_fn: <specific function> = specific_function %impl.elem0, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:     %bound_method.loc16_19.2: <bound method> = bound_method %int_0, %specific_fn [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %u1 = call %bound_method.loc16_19.2(%int_0) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:     %.loc16_19.2: init %u1 = converted %int_0, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:     %.loc16_19.3: init %u1 to %.loc16_19.1 = in_place_init %.loc16_19.2 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:     %.loc16_19.4: ref @P.Both.%.loc16_19.10 (%.d27) = class_element_access %return.param, element1
// CHECK:STDOUT:     %.loc16_19.5: ref @P.Both.%tuple.type (%tuple.type.07a) = class_element_access %.loc16_19.4, element0
// CHECK:STDOUT:     %.loc17_19.1: init @P.Both.%tuple.type (%tuple.type.07a) to %.loc16_19.5 = tuple_init (%_.param.loc16_19.1, %_.param.loc16_19.2)
// CHECK:STDOUT:     %uninit.loc16_19.1: @P.Both.%.loc16_19.10 (%.d27) = uninitialized_value [symbolic = %uninit.loc16_19.2 (constants.%uninit.216)]
// CHECK:STDOUT:     %.loc16_19.6: init @P.Both.%.loc16_19.10 (%.d27) to %.loc16_19.4 = in_place_init %uninit.loc16_19.1 [symbolic = %uninit.loc16_19.2 (constants.%uninit.216)]
// CHECK:STDOUT:     %.loc16_19.7: init @P.Both.%P.loc16_19.1 (%P.f86) to %return.param = class_init (%.loc16_19.3, %.loc16_19.6) [symbolic = %P.val (constants.%P.val.5d5)]
// CHECK:STDOUT:     %.loc16_19.8: init @P.Both.%P.loc16_19.1 (%P.f86) = update_init %.loc16_19.7, %.loc17_19.1
// CHECK:STDOUT:     %tuple.elem0: ref @P.Both.%T (%T.67d) = tuple_access %.loc16_19.5, element0
// CHECK:STDOUT:     %.loc17_19.2: init @P.Both.%T (%T.67d) to %tuple.elem0 = in_place_init %_.param.loc16_19.1
// CHECK:STDOUT:     %tuple.elem1: ref @P.Both.%T (%T.67d) = tuple_access %.loc16_19.5, element1
// CHECK:STDOUT:     %.loc17_19.3: init @P.Both.%T (%T.67d) to %tuple.elem1 = in_place_init %_.param.loc16_19.2
// CHECK:STDOUT:     return %.loc16_19.8 to %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @Discard(%U.loc21_13.2: type) {
// CHECK:STDOUT:   %U.patt.loc21_13.2: %pattern_type.98f = symbolic_binding_pattern U, 0 [symbolic = %U.patt.loc21_13.2 (constants.%U.patt.d47)]
// CHECK:STDOUT:   %U.loc21_13.1: type = symbolic_binding U, 0 [symbolic = %U.loc21_13.1 (constants.%U.67d)]
// CHECK:STDOUT:   %pattern_type: type = pattern_type %U.loc21_13.1 [symbolic = %pattern_type (constants.%pattern_type.51d1c4.4)]
// CHECK:STDOUT:   %_.param_patt.loc21_22.2: @Discard.%pattern_type (%pattern_type.51d1c4.4) = value_param_pattern [symbolic = %_.param_patt.loc21_22.2 (constants.%_.param_patt.339927.2)]
// CHECK:STDOUT:   %_.patt.loc21_22.2: @Discard.%pattern_type (%pattern_type.51d1c4.4) = at_binding_pattern _, %_.param_patt.loc21_22.2 [symbolic = %_.patt.loc21_22.2 (constants.%_.patt.fd3aed.2)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete: <witness> = require_complete_type %U.loc21_13.1 [symbolic = %require_complete (constants.%require_complete.9443dd.2)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%_.param.loc21_22: @Discard.%U.loc21_13.1 (%U.67d), %_.param.loc21_28: @Discard.%U.loc21_13.1 (%U.67d)) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     return
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @Classify(%T.loc23_14.2: type) {
// CHECK:STDOUT:   %T.patt.loc23_14.2: %pattern_type.98f = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc23_14.2 (constants.%T.patt.d47)]
// CHECK:STDOUT:   %T.loc23_14.1: type = symbolic_binding T, 0 [symbolic = %T.loc23_14.1 (constants.%T.67d)]
// CHECK:STDOUT:   %P.loc23_28.1: type = class_type @P, @P(%T.loc23_14.1) [symbolic = %P.loc23_28.1 (constants.%P.f86)]
// CHECK:STDOUT:   %pattern_type.loc23: type = pattern_type %P.loc23_28.1 [symbolic = %pattern_type.loc23 (constants.%pattern_type.6d3)]
// CHECK:STDOUT:   %p.param_patt.loc23_23.2: @Classify.%pattern_type.loc23 (%pattern_type.6d3) = value_param_pattern [symbolic = %p.param_patt.loc23_23.2 (constants.%p.param_patt.631)]
// CHECK:STDOUT:   %p.patt.loc23_23.2: @Classify.%pattern_type.loc23 (%pattern_type.6d3) = at_binding_pattern p, %p.param_patt.loc23_23.2 [symbolic = %p.patt.loc23_23.2 (constants.%p.patt.4ce)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc23: <witness> = require_complete_type %P.loc23_28.1 [symbolic = %require_complete.loc23 (constants.%require_complete.657)]
// CHECK:STDOUT:   %require_complete.loc25: <witness> = require_complete_type %T.loc23_14.1 [symbolic = %require_complete.loc25 (constants.%require_complete.9443dd.1)]
// CHECK:STDOUT:   %pattern_type.loc25_17: type = pattern_type %T.loc23_14.1 [symbolic = %pattern_type.loc25_17 (constants.%pattern_type.51d1c4.1)]
// CHECK:STDOUT:   %a.patt.loc25_17.2: @Classify.%pattern_type.loc25_17 (%pattern_type.51d1c4.1) = value_binding_pattern a [symbolic = %a.patt.loc25_17.2 (constants.%a.patt.54f)]
// CHECK:STDOUT:   %b.patt.loc25_23.2: @Classify.%pattern_type.loc25_17 (%pattern_type.51d1c4.1) = value_binding_pattern b [symbolic = %b.patt.loc25_23.2 (constants.%b.patt.b98)]
// CHECK:STDOUT:   %tuple.type: type = tuple_type (%T.loc23_14.1, %T.loc23_14.1) [symbolic = %tuple.type (constants.%tuple.type.07a)]
// CHECK:STDOUT:   %pattern_type.loc25_26: type = pattern_type %tuple.type [symbolic = %pattern_type.loc25_26 (constants.%pattern_type.c3f)]
// CHECK:STDOUT:   %.loc25_26.2: @Classify.%pattern_type.loc25_26 (%pattern_type.c3f) = tuple_pattern (%a.patt.loc25_17.2, %b.patt.loc25_23.2) [symbolic = %.loc25_26.2 (constants.%.dcb)]
// CHECK:STDOUT:   %.loc25_28.11: type = custom_layout_type {size=0, align=0, .Both@0: @Classify.%tuple.type (%tuple.type.07a)} [symbolic = %.loc25_28.11 (constants.%.d27)]
// CHECK:STDOUT:   %Discard.specific_fn.loc26_7.2: <specific function> = specific_function constants.%Discard, @Discard(%T.loc23_14.1) [symbolic = %Discard.specific_fn.loc26_7.2 (constants.%Discard.specific_fn.628)]
// CHECK:STDOUT:   %uninit: @Classify.%.loc25_28.11 (%.d27) = uninitialized_value [symbolic = %uninit (constants.%uninit.216)]
// CHECK:STDOUT:   %P.val: @Classify.%P.loc23_28.1 (%P.f86) = struct_value (constants.%int_1.233, %uninit) [symbolic = %P.val (constants.%P.val.a40)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%p.param: @Classify.%P.loc23_28.1 (%P.f86)) -> out %return.param: %i32 {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %p.ref: @Classify.%P.loc23_28.1 (%P.f86) = name_ref p, %p
// CHECK:STDOUT:     name_binding_decl {
// CHECK:STDOUT:       %a.patt.loc25_17.1: @Classify.%pattern_type.loc25_17 (%pattern_type.51d1c4.1) = value_binding_pattern a [symbolic = %a.patt.loc25_17.2 (constants.%a.patt.54f)]
// CHECK:STDOUT:       %b.patt.loc25_23.1: @Classify.%pattern_type.loc25_17 (%pattern_type.51d1c4.1) = value_binding_pattern b [symbolic = %b.patt.loc25_23.2 (constants.%b.patt.b98)]
// CHECK:STDOUT:       %.loc25_26.1: @Classify.%pattern_type.loc25_26 (%pattern_type.c3f) = tuple_pattern (%a.patt.loc25_17.1, %b.patt.loc25_23.1) [symbolic = %.loc25_26.2 (constants.%.dcb)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %int_0.loc25: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:     %impl.elem0.loc25_28.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:     %bound_method.loc25_28.1: <bound method> = bound_method %int_0.loc25, %impl.elem0.loc25_28.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:     %specific_fn.loc25_28.1: <specific function> = specific_function %impl.elem0.loc25_28.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:     %bound_method.loc25_28.2: <bound method> = bound_method %int_0.loc25, %specific_fn.loc25_28.1 [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc25: init %u1 = call %bound_method.loc25_28.2(%int_0.loc25) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:     %.loc25_28.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc25 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:     %.loc25_28.2: %u1 = converted %int_0.loc25, %.loc25_28.1 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:     %.loc25_28.3: ref %u1 = class_element_access %p.ref, element0
// CHECK:STDOUT:     %impl.elem0.loc25_28.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:     %bound_method.loc25_28.3: <bound method> = bound_method %.loc25_28.2, %impl.elem0.loc25_28.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.f34]
// CHECK:STDOUT:     %specific_fn.loc25_28.2: <specific function> = specific_function %impl.elem0.loc25_28.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:     %bound_method.loc25_28.4: <bound method> = bound_method %.loc25_28.2, %specific_fn.loc25_28.2 [concrete = constants.%bound_method.53a]
// CHECK:STDOUT:     %.loc25_28.4: %u1 = acquire_value %.loc25_28.3
// CHECK:STDOUT:     %UInt.as.EqWith.impl.Equal.call.loc25: init bool = call %bound_method.loc25_28.4(%.loc25_28.2, %.loc25_28.4)
// CHECK:STDOUT:     %.loc25_28.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc25
// CHECK:STDOUT:     %.loc25_28.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc25, %.loc25_28.5
// CHECK:STDOUT:     if %.loc25_28.6 br !match.case.then.loc25 else br !match.case.else.loc25
// CHECK:STDOUT:
// CHECK:STDOUT:   !match.case.then.loc25:
// CHECK:STDOUT:     %.loc25_28.7: ref @Classify.%.loc25_28.11 (%.d27) = class_element_access %p.ref, element1
// CHECK:STDOUT:     %.loc25_28.8: ref @Classify.%tuple.type (%tuple.type.07a) = class_element_access %.loc25_28.7, element0
// CHECK:STDOUT:     %tuple.elem0: ref @Classify.%T.loc23_14.1 (%T.67d) = tuple_access %.loc25_28.8, element0
// CHECK:STDOUT:     %tuple.elem1: ref @Classify.%T.loc23_14.1 (%T.67d) = tuple_access %.loc25_28.8, element1
// CHECK:STDOUT:     %.loc25_28.9: @Classify.%T.loc23_14.1 (%T.67d) = acquire_value %tuple.elem0
// CHECK:STDOUT:     %T.ref.loc25_19: type = name_ref T, %T.loc23_14.2 [symbolic = %T.loc23_14.1 (constants.%T.67d)]
// CHECK:STDOUT:     %a: @Classify.%T.loc23_14.1 (%T.67d) = wrapper_binding a, %.loc25_28.9
// CHECK:STDOUT:     %.loc25_28.10: @Classify.%T.loc23_14.1 (%T.67d) = acquire_value %tuple.elem1
// CHECK:STDOUT:     %T.ref.loc25_25: type = name_ref T, %T.loc23_14.2 [symbolic = %T.loc23_14.1 (constants.%T.67d)]
// CHECK:STDOUT:     %b: @Classify.%T.loc23_14.1 (%T.67d) = wrapper_binding b, %.loc25_28.10
// CHECK:STDOUT:     %Discard.ref: %Discard.type = name_ref Discard, file.%Discard.decl [concrete = constants.%Discard]
// CHECK:STDOUT:     %a.ref: @Classify.%T.loc23_14.1 (%T.67d) = name_ref a, %a
// CHECK:STDOUT:     %b.ref: @Classify.%T.loc23_14.1 (%T.67d) = name_ref b, %b
// CHECK:STDOUT:     %Discard.specific_fn.loc26_7.1: <specific function> = specific_function %Discard.ref, @Discard(constants.%T.67d) [symbolic = %Discard.specific_fn.loc26_7.2 (constants.%Discard.specific_fn.628)]
// CHECK:STDOUT:     %Discard.call: init %empty_tuple.type = call %Discard.specific_fn.loc26_7.1(%a.ref, %b.ref)
// CHECK:STDOUT:     %int_1.loc27: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:     %impl.elem0.loc27: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:     %bound_method.loc27_15.1: <bound method> = bound_method %int_1.loc27, %impl.elem0.loc27 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:     %specific_fn.loc27: <specific function> = specific_function %impl.elem0.loc27, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:     %bound_method.loc27_15.2: <bound method> = bound_method %int_1.loc27, %specific_fn.loc27 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc27: init %i32 = call %bound_method.loc27_15.2(%int_1.loc27) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:     %.loc27: init %i32 = converted %int_1.loc27, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc27 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:     return %.loc27
// CHECK:STDOUT:
// CHECK:STDOUT:   !match.case.else.loc25:
// CHECK:STDOUT:     name_binding_decl {
// CHECK:STDOUT:       %expr_patt: @Classify.%pattern_type.loc23 (%pattern_type.6d3) = expr_pattern %Neither.ref in [concrete] {
// CHECK:STDOUT:         %.loc29_10.2: @Classify.%P.loc23_28.1 (%P.f86) = specific_constant @P.%.loc19_1.13, @P(constants.%T.67d) [symbolic = %P.val (constants.%P.val.a40)]
// CHECK:STDOUT:         %Neither.ref: @Classify.%P.loc23_28.1 (%P.f86) = name_ref Neither, %.loc29_10.2 [symbolic = %P.val (constants.%P.val.a40)]
// CHECK:STDOUT:       }
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %.loc29_10.1: @Classify.%P.loc23_28.1 (%P.f86) = splice_block %Neither.ref [symbolic = %P.val (constants.%P.val.a40)] {
// CHECK:STDOUT:       %.loc29_10.2: @Classify.%P.loc23_28.1 (%P.f86) = specific_constant @P.%.loc19_1.13, @P(constants.%T.67d) [symbolic = %P.val (constants.%P.val.a40)]
// CHECK:STDOUT:       %Neither.ref: @Classify.%P.loc23_28.1 (%P.f86) = name_ref Neither, %.loc29_10.2 [symbolic = %P.val (constants.%P.val.a40)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %int_1.loc29: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:     %impl.elem0.loc29_19.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:     %bound_method.loc29_19.1: <bound method> = bound_method %int_1.loc29, %impl.elem0.loc29_19.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:     %specific_fn.loc29_19.1: <specific function> = specific_function %impl.elem0.loc29_19.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:     %bound_method.loc29_19.2: <bound method> = bound_method %int_1.loc29, %specific_fn.loc29_19.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc29_19: init %u1 = call %bound_method.loc29_19.2(%int_1.loc29) [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc29_19.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc29_19 [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc29_19.2: %u1 = converted %int_1.loc29, %.loc29_19.1 [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc29_19.3: ref %u1 = class_element_access %p.ref, element0
// CHECK:STDOUT:     %impl.elem0.loc29_19.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:     %bound_method.loc29_19.3: <bound method> = bound_method %.loc29_19.2, %impl.elem0.loc29_19.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.22c]
// CHECK:STDOUT:     %specific_fn.loc29_19.2: <specific function> = specific_function %impl.elem0.loc29_19.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:     %bound_method.loc29_19.4: <bound method> = bound_method %.loc29_19.2, %specific_fn.loc29_19.2 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:     %.loc29_19.4: %u1 = acquire_value %.loc29_19.3
// CHECK:STDOUT:     %UInt.as.EqWith.impl.Equal.call.loc29: init bool = call %bound_method.loc29_19.4(%.loc29_19.2, %.loc29_19.4)
// CHECK:STDOUT:     %.loc29_19.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc29
// CHECK:STDOUT:     %.loc29_19.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc29, %.loc29_19.5
// CHECK:STDOUT:     if %.loc29_19.6 br !match.case.then.loc29 else br !match.case.else.loc29
// CHECK:STDOUT:
// CHECK:STDOUT:   !match.case.then.loc29:
// CHECK:STDOUT:     %int_0.loc29: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:     %impl.elem0.loc29_32: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:     %bound_method.loc29_32.1: <bound method> = bound_method %int_0.loc29, %impl.elem0.loc29_32 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:     %specific_fn.loc29_32: <specific function> = specific_function %impl.elem0.loc29_32, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:     %bound_method.loc29_32.2: <bound method> = bound_method %int_0.loc29, %specific_fn.loc29_32 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc29_32: init %i32 = call %bound_method.loc29_32.2(%int_0.loc29) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:     %.loc29_32: init %i32 = converted %int_0.loc29, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc29_32 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:     return %.loc29_32
// CHECK:STDOUT:
// CHECK:STDOUT:   !match.case.else.loc29:
// CHECK:STDOUT:     br !match.done
// CHECK:STDOUT:
// CHECK:STDOUT:   !match.done:
// CHECK:STDOUT:     %int_1.loc32: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:     %impl.elem1: %.758 = impl_witness_access constants.%Negate.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:     %bound_method.loc32_10: <bound method> = bound_method %int_1.loc32, %impl.elem1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op.bound]
// CHECK:STDOUT:     %Core.IntLiteral.as.Negate.impl.Op.call: init Core.IntLiteral = call %bound_method.loc32_10(%int_1.loc32) [concrete = constants.%int_-1.638]
// CHECK:STDOUT:     %impl.elem0.loc32: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:     %bound_method.loc32_12.1: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %impl.elem0.loc32 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.65e]
// CHECK:STDOUT:     %specific_fn.loc32: <specific function> = specific_function %impl.elem0.loc32, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:     %bound_method.loc32_12.2: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %specific_fn.loc32 [concrete = constants.%bound_method.a65]
// CHECK:STDOUT:     %.loc32_10.1: Core.IntLiteral = value_of_initializer %Core.IntLiteral.as.Negate.impl.Op.call [concrete = constants.%int_-1.638]
// CHECK:STDOUT:     %.loc32_10.2: Core.IntLiteral = converted %Core.IntLiteral.as.Negate.impl.Op.call, %.loc32_10.1 [concrete = constants.%int_-1.638]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc32: init %i32 = call %bound_method.loc32_12.2(%.loc32_10.2) [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:     %.loc32_12: init %i32 = converted %Core.IntLiteral.as.Negate.impl.Op.call, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc32 [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:     return %.loc32_12
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Call(%p.param: %P.b38) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Classify.ref: %Classify.type = name_ref Classify, file.%Classify.decl [concrete = constants.%Classify]
// CHECK:STDOUT:   %p.ref: %P.b38 = name_ref p, %p
// CHECK:STDOUT:   %Classify.specific_fn: <specific function> = specific_function %Classify.ref, @Classify(constants.%i32) [concrete = constants.%Classify.specific_fn]
// CHECK:STDOUT:   %Classify.call: init %i32 = call %Classify.specific_fn(%p.ref)
// CHECK:STDOUT:   return %Classify.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @P(constants.%T.67d) {
// CHECK:STDOUT:   %T.patt.loc16_11.2 => constants.%T.patt.d47
// CHECK:STDOUT:   %T.loc16_11.1 => constants.%T.67d
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.51d1c4.1
// CHECK:STDOUT:   %x.param_patt => constants.%x.param_patt.91d
// CHECK:STDOUT:   %x.patt => constants.%x.patt.800
// CHECK:STDOUT:   %y.param_patt => constants.%y.param_patt.be3
// CHECK:STDOUT:   %y.patt => constants.%y.patt.b85
// CHECK:STDOUT:   %require_complete.loc17 => constants.%require_complete.9443dd.1
// CHECK:STDOUT:   %tuple.type => constants.%tuple.type.07a
// CHECK:STDOUT:   %.loc19_1.14 => constants.%.d27
// CHECK:STDOUT:   %struct_type.discriminant.payload => constants.%struct_type.discriminant.payload.1ec
// CHECK:STDOUT:   %complete_type.loc19_1.2 => constants.%complete_type.d2c
// CHECK:STDOUT:   %P.Both.type => constants.%P.Both.type.e35
// CHECK:STDOUT:   %P.Both => constants.%P.Both.862
// CHECK:STDOUT:   %P => constants.%P.f86
// CHECK:STDOUT:   %require_complete.loc19 => constants.%require_complete.657
// CHECK:STDOUT:   %uninit.loc19_1.2 => constants.%uninit.216
// CHECK:STDOUT:   %P.val => constants.%P.val.a40
// CHECK:STDOUT:   %.loc19_1.15 => constants.%.a21
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @P.Both(constants.%T.67d) {
// CHECK:STDOUT:   %T => constants.%T.67d
// CHECK:STDOUT:   %pattern_type.loc16_19.1 => constants.%pattern_type.51d1c4.1
// CHECK:STDOUT:   %_.param_patt.loc16_19.3 => constants.%_.param_patt.339927.1
// CHECK:STDOUT:   %_.patt.loc16_19.3 => constants.%_.patt.fd3aed.1
// CHECK:STDOUT:   %P.loc16_19.1 => constants.%P.f86
// CHECK:STDOUT:   %.loc16_19.9 => constants.%.3a8
// CHECK:STDOUT:   %pattern_type.loc16_19.2 => constants.%pattern_type.6d3
// CHECK:STDOUT:   %return.param_patt.loc16_19.2 => constants.%return.param_patt.3b8
// CHECK:STDOUT:   %return.patt.loc16_19.2 => constants.%return.patt.ec6
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Discard(constants.%U.67d) {
// CHECK:STDOUT:   %U.patt.loc21_13.2 => constants.%U.patt.d47
// CHECK:STDOUT:   %U.loc21_13.1 => constants.%U.67d
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.51d1c4.4
// CHECK:STDOUT:   %_.param_patt.loc21_22.2 => constants.%_.param_patt.339927.2
// CHECK:STDOUT:   %_.patt.loc21_22.2 => constants.%_.patt.fd3aed.2
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Classify(constants.%T.67d) {
// CHECK:STDOUT:   %T.patt.loc23_14.2 => constants.%T.patt.d47
// CHECK:STDOUT:   %T.loc23_14.1 => constants.%T.67d
// CHECK:STDOUT:   %P.loc23_28.1 => constants.%P.f86
// CHECK:STDOUT:   %pattern_type.loc23 => constants.%pattern_type.6d3
// CHECK:STDOUT:   %p.param_patt.loc23_23.2 => constants.%p.param_patt.631
// CHECK:STDOUT:   %p.patt.loc23_23.2 => constants.%p.patt.4ce
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Discard(constants.%T.67d) {
// CHECK:STDOUT:   %U.patt.loc21_13.2 => constants.%U.patt.d47
// CHECK:STDOUT:   %U.loc21_13.1 => constants.%T.67d
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.51d1c4.1
// CHECK:STDOUT:   %_.param_patt.loc21_22.2 => constants.%_.param_patt.339927.1
// CHECK:STDOUT:   %_.patt.loc21_22.2 => constants.%_.patt.fd3aed.1
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete => constants.%require_complete.9443dd.1
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @P(constants.%i32) {
// CHECK:STDOUT:   %T.patt.loc16_11.2 => constants.%T.patt.d47
// CHECK:STDOUT:   %T.loc16_11.1 => constants.%i32
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.6b6
// CHECK:STDOUT:   %x.param_patt => constants.%x.param_patt.cee
// CHECK:STDOUT:   %x.patt => constants.%x.patt.fbe
// CHECK:STDOUT:   %y.param_patt => constants.%y.param_patt.673
// CHECK:STDOUT:   %y.patt => constants.%y.patt.b43
// CHECK:STDOUT:   %require_complete.loc17 => constants.%complete_type.f8a
// CHECK:STDOUT:   %tuple.type => constants.%tuple.type.e55
// CHECK:STDOUT:   %.loc19_1.14 => constants.%.20c
// CHECK:STDOUT:   %struct_type.discriminant.payload => constants.%struct_type.discriminant.payload.92c
// CHECK:STDOUT:   %complete_type.loc19_1.2 => constants.%complete_type.ea6
// CHECK:STDOUT:   %P.Both.type => constants.%P.Both.type.571
// CHECK:STDOUT:   %P.Both => constants.%P.Both.ce5
// CHECK:STDOUT:   %P => constants.%P.b38
// CHECK:STDOUT:   %require_complete.loc19 => constants.%complete_type.ea6
// CHECK:STDOUT:   %uninit.loc19_1.2 => constants.%uninit.525
// CHECK:STDOUT:   %P.val => constants.%P.val.3d1
// CHECK:STDOUT:   %.loc19_1.15 => constants.%.b5a
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Classify(constants.%i32) {
// CHECK:STDOUT:   %T.patt.loc23_14.2 => constants.%T.patt.d47
// CHECK:STDOUT:   %T.loc23_14.1 => constants.%i32
// CHECK:STDOUT:   %P.loc23_28.1 => constants.%P.b38
// CHECK:STDOUT:   %pattern_type.loc23 => constants.%pattern_type.e96
// CHECK:STDOUT:   %p.param_patt.loc23_23.2 => constants.%p.param_patt.d8e
// CHECK:STDOUT:   %p.patt.loc23_23.2 => constants.%p.patt.38d
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc23 => constants.%complete_type.ea6
// CHECK:STDOUT:   %require_complete.loc25 => constants.%complete_type.f8a
// CHECK:STDOUT:   %pattern_type.loc25_17 => constants.%pattern_type.6b6
// CHECK:STDOUT:   %a.patt.loc25_17.2 => constants.%a.patt.bb2
// CHECK:STDOUT:   %b.patt.loc25_23.2 => constants.%b.patt.e7d
// CHECK:STDOUT:   %tuple.type => constants.%tuple.type.e55
// CHECK:STDOUT:   %pattern_type.loc25_26 => constants.%pattern_type.394
// CHECK:STDOUT:   %.loc25_26.2 => constants.%.d82
// CHECK:STDOUT:   %.loc25_28.11 => constants.%.20c
// CHECK:STDOUT:   %Discard.specific_fn.loc26_7.2 => constants.%Discard.specific_fn.f3f
// CHECK:STDOUT:   %uninit => constants.%uninit.525
// CHECK:STDOUT:   %P.val => constants.%P.val.3d1
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Discard(constants.%i32) {
// CHECK:STDOUT:   %U.patt.loc21_13.2 => constants.%U.patt.d47
// CHECK:STDOUT:   %U.loc21_13.1 => constants.%i32
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.6b6
// CHECK:STDOUT:   %_.param_patt.loc21_22.2 => constants.%_.param_patt.fb2
// CHECK:STDOUT:   %_.patt.loc21_22.2 => constants.%_.patt.b75
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete => constants.%complete_type.f8a
// CHECK:STDOUT: }
// CHECK:STDOUT:
