// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --dump-sem-ir-ranges=only
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/function/overload/generic.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/function/overload/generic.carbon

// Generic members of `overload fn` sets (fork/overload/plan.md OV-2, §1.B.4).
// A generic member is probed by non-diagnosing deduction inside the same
// discard scope as the conversion probe (D-OV-4 step 2(d)); the committed call
// re-deduces diagnosing and names a specific of the member. Declaration-order
// first-match over mixed generic and non-generic members is pure order: a
// generic member declared first accepts every call it can deduce.

// --- generic_second.carbon

library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
overload fn Kind(unused x: i32) -> i32 { return 1; }
overload fn Kind[T: type](unused x: T) -> i32 { return 2; }

// `Kind(5)` selects member 0 (the literal converts to `i32`); `Kind(true)`
// is rejected by member 0 and deduces `T = bool` for member 1.
fn Use() -> i32 { return Kind(5) + Kind(true); }
//@dump-sem-ir-end

// --- generic_first.carbon

library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
overload fn Kind[T: type](unused x: T) -> i32 { return 2; }
overload fn Kind(unused x: i32) -> i32 { return 1; }

// Pure declaration order: the generic member swallows the call with
// `T = Core.IntLiteral`; the exact non-generic member is never reached.
fn Use() -> i32 { return Kind(5); }
//@dump-sem-ir-end

// --- fail_deduce_all.carbon

library "[[@TEST_NAME]]";

overload fn Only[T: Core.ImplicitAs(i32)](unused x: T) -> i32 { return 1; }
overload fn Only[T: Core.ImplicitAs(i64)](unused x: T) -> i32 { return 2; }

// `bool` satisfies neither constraint, so both members are rejected by
// deduction (reason 2) and nothing is diagnosed by the probes themselves.
fn Use() -> i32 { return Only(true); }
