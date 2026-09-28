// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/function/overload/import_member_specific.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/function/overload/import_member_specific.carbon

// The specific `Gen(i16)` is lowered in the importing file; its call to the
// member selected inside `Gen`'s body must name that member's own symbol,
// `_CP:overload0.Main` — the member's set-relative index is mirrored on
// import (D-OV-5), so the two members never collapse onto one declaration. An
// un-indexed `_CP.Main` here would be the falsifier.

// --- lib.carbon

library "[[@TEST_NAME]]";

overload fn P(unused x: i32) -> i32 { return 1; }
overload fn P(unused b: bool) -> i32 { return 2; }

fn Gen[T: Core.ImplicitAs(i32)](x: T) -> i32 { return P(x); }

// --- use_lib.carbon

library "[[@TEST_NAME]]";

import library "lib";

fn Use() -> i32 { return Gen(7 as i16); }
