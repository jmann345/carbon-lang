// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/choice/optional_pointer_payload.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/choice/optional_pointer_payload.carbon

// Fork (SV-1, fork/sumtype-interop/plan.md D-SV-8): the SF-6 payload
// predicate admits the pointer-niche `Core.Optional(T*)` -- an adapter of
// `MaybeUnformed(T*)` -- by name, as a pointer payload; `Core.Optional(T)` for
// a non-pointer `T`, and the other qualified adapters (`Cpp.nullptr_t`,
// `Core.MaybeUnformed(T)`), are still not payloads.

// --- pointer.carbon

library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
choice Slot {
  Held(p: Core.Optional(i32*)),
  Empty
}

fn Read(s: Slot) -> bool {
  match (s) {
    case .Held(p: Core.Optional(i32*)) => {
      return p.HasValue();
    }
    case .Empty => {
      return false;
    }
  }
  return false;
}
//@dump-sem-ir-end

// --- fail_todo_non_pointer_optional.carbon

library "[[@TEST_NAME]]";

choice Boxed {
  // CHECK:STDERR: fail_todo_non_pointer_optional.carbon:[[@LINE+4]]:7: error: semantics TODO: `choice alternative payload that is not trivially copyable and destructible` [SemanticsTodo]
  // CHECK:STDERR:   Held(o: Core.Optional(i32)),
  // CHECK:STDERR:       ^~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  Held(o: Core.Optional(i32)),
  Empty
}

// --- fail_todo_nullptr_payload.carbon

library "[[@TEST_NAME]]";

choice NullBox {
  // CHECK:STDERR: fail_todo_nullptr_payload.carbon:[[@LINE+4]]:7: error: semantics TODO: `choice alternative payload that is not trivially copyable and destructible` [SemanticsTodo]
  // CHECK:STDERR:   Held(p: Core.CppCompat.NullptrT),
  // CHECK:STDERR:       ^~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  Held(p: Core.CppCompat.NullptrT),
  Empty
}

// --- fail_todo_maybe_unformed_payload.carbon

library "[[@TEST_NAME]]";

choice Unformed {
  // CHECK:STDERR: fail_todo_maybe_unformed_payload.carbon:[[@LINE+4]]:7: error: semantics TODO: `choice alternative payload that is not trivially copyable and destructible` [SemanticsTodo]
  // CHECK:STDERR:   Held(x: Core.MaybeUnformed(i32*)),
  // CHECK:STDERR:       ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  Held(x: Core.MaybeUnformed(i32*)),
  Empty
}

