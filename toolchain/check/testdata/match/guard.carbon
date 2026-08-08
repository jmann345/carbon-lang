// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/guard.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/guard.carbon

// Case guards (`case P if (E) => ...`, re-platform plan S2d): the guard
// expression is checked in the arm's scope with the pattern's bindings in
// scope (docs/design/pattern_matching.md, "Guards"), evaluated in the arm's
// body block after the pattern's test and bind passes, and a failed guard
// falls through to the next arm (or `default`), preserving
// first-match-wins.

//@dump-sem-ir-begin
// A guard on a literal arm, referencing the enclosing scope.
fn Literal(x: i32) -> i32 {
  match (x) {
    case 0 if (x > -1) => { return 1; }
    default => { return 0; }
  }
  return -1;
}

// Guards using the arms' own bindings, in the guard and in the body. Both
// arms are irrefutable binding patterns, so only the guards discriminate:
// a failed first guard falls through to the second arm, and a failed
// second guard falls through to `default`.
fn Binding(x: i32) -> i32 {
  match (x) {
    case a: i32 if (a < 0) => { return a; }
    case b: i32 if (b > 10) => { return b; }
    default => { return 0; }
  }
  return -1;
}

// A side-effect-free compound guard: `and` short-circuits, so the guard's
// captured expression region is multi-block and splices into the arm's
// body block with branches rather than a `splice_block`.
fn Compound(x: i32) -> i32 {
  match (x) {
    case c: i32 if (c > 0 and c < 10) => { return 1; }
    default => { return 0; }
  }
  return -1;
}

// A guarded arm whose binding's declared type converts from the
// scrutinee's (`n: i64` from an `i32` scrutinee): the bind pass's
// conversion runs before the guard, its objects are deferred to the arm
// scope's cleanups, and the guard's failure edge discharges them before
// falling through to `default`.
fn Converting(x: i32) -> i64 {
  match (x) {
    case n: i64 if (n > 0) => { return n; }
    default => { return 0; }
  }
  return -1;
}
//@dump-sem-ir-end

