// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --target=x86_64-linux-gnu
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/builtins/maybe_unformed_value_repr.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/builtins/maybe_unformed_value_repr.carbon

// Fork (OP-2, fork/optional2/plan.md §4, W-171): converting a value between
// `MaybeUnformed(T)` and `T`, whose value representations can differ, loads
// the value when the operand is passed by pointer and the result by copy, and
// stores it to a temporary in the other direction, concretely and in each
// specific of a generic.

// --- concrete.carbon

library "[[@TEST_NAME]]";

fn FromBool(m: Core.MaybeUnformed(bool)) -> bool { return m unsafe as bool; }

fn FromOptionalPointer(m: Core.MaybeUnformed(Core.Optional(i32*)))
    -> Core.Optional(i32*) {
  return m unsafe as Core.Optional(i32*);
}

fn RoundTrip(o: Core.Optional(i32*)) -> Core.Optional(i32*) {
  let m: Core.MaybeUnformed(Core.Optional(i32*)) =
      o unsafe as Core.MaybeUnformed(Core.Optional(i32*));
  return m unsafe as Core.Optional(i32*);
}

// --- generic.carbon

library "[[@TEST_NAME]]";

fn Unwrap[T: Core.Copy & Core.Destroy](m: Core.MaybeUnformed(T)) -> T {
  return m unsafe as T;
}

fn CallBool(m: Core.MaybeUnformed(bool)) -> bool { return Unwrap(m); }

fn CallI32(m: Core.MaybeUnformed(i32)) -> i32 { return Unwrap(m); }

fn CallOptionalPointer(m: Core.MaybeUnformed(Core.Optional(i32*)))
    -> Core.Optional(i32*) {
  return Unwrap(m);
}
