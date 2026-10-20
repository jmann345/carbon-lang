// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE

// Refutable patterns on a template-dependent choice value (TP-1 round 10,
// X-1; check/testdata/generic/template/match_choice.carbon): each specific
// compares its own discriminant and reads its payload at its own offset, and
// an integer of a template-dependent width compares at its own width.

// --- designator_arm.carbon
library "[[@TEST_NAME]]";

choice Opt(T: type) {
  Some(value: T),
  None
}

fn Get[template T: type](s: Opt(T), d: T) -> T {
  match (s) {
    case .None => { return d; }
    case .Some(n: T) => { return n; }
  }
  return d;
}

fn UseI8(s: Opt(i8), d: i8) -> i8 {
  return Get(s, d);
}

fn UseI64(s: Opt(i64), d: i64) -> i64 {
  return Get(s, d);
}

// --- class_template_choice.carbon
library "[[@TEST_NAME]]";

class Outer(template T: type) {
  choice C {
    A(n: T),
    B
  }

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
}

fn Use(x: i32) -> i32 {
  return Outer(i32).Get(x, true);
}

// --- let_else_payload.carbon
library "[[@TEST_NAME]]";

choice Opt(T: type) {
  Some(value: T),
  None
}

fn Unwrap[template T: type](s: Opt(T), d: T) -> T {
  let .Some(n: T) = s else { return d; }
  return n;
}

fn Use(s: Opt(i64), d: i64) -> i64 {
  return Unwrap(s, d);
}

// --- int_scrutinee.carbon
library "[[@TEST_NAME]]";

fn Kind[template N: Core.IntLiteral](x: Core.Int(N)) -> i32 {
  match (x) {
    case 1 => { return 1; }
    case -1 => { return 2; }
    default => { return 0; }
  }
}

fn UseI8(a: i8) -> i32 {
  return Kind(a);
}

fn UseI64(b: i64) -> i32 {
  return Kind(b);
}
