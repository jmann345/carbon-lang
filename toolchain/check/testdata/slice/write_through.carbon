// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/slice/write_through.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/slice/write_through.carbon

// --- write.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn Write(s: Core.Slice(i32), i: i64) {
  s[i] = s[0] + 1;
}
//@dump-sem-ir-end

// --- generic_write.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn Fill[T: Core.Copy & Core.Destroy](s: Core.Slice(T), v: T) {
  s[0] = v;
}
//@dump-sem-ir-end

// --- generic_write_const_element.carbon
library "[[@TEST_NAME]]";

// W-327's current behavior, pinned: the generic body writes through
// `Slice(T)`, and the specific at `T = const i32` is not diagnosed.
fn Fill[T: Core.Copy & Core.Destroy](s: Core.Slice(T), v: T) {
  s[0] = v;
}

fn G(c: Core.Slice(const i32)) {
  Fill(c, c[1]);
}

// --- fail_const_element.carbon
library "[[@TEST_NAME]]";

fn W(s: Core.Slice(const i32)) {
  s[0] = 1;
}

// --- buf_write.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn BufWrite(b: Core.Buf(i32)) {
  b[0] = 7;
}
//@dump-sem-ir-end
