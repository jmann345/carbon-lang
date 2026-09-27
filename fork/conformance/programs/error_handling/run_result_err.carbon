// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Error handling: dedicated control flow constructs
// EXPECT-EXIT: 1
// EXPECT-STDOUT:
//   1
//
// The EH-A `Result` entry-point arbiter, failure path (fork/eh/plan.md
// §5.A.4; decision D10 of docs/design/error_handling.md, "Entry point"):
// `fn Run() -> Core.Result((), i32)` is a valid entry point, and an `.Err`
// propagated out of `Run` by `?` makes the process exit with code 1 after the
// runtime writes a diagnostic naming the error type to standard error
// ("carbon: `Main.Run` returned `.Err` of type `i32`; exiting with code 1" —
// stderr is not asserted by the runner; the message is pinned by
// toolchain/lower/testdata/main_run/return_result.carbon). `Fails(0)` is
// `.Err(7)` on the runtime-computed input `RuntimeSeed(-20)` = 0 (R16d), so
// the `?` takes the break path. Exit-code belt: the `Core.Print(2)` after
// the `?` must NOT run and the trailing `.Ok(())` must NOT exit 0 — a `?`
// that wrongly continued would print `2` and exit 0.

import Core library "io";

fn Fails(n: i32) -> Core.Result((), i32) {
  if (n == 0) { return Core.Result((), i32).Err(n + 7); }
  return Core.Result((), i32).Ok(());
}

fn RuntimeSeed(x: i32) -> i32 { return x + 20; }

fn Run() -> Core.Result((), i32) {
  Core.Print(1);
  Fails(RuntimeSeed(-20))?;
  Core.Print(2);
  return Core.Result((), i32).Ok(());
}
