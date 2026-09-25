// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/match/var_binding.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/match/var_binding.carbon

// `var` case bindings must lower to one alloca per arm, initialized by
// copy from the scrutinee in the arm's body block — storage is NOT aliased
// across arms (docs/design/pattern_matching.md, "Pattern match control
// flow") — and writes through the binding must hit the arm's own storage,
// never the scrutinee. `ref` bindings are the opposite pin: no alloca, no
// copy, writes hit the scrutinee's storage.

fn TwoVarArms(x: i32) -> i32 {
  match (x) {
    case var a: i32 if (a > 9) => { a = a + 1; return a; }
    case var b: i32 => { b = b + 2; return b; }
    default => { return -1; }
  }
  return -2;
}

fn VarTuple(p: (i32, i32)) -> i32 {
  match (p) {
    case var (a: i32, b: i32) => { a = a + b; return a; }
    default => { return -1; }
  }
  return -2;
}

fn RefAlias() -> i32 {
  var x: i32 = 5;
  match (x) {
    case ref a: i32 => { a = 7; }
    default => { x = 0; }
  }
  return x;
}
