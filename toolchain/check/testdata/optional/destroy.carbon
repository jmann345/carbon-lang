// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/optional/destroy.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/optional/destroy.carbon

// Fork (OP-2, fork/optional2/plan.md §4, W-170): a `Core.Optional(T)` owns the
// value it holds (fork design F-015). The default storage declares a `Destroy`
// that destroys the value when there is one, and the `Optional` adapter is
// destroyed as its storage (fork design F-016); the pointer niche declares
// none, so `Core.Optional(T*)` stays trivially destructible and a union may
// hold one. Only `Core.Optional(T*)` may be declared without an initializer.

// --- concrete.carbon

library "[[@TEST_NAME]]";

class Tracked {
  impl as Core.Copy {
    fn Op(unused self) -> Self { return {}; }
  }
  impl as Core.Destroy {
    fn Op(unused ref self) {}
  }
}

//@dump-sem-ir-begin
fn Hold(t: Tracked) {
  var unused o: Core.Optional(Tracked) = Core.Optional(Tracked).Some(t);
}
//@dump-sem-ir-end

// --- pointer.carbon

library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn HoldPointer(p: i32*) {
  var unused o: Core.Optional(i32*) = Core.Optional(i32*).Some(p);
}
//@dump-sem-ir-end

// --- generic.carbon

library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn HoldGeneric[T: Core.Copy & Core.Destroy](a: T) -> bool {
  let o: Core.Optional(T) = Core.Optional(T).Some(a);
  return o.HasValue();
}
//@dump-sem-ir-end

// --- union_pointer_field.carbon

library "[[@TEST_NAME]]";

union U {
  var o: Core.Optional(i32*);
  var n: i32;
}

// --- fail_union_value_field.carbon

library "[[@TEST_NAME]]";

// `Core.Optional(i32)`'s storage defines a destructor with a non-empty body, so
// it is not `TrivialDestructor` (docs/design/classes.md), and neither is the
// `Optional` adapter of it (fork design F-016): it is not a union field type
// (docs/design/unions.md).
union V {
  var o: Core.Optional(i32);
  var n: i32;
}

// --- unformed_pointer.carbon

library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn DeclarePointer() {
  var unused o: Core.Optional(i32*);
}
//@dump-sem-ir-end

// --- fail_unformed_value.carbon

library "[[@TEST_NAME]]";

// Only `Core.Optional(T*)` is `UnformedInit`: the default storage's `Destroy`
// reads `has_value`, which an unformed Optional would leave uninitialized, so a
// non-pointer Optional needs an initializer, as a `Core.Buf` does.
fn DeclareValue() {
  var unused o: Core.Optional(i32);
}
