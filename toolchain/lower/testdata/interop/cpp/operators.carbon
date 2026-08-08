// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/interop/cpp/operators.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/interop/cpp/operators.carbon
// CHECK:STDERR: {{.*}}/prelude/try.carbon:20:1: error: name `Core.ImplicitAs` implicitly referenced here, but not found [CoreNameNotFound]
// CHECK:STDERR: choice ControlFlow(C: type, B: type) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: {{.*}}/prelude/try.carbon:20:1: error: name `Core.ImplicitAs` implicitly referenced here, but not found [CoreNameNotFound]
// CHECK:STDERR: choice ControlFlow(C: type, B: type) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:

// --- eq_with.carbon

library "[[@TEST_NAME]]";

import Cpp inline '''c++
struct A {
  int value;

  friend auto operator==(A x, A y) -> bool {
    return x.value == y.value;
  }

  friend auto operator!=(A x, A y) -> bool {
    return !(x == y);
  }
};
''';

fn CheckEqWith[U: type, T: Core.EqWith(U)](x: T, y: U) {
  x == y;
  x != y;
}

fn Driver(x: Cpp.A, y: Cpp.A) {
  CheckEqWith(x, y);
}

// --- ordered_with.carbon

library "[[@TEST_NAME]]";

import Cpp inline '''c++
struct A {
  int value;

  friend auto operator<(A x, A y) -> bool {
    return x.value < y.value;
  }

  friend auto operator>(A x, A y) -> bool {
    return y < x;
  }

  friend auto operator<=(A x, A y) -> bool {
    return !(y < x);
  }

  friend auto operator>=(A x, A y) -> bool {
    return !(x < y);
  }
};
''';

fn CheckOrderedWith[U: type, T: Core.OrderedWith(U)](x: T, y: U) {
  x < y;
  x > y;
  x <= y;
  x >= y;
}

fn Driver(x: Cpp.A, y: Cpp.A) {
  CheckOrderedWith(x, y);
}

