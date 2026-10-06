// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --dump-sem-ir-ranges=only
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/function/overload/fail_todo_gates.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/function/overload/fail_todo_gates.carbon

// The 0.1 gates of fork/overload/plan.md D-OV-6, one subfile per gate. Each is
// a semantics TODO at the declaration (or, for the two call-site gates, at
// the call) so that overload resolution only ever sees supported members.
// OV-2 lifted (i) generic members, (ii) sets in generic scopes and (iv)
// `extern` members, and deleted their subfiles (generic.carbon,
// generic_class_method_set.carbon and import.carbon pin the lifted shapes).
// Gate (xi), template-dependent arguments, is bypassed since the UA-1 merge:
// upstream defers a call with a template-dependent argument as a `CallAction`
// and performs it per specific, where the argument types are concrete, so the
// `template_dependent.carbon` subfile below is a positive pin of resolution
// at instantiation (the gate itself remains for a call that is not deferred).

// --- fail_todo_ref_param.carbon

library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_todo_ref_param.carbon:[[@LINE+4]]:15: error: semantics TODO: ``overload fn` with a non-value explicit parameter` [SemanticsTodo]
// CHECK:STDERR: overload fn F(ref x: i32);
// CHECK:STDERR:               ^~~~~~~~~~
// CHECK:STDERR:
overload fn F(ref x: i32);

// --- fail_todo_entry_point.carbon

library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_todo_entry_point.carbon:[[@LINE+4]]:1: error: semantics TODO: ``overload` on the entry point` [SemanticsTodo]
// CHECK:STDERR: overload fn Run() -> i32 { return 0; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
overload fn Run() -> i32 { return 0; }

// --- fail_todo_access.carbon

library "[[@TEST_NAME]]";

overload fn F(x: i32);
// CHECK:STDERR: fail_todo_access.carbon:[[@LINE+4]]:1: error: semantics TODO: ``overload fn` members with differing access` [SemanticsTodo]
// CHECK:STDERR: private overload fn F(b: bool);
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
private overload fn F(b: bool);

// --- fail_todo_self_only.carbon

library "[[@TEST_NAME]]";

class C {
  overload fn F(self, x: i32);
  // CHECK:STDERR: fail_todo_self_only.carbon:[[@LINE+4]]:3: error: semantics TODO: ``overload fn` members distinguished only by `self`` [SemanticsTodo]
  // CHECK:STDERR:   overload fn F(ref self, x: i32);
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  overload fn F(ref self, x: i32);
}

// --- fail_todo_interface.carbon

library "[[@TEST_NAME]]";

interface I {
  // CHECK:STDERR: fail_todo_interface.carbon:[[@LINE+4]]:3: error: semantics TODO: ``overload fn` in an interface` [SemanticsTodo]
  // CHECK:STDERR:   overload fn M(self);
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  overload fn M(self);
}

// --- fail_todo_mixed_self.carbon

library "[[@TEST_NAME]]";

class C {
  overload fn F(self, x: i32);
  // CHECK:STDERR: fail_todo_mixed_self.carbon:[[@LINE+4]]:3: error: semantics TODO: ``overload fn` members that disagree on `self`` [SemanticsTodo]
  // CHECK:STDERR:   overload fn F(b: bool);
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  overload fn F(b: bool);
}

// --- template_dependent.carbon

library "[[@TEST_NAME]]";

overload fn F(unused x: i32) -> i32 { return 1; }
overload fn F(unused b: bool) -> i32 { return 2; }

// The call is deferred at the definition (its argument's type is the template
// parameter) and resolved for each specific: `i32` selects the first member,
// `bool` the second, by declaration order (F-009, D-OV-4).
fn T2(template T: type, x: T) -> i32 { return F(x); }

//@dump-sem-ir-begin
fn Use() -> i32 {
  return T2(i32, 1) + T2(bool, true);
}
//@dump-sem-ir-end

// --- fail_todo_explicit_ref_receiver.carbon

library "[[@TEST_NAME]]";

class R {
  var n: i32;
  overload fn Bump(ref self, x: i32) { self.n = self.n + x; }
  overload fn Bump(unused ref self, unused b: bool) {}
}

// The same call through `r.Bump(1)` is the positive `method_set` shape.
// CHECK:STDERR: fail_todo_explicit_ref_receiver.carbon:[[@LINE+4]]:16: error: semantics TODO: `explicit receiver for a `ref self`/`addr self` overload member` [SemanticsTodo]
// CHECK:STDERR: fn Use(r: R) { R.Bump(r, 1); }
// CHECK:STDERR:                ^~~~~~~~~~~~
// CHECK:STDERR:
fn Use(r: R) { R.Bump(r, 1); }

