// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Control flow: matching — good switch equivalents
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   122
//   22
//   125
//
// `var` and `ref` case bindings (W-008 W8b), the storage-semantics half of
// the switch-equivalents bullet. Semantics per
// docs/design/pattern_matching.md, "Pattern match control flow": "the
// objects created by `var` patterns are not reused by multiple `case`s" —
// a `var` case binding is the arm's own copy, so mutating it leaves the
// scrutinee's original unchanged; a `ref` case binding instead aliases the
// scrutinee, which must itself be a durable reference ("Name binding
// patterns"), so a write through it is visible after the `match`. Runtime
// inputs go through RuntimeSeed(x) = x + 20 so the arms run against real
// runtime values, not constant folds. Expected values derived by hand:
// 2+20=22, 22+100=122 (copy printed, original still 22); 5+20=25,
// 25+100=125 (write through the alias observed after the match).

import Core library "io";

fn RuntimeSeed(x: i32) -> i32 { return x + 20; }

// `var`: the arm mutates its own copy; the original is unchanged.
fn MutateCopy() -> i32 {
  var x: i32 = RuntimeSeed(2);
  match (x) {
    case var a: i32 => { a = a + 100; Core.Print(a); }
    default => { return -1; }
  }
  return x;
}

// `ref`: the arm writes through the alias; the original changes.
fn MutateThroughRef() -> i32 {
  var y: i32 = RuntimeSeed(5);
  match (y) {
    case ref r: i32 => { r = r + 100; }
    default => { return -1; }
  }
  return y;
}

fn Run() -> i32 {
  // 122 printed inside the arm; 22 proves the original survived the copy's
  // mutation.
  Core.Print(MutateCopy());
  // 125 proves the write through the `ref` alias landed on the original.
  Core.Print(MutateThroughRef());
  // Exit-code belt (print-free helper only: MutateCopy prints in its arm).
  if (MutateThroughRef() != 125) { return 1; }
  return 0;
}
