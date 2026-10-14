// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/primitives.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/variadics/fail_todo_slice.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/variadics/fail_todo_slice.carbon

// --- fail_todo_generic_pack.carbon
library "[[@TEST_NAME]]";

fn F[... each T: type](... each x: each T);

// --- fail_todo_tuple_pattern.carbon
library "[[@TEST_NAME]]";

fn F() {
  let (... each x: i64) = ();
}

// --- fail_todo_statement_kind.carbon
library "[[@TEST_NAME]]";

fn F(... each n: i64) {
  ... var x: i64 = each n;
}

// --- fail_todo_control_flow.carbon
library "[[@TEST_NAME]]";

fn Consume(x: bool);

fn F(... each b: bool) {
  ... Consume(each b and true);
}

// --- fail_todo_tuple_literal.carbon
library "[[@TEST_NAME]]";

fn F(... each n: i64) {
  let unused t: (i64, i64) = (... each n);
}

// --- fail_todo_merged_segments.carbon
library "[[@TEST_NAME]]";

fn ForEach(... each n: i64);

fn F(... each n: i64) {
  ForEach(0, ... each n);
}

// --- fail_todo_ref_pack.carbon
library "[[@TEST_NAME]]";

fn F(... ref each n: i64);

// --- fail_todo_two_each_names.carbon
library "[[@TEST_NAME]]";

fn F(... (each a: i64, each b: i64));

// --- fail_todo_tuple_operand.carbon
library "[[@TEST_NAME]]";

fn F(... (each a: i64,));

// --- fail_todo_overload_member.carbon
library "[[@TEST_NAME]]";

overload fn G(unused b: bool) {}
overload fn G(... each n: i64) {}

fn F() {
  G(1, 2);
}

// --- fail_todo_overload_pack_arg.carbon
library "[[@TEST_NAME]]";

overload fn G(unused x: i64) {}
overload fn G(unused b: bool) {}

fn F(... each n: i64) {
  G(... each n);
}

// --- fail_todo_template_dependent_call.carbon
library "[[@TEST_NAME]]";

fn F[template T: type](t: T, ... each n: i64) {
  t.G(... each n);
}

// --- fail_todo_pack_name_without_each.carbon
library "[[@TEST_NAME]]";

fn Consume(x: i64);

fn F(... each n: i64) {
  Consume(n);
}

// --- fail_todo_default_after_pack.carbon
library "[[@TEST_NAME]]";

fn F(... each n: i64, last: i64 = 7);

// --- fail_todo_default_before_pack.carbon
library "[[@TEST_NAME]]";

fn F(first: i64 = 7, ... each n: i64);

// --- fail_todo_default_on_pack.carbon
library "[[@TEST_NAME]]";

fn F(... each n: i64 = 1);

// --- fail_todo_interface_function.carbon
library "[[@TEST_NAME]]";

interface I {
  fn F(... each n: i64);
}

// --- fail_todo_conversion_cleanup.carbon
library "[[@TEST_NAME]]";

class C {
  impl as Core.Destroy {
    fn Op(ref self);
  }
}

class D {}

impl D as Core.ImplicitAs(C) {
  fn Convert(self) -> C;
}

fn ForEach(... unused each c: C) {}

fn F(... each d: D) {
  ForEach(... each d);
}
