// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --dump-sem-ir-ranges=only
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/function/overload/fail_todo_gates.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/function/overload/fail_todo_gates.carbon

// The 0.1 gates of fork/overload/plan.md D-OV-6, one subfile per gate. Each is
// a semantics TODO at the declaration (or, for the two call-site gates, at
// the call) so that overload resolution only ever sees supported members.
// OV-2 lifted (i) generic members, (ii) sets in generic scopes and (iv)
// `extern` members, and deleted their subfiles (generic.carbon,
// generic_class_method_set.carbon and import.carbon pin the lifted shapes).

// --- fail_todo_ref_param.carbon

library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_todo_ref_param.carbon:[[@LINE+4]]:15: error: semantics TODO: ``overload fn` with a non-value explicit parameter` [SemanticsTodo]
// CHECK:STDERR: overload fn F(ref x: i32);
// CHECK:STDERR:               ^~~~~~~~~~
// CHECK:STDERR:
overload fn F(ref x: i32);

// --- fail_todo_entry_point.carbon

library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_todo_entry_point.carbon:[[@LINE+4]]:1: error: semantics TODO: ``overload` on the entry point` [SemanticsTodo]
// CHECK:STDERR: overload fn Run() -> i32 { return 0; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
overload fn Run() -> i32 { return 0; }

// --- fail_todo_access.carbon

library "[[@TEST_NAME]]";

overload fn F(x: i32);
// CHECK:STDERR: fail_todo_access.carbon:[[@LINE+4]]:1: error: semantics TODO: ``overload fn` members with differing access` [SemanticsTodo]
// CHECK:STDERR: private overload fn F(b: bool);
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
private overload fn F(b: bool);

// --- fail_todo_self_only.carbon

library "[[@TEST_NAME]]";

class C {
  overload fn F(self, x: i32);
  // CHECK:STDERR: fail_todo_self_only.carbon:[[@LINE+4]]:3: error: semantics TODO: ``overload fn` members distinguished only by `self`` [SemanticsTodo]
  // CHECK:STDERR:   overload fn F(ref self, x: i32);
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  overload fn F(ref self, x: i32);
}

// --- fail_todo_interface.carbon

library "[[@TEST_NAME]]";

interface I {
  // CHECK:STDERR: fail_todo_interface.carbon:[[@LINE+4]]:3: error: semantics TODO: ``overload fn` in an interface` [SemanticsTodo]
  // CHECK:STDERR:   overload fn M(self);
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  overload fn M(self);
}

// --- fail_todo_mixed_self.carbon

library "[[@TEST_NAME]]";

class C {
  overload fn F(self, x: i32);
  // CHECK:STDERR: fail_todo_mixed_self.carbon:[[@LINE+4]]:3: error: semantics TODO: ``overload fn` members that disagree on `self`` [SemanticsTodo]
  // CHECK:STDERR:   overload fn F(b: bool);
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  overload fn F(b: bool);
}

// --- fail_todo_template_dependent.carbon

library "[[@TEST_NAME]]";

overload fn F(unused x: i32) -> i32 { return 1; }
overload fn F(unused b: bool) -> i32 { return 2; }

fn T2(template T: type, x: T) -> i32 { return F(x); }

// --- fail_todo_explicit_ref_receiver.carbon

library "[[@TEST_NAME]]";

class R {
  var n: i32;
  overload fn Bump(ref self, x: i32) { self.n = self.n + x; }
  overload fn Bump(unused ref self, unused b: bool) {}
}

// The same call through `r.Bump(1)` is the positive `method_set` shape.
// CHECK:STDERR: fail_todo_explicit_ref_receiver.carbon:[[@LINE+4]]:16: error: semantics TODO: `explicit receiver for a `ref self`/`addr self` overload member` [SemanticsTodo]
// CHECK:STDERR: fn Use(r: R) { R.Bump(r, 1); }
// CHECK:STDERR:                ^~~~~~~~~~~~
// CHECK:STDERR:
fn Use(r: R) { R.Bump(r, 1); }

// --- fail_todo_impl_body.carbon

library "[[@TEST_NAME]]";

interface I {
  fn Get(self) -> i32;
}

class D {
  extend impl as I {
    // CHECK:STDERR: fail_todo_impl_body.carbon:[[@LINE+4]]:5: error: semantics TODO: ``overload fn` in an `impl` body` [SemanticsTodo]
    // CHECK:STDERR:     overload fn Get(unused self) -> i32 { return 1; }
    // CHECK:STDERR:     ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // CHECK:STDERR:
    overload fn Get(unused self) -> i32 { return 1; }
  }
}
