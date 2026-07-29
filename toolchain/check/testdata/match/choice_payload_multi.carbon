// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/choice_payload_multi.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/choice_payload_multi.carbon

// Multi-element payload destructuring (one subpattern per declared
// parameter, positionally), a zero-payload function-like alternative
// matched with its empty parentheses (`case .On()`, SF-3), and a binding
// whose declared type implicitly converts from the payload element type
// (`n: i64` from an `i32` payload — the bind pass converts per element, and
// the conversion's temporaries defer to the arm scope's cleanups).
//@dump-sem-ir-begin
choice Event {
  Move(dx: i32, dy: i32),
  Set(value: i32),
  On(),
  Off
}

fn Total(e: Event) -> i64 {
  match (e) {
    // CHECK:STDERR: choice_payload_multi.carbon:[[@LINE+4]]:16: warning: binding `dx` unused [UnusedBinding]
    // CHECK:STDERR:     case .Move(dx: i32, dy: i64) => { return dy; }
    // CHECK:STDERR:                ^~~~~~~
    // CHECK:STDERR:
    case .Move(dx: i32, dy: i64) => { return dy; }
    case .Set(n: i64) => { return n; }
    case .On() => { return 1; }
    case .Off => { return 0; }
    default => { return -1; }
  }
  return -2;
}
//@dump-sem-ir-end

