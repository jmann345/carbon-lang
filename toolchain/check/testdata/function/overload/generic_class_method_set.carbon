// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --dump-sem-ir-ranges=only
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/function/overload/generic_class_method_set.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/function/overload/generic_class_method_set.carbon

// An `overload fn` set declared inside a generic class (fork/overload/plan.md
// §1.B.5; D-OV-6 gate (ii) lifted at OV-2). The set's type records the class's
// self specific exactly as a member function's type does, and naming the set
// through `Box(i64)` substitutes that specific, so the bound set names the
// `Box(i64)` set value and each committed callee is a specific function of the
// selected member. The members are effectively non-generic within the
// specific: the enclosing specific supplies the class's bindings.
//
// Spelling per R3: the class parameter is `T: Core.Copy` (the plan's
// `T: type`) because `Make` copies its `t: T` parameter into the `tag` field,
// as toolchain/check/testdata/class/generic/member_type.carbon does.

// --- generic_class.carbon

library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
class Box(T: Core.Copy) {
  var tag: T;
  var total: i32;
  fn Make(x: i32, t: T) -> Box(T) { return {.tag = t, .total = x}; }
  overload fn Add(ref self, n: i32) { self.total = self.total + n; }
  overload fn Add(ref self, b: bool) { if (b) { self.total = self.total + 100; } }
  fn Get(self) -> i32 { return self.total; }
}

fn Use() -> i32 {
  var b: Box(i64) = Box(i64).Make(1, 0 as i64);
  b.Add(1);
  b.Add(true);
  return b.Get();
}
//@dump-sem-ir-end
