// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/primitives.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/variadics/fail_each_name.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/variadics/fail_each_name.carbon

// --- fail_each_name_not_pack.carbon
library "[[@TEST_NAME]]";

fn Consume(x: i64);

fn F(x: i64) {
  // CHECK:STDERR: fail_each_name_not_pack.carbon:[[@LINE+4]]:15: error: `each x` does not name a pack [EachNameNotPack]
  // CHECK:STDERR:   ... Consume(each x);
  // CHECK:STDERR:               ^~~~~~
  // CHECK:STDERR:
  ... Consume(each x);
}

// --- fail_each_name_outside_expansion.carbon
library "[[@TEST_NAME]]";

fn Consume(x: i64);

fn F(... each n: i64) {
  // CHECK:STDERR: fail_each_name_outside_expansion.carbon:[[@LINE+4]]:11: error: each-name `each n` is not inside a pack expansion [EachNameOutsidePackExpansion]
  // CHECK:STDERR:   Consume(each n);
  // CHECK:STDERR:           ^~~~~~
  // CHECK:STDERR:
  Consume(each n);
}

// --- fail_each_binding_outside_expansion.carbon
library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_each_binding_outside_expansion.carbon:[[@LINE+8]]:11: error: each-name binding `each n` is not inside a pack expansion pattern [EachBindingOutsidePackExpansion]
// CHECK:STDERR: fn F(each n: i64) {}
// CHECK:STDERR:           ^
// CHECK:STDERR:
// CHECK:STDERR: fail_each_binding_outside_expansion.carbon:[[@LINE+4]]:6: warning: binding `n` unused [UnusedBinding]
// CHECK:STDERR: fn F(each n: i64) {}
// CHECK:STDERR:      ^~~~~~~~~~~
// CHECK:STDERR:
fn F(each n: i64) {}

// --- fail_binding_without_each.carbon
library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_binding_without_each.carbon:[[@LINE+4]]:10: error: binding pattern in a pack expansion must declare an each-name, such as `each n` [PackExpansionBindingWithoutEach]
// CHECK:STDERR: fn F(... n: i64) {}
// CHECK:STDERR:          ^
// CHECK:STDERR:
fn F(... n: i64) {}

// --- fail_unused_without_definition.carbon
library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_unused_without_definition.carbon:[[@LINE+4]]:17: error: `unused` modifier without a definition [UnusedModifierWithoutDefinition]
// CHECK:STDERR: fn F(... unused each n: i64);
// CHECK:STDERR:                 ^~~~~~~~~~~
// CHECK:STDERR:
fn F(... unused each n: i64);

// --- fail_underscore_without_each.carbon
library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_underscore_without_each.carbon:[[@LINE+4]]:10: error: binding pattern in a pack expansion must declare an each-name, `each` followed by an identifier [PackExpansionBindingNotIdentifier]
// CHECK:STDERR: fn F(... _: i64) {}
// CHECK:STDERR:          ^
// CHECK:STDERR:
fn F(... _: i64) {}

// --- fail_self_without_each.carbon
library "[[@TEST_NAME]]";

class C {
  // CHECK:STDERR: fail_self_without_each.carbon:[[@LINE+4]]:12: error: binding pattern in a pack expansion must declare an each-name, `each` followed by an identifier [PackExpansionBindingNotIdentifier]
  // CHECK:STDERR:   fn F(... self) {}
  // CHECK:STDERR:            ^~~~
  // CHECK:STDERR:
  fn F(... self) {}
}

// --- fail_invalid_element_type.carbon
library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_invalid_element_type.carbon:[[@LINE+4]]:25: error: name `Undeclared` not found [NameNotFound]
// CHECK:STDERR: fn F(... unused each n: Undeclared) {}
// CHECK:STDERR:                         ^~~~~~~~~~
// CHECK:STDERR:
fn F(... unused each n: Undeclared) {}

fn G() {
  F();
  F(1);
  F(1, 2);
}
