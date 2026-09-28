// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --dump-sem-ir-ranges=only
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/function/overload/fail_todo_export.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/function/overload/fail_todo_export.carbon

// C++ name lookup of a Carbon `overload fn` set is a semantics TODO in OV-1
// (D-OV-6 gate (viii)); OV-3 returns every member as a C++ overload set and
// deletes this file.

// --- fail_export.carbon

library "[[@TEST_NAME]]";

import Cpp;

overload fn F(x: i32) -> i32 { return 1; }
overload fn F(b: bool) -> i32 { return 2; }

inline Cpp '''
int Use() { return Carbon::F(true); }
''';

fn G() -> i32 { return Cpp.Use(); }
