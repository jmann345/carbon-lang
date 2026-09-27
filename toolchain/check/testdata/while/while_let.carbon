// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/while/while_let.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/while/while_let.carbon

// while-let (W-012): the loop header re-evaluates the initializer and
// re-tests the pattern each iteration (`while.body`/`while.done`), and the
// bind pass rebinds in the body block; the bindings live in the loop scope.

// --- pop_loop.carbon
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

//@dump-sem-ir-begin
fn F(start: i32) -> i32 {
  var cur: i32 = start;
  while (let .Some(x: i32) = Next(cur)) {
    cur = x;
  }
  return cur;
}
//@dump-sem-ir-end

// --- break_continue.carbon
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

//@dump-sem-ir-begin
fn F(start: i32) -> i32 {
  var cur: i32 = start;
  var total: i32 = 0;
  while (let .Some(x: i32) = Next(cur)) {
    cur = x;
    if (x == 3) {
      break;
    }
    if (x == 5) {
      continue;
    }
    total = total + x;
  }
  return total;
}
//@dump-sem-ir-end

// --- var_alternative.carbon
library "[[@TEST_NAME]]";

// The var-alternative lane in a loop: per-iteration on-demand storage in
// the body block.
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

//@dump-sem-ir-begin
fn F(start: i32) -> i32 {
  var cur: i32 = start;
  while (var .Some(x: i32) = Next(cur)) {
    x = x - 1;
    cur = x;
  }
  return cur;
}
//@dump-sem-ir-end
