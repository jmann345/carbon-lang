// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/primitives.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/template/fail_todo_cpp_call_on_hetero_element.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/template/fail_todo_cpp_call_on_hetero_element.carbon

// --- templates.h

template<typename T> void Add(T x);
template<typename T> int SizeOfFn() { return sizeof(T); }

// --- fail_todo_value_arg.carbon
library "[[@TEST_NAME]]";

import Cpp library "templates.h";

fn F[... each T: type](... each x: each T) {
  ... Cpp.Add(each x);
}

// --- fail_todo_type_arg.carbon
library "[[@TEST_NAME]]";

import Cpp library "templates.h";

fn Consume(x: i32);

fn F[... each T: type](... unused each x: each T) {
  ... Consume(Cpp.SizeOfFn(each T));
}

// --- fail_todo_facet_type_arg.carbon
library "[[@TEST_NAME]]";

import Cpp library "templates.h";

interface I {}

fn Consume(x: i32);

fn F[... each T: I](... unused each x: each T) {
  ... Consume(Cpp.SizeOfFn(each T));
}

// --- fail_todo_tuple_literal_arg.carbon
library "[[@TEST_NAME]]";

import Cpp library "templates.h";

fn F[... each T: type](... each x: each T) {
  Cpp.Add((... each x));
}
