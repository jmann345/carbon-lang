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

// --- eq_with.carbon

library "[[@TEST_NAME]]";

import Cpp inline '''c++
struct EqA {
  int value;

  friend auto operator==(EqA x, EqA y) -> bool {
    return x.value == y.value;
  }

  friend auto operator!=(EqA x, EqA y) -> bool {
    return !(x == y);
  }
};
''';

fn CheckEqWith[U: type, T: Core.EqWith(U)](x: T, y: U) {
  x == y;
  x != y;
}

fn Driver(x: Cpp.EqA, y: Cpp.EqA) {
  CheckEqWith(x, y);
}

// --- ordered_with.carbon

library "[[@TEST_NAME]]";

import Cpp inline '''c++
struct OrderedA {
  int value;

  friend auto operator<(OrderedA x, OrderedA y) -> bool {
    return x.value < y.value;
  }

  friend auto operator>(OrderedA x, OrderedA y) -> bool {
    return y < x;
  }

  friend auto operator<=(OrderedA x, OrderedA y) -> bool {
    return !(y < x);
  }

  friend auto operator>=(OrderedA x, OrderedA y) -> bool {
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

fn Driver(x: Cpp.OrderedA, y: Cpp.OrderedA) {
  CheckOrderedWith(x, y);
}
