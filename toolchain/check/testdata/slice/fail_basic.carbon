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
// CHECK:STDERR: {{.*}}/prelude/types/cpp/slice.carbon:69:9: error: cannot access member of interface `Destroy` in type `C.(CppContiguousRange.SizeType)` that does not implement that interface [MissingImplInMemberAccess]
// CHECK:STDERR:         self.Size().(ImplicitAs(u64).Convert)().(As(i64).Convert)());
// CHECK:STDERR:         ^~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: {{.*}}/prelude/types/cpp/slice.carbon:68:9: error: cannot access member of interface `Destroy` in type `C.(CppContiguousRange.DataType)` that does not implement that interface [MissingImplInMemberAccess]
// CHECK:STDERR:         self.Data().(CppDataPointer.Raw)(),
// CHECK:STDERR:         ^~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: {{.*}}/prelude/types/cpp/slice.carbon:64:1: error: orphan `impl` found; something in the self-type or constraint must be defined in the same file [ImplIsOrphan]
// CHECK:STDERR: impl forall [C: CppContiguous where .Element impls Copy & Destroy]
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:

// Fork (SL-1, fork/slices/plan.md §4.A): the pinned 0.1 limits of
// `Core.Slice(T)`.

// --- fail_write_through.carbon

library "[[@TEST_NAME]]";

// D-SL-3's pin: `s[i]` is a value expression (`IndexWith.At`), so a write
// through a slice diagnoses `AssignmentToNonAssignable` "expression is not
// assignable". The pin is deleted when `IndirectIndexWith`/`ref` returns land.
fn W(s: Core.Slice(i32)) {
  // CHECK:STDERR: fail_write_through.carbon:[[@LINE+4]]:3: error: expression is not assignable [AssignmentToNonAssignable]
  // CHECK:STDERR:   s[0] = 5;
  // CHECK:STDERR:   ^~~~
  // CHECK:STDERR:
  s[0] = 5;
}

// --- fail_subscript_i32.carbon

library "[[@TEST_NAME]]";

// Subscripts are `i64`; only an integer LITERAL converts (the literal-subscript
// rule, check/handle_index.cpp), so an `i32` value needs an explicit `as i64`.
// Predicted `MissingImplInMemberAccess` "cannot access member of interface
// `Core.IndexWith(i32)` in type `Core.Slice(i32)` that does not implement that
// interface".
fn I(s: Core.Slice(i32), i: i32) -> i32 {
  // CHECK:STDERR: fail_subscript_i32.carbon:[[@LINE+4]]:10: error: cannot access member of interface `Core.IndexWith(i32)` in type `Core.Slice(i32 as Core.Destroy & Core.Copy)` that does not implement that interface [MissingImplInMemberAccess]
  // CHECK:STDERR:   return s[i];
  // CHECK:STDERR:          ^~~~
  // CHECK:STDERR:
  return s[i];
}

// --- fail_array_value_no_conversion.carbon

library "[[@TEST_NAME]]";

// D-SL-2's pin: there is no implicit conversion from an array VALUE; views
// are formed from `&a`. Predicted `ConversionFailure` "cannot implicitly
// convert expression of type `array(i32, 4)` to `Core.Slice(i32)`".
fn V(a: array(i32, 4)) {
  // CHECK:STDERR: fail_array_value_no_conversion.carbon:[[@LINE+11]]:28: error: cannot implicitly convert expression of type `array(i32, 4)` to `Core.Slice(i32 as Core.Destroy & Core.Copy)` [ConversionFailure]
  // CHECK:STDERR:   let s: Core.Slice(i32) = a;
  // CHECK:STDERR:                            ^
  // CHECK:STDERR: fail_array_value_no_conversion.carbon:[[@LINE+8]]:28: note: type `array(i32, 4)` does not implement interface `Core.ImplicitAs(Core.Slice(i32 as Core.Destroy & Core.Copy))` [MissingImplInMemberAccessInContext]
  // CHECK:STDERR:   let s: Core.Slice(i32) = a;
  // CHECK:STDERR:                            ^
  // CHECK:STDERR:
  // CHECK:STDERR: fail_array_value_no_conversion.carbon:[[@LINE+4]]:7: warning: binding `s` unused [UnusedBinding]
  // CHECK:STDERR:   let s: Core.Slice(i32) = a;
  // CHECK:STDERR:       ^~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  let s: Core.Slice(i32) = a;
}

// --- fail_non_copy_element.carbon

library "[[@TEST_NAME]]";

// The element constraint `T: Copy & Destroy` (D-SL-1). Predicted
// `ConversionFailureTypeToFacet` "cannot convert type `NoCopy` into type
// implementing `Core.Copy & Core.Destroy`".
class NoCopy {}

// CHECK:STDERR: fail_non_copy_element.carbon:[[@LINE+7]]:9: error: cannot convert type `NoCopy` into type implementing `Core.Destroy & Core.Copy` [ConversionFailureTypeToFacet]
// CHECK:STDERR: fn N(s: Core.Slice(NoCopy));
// CHECK:STDERR:         ^~~~~~~~~~~~~~~~~~
// CHECK:STDERR: {{.*}}/prelude/types/slice.carbon:24:13: note: initializing generic parameter `T` declared here [InitializingGenericParam]
// CHECK:STDERR: class Slice(T: Copy & Destroy) {
// CHECK:STDERR:             ^~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn N(s: Core.Slice(NoCopy));
