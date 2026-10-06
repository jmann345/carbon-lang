// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/primitives.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/if_expr/arm_temporary.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/if_expr/arm_temporary.carbon

// --- member_of_temporary.carbon

library "[[@TEST_NAME]]";

class C {
  var x: i32;
}

fn Make(x: i32) -> C { return {.x = x}; }

// Each arm's `Make(...)` temporary is destroyed at the end of that arm, after
// its member has been read, rather than in the `if.expr.result` block: only
// the taken arm's temporary exists there, and neither arm's creation of it
// dominates that block.
//@dump-sem-ir-begin
fn F(c: bool) -> i32 {
  return if c then Make(1).x else Make(2).x;
}
//@dump-sem-ir-end

// --- fail_todo_by_ref_result.carbon

library "[[@TEST_NAME]]";

class C {
  var x: i32;
}

fn Make(x: i32) -> C { return {.x = x}; }

fn Use(c: C);

fn G(c: bool) {
  // A class value refers to the object it was formed from, here the arm's own
  // temporary, which the arm would destroy before the `if` expression's value
  // is used; the arm is diagnosed instead.
  Use(if c then Make(1) else Make(2));
}
