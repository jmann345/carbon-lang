// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/builtins/heap/allocate_free.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/builtins/heap/allocate_free.carbon

// Fork (SL-1, fork/slices/plan.md §4.A): the `heap.allocate` and `heap.free`
// builtins. `heap.allocate` names the element type through a `generic`
// parameter, which is not a call parameter, and returns
// `Core.MaybeUnformed(T*)` so that a failed allocation is testable with
// `pointer.is_null`.

// --- call.carbon

library "[[@TEST_NAME]]";

fn Alloc(generic T: type, n: i64) -> Core.MaybeUnformed(T*) = "heap.allocate";
fn Free[T: type](p: T*) = "heap.free";

//@dump-sem-ir-begin
fn F(n: i64) -> Core.MaybeUnformed(i32*) {
  return Alloc(i32, n);
}

fn G(p: i32*) {
  Free(p);
}
//@dump-sem-ir-end

// --- fail_allocate_plain_pointer.carbon

library "[[@TEST_NAME]]";

// Predicted: `InvalidBuiltinSignature` "invalid signature for builtin function
// \"heap.allocate\"" — the result must be `MaybeUnformed(T*)`, not `T*`.
fn Bad(generic T: type, n: i64) -> T* = "heap.allocate";

// --- fail_free_returns.carbon

library "[[@TEST_NAME]]";

// Predicted: `InvalidBuiltinSignature` "invalid signature for builtin function
// \"heap.free\"" — the builtin returns `()`.
fn Bad[T: type](p: T*) -> i32 = "heap.free";
