// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/function/overload/default_values.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/function/overload/default_values.carbon

// The committed call to a defaulted `overload fn` member passes the default
// value for the omitted argument (fork/overload/ov4-plan.md OV-4): the lowered
// call to member 0 receives the constant `10`, and a class-typed default is
// initialized in the caller as the ordinary call initializes it. In a
// template's specific, the deferred call is resolved and filled the same way.

// --- omitted_and_supplied.carbon

library "[[@TEST_NAME]]";

overload fn Scale(x: i32, factor: i32 = 10) -> i32 { return x * factor; }
overload fn Scale(unused b: bool) -> i32 { return 0; }

fn Use() -> i32 { return Scale(1) + Scale(2, 3); }

// --- class_default.carbon

library "[[@TEST_NAME]]";

class C { var v: i32; }
fn MakeC() -> C { return {.v = 7}; }

overload fn F(c: C, d: C = {.v = 3}) -> i32 { return c.v * 10 + d.v; }
overload fn F(unused b: bool) -> i32 { return -1; }

fn Use() -> i32 { return F(MakeC()) + F(MakeC(), MakeC()); }

// --- template_dependent_default.carbon

library "[[@TEST_NAME]]";

overload fn F(x: i32, y: i32 = 2) -> i32 { return x * 10 + y; }
overload fn F(unused b: bool) -> i32 { return -1; }

// Each specific of `T` resolves its deferred call: `T(i32)` calls member 0
// with the default `2` filled, and `T(bool)` calls member 1.
fn T(template U: type, u: U) -> i32 { return F(u); }

fn Use() -> i32 { return T(i32, 1) + T(bool, true); }
