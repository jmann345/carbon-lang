// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/generic/template/match_choice.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/generic/template/match_choice.carbon

// Refutable patterns on a template-dependent choice value (TP-1 round 10,
// X-1). A generic choice applied to a template parameter is a class type in
// the definition (D-TP-11), and so is a choice declared in a class template;
// the scrutinee gate admits it as it admits a checked generic's choice, and
// `Core.Int(N)` for a template `N` as it admits a checked `Int(N)`. An
// alternative pattern's name is resolved in the definition
// (`PerformAlternativeAccess`, refutable_binding.cpp), so a payload-free
// alternative's arm compares discriminants as for a checked generic; the
// deferred access it replaced left a splice that stopped the compiler at
// pattern_match.cpp:1409. Operations on payloads of the template parameter's
// type run on instantiation. A scrutinee whose type is not known in the
// definition, such as the template parameter itself (proposal 2200's `match`
// on a dependent value, TR-13), stays a `semantics TODO` (W-252).

// --- designator_arm.carbon
library "[[@TEST_NAME]]";

choice Opt(T: type) {
  Some(value: T),
  None
}

//@dump-sem-ir-begin
fn Conv[template T: type](unused t: T) -> i32 {
  let s: Opt(T) = Opt(T).None;
  match (s) {
    case .Some(unused n: T) => { return 1; }
    case .None => { return 0; }
  }
  return -1;
}
//@dump-sem-ir-end

fn Use() -> i32 {
  let one: i32 = 1;
  return Conv(one);
}

// --- designator_arm_exhaustive.carbon
library "[[@TEST_NAME]]";

choice Opt(T: type) {
  Some(value: T),
  None
}

// Both alternatives are covered, so no `default` arm is required.
fn Count[template T: type](s: Opt(T)) -> i32 {
  match (s) {
    case .None => { return 0; }
    case .Some(_: T) => { return 1; }
  }
  return -1;
}

fn Use(a: Opt(i32), b: Opt(bool)) -> i32 {
  return Count(a) + Count(b);
}

// --- class_template_choice.carbon
library "[[@TEST_NAME]]";

// A choice declared in a class template is template-dependent without
// D-TP-11; trunk stops at the same check for its `.B` arm.
class Outer(template T: type) {
  choice C {
    A(n: T),
    B
  }

  //@dump-sem-ir-begin
  fn Get(t: T, full: bool) -> i32 {
    var c: C = C.B;
    if (full) {
      c = C.A(t);
    }
    match (c) {
      case .B => { return 0; }
      case .A(_: T) => { return 1; }
    }
    return -1;
  }
  //@dump-sem-ir-end
}

fn Use() -> i32 {
  let x: i32 = 1;
  return Outer(i32).Get(x, true);
}

// --- value_param.carbon
library "[[@TEST_NAME]]";

choice V(N: i32) {
  A,
  B
}

fn Kind(template N: i32) -> i32 {
  let v: V(N) = V(N).B;
  match (v) {
    case .A => { return 1; }
    case .B => { return 2; }
  }
  return -1;
}

fn Use() -> i32 {
  return Kind(3);
}

// --- nested_match.carbon
library "[[@TEST_NAME]]";

choice Opt(T: type) {
  Some(value: T),
  None
}

fn Inner[template T: type](s: Opt(T), k: i32) -> i32 {
  match (k) {
    case 1 => {
      match (s) {
        case .None => { return 2; }
        default => { return 3; }
      }
    }
    default => { return 4; }
  }
}

fn Use(s: Opt(i64)) -> i32 {
  return Inner(s, 1);
}

// --- guard.carbon
library "[[@TEST_NAME]]";

choice Opt(T: type) {
  Some(value: T),
  None
}

fn Big[template T: type](t: T) -> i32 {
  let s: Opt(T) = Opt(T).Some(t);
  match (s) {
    case .Some(n: T) if (n > 2) => { return 1; }
    case .Some(_: T) => { return 2; }
    case .None => { return 0; }
  }
  return -1;
}

fn Use() -> i32 {
  let a: i32 = 5;
  let b: i64 = 0;
  return Big(a) + Big(b);
}

// --- pattern_forms.carbon
library "[[@TEST_NAME]]";

choice Opt(T: type) {
  Some(value: T),
  None
}

fn HasValue[template T: type](s: Opt(T)) -> bool {
  if (let .Some(_: T) = s) {
    return true;
  }
  return false;
}

fn IsNone[template T: type](s: Opt(T)) -> bool {
  if (let .None = s) {
    return true;
  }
  return false;
}

fn Unwrap[template T: type](s: Opt(T), d: T) -> T {
  let .Some(n: T) = s else { return d; }
  return n;
}

fn Loop[template T: type](s: Opt(T)) -> i32 {
  while (let .Some(_: T) = s) {
    return 1;
  }
  return 0;
}

fn Use(s: Opt(i32), d: i32) -> i32 {
  if (HasValue(s) and not IsNone(s)) {
    return Unwrap(s, d) + Loop(s);
  }
  return d;
}

// --- int_scrutinee.carbon
library "[[@TEST_NAME]]";

fn Kind[template N: Core.IntLiteral](x: Core.Int(N)) -> i32 {
  match (x) {
    case 1 => { return 1; }
    case -1 => { return 2; }
    case n: Core.Int(N) => { return (n as i32) + 10; }
  }
  return 0;
}

fn IsFour[template N: Core.IntLiteral](x: Core.Int(N)) -> bool {
  if (let 4 = x) {
    return true;
  }
  return false;
}

fn Use(a: i8, b: i64) -> i32 {
  if (IsFour(a)) {
    return Kind(a);
  }
  return Kind(b);
}

// --- fail_unknown_alternative.carbon
library "[[@TEST_NAME]]";

choice Opt(T: type) {
  Some(value: T),
  None
}

// Diagnosed in the definition, as for a checked generic, though no call
// instantiates the functions.
fn InMatch[template T: type](s: Opt(T)) -> i32 {
  match (s) {
    // CHECK:STDERR: fail_unknown_alternative.carbon:[[@LINE+4]]:10: error: member name `Nope` not found in `Opt(T)` [MemberNameNotFoundInSpecificScope]
    // CHECK:STDERR:     case .Nope => { return 0; }
    // CHECK:STDERR:          ^~~~~
    // CHECK:STDERR:
    case .Nope => { return 0; }
    default => { return 1; }
  }
}

fn InIfLet[template T: type](s: Opt(T)) -> i32 {
  // CHECK:STDERR: fail_unknown_alternative.carbon:[[@LINE+4]]:11: error: member name `Nope` not found in `Opt(T)` [MemberNameNotFoundInSpecificScope]
  // CHECK:STDERR:   if (let .Nope = s) {
  // CHECK:STDERR:           ^~~~~
  // CHECK:STDERR:
  if (let .Nope = s) {
    return 0;
  }
  return 1;
}

fn InLetElse[template T: type](s: Opt(T)) -> i32 {
  // CHECK:STDERR: fail_unknown_alternative.carbon:[[@LINE+4]]:7: error: member name `Nope` not found in `Opt(T)` [MemberNameNotFoundInSpecificScope]
  // CHECK:STDERR:   let .Nope = s else { return 0; }
  // CHECK:STDERR:       ^~~~~
  // CHECK:STDERR:
  let .Nope = s else { return 0; }
  return 1;
}

// --- fail_nonexhaustive.carbon
library "[[@TEST_NAME]]";

choice Opt(T: type) {
  Some(value: T),
  None
}

fn Conv[template T: type](s: Opt(T)) -> i32 {
  // CHECK:STDERR: fail_nonexhaustive.carbon:[[@LINE+4]]:3: error: `match` on choice `Opt(T)` has no `default` arm and does not cover alternative `.Some` [MatchNonexhaustive]
  // CHECK:STDERR:   match (s) {
  // CHECK:STDERR:   ^~~~~~~~~~~
  // CHECK:STDERR:
  match (s) {
    case .None => { return 0; }
  }
  return 1;
}

// --- fail_never_matches.carbon
library "[[@TEST_NAME]]";

choice Opt(T: type) {
  Some(value: T),
  None
}

fn Conv[template T: type](s: Opt(T)) -> i32 {
  match (s) {
    case .None => { return 0; }
    case .Some(_: T) => { return 1; }
    // CHECK:STDERR: fail_never_matches.carbon:[[@LINE+7]]:5: error: `case` pattern never matches; every value it can match is matched by a prior arm [MatchCaseNeverMatches]
    // CHECK:STDERR:     case .None => { return 2; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR: fail_never_matches.carbon:[[@LINE-5]]:5: note: pattern is fully covered by this prior arm [MatchCaseNeverMatchesPriorArm]
    // CHECK:STDERR:     case .None => { return 0; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR:
    case .None => { return 2; }
  }
  return 3;
}

// --- fail_int_never_matches.carbon
library "[[@TEST_NAME]]";

fn Kind[template N: Core.IntLiteral](x: Core.Int(N)) -> i32 {
  match (x) {
    case 1 => { return 1; }
    // CHECK:STDERR: fail_int_never_matches.carbon:[[@LINE+7]]:5: error: `case` pattern never matches; every value it can match is matched by a prior arm [MatchCaseNeverMatches]
    // CHECK:STDERR:     case 1 => { return 2; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR: fail_int_never_matches.carbon:[[@LINE-4]]:5: note: pattern is fully covered by this prior arm [MatchCaseNeverMatchesPriorArm]
    // CHECK:STDERR:     case 1 => { return 1; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR:
    case 1 => { return 2; }
    default => { return 0; }
  }
}

// --- fail_int_literal_out_of_range_on_instantiation.carbon
library "[[@TEST_NAME]]";

fn Kind[template N: Core.IntLiteral](x: Core.Int(N)) -> i32 {
  match (x) {
    case 300 => { return 1; }
    default => { return 0; }
  }
}

fn Use(a: i8) -> i32 {
  // CHECK:STDERR: fail_int_literal_out_of_range_on_instantiation.carbon:[[@LINE+8]]:10: error: unable to monomorphize specific `Kind(8)` [ResolvingSpecificHere]
  // CHECK:STDERR:   return Kind(a);
  // CHECK:STDERR:          ^~~~
  // CHECK:STDERR: fail_int_literal_out_of_range_on_instantiation.carbon: note: integer value 300 too large for type `i8` [IntTooLargeForType]
  // CHECK:STDERR: {{.*}}/prelude/types/int.carbon:124:12: note: initializing function parameter [InCallToFunctionParam]
  // CHECK:STDERR:   fn Equal(self: Int(N), other: Int(N)) -> bool = "int.eq";
  // CHECK:STDERR:            ^~~~~~~~~~~~
  // CHECK:STDERR:
  return Kind(a);
}

// --- fail_payload_literal_on_instantiation.carbon
library "[[@TEST_NAME]]";

choice Opt(T: type) {
  Some(value: T),
  None
}

fn Conv[template T: type](t: T) -> i32 {
  let s: Opt(T) = Opt(T).Some(t);
  match (s) {
    case .Some(1) => { return 1; }
    default => { return 0; }
  }
}

fn Use() -> i32 {
  // CHECK:STDERR: fail_payload_literal_on_instantiation.carbon:[[@LINE+7]]:10: error: unable to monomorphize specific `Conv(bool)` [ResolvingSpecificHere]
  // CHECK:STDERR:   return Conv(true);
  // CHECK:STDERR:          ^~~~
  // CHECK:STDERR: fail_payload_literal_on_instantiation.carbon:[[@LINE-9]]:5: note: cannot access member of interface `Core.EqWith(bool)` in type `Core.IntLiteral` that does not implement that interface [MissingImplInMemberAccess]
  // CHECK:STDERR:     case .Some(1) => { return 1; }
  // CHECK:STDERR:     ^~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  return Conv(true);
}

// --- fail_guard_on_instantiation.carbon
library "[[@TEST_NAME]]";

choice Opt(T: type) {
  Some(value: T),
  None
}

fn Conv[template T: type](t: T) -> i32 {
  let s: Opt(T) = Opt(T).Some(t);
  match (s) {
    case .Some(n: T) if (n.Valid()) => { return 1; }
    default => { return 0; }
  }
}

fn Use() -> i32 {
  let a: i32 = 3;
  // CHECK:STDERR: fail_guard_on_instantiation.carbon:[[@LINE+7]]:10: error: unable to monomorphize specific `Conv(i32)` [ResolvingSpecificHere]
  // CHECK:STDERR:   return Conv(a);
  // CHECK:STDERR:          ^~~~
  // CHECK:STDERR: fail_guard_on_instantiation.carbon:[[@LINE-10]]:26: note: member name `Valid` not found in `i32` [MemberNameNotFoundInSpecificScope]
  // CHECK:STDERR:     case .Some(n: T) if (n.Valid()) => { return 1; }
  // CHECK:STDERR:                          ^~~~~~~
  // CHECK:STDERR:
  return Conv(a);
}

// --- fail_payload_not_trivial_on_instantiation.carbon
library "[[@TEST_NAME]]";

choice Opt(T: type) {
  Some(value: T),
  None
}

class P {
  var x: i32;
}

fn Conv[template T: type](t: T) -> i32 {
  let s: Opt(T) = Opt(T).Some(t);
  match (s) {
    case .Some(_: T) => { return 1; }
    case .None => { return 0; }
  }
  return -1;
}

