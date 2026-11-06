// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/destroy.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/variadics/fail_todo_cleanup.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/variadics/fail_todo_cleanup.carbon

// --- fail_todo_cleanup_statement.carbon
library "[[@TEST_NAME]]";

class C {
  impl as Core.Destroy {
    fn Op(ref self);
  }

  fn Make(c: Self) -> Self;
}

fn Consume(c: C);

fn F(... each c: C) {
  // CHECK:STDERR: fail_todo_cleanup_statement.carbon:[[@LINE+4]]:3: error: semantics TODO: `pack expansion element that needs a cleanup` [SemanticsTodo]
  // CHECK:STDERR:   ... Consume(C.Make(each c));
  // CHECK:STDERR:   ^~~
  // CHECK:STDERR:
  ... Consume(C.Make(each c));
}

// --- fail_todo_cleanup_argument.carbon
library "[[@TEST_NAME]]";

class C {
  impl as Core.Destroy {
    fn Op(ref self);
  }

  fn Make(c: Self) -> Self;
}

fn ForEach(... each c: C);

fn F(... each c: C) {
  // CHECK:STDERR: fail_todo_cleanup_argument.carbon:[[@LINE+4]]:11: error: semantics TODO: `pack expansion element that needs a cleanup` [SemanticsTodo]
  // CHECK:STDERR:   ForEach(... C.Make(each c));
  // CHECK:STDERR:           ^~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  ForEach(... C.Make(each c));
}