// CHECK:STDOUT: --- choice_payload_multi.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %Event: type = class_type @Event [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %int_2.ecc: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %u2: type = class_type @UInt, @UInt(%int_2.ecc) [concrete]
// CHECK:STDOUT:   %tuple.type.e55: type = tuple_type (%i32, %i32) [concrete]
// CHECK:STDOUT:   %tuple.type.a8a: type = tuple_type (%i32) [concrete]
// CHECK:STDOUT:   %.677: type = custom_layout_type {size=8, align=4, .Move@0: %tuple.type.e55, .Set@0: %tuple.type.a8a} [concrete]
// CHECK:STDOUT:   %struct_type.discriminant.payload.1c4: type = struct_type {.discriminant: %u2, .payload: %.677} [concrete]
// CHECK:STDOUT:   %complete_type.cf7: <witness> = complete_type_witness %struct_type.discriminant.payload.1c4 [concrete]
// CHECK:STDOUT:   %struct_type.discriminant: type = struct_type {.discriminant: %u2} [concrete]
// CHECK:STDOUT:   %_.param_patt: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %_.patt: %pattern_type.6b6 = at_binding_pattern _, %_.param_patt [concrete]
// CHECK:STDOUT:   %.3df: Core.Form = init_form %Event [concrete]
// CHECK:STDOUT:   %pattern_type.afb: type = pattern_type %Event [concrete]
// CHECK:STDOUT:   %return.param_patt.dc0: %pattern_type.afb = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.2c2: %pattern_type.afb = return_slot_pattern %return.param_patt.dc0, %Event [concrete]
// CHECK:STDOUT:   %Event.Move.type: type = fn_type @Event.Move [concrete]
// CHECK:STDOUT:   %Event.Move: %Event.Move.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.452: type = facet_type <@ImplicitAs, @ImplicitAs(%u2)> [concrete]
// CHECK:STDOUT:   %To.fe9: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.170: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.e93: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.42f, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_2.ecc) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.d95: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_2.ecc) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.409: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.d95 = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.955: %ImplicitAs.type.452 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.e93) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.119: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%u2, %ImplicitAs.facet.955) [concrete]
// CHECK:STDOUT:   %.66c: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.119, %ImplicitAs.facet.955 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.941: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.409 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.a72: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.409, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(%int_2.ecc) [concrete]
// CHECK:STDOUT:   %bound_method.6ef: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.a72 [concrete]
// CHECK:STDOUT:   %int_0.336: %u2 = int_value 0 [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.0e0: <witness> = impl_witness imports.%Copy.impl_witness_table.367, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet.987: %Copy.type = facet_value %i32, (%Copy.impl_witness.0e0) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.d09: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.987) [concrete]
// CHECK:STDOUT:   %.7a6: type = fn_type_with_self_type %Copy.WithSelf.Op.type.d09, %Copy.facet.987 [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn.287: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %Event.Set.type: type = fn_type @Event.Set [concrete]
// CHECK:STDOUT:   %Event.Set: %Event.Set.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.48e: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.409 [concrete]
// CHECK:STDOUT:   %bound_method.0f5: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.a72 [concrete]
// CHECK:STDOUT:   %int_1.508: %u2 = int_value 1 [concrete]
// CHECK:STDOUT:   %Event.On.type: type = fn_type @Event.On [concrete]
// CHECK:STDOUT:   %Event.On: %Event.On.type = struct_value () [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.6c9: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.409 [concrete]
// CHECK:STDOUT:   %bound_method.135: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.a72 [concrete]
// CHECK:STDOUT:   %int_2.996: %u2 = int_value 2 [concrete]
// CHECK:STDOUT:   %uninit: %.677 = uninitialized_value [concrete]
// CHECK:STDOUT:   %Event.val.2df: %Event = struct_value (%int_2.996, %uninit) [concrete]
// CHECK:STDOUT:   %int_3.1ba: Core.IntLiteral = int_value 3 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.0d0: <bound method> = bound_method %int_3.1ba, %Core.IntLiteral.as.ImplicitAs.impl.Convert.409 [concrete]
// CHECK:STDOUT:   %bound_method.f45: <bound method> = bound_method %int_3.1ba, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.a72 [concrete]
// CHECK:STDOUT:   %int_3.184: %u2 = int_value 3 [concrete]
// CHECK:STDOUT:   %struct: %struct_type.discriminant = struct_value (%int_3.184) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.type.0c5: type = fn_type @UInt.as.Copy.impl.Op, @UInt.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.38a: %UInt.as.Copy.impl.Op.type.0c5 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.f92: <witness> = impl_witness imports.%Copy.impl_witness_table.fe3, @UInt.as.Copy.impl(%int_2.ecc) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.type.d68: type = fn_type @UInt.as.Copy.impl.Op, @UInt.as.Copy.impl(%int_2.ecc) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.4d1: %UInt.as.Copy.impl.Op.type.d68 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet.842: %Copy.type = facet_value %u2, (%Copy.impl_witness.f92) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.21e: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.842) [concrete]
// CHECK:STDOUT:   %.594: type = fn_type_with_self_type %Copy.WithSelf.Op.type.21e, %Copy.facet.842 [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.bound: <bound method> = bound_method %int_3.184, %UInt.as.Copy.impl.Op.4d1 [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %UInt.as.Copy.impl.Op.4d1, @UInt.as.Copy.impl.Op(%int_2.ecc) [concrete]
// CHECK:STDOUT:   %bound_method.f04: <bound method> = bound_method %int_3.184, %UInt.as.Copy.impl.Op.specific_fn [concrete]
// CHECK:STDOUT:   %Event.val.679: %Event = struct_value (%int_3.184, %uninit) [concrete]
// CHECK:STDOUT:   %.ac9: ref %Event = temporary invalid, %Event.val.679 [concrete]
// CHECK:STDOUT:   %e.param_patt: %pattern_type.afb = value_param_pattern [concrete]
// CHECK:STDOUT:   %e.patt: %pattern_type.afb = at_binding_pattern e, %e.param_patt [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %.bc0: Core.Form = init_form %i64 [concrete]
// CHECK:STDOUT:   %pattern_type.f57: type = pattern_type %i64 [concrete]
// CHECK:STDOUT:   %return.param_patt.cfc: %pattern_type.f57 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.178: %pattern_type.f57 = return_slot_pattern %return.param_patt.cfc, %i64 [concrete]
// CHECK:STDOUT:   %Total.type: type = fn_type @Total [concrete]
// CHECK:STDOUT:   %Total: %Total.type = struct_value () [concrete]
// CHECK:STDOUT:   %dx.patt.dec: %pattern_type.6b6 = value_binding_pattern dx [concrete]
// CHECK:STDOUT:   %dy.patt.2f4: %pattern_type.f57 = value_binding_pattern dy [concrete]
// CHECK:STDOUT:   %tuple.type.b3d: type = tuple_type (%i32, %i64) [concrete]
// CHECK:STDOUT:   %pattern_type.34e: type = pattern_type %tuple.type.b3d [concrete]
// CHECK:STDOUT:   %.4d8: %pattern_type.34e = tuple_pattern (%dx.patt.dec, %dy.patt.2f4) [concrete]
// CHECK:STDOUT:   %EqWith.type.f24: type = facet_type <@EqWith, @EqWith(%u2)> [concrete]
// CHECK:STDOUT:   %M: Core.IntLiteral = symbolic_binding M, 1 [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.544: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%N, %M) [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.c67: %UInt.as.EqWith.impl.Equal.type.544 = struct_value () [symbolic]
// CHECK:STDOUT:   %EqWith.impl_witness.454: <witness> = impl_witness imports.%EqWith.impl_witness_table.cbd, @UInt.as.EqWith.impl.f13(%int_2.ecc, %int_2.ecc) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.5fc: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%int_2.ecc, %int_2.ecc) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.e76: %UInt.as.EqWith.impl.Equal.type.5fc = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.16f: %EqWith.type.f24 = facet_value %u2, (%EqWith.impl_witness.454) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.c65: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%u2, %EqWith.facet.16f) [concrete]
// CHECK:STDOUT:   %.7a0: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.c65, %EqWith.facet.16f [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound.dac: <bound method> = bound_method %int_0.336, %UInt.as.EqWith.impl.Equal.e76 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.specific_fn.149: <specific function> = specific_function %UInt.as.EqWith.impl.Equal.e76, @UInt.as.EqWith.impl.Equal.1(%int_2.ecc, %int_2.ecc) [concrete]
// CHECK:STDOUT:   %bound_method.dad: <bound method> = bound_method %int_0.336, %UInt.as.EqWith.impl.Equal.specific_fn.149 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.221: type = facet_type <@ImplicitAs, @ImplicitAs(%i64)> [concrete]
// CHECK:STDOUT:   %Int.67af24.2: type = class_type @Int, @Int(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %facet_type.037: type = facet_type <@IntFitsIn, @IntFitsIn(%Int.67af24.2) & @AnyInt> [symbolic]
// CHECK:STDOUT:   %From.6a4: %facet_type.037 = symbolic_binding From, 1 [symbolic]
// CHECK:STDOUT:   %From.as_type.as.ImplicitAs.impl.Convert.type.7fa: type = fn_type @From.as_type.as.ImplicitAs.impl.Convert, @From.as_type.as.ImplicitAs.impl(%To.fe9, %From.6a4) [symbolic]
// CHECK:STDOUT:   %From.as_type.as.ImplicitAs.impl.Convert.643: %From.as_type.as.ImplicitAs.impl.Convert.type.7fa = struct_value () [symbolic]
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
// CHECK:STDOUT:   %n.patt: %pattern_type.f57 = value_binding_pattern n [concrete]
// CHECK:STDOUT:   %tuple.type.f67: type = tuple_type (%i64) [concrete]
// CHECK:STDOUT:   %pattern_type.335: type = pattern_type %tuple.type.f67 [concrete]
// CHECK:STDOUT:   %.241: %pattern_type.335 = tuple_pattern (%n.patt) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound.f51: <bound method> = bound_method %int_1.508, %UInt.as.EqWith.impl.Equal.e76 [concrete]
// CHECK:STDOUT:   %bound_method.1da: <bound method> = bound_method %int_1.508, %UInt.as.EqWith.impl.Equal.specific_fn.149 [concrete]
// CHECK:STDOUT:   %pattern_type.cb1: type = pattern_type %empty_tuple.type [concrete]
// CHECK:STDOUT:   %.e84: %pattern_type.cb1 = tuple_pattern () [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound.99a: <bound method> = bound_method %int_2.996, %UInt.as.EqWith.impl.Equal.e76 [concrete]
// CHECK:STDOUT:   %bound_method.64f: <bound method> = bound_method %int_2.996, %UInt.as.EqWith.impl.Equal.specific_fn.149 [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.091: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.b3c, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_64) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.55a: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_64) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.55a = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.6e8: %ImplicitAs.type.221 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.091) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.a04: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i64, %ImplicitAs.facet.6e8) [concrete]
// CHECK:STDOUT:   %.f349: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.a04, %ImplicitAs.facet.6e8 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.89f: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.f33: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(%int_64) [concrete]
// CHECK:STDOUT:   %bound_method.c5e: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.f33 [concrete]
// CHECK:STDOUT:   %int_1.d98: %i64 = int_value 1 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound.163: <bound method> = bound_method %int_3.184, %UInt.as.EqWith.impl.Equal.e76 [concrete]
// CHECK:STDOUT:   %bound_method.d66: <bound method> = bound_method %int_3.184, %UInt.as.EqWith.impl.Equal.specific_fn.149 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.0a3: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b [concrete]
// CHECK:STDOUT:   %bound_method.0c1: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.f33 [concrete]
// CHECK:STDOUT:   %int_0.2e4: %i64 = int_value 0 [concrete]
// CHECK:STDOUT:   %Negate.type: type = facet_type <@Negate> [concrete]
// CHECK:STDOUT:   %Negate.impl_witness: <witness> = impl_witness imports.%Negate.impl_witness_table [concrete]
// CHECK:STDOUT:   %Negate.facet: %Negate.type = facet_value Core.IntLiteral, (%Negate.impl_witness) [concrete]
// CHECK:STDOUT:   %Negate.WithSelf.Op.type.f03: type = fn_type @Negate.WithSelf.Op, @Negate.WithSelf(%Negate.facet) [concrete]
// CHECK:STDOUT:   %.02b: type = fn_type_with_self_type %Negate.WithSelf.Op.type.f03, %Negate.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.type: type = fn_type @Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op: %Core.IntLiteral.as.Negate.impl.Op.type = struct_value () [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.bound.6a0: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %int_-1.638: Core.IntLiteral = int_value -1 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.bc7: <bound method> = bound_method %int_-1.638, %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b [concrete]
// CHECK:STDOUT:   %bound_method.ef0: <bound method> = bound_method %int_-1.638, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.f33 [concrete]
// CHECK:STDOUT:   %int_-1.a7e: %i64 = int_value -1 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.aa5: @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.170)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.42f = impl_witness_table (%Core.import_ref.aa5), @Core.IntLiteral.as.ImplicitAs.impl.b68 [concrete]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.367 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.791: @UInt.as.Copy.impl.%UInt.as.Copy.impl.Op.type (%UInt.as.Copy.impl.Op.type.0c5) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.Copy.impl.%UInt.as.Copy.impl.Op (constants.%UInt.as.Copy.impl.Op.38a)]
// CHECK:STDOUT:   %Copy.impl_witness_table.fe3 = impl_witness_table (%Core.import_ref.791), @UInt.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.b92: @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal.type (%UInt.as.EqWith.impl.Equal.type.544) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal (constants.%UInt.as.EqWith.impl.Equal.c67)]
// CHECK:STDOUT:   %Core.import_ref.b44 = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.cbd = impl_witness_table (%Core.import_ref.b92, %Core.import_ref.b44), @UInt.as.EqWith.impl.f13 [concrete]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.b3c = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.2a4: @From.as_type.as.ImplicitAs.impl.%From.as_type.as.ImplicitAs.impl.Convert.type (%From.as_type.as.ImplicitAs.impl.Convert.type.7fa) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @From.as_type.as.ImplicitAs.impl.%From.as_type.as.ImplicitAs.impl.Convert (constants.%From.as_type.as.ImplicitAs.impl.Convert.643)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.3b9 = impl_witness_table (%Core.import_ref.2a4), @From.as_type.as.ImplicitAs.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.47b: Core.IntLiteral = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.AnyInt.impl.%N (constants.%N)]
// CHECK:STDOUT:   %Core.import_ref.fd3: @Int.as.AnyInt.impl.%Int.as.AnyInt.impl.AsInt.type (%Int.as.AnyInt.impl.AsInt.type.80b) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.AnyInt.impl.%Int.as.AnyInt.impl.AsInt (constants.%Int.as.AnyInt.impl.AsInt.23f)]
// CHECK:STDOUT:   %AnyInt.impl_witness_table = impl_witness_table (%Core.import_ref.47b, %Core.import_ref.fd3), @Int.as.AnyInt.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.abd = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9c3: %Core.IntLiteral.as.Negate.impl.Op.type = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, loaded [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %Negate.impl_witness_table = impl_witness_table (%Core.import_ref.abd, %Core.import_ref.9c3), @Core.IntLiteral.as.Negate.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %Event.Move.decl: %Event.Move.type = fn_decl @Event.Move [concrete = constants.%Event.Move] {
// CHECK:STDOUT:     %_.param_patt.loc20_14.1: %pattern_type.6b6 = value_param_pattern [concrete = constants.%_.param_patt]
// CHECK:STDOUT:     %_.patt.loc20_14.1: %pattern_type.6b6 = at_binding_pattern _, %_.param_patt.loc20_14.1 [concrete = constants.%_.patt]
// CHECK:STDOUT:     %_.param_patt.loc20_14.2: %pattern_type.6b6 = value_param_pattern [concrete = constants.%_.param_patt]
// CHECK:STDOUT:     %_.patt.loc20_14.2: %pattern_type.6b6 = at_binding_pattern _, %_.param_patt.loc20_14.2 [concrete = constants.%_.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.afb = out_param_pattern [concrete = constants.%return.param_patt.dc0]
// CHECK:STDOUT:     %return.patt: %pattern_type.afb = return_slot_pattern %return.param_patt, constants.%Event [concrete = constants.%return.patt.2c2]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc20_14.8: Core.Form = init_form constants.%Event [concrete = constants.%.3df]
// CHECK:STDOUT:     %_.param.loc20_14.1: %i32 = value_param call_param0
// CHECK:STDOUT:     %_.loc20_14.1: %i32 = wrapper_binding _, %_.param.loc20_14.1
// CHECK:STDOUT:     %_.param.loc20_14.2: %i32 = value_param call_param1
// CHECK:STDOUT:     %_.loc20_14.2: %i32 = wrapper_binding _, %_.param.loc20_14.2
// CHECK:STDOUT:     %return.param: ref %Event = out_param call_param2
// CHECK:STDOUT:     %return: ref %Event = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Event.Set.decl: %Event.Set.type = fn_decl @Event.Set [concrete = constants.%Event.Set] {
// CHECK:STDOUT:     %_.param_patt: %pattern_type.6b6 = value_param_pattern [concrete = constants.%_.param_patt]
// CHECK:STDOUT:     %_.patt: %pattern_type.6b6 = at_binding_pattern _, %_.param_patt [concrete = constants.%_.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.afb = out_param_pattern [concrete = constants.%return.param_patt.dc0]
// CHECK:STDOUT:     %return.patt: %pattern_type.afb = return_slot_pattern %return.param_patt, constants.%Event [concrete = constants.%return.patt.2c2]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc20_14.9: Core.Form = init_form constants.%Event [concrete = constants.%.3df]
// CHECK:STDOUT:     %_.param: %i32 = value_param call_param0
// CHECK:STDOUT:     %_: %i32 = wrapper_binding _, %_.param
// CHECK:STDOUT:     %return.param: ref %Event = out_param call_param1
// CHECK:STDOUT:     %return: ref %Event = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Event.On.decl: %Event.On.type = fn_decl @Event.On [concrete = constants.%Event.On] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.afb = out_param_pattern [concrete = constants.%return.param_patt.dc0]
// CHECK:STDOUT:     %return.patt: %pattern_type.afb = return_slot_pattern %return.param_patt, constants.%Event [concrete = constants.%return.patt.2c2]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc20_14.7: Core.Form = init_form constants.%Event [concrete = constants.%.3df]
// CHECK:STDOUT:     %return.param: ref %Event = out_param call_param0
// CHECK:STDOUT:     %return: ref %Event = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Event.decl: type = class_decl @Event [concrete = constants.%Event] {} {}
// CHECK:STDOUT:   %Total.decl: %Total.type = fn_decl @Total [concrete = constants.%Total] {
// CHECK:STDOUT:     %e.param_patt: %pattern_type.afb = value_param_pattern [concrete = constants.%e.param_patt]
// CHECK:STDOUT:     %e.patt: %pattern_type.afb = at_binding_pattern e, %e.param_patt [concrete = constants.%e.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.f57 = out_param_pattern [concrete = constants.%return.param_patt.cfc]
// CHECK:STDOUT:     %return.patt: %pattern_type.f57 = return_slot_pattern %return.param_patt, %i64.loc27 [concrete = constants.%return.patt.178]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i64.loc27: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:     %.loc27: Core.Form = init_form %i64.loc27 [concrete = constants.%.bc0]
// CHECK:STDOUT:     %e.param: %Event = value_param call_param0
// CHECK:STDOUT:     %Event.ref: type = name_ref Event, file.%Event.decl [concrete = constants.%Event]
// CHECK:STDOUT:     %e: %Event = wrapper_binding e, %e.param
// CHECK:STDOUT:     %return.param: ref %i64 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i64 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: class @Event {
// CHECK:STDOUT:   %dx.param: %i32 = value_param call_param0
// CHECK:STDOUT:   %i32.loc21_12: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %dx: %i32 = wrapper_binding dx, %dx.param
// CHECK:STDOUT:   %dy.param: %i32 = value_param call_param1
// CHECK:STDOUT:   %i32.loc21_21: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %dy: %i32 = wrapper_binding dy, %dy.param
// CHECK:STDOUT:   %value.param: %i32 = value_param call_param0
// CHECK:STDOUT:   %i32.loc22: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %value: %i32 = wrapper_binding value, %value.param
// CHECK:STDOUT:   %.loc25_1.1: type = custom_layout_type {size=8, align=4, .Move@0: %tuple.type.e55, .Set@0: %tuple.type.a8a} [concrete = constants.%.677]
// CHECK:STDOUT:   %complete_type: <witness> = complete_type_witness constants.%struct_type.discriminant.payload.1c4 [concrete = constants.%complete_type.cf7]
// CHECK:STDOUT:   %int_3: Core.IntLiteral = int_value 3 [concrete = constants.%int_3.1ba]
// CHECK:STDOUT:   %impl.elem0.loc25_1.1: %.66c = impl_witness_access constants.%ImplicitAs.impl_witness.e93, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.409]
// CHECK:STDOUT:   %bound_method.loc25_1.1: <bound method> = bound_method %int_3, %impl.elem0.loc25_1.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.0d0]
// CHECK:STDOUT:   %specific_fn.loc25_1.1: <specific function> = specific_function %impl.elem0.loc25_1.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_2.ecc) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.a72]
// CHECK:STDOUT:   %bound_method.loc25_1.2: <bound method> = bound_method %int_3, %specific_fn.loc25_1.1 [concrete = constants.%bound_method.f45]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %u2 = call %bound_method.loc25_1.2(%int_3) [concrete = constants.%int_3.184]
// CHECK:STDOUT:   %.loc25_1.2: %u2 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_3.184]
// CHECK:STDOUT:   %.loc25_1.3: %u2 = converted %int_3, %.loc25_1.2 [concrete = constants.%int_3.184]
// CHECK:STDOUT:   %.loc25_1.4: %struct_type.discriminant = struct_literal (%.loc25_1.3) [concrete = constants.%struct]
// CHECK:STDOUT:   %impl.elem0.loc25_1.2: %.594 = impl_witness_access constants.%Copy.impl_witness.f92, element0 [concrete = constants.%UInt.as.Copy.impl.Op.4d1]
// CHECK:STDOUT:   %bound_method.loc25_1.3: <bound method> = bound_method %.loc25_1.3, %impl.elem0.loc25_1.2 [concrete = constants.%UInt.as.Copy.impl.Op.bound]
// CHECK:STDOUT:   %specific_fn.loc25_1.2: <specific function> = specific_function %impl.elem0.loc25_1.2, @UInt.as.Copy.impl.Op(constants.%int_2.ecc) [concrete = constants.%UInt.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc25_1.4: <bound method> = bound_method %.loc25_1.3, %specific_fn.loc25_1.2 [concrete = constants.%bound_method.f04]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.call: init %u2 = call %bound_method.loc25_1.4(%.loc25_1.3) [concrete = constants.%int_3.184]
// CHECK:STDOUT:   %.loc25_1.5: ref %Event = temporary_storage
// CHECK:STDOUT:   %.loc25_1.6: ref %u2 = class_element_access %.loc25_1.5, element0
// CHECK:STDOUT:   %.loc25_1.7: init %u2 to %.loc25_1.6 = in_place_init %UInt.as.Copy.impl.Op.call [concrete = constants.%int_3.184]
// CHECK:STDOUT:   %.loc25_1.8: ref %.677 = class_element_access %.loc25_1.5, element1
// CHECK:STDOUT:   %uninit: %.677 = uninitialized_value [concrete = constants.%uninit]
// CHECK:STDOUT:   %.loc25_1.9: init %.677 to %.loc25_1.8 = in_place_init %uninit [concrete = constants.%uninit]
// CHECK:STDOUT:   %.loc25_1.10: init %Event to %.loc25_1.5 = class_init (%.loc25_1.7, %.loc25_1.9) [concrete = constants.%Event.val.679]
// CHECK:STDOUT:   %.loc25_1.11: init %Event = converted %.loc25_1.4, %.loc25_1.10 [concrete = constants.%Event.val.679]
// CHECK:STDOUT:   %.loc25_1.12: ref %Event = temporary %.loc25_1.5, %.loc25_1.11 [concrete = constants.%.ac9]
// CHECK:STDOUT:   %.loc25_1.13: %Event = acquire_value %.loc25_1.12 [concrete = constants.%Event.val.679]
// CHECK:STDOUT:   %Off: %Event = wrapper_binding Off, %.loc25_1.13
// CHECK:STDOUT:   complete_type_witness = %complete_type
// CHECK:STDOUT:
// CHECK:STDOUT: !members:
// CHECK:STDOUT:   .Self = constants.%Event
// CHECK:STDOUT:   .Move = generated.%Event.Move.decl
// CHECK:STDOUT:   .Set = generated.%Event.Set.decl
// CHECK:STDOUT:   .On = generated.%Event.On.decl
// CHECK:STDOUT:   .Off = %Off
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Event.Move(%_.param.loc20_14.1: %i32, %_.param.loc20_14.2: %i32) -> out %return.param: %Event {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %.loc20_14.1: ref %u2 = class_element_access %return.param, element0
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc20_14.1: %.66c = impl_witness_access constants.%ImplicitAs.impl_witness.e93, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.409]
// CHECK:STDOUT:   %bound_method.loc20_14.1: <bound method> = bound_method %int_0, %impl.elem0.loc20_14.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.941]
// CHECK:STDOUT:   %specific_fn.loc20_14.1: <specific function> = specific_function %impl.elem0.loc20_14.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_2.ecc) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.a72]
// CHECK:STDOUT:   %bound_method.loc20_14.2: <bound method> = bound_method %int_0, %specific_fn.loc20_14.1 [concrete = constants.%bound_method.6ef]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %u2 = call %bound_method.loc20_14.2(%int_0) [concrete = constants.%int_0.336]
// CHECK:STDOUT:   %.loc20_14.2: init %u2 = converted %int_0, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_0.336]
// CHECK:STDOUT:   %.loc20_14.3: init %u2 to %.loc20_14.1 = in_place_init %.loc20_14.2 [concrete = constants.%int_0.336]
// CHECK:STDOUT:   %.loc20_14.4: ref %.677 = class_element_access %return.param, element1
// CHECK:STDOUT:   %.loc20_14.5: ref %tuple.type.e55 = class_element_access %.loc20_14.4, element0
// CHECK:STDOUT:   %.loc21_25.1: %tuple.type.e55 = tuple_literal (%_.param.loc20_14.1, %_.param.loc20_14.2)
// CHECK:STDOUT:   %impl.elem0.loc20_14.2: %.7a6 = impl_witness_access constants.%Copy.impl_witness.0e0, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc20_14.3: <bound method> = bound_method %_.param.loc20_14.1, %impl.elem0.loc20_14.2
// CHECK:STDOUT:   %specific_fn.loc20_14.2: <specific function> = specific_function %impl.elem0.loc20_14.2, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn.287]
// CHECK:STDOUT:   %bound_method.loc20_14.4: <bound method> = bound_method %_.param.loc20_14.1, %specific_fn.loc20_14.2
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call.loc20_14.1: init %i32 = call %bound_method.loc20_14.4(%_.param.loc20_14.1)
// CHECK:STDOUT:   %tuple.elem0: ref %i32 = tuple_access %.loc20_14.5, element0
// CHECK:STDOUT:   %.loc21_25.2: init %i32 to %tuple.elem0 = in_place_init %Int.as.Copy.impl.Op.call.loc20_14.1
// CHECK:STDOUT:   %impl.elem0.loc20_14.3: %.7a6 = impl_witness_access constants.%Copy.impl_witness.0e0, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc20_14.5: <bound method> = bound_method %_.param.loc20_14.2, %impl.elem0.loc20_14.3
// CHECK:STDOUT:   %specific_fn.loc20_14.3: <specific function> = specific_function %impl.elem0.loc20_14.3, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn.287]
// CHECK:STDOUT:   %bound_method.loc20_14.6: <bound method> = bound_method %_.param.loc20_14.2, %specific_fn.loc20_14.3
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call.loc20_14.2: init %i32 = call %bound_method.loc20_14.6(%_.param.loc20_14.2)
// CHECK:STDOUT:   %tuple.elem1: ref %i32 = tuple_access %.loc20_14.5, element1
// CHECK:STDOUT:   %.loc21_25.3: init %i32 to %tuple.elem1 = in_place_init %Int.as.Copy.impl.Op.call.loc20_14.2
// CHECK:STDOUT:   %.loc21_25.4: init %tuple.type.e55 to %.loc20_14.5 = tuple_init (%.loc21_25.2, %.loc21_25.3)
// CHECK:STDOUT:   %.loc20_14.6: init %tuple.type.e55 = converted %.loc21_25.1, %.loc21_25.4
// CHECK:STDOUT:   %.loc20_14.7: init %Event to %return.param = class_init (%.loc20_14.3, %.loc20_14.6)
// CHECK:STDOUT:   return %.loc20_14.7 to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Event.Set(%_.param: %i32) -> out %return.param: %Event {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %.loc20_14.1: ref %u2 = class_element_access %return.param, element0
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc20_14.1: %.66c = impl_witness_access constants.%ImplicitAs.impl_witness.e93, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.409]
// CHECK:STDOUT:   %bound_method.loc20_14.1: <bound method> = bound_method %int_1, %impl.elem0.loc20_14.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.48e]
// CHECK:STDOUT:   %specific_fn.loc20_14.1: <specific function> = specific_function %impl.elem0.loc20_14.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_2.ecc) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.a72]
// CHECK:STDOUT:   %bound_method.loc20_14.2: <bound method> = bound_method %int_1, %specific_fn.loc20_14.1 [concrete = constants.%bound_method.0f5]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %u2 = call %bound_method.loc20_14.2(%int_1) [concrete = constants.%int_1.508]
// CHECK:STDOUT:   %.loc20_14.2: init %u2 = converted %int_1, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_1.508]
// CHECK:STDOUT:   %.loc20_14.3: init %u2 to %.loc20_14.1 = in_place_init %.loc20_14.2 [concrete = constants.%int_1.508]
// CHECK:STDOUT:   %.loc20_14.4: ref %.677 = class_element_access %return.param, element1
// CHECK:STDOUT:   %.loc20_14.5: ref %tuple.type.a8a = class_element_access %.loc20_14.4, element1
// CHECK:STDOUT:   %.loc22_18.1: %tuple.type.a8a = tuple_literal (%_.param)
// CHECK:STDOUT:   %impl.elem0.loc20_14.2: %.7a6 = impl_witness_access constants.%Copy.impl_witness.0e0, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc20_14.3: <bound method> = bound_method %_.param, %impl.elem0.loc20_14.2
// CHECK:STDOUT:   %specific_fn.loc20_14.2: <specific function> = specific_function %impl.elem0.loc20_14.2, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn.287]
// CHECK:STDOUT:   %bound_method.loc20_14.4: <bound method> = bound_method %_.param, %specific_fn.loc20_14.2
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc20_14.4(%_.param)
// CHECK:STDOUT:   %.loc22_18.2: init %tuple.type.a8a to %.loc20_14.5 = tuple_init (%Int.as.Copy.impl.Op.call)
// CHECK:STDOUT:   %.loc20_14.6: init %tuple.type.a8a = converted %.loc22_18.1, %.loc22_18.2
// CHECK:STDOUT:   %.loc20_14.7: init %tuple.type.a8a to %.loc20_14.5 = in_place_init %.loc20_14.6
// CHECK:STDOUT:   %.loc20_14.8: init %Event to %return.param = class_init (%.loc20_14.3, %.loc20_14.7)
// CHECK:STDOUT:   return %.loc20_14.8 to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Event.On() -> out %return.param: %Event {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %.loc20_14.1: ref %u2 = class_element_access %return.param, element0
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:   %impl.elem0: %.66c = impl_witness_access constants.%ImplicitAs.impl_witness.e93, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.409]
// CHECK:STDOUT:   %bound_method.loc20_14.1: <bound method> = bound_method %int_2, %impl.elem0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.6c9]
// CHECK:STDOUT:   %specific_fn: <specific function> = specific_function %impl.elem0, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_2.ecc) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.a72]
// CHECK:STDOUT:   %bound_method.loc20_14.2: <bound method> = bound_method %int_2, %specific_fn [concrete = constants.%bound_method.135]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %u2 = call %bound_method.loc20_14.2(%int_2) [concrete = constants.%int_2.996]
// CHECK:STDOUT:   %.loc20_14.2: init %u2 = converted %int_2, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_2.996]
// CHECK:STDOUT:   %.loc20_14.3: init %u2 to %.loc20_14.1 = in_place_init %.loc20_14.2 [concrete = constants.%int_2.996]
// CHECK:STDOUT:   %.loc20_14.4: ref %.677 = class_element_access %return.param, element1
// CHECK:STDOUT:   %uninit: %.677 = uninitialized_value [concrete = constants.%uninit]
// CHECK:STDOUT:   %.loc20_14.5: init %.677 to %.loc20_14.4 = in_place_init %uninit [concrete = constants.%uninit]
// CHECK:STDOUT:   %.loc20_14.6: init %Event to %return.param = class_init (%.loc20_14.3, %.loc20_14.5) [concrete = constants.%Event.val.2df]
// CHECK:STDOUT:   return %.loc20_14.6 to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Total(%e.param: %Event) -> out %return.param: %i64 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %e.ref: %Event = name_ref e, %e
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %dx.patt: %pattern_type.6b6 = value_binding_pattern dx [concrete = constants.%dx.patt.dec]
// CHECK:STDOUT:     %dy.patt: %pattern_type.f57 = value_binding_pattern dy [concrete = constants.%dy.patt.2f4]
// CHECK:STDOUT:     %.loc33_32.1: %pattern_type.34e = tuple_pattern (%dx.patt, %dy.patt) [concrete = constants.%.4d8]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_0.loc33: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc33_34.1: %.66c = impl_witness_access constants.%ImplicitAs.impl_witness.e93, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.409]
// CHECK:STDOUT:   %bound_method.loc33_34.1: <bound method> = bound_method %int_0.loc33, %impl.elem0.loc33_34.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.941]
// CHECK:STDOUT:   %specific_fn.loc33_34.1: <specific function> = specific_function %impl.elem0.loc33_34.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_2.ecc) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.a72]
// CHECK:STDOUT:   %bound_method.loc33_34.2: <bound method> = bound_method %int_0.loc33, %specific_fn.loc33_34.1 [concrete = constants.%bound_method.6ef]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc33: init %u2 = call %bound_method.loc33_34.2(%int_0.loc33) [concrete = constants.%int_0.336]
// CHECK:STDOUT:   %.loc33_34.1: %u2 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc33 [concrete = constants.%int_0.336]
// CHECK:STDOUT:   %.loc33_34.2: %u2 = converted %int_0.loc33, %.loc33_34.1 [concrete = constants.%int_0.336]
// CHECK:STDOUT:   %.loc33_34.3: ref %u2 = class_element_access %e.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc33_34.2: %.7a0 = impl_witness_access constants.%EqWith.impl_witness.454, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.e76]
// CHECK:STDOUT:   %bound_method.loc33_34.3: <bound method> = bound_method %.loc33_34.2, %impl.elem0.loc33_34.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.dac]
// CHECK:STDOUT:   %specific_fn.loc33_34.2: <specific function> = specific_function %impl.elem0.loc33_34.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_2.ecc, constants.%int_2.ecc) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.149]
// CHECK:STDOUT:   %bound_method.loc33_34.4: <bound method> = bound_method %.loc33_34.2, %specific_fn.loc33_34.2 [concrete = constants.%bound_method.dad]
// CHECK:STDOUT:   %.loc33_34.4: %u2 = acquire_value %.loc33_34.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc33: init bool = call %bound_method.loc33_34.4(%.loc33_34.2, %.loc33_34.4)
// CHECK:STDOUT:   %.loc33_34.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc33
// CHECK:STDOUT:   %.loc33_34.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc33, %.loc33_34.5
// CHECK:STDOUT:   if %.loc33_34.6 br !match.case.then.loc33 else br !match.case.else.loc33
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc33:
// CHECK:STDOUT:   %.loc33_34.7: ref %.677 = class_element_access %e.ref, element1
// CHECK:STDOUT:   %.loc33_34.8: ref %tuple.type.e55 = class_element_access %.loc33_34.7, element0
// CHECK:STDOUT:   %tuple.elem0.loc33_34.1: ref %i32 = tuple_access %.loc33_34.8, element0
// CHECK:STDOUT:   %.loc33_34.9: %i32 = acquire_value %tuple.elem0.loc33_34.1
// CHECK:STDOUT:   %tuple.elem1.loc33_34.1: ref %i32 = tuple_access %.loc33_34.8, element1
// CHECK:STDOUT:   %impl.elem0.loc33_34.3: %.9a0 = impl_witness_access constants.%ImplicitAs.impl_witness.a40, element0 [concrete = constants.%From.as_type.as.ImplicitAs.impl.Convert.e3c]
// CHECK:STDOUT:   %bound_method.loc33_34.5: <bound method> = bound_method %tuple.elem1.loc33_34.1, %impl.elem0.loc33_34.3
// CHECK:STDOUT:   %specific_fn.loc33_34.3: <specific function> = specific_function %impl.elem0.loc33_34.3, @From.as_type.as.ImplicitAs.impl.Convert(constants.%int_64, constants.%facet_value) [concrete = constants.%From.as_type.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc33_34.6: <bound method> = bound_method %tuple.elem1.loc33_34.1, %specific_fn.loc33_34.3
// CHECK:STDOUT:   %.loc33_34.10: %i32 = acquire_value %tuple.elem1.loc33_34.1
// CHECK:STDOUT:   %From.as_type.as.ImplicitAs.impl.Convert.call.loc33: init %i64 = call %bound_method.loc33_34.6(%.loc33_34.10)
// CHECK:STDOUT:   %.loc33_34.11: %i64 = value_of_initializer %From.as_type.as.ImplicitAs.impl.Convert.call.loc33
// CHECK:STDOUT:   %.loc33_34.12: %i64 = converted %tuple.elem1.loc33_34.1, %.loc33_34.11
// CHECK:STDOUT:   %tuple.loc33: %tuple.type.b3d = tuple_value (%.loc33_34.9, %.loc33_34.12)
// CHECK:STDOUT:   %.loc33_32.2: %tuple.type.b3d = converted %.loc33_34.8, %tuple.loc33
// CHECK:STDOUT:   %tuple.elem0.loc33_34.2: %i32 = tuple_access %.loc33_32.2, element0
// CHECK:STDOUT:   %tuple.elem1.loc33_34.2: %i64 = tuple_access %.loc33_32.2, element1
// CHECK:STDOUT:   %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %dx: %i32 = wrapper_binding dx, %tuple.elem0.loc33_34.2
// CHECK:STDOUT:   %i64.loc33: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:   %dy: %i64 = wrapper_binding dy, %tuple.elem1.loc33_34.2
// CHECK:STDOUT:   %dy.ref: %i64 = name_ref dy, %dy
// CHECK:STDOUT:   %impl.elem0.loc33_46: %.3cb = impl_witness_access constants.%Copy.impl_witness.c5e, element0 [concrete = constants.%Int.as.Copy.impl.Op.d73]
// CHECK:STDOUT:   %bound_method.loc33_46.1: <bound method> = bound_method %dy.ref, %impl.elem0.loc33_46
// CHECK:STDOUT:   %specific_fn.loc33_46: <specific function> = specific_function %impl.elem0.loc33_46, @Int.as.Copy.impl.Op(constants.%int_64) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn.b95]
// CHECK:STDOUT:   %bound_method.loc33_46.2: <bound method> = bound_method %dy.ref, %specific_fn.loc33_46
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call.loc33: init %i64 = call %bound_method.loc33_46.2(%dy.ref)
// CHECK:STDOUT:   return %Int.as.Copy.impl.Op.call.loc33
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc33:
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %n.patt: %pattern_type.f57 = value_binding_pattern n [concrete = constants.%n.patt]
// CHECK:STDOUT:     %.loc34_16.1: %pattern_type.335 = tuple_pattern (%n.patt) [concrete = constants.%.241]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_1.loc34: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc34_23.1: %.66c = impl_witness_access constants.%ImplicitAs.impl_witness.e93, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.409]
// CHECK:STDOUT:   %bound_method.loc34_23.1: <bound method> = bound_method %int_1.loc34, %impl.elem0.loc34_23.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.48e]
// CHECK:STDOUT:   %specific_fn.loc34_23.1: <specific function> = specific_function %impl.elem0.loc34_23.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_2.ecc) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.a72]
// CHECK:STDOUT:   %bound_method.loc34_23.2: <bound method> = bound_method %int_1.loc34, %specific_fn.loc34_23.1 [concrete = constants.%bound_method.0f5]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc34: init %u2 = call %bound_method.loc34_23.2(%int_1.loc34) [concrete = constants.%int_1.508]
// CHECK:STDOUT:   %.loc34_23.1: %u2 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc34 [concrete = constants.%int_1.508]
// CHECK:STDOUT:   %.loc34_23.2: %u2 = converted %int_1.loc34, %.loc34_23.1 [concrete = constants.%int_1.508]
// CHECK:STDOUT:   %.loc34_23.3: ref %u2 = class_element_access %e.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc34_23.2: %.7a0 = impl_witness_access constants.%EqWith.impl_witness.454, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.e76]
// CHECK:STDOUT:   %bound_method.loc34_23.3: <bound method> = bound_method %.loc34_23.2, %impl.elem0.loc34_23.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.f51]
// CHECK:STDOUT:   %specific_fn.loc34_23.2: <specific function> = specific_function %impl.elem0.loc34_23.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_2.ecc, constants.%int_2.ecc) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.149]
// CHECK:STDOUT:   %bound_method.loc34_23.4: <bound method> = bound_method %.loc34_23.2, %specific_fn.loc34_23.2 [concrete = constants.%bound_method.1da]
// CHECK:STDOUT:   %.loc34_23.4: %u2 = acquire_value %.loc34_23.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc34: init bool = call %bound_method.loc34_23.4(%.loc34_23.2, %.loc34_23.4)
// CHECK:STDOUT:   %.loc34_23.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc34
// CHECK:STDOUT:   %.loc34_23.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc34, %.loc34_23.5
// CHECK:STDOUT:   if %.loc34_23.6 br !match.case.then.loc34 else br !match.case.else.loc34
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc34:
// CHECK:STDOUT:   %.loc34_23.7: ref %.677 = class_element_access %e.ref, element1
// CHECK:STDOUT:   %.loc34_23.8: ref %tuple.type.a8a = class_element_access %.loc34_23.7, element1
// CHECK:STDOUT:   %tuple.elem0.loc34_23.1: ref %i32 = tuple_access %.loc34_23.8, element0
// CHECK:STDOUT:   %impl.elem0.loc34_23.3: %.9a0 = impl_witness_access constants.%ImplicitAs.impl_witness.a40, element0 [concrete = constants.%From.as_type.as.ImplicitAs.impl.Convert.e3c]
// CHECK:STDOUT:   %bound_method.loc34_23.5: <bound method> = bound_method %tuple.elem0.loc34_23.1, %impl.elem0.loc34_23.3
// CHECK:STDOUT:   %specific_fn.loc34_23.3: <specific function> = specific_function %impl.elem0.loc34_23.3, @From.as_type.as.ImplicitAs.impl.Convert(constants.%int_64, constants.%facet_value) [concrete = constants.%From.as_type.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc34_23.6: <bound method> = bound_method %tuple.elem0.loc34_23.1, %specific_fn.loc34_23.3
// CHECK:STDOUT:   %.loc34_23.9: %i32 = acquire_value %tuple.elem0.loc34_23.1
// CHECK:STDOUT:   %From.as_type.as.ImplicitAs.impl.Convert.call.loc34: init %i64 = call %bound_method.loc34_23.6(%.loc34_23.9)
// CHECK:STDOUT:   %.loc34_23.10: %i64 = value_of_initializer %From.as_type.as.ImplicitAs.impl.Convert.call.loc34
// CHECK:STDOUT:   %.loc34_23.11: %i64 = converted %tuple.elem0.loc34_23.1, %.loc34_23.10
// CHECK:STDOUT:   %tuple.loc34: %tuple.type.f67 = tuple_value (%.loc34_23.11)
// CHECK:STDOUT:   %.loc34_16.2: %tuple.type.f67 = converted %.loc34_23.8, %tuple.loc34
// CHECK:STDOUT:   %tuple.elem0.loc34_23.2: %i64 = tuple_access %.loc34_16.2, element0
// CHECK:STDOUT:   %i64.loc34: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:   %n: %i64 = wrapper_binding n, %tuple.elem0.loc34_23.2
// CHECK:STDOUT:   %n.ref: %i64 = name_ref n, %n
// CHECK:STDOUT:   %impl.elem0.loc34_35: %.3cb = impl_witness_access constants.%Copy.impl_witness.c5e, element0 [concrete = constants.%Int.as.Copy.impl.Op.d73]
// CHECK:STDOUT:   %bound_method.loc34_35.1: <bound method> = bound_method %n.ref, %impl.elem0.loc34_35
// CHECK:STDOUT:   %specific_fn.loc34_35: <specific function> = specific_function %impl.elem0.loc34_35, @Int.as.Copy.impl.Op(constants.%int_64) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn.b95]
// CHECK:STDOUT:   %bound_method.loc34_35.2: <bound method> = bound_method %n.ref, %specific_fn.loc34_35
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call.loc34: init %i64 = call %bound_method.loc34_35.2(%n.ref)
// CHECK:STDOUT:   return %Int.as.Copy.impl.Op.call.loc34
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc34:
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %.loc35_14: %pattern_type.cb1 = tuple_pattern () [concrete = constants.%.e84]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:   %impl.elem0.loc35_16.1: %.66c = impl_witness_access constants.%ImplicitAs.impl_witness.e93, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.409]
// CHECK:STDOUT:   %bound_method.loc35_16.1: <bound method> = bound_method %int_2, %impl.elem0.loc35_16.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.6c9]
// CHECK:STDOUT:   %specific_fn.loc35_16.1: <specific function> = specific_function %impl.elem0.loc35_16.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_2.ecc) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.a72]
// CHECK:STDOUT:   %bound_method.loc35_16.2: <bound method> = bound_method %int_2, %specific_fn.loc35_16.1 [concrete = constants.%bound_method.135]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc35_16: init %u2 = call %bound_method.loc35_16.2(%int_2) [concrete = constants.%int_2.996]
// CHECK:STDOUT:   %.loc35_16.1: %u2 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc35_16 [concrete = constants.%int_2.996]
// CHECK:STDOUT:   %.loc35_16.2: %u2 = converted %int_2, %.loc35_16.1 [concrete = constants.%int_2.996]
// CHECK:STDOUT:   %.loc35_16.3: ref %u2 = class_element_access %e.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc35_16.2: %.7a0 = impl_witness_access constants.%EqWith.impl_witness.454, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.e76]
// CHECK:STDOUT:   %bound_method.loc35_16.3: <bound method> = bound_method %.loc35_16.2, %impl.elem0.loc35_16.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.99a]
// CHECK:STDOUT:   %specific_fn.loc35_16.2: <specific function> = specific_function %impl.elem0.loc35_16.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_2.ecc, constants.%int_2.ecc) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.149]
// CHECK:STDOUT:   %bound_method.loc35_16.4: <bound method> = bound_method %.loc35_16.2, %specific_fn.loc35_16.2 [concrete = constants.%bound_method.64f]
// CHECK:STDOUT:   %.loc35_16.4: %u2 = acquire_value %.loc35_16.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc35: init bool = call %bound_method.loc35_16.4(%.loc35_16.2, %.loc35_16.4)
// CHECK:STDOUT:   %.loc35_16.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc35
// CHECK:STDOUT:   %.loc35_16.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc35, %.loc35_16.5
// CHECK:STDOUT:   if %.loc35_16.6 br !match.case.then.loc35 else br !match.case.else.loc35
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc35:
// CHECK:STDOUT:   %int_1.loc35: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc35_29: %.f349 = impl_witness_access constants.%ImplicitAs.impl_witness.091, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b]
// CHECK:STDOUT:   %bound_method.loc35_29.1: <bound method> = bound_method %int_1.loc35, %impl.elem0.loc35_29 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.89f]
// CHECK:STDOUT:   %specific_fn.loc35_29: <specific function> = specific_function %impl.elem0.loc35_29, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.f33]
// CHECK:STDOUT:   %bound_method.loc35_29.2: <bound method> = bound_method %int_1.loc35, %specific_fn.loc35_29 [concrete = constants.%bound_method.c5e]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc35_29: init %i64 = call %bound_method.loc35_29.2(%int_1.loc35) [concrete = constants.%int_1.d98]
// CHECK:STDOUT:   %.loc35_29: init %i64 = converted %int_1.loc35, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc35_29 [concrete = constants.%int_1.d98]
// CHECK:STDOUT:   return %.loc35_29
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc35:
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt: %pattern_type.afb = expr_pattern %Off.ref in [concrete] {
// CHECK:STDOUT:       %Off.ref: %Event = name_ref Off, @Event.%Off
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Off.ref: %Event = name_ref Off, @Event.%Off
// CHECK:STDOUT:   %int_3: Core.IntLiteral = int_value 3 [concrete = constants.%int_3.1ba]
// CHECK:STDOUT:   %impl.elem0.loc36_15.1: %.66c = impl_witness_access constants.%ImplicitAs.impl_witness.e93, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.409]
// CHECK:STDOUT:   %bound_method.loc36_15.1: <bound method> = bound_method %int_3, %impl.elem0.loc36_15.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.0d0]
// CHECK:STDOUT:   %specific_fn.loc36_15.1: <specific function> = specific_function %impl.elem0.loc36_15.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_2.ecc) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.a72]
// CHECK:STDOUT:   %bound_method.loc36_15.2: <bound method> = bound_method %int_3, %specific_fn.loc36_15.1 [concrete = constants.%bound_method.f45]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc36_15: init %u2 = call %bound_method.loc36_15.2(%int_3) [concrete = constants.%int_3.184]
// CHECK:STDOUT:   %.loc36_15.1: %u2 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc36_15 [concrete = constants.%int_3.184]
// CHECK:STDOUT:   %.loc36_15.2: %u2 = converted %int_3, %.loc36_15.1 [concrete = constants.%int_3.184]
// CHECK:STDOUT:   %.loc36_15.3: ref %u2 = class_element_access %e.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc36_15.2: %.7a0 = impl_witness_access constants.%EqWith.impl_witness.454, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.e76]
// CHECK:STDOUT:   %bound_method.loc36_15.3: <bound method> = bound_method %.loc36_15.2, %impl.elem0.loc36_15.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.163]
// CHECK:STDOUT:   %specific_fn.loc36_15.2: <specific function> = specific_function %impl.elem0.loc36_15.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_2.ecc, constants.%int_2.ecc) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.149]
// CHECK:STDOUT:   %bound_method.loc36_15.4: <bound method> = bound_method %.loc36_15.2, %specific_fn.loc36_15.2 [concrete = constants.%bound_method.d66]
// CHECK:STDOUT:   %.loc36_15.4: %u2 = acquire_value %.loc36_15.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc36: init bool = call %bound_method.loc36_15.4(%.loc36_15.2, %.loc36_15.4)
// CHECK:STDOUT:   %.loc36_15.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc36
// CHECK:STDOUT:   %.loc36_15.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc36, %.loc36_15.5
// CHECK:STDOUT:   if %.loc36_15.6 br !match.case.then.loc36 else br !match.case.else.loc36
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc36:
// CHECK:STDOUT:   %int_0.loc36: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc36_28: %.f349 = impl_witness_access constants.%ImplicitAs.impl_witness.091, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b]
// CHECK:STDOUT:   %bound_method.loc36_28.1: <bound method> = bound_method %int_0.loc36, %impl.elem0.loc36_28 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.0a3]
// CHECK:STDOUT:   %specific_fn.loc36_28: <specific function> = specific_function %impl.elem0.loc36_28, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.f33]
// CHECK:STDOUT:   %bound_method.loc36_28.2: <bound method> = bound_method %int_0.loc36, %specific_fn.loc36_28 [concrete = constants.%bound_method.0c1]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc36_28: init %i64 = call %bound_method.loc36_28.2(%int_0.loc36) [concrete = constants.%int_0.2e4]
// CHECK:STDOUT:   %.loc36_28: init %i64 = converted %int_0.loc36, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc36_28 [concrete = constants.%int_0.2e4]
// CHECK:STDOUT:   return %.loc36_28
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc36:
// CHECK:STDOUT:   %int_1.loc37: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem1: %.02b = impl_witness_access constants.%Negate.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %bound_method.loc37_25: <bound method> = bound_method %int_1.loc37, %impl.elem1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op.bound.6a0]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.call: init Core.IntLiteral = call %bound_method.loc37_25(%int_1.loc37) [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %impl.elem0.loc37: %.f349 = impl_witness_access constants.%ImplicitAs.impl_witness.091, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b]
// CHECK:STDOUT:   %bound_method.loc37_27.1: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %impl.elem0.loc37 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.bc7]
// CHECK:STDOUT:   %specific_fn.loc37: <specific function> = specific_function %impl.elem0.loc37, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.f33]
// CHECK:STDOUT:   %bound_method.loc37_27.2: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %specific_fn.loc37 [concrete = constants.%bound_method.ef0]
// CHECK:STDOUT:   %.loc37_25.1: Core.IntLiteral = value_of_initializer %Core.IntLiteral.as.Negate.impl.Op.call [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %.loc37_25.2: Core.IntLiteral = converted %Core.IntLiteral.as.Negate.impl.Op.call, %.loc37_25.1 [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc37: init %i64 = call %bound_method.loc37_27.2(%.loc37_25.2) [concrete = constants.%int_-1.a7e]
// CHECK:STDOUT:   %.loc37_27: init %i64 = converted %Core.IntLiteral.as.Negate.impl.Op.call, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc37 [concrete = constants.%int_-1.a7e]
// CHECK:STDOUT:   return %.loc37_27
// CHECK:STDOUT: }
// CHECK:STDOUT:
