// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/uint.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/choice/params.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/choice/params.carbon

// --- empty_params.carbon
library "[[@TEST_NAME]]";

choice Always {
  Sunny()
}

// A zero-payload alternative declared with `()` is function-like: it is
// constructed by calling it.
let mood: Always = Always.Sunny();

// --- params.carbon
library "[[@TEST_NAME]]";

choice C {
  Alt1,
  Alt2(a: i32, b: i64),
  Alt3,
}

let c1: C = C.Alt1;
let c3: C = C.Alt3;

fn Construct(n: i32) -> C {
  return C.Alt2(n, 9);
}

// --- generic_params.carbon
library "[[@TEST_NAME]]";

// A symbolic payload type synthesizes (W5-S3b): the single-alternative choice
// defines and constructs — its discriminant is the empty tuple — though
// matching a fewer-than-two-alternatives specific stays gated (W-068).
// CHECK:STDERR: generic_params.carbon:[[@LINE+7]]:1: error: cannot copy value of type `T` [CopyOfUncopyableType]
// CHECK:STDERR: choice C(T: type) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: generic_params.carbon:[[@LINE+4]]:1: note: type `T` does not implement interface `Core.Copy` [MissingImplInMemberAccessInContext]
// CHECK:STDERR: choice C(T: type) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
choice C(T: type) {
  Alt(a: T)
}

fn Make(n: i32) -> C(i32) {
  // CHECK:STDERR: generic_params.carbon:[[@LINE+7]]:3: error: cannot implicitly convert expression of type `C(T)` to `C(i32)` [ConversionFailure]
  // CHECK:STDERR:   return C(i32).Alt(n);
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR: generic_params.carbon:[[@LINE+4]]:3: note: type `C(T)` does not implement interface `Core.ImplicitAs(C(i32))` [MissingImplInMemberAccessInContext]
  // CHECK:STDERR:   return C(i32).Alt(n);
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  return C(i32).Alt(n);
}

// --- fail_todo_self_param.carbon
library "[[@TEST_NAME]]";

choice C {
  // CHECK:STDERR: fail_todo_self_param.carbon:[[@LINE+4]]:6: error: semantics TODO: `choice alternative payload with Self-dependent type` [SemanticsTodo]
  // CHECK:STDERR:   Alt(a: Self*)
  // CHECK:STDERR:      ^~~~~~~~~~
  // CHECK:STDERR:
  Alt(a: Self*)
}

// --- fail_unknown_payload_type.carbon
library "[[@TEST_NAME]]";

choice C {
  // CHECK:STDERR: fail_unknown_payload_type.carbon:[[@LINE+4]]:10: error: name `NoSuchType` not found [NameNotFound]
  // CHECK:STDERR:   Alt(a: NoSuchType),
  // CHECK:STDERR:          ^~~~~~~~~~
  // CHECK:STDERR:
  Alt(a: NoSuchType),
  Nothing
}

// The alternative whose parameter failed to check must not vanish from the
// choice's scope: this reference resolves to an error binding rather than
// reporting a phantom missing member.
fn F() -> C {
  return C.Alt(1);
}
