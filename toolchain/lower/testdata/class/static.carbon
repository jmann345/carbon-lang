// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/int.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/class/static.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/class/static.carbon

// --- static.carbon
library "[[@TEST_NAME]]";

class C {
  static var static_field: i32;
  static var static_field_with_init: i32 = 123;
}

fn F() {
  C.static_field = 456;
  C.static_field_with_init = 789;
}

// --- static_export.carbon
library "[[@TEST_NAME]]";
import Cpp;

class C {
  static var x: i32 = 123;
}

inline Cpp '''
int F() {
  return Carbon::C::x;
}
''';

fn Run() -> i32 {
  return Cpp.F();
}
