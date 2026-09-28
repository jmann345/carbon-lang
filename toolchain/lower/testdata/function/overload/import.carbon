// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/function/overload/import.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/function/overload/import.carbon

// A member of an imported `overload fn` set is called by the same
// `:overload<N>` symbol that defines it (D-OV-5's stability pin): the index is
// the member's position in the set, mirrored on import, never a fingerprint of
// any instruction. The defining file's `define`s and the using file's `call`s
// name identical symbols; an api/impl pair defines each member once, in the
// implementation file, under the API-declared index.

// --- lib.carbon

library "[[@TEST_NAME]]";

overload fn F(unused x: i32) -> i32 { return 1; }
overload fn F(unused b: bool) -> i32 { return 2; }

// --- use.carbon

library "[[@TEST_NAME]]";

import library "lib";

fn Use() -> i32 { return F(7) + F(true); }

// --- api_impl.carbon

library "[[@TEST_NAME]]";

overload fn G(x: i32) -> i32;
overload fn G(b: bool) -> i32;

// --- api_impl.impl.carbon

impl library "[[@TEST_NAME]]";

overload fn G(x: i32) -> i32 { return x; }
overload fn G(b: bool) -> i32 { if (b) { return 1; } return 0; }

fn Use() -> i32 { return G(3) + G(true); }
