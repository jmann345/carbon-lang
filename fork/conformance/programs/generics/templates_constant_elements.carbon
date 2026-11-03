// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: Integrated templates
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   41
//   42
//   43
//   41
//   41
//   423
//   34
//   41
//   42
//
// Proposal 2200 ("Use of dependent value is dependent"): an initializer whose
// elements mix a template-dependent value with a constant initializes every
// element, as the same initializer does without a template (TP-1, the
// implementation-review fold). Each line prints the first element times 10
// plus the second: `(x, 1)` returned, `{.a = x, .b = 2}` returned and
// `(x, 3)` returned as an array, with x = 4, give 41, 42 and 43; a `var` of
// `(x, 1)` gives 41; a `var` initialized with `(x, 9)` and then assigned
// `(x, 1)` gives 41; `((x, 2), 3)` prints its three elements as 423; a
// template value `N = 3` beside the runtime 4 gives 34; a class `P(T)`
// returned from `{.a = x, .b = 1}` gives 41, and a `var` of `P(T)` from
// `{.a = x, .b = 2}` gives 42.

import Core library "io";

class P(T: type) {
  var a: T;
  var b: T;
}

fn RetTuple[template T: type](x: T) -> (T, T) {
  return (x, 1);
}

fn RetStruct[template T: type](x: T) -> {.a: T, .b: T} {
  return {.a = x, .b = 2};
}

fn RetArray[template T: type](x: T) -> array(T, 2) {
  return (x, 3);
}

fn VarTuple[template T: type](x: T) -> T {
  var p: (T, T) = (x, 1);
  return p.0 * 10 + p.1;
}

fn Assign[template T: type](x: T, y: T) -> (T, T) {
  var t: (T, T) = (x, y);
  t = (x, 1);
  return t;
}

fn Nested[template T: type](x: T) -> ((T, T), T) {
  return ((x, 2), 3);
}

fn Value(template N: i32, x: i32) -> (i32, i32) {
  return (N, x);
}

fn RetClass[template T: type](x: T) -> P(T) {
  return {.a = x, .b = 1};
}

fn VarClass[template T: type](x: T) -> T {
  var p: P(T) = {.a = x, .b = 2};
  return p.a * 10 + p.b;
}

fn Run() -> i32 {
  let t: (i32, i32) = RetTuple(4 as i32);
  Core.Print(t.0 * 10 + t.1);
  let s: {.a: i32, .b: i32} = RetStruct(4 as i32);
  Core.Print(s.a * 10 + s.b);
  let a: array(i32, 2) = RetArray(4 as i32);
  Core.Print(a[0] * 10 + a[1]);
  Core.Print(VarTuple(4 as i32));
  let u: (i32, i32) = Assign(4 as i32, 9 as i32);
  Core.Print(u.0 * 10 + u.1);
  let n: ((i32, i32), i32) = Nested(4 as i32);
  Core.Print(n.0.0 * 100 + n.0.1 * 10 + n.1);
  let v: (i32, i32) = Value(3, 4);
  Core.Print(v.0 * 10 + v.1);
  let c: P(i32) = RetClass(4 as i32);
  Core.Print(c.a * 10 + c.b);
  Core.Print(VarClass(4 as i32));
  return 0;
}
