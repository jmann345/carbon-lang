// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Control flow: matching — if-let / let-else combined match+declaration
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   42
//   0
//   7
//   99
//   1
//   98
//
// The combined match+declaration forms (W-012; fork decision F-011, Option A
// of fork/design-sprint/if-let.md; docs/design/pattern_matching.md,
// "Refutable pattern bindings"): if-let binds on pattern success with the
// binding scoped to the then-block; let-else binds in the enclosing scope
// or diverges through its `else` block; var-else gives mutable storage.
// Payload values go through RuntimeSeed(x) = x + 20 so the discriminant
// tests are real runtime compares, not constant folds.

import Core library "io";

choice OptInt {
  Some(x: i32),
  None
}

fn RuntimeSeed(x: i32) -> i32 { return x + 20; }

// if-let: bindings live in the then-block only.
fn Double(o: OptInt) -> i32 {
  if (let .Some(n: i32) = o) { return n * 2; } else { return 0; }
}

// let-else: `port` is in scope after the declaration.
fn PortOr99(o: OptInt) -> i32 {
  let .Some(port: i32) = o else { return 99; }
  return port;
}

// var-else: mutable storage after the declaration.
fn Bump(o: OptInt) -> i32 {
  var .Some(v: i32) = o else { return 98; }
  v = v + 1;
  return v;
}

fn Run() -> i32 {
  Core.Print(Double(OptInt.Some(RuntimeSeed(1))));      // (1+20)*2 = 42
  Core.Print(Double(OptInt.None));                       // 0
  Core.Print(PortOr99(OptInt.Some(RuntimeSeed(-13))));   // -13+20 = 7
  Core.Print(PortOr99(OptInt.None));                     // 99
  Core.Print(Bump(OptInt.Some(RuntimeSeed(-20))));       // 0+1 = 1
  Core.Print(Bump(OptInt.None));                         // 98
  if (Double(OptInt.Some(RuntimeSeed(1))) != 42) { return 1; }
  return 0;
}
