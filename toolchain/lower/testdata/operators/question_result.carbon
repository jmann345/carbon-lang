// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/operators/question_result.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/operators/question_result.carbon
// CHECK:STDERR: {{.*}}/prelude/types/cpp/slice.carbon:69:9: error: cannot access member of interface `Destroy` in type `C.(CppContiguousRange.SizeType)` that does not implement that interface [MissingImplInMemberAccess]
// CHECK:STDERR:         self.Size().(ImplicitAs(u64).Convert)().(As(i64).Convert)());
// CHECK:STDERR:         ^~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: {{.*}}/prelude/types/cpp/slice.carbon:68:9: error: cannot access member of interface `Destroy` in type `C.(CppContiguousRange.DataType)` that does not implement that interface [MissingImplInMemberAccess]
// CHECK:STDERR:         self.Data().(CppDataPointer.Raw)(),
// CHECK:STDERR:         ^~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: {{.*}}/prelude/types/cpp/slice.carbon:64:1: error: orphan `impl` found; something in the self-type or constraint must be defined in the same file [ImplIsOrphan]
// CHECK:STDERR: impl forall [C: CppContiguous where .Element impls Copy & Destroy]
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:

// The postfix `?` desugar over the prelude `Core.Result(T, E)`, lowered (the
// operators/question.carbon shape with the user `MyResult` replaced by the
// prelude choice and its `final impl ... as Try`): the prelude `Branch`
// call materializing the `Core.ControlFlow(i32, i32)` carrier, the `i8`
// discriminant load compared against `Break`'s discriminant (1), the
// conditional branch, the break path's payload load + prelude `FromBreak`
// call + early `ret` through the return slot, and the continue path's
// payload load as the expression's value. `Unit` additionally lowers a
// `Core.Result((), i32)` — the zero-sized `Ok(())` payload (D-EH-2).

// --- propagate.carbon
library "[[@TEST_NAME]]";

fn Open(n: i32) -> Core.Result(i32, i32) {
  if (n > 0) { return Core.Result(i32, i32).Ok(n); }
  return Core.Result(i32, i32).Err(n);
}

fn Basic(n: i32) -> Core.Result(i32, i32) {
  var f: i32 = Open(n)?;
  return Core.Result(i32, i32).Ok(f + 1);
}

fn Chain(n: i32) -> Core.Result(i32, i32) {
  var t: i32 = Open(Open(n)?)?;
  return Core.Result(i32, i32).Ok(t);
}

// --- unit.carbon
library "[[@TEST_NAME]]";

fn Check(n: i32) -> Core.Result((), i32) {
  if (n > 0) { return Core.Result((), i32).Ok(()); }
  return Core.Result((), i32).Err(n);
}

fn Unit(n: i32) -> Core.Result((), i32) {
  Check(n)?;
  return Core.Result((), i32).Ok(());
}

