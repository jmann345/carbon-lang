// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/main_run/return_result.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/main_run/return_result.carbon

// The `Result`-returning entry point, lowered (decision D10 of docs/design/
// error_handling.md, "Entry point"; fork/eh/plan.md §2.A.5): `define i32
// @main()` with ZERO parameters (no `sret`, no `ptr` — the SemIR return
// parameter is ignored, not lowered), the `Core.Result` return slot as a
// local `alloca` in the entry block, and at every `return` the epilogue:
// `load i8` of the discriminant, `icmp eq ... 0`, a branch to `run.result.ok`
// (`ret i32 0` for `Ok(())`, the `i32` payload load for `Ok(code)`) or
// `run.result.err` (`call i64 @write(i32 2, ptr @main.result.err.message,
// i64 <len>)` — `declare i64 @write(i32, ptr, i64)` — then `ret i32 1`). The
// `?` in `unit_ok` adds a second `return` sharing the one message global.

// --- unit_ok.carbon
library "[[@TEST_NAME]]";

fn Fails(n: i32) -> Core.Result((), i32) {
  return Core.Result((), i32).Err(n);
}

fn Run() -> Core.Result((), i32) {
  Fails(7)?;
  return Core.Result((), i32).Ok(());
}

// --- i32_ok.carbon
library "[[@TEST_NAME]]";

fn Run() -> Core.Result(i32, i32) {
  return Core.Result(i32, i32).Ok(3);
}