// CHECK:STDOUT: --- pointer.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %Slot: type = class_type @Slot [concrete]
// CHECK:STDOUT:   %Optional.type: type = generic_class_type @Optional [concrete]
// CHECK:STDOUT:   %Optional.generic: %Optional.type = struct_value () [concrete]
// CHECK:STDOUT:   %OptionalStorage.type: type = facet_type <@OptionalStorage> [concrete]
// CHECK:STDOUT:   %pattern_type.831: type = pattern_type bool [concrete]
// CHECK:STDOUT:   %return.param_patt.5a1: %pattern_type.831 = out_param_pattern [concrete]
// CHECK:STDOUT:   %.f34: Core.Form = init_form bool [concrete]
// CHECK:STDOUT:   %T.220: %OptionalStorage.type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %Optional.HasValue.type.e9e: type = fn_type @Optional.HasValue, @Optional(%T.220) [symbolic]
// CHECK:STDOUT:   %Optional.HasValue.6cd: %Optional.HasValue.type.e9e = struct_value () [symbolic]
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
// CHECK:STDOUT:   %ptr.as.OptionalStorage.impl.Copy.type.27d: type = fn_type @ptr.as.OptionalStorage.impl.Copy, @ptr.as.OptionalStorage.impl(%T.67d) [symbolic]
// CHECK:STDOUT:   %ptr.as.OptionalStorage.impl.Copy.c8d: %ptr.as.OptionalStorage.impl.Copy.type.27d = struct_value () [symbolic]
// CHECK:STDOUT:   %ptr.as.OptionalStorage.impl.Has.type.0e1: type = fn_type @ptr.as.OptionalStorage.impl.Has, @ptr.as.OptionalStorage.impl(%T.67d) [symbolic]
// CHECK:STDOUT:   %ptr.as.OptionalStorage.impl.Has.05c: %ptr.as.OptionalStorage.impl.Has.type.0e1 = struct_value () [symbolic]
// CHECK:STDOUT:   %OptionalStorage.impl_witness.0ce: <witness> = impl_witness imports.%OptionalStorage.impl_witness_table.110, @ptr.as.OptionalStorage.impl(%i32) [concrete]
// CHECK:STDOUT:   %OptionalStorage.facet: %OptionalStorage.type = facet_value %ptr.d08, (%OptionalStorage.impl_witness.0ce) [concrete]
// CHECK:STDOUT:   %Optional.5b3: type = class_type @Optional, @Optional(%OptionalStorage.facet) [concrete]
// CHECK:STDOUT:   %pattern_type.ef8: type = pattern_type %Optional.5b3 [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %UInt.type: type = generic_class_type @UInt [concrete]
// CHECK:STDOUT:   %UInt.generic: %UInt.type = struct_value () [concrete]
// CHECK:STDOUT:   %u1: type = class_type @UInt, @UInt(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Optional.HasValue.type.c62: type = fn_type @Optional.HasValue, @Optional(%OptionalStorage.facet) [concrete]
// CHECK:STDOUT:   %Optional.HasValue.84d: %Optional.HasValue.type.c62 = struct_value () [concrete]
// CHECK:STDOUT:   %tuple.type.e2f: type = tuple_type (%Optional.5b3) [concrete]
// CHECK:STDOUT:   %.dcd: type = custom_layout_type {size=8, align=8, .Held@0: %tuple.type.e2f} [concrete]
// CHECK:STDOUT:   %struct_type.discriminant.payload.caa: type = struct_type {.discriminant: %u1, .payload: %.dcd} [concrete]
// CHECK:STDOUT:   %complete_type.24c: <witness> = complete_type_witness %struct_type.discriminant.payload.caa [concrete]
// CHECK:STDOUT:   %struct_type.discriminant: type = struct_type {.discriminant: %u1} [concrete]
// CHECK:STDOUT:   %_.param_patt: %pattern_type.ef8 = value_param_pattern [concrete]
// CHECK:STDOUT:   %_.patt: %pattern_type.ef8 = wrapper_binding_pattern _, %_.param_patt [concrete]
// CHECK:STDOUT:   %.14e: Core.Form = init_form %Slot [concrete]
// CHECK:STDOUT:   %pattern_type.c59: type = pattern_type %Slot [concrete]
// CHECK:STDOUT:   %return.param_patt.450: %pattern_type.c59 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.8a9: %pattern_type.c59 = return_slot_pattern %return.param_patt.450, %Slot [concrete]
// CHECK:STDOUT:   %Slot.Held.type: type = fn_type @Slot.Held [concrete]
// CHECK:STDOUT:   %Slot.Held: %Slot.Held.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.0ff: type = generic_interface_type @ImplicitAs [concrete]
// CHECK:STDOUT:   %ImplicitAs.generic: %ImplicitAs.type.0ff = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.ca1: type = facet_type <@ImplicitAs, @ImplicitAs(%u1)> [concrete]
// CHECK:STDOUT:   %To.fe9: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.b68(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.170: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.f4c: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.f01, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet: %ImplicitAs.type.ca1 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.f4c) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.77c: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%u1, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.e74: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.77c, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.0e8: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_0.1a7: %u1 = int_value 0 [concrete]
// CHECK:STDOUT:   %Optional.as.Copy.impl.Op.type.516: type = fn_type @Optional.as.Copy.impl.Op, @Optional.as.Copy.impl(%T.220) [symbolic]
// CHECK:STDOUT:   %Optional.as.Copy.impl.Op.3a2: %Optional.as.Copy.impl.Op.type.516 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b42: <witness> = impl_witness imports.%Copy.impl_witness_table.777, @Optional.as.Copy.impl(%OptionalStorage.facet) [concrete]
// CHECK:STDOUT:   %Optional.as.Copy.impl.Op.type.68a: type = fn_type @Optional.as.Copy.impl.Op, @Optional.as.Copy.impl(%OptionalStorage.facet) [concrete]
// CHECK:STDOUT:   %Optional.as.Copy.impl.Op.8ee: %Optional.as.Copy.impl.Op.type.68a = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet.398: %Copy.type = facet_value %Optional.5b3, (%Copy.impl_witness.b42) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.ec5: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.398) [concrete]
// CHECK:STDOUT:   %.82f35: type = fn_type_with_self_type %Copy.WithSelf.Op.type.ec5, %Copy.facet.398 [concrete]
// CHECK:STDOUT:   %Optional.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Optional.as.Copy.impl.Op.8ee, @Optional.as.Copy.impl.Op(%OptionalStorage.facet) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %bound_method.d7a: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_1.233: %u1 = int_value 1 [concrete]
// CHECK:STDOUT:   %struct: %struct_type.discriminant = struct_value (%int_1.233) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.type.0c5: type = fn_type @UInt.as.Copy.impl.Op, @UInt.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.38a: %UInt.as.Copy.impl.Op.type.0c5 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.334: <witness> = impl_witness imports.%Copy.impl_witness_table.ae7, @UInt.as.Copy.impl(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.type.c97: type = fn_type @UInt.as.Copy.impl.Op, @UInt.as.Copy.impl(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.d9c: %UInt.as.Copy.impl.Op.type.c97 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet.18b: %Copy.type = facet_value %u1, (%Copy.impl_witness.334) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.703: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.18b) [concrete]
// CHECK:STDOUT:   %.952: type = fn_type_with_self_type %Copy.WithSelf.Op.type.703, %Copy.facet.18b [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.bound: <bound method> = bound_method %int_1.233, %UInt.as.Copy.impl.Op.d9c [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %UInt.as.Copy.impl.Op.d9c, @UInt.as.Copy.impl.Op(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.edd: <bound method> = bound_method %int_1.233, %UInt.as.Copy.impl.Op.specific_fn [concrete]
// CHECK:STDOUT:   %uninit: %.dcd = uninitialized_value [concrete]
// CHECK:STDOUT:   %Slot.val: %Slot = struct_value (%int_1.233, %uninit) [concrete]
// CHECK:STDOUT:   %.8f9: ref %Slot = temporary invalid, %Slot.val [concrete]
// CHECK:STDOUT:   %s.param_patt: %pattern_type.c59 = value_param_pattern [concrete]
// CHECK:STDOUT:   %s.patt: %pattern_type.c59 = wrapper_binding_pattern s, %s.param_patt [concrete]
// CHECK:STDOUT:   %return.patt.c0c: %pattern_type.831 = return_slot_pattern %return.param_patt.5a1, bool [concrete]
// CHECK:STDOUT:   %Read.type: type = fn_type @Read [concrete]
// CHECK:STDOUT:   %Read: %Read.type = struct_value () [concrete]
// CHECK:STDOUT:   %p.patt.201: %pattern_type.ef8 = value_binding_pattern p [concrete]
// CHECK:STDOUT:   %pattern_type.26e: type = pattern_type %tuple.type.e2f [concrete]
// CHECK:STDOUT:   %.f12: %pattern_type.26e = tuple_pattern (%p.patt.201) [concrete]
// CHECK:STDOUT:   %EqWith.type.f77: type = generic_interface_type @EqWith [concrete]
// CHECK:STDOUT:   %EqWith.generic: %EqWith.type.f77 = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.type.c25: type = facet_type <@EqWith, @EqWith(%u1)> [concrete]
// CHECK:STDOUT:   %M: Core.IntLiteral = symbolic_binding M, 1 [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.544: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%N, %M) [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.c67: %UInt.as.EqWith.impl.Equal.type.544 = struct_value () [symbolic]
// CHECK:STDOUT:   %EqWith.impl_witness.7b3: <witness> = impl_witness imports.%EqWith.impl_witness_table.166, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.29b: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.ba4: %UInt.as.EqWith.impl.Equal.type.29b = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.4d0: %EqWith.type.c25 = facet_value %u1, (%EqWith.impl_witness.7b3) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.e3c: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%u1, %EqWith.facet.4d0) [concrete]
// CHECK:STDOUT:   %.9eb: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.e3c, %EqWith.facet.4d0 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound.f34: <bound method> = bound_method %int_0.1a7, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.specific_fn.6b6: <specific function> = specific_function %UInt.as.EqWith.impl.Equal.ba4, @UInt.as.EqWith.impl.Equal.1(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.53a: <bound method> = bound_method %int_0.1a7, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
// CHECK:STDOUT:   %Optional.HasValue.specific_fn: <specific function> = specific_function %Optional.HasValue.84d, @Optional.HasValue(%OptionalStorage.facet) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound.22c: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %bound_method.a82: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
// CHECK:STDOUT:   %false: bool = bool_literal false [concrete]
// CHECK:STDOUT:   %Copy.impl_witness.5e1: <witness> = impl_witness imports.%Copy.impl_witness_table.bda [concrete]
// CHECK:STDOUT:   %Copy.facet.7af: %Copy.type = facet_value bool, (%Copy.impl_witness.5e1) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.d02: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.7af) [concrete]
// CHECK:STDOUT:   %.e28: type = fn_type_with_self_type %Copy.WithSelf.Op.type.d02, %Copy.facet.7af [concrete]
// CHECK:STDOUT:   %bool.as.Copy.impl.Op.type: type = fn_type @bool.as.Copy.impl.Op [concrete]
// CHECK:STDOUT:   %bool.as.Copy.impl.Op: %bool.as.Copy.impl.Op.type = struct_value () [concrete]
// CHECK:STDOUT:   %bool.as.Copy.impl.Op.bound: <bound method> = bound_method %false, %bool.as.Copy.impl.Op [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .Optional = %Core.Optional
// CHECK:STDOUT:     .Int = %Core.Int
// CHECK:STDOUT:     .UInt = %Core.UInt
// CHECK:STDOUT:     .ImplicitAs = %Core.ImplicitAs
// CHECK:STDOUT:     .Copy = %Core.Copy.e5d
// CHECK:STDOUT:     .Bool = %Core.Bool
// CHECK:STDOUT:     .EqWith = %Core.EqWith
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Optional: %Optional.type = import_ref Core//prelude/types/optional, Optional, loaded [concrete = constants.%Optional.generic]
// CHECK:STDOUT:   %Core.import_ref.729: @Optional.%Optional.HasValue.type (%Optional.HasValue.type.e9e) = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @Optional.%Optional.HasValue (constants.%Optional.HasValue.6cd)]
// CHECK:STDOUT:   %Core.Int: %Int.type = import_ref Core//prelude/types/int, Int, loaded [concrete = constants.%Int.generic]
// CHECK:STDOUT:   %Core.import_ref.509: type = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @ptr.as.OptionalStorage.impl.%MaybeUnformed (constants.%MaybeUnformed.ddb)]
// CHECK:STDOUT:   %Core.import_ref.105 = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.c9a = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.575: @ptr.as.OptionalStorage.impl.%ptr.as.OptionalStorage.impl.Has.type (%ptr.as.OptionalStorage.impl.Has.type.0e1) = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @ptr.as.OptionalStorage.impl.%ptr.as.OptionalStorage.impl.Has (constants.%ptr.as.OptionalStorage.impl.Has.05c)]
// CHECK:STDOUT:   %Core.import_ref.306 = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.f85: @ptr.as.OptionalStorage.impl.%ptr.as.OptionalStorage.impl.Copy.type (%ptr.as.OptionalStorage.impl.Copy.type.27d) = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @ptr.as.OptionalStorage.impl.%ptr.as.OptionalStorage.impl.Copy (constants.%ptr.as.OptionalStorage.impl.Copy.c8d)]
// CHECK:STDOUT:   %OptionalStorage.impl_witness_table.110 = impl_witness_table (%Core.import_ref.509, %Core.import_ref.105, %Core.import_ref.c9a, %Core.import_ref.575, %Core.import_ref.306, %Core.import_ref.f85), @ptr.as.OptionalStorage.impl [concrete]
// CHECK:STDOUT:   %Core.UInt: %UInt.type = import_ref Core//prelude/types/uint, UInt, loaded [concrete = constants.%UInt.generic]
// CHECK:STDOUT:   %Core.ImplicitAs: %ImplicitAs.type.0ff = import_ref Core//prelude/operators/as, ImplicitAs, loaded [concrete = constants.%ImplicitAs.generic]
// CHECK:STDOUT:   %Core.import_ref.aa5: @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.170)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.f01 = impl_witness_table (%Core.import_ref.aa5), @Core.IntLiteral.as.ImplicitAs.impl.b68 [concrete]
// CHECK:STDOUT:   %Core.Copy.e5d: type = import_ref Core//prelude/copy, Copy, loaded [concrete = constants.%Copy.type]
// CHECK:STDOUT:   %Core.import_ref.c7b: @Optional.as.Copy.impl.%Optional.as.Copy.impl.Op.type (%Optional.as.Copy.impl.Op.type.516) = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @Optional.as.Copy.impl.%Optional.as.Copy.impl.Op (constants.%Optional.as.Copy.impl.Op.3a2)]
// CHECK:STDOUT:   %Copy.impl_witness_table.777 = impl_witness_table (%Core.import_ref.c7b), @Optional.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.791: @UInt.as.Copy.impl.%UInt.as.Copy.impl.Op.type (%UInt.as.Copy.impl.Op.type.0c5) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.Copy.impl.%UInt.as.Copy.impl.Op (constants.%UInt.as.Copy.impl.Op.38a)]
// CHECK:STDOUT:   %Copy.impl_witness_table.ae7 = impl_witness_table (%Core.import_ref.791), @UInt.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.Bool: type = import_ref Core//prelude/types/bool, Bool, loaded [concrete = bool]
// CHECK:STDOUT:   %Core.EqWith: %EqWith.type.f77 = import_ref Core//prelude/operators/comparison, EqWith, loaded [concrete = constants.%EqWith.generic]
// CHECK:STDOUT:   %Core.import_ref.b92: @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal.type (%UInt.as.EqWith.impl.Equal.type.544) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal (constants.%UInt.as.EqWith.impl.Equal.c67)]
// CHECK:STDOUT:   %Core.import_ref.b44 = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.166 = impl_witness_table (%Core.import_ref.b92, %Core.import_ref.b44), @UInt.as.EqWith.impl.f13 [concrete]
// CHECK:STDOUT:   %Core.import_ref.9c3: %bool.as.Copy.impl.Op.type = import_ref Core//prelude/copy, loc{{\d+_\d+}}, loaded [concrete = constants.%bool.as.Copy.impl.Op]
// CHECK:STDOUT:   %Copy.impl_witness_table.bda = impl_witness_table (%Core.import_ref.9c3), @bool.as.Copy.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %Slot.Held.decl: %Slot.Held.type = fn_decl @Slot.Held [concrete = constants.%Slot.Held] {
// CHECK:STDOUT:     %_.param_patt: %pattern_type.ef8 = value_param_pattern [concrete = constants.%_.param_patt]
// CHECK:STDOUT:     %_.patt: %pattern_type.ef8 = wrapper_binding_pattern _, %_.param_patt [concrete = constants.%_.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.c59 = out_param_pattern [concrete = constants.%return.param_patt.450]
// CHECK:STDOUT:     %return.patt: %pattern_type.c59 = return_slot_pattern %return.param_patt, constants.%Slot [concrete = constants.%return.patt.8a9]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc5_13.9: Core.Form = init_form constants.%Slot [concrete = constants.%.14e]
// CHECK:STDOUT:     %_.param: %Optional.5b3 = value_param call_param0
// CHECK:STDOUT:     %_: %Optional.5b3 = wrapper_binding _, %_.param
// CHECK:STDOUT:     %return.param: ref %Slot = out_param call_param1
// CHECK:STDOUT:     %return: ref %Slot = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Slot.decl: type = class_decl @Slot [concrete = constants.%Slot] {} {}
// CHECK:STDOUT:   %Read.decl: %Read.type = fn_decl @Read [concrete = constants.%Read] {
// CHECK:STDOUT:     %s.param_patt: %pattern_type.c59 = value_param_pattern [concrete = constants.%s.param_patt]
// CHECK:STDOUT:     %s.patt: %pattern_type.c59 = wrapper_binding_pattern s, %s.param_patt [concrete = constants.%s.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.831 = out_param_pattern [concrete = constants.%return.param_patt.5a1]
// CHECK:STDOUT:     %return.patt: %pattern_type.831 = return_slot_pattern %return.param_patt, %.loc10_21.1 [concrete = constants.%return.patt.c0c]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc10_21.1: type = type_literal bool [concrete = bool]
// CHECK:STDOUT:     %.loc10_21.2: Core.Form = init_form %.loc10_21.1 [concrete = constants.%.f34]
// CHECK:STDOUT:     %s.param: %Slot = value_param call_param0
// CHECK:STDOUT:     %Slot.ref: type = name_ref Slot, file.%Slot.decl [concrete = constants.%Slot]
// CHECK:STDOUT:     %s: %Slot = wrapper_binding s, %s.param
// CHECK:STDOUT:     %return.param: ref bool = out_param call_param1
// CHECK:STDOUT:     %return: ref bool = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: class @Slot {
// CHECK:STDOUT:   %p.param: %Optional.5b3 = value_param call_param0
// CHECK:STDOUT:   %.loc6_29.1: type = splice_block %Optional [concrete = constants.%Optional.5b3] {
// CHECK:STDOUT:     %Core.ref: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:     %Optional.ref: %Optional.type = name_ref Optional, imports.%Core.Optional [concrete = constants.%Optional.generic]
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %ptr: type = ptr_type %i32 [concrete = constants.%ptr.d08]
// CHECK:STDOUT:     %OptionalStorage.facet: %OptionalStorage.type = facet_value %ptr, (constants.%OptionalStorage.impl_witness.0ce) [concrete = constants.%OptionalStorage.facet]
// CHECK:STDOUT:     %.loc6_29.2: %OptionalStorage.type = converted %ptr, %OptionalStorage.facet [concrete = constants.%OptionalStorage.facet]
// CHECK:STDOUT:     %Optional: type = class_type @Optional, @Optional(constants.%OptionalStorage.facet) [concrete = constants.%Optional.5b3]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %p: %Optional.5b3 = wrapper_binding p, %p.param
// CHECK:STDOUT:   %.loc8_1.1: type = custom_layout_type {size=8, align=8, .Held@0: %tuple.type.e2f} [concrete = constants.%.dcd]
// CHECK:STDOUT:   %complete_type: <witness> = complete_type_witness constants.%struct_type.discriminant.payload.caa [concrete = constants.%complete_type.24c]
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc8_1.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc8_1.1: <bound method> = bound_method %int_1, %impl.elem0.loc8_1.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc8_1.1: <specific function> = specific_function %impl.elem0.loc8_1.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc8_1.2: <bound method> = bound_method %int_1, %specific_fn.loc8_1.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %u1 = call %bound_method.loc8_1.2(%int_1) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc8_1.2: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc8_1.3: %u1 = converted %int_1, %.loc8_1.2 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc8_1.4: %struct_type.discriminant = struct_literal (%.loc8_1.3) [concrete = constants.%struct]
// CHECK:STDOUT:   %impl.elem0.loc8_1.2: %.952 = impl_witness_access constants.%Copy.impl_witness.334, element0 [concrete = constants.%UInt.as.Copy.impl.Op.d9c]
// CHECK:STDOUT:   %bound_method.loc8_1.3: <bound method> = bound_method %.loc8_1.3, %impl.elem0.loc8_1.2 [concrete = constants.%UInt.as.Copy.impl.Op.bound]
// CHECK:STDOUT:   %specific_fn.loc8_1.2: <specific function> = specific_function %impl.elem0.loc8_1.2, @UInt.as.Copy.impl.Op(constants.%int_1.5b8) [concrete = constants.%UInt.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc8_1.4: <bound method> = bound_method %.loc8_1.3, %specific_fn.loc8_1.2 [concrete = constants.%bound_method.edd]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.call: init %u1 = call %bound_method.loc8_1.4(%.loc8_1.3) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc8_1.5: ref %Slot = temporary_storage
// CHECK:STDOUT:   %.loc8_1.6: ref %u1 = class_element_access %.loc8_1.5, element0
// CHECK:STDOUT:   %.loc8_1.7: init %u1 to %.loc8_1.6 = in_place_init %UInt.as.Copy.impl.Op.call [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc8_1.8: ref %.dcd = class_element_access %.loc8_1.5, element1
// CHECK:STDOUT:   %uninit: %.dcd = uninitialized_value [concrete = constants.%uninit]
// CHECK:STDOUT:   %.loc8_1.9: init %.dcd to %.loc8_1.8 = in_place_init %uninit [concrete = constants.%uninit]
// CHECK:STDOUT:   %.loc8_1.10: init %Slot to %.loc8_1.5 = class_init (%.loc8_1.7, %.loc8_1.9) [concrete = constants.%Slot.val]
// CHECK:STDOUT:   %.loc8_1.11: init %Slot = converted %.loc8_1.4, %.loc8_1.10 [concrete = constants.%Slot.val]
// CHECK:STDOUT:   %.loc8_1.12: ref %Slot = temporary %.loc8_1.5, %.loc8_1.11 [concrete = constants.%.8f9]
// CHECK:STDOUT:   %.loc8_1.13: %Slot = acquire_value %.loc8_1.12 [concrete = constants.%Slot.val]
// CHECK:STDOUT:   %Empty: %Slot = wrapper_binding Empty, %.loc8_1.13
// CHECK:STDOUT:   complete_type_witness = %complete_type
// CHECK:STDOUT:
// CHECK:STDOUT: !members:
// CHECK:STDOUT:   .Self = constants.%Slot
// CHECK:STDOUT:   .Held = generated.%Slot.Held.decl
// CHECK:STDOUT:   .Empty = %Empty
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Slot.Held(%_.param: %Optional.5b3) -> out %return.param: %Slot {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %.loc5_13.1: ref %u1 = class_element_access %return.param, element0
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc5_13.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc5_13.1: <bound method> = bound_method %int_0, %impl.elem0.loc5_13.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:   %specific_fn.loc5_13.1: <specific function> = specific_function %impl.elem0.loc5_13.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc5_13.2: <bound method> = bound_method %int_0, %specific_fn.loc5_13.1 [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %u1 = call %bound_method.loc5_13.2(%int_0) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc5_13.2: init %u1 = converted %int_0, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc5_13.3: init %u1 to %.loc5_13.1 = in_place_init %.loc5_13.2 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc5_13.4: ref %.dcd = class_element_access %return.param, element1
// CHECK:STDOUT:   %.loc5_13.5: ref %tuple.type.e2f = class_element_access %.loc5_13.4, element0
// CHECK:STDOUT:   %.loc6_31.1: %tuple.type.e2f = tuple_literal (%_.param)
// CHECK:STDOUT:   %impl.elem0.loc5_13.2: %.82f35 = impl_witness_access constants.%Copy.impl_witness.b42, element0 [concrete = constants.%Optional.as.Copy.impl.Op.8ee]
// CHECK:STDOUT:   %bound_method.loc5_13.3: <bound method> = bound_method %_.param, %impl.elem0.loc5_13.2
// CHECK:STDOUT:   %specific_fn.loc5_13.2: <specific function> = specific_function %impl.elem0.loc5_13.2, @Optional.as.Copy.impl.Op(constants.%OptionalStorage.facet) [concrete = constants.%Optional.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc5_13.4: <bound method> = bound_method %_.param, %specific_fn.loc5_13.2
// CHECK:STDOUT:   %Optional.as.Copy.impl.Op.call: init %Optional.5b3 = call %bound_method.loc5_13.4(%_.param)
// CHECK:STDOUT:   %.loc6_31.2: init %tuple.type.e2f to %.loc5_13.5 = tuple_init (%Optional.as.Copy.impl.Op.call)
// CHECK:STDOUT:   %.loc5_13.6: init %tuple.type.e2f = converted %.loc6_31.1, %.loc6_31.2
// CHECK:STDOUT:   %.loc5_13.7: init %tuple.type.e2f to %.loc5_13.5 = in_place_init %.loc5_13.6
// CHECK:STDOUT:   %.loc5_13.8: init %Slot to %return.param = class_init (%.loc5_13.3, %.loc5_13.7)
// CHECK:STDOUT:   return %.loc5_13.8 to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Read(%s.param: %Slot) -> out %return.param: bool {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %s.ref: %Slot = name_ref s, %s
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %p.patt: %pattern_type.ef8 = value_binding_pattern p [concrete = constants.%p.patt.201]
// CHECK:STDOUT:     %.loc12_17: %pattern_type.26e = tuple_pattern (%p.patt) [concrete = constants.%.f12]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc12_40.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc12_40.1: <bound method> = bound_method %int_0, %impl.elem0.loc12_40.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:   %specific_fn.loc12_40.1: <specific function> = specific_function %impl.elem0.loc12_40.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc12_40.2: <bound method> = bound_method %int_0, %specific_fn.loc12_40.1 [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc12: init %u1 = call %bound_method.loc12_40.2(%int_0) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc12_40.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc12 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc12_40.2: %u1 = converted %int_0, %.loc12_40.1 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc12_40.3: ref %u1 = class_element_access %s.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc12_40.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc12_40.3: <bound method> = bound_method %.loc12_40.2, %impl.elem0.loc12_40.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.f34]
// CHECK:STDOUT:   %specific_fn.loc12_40.2: <specific function> = specific_function %impl.elem0.loc12_40.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc12_40.4: <bound method> = bound_method %.loc12_40.2, %specific_fn.loc12_40.2 [concrete = constants.%bound_method.53a]
// CHECK:STDOUT:   %.loc12_40.4: %u1 = acquire_value %.loc12_40.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc12: init bool = call %bound_method.loc12_40.4(%.loc12_40.2, %.loc12_40.4)
// CHECK:STDOUT:   %.loc12_40.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc12
// CHECK:STDOUT:   %.loc12_40.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc12, %.loc12_40.5
// CHECK:STDOUT:   if %.loc12_40.6 br !match.case.then.loc12 else br !match.case.else.loc12
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc12:
// CHECK:STDOUT:   %.loc12_40.7: ref %.dcd = class_element_access %s.ref, element1
// CHECK:STDOUT:   %.loc12_40.8: ref %tuple.type.e2f = class_element_access %.loc12_40.7, element0
// CHECK:STDOUT:   %tuple.elem0: ref %Optional.5b3 = tuple_access %.loc12_40.8, element0
// CHECK:STDOUT:   %.loc12_40.9: %Optional.5b3 = acquire_value %tuple.elem0
// CHECK:STDOUT:   %.loc12_37.1: type = splice_block %Optional [concrete = constants.%Optional.5b3] {
// CHECK:STDOUT:     %Core.ref: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:     %Optional.ref: %Optional.type = name_ref Optional, imports.%Core.Optional [concrete = constants.%Optional.generic]
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %ptr: type = ptr_type %i32 [concrete = constants.%ptr.d08]
// CHECK:STDOUT:     %OptionalStorage.facet: %OptionalStorage.type = facet_value %ptr, (constants.%OptionalStorage.impl_witness.0ce) [concrete = constants.%OptionalStorage.facet]
// CHECK:STDOUT:     %.loc12_37.2: %OptionalStorage.type = converted %ptr, %OptionalStorage.facet [concrete = constants.%OptionalStorage.facet]
// CHECK:STDOUT:     %Optional: type = class_type @Optional, @Optional(constants.%OptionalStorage.facet) [concrete = constants.%Optional.5b3]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %p: %Optional.5b3 = wrapper_binding p, %.loc12_40.9
// CHECK:STDOUT:   %p.ref: %Optional.5b3 = name_ref p, %p
// CHECK:STDOUT:   %.loc13: %Optional.HasValue.type.c62 = specific_constant imports.%Core.import_ref.729, @Optional(constants.%OptionalStorage.facet) [concrete = constants.%Optional.HasValue.84d]
// CHECK:STDOUT:   %HasValue.ref: %Optional.HasValue.type.c62 = name_ref HasValue, %.loc13 [concrete = constants.%Optional.HasValue.84d]
// CHECK:STDOUT:   %Optional.HasValue.bound: <bound method> = bound_method %p.ref, %HasValue.ref
// CHECK:STDOUT:   %Optional.HasValue.specific_fn: <specific function> = specific_function %HasValue.ref, @Optional.HasValue(constants.%OptionalStorage.facet) [concrete = constants.%Optional.HasValue.specific_fn]
// CHECK:STDOUT:   %bound_method.loc13: <bound method> = bound_method %p.ref, %Optional.HasValue.specific_fn
// CHECK:STDOUT:   %Optional.HasValue.call: init bool = call %bound_method.loc13(%p.ref)
// CHECK:STDOUT:   return %Optional.HasValue.call
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc12:
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt: %pattern_type.c59 = expr_pattern %Empty.ref in [concrete] {
// CHECK:STDOUT:       %Empty.ref: %Slot = name_ref Empty, @Slot.%Empty
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Empty.ref: %Slot = name_ref Empty, @Slot.%Empty
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc15_17.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc15_17.1: <bound method> = bound_method %int_1, %impl.elem0.loc15_17.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc15_17.1: <specific function> = specific_function %impl.elem0.loc15_17.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc15_17.2: <bound method> = bound_method %int_1, %specific_fn.loc15_17.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc15: init %u1 = call %bound_method.loc15_17.2(%int_1) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc15_17.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc15 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc15_17.2: %u1 = converted %int_1, %.loc15_17.1 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc15_17.3: ref %u1 = class_element_access %s.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc15_17.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc15_17.3: <bound method> = bound_method %.loc15_17.2, %impl.elem0.loc15_17.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.22c]
// CHECK:STDOUT:   %specific_fn.loc15_17.2: <specific function> = specific_function %impl.elem0.loc15_17.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc15_17.4: <bound method> = bound_method %.loc15_17.2, %specific_fn.loc15_17.2 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc15_17.4: %u1 = acquire_value %.loc15_17.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc15: init bool = call %bound_method.loc15_17.4(%.loc15_17.2, %.loc15_17.4)
// CHECK:STDOUT:   %.loc15_17.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc15
// CHECK:STDOUT:   %.loc15_17.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc15, %.loc15_17.5
// CHECK:STDOUT:   if %.loc15_17.6 br !match.case.then.loc15 else br !match.case.else.loc15
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc15:
// CHECK:STDOUT:   %false.loc16: bool = bool_literal false [concrete = constants.%false]
// CHECK:STDOUT:   %impl.elem0.loc16: %.e28 = impl_witness_access constants.%Copy.impl_witness.5e1, element0 [concrete = constants.%bool.as.Copy.impl.Op]
// CHECK:STDOUT:   %bound_method.loc16: <bound method> = bound_method %false.loc16, %impl.elem0.loc16 [concrete = constants.%bool.as.Copy.impl.Op.bound]
// CHECK:STDOUT:   %bool.as.Copy.impl.Op.call.loc16: init bool = call %bound_method.loc16(%false.loc16) [concrete = constants.%false]
// CHECK:STDOUT:   return %bool.as.Copy.impl.Op.call.loc16
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc15:
// CHECK:STDOUT:   br !match.done
// CHECK:STDOUT:
// CHECK:STDOUT: !match.done:
// CHECK:STDOUT:   %false.loc19: bool = bool_literal false [concrete = constants.%false]
// CHECK:STDOUT:   %impl.elem0.loc19: %.e28 = impl_witness_access constants.%Copy.impl_witness.5e1, element0 [concrete = constants.%bool.as.Copy.impl.Op]
// CHECK:STDOUT:   %bound_method.loc19: <bound method> = bound_method %false.loc19, %impl.elem0.loc19 [concrete = constants.%bool.as.Copy.impl.Op.bound]
// CHECK:STDOUT:   %bool.as.Copy.impl.Op.call.loc19: init bool = call %bound_method.loc19(%false.loc19) [concrete = constants.%false]
// CHECK:STDOUT:   return %bool.as.Copy.impl.Op.call.loc19
// CHECK:STDOUT: }
// CHECK:STDOUT:
