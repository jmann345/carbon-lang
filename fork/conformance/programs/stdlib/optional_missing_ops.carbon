// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Stdlib: Optional
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   1
//
// Written test-first for the Optional bullet and un-SKIPped at OP-1
// (fork/optional/plan.md; working slices: optional_basic.carbon,
// optional_pointer_niche.carbon). `a == b` on two `Core.Optional(i32)` values
// is the conditional `Optional(T) as EqWith(Optional(T))` impl, which applies
// because `i32` is `Core.Eq` (core/prelude/types/optional.carbon; fork design
// F-015, docs/design/optional.md): both values hold 1, so they are equal.

import Core library "io";

fn Run() -> i32 {
  var a: Core.Optional(i32) = Core.Optional(i32).Some(1);
  var b: Core.Optional(i32) = Core.Optional(i32).Some(1);
  // `Optional(T) as EqWith(Optional(T))`: both hold 1.
  Core.Print(if a == b then 1 else 0);
  return 0;
}
