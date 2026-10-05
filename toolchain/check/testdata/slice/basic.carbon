// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/slice/basic.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/slice/basic.carbon

// Fork (SL-1, fork/slices/plan.md §4.A): `Core.Slice(T)` (D-SL-1..3, 7, 10).
// Positives only, one dump range per function.

// --- from_array_index.carbon

library "[[@TEST_NAME]]";

// Predicted: a `FromArray` specific with `N = 4` deduced from
// `array(i32, 4)*`; the literal subscript converted to `i64` by the
// literal-subscript rule (check/handle_index.cpp: `Slice(i32)` implements
// `IndexWith(i64)` and not `IndexWith(Core.IntLiteral)`), so the
// `Slice(i32) as IndexWith(i64)` witness and an `At` call with an `i64`
// argument producing a value of type `i32`.
//@dump-sem-ir-begin
fn F() -> i32 {
  var a: array(i32, 4) = (1, 2, 3, 4);
  let s: Core.Slice(i32) = Core.Slice(i32).FromArray(&a);
  return s[1];
}
//@dump-sem-ir-end

// --- index_runtime_subscript.carbon

library "[[@TEST_NAME]]";

// Predicted: an `i64` subscript dispatches `IndexWith(i64)` directly, with no
// conversion of `i` (an `i32` subscript is the `fail_subscript_i32` pin in
// fail_basic.carbon).
//@dump-sem-ir-begin
fn G(s: Core.Slice(i32), i: i64) -> i32 {
  return s[i];
}
//@dump-sem-ir-end

// --- subslice_and_size.carbon

library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn H(s: Core.Slice(i32)) -> i64 {
  return s.Subslice(1, 3).Size();
}
//@dump-sem-ir-end

// --- const_view.carbon

library "[[@TEST_NAME]]";

// Predicted: the out-of-class `impl forall [T] Slice(T) as
// ImplicitAs(Slice(const T))` witness (D-SL-10).
//@dump-sem-ir-begin
fn K(s: Core.Slice(i32)) -> Core.Slice(const i32) {
  return s;
}
//@dump-sem-ir-end

// --- iterate.carbon

library "[[@TEST_NAME]]";

// Predicted: the `Slice(T) as Iterate` witness with `NewCursor` and `Next`
// calls (D-SL-7).
//@dump-sem-ir-begin
fn Sum(s: Core.Slice(i32)) -> i32 {
  var t: i32 = 0;
  for (x: i32 in s) {
    t += x;
  }
  return t;
}
//@dump-sem-ir-end

// --- unformed.carbon

library "[[@TEST_NAME]]";

// Predicted: the `DefaultOrUnformed` blanket impl over `UnformedInit`; no
// `ConversionFailureTypeToFacet`. The only diagnostic is the `UnusedBinding`
// WARNING on `s` (a warning needs no `fail_` prefix: patterns/unused.carbon).
//@dump-sem-ir-begin
fn U() {
  var s: Core.Slice(i32);
}
//@dump-sem-ir-end

// --- generic_element.carbon

library "[[@TEST_NAME]]";

// Predicted: the literal converts to `i64` (the `IndexWith(i64)` impl is a
// candidate for the symbolic `Slice(T)`, `IndexWith(Core.IntLiteral)` has
// none) and the symbolic `IndexWith(i64)` lookup is deferred to the specific.
//@dump-sem-ir-begin
fn First[T: Core.Copy & Core.Destroy](s: Core.Slice(T)) -> T {
  return s[0];
}
//@dump-sem-ir-end
