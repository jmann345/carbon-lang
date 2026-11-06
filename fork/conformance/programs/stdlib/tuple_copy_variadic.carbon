// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Stdlib: tuple/array library parts
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   4
//   8
//   101
//   102
//   2
//   101
//   1
//   6
//   13
//   0
//
// A tuple whose element types are all `Core.Copy` is `Core.Copy` itself, by
// the prelude's variadic impl (core/prelude/copy.carbon), whatever its arity,
// and its `Op` copies each element once, in order, by the element's own
// `Copy` (docs/design/tuples.md, "Operations performed field-wise"). Dup
// requires `Core.Copy` and calls `Op`; binding a tuple with `let` copies
// nothing. A 4-tuple and a 5-tuple of mixed element types copy (4, then 8);
// a (Loud, Loud) copies each element once, printing 101 and 102, then its
// copy's second field, 2; a (Loud,) prints 101, then 1; a tuple of tuples
// copies through the same impl at each level (6); a 13-tuple copies (13),
// beyond any fixed set of hand-written impls; the empty tuple copies with no
// output, and then 0 is printed.

import Core library "io";

class Loud {
  var a: i32;
}

impl Loud as Core.Copy {
  fn Op(self) -> Self {
    Core.Print(100 + self.a);
    return {.a = self.a};
  }
}

fn Dup[T: Core.Copy](x: T) -> T {
  return x.(Core.Copy.Op)();
}

fn Run() -> i32 {
  let t: (i32, i32, i32, i32) = (1, 2, 3, 4);
  Core.Print(Dup(t).3);
  let f: (i32, i64, bool, i32, i32) = (5, 6, true, 7, 8);
  Core.Print(Dup(f).4);
  let l1: Loud = {.a = 1};
  let l2: Loud = {.a = 2};
  let p: (Loud, Loud) = (l1, l2);
  let q: (Loud, Loud) = Dup(p);
  Core.Print(q.1.a);
  let one: (Loud,) = (l1,);
  Core.Print(Dup(one).0.a);
  let n: ((i32, i32), (i32, i32, i32, i32)) = ((1, 2), (3, 4, 5, 6));
  Core.Print(Dup(n).1.3);
  let big: (i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) =
      (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13);
  Core.Print(Dup(big).12);
  let e: () = ();
  Dup(e);
  Core.Print(0);
  return 0;
}
