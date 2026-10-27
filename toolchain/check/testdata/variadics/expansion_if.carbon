// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/primitives.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/variadics/expansion_if.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/variadics/expansion_if.carbon

// --- if_else.carbon
library "[[@TEST_NAME]]";

fn Consume(x: i64);

//@dump-sem-ir-begin
fn F(... each b: bool) {
  ... if (each b) {
    Consume(1);
  } else {
    Consume(0);
  }
}
//@dump-sem-ir-end

// --- else_if_return.carbon
library "[[@TEST_NAME]]";

fn Consume(x: i64);

//@dump-sem-ir-begin
fn First(... each b: bool) -> i64 {
  ... if (each b) {
    return 1;
  } else if (true) {
    Consume(2);
  }
  return 0;
}
//@dump-sem-ir-end

// --- generic.carbon
library "[[@TEST_NAME]]";

interface Less {
  fn Lt(self, other: Self) -> bool;
}

//@dump-sem-ir-begin
fn AnyLess[T: Less](first: T, ... each next: T) -> bool {
  ... if (each next.Lt(first)) {
    return true;
  }
  return false;
}
//@dump-sem-ir-end

// --- nested.carbon
library "[[@TEST_NAME]]";

fn Consume(x: i64);

//@dump-sem-ir-begin
fn F(... each b: bool) {
  ... if (each b) {
    if (each b) {
      Consume(1);
    }
  }
}
//@dump-sem-ir-end

// --- fail_question_body_position.carbon
library "[[@TEST_NAME]]";

fn Consume(x: i64);

fn InExpression(... each x: i64) {
  ... Consume(each x?);
}

fn InCondition(... each b: bool) {
  ... if (each b?) {
    Consume(1);
  }
}
