// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/named_constraint/template_constraint_satisfy.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/named_constraint/template_constraint_satisfy.carbon

// Structural satisfaction of `template constraint` member requirements (fork
// decision F-010 / SC-1, fork/structural/plan.md D-SC-4, D-SC-5): a type
// satisfies the constraint through its OWN members, with no `impl`. The facet
// value carries no witnesses.

// --- method.carbon
library "[[@TEST_NAME]]";

template constraint HasGet {
  fn Get(self) -> i32;
}

class C {
  // CHECK:STDERR: method.carbon:[[@LINE+4]]:10: warning: binding `self` unused [UnusedBinding]
  // CHECK:STDERR:   fn Get(self) -> i32 { return 1; }
  // CHECK:STDERR:          ^~~~
  // CHECK:STDERR:
  fn Get(unused self) -> i32 { return 1; }
}

fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }

//@dump-sem-ir-begin
fn Test(c: C) -> i32 { return CallGet(c); }
//@dump-sem-ir-end

// --- ref_self.carbon
library "[[@TEST_NAME]]";

// A `ref self` requirement is satisfied by a `ref self` method, called on a
// `var` through a pointer.
template constraint HasGet {
  fn Get(ref self) -> i32;
}

class C {
  // CHECK:STDERR: ref_self.carbon:[[@LINE+4]]:10: warning: binding `self` unused [UnusedBinding]
  // CHECK:STDERR:   fn Get(ref self) -> i32 { return 1; }
  // CHECK:STDERR:          ^~~~~~~~
  // CHECK:STDERR:
  fn Get(unused ref self) -> i32 { return 1; }
}

fn CallGet[template T: HasGet](p: T*) -> i32 { return p->Get(); }

fn Test() -> i32 {
  var c: C = {};
  return CallGet(&c);
}

// --- assoc_fn.carbon
library "[[@TEST_NAME]]";

// An associated-function requirement (no `self`), satisfied by a class
// function whose return type is the class (`Self := C`).
template constraint HasMake {
  fn Make() -> Self;
}

class C {
  fn Make() -> C { return {}; }
}

//@dump-sem-ir-begin
fn MakeIt(template T: HasMake) -> T { return T.Make(); }

fn Test() -> C { return MakeIt(C); }
//@dump-sem-ir-end

// --- alias_member.carbon
library "[[@TEST_NAME]]";

// p002200's class `D`: an `alias` of an interface member resolves through the
// class's own `impl` to the impl's function, which satisfies the requirement
// (review fold A10: the member is an `ImplWitnessAccess`, not a `FunctionDecl`).
interface A {
  fn F(self);
}

template constraint HasF {
  fn F(self);
}

class D {
  impl as A {
    // CHECK:STDERR: alias_member.carbon:[[@LINE+4]]:10: warning: binding `self` unused [UnusedBinding]
    // CHECK:STDERR:     fn F(self) {}
    // CHECK:STDERR:          ^~~~
    // CHECK:STDERR:
    fn F(unused self) {}
  }
  alias F = A.F;
}

fn CallF[template T: HasF](x: T) { x.F(); }

fn Test(d: D) { CallF(d); }

// --- class_param.carbon
library "[[@TEST_NAME]]";

// The class-parameter site: the conversion of the class argument runs the
// check (review fold B6).
template constraint HasGet {
  fn Get(self) -> i32;
}

class C {
  // CHECK:STDERR: class_param.carbon:[[@LINE+4]]:10: warning: binding `self` unused [UnusedBinding]
  // CHECK:STDERR:   fn Get(self) -> i32 { return 1; }
  // CHECK:STDERR:          ^~~~
  // CHECK:STDERR:
  fn Get(unused self) -> i32 { return 1; }
}

class Box(template T: HasGet) {
  // CHECK:STDERR: class_param.carbon:[[@LINE+4]]:11: warning: binding `self` unused [UnusedBinding]
  // CHECK:STDERR:   fn Call(self, x: T) -> i32 { return x.Get(); }
  // CHECK:STDERR:           ^~~~
  // CHECK:STDERR:
  fn Call(unused self, x: T) -> i32 { return x.Get(); }
}

