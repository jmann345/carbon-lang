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

// CHECK:STDERR: fail_on_class.carbon:[[@LINE+4]]:1: error: `overload` not allowed on `class` declaration [ModifierNotAllowedOnDeclaration]
// CHECK:STDERR: overload class C {}
// CHECK:STDERR: ^~~~~~~~
// CHECK:STDERR:
overload class C {}

// --- fail_with_virtual.carbon

library "[[@TEST_NAME]]";

base class B {
  // CHECK:STDERR: fail_with_virtual.carbon:[[@LINE+7]]:11: error: `overload` not allowed on declaration with `virtual` [ModifierNotAllowedWith]
  // CHECK:STDERR:   virtual overload fn F(self);
  // CHECK:STDERR:           ^~~~~~~~
  // CHECK:STDERR: fail_with_virtual.carbon:[[@LINE+4]]:3: note: `virtual` previously appeared here [ModifierPrevious]
  // CHECK:STDERR:   virtual overload fn F(self);
  // CHECK:STDERR:   ^~~~~~~
  // CHECK:STDERR:
  virtual overload fn F(self);
}

// --- fail_with_impl.carbon

library "[[@TEST_NAME]]";

base class B2 {
  // CHECK:STDERR: fail_with_impl.carbon:[[@LINE+11]]:8: error: `overload` not allowed on declaration with `impl` [ModifierNotAllowedWith]
  // CHECK:STDERR:   impl overload fn F(self);
  // CHECK:STDERR:        ^~~~~~~~
  // CHECK:STDERR: fail_with_impl.carbon:[[@LINE+8]]:3: note: `impl` previously appeared here [ModifierPrevious]
  // CHECK:STDERR:   impl overload fn F(self);
  // CHECK:STDERR:   ^~~~
  // CHECK:STDERR:
  // CHECK:STDERR: fail_with_impl.carbon:[[@LINE+4]]:3: error: `impl` not allowed on `fn` declaration [ModifierNotAllowedOnDeclaration]
  // CHECK:STDERR:   impl overload fn F(self);
  // CHECK:STDERR:   ^~~~
  // CHECK:STDERR:
  impl overload fn F(self);
}

// --- fail_with_export.carbon

library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_with_export.carbon:[[@LINE+7]]:8: error: `overload` not allowed on declaration with `export` [ModifierNotAllowedWith]
// CHECK:STDERR: export overload fn E();
// CHECK:STDERR:        ^~~~~~~~
// CHECK:STDERR: fail_with_export.carbon:[[@LINE+4]]:1: note: `export` previously appeared here [ModifierPrevious]
// CHECK:STDERR: export overload fn E();
// CHECK:STDERR: ^~~~~~
// CHECK:STDERR:
export overload fn E();

// --- fail_order.carbon

library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_order.carbon:[[@LINE+7]]:10: error: `private` must appear before `overload` [ModifierMustAppearBefore]
// CHECK:STDERR: overload private fn H();
// CHECK:STDERR:          ^~~~~~~
// CHECK:STDERR: fail_order.carbon:[[@LINE+4]]:1: note: `overload` previously appeared here [ModifierPrevious]
// CHECK:STDERR: overload private fn H();
// CHECK:STDERR: ^~~~~~~~
// CHECK:STDERR:
overload private fn H();

// --- fail_repeated.carbon

library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_repeated.carbon:[[@LINE+7]]:10: error: `overload` repeated on declaration [ModifierRepeated]
// CHECK:STDERR: overload overload fn I();
// CHECK:STDERR:          ^~~~~~~~
// CHECK:STDERR: fail_repeated.carbon:[[@LINE+4]]:1: note: `overload` previously appeared here [ModifierPrevious]
// CHECK:STDERR: overload overload fn I();
// CHECK:STDERR: ^~~~~~~~
// CHECK:STDERR:
overload overload fn I();
