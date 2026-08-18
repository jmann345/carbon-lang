// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/choice_generic_scrutinee.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/choice_generic_scrutinee.carbon

// Specifics of a generic choice as `match` scrutinees (W5-S3a,
// fork/w5-s3/plan.md §3): the scrutinee gate forces the specific's
// definition resolution (`RequireCompleteType` at `MatchCondition`), and
// `GetChoiceDiscriminantType` reads the object representation through the
// specific, so payload-free generic choices dispatch and are covered by the
// SF-7 exhaustiveness analysis exactly like concrete choices. Payload
// synthesis in generic choices lands at W5-S3b (choice/generic_payload.carbon
// and match/choice_generic_payload_scrutinee.carbon).

// --- basic.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
choice P(T: type) {
  A,
  B
}

// A specific of a payload-free generic choice is an admitted scrutinee:
// both alternatives are covered by unguarded arms, so no `default` arm is
// required (SF-7 through the shared alternative table).
fn Classify(p: P(i32)) -> i32 {
  match (p) {
    case .A => { return 0; }
    case .B => { return 1; }
  }
  return -1;
}

// The alternative constant resolves through the specific's scope; a `let`
// binds the value directly — returning or `var`-initializing from the
// constant would require a `Copy` impl, which choices do not have (see
// fork/conformance/programs/types/choice_payload_construct.carbon).
fn Construct() -> i32 {
  let b: P(i32) = P(i32).B;
  return Classify(b);
}
//@dump-sem-ir-end

// --- two_specifics.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
choice P(T: type) {
  A,
  B
}

// Two specifics of one generic choice matched in one function: each match
// dispatches on its own specific's discriminant, and each is exhaustive on
// its own — the alternative table is shared through the `class_id`, the
// coverage is per statement.
fn G(a: P(i32), b: P(bool)) -> i32 {
  match (a) {
    case .A => { return 0; }
    case .B => { return 1; }
  }
  match (b) {
    case .A => { return 2; }
    case .B => { return 3; }
  }
  return -1;
}
//@dump-sem-ir-end

// --- symbolic_specific.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
choice P(T: type) {
  A,
  B
}

// A SYMBOLIC specific as scrutinee (risk R-8's scope-in): matching
// `x: P(T)` inside a generic body is admitted by the same gate lift — the
// payload-free choice's representation witness is concrete, and the forced
// completion defers the specific's requirement to monomorphization
// (`require_complete_type`).
fn F[T: type](x: P(T)) -> i32 {
  match (x) {
    case .A => { return 0; }
    case .B => { return 1; }
  }
  return -1;
}

fn Call(p: P(i32)) -> i32 {
  return F(p);
}
//@dump-sem-ir-end

// --- plib.carbon
library "plib";

choice P(T: type) {
  A,
  B
}

// --- use_imported.carbon
library "[[@TEST_NAME]]";

import library "plib";

//@dump-sem-ir-begin
// Matching a specific of a generic choice declared in another library: the
// `is_choice` entity flag, the alternative table, and the generic's
// definition must arrive through import for the scrutinee gate's forced
// specific resolution and the designator resolution to work.
fn Classify(p: P(i32)) -> i32 {
  match (p) {
    case .A => { return 0; }
    case .B => { return 1; }
  }
  return -1;
}

fn Construct() -> i32 {
  let a: P(i32) = P(i32).A;
  return Classify(a);
}
//@dump-sem-ir-end

// --- fail_nonexhaustive.carbon
library "[[@TEST_NAME]]";

choice P(T: type) {
  A,
  B
}

// A non-exhaustive match on a specific names the missing alternative, with
// the scrutinee's specific type in the message.
fn F(p: P(i32)) -> i32 {
  // CHECK:STDERR: fail_nonexhaustive.carbon:[[@LINE+4]]:3: error: `match` on choice `P(i32)` has no `default` arm and does not cover alternative `.B` [MatchNonexhaustive]
  // CHECK:STDERR:   match (p) {
  // CHECK:STDERR:   ^~~~~~~~~~~
  // CHECK:STDERR:
  match (p) {
    case .A => { return 0; }
  }
  return -1;
}

// --- fail_two_specifics_one_nonexhaustive.carbon
library "[[@TEST_NAME]]";

choice P(T: type) {
  A,
  B
}

// The R-5 pin: coverage identity is shared across specifics through the
// `class_id`, but coverage itself is per match statement — the exhaustive
// `P(i32)` match compiles in silence while the `P(bool)` match right after
// it is diagnosed, naming its own missing alternative. Coverage bleeding
// between the statements (or between the specifics) would falsify this.
fn F(a: P(i32), b: P(bool)) -> i32 {
  match (a) {
    case .A => { return 0; }
    case .B => { return 1; }
  }
  // CHECK:STDERR: fail_two_specifics_one_nonexhaustive.carbon:[[@LINE+4]]:3: error: `match` on choice `P(bool)` has no `default` arm and does not cover alternative `.B` [MatchNonexhaustive]
  // CHECK:STDERR:   match (b) {
  // CHECK:STDERR:   ^~~~~~~~~~~
  // CHECK:STDERR:
  match (b) {
    case .A => { return 2; }
  }
  return -1;
}

// --- single_alternative_specific.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
choice Always(T: type) {
  Sunny
}

// W-068 composition: a single-alternative specific's discriminant is the
// empty tuple, so the lifted fewer-than-two gate admits it through the same
// repr read as a concrete choice — the one arm is always taken with no
// discriminant test, and covering the only alternative discharges the
// `default` requirement.
fn F(a: Always(i32)) {
  match (a) {
    case .Sunny => { return; }
  }
}
//@dump-sem-ir-end

// --- empty_choice_specific.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
choice Never(T: type) {}

// The zero-alternative composition (W-068): an empty generic choice's
// specific is admitted too; the `default` arm is dynamically dead —
// `Never(i32)` has no constructors — and the match is vacuously exhaustive.
fn F(n: Never(i32)) {
  match (n) {
    default => { return; }
  }
}
//@dump-sem-ir-end

// --- fail_mixed_table_closed.carbon
library "[[@TEST_NAME]]";

// The S3a partial-table window is CLOSED (plan §2.5 i): the parameterized
// alternative of a MIXED generic choice now synthesizes and gets its
// alternative-table row, so the match below — which covers only the constant
// alternatives and passed exhaustiveness IN SILENCE at S3a — is diagnosed,
// naming `.Tag`.
choice P(T: type) {
  Tag(n: i32),
  A,
  B
}

fn F(p: P(i32)) -> i32 {
  // CHECK:STDERR: fail_mixed_table_closed.carbon:[[@LINE+4]]:3: error: `match` on choice `P(i32)` has no `default` arm and does not cover alternative `.Tag` [MatchNonexhaustive]
  // CHECK:STDERR:   match (p) {
  // CHECK:STDERR:   ^~~~~~~~~~~
  // CHECK:STDERR:
  match (p) {
    case .A => { return 0; }
    case .B => { return 1; }
  }
  return -1;
}

