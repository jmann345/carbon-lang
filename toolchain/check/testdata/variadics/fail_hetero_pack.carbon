// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/primitives.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/variadics/fail_hetero_pack.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/variadics/fail_hetero_pack.carbon

// --- fail_missing_impl.carbon
library "[[@TEST_NAME]]";

interface Code {
  fn Get(self) -> i64;
}

class A {}
impl A as Code {
  fn Get(unused self) -> i64 { return 1; }
}

class C {}

fn ForEach[... each T: Code](... each x: each T);

fn Call(a: A, c: C) {
  // CHECK:STDERR: fail_missing_impl.carbon:[[@LINE+7]]:3: error: cannot convert type `C` into type implementing `Code` [ConversionFailureTypeToFacet]
  // CHECK:STDERR:   ForEach(a, c);
  // CHECK:STDERR:   ^~~~~~~~~~~~~
  // CHECK:STDERR: fail_missing_impl.carbon:[[@LINE-6]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
  // CHECK:STDERR: fn ForEach[... each T: Code](... each x: each T);
  // CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  ForEach(a, c);
}

// --- fail_missing_member.carbon
library "[[@TEST_NAME]]";

interface Code {
  fn Get(self) -> i64;
}

fn ForEach[... each T: Code](... each x: each T) {
  // CHECK:STDERR: fail_missing_member.carbon:[[@LINE+4]]:7: error: member name `Missing` not found in `Code` [MemberNameNotFoundInSpecificScope]
  // CHECK:STDERR:   ... each x.Missing();
  // CHECK:STDERR:       ^~~~~~~~~~~~~~
  // CHECK:STDERR:
  ... each x.Missing();
}

// --- fail_convert_element.carbon
library "[[@TEST_NAME]]";

fn Consume(x: i64);

fn ForEach[... each T: type](... each x: each T) {
  // CHECK:STDERR: fail_convert_element.carbon:[[@LINE+10]]:15: error: cannot implicitly convert expression of type `each T` to `i64` [ConversionFailure]
  // CHECK:STDERR:   ... Consume(each x);
  // CHECK:STDERR:               ^~~~~~
  // CHECK:STDERR: fail_convert_element.carbon:[[@LINE+7]]:15: note: type `each T` does not implement interface `Core.ImplicitAs(i64)` [MissingImplInMemberAccessInContext]
  // CHECK:STDERR:   ... Consume(each x);
  // CHECK:STDERR:               ^~~~~~
  // CHECK:STDERR: fail_convert_element.carbon:[[@LINE-9]]:12: note: initializing function parameter [InCallToFunctionParam]
  // CHECK:STDERR: fn Consume(x: i64);
  // CHECK:STDERR:            ^~~~~~
  // CHECK:STDERR:
  ... Consume(each x);
}

// --- fail_each_type_not_pack.carbon
library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_each_type_not_pack.carbon:[[@LINE+4]]:27: error: `each T` does not name a pack [EachNameNotPack]
// CHECK:STDERR: fn F[T: type](... each x: each T);
// CHECK:STDERR:                           ^~~~~~
// CHECK:STDERR:
fn F[T: type](... each x: each T);

// --- fail_two_explicit_packs.carbon
library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_two_explicit_packs.carbon:[[@LINE+7]]:44: error: parameter list can contain at most one pack expansion pattern [MultiplePackExpansionPatterns]
// CHECK:STDERR: fn F[... each T: type](... each x: each T, ... each y: each T);
// CHECK:STDERR:                                            ^~~
// CHECK:STDERR: fail_two_explicit_packs.carbon:[[@LINE+4]]:24: note: previous pack expansion pattern is here [PreviousPackExpansionPattern]
// CHECK:STDERR: fn F[... each T: type](... each x: each T, ... each y: each T);
// CHECK:STDERR:                        ^~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn F[... each T: type](... each x: each T, ... each y: each T);

// --- fail_binding_type_error.carbon
library "[[@TEST_NAME]]";

interface Code {}
interface Other {}

class Box(unused T: Other) {}

// CHECK:STDERR: fail_binding_type_error.carbon:[[@LINE+7]]:43: error: cannot convert type `each T` that implements `Code` into type implementing `Other` [ConversionFailureFacetToFacet]
// CHECK:STDERR: fn F[... each T: Code](... unused each x: Box(each T)) {}
// CHECK:STDERR:                                           ^~~~~~~~~~~
// CHECK:STDERR: fail_binding_type_error.carbon:[[@LINE-5]]:18: note: initializing generic parameter `T` declared here [InitializingGenericParam]
// CHECK:STDERR: class Box(unused T: Other) {}
// CHECK:STDERR:                  ^~~~~~~~
// CHECK:STDERR:
fn F[... each T: Code](... unused each x: Box(each T)) {}

// --- fail_binding_type_name_error.carbon
library "[[@TEST_NAME]]";

interface Code {}

// CHECK:STDERR: fail_binding_type_name_error.carbon:[[@LINE+4]]:43: error: name `Missing` not found [NameNotFound]
// CHECK:STDERR: fn F[... each T: Code](... unused each x: Missing(each T)) {}
// CHECK:STDERR:                                           ^~~~~~~
// CHECK:STDERR:
fn F[... each T: Code](... unused each x: Missing(each T)) {}

// --- fail_let_binding_type_error.carbon
library "[[@TEST_NAME]]";

interface Code {}

fn F[... each T: Code](t: (... each T)) {
  let (... unused each y: Missing(each T)) = t;
}