//@dump-sem-ir-begin
fn Test(c: C) -> i32 {
  var b: Box(C) = {};
  return b.Call(c);
}
//@dump-sem-ir-end

// --- generic_self.carbon
library "[[@TEST_NAME]]";

// A member of a GENERIC class specific (commit-2 review, MAJOR finding):
// `Box(i32).Get` declares `self: Box(T)`, and the matcher reads it in the
// member's own specific, formed from the arguments of its enclosing specific
// `Box(i32)`, so that it equals the requirement's `Self := Box(i32)`. Spelling
// from class/method/generic_method.carbon.
template constraint HasGet {
  fn Get(self) -> i32;
}

class Box(T: type) {
  // CHECK:STDERR: generic_self.carbon:[[@LINE+4]]:10: warning: binding `self` unused [UnusedBinding]
  // CHECK:STDERR:   fn Get(self) -> i32 { return 1; }
  // CHECK:STDERR:          ^~~~
  // CHECK:STDERR:
  fn Get(unused self) -> i32 { return 1; }
}

fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }

fn Test(b: Box(i32)) -> i32 { return CallGet(b); }

// --- nested_generic.carbon
library "[[@TEST_NAME]]";

// A member of a class nested in a generic class (fill round 2, review finding
// MINOR-4): `Outer(i32).Inner(bool).Get` is generic over both classes'
// parameters, and its own specific is formed from the arguments of
// `Outer(i32).Inner(bool)`.
template constraint HasGet {
  fn Get(self) -> i32;
}

class Outer(T: type) {
  class Inner(U: type) {
    fn Get(unused self) -> i32 { return 1; }
  }
}

fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }

fn Test(b: Outer(i32).Inner(bool)) -> i32 { return CallGet(b); }

// --- as_facet.carbon
library "[[@TEST_NAME]]";

// An associated-function requirement named on a concrete facet value outside
// any template: the lookup finds the requirement with `Self := C` and names
// `C`'s own `Make` instead (D-SC-4; fill round 1, fix 3).
template constraint HasMake {
  fn Make() -> Self;
}

class C {
  fn Make() -> C { return {}; }
}

//@dump-sem-ir-begin
fn Test() -> C { return (C as HasMake).Make(); }
//@dump-sem-ir-end

// --- fail_todo_ambiguous_with_interface.carbon
library "[[@TEST_NAME]]";

// p002200:385-399: a name that lookup finds both through a template constraint
// and through an interface, where both resolve to the type's same function, is
// not ambiguous. Lookup decides ambiguity across extended scopes before the
// D-SC-4 redirect resolves the requirement to `C.Make` (and, for the interface,
// before impl lookup: upstream's own TODO in member_access.cpp), so it is still
// diagnosed (fill round 2, review finding MINOR-3; residue in
// fork/structural/plan.md, "Landed notes (fill round 2)").
template constraint HasMake {
  fn Make() -> Self;
}

interface J {
  fn Make() -> Self;
}

class C {
  extend impl as J {
    fn Make() -> C { return {}; }
  }
}

fn ViaT(template T: HasMake & J) -> T { return T.Make(); }

fn Test() -> C { return ViaT(C); }