// CHECK:STDOUT: --- basic.carbon
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
// CHECK:STDOUT:   %require_complete.657: <witness> = require_complete_type %P.f86 [symbolic]
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
// CHECK:STDOUT:   %P.val.7d0: %P.f86 = struct_value (%int_0.1a7) [symbolic]
// CHECK:STDOUT:   %.72a: ref %P.f86 = temporary invalid, %P.val.7d0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %bound_method.d7a: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
// CHECK:STDOUT:   %int_1.233: %u1 = int_value 1 [concrete]
// CHECK:STDOUT:   %struct.a79: %struct_type.discriminant = struct_value (%int_1.233) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.bound.332: <bound method> = bound_method %int_1.233, %UInt.as.Copy.impl.Op.d9c [concrete]
// CHECK:STDOUT:   %bound_method.edd: <bound method> = bound_method %int_1.233, %UInt.as.Copy.impl.Op.specific_fn [concrete]
// CHECK:STDOUT:   %P.val.e49: %P.f86 = struct_value (%int_1.233) [symbolic]
// CHECK:STDOUT:   %.3aa: ref %P.f86 = temporary invalid, %P.val.e49 [symbolic]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %P.b38: type = class_type @P, @P(%i32) [concrete]
// CHECK:STDOUT:   %pattern_type.e96: type = pattern_type %P.b38 [concrete]
// CHECK:STDOUT:   %p.param_patt: %pattern_type.e96 = value_param_pattern [concrete]
// CHECK:STDOUT:   %p.patt: %pattern_type.e96 = at_binding_pattern p, %p.param_patt [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %Classify.type: type = fn_type @Classify [concrete]
// CHECK:STDOUT:   %Classify: %Classify.type = struct_value () [concrete]
// CHECK:STDOUT:   %P.val.0e9: %P.b38 = struct_value (%int_0.1a7) [concrete]
// CHECK:STDOUT:   %.043: ref %P.b38 = temporary invalid, %P.val.0e9 [concrete]
// CHECK:STDOUT:   %P.val.61e: %P.b38 = struct_value (%int_1.233) [concrete]
// CHECK:STDOUT:   %.91e: ref %P.b38 = temporary invalid, %P.val.61e [concrete]
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
// CHECK:STDOUT:   %Classify.decl: %Classify.type = fn_decl @Classify [concrete = constants.%Classify] {
// CHECK:STDOUT:     %p.param_patt: %pattern_type.e96 = value_param_pattern [concrete = constants.%p.param_patt]
// CHECK:STDOUT:     %p.patt: %pattern_type.e96 = at_binding_pattern p, %p.param_patt [concrete = constants.%p.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc12_27 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc12_27: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc12_27: Core.Form = init_form %i32.loc12_27 [concrete = constants.%.795f]
// CHECK:STDOUT:     %p.param: %P.b38 = value_param call_param0
// CHECK:STDOUT:     %.loc12_21: type = splice_block %P [concrete = constants.%P.b38] {
// CHECK:STDOUT:       %P.ref: %P.type = name_ref P, file.%P.decl [concrete = constants.%P.generic]
// CHECK:STDOUT:       %i32.loc12_18: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %P: type = class_type @P, @P(constants.%i32) [concrete = constants.%P.b38]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %p: %P.b38 = wrapper_binding p, %p.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Construct.decl: %Construct.type = fn_decl @Construct [concrete = constants.%Construct] {
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
// CHECK:STDOUT: generic class @P(%T.loc4_11.2: type) {
// CHECK:STDOUT:   %T.patt.loc4_11.2: %pattern_type.98f = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc4_11.2 (constants.%T.patt.d47)]
// CHECK:STDOUT:   %T.loc4_11.1: type = symbolic_binding T, 0 [symbolic = %T.loc4_11.1 (constants.%T.67d)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %P: type = class_type @P, @P(%T.loc4_11.1) [symbolic = %P (constants.%P.f86)]
// CHECK:STDOUT:   %require_complete: <witness> = require_complete_type %P [symbolic = %require_complete (constants.%require_complete.657)]
// CHECK:STDOUT:   %P.val.loc5: @P.%P (%P.f86) = struct_value (constants.%int_0.1a7) [symbolic = %P.val.loc5 (constants.%P.val.7d0)]
// CHECK:STDOUT:   %.loc5_4.11: ref @P.%P (%P.f86) = temporary invalid, %P.val.loc5 [symbolic = %.loc5_4.11 (constants.%.72a)]
// CHECK:STDOUT:   %P.val.loc7: @P.%P (%P.f86) = struct_value (constants.%int_1.233) [symbolic = %P.val.loc7 (constants.%P.val.e49)]
// CHECK:STDOUT:   %.loc7_1.11: ref @P.%P (%P.f86) = temporary invalid, %P.val.loc7 [symbolic = %.loc7_1.11 (constants.%.3aa)]
// CHECK:STDOUT:
// CHECK:STDOUT:   class {
// CHECK:STDOUT:     %complete_type: <witness> = complete_type_witness constants.%struct_type.discriminant [concrete = constants.%complete_type.3a6]
// CHECK:STDOUT:     %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:     %impl.elem0.loc5_4.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:     %bound_method.loc5_4.1: <bound method> = bound_method %int_0, %impl.elem0.loc5_4.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:     %specific_fn.loc5_4.1: <specific function> = specific_function %impl.elem0.loc5_4.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:     %bound_method.loc5_4.2: <bound method> = bound_method %int_0, %specific_fn.loc5_4.1 [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc5: init %u1 = call %bound_method.loc5_4.2(%int_0) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:     %.loc5_4.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc5 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:     %.loc5_4.2: %u1 = converted %int_0, %.loc5_4.1 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:     %.loc5_4.3: %struct_type.discriminant = struct_literal (%.loc5_4.2) [concrete = constants.%struct.249]
// CHECK:STDOUT:     %impl.elem0.loc5_4.2: %.952 = impl_witness_access constants.%Copy.impl_witness.334, element0 [concrete = constants.%UInt.as.Copy.impl.Op.d9c]
// CHECK:STDOUT:     %bound_method.loc5_4.3: <bound method> = bound_method %.loc5_4.2, %impl.elem0.loc5_4.2 [concrete = constants.%UInt.as.Copy.impl.Op.bound.bd0]
// CHECK:STDOUT:     %specific_fn.loc5_4.2: <specific function> = specific_function %impl.elem0.loc5_4.2, @UInt.as.Copy.impl.Op(constants.%int_1.5b8) [concrete = constants.%UInt.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:     %bound_method.loc5_4.4: <bound method> = bound_method %.loc5_4.2, %specific_fn.loc5_4.2 [concrete = constants.%bound_method.61c]
// CHECK:STDOUT:     %UInt.as.Copy.impl.Op.call.loc5: init %u1 = call %bound_method.loc5_4.4(%.loc5_4.2) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:     %.loc5_4.4: ref @P.%P (%P.f86) = temporary_storage
// CHECK:STDOUT:     %.loc5_4.5: ref %u1 = class_element_access %.loc5_4.4, element0
// CHECK:STDOUT:     %.loc5_4.6: init %u1 to %.loc5_4.5 = in_place_init %UInt.as.Copy.impl.Op.call.loc5 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:     %.loc5_4.7: init @P.%P (%P.f86) to %.loc5_4.4 = class_init (%.loc5_4.6) [symbolic = %P.val.loc5 (constants.%P.val.7d0)]
// CHECK:STDOUT:     %.loc5_4.8: init @P.%P (%P.f86) = converted %.loc5_4.3, %.loc5_4.7 [symbolic = %P.val.loc5 (constants.%P.val.7d0)]
// CHECK:STDOUT:     %.loc5_4.9: ref @P.%P (%P.f86) = temporary %.loc5_4.4, %.loc5_4.8 [symbolic = %.loc5_4.11 (constants.%.72a)]
// CHECK:STDOUT:     %.loc5_4.10: @P.%P (%P.f86) = acquire_value %.loc5_4.9 [symbolic = %P.val.loc5 (constants.%P.val.7d0)]
// CHECK:STDOUT:     %A: @P.%P (%P.f86) = wrapper_binding A, %.loc5_4.10
// CHECK:STDOUT:     %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:     %impl.elem0.loc7_1.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:     %bound_method.loc7_1.1: <bound method> = bound_method %int_1, %impl.elem0.loc7_1.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:     %specific_fn.loc7_1.1: <specific function> = specific_function %impl.elem0.loc7_1.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:     %bound_method.loc7_1.2: <bound method> = bound_method %int_1, %specific_fn.loc7_1.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc7: init %u1 = call %bound_method.loc7_1.2(%int_1) [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc7_1.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc7 [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc7_1.2: %u1 = converted %int_1, %.loc7_1.1 [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc7_1.3: %struct_type.discriminant = struct_literal (%.loc7_1.2) [concrete = constants.%struct.a79]
// CHECK:STDOUT:     %impl.elem0.loc7_1.2: %.952 = impl_witness_access constants.%Copy.impl_witness.334, element0 [concrete = constants.%UInt.as.Copy.impl.Op.d9c]
// CHECK:STDOUT:     %bound_method.loc7_1.3: <bound method> = bound_method %.loc7_1.2, %impl.elem0.loc7_1.2 [concrete = constants.%UInt.as.Copy.impl.Op.bound.332]
// CHECK:STDOUT:     %specific_fn.loc7_1.2: <specific function> = specific_function %impl.elem0.loc7_1.2, @UInt.as.Copy.impl.Op(constants.%int_1.5b8) [concrete = constants.%UInt.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:     %bound_method.loc7_1.4: <bound method> = bound_method %.loc7_1.2, %specific_fn.loc7_1.2 [concrete = constants.%bound_method.edd]
// CHECK:STDOUT:     %UInt.as.Copy.impl.Op.call.loc7: init %u1 = call %bound_method.loc7_1.4(%.loc7_1.2) [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc7_1.4: ref @P.%P (%P.f86) = temporary_storage
// CHECK:STDOUT:     %.loc7_1.5: ref %u1 = class_element_access %.loc7_1.4, element0
// CHECK:STDOUT:     %.loc7_1.6: init %u1 to %.loc7_1.5 = in_place_init %UInt.as.Copy.impl.Op.call.loc7 [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc7_1.7: init @P.%P (%P.f86) to %.loc7_1.4 = class_init (%.loc7_1.6) [symbolic = %P.val.loc7 (constants.%P.val.e49)]
// CHECK:STDOUT:     %.loc7_1.8: init @P.%P (%P.f86) = converted %.loc7_1.3, %.loc7_1.7 [symbolic = %P.val.loc7 (constants.%P.val.e49)]
// CHECK:STDOUT:     %.loc7_1.9: ref @P.%P (%P.f86) = temporary %.loc7_1.4, %.loc7_1.8 [symbolic = %.loc7_1.11 (constants.%.3aa)]
// CHECK:STDOUT:     %.loc7_1.10: @P.%P (%P.f86) = acquire_value %.loc7_1.9 [symbolic = %P.val.loc7 (constants.%P.val.e49)]
// CHECK:STDOUT:     %B: @P.%P (%P.f86) = wrapper_binding B, %.loc7_1.10
// CHECK:STDOUT:     complete_type_witness = %complete_type
// CHECK:STDOUT:
// CHECK:STDOUT:   !members:
// CHECK:STDOUT:     .Self = constants.%P.f86
// CHECK:STDOUT:     .A = %A
// CHECK:STDOUT:     .B = %B
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Classify(%p.param: %P.b38) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %p.ref: %P.b38 = name_ref p, %p
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt.loc14: %pattern_type.e96 = expr_pattern %A.ref in [concrete] {
// CHECK:STDOUT:       %.loc14_10.2: %P.b38 = specific_constant @P.%.loc5_4.10, @P(constants.%i32) [concrete = constants.%P.val.0e9]
// CHECK:STDOUT:       %A.ref: %P.b38 = name_ref A, %.loc14_10.2 [concrete = constants.%P.val.0e9]
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %.loc14_10.1: %P.b38 = splice_block %A.ref [concrete = constants.%P.val.0e9] {
// CHECK:STDOUT:     %.loc14_10.2: %P.b38 = specific_constant @P.%.loc5_4.10, @P(constants.%i32) [concrete = constants.%P.val.0e9]
// CHECK:STDOUT:     %A.ref: %P.b38 = name_ref A, %.loc14_10.2 [concrete = constants.%P.val.0e9]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_0.loc14_13: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc14_13.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc14_13.1: <bound method> = bound_method %int_0.loc14_13, %impl.elem0.loc14_13.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:   %specific_fn.loc14_13.1: <specific function> = specific_function %impl.elem0.loc14_13.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc14_13.2: <bound method> = bound_method %int_0.loc14_13, %specific_fn.loc14_13.1 [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14_13: init %u1 = call %bound_method.loc14_13.2(%int_0.loc14_13) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc14_13.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14_13 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc14_13.2: %u1 = converted %int_0.loc14_13, %.loc14_13.1 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc14_13.3: ref %u1 = class_element_access %p.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc14_13.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc14_13.3: <bound method> = bound_method %.loc14_13.2, %impl.elem0.loc14_13.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.f34]
// CHECK:STDOUT:   %specific_fn.loc14_13.2: <specific function> = specific_function %impl.elem0.loc14_13.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc14_13.4: <bound method> = bound_method %.loc14_13.2, %specific_fn.loc14_13.2 [concrete = constants.%bound_method.53a]
// CHECK:STDOUT:   %.loc14_13.4: %u1 = acquire_value %.loc14_13.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc14: init bool = call %bound_method.loc14_13.4(%.loc14_13.2, %.loc14_13.4)
// CHECK:STDOUT:   %.loc14_13.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc14
// CHECK:STDOUT:   %.loc14_13.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc14, %.loc14_13.5
// CHECK:STDOUT:   if %.loc14_13.6 br !match.case.then.loc14 else br !match.case.else.loc14
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc14:
// CHECK:STDOUT:   %int_0.loc14_25: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc14_26: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc14_26.1: <bound method> = bound_method %int_0.loc14_25, %impl.elem0.loc14_26 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc14_26: <specific function> = specific_function %impl.elem0.loc14_26, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc14_26.2: <bound method> = bound_method %int_0.loc14_25, %specific_fn.loc14_26 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14_26: init %i32 = call %bound_method.loc14_26.2(%int_0.loc14_25) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc14_26: init %i32 = converted %int_0.loc14_25, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14_26 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   return %.loc14_26
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc14:
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt.loc15: %pattern_type.e96 = expr_pattern %B.ref in [concrete] {
// CHECK:STDOUT:       %.loc15_10.2: %P.b38 = specific_constant @P.%.loc7_1.10, @P(constants.%i32) [concrete = constants.%P.val.61e]
// CHECK:STDOUT:       %B.ref: %P.b38 = name_ref B, %.loc15_10.2 [concrete = constants.%P.val.61e]
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %.loc15_10.1: %P.b38 = splice_block %B.ref [concrete = constants.%P.val.61e] {
// CHECK:STDOUT:     %.loc15_10.2: %P.b38 = specific_constant @P.%.loc7_1.10, @P(constants.%i32) [concrete = constants.%P.val.61e]
// CHECK:STDOUT:     %B.ref: %P.b38 = name_ref B, %.loc15_10.2 [concrete = constants.%P.val.61e]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_1.loc15_13: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc15_13.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc15_13.1: <bound method> = bound_method %int_1.loc15_13, %impl.elem0.loc15_13.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc15_13.1: <specific function> = specific_function %impl.elem0.loc15_13.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc15_13.2: <bound method> = bound_method %int_1.loc15_13, %specific_fn.loc15_13.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc15_13: init %u1 = call %bound_method.loc15_13.2(%int_1.loc15_13) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc15_13.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc15_13 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc15_13.2: %u1 = converted %int_1.loc15_13, %.loc15_13.1 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc15_13.3: ref %u1 = class_element_access %p.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc15_13.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc15_13.3: <bound method> = bound_method %.loc15_13.2, %impl.elem0.loc15_13.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.22c]
// CHECK:STDOUT:   %specific_fn.loc15_13.2: <specific function> = specific_function %impl.elem0.loc15_13.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc15_13.4: <bound method> = bound_method %.loc15_13.2, %specific_fn.loc15_13.2 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc15_13.4: %u1 = acquire_value %.loc15_13.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc15: init bool = call %bound_method.loc15_13.4(%.loc15_13.2, %.loc15_13.4)
// CHECK:STDOUT:   %.loc15_13.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc15
// CHECK:STDOUT:   %.loc15_13.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc15, %.loc15_13.5
// CHECK:STDOUT:   if %.loc15_13.6 br !match.case.then.loc15 else br !match.case.else.loc15
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc15:
// CHECK:STDOUT:   %int_1.loc15_25: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc15_26: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc15_26.1: <bound method> = bound_method %int_1.loc15_25, %impl.elem0.loc15_26 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc15_26: <specific function> = specific_function %impl.elem0.loc15_26, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc15_26.2: <bound method> = bound_method %int_1.loc15_25, %specific_fn.loc15_26 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc15_26: init %i32 = call %bound_method.loc15_26.2(%int_1.loc15_25) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc15_26: init %i32 = converted %int_1.loc15_25, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc15_26 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   return %.loc15_26
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc15:
// CHECK:STDOUT:   br !match.done
// CHECK:STDOUT:
// CHECK:STDOUT: !match.done:
// CHECK:STDOUT:   %int_1.loc17: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem1: %.758 = impl_witness_access constants.%Negate.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %bound_method.loc17_10: <bound method> = bound_method %int_1.loc17, %impl.elem1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op.bound]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.call: init Core.IntLiteral = call %bound_method.loc17_10(%int_1.loc17) [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %impl.elem0.loc17: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc17_12.1: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %impl.elem0.loc17 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.65e]
// CHECK:STDOUT:   %specific_fn.loc17: <specific function> = specific_function %impl.elem0.loc17, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc17_12.2: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %specific_fn.loc17 [concrete = constants.%bound_method.a65]
// CHECK:STDOUT:   %.loc17_10.1: Core.IntLiteral = value_of_initializer %Core.IntLiteral.as.Negate.impl.Op.call [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %.loc17_10.2: Core.IntLiteral = converted %Core.IntLiteral.as.Negate.impl.Op.call, %.loc17_10.1 [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc17: init %i32 = call %bound_method.loc17_12.2(%.loc17_10.2) [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   %.loc17_12: init %i32 = converted %Core.IntLiteral.as.Negate.impl.Op.call, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc17 [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   return %.loc17_12
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Construct() -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %P.ref.loc25_19: %P.type = name_ref P, file.%P.decl [concrete = constants.%P.generic]
// CHECK:STDOUT:   %i32.loc25_21: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %P.loc25_24: type = class_type @P, @P(constants.%i32) [concrete = constants.%P.b38]
// CHECK:STDOUT:   %.loc25_25: %P.b38 = specific_constant @P.%.loc7_1.10, @P(constants.%i32) [concrete = constants.%P.val.61e]
// CHECK:STDOUT:   %B.ref: %P.b38 = name_ref B, %.loc25_25 [concrete = constants.%P.val.61e]
// CHECK:STDOUT:   %.loc25_15: type = splice_block %P.loc25_15 [concrete = constants.%P.b38] {
// CHECK:STDOUT:     %P.ref.loc25_10: %P.type = name_ref P, file.%P.decl [concrete = constants.%P.generic]
// CHECK:STDOUT:     %i32.loc25_12: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %P.loc25_15: type = class_type @P, @P(constants.%i32) [concrete = constants.%P.b38]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %b: %P.b38 = wrapper_binding b, %B.ref
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %b.patt: %pattern_type.e96 = value_binding_pattern b [concrete = constants.%b.patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Classify.ref: %Classify.type = name_ref Classify, file.%Classify.decl [concrete = constants.%Classify]
// CHECK:STDOUT:   %b.ref: %P.b38 = name_ref b, %b
// CHECK:STDOUT:   %Classify.call: init %i32 = call %Classify.ref(%b.ref)
// CHECK:STDOUT:   return %Classify.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @P(constants.%T.67d) {
// CHECK:STDOUT:   %T.patt.loc4_11.2 => constants.%T.patt.d47
// CHECK:STDOUT:   %T.loc4_11.1 => constants.%T.67d
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @P(constants.%i32) {
// CHECK:STDOUT:   %T.patt.loc4_11.2 => constants.%T.patt.d47
// CHECK:STDOUT:   %T.loc4_11.1 => constants.%i32
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %P => constants.%P.b38
// CHECK:STDOUT:   %require_complete => constants.%complete_type.3a6
// CHECK:STDOUT:   %P.val.loc5 => constants.%P.val.0e9
// CHECK:STDOUT:   %.loc5_4.11 => constants.%.043
// CHECK:STDOUT:   %P.val.loc7 => constants.%P.val.61e
// CHECK:STDOUT:   %.loc7_1.11 => constants.%.91e
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- two_specifics.carbon
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
// CHECK:STDOUT:   %require_complete.657: <witness> = require_complete_type %P.f86 [symbolic]
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
// CHECK:STDOUT:   %P.val.7d0: %P.f86 = struct_value (%int_0.1a7) [symbolic]
// CHECK:STDOUT:   %.72a: ref %P.f86 = temporary invalid, %P.val.7d0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %bound_method.d7a: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
// CHECK:STDOUT:   %int_1.233: %u1 = int_value 1 [concrete]
// CHECK:STDOUT:   %struct.a79: %struct_type.discriminant = struct_value (%int_1.233) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.bound.332: <bound method> = bound_method %int_1.233, %UInt.as.Copy.impl.Op.d9c [concrete]
// CHECK:STDOUT:   %bound_method.edd: <bound method> = bound_method %int_1.233, %UInt.as.Copy.impl.Op.specific_fn [concrete]
// CHECK:STDOUT:   %P.val.e49: %P.f86 = struct_value (%int_1.233) [symbolic]
// CHECK:STDOUT:   %.3aa: ref %P.f86 = temporary invalid, %P.val.e49 [symbolic]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %P.b38: type = class_type @P, @P(%i32) [concrete]
// CHECK:STDOUT:   %pattern_type.e96: type = pattern_type %P.b38 [concrete]
// CHECK:STDOUT:   %a.param_patt: %pattern_type.e96 = value_param_pattern [concrete]
// CHECK:STDOUT:   %a.patt: %pattern_type.e96 = at_binding_pattern a, %a.param_patt [concrete]
// CHECK:STDOUT:   %P.94c: type = class_type @P, @P(bool) [concrete]
// CHECK:STDOUT:   %pattern_type.b3c: type = pattern_type %P.94c [concrete]
// CHECK:STDOUT:   %b.param_patt: %pattern_type.b3c = value_param_pattern [concrete]
// CHECK:STDOUT:   %b.patt: %pattern_type.b3c = at_binding_pattern b, %b.param_patt [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %G.type: type = fn_type @G [concrete]
// CHECK:STDOUT:   %G: %G.type = struct_value () [concrete]
// CHECK:STDOUT:   %P.val.0e9: %P.b38 = struct_value (%int_0.1a7) [concrete]
// CHECK:STDOUT:   %.043: ref %P.b38 = temporary invalid, %P.val.0e9 [concrete]
// CHECK:STDOUT:   %P.val.61e: %P.b38 = struct_value (%int_1.233) [concrete]
// CHECK:STDOUT:   %.91e: ref %P.b38 = temporary invalid, %P.val.61e [concrete]
// CHECK:STDOUT:   %P.val.81d: %P.94c = struct_value (%int_0.1a7) [concrete]
// CHECK:STDOUT:   %.796: ref %P.94c = temporary invalid, %P.val.81d [concrete]
// CHECK:STDOUT:   %P.val.7b9: %P.94c = struct_value (%int_1.233) [concrete]
// CHECK:STDOUT:   %.c15: ref %P.94c = temporary invalid, %P.val.7b9 [concrete]
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
// CHECK:STDOUT:   %int_2.ecc: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.9f3: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.3cb: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_2.295: %i32 = int_value 2 [concrete]
// CHECK:STDOUT:   %int_3.1ba: Core.IntLiteral = int_value 3 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.485: <bound method> = bound_method %int_3.1ba, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.763: <bound method> = bound_method %int_3.1ba, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_3.410: %i32 = int_value 3 [concrete]
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
// CHECK:STDOUT:   %G.decl: %G.type = fn_decl @G [concrete = constants.%G] {
// CHECK:STDOUT:     %a.param_patt: %pattern_type.e96 = value_param_pattern [concrete = constants.%a.param_patt]
// CHECK:STDOUT:     %a.patt: %pattern_type.e96 = at_binding_pattern a, %a.param_patt [concrete = constants.%a.patt]
// CHECK:STDOUT:     %b.param_patt: %pattern_type.b3c = value_param_pattern [concrete = constants.%b.param_patt]
// CHECK:STDOUT:     %b.patt: %pattern_type.b3c = at_binding_pattern b, %b.param_patt [concrete = constants.%b.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc13_32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc13_32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc13_32: Core.Form = init_form %i32.loc13_32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %a.param: %P.b38 = value_param call_param0
// CHECK:STDOUT:     %.loc13_14: type = splice_block %P.loc13_14 [concrete = constants.%P.b38] {
// CHECK:STDOUT:       %P.ref.loc13_9: %P.type = name_ref P, file.%P.decl [concrete = constants.%P.generic]
// CHECK:STDOUT:       %i32.loc13_11: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %P.loc13_14: type = class_type @P, @P(constants.%i32) [concrete = constants.%P.b38]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %a: %P.b38 = wrapper_binding a, %a.param
// CHECK:STDOUT:     %b.param: %P.94c = value_param call_param1
// CHECK:STDOUT:     %.loc13_26: type = splice_block %P.loc13_26 [concrete = constants.%P.94c] {
// CHECK:STDOUT:       %P.ref.loc13_20: %P.type = name_ref P, file.%P.decl [concrete = constants.%P.generic]
// CHECK:STDOUT:       %.loc13_22: type = type_literal bool [concrete = bool]
// CHECK:STDOUT:       %P.loc13_26: type = class_type @P, @P(bool) [concrete = constants.%P.94c]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %b: %P.94c = wrapper_binding b, %b.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param2
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic class @P(%T.loc4_11.2: type) {
// CHECK:STDOUT:   %T.patt.loc4_11.2: %pattern_type.98f = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc4_11.2 (constants.%T.patt.d47)]
// CHECK:STDOUT:   %T.loc4_11.1: type = symbolic_binding T, 0 [symbolic = %T.loc4_11.1 (constants.%T.67d)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %P: type = class_type @P, @P(%T.loc4_11.1) [symbolic = %P (constants.%P.f86)]
// CHECK:STDOUT:   %require_complete: <witness> = require_complete_type %P [symbolic = %require_complete (constants.%require_complete.657)]
// CHECK:STDOUT:   %P.val.loc5: @P.%P (%P.f86) = struct_value (constants.%int_0.1a7) [symbolic = %P.val.loc5 (constants.%P.val.7d0)]
// CHECK:STDOUT:   %.loc5_4.11: ref @P.%P (%P.f86) = temporary invalid, %P.val.loc5 [symbolic = %.loc5_4.11 (constants.%.72a)]
// CHECK:STDOUT:   %P.val.loc7: @P.%P (%P.f86) = struct_value (constants.%int_1.233) [symbolic = %P.val.loc7 (constants.%P.val.e49)]
// CHECK:STDOUT:   %.loc7_1.11: ref @P.%P (%P.f86) = temporary invalid, %P.val.loc7 [symbolic = %.loc7_1.11 (constants.%.3aa)]
// CHECK:STDOUT:
// CHECK:STDOUT:   class {
// CHECK:STDOUT:     %complete_type: <witness> = complete_type_witness constants.%struct_type.discriminant [concrete = constants.%complete_type.3a6]
// CHECK:STDOUT:     %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:     %impl.elem0.loc5_4.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:     %bound_method.loc5_4.1: <bound method> = bound_method %int_0, %impl.elem0.loc5_4.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:     %specific_fn.loc5_4.1: <specific function> = specific_function %impl.elem0.loc5_4.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:     %bound_method.loc5_4.2: <bound method> = bound_method %int_0, %specific_fn.loc5_4.1 [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc5: init %u1 = call %bound_method.loc5_4.2(%int_0) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:     %.loc5_4.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc5 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:     %.loc5_4.2: %u1 = converted %int_0, %.loc5_4.1 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:     %.loc5_4.3: %struct_type.discriminant = struct_literal (%.loc5_4.2) [concrete = constants.%struct.249]
// CHECK:STDOUT:     %impl.elem0.loc5_4.2: %.952 = impl_witness_access constants.%Copy.impl_witness.334, element0 [concrete = constants.%UInt.as.Copy.impl.Op.d9c]
// CHECK:STDOUT:     %bound_method.loc5_4.3: <bound method> = bound_method %.loc5_4.2, %impl.elem0.loc5_4.2 [concrete = constants.%UInt.as.Copy.impl.Op.bound.bd0]
// CHECK:STDOUT:     %specific_fn.loc5_4.2: <specific function> = specific_function %impl.elem0.loc5_4.2, @UInt.as.Copy.impl.Op(constants.%int_1.5b8) [concrete = constants.%UInt.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:     %bound_method.loc5_4.4: <bound method> = bound_method %.loc5_4.2, %specific_fn.loc5_4.2 [concrete = constants.%bound_method.61c]
// CHECK:STDOUT:     %UInt.as.Copy.impl.Op.call.loc5: init %u1 = call %bound_method.loc5_4.4(%.loc5_4.2) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:     %.loc5_4.4: ref @P.%P (%P.f86) = temporary_storage
// CHECK:STDOUT:     %.loc5_4.5: ref %u1 = class_element_access %.loc5_4.4, element0
// CHECK:STDOUT:     %.loc5_4.6: init %u1 to %.loc5_4.5 = in_place_init %UInt.as.Copy.impl.Op.call.loc5 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:     %.loc5_4.7: init @P.%P (%P.f86) to %.loc5_4.4 = class_init (%.loc5_4.6) [symbolic = %P.val.loc5 (constants.%P.val.7d0)]
// CHECK:STDOUT:     %.loc5_4.8: init @P.%P (%P.f86) = converted %.loc5_4.3, %.loc5_4.7 [symbolic = %P.val.loc5 (constants.%P.val.7d0)]
// CHECK:STDOUT:     %.loc5_4.9: ref @P.%P (%P.f86) = temporary %.loc5_4.4, %.loc5_4.8 [symbolic = %.loc5_4.11 (constants.%.72a)]
// CHECK:STDOUT:     %.loc5_4.10: @P.%P (%P.f86) = acquire_value %.loc5_4.9 [symbolic = %P.val.loc5 (constants.%P.val.7d0)]
// CHECK:STDOUT:     %A: @P.%P (%P.f86) = wrapper_binding A, %.loc5_4.10
// CHECK:STDOUT:     %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:     %impl.elem0.loc7_1.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:     %bound_method.loc7_1.1: <bound method> = bound_method %int_1, %impl.elem0.loc7_1.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:     %specific_fn.loc7_1.1: <specific function> = specific_function %impl.elem0.loc7_1.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:     %bound_method.loc7_1.2: <bound method> = bound_method %int_1, %specific_fn.loc7_1.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc7: init %u1 = call %bound_method.loc7_1.2(%int_1) [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc7_1.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc7 [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc7_1.2: %u1 = converted %int_1, %.loc7_1.1 [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc7_1.3: %struct_type.discriminant = struct_literal (%.loc7_1.2) [concrete = constants.%struct.a79]
// CHECK:STDOUT:     %impl.elem0.loc7_1.2: %.952 = impl_witness_access constants.%Copy.impl_witness.334, element0 [concrete = constants.%UInt.as.Copy.impl.Op.d9c]
// CHECK:STDOUT:     %bound_method.loc7_1.3: <bound method> = bound_method %.loc7_1.2, %impl.elem0.loc7_1.2 [concrete = constants.%UInt.as.Copy.impl.Op.bound.332]
// CHECK:STDOUT:     %specific_fn.loc7_1.2: <specific function> = specific_function %impl.elem0.loc7_1.2, @UInt.as.Copy.impl.Op(constants.%int_1.5b8) [concrete = constants.%UInt.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:     %bound_method.loc7_1.4: <bound method> = bound_method %.loc7_1.2, %specific_fn.loc7_1.2 [concrete = constants.%bound_method.edd]
// CHECK:STDOUT:     %UInt.as.Copy.impl.Op.call.loc7: init %u1 = call %bound_method.loc7_1.4(%.loc7_1.2) [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc7_1.4: ref @P.%P (%P.f86) = temporary_storage
// CHECK:STDOUT:     %.loc7_1.5: ref %u1 = class_element_access %.loc7_1.4, element0
// CHECK:STDOUT:     %.loc7_1.6: init %u1 to %.loc7_1.5 = in_place_init %UInt.as.Copy.impl.Op.call.loc7 [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc7_1.7: init @P.%P (%P.f86) to %.loc7_1.4 = class_init (%.loc7_1.6) [symbolic = %P.val.loc7 (constants.%P.val.e49)]
// CHECK:STDOUT:     %.loc7_1.8: init @P.%P (%P.f86) = converted %.loc7_1.3, %.loc7_1.7 [symbolic = %P.val.loc7 (constants.%P.val.e49)]
// CHECK:STDOUT:     %.loc7_1.9: ref @P.%P (%P.f86) = temporary %.loc7_1.4, %.loc7_1.8 [symbolic = %.loc7_1.11 (constants.%.3aa)]
// CHECK:STDOUT:     %.loc7_1.10: @P.%P (%P.f86) = acquire_value %.loc7_1.9 [symbolic = %P.val.loc7 (constants.%P.val.e49)]
// CHECK:STDOUT:     %B: @P.%P (%P.f86) = wrapper_binding B, %.loc7_1.10
// CHECK:STDOUT:     complete_type_witness = %complete_type
// CHECK:STDOUT:
// CHECK:STDOUT:   !members:
// CHECK:STDOUT:     .Self = constants.%P.f86
// CHECK:STDOUT:     .A = %A
// CHECK:STDOUT:     .B = %B
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @G(%a.param: %P.b38, %b.param: %P.94c) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %a.ref: %P.b38 = name_ref a, %a
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt.loc15: %pattern_type.e96 = expr_pattern %A.ref.loc15 in [concrete] {
// CHECK:STDOUT:       %.loc15_10.2: %P.b38 = specific_constant @P.%.loc5_4.10, @P(constants.%i32) [concrete = constants.%P.val.0e9]
// CHECK:STDOUT:       %A.ref.loc15: %P.b38 = name_ref A, %.loc15_10.2 [concrete = constants.%P.val.0e9]
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %.loc15_10.1: %P.b38 = splice_block %A.ref.loc15 [concrete = constants.%P.val.0e9] {
// CHECK:STDOUT:     %.loc15_10.2: %P.b38 = specific_constant @P.%.loc5_4.10, @P(constants.%i32) [concrete = constants.%P.val.0e9]
// CHECK:STDOUT:     %A.ref.loc15: %P.b38 = name_ref A, %.loc15_10.2 [concrete = constants.%P.val.0e9]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_0.loc15_13: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc15_13.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc15_13.1: <bound method> = bound_method %int_0.loc15_13, %impl.elem0.loc15_13.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:   %specific_fn.loc15_13.1: <specific function> = specific_function %impl.elem0.loc15_13.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc15_13.2: <bound method> = bound_method %int_0.loc15_13, %specific_fn.loc15_13.1 [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc15_13: init %u1 = call %bound_method.loc15_13.2(%int_0.loc15_13) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc15_13.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc15_13 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc15_13.2: %u1 = converted %int_0.loc15_13, %.loc15_13.1 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc15_13.3: ref %u1 = class_element_access %a.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc15_13.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc15_13.3: <bound method> = bound_method %.loc15_13.2, %impl.elem0.loc15_13.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.f34]
// CHECK:STDOUT:   %specific_fn.loc15_13.2: <specific function> = specific_function %impl.elem0.loc15_13.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc15_13.4: <bound method> = bound_method %.loc15_13.2, %specific_fn.loc15_13.2 [concrete = constants.%bound_method.53a]
// CHECK:STDOUT:   %.loc15_13.4: %u1 = acquire_value %.loc15_13.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc15: init bool = call %bound_method.loc15_13.4(%.loc15_13.2, %.loc15_13.4)
// CHECK:STDOUT:   %.loc15_13.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc15
// CHECK:STDOUT:   %.loc15_13.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc15, %.loc15_13.5
// CHECK:STDOUT:   if %.loc15_13.6 br !match.case.then.loc15 else br !match.case.else.loc15
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc15:
// CHECK:STDOUT:   %int_0.loc15_25: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc15_26: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc15_26.1: <bound method> = bound_method %int_0.loc15_25, %impl.elem0.loc15_26 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc15_26: <specific function> = specific_function %impl.elem0.loc15_26, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc15_26.2: <bound method> = bound_method %int_0.loc15_25, %specific_fn.loc15_26 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc15_26: init %i32 = call %bound_method.loc15_26.2(%int_0.loc15_25) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc15_26: init %i32 = converted %int_0.loc15_25, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc15_26 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   return %.loc15_26
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc15:
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt.loc16: %pattern_type.e96 = expr_pattern %B.ref.loc16 in [concrete] {
// CHECK:STDOUT:       %.loc16_10.2: %P.b38 = specific_constant @P.%.loc7_1.10, @P(constants.%i32) [concrete = constants.%P.val.61e]
// CHECK:STDOUT:       %B.ref.loc16: %P.b38 = name_ref B, %.loc16_10.2 [concrete = constants.%P.val.61e]
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %.loc16_10.1: %P.b38 = splice_block %B.ref.loc16 [concrete = constants.%P.val.61e] {
// CHECK:STDOUT:     %.loc16_10.2: %P.b38 = specific_constant @P.%.loc7_1.10, @P(constants.%i32) [concrete = constants.%P.val.61e]
// CHECK:STDOUT:     %B.ref.loc16: %P.b38 = name_ref B, %.loc16_10.2 [concrete = constants.%P.val.61e]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_1.loc16_13: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc16_13.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc16_13.1: <bound method> = bound_method %int_1.loc16_13, %impl.elem0.loc16_13.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc16_13.1: <specific function> = specific_function %impl.elem0.loc16_13.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc16_13.2: <bound method> = bound_method %int_1.loc16_13, %specific_fn.loc16_13.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16_13: init %u1 = call %bound_method.loc16_13.2(%int_1.loc16_13) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc16_13.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16_13 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc16_13.2: %u1 = converted %int_1.loc16_13, %.loc16_13.1 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc16_13.3: ref %u1 = class_element_access %a.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc16_13.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc16_13.3: <bound method> = bound_method %.loc16_13.2, %impl.elem0.loc16_13.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.22c]
// CHECK:STDOUT:   %specific_fn.loc16_13.2: <specific function> = specific_function %impl.elem0.loc16_13.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc16_13.4: <bound method> = bound_method %.loc16_13.2, %specific_fn.loc16_13.2 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc16_13.4: %u1 = acquire_value %.loc16_13.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc16: init bool = call %bound_method.loc16_13.4(%.loc16_13.2, %.loc16_13.4)
// CHECK:STDOUT:   %.loc16_13.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc16
// CHECK:STDOUT:   %.loc16_13.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc16, %.loc16_13.5
// CHECK:STDOUT:   if %.loc16_13.6 br !match.case.then.loc16 else br !match.case.else.loc16
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc16:
// CHECK:STDOUT:   %int_1.loc16_25: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc16_26: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc16_26.1: <bound method> = bound_method %int_1.loc16_25, %impl.elem0.loc16_26 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc16_26: <specific function> = specific_function %impl.elem0.loc16_26, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc16_26.2: <bound method> = bound_method %int_1.loc16_25, %specific_fn.loc16_26 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16_26: init %i32 = call %bound_method.loc16_26.2(%int_1.loc16_25) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc16_26: init %i32 = converted %int_1.loc16_25, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16_26 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   return %.loc16_26
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc16:
// CHECK:STDOUT:   br !match.done.loc17
// CHECK:STDOUT:
// CHECK:STDOUT: !match.done.loc17:
// CHECK:STDOUT:   %b.ref: %P.94c = name_ref b, %b
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt.loc19: %pattern_type.b3c = expr_pattern %A.ref.loc19 in [concrete] {
// CHECK:STDOUT:       %.loc19_10.2: %P.94c = specific_constant @P.%.loc5_4.10, @P(bool) [concrete = constants.%P.val.81d]
// CHECK:STDOUT:       %A.ref.loc19: %P.94c = name_ref A, %.loc19_10.2 [concrete = constants.%P.val.81d]
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %.loc19_10.1: %P.94c = splice_block %A.ref.loc19 [concrete = constants.%P.val.81d] {
// CHECK:STDOUT:     %.loc19_10.2: %P.94c = specific_constant @P.%.loc5_4.10, @P(bool) [concrete = constants.%P.val.81d]
// CHECK:STDOUT:     %A.ref.loc19: %P.94c = name_ref A, %.loc19_10.2 [concrete = constants.%P.val.81d]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_0.loc19: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc19_13.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc19_13.1: <bound method> = bound_method %int_0.loc19, %impl.elem0.loc19_13.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:   %specific_fn.loc19_13.1: <specific function> = specific_function %impl.elem0.loc19_13.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc19_13.2: <bound method> = bound_method %int_0.loc19, %specific_fn.loc19_13.1 [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc19_13: init %u1 = call %bound_method.loc19_13.2(%int_0.loc19) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc19_13.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc19_13 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc19_13.2: %u1 = converted %int_0.loc19, %.loc19_13.1 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc19_13.3: ref %u1 = class_element_access %b.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc19_13.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc19_13.3: <bound method> = bound_method %.loc19_13.2, %impl.elem0.loc19_13.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.f34]
// CHECK:STDOUT:   %specific_fn.loc19_13.2: <specific function> = specific_function %impl.elem0.loc19_13.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc19_13.4: <bound method> = bound_method %.loc19_13.2, %specific_fn.loc19_13.2 [concrete = constants.%bound_method.53a]
// CHECK:STDOUT:   %.loc19_13.4: %u1 = acquire_value %.loc19_13.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc19: init bool = call %bound_method.loc19_13.4(%.loc19_13.2, %.loc19_13.4)
// CHECK:STDOUT:   %.loc19_13.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc19
// CHECK:STDOUT:   %.loc19_13.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc19, %.loc19_13.5
// CHECK:STDOUT:   if %.loc19_13.6 br !match.case.then.loc19 else br !match.case.else.loc19
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc19:
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:   %impl.elem0.loc19_26: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc19_26.1: <bound method> = bound_method %int_2, %impl.elem0.loc19_26 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.9f3]
// CHECK:STDOUT:   %specific_fn.loc19_26: <specific function> = specific_function %impl.elem0.loc19_26, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc19_26.2: <bound method> = bound_method %int_2, %specific_fn.loc19_26 [concrete = constants.%bound_method.3cb]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc19_26: init %i32 = call %bound_method.loc19_26.2(%int_2) [concrete = constants.%int_2.295]
// CHECK:STDOUT:   %.loc19_26: init %i32 = converted %int_2, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc19_26 [concrete = constants.%int_2.295]
// CHECK:STDOUT:   return %.loc19_26
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc19:
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt.loc20: %pattern_type.b3c = expr_pattern %B.ref.loc20 in [concrete] {
// CHECK:STDOUT:       %.loc20_10.2: %P.94c = specific_constant @P.%.loc7_1.10, @P(bool) [concrete = constants.%P.val.7b9]
// CHECK:STDOUT:       %B.ref.loc20: %P.94c = name_ref B, %.loc20_10.2 [concrete = constants.%P.val.7b9]
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %.loc20_10.1: %P.94c = splice_block %B.ref.loc20 [concrete = constants.%P.val.7b9] {
// CHECK:STDOUT:     %.loc20_10.2: %P.94c = specific_constant @P.%.loc7_1.10, @P(bool) [concrete = constants.%P.val.7b9]
// CHECK:STDOUT:     %B.ref.loc20: %P.94c = name_ref B, %.loc20_10.2 [concrete = constants.%P.val.7b9]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_1.loc20: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc20_13.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc20_13.1: <bound method> = bound_method %int_1.loc20, %impl.elem0.loc20_13.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc20_13.1: <specific function> = specific_function %impl.elem0.loc20_13.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc20_13.2: <bound method> = bound_method %int_1.loc20, %specific_fn.loc20_13.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc20_13: init %u1 = call %bound_method.loc20_13.2(%int_1.loc20) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc20_13.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc20_13 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc20_13.2: %u1 = converted %int_1.loc20, %.loc20_13.1 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc20_13.3: ref %u1 = class_element_access %b.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc20_13.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc20_13.3: <bound method> = bound_method %.loc20_13.2, %impl.elem0.loc20_13.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.22c]
// CHECK:STDOUT:   %specific_fn.loc20_13.2: <specific function> = specific_function %impl.elem0.loc20_13.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc20_13.4: <bound method> = bound_method %.loc20_13.2, %specific_fn.loc20_13.2 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc20_13.4: %u1 = acquire_value %.loc20_13.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc20: init bool = call %bound_method.loc20_13.4(%.loc20_13.2, %.loc20_13.4)
// CHECK:STDOUT:   %.loc20_13.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc20
// CHECK:STDOUT:   %.loc20_13.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc20, %.loc20_13.5
// CHECK:STDOUT:   if %.loc20_13.6 br !match.case.then.loc20 else br !match.case.else.loc20
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc20:
// CHECK:STDOUT:   %int_3: Core.IntLiteral = int_value 3 [concrete = constants.%int_3.1ba]
// CHECK:STDOUT:   %impl.elem0.loc20_26: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc20_26.1: <bound method> = bound_method %int_3, %impl.elem0.loc20_26 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.485]
// CHECK:STDOUT:   %specific_fn.loc20_26: <specific function> = specific_function %impl.elem0.loc20_26, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc20_26.2: <bound method> = bound_method %int_3, %specific_fn.loc20_26 [concrete = constants.%bound_method.763]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc20_26: init %i32 = call %bound_method.loc20_26.2(%int_3) [concrete = constants.%int_3.410]
// CHECK:STDOUT:   %.loc20_26: init %i32 = converted %int_3, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc20_26 [concrete = constants.%int_3.410]
// CHECK:STDOUT:   return %.loc20_26
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc20:
// CHECK:STDOUT:   br !match.done.loc21
// CHECK:STDOUT:
// CHECK:STDOUT: !match.done.loc21:
// CHECK:STDOUT:   %int_1.loc22: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem1: %.758 = impl_witness_access constants.%Negate.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %bound_method.loc22_10: <bound method> = bound_method %int_1.loc22, %impl.elem1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op.bound]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.call: init Core.IntLiteral = call %bound_method.loc22_10(%int_1.loc22) [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %impl.elem0.loc22: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc22_12.1: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %impl.elem0.loc22 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.65e]
// CHECK:STDOUT:   %specific_fn.loc22: <specific function> = specific_function %impl.elem0.loc22, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc22_12.2: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %specific_fn.loc22 [concrete = constants.%bound_method.a65]
// CHECK:STDOUT:   %.loc22_10.1: Core.IntLiteral = value_of_initializer %Core.IntLiteral.as.Negate.impl.Op.call [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %.loc22_10.2: Core.IntLiteral = converted %Core.IntLiteral.as.Negate.impl.Op.call, %.loc22_10.1 [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc22: init %i32 = call %bound_method.loc22_12.2(%.loc22_10.2) [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   %.loc22_12: init %i32 = converted %Core.IntLiteral.as.Negate.impl.Op.call, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc22 [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   return %.loc22_12
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @P(constants.%T.67d) {
// CHECK:STDOUT:   %T.patt.loc4_11.2 => constants.%T.patt.d47
// CHECK:STDOUT:   %T.loc4_11.1 => constants.%T.67d
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @P(constants.%i32) {
// CHECK:STDOUT:   %T.patt.loc4_11.2 => constants.%T.patt.d47
// CHECK:STDOUT:   %T.loc4_11.1 => constants.%i32
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %P => constants.%P.b38
// CHECK:STDOUT:   %require_complete => constants.%complete_type.3a6
// CHECK:STDOUT:   %P.val.loc5 => constants.%P.val.0e9
// CHECK:STDOUT:   %.loc5_4.11 => constants.%.043
// CHECK:STDOUT:   %P.val.loc7 => constants.%P.val.61e
// CHECK:STDOUT:   %.loc7_1.11 => constants.%.91e
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @P(bool) {
// CHECK:STDOUT:   %T.patt.loc4_11.2 => constants.%T.patt.d47
// CHECK:STDOUT:   %T.loc4_11.1 => bool
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %P => constants.%P.94c
// CHECK:STDOUT:   %require_complete => constants.%complete_type.3a6
// CHECK:STDOUT:   %P.val.loc5 => constants.%P.val.81d
// CHECK:STDOUT:   %.loc5_4.11 => constants.%.796
// CHECK:STDOUT:   %P.val.loc7 => constants.%P.val.7b9
// CHECK:STDOUT:   %.loc7_1.11 => constants.%.c15
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- symbolic_specific.carbon
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
// CHECK:STDOUT:   %require_complete.657: <witness> = require_complete_type %P.f86 [symbolic]
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
// CHECK:STDOUT:   %P.val.7d0: %P.f86 = struct_value (%int_0.1a7) [symbolic]
// CHECK:STDOUT:   %.72a: ref %P.f86 = temporary invalid, %P.val.7d0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %bound_method.d7a: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
// CHECK:STDOUT:   %int_1.233: %u1 = int_value 1 [concrete]
// CHECK:STDOUT:   %struct.a79: %struct_type.discriminant = struct_value (%int_1.233) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.bound.332: <bound method> = bound_method %int_1.233, %UInt.as.Copy.impl.Op.d9c [concrete]
// CHECK:STDOUT:   %bound_method.edd: <bound method> = bound_method %int_1.233, %UInt.as.Copy.impl.Op.specific_fn [concrete]
// CHECK:STDOUT:   %P.val.e49: %P.f86 = struct_value (%int_1.233) [symbolic]
// CHECK:STDOUT:   %.3aa: ref %P.f86 = temporary invalid, %P.val.e49 [symbolic]
// CHECK:STDOUT:   %pattern_type.6d3: type = pattern_type %P.f86 [symbolic]
// CHECK:STDOUT:   %x.param_patt.038: %pattern_type.6d3 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %x.patt.aa3: %pattern_type.6d3 = at_binding_pattern x, %x.param_patt.038 [symbolic]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
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
// CHECK:STDOUT:   %p.param_patt: %pattern_type.e96 = value_param_pattern [concrete]
// CHECK:STDOUT:   %p.patt: %pattern_type.e96 = at_binding_pattern p, %p.param_patt [concrete]
// CHECK:STDOUT:   %Call.type: type = fn_type @Call [concrete]
// CHECK:STDOUT:   %Call: %Call.type = struct_value () [concrete]
// CHECK:STDOUT:   %P.val.0e9: %P.b38 = struct_value (%int_0.1a7) [concrete]
// CHECK:STDOUT:   %.043: ref %P.b38 = temporary invalid, %P.val.0e9 [concrete]
// CHECK:STDOUT:   %P.val.61e: %P.b38 = struct_value (%int_1.233) [concrete]
// CHECK:STDOUT:   %.91e: ref %P.b38 = temporary invalid, %P.val.61e [concrete]
// CHECK:STDOUT:   %x.param_patt.755: %pattern_type.e96 = value_param_pattern [concrete]
// CHECK:STDOUT:   %x.patt.fe3: %pattern_type.e96 = at_binding_pattern x, %x.param_patt.755 [concrete]
// CHECK:STDOUT:   %F.specific_fn: <specific function> = specific_function %F, @F(%i32) [concrete]
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
// CHECK:STDOUT:     %T.patt.loc14_7.1: %pattern_type.98f = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc14_7.2 (constants.%T.patt.d47)]
// CHECK:STDOUT:     %x.param_patt.loc14_16.1: @F.%pattern_type (%pattern_type.6d3) = value_param_pattern [symbolic = %x.param_patt.loc14_16.2 (constants.%x.param_patt.038)]
// CHECK:STDOUT:     %x.patt.loc14_16.1: @F.%pattern_type (%pattern_type.6d3) = at_binding_pattern x, %x.param_patt.loc14_16.1 [symbolic = %x.patt.loc14_16.2 (constants.%x.patt.aa3)]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc14_27: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %.loc14_9.1: type = splice_block %.loc14_9.2 [concrete = type] {
// CHECK:STDOUT:       %.Self.frozen: %type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %.loc14_9.2: type = type_literal type [concrete = type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc14_7.2: type = symbolic_binding T, 0 [symbolic = %T.loc14_7.1 (constants.%T.67d)]
// CHECK:STDOUT:     %x.param: @F.%P.loc14_21.1 (%P.f86) = value_param call_param0
// CHECK:STDOUT:     %.loc14_21: type = splice_block %P.loc14_21.2 [symbolic = %P.loc14_21.1 (constants.%P.f86)] {
// CHECK:STDOUT:       %P.ref: %P.type = name_ref P, file.%P.decl [concrete = constants.%P.generic]
// CHECK:STDOUT:       %T.ref: type = name_ref T, %T.loc14_7.2 [symbolic = %T.loc14_7.1 (constants.%T.67d)]
// CHECK:STDOUT:       %P.loc14_21.2: type = class_type @P, @P(constants.%T.67d) [symbolic = %P.loc14_21.1 (constants.%P.f86)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %x: @F.%P.loc14_21.1 (%P.f86) = wrapper_binding x, %x.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Call.decl: %Call.type = fn_decl @Call [concrete = constants.%Call] {
// CHECK:STDOUT:     %p.param_patt: %pattern_type.e96 = value_param_pattern [concrete = constants.%p.param_patt]
// CHECK:STDOUT:     %p.patt: %pattern_type.e96 = at_binding_pattern p, %p.param_patt [concrete = constants.%p.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc22_23 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc22_23: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc22_23: Core.Form = init_form %i32.loc22_23 [concrete = constants.%.795f]
// CHECK:STDOUT:     %p.param: %P.b38 = value_param call_param0
// CHECK:STDOUT:     %.loc22_17: type = splice_block %P [concrete = constants.%P.b38] {
// CHECK:STDOUT:       %P.ref: %P.type = name_ref P, file.%P.decl [concrete = constants.%P.generic]
// CHECK:STDOUT:       %i32.loc22_14: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %P: type = class_type @P, @P(constants.%i32) [concrete = constants.%P.b38]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %p: %P.b38 = wrapper_binding p, %p.param
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
// CHECK:STDOUT:   %P: type = class_type @P, @P(%T.loc4_11.1) [symbolic = %P (constants.%P.f86)]
// CHECK:STDOUT:   %require_complete: <witness> = require_complete_type %P [symbolic = %require_complete (constants.%require_complete.657)]
// CHECK:STDOUT:   %P.val.loc5: @P.%P (%P.f86) = struct_value (constants.%int_0.1a7) [symbolic = %P.val.loc5 (constants.%P.val.7d0)]
// CHECK:STDOUT:   %.loc5_4.11: ref @P.%P (%P.f86) = temporary invalid, %P.val.loc5 [symbolic = %.loc5_4.11 (constants.%.72a)]
// CHECK:STDOUT:   %P.val.loc7: @P.%P (%P.f86) = struct_value (constants.%int_1.233) [symbolic = %P.val.loc7 (constants.%P.val.e49)]
// CHECK:STDOUT:   %.loc7_1.11: ref @P.%P (%P.f86) = temporary invalid, %P.val.loc7 [symbolic = %.loc7_1.11 (constants.%.3aa)]
// CHECK:STDOUT:
// CHECK:STDOUT:   class {
// CHECK:STDOUT:     %complete_type: <witness> = complete_type_witness constants.%struct_type.discriminant [concrete = constants.%complete_type.3a6]
// CHECK:STDOUT:     %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:     %impl.elem0.loc5_4.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:     %bound_method.loc5_4.1: <bound method> = bound_method %int_0, %impl.elem0.loc5_4.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:     %specific_fn.loc5_4.1: <specific function> = specific_function %impl.elem0.loc5_4.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:     %bound_method.loc5_4.2: <bound method> = bound_method %int_0, %specific_fn.loc5_4.1 [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc5: init %u1 = call %bound_method.loc5_4.2(%int_0) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:     %.loc5_4.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc5 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:     %.loc5_4.2: %u1 = converted %int_0, %.loc5_4.1 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:     %.loc5_4.3: %struct_type.discriminant = struct_literal (%.loc5_4.2) [concrete = constants.%struct.249]
// CHECK:STDOUT:     %impl.elem0.loc5_4.2: %.952 = impl_witness_access constants.%Copy.impl_witness.334, element0 [concrete = constants.%UInt.as.Copy.impl.Op.d9c]
// CHECK:STDOUT:     %bound_method.loc5_4.3: <bound method> = bound_method %.loc5_4.2, %impl.elem0.loc5_4.2 [concrete = constants.%UInt.as.Copy.impl.Op.bound.bd0]
// CHECK:STDOUT:     %specific_fn.loc5_4.2: <specific function> = specific_function %impl.elem0.loc5_4.2, @UInt.as.Copy.impl.Op(constants.%int_1.5b8) [concrete = constants.%UInt.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:     %bound_method.loc5_4.4: <bound method> = bound_method %.loc5_4.2, %specific_fn.loc5_4.2 [concrete = constants.%bound_method.61c]
// CHECK:STDOUT:     %UInt.as.Copy.impl.Op.call.loc5: init %u1 = call %bound_method.loc5_4.4(%.loc5_4.2) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:     %.loc5_4.4: ref @P.%P (%P.f86) = temporary_storage
// CHECK:STDOUT:     %.loc5_4.5: ref %u1 = class_element_access %.loc5_4.4, element0
// CHECK:STDOUT:     %.loc5_4.6: init %u1 to %.loc5_4.5 = in_place_init %UInt.as.Copy.impl.Op.call.loc5 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:     %.loc5_4.7: init @P.%P (%P.f86) to %.loc5_4.4 = class_init (%.loc5_4.6) [symbolic = %P.val.loc5 (constants.%P.val.7d0)]
// CHECK:STDOUT:     %.loc5_4.8: init @P.%P (%P.f86) = converted %.loc5_4.3, %.loc5_4.7 [symbolic = %P.val.loc5 (constants.%P.val.7d0)]
// CHECK:STDOUT:     %.loc5_4.9: ref @P.%P (%P.f86) = temporary %.loc5_4.4, %.loc5_4.8 [symbolic = %.loc5_4.11 (constants.%.72a)]
// CHECK:STDOUT:     %.loc5_4.10: @P.%P (%P.f86) = acquire_value %.loc5_4.9 [symbolic = %P.val.loc5 (constants.%P.val.7d0)]
// CHECK:STDOUT:     %A: @P.%P (%P.f86) = wrapper_binding A, %.loc5_4.10
// CHECK:STDOUT:     %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:     %impl.elem0.loc7_1.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:     %bound_method.loc7_1.1: <bound method> = bound_method %int_1, %impl.elem0.loc7_1.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:     %specific_fn.loc7_1.1: <specific function> = specific_function %impl.elem0.loc7_1.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:     %bound_method.loc7_1.2: <bound method> = bound_method %int_1, %specific_fn.loc7_1.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc7: init %u1 = call %bound_method.loc7_1.2(%int_1) [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc7_1.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc7 [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc7_1.2: %u1 = converted %int_1, %.loc7_1.1 [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc7_1.3: %struct_type.discriminant = struct_literal (%.loc7_1.2) [concrete = constants.%struct.a79]
// CHECK:STDOUT:     %impl.elem0.loc7_1.2: %.952 = impl_witness_access constants.%Copy.impl_witness.334, element0 [concrete = constants.%UInt.as.Copy.impl.Op.d9c]
// CHECK:STDOUT:     %bound_method.loc7_1.3: <bound method> = bound_method %.loc7_1.2, %impl.elem0.loc7_1.2 [concrete = constants.%UInt.as.Copy.impl.Op.bound.332]
// CHECK:STDOUT:     %specific_fn.loc7_1.2: <specific function> = specific_function %impl.elem0.loc7_1.2, @UInt.as.Copy.impl.Op(constants.%int_1.5b8) [concrete = constants.%UInt.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:     %bound_method.loc7_1.4: <bound method> = bound_method %.loc7_1.2, %specific_fn.loc7_1.2 [concrete = constants.%bound_method.edd]
// CHECK:STDOUT:     %UInt.as.Copy.impl.Op.call.loc7: init %u1 = call %bound_method.loc7_1.4(%.loc7_1.2) [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc7_1.4: ref @P.%P (%P.f86) = temporary_storage
// CHECK:STDOUT:     %.loc7_1.5: ref %u1 = class_element_access %.loc7_1.4, element0
// CHECK:STDOUT:     %.loc7_1.6: init %u1 to %.loc7_1.5 = in_place_init %UInt.as.Copy.impl.Op.call.loc7 [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc7_1.7: init @P.%P (%P.f86) to %.loc7_1.4 = class_init (%.loc7_1.6) [symbolic = %P.val.loc7 (constants.%P.val.e49)]
// CHECK:STDOUT:     %.loc7_1.8: init @P.%P (%P.f86) = converted %.loc7_1.3, %.loc7_1.7 [symbolic = %P.val.loc7 (constants.%P.val.e49)]
// CHECK:STDOUT:     %.loc7_1.9: ref @P.%P (%P.f86) = temporary %.loc7_1.4, %.loc7_1.8 [symbolic = %.loc7_1.11 (constants.%.3aa)]
// CHECK:STDOUT:     %.loc7_1.10: @P.%P (%P.f86) = acquire_value %.loc7_1.9 [symbolic = %P.val.loc7 (constants.%P.val.e49)]
// CHECK:STDOUT:     %B: @P.%P (%P.f86) = wrapper_binding B, %.loc7_1.10
// CHECK:STDOUT:     complete_type_witness = %complete_type
// CHECK:STDOUT:
// CHECK:STDOUT:   !members:
// CHECK:STDOUT:     .Self = constants.%P.f86
// CHECK:STDOUT:     .A = %A
// CHECK:STDOUT:     .B = %B
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @F(%T.loc14_7.2: type) {
// CHECK:STDOUT:   %T.patt.loc14_7.2: %pattern_type.98f = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc14_7.2 (constants.%T.patt.d47)]
// CHECK:STDOUT:   %T.loc14_7.1: type = symbolic_binding T, 0 [symbolic = %T.loc14_7.1 (constants.%T.67d)]
// CHECK:STDOUT:   %P.loc14_21.1: type = class_type @P, @P(%T.loc14_7.1) [symbolic = %P.loc14_21.1 (constants.%P.f86)]
// CHECK:STDOUT:   %pattern_type: type = pattern_type %P.loc14_21.1 [symbolic = %pattern_type (constants.%pattern_type.6d3)]
// CHECK:STDOUT:   %x.param_patt.loc14_16.2: @F.%pattern_type (%pattern_type.6d3) = value_param_pattern [symbolic = %x.param_patt.loc14_16.2 (constants.%x.param_patt.038)]
// CHECK:STDOUT:   %x.patt.loc14_16.2: @F.%pattern_type (%pattern_type.6d3) = at_binding_pattern x, %x.param_patt.loc14_16.2 [symbolic = %x.patt.loc14_16.2 (constants.%x.patt.aa3)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete: <witness> = require_complete_type %P.loc14_21.1 [symbolic = %require_complete (constants.%require_complete.657)]
// CHECK:STDOUT:   %P.val.loc16: @F.%P.loc14_21.1 (%P.f86) = struct_value (constants.%int_0.1a7) [symbolic = %P.val.loc16 (constants.%P.val.7d0)]
// CHECK:STDOUT:   %P.val.loc17: @F.%P.loc14_21.1 (%P.f86) = struct_value (constants.%int_1.233) [symbolic = %P.val.loc17 (constants.%P.val.e49)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%x.param: @F.%P.loc14_21.1 (%P.f86)) -> out %return.param: %i32 {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %x.ref: @F.%P.loc14_21.1 (%P.f86) = name_ref x, %x
// CHECK:STDOUT:     name_binding_decl {
// CHECK:STDOUT:       %expr_patt.loc16: @F.%pattern_type (%pattern_type.6d3) = expr_pattern %A.ref in [concrete] {
// CHECK:STDOUT:         %.loc16_10.2: @F.%P.loc14_21.1 (%P.f86) = specific_constant @P.%.loc5_4.10, @P(constants.%T.67d) [symbolic = %P.val.loc16 (constants.%P.val.7d0)]
// CHECK:STDOUT:         %A.ref: @F.%P.loc14_21.1 (%P.f86) = name_ref A, %.loc16_10.2 [symbolic = %P.val.loc16 (constants.%P.val.7d0)]
// CHECK:STDOUT:       }
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %.loc16_10.1: @F.%P.loc14_21.1 (%P.f86) = splice_block %A.ref [symbolic = %P.val.loc16 (constants.%P.val.7d0)] {
// CHECK:STDOUT:       %.loc16_10.2: @F.%P.loc14_21.1 (%P.f86) = specific_constant @P.%.loc5_4.10, @P(constants.%T.67d) [symbolic = %P.val.loc16 (constants.%P.val.7d0)]
// CHECK:STDOUT:       %A.ref: @F.%P.loc14_21.1 (%P.f86) = name_ref A, %.loc16_10.2 [symbolic = %P.val.loc16 (constants.%P.val.7d0)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %int_0.loc16_13: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:     %impl.elem0.loc16_13.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:     %bound_method.loc16_13.1: <bound method> = bound_method %int_0.loc16_13, %impl.elem0.loc16_13.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:     %specific_fn.loc16_13.1: <specific function> = specific_function %impl.elem0.loc16_13.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:     %bound_method.loc16_13.2: <bound method> = bound_method %int_0.loc16_13, %specific_fn.loc16_13.1 [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16_13: init %u1 = call %bound_method.loc16_13.2(%int_0.loc16_13) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:     %.loc16_13.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16_13 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:     %.loc16_13.2: %u1 = converted %int_0.loc16_13, %.loc16_13.1 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:     %.loc16_13.3: ref %u1 = class_element_access %x.ref, element0
// CHECK:STDOUT:     %impl.elem0.loc16_13.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:     %bound_method.loc16_13.3: <bound method> = bound_method %.loc16_13.2, %impl.elem0.loc16_13.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.f34]
// CHECK:STDOUT:     %specific_fn.loc16_13.2: <specific function> = specific_function %impl.elem0.loc16_13.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:     %bound_method.loc16_13.4: <bound method> = bound_method %.loc16_13.2, %specific_fn.loc16_13.2 [concrete = constants.%bound_method.53a]
// CHECK:STDOUT:     %.loc16_13.4: %u1 = acquire_value %.loc16_13.3
// CHECK:STDOUT:     %UInt.as.EqWith.impl.Equal.call.loc16: init bool = call %bound_method.loc16_13.4(%.loc16_13.2, %.loc16_13.4)
// CHECK:STDOUT:     %.loc16_13.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc16
// CHECK:STDOUT:     %.loc16_13.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc16, %.loc16_13.5
// CHECK:STDOUT:     if %.loc16_13.6 br !match.case.then.loc16 else br !match.case.else.loc16
// CHECK:STDOUT:
// CHECK:STDOUT:   !match.case.then.loc16:
// CHECK:STDOUT:     %int_0.loc16_25: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:     %impl.elem0.loc16_26: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:     %bound_method.loc16_26.1: <bound method> = bound_method %int_0.loc16_25, %impl.elem0.loc16_26 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:     %specific_fn.loc16_26: <specific function> = specific_function %impl.elem0.loc16_26, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:     %bound_method.loc16_26.2: <bound method> = bound_method %int_0.loc16_25, %specific_fn.loc16_26 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16_26: init %i32 = call %bound_method.loc16_26.2(%int_0.loc16_25) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:     %.loc16_26: init %i32 = converted %int_0.loc16_25, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16_26 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:     return %.loc16_26
// CHECK:STDOUT:
// CHECK:STDOUT:   !match.case.else.loc16:
// CHECK:STDOUT:     name_binding_decl {
// CHECK:STDOUT:       %expr_patt.loc17: @F.%pattern_type (%pattern_type.6d3) = expr_pattern %B.ref in [concrete] {
// CHECK:STDOUT:         %.loc17_10.2: @F.%P.loc14_21.1 (%P.f86) = specific_constant @P.%.loc7_1.10, @P(constants.%T.67d) [symbolic = %P.val.loc17 (constants.%P.val.e49)]
// CHECK:STDOUT:         %B.ref: @F.%P.loc14_21.1 (%P.f86) = name_ref B, %.loc17_10.2 [symbolic = %P.val.loc17 (constants.%P.val.e49)]
// CHECK:STDOUT:       }
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %.loc17_10.1: @F.%P.loc14_21.1 (%P.f86) = splice_block %B.ref [symbolic = %P.val.loc17 (constants.%P.val.e49)] {
// CHECK:STDOUT:       %.loc17_10.2: @F.%P.loc14_21.1 (%P.f86) = specific_constant @P.%.loc7_1.10, @P(constants.%T.67d) [symbolic = %P.val.loc17 (constants.%P.val.e49)]
// CHECK:STDOUT:       %B.ref: @F.%P.loc14_21.1 (%P.f86) = name_ref B, %.loc17_10.2 [symbolic = %P.val.loc17 (constants.%P.val.e49)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %int_1.loc17_13: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:     %impl.elem0.loc17_13.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:     %bound_method.loc17_13.1: <bound method> = bound_method %int_1.loc17_13, %impl.elem0.loc17_13.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:     %specific_fn.loc17_13.1: <specific function> = specific_function %impl.elem0.loc17_13.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:     %bound_method.loc17_13.2: <bound method> = bound_method %int_1.loc17_13, %specific_fn.loc17_13.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc17_13: init %u1 = call %bound_method.loc17_13.2(%int_1.loc17_13) [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc17_13.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc17_13 [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc17_13.2: %u1 = converted %int_1.loc17_13, %.loc17_13.1 [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc17_13.3: ref %u1 = class_element_access %x.ref, element0
// CHECK:STDOUT:     %impl.elem0.loc17_13.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:     %bound_method.loc17_13.3: <bound method> = bound_method %.loc17_13.2, %impl.elem0.loc17_13.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.22c]
// CHECK:STDOUT:     %specific_fn.loc17_13.2: <specific function> = specific_function %impl.elem0.loc17_13.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:     %bound_method.loc17_13.4: <bound method> = bound_method %.loc17_13.2, %specific_fn.loc17_13.2 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:     %.loc17_13.4: %u1 = acquire_value %.loc17_13.3
// CHECK:STDOUT:     %UInt.as.EqWith.impl.Equal.call.loc17: init bool = call %bound_method.loc17_13.4(%.loc17_13.2, %.loc17_13.4)
// CHECK:STDOUT:     %.loc17_13.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc17
// CHECK:STDOUT:     %.loc17_13.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc17, %.loc17_13.5
// CHECK:STDOUT:     if %.loc17_13.6 br !match.case.then.loc17 else br !match.case.else.loc17
// CHECK:STDOUT:
// CHECK:STDOUT:   !match.case.then.loc17:
// CHECK:STDOUT:     %int_1.loc17_25: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:     %impl.elem0.loc17_26: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:     %bound_method.loc17_26.1: <bound method> = bound_method %int_1.loc17_25, %impl.elem0.loc17_26 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:     %specific_fn.loc17_26: <specific function> = specific_function %impl.elem0.loc17_26, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:     %bound_method.loc17_26.2: <bound method> = bound_method %int_1.loc17_25, %specific_fn.loc17_26 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc17_26: init %i32 = call %bound_method.loc17_26.2(%int_1.loc17_25) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:     %.loc17_26: init %i32 = converted %int_1.loc17_25, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc17_26 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:     return %.loc17_26
// CHECK:STDOUT:
// CHECK:STDOUT:   !match.case.else.loc17:
// CHECK:STDOUT:     br !match.done
// CHECK:STDOUT:
// CHECK:STDOUT:   !match.done:
// CHECK:STDOUT:     %int_1.loc19: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:     %impl.elem1: %.758 = impl_witness_access constants.%Negate.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:     %bound_method.loc19_10: <bound method> = bound_method %int_1.loc19, %impl.elem1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op.bound]
// CHECK:STDOUT:     %Core.IntLiteral.as.Negate.impl.Op.call: init Core.IntLiteral = call %bound_method.loc19_10(%int_1.loc19) [concrete = constants.%int_-1.638]
// CHECK:STDOUT:     %impl.elem0.loc19: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:     %bound_method.loc19_12.1: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %impl.elem0.loc19 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.65e]
// CHECK:STDOUT:     %specific_fn.loc19: <specific function> = specific_function %impl.elem0.loc19, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:     %bound_method.loc19_12.2: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %specific_fn.loc19 [concrete = constants.%bound_method.a65]
// CHECK:STDOUT:     %.loc19_10.1: Core.IntLiteral = value_of_initializer %Core.IntLiteral.as.Negate.impl.Op.call [concrete = constants.%int_-1.638]
// CHECK:STDOUT:     %.loc19_10.2: Core.IntLiteral = converted %Core.IntLiteral.as.Negate.impl.Op.call, %.loc19_10.1 [concrete = constants.%int_-1.638]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc19: init %i32 = call %bound_method.loc19_12.2(%.loc19_10.2) [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:     %.loc19_12: init %i32 = converted %Core.IntLiteral.as.Negate.impl.Op.call, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc19 [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:     return %.loc19_12
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Call(%p.param: %P.b38) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %F.ref: %F.type = name_ref F, file.%F.decl [concrete = constants.%F]
// CHECK:STDOUT:   %p.ref: %P.b38 = name_ref p, %p
// CHECK:STDOUT:   %F.specific_fn: <specific function> = specific_function %F.ref, @F(constants.%i32) [concrete = constants.%F.specific_fn]
// CHECK:STDOUT:   %F.call: init %i32 = call %F.specific_fn(%p.ref)
// CHECK:STDOUT:   return %F.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @P(constants.%T.67d) {
// CHECK:STDOUT:   %T.patt.loc4_11.2 => constants.%T.patt.d47
// CHECK:STDOUT:   %T.loc4_11.1 => constants.%T.67d
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %P => constants.%P.f86
// CHECK:STDOUT:   %require_complete => constants.%require_complete.657
// CHECK:STDOUT:   %P.val.loc5 => constants.%P.val.7d0
// CHECK:STDOUT:   %.loc5_4.11 => constants.%.72a
// CHECK:STDOUT:   %P.val.loc7 => constants.%P.val.e49
// CHECK:STDOUT:   %.loc7_1.11 => constants.%.3aa
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @F(constants.%T.67d) {
// CHECK:STDOUT:   %T.patt.loc14_7.2 => constants.%T.patt.d47
// CHECK:STDOUT:   %T.loc14_7.1 => constants.%T.67d
// CHECK:STDOUT:   %P.loc14_21.1 => constants.%P.f86
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.6d3
// CHECK:STDOUT:   %x.param_patt.loc14_16.2 => constants.%x.param_patt.038
// CHECK:STDOUT:   %x.patt.loc14_16.2 => constants.%x.patt.aa3
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @P(constants.%i32) {
// CHECK:STDOUT:   %T.patt.loc4_11.2 => constants.%T.patt.d47
// CHECK:STDOUT:   %T.loc4_11.1 => constants.%i32
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %P => constants.%P.b38
// CHECK:STDOUT:   %require_complete => constants.%complete_type.3a6
// CHECK:STDOUT:   %P.val.loc5 => constants.%P.val.0e9
// CHECK:STDOUT:   %.loc5_4.11 => constants.%.043
// CHECK:STDOUT:   %P.val.loc7 => constants.%P.val.61e
// CHECK:STDOUT:   %.loc7_1.11 => constants.%.91e
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @F(constants.%i32) {
// CHECK:STDOUT:   %T.patt.loc14_7.2 => constants.%T.patt.d47
// CHECK:STDOUT:   %T.loc14_7.1 => constants.%i32
// CHECK:STDOUT:   %P.loc14_21.1 => constants.%P.b38
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.e96
// CHECK:STDOUT:   %x.param_patt.loc14_16.2 => constants.%x.param_patt.755
// CHECK:STDOUT:   %x.patt.loc14_16.2 => constants.%x.patt.fe3
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete => constants.%complete_type.3a6
// CHECK:STDOUT:   %P.val.loc16 => constants.%P.val.0e9
// CHECK:STDOUT:   %P.val.loc17 => constants.%P.val.61e
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- use_imported.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %P.type: type = generic_class_type @P [concrete]
// CHECK:STDOUT:   %P.generic: %P.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %u1: type = class_type @UInt, @UInt(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %T.67d: type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %P.f86: type = class_type @P, @P(%T.67d) [symbolic]
// CHECK:STDOUT:   %int_1.233: %u1 = int_value 1 [concrete]
// CHECK:STDOUT:   %P.val.e49: %P.f86 = struct_value (%int_1.233) [symbolic]
// CHECK:STDOUT:   %int_0.1a7: %u1 = int_value 0 [concrete]
// CHECK:STDOUT:   %P.val.7d0: %P.f86 = struct_value (%int_0.1a7) [symbolic]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %P.b38: type = class_type @P, @P(%i32) [concrete]
// CHECK:STDOUT:   %pattern_type.e96: type = pattern_type %P.b38 [concrete]
// CHECK:STDOUT:   %p.param_patt: %pattern_type.e96 = value_param_pattern [concrete]
// CHECK:STDOUT:   %p.patt: %pattern_type.e96 = at_binding_pattern p, %p.param_patt [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %Classify.type: type = fn_type @Classify [concrete]
// CHECK:STDOUT:   %Classify: %Classify.type = struct_value () [concrete]
// CHECK:STDOUT:   %P.val.0e9: %P.b38 = struct_value (%int_0.1a7) [concrete]
// CHECK:STDOUT:   %P.val.61e: %P.b38 = struct_value (%int_1.233) [concrete]
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
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %bound_method.d7a: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
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
// CHECK:STDOUT:   %Construct.type: type = fn_type @Construct [concrete]
// CHECK:STDOUT:   %Construct: %Construct.type = struct_value () [concrete]
// CHECK:STDOUT:   %a.patt: %pattern_type.e96 = value_binding_pattern a [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Main.P: %P.type = import_ref Main//plib, P, loaded [concrete = constants.%P.generic]
// CHECK:STDOUT:   %Main.import_ref.08d: @P.%P (%P.f86) = import_ref Main//plib, loc4_4, loaded [symbolic = @P.%P.val.1 (constants.%P.val.7d0)]
// CHECK:STDOUT:   %Main.import_ref.04a: @P.%P (%P.f86) = import_ref Main//plib, loc6_1, loaded [symbolic = @P.%P.val.2 (constants.%P.val.e49)]
// CHECK:STDOUT:   %Core.import_ref.aa5: @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.170)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.f01 = impl_witness_table (%Core.import_ref.aa5), @Core.IntLiteral.as.ImplicitAs.impl.b68 [concrete]
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
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Classify.decl: %Classify.type = fn_decl @Classify [concrete = constants.%Classify] {
// CHECK:STDOUT:     %p.param_patt: %pattern_type.e96 = value_param_pattern [concrete = constants.%p.param_patt]
// CHECK:STDOUT:     %p.patt: %pattern_type.e96 = at_binding_pattern p, %p.param_patt [concrete = constants.%p.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc10_27 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc10_27: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc10_27: Core.Form = init_form %i32.loc10_27 [concrete = constants.%.795f]
// CHECK:STDOUT:     %p.param: %P.b38 = value_param call_param0
// CHECK:STDOUT:     %.loc10_21: type = splice_block %P [concrete = constants.%P.b38] {
// CHECK:STDOUT:       %P.ref: %P.type = name_ref P, imports.%Main.P [concrete = constants.%P.generic]
// CHECK:STDOUT:       %i32.loc10_18: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %P: type = class_type @P, @P(constants.%i32) [concrete = constants.%P.b38]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %p: %P.b38 = wrapper_binding p, %p.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Construct.decl: %Construct.type = fn_decl @Construct [concrete = constants.%Construct] {
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
// CHECK:STDOUT: fn @Classify(%p.param: %P.b38) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %p.ref: %P.b38 = name_ref p, %p
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt.loc12: %pattern_type.e96 = expr_pattern %A.ref in [concrete] {
// CHECK:STDOUT:       %.loc12_10.2: %P.b38 = specific_constant imports.%Main.import_ref.08d, @P(constants.%i32) [concrete = constants.%P.val.0e9]
// CHECK:STDOUT:       %A.ref: %P.b38 = name_ref A, %.loc12_10.2 [concrete = constants.%P.val.0e9]
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %.loc12_10.1: %P.b38 = splice_block %A.ref [concrete = constants.%P.val.0e9] {
// CHECK:STDOUT:     %.loc12_10.2: %P.b38 = specific_constant imports.%Main.import_ref.08d, @P(constants.%i32) [concrete = constants.%P.val.0e9]
// CHECK:STDOUT:     %A.ref: %P.b38 = name_ref A, %.loc12_10.2 [concrete = constants.%P.val.0e9]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_0.loc12_13: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc12_13.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc12_13.1: <bound method> = bound_method %int_0.loc12_13, %impl.elem0.loc12_13.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:   %specific_fn.loc12_13.1: <specific function> = specific_function %impl.elem0.loc12_13.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc12_13.2: <bound method> = bound_method %int_0.loc12_13, %specific_fn.loc12_13.1 [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc12_13: init %u1 = call %bound_method.loc12_13.2(%int_0.loc12_13) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc12_13.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc12_13 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc12_13.2: %u1 = converted %int_0.loc12_13, %.loc12_13.1 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc12_13.3: ref %u1 = class_element_access %p.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc12_13.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc12_13.3: <bound method> = bound_method %.loc12_13.2, %impl.elem0.loc12_13.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.f34]
// CHECK:STDOUT:   %specific_fn.loc12_13.2: <specific function> = specific_function %impl.elem0.loc12_13.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc12_13.4: <bound method> = bound_method %.loc12_13.2, %specific_fn.loc12_13.2 [concrete = constants.%bound_method.53a]
// CHECK:STDOUT:   %.loc12_13.4: %u1 = acquire_value %.loc12_13.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc12: init bool = call %bound_method.loc12_13.4(%.loc12_13.2, %.loc12_13.4)
// CHECK:STDOUT:   %.loc12_13.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc12
// CHECK:STDOUT:   %.loc12_13.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc12, %.loc12_13.5
// CHECK:STDOUT:   if %.loc12_13.6 br !match.case.then.loc12 else br !match.case.else.loc12
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc12:
// CHECK:STDOUT:   %int_0.loc12_25: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc12_26: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc12_26.1: <bound method> = bound_method %int_0.loc12_25, %impl.elem0.loc12_26 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc12_26: <specific function> = specific_function %impl.elem0.loc12_26, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc12_26.2: <bound method> = bound_method %int_0.loc12_25, %specific_fn.loc12_26 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc12_26: init %i32 = call %bound_method.loc12_26.2(%int_0.loc12_25) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc12_26: init %i32 = converted %int_0.loc12_25, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc12_26 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   return %.loc12_26
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc12:
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt.loc13: %pattern_type.e96 = expr_pattern %B.ref in [concrete] {
// CHECK:STDOUT:       %.loc13_10.2: %P.b38 = specific_constant imports.%Main.import_ref.04a, @P(constants.%i32) [concrete = constants.%P.val.61e]
// CHECK:STDOUT:       %B.ref: %P.b38 = name_ref B, %.loc13_10.2 [concrete = constants.%P.val.61e]
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %.loc13_10.1: %P.b38 = splice_block %B.ref [concrete = constants.%P.val.61e] {
// CHECK:STDOUT:     %.loc13_10.2: %P.b38 = specific_constant imports.%Main.import_ref.04a, @P(constants.%i32) [concrete = constants.%P.val.61e]
// CHECK:STDOUT:     %B.ref: %P.b38 = name_ref B, %.loc13_10.2 [concrete = constants.%P.val.61e]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_1.loc13_13: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc13_13.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc13_13.1: <bound method> = bound_method %int_1.loc13_13, %impl.elem0.loc13_13.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc13_13.1: <specific function> = specific_function %impl.elem0.loc13_13.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc13_13.2: <bound method> = bound_method %int_1.loc13_13, %specific_fn.loc13_13.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13_13: init %u1 = call %bound_method.loc13_13.2(%int_1.loc13_13) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc13_13.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13_13 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc13_13.2: %u1 = converted %int_1.loc13_13, %.loc13_13.1 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc13_13.3: ref %u1 = class_element_access %p.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc13_13.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc13_13.3: <bound method> = bound_method %.loc13_13.2, %impl.elem0.loc13_13.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.22c]
// CHECK:STDOUT:   %specific_fn.loc13_13.2: <specific function> = specific_function %impl.elem0.loc13_13.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc13_13.4: <bound method> = bound_method %.loc13_13.2, %specific_fn.loc13_13.2 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc13_13.4: %u1 = acquire_value %.loc13_13.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc13: init bool = call %bound_method.loc13_13.4(%.loc13_13.2, %.loc13_13.4)
// CHECK:STDOUT:   %.loc13_13.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc13
// CHECK:STDOUT:   %.loc13_13.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc13, %.loc13_13.5
// CHECK:STDOUT:   if %.loc13_13.6 br !match.case.then.loc13 else br !match.case.else.loc13
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc13:
// CHECK:STDOUT:   %int_1.loc13_25: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc13_26: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc13_26.1: <bound method> = bound_method %int_1.loc13_25, %impl.elem0.loc13_26 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc13_26: <specific function> = specific_function %impl.elem0.loc13_26, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc13_26.2: <bound method> = bound_method %int_1.loc13_25, %specific_fn.loc13_26 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13_26: init %i32 = call %bound_method.loc13_26.2(%int_1.loc13_25) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc13_26: init %i32 = converted %int_1.loc13_25, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13_26 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   return %.loc13_26
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc13:
// CHECK:STDOUT:   br !match.done
// CHECK:STDOUT:
// CHECK:STDOUT: !match.done:
// CHECK:STDOUT:   %int_1.loc15: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem1: %.758 = impl_witness_access constants.%Negate.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %bound_method.loc15_10: <bound method> = bound_method %int_1.loc15, %impl.elem1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op.bound]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.call: init Core.IntLiteral = call %bound_method.loc15_10(%int_1.loc15) [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %impl.elem0.loc15: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc15_12.1: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %impl.elem0.loc15 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.65e]
// CHECK:STDOUT:   %specific_fn.loc15: <specific function> = specific_function %impl.elem0.loc15, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc15_12.2: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %specific_fn.loc15 [concrete = constants.%bound_method.a65]
// CHECK:STDOUT:   %.loc15_10.1: Core.IntLiteral = value_of_initializer %Core.IntLiteral.as.Negate.impl.Op.call [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %.loc15_10.2: Core.IntLiteral = converted %Core.IntLiteral.as.Negate.impl.Op.call, %.loc15_10.1 [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc15: init %i32 = call %bound_method.loc15_12.2(%.loc15_10.2) [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   %.loc15_12: init %i32 = converted %Core.IntLiteral.as.Negate.impl.Op.call, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc15 [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   return %.loc15_12
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Construct() -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %P.ref.loc19_19: %P.type = name_ref P, imports.%Main.P [concrete = constants.%P.generic]
// CHECK:STDOUT:   %i32.loc19_21: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %P.loc19_24: type = class_type @P, @P(constants.%i32) [concrete = constants.%P.b38]
// CHECK:STDOUT:   %.loc19_25: %P.b38 = specific_constant imports.%Main.import_ref.08d, @P(constants.%i32) [concrete = constants.%P.val.0e9]
// CHECK:STDOUT:   %A.ref: %P.b38 = name_ref A, %.loc19_25 [concrete = constants.%P.val.0e9]
// CHECK:STDOUT:   %.loc19_15: type = splice_block %P.loc19_15 [concrete = constants.%P.b38] {
// CHECK:STDOUT:     %P.ref.loc19_10: %P.type = name_ref P, imports.%Main.P [concrete = constants.%P.generic]
// CHECK:STDOUT:     %i32.loc19_12: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %P.loc19_15: type = class_type @P, @P(constants.%i32) [concrete = constants.%P.b38]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %a: %P.b38 = wrapper_binding a, %A.ref
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %a.patt: %pattern_type.e96 = value_binding_pattern a [concrete = constants.%a.patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Classify.ref: %Classify.type = name_ref Classify, file.%Classify.decl [concrete = constants.%Classify]
// CHECK:STDOUT:   %a.ref: %P.b38 = name_ref a, %a
// CHECK:STDOUT:   %Classify.call: init %i32 = call %Classify.ref(%a.ref)
// CHECK:STDOUT:   return %Classify.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- single_alternative_specific.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %.Self.frozen: %type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %pattern_type.98f: type = pattern_type type [concrete]
// CHECK:STDOUT:   %T.patt: %pattern_type.98f = symbolic_binding_pattern T, 0 [symbolic]
// CHECK:STDOUT:   %T: type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %Always.type: type = generic_class_type @Always [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %Always.generic: %Always.type = struct_value () [concrete]
// CHECK:STDOUT:   %Always.7a1: type = class_type @Always, @Always(%T) [symbolic]
// CHECK:STDOUT:   %struct_type.discriminant: type = struct_type {.discriminant: %empty_tuple.type} [concrete]
// CHECK:STDOUT:   %complete_type.a0b: <witness> = complete_type_witness %struct_type.discriminant [concrete]
// CHECK:STDOUT:   %empty_tuple: %empty_tuple.type = tuple_value () [concrete]
// CHECK:STDOUT:   %struct: %struct_type.discriminant = struct_value (%empty_tuple) [concrete]
// CHECK:STDOUT:   %require_complete.a19: <witness> = require_complete_type %Always.7a1 [symbolic]
// CHECK:STDOUT:   %Always.val.158: %Always.7a1 = struct_value (%empty_tuple) [symbolic]
// CHECK:STDOUT:   %.4eb: ref %Always.7a1 = temporary invalid, %Always.val.158 [symbolic]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %Always.413: type = class_type @Always, @Always(%i32) [concrete]
// CHECK:STDOUT:   %pattern_type.b4f: type = pattern_type %Always.413 [concrete]
// CHECK:STDOUT:   %a.param_patt: %pattern_type.b4f = value_param_pattern [concrete]
// CHECK:STDOUT:   %a.patt: %pattern_type.b4f = at_binding_pattern a, %a.param_patt [concrete]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT:   %Always.val.792: %Always.413 = struct_value (%empty_tuple) [concrete]
// CHECK:STDOUT:   %.d3a: ref %Always.413 = temporary invalid, %Always.val.792 [concrete]
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Always.decl: %Always.type = class_decl @Always [concrete = constants.%Always.generic] {
// CHECK:STDOUT:     %T.patt.loc4_16.1: %pattern_type.98f = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc4_16.2 (constants.%T.patt)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc4_18.1: type = splice_block %.loc4_18.2 [concrete = type] {
// CHECK:STDOUT:       %.Self.frozen: %type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %.loc4_18.2: type = type_literal type [concrete = type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc4_16.2: type = symbolic_binding T, 0 [symbolic = %T.loc4_16.1 (constants.%T)]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %F.decl: %F.type = fn_decl @F [concrete = constants.%F] {
// CHECK:STDOUT:     %a.param_patt: %pattern_type.b4f = value_param_pattern [concrete = constants.%a.param_patt]
// CHECK:STDOUT:     %a.patt: %pattern_type.b4f = at_binding_pattern a, %a.param_patt [concrete = constants.%a.patt]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %a.param: %Always.413 = value_param call_param0
// CHECK:STDOUT:     %.loc13: type = splice_block %Always [concrete = constants.%Always.413] {
// CHECK:STDOUT:       %Always.ref: %Always.type = name_ref Always, file.%Always.decl [concrete = constants.%Always.generic]
// CHECK:STDOUT:       %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %Always: type = class_type @Always, @Always(constants.%i32) [concrete = constants.%Always.413]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %a: %Always.413 = wrapper_binding a, %a.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic class @Always(%T.loc4_16.2: type) {
// CHECK:STDOUT:   %T.patt.loc4_16.2: %pattern_type.98f = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc4_16.2 (constants.%T.patt)]
// CHECK:STDOUT:   %T.loc4_16.1: type = symbolic_binding T, 0 [symbolic = %T.loc4_16.1 (constants.%T)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %Always: type = class_type @Always, @Always(%T.loc4_16.1) [symbolic = %Always (constants.%Always.7a1)]
// CHECK:STDOUT:   %require_complete: <witness> = require_complete_type %Always [symbolic = %require_complete (constants.%require_complete.a19)]
// CHECK:STDOUT:   %Always.val: @Always.%Always (%Always.7a1) = struct_value (constants.%empty_tuple) [symbolic = %Always.val (constants.%Always.val.158)]
// CHECK:STDOUT:   %.loc6_1.13: ref @Always.%Always (%Always.7a1) = temporary invalid, %Always.val [symbolic = %.loc6_1.13 (constants.%.4eb)]
// CHECK:STDOUT:
// CHECK:STDOUT:   class {
// CHECK:STDOUT:     %complete_type: <witness> = complete_type_witness constants.%struct_type.discriminant [concrete = constants.%complete_type.a0b]
// CHECK:STDOUT:     %.loc6_1.1: %empty_tuple.type = tuple_literal () [concrete = constants.%empty_tuple]
// CHECK:STDOUT:     %empty_tuple: %empty_tuple.type = tuple_value () [concrete = constants.%empty_tuple]
// CHECK:STDOUT:     %.loc6_1.2: %empty_tuple.type = converted %.loc6_1.1, %empty_tuple [concrete = constants.%empty_tuple]
// CHECK:STDOUT:     %.loc6_1.3: %struct_type.discriminant = struct_literal (%.loc6_1.2) [concrete = constants.%struct]
// CHECK:STDOUT:     %.loc6_1.4: ref @Always.%Always (%Always.7a1) = temporary_storage
// CHECK:STDOUT:     %.loc6_1.5: ref %empty_tuple.type = class_element_access %.loc6_1.4, element0
// CHECK:STDOUT:     %.loc6_1.6: init %empty_tuple.type to %.loc6_1.5 = tuple_init () [concrete = constants.%empty_tuple]
// CHECK:STDOUT:     %.loc6_1.7: init %empty_tuple.type = converted %.loc6_1.2, %.loc6_1.6 [concrete = constants.%empty_tuple]
// CHECK:STDOUT:     %.loc6_1.8: init %empty_tuple.type to %.loc6_1.5 = in_place_init %.loc6_1.7 [concrete = constants.%empty_tuple]
// CHECK:STDOUT:     %.loc6_1.9: init @Always.%Always (%Always.7a1) to %.loc6_1.4 = class_init (%.loc6_1.8) [symbolic = %Always.val (constants.%Always.val.158)]
// CHECK:STDOUT:     %.loc6_1.10: init @Always.%Always (%Always.7a1) = converted %.loc6_1.3, %.loc6_1.9 [symbolic = %Always.val (constants.%Always.val.158)]
// CHECK:STDOUT:     %.loc6_1.11: ref @Always.%Always (%Always.7a1) = temporary %.loc6_1.4, %.loc6_1.10 [symbolic = %.loc6_1.13 (constants.%.4eb)]
// CHECK:STDOUT:     %.loc6_1.12: @Always.%Always (%Always.7a1) = acquire_value %.loc6_1.11 [symbolic = %Always.val (constants.%Always.val.158)]
// CHECK:STDOUT:     %Sunny: @Always.%Always (%Always.7a1) = wrapper_binding Sunny, %.loc6_1.12
// CHECK:STDOUT:     complete_type_witness = %complete_type
// CHECK:STDOUT:
// CHECK:STDOUT:   !members:
// CHECK:STDOUT:     .Self = constants.%Always.7a1
// CHECK:STDOUT:     .Sunny = %Sunny
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @F(%a.param: %Always.413) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %a.ref: %Always.413 = name_ref a, %a
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt: %pattern_type.b4f = expr_pattern %Sunny.ref in [concrete] {
// CHECK:STDOUT:       %.loc15_10.2: %Always.413 = specific_constant @Always.%.loc6_1.12, @Always(constants.%i32) [concrete = constants.%Always.val.792]
// CHECK:STDOUT:       %Sunny.ref: %Always.413 = name_ref Sunny, %.loc15_10.2 [concrete = constants.%Always.val.792]
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %.loc15_10.1: %Always.413 = splice_block %Sunny.ref [concrete = constants.%Always.val.792] {
// CHECK:STDOUT:     %.loc15_10.2: %Always.413 = specific_constant @Always.%.loc6_1.12, @Always(constants.%i32) [concrete = constants.%Always.val.792]
// CHECK:STDOUT:     %Sunny.ref: %Always.413 = name_ref Sunny, %.loc15_10.2 [concrete = constants.%Always.val.792]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:   if %true br !match.case.then else br !match.case.else
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then:
// CHECK:STDOUT:   return
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else:
// CHECK:STDOUT:   br !match.done
// CHECK:STDOUT:
// CHECK:STDOUT: !match.done:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Always(constants.%T) {
// CHECK:STDOUT:   %T.patt.loc4_16.2 => constants.%T.patt
// CHECK:STDOUT:   %T.loc4_16.1 => constants.%T
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Always(constants.%i32) {
// CHECK:STDOUT:   %T.patt.loc4_16.2 => constants.%T.patt
// CHECK:STDOUT:   %T.loc4_16.1 => constants.%i32
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %Always => constants.%Always.413
// CHECK:STDOUT:   %require_complete => constants.%complete_type.a0b
// CHECK:STDOUT:   %Always.val => constants.%Always.val.792
// CHECK:STDOUT:   %.loc6_1.13 => constants.%.d3a
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- empty_choice_specific.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %.Self.frozen: %type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %pattern_type.98f: type = pattern_type type [concrete]
// CHECK:STDOUT:   %T.patt: %pattern_type.98f = symbolic_binding_pattern T, 0 [symbolic]
// CHECK:STDOUT:   %T: type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %Never.type: type = generic_class_type @Never [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %Never.generic: %Never.type = struct_value () [concrete]
// CHECK:STDOUT:   %Never.8b0: type = class_type @Never, @Never(%T) [symbolic]
// CHECK:STDOUT:   %struct_type.discriminant: type = struct_type {.discriminant: %empty_tuple.type} [concrete]
// CHECK:STDOUT:   %complete_type.a0b: <witness> = complete_type_witness %struct_type.discriminant [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %Never.0c1: type = class_type @Never, @Never(%i32) [concrete]
// CHECK:STDOUT:   %pattern_type.790: type = pattern_type %Never.0c1 [concrete]
// CHECK:STDOUT:   %n.param_patt: %pattern_type.790 = value_param_pattern [concrete]
// CHECK:STDOUT:   %n.patt: %pattern_type.790 = at_binding_pattern n, %n.param_patt [concrete]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Never.decl: %Never.type = class_decl @Never [concrete = constants.%Never.generic] {
// CHECK:STDOUT:     %T.patt.loc4_15.1: %pattern_type.98f = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc4_15.2 (constants.%T.patt)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc4_17.1: type = splice_block %.loc4_17.2 [concrete = type] {
// CHECK:STDOUT:       %.Self.frozen: %type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %.loc4_17.2: type = type_literal type [concrete = type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc4_15.2: type = symbolic_binding T, 0 [symbolic = %T.loc4_15.1 (constants.%T)]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %F.decl: %F.type = fn_decl @F [concrete = constants.%F] {
// CHECK:STDOUT:     %n.param_patt: %pattern_type.790 = value_param_pattern [concrete = constants.%n.param_patt]
// CHECK:STDOUT:     %n.patt: %pattern_type.790 = at_binding_pattern n, %n.param_patt [concrete = constants.%n.patt]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %n.param: %Never.0c1 = value_param call_param0
// CHECK:STDOUT:     %.loc9: type = splice_block %Never [concrete = constants.%Never.0c1] {
// CHECK:STDOUT:       %Never.ref: %Never.type = name_ref Never, file.%Never.decl [concrete = constants.%Never.generic]
// CHECK:STDOUT:       %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %Never: type = class_type @Never, @Never(constants.%i32) [concrete = constants.%Never.0c1]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %n: %Never.0c1 = wrapper_binding n, %n.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic class @Never(%T.loc4_15.2: type) {
// CHECK:STDOUT:   %T.patt.loc4_15.2: %pattern_type.98f = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc4_15.2 (constants.%T.patt)]
// CHECK:STDOUT:   %T.loc4_15.1: type = symbolic_binding T, 0 [symbolic = %T.loc4_15.1 (constants.%T)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:
// CHECK:STDOUT:   class {
// CHECK:STDOUT:     %complete_type: <witness> = complete_type_witness constants.%struct_type.discriminant [concrete = constants.%complete_type.a0b]
// CHECK:STDOUT:     complete_type_witness = %complete_type
// CHECK:STDOUT:
// CHECK:STDOUT:   !members:
// CHECK:STDOUT:     .Self = constants.%Never.8b0
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @F(%n.param: %Never.0c1) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %n.ref: %Never.0c1 = name_ref n, %n
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Never(constants.%T) {
// CHECK:STDOUT:   %T.patt.loc4_15.2 => constants.%T.patt
// CHECK:STDOUT:   %T.loc4_15.1 => constants.%T
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Never(constants.%i32) {
// CHECK:STDOUT:   %T.patt.loc4_15.2 => constants.%T.patt
// CHECK:STDOUT:   %T.loc4_15.1 => constants.%i32
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT: }
// CHECK:STDOUT:
