// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/function/overload/import_generic_class.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/function/overload/import_generic_class.carbon

// The members of an imported generic class's `overload fn` set lower in the
// importing file once per specific it uses, under the set-relative marker THEN
// the specific fingerprint (`_CAdd:overload0.Box.Main.<16 hex>` and
// `_CAdd:overload1.Box.Main.<16 hex>`, as in generic_class.carbon for the
// declaring file): two `define`s for `Box(i64)`, and `Use` calls each once.

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

fn Use() -> i32 {
  var b: Box(i64) = Box(i64).Make(1, 0 as i64);
  b.Add(1);
  b.Add(true);
  return b.Get();
}
