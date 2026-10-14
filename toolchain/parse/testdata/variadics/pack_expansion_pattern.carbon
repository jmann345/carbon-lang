// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/parse/testdata/variadics/pack_expansion_pattern.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/parse/testdata/variadics/pack_expansion_pattern.carbon

// --- param.carbon

fn F(... each x: i32);
fn G(a: i32, ... each b: i32, c: i32);

// --- implicit.carbon

fn F[... each T: type](... each x: each T);

// --- tuple_pattern.carbon

fn F() {
  let (a: i32, ... each b: i32) = (1, 2);
}