// CHECK:STDOUT: --- guard.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %Int.67af24.1: type = class_type @Int, @Int(%N) [symbolic]
// CHECK:STDOUT:   %pattern_type.dc0: type = pattern_type Core.IntLiteral [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %x.param_patt: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %x.patt: %pattern_type.6b6 = at_binding_pattern x, %x.param_patt [concrete]
// CHECK:STDOUT:   %.795: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %Literal.type: type = fn_type @Literal [concrete]
// CHECK:STDOUT:   %Literal: %Literal.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %Negate.type: type = facet_type <@Negate> [concrete]
// CHECK:STDOUT:   %Negate.impl_witness: <witness> = impl_witness imports.%Negate.impl_witness_table [concrete]
// CHECK:STDOUT:   %Negate.facet: %Negate.type = facet_value Core.IntLiteral, (%Negate.impl_witness) [concrete]
// CHECK:STDOUT:   %Negate.WithSelf.Op.type.f03: type = fn_type @Negate.WithSelf.Op, @Negate.WithSelf(%Negate.facet) [concrete]
// CHECK:STDOUT:   %.02b: type = fn_type_with_self_type %Negate.WithSelf.Op.type.f03, %Negate.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.type: type = fn_type @Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op: %Core.IntLiteral.as.Negate.impl.Op.type = struct_value () [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.bound: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %int_-1.638: Core.IntLiteral = int_value -1 [concrete]
// CHECK:STDOUT:   %OrderedWith.type.975: type = facet_type <@OrderedWith, @OrderedWith(Core.IntLiteral)> [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.f7de31.1: type = facet_type <@ImplicitAs, @ImplicitAs(%Int.67af24.1)> [symbolic]
// CHECK:STDOUT:   %T.4e6: %ImplicitAs.type.f7de31.1 = symbolic_binding T, 1 [symbolic]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.type.18c27f.1: type = fn_type @Int.as.OrderedWith.impl.Greater.2, @Int.as.OrderedWith.impl.f36(%N, %T.4e6) [symbolic]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.cbccb6.1: %Int.as.OrderedWith.impl.Greater.type.18c27f.1 = struct_value () [symbolic]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Less.type.6605e2.1: type = fn_type @Int.as.OrderedWith.impl.Less.2, @Int.as.OrderedWith.impl.f36(%N, %T.4e6) [symbolic]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Less.59643b.1: %Int.as.OrderedWith.impl.Less.type.6605e2.1 = struct_value () [symbolic]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.type.18c27f.2: type = fn_type @Int.as.OrderedWith.impl.Greater.3, @Int.as.OrderedWith.impl.f36(%N, %T.4e6) [symbolic]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.cbccb6.2: %Int.as.OrderedWith.impl.Greater.type.18c27f.2 = struct_value () [symbolic]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Less.type.6605e2.2: type = fn_type @Int.as.OrderedWith.impl.Less.3, @Int.as.OrderedWith.impl.f36(%N, %T.4e6) [symbolic]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Less.59643b.2: %Int.as.OrderedWith.impl.Less.type.6605e2.2 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %To: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Int.67af24.2: type = class_type @Int, @Int(%To) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %facet_type.037: type = facet_type <@IntFitsIn, @IntFitsIn(%Int.67af24.2) & @AnyInt> [symbolic]
// CHECK:STDOUT:   %From.6a4: %facet_type.037 = symbolic_binding From, 1 [symbolic]
// CHECK:STDOUT:   %From.as_type.as.ImplicitAs.impl.Convert.type.7fa: type = fn_type @From.as_type.as.ImplicitAs.impl.Convert, @From.as_type.as.ImplicitAs.impl(%To, %From.6a4) [symbolic]
// CHECK:STDOUT:   %From.as_type.as.ImplicitAs.impl.Convert.643: %From.as_type.as.ImplicitAs.impl.Convert.type.7fa = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a23: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.b3c, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.9f1: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a23) [concrete]
// CHECK:STDOUT:   %OrderedWith.impl_witness.cb8: <witness> = impl_witness imports.%OrderedWith.impl_witness_table.6ed, @Int.as.OrderedWith.impl.f36(%int_32, %ImplicitAs.facet.9f1) [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Less.type.6df962.1: type = fn_type @Int.as.OrderedWith.impl.Less.3, @Int.as.OrderedWith.impl.f36(%int_32, %ImplicitAs.facet.9f1) [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Less.5da945.1: %Int.as.OrderedWith.impl.Less.type.6df962.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.type.c37381.1: type = fn_type @Int.as.OrderedWith.impl.Greater.3, @Int.as.OrderedWith.impl.f36(%int_32, %ImplicitAs.facet.9f1) [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.3fec66.1: %Int.as.OrderedWith.impl.Greater.type.c37381.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Less.type.6df962.2: type = fn_type @Int.as.OrderedWith.impl.Less.2, @Int.as.OrderedWith.impl.f36(%int_32, %ImplicitAs.facet.9f1) [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Less.5da945.2: %Int.as.OrderedWith.impl.Less.type.6df962.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.type.c37381.2: type = fn_type @Int.as.OrderedWith.impl.Greater.2, @Int.as.OrderedWith.impl.f36(%int_32, %ImplicitAs.facet.9f1) [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.3fec66.2: %Int.as.OrderedWith.impl.Greater.type.c37381.2 = struct_value () [concrete]
// CHECK:STDOUT:   %OrderedWith.facet.38e: %OrderedWith.type.975 = facet_value %i32, (%OrderedWith.impl_witness.cb8) [concrete]
// CHECK:STDOUT:   %OrderedWith.WithSelf.Less.type.c07: type = fn_type @OrderedWith.WithSelf.Less, @OrderedWith.WithSelf(Core.IntLiteral, %OrderedWith.facet.38e) [concrete]
// CHECK:STDOUT:   %OrderedWith.WithSelf.Greater.type.7e4: type = fn_type @OrderedWith.WithSelf.Greater, @OrderedWith.WithSelf(Core.IntLiteral, %OrderedWith.facet.38e) [concrete]
// CHECK:STDOUT:   %.d29: type = fn_type_with_self_type %OrderedWith.WithSelf.Greater.type.7e4, %OrderedWith.facet.38e [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.specific_fn.a67ca5.1: <specific function> = specific_function %Int.as.OrderedWith.impl.Greater.3fec66.2, @Int.as.OrderedWith.impl.Greater.2(%int_32, %ImplicitAs.facet.9f1) [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.specific_fn.a67ca5.2: <specific function> = specific_function %Int.as.OrderedWith.impl.Greater.3fec66.1, @Int.as.OrderedWith.impl.Greater.3(%int_32, %ImplicitAs.facet.9f1) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.740: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet.9f1) [concrete]
// CHECK:STDOUT:   %.1c5: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.740, %ImplicitAs.facet.9f1 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.65e: <bound method> = bound_method %int_-1.638, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.a65: <bound method> = bound_method %int_-1.638, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_-1.4ef: %i32 = int_value -1 [concrete]
// CHECK:STDOUT:   %EqWith.type.8ee: type = facet_type <@EqWith, @EqWith(%i32)> [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.type.8af025.1: type = fn_type @T.as_type.as.EqWith.impl.Equal.1, @T.as_type.as.EqWith.impl(%N, %T.4e6) [symbolic]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.c477d6.1: %T.as_type.as.EqWith.impl.Equal.type.8af025.1 = struct_value () [symbolic]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.type.8af025.2: type = fn_type @T.as_type.as.EqWith.impl.Equal.2, @T.as_type.as.EqWith.impl(%N, %T.4e6) [symbolic]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.c477d6.2: %T.as_type.as.EqWith.impl.Equal.type.8af025.2 = struct_value () [symbolic]
// CHECK:STDOUT:   %EqWith.impl_witness.8ff: <witness> = impl_witness imports.%EqWith.impl_witness_table.468, @T.as_type.as.EqWith.impl(%int_32, %ImplicitAs.facet.9f1) [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.type.e4cecd.1: type = fn_type @T.as_type.as.EqWith.impl.Equal.2, @T.as_type.as.EqWith.impl(%int_32, %ImplicitAs.facet.9f1) [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.a942d5.1: %T.as_type.as.EqWith.impl.Equal.type.e4cecd.1 = struct_value () [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.type.e4cecd.2: type = fn_type @T.as_type.as.EqWith.impl.Equal.1, @T.as_type.as.EqWith.impl(%int_32, %ImplicitAs.facet.9f1) [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.a942d5.2: %T.as_type.as.EqWith.impl.Equal.type.e4cecd.2 = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.28c: %EqWith.type.8ee = facet_value Core.IntLiteral, (%EqWith.impl_witness.8ff) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.b21: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%i32, %EqWith.facet.28c) [concrete]
// CHECK:STDOUT:   %.44e: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.b21, %EqWith.facet.28c [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound.6da2d9.1: <bound method> = bound_method %int_0.5c6, %T.as_type.as.EqWith.impl.Equal.a942d5.2 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.specific_fn.76b46b.1: <specific function> = specific_function %T.as_type.as.EqWith.impl.Equal.a942d5.2, @T.as_type.as.EqWith.impl.Equal.1(%int_32, %ImplicitAs.facet.9f1) [concrete]
// CHECK:STDOUT:   %bound_method.24f1fd.1: <bound method> = bound_method %int_0.5c6, %T.as_type.as.EqWith.impl.Equal.specific_fn.76b46b.1 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound.6da2d9.2: <bound method> = bound_method %int_0.5c6, %T.as_type.as.EqWith.impl.Equal.a942d5.1 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.specific_fn.76b46b.2: <specific function> = specific_function %T.as_type.as.EqWith.impl.Equal.a942d5.1, @T.as_type.as.EqWith.impl.Equal.2(%int_32, %ImplicitAs.facet.9f1) [concrete]
// CHECK:STDOUT:   %bound_method.24f1fd.2: <bound method> = bound_method %int_0.5c6, %T.as_type.as.EqWith.impl.Equal.specific_fn.76b46b.2 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.6e0: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_0.3c0: %i32 = int_value 0 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.953: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT:   %Binding.type: type = fn_type @Binding [concrete]
// CHECK:STDOUT:   %Binding: %Binding.type = struct_value () [concrete]
// CHECK:STDOUT:   %a.patt: %pattern_type.6b6 = value_binding_pattern a [concrete]
// CHECK:STDOUT:   %.211: type = fn_type_with_self_type %OrderedWith.WithSelf.Less.type.c07, %OrderedWith.facet.38e [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Less.specific_fn.4339a5.1: <specific function> = specific_function %Int.as.OrderedWith.impl.Less.5da945.2, @Int.as.OrderedWith.impl.Less.2(%int_32, %ImplicitAs.facet.9f1) [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Less.specific_fn.4339a5.2: <specific function> = specific_function %Int.as.OrderedWith.impl.Less.5da945.1, @Int.as.OrderedWith.impl.Less.3(%int_32, %ImplicitAs.facet.9f1) [concrete]
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.0e0: <witness> = impl_witness imports.%Copy.impl_witness_table.367, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet.987: %Copy.type = facet_value %i32, (%Copy.impl_witness.0e0) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.d09: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.987) [concrete]
// CHECK:STDOUT:   %.7a6: type = fn_type_with_self_type %Copy.WithSelf.Op.type.d09, %Copy.facet.987 [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn.287: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %b.patt: %pattern_type.6b6 = value_binding_pattern b [concrete]
// CHECK:STDOUT:   %int_10.64f: Core.IntLiteral = int_value 10 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.dcb: <bound method> = bound_method %int_10.64f, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.1b6: <bound method> = bound_method %int_10.64f, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_10.6bf: %i32 = int_value 10 [concrete]
// CHECK:STDOUT:   %Compound.type: type = fn_type @Compound [concrete]
// CHECK:STDOUT:   %Compound: %Compound.type = struct_value () [concrete]
// CHECK:STDOUT:   %c.patt: %pattern_type.6b6 = value_binding_pattern c [concrete]
// CHECK:STDOUT:   %false: bool = bool_literal false [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %.bc0: Core.Form = init_form %i64 [concrete]
// CHECK:STDOUT:   %pattern_type.f57: type = pattern_type %i64 [concrete]
// CHECK:STDOUT:   %return.param_patt.cfc: %pattern_type.f57 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.178: %pattern_type.f57 = return_slot_pattern %return.param_patt.cfc, %i64 [concrete]
// CHECK:STDOUT:   %Converting.type: type = fn_type @Converting [concrete]
// CHECK:STDOUT:   %Converting: %Converting.type = struct_value () [concrete]
// CHECK:STDOUT:   %n.patt: %pattern_type.f57 = value_binding_pattern n [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.221: type = facet_type <@ImplicitAs, @ImplicitAs(%i64)> [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.091: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.b3c, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_64) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.55a: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_64) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.55a = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.6e8: %ImplicitAs.type.221 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.091) [concrete]
// CHECK:STDOUT:   %OrderedWith.impl_witness.b1d: <witness> = impl_witness imports.%OrderedWith.impl_witness_table.6ed, @Int.as.OrderedWith.impl.f36(%int_64, %ImplicitAs.facet.6e8) [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.type.002547.1: type = fn_type @Int.as.OrderedWith.impl.Greater.3, @Int.as.OrderedWith.impl.f36(%int_64, %ImplicitAs.facet.6e8) [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.88ab7c.1: %Int.as.OrderedWith.impl.Greater.type.002547.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.type.002547.2: type = fn_type @Int.as.OrderedWith.impl.Greater.2, @Int.as.OrderedWith.impl.f36(%int_64, %ImplicitAs.facet.6e8) [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.88ab7c.2: %Int.as.OrderedWith.impl.Greater.type.002547.2 = struct_value () [concrete]
// CHECK:STDOUT:   %OrderedWith.facet.66f: %OrderedWith.type.975 = facet_value %i64, (%OrderedWith.impl_witness.b1d) [concrete]
// CHECK:STDOUT:   %OrderedWith.WithSelf.Greater.type.214: type = fn_type @OrderedWith.WithSelf.Greater, @OrderedWith.WithSelf(Core.IntLiteral, %OrderedWith.facet.66f) [concrete]
// CHECK:STDOUT:   %.996: type = fn_type_with_self_type %OrderedWith.WithSelf.Greater.type.214, %OrderedWith.facet.66f [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.specific_fn.07e5e7.1: <specific function> = specific_function %Int.as.OrderedWith.impl.Greater.88ab7c.2, @Int.as.OrderedWith.impl.Greater.2(%int_64, %ImplicitAs.facet.6e8) [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.specific_fn.07e5e7.2: <specific function> = specific_function %Int.as.OrderedWith.impl.Greater.88ab7c.1, @Int.as.OrderedWith.impl.Greater.3(%int_64, %ImplicitAs.facet.6e8) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.a04: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i64, %ImplicitAs.facet.6e8) [concrete]
// CHECK:STDOUT:   %.f349: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.a04, %ImplicitAs.facet.6e8 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.0a3: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.f33: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_64) [concrete]
// CHECK:STDOUT:   %bound_method.0c1: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.f33 [concrete]
// CHECK:STDOUT:   %int_0.2e4: %i64 = int_value 0 [concrete]
// CHECK:STDOUT:   %facet_type.30a: type = facet_type <@IntFitsIn, @IntFitsIn(%i64) & @AnyInt> [concrete]
// CHECK:STDOUT:   %custom_witness: <witness> = custom_witness (), @IntFitsIn, @IntFitsIn(%i64) [concrete]
// CHECK:STDOUT:   %Int.as.AnyInt.impl.AsInt.type.80b: type = fn_type @Int.as.AnyInt.impl.AsInt, @Int.as.AnyInt.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.AnyInt.impl.AsInt.23f: %Int.as.AnyInt.impl.AsInt.type.80b = struct_value () [symbolic]
// CHECK:STDOUT:   %AnyInt.impl_witness.76c: <witness> = impl_witness imports.%AnyInt.impl_witness_table, @Int.as.AnyInt.impl(%int_32) [concrete]
// CHECK:STDOUT:   %facet_value: %facet_type.30a = facet_value %i32, (%custom_witness, %AnyInt.impl_witness.76c) [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a40: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.3b9, @From.as_type.as.ImplicitAs.impl(%int_64, %facet_value) [concrete]
// CHECK:STDOUT:   %From.as_type.as.ImplicitAs.impl.Convert.type.eaf: type = fn_type @From.as_type.as.ImplicitAs.impl.Convert, @From.as_type.as.ImplicitAs.impl(%int_64, %facet_value) [concrete]
// CHECK:STDOUT:   %From.as_type.as.ImplicitAs.impl.Convert.e3c: %From.as_type.as.ImplicitAs.impl.Convert.type.eaf = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.401: %ImplicitAs.type.221 = facet_value %i32, (%ImplicitAs.impl_witness.a40) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.4fc: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i64, %ImplicitAs.facet.401) [concrete]
// CHECK:STDOUT:   %.9a0: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.4fc, %ImplicitAs.facet.401 [concrete]
// CHECK:STDOUT:   %From.as_type.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %From.as_type.as.ImplicitAs.impl.Convert.e3c, @From.as_type.as.ImplicitAs.impl.Convert(%int_64, %facet_value) [concrete]
// CHECK:STDOUT:   %Copy.impl_witness.c5e: <witness> = impl_witness imports.%Copy.impl_witness_table.367, @Int.as.Copy.impl(%int_64) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.494: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_64) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.d73: %Int.as.Copy.impl.Op.type.494 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet.b84: %Copy.type = facet_value %i64, (%Copy.impl_witness.c5e) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.70a: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.b84) [concrete]
// CHECK:STDOUT:   %.3cb: type = fn_type_with_self_type %Copy.WithSelf.Op.type.70a, %Copy.facet.b84 [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn.b95: <specific function> = specific_function %Int.as.Copy.impl.Op.d73, @Int.as.Copy.impl.Op(%int_64) [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.abd = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9c3: %Core.IntLiteral.as.Negate.impl.Op.type = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, loaded [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %Negate.impl_witness_table = impl_witness_table (%Core.import_ref.abd, %Core.import_ref.9c3), @Core.IntLiteral.as.Negate.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.1dc: @Int.as.OrderedWith.impl.f36.%Int.as.OrderedWith.impl.Less.type.2 (%Int.as.OrderedWith.impl.Less.type.6605e2.1) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.OrderedWith.impl.f36.%Int.as.OrderedWith.impl.Less.2 (constants.%Int.as.OrderedWith.impl.Less.59643b.1)]
// CHECK:STDOUT:   %Core.import_ref.f9d = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.0ab: @Int.as.OrderedWith.impl.f36.%Int.as.OrderedWith.impl.Greater.type.2 (%Int.as.OrderedWith.impl.Greater.type.18c27f.1) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.OrderedWith.impl.f36.%Int.as.OrderedWith.impl.Greater.2 (constants.%Int.as.OrderedWith.impl.Greater.cbccb6.1)]
// CHECK:STDOUT:   %Core.import_ref.b56 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %OrderedWith.impl_witness_table.6ed = impl_witness_table (%Core.import_ref.1dc, %Core.import_ref.f9d, %Core.import_ref.0ab, %Core.import_ref.b56), @Int.as.OrderedWith.impl.f36 [concrete]
// CHECK:STDOUT:   %Core.Less.80e: @Int.as.OrderedWith.impl.f36.%Int.as.OrderedWith.impl.Less.type.1 (%Int.as.OrderedWith.impl.Less.type.6605e2.2) = import_ref Core//prelude/types/int, Less, loaded [symbolic = @Int.as.OrderedWith.impl.f36.%Int.as.OrderedWith.impl.Less.1 (constants.%Int.as.OrderedWith.impl.Less.59643b.2)]
// CHECK:STDOUT:   %Core.Greater.28d: @Int.as.OrderedWith.impl.f36.%Int.as.OrderedWith.impl.Greater.type.1 (%Int.as.OrderedWith.impl.Greater.type.18c27f.2) = import_ref Core//prelude/types/int, Greater, loaded [symbolic = @Int.as.OrderedWith.impl.f36.%Int.as.OrderedWith.impl.Greater.1 (constants.%Int.as.OrderedWith.impl.Greater.cbccb6.2)]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.b3c = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.2a4: @From.as_type.as.ImplicitAs.impl.%From.as_type.as.ImplicitAs.impl.Convert.type (%From.as_type.as.ImplicitAs.impl.Convert.type.7fa) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @From.as_type.as.ImplicitAs.impl.%From.as_type.as.ImplicitAs.impl.Convert (constants.%From.as_type.as.ImplicitAs.impl.Convert.643)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.3b9 = impl_witness_table (%Core.import_ref.2a4), @From.as_type.as.ImplicitAs.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.a9a: @T.as_type.as.EqWith.impl.%T.as_type.as.EqWith.impl.Equal.type.2 (%T.as_type.as.EqWith.impl.Equal.type.8af025.1) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @T.as_type.as.EqWith.impl.%T.as_type.as.EqWith.impl.Equal.2 (constants.%T.as_type.as.EqWith.impl.Equal.c477d6.1)]
// CHECK:STDOUT:   %Core.import_ref.712 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.468 = impl_witness_table (%Core.import_ref.a9a, %Core.import_ref.712), @T.as_type.as.EqWith.impl [concrete]
// CHECK:STDOUT:   %Core.Equal.970: @T.as_type.as.EqWith.impl.%T.as_type.as.EqWith.impl.Equal.type.1 (%T.as_type.as.EqWith.impl.Equal.type.8af025.2) = import_ref Core//prelude/types/int, Equal, loaded [symbolic = @T.as_type.as.EqWith.impl.%T.as_type.as.EqWith.impl.Equal.1 (constants.%T.as_type.as.EqWith.impl.Equal.c477d6.2)]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.367 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.47b: Core.IntLiteral = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.AnyInt.impl.%N (constants.%N)]
// CHECK:STDOUT:   %Core.import_ref.fd3: @Int.as.AnyInt.impl.%Int.as.AnyInt.impl.AsInt.type (%Int.as.AnyInt.impl.AsInt.type.80b) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.AnyInt.impl.%Int.as.AnyInt.impl.AsInt (constants.%Int.as.AnyInt.impl.AsInt.23f)]
// CHECK:STDOUT:   %AnyInt.impl_witness_table = impl_witness_table (%Core.import_ref.47b, %Core.import_ref.fd3), @Int.as.AnyInt.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Literal.decl: %Literal.type = fn_decl @Literal [concrete = constants.%Literal] {
// CHECK:STDOUT:     %x.param_patt: %pattern_type.6b6 = value_param_pattern [concrete = constants.%x.param_patt]
// CHECK:STDOUT:     %x.patt: %pattern_type.6b6 = at_binding_pattern x, %x.param_patt [concrete = constants.%x.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc22_23 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc22_23: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc22: Core.Form = init_form %i32.loc22_23 [concrete = constants.%.795]
// CHECK:STDOUT:     %x.param: %i32 = value_param call_param0
// CHECK:STDOUT:     %i32.loc22_15: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %x: %i32 = wrapper_binding x, %x.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Binding.decl: %Binding.type = fn_decl @Binding [concrete = constants.%Binding] {
// CHECK:STDOUT:     %x.param_patt: %pattern_type.6b6 = value_param_pattern [concrete = constants.%x.param_patt]
// CHECK:STDOUT:     %x.patt: %pattern_type.6b6 = at_binding_pattern x, %x.param_patt [concrete = constants.%x.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc34_23 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc34_23: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc34: Core.Form = init_form %i32.loc34_23 [concrete = constants.%.795]
// CHECK:STDOUT:     %x.param: %i32 = value_param call_param0
// CHECK:STDOUT:     %i32.loc34_15: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %x: %i32 = wrapper_binding x, %x.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Compound.decl: %Compound.type = fn_decl @Compound [concrete = constants.%Compound] {
// CHECK:STDOUT:     %x.param_patt: %pattern_type.6b6 = value_param_pattern [concrete = constants.%x.param_patt]
// CHECK:STDOUT:     %x.patt: %pattern_type.6b6 = at_binding_pattern x, %x.param_patt [concrete = constants.%x.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc46_24 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc46_24: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc46: Core.Form = init_form %i32.loc46_24 [concrete = constants.%.795]
// CHECK:STDOUT:     %x.param: %i32 = value_param call_param0
// CHECK:STDOUT:     %i32.loc46_16: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %x: %i32 = wrapper_binding x, %x.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Converting.decl: %Converting.type = fn_decl @Converting [concrete = constants.%Converting] {
// CHECK:STDOUT:     %x.param_patt: %pattern_type.6b6 = value_param_pattern [concrete = constants.%x.param_patt]
// CHECK:STDOUT:     %x.patt: %pattern_type.6b6 = at_binding_pattern x, %x.param_patt [concrete = constants.%x.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.f57 = out_param_pattern [concrete = constants.%return.param_patt.cfc]
// CHECK:STDOUT:     %return.patt: %pattern_type.f57 = return_slot_pattern %return.param_patt, %i64.loc59 [concrete = constants.%return.patt.178]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i64.loc59: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:     %.loc59: Core.Form = init_form %i64.loc59 [concrete = constants.%.bc0]
// CHECK:STDOUT:     %x.param: %i32 = value_param call_param0
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %x: %i32 = wrapper_binding x, %x.param
// CHECK:STDOUT:     %return.param: ref %i64 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i64 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Literal(%x.param: %i32) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %x.ref.loc23: %i32 = name_ref x, %x
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt: %pattern_type.dc0 = expr_pattern %int_0.loc24 in [concrete] {
// CHECK:STDOUT:       %int_0.loc24: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_0.loc24: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc24_24: %.44e = impl_witness_access constants.%EqWith.impl_witness.8ff, element0 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.a942d5.2]
// CHECK:STDOUT:   %bound_method.loc24_24.1: <bound method> = bound_method %int_0.loc24, %impl.elem0.loc24_24 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.bound.6da2d9.1]
// CHECK:STDOUT:   %specific_fn.loc24_24: <specific function> = specific_function %impl.elem0.loc24_24, @T.as_type.as.EqWith.impl.Equal.1(constants.%int_32, constants.%ImplicitAs.facet.9f1) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.specific_fn.76b46b.1]
// CHECK:STDOUT:   %bound_method.loc24_24.2: <bound method> = bound_method %int_0.loc24, %specific_fn.loc24_24 [concrete = constants.%bound_method.24f1fd.1]
// CHECK:STDOUT:   %.loc24_24.1: %T.as_type.as.EqWith.impl.Equal.type.e4cecd.1 = specific_constant imports.%Core.Equal.970, @T.as_type.as.EqWith.impl(constants.%int_32, constants.%ImplicitAs.facet.9f1) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.a942d5.1]
// CHECK:STDOUT:   %Equal.ref: %T.as_type.as.EqWith.impl.Equal.type.e4cecd.1 = name_ref Equal, %.loc24_24.1 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.a942d5.1]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound: <bound method> = bound_method %int_0.loc24, %Equal.ref [concrete = constants.%T.as_type.as.EqWith.impl.Equal.bound.6da2d9.2]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.specific_fn: <specific function> = specific_function %Equal.ref, @T.as_type.as.EqWith.impl.Equal.2(constants.%int_32, constants.%ImplicitAs.facet.9f1) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.specific_fn.76b46b.2]
// CHECK:STDOUT:   %bound_method.loc24_24.3: <bound method> = bound_method %int_0.loc24, %T.as_type.as.EqWith.impl.Equal.specific_fn [concrete = constants.%bound_method.24f1fd.2]
// CHECK:STDOUT:   %impl.elem0.loc24_10: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc24_10.1: <bound method> = bound_method %int_0.loc24, %impl.elem0.loc24_10 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc24_10: <specific function> = specific_function %impl.elem0.loc24_10, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc24_10.2: <bound method> = bound_method %int_0.loc24, %specific_fn.loc24_10 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc24_10: init %i32 = call %bound_method.loc24_10.2(%int_0.loc24) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc24_10.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc24_10 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc24_10.2: %i32 = converted %int_0.loc24, %.loc24_10.1 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.call: init bool = call %bound_method.loc24_24.3(%.loc24_10.2, %x.ref.loc23)
// CHECK:STDOUT:   %.loc24_24.2: bool = value_of_initializer %T.as_type.as.EqWith.impl.Equal.call
// CHECK:STDOUT:   %.loc24_24.3: bool = converted %T.as_type.as.EqWith.impl.Equal.call, %.loc24_24.2
// CHECK:STDOUT:   if %.loc24_24.3 br !match.case.then.loc24_24.1 else br !match.case.else
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc24_24.1:
// CHECK:STDOUT:   %.loc24_18.1: bool = splice_block %.loc24_18.4 {
// CHECK:STDOUT:     %x.ref.loc24: %i32 = name_ref x, %x
// CHECK:STDOUT:     %int_1.loc24_21: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:     %impl.elem1: %.02b = impl_witness_access constants.%Negate.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:     %bound_method.loc24_20.1: <bound method> = bound_method %int_1.loc24_21, %impl.elem1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op.bound]
// CHECK:STDOUT:     %Core.IntLiteral.as.Negate.impl.Op.call: init Core.IntLiteral = call %bound_method.loc24_20.1(%int_1.loc24_21) [concrete = constants.%int_-1.638]
// CHECK:STDOUT:     %impl.elem2: %.d29 = impl_witness_access constants.%OrderedWith.impl_witness.cb8, element2 [concrete = constants.%Int.as.OrderedWith.impl.Greater.3fec66.2]
// CHECK:STDOUT:     %bound_method.loc24_18.1: <bound method> = bound_method %x.ref.loc24, %impl.elem2
// CHECK:STDOUT:     %specific_fn.loc24_18: <specific function> = specific_function %impl.elem2, @Int.as.OrderedWith.impl.Greater.2(constants.%int_32, constants.%ImplicitAs.facet.9f1) [concrete = constants.%Int.as.OrderedWith.impl.Greater.specific_fn.a67ca5.1]
// CHECK:STDOUT:     %bound_method.loc24_18.2: <bound method> = bound_method %x.ref.loc24, %specific_fn.loc24_18
// CHECK:STDOUT:     %.loc24_20.1: Core.IntLiteral = value_of_initializer %Core.IntLiteral.as.Negate.impl.Op.call [concrete = constants.%int_-1.638]
// CHECK:STDOUT:     %.loc24_20.2: Core.IntLiteral = converted %Core.IntLiteral.as.Negate.impl.Op.call, %.loc24_20.1 [concrete = constants.%int_-1.638]
// CHECK:STDOUT:     %.loc24_18.2: %Int.as.OrderedWith.impl.Greater.type.c37381.1 = specific_constant imports.%Core.Greater.28d, @Int.as.OrderedWith.impl.f36(constants.%int_32, constants.%ImplicitAs.facet.9f1) [concrete = constants.%Int.as.OrderedWith.impl.Greater.3fec66.1]
// CHECK:STDOUT:     %Greater.ref: %Int.as.OrderedWith.impl.Greater.type.c37381.1 = name_ref Greater, %.loc24_18.2 [concrete = constants.%Int.as.OrderedWith.impl.Greater.3fec66.1]
// CHECK:STDOUT:     %Int.as.OrderedWith.impl.Greater.bound: <bound method> = bound_method %x.ref.loc24, %Greater.ref
// CHECK:STDOUT:     %Int.as.OrderedWith.impl.Greater.specific_fn: <specific function> = specific_function %Greater.ref, @Int.as.OrderedWith.impl.Greater.3(constants.%int_32, constants.%ImplicitAs.facet.9f1) [concrete = constants.%Int.as.OrderedWith.impl.Greater.specific_fn.a67ca5.2]
// CHECK:STDOUT:     %bound_method.loc24_18.3: <bound method> = bound_method %x.ref.loc24, %Int.as.OrderedWith.impl.Greater.specific_fn
// CHECK:STDOUT:     %impl.elem0.loc24_20: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:     %bound_method.loc24_20.2: <bound method> = bound_method %.loc24_20.2, %impl.elem0.loc24_20 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.65e]
// CHECK:STDOUT:     %specific_fn.loc24_20: <specific function> = specific_function %impl.elem0.loc24_20, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:     %bound_method.loc24_20.3: <bound method> = bound_method %.loc24_20.2, %specific_fn.loc24_20 [concrete = constants.%bound_method.a65]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc24_20: init %i32 = call %bound_method.loc24_20.3(%.loc24_20.2) [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:     %.loc24_20.3: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc24_20 [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:     %.loc24_20.4: %i32 = converted %.loc24_20.2, %.loc24_20.3 [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:     %Int.as.OrderedWith.impl.Greater.call: init bool = call %bound_method.loc24_18.3(%x.ref.loc24, %.loc24_20.4)
// CHECK:STDOUT:     %.loc24_18.3: bool = value_of_initializer %Int.as.OrderedWith.impl.Greater.call
// CHECK:STDOUT:     %.loc24_18.4: bool = converted %Int.as.OrderedWith.impl.Greater.call, %.loc24_18.3
// CHECK:STDOUT:   }
// CHECK:STDOUT:   if %.loc24_18.1 br !match.case.then.loc24_24.2 else br !match.case.else
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc24_24.2:
// CHECK:STDOUT:   %int_1.loc24_36: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc24_37: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc24_37.1: <bound method> = bound_method %int_1.loc24_36, %impl.elem0.loc24_37 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc24_37: <specific function> = specific_function %impl.elem0.loc24_37, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc24_37.2: <bound method> = bound_method %int_1.loc24_36, %specific_fn.loc24_37 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc24_37: init %i32 = call %bound_method.loc24_37.2(%int_1.loc24_36) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc24_37: init %i32 = converted %int_1.loc24_36, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc24_37 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   return %.loc24_37
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else:
// CHECK:STDOUT:   %int_0.loc25: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc25: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc25_26.1: <bound method> = bound_method %int_0.loc25, %impl.elem0.loc25 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc25: <specific function> = specific_function %impl.elem0.loc25, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc25_26.2: <bound method> = bound_method %int_0.loc25, %specific_fn.loc25 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc25: init %i32 = call %bound_method.loc25_26.2(%int_0.loc25) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc25: init %i32 = converted %int_0.loc25, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc25 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   return %.loc25
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Binding(%x.param: %i32) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %x.ref: %i32 = name_ref x, %x
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %a.patt: %pattern_type.6b6 = value_binding_pattern a [concrete = constants.%a.patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %true.loc36: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:   if %true.loc36 br !match.case.then.loc36_28.1 else br !match.case.else.loc36
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc36_28.1:
// CHECK:STDOUT:   %i32.loc36: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %a: %i32 = wrapper_binding a, %x.ref
// CHECK:STDOUT:   %.loc36_23.1: bool = splice_block %.loc36_23.4 {
// CHECK:STDOUT:     %a.ref.loc36_21: %i32 = name_ref a, %a
// CHECK:STDOUT:     %int_0.loc36: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:     %impl.elem0.loc36_23: %.211 = impl_witness_access constants.%OrderedWith.impl_witness.cb8, element0 [concrete = constants.%Int.as.OrderedWith.impl.Less.5da945.2]
// CHECK:STDOUT:     %bound_method.loc36_23.1: <bound method> = bound_method %a.ref.loc36_21, %impl.elem0.loc36_23
// CHECK:STDOUT:     %specific_fn.loc36_23: <specific function> = specific_function %impl.elem0.loc36_23, @Int.as.OrderedWith.impl.Less.2(constants.%int_32, constants.%ImplicitAs.facet.9f1) [concrete = constants.%Int.as.OrderedWith.impl.Less.specific_fn.4339a5.1]
// CHECK:STDOUT:     %bound_method.loc36_23.2: <bound method> = bound_method %a.ref.loc36_21, %specific_fn.loc36_23
// CHECK:STDOUT:     %.loc36_23.2: %Int.as.OrderedWith.impl.Less.type.6df962.1 = specific_constant imports.%Core.Less.80e, @Int.as.OrderedWith.impl.f36(constants.%int_32, constants.%ImplicitAs.facet.9f1) [concrete = constants.%Int.as.OrderedWith.impl.Less.5da945.1]
// CHECK:STDOUT:     %Less.ref: %Int.as.OrderedWith.impl.Less.type.6df962.1 = name_ref Less, %.loc36_23.2 [concrete = constants.%Int.as.OrderedWith.impl.Less.5da945.1]
// CHECK:STDOUT:     %Int.as.OrderedWith.impl.Less.bound: <bound method> = bound_method %a.ref.loc36_21, %Less.ref
// CHECK:STDOUT:     %Int.as.OrderedWith.impl.Less.specific_fn: <specific function> = specific_function %Less.ref, @Int.as.OrderedWith.impl.Less.3(constants.%int_32, constants.%ImplicitAs.facet.9f1) [concrete = constants.%Int.as.OrderedWith.impl.Less.specific_fn.4339a5.2]
// CHECK:STDOUT:     %bound_method.loc36_23.3: <bound method> = bound_method %a.ref.loc36_21, %Int.as.OrderedWith.impl.Less.specific_fn
// CHECK:STDOUT:     %impl.elem0.loc36_25: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:     %bound_method.loc36_25.1: <bound method> = bound_method %int_0.loc36, %impl.elem0.loc36_25 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:     %specific_fn.loc36_25: <specific function> = specific_function %impl.elem0.loc36_25, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:     %bound_method.loc36_25.2: <bound method> = bound_method %int_0.loc36, %specific_fn.loc36_25 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc36: init %i32 = call %bound_method.loc36_25.2(%int_0.loc36) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:     %.loc36_25.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc36 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:     %.loc36_25.2: %i32 = converted %int_0.loc36, %.loc36_25.1 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:     %Int.as.OrderedWith.impl.Less.call: init bool = call %bound_method.loc36_23.3(%a.ref.loc36_21, %.loc36_25.2)
// CHECK:STDOUT:     %.loc36_23.3: bool = value_of_initializer %Int.as.OrderedWith.impl.Less.call
// CHECK:STDOUT:     %.loc36_23.4: bool = converted %Int.as.OrderedWith.impl.Less.call, %.loc36_23.3
// CHECK:STDOUT:   }
// CHECK:STDOUT:   if %.loc36_23.1 br !match.case.then.loc36_28.2 else br !match.case.else.loc36
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc36_28.2:
// CHECK:STDOUT:   %a.ref.loc36_40: %i32 = name_ref a, %a
// CHECK:STDOUT:   %impl.elem0.loc36_40: %.7a6 = impl_witness_access constants.%Copy.impl_witness.0e0, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc36_40.1: <bound method> = bound_method %a.ref.loc36_40, %impl.elem0.loc36_40
// CHECK:STDOUT:   %specific_fn.loc36_40: <specific function> = specific_function %impl.elem0.loc36_40, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn.287]
// CHECK:STDOUT:   %bound_method.loc36_40.2: <bound method> = bound_method %a.ref.loc36_40, %specific_fn.loc36_40
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call.loc36: init %i32 = call %bound_method.loc36_40.2(%a.ref.loc36_40)
// CHECK:STDOUT:   return %Int.as.Copy.impl.Op.call.loc36
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc36:
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %b.patt: %pattern_type.6b6 = value_binding_pattern b [concrete = constants.%b.patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %true.loc37: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:   if %true.loc37 br !match.case.then.loc37_29.1 else br !match.case.else.loc37
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc37_29.1:
// CHECK:STDOUT:   %i32.loc37: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %b: %i32 = wrapper_binding b, %x.ref
// CHECK:STDOUT:   %.loc37_23.1: bool = splice_block %.loc37_23.4 {
// CHECK:STDOUT:     %b.ref.loc37_21: %i32 = name_ref b, %b
// CHECK:STDOUT:     %int_10: Core.IntLiteral = int_value 10 [concrete = constants.%int_10.64f]
// CHECK:STDOUT:     %impl.elem2: %.d29 = impl_witness_access constants.%OrderedWith.impl_witness.cb8, element2 [concrete = constants.%Int.as.OrderedWith.impl.Greater.3fec66.2]
// CHECK:STDOUT:     %bound_method.loc37_23.1: <bound method> = bound_method %b.ref.loc37_21, %impl.elem2
// CHECK:STDOUT:     %specific_fn.loc37_23: <specific function> = specific_function %impl.elem2, @Int.as.OrderedWith.impl.Greater.2(constants.%int_32, constants.%ImplicitAs.facet.9f1) [concrete = constants.%Int.as.OrderedWith.impl.Greater.specific_fn.a67ca5.1]
// CHECK:STDOUT:     %bound_method.loc37_23.2: <bound method> = bound_method %b.ref.loc37_21, %specific_fn.loc37_23
// CHECK:STDOUT:     %.loc37_23.2: %Int.as.OrderedWith.impl.Greater.type.c37381.1 = specific_constant imports.%Core.Greater.28d, @Int.as.OrderedWith.impl.f36(constants.%int_32, constants.%ImplicitAs.facet.9f1) [concrete = constants.%Int.as.OrderedWith.impl.Greater.3fec66.1]
// CHECK:STDOUT:     %Greater.ref: %Int.as.OrderedWith.impl.Greater.type.c37381.1 = name_ref Greater, %.loc37_23.2 [concrete = constants.%Int.as.OrderedWith.impl.Greater.3fec66.1]
// CHECK:STDOUT:     %Int.as.OrderedWith.impl.Greater.bound: <bound method> = bound_method %b.ref.loc37_21, %Greater.ref
// CHECK:STDOUT:     %Int.as.OrderedWith.impl.Greater.specific_fn: <specific function> = specific_function %Greater.ref, @Int.as.OrderedWith.impl.Greater.3(constants.%int_32, constants.%ImplicitAs.facet.9f1) [concrete = constants.%Int.as.OrderedWith.impl.Greater.specific_fn.a67ca5.2]
// CHECK:STDOUT:     %bound_method.loc37_23.3: <bound method> = bound_method %b.ref.loc37_21, %Int.as.OrderedWith.impl.Greater.specific_fn
// CHECK:STDOUT:     %impl.elem0.loc37_25: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:     %bound_method.loc37_25.1: <bound method> = bound_method %int_10, %impl.elem0.loc37_25 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.dcb]
// CHECK:STDOUT:     %specific_fn.loc37_25: <specific function> = specific_function %impl.elem0.loc37_25, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:     %bound_method.loc37_25.2: <bound method> = bound_method %int_10, %specific_fn.loc37_25 [concrete = constants.%bound_method.1b6]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc37: init %i32 = call %bound_method.loc37_25.2(%int_10) [concrete = constants.%int_10.6bf]
// CHECK:STDOUT:     %.loc37_25.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc37 [concrete = constants.%int_10.6bf]
// CHECK:STDOUT:     %.loc37_25.2: %i32 = converted %int_10, %.loc37_25.1 [concrete = constants.%int_10.6bf]
// CHECK:STDOUT:     %Int.as.OrderedWith.impl.Greater.call: init bool = call %bound_method.loc37_23.3(%b.ref.loc37_21, %.loc37_25.2)
// CHECK:STDOUT:     %.loc37_23.3: bool = value_of_initializer %Int.as.OrderedWith.impl.Greater.call
// CHECK:STDOUT:     %.loc37_23.4: bool = converted %Int.as.OrderedWith.impl.Greater.call, %.loc37_23.3
// CHECK:STDOUT:   }
// CHECK:STDOUT:   if %.loc37_23.1 br !match.case.then.loc37_29.2 else br !match.case.else.loc37
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc37_29.2:
// CHECK:STDOUT:   %b.ref.loc37_41: %i32 = name_ref b, %b
// CHECK:STDOUT:   %impl.elem0.loc37_41: %.7a6 = impl_witness_access constants.%Copy.impl_witness.0e0, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc37_41.1: <bound method> = bound_method %b.ref.loc37_41, %impl.elem0.loc37_41
// CHECK:STDOUT:   %specific_fn.loc37_41: <specific function> = specific_function %impl.elem0.loc37_41, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn.287]
// CHECK:STDOUT:   %bound_method.loc37_41.2: <bound method> = bound_method %b.ref.loc37_41, %specific_fn.loc37_41
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call.loc37: init %i32 = call %bound_method.loc37_41.2(%b.ref.loc37_41)
// CHECK:STDOUT:   return %Int.as.Copy.impl.Op.call.loc37
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc37:
// CHECK:STDOUT:   %int_0.loc38: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc38: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc38_26.1: <bound method> = bound_method %int_0.loc38, %impl.elem0.loc38 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc38: <specific function> = specific_function %impl.elem0.loc38, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc38_26.2: <bound method> = bound_method %int_0.loc38, %specific_fn.loc38 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc38: init %i32 = call %bound_method.loc38_26.2(%int_0.loc38) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc38: init %i32 = converted %int_0.loc38, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc38 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   return %.loc38
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Compound(%x.param: %i32) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %x.ref: %i32 = name_ref x, %x
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %c.patt: %pattern_type.6b6 = value_binding_pattern c [concrete = constants.%c.patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:   if %true br !match.case.then.loc48_39.1 else br !match.case.else
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc48_39.1:
// CHECK:STDOUT:   %i32.loc48: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %c: %i32 = wrapper_binding c, %x.ref
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc48_21:
// CHECK:STDOUT:   %c.ref.loc48_21: %i32 = name_ref c, %c
// CHECK:STDOUT:   %int_0.loc48: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem2: %.d29 = impl_witness_access constants.%OrderedWith.impl_witness.cb8, element2 [concrete = constants.%Int.as.OrderedWith.impl.Greater.3fec66.2]
// CHECK:STDOUT:   %bound_method.loc48_23.1: <bound method> = bound_method %c.ref.loc48_21, %impl.elem2
// CHECK:STDOUT:   %specific_fn.loc48_23: <specific function> = specific_function %impl.elem2, @Int.as.OrderedWith.impl.Greater.2(constants.%int_32, constants.%ImplicitAs.facet.9f1) [concrete = constants.%Int.as.OrderedWith.impl.Greater.specific_fn.a67ca5.1]
// CHECK:STDOUT:   %bound_method.loc48_23.2: <bound method> = bound_method %c.ref.loc48_21, %specific_fn.loc48_23
// CHECK:STDOUT:   %.loc48_23: %Int.as.OrderedWith.impl.Greater.type.c37381.1 = specific_constant imports.%Core.Greater.28d, @Int.as.OrderedWith.impl.f36(constants.%int_32, constants.%ImplicitAs.facet.9f1) [concrete = constants.%Int.as.OrderedWith.impl.Greater.3fec66.1]
// CHECK:STDOUT:   %Greater.ref: %Int.as.OrderedWith.impl.Greater.type.c37381.1 = name_ref Greater, %.loc48_23 [concrete = constants.%Int.as.OrderedWith.impl.Greater.3fec66.1]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.bound: <bound method> = bound_method %c.ref.loc48_21, %Greater.ref
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.specific_fn: <specific function> = specific_function %Greater.ref, @Int.as.OrderedWith.impl.Greater.3(constants.%int_32, constants.%ImplicitAs.facet.9f1) [concrete = constants.%Int.as.OrderedWith.impl.Greater.specific_fn.a67ca5.2]
// CHECK:STDOUT:   %bound_method.loc48_23.3: <bound method> = bound_method %c.ref.loc48_21, %Int.as.OrderedWith.impl.Greater.specific_fn
// CHECK:STDOUT:   %impl.elem0.loc48_25: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc48_25.1: <bound method> = bound_method %int_0.loc48, %impl.elem0.loc48_25 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc48_25: <specific function> = specific_function %impl.elem0.loc48_25, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc48_25.2: <bound method> = bound_method %int_0.loc48, %specific_fn.loc48_25 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc48_25: init %i32 = call %bound_method.loc48_25.2(%int_0.loc48) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc48_25.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc48_25 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc48_25.2: %i32 = converted %int_0.loc48, %.loc48_25.1 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.call: init bool = call %bound_method.loc48_23.3(%c.ref.loc48_21, %.loc48_25.2)
// CHECK:STDOUT:   %.loc48_27.1: bool = value_of_initializer %Int.as.OrderedWith.impl.Greater.call
// CHECK:STDOUT:   %.loc48_27.2: bool = converted %Int.as.OrderedWith.impl.Greater.call, %.loc48_27.1
// CHECK:STDOUT:   %false: bool = bool_literal false [concrete = constants.%false]
// CHECK:STDOUT:   if %.loc48_27.2 br !and.rhs else br !and.result(%false)
// CHECK:STDOUT:
// CHECK:STDOUT: !and.rhs:
// CHECK:STDOUT:   %c.ref.loc48_31: %i32 = name_ref c, %c
// CHECK:STDOUT:   %int_10: Core.IntLiteral = int_value 10 [concrete = constants.%int_10.64f]
// CHECK:STDOUT:   %impl.elem0.loc48_33: %.211 = impl_witness_access constants.%OrderedWith.impl_witness.cb8, element0 [concrete = constants.%Int.as.OrderedWith.impl.Less.5da945.2]
// CHECK:STDOUT:   %bound_method.loc48_33.1: <bound method> = bound_method %c.ref.loc48_31, %impl.elem0.loc48_33
// CHECK:STDOUT:   %specific_fn.loc48_33: <specific function> = specific_function %impl.elem0.loc48_33, @Int.as.OrderedWith.impl.Less.2(constants.%int_32, constants.%ImplicitAs.facet.9f1) [concrete = constants.%Int.as.OrderedWith.impl.Less.specific_fn.4339a5.1]
// CHECK:STDOUT:   %bound_method.loc48_33.2: <bound method> = bound_method %c.ref.loc48_31, %specific_fn.loc48_33
// CHECK:STDOUT:   %.loc48_33: %Int.as.OrderedWith.impl.Less.type.6df962.1 = specific_constant imports.%Core.Less.80e, @Int.as.OrderedWith.impl.f36(constants.%int_32, constants.%ImplicitAs.facet.9f1) [concrete = constants.%Int.as.OrderedWith.impl.Less.5da945.1]
// CHECK:STDOUT:   %Less.ref: %Int.as.OrderedWith.impl.Less.type.6df962.1 = name_ref Less, %.loc48_33 [concrete = constants.%Int.as.OrderedWith.impl.Less.5da945.1]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Less.bound: <bound method> = bound_method %c.ref.loc48_31, %Less.ref
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Less.specific_fn: <specific function> = specific_function %Less.ref, @Int.as.OrderedWith.impl.Less.3(constants.%int_32, constants.%ImplicitAs.facet.9f1) [concrete = constants.%Int.as.OrderedWith.impl.Less.specific_fn.4339a5.2]
// CHECK:STDOUT:   %bound_method.loc48_33.3: <bound method> = bound_method %c.ref.loc48_31, %Int.as.OrderedWith.impl.Less.specific_fn
// CHECK:STDOUT:   %impl.elem0.loc48_35: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc48_35.1: <bound method> = bound_method %int_10, %impl.elem0.loc48_35 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.dcb]
// CHECK:STDOUT:   %specific_fn.loc48_35: <specific function> = specific_function %impl.elem0.loc48_35, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc48_35.2: <bound method> = bound_method %int_10, %specific_fn.loc48_35 [concrete = constants.%bound_method.1b6]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc48_35: init %i32 = call %bound_method.loc48_35.2(%int_10) [concrete = constants.%int_10.6bf]
// CHECK:STDOUT:   %.loc48_35.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc48_35 [concrete = constants.%int_10.6bf]
// CHECK:STDOUT:   %.loc48_35.2: %i32 = converted %int_10, %.loc48_35.1 [concrete = constants.%int_10.6bf]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Less.call: init bool = call %bound_method.loc48_33.3(%c.ref.loc48_31, %.loc48_35.2)
// CHECK:STDOUT:   %.loc48_27.3: bool = value_of_initializer %Int.as.OrderedWith.impl.Less.call
// CHECK:STDOUT:   %.loc48_27.4: bool = converted %Int.as.OrderedWith.impl.Less.call, %.loc48_27.3
// CHECK:STDOUT:   br !and.result(%.loc48_27.4)
// CHECK:STDOUT:
// CHECK:STDOUT: !and.result:
// CHECK:STDOUT:   %.loc48_27.5: bool = block_arg !and.result
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc48_39:
// CHECK:STDOUT:   if %.loc48_27.5 br !match.case.then.loc48_39.2 else br !match.case.else
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc48_39.2:
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc48_52: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc48_52.1: <bound method> = bound_method %int_1, %impl.elem0.loc48_52 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc48_52: <specific function> = specific_function %impl.elem0.loc48_52, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc48_52.2: <bound method> = bound_method %int_1, %specific_fn.loc48_52 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc48_52: init %i32 = call %bound_method.loc48_52.2(%int_1) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc48_52: init %i32 = converted %int_1, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc48_52 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   return %.loc48_52
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else:
// CHECK:STDOUT:   %int_0.loc49: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc49: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc49_26.1: <bound method> = bound_method %int_0.loc49, %impl.elem0.loc49 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc49: <specific function> = specific_function %impl.elem0.loc49, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc49_26.2: <bound method> = bound_method %int_0.loc49, %specific_fn.loc49 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc49: init %i32 = call %bound_method.loc49_26.2(%int_0.loc49) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc49: init %i32 = converted %int_0.loc49, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc49 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   return %.loc49
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Converting(%x.param: %i32) -> out %return.param: %i64 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %x.ref: %i32 = name_ref x, %x
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %n.patt: %pattern_type.f57 = value_binding_pattern n [concrete = constants.%n.patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:   if %true br !match.case.then.loc61_28.1 else br !match.case.else
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc61_28.1:
// CHECK:STDOUT:   %impl.elem0.loc60: %.9a0 = impl_witness_access constants.%ImplicitAs.impl_witness.a40, element0 [concrete = constants.%From.as_type.as.ImplicitAs.impl.Convert.e3c]
// CHECK:STDOUT:   %bound_method.loc60_10.1: <bound method> = bound_method %x.ref, %impl.elem0.loc60
// CHECK:STDOUT:   %specific_fn.loc60: <specific function> = specific_function %impl.elem0.loc60, @From.as_type.as.ImplicitAs.impl.Convert(constants.%int_64, constants.%facet_value) [concrete = constants.%From.as_type.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc60_10.2: <bound method> = bound_method %x.ref, %specific_fn.loc60
// CHECK:STDOUT:   %From.as_type.as.ImplicitAs.impl.Convert.call: init %i64 = call %bound_method.loc60_10.2(%x.ref)
// CHECK:STDOUT:   %.loc60_10.1: %i64 = value_of_initializer %From.as_type.as.ImplicitAs.impl.Convert.call
// CHECK:STDOUT:   %.loc60_10.2: %i64 = converted %x.ref, %.loc60_10.1
// CHECK:STDOUT:   %i64.loc61: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:   %n: %i64 = wrapper_binding n, %.loc60_10.2
// CHECK:STDOUT:   %.loc61_23.1: bool = splice_block %.loc61_23.4 {
// CHECK:STDOUT:     %n.ref.loc61_21: %i64 = name_ref n, %n
// CHECK:STDOUT:     %int_0.loc61: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:     %impl.elem2: %.996 = impl_witness_access constants.%OrderedWith.impl_witness.b1d, element2 [concrete = constants.%Int.as.OrderedWith.impl.Greater.88ab7c.2]
// CHECK:STDOUT:     %bound_method.loc61_23.1: <bound method> = bound_method %n.ref.loc61_21, %impl.elem2
// CHECK:STDOUT:     %specific_fn.loc61_23: <specific function> = specific_function %impl.elem2, @Int.as.OrderedWith.impl.Greater.2(constants.%int_64, constants.%ImplicitAs.facet.6e8) [concrete = constants.%Int.as.OrderedWith.impl.Greater.specific_fn.07e5e7.1]
// CHECK:STDOUT:     %bound_method.loc61_23.2: <bound method> = bound_method %n.ref.loc61_21, %specific_fn.loc61_23
// CHECK:STDOUT:     %.loc61_23.2: %Int.as.OrderedWith.impl.Greater.type.002547.1 = specific_constant imports.%Core.Greater.28d, @Int.as.OrderedWith.impl.f36(constants.%int_64, constants.%ImplicitAs.facet.6e8) [concrete = constants.%Int.as.OrderedWith.impl.Greater.88ab7c.1]
// CHECK:STDOUT:     %Greater.ref: %Int.as.OrderedWith.impl.Greater.type.002547.1 = name_ref Greater, %.loc61_23.2 [concrete = constants.%Int.as.OrderedWith.impl.Greater.88ab7c.1]
// CHECK:STDOUT:     %Int.as.OrderedWith.impl.Greater.bound: <bound method> = bound_method %n.ref.loc61_21, %Greater.ref
// CHECK:STDOUT:     %Int.as.OrderedWith.impl.Greater.specific_fn: <specific function> = specific_function %Greater.ref, @Int.as.OrderedWith.impl.Greater.3(constants.%int_64, constants.%ImplicitAs.facet.6e8) [concrete = constants.%Int.as.OrderedWith.impl.Greater.specific_fn.07e5e7.2]
// CHECK:STDOUT:     %bound_method.loc61_23.3: <bound method> = bound_method %n.ref.loc61_21, %Int.as.OrderedWith.impl.Greater.specific_fn
// CHECK:STDOUT:     %impl.elem0.loc61_25: %.f349 = impl_witness_access constants.%ImplicitAs.impl_witness.091, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b]
// CHECK:STDOUT:     %bound_method.loc61_25.1: <bound method> = bound_method %int_0.loc61, %impl.elem0.loc61_25 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.0a3]
// CHECK:STDOUT:     %specific_fn.loc61_25: <specific function> = specific_function %impl.elem0.loc61_25, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.f33]
// CHECK:STDOUT:     %bound_method.loc61_25.2: <bound method> = bound_method %int_0.loc61, %specific_fn.loc61_25 [concrete = constants.%bound_method.0c1]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc61: init %i64 = call %bound_method.loc61_25.2(%int_0.loc61) [concrete = constants.%int_0.2e4]
// CHECK:STDOUT:     %.loc61_25.1: %i64 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc61 [concrete = constants.%int_0.2e4]
// CHECK:STDOUT:     %.loc61_25.2: %i64 = converted %int_0.loc61, %.loc61_25.1 [concrete = constants.%int_0.2e4]
// CHECK:STDOUT:     %Int.as.OrderedWith.impl.Greater.call: init bool = call %bound_method.loc61_23.3(%n.ref.loc61_21, %.loc61_25.2)
// CHECK:STDOUT:     %.loc61_23.3: bool = value_of_initializer %Int.as.OrderedWith.impl.Greater.call
// CHECK:STDOUT:     %.loc61_23.4: bool = converted %Int.as.OrderedWith.impl.Greater.call, %.loc61_23.3
// CHECK:STDOUT:   }
// CHECK:STDOUT:   if %.loc61_23.1 br !match.case.then.loc61_28.2 else br !match.case.else
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc61_28.2:
// CHECK:STDOUT:   %n.ref.loc61_40: %i64 = name_ref n, %n
// CHECK:STDOUT:   %impl.elem0.loc61_40: %.3cb = impl_witness_access constants.%Copy.impl_witness.c5e, element0 [concrete = constants.%Int.as.Copy.impl.Op.d73]
// CHECK:STDOUT:   %bound_method.loc61_40.1: <bound method> = bound_method %n.ref.loc61_40, %impl.elem0.loc61_40
// CHECK:STDOUT:   %specific_fn.loc61_40: <specific function> = specific_function %impl.elem0.loc61_40, @Int.as.Copy.impl.Op(constants.%int_64) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn.b95]
// CHECK:STDOUT:   %bound_method.loc61_40.2: <bound method> = bound_method %n.ref.loc61_40, %specific_fn.loc61_40
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i64 = call %bound_method.loc61_40.2(%n.ref.loc61_40)
// CHECK:STDOUT:   return %Int.as.Copy.impl.Op.call
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else:
// CHECK:STDOUT:   %int_0.loc62: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc62: %.f349 = impl_witness_access constants.%ImplicitAs.impl_witness.091, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b]
// CHECK:STDOUT:   %bound_method.loc62_26.1: <bound method> = bound_method %int_0.loc62, %impl.elem0.loc62 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.0a3]
// CHECK:STDOUT:   %specific_fn.loc62: <specific function> = specific_function %impl.elem0.loc62, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.f33]
// CHECK:STDOUT:   %bound_method.loc62_26.2: <bound method> = bound_method %int_0.loc62, %specific_fn.loc62 [concrete = constants.%bound_method.0c1]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc62: init %i64 = call %bound_method.loc62_26.2(%int_0.loc62) [concrete = constants.%int_0.2e4]
// CHECK:STDOUT:   %.loc62: init %i64 = converted %int_0.loc62, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc62 [concrete = constants.%int_0.2e4]
// CHECK:STDOUT:   return %.loc62
// CHECK:STDOUT: }
// CHECK:STDOUT:
