// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: Integrated templates
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   0
//   1
//   41
//   7
//   5
//   1
//   0
//   1
//   0
//   2
//   1
//   0
//
// Refutable patterns on a template-dependent choice value (TP-1 round 10,
// X-1): `Opt(T)` and `Shape(T)` are generic choices applied to a template
// parameter, and `Box(T).State` is a choice declared in a class template.
// Count of a `None` is 0 and of a `Some` is 1. Unwrap of `Some(41)` is its
// payload, 41; of a `None` with the default 7 it is 7 (an i64, printed as
// i32). Width of `Rect(5, 2)` is the `w` payload, 5; of `Circle(3)` it is 1;
// of `Empty` it is 0. Box(i32).Fill with `full` true holds `Full`, 1;
// Box(i64).Fill with `full` false holds `Empty`, 0. `Core.Int(N)` for a
// template `N` is an integer scrutinee of the instantiation's width: Small of
// an i8 2 is 2, of an i64 1 is 1 and of an i32 5 is 0 (the `default` arm).

import Core library "io";

choice Opt(T: type) {
  Some(value: T),
  None
}

choice Shape(T: type) {
  Circle(r: T),
  Rect(w: i32, h: T),
  Empty
}

fn Count[template T: type](s: Opt(T)) -> i32 {
  match (s) {
    case .None => { return 0; }
    case .Some(_: T) => { return 1; }
  }
  return -1;
}

fn Unwrap[template T: type](s: Opt(T), d: T) -> T {
  let .Some(n: T) = s else { return d; }
  return n;
}

fn Width[template T: type](s: Shape(T)) -> i32 {
  match (s) {
    case .Empty => { return 0; }
    case .Circle(_: T) => { return 1; }
    case .Rect(w: i32, _: T) => { return w; }
  }
  return -1;
}

class Box(template T: type) {
  choice State {
    Full(v: T),
    Empty
  }

  fn Fill(t: T, full: bool) -> i32 {
    var s: State = State.Empty;
    if (full) {
      s = State.Full(t);
    }
    match (s) {
      case .Empty => { return 0; }
      case .Full(_: T) => { return 1; }
    }
    return -1;
  }
}

fn Small[template N: Core.IntLiteral](x: Core.Int(N)) -> i32 {
  match (x) {
    case 1 => { return 1; }
    case 2 => { return 2; }
    default => { return 0; }
  }
}

fn Run() -> i32 {
  let a: i32 = 41;
  let b: i64 = 7;
  let none_i32: Opt(i32) = Opt(i32).None;
  let some_i64: Opt(i64) = Opt(i64).Some(b);
  Core.Print(Count(none_i32));
  Core.Print(Count(some_i64));

  let some_i32: Opt(i32) = Opt(i32).Some(a);
  let none_i64: Opt(i64) = Opt(i64).None;
  Core.Print(Unwrap(some_i32, 0 as i32));
  Core.Print(Unwrap(none_i64, b) as i32);

  let two: i64 = 2;
  let rect: Shape(i64) = Shape(i64).Rect(5, two);
  let circle: Shape(i32) = Shape(i32).Circle(3);
  let empty: Shape(i32) = Shape(i32).Empty;
  Core.Print(Width(rect));
  Core.Print(Width(circle));
  Core.Print(Width(empty));

  Core.Print(Box(i32).Fill(a, true));
  Core.Print(Box(i64).Fill(b, false));

  let c: i8 = 2;
  let d: i64 = 1;
  let e: i32 = 5;
  Core.Print(Small(c));
  Core.Print(Small(d));
  Core.Print(Small(e));
  return 0;
}
