// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/union/basic.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/union/basic.carbon

// Native `union` declarations end to end (fork/unions/plan.md UN-1, W-009):
// the design's spellings (docs/design/unions.md, "Declaring a union",
// "Initialization and assignment", "Writing and reading fields"), R27-diffed.
// A union is a class with `is_union` whose object representation is a
// `custom_layout_type` with every field at offset zero.

// --- declare_and_access.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
union IntOrBytes {
  var word: i32;
  var bytes: array(i8, 4);
}

fn Read(u: IntOrBytes) -> i32 { return u.word; }

fn Write(p: IntOrBytes*) { p->word = 1; }
//@dump-sem-ir-end

// --- unformed_then_assign.carbon
library "[[@TEST_NAME]]";

union IntOrBytes {
  var word: i32;
  var bytes: array(i8, 4);
}

// `var u: IntOrBytes;` is the unformed state: the union implements
// `Core.UnformedInit` through a synthesized empty custom witness, so the
// prelude's blanket `DefaultOrUnformed` impl applies and the initializer is a
// `make_uninitialized` call. The first field write forms the variable.
//@dump-sem-ir-begin
fn UnformedThenAssign() -> i32 {
  var u: IntOrBytes;
  u.word = 5;
  return u.word;
}
//@dump-sem-ir-end

// --- designated_init.carbon
library "[[@TEST_NAME]]";

union IntOrBytes {
  var word: i32;
  var bytes: array(i8, 4);
}

// A struct literal designating exactly one field initializes that field in
// place: one `class_element_access` and a one-element `class_init`, and no
// `struct_value` constant of the union type anywhere (the initializer never
// folds).
//@dump-sem-ir-begin
fn DesignatedInit() -> i32 {
  var v: IntOrBytes = {.word = 5};
  var b: IntOrBytes = {.bytes = (1, 2, 3, 4)};
  return v.word + (b.bytes[3] as i32);
}
//@dump-sem-ir-end

// --- return_designated.carbon
library "[[@TEST_NAME]]";

union IntOrBytes {
  var word: i32;
  var bytes: array(i8, 4);
}

//@dump-sem-ir-begin
fn Make() -> IntOrBytes { return {.word = 7}; }
//@dump-sem-ir-end

// --- let_designated.carbon
library "[[@TEST_NAME]]";

union IntOrBytes {
  var word: i32;
  var bytes: array(i8, 4);
}

//@dump-sem-ir-begin
fn LetDesignated() -> i32 {
  let v: IntOrBytes = {.word = 9};
  return v.word;
}
//@dump-sem-ir-end

// --- from_struct_value.carbon
library "[[@TEST_NAME]]";

union IntOrBytes {
  var word: i32;
  var bytes: array(i8, 4);
}

// A struct value (not a literal) designating one field converts too; the
// element comes from a `struct_access`.
//@dump-sem-ir-begin
fn FromStructValue() -> i32 {
  var s: {.word: i32} = {.word = 1};
  var v: IntOrBytes = s;
  return v.word;
}
//@dump-sem-ir-end

// --- copy.carbon
library "[[@TEST_NAME]]";

union IntOrBytes {
  var word: i32;
  var bytes: array(i8, 4);
}

// Copy initialization and assignment copy the whole object representation
// through the synthesized primitive-copy `Core.Copy` witness.
//@dump-sem-ir-begin
fn Copy(v: IntOrBytes) -> i32 {
  var w: IntOrBytes = v;
  w = v;
  return w.word;
}
//@dump-sem-ir-end

// --- user_copy_impl_shadowed.carbon
library "[[@TEST_NAME]]";

// The synthesized copy witness precedes candidate-impl iteration, so an
// `impl as Core.Copy` written inside the union body is shadowed: the copy
// resolves to the synthesized `custom_witness`, not the user `Op` (the same
// consequence choices have, check/testdata/choice/alternative_copy.carbon).
union Shadowed {
  var a: i32;
  impl as Core.Copy {
    fn Op(self) -> Self { return {.a = 0}; }
  }
}

//@dump-sem-ir-begin
fn CopyShadowed(x: Shadowed) -> i32 {
  var y: Shadowed = x;
  return y.a;
}
//@dump-sem-ir-end

