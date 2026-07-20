// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Stdlib: String and string-literal types
// SKIP: known-missing slice of this PARTIAL bullet: Core.String has no equality/concatenation impls and no owning variant (core/prelude/types/string.carbon is only Size/Copy/IndexWith); on the arbiter toolchain `a == b` on `str` fails with "error: cannot access member of interface `Core.EqWith(str)` in type `str` that does not implement that interface" and `a + b` fails with "error: cannot access member of interface `Core.AddWith(str)` in type `str` that does not implement that interface"
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   1
//   4
//
// Write-tests-first program for the missing slice of the String bullet
// (working slice: string_basic.carbon). Un-SKIP once `String as
// EqWith(String)` and `String as AddWith(String)` (or an owning string type)
// land in core/prelude/types/string.carbon. Both errors below were captured
// verbatim from carbon_toolchain-0.0.0-0.nightly.2026.07.19 `carbon compile`.

import Core library "io";

fn Run() -> i32 {
  let a: str = "hi";
  let b: str = "hi";
  // Missing: `String as EqWith(String)`.
  Core.Print(if a == b then 1 else 0);
  // Missing: `String as AddWith(String)` (concatenation).
  let c: str = a + b;
  Core.Print(c.Size() as i32);
  return 0;
}
