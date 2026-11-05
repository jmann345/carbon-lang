// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Stdlib: Optional
// SKIP: known-missing slice of this PARTIAL bullet (W-171): with OP-1 this program checks with no diagnostic and `carbon compile` then aborts in lowering (exit 134) at "Lowering function Copy(bool as Core.Copy & Core.Destroy)" (core/prelude/types/optional.carbon:172) with "CHECK failure at toolchain/lower/handle_call.cpp:984: args_ok: Argument mismatch: call ptr @"_CSome.5d6f3f3a4b44a8f1:OptionalStorage.Core.8ae0339be4ca7eba"(ptr %return, ptr %value1)"; without the copy, `Get()` and `==` abort with "Function return type does not match operand type of return inst!" and "CHECK failure at toolchain/lower/lower.cpp:48: !llvm::verifyModule(*module, options.llvm_verifier_stream)"; `Core.MaybeUnformed(bool)` and `bool` differ in value representation (toolchain/check/convert.cpp:1687-1704)
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
// (0); `Some(true) == Some(true)` (1); `Some(true) == Some(false)` (0). Un-SKIP
// when W-171 lands; the body then needs no change.

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
