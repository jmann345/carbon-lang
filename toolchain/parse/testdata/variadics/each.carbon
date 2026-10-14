// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/parse/testdata/variadics/each.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/parse/testdata/variadics/each.carbon

// --- binding.carbon

fn F(... each x: i32);

// --- binding_modifiers.carbon

fn F[... template each T: type](... ref each x: i32, ... var each y: i32);

// --- expr.carbon

fn F() {
  ... G(each x, each x.y, each x.f(), -each x);
}

// --- fail_each_without_name.carbon

fn F() {
  G(each);
}

// --- fail_each_binding_without_name.carbon

fn F(... each _: i32);
