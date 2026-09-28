// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --dump-sem-ir-ranges=only
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/function/overload/export_import.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/function/overload/export_import.carbon

// An `overload fn` set re-exported through `export import` arrives whole
// (D-OV-10's transitivity rule, fork/overload/plan.md §1.B.8): the
// re-exporting library's scope entry is an import ref to the set value, which
// the resolver localizes with its complete member list, so both members
// resolve in the importing library. Fewer members than the source set, or a
// `MemberNameNotFound`, would be the falsifier.

// --- base.carbon

library "[[@TEST_NAME]]";

overload fn F(unused x: i32) -> i32 { return 1; }
overload fn F(unused b: bool) -> i32 { return 2; }

// --- reexport.carbon

library "[[@TEST_NAME]]";

export import library "base";

// --- use.carbon

library "[[@TEST_NAME]]";

import library "reexport";

//@dump-sem-ir-begin
fn Use() -> i32 { return F(7) + F(true); }
//@dump-sem-ir-end