// CHECK:STDOUT: --- method.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %HasGet.type: type = facet_type <@HasGet> [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %C: type = class_type @C [concrete]
// CHECK:STDOUT:   %pattern_type.98b: type = pattern_type %C [concrete]
// CHECK:STDOUT:   %CallGet.type: type = fn_type @CallGet [concrete]
// CHECK:STDOUT:   %CallGet: %CallGet.type = struct_value () [concrete]
// CHECK:STDOUT:   %c.param_patt: %pattern_type.98b = value_param_pattern [concrete]
// CHECK:STDOUT:   %c.patt: %pattern_type.98b = wrapper_binding_pattern c, %c.param_patt [concrete]
// CHECK:STDOUT:   %Test.type: type = fn_type @Test [concrete]
// CHECK:STDOUT:   %Test: %Test.type = struct_value () [concrete]
// CHECK:STDOUT:   %HasGet.facet: %HasGet.type = facet_value %C, () [concrete]
// CHECK:STDOUT:   %CallGet.specific_fn: <specific function> = specific_function %CallGet, @CallGet(%HasGet.facet) [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Test.decl: %Test.type = fn_decl @Test [concrete = constants.%Test] {
// CHECK:STDOUT:     %c.param_patt: %pattern_type.98b = value_param_pattern [concrete = constants.%c.param_patt]
// CHECK:STDOUT:     %c.patt: %pattern_type.98b = wrapper_binding_pattern c, %c.param_patt [concrete = constants.%c.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc18_18: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %c.param: %C = value_param call_param0
// CHECK:STDOUT:     %C.ref: type = name_ref C, file.%C.decl [concrete = constants.%C]
// CHECK:STDOUT:     %c: %C = wrapper_binding c, %c.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Test(%c.param: %C) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %CallGet.ref: %CallGet.type = name_ref CallGet, file.%CallGet.decl [concrete = constants.%CallGet]
// CHECK:STDOUT:   %c.ref: %C = name_ref c, %c
// CHECK:STDOUT:   %HasGet.facet.loc18_40.1: %HasGet.type = facet_value constants.%C, () [concrete = constants.%HasGet.facet]
// CHECK:STDOUT:   %.loc18_40.1: %HasGet.type = converted constants.%C, %HasGet.facet.loc18_40.1 [concrete = constants.%HasGet.facet]
// CHECK:STDOUT:   %HasGet.facet.loc18_40.2: %HasGet.type = facet_value constants.%C, () [concrete = constants.%HasGet.facet]
// CHECK:STDOUT:   %.loc18_40.2: %HasGet.type = converted constants.%C, %HasGet.facet.loc18_40.2 [concrete = constants.%HasGet.facet]
// CHECK:STDOUT:   %CallGet.specific_fn: <specific function> = specific_function %CallGet.ref, @CallGet(constants.%HasGet.facet) [concrete = constants.%CallGet.specific_fn]
// CHECK:STDOUT:   %CallGet.call: init %i32 = call %CallGet.specific_fn(%c.ref)
// CHECK:STDOUT:   return %CallGet.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- class_param.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %HasGet.type: type = facet_type <@HasGet> [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %C: type = class_type @C [concrete]
// CHECK:STDOUT:   %pattern_type.98b: type = pattern_type %C [concrete]
// CHECK:STDOUT:   %empty_struct_type: type = struct_type {} [concrete]
// CHECK:STDOUT:   %Box.type: type = generic_class_type @Box [concrete]
// CHECK:STDOUT:   %Box.generic: %Box.type = struct_value () [concrete]
// CHECK:STDOUT:   %c.param_patt: %pattern_type.98b = value_param_pattern [concrete]
// CHECK:STDOUT:   %c.patt: %pattern_type.98b = wrapper_binding_pattern c, %c.param_patt [concrete]
// CHECK:STDOUT:   %Test.type: type = fn_type @Test [concrete]
// CHECK:STDOUT:   %Test: %Test.type = struct_value () [concrete]
// CHECK:STDOUT:   %HasGet.facet: %HasGet.type = facet_value %C, () [concrete]
// CHECK:STDOUT:   %Box.dfa: type = class_type @Box, @Box(%HasGet.facet) [concrete]
// CHECK:STDOUT:   %Box.Call.type.bcf: type = fn_type @Box.Call, @Box(%HasGet.facet) [concrete]
// CHECK:STDOUT:   %Box.Call.921: %Box.Call.type.bcf = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.7d4: type = pattern_type %Box.dfa [concrete]
// CHECK:STDOUT:   %b.patt: %pattern_type.7d4 = ref_binding_pattern b [concrete]
// CHECK:STDOUT:   %b.var_patt: %pattern_type.7d4 = var_pattern %b.patt [concrete]
// CHECK:STDOUT:   %empty_struct: %empty_struct_type = struct_value () [concrete]
// CHECK:STDOUT:   %Box.val: %Box.dfa = struct_value () [concrete]
// CHECK:STDOUT:   %Box.Call.specific_fn: <specific function> = specific_function %Box.Call.921, @Box.Call(%HasGet.facet) [concrete]
// CHECK:STDOUT:   %pattern_type.a96: type = pattern_type %empty_struct_type [concrete]
// CHECK:STDOUT:   %self.param_patt.52f: %pattern_type.a96 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.4b1: %pattern_type.a96 = wrapper_binding_pattern self, %self.param_patt.52f [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc27_3.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.1: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.1: type = fn_type @Destroy.WithSelf.Op.loc27_3.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.1: %Destroy.WithSelf.Op.type.ef016f.1 = struct_value () [concrete]
// CHECK:STDOUT:   %self.param_patt.66a: %pattern_type.7d4 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.a68: %pattern_type.7d4 = wrapper_binding_pattern self, %self.param_patt.66a [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc27_3.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.2: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.2: type = fn_type @Destroy.WithSelf.Op.loc27_3.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.2: %Destroy.WithSelf.Op.type.ef016f.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.2: type = fn_type @Destroy.WithSelf.SelfDestruct.loc27_3.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.2: %Destroy.WithSelf.SelfDestruct.type.fbceb5.2 = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.1: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc27_3.1 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.1] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.a96 = ref_param_pattern [concrete = constants.%self.param_patt.52f]
// CHECK:STDOUT:     %self.patt: %pattern_type.a96 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.4b1]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %empty_struct_type = ref_param call_param0
// CHECK:STDOUT:     %self: ref %empty_struct_type = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.1: %Destroy.WithSelf.Op.type.ef016f.1 = fn_decl @Destroy.WithSelf.Op.loc27_3.1 [concrete = constants.%Destroy.WithSelf.Op.403171.1] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.a96 = ref_param_pattern [concrete = constants.%self.param_patt.52f]
// CHECK:STDOUT:     %self.patt: %pattern_type.a96 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.4b1]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %empty_struct_type = ref_param call_param0
// CHECK:STDOUT:     %self: ref %empty_struct_type = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.2: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc27_3.2 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.2] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.7d4 = ref_param_pattern [concrete = constants.%self.param_patt.66a]
// CHECK:STDOUT:     %self.patt: %pattern_type.7d4 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.a68]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %Box.dfa = ref_param call_param0
// CHECK:STDOUT:     %self: ref %Box.dfa = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.2: %Destroy.WithSelf.Op.type.ef016f.2 = fn_decl @Destroy.WithSelf.Op.loc27_3.2 [concrete = constants.%Destroy.WithSelf.Op.403171.2] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.7d4 = ref_param_pattern [concrete = constants.%self.param_patt.66a]
// CHECK:STDOUT:     %self.patt: %pattern_type.7d4 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.a68]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %Box.dfa = ref_param call_param0
// CHECK:STDOUT:     %self: ref %Box.dfa = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Test.decl: %Test.type = fn_decl @Test [concrete = constants.%Test] {
// CHECK:STDOUT:     %c.param_patt: %pattern_type.98b = value_param_pattern [concrete = constants.%c.param_patt]
// CHECK:STDOUT:     %c.patt: %pattern_type.98b = wrapper_binding_pattern c, %c.param_patt [concrete = constants.%c.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc26: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %c.param: %C = value_param call_param0
// CHECK:STDOUT:     %C.ref.loc26: type = name_ref C, file.%C.decl [concrete = constants.%C]
// CHECK:STDOUT:     %c: %C = wrapper_binding c, %c.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Test(%c.param: %C) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %b.var: ref %Box.dfa = var_storage %b.var_patt
// CHECK:STDOUT:   %.loc27_20.1: %empty_struct_type = struct_literal () [concrete = constants.%empty_struct]
// CHECK:STDOUT:   %.loc27_20.2: init %Box.dfa to %b.var = class_init () [concrete = constants.%Box.val]
// CHECK:STDOUT:   %.loc27_3: init %Box.dfa = converted %.loc27_20.1, %.loc27_20.2 [concrete = constants.%Box.val]
// CHECK:STDOUT:   assign %b.var, %.loc27_3
// CHECK:STDOUT:   %.loc27_15.1: type = splice_block %Box [concrete = constants.%Box.dfa] {
// CHECK:STDOUT:     %Box.ref: %Box.type = name_ref Box, file.%Box.decl [concrete = constants.%Box.generic]
// CHECK:STDOUT:     %C.ref.loc27: type = name_ref C, file.%C.decl [concrete = constants.%C]
// CHECK:STDOUT:     %HasGet.facet.loc27: %HasGet.type = facet_value %C.ref.loc27, () [concrete = constants.%HasGet.facet]
// CHECK:STDOUT:     %.loc27_15.2: %HasGet.type = converted %C.ref.loc27, %HasGet.facet.loc27 [concrete = constants.%HasGet.facet]
// CHECK:STDOUT:     %Box: type = class_type @Box, @Box(constants.%HasGet.facet) [concrete = constants.%Box.dfa]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %b: ref %Box.dfa = wrapper_binding b, %b.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %b.patt: %pattern_type.7d4 = ref_binding_pattern b [concrete = constants.%b.patt]
// CHECK:STDOUT:     %b.var_patt: %pattern_type.7d4 = var_pattern %b.patt [concrete = constants.%b.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %b.ref: ref %Box.dfa = name_ref b, %b
// CHECK:STDOUT:   %.loc28_11: %Box.Call.type.bcf = specific_constant @Box.%Box.Call.decl, @Box(constants.%HasGet.facet) [concrete = constants.%Box.Call.921]
// CHECK:STDOUT:   %Call.ref: %Box.Call.type.bcf = name_ref Call, %.loc28_11 [concrete = constants.%Box.Call.921]
// CHECK:STDOUT:   %Box.Call.bound: <bound method> = bound_method %b.ref, %Call.ref
// CHECK:STDOUT:   %c.ref: %C = name_ref c, %c
// CHECK:STDOUT:   %HasGet.facet.loc28_18.1: %HasGet.type = facet_value constants.%C, () [concrete = constants.%HasGet.facet]
// CHECK:STDOUT:   %.loc28_18.1: %HasGet.type = converted constants.%C, %HasGet.facet.loc28_18.1 [concrete = constants.%HasGet.facet]
// CHECK:STDOUT:   %HasGet.facet.loc28_18.2: %HasGet.type = facet_value constants.%C, () [concrete = constants.%HasGet.facet]
// CHECK:STDOUT:   %.loc28_18.2: %HasGet.type = converted constants.%C, %HasGet.facet.loc28_18.2 [concrete = constants.%HasGet.facet]
// CHECK:STDOUT:   %Box.Call.specific_fn: <specific function> = specific_function %Call.ref, @Box.Call(constants.%HasGet.facet) [concrete = constants.%Box.Call.specific_fn]
// CHECK:STDOUT:   %bound_method: <bound method> = bound_method %b.ref, %Box.Call.specific_fn
// CHECK:STDOUT:   %.loc28_10: %Box.dfa = acquire_value %b.ref
// CHECK:STDOUT:   %Box.Call.call: init %i32 = call %bound_method(%.loc28_10, %c.ref)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound: <bound method> = bound_method %b.var, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound(%b.var)
// CHECK:STDOUT:   return %Box.Call.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc27_3.1(%self.param: ref %empty_struct_type) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc27_3.1(%self.param: ref %empty_struct_type) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc27_3.1(%self.param: ref %empty_struct_type) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.1(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.1(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc27_3.2(%self.param: ref %Box.dfa) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc27_3.2(%self.param: ref %Box.dfa) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc27_3.2(%self.param: ref %Box.dfa) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.2(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.2(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
