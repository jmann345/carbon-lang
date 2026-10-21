// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/core_optional_view.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/core_optional_view.carbon

// Fork (SV-1, fork/sumtype-interop/plan.md §1.7): a `Core.Optional(T)`
// scrutinee whose payload is a concrete 0.1 choice payload type is matched as
// its view `Core.CppCompat.StdOptional(T)`, converted by value through the
// prelude's `ImplicitAs` impl; the class is unchanged.

// --- concrete.carbon

library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn F(o: Core.Optional(i32)) -> i32 {
  match (o) {
    case .Some(value: i32) => {
      return value;
    }
    case .None => {
      return -1;
    }
  }
  return -2;
}
//@dump-sem-ir-end

// --- pointer.carbon

library "[[@TEST_NAME]]";

// `Core.Optional(T*)`'s `None` is the null pointer; `.Some` binds the
// non-null `T*`.
fn G(p: Core.Optional(i32*)) -> i32 {
  if (let .Some(q: i32*) = p) {
    return *q;
  }
  return 0;
}

// --- fail_todo_generic.carbon

library "[[@TEST_NAME]]";

// A symbolic payload type is not viewed: whether `StdOptional(T)` is a valid
// choice would be known only at monomorphization (§1.7).
fn H[T: Core.Copy & Core.Destroy](o: Core.Optional(T)) -> bool {
  match (o) {
    case .Some(unused value: T) => {
      return true;
    }
    case .None => {
      return false;
    }
  }
  return false;
}

// --- fail_todo_aggregate.carbon

library "[[@TEST_NAME]]";

// Nor a payload that is not a 0.1 choice payload type (SF-6).
fn A(o: Core.Optional((i32, i32))) -> bool {
  if (let .Some(unused value: (i32, i32)) = o) {
    return true;
  }
  return false;
}

// --- fail_todo_ref_binding.carbon

library "[[@TEST_NAME]]";

// The view is a by-value copy, so a `ref` payload binding is rejected.
fn R() {
  var o: Core.Optional(i32) = Core.Optional(i32).Some(4);
  match (o) {
    case .Some(ref n: i32) => {
      n = 9;
    }
    case .None => {}
  }
}

// --- fail_unknown_alternative.carbon

library "[[@TEST_NAME]]";

fn K(o: Core.Optional(i32)) {
  match (o) {
    case .Ok(unused value: i32) => {}
    default => {}
  }
}
