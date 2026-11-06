// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: Definition-checked variadics
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   3
//   1
//   50
//   0
//   3
//   0
//
// A pack of different types is forwarded with `... each y`, which deduces the
// callee's pack of types from the caller's (docs/design/variadics.md,
// "Typechecking pattern matches"): Forward(3 as i32, true, 50 as i32, false)
// passes its four elements to ShowAll, whose statement expansion prints each
// element's code in order, i32's code being its value and bool's 1 or 0: 3,
// 1, 50, 0. Forward() forwards an empty pack and prints nothing. Count adds
// One's result once per element, each call a specific of One for that
// element's type: Count(true, 2 as i32, false) is 3 and Count() is 0.

import Core library "io";

interface Show {
  fn Code(self) -> i32;
}

impl i32 as Show {
  fn Code(self) -> i32 { return self; }
}

impl bool as Show {
  fn Code(self) -> i32 {
    if (self) {
      return 1;
    }
    return 0;
  }
}

fn ShowAll[... each T: Show](... each x: each T) {
  ... Core.Print(each x.Code());
}

fn Forward[... each U: Show](... each y: each U) {
  ShowAll(... each y);
}

fn One[V: type](unused v: V) -> i32 {
  return 1;
}

fn Count[... each T: type](... each x: each T) -> i32 {
  var n: i32 = 0;
  ... n += One(each x);
  return n;
}

fn Run() -> i32 {
  Forward(3 as i32, true, 50 as i32, false);
  Forward();
  Core.Print(Count(true, 2 as i32, false));
  Core.Print(Count());
  return 0;
}
