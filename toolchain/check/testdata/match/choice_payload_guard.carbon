// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/choice_payload_guard.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/choice_payload_guard.carbon

// A guard on a payload-destructuring alternative arm (re-platform plan
// S2d): the arm's test compares the discriminant, the bind pass extracts
// the payload and initializes the payload binding, and only then does the
// guard evaluate — with the payload binding in scope
// (docs/design/pattern_matching.md, "Guards"). A failed guard falls
// through to the next arm: the same alternative is matched twice — once
// guarded, once unguarded — so `.Ok` values split on the guard while
// `.Err` and `default` stay reachable.
//@dump-sem-ir-begin
choice IntResult {
  Ok(value: i32),
  Err
}

fn Consume(r: IntResult) -> i32 {
  match (r) {
    case .Ok(v: i32) if (v > 0) => { return v; }
    case .Ok(w: i32) => { return w - 1; }
    case .Err => { return -10; }
    default => { return -2; }
  }
  return -3;
}
//@dump-sem-ir-end

// CHECK:STDOUT: --- choice_payload_guard.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %IntResult: type = class_type @IntResult [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %Int.67af24.1: type = class_type @Int, @Int(%N) [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %u1: type = class_type @UInt, @UInt(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %tuple.type.a8a: type = tuple_type (%i32) [concrete]
// CHECK:STDOUT:   %.2a5: type = custom_layout_type {size=4, align=4, .Ok@0: %tuple.type.a8a} [concrete]
// CHECK:STDOUT:   %struct_type.discriminant.payload.898: type = struct_type {.discriminant: %u1, .payload: %.2a5} [concrete]
// CHECK:STDOUT:   %complete_type.697: <witness> = complete_type_witness %struct_type.discriminant.payload.898 [concrete]
// CHECK:STDOUT:   %struct_type.discriminant: type = struct_type {.discriminant: %u1} [concrete]
// CHECK:STDOUT:   %_.param_patt: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %_.patt: %pattern_type.6b6 = at_binding_pattern _, %_.param_patt [concrete]
// CHECK:STDOUT:   %.918: Core.Form = init_form %IntResult [concrete]
// CHECK:STDOUT:   %pattern_type.e14: type = pattern_type %IntResult [concrete]
// CHECK:STDOUT:   %return.param_patt.3e8: %pattern_type.e14 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.437: %pattern_type.e14 = return_slot_pattern %return.param_patt.3e8, %IntResult [concrete]
// CHECK:STDOUT:   %IntResult.Ok.type: type = fn_type @IntResult.Ok [concrete]
// CHECK:STDOUT:   %IntResult.Ok: %IntResult.Ok.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.ca1: type = facet_type <@ImplicitAs, @ImplicitAs(%u1)> [concrete]
// CHECK:STDOUT:   %To.fe9: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.170: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.9a9: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.42f, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.115: %ImplicitAs.type.ca1 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.9a9) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.19e: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%u1, %ImplicitAs.facet.115) [concrete]
// CHECK:STDOUT:   %.e60: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.19e, %ImplicitAs.facet.115 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.0e8: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
// CHECK:STDOUT:   %int_0.1a7: %u1 = int_value 0 [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.0e0: <witness> = impl_witness imports.%Copy.impl_witness_table.367, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet.987: %Copy.type = facet_value %i32, (%Copy.impl_witness.0e0) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.d09: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.987) [concrete]
// CHECK:STDOUT:   %.7a6: type = fn_type_with_self_type %Copy.WithSelf.Op.type.d09, %Copy.facet.987 [concrete]
// CHECK:STDOUT:   %.795: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %bound_method.d7a: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
// CHECK:STDOUT:   %int_1.233: %u1 = int_value 1 [concrete]
// CHECK:STDOUT:   %struct: %struct_type.discriminant = struct_value (%int_1.233) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.type.0c5: type = fn_type @UInt.as.Copy.impl.Op, @UInt.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.38a: %UInt.as.Copy.impl.Op.type.0c5 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.fb7: <witness> = impl_witness imports.%Copy.impl_witness_table.fe3, @UInt.as.Copy.impl(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.type.c97: type = fn_type @UInt.as.Copy.impl.Op, @UInt.as.Copy.impl(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.d9c: %UInt.as.Copy.impl.Op.type.c97 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet.771: %Copy.type = facet_value %u1, (%Copy.impl_witness.fb7) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.4d4: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.771) [concrete]
// CHECK:STDOUT:   %.37a: type = fn_type_with_self_type %Copy.WithSelf.Op.type.4d4, %Copy.facet.771 [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.bound: <bound method> = bound_method %int_1.233, %UInt.as.Copy.impl.Op.d9c [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %UInt.as.Copy.impl.Op.d9c, @UInt.as.Copy.impl.Op(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.edd: <bound method> = bound_method %int_1.233, %UInt.as.Copy.impl.Op.specific_fn [concrete]
// CHECK:STDOUT:   %uninit: %.2a5 = uninitialized_value [concrete]
// CHECK:STDOUT:   %IntResult.val: %IntResult = struct_value (%int_1.233, %uninit) [concrete]
// CHECK:STDOUT:   %.942: ref %IntResult = temporary invalid, %IntResult.val [concrete]
// CHECK:STDOUT:   %r.param_patt: %pattern_type.e14 = value_param_pattern [concrete]
// CHECK:STDOUT:   %r.patt: %pattern_type.e14 = at_binding_pattern r, %r.param_patt [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %Consume.type: type = fn_type @Consume [concrete]
// CHECK:STDOUT:   %Consume: %Consume.type = struct_value () [concrete]
// CHECK:STDOUT:   %v.patt: %pattern_type.6b6 = value_binding_pattern v [concrete]
// CHECK:STDOUT:   %pattern_type.e71: type = pattern_type %tuple.type.a8a [concrete]
// CHECK:STDOUT:   %.13b: %pattern_type.e71 = tuple_pattern (%v.patt) [concrete]
// CHECK:STDOUT:   %OrderedWith.type.975: type = facet_type <@OrderedWith, @OrderedWith(Core.IntLiteral)> [concrete]
// CHECK:STDOUT:   %M: Core.IntLiteral = symbolic_binding M, 1 [symbolic]
// CHECK:STDOUT:   %ImplicitAs.type.f7de31.1: type = facet_type <@ImplicitAs, @ImplicitAs(%Int.67af24.1)> [symbolic]
// CHECK:STDOUT:   %T.4e6: %ImplicitAs.type.f7de31.1 = symbolic_binding T, 1 [symbolic]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.type.18c27f.1: type = fn_type @Int.as.OrderedWith.impl.Greater.2, @Int.as.OrderedWith.impl.f36(%N, %T.4e6) [symbolic]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.cbccb6.1: %Int.as.OrderedWith.impl.Greater.type.18c27f.1 = struct_value () [symbolic]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.type.18c27f.2: type = fn_type @Int.as.OrderedWith.impl.Greater.3, @Int.as.OrderedWith.impl.f36(%N, %T.4e6) [symbolic]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.cbccb6.2: %Int.as.OrderedWith.impl.Greater.type.18c27f.2 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a23: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.b3c, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.9f1: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a23) [concrete]
// CHECK:STDOUT:   %OrderedWith.impl_witness.a3c: <witness> = impl_witness imports.%OrderedWith.impl_witness_table.091, @Int.as.OrderedWith.impl.f36(%int_32, %ImplicitAs.facet.9f1) [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.type.c37381.1: type = fn_type @Int.as.OrderedWith.impl.Greater.3, @Int.as.OrderedWith.impl.f36(%int_32, %ImplicitAs.facet.9f1) [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.3fec66.1: %Int.as.OrderedWith.impl.Greater.type.c37381.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.type.c37381.2: type = fn_type @Int.as.OrderedWith.impl.Greater.2, @Int.as.OrderedWith.impl.f36(%int_32, %ImplicitAs.facet.9f1) [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.3fec66.2: %Int.as.OrderedWith.impl.Greater.type.c37381.2 = struct_value () [concrete]
// CHECK:STDOUT:   %OrderedWith.facet.14b: %OrderedWith.type.975 = facet_value %i32, (%OrderedWith.impl_witness.a3c) [concrete]
// CHECK:STDOUT:   %OrderedWith.WithSelf.Greater.type.a92: type = fn_type @OrderedWith.WithSelf.Greater, @OrderedWith.WithSelf(Core.IntLiteral, %OrderedWith.facet.14b) [concrete]
// CHECK:STDOUT:   %.1d6: type = fn_type_with_self_type %OrderedWith.WithSelf.Greater.type.a92, %OrderedWith.facet.14b [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.specific_fn.a67ca5.1: <specific function> = specific_function %Int.as.OrderedWith.impl.Greater.3fec66.2, @Int.as.OrderedWith.impl.Greater.2(%int_32, %ImplicitAs.facet.9f1) [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.specific_fn.a67ca5.2: <specific function> = specific_function %Int.as.OrderedWith.impl.Greater.3fec66.1, @Int.as.OrderedWith.impl.Greater.3(%int_32, %ImplicitAs.facet.9f1) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.740: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet.9f1) [concrete]
// CHECK:STDOUT:   %.1c5: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.740, %ImplicitAs.facet.9f1 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.6e0: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_0.3c0: %i32 = int_value 0 [concrete]
// CHECK:STDOUT:   %EqWith.type.c25: type = facet_type <@EqWith, @EqWith(%u1)> [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.544: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%N, %M) [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.c67: %UInt.as.EqWith.impl.Equal.type.544 = struct_value () [symbolic]
// CHECK:STDOUT:   %EqWith.impl_witness.d63: <witness> = impl_witness imports.%EqWith.impl_witness_table.cbd, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.29b: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.ba4: %UInt.as.EqWith.impl.Equal.type.29b = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.3b6: %EqWith.type.c25 = facet_value %u1, (%EqWith.impl_witness.d63) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.922: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%u1, %EqWith.facet.3b6) [concrete]
// CHECK:STDOUT:   %.9ed: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.922, %EqWith.facet.3b6 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound.f34: <bound method> = bound_method %int_0.1a7, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.specific_fn.6b6: <specific function> = specific_function %UInt.as.EqWith.impl.Equal.ba4, @UInt.as.EqWith.impl.Equal.1(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.53a: <bound method> = bound_method %int_0.1a7, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
// CHECK:STDOUT:   %w.patt: %pattern_type.6b6 = value_binding_pattern w [concrete]
// CHECK:STDOUT:   %.849: %pattern_type.e71 = tuple_pattern (%w.patt) [concrete]
// CHECK:STDOUT:   %SubWith.type.4c2: type = facet_type <@SubWith, @SubWith(Core.IntLiteral)> [concrete]
// CHECK:STDOUT:   %U.4e6: %ImplicitAs.type.f7de31.1 = symbolic_binding U, 1 [symbolic]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.type.409f5c.1: type = fn_type @Int.as.SubWith.impl.Op.2, @Int.as.SubWith.impl.e74(%N, %U.4e6) [symbolic]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.4b8395.1: %Int.as.SubWith.impl.Op.type.409f5c.1 = struct_value () [symbolic]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.type.409f5c.2: type = fn_type @Int.as.SubWith.impl.Op.3, @Int.as.SubWith.impl.e74(%N, %U.4e6) [symbolic]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.4b8395.2: %Int.as.SubWith.impl.Op.type.409f5c.2 = struct_value () [symbolic]
// CHECK:STDOUT:   %SubWith.impl_witness.45c: <witness> = impl_witness imports.%SubWith.impl_witness_table.931, @Int.as.SubWith.impl.e74(%int_32, %ImplicitAs.facet.9f1) [concrete]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.type.6ebef3.1: type = fn_type @Int.as.SubWith.impl.Op.3, @Int.as.SubWith.impl.e74(%int_32, %ImplicitAs.facet.9f1) [concrete]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.09063a.1: %Int.as.SubWith.impl.Op.type.6ebef3.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.type.6ebef3.2: type = fn_type @Int.as.SubWith.impl.Op.2, @Int.as.SubWith.impl.e74(%int_32, %ImplicitAs.facet.9f1) [concrete]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.09063a.2: %Int.as.SubWith.impl.Op.type.6ebef3.2 = struct_value () [concrete]
// CHECK:STDOUT:   %SubWith.facet.962: %SubWith.type.4c2 = facet_value %i32, (%SubWith.impl_witness.45c) [concrete]
// CHECK:STDOUT:   %SubWith.WithSelf.Op.type.a25: type = fn_type @SubWith.WithSelf.Op, @SubWith.WithSelf(Core.IntLiteral, %SubWith.facet.962) [concrete]
// CHECK:STDOUT:   %.298: type = fn_type_with_self_type %SubWith.WithSelf.Op.type.a25, %SubWith.facet.962 [concrete]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.specific_fn.b38ba1.1: <specific function> = specific_function %Int.as.SubWith.impl.Op.09063a.2, @Int.as.SubWith.impl.Op.2(%int_32, %ImplicitAs.facet.9f1) [concrete]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.specific_fn.b38ba1.2: <specific function> = specific_function %Int.as.SubWith.impl.Op.09063a.1, @Int.as.SubWith.impl.Op.3(%int_32, %ImplicitAs.facet.9f1) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.953: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound.22c: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %bound_method.a82: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
// CHECK:STDOUT:   %int_10: Core.IntLiteral = int_value 10 [concrete]
// CHECK:STDOUT:   %Negate.type: type = facet_type <@Negate> [concrete]
// CHECK:STDOUT:   %Negate.impl_witness: <witness> = impl_witness imports.%Negate.impl_witness_table [concrete]
// CHECK:STDOUT:   %Negate.facet: %Negate.type = facet_value Core.IntLiteral, (%Negate.impl_witness) [concrete]
// CHECK:STDOUT:   %Negate.WithSelf.Op.type.f03: type = fn_type @Negate.WithSelf.Op, @Negate.WithSelf(%Negate.facet) [concrete]
// CHECK:STDOUT:   %.02b: type = fn_type_with_self_type %Negate.WithSelf.Op.type.f03, %Negate.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.type: type = fn_type @Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op: %Core.IntLiteral.as.Negate.impl.Op.type = struct_value () [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.bound.599: <bound method> = bound_method %int_10, %Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %int_-10.06d: Core.IntLiteral = int_value -10 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.f93: <bound method> = bound_method %int_-10.06d, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.27d: <bound method> = bound_method %int_-10.06d, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_-10.642: %i32 = int_value -10 [concrete]
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.bound.e21: <bound method> = bound_method %int_2, %Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %int_-2.962: Core.IntLiteral = int_value -2 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.2a0: <bound method> = bound_method %int_-2.962, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.33f: <bound method> = bound_method %int_-2.962, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_-2.c83: %i32 = int_value -2 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.aa5: @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.170)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.42f = impl_witness_table (%Core.import_ref.aa5), @Core.IntLiteral.as.ImplicitAs.impl.b68 [concrete]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.367 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.791: @UInt.as.Copy.impl.%UInt.as.Copy.impl.Op.type (%UInt.as.Copy.impl.Op.type.0c5) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.Copy.impl.%UInt.as.Copy.impl.Op (constants.%UInt.as.Copy.impl.Op.38a)]
// CHECK:STDOUT:   %Copy.impl_witness_table.fe3 = impl_witness_table (%Core.import_ref.791), @UInt.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.0e6 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.f9df = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.0ab: @Int.as.OrderedWith.impl.f36.%Int.as.OrderedWith.impl.Greater.type.2 (%Int.as.OrderedWith.impl.Greater.type.18c27f.1) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.OrderedWith.impl.f36.%Int.as.OrderedWith.impl.Greater.2 (constants.%Int.as.OrderedWith.impl.Greater.cbccb6.1)]
// CHECK:STDOUT:   %Core.import_ref.b56 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %OrderedWith.impl_witness_table.091 = impl_witness_table (%Core.import_ref.0e6, %Core.import_ref.f9df, %Core.import_ref.0ab, %Core.import_ref.b56), @Int.as.OrderedWith.impl.f36 [concrete]
// CHECK:STDOUT:   %Core.Greater.28d: @Int.as.OrderedWith.impl.f36.%Int.as.OrderedWith.impl.Greater.type.1 (%Int.as.OrderedWith.impl.Greater.type.18c27f.2) = import_ref Core//prelude/types/int, Greater, loaded [symbolic = @Int.as.OrderedWith.impl.f36.%Int.as.OrderedWith.impl.Greater.1 (constants.%Int.as.OrderedWith.impl.Greater.cbccb6.2)]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.b3c = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.b92: @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal.type (%UInt.as.EqWith.impl.Equal.type.544) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal (constants.%UInt.as.EqWith.impl.Equal.c67)]
// CHECK:STDOUT:   %Core.import_ref.b44 = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.cbd = impl_witness_table (%Core.import_ref.b92, %Core.import_ref.b44), @UInt.as.EqWith.impl.f13 [concrete]
// CHECK:STDOUT:   %Core.import_ref.b4fd3a.2 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.875: @Int.as.SubWith.impl.e74.%Int.as.SubWith.impl.Op.type.2 (%Int.as.SubWith.impl.Op.type.409f5c.1) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.SubWith.impl.e74.%Int.as.SubWith.impl.Op.2 (constants.%Int.as.SubWith.impl.Op.4b8395.1)]
// CHECK:STDOUT:   %SubWith.impl_witness_table.931 = impl_witness_table (%Core.import_ref.b4fd3a.2, %Core.import_ref.875), @Int.as.SubWith.impl.e74 [concrete]
// CHECK:STDOUT:   %Core.Op.33f: @Int.as.SubWith.impl.e74.%Int.as.SubWith.impl.Op.type.1 (%Int.as.SubWith.impl.Op.type.409f5c.2) = import_ref Core//prelude/types/int, Op, loaded [symbolic = @Int.as.SubWith.impl.e74.%Int.as.SubWith.impl.Op.1 (constants.%Int.as.SubWith.impl.Op.4b8395.2)]
// CHECK:STDOUT:   %Core.import_ref.abd = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9c3: %Core.IntLiteral.as.Negate.impl.Op.type = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, loaded [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %Negate.impl_witness_table = impl_witness_table (%Core.import_ref.abd, %Core.import_ref.9c3), @Core.IntLiteral.as.Negate.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %IntResult.Ok.decl: %IntResult.Ok.type = fn_decl @IntResult.Ok [concrete = constants.%IntResult.Ok] {
// CHECK:STDOUT:     %_.param_patt: %pattern_type.6b6 = value_param_pattern [concrete = constants.%_.param_patt]
// CHECK:STDOUT:     %_.patt: %pattern_type.6b6 = at_binding_pattern _, %_.param_patt [concrete = constants.%_.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.e14 = out_param_pattern [concrete = constants.%return.param_patt.3e8]
// CHECK:STDOUT:     %return.patt: %pattern_type.e14 = return_slot_pattern %return.param_patt, constants.%IntResult [concrete = constants.%return.patt.437]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc22_18.9: Core.Form = init_form constants.%IntResult [concrete = constants.%.918]
// CHECK:STDOUT:     %_.param: %i32 = value_param call_param0
// CHECK:STDOUT:     %_: %i32 = wrapper_binding _, %_.param
// CHECK:STDOUT:     %return.param: ref %IntResult = out_param call_param1
// CHECK:STDOUT:     %return: ref %IntResult = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %IntResult.decl: type = class_decl @IntResult [concrete = constants.%IntResult] {} {}
// CHECK:STDOUT:   %Consume.decl: %Consume.type = fn_decl @Consume [concrete = constants.%Consume] {
// CHECK:STDOUT:     %r.param_patt: %pattern_type.e14 = value_param_pattern [concrete = constants.%r.param_patt]
// CHECK:STDOUT:     %r.patt: %pattern_type.e14 = at_binding_pattern r, %r.param_patt [concrete = constants.%r.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc27 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc27: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc27: Core.Form = init_form %i32.loc27 [concrete = constants.%.795]
// CHECK:STDOUT:     %r.param: %IntResult = value_param call_param0
// CHECK:STDOUT:     %IntResult.ref: type = name_ref IntResult, file.%IntResult.decl [concrete = constants.%IntResult]
// CHECK:STDOUT:     %r: %IntResult = wrapper_binding r, %r.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: class @IntResult {
// CHECK:STDOUT:   %value.param: %i32 = value_param call_param0
// CHECK:STDOUT:   %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %value: %i32 = wrapper_binding value, %value.param
// CHECK:STDOUT:   %.loc25_1.1: type = custom_layout_type {size=4, align=4, .Ok@0: %tuple.type.a8a} [concrete = constants.%.2a5]
// CHECK:STDOUT:   %complete_type: <witness> = complete_type_witness constants.%struct_type.discriminant.payload.898 [concrete = constants.%complete_type.697]
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc25_1.1: %.e60 = impl_witness_access constants.%ImplicitAs.impl_witness.9a9, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc25_1.1: <bound method> = bound_method %int_1, %impl.elem0.loc25_1.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc25_1.1: <specific function> = specific_function %impl.elem0.loc25_1.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc25_1.2: <bound method> = bound_method %int_1, %specific_fn.loc25_1.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %u1 = call %bound_method.loc25_1.2(%int_1) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc25_1.2: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc25_1.3: %u1 = converted %int_1, %.loc25_1.2 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc25_1.4: %struct_type.discriminant = struct_literal (%.loc25_1.3) [concrete = constants.%struct]
// CHECK:STDOUT:   %impl.elem0.loc25_1.2: %.37a = impl_witness_access constants.%Copy.impl_witness.fb7, element0 [concrete = constants.%UInt.as.Copy.impl.Op.d9c]
// CHECK:STDOUT:   %bound_method.loc25_1.3: <bound method> = bound_method %.loc25_1.3, %impl.elem0.loc25_1.2 [concrete = constants.%UInt.as.Copy.impl.Op.bound]
// CHECK:STDOUT:   %specific_fn.loc25_1.2: <specific function> = specific_function %impl.elem0.loc25_1.2, @UInt.as.Copy.impl.Op(constants.%int_1.5b8) [concrete = constants.%UInt.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc25_1.4: <bound method> = bound_method %.loc25_1.3, %specific_fn.loc25_1.2 [concrete = constants.%bound_method.edd]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.call: init %u1 = call %bound_method.loc25_1.4(%.loc25_1.3) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc25_1.5: ref %IntResult = temporary_storage
// CHECK:STDOUT:   %.loc25_1.6: ref %u1 = class_element_access %.loc25_1.5, element0
// CHECK:STDOUT:   %.loc25_1.7: init %u1 to %.loc25_1.6 = in_place_init %UInt.as.Copy.impl.Op.call [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc25_1.8: ref %.2a5 = class_element_access %.loc25_1.5, element1
// CHECK:STDOUT:   %uninit: %.2a5 = uninitialized_value [concrete = constants.%uninit]
// CHECK:STDOUT:   %.loc25_1.9: init %.2a5 to %.loc25_1.8 = in_place_init %uninit [concrete = constants.%uninit]
// CHECK:STDOUT:   %.loc25_1.10: init %IntResult to %.loc25_1.5 = class_init (%.loc25_1.7, %.loc25_1.9) [concrete = constants.%IntResult.val]
// CHECK:STDOUT:   %.loc25_1.11: init %IntResult = converted %.loc25_1.4, %.loc25_1.10 [concrete = constants.%IntResult.val]
// CHECK:STDOUT:   %.loc25_1.12: ref %IntResult = temporary %.loc25_1.5, %.loc25_1.11 [concrete = constants.%.942]
// CHECK:STDOUT:   %.loc25_1.13: %IntResult = acquire_value %.loc25_1.12 [concrete = constants.%IntResult.val]
// CHECK:STDOUT:   %Err: %IntResult = wrapper_binding Err, %.loc25_1.13
// CHECK:STDOUT:   complete_type_witness = %complete_type
// CHECK:STDOUT:
// CHECK:STDOUT: !members:
// CHECK:STDOUT:   .Self = constants.%IntResult
// CHECK:STDOUT:   .Ok = generated.%IntResult.Ok.decl
// CHECK:STDOUT:   .Err = %Err
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @IntResult.Ok(%_.param: %i32) -> out %return.param: %IntResult {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %.loc22_18.1: ref %u1 = class_element_access %return.param, element0
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc22_18.1: %.e60 = impl_witness_access constants.%ImplicitAs.impl_witness.9a9, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc22_18.1: <bound method> = bound_method %int_0, %impl.elem0.loc22_18.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:   %specific_fn.loc22_18.1: <specific function> = specific_function %impl.elem0.loc22_18.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc22_18.2: <bound method> = bound_method %int_0, %specific_fn.loc22_18.1 [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %u1 = call %bound_method.loc22_18.2(%int_0) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc22_18.2: init %u1 = converted %int_0, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc22_18.3: init %u1 to %.loc22_18.1 = in_place_init %.loc22_18.2 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc22_18.4: ref %.2a5 = class_element_access %return.param, element1
// CHECK:STDOUT:   %.loc22_18.5: ref %tuple.type.a8a = class_element_access %.loc22_18.4, element0
// CHECK:STDOUT:   %.loc23_17.1: %tuple.type.a8a = tuple_literal (%_.param)
// CHECK:STDOUT:   %impl.elem0.loc22_18.2: %.7a6 = impl_witness_access constants.%Copy.impl_witness.0e0, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc22_18.3: <bound method> = bound_method %_.param, %impl.elem0.loc22_18.2
// CHECK:STDOUT:   %specific_fn.loc22_18.2: <specific function> = specific_function %impl.elem0.loc22_18.2, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc22_18.4: <bound method> = bound_method %_.param, %specific_fn.loc22_18.2
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc22_18.4(%_.param)
// CHECK:STDOUT:   %.loc23_17.2: init %tuple.type.a8a to %.loc22_18.5 = tuple_init (%Int.as.Copy.impl.Op.call)
// CHECK:STDOUT:   %.loc22_18.6: init %tuple.type.a8a = converted %.loc23_17.1, %.loc23_17.2
// CHECK:STDOUT:   %.loc22_18.7: init %tuple.type.a8a to %.loc22_18.5 = in_place_init %.loc22_18.6
// CHECK:STDOUT:   %.loc22_18.8: init %IntResult to %return.param = class_init (%.loc22_18.3, %.loc22_18.7)
// CHECK:STDOUT:   return %.loc22_18.8 to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Consume(%r.param: %IntResult) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %r.ref: %IntResult = name_ref r, %r
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %v.patt: %pattern_type.6b6 = value_binding_pattern v [concrete = constants.%v.patt]
// CHECK:STDOUT:     %.loc29_15: %pattern_type.e71 = tuple_pattern (%v.patt) [concrete = constants.%.13b]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_0.loc29_33: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc29_33.1: %.e60 = impl_witness_access constants.%ImplicitAs.impl_witness.9a9, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc29_33.1: <bound method> = bound_method %int_0.loc29_33, %impl.elem0.loc29_33.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:   %specific_fn.loc29_33.1: <specific function> = specific_function %impl.elem0.loc29_33.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc29_33.2: <bound method> = bound_method %int_0.loc29_33, %specific_fn.loc29_33.1 [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc29_33: init %u1 = call %bound_method.loc29_33.2(%int_0.loc29_33) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc29_33.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc29_33 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc29_33.2: %u1 = converted %int_0.loc29_33, %.loc29_33.1 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc29_33.3: ref %u1 = class_element_access %r.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc29_33.2: %.9ed = impl_witness_access constants.%EqWith.impl_witness.d63, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc29_33.3: <bound method> = bound_method %.loc29_33.2, %impl.elem0.loc29_33.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.f34]
// CHECK:STDOUT:   %specific_fn.loc29_33.2: <specific function> = specific_function %impl.elem0.loc29_33.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc29_33.4: <bound method> = bound_method %.loc29_33.2, %specific_fn.loc29_33.2 [concrete = constants.%bound_method.53a]
// CHECK:STDOUT:   %.loc29_33.4: %u1 = acquire_value %.loc29_33.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc29: init bool = call %bound_method.loc29_33.4(%.loc29_33.2, %.loc29_33.4)
// CHECK:STDOUT:   %.loc29_33.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc29
// CHECK:STDOUT:   %.loc29_33.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc29, %.loc29_33.5
// CHECK:STDOUT:   if %.loc29_33.6 br !match.case.then.loc29_33.1 else br !match.case.else.loc29
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc29_33.1:
// CHECK:STDOUT:   %.loc29_33.7: ref %.2a5 = class_element_access %r.ref, element1
// CHECK:STDOUT:   %.loc29_33.8: ref %tuple.type.a8a = class_element_access %.loc29_33.7, element0
// CHECK:STDOUT:   %tuple.elem0.loc29: ref %i32 = tuple_access %.loc29_33.8, element0
// CHECK:STDOUT:   %.loc29_33.9: %i32 = acquire_value %tuple.elem0.loc29
// CHECK:STDOUT:   %i32.loc29: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %v: %i32 = wrapper_binding v, %.loc29_33.9
// CHECK:STDOUT:   %.loc29_28.1: bool = splice_block %.loc29_28.4 {
// CHECK:STDOUT:     %v.ref.loc29_26: %i32 = name_ref v, %v
// CHECK:STDOUT:     %int_0.loc29_30: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:     %impl.elem2: %.1d6 = impl_witness_access constants.%OrderedWith.impl_witness.a3c, element2 [concrete = constants.%Int.as.OrderedWith.impl.Greater.3fec66.2]
// CHECK:STDOUT:     %bound_method.loc29_28.1: <bound method> = bound_method %v.ref.loc29_26, %impl.elem2
// CHECK:STDOUT:     %specific_fn.loc29_28: <specific function> = specific_function %impl.elem2, @Int.as.OrderedWith.impl.Greater.2(constants.%int_32, constants.%ImplicitAs.facet.9f1) [concrete = constants.%Int.as.OrderedWith.impl.Greater.specific_fn.a67ca5.1]
// CHECK:STDOUT:     %bound_method.loc29_28.2: <bound method> = bound_method %v.ref.loc29_26, %specific_fn.loc29_28
// CHECK:STDOUT:     %.loc29_28.2: %Int.as.OrderedWith.impl.Greater.type.c37381.1 = specific_constant imports.%Core.Greater.28d, @Int.as.OrderedWith.impl.f36(constants.%int_32, constants.%ImplicitAs.facet.9f1) [concrete = constants.%Int.as.OrderedWith.impl.Greater.3fec66.1]
// CHECK:STDOUT:     %Greater.ref: %Int.as.OrderedWith.impl.Greater.type.c37381.1 = name_ref Greater, %.loc29_28.2 [concrete = constants.%Int.as.OrderedWith.impl.Greater.3fec66.1]
// CHECK:STDOUT:     %Int.as.OrderedWith.impl.Greater.bound: <bound method> = bound_method %v.ref.loc29_26, %Greater.ref
// CHECK:STDOUT:     %Int.as.OrderedWith.impl.Greater.specific_fn: <specific function> = specific_function %Greater.ref, @Int.as.OrderedWith.impl.Greater.3(constants.%int_32, constants.%ImplicitAs.facet.9f1) [concrete = constants.%Int.as.OrderedWith.impl.Greater.specific_fn.a67ca5.2]
// CHECK:STDOUT:     %bound_method.loc29_28.3: <bound method> = bound_method %v.ref.loc29_26, %Int.as.OrderedWith.impl.Greater.specific_fn
// CHECK:STDOUT:     %impl.elem0.loc29_30: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:     %bound_method.loc29_30.1: <bound method> = bound_method %int_0.loc29_30, %impl.elem0.loc29_30 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:     %specific_fn.loc29_30: <specific function> = specific_function %impl.elem0.loc29_30, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:     %bound_method.loc29_30.2: <bound method> = bound_method %int_0.loc29_30, %specific_fn.loc29_30 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc29_30: init %i32 = call %bound_method.loc29_30.2(%int_0.loc29_30) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:     %.loc29_30.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc29_30 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:     %.loc29_30.2: %i32 = converted %int_0.loc29_30, %.loc29_30.1 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:     %Int.as.OrderedWith.impl.Greater.call: init bool = call %bound_method.loc29_28.3(%v.ref.loc29_26, %.loc29_30.2)
// CHECK:STDOUT:     %.loc29_28.3: bool = value_of_initializer %Int.as.OrderedWith.impl.Greater.call
// CHECK:STDOUT:     %.loc29_28.4: bool = converted %Int.as.OrderedWith.impl.Greater.call, %.loc29_28.3
// CHECK:STDOUT:   }
// CHECK:STDOUT:   if %.loc29_28.1 br !match.case.then.loc29_33.2 else br !match.case.else.loc29
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc29_33.2:
// CHECK:STDOUT:   %v.ref.loc29_45: %i32 = name_ref v, %v
// CHECK:STDOUT:   %impl.elem0.loc29_45: %.7a6 = impl_witness_access constants.%Copy.impl_witness.0e0, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc29_45.1: <bound method> = bound_method %v.ref.loc29_45, %impl.elem0.loc29_45
// CHECK:STDOUT:   %specific_fn.loc29_45: <specific function> = specific_function %impl.elem0.loc29_45, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc29_45.2: <bound method> = bound_method %v.ref.loc29_45, %specific_fn.loc29_45
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc29_45.2(%v.ref.loc29_45)
// CHECK:STDOUT:   return %Int.as.Copy.impl.Op.call
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc29:
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %w.patt: %pattern_type.6b6 = value_binding_pattern w [concrete = constants.%w.patt]
// CHECK:STDOUT:     %.loc30_15: %pattern_type.e71 = tuple_pattern (%w.patt) [concrete = constants.%.849]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_0.loc30: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc30_22.1: %.e60 = impl_witness_access constants.%ImplicitAs.impl_witness.9a9, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc30_22.1: <bound method> = bound_method %int_0.loc30, %impl.elem0.loc30_22.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:   %specific_fn.loc30_22.1: <specific function> = specific_function %impl.elem0.loc30_22.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc30_22.2: <bound method> = bound_method %int_0.loc30, %specific_fn.loc30_22.1 [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc30_22: init %u1 = call %bound_method.loc30_22.2(%int_0.loc30) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc30_22.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc30_22 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc30_22.2: %u1 = converted %int_0.loc30, %.loc30_22.1 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc30_22.3: ref %u1 = class_element_access %r.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc30_22.2: %.9ed = impl_witness_access constants.%EqWith.impl_witness.d63, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc30_22.3: <bound method> = bound_method %.loc30_22.2, %impl.elem0.loc30_22.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.f34]
// CHECK:STDOUT:   %specific_fn.loc30_22.2: <specific function> = specific_function %impl.elem0.loc30_22.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc30_22.4: <bound method> = bound_method %.loc30_22.2, %specific_fn.loc30_22.2 [concrete = constants.%bound_method.53a]
// CHECK:STDOUT:   %.loc30_22.4: %u1 = acquire_value %.loc30_22.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc30: init bool = call %bound_method.loc30_22.4(%.loc30_22.2, %.loc30_22.4)
// CHECK:STDOUT:   %.loc30_22.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc30
// CHECK:STDOUT:   %.loc30_22.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc30, %.loc30_22.5
// CHECK:STDOUT:   if %.loc30_22.6 br !match.case.then.loc30 else br !match.case.else.loc30
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc30:
// CHECK:STDOUT:   %.loc30_22.7: ref %.2a5 = class_element_access %r.ref, element1
// CHECK:STDOUT:   %.loc30_22.8: ref %tuple.type.a8a = class_element_access %.loc30_22.7, element0
// CHECK:STDOUT:   %tuple.elem0.loc30: ref %i32 = tuple_access %.loc30_22.8, element0
// CHECK:STDOUT:   %.loc30_22.9: %i32 = acquire_value %tuple.elem0.loc30
// CHECK:STDOUT:   %i32.loc30: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %w: %i32 = wrapper_binding w, %.loc30_22.9
// CHECK:STDOUT:   %w.ref: %i32 = name_ref w, %w
// CHECK:STDOUT:   %int_1.loc30: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem1.loc30: %.298 = impl_witness_access constants.%SubWith.impl_witness.45c, element1 [concrete = constants.%Int.as.SubWith.impl.Op.09063a.2]
// CHECK:STDOUT:   %bound_method.loc30_36.1: <bound method> = bound_method %w.ref, %impl.elem1.loc30
// CHECK:STDOUT:   %specific_fn.loc30_36: <specific function> = specific_function %impl.elem1.loc30, @Int.as.SubWith.impl.Op.2(constants.%int_32, constants.%ImplicitAs.facet.9f1) [concrete = constants.%Int.as.SubWith.impl.Op.specific_fn.b38ba1.1]
// CHECK:STDOUT:   %bound_method.loc30_36.2: <bound method> = bound_method %w.ref, %specific_fn.loc30_36
// CHECK:STDOUT:   %.loc30_36: %Int.as.SubWith.impl.Op.type.6ebef3.1 = specific_constant imports.%Core.Op.33f, @Int.as.SubWith.impl.e74(constants.%int_32, constants.%ImplicitAs.facet.9f1) [concrete = constants.%Int.as.SubWith.impl.Op.09063a.1]
// CHECK:STDOUT:   %Op.ref: %Int.as.SubWith.impl.Op.type.6ebef3.1 = name_ref Op, %.loc30_36 [concrete = constants.%Int.as.SubWith.impl.Op.09063a.1]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.bound: <bound method> = bound_method %w.ref, %Op.ref
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.specific_fn: <specific function> = specific_function %Op.ref, @Int.as.SubWith.impl.Op.3(constants.%int_32, constants.%ImplicitAs.facet.9f1) [concrete = constants.%Int.as.SubWith.impl.Op.specific_fn.b38ba1.2]
// CHECK:STDOUT:   %bound_method.loc30_36.3: <bound method> = bound_method %w.ref, %Int.as.SubWith.impl.Op.specific_fn
// CHECK:STDOUT:   %impl.elem0.loc30_38: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc30_38.1: <bound method> = bound_method %int_1.loc30, %impl.elem0.loc30_38 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc30_38: <specific function> = specific_function %impl.elem0.loc30_38, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc30_38.2: <bound method> = bound_method %int_1.loc30, %specific_fn.loc30_38 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc30_38: init %i32 = call %bound_method.loc30_38.2(%int_1.loc30) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc30_38.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc30_38 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc30_38.2: %i32 = converted %int_1.loc30, %.loc30_38.1 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %Int.as.SubWith.impl.Op.call: init %i32 = call %bound_method.loc30_36.3(%w.ref, %.loc30_38.2)
// CHECK:STDOUT:   return %Int.as.SubWith.impl.Op.call
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc30:
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt: %pattern_type.e14 = expr_pattern %Err.ref in [concrete] {
// CHECK:STDOUT:       %Err.ref: %IntResult = name_ref Err, @IntResult.%Err
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Err.ref: %IntResult = name_ref Err, @IntResult.%Err
// CHECK:STDOUT:   %int_1.loc31: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc31_15.1: %.e60 = impl_witness_access constants.%ImplicitAs.impl_witness.9a9, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc31_15.1: <bound method> = bound_method %int_1.loc31, %impl.elem0.loc31_15.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc31_15.1: <specific function> = specific_function %impl.elem0.loc31_15.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc31_15.2: <bound method> = bound_method %int_1.loc31, %specific_fn.loc31_15.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc31_15: init %u1 = call %bound_method.loc31_15.2(%int_1.loc31) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc31_15.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc31_15 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc31_15.2: %u1 = converted %int_1.loc31, %.loc31_15.1 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc31_15.3: ref %u1 = class_element_access %r.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc31_15.2: %.9ed = impl_witness_access constants.%EqWith.impl_witness.d63, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc31_15.3: <bound method> = bound_method %.loc31_15.2, %impl.elem0.loc31_15.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.22c]
// CHECK:STDOUT:   %specific_fn.loc31_15.2: <specific function> = specific_function %impl.elem0.loc31_15.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc31_15.4: <bound method> = bound_method %.loc31_15.2, %specific_fn.loc31_15.2 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc31_15.4: %u1 = acquire_value %.loc31_15.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc31: init bool = call %bound_method.loc31_15.4(%.loc31_15.2, %.loc31_15.4)
// CHECK:STDOUT:   %.loc31_15.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc31
// CHECK:STDOUT:   %.loc31_15.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc31, %.loc31_15.5
// CHECK:STDOUT:   if %.loc31_15.6 br !match.case.then.loc31 else br !match.case.else.loc31
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc31:
// CHECK:STDOUT:   %int_10: Core.IntLiteral = int_value 10 [concrete = constants.%int_10]
// CHECK:STDOUT:   %impl.elem1.loc31: %.02b = impl_witness_access constants.%Negate.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %bound_method.loc31_27: <bound method> = bound_method %int_10, %impl.elem1.loc31 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op.bound.599]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.call.loc31: init Core.IntLiteral = call %bound_method.loc31_27(%int_10) [concrete = constants.%int_-10.06d]
// CHECK:STDOUT:   %impl.elem0.loc31_30: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc31_30.1: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call.loc31, %impl.elem0.loc31_30 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.f93]
// CHECK:STDOUT:   %specific_fn.loc31_30: <specific function> = specific_function %impl.elem0.loc31_30, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc31_30.2: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call.loc31, %specific_fn.loc31_30 [concrete = constants.%bound_method.27d]
// CHECK:STDOUT:   %.loc31_27.1: Core.IntLiteral = value_of_initializer %Core.IntLiteral.as.Negate.impl.Op.call.loc31 [concrete = constants.%int_-10.06d]
// CHECK:STDOUT:   %.loc31_27.2: Core.IntLiteral = converted %Core.IntLiteral.as.Negate.impl.Op.call.loc31, %.loc31_27.1 [concrete = constants.%int_-10.06d]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc31_30: init %i32 = call %bound_method.loc31_30.2(%.loc31_27.2) [concrete = constants.%int_-10.642]
// CHECK:STDOUT:   %.loc31_30: init %i32 = converted %Core.IntLiteral.as.Negate.impl.Op.call.loc31, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc31_30 [concrete = constants.%int_-10.642]
// CHECK:STDOUT:   return %.loc31_30
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc31:
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2]
// CHECK:STDOUT:   %impl.elem1.loc32: %.02b = impl_witness_access constants.%Negate.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %bound_method.loc32_25: <bound method> = bound_method %int_2, %impl.elem1.loc32 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op.bound.e21]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.call.loc32: init Core.IntLiteral = call %bound_method.loc32_25(%int_2) [concrete = constants.%int_-2.962]
// CHECK:STDOUT:   %impl.elem0.loc32: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc32_27.1: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call.loc32, %impl.elem0.loc32 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.2a0]
// CHECK:STDOUT:   %specific_fn.loc32: <specific function> = specific_function %impl.elem0.loc32, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc32_27.2: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call.loc32, %specific_fn.loc32 [concrete = constants.%bound_method.33f]
// CHECK:STDOUT:   %.loc32_25.1: Core.IntLiteral = value_of_initializer %Core.IntLiteral.as.Negate.impl.Op.call.loc32 [concrete = constants.%int_-2.962]
// CHECK:STDOUT:   %.loc32_25.2: Core.IntLiteral = converted %Core.IntLiteral.as.Negate.impl.Op.call.loc32, %.loc32_25.1 [concrete = constants.%int_-2.962]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc32: init %i32 = call %bound_method.loc32_27.2(%.loc32_25.2) [concrete = constants.%int_-2.c83]
// CHECK:STDOUT:   %.loc32_27: init %i32 = converted %Core.IntLiteral.as.Negate.impl.Op.call.loc32, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc32 [concrete = constants.%int_-2.c83]
// CHECK:STDOUT:   return %.loc32_27
// CHECK:STDOUT: }
// CHECK:STDOUT:
