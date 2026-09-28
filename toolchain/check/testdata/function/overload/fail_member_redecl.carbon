// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --dump-sem-ir-ranges=only
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/function/overload/fail_member_redecl.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/function/overload/fail_member_redecl.carbon

// Member identity is parameter-type equality: a marked declaration whose
// parameter types match an existing member is a redeclaration of that member
// and keeps every redeclaration-matching diagnostic (D-OV-3, proposal #3763).

// --- fail_name_differs.carbon

library "[[@TEST_NAME]]";

overload fn F(a: i32);

// Same types means the same member; the binding name differs.
// CHECK:STDERR: fail_name_differs.carbon:[[@LINE+11]]:15: error: redeclaration differs at parameter 1 [RedeclParamDiffers]
// CHECK:STDERR: overload fn F(b: i32) {}
// CHECK:STDERR:               ^~~~~~
// CHECK:STDERR: fail_name_differs.carbon:[[@LINE-6]]:15: note: previous declaration's corresponding parameter here [RedeclParamPrevious]
// CHECK:STDERR: overload fn F(a: i32);
// CHECK:STDERR:               ^~~~~~
// CHECK:STDERR:
// CHECK:STDERR: fail_name_differs.carbon:[[@LINE+4]]:15: warning: binding `b` unused [UnusedBinding]
// CHECK:STDERR: overload fn F(b: i32) {}
// CHECK:STDERR:               ^~~~~~
// CHECK:STDERR:
overload fn F(b: i32) {}

// --- fail_return_type.carbon

library "[[@TEST_NAME]]";

overload fn F(x: i32) -> i32;

// No overloading on return type.
// CHECK:STDERR: fail_return_type.carbon:[[@LINE+7]]:1: error: function redeclaration differs because return type is `bool` [FunctionRedeclReturnTypeDiffers]
// CHECK:STDERR: overload fn F(x: i32) -> bool;
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_return_type.carbon:[[@LINE-6]]:1: note: previously declared with return type `i32` [FunctionRedeclReturnTypePrevious]
// CHECK:STDERR: overload fn F(x: i32) -> i32;
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
overload fn F(x: i32) -> bool;

// --- fail_redefinition.carbon

library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_redefinition.carbon:[[@LINE+4]]:15: warning: binding `x` unused [UnusedBinding]
// CHECK:STDERR: overload fn F(x: i32) -> i32 { return 1; }
// CHECK:STDERR:               ^~~~~~
// CHECK:STDERR:
overload fn F(x: i32) -> i32 { return 1; }

// CHECK:STDERR: fail_redefinition.carbon:[[@LINE+11]]:1: error: redefinition of `fn F` [RedeclRedef]
// CHECK:STDERR: overload fn F(x: i32) -> i32 { return 2; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_redefinition.carbon:[[@LINE-5]]:1: note: previously defined here [RedeclPrevDef]
// CHECK:STDERR: overload fn F(x: i32) -> i32 { return 1; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: fail_redefinition.carbon:[[@LINE+4]]:15: warning: binding `x` unused [UnusedBinding]
// CHECK:STDERR: overload fn F(x: i32) -> i32 { return 2; }
// CHECK:STDERR:               ^~~~~~
// CHECK:STDERR:
overload fn F(x: i32) -> i32 { return 2; }

// --- fail_redundant.carbon

library "[[@TEST_NAME]]";

overload fn F(x: i32) -> i32;

// CHECK:STDERR: fail_redundant.carbon:[[@LINE+7]]:1: error: redeclaration of `fn F` is redundant [RedeclRedundant]
// CHECK:STDERR: overload fn F(x: i32) -> i32;
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_redundant.carbon:[[@LINE-5]]:1: note: previously declared here [RedeclPrevDecl]
// CHECK:STDERR: overload fn F(x: i32) -> i32;
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
overload fn F(x: i32) -> i32;
