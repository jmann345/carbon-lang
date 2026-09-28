// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/function/overload/generic.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/function/overload/generic.carbon

// A generic member of an `overload fn` set lowers per specific, and the
// specific's mangled name carries both the set-relative marker and the
// specific fingerprint (`_CKind:overload1.Main.<16 hex>`) beside the
// non-generic member's `_CKind:overload0.Main` (D-OV-5).

// --- kind.carbon

library "[[@TEST_NAME]]";

overload fn Kind(unused x: i32) -> i32 { return 1; }
overload fn Kind[T: type](unused x: T) -> i32 { return 2; }

fn Use() -> i32 { return Kind(5) + Kind(true); }

// --- discard_probe_constants.carbon

library "[[@TEST_NAME]]";

// Member 0 is a generic member that deduction ACCEPTS (`T = bool`) and the
// conversion probe then REJECTS (`false` does not convert to `i32`), so the
// call commits to member 1. The specific `Mixed(bool)` was minted by the
// rejected probe and is a persistent side effect (fork/overload/plan.md D-OV-4
// step 2(e)(a)): an extra `define` for it MAY appear here alongside the call
// to member 1 — predicted, not forbidden. The pin is the call: `Use` calls
// `_CMixed:overload1.Main`, never a specific of member 0.
overload fn Mixed[T: type](unused x: T, unused y: i32) -> i32 { return 1; }
overload fn Mixed(unused a: bool, unused b: bool) -> i32 { return 2; }

fn Use() -> i32 { return Mixed(true, false); }
