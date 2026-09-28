// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/builtins/heap.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/builtins/heap.carbon

// Fork (SL-1, fork/slices/plan.md §4.A): `heap.allocate` lowers to
// `mul i64 %n, 4` (the element size), a zero guard (`select`), and
// `call ptr @malloc(i64 ...)`; `heap.free` lowers to `call void @free(ptr %p)`.

fn Alloc(generic T: type, n: i64) -> Core.MaybeUnformed(T*) = "heap.allocate";
fn Free[T: type](p: T*) = "heap.free";

fn A(n: i64) -> Core.MaybeUnformed(i32*) {
  return Alloc(i32, n);
}

fn Fr(p: i32*) {
  Free(p);
}
