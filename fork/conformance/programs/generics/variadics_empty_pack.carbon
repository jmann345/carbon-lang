// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: Definition-checked variadics
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   7
//   1
//   2
//   9
//
// A statement expansion with a side effect runs once per element and never
// for an empty pack: "A statement of the form `...` statement is evaluated
// by executing statement N times" (docs/design/variadics.md, "Expressions
// and statements"). PrintAll() prints nothing, so the first line is the 7
// printed between the calls; PrintAll(1, 2) prints 1 then 2 in order; the
// second empty call prints nothing again; Forward() forwards an empty pack
// to PrintAll, which prints nothing, before the closing 9.

import Core library "io";

fn PrintAll(... each n: i32) {
  ... Core.Print(each n);
}

fn Forward(... each n: i32) {
  PrintAll(... each n);
}

fn Run() -> i32 {
  PrintAll();
  Core.Print(7);
  PrintAll(1, 2);
  PrintAll();
  Forward();
  Core.Print(9);
  return 0;
}
