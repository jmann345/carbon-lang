// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: Definition-checked variadics
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   1
//   2
//   3
//   4
//   3
//   4
//
// A pack binds its arguments' values: "the Nth iteration of the pack
// expansion will initialize the Nth element of the named pack from the Nth
// scrutinee" (docs/design/variadics.md, "Pack expansion patterns"), and
// `each p: Plain` is a value binding, which only requires "the matched
// expression to be a value expression" (docs/design/values.md, "Binding
// patterns and local variables with `let` and `var`"), so it performs no
// copy initialization. Plain implements no Core.Copy, so binding it must not
// need one; Loud's Copy prints 100 plus its field, so a copy would print 103
// or 104. PrintPlain(p, q) prints 1 and 2; PrintLoud(l, m) prints 3 and 4 and
// nothing else; ForwardLoud(l, m) passes its pack on with `... each l`, which
// binds the same values again: 3 and 4.

import Core library "io";

class Plain {
  var a: i32;
}

class Loud {
  var a: i32;
}

impl Loud as Core.Copy {
  fn Op(self) -> Self {
    Core.Print(100 + self.a);
    return {.a = self.a};
  }
}

fn PrintPlain(... each p: Plain) {
  ... Core.Print(each p.a);
}

fn PrintLoud(... each l: Loud) {
  ... Core.Print(each l.a);
}

fn ForwardLoud(... each l: Loud) {
  PrintLoud(... each l);
}

fn Run() -> i32 {
  let p: Plain = {.a = 1};
  let q: Plain = {.a = 2};
  PrintPlain(p, q);
  let l: Loud = {.a = 3};
  let m: Loud = {.a = 4};
  PrintLoud(l, m);
  ForwardLoud(l, m);
  return 0;
}