// --- fail_todo_impl_body.carbon

library "[[@TEST_NAME]]";

interface I {
  fn Get(self) -> i32;
}

class D {
  extend impl as I {
    // CHECK:STDERR: fail_todo_impl_body.carbon:[[@LINE+4]]:5: error: semantics TODO: ``overload fn` in an `impl` body` [SemanticsTodo]
    // CHECK:STDERR:     overload fn Get(unused self) -> i32 { return 1; }
    // CHECK:STDERR:     ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // CHECK:STDERR:
    overload fn Get(unused self) -> i32 { return 1; }
  }
}

// CHECK:STDOUT: --- template_dependent.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
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
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.953: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT:   %T2.type: type = fn_type @T2 [concrete]
// CHECK:STDOUT:   %T2: %T2.type = struct_value () [concrete]
// CHECK:STDOUT:   %Use.type: type = fn_type @Use [concrete]
// CHECK:STDOUT:   %Use: %Use.type = struct_value () [concrete]
// CHECK:STDOUT:   %T2.specific_fn.486: <specific function> = specific_function %T2, @T2(%i32) [concrete]
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete]
// CHECK:STDOUT:   %T2.specific_fn.dab: <specific function> = specific_function %T2, @T2(bool) [concrete]
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
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.b4fd3a.1 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.684: @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op.type (%Int.as.AddWith.impl.Op.type.610) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op (constants.%Int.as.AddWith.impl.Op.732)]
// CHECK:STDOUT:   %AddWith.impl_witness_table.6b4 = impl_witness_table (%Core.import_ref.b4fd3a.1, %Core.import_ref.684), @Int.as.AddWith.impl.3af [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Use.decl: %Use.type = fn_decl @Use [concrete = constants.%Use] {
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
// CHECK:STDOUT: fn @Use() -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %T2.ref.loc14_10: %T2.type = name_ref T2, file.%T2.decl [concrete = constants.%T2]
// CHECK:STDOUT:   %i32.loc14: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %T2.specific_fn.loc14_10: <specific function> = specific_function %T2.ref.loc14_10, @T2(constants.%i32) [concrete = constants.%T2.specific_fn.486]
// CHECK:STDOUT:   %impl.elem0: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc14_18.1: <bound method> = bound_method %int_1, %impl.elem0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc14_18: <specific function> = specific_function %impl.elem0, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc14_18.2: <bound method> = bound_method %int_1, %specific_fn.loc14_18 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %i32 = call %bound_method.loc14_18.2(%int_1) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc14_18.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc14_18.2: %i32 = converted %int_1, %.loc14_18.1 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %T2.call.loc14_19: init %i32 = call %T2.specific_fn.loc14_10(%.loc14_18.2)
// CHECK:STDOUT:   %T2.ref.loc14_23: %T2.type = name_ref T2, file.%T2.decl [concrete = constants.%T2]
// CHECK:STDOUT:   %.loc14_26: type = type_literal bool [concrete = bool]
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:   %T2.specific_fn.loc14_23: <specific function> = specific_function %T2.ref.loc14_23, @T2(bool) [concrete = constants.%T2.specific_fn.dab]
// CHECK:STDOUT:   %T2.call.loc14_36: init %i32 = call %T2.specific_fn.loc14_23(%true)
// CHECK:STDOUT:   %impl.elem1: %.d47 = impl_witness_access constants.%AddWith.impl_witness.833, element1 [concrete = constants.%Int.as.AddWith.impl.Op.365]
// CHECK:STDOUT:   %bound_method.loc14_21.1: <bound method> = bound_method %T2.call.loc14_19, %impl.elem1
// CHECK:STDOUT:   %specific_fn.loc14_21: <specific function> = specific_function %impl.elem1, @Int.as.AddWith.impl.Op.1(constants.%int_32) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.f25]
// CHECK:STDOUT:   %bound_method.loc14_21.2: <bound method> = bound_method %T2.call.loc14_19, %specific_fn.loc14_21
// CHECK:STDOUT:   %.loc14_19.1: %i32 = value_of_initializer %T2.call.loc14_19
// CHECK:STDOUT:   %.loc14_19.2: %i32 = converted %T2.call.loc14_19, %.loc14_19.1
// CHECK:STDOUT:   %.loc14_36.1: %i32 = value_of_initializer %T2.call.loc14_36
// CHECK:STDOUT:   %.loc14_36.2: %i32 = converted %T2.call.loc14_36, %.loc14_36.1
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call: init %i32 = call %bound_method.loc14_21.2(%.loc14_19.2, %.loc14_36.2)
// CHECK:STDOUT:   return %Int.as.AddWith.impl.Op.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
