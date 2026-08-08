// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/packages/separate_compilation_witness.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/packages/separate_compilation_witness.carbon
// CHECK:STDERR: {{.*}}/prelude/try.carbon:20:1: error: name `Core.ImplicitAs` implicitly referenced here, but not found [CoreNameNotFound]
// CHECK:STDERR: choice ControlFlow(C: type, B: type) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: {{.*}}/prelude/try.carbon:20:1: error: name `Core.ImplicitAs` implicitly referenced here, but not found [CoreNameNotFound]
// CHECK:STDERR: choice ControlFlow(C: type, B: type) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:

// This test ensures that we get the same mangled name for the below `(Vector as
// Add).Op` and `(Vector as MulWith(i32)).Op` functions for various calls from
// different contexts.

// --- owner.carbon
package OwningPackage library "[[@TEST_NAME]]";

class Vector {
  var x: i32;
}

impl Vector as Core.AddWith(Vector) where .Result = Vector {
  fn Op(self, other: Vector) -> Vector {
    return {.x = self.x + other.x};
  }
}

impl Vector as Core.MulWith(i32) where .Result = Vector {
  fn Op(self, n: i32) -> Vector {
    return {.x = self.x * n};
  }
}

// --- owner.impl.carbon
impl package OwningPackage library "[[@TEST_NAME]]";

fn DirectInImplFile(v1: Vector, v2: Vector) -> Vector {
  // Direct call, same package, same library.
  return v1 + v2 * (2 as i32);
}

// --- direct_same_package.carbon
package OwningPackage library "[[@TEST_NAME]]";

import library "owner";

fn Direct(v1: Vector, v2: Vector) -> Vector {
  // Direct call, same package, different library.
  return v1 + v2 * (2 as i32);
}

// --- generic_same_package.carbon
package OwningPackage library "[[@TEST_NAME]]";

import library "owner";

fn Generic(unused generic T: type, v1: Vector, v2: Vector) -> Vector {
  return v1 + v2 * (2 as i32);
}

fn Make() -> Vector;

// --- indirect_same_package.carbon
package OwningPackage library "[[@TEST_NAME]]";

import library "generic_same_package";

fn CallGeneric() {
  // Indirect call, same package, different library.
  Generic((), Make(), Make());
}

// --- direct_different_package.carbon
package OtherPackage library "[[@TEST_NAME]]";

import OwningPackage library "owner";

fn Direct(v1: OwningPackage.Vector, v2: OwningPackage.Vector) -> OwningPackage.Vector {
  // Direct call, different package.
  return v1 + v2 * (2 as i32);
}

// --- indirect_different_package_via_generic_in_same_package.carbon
package OtherPackage library "[[@TEST_NAME]]";

import OwningPackage library "generic_same_package";

fn CallGenericInOwningPackage() {
  // Indirect call, different package.
  OwningPackage.Generic((), OwningPackage.Make(), OwningPackage.Make());
}

// --- generic_different_package.carbon
package OtherPackage library "[[@TEST_NAME]]";

import OwningPackage library "owner";

fn Generic(unused generic T: type, v1: OwningPackage.Vector, v2: OwningPackage.Vector) -> OwningPackage.Vector {
  return v1 + v2 * (2 as i32);
}

fn Make() -> OwningPackage.Vector;

// --- indirect_different_package_via_generic_in_different_package.carbon
package OtherPackage library "[[@TEST_NAME]]";

import library "generic_different_package";

fn CallGeneric() {
  // Indirect call, different package.
  Generic((), Make(), Make());
}

