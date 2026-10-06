// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/primitives.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/operators/builtin/short_circuit_temporary.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/operators/builtin/short_circuit_temporary.carbon

class C {
  var b: bool;
}

fn Make(b: bool) -> C { return {.b = b}; }

// The right-hand operand's `Make(...)` temporary is destroyed at the end of the
// `and.rhs` or `or.rhs` block, after its member has been read, rather than in
// the resumption block, which is also reached when the operand isn't evaluated
// and which the operand's block doesn't dominate.
//@dump-sem-ir-begin
fn And(c: bool) -> bool {
  return c and Make(true).b;
}

fn Or(c: bool) -> bool {
  return c or Make(false).b;
}
//@dump-sem-ir-end
