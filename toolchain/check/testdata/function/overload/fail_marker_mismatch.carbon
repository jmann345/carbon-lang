// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --dump-sem-ir-ranges=only
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/function/overload/fail_marker_mismatch.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/function/overload/fail_marker_mismatch.carbon
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

// The `overload` marker must be on every declaration of a name or on none
// (D-OV-3).

// --- fail_unmarked_second.carbon

library "[[@TEST_NAME]]";

overload fn F(unused x: i32) -> i32 { return 1; }

// Diagnosed once, then recovers as if marked: the declaration is a member.
// CHECK:STDERR: fail_unmarked_second.carbon:[[@LINE+7]]:1: error: `overload` must appear on every declaration of `F` or on none [OverloadMarkerMismatch]
// CHECK:STDERR: fn F(unused b: bool) -> i32 { return 2; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_unmarked_second.carbon:[[@LINE-6]]:1: note: previous declaration of `F` here [OverloadMarkerPrevious]
// CHECK:STDERR: overload fn F(unused x: i32) -> i32 { return 1; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn F(unused b: bool) -> i32 { return 2; }

fn Use() -> i32 { return F(true); }

// --- fail_marked_second.carbon

library "[[@TEST_NAME]]";

fn F(unused x: i32) -> i32 { return 1; }

// Diagnosed and not merged; no redeclaration diagnostic is emitted on top.
// CHECK:STDERR: fail_marked_second.carbon:[[@LINE+7]]:1: error: `overload` must appear on every declaration of `F` or on none [OverloadMarkerMismatch]
// CHECK:STDERR: overload fn F(unused b: bool) -> i32 { return 2; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_marked_second.carbon:[[@LINE-6]]:1: note: previous declaration of `F` here [OverloadMarkerPrevious]
// CHECK:STDERR: fn F(unused x: i32) -> i32 { return 1; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
overload fn F(unused b: bool) -> i32 { return 2; }

// --- fail_plain_redecl_unchanged.carbon

library "[[@TEST_NAME]]";

fn G(x: i32);

// Without the marker, differing signatures remain today's redeclaration error.
// CHECK:STDERR: fail_plain_redecl_unchanged.carbon:[[@LINE+7]]:6: error: redeclaration differs at parameter 1 [RedeclParamDiffers]
// CHECK:STDERR: fn G(b: bool);
// CHECK:STDERR:      ^~~~~~~
// CHECK:STDERR: fail_plain_redecl_unchanged.carbon:[[@LINE-6]]:6: note: previous declaration's corresponding parameter here [RedeclParamPrevious]
// CHECK:STDERR: fn G(x: i32);
// CHECK:STDERR:      ^~~~~~
// CHECK:STDERR:
fn G(b: bool);
