// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/function/overload/import.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/function/overload/import.carbon
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

// A member of an imported `overload fn` set is called by the same
// `:overload<N>` symbol that defines it (D-OV-5's stability pin): the index is
// the member's position in the set, mirrored on import, never a fingerprint of
// any instruction. The defining file's `define`s and the using file's `call`s
// name identical symbols; an api/impl pair defines each member once, in the
// implementation file, under the API-declared index. The two-file `extern`
// owner shape (fork/overload/plan.md §1.B.3) defines each member in the owning
// library's implementation file after an owning declaration in its API file,
// into a member localized from the set's `extern library` declaration;
// lowering reads neither `is_extern` nor `extern_library_id`, so the `define`s
// are emitted under the same symbols.

// --- lib.carbon

library "[[@TEST_NAME]]";

overload fn F(unused x: i32) -> i32 { return 1; }
overload fn F(unused b: bool) -> i32 { return 2; }

// --- use.carbon

library "[[@TEST_NAME]]";

import library "lib";

fn Use() -> i32 { return F(7) + F(true); }

// --- api_impl.carbon

library "[[@TEST_NAME]]";

overload fn G(x: i32) -> i32;
overload fn G(b: bool) -> i32;

// --- api_impl.impl.carbon

impl library "[[@TEST_NAME]]";

overload fn G(x: i32) -> i32 { return x; }
overload fn G(b: bool) -> i32 { if (b) { return 1; } return 0; }

fn Use() -> i32 { return G(3) + G(true); }

// --- extern_two_file_lib.carbon

library "[[@TEST_NAME]]";

extern library "extern_two_file" overload fn D(x: i32) -> i32;
extern library "extern_two_file" overload fn D(b: bool) -> i32;

// --- extern_two_file.carbon

library "[[@TEST_NAME]]";

import library "extern_two_file_lib";

extern overload fn D(x: i32) -> i32;
extern overload fn D(b: bool) -> i32;

// --- extern_two_file.impl.carbon

impl library "[[@TEST_NAME]]";

extern overload fn D(x: i32) -> i32 { return x; }
extern overload fn D(b: bool) -> i32 { if (b) { return 1; } return 0; }

fn Use() -> i32 { return D(1) + D(true); }

