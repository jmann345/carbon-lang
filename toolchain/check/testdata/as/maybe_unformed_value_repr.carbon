// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/as/maybe_unformed_value_repr.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/as/maybe_unformed_value_repr.carbon

// Fork (OP-2, fork/optional2/plan.md §4, W-171): removing `MaybeUnformed` from
// a value whose value representation differs from the result's goes through a
// reference (`value_as_ref`, then `acquire_value`); `MaybeUnformed(bool)` is
// passed by pointer and `bool` by copy. Where the two representations agree,
// or are unknown until a specific is lowered, the conversion is an
// `as_compatible` alone, and lowering converts the representation per specific
// (lower/testdata/builtins/maybe_unformed_value_repr.carbon).

// --- bool.carbon

library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn FromBool(m: Core.MaybeUnformed(bool)) -> bool { return m unsafe as bool; }
//@dump-sem-ir-end

// --- i32.carbon

library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn FromI32(m: Core.MaybeUnformed(i32)) -> i32 { return m unsafe as i32; }
//@dump-sem-ir-end

// --- generic.carbon

library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn Unwrap[T: Core.Copy & Core.Destroy](m: Core.MaybeUnformed(T)) -> T {
  return m unsafe as T;
}
//@dump-sem-ir-end