fn Use() -> i32 {
  let p: P = {.x = 3};
  // CHECK:STDERR: fail_payload_not_trivial_on_instantiation.carbon:[[@LINE+22]]:10: error: unable to monomorphize specific `Conv(P)` [ResolvingSpecificHere]
  // CHECK:STDERR:   return Conv(p);
  // CHECK:STDERR:          ^~~~
  // CHECK:STDERR: fail_payload_not_trivial_on_instantiation.carbon:[[@LINE-13]]:10: note: `Opt(T)` evaluates to incomplete type `Opt(P)` [IncompleteTypeInMonomorphization]
  // CHECK:STDERR:   let s: Opt(T) = Opt(T).Some(t);
  // CHECK:STDERR:          ^~~~~~
  // CHECK:STDERR: fail_payload_not_trivial_on_instantiation.carbon:[[@LINE-26]]:1: note: choice alternative payload type `P` is not trivially copyable and destructible in this specific [ChoicePayloadNotTrivialInSpecific]
  // CHECK:STDERR: choice Opt(T: type) {
  // CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  // CHECK:STDERR: fail_payload_not_trivial_on_instantiation.carbon:[[@LINE+12]]:10: error: unable to monomorphize specific `Conv(P)` [ResolvingSpecificHere]
  // CHECK:STDERR:   return Conv(p);
  // CHECK:STDERR:          ^~~~
  // CHECK:STDERR: fail_payload_not_trivial_on_instantiation.carbon:[[@LINE-21]]:5: note: choice alternative payload type `P` is not trivially copyable and destructible in this specific [ChoicePayloadNotTrivialInSpecific]
  // CHECK:STDERR:     case .Some(_: T) => { return 1; }
  // CHECK:STDERR:     ^~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  // CHECK:STDERR: fail_payload_not_trivial_on_instantiation.carbon: error: unable to monomorphize specific `Some(P)` [ResolvingSpecificHere]
  // CHECK:STDERR: fail_payload_not_trivial_on_instantiation.carbon:[[@LINE-38]]:1: note: choice alternative payload type `P` is not trivially copyable and destructible in this specific [ChoicePayloadNotTrivialInSpecific]
  // CHECK:STDERR: choice Opt(T: type) {
  // CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  return Conv(p);
}

// --- fail_todo_scrutinee_template_type.carbon
library "[[@TEST_NAME]]";

// Proposal 2200's `match` on a dependent value (TR-13, DD-1 fixture X10).
fn Kind[template T: type](x: T) -> i32 {
  // CHECK:STDERR: fail_todo_scrutinee_template_type.carbon:[[@LINE+4]]:9: error: semantics TODO: `match on unsupported scrutinee type` [SemanticsTodo]
  // CHECK:STDERR:   match (x) {
  // CHECK:STDERR:         ^~~
  // CHECK:STDERR:
  match (x) {
    case _: i32 => { return 32; }
    default => { return 0; }
  }
}

fn Use() -> i32 {
  return Kind(1 as i32);
}

// --- fail_todo_scrutinee_template_tuple.carbon
library "[[@TEST_NAME]]";

fn Kind[template T: type](t: T) -> i32 {
  // CHECK:STDERR: fail_todo_scrutinee_template_tuple.carbon:[[@LINE+4]]:9: error: semantics TODO: `match on unsupported scrutinee type` [SemanticsTodo]
  // CHECK:STDERR:   match ((t, 1)) {
  // CHECK:STDERR:         ^~~~~~~~
  // CHECK:STDERR:
  match ((t, 1)) {
    case (_: T, 1) => { return 1; }
    default => { return 0; }
  }
}

// --- fail_todo_case_template_constant.carbon
library "[[@TEST_NAME]]";

// A case expression whose value is a template parameter is not a constant
// integer in the definition, as for a checked parameter.
fn Is(template K: i32, x: i32) -> i32 {
  match (x) {
    // CHECK:STDERR: fail_todo_case_template_constant.carbon:[[@LINE+4]]:5: error: semantics TODO: `match case expression pattern that is not a constant integer or `bool`` [SemanticsTodo]
    // CHECK:STDERR:     case K => { return 1; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR:
    case K => { return 1; }
    default => { return 0; }
  }
}

// --- fail_todo_scrutinee_deferred_call.carbon
library "[[@TEST_NAME]]";

choice Opt(T: type) {
  Some(value: T),
  None
}

fn Make[T: type](t: T) -> Opt(T) {
  return Opt(T).Some(t);
}

// The call is deferred, so the scrutinee's type is not known in the
// definition.
fn Conv[template T: type](t: T) -> i32 {
  // CHECK:STDERR: fail_todo_scrutinee_deferred_call.carbon:[[@LINE+4]]:9: error: semantics TODO: `match on unsupported scrutinee type` [SemanticsTodo]
  // CHECK:STDERR:   match (Make(t)) {
  // CHECK:STDERR:         ^~~~~~~~~
  // CHECK:STDERR:
  match (Make(t)) {
    case .None => { return 0; }
    default => { return 1; }
  }
}

// --- fail_todo_scrutinee_dependent_member.carbon
library "[[@TEST_NAME]]";

choice Opt(T: type) {
  Some(value: T),
  None
}

class Holder(T: type) {
  var o: Opt(T);
}

fn Conv[template T: type](h: Holder(T)) -> i32 {
  // CHECK:STDERR: fail_todo_scrutinee_dependent_member.carbon:[[@LINE+4]]:9: error: semantics TODO: `match on unsupported scrutinee type` [SemanticsTodo]
  // CHECK:STDERR:   match (h.o) {
  // CHECK:STDERR:         ^~~~~
  // CHECK:STDERR:
  match (h.o) {
    case .None => { return 0; }
    default => { return 1; }
  }
}

// --- fail_todo_pattern_form_deferred_call.carbon
library "[[@TEST_NAME]]";

choice Opt(T: type) {
  Some(value: T),
  None
}

fn Make[T: type](t: T) -> Opt(T) {
  return Opt(T).Some(t);
}

fn Conv[template T: type](t: T) -> i32 {
  // CHECK:STDERR: fail_todo_pattern_form_deferred_call.carbon:[[@LINE+4]]:19: error: semantics TODO: `refutable pattern binding on unsupported scrutinee type` [SemanticsTodo]
  // CHECK:STDERR:   if (let .None = Make(t)) {
  // CHECK:STDERR:                   ^~~~~~~
  // CHECK:STDERR:
  if (let .None = Make(t)) {
    return 0;
  }
  return 1;
}

// --- fail_todo_qualified_alternative.carbon
library "[[@TEST_NAME]]";

choice Opt(T: type) {
  Some(value: T),
  None
}

// The qualified spelling is a deferred member access in a template, so the
// case expression is not known to name an alternative in the definition.
fn Conv[template T: type](s: Opt(T)) -> i32 {
  match (s) {
    // CHECK:STDERR: fail_todo_qualified_alternative.carbon:[[@LINE+4]]:5: error: semantics TODO: `match case expression pattern on a choice scrutinee that is not an alternative` [SemanticsTodo]
    // CHECK:STDERR:     case Opt(T).None => { return 0; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR:
    case Opt(T).None => { return 0; }
    default => { return 1; }
  }
}

