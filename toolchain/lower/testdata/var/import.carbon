// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/int.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/var/import.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/var/import.carbon

// --- simple.carbon

library "[[@TEST_NAME]]";

var v: i32 = 42;

// --- import_simple.carbon

library "[[@TEST_NAME]]";

import library "simple";

fn Run() -> i32 {
  return v;
}

// --- tuple_pattern.carbon

library "[[@TEST_NAME]]";

var (v: i32, w: i32) = (1, 2);

let (x: i32, var y: i32) = (3, 4);

var (_: i32, z: i32) = (5, 6);

// --- import_tuple_pattern.carbon

library "[[@TEST_NAME]]";

import library "tuple_pattern";

fn V() -> i32 { return v; }
fn W() -> i32 { return w; }
fn X() -> i32 { return x; }
fn Y() -> i32 { return y; }
fn Z() -> i32 { return z; }
