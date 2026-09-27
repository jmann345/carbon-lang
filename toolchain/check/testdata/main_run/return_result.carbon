// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/main_run/return_result.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/main_run/return_result.carbon

// The `Result` entry-point shapes of decision D10 (docs/design/
// error_handling.md, "Entry point"; fork/eh/plan.md §1.A.5):
// `IsValidEntryPointReturnType` accepts a `Core.Result(T, E)` specific whose
// success type is exactly `()` or `i32`, for any `E`, so `?` is usable in
// `Run` itself. The success type is matched by `TypeId` equality like the
// plain `-> i32` shape — `fail_adapter_success_type` pins that an adapter
// over `i32` is rejected in the `Result` position exactly as `-> Adapter`
// is rejected today. Lowering (lower/testdata/main_run/return_result.carbon)
// gives these functions the C ABI `i32 main()` and the exit-code epilogue.

// --- unit_ok.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn Run() -> Core.Result((), i32) {
  return Core.Result((), i32).Ok(());
}
//@dump-sem-ir-end

// --- i32_ok.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn Run() -> Core.Result(i32, i32) {
  return Core.Result(i32, i32).Ok(3);
}
//@dump-sem-ir-end

// --- with_question.carbon
library "[[@TEST_NAME]]";

fn Fails(n: i32) -> Core.Result((), i32) {
  return Core.Result((), i32).Err(n);
}

//@dump-sem-ir-begin
fn Run() -> Core.Result((), i32) {
  Fails(7)?;
  return Core.Result((), i32).Ok(());
}
//@dump-sem-ir-end

// --- fail_bad_success_type.carbon
library "[[@TEST_NAME]]";

// Only `()` and `i32` are D10 success types.
fn Run() -> Core.Result(i64, i32) {
  return Core.Result(i64, i32).Ok(0);
}

// --- fail_non_result_class.carbon
library "[[@TEST_NAME]]";

class C {
  var x: i32;
}

fn Run() -> C {
  return {.x = 0};
}

// --- fail_adapter_success_type.carbon
library "[[@TEST_NAME]]";

// An adapter over `i32` is an SF-6-admissible payload, so the specific
// itself is fine; the entry-point check still rejects it, as it rejects the
// plain `fn Run() -> Code` shape.
class Code {
  adapt i32;
}

fn Run() -> Core.Result(Code, i32) {
  return Core.Result(Code, i32).Err(1);
}
