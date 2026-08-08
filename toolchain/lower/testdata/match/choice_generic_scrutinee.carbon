// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/match/choice_generic_scrutinee.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/match/choice_generic_scrutinee.carbon
// CHECK:STDERR: {{.*}}/prelude/try.carbon:20:1: error: name `Core.ImplicitAs` implicitly referenced here, but not found [CoreNameNotFound]
// CHECK:STDERR: choice ControlFlow(C: type, B: type) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: {{.*}}/prelude/try.carbon:20:1: error: name `Core.ImplicitAs` implicitly referenced here, but not found [CoreNameNotFound]
// CHECK:STDERR: choice ControlFlow(C: type, B: type) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:

// Discriminant dispatch on a specific of a payload-free generic choice
// (W5-S3a): the specific's object representation supplies the integer
// discriminant the arms compare against, and constructing an alternative
// constant through the specific stores the same discriminant the dispatch
// reads back.

choice P(T: type) {
  A,
  B
}

fn Classify(p: P(i32)) -> i32 {
  match (p) {
    case .A => { return 0; }
    case .B => { return 1; }
  }
  return -1;
}

fn Run() -> i32 {
  // `let` binds the alternative constant's value directly (choices have no
  // `Copy` impl, so return/`var` initialization from the constant is out);
  // the lowered constant carries the discriminant the dispatch reads back.
  let b: P(i32) = P(i32).B;
  return Classify(b);
}

