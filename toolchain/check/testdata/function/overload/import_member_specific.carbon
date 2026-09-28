// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --dump-sem-ir-ranges=only
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/function/overload/import_member_specific.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/function/overload/import_member_specific.carbon

// A MEMBER of an `overload fn` set reached through an import: the member
// selected inside an imported generic's body is resolved when the importing
// library instantiates the generic. The set itself is not imported (D-OV-7,
// gated until OV-2), but the member's `overload_index` is mirrored on import,
// so the specific's call names the member's own `:overload<N>` symbol (see the
// lower twin) and no diagnostic is emitted.

// --- lib.carbon

library "[[@TEST_NAME]]";

overload fn P(unused x: i32) -> i32 { return 1; }
overload fn P(unused b: bool) -> i32 { return 2; }

fn Gen[T: Core.ImplicitAs(i32)](x: T) -> i32 { return P(x); }

// --- use_lib.carbon

library "[[@TEST_NAME]]";

import library "lib";

//@dump-sem-ir-begin
fn Use() -> i32 { return Gen(7 as i16); }
//@dump-sem-ir-end
