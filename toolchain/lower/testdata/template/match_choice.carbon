// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/template/match_choice.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/template/match_choice.carbon

// Refutable patterns on a template-dependent choice value (TP-1 round 10,
// X-1; check/testdata/generic/template/match_choice.carbon): each specific
// compares its own discriminant and reads its payload at its own offset, and
// an integer of a template-dependent width compares at its own width.

// --- fail_todo_designator_arm.carbon
library "[[@TEST_NAME]]";
// TODO: since TP-2 (W-374) `Opt(T)` is a deferred `call_action`, so a
// `match` on it reports the scrutinee TODO and nothing is lowered (fork work
// item W-397).

choice Opt(T: type) {
  Some(value: T),
  None
}

fn Get[template T: type](s: Opt(T), d: T) -> T {
  // CHECK:STDERR: fail_todo_designator_arm.carbon:[[@LINE+4]]:9: error: semantics TODO: `match on unsupported scrutinee type` [SemanticsTodo]
  // CHECK:STDERR:   match (s) {
  // CHECK:STDERR:         ^~~
  // CHECK:STDERR:
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

// --- fail_todo_let_else_payload.carbon
library "[[@TEST_NAME]]";
// TODO: as fail_todo_designator_arm (W-397).

choice Opt(T: type) {
  Some(value: T),
  None
}

fn Unwrap[template T: type](s: Opt(T), d: T) -> T {
  // CHECK:STDERR: fail_todo_let_else_payload.carbon:[[@LINE+4]]:21: error: semantics TODO: `refutable pattern binding on unsupported scrutinee type` [SemanticsTodo]
  // CHECK:STDERR:   let .Some(n: T) = s else { return d; }
  // CHECK:STDERR:                     ^
  // CHECK:STDERR:
  let .Some(n: T) = s else { return d; }
  return n;
}

fn Use(s: Opt(i64), d: i64) -> i64 {
  return Unwrap(s, d);
}

// --- fail_todo_int_scrutinee.carbon
library "[[@TEST_NAME]]";
// TODO: as fail_todo_designator_arm, for `Core.Int(N)` (W-397); `N` is
// not deduced through `Core.Int(N)` either (W-396), which the body's TODO
// hides.

fn Kind[template N: Core.IntLiteral](x: Core.Int(N)) -> i32 {
  // CHECK:STDERR: fail_todo_int_scrutinee.carbon:[[@LINE+4]]:9: error: semantics TODO: `match on unsupported scrutinee type` [SemanticsTodo]
  // CHECK:STDERR:   match (x) {
  // CHECK:STDERR:         ^~~
  // CHECK:STDERR:
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
