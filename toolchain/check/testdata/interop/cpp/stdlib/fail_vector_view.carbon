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
// `Cpp.NoSize` to `Core.Slice(i32)`" (whatever note the conversion path adds
// is the fill's to pin). `fail_void_members`: `void data(); void size();`
// have no result type, so `LookupCppMemberWithResultType` declines instead of
// building a witness entry (the round-1 fix of the `CARBON_CHECK` the
// `CppRangeForIterate` precedent carries) -- the same `ConversionFailure`,
// not an ICE.

// --- no_size.h

class NoSize {
 public:
  int* _Nonnull data();
};

// --- fail_no_size.carbon

library "[[@TEST_NAME]]";

import Cpp library "no_size.h";

fn View(v: Cpp.NoSize) -> Core.Slice(i32) {
  // CHECK:STDERR: fail_no_size.carbon:[[@LINE+7]]:3: error: cannot implicitly convert expression of type `NoSize` to `Core.Slice(i32 as Core.Destroy & Core.Copy)` [ConversionFailure]
  // CHECK:STDERR:   return v;
  // CHECK:STDERR:   ^~~~~~~~~
  // CHECK:STDERR: fail_no_size.carbon:[[@LINE+4]]:3: note: type `Cpp.NoSize` does not implement interface `Core.ImplicitAs(Core.Slice(i32 as Core.Destroy & Core.Copy))` [MissingImplInMemberAccessInContext]
  // CHECK:STDERR:   return v;
  // CHECK:STDERR:   ^~~~~~~~~
  // CHECK:STDERR:
  return v;
}

// --- void_members.h

class VoidMembers {
 public:
  void data();
  void size();
};

// --- fail_void_members.carbon

library "[[@TEST_NAME]]";

import Cpp library "void_members.h";

fn View(v: Cpp.VoidMembers) -> Core.Slice(i32) {
  // CHECK:STDERR: fail_void_members.carbon:[[@LINE+7]]:3: error: cannot implicitly convert expression of type `VoidMembers` to `Core.Slice(i32 as Core.Destroy & Core.Copy)` [ConversionFailure]
  // CHECK:STDERR:   return v;
  // CHECK:STDERR:   ^~~~~~~~~
  // CHECK:STDERR: fail_void_members.carbon:[[@LINE+4]]:3: note: type `Cpp.VoidMembers` does not implement interface `Core.ImplicitAs(Core.Slice(i32 as Core.Destroy & Core.Copy))` [MissingImplInMemberAccessInContext]
  // CHECK:STDERR:   return v;
  // CHECK:STDERR:   ^~~~~~~~~
  // CHECK:STDERR:
  return v;
}
