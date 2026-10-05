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
  // CHECK:STDERR: declare_and_access.carbon:[[@LINE+4]]:7: error: union field `word` has type `i32`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var word: i32;
  // CHECK:STDERR:       ^~~~~~~~~
  // CHECK:STDERR:
  var word: i32;
  // CHECK:STDERR: declare_and_access.carbon:[[@LINE+4]]:7: error: union field `bytes` has type `array(i8, 4)`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var bytes: array(i8, 4);
  // CHECK:STDERR:       ^~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  var bytes: array(i8, 4);
}

fn Read(u: IntOrBytes) -> i32 { return u.word; }

fn Write(p: IntOrBytes*) { p->word = 1; }
//@dump-sem-ir-end

// --- unformed_then_assign.carbon
library "[[@TEST_NAME]]";

union IntOrBytes {
  // CHECK:STDERR: unformed_then_assign.carbon:[[@LINE+4]]:7: error: union field `word` has type `i32`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var word: i32;
  // CHECK:STDERR:       ^~~~~~~~~
  // CHECK:STDERR:
  var word: i32;
  // CHECK:STDERR: unformed_then_assign.carbon:[[@LINE+4]]:7: error: union field `bytes` has type `array(i8, 4)`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var bytes: array(i8, 4);
  // CHECK:STDERR:       ^~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
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
  // CHECK:STDERR: designated_init.carbon:[[@LINE+4]]:7: error: union field `word` has type `i32`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var word: i32;
  // CHECK:STDERR:       ^~~~~~~~~
  // CHECK:STDERR:
  var word: i32;
  // CHECK:STDERR: designated_init.carbon:[[@LINE+4]]:7: error: union field `bytes` has type `array(i8, 4)`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var bytes: array(i8, 4);
  // CHECK:STDERR:       ^~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
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
  // CHECK:STDERR: return_designated.carbon:[[@LINE+4]]:7: error: union field `word` has type `i32`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var word: i32;
  // CHECK:STDERR:       ^~~~~~~~~
  // CHECK:STDERR:
  var word: i32;
  // CHECK:STDERR: return_designated.carbon:[[@LINE+4]]:7: error: union field `bytes` has type `array(i8, 4)`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var bytes: array(i8, 4);
  // CHECK:STDERR:       ^~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  var bytes: array(i8, 4);
}

//@dump-sem-ir-begin
fn Make() -> IntOrBytes { return {.word = 7}; }
//@dump-sem-ir-end

// --- let_designated.carbon
library "[[@TEST_NAME]]";

