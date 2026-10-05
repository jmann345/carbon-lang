// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/function/overload/import_class_scope.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/function/overload/import_class_scope.carbon
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

// A member of a class-scope `overload fn` set is called through an import by
// the same `:overload<N>` symbol that defines it, with the class in the scope
// chain after the marker (`_CF:overload0.C.Main`; D-OV-5's stability pin): the
// defining file's `define`s and the importing file's `call`s name identical
// symbols, and an api/impl pair defines each member once, out of line in the
// implementation file, under the API-declared index.

// --- lib.carbon

library "[[@TEST_NAME]]";

class C {
  overload fn F(unused x: i32) -> i32 { return 1; }
  overload fn F(unused b: bool) -> i32 { return 2; }
}

// --- use.carbon

library "[[@TEST_NAME]]";

import library "lib";

fn Use() -> i32 { return C.F(7) + C.F(true); }

// --- api_impl.carbon

library "[[@TEST_NAME]]";

class D {
  overload fn G(x: i32) -> i32;
  overload fn G(b: bool) -> i32;
}

// --- api_impl.impl.carbon

impl library "[[@TEST_NAME]]";

overload fn D.G(x: i32) -> i32 { return x; }
overload fn D.G(b: bool) -> i32 { if (b) { return 1; } return 0; }

fn Use() -> i32 { return D.G(3) + D.G(true); }

