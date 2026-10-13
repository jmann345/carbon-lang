// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/optional/compare.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/optional/compare.carbon

// Fork (OP-1, fork/optional/plan.md §4): `Core.Optional(T)` implements
// `EqWith` and `OrderedWith` with itself when `T` is `Core.Eq` or
// `Core.Ordered` (D-OP-1..D-OP-3), the pointer niche included when the pointer
// type is `Core.Eq`.

// --- concrete.carbon

library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn IsEq(a: Core.Optional(i32), b: Core.Optional(i32)) -> bool { return a == b; }
fn IsNe(a: Core.Optional(i32), b: Core.Optional(i32)) -> bool { return a != b; }
fn IsLt(a: Core.Optional(i32), b: Core.Optional(i32)) -> bool { return a < b; }
fn IsLe(a: Core.Optional(i32), b: Core.Optional(i32)) -> bool { return a <= b; }
fn IsGt(a: Core.Optional(i32), b: Core.Optional(i32)) -> bool { return a > b; }
fn IsGe(a: Core.Optional(i32), b: Core.Optional(i32)) -> bool { return a >= b; }
//@dump-sem-ir-end

// --- generic.carbon

library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn Same[T: Core.Eq & Core.Copy & Core.Destroy](a: Core.Optional(T),
                                               b: Core.Optional(T)) -> bool {
  return a == b;
}

fn UseSame(a: Core.Optional(i64)) -> bool { return Same(a, a); }
//@dump-sem-ir-end

// --- ordered_only.carbon

library "[[@TEST_NAME]]";

class Rank {
  var v: i32;
  impl as Core.Copy {
    fn Op(self) -> Self { return {.v = self.v}; }
  }
}

impl Rank as Core.OrderedWith(Rank) {
  fn Less(self, other: Rank) -> bool { return self.v < other.v; }
  fn LessOrEquivalent(self, other: Rank) -> bool { return self.v <= other.v; }
  fn Greater(self, other: Rank) -> bool { return self.v > other.v; }
  fn GreaterOrEquivalent(self, other: Rank) -> bool {
    return self.v >= other.v;
  }
}

//@dump-sem-ir-begin
fn RankLess(a: Core.Optional(Rank), b: Core.Optional(Rank)) -> bool {
  return a < b;
}
//@dump-sem-ir-end

// --- user_pointer.carbon

library "[[@TEST_NAME]]";

class C {
  var v: i32;
}

// Allowed in this library because `C` is local; the prelude gives `C*` no
// `==`, so this impl is what makes `Core.Optional(C*)` comparable.
impl C* as Core.EqWith(C*) {
  fn Equal(self, other: C*) -> bool { return self->v == other->v; }
  fn NotEqual(self, other: C*) -> bool { return self->v != other->v; }
}

//@dump-sem-ir-begin
fn SameC(a: Core.Optional(C*), b: Core.Optional(C*)) -> bool {
  return a == b;
}
//@dump-sem-ir-end
