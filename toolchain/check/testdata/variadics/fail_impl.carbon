// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/primitives.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/variadics/fail_impl.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/variadics/fail_impl.carbon

// --- fail_missing_element_impl.carbon
library "[[@TEST_NAME]]";

interface Code {
  fn Get(self) -> i64;
}

impl i64 as Code {
  fn Get(self) -> i64 { return self; }
}

impl forall [... each T: Code] (... each T) as Code {
  fn Get(unused self) -> i64 { return 0; }
}

fn Call(t: (i64, bool)) -> i64 {
  // CHECK:STDERR: fail_missing_element_impl.carbon:[[@LINE+4]]:10: error: cannot access member of interface `Code` in type `(i64, bool)` that does not implement that interface [MissingImplInMemberAccess]
  // CHECK:STDERR:   return t.(Code.Get)();
  // CHECK:STDERR:          ^~~~~~~~~~~~
  // CHECK:STDERR:
  return t.(Code.Get)();
}

// --- fail_not_a_tuple.carbon
library "[[@TEST_NAME]]";

interface Count {
  fn N(self) -> i64;
}

impl forall [... each T: type] (... each T) as Count {
  fn N(unused self) -> i64 { return 7; }
}

fn Call(x: i64) -> i64 {
  // CHECK:STDERR: fail_not_a_tuple.carbon:[[@LINE+4]]:10: error: cannot access member of interface `Count` in type `i64` that does not implement that interface [MissingImplInMemberAccess]
  // CHECK:STDERR:   return x.(Count.N)();
  // CHECK:STDERR:          ^~~~~~~~~~~
  // CHECK:STDERR:
  return x.(Count.N)();
}

// --- fail_unused_pack.carbon
library "[[@TEST_NAME]]";

interface Count {
  fn N(self) -> i64;
}

// CHECK:STDERR: fail_unused_pack.carbon:[[@LINE+4]]:13: error: `impl` with unused generic binding [ImplUnusedBinding]
// CHECK:STDERR: impl forall [... each T: type] i64 as Count {
// CHECK:STDERR:             ^~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
impl forall [... each T: type] i64 as Count {
  fn N(unused self) -> i64 { return 7; }
}

// --- fail_same_type_structure.carbon
library "[[@TEST_NAME]]";

interface Count {
  fn N(self) -> i64;
}

impl forall [... each T: type] (... each T) as Count {
  fn N(unused self) -> i64 { return 1; }
}

// CHECK:STDERR: fail_same_type_structure.carbon:[[@LINE+7]]:1: error: found non-final `impl` with the same type structure as another non-final `impl` [ImplNonFinalSameTypeStructure]
// CHECK:STDERR: impl forall [... each U: type] (... each U) as Count {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_same_type_structure.carbon:[[@LINE-7]]:1: note: other `impl` here [ImplNonFinalSameTypeStructureNote]
// CHECK:STDERR: impl forall [... each T: type] (... each T) as Count {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
impl forall [... each U: type] (... each U) as Count {
  fn N(unused self) -> i64 { return 2; }
}
