// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/stdlib/fail_vector_view.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/stdlib/fail_vector_view.carbon

// Fork (SL-2, fork/slices/plan.md §4.B `fail_no_size`; D-SL-9): a class
// without a `size()` member gets no `CppContiguousRange` witness, so the
// blanket `ImplicitAs(Slice(...))` impl does not apply. Predicted
// `ConversionFailure` "cannot implicitly convert expression of type
// `Cpp.NoSize` to `Core.Slice(i32)`" with the
// `MissingImplInMemberAccessInContext` note.

// --- no_size.h

class NoSize {
 public:
  int* data();
};

// --- fail_no_size.carbon

library "[[@TEST_NAME]]";

import Cpp library "no_size.h";

fn View(v: Cpp.NoSize) -> Core.Slice(i32) {
  return v;
}
