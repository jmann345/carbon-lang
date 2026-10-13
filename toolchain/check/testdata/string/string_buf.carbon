// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/string/string_buf.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/string/string_buf.carbon

// Fork (ST-1, fork/string/plan.md §4): the owning `Core.StringBuf`
// (D-ST-4..7).

// --- concat.carbon

library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn Concat(a: str, b: str) -> Core.StringBuf { return a + b; }
fn Chain(a: str) -> Core.StringBuf { return a + a + a; }
fn Dup(s: Core.StringBuf) -> Core.StringBuf { return Core.StringBuf.Make(s); }
//@dump-sem-ir-end

// --- append.carbon

library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn Append(s: str) -> i64 {
  var b: Core.StringBuf = Core.StringBuf.Make(s);
  b += "!";
  b += b;
  return b.Size();
}
//@dump-sem-ir-end

// --- view.carbon

library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn View(b: Core.StringBuf) -> str { return b; }
fn LetView(a: str) -> i64 {
  var c: Core.StringBuf = a + a;
  let v: str = c;
  return v.Size();
}
//@dump-sem-ir-end
