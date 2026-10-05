// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --dump-sem-ir-ranges=only
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/function/overload/import_class_scope.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/function/overload/import_class_scope.carbon

// An `overload fn` set declared in a class scope and reached through an import
// (fork/overload/plan.md OV-2, §1.B.1-2). The set is a member of the class's
// scope, so an importer reaches it by member access on the imported class
// (`C.F`), and an implementation file defines members out of line (`fn D.G`)
// against the set the API file's class declares; the set's parent scope is
// the localized class scope.

// --- lib.carbon

library "[[@TEST_NAME]]";

class C {
  overload fn F(unused x: i32) -> i32 { return 1; }
  overload fn F(unused b: bool) -> i32 { return 2; }
}

// --- use.carbon

library "[[@TEST_NAME]]";

import library "lib";

//@dump-sem-ir-begin
fn Use() -> i32 { return C.F(7) + C.F(true); }
//@dump-sem-ir-end

// --- api_impl.carbon

library "[[@TEST_NAME]]";

class D {
  overload fn G(x: i32) -> i32;
  overload fn G(b: bool) -> i32;
}

// --- api_impl.impl.carbon

impl library "[[@TEST_NAME]]";

// Each out-of-line definition merges into its API-declared member of the
// imported class's set; both are defined, so §1.B.7's check is quiet.
//@dump-sem-ir-begin
overload fn D.G(x: i32) -> i32 { return x; }
overload fn D.G(b: bool) -> i32 { if (b) { return 1; } return 0; }

fn Use() -> i32 { return D.G(3) + D.G(true); }
//@dump-sem-ir-end
