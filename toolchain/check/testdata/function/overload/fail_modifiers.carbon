// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --dump-sem-ir-ranges=only
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/function/overload/fail_modifiers.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/function/overload/fail_modifiers.carbon

// `overload` is a declaration modifier in the `Decl` order group (D-OV-1):
// valid only on `fn`, after any access modifier, and exclusive with the other
// `Decl`-group modifiers in 0.1.

// --- fail_on_class.carbon

library "[[@TEST_NAME]]";

overload class C {}

// --- fail_with_virtual.carbon

library "[[@TEST_NAME]]";

base class B {
  virtual overload fn F(self);
}

// --- fail_with_impl.carbon

library "[[@TEST_NAME]]";

base class B2 {
  impl overload fn F(self);
}

// --- fail_with_export.carbon

library "[[@TEST_NAME]]";

export overload fn E();

// --- fail_order.carbon

library "[[@TEST_NAME]]";

overload private fn H();

// --- fail_repeated.carbon

library "[[@TEST_NAME]]";

overload overload fn I();
