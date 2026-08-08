// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/choice/fail_generic_payload.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/choice/fail_generic_payload.carbon

// --- fail_not_trivial_in_specific.carbon
library "[[@TEST_NAME]]";

// SF-6 enforcement moves to monomorphization for symbolic payload types
// (fork/w5-s3/plan.md §2.3): `P(C)`'s substituted payload element `C` is not
// trivially copyable and destructible, so the specific fails to resolve at
// the use that forces it — the recorded trade is that the diagnostic lands
// here, not at the declaration (the `IncompleteTypeInMonomorphization`
// placement precedent).
class C {}

choice P(T: type) {
  Wrap(a: T),
  None
}

fn F() {
  // CHECK:STDERR: fail_not_trivial_in_specific.carbon:[[@LINE+7]]:10: error: unable to monomorphize specific `P(C)` [ResolvingSpecificHere]
  // CHECK:STDERR:   var p: P(C);
  // CHECK:STDERR:          ^
  // CHECK:STDERR: fail_not_trivial_in_specific.carbon:[[@LINE-6]]:1: note: choice alternative payload type `C` is not trivially copyable and destructible in this specific [ChoicePayloadNotTrivialInSpecific]
  // CHECK:STDERR: }
  // CHECK:STDERR: ^
  // CHECK:STDERR:
  var p: P(C);
}

// --- fail_mutual_by_value_recursion.carbon
library "[[@TEST_NAME]]";

// Mutual by-value generic recursion between a choice payload and a class
// field: completing the substituted payload tuple `(G(i32),)` would complete
// `G(i32)`, whose field `P(i32)` re-enters the choice specific's own
// in-progress resolution and dies on the forward-reference CHECK. The
// structural SF-6 pre-filter in the `CustomLayoutType` eval hook rejects the
// disallowed class kind BEFORE any completion, so this is the real
// per-specific diagnostic, not a crash.
class G(T: type);

choice P(T: type) {
  A(x: G(T)),
  B
}

class G(T: type) {
  var p: P(T);
}

fn F() {
  // CHECK:STDERR: fail_mutual_by_value_recursion.carbon:[[@LINE+7]]:10: error: unable to monomorphize specific `P(i32)` [ResolvingSpecificHere]
  // CHECK:STDERR:   var p: P(i32);
  // CHECK:STDERR:          ^
  // CHECK:STDERR: fail_mutual_by_value_recursion.carbon:[[@LINE-10]]:1: note: choice alternative payload type `G(i32)` is not trivially copyable and destructible in this specific [ChoicePayloadNotTrivialInSpecific]
  // CHECK:STDERR: }
  // CHECK:STDERR: ^
  // CHECK:STDERR:
  var p: P(i32);
}

// --- fail_self_dependent.carbon
library "[[@TEST_NAME]]";

// The narrowed Self-dependence gate (plan §6): a symbolic payload type in a
// generic choice proceeds to synthesis, but one that mentions the choice
// being defined keeps a definition-time rejection with the narrowed string.
choice P(T: type) {
  // CHECK:STDERR: fail_self_dependent.carbon:[[@LINE+4]]:4: error: semantics TODO: `choice alternative payload with Self-dependent type` [SemanticsTodo]
  // CHECK:STDERR:   A(x: Self*),
  // CHECK:STDERR:    ^~~~~~~~~~
  // CHECK:STDERR:
  A(x: Self*),
  B
}
