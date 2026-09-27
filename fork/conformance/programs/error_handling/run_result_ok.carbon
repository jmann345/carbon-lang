// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Error handling: dedicated control flow constructs
// EXPECT-EXIT: 3
// EXPECT-STDOUT:
//   21
//   20
//
// The EH-A `Result` entry-point arbiter, success path (fork/eh/plan.md
// §5.A.3; decision D10 of docs/design/error_handling.md, "Entry point"):
// `fn Run() -> Core.Result(i32, i32)` is a valid entry point, `?` is usable
// inside `Run` itself, and `.Ok(code)` makes `code` the process exit code —
// lowering gives `Run` the C ABI `i32 main()` and derives the exit code from
// the returned alternative (toolchain/lower/handle.cpp). Both `?` sites take
// the continue path on even runtime-computed inputs (R16d): Half(42) = 21
// and Half(40) = 20 are printed, then `.Ok(RuntimeSeed(-17))` = `.Ok(3)`
// exits 3. Exit-code belt: a `?` that wrongly broke would exit 1 (the
// `.Err` epilogue) with a shorter stdout.

import Core library "io";

fn Half(n: i32) -> Core.Result(i32, i32) {
  if ((n / 2) * 2 == n) { return Core.Result(i32, i32).Ok(n / 2); }
  return Core.Result(i32, i32).Err(n);
}

fn RuntimeSeed(x: i32) -> i32 { return x + 20; }

fn Run() -> Core.Result(i32, i32) {
  var h: i32 = Half(RuntimeSeed(22))?;
  Core.Print(h);
  var q: i32 = Half(RuntimeSeed(20))?;
  Core.Print(q);
  return Core.Result(i32, i32).Ok(RuntimeSeed(-17));
}
