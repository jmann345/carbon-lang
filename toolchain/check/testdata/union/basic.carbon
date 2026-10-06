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

// An `impl` is a permitted union member, "as in classes": `extend impl as`
// makes the interface's members visible as members of the union
// (check/testdata/impl/extend_impl.carbon), which is what `u.Get()` needs; a
// plain `impl as I` is reached through the interface (`u.(I.Get)()`).
//@dump-sem-ir-begin
union WithImpl {
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

// CHECK:STDOUT: --- declare_and_access.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
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
// CHECK:STDOUT:   %.e9a: type = custom_layout_type {size=4, align=4, .word@0: %i32, .bytes@0: %array_type} [concrete]
// CHECK:STDOUT:   %complete_type.57b: <witness> = complete_type_witness %.e9a [concrete]
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
// CHECK:STDOUT:   %field_decl.loc5: %IntOrBytes.elem.a3f = field_decl word, element0, %i32 in [concrete] {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %field_decl.loc6: %IntOrBytes.elem.ff6 = field_decl bytes, element1, %array_type in [concrete] {
// CHECK:STDOUT:     %i8: type = type_literal constants.%i8 [concrete = constants.%i8]
// CHECK:STDOUT:     %int_4: Core.IntLiteral = int_value 4 [concrete = constants.%int_4]
// CHECK:STDOUT:     %array_type: type = array_type %int_4, %i8 [concrete = constants.%array_type]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %.loc7: type = custom_layout_type {size=4, align=4, .word@0: %i32, .bytes@0: %array_type} [concrete = constants.%.e9a]
// CHECK:STDOUT:   %complete_type: <witness> = complete_type_witness %.loc7 [concrete = constants.%complete_type.57b]
// CHECK:STDOUT:   complete_type_witness = %complete_type
// CHECK:STDOUT:
// CHECK:STDOUT: !members:
// CHECK:STDOUT:   .Self = constants.%IntOrBytes
// CHECK:STDOUT:   .word = %field_decl.loc5
// CHECK:STDOUT:   .bytes = %field_decl.loc6
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Read(%u.param: %IntOrBytes) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %u.ref: %IntOrBytes = name_ref u, %u
// CHECK:STDOUT:   %word.ref: %IntOrBytes.elem.a3f = name_ref word, @IntOrBytes.%field_decl.loc5 [concrete = @IntOrBytes.%field_decl.loc5]
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
// CHECK:STDOUT:   %word.ref: %IntOrBytes.elem.a3f = name_ref word, @IntOrBytes.%field_decl.loc5 [concrete = @IntOrBytes.%field_decl.loc5]
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
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %IntOrBytes: type = class_type @IntOrBytes [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %N.fe9: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %IntOrBytes.elem.a3f: type = unbound_element_type %IntOrBytes, %i32 [concrete]
// CHECK:STDOUT:   %int_8: Core.IntLiteral = int_value 8 [concrete]
// CHECK:STDOUT:   %i8: type = class_type @Int, @Int(%int_8) [concrete]
// CHECK:STDOUT:   %int_4: Core.IntLiteral = int_value 4 [concrete]
// CHECK:STDOUT:   %array_type.69d: type = array_type %int_4, %i8 [concrete]
// CHECK:STDOUT:   %pattern_type.9c7: type = pattern_type %array_type.69d [concrete]
// CHECK:STDOUT:   %IntOrBytes.elem.ff6: type = unbound_element_type %IntOrBytes, %array_type.69d [concrete]
// CHECK:STDOUT:   %.e9a: type = custom_layout_type {size=4, align=4, .word@0: %i32, .bytes@0: %array_type.69d} [concrete]
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
// CHECK:STDOUT:   %self.param_patt.705: %pattern_type.6b6 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.70d: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt.705 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc14_3.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.1: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.1: type = fn_type @Destroy.WithSelf.Op.loc14_3.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.1: %Destroy.WithSelf.Op.type.ef016f.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.1: type = fn_type @Destroy.WithSelf.SelfDestruct.loc14_3.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.1: %Destroy.WithSelf.SelfDestruct.type.fbceb5.1 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.0cf: type = pattern_type %i8 [concrete]
// CHECK:STDOUT:   %self.param_patt.6c8: %pattern_type.0cf = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.136: %pattern_type.0cf = wrapper_binding_pattern self, %self.param_patt.6c8 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc14_3.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.2: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.2: type = fn_type @Destroy.WithSelf.Op.loc14_3.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.2: %Destroy.WithSelf.Op.type.ef016f.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.2: type = fn_type @Destroy.WithSelf.SelfDestruct.loc14_3.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.2: %Destroy.WithSelf.SelfDestruct.type.fbceb5.2 = struct_value () [concrete]
// CHECK:STDOUT:   %self.param_patt.078: %pattern_type.9c7 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.d53: %pattern_type.9c7 = wrapper_binding_pattern self, %self.param_patt.078 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc14_3.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.3: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3 = struct_value () [concrete]
// CHECK:STDOUT:   %int_3: Core.IntLiteral = int_value 3 [concrete]
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.3: type = fn_type @Destroy.WithSelf.Op.loc14_3.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.3: %Destroy.WithSelf.Op.type.ef016f.3 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.3: type = fn_type @Destroy.WithSelf.SelfDestruct.loc14_3.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.3: %Destroy.WithSelf.SelfDestruct.type.fbceb5.3 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.cf0: type = pattern_type %.e9a [concrete]
// CHECK:STDOUT:   %self.param_patt.bc5: %pattern_type.cf0 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.928: %pattern_type.cf0 = wrapper_binding_pattern self, %self.param_patt.bc5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc14_3.4 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.4: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.4: type = fn_type @Destroy.WithSelf.Op.loc14_3.4 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.4: %Destroy.WithSelf.Op.type.ef016f.4 = struct_value () [concrete]
// CHECK:STDOUT:   %self.param_patt.453: %pattern_type.970 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.e2e: %pattern_type.970 = wrapper_binding_pattern self, %self.param_patt.453 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.5: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc14_3.5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.5: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.5 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.5: type = fn_type @Destroy.WithSelf.Op.loc14_3.5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.5: %Destroy.WithSelf.Op.type.ef016f.5 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.5: type = fn_type @Destroy.WithSelf.SelfDestruct.loc14_3.5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.5: %Destroy.WithSelf.SelfDestruct.type.fbceb5.5 = struct_value () [concrete]
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
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.1: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc14_3.1 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.1] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6b6 = ref_param_pattern [concrete = constants.%self.param_patt.705]
// CHECK:STDOUT:     %self.patt: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.70d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i32 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i32 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.1: %Destroy.WithSelf.Op.type.ef016f.1 = fn_decl @Destroy.WithSelf.Op.loc14_3.1 [concrete = constants.%Destroy.WithSelf.Op.403171.1] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6b6 = ref_param_pattern [concrete = constants.%self.param_patt.705]
// CHECK:STDOUT:     %self.patt: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.70d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i32 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i32 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.2: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc14_3.2 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.2] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.0cf = ref_param_pattern [concrete = constants.%self.param_patt.6c8]
// CHECK:STDOUT:     %self.patt: %pattern_type.0cf = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.136]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i8 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i8 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.2: %Destroy.WithSelf.Op.type.ef016f.2 = fn_decl @Destroy.WithSelf.Op.loc14_3.2 [concrete = constants.%Destroy.WithSelf.Op.403171.2] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.0cf = ref_param_pattern [concrete = constants.%self.param_patt.6c8]
// CHECK:STDOUT:     %self.patt: %pattern_type.0cf = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.136]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i8 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i8 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.3: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc14_3.3 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.3] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.9c7 = ref_param_pattern [concrete = constants.%self.param_patt.078]
// CHECK:STDOUT:     %self.patt: %pattern_type.9c7 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.d53]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %array_type.69d = ref_param call_param0
// CHECK:STDOUT:     %self: ref %array_type.69d = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.3: %Destroy.WithSelf.Op.type.ef016f.3 = fn_decl @Destroy.WithSelf.Op.loc14_3.3 [concrete = constants.%Destroy.WithSelf.Op.403171.3] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.9c7 = ref_param_pattern [concrete = constants.%self.param_patt.078]
// CHECK:STDOUT:     %self.patt: %pattern_type.9c7 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.d53]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %array_type.69d = ref_param call_param0
// CHECK:STDOUT:     %self: ref %array_type.69d = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.4: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc14_3.4 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.4] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.cf0 = ref_param_pattern [concrete = constants.%self.param_patt.bc5]
// CHECK:STDOUT:     %self.patt: %pattern_type.cf0 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.928]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %.e9a = ref_param call_param0
// CHECK:STDOUT:     %self: ref %.e9a = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.4: %Destroy.WithSelf.Op.type.ef016f.4 = fn_decl @Destroy.WithSelf.Op.loc14_3.4 [concrete = constants.%Destroy.WithSelf.Op.403171.4] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.cf0 = ref_param_pattern [concrete = constants.%self.param_patt.bc5]
// CHECK:STDOUT:     %self.patt: %pattern_type.cf0 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.928]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %.e9a = ref_param call_param0
// CHECK:STDOUT:     %self: ref %.e9a = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.5: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.5 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc14_3.5 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.5] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.970 = ref_param_pattern [concrete = constants.%self.param_patt.453]
// CHECK:STDOUT:     %self.patt: %pattern_type.970 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.e2e]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %IntOrBytes = ref_param call_param0
// CHECK:STDOUT:     %self: ref %IntOrBytes = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.5: %Destroy.WithSelf.Op.type.ef016f.5 = fn_decl @Destroy.WithSelf.Op.loc14_3.5 [concrete = constants.%Destroy.WithSelf.Op.403171.5] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.970 = ref_param_pattern [concrete = constants.%self.param_patt.453]
// CHECK:STDOUT:     %self.patt: %pattern_type.970 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.e2e]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %IntOrBytes = ref_param call_param0
// CHECK:STDOUT:     %self: ref %IntOrBytes = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
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
// CHECK:STDOUT:   %word.ref.loc15: %IntOrBytes.elem.a3f = name_ref word, @IntOrBytes.%field_decl.loc4 [concrete = @IntOrBytes.%field_decl.loc4]
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
// CHECK:STDOUT:   %word.ref.loc16: %IntOrBytes.elem.a3f = name_ref word, @IntOrBytes.%field_decl.loc4 [concrete = @IntOrBytes.%field_decl.loc4]
// CHECK:STDOUT:   %.loc16_11.1: ref %i32 = class_element_access %u.ref.loc16, element0
// CHECK:STDOUT:   %.loc16_11.2: %i32 = acquire_value %.loc16_11.1
// CHECK:STDOUT:   %impl.elem0.loc16: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc16_11.1: <bound method> = bound_method %.loc16_11.2, %impl.elem0.loc16
// CHECK:STDOUT:   %specific_fn.loc16: <specific function> = specific_function %impl.elem0.loc16, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc16_11.2: <bound method> = bound_method %.loc16_11.2, %specific_fn.loc16
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc16_11.2(%.loc16_11.2)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound: <bound method> = bound_method %u.var, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.5
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound(%u.var)
// CHECK:STDOUT:   return %Int.as.Copy.impl.Op.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc14_3.1(%self.param: ref %i32) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc14_3.1(%self.param: ref %i32) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc14_3.1(%self.param: ref %i32) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.1(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.1(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc14_3.2(%self.param: ref %i8) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc14_3.2(%self.param: ref %i8) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc14_3.2(%self.param: ref %i8) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.2(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.2(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc14_3.3(%self.param: ref %array_type.69d) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %int_3: Core.IntLiteral = int_value 3 [concrete = constants.%int_3]
// CHECK:STDOUT:   %.loc14_3.1: ref %i8 = array_index %self.param, %int_3
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc14_3.1: <bound method> = bound_method %.loc14_3.1, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc14_3.1: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc14_3.1(%.loc14_3.1)
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2]
// CHECK:STDOUT:   %.loc14_3.2: ref %i8 = array_index %self.param, %int_2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc14_3.2: <bound method> = bound_method %.loc14_3.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc14_3.2: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc14_3.2(%.loc14_3.2)
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1]
// CHECK:STDOUT:   %.loc14_3.3: ref %i8 = array_index %self.param, %int_1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc14_3.3: <bound method> = bound_method %.loc14_3.3, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc14_3.3: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc14_3.3(%.loc14_3.3)
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0]
// CHECK:STDOUT:   %.loc14_3.4: ref %i8 = array_index %self.param, %int_0
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc14_3.4: <bound method> = bound_method %.loc14_3.4, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc14_3.4: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc14_3.4(%.loc14_3.4)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc14_3.3(%self.param: ref %array_type.69d) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc14_3.3(%self.param: ref %array_type.69d) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.3(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.3(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc14_3.4(%self.param: ref %.e9a) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc14_3.4(%self.param: ref %.e9a) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc14_3.4(%self.param: ref %.e9a) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.4(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.4(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc14_3.5(%self.param: ref %IntOrBytes) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %bytes.ref: %IntOrBytes.elem.ff6 = name_ref bytes, @IntOrBytes.%field_decl.loc5 [concrete = @IntOrBytes.%field_decl.loc5]
// CHECK:STDOUT:   %.loc14_3.1: ref %array_type.69d = class_element_access %self.param, element1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc14_3.1: <bound method> = bound_method %.loc14_3.1, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.3
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc14_3.1: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc14_3.1(%.loc14_3.1)
// CHECK:STDOUT:   %word.ref: %IntOrBytes.elem.a3f = name_ref word, @IntOrBytes.%field_decl.loc4 [concrete = @IntOrBytes.%field_decl.loc4]
// CHECK:STDOUT:   %.loc14_3.2: ref %i32 = class_element_access %self.param, element0
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc14_3.2: <bound method> = bound_method %.loc14_3.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc14_3.2: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc14_3.2(%.loc14_3.2)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc14_3.5(%self.param: ref %IntOrBytes) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc14_3.5(%self.param: ref %IntOrBytes) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.5(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.5(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- designated_init.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %IntOrBytes: type = class_type @IntOrBytes [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %IntOrBytes.elem.a3f: type = unbound_element_type %IntOrBytes, %i32 [concrete]
// CHECK:STDOUT:   %int_8: Core.IntLiteral = int_value 8 [concrete]
// CHECK:STDOUT:   %i8: type = class_type @Int, @Int(%int_8) [concrete]
// CHECK:STDOUT:   %int_4.0c1: Core.IntLiteral = int_value 4 [concrete]
// CHECK:STDOUT:   %array_type: type = array_type %int_4.0c1, %i8 [concrete]
// CHECK:STDOUT:   %pattern_type.9c7: type = pattern_type %array_type [concrete]
// CHECK:STDOUT:   %IntOrBytes.elem.ff6: type = unbound_element_type %IntOrBytes, %array_type [concrete]
// CHECK:STDOUT:   %.e9a: type = custom_layout_type {size=4, align=4, .word@0: %i32, .bytes@0: %array_type} [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %DesignatedInit.type: type = fn_type @DesignatedInit [concrete]
// CHECK:STDOUT:   %DesignatedInit: %DesignatedInit.type = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.970: type = pattern_type %IntOrBytes [concrete]
// CHECK:STDOUT:   %v.patt: %pattern_type.970 = ref_binding_pattern v [concrete]
// CHECK:STDOUT:   %v.var_patt: %pattern_type.970 = var_pattern %v.patt [concrete]
// CHECK:STDOUT:   %int_5.64b: Core.IntLiteral = int_value 5 [concrete]
// CHECK:STDOUT:   %struct_type.word: type = struct_type {.word: Core.IntLiteral} [concrete]
// CHECK:STDOUT:   %struct.64b: %struct_type.word = struct_value (%int_5.64b) [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %To.fe9: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %From.fe9: Core.IntLiteral = symbolic_binding From, 0 [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.48f: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet.48f [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.f6c: <bound method> = bound_method %int_5.64b, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.c9d: <bound method> = bound_method %int_5.64b, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_5.eef: %i32 = int_value 5 [concrete]
// CHECK:STDOUT:   %b.patt: %pattern_type.970 = ref_binding_pattern b [concrete]
// CHECK:STDOUT:   %b.var_patt: %pattern_type.970 = var_pattern %b.patt [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %int_2.ecc: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %int_3.1ba: Core.IntLiteral = int_value 3 [concrete]
// CHECK:STDOUT:   %tuple.type: type = tuple_type (Core.IntLiteral, Core.IntLiteral, Core.IntLiteral, Core.IntLiteral) [concrete]
// CHECK:STDOUT:   %tuple: %tuple.type = tuple_value (%int_1.5b8, %int_2.ecc, %int_3.1ba, %int_4.0c1) [concrete]
// CHECK:STDOUT:   %struct_type.bytes.ed8: type = struct_type {.bytes: %tuple.type} [concrete]
// CHECK:STDOUT:   %struct.c89: %struct_type.bytes.ed8 = struct_value (%tuple) [concrete]
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.869: type = facet_type <@ImplicitAs, @ImplicitAs(%i8)> [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.1b5: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.f5b: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.868: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.f5b = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.41f: %ImplicitAs.type.869 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.1b5) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.999: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i8, %ImplicitAs.facet.41f) [concrete]
// CHECK:STDOUT:   %.5d4: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.999, %ImplicitAs.facet.41f [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.0ab: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.868 [concrete]
// CHECK:STDOUT:   %pattern_type.0cf: type = pattern_type %i8 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.cda: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.868, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_8) [concrete]
// CHECK:STDOUT:   %bound_method.272: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.cda [concrete]
// CHECK:STDOUT:   %int_1.f1e: %i8 = int_value 1 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.1e4: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.868 [concrete]
// CHECK:STDOUT:   %bound_method.b43: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.cda [concrete]
// CHECK:STDOUT:   %int_2.496: %i8 = int_value 2 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.84c: <bound method> = bound_method %int_3.1ba, %Core.IntLiteral.as.ImplicitAs.impl.Convert.868 [concrete]
// CHECK:STDOUT:   %bound_method.901: <bound method> = bound_method %int_3.1ba, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.cda [concrete]
// CHECK:STDOUT:   %int_3.c76: %i8 = int_value 3 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.023: <bound method> = bound_method %int_4.0c1, %Core.IntLiteral.as.ImplicitAs.impl.Convert.868 [concrete]
// CHECK:STDOUT:   %bound_method.87f: <bound method> = bound_method %int_4.0c1, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.cda [concrete]
// CHECK:STDOUT:   %int_4.884: %i8 = int_value 4 [concrete]
// CHECK:STDOUT:   %array: %array_type = tuple_value (%int_1.f1e, %int_2.496, %int_3.c76, %int_4.884) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.485: <bound method> = bound_method %int_3.1ba, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.763: <bound method> = bound_method %int_3.1ba, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
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
// CHECK:STDOUT:   %self.param_patt.705: %pattern_type.6b6 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.70d: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt.705 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc15_3.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.1: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.1: type = fn_type @Destroy.WithSelf.Op.loc15_3.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.1: %Destroy.WithSelf.Op.type.ef016f.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.1: type = fn_type @Destroy.WithSelf.SelfDestruct.loc15_3.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.1: %Destroy.WithSelf.SelfDestruct.type.fbceb5.1 = struct_value () [concrete]
// CHECK:STDOUT:   %self.param_patt.6c8: %pattern_type.0cf = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.136: %pattern_type.0cf = wrapper_binding_pattern self, %self.param_patt.6c8 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc15_3.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.2: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.2: type = fn_type @Destroy.WithSelf.Op.loc15_3.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.2: %Destroy.WithSelf.Op.type.ef016f.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.2: type = fn_type @Destroy.WithSelf.SelfDestruct.loc15_3.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.2: %Destroy.WithSelf.SelfDestruct.type.fbceb5.2 = struct_value () [concrete]
// CHECK:STDOUT:   %self.param_patt.078: %pattern_type.9c7 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.d53: %pattern_type.9c7 = wrapper_binding_pattern self, %self.param_patt.078 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc15_3.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.3: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.3: type = fn_type @Destroy.WithSelf.Op.loc15_3.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.3: %Destroy.WithSelf.Op.type.ef016f.3 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.3: type = fn_type @Destroy.WithSelf.SelfDestruct.loc15_3.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.3: %Destroy.WithSelf.SelfDestruct.type.fbceb5.3 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.cf0: type = pattern_type %.e9a [concrete]
// CHECK:STDOUT:   %self.param_patt.bc5: %pattern_type.cf0 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.928: %pattern_type.cf0 = wrapper_binding_pattern self, %self.param_patt.bc5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc15_3.4 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.4: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.4: type = fn_type @Destroy.WithSelf.Op.loc15_3.4 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.4: %Destroy.WithSelf.Op.type.ef016f.4 = struct_value () [concrete]
// CHECK:STDOUT:   %self.param_patt.453: %pattern_type.970 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.e2e: %pattern_type.970 = wrapper_binding_pattern self, %self.param_patt.453 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.5: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc15_3.5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.5: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.5 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.5: type = fn_type @Destroy.WithSelf.Op.loc15_3.5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.5: %Destroy.WithSelf.Op.type.ef016f.5 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.5: type = fn_type @Destroy.WithSelf.SelfDestruct.loc15_3.5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.5: %Destroy.WithSelf.SelfDestruct.type.fbceb5.5 = struct_value () [concrete]
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
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.1: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc15_3.1 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.1] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6b6 = ref_param_pattern [concrete = constants.%self.param_patt.705]
// CHECK:STDOUT:     %self.patt: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.70d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i32 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i32 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.1: %Destroy.WithSelf.Op.type.ef016f.1 = fn_decl @Destroy.WithSelf.Op.loc15_3.1 [concrete = constants.%Destroy.WithSelf.Op.403171.1] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6b6 = ref_param_pattern [concrete = constants.%self.param_patt.705]
// CHECK:STDOUT:     %self.patt: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.70d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i32 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i32 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.2: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc15_3.2 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.2] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.0cf = ref_param_pattern [concrete = constants.%self.param_patt.6c8]
// CHECK:STDOUT:     %self.patt: %pattern_type.0cf = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.136]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i8 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i8 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.2: %Destroy.WithSelf.Op.type.ef016f.2 = fn_decl @Destroy.WithSelf.Op.loc15_3.2 [concrete = constants.%Destroy.WithSelf.Op.403171.2] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.0cf = ref_param_pattern [concrete = constants.%self.param_patt.6c8]
// CHECK:STDOUT:     %self.patt: %pattern_type.0cf = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.136]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i8 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i8 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.3: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc15_3.3 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.3] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.9c7 = ref_param_pattern [concrete = constants.%self.param_patt.078]
// CHECK:STDOUT:     %self.patt: %pattern_type.9c7 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.d53]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %array_type = ref_param call_param0
// CHECK:STDOUT:     %self: ref %array_type = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.3: %Destroy.WithSelf.Op.type.ef016f.3 = fn_decl @Destroy.WithSelf.Op.loc15_3.3 [concrete = constants.%Destroy.WithSelf.Op.403171.3] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.9c7 = ref_param_pattern [concrete = constants.%self.param_patt.078]
// CHECK:STDOUT:     %self.patt: %pattern_type.9c7 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.d53]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %array_type = ref_param call_param0
// CHECK:STDOUT:     %self: ref %array_type = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.4: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc15_3.4 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.4] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.cf0 = ref_param_pattern [concrete = constants.%self.param_patt.bc5]
// CHECK:STDOUT:     %self.patt: %pattern_type.cf0 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.928]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %.e9a = ref_param call_param0
// CHECK:STDOUT:     %self: ref %.e9a = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.4: %Destroy.WithSelf.Op.type.ef016f.4 = fn_decl @Destroy.WithSelf.Op.loc15_3.4 [concrete = constants.%Destroy.WithSelf.Op.403171.4] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.cf0 = ref_param_pattern [concrete = constants.%self.param_patt.bc5]
// CHECK:STDOUT:     %self.patt: %pattern_type.cf0 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.928]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %.e9a = ref_param call_param0
// CHECK:STDOUT:     %self: ref %.e9a = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.5: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.5 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc15_3.5 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.5] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.970 = ref_param_pattern [concrete = constants.%self.param_patt.453]
// CHECK:STDOUT:     %self.patt: %pattern_type.970 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.e2e]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %IntOrBytes = ref_param call_param0
// CHECK:STDOUT:     %self: ref %IntOrBytes = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.5: %Destroy.WithSelf.Op.type.ef016f.5 = fn_decl @Destroy.WithSelf.Op.loc15_3.5 [concrete = constants.%Destroy.WithSelf.Op.403171.5] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.970 = ref_param_pattern [concrete = constants.%self.param_patt.453]
// CHECK:STDOUT:     %self.patt: %pattern_type.970 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.e2e]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %IntOrBytes = ref_param call_param0
// CHECK:STDOUT:     %self: ref %IntOrBytes = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
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
// CHECK:STDOUT:   %int_5: Core.IntLiteral = int_value 5 [concrete = constants.%int_5.64b]
// CHECK:STDOUT:   %.loc14_33.1: %struct_type.word = struct_literal (%int_5) [concrete = constants.%struct.64b]
// CHECK:STDOUT:   %impl.elem0.loc14: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc14_33.1: <bound method> = bound_method %int_5, %impl.elem0.loc14 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.f6c]
// CHECK:STDOUT:   %specific_fn.loc14: <specific function> = specific_function %impl.elem0.loc14, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc14_33.2: <bound method> = bound_method %int_5, %specific_fn.loc14 [concrete = constants.%bound_method.c9d]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14: init %i32 = call %bound_method.loc14_33.2(%int_5) [concrete = constants.%int_5.eef]
// CHECK:STDOUT:   %.loc14_33.2: init %i32 = converted %int_5, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14 [concrete = constants.%int_5.eef]
// CHECK:STDOUT:   %.loc14_33.3: ref %i32 = class_element_access %v.var, element0
// CHECK:STDOUT:   %.loc14_33.4: init %i32 to %.loc14_33.3 = in_place_init %.loc14_33.2 [concrete = constants.%int_5.eef]
// CHECK:STDOUT:   %.loc14_33.5: init %IntOrBytes to %v.var = class_init (%.loc14_33.4)
// CHECK:STDOUT:   %.loc14_3: init %IntOrBytes = converted %.loc14_33.1, %.loc14_33.5
// CHECK:STDOUT:   assign %v.var, %.loc14_3
// CHECK:STDOUT:   %IntOrBytes.ref.loc14: type = name_ref IntOrBytes, file.%IntOrBytes.decl [concrete = constants.%IntOrBytes]
// CHECK:STDOUT:   %v: ref %IntOrBytes = wrapper_binding v, %v.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %v.patt: %pattern_type.970 = ref_binding_pattern v [concrete = constants.%v.patt]
// CHECK:STDOUT:     %v.var_patt: %pattern_type.970 = var_pattern %v.patt [concrete = constants.%v.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %b.var: ref %IntOrBytes = var_storage %b.var_patt
// CHECK:STDOUT:   %int_1.loc15_34: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %int_2.loc15_37: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:   %int_3.loc15_40: Core.IntLiteral = int_value 3 [concrete = constants.%int_3.1ba]
// CHECK:STDOUT:   %int_4: Core.IntLiteral = int_value 4 [concrete = constants.%int_4.0c1]
// CHECK:STDOUT:   %.loc15_44.1: %tuple.type = tuple_literal (%int_1.loc15_34, %int_2.loc15_37, %int_3.loc15_40, %int_4) [concrete = constants.%tuple]
// CHECK:STDOUT:   %.loc15_45.1: %struct_type.bytes.ed8 = struct_literal (%.loc15_44.1) [concrete = constants.%struct.c89]
// CHECK:STDOUT:   %impl.elem0.loc15_44.1: %.5d4 = impl_witness_access constants.%ImplicitAs.impl_witness.1b5, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.868]
// CHECK:STDOUT:   %bound_method.loc15_44.1: <bound method> = bound_method %int_1.loc15_34, %impl.elem0.loc15_44.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.0ab]
// CHECK:STDOUT:   %specific_fn.loc15_44.1: <specific function> = specific_function %impl.elem0.loc15_44.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.cda]
// CHECK:STDOUT:   %bound_method.loc15_44.2: <bound method> = bound_method %int_1.loc15_34, %specific_fn.loc15_44.1 [concrete = constants.%bound_method.272]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc15_44.1: init %i8 = call %bound_method.loc15_44.2(%int_1.loc15_34) [concrete = constants.%int_1.f1e]
// CHECK:STDOUT:   %.loc15_44.2: init %i8 = converted %int_1.loc15_34, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc15_44.1 [concrete = constants.%int_1.f1e]
// CHECK:STDOUT:   %.loc15_45.2: ref %array_type = class_element_access %b.var, element1
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0]
// CHECK:STDOUT:   %.loc15_44.3: ref %i8 = array_index %.loc15_45.2, %int_0
// CHECK:STDOUT:   %.loc15_44.4: init %i8 to %.loc15_44.3 = in_place_init %.loc15_44.2 [concrete = constants.%int_1.f1e]
// CHECK:STDOUT:   %impl.elem0.loc15_44.2: %.5d4 = impl_witness_access constants.%ImplicitAs.impl_witness.1b5, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.868]
// CHECK:STDOUT:   %bound_method.loc15_44.3: <bound method> = bound_method %int_2.loc15_37, %impl.elem0.loc15_44.2 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.1e4]
// CHECK:STDOUT:   %specific_fn.loc15_44.2: <specific function> = specific_function %impl.elem0.loc15_44.2, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.cda]
// CHECK:STDOUT:   %bound_method.loc15_44.4: <bound method> = bound_method %int_2.loc15_37, %specific_fn.loc15_44.2 [concrete = constants.%bound_method.b43]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc15_44.2: init %i8 = call %bound_method.loc15_44.4(%int_2.loc15_37) [concrete = constants.%int_2.496]
// CHECK:STDOUT:   %.loc15_44.5: init %i8 = converted %int_2.loc15_37, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc15_44.2 [concrete = constants.%int_2.496]
// CHECK:STDOUT:   %int_1.loc15_44: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %.loc15_44.6: ref %i8 = array_index %.loc15_45.2, %int_1.loc15_44
// CHECK:STDOUT:   %.loc15_44.7: init %i8 to %.loc15_44.6 = in_place_init %.loc15_44.5 [concrete = constants.%int_2.496]
// CHECK:STDOUT:   %impl.elem0.loc15_44.3: %.5d4 = impl_witness_access constants.%ImplicitAs.impl_witness.1b5, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.868]
// CHECK:STDOUT:   %bound_method.loc15_44.5: <bound method> = bound_method %int_3.loc15_40, %impl.elem0.loc15_44.3 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.84c]
// CHECK:STDOUT:   %specific_fn.loc15_44.3: <specific function> = specific_function %impl.elem0.loc15_44.3, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.cda]
// CHECK:STDOUT:   %bound_method.loc15_44.6: <bound method> = bound_method %int_3.loc15_40, %specific_fn.loc15_44.3 [concrete = constants.%bound_method.901]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc15_44.3: init %i8 = call %bound_method.loc15_44.6(%int_3.loc15_40) [concrete = constants.%int_3.c76]
// CHECK:STDOUT:   %.loc15_44.8: init %i8 = converted %int_3.loc15_40, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc15_44.3 [concrete = constants.%int_3.c76]
// CHECK:STDOUT:   %int_2.loc15_44: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:   %.loc15_44.9: ref %i8 = array_index %.loc15_45.2, %int_2.loc15_44
// CHECK:STDOUT:   %.loc15_44.10: init %i8 to %.loc15_44.9 = in_place_init %.loc15_44.8 [concrete = constants.%int_3.c76]
// CHECK:STDOUT:   %impl.elem0.loc15_44.4: %.5d4 = impl_witness_access constants.%ImplicitAs.impl_witness.1b5, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.868]
// CHECK:STDOUT:   %bound_method.loc15_44.7: <bound method> = bound_method %int_4, %impl.elem0.loc15_44.4 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.023]
// CHECK:STDOUT:   %specific_fn.loc15_44.4: <specific function> = specific_function %impl.elem0.loc15_44.4, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.cda]
// CHECK:STDOUT:   %bound_method.loc15_44.8: <bound method> = bound_method %int_4, %specific_fn.loc15_44.4 [concrete = constants.%bound_method.87f]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc15_44.4: init %i8 = call %bound_method.loc15_44.8(%int_4) [concrete = constants.%int_4.884]
// CHECK:STDOUT:   %.loc15_44.11: init %i8 = converted %int_4, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc15_44.4 [concrete = constants.%int_4.884]
// CHECK:STDOUT:   %int_3.loc15_44: Core.IntLiteral = int_value 3 [concrete = constants.%int_3.1ba]
// CHECK:STDOUT:   %.loc15_44.12: ref %i8 = array_index %.loc15_45.2, %int_3.loc15_44
// CHECK:STDOUT:   %.loc15_44.13: init %i8 to %.loc15_44.12 = in_place_init %.loc15_44.11 [concrete = constants.%int_4.884]
// CHECK:STDOUT:   %.loc15_44.14: init %array_type to %.loc15_45.2 = array_init (%.loc15_44.4, %.loc15_44.7, %.loc15_44.10, %.loc15_44.13) [concrete = constants.%array]
// CHECK:STDOUT:   %.loc15_45.3: init %array_type = converted %.loc15_44.1, %.loc15_44.14 [concrete = constants.%array]
// CHECK:STDOUT:   %.loc15_45.4: init %IntOrBytes to %b.var = class_init (%.loc15_45.3)
// CHECK:STDOUT:   %.loc15_3: init %IntOrBytes = converted %.loc15_45.1, %.loc15_45.4
// CHECK:STDOUT:   assign %b.var, %.loc15_3
// CHECK:STDOUT:   %IntOrBytes.ref.loc15: type = name_ref IntOrBytes, file.%IntOrBytes.decl [concrete = constants.%IntOrBytes]
// CHECK:STDOUT:   %b: ref %IntOrBytes = wrapper_binding b, %b.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %b.patt: %pattern_type.970 = ref_binding_pattern b [concrete = constants.%b.patt]
// CHECK:STDOUT:     %b.var_patt: %pattern_type.970 = var_pattern %b.patt [concrete = constants.%b.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %v.ref: ref %IntOrBytes = name_ref v, %v
// CHECK:STDOUT:   %word.ref: %IntOrBytes.elem.a3f = name_ref word, @IntOrBytes.%field_decl.loc4 [concrete = @IntOrBytes.%field_decl.loc4]
// CHECK:STDOUT:   %.loc16_11.1: ref %i32 = class_element_access %v.ref, element0
// CHECK:STDOUT:   %b.ref: ref %IntOrBytes = name_ref b, %b
// CHECK:STDOUT:   %bytes.ref: %IntOrBytes.elem.ff6 = name_ref bytes, @IntOrBytes.%field_decl.loc5 [concrete = @IntOrBytes.%field_decl.loc5]
// CHECK:STDOUT:   %.loc16_21: ref %array_type = class_element_access %b.ref, element1
// CHECK:STDOUT:   %int_3.loc16: Core.IntLiteral = int_value 3 [concrete = constants.%int_3.1ba]
// CHECK:STDOUT:   %impl.elem0.loc16_28: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc16_28.1: <bound method> = bound_method %int_3.loc16, %impl.elem0.loc16_28 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.485]
// CHECK:STDOUT:   %specific_fn.loc16_28: <specific function> = specific_function %impl.elem0.loc16_28, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc16_28.2: <bound method> = bound_method %int_3.loc16, %specific_fn.loc16_28 [concrete = constants.%bound_method.763]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16: init %i32 = call %bound_method.loc16_28.2(%int_3.loc16) [concrete = constants.%int_3.410]
// CHECK:STDOUT:   %.loc16_28.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16 [concrete = constants.%int_3.410]
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
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc15: <bound method> = bound_method %b.var, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.5
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc15: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc15(%b.var)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc14: <bound method> = bound_method %v.var, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.5
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc14: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc14(%v.var)
// CHECK:STDOUT:   return %Int.as.AddWith.impl.Op.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc15_3.1(%self.param: ref %i32) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc15_3.1(%self.param: ref %i32) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc15_3.1(%self.param: ref %i32) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.1(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.1(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc15_3.2(%self.param: ref %i8) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc15_3.2(%self.param: ref %i8) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc15_3.2(%self.param: ref %i8) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.2(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.2(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc15_3.3(%self.param: ref %array_type) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %int_3: Core.IntLiteral = int_value 3 [concrete = constants.%int_3.1ba]
// CHECK:STDOUT:   %.loc15_3.1: ref %i8 = array_index %self.param, %int_3
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc15_3.1: <bound method> = bound_method %.loc15_3.1, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc15_3.1: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc15_3.1(%.loc15_3.1)
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:   %.loc15_3.2: ref %i8 = array_index %self.param, %int_2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc15_3.2: <bound method> = bound_method %.loc15_3.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc15_3.2: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc15_3.2(%.loc15_3.2)
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %.loc15_3.3: ref %i8 = array_index %self.param, %int_1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc15_3.3: <bound method> = bound_method %.loc15_3.3, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc15_3.3: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc15_3.3(%.loc15_3.3)
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0]
// CHECK:STDOUT:   %.loc15_3.4: ref %i8 = array_index %self.param, %int_0
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc15_3.4: <bound method> = bound_method %.loc15_3.4, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc15_3.4: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc15_3.4(%.loc15_3.4)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc15_3.3(%self.param: ref %array_type) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc15_3.3(%self.param: ref %array_type) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.3(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.3(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc15_3.4(%self.param: ref %.e9a) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc15_3.4(%self.param: ref %.e9a) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc15_3.4(%self.param: ref %.e9a) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.4(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.4(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc15_3.5(%self.param: ref %IntOrBytes) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %bytes.ref: %IntOrBytes.elem.ff6 = name_ref bytes, @IntOrBytes.%field_decl.loc5 [concrete = @IntOrBytes.%field_decl.loc5]
// CHECK:STDOUT:   %.loc15_3.1: ref %array_type = class_element_access %self.param, element1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc15_3.1: <bound method> = bound_method %.loc15_3.1, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.3
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc15_3.1: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc15_3.1(%.loc15_3.1)
// CHECK:STDOUT:   %word.ref: %IntOrBytes.elem.a3f = name_ref word, @IntOrBytes.%field_decl.loc4 [concrete = @IntOrBytes.%field_decl.loc4]
// CHECK:STDOUT:   %.loc15_3.2: ref %i32 = class_element_access %self.param, element0
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc15_3.2: <bound method> = bound_method %.loc15_3.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc15_3.2: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc15_3.2(%.loc15_3.2)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc15_3.5(%self.param: ref %IntOrBytes) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc15_3.5(%self.param: ref %IntOrBytes) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.5(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.5(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- return_designated.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %IntOrBytes: type = class_type @IntOrBytes [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %.44d: Core.Form = init_form %IntOrBytes [concrete]
// CHECK:STDOUT:   %pattern_type.970: type = pattern_type %IntOrBytes [concrete]
// CHECK:STDOUT:   %return.param_patt.b6e: %pattern_type.970 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.57b: %pattern_type.970 = return_slot_pattern %return.param_patt.b6e, %IntOrBytes [concrete]
// CHECK:STDOUT:   %Make.type: type = fn_type @Make [concrete]
// CHECK:STDOUT:   %Make: %Make.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_7.29f: Core.IntLiteral = int_value 7 [concrete]
// CHECK:STDOUT:   %struct_type.word: type = struct_type {.word: Core.IntLiteral} [concrete]
// CHECK:STDOUT:   %struct: %struct_type.word = struct_value (%int_7.29f) [concrete]
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
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound: <bound method> = bound_method %int_7.29f, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method: <bound method> = bound_method %int_7.29f, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_7.690: %i32 = int_value 7 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Make.decl: %Make.type = fn_decl @Make [concrete = constants.%Make] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.970 = out_param_pattern [concrete = constants.%return.param_patt.b6e]
// CHECK:STDOUT:     %return.patt: %pattern_type.970 = return_slot_pattern %return.param_patt, %IntOrBytes.ref [concrete = constants.%return.patt.57b]
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
// CHECK:STDOUT:   %int_7: Core.IntLiteral = int_value 7 [concrete = constants.%int_7.29f]
// CHECK:STDOUT:   %.loc9_44.1: %struct_type.word = struct_literal (%int_7) [concrete = constants.%struct]
// CHECK:STDOUT:   %impl.elem0: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc9_44.1: <bound method> = bound_method %int_7, %impl.elem0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound]
// CHECK:STDOUT:   %specific_fn: <specific function> = specific_function %impl.elem0, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc9_44.2: <bound method> = bound_method %int_7, %specific_fn [concrete = constants.%bound_method]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %i32 = call %bound_method.loc9_44.2(%int_7) [concrete = constants.%int_7.690]
// CHECK:STDOUT:   %.loc9_44.2: init %i32 = converted %int_7, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_7.690]
// CHECK:STDOUT:   %.loc9_44.3: ref %i32 = class_element_access %return.param, element0
// CHECK:STDOUT:   %.loc9_44.4: init %i32 to %.loc9_44.3 = in_place_init %.loc9_44.2 [concrete = constants.%int_7.690]
// CHECK:STDOUT:   %.loc9_44.5: init %IntOrBytes to %return.param = class_init (%.loc9_44.4)
// CHECK:STDOUT:   %.loc9_45: init %IntOrBytes = converted %.loc9_44.1, %.loc9_44.5
// CHECK:STDOUT:   return %.loc9_45 to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- let_designated.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
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
// CHECK:STDOUT:   %pattern_type.9c7: type = pattern_type %array_type [concrete]
// CHECK:STDOUT:   %IntOrBytes.elem.ff6: type = unbound_element_type %IntOrBytes, %array_type [concrete]
// CHECK:STDOUT:   %.e9a: type = custom_layout_type {size=4, align=4, .word@0: %i32, .bytes@0: %array_type} [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %LetDesignated.type: type = fn_type @LetDesignated [concrete]
// CHECK:STDOUT:   %LetDesignated: %LetDesignated.type = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.970: type = pattern_type %IntOrBytes [concrete]
// CHECK:STDOUT:   %v.patt: %pattern_type.970 = value_binding_pattern v [concrete]
// CHECK:STDOUT:   %int_9.988: Core.IntLiteral = int_value 9 [concrete]
// CHECK:STDOUT:   %struct_type.word: type = struct_type {.word: Core.IntLiteral} [concrete]
// CHECK:STDOUT:   %struct: %struct_type.word = struct_value (%int_9.988) [concrete]
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
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound: <bound method> = bound_method %int_9.988, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method: <bound method> = bound_method %int_9.988, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_9.056: %i32 = int_value 9 [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet: %Copy.type = facet_value %i32, (%Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.381: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet) [concrete]
// CHECK:STDOUT:   %.737: type = fn_type_with_self_type %Copy.WithSelf.Op.type.381, %Copy.facet [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %self.param_patt.705: %pattern_type.6b6 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.70d: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt.705 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc10_33.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.1: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.1: type = fn_type @Destroy.WithSelf.Op.loc10_33.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.1: %Destroy.WithSelf.Op.type.ef016f.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.1: type = fn_type @Destroy.WithSelf.SelfDestruct.loc10_33.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.1: %Destroy.WithSelf.SelfDestruct.type.fbceb5.1 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.0cf: type = pattern_type %i8 [concrete]
// CHECK:STDOUT:   %self.param_patt.6c8: %pattern_type.0cf = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.136: %pattern_type.0cf = wrapper_binding_pattern self, %self.param_patt.6c8 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc10_33.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.2: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.2: type = fn_type @Destroy.WithSelf.Op.loc10_33.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.2: %Destroy.WithSelf.Op.type.ef016f.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.2: type = fn_type @Destroy.WithSelf.SelfDestruct.loc10_33.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.2: %Destroy.WithSelf.SelfDestruct.type.fbceb5.2 = struct_value () [concrete]
// CHECK:STDOUT:   %self.param_patt.078: %pattern_type.9c7 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.d53: %pattern_type.9c7 = wrapper_binding_pattern self, %self.param_patt.078 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc10_33.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.3: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3 = struct_value () [concrete]
// CHECK:STDOUT:   %int_3: Core.IntLiteral = int_value 3 [concrete]
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.3: type = fn_type @Destroy.WithSelf.Op.loc10_33.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.3: %Destroy.WithSelf.Op.type.ef016f.3 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.3: type = fn_type @Destroy.WithSelf.SelfDestruct.loc10_33.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.3: %Destroy.WithSelf.SelfDestruct.type.fbceb5.3 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.cf0: type = pattern_type %.e9a [concrete]
// CHECK:STDOUT:   %self.param_patt.bc5: %pattern_type.cf0 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.928: %pattern_type.cf0 = wrapper_binding_pattern self, %self.param_patt.bc5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc10_33.4 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.4: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.4: type = fn_type @Destroy.WithSelf.Op.loc10_33.4 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.4: %Destroy.WithSelf.Op.type.ef016f.4 = struct_value () [concrete]
// CHECK:STDOUT:   %self.param_patt.453: %pattern_type.970 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.e2e: %pattern_type.970 = wrapper_binding_pattern self, %self.param_patt.453 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.5: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc10_33.5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.5: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.5 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.5: type = fn_type @Destroy.WithSelf.Op.loc10_33.5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.5: %Destroy.WithSelf.Op.type.ef016f.5 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.5: type = fn_type @Destroy.WithSelf.SelfDestruct.loc10_33.5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.5: %Destroy.WithSelf.SelfDestruct.type.fbceb5.5 = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.1: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc10_33.1 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.1] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6b6 = ref_param_pattern [concrete = constants.%self.param_patt.705]
// CHECK:STDOUT:     %self.patt: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.70d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i32 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i32 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.1: %Destroy.WithSelf.Op.type.ef016f.1 = fn_decl @Destroy.WithSelf.Op.loc10_33.1 [concrete = constants.%Destroy.WithSelf.Op.403171.1] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6b6 = ref_param_pattern [concrete = constants.%self.param_patt.705]
// CHECK:STDOUT:     %self.patt: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.70d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i32 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i32 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.2: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc10_33.2 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.2] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.0cf = ref_param_pattern [concrete = constants.%self.param_patt.6c8]
// CHECK:STDOUT:     %self.patt: %pattern_type.0cf = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.136]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i8 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i8 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.2: %Destroy.WithSelf.Op.type.ef016f.2 = fn_decl @Destroy.WithSelf.Op.loc10_33.2 [concrete = constants.%Destroy.WithSelf.Op.403171.2] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.0cf = ref_param_pattern [concrete = constants.%self.param_patt.6c8]
// CHECK:STDOUT:     %self.patt: %pattern_type.0cf = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.136]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i8 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i8 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.3: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc10_33.3 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.3] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.9c7 = ref_param_pattern [concrete = constants.%self.param_patt.078]
// CHECK:STDOUT:     %self.patt: %pattern_type.9c7 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.d53]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %array_type = ref_param call_param0
// CHECK:STDOUT:     %self: ref %array_type = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.3: %Destroy.WithSelf.Op.type.ef016f.3 = fn_decl @Destroy.WithSelf.Op.loc10_33.3 [concrete = constants.%Destroy.WithSelf.Op.403171.3] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.9c7 = ref_param_pattern [concrete = constants.%self.param_patt.078]
// CHECK:STDOUT:     %self.patt: %pattern_type.9c7 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.d53]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %array_type = ref_param call_param0
// CHECK:STDOUT:     %self: ref %array_type = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.4: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc10_33.4 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.4] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.cf0 = ref_param_pattern [concrete = constants.%self.param_patt.bc5]
// CHECK:STDOUT:     %self.patt: %pattern_type.cf0 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.928]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %.e9a = ref_param call_param0
// CHECK:STDOUT:     %self: ref %.e9a = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.4: %Destroy.WithSelf.Op.type.ef016f.4 = fn_decl @Destroy.WithSelf.Op.loc10_33.4 [concrete = constants.%Destroy.WithSelf.Op.403171.4] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.cf0 = ref_param_pattern [concrete = constants.%self.param_patt.bc5]
// CHECK:STDOUT:     %self.patt: %pattern_type.cf0 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.928]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %.e9a = ref_param call_param0
// CHECK:STDOUT:     %self: ref %.e9a = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.5: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.5 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc10_33.5 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.5] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.970 = ref_param_pattern [concrete = constants.%self.param_patt.453]
// CHECK:STDOUT:     %self.patt: %pattern_type.970 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.e2e]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %IntOrBytes = ref_param call_param0
// CHECK:STDOUT:     %self: ref %IntOrBytes = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.5: %Destroy.WithSelf.Op.type.ef016f.5 = fn_decl @Destroy.WithSelf.Op.loc10_33.5 [concrete = constants.%Destroy.WithSelf.Op.403171.5] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.970 = ref_param_pattern [concrete = constants.%self.param_patt.453]
// CHECK:STDOUT:     %self.patt: %pattern_type.970 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.e2e]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %IntOrBytes = ref_param call_param0
// CHECK:STDOUT:     %self: ref %IntOrBytes = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %LetDesignated.decl: %LetDesignated.type = fn_decl @LetDesignated [concrete = constants.%LetDesignated] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc9: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param0
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @LetDesignated() -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %int_9: Core.IntLiteral = int_value 9 [concrete = constants.%int_9.988]
// CHECK:STDOUT:   %.loc10_33.1: %struct_type.word = struct_literal (%int_9) [concrete = constants.%struct]
// CHECK:STDOUT:   %impl.elem0.loc10: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc10_33.1: <bound method> = bound_method %int_9, %impl.elem0.loc10 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound]
// CHECK:STDOUT:   %specific_fn.loc10: <specific function> = specific_function %impl.elem0.loc10, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc10_33.2: <bound method> = bound_method %int_9, %specific_fn.loc10 [concrete = constants.%bound_method]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %i32 = call %bound_method.loc10_33.2(%int_9) [concrete = constants.%int_9.056]
// CHECK:STDOUT:   %.loc10_33.2: init %i32 = converted %int_9, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_9.056]
// CHECK:STDOUT:   %.loc10_33.3: ref %IntOrBytes = temporary_storage
// CHECK:STDOUT:   %.loc10_33.4: ref %i32 = class_element_access %.loc10_33.3, element0
// CHECK:STDOUT:   %.loc10_33.5: init %i32 to %.loc10_33.4 = in_place_init %.loc10_33.2 [concrete = constants.%int_9.056]
// CHECK:STDOUT:   %.loc10_33.6: init %IntOrBytes to %.loc10_33.3 = class_init (%.loc10_33.5)
// CHECK:STDOUT:   %.loc10_33.7: init %IntOrBytes = converted %.loc10_33.1, %.loc10_33.6
// CHECK:STDOUT:   %.loc10_33.8: ref %IntOrBytes = temporary %.loc10_33.3, %.loc10_33.7
// CHECK:STDOUT:   %.loc10_33.9: %IntOrBytes = acquire_value %.loc10_33.8
// CHECK:STDOUT:   %IntOrBytes.ref: type = name_ref IntOrBytes, file.%IntOrBytes.decl [concrete = constants.%IntOrBytes]
// CHECK:STDOUT:   %v: %IntOrBytes = wrapper_binding v, %.loc10_33.9
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %v.patt: %pattern_type.970 = value_binding_pattern v [concrete = constants.%v.patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %v.ref: %IntOrBytes = name_ref v, %v
// CHECK:STDOUT:   %word.ref: %IntOrBytes.elem.a3f = name_ref word, @IntOrBytes.%field_decl.loc4 [concrete = @IntOrBytes.%field_decl.loc4]
// CHECK:STDOUT:   %.loc11_11.1: ref %i32 = class_element_access %v.ref, element0
// CHECK:STDOUT:   %.loc11_11.2: %i32 = acquire_value %.loc11_11.1
// CHECK:STDOUT:   %impl.elem0.loc11: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc11_11.1: <bound method> = bound_method %.loc11_11.2, %impl.elem0.loc11
// CHECK:STDOUT:   %specific_fn.loc11: <specific function> = specific_function %impl.elem0.loc11, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc11_11.2: <bound method> = bound_method %.loc11_11.2, %specific_fn.loc11
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc11_11.2(%.loc11_11.2)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound: <bound method> = bound_method %.loc10_33.8, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.5
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound(%.loc10_33.8)
// CHECK:STDOUT:   return %Int.as.Copy.impl.Op.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc10_33.1(%self.param: ref %i32) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc10_33.1(%self.param: ref %i32) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc10_33.1(%self.param: ref %i32) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.1(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.1(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc10_33.2(%self.param: ref %i8) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc10_33.2(%self.param: ref %i8) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc10_33.2(%self.param: ref %i8) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.2(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.2(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc10_33.3(%self.param: ref %array_type) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %int_3: Core.IntLiteral = int_value 3 [concrete = constants.%int_3]
// CHECK:STDOUT:   %.loc10_33.1: ref %i8 = array_index %self.param, %int_3
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc10_33.1: <bound method> = bound_method %.loc10_33.1, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc10_33.1: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc10_33.1(%.loc10_33.1)
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2]
// CHECK:STDOUT:   %.loc10_33.2: ref %i8 = array_index %self.param, %int_2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc10_33.2: <bound method> = bound_method %.loc10_33.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc10_33.2: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc10_33.2(%.loc10_33.2)
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1]
// CHECK:STDOUT:   %.loc10_33.3: ref %i8 = array_index %self.param, %int_1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc10_33.3: <bound method> = bound_method %.loc10_33.3, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc10_33.3: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc10_33.3(%.loc10_33.3)
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0]
// CHECK:STDOUT:   %.loc10_33.4: ref %i8 = array_index %self.param, %int_0
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc10_33.4: <bound method> = bound_method %.loc10_33.4, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc10_33.4: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc10_33.4(%.loc10_33.4)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc10_33.3(%self.param: ref %array_type) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc10_33.3(%self.param: ref %array_type) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.3(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.3(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc10_33.4(%self.param: ref %.e9a) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc10_33.4(%self.param: ref %.e9a) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc10_33.4(%self.param: ref %.e9a) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.4(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.4(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc10_33.5(%self.param: ref %IntOrBytes) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %bytes.ref: %IntOrBytes.elem.ff6 = name_ref bytes, @IntOrBytes.%field_decl.loc5 [concrete = @IntOrBytes.%field_decl.loc5]
// CHECK:STDOUT:   %.loc10_33.1: ref %array_type = class_element_access %self.param, element1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc10_33.1: <bound method> = bound_method %.loc10_33.1, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.3
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc10_33.1: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc10_33.1(%.loc10_33.1)
// CHECK:STDOUT:   %word.ref: %IntOrBytes.elem.a3f = name_ref word, @IntOrBytes.%field_decl.loc4 [concrete = @IntOrBytes.%field_decl.loc4]
// CHECK:STDOUT:   %.loc10_33.2: ref %i32 = class_element_access %self.param, element0
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc10_33.2: <bound method> = bound_method %.loc10_33.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc10_33.2: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc10_33.2(%.loc10_33.2)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc10_33.5(%self.param: ref %IntOrBytes) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc10_33.5(%self.param: ref %IntOrBytes) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.5(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.5(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- from_struct_value.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
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
// CHECK:STDOUT:   %pattern_type.9c7: type = pattern_type %array_type [concrete]
// CHECK:STDOUT:   %IntOrBytes.elem.ff6: type = unbound_element_type %IntOrBytes, %array_type [concrete]
// CHECK:STDOUT:   %.e9a: type = custom_layout_type {size=4, align=4, .word@0: %i32, .bytes@0: %array_type} [concrete]
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
// CHECK:STDOUT:   %self.param_patt.705: %pattern_type.6b6 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.70d: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt.705 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc13_3.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.1: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.1: type = fn_type @Destroy.WithSelf.Op.loc13_3.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.1: %Destroy.WithSelf.Op.type.ef016f.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.1: type = fn_type @Destroy.WithSelf.SelfDestruct.loc13_3.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.1: %Destroy.WithSelf.SelfDestruct.type.fbceb5.1 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.0cf: type = pattern_type %i8 [concrete]
// CHECK:STDOUT:   %self.param_patt.6c8: %pattern_type.0cf = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.136: %pattern_type.0cf = wrapper_binding_pattern self, %self.param_patt.6c8 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc13_3.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.2: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.2: type = fn_type @Destroy.WithSelf.Op.loc13_3.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.2: %Destroy.WithSelf.Op.type.ef016f.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.2: type = fn_type @Destroy.WithSelf.SelfDestruct.loc13_3.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.2: %Destroy.WithSelf.SelfDestruct.type.fbceb5.2 = struct_value () [concrete]
// CHECK:STDOUT:   %self.param_patt.078: %pattern_type.9c7 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.d53: %pattern_type.9c7 = wrapper_binding_pattern self, %self.param_patt.078 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc13_3.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.3: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3 = struct_value () [concrete]
// CHECK:STDOUT:   %int_3: Core.IntLiteral = int_value 3 [concrete]
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.3: type = fn_type @Destroy.WithSelf.Op.loc13_3.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.3: %Destroy.WithSelf.Op.type.ef016f.3 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.3: type = fn_type @Destroy.WithSelf.SelfDestruct.loc13_3.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.3: %Destroy.WithSelf.SelfDestruct.type.fbceb5.3 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.cf0: type = pattern_type %.e9a [concrete]
// CHECK:STDOUT:   %self.param_patt.bc5: %pattern_type.cf0 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.928: %pattern_type.cf0 = wrapper_binding_pattern self, %self.param_patt.bc5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc13_3.4 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.4: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.4: type = fn_type @Destroy.WithSelf.Op.loc13_3.4 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.4: %Destroy.WithSelf.Op.type.ef016f.4 = struct_value () [concrete]
// CHECK:STDOUT:   %self.param_patt.453: %pattern_type.970 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.e2e: %pattern_type.970 = wrapper_binding_pattern self, %self.param_patt.453 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.5: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc13_3.5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.5: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.5 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.5: type = fn_type @Destroy.WithSelf.Op.loc13_3.5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.5: %Destroy.WithSelf.Op.type.ef016f.5 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.5: type = fn_type @Destroy.WithSelf.SelfDestruct.loc13_3.5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.5: %Destroy.WithSelf.SelfDestruct.type.fbceb5.5 = struct_value () [concrete]
// CHECK:STDOUT:   %self.param_patt.5fd: %pattern_type.183 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.a77: %pattern_type.183 = wrapper_binding_pattern self, %self.param_patt.5fd [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.6: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc12 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.6: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.6 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.6: type = fn_type @Destroy.WithSelf.Op.loc12 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.6: %Destroy.WithSelf.Op.type.ef016f.6 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.6: type = fn_type @Destroy.WithSelf.SelfDestruct.loc12 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.6: %Destroy.WithSelf.SelfDestruct.type.fbceb5.6 = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.1: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc13_3.1 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.1] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6b6 = ref_param_pattern [concrete = constants.%self.param_patt.705]
// CHECK:STDOUT:     %self.patt: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.70d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i32 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i32 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.1: %Destroy.WithSelf.Op.type.ef016f.1 = fn_decl @Destroy.WithSelf.Op.loc13_3.1 [concrete = constants.%Destroy.WithSelf.Op.403171.1] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6b6 = ref_param_pattern [concrete = constants.%self.param_patt.705]
// CHECK:STDOUT:     %self.patt: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.70d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i32 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i32 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.2: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc13_3.2 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.2] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.0cf = ref_param_pattern [concrete = constants.%self.param_patt.6c8]
// CHECK:STDOUT:     %self.patt: %pattern_type.0cf = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.136]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i8 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i8 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.2: %Destroy.WithSelf.Op.type.ef016f.2 = fn_decl @Destroy.WithSelf.Op.loc13_3.2 [concrete = constants.%Destroy.WithSelf.Op.403171.2] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.0cf = ref_param_pattern [concrete = constants.%self.param_patt.6c8]
// CHECK:STDOUT:     %self.patt: %pattern_type.0cf = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.136]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i8 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i8 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.3: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc13_3.3 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.3] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.9c7 = ref_param_pattern [concrete = constants.%self.param_patt.078]
// CHECK:STDOUT:     %self.patt: %pattern_type.9c7 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.d53]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %array_type = ref_param call_param0
// CHECK:STDOUT:     %self: ref %array_type = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.3: %Destroy.WithSelf.Op.type.ef016f.3 = fn_decl @Destroy.WithSelf.Op.loc13_3.3 [concrete = constants.%Destroy.WithSelf.Op.403171.3] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.9c7 = ref_param_pattern [concrete = constants.%self.param_patt.078]
// CHECK:STDOUT:     %self.patt: %pattern_type.9c7 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.d53]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %array_type = ref_param call_param0
// CHECK:STDOUT:     %self: ref %array_type = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.4: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc13_3.4 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.4] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.cf0 = ref_param_pattern [concrete = constants.%self.param_patt.bc5]
// CHECK:STDOUT:     %self.patt: %pattern_type.cf0 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.928]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %.e9a = ref_param call_param0
// CHECK:STDOUT:     %self: ref %.e9a = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.4: %Destroy.WithSelf.Op.type.ef016f.4 = fn_decl @Destroy.WithSelf.Op.loc13_3.4 [concrete = constants.%Destroy.WithSelf.Op.403171.4] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.cf0 = ref_param_pattern [concrete = constants.%self.param_patt.bc5]
// CHECK:STDOUT:     %self.patt: %pattern_type.cf0 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.928]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %.e9a = ref_param call_param0
// CHECK:STDOUT:     %self: ref %.e9a = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.5: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.5 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc13_3.5 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.5] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.970 = ref_param_pattern [concrete = constants.%self.param_patt.453]
// CHECK:STDOUT:     %self.patt: %pattern_type.970 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.e2e]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %IntOrBytes = ref_param call_param0
// CHECK:STDOUT:     %self: ref %IntOrBytes = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.5: %Destroy.WithSelf.Op.type.ef016f.5 = fn_decl @Destroy.WithSelf.Op.loc13_3.5 [concrete = constants.%Destroy.WithSelf.Op.403171.5] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.970 = ref_param_pattern [concrete = constants.%self.param_patt.453]
// CHECK:STDOUT:     %self.patt: %pattern_type.970 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.e2e]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %IntOrBytes = ref_param call_param0
// CHECK:STDOUT:     %self: ref %IntOrBytes = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.6: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.6 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc12 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.6] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.183 = ref_param_pattern [concrete = constants.%self.param_patt.5fd]
// CHECK:STDOUT:     %self.patt: %pattern_type.183 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.a77]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %struct_type.word.486 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %struct_type.word.486 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.6: %Destroy.WithSelf.Op.type.ef016f.6 = fn_decl @Destroy.WithSelf.Op.loc12 [concrete = constants.%Destroy.WithSelf.Op.403171.6] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.183 = ref_param_pattern [concrete = constants.%self.param_patt.5fd]
// CHECK:STDOUT:     %self.patt: %pattern_type.183 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.a77]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %struct_type.word.486 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %struct_type.word.486 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
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
// CHECK:STDOUT:   %.loc13_23.1: ref %i32 = struct_access %s.ref, element0
// CHECK:STDOUT:   %.loc13_23.2: %i32 = acquire_value %.loc13_23.1
// CHECK:STDOUT:   %impl.elem0.loc13: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc13_23.1: <bound method> = bound_method %.loc13_23.2, %impl.elem0.loc13
// CHECK:STDOUT:   %specific_fn.loc13: <specific function> = specific_function %impl.elem0.loc13, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc13_23.2: <bound method> = bound_method %.loc13_23.2, %specific_fn.loc13
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call.loc13: init %i32 = call %bound_method.loc13_23.2(%.loc13_23.2)
// CHECK:STDOUT:   %.loc13_23.3: ref %i32 = class_element_access %v.var, element0
// CHECK:STDOUT:   %.loc13_23.4: init %i32 to %.loc13_23.3 = in_place_init %Int.as.Copy.impl.Op.call.loc13
// CHECK:STDOUT:   %.loc13_23.5: init %IntOrBytes to %v.var = class_init (%.loc13_23.4)
// CHECK:STDOUT:   %.loc13_3: init %IntOrBytes = converted %s.ref, %.loc13_23.5
// CHECK:STDOUT:   assign %v.var, %.loc13_3
// CHECK:STDOUT:   %IntOrBytes.ref: type = name_ref IntOrBytes, file.%IntOrBytes.decl [concrete = constants.%IntOrBytes]
// CHECK:STDOUT:   %v: ref %IntOrBytes = wrapper_binding v, %v.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %v.patt: %pattern_type.970 = ref_binding_pattern v [concrete = constants.%v.patt]
// CHECK:STDOUT:     %v.var_patt: %pattern_type.970 = var_pattern %v.patt [concrete = constants.%v.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %v.ref: ref %IntOrBytes = name_ref v, %v
// CHECK:STDOUT:   %word.ref: %IntOrBytes.elem.a3f = name_ref word, @IntOrBytes.%field_decl.loc4 [concrete = @IntOrBytes.%field_decl.loc4]
// CHECK:STDOUT:   %.loc14_11.1: ref %i32 = class_element_access %v.ref, element0
// CHECK:STDOUT:   %.loc14_11.2: %i32 = acquire_value %.loc14_11.1
// CHECK:STDOUT:   %impl.elem0.loc14: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc14_11.1: <bound method> = bound_method %.loc14_11.2, %impl.elem0.loc14
// CHECK:STDOUT:   %specific_fn.loc14: <specific function> = specific_function %impl.elem0.loc14, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc14_11.2: <bound method> = bound_method %.loc14_11.2, %specific_fn.loc14
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call.loc14: init %i32 = call %bound_method.loc14_11.2(%.loc14_11.2)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc13: <bound method> = bound_method %v.var, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.5
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc13: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc13(%v.var)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc12: <bound method> = bound_method %s.var, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.6
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc12: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc12(%s.var)
// CHECK:STDOUT:   return %Int.as.Copy.impl.Op.call.loc14
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc13_3.1(%self.param: ref %i32) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc13_3.1(%self.param: ref %i32) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc13_3.1(%self.param: ref %i32) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.1(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.1(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc13_3.2(%self.param: ref %i8) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc13_3.2(%self.param: ref %i8) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc13_3.2(%self.param: ref %i8) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.2(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.2(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc13_3.3(%self.param: ref %array_type) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %int_3: Core.IntLiteral = int_value 3 [concrete = constants.%int_3]
// CHECK:STDOUT:   %.loc13_3.1: ref %i8 = array_index %self.param, %int_3
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc13_3.1: <bound method> = bound_method %.loc13_3.1, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc13_3.1: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc13_3.1(%.loc13_3.1)
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2]
// CHECK:STDOUT:   %.loc13_3.2: ref %i8 = array_index %self.param, %int_2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc13_3.2: <bound method> = bound_method %.loc13_3.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc13_3.2: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc13_3.2(%.loc13_3.2)
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %.loc13_3.3: ref %i8 = array_index %self.param, %int_1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc13_3.3: <bound method> = bound_method %.loc13_3.3, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc13_3.3: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc13_3.3(%.loc13_3.3)
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0]
// CHECK:STDOUT:   %.loc13_3.4: ref %i8 = array_index %self.param, %int_0
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc13_3.4: <bound method> = bound_method %.loc13_3.4, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc13_3.4: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc13_3.4(%.loc13_3.4)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc13_3.3(%self.param: ref %array_type) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc13_3.3(%self.param: ref %array_type) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.3(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.3(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc13_3.4(%self.param: ref %.e9a) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc13_3.4(%self.param: ref %.e9a) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc13_3.4(%self.param: ref %.e9a) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.4(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.4(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc13_3.5(%self.param: ref %IntOrBytes) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %bytes.ref: %IntOrBytes.elem.ff6 = name_ref bytes, @IntOrBytes.%field_decl.loc5 [concrete = @IntOrBytes.%field_decl.loc5]
// CHECK:STDOUT:   %.loc13_3.1: ref %array_type = class_element_access %self.param, element1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc13_3.1: <bound method> = bound_method %.loc13_3.1, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.3
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc13_3.1: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc13_3.1(%.loc13_3.1)
// CHECK:STDOUT:   %word.ref: %IntOrBytes.elem.a3f = name_ref word, @IntOrBytes.%field_decl.loc4 [concrete = @IntOrBytes.%field_decl.loc4]
// CHECK:STDOUT:   %.loc13_3.2: ref %i32 = class_element_access %self.param, element0
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc13_3.2: <bound method> = bound_method %.loc13_3.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc13_3.2: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc13_3.2(%.loc13_3.2)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc13_3.5(%self.param: ref %IntOrBytes) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc13_3.5(%self.param: ref %IntOrBytes) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.5(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.5(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc12(%self.param: ref %struct_type.word.486) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %.loc12: ref %i32 = struct_access %self.param, element0
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound: <bound method> = bound_method %.loc12, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound(%.loc12)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc12(%self.param: ref %struct_type.word.486) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc12(%self.param: ref %struct_type.word.486) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.6(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.6(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- copy.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
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
// CHECK:STDOUT:   %pattern_type.9c7: type = pattern_type %array_type [concrete]
// CHECK:STDOUT:   %IntOrBytes.elem.ff6: type = unbound_element_type %IntOrBytes, %array_type [concrete]
// CHECK:STDOUT:   %.e9a: type = custom_layout_type {size=4, align=4, .word@0: %i32, .bytes@0: %array_type} [concrete]
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
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.7f5: type = fn_type @Copy.WithSelf.Op.2 [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.416: %Copy.WithSelf.Op.type.7f5 = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.bab: <witness> = custom_witness (%Copy.WithSelf.Op.416), @Copy.1 [concrete]
// CHECK:STDOUT:   %Copy.facet.b97: %Copy.type.bd0 = facet_value %IntOrBytes, (%custom_witness.bab) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.c4f: type = fn_type @Copy.WithSelf.Op.1, @Copy.WithSelf(%Copy.facet.b97) [concrete]
// CHECK:STDOUT:   %.2da: type = fn_type_with_self_type %Copy.WithSelf.Op.type.c4f, %Copy.facet.b97 [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet.1e1: %Copy.type.bd0 = facet_value %i32, (%Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.381: type = fn_type @Copy.WithSelf.Op.1, @Copy.WithSelf(%Copy.facet.1e1) [concrete]
// CHECK:STDOUT:   %.737: type = fn_type_with_self_type %Copy.WithSelf.Op.type.381, %Copy.facet.1e1 [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %self.param_patt.705: %pattern_type.6b6 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.70d: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt.705 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc12_3.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.1: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.1: type = fn_type @Destroy.WithSelf.Op.loc12_3.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.1: %Destroy.WithSelf.Op.type.ef016f.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.1: type = fn_type @Destroy.WithSelf.SelfDestruct.loc12_3.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.1: %Destroy.WithSelf.SelfDestruct.type.fbceb5.1 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.0cf: type = pattern_type %i8 [concrete]
// CHECK:STDOUT:   %self.param_patt.6c8: %pattern_type.0cf = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.136: %pattern_type.0cf = wrapper_binding_pattern self, %self.param_patt.6c8 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc12_3.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.2: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.2: type = fn_type @Destroy.WithSelf.Op.loc12_3.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.2: %Destroy.WithSelf.Op.type.ef016f.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.2: type = fn_type @Destroy.WithSelf.SelfDestruct.loc12_3.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.2: %Destroy.WithSelf.SelfDestruct.type.fbceb5.2 = struct_value () [concrete]
// CHECK:STDOUT:   %self.param_patt.078: %pattern_type.9c7 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.d53: %pattern_type.9c7 = wrapper_binding_pattern self, %self.param_patt.078 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc12_3.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.3: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3 = struct_value () [concrete]
// CHECK:STDOUT:   %int_3: Core.IntLiteral = int_value 3 [concrete]
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.3: type = fn_type @Destroy.WithSelf.Op.loc12_3.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.3: %Destroy.WithSelf.Op.type.ef016f.3 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.3: type = fn_type @Destroy.WithSelf.SelfDestruct.loc12_3.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.3: %Destroy.WithSelf.SelfDestruct.type.fbceb5.3 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.cf0: type = pattern_type %.e9a [concrete]
// CHECK:STDOUT:   %self.param_patt.bc5: %pattern_type.cf0 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.928: %pattern_type.cf0 = wrapper_binding_pattern self, %self.param_patt.bc5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc12_3.4 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.4: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.4: type = fn_type @Destroy.WithSelf.Op.loc12_3.4 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.4: %Destroy.WithSelf.Op.type.ef016f.4 = struct_value () [concrete]
// CHECK:STDOUT:   %self.param_patt.453: %pattern_type.970 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.e2e: %pattern_type.970 = wrapper_binding_pattern self, %self.param_patt.453 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.5: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc12_3.5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.5: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.5 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.5: type = fn_type @Destroy.WithSelf.Op.loc12_3.5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.5: %Destroy.WithSelf.Op.type.ef016f.5 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.5: type = fn_type @Destroy.WithSelf.SelfDestruct.loc12_3.5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.5: %Destroy.WithSelf.SelfDestruct.type.fbceb5.5 = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.1: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc12_3.1 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.1] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6b6 = ref_param_pattern [concrete = constants.%self.param_patt.705]
// CHECK:STDOUT:     %self.patt: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.70d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i32 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i32 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.1: %Destroy.WithSelf.Op.type.ef016f.1 = fn_decl @Destroy.WithSelf.Op.loc12_3.1 [concrete = constants.%Destroy.WithSelf.Op.403171.1] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6b6 = ref_param_pattern [concrete = constants.%self.param_patt.705]
// CHECK:STDOUT:     %self.patt: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.70d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i32 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i32 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.2: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc12_3.2 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.2] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.0cf = ref_param_pattern [concrete = constants.%self.param_patt.6c8]
// CHECK:STDOUT:     %self.patt: %pattern_type.0cf = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.136]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i8 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i8 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.2: %Destroy.WithSelf.Op.type.ef016f.2 = fn_decl @Destroy.WithSelf.Op.loc12_3.2 [concrete = constants.%Destroy.WithSelf.Op.403171.2] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.0cf = ref_param_pattern [concrete = constants.%self.param_patt.6c8]
// CHECK:STDOUT:     %self.patt: %pattern_type.0cf = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.136]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i8 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i8 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.3: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc12_3.3 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.3] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.9c7 = ref_param_pattern [concrete = constants.%self.param_patt.078]
// CHECK:STDOUT:     %self.patt: %pattern_type.9c7 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.d53]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %array_type = ref_param call_param0
// CHECK:STDOUT:     %self: ref %array_type = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.3: %Destroy.WithSelf.Op.type.ef016f.3 = fn_decl @Destroy.WithSelf.Op.loc12_3.3 [concrete = constants.%Destroy.WithSelf.Op.403171.3] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.9c7 = ref_param_pattern [concrete = constants.%self.param_patt.078]
// CHECK:STDOUT:     %self.patt: %pattern_type.9c7 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.d53]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %array_type = ref_param call_param0
// CHECK:STDOUT:     %self: ref %array_type = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.4: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc12_3.4 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.4] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.cf0 = ref_param_pattern [concrete = constants.%self.param_patt.bc5]
// CHECK:STDOUT:     %self.patt: %pattern_type.cf0 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.928]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %.e9a = ref_param call_param0
// CHECK:STDOUT:     %self: ref %.e9a = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.4: %Destroy.WithSelf.Op.type.ef016f.4 = fn_decl @Destroy.WithSelf.Op.loc12_3.4 [concrete = constants.%Destroy.WithSelf.Op.403171.4] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.cf0 = ref_param_pattern [concrete = constants.%self.param_patt.bc5]
// CHECK:STDOUT:     %self.patt: %pattern_type.cf0 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.928]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %.e9a = ref_param call_param0
// CHECK:STDOUT:     %self: ref %.e9a = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.5: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.5 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc12_3.5 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.5] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.970 = ref_param_pattern [concrete = constants.%self.param_patt.453]
// CHECK:STDOUT:     %self.patt: %pattern_type.970 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.e2e]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %IntOrBytes = ref_param call_param0
// CHECK:STDOUT:     %self: ref %IntOrBytes = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.5: %Destroy.WithSelf.Op.type.ef016f.5 = fn_decl @Destroy.WithSelf.Op.loc12_3.5 [concrete = constants.%Destroy.WithSelf.Op.403171.5] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.970 = ref_param_pattern [concrete = constants.%self.param_patt.453]
// CHECK:STDOUT:     %self.patt: %pattern_type.970 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.e2e]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %IntOrBytes = ref_param call_param0
// CHECK:STDOUT:     %self: ref %IntOrBytes = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
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
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:   %impl.elem0.loc12: %.2da = impl_witness_access constants.%custom_witness.bab, element0 [concrete = constants.%Copy.WithSelf.Op.416]
// CHECK:STDOUT:   %bound_method.loc12: <bound method> = bound_method %v.ref.loc12, %impl.elem0.loc12
// CHECK:STDOUT:   %.loc12: ref %IntOrBytes = splice_block %w.var {}
// CHECK:STDOUT:   %Copy.WithSelf.Op.call.loc12: init %IntOrBytes to %.loc12 = call %bound_method.loc12(%v.ref.loc12)
// CHECK:STDOUT:   assign %w.var, %Copy.WithSelf.Op.call.loc12
// CHECK:STDOUT:   %IntOrBytes.ref.loc12: type = name_ref IntOrBytes, file.%IntOrBytes.decl [concrete = constants.%IntOrBytes]
// CHECK:STDOUT:   %w: ref %IntOrBytes = wrapper_binding w, %w.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %w.patt: %pattern_type.970 = ref_binding_pattern w [concrete = constants.%w.patt]
// CHECK:STDOUT:     %w.var_patt: %pattern_type.970 = var_pattern %w.patt [concrete = constants.%w.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %w.ref.loc13: ref %IntOrBytes = name_ref w, %w
// CHECK:STDOUT:   %v.ref.loc13: %IntOrBytes = name_ref v, %v
// CHECK:STDOUT:   %impl.elem0.loc13: %.2da = impl_witness_access constants.%custom_witness.bab, element0 [concrete = constants.%Copy.WithSelf.Op.416]
// CHECK:STDOUT:   %bound_method.loc13: <bound method> = bound_method %v.ref.loc13, %impl.elem0.loc13
// CHECK:STDOUT:   %.loc13: ref %IntOrBytes = splice_block %w.ref.loc13 {}
// CHECK:STDOUT:   %Copy.WithSelf.Op.call.loc13: init %IntOrBytes to %.loc13 = call %bound_method.loc13(%v.ref.loc13)
// CHECK:STDOUT:   assign %w.ref.loc13, %Copy.WithSelf.Op.call.loc13
// CHECK:STDOUT:   %w.ref.loc14: ref %IntOrBytes = name_ref w, %w
// CHECK:STDOUT:   %word.ref: %IntOrBytes.elem.a3f = name_ref word, @IntOrBytes.%field_decl.loc4 [concrete = @IntOrBytes.%field_decl.loc4]
// CHECK:STDOUT:   %.loc14_11.1: ref %i32 = class_element_access %w.ref.loc14, element0
// CHECK:STDOUT:   %.loc14_11.2: %i32 = acquire_value %.loc14_11.1
// CHECK:STDOUT:   %impl.elem0.loc14: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc14_11.1: <bound method> = bound_method %.loc14_11.2, %impl.elem0.loc14
// CHECK:STDOUT:   %specific_fn: <specific function> = specific_function %impl.elem0.loc14, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc14_11.2: <bound method> = bound_method %.loc14_11.2, %specific_fn
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc14_11.2(%.loc14_11.2)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound: <bound method> = bound_method %w.var, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.5
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound(%w.var)
// CHECK:STDOUT:   return %Int.as.Copy.impl.Op.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc12_3.1(%self.param: ref %i32) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc12_3.1(%self.param: ref %i32) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc12_3.1(%self.param: ref %i32) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.1(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.1(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc12_3.2(%self.param: ref %i8) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc12_3.2(%self.param: ref %i8) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc12_3.2(%self.param: ref %i8) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.2(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.2(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc12_3.3(%self.param: ref %array_type) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %int_3: Core.IntLiteral = int_value 3 [concrete = constants.%int_3]
// CHECK:STDOUT:   %.loc12_3.1: ref %i8 = array_index %self.param, %int_3
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc12_3.1: <bound method> = bound_method %.loc12_3.1, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc12_3.1: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc12_3.1(%.loc12_3.1)
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2]
// CHECK:STDOUT:   %.loc12_3.2: ref %i8 = array_index %self.param, %int_2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc12_3.2: <bound method> = bound_method %.loc12_3.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc12_3.2: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc12_3.2(%.loc12_3.2)
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1]
// CHECK:STDOUT:   %.loc12_3.3: ref %i8 = array_index %self.param, %int_1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc12_3.3: <bound method> = bound_method %.loc12_3.3, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc12_3.3: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc12_3.3(%.loc12_3.3)
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0]
// CHECK:STDOUT:   %.loc12_3.4: ref %i8 = array_index %self.param, %int_0
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc12_3.4: <bound method> = bound_method %.loc12_3.4, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc12_3.4: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc12_3.4(%.loc12_3.4)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc12_3.3(%self.param: ref %array_type) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc12_3.3(%self.param: ref %array_type) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.3(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.3(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc12_3.4(%self.param: ref %.e9a) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc12_3.4(%self.param: ref %.e9a) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc12_3.4(%self.param: ref %.e9a) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.4(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.4(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc12_3.5(%self.param: ref %IntOrBytes) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %bytes.ref: %IntOrBytes.elem.ff6 = name_ref bytes, @IntOrBytes.%field_decl.loc5 [concrete = @IntOrBytes.%field_decl.loc5]
// CHECK:STDOUT:   %.loc12_3.1: ref %array_type = class_element_access %self.param, element1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc12_3.1: <bound method> = bound_method %.loc12_3.1, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.3
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc12_3.1: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc12_3.1(%.loc12_3.1)
// CHECK:STDOUT:   %word.ref: %IntOrBytes.elem.a3f = name_ref word, @IntOrBytes.%field_decl.loc4 [concrete = @IntOrBytes.%field_decl.loc4]
// CHECK:STDOUT:   %.loc12_3.2: ref %i32 = class_element_access %self.param, element0
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc12_3.2: <bound method> = bound_method %.loc12_3.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc12_3.2: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc12_3.2(%.loc12_3.2)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc12_3.5(%self.param: ref %IntOrBytes) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc12_3.5(%self.param: ref %IntOrBytes) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.5(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.5(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- user_copy_impl_shadowed.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %Shadowed: type = class_type @Shadowed [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %Shadowed.elem: type = unbound_element_type %Shadowed, %i32 [concrete]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %pattern_type.915: type = pattern_type %Shadowed [concrete]
// CHECK:STDOUT:   %.784: type = custom_layout_type {size=4, align=4, .a@0: %i32} [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %x.param_patt: %pattern_type.915 = value_param_pattern [concrete]
// CHECK:STDOUT:   %x.patt: %pattern_type.915 = wrapper_binding_pattern x, %x.param_patt [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %CopyShadowed.type: type = fn_type @CopyShadowed [concrete]
// CHECK:STDOUT:   %CopyShadowed: %CopyShadowed.type = struct_value () [concrete]
// CHECK:STDOUT:   %y.patt: %pattern_type.915 = ref_binding_pattern y [concrete]
// CHECK:STDOUT:   %y.var_patt: %pattern_type.915 = var_pattern %y.patt [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.7f5: type = fn_type @Copy.WithSelf.Op.2 [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.416: %Copy.WithSelf.Op.type.7f5 = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.bab: <witness> = custom_witness (%Copy.WithSelf.Op.416), @Copy [concrete]
// CHECK:STDOUT:   %Copy.facet.29d: %Copy.type = facet_value %Shadowed, (%custom_witness.bab) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.f63: type = fn_type @Copy.WithSelf.Op.1, @Copy.WithSelf(%Copy.facet.29d) [concrete]
// CHECK:STDOUT:   %.a28: type = fn_type_with_self_type %Copy.WithSelf.Op.type.f63, %Copy.facet.29d [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet.1e1: %Copy.type = facet_value %i32, (%Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.381: type = fn_type @Copy.WithSelf.Op.1, @Copy.WithSelf(%Copy.facet.1e1) [concrete]
// CHECK:STDOUT:   %.737: type = fn_type_with_self_type %Copy.WithSelf.Op.type.381, %Copy.facet.1e1 [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %self.param_patt.705: %pattern_type.6b6 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.70d: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt.705 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc20_3.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.1: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.1: type = fn_type @Destroy.WithSelf.Op.loc20_3.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.1: %Destroy.WithSelf.Op.type.ef016f.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.1: type = fn_type @Destroy.WithSelf.SelfDestruct.loc20_3.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.1: %Destroy.WithSelf.SelfDestruct.type.fbceb5.1 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.a49: type = pattern_type %.784 [concrete]
// CHECK:STDOUT:   %self.param_patt.2d3: %pattern_type.a49 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.887: %pattern_type.a49 = wrapper_binding_pattern self, %self.param_patt.2d3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc20_3.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.2: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.2: type = fn_type @Destroy.WithSelf.Op.loc20_3.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.2: %Destroy.WithSelf.Op.type.ef016f.2 = struct_value () [concrete]
// CHECK:STDOUT:   %self.param_patt.6e0: %pattern_type.915 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.291: %pattern_type.915 = wrapper_binding_pattern self, %self.param_patt.6e0 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc20_3.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.3: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.3: type = fn_type @Destroy.WithSelf.Op.loc20_3.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.3: %Destroy.WithSelf.Op.type.ef016f.3 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.3: type = fn_type @Destroy.WithSelf.SelfDestruct.loc20_3.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.3: %Destroy.WithSelf.SelfDestruct.type.fbceb5.3 = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.1: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc20_3.1 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.1] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6b6 = ref_param_pattern [concrete = constants.%self.param_patt.705]
// CHECK:STDOUT:     %self.patt: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.70d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i32 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i32 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.1: %Destroy.WithSelf.Op.type.ef016f.1 = fn_decl @Destroy.WithSelf.Op.loc20_3.1 [concrete = constants.%Destroy.WithSelf.Op.403171.1] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6b6 = ref_param_pattern [concrete = constants.%self.param_patt.705]
// CHECK:STDOUT:     %self.patt: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.70d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i32 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i32 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.2: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc20_3.2 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.2] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.a49 = ref_param_pattern [concrete = constants.%self.param_patt.2d3]
// CHECK:STDOUT:     %self.patt: %pattern_type.a49 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.887]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %.784 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %.784 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.2: %Destroy.WithSelf.Op.type.ef016f.2 = fn_decl @Destroy.WithSelf.Op.loc20_3.2 [concrete = constants.%Destroy.WithSelf.Op.403171.2] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.a49 = ref_param_pattern [concrete = constants.%self.param_patt.2d3]
// CHECK:STDOUT:     %self.patt: %pattern_type.a49 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.887]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %.784 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %.784 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.3: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc20_3.3 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.3] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.915 = ref_param_pattern [concrete = constants.%self.param_patt.6e0]
// CHECK:STDOUT:     %self.patt: %pattern_type.915 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.291]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %Shadowed = ref_param call_param0
// CHECK:STDOUT:     %self: ref %Shadowed = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.3: %Destroy.WithSelf.Op.type.ef016f.3 = fn_decl @Destroy.WithSelf.Op.loc20_3.3 [concrete = constants.%Destroy.WithSelf.Op.403171.3] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.915 = ref_param_pattern [concrete = constants.%self.param_patt.6e0]
// CHECK:STDOUT:     %self.patt: %pattern_type.915 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.291]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %Shadowed = ref_param call_param0
// CHECK:STDOUT:     %self: ref %Shadowed = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
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
// CHECK:STDOUT:     %.loc19: Core.Form = init_form %i32 [concrete = constants.%.795f]
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
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:   %impl.elem0.loc20: %.a28 = impl_witness_access constants.%custom_witness.bab, element0 [concrete = constants.%Copy.WithSelf.Op.416]
// CHECK:STDOUT:   %bound_method.loc20: <bound method> = bound_method %x.ref, %impl.elem0.loc20
// CHECK:STDOUT:   %.loc20: ref %Shadowed = splice_block %y.var {}
// CHECK:STDOUT:   %Copy.WithSelf.Op.call: init %Shadowed to %.loc20 = call %bound_method.loc20(%x.ref)
// CHECK:STDOUT:   assign %y.var, %Copy.WithSelf.Op.call
// CHECK:STDOUT:   %Shadowed.ref.loc20: type = name_ref Shadowed, file.%Shadowed.decl [concrete = constants.%Shadowed]
// CHECK:STDOUT:   %y: ref %Shadowed = wrapper_binding y, %y.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %y.patt: %pattern_type.915 = ref_binding_pattern y [concrete = constants.%y.patt]
// CHECK:STDOUT:     %y.var_patt: %pattern_type.915 = var_pattern %y.patt [concrete = constants.%y.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %y.ref: ref %Shadowed = name_ref y, %y
// CHECK:STDOUT:   %a.ref: %Shadowed.elem = name_ref a, @Shadowed.%field_decl [concrete = @Shadowed.%field_decl]
// CHECK:STDOUT:   %.loc21_11.1: ref %i32 = class_element_access %y.ref, element0
// CHECK:STDOUT:   %.loc21_11.2: %i32 = acquire_value %.loc21_11.1
// CHECK:STDOUT:   %impl.elem0.loc21: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc21_11.1: <bound method> = bound_method %.loc21_11.2, %impl.elem0.loc21
// CHECK:STDOUT:   %specific_fn: <specific function> = specific_function %impl.elem0.loc21, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc21_11.2: <bound method> = bound_method %.loc21_11.2, %specific_fn
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc21_11.2(%.loc21_11.2)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound: <bound method> = bound_method %y.var, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.3
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound(%y.var)
// CHECK:STDOUT:   return %Int.as.Copy.impl.Op.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc20_3.1(%self.param: ref %i32) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc20_3.1(%self.param: ref %i32) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc20_3.1(%self.param: ref %i32) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.1(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.1(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc20_3.2(%self.param: ref %.784) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc20_3.2(%self.param: ref %.784) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc20_3.2(%self.param: ref %.784) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.2(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.2(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc20_3.3(%self.param: ref %Shadowed) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %a.ref: %Shadowed.elem = name_ref a, @Shadowed.%field_decl [concrete = @Shadowed.%field_decl]
// CHECK:STDOUT:   %.loc20: ref %i32 = class_element_access %self.param, element0
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound: <bound method> = bound_method %.loc20, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound(%.loc20)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc20_3.3(%self.param: ref %Shadowed) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc20_3.3(%self.param: ref %Shadowed) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.3(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.3(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- method.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
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
// CHECK:STDOUT:   %pattern_type.9c7: type = pattern_type %array_type [concrete]
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
// CHECK:STDOUT:   %.e9a: type = custom_layout_type {size=4, align=4, .word@0: %i32, .bytes@0: %array_type} [concrete]
// CHECK:STDOUT:   %complete_type.57b: <witness> = complete_type_witness %.e9a [concrete]
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
// CHECK:STDOUT:   %pattern_type.0cf: type = pattern_type %i8 [concrete]
// CHECK:STDOUT:   %Int.as.As.impl.Convert.specific_fn: <specific function> = specific_function %Int.as.As.impl.Convert.c63, @Int.as.As.impl.Convert.2(%int_8, %int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet.1e1: %Copy.type = facet_value %i32, (%Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.381: type = fn_type @Copy.WithSelf.Op.1, @Copy.WithSelf(%Copy.facet.1e1) [concrete]
// CHECK:STDOUT:   %.737: type = fn_type_with_self_type %Copy.WithSelf.Op.type.381, %Copy.facet.1e1 [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %u.param_patt: %pattern_type.970 = value_param_pattern [concrete]
// CHECK:STDOUT:   %u.patt: %pattern_type.970 = wrapper_binding_pattern u, %u.param_patt [concrete]
// CHECK:STDOUT:   %UseMethods.type: type = fn_type @UseMethods [concrete]
// CHECK:STDOUT:   %UseMethods: %UseMethods.type = struct_value () [concrete]
// CHECK:STDOUT:   %v.patt: %pattern_type.970 = ref_binding_pattern v [concrete]
// CHECK:STDOUT:   %v.var_patt: %pattern_type.970 = var_pattern %v.patt [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.7f5: type = fn_type @Copy.WithSelf.Op.2 [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.416: %Copy.WithSelf.Op.type.7f5 = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.bab: <witness> = custom_witness (%Copy.WithSelf.Op.416), @Copy [concrete]
// CHECK:STDOUT:   %Copy.facet.b97: %Copy.type = facet_value %IntOrBytes, (%custom_witness.bab) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.c4f: type = fn_type @Copy.WithSelf.Op.1, @Copy.WithSelf(%Copy.facet.b97) [concrete]
// CHECK:STDOUT:   %.2da: type = fn_type_with_self_type %Copy.WithSelf.Op.type.c4f, %Copy.facet.b97 [concrete]
// CHECK:STDOUT:   %int_3.1ba: Core.IntLiteral = int_value 3 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.485: <bound method> = bound_method %int_3.1ba, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.763: <bound method> = bound_method %int_3.1ba, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_3.410: %i32 = int_value 3 [concrete]
// CHECK:STDOUT:   %self.param_patt.705: %pattern_type.6b6 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.70d: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt.705 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc13_3.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.1: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.1: type = fn_type @Destroy.WithSelf.Op.loc13_3.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.1: %Destroy.WithSelf.Op.type.ef016f.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.1: type = fn_type @Destroy.WithSelf.SelfDestruct.loc13_3.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.1: %Destroy.WithSelf.SelfDestruct.type.fbceb5.1 = struct_value () [concrete]
// CHECK:STDOUT:   %self.param_patt.6c8: %pattern_type.0cf = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.136: %pattern_type.0cf = wrapper_binding_pattern self, %self.param_patt.6c8 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc13_3.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.2: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.2: type = fn_type @Destroy.WithSelf.Op.loc13_3.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.2: %Destroy.WithSelf.Op.type.ef016f.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.2: type = fn_type @Destroy.WithSelf.SelfDestruct.loc13_3.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.2: %Destroy.WithSelf.SelfDestruct.type.fbceb5.2 = struct_value () [concrete]
// CHECK:STDOUT:   %self.param_patt.078: %pattern_type.9c7 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.d53: %pattern_type.9c7 = wrapper_binding_pattern self, %self.param_patt.078 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc13_3.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.3: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3 = struct_value () [concrete]
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.3: type = fn_type @Destroy.WithSelf.Op.loc13_3.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.3: %Destroy.WithSelf.Op.type.ef016f.3 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.3: type = fn_type @Destroy.WithSelf.SelfDestruct.loc13_3.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.3: %Destroy.WithSelf.SelfDestruct.type.fbceb5.3 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.cf0: type = pattern_type %.e9a [concrete]
// CHECK:STDOUT:   %self.param_patt.bc5: %pattern_type.cf0 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.928: %pattern_type.cf0 = wrapper_binding_pattern self, %self.param_patt.bc5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc13_3.4 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.4: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.4: type = fn_type @Destroy.WithSelf.Op.loc13_3.4 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.4: %Destroy.WithSelf.Op.type.ef016f.4 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.5: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc13_3.5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.5: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.5 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.5: type = fn_type @Destroy.WithSelf.Op.loc13_3.5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.5: %Destroy.WithSelf.Op.type.ef016f.5 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.5: type = fn_type @Destroy.WithSelf.SelfDestruct.loc13_3.5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.5: %Destroy.WithSelf.SelfDestruct.type.fbceb5.5 = struct_value () [concrete]
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
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.1: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc13_3.1 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.1] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6b6 = ref_param_pattern [concrete = constants.%self.param_patt.705]
// CHECK:STDOUT:     %self.patt: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.70d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i32 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i32 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.1: %Destroy.WithSelf.Op.type.ef016f.1 = fn_decl @Destroy.WithSelf.Op.loc13_3.1 [concrete = constants.%Destroy.WithSelf.Op.403171.1] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6b6 = ref_param_pattern [concrete = constants.%self.param_patt.705]
// CHECK:STDOUT:     %self.patt: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.70d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i32 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i32 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.2: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc13_3.2 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.2] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.0cf = ref_param_pattern [concrete = constants.%self.param_patt.6c8]
// CHECK:STDOUT:     %self.patt: %pattern_type.0cf = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.136]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i8 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i8 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.2: %Destroy.WithSelf.Op.type.ef016f.2 = fn_decl @Destroy.WithSelf.Op.loc13_3.2 [concrete = constants.%Destroy.WithSelf.Op.403171.2] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.0cf = ref_param_pattern [concrete = constants.%self.param_patt.6c8]
// CHECK:STDOUT:     %self.patt: %pattern_type.0cf = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.136]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i8 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i8 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.3: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc13_3.3 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.3] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.9c7 = ref_param_pattern [concrete = constants.%self.param_patt.078]
// CHECK:STDOUT:     %self.patt: %pattern_type.9c7 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.d53]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %array_type = ref_param call_param0
// CHECK:STDOUT:     %self: ref %array_type = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.3: %Destroy.WithSelf.Op.type.ef016f.3 = fn_decl @Destroy.WithSelf.Op.loc13_3.3 [concrete = constants.%Destroy.WithSelf.Op.403171.3] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.9c7 = ref_param_pattern [concrete = constants.%self.param_patt.078]
// CHECK:STDOUT:     %self.patt: %pattern_type.9c7 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.d53]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %array_type = ref_param call_param0
// CHECK:STDOUT:     %self: ref %array_type = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.4: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc13_3.4 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.4] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.cf0 = ref_param_pattern [concrete = constants.%self.param_patt.bc5]
// CHECK:STDOUT:     %self.patt: %pattern_type.cf0 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.928]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %.e9a = ref_param call_param0
// CHECK:STDOUT:     %self: ref %.e9a = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.4: %Destroy.WithSelf.Op.type.ef016f.4 = fn_decl @Destroy.WithSelf.Op.loc13_3.4 [concrete = constants.%Destroy.WithSelf.Op.403171.4] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.cf0 = ref_param_pattern [concrete = constants.%self.param_patt.bc5]
// CHECK:STDOUT:     %self.patt: %pattern_type.cf0 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.928]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %.e9a = ref_param call_param0
// CHECK:STDOUT:     %self: ref %.e9a = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.5: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.5 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc13_3.5 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.5] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.970 = ref_param_pattern [concrete = constants.%self.param_patt.453]
// CHECK:STDOUT:     %self.patt: %pattern_type.970 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.e2e]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %IntOrBytes = ref_param call_param0
// CHECK:STDOUT:     %self: ref %IntOrBytes = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.5: %Destroy.WithSelf.Op.type.ef016f.5 = fn_decl @Destroy.WithSelf.Op.loc13_3.5 [concrete = constants.%Destroy.WithSelf.Op.403171.5] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.970 = ref_param_pattern [concrete = constants.%self.param_patt.453]
// CHECK:STDOUT:     %self.patt: %pattern_type.970 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.e2e]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %IntOrBytes = ref_param call_param0
// CHECK:STDOUT:     %self: ref %IntOrBytes = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
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
// CHECK:STDOUT:   %field_decl.loc5: %IntOrBytes.elem.a3f = field_decl word, element0, %i32 in [concrete] {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %field_decl.loc6: %IntOrBytes.elem.ff6 = field_decl bytes, element1, %array_type in [concrete] {
// CHECK:STDOUT:     %i8: type = type_literal constants.%i8 [concrete = constants.%i8]
// CHECK:STDOUT:     %int_4: Core.IntLiteral = int_value 4 [concrete = constants.%int_4]
// CHECK:STDOUT:     %array_type: type = array_type %int_4, %i8 [concrete = constants.%array_type]
// CHECK:STDOUT:   }
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
// CHECK:STDOUT:   %.loc10: type = custom_layout_type {size=4, align=4, .word@0: %i32, .bytes@0: %array_type} [concrete = constants.%.e9a]
// CHECK:STDOUT:   %complete_type: <witness> = complete_type_witness %.loc10 [concrete = constants.%complete_type.57b]
// CHECK:STDOUT:   complete_type_witness = %complete_type
// CHECK:STDOUT:
// CHECK:STDOUT: !members:
// CHECK:STDOUT:   .Self = constants.%IntOrBytes
// CHECK:STDOUT:   .word = %field_decl.loc5
// CHECK:STDOUT:   .bytes = %field_decl.loc6
// CHECK:STDOUT:   .LowHalf = %IntOrBytes.LowHalf.decl
// CHECK:STDOUT:   .Set = %IntOrBytes.Set.decl
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @IntOrBytes.LowHalf(%self.param: %IntOrBytes) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %self.ref: %IntOrBytes = name_ref self, %self
// CHECK:STDOUT:   %bytes.ref: %IntOrBytes.elem.ff6 = name_ref bytes, @IntOrBytes.%field_decl.loc6 [concrete = @IntOrBytes.%field_decl.loc6]
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
// CHECK:STDOUT:   %word.ref: %IntOrBytes.elem.a3f = name_ref word, @IntOrBytes.%field_decl.loc5 [concrete = @IntOrBytes.%field_decl.loc5]
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
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:   %impl.elem0.loc13: %.2da = impl_witness_access constants.%custom_witness.bab, element0 [concrete = constants.%Copy.WithSelf.Op.416]
// CHECK:STDOUT:   %bound_method.loc13: <bound method> = bound_method %u.ref, %impl.elem0.loc13
// CHECK:STDOUT:   %.loc13: ref %IntOrBytes = splice_block %v.var {}
// CHECK:STDOUT:   %Copy.WithSelf.Op.call: init %IntOrBytes to %.loc13 = call %bound_method.loc13(%u.ref)
// CHECK:STDOUT:   assign %v.var, %Copy.WithSelf.Op.call
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
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound: <bound method> = bound_method %v.var, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.5
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound(%v.var)
// CHECK:STDOUT:   return %IntOrBytes.LowHalf.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc13_3.1(%self.param: ref %i32) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc13_3.1(%self.param: ref %i32) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc13_3.1(%self.param: ref %i32) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.1(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.1(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc13_3.2(%self.param: ref %i8) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc13_3.2(%self.param: ref %i8) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc13_3.2(%self.param: ref %i8) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.2(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.2(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc13_3.3(%self.param: ref %array_type) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %int_3: Core.IntLiteral = int_value 3 [concrete = constants.%int_3.1ba]
// CHECK:STDOUT:   %.loc13_3.1: ref %i8 = array_index %self.param, %int_3
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc13_3.1: <bound method> = bound_method %.loc13_3.1, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc13_3.1: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc13_3.1(%.loc13_3.1)
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2]
// CHECK:STDOUT:   %.loc13_3.2: ref %i8 = array_index %self.param, %int_2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc13_3.2: <bound method> = bound_method %.loc13_3.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc13_3.2: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc13_3.2(%.loc13_3.2)
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1]
// CHECK:STDOUT:   %.loc13_3.3: ref %i8 = array_index %self.param, %int_1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc13_3.3: <bound method> = bound_method %.loc13_3.3, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc13_3.3: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc13_3.3(%.loc13_3.3)
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %.loc13_3.4: ref %i8 = array_index %self.param, %int_0
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc13_3.4: <bound method> = bound_method %.loc13_3.4, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc13_3.4: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc13_3.4(%.loc13_3.4)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc13_3.3(%self.param: ref %array_type) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc13_3.3(%self.param: ref %array_type) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.3(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.3(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc13_3.4(%self.param: ref %.e9a) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc13_3.4(%self.param: ref %.e9a) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc13_3.4(%self.param: ref %.e9a) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.4(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.4(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc13_3.5(%self.param: ref %IntOrBytes) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %bytes.ref: %IntOrBytes.elem.ff6 = name_ref bytes, @IntOrBytes.%field_decl.loc6 [concrete = @IntOrBytes.%field_decl.loc6]
// CHECK:STDOUT:   %.loc13_3.1: ref %array_type = class_element_access %self.param, element1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc13_3.1: <bound method> = bound_method %.loc13_3.1, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.3
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc13_3.1: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc13_3.1(%.loc13_3.1)
// CHECK:STDOUT:   %word.ref: %IntOrBytes.elem.a3f = name_ref word, @IntOrBytes.%field_decl.loc5 [concrete = @IntOrBytes.%field_decl.loc5]
// CHECK:STDOUT:   %.loc13_3.2: ref %i32 = class_element_access %self.param, element0
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc13_3.2: <bound method> = bound_method %.loc13_3.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc13_3.2: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc13_3.2(%.loc13_3.2)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc13_3.5(%self.param: ref %IntOrBytes) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc13_3.5(%self.param: ref %IntOrBytes) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.5(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.5(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- impl_member.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
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
// CHECK:STDOUT:   %.784: type = custom_layout_type {size=4, align=4, .a@0: %i32} [concrete]
// CHECK:STDOUT:   %complete_type.b3f: <witness> = complete_type_witness %.784 [concrete]
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
// CHECK:STDOUT:   %field_decl: %WithImpl.elem = field_decl a, element0, %i32 in [concrete] {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   impl_decl @WithImpl.as.I.impl [concrete] {} {
// CHECK:STDOUT:     %Self.ref: type = name_ref Self, constants.%WithImpl [concrete = constants.%WithImpl]
// CHECK:STDOUT:     %I.ref: type = name_ref I, file.%I.decl [concrete = constants.%I.type]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %.loc14: <witness> = impl_self_witness @WithImpl.as.I.impl.%Self.ref, @I [concrete = constants.%.4b6]
// CHECK:STDOUT:   %.loc17: type = custom_layout_type {size=4, align=4, .a@0: %i32} [concrete = constants.%.784]
// CHECK:STDOUT:   %complete_type: <witness> = complete_type_witness %.loc17 [concrete = constants.%complete_type.b3f]
// CHECK:STDOUT:   complete_type_witness = %complete_type
// CHECK:STDOUT:
// CHECK:STDOUT: !members:
// CHECK:STDOUT:   .Self = constants.%WithImpl
// CHECK:STDOUT:   .a = %field_decl
// CHECK:STDOUT:   .I = <poisoned>
// CHECK:STDOUT:   .Get = <poisoned>
// CHECK:STDOUT:   extend @WithImpl.as.I.impl.%I.ref
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @WithImpl.as.I.impl.Get(%self.param: %WithImpl) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %self.ref: %WithImpl = name_ref self, %self
// CHECK:STDOUT:   %a.ref: %WithImpl.elem = name_ref a, @WithImpl.%field_decl [concrete = @WithImpl.%field_decl]
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
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %U.951: type = class_type @U [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %U.elem: type = unbound_element_type %U.951, %i32 [concrete]
// CHECK:STDOUT:   %.784: type = custom_layout_type {size=4, align=4, .a@0: %i32} [concrete]
// CHECK:STDOUT:   %complete_type.b3f: <witness> = complete_type_witness %.784 [concrete]
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
// CHECK:STDOUT:   %field_decl: %U.elem = field_decl a, element0, %i32 in [concrete] {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %.loc10: type = custom_layout_type {size=4, align=4, .a@0: %i32} [concrete = constants.%.784]
// CHECK:STDOUT:   %complete_type: <witness> = complete_type_witness %.loc10 [concrete = constants.%complete_type.b3f]
// CHECK:STDOUT:   complete_type_witness = %complete_type
// CHECK:STDOUT:
// CHECK:STDOUT: !members:
// CHECK:STDOUT:   .Self = constants.%U.951
// CHECK:STDOUT:   .a = %field_decl
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @UseU(%u.param: %U.951) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %u.ref: %U.951 = name_ref u, %u
// CHECK:STDOUT:   %a.ref: %U.elem = name_ref a, @U.%field_decl [concrete = @U.%field_decl]
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
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %C: type = class_type @C [concrete]
// CHECK:STDOUT:   %Inner: type = class_type @Inner [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %Inner.elem: type = unbound_element_type %Inner, %i32 [concrete]
// CHECK:STDOUT:   %.784: type = custom_layout_type {size=4, align=4, .a@0: %i32} [concrete]
// CHECK:STDOUT:   %complete_type.b3f: <witness> = complete_type_witness %.784 [concrete]
// CHECK:STDOUT:   %C.elem: type = unbound_element_type %C, %Inner [concrete]
// CHECK:STDOUT:   %struct_type.u.a57: type = struct_type {.u: %Inner} [concrete]
// CHECK:STDOUT:   %complete_type.e2c: <witness> = complete_type_witness %struct_type.u.a57 [concrete]
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
// CHECK:STDOUT:   %field_decl: %C.elem = field_decl u, element0, %Inner.ref in [concrete] {
// CHECK:STDOUT:     %Inner.ref: type = name_ref Inner, %Inner.decl [concrete = constants.%Inner]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %complete_type: <witness> = complete_type_witness constants.%struct_type.u.a57 [concrete = constants.%complete_type.e2c]
// CHECK:STDOUT:   complete_type_witness = %complete_type
// CHECK:STDOUT:
// CHECK:STDOUT: !members:
// CHECK:STDOUT:   .Self = constants.%C
// CHECK:STDOUT:   .Inner = %Inner.decl
// CHECK:STDOUT:   .u = %field_decl
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: class @Inner {
// CHECK:STDOUT:   %field_decl: %Inner.elem = field_decl a, element0, %i32 in [concrete] {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %.loc7: type = custom_layout_type {size=4, align=4, .a@0: %i32} [concrete = constants.%.784]
// CHECK:STDOUT:   %complete_type: <witness> = complete_type_witness %.loc7 [concrete = constants.%complete_type.b3f]
// CHECK:STDOUT:   complete_type_witness = %complete_type
// CHECK:STDOUT:
// CHECK:STDOUT: !members:
// CHECK:STDOUT:   .Self = constants.%Inner
// CHECK:STDOUT:   .a = %field_decl
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @UseInner(%c.param: %C) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %c.ref: %C = name_ref c, %c
// CHECK:STDOUT:   %u.ref: %C.elem = name_ref u, @C.%field_decl [concrete = @C.%field_decl]
// CHECK:STDOUT:   %.loc11_36.1: ref %Inner = class_element_access %c.ref, element0
// CHECK:STDOUT:   %.loc11_36.2: %Inner = acquire_value %.loc11_36.1
// CHECK:STDOUT:   %a.ref: %Inner.elem = name_ref a, @Inner.%field_decl [concrete = @Inner.%field_decl]
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
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %U.e8a: type = class_type @U [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %U.elem: type = unbound_element_type %U.e8a, %i32 [concrete]
// CHECK:STDOUT:   %.784: type = custom_layout_type {size=4, align=4, .a@0: %i32} [concrete]
// CHECK:STDOUT:   %complete_type.b3f: <witness> = complete_type_witness %.784 [concrete]
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
// CHECK:STDOUT:   %field_decl: %U.elem = field_decl a, element0, %i32 in [concrete] {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %.loc8: type = custom_layout_type {size=4, align=4, .a@0: %i32} [concrete = constants.%.784]
// CHECK:STDOUT:   %complete_type: <witness> = complete_type_witness %.loc8 [concrete = constants.%complete_type.b3f]
// CHECK:STDOUT:   complete_type_witness = %complete_type
// CHECK:STDOUT:
// CHECK:STDOUT: !members:
// CHECK:STDOUT:   .Self = constants.%U.e8a
// CHECK:STDOUT:   .a = %field_decl
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @UseNU(%u.param: %U.e8a) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %u.ref: %U.e8a = name_ref u, %u
// CHECK:STDOUT:   %a.ref: %U.elem = name_ref a, @U.%field_decl [concrete = @U.%field_decl]
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
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %U.951: type = class_type @U [concrete]
// CHECK:STDOUT:   %U.elem: type = unbound_element_type %U.951, %i32 [concrete]
// CHECK:STDOUT:   %.784: type = custom_layout_type {size=4, align=4, .a@0: %i32} [concrete]
// CHECK:STDOUT:   %complete_type.b3f: <witness> = complete_type_witness %.784 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %U.decl: type = class_decl @U [concrete = constants.%U.951] {} {}
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: class @U {
// CHECK:STDOUT:   %field_decl: %U.elem = field_decl a, element0, %i32 in [concrete] {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %.loc14: type = custom_layout_type {size=4, align=4, .a@0: %i32} [concrete = constants.%.784]
// CHECK:STDOUT:   %complete_type: <witness> = complete_type_witness %.loc14 [concrete = constants.%complete_type.b3f]
// CHECK:STDOUT:   complete_type_witness = %complete_type
// CHECK:STDOUT:
// CHECK:STDOUT: !members:
// CHECK:STDOUT:   .Self = constants.%U.951
// CHECK:STDOUT:   .a = %field_decl
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- file_scope_designated.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %IntOrBytes: type = class_type @IntOrBytes [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.970: type = pattern_type %IntOrBytes [concrete]
// CHECK:STDOUT:   %g.patt: %pattern_type.970 = ref_binding_pattern g [concrete]
// CHECK:STDOUT:   %g.var_patt: %pattern_type.970 = var_pattern %g.patt [concrete]
// CHECK:STDOUT:   %int_5.64b: Core.IntLiteral = int_value 5 [concrete]
// CHECK:STDOUT:   %struct_type.word: type = struct_type {.word: Core.IntLiteral} [concrete]
// CHECK:STDOUT:   %struct: %struct_type.word = struct_value (%int_5.64b) [concrete]
// CHECK:STDOUT:   %.fa8: ref %i32 = class_element_access file.%g.var, element0 [concrete]
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
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound: <bound method> = bound_method %int_5.64b, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method: <bound method> = bound_method %int_5.64b, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_5.eef: %i32 = int_value 5 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
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
// CHECK:STDOUT:   %int_5: Core.IntLiteral = int_value 5 [concrete = constants.%int_5.64b]
// CHECK:STDOUT:   %.loc11_31.1: %struct_type.word = struct_literal (%int_5) [concrete = constants.%struct]
// CHECK:STDOUT:   %impl.elem0: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc11_31.1: <bound method> = bound_method %int_5, %impl.elem0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound]
// CHECK:STDOUT:   %specific_fn: <specific function> = specific_function %impl.elem0, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc11_31.2: <bound method> = bound_method %int_5, %specific_fn [concrete = constants.%bound_method]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %i32 = call %bound_method.loc11_31.2(%int_5) [concrete = constants.%int_5.eef]
// CHECK:STDOUT:   %.loc11_31.2: init %i32 = converted %int_5, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_5.eef]
// CHECK:STDOUT:   %.loc11_31.3: ref %i32 = class_element_access file.%g.var, element0 [concrete = constants.%.fa8]
// CHECK:STDOUT:   %.loc11_31.4: init %i32 to %.loc11_31.3 = in_place_init %.loc11_31.2 [concrete = constants.%int_5.eef]
// CHECK:STDOUT:   %.loc11_31.5: init %IntOrBytes to file.%g.var = class_init (%.loc11_31.4)
// CHECK:STDOUT:   %.loc11_1: init %IntOrBytes = converted %.loc11_31.1, %.loc11_31.5
// CHECK:STDOUT:   assign file.%g.var, %.loc11_1
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- raw_identifier.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
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
// CHECK:STDOUT:   %self.param_patt.705: %pattern_type.6b6 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.70d: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt.705 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfc: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc6 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01: %Destroy.WithSelf.SubobjectDestroy.type.dfc = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef0: type = fn_type @Destroy.WithSelf.Op.loc6 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403: %Destroy.WithSelf.Op.type.ef0 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbc: type = fn_type @Destroy.WithSelf.SelfDestruct.loc6 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3: %Destroy.WithSelf.SelfDestruct.type.fbc = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl: %Destroy.WithSelf.SubobjectDestroy.type.dfc = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc6 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6b6 = ref_param_pattern [concrete = constants.%self.param_patt.705]
// CHECK:STDOUT:     %self.patt: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.70d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i32 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i32 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl: %Destroy.WithSelf.Op.type.ef0 = fn_decl @Destroy.WithSelf.Op.loc6 [concrete = constants.%Destroy.WithSelf.Op.403] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6b6 = ref_param_pattern [concrete = constants.%self.param_patt.705]
// CHECK:STDOUT:     %self.patt: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.70d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i32 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i32 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
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
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound: <bound method> = bound_method %union.var, constants.%Destroy.WithSelf.SelfDestruct.db3
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound(%union.var)
// CHECK:STDOUT:   return %Int.as.Copy.impl.Op.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc6(%self.param: ref %i32) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc6(%self.param: ref %i32) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc6(%self.param: ref %i32) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- nested_union_field.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %IntOrBytes: type = class_type @IntOrBytes [concrete]
// CHECK:STDOUT:   %Outer: type = class_type @Outer [concrete]
// CHECK:STDOUT:   %Outer.elem.1b0: type = unbound_element_type %Outer, %IntOrBytes [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %Outer.elem.528: type = unbound_element_type %Outer, %i64 [concrete]
// CHECK:STDOUT:   %.6cd: type = custom_layout_type {size=8, align=8, .inner@0: %IntOrBytes, .w@0: %i64} [concrete]
// CHECK:STDOUT:   %complete_type.136: <witness> = complete_type_witness %.6cd [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Outer.decl: type = class_decl @Outer [concrete = constants.%Outer] {} {}
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: class @Outer {
// CHECK:STDOUT:   %field_decl.loc12: %Outer.elem.1b0 = field_decl inner, element0, %IntOrBytes.ref in [concrete] {
// CHECK:STDOUT:     %IntOrBytes.ref: type = name_ref IntOrBytes, file.%IntOrBytes.decl [concrete = constants.%IntOrBytes]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %field_decl.loc13: %Outer.elem.528 = field_decl w, element1, %i64 in [concrete] {
// CHECK:STDOUT:     %i64: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %.loc14: type = custom_layout_type {size=8, align=8, .inner@0: %IntOrBytes, .w@0: %i64} [concrete = constants.%.6cd]
// CHECK:STDOUT:   %complete_type: <witness> = complete_type_witness %.loc14 [concrete = constants.%complete_type.136]
// CHECK:STDOUT:   complete_type_witness = %complete_type
// CHECK:STDOUT:
// CHECK:STDOUT: !members:
// CHECK:STDOUT:   .Self = constants.%Outer
// CHECK:STDOUT:   .IntOrBytes = <poisoned>
// CHECK:STDOUT:   .inner = %field_decl.loc12
// CHECK:STDOUT:   .w = %field_decl.loc13
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- aggregate_fields.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %Aggregates: type = class_type @Aggregates [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %Int.type: type = generic_class_type @Int [concrete]
// CHECK:STDOUT:   %Int.generic: %Int.type = struct_value () [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %struct_type.a.b: type = struct_type {.a: %i32, .b: %i32} [concrete]
// CHECK:STDOUT:   %Aggregates.elem.431: type = unbound_element_type %Aggregates, %struct_type.a.b [concrete]
// CHECK:STDOUT:   %int_16: Core.IntLiteral = int_value 16 [concrete]
// CHECK:STDOUT:   %i16: type = class_type @Int, @Int(%int_16) [concrete]
// CHECK:STDOUT:   %tuple.type.693: type = tuple_type (type, type) [concrete]
// CHECK:STDOUT:   %tuple: %tuple.type.693 = tuple_value (%i32, %i16) [concrete]
// CHECK:STDOUT:   %tuple.type.7d4: type = tuple_type (%i32, %i16) [concrete]
// CHECK:STDOUT:   %Aggregates.elem.4f3: type = unbound_element_type %Aggregates, %tuple.type.7d4 [concrete]
// CHECK:STDOUT:   %ptr.d08: type = ptr_type %i32 [concrete]
// CHECK:STDOUT:   %Aggregates.elem.9b1: type = unbound_element_type %Aggregates, %ptr.d08 [concrete]
// CHECK:STDOUT:   %Aggregates.elem.0bd: type = unbound_element_type %Aggregates, bool [concrete]
// CHECK:STDOUT:   %char: type = class_type @Char [concrete]
// CHECK:STDOUT:   %Aggregates.elem.57d: type = unbound_element_type %Aggregates, %char [concrete]
// CHECK:STDOUT:   %str: type = class_type @String [concrete]
// CHECK:STDOUT:   %Aggregates.elem.32a: type = unbound_element_type %Aggregates, %str [concrete]
// CHECK:STDOUT:   %.f0d: type = custom_layout_type {size=16, align=8, .s@0: %struct_type.a.b, .t@0: %tuple.type.7d4, .p@0: %ptr.d08, .b@0: bool, .c@0: %char, .text@0: %str, .literal_text@0: %str} [concrete]
// CHECK:STDOUT:   %complete_type.59a: <witness> = complete_type_witness %.f0d [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .Int = %Core.Int
// CHECK:STDOUT:     .Bool = %Core.Bool
// CHECK:STDOUT:     .Char = %Core.Char
// CHECK:STDOUT:     .String = %Core.String
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Int: %Int.type = import_ref Core//prelude/types/int, Int, loaded [concrete = constants.%Int.generic]
// CHECK:STDOUT:   %Core.Bool: type = import_ref Core//prelude/types/bool, Bool, loaded [concrete = bool]
// CHECK:STDOUT:   %Core.Char: type = import_ref Core//prelude/types/char, Char, loaded [concrete = constants.%char]
// CHECK:STDOUT:   %Core.String: type = import_ref Core//prelude/types/string, String, loaded [concrete = constants.%str]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Aggregates.decl: type = class_decl @Aggregates [concrete = constants.%Aggregates] {} {}
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: class @Aggregates {
// CHECK:STDOUT:   %field_decl.loc7: %Aggregates.elem.431 = field_decl s, element0, %struct_type.a.b in [concrete] {
// CHECK:STDOUT:     %i32.loc7_15: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %i32.loc7_24: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %struct_type.a.b: type = struct_type {.a: %i32, .b: %i32} [concrete = constants.%struct_type.a.b]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %field_decl.loc8: %Aggregates.elem.4f3 = field_decl t, element1, %.loc8_19.2 in [concrete] {
// CHECK:STDOUT:     %i32.loc8: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %i16: type = type_literal constants.%i16 [concrete = constants.%i16]
// CHECK:STDOUT:     %.loc8_19.1: %tuple.type.693 = tuple_literal (%i32.loc8, %i16) [concrete = constants.%tuple]
// CHECK:STDOUT:     %.loc8_19.2: type = converted %.loc8_19.1, constants.%tuple.type.7d4 [concrete = constants.%tuple.type.7d4]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %field_decl.loc9: %Aggregates.elem.9b1 = field_decl p, element2, %ptr in [concrete] {
// CHECK:STDOUT:     %i32.loc9: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %ptr: type = ptr_type %i32.loc9 [concrete = constants.%ptr.d08]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %field_decl.loc10: %Aggregates.elem.0bd = field_decl b, element3, %.loc10 in [concrete] {
// CHECK:STDOUT:     %.loc10: type = type_literal bool [concrete = bool]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %field_decl.loc11: %Aggregates.elem.57d = field_decl c, element4, %char in [concrete] {
// CHECK:STDOUT:     %char: type = type_literal constants.%char [concrete = constants.%char]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %field_decl.loc12: %Aggregates.elem.32a = field_decl text, element5, %String.ref in [concrete] {
// CHECK:STDOUT:     %Core.ref: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:     %String.ref: type = name_ref String, imports.%Core.String [concrete = constants.%str]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %field_decl.loc13: %Aggregates.elem.32a = field_decl literal_text, element6, %str in [concrete] {
// CHECK:STDOUT:     %str: type = type_literal constants.%str [concrete = constants.%str]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %.loc14: type = custom_layout_type {size=16, align=8, .s@0: %struct_type.a.b, .t@0: %tuple.type.7d4, .p@0: %ptr.d08, .b@0: bool, .c@0: %char, .text@0: %str, .literal_text@0: %str} [concrete = constants.%.f0d]
// CHECK:STDOUT:   %complete_type: <witness> = complete_type_witness %.loc14 [concrete = constants.%complete_type.59a]
// CHECK:STDOUT:   complete_type_witness = %complete_type
// CHECK:STDOUT:
// CHECK:STDOUT: !members:
// CHECK:STDOUT:   .Self = constants.%Aggregates
// CHECK:STDOUT:   .s = %field_decl.loc7
// CHECK:STDOUT:   .t = %field_decl.loc8
// CHECK:STDOUT:   .p = %field_decl.loc9
// CHECK:STDOUT:   .b = %field_decl.loc10
// CHECK:STDOUT:   .c = %field_decl.loc11
// CHECK:STDOUT:   .text = %field_decl.loc12
// CHECK:STDOUT:   .literal_text = %field_decl.loc13
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- optional_pointer_field.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %OptPtr: type = class_type @OptPtr [concrete]
// CHECK:STDOUT:   %Optional.type: type = generic_class_type @Optional [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %Optional.generic: %Optional.type = struct_value () [concrete]
// CHECK:STDOUT:   %OptionalStorage.type: type = facet_type <@OptionalStorage> [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %Int.type: type = generic_class_type @Int [concrete]
// CHECK:STDOUT:   %Int.generic: %Int.type = struct_value () [concrete]
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
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1: type = fn_type @Destroy.WithSelf.SubobjectDestroy.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.1: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.1: type = fn_type @Destroy.WithSelf.Op.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.1: %Destroy.WithSelf.Op.type.ef016f.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.1: type = fn_type @Destroy.WithSelf.SelfDestruct.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.1: %Destroy.WithSelf.SelfDestruct.type.fbceb5.1 = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.f8f19d.1: <witness> = custom_witness (%Destroy.WithSelf.Op.403171.1, %Destroy.WithSelf.SubobjectDestroy.d01daf.1, %Destroy.WithSelf.SelfDestruct.db3fdb.1), @Destroy [concrete]
// CHECK:STDOUT:   %Destroy.facet.4ee: %Destroy.type = facet_value %ptr.d08, (%custom_witness.f8f19d.1) [concrete]
// CHECK:STDOUT:   %MaybeUnformed.729: type = class_type @MaybeUnformed, @MaybeUnformed(%Destroy.facet.4ee) [concrete]
// CHECK:STDOUT:   %OptionalStorage.impl_witness.0ce: <witness> = impl_witness imports.%OptionalStorage.impl_witness_table.110, @ptr.as.OptionalStorage.impl(%i32) [concrete]
// CHECK:STDOUT:   %.0f8: type = maybe_unformed_type %ptr.d08 [concrete]
// CHECK:STDOUT:   %OptionalStorage.facet: %OptionalStorage.type = facet_value %ptr.d08, (%OptionalStorage.impl_witness.0ce) [concrete]
// CHECK:STDOUT:   %Optional.5b3: type = class_type @Optional, @Optional(%OptionalStorage.facet) [concrete]
// CHECK:STDOUT:   %pattern_type.ef8: type = pattern_type %Optional.5b3 [concrete]
// CHECK:STDOUT:   %OptPtr.elem.4da: type = unbound_element_type %OptPtr, %Optional.5b3 [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %pattern_type.f57: type = pattern_type %i64 [concrete]
// CHECK:STDOUT:   %OptPtr.elem.d1b: type = unbound_element_type %OptPtr, %i64 [concrete]
// CHECK:STDOUT:   %.c2d: type = custom_layout_type {size=8, align=8, .o@0: %Optional.5b3, .n@0: %i64} [concrete]
// CHECK:STDOUT:   %complete_type.4a8: <witness> = complete_type_witness %.c2d [concrete]
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
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.7f5: type = fn_type @Copy.WithSelf.Op.2 [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.416: %Copy.WithSelf.Op.type.7f5 = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.bab: <witness> = custom_witness (%Copy.WithSelf.Op.416), @Copy [concrete]
// CHECK:STDOUT:   %Copy.facet.0b1: %Copy.type = facet_value %OptPtr, (%custom_witness.bab) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.f32: type = fn_type @Copy.WithSelf.Op.1, @Copy.WithSelf(%Copy.facet.0b1) [concrete]
// CHECK:STDOUT:   %.2e8: type = fn_type_with_self_type %Copy.WithSelf.Op.type.f32, %Copy.facet.0b1 [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.8cc: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_64) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.494: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_64) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.d73: %Int.as.Copy.impl.Op.type.494 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet.4e9: %Copy.type = facet_value %i64, (%Copy.impl_witness.8cc) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.5c1: type = fn_type @Copy.WithSelf.Op.1, @Copy.WithSelf(%Copy.facet.4e9) [concrete]
// CHECK:STDOUT:   %.826: type = fn_type_with_self_type %Copy.WithSelf.Op.type.5c1, %Copy.facet.4e9 [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.d73, @Int.as.Copy.impl.Op(%int_64) [concrete]
// CHECK:STDOUT:   %pattern_type.59d: type = pattern_type %.0f8 [concrete]
// CHECK:STDOUT:   %self.param_patt.9e1: %pattern_type.59d = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.8da: %pattern_type.59d = wrapper_binding_pattern self, %self.param_patt.9e1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc13_3.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.2: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.2: type = fn_type @Destroy.WithSelf.Op.loc13_3.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.2: %Destroy.WithSelf.Op.type.ef016f.2 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.6db: type = pattern_type %MaybeUnformed.729 [concrete]
// CHECK:STDOUT:   %self.param_patt.e99: %pattern_type.6db = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.e88: %pattern_type.6db = wrapper_binding_pattern self, %self.param_patt.e99 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc13_3.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.3: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.3: type = fn_type @Destroy.WithSelf.Op.loc13_3.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.3: %Destroy.WithSelf.Op.type.ef016f.3 = struct_value () [concrete]
// CHECK:STDOUT:   %self.param_patt.d96: %pattern_type.ef8 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.77d: %pattern_type.ef8 = wrapper_binding_pattern self, %self.param_patt.d96 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc13_3.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.4: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.4: type = fn_type @Destroy.WithSelf.Op.loc13_3.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.4: %Destroy.WithSelf.Op.type.ef016f.4 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.4: type = fn_type @Destroy.WithSelf.SelfDestruct.loc13_3.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.4: %Destroy.WithSelf.SelfDestruct.type.fbceb5.4 = struct_value () [concrete]
// CHECK:STDOUT:   %self.param_patt.108: %pattern_type.f57 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.5f4: %pattern_type.f57 = wrapper_binding_pattern self, %self.param_patt.108 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.5: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc13_3.4 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.5: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.5 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.5: type = fn_type @Destroy.WithSelf.Op.loc13_3.4 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.5: %Destroy.WithSelf.Op.type.ef016f.5 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.5: type = fn_type @Destroy.WithSelf.SelfDestruct.loc13_3.4 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.5: %Destroy.WithSelf.SelfDestruct.type.fbceb5.5 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.919: type = pattern_type %.c2d [concrete]
// CHECK:STDOUT:   %self.param_patt.a41: %pattern_type.919 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.77b: %pattern_type.919 = wrapper_binding_pattern self, %self.param_patt.a41 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.6: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc13_3.5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.6: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.6 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.6: type = fn_type @Destroy.WithSelf.Op.loc13_3.5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.6: %Destroy.WithSelf.Op.type.ef016f.6 = struct_value () [concrete]
// CHECK:STDOUT:   %self.param_patt.35c: %pattern_type.b17 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.440: %pattern_type.b17 = wrapper_binding_pattern self, %self.param_patt.35c [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.7: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc13_3.6 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.7: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.7 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.7: type = fn_type @Destroy.WithSelf.Op.loc13_3.6 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.7: %Destroy.WithSelf.Op.type.ef016f.7 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.7: type = fn_type @Destroy.WithSelf.SelfDestruct.loc13_3.6 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.7: %Destroy.WithSelf.SelfDestruct.type.fbceb5.7 = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .Optional = %Core.Optional
// CHECK:STDOUT:     .Int = %Core.Int
// CHECK:STDOUT:     .Copy = %Core.Copy.e5d
// CHECK:STDOUT:     .Destroy = %Core.Destroy
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Optional: %Optional.type = import_ref Core//prelude/types/optional, Optional, loaded [concrete = constants.%Optional.generic]
// CHECK:STDOUT:   %Core.Int: %Int.type = import_ref Core//prelude/types/int, Int, loaded [concrete = constants.%Int.generic]
// CHECK:STDOUT:   %Core.import_ref.509: type = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @ptr.as.OptionalStorage.impl.%MaybeUnformed (constants.%MaybeUnformed.ddb)]
// CHECK:STDOUT:   %Core.import_ref.105 = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.c9a = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.a90 = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.306 = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.3e3 = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %OptionalStorage.impl_witness_table.110 = impl_witness_table (%Core.import_ref.509, %Core.import_ref.105, %Core.import_ref.c9a, %Core.import_ref.a90, %Core.import_ref.306, %Core.import_ref.3e3), @ptr.as.OptionalStorage.impl [concrete]
// CHECK:STDOUT:   %Core.Copy.e5d: type = import_ref Core//prelude/copy, Copy, loaded [concrete = constants.%Copy.type]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.Destroy: type = import_ref Core//prelude/destroy, Destroy, loaded [concrete = constants.%Destroy.type]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.2: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc13_3.1 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.2] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.59d = ref_param_pattern [concrete = constants.%self.param_patt.9e1]
// CHECK:STDOUT:     %self.patt: %pattern_type.59d = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.8da]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %.0f8 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %.0f8 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.2: %Destroy.WithSelf.Op.type.ef016f.2 = fn_decl @Destroy.WithSelf.Op.loc13_3.1 [concrete = constants.%Destroy.WithSelf.Op.403171.2] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.59d = ref_param_pattern [concrete = constants.%self.param_patt.9e1]
// CHECK:STDOUT:     %self.patt: %pattern_type.59d = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.8da]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %.0f8 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %.0f8 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.3: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc13_3.2 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.3] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6db = ref_param_pattern [concrete = constants.%self.param_patt.e99]
// CHECK:STDOUT:     %self.patt: %pattern_type.6db = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.e88]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %MaybeUnformed.729 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %MaybeUnformed.729 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.3: %Destroy.WithSelf.Op.type.ef016f.3 = fn_decl @Destroy.WithSelf.Op.loc13_3.2 [concrete = constants.%Destroy.WithSelf.Op.403171.3] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6db = ref_param_pattern [concrete = constants.%self.param_patt.e99]
// CHECK:STDOUT:     %self.patt: %pattern_type.6db = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.e88]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %MaybeUnformed.729 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %MaybeUnformed.729 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.4: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc13_3.3 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.4] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.ef8 = ref_param_pattern [concrete = constants.%self.param_patt.d96]
// CHECK:STDOUT:     %self.patt: %pattern_type.ef8 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.77d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %Optional.5b3 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %Optional.5b3 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.4: %Destroy.WithSelf.Op.type.ef016f.4 = fn_decl @Destroy.WithSelf.Op.loc13_3.3 [concrete = constants.%Destroy.WithSelf.Op.403171.4] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.ef8 = ref_param_pattern [concrete = constants.%self.param_patt.d96]
// CHECK:STDOUT:     %self.patt: %pattern_type.ef8 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.77d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %Optional.5b3 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %Optional.5b3 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.5: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.5 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc13_3.4 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.5] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.f57 = ref_param_pattern [concrete = constants.%self.param_patt.108]
// CHECK:STDOUT:     %self.patt: %pattern_type.f57 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.5f4]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i64 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i64 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.5: %Destroy.WithSelf.Op.type.ef016f.5 = fn_decl @Destroy.WithSelf.Op.loc13_3.4 [concrete = constants.%Destroy.WithSelf.Op.403171.5] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.f57 = ref_param_pattern [concrete = constants.%self.param_patt.108]
// CHECK:STDOUT:     %self.patt: %pattern_type.f57 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.5f4]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i64 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i64 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.6: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.6 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc13_3.5 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.6] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.919 = ref_param_pattern [concrete = constants.%self.param_patt.a41]
// CHECK:STDOUT:     %self.patt: %pattern_type.919 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.77b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %.c2d = ref_param call_param0
// CHECK:STDOUT:     %self: ref %.c2d = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.6: %Destroy.WithSelf.Op.type.ef016f.6 = fn_decl @Destroy.WithSelf.Op.loc13_3.5 [concrete = constants.%Destroy.WithSelf.Op.403171.6] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.919 = ref_param_pattern [concrete = constants.%self.param_patt.a41]
// CHECK:STDOUT:     %self.patt: %pattern_type.919 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.77b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %.c2d = ref_param call_param0
// CHECK:STDOUT:     %self: ref %.c2d = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.7: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.7 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc13_3.6 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.7] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.b17 = ref_param_pattern [concrete = constants.%self.param_patt.35c]
// CHECK:STDOUT:     %self.patt: %pattern_type.b17 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.440]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %OptPtr = ref_param call_param0
// CHECK:STDOUT:     %self: ref %OptPtr = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.7: %Destroy.WithSelf.Op.type.ef016f.7 = fn_decl @Destroy.WithSelf.Op.loc13_3.6 [concrete = constants.%Destroy.WithSelf.Op.403171.7] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.b17 = ref_param_pattern [concrete = constants.%self.param_patt.35c]
// CHECK:STDOUT:     %self.patt: %pattern_type.b17 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.440]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %OptPtr = ref_param call_param0
// CHECK:STDOUT:     %self: ref %OptPtr = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
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
// CHECK:STDOUT:   %field_decl.loc8: %OptPtr.elem.4da = field_decl o, element0, %Optional in [concrete] {
// CHECK:STDOUT:     %Core.ref: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:     %Optional.ref: %Optional.type = name_ref Optional, imports.%Core.Optional [concrete = constants.%Optional.generic]
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %ptr: type = ptr_type %i32 [concrete = constants.%ptr.d08]
// CHECK:STDOUT:     %OptionalStorage.facet: %OptionalStorage.type = facet_value %ptr, (constants.%OptionalStorage.impl_witness.0ce) [concrete = constants.%OptionalStorage.facet]
// CHECK:STDOUT:     %.loc8: %OptionalStorage.type = converted %ptr, %OptionalStorage.facet [concrete = constants.%OptionalStorage.facet]
// CHECK:STDOUT:     %Optional: type = class_type @Optional, @Optional(constants.%OptionalStorage.facet) [concrete = constants.%Optional.5b3]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %field_decl.loc9: %OptPtr.elem.d1b = field_decl n, element1, %i64 in [concrete] {
// CHECK:STDOUT:     %i64: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %.loc10: type = custom_layout_type {size=8, align=8, .o@0: %Optional.5b3, .n@0: %i64} [concrete = constants.%.c2d]
// CHECK:STDOUT:   %complete_type: <witness> = complete_type_witness %.loc10 [concrete = constants.%complete_type.4a8]
// CHECK:STDOUT:   complete_type_witness = %complete_type
// CHECK:STDOUT:
// CHECK:STDOUT: !members:
// CHECK:STDOUT:   .Self = constants.%OptPtr
// CHECK:STDOUT:   .o = %field_decl.loc8
// CHECK:STDOUT:   .n = %field_decl.loc9
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @CopyOptPtr(%p.param: %OptPtr) -> out %return.param: %i64 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %q.var: ref %OptPtr = var_storage %q.var_patt
// CHECK:STDOUT:   %p.ref: %OptPtr = name_ref p, %p
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:   %impl.elem0.loc13: %.2e8 = impl_witness_access constants.%custom_witness.bab, element0 [concrete = constants.%Copy.WithSelf.Op.416]
// CHECK:STDOUT:   %bound_method.loc13: <bound method> = bound_method %p.ref, %impl.elem0.loc13
// CHECK:STDOUT:   %.loc13: ref %OptPtr = splice_block %q.var {}
// CHECK:STDOUT:   %Copy.WithSelf.Op.call: init %OptPtr to %.loc13 = call %bound_method.loc13(%p.ref)
// CHECK:STDOUT:   assign %q.var, %Copy.WithSelf.Op.call
// CHECK:STDOUT:   %OptPtr.ref.loc13: type = name_ref OptPtr, file.%OptPtr.decl [concrete = constants.%OptPtr]
// CHECK:STDOUT:   %q: ref %OptPtr = wrapper_binding q, %q.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %q.patt: %pattern_type.b17 = ref_binding_pattern q [concrete = constants.%q.patt]
// CHECK:STDOUT:     %q.var_patt: %pattern_type.b17 = var_pattern %q.patt [concrete = constants.%q.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %q.ref: ref %OptPtr = name_ref q, %q
// CHECK:STDOUT:   %n.ref: %OptPtr.elem.d1b = name_ref n, @OptPtr.%field_decl.loc9 [concrete = @OptPtr.%field_decl.loc9]
// CHECK:STDOUT:   %.loc14_11.1: ref %i64 = class_element_access %q.ref, element1
// CHECK:STDOUT:   %.loc14_11.2: %i64 = acquire_value %.loc14_11.1
// CHECK:STDOUT:   %impl.elem0.loc14: %.826 = impl_witness_access constants.%Copy.impl_witness.8cc, element0 [concrete = constants.%Int.as.Copy.impl.Op.d73]
// CHECK:STDOUT:   %bound_method.loc14_11.1: <bound method> = bound_method %.loc14_11.2, %impl.elem0.loc14
// CHECK:STDOUT:   %specific_fn: <specific function> = specific_function %impl.elem0.loc14, @Int.as.Copy.impl.Op(constants.%int_64) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc14_11.2: <bound method> = bound_method %.loc14_11.2, %specific_fn
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i64 = call %bound_method.loc14_11.2(%.loc14_11.2)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound: <bound method> = bound_method %q.var, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.7
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound(%q.var)
// CHECK:STDOUT:   return %Int.as.Copy.impl.Op.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc13_3.1(%self.param: ref %.0f8) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc13_3.1(%self.param: ref %.0f8) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc13_3.1(%self.param: ref %.0f8) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.2(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.2(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc13_3.2(%self.param: ref %MaybeUnformed.729) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc13_3.2(%self.param: ref %MaybeUnformed.729) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc13_3.2(%self.param: ref %MaybeUnformed.729) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.3(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.3(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc13_3.3(%self.param: ref %Optional.5b3) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc13_3.3(%self.param: ref %Optional.5b3) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc13_3.3(%self.param: ref %Optional.5b3) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.4(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.4(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc13_3.4(%self.param: ref %i64) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc13_3.4(%self.param: ref %i64) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc13_3.4(%self.param: ref %i64) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.5(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.5(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc13_3.5(%self.param: ref %.c2d) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc13_3.5(%self.param: ref %.c2d) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc13_3.5(%self.param: ref %.c2d) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.6(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.6(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc13_3.6(%self.param: ref %OptPtr) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %n.ref: %OptPtr.elem.d1b = name_ref n, @OptPtr.%field_decl.loc9 [concrete = @OptPtr.%field_decl.loc9]
// CHECK:STDOUT:   %.loc13_3.1: ref %i64 = class_element_access %self.param, element1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc13_3.1: <bound method> = bound_method %.loc13_3.1, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.5
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc13_3.1: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc13_3.1(%.loc13_3.1)
// CHECK:STDOUT:   %o.ref: %OptPtr.elem.4da = name_ref o, @OptPtr.%field_decl.loc8 [concrete = @OptPtr.%field_decl.loc8]
// CHECK:STDOUT:   %.loc13_3.2: ref %Optional.5b3 = class_element_access %self.param, element0
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc13_3.2: <bound method> = bound_method %.loc13_3.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.4
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc13_3.2: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc13_3.2(%.loc13_3.2)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc13_3.6(%self.param: ref %OptPtr) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc13_3.6(%self.param: ref %OptPtr) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.7(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.7(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
