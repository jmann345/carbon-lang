// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/primitives.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/variadics/fail_todo_va2.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/variadics/fail_todo_va2.carbon

// --- fail_todo_two_implicit_packs.carbon
library "[[@TEST_NAME]]";

fn F[... each T: type, ... each U: type](... each x: each T);

// --- fail_todo_computed_element_type.carbon
library "[[@TEST_NAME]]";

class Box(T: type) {}

fn F[... each T: type](... each b: Box(each T));

// --- fail_todo_template_each.carbon
library "[[@TEST_NAME]]";

fn F[... template each T: type](... each x: each T);

// --- fail_todo_class_pack.carbon
library "[[@TEST_NAME]]";

class Tup(... each T: type) {}

// --- fail_todo_interface_pack.carbon
library "[[@TEST_NAME]]";

interface I(... each T: type) {}

// --- fail_todo_explicit_generic_pack.carbon
library "[[@TEST_NAME]]";

fn Count(... generic each T: type) -> i64;

// --- fail_todo_each_auto.carbon
library "[[@TEST_NAME]]";

fn F(... each x: auto);

// --- fail_todo_two_arities.carbon
library "[[@TEST_NAME]]";

fn F[... each T: type](... each n: i64);

// --- fail_todo_forward_hetero_to_homo.carbon
library "[[@TEST_NAME]]";

fn H(... each y: i64);

fn F[... each T: Core.ImplicitAs(i64)](... each x: each T) {
  H(... each x);
}

// --- fail_todo_expansion_without_each_name.carbon
library "[[@TEST_NAME]]";

fn F(t: (... i64));

// --- fail_todo_overload_hetero_member.carbon
library "[[@TEST_NAME]]";

overload fn G(unused b: bool) {}
overload fn G[... each T: type](... unused each x: each T) {}

fn Call() {
  G(1 as i64, true);
}

// --- traits.h

template<typename T> struct Traits {
  static constexpr int size = sizeof(T);
};

// --- fail_todo_cpp_template_on_hetero_element.carbon
library "[[@TEST_NAME]]";

import Cpp library "traits.h";

fn Consume(x: i32);

fn F[... each T: type](... unused each x: each T) {
  ... Consume(Cpp.Traits(each T).size);
}

// --- fail_todo_cpp_template_on_tuple_of_pack.carbon
library "[[@TEST_NAME]]";

import Cpp library "traits.h";

fn F[... each T: type](... unused each x: each T) -> i32 {
  return Cpp.Traits((... each T)).size;
}

fn Call() {
  F(1 as i32, 2 as i64, true);
}

// --- fail_todo_template_action_on_hetero_element.carbon
library "[[@TEST_NAME]]";

fn F[template U: type, ... each T: type](u: U, ... each x: each T) {
  ... u.Get(each x);
}
