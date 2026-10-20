// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE

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
    case .Nope => { return 0; }
    default => { return 1; }
  }
}

fn InIfLet[template T: type](s: Opt(T)) -> i32 {
  if (let .Nope = s) {
    return 0;
  }
  return 1;
}

fn InLetElse[template T: type](s: Opt(T)) -> i32 {
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
    case .None => { return 2; }
  }
  return 3;
}

// --- fail_int_never_matches.carbon
library "[[@TEST_NAME]]";

fn Kind[template N: Core.IntLiteral](x: Core.Int(N)) -> i32 {
  match (x) {
    case 1 => { return 1; }
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
  return Conv(p);
}

// --- fail_todo_scrutinee_template_type.carbon
library "[[@TEST_NAME]]";

// Proposal 2200's `match` on a dependent value (TR-13, DD-1 fixture X10).
fn Kind[template T: type](x: T) -> i32 {
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
    case Opt(T).None => { return 0; }
    default => { return 1; }
  }
}
