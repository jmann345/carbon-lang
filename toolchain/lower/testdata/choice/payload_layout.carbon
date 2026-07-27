// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/choice/payload_layout.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/choice/payload_layout.carbon

// The F-007k layout arbiter (fork/w5-choice/plan.md risk R-6): the payload
// region must lower as a single `[N x i8]` byte array whose size is the MAX
// over the payload tuples — 16 bytes here: (i64, i32) is 12 bytes rounded up
// to its 8-byte alignment; (i32) is 4 — with every payload tuple accessed at
// byte offset 0. Sequential (non-overlapping) layout would produce a visibly
// larger array and a nonzero offset for one of the constructors' stores. The
// `None` constant additionally pins the payload-covering constant of a
// payload-carrying choice: a struct constant whose payload element is poison
// (the `UninitializedValue` lowering).

choice Sized {
  Small(a: i32),
  // CHECK:STDERR: payload_layout.carbon:[[@LINE+7]]:9: error: duplicate name `a` being declared in the same scope [NameDeclDuplicate]
  // CHECK:STDERR:   Large(a: i64, b: i32),
  // CHECK:STDERR:         ^
  // CHECK:STDERR: payload_layout.carbon:[[@LINE-4]]:9: note: name is previously declared here [NameDeclPrevious]
  // CHECK:STDERR:   Small(a: i32),
  // CHECK:STDERR:         ^~~~~~
  // CHECK:STDERR:
  Large(a: i64, b: i32),
  None
}

let global_none: Sized = Sized.None;

fn MakeSmall(n: i32) -> Sized {
  return Sized.Small(n);
}

fn MakeLarge(a: i64, b: i32) -> Sized {
  return Sized.Large(a, b);
}

fn Classify(s: Sized) -> i32 {
  match (s) {
    case .None => { return 0; }
    default => { return 1; }
  }
  return -1;
}

fn Use(n: i32) {
  // Scope exit of a local exercises the destroy path for the payload region.
  // CHECK:STDERR: payload_layout.carbon:[[@LINE+4]]:7: warning: binding `v` unused [UnusedBinding]
  // CHECK:STDERR:   var v: Sized = MakeSmall(n);
  // CHECK:STDERR:       ^~~~~~~~
  // CHECK:STDERR:
  var v: Sized = MakeSmall(n);
}
