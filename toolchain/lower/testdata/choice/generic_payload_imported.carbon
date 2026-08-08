// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --output=%t --output-last-input-only
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/choice/generic_payload_imported.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/choice/generic_payload_imported.carbon

// Risk R-4's falsifier as an artifact: the generic choice — and its
// dependent-layout sentinel — is declared in another library, and the
// specific is formed in THIS file, so the layout recompute must fire in the
// importing file: the payload region must lower as the recomputed `[8 x i8]`
// ((i32, i32), align 4). A stale import shows as a wrong region size here.

// --- plib.carbon
library "plib";

// CHECK:STDERR: plib.carbon:[[@LINE+7]]:1: error: cannot copy value of type `T` [CopyOfUncopyableType]
// CHECK:STDERR: choice Pair(T: type) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: plib.carbon:[[@LINE+4]]:1: note: type `T` does not implement interface `Core.Copy` [MissingImplInMemberAccessInContext]
// CHECK:STDERR: choice Pair(T: type) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
choice Pair(T: type) {
  Both(x: T, y: T),
  Neither
}

// --- use_imported.carbon
library "[[@TEST_NAME]]";

import library "plib";

fn Classify(p: Pair(i32)) -> i32 {
  match (p) {
    case .Neither => { return 0; }
    default => { return 1; }
  }
}

fn Run() -> i32 {
  // CHECK:STDERR: use_imported.carbon:[[@LINE+7]]:22: error: cannot implicitly convert expression of type `Pair(T)` to `Pair(i32)` [ConversionFailure]
  // CHECK:STDERR:   let b: Pair(i32) = Pair(i32).Both(1, 2);
  // CHECK:STDERR:                      ^~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR: use_imported.carbon:[[@LINE+4]]:22: note: type `Pair(T)` does not implement interface `Core.ImplicitAs(Pair(i32))` [MissingImplInMemberAccessInContext]
  // CHECK:STDERR:   let b: Pair(i32) = Pair(i32).Both(1, 2);
  // CHECK:STDERR:                      ^~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  let b: Pair(i32) = Pair(i32).Both(1, 2);
  return Classify(b);
}
