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
overload fn F(b: i32) {}

// --- fail_return_type.carbon

library "[[@TEST_NAME]]";

overload fn F(x: i32) -> i32;

// No overloading on return type.
overload fn F(x: i32) -> bool;

// --- fail_redefinition.carbon

library "[[@TEST_NAME]]";

overload fn F(x: i32) -> i32 { return 1; }

overload fn F(x: i32) -> i32 { return 2; }

// --- fail_redundant.carbon

library "[[@TEST_NAME]]";

overload fn F(x: i32) -> i32;

overload fn F(x: i32) -> i32;