// CHECK:STDOUT: --- designator_arm.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %.Self.frozen: type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %pattern_type.9a5: type = pattern_type type [concrete]
// CHECK:STDOUT:   %Opt.type: type = generic_class_type @Opt [concrete]
// CHECK:STDOUT:   %Opt.generic: %Opt.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %u1: type = class_type @UInt, @UInt(%int_1.5b8) [concrete]
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
// CHECK:STDOUT:   %int_0.1a7: %u1 = int_value 0 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %bound_method.d7a: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
// CHECK:STDOUT:   %int_1.233: %u1 = int_value 1 [concrete]
// CHECK:STDOUT:   %T.patt.3a0592.2: %pattern_type.9a5 = symbolic_binding_pattern T, 0, template [template]
// CHECK:STDOUT:   %T.67db0b.2: type = symbolic_binding T, 0, template [template]
// CHECK:STDOUT:   %pattern_type.51d1c4.4: type = pattern_type %T.67db0b.2 [template]
// CHECK:STDOUT:   %t.param_patt.513: %pattern_type.51d1c4.4 = value_param_pattern [template]
// CHECK:STDOUT:   %t.patt.c64: %pattern_type.51d1c4.4 = wrapper_binding_pattern t, %t.param_patt.513 [template]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %Conv.type: type = fn_type @Conv [concrete]
// CHECK:STDOUT:   %Conv: %Conv.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete.9443dd.2: <witness> = require_complete_type %T.67db0b.2 [template]
// CHECK:STDOUT:   %i32.builtin: type = int_type signed, %int_32 [concrete]
// CHECK:STDOUT:   %complete_type.f8a: <witness> = complete_type_witness %i32.builtin [concrete]
// CHECK:STDOUT:   %Opt.ba7227.2: type = class_type @Opt, @Opt(%T.67db0b.2) [template]
// CHECK:STDOUT:   %tuple.type.026b76.2: type = tuple_type (%T.67db0b.2) [template]
// CHECK:STDOUT:   %.a2d648.2: type = custom_layout_type {size=0, align=0, .Some@0: %tuple.type.026b76.2} [template]
// CHECK:STDOUT:   %require_complete.dd155a.2: <witness> = require_complete_type %Opt.ba7227.2 [template]
// CHECK:STDOUT:   %uninit.37aa5a.2: %.a2d648.2 = uninitialized_value [template]
// CHECK:STDOUT:   %Opt.val.a5e0a9.2: %Opt.ba7227.2 = struct_value (%int_1.233, %uninit.37aa5a.2) [template]
// CHECK:STDOUT:   %pattern_type.86b717.2: type = pattern_type %Opt.ba7227.2 [template]
// CHECK:STDOUT:   %s.patt.f46: %pattern_type.86b717.2 = value_binding_pattern s [template]
// CHECK:STDOUT:   %.70f: type = type_of_inst @Conv.%.loc10_25.4 [template]
// CHECK:STDOUT:   %.fc3: %.70f = splice_inst @Conv.%.loc10_25.4 [template]
// CHECK:STDOUT:   %.768: %Opt.ba7227.2 = splice_inst @Conv.%.loc10_25.7 [template]
// CHECK:STDOUT:   %n.patt.d33: %pattern_type.51d1c4.4 = value_binding_pattern n [template]
// CHECK:STDOUT:   %pattern_type.b26: type = pattern_type %tuple.type.026b76.2 [template]
// CHECK:STDOUT:   %.f6e: %pattern_type.b26 = tuple_pattern (%n.patt.d33) [template]
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
// CHECK:STDOUT:   %t.param_patt.91a: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %t.patt.e4b: %pattern_type.6b6 = wrapper_binding_pattern t, %t.param_patt.91a [concrete]
// CHECK:STDOUT:   %Opt.46d: type = class_type @Opt, @Opt(%i32) [concrete]
// CHECK:STDOUT:   %tuple.type.a8a: type = tuple_type (%i32) [concrete]
// CHECK:STDOUT:   %.e8e: type = custom_layout_type {size=4, align=4, .Some@0: %tuple.type.a8a} [concrete]
// CHECK:STDOUT:   %struct_type.discriminant.payload.e99: type = struct_type {.discriminant: %u1, .payload: %.e8e} [concrete]
// CHECK:STDOUT:   %complete_type.378: <witness> = complete_type_witness %struct_type.discriminant.payload.e99 [concrete]
// CHECK:STDOUT:   %uninit.060: %.e8e = uninitialized_value [concrete]
// CHECK:STDOUT:   %Opt.val.b51: %Opt.46d = struct_value (%int_1.233, %uninit.060) [concrete]
// CHECK:STDOUT:   %pattern_type.25d: type = pattern_type %Opt.46d [concrete]
// CHECK:STDOUT:   %s.patt.5d5: %pattern_type.25d = value_binding_pattern s [concrete]
// CHECK:STDOUT:   %inst.splice_block.426619.1: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.3d0: %Opt.46d = splice_block %None.ref [concrete = %Opt.val.b51] {
// CHECK:STDOUT:       %.274: %Opt.46d = specific_constant @Opt.%.loc6_1.13, @Opt(%i32) [concrete = %Opt.val.b51]
// CHECK:STDOUT:       %None.ref: %Opt.46d = name_ref None, %.274 [concrete = %Opt.val.b51]
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %inst.splice_block.426619.2: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.b46: %Opt.46d = splice_block %Opt.val.b51 [concrete = %Opt.val.b51] {}
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %n.patt.c48: %pattern_type.6b6 = value_binding_pattern n [concrete]
// CHECK:STDOUT:   %pattern_type.e71: type = pattern_type %tuple.type.a8a [concrete]
// CHECK:STDOUT:   %.4e1: %pattern_type.e71 = tuple_pattern (%n.patt.c48) [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
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
// CHECK:STDOUT:   %Conv.decl: %Conv.type = fn_decl @Conv [concrete = constants.%Conv] {
// CHECK:STDOUT:     %T.patt.loc9_19.1: %pattern_type.9a5 = symbolic_binding_pattern T, 0, template [template = %T.patt.loc9_19.2 (constants.%T.patt.3a0592.2)]
// CHECK:STDOUT:     %t.param_patt.loc9_35.1: @Conv.%pattern_type.loc9 (%pattern_type.51d1c4.4) = value_param_pattern [template = %t.param_patt.loc9_35.2 (constants.%t.param_patt.513)]
// CHECK:STDOUT:     %t.patt.loc9_35.1: @Conv.%pattern_type.loc9 (%pattern_type.51d1c4.4) = wrapper_binding_pattern t, %t.param_patt.loc9_35.1 [template = %t.patt.loc9_35.2 (constants.%t.patt.c64)]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc9_43: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %.loc9_21.1: type = splice_block %.loc9_21.2 [concrete = type] {
// CHECK:STDOUT:       %.Self.frozen: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %.loc9_21.2: type = type_literal type [concrete = type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc9_19.2: type = symbolic_binding T, 0, template [template = %T.loc9_19.1 (constants.%T.67db0b.2)]
// CHECK:STDOUT:     %t.param: @Conv.%T.loc9_19.1 (%T.67db0b.2) = value_param call_param0
// CHECK:STDOUT:     %T.ref.loc9: type = name_ref T, %T.loc9_19.2 [template = %T.loc9_19.1 (constants.%T.67db0b.2)]
// CHECK:STDOUT:     %t: @Conv.%T.loc9_19.1 (%T.67db0b.2) = wrapper_binding t, %t.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @Conv(%T.loc9_19.2: type) {
// CHECK:STDOUT:   %T.patt.loc9_19.2: %pattern_type.9a5 = symbolic_binding_pattern T, 0, template [template = %T.patt.loc9_19.2 (constants.%T.patt.3a0592.2)]
// CHECK:STDOUT:   %T.loc9_19.1: type = symbolic_binding T, 0, template [template = %T.loc9_19.1 (constants.%T.67db0b.2)]
// CHECK:STDOUT:   %pattern_type.loc9: type = pattern_type %T.loc9_19.1 [template = %pattern_type.loc9 (constants.%pattern_type.51d1c4.4)]
// CHECK:STDOUT:   %t.param_patt.loc9_35.2: @Conv.%pattern_type.loc9 (%pattern_type.51d1c4.4) = value_param_pattern [template = %t.param_patt.loc9_35.2 (constants.%t.param_patt.513)]
// CHECK:STDOUT:   %t.patt.loc9_35.2: @Conv.%pattern_type.loc9 (%pattern_type.51d1c4.4) = wrapper_binding_pattern t, %t.param_patt.loc9_35.2 [template = %t.patt.loc9_35.2 (constants.%t.patt.c64)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc9: <witness> = require_complete_type %T.loc9_19.1 [template = %require_complete.loc9 (constants.%require_complete.9443dd.2)]
// CHECK:STDOUT:   %Opt.loc10_15.2: type = class_type @Opt, @Opt(%T.loc9_19.1) [template = %Opt.loc10_15.2 (constants.%Opt.ba7227.2)]
// CHECK:STDOUT:   %require_complete.loc10: <witness> = require_complete_type %Opt.loc10_15.2 [template = %require_complete.loc10 (constants.%require_complete.dd155a.2)]
// CHECK:STDOUT:   %pattern_type.loc10: type = pattern_type %Opt.loc10_15.2 [template = %pattern_type.loc10 (constants.%pattern_type.86b717.2)]
// CHECK:STDOUT:   %s.patt.loc10_8.2: @Conv.%pattern_type.loc10 (%pattern_type.86b717.2) = value_binding_pattern s [template = %s.patt.loc10_8.2 (constants.%s.patt.f46)]
// CHECK:STDOUT:   %.loc10_25.4: <instruction> = access_member_action %Opt.loc10_24, None [template]
// CHECK:STDOUT:   %.loc10_25.5: type = type_of_inst %.loc10_25.4 [template = %.loc10_25.5 (constants.%.70f)]
// CHECK:STDOUT:   %.loc10_25.6: @Conv.%.loc10_25.5 (%.70f) = splice_inst %.loc10_25.4 [template = %.loc10_25.6 (constants.%.fc3)]
// CHECK:STDOUT:   %.loc10_25.7: <instruction> = convert_to_value_action %.loc10_25.2, %Opt.loc10_15.2 [template]
// CHECK:STDOUT:   %.loc10_25.8: @Conv.%Opt.loc10_15.2 (%Opt.ba7227.2) = splice_inst %.loc10_25.7 [template = %.loc10_25.8 (constants.%.768)]
// CHECK:STDOUT:   %n.patt.loc12_24.2: @Conv.%pattern_type.loc9 (%pattern_type.51d1c4.4) = value_binding_pattern n [template = %n.patt.loc12_24.2 (constants.%n.patt.d33)]
// CHECK:STDOUT:   %tuple.type: type = tuple_type (%T.loc9_19.1) [template = %tuple.type (constants.%tuple.type.026b76.2)]
// CHECK:STDOUT:   %pattern_type.loc12: type = pattern_type %tuple.type [template = %pattern_type.loc12 (constants.%pattern_type.b26)]
// CHECK:STDOUT:   %.loc12_24.2: @Conv.%pattern_type.loc12 (%pattern_type.b26) = tuple_pattern (%n.patt.loc12_24.2) [template = %.loc12_24.2 (constants.%.f6e)]
// CHECK:STDOUT:   %.loc12_29.10: type = custom_layout_type {size=0, align=0, .Some@0: @Conv.%tuple.type (%tuple.type.026b76.2)} [template = %.loc12_29.10 (constants.%.a2d648.2)]
// CHECK:STDOUT:   %uninit: @Conv.%.loc12_29.10 (%.a2d648.2) = uninitialized_value [template = %uninit (constants.%uninit.37aa5a.2)]
// CHECK:STDOUT:   %Opt.val: @Conv.%Opt.loc10_15.2 (%Opt.ba7227.2) = struct_value (constants.%int_1.233, %uninit) [template = %Opt.val (constants.%Opt.val.a5e0a9.2)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%t.param: @Conv.%T.loc9_19.1 (%T.67db0b.2)) -> out %return.param: %i32 {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %Opt.ref.loc10_19: %Opt.type = name_ref Opt, file.%Opt.decl [concrete = constants.%Opt.generic]
// CHECK:STDOUT:     %T.ref.loc10_23: type = name_ref T, %T.loc9_19.2 [template = %T.loc9_19.1 (constants.%T.67db0b.2)]
// CHECK:STDOUT:     %Opt.loc10_24: type = class_type @Opt, @Opt(constants.%T.67db0b.2) [template = %Opt.loc10_15.2 (constants.%Opt.ba7227.2)]
// CHECK:STDOUT:     %.loc10_25.1: type = type_of_inst %.loc10_25.4 [template = %.loc10_25.5 (constants.%.70f)]
// CHECK:STDOUT:     %.loc10_25.2: @Conv.%.loc10_25.5 (%.70f) = splice_inst %.loc10_25.4 [template = %.loc10_25.6 (constants.%.fc3)]
// CHECK:STDOUT:     %.loc10_25.3: @Conv.%Opt.loc10_15.2 (%Opt.ba7227.2) = splice_inst %.loc10_25.7 [template = %.loc10_25.8 (constants.%.768)]
// CHECK:STDOUT:     %.loc10_15: type = splice_block %Opt.loc10_15.1 [template = %Opt.loc10_15.2 (constants.%Opt.ba7227.2)] {
// CHECK:STDOUT:       %Opt.ref.loc10_10: %Opt.type = name_ref Opt, file.%Opt.decl [concrete = constants.%Opt.generic]
// CHECK:STDOUT:       %T.ref.loc10_14: type = name_ref T, %T.loc9_19.2 [template = %T.loc9_19.1 (constants.%T.67db0b.2)]
// CHECK:STDOUT:       %Opt.loc10_15.1: type = class_type @Opt, @Opt(constants.%T.67db0b.2) [template = %Opt.loc10_15.2 (constants.%Opt.ba7227.2)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %s: @Conv.%Opt.loc10_15.2 (%Opt.ba7227.2) = wrapper_binding s, %.loc10_25.3
// CHECK:STDOUT:     name_binding_decl {
// CHECK:STDOUT:       %s.patt.loc10_8.1: @Conv.%pattern_type.loc10 (%pattern_type.86b717.2) = value_binding_pattern s [template = %s.patt.loc10_8.2 (constants.%s.patt.f46)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %s.ref: @Conv.%Opt.loc10_15.2 (%Opt.ba7227.2) = name_ref s, %s
// CHECK:STDOUT:     name_binding_decl {
// CHECK:STDOUT:       %n.patt.loc12_24.1: @Conv.%pattern_type.loc9 (%pattern_type.51d1c4.4) = value_binding_pattern n [template = %n.patt.loc12_24.2 (constants.%n.patt.d33)]
// CHECK:STDOUT:       %.loc12_24.1: @Conv.%pattern_type.loc12 (%pattern_type.b26) = tuple_pattern (%n.patt.loc12_24.1) [template = %.loc12_24.2 (constants.%.f6e)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %int_0.loc12: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:     %impl.elem0.loc12_29.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:     %bound_method.loc12_29.1: <bound method> = bound_method %int_0.loc12, %impl.elem0.loc12_29.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:     %specific_fn.loc12_29.1: <specific function> = specific_function %impl.elem0.loc12_29.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:     %bound_method.loc12_29.2: <bound method> = bound_method %int_0.loc12, %specific_fn.loc12_29.1 [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc12_29: init %u1 = call %bound_method.loc12_29.2(%int_0.loc12) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:     %.loc12_29.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc12_29 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:     %.loc12_29.2: %u1 = converted %int_0.loc12, %.loc12_29.1 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:     %.loc12_29.3: ref %u1 = class_element_access %s.ref, element0
// CHECK:STDOUT:     %impl.elem0.loc12_29.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:     %bound_method.loc12_29.3: <bound method> = bound_method %.loc12_29.2, %impl.elem0.loc12_29.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.f34]
// CHECK:STDOUT:     %specific_fn.loc12_29.2: <specific function> = specific_function %impl.elem0.loc12_29.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:     %bound_method.loc12_29.4: <bound method> = bound_method %.loc12_29.2, %specific_fn.loc12_29.2 [concrete = constants.%bound_method.53a]
// CHECK:STDOUT:     %.loc12_29.4: %u1 = acquire_value %.loc12_29.3
// CHECK:STDOUT:     %UInt.as.EqWith.impl.Equal.call.loc12: init bool = call %bound_method.loc12_29.4(%.loc12_29.2, %.loc12_29.4)
// CHECK:STDOUT:     %.loc12_29.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc12
// CHECK:STDOUT:     %.loc12_29.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc12, %.loc12_29.5
// CHECK:STDOUT:     if %.loc12_29.6 br !match.case.then.loc12 else br !match.case.else.loc12
// CHECK:STDOUT:
// CHECK:STDOUT:   !match.case.then.loc12:
// CHECK:STDOUT:     %.loc12_29.7: ref @Conv.%.loc12_29.10 (%.a2d648.2) = class_element_access %s.ref, element1
// CHECK:STDOUT:     %.loc12_29.8: ref @Conv.%tuple.type (%tuple.type.026b76.2) = class_element_access %.loc12_29.7, element0
// CHECK:STDOUT:     %tuple.elem0: ref @Conv.%T.loc9_19.1 (%T.67db0b.2) = tuple_access %.loc12_29.8, element0
// CHECK:STDOUT:     %.loc12_29.9: @Conv.%T.loc9_19.1 (%T.67db0b.2) = acquire_value %tuple.elem0
// CHECK:STDOUT:     %T.ref.loc12: type = name_ref T, %T.loc9_19.2 [template = %T.loc9_19.1 (constants.%T.67db0b.2)]
// CHECK:STDOUT:     %n: @Conv.%T.loc9_19.1 (%T.67db0b.2) = wrapper_binding n, %.loc12_29.9
// CHECK:STDOUT:     %int_1.loc12: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:     %impl.elem0.loc12_42: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:     %bound_method.loc12_42.1: <bound method> = bound_method %int_1.loc12, %impl.elem0.loc12_42 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:     %specific_fn.loc12_42: <specific function> = specific_function %impl.elem0.loc12_42, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:     %bound_method.loc12_42.2: <bound method> = bound_method %int_1.loc12, %specific_fn.loc12_42 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc12_42: init %i32 = call %bound_method.loc12_42.2(%int_1.loc12) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:     %.loc12_42: init %i32 = converted %int_1.loc12, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc12_42 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:     return %.loc12_42
// CHECK:STDOUT:
// CHECK:STDOUT:   !match.case.else.loc12:
// CHECK:STDOUT:     name_binding_decl {
// CHECK:STDOUT:       %expr_patt: @Conv.%pattern_type.loc10 (%pattern_type.86b717.2) = expr_pattern %None.ref in [concrete] {
// CHECK:STDOUT:         %.loc13_10.2: @Conv.%Opt.loc10_15.2 (%Opt.ba7227.2) = specific_constant @Opt.%.loc6_1.13, @Opt(constants.%T.67db0b.2) [template = %Opt.val (constants.%Opt.val.a5e0a9.2)]
// CHECK:STDOUT:         %None.ref: @Conv.%Opt.loc10_15.2 (%Opt.ba7227.2) = name_ref None, %.loc13_10.2 [template = %Opt.val (constants.%Opt.val.a5e0a9.2)]
// CHECK:STDOUT:       }
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %.loc13_10.1: @Conv.%Opt.loc10_15.2 (%Opt.ba7227.2) = splice_block %None.ref [template = %Opt.val (constants.%Opt.val.a5e0a9.2)] {
// CHECK:STDOUT:       %.loc13_10.2: @Conv.%Opt.loc10_15.2 (%Opt.ba7227.2) = specific_constant @Opt.%.loc6_1.13, @Opt(constants.%T.67db0b.2) [template = %Opt.val (constants.%Opt.val.a5e0a9.2)]
// CHECK:STDOUT:       %None.ref: @Conv.%Opt.loc10_15.2 (%Opt.ba7227.2) = name_ref None, %.loc13_10.2 [template = %Opt.val (constants.%Opt.val.a5e0a9.2)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %int_1.loc13: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:     %impl.elem0.loc13_16.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:     %bound_method.loc13_16.1: <bound method> = bound_method %int_1.loc13, %impl.elem0.loc13_16.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:     %specific_fn.loc13_16.1: <specific function> = specific_function %impl.elem0.loc13_16.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:     %bound_method.loc13_16.2: <bound method> = bound_method %int_1.loc13, %specific_fn.loc13_16.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13_16: init %u1 = call %bound_method.loc13_16.2(%int_1.loc13) [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc13_16.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13_16 [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc13_16.2: %u1 = converted %int_1.loc13, %.loc13_16.1 [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc13_16.3: ref %u1 = class_element_access %s.ref, element0
// CHECK:STDOUT:     %impl.elem0.loc13_16.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:     %bound_method.loc13_16.3: <bound method> = bound_method %.loc13_16.2, %impl.elem0.loc13_16.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.22c]
// CHECK:STDOUT:     %specific_fn.loc13_16.2: <specific function> = specific_function %impl.elem0.loc13_16.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:     %bound_method.loc13_16.4: <bound method> = bound_method %.loc13_16.2, %specific_fn.loc13_16.2 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:     %.loc13_16.4: %u1 = acquire_value %.loc13_16.3
// CHECK:STDOUT:     %UInt.as.EqWith.impl.Equal.call.loc13: init bool = call %bound_method.loc13_16.4(%.loc13_16.2, %.loc13_16.4)
// CHECK:STDOUT:     %.loc13_16.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc13
// CHECK:STDOUT:     %.loc13_16.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc13, %.loc13_16.5
// CHECK:STDOUT:     if %.loc13_16.6 br !match.case.then.loc13 else br !match.case.else.loc13
// CHECK:STDOUT:
// CHECK:STDOUT:   !match.case.then.loc13:
// CHECK:STDOUT:     %int_0.loc13: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:     %impl.elem0.loc13_29: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:     %bound_method.loc13_29.1: <bound method> = bound_method %int_0.loc13, %impl.elem0.loc13_29 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:     %specific_fn.loc13_29: <specific function> = specific_function %impl.elem0.loc13_29, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:     %bound_method.loc13_29.2: <bound method> = bound_method %int_0.loc13, %specific_fn.loc13_29 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13_29: init %i32 = call %bound_method.loc13_29.2(%int_0.loc13) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:     %.loc13_29: init %i32 = converted %int_0.loc13, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13_29 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:     return %.loc13_29
// CHECK:STDOUT:
// CHECK:STDOUT:   !match.case.else.loc13:
// CHECK:STDOUT:     br !match.done
// CHECK:STDOUT:
// CHECK:STDOUT:   !match.done:
// CHECK:STDOUT:     %int_1.loc15: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:     %impl.elem1: %.758 = impl_witness_access constants.%Negate.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:     %bound_method.loc15_10: <bound method> = bound_method %int_1.loc15, %impl.elem1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op.bound]
// CHECK:STDOUT:     %Core.IntLiteral.as.Negate.impl.Op.call: init Core.IntLiteral = call %bound_method.loc15_10(%int_1.loc15) [concrete = constants.%int_-1.638]
// CHECK:STDOUT:     %impl.elem0.loc15: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:     %bound_method.loc15_12.1: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %impl.elem0.loc15 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.65e]
// CHECK:STDOUT:     %specific_fn.loc15: <specific function> = specific_function %impl.elem0.loc15, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:     %bound_method.loc15_12.2: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %specific_fn.loc15 [concrete = constants.%bound_method.a65]
// CHECK:STDOUT:     %.loc15_10.1: Core.IntLiteral = value_of_initializer %Core.IntLiteral.as.Negate.impl.Op.call [concrete = constants.%int_-1.638]
// CHECK:STDOUT:     %.loc15_10.2: Core.IntLiteral = converted %Core.IntLiteral.as.Negate.impl.Op.call, %.loc15_10.1 [concrete = constants.%int_-1.638]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc15: init %i32 = call %bound_method.loc15_12.2(%.loc15_10.2) [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:     %.loc15_12: init %i32 = converted %Core.IntLiteral.as.Negate.impl.Op.call, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc15 [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:     return %.loc15_12
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Conv(constants.%T.67db0b.2) {
// CHECK:STDOUT:   %T.patt.loc9_19.2 => constants.%T.patt.3a0592.2
// CHECK:STDOUT:   %T.loc9_19.1 => constants.%T.67db0b.2
// CHECK:STDOUT:   %pattern_type.loc9 => constants.%pattern_type.51d1c4.4
// CHECK:STDOUT:   %t.param_patt.loc9_35.2 => constants.%t.param_patt.513
// CHECK:STDOUT:   %t.patt.loc9_35.2 => constants.%t.patt.c64
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Conv(constants.%i32) {
// CHECK:STDOUT:   %T.patt.loc9_19.2 => constants.%T.patt.3a0592.2
// CHECK:STDOUT:   %T.loc9_19.1 => constants.%i32
// CHECK:STDOUT:   %pattern_type.loc9 => constants.%pattern_type.6b6
// CHECK:STDOUT:   %t.param_patt.loc9_35.2 => constants.%t.param_patt.91a
// CHECK:STDOUT:   %t.patt.loc9_35.2 => constants.%t.patt.e4b
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc9 => constants.%complete_type.f8a
// CHECK:STDOUT:   %Opt.loc10_15.2 => constants.%Opt.46d
// CHECK:STDOUT:   %require_complete.loc10 => constants.%complete_type.378
// CHECK:STDOUT:   %pattern_type.loc10 => constants.%pattern_type.25d
// CHECK:STDOUT:   %s.patt.loc10_8.2 => constants.%s.patt.5d5
// CHECK:STDOUT:   %.loc10_25.4 => constants.%inst.splice_block.426619.1
// CHECK:STDOUT:   %.loc10_25.5 => constants.%Opt.46d
// CHECK:STDOUT:   %.loc10_25.6 => constants.%Opt.val.b51
// CHECK:STDOUT:   %.loc10_25.7 => constants.%inst.splice_block.426619.2
// CHECK:STDOUT:   %.loc10_25.8 => constants.%Opt.val.b51
// CHECK:STDOUT:   %n.patt.loc12_24.2 => constants.%n.patt.c48
// CHECK:STDOUT:   %tuple.type => constants.%tuple.type.a8a
// CHECK:STDOUT:   %pattern_type.loc12 => constants.%pattern_type.e71
// CHECK:STDOUT:   %.loc12_24.2 => constants.%.4e1
// CHECK:STDOUT:   %.loc12_29.10 => constants.%.e8e
// CHECK:STDOUT:   %uninit => constants.%uninit.060
// CHECK:STDOUT:   %Opt.val => constants.%Opt.val.b51
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- class_template_choice.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %pattern_type.9a5: type = pattern_type type [concrete]
// CHECK:STDOUT:   %T.patt.3a0592.1: %pattern_type.9a5 = symbolic_binding_pattern T, 0, template [template]
// CHECK:STDOUT:   %T.67db0b.1: type = symbolic_binding T, 0, template [template]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %Outer.dee: type = class_type @Outer, @Outer(%T.67db0b.1) [template]
// CHECK:STDOUT:   %C.7d7: type = class_type @C, @C(%T.67db0b.1) [template]
// CHECK:STDOUT:   %pattern_type.51d1c4.1: type = pattern_type %T.67db0b.1 [template]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %u1: type = class_type @UInt, @UInt(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %require_complete.9443dd.1: <witness> = require_complete_type %T.67db0b.1 [template]
// CHECK:STDOUT:   %tuple.type.026: type = tuple_type (%T.67db0b.1) [template]
// CHECK:STDOUT:   %.964: type = custom_layout_type {size=0, align=0, .A@0: %tuple.type.026} [template]
// CHECK:STDOUT:   %pattern_type.6fd: type = pattern_type %C.7d7 [template]
// CHECK:STDOUT:   %C.A.type.36a: type = fn_type @C.A, @C(%T.67db0b.1) [template]
// CHECK:STDOUT:   %C.A.f60: %C.A.type.36a = struct_value () [template]
// CHECK:STDOUT:   %require_complete.895: <witness> = require_complete_type %C.7d7 [template]
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
// CHECK:STDOUT:   %pattern_type.322: type = pattern_type %u1 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.0e8: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
// CHECK:STDOUT:   %int_0.1a7: %u1 = int_value 0 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %bound_method.d7a: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
// CHECK:STDOUT:   %int_1.233: %u1 = int_value 1 [concrete]
// CHECK:STDOUT:   %t.param_patt.513: %pattern_type.51d1c4.1 = value_param_pattern [template]
// CHECK:STDOUT:   %t.patt.c64: %pattern_type.51d1c4.1 = wrapper_binding_pattern t, %t.param_patt.513 [template]
// CHECK:STDOUT:   %pattern_type.831: type = pattern_type bool [concrete]
// CHECK:STDOUT:   %full.param_patt: %pattern_type.831 = value_param_pattern [concrete]
// CHECK:STDOUT:   %full.patt: %pattern_type.831 = wrapper_binding_pattern full, %full.param_patt [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %Outer.Get.type.53c: type = fn_type @Outer.Get, @Outer(%T.67db0b.1) [template]
// CHECK:STDOUT:   %Outer.Get.1cd: %Outer.Get.type.53c = struct_value () [template]
// CHECK:STDOUT:   %i32.builtin: type = int_type signed, %int_32 [concrete]
// CHECK:STDOUT:   %complete_type.f8a: <witness> = complete_type_witness %i32.builtin [concrete]
// CHECK:STDOUT:   %c.patt.6d1: %pattern_type.6fd = ref_binding_pattern c [template]
// CHECK:STDOUT:   %.65b: <instruction> = convert_to_value_action @C.%.loc9_3.4, %C.7d7 [template]
// CHECK:STDOUT:   %.85d25b.2: %C.7d7 = splice_inst %.65b [template]
// CHECK:STDOUT:   %c.var_patt.7e6: %pattern_type.6fd = var_pattern %c.patt.6d1 [template]
// CHECK:STDOUT:   %.46d: type = type_of_inst @Outer.Get.%.loc13_17.3 [template]
// CHECK:STDOUT:   %.558: %.46d = splice_inst @Outer.Get.%.loc13_17.3 [template]
// CHECK:STDOUT:   %tuple.type.f7a: type = tuple_type (<instruction>) [concrete]
// CHECK:STDOUT:   %.290699.1: %C.7d7 = splice_inst @Outer.Get.%tuple.elem0.loc13 [template]
// CHECK:STDOUT:   %.fdd: type = type_of_inst @Outer.Get.%.loc15_12.3 [template]
// CHECK:STDOUT:   %.598: %.fdd = splice_inst @Outer.Get.%.loc15_12.3 [template]
// CHECK:STDOUT:   %.cde: type = type_of_inst @Outer.Get.%.loc15_16.3 [template]
// CHECK:STDOUT:   %.a15: %.cde = splice_inst @Outer.Get.%.loc15_16.3 [template]
// CHECK:STDOUT:   %.290699.2: %C.7d7 = splice_inst @Outer.Get.%tuple.elem0.loc15 [template]
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
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound.22c: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
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
// CHECK:STDOUT:   %Destroy.type: type = facet_type <@Destroy> [concrete]
// CHECK:STDOUT:   %Self.0e7: %Destroy.type = symbolic_binding Self, 0 [symbolic]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.4e5: type = fn_type @Destroy.WithSelf.SelfDestruct.1, @Destroy.WithSelf(%Self.0e7) [symbolic]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.4a0: %Destroy.WithSelf.SelfDestruct.type.4e5 = struct_value () [symbolic]
// CHECK:STDOUT:   %Destroy.assoc_type: type = assoc_entity_type @Destroy [concrete]
// CHECK:STDOUT:   %assoc2: %Destroy.assoc_type = assoc_entity element2, imports.%Core.import_ref.71d [concrete]
// CHECK:STDOUT:   %.8cb5e6.1: type = type_of_inst @Outer.Get.%.loc13_5.16 [template]
// CHECK:STDOUT:   %.c234ea.1: %.8cb5e6.1 = splice_inst @Outer.Get.%.loc13_5.16 [template]
// CHECK:STDOUT:   %.57c638.1: type = type_of_inst @Outer.Get.%.loc13_5.19 [template]
// CHECK:STDOUT:   %.e63d45.1: %.57c638.1 = splice_inst @Outer.Get.%.loc13_5.19 [template]
// CHECK:STDOUT:   %_.patt.ee9: %pattern_type.51d1c4.1 = value_binding_pattern _ [template]
// CHECK:STDOUT:   %pattern_type.b26: type = pattern_type %tuple.type.026 [template]
// CHECK:STDOUT:   %.0bf: %pattern_type.b26 = tuple_pattern (%_.patt.ee9) [template]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound.f34: <bound method> = bound_method %int_0.1a7, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %bound_method.53a: <bound method> = bound_method %int_0.1a7, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.953: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT:   %.8cb5e6.2: type = type_of_inst @Outer.Get.%.loc13_5.22 [template]
// CHECK:STDOUT:   %.c234ea.2: %.8cb5e6.2 = splice_inst @Outer.Get.%.loc13_5.22 [template]
// CHECK:STDOUT:   %.57c638.2: type = type_of_inst @Outer.Get.%.loc13_5.25 [template]
// CHECK:STDOUT:   %.e63d45.2: %.57c638.2 = splice_inst @Outer.Get.%.loc13_5.25 [template]
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
// CHECK:STDOUT:   %.8cb5e6.3: type = type_of_inst @Outer.Get.%.loc13_5.28 [template]
// CHECK:STDOUT:   %.c234ea.3: %.8cb5e6.3 = splice_inst @Outer.Get.%.loc13_5.28 [template]
// CHECK:STDOUT:   %.57c638.3: type = type_of_inst @Outer.Get.%.loc13_5.31 [template]
// CHECK:STDOUT:   %.e63d45.3: %.57c638.3 = splice_inst @Outer.Get.%.loc13_5.31 [template]
// CHECK:STDOUT:   %C.b7f: type = class_type @C, @C(%i32) [concrete]
// CHECK:STDOUT:   %Outer.Get.type.ac9: type = fn_type @Outer.Get, @Outer(%i32) [concrete]
// CHECK:STDOUT:   %Outer.Get.dd6: %Outer.Get.type.ac9 = struct_value () [concrete]
// CHECK:STDOUT:   %t.param_patt.91a: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %t.patt.e4b: %pattern_type.6b6 = wrapper_binding_pattern t, %t.param_patt.91a [concrete]
// CHECK:STDOUT:   %tuple.type.a8a: type = tuple_type (%i32) [concrete]
// CHECK:STDOUT:   %.39a: type = custom_layout_type {size=4, align=4, .A@0: %tuple.type.a8a} [concrete]
// CHECK:STDOUT:   %struct_type.discriminant.payload.913: type = struct_type {.discriminant: %u1, .payload: %.39a} [concrete]
// CHECK:STDOUT:   %complete_type.e44: <witness> = complete_type_witness %struct_type.discriminant.payload.913 [concrete]
// CHECK:STDOUT:   %C.A.type.23d: type = fn_type @C.A, @C(%i32) [concrete]
// CHECK:STDOUT:   %C.A.e9e: %C.A.type.23d = struct_value () [concrete]
// CHECK:STDOUT:   %uninit.5bdc45.1: %.39a = uninitialized_value [concrete]
// CHECK:STDOUT:   %C.val.375: %C.b7f = struct_value (%int_1.233, %uninit.5bdc45.1) [concrete]
// CHECK:STDOUT:   %pattern_type.9d0: type = pattern_type %C.b7f [concrete]
// CHECK:STDOUT:   %c.patt.69e: %pattern_type.9d0 = ref_binding_pattern c [concrete]
// CHECK:STDOUT:   %c.var_patt.e4b: %pattern_type.9d0 = var_pattern %c.patt.69e [concrete]
// CHECK:STDOUT:   %inst.splice_block.426619.2: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.8c3: %C.b7f = splice_block %B.ref [concrete = %C.val.375] {
// CHECK:STDOUT:       %.a50: %C.b7f = specific_constant @C.%.loc9_3.5, @C(%i32) [concrete = %C.val.375]
// CHECK:STDOUT:       %B.ref: %C.b7f = name_ref B, %.a50 [concrete = %C.val.375]
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %inst.splice_block.426619.3: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.674: init %C.b7f = splice_block %Copy.WithSelf.Op.call [concrete = %C.val.375] {
// CHECK:STDOUT:       <elided>
// CHECK:STDOUT:       %.821be2.4: ref %C.b7f = specific_inst @Outer.Get.%c.var, @Outer.Get(%i32)
// CHECK:STDOUT:       <elided>
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %tuple.24243e.1: %tuple.type.f7a = tuple_value (%inst.splice_block.426619.3) [concrete]
// CHECK:STDOUT:   %inst.splice_block.426619.4: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.6cc: %C.A.type.23d = splice_block %A.ref [concrete = %C.A.e9e] {
// CHECK:STDOUT:       %.416: %C.A.type.23d = specific_constant generated.%C.A.decl, @C(%i32) [concrete = %C.A.e9e]
// CHECK:STDOUT:       %A.ref: %C.A.type.23d = name_ref A, %.416 [concrete = %C.A.e9e]
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %inst.splice_block.426619.5: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.53e: init %C.b7f = splice_block %C.A.call {
// CHECK:STDOUT:       %.cb7: %i32 = specific_inst @Outer.Get.%t.ref, @Outer.Get(%i32)
// CHECK:STDOUT:       <elided>
// CHECK:STDOUT:       %.f0b: ref %C.b7f = specific_inst @Outer.Get.%c.ref.loc15, @Outer.Get(%i32)
// CHECK:STDOUT:       %C.A.call: init %C.b7f to %.f0b = call %C.A.specific_fn.f0c556.2(%.cb7)
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %inst.splice_block.426619.6: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.e4e: init %C.b7f = splice_block %.53e {}
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %tuple.24243e.2: %tuple.type.f7a = tuple_value (%inst.splice_block.426619.6) [concrete]
// CHECK:STDOUT:   %inst.splice_block.426619.7: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.f61657.2: %C.b7f = splice_block %.ca191a.1 [concrete = %C.val.375] {
// CHECK:STDOUT:       <elided>
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %self.param_patt.7c1: %pattern_type.322 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.945: %pattern_type.322 = wrapper_binding_pattern self, %self.param_patt.7c1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc13_5.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.1: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.1: type = fn_type @Destroy.WithSelf.Op.loc13_5.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.1: %Destroy.WithSelf.Op.type.ef016f.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.1: type = fn_type @Destroy.WithSelf.SelfDestruct.loc13_5.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.1: %Destroy.WithSelf.SelfDestruct.type.fbceb5.1 = struct_value () [concrete]
// CHECK:STDOUT:   %self.param_patt.705: %pattern_type.6b6 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.70d: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt.705 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc13_5.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.2: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.2: type = fn_type @Destroy.WithSelf.Op.loc13_5.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.2: %Destroy.WithSelf.Op.type.ef016f.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.2: type = fn_type @Destroy.WithSelf.SelfDestruct.loc13_5.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.2: %Destroy.WithSelf.SelfDestruct.type.fbceb5.2 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.e71: type = pattern_type %tuple.type.a8a [concrete]
// CHECK:STDOUT:   %self.param_patt.bad: %pattern_type.e71 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.216: %pattern_type.e71 = wrapper_binding_pattern self, %self.param_patt.bad [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc13_5.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.3: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.3: type = fn_type @Destroy.WithSelf.Op.loc13_5.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.3: %Destroy.WithSelf.Op.type.ef016f.3 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.06b: type = pattern_type %.39a [concrete]
// CHECK:STDOUT:   %self.param_patt.6d7: %pattern_type.06b = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.1393: %pattern_type.06b = wrapper_binding_pattern self, %self.param_patt.6d7 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc13_5.4 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.4: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.4: type = fn_type @Destroy.WithSelf.Op.loc13_5.4 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.4: %Destroy.WithSelf.Op.type.ef016f.4 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.4: type = fn_type @Destroy.WithSelf.SelfDestruct.loc13_5.4 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.4: %Destroy.WithSelf.SelfDestruct.type.fbceb5.4 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.9e3: type = pattern_type %struct_type.discriminant.payload.913 [concrete]
// CHECK:STDOUT:   %self.param_patt.ecc: %pattern_type.9e3 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.98e: %pattern_type.9e3 = wrapper_binding_pattern self, %self.param_patt.ecc [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.5: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc13_5.5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.5: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.5 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.5: type = fn_type @Destroy.WithSelf.Op.loc13_5.5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.5: %Destroy.WithSelf.Op.type.ef016f.5 = struct_value () [concrete]
// CHECK:STDOUT:   %self.param_patt.348: %pattern_type.9d0 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.a42: %pattern_type.9d0 = wrapper_binding_pattern self, %self.param_patt.348 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.6: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc13_5.6 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.6: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.6 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.6: type = fn_type @Destroy.WithSelf.Op.loc13_5.6 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.6: %Destroy.WithSelf.Op.type.ef016f.6 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.6: type = fn_type @Destroy.WithSelf.SelfDestruct.loc13_5.6 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.6: %Destroy.WithSelf.SelfDestruct.type.fbceb5.6 = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.f8f19d.6: <witness> = custom_witness (%Destroy.WithSelf.Op.403171.6, %Destroy.WithSelf.SubobjectDestroy.d01daf.6, %Destroy.WithSelf.SelfDestruct.db3fdb.6), @Destroy [concrete]
// CHECK:STDOUT:   %Destroy.facet.4e1: %Destroy.type = facet_value %C.b7f, (%custom_witness.f8f19d.6) [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.544: type = fn_type @Destroy.WithSelf.SelfDestruct.1, @Destroy.WithSelf(%Destroy.facet.4e1) [concrete]
// CHECK:STDOUT:   %.001: type = fn_type_with_self_type %Destroy.WithSelf.SelfDestruct.type.544, %Destroy.facet.4e1 [concrete]
// CHECK:STDOUT:   %inst.splice_block.426619.8: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.d44458.1: <bound method> = splice_block %bound_method.579dff.3 {
// CHECK:STDOUT:       %.821be2.3: ref %C.b7f = specific_inst @Outer.Get.%c.var, @Outer.Get(%i32)
// CHECK:STDOUT:       %impl.elem2.42bc1a.3: %.001 = impl_witness_access %custom_witness.f8f19d.6, element2 [concrete = %Destroy.WithSelf.SelfDestruct.db3fdb.6]
// CHECK:STDOUT:       %bound_method.579dff.3: <bound method> = bound_method %.821be2.3, %impl.elem2.42bc1a.3
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %inst.call.426619.1: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %Destroy.WithSelf.SelfDestruct.call.fe735d.1: init %empty_tuple.type = call %.d44458.1(%.821be2.3)
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %_.patt.bed: %pattern_type.6b6 = value_binding_pattern _ [concrete]
// CHECK:STDOUT:   %.91c8: %pattern_type.e71 = tuple_pattern (%_.patt.bed) [concrete]
// CHECK:STDOUT:   %inst.splice_block.426619.9: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.d44458.2: <bound method> = splice_block %bound_method.579dff.2 {
// CHECK:STDOUT:       %.821be2.2: ref %C.b7f = specific_inst @Outer.Get.%c.var, @Outer.Get(%i32)
// CHECK:STDOUT:       %impl.elem2.42bc1a.2: %.001 = impl_witness_access %custom_witness.f8f19d.6, element2 [concrete = %Destroy.WithSelf.SelfDestruct.db3fdb.6]
// CHECK:STDOUT:       %bound_method.579dff.2: <bound method> = bound_method %.821be2.2, %impl.elem2.42bc1a.2
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %inst.call.426619.2: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %Destroy.WithSelf.SelfDestruct.call.fe735d.2: init %empty_tuple.type = call %.d44458.2(%.821be2.2)
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %inst.splice_block.426619.10: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.d44458.3: <bound method> = splice_block %bound_method.579dff.1 {
// CHECK:STDOUT:       %.821be2.1: ref %C.b7f = specific_inst @Outer.Get.%c.var, @Outer.Get(%i32)
// CHECK:STDOUT:       %impl.elem2.42bc1a.1: %.001 = impl_witness_access %custom_witness.f8f19d.6, element2 [concrete = %Destroy.WithSelf.SelfDestruct.db3fdb.6]
// CHECK:STDOUT:       %bound_method.579dff.1: <bound method> = bound_method %.821be2.1, %impl.elem2.42bc1a.1
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %inst.call.426619.3: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %Destroy.WithSelf.SelfDestruct.call.fe735d.3: init %empty_tuple.type = call %.d44458.3(%.821be2.1)
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.aa5: @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.170)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.f01 = impl_witness_table (%Core.import_ref.aa5), @Core.IntLiteral.as.ImplicitAs.impl.b68 [concrete]
// CHECK:STDOUT:   %Core.import_ref.b92: @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal.type (%UInt.as.EqWith.impl.Equal.type.544) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal (constants.%UInt.as.EqWith.impl.Equal.c67)]
// CHECK:STDOUT:   %Core.import_ref.b44 = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.166 = impl_witness_table (%Core.import_ref.b92, %Core.import_ref.b44), @UInt.as.EqWith.impl.f13 [concrete]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.71d: @Destroy.WithSelf.%Destroy.WithSelf.SelfDestruct.type (%Destroy.WithSelf.SelfDestruct.type.4e5) = import_ref Core//prelude/destroy, loc{{\d+_\d+}}, loaded [symbolic = @Destroy.WithSelf.%Destroy.WithSelf.SelfDestruct (constants.%Destroy.WithSelf.SelfDestruct.4a0)]
// CHECK:STDOUT:   %Core.import_ref.abd = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9c3: %Core.IntLiteral.as.Negate.impl.Op.type = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, loaded [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %Negate.impl_witness_table = impl_witness_table (%Core.import_ref.abd, %Core.import_ref.9c3), @Core.IntLiteral.as.Negate.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %C.A.decl: @C.%C.A.type (%C.A.type.36a) = fn_decl @C.A [template = @C.%C.A (constants.%C.A.f60)] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.1: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc13_5.1 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.1] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.322 = ref_param_pattern [concrete = constants.%self.param_patt.7c1]
// CHECK:STDOUT:     %self.patt: %pattern_type.322 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.945]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %u1 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %u1 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.1: %Destroy.WithSelf.Op.type.ef016f.1 = fn_decl @Destroy.WithSelf.Op.loc13_5.1 [concrete = constants.%Destroy.WithSelf.Op.403171.1] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.322 = ref_param_pattern [concrete = constants.%self.param_patt.7c1]
// CHECK:STDOUT:     %self.patt: %pattern_type.322 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.945]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %u1 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %u1 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.2: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc13_5.2 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.2] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6b6 = ref_param_pattern [concrete = constants.%self.param_patt.705]
// CHECK:STDOUT:     %self.patt: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.70d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i32 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i32 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.2: %Destroy.WithSelf.Op.type.ef016f.2 = fn_decl @Destroy.WithSelf.Op.loc13_5.2 [concrete = constants.%Destroy.WithSelf.Op.403171.2] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6b6 = ref_param_pattern [concrete = constants.%self.param_patt.705]
// CHECK:STDOUT:     %self.patt: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.70d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i32 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i32 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.3: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc13_5.3 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.3] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.e71 = ref_param_pattern [concrete = constants.%self.param_patt.bad]
// CHECK:STDOUT:     %self.patt: %pattern_type.e71 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.216]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %tuple.type.a8a = ref_param call_param0
// CHECK:STDOUT:     %self: ref %tuple.type.a8a = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.3: %Destroy.WithSelf.Op.type.ef016f.3 = fn_decl @Destroy.WithSelf.Op.loc13_5.3 [concrete = constants.%Destroy.WithSelf.Op.403171.3] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.e71 = ref_param_pattern [concrete = constants.%self.param_patt.bad]
// CHECK:STDOUT:     %self.patt: %pattern_type.e71 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.216]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %tuple.type.a8a = ref_param call_param0
// CHECK:STDOUT:     %self: ref %tuple.type.a8a = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.4: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc13_5.4 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.4] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.06b = ref_param_pattern [concrete = constants.%self.param_patt.6d7]
// CHECK:STDOUT:     %self.patt: %pattern_type.06b = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.1393]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %.39a = ref_param call_param0
// CHECK:STDOUT:     %self: ref %.39a = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.4: %Destroy.WithSelf.Op.type.ef016f.4 = fn_decl @Destroy.WithSelf.Op.loc13_5.4 [concrete = constants.%Destroy.WithSelf.Op.403171.4] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.06b = ref_param_pattern [concrete = constants.%self.param_patt.6d7]
// CHECK:STDOUT:     %self.patt: %pattern_type.06b = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.1393]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %.39a = ref_param call_param0
// CHECK:STDOUT:     %self: ref %.39a = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.5: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.5 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc13_5.5 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.5] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.9e3 = ref_param_pattern [concrete = constants.%self.param_patt.ecc]
// CHECK:STDOUT:     %self.patt: %pattern_type.9e3 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.98e]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %struct_type.discriminant.payload.913 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %struct_type.discriminant.payload.913 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.5: %Destroy.WithSelf.Op.type.ef016f.5 = fn_decl @Destroy.WithSelf.Op.loc13_5.5 [concrete = constants.%Destroy.WithSelf.Op.403171.5] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.9e3 = ref_param_pattern [concrete = constants.%self.param_patt.ecc]
// CHECK:STDOUT:     %self.patt: %pattern_type.9e3 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.98e]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %struct_type.discriminant.payload.913 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %struct_type.discriminant.payload.913 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.6: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.6 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc13_5.6 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.6] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.9d0 = ref_param_pattern [concrete = constants.%self.param_patt.348]
// CHECK:STDOUT:     %self.patt: %pattern_type.9d0 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.a42]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %C.b7f = ref_param call_param0
// CHECK:STDOUT:     %self: ref %C.b7f = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.6: %Destroy.WithSelf.Op.type.ef016f.6 = fn_decl @Destroy.WithSelf.Op.loc13_5.6 [concrete = constants.%Destroy.WithSelf.Op.403171.6] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.9d0 = ref_param_pattern [concrete = constants.%self.param_patt.348]
// CHECK:STDOUT:     %self.patt: %pattern_type.9d0 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.a42]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %C.b7f = ref_param call_param0
// CHECK:STDOUT:     %self: ref %C.b7f = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic class @Outer(%T.loc5_23.2: type) {
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:   %Outer.Get.type: type = fn_type @Outer.Get, @Outer(%T.loc5_23.1) [template = %Outer.Get.type (constants.%Outer.Get.type.53c)]
// CHECK:STDOUT:   %Outer.Get: @Outer.%Outer.Get.type (%Outer.Get.type.53c) = struct_value () [template = %Outer.Get (constants.%Outer.Get.1cd)]
// CHECK:STDOUT:
// CHECK:STDOUT:   class {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:     %Outer.Get.decl: @Outer.%Outer.Get.type (%Outer.Get.type.53c) = fn_decl @Outer.Get [template = @Outer.%Outer.Get (constants.%Outer.Get.1cd)] {
// CHECK:STDOUT:       %t.param_patt.loc12_11.1: @Outer.Get.%pattern_type.loc12 (%pattern_type.51d1c4.1) = value_param_pattern [template = %t.param_patt.loc12_11.2 (constants.%t.param_patt.513)]
// CHECK:STDOUT:       %t.patt.loc12_11.1: @Outer.Get.%pattern_type.loc12 (%pattern_type.51d1c4.1) = wrapper_binding_pattern t, %t.param_patt.loc12_11.1 [template = %t.patt.loc12_11.2 (constants.%t.patt.c64)]
// CHECK:STDOUT:       %full.param_patt: %pattern_type.831 = value_param_pattern [concrete = constants.%full.param_patt]
// CHECK:STDOUT:       %full.patt: %pattern_type.831 = wrapper_binding_pattern full, %full.param_patt [concrete = constants.%full.patt]
// CHECK:STDOUT:       %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:       %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:     } {
// CHECK:STDOUT:       %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %.loc12_31: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:       %t.param: @Outer.Get.%T (%T.67db0b.1) = value_param call_param0
// CHECK:STDOUT:       %T.ref.loc12: type = name_ref T, @Outer.%T.loc5_23.2 [template = %T (constants.%T.67db0b.1)]
// CHECK:STDOUT:       %t: @Outer.Get.%T (%T.67db0b.1) = wrapper_binding t, %t.param
// CHECK:STDOUT:       %full.param: bool = value_param call_param1
// CHECK:STDOUT:       %.loc12_22: type = type_literal bool [concrete = bool]
// CHECK:STDOUT:       %full: bool = wrapper_binding full, %full.param
// CHECK:STDOUT:       %return.param: ref %i32 = out_param call_param2
// CHECK:STDOUT:       %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:     }
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:     complete_type_witness = %complete_type
// CHECK:STDOUT:
// CHECK:STDOUT:   !members:
// CHECK:STDOUT:     .Self = constants.%Outer.dee
// CHECK:STDOUT:     .C = %C.decl
// CHECK:STDOUT:     .T = <poisoned>
// CHECK:STDOUT:     .Get = %Outer.Get.decl
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @Outer.Get(@Outer.%T.loc5_23.2: type) {
// CHECK:STDOUT:   %T: type = symbolic_binding T, 0, template [template = %T (constants.%T.67db0b.1)]
// CHECK:STDOUT:   %pattern_type.loc12: type = pattern_type %T [template = %pattern_type.loc12 (constants.%pattern_type.51d1c4.1)]
// CHECK:STDOUT:   %t.param_patt.loc12_11.2: @Outer.Get.%pattern_type.loc12 (%pattern_type.51d1c4.1) = value_param_pattern [template = %t.param_patt.loc12_11.2 (constants.%t.param_patt.513)]
// CHECK:STDOUT:   %t.patt.loc12_11.2: @Outer.Get.%pattern_type.loc12 (%pattern_type.51d1c4.1) = wrapper_binding_pattern t, %t.param_patt.loc12_11.2 [template = %t.patt.loc12_11.2 (constants.%t.patt.c64)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc12: <witness> = require_complete_type %T [template = %require_complete.loc12 (constants.%require_complete.9443dd.1)]
// CHECK:STDOUT:   %C: type = class_type @C, @C(%T) [template = %C (constants.%C.7d7)]
// CHECK:STDOUT:   %require_complete.loc13: <witness> = require_complete_type %C [template = %require_complete.loc13 (constants.%require_complete.895)]
// CHECK:STDOUT:   %pattern_type.loc13: type = pattern_type %C [template = %pattern_type.loc13 (constants.%pattern_type.6fd)]
// CHECK:STDOUT:   %c.patt.loc13_10.2: @Outer.Get.%pattern_type.loc13 (%pattern_type.6fd) = ref_binding_pattern c [template = %c.patt.loc13_10.2 (constants.%c.patt.6d1)]
// CHECK:STDOUT:   %c.var_patt.loc13_5.2: @Outer.Get.%pattern_type.loc13 (%pattern_type.6fd) = var_pattern %c.patt.loc13_10.2 [template = %c.var_patt.loc13_5.2 (constants.%c.var_patt.7e6)]
// CHECK:STDOUT:   %.loc13_17.3: <instruction> = access_member_action %C.ref.loc13_16, B [template]
// CHECK:STDOUT:   %.loc13_17.4: type = type_of_inst %.loc13_17.3 [template = %.loc13_17.4 (constants.%.46d)]
// CHECK:STDOUT:   %.loc13_17.5: @Outer.Get.%.loc13_17.4 (%.46d) = splice_inst %.loc13_17.3 [template = %.loc13_17.5 (constants.%.558)]
// CHECK:STDOUT:   %.loc13_5.14: %tuple.type.f7a = initialize_action %.loc13_17.2, %C, %c.var, false [template]
// CHECK:STDOUT:   %tuple.elem0.loc13: <instruction> = tuple_access %.loc13_5.14, element0 [template]
// CHECK:STDOUT:   %.loc13_5.15: @Outer.Get.%C (%C.7d7) = splice_inst %tuple.elem0.loc13 [template = %.loc13_5.15 (constants.%.290699.1)]
// CHECK:STDOUT:   %.loc15_12.3: <instruction> = access_member_action %C.ref.loc15, A [template]
// CHECK:STDOUT:   %.loc15_12.4: type = type_of_inst %.loc15_12.3 [template = %.loc15_12.4 (constants.%.fdd)]
// CHECK:STDOUT:   %.loc15_12.5: @Outer.Get.%.loc15_12.4 (%.fdd) = splice_inst %.loc15_12.3 [template = %.loc15_12.5 (constants.%.598)]
// CHECK:STDOUT:   %.loc15_16.3: <instruction> = call_action (%.loc15_12.2, %t.ref), false [template]
// CHECK:STDOUT:   %.loc15_16.4: type = type_of_inst %.loc15_16.3 [template = %.loc15_16.4 (constants.%.cde)]
// CHECK:STDOUT:   %.loc15_16.5: @Outer.Get.%.loc15_16.4 (%.cde) = splice_inst %.loc15_16.3 [template = %.loc15_16.5 (constants.%.a15)]
// CHECK:STDOUT:   %.loc15_9.2: %tuple.type.f7a = initialize_action %.loc15_16.2, %C, %c.ref.loc15, false [template]
// CHECK:STDOUT:   %tuple.elem0.loc15: <instruction> = tuple_access %.loc15_9.2, element0 [template]
// CHECK:STDOUT:   %.loc15_9.3: @Outer.Get.%C (%C.7d7) = splice_inst %tuple.elem0.loc15 [template = %.loc15_9.3 (constants.%.290699.2)]
// CHECK:STDOUT:   %.loc18_12.3: <instruction> = convert_to_value_action @C.%.loc9_3.4, %C [template = %.loc18_12.3 (constants.%.65b)]
// CHECK:STDOUT:   %.loc18_12.4: @Outer.Get.%C (%C.7d7) = splice_inst %.loc18_12.3 [template = %.loc18_12.4 (constants.%.85d25b.2)]
// CHECK:STDOUT:   %.loc13_5.16: <instruction> = compound_member_access_action %c.var, constants.%assoc2 [template]
// CHECK:STDOUT:   %.loc13_5.17: type = type_of_inst %.loc13_5.16 [template = %.loc13_5.17 (constants.%.8cb5e6.1)]
// CHECK:STDOUT:   %.loc13_5.18: @Outer.Get.%.loc13_5.17 (%.8cb5e6.1) = splice_inst %.loc13_5.16 [template = %.loc13_5.18 (constants.%.c234ea.1)]
// CHECK:STDOUT:   %.loc13_5.19: <instruction> = call_action (%.loc13_5.3), true [template]
// CHECK:STDOUT:   %.loc13_5.20: type = type_of_inst %.loc13_5.19 [template = %.loc13_5.20 (constants.%.57c638.1)]
// CHECK:STDOUT:   %.loc13_5.21: @Outer.Get.%.loc13_5.20 (%.57c638.1) = splice_inst %.loc13_5.19 [template = %.loc13_5.21 (constants.%.e63d45.1)]
// CHECK:STDOUT:   %_.patt.loc19_16.2: @Outer.Get.%pattern_type.loc12 (%pattern_type.51d1c4.1) = value_binding_pattern _ [template = %_.patt.loc19_16.2 (constants.%_.patt.ee9)]
// CHECK:STDOUT:   %tuple.type: type = tuple_type (%T) [template = %tuple.type (constants.%tuple.type.026)]
// CHECK:STDOUT:   %pattern_type.loc19: type = pattern_type %tuple.type [template = %pattern_type.loc19 (constants.%pattern_type.b26)]
// CHECK:STDOUT:   %.loc19_16.2: @Outer.Get.%pattern_type.loc19 (%pattern_type.b26) = tuple_pattern (%_.patt.loc19_16.2) [template = %.loc19_16.2 (constants.%.0bf)]
// CHECK:STDOUT:   %.loc19_21.10: type = custom_layout_type {size=0, align=0, .A@0: @Outer.Get.%tuple.type (%tuple.type.026)} [template = %.loc19_21.10 (constants.%.964)]
// CHECK:STDOUT:   %.loc13_5.22: <instruction> = compound_member_access_action %c.var, constants.%assoc2 [template]
// CHECK:STDOUT:   %.loc13_5.23: type = type_of_inst %.loc13_5.22 [template = %.loc13_5.23 (constants.%.8cb5e6.2)]
// CHECK:STDOUT:   %.loc13_5.24: @Outer.Get.%.loc13_5.23 (%.8cb5e6.2) = splice_inst %.loc13_5.22 [template = %.loc13_5.24 (constants.%.c234ea.2)]
// CHECK:STDOUT:   %.loc13_5.25: <instruction> = call_action (%.loc13_5.7), true [template]
// CHECK:STDOUT:   %.loc13_5.26: type = type_of_inst %.loc13_5.25 [template = %.loc13_5.26 (constants.%.57c638.2)]
// CHECK:STDOUT:   %.loc13_5.27: @Outer.Get.%.loc13_5.26 (%.57c638.2) = splice_inst %.loc13_5.25 [template = %.loc13_5.27 (constants.%.e63d45.2)]
// CHECK:STDOUT:   %.loc13_5.28: <instruction> = compound_member_access_action %c.var, constants.%assoc2 [template]
// CHECK:STDOUT:   %.loc13_5.29: type = type_of_inst %.loc13_5.28 [template = %.loc13_5.29 (constants.%.8cb5e6.3)]
// CHECK:STDOUT:   %.loc13_5.30: @Outer.Get.%.loc13_5.29 (%.8cb5e6.3) = splice_inst %.loc13_5.28 [template = %.loc13_5.30 (constants.%.c234ea.3)]
// CHECK:STDOUT:   %.loc13_5.31: <instruction> = call_action (%.loc13_5.11), true [template]
// CHECK:STDOUT:   %.loc13_5.32: type = type_of_inst %.loc13_5.31 [template = %.loc13_5.32 (constants.%.57c638.3)]
// CHECK:STDOUT:   %.loc13_5.33: @Outer.Get.%.loc13_5.32 (%.57c638.3) = splice_inst %.loc13_5.31 [template = %.loc13_5.33 (constants.%.e63d45.3)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%t.param: @Outer.Get.%T (%T.67db0b.1), %full.param: bool) -> out %return.param: %i32 {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %c.var: ref @Outer.Get.%C (%C.7d7) = var_storage %c.var_patt.loc13_5.1
// CHECK:STDOUT:     %.loc13_16: type = specific_constant @Outer.%C.decl, @Outer(constants.%T.67db0b.1) [template = %C (constants.%C.7d7)]
// CHECK:STDOUT:     %C.ref.loc13_16: type = name_ref C, %.loc13_16 [template = %C (constants.%C.7d7)]
// CHECK:STDOUT:     %.loc13_17.1: type = type_of_inst %.loc13_17.3 [template = %.loc13_17.4 (constants.%.46d)]
// CHECK:STDOUT:     %.loc13_17.2: @Outer.Get.%.loc13_17.4 (%.46d) = splice_inst %.loc13_17.3 [template = %.loc13_17.5 (constants.%.558)]
// CHECK:STDOUT:     %.loc13_5.1: @Outer.Get.%C (%C.7d7) = splice_inst %tuple.elem0.loc13 [template = %.loc13_5.15 (constants.%.290699.1)]
// CHECK:STDOUT:     assign %c.var, %.loc13_5.1
// CHECK:STDOUT:     %.loc13_12.1: type = splice_block %C.ref.loc13_12 [template = %C (constants.%C.7d7)] {
// CHECK:STDOUT:       %.loc13_12.2: type = specific_constant @Outer.%C.decl, @Outer(constants.%T.67db0b.1) [template = %C (constants.%C.7d7)]
// CHECK:STDOUT:       %C.ref.loc13_12: type = name_ref C, %.loc13_12.2 [template = %C (constants.%C.7d7)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %c: ref @Outer.Get.%C (%C.7d7) = wrapper_binding c, %c.var
// CHECK:STDOUT:     name_binding_decl {
// CHECK:STDOUT:       %c.patt.loc13_10.1: @Outer.Get.%pattern_type.loc13 (%pattern_type.6fd) = ref_binding_pattern c [template = %c.patt.loc13_10.2 (constants.%c.patt.6d1)]
// CHECK:STDOUT:       %c.var_patt.loc13_5.1: @Outer.Get.%pattern_type.loc13 (%pattern_type.6fd) = var_pattern %c.patt.loc13_10.1 [template = %c.var_patt.loc13_5.2 (constants.%c.var_patt.7e6)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %full.ref: bool = name_ref full, %full
// CHECK:STDOUT:     if %full.ref br !if.then else br !if.else
// CHECK:STDOUT:
// CHECK:STDOUT:   !if.then:
// CHECK:STDOUT:     %c.ref.loc15: ref @Outer.Get.%C (%C.7d7) = name_ref c, %c
// CHECK:STDOUT:     %.loc15_11: type = specific_constant @Outer.%C.decl, @Outer(constants.%T.67db0b.1) [template = %C (constants.%C.7d7)]
// CHECK:STDOUT:     %C.ref.loc15: type = name_ref C, %.loc15_11 [template = %C (constants.%C.7d7)]
// CHECK:STDOUT:     %.loc15_12.1: type = type_of_inst %.loc15_12.3 [template = %.loc15_12.4 (constants.%.fdd)]
// CHECK:STDOUT:     %.loc15_12.2: @Outer.Get.%.loc15_12.4 (%.fdd) = splice_inst %.loc15_12.3 [template = %.loc15_12.5 (constants.%.598)]
// CHECK:STDOUT:     %t.ref: @Outer.Get.%T (%T.67db0b.1) = name_ref t, %t
// CHECK:STDOUT:     %.loc15_16.1: type = type_of_inst %.loc15_16.3 [template = %.loc15_16.4 (constants.%.cde)]
// CHECK:STDOUT:     %.loc15_16.2: @Outer.Get.%.loc15_16.4 (%.cde) = splice_inst %.loc15_16.3 [template = %.loc15_16.5 (constants.%.a15)]
// CHECK:STDOUT:     %.loc15_9.1: @Outer.Get.%C (%C.7d7) = splice_inst %tuple.elem0.loc15 [template = %.loc15_9.3 (constants.%.290699.2)]
// CHECK:STDOUT:     assign %c.ref.loc15, %.loc15_9.1
// CHECK:STDOUT:     br !if.else
// CHECK:STDOUT:
// CHECK:STDOUT:   !if.else:
// CHECK:STDOUT:     %c.ref.loc17: ref @Outer.Get.%C (%C.7d7) = name_ref c, %c
// CHECK:STDOUT:     name_binding_decl {
// CHECK:STDOUT:       %expr_patt: @Outer.Get.%pattern_type.loc13 (%pattern_type.6fd) = expr_pattern %B.ref in [concrete] {
// CHECK:STDOUT:         %.loc18_12.2: @Outer.Get.%C (%C.7d7) = specific_constant @C.%.loc9_3.5, @C(constants.%T.67db0b.1) [template = %.loc18_12.4 (constants.%.85d25b.2)]
// CHECK:STDOUT:         %B.ref: @Outer.Get.%C (%C.7d7) = name_ref B, %.loc18_12.2 [template = %.loc18_12.4 (constants.%.85d25b.2)]
// CHECK:STDOUT:       }
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %.loc18_12.1: @Outer.Get.%C (%C.7d7) = splice_block %B.ref [template = %.loc18_12.4 (constants.%.85d25b.2)] {
// CHECK:STDOUT:       %.loc18_12.2: @Outer.Get.%C (%C.7d7) = specific_constant @C.%.loc9_3.5, @C(constants.%T.67db0b.1) [template = %.loc18_12.4 (constants.%.85d25b.2)]
// CHECK:STDOUT:       %B.ref: @Outer.Get.%C (%C.7d7) = name_ref B, %.loc18_12.2 [template = %.loc18_12.4 (constants.%.85d25b.2)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %int_1.loc18: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:     %impl.elem0.loc18_15.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:     %bound_method.loc18_15.1: <bound method> = bound_method %int_1.loc18, %impl.elem0.loc18_15.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:     %specific_fn.loc18_15.1: <specific function> = specific_function %impl.elem0.loc18_15.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:     %bound_method.loc18_15.2: <bound method> = bound_method %int_1.loc18, %specific_fn.loc18_15.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc18_15: init %u1 = call %bound_method.loc18_15.2(%int_1.loc18) [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc18_15.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc18_15 [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc18_15.2: %u1 = converted %int_1.loc18, %.loc18_15.1 [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc18_15.3: ref %u1 = class_element_access %c.ref.loc17, element0
// CHECK:STDOUT:     %impl.elem0.loc18_15.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:     %bound_method.loc18_15.3: <bound method> = bound_method %.loc18_15.2, %impl.elem0.loc18_15.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.22c]
// CHECK:STDOUT:     %specific_fn.loc18_15.2: <specific function> = specific_function %impl.elem0.loc18_15.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:     %bound_method.loc18_15.4: <bound method> = bound_method %.loc18_15.2, %specific_fn.loc18_15.2 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:     %.loc18_15.4: %u1 = acquire_value %.loc18_15.3
// CHECK:STDOUT:     %UInt.as.EqWith.impl.Equal.call.loc18: init bool = call %bound_method.loc18_15.4(%.loc18_15.2, %.loc18_15.4)
// CHECK:STDOUT:     %.loc18_15.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc18
// CHECK:STDOUT:     %.loc18_15.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc18, %.loc18_15.5
// CHECK:STDOUT:     if %.loc18_15.6 br !match.case.then.loc18 else br !match.case.else.loc18
// CHECK:STDOUT:
// CHECK:STDOUT:   !match.case.then.loc18:
// CHECK:STDOUT:     %int_0.loc18: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:     %impl.elem0.loc18_28: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:     %bound_method.loc18_28.1: <bound method> = bound_method %int_0.loc18, %impl.elem0.loc18_28 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:     %specific_fn.loc18_28: <specific function> = specific_function %impl.elem0.loc18_28, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:     %bound_method.loc18_28.2: <bound method> = bound_method %int_0.loc18, %specific_fn.loc18_28 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc18_28: init %i32 = call %bound_method.loc18_28.2(%int_0.loc18) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:     %.loc18_28: init %i32 = converted %int_0.loc18, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc18_28 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:     %.loc13_5.2: type = type_of_inst %.loc13_5.16 [template = %.loc13_5.17 (constants.%.8cb5e6.1)]
// CHECK:STDOUT:     %.loc13_5.3: @Outer.Get.%.loc13_5.17 (%.8cb5e6.1) = splice_inst %.loc13_5.16 [template = %.loc13_5.18 (constants.%.c234ea.1)]
// CHECK:STDOUT:     %.loc13_5.4: type = type_of_inst %.loc13_5.19 [template = %.loc13_5.20 (constants.%.57c638.1)]
// CHECK:STDOUT:     %.loc13_5.5: @Outer.Get.%.loc13_5.20 (%.57c638.1) = splice_inst %.loc13_5.19 [template = %.loc13_5.21 (constants.%.e63d45.1)]
// CHECK:STDOUT:     return %.loc18_28
// CHECK:STDOUT:
// CHECK:STDOUT:   !match.case.else.loc18:
// CHECK:STDOUT:     name_binding_decl {
// CHECK:STDOUT:       %_.patt.loc19_16.1: @Outer.Get.%pattern_type.loc12 (%pattern_type.51d1c4.1) = value_binding_pattern _ [template = %_.patt.loc19_16.2 (constants.%_.patt.ee9)]
// CHECK:STDOUT:       %.loc19_16.1: @Outer.Get.%pattern_type.loc19 (%pattern_type.b26) = tuple_pattern (%_.patt.loc19_16.1) [template = %.loc19_16.2 (constants.%.0bf)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %int_0.loc19: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:     %impl.elem0.loc19_21.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:     %bound_method.loc19_21.1: <bound method> = bound_method %int_0.loc19, %impl.elem0.loc19_21.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:     %specific_fn.loc19_21.1: <specific function> = specific_function %impl.elem0.loc19_21.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:     %bound_method.loc19_21.2: <bound method> = bound_method %int_0.loc19, %specific_fn.loc19_21.1 [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc19_21: init %u1 = call %bound_method.loc19_21.2(%int_0.loc19) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:     %.loc19_21.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc19_21 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:     %.loc19_21.2: %u1 = converted %int_0.loc19, %.loc19_21.1 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:     %.loc19_21.3: ref %u1 = class_element_access %c.ref.loc17, element0
// CHECK:STDOUT:     %impl.elem0.loc19_21.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:     %bound_method.loc19_21.3: <bound method> = bound_method %.loc19_21.2, %impl.elem0.loc19_21.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.f34]
// CHECK:STDOUT:     %specific_fn.loc19_21.2: <specific function> = specific_function %impl.elem0.loc19_21.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:     %bound_method.loc19_21.4: <bound method> = bound_method %.loc19_21.2, %specific_fn.loc19_21.2 [concrete = constants.%bound_method.53a]
// CHECK:STDOUT:     %.loc19_21.4: %u1 = acquire_value %.loc19_21.3
// CHECK:STDOUT:     %UInt.as.EqWith.impl.Equal.call.loc19: init bool = call %bound_method.loc19_21.4(%.loc19_21.2, %.loc19_21.4)
// CHECK:STDOUT:     %.loc19_21.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc19
// CHECK:STDOUT:     %.loc19_21.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc19, %.loc19_21.5
// CHECK:STDOUT:     if %.loc19_21.6 br !match.case.then.loc19 else br !match.case.else.loc19
// CHECK:STDOUT:
// CHECK:STDOUT:   !match.case.then.loc19:
// CHECK:STDOUT:     %.loc19_21.7: ref @Outer.Get.%.loc19_21.10 (%.964) = class_element_access %c.ref.loc17, element1
// CHECK:STDOUT:     %.loc19_21.8: ref @Outer.Get.%tuple.type (%tuple.type.026) = class_element_access %.loc19_21.7, element0
// CHECK:STDOUT:     %tuple.elem0.loc19: ref @Outer.Get.%T (%T.67db0b.1) = tuple_access %.loc19_21.8, element0
// CHECK:STDOUT:     %.loc19_21.9: @Outer.Get.%T (%T.67db0b.1) = acquire_value %tuple.elem0.loc19
// CHECK:STDOUT:     %T.ref.loc19: type = name_ref T, @Outer.%T.loc5_23.2 [template = %T (constants.%T.67db0b.1)]
// CHECK:STDOUT:     %_: @Outer.Get.%T (%T.67db0b.1) = wrapper_binding _, %.loc19_21.9
// CHECK:STDOUT:     %int_1.loc19: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:     %impl.elem0.loc19_34: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:     %bound_method.loc19_34.1: <bound method> = bound_method %int_1.loc19, %impl.elem0.loc19_34 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:     %specific_fn.loc19_34: <specific function> = specific_function %impl.elem0.loc19_34, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:     %bound_method.loc19_34.2: <bound method> = bound_method %int_1.loc19, %specific_fn.loc19_34 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc19_34: init %i32 = call %bound_method.loc19_34.2(%int_1.loc19) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:     %.loc19_34: init %i32 = converted %int_1.loc19, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc19_34 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:     %.loc13_5.6: type = type_of_inst %.loc13_5.22 [template = %.loc13_5.23 (constants.%.8cb5e6.2)]
// CHECK:STDOUT:     %.loc13_5.7: @Outer.Get.%.loc13_5.23 (%.8cb5e6.2) = splice_inst %.loc13_5.22 [template = %.loc13_5.24 (constants.%.c234ea.2)]
// CHECK:STDOUT:     %.loc13_5.8: type = type_of_inst %.loc13_5.25 [template = %.loc13_5.26 (constants.%.57c638.2)]
// CHECK:STDOUT:     %.loc13_5.9: @Outer.Get.%.loc13_5.26 (%.57c638.2) = splice_inst %.loc13_5.25 [template = %.loc13_5.27 (constants.%.e63d45.2)]
// CHECK:STDOUT:     return %.loc19_34
// CHECK:STDOUT:
// CHECK:STDOUT:   !match.case.else.loc19:
// CHECK:STDOUT:     br !match.done
// CHECK:STDOUT:
// CHECK:STDOUT:   !match.done:
// CHECK:STDOUT:     %int_1.loc21: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:     %impl.elem1: %.758 = impl_witness_access constants.%Negate.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:     %bound_method.loc21_12: <bound method> = bound_method %int_1.loc21, %impl.elem1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op.bound]
// CHECK:STDOUT:     %Core.IntLiteral.as.Negate.impl.Op.call: init Core.IntLiteral = call %bound_method.loc21_12(%int_1.loc21) [concrete = constants.%int_-1.638]
// CHECK:STDOUT:     %impl.elem0.loc21: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:     %bound_method.loc21_14.1: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %impl.elem0.loc21 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.65e]
// CHECK:STDOUT:     %specific_fn.loc21: <specific function> = specific_function %impl.elem0.loc21, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:     %bound_method.loc21_14.2: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %specific_fn.loc21 [concrete = constants.%bound_method.a65]
// CHECK:STDOUT:     %.loc21_12.1: Core.IntLiteral = value_of_initializer %Core.IntLiteral.as.Negate.impl.Op.call [concrete = constants.%int_-1.638]
// CHECK:STDOUT:     %.loc21_12.2: Core.IntLiteral = converted %Core.IntLiteral.as.Negate.impl.Op.call, %.loc21_12.1 [concrete = constants.%int_-1.638]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc21: init %i32 = call %bound_method.loc21_14.2(%.loc21_12.2) [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:     %.loc21_14: init %i32 = converted %Core.IntLiteral.as.Negate.impl.Op.call, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc21 [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:     %.loc13_5.10: type = type_of_inst %.loc13_5.28 [template = %.loc13_5.29 (constants.%.8cb5e6.3)]
// CHECK:STDOUT:     %.loc13_5.11: @Outer.Get.%.loc13_5.29 (%.8cb5e6.3) = splice_inst %.loc13_5.28 [template = %.loc13_5.30 (constants.%.c234ea.3)]
// CHECK:STDOUT:     %.loc13_5.12: type = type_of_inst %.loc13_5.31 [template = %.loc13_5.32 (constants.%.57c638.3)]
// CHECK:STDOUT:     %.loc13_5.13: @Outer.Get.%.loc13_5.32 (%.57c638.3) = splice_inst %.loc13_5.31 [template = %.loc13_5.33 (constants.%.e63d45.3)]
// CHECK:STDOUT:     return %.loc21_14
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc13_5.1(%self.param: ref %u1) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc13_5.1(%self.param: ref %u1) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc13_5.1(%self.param: ref %u1) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.1(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.1(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc13_5.2(%self.param: ref %i32) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc13_5.2(%self.param: ref %i32) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc13_5.2(%self.param: ref %i32) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.2(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.2(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc13_5.3(%self.param: ref %tuple.type.a8a) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %tuple.elem0: ref %i32 = tuple_access %self.param, element0
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound: <bound method> = bound_method %tuple.elem0, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound(%tuple.elem0)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc13_5.3(%self.param: ref %tuple.type.a8a) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc13_5.3(%self.param: ref %tuple.type.a8a) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.3(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.3(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc13_5.4(%self.param: ref %.39a) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc13_5.4(%self.param: ref %.39a) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc13_5.4(%self.param: ref %.39a) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.4(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.4(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc13_5.5(%self.param: ref %struct_type.discriminant.payload.913) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %.loc13_5.1: ref %.39a = struct_access %self.param, element1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc13_5.1: <bound method> = bound_method %.loc13_5.1, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.4
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc13_5.1: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc13_5.1(%.loc13_5.1)
// CHECK:STDOUT:   %.loc13_5.2: ref %u1 = struct_access %self.param, element0
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc13_5.2: <bound method> = bound_method %.loc13_5.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc13_5.2: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc13_5.2(%.loc13_5.2)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc13_5.5(%self.param: ref %struct_type.discriminant.payload.913) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc13_5.5(%self.param: ref %struct_type.discriminant.payload.913) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.5(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.5(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc13_5.6(%self.param: ref %C.b7f) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc13_5.6(%self.param: ref %C.b7f) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc13_5.6(%self.param: ref %C.b7f) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.6(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.6(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Outer(constants.%T.67db0b.1) {
// CHECK:STDOUT:   %T.patt.loc5_23.2 => constants.%T.patt.3a0592.1
// CHECK:STDOUT:   %T.loc5_23.1 => constants.%T.67db0b.1
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %C => constants.%C.7d7
// CHECK:STDOUT:   %Outer.Get.type => constants.%Outer.Get.type.53c
// CHECK:STDOUT:   %Outer.Get => constants.%Outer.Get.1cd
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Outer.Get(constants.%T.67db0b.1) {
// CHECK:STDOUT:   %T => constants.%T.67db0b.1
// CHECK:STDOUT:   %pattern_type.loc12 => constants.%pattern_type.51d1c4.1
// CHECK:STDOUT:   %t.param_patt.loc12_11.2 => constants.%t.param_patt.513
// CHECK:STDOUT:   %t.patt.loc12_11.2 => constants.%t.patt.c64
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Outer(constants.%i32) {
// CHECK:STDOUT:   %T.patt.loc5_23.2 => constants.%T.patt.3a0592.1
// CHECK:STDOUT:   %T.loc5_23.1 => constants.%i32
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %C => constants.%C.b7f
// CHECK:STDOUT:   %Outer.Get.type => constants.%Outer.Get.type.ac9
// CHECK:STDOUT:   %Outer.Get => constants.%Outer.Get.dd6
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Outer.Get(constants.%i32) {
// CHECK:STDOUT:   %T => constants.%i32
// CHECK:STDOUT:   %pattern_type.loc12 => constants.%pattern_type.6b6
// CHECK:STDOUT:   %t.param_patt.loc12_11.2 => constants.%t.param_patt.91a
// CHECK:STDOUT:   %t.patt.loc12_11.2 => constants.%t.patt.e4b
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc12 => constants.%complete_type.f8a
// CHECK:STDOUT:   %C => constants.%C.b7f
// CHECK:STDOUT:   %require_complete.loc13 => constants.%complete_type.e44
// CHECK:STDOUT:   %pattern_type.loc13 => constants.%pattern_type.9d0
// CHECK:STDOUT:   %c.patt.loc13_10.2 => constants.%c.patt.69e
// CHECK:STDOUT:   %c.var_patt.loc13_5.2 => constants.%c.var_patt.e4b
// CHECK:STDOUT:   %.loc13_17.3 => constants.%inst.splice_block.426619.2
// CHECK:STDOUT:   %.loc13_17.4 => constants.%C.b7f
// CHECK:STDOUT:   %.loc13_17.5 => constants.%C.val.375
// CHECK:STDOUT:   %.loc13_5.14 => constants.%tuple.24243e.1
// CHECK:STDOUT:   %tuple.elem0.loc13 => constants.%inst.splice_block.426619.3
// CHECK:STDOUT:   %.loc13_5.15 => constants.%C.val.375
// CHECK:STDOUT:   %.loc15_12.3 => constants.%inst.splice_block.426619.4
// CHECK:STDOUT:   %.loc15_12.4 => constants.%C.A.type.23d
// CHECK:STDOUT:   %.loc15_12.5 => constants.%C.A.e9e
// CHECK:STDOUT:   %.loc15_16.3 => constants.%inst.splice_block.426619.5
// CHECK:STDOUT:   %.loc15_16.4 => constants.%C.b7f
// CHECK:STDOUT:   %.loc15_16.5 => <not constant>
// CHECK:STDOUT:   %.loc15_9.2 => constants.%tuple.24243e.2
// CHECK:STDOUT:   %tuple.elem0.loc15 => constants.%inst.splice_block.426619.6
// CHECK:STDOUT:   %.loc15_9.3 => <not constant>
// CHECK:STDOUT:   %.loc18_12.3 => constants.%inst.splice_block.426619.7
// CHECK:STDOUT:   %.loc18_12.4 => constants.%C.val.375
// CHECK:STDOUT:   %.loc13_5.16 => constants.%inst.splice_block.426619.8
// CHECK:STDOUT:   %.loc13_5.17 => <bound method>
// CHECK:STDOUT:   %.loc13_5.18 => <not constant>
// CHECK:STDOUT:   %.loc13_5.19 => constants.%inst.call.426619.1
// CHECK:STDOUT:   %.loc13_5.20 => constants.%empty_tuple.type
// CHECK:STDOUT:   %.loc13_5.21 => <not constant>
// CHECK:STDOUT:   %_.patt.loc19_16.2 => constants.%_.patt.bed
// CHECK:STDOUT:   %tuple.type => constants.%tuple.type.a8a
// CHECK:STDOUT:   %pattern_type.loc19 => constants.%pattern_type.e71
// CHECK:STDOUT:   %.loc19_16.2 => constants.%.91c8
// CHECK:STDOUT:   %.loc19_21.10 => constants.%.39a
// CHECK:STDOUT:   %.loc13_5.22 => constants.%inst.splice_block.426619.9
// CHECK:STDOUT:   %.loc13_5.23 => <bound method>
// CHECK:STDOUT:   %.loc13_5.24 => <not constant>
// CHECK:STDOUT:   %.loc13_5.25 => constants.%inst.call.426619.2
// CHECK:STDOUT:   %.loc13_5.26 => constants.%empty_tuple.type
// CHECK:STDOUT:   %.loc13_5.27 => <not constant>
// CHECK:STDOUT:   %.loc13_5.28 => constants.%inst.splice_block.426619.10
// CHECK:STDOUT:   %.loc13_5.29 => <bound method>
// CHECK:STDOUT:   %.loc13_5.30 => <not constant>
// CHECK:STDOUT:   %.loc13_5.31 => constants.%inst.call.426619.3
// CHECK:STDOUT:   %.loc13_5.32 => constants.%empty_tuple.type
// CHECK:STDOUT:   %.loc13_5.33 => <not constant>
// CHECK:STDOUT: }
// CHECK:STDOUT:
