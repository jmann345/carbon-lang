// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Stdlib: Slices
// EXPECT-EXIT: -6
//
// The runtime bounds check of `Core.Slice(T)` (SL-1, fork/slices/plan.md
// §5.A.3; D-SL-4, D-SL-12). An out-of-bounds read fails-stop: one line on
// stderr (`carbon: Core.Slice index out of bounds; terminating`), then
// `abort()`. The authority is docs/design/safety/README.md:218-232 — bounds
// checking is part of the baseline hardening, and the debug build's
// fail-stop-with-diagnostics promise is adopted as the single 0.1 mode (the
// toolchain has no build modes) — with safety/terminology.md's definition of
// fail-stop. SIGABRT is 6 on Linux and macOS; the runner returns the
// subprocess `returncode` unmodified and compares it with `EXPECT-EXIT`
// (fork/conformance/runner.py:454-463, :587), and Python reports death by
// signal N as -N, so -6 is the whole observable. Deliberately no
// `EXPECT-STDOUT`: `abort()` does not flush stdio, so a checked stdout would
// be a false negative under a pipe (the cpp_exceptions_fence_terminate.carbon
// precedent). The `Core.Print(bad)` after the read makes a run that survives
// the violation fail loudly (exit 0 != -6 -> RUN-FAIL).
//
// Hand-derived expectation (R16(d)): `RuntimeSeed(-18)` is 2, `s.Size()` is 2,
// and `2 >= 2` takes the fail branch in `Slice.Get` before any output.

import Core library "io";

fn RuntimeSeed(x: i32) -> i32 { return x + 20; }

fn Run() -> i32 {
  var a: array(i32, 2) = (1, 2);
  let s: Core.Slice(i32) = Core.Slice(i32).FromArray(&a);
  // Index 2 on a two-element view: fails-stop before any output.
  let bad: i32 = s[RuntimeSeed(-18)];
  Core.Print(bad);
  return 0;
}
