// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/int.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/array/mixed_constant_init.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/array/mixed_constant_init.carbon

// Fork (SL-2 round 4): an array initialized from a tuple literal that mixes a
// runtime element with constant ones. The `array_init` is not a constant (its
// first element is a call), so the `var`'s `Assign` copies nothing, and the
// constant elements' `in_place_init`s are skipped by `LowerInst` as constants:
// `HandleInst(ArrayInit)` now finishes them, as `EmitAggregateInitializer`
// does for struct, tuple and class inits. Predicted: a `call @_CF.Main` whose
// result is stored to `a[0]`, then `store i32 2` and `store i32 3` to the
// `array.index` of elements 1 and 2, then the load of `a[1]`. Before the fix,
// the two constant stores were absent and `a[1]` read uninitialized stack
// (the hosted conformance run 37378790657's `cpp_span_roundtrip_diff`
// mismatch). An all-constant initializer is unchanged: array_in_place.carbon
// and the all-runtime `(F(), F())` shape are unaffected.

fn F() -> i32;

fn G() -> i32 {
  var a: array(i32, 3) = (F(), 2, 3);
  return a[1];
}
