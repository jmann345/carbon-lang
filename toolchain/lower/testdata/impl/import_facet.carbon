// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// This is testing a facet type that combines two interfaces across multiple
// import boundaries.
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/impl/import_facet.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/impl/import_facet.carbon
// CHECK:STDERR: {{.*}}/prelude/try.carbon:20:1: error: name `Core.ImplicitAs` implicitly referenced here, but not found [CoreNameNotFound]
// CHECK:STDERR: choice ControlFlow(C: type, B: type) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: {{.*}}/prelude/try.carbon:20:1: error: name `Core.ImplicitAs` implicitly referenced here, but not found [CoreNameNotFound]
// CHECK:STDERR: choice ControlFlow(C: type, B: type) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:

// --- a.carbon
library "[[@TEST_NAME]]";

class C(T: Core.Copy & Core.UnformedInit & Core.Destroy) {
  fn GetC(unused self) -> T {
    var value: T;
    return value;
  }
}

// --- b.carbon
library "[[@TEST_NAME]]";
export import library "a";

interface I {
  let T: Core.Copy & Core.UnformedInit & Core.Destroy;
  fn GetI(self) -> C(T);
}

// --- c.carbon
library "[[@TEST_NAME]]";
export import library "b";

class D(U: type) {
  impl as I where .T = U* {
    fn GetI(unused self) -> C(U*) {
      return {};
    }
  }
}

// --- d.carbon
library "[[@TEST_NAME]]";
import library "c";

fn F(d: D(i32)) -> i32* {
  return d.(I.GetI)().GetC();
}

