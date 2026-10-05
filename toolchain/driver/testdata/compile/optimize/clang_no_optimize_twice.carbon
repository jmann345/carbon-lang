// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// ARGS: compile --optimize=none foo.carbon --target=x86_64-unknown-linux-gnu --phase=optimize --dump-llvm-ir --exclude-dump-file-prefix=%{core} --clang-arg=-O3
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/driver/testdata/compile/optimize/clang_no_optimize_twice.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/driver/testdata/compile/optimize/clang_no_optimize_twice.carbon
// CHECK:STDERR: {{.*}}/prelude/types/cpp/slice.carbon:69:9: error: cannot access member of interface `Destroy` in type `C.(CppContiguousRange.SizeType)` that does not implement that interface
// CHECK:STDERR:         self.Size().(ImplicitAs(u64).Convert)().(As(i64).Convert)());
// CHECK:STDERR:         ^~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: {{.*}}/prelude/types/cpp/slice.carbon:68:9: error: cannot access member of interface `Destroy` in type `C.(CppContiguousRange.DataType)` that does not implement that interface
// CHECK:STDERR:         self.Data().(CppDataPointer.Raw)(),
// CHECK:STDERR:         ^~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: {{.*}}/prelude/types/cpp/slice.carbon:64:1: error: orphan `impl` found; something in the self-type or constraint must be defined in the same file
// CHECK:STDERR: impl forall [C: CppContiguous where .Element impls Copy & Destroy]
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:

// --- foo.carbon

import Cpp inline '''c++
// This should not be `optnone`, because Clang had `-O3`.
inline int f() { return 42; }

// The call to `f()` should not be inlined because Carbon had `--optimize=none`,
// so we don't run the inliner.
int g() { return f(); }
''';

// This should be emitted `optnone`.
fn Call() -> i32 {
  return Cpp.g();
}

