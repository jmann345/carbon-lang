// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/exceptions/catching_thunk.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/exceptions/catching_thunk.carbon

// Catching imports (docs/design/error_handling.md, "Catching imports:
// `Result(T, Cpp.Exception)`"; fork/eh/plan.md §1.B.1-1.B.3, §4.B): under the
// default `--cpp-exceptions=auto` (resolving to `catch` here), applying `?`
// DIRECTLY to a call of a potentially-throwing C++ function selects the
// CATCHING thunk — a second, distinctly named thunk (`__carbon_catching_thunk`,
// asm label `.carbon_thunk_catch`) built lazily at the first such call — and
// the call has type `Core.Result(S, Cpp.Exception)`. The SemIR shows the
// return-slot and error temporaries, ONE `temporary_storage` of the `Result`
// type minted before the branch, the `i32` discriminant call, the `EqWith`
// test against 0, each block's alternative-constructor `call` initializing
// that storage in place (`assign`), the convergence, and the value read from
// the storage after it.
// The FENCED thunk is built eagerly at import, so a callee used both ways has
// BOTH thunk declarations in `imports`. The full prelude is needed for
// `Core.Result`.

// --- question_select.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
int may_throw_int();
''';

//@dump-sem-ir-begin
fn F() -> Core.Result(i32, Cpp.Exception) {
  return Core.Result(i32, Cpp.Exception).Ok(Cpp.may_throw_int()?);
}
//@dump-sem-ir-end

// --- void_callee.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
void may_throw();
''';

// A `void` callee: `S` is `()`, so the catching thunk has no return
// out-parameter and no return-slot temporary is minted.
//@dump-sem-ir-begin
fn G() -> Core.Result((), Cpp.Exception) {
  Cpp.may_throw()?;
  return Core.Result((), Cpp.Exception).Ok(());
}
//@dump-sem-ir-end

// --- nested_argument.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
int f(int n);
int g();
''';

// Only the call `?` is applied to is catching: the argument call `Cpp.g()` is
// followed by `f`'s `CallExpr` node in postorder, never directly by `?`, so it
// stays fenced.
//@dump-sem-ir-begin
fn H() -> Core.Result(i32, Cpp.Exception) {
  return Core.Result(i32, Cpp.Exception).Ok(Cpp.f(Cpp.g())?);
}
//@dump-sem-ir-end

// --- same_callee_both_ways.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
int may_throw_int();
''';

// Selection is per call site: the same callee is called fenced once and
// catching once, and `imports` carries both thunk declarations with distinct
// identifiers.
//@dump-sem-ir-begin
fn Both() -> Core.Result(i32, Cpp.Exception) {
  var plain: i32 = Cpp.may_throw_int();
  var caught: i32 = Cpp.may_throw_int()?;
  return Core.Result(i32, Cpp.Exception).Ok(plain + caught);
}
//@dump-sem-ir-end

// --- paren_operand.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
int may_throw_int();
''';

// The adjacency test walks up through `ParenExpr` nodes: `?` binds to the
// value, not the spelling.
//@dump-sem-ir-begin
fn P() -> Core.Result(i32, Cpp.Exception) {
  var one: i32 = (Cpp.may_throw_int())?;
  var two: i32 = ((Cpp.may_throw_int()))?;
  return Core.Result(i32, Cpp.Exception).Ok(one + two);
}
//@dump-sem-ir-end

// --- member.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
struct C {
  int get() const;
  int mutate();
};
''';

// Member callees: the catching thunk's first parameter is the implicit object
// parameter (`const C&` for `get`, `C&` for `mutate`), followed by the return
// out-pointer and the error out-pointer. The thunk is imported by the bare
// function import (`ImportCppThunkFunctionDecl`), so the non-simple-ABI
// `const C&` parameter does not make it a thunk-requiring callee itself:
// `imports` shows each method's fenced thunk and its catching thunk, and both
// calls are `Call`s to the catching thunk followed by the `Result`
// construction.
//@dump-sem-ir-begin
fn M(c: Cpp.C, p: Cpp.C*) -> Core.Result(i32, Cpp.Exception) {
  var a: i32 = c.get()?;
  var b: i32 = p->mutate()?;
  return Core.Result(i32, Cpp.Exception).Ok(a + b);
}
//@dump-sem-ir-end

