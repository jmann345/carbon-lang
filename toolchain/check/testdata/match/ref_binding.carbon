// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/ref_binding.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/ref_binding.carbon

// `ref` case bindings (W-008 W8b): the binding aliases the scrutinee
// itself, which must be a durable reference — here a `var` local — so a
// write through the binding is visible after the `match`
// (docs/design/pattern_matching.md, "Name binding patterns": for `ref`
// binding patterns the user-provided scrutinee must meet the durable
// reference requirement itself).

//@dump-sem-ir-begin
fn F() -> i32 {
  var x: i32 = 5;
  match (x) {
    case ref a: i32 => { a = 7; }
  }
  return x;
}
//@dump-sem-ir-end
