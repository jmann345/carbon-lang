// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/optional/fail_compare.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/optional/fail_compare.carbon

// Fork (OP-1, fork/optional/plan.md §4): what `Core.Optional(T)` comparison
// does not accept (D-OP-1..D-OP-3, W-174, W-176, W-178), and one subsumed
// specialization that compiles today although p5337 makes it an error.

// --- fail_not_eq.carbon

library "[[@TEST_NAME]]";

class NoEq {
  var v: i32;
  impl as Core.Copy {
    fn Op(self) -> Self { return {.v = self.v}; }
  }
}

fn F(a: Core.Optional(NoEq), b: Core.Optional(NoEq)) -> bool {
  return a == b;
}

// --- fail_pointer.carbon

library "[[@TEST_NAME]]";

fn F(a: Core.Optional(i32*), b: Core.Optional(i32*)) -> bool {
  return a == b;
}

// --- fail_value_operand.carbon

library "[[@TEST_NAME]]";

fn F(a: Core.Optional(i32), b: i32) -> bool {
  return a == b;
}

// --- fail_different_payloads.carbon

library "[[@TEST_NAME]]";

fn F(a: Core.Optional(i32), b: Core.Optional(i64)) -> bool {
  return a == b;
}

// --- fail_generic_without_copy.carbon

library "[[@TEST_NAME]]";

fn F[T: Core.Eq](a: Core.Optional(T), b: Core.Optional(T)) -> bool {
  return a == b;
}

// --- fail_specialize.carbon

library "[[@TEST_NAME]]";

class Q {
  var v: i32;
  impl as Core.Copy {
    fn Op(self) -> Self { return {.v = self.v}; }
  }
}

impl Q as Core.EqWith(Q) {
  fn Equal(self, other: Q) -> bool { return self.v == other.v; }
  fn NotEqual(self, other: Q) -> bool { return self.v != other.v; }
}

impl Core.Optional(Q) as Core.EqWith(Core.Optional(Q)) {
  fn Equal(self, unused other: Core.Optional(Q)) -> bool {
    return self.HasValue();
  }
  fn NotEqual(self, unused other: Core.Optional(Q)) -> bool {
    return not self.HasValue();
  }
}

fn F(a: Core.Optional(Q), b: Core.Optional(Q)) -> bool {
  return a == b;
}

// --- todo_fail_specialize_unused.carbon

library "[[@TEST_NAME]]";

// TODO: p5337 makes a non-final impl that a `final` impl subsumes an error at
// its declaration; the toolchain diagnoses it only where it is used
// (`fail_specialize` above), so this declaration alone compiles (W-179).

class R {
  var v: i32;
  impl as Core.Copy {
    fn Op(self) -> Self { return {.v = self.v}; }
  }
}

impl R as Core.EqWith(R) {
  fn Equal(self, other: R) -> bool { return self.v == other.v; }
  fn NotEqual(self, other: R) -> bool { return self.v != other.v; }
}

impl Core.Optional(R) as Core.EqWith(Core.Optional(R)) {
  fn Equal(self, unused other: Core.Optional(R)) -> bool {
    return self.HasValue();
  }
  fn NotEqual(self, unused other: Core.Optional(R)) -> bool {
    return not self.HasValue();
  }
}
