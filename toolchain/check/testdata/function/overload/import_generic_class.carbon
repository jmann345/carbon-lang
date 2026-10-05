// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --dump-sem-ir-ranges=only
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/function/overload/import_generic_class.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/function/overload/import_generic_class.carbon

// An `overload fn` set declared in a generic class and reached through an
// import (fork/overload/plan.md OV-2, §1.B.1 and §1.B.5): the imported set's
// type carries the class's self specific (`OverloadSetType.specific_id`,
// localized with the set), so naming the set through `Box(i64)` in the
// importing library substitutes that specific exactly as it does in the
// declaring file (generic_class_method_set.carbon), and each committed callee
// is a specific function of the selected member.
//
// Spelling per R3: `T: Core.Copy` because `Make` copies its `t: T` parameter
// into the `tag` field.

// --- lib.carbon

library "[[@TEST_NAME]]";

class Box(T: Core.Copy) {
  var tag: T;
  var total: i32;
  fn Make(x: i32, t: T) -> Box(T) { return {.tag = t, .total = x}; }
  overload fn Add(ref self, n: i32) { self.total = self.total + n; }
  overload fn Add(ref self, b: bool) { if (b) { self.total = self.total + 100; } }
  fn Get(self) -> i32 { return self.total; }
}

// --- use.carbon

library "[[@TEST_NAME]]";

import library "lib";

//@dump-sem-ir-begin
fn Use() -> i32 {
  var b: Box(i64) = Box(i64).Make(1, 0 as i64);
  b.Add(1);
  b.Add(true);
  return b.Get();
}
//@dump-sem-ir-end
