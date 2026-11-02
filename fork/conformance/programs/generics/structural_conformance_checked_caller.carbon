// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: Template-style structural conformance to nominal constraints
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   7
//
// A checked generic calls a template-constrained function (leads issue 2153:
// "We have decided to support passing a symbolic constant to a template
// parameter", docs/design/generics/overview.md). The call is an ordinary call
// in `Caller`; `HasGet`'s member requirement is checked in each specific of
// `Caller`, where `U` is `C`, whose own `Get` satisfies `HasGet` structurally
// (fork decision F-010). Expected: `Caller(c)` returns `CallGet(c)`, which
// returns `c.Get()`, `c.v`, 7.

import Core library "io";

template constraint HasGet {
  fn Get(self) -> i32;
}

fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }

fn Caller[U: type](x: U) -> i32 { return CallGet(x); }

class C {
  var v: i32;
  fn Get(self) -> i32 { return self.v; }
}

fn Run() -> i32 {
  let c: C = {.v = 7};
  Core.Print(Caller(c));
  return 0;
}
