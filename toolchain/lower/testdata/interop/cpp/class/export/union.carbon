// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --clang-arg=-fno-exceptions
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/interop/cpp/class/export/union.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/interop/cpp/class/export/union.carbon

// An exported Carbon union in lowering (fork/unions/plan.md UN-2, §4.B): the
// union's storage is `[8 x i8]`, the exported method thunk and the C++ `Use`
// both read `lo` at offset zero, and the designated initializer is a plain
// store through a byte-offset GEP.

// --- export.carbon
library "[[@TEST_NAME]]";

import Cpp;

union Wide {
  // CHECK:STDERR: export.carbon:[[@LINE+4]]:7: error: union field `lo` has type `i32`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var lo: i32;
  // CHECK:STDERR:       ^~~~~~~
  // CHECK:STDERR:
  var lo: i32;
  // CHECK:STDERR: export.carbon:[[@LINE+4]]:7: error: union field `both` has type `i64`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var both: i64;
  // CHECK:STDERR:       ^~~~~~~~~
  // CHECK:STDERR:
  var both: i64;
  fn Low(self) -> i32 { return self.lo; }
}

inline Cpp '''
int Use(Carbon::Wide* w) {
  // CHECK:STDERR: export.carbon:[[@LINE+4]]:6: error: no member named 'lo' in 'Carbon::Wide' [CppInteropParseError]
  // CHECK:STDERR:    25 |   w->lo = 3;
  // CHECK:STDERR:       |   ~  ^
  // CHECK:STDERR:
  w->lo = 3;
  return w->Low();
}
''';

fn CallUse() -> i32 {
  var w: Wide = {.both = 5};
  return Cpp.Use(&w);
}

