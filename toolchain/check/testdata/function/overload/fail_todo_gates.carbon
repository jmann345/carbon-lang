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
// OV-2 lifts (i), (ii) and (iv) and deletes those subfiles in the same commit.

// --- fail_todo_generic_member.carbon

library "[[@TEST_NAME]]";

overload fn F[T: type](x: T);

// --- fail_todo_generic_scope.carbon

library "[[@TEST_NAME]]";

class Box(T: type) {
  overload fn F(self);
}

// --- fail_todo_ref_param.carbon

library "[[@TEST_NAME]]";

overload fn F(ref x: i32);

// --- fail_todo_extern.carbon

library "[[@TEST_NAME]]";

extern overload fn F(x: i32);

// --- fail_todo_entry_point.carbon

library "[[@TEST_NAME]]";

overload fn Run() -> i32 { return 0; }

// --- fail_todo_access.carbon

library "[[@TEST_NAME]]";

overload fn F(x: i32);
private overload fn F(b: bool);

// --- fail_todo_self_only.carbon

library "[[@TEST_NAME]]";

class C {
  overload fn F(self, x: i32);
  overload fn F(ref self, x: i32);
}

// --- fail_todo_interface.carbon

library "[[@TEST_NAME]]";

interface I {
  overload fn M(self);
}

// --- fail_todo_mixed_self.carbon

library "[[@TEST_NAME]]";

class C {
  overload fn F(self, x: i32);
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
fn Use(r: R) { R.Bump(r, 1); }

// --- fail_todo_impl_body.carbon

library "[[@TEST_NAME]]";

interface I {
  fn Get(self) -> i32;
}

class D {
  extend impl as I {
    overload fn Get(unused self) -> i32 { return 1; }
  }
}
