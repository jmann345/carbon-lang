// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --dump-sem-ir-ranges=only
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/function/overload/fail_todo_export.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/function/overload/fail_todo_export.carbon
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

// C++ name lookup of a Carbon `overload fn` set is a semantics TODO in OV-1
// (D-OV-6 gate (viii)); OV-3 returns every member as a C++ overload set and
// deletes this file.

// --- fail_export.carbon

library "[[@TEST_NAME]]";

import Cpp;

overload fn F(unused x: i32) -> i32 { return 1; }
overload fn F(unused b: bool) -> i32 { return 2; }

inline Cpp '''
// CHECK:STDERR: fail_export.carbon:[[@LINE+8]]:28: error: semantics TODO: `overload set export` [SemanticsTodo]
// CHECK:STDERR: int Use() { return Carbon::F(true); }
// CHECK:STDERR:                            ^
// CHECK:STDERR:
// CHECK:STDERR: fail_export.carbon:[[@LINE+4]]:28: error: no member named 'F' in namespace 'Carbon' [CppInteropParseError]
// CHECK:STDERR:    18 | int Use() { return Carbon::F(true); }
// CHECK:STDERR:       |                            ^
// CHECK:STDERR:
int Use() { return Carbon::F(true); }
''';

fn G() -> i32 { return Cpp.Use(); }