union IntOrBytes {
  // CHECK:STDERR: let_designated.carbon:[[@LINE+4]]:7: error: union field `word` has type `i32`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var word: i32;
  // CHECK:STDERR:       ^~~~~~~~~
  // CHECK:STDERR:
  var word: i32;
  // CHECK:STDERR: let_designated.carbon:[[@LINE+4]]:7: error: union field `bytes` has type `array(i8, 4)`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var bytes: array(i8, 4);
  // CHECK:STDERR:       ^~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
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
  // CHECK:STDERR: from_struct_value.carbon:[[@LINE+4]]:7: error: union field `word` has type `i32`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var word: i32;
  // CHECK:STDERR:       ^~~~~~~~~
  // CHECK:STDERR:
  var word: i32;
  // CHECK:STDERR: from_struct_value.carbon:[[@LINE+4]]:7: error: union field `bytes` has type `array(i8, 4)`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var bytes: array(i8, 4);
  // CHECK:STDERR:       ^~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
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
  // CHECK:STDERR: copy.carbon:[[@LINE+4]]:7: error: union field `word` has type `i32`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var word: i32;
  // CHECK:STDERR:       ^~~~~~~~~
  // CHECK:STDERR:
  var word: i32;
  // CHECK:STDERR: copy.carbon:[[@LINE+4]]:7: error: union field `bytes` has type `array(i8, 4)`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var bytes: array(i8, 4);
  // CHECK:STDERR:       ^~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
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
  // CHECK:STDERR: user_copy_impl_shadowed.carbon:[[@LINE+4]]:7: error: union field `a` has type `i32`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var a: i32;
  // CHECK:STDERR:       ^~~~~~
  // CHECK:STDERR:
  var a: i32;
  impl as Core.Copy {
    // CHECK:STDERR: user_copy_impl_shadowed.carbon:[[@LINE+4]]:11: warning: binding `self` unused [UnusedBinding]
    // CHECK:STDERR:     fn Op(self) -> Self { return {.a = 0}; }
    // CHECK:STDERR:           ^~~~
    // CHECK:STDERR:
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
  // CHECK:STDERR: method.carbon:[[@LINE+4]]:7: error: union field `word` has type `i32`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var word: i32;
  // CHECK:STDERR:       ^~~~~~~~~
  // CHECK:STDERR:
  var word: i32;
  // CHECK:STDERR: method.carbon:[[@LINE+4]]:7: error: union field `bytes` has type `array(i8, 4)`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var bytes: array(i8, 4);
  // CHECK:STDERR:       ^~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
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

// An `impl` is a permitted union member, "as in classes": `extend impl as`
// makes the interface's members visible as members of the union
// (check/testdata/impl/extend_impl.carbon), which is what `u.Get()` needs; a
// plain `impl as I` is reached through the interface (`u.(I.Get)()`).
//@dump-sem-ir-begin
union WithImpl {
  // CHECK:STDERR: impl_member.carbon:[[@LINE+4]]:7: error: union field `a` has type `i32`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var a: i32;
  // CHECK:STDERR:       ^~~~~~
  // CHECK:STDERR:
  var a: i32;
  extend impl as I {
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
  // CHECK:STDERR: forward_decl.carbon:[[@LINE+4]]:7: error: union field `a` has type `i32`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var a: i32;
  // CHECK:STDERR:       ^~~~~~
  // CHECK:STDERR:
  var a: i32;
}

fn UseU(u: U) -> i32 { return u.a; }
//@dump-sem-ir-end

// --- member_of_class.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
class C {
  union Inner {
    // CHECK:STDERR: member_of_class.carbon:[[@LINE+4]]:9: error: union field `a` has type `i32`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
    // CHECK:STDERR:     var a: i32;
    // CHECK:STDERR:         ^~~~~~
    // CHECK:STDERR:
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
  // CHECK:STDERR: namespace_scoped.carbon:[[@LINE+4]]:7: error: union field `a` has type `i32`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var a: i32;
  // CHECK:STDERR:       ^~~~~~
  // CHECK:STDERR:
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
  // CHECK:STDERR: order_independent_i32.carbon:[[@LINE+4]]:7: error: union field `a` has type `i32`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var a: i32;
  // CHECK:STDERR:       ^~~~~~
  // CHECK:STDERR:
  var a: i32;
}
//@dump-sem-ir-end

// --- file_scope_designated.carbon
library "[[@TEST_NAME]]";

union IntOrBytes {
  // CHECK:STDERR: file_scope_designated.carbon:[[@LINE+4]]:7: error: union field `word` has type `i32`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var word: i32;
  // CHECK:STDERR:       ^~~~~~~~~
  // CHECK:STDERR:
  var word: i32;
  // CHECK:STDERR: file_scope_designated.carbon:[[@LINE+4]]:7: error: union field `bytes` has type `array(i8, 4)`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var bytes: array(i8, 4);
  // CHECK:STDERR:       ^~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
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
  // CHECK:STDERR: nested_union_field.carbon:[[@LINE+4]]:7: error: union field `word` has type `i32`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var word: i32;
  // CHECK:STDERR:       ^~~~~~~~~
  // CHECK:STDERR:
  var word: i32;
  // CHECK:STDERR: nested_union_field.carbon:[[@LINE+4]]:7: error: union field `bytes` has type `array(i8, 4)`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var bytes: array(i8, 4);
  // CHECK:STDERR:       ^~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  var bytes: array(i8, 4);
}

// A union is itself trivially copyable and destructible, so it is a valid
// field of another union (the `CustomLayoutType` arm of the predicate).
//@dump-sem-ir-begin
union Outer {
  // CHECK:STDERR: nested_union_field.carbon:[[@LINE+4]]:7: error: union field `inner` has type `IntOrBytes`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var inner: IntOrBytes;
  // CHECK:STDERR:       ^~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  var inner: IntOrBytes;
  // CHECK:STDERR: nested_union_field.carbon:[[@LINE+4]]:7: error: union field `w` has type `i64`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var w: i64;
  // CHECK:STDERR:       ^~~~~~
  // CHECK:STDERR:
  var w: i64;
}
//@dump-sem-ir-end

// --- aggregate_fields.carbon
library "[[@TEST_NAME]]";

// Every `Core.Copy` impl these field types reach is declared in package
// `Core`, so all are admitted; `str` spells `Core.String`.
//@dump-sem-ir-begin
union Aggregates {
  // CHECK:STDERR: aggregate_fields.carbon:[[@LINE+4]]:7: error: union field `s` has type `{.a: i32, .b: i32}`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var s: {.a: i32, .b: i32};
  // CHECK:STDERR:       ^~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  var s: {.a: i32, .b: i32};
  // CHECK:STDERR: aggregate_fields.carbon:[[@LINE+4]]:7: error: union field `t` has type `(i32, i16)`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var t: (i32, i16);
  // CHECK:STDERR:       ^~~~~~~~~~~~~
  // CHECK:STDERR:
  var t: (i32, i16);
  var p: i32*;
  var b: bool;
  // CHECK:STDERR: aggregate_fields.carbon:[[@LINE+4]]:7: error: union field `c` has type `char`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var c: char;
  // CHECK:STDERR:       ^~~~~~~
  // CHECK:STDERR:
  var c: char;
  // CHECK:STDERR: aggregate_fields.carbon:[[@LINE+4]]:7: error: union field `text` has type `str`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var text: Core.String;
  // CHECK:STDERR:       ^~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  var text: Core.String;
  // CHECK:STDERR: aggregate_fields.carbon:[[@LINE+4]]:7: error: union field `literal_text` has type `str`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var literal_text: str;
  // CHECK:STDERR:       ^~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
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
  // CHECK:STDERR: optional_pointer_field.carbon:[[@LINE+4]]:7: error: union field `o` has type `Core.Optional(i32* as Core.OptionalStorage)`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var o: Core.Optional(i32*);
  // CHECK:STDERR:       ^~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  var o: Core.Optional(i32*);
  // CHECK:STDERR: optional_pointer_field.carbon:[[@LINE+4]]:7: error: union field `n` has type `i64`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var n: i64;
  // CHECK:STDERR:       ^~~~~~
  // CHECK:STDERR:
  var n: i64;
}

fn CopyOptPtr(p: OptPtr) -> i64 {
  var q: OptPtr = p;
  return q.n;
}
//@dump-sem-ir-end

// CHECK:STDOUT: --- declare_and_access.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %IntOrBytes: type = class_type @IntOrBytes [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %IntOrBytes.elem.a3f: type = unbound_element_type %IntOrBytes, %i32 [concrete]
// CHECK:STDOUT:   %int_8: Core.IntLiteral = int_value 8 [concrete]
// CHECK:STDOUT:   %i8: type = class_type @Int, @Int(%int_8) [concrete]
// CHECK:STDOUT:   %int_4: Core.IntLiteral = int_value 4 [concrete]
// CHECK:STDOUT:   %array_type: type = array_type %int_4, %i8 [concrete]
// CHECK:STDOUT:   %IntOrBytes.elem.ff6: type = unbound_element_type %IntOrBytes, %array_type [concrete]
// CHECK:STDOUT:   %pattern_type.970: type = pattern_type %IntOrBytes [concrete]
// CHECK:STDOUT:   %u.param_patt: %pattern_type.970 = value_param_pattern [concrete]
// CHECK:STDOUT:   %u.patt: %pattern_type.970 = wrapper_binding_pattern u, %u.param_patt [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %Read.type: type = fn_type @Read [concrete]
// CHECK:STDOUT:   %Read: %Read.type = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet: %Copy.type = facet_value %i32, (%Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.381: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet) [concrete]
// CHECK:STDOUT:   %.737: type = fn_type_with_self_type %Copy.WithSelf.Op.type.381, %Copy.facet [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %ptr.ad0: type = ptr_type %IntOrBytes [concrete]
// CHECK:STDOUT:   %pattern_type.5db: type = pattern_type %ptr.ad0 [concrete]
// CHECK:STDOUT:   %p.param_patt: %pattern_type.5db = value_param_pattern [concrete]
// CHECK:STDOUT:   %p.patt: %pattern_type.5db = wrapper_binding_pattern p, %p.param_patt [concrete]
// CHECK:STDOUT:   %Write.type: type = fn_type @Write [concrete]
// CHECK:STDOUT:   %Write: %Write.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %To: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %IntOrBytes.decl: type = class_decl @IntOrBytes [concrete = constants.%IntOrBytes] {} {}
// CHECK:STDOUT:   %Read.decl: %Read.type = fn_decl @Read [concrete = constants.%Read] {
// CHECK:STDOUT:     %u.param_patt: %pattern_type.970 = value_param_pattern [concrete = constants.%u.param_patt]
// CHECK:STDOUT:     %u.patt: %pattern_type.970 = wrapper_binding_pattern u, %u.param_patt [concrete = constants.%u.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc9_27: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %u.param: %IntOrBytes = value_param call_param0
// CHECK:STDOUT:     %IntOrBytes.ref: type = name_ref IntOrBytes, file.%IntOrBytes.decl [concrete = constants.%IntOrBytes]
// CHECK:STDOUT:     %u: %IntOrBytes = wrapper_binding u, %u.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Write.decl: %Write.type = fn_decl @Write [concrete = constants.%Write] {
// CHECK:STDOUT:     %p.param_patt: %pattern_type.5db = value_param_pattern [concrete = constants.%p.param_patt]
// CHECK:STDOUT:     %p.patt: %pattern_type.5db = wrapper_binding_pattern p, %p.param_patt [concrete = constants.%p.patt]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %p.param: %ptr.ad0 = value_param call_param0
// CHECK:STDOUT:     %.loc11_23: type = splice_block %ptr [concrete = constants.%ptr.ad0] {
// CHECK:STDOUT:       %IntOrBytes.ref: type = name_ref IntOrBytes, file.%IntOrBytes.decl [concrete = constants.%IntOrBytes]
// CHECK:STDOUT:       %ptr: type = ptr_type %IntOrBytes.ref [concrete = constants.%ptr.ad0]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %p: %ptr.ad0 = wrapper_binding p, %p.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: class @IntOrBytes {
// CHECK:STDOUT:   %.loc5: %IntOrBytes.elem.a3f = field_decl word, element0 [concrete]
// CHECK:STDOUT:   %.loc6: %IntOrBytes.elem.ff6 = field_decl bytes, element1 [concrete]
// CHECK:STDOUT:   complete_type_witness = <error>
// CHECK:STDOUT:
// CHECK:STDOUT: !members:
// CHECK:STDOUT:   .Self = constants.%IntOrBytes
// CHECK:STDOUT:   .word = %.loc5
// CHECK:STDOUT:   .bytes = %.loc6
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Read(%u.param: %IntOrBytes) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %u.ref: %IntOrBytes = name_ref u, %u
// CHECK:STDOUT:   %word.ref: %IntOrBytes.elem.a3f = name_ref word, @IntOrBytes.%.loc5 [concrete = @IntOrBytes.%.loc5]
// CHECK:STDOUT:   %.loc9_41.1: ref %i32 = class_element_access %u.ref, element0
// CHECK:STDOUT:   %.loc9_41.2: %i32 = acquire_value %.loc9_41.1
// CHECK:STDOUT:   %impl.elem0: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc9_41.1: <bound method> = bound_method %.loc9_41.2, %impl.elem0
// CHECK:STDOUT:   %specific_fn: <specific function> = specific_function %impl.elem0, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc9_41.2: <bound method> = bound_method %.loc9_41.2, %specific_fn
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc9_41.2(%.loc9_41.2)
// CHECK:STDOUT:   return %Int.as.Copy.impl.Op.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Write(%p.param: %ptr.ad0) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %p.ref: %ptr.ad0 = name_ref p, %p
// CHECK:STDOUT:   %.loc11_29.1: ref %IntOrBytes = deref %p.ref
// CHECK:STDOUT:   %word.ref: %IntOrBytes.elem.a3f = name_ref word, @IntOrBytes.%.loc5 [concrete = @IntOrBytes.%.loc5]
// CHECK:STDOUT:   %.loc11_29.2: ref %i32 = class_element_access %.loc11_29.1, element0
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc11_36.1: <bound method> = bound_method %int_1, %impl.elem0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound]
// CHECK:STDOUT:   %specific_fn: <specific function> = specific_function %impl.elem0, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc11_36.2: <bound method> = bound_method %int_1, %specific_fn [concrete = constants.%bound_method]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %i32 = call %bound_method.loc11_36.2(%int_1) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc11_36: init %i32 = converted %int_1, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   assign %.loc11_29.2, %.loc11_36
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- unformed_then_assign.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %IntOrBytes: type = class_type @IntOrBytes [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %N.fe9: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %IntOrBytes.elem.a3f: type = unbound_element_type %IntOrBytes, %i32 [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %UnformedThenAssign.type: type = fn_type @UnformedThenAssign [concrete]
// CHECK:STDOUT:   %UnformedThenAssign: %UnformedThenAssign.type = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.970: type = pattern_type %IntOrBytes [concrete]
// CHECK:STDOUT:   %u.patt: %pattern_type.970 = ref_binding_pattern u [concrete]
// CHECK:STDOUT:   %u.var_patt: %pattern_type.970 = var_pattern %u.patt [concrete]
// CHECK:STDOUT:   %DefaultOrUnformed.type: type = facet_type <@DefaultOrUnformed> [concrete]
// CHECK:STDOUT:   %UnformedInit.type: type = facet_type <@UnformedInit> [concrete]
// CHECK:STDOUT:   %T.fef: %UnformedInit.type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %T.as_type.as.DefaultOrUnformed.impl.Op.type.215: type = fn_type @T.as_type.as.DefaultOrUnformed.impl.Op.2, @T.as_type.as.DefaultOrUnformed.impl.52f(%T.fef) [symbolic]
// CHECK:STDOUT:   %T.as_type.as.DefaultOrUnformed.impl.Op.f65: %T.as_type.as.DefaultOrUnformed.impl.Op.type.215 = struct_value () [symbolic]
// CHECK:STDOUT:   %custom_witness.19e: <witness> = custom_witness (), @UnformedInit [concrete]
// CHECK:STDOUT:   %UnformedInit.facet: %UnformedInit.type = facet_value %IntOrBytes, (%custom_witness.19e) [concrete]
// CHECK:STDOUT:   %DefaultOrUnformed.impl_witness.88f: <witness> = impl_witness imports.%DefaultOrUnformed.impl_witness_table.8f5, @T.as_type.as.DefaultOrUnformed.impl.52f(%UnformedInit.facet) [concrete]
// CHECK:STDOUT:   %DefaultOrUnformed.facet: %DefaultOrUnformed.type = facet_value %IntOrBytes, (%DefaultOrUnformed.impl_witness.88f) [concrete]
// CHECK:STDOUT:   %int_5.64b: Core.IntLiteral = int_value 5 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %To: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound: <bound method> = bound_method %int_5.64b, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method: <bound method> = bound_method %int_5.64b, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_5.eef: %i32 = int_value 5 [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N.fe9) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet: %Copy.type = facet_value %i32, (%Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.381: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet) [concrete]
// CHECK:STDOUT:   %.737: type = fn_type_with_self_type %Copy.WithSelf.Op.type.381, %Copy.facet [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %Destroy.Op.type: type = fn_type @Destroy.Op [concrete]
// CHECK:STDOUT:   %Destroy.Op: %Destroy.Op.type = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.083: @T.as_type.as.DefaultOrUnformed.impl.52f.%T.as_type.as.DefaultOrUnformed.impl.Op.type (%T.as_type.as.DefaultOrUnformed.impl.Op.type.215) = import_ref Core//prelude/default, loc{{\d+_\d+}}, loaded [symbolic = @T.as_type.as.DefaultOrUnformed.impl.52f.%T.as_type.as.DefaultOrUnformed.impl.Op (constants.%T.as_type.as.DefaultOrUnformed.impl.Op.f65)]
// CHECK:STDOUT:   %DefaultOrUnformed.impl_witness_table.8f5 = impl_witness_table (%Core.import_ref.083), @T.as_type.as.DefaultOrUnformed.impl.52f [concrete]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %UnformedThenAssign.decl: %UnformedThenAssign.type = fn_decl @UnformedThenAssign [concrete = constants.%UnformedThenAssign] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc13: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param0
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @UnformedThenAssign() -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %u.var: ref %IntOrBytes = var_storage %u.var_patt
// CHECK:STDOUT:   %DefaultOrUnformed.facet: %DefaultOrUnformed.type = facet_value constants.%IntOrBytes, (constants.%DefaultOrUnformed.impl_witness.88f) [concrete = constants.%DefaultOrUnformed.facet]
// CHECK:STDOUT:   %.loc14_20.1: %DefaultOrUnformed.type = converted constants.%IntOrBytes, %DefaultOrUnformed.facet [concrete = constants.%DefaultOrUnformed.facet]
// CHECK:STDOUT:   %as_type: type = facet_access_type %.loc14_20.1 [concrete = constants.%IntOrBytes]
// CHECK:STDOUT:   %.loc14_20.2: type = converted %.loc14_20.1, %as_type [concrete = constants.%IntOrBytes]
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:   %.loc14_3: ref %IntOrBytes = splice_block %u.var {}
// CHECK:STDOUT:   %T.as_type.as.DefaultOrUnformed.impl.Op.call: init %IntOrBytes to %.loc14_3 = call %T.as_type.as.DefaultOrUnformed.impl.Op.specific_fn()
// CHECK:STDOUT:   assign %u.var, %T.as_type.as.DefaultOrUnformed.impl.Op.call
// CHECK:STDOUT:   %IntOrBytes.ref: type = name_ref IntOrBytes, file.%IntOrBytes.decl [concrete = constants.%IntOrBytes]
// CHECK:STDOUT:   %u: ref %IntOrBytes = wrapper_binding u, %u.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %u.patt: %pattern_type.970 = ref_binding_pattern u [concrete = constants.%u.patt]
// CHECK:STDOUT:     %u.var_patt: %pattern_type.970 = var_pattern %u.patt [concrete = constants.%u.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %u.ref.loc15: ref %IntOrBytes = name_ref u, %u
// CHECK:STDOUT:   %word.ref.loc15: %IntOrBytes.elem.a3f = name_ref word, @IntOrBytes.%.loc4 [concrete = @IntOrBytes.%.loc4]
// CHECK:STDOUT:   %.loc15_4: ref %i32 = class_element_access %u.ref.loc15, element0
// CHECK:STDOUT:   %int_5: Core.IntLiteral = int_value 5 [concrete = constants.%int_5.64b]
// CHECK:STDOUT:   %impl.elem0.loc15: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc15_10.1: <bound method> = bound_method %int_5, %impl.elem0.loc15 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound]
// CHECK:STDOUT:   %specific_fn.loc15: <specific function> = specific_function %impl.elem0.loc15, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc15_10.2: <bound method> = bound_method %int_5, %specific_fn.loc15 [concrete = constants.%bound_method]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %i32 = call %bound_method.loc15_10.2(%int_5) [concrete = constants.%int_5.eef]
// CHECK:STDOUT:   %.loc15_10: init %i32 = converted %int_5, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_5.eef]
// CHECK:STDOUT:   assign %.loc15_4, %.loc15_10
// CHECK:STDOUT:   %u.ref.loc16: ref %IntOrBytes = name_ref u, %u
// CHECK:STDOUT:   %word.ref.loc16: %IntOrBytes.elem.a3f = name_ref word, @IntOrBytes.%.loc4 [concrete = @IntOrBytes.%.loc4]
// CHECK:STDOUT:   %.loc16_11.1: ref %i32 = class_element_access %u.ref.loc16, element0
// CHECK:STDOUT:   %.loc16_11.2: %i32 = acquire_value %.loc16_11.1
// CHECK:STDOUT:   %impl.elem0.loc16: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc16_11.1: <bound method> = bound_method %.loc16_11.2, %impl.elem0.loc16
// CHECK:STDOUT:   %specific_fn.loc16: <specific function> = specific_function %impl.elem0.loc16, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc16_11.2: <bound method> = bound_method %.loc16_11.2, %specific_fn.loc16
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc16_11.2(%.loc16_11.2)
// CHECK:STDOUT:   %Destroy.Op.bound: <bound method> = bound_method %u.var, constants.%Destroy.Op
// CHECK:STDOUT:   %Destroy.Op.call: init %empty_tuple.type = call %Destroy.Op.bound(%u.var)
// CHECK:STDOUT:   return %Int.as.Copy.impl.Op.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op(%self.param: ref %IntOrBytes) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- designated_init.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %IntOrBytes: type = class_type @IntOrBytes [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %IntOrBytes.elem.a3f: type = unbound_element_type %IntOrBytes, %i32 [concrete]
// CHECK:STDOUT:   %int_8: Core.IntLiteral = int_value 8 [concrete]
// CHECK:STDOUT:   %i8: type = class_type @Int, @Int(%int_8) [concrete]
// CHECK:STDOUT:   %int_4: Core.IntLiteral = int_value 4 [concrete]
// CHECK:STDOUT:   %array_type: type = array_type %int_4, %i8 [concrete]
// CHECK:STDOUT:   %IntOrBytes.elem.ff6: type = unbound_element_type %IntOrBytes, %array_type [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %DesignatedInit.type: type = fn_type @DesignatedInit [concrete]
// CHECK:STDOUT:   %DesignatedInit: %DesignatedInit.type = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.970: type = pattern_type %IntOrBytes [concrete]
// CHECK:STDOUT:   %v.patt: %pattern_type.970 = ref_binding_pattern v [concrete]
// CHECK:STDOUT:   %v.var_patt: %pattern_type.970 = var_pattern %v.patt [concrete]
// CHECK:STDOUT:   %int_5: Core.IntLiteral = int_value 5 [concrete]
// CHECK:STDOUT:   %struct_type.word: type = struct_type {.word: Core.IntLiteral} [concrete]
// CHECK:STDOUT:   %struct.64b: %struct_type.word = struct_value (%int_5) [concrete]
// CHECK:STDOUT:   %b.patt: %pattern_type.970 = ref_binding_pattern b [concrete]
// CHECK:STDOUT:   %b.var_patt: %pattern_type.970 = var_pattern %b.patt [concrete]
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %int_3.1ba: Core.IntLiteral = int_value 3 [concrete]
// CHECK:STDOUT:   %tuple.type: type = tuple_type (Core.IntLiteral, Core.IntLiteral, Core.IntLiteral, Core.IntLiteral) [concrete]
// CHECK:STDOUT:   %tuple: %tuple.type = tuple_value (%int_1, %int_2, %int_3.1ba, %int_4) [concrete]
// CHECK:STDOUT:   %struct_type.bytes.ed8: type = struct_type {.bytes: %tuple.type} [concrete]
// CHECK:STDOUT:   %struct.c89: %struct_type.bytes.ed8 = struct_value (%tuple) [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %To.fe9: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %From.fe9: Core.IntLiteral = symbolic_binding From, 0 [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound: <bound method> = bound_method %int_3.1ba, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method: <bound method> = bound_method %int_3.1ba, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_3.410: %i32 = int_value 3 [concrete]
// CHECK:STDOUT:   %As.type.155: type = facet_type <@As, @As(%i32)> [concrete]
// CHECK:STDOUT:   %To.d23: Core.IntLiteral = symbolic_binding To, 1 [symbolic]
// CHECK:STDOUT:   %Int.as.As.impl.Convert.type.a00: type = fn_type @Int.as.As.impl.Convert.2, @Int.as.As.impl.c50(%From.fe9, %To.d23) [symbolic]
// CHECK:STDOUT:   %Int.as.As.impl.Convert.3b9: %Int.as.As.impl.Convert.type.a00 = struct_value () [symbolic]
// CHECK:STDOUT:   %As.impl_witness.33c: <witness> = impl_witness imports.%As.impl_witness_table.dc5, @Int.as.As.impl.c50(%int_8, %int_32) [concrete]
// CHECK:STDOUT:   %Int.as.As.impl.Convert.type.892: type = fn_type @Int.as.As.impl.Convert.2, @Int.as.As.impl.c50(%int_8, %int_32) [concrete]
// CHECK:STDOUT:   %Int.as.As.impl.Convert.c63: %Int.as.As.impl.Convert.type.892 = struct_value () [concrete]
// CHECK:STDOUT:   %As.facet: %As.type.155 = facet_value %i8, (%As.impl_witness.33c) [concrete]
// CHECK:STDOUT:   %As.WithSelf.Convert.type.7de: type = fn_type @As.WithSelf.Convert, @As.WithSelf(%i32, %As.facet) [concrete]
// CHECK:STDOUT:   %.35d: type = fn_type_with_self_type %As.WithSelf.Convert.type.7de, %As.facet [concrete]
// CHECK:STDOUT:   %Int.as.As.impl.Convert.specific_fn: <specific function> = specific_function %Int.as.As.impl.Convert.c63, @Int.as.As.impl.Convert.2(%int_8, %int_32) [concrete]
// CHECK:STDOUT:   %AddWith.type.be9: type = facet_type <@AddWith, @AddWith(%i32)> [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.610: type = fn_type @Int.as.AddWith.impl.Op.1, @Int.as.AddWith.impl.3af(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.732: %Int.as.AddWith.impl.Op.type.610 = struct_value () [symbolic]
// CHECK:STDOUT:   %AddWith.impl_witness.833: <witness> = impl_witness imports.%AddWith.impl_witness_table.6b4, @Int.as.AddWith.impl.3af(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.056: type = fn_type @Int.as.AddWith.impl.Op.1, @Int.as.AddWith.impl.3af(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.365: %Int.as.AddWith.impl.Op.type.056 = struct_value () [concrete]
// CHECK:STDOUT:   %AddWith.facet.76a: %AddWith.type.be9 = facet_value %i32, (%AddWith.impl_witness.833) [concrete]
// CHECK:STDOUT:   %AddWith.WithSelf.Op.type.02a: type = fn_type @AddWith.WithSelf.Op, @AddWith.WithSelf(%i32, %AddWith.facet.76a) [concrete]
// CHECK:STDOUT:   %.d47: type = fn_type_with_self_type %AddWith.WithSelf.Op.type.02a, %AddWith.facet.76a [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.specific_fn.f25: <specific function> = specific_function %Int.as.AddWith.impl.Op.365, @Int.as.AddWith.impl.Op.1(%int_32) [concrete]
// CHECK:STDOUT:   %Destroy.Op.type: type = fn_type @Destroy.Op [concrete]
// CHECK:STDOUT:   %Destroy.Op: %Destroy.Op.type = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.a86: @Int.as.As.impl.c50.%Int.as.As.impl.Convert.type (%Int.as.As.impl.Convert.type.a00) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.As.impl.c50.%Int.as.As.impl.Convert (constants.%Int.as.As.impl.Convert.3b9)]
// CHECK:STDOUT:   %As.impl_witness_table.dc5 = impl_witness_table (%Core.import_ref.a86), @Int.as.As.impl.c50 [concrete]
// CHECK:STDOUT:   %Core.import_ref.b4fd3a.1 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.684: @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op.type (%Int.as.AddWith.impl.Op.type.610) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op (constants.%Int.as.AddWith.impl.Op.732)]
// CHECK:STDOUT:   %AddWith.impl_witness_table.6b4 = impl_witness_table (%Core.import_ref.b4fd3a.1, %Core.import_ref.684), @Int.as.AddWith.impl.3af [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %DesignatedInit.decl: %DesignatedInit.type = fn_decl @DesignatedInit [concrete = constants.%DesignatedInit] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc13 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc13: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc13: Core.Form = init_form %i32.loc13 [concrete = constants.%.795f]
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param0
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @DesignatedInit() -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %v.var: ref %IntOrBytes = var_storage %v.var_patt
// CHECK:STDOUT:   %int_5: Core.IntLiteral = int_value 5 [concrete = constants.%int_5]
// CHECK:STDOUT:   %.loc14: %struct_type.word = struct_literal (%int_5) [concrete = constants.%struct.64b]
// CHECK:STDOUT:   assign %v.var, <error>
// CHECK:STDOUT:   %IntOrBytes.ref.loc14: type = name_ref IntOrBytes, file.%IntOrBytes.decl [concrete = constants.%IntOrBytes]
// CHECK:STDOUT:   %v: ref %IntOrBytes = wrapper_binding v, %v.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %v.patt: %pattern_type.970 = ref_binding_pattern v [concrete = constants.%v.patt]
// CHECK:STDOUT:     %v.var_patt: %pattern_type.970 = var_pattern %v.patt [concrete = constants.%v.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %b.var: ref %IntOrBytes = var_storage %b.var_patt
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1]
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2]
// CHECK:STDOUT:   %int_3.loc15: Core.IntLiteral = int_value 3 [concrete = constants.%int_3.1ba]
// CHECK:STDOUT:   %int_4: Core.IntLiteral = int_value 4 [concrete = constants.%int_4]
// CHECK:STDOUT:   %.loc15_44: %tuple.type = tuple_literal (%int_1, %int_2, %int_3.loc15, %int_4) [concrete = constants.%tuple]
// CHECK:STDOUT:   %.loc15_45: %struct_type.bytes.ed8 = struct_literal (%.loc15_44) [concrete = constants.%struct.c89]
// CHECK:STDOUT:   assign %b.var, <error>
// CHECK:STDOUT:   %IntOrBytes.ref.loc15: type = name_ref IntOrBytes, file.%IntOrBytes.decl [concrete = constants.%IntOrBytes]
// CHECK:STDOUT:   %b: ref %IntOrBytes = wrapper_binding b, %b.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %b.patt: %pattern_type.970 = ref_binding_pattern b [concrete = constants.%b.patt]
// CHECK:STDOUT:     %b.var_patt: %pattern_type.970 = var_pattern %b.patt [concrete = constants.%b.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %v.ref: ref %IntOrBytes = name_ref v, %v
// CHECK:STDOUT:   %word.ref: %IntOrBytes.elem.a3f = name_ref word, @IntOrBytes.%.loc4 [concrete = @IntOrBytes.%.loc4]
// CHECK:STDOUT:   %.loc16_11.1: ref %i32 = class_element_access %v.ref, element0
// CHECK:STDOUT:   %b.ref: ref %IntOrBytes = name_ref b, %b
// CHECK:STDOUT:   %bytes.ref: %IntOrBytes.elem.ff6 = name_ref bytes, @IntOrBytes.%.loc5 [concrete = @IntOrBytes.%.loc5]
// CHECK:STDOUT:   %.loc16_21: ref %array_type = class_element_access %b.ref, element1
// CHECK:STDOUT:   %int_3.loc16: Core.IntLiteral = int_value 3 [concrete = constants.%int_3.1ba]
// CHECK:STDOUT:   %impl.elem0.loc16_28: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc16_28.1: <bound method> = bound_method %int_3.loc16, %impl.elem0.loc16_28 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound]
// CHECK:STDOUT:   %specific_fn.loc16_28: <specific function> = specific_function %impl.elem0.loc16_28, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc16_28.2: <bound method> = bound_method %int_3.loc16, %specific_fn.loc16_28 [concrete = constants.%bound_method]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %i32 = call %bound_method.loc16_28.2(%int_3.loc16) [concrete = constants.%int_3.410]
// CHECK:STDOUT:   %.loc16_28.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_3.410]
// CHECK:STDOUT:   %.loc16_28.2: %i32 = converted %int_3.loc16, %.loc16_28.1 [concrete = constants.%int_3.410]
// CHECK:STDOUT:   %.loc16_29.1: ref %i8 = array_index %.loc16_21, %.loc16_28.2
// CHECK:STDOUT:   %i32.loc16: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %impl.elem0.loc16_31: %.35d = impl_witness_access constants.%As.impl_witness.33c, element0 [concrete = constants.%Int.as.As.impl.Convert.c63]
// CHECK:STDOUT:   %bound_method.loc16_31.1: <bound method> = bound_method %.loc16_29.1, %impl.elem0.loc16_31
// CHECK:STDOUT:   %specific_fn.loc16_31: <specific function> = specific_function %impl.elem0.loc16_31, @Int.as.As.impl.Convert.2(constants.%int_8, constants.%int_32) [concrete = constants.%Int.as.As.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc16_31.2: <bound method> = bound_method %.loc16_29.1, %specific_fn.loc16_31
// CHECK:STDOUT:   %.loc16_29.2: %i8 = acquire_value %.loc16_29.1
// CHECK:STDOUT:   %Int.as.As.impl.Convert.call: init %i32 = call %bound_method.loc16_31.2(%.loc16_29.2)
// CHECK:STDOUT:   %.loc16_31.1: %i32 = value_of_initializer %Int.as.As.impl.Convert.call
// CHECK:STDOUT:   %.loc16_31.2: %i32 = converted %.loc16_29.1, %.loc16_31.1
// CHECK:STDOUT:   %impl.elem1: %.d47 = impl_witness_access constants.%AddWith.impl_witness.833, element1 [concrete = constants.%Int.as.AddWith.impl.Op.365]
// CHECK:STDOUT:   %bound_method.loc16_17.1: <bound method> = bound_method %.loc16_11.1, %impl.elem1
// CHECK:STDOUT:   %specific_fn.loc16_17: <specific function> = specific_function %impl.elem1, @Int.as.AddWith.impl.Op.1(constants.%int_32) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.f25]
// CHECK:STDOUT:   %bound_method.loc16_17.2: <bound method> = bound_method %.loc16_11.1, %specific_fn.loc16_17
// CHECK:STDOUT:   %.loc16_11.2: %i32 = acquire_value %.loc16_11.1
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call: init %i32 = call %bound_method.loc16_17.2(%.loc16_11.2, %.loc16_31.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc15: <bound method> = bound_method %b.var, constants.%Destroy.Op
// CHECK:STDOUT:   %Destroy.Op.call.loc15: init %empty_tuple.type = call %Destroy.Op.bound.loc15(%b.var)
// CHECK:STDOUT:   %Destroy.Op.bound.loc14: <bound method> = bound_method %v.var, constants.%Destroy.Op
// CHECK:STDOUT:   %Destroy.Op.call.loc14: init %empty_tuple.type = call %Destroy.Op.bound.loc14(%v.var)
// CHECK:STDOUT:   return %Int.as.AddWith.impl.Op.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op(%self.param: ref %IntOrBytes) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- return_designated.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %IntOrBytes: type = class_type @IntOrBytes [concrete]
// CHECK:STDOUT:   %.44d: Core.Form = init_form %IntOrBytes [concrete]
// CHECK:STDOUT:   %pattern_type.970: type = pattern_type %IntOrBytes [concrete]
// CHECK:STDOUT:   %return.param_patt: %pattern_type.970 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt: %pattern_type.970 = return_slot_pattern %return.param_patt, %IntOrBytes [concrete]
// CHECK:STDOUT:   %Make.type: type = fn_type @Make [concrete]
// CHECK:STDOUT:   %Make: %Make.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_7: Core.IntLiteral = int_value 7 [concrete]
// CHECK:STDOUT:   %struct_type.word: type = struct_type {.word: Core.IntLiteral} [concrete]
// CHECK:STDOUT:   %struct: %struct_type.word = struct_value (%int_7) [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Make.decl: %Make.type = fn_decl @Make [concrete = constants.%Make] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.970 = out_param_pattern [concrete = constants.%return.param_patt]
// CHECK:STDOUT:     %return.patt: %pattern_type.970 = return_slot_pattern %return.param_patt, %IntOrBytes.ref [concrete = constants.%return.patt]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %IntOrBytes.ref: type = name_ref IntOrBytes, file.%IntOrBytes.decl [concrete = constants.%IntOrBytes]
// CHECK:STDOUT:     %.loc9_14: Core.Form = init_form %IntOrBytes.ref [concrete = constants.%.44d]
// CHECK:STDOUT:     %return.param: ref %IntOrBytes = out_param call_param0
// CHECK:STDOUT:     %return: ref %IntOrBytes = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Make() -> out %return.param: %IntOrBytes {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %int_7: Core.IntLiteral = int_value 7 [concrete = constants.%int_7]
// CHECK:STDOUT:   %.loc9_44: %struct_type.word = struct_literal (%int_7) [concrete = constants.%struct]
// CHECK:STDOUT:   return <error> to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- let_designated.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %IntOrBytes: type = class_type @IntOrBytes [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %.795: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete]
// CHECK:STDOUT:   %LetDesignated.type: type = fn_type @LetDesignated [concrete]
// CHECK:STDOUT:   %LetDesignated: %LetDesignated.type = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.970: type = pattern_type %IntOrBytes [concrete]
// CHECK:STDOUT:   %v.patt: %pattern_type.970 = value_binding_pattern v [concrete]
// CHECK:STDOUT:   %int_9: Core.IntLiteral = int_value 9 [concrete]
// CHECK:STDOUT:   %struct_type.word: type = struct_type {.word: Core.IntLiteral} [concrete]
// CHECK:STDOUT:   %struct: %struct_type.word = struct_value (%int_9) [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %LetDesignated.decl: %LetDesignated.type = fn_decl @LetDesignated [concrete = constants.%LetDesignated] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc9: Core.Form = init_form %i32 [concrete = constants.%.795]
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param0
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @LetDesignated() -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %int_9: Core.IntLiteral = int_value 9 [concrete = constants.%int_9]
// CHECK:STDOUT:   %.loc10: %struct_type.word = struct_literal (%int_9) [concrete = constants.%struct]
// CHECK:STDOUT:   %IntOrBytes.ref: type = name_ref IntOrBytes, file.%IntOrBytes.decl [concrete = constants.%IntOrBytes]
// CHECK:STDOUT:   %v: %IntOrBytes = wrapper_binding v, <error> [concrete = <error>]
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %v.patt: %pattern_type.970 = value_binding_pattern v [concrete = constants.%v.patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %v.ref: %IntOrBytes = name_ref v, %v [concrete = <error>]
// CHECK:STDOUT:   %word.ref: <error> = name_ref word, <error> [concrete = <error>]
// CHECK:STDOUT:   return <error>
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- from_struct_value.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %IntOrBytes: type = class_type @IntOrBytes [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %i32.builtin: type = int_type signed, %int_32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %IntOrBytes.elem.a3f: type = unbound_element_type %IntOrBytes, %i32 [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %FromStructValue.type: type = fn_type @FromStructValue [concrete]
// CHECK:STDOUT:   %FromStructValue: %FromStructValue.type = struct_value () [concrete]
// CHECK:STDOUT:   %struct_type.word.486: type = struct_type {.word: %i32} [concrete]
// CHECK:STDOUT:   %pattern_type.183: type = pattern_type %struct_type.word.486 [concrete]
// CHECK:STDOUT:   %s.patt: %pattern_type.183 = ref_binding_pattern s [concrete]
// CHECK:STDOUT:   %s.var_patt: %pattern_type.183 = var_pattern %s.patt [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %struct_type.word.450: type = struct_type {.word: Core.IntLiteral} [concrete]
// CHECK:STDOUT:   %struct.b61: %struct_type.word.450 = struct_value (%int_1.5b8) [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %To: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT:   %struct.ad7: %struct_type.word.486 = struct_value (%int_1.0c6) [concrete]
// CHECK:STDOUT:   %pattern_type.970: type = pattern_type %IntOrBytes [concrete]
// CHECK:STDOUT:   %v.patt: %pattern_type.970 = ref_binding_pattern v [concrete]
// CHECK:STDOUT:   %v.var_patt: %pattern_type.970 = var_pattern %v.patt [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet: %Copy.type = facet_value %i32, (%Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.381: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet) [concrete]
// CHECK:STDOUT:   %.737: type = fn_type_with_self_type %Copy.WithSelf.Op.type.381, %Copy.facet [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.1: type = fn_type @Destroy.Op.loc13 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.1: %Destroy.Op.type.1d8f74.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.4: type = fn_type @Destroy.Op.loc12_3.3 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.4: %Destroy.Op.type.1d8f74.4 = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %FromStructValue.decl: %FromStructValue.type = fn_decl @FromStructValue [concrete = constants.%FromStructValue] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc11 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc11: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc11: Core.Form = init_form %i32.loc11 [concrete = constants.%.795f]
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param0
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @FromStructValue() -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %s.var: ref %struct_type.word.486 = var_storage %s.var_patt
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %.loc12_35.1: %struct_type.word.450 = struct_literal (%int_1) [concrete = constants.%struct.b61]
// CHECK:STDOUT:   %impl.elem0.loc12: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc12_35.1: <bound method> = bound_method %int_1, %impl.elem0.loc12 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound]
// CHECK:STDOUT:   %specific_fn.loc12: <specific function> = specific_function %impl.elem0.loc12, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc12_35.2: <bound method> = bound_method %int_1, %specific_fn.loc12 [concrete = constants.%bound_method]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %i32 = call %bound_method.loc12_35.2(%int_1) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc12_35.2: init %i32 = converted %int_1, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc12_35.3: init %struct_type.word.486 to %s.var = struct_init (%.loc12_35.2) [concrete = constants.%struct.ad7]
// CHECK:STDOUT:   %.loc12_3: init %struct_type.word.486 = converted %.loc12_35.1, %.loc12_35.3 [concrete = constants.%struct.ad7]
// CHECK:STDOUT:   assign %s.var, %.loc12_3
// CHECK:STDOUT:   %.loc12_21: type = splice_block %struct_type.word [concrete = constants.%struct_type.word.486] {
// CHECK:STDOUT:     %i32.loc12: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %struct_type.word: type = struct_type {.word: %i32} [concrete = constants.%struct_type.word.486]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %s: ref %struct_type.word.486 = wrapper_binding s, %s.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %s.patt: %pattern_type.183 = ref_binding_pattern s [concrete = constants.%s.patt]
// CHECK:STDOUT:     %s.var_patt: %pattern_type.183 = var_pattern %s.patt [concrete = constants.%s.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %v.var: ref %IntOrBytes = var_storage %v.var_patt
// CHECK:STDOUT:   %s.ref: ref %struct_type.word.486 = name_ref s, %s
// CHECK:STDOUT:   assign %v.var, <error>
// CHECK:STDOUT:   %IntOrBytes.ref: type = name_ref IntOrBytes, file.%IntOrBytes.decl [concrete = constants.%IntOrBytes]
// CHECK:STDOUT:   %v: ref %IntOrBytes = wrapper_binding v, %v.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %v.patt: %pattern_type.970 = ref_binding_pattern v [concrete = constants.%v.patt]
// CHECK:STDOUT:     %v.var_patt: %pattern_type.970 = var_pattern %v.patt [concrete = constants.%v.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %v.ref: ref %IntOrBytes = name_ref v, %v
// CHECK:STDOUT:   %word.ref: %IntOrBytes.elem.a3f = name_ref word, @IntOrBytes.%.loc4 [concrete = @IntOrBytes.%.loc4]
// CHECK:STDOUT:   %.loc14_11.1: ref %i32 = class_element_access %v.ref, element0
// CHECK:STDOUT:   %.loc14_11.2: %i32 = acquire_value %.loc14_11.1
// CHECK:STDOUT:   %impl.elem0.loc14: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc14_11.1: <bound method> = bound_method %.loc14_11.2, %impl.elem0.loc14
// CHECK:STDOUT:   %specific_fn.loc14: <specific function> = specific_function %impl.elem0.loc14, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc14_11.2: <bound method> = bound_method %.loc14_11.2, %specific_fn.loc14
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc14_11.2(%.loc14_11.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc13: <bound method> = bound_method %v.var, constants.%Destroy.Op.1a2547.1
// CHECK:STDOUT:   %Destroy.Op.call.loc13: init %empty_tuple.type = call %Destroy.Op.bound.loc13(%v.var)
// CHECK:STDOUT:   %Destroy.Op.bound.loc12: <bound method> = bound_method %s.var, constants.%Destroy.Op.1a2547.4
// CHECK:STDOUT:   %Destroy.Op.call.loc12: init %empty_tuple.type = call %Destroy.Op.bound.loc12(%s.var)
// CHECK:STDOUT:   return %Int.as.Copy.impl.Op.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc13(%self.param: ref %IntOrBytes) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc12_3.1(%self.param: ref %i32.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc12_3.2(%self.param: ref %i32) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc12_3.3(%self.param: ref %struct_type.word.486) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- copy.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %IntOrBytes: type = class_type @IntOrBytes [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %IntOrBytes.elem.a3f: type = unbound_element_type %IntOrBytes, %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.970: type = pattern_type %IntOrBytes [concrete]
// CHECK:STDOUT:   %v.param_patt: %pattern_type.970 = value_param_pattern [concrete]
// CHECK:STDOUT:   %v.patt: %pattern_type.970 = wrapper_binding_pattern v, %v.param_patt [concrete]
// CHECK:STDOUT:   %.795: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %Copy.type.705: type = fn_type @Copy.loc11 [concrete]
// CHECK:STDOUT:   %Copy: %Copy.type.705 = struct_value () [concrete]
// CHECK:STDOUT:   %w.patt: %pattern_type.970 = ref_binding_pattern w [concrete]
// CHECK:STDOUT:   %w.var_patt: %pattern_type.970 = var_pattern %w.patt [concrete]
// CHECK:STDOUT:   %Copy.type.bd0: type = facet_type <@Copy.1> [concrete]
// CHECK:STDOUT:   %Copy.Op.type: type = fn_type @Copy.Op [concrete]
// CHECK:STDOUT:   %Copy.Op: %Copy.Op.type = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.14b: <witness> = custom_witness (%Copy.Op), @Copy.1 [concrete]
// CHECK:STDOUT:   %Copy.facet.fcd: %Copy.type.bd0 = facet_value %IntOrBytes, (%custom_witness.14b) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.2bd: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.fcd) [concrete]
// CHECK:STDOUT:   %.c63: type = fn_type_with_self_type %Copy.WithSelf.Op.type.2bd, %Copy.facet.fcd [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet.1e1: %Copy.type.bd0 = facet_value %i32, (%Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.381: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.1e1) [concrete]
// CHECK:STDOUT:   %.737: type = fn_type_with_self_type %Copy.WithSelf.Op.type.381, %Copy.facet.1e1 [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %Destroy.Op.type: type = fn_type @Destroy.Op [concrete]
// CHECK:STDOUT:   %Destroy.Op: %Destroy.Op.type = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Copy.decl: %Copy.type.705 = fn_decl @Copy.loc11 [concrete = constants.%Copy] {
// CHECK:STDOUT:     %v.param_patt: %pattern_type.970 = value_param_pattern [concrete = constants.%v.param_patt]
// CHECK:STDOUT:     %v.patt: %pattern_type.970 = wrapper_binding_pattern v, %v.param_patt [concrete = constants.%v.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc11: Core.Form = init_form %i32 [concrete = constants.%.795]
// CHECK:STDOUT:     %v.param: %IntOrBytes = value_param call_param0
// CHECK:STDOUT:     %IntOrBytes.ref.loc11: type = name_ref IntOrBytes, file.%IntOrBytes.decl [concrete = constants.%IntOrBytes]
// CHECK:STDOUT:     %v: %IntOrBytes = wrapper_binding v, %v.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Copy.loc11(%v.param: %IntOrBytes) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %w.var: ref %IntOrBytes = var_storage %w.var_patt
// CHECK:STDOUT:   %v.ref.loc12: %IntOrBytes = name_ref v, %v
// CHECK:STDOUT:   %impl.elem0.loc12: %.c63 = impl_witness_access constants.%custom_witness.14b, element0 [concrete = constants.%Copy.Op]
// CHECK:STDOUT:   %bound_method.loc12: <bound method> = bound_method %v.ref.loc12, %impl.elem0.loc12
// CHECK:STDOUT:   %.loc12: ref %IntOrBytes = splice_block %w.var {}
// CHECK:STDOUT:   %Copy.Op.call.loc12: init %IntOrBytes to %.loc12 = call %bound_method.loc12(%v.ref.loc12)
// CHECK:STDOUT:   assign %w.var, %Copy.Op.call.loc12
// CHECK:STDOUT:   %IntOrBytes.ref.loc12: type = name_ref IntOrBytes, file.%IntOrBytes.decl [concrete = constants.%IntOrBytes]
// CHECK:STDOUT:   %w: ref %IntOrBytes = wrapper_binding w, %w.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %w.patt: %pattern_type.970 = ref_binding_pattern w [concrete = constants.%w.patt]
// CHECK:STDOUT:     %w.var_patt: %pattern_type.970 = var_pattern %w.patt [concrete = constants.%w.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %w.ref.loc13: ref %IntOrBytes = name_ref w, %w
// CHECK:STDOUT:   %v.ref.loc13: %IntOrBytes = name_ref v, %v
// CHECK:STDOUT:   %impl.elem0.loc13: %.c63 = impl_witness_access constants.%custom_witness.14b, element0 [concrete = constants.%Copy.Op]
// CHECK:STDOUT:   %bound_method.loc13: <bound method> = bound_method %v.ref.loc13, %impl.elem0.loc13
// CHECK:STDOUT:   %.loc13: ref %IntOrBytes = splice_block %w.ref.loc13 {}
// CHECK:STDOUT:   %Copy.Op.call.loc13: init %IntOrBytes to %.loc13 = call %bound_method.loc13(%v.ref.loc13)
// CHECK:STDOUT:   assign %w.ref.loc13, %Copy.Op.call.loc13
// CHECK:STDOUT:   %w.ref.loc14: ref %IntOrBytes = name_ref w, %w
// CHECK:STDOUT:   %word.ref: %IntOrBytes.elem.a3f = name_ref word, @IntOrBytes.%.loc4 [concrete = @IntOrBytes.%.loc4]
// CHECK:STDOUT:   %.loc14_11.1: ref %i32 = class_element_access %w.ref.loc14, element0
// CHECK:STDOUT:   %.loc14_11.2: %i32 = acquire_value %.loc14_11.1
// CHECK:STDOUT:   %impl.elem0.loc14: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc14_11.1: <bound method> = bound_method %.loc14_11.2, %impl.elem0.loc14
// CHECK:STDOUT:   %specific_fn: <specific function> = specific_function %impl.elem0.loc14, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc14_11.2: <bound method> = bound_method %.loc14_11.2, %specific_fn
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc14_11.2(%.loc14_11.2)
// CHECK:STDOUT:   %Destroy.Op.bound: <bound method> = bound_method %w.var, constants.%Destroy.Op
// CHECK:STDOUT:   %Destroy.Op.call: init %empty_tuple.type = call %Destroy.Op.bound(%w.var)
// CHECK:STDOUT:   return %Int.as.Copy.impl.Op.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op(%self.param: ref %IntOrBytes) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- user_copy_impl_shadowed.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %Shadowed: type = class_type @Shadowed [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %Shadowed.elem: type = unbound_element_type %Shadowed, %i32 [concrete]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %pattern_type.915: type = pattern_type %Shadowed [concrete]
// CHECK:STDOUT:   %x.param_patt: %pattern_type.915 = value_param_pattern [concrete]
// CHECK:STDOUT:   %x.patt: %pattern_type.915 = wrapper_binding_pattern x, %x.param_patt [concrete]
// CHECK:STDOUT:   %.795: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %CopyShadowed.type: type = fn_type @CopyShadowed [concrete]
// CHECK:STDOUT:   %CopyShadowed: %CopyShadowed.type = struct_value () [concrete]
// CHECK:STDOUT:   %y.patt: %pattern_type.915 = ref_binding_pattern y [concrete]
// CHECK:STDOUT:   %y.var_patt: %pattern_type.915 = var_pattern %y.patt [concrete]
// CHECK:STDOUT:   %Copy.Op.type: type = fn_type @Copy.Op [concrete]
// CHECK:STDOUT:   %Copy.Op: %Copy.Op.type = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.14b: <witness> = custom_witness (%Copy.Op), @Copy [concrete]
// CHECK:STDOUT:   %Copy.facet.d91: %Copy.type = facet_value %Shadowed, (%custom_witness.14b) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.03b: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.d91) [concrete]
// CHECK:STDOUT:   %.bc0: type = fn_type_with_self_type %Copy.WithSelf.Op.type.03b, %Copy.facet.d91 [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet.1e1: %Copy.type = facet_value %i32, (%Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.381: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.1e1) [concrete]
// CHECK:STDOUT:   %.737: type = fn_type_with_self_type %Copy.WithSelf.Op.type.381, %Copy.facet.1e1 [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %Destroy.Op.type: type = fn_type @Destroy.Op [concrete]
// CHECK:STDOUT:   %Destroy.Op: %Destroy.Op.type = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %CopyShadowed.decl: %CopyShadowed.type = fn_decl @CopyShadowed [concrete = constants.%CopyShadowed] {
// CHECK:STDOUT:     %x.param_patt: %pattern_type.915 = value_param_pattern [concrete = constants.%x.param_patt]
// CHECK:STDOUT:     %x.patt: %pattern_type.915 = wrapper_binding_pattern x, %x.param_patt [concrete = constants.%x.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc19: Core.Form = init_form %i32 [concrete = constants.%.795]
// CHECK:STDOUT:     %x.param: %Shadowed = value_param call_param0
// CHECK:STDOUT:     %Shadowed.ref.loc19: type = name_ref Shadowed, file.%Shadowed.decl [concrete = constants.%Shadowed]
// CHECK:STDOUT:     %x: %Shadowed = wrapper_binding x, %x.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @CopyShadowed(%x.param: %Shadowed) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %y.var: ref %Shadowed = var_storage %y.var_patt
// CHECK:STDOUT:   %x.ref: %Shadowed = name_ref x, %x
// CHECK:STDOUT:   %impl.elem0.loc20: %.bc0 = impl_witness_access constants.%custom_witness.14b, element0 [concrete = constants.%Copy.Op]
// CHECK:STDOUT:   %bound_method.loc20: <bound method> = bound_method %x.ref, %impl.elem0.loc20
// CHECK:STDOUT:   %.loc20: ref %Shadowed = splice_block %y.var {}
// CHECK:STDOUT:   %Copy.Op.call: init %Shadowed to %.loc20 = call %bound_method.loc20(%x.ref)
// CHECK:STDOUT:   assign %y.var, %Copy.Op.call
// CHECK:STDOUT:   %Shadowed.ref.loc20: type = name_ref Shadowed, file.%Shadowed.decl [concrete = constants.%Shadowed]
// CHECK:STDOUT:   %y: ref %Shadowed = wrapper_binding y, %y.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %y.patt: %pattern_type.915 = ref_binding_pattern y [concrete = constants.%y.patt]
// CHECK:STDOUT:     %y.var_patt: %pattern_type.915 = var_pattern %y.patt [concrete = constants.%y.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %y.ref: ref %Shadowed = name_ref y, %y
// CHECK:STDOUT:   %a.ref: %Shadowed.elem = name_ref a, @Shadowed.%.loc8 [concrete = @Shadowed.%.loc8]
// CHECK:STDOUT:   %.loc21_11.1: ref %i32 = class_element_access %y.ref, element0
// CHECK:STDOUT:   %.loc21_11.2: %i32 = acquire_value %.loc21_11.1
// CHECK:STDOUT:   %impl.elem0.loc21: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc21_11.1: <bound method> = bound_method %.loc21_11.2, %impl.elem0.loc21
// CHECK:STDOUT:   %specific_fn: <specific function> = specific_function %impl.elem0.loc21, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc21_11.2: <bound method> = bound_method %.loc21_11.2, %specific_fn
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc21_11.2(%.loc21_11.2)
// CHECK:STDOUT:   %Destroy.Op.bound: <bound method> = bound_method %y.var, constants.%Destroy.Op
// CHECK:STDOUT:   %Destroy.Op.call: init %empty_tuple.type = call %Destroy.Op.bound(%y.var)
// CHECK:STDOUT:   return %Int.as.Copy.impl.Op.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op(%self.param: ref %Shadowed) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- method.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %IntOrBytes: type = class_type @IntOrBytes [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %IntOrBytes.elem.a3f: type = unbound_element_type %IntOrBytes, %i32 [concrete]
// CHECK:STDOUT:   %int_8: Core.IntLiteral = int_value 8 [concrete]
// CHECK:STDOUT:   %i8: type = class_type @Int, @Int(%int_8) [concrete]
// CHECK:STDOUT:   %int_4: Core.IntLiteral = int_value 4 [concrete]
// CHECK:STDOUT:   %array_type: type = array_type %int_4, %i8 [concrete]
// CHECK:STDOUT:   %IntOrBytes.elem.ff6: type = unbound_element_type %IntOrBytes, %array_type [concrete]
// CHECK:STDOUT:   %pattern_type.970: type = pattern_type %IntOrBytes [concrete]
// CHECK:STDOUT:   %self.param_patt.52b: %pattern_type.970 = value_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.b37: %pattern_type.970 = wrapper_binding_pattern self, %self.param_patt.52b [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %IntOrBytes.LowHalf.type: type = fn_type @IntOrBytes.LowHalf [concrete]
// CHECK:STDOUT:   %IntOrBytes.LowHalf: %IntOrBytes.LowHalf.type = struct_value () [concrete]
// CHECK:STDOUT:   %self.param_patt.453: %pattern_type.970 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.e2e: %pattern_type.970 = wrapper_binding_pattern self, %self.param_patt.453 [concrete]
// CHECK:STDOUT:   %x.param_patt: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %x.patt: %pattern_type.6b6 = wrapper_binding_pattern x, %x.param_patt [concrete]
// CHECK:STDOUT:   %IntOrBytes.Set.type: type = fn_type @IntOrBytes.Set [concrete]
// CHECK:STDOUT:   %IntOrBytes.Set: %IntOrBytes.Set.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %To.fe9: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %From.fe9: Core.IntLiteral = symbolic_binding From, 0 [symbolic]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.6e0: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_0.3c0: %i32 = int_value 0 [concrete]
// CHECK:STDOUT:   %As.type.155: type = facet_type <@As, @As(%i32)> [concrete]
// CHECK:STDOUT:   %To.d23: Core.IntLiteral = symbolic_binding To, 1 [symbolic]
// CHECK:STDOUT:   %Int.as.As.impl.Convert.type.a00: type = fn_type @Int.as.As.impl.Convert.2, @Int.as.As.impl.c50(%From.fe9, %To.d23) [symbolic]
// CHECK:STDOUT:   %Int.as.As.impl.Convert.3b9: %Int.as.As.impl.Convert.type.a00 = struct_value () [symbolic]
// CHECK:STDOUT:   %As.impl_witness.33c: <witness> = impl_witness imports.%As.impl_witness_table.dc5, @Int.as.As.impl.c50(%int_8, %int_32) [concrete]
// CHECK:STDOUT:   %Int.as.As.impl.Convert.type.892: type = fn_type @Int.as.As.impl.Convert.2, @Int.as.As.impl.c50(%int_8, %int_32) [concrete]
// CHECK:STDOUT:   %Int.as.As.impl.Convert.c63: %Int.as.As.impl.Convert.type.892 = struct_value () [concrete]
// CHECK:STDOUT:   %As.facet: %As.type.155 = facet_value %i8, (%As.impl_witness.33c) [concrete]
// CHECK:STDOUT:   %As.WithSelf.Convert.type.7de: type = fn_type @As.WithSelf.Convert, @As.WithSelf(%i32, %As.facet) [concrete]
// CHECK:STDOUT:   %.35d: type = fn_type_with_self_type %As.WithSelf.Convert.type.7de, %As.facet [concrete]
// CHECK:STDOUT:   %Int.as.As.impl.Convert.specific_fn: <specific function> = specific_function %Int.as.As.impl.Convert.c63, @Int.as.As.impl.Convert.2(%int_8, %int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet.1e1: %Copy.type = facet_value %i32, (%Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.381: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.1e1) [concrete]
// CHECK:STDOUT:   %.737: type = fn_type_with_self_type %Copy.WithSelf.Op.type.381, %Copy.facet.1e1 [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %u.param_patt: %pattern_type.970 = value_param_pattern [concrete]
// CHECK:STDOUT:   %u.patt: %pattern_type.970 = wrapper_binding_pattern u, %u.param_patt [concrete]
// CHECK:STDOUT:   %UseMethods.type: type = fn_type @UseMethods [concrete]
// CHECK:STDOUT:   %UseMethods: %UseMethods.type = struct_value () [concrete]
// CHECK:STDOUT:   %v.patt: %pattern_type.970 = ref_binding_pattern v [concrete]
// CHECK:STDOUT:   %v.var_patt: %pattern_type.970 = var_pattern %v.patt [concrete]
// CHECK:STDOUT:   %Copy.Op.type: type = fn_type @Copy.Op [concrete]
// CHECK:STDOUT:   %Copy.Op: %Copy.Op.type = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.14b: <witness> = custom_witness (%Copy.Op), @Copy [concrete]
// CHECK:STDOUT:   %Copy.facet.fcd: %Copy.type = facet_value %IntOrBytes, (%custom_witness.14b) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.2bd: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.fcd) [concrete]
// CHECK:STDOUT:   %.c63: type = fn_type_with_self_type %Copy.WithSelf.Op.type.2bd, %Copy.facet.fcd [concrete]
// CHECK:STDOUT:   %int_3.1ba: Core.IntLiteral = int_value 3 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.485: <bound method> = bound_method %int_3.1ba, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.763: <bound method> = bound_method %int_3.1ba, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_3.410: %i32 = int_value 3 [concrete]
// CHECK:STDOUT:   %Destroy.Op.type: type = fn_type @Destroy.Op [concrete]
// CHECK:STDOUT:   %Destroy.Op: %Destroy.Op.type = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.a86: @Int.as.As.impl.c50.%Int.as.As.impl.Convert.type (%Int.as.As.impl.Convert.type.a00) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.As.impl.c50.%Int.as.As.impl.Convert (constants.%Int.as.As.impl.Convert.3b9)]
// CHECK:STDOUT:   %As.impl_witness_table.dc5 = impl_witness_table (%Core.import_ref.a86), @Int.as.As.impl.c50 [concrete]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %IntOrBytes.decl: type = class_decl @IntOrBytes [concrete = constants.%IntOrBytes] {} {}
// CHECK:STDOUT:   %UseMethods.decl: %UseMethods.type = fn_decl @UseMethods [concrete = constants.%UseMethods] {
// CHECK:STDOUT:     %u.param_patt: %pattern_type.970 = value_param_pattern [concrete = constants.%u.param_patt]
// CHECK:STDOUT:     %u.patt: %pattern_type.970 = wrapper_binding_pattern u, %u.param_patt [concrete = constants.%u.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc12: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %u.param: %IntOrBytes = value_param call_param0
// CHECK:STDOUT:     %IntOrBytes.ref.loc12: type = name_ref IntOrBytes, file.%IntOrBytes.decl [concrete = constants.%IntOrBytes]
// CHECK:STDOUT:     %u: %IntOrBytes = wrapper_binding u, %u.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: class @IntOrBytes {
// CHECK:STDOUT:   %.loc5: %IntOrBytes.elem.a3f = field_decl word, element0 [concrete]
// CHECK:STDOUT:   %.loc6: %IntOrBytes.elem.ff6 = field_decl bytes, element1 [concrete]
// CHECK:STDOUT:   %IntOrBytes.LowHalf.decl: %IntOrBytes.LowHalf.type = fn_decl @IntOrBytes.LowHalf [concrete = constants.%IntOrBytes.LowHalf] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.970 = value_param_pattern [concrete = constants.%self.param_patt.52b]
// CHECK:STDOUT:     %self.patt: %pattern_type.970 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.b37]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc8_23 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc8_23: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc8_23: Core.Form = init_form %i32.loc8_23 [concrete = constants.%.795f]
// CHECK:STDOUT:     %self.param: %IntOrBytes = value_param call_param0
// CHECK:STDOUT:     %Self.ref: type = name_ref Self, constants.%IntOrBytes [concrete = constants.%IntOrBytes]
// CHECK:STDOUT:     %self: %IntOrBytes = wrapper_binding self, %self.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %IntOrBytes.Set.decl: %IntOrBytes.Set.type = fn_decl @IntOrBytes.Set [concrete = constants.%IntOrBytes.Set] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.970 = ref_param_pattern [concrete = constants.%self.param_patt.453]
// CHECK:STDOUT:     %self.patt: %pattern_type.970 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.e2e]
// CHECK:STDOUT:     %x.param_patt: %pattern_type.6b6 = value_param_pattern [concrete = constants.%x.param_patt]
// CHECK:STDOUT:     %x.patt: %pattern_type.6b6 = wrapper_binding_pattern x, %x.param_patt [concrete = constants.%x.patt]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %IntOrBytes = ref_param call_param0
// CHECK:STDOUT:     %Self.ref: type = name_ref Self, constants.%IntOrBytes [concrete = constants.%IntOrBytes]
// CHECK:STDOUT:     %self: ref %IntOrBytes = wrapper_binding self, %self.param
// CHECK:STDOUT:     %x.param: %i32 = value_param call_param1
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %x: %i32 = wrapper_binding x, %x.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   complete_type_witness = <error>
// CHECK:STDOUT:
// CHECK:STDOUT: !members:
// CHECK:STDOUT:   .Self = constants.%IntOrBytes
// CHECK:STDOUT:   .word = %.loc5
// CHECK:STDOUT:   .bytes = %.loc6
// CHECK:STDOUT:   .LowHalf = %IntOrBytes.LowHalf.decl
// CHECK:STDOUT:   .Set = %IntOrBytes.Set.decl
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @IntOrBytes.LowHalf(%self.param: %IntOrBytes) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %self.ref: %IntOrBytes = name_ref self, %self
// CHECK:STDOUT:   %bytes.ref: %IntOrBytes.elem.ff6 = name_ref bytes, @IntOrBytes.%.loc6 [concrete = @IntOrBytes.%.loc6]
// CHECK:STDOUT:   %.loc8_40.1: ref %array_type = class_element_access %self.ref, element1
// CHECK:STDOUT:   %.loc8_40.2: %array_type = acquire_value %.loc8_40.1
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc8_47: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc8_47.1: <bound method> = bound_method %int_0, %impl.elem0.loc8_47 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc8_47: <specific function> = specific_function %impl.elem0.loc8_47, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc8_47.2: <bound method> = bound_method %int_0, %specific_fn.loc8_47 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %i32 = call %bound_method.loc8_47.2(%int_0) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc8_47.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc8_47.2: %i32 = converted %int_0, %.loc8_47.1 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc8_48.1: ref %array_type = value_as_ref %.loc8_40.2
// CHECK:STDOUT:   %.loc8_48.2: ref %i8 = array_index %.loc8_48.1, %.loc8_47.2
// CHECK:STDOUT:   %.loc8_48.3: %i8 = acquire_value %.loc8_48.2
// CHECK:STDOUT:   %i32.loc8_53: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %impl.elem0.loc8_50.1: %.35d = impl_witness_access constants.%As.impl_witness.33c, element0 [concrete = constants.%Int.as.As.impl.Convert.c63]
// CHECK:STDOUT:   %bound_method.loc8_50.1: <bound method> = bound_method %.loc8_48.3, %impl.elem0.loc8_50.1
// CHECK:STDOUT:   %specific_fn.loc8_50.1: <specific function> = specific_function %impl.elem0.loc8_50.1, @Int.as.As.impl.Convert.2(constants.%int_8, constants.%int_32) [concrete = constants.%Int.as.As.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc8_50.2: <bound method> = bound_method %.loc8_48.3, %specific_fn.loc8_50.1
// CHECK:STDOUT:   %Int.as.As.impl.Convert.call: init %i32 = call %bound_method.loc8_50.2(%.loc8_48.3)
// CHECK:STDOUT:   %.loc8_50.1: %i32 = value_of_initializer %Int.as.As.impl.Convert.call
// CHECK:STDOUT:   %.loc8_50.2: %i32 = converted %.loc8_48.3, %.loc8_50.1
// CHECK:STDOUT:   %impl.elem0.loc8_50.2: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc8_50.3: <bound method> = bound_method %.loc8_50.2, %impl.elem0.loc8_50.2
// CHECK:STDOUT:   %specific_fn.loc8_50.2: <specific function> = specific_function %impl.elem0.loc8_50.2, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc8_50.4: <bound method> = bound_method %.loc8_50.2, %specific_fn.loc8_50.2
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc8_50.4(%.loc8_50.2)
// CHECK:STDOUT:   return %Int.as.Copy.impl.Op.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @IntOrBytes.Set(%self.param: ref %IntOrBytes, %x.param: %i32) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %self.ref: ref %IntOrBytes = name_ref self, %self
// CHECK:STDOUT:   %word.ref: %IntOrBytes.elem.a3f = name_ref word, @IntOrBytes.%.loc5 [concrete = @IntOrBytes.%.loc5]
// CHECK:STDOUT:   %.loc9: ref %i32 = class_element_access %self.ref, element0
// CHECK:STDOUT:   %x.ref: %i32 = name_ref x, %x
// CHECK:STDOUT:   %impl.elem0: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc9_42.1: <bound method> = bound_method %x.ref, %impl.elem0
// CHECK:STDOUT:   %specific_fn: <specific function> = specific_function %impl.elem0, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc9_42.2: <bound method> = bound_method %x.ref, %specific_fn
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc9_42.2(%x.ref)
// CHECK:STDOUT:   assign %.loc9, %Int.as.Copy.impl.Op.call
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @UseMethods(%u.param: %IntOrBytes) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %v.var: ref %IntOrBytes = var_storage %v.var_patt
// CHECK:STDOUT:   %u.ref: %IntOrBytes = name_ref u, %u
// CHECK:STDOUT:   %impl.elem0.loc13: %.c63 = impl_witness_access constants.%custom_witness.14b, element0 [concrete = constants.%Copy.Op]
// CHECK:STDOUT:   %bound_method.loc13: <bound method> = bound_method %u.ref, %impl.elem0.loc13
// CHECK:STDOUT:   %.loc13: ref %IntOrBytes = splice_block %v.var {}
// CHECK:STDOUT:   %Copy.Op.call: init %IntOrBytes to %.loc13 = call %bound_method.loc13(%u.ref)
// CHECK:STDOUT:   assign %v.var, %Copy.Op.call
// CHECK:STDOUT:   %IntOrBytes.ref.loc13: type = name_ref IntOrBytes, file.%IntOrBytes.decl [concrete = constants.%IntOrBytes]
// CHECK:STDOUT:   %v: ref %IntOrBytes = wrapper_binding v, %v.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %v.patt: %pattern_type.970 = ref_binding_pattern v [concrete = constants.%v.patt]
// CHECK:STDOUT:     %v.var_patt: %pattern_type.970 = var_pattern %v.patt [concrete = constants.%v.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %v.ref.loc14: ref %IntOrBytes = name_ref v, %v
// CHECK:STDOUT:   %Set.ref: %IntOrBytes.Set.type = name_ref Set, @IntOrBytes.%IntOrBytes.Set.decl [concrete = constants.%IntOrBytes.Set]
// CHECK:STDOUT:   %IntOrBytes.Set.bound: <bound method> = bound_method %v.ref.loc14, %Set.ref
// CHECK:STDOUT:   %int_3: Core.IntLiteral = int_value 3 [concrete = constants.%int_3.1ba]
// CHECK:STDOUT:   %impl.elem0.loc14: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc14_9.1: <bound method> = bound_method %int_3, %impl.elem0.loc14 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.485]
// CHECK:STDOUT:   %specific_fn: <specific function> = specific_function %impl.elem0.loc14, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc14_9.2: <bound method> = bound_method %int_3, %specific_fn [concrete = constants.%bound_method.763]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %i32 = call %bound_method.loc14_9.2(%int_3) [concrete = constants.%int_3.410]
// CHECK:STDOUT:   %.loc14_9.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_3.410]
// CHECK:STDOUT:   %.loc14_9.2: %i32 = converted %int_3, %.loc14_9.1 [concrete = constants.%int_3.410]
// CHECK:STDOUT:   %IntOrBytes.Set.call: init %empty_tuple.type = call %IntOrBytes.Set.bound(%v.ref.loc14, %.loc14_9.2)
// CHECK:STDOUT:   %v.ref.loc15: ref %IntOrBytes = name_ref v, %v
// CHECK:STDOUT:   %LowHalf.ref: %IntOrBytes.LowHalf.type = name_ref LowHalf, @IntOrBytes.%IntOrBytes.LowHalf.decl [concrete = constants.%IntOrBytes.LowHalf]
// CHECK:STDOUT:   %IntOrBytes.LowHalf.bound: <bound method> = bound_method %v.ref.loc15, %LowHalf.ref
// CHECK:STDOUT:   %.loc15: %IntOrBytes = acquire_value %v.ref.loc15
// CHECK:STDOUT:   %IntOrBytes.LowHalf.call: init %i32 = call %IntOrBytes.LowHalf.bound(%.loc15)
// CHECK:STDOUT:   %Destroy.Op.bound: <bound method> = bound_method %v.var, constants.%Destroy.Op
// CHECK:STDOUT:   %Destroy.Op.call: init %empty_tuple.type = call %Destroy.Op.bound(%v.var)
// CHECK:STDOUT:   return %IntOrBytes.LowHalf.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op(%self.param: ref %IntOrBytes) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- impl_member.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %I.type: type = facet_type <@I> [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %.795: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %I.assoc_type: type = assoc_entity_type @I [concrete]
// CHECK:STDOUT:   %assoc0.510: %I.assoc_type = assoc_entity element0, @I.WithSelf.%I.WithSelf.Get.decl [concrete]
// CHECK:STDOUT:   %WithImpl: type = class_type @WithImpl [concrete]
// CHECK:STDOUT:   %WithImpl.elem: type = unbound_element_type %WithImpl, %i32 [concrete]
// CHECK:STDOUT:   %.4b6: <witness> = impl_self_witness %WithImpl, @I [concrete]
// CHECK:STDOUT:   %I.impl_witness: <witness> = impl_witness @WithImpl.as.I.impl.%I.impl_witness_table [concrete]
// CHECK:STDOUT:   %pattern_type.b67: type = pattern_type %WithImpl [concrete]
// CHECK:STDOUT:   %self.param_patt.636: %pattern_type.b67 = value_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.a82: %pattern_type.b67 = wrapper_binding_pattern self, %self.param_patt.636 [concrete]
// CHECK:STDOUT:   %WithImpl.as.I.impl.Get.type: type = fn_type @WithImpl.as.I.impl.Get [concrete]
// CHECK:STDOUT:   %WithImpl.as.I.impl.Get: %WithImpl.as.I.impl.Get.type = struct_value () [concrete]
// CHECK:STDOUT:   %I.facet: %I.type = facet_value %WithImpl, (%I.impl_witness) [concrete]
// CHECK:STDOUT:   %I.WithSelf.Get.type.a11: type = fn_type @I.WithSelf.Get, @I.WithSelf(%I.facet) [concrete]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet: %Copy.type = facet_value %i32, (%Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.381: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet) [concrete]
// CHECK:STDOUT:   %.737: type = fn_type_with_self_type %Copy.WithSelf.Op.type.381, %Copy.facet [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %u.param_patt: %pattern_type.b67 = value_param_pattern [concrete]
// CHECK:STDOUT:   %u.patt: %pattern_type.b67 = wrapper_binding_pattern u, %u.param_patt [concrete]
// CHECK:STDOUT:   %UseImpl.type: type = fn_type @UseImpl [concrete]
// CHECK:STDOUT:   %UseImpl: %UseImpl.type = struct_value () [concrete]
// CHECK:STDOUT:   %.840: type = fn_type_with_self_type %I.WithSelf.Get.type.a11, %I.facet [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %WithImpl.decl: type = class_decl @WithImpl [concrete = constants.%WithImpl] {} {}
// CHECK:STDOUT:   %UseImpl.decl: %UseImpl.type = fn_decl @UseImpl [concrete = constants.%UseImpl] {
// CHECK:STDOUT:     %u.param_patt: %pattern_type.b67 = value_param_pattern [concrete = constants.%u.param_patt]
// CHECK:STDOUT:     %u.patt: %pattern_type.b67 = wrapper_binding_pattern u, %u.param_patt [concrete = constants.%u.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc19: Core.Form = init_form %i32 [concrete = constants.%.795]
// CHECK:STDOUT:     %u.param: %WithImpl = value_param call_param0
// CHECK:STDOUT:     %WithImpl.ref: type = name_ref WithImpl, file.%WithImpl.decl [concrete = constants.%WithImpl]
// CHECK:STDOUT:     %u: %WithImpl = wrapper_binding u, %u.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: impl @WithImpl.as.I.impl: %Self.ref as %I.ref {
// CHECK:STDOUT:   %WithImpl.as.I.impl.Get.decl: %WithImpl.as.I.impl.Get.type = fn_decl @WithImpl.as.I.impl.Get [concrete = constants.%WithImpl.as.I.impl.Get] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.b67 = value_param_pattern [concrete = constants.%self.param_patt.636]
// CHECK:STDOUT:     %self.patt: %pattern_type.b67 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.a82]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc15_21: Core.Form = init_form %i32 [concrete = constants.%.795]
// CHECK:STDOUT:     %self.param: %WithImpl = value_param call_param0
// CHECK:STDOUT:     %Self.ref: type = name_ref Self, constants.%WithImpl [concrete = constants.%WithImpl]
// CHECK:STDOUT:     %self: %WithImpl = wrapper_binding self, %self.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %I.impl_witness_table = impl_witness_table (%WithImpl.as.I.impl.Get.decl), @WithImpl.as.I.impl [concrete]
// CHECK:STDOUT:   %I.impl_witness: <witness> = impl_witness %I.impl_witness_table [concrete = constants.%I.impl_witness]
// CHECK:STDOUT:
// CHECK:STDOUT: !members:
// CHECK:STDOUT:   .Get = %WithImpl.as.I.impl.Get.decl
// CHECK:STDOUT:   extend %I.ref
// CHECK:STDOUT:   witness = %I.impl_witness
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: class @WithImpl {
// CHECK:STDOUT:   %.loc13: %WithImpl.elem = field_decl a, element0 [concrete]
// CHECK:STDOUT:   impl_decl @WithImpl.as.I.impl [concrete] {} {
// CHECK:STDOUT:     %Self.ref: type = name_ref Self, constants.%WithImpl [concrete = constants.%WithImpl]
// CHECK:STDOUT:     %I.ref: type = name_ref I, file.%I.decl [concrete = constants.%I.type]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %.loc14: <witness> = impl_self_witness @WithImpl.as.I.impl.%Self.ref, @I [concrete = constants.%.4b6]
// CHECK:STDOUT:   complete_type_witness = <error>
// CHECK:STDOUT:
// CHECK:STDOUT: !members:
// CHECK:STDOUT:   .Self = constants.%WithImpl
// CHECK:STDOUT:   .a = %.loc13
// CHECK:STDOUT:   .I = <poisoned>
// CHECK:STDOUT:   .Get = <poisoned>
// CHECK:STDOUT:   extend @WithImpl.as.I.impl.%I.ref
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @WithImpl.as.I.impl.Get(%self.param: %WithImpl) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %self.ref: %WithImpl = name_ref self, %self
// CHECK:STDOUT:   %a.ref: %WithImpl.elem = name_ref a, @WithImpl.%.loc13 [concrete = @WithImpl.%.loc13]
// CHECK:STDOUT:   %.loc15_38.1: ref %i32 = class_element_access %self.ref, element0
// CHECK:STDOUT:   %.loc15_38.2: %i32 = acquire_value %.loc15_38.1
// CHECK:STDOUT:   %impl.elem0: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc15_38.1: <bound method> = bound_method %.loc15_38.2, %impl.elem0
// CHECK:STDOUT:   %specific_fn: <specific function> = specific_function %impl.elem0, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc15_38.2: <bound method> = bound_method %.loc15_38.2, %specific_fn
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc15_38.2(%.loc15_38.2)
// CHECK:STDOUT:   return %Int.as.Copy.impl.Op.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @UseImpl(%u.param: %WithImpl) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %u.ref: %WithImpl = name_ref u, %u
// CHECK:STDOUT:   %Get.ref: %I.assoc_type = name_ref Get, @I.WithSelf.%assoc0 [concrete = constants.%assoc0.510]
// CHECK:STDOUT:   %impl.elem0: %.840 = impl_witness_access constants.%I.impl_witness, element0 [concrete = constants.%WithImpl.as.I.impl.Get]
// CHECK:STDOUT:   %bound_method: <bound method> = bound_method %u.ref, %impl.elem0
// CHECK:STDOUT:   %WithImpl.as.I.impl.Get.call: init %i32 = call %bound_method(%u.ref)
// CHECK:STDOUT:   return %WithImpl.as.I.impl.Get.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- forward_decl.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %U.951: type = class_type @U [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %U.elem: type = unbound_element_type %U.951, %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.3db: type = pattern_type %U.951 [concrete]
// CHECK:STDOUT:   %u.param_patt: %pattern_type.3db = value_param_pattern [concrete]
// CHECK:STDOUT:   %u.patt: %pattern_type.3db = wrapper_binding_pattern u, %u.param_patt [concrete]
// CHECK:STDOUT:   %.795: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %UseU.type: type = fn_type @UseU [concrete]
// CHECK:STDOUT:   %UseU: %UseU.type = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet: %Copy.type = facet_value %i32, (%Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.381: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet) [concrete]
// CHECK:STDOUT:   %.737: type = fn_type_with_self_type %Copy.WithSelf.Op.type.381, %Copy.facet [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %U.decl.loc6: type = class_decl @U [concrete = constants.%U.951] {} {}
// CHECK:STDOUT:   %U.decl.loc8: type = class_decl @U [concrete = constants.%U.951] {} {}
// CHECK:STDOUT:   %UseU.decl: %UseU.type = fn_decl @UseU [concrete = constants.%UseU] {
// CHECK:STDOUT:     %u.param_patt: %pattern_type.3db = value_param_pattern [concrete = constants.%u.param_patt]
// CHECK:STDOUT:     %u.patt: %pattern_type.3db = wrapper_binding_pattern u, %u.param_patt [concrete = constants.%u.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc12_18: Core.Form = init_form %i32 [concrete = constants.%.795]
// CHECK:STDOUT:     %u.param: %U.951 = value_param call_param0
// CHECK:STDOUT:     %U.ref: type = name_ref U, file.%U.decl.loc6 [concrete = constants.%U.951]
// CHECK:STDOUT:     %u: %U.951 = wrapper_binding u, %u.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: class @U {
// CHECK:STDOUT:   %.loc9: %U.elem = field_decl a, element0 [concrete]
// CHECK:STDOUT:   complete_type_witness = <error>
// CHECK:STDOUT:
// CHECK:STDOUT: !members:
// CHECK:STDOUT:   .Self = constants.%U.951
// CHECK:STDOUT:   .a = %.loc9
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @UseU(%u.param: %U.951) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %u.ref: %U.951 = name_ref u, %u
// CHECK:STDOUT:   %a.ref: %U.elem = name_ref a, @U.%.loc9 [concrete = @U.%.loc9]
// CHECK:STDOUT:   %.loc12_32.1: ref %i32 = class_element_access %u.ref, element0
// CHECK:STDOUT:   %.loc12_32.2: %i32 = acquire_value %.loc12_32.1
// CHECK:STDOUT:   %impl.elem0: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc12_32.1: <bound method> = bound_method %.loc12_32.2, %impl.elem0
// CHECK:STDOUT:   %specific_fn: <specific function> = specific_function %impl.elem0, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc12_32.2: <bound method> = bound_method %.loc12_32.2, %specific_fn
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc12_32.2(%.loc12_32.2)
// CHECK:STDOUT:   return %Int.as.Copy.impl.Op.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- member_of_class.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %C: type = class_type @C [concrete]
// CHECK:STDOUT:   %Inner: type = class_type @Inner [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %Inner.elem: type = unbound_element_type %Inner, %i32 [concrete]
// CHECK:STDOUT:   %C.elem: type = unbound_element_type %C, %Inner [concrete]
// CHECK:STDOUT:   %struct_type.u: type = struct_type {.u: %Inner} [concrete]
// CHECK:STDOUT:   %complete_type.e2c: <witness> = complete_type_witness %struct_type.u [concrete]
// CHECK:STDOUT:   %pattern_type.98b: type = pattern_type %C [concrete]
// CHECK:STDOUT:   %c.param_patt: %pattern_type.98b = value_param_pattern [concrete]
// CHECK:STDOUT:   %c.patt: %pattern_type.98b = wrapper_binding_pattern c, %c.param_patt [concrete]
// CHECK:STDOUT:   %.795: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %UseInner.type: type = fn_type @UseInner [concrete]
// CHECK:STDOUT:   %UseInner: %UseInner.type = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet: %Copy.type = facet_value %i32, (%Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.381: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet) [concrete]
// CHECK:STDOUT:   %.737: type = fn_type_with_self_type %Copy.WithSelf.Op.type.381, %Copy.facet [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %C.decl: type = class_decl @C [concrete = constants.%C] {} {}
// CHECK:STDOUT:   %UseInner.decl: %UseInner.type = fn_decl @UseInner [concrete = constants.%UseInner] {
// CHECK:STDOUT:     %c.param_patt: %pattern_type.98b = value_param_pattern [concrete = constants.%c.param_patt]
// CHECK:STDOUT:     %c.patt: %pattern_type.98b = wrapper_binding_pattern c, %c.param_patt [concrete = constants.%c.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc11_22: Core.Form = init_form %i32 [concrete = constants.%.795]
// CHECK:STDOUT:     %c.param: %C = value_param call_param0
// CHECK:STDOUT:     %C.ref: type = name_ref C, file.%C.decl [concrete = constants.%C]
// CHECK:STDOUT:     %c: %C = wrapper_binding c, %c.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: class @C {
// CHECK:STDOUT:   %Inner.decl: type = class_decl @Inner [concrete = constants.%Inner] {} {}
// CHECK:STDOUT:   %.loc8: %C.elem = field_decl u, element0 [concrete]
// CHECK:STDOUT:   %complete_type: <witness> = complete_type_witness constants.%struct_type.u [concrete = constants.%complete_type.e2c]
// CHECK:STDOUT:   complete_type_witness = %complete_type
// CHECK:STDOUT:
// CHECK:STDOUT: !members:
// CHECK:STDOUT:   .Self = constants.%C
// CHECK:STDOUT:   .Inner = %Inner.decl
// CHECK:STDOUT:   .u = %.loc8
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: class @Inner {
// CHECK:STDOUT:   %.loc6: %Inner.elem = field_decl a, element0 [concrete]
// CHECK:STDOUT:   complete_type_witness = <error>
// CHECK:STDOUT:
// CHECK:STDOUT: !members:
// CHECK:STDOUT:   .Self = constants.%Inner
// CHECK:STDOUT:   .a = %.loc6
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @UseInner(%c.param: %C) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %c.ref: %C = name_ref c, %c
// CHECK:STDOUT:   %u.ref: %C.elem = name_ref u, @C.%.loc8 [concrete = @C.%.loc8]
// CHECK:STDOUT:   %.loc11_36.1: ref %Inner = class_element_access %c.ref, element0
// CHECK:STDOUT:   %.loc11_36.2: %Inner = acquire_value %.loc11_36.1
// CHECK:STDOUT:   %a.ref: %Inner.elem = name_ref a, @Inner.%.loc6 [concrete = @Inner.%.loc6]
// CHECK:STDOUT:   %.loc11_38.1: ref %i32 = class_element_access %.loc11_36.2, element0
// CHECK:STDOUT:   %.loc11_38.2: %i32 = acquire_value %.loc11_38.1
// CHECK:STDOUT:   %impl.elem0: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc11_38.1: <bound method> = bound_method %.loc11_38.2, %impl.elem0
// CHECK:STDOUT:   %specific_fn: <specific function> = specific_function %impl.elem0, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc11_38.2: <bound method> = bound_method %.loc11_38.2, %specific_fn
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc11_38.2(%.loc11_38.2)
// CHECK:STDOUT:   return %Int.as.Copy.impl.Op.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- namespace_scoped.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %U.e8a: type = class_type @U [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %U.elem: type = unbound_element_type %U.e8a, %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.0ab: type = pattern_type %U.e8a [concrete]
// CHECK:STDOUT:   %u.param_patt: %pattern_type.0ab = value_param_pattern [concrete]
// CHECK:STDOUT:   %u.patt: %pattern_type.0ab = wrapper_binding_pattern u, %u.param_patt [concrete]
// CHECK:STDOUT:   %.795: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %UseNU.type: type = fn_type @UseNU [concrete]
// CHECK:STDOUT:   %UseNU: %UseNU.type = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet: %Copy.type = facet_value %i32, (%Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.381: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet) [concrete]
// CHECK:STDOUT:   %.737: type = fn_type_with_self_type %Copy.WithSelf.Op.type.381, %Copy.facet [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %U.decl: type = class_decl @U [concrete = constants.%U.e8a] {} {}
// CHECK:STDOUT:   %UseNU.decl: %UseNU.type = fn_decl @UseNU [concrete = constants.%UseNU] {
// CHECK:STDOUT:     %u.param_patt: %pattern_type.0ab = value_param_pattern [concrete = constants.%u.param_patt]
// CHECK:STDOUT:     %u.patt: %pattern_type.0ab = wrapper_binding_pattern u, %u.param_patt [concrete = constants.%u.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc10_21: Core.Form = init_form %i32 [concrete = constants.%.795]
// CHECK:STDOUT:     %u.param: %U.e8a = value_param call_param0
// CHECK:STDOUT:     %.loc10_14: type = splice_block %U.ref [concrete = constants.%U.e8a] {
// CHECK:STDOUT:       %N.ref: <namespace> = name_ref N, file.%N [concrete = file.%N]
// CHECK:STDOUT:       %U.ref: type = name_ref U, file.%U.decl [concrete = constants.%U.e8a]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %u: %U.e8a = wrapper_binding u, %u.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: class @U {
// CHECK:STDOUT:   %.loc7: %U.elem = field_decl a, element0 [concrete]
// CHECK:STDOUT:   complete_type_witness = <error>
// CHECK:STDOUT:
// CHECK:STDOUT: !members:
// CHECK:STDOUT:   .Self = constants.%U.e8a
// CHECK:STDOUT:   .a = %.loc7
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @UseNU(%u.param: %U.e8a) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %u.ref: %U.e8a = name_ref u, %u
// CHECK:STDOUT:   %a.ref: %U.elem = name_ref a, @U.%.loc7 [concrete = @U.%.loc7]
// CHECK:STDOUT:   %.loc10_35.1: ref %i32 = class_element_access %u.ref, element0
// CHECK:STDOUT:   %.loc10_35.2: %i32 = acquire_value %.loc10_35.1
// CHECK:STDOUT:   %impl.elem0: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc10_35.1: <bound method> = bound_method %.loc10_35.2, %impl.elem0
// CHECK:STDOUT:   %specific_fn: <specific function> = specific_function %impl.elem0, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc10_35.2: <bound method> = bound_method %.loc10_35.2, %specific_fn
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc10_35.2(%.loc10_35.2)
// CHECK:STDOUT:   return %Int.as.Copy.impl.Op.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- order_independent_i32.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %U.951: type = class_type @U [concrete]
// CHECK:STDOUT:   %U.elem: type = unbound_element_type %U.951, %i32 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %U.decl: type = class_decl @U [concrete = constants.%U.951] {} {}
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: class @U {
// CHECK:STDOUT:   %.loc13: %U.elem = field_decl a, element0 [concrete]
// CHECK:STDOUT:   complete_type_witness = <error>
// CHECK:STDOUT:
// CHECK:STDOUT: !members:
// CHECK:STDOUT:   .Self = constants.%U.951
// CHECK:STDOUT:   .a = %.loc13
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- file_scope_designated.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %IntOrBytes: type = class_type @IntOrBytes [concrete]
// CHECK:STDOUT:   %pattern_type.970: type = pattern_type %IntOrBytes [concrete]
// CHECK:STDOUT:   %g.patt: %pattern_type.970 = ref_binding_pattern g [concrete]
// CHECK:STDOUT:   %g.var_patt: %pattern_type.970 = var_pattern %g.patt [concrete]
// CHECK:STDOUT:   %int_5: Core.IntLiteral = int_value 5 [concrete]
// CHECK:STDOUT:   %struct_type.word: type = struct_type {.word: Core.IntLiteral} [concrete]
// CHECK:STDOUT:   %struct: %struct_type.word = struct_value (%int_5) [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %g.var: ref %IntOrBytes = var_storage %g.var_patt [concrete]
// CHECK:STDOUT:   %IntOrBytes.ref: type = name_ref IntOrBytes, %IntOrBytes.decl [concrete = constants.%IntOrBytes]
// CHECK:STDOUT:   %g: ref %IntOrBytes = wrapper_binding g, %g.var [concrete = %g.var]
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %g.patt: %pattern_type.970 = ref_binding_pattern g [concrete = constants.%g.patt]
// CHECK:STDOUT:     %g.var_patt: %pattern_type.970 = var_pattern %g.patt [concrete = constants.%g.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @__global_init() {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %int_5: Core.IntLiteral = int_value 5 [concrete = constants.%int_5]
// CHECK:STDOUT:   %.loc11: %struct_type.word = struct_literal (%int_5) [concrete = constants.%struct]
// CHECK:STDOUT:   assign file.%g.var, <error>
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- raw_identifier.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %RawIdentifier.type: type = fn_type @RawIdentifier [concrete]
// CHECK:STDOUT:   %RawIdentifier: %RawIdentifier.type = struct_value () [concrete]
// CHECK:STDOUT:   %i32.builtin: type = int_type signed, %int_32 [concrete]
// CHECK:STDOUT:   %union.patt: %pattern_type.6b6 = ref_binding_pattern r#union [concrete]
// CHECK:STDOUT:   %union.var_patt: %pattern_type.6b6 = var_pattern %union.patt [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %To: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet: %Copy.type = facet_value %i32, (%Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.381: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet) [concrete]
// CHECK:STDOUT:   %.737: type = fn_type_with_self_type %Copy.WithSelf.Op.type.381, %Copy.facet [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.2: type = fn_type @Destroy.Op.loc6_3.2 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.2: %Destroy.Op.type.1d8f74.2 = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %RawIdentifier.decl: %RawIdentifier.type = fn_decl @RawIdentifier [concrete = constants.%RawIdentifier] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc5 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc5: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc5: Core.Form = init_form %i32.loc5 [concrete = constants.%.795f]
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param0
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @RawIdentifier() -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %union.var: ref %i32 = var_storage %union.var_patt
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc6: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc6_3.1: <bound method> = bound_method %int_1, %impl.elem0.loc6 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound]
// CHECK:STDOUT:   %specific_fn.loc6: <specific function> = specific_function %impl.elem0.loc6, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc6_3.2: <bound method> = bound_method %int_1, %specific_fn.loc6 [concrete = constants.%bound_method]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %i32 = call %bound_method.loc6_3.2(%int_1) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc6: init %i32 = converted %int_1, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   assign %union.var, %.loc6
// CHECK:STDOUT:   %i32.loc6: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %union: ref %i32 = wrapper_binding r#union, %union.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %union.patt: %pattern_type.6b6 = ref_binding_pattern r#union [concrete = constants.%union.patt]
// CHECK:STDOUT:     %union.var_patt: %pattern_type.6b6 = var_pattern %union.patt [concrete = constants.%union.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %union.ref: ref %i32 = name_ref r#union, %union
// CHECK:STDOUT:   %.loc7: %i32 = acquire_value %union.ref
// CHECK:STDOUT:   %impl.elem0.loc7: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc7_10.1: <bound method> = bound_method %.loc7, %impl.elem0.loc7
// CHECK:STDOUT:   %specific_fn.loc7: <specific function> = specific_function %impl.elem0.loc7, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc7_10.2: <bound method> = bound_method %.loc7, %specific_fn.loc7
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc7_10.2(%.loc7)
// CHECK:STDOUT:   %Destroy.Op.bound: <bound method> = bound_method %union.var, constants.%Destroy.Op.1a2547.2
// CHECK:STDOUT:   %Destroy.Op.call: init %empty_tuple.type = call %Destroy.Op.bound(%union.var)
// CHECK:STDOUT:   return %Int.as.Copy.impl.Op.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc6_3.1(%self.param: ref %i32.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc6_3.2(%self.param: ref %i32) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- nested_union_field.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %IntOrBytes: type = class_type @IntOrBytes [concrete]
// CHECK:STDOUT:   %Outer: type = class_type @Outer [concrete]
// CHECK:STDOUT:   %Outer.elem.1b0: type = unbound_element_type %Outer, %IntOrBytes [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %Outer.elem.528: type = unbound_element_type %Outer, %i64 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Outer.decl: type = class_decl @Outer [concrete = constants.%Outer] {} {}
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: class @Outer {
// CHECK:STDOUT:   %.loc12: %Outer.elem.1b0 = field_decl inner, element0 [concrete]
// CHECK:STDOUT:   %.loc13: %Outer.elem.528 = field_decl w, element1 [concrete]
// CHECK:STDOUT:   complete_type_witness = <error>
// CHECK:STDOUT:
// CHECK:STDOUT: !members:
// CHECK:STDOUT:   .Self = constants.%Outer
// CHECK:STDOUT:   .IntOrBytes = <poisoned>
// CHECK:STDOUT:   .inner = %.loc12
// CHECK:STDOUT:   .w = %.loc13
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- aggregate_fields.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %Aggregates: type = class_type @Aggregates [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %struct_type.a.b: type = struct_type {.a: %i32, .b: %i32} [concrete]
// CHECK:STDOUT:   %Aggregates.elem.431: type = unbound_element_type %Aggregates, %struct_type.a.b [concrete]
// CHECK:STDOUT:   %int_16: Core.IntLiteral = int_value 16 [concrete]
// CHECK:STDOUT:   %i16: type = class_type @Int, @Int(%int_16) [concrete]
// CHECK:STDOUT:   %tuple.type.7d4: type = tuple_type (%i32, %i16) [concrete]
// CHECK:STDOUT:   %Aggregates.elem.4f3: type = unbound_element_type %Aggregates, %tuple.type.7d4 [concrete]
// CHECK:STDOUT:   %ptr.d08: type = ptr_type %i32 [concrete]
// CHECK:STDOUT:   %Aggregates.elem.9b1: type = unbound_element_type %Aggregates, %ptr.d08 [concrete]
// CHECK:STDOUT:   %Aggregates.elem.0bd: type = unbound_element_type %Aggregates, bool [concrete]
// CHECK:STDOUT:   %char: type = class_type @Char [concrete]
// CHECK:STDOUT:   %Aggregates.elem.57d: type = unbound_element_type %Aggregates, %char [concrete]
// CHECK:STDOUT:   %str: type = class_type @String [concrete]
// CHECK:STDOUT:   %Aggregates.elem.32a: type = unbound_element_type %Aggregates, %str [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Aggregates.decl: type = class_decl @Aggregates [concrete = constants.%Aggregates] {} {}
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: class @Aggregates {
// CHECK:STDOUT:   %.loc7: %Aggregates.elem.431 = field_decl s, element0 [concrete]
// CHECK:STDOUT:   %.loc8: %Aggregates.elem.4f3 = field_decl t, element1 [concrete]
// CHECK:STDOUT:   %.loc9: %Aggregates.elem.9b1 = field_decl p, element2 [concrete]
// CHECK:STDOUT:   %.loc10: %Aggregates.elem.0bd = field_decl b, element3 [concrete]
// CHECK:STDOUT:   %.loc11: %Aggregates.elem.57d = field_decl c, element4 [concrete]
// CHECK:STDOUT:   %.loc12: %Aggregates.elem.32a = field_decl text, element5 [concrete]
// CHECK:STDOUT:   %.loc13: %Aggregates.elem.32a = field_decl literal_text, element6 [concrete]
// CHECK:STDOUT:   complete_type_witness = <error>
// CHECK:STDOUT:
// CHECK:STDOUT: !members:
// CHECK:STDOUT:   .Self = constants.%Aggregates
// CHECK:STDOUT:   .s = %.loc7
// CHECK:STDOUT:   .t = %.loc8
// CHECK:STDOUT:   .p = %.loc9
// CHECK:STDOUT:   .b = %.loc10
// CHECK:STDOUT:   .c = %.loc11
// CHECK:STDOUT:   .text = %.loc12
// CHECK:STDOUT:   .literal_text = %.loc13
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- optional_pointer_field.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %OptPtr: type = class_type @OptPtr [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %OptionalStorage.type: type = facet_type <@OptionalStorage> [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %ptr.d08: type = ptr_type %i32 [concrete]
// CHECK:STDOUT:   %Destroy.type: type = facet_type <@Destroy> [concrete]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %T.67d: type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %ptr.e8f: type = ptr_type %T.67d [symbolic]
// CHECK:STDOUT:   %Destroy.lookup_impl_witness.781: <witness> = lookup_impl_witness %ptr.e8f, @Destroy [symbolic]
// CHECK:STDOUT:   %Destroy.facet.e46: %Destroy.type = facet_value %ptr.e8f, (%Destroy.lookup_impl_witness.781) [symbolic]
// CHECK:STDOUT:   %MaybeUnformed.ddb: type = class_type @MaybeUnformed, @MaybeUnformed(%Destroy.facet.e46) [symbolic]
// CHECK:STDOUT:   %OptionalStorage.impl_witness.0ce: <witness> = impl_witness imports.%OptionalStorage.impl_witness_table.110, @ptr.as.OptionalStorage.impl(%i32) [concrete]
// CHECK:STDOUT:   %OptionalStorage.facet: %OptionalStorage.type = facet_value %ptr.d08, (%OptionalStorage.impl_witness.0ce) [concrete]
// CHECK:STDOUT:   %Optional.5b3: type = class_type @Optional, @Optional(%OptionalStorage.facet) [concrete]
// CHECK:STDOUT:   %OptPtr.elem.4da: type = unbound_element_type %OptPtr, %Optional.5b3 [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %pattern_type.f57: type = pattern_type %i64 [concrete]
// CHECK:STDOUT:   %OptPtr.elem.d1b: type = unbound_element_type %OptPtr, %i64 [concrete]
// CHECK:STDOUT:   %pattern_type.b17: type = pattern_type %OptPtr [concrete]
// CHECK:STDOUT:   %p.param_patt: %pattern_type.b17 = value_param_pattern [concrete]
// CHECK:STDOUT:   %p.patt: %pattern_type.b17 = wrapper_binding_pattern p, %p.param_patt [concrete]
// CHECK:STDOUT:   %.bc0: Core.Form = init_form %i64 [concrete]
// CHECK:STDOUT:   %return.param_patt.cfc: %pattern_type.f57 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.178: %pattern_type.f57 = return_slot_pattern %return.param_patt.cfc, %i64 [concrete]
// CHECK:STDOUT:   %CopyOptPtr.type: type = fn_type @CopyOptPtr [concrete]
// CHECK:STDOUT:   %CopyOptPtr: %CopyOptPtr.type = struct_value () [concrete]
// CHECK:STDOUT:   %q.patt: %pattern_type.b17 = ref_binding_pattern q [concrete]
// CHECK:STDOUT:   %q.var_patt: %pattern_type.b17 = var_pattern %q.patt [concrete]
// CHECK:STDOUT:   %Copy.Op.type: type = fn_type @Copy.Op [concrete]
// CHECK:STDOUT:   %Copy.Op: %Copy.Op.type = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.14b: <witness> = custom_witness (%Copy.Op), @Copy [concrete]
// CHECK:STDOUT:   %Copy.facet.a6a: %Copy.type = facet_value %OptPtr, (%custom_witness.14b) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.11e: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.a6a) [concrete]
// CHECK:STDOUT:   %.2c1: type = fn_type_with_self_type %Copy.WithSelf.Op.type.11e, %Copy.facet.a6a [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.8cc: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_64) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.494: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_64) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.d73: %Int.as.Copy.impl.Op.type.494 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet.4e9: %Copy.type = facet_value %i64, (%Copy.impl_witness.8cc) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.5c1: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.4e9) [concrete]
// CHECK:STDOUT:   %.826: type = fn_type_with_self_type %Copy.WithSelf.Op.type.5c1, %Copy.facet.4e9 [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.d73, @Int.as.Copy.impl.Op(%int_64) [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.2: type = fn_type @Destroy.Op.loc13 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.2: %Destroy.Op.type.1d8f74.2 = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.509: type = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @ptr.as.OptionalStorage.impl.%MaybeUnformed (constants.%MaybeUnformed.ddb)]
// CHECK:STDOUT:   %Core.import_ref.105 = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.c9a = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.a90 = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.306 = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.3e3 = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %OptionalStorage.impl_witness_table.110 = impl_witness_table (%Core.import_ref.509, %Core.import_ref.105, %Core.import_ref.c9a, %Core.import_ref.a90, %Core.import_ref.306, %Core.import_ref.3e3), @ptr.as.OptionalStorage.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %OptPtr.decl: type = class_decl @OptPtr [concrete = constants.%OptPtr] {} {}
// CHECK:STDOUT:   %CopyOptPtr.decl: %CopyOptPtr.type = fn_decl @CopyOptPtr [concrete = constants.%CopyOptPtr] {
// CHECK:STDOUT:     %p.param_patt: %pattern_type.b17 = value_param_pattern [concrete = constants.%p.param_patt]
// CHECK:STDOUT:     %p.patt: %pattern_type.b17 = wrapper_binding_pattern p, %p.param_patt [concrete = constants.%p.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.f57 = out_param_pattern [concrete = constants.%return.param_patt.cfc]
// CHECK:STDOUT:     %return.patt: %pattern_type.f57 = return_slot_pattern %return.param_patt, %i64 [concrete = constants.%return.patt.178]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i64: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:     %.loc12: Core.Form = init_form %i64 [concrete = constants.%.bc0]
// CHECK:STDOUT:     %p.param: %OptPtr = value_param call_param0
// CHECK:STDOUT:     %OptPtr.ref.loc12: type = name_ref OptPtr, file.%OptPtr.decl [concrete = constants.%OptPtr]
// CHECK:STDOUT:     %p: %OptPtr = wrapper_binding p, %p.param
// CHECK:STDOUT:     %return.param: ref %i64 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i64 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: class @OptPtr {
// CHECK:STDOUT:   %.loc8: %OptPtr.elem.4da = field_decl o, element0 [concrete]
// CHECK:STDOUT:   %.loc9: %OptPtr.elem.d1b = field_decl n, element1 [concrete]
// CHECK:STDOUT:   complete_type_witness = <error>
// CHECK:STDOUT:
// CHECK:STDOUT: !members:
// CHECK:STDOUT:   .Self = constants.%OptPtr
// CHECK:STDOUT:   .o = %.loc8
// CHECK:STDOUT:   .n = %.loc9
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @CopyOptPtr(%p.param: %OptPtr) -> out %return.param: %i64 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %q.var: ref %OptPtr = var_storage %q.var_patt
// CHECK:STDOUT:   %p.ref: %OptPtr = name_ref p, %p
// CHECK:STDOUT:   %impl.elem0.loc13: %.2c1 = impl_witness_access constants.%custom_witness.14b, element0 [concrete = constants.%Copy.Op]
// CHECK:STDOUT:   %bound_method.loc13: <bound method> = bound_method %p.ref, %impl.elem0.loc13
// CHECK:STDOUT:   %.loc13: ref %OptPtr = splice_block %q.var {}
// CHECK:STDOUT:   %Copy.Op.call: init %OptPtr to %.loc13 = call %bound_method.loc13(%p.ref)
// CHECK:STDOUT:   assign %q.var, %Copy.Op.call
// CHECK:STDOUT:   %OptPtr.ref.loc13: type = name_ref OptPtr, file.%OptPtr.decl [concrete = constants.%OptPtr]
// CHECK:STDOUT:   %q: ref %OptPtr = wrapper_binding q, %q.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %q.patt: %pattern_type.b17 = ref_binding_pattern q [concrete = constants.%q.patt]
// CHECK:STDOUT:     %q.var_patt: %pattern_type.b17 = var_pattern %q.patt [concrete = constants.%q.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %q.ref: ref %OptPtr = name_ref q, %q
// CHECK:STDOUT:   %n.ref: %OptPtr.elem.d1b = name_ref n, @OptPtr.%.loc9 [concrete = @OptPtr.%.loc9]
// CHECK:STDOUT:   %.loc14_11.1: ref %i64 = class_element_access %q.ref, element1
// CHECK:STDOUT:   %.loc14_11.2: %i64 = acquire_value %.loc14_11.1
// CHECK:STDOUT:   %impl.elem0.loc14: %.826 = impl_witness_access constants.%Copy.impl_witness.8cc, element0 [concrete = constants.%Int.as.Copy.impl.Op.d73]
// CHECK:STDOUT:   %bound_method.loc14_11.1: <bound method> = bound_method %.loc14_11.2, %impl.elem0.loc14
// CHECK:STDOUT:   %specific_fn: <specific function> = specific_function %impl.elem0.loc14, @Int.as.Copy.impl.Op(constants.%int_64) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc14_11.2: <bound method> = bound_method %.loc14_11.2, %specific_fn
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i64 = call %bound_method.loc14_11.2(%.loc14_11.2)
// CHECK:STDOUT:   %Destroy.Op.bound: <bound method> = bound_method %q.var, constants.%Destroy.Op.1a2547.2
// CHECK:STDOUT:   %Destroy.Op.call: init %empty_tuple.type = call %Destroy.Op.bound(%q.var)
// CHECK:STDOUT:   return %Int.as.Copy.impl.Op.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc13(%self.param: ref %OptPtr) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
