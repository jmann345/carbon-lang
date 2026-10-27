// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: Definition-checked variadics
// EXPECT-EXIT: 0
//
// Differential pair: variadics_hetero_digits_diff.diff.cpp computes the same
// values with C++17 function templates over parameter packs of different
// types, whose comma folds evaluate left to right as Carbon's statement
// expansions execute their bodies once per element in order
// (docs/design/variadics.md, "Execution Semantics"), so C++ is the oracle for
// every printed line (no EXPECT-STDOUT). Cat has the shape of the design's
// StrCat ("Additional examples"): a pack of different types that each
// implement a local interface, one expansion summing the elements' widths and
// a second appending each element's digits, so the elements' order is visible
// in the digits. Sum takes integers of three widths, each converted to i64 by
// its own type's conversion.

import Core library "io";

interface Digits {
  fn Width(self) -> i64;
  fn Value(self) -> i64;
}

class One {
  var v: i64;
}

impl One as Digits {
  fn Width(unused self) -> i64 { return 1; }
  fn Value(self) -> i64 { return self.v; }
}

class Two {
  var v: i64;
}

impl Two as Digits {
  fn Width(unused self) -> i64 { return 2; }
  fn Value(self) -> i64 { return self.v; }
}

fn Pow10(n: i64) -> i64 {
  var result: i64 = 1;
  var i: i64 = 0;
  while (i < n) {
    result = result * 10;
    i = i + 1;
  }
  return result;
}

fn Cat[... each T: Digits](... each d: each T) -> i64 {
  var width: i64 = 0;
  ... width += each d.Width();
  Core.Print(width as i32);
  var result: i64 = 0;
  ... result = result * Pow10(each d.Width()) + each d.Value();
  return result;
}

fn Sum[... each T: Core.ImplicitAs(i64)](... each x: each T) -> i64 {
  var total: i64 = 0;
  ... total += each x as i64;
  return total;
}

fn Run() -> i32 {
  let a: Two = {.v = 74};
  let b: One = {.v = 2};
  let c: Two = {.v = 7};
  let d: One = {.v = 4};
  let e: Two = {.v = 22};
  Core.Print(Cat(a, b, c, d) as i32);
  Core.Print(Cat(d, e) as i32);
  Core.Print(Cat() as i32);
  Core.Print(Sum(-7 as i8, 300 as i16, 40000 as i32) as i32);
  Core.Print(Sum(5 as i32) as i32);
  return 0;
}
