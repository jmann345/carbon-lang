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
  // CHECK:STDERR: fail_not_trivial_in_specific.carbon:[[@LINE+15]]:10: error: binding pattern has incomplete type `P(C)` in name binding declaration [IncompleteTypeInBindingDecl]
  // CHECK:STDERR:   var p: P(C);
  // CHECK:STDERR:          ^~~~
  // CHECK:STDERR: fail_not_trivial_in_specific.carbon:[[@LINE-9]]:1: note: choice alternative payload type `C` is not trivially copyable and destructible in this specific [ChoicePayloadNotTrivialInSpecific]
  // CHECK:STDERR: choice P(T: type) {
  // CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  // CHECK:STDERR: fail_not_trivial_in_specific.carbon:[[@LINE+8]]:3: error: cannot convert type `P(C)` into type implementing `Core.DefaultOrUnformed` [ConversionFailureTypeToFacet]
  // CHECK:STDERR:   var p: P(C);
  // CHECK:STDERR:   ^~~~~~~~~~~~
  // CHECK:STDERR:
  // CHECK:STDERR: fail_not_trivial_in_specific.carbon:[[@LINE+4]]:7: warning: binding `p` unused [UnusedBinding]
  // CHECK:STDERR:   var p: P(C);
  // CHECK:STDERR:       ^~~~~~~
  // CHECK:STDERR:
  var p: P(C);
}

// --- fail_mutual_by_value_recursion.carbon
library "[[@TEST_NAME]]";

// Mutual by-value generic recursion between a choice payload and a class
// field: the payload names a specific of a class that is only forward
// declared at the choice definition, so it cannot complete — dependently or
// otherwise — and the definition-time completion requirement rejects the
// alternative with the incomplete-payload diagnostic (the class-field
// precedent), instead of CHECK-failing on the payload tuple's forced
// completion. The rejected alternative gets an error binding; the remaining
// payload-free choice monomorphizes cleanly.
class G(T: type);

choice P(T: type) {
  // CHECK:STDERR: fail_mutual_by_value_recursion.carbon:[[@LINE+7]]:4: error: choice alternative payload has incomplete type `G(T)` [IncompleteTypeInChoicePayload]
  // CHECK:STDERR:   A(x: G(T)),
  // CHECK:STDERR:    ^~~~~~~~~
  // CHECK:STDERR: fail_mutual_by_value_recursion.carbon:[[@LINE-6]]:1: note: class was forward declared here [ClassForwardDeclaredHere]
  // CHECK:STDERR: class G(T: type);
  // CHECK:STDERR: ^~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  A(x: G(T)),
  B
}

class G(T: type) {
  var p: P(T);
}

fn F() {
  // CHECK:STDERR: fail_mutual_by_value_recursion.carbon:[[@LINE+8]]:3: error: cannot convert type `P(i32)` into type implementing `Core.DefaultOrUnformed` [ConversionFailureTypeToFacet]
  // CHECK:STDERR:   var p: P(i32);
  // CHECK:STDERR:   ^~~~~~~~~~~~~~
  // CHECK:STDERR:
  // CHECK:STDERR: fail_mutual_by_value_recursion.carbon:[[@LINE+4]]:7: warning: binding `p` unused [UnusedBinding]
  // CHECK:STDERR:   var p: P(i32);
  // CHECK:STDERR:       ^~~~~~~~~
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
