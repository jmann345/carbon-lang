// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/named_constraint/fail_template_constraint_requirement_call.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/named_constraint/fail_template_constraint_requirement_call.carbon

// A requirement `fn` of a `template constraint` has no body and is never itself
// called: a call through a type that satisfies the constraint targets the
// type's own member (fork decision F-010 / SC-1, fork/structural/plan.md D-SC-4;
// fill round 2, review findings MINOR-2 / F4).

// --- fail_direct_call.carbon
library "[[@TEST_NAME]]";

// Named with no self, the requirement's `Self` is the constraint's `.Self`
// (D-SC-20), which no type replaces.
template constraint HasCount {
  fn Count() -> i32;
}

template constraint HasMake {
  fn Make() -> Self;
}

class C {
  fn Make() -> C { return {}; }
}

fn K() -> i32 { return HasCount.Count(); }

fn M() -> C { return HasMake.Make(); }

// --- fail_todo_runtime_facet.carbon
library "[[@TEST_NAME]]";

// A runtime facet value is not a type: member access looks into its facet type
// with no self, as for `HasMake.Make`, and a compound access through it is
// upstream's open "associated value lookup on runtime facet value" case
// (member_access.cpp, `GetAssociatedValueImpl`).
template constraint HasMake {
  fn Make() -> Self;
}

class C {
  fn Make() -> C { return {}; }
}

fn ViaLet() -> C {
  let F: HasMake = C;
  return F.Make();
}

fn ViaLetCompound() -> C {
  let F: HasMake = C;
  return F.(HasMake.Make)();
}
