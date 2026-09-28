// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --dump-sem-ir-ranges=only
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/function/overload/fail_todo_impl_file.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/function/overload/fail_todo_impl_file.carbon

// OV-1 delivers same-FILE sets: a set reached through any import, including
// the api file seen from its impl file, resolves to a semantics TODO (D-OV-7,
// gate (vii)) and the impl-file declaration is then a duplicate name. OV-2
// replaces the resolver arms with real set import and deletes this file; its
// `local` subfiles survive as `impl_local_set`.

// --- set.carbon

library "[[@TEST_NAME]]";

overload fn F(x: i32) -> i32;
overload fn F(b: bool) -> i32;

// --- fail_set.impl.carbon

impl library "[[@TEST_NAME]]";

overload fn F(x: i32) -> i32 { return x; }

// --- local.carbon

library "[[@TEST_NAME]]";

// --- local.impl.carbon

impl library "[[@TEST_NAME]]";

// A set declared wholly inside an implementation file involves no import, so
// the same-file path applies.
overload fn L(x: i32) -> i32 { return 1; }
overload fn L(b: bool) -> i32 { return 2; }

fn Use() -> i32 { return L(true); }