// --- reserved_name.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
struct Exception {};
int may_throw_int();
''';

// `Exception` is reserved at the top of the `Cpp` package: `Cpp.Exception`
// still names the Carbon built-in type (the `Result` specific below is the
// same `Core.Result(i32, Cpp.Exception)` as in `question_select`), and the
// header's global `struct Exception` is reported unreachable under that
// name.
//@dump-sem-ir-begin
// CHECK:STDERR: reserved_name.carbon:[[@LINE+7]]:28: warning: C++ entity `Exception` declared at global scope is not reachable as `Cpp.Exception`, which names the Carbon built-in type; name it through a C++-side alias in bridge code [CppReservedNameShadowed]
// CHECK:STDERR: fn R() -> Core.Result(i32, Cpp.Exception) {
// CHECK:STDERR:                            ^~~~~~~~~~~~~
// CHECK:STDERR: reserved_name.carbon:[[@LINE+4]]:28: note: in `Cpp` name lookup for `Exception` [InCppNameLookup]
// CHECK:STDERR: fn R() -> Core.Result(i32, Cpp.Exception) {
// CHECK:STDERR:                            ^~~~~~~~~~~~~
// CHECK:STDERR:
fn R() -> Core.Result(i32, Cpp.Exception) {
  return Core.Result(i32, Cpp.Exception).Ok(Cpp.may_throw_int()?);
}
//@dump-sem-ir-end

// CHECK:STDOUT: --- question_select.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %Result.type: type = generic_class_type @Result [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %Result.generic: %Result.type = struct_value () [concrete]
// CHECK:STDOUT:   %E: type = symbolic_binding E, 1 [symbolic]
// CHECK:STDOUT:   %T.67d: type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %u1: type = class_type @UInt, @UInt(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %u1.builtin: type = int_type unsigned, %int_1.5b8 [concrete]
// CHECK:STDOUT:   %Result.Err.type.b75: type = fn_type @Result.Err, @Result(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %Result.Err.08c: %Result.Err.type.b75 = struct_value () [symbolic]
// CHECK:STDOUT:   %Result.Ok.type.898: type = fn_type @Result.Ok, @Result(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %Result.Ok.58a: %Result.Ok.type.898 = struct_value () [symbolic]
// CHECK:STDOUT:   %int_1.233: %u1 = int_value 1 [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %Int.type: type = generic_class_type @Int [concrete]
// CHECK:STDOUT:   %Int.generic: %Int.type = struct_value () [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %Cpp.Exception: type = class_type @Exception [concrete]
// CHECK:STDOUT:   %Cpp.void: type = class_type @VoidBase [concrete]
// CHECK:STDOUT:   %ptr.00a: type = ptr_type %Cpp.void [concrete]
// CHECK:STDOUT:   %Result.900: type = class_type @Result, @Result(%i32, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %.c19: Core.Form = init_form %Result.900 [concrete]
// CHECK:STDOUT:   %pattern_type.5d9: type = pattern_type %Result.900 [concrete]
// CHECK:STDOUT:   %return.param_patt.8a0: %pattern_type.5d9 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.dd6: %pattern_type.5d9 = return_slot_pattern %return.param_patt.8a0, %Result.900 [concrete]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT:   %i32.builtin: type = int_type signed, %int_32 [concrete]
// CHECK:STDOUT:   %tuple.type.a8a: type = tuple_type (%i32) [concrete]
// CHECK:STDOUT:   %tuple.type.b42: type = tuple_type (%Cpp.Exception) [concrete]
// CHECK:STDOUT:   %Result.Ok.type.977: type = fn_type @Result.Ok, @Result(%i32, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %Result.Ok.789: %Result.Ok.type.977 = struct_value () [concrete]
// CHECK:STDOUT:   %Result.Err.type.a4b: type = fn_type @Result.Err, @Result(%i32, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %Result.Err.7cb: %Result.Err.type.a4b = struct_value () [concrete]
// CHECK:STDOUT:   %may_throw_int.cpp_overload_set.type: type = cpp_overload_set_type @may_throw_int.cpp_overload_set [concrete]
// CHECK:STDOUT:   %may_throw_int.cpp_overload_set.value: %may_throw_int.cpp_overload_set.type = cpp_overload_set_value @may_throw_int.cpp_overload_set [concrete]
// CHECK:STDOUT:   %Try.type: type = facet_type <@Try> [concrete]
// CHECK:STDOUT:   %ptr.d08: type = ptr_type %i32 [concrete]
// CHECK:STDOUT:   %ptr.6f9: type = ptr_type %ptr.00a [concrete]
// CHECK:STDOUT:   %may_throw_int__carbon_catching_thunk.type: type = fn_type @may_throw_int__carbon_catching_thunk [concrete]
// CHECK:STDOUT:   %may_throw_int__carbon_catching_thunk: %may_throw_int__carbon_catching_thunk.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.0ff: type = generic_interface_type @ImplicitAs [concrete]
// CHECK:STDOUT:   %ImplicitAs.generic: %ImplicitAs.type.0ff = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %To.fe9: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.48f: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet.48f [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.6e0: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_0.3c0: %i32 = int_value 0 [concrete]
// CHECK:STDOUT:   %EqWith.type.f77: type = generic_interface_type @EqWith [concrete]
// CHECK:STDOUT:   %EqWith.generic: %EqWith.type.f77 = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.type.8ee: type = facet_type <@EqWith, @EqWith(%i32)> [concrete]
// CHECK:STDOUT:   %M: Core.IntLiteral = symbolic_binding M, 1 [symbolic]
// CHECK:STDOUT:   %Int.as.EqWith.impl.Equal.type.9a2: type = fn_type @Int.as.EqWith.impl.Equal.1, @Int.as.EqWith.impl.e9c(%N, %M) [symbolic]
// CHECK:STDOUT:   %Int.as.EqWith.impl.Equal.792: %Int.as.EqWith.impl.Equal.type.9a2 = struct_value () [symbolic]
// CHECK:STDOUT:   %EqWith.impl_witness.34c: <witness> = impl_witness imports.%EqWith.impl_witness_table.09e, @Int.as.EqWith.impl.e9c(%int_32, %int_32) [concrete]
// CHECK:STDOUT:   %Int.as.EqWith.impl.Equal.type.01c: type = fn_type @Int.as.EqWith.impl.Equal.1, @Int.as.EqWith.impl.e9c(%int_32, %int_32) [concrete]
// CHECK:STDOUT:   %Int.as.EqWith.impl.Equal.34f: %Int.as.EqWith.impl.Equal.type.01c = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.508: %EqWith.type.8ee = facet_value %i32, (%EqWith.impl_witness.34c) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.530: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%i32, %EqWith.facet.508) [concrete]
// CHECK:STDOUT:   %.a79: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.530, %EqWith.facet.508 [concrete]
// CHECK:STDOUT:   %Int.as.EqWith.impl.Equal.specific_fn.12d: <specific function> = specific_function %Int.as.EqWith.impl.Equal.34f, @Int.as.EqWith.impl.Equal.1(%int_32, %int_32) [concrete]
// CHECK:STDOUT:   %Result.Ok.specific_fn: <specific function> = specific_function %Result.Ok.789, @Result.Ok(%i32, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %Result.Err.specific_fn.031: <specific function> = specific_function %Result.Err.7cb, @Result.Err(%i32, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.type.834: type = fn_type @Result.as.Try.impl.FromBreak, @Result.as.Try.impl(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.9cc: %Result.as.Try.impl.FromBreak.type.834 = struct_value () [symbolic]
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.type.d6a: type = fn_type @Result.as.Try.impl.Branch, @Result.as.Try.impl(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.513: %Result.as.Try.impl.Branch.type.d6a = struct_value () [symbolic]
// CHECK:STDOUT:   %Try.impl_witness.d5a: <witness> = impl_witness imports.%Try.impl_witness_table, @Result.as.Try.impl(%i32, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.type.521: type = fn_type @Result.as.Try.impl.Branch, @Result.as.Try.impl(%i32, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.1b9: %Result.as.Try.impl.Branch.type.521 = struct_value () [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.type.b43: type = fn_type @Result.as.Try.impl.FromBreak, @Result.as.Try.impl(%i32, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.c94: %Result.as.Try.impl.FromBreak.type.b43 = struct_value () [concrete]
// CHECK:STDOUT:   %Try.facet.51d: %Try.type = facet_value %Result.900, (%Try.impl_witness.d5a) [concrete]
// CHECK:STDOUT:   %Try.WithSelf.Branch.type.353: type = fn_type @Try.WithSelf.Branch, @Try.WithSelf(%Try.facet.51d) [concrete]
// CHECK:STDOUT:   %Try.WithSelf.FromBreak.type.cf1: type = fn_type @Try.WithSelf.FromBreak, @Try.WithSelf(%Try.facet.51d) [concrete]
// CHECK:STDOUT:   %.8bc: type = fn_type_with_self_type %Try.WithSelf.Branch.type.353, %Try.facet.51d [concrete]
// CHECK:STDOUT:   %ControlFlow.bd1: type = class_type @ControlFlow, @ControlFlow(%i32, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.specific_fn.2e1: <specific function> = specific_function %Result.as.Try.impl.Branch.1b9, @Result.as.Try.impl.Branch(%i32, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %.337: type = custom_layout_type {size=8, align=8, .Continue@0: %tuple.type.a8a, .Break@0: %tuple.type.b42} [concrete]
// CHECK:STDOUT:   %struct_type.discriminant.payload.b51: type = struct_type {.discriminant: %u1, .payload: %.337} [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.ca1: type = facet_type <@ImplicitAs, @ImplicitAs(%u1)> [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.b68(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.170: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.f4c: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.f01, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.46b: %ImplicitAs.type.ca1 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.f4c) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.77c: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%u1, %ImplicitAs.facet.46b) [concrete]
// CHECK:STDOUT:   %.e74: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.77c, %ImplicitAs.facet.46b [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.d7a: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
// CHECK:STDOUT:   %EqWith.type.c25: type = facet_type <@EqWith, @EqWith(%u1)> [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.544: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%N, %M) [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.c67: %UInt.as.EqWith.impl.Equal.type.544 = struct_value () [symbolic]
// CHECK:STDOUT:   %EqWith.impl_witness.7b3: <witness> = impl_witness imports.%EqWith.impl_witness_table.166, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.29b: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.ba4: %UInt.as.EqWith.impl.Equal.type.29b = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.4d0: %EqWith.type.c25 = facet_value %u1, (%EqWith.impl_witness.7b3) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.e3c: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%u1, %EqWith.facet.4d0) [concrete]
// CHECK:STDOUT:   %.9eb: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.e3c, %EqWith.facet.4d0 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.specific_fn.6b6: <specific function> = specific_function %UInt.as.EqWith.impl.Equal.ba4, @UInt.as.EqWith.impl.Equal.1(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.a82: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
// CHECK:STDOUT:   %.cfb: type = fn_type_with_self_type %Try.WithSelf.FromBreak.type.cf1, %Try.facet.51d [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.specific_fn: <specific function> = specific_function %Result.as.Try.impl.FromBreak.c94, @Result.as.Try.impl.FromBreak(%i32, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %Destroy.type: type = facet_type <@Destroy> [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.11: type = fn_type @Destroy.Op.loc12_64.11 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.11: %Destroy.Op.type.1d8f74.11 = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .Result = %Core.Result
// CHECK:STDOUT:     .Int = %Core.Int
// CHECK:STDOUT:     .CppCompat = %CppCompat.f0dbf9.1
// CHECK:STDOUT:     .Try = %Core.Try
// CHECK:STDOUT:     .ImplicitAs = %Core.ImplicitAs
// CHECK:STDOUT:     .EqWith = %Core.EqWith
// CHECK:STDOUT:     .Destroy = %Core.Destroy
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Cpp: <namespace> = namespace file.%Cpp.import_cpp, [concrete] {
// CHECK:STDOUT:     .Exception = constants.%Cpp.Exception
// CHECK:STDOUT:     .may_throw_int = %may_throw_int.cpp_overload_set.value
// CHECK:STDOUT:     import Cpp//...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Result: %Result.type = import_ref Core//prelude/types/result, Result, loaded [concrete = constants.%Result.generic]
// CHECK:STDOUT:   %Core.import_ref.597: @Result.%Result.Ok.type (%Result.Ok.type.898) = import_ref Core//prelude/types/result, loc{{\d+_\d+}}, loaded [symbolic = @Result.%Result.Ok (constants.%Result.Ok.58a)]
// CHECK:STDOUT:   %Core.import_ref.bfc4: @Result.%Result.Err.type (%Result.Err.type.b75) = import_ref Core//prelude/types/result, loc{{\d+_\d+}}, loaded [symbolic = @Result.%Result.Err (constants.%Result.Err.08c)]
// CHECK:STDOUT:   %Core.Int: %Int.type = import_ref Core//prelude/types/int, Int, loaded [concrete = constants.%Int.generic]
// CHECK:STDOUT:   %Core.CppCompat: <namespace> = import_ref Core//prelude, CppCompat, loaded
// CHECK:STDOUT:   %CppCompat.f0dbf9.1: <namespace> = namespace %Core.CppCompat, [concrete] {
// CHECK:STDOUT:     .Exception = %Core.Exception
// CHECK:STDOUT:     .VoidBase = %Core.VoidBase
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Exception: type = import_ref Core//prelude/types/cpp/exception, Exception, loaded [concrete = constants.%Cpp.Exception]
// CHECK:STDOUT:   %may_throw_int.cpp_overload_set.value: %may_throw_int.cpp_overload_set.type = cpp_overload_set_value @may_throw_int.cpp_overload_set [concrete = constants.%may_throw_int.cpp_overload_set.value]
// CHECK:STDOUT:   %Core.Try: type = import_ref Core//prelude/try, Try, loaded [concrete = constants.%Try.type]
// CHECK:STDOUT:   %Core.VoidBase: type = import_ref Core//prelude/types/cpp/void, VoidBase, loaded [concrete = constants.%Cpp.void]
// CHECK:STDOUT:   %may_throw_int__carbon_catching_thunk.decl: %may_throw_int__carbon_catching_thunk.type = fn_decl @may_throw_int__carbon_catching_thunk [concrete = constants.%may_throw_int__carbon_catching_thunk] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.ImplicitAs: %ImplicitAs.type.0ff = import_ref Core//prelude/operators/as, ImplicitAs, loaded [concrete = constants.%ImplicitAs.generic]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.EqWith: %EqWith.type.f77 = import_ref Core//prelude/operators/comparison, EqWith, loaded [concrete = constants.%EqWith.generic]
// CHECK:STDOUT:   %Core.import_ref.074: @Int.as.EqWith.impl.e9c.%Int.as.EqWith.impl.Equal.type (%Int.as.EqWith.impl.Equal.type.9a2) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.EqWith.impl.e9c.%Int.as.EqWith.impl.Equal (constants.%Int.as.EqWith.impl.Equal.792)]
// CHECK:STDOUT:   %Core.import_ref.449 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.09e = impl_witness_table (%Core.import_ref.074, %Core.import_ref.449), @Int.as.EqWith.impl.e9c [concrete]
// CHECK:STDOUT:   %Core.import_ref.0b3 = import_ref Core//prelude/types/result, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.6e9 = import_ref Core//prelude/types/result, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9f4: @Result.as.Try.impl.%Result.as.Try.impl.Branch.type (%Result.as.Try.impl.Branch.type.d6a) = import_ref Core//prelude/types/result, loc{{\d+_\d+}}, loaded [symbolic = @Result.as.Try.impl.%Result.as.Try.impl.Branch (constants.%Result.as.Try.impl.Branch.513)]
// CHECK:STDOUT:   %Core.import_ref.6a4: @Result.as.Try.impl.%Result.as.Try.impl.FromBreak.type (%Result.as.Try.impl.FromBreak.type.834) = import_ref Core//prelude/types/result, loc{{\d+_\d+}}, loaded [symbolic = @Result.as.Try.impl.%Result.as.Try.impl.FromBreak (constants.%Result.as.Try.impl.FromBreak.9cc)]
// CHECK:STDOUT:   %Try.impl_witness_table = impl_witness_table (%Core.import_ref.0b3, %Core.import_ref.6e9, %Core.import_ref.9f4, %Core.import_ref.6a4), @Result.as.Try.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.aa5: @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.170)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.f01 = impl_witness_table (%Core.import_ref.aa5), @Core.IntLiteral.as.ImplicitAs.impl.b68 [concrete]
// CHECK:STDOUT:   %Core.import_ref.b92: @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal.type (%UInt.as.EqWith.impl.Equal.type.544) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal (constants.%UInt.as.EqWith.impl.Equal.c67)]
// CHECK:STDOUT:   %Core.import_ref.b44 = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.166 = impl_witness_table (%Core.import_ref.b92, %Core.import_ref.b44), @UInt.as.EqWith.impl.f13 [concrete]
// CHECK:STDOUT:   %Core.Destroy: type = import_ref Core//prelude/destroy, Destroy, loaded [concrete = constants.%Destroy.type]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %F.decl: %F.type = fn_decl @F [concrete = constants.%F] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.5d9 = out_param_pattern [concrete = constants.%return.param_patt.8a0]
// CHECK:STDOUT:     %return.patt: %pattern_type.5d9 = return_slot_pattern %return.param_patt, %Result.loc11 [concrete = constants.%return.patt.dd6]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %Core.ref.loc11: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:     %Result.ref.loc11: %Result.type = name_ref Result, imports.%Core.Result [concrete = constants.%Result.generic]
// CHECK:STDOUT:     %i32.loc11: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %Cpp.ref.loc11: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:     %Exception.ref.loc11: type = name_ref Exception, constants.%Cpp.Exception [concrete = constants.%Cpp.Exception]
// CHECK:STDOUT:     %Result.loc11: type = class_type @Result, @Result(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.900]
// CHECK:STDOUT:     %.loc11_41.3: Core.Form = init_form %Result.loc11 [concrete = constants.%.c19]
// CHECK:STDOUT:     %return.param: ref %Result.900 = out_param call_param0
// CHECK:STDOUT:     %return: ref %Result.900 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @F() -> out %return.param: %Result.900 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Core.ref.loc12: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:   %Result.ref.loc12: %Result.type = name_ref Result, imports.%Core.Result [concrete = constants.%Result.generic]
// CHECK:STDOUT:   %i32.loc12: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %Cpp.ref.loc12_27: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:   %Exception.ref.loc12: type = name_ref Exception, constants.%Cpp.Exception [concrete = constants.%Cpp.Exception]
// CHECK:STDOUT:   %Result.loc12_40: type = class_type @Result, @Result(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.900]
// CHECK:STDOUT:   %.loc12_41: %Result.Ok.type.977 = specific_constant imports.%Core.import_ref.597, @Result(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.Ok.789]
// CHECK:STDOUT:   %Ok.ref.loc12_41: %Result.Ok.type.977 = name_ref Ok, %.loc12_41 [concrete = constants.%Result.Ok.789]
// CHECK:STDOUT:   %Cpp.ref.loc12_45: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:   %may_throw_int.ref: %may_throw_int.cpp_overload_set.type = name_ref may_throw_int, imports.%may_throw_int.cpp_overload_set.value [concrete = constants.%may_throw_int.cpp_overload_set.value]
// CHECK:STDOUT:   %Result.loc12_63: type = class_type @Result, @Result(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.900]
// CHECK:STDOUT:   %.loc12_63.1: ref %i32 = temporary_storage
// CHECK:STDOUT:   %addr.loc12_63.1: %ptr.d08 = addr_of %.loc12_63.1
// CHECK:STDOUT:   %.loc12_63.2: ref %ptr.00a = temporary_storage
// CHECK:STDOUT:   %addr.loc12_63.2: %ptr.6f9 = addr_of %.loc12_63.2
// CHECK:STDOUT:   %may_throw_int__carbon_catching_thunk.call: init %i32 = call imports.%may_throw_int__carbon_catching_thunk.decl(%addr.loc12_63.1, %addr.loc12_63.2)
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc12_63.1: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc12_63.1: <bound method> = bound_method %int_0, %impl.elem0.loc12_63.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc12_63.1: <specific function> = specific_function %impl.elem0.loc12_63.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc12_63.2: <bound method> = bound_method %int_0, %specific_fn.loc12_63.1 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc12_63: init %i32 = call %bound_method.loc12_63.2(%int_0) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc12_63.3: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc12_63 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc12_63.4: %i32 = converted %int_0, %.loc12_63.3 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %impl.elem0.loc12_63.2: %.a79 = impl_witness_access constants.%EqWith.impl_witness.34c, element0 [concrete = constants.%Int.as.EqWith.impl.Equal.34f]
// CHECK:STDOUT:   %bound_method.loc12_63.3: <bound method> = bound_method %may_throw_int__carbon_catching_thunk.call, %impl.elem0.loc12_63.2
// CHECK:STDOUT:   %specific_fn.loc12_63.2: <specific function> = specific_function %impl.elem0.loc12_63.2, @Int.as.EqWith.impl.Equal.1(constants.%int_32, constants.%int_32) [concrete = constants.%Int.as.EqWith.impl.Equal.specific_fn.12d]
// CHECK:STDOUT:   %bound_method.loc12_63.4: <bound method> = bound_method %may_throw_int__carbon_catching_thunk.call, %specific_fn.loc12_63.2
// CHECK:STDOUT:   %.loc12_63.5: %i32 = value_of_initializer %may_throw_int__carbon_catching_thunk.call
// CHECK:STDOUT:   %.loc12_63.6: %i32 = converted %may_throw_int__carbon_catching_thunk.call, %.loc12_63.5
// CHECK:STDOUT:   %Int.as.EqWith.impl.Equal.call: init bool = call %bound_method.loc12_63.4(%.loc12_63.6, %.loc12_63.4)
// CHECK:STDOUT:   %.loc12_63.7: bool = value_of_initializer %Int.as.EqWith.impl.Equal.call
// CHECK:STDOUT:   %.loc12_63.8: bool = converted %Int.as.EqWith.impl.Equal.call, %.loc12_63.7
// CHECK:STDOUT:   %.loc12_63.9: ref %Result.900 = temporary_storage
// CHECK:STDOUT:   if %.loc12_63.8 br !.loc12_63.1 else br !.loc12_63.2
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc12_63.1:
// CHECK:STDOUT:   %.loc12_63.10: %i32 = acquire_value %.loc12_63.1
// CHECK:STDOUT:   %.loc12_63.11: %Result.Ok.type.977 = specific_constant imports.%Core.import_ref.597, @Result(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.Ok.789]
// CHECK:STDOUT:   %Ok.ref.loc12_63: %Result.Ok.type.977 = name_ref Ok, %.loc12_63.11 [concrete = constants.%Result.Ok.789]
// CHECK:STDOUT:   %Result.Ok.specific_fn.loc12_63: <specific function> = specific_function %Ok.ref.loc12_63, @Result.Ok(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.Ok.specific_fn]
// CHECK:STDOUT:   %.loc12_63.12: ref %Result.900 = splice_block %.loc12_63.9 {}
// CHECK:STDOUT:   %Result.Ok.call.loc12_63: init %Result.900 to %.loc12_63.12 = call %Result.Ok.specific_fn.loc12_63(%.loc12_63.10)
// CHECK:STDOUT:   assign %.loc12_63.9, %Result.Ok.call.loc12_63
// CHECK:STDOUT:   br !.loc12_63.3
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc12_63.2:
// CHECK:STDOUT:   %.loc12_63.13: %ptr.00a = acquire_value %.loc12_63.2
// CHECK:STDOUT:   %.loc12_63.14: %Cpp.Exception = as_compatible %.loc12_63.13
// CHECK:STDOUT:   %.loc12_63.15: %Cpp.Exception = converted %.loc12_63.13, %.loc12_63.14
// CHECK:STDOUT:   %.loc12_63.16: %Result.Err.type.a4b = specific_constant imports.%Core.import_ref.bfc4, @Result(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.Err.7cb]
// CHECK:STDOUT:   %Err.ref: %Result.Err.type.a4b = name_ref Err, %.loc12_63.16 [concrete = constants.%Result.Err.7cb]
// CHECK:STDOUT:   %Result.Err.specific_fn: <specific function> = specific_function %Err.ref, @Result.Err(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.Err.specific_fn.031]
// CHECK:STDOUT:   %.loc12_63.17: ref %Result.900 = splice_block %.loc12_63.9 {}
// CHECK:STDOUT:   %Result.Err.call: init %Result.900 to %.loc12_63.17 = call %Result.Err.specific_fn(%.loc12_63.15)
// CHECK:STDOUT:   assign %.loc12_63.9, %Result.Err.call
// CHECK:STDOUT:   br !.loc12_63.3
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc12_63.3:
// CHECK:STDOUT:   %.loc12_63.18: %Result.900 = acquire_value %.loc12_63.9
// CHECK:STDOUT:   %impl.elem2: %.8bc = impl_witness_access constants.%Try.impl_witness.d5a, element2 [concrete = constants.%Result.as.Try.impl.Branch.1b9]
// CHECK:STDOUT:   %bound_method.loc12_64.1: <bound method> = bound_method %.loc12_63.18, %impl.elem2
// CHECK:STDOUT:   %specific_fn.loc12_64.1: <specific function> = specific_function %impl.elem2, @Result.as.Try.impl.Branch(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.as.Try.impl.Branch.specific_fn.2e1]
// CHECK:STDOUT:   %bound_method.loc12_64.2: <bound method> = bound_method %.loc12_63.18, %specific_fn.loc12_64.1
// CHECK:STDOUT:   %.loc12_64.1: ref %ControlFlow.bd1 = temporary_storage
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.call: init %ControlFlow.bd1 to %.loc12_64.1 = call %bound_method.loc12_64.2(%.loc12_63.18)
// CHECK:STDOUT:   %.loc12_64.2: ref %ControlFlow.bd1 = temporary %.loc12_64.1, %Result.as.Try.impl.Branch.call
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc12_64.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc12_64.3: <bound method> = bound_method %int_1, %impl.elem0.loc12_64.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc12_64.2: <specific function> = specific_function %impl.elem0.loc12_64.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc12_64.4: <bound method> = bound_method %int_1, %specific_fn.loc12_64.2 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc12_64: init %u1 = call %bound_method.loc12_64.4(%int_1) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc12_64.3: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc12_64 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc12_64.4: %u1 = converted %int_1, %.loc12_64.3 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc12_64.5: ref %u1 = class_element_access %.loc12_64.2, element0
// CHECK:STDOUT:   %impl.elem0.loc12_64.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc12_64.5: <bound method> = bound_method %.loc12_64.4, %impl.elem0.loc12_64.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound]
// CHECK:STDOUT:   %specific_fn.loc12_64.3: <specific function> = specific_function %impl.elem0.loc12_64.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc12_64.6: <bound method> = bound_method %.loc12_64.4, %specific_fn.loc12_64.3 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc12_64.6: %u1 = acquire_value %.loc12_64.5
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call: init bool = call %bound_method.loc12_64.6(%.loc12_64.4, %.loc12_64.6)
// CHECK:STDOUT:   %.loc12_64.7: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call
// CHECK:STDOUT:   %.loc12_64.8: bool = converted %UInt.as.EqWith.impl.Equal.call, %.loc12_64.7
// CHECK:STDOUT:   if %.loc12_64.8 br !.loc12_64.1 else br !.loc12_64.2
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc12_64.1:
// CHECK:STDOUT:   %.loc12_64.9: ref %.337 = class_element_access %.loc12_64.2, element1
// CHECK:STDOUT:   %.loc12_64.10: ref %tuple.type.b42 = class_element_access %.loc12_64.9, element1
// CHECK:STDOUT:   %tuple.elem0.loc12_64.1: ref %Cpp.Exception = tuple_access %.loc12_64.10, element0
// CHECK:STDOUT:   %.loc12_64.11: %Cpp.Exception = acquire_value %tuple.elem0.loc12_64.1
// CHECK:STDOUT:   %Try.facet: %Try.type = facet_value constants.%Result.900, (constants.%Try.impl_witness.d5a) [concrete = constants.%Try.facet.51d]
// CHECK:STDOUT:   %.loc12_64.12: %Try.type = converted constants.%Result.900, %Try.facet [concrete = constants.%Try.facet.51d]
// CHECK:STDOUT:   %impl.elem3: %.cfb = impl_witness_access constants.%Try.impl_witness.d5a, element3 [concrete = constants.%Result.as.Try.impl.FromBreak.c94]
// CHECK:STDOUT:   %specific_fn.loc12_64.4: <specific function> = specific_function %impl.elem3, @Result.as.Try.impl.FromBreak(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.as.Try.impl.FromBreak.specific_fn]
// CHECK:STDOUT:   %.loc11_41.1: ref %Result.900 = splice_block %return.param {}
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.call: init %Result.900 to %.loc11_41.1 = call %specific_fn.loc12_64.4(%.loc12_64.11)
// CHECK:STDOUT:   %Destroy.Op.bound.loc12_64.1: <bound method> = bound_method %.loc12_64.2, constants.%Destroy.Op.1a2547.11
// CHECK:STDOUT:   %Destroy.Op.call.loc12_64.1: init %empty_tuple.type = call %Destroy.Op.bound.loc12_64.1(%.loc12_64.2)
// CHECK:STDOUT:   return %Result.as.Try.impl.FromBreak.call to %return.param
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc12_64.2:
// CHECK:STDOUT:   %.loc12_64.13: ref %.337 = class_element_access %.loc12_64.2, element1
// CHECK:STDOUT:   %.loc12_64.14: ref %tuple.type.a8a = class_element_access %.loc12_64.13, element0
// CHECK:STDOUT:   %tuple.elem0.loc12_64.2: ref %i32 = tuple_access %.loc12_64.14, element0
// CHECK:STDOUT:   %.loc12_64.15: %i32 = acquire_value %tuple.elem0.loc12_64.2
// CHECK:STDOUT:   %Result.Ok.specific_fn.loc12_41: <specific function> = specific_function %Ok.ref.loc12_41, @Result.Ok(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.Ok.specific_fn]
// CHECK:STDOUT:   %.loc11_41.2: ref %Result.900 = splice_block %return.param {}
// CHECK:STDOUT:   %Result.Ok.call.loc12_65: init %Result.900 to %.loc11_41.2 = call %Result.Ok.specific_fn.loc12_41(%.loc12_64.15)
// CHECK:STDOUT:   %Destroy.Op.bound.loc12_64.2: <bound method> = bound_method %.loc12_64.2, constants.%Destroy.Op.1a2547.11
// CHECK:STDOUT:   %Destroy.Op.call.loc12_64.2: init %empty_tuple.type = call %Destroy.Op.bound.loc12_64.2(%.loc12_64.2)
// CHECK:STDOUT:   return %Result.Ok.call.loc12_65 to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc12_64.1(%self.param: ref %u1.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc12_64.2(%self.param: ref %u1) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc12_64.3(%self.param: ref %i32.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc12_64.4(%self.param: ref %i32) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc12_64.5(%self.param: ref %tuple.type.a8a) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc12_64.6(%self.param: ref %ptr.00a) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc12_64.7(%self.param: ref %Cpp.Exception) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc12_64.8(%self.param: ref %tuple.type.b42) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc12_64.9(%self.param: ref %.337) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc12_64.10(%self.param: ref %struct_type.discriminant.payload.b51) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc12_64.11(%self.param: ref %ControlFlow.bd1) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- void_callee.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %Result.type: type = generic_class_type @Result [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %Result.generic: %Result.type = struct_value () [concrete]
// CHECK:STDOUT:   %E: type = symbolic_binding E, 1 [symbolic]
// CHECK:STDOUT:   %T.67d: type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %u1: type = class_type @UInt, @UInt(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %u1.builtin: type = int_type unsigned, %int_1.5b8 [concrete]
// CHECK:STDOUT:   %Result.Err.type.b75: type = fn_type @Result.Err, @Result(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %Result.Err.08c: %Result.Err.type.b75 = struct_value () [symbolic]
// CHECK:STDOUT:   %Result.Ok.type.898: type = fn_type @Result.Ok, @Result(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %Result.Ok.58a: %Result.Ok.type.898 = struct_value () [symbolic]
// CHECK:STDOUT:   %int_1.233: %u1 = int_value 1 [concrete]
// CHECK:STDOUT:   %empty_tuple: %empty_tuple.type = tuple_value () [concrete]
// CHECK:STDOUT:   %Cpp.Exception: type = class_type @Exception [concrete]
// CHECK:STDOUT:   %Cpp.void: type = class_type @VoidBase [concrete]
// CHECK:STDOUT:   %ptr.00a: type = ptr_type %Cpp.void [concrete]
// CHECK:STDOUT:   %Result.4ff: type = class_type @Result, @Result(%empty_tuple.type, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %.8f5: Core.Form = init_form %Result.4ff [concrete]
// CHECK:STDOUT:   %pattern_type.1da: type = pattern_type %Result.4ff [concrete]
// CHECK:STDOUT:   %return.param_patt.1e0: %pattern_type.1da = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.064: %pattern_type.1da = return_slot_pattern %return.param_patt.1e0, %Result.4ff [concrete]
// CHECK:STDOUT:   %G.type: type = fn_type @G [concrete]
// CHECK:STDOUT:   %G: %G.type = struct_value () [concrete]
// CHECK:STDOUT:   %tuple.type.9fb: type = tuple_type (%empty_tuple.type) [concrete]
// CHECK:STDOUT:   %tuple.type.b42: type = tuple_type (%Cpp.Exception) [concrete]
// CHECK:STDOUT:   %Result.Ok.type.7b6: type = fn_type @Result.Ok, @Result(%empty_tuple.type, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %Result.Ok.c09: %Result.Ok.type.7b6 = struct_value () [concrete]
// CHECK:STDOUT:   %Result.Err.type.6e1: type = fn_type @Result.Err, @Result(%empty_tuple.type, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %Result.Err.f45: %Result.Err.type.6e1 = struct_value () [concrete]
// CHECK:STDOUT:   %may_throw.cpp_overload_set.type: type = cpp_overload_set_type @may_throw.cpp_overload_set [concrete]
// CHECK:STDOUT:   %may_throw.cpp_overload_set.value: %may_throw.cpp_overload_set.type = cpp_overload_set_value @may_throw.cpp_overload_set [concrete]
// CHECK:STDOUT:   %Try.type: type = facet_type <@Try> [concrete]
// CHECK:STDOUT:   %ptr.6f9: type = ptr_type %ptr.00a [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %Int.type: type = generic_class_type @Int [concrete]
// CHECK:STDOUT:   %Int.generic: %Int.type = struct_value () [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %may_throw__carbon_catching_thunk.type: type = fn_type @may_throw__carbon_catching_thunk [concrete]
// CHECK:STDOUT:   %may_throw__carbon_catching_thunk: %may_throw__carbon_catching_thunk.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.0ff: type = generic_interface_type @ImplicitAs [concrete]
// CHECK:STDOUT:   %ImplicitAs.generic: %ImplicitAs.type.0ff = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %To.fe9: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.48f: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet.48f [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.6e0: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_0.3c0: %i32 = int_value 0 [concrete]
// CHECK:STDOUT:   %EqWith.type.f77: type = generic_interface_type @EqWith [concrete]
// CHECK:STDOUT:   %EqWith.generic: %EqWith.type.f77 = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.type.8ee: type = facet_type <@EqWith, @EqWith(%i32)> [concrete]
// CHECK:STDOUT:   %M: Core.IntLiteral = symbolic_binding M, 1 [symbolic]
// CHECK:STDOUT:   %Int.as.EqWith.impl.Equal.type.9a2: type = fn_type @Int.as.EqWith.impl.Equal.1, @Int.as.EqWith.impl.e9c(%N, %M) [symbolic]
// CHECK:STDOUT:   %Int.as.EqWith.impl.Equal.792: %Int.as.EqWith.impl.Equal.type.9a2 = struct_value () [symbolic]
// CHECK:STDOUT:   %EqWith.impl_witness.34c: <witness> = impl_witness imports.%EqWith.impl_witness_table.09e, @Int.as.EqWith.impl.e9c(%int_32, %int_32) [concrete]
// CHECK:STDOUT:   %Int.as.EqWith.impl.Equal.type.01c: type = fn_type @Int.as.EqWith.impl.Equal.1, @Int.as.EqWith.impl.e9c(%int_32, %int_32) [concrete]
// CHECK:STDOUT:   %Int.as.EqWith.impl.Equal.34f: %Int.as.EqWith.impl.Equal.type.01c = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.508: %EqWith.type.8ee = facet_value %i32, (%EqWith.impl_witness.34c) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.530: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%i32, %EqWith.facet.508) [concrete]
// CHECK:STDOUT:   %.a79: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.530, %EqWith.facet.508 [concrete]
// CHECK:STDOUT:   %Int.as.EqWith.impl.Equal.specific_fn.12d: <specific function> = specific_function %Int.as.EqWith.impl.Equal.34f, @Int.as.EqWith.impl.Equal.1(%int_32, %int_32) [concrete]
// CHECK:STDOUT:   %Result.Ok.specific_fn: <specific function> = specific_function %Result.Ok.c09, @Result.Ok(%empty_tuple.type, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %Result.Err.specific_fn.75e: <specific function> = specific_function %Result.Err.f45, @Result.Err(%empty_tuple.type, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.type.834: type = fn_type @Result.as.Try.impl.FromBreak, @Result.as.Try.impl(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.9cc: %Result.as.Try.impl.FromBreak.type.834 = struct_value () [symbolic]
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.type.d6a: type = fn_type @Result.as.Try.impl.Branch, @Result.as.Try.impl(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.513: %Result.as.Try.impl.Branch.type.d6a = struct_value () [symbolic]
// CHECK:STDOUT:   %Try.impl_witness.875: <witness> = impl_witness imports.%Try.impl_witness_table, @Result.as.Try.impl(%empty_tuple.type, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.type.95b: type = fn_type @Result.as.Try.impl.Branch, @Result.as.Try.impl(%empty_tuple.type, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.209: %Result.as.Try.impl.Branch.type.95b = struct_value () [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.type.369: type = fn_type @Result.as.Try.impl.FromBreak, @Result.as.Try.impl(%empty_tuple.type, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.839: %Result.as.Try.impl.FromBreak.type.369 = struct_value () [concrete]
// CHECK:STDOUT:   %Try.facet.803: %Try.type = facet_value %Result.4ff, (%Try.impl_witness.875) [concrete]
// CHECK:STDOUT:   %Try.WithSelf.Branch.type.dd93: type = fn_type @Try.WithSelf.Branch, @Try.WithSelf(%Try.facet.803) [concrete]
// CHECK:STDOUT:   %Try.WithSelf.FromBreak.type.f85: type = fn_type @Try.WithSelf.FromBreak, @Try.WithSelf(%Try.facet.803) [concrete]
// CHECK:STDOUT:   %.d88: type = fn_type_with_self_type %Try.WithSelf.Branch.type.dd93, %Try.facet.803 [concrete]
// CHECK:STDOUT:   %ControlFlow.ba8: type = class_type @ControlFlow, @ControlFlow(%empty_tuple.type, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.specific_fn.29b: <specific function> = specific_function %Result.as.Try.impl.Branch.209, @Result.as.Try.impl.Branch(%empty_tuple.type, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %.53b: type = custom_layout_type {size=8, align=8, .Continue@0: %tuple.type.9fb, .Break@0: %tuple.type.b42} [concrete]
// CHECK:STDOUT:   %struct_type.discriminant.payload.50e: type = struct_type {.discriminant: %u1, .payload: %.53b} [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.ca1: type = facet_type <@ImplicitAs, @ImplicitAs(%u1)> [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.b68(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.170: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.f4c: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.f01, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.46b: %ImplicitAs.type.ca1 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.f4c) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.77c: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%u1, %ImplicitAs.facet.46b) [concrete]
// CHECK:STDOUT:   %.e74: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.77c, %ImplicitAs.facet.46b [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.d7a: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
// CHECK:STDOUT:   %EqWith.type.c25: type = facet_type <@EqWith, @EqWith(%u1)> [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.544: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%N, %M) [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.c67: %UInt.as.EqWith.impl.Equal.type.544 = struct_value () [symbolic]
// CHECK:STDOUT:   %EqWith.impl_witness.7b3: <witness> = impl_witness imports.%EqWith.impl_witness_table.166, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.29b: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.ba4: %UInt.as.EqWith.impl.Equal.type.29b = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.4d0: %EqWith.type.c25 = facet_value %u1, (%EqWith.impl_witness.7b3) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.e3c: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%u1, %EqWith.facet.4d0) [concrete]
// CHECK:STDOUT:   %.9eb: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.e3c, %EqWith.facet.4d0 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.specific_fn.6b6: <specific function> = specific_function %UInt.as.EqWith.impl.Equal.ba4, @UInt.as.EqWith.impl.Equal.1(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.a82: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
// CHECK:STDOUT:   %.0fd: type = fn_type_with_self_type %Try.WithSelf.FromBreak.type.f85, %Try.facet.803 [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.specific_fn: <specific function> = specific_function %Result.as.Try.impl.FromBreak.839, @Result.as.Try.impl.FromBreak(%empty_tuple.type, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %Destroy.type: type = facet_type <@Destroy> [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.10: type = fn_type @Destroy.Op.loc14_18.10 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.10: %Destroy.Op.type.1d8f74.10 = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .Result = %Core.Result
// CHECK:STDOUT:     .CppCompat = %CppCompat.f0dbf9.1
// CHECK:STDOUT:     .Try = %Core.Try
// CHECK:STDOUT:     .Int = %Core.Int
// CHECK:STDOUT:     .ImplicitAs = %Core.ImplicitAs
// CHECK:STDOUT:     .EqWith = %Core.EqWith
// CHECK:STDOUT:     .Destroy = %Core.Destroy
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Cpp: <namespace> = namespace file.%Cpp.import_cpp, [concrete] {
// CHECK:STDOUT:     .Exception = constants.%Cpp.Exception
// CHECK:STDOUT:     .may_throw = %may_throw.cpp_overload_set.value
// CHECK:STDOUT:     import Cpp//...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Result: %Result.type = import_ref Core//prelude/types/result, Result, loaded [concrete = constants.%Result.generic]
// CHECK:STDOUT:   %Core.import_ref.597: @Result.%Result.Ok.type (%Result.Ok.type.898) = import_ref Core//prelude/types/result, loc{{\d+_\d+}}, loaded [symbolic = @Result.%Result.Ok (constants.%Result.Ok.58a)]
// CHECK:STDOUT:   %Core.import_ref.bfc4: @Result.%Result.Err.type (%Result.Err.type.b75) = import_ref Core//prelude/types/result, loc{{\d+_\d+}}, loaded [symbolic = @Result.%Result.Err (constants.%Result.Err.08c)]
// CHECK:STDOUT:   %Core.CppCompat: <namespace> = import_ref Core//prelude, CppCompat, loaded
// CHECK:STDOUT:   %CppCompat.f0dbf9.1: <namespace> = namespace %Core.CppCompat, [concrete] {
// CHECK:STDOUT:     .Exception = %Core.Exception
// CHECK:STDOUT:     .VoidBase = %Core.VoidBase
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Exception: type = import_ref Core//prelude/types/cpp/exception, Exception, loaded [concrete = constants.%Cpp.Exception]
// CHECK:STDOUT:   %may_throw.cpp_overload_set.value: %may_throw.cpp_overload_set.type = cpp_overload_set_value @may_throw.cpp_overload_set [concrete = constants.%may_throw.cpp_overload_set.value]
// CHECK:STDOUT:   %Core.Try: type = import_ref Core//prelude/try, Try, loaded [concrete = constants.%Try.type]
// CHECK:STDOUT:   %Core.VoidBase: type = import_ref Core//prelude/types/cpp/void, VoidBase, loaded [concrete = constants.%Cpp.void]
// CHECK:STDOUT:   %Core.Int: %Int.type = import_ref Core//prelude/types/int, Int, loaded [concrete = constants.%Int.generic]
// CHECK:STDOUT:   %may_throw__carbon_catching_thunk.decl: %may_throw__carbon_catching_thunk.type = fn_decl @may_throw__carbon_catching_thunk [concrete = constants.%may_throw__carbon_catching_thunk] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.ImplicitAs: %ImplicitAs.type.0ff = import_ref Core//prelude/operators/as, ImplicitAs, loaded [concrete = constants.%ImplicitAs.generic]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.EqWith: %EqWith.type.f77 = import_ref Core//prelude/operators/comparison, EqWith, loaded [concrete = constants.%EqWith.generic]
// CHECK:STDOUT:   %Core.import_ref.074: @Int.as.EqWith.impl.e9c.%Int.as.EqWith.impl.Equal.type (%Int.as.EqWith.impl.Equal.type.9a2) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.EqWith.impl.e9c.%Int.as.EqWith.impl.Equal (constants.%Int.as.EqWith.impl.Equal.792)]
// CHECK:STDOUT:   %Core.import_ref.449 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.09e = impl_witness_table (%Core.import_ref.074, %Core.import_ref.449), @Int.as.EqWith.impl.e9c [concrete]
// CHECK:STDOUT:   %Core.import_ref.0b3 = import_ref Core//prelude/types/result, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.6e9 = import_ref Core//prelude/types/result, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9f4: @Result.as.Try.impl.%Result.as.Try.impl.Branch.type (%Result.as.Try.impl.Branch.type.d6a) = import_ref Core//prelude/types/result, loc{{\d+_\d+}}, loaded [symbolic = @Result.as.Try.impl.%Result.as.Try.impl.Branch (constants.%Result.as.Try.impl.Branch.513)]
// CHECK:STDOUT:   %Core.import_ref.6a4: @Result.as.Try.impl.%Result.as.Try.impl.FromBreak.type (%Result.as.Try.impl.FromBreak.type.834) = import_ref Core//prelude/types/result, loc{{\d+_\d+}}, loaded [symbolic = @Result.as.Try.impl.%Result.as.Try.impl.FromBreak (constants.%Result.as.Try.impl.FromBreak.9cc)]
// CHECK:STDOUT:   %Try.impl_witness_table = impl_witness_table (%Core.import_ref.0b3, %Core.import_ref.6e9, %Core.import_ref.9f4, %Core.import_ref.6a4), @Result.as.Try.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.aa5: @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.170)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.f01 = impl_witness_table (%Core.import_ref.aa5), @Core.IntLiteral.as.ImplicitAs.impl.b68 [concrete]
// CHECK:STDOUT:   %Core.import_ref.b92: @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal.type (%UInt.as.EqWith.impl.Equal.type.544) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal (constants.%UInt.as.EqWith.impl.Equal.c67)]
// CHECK:STDOUT:   %Core.import_ref.b44 = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.166 = impl_witness_table (%Core.import_ref.b92, %Core.import_ref.b44), @UInt.as.EqWith.impl.f13 [concrete]
// CHECK:STDOUT:   %Core.Destroy: type = import_ref Core//prelude/destroy, Destroy, loaded [concrete = constants.%Destroy.type]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %G.decl: %G.type = fn_decl @G [concrete = constants.%G] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.1da = out_param_pattern [concrete = constants.%return.param_patt.1e0]
// CHECK:STDOUT:     %return.patt: %pattern_type.1da = return_slot_pattern %return.param_patt, %Result.loc13 [concrete = constants.%return.patt.064]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %Core.ref.loc13: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:     %Result.ref.loc13: %Result.type = name_ref Result, imports.%Core.Result [concrete = constants.%Result.generic]
// CHECK:STDOUT:     %.loc13_24: %empty_tuple.type = tuple_literal () [concrete = constants.%empty_tuple]
// CHECK:STDOUT:     %Cpp.ref.loc13: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:     %Exception.ref.loc13: type = name_ref Exception, constants.%Cpp.Exception [concrete = constants.%Cpp.Exception]
// CHECK:STDOUT:     %.loc13_40.3: type = converted %.loc13_24, constants.%empty_tuple.type [concrete = constants.%empty_tuple.type]
// CHECK:STDOUT:     %Result.loc13: type = class_type @Result, @Result(constants.%empty_tuple.type, constants.%Cpp.Exception) [concrete = constants.%Result.4ff]
// CHECK:STDOUT:     %.loc13_40.4: Core.Form = init_form %Result.loc13 [concrete = constants.%.8f5]
// CHECK:STDOUT:     %return.param: ref %Result.4ff = out_param call_param0
// CHECK:STDOUT:     %return: ref %Result.4ff = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @G() -> out %return.param: %Result.4ff {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Cpp.ref.loc14: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:   %may_throw.ref: %may_throw.cpp_overload_set.type = name_ref may_throw, imports.%may_throw.cpp_overload_set.value [concrete = constants.%may_throw.cpp_overload_set.value]
// CHECK:STDOUT:   %Result.loc14: type = class_type @Result, @Result(constants.%empty_tuple.type, constants.%Cpp.Exception) [concrete = constants.%Result.4ff]
// CHECK:STDOUT:   %.loc14_17.1: ref %ptr.00a = temporary_storage
// CHECK:STDOUT:   %addr: %ptr.6f9 = addr_of %.loc14_17.1
// CHECK:STDOUT:   %may_throw__carbon_catching_thunk.call: init %i32 = call imports.%may_throw__carbon_catching_thunk.decl(%addr)
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc14_17.1: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc14_17.1: <bound method> = bound_method %int_0, %impl.elem0.loc14_17.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc14_17.1: <specific function> = specific_function %impl.elem0.loc14_17.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc14_17.2: <bound method> = bound_method %int_0, %specific_fn.loc14_17.1 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14_17: init %i32 = call %bound_method.loc14_17.2(%int_0) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc14_17.2: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14_17 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc14_17.3: %i32 = converted %int_0, %.loc14_17.2 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %impl.elem0.loc14_17.2: %.a79 = impl_witness_access constants.%EqWith.impl_witness.34c, element0 [concrete = constants.%Int.as.EqWith.impl.Equal.34f]
// CHECK:STDOUT:   %bound_method.loc14_17.3: <bound method> = bound_method %may_throw__carbon_catching_thunk.call, %impl.elem0.loc14_17.2
// CHECK:STDOUT:   %specific_fn.loc14_17.2: <specific function> = specific_function %impl.elem0.loc14_17.2, @Int.as.EqWith.impl.Equal.1(constants.%int_32, constants.%int_32) [concrete = constants.%Int.as.EqWith.impl.Equal.specific_fn.12d]
// CHECK:STDOUT:   %bound_method.loc14_17.4: <bound method> = bound_method %may_throw__carbon_catching_thunk.call, %specific_fn.loc14_17.2
// CHECK:STDOUT:   %.loc14_17.4: %i32 = value_of_initializer %may_throw__carbon_catching_thunk.call
// CHECK:STDOUT:   %.loc14_17.5: %i32 = converted %may_throw__carbon_catching_thunk.call, %.loc14_17.4
// CHECK:STDOUT:   %Int.as.EqWith.impl.Equal.call: init bool = call %bound_method.loc14_17.4(%.loc14_17.5, %.loc14_17.3)
// CHECK:STDOUT:   %.loc14_17.6: bool = value_of_initializer %Int.as.EqWith.impl.Equal.call
// CHECK:STDOUT:   %.loc14_17.7: bool = converted %Int.as.EqWith.impl.Equal.call, %.loc14_17.6
// CHECK:STDOUT:   %.loc14_17.8: ref %Result.4ff = temporary_storage
// CHECK:STDOUT:   if %.loc14_17.7 br !.loc14_17.1 else br !.loc14_17.2
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc14_17.1:
// CHECK:STDOUT:   %empty_tuple.loc14: %empty_tuple.type = tuple_value () [concrete = constants.%empty_tuple]
// CHECK:STDOUT:   %.loc14_17.9: %Result.Ok.type.7b6 = specific_constant imports.%Core.import_ref.597, @Result(constants.%empty_tuple.type, constants.%Cpp.Exception) [concrete = constants.%Result.Ok.c09]
// CHECK:STDOUT:   %Ok.ref.loc14: %Result.Ok.type.7b6 = name_ref Ok, %.loc14_17.9 [concrete = constants.%Result.Ok.c09]
// CHECK:STDOUT:   %Result.Ok.specific_fn.loc14: <specific function> = specific_function %Ok.ref.loc14, @Result.Ok(constants.%empty_tuple.type, constants.%Cpp.Exception) [concrete = constants.%Result.Ok.specific_fn]
// CHECK:STDOUT:   %.loc14_17.10: ref %Result.4ff = splice_block %.loc14_17.8 {}
// CHECK:STDOUT:   %Result.Ok.call.loc14: init %Result.4ff to %.loc14_17.10 = call %Result.Ok.specific_fn.loc14(%empty_tuple.loc14)
// CHECK:STDOUT:   assign %.loc14_17.8, %Result.Ok.call.loc14
// CHECK:STDOUT:   br !.loc14_17.3
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc14_17.2:
// CHECK:STDOUT:   %.loc14_17.11: %ptr.00a = acquire_value %.loc14_17.1
// CHECK:STDOUT:   %.loc14_17.12: %Cpp.Exception = as_compatible %.loc14_17.11
// CHECK:STDOUT:   %.loc14_17.13: %Cpp.Exception = converted %.loc14_17.11, %.loc14_17.12
// CHECK:STDOUT:   %.loc14_17.14: %Result.Err.type.6e1 = specific_constant imports.%Core.import_ref.bfc4, @Result(constants.%empty_tuple.type, constants.%Cpp.Exception) [concrete = constants.%Result.Err.f45]
// CHECK:STDOUT:   %Err.ref: %Result.Err.type.6e1 = name_ref Err, %.loc14_17.14 [concrete = constants.%Result.Err.f45]
// CHECK:STDOUT:   %Result.Err.specific_fn: <specific function> = specific_function %Err.ref, @Result.Err(constants.%empty_tuple.type, constants.%Cpp.Exception) [concrete = constants.%Result.Err.specific_fn.75e]
// CHECK:STDOUT:   %.loc14_17.15: ref %Result.4ff = splice_block %.loc14_17.8 {}
// CHECK:STDOUT:   %Result.Err.call: init %Result.4ff to %.loc14_17.15 = call %Result.Err.specific_fn(%.loc14_17.13)
// CHECK:STDOUT:   assign %.loc14_17.8, %Result.Err.call
// CHECK:STDOUT:   br !.loc14_17.3
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc14_17.3:
// CHECK:STDOUT:   %.loc14_17.16: %Result.4ff = acquire_value %.loc14_17.8
// CHECK:STDOUT:   %impl.elem2: %.d88 = impl_witness_access constants.%Try.impl_witness.875, element2 [concrete = constants.%Result.as.Try.impl.Branch.209]
// CHECK:STDOUT:   %bound_method.loc14_18.1: <bound method> = bound_method %.loc14_17.16, %impl.elem2
// CHECK:STDOUT:   %specific_fn.loc14_18.1: <specific function> = specific_function %impl.elem2, @Result.as.Try.impl.Branch(constants.%empty_tuple.type, constants.%Cpp.Exception) [concrete = constants.%Result.as.Try.impl.Branch.specific_fn.29b]
// CHECK:STDOUT:   %bound_method.loc14_18.2: <bound method> = bound_method %.loc14_17.16, %specific_fn.loc14_18.1
// CHECK:STDOUT:   %.loc14_18.1: ref %ControlFlow.ba8 = temporary_storage
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.call: init %ControlFlow.ba8 to %.loc14_18.1 = call %bound_method.loc14_18.2(%.loc14_17.16)
// CHECK:STDOUT:   %.loc14_18.2: ref %ControlFlow.ba8 = temporary %.loc14_18.1, %Result.as.Try.impl.Branch.call
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc14_18.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc14_18.3: <bound method> = bound_method %int_1, %impl.elem0.loc14_18.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc14_18.2: <specific function> = specific_function %impl.elem0.loc14_18.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc14_18.4: <bound method> = bound_method %int_1, %specific_fn.loc14_18.2 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14_18: init %u1 = call %bound_method.loc14_18.4(%int_1) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc14_18.3: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14_18 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc14_18.4: %u1 = converted %int_1, %.loc14_18.3 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc14_18.5: ref %u1 = class_element_access %.loc14_18.2, element0
// CHECK:STDOUT:   %impl.elem0.loc14_18.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc14_18.5: <bound method> = bound_method %.loc14_18.4, %impl.elem0.loc14_18.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound]
// CHECK:STDOUT:   %specific_fn.loc14_18.3: <specific function> = specific_function %impl.elem0.loc14_18.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc14_18.6: <bound method> = bound_method %.loc14_18.4, %specific_fn.loc14_18.3 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc14_18.6: %u1 = acquire_value %.loc14_18.5
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call: init bool = call %bound_method.loc14_18.6(%.loc14_18.4, %.loc14_18.6)
// CHECK:STDOUT:   %.loc14_18.7: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call
// CHECK:STDOUT:   %.loc14_18.8: bool = converted %UInt.as.EqWith.impl.Equal.call, %.loc14_18.7
// CHECK:STDOUT:   if %.loc14_18.8 br !.loc14_18.1 else br !.loc14_18.2
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc14_18.1:
// CHECK:STDOUT:   %.loc14_18.9: ref %.53b = class_element_access %.loc14_18.2, element1
// CHECK:STDOUT:   %.loc14_18.10: ref %tuple.type.b42 = class_element_access %.loc14_18.9, element1
// CHECK:STDOUT:   %tuple.elem0.loc14_18.1: ref %Cpp.Exception = tuple_access %.loc14_18.10, element0
// CHECK:STDOUT:   %.loc14_18.11: %Cpp.Exception = acquire_value %tuple.elem0.loc14_18.1
// CHECK:STDOUT:   %Try.facet: %Try.type = facet_value constants.%Result.4ff, (constants.%Try.impl_witness.875) [concrete = constants.%Try.facet.803]
// CHECK:STDOUT:   %.loc14_18.12: %Try.type = converted constants.%Result.4ff, %Try.facet [concrete = constants.%Try.facet.803]
// CHECK:STDOUT:   %impl.elem3: %.0fd = impl_witness_access constants.%Try.impl_witness.875, element3 [concrete = constants.%Result.as.Try.impl.FromBreak.839]
// CHECK:STDOUT:   %specific_fn.loc14_18.4: <specific function> = specific_function %impl.elem3, @Result.as.Try.impl.FromBreak(constants.%empty_tuple.type, constants.%Cpp.Exception) [concrete = constants.%Result.as.Try.impl.FromBreak.specific_fn]
// CHECK:STDOUT:   %.loc13_40.1: ref %Result.4ff = splice_block %return.param {}
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.call: init %Result.4ff to %.loc13_40.1 = call %specific_fn.loc14_18.4(%.loc14_18.11)
// CHECK:STDOUT:   %Destroy.Op.bound.loc14_18.1: <bound method> = bound_method %.loc14_18.2, constants.%Destroy.Op.1a2547.10
// CHECK:STDOUT:   %Destroy.Op.call.loc14_18.1: init %empty_tuple.type = call %Destroy.Op.bound.loc14_18.1(%.loc14_18.2)
// CHECK:STDOUT:   return %Result.as.Try.impl.FromBreak.call to %return.param
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc14_18.2:
// CHECK:STDOUT:   %.loc14_18.13: ref %.53b = class_element_access %.loc14_18.2, element1
// CHECK:STDOUT:   %.loc14_18.14: ref %tuple.type.9fb = class_element_access %.loc14_18.13, element0
// CHECK:STDOUT:   %tuple.elem0.loc14_18.2: ref %empty_tuple.type = tuple_access %.loc14_18.14, element0
// CHECK:STDOUT:   %tuple: %empty_tuple.type = tuple_value () [concrete = constants.%empty_tuple]
// CHECK:STDOUT:   %.loc14_18.15: %empty_tuple.type = converted %tuple.elem0.loc14_18.2, %tuple [concrete = constants.%empty_tuple]
// CHECK:STDOUT:   %Destroy.Op.bound.loc14_18.2: <bound method> = bound_method %.loc14_18.2, constants.%Destroy.Op.1a2547.10
// CHECK:STDOUT:   %Destroy.Op.call.loc14_18.2: init %empty_tuple.type = call %Destroy.Op.bound.loc14_18.2(%.loc14_18.2)
// CHECK:STDOUT:   %Core.ref.loc15: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:   %Result.ref.loc15: %Result.type = name_ref Result, imports.%Core.Result [concrete = constants.%Result.generic]
// CHECK:STDOUT:   %.loc15_23: %empty_tuple.type = tuple_literal () [concrete = constants.%empty_tuple]
// CHECK:STDOUT:   %Cpp.ref.loc15: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:   %Exception.ref.loc15: type = name_ref Exception, constants.%Cpp.Exception [concrete = constants.%Cpp.Exception]
// CHECK:STDOUT:   %.loc15_39: type = converted %.loc15_23, constants.%empty_tuple.type [concrete = constants.%empty_tuple.type]
// CHECK:STDOUT:   %Result.loc15: type = class_type @Result, @Result(constants.%empty_tuple.type, constants.%Cpp.Exception) [concrete = constants.%Result.4ff]
// CHECK:STDOUT:   %.loc15_40: %Result.Ok.type.7b6 = specific_constant imports.%Core.import_ref.597, @Result(constants.%empty_tuple.type, constants.%Cpp.Exception) [concrete = constants.%Result.Ok.c09]
// CHECK:STDOUT:   %Ok.ref.loc15: %Result.Ok.type.7b6 = name_ref Ok, %.loc15_40 [concrete = constants.%Result.Ok.c09]
// CHECK:STDOUT:   %.loc15_45.1: %empty_tuple.type = tuple_literal () [concrete = constants.%empty_tuple]
// CHECK:STDOUT:   %Result.Ok.specific_fn.loc15: <specific function> = specific_function %Ok.ref.loc15, @Result.Ok(constants.%empty_tuple.type, constants.%Cpp.Exception) [concrete = constants.%Result.Ok.specific_fn]
// CHECK:STDOUT:   %.loc13_40.2: ref %Result.4ff = splice_block %return.param {}
// CHECK:STDOUT:   %empty_tuple.loc15: %empty_tuple.type = tuple_value () [concrete = constants.%empty_tuple]
// CHECK:STDOUT:   %.loc15_45.2: %empty_tuple.type = converted %.loc15_45.1, %empty_tuple.loc15 [concrete = constants.%empty_tuple]
// CHECK:STDOUT:   %Result.Ok.call.loc15: init %Result.4ff to %.loc13_40.2 = call %Result.Ok.specific_fn.loc15(%.loc15_45.2)
// CHECK:STDOUT:   return %Result.Ok.call.loc15 to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc14_18.1(%self.param: ref %u1.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc14_18.2(%self.param: ref %u1) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc14_18.3(%self.param: ref %empty_tuple.type) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc14_18.4(%self.param: ref %tuple.type.9fb) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc14_18.5(%self.param: ref %ptr.00a) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc14_18.6(%self.param: ref %Cpp.Exception) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc14_18.7(%self.param: ref %tuple.type.b42) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc14_18.8(%self.param: ref %.53b) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc14_18.9(%self.param: ref %struct_type.discriminant.payload.50e) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc14_18.10(%self.param: ref %ControlFlow.ba8) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- nested_argument.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %Result.type: type = generic_class_type @Result [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %Result.generic: %Result.type = struct_value () [concrete]
// CHECK:STDOUT:   %E: type = symbolic_binding E, 1 [symbolic]
// CHECK:STDOUT:   %T.67d: type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %u1: type = class_type @UInt, @UInt(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %u1.builtin: type = int_type unsigned, %int_1.5b8 [concrete]
// CHECK:STDOUT:   %Result.Err.type.b75: type = fn_type @Result.Err, @Result(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %Result.Err.08c: %Result.Err.type.b75 = struct_value () [symbolic]
// CHECK:STDOUT:   %Result.Ok.type.898: type = fn_type @Result.Ok, @Result(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %Result.Ok.58a: %Result.Ok.type.898 = struct_value () [symbolic]
// CHECK:STDOUT:   %int_1.233: %u1 = int_value 1 [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %Int.type: type = generic_class_type @Int [concrete]
// CHECK:STDOUT:   %Int.generic: %Int.type = struct_value () [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %Cpp.Exception: type = class_type @Exception [concrete]
// CHECK:STDOUT:   %Cpp.void: type = class_type @VoidBase [concrete]
// CHECK:STDOUT:   %ptr.00a: type = ptr_type %Cpp.void [concrete]
// CHECK:STDOUT:   %Result.900: type = class_type @Result, @Result(%i32, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %.c19: Core.Form = init_form %Result.900 [concrete]
// CHECK:STDOUT:   %pattern_type.5d9: type = pattern_type %Result.900 [concrete]
// CHECK:STDOUT:   %return.param_patt.8a0: %pattern_type.5d9 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.dd6: %pattern_type.5d9 = return_slot_pattern %return.param_patt.8a0, %Result.900 [concrete]
// CHECK:STDOUT:   %H.type: type = fn_type @H [concrete]
// CHECK:STDOUT:   %H: %H.type = struct_value () [concrete]
// CHECK:STDOUT:   %i32.builtin: type = int_type signed, %int_32 [concrete]
// CHECK:STDOUT:   %tuple.type.a8a: type = tuple_type (%i32) [concrete]
// CHECK:STDOUT:   %tuple.type.b42: type = tuple_type (%Cpp.Exception) [concrete]
// CHECK:STDOUT:   %Result.Ok.type.977: type = fn_type @Result.Ok, @Result(%i32, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %Result.Ok.789: %Result.Ok.type.977 = struct_value () [concrete]
// CHECK:STDOUT:   %Result.Err.type.a4b: type = fn_type @Result.Err, @Result(%i32, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %Result.Err.7cb: %Result.Err.type.a4b = struct_value () [concrete]
// CHECK:STDOUT:   %f.cpp_overload_set.type: type = cpp_overload_set_type @f.cpp_overload_set [concrete]
// CHECK:STDOUT:   %f.cpp_overload_set.value: %f.cpp_overload_set.type = cpp_overload_set_value @f.cpp_overload_set [concrete]
// CHECK:STDOUT:   %g.cpp_overload_set.type: type = cpp_overload_set_type @g.cpp_overload_set [concrete]
// CHECK:STDOUT:   %g.cpp_overload_set.value: %g.cpp_overload_set.type = cpp_overload_set_value @g.cpp_overload_set [concrete]
// CHECK:STDOUT:   %g__carbon_thunk.type: type = fn_type @g__carbon_thunk [concrete]
// CHECK:STDOUT:   %g__carbon_thunk: %g__carbon_thunk.type = struct_value () [concrete]
// CHECK:STDOUT:   %Try.type: type = facet_type <@Try> [concrete]
// CHECK:STDOUT:   %ptr.d08: type = ptr_type %i32 [concrete]
// CHECK:STDOUT:   %ptr.6f9: type = ptr_type %ptr.00a [concrete]
// CHECK:STDOUT:   %f__carbon_catching_thunk.type: type = fn_type @f__carbon_catching_thunk [concrete]
// CHECK:STDOUT:   %f__carbon_catching_thunk: %f__carbon_catching_thunk.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.0ff: type = generic_interface_type @ImplicitAs [concrete]
// CHECK:STDOUT:   %ImplicitAs.generic: %ImplicitAs.type.0ff = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %To.fe9: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.48f: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet.48f [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.6e0: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_0.3c0: %i32 = int_value 0 [concrete]
// CHECK:STDOUT:   %EqWith.type.f77: type = generic_interface_type @EqWith [concrete]
// CHECK:STDOUT:   %EqWith.generic: %EqWith.type.f77 = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.type.8ee: type = facet_type <@EqWith, @EqWith(%i32)> [concrete]
// CHECK:STDOUT:   %M: Core.IntLiteral = symbolic_binding M, 1 [symbolic]
// CHECK:STDOUT:   %Int.as.EqWith.impl.Equal.type.9a2: type = fn_type @Int.as.EqWith.impl.Equal.1, @Int.as.EqWith.impl.e9c(%N, %M) [symbolic]
// CHECK:STDOUT:   %Int.as.EqWith.impl.Equal.792: %Int.as.EqWith.impl.Equal.type.9a2 = struct_value () [symbolic]
// CHECK:STDOUT:   %EqWith.impl_witness.34c: <witness> = impl_witness imports.%EqWith.impl_witness_table.09e, @Int.as.EqWith.impl.e9c(%int_32, %int_32) [concrete]
// CHECK:STDOUT:   %Int.as.EqWith.impl.Equal.type.01c: type = fn_type @Int.as.EqWith.impl.Equal.1, @Int.as.EqWith.impl.e9c(%int_32, %int_32) [concrete]
// CHECK:STDOUT:   %Int.as.EqWith.impl.Equal.34f: %Int.as.EqWith.impl.Equal.type.01c = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.508: %EqWith.type.8ee = facet_value %i32, (%EqWith.impl_witness.34c) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.530: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%i32, %EqWith.facet.508) [concrete]
// CHECK:STDOUT:   %.a79: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.530, %EqWith.facet.508 [concrete]
// CHECK:STDOUT:   %Int.as.EqWith.impl.Equal.specific_fn.12d: <specific function> = specific_function %Int.as.EqWith.impl.Equal.34f, @Int.as.EqWith.impl.Equal.1(%int_32, %int_32) [concrete]
// CHECK:STDOUT:   %Result.Ok.specific_fn: <specific function> = specific_function %Result.Ok.789, @Result.Ok(%i32, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %Result.Err.specific_fn.031: <specific function> = specific_function %Result.Err.7cb, @Result.Err(%i32, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.type.834: type = fn_type @Result.as.Try.impl.FromBreak, @Result.as.Try.impl(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.9cc: %Result.as.Try.impl.FromBreak.type.834 = struct_value () [symbolic]
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.type.d6a: type = fn_type @Result.as.Try.impl.Branch, @Result.as.Try.impl(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.513: %Result.as.Try.impl.Branch.type.d6a = struct_value () [symbolic]
// CHECK:STDOUT:   %Try.impl_witness.d5a: <witness> = impl_witness imports.%Try.impl_witness_table, @Result.as.Try.impl(%i32, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.type.521: type = fn_type @Result.as.Try.impl.Branch, @Result.as.Try.impl(%i32, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.1b9: %Result.as.Try.impl.Branch.type.521 = struct_value () [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.type.b43: type = fn_type @Result.as.Try.impl.FromBreak, @Result.as.Try.impl(%i32, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.c94: %Result.as.Try.impl.FromBreak.type.b43 = struct_value () [concrete]
// CHECK:STDOUT:   %Try.facet.51d: %Try.type = facet_value %Result.900, (%Try.impl_witness.d5a) [concrete]
// CHECK:STDOUT:   %Try.WithSelf.Branch.type.353: type = fn_type @Try.WithSelf.Branch, @Try.WithSelf(%Try.facet.51d) [concrete]
// CHECK:STDOUT:   %Try.WithSelf.FromBreak.type.cf1: type = fn_type @Try.WithSelf.FromBreak, @Try.WithSelf(%Try.facet.51d) [concrete]
// CHECK:STDOUT:   %.8bc: type = fn_type_with_self_type %Try.WithSelf.Branch.type.353, %Try.facet.51d [concrete]
// CHECK:STDOUT:   %ControlFlow.bd1: type = class_type @ControlFlow, @ControlFlow(%i32, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.specific_fn.2e1: <specific function> = specific_function %Result.as.Try.impl.Branch.1b9, @Result.as.Try.impl.Branch(%i32, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %.337: type = custom_layout_type {size=8, align=8, .Continue@0: %tuple.type.a8a, .Break@0: %tuple.type.b42} [concrete]
// CHECK:STDOUT:   %struct_type.discriminant.payload.b51: type = struct_type {.discriminant: %u1, .payload: %.337} [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.ca1: type = facet_type <@ImplicitAs, @ImplicitAs(%u1)> [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.b68(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.170: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.f4c: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.f01, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.46b: %ImplicitAs.type.ca1 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.f4c) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.77c: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%u1, %ImplicitAs.facet.46b) [concrete]
// CHECK:STDOUT:   %.e74: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.77c, %ImplicitAs.facet.46b [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.d7a: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
// CHECK:STDOUT:   %EqWith.type.c25: type = facet_type <@EqWith, @EqWith(%u1)> [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.544: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%N, %M) [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.c67: %UInt.as.EqWith.impl.Equal.type.544 = struct_value () [symbolic]
// CHECK:STDOUT:   %EqWith.impl_witness.7b3: <witness> = impl_witness imports.%EqWith.impl_witness_table.166, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.29b: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.ba4: %UInt.as.EqWith.impl.Equal.type.29b = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.4d0: %EqWith.type.c25 = facet_value %u1, (%EqWith.impl_witness.7b3) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.e3c: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%u1, %EqWith.facet.4d0) [concrete]
// CHECK:STDOUT:   %.9eb: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.e3c, %EqWith.facet.4d0 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.specific_fn.6b6: <specific function> = specific_function %UInt.as.EqWith.impl.Equal.ba4, @UInt.as.EqWith.impl.Equal.1(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.a82: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
// CHECK:STDOUT:   %.cfb: type = fn_type_with_self_type %Try.WithSelf.FromBreak.type.cf1, %Try.facet.51d [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.specific_fn: <specific function> = specific_function %Result.as.Try.impl.FromBreak.c94, @Result.as.Try.impl.FromBreak(%i32, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %Destroy.type: type = facet_type <@Destroy> [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.11: type = fn_type @Destroy.Op.loc16_59.11 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.11: %Destroy.Op.type.1d8f74.11 = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .Result = %Core.Result
// CHECK:STDOUT:     .Int = %Core.Int
// CHECK:STDOUT:     .CppCompat = %CppCompat.f0dbf9.1
// CHECK:STDOUT:     .Try = %Core.Try
// CHECK:STDOUT:     .ImplicitAs = %Core.ImplicitAs
// CHECK:STDOUT:     .EqWith = %Core.EqWith
// CHECK:STDOUT:     .Destroy = %Core.Destroy
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Cpp: <namespace> = namespace file.%Cpp.import_cpp, [concrete] {
// CHECK:STDOUT:     .Exception = constants.%Cpp.Exception
// CHECK:STDOUT:     .f = %f.cpp_overload_set.value
// CHECK:STDOUT:     .g = %g.cpp_overload_set.value
// CHECK:STDOUT:     import Cpp//...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Result: %Result.type = import_ref Core//prelude/types/result, Result, loaded [concrete = constants.%Result.generic]
// CHECK:STDOUT:   %Core.import_ref.597: @Result.%Result.Ok.type (%Result.Ok.type.898) = import_ref Core//prelude/types/result, loc{{\d+_\d+}}, loaded [symbolic = @Result.%Result.Ok (constants.%Result.Ok.58a)]
// CHECK:STDOUT:   %Core.import_ref.bfc4: @Result.%Result.Err.type (%Result.Err.type.b75) = import_ref Core//prelude/types/result, loc{{\d+_\d+}}, loaded [symbolic = @Result.%Result.Err (constants.%Result.Err.08c)]
// CHECK:STDOUT:   %Core.Int: %Int.type = import_ref Core//prelude/types/int, Int, loaded [concrete = constants.%Int.generic]
// CHECK:STDOUT:   %Core.CppCompat: <namespace> = import_ref Core//prelude, CppCompat, loaded
// CHECK:STDOUT:   %CppCompat.f0dbf9.1: <namespace> = namespace %Core.CppCompat, [concrete] {
// CHECK:STDOUT:     .Exception = %Core.Exception
// CHECK:STDOUT:     .VoidBase = %Core.VoidBase
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Exception: type = import_ref Core//prelude/types/cpp/exception, Exception, loaded [concrete = constants.%Cpp.Exception]
// CHECK:STDOUT:   %f.cpp_overload_set.value: %f.cpp_overload_set.type = cpp_overload_set_value @f.cpp_overload_set [concrete = constants.%f.cpp_overload_set.value]
// CHECK:STDOUT:   %g.cpp_overload_set.value: %g.cpp_overload_set.type = cpp_overload_set_value @g.cpp_overload_set [concrete = constants.%g.cpp_overload_set.value]
// CHECK:STDOUT:   %g__carbon_thunk.decl: %g__carbon_thunk.type = fn_decl @g__carbon_thunk [concrete = constants.%g__carbon_thunk] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Try: type = import_ref Core//prelude/try, Try, loaded [concrete = constants.%Try.type]
// CHECK:STDOUT:   %Core.VoidBase: type = import_ref Core//prelude/types/cpp/void, VoidBase, loaded [concrete = constants.%Cpp.void]
// CHECK:STDOUT:   %f__carbon_catching_thunk.decl: %f__carbon_catching_thunk.type = fn_decl @f__carbon_catching_thunk [concrete = constants.%f__carbon_catching_thunk] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.ImplicitAs: %ImplicitAs.type.0ff = import_ref Core//prelude/operators/as, ImplicitAs, loaded [concrete = constants.%ImplicitAs.generic]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.EqWith: %EqWith.type.f77 = import_ref Core//prelude/operators/comparison, EqWith, loaded [concrete = constants.%EqWith.generic]
// CHECK:STDOUT:   %Core.import_ref.074: @Int.as.EqWith.impl.e9c.%Int.as.EqWith.impl.Equal.type (%Int.as.EqWith.impl.Equal.type.9a2) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.EqWith.impl.e9c.%Int.as.EqWith.impl.Equal (constants.%Int.as.EqWith.impl.Equal.792)]
// CHECK:STDOUT:   %Core.import_ref.449 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.09e = impl_witness_table (%Core.import_ref.074, %Core.import_ref.449), @Int.as.EqWith.impl.e9c [concrete]
// CHECK:STDOUT:   %Core.import_ref.0b3 = import_ref Core//prelude/types/result, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.6e9 = import_ref Core//prelude/types/result, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9f4: @Result.as.Try.impl.%Result.as.Try.impl.Branch.type (%Result.as.Try.impl.Branch.type.d6a) = import_ref Core//prelude/types/result, loc{{\d+_\d+}}, loaded [symbolic = @Result.as.Try.impl.%Result.as.Try.impl.Branch (constants.%Result.as.Try.impl.Branch.513)]
// CHECK:STDOUT:   %Core.import_ref.6a4: @Result.as.Try.impl.%Result.as.Try.impl.FromBreak.type (%Result.as.Try.impl.FromBreak.type.834) = import_ref Core//prelude/types/result, loc{{\d+_\d+}}, loaded [symbolic = @Result.as.Try.impl.%Result.as.Try.impl.FromBreak (constants.%Result.as.Try.impl.FromBreak.9cc)]
// CHECK:STDOUT:   %Try.impl_witness_table = impl_witness_table (%Core.import_ref.0b3, %Core.import_ref.6e9, %Core.import_ref.9f4, %Core.import_ref.6a4), @Result.as.Try.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.aa5: @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.170)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.f01 = impl_witness_table (%Core.import_ref.aa5), @Core.IntLiteral.as.ImplicitAs.impl.b68 [concrete]
// CHECK:STDOUT:   %Core.import_ref.b92: @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal.type (%UInt.as.EqWith.impl.Equal.type.544) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal (constants.%UInt.as.EqWith.impl.Equal.c67)]
// CHECK:STDOUT:   %Core.import_ref.b44 = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.166 = impl_witness_table (%Core.import_ref.b92, %Core.import_ref.b44), @UInt.as.EqWith.impl.f13 [concrete]
// CHECK:STDOUT:   %Core.Destroy: type = import_ref Core//prelude/destroy, Destroy, loaded [concrete = constants.%Destroy.type]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %H.decl: %H.type = fn_decl @H [concrete = constants.%H] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.5d9 = out_param_pattern [concrete = constants.%return.param_patt.8a0]
// CHECK:STDOUT:     %return.patt: %pattern_type.5d9 = return_slot_pattern %return.param_patt, %Result.loc15 [concrete = constants.%return.patt.dd6]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %Core.ref.loc15: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:     %Result.ref.loc15: %Result.type = name_ref Result, imports.%Core.Result [concrete = constants.%Result.generic]
// CHECK:STDOUT:     %i32.loc15: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %Cpp.ref.loc15: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:     %Exception.ref.loc15: type = name_ref Exception, constants.%Cpp.Exception [concrete = constants.%Cpp.Exception]
// CHECK:STDOUT:     %Result.loc15: type = class_type @Result, @Result(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.900]
// CHECK:STDOUT:     %.loc15_41.3: Core.Form = init_form %Result.loc15 [concrete = constants.%.c19]
// CHECK:STDOUT:     %return.param: ref %Result.900 = out_param call_param0
// CHECK:STDOUT:     %return: ref %Result.900 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @H() -> out %return.param: %Result.900 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Core.ref.loc16: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:   %Result.ref.loc16: %Result.type = name_ref Result, imports.%Core.Result [concrete = constants.%Result.generic]
// CHECK:STDOUT:   %i32.loc16: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %Cpp.ref.loc16_27: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:   %Exception.ref.loc16: type = name_ref Exception, constants.%Cpp.Exception [concrete = constants.%Cpp.Exception]
// CHECK:STDOUT:   %Result.loc16_40: type = class_type @Result, @Result(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.900]
// CHECK:STDOUT:   %.loc16_41: %Result.Ok.type.977 = specific_constant imports.%Core.import_ref.597, @Result(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.Ok.789]
// CHECK:STDOUT:   %Ok.ref.loc16_41: %Result.Ok.type.977 = name_ref Ok, %.loc16_41 [concrete = constants.%Result.Ok.789]
// CHECK:STDOUT:   %Cpp.ref.loc16_45: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:   %f.ref: %f.cpp_overload_set.type = name_ref f, imports.%f.cpp_overload_set.value [concrete = constants.%f.cpp_overload_set.value]
// CHECK:STDOUT:   %Cpp.ref.loc16_51: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:   %g.ref: %g.cpp_overload_set.type = name_ref g, imports.%g.cpp_overload_set.value [concrete = constants.%g.cpp_overload_set.value]
// CHECK:STDOUT:   %g__carbon_thunk.call: init %i32 = call imports.%g__carbon_thunk.decl()
// CHECK:STDOUT:   %.loc16_57.1: %i32 = value_of_initializer %g__carbon_thunk.call
// CHECK:STDOUT:   %.loc16_57.2: %i32 = converted %g__carbon_thunk.call, %.loc16_57.1
// CHECK:STDOUT:   %Result.loc16_58: type = class_type @Result, @Result(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.900]
// CHECK:STDOUT:   %.loc16_58.1: ref %i32 = temporary_storage
// CHECK:STDOUT:   %addr.loc16_58.1: %ptr.d08 = addr_of %.loc16_58.1
// CHECK:STDOUT:   %.loc16_58.2: ref %ptr.00a = temporary_storage
// CHECK:STDOUT:   %addr.loc16_58.2: %ptr.6f9 = addr_of %.loc16_58.2
// CHECK:STDOUT:   %f__carbon_catching_thunk.call: init %i32 = call imports.%f__carbon_catching_thunk.decl(%.loc16_57.2, %addr.loc16_58.1, %addr.loc16_58.2)
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc16_58.1: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc16_58.1: <bound method> = bound_method %int_0, %impl.elem0.loc16_58.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc16_58.1: <specific function> = specific_function %impl.elem0.loc16_58.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc16_58.2: <bound method> = bound_method %int_0, %specific_fn.loc16_58.1 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16_58: init %i32 = call %bound_method.loc16_58.2(%int_0) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc16_58.3: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16_58 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc16_58.4: %i32 = converted %int_0, %.loc16_58.3 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %impl.elem0.loc16_58.2: %.a79 = impl_witness_access constants.%EqWith.impl_witness.34c, element0 [concrete = constants.%Int.as.EqWith.impl.Equal.34f]
// CHECK:STDOUT:   %bound_method.loc16_58.3: <bound method> = bound_method %f__carbon_catching_thunk.call, %impl.elem0.loc16_58.2
// CHECK:STDOUT:   %specific_fn.loc16_58.2: <specific function> = specific_function %impl.elem0.loc16_58.2, @Int.as.EqWith.impl.Equal.1(constants.%int_32, constants.%int_32) [concrete = constants.%Int.as.EqWith.impl.Equal.specific_fn.12d]
// CHECK:STDOUT:   %bound_method.loc16_58.4: <bound method> = bound_method %f__carbon_catching_thunk.call, %specific_fn.loc16_58.2
// CHECK:STDOUT:   %.loc16_58.5: %i32 = value_of_initializer %f__carbon_catching_thunk.call
// CHECK:STDOUT:   %.loc16_58.6: %i32 = converted %f__carbon_catching_thunk.call, %.loc16_58.5
// CHECK:STDOUT:   %Int.as.EqWith.impl.Equal.call: init bool = call %bound_method.loc16_58.4(%.loc16_58.6, %.loc16_58.4)
// CHECK:STDOUT:   %.loc16_58.7: bool = value_of_initializer %Int.as.EqWith.impl.Equal.call
// CHECK:STDOUT:   %.loc16_58.8: bool = converted %Int.as.EqWith.impl.Equal.call, %.loc16_58.7
// CHECK:STDOUT:   %.loc16_58.9: ref %Result.900 = temporary_storage
// CHECK:STDOUT:   if %.loc16_58.8 br !.loc16_58.1 else br !.loc16_58.2
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc16_58.1:
// CHECK:STDOUT:   %.loc16_58.10: %i32 = acquire_value %.loc16_58.1
// CHECK:STDOUT:   %.loc16_58.11: %Result.Ok.type.977 = specific_constant imports.%Core.import_ref.597, @Result(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.Ok.789]
// CHECK:STDOUT:   %Ok.ref.loc16_58: %Result.Ok.type.977 = name_ref Ok, %.loc16_58.11 [concrete = constants.%Result.Ok.789]
// CHECK:STDOUT:   %Result.Ok.specific_fn.loc16_58: <specific function> = specific_function %Ok.ref.loc16_58, @Result.Ok(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.Ok.specific_fn]
// CHECK:STDOUT:   %.loc16_58.12: ref %Result.900 = splice_block %.loc16_58.9 {}
// CHECK:STDOUT:   %Result.Ok.call.loc16_58: init %Result.900 to %.loc16_58.12 = call %Result.Ok.specific_fn.loc16_58(%.loc16_58.10)
// CHECK:STDOUT:   assign %.loc16_58.9, %Result.Ok.call.loc16_58
// CHECK:STDOUT:   br !.loc16_58.3
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc16_58.2:
// CHECK:STDOUT:   %.loc16_58.13: %ptr.00a = acquire_value %.loc16_58.2
// CHECK:STDOUT:   %.loc16_58.14: %Cpp.Exception = as_compatible %.loc16_58.13
// CHECK:STDOUT:   %.loc16_58.15: %Cpp.Exception = converted %.loc16_58.13, %.loc16_58.14
// CHECK:STDOUT:   %.loc16_58.16: %Result.Err.type.a4b = specific_constant imports.%Core.import_ref.bfc4, @Result(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.Err.7cb]
// CHECK:STDOUT:   %Err.ref: %Result.Err.type.a4b = name_ref Err, %.loc16_58.16 [concrete = constants.%Result.Err.7cb]
// CHECK:STDOUT:   %Result.Err.specific_fn: <specific function> = specific_function %Err.ref, @Result.Err(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.Err.specific_fn.031]
// CHECK:STDOUT:   %.loc16_58.17: ref %Result.900 = splice_block %.loc16_58.9 {}
// CHECK:STDOUT:   %Result.Err.call: init %Result.900 to %.loc16_58.17 = call %Result.Err.specific_fn(%.loc16_58.15)
// CHECK:STDOUT:   assign %.loc16_58.9, %Result.Err.call
// CHECK:STDOUT:   br !.loc16_58.3
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc16_58.3:
// CHECK:STDOUT:   %.loc16_58.18: %Result.900 = acquire_value %.loc16_58.9
// CHECK:STDOUT:   %impl.elem2: %.8bc = impl_witness_access constants.%Try.impl_witness.d5a, element2 [concrete = constants.%Result.as.Try.impl.Branch.1b9]
// CHECK:STDOUT:   %bound_method.loc16_59.1: <bound method> = bound_method %.loc16_58.18, %impl.elem2
// CHECK:STDOUT:   %specific_fn.loc16_59.1: <specific function> = specific_function %impl.elem2, @Result.as.Try.impl.Branch(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.as.Try.impl.Branch.specific_fn.2e1]
// CHECK:STDOUT:   %bound_method.loc16_59.2: <bound method> = bound_method %.loc16_58.18, %specific_fn.loc16_59.1
// CHECK:STDOUT:   %.loc16_59.1: ref %ControlFlow.bd1 = temporary_storage
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.call: init %ControlFlow.bd1 to %.loc16_59.1 = call %bound_method.loc16_59.2(%.loc16_58.18)
// CHECK:STDOUT:   %.loc16_59.2: ref %ControlFlow.bd1 = temporary %.loc16_59.1, %Result.as.Try.impl.Branch.call
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc16_59.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc16_59.3: <bound method> = bound_method %int_1, %impl.elem0.loc16_59.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc16_59.2: <specific function> = specific_function %impl.elem0.loc16_59.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc16_59.4: <bound method> = bound_method %int_1, %specific_fn.loc16_59.2 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16_59: init %u1 = call %bound_method.loc16_59.4(%int_1) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc16_59.3: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16_59 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc16_59.4: %u1 = converted %int_1, %.loc16_59.3 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc16_59.5: ref %u1 = class_element_access %.loc16_59.2, element0
// CHECK:STDOUT:   %impl.elem0.loc16_59.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc16_59.5: <bound method> = bound_method %.loc16_59.4, %impl.elem0.loc16_59.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound]
// CHECK:STDOUT:   %specific_fn.loc16_59.3: <specific function> = specific_function %impl.elem0.loc16_59.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc16_59.6: <bound method> = bound_method %.loc16_59.4, %specific_fn.loc16_59.3 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc16_59.6: %u1 = acquire_value %.loc16_59.5
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call: init bool = call %bound_method.loc16_59.6(%.loc16_59.4, %.loc16_59.6)
// CHECK:STDOUT:   %.loc16_59.7: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call
// CHECK:STDOUT:   %.loc16_59.8: bool = converted %UInt.as.EqWith.impl.Equal.call, %.loc16_59.7
// CHECK:STDOUT:   if %.loc16_59.8 br !.loc16_59.1 else br !.loc16_59.2
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc16_59.1:
// CHECK:STDOUT:   %.loc16_59.9: ref %.337 = class_element_access %.loc16_59.2, element1
// CHECK:STDOUT:   %.loc16_59.10: ref %tuple.type.b42 = class_element_access %.loc16_59.9, element1
// CHECK:STDOUT:   %tuple.elem0.loc16_59.1: ref %Cpp.Exception = tuple_access %.loc16_59.10, element0
// CHECK:STDOUT:   %.loc16_59.11: %Cpp.Exception = acquire_value %tuple.elem0.loc16_59.1
// CHECK:STDOUT:   %Try.facet: %Try.type = facet_value constants.%Result.900, (constants.%Try.impl_witness.d5a) [concrete = constants.%Try.facet.51d]
// CHECK:STDOUT:   %.loc16_59.12: %Try.type = converted constants.%Result.900, %Try.facet [concrete = constants.%Try.facet.51d]
// CHECK:STDOUT:   %impl.elem3: %.cfb = impl_witness_access constants.%Try.impl_witness.d5a, element3 [concrete = constants.%Result.as.Try.impl.FromBreak.c94]
// CHECK:STDOUT:   %specific_fn.loc16_59.4: <specific function> = specific_function %impl.elem3, @Result.as.Try.impl.FromBreak(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.as.Try.impl.FromBreak.specific_fn]
// CHECK:STDOUT:   %.loc15_41.1: ref %Result.900 = splice_block %return.param {}
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.call: init %Result.900 to %.loc15_41.1 = call %specific_fn.loc16_59.4(%.loc16_59.11)
// CHECK:STDOUT:   %Destroy.Op.bound.loc16_59.1: <bound method> = bound_method %.loc16_59.2, constants.%Destroy.Op.1a2547.11
// CHECK:STDOUT:   %Destroy.Op.call.loc16_59.1: init %empty_tuple.type = call %Destroy.Op.bound.loc16_59.1(%.loc16_59.2)
// CHECK:STDOUT:   return %Result.as.Try.impl.FromBreak.call to %return.param
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc16_59.2:
// CHECK:STDOUT:   %.loc16_59.13: ref %.337 = class_element_access %.loc16_59.2, element1
// CHECK:STDOUT:   %.loc16_59.14: ref %tuple.type.a8a = class_element_access %.loc16_59.13, element0
// CHECK:STDOUT:   %tuple.elem0.loc16_59.2: ref %i32 = tuple_access %.loc16_59.14, element0
// CHECK:STDOUT:   %.loc16_59.15: %i32 = acquire_value %tuple.elem0.loc16_59.2
// CHECK:STDOUT:   %Result.Ok.specific_fn.loc16_41: <specific function> = specific_function %Ok.ref.loc16_41, @Result.Ok(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.Ok.specific_fn]
// CHECK:STDOUT:   %.loc15_41.2: ref %Result.900 = splice_block %return.param {}
// CHECK:STDOUT:   %Result.Ok.call.loc16_60: init %Result.900 to %.loc15_41.2 = call %Result.Ok.specific_fn.loc16_41(%.loc16_59.15)
// CHECK:STDOUT:   %Destroy.Op.bound.loc16_59.2: <bound method> = bound_method %.loc16_59.2, constants.%Destroy.Op.1a2547.11
// CHECK:STDOUT:   %Destroy.Op.call.loc16_59.2: init %empty_tuple.type = call %Destroy.Op.bound.loc16_59.2(%.loc16_59.2)
// CHECK:STDOUT:   return %Result.Ok.call.loc16_60 to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc16_59.1(%self.param: ref %u1.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc16_59.2(%self.param: ref %u1) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc16_59.3(%self.param: ref %i32.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc16_59.4(%self.param: ref %i32) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc16_59.5(%self.param: ref %tuple.type.a8a) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc16_59.6(%self.param: ref %ptr.00a) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc16_59.7(%self.param: ref %Cpp.Exception) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc16_59.8(%self.param: ref %tuple.type.b42) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc16_59.9(%self.param: ref %.337) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc16_59.10(%self.param: ref %struct_type.discriminant.payload.b51) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc16_59.11(%self.param: ref %ControlFlow.bd1) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- same_callee_both_ways.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %Result.type: type = generic_class_type @Result [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %Result.generic: %Result.type = struct_value () [concrete]
// CHECK:STDOUT:   %E: type = symbolic_binding E, 1 [symbolic]
// CHECK:STDOUT:   %T.67d: type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %u1: type = class_type @UInt, @UInt(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %u1.builtin: type = int_type unsigned, %int_1.5b8 [concrete]
// CHECK:STDOUT:   %Result.Err.type.b75: type = fn_type @Result.Err, @Result(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %Result.Err.08c: %Result.Err.type.b75 = struct_value () [symbolic]
// CHECK:STDOUT:   %Result.Ok.type.898: type = fn_type @Result.Ok, @Result(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %Result.Ok.58a: %Result.Ok.type.898 = struct_value () [symbolic]
// CHECK:STDOUT:   %int_1.233: %u1 = int_value 1 [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %Int.type: type = generic_class_type @Int [concrete]
// CHECK:STDOUT:   %Int.generic: %Int.type = struct_value () [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %Cpp.Exception: type = class_type @Exception [concrete]
// CHECK:STDOUT:   %Cpp.void: type = class_type @VoidBase [concrete]
// CHECK:STDOUT:   %ptr.00a: type = ptr_type %Cpp.void [concrete]
// CHECK:STDOUT:   %Result.900: type = class_type @Result, @Result(%i32, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %.c19: Core.Form = init_form %Result.900 [concrete]
// CHECK:STDOUT:   %pattern_type.5d9: type = pattern_type %Result.900 [concrete]
// CHECK:STDOUT:   %return.param_patt.8a0: %pattern_type.5d9 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.dd6: %pattern_type.5d9 = return_slot_pattern %return.param_patt.8a0, %Result.900 [concrete]
// CHECK:STDOUT:   %Both.type: type = fn_type @Both [concrete]
// CHECK:STDOUT:   %Both: %Both.type = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %i32.builtin: type = int_type signed, %int_32 [concrete]
// CHECK:STDOUT:   %tuple.type.a8a: type = tuple_type (%i32) [concrete]
// CHECK:STDOUT:   %tuple.type.b42: type = tuple_type (%Cpp.Exception) [concrete]
// CHECK:STDOUT:   %Result.Ok.type.977: type = fn_type @Result.Ok, @Result(%i32, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %Result.Ok.789: %Result.Ok.type.977 = struct_value () [concrete]
// CHECK:STDOUT:   %Result.Err.type.a4b: type = fn_type @Result.Err, @Result(%i32, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %Result.Err.7cb: %Result.Err.type.a4b = struct_value () [concrete]
// CHECK:STDOUT:   %plain.patt: %pattern_type.6b6 = ref_binding_pattern plain [concrete]
// CHECK:STDOUT:   %plain.var_patt: %pattern_type.6b6 = var_pattern %plain.patt [concrete]
// CHECK:STDOUT:   %may_throw_int.cpp_overload_set.type: type = cpp_overload_set_type @may_throw_int.cpp_overload_set [concrete]
// CHECK:STDOUT:   %may_throw_int.cpp_overload_set.value: %may_throw_int.cpp_overload_set.type = cpp_overload_set_value @may_throw_int.cpp_overload_set [concrete]
// CHECK:STDOUT:   %may_throw_int__carbon_thunk.type: type = fn_type @may_throw_int__carbon_thunk [concrete]
// CHECK:STDOUT:   %may_throw_int__carbon_thunk: %may_throw_int__carbon_thunk.type = struct_value () [concrete]
// CHECK:STDOUT:   %caught.patt: %pattern_type.6b6 = ref_binding_pattern caught [concrete]
// CHECK:STDOUT:   %caught.var_patt: %pattern_type.6b6 = var_pattern %caught.patt [concrete]
// CHECK:STDOUT:   %Try.type: type = facet_type <@Try> [concrete]
// CHECK:STDOUT:   %ptr.d08: type = ptr_type %i32 [concrete]
// CHECK:STDOUT:   %ptr.6f9: type = ptr_type %ptr.00a [concrete]
// CHECK:STDOUT:   %may_throw_int__carbon_catching_thunk.type: type = fn_type @may_throw_int__carbon_catching_thunk [concrete]
// CHECK:STDOUT:   %may_throw_int__carbon_catching_thunk: %may_throw_int__carbon_catching_thunk.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.0ff: type = generic_interface_type @ImplicitAs [concrete]
// CHECK:STDOUT:   %ImplicitAs.generic: %ImplicitAs.type.0ff = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %To.fe9: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.48f: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet.48f [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.6e0: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_0.3c0: %i32 = int_value 0 [concrete]
// CHECK:STDOUT:   %EqWith.type.f77: type = generic_interface_type @EqWith [concrete]
// CHECK:STDOUT:   %EqWith.generic: %EqWith.type.f77 = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.type.8ee: type = facet_type <@EqWith, @EqWith(%i32)> [concrete]
// CHECK:STDOUT:   %M: Core.IntLiteral = symbolic_binding M, 1 [symbolic]
// CHECK:STDOUT:   %Int.as.EqWith.impl.Equal.type.9a2: type = fn_type @Int.as.EqWith.impl.Equal.1, @Int.as.EqWith.impl.e9c(%N, %M) [symbolic]
// CHECK:STDOUT:   %Int.as.EqWith.impl.Equal.792: %Int.as.EqWith.impl.Equal.type.9a2 = struct_value () [symbolic]
// CHECK:STDOUT:   %EqWith.impl_witness.34c: <witness> = impl_witness imports.%EqWith.impl_witness_table.09e, @Int.as.EqWith.impl.e9c(%int_32, %int_32) [concrete]
// CHECK:STDOUT:   %Int.as.EqWith.impl.Equal.type.01c: type = fn_type @Int.as.EqWith.impl.Equal.1, @Int.as.EqWith.impl.e9c(%int_32, %int_32) [concrete]
// CHECK:STDOUT:   %Int.as.EqWith.impl.Equal.34f: %Int.as.EqWith.impl.Equal.type.01c = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.508: %EqWith.type.8ee = facet_value %i32, (%EqWith.impl_witness.34c) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.530: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%i32, %EqWith.facet.508) [concrete]
// CHECK:STDOUT:   %.a79: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.530, %EqWith.facet.508 [concrete]
// CHECK:STDOUT:   %Int.as.EqWith.impl.Equal.specific_fn.12d: <specific function> = specific_function %Int.as.EqWith.impl.Equal.34f, @Int.as.EqWith.impl.Equal.1(%int_32, %int_32) [concrete]
// CHECK:STDOUT:   %Result.Ok.specific_fn: <specific function> = specific_function %Result.Ok.789, @Result.Ok(%i32, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %Result.Err.specific_fn.031: <specific function> = specific_function %Result.Err.7cb, @Result.Err(%i32, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.type.834: type = fn_type @Result.as.Try.impl.FromBreak, @Result.as.Try.impl(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.9cc: %Result.as.Try.impl.FromBreak.type.834 = struct_value () [symbolic]
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.type.d6a: type = fn_type @Result.as.Try.impl.Branch, @Result.as.Try.impl(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.513: %Result.as.Try.impl.Branch.type.d6a = struct_value () [symbolic]
// CHECK:STDOUT:   %Try.impl_witness.d5a: <witness> = impl_witness imports.%Try.impl_witness_table, @Result.as.Try.impl(%i32, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.type.521: type = fn_type @Result.as.Try.impl.Branch, @Result.as.Try.impl(%i32, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.1b9: %Result.as.Try.impl.Branch.type.521 = struct_value () [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.type.b43: type = fn_type @Result.as.Try.impl.FromBreak, @Result.as.Try.impl(%i32, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.c94: %Result.as.Try.impl.FromBreak.type.b43 = struct_value () [concrete]
// CHECK:STDOUT:   %Try.facet.51d: %Try.type = facet_value %Result.900, (%Try.impl_witness.d5a) [concrete]
// CHECK:STDOUT:   %Try.WithSelf.Branch.type.353: type = fn_type @Try.WithSelf.Branch, @Try.WithSelf(%Try.facet.51d) [concrete]
// CHECK:STDOUT:   %Try.WithSelf.FromBreak.type.cf1: type = fn_type @Try.WithSelf.FromBreak, @Try.WithSelf(%Try.facet.51d) [concrete]
// CHECK:STDOUT:   %.8bc: type = fn_type_with_self_type %Try.WithSelf.Branch.type.353, %Try.facet.51d [concrete]
// CHECK:STDOUT:   %ControlFlow.bd1: type = class_type @ControlFlow, @ControlFlow(%i32, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.specific_fn.2e1: <specific function> = specific_function %Result.as.Try.impl.Branch.1b9, @Result.as.Try.impl.Branch(%i32, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %.337: type = custom_layout_type {size=8, align=8, .Continue@0: %tuple.type.a8a, .Break@0: %tuple.type.b42} [concrete]
// CHECK:STDOUT:   %struct_type.discriminant.payload.b51: type = struct_type {.discriminant: %u1, .payload: %.337} [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.ca1: type = facet_type <@ImplicitAs, @ImplicitAs(%u1)> [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.b68(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.170: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.f4c: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.f01, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.46b: %ImplicitAs.type.ca1 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.f4c) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.77c: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%u1, %ImplicitAs.facet.46b) [concrete]
// CHECK:STDOUT:   %.e74: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.77c, %ImplicitAs.facet.46b [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.d7a: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
// CHECK:STDOUT:   %EqWith.type.c25: type = facet_type <@EqWith, @EqWith(%u1)> [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.544: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%N, %M) [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.c67: %UInt.as.EqWith.impl.Equal.type.544 = struct_value () [symbolic]
// CHECK:STDOUT:   %EqWith.impl_witness.7b3: <witness> = impl_witness imports.%EqWith.impl_witness_table.166, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.29b: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.ba4: %UInt.as.EqWith.impl.Equal.type.29b = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.4d0: %EqWith.type.c25 = facet_value %u1, (%EqWith.impl_witness.7b3) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.e3c: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%u1, %EqWith.facet.4d0) [concrete]
// CHECK:STDOUT:   %.9eb: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.e3c, %EqWith.facet.4d0 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.specific_fn.6b6: <specific function> = specific_function %UInt.as.EqWith.impl.Equal.ba4, @UInt.as.EqWith.impl.Equal.1(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.a82: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
// CHECK:STDOUT:   %.cfb: type = fn_type_with_self_type %Try.WithSelf.FromBreak.type.cf1, %Try.facet.51d [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.specific_fn: <specific function> = specific_function %Result.as.Try.impl.FromBreak.c94, @Result.as.Try.impl.FromBreak(%i32, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %Destroy.type: type = facet_type <@Destroy> [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.4: type = fn_type @Destroy.Op.loc16_40.4 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.4: %Destroy.Op.type.1d8f74.4 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.11: type = fn_type @Destroy.Op.loc16_40.11 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.11: %Destroy.Op.type.1d8f74.11 = struct_value () [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet: %Copy.type = facet_value %i32, (%Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.381: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet) [concrete]
// CHECK:STDOUT:   %.737: type = fn_type_with_self_type %Copy.WithSelf.Op.type.381, %Copy.facet [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %AddWith.type.2ef: type = generic_interface_type @AddWith [concrete]
// CHECK:STDOUT:   %AddWith.generic: %AddWith.type.2ef = struct_value () [concrete]
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
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .Result = %Core.Result.0b3
// CHECK:STDOUT:     .Int = %Core.Int
// CHECK:STDOUT:     .CppCompat = %CppCompat.f0dbf9.1
// CHECK:STDOUT:     .Try = %Core.Try
// CHECK:STDOUT:     .ImplicitAs = %Core.ImplicitAs
// CHECK:STDOUT:     .EqWith = %Core.EqWith
// CHECK:STDOUT:     .Destroy = %Core.Destroy
// CHECK:STDOUT:     .Copy = %Core.Copy
// CHECK:STDOUT:     .AddWith = %Core.AddWith
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Cpp: <namespace> = namespace file.%Cpp.import_cpp, [concrete] {
// CHECK:STDOUT:     .Exception = constants.%Cpp.Exception
// CHECK:STDOUT:     .may_throw_int = %may_throw_int.cpp_overload_set.value
// CHECK:STDOUT:     import Cpp//...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Result.0b3: %Result.type = import_ref Core//prelude/types/result, Result, loaded [concrete = constants.%Result.generic]
// CHECK:STDOUT:   %Core.import_ref.597: @Result.%Result.Ok.type (%Result.Ok.type.898) = import_ref Core//prelude/types/result, loc{{\d+_\d+}}, loaded [symbolic = @Result.%Result.Ok (constants.%Result.Ok.58a)]
// CHECK:STDOUT:   %Core.import_ref.bfc4: @Result.%Result.Err.type (%Result.Err.type.b75) = import_ref Core//prelude/types/result, loc{{\d+_\d+}}, loaded [symbolic = @Result.%Result.Err (constants.%Result.Err.08c)]
// CHECK:STDOUT:   %Core.Int: %Int.type = import_ref Core//prelude/types/int, Int, loaded [concrete = constants.%Int.generic]
// CHECK:STDOUT:   %Core.CppCompat: <namespace> = import_ref Core//prelude, CppCompat, loaded
// CHECK:STDOUT:   %CppCompat.f0dbf9.1: <namespace> = namespace %Core.CppCompat, [concrete] {
// CHECK:STDOUT:     .Exception = %Core.Exception
// CHECK:STDOUT:     .VoidBase = %Core.VoidBase
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Exception: type = import_ref Core//prelude/types/cpp/exception, Exception, loaded [concrete = constants.%Cpp.Exception]
// CHECK:STDOUT:   %may_throw_int.cpp_overload_set.value: %may_throw_int.cpp_overload_set.type = cpp_overload_set_value @may_throw_int.cpp_overload_set [concrete = constants.%may_throw_int.cpp_overload_set.value]
// CHECK:STDOUT:   %may_throw_int__carbon_thunk.decl: %may_throw_int__carbon_thunk.type = fn_decl @may_throw_int__carbon_thunk [concrete = constants.%may_throw_int__carbon_thunk] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Try: type = import_ref Core//prelude/try, Try, loaded [concrete = constants.%Try.type]
// CHECK:STDOUT:   %Core.VoidBase: type = import_ref Core//prelude/types/cpp/void, VoidBase, loaded [concrete = constants.%Cpp.void]
// CHECK:STDOUT:   %may_throw_int__carbon_catching_thunk.decl: %may_throw_int__carbon_catching_thunk.type = fn_decl @may_throw_int__carbon_catching_thunk [concrete = constants.%may_throw_int__carbon_catching_thunk] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.ImplicitAs: %ImplicitAs.type.0ff = import_ref Core//prelude/operators/as, ImplicitAs, loaded [concrete = constants.%ImplicitAs.generic]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.EqWith: %EqWith.type.f77 = import_ref Core//prelude/operators/comparison, EqWith, loaded [concrete = constants.%EqWith.generic]
// CHECK:STDOUT:   %Core.import_ref.074: @Int.as.EqWith.impl.e9c.%Int.as.EqWith.impl.Equal.type (%Int.as.EqWith.impl.Equal.type.9a2) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.EqWith.impl.e9c.%Int.as.EqWith.impl.Equal (constants.%Int.as.EqWith.impl.Equal.792)]
// CHECK:STDOUT:   %Core.import_ref.449 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.09e = impl_witness_table (%Core.import_ref.074, %Core.import_ref.449), @Int.as.EqWith.impl.e9c [concrete]
// CHECK:STDOUT:   %Core.import_ref.0b3 = import_ref Core//prelude/types/result, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.6e9 = import_ref Core//prelude/types/result, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9f4: @Result.as.Try.impl.%Result.as.Try.impl.Branch.type (%Result.as.Try.impl.Branch.type.d6a) = import_ref Core//prelude/types/result, loc{{\d+_\d+}}, loaded [symbolic = @Result.as.Try.impl.%Result.as.Try.impl.Branch (constants.%Result.as.Try.impl.Branch.513)]
// CHECK:STDOUT:   %Core.import_ref.6a4: @Result.as.Try.impl.%Result.as.Try.impl.FromBreak.type (%Result.as.Try.impl.FromBreak.type.834) = import_ref Core//prelude/types/result, loc{{\d+_\d+}}, loaded [symbolic = @Result.as.Try.impl.%Result.as.Try.impl.FromBreak (constants.%Result.as.Try.impl.FromBreak.9cc)]
// CHECK:STDOUT:   %Try.impl_witness_table = impl_witness_table (%Core.import_ref.0b3, %Core.import_ref.6e9, %Core.import_ref.9f4, %Core.import_ref.6a4), @Result.as.Try.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.aa5: @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.170)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.f01 = impl_witness_table (%Core.import_ref.aa5), @Core.IntLiteral.as.ImplicitAs.impl.b68 [concrete]
// CHECK:STDOUT:   %Core.import_ref.b92: @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal.type (%UInt.as.EqWith.impl.Equal.type.544) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal (constants.%UInt.as.EqWith.impl.Equal.c67)]
// CHECK:STDOUT:   %Core.import_ref.b44 = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.166 = impl_witness_table (%Core.import_ref.b92, %Core.import_ref.b44), @UInt.as.EqWith.impl.f13 [concrete]
// CHECK:STDOUT:   %Core.Destroy: type = import_ref Core//prelude/destroy, Destroy, loaded [concrete = constants.%Destroy.type]
// CHECK:STDOUT:   %Core.Copy: type = import_ref Core//prelude/copy, Copy, loaded [concrete = constants.%Copy.type]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.AddWith: %AddWith.type.2ef = import_ref Core//prelude/operators/arithmetic, AddWith, loaded [concrete = constants.%AddWith.generic]
// CHECK:STDOUT:   %Core.import_ref.b4fd3a.1 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.684: @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op.type (%Int.as.AddWith.impl.Op.type.610) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op (constants.%Int.as.AddWith.impl.Op.732)]
// CHECK:STDOUT:   %AddWith.impl_witness_table.6b4 = impl_witness_table (%Core.import_ref.b4fd3a.1, %Core.import_ref.684), @Int.as.AddWith.impl.3af [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Both.decl: %Both.type = fn_decl @Both [concrete = constants.%Both] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.5d9 = out_param_pattern [concrete = constants.%return.param_patt.8a0]
// CHECK:STDOUT:     %return.patt: %pattern_type.5d9 = return_slot_pattern %return.param_patt, %Result.loc14 [concrete = constants.%return.patt.dd6]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %Core.ref.loc14: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:     %Result.ref.loc14: %Result.type = name_ref Result, imports.%Core.Result.0b3 [concrete = constants.%Result.generic]
// CHECK:STDOUT:     %i32.loc14: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %Cpp.ref.loc14: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:     %Exception.ref.loc14: type = name_ref Exception, constants.%Cpp.Exception [concrete = constants.%Cpp.Exception]
// CHECK:STDOUT:     %Result.loc14: type = class_type @Result, @Result(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.900]
// CHECK:STDOUT:     %.loc14_44.3: Core.Form = init_form %Result.loc14 [concrete = constants.%.c19]
// CHECK:STDOUT:     %return.param: ref %Result.900 = out_param call_param0
// CHECK:STDOUT:     %return: ref %Result.900 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Both() -> out %return.param: %Result.900 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %plain.var: ref %i32 = var_storage %plain.var_patt
// CHECK:STDOUT:   %Cpp.ref.loc15: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:   %may_throw_int.ref.loc15: %may_throw_int.cpp_overload_set.type = name_ref may_throw_int, imports.%may_throw_int.cpp_overload_set.value [concrete = constants.%may_throw_int.cpp_overload_set.value]
// CHECK:STDOUT:   %may_throw_int__carbon_thunk.call: init %i32 = call imports.%may_throw_int__carbon_thunk.decl()
// CHECK:STDOUT:   assign %plain.var, %may_throw_int__carbon_thunk.call
// CHECK:STDOUT:   %i32.loc15: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %plain: ref %i32 = wrapper_binding plain, %plain.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %plain.patt: %pattern_type.6b6 = ref_binding_pattern plain [concrete = constants.%plain.patt]
// CHECK:STDOUT:     %plain.var_patt: %pattern_type.6b6 = var_pattern %plain.patt [concrete = constants.%plain.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %caught.var: ref %i32 = var_storage %caught.var_patt
// CHECK:STDOUT:   %Cpp.ref.loc16: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:   %may_throw_int.ref.loc16: %may_throw_int.cpp_overload_set.type = name_ref may_throw_int, imports.%may_throw_int.cpp_overload_set.value [concrete = constants.%may_throw_int.cpp_overload_set.value]
// CHECK:STDOUT:   %Result.loc16: type = class_type @Result, @Result(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.900]
// CHECK:STDOUT:   %.loc16_39.1: ref %i32 = temporary_storage
// CHECK:STDOUT:   %addr.loc16_39.1: %ptr.d08 = addr_of %.loc16_39.1
// CHECK:STDOUT:   %.loc16_39.2: ref %ptr.00a = temporary_storage
// CHECK:STDOUT:   %addr.loc16_39.2: %ptr.6f9 = addr_of %.loc16_39.2
// CHECK:STDOUT:   %may_throw_int__carbon_catching_thunk.call: init %i32 = call imports.%may_throw_int__carbon_catching_thunk.decl(%addr.loc16_39.1, %addr.loc16_39.2)
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc16_39.1: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc16_39.1: <bound method> = bound_method %int_0, %impl.elem0.loc16_39.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc16_39.1: <specific function> = specific_function %impl.elem0.loc16_39.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc16_39.2: <bound method> = bound_method %int_0, %specific_fn.loc16_39.1 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16_39: init %i32 = call %bound_method.loc16_39.2(%int_0) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc16_39.3: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16_39 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc16_39.4: %i32 = converted %int_0, %.loc16_39.3 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %impl.elem0.loc16_39.2: %.a79 = impl_witness_access constants.%EqWith.impl_witness.34c, element0 [concrete = constants.%Int.as.EqWith.impl.Equal.34f]
// CHECK:STDOUT:   %bound_method.loc16_39.3: <bound method> = bound_method %may_throw_int__carbon_catching_thunk.call, %impl.elem0.loc16_39.2
// CHECK:STDOUT:   %specific_fn.loc16_39.2: <specific function> = specific_function %impl.elem0.loc16_39.2, @Int.as.EqWith.impl.Equal.1(constants.%int_32, constants.%int_32) [concrete = constants.%Int.as.EqWith.impl.Equal.specific_fn.12d]
// CHECK:STDOUT:   %bound_method.loc16_39.4: <bound method> = bound_method %may_throw_int__carbon_catching_thunk.call, %specific_fn.loc16_39.2
// CHECK:STDOUT:   %.loc16_39.5: %i32 = value_of_initializer %may_throw_int__carbon_catching_thunk.call
// CHECK:STDOUT:   %.loc16_39.6: %i32 = converted %may_throw_int__carbon_catching_thunk.call, %.loc16_39.5
// CHECK:STDOUT:   %Int.as.EqWith.impl.Equal.call: init bool = call %bound_method.loc16_39.4(%.loc16_39.6, %.loc16_39.4)
// CHECK:STDOUT:   %.loc16_39.7: bool = value_of_initializer %Int.as.EqWith.impl.Equal.call
// CHECK:STDOUT:   %.loc16_39.8: bool = converted %Int.as.EqWith.impl.Equal.call, %.loc16_39.7
// CHECK:STDOUT:   %.loc16_39.9: ref %Result.900 = temporary_storage
// CHECK:STDOUT:   if %.loc16_39.8 br !.loc16_39.1 else br !.loc16_39.2
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc16_39.1:
// CHECK:STDOUT:   %.loc16_39.10: %i32 = acquire_value %.loc16_39.1
// CHECK:STDOUT:   %.loc16_39.11: %Result.Ok.type.977 = specific_constant imports.%Core.import_ref.597, @Result(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.Ok.789]
// CHECK:STDOUT:   %Ok.ref.loc16: %Result.Ok.type.977 = name_ref Ok, %.loc16_39.11 [concrete = constants.%Result.Ok.789]
// CHECK:STDOUT:   %Result.Ok.specific_fn.loc16: <specific function> = specific_function %Ok.ref.loc16, @Result.Ok(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.Ok.specific_fn]
// CHECK:STDOUT:   %.loc16_39.12: ref %Result.900 = splice_block %.loc16_39.9 {}
// CHECK:STDOUT:   %Result.Ok.call.loc16: init %Result.900 to %.loc16_39.12 = call %Result.Ok.specific_fn.loc16(%.loc16_39.10)
// CHECK:STDOUT:   assign %.loc16_39.9, %Result.Ok.call.loc16
// CHECK:STDOUT:   br !.loc16_39.3
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc16_39.2:
// CHECK:STDOUT:   %.loc16_39.13: %ptr.00a = acquire_value %.loc16_39.2
// CHECK:STDOUT:   %.loc16_39.14: %Cpp.Exception = as_compatible %.loc16_39.13
// CHECK:STDOUT:   %.loc16_39.15: %Cpp.Exception = converted %.loc16_39.13, %.loc16_39.14
// CHECK:STDOUT:   %.loc16_39.16: %Result.Err.type.a4b = specific_constant imports.%Core.import_ref.bfc4, @Result(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.Err.7cb]
// CHECK:STDOUT:   %Err.ref: %Result.Err.type.a4b = name_ref Err, %.loc16_39.16 [concrete = constants.%Result.Err.7cb]
// CHECK:STDOUT:   %Result.Err.specific_fn: <specific function> = specific_function %Err.ref, @Result.Err(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.Err.specific_fn.031]
// CHECK:STDOUT:   %.loc16_39.17: ref %Result.900 = splice_block %.loc16_39.9 {}
// CHECK:STDOUT:   %Result.Err.call: init %Result.900 to %.loc16_39.17 = call %Result.Err.specific_fn(%.loc16_39.15)
// CHECK:STDOUT:   assign %.loc16_39.9, %Result.Err.call
// CHECK:STDOUT:   br !.loc16_39.3
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc16_39.3:
// CHECK:STDOUT:   %.loc16_39.18: %Result.900 = acquire_value %.loc16_39.9
// CHECK:STDOUT:   %impl.elem2: %.8bc = impl_witness_access constants.%Try.impl_witness.d5a, element2 [concrete = constants.%Result.as.Try.impl.Branch.1b9]
// CHECK:STDOUT:   %bound_method.loc16_40.1: <bound method> = bound_method %.loc16_39.18, %impl.elem2
// CHECK:STDOUT:   %specific_fn.loc16_40.1: <specific function> = specific_function %impl.elem2, @Result.as.Try.impl.Branch(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.as.Try.impl.Branch.specific_fn.2e1]
// CHECK:STDOUT:   %bound_method.loc16_40.2: <bound method> = bound_method %.loc16_39.18, %specific_fn.loc16_40.1
// CHECK:STDOUT:   %.loc16_40.1: ref %ControlFlow.bd1 = temporary_storage
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.call: init %ControlFlow.bd1 to %.loc16_40.1 = call %bound_method.loc16_40.2(%.loc16_39.18)
// CHECK:STDOUT:   %.loc16_40.2: ref %ControlFlow.bd1 = temporary %.loc16_40.1, %Result.as.Try.impl.Branch.call
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc16_40.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc16_40.3: <bound method> = bound_method %int_1, %impl.elem0.loc16_40.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc16_40.2: <specific function> = specific_function %impl.elem0.loc16_40.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc16_40.4: <bound method> = bound_method %int_1, %specific_fn.loc16_40.2 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16_40: init %u1 = call %bound_method.loc16_40.4(%int_1) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc16_40.3: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16_40 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc16_40.4: %u1 = converted %int_1, %.loc16_40.3 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc16_40.5: ref %u1 = class_element_access %.loc16_40.2, element0
// CHECK:STDOUT:   %impl.elem0.loc16_40.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc16_40.5: <bound method> = bound_method %.loc16_40.4, %impl.elem0.loc16_40.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound]
// CHECK:STDOUT:   %specific_fn.loc16_40.3: <specific function> = specific_function %impl.elem0.loc16_40.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc16_40.6: <bound method> = bound_method %.loc16_40.4, %specific_fn.loc16_40.3 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc16_40.6: %u1 = acquire_value %.loc16_40.5
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call: init bool = call %bound_method.loc16_40.6(%.loc16_40.4, %.loc16_40.6)
// CHECK:STDOUT:   %.loc16_40.7: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call
// CHECK:STDOUT:   %.loc16_40.8: bool = converted %UInt.as.EqWith.impl.Equal.call, %.loc16_40.7
// CHECK:STDOUT:   if %.loc16_40.8 br !.loc16_40.1 else br !.loc16_40.2
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc16_40.1:
// CHECK:STDOUT:   %.loc16_40.9: ref %.337 = class_element_access %.loc16_40.2, element1
// CHECK:STDOUT:   %.loc16_40.10: ref %tuple.type.b42 = class_element_access %.loc16_40.9, element1
// CHECK:STDOUT:   %tuple.elem0.loc16_40.1: ref %Cpp.Exception = tuple_access %.loc16_40.10, element0
// CHECK:STDOUT:   %.loc16_40.11: %Cpp.Exception = acquire_value %tuple.elem0.loc16_40.1
// CHECK:STDOUT:   %Try.facet: %Try.type = facet_value constants.%Result.900, (constants.%Try.impl_witness.d5a) [concrete = constants.%Try.facet.51d]
// CHECK:STDOUT:   %.loc16_40.12: %Try.type = converted constants.%Result.900, %Try.facet [concrete = constants.%Try.facet.51d]
// CHECK:STDOUT:   %impl.elem3: %.cfb = impl_witness_access constants.%Try.impl_witness.d5a, element3 [concrete = constants.%Result.as.Try.impl.FromBreak.c94]
// CHECK:STDOUT:   %specific_fn.loc16_40.4: <specific function> = specific_function %impl.elem3, @Result.as.Try.impl.FromBreak(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.as.Try.impl.FromBreak.specific_fn]
// CHECK:STDOUT:   %.loc14_44.1: ref %Result.900 = splice_block %return.param {}
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.call: init %Result.900 to %.loc14_44.1 = call %specific_fn.loc16_40.4(%.loc16_40.11)
// CHECK:STDOUT:   %Destroy.Op.bound.loc16_40.1: <bound method> = bound_method %.loc16_40.2, constants.%Destroy.Op.1a2547.11
// CHECK:STDOUT:   %Destroy.Op.call.loc16_40.1: init %empty_tuple.type = call %Destroy.Op.bound.loc16_40.1(%.loc16_40.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc16_3.1: <bound method> = bound_method %caught.var, constants.%Destroy.Op.1a2547.4
// CHECK:STDOUT:   %Destroy.Op.call.loc16_3.1: init %empty_tuple.type = call %Destroy.Op.bound.loc16_3.1(%caught.var)
// CHECK:STDOUT:   %Destroy.Op.bound.loc15_3.1: <bound method> = bound_method %plain.var, constants.%Destroy.Op.1a2547.4
// CHECK:STDOUT:   %Destroy.Op.call.loc15_3.1: init %empty_tuple.type = call %Destroy.Op.bound.loc15_3.1(%plain.var)
// CHECK:STDOUT:   return %Result.as.Try.impl.FromBreak.call to %return.param
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc16_40.2:
// CHECK:STDOUT:   %.loc16_40.13: ref %.337 = class_element_access %.loc16_40.2, element1
// CHECK:STDOUT:   %.loc16_40.14: ref %tuple.type.a8a = class_element_access %.loc16_40.13, element0
// CHECK:STDOUT:   %tuple.elem0.loc16_40.2: ref %i32 = tuple_access %.loc16_40.14, element0
// CHECK:STDOUT:   %.loc16_40.15: %i32 = acquire_value %tuple.elem0.loc16_40.2
// CHECK:STDOUT:   %impl.elem0.loc16_40.3: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc16_40.7: <bound method> = bound_method %.loc16_40.15, %impl.elem0.loc16_40.3
// CHECK:STDOUT:   %specific_fn.loc16_40.5: <specific function> = specific_function %impl.elem0.loc16_40.3, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc16_40.8: <bound method> = bound_method %.loc16_40.15, %specific_fn.loc16_40.5
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc16_40.8(%.loc16_40.15)
// CHECK:STDOUT:   assign %caught.var, %Int.as.Copy.impl.Op.call
// CHECK:STDOUT:   %i32.loc16: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %caught: ref %i32 = wrapper_binding caught, %caught.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %caught.patt: %pattern_type.6b6 = ref_binding_pattern caught [concrete = constants.%caught.patt]
// CHECK:STDOUT:     %caught.var_patt: %pattern_type.6b6 = var_pattern %caught.patt [concrete = constants.%caught.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.ref.loc17: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:   %Result.ref.loc17: %Result.type = name_ref Result, imports.%Core.Result.0b3 [concrete = constants.%Result.generic]
// CHECK:STDOUT:   %i32.loc17: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %Cpp.ref.loc17: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:   %Exception.ref.loc17: type = name_ref Exception, constants.%Cpp.Exception [concrete = constants.%Cpp.Exception]
// CHECK:STDOUT:   %Result.loc17: type = class_type @Result, @Result(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.900]
// CHECK:STDOUT:   %.loc17_41: %Result.Ok.type.977 = specific_constant imports.%Core.import_ref.597, @Result(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.Ok.789]
// CHECK:STDOUT:   %Ok.ref.loc17: %Result.Ok.type.977 = name_ref Ok, %.loc17_41 [concrete = constants.%Result.Ok.789]
// CHECK:STDOUT:   %plain.ref: ref %i32 = name_ref plain, %plain
// CHECK:STDOUT:   %caught.ref: ref %i32 = name_ref caught, %caught
// CHECK:STDOUT:   %impl.elem1: %.d47 = impl_witness_access constants.%AddWith.impl_witness.833, element1 [concrete = constants.%Int.as.AddWith.impl.Op.365]
// CHECK:STDOUT:   %bound_method.loc17_51.1: <bound method> = bound_method %plain.ref, %impl.elem1
// CHECK:STDOUT:   %specific_fn.loc17: <specific function> = specific_function %impl.elem1, @Int.as.AddWith.impl.Op.1(constants.%int_32) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.f25]
// CHECK:STDOUT:   %bound_method.loc17_51.2: <bound method> = bound_method %plain.ref, %specific_fn.loc17
// CHECK:STDOUT:   %.loc17_45: %i32 = acquire_value %plain.ref
// CHECK:STDOUT:   %.loc17_53: %i32 = acquire_value %caught.ref
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call: init %i32 = call %bound_method.loc17_51.2(%.loc17_45, %.loc17_53)
// CHECK:STDOUT:   %Result.Ok.specific_fn.loc17: <specific function> = specific_function %Ok.ref.loc17, @Result.Ok(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.Ok.specific_fn]
// CHECK:STDOUT:   %.loc14_44.2: ref %Result.900 = splice_block %return.param {}
// CHECK:STDOUT:   %.loc17_51.1: %i32 = value_of_initializer %Int.as.AddWith.impl.Op.call
// CHECK:STDOUT:   %.loc17_51.2: %i32 = converted %Int.as.AddWith.impl.Op.call, %.loc17_51.1
// CHECK:STDOUT:   %Result.Ok.call.loc17: init %Result.900 to %.loc14_44.2 = call %Result.Ok.specific_fn.loc17(%.loc17_51.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc16_40.2: <bound method> = bound_method %.loc16_40.2, constants.%Destroy.Op.1a2547.11
// CHECK:STDOUT:   %Destroy.Op.call.loc16_40.2: init %empty_tuple.type = call %Destroy.Op.bound.loc16_40.2(%.loc16_40.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc16_3.2: <bound method> = bound_method %caught.var, constants.%Destroy.Op.1a2547.4
// CHECK:STDOUT:   %Destroy.Op.call.loc16_3.2: init %empty_tuple.type = call %Destroy.Op.bound.loc16_3.2(%caught.var)
// CHECK:STDOUT:   %Destroy.Op.bound.loc15_3.2: <bound method> = bound_method %plain.var, constants.%Destroy.Op.1a2547.4
// CHECK:STDOUT:   %Destroy.Op.call.loc15_3.2: init %empty_tuple.type = call %Destroy.Op.bound.loc15_3.2(%plain.var)
// CHECK:STDOUT:   return %Result.Ok.call.loc17 to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc16_40.1(%self.param: ref %u1.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc16_40.2(%self.param: ref %u1) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc16_40.3(%self.param: ref %i32.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc16_40.4(%self.param: ref %i32) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc16_40.5(%self.param: ref %tuple.type.a8a) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc16_40.6(%self.param: ref %ptr.00a) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc16_40.7(%self.param: ref %Cpp.Exception) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc16_40.8(%self.param: ref %tuple.type.b42) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc16_40.9(%self.param: ref %.337) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc16_40.10(%self.param: ref %struct_type.discriminant.payload.b51) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc16_40.11(%self.param: ref %ControlFlow.bd1) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- paren_operand.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %Result.type: type = generic_class_type @Result [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %Result.generic: %Result.type = struct_value () [concrete]
// CHECK:STDOUT:   %E: type = symbolic_binding E, 1 [symbolic]
// CHECK:STDOUT:   %T.67d: type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %u1: type = class_type @UInt, @UInt(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %u1.builtin: type = int_type unsigned, %int_1.5b8 [concrete]
// CHECK:STDOUT:   %Result.Err.type.b75: type = fn_type @Result.Err, @Result(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %Result.Err.08c: %Result.Err.type.b75 = struct_value () [symbolic]
// CHECK:STDOUT:   %Result.Ok.type.898: type = fn_type @Result.Ok, @Result(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %Result.Ok.58a: %Result.Ok.type.898 = struct_value () [symbolic]
// CHECK:STDOUT:   %int_1.233: %u1 = int_value 1 [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %Int.type: type = generic_class_type @Int [concrete]
// CHECK:STDOUT:   %Int.generic: %Int.type = struct_value () [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %Cpp.Exception: type = class_type @Exception [concrete]
// CHECK:STDOUT:   %Cpp.void: type = class_type @VoidBase [concrete]
// CHECK:STDOUT:   %ptr.00a: type = ptr_type %Cpp.void [concrete]
// CHECK:STDOUT:   %Result.900: type = class_type @Result, @Result(%i32, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %.c19: Core.Form = init_form %Result.900 [concrete]
// CHECK:STDOUT:   %pattern_type.5d9: type = pattern_type %Result.900 [concrete]
// CHECK:STDOUT:   %return.param_patt.8a0: %pattern_type.5d9 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.dd6: %pattern_type.5d9 = return_slot_pattern %return.param_patt.8a0, %Result.900 [concrete]
// CHECK:STDOUT:   %P.type: type = fn_type @P [concrete]
// CHECK:STDOUT:   %P: %P.type = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %i32.builtin: type = int_type signed, %int_32 [concrete]
// CHECK:STDOUT:   %tuple.type.a8a: type = tuple_type (%i32) [concrete]
// CHECK:STDOUT:   %tuple.type.b42: type = tuple_type (%Cpp.Exception) [concrete]
// CHECK:STDOUT:   %Result.Ok.type.977: type = fn_type @Result.Ok, @Result(%i32, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %Result.Ok.789: %Result.Ok.type.977 = struct_value () [concrete]
// CHECK:STDOUT:   %Result.Err.type.a4b: type = fn_type @Result.Err, @Result(%i32, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %Result.Err.7cb: %Result.Err.type.a4b = struct_value () [concrete]
// CHECK:STDOUT:   %one.patt: %pattern_type.6b6 = ref_binding_pattern one [concrete]
// CHECK:STDOUT:   %one.var_patt: %pattern_type.6b6 = var_pattern %one.patt [concrete]
// CHECK:STDOUT:   %may_throw_int.cpp_overload_set.type: type = cpp_overload_set_type @may_throw_int.cpp_overload_set [concrete]
// CHECK:STDOUT:   %may_throw_int.cpp_overload_set.value: %may_throw_int.cpp_overload_set.type = cpp_overload_set_value @may_throw_int.cpp_overload_set [concrete]
// CHECK:STDOUT:   %Try.type: type = facet_type <@Try> [concrete]
// CHECK:STDOUT:   %ptr.d08: type = ptr_type %i32 [concrete]
// CHECK:STDOUT:   %ptr.6f9: type = ptr_type %ptr.00a [concrete]
// CHECK:STDOUT:   %may_throw_int__carbon_catching_thunk.type: type = fn_type @may_throw_int__carbon_catching_thunk [concrete]
// CHECK:STDOUT:   %may_throw_int__carbon_catching_thunk: %may_throw_int__carbon_catching_thunk.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.0ff: type = generic_interface_type @ImplicitAs [concrete]
// CHECK:STDOUT:   %ImplicitAs.generic: %ImplicitAs.type.0ff = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %To.fe9: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.48f: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet.48f [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.6e0: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_0.3c0: %i32 = int_value 0 [concrete]
// CHECK:STDOUT:   %EqWith.type.f77: type = generic_interface_type @EqWith [concrete]
// CHECK:STDOUT:   %EqWith.generic: %EqWith.type.f77 = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.type.8ee: type = facet_type <@EqWith, @EqWith(%i32)> [concrete]
// CHECK:STDOUT:   %M: Core.IntLiteral = symbolic_binding M, 1 [symbolic]
// CHECK:STDOUT:   %Int.as.EqWith.impl.Equal.type.9a2: type = fn_type @Int.as.EqWith.impl.Equal.1, @Int.as.EqWith.impl.e9c(%N, %M) [symbolic]
// CHECK:STDOUT:   %Int.as.EqWith.impl.Equal.792: %Int.as.EqWith.impl.Equal.type.9a2 = struct_value () [symbolic]
// CHECK:STDOUT:   %EqWith.impl_witness.34c: <witness> = impl_witness imports.%EqWith.impl_witness_table.09e, @Int.as.EqWith.impl.e9c(%int_32, %int_32) [concrete]
// CHECK:STDOUT:   %Int.as.EqWith.impl.Equal.type.01c: type = fn_type @Int.as.EqWith.impl.Equal.1, @Int.as.EqWith.impl.e9c(%int_32, %int_32) [concrete]
// CHECK:STDOUT:   %Int.as.EqWith.impl.Equal.34f: %Int.as.EqWith.impl.Equal.type.01c = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.508: %EqWith.type.8ee = facet_value %i32, (%EqWith.impl_witness.34c) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.530: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%i32, %EqWith.facet.508) [concrete]
// CHECK:STDOUT:   %.a79: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.530, %EqWith.facet.508 [concrete]
// CHECK:STDOUT:   %Int.as.EqWith.impl.Equal.specific_fn.12d: <specific function> = specific_function %Int.as.EqWith.impl.Equal.34f, @Int.as.EqWith.impl.Equal.1(%int_32, %int_32) [concrete]
// CHECK:STDOUT:   %Result.Ok.specific_fn: <specific function> = specific_function %Result.Ok.789, @Result.Ok(%i32, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %Result.Err.specific_fn.031: <specific function> = specific_function %Result.Err.7cb, @Result.Err(%i32, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.type.834: type = fn_type @Result.as.Try.impl.FromBreak, @Result.as.Try.impl(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.9cc: %Result.as.Try.impl.FromBreak.type.834 = struct_value () [symbolic]
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.type.d6a: type = fn_type @Result.as.Try.impl.Branch, @Result.as.Try.impl(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.513: %Result.as.Try.impl.Branch.type.d6a = struct_value () [symbolic]
// CHECK:STDOUT:   %Try.impl_witness.d5a: <witness> = impl_witness imports.%Try.impl_witness_table, @Result.as.Try.impl(%i32, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.type.521: type = fn_type @Result.as.Try.impl.Branch, @Result.as.Try.impl(%i32, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.1b9: %Result.as.Try.impl.Branch.type.521 = struct_value () [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.type.b43: type = fn_type @Result.as.Try.impl.FromBreak, @Result.as.Try.impl(%i32, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.c94: %Result.as.Try.impl.FromBreak.type.b43 = struct_value () [concrete]
// CHECK:STDOUT:   %Try.facet.51d: %Try.type = facet_value %Result.900, (%Try.impl_witness.d5a) [concrete]
// CHECK:STDOUT:   %Try.WithSelf.Branch.type.353: type = fn_type @Try.WithSelf.Branch, @Try.WithSelf(%Try.facet.51d) [concrete]
// CHECK:STDOUT:   %Try.WithSelf.FromBreak.type.cf1: type = fn_type @Try.WithSelf.FromBreak, @Try.WithSelf(%Try.facet.51d) [concrete]
// CHECK:STDOUT:   %.8bc: type = fn_type_with_self_type %Try.WithSelf.Branch.type.353, %Try.facet.51d [concrete]
// CHECK:STDOUT:   %ControlFlow.bd1: type = class_type @ControlFlow, @ControlFlow(%i32, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.specific_fn.2e1: <specific function> = specific_function %Result.as.Try.impl.Branch.1b9, @Result.as.Try.impl.Branch(%i32, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %.337: type = custom_layout_type {size=8, align=8, .Continue@0: %tuple.type.a8a, .Break@0: %tuple.type.b42} [concrete]
// CHECK:STDOUT:   %struct_type.discriminant.payload.b51: type = struct_type {.discriminant: %u1, .payload: %.337} [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.ca1: type = facet_type <@ImplicitAs, @ImplicitAs(%u1)> [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.b68(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.170: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.f4c: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.f01, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.46b: %ImplicitAs.type.ca1 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.f4c) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.77c: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%u1, %ImplicitAs.facet.46b) [concrete]
// CHECK:STDOUT:   %.e74: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.77c, %ImplicitAs.facet.46b [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.d7a: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
// CHECK:STDOUT:   %EqWith.type.c25: type = facet_type <@EqWith, @EqWith(%u1)> [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.544: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%N, %M) [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.c67: %UInt.as.EqWith.impl.Equal.type.544 = struct_value () [symbolic]
// CHECK:STDOUT:   %EqWith.impl_witness.7b3: <witness> = impl_witness imports.%EqWith.impl_witness_table.166, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.29b: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.ba4: %UInt.as.EqWith.impl.Equal.type.29b = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.4d0: %EqWith.type.c25 = facet_value %u1, (%EqWith.impl_witness.7b3) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.e3c: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%u1, %EqWith.facet.4d0) [concrete]
// CHECK:STDOUT:   %.9eb: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.e3c, %EqWith.facet.4d0 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.specific_fn.6b6: <specific function> = specific_function %UInt.as.EqWith.impl.Equal.ba4, @UInt.as.EqWith.impl.Equal.1(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.a82: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
// CHECK:STDOUT:   %.cfb: type = fn_type_with_self_type %Try.WithSelf.FromBreak.type.cf1, %Try.facet.51d [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.specific_fn: <specific function> = specific_function %Result.as.Try.impl.FromBreak.c94, @Result.as.Try.impl.FromBreak(%i32, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %Destroy.type: type = facet_type <@Destroy> [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.4: type = fn_type @Destroy.Op.loc14_39.4 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.4: %Destroy.Op.type.1d8f74.4 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.11: type = fn_type @Destroy.Op.loc14_39.11 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.11: %Destroy.Op.type.1d8f74.11 = struct_value () [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet: %Copy.type = facet_value %i32, (%Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.381: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet) [concrete]
// CHECK:STDOUT:   %.737: type = fn_type_with_self_type %Copy.WithSelf.Op.type.381, %Copy.facet [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %two.patt: %pattern_type.6b6 = ref_binding_pattern two [concrete]
// CHECK:STDOUT:   %two.var_patt: %pattern_type.6b6 = var_pattern %two.patt [concrete]
// CHECK:STDOUT:   %AddWith.type.2ef: type = generic_interface_type @AddWith [concrete]
// CHECK:STDOUT:   %AddWith.generic: %AddWith.type.2ef = struct_value () [concrete]
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
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .Result = %Core.Result.0b3
// CHECK:STDOUT:     .Int = %Core.Int
// CHECK:STDOUT:     .CppCompat = %CppCompat.f0dbf9.1
// CHECK:STDOUT:     .Try = %Core.Try
// CHECK:STDOUT:     .ImplicitAs = %Core.ImplicitAs
// CHECK:STDOUT:     .EqWith = %Core.EqWith
// CHECK:STDOUT:     .Destroy = %Core.Destroy
// CHECK:STDOUT:     .Copy = %Core.Copy
// CHECK:STDOUT:     .AddWith = %Core.AddWith
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Cpp: <namespace> = namespace file.%Cpp.import_cpp, [concrete] {
// CHECK:STDOUT:     .Exception = constants.%Cpp.Exception
// CHECK:STDOUT:     .may_throw_int = %may_throw_int.cpp_overload_set.value
// CHECK:STDOUT:     import Cpp//...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Result.0b3: %Result.type = import_ref Core//prelude/types/result, Result, loaded [concrete = constants.%Result.generic]
// CHECK:STDOUT:   %Core.import_ref.597: @Result.%Result.Ok.type (%Result.Ok.type.898) = import_ref Core//prelude/types/result, loc{{\d+_\d+}}, loaded [symbolic = @Result.%Result.Ok (constants.%Result.Ok.58a)]
// CHECK:STDOUT:   %Core.import_ref.bfc4: @Result.%Result.Err.type (%Result.Err.type.b75) = import_ref Core//prelude/types/result, loc{{\d+_\d+}}, loaded [symbolic = @Result.%Result.Err (constants.%Result.Err.08c)]
// CHECK:STDOUT:   %Core.Int: %Int.type = import_ref Core//prelude/types/int, Int, loaded [concrete = constants.%Int.generic]
// CHECK:STDOUT:   %Core.CppCompat: <namespace> = import_ref Core//prelude, CppCompat, loaded
// CHECK:STDOUT:   %CppCompat.f0dbf9.1: <namespace> = namespace %Core.CppCompat, [concrete] {
// CHECK:STDOUT:     .Exception = %Core.Exception
// CHECK:STDOUT:     .VoidBase = %Core.VoidBase
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Exception: type = import_ref Core//prelude/types/cpp/exception, Exception, loaded [concrete = constants.%Cpp.Exception]
// CHECK:STDOUT:   %may_throw_int.cpp_overload_set.value: %may_throw_int.cpp_overload_set.type = cpp_overload_set_value @may_throw_int.cpp_overload_set [concrete = constants.%may_throw_int.cpp_overload_set.value]
// CHECK:STDOUT:   %Core.Try: type = import_ref Core//prelude/try, Try, loaded [concrete = constants.%Try.type]
// CHECK:STDOUT:   %Core.VoidBase: type = import_ref Core//prelude/types/cpp/void, VoidBase, loaded [concrete = constants.%Cpp.void]
// CHECK:STDOUT:   %may_throw_int__carbon_catching_thunk.decl: %may_throw_int__carbon_catching_thunk.type = fn_decl @may_throw_int__carbon_catching_thunk [concrete = constants.%may_throw_int__carbon_catching_thunk] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.ImplicitAs: %ImplicitAs.type.0ff = import_ref Core//prelude/operators/as, ImplicitAs, loaded [concrete = constants.%ImplicitAs.generic]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.EqWith: %EqWith.type.f77 = import_ref Core//prelude/operators/comparison, EqWith, loaded [concrete = constants.%EqWith.generic]
// CHECK:STDOUT:   %Core.import_ref.074: @Int.as.EqWith.impl.e9c.%Int.as.EqWith.impl.Equal.type (%Int.as.EqWith.impl.Equal.type.9a2) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.EqWith.impl.e9c.%Int.as.EqWith.impl.Equal (constants.%Int.as.EqWith.impl.Equal.792)]
// CHECK:STDOUT:   %Core.import_ref.449 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.09e = impl_witness_table (%Core.import_ref.074, %Core.import_ref.449), @Int.as.EqWith.impl.e9c [concrete]
// CHECK:STDOUT:   %Core.import_ref.0b3 = import_ref Core//prelude/types/result, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.6e9 = import_ref Core//prelude/types/result, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9f4: @Result.as.Try.impl.%Result.as.Try.impl.Branch.type (%Result.as.Try.impl.Branch.type.d6a) = import_ref Core//prelude/types/result, loc{{\d+_\d+}}, loaded [symbolic = @Result.as.Try.impl.%Result.as.Try.impl.Branch (constants.%Result.as.Try.impl.Branch.513)]
// CHECK:STDOUT:   %Core.import_ref.6a4: @Result.as.Try.impl.%Result.as.Try.impl.FromBreak.type (%Result.as.Try.impl.FromBreak.type.834) = import_ref Core//prelude/types/result, loc{{\d+_\d+}}, loaded [symbolic = @Result.as.Try.impl.%Result.as.Try.impl.FromBreak (constants.%Result.as.Try.impl.FromBreak.9cc)]
// CHECK:STDOUT:   %Try.impl_witness_table = impl_witness_table (%Core.import_ref.0b3, %Core.import_ref.6e9, %Core.import_ref.9f4, %Core.import_ref.6a4), @Result.as.Try.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.aa5: @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.170)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.f01 = impl_witness_table (%Core.import_ref.aa5), @Core.IntLiteral.as.ImplicitAs.impl.b68 [concrete]
// CHECK:STDOUT:   %Core.import_ref.b92: @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal.type (%UInt.as.EqWith.impl.Equal.type.544) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal (constants.%UInt.as.EqWith.impl.Equal.c67)]
// CHECK:STDOUT:   %Core.import_ref.b44 = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.166 = impl_witness_table (%Core.import_ref.b92, %Core.import_ref.b44), @UInt.as.EqWith.impl.f13 [concrete]
// CHECK:STDOUT:   %Core.Destroy: type = import_ref Core//prelude/destroy, Destroy, loaded [concrete = constants.%Destroy.type]
// CHECK:STDOUT:   %Core.Copy: type = import_ref Core//prelude/copy, Copy, loaded [concrete = constants.%Copy.type]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.AddWith: %AddWith.type.2ef = import_ref Core//prelude/operators/arithmetic, AddWith, loaded [concrete = constants.%AddWith.generic]
// CHECK:STDOUT:   %Core.import_ref.b4fd3a.1 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.684: @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op.type (%Int.as.AddWith.impl.Op.type.610) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op (constants.%Int.as.AddWith.impl.Op.732)]
// CHECK:STDOUT:   %AddWith.impl_witness_table.6b4 = impl_witness_table (%Core.import_ref.b4fd3a.1, %Core.import_ref.684), @Int.as.AddWith.impl.3af [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %P.decl: %P.type = fn_decl @P [concrete = constants.%P] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.5d9 = out_param_pattern [concrete = constants.%return.param_patt.8a0]
// CHECK:STDOUT:     %return.patt: %pattern_type.5d9 = return_slot_pattern %return.param_patt, %Result.loc13 [concrete = constants.%return.patt.dd6]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %Core.ref.loc13: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:     %Result.ref.loc13: %Result.type = name_ref Result, imports.%Core.Result.0b3 [concrete = constants.%Result.generic]
// CHECK:STDOUT:     %i32.loc13: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %Cpp.ref.loc13: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:     %Exception.ref.loc13: type = name_ref Exception, constants.%Cpp.Exception [concrete = constants.%Cpp.Exception]
// CHECK:STDOUT:     %Result.loc13: type = class_type @Result, @Result(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.900]
// CHECK:STDOUT:     %.loc13_41.4: Core.Form = init_form %Result.loc13 [concrete = constants.%.c19]
// CHECK:STDOUT:     %return.param: ref %Result.900 = out_param call_param0
// CHECK:STDOUT:     %return: ref %Result.900 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @P() -> out %return.param: %Result.900 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %one.var: ref %i32 = var_storage %one.var_patt
// CHECK:STDOUT:   %Cpp.ref.loc14: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:   %may_throw_int.ref.loc14: %may_throw_int.cpp_overload_set.type = name_ref may_throw_int, imports.%may_throw_int.cpp_overload_set.value [concrete = constants.%may_throw_int.cpp_overload_set.value]
// CHECK:STDOUT:   %Result.loc14: type = class_type @Result, @Result(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.900]
// CHECK:STDOUT:   %.loc14_37.1: ref %i32 = temporary_storage
// CHECK:STDOUT:   %addr.loc14_37.1: %ptr.d08 = addr_of %.loc14_37.1
// CHECK:STDOUT:   %.loc14_37.2: ref %ptr.00a = temporary_storage
// CHECK:STDOUT:   %addr.loc14_37.2: %ptr.6f9 = addr_of %.loc14_37.2
// CHECK:STDOUT:   %may_throw_int__carbon_catching_thunk.call.loc14: init %i32 = call imports.%may_throw_int__carbon_catching_thunk.decl(%addr.loc14_37.1, %addr.loc14_37.2)
// CHECK:STDOUT:   %int_0.loc14: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc14_37.1: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc14_37.1: <bound method> = bound_method %int_0.loc14, %impl.elem0.loc14_37.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc14_37.1: <specific function> = specific_function %impl.elem0.loc14_37.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc14_37.2: <bound method> = bound_method %int_0.loc14, %specific_fn.loc14_37.1 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14_37: init %i32 = call %bound_method.loc14_37.2(%int_0.loc14) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc14_37.3: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14_37 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc14_37.4: %i32 = converted %int_0.loc14, %.loc14_37.3 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %impl.elem0.loc14_37.2: %.a79 = impl_witness_access constants.%EqWith.impl_witness.34c, element0 [concrete = constants.%Int.as.EqWith.impl.Equal.34f]
// CHECK:STDOUT:   %bound_method.loc14_37.3: <bound method> = bound_method %may_throw_int__carbon_catching_thunk.call.loc14, %impl.elem0.loc14_37.2
// CHECK:STDOUT:   %specific_fn.loc14_37.2: <specific function> = specific_function %impl.elem0.loc14_37.2, @Int.as.EqWith.impl.Equal.1(constants.%int_32, constants.%int_32) [concrete = constants.%Int.as.EqWith.impl.Equal.specific_fn.12d]
// CHECK:STDOUT:   %bound_method.loc14_37.4: <bound method> = bound_method %may_throw_int__carbon_catching_thunk.call.loc14, %specific_fn.loc14_37.2
// CHECK:STDOUT:   %.loc14_37.5: %i32 = value_of_initializer %may_throw_int__carbon_catching_thunk.call.loc14
// CHECK:STDOUT:   %.loc14_37.6: %i32 = converted %may_throw_int__carbon_catching_thunk.call.loc14, %.loc14_37.5
// CHECK:STDOUT:   %Int.as.EqWith.impl.Equal.call.loc14: init bool = call %bound_method.loc14_37.4(%.loc14_37.6, %.loc14_37.4)
// CHECK:STDOUT:   %.loc14_37.7: bool = value_of_initializer %Int.as.EqWith.impl.Equal.call.loc14
// CHECK:STDOUT:   %.loc14_37.8: bool = converted %Int.as.EqWith.impl.Equal.call.loc14, %.loc14_37.7
// CHECK:STDOUT:   %.loc14_37.9: ref %Result.900 = temporary_storage
// CHECK:STDOUT:   if %.loc14_37.8 br !.loc14_37.1 else br !.loc14_37.2
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc14_37.1:
// CHECK:STDOUT:   %.loc14_37.10: %i32 = acquire_value %.loc14_37.1
// CHECK:STDOUT:   %.loc14_37.11: %Result.Ok.type.977 = specific_constant imports.%Core.import_ref.597, @Result(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.Ok.789]
// CHECK:STDOUT:   %Ok.ref.loc14: %Result.Ok.type.977 = name_ref Ok, %.loc14_37.11 [concrete = constants.%Result.Ok.789]
// CHECK:STDOUT:   %Result.Ok.specific_fn.loc14: <specific function> = specific_function %Ok.ref.loc14, @Result.Ok(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.Ok.specific_fn]
// CHECK:STDOUT:   %.loc14_37.12: ref %Result.900 = splice_block %.loc14_37.9 {}
// CHECK:STDOUT:   %Result.Ok.call.loc14: init %Result.900 to %.loc14_37.12 = call %Result.Ok.specific_fn.loc14(%.loc14_37.10)
// CHECK:STDOUT:   assign %.loc14_37.9, %Result.Ok.call.loc14
// CHECK:STDOUT:   br !.loc14_37.3
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc14_37.2:
// CHECK:STDOUT:   %.loc14_37.13: %ptr.00a = acquire_value %.loc14_37.2
// CHECK:STDOUT:   %.loc14_37.14: %Cpp.Exception = as_compatible %.loc14_37.13
// CHECK:STDOUT:   %.loc14_37.15: %Cpp.Exception = converted %.loc14_37.13, %.loc14_37.14
// CHECK:STDOUT:   %.loc14_37.16: %Result.Err.type.a4b = specific_constant imports.%Core.import_ref.bfc4, @Result(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.Err.7cb]
// CHECK:STDOUT:   %Err.ref.loc14: %Result.Err.type.a4b = name_ref Err, %.loc14_37.16 [concrete = constants.%Result.Err.7cb]
// CHECK:STDOUT:   %Result.Err.specific_fn.loc14: <specific function> = specific_function %Err.ref.loc14, @Result.Err(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.Err.specific_fn.031]
// CHECK:STDOUT:   %.loc14_37.17: ref %Result.900 = splice_block %.loc14_37.9 {}
// CHECK:STDOUT:   %Result.Err.call.loc14: init %Result.900 to %.loc14_37.17 = call %Result.Err.specific_fn.loc14(%.loc14_37.15)
// CHECK:STDOUT:   assign %.loc14_37.9, %Result.Err.call.loc14
// CHECK:STDOUT:   br !.loc14_37.3
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc14_37.3:
// CHECK:STDOUT:   %.loc14_37.18: %Result.900 = acquire_value %.loc14_37.9
// CHECK:STDOUT:   %impl.elem2.loc14: %.8bc = impl_witness_access constants.%Try.impl_witness.d5a, element2 [concrete = constants.%Result.as.Try.impl.Branch.1b9]
// CHECK:STDOUT:   %bound_method.loc14_39.1: <bound method> = bound_method %.loc14_37.18, %impl.elem2.loc14
// CHECK:STDOUT:   %specific_fn.loc14_39.1: <specific function> = specific_function %impl.elem2.loc14, @Result.as.Try.impl.Branch(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.as.Try.impl.Branch.specific_fn.2e1]
// CHECK:STDOUT:   %bound_method.loc14_39.2: <bound method> = bound_method %.loc14_37.18, %specific_fn.loc14_39.1
// CHECK:STDOUT:   %.loc14_39.1: ref %ControlFlow.bd1 = temporary_storage
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.call.loc14: init %ControlFlow.bd1 to %.loc14_39.1 = call %bound_method.loc14_39.2(%.loc14_37.18)
// CHECK:STDOUT:   %.loc14_39.2: ref %ControlFlow.bd1 = temporary %.loc14_39.1, %Result.as.Try.impl.Branch.call.loc14
// CHECK:STDOUT:   %int_1.loc14: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc14_39.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc14_39.3: <bound method> = bound_method %int_1.loc14, %impl.elem0.loc14_39.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc14_39.2: <specific function> = specific_function %impl.elem0.loc14_39.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc14_39.4: <bound method> = bound_method %int_1.loc14, %specific_fn.loc14_39.2 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14_39: init %u1 = call %bound_method.loc14_39.4(%int_1.loc14) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc14_39.3: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14_39 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc14_39.4: %u1 = converted %int_1.loc14, %.loc14_39.3 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc14_39.5: ref %u1 = class_element_access %.loc14_39.2, element0
// CHECK:STDOUT:   %impl.elem0.loc14_39.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc14_39.5: <bound method> = bound_method %.loc14_39.4, %impl.elem0.loc14_39.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound]
// CHECK:STDOUT:   %specific_fn.loc14_39.3: <specific function> = specific_function %impl.elem0.loc14_39.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc14_39.6: <bound method> = bound_method %.loc14_39.4, %specific_fn.loc14_39.3 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc14_39.6: %u1 = acquire_value %.loc14_39.5
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc14: init bool = call %bound_method.loc14_39.6(%.loc14_39.4, %.loc14_39.6)
// CHECK:STDOUT:   %.loc14_39.7: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc14
// CHECK:STDOUT:   %.loc14_39.8: bool = converted %UInt.as.EqWith.impl.Equal.call.loc14, %.loc14_39.7
// CHECK:STDOUT:   if %.loc14_39.8 br !.loc14_39.1 else br !.loc14_39.2
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc14_39.1:
// CHECK:STDOUT:   %.loc14_39.9: ref %.337 = class_element_access %.loc14_39.2, element1
// CHECK:STDOUT:   %.loc14_39.10: ref %tuple.type.b42 = class_element_access %.loc14_39.9, element1
// CHECK:STDOUT:   %tuple.elem0.loc14_39.1: ref %Cpp.Exception = tuple_access %.loc14_39.10, element0
// CHECK:STDOUT:   %.loc14_39.11: %Cpp.Exception = acquire_value %tuple.elem0.loc14_39.1
// CHECK:STDOUT:   %Try.facet.loc14: %Try.type = facet_value constants.%Result.900, (constants.%Try.impl_witness.d5a) [concrete = constants.%Try.facet.51d]
// CHECK:STDOUT:   %.loc14_39.12: %Try.type = converted constants.%Result.900, %Try.facet.loc14 [concrete = constants.%Try.facet.51d]
// CHECK:STDOUT:   %impl.elem3.loc14: %.cfb = impl_witness_access constants.%Try.impl_witness.d5a, element3 [concrete = constants.%Result.as.Try.impl.FromBreak.c94]
// CHECK:STDOUT:   %specific_fn.loc14_39.4: <specific function> = specific_function %impl.elem3.loc14, @Result.as.Try.impl.FromBreak(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.as.Try.impl.FromBreak.specific_fn]
// CHECK:STDOUT:   %.loc13_41.1: ref %Result.900 = splice_block %return.param {}
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.call.loc14: init %Result.900 to %.loc13_41.1 = call %specific_fn.loc14_39.4(%.loc14_39.11)
// CHECK:STDOUT:   %Destroy.Op.bound.loc14_39.1: <bound method> = bound_method %.loc14_39.2, constants.%Destroy.Op.1a2547.11
// CHECK:STDOUT:   %Destroy.Op.call.loc14_39.1: init %empty_tuple.type = call %Destroy.Op.bound.loc14_39.1(%.loc14_39.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc14_3.1: <bound method> = bound_method %one.var, constants.%Destroy.Op.1a2547.4
// CHECK:STDOUT:   %Destroy.Op.call.loc14_3.1: init %empty_tuple.type = call %Destroy.Op.bound.loc14_3.1(%one.var)
// CHECK:STDOUT:   return %Result.as.Try.impl.FromBreak.call.loc14 to %return.param
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc14_39.2:
// CHECK:STDOUT:   %.loc14_39.13: ref %.337 = class_element_access %.loc14_39.2, element1
// CHECK:STDOUT:   %.loc14_39.14: ref %tuple.type.a8a = class_element_access %.loc14_39.13, element0
// CHECK:STDOUT:   %tuple.elem0.loc14_39.2: ref %i32 = tuple_access %.loc14_39.14, element0
// CHECK:STDOUT:   %.loc14_39.15: %i32 = acquire_value %tuple.elem0.loc14_39.2
// CHECK:STDOUT:   %impl.elem0.loc14_39.3: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc14_39.7: <bound method> = bound_method %.loc14_39.15, %impl.elem0.loc14_39.3
// CHECK:STDOUT:   %specific_fn.loc14_39.5: <specific function> = specific_function %impl.elem0.loc14_39.3, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc14_39.8: <bound method> = bound_method %.loc14_39.15, %specific_fn.loc14_39.5
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call.loc14: init %i32 = call %bound_method.loc14_39.8(%.loc14_39.15)
// CHECK:STDOUT:   assign %one.var, %Int.as.Copy.impl.Op.call.loc14
// CHECK:STDOUT:   %i32.loc14: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %one: ref %i32 = wrapper_binding one, %one.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %one.patt: %pattern_type.6b6 = ref_binding_pattern one [concrete = constants.%one.patt]
// CHECK:STDOUT:     %one.var_patt: %pattern_type.6b6 = var_pattern %one.patt [concrete = constants.%one.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %two.var: ref %i32 = var_storage %two.var_patt
// CHECK:STDOUT:   %Cpp.ref.loc15: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:   %may_throw_int.ref.loc15: %may_throw_int.cpp_overload_set.type = name_ref may_throw_int, imports.%may_throw_int.cpp_overload_set.value [concrete = constants.%may_throw_int.cpp_overload_set.value]
// CHECK:STDOUT:   %Result.loc15: type = class_type @Result, @Result(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.900]
// CHECK:STDOUT:   %.loc15_38.1: ref %i32 = temporary_storage
// CHECK:STDOUT:   %addr.loc15_38.1: %ptr.d08 = addr_of %.loc15_38.1
// CHECK:STDOUT:   %.loc15_38.2: ref %ptr.00a = temporary_storage
// CHECK:STDOUT:   %addr.loc15_38.2: %ptr.6f9 = addr_of %.loc15_38.2
// CHECK:STDOUT:   %may_throw_int__carbon_catching_thunk.call.loc15: init %i32 = call imports.%may_throw_int__carbon_catching_thunk.decl(%addr.loc15_38.1, %addr.loc15_38.2)
// CHECK:STDOUT:   %int_0.loc15: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc15_38.1: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc15_38.1: <bound method> = bound_method %int_0.loc15, %impl.elem0.loc15_38.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc15_38.1: <specific function> = specific_function %impl.elem0.loc15_38.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc15_38.2: <bound method> = bound_method %int_0.loc15, %specific_fn.loc15_38.1 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc15_38: init %i32 = call %bound_method.loc15_38.2(%int_0.loc15) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc15_38.3: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc15_38 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc15_38.4: %i32 = converted %int_0.loc15, %.loc15_38.3 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %impl.elem0.loc15_38.2: %.a79 = impl_witness_access constants.%EqWith.impl_witness.34c, element0 [concrete = constants.%Int.as.EqWith.impl.Equal.34f]
// CHECK:STDOUT:   %bound_method.loc15_38.3: <bound method> = bound_method %may_throw_int__carbon_catching_thunk.call.loc15, %impl.elem0.loc15_38.2
// CHECK:STDOUT:   %specific_fn.loc15_38.2: <specific function> = specific_function %impl.elem0.loc15_38.2, @Int.as.EqWith.impl.Equal.1(constants.%int_32, constants.%int_32) [concrete = constants.%Int.as.EqWith.impl.Equal.specific_fn.12d]
// CHECK:STDOUT:   %bound_method.loc15_38.4: <bound method> = bound_method %may_throw_int__carbon_catching_thunk.call.loc15, %specific_fn.loc15_38.2
// CHECK:STDOUT:   %.loc15_38.5: %i32 = value_of_initializer %may_throw_int__carbon_catching_thunk.call.loc15
// CHECK:STDOUT:   %.loc15_38.6: %i32 = converted %may_throw_int__carbon_catching_thunk.call.loc15, %.loc15_38.5
// CHECK:STDOUT:   %Int.as.EqWith.impl.Equal.call.loc15: init bool = call %bound_method.loc15_38.4(%.loc15_38.6, %.loc15_38.4)
// CHECK:STDOUT:   %.loc15_38.7: bool = value_of_initializer %Int.as.EqWith.impl.Equal.call.loc15
// CHECK:STDOUT:   %.loc15_38.8: bool = converted %Int.as.EqWith.impl.Equal.call.loc15, %.loc15_38.7
// CHECK:STDOUT:   %.loc15_38.9: ref %Result.900 = temporary_storage
// CHECK:STDOUT:   if %.loc15_38.8 br !.loc15_38.1 else br !.loc15_38.2
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc15_38.1:
// CHECK:STDOUT:   %.loc15_38.10: %i32 = acquire_value %.loc15_38.1
// CHECK:STDOUT:   %.loc15_38.11: %Result.Ok.type.977 = specific_constant imports.%Core.import_ref.597, @Result(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.Ok.789]
// CHECK:STDOUT:   %Ok.ref.loc15: %Result.Ok.type.977 = name_ref Ok, %.loc15_38.11 [concrete = constants.%Result.Ok.789]
// CHECK:STDOUT:   %Result.Ok.specific_fn.loc15: <specific function> = specific_function %Ok.ref.loc15, @Result.Ok(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.Ok.specific_fn]
// CHECK:STDOUT:   %.loc15_38.12: ref %Result.900 = splice_block %.loc15_38.9 {}
// CHECK:STDOUT:   %Result.Ok.call.loc15: init %Result.900 to %.loc15_38.12 = call %Result.Ok.specific_fn.loc15(%.loc15_38.10)
// CHECK:STDOUT:   assign %.loc15_38.9, %Result.Ok.call.loc15
// CHECK:STDOUT:   br !.loc15_38.3
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc15_38.2:
// CHECK:STDOUT:   %.loc15_38.13: %ptr.00a = acquire_value %.loc15_38.2
// CHECK:STDOUT:   %.loc15_38.14: %Cpp.Exception = as_compatible %.loc15_38.13
// CHECK:STDOUT:   %.loc15_38.15: %Cpp.Exception = converted %.loc15_38.13, %.loc15_38.14
// CHECK:STDOUT:   %.loc15_38.16: %Result.Err.type.a4b = specific_constant imports.%Core.import_ref.bfc4, @Result(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.Err.7cb]
// CHECK:STDOUT:   %Err.ref.loc15: %Result.Err.type.a4b = name_ref Err, %.loc15_38.16 [concrete = constants.%Result.Err.7cb]
// CHECK:STDOUT:   %Result.Err.specific_fn.loc15: <specific function> = specific_function %Err.ref.loc15, @Result.Err(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.Err.specific_fn.031]
// CHECK:STDOUT:   %.loc15_38.17: ref %Result.900 = splice_block %.loc15_38.9 {}
// CHECK:STDOUT:   %Result.Err.call.loc15: init %Result.900 to %.loc15_38.17 = call %Result.Err.specific_fn.loc15(%.loc15_38.15)
// CHECK:STDOUT:   assign %.loc15_38.9, %Result.Err.call.loc15
// CHECK:STDOUT:   br !.loc15_38.3
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc15_38.3:
// CHECK:STDOUT:   %.loc15_38.18: %Result.900 = acquire_value %.loc15_38.9
// CHECK:STDOUT:   %impl.elem2.loc15: %.8bc = impl_witness_access constants.%Try.impl_witness.d5a, element2 [concrete = constants.%Result.as.Try.impl.Branch.1b9]
// CHECK:STDOUT:   %bound_method.loc15_41.1: <bound method> = bound_method %.loc15_38.18, %impl.elem2.loc15
// CHECK:STDOUT:   %specific_fn.loc15_41.1: <specific function> = specific_function %impl.elem2.loc15, @Result.as.Try.impl.Branch(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.as.Try.impl.Branch.specific_fn.2e1]
// CHECK:STDOUT:   %bound_method.loc15_41.2: <bound method> = bound_method %.loc15_38.18, %specific_fn.loc15_41.1
// CHECK:STDOUT:   %.loc15_41.1: ref %ControlFlow.bd1 = temporary_storage
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.call.loc15: init %ControlFlow.bd1 to %.loc15_41.1 = call %bound_method.loc15_41.2(%.loc15_38.18)
// CHECK:STDOUT:   %.loc15_41.2: ref %ControlFlow.bd1 = temporary %.loc15_41.1, %Result.as.Try.impl.Branch.call.loc15
// CHECK:STDOUT:   %int_1.loc15: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc15_41.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc15_41.3: <bound method> = bound_method %int_1.loc15, %impl.elem0.loc15_41.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc15_41.2: <specific function> = specific_function %impl.elem0.loc15_41.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc15_41.4: <bound method> = bound_method %int_1.loc15, %specific_fn.loc15_41.2 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc15_41: init %u1 = call %bound_method.loc15_41.4(%int_1.loc15) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc15_41.3: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc15_41 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc15_41.4: %u1 = converted %int_1.loc15, %.loc15_41.3 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc15_41.5: ref %u1 = class_element_access %.loc15_41.2, element0
// CHECK:STDOUT:   %impl.elem0.loc15_41.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc15_41.5: <bound method> = bound_method %.loc15_41.4, %impl.elem0.loc15_41.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound]
// CHECK:STDOUT:   %specific_fn.loc15_41.3: <specific function> = specific_function %impl.elem0.loc15_41.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc15_41.6: <bound method> = bound_method %.loc15_41.4, %specific_fn.loc15_41.3 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc15_41.6: %u1 = acquire_value %.loc15_41.5
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc15: init bool = call %bound_method.loc15_41.6(%.loc15_41.4, %.loc15_41.6)
// CHECK:STDOUT:   %.loc15_41.7: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc15
// CHECK:STDOUT:   %.loc15_41.8: bool = converted %UInt.as.EqWith.impl.Equal.call.loc15, %.loc15_41.7
// CHECK:STDOUT:   if %.loc15_41.8 br !.loc15_41.1 else br !.loc15_41.2
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc15_41.1:
// CHECK:STDOUT:   %.loc15_41.9: ref %.337 = class_element_access %.loc15_41.2, element1
// CHECK:STDOUT:   %.loc15_41.10: ref %tuple.type.b42 = class_element_access %.loc15_41.9, element1
// CHECK:STDOUT:   %tuple.elem0.loc15_41.1: ref %Cpp.Exception = tuple_access %.loc15_41.10, element0
// CHECK:STDOUT:   %.loc15_41.11: %Cpp.Exception = acquire_value %tuple.elem0.loc15_41.1
// CHECK:STDOUT:   %Try.facet.loc15: %Try.type = facet_value constants.%Result.900, (constants.%Try.impl_witness.d5a) [concrete = constants.%Try.facet.51d]
// CHECK:STDOUT:   %.loc15_41.12: %Try.type = converted constants.%Result.900, %Try.facet.loc15 [concrete = constants.%Try.facet.51d]
// CHECK:STDOUT:   %impl.elem3.loc15: %.cfb = impl_witness_access constants.%Try.impl_witness.d5a, element3 [concrete = constants.%Result.as.Try.impl.FromBreak.c94]
// CHECK:STDOUT:   %specific_fn.loc15_41.4: <specific function> = specific_function %impl.elem3.loc15, @Result.as.Try.impl.FromBreak(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.as.Try.impl.FromBreak.specific_fn]
// CHECK:STDOUT:   %.loc13_41.2: ref %Result.900 = splice_block %return.param {}
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.call.loc15: init %Result.900 to %.loc13_41.2 = call %specific_fn.loc15_41.4(%.loc15_41.11)
// CHECK:STDOUT:   %Destroy.Op.bound.loc15_41.1: <bound method> = bound_method %.loc15_41.2, constants.%Destroy.Op.1a2547.11
// CHECK:STDOUT:   %Destroy.Op.call.loc15_41.1: init %empty_tuple.type = call %Destroy.Op.bound.loc15_41.1(%.loc15_41.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc15_3.1: <bound method> = bound_method %two.var, constants.%Destroy.Op.1a2547.4
// CHECK:STDOUT:   %Destroy.Op.call.loc15_3.1: init %empty_tuple.type = call %Destroy.Op.bound.loc15_3.1(%two.var)
// CHECK:STDOUT:   %Destroy.Op.bound.loc14_39.2: <bound method> = bound_method %.loc14_39.2, constants.%Destroy.Op.1a2547.11
// CHECK:STDOUT:   %Destroy.Op.call.loc14_39.2: init %empty_tuple.type = call %Destroy.Op.bound.loc14_39.2(%.loc14_39.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc14_3.2: <bound method> = bound_method %one.var, constants.%Destroy.Op.1a2547.4
// CHECK:STDOUT:   %Destroy.Op.call.loc14_3.2: init %empty_tuple.type = call %Destroy.Op.bound.loc14_3.2(%one.var)
// CHECK:STDOUT:   return %Result.as.Try.impl.FromBreak.call.loc15 to %return.param
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc15_41.2:
// CHECK:STDOUT:   %.loc15_41.13: ref %.337 = class_element_access %.loc15_41.2, element1
// CHECK:STDOUT:   %.loc15_41.14: ref %tuple.type.a8a = class_element_access %.loc15_41.13, element0
// CHECK:STDOUT:   %tuple.elem0.loc15_41.2: ref %i32 = tuple_access %.loc15_41.14, element0
// CHECK:STDOUT:   %.loc15_41.15: %i32 = acquire_value %tuple.elem0.loc15_41.2
// CHECK:STDOUT:   %impl.elem0.loc15_41.3: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc15_41.7: <bound method> = bound_method %.loc15_41.15, %impl.elem0.loc15_41.3
// CHECK:STDOUT:   %specific_fn.loc15_41.5: <specific function> = specific_function %impl.elem0.loc15_41.3, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc15_41.8: <bound method> = bound_method %.loc15_41.15, %specific_fn.loc15_41.5
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call.loc15: init %i32 = call %bound_method.loc15_41.8(%.loc15_41.15)
// CHECK:STDOUT:   assign %two.var, %Int.as.Copy.impl.Op.call.loc15
// CHECK:STDOUT:   %i32.loc15: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %two: ref %i32 = wrapper_binding two, %two.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %two.patt: %pattern_type.6b6 = ref_binding_pattern two [concrete = constants.%two.patt]
// CHECK:STDOUT:     %two.var_patt: %pattern_type.6b6 = var_pattern %two.patt [concrete = constants.%two.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.ref.loc16: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:   %Result.ref.loc16: %Result.type = name_ref Result, imports.%Core.Result.0b3 [concrete = constants.%Result.generic]
// CHECK:STDOUT:   %i32.loc16: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %Cpp.ref.loc16: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:   %Exception.ref.loc16: type = name_ref Exception, constants.%Cpp.Exception [concrete = constants.%Cpp.Exception]
// CHECK:STDOUT:   %Result.loc16: type = class_type @Result, @Result(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.900]
// CHECK:STDOUT:   %.loc16_41: %Result.Ok.type.977 = specific_constant imports.%Core.import_ref.597, @Result(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.Ok.789]
// CHECK:STDOUT:   %Ok.ref.loc16: %Result.Ok.type.977 = name_ref Ok, %.loc16_41 [concrete = constants.%Result.Ok.789]
// CHECK:STDOUT:   %one.ref: ref %i32 = name_ref one, %one
// CHECK:STDOUT:   %two.ref: ref %i32 = name_ref two, %two
// CHECK:STDOUT:   %impl.elem1: %.d47 = impl_witness_access constants.%AddWith.impl_witness.833, element1 [concrete = constants.%Int.as.AddWith.impl.Op.365]
// CHECK:STDOUT:   %bound_method.loc16_49.1: <bound method> = bound_method %one.ref, %impl.elem1
// CHECK:STDOUT:   %specific_fn.loc16: <specific function> = specific_function %impl.elem1, @Int.as.AddWith.impl.Op.1(constants.%int_32) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.f25]
// CHECK:STDOUT:   %bound_method.loc16_49.2: <bound method> = bound_method %one.ref, %specific_fn.loc16
// CHECK:STDOUT:   %.loc16_45: %i32 = acquire_value %one.ref
// CHECK:STDOUT:   %.loc16_51: %i32 = acquire_value %two.ref
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call: init %i32 = call %bound_method.loc16_49.2(%.loc16_45, %.loc16_51)
// CHECK:STDOUT:   %Result.Ok.specific_fn.loc16: <specific function> = specific_function %Ok.ref.loc16, @Result.Ok(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.Ok.specific_fn]
// CHECK:STDOUT:   %.loc13_41.3: ref %Result.900 = splice_block %return.param {}
// CHECK:STDOUT:   %.loc16_49.1: %i32 = value_of_initializer %Int.as.AddWith.impl.Op.call
// CHECK:STDOUT:   %.loc16_49.2: %i32 = converted %Int.as.AddWith.impl.Op.call, %.loc16_49.1
// CHECK:STDOUT:   %Result.Ok.call.loc16: init %Result.900 to %.loc13_41.3 = call %Result.Ok.specific_fn.loc16(%.loc16_49.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc15_41.2: <bound method> = bound_method %.loc15_41.2, constants.%Destroy.Op.1a2547.11
// CHECK:STDOUT:   %Destroy.Op.call.loc15_41.2: init %empty_tuple.type = call %Destroy.Op.bound.loc15_41.2(%.loc15_41.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc15_3.2: <bound method> = bound_method %two.var, constants.%Destroy.Op.1a2547.4
// CHECK:STDOUT:   %Destroy.Op.call.loc15_3.2: init %empty_tuple.type = call %Destroy.Op.bound.loc15_3.2(%two.var)
// CHECK:STDOUT:   %Destroy.Op.bound.loc14_39.3: <bound method> = bound_method %.loc14_39.2, constants.%Destroy.Op.1a2547.11
// CHECK:STDOUT:   %Destroy.Op.call.loc14_39.3: init %empty_tuple.type = call %Destroy.Op.bound.loc14_39.3(%.loc14_39.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc14_3.3: <bound method> = bound_method %one.var, constants.%Destroy.Op.1a2547.4
// CHECK:STDOUT:   %Destroy.Op.call.loc14_3.3: init %empty_tuple.type = call %Destroy.Op.bound.loc14_3.3(%one.var)
// CHECK:STDOUT:   return %Result.Ok.call.loc16 to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc14_39.1(%self.param: ref %u1.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc14_39.2(%self.param: ref %u1) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc14_39.3(%self.param: ref %i32.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc14_39.4(%self.param: ref %i32) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc14_39.5(%self.param: ref %tuple.type.a8a) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc14_39.6(%self.param: ref %ptr.00a) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc14_39.7(%self.param: ref %Cpp.Exception) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc14_39.8(%self.param: ref %tuple.type.b42) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc14_39.9(%self.param: ref %.337) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc14_39.10(%self.param: ref %struct_type.discriminant.payload.b51) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc14_39.11(%self.param: ref %ControlFlow.bd1) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- member.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %C.417: type = class_type @C [concrete]
// CHECK:STDOUT:   %pattern_type.bbc: type = pattern_type %C.417 [concrete]
// CHECK:STDOUT:   %c.param_patt: %pattern_type.bbc = value_param_pattern [concrete]
// CHECK:STDOUT:   %c.patt: %pattern_type.bbc = wrapper_binding_pattern c, %c.param_patt [concrete]
// CHECK:STDOUT:   %ptr.0a2: type = ptr_type %C.417 [concrete]
// CHECK:STDOUT:   %pattern_type.8fa: type = pattern_type %ptr.0a2 [concrete]
// CHECK:STDOUT:   %p.param_patt: %pattern_type.8fa = value_param_pattern [concrete]
// CHECK:STDOUT:   %p.patt: %pattern_type.8fa = wrapper_binding_pattern p, %p.param_patt [concrete]
// CHECK:STDOUT:   %Result.type: type = generic_class_type @Result [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %Result.generic: %Result.type = struct_value () [concrete]
// CHECK:STDOUT:   %E: type = symbolic_binding E, 1 [symbolic]
// CHECK:STDOUT:   %T.67d: type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %u1: type = class_type @UInt, @UInt(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %u1.builtin: type = int_type unsigned, %int_1.5b8 [concrete]
// CHECK:STDOUT:   %Result.Err.type.b75: type = fn_type @Result.Err, @Result(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %Result.Err.08c: %Result.Err.type.b75 = struct_value () [symbolic]
// CHECK:STDOUT:   %Result.Ok.type.898: type = fn_type @Result.Ok, @Result(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %Result.Ok.58a: %Result.Ok.type.898 = struct_value () [symbolic]
// CHECK:STDOUT:   %int_1.233: %u1 = int_value 1 [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %Int.type: type = generic_class_type @Int [concrete]
// CHECK:STDOUT:   %Int.generic: %Int.type = struct_value () [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %Cpp.Exception: type = class_type @Exception [concrete]
// CHECK:STDOUT:   %Cpp.void: type = class_type @VoidBase [concrete]
// CHECK:STDOUT:   %ptr.00a: type = ptr_type %Cpp.void [concrete]
// CHECK:STDOUT:   %Result.900: type = class_type @Result, @Result(%i32, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %.c19: Core.Form = init_form %Result.900 [concrete]
// CHECK:STDOUT:   %pattern_type.5d9: type = pattern_type %Result.900 [concrete]
// CHECK:STDOUT:   %return.param_patt.8a0: %pattern_type.5d9 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.dd6: %pattern_type.5d9 = return_slot_pattern %return.param_patt.8a0, %Result.900 [concrete]
// CHECK:STDOUT:   %M.type: type = fn_type @M [concrete]
// CHECK:STDOUT:   %M.e50: %M.type = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %i32.builtin: type = int_type signed, %int_32 [concrete]
// CHECK:STDOUT:   %tuple.type.a8a: type = tuple_type (%i32) [concrete]
// CHECK:STDOUT:   %tuple.type.b42: type = tuple_type (%Cpp.Exception) [concrete]
// CHECK:STDOUT:   %Result.Ok.type.977: type = fn_type @Result.Ok, @Result(%i32, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %Result.Ok.789: %Result.Ok.type.977 = struct_value () [concrete]
// CHECK:STDOUT:   %Result.Err.type.a4b: type = fn_type @Result.Err, @Result(%i32, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %Result.Err.7cb: %Result.Err.type.a4b = struct_value () [concrete]
// CHECK:STDOUT:   %a.patt: %pattern_type.6b6 = ref_binding_pattern a [concrete]
// CHECK:STDOUT:   %a.var_patt: %pattern_type.6b6 = var_pattern %a.patt [concrete]
// CHECK:STDOUT:   %C.get.cpp_overload_set.type: type = cpp_overload_set_type @C.get.cpp_overload_set [concrete]
// CHECK:STDOUT:   %C.get.cpp_overload_set.value: %C.get.cpp_overload_set.type = cpp_overload_set_value @C.get.cpp_overload_set [concrete]
// CHECK:STDOUT:   %Try.type: type = facet_type <@Try> [concrete]
// CHECK:STDOUT:   %ptr.d08: type = ptr_type %i32 [concrete]
// CHECK:STDOUT:   %ptr.6f9: type = ptr_type %ptr.00a [concrete]
// CHECK:STDOUT:   %get__carbon_catching_thunk.type: type = fn_type @get__carbon_catching_thunk [concrete]
// CHECK:STDOUT:   %get__carbon_catching_thunk: %get__carbon_catching_thunk.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.0ff: type = generic_interface_type @ImplicitAs [concrete]
// CHECK:STDOUT:   %ImplicitAs.generic: %ImplicitAs.type.0ff = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %To.fe9: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.48f: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet.48f [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.6e0: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_0.3c0: %i32 = int_value 0 [concrete]
// CHECK:STDOUT:   %EqWith.type.f77: type = generic_interface_type @EqWith [concrete]
// CHECK:STDOUT:   %EqWith.generic: %EqWith.type.f77 = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.type.8ee: type = facet_type <@EqWith, @EqWith(%i32)> [concrete]
// CHECK:STDOUT:   %M.d23: Core.IntLiteral = symbolic_binding M, 1 [symbolic]
// CHECK:STDOUT:   %Int.as.EqWith.impl.Equal.type.9a2: type = fn_type @Int.as.EqWith.impl.Equal.1, @Int.as.EqWith.impl.e9c(%N, %M.d23) [symbolic]
// CHECK:STDOUT:   %Int.as.EqWith.impl.Equal.792: %Int.as.EqWith.impl.Equal.type.9a2 = struct_value () [symbolic]
// CHECK:STDOUT:   %EqWith.impl_witness.34c: <witness> = impl_witness imports.%EqWith.impl_witness_table.09e, @Int.as.EqWith.impl.e9c(%int_32, %int_32) [concrete]
// CHECK:STDOUT:   %Int.as.EqWith.impl.Equal.type.01c: type = fn_type @Int.as.EqWith.impl.Equal.1, @Int.as.EqWith.impl.e9c(%int_32, %int_32) [concrete]
// CHECK:STDOUT:   %Int.as.EqWith.impl.Equal.34f: %Int.as.EqWith.impl.Equal.type.01c = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.508: %EqWith.type.8ee = facet_value %i32, (%EqWith.impl_witness.34c) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.530: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%i32, %EqWith.facet.508) [concrete]
// CHECK:STDOUT:   %.a79: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.530, %EqWith.facet.508 [concrete]
// CHECK:STDOUT:   %Int.as.EqWith.impl.Equal.specific_fn.12d: <specific function> = specific_function %Int.as.EqWith.impl.Equal.34f, @Int.as.EqWith.impl.Equal.1(%int_32, %int_32) [concrete]
// CHECK:STDOUT:   %Result.Ok.specific_fn: <specific function> = specific_function %Result.Ok.789, @Result.Ok(%i32, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %Result.Err.specific_fn.031: <specific function> = specific_function %Result.Err.7cb, @Result.Err(%i32, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.type.834: type = fn_type @Result.as.Try.impl.FromBreak, @Result.as.Try.impl(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.9cc: %Result.as.Try.impl.FromBreak.type.834 = struct_value () [symbolic]
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.type.d6a: type = fn_type @Result.as.Try.impl.Branch, @Result.as.Try.impl(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.513: %Result.as.Try.impl.Branch.type.d6a = struct_value () [symbolic]
// CHECK:STDOUT:   %Try.impl_witness.d5a: <witness> = impl_witness imports.%Try.impl_witness_table, @Result.as.Try.impl(%i32, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.type.521: type = fn_type @Result.as.Try.impl.Branch, @Result.as.Try.impl(%i32, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.1b9: %Result.as.Try.impl.Branch.type.521 = struct_value () [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.type.b43: type = fn_type @Result.as.Try.impl.FromBreak, @Result.as.Try.impl(%i32, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.c94: %Result.as.Try.impl.FromBreak.type.b43 = struct_value () [concrete]
// CHECK:STDOUT:   %Try.facet.51d: %Try.type = facet_value %Result.900, (%Try.impl_witness.d5a) [concrete]
// CHECK:STDOUT:   %Try.WithSelf.Branch.type.353: type = fn_type @Try.WithSelf.Branch, @Try.WithSelf(%Try.facet.51d) [concrete]
// CHECK:STDOUT:   %Try.WithSelf.FromBreak.type.cf1: type = fn_type @Try.WithSelf.FromBreak, @Try.WithSelf(%Try.facet.51d) [concrete]
// CHECK:STDOUT:   %.8bc: type = fn_type_with_self_type %Try.WithSelf.Branch.type.353, %Try.facet.51d [concrete]
// CHECK:STDOUT:   %ControlFlow.bd1: type = class_type @ControlFlow, @ControlFlow(%i32, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.specific_fn.2e1: <specific function> = specific_function %Result.as.Try.impl.Branch.1b9, @Result.as.Try.impl.Branch(%i32, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %.337: type = custom_layout_type {size=8, align=8, .Continue@0: %tuple.type.a8a, .Break@0: %tuple.type.b42} [concrete]
// CHECK:STDOUT:   %struct_type.discriminant.payload.b51: type = struct_type {.discriminant: %u1, .payload: %.337} [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.ca1: type = facet_type <@ImplicitAs, @ImplicitAs(%u1)> [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.b68(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.170: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.f4c: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.f01, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.46b: %ImplicitAs.type.ca1 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.f4c) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.77c: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%u1, %ImplicitAs.facet.46b) [concrete]
// CHECK:STDOUT:   %.e74: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.77c, %ImplicitAs.facet.46b [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.d7a: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
// CHECK:STDOUT:   %EqWith.type.c25: type = facet_type <@EqWith, @EqWith(%u1)> [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.544: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%N, %M.d23) [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.c67: %UInt.as.EqWith.impl.Equal.type.544 = struct_value () [symbolic]
// CHECK:STDOUT:   %EqWith.impl_witness.7b3: <witness> = impl_witness imports.%EqWith.impl_witness_table.166, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.29b: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.ba4: %UInt.as.EqWith.impl.Equal.type.29b = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.4d0: %EqWith.type.c25 = facet_value %u1, (%EqWith.impl_witness.7b3) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.e3c: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%u1, %EqWith.facet.4d0) [concrete]
// CHECK:STDOUT:   %.9eb: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.e3c, %EqWith.facet.4d0 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.specific_fn.6b6: <specific function> = specific_function %UInt.as.EqWith.impl.Equal.ba4, @UInt.as.EqWith.impl.Equal.1(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.a82: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
// CHECK:STDOUT:   %.cfb: type = fn_type_with_self_type %Try.WithSelf.FromBreak.type.cf1, %Try.facet.51d [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.specific_fn: <specific function> = specific_function %Result.as.Try.impl.FromBreak.c94, @Result.as.Try.impl.FromBreak(%i32, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %Destroy.type: type = facet_type <@Destroy> [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.4: type = fn_type @Destroy.Op.loc23_23.4 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.4: %Destroy.Op.type.1d8f74.4 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.11: type = fn_type @Destroy.Op.loc23_23.11 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.11: %Destroy.Op.type.1d8f74.11 = struct_value () [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet: %Copy.type = facet_value %i32, (%Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.381: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet) [concrete]
// CHECK:STDOUT:   %.737: type = fn_type_with_self_type %Copy.WithSelf.Op.type.381, %Copy.facet [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %b.patt.387: %pattern_type.6b6 = ref_binding_pattern b [concrete]
// CHECK:STDOUT:   %b.var_patt: %pattern_type.6b6 = var_pattern %b.patt.387 [concrete]
// CHECK:STDOUT:   %C.mutate.cpp_overload_set.type: type = cpp_overload_set_type @C.mutate.cpp_overload_set [concrete]
// CHECK:STDOUT:   %C.mutate.cpp_overload_set.value: %C.mutate.cpp_overload_set.type = cpp_overload_set_value @C.mutate.cpp_overload_set [concrete]
// CHECK:STDOUT:   %mutate__carbon_catching_thunk.type: type = fn_type @mutate__carbon_catching_thunk [concrete]
// CHECK:STDOUT:   %mutate__carbon_catching_thunk: %mutate__carbon_catching_thunk.type = struct_value () [concrete]
// CHECK:STDOUT:   %AddWith.type.2ef: type = generic_interface_type @AddWith [concrete]
// CHECK:STDOUT:   %AddWith.generic: %AddWith.type.2ef = struct_value () [concrete]
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
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .Result = %Core.Result.0b3
// CHECK:STDOUT:     .Int = %Core.Int
// CHECK:STDOUT:     .CppCompat = %CppCompat.f0dbf9.1
// CHECK:STDOUT:     .Try = %Core.Try
// CHECK:STDOUT:     .ImplicitAs = %Core.ImplicitAs
// CHECK:STDOUT:     .EqWith = %Core.EqWith
// CHECK:STDOUT:     .Destroy = %Core.Destroy
// CHECK:STDOUT:     .Copy = %Core.Copy
// CHECK:STDOUT:     .AddWith = %Core.AddWith
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Cpp: <namespace> = namespace file.%Cpp.import_cpp, [concrete] {
// CHECK:STDOUT:     .C = %C.decl
// CHECK:STDOUT:     .Exception = constants.%Cpp.Exception
// CHECK:STDOUT:     import Cpp//...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %C.decl: type = class_decl @C [concrete = constants.%C.417] {} {}
// CHECK:STDOUT:   %Core.Result.0b3: %Result.type = import_ref Core//prelude/types/result, Result, loaded [concrete = constants.%Result.generic]
// CHECK:STDOUT:   %Core.import_ref.597: @Result.%Result.Ok.type (%Result.Ok.type.898) = import_ref Core//prelude/types/result, loc{{\d+_\d+}}, loaded [symbolic = @Result.%Result.Ok (constants.%Result.Ok.58a)]
// CHECK:STDOUT:   %Core.import_ref.bfc4: @Result.%Result.Err.type (%Result.Err.type.b75) = import_ref Core//prelude/types/result, loc{{\d+_\d+}}, loaded [symbolic = @Result.%Result.Err (constants.%Result.Err.08c)]
// CHECK:STDOUT:   %Core.Int: %Int.type = import_ref Core//prelude/types/int, Int, loaded [concrete = constants.%Int.generic]
// CHECK:STDOUT:   %Core.CppCompat: <namespace> = import_ref Core//prelude, CppCompat, loaded
// CHECK:STDOUT:   %CppCompat.f0dbf9.1: <namespace> = namespace %Core.CppCompat, [concrete] {
// CHECK:STDOUT:     .Exception = %Core.Exception
// CHECK:STDOUT:     .VoidBase = %Core.VoidBase
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Exception: type = import_ref Core//prelude/types/cpp/exception, Exception, loaded [concrete = constants.%Cpp.Exception]
// CHECK:STDOUT:   %C.get.cpp_overload_set.value: %C.get.cpp_overload_set.type = cpp_overload_set_value @C.get.cpp_overload_set [concrete = constants.%C.get.cpp_overload_set.value]
// CHECK:STDOUT:   %Core.Try: type = import_ref Core//prelude/try, Try, loaded [concrete = constants.%Try.type]
// CHECK:STDOUT:   %Core.VoidBase: type = import_ref Core//prelude/types/cpp/void, VoidBase, loaded [concrete = constants.%Cpp.void]
// CHECK:STDOUT:   %get__carbon_catching_thunk.decl: %get__carbon_catching_thunk.type = fn_decl @get__carbon_catching_thunk [concrete = constants.%get__carbon_catching_thunk] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.ImplicitAs: %ImplicitAs.type.0ff = import_ref Core//prelude/operators/as, ImplicitAs, loaded [concrete = constants.%ImplicitAs.generic]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.EqWith: %EqWith.type.f77 = import_ref Core//prelude/operators/comparison, EqWith, loaded [concrete = constants.%EqWith.generic]
// CHECK:STDOUT:   %Core.import_ref.074: @Int.as.EqWith.impl.e9c.%Int.as.EqWith.impl.Equal.type (%Int.as.EqWith.impl.Equal.type.9a2) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.EqWith.impl.e9c.%Int.as.EqWith.impl.Equal (constants.%Int.as.EqWith.impl.Equal.792)]
// CHECK:STDOUT:   %Core.import_ref.449 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.09e = impl_witness_table (%Core.import_ref.074, %Core.import_ref.449), @Int.as.EqWith.impl.e9c [concrete]
// CHECK:STDOUT:   %Core.import_ref.0b3 = import_ref Core//prelude/types/result, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.6e9 = import_ref Core//prelude/types/result, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9f4: @Result.as.Try.impl.%Result.as.Try.impl.Branch.type (%Result.as.Try.impl.Branch.type.d6a) = import_ref Core//prelude/types/result, loc{{\d+_\d+}}, loaded [symbolic = @Result.as.Try.impl.%Result.as.Try.impl.Branch (constants.%Result.as.Try.impl.Branch.513)]
// CHECK:STDOUT:   %Core.import_ref.6a4: @Result.as.Try.impl.%Result.as.Try.impl.FromBreak.type (%Result.as.Try.impl.FromBreak.type.834) = import_ref Core//prelude/types/result, loc{{\d+_\d+}}, loaded [symbolic = @Result.as.Try.impl.%Result.as.Try.impl.FromBreak (constants.%Result.as.Try.impl.FromBreak.9cc)]
// CHECK:STDOUT:   %Try.impl_witness_table = impl_witness_table (%Core.import_ref.0b3, %Core.import_ref.6e9, %Core.import_ref.9f4, %Core.import_ref.6a4), @Result.as.Try.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.aa5: @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.170)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.f01 = impl_witness_table (%Core.import_ref.aa5), @Core.IntLiteral.as.ImplicitAs.impl.b68 [concrete]
// CHECK:STDOUT:   %Core.import_ref.b92: @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal.type (%UInt.as.EqWith.impl.Equal.type.544) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal (constants.%UInt.as.EqWith.impl.Equal.c67)]
// CHECK:STDOUT:   %Core.import_ref.b44 = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.166 = impl_witness_table (%Core.import_ref.b92, %Core.import_ref.b44), @UInt.as.EqWith.impl.f13 [concrete]
// CHECK:STDOUT:   %Core.Destroy: type = import_ref Core//prelude/destroy, Destroy, loaded [concrete = constants.%Destroy.type]
// CHECK:STDOUT:   %Core.Copy: type = import_ref Core//prelude/copy, Copy, loaded [concrete = constants.%Copy.type]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %C.mutate.cpp_overload_set.value: %C.mutate.cpp_overload_set.type = cpp_overload_set_value @C.mutate.cpp_overload_set [concrete = constants.%C.mutate.cpp_overload_set.value]
// CHECK:STDOUT:   %mutate__carbon_catching_thunk.decl: %mutate__carbon_catching_thunk.type = fn_decl @mutate__carbon_catching_thunk [concrete = constants.%mutate__carbon_catching_thunk] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.AddWith: %AddWith.type.2ef = import_ref Core//prelude/operators/arithmetic, AddWith, loaded [concrete = constants.%AddWith.generic]
// CHECK:STDOUT:   %Core.import_ref.b4fd3a.1 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.684: @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op.type (%Int.as.AddWith.impl.Op.type.610) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op (constants.%Int.as.AddWith.impl.Op.732)]
// CHECK:STDOUT:   %AddWith.impl_witness_table.6b4 = impl_witness_table (%Core.import_ref.b4fd3a.1, %Core.import_ref.684), @Int.as.AddWith.impl.3af [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %M.decl: %M.type = fn_decl @M [concrete = constants.%M.e50] {
// CHECK:STDOUT:     %c.param_patt: %pattern_type.bbc = value_param_pattern [concrete = constants.%c.param_patt]
// CHECK:STDOUT:     %c.patt: %pattern_type.bbc = wrapper_binding_pattern c, %c.param_patt [concrete = constants.%c.patt]
// CHECK:STDOUT:     %p.param_patt: %pattern_type.8fa = value_param_pattern [concrete = constants.%p.param_patt]
// CHECK:STDOUT:     %p.patt: %pattern_type.8fa = wrapper_binding_pattern p, %p.param_patt [concrete = constants.%p.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.5d9 = out_param_pattern [concrete = constants.%return.param_patt.8a0]
// CHECK:STDOUT:     %return.patt: %pattern_type.5d9 = return_slot_pattern %return.param_patt, %Result.loc22 [concrete = constants.%return.patt.dd6]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %Core.ref.loc22: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:     %Result.ref.loc22: %Result.type = name_ref Result, imports.%Core.Result.0b3 [concrete = constants.%Result.generic]
// CHECK:STDOUT:     %i32.loc22: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %Cpp.ref.loc22_47: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:     %Exception.ref.loc22: type = name_ref Exception, constants.%Cpp.Exception [concrete = constants.%Cpp.Exception]
// CHECK:STDOUT:     %Result.loc22: type = class_type @Result, @Result(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.900]
// CHECK:STDOUT:     %.loc22_60.4: Core.Form = init_form %Result.loc22 [concrete = constants.%.c19]
// CHECK:STDOUT:     %c.param: %C.417 = value_param call_param0
// CHECK:STDOUT:     %.loc22_12: type = splice_block %C.ref.loc22_12 [concrete = constants.%C.417] {
// CHECK:STDOUT:       %Cpp.ref.loc22_9: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:       %C.ref.loc22_12: type = name_ref C, imports.%C.decl [concrete = constants.%C.417]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %c: %C.417 = wrapper_binding c, %c.param
// CHECK:STDOUT:     %p.param: %ptr.0a2 = value_param call_param1
// CHECK:STDOUT:     %.loc22_24: type = splice_block %ptr [concrete = constants.%ptr.0a2] {
// CHECK:STDOUT:       %Cpp.ref.loc22_19: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:       %C.ref.loc22_22: type = name_ref C, imports.%C.decl [concrete = constants.%C.417]
// CHECK:STDOUT:       %ptr: type = ptr_type %C.ref.loc22_22 [concrete = constants.%ptr.0a2]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %p: %ptr.0a2 = wrapper_binding p, %p.param
// CHECK:STDOUT:     %return.param: ref %Result.900 = out_param call_param2
// CHECK:STDOUT:     %return: ref %Result.900 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @M(%c.param: %C.417, %p.param: %ptr.0a2) -> out %return.param: %Result.900 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %a.var: ref %i32 = var_storage %a.var_patt
// CHECK:STDOUT:   %c.ref: %C.417 = name_ref c, %c
// CHECK:STDOUT:   %get.ref: %C.get.cpp_overload_set.type = name_ref get, imports.%C.get.cpp_overload_set.value [concrete = constants.%C.get.cpp_overload_set.value]
// CHECK:STDOUT:   %bound_method.loc23_17: <bound method> = bound_method %c.ref, %get.ref
// CHECK:STDOUT:   %Result.loc23: type = class_type @Result, @Result(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.900]
// CHECK:STDOUT:   %.loc23_22.1: ref %i32 = temporary_storage
// CHECK:STDOUT:   %addr.loc23_22.1: %ptr.d08 = addr_of %.loc23_22.1
// CHECK:STDOUT:   %.loc23_22.2: ref %ptr.00a = temporary_storage
// CHECK:STDOUT:   %addr.loc23_22.2: %ptr.6f9 = addr_of %.loc23_22.2
// CHECK:STDOUT:   %get__carbon_catching_thunk.call: init %i32 = call imports.%get__carbon_catching_thunk.decl(%c.ref, %addr.loc23_22.1, %addr.loc23_22.2)
// CHECK:STDOUT:   %int_0.loc23: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc23_22.1: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc23_22.1: <bound method> = bound_method %int_0.loc23, %impl.elem0.loc23_22.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc23_22.1: <specific function> = specific_function %impl.elem0.loc23_22.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc23_22.2: <bound method> = bound_method %int_0.loc23, %specific_fn.loc23_22.1 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc23_22: init %i32 = call %bound_method.loc23_22.2(%int_0.loc23) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc23_22.3: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc23_22 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc23_22.4: %i32 = converted %int_0.loc23, %.loc23_22.3 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %impl.elem0.loc23_22.2: %.a79 = impl_witness_access constants.%EqWith.impl_witness.34c, element0 [concrete = constants.%Int.as.EqWith.impl.Equal.34f]
// CHECK:STDOUT:   %bound_method.loc23_22.3: <bound method> = bound_method %get__carbon_catching_thunk.call, %impl.elem0.loc23_22.2
// CHECK:STDOUT:   %specific_fn.loc23_22.2: <specific function> = specific_function %impl.elem0.loc23_22.2, @Int.as.EqWith.impl.Equal.1(constants.%int_32, constants.%int_32) [concrete = constants.%Int.as.EqWith.impl.Equal.specific_fn.12d]
// CHECK:STDOUT:   %bound_method.loc23_22.4: <bound method> = bound_method %get__carbon_catching_thunk.call, %specific_fn.loc23_22.2
// CHECK:STDOUT:   %.loc23_22.5: %i32 = value_of_initializer %get__carbon_catching_thunk.call
// CHECK:STDOUT:   %.loc23_22.6: %i32 = converted %get__carbon_catching_thunk.call, %.loc23_22.5
// CHECK:STDOUT:   %Int.as.EqWith.impl.Equal.call.loc23: init bool = call %bound_method.loc23_22.4(%.loc23_22.6, %.loc23_22.4)
// CHECK:STDOUT:   %.loc23_22.7: bool = value_of_initializer %Int.as.EqWith.impl.Equal.call.loc23
// CHECK:STDOUT:   %.loc23_22.8: bool = converted %Int.as.EqWith.impl.Equal.call.loc23, %.loc23_22.7
// CHECK:STDOUT:   %.loc23_22.9: ref %Result.900 = temporary_storage
// CHECK:STDOUT:   if %.loc23_22.8 br !.loc23_22.1 else br !.loc23_22.2
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc23_22.1:
// CHECK:STDOUT:   %.loc23_22.10: %i32 = acquire_value %.loc23_22.1
// CHECK:STDOUT:   %.loc23_22.11: %Result.Ok.type.977 = specific_constant imports.%Core.import_ref.597, @Result(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.Ok.789]
// CHECK:STDOUT:   %Ok.ref.loc23: %Result.Ok.type.977 = name_ref Ok, %.loc23_22.11 [concrete = constants.%Result.Ok.789]
// CHECK:STDOUT:   %Result.Ok.specific_fn.loc23: <specific function> = specific_function %Ok.ref.loc23, @Result.Ok(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.Ok.specific_fn]
// CHECK:STDOUT:   %.loc23_22.12: ref %Result.900 = splice_block %.loc23_22.9 {}
// CHECK:STDOUT:   %Result.Ok.call.loc23: init %Result.900 to %.loc23_22.12 = call %Result.Ok.specific_fn.loc23(%.loc23_22.10)
// CHECK:STDOUT:   assign %.loc23_22.9, %Result.Ok.call.loc23
// CHECK:STDOUT:   br !.loc23_22.3
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc23_22.2:
// CHECK:STDOUT:   %.loc23_22.13: %ptr.00a = acquire_value %.loc23_22.2
// CHECK:STDOUT:   %.loc23_22.14: %Cpp.Exception = as_compatible %.loc23_22.13
// CHECK:STDOUT:   %.loc23_22.15: %Cpp.Exception = converted %.loc23_22.13, %.loc23_22.14
// CHECK:STDOUT:   %.loc23_22.16: %Result.Err.type.a4b = specific_constant imports.%Core.import_ref.bfc4, @Result(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.Err.7cb]
// CHECK:STDOUT:   %Err.ref.loc23: %Result.Err.type.a4b = name_ref Err, %.loc23_22.16 [concrete = constants.%Result.Err.7cb]
// CHECK:STDOUT:   %Result.Err.specific_fn.loc23: <specific function> = specific_function %Err.ref.loc23, @Result.Err(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.Err.specific_fn.031]
// CHECK:STDOUT:   %.loc23_22.17: ref %Result.900 = splice_block %.loc23_22.9 {}
// CHECK:STDOUT:   %Result.Err.call.loc23: init %Result.900 to %.loc23_22.17 = call %Result.Err.specific_fn.loc23(%.loc23_22.15)
// CHECK:STDOUT:   assign %.loc23_22.9, %Result.Err.call.loc23
// CHECK:STDOUT:   br !.loc23_22.3
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc23_22.3:
// CHECK:STDOUT:   %.loc23_22.18: %Result.900 = acquire_value %.loc23_22.9
// CHECK:STDOUT:   %impl.elem2.loc23: %.8bc = impl_witness_access constants.%Try.impl_witness.d5a, element2 [concrete = constants.%Result.as.Try.impl.Branch.1b9]
// CHECK:STDOUT:   %bound_method.loc23_23.1: <bound method> = bound_method %.loc23_22.18, %impl.elem2.loc23
// CHECK:STDOUT:   %specific_fn.loc23_23.1: <specific function> = specific_function %impl.elem2.loc23, @Result.as.Try.impl.Branch(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.as.Try.impl.Branch.specific_fn.2e1]
// CHECK:STDOUT:   %bound_method.loc23_23.2: <bound method> = bound_method %.loc23_22.18, %specific_fn.loc23_23.1
// CHECK:STDOUT:   %.loc23_23.1: ref %ControlFlow.bd1 = temporary_storage
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.call.loc23: init %ControlFlow.bd1 to %.loc23_23.1 = call %bound_method.loc23_23.2(%.loc23_22.18)
// CHECK:STDOUT:   %.loc23_23.2: ref %ControlFlow.bd1 = temporary %.loc23_23.1, %Result.as.Try.impl.Branch.call.loc23
// CHECK:STDOUT:   %int_1.loc23: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc23_23.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc23_23.3: <bound method> = bound_method %int_1.loc23, %impl.elem0.loc23_23.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc23_23.2: <specific function> = specific_function %impl.elem0.loc23_23.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc23_23.4: <bound method> = bound_method %int_1.loc23, %specific_fn.loc23_23.2 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc23_23: init %u1 = call %bound_method.loc23_23.4(%int_1.loc23) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc23_23.3: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc23_23 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc23_23.4: %u1 = converted %int_1.loc23, %.loc23_23.3 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc23_23.5: ref %u1 = class_element_access %.loc23_23.2, element0
// CHECK:STDOUT:   %impl.elem0.loc23_23.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc23_23.5: <bound method> = bound_method %.loc23_23.4, %impl.elem0.loc23_23.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound]
// CHECK:STDOUT:   %specific_fn.loc23_23.3: <specific function> = specific_function %impl.elem0.loc23_23.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc23_23.6: <bound method> = bound_method %.loc23_23.4, %specific_fn.loc23_23.3 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc23_23.6: %u1 = acquire_value %.loc23_23.5
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc23: init bool = call %bound_method.loc23_23.6(%.loc23_23.4, %.loc23_23.6)
// CHECK:STDOUT:   %.loc23_23.7: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc23
// CHECK:STDOUT:   %.loc23_23.8: bool = converted %UInt.as.EqWith.impl.Equal.call.loc23, %.loc23_23.7
// CHECK:STDOUT:   if %.loc23_23.8 br !.loc23_23.1 else br !.loc23_23.2
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc23_23.1:
// CHECK:STDOUT:   %.loc23_23.9: ref %.337 = class_element_access %.loc23_23.2, element1
// CHECK:STDOUT:   %.loc23_23.10: ref %tuple.type.b42 = class_element_access %.loc23_23.9, element1
// CHECK:STDOUT:   %tuple.elem0.loc23_23.1: ref %Cpp.Exception = tuple_access %.loc23_23.10, element0
// CHECK:STDOUT:   %.loc23_23.11: %Cpp.Exception = acquire_value %tuple.elem0.loc23_23.1
// CHECK:STDOUT:   %Try.facet.loc23: %Try.type = facet_value constants.%Result.900, (constants.%Try.impl_witness.d5a) [concrete = constants.%Try.facet.51d]
// CHECK:STDOUT:   %.loc23_23.12: %Try.type = converted constants.%Result.900, %Try.facet.loc23 [concrete = constants.%Try.facet.51d]
// CHECK:STDOUT:   %impl.elem3.loc23: %.cfb = impl_witness_access constants.%Try.impl_witness.d5a, element3 [concrete = constants.%Result.as.Try.impl.FromBreak.c94]
// CHECK:STDOUT:   %specific_fn.loc23_23.4: <specific function> = specific_function %impl.elem3.loc23, @Result.as.Try.impl.FromBreak(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.as.Try.impl.FromBreak.specific_fn]
// CHECK:STDOUT:   %.loc22_60.1: ref %Result.900 = splice_block %return.param {}
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.call.loc23: init %Result.900 to %.loc22_60.1 = call %specific_fn.loc23_23.4(%.loc23_23.11)
// CHECK:STDOUT:   %Destroy.Op.bound.loc23_23.1: <bound method> = bound_method %.loc23_23.2, constants.%Destroy.Op.1a2547.11
// CHECK:STDOUT:   %Destroy.Op.call.loc23_23.1: init %empty_tuple.type = call %Destroy.Op.bound.loc23_23.1(%.loc23_23.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc23_3.1: <bound method> = bound_method %a.var, constants.%Destroy.Op.1a2547.4
// CHECK:STDOUT:   %Destroy.Op.call.loc23_3.1: init %empty_tuple.type = call %Destroy.Op.bound.loc23_3.1(%a.var)
// CHECK:STDOUT:   return %Result.as.Try.impl.FromBreak.call.loc23 to %return.param
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc23_23.2:
// CHECK:STDOUT:   %.loc23_23.13: ref %.337 = class_element_access %.loc23_23.2, element1
// CHECK:STDOUT:   %.loc23_23.14: ref %tuple.type.a8a = class_element_access %.loc23_23.13, element0
// CHECK:STDOUT:   %tuple.elem0.loc23_23.2: ref %i32 = tuple_access %.loc23_23.14, element0
// CHECK:STDOUT:   %.loc23_23.15: %i32 = acquire_value %tuple.elem0.loc23_23.2
// CHECK:STDOUT:   %impl.elem0.loc23_23.3: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc23_23.7: <bound method> = bound_method %.loc23_23.15, %impl.elem0.loc23_23.3
// CHECK:STDOUT:   %specific_fn.loc23_23.5: <specific function> = specific_function %impl.elem0.loc23_23.3, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc23_23.8: <bound method> = bound_method %.loc23_23.15, %specific_fn.loc23_23.5
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call.loc23: init %i32 = call %bound_method.loc23_23.8(%.loc23_23.15)
// CHECK:STDOUT:   assign %a.var, %Int.as.Copy.impl.Op.call.loc23
// CHECK:STDOUT:   %i32.loc23: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %a: ref %i32 = wrapper_binding a, %a.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %a.patt: %pattern_type.6b6 = ref_binding_pattern a [concrete = constants.%a.patt]
// CHECK:STDOUT:     %a.var_patt: %pattern_type.6b6 = var_pattern %a.patt [concrete = constants.%a.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %b.var: ref %i32 = var_storage %b.var_patt
// CHECK:STDOUT:   %p.ref: %ptr.0a2 = name_ref p, %p
// CHECK:STDOUT:   %.loc24_17: ref %C.417 = deref %p.ref
// CHECK:STDOUT:   %mutate.ref: %C.mutate.cpp_overload_set.type = name_ref mutate, imports.%C.mutate.cpp_overload_set.value [concrete = constants.%C.mutate.cpp_overload_set.value]
// CHECK:STDOUT:   %bound_method.loc24_17: <bound method> = bound_method %.loc24_17, %mutate.ref
// CHECK:STDOUT:   %Result.loc24: type = class_type @Result, @Result(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.900]
// CHECK:STDOUT:   %.loc24_26.1: ref %i32 = temporary_storage
// CHECK:STDOUT:   %addr.loc24_26.1: %ptr.d08 = addr_of %.loc24_26.1
// CHECK:STDOUT:   %.loc24_26.2: ref %ptr.00a = temporary_storage
// CHECK:STDOUT:   %addr.loc24_26.2: %ptr.6f9 = addr_of %.loc24_26.2
// CHECK:STDOUT:   %mutate__carbon_catching_thunk.call: init %i32 = call imports.%mutate__carbon_catching_thunk.decl(%.loc24_17, %addr.loc24_26.1, %addr.loc24_26.2)
// CHECK:STDOUT:   %int_0.loc24: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc24_26.1: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc24_26.1: <bound method> = bound_method %int_0.loc24, %impl.elem0.loc24_26.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc24_26.1: <specific function> = specific_function %impl.elem0.loc24_26.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc24_26.2: <bound method> = bound_method %int_0.loc24, %specific_fn.loc24_26.1 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc24_26: init %i32 = call %bound_method.loc24_26.2(%int_0.loc24) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc24_26.3: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc24_26 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc24_26.4: %i32 = converted %int_0.loc24, %.loc24_26.3 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %impl.elem0.loc24_26.2: %.a79 = impl_witness_access constants.%EqWith.impl_witness.34c, element0 [concrete = constants.%Int.as.EqWith.impl.Equal.34f]
// CHECK:STDOUT:   %bound_method.loc24_26.3: <bound method> = bound_method %mutate__carbon_catching_thunk.call, %impl.elem0.loc24_26.2
// CHECK:STDOUT:   %specific_fn.loc24_26.2: <specific function> = specific_function %impl.elem0.loc24_26.2, @Int.as.EqWith.impl.Equal.1(constants.%int_32, constants.%int_32) [concrete = constants.%Int.as.EqWith.impl.Equal.specific_fn.12d]
// CHECK:STDOUT:   %bound_method.loc24_26.4: <bound method> = bound_method %mutate__carbon_catching_thunk.call, %specific_fn.loc24_26.2
// CHECK:STDOUT:   %.loc24_26.5: %i32 = value_of_initializer %mutate__carbon_catching_thunk.call
// CHECK:STDOUT:   %.loc24_26.6: %i32 = converted %mutate__carbon_catching_thunk.call, %.loc24_26.5
// CHECK:STDOUT:   %Int.as.EqWith.impl.Equal.call.loc24: init bool = call %bound_method.loc24_26.4(%.loc24_26.6, %.loc24_26.4)
// CHECK:STDOUT:   %.loc24_26.7: bool = value_of_initializer %Int.as.EqWith.impl.Equal.call.loc24
// CHECK:STDOUT:   %.loc24_26.8: bool = converted %Int.as.EqWith.impl.Equal.call.loc24, %.loc24_26.7
// CHECK:STDOUT:   %.loc24_26.9: ref %Result.900 = temporary_storage
// CHECK:STDOUT:   if %.loc24_26.8 br !.loc24_26.1 else br !.loc24_26.2
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc24_26.1:
// CHECK:STDOUT:   %.loc24_26.10: %i32 = acquire_value %.loc24_26.1
// CHECK:STDOUT:   %.loc24_26.11: %Result.Ok.type.977 = specific_constant imports.%Core.import_ref.597, @Result(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.Ok.789]
// CHECK:STDOUT:   %Ok.ref.loc24: %Result.Ok.type.977 = name_ref Ok, %.loc24_26.11 [concrete = constants.%Result.Ok.789]
// CHECK:STDOUT:   %Result.Ok.specific_fn.loc24: <specific function> = specific_function %Ok.ref.loc24, @Result.Ok(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.Ok.specific_fn]
// CHECK:STDOUT:   %.loc24_26.12: ref %Result.900 = splice_block %.loc24_26.9 {}
// CHECK:STDOUT:   %Result.Ok.call.loc24: init %Result.900 to %.loc24_26.12 = call %Result.Ok.specific_fn.loc24(%.loc24_26.10)
// CHECK:STDOUT:   assign %.loc24_26.9, %Result.Ok.call.loc24
// CHECK:STDOUT:   br !.loc24_26.3
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc24_26.2:
// CHECK:STDOUT:   %.loc24_26.13: %ptr.00a = acquire_value %.loc24_26.2
// CHECK:STDOUT:   %.loc24_26.14: %Cpp.Exception = as_compatible %.loc24_26.13
// CHECK:STDOUT:   %.loc24_26.15: %Cpp.Exception = converted %.loc24_26.13, %.loc24_26.14
// CHECK:STDOUT:   %.loc24_26.16: %Result.Err.type.a4b = specific_constant imports.%Core.import_ref.bfc4, @Result(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.Err.7cb]
// CHECK:STDOUT:   %Err.ref.loc24: %Result.Err.type.a4b = name_ref Err, %.loc24_26.16 [concrete = constants.%Result.Err.7cb]
// CHECK:STDOUT:   %Result.Err.specific_fn.loc24: <specific function> = specific_function %Err.ref.loc24, @Result.Err(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.Err.specific_fn.031]
// CHECK:STDOUT:   %.loc24_26.17: ref %Result.900 = splice_block %.loc24_26.9 {}
// CHECK:STDOUT:   %Result.Err.call.loc24: init %Result.900 to %.loc24_26.17 = call %Result.Err.specific_fn.loc24(%.loc24_26.15)
// CHECK:STDOUT:   assign %.loc24_26.9, %Result.Err.call.loc24
// CHECK:STDOUT:   br !.loc24_26.3
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc24_26.3:
// CHECK:STDOUT:   %.loc24_26.18: %Result.900 = acquire_value %.loc24_26.9
// CHECK:STDOUT:   %impl.elem2.loc24: %.8bc = impl_witness_access constants.%Try.impl_witness.d5a, element2 [concrete = constants.%Result.as.Try.impl.Branch.1b9]
// CHECK:STDOUT:   %bound_method.loc24_27.1: <bound method> = bound_method %.loc24_26.18, %impl.elem2.loc24
// CHECK:STDOUT:   %specific_fn.loc24_27.1: <specific function> = specific_function %impl.elem2.loc24, @Result.as.Try.impl.Branch(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.as.Try.impl.Branch.specific_fn.2e1]
// CHECK:STDOUT:   %bound_method.loc24_27.2: <bound method> = bound_method %.loc24_26.18, %specific_fn.loc24_27.1
// CHECK:STDOUT:   %.loc24_27.1: ref %ControlFlow.bd1 = temporary_storage
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.call.loc24: init %ControlFlow.bd1 to %.loc24_27.1 = call %bound_method.loc24_27.2(%.loc24_26.18)
// CHECK:STDOUT:   %.loc24_27.2: ref %ControlFlow.bd1 = temporary %.loc24_27.1, %Result.as.Try.impl.Branch.call.loc24
// CHECK:STDOUT:   %int_1.loc24: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc24_27.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc24_27.3: <bound method> = bound_method %int_1.loc24, %impl.elem0.loc24_27.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc24_27.2: <specific function> = specific_function %impl.elem0.loc24_27.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc24_27.4: <bound method> = bound_method %int_1.loc24, %specific_fn.loc24_27.2 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc24_27: init %u1 = call %bound_method.loc24_27.4(%int_1.loc24) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc24_27.3: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc24_27 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc24_27.4: %u1 = converted %int_1.loc24, %.loc24_27.3 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc24_27.5: ref %u1 = class_element_access %.loc24_27.2, element0
// CHECK:STDOUT:   %impl.elem0.loc24_27.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc24_27.5: <bound method> = bound_method %.loc24_27.4, %impl.elem0.loc24_27.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound]
// CHECK:STDOUT:   %specific_fn.loc24_27.3: <specific function> = specific_function %impl.elem0.loc24_27.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc24_27.6: <bound method> = bound_method %.loc24_27.4, %specific_fn.loc24_27.3 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc24_27.6: %u1 = acquire_value %.loc24_27.5
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc24: init bool = call %bound_method.loc24_27.6(%.loc24_27.4, %.loc24_27.6)
// CHECK:STDOUT:   %.loc24_27.7: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc24
// CHECK:STDOUT:   %.loc24_27.8: bool = converted %UInt.as.EqWith.impl.Equal.call.loc24, %.loc24_27.7
// CHECK:STDOUT:   if %.loc24_27.8 br !.loc24_27.1 else br !.loc24_27.2
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc24_27.1:
// CHECK:STDOUT:   %.loc24_27.9: ref %.337 = class_element_access %.loc24_27.2, element1
// CHECK:STDOUT:   %.loc24_27.10: ref %tuple.type.b42 = class_element_access %.loc24_27.9, element1
// CHECK:STDOUT:   %tuple.elem0.loc24_27.1: ref %Cpp.Exception = tuple_access %.loc24_27.10, element0
// CHECK:STDOUT:   %.loc24_27.11: %Cpp.Exception = acquire_value %tuple.elem0.loc24_27.1
// CHECK:STDOUT:   %Try.facet.loc24: %Try.type = facet_value constants.%Result.900, (constants.%Try.impl_witness.d5a) [concrete = constants.%Try.facet.51d]
// CHECK:STDOUT:   %.loc24_27.12: %Try.type = converted constants.%Result.900, %Try.facet.loc24 [concrete = constants.%Try.facet.51d]
// CHECK:STDOUT:   %impl.elem3.loc24: %.cfb = impl_witness_access constants.%Try.impl_witness.d5a, element3 [concrete = constants.%Result.as.Try.impl.FromBreak.c94]
// CHECK:STDOUT:   %specific_fn.loc24_27.4: <specific function> = specific_function %impl.elem3.loc24, @Result.as.Try.impl.FromBreak(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.as.Try.impl.FromBreak.specific_fn]
// CHECK:STDOUT:   %.loc22_60.2: ref %Result.900 = splice_block %return.param {}
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.call.loc24: init %Result.900 to %.loc22_60.2 = call %specific_fn.loc24_27.4(%.loc24_27.11)
// CHECK:STDOUT:   %Destroy.Op.bound.loc24_27.1: <bound method> = bound_method %.loc24_27.2, constants.%Destroy.Op.1a2547.11
// CHECK:STDOUT:   %Destroy.Op.call.loc24_27.1: init %empty_tuple.type = call %Destroy.Op.bound.loc24_27.1(%.loc24_27.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc24_3.1: <bound method> = bound_method %b.var, constants.%Destroy.Op.1a2547.4
// CHECK:STDOUT:   %Destroy.Op.call.loc24_3.1: init %empty_tuple.type = call %Destroy.Op.bound.loc24_3.1(%b.var)
// CHECK:STDOUT:   %Destroy.Op.bound.loc23_23.2: <bound method> = bound_method %.loc23_23.2, constants.%Destroy.Op.1a2547.11
// CHECK:STDOUT:   %Destroy.Op.call.loc23_23.2: init %empty_tuple.type = call %Destroy.Op.bound.loc23_23.2(%.loc23_23.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc23_3.2: <bound method> = bound_method %a.var, constants.%Destroy.Op.1a2547.4
// CHECK:STDOUT:   %Destroy.Op.call.loc23_3.2: init %empty_tuple.type = call %Destroy.Op.bound.loc23_3.2(%a.var)
// CHECK:STDOUT:   return %Result.as.Try.impl.FromBreak.call.loc24 to %return.param
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc24_27.2:
// CHECK:STDOUT:   %.loc24_27.13: ref %.337 = class_element_access %.loc24_27.2, element1
// CHECK:STDOUT:   %.loc24_27.14: ref %tuple.type.a8a = class_element_access %.loc24_27.13, element0
// CHECK:STDOUT:   %tuple.elem0.loc24_27.2: ref %i32 = tuple_access %.loc24_27.14, element0
// CHECK:STDOUT:   %.loc24_27.15: %i32 = acquire_value %tuple.elem0.loc24_27.2
// CHECK:STDOUT:   %impl.elem0.loc24_27.3: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc24_27.7: <bound method> = bound_method %.loc24_27.15, %impl.elem0.loc24_27.3
// CHECK:STDOUT:   %specific_fn.loc24_27.5: <specific function> = specific_function %impl.elem0.loc24_27.3, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc24_27.8: <bound method> = bound_method %.loc24_27.15, %specific_fn.loc24_27.5
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call.loc24: init %i32 = call %bound_method.loc24_27.8(%.loc24_27.15)
// CHECK:STDOUT:   assign %b.var, %Int.as.Copy.impl.Op.call.loc24
// CHECK:STDOUT:   %i32.loc24: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %b: ref %i32 = wrapper_binding b, %b.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %b.patt: %pattern_type.6b6 = ref_binding_pattern b [concrete = constants.%b.patt.387]
// CHECK:STDOUT:     %b.var_patt: %pattern_type.6b6 = var_pattern %b.patt [concrete = constants.%b.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.ref.loc25: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:   %Result.ref.loc25: %Result.type = name_ref Result, imports.%Core.Result.0b3 [concrete = constants.%Result.generic]
// CHECK:STDOUT:   %i32.loc25: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %Cpp.ref.loc25: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:   %Exception.ref.loc25: type = name_ref Exception, constants.%Cpp.Exception [concrete = constants.%Cpp.Exception]
// CHECK:STDOUT:   %Result.loc25: type = class_type @Result, @Result(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.900]
// CHECK:STDOUT:   %.loc25_41: %Result.Ok.type.977 = specific_constant imports.%Core.import_ref.597, @Result(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.Ok.789]
// CHECK:STDOUT:   %Ok.ref.loc25: %Result.Ok.type.977 = name_ref Ok, %.loc25_41 [concrete = constants.%Result.Ok.789]
// CHECK:STDOUT:   %a.ref: ref %i32 = name_ref a, %a
// CHECK:STDOUT:   %b.ref: ref %i32 = name_ref b, %b
// CHECK:STDOUT:   %impl.elem1: %.d47 = impl_witness_access constants.%AddWith.impl_witness.833, element1 [concrete = constants.%Int.as.AddWith.impl.Op.365]
// CHECK:STDOUT:   %bound_method.loc25_47.1: <bound method> = bound_method %a.ref, %impl.elem1
// CHECK:STDOUT:   %specific_fn.loc25: <specific function> = specific_function %impl.elem1, @Int.as.AddWith.impl.Op.1(constants.%int_32) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.f25]
// CHECK:STDOUT:   %bound_method.loc25_47.2: <bound method> = bound_method %a.ref, %specific_fn.loc25
// CHECK:STDOUT:   %.loc25_45: %i32 = acquire_value %a.ref
// CHECK:STDOUT:   %.loc25_49: %i32 = acquire_value %b.ref
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call: init %i32 = call %bound_method.loc25_47.2(%.loc25_45, %.loc25_49)
// CHECK:STDOUT:   %Result.Ok.specific_fn.loc25: <specific function> = specific_function %Ok.ref.loc25, @Result.Ok(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.Ok.specific_fn]
// CHECK:STDOUT:   %.loc22_60.3: ref %Result.900 = splice_block %return.param {}
// CHECK:STDOUT:   %.loc25_47.1: %i32 = value_of_initializer %Int.as.AddWith.impl.Op.call
// CHECK:STDOUT:   %.loc25_47.2: %i32 = converted %Int.as.AddWith.impl.Op.call, %.loc25_47.1
// CHECK:STDOUT:   %Result.Ok.call.loc25: init %Result.900 to %.loc22_60.3 = call %Result.Ok.specific_fn.loc25(%.loc25_47.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc24_27.2: <bound method> = bound_method %.loc24_27.2, constants.%Destroy.Op.1a2547.11
// CHECK:STDOUT:   %Destroy.Op.call.loc24_27.2: init %empty_tuple.type = call %Destroy.Op.bound.loc24_27.2(%.loc24_27.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc24_3.2: <bound method> = bound_method %b.var, constants.%Destroy.Op.1a2547.4
// CHECK:STDOUT:   %Destroy.Op.call.loc24_3.2: init %empty_tuple.type = call %Destroy.Op.bound.loc24_3.2(%b.var)
// CHECK:STDOUT:   %Destroy.Op.bound.loc23_23.3: <bound method> = bound_method %.loc23_23.2, constants.%Destroy.Op.1a2547.11
// CHECK:STDOUT:   %Destroy.Op.call.loc23_23.3: init %empty_tuple.type = call %Destroy.Op.bound.loc23_23.3(%.loc23_23.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc23_3.3: <bound method> = bound_method %a.var, constants.%Destroy.Op.1a2547.4
// CHECK:STDOUT:   %Destroy.Op.call.loc23_3.3: init %empty_tuple.type = call %Destroy.Op.bound.loc23_3.3(%a.var)
// CHECK:STDOUT:   return %Result.Ok.call.loc25 to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc23_23.1(%self.param: ref %u1.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc23_23.2(%self.param: ref %u1) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc23_23.3(%self.param: ref %i32.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc23_23.4(%self.param: ref %i32) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc23_23.5(%self.param: ref %tuple.type.a8a) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc23_23.6(%self.param: ref %ptr.00a) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc23_23.7(%self.param: ref %Cpp.Exception) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc23_23.8(%self.param: ref %tuple.type.b42) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc23_23.9(%self.param: ref %.337) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc23_23.10(%self.param: ref %struct_type.discriminant.payload.b51) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc23_23.11(%self.param: ref %ControlFlow.bd1) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- reserved_name.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %Result.type: type = generic_class_type @Result [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %Result.generic: %Result.type = struct_value () [concrete]
// CHECK:STDOUT:   %E: type = symbolic_binding E, 1 [symbolic]
// CHECK:STDOUT:   %T.67d: type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %u1: type = class_type @UInt, @UInt(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %u1.builtin: type = int_type unsigned, %int_1.5b8 [concrete]
// CHECK:STDOUT:   %Result.Err.type.b75: type = fn_type @Result.Err, @Result(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %Result.Err.08c: %Result.Err.type.b75 = struct_value () [symbolic]
// CHECK:STDOUT:   %Result.Ok.type.898: type = fn_type @Result.Ok, @Result(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %Result.Ok.58a: %Result.Ok.type.898 = struct_value () [symbolic]
// CHECK:STDOUT:   %int_1.233: %u1 = int_value 1 [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %Int.type: type = generic_class_type @Int [concrete]
// CHECK:STDOUT:   %Int.generic: %Int.type = struct_value () [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %Cpp.Exception: type = class_type @Exception [concrete]
// CHECK:STDOUT:   %Cpp.void: type = class_type @VoidBase [concrete]
// CHECK:STDOUT:   %ptr.00a: type = ptr_type %Cpp.void [concrete]
// CHECK:STDOUT:   %Result.900: type = class_type @Result, @Result(%i32, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %.c19: Core.Form = init_form %Result.900 [concrete]
// CHECK:STDOUT:   %pattern_type.5d9: type = pattern_type %Result.900 [concrete]
// CHECK:STDOUT:   %return.param_patt.8a0: %pattern_type.5d9 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.dd6: %pattern_type.5d9 = return_slot_pattern %return.param_patt.8a0, %Result.900 [concrete]
// CHECK:STDOUT:   %R.type: type = fn_type @R [concrete]
// CHECK:STDOUT:   %R: %R.type = struct_value () [concrete]
// CHECK:STDOUT:   %i32.builtin: type = int_type signed, %int_32 [concrete]
// CHECK:STDOUT:   %tuple.type.a8a: type = tuple_type (%i32) [concrete]
// CHECK:STDOUT:   %tuple.type.b42: type = tuple_type (%Cpp.Exception) [concrete]
// CHECK:STDOUT:   %Result.Ok.type.977: type = fn_type @Result.Ok, @Result(%i32, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %Result.Ok.789: %Result.Ok.type.977 = struct_value () [concrete]
// CHECK:STDOUT:   %Result.Err.type.a4b: type = fn_type @Result.Err, @Result(%i32, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %Result.Err.7cb: %Result.Err.type.a4b = struct_value () [concrete]
// CHECK:STDOUT:   %may_throw_int.cpp_overload_set.type: type = cpp_overload_set_type @may_throw_int.cpp_overload_set [concrete]
// CHECK:STDOUT:   %may_throw_int.cpp_overload_set.value: %may_throw_int.cpp_overload_set.type = cpp_overload_set_value @may_throw_int.cpp_overload_set [concrete]
// CHECK:STDOUT:   %Try.type: type = facet_type <@Try> [concrete]
// CHECK:STDOUT:   %ptr.d08: type = ptr_type %i32 [concrete]
// CHECK:STDOUT:   %ptr.6f9: type = ptr_type %ptr.00a [concrete]
// CHECK:STDOUT:   %may_throw_int__carbon_catching_thunk.type: type = fn_type @may_throw_int__carbon_catching_thunk [concrete]
// CHECK:STDOUT:   %may_throw_int__carbon_catching_thunk: %may_throw_int__carbon_catching_thunk.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.0ff: type = generic_interface_type @ImplicitAs [concrete]
// CHECK:STDOUT:   %ImplicitAs.generic: %ImplicitAs.type.0ff = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %To.fe9: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.48f: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet.48f [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.6e0: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_0.3c0: %i32 = int_value 0 [concrete]
// CHECK:STDOUT:   %EqWith.type.f77: type = generic_interface_type @EqWith [concrete]
// CHECK:STDOUT:   %EqWith.generic: %EqWith.type.f77 = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.type.8ee: type = facet_type <@EqWith, @EqWith(%i32)> [concrete]
// CHECK:STDOUT:   %M: Core.IntLiteral = symbolic_binding M, 1 [symbolic]
// CHECK:STDOUT:   %Int.as.EqWith.impl.Equal.type.9a2: type = fn_type @Int.as.EqWith.impl.Equal.1, @Int.as.EqWith.impl.e9c(%N, %M) [symbolic]
// CHECK:STDOUT:   %Int.as.EqWith.impl.Equal.792: %Int.as.EqWith.impl.Equal.type.9a2 = struct_value () [symbolic]
// CHECK:STDOUT:   %EqWith.impl_witness.34c: <witness> = impl_witness imports.%EqWith.impl_witness_table.09e, @Int.as.EqWith.impl.e9c(%int_32, %int_32) [concrete]
// CHECK:STDOUT:   %Int.as.EqWith.impl.Equal.type.01c: type = fn_type @Int.as.EqWith.impl.Equal.1, @Int.as.EqWith.impl.e9c(%int_32, %int_32) [concrete]
// CHECK:STDOUT:   %Int.as.EqWith.impl.Equal.34f: %Int.as.EqWith.impl.Equal.type.01c = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.508: %EqWith.type.8ee = facet_value %i32, (%EqWith.impl_witness.34c) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.530: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%i32, %EqWith.facet.508) [concrete]
// CHECK:STDOUT:   %.a79: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.530, %EqWith.facet.508 [concrete]
// CHECK:STDOUT:   %Int.as.EqWith.impl.Equal.specific_fn.12d: <specific function> = specific_function %Int.as.EqWith.impl.Equal.34f, @Int.as.EqWith.impl.Equal.1(%int_32, %int_32) [concrete]
// CHECK:STDOUT:   %Result.Ok.specific_fn: <specific function> = specific_function %Result.Ok.789, @Result.Ok(%i32, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %Result.Err.specific_fn.031: <specific function> = specific_function %Result.Err.7cb, @Result.Err(%i32, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.type.834: type = fn_type @Result.as.Try.impl.FromBreak, @Result.as.Try.impl(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.9cc: %Result.as.Try.impl.FromBreak.type.834 = struct_value () [symbolic]
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.type.d6a: type = fn_type @Result.as.Try.impl.Branch, @Result.as.Try.impl(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.513: %Result.as.Try.impl.Branch.type.d6a = struct_value () [symbolic]
// CHECK:STDOUT:   %Try.impl_witness.d5a: <witness> = impl_witness imports.%Try.impl_witness_table, @Result.as.Try.impl(%i32, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.type.521: type = fn_type @Result.as.Try.impl.Branch, @Result.as.Try.impl(%i32, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.1b9: %Result.as.Try.impl.Branch.type.521 = struct_value () [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.type.b43: type = fn_type @Result.as.Try.impl.FromBreak, @Result.as.Try.impl(%i32, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.c94: %Result.as.Try.impl.FromBreak.type.b43 = struct_value () [concrete]
// CHECK:STDOUT:   %Try.facet.51d: %Try.type = facet_value %Result.900, (%Try.impl_witness.d5a) [concrete]
// CHECK:STDOUT:   %Try.WithSelf.Branch.type.353: type = fn_type @Try.WithSelf.Branch, @Try.WithSelf(%Try.facet.51d) [concrete]
// CHECK:STDOUT:   %Try.WithSelf.FromBreak.type.cf1: type = fn_type @Try.WithSelf.FromBreak, @Try.WithSelf(%Try.facet.51d) [concrete]
// CHECK:STDOUT:   %.8bc: type = fn_type_with_self_type %Try.WithSelf.Branch.type.353, %Try.facet.51d [concrete]
// CHECK:STDOUT:   %ControlFlow.bd1: type = class_type @ControlFlow, @ControlFlow(%i32, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.specific_fn.2e1: <specific function> = specific_function %Result.as.Try.impl.Branch.1b9, @Result.as.Try.impl.Branch(%i32, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %.337: type = custom_layout_type {size=8, align=8, .Continue@0: %tuple.type.a8a, .Break@0: %tuple.type.b42} [concrete]
// CHECK:STDOUT:   %struct_type.discriminant.payload.b51: type = struct_type {.discriminant: %u1, .payload: %.337} [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.ca1: type = facet_type <@ImplicitAs, @ImplicitAs(%u1)> [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.b68(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.170: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.f4c: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.f01, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.46b: %ImplicitAs.type.ca1 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.f4c) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.77c: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%u1, %ImplicitAs.facet.46b) [concrete]
// CHECK:STDOUT:   %.e74: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.77c, %ImplicitAs.facet.46b [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.d7a: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
// CHECK:STDOUT:   %EqWith.type.c25: type = facet_type <@EqWith, @EqWith(%u1)> [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.544: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%N, %M) [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.c67: %UInt.as.EqWith.impl.Equal.type.544 = struct_value () [symbolic]
// CHECK:STDOUT:   %EqWith.impl_witness.7b3: <witness> = impl_witness imports.%EqWith.impl_witness_table.166, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.29b: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.ba4: %UInt.as.EqWith.impl.Equal.type.29b = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.4d0: %EqWith.type.c25 = facet_value %u1, (%EqWith.impl_witness.7b3) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.e3c: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%u1, %EqWith.facet.4d0) [concrete]
// CHECK:STDOUT:   %.9eb: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.e3c, %EqWith.facet.4d0 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.specific_fn.6b6: <specific function> = specific_function %UInt.as.EqWith.impl.Equal.ba4, @UInt.as.EqWith.impl.Equal.1(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.a82: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
// CHECK:STDOUT:   %.cfb: type = fn_type_with_self_type %Try.WithSelf.FromBreak.type.cf1, %Try.facet.51d [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.specific_fn: <specific function> = specific_function %Result.as.Try.impl.FromBreak.c94, @Result.as.Try.impl.FromBreak(%i32, %Cpp.Exception) [concrete]
// CHECK:STDOUT:   %Destroy.type: type = facet_type <@Destroy> [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.11: type = fn_type @Destroy.Op.loc25_64.11 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.11: %Destroy.Op.type.1d8f74.11 = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .Result = %Core.Result
// CHECK:STDOUT:     .Int = %Core.Int
// CHECK:STDOUT:     .CppCompat = %CppCompat.f0dbf9.1
// CHECK:STDOUT:     .Try = %Core.Try
// CHECK:STDOUT:     .ImplicitAs = %Core.ImplicitAs
// CHECK:STDOUT:     .EqWith = %Core.EqWith
// CHECK:STDOUT:     .Destroy = %Core.Destroy
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Cpp: <namespace> = namespace file.%Cpp.import_cpp, [concrete] {
// CHECK:STDOUT:     .Exception = constants.%Cpp.Exception
// CHECK:STDOUT:     .may_throw_int = %may_throw_int.cpp_overload_set.value
// CHECK:STDOUT:     import Cpp//...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Result: %Result.type = import_ref Core//prelude/types/result, Result, loaded [concrete = constants.%Result.generic]
// CHECK:STDOUT:   %Core.import_ref.597: @Result.%Result.Ok.type (%Result.Ok.type.898) = import_ref Core//prelude/types/result, loc{{\d+_\d+}}, loaded [symbolic = @Result.%Result.Ok (constants.%Result.Ok.58a)]
// CHECK:STDOUT:   %Core.import_ref.bfc4: @Result.%Result.Err.type (%Result.Err.type.b75) = import_ref Core//prelude/types/result, loc{{\d+_\d+}}, loaded [symbolic = @Result.%Result.Err (constants.%Result.Err.08c)]
// CHECK:STDOUT:   %Core.Int: %Int.type = import_ref Core//prelude/types/int, Int, loaded [concrete = constants.%Int.generic]
// CHECK:STDOUT:   %Core.CppCompat: <namespace> = import_ref Core//prelude, CppCompat, loaded
// CHECK:STDOUT:   %CppCompat.f0dbf9.1: <namespace> = namespace %Core.CppCompat, [concrete] {
// CHECK:STDOUT:     .Exception = %Core.Exception
// CHECK:STDOUT:     .VoidBase = %Core.VoidBase
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Exception: type = import_ref Core//prelude/types/cpp/exception, Exception, loaded [concrete = constants.%Cpp.Exception]
// CHECK:STDOUT:   %may_throw_int.cpp_overload_set.value: %may_throw_int.cpp_overload_set.type = cpp_overload_set_value @may_throw_int.cpp_overload_set [concrete = constants.%may_throw_int.cpp_overload_set.value]
// CHECK:STDOUT:   %Core.Try: type = import_ref Core//prelude/try, Try, loaded [concrete = constants.%Try.type]
// CHECK:STDOUT:   %Core.VoidBase: type = import_ref Core//prelude/types/cpp/void, VoidBase, loaded [concrete = constants.%Cpp.void]
// CHECK:STDOUT:   %may_throw_int__carbon_catching_thunk.decl: %may_throw_int__carbon_catching_thunk.type = fn_decl @may_throw_int__carbon_catching_thunk [concrete = constants.%may_throw_int__carbon_catching_thunk] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.ImplicitAs: %ImplicitAs.type.0ff = import_ref Core//prelude/operators/as, ImplicitAs, loaded [concrete = constants.%ImplicitAs.generic]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.EqWith: %EqWith.type.f77 = import_ref Core//prelude/operators/comparison, EqWith, loaded [concrete = constants.%EqWith.generic]
// CHECK:STDOUT:   %Core.import_ref.074: @Int.as.EqWith.impl.e9c.%Int.as.EqWith.impl.Equal.type (%Int.as.EqWith.impl.Equal.type.9a2) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.EqWith.impl.e9c.%Int.as.EqWith.impl.Equal (constants.%Int.as.EqWith.impl.Equal.792)]
// CHECK:STDOUT:   %Core.import_ref.449 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.09e = impl_witness_table (%Core.import_ref.074, %Core.import_ref.449), @Int.as.EqWith.impl.e9c [concrete]
// CHECK:STDOUT:   %Core.import_ref.0b3 = import_ref Core//prelude/types/result, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.6e9 = import_ref Core//prelude/types/result, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9f4: @Result.as.Try.impl.%Result.as.Try.impl.Branch.type (%Result.as.Try.impl.Branch.type.d6a) = import_ref Core//prelude/types/result, loc{{\d+_\d+}}, loaded [symbolic = @Result.as.Try.impl.%Result.as.Try.impl.Branch (constants.%Result.as.Try.impl.Branch.513)]
// CHECK:STDOUT:   %Core.import_ref.6a4: @Result.as.Try.impl.%Result.as.Try.impl.FromBreak.type (%Result.as.Try.impl.FromBreak.type.834) = import_ref Core//prelude/types/result, loc{{\d+_\d+}}, loaded [symbolic = @Result.as.Try.impl.%Result.as.Try.impl.FromBreak (constants.%Result.as.Try.impl.FromBreak.9cc)]
// CHECK:STDOUT:   %Try.impl_witness_table = impl_witness_table (%Core.import_ref.0b3, %Core.import_ref.6e9, %Core.import_ref.9f4, %Core.import_ref.6a4), @Result.as.Try.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.aa5: @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.170)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.f01 = impl_witness_table (%Core.import_ref.aa5), @Core.IntLiteral.as.ImplicitAs.impl.b68 [concrete]
// CHECK:STDOUT:   %Core.import_ref.b92: @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal.type (%UInt.as.EqWith.impl.Equal.type.544) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal (constants.%UInt.as.EqWith.impl.Equal.c67)]
// CHECK:STDOUT:   %Core.import_ref.b44 = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.166 = impl_witness_table (%Core.import_ref.b92, %Core.import_ref.b44), @UInt.as.EqWith.impl.f13 [concrete]
// CHECK:STDOUT:   %Core.Destroy: type = import_ref Core//prelude/destroy, Destroy, loaded [concrete = constants.%Destroy.type]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %R.decl: %R.type = fn_decl @R [concrete = constants.%R] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.5d9 = out_param_pattern [concrete = constants.%return.param_patt.8a0]
// CHECK:STDOUT:     %return.patt: %pattern_type.5d9 = return_slot_pattern %return.param_patt, %Result.loc24 [concrete = constants.%return.patt.dd6]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %Core.ref.loc24: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:     %Result.ref.loc24: %Result.type = name_ref Result, imports.%Core.Result [concrete = constants.%Result.generic]
// CHECK:STDOUT:     %i32.loc24: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %Cpp.ref.loc24: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:     %Exception.ref.loc24: type = name_ref Exception, constants.%Cpp.Exception [concrete = constants.%Cpp.Exception]
// CHECK:STDOUT:     %Result.loc24: type = class_type @Result, @Result(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.900]
// CHECK:STDOUT:     %.loc24_41.3: Core.Form = init_form %Result.loc24 [concrete = constants.%.c19]
// CHECK:STDOUT:     %return.param: ref %Result.900 = out_param call_param0
// CHECK:STDOUT:     %return: ref %Result.900 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @R() -> out %return.param: %Result.900 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Core.ref.loc25: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:   %Result.ref.loc25: %Result.type = name_ref Result, imports.%Core.Result [concrete = constants.%Result.generic]
// CHECK:STDOUT:   %i32.loc25: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %Cpp.ref.loc25_27: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:   %Exception.ref.loc25: type = name_ref Exception, constants.%Cpp.Exception [concrete = constants.%Cpp.Exception]
// CHECK:STDOUT:   %Result.loc25_40: type = class_type @Result, @Result(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.900]
// CHECK:STDOUT:   %.loc25_41: %Result.Ok.type.977 = specific_constant imports.%Core.import_ref.597, @Result(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.Ok.789]
// CHECK:STDOUT:   %Ok.ref.loc25_41: %Result.Ok.type.977 = name_ref Ok, %.loc25_41 [concrete = constants.%Result.Ok.789]
// CHECK:STDOUT:   %Cpp.ref.loc25_45: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:   %may_throw_int.ref: %may_throw_int.cpp_overload_set.type = name_ref may_throw_int, imports.%may_throw_int.cpp_overload_set.value [concrete = constants.%may_throw_int.cpp_overload_set.value]
// CHECK:STDOUT:   %Result.loc25_63: type = class_type @Result, @Result(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.900]
// CHECK:STDOUT:   %.loc25_63.1: ref %i32 = temporary_storage
// CHECK:STDOUT:   %addr.loc25_63.1: %ptr.d08 = addr_of %.loc25_63.1
// CHECK:STDOUT:   %.loc25_63.2: ref %ptr.00a = temporary_storage
// CHECK:STDOUT:   %addr.loc25_63.2: %ptr.6f9 = addr_of %.loc25_63.2
// CHECK:STDOUT:   %may_throw_int__carbon_catching_thunk.call: init %i32 = call imports.%may_throw_int__carbon_catching_thunk.decl(%addr.loc25_63.1, %addr.loc25_63.2)
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc25_63.1: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc25_63.1: <bound method> = bound_method %int_0, %impl.elem0.loc25_63.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc25_63.1: <specific function> = specific_function %impl.elem0.loc25_63.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc25_63.2: <bound method> = bound_method %int_0, %specific_fn.loc25_63.1 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc25_63: init %i32 = call %bound_method.loc25_63.2(%int_0) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc25_63.3: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc25_63 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc25_63.4: %i32 = converted %int_0, %.loc25_63.3 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %impl.elem0.loc25_63.2: %.a79 = impl_witness_access constants.%EqWith.impl_witness.34c, element0 [concrete = constants.%Int.as.EqWith.impl.Equal.34f]
// CHECK:STDOUT:   %bound_method.loc25_63.3: <bound method> = bound_method %may_throw_int__carbon_catching_thunk.call, %impl.elem0.loc25_63.2
// CHECK:STDOUT:   %specific_fn.loc25_63.2: <specific function> = specific_function %impl.elem0.loc25_63.2, @Int.as.EqWith.impl.Equal.1(constants.%int_32, constants.%int_32) [concrete = constants.%Int.as.EqWith.impl.Equal.specific_fn.12d]
// CHECK:STDOUT:   %bound_method.loc25_63.4: <bound method> = bound_method %may_throw_int__carbon_catching_thunk.call, %specific_fn.loc25_63.2
// CHECK:STDOUT:   %.loc25_63.5: %i32 = value_of_initializer %may_throw_int__carbon_catching_thunk.call
// CHECK:STDOUT:   %.loc25_63.6: %i32 = converted %may_throw_int__carbon_catching_thunk.call, %.loc25_63.5
// CHECK:STDOUT:   %Int.as.EqWith.impl.Equal.call: init bool = call %bound_method.loc25_63.4(%.loc25_63.6, %.loc25_63.4)
// CHECK:STDOUT:   %.loc25_63.7: bool = value_of_initializer %Int.as.EqWith.impl.Equal.call
// CHECK:STDOUT:   %.loc25_63.8: bool = converted %Int.as.EqWith.impl.Equal.call, %.loc25_63.7
// CHECK:STDOUT:   %.loc25_63.9: ref %Result.900 = temporary_storage
// CHECK:STDOUT:   if %.loc25_63.8 br !.loc25_63.1 else br !.loc25_63.2
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc25_63.1:
// CHECK:STDOUT:   %.loc25_63.10: %i32 = acquire_value %.loc25_63.1
// CHECK:STDOUT:   %.loc25_63.11: %Result.Ok.type.977 = specific_constant imports.%Core.import_ref.597, @Result(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.Ok.789]
// CHECK:STDOUT:   %Ok.ref.loc25_63: %Result.Ok.type.977 = name_ref Ok, %.loc25_63.11 [concrete = constants.%Result.Ok.789]
// CHECK:STDOUT:   %Result.Ok.specific_fn.loc25_63: <specific function> = specific_function %Ok.ref.loc25_63, @Result.Ok(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.Ok.specific_fn]
// CHECK:STDOUT:   %.loc25_63.12: ref %Result.900 = splice_block %.loc25_63.9 {}
// CHECK:STDOUT:   %Result.Ok.call.loc25_63: init %Result.900 to %.loc25_63.12 = call %Result.Ok.specific_fn.loc25_63(%.loc25_63.10)
// CHECK:STDOUT:   assign %.loc25_63.9, %Result.Ok.call.loc25_63
// CHECK:STDOUT:   br !.loc25_63.3
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc25_63.2:
// CHECK:STDOUT:   %.loc25_63.13: %ptr.00a = acquire_value %.loc25_63.2
// CHECK:STDOUT:   %.loc25_63.14: %Cpp.Exception = as_compatible %.loc25_63.13
// CHECK:STDOUT:   %.loc25_63.15: %Cpp.Exception = converted %.loc25_63.13, %.loc25_63.14
// CHECK:STDOUT:   %.loc25_63.16: %Result.Err.type.a4b = specific_constant imports.%Core.import_ref.bfc4, @Result(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.Err.7cb]
// CHECK:STDOUT:   %Err.ref: %Result.Err.type.a4b = name_ref Err, %.loc25_63.16 [concrete = constants.%Result.Err.7cb]
// CHECK:STDOUT:   %Result.Err.specific_fn: <specific function> = specific_function %Err.ref, @Result.Err(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.Err.specific_fn.031]
// CHECK:STDOUT:   %.loc25_63.17: ref %Result.900 = splice_block %.loc25_63.9 {}
// CHECK:STDOUT:   %Result.Err.call: init %Result.900 to %.loc25_63.17 = call %Result.Err.specific_fn(%.loc25_63.15)
// CHECK:STDOUT:   assign %.loc25_63.9, %Result.Err.call
// CHECK:STDOUT:   br !.loc25_63.3
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc25_63.3:
// CHECK:STDOUT:   %.loc25_63.18: %Result.900 = acquire_value %.loc25_63.9
// CHECK:STDOUT:   %impl.elem2: %.8bc = impl_witness_access constants.%Try.impl_witness.d5a, element2 [concrete = constants.%Result.as.Try.impl.Branch.1b9]
// CHECK:STDOUT:   %bound_method.loc25_64.1: <bound method> = bound_method %.loc25_63.18, %impl.elem2
// CHECK:STDOUT:   %specific_fn.loc25_64.1: <specific function> = specific_function %impl.elem2, @Result.as.Try.impl.Branch(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.as.Try.impl.Branch.specific_fn.2e1]
// CHECK:STDOUT:   %bound_method.loc25_64.2: <bound method> = bound_method %.loc25_63.18, %specific_fn.loc25_64.1
// CHECK:STDOUT:   %.loc25_64.1: ref %ControlFlow.bd1 = temporary_storage
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.call: init %ControlFlow.bd1 to %.loc25_64.1 = call %bound_method.loc25_64.2(%.loc25_63.18)
// CHECK:STDOUT:   %.loc25_64.2: ref %ControlFlow.bd1 = temporary %.loc25_64.1, %Result.as.Try.impl.Branch.call
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc25_64.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc25_64.3: <bound method> = bound_method %int_1, %impl.elem0.loc25_64.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc25_64.2: <specific function> = specific_function %impl.elem0.loc25_64.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc25_64.4: <bound method> = bound_method %int_1, %specific_fn.loc25_64.2 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc25_64: init %u1 = call %bound_method.loc25_64.4(%int_1) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc25_64.3: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc25_64 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc25_64.4: %u1 = converted %int_1, %.loc25_64.3 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc25_64.5: ref %u1 = class_element_access %.loc25_64.2, element0
// CHECK:STDOUT:   %impl.elem0.loc25_64.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc25_64.5: <bound method> = bound_method %.loc25_64.4, %impl.elem0.loc25_64.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound]
// CHECK:STDOUT:   %specific_fn.loc25_64.3: <specific function> = specific_function %impl.elem0.loc25_64.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc25_64.6: <bound method> = bound_method %.loc25_64.4, %specific_fn.loc25_64.3 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc25_64.6: %u1 = acquire_value %.loc25_64.5
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call: init bool = call %bound_method.loc25_64.6(%.loc25_64.4, %.loc25_64.6)
// CHECK:STDOUT:   %.loc25_64.7: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call
// CHECK:STDOUT:   %.loc25_64.8: bool = converted %UInt.as.EqWith.impl.Equal.call, %.loc25_64.7
// CHECK:STDOUT:   if %.loc25_64.8 br !.loc25_64.1 else br !.loc25_64.2
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc25_64.1:
// CHECK:STDOUT:   %.loc25_64.9: ref %.337 = class_element_access %.loc25_64.2, element1
// CHECK:STDOUT:   %.loc25_64.10: ref %tuple.type.b42 = class_element_access %.loc25_64.9, element1
// CHECK:STDOUT:   %tuple.elem0.loc25_64.1: ref %Cpp.Exception = tuple_access %.loc25_64.10, element0
// CHECK:STDOUT:   %.loc25_64.11: %Cpp.Exception = acquire_value %tuple.elem0.loc25_64.1
// CHECK:STDOUT:   %Try.facet: %Try.type = facet_value constants.%Result.900, (constants.%Try.impl_witness.d5a) [concrete = constants.%Try.facet.51d]
// CHECK:STDOUT:   %.loc25_64.12: %Try.type = converted constants.%Result.900, %Try.facet [concrete = constants.%Try.facet.51d]
// CHECK:STDOUT:   %impl.elem3: %.cfb = impl_witness_access constants.%Try.impl_witness.d5a, element3 [concrete = constants.%Result.as.Try.impl.FromBreak.c94]
// CHECK:STDOUT:   %specific_fn.loc25_64.4: <specific function> = specific_function %impl.elem3, @Result.as.Try.impl.FromBreak(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.as.Try.impl.FromBreak.specific_fn]
// CHECK:STDOUT:   %.loc24_41.1: ref %Result.900 = splice_block %return.param {}
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.call: init %Result.900 to %.loc24_41.1 = call %specific_fn.loc25_64.4(%.loc25_64.11)
// CHECK:STDOUT:   %Destroy.Op.bound.loc25_64.1: <bound method> = bound_method %.loc25_64.2, constants.%Destroy.Op.1a2547.11
// CHECK:STDOUT:   %Destroy.Op.call.loc25_64.1: init %empty_tuple.type = call %Destroy.Op.bound.loc25_64.1(%.loc25_64.2)
// CHECK:STDOUT:   return %Result.as.Try.impl.FromBreak.call to %return.param
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc25_64.2:
// CHECK:STDOUT:   %.loc25_64.13: ref %.337 = class_element_access %.loc25_64.2, element1
// CHECK:STDOUT:   %.loc25_64.14: ref %tuple.type.a8a = class_element_access %.loc25_64.13, element0
// CHECK:STDOUT:   %tuple.elem0.loc25_64.2: ref %i32 = tuple_access %.loc25_64.14, element0
// CHECK:STDOUT:   %.loc25_64.15: %i32 = acquire_value %tuple.elem0.loc25_64.2
// CHECK:STDOUT:   %Result.Ok.specific_fn.loc25_41: <specific function> = specific_function %Ok.ref.loc25_41, @Result.Ok(constants.%i32, constants.%Cpp.Exception) [concrete = constants.%Result.Ok.specific_fn]
// CHECK:STDOUT:   %.loc24_41.2: ref %Result.900 = splice_block %return.param {}
// CHECK:STDOUT:   %Result.Ok.call.loc25_65: init %Result.900 to %.loc24_41.2 = call %Result.Ok.specific_fn.loc25_41(%.loc25_64.15)
// CHECK:STDOUT:   %Destroy.Op.bound.loc25_64.2: <bound method> = bound_method %.loc25_64.2, constants.%Destroy.Op.1a2547.11
// CHECK:STDOUT:   %Destroy.Op.call.loc25_64.2: init %empty_tuple.type = call %Destroy.Op.bound.loc25_64.2(%.loc25_64.2)
// CHECK:STDOUT:   return %Result.Ok.call.loc25_65 to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc25_64.1(%self.param: ref %u1.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc25_64.2(%self.param: ref %u1) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc25_64.3(%self.param: ref %i32.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc25_64.4(%self.param: ref %i32) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc25_64.5(%self.param: ref %tuple.type.a8a) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc25_64.6(%self.param: ref %ptr.00a) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc25_64.7(%self.param: ref %Cpp.Exception) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc25_64.8(%self.param: ref %tuple.type.b42) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc25_64.9(%self.param: ref %.337) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc25_64.10(%self.param: ref %struct_type.discriminant.payload.b51) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc25_64.11(%self.param: ref %ControlFlow.bd1) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