// --- method.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
union IntOrBytes {
  var word: i32;
  var bytes: array(i8, 4);

  fn LowHalf(self) -> i32 { return self.bytes[0] as i32; }
  fn Set(ref self, x: i32) { self.word = x; }
}

fn UseMethods(u: IntOrBytes) -> i32 {
  var v: IntOrBytes = u;
  v.Set(3);
  return v.LowHalf();
}
//@dump-sem-ir-end

// --- impl_member.carbon
library "[[@TEST_NAME]]";

interface I {
  fn Get(self) -> i32;
}

// An `impl` is a permitted union member.
//@dump-sem-ir-begin
union WithImpl {
  var a: i32;
  impl as I {
    fn Get(self) -> i32 { return self.a; }
  }
}

fn UseImpl(u: WithImpl) -> i32 { return u.Get(); }
//@dump-sem-ir-end

// --- forward_decl.carbon
library "[[@TEST_NAME]]";

// A forward declaration merges with the definition: one `class_decl`, no
// diagnostic.
//@dump-sem-ir-begin
union U;

union U {
  var a: i32;
}

fn UseU(u: U) -> i32 { return u.a; }
//@dump-sem-ir-end

// --- member_of_class.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
class C {
  union Inner {
    var a: i32;
  }
  var u: Inner;
}

fn UseInner(c: C) -> i32 { return c.u.a; }
//@dump-sem-ir-end

// --- namespace_scoped.carbon
library "[[@TEST_NAME]]";

namespace N;

//@dump-sem-ir-begin
union N.U {
  var a: i32;
}

fn UseNU(u: N.U) -> i32 { return u.a; }
//@dump-sem-ir-end

// --- order_independent_i32.carbon
library "[[@TEST_NAME]]";

// An `i32` `Core.Copy` lookup before the union materializes the prelude's
// `Int.as.Copy.impl` into the local impl store; that impl is declared in
// package `Core`, so the union field rule must still admit `i32` here.
fn Warm(x: i32) -> i32 {
  var y: i32 = x;
  return y;
}

//@dump-sem-ir-begin
union U {
  var a: i32;
}
//@dump-sem-ir-end

// --- file_scope_designated.carbon
library "[[@TEST_NAME]]";

union IntOrBytes {
  var word: i32;
  var bytes: array(i8, 4);
}

// The initializer is not a constant, so the store happens in the file's
// global initializer.
//@dump-sem-ir-begin
var g: IntOrBytes = {.word = 5};
//@dump-sem-ir-end

// --- raw_identifier.carbon
library "[[@TEST_NAME]]";

// `union` is a keyword; the raw identifier stays available.
//@dump-sem-ir-begin
fn RawIdentifier() -> i32 {
  var r#union: i32 = 1;
  return r#union;
}
//@dump-sem-ir-end

// --- nested_union_field.carbon
library "[[@TEST_NAME]]";

union IntOrBytes {
  var word: i32;
  var bytes: array(i8, 4);
}

// A union is itself trivially copyable and destructible, so it is a valid
// field of another union (the `CustomLayoutType` arm of the predicate).
//@dump-sem-ir-begin
union Outer {
  var inner: IntOrBytes;
  var w: i64;
}
//@dump-sem-ir-end

// --- aggregate_fields.carbon
library "[[@TEST_NAME]]";

// Every `Core.Copy` impl these field types reach is declared in package
// `Core`, so all are admitted; `str` spells `Core.String`.
//@dump-sem-ir-begin
union Aggregates {
  var s: {.a: i32, .b: i32};
  var t: (i32, i16);
  var p: i32*;
  var b: bool;
  var c: char;
  var text: Core.String;
  var literal_text: str;
}
//@dump-sem-ir-end

// --- optional_pointer_field.carbon
library "[[@TEST_NAME]]";

// `Core.Optional(T*)` is a permitted field type (docs/design/unions.md,
// "Reads"): its `Core.Copy` impl is declared in the prelude, and its
// storage is `MaybeUnformed(i32*)`.
//@dump-sem-ir-begin
union OptPtr {
  var o: Core.Optional(i32*);
  var n: i64;
}

fn CopyOptPtr(p: OptPtr) -> i64 {
  var q: OptPtr = p;
  return q.n;
}
//@dump-sem-ir-end
