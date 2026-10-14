// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/generic/template/default_init.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/generic/template/default_init.carbon

// --- var_uninit.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn F[template T: type](x: T) -> T {
  var y: T;
  y = x;
  return y;
}
//@dump-sem-ir-end

fn Use() -> i32 {
  return F(5 as i32);
}

// --- class_method_var_uninit.carbon
library "[[@TEST_NAME]]";

class Stack(template T: type) {
  var top: T;
  fn Peek(self) -> T {
    var y: T;
    y = self.top;
    return y;
  }
}

fn Use(s: Stack(i32)) -> i32 {
  return s.Peek();
}

// --- fail_var_uninit_tuple_on_instantiation.carbon
library "[[@TEST_NAME]]";

fn F[template T: type](x: T) -> T {
  var y: T;
  y = x;
  return y;
}

fn Use(t: (i32, i32)) -> (i32, i32) {
  return F(t);
}

// --- template_interface_concrete_self.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn Widen(template U: type, x: i32) -> U {
  return x;
}
//@dump-sem-ir-end

fn Use(x: i32) -> i64 {
  return Widen(i64, x);
}
