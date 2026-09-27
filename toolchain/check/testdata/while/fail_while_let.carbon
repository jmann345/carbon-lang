// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/while/fail_while_let.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/while/fail_while_let.carbon

// while-let negatives (W-012): the bindings end with the loop, an
// irrefutable pattern warns, and `and`/`or` chaining is reserved.

// --- fail_binding_after_loop.carbon
library "[[@TEST_NAME]]";

choice OptInt {
  Some(x: i32),
  None
}
fn Next(n: i32) -> OptInt {
  if (n > 0) {
    return OptInt.Some(n - 1);
  }
  return OptInt.None;
}

fn Use(n: i32) {}

fn F(start: i32) {
  var cur: i32 = start;
  while (let .Some(x: i32) = Next(cur)) {
    cur = x;
  }
  Use(x);
}

// --- irrefutable.carbon
library "[[@TEST_NAME]]";

fn F(start: i32) -> i32 {
  var cur: i32 = start;
  while (let n: i32 = cur) {
    cur = n - 1;
    if (cur < 0) {
      break;
    }
  }
  return cur;
}

// --- fail_chain_reserved.carbon
library "[[@TEST_NAME]]";

fn F(a: bool, b: bool) {
  while (let true = a and b) {
    break;
  }
}
