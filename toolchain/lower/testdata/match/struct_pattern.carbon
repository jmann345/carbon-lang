// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/match/struct_pattern.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/match/struct_pattern.carbon

// Struct case patterns lower with ZERO lower-side code (W-077): the check
// layer desugars an arm to `struct_access` field reads (already lowered),
// `icmp` compares folded into one arm condition, and the landed dispatch
// CFG, with the arm's bindings re-extracted in the arm's body block. A
// subset+`_` arm reads only the fields it names; the trailing all-binding
// arm discharges exhaustiveness, so `Dispatch` needs no `default`.

fn Dispatch(p: {.tag: i32, .val: i32}) -> i32 {
  match (p) {
    case {.tag = 1, _} => { return 100; }
    case {.tag = 2, .val = v: i32} => { return v; }
    case {tag: i32, val: i32} => { return tag + val; }
  }
  return -2;
}

fn VarScrutinee() -> i32 {
  var s: {.a: i32, .b: i32} = {.a = 1, .b = 2};
  match (s) {
    case {.a = 1, b: i32} => { return b; }
    default => { return -1; }
  }
  return -2;
}
