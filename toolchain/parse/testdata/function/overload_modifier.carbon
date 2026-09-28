// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/parse/testdata/function/overload_modifier.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/parse/testdata/function/overload_modifier.carbon

// --- basic.carbon

overload fn F(x: i32);

// --- with_access.carbon

private overload fn G(b: bool) {}

// --- method.carbon

class C {
  overload fn M(self, x: i32);
}

// --- in_function_body.carbon

fn Outer() {
  overload fn L(x: i32) {}
}

// --- fail_overload_after_fn.carbon

// `overload` is a keyword, so it cannot be the declaration's name.
fn overload F();

// --- ordering.carbon

// The parser accepts modifiers in any order; the ordering error
// (`ModifierMustAppearBefore`) is diagnosed by the checker, so this parses
// cleanly with the modifiers in source order.
overload private fn H();
