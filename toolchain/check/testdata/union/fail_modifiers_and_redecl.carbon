// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/union/fail_modifiers_and_redecl.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/union/fail_modifiers_and_redecl.carbon
// CHECK:STDERR: {{.*}}/prelude/types/cpp/slice.carbon:69:9: error: cannot access member of interface `Destroy` in type `C.(CppContiguousRange.SizeType)` that does not implement that interface [MissingImplInMemberAccess]
// CHECK:STDERR:         self.Size().(ImplicitAs(u64).Convert)().(As(i64).Convert)());
// CHECK:STDERR:         ^~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: {{.*}}/prelude/types/cpp/slice.carbon:68:9: error: cannot access member of interface `Destroy` in type `C.(CppContiguousRange.DataType)` that does not implement that interface [MissingImplInMemberAccess]
// CHECK:STDERR:         self.Data().(CppDataPointer.Raw)(),
// CHECK:STDERR:         ^~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: {{.*}}/prelude/types/cpp/slice.carbon:64:1: error: orphan `impl` found; something in the self-type or constraint must be defined in the same file [ImplIsOrphan]
// CHECK:STDERR: impl forall [C: CppContiguous where .Element impls Copy & Destroy]
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:

// Member and modifier restrictions reuse the class diagnostics
// (docs/design/unions.md, "Union members"): a union is implicitly final.

// --- fail_abstract.carbon
library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_abstract.carbon:[[@LINE+4]]:1: error: `abstract` not allowed on `union` declaration [ModifierNotAllowedOnDeclaration]
// CHECK:STDERR: abstract union A {
// CHECK:STDERR: ^~~~~~~~
// CHECK:STDERR:
abstract union A {
  var a: i32;
}

// --- fail_base.carbon
library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_base.carbon:[[@LINE+4]]:1: error: `base` not allowed on `union` declaration [ModifierNotAllowedOnDeclaration]
// CHECK:STDERR: base union B {
// CHECK:STDERR: ^~~~
// CHECK:STDERR:
base union B {
  var a: i32;
}

// --- fail_virtual_method.carbon
library "[[@TEST_NAME]]";

union V {
  var a: i32;
  // CHECK:STDERR: fail_virtual_method.carbon:[[@LINE+11]]:3: error: `virtual` not allowed; requires `abstract` or `base` class scope [ModifierVirtualNotAllowed]
  // CHECK:STDERR:   virtual fn F(self) {}
  // CHECK:STDERR:   ^~~~~~~
  // CHECK:STDERR: fail_virtual_method.carbon:[[@LINE-5]]:1: note: containing definition here [ModifierNotInContext]
  // CHECK:STDERR: union V {
  // CHECK:STDERR: ^~~~~~~~~
  // CHECK:STDERR:
  // CHECK:STDERR: fail_virtual_method.carbon:[[@LINE+4]]:16: warning: binding `self` unused [UnusedBinding]
  // CHECK:STDERR:   virtual fn F(self) {}
  // CHECK:STDERR:                ^~~~
  // CHECK:STDERR:
  virtual fn F(self) {}
}

// --- fail_class_then_union.carbon
library "[[@TEST_NAME]]";

class C;

// CHECK:STDERR: fail_class_then_union.carbon:[[@LINE+7]]:7: error: duplicate name `C` being declared in the same scope [NameDeclDuplicate]
// CHECK:STDERR: union C {
// CHECK:STDERR:       ^
// CHECK:STDERR: fail_class_then_union.carbon:[[@LINE-5]]:1: note: name is previously declared here [NameDeclPrevious]
// CHECK:STDERR: class C;
// CHECK:STDERR: ^~~~~~~~
// CHECK:STDERR:
union C {
  var a: i32;
}

// --- fail_redefinition.carbon
library "[[@TEST_NAME]]";

union D {
  var a: i32;
}

// CHECK:STDERR: fail_redefinition.carbon:[[@LINE+7]]:1: error: redefinition of `union D` [RedeclRedef]
// CHECK:STDERR: union D {
// CHECK:STDERR: ^~~~~~~~~
// CHECK:STDERR: fail_redefinition.carbon:[[@LINE-7]]:1: note: previously defined here [RedeclPrevDef]
// CHECK:STDERR: union D {
// CHECK:STDERR: ^~~~~~~~~
// CHECK:STDERR:
union D {
  var a: i32;
}
