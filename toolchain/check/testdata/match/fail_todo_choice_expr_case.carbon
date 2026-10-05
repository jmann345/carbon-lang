// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/fail_todo_choice_expr_case.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/fail_todo_choice_expr_case.carbon
// CHECK:STDERR: {{.*}}/prelude/types/cpp/slice.carbon:69:9: error: cannot access member of interface `Destroy` in type `C.(CppContiguousRange.SizeType)` that does not implement that interface [MissingImplInMemberAccess]
// CHECK:STDERR:         self.Size().(ImplicitAs(u64).Convert)().(As(i64).Convert)());
// CHECK:STDERR:         ^~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: {{.*}}/prelude/types/cpp/slice.carbon:68:9: error: cannot access member of interface `Destroy` in type `C.(CppContiguousRange.DataType)` that does not implement that interface [MissingImplInMemberAccess]
// CHECK:STDERR:         self.Data().(CppDataPointer.Raw)(),
// CHECK:STDERR:         ^~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: {{.*}}/prelude/types/cpp/slice.carbon:64:1: error: orphan `impl` found; something in the self-type or constraint must be defined in the same file [ImplIsOrphan]
// CHECK:STDERR: impl forall [C: CppContiguous where .Element impls Copy & Destroy]
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:

// An expression case pattern on a choice scrutinee that names no
// alternative of the scrutinee's choice type (here an integer literal)
// stays behind its own gate, narrowed from the combined W4 slice-gate
// string at W8c (W-008 plan §3.3): the design compares it with `==`, which
// in-slice choices do not implement (plan §1.3). Pinned to the arm's
// `case` token, the choice-scrutinee backstop in `DoMatchCaseExprPattern`
// (pattern_match.cpp).

choice Two {
  A,
  B
}

fn F(c: Two) -> i32 {
  match (c) {
    // CHECK:STDERR: fail_todo_choice_expr_case.carbon:[[@LINE+4]]:5: error: semantics TODO: `match case expression pattern on a choice scrutinee that is not an alternative` [SemanticsTodo]
    // CHECK:STDERR:     case 5 => { return 1; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR:
    case 5 => { return 1; }
    default => { return 0; }
  }
  return -1;
}
