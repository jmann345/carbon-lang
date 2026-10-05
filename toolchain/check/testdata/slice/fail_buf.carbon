// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/slice/fail_buf.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/slice/fail_buf.carbon

// Fork (SL-1, fork/slices/plan.md §4.A): the pinned 0.1 limits of
// `Core.Buf(T)` (D-SL-6).

// --- fail_copy.carbon

library "[[@TEST_NAME]]";

// `Buf` has no `Copy` impl, so a copy is a compile error, never a double
// free. Predicted `CopyOfUncopyableType` "cannot copy value of type
// `Core.Buf(i32)`" with the `MissingImplInMemberAccessInContext` note "type
// `Core.Buf(i32)` does not implement interface `Core.Copy`".
fn C(b: Core.Buf(i32)) {
  var c: Core.Buf(i32) = b;
}

// --- fail_unformed.carbon

library "[[@TEST_NAME]]";

// `Buf` is not `UnformedInit`: `Destroy` runs unconditionally on `var`
// storage, so an unformed `Buf` would free a garbage pointer. Predicted
// `ConversionFailureTypeToFacet` "cannot convert type `Core.Buf(i32)` into
// type implementing `Core.DefaultOrUnformed`".
fn U() {
  var b: Core.Buf(i32);
}
