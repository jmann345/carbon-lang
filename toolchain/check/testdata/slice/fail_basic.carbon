// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/slice/fail_basic.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/slice/fail_basic.carbon

// Fork (SL-1, fork/slices/plan.md §4.A): the pinned 0.1 limits of
// `Core.Slice(T)`.

// --- fail_write_through.carbon

library "[[@TEST_NAME]]";

// D-SL-3's pin: `s[i]` is a value expression (`IndexWith.At`), so a write
// through a slice diagnoses `AssignmentToNonAssignable` "expression is not
// assignable". The pin is deleted when `IndirectIndexWith`/`ref` returns land.
fn W(s: Core.Slice(i32)) {
  s[0] = 5;
}

// --- fail_array_value_no_conversion.carbon

library "[[@TEST_NAME]]";

// D-SL-2's pin: there is no implicit conversion from an array VALUE; views
// are formed from `&a`. Predicted `ConversionFailure` "cannot implicitly
// convert expression of type `array(i32, 4)` to `Core.Slice(i32)`".
fn V(a: array(i32, 4)) {
  let s: Core.Slice(i32) = a;
}

// --- fail_non_copy_element.carbon

library "[[@TEST_NAME]]";

// The element constraint `T: Copy & Destroy` (D-SL-1). Predicted
// `ConversionFailureTypeToFacet` "cannot convert type `NoCopy` into type
// implementing `Core.Copy & Core.Destroy`".
class NoCopy {}

fn N(s: Core.Slice(NoCopy));
