// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/primitives.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/variadics/expansion_if.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/variadics/expansion_if.carbon

// --- first.carbon
library "[[@TEST_NAME]]";

fn Consume(x: i64);

fn First(... each b: bool) -> i64 {
  ... if (each b) {
    return 1;
  } else {
    Consume(0);
  }
  return 0;
}

fn Call() -> i64 {
  return First(false, true, false);
}

// --- min.carbon
library "[[@TEST_NAME]]";

fn Less(a: i64, b: i64) -> bool = "int.less";

fn Min(first: i64, ... each next: i64) -> i64 {
  var result: i64 = first;
  ... if (Less(each next, result)) {
    result = each next;
  }
  return result;
}

fn Call() -> i64 {
  return Min(3, 1, 2);
}

// --- padded_element.carbon
library "[[@TEST_NAME]]";

fn Consume(x: i64);

fn Each(... each x: {.a: i64, .b: bool}) {
  ... if (each x.b) {
    Consume(each x.a);
  }
}

fn Call(y: {.a: i64, .b: bool}) {
  Each(y, y);
}

fn CallConstants() {
  Each({.a = 1, .b = true}, {.a = 2, .b = false});
}

// --- aggregate_constants.carbon
library "[[@TEST_NAME]]";

fn Consume(x: i64);

fn Less(a: i64, b: i64) -> bool = "int.less";

interface Get {
  fn Value(self: Self) -> i64;
}

impl (i64, i64) as Get {
  fn Value(self: Self) -> i64 { return self.1; }
}

impl {.a: i64, .b: bool} as Get {
  fn Value(self: Self) -> i64 { return self.a; }
}

fn Each[... each T: Get](... each x: each T) {
  ... if (Less(0, each x.Value())) {
    Consume(each x.Value());
  }
}

fn Call() {
  Each((1 as i64, 2 as i64), {.a = 3 as i64, .b = true});
}
