// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/string/compare.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/string/compare.carbon

// Fork (ST-1, fork/string/plan.md §4): byte-wise `EqWith` and `OrderedWith`
// on `str` and `Core.StringBuf`, all four operand pairs (D-ST-2, D-ST-3,
// D-ST-8).

// --- str_str.carbon

library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn Eq(a: str, b: str) -> bool { return a == b; }
fn Ne(a: str, b: str) -> bool { return a != b; }
fn Lt(a: str, b: str) -> bool { return a < b; }
fn Ge(a: str, b: str) -> bool { return a >= b; }
//@dump-sem-ir-end

// --- mixed.carbon

library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn EqBufStr(a: Core.StringBuf, b: str) -> bool { return a == b; }
fn LtStrBuf(a: str, b: Core.StringBuf) -> bool { return a < b; }
fn GtBufBuf(a: Core.StringBuf, b: Core.StringBuf) -> bool { return a > b; }
//@dump-sem-ir-end

// --- generic.carbon

library "[[@TEST_NAME]]";

fn Min[T: Core.Ordered & Core.Copy](a: T, b: T) -> T {
  return if a < b then a else b;
}

//@dump-sem-ir-begin
fn UseMin() -> str { return Min("pear", "apple"); }
//@dump-sem-ir-end
