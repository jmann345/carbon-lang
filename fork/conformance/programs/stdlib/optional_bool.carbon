// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Stdlib: Optional
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   1
//   1
//   0
//   1
//   0
//   1
//   0
//
// Write-tests-first program for `Core.Optional(bool)`, which fork design F-015
// (docs/design/optional.md) gives the same API and comparisons as every other
// `Core.Optional(T)`. Expected, from F-015's rules: `Some(true)` holds a value
// (1) and reads back as `true` (1); `Some(false)` reads back as `false` (0); a
// copy of `Some(true)` reads back as `true` (1); the empty value holds none
// (0); `Some(true) == Some(true)` (1); `Some(true) == Some(false)` (0). W-171
// landed at OP-2 (fork/optional2/plan.md), and the body is unchanged.

import Core library "io";

fn B(b: bool) -> i32 { return if b then 1 else 0; }

fn Run() -> i32 {
  let yes: Core.Optional(bool) = Core.Optional(bool).Some(true);
  let no: Core.Optional(bool) = Core.Optional(bool).Some(false);
  let none: Core.Optional(bool) = Core.Optional(bool).None();
  Core.Print(B(yes.HasValue()));
  Core.Print(B(yes.Get()));
  Core.Print(B(no.Get()));
  var copy: Core.Optional(bool) = yes;
  Core.Print(B(copy.Get()));
  Core.Print(B(none.HasValue()));
  Core.Print(B(yes == Core.Optional(bool).Some(true)));
  Core.Print(B(yes == no));
  return 0;
}
