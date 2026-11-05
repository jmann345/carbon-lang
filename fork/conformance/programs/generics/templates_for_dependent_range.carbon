// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: Integrated templates
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   6
//   10
//   12
//
// Proposal 2200: a `for` loop whose range depends on a template parameter is
// checked when the template is instantiated (TP-1; DD-1 fixture X28, which
// stopped the compiler). Sum over the array (1, 2, 3) is 6; CountUp over
// Core.Range(5), which yields 0 to 4 (core/prelude/range.carbon), is 10;
// SumMember over the member array (7, 2, 3) is 12.

import Core library "io";

class Counter {
  var n: i32;
}

class Wrapper {
  var a: array(i32, 3);
}

fn Sum[template T: type](a: T) -> i32 {
  var s: i32 = 0;
  for (x: i32 in a) {
    s += x;
  }
  return s;
}

fn CountUp[template T: type](c: T) -> i32 {
  var s: i32 = 0;
  for (x: i32 in Core.Range(c.n)) {
    s += x;
  }
  return s;
}

fn SumMember[template T: type](w: T) -> i32 {
  var s: i32 = 0;
  for (x: i32 in w.a) {
    s += x;
  }
  return s;
}

fn Run() -> i32 {
  let a: array(i32, 3) = (1, 2, 3);
  Core.Print(Sum(a));
  let c: Counter = {.n = 5};
  Core.Print(CountUp(c));
  let w: Wrapper = {.a = (7, 2, 3)};
  Core.Print(SumMember(w));
  return 0;
}
