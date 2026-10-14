// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/generic/template/for_range.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/generic/template/for_range.carbon

// --- range_param.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn Sum[template T: type](a: T) -> i32 {
  var s: i32 = 0;
  for (x: i32 in a) {
    s += x;
  }
  return s;
}
//@dump-sem-ir-end

// --- range_param_called_array.carbon
library "[[@TEST_NAME]]";

fn Sum[template T: type](a: T) -> i32 {
  var s: i32 = 0;
  for (x: i32 in a) {
    s += x;
  }
  return s;
}

fn Use(a: array(i32, 3)) -> i32 {
  return Sum(a);
}

// --- range_member_array.carbon
library "[[@TEST_NAME]]";

class W {
  var a: array(i32, 3);
}

fn F[template T: type](w: T) -> i32 {
  var s: i32 = 0;
  for (e: i32 in w.a) {
    s += e;
  }
  return s;
}

fn Use(w: W) -> i32 {
  return F(w);
}

// --- range_core_range.carbon
library "[[@TEST_NAME]]";

class W {
  var n: i32;
}

fn Count[template T: type](w: T) -> i32 {
  var s: i32 = 0;
  for (x: i32 in Core.Range(w.n)) {
    s += x;
  }
  return s;
}

fn Use(w: W) -> i32 {
  return Count(w);
}

// --- range_dependent_bound.carbon
library "[[@TEST_NAME]]";

fn Sum(template N: i32, a: array(i32, N)) -> i32 {
  var s: i32 = 0;
  for (x: i32 in a) {
    s += x;
  }
  return s;
}

fn Use(a: array(i32, 3)) -> i32 {
  return Sum(3, a);
}
