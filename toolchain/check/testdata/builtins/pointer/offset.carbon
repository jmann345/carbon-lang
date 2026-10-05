// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/int.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/builtins/pointer/offset.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/builtins/pointer/offset.carbon

// Fork (SL-1, fork/slices/plan.md §4.A): the `pointer.offset` builtin, plus the
// two isolating symbolic-pointer shapes of risk R-4 (`Load`: a value read
// through a `Deref` of symbolic `T` goes through the `Copy` witness; `Store`:
// an assignment into a `Deref` of symbolic `T`). If the prelude's own compile
// fails on the same shapes, this file attributes the failure to the shape.

// --- call.carbon

library "[[@TEST_NAME]]";

fn Offset[T: type](p: T*, n: i64) -> T* = "pointer.offset";

//@dump-sem-ir-begin
fn F(p: i32*) -> i32* {
  return Offset(p, 1);
}
//@dump-sem-ir-end

// --- symbolic_deref.carbon

library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn Load[T: Core.Copy](p: T*) -> T {
  return *p;
}

fn Store[T: Core.Copy](p: T*, v: T) {
  *p = v;
}
//@dump-sem-ir-end

// --- fail_incomplete_pointee.carbon

library "[[@TEST_NAME]]";

class Incomplete;

fn Offset[T: type](p: T*, n: i64) -> T* = "pointer.offset";

// Predicted: `IncompleteTypeInBuiltinCall` "pointee type `Incomplete` is
// incomplete in call to builtin function pointer.offset", with the
// `ClassForwardDeclaredHere` note — the lowering strides by the pointee's
// size, so the call requires it complete (an incomplete type would lower to
// an unsized opaque struct and fail the LLVM verifier).
fn F(p: Incomplete*) -> Incomplete* {
  return Offset(p, 1);
}

// --- fail_mismatched_pointee.carbon

library "[[@TEST_NAME]]";

// Predicted: `InvalidBuiltinSignature` "invalid signature for builtin function
// \"pointer.offset\"" — the result pointee must be the parameter pointee.
fn Bad[T: type, U: type](p: T*, n: i64) -> U* = "pointer.offset";

// --- fail_non_pointer.carbon

library "[[@TEST_NAME]]";

// Predicted: `InvalidBuiltinSignature` "invalid signature for builtin function
// \"pointer.offset\"" — the first parameter must be a pointer.
fn Bad(p: i64, n: i64) -> i64 = "pointer.offset";
