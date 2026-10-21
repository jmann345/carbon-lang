// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/operators/overloaded/indirect_index_with.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/operators/overloaded/indirect_index_with.carbon

// --- types.carbon

library "[[@TEST_NAME]]";

class Copyable {
  impl as Core.Copy {
    fn Op(unused self) -> Self { return {}; }
  }
}
class NonCopyable {}
class SubscriptType {}

class C {
  var ptr: Copyable*;
}

//@dump-sem-ir-begin
impl C as Core.IndirectIndexWith(SubscriptType) where .ElementType = Copyable {
  fn Ref(self, unused subscript: SubscriptType) -> ref Copyable {
    return *self.ptr;
  }
}
//@dump-sem-ir-end

class CNonCopy {
  var ptr: NonCopyable*;
}

impl CNonCopy as Core.IndirectIndexWith(SubscriptType)
    where .ElementType = NonCopyable {
  fn Ref(self, unused subscript: SubscriptType) -> ref NonCopyable {
    return *self.ptr;
  }
}

// --- ref_copyable.carbon

library "[[@TEST_NAME]]";

import library "types";

fn F(c: C, s: SubscriptType, v: Copyable) -> ref Copyable {
  //@dump-sem-ir-begin
  c.(Core.IndirectIndexWith(SubscriptType).Ref)(s) = v;
  return c.(Core.IndirectIndexWith(SubscriptType).Ref)(s);
  //@dump-sem-ir-end
}

// --- ref_non_copyable.carbon

library "[[@TEST_NAME]]";

import library "types";

fn F(c: CNonCopy, s: SubscriptType) -> ref NonCopyable {
  //@dump-sem-ir-begin
  return c.(Core.IndirectIndexWith(SubscriptType).Ref)(s);
  //@dump-sem-ir-end
}

// --- at_from_blanket_impl.carbon

library "[[@TEST_NAME]]";

import library "types";

fn F(c: C, s: SubscriptType) -> Copyable {
  //@dump-sem-ir-begin
  return c.(Core.IndexWith(SubscriptType).At)(s);
  //@dump-sem-ir-end
}

// --- fail_at_non_copyable.carbon

library "[[@TEST_NAME]]";

import library "types";

fn F(c: CNonCopy, s: SubscriptType) {
  c.(Core.IndexWith(SubscriptType).At)(s);
}

// --- subscript_copyable.carbon

library "[[@TEST_NAME]]";

import library "types";

fn F(c: C, s: SubscriptType) -> Copyable {
  //@dump-sem-ir-begin
  return c[s];
  //@dump-sem-ir-end
}

// --- subscript_non_copyable.carbon

library "[[@TEST_NAME]]";

import library "types";

fn F(c: CNonCopy, s: SubscriptType) -> ref NonCopyable {
  //@dump-sem-ir-begin
  return c[s];
  //@dump-sem-ir-end
}

// --- subscript_assign.carbon

library "[[@TEST_NAME]]";

import library "types";

fn F(c: C, s: SubscriptType, v: Copyable) {
  //@dump-sem-ir-begin
  c[s] = v;
  //@dump-sem-ir-end
}
