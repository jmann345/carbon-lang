// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/optional/compare.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/optional/compare.carbon

// Fork (OP-1, fork/optional/plan.md §4): `Core.Optional(T)` implements
// `EqWith` and `OrderedWith` with itself when `T` is `Core.Eq` or
// `Core.Ordered` (D-OP-1..D-OP-3), the pointer niche included when the pointer
// type is `Core.Eq`.

// --- concrete.carbon

library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn IsEq(a: Core.Optional(i32), b: Core.Optional(i32)) -> bool { return a == b; }
fn IsNe(a: Core.Optional(i32), b: Core.Optional(i32)) -> bool { return a != b; }
fn IsLt(a: Core.Optional(i32), b: Core.Optional(i32)) -> bool { return a < b; }
fn IsLe(a: Core.Optional(i32), b: Core.Optional(i32)) -> bool { return a <= b; }
fn IsGt(a: Core.Optional(i32), b: Core.Optional(i32)) -> bool { return a > b; }
fn IsGe(a: Core.Optional(i32), b: Core.Optional(i32)) -> bool { return a >= b; }
//@dump-sem-ir-end

// --- generic.carbon

library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn Same[T: Core.Eq & Core.Copy & Core.Destroy](a: Core.Optional(T),
                                               b: Core.Optional(T)) -> bool {
  return a == b;
}

fn UseSame(a: Core.Optional(i64)) -> bool { return Same(a, a); }
//@dump-sem-ir-end

// --- ordered_only.carbon

library "[[@TEST_NAME]]";

class Rank {
  var v: i32;
  impl as Core.Copy {
    fn Op(self) -> Self { return {.v = self.v}; }
  }
}

impl Rank as Core.OrderedWith(Rank) {
  fn Less(self, other: Rank) -> bool { return self.v < other.v; }
  fn LessOrEquivalent(self, other: Rank) -> bool { return self.v <= other.v; }
  fn Greater(self, other: Rank) -> bool { return self.v > other.v; }
  fn GreaterOrEquivalent(self, other: Rank) -> bool {
    return self.v >= other.v;
  }
}

//@dump-sem-ir-begin
fn RankLess(a: Core.Optional(Rank), b: Core.Optional(Rank)) -> bool {
  return a < b;
}
//@dump-sem-ir-end

// --- user_pointer.carbon

library "[[@TEST_NAME]]";

class C {
  var v: i32;
}

// Allowed in this library because `C` is local; the prelude gives `C*` no
// `==`, so this impl is what makes `Core.Optional(C*)` comparable.
impl C* as Core.EqWith(C*) {
  fn Equal(self, other: C*) -> bool { return self->v == other->v; }
  fn NotEqual(self, other: C*) -> bool { return self->v != other->v; }
}

//@dump-sem-ir-begin
fn SameC(a: Core.Optional(C*), b: Core.Optional(C*)) -> bool {
  return a == b;
}
//@dump-sem-ir-end

// CHECK:STDOUT: --- concrete.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %Optional.type: type = generic_class_type @Optional [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %Optional.generic: %Optional.type = struct_value () [concrete]
// CHECK:STDOUT:   %OptionalStorage.type: type = facet_type <@OptionalStorage> [concrete]
// CHECK:STDOUT:   %Destroy.type: type = facet_type <@Destroy> [concrete]
// CHECK:STDOUT:   %pattern_type.831: type = pattern_type bool [concrete]
// CHECK:STDOUT:   %return.param_patt.5a1: %pattern_type.831 = out_param_pattern [concrete]
// CHECK:STDOUT:   %.f34: Core.Form = init_form bool [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %Int.type: type = generic_class_type @Int [concrete]
// CHECK:STDOUT:   %Int.generic: %Int.type = struct_value () [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %facet_type.f48: type = facet_type <@Destroy & @Copy> [concrete]
// CHECK:STDOUT:   %T.283: %facet_type.f48 = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %DefaultOptionalStorage.d50: type = class_type @DefaultOptionalStorage, @DefaultOptionalStorage(%T.283) [symbolic]
// CHECK:STDOUT:   %T.as_type.as.OptionalStorage.impl.Get.type.a12: type = fn_type @T.as_type.as.OptionalStorage.impl.Get, @T.as_type.as.OptionalStorage.impl(%T.283) [symbolic]
// CHECK:STDOUT:   %T.as_type.as.OptionalStorage.impl.Get.d32: %T.as_type.as.OptionalStorage.impl.Get.type.a12 = struct_value () [symbolic]
// CHECK:STDOUT:   %T.as_type.as.OptionalStorage.impl.Has.type.e5a: type = fn_type @T.as_type.as.OptionalStorage.impl.Has, @T.as_type.as.OptionalStorage.impl(%T.283) [symbolic]
// CHECK:STDOUT:   %T.as_type.as.OptionalStorage.impl.Has.4ee: %T.as_type.as.OptionalStorage.impl.Has.type.e5a = struct_value () [symbolic]
// CHECK:STDOUT:   %Destroy.lookup_impl_witness.7b3: <witness> = lookup_impl_witness %DefaultOptionalStorage.d50, @Destroy [symbolic]
// CHECK:STDOUT:   %Destroy.facet.e78: %Destroy.type = facet_value %DefaultOptionalStorage.d50, (%Destroy.lookup_impl_witness.7b3) [symbolic]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %self.param_patt.705: %pattern_type.6b6 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.70d: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt.705 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfc: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01: %Destroy.WithSelf.SubobjectDestroy.type.dfc = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef0: type = fn_type @Destroy.WithSelf.Op.loc5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403: %Destroy.WithSelf.Op.type.ef0 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbc: type = fn_type @Destroy.WithSelf.SelfDestruct.loc5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3: %Destroy.WithSelf.SelfDestruct.type.fbc = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.f8f: <witness> = custom_witness (%Destroy.WithSelf.Op.403, %Destroy.WithSelf.SubobjectDestroy.d01, %Destroy.WithSelf.SelfDestruct.db3), @Destroy [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %facet_value.178: %facet_type.f48 = facet_value %i32, (%custom_witness.f8f, %Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %OptionalStorage.impl_witness.3c7: <witness> = impl_witness imports.%OptionalStorage.impl_witness_table.460, @T.as_type.as.OptionalStorage.impl(%facet_value.178) [concrete]
// CHECK:STDOUT:   %OptionalStorage.facet.6c5: %OptionalStorage.type = facet_value %i32, (%OptionalStorage.impl_witness.3c7) [concrete]
// CHECK:STDOUT:   %Optional.0ac: type = class_type @Optional, @Optional(%OptionalStorage.facet.6c5) [concrete]
// CHECK:STDOUT:   %pattern_type.022: type = pattern_type %Optional.0ac [concrete]
// CHECK:STDOUT:   %a.param_patt: %pattern_type.022 = value_param_pattern [concrete]
// CHECK:STDOUT:   %a.patt: %pattern_type.022 = wrapper_binding_pattern a, %a.param_patt [concrete]
// CHECK:STDOUT:   %b.param_patt: %pattern_type.022 = value_param_pattern [concrete]
// CHECK:STDOUT:   %b.patt: %pattern_type.022 = wrapper_binding_pattern b, %b.param_patt [concrete]
// CHECK:STDOUT:   %return.patt.c0c: %pattern_type.831 = return_slot_pattern %return.param_patt.5a1, bool [concrete]
// CHECK:STDOUT:   %IsEq.type: type = fn_type @IsEq [concrete]
// CHECK:STDOUT:   %IsEq: %IsEq.type = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.type.f77: type = generic_interface_type @EqWith [concrete]
// CHECK:STDOUT:   %EqWith.generic: %EqWith.type.f77 = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.type.fd7: type = facet_type <@EqWith, @EqWith(%Optional.0ac)> [concrete]
// CHECK:STDOUT:   %M: Core.IntLiteral = symbolic_binding M, 1 [symbolic]
// CHECK:STDOUT:   %Int.as.EqWith.impl.NotEqual.type.df2: type = fn_type @Int.as.EqWith.impl.NotEqual.1, @Int.as.EqWith.impl.e9c(%N, %M) [symbolic]
// CHECK:STDOUT:   %Int.as.EqWith.impl.NotEqual.539: %Int.as.EqWith.impl.NotEqual.type.df2 = struct_value () [symbolic]
// CHECK:STDOUT:   %Int.as.EqWith.impl.Equal.type.9a2: type = fn_type @Int.as.EqWith.impl.Equal.1, @Int.as.EqWith.impl.e9c(%N, %M) [symbolic]
// CHECK:STDOUT:   %Int.as.EqWith.impl.Equal.792: %Int.as.EqWith.impl.Equal.type.9a2 = struct_value () [symbolic]
// CHECK:STDOUT:   %facet_type.a0bbe6.1: type = facet_type <@OptionalStorage & @Destroy & @Eq> [concrete]
// CHECK:STDOUT:   %T.2038aa.1: %facet_type.a0bbe6.1 = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %Optional.as.EqWith.impl.NotEqual.type.a57: type = fn_type @Optional.as.EqWith.impl.NotEqual, @Optional.as.EqWith.impl(%T.2038aa.1) [symbolic]
// CHECK:STDOUT:   %Optional.as.EqWith.impl.NotEqual.085: %Optional.as.EqWith.impl.NotEqual.type.a57 = struct_value () [symbolic]
// CHECK:STDOUT:   %Optional.as.EqWith.impl.Equal.type.ab4: type = fn_type @Optional.as.EqWith.impl.Equal, @Optional.as.EqWith.impl(%T.2038aa.1) [symbolic]
// CHECK:STDOUT:   %Optional.as.EqWith.impl.Equal.455: %Optional.as.EqWith.impl.Equal.type.ab4 = struct_value () [symbolic]
// CHECK:STDOUT:   %EqWith.impl_witness.34c: <witness> = impl_witness imports.%EqWith.impl_witness_table.09e, @Int.as.EqWith.impl.e9c(%int_32, %int_32) [concrete]
// CHECK:STDOUT:   %facet_value.395: %facet_type.a0bbe6.1 = facet_value %i32, (%OptionalStorage.impl_witness.3c7, %custom_witness.f8f, %EqWith.impl_witness.34c) [concrete]
// CHECK:STDOUT:   %EqWith.impl_witness.ce3: <witness> = impl_witness imports.%EqWith.impl_witness_table.3e4, @Optional.as.EqWith.impl(%facet_value.395) [concrete]
// CHECK:STDOUT:   %Optional.as.EqWith.impl.Equal.type.3eb: type = fn_type @Optional.as.EqWith.impl.Equal, @Optional.as.EqWith.impl(%facet_value.395) [concrete]
// CHECK:STDOUT:   %Optional.as.EqWith.impl.Equal.5ca: %Optional.as.EqWith.impl.Equal.type.3eb = struct_value () [concrete]
// CHECK:STDOUT:   %Optional.as.EqWith.impl.NotEqual.type.298: type = fn_type @Optional.as.EqWith.impl.NotEqual, @Optional.as.EqWith.impl(%facet_value.395) [concrete]
// CHECK:STDOUT:   %Optional.as.EqWith.impl.NotEqual.e06: %Optional.as.EqWith.impl.NotEqual.type.298 = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.f88: %EqWith.type.fd7 = facet_value %Optional.0ac, (%EqWith.impl_witness.ce3) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.1b0: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%Optional.0ac, %EqWith.facet.f88) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.NotEqual.type.079: type = fn_type @EqWith.WithSelf.NotEqual, @EqWith.WithSelf(%Optional.0ac, %EqWith.facet.f88) [concrete]
// CHECK:STDOUT:   %.7b3: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.1b0, %EqWith.facet.f88 [concrete]
// CHECK:STDOUT:   %Optional.as.EqWith.impl.Equal.specific_fn: <specific function> = specific_function %Optional.as.EqWith.impl.Equal.5ca, @Optional.as.EqWith.impl.Equal(%facet_value.395) [concrete]
// CHECK:STDOUT:   %IsNe.type: type = fn_type @IsNe [concrete]
// CHECK:STDOUT:   %IsNe: %IsNe.type = struct_value () [concrete]
// CHECK:STDOUT:   %.5dd: type = fn_type_with_self_type %EqWith.WithSelf.NotEqual.type.079, %EqWith.facet.f88 [concrete]
// CHECK:STDOUT:   %Optional.as.EqWith.impl.NotEqual.specific_fn: <specific function> = specific_function %Optional.as.EqWith.impl.NotEqual.e06, @Optional.as.EqWith.impl.NotEqual(%facet_value.395) [concrete]
// CHECK:STDOUT:   %IsLt.type: type = fn_type @IsLt [concrete]
// CHECK:STDOUT:   %IsLt: %IsLt.type = struct_value () [concrete]
// CHECK:STDOUT:   %OrderedWith.type.ad8: type = generic_interface_type @OrderedWith [concrete]
// CHECK:STDOUT:   %OrderedWith.generic: %OrderedWith.type.ad8 = struct_value () [concrete]
// CHECK:STDOUT:   %OrderedWith.type.eec: type = facet_type <@OrderedWith, @OrderedWith(%Optional.0ac)> [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.GreaterOrEquivalent.type.b34: type = fn_type @Int.as.OrderedWith.impl.GreaterOrEquivalent.1, @Int.as.OrderedWith.impl.ab3(%N, %M) [symbolic]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.GreaterOrEquivalent.9d9: %Int.as.OrderedWith.impl.GreaterOrEquivalent.type.b34 = struct_value () [symbolic]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.type.944: type = fn_type @Int.as.OrderedWith.impl.Greater.1, @Int.as.OrderedWith.impl.ab3(%N, %M) [symbolic]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.8d1: %Int.as.OrderedWith.impl.Greater.type.944 = struct_value () [symbolic]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.LessOrEquivalent.type.b23: type = fn_type @Int.as.OrderedWith.impl.LessOrEquivalent.1, @Int.as.OrderedWith.impl.ab3(%N, %M) [symbolic]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.LessOrEquivalent.c49: %Int.as.OrderedWith.impl.LessOrEquivalent.type.b23 = struct_value () [symbolic]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Less.type.89b: type = fn_type @Int.as.OrderedWith.impl.Less.1, @Int.as.OrderedWith.impl.ab3(%N, %M) [symbolic]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Less.050: %Int.as.OrderedWith.impl.Less.type.89b = struct_value () [symbolic]
// CHECK:STDOUT:   %facet_type.a0bbe6.2: type = facet_type <@OptionalStorage & @Destroy & @Ordered> [concrete]
// CHECK:STDOUT:   %T.2038aa.2: %facet_type.a0bbe6.2 = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %Optional.as.OrderedWith.impl.GreaterOrEquivalent.type.cb7: type = fn_type @Optional.as.OrderedWith.impl.GreaterOrEquivalent, @Optional.as.OrderedWith.impl(%T.2038aa.2) [symbolic]
// CHECK:STDOUT:   %Optional.as.OrderedWith.impl.GreaterOrEquivalent.e05: %Optional.as.OrderedWith.impl.GreaterOrEquivalent.type.cb7 = struct_value () [symbolic]
// CHECK:STDOUT:   %Optional.as.OrderedWith.impl.Greater.type.f3d: type = fn_type @Optional.as.OrderedWith.impl.Greater, @Optional.as.OrderedWith.impl(%T.2038aa.2) [symbolic]
// CHECK:STDOUT:   %Optional.as.OrderedWith.impl.Greater.2fe: %Optional.as.OrderedWith.impl.Greater.type.f3d = struct_value () [symbolic]
// CHECK:STDOUT:   %Optional.as.OrderedWith.impl.LessOrEquivalent.type.638: type = fn_type @Optional.as.OrderedWith.impl.LessOrEquivalent, @Optional.as.OrderedWith.impl(%T.2038aa.2) [symbolic]
// CHECK:STDOUT:   %Optional.as.OrderedWith.impl.LessOrEquivalent.27f: %Optional.as.OrderedWith.impl.LessOrEquivalent.type.638 = struct_value () [symbolic]
// CHECK:STDOUT:   %Optional.as.OrderedWith.impl.Less.type.5d9: type = fn_type @Optional.as.OrderedWith.impl.Less, @Optional.as.OrderedWith.impl(%T.2038aa.2) [symbolic]
// CHECK:STDOUT:   %Optional.as.OrderedWith.impl.Less.036: %Optional.as.OrderedWith.impl.Less.type.5d9 = struct_value () [symbolic]
// CHECK:STDOUT:   %OrderedWith.impl_witness.dcd: <witness> = impl_witness imports.%OrderedWith.impl_witness_table.087, @Int.as.OrderedWith.impl.ab3(%int_32, %int_32) [concrete]
// CHECK:STDOUT:   %facet_value.6b2: %facet_type.a0bbe6.2 = facet_value %i32, (%OptionalStorage.impl_witness.3c7, %custom_witness.f8f, %OrderedWith.impl_witness.dcd) [concrete]
// CHECK:STDOUT:   %OrderedWith.impl_witness.064: <witness> = impl_witness imports.%OrderedWith.impl_witness_table.98f, @Optional.as.OrderedWith.impl(%facet_value.6b2) [concrete]
// CHECK:STDOUT:   %Optional.as.OrderedWith.impl.Less.type.419: type = fn_type @Optional.as.OrderedWith.impl.Less, @Optional.as.OrderedWith.impl(%facet_value.6b2) [concrete]
// CHECK:STDOUT:   %Optional.as.OrderedWith.impl.Less.3f4: %Optional.as.OrderedWith.impl.Less.type.419 = struct_value () [concrete]
// CHECK:STDOUT:   %Optional.as.OrderedWith.impl.LessOrEquivalent.type.c4b: type = fn_type @Optional.as.OrderedWith.impl.LessOrEquivalent, @Optional.as.OrderedWith.impl(%facet_value.6b2) [concrete]
// CHECK:STDOUT:   %Optional.as.OrderedWith.impl.LessOrEquivalent.1c1: %Optional.as.OrderedWith.impl.LessOrEquivalent.type.c4b = struct_value () [concrete]
// CHECK:STDOUT:   %Optional.as.OrderedWith.impl.Greater.type.367: type = fn_type @Optional.as.OrderedWith.impl.Greater, @Optional.as.OrderedWith.impl(%facet_value.6b2) [concrete]
// CHECK:STDOUT:   %Optional.as.OrderedWith.impl.Greater.229: %Optional.as.OrderedWith.impl.Greater.type.367 = struct_value () [concrete]
// CHECK:STDOUT:   %Optional.as.OrderedWith.impl.GreaterOrEquivalent.type.601: type = fn_type @Optional.as.OrderedWith.impl.GreaterOrEquivalent, @Optional.as.OrderedWith.impl(%facet_value.6b2) [concrete]
// CHECK:STDOUT:   %Optional.as.OrderedWith.impl.GreaterOrEquivalent.5c3: %Optional.as.OrderedWith.impl.GreaterOrEquivalent.type.601 = struct_value () [concrete]
// CHECK:STDOUT:   %OrderedWith.facet.eca: %OrderedWith.type.eec = facet_value %Optional.0ac, (%OrderedWith.impl_witness.064) [concrete]
// CHECK:STDOUT:   %OrderedWith.WithSelf.Less.type.20b: type = fn_type @OrderedWith.WithSelf.Less, @OrderedWith.WithSelf(%Optional.0ac, %OrderedWith.facet.eca) [concrete]
// CHECK:STDOUT:   %OrderedWith.WithSelf.LessOrEquivalent.type.b28: type = fn_type @OrderedWith.WithSelf.LessOrEquivalent, @OrderedWith.WithSelf(%Optional.0ac, %OrderedWith.facet.eca) [concrete]
// CHECK:STDOUT:   %OrderedWith.WithSelf.Greater.type.bc2: type = fn_type @OrderedWith.WithSelf.Greater, @OrderedWith.WithSelf(%Optional.0ac, %OrderedWith.facet.eca) [concrete]
// CHECK:STDOUT:   %OrderedWith.WithSelf.GreaterOrEquivalent.type.907: type = fn_type @OrderedWith.WithSelf.GreaterOrEquivalent, @OrderedWith.WithSelf(%Optional.0ac, %OrderedWith.facet.eca) [concrete]
// CHECK:STDOUT:   %.9b7: type = fn_type_with_self_type %OrderedWith.WithSelf.Less.type.20b, %OrderedWith.facet.eca [concrete]
// CHECK:STDOUT:   %Optional.as.OrderedWith.impl.Less.specific_fn: <specific function> = specific_function %Optional.as.OrderedWith.impl.Less.3f4, @Optional.as.OrderedWith.impl.Less(%facet_value.6b2) [concrete]
// CHECK:STDOUT:   %IsLe.type: type = fn_type @IsLe [concrete]
// CHECK:STDOUT:   %IsLe: %IsLe.type = struct_value () [concrete]
// CHECK:STDOUT:   %.206: type = fn_type_with_self_type %OrderedWith.WithSelf.LessOrEquivalent.type.b28, %OrderedWith.facet.eca [concrete]
// CHECK:STDOUT:   %Optional.as.OrderedWith.impl.LessOrEquivalent.specific_fn: <specific function> = specific_function %Optional.as.OrderedWith.impl.LessOrEquivalent.1c1, @Optional.as.OrderedWith.impl.LessOrEquivalent(%facet_value.6b2) [concrete]
// CHECK:STDOUT:   %IsGt.type: type = fn_type @IsGt [concrete]
// CHECK:STDOUT:   %IsGt: %IsGt.type = struct_value () [concrete]
// CHECK:STDOUT:   %.f2d: type = fn_type_with_self_type %OrderedWith.WithSelf.Greater.type.bc2, %OrderedWith.facet.eca [concrete]
// CHECK:STDOUT:   %Optional.as.OrderedWith.impl.Greater.specific_fn: <specific function> = specific_function %Optional.as.OrderedWith.impl.Greater.229, @Optional.as.OrderedWith.impl.Greater(%facet_value.6b2) [concrete]
// CHECK:STDOUT:   %IsGe.type: type = fn_type @IsGe [concrete]
// CHECK:STDOUT:   %IsGe: %IsGe.type = struct_value () [concrete]
// CHECK:STDOUT:   %.223: type = fn_type_with_self_type %OrderedWith.WithSelf.GreaterOrEquivalent.type.907, %OrderedWith.facet.eca [concrete]
// CHECK:STDOUT:   %Optional.as.OrderedWith.impl.GreaterOrEquivalent.specific_fn: <specific function> = specific_function %Optional.as.OrderedWith.impl.GreaterOrEquivalent.5c3, @Optional.as.OrderedWith.impl.GreaterOrEquivalent(%facet_value.6b2) [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .Optional = %Core.Optional
// CHECK:STDOUT:     .Int = %Core.Int
// CHECK:STDOUT:     .Bool = %Core.Bool
// CHECK:STDOUT:     .EqWith = %Core.EqWith
// CHECK:STDOUT:     .OrderedWith = %Core.OrderedWith
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Optional: %Optional.type = import_ref Core//prelude/types/optional, Optional, loaded [concrete = constants.%Optional.generic]
// CHECK:STDOUT:   %Core.Int: %Int.type = import_ref Core//prelude/types/int, Int, loaded [concrete = constants.%Int.generic]
// CHECK:STDOUT:   %Core.import_ref.f38: %Destroy.type = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @T.as_type.as.OptionalStorage.impl.%Destroy.facet (constants.%Destroy.facet.e78)]
// CHECK:STDOUT:   %Core.import_ref.f71 = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.f5a = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.eb2: @T.as_type.as.OptionalStorage.impl.%T.as_type.as.OptionalStorage.impl.Has.type (%T.as_type.as.OptionalStorage.impl.Has.type.e5a) = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @T.as_type.as.OptionalStorage.impl.%T.as_type.as.OptionalStorage.impl.Has (constants.%T.as_type.as.OptionalStorage.impl.Has.4ee)]
// CHECK:STDOUT:   %Core.import_ref.5ec: @T.as_type.as.OptionalStorage.impl.%T.as_type.as.OptionalStorage.impl.Get.type (%T.as_type.as.OptionalStorage.impl.Get.type.a12) = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @T.as_type.as.OptionalStorage.impl.%T.as_type.as.OptionalStorage.impl.Get (constants.%T.as_type.as.OptionalStorage.impl.Get.d32)]
// CHECK:STDOUT:   %Core.import_ref.007 = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %OptionalStorage.impl_witness_table.460 = impl_witness_table (%Core.import_ref.f38, %Core.import_ref.f71, %Core.import_ref.f5a, %Core.import_ref.eb2, %Core.import_ref.5ec, %Core.import_ref.007), @T.as_type.as.OptionalStorage.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.Bool: type = import_ref Core//prelude/types/bool, Bool, loaded [concrete = bool]
// CHECK:STDOUT:   %Core.EqWith: %EqWith.type.f77 = import_ref Core//prelude/operators/comparison, EqWith, loaded [concrete = constants.%EqWith.generic]
// CHECK:STDOUT:   %Core.import_ref.074: @Int.as.EqWith.impl.e9c.%Int.as.EqWith.impl.Equal.type (%Int.as.EqWith.impl.Equal.type.9a2) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.EqWith.impl.e9c.%Int.as.EqWith.impl.Equal (constants.%Int.as.EqWith.impl.Equal.792)]
// CHECK:STDOUT:   %Core.import_ref.30d: @Int.as.EqWith.impl.e9c.%Int.as.EqWith.impl.NotEqual.type (%Int.as.EqWith.impl.NotEqual.type.df2) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.EqWith.impl.e9c.%Int.as.EqWith.impl.NotEqual (constants.%Int.as.EqWith.impl.NotEqual.539)]
// CHECK:STDOUT:   %EqWith.impl_witness_table.09e = impl_witness_table (%Core.import_ref.074, %Core.import_ref.30d), @Int.as.EqWith.impl.e9c [concrete]
// CHECK:STDOUT:   %Core.import_ref.c4b: @Optional.as.EqWith.impl.%Optional.as.EqWith.impl.Equal.type (%Optional.as.EqWith.impl.Equal.type.ab4) = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @Optional.as.EqWith.impl.%Optional.as.EqWith.impl.Equal (constants.%Optional.as.EqWith.impl.Equal.455)]
// CHECK:STDOUT:   %Core.import_ref.ffc: @Optional.as.EqWith.impl.%Optional.as.EqWith.impl.NotEqual.type (%Optional.as.EqWith.impl.NotEqual.type.a57) = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @Optional.as.EqWith.impl.%Optional.as.EqWith.impl.NotEqual (constants.%Optional.as.EqWith.impl.NotEqual.085)]
// CHECK:STDOUT:   %EqWith.impl_witness_table.3e4 = impl_witness_table (%Core.import_ref.c4b, %Core.import_ref.ffc), @Optional.as.EqWith.impl [concrete]
// CHECK:STDOUT:   %Core.OrderedWith: %OrderedWith.type.ad8 = import_ref Core//prelude/operators/comparison, OrderedWith, loaded [concrete = constants.%OrderedWith.generic]
// CHECK:STDOUT:   %Core.import_ref.c1c8: @Int.as.OrderedWith.impl.ab3.%Int.as.OrderedWith.impl.Less.type (%Int.as.OrderedWith.impl.Less.type.89b) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.OrderedWith.impl.ab3.%Int.as.OrderedWith.impl.Less (constants.%Int.as.OrderedWith.impl.Less.050)]
// CHECK:STDOUT:   %Core.import_ref.6e8: @Int.as.OrderedWith.impl.ab3.%Int.as.OrderedWith.impl.LessOrEquivalent.type (%Int.as.OrderedWith.impl.LessOrEquivalent.type.b23) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.OrderedWith.impl.ab3.%Int.as.OrderedWith.impl.LessOrEquivalent (constants.%Int.as.OrderedWith.impl.LessOrEquivalent.c49)]
// CHECK:STDOUT:   %Core.import_ref.f15: @Int.as.OrderedWith.impl.ab3.%Int.as.OrderedWith.impl.Greater.type (%Int.as.OrderedWith.impl.Greater.type.944) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.OrderedWith.impl.ab3.%Int.as.OrderedWith.impl.Greater (constants.%Int.as.OrderedWith.impl.Greater.8d1)]
// CHECK:STDOUT:   %Core.import_ref.1c5: @Int.as.OrderedWith.impl.ab3.%Int.as.OrderedWith.impl.GreaterOrEquivalent.type (%Int.as.OrderedWith.impl.GreaterOrEquivalent.type.b34) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.OrderedWith.impl.ab3.%Int.as.OrderedWith.impl.GreaterOrEquivalent (constants.%Int.as.OrderedWith.impl.GreaterOrEquivalent.9d9)]
// CHECK:STDOUT:   %OrderedWith.impl_witness_table.087 = impl_witness_table (%Core.import_ref.c1c8, %Core.import_ref.6e8, %Core.import_ref.f15, %Core.import_ref.1c5), @Int.as.OrderedWith.impl.ab3 [concrete]
// CHECK:STDOUT:   %Core.import_ref.174: @Optional.as.OrderedWith.impl.%Optional.as.OrderedWith.impl.Less.type (%Optional.as.OrderedWith.impl.Less.type.5d9) = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @Optional.as.OrderedWith.impl.%Optional.as.OrderedWith.impl.Less (constants.%Optional.as.OrderedWith.impl.Less.036)]
// CHECK:STDOUT:   %Core.import_ref.66e: @Optional.as.OrderedWith.impl.%Optional.as.OrderedWith.impl.LessOrEquivalent.type (%Optional.as.OrderedWith.impl.LessOrEquivalent.type.638) = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @Optional.as.OrderedWith.impl.%Optional.as.OrderedWith.impl.LessOrEquivalent (constants.%Optional.as.OrderedWith.impl.LessOrEquivalent.27f)]
// CHECK:STDOUT:   %Core.import_ref.68b: @Optional.as.OrderedWith.impl.%Optional.as.OrderedWith.impl.Greater.type (%Optional.as.OrderedWith.impl.Greater.type.f3d) = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @Optional.as.OrderedWith.impl.%Optional.as.OrderedWith.impl.Greater (constants.%Optional.as.OrderedWith.impl.Greater.2fe)]
// CHECK:STDOUT:   %Core.import_ref.6d76: @Optional.as.OrderedWith.impl.%Optional.as.OrderedWith.impl.GreaterOrEquivalent.type (%Optional.as.OrderedWith.impl.GreaterOrEquivalent.type.cb7) = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @Optional.as.OrderedWith.impl.%Optional.as.OrderedWith.impl.GreaterOrEquivalent (constants.%Optional.as.OrderedWith.impl.GreaterOrEquivalent.e05)]
// CHECK:STDOUT:   %OrderedWith.impl_witness_table.98f = impl_witness_table (%Core.import_ref.174, %Core.import_ref.66e, %Core.import_ref.68b, %Core.import_ref.6d76), @Optional.as.OrderedWith.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl: %Destroy.WithSelf.SubobjectDestroy.type.dfc = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc5 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6b6 = ref_param_pattern [concrete = constants.%self.param_patt.705]
// CHECK:STDOUT:     %self.patt: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.70d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i32 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i32 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl: %Destroy.WithSelf.Op.type.ef0 = fn_decl @Destroy.WithSelf.Op.loc5 [concrete = constants.%Destroy.WithSelf.Op.403] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6b6 = ref_param_pattern [concrete = constants.%self.param_patt.705]
// CHECK:STDOUT:     %self.patt: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.70d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i32 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i32 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %IsEq.decl: %IsEq.type = fn_decl @IsEq [concrete = constants.%IsEq] {
// CHECK:STDOUT:     %a.param_patt: %pattern_type.022 = value_param_pattern [concrete = constants.%a.param_patt]
// CHECK:STDOUT:     %a.patt: %pattern_type.022 = wrapper_binding_pattern a, %a.param_patt [concrete = constants.%a.patt]
// CHECK:STDOUT:     %b.param_patt: %pattern_type.022 = value_param_pattern [concrete = constants.%b.param_patt]
// CHECK:STDOUT:     %b.patt: %pattern_type.022 = wrapper_binding_pattern b, %b.param_patt [concrete = constants.%b.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.831 = out_param_pattern [concrete = constants.%return.param_patt.5a1]
// CHECK:STDOUT:     %return.patt: %pattern_type.831 = return_slot_pattern %return.param_patt, %.loc5_58.1 [concrete = constants.%return.patt.c0c]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc5_58.1: type = type_literal bool [concrete = bool]
// CHECK:STDOUT:     %.loc5_58.2: Core.Form = init_form %.loc5_58.1 [concrete = constants.%.f34]
// CHECK:STDOUT:     %a.param: %Optional.0ac = value_param call_param0
// CHECK:STDOUT:     %.loc5_29.1: type = splice_block %Optional.loc5_29 [concrete = constants.%Optional.0ac] {
// CHECK:STDOUT:       %Core.ref.loc5_12: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %Optional.ref.loc5_16: %Optional.type = name_ref Optional, imports.%Core.Optional [concrete = constants.%Optional.generic]
// CHECK:STDOUT:       %i32.loc5_26: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %OptionalStorage.facet.loc5_29: %OptionalStorage.type = facet_value %i32.loc5_26, (constants.%OptionalStorage.impl_witness.3c7) [concrete = constants.%OptionalStorage.facet.6c5]
// CHECK:STDOUT:       %.loc5_29.2: %OptionalStorage.type = converted %i32.loc5_26, %OptionalStorage.facet.loc5_29 [concrete = constants.%OptionalStorage.facet.6c5]
// CHECK:STDOUT:       %Optional.loc5_29: type = class_type @Optional, @Optional(constants.%OptionalStorage.facet.6c5) [concrete = constants.%Optional.0ac]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %a: %Optional.0ac = wrapper_binding a, %a.param
// CHECK:STDOUT:     %b.param: %Optional.0ac = value_param call_param1
// CHECK:STDOUT:     %.loc5_52.1: type = splice_block %Optional.loc5_52 [concrete = constants.%Optional.0ac] {
// CHECK:STDOUT:       %Core.ref.loc5_35: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %Optional.ref.loc5_39: %Optional.type = name_ref Optional, imports.%Core.Optional [concrete = constants.%Optional.generic]
// CHECK:STDOUT:       %i32.loc5_49: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %OptionalStorage.facet.loc5_52: %OptionalStorage.type = facet_value %i32.loc5_49, (constants.%OptionalStorage.impl_witness.3c7) [concrete = constants.%OptionalStorage.facet.6c5]
// CHECK:STDOUT:       %.loc5_52.2: %OptionalStorage.type = converted %i32.loc5_49, %OptionalStorage.facet.loc5_52 [concrete = constants.%OptionalStorage.facet.6c5]
// CHECK:STDOUT:       %Optional.loc5_52: type = class_type @Optional, @Optional(constants.%OptionalStorage.facet.6c5) [concrete = constants.%Optional.0ac]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %b: %Optional.0ac = wrapper_binding b, %b.param
// CHECK:STDOUT:     %return.param: ref bool = out_param call_param2
// CHECK:STDOUT:     %return: ref bool = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %IsNe.decl: %IsNe.type = fn_decl @IsNe [concrete = constants.%IsNe] {
// CHECK:STDOUT:     %a.param_patt: %pattern_type.022 = value_param_pattern [concrete = constants.%a.param_patt]
// CHECK:STDOUT:     %a.patt: %pattern_type.022 = wrapper_binding_pattern a, %a.param_patt [concrete = constants.%a.patt]
// CHECK:STDOUT:     %b.param_patt: %pattern_type.022 = value_param_pattern [concrete = constants.%b.param_patt]
// CHECK:STDOUT:     %b.patt: %pattern_type.022 = wrapper_binding_pattern b, %b.param_patt [concrete = constants.%b.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.831 = out_param_pattern [concrete = constants.%return.param_patt.5a1]
// CHECK:STDOUT:     %return.patt: %pattern_type.831 = return_slot_pattern %return.param_patt, %.loc6_58.1 [concrete = constants.%return.patt.c0c]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc6_58.1: type = type_literal bool [concrete = bool]
// CHECK:STDOUT:     %.loc6_58.2: Core.Form = init_form %.loc6_58.1 [concrete = constants.%.f34]
// CHECK:STDOUT:     %a.param: %Optional.0ac = value_param call_param0
// CHECK:STDOUT:     %.loc6_29.1: type = splice_block %Optional.loc6_29 [concrete = constants.%Optional.0ac] {
// CHECK:STDOUT:       %Core.ref.loc6_12: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %Optional.ref.loc6_16: %Optional.type = name_ref Optional, imports.%Core.Optional [concrete = constants.%Optional.generic]
// CHECK:STDOUT:       %i32.loc6_26: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %OptionalStorage.facet.loc6_29: %OptionalStorage.type = facet_value %i32.loc6_26, (constants.%OptionalStorage.impl_witness.3c7) [concrete = constants.%OptionalStorage.facet.6c5]
// CHECK:STDOUT:       %.loc6_29.2: %OptionalStorage.type = converted %i32.loc6_26, %OptionalStorage.facet.loc6_29 [concrete = constants.%OptionalStorage.facet.6c5]
// CHECK:STDOUT:       %Optional.loc6_29: type = class_type @Optional, @Optional(constants.%OptionalStorage.facet.6c5) [concrete = constants.%Optional.0ac]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %a: %Optional.0ac = wrapper_binding a, %a.param
// CHECK:STDOUT:     %b.param: %Optional.0ac = value_param call_param1
// CHECK:STDOUT:     %.loc6_52.1: type = splice_block %Optional.loc6_52 [concrete = constants.%Optional.0ac] {
// CHECK:STDOUT:       %Core.ref.loc6_35: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %Optional.ref.loc6_39: %Optional.type = name_ref Optional, imports.%Core.Optional [concrete = constants.%Optional.generic]
// CHECK:STDOUT:       %i32.loc6_49: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %OptionalStorage.facet.loc6_52: %OptionalStorage.type = facet_value %i32.loc6_49, (constants.%OptionalStorage.impl_witness.3c7) [concrete = constants.%OptionalStorage.facet.6c5]
// CHECK:STDOUT:       %.loc6_52.2: %OptionalStorage.type = converted %i32.loc6_49, %OptionalStorage.facet.loc6_52 [concrete = constants.%OptionalStorage.facet.6c5]
// CHECK:STDOUT:       %Optional.loc6_52: type = class_type @Optional, @Optional(constants.%OptionalStorage.facet.6c5) [concrete = constants.%Optional.0ac]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %b: %Optional.0ac = wrapper_binding b, %b.param
// CHECK:STDOUT:     %return.param: ref bool = out_param call_param2
// CHECK:STDOUT:     %return: ref bool = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %IsLt.decl: %IsLt.type = fn_decl @IsLt [concrete = constants.%IsLt] {
// CHECK:STDOUT:     %a.param_patt: %pattern_type.022 = value_param_pattern [concrete = constants.%a.param_patt]
// CHECK:STDOUT:     %a.patt: %pattern_type.022 = wrapper_binding_pattern a, %a.param_patt [concrete = constants.%a.patt]
// CHECK:STDOUT:     %b.param_patt: %pattern_type.022 = value_param_pattern [concrete = constants.%b.param_patt]
// CHECK:STDOUT:     %b.patt: %pattern_type.022 = wrapper_binding_pattern b, %b.param_patt [concrete = constants.%b.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.831 = out_param_pattern [concrete = constants.%return.param_patt.5a1]
// CHECK:STDOUT:     %return.patt: %pattern_type.831 = return_slot_pattern %return.param_patt, %.loc7_58.1 [concrete = constants.%return.patt.c0c]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc7_58.1: type = type_literal bool [concrete = bool]
// CHECK:STDOUT:     %.loc7_58.2: Core.Form = init_form %.loc7_58.1 [concrete = constants.%.f34]
// CHECK:STDOUT:     %a.param: %Optional.0ac = value_param call_param0
// CHECK:STDOUT:     %.loc7_29.1: type = splice_block %Optional.loc7_29 [concrete = constants.%Optional.0ac] {
// CHECK:STDOUT:       %Core.ref.loc7_12: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %Optional.ref.loc7_16: %Optional.type = name_ref Optional, imports.%Core.Optional [concrete = constants.%Optional.generic]
// CHECK:STDOUT:       %i32.loc7_26: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %OptionalStorage.facet.loc7_29: %OptionalStorage.type = facet_value %i32.loc7_26, (constants.%OptionalStorage.impl_witness.3c7) [concrete = constants.%OptionalStorage.facet.6c5]
// CHECK:STDOUT:       %.loc7_29.2: %OptionalStorage.type = converted %i32.loc7_26, %OptionalStorage.facet.loc7_29 [concrete = constants.%OptionalStorage.facet.6c5]
// CHECK:STDOUT:       %Optional.loc7_29: type = class_type @Optional, @Optional(constants.%OptionalStorage.facet.6c5) [concrete = constants.%Optional.0ac]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %a: %Optional.0ac = wrapper_binding a, %a.param
// CHECK:STDOUT:     %b.param: %Optional.0ac = value_param call_param1
// CHECK:STDOUT:     %.loc7_52.1: type = splice_block %Optional.loc7_52 [concrete = constants.%Optional.0ac] {
// CHECK:STDOUT:       %Core.ref.loc7_35: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %Optional.ref.loc7_39: %Optional.type = name_ref Optional, imports.%Core.Optional [concrete = constants.%Optional.generic]
// CHECK:STDOUT:       %i32.loc7_49: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %OptionalStorage.facet.loc7_52: %OptionalStorage.type = facet_value %i32.loc7_49, (constants.%OptionalStorage.impl_witness.3c7) [concrete = constants.%OptionalStorage.facet.6c5]
// CHECK:STDOUT:       %.loc7_52.2: %OptionalStorage.type = converted %i32.loc7_49, %OptionalStorage.facet.loc7_52 [concrete = constants.%OptionalStorage.facet.6c5]
// CHECK:STDOUT:       %Optional.loc7_52: type = class_type @Optional, @Optional(constants.%OptionalStorage.facet.6c5) [concrete = constants.%Optional.0ac]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %b: %Optional.0ac = wrapper_binding b, %b.param
// CHECK:STDOUT:     %return.param: ref bool = out_param call_param2
// CHECK:STDOUT:     %return: ref bool = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %IsLe.decl: %IsLe.type = fn_decl @IsLe [concrete = constants.%IsLe] {
// CHECK:STDOUT:     %a.param_patt: %pattern_type.022 = value_param_pattern [concrete = constants.%a.param_patt]
// CHECK:STDOUT:     %a.patt: %pattern_type.022 = wrapper_binding_pattern a, %a.param_patt [concrete = constants.%a.patt]
// CHECK:STDOUT:     %b.param_patt: %pattern_type.022 = value_param_pattern [concrete = constants.%b.param_patt]
// CHECK:STDOUT:     %b.patt: %pattern_type.022 = wrapper_binding_pattern b, %b.param_patt [concrete = constants.%b.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.831 = out_param_pattern [concrete = constants.%return.param_patt.5a1]
// CHECK:STDOUT:     %return.patt: %pattern_type.831 = return_slot_pattern %return.param_patt, %.loc8_58.1 [concrete = constants.%return.patt.c0c]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc8_58.1: type = type_literal bool [concrete = bool]
// CHECK:STDOUT:     %.loc8_58.2: Core.Form = init_form %.loc8_58.1 [concrete = constants.%.f34]
// CHECK:STDOUT:     %a.param: %Optional.0ac = value_param call_param0
// CHECK:STDOUT:     %.loc8_29.1: type = splice_block %Optional.loc8_29 [concrete = constants.%Optional.0ac] {
// CHECK:STDOUT:       %Core.ref.loc8_12: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %Optional.ref.loc8_16: %Optional.type = name_ref Optional, imports.%Core.Optional [concrete = constants.%Optional.generic]
// CHECK:STDOUT:       %i32.loc8_26: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %OptionalStorage.facet.loc8_29: %OptionalStorage.type = facet_value %i32.loc8_26, (constants.%OptionalStorage.impl_witness.3c7) [concrete = constants.%OptionalStorage.facet.6c5]
// CHECK:STDOUT:       %.loc8_29.2: %OptionalStorage.type = converted %i32.loc8_26, %OptionalStorage.facet.loc8_29 [concrete = constants.%OptionalStorage.facet.6c5]
// CHECK:STDOUT:       %Optional.loc8_29: type = class_type @Optional, @Optional(constants.%OptionalStorage.facet.6c5) [concrete = constants.%Optional.0ac]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %a: %Optional.0ac = wrapper_binding a, %a.param
// CHECK:STDOUT:     %b.param: %Optional.0ac = value_param call_param1
// CHECK:STDOUT:     %.loc8_52.1: type = splice_block %Optional.loc8_52 [concrete = constants.%Optional.0ac] {
// CHECK:STDOUT:       %Core.ref.loc8_35: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %Optional.ref.loc8_39: %Optional.type = name_ref Optional, imports.%Core.Optional [concrete = constants.%Optional.generic]
// CHECK:STDOUT:       %i32.loc8_49: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %OptionalStorage.facet.loc8_52: %OptionalStorage.type = facet_value %i32.loc8_49, (constants.%OptionalStorage.impl_witness.3c7) [concrete = constants.%OptionalStorage.facet.6c5]
// CHECK:STDOUT:       %.loc8_52.2: %OptionalStorage.type = converted %i32.loc8_49, %OptionalStorage.facet.loc8_52 [concrete = constants.%OptionalStorage.facet.6c5]
// CHECK:STDOUT:       %Optional.loc8_52: type = class_type @Optional, @Optional(constants.%OptionalStorage.facet.6c5) [concrete = constants.%Optional.0ac]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %b: %Optional.0ac = wrapper_binding b, %b.param
// CHECK:STDOUT:     %return.param: ref bool = out_param call_param2
// CHECK:STDOUT:     %return: ref bool = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %IsGt.decl: %IsGt.type = fn_decl @IsGt [concrete = constants.%IsGt] {
// CHECK:STDOUT:     %a.param_patt: %pattern_type.022 = value_param_pattern [concrete = constants.%a.param_patt]
// CHECK:STDOUT:     %a.patt: %pattern_type.022 = wrapper_binding_pattern a, %a.param_patt [concrete = constants.%a.patt]
// CHECK:STDOUT:     %b.param_patt: %pattern_type.022 = value_param_pattern [concrete = constants.%b.param_patt]
// CHECK:STDOUT:     %b.patt: %pattern_type.022 = wrapper_binding_pattern b, %b.param_patt [concrete = constants.%b.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.831 = out_param_pattern [concrete = constants.%return.param_patt.5a1]
// CHECK:STDOUT:     %return.patt: %pattern_type.831 = return_slot_pattern %return.param_patt, %.loc9_58.1 [concrete = constants.%return.patt.c0c]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc9_58.1: type = type_literal bool [concrete = bool]
// CHECK:STDOUT:     %.loc9_58.2: Core.Form = init_form %.loc9_58.1 [concrete = constants.%.f34]
// CHECK:STDOUT:     %a.param: %Optional.0ac = value_param call_param0
// CHECK:STDOUT:     %.loc9_29.1: type = splice_block %Optional.loc9_29 [concrete = constants.%Optional.0ac] {
// CHECK:STDOUT:       %Core.ref.loc9_12: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %Optional.ref.loc9_16: %Optional.type = name_ref Optional, imports.%Core.Optional [concrete = constants.%Optional.generic]
// CHECK:STDOUT:       %i32.loc9_26: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %OptionalStorage.facet.loc9_29: %OptionalStorage.type = facet_value %i32.loc9_26, (constants.%OptionalStorage.impl_witness.3c7) [concrete = constants.%OptionalStorage.facet.6c5]
// CHECK:STDOUT:       %.loc9_29.2: %OptionalStorage.type = converted %i32.loc9_26, %OptionalStorage.facet.loc9_29 [concrete = constants.%OptionalStorage.facet.6c5]
// CHECK:STDOUT:       %Optional.loc9_29: type = class_type @Optional, @Optional(constants.%OptionalStorage.facet.6c5) [concrete = constants.%Optional.0ac]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %a: %Optional.0ac = wrapper_binding a, %a.param
// CHECK:STDOUT:     %b.param: %Optional.0ac = value_param call_param1
// CHECK:STDOUT:     %.loc9_52.1: type = splice_block %Optional.loc9_52 [concrete = constants.%Optional.0ac] {
// CHECK:STDOUT:       %Core.ref.loc9_35: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %Optional.ref.loc9_39: %Optional.type = name_ref Optional, imports.%Core.Optional [concrete = constants.%Optional.generic]
// CHECK:STDOUT:       %i32.loc9_49: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %OptionalStorage.facet.loc9_52: %OptionalStorage.type = facet_value %i32.loc9_49, (constants.%OptionalStorage.impl_witness.3c7) [concrete = constants.%OptionalStorage.facet.6c5]
// CHECK:STDOUT:       %.loc9_52.2: %OptionalStorage.type = converted %i32.loc9_49, %OptionalStorage.facet.loc9_52 [concrete = constants.%OptionalStorage.facet.6c5]
// CHECK:STDOUT:       %Optional.loc9_52: type = class_type @Optional, @Optional(constants.%OptionalStorage.facet.6c5) [concrete = constants.%Optional.0ac]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %b: %Optional.0ac = wrapper_binding b, %b.param
// CHECK:STDOUT:     %return.param: ref bool = out_param call_param2
// CHECK:STDOUT:     %return: ref bool = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %IsGe.decl: %IsGe.type = fn_decl @IsGe [concrete = constants.%IsGe] {
// CHECK:STDOUT:     %a.param_patt: %pattern_type.022 = value_param_pattern [concrete = constants.%a.param_patt]
// CHECK:STDOUT:     %a.patt: %pattern_type.022 = wrapper_binding_pattern a, %a.param_patt [concrete = constants.%a.patt]
// CHECK:STDOUT:     %b.param_patt: %pattern_type.022 = value_param_pattern [concrete = constants.%b.param_patt]
// CHECK:STDOUT:     %b.patt: %pattern_type.022 = wrapper_binding_pattern b, %b.param_patt [concrete = constants.%b.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.831 = out_param_pattern [concrete = constants.%return.param_patt.5a1]
// CHECK:STDOUT:     %return.patt: %pattern_type.831 = return_slot_pattern %return.param_patt, %.loc10_58.1 [concrete = constants.%return.patt.c0c]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc10_58.1: type = type_literal bool [concrete = bool]
// CHECK:STDOUT:     %.loc10_58.2: Core.Form = init_form %.loc10_58.1 [concrete = constants.%.f34]
// CHECK:STDOUT:     %a.param: %Optional.0ac = value_param call_param0
// CHECK:STDOUT:     %.loc10_29.1: type = splice_block %Optional.loc10_29 [concrete = constants.%Optional.0ac] {
// CHECK:STDOUT:       %Core.ref.loc10_12: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %Optional.ref.loc10_16: %Optional.type = name_ref Optional, imports.%Core.Optional [concrete = constants.%Optional.generic]
// CHECK:STDOUT:       %i32.loc10_26: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %OptionalStorage.facet.loc10_29: %OptionalStorage.type = facet_value %i32.loc10_26, (constants.%OptionalStorage.impl_witness.3c7) [concrete = constants.%OptionalStorage.facet.6c5]
// CHECK:STDOUT:       %.loc10_29.2: %OptionalStorage.type = converted %i32.loc10_26, %OptionalStorage.facet.loc10_29 [concrete = constants.%OptionalStorage.facet.6c5]
// CHECK:STDOUT:       %Optional.loc10_29: type = class_type @Optional, @Optional(constants.%OptionalStorage.facet.6c5) [concrete = constants.%Optional.0ac]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %a: %Optional.0ac = wrapper_binding a, %a.param
// CHECK:STDOUT:     %b.param: %Optional.0ac = value_param call_param1
// CHECK:STDOUT:     %.loc10_52.1: type = splice_block %Optional.loc10_52 [concrete = constants.%Optional.0ac] {
// CHECK:STDOUT:       %Core.ref.loc10_35: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %Optional.ref.loc10_39: %Optional.type = name_ref Optional, imports.%Core.Optional [concrete = constants.%Optional.generic]
// CHECK:STDOUT:       %i32.loc10_49: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %OptionalStorage.facet.loc10_52: %OptionalStorage.type = facet_value %i32.loc10_49, (constants.%OptionalStorage.impl_witness.3c7) [concrete = constants.%OptionalStorage.facet.6c5]
// CHECK:STDOUT:       %.loc10_52.2: %OptionalStorage.type = converted %i32.loc10_49, %OptionalStorage.facet.loc10_52 [concrete = constants.%OptionalStorage.facet.6c5]
// CHECK:STDOUT:       %Optional.loc10_52: type = class_type @Optional, @Optional(constants.%OptionalStorage.facet.6c5) [concrete = constants.%Optional.0ac]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %b: %Optional.0ac = wrapper_binding b, %b.param
// CHECK:STDOUT:     %return.param: ref bool = out_param call_param2
// CHECK:STDOUT:     %return: ref bool = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc5(%self.param: ref %i32) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc5(%self.param: ref %i32) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc5(%self.param: ref %i32) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @IsEq(%a.param: %Optional.0ac, %b.param: %Optional.0ac) -> out %return.param: bool {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %a.ref: %Optional.0ac = name_ref a, %a
// CHECK:STDOUT:   %b.ref: %Optional.0ac = name_ref b, %b
// CHECK:STDOUT:   %impl.elem0: %.7b3 = impl_witness_access constants.%EqWith.impl_witness.ce3, element0 [concrete = constants.%Optional.as.EqWith.impl.Equal.5ca]
// CHECK:STDOUT:   %bound_method.loc5_74.1: <bound method> = bound_method %a.ref, %impl.elem0
// CHECK:STDOUT:   %facet_value.loc5_74.1: %facet_type.a0bbe6.1 = facet_value constants.%i32, (constants.%OptionalStorage.impl_witness.3c7, constants.%custom_witness.f8f, constants.%EqWith.impl_witness.34c) [concrete = constants.%facet_value.395]
// CHECK:STDOUT:   %.loc5_74.1: %facet_type.a0bbe6.1 = converted constants.%i32, %facet_value.loc5_74.1 [concrete = constants.%facet_value.395]
// CHECK:STDOUT:   %facet_value.loc5_74.2: %facet_type.a0bbe6.1 = facet_value constants.%i32, (constants.%OptionalStorage.impl_witness.3c7, constants.%custom_witness.f8f, constants.%EqWith.impl_witness.34c) [concrete = constants.%facet_value.395]
// CHECK:STDOUT:   %.loc5_74.2: %facet_type.a0bbe6.1 = converted constants.%i32, %facet_value.loc5_74.2 [concrete = constants.%facet_value.395]
// CHECK:STDOUT:   %facet_value.loc5_74.3: %facet_type.a0bbe6.1 = facet_value constants.%i32, (constants.%OptionalStorage.impl_witness.3c7, constants.%custom_witness.f8f, constants.%EqWith.impl_witness.34c) [concrete = constants.%facet_value.395]
// CHECK:STDOUT:   %.loc5_74.3: %facet_type.a0bbe6.1 = converted constants.%i32, %facet_value.loc5_74.3 [concrete = constants.%facet_value.395]
// CHECK:STDOUT:   %facet_value.loc5_74.4: %facet_type.a0bbe6.1 = facet_value constants.%i32, (constants.%OptionalStorage.impl_witness.3c7, constants.%custom_witness.f8f, constants.%EqWith.impl_witness.34c) [concrete = constants.%facet_value.395]
// CHECK:STDOUT:   %.loc5_74.4: %facet_type.a0bbe6.1 = converted constants.%i32, %facet_value.loc5_74.4 [concrete = constants.%facet_value.395]
// CHECK:STDOUT:   %specific_fn: <specific function> = specific_function %impl.elem0, @Optional.as.EqWith.impl.Equal(constants.%facet_value.395) [concrete = constants.%Optional.as.EqWith.impl.Equal.specific_fn]
// CHECK:STDOUT:   %bound_method.loc5_74.2: <bound method> = bound_method %a.ref, %specific_fn
// CHECK:STDOUT:   %Optional.as.EqWith.impl.Equal.call: init bool = call %bound_method.loc5_74.2(%a.ref, %b.ref)
// CHECK:STDOUT:   return %Optional.as.EqWith.impl.Equal.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @IsNe(%a.param: %Optional.0ac, %b.param: %Optional.0ac) -> out %return.param: bool {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %a.ref: %Optional.0ac = name_ref a, %a
// CHECK:STDOUT:   %b.ref: %Optional.0ac = name_ref b, %b
// CHECK:STDOUT:   %impl.elem1: %.5dd = impl_witness_access constants.%EqWith.impl_witness.ce3, element1 [concrete = constants.%Optional.as.EqWith.impl.NotEqual.e06]
// CHECK:STDOUT:   %bound_method.loc6_74.1: <bound method> = bound_method %a.ref, %impl.elem1
// CHECK:STDOUT:   %facet_value.loc6_74.1: %facet_type.a0bbe6.1 = facet_value constants.%i32, (constants.%OptionalStorage.impl_witness.3c7, constants.%custom_witness.f8f, constants.%EqWith.impl_witness.34c) [concrete = constants.%facet_value.395]
// CHECK:STDOUT:   %.loc6_74.1: %facet_type.a0bbe6.1 = converted constants.%i32, %facet_value.loc6_74.1 [concrete = constants.%facet_value.395]
// CHECK:STDOUT:   %facet_value.loc6_74.2: %facet_type.a0bbe6.1 = facet_value constants.%i32, (constants.%OptionalStorage.impl_witness.3c7, constants.%custom_witness.f8f, constants.%EqWith.impl_witness.34c) [concrete = constants.%facet_value.395]
// CHECK:STDOUT:   %.loc6_74.2: %facet_type.a0bbe6.1 = converted constants.%i32, %facet_value.loc6_74.2 [concrete = constants.%facet_value.395]
// CHECK:STDOUT:   %facet_value.loc6_74.3: %facet_type.a0bbe6.1 = facet_value constants.%i32, (constants.%OptionalStorage.impl_witness.3c7, constants.%custom_witness.f8f, constants.%EqWith.impl_witness.34c) [concrete = constants.%facet_value.395]
// CHECK:STDOUT:   %.loc6_74.3: %facet_type.a0bbe6.1 = converted constants.%i32, %facet_value.loc6_74.3 [concrete = constants.%facet_value.395]
// CHECK:STDOUT:   %facet_value.loc6_74.4: %facet_type.a0bbe6.1 = facet_value constants.%i32, (constants.%OptionalStorage.impl_witness.3c7, constants.%custom_witness.f8f, constants.%EqWith.impl_witness.34c) [concrete = constants.%facet_value.395]
// CHECK:STDOUT:   %.loc6_74.4: %facet_type.a0bbe6.1 = converted constants.%i32, %facet_value.loc6_74.4 [concrete = constants.%facet_value.395]
// CHECK:STDOUT:   %specific_fn: <specific function> = specific_function %impl.elem1, @Optional.as.EqWith.impl.NotEqual(constants.%facet_value.395) [concrete = constants.%Optional.as.EqWith.impl.NotEqual.specific_fn]
// CHECK:STDOUT:   %bound_method.loc6_74.2: <bound method> = bound_method %a.ref, %specific_fn
// CHECK:STDOUT:   %Optional.as.EqWith.impl.NotEqual.call: init bool = call %bound_method.loc6_74.2(%a.ref, %b.ref)
// CHECK:STDOUT:   return %Optional.as.EqWith.impl.NotEqual.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @IsLt(%a.param: %Optional.0ac, %b.param: %Optional.0ac) -> out %return.param: bool {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %a.ref: %Optional.0ac = name_ref a, %a
// CHECK:STDOUT:   %b.ref: %Optional.0ac = name_ref b, %b
// CHECK:STDOUT:   %impl.elem0: %.9b7 = impl_witness_access constants.%OrderedWith.impl_witness.064, element0 [concrete = constants.%Optional.as.OrderedWith.impl.Less.3f4]
// CHECK:STDOUT:   %bound_method.loc7_74.1: <bound method> = bound_method %a.ref, %impl.elem0
// CHECK:STDOUT:   %facet_value.loc7_74.1: %facet_type.a0bbe6.2 = facet_value constants.%i32, (constants.%OptionalStorage.impl_witness.3c7, constants.%custom_witness.f8f, constants.%OrderedWith.impl_witness.dcd) [concrete = constants.%facet_value.6b2]
// CHECK:STDOUT:   %.loc7_74.1: %facet_type.a0bbe6.2 = converted constants.%i32, %facet_value.loc7_74.1 [concrete = constants.%facet_value.6b2]
// CHECK:STDOUT:   %facet_value.loc7_74.2: %facet_type.a0bbe6.2 = facet_value constants.%i32, (constants.%OptionalStorage.impl_witness.3c7, constants.%custom_witness.f8f, constants.%OrderedWith.impl_witness.dcd) [concrete = constants.%facet_value.6b2]
// CHECK:STDOUT:   %.loc7_74.2: %facet_type.a0bbe6.2 = converted constants.%i32, %facet_value.loc7_74.2 [concrete = constants.%facet_value.6b2]
// CHECK:STDOUT:   %facet_value.loc7_74.3: %facet_type.a0bbe6.2 = facet_value constants.%i32, (constants.%OptionalStorage.impl_witness.3c7, constants.%custom_witness.f8f, constants.%OrderedWith.impl_witness.dcd) [concrete = constants.%facet_value.6b2]
// CHECK:STDOUT:   %.loc7_74.3: %facet_type.a0bbe6.2 = converted constants.%i32, %facet_value.loc7_74.3 [concrete = constants.%facet_value.6b2]
// CHECK:STDOUT:   %facet_value.loc7_74.4: %facet_type.a0bbe6.2 = facet_value constants.%i32, (constants.%OptionalStorage.impl_witness.3c7, constants.%custom_witness.f8f, constants.%OrderedWith.impl_witness.dcd) [concrete = constants.%facet_value.6b2]
// CHECK:STDOUT:   %.loc7_74.4: %facet_type.a0bbe6.2 = converted constants.%i32, %facet_value.loc7_74.4 [concrete = constants.%facet_value.6b2]
// CHECK:STDOUT:   %specific_fn: <specific function> = specific_function %impl.elem0, @Optional.as.OrderedWith.impl.Less(constants.%facet_value.6b2) [concrete = constants.%Optional.as.OrderedWith.impl.Less.specific_fn]
// CHECK:STDOUT:   %bound_method.loc7_74.2: <bound method> = bound_method %a.ref, %specific_fn
// CHECK:STDOUT:   %Optional.as.OrderedWith.impl.Less.call: init bool = call %bound_method.loc7_74.2(%a.ref, %b.ref)
// CHECK:STDOUT:   return %Optional.as.OrderedWith.impl.Less.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @IsLe(%a.param: %Optional.0ac, %b.param: %Optional.0ac) -> out %return.param: bool {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %a.ref: %Optional.0ac = name_ref a, %a
// CHECK:STDOUT:   %b.ref: %Optional.0ac = name_ref b, %b
// CHECK:STDOUT:   %impl.elem1: %.206 = impl_witness_access constants.%OrderedWith.impl_witness.064, element1 [concrete = constants.%Optional.as.OrderedWith.impl.LessOrEquivalent.1c1]
// CHECK:STDOUT:   %bound_method.loc8_74.1: <bound method> = bound_method %a.ref, %impl.elem1
// CHECK:STDOUT:   %facet_value.loc8_74.1: %facet_type.a0bbe6.2 = facet_value constants.%i32, (constants.%OptionalStorage.impl_witness.3c7, constants.%custom_witness.f8f, constants.%OrderedWith.impl_witness.dcd) [concrete = constants.%facet_value.6b2]
// CHECK:STDOUT:   %.loc8_74.1: %facet_type.a0bbe6.2 = converted constants.%i32, %facet_value.loc8_74.1 [concrete = constants.%facet_value.6b2]
// CHECK:STDOUT:   %facet_value.loc8_74.2: %facet_type.a0bbe6.2 = facet_value constants.%i32, (constants.%OptionalStorage.impl_witness.3c7, constants.%custom_witness.f8f, constants.%OrderedWith.impl_witness.dcd) [concrete = constants.%facet_value.6b2]
// CHECK:STDOUT:   %.loc8_74.2: %facet_type.a0bbe6.2 = converted constants.%i32, %facet_value.loc8_74.2 [concrete = constants.%facet_value.6b2]
// CHECK:STDOUT:   %facet_value.loc8_74.3: %facet_type.a0bbe6.2 = facet_value constants.%i32, (constants.%OptionalStorage.impl_witness.3c7, constants.%custom_witness.f8f, constants.%OrderedWith.impl_witness.dcd) [concrete = constants.%facet_value.6b2]
// CHECK:STDOUT:   %.loc8_74.3: %facet_type.a0bbe6.2 = converted constants.%i32, %facet_value.loc8_74.3 [concrete = constants.%facet_value.6b2]
// CHECK:STDOUT:   %facet_value.loc8_74.4: %facet_type.a0bbe6.2 = facet_value constants.%i32, (constants.%OptionalStorage.impl_witness.3c7, constants.%custom_witness.f8f, constants.%OrderedWith.impl_witness.dcd) [concrete = constants.%facet_value.6b2]
// CHECK:STDOUT:   %.loc8_74.4: %facet_type.a0bbe6.2 = converted constants.%i32, %facet_value.loc8_74.4 [concrete = constants.%facet_value.6b2]
// CHECK:STDOUT:   %specific_fn: <specific function> = specific_function %impl.elem1, @Optional.as.OrderedWith.impl.LessOrEquivalent(constants.%facet_value.6b2) [concrete = constants.%Optional.as.OrderedWith.impl.LessOrEquivalent.specific_fn]
// CHECK:STDOUT:   %bound_method.loc8_74.2: <bound method> = bound_method %a.ref, %specific_fn
// CHECK:STDOUT:   %Optional.as.OrderedWith.impl.LessOrEquivalent.call: init bool = call %bound_method.loc8_74.2(%a.ref, %b.ref)
// CHECK:STDOUT:   return %Optional.as.OrderedWith.impl.LessOrEquivalent.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @IsGt(%a.param: %Optional.0ac, %b.param: %Optional.0ac) -> out %return.param: bool {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %a.ref: %Optional.0ac = name_ref a, %a
// CHECK:STDOUT:   %b.ref: %Optional.0ac = name_ref b, %b
// CHECK:STDOUT:   %impl.elem2: %.f2d = impl_witness_access constants.%OrderedWith.impl_witness.064, element2 [concrete = constants.%Optional.as.OrderedWith.impl.Greater.229]
// CHECK:STDOUT:   %bound_method.loc9_74.1: <bound method> = bound_method %a.ref, %impl.elem2
// CHECK:STDOUT:   %facet_value.loc9_74.1: %facet_type.a0bbe6.2 = facet_value constants.%i32, (constants.%OptionalStorage.impl_witness.3c7, constants.%custom_witness.f8f, constants.%OrderedWith.impl_witness.dcd) [concrete = constants.%facet_value.6b2]
// CHECK:STDOUT:   %.loc9_74.1: %facet_type.a0bbe6.2 = converted constants.%i32, %facet_value.loc9_74.1 [concrete = constants.%facet_value.6b2]
// CHECK:STDOUT:   %facet_value.loc9_74.2: %facet_type.a0bbe6.2 = facet_value constants.%i32, (constants.%OptionalStorage.impl_witness.3c7, constants.%custom_witness.f8f, constants.%OrderedWith.impl_witness.dcd) [concrete = constants.%facet_value.6b2]
// CHECK:STDOUT:   %.loc9_74.2: %facet_type.a0bbe6.2 = converted constants.%i32, %facet_value.loc9_74.2 [concrete = constants.%facet_value.6b2]
// CHECK:STDOUT:   %facet_value.loc9_74.3: %facet_type.a0bbe6.2 = facet_value constants.%i32, (constants.%OptionalStorage.impl_witness.3c7, constants.%custom_witness.f8f, constants.%OrderedWith.impl_witness.dcd) [concrete = constants.%facet_value.6b2]
// CHECK:STDOUT:   %.loc9_74.3: %facet_type.a0bbe6.2 = converted constants.%i32, %facet_value.loc9_74.3 [concrete = constants.%facet_value.6b2]
// CHECK:STDOUT:   %facet_value.loc9_74.4: %facet_type.a0bbe6.2 = facet_value constants.%i32, (constants.%OptionalStorage.impl_witness.3c7, constants.%custom_witness.f8f, constants.%OrderedWith.impl_witness.dcd) [concrete = constants.%facet_value.6b2]
// CHECK:STDOUT:   %.loc9_74.4: %facet_type.a0bbe6.2 = converted constants.%i32, %facet_value.loc9_74.4 [concrete = constants.%facet_value.6b2]
// CHECK:STDOUT:   %specific_fn: <specific function> = specific_function %impl.elem2, @Optional.as.OrderedWith.impl.Greater(constants.%facet_value.6b2) [concrete = constants.%Optional.as.OrderedWith.impl.Greater.specific_fn]
// CHECK:STDOUT:   %bound_method.loc9_74.2: <bound method> = bound_method %a.ref, %specific_fn
// CHECK:STDOUT:   %Optional.as.OrderedWith.impl.Greater.call: init bool = call %bound_method.loc9_74.2(%a.ref, %b.ref)
// CHECK:STDOUT:   return %Optional.as.OrderedWith.impl.Greater.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @IsGe(%a.param: %Optional.0ac, %b.param: %Optional.0ac) -> out %return.param: bool {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %a.ref: %Optional.0ac = name_ref a, %a
// CHECK:STDOUT:   %b.ref: %Optional.0ac = name_ref b, %b
// CHECK:STDOUT:   %impl.elem3: %.223 = impl_witness_access constants.%OrderedWith.impl_witness.064, element3 [concrete = constants.%Optional.as.OrderedWith.impl.GreaterOrEquivalent.5c3]
// CHECK:STDOUT:   %bound_method.loc10_74.1: <bound method> = bound_method %a.ref, %impl.elem3
// CHECK:STDOUT:   %facet_value.loc10_74.1: %facet_type.a0bbe6.2 = facet_value constants.%i32, (constants.%OptionalStorage.impl_witness.3c7, constants.%custom_witness.f8f, constants.%OrderedWith.impl_witness.dcd) [concrete = constants.%facet_value.6b2]
// CHECK:STDOUT:   %.loc10_74.1: %facet_type.a0bbe6.2 = converted constants.%i32, %facet_value.loc10_74.1 [concrete = constants.%facet_value.6b2]
// CHECK:STDOUT:   %facet_value.loc10_74.2: %facet_type.a0bbe6.2 = facet_value constants.%i32, (constants.%OptionalStorage.impl_witness.3c7, constants.%custom_witness.f8f, constants.%OrderedWith.impl_witness.dcd) [concrete = constants.%facet_value.6b2]
// CHECK:STDOUT:   %.loc10_74.2: %facet_type.a0bbe6.2 = converted constants.%i32, %facet_value.loc10_74.2 [concrete = constants.%facet_value.6b2]
// CHECK:STDOUT:   %facet_value.loc10_74.3: %facet_type.a0bbe6.2 = facet_value constants.%i32, (constants.%OptionalStorage.impl_witness.3c7, constants.%custom_witness.f8f, constants.%OrderedWith.impl_witness.dcd) [concrete = constants.%facet_value.6b2]
// CHECK:STDOUT:   %.loc10_74.3: %facet_type.a0bbe6.2 = converted constants.%i32, %facet_value.loc10_74.3 [concrete = constants.%facet_value.6b2]
// CHECK:STDOUT:   %facet_value.loc10_74.4: %facet_type.a0bbe6.2 = facet_value constants.%i32, (constants.%OptionalStorage.impl_witness.3c7, constants.%custom_witness.f8f, constants.%OrderedWith.impl_witness.dcd) [concrete = constants.%facet_value.6b2]
// CHECK:STDOUT:   %.loc10_74.4: %facet_type.a0bbe6.2 = converted constants.%i32, %facet_value.loc10_74.4 [concrete = constants.%facet_value.6b2]
// CHECK:STDOUT:   %specific_fn: <specific function> = specific_function %impl.elem3, @Optional.as.OrderedWith.impl.GreaterOrEquivalent(constants.%facet_value.6b2) [concrete = constants.%Optional.as.OrderedWith.impl.GreaterOrEquivalent.specific_fn]
// CHECK:STDOUT:   %bound_method.loc10_74.2: <bound method> = bound_method %a.ref, %specific_fn
// CHECK:STDOUT:   %Optional.as.OrderedWith.impl.GreaterOrEquivalent.call: init bool = call %bound_method.loc10_74.2(%a.ref, %b.ref)
// CHECK:STDOUT:   return %Optional.as.OrderedWith.impl.GreaterOrEquivalent.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- generic.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %.Self.frozen: type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %Eq.type: type = facet_type <@Eq> [concrete]
// CHECK:STDOUT:   %EqWith.type.f77: type = generic_interface_type @EqWith [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %EqWith.generic: %EqWith.type.f77 = struct_value () [concrete]
// CHECK:STDOUT:   %Other: type = symbolic_binding Other, 0 [symbolic]
// CHECK:STDOUT:   %EqWith.type.98e: type = facet_type <@EqWith, @EqWith(%Other)> [symbolic]
// CHECK:STDOUT:   %Self.d94: %EqWith.type.98e = symbolic_binding Self, 1 [symbolic]
// CHECK:STDOUT:   %EqWith.assoc_type.85b: type = assoc_entity_type @EqWith, @EqWith(%Other) [symbolic]
// CHECK:STDOUT:   %pattern_type.831: type = pattern_type bool [concrete]
// CHECK:STDOUT:   %return.param_patt.5a1: %pattern_type.831 = out_param_pattern [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.b82: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%Other, %Self.d94) [symbolic]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.ae3: %EqWith.WithSelf.Equal.type.b82 = struct_value () [symbolic]
// CHECK:STDOUT:   %.f34: Core.Form = init_form bool [concrete]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %BitAndWith.type.a06: type = generic_interface_type @BitAndWith [concrete]
// CHECK:STDOUT:   %BitAndWith.generic: %BitAndWith.type.a06 = struct_value () [concrete]
// CHECK:STDOUT:   %BitAndWith.type.411: type = facet_type <@BitAndWith, @BitAndWith(type)> [concrete]
// CHECK:STDOUT:   %BitAndWith.impl_witness: <witness> = impl_witness imports.%BitAndWith.impl_witness_table [concrete]
// CHECK:STDOUT:   %BitAndWith.facet: %BitAndWith.type.411 = facet_value type, (%BitAndWith.impl_witness) [concrete]
// CHECK:STDOUT:   %BitAndWith.WithSelf.Op.type.0cf: type = fn_type @BitAndWith.WithSelf.Op, @BitAndWith.WithSelf(type, %BitAndWith.facet) [concrete]
// CHECK:STDOUT:   %.85c: type = fn_type_with_self_type %BitAndWith.WithSelf.Op.type.0cf, %BitAndWith.facet [concrete]
// CHECK:STDOUT:   %type.as.BitAndWith.impl.Op.type: type = fn_type @type.as.BitAndWith.impl.Op [concrete]
// CHECK:STDOUT:   %type.as.BitAndWith.impl.Op: %type.as.BitAndWith.impl.Op.type = struct_value () [concrete]
// CHECK:STDOUT:   %type.as.BitAndWith.impl.Op.bound.7a5: <bound method> = bound_method %Eq.type, %type.as.BitAndWith.impl.Op [concrete]
// CHECK:STDOUT:   %facet_type.bd0: type = facet_type <@Copy & @Eq> [concrete]
// CHECK:STDOUT:   %Destroy.type: type = facet_type <@Destroy> [concrete]
// CHECK:STDOUT:   %type.as.BitAndWith.impl.Op.bound.e6a: <bound method> = bound_method %facet_type.bd0, %type.as.BitAndWith.impl.Op [concrete]
// CHECK:STDOUT:   %facet_type.a1aaf9.1: type = facet_type <@Copy & @Destroy & @Eq> [concrete]
// CHECK:STDOUT:   %pattern_type.143af7.1: type = pattern_type %facet_type.a1aaf9.1 [concrete]
// CHECK:STDOUT:   %T.patt.256c82.1: %pattern_type.143af7.1 = symbolic_binding_pattern T, 0 [symbolic]
// CHECK:STDOUT:   %T.dc4a5c.1: %facet_type.a1aaf9.1 = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %Optional.type: type = generic_class_type @Optional [concrete]
// CHECK:STDOUT:   %Optional.generic: %Optional.type = struct_value () [concrete]
// CHECK:STDOUT:   %OptionalStorage.type: type = facet_type <@OptionalStorage> [concrete]
// CHECK:STDOUT:   %T.as_type.5d6f3f.1: type = facet_access_type %T.dc4a5c.1 [symbolic]
// CHECK:STDOUT:   %facet_type.a1aaf9.2: type = facet_type <@Copy & @Destroy> [concrete]
// CHECK:STDOUT:   %T.dc4a5c.2: %facet_type.a1aaf9.2 = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %DefaultOptionalStorage.5e0: type = class_type @DefaultOptionalStorage, @DefaultOptionalStorage(%T.dc4a5c.2) [symbolic]
// CHECK:STDOUT:   %T.as_type.as.OptionalStorage.impl.Get.type.7fb: type = fn_type @T.as_type.as.OptionalStorage.impl.Get, @T.as_type.as.OptionalStorage.impl(%T.dc4a5c.2) [symbolic]
// CHECK:STDOUT:   %T.as_type.as.OptionalStorage.impl.Get.a96: %T.as_type.as.OptionalStorage.impl.Get.type.7fb = struct_value () [symbolic]
// CHECK:STDOUT:   %T.as_type.as.OptionalStorage.impl.Has.type.62c: type = fn_type @T.as_type.as.OptionalStorage.impl.Has, @T.as_type.as.OptionalStorage.impl(%T.dc4a5c.2) [symbolic]
// CHECK:STDOUT:   %T.as_type.as.OptionalStorage.impl.Has.7e4: %T.as_type.as.OptionalStorage.impl.Has.type.62c = struct_value () [symbolic]
// CHECK:STDOUT:   %Destroy.lookup_impl_witness.597: <witness> = lookup_impl_witness %DefaultOptionalStorage.5e0, @Destroy [symbolic]
// CHECK:STDOUT:   %Destroy.facet.0de: %Destroy.type = facet_value %DefaultOptionalStorage.5e0, (%Destroy.lookup_impl_witness.597) [symbolic]
// CHECK:STDOUT:   %OptionalStorage.lookup_impl_witness.a98: <witness> = lookup_impl_witness %T.dc4a5c.1, @OptionalStorage [symbolic]
// CHECK:STDOUT:   %Copy.lookup_impl_witness.fd8341.2: <witness> = lookup_impl_witness %T.dc4a5c.1, @Copy [symbolic]
// CHECK:STDOUT:   %Destroy.lookup_impl_witness.49108c.2: <witness> = lookup_impl_witness %T.dc4a5c.1, @Destroy [symbolic]
// CHECK:STDOUT:   %facet_value.176: %facet_type.a1aaf9.2 = facet_value %T.as_type.5d6f3f.1, (%Copy.lookup_impl_witness.fd8341.2, %Destroy.lookup_impl_witness.49108c.2) [symbolic]
// CHECK:STDOUT:   %.1c5: require_specific_def_type = require_specific_def @T.as_type.as.OptionalStorage.impl(%facet_value.176) [symbolic]
// CHECK:STDOUT:   %OptionalStorage.facet.463: %OptionalStorage.type = facet_value %T.as_type.5d6f3f.1, (%OptionalStorage.lookup_impl_witness.a98) [symbolic]
// CHECK:STDOUT:   %Optional.4d3: type = class_type @Optional, @Optional(%OptionalStorage.facet.463) [symbolic]
// CHECK:STDOUT:   %pattern_type.6d4: type = pattern_type %Optional.4d3 [symbolic]
// CHECK:STDOUT:   %a.param_patt.d75: %pattern_type.6d4 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %a.patt.984: %pattern_type.6d4 = wrapper_binding_pattern a, %a.param_patt.d75 [symbolic]
// CHECK:STDOUT:   %b.param_patt.5ec: %pattern_type.6d4 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %b.patt.b97: %pattern_type.6d4 = wrapper_binding_pattern b, %b.param_patt.5ec [symbolic]
// CHECK:STDOUT:   %return.patt.c0c: %pattern_type.831 = return_slot_pattern %return.param_patt.5a1, bool [concrete]
// CHECK:STDOUT:   %Same.type: type = fn_type @Same [concrete]
// CHECK:STDOUT:   %Same: %Same.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete.b69: <witness> = require_complete_type %Optional.4d3 [symbolic]
// CHECK:STDOUT:   %EqWith.type.330: type = facet_type <@EqWith, @EqWith(%Optional.4d3)> [symbolic]
// CHECK:STDOUT:   %EqWith.assoc_type.b51: type = assoc_entity_type @EqWith, @EqWith(%Optional.4d3) [symbolic]
// CHECK:STDOUT:   %assoc0.eed: %EqWith.assoc_type.b51 = assoc_entity element0, imports.%Core.import_ref.5ba2c [symbolic]
// CHECK:STDOUT:   %require_complete.2ce: <witness> = require_complete_type %EqWith.type.330 [symbolic]
// CHECK:STDOUT:   %assoc0.d00a4a.3: %EqWith.assoc_type.85b = assoc_entity element0, imports.%Core.import_ref.2e55e8.3 [symbolic]
// CHECK:STDOUT:   %facet_type.342: type = facet_type <@Destroy & @OptionalStorage & @Eq> [concrete]
// CHECK:STDOUT:   %T.2d7: %facet_type.342 = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %Optional.as.EqWith.impl.Equal.type.d1a: type = fn_type @Optional.as.EqWith.impl.Equal, @Optional.as.EqWith.impl(%T.2d7) [symbolic]
// CHECK:STDOUT:   %Optional.as.EqWith.impl.Equal.384: %Optional.as.EqWith.impl.Equal.type.d1a = struct_value () [symbolic]
// CHECK:STDOUT:   %EqWith.lookup_impl_witness.781: <witness> = lookup_impl_witness %T.dc4a5c.1, @EqWith, @EqWith(%T.as_type.5d6f3f.1) [symbolic]
// CHECK:STDOUT:   %facet_value.c84: %facet_type.342 = facet_value %T.as_type.5d6f3f.1, (%EqWith.lookup_impl_witness.781, %Destroy.lookup_impl_witness.49108c.2, %OptionalStorage.lookup_impl_witness.a98) [symbolic]
// CHECK:STDOUT:   %EqWith.impl_witness.1e9: <witness> = impl_witness imports.%EqWith.impl_witness_table.978, @Optional.as.EqWith.impl(%facet_value.c84) [symbolic]
// CHECK:STDOUT:   %Optional.as.EqWith.impl.Equal.type.d97: type = fn_type @Optional.as.EqWith.impl.Equal, @Optional.as.EqWith.impl(%facet_value.c84) [symbolic]
// CHECK:STDOUT:   %Optional.as.EqWith.impl.Equal.48b: %Optional.as.EqWith.impl.Equal.type.d97 = struct_value () [symbolic]
// CHECK:STDOUT:   %.764: require_specific_def_type = require_specific_def @Optional.as.EqWith.impl(%facet_value.c84) [symbolic]
// CHECK:STDOUT:   %EqWith.facet.0d1: %EqWith.type.330 = facet_value %Optional.4d3, (%EqWith.impl_witness.1e9) [symbolic]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.1f0: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%Optional.4d3, %EqWith.facet.0d1) [symbolic]
// CHECK:STDOUT:   %.3e35: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.1f0, %EqWith.facet.0d1 [symbolic]
// CHECK:STDOUT:   %Optional.as.EqWith.impl.Equal.specific_fn.3b3: <specific function> = specific_function %Optional.as.EqWith.impl.Equal.48b, @Optional.as.EqWith.impl.Equal(%facet_value.c84) [symbolic]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %Int.type: type = generic_class_type @Int [concrete]
// CHECK:STDOUT:   %Int.generic: %Int.type = struct_value () [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.8cc: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_64) [concrete]
// CHECK:STDOUT:   %pattern_type.f57: type = pattern_type %i64 [concrete]
// CHECK:STDOUT:   %self.param_patt.108: %pattern_type.f57 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.5f4: %pattern_type.f57 = wrapper_binding_pattern self, %self.param_patt.108 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfc: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc10 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01: %Destroy.WithSelf.SubobjectDestroy.type.dfc = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef0: type = fn_type @Destroy.WithSelf.Op.loc10 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403: %Destroy.WithSelf.Op.type.ef0 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbc: type = fn_type @Destroy.WithSelf.SelfDestruct.loc10 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3: %Destroy.WithSelf.SelfDestruct.type.fbc = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.f8f: <witness> = custom_witness (%Destroy.WithSelf.Op.403, %Destroy.WithSelf.SubobjectDestroy.d01, %Destroy.WithSelf.SelfDestruct.db3), @Destroy [concrete]
// CHECK:STDOUT:   %facet_value.b60: %facet_type.a1aaf9.2 = facet_value %i64, (%Copy.impl_witness.8cc, %custom_witness.f8f) [concrete]
// CHECK:STDOUT:   %DefaultOptionalStorage.8f6: type = class_type @DefaultOptionalStorage, @DefaultOptionalStorage(%facet_value.b60) [concrete]
// CHECK:STDOUT:   %OptionalStorage.impl_witness.ccf: <witness> = impl_witness imports.%OptionalStorage.impl_witness_table.0d6, @T.as_type.as.OptionalStorage.impl(%facet_value.b60) [concrete]
// CHECK:STDOUT:   %.8439: require_specific_def_type = require_specific_def @T.as_type.as.OptionalStorage.impl(%facet_value.b60) [concrete]
// CHECK:STDOUT:   %OptionalStorage.facet.cbb: %OptionalStorage.type = facet_value %i64, (%OptionalStorage.impl_witness.ccf) [concrete]
// CHECK:STDOUT:   %Optional.0e7: type = class_type @Optional, @Optional(%OptionalStorage.facet.cbb) [concrete]
// CHECK:STDOUT:   %pattern_type.765: type = pattern_type %Optional.0e7 [concrete]
// CHECK:STDOUT:   %a.param_patt.535: %pattern_type.765 = value_param_pattern [concrete]
// CHECK:STDOUT:   %a.patt.9e5: %pattern_type.765 = wrapper_binding_pattern a, %a.param_patt.535 [concrete]
// CHECK:STDOUT:   %UseSame.type: type = fn_type @UseSame [concrete]
// CHECK:STDOUT:   %UseSame: %UseSame.type = struct_value () [concrete]
// CHECK:STDOUT:   %complete_type.dea: <witness> = complete_type_witness %DefaultOptionalStorage.8f6 [concrete]
// CHECK:STDOUT:   %M: Core.IntLiteral = symbolic_binding M, 1 [symbolic]
// CHECK:STDOUT:   %Int.as.EqWith.impl.Equal.type.9a2: type = fn_type @Int.as.EqWith.impl.Equal.1, @Int.as.EqWith.impl.e9c(%N, %M) [symbolic]
// CHECK:STDOUT:   %Int.as.EqWith.impl.Equal.792: %Int.as.EqWith.impl.Equal.type.9a2 = struct_value () [symbolic]
// CHECK:STDOUT:   %EqWith.impl_witness.932: <witness> = impl_witness imports.%EqWith.impl_witness_table.09e, @Int.as.EqWith.impl.e9c(%int_64, %int_64) [concrete]
// CHECK:STDOUT:   %facet_value.c24: %facet_type.a1aaf9.1 = facet_value %i64, (%EqWith.impl_witness.932, %Copy.impl_witness.8cc, %custom_witness.f8f) [concrete]
// CHECK:STDOUT:   %b.param_patt.d47: %pattern_type.765 = value_param_pattern [concrete]
// CHECK:STDOUT:   %b.patt.9e8: %pattern_type.765 = wrapper_binding_pattern b, %b.param_patt.d47 [concrete]
// CHECK:STDOUT:   %Same.specific_fn: <specific function> = specific_function %Same, @Same(%facet_value.c24) [concrete]
// CHECK:STDOUT:   %EqWith.type.240: type = facet_type <@EqWith, @EqWith(%Optional.0e7)> [concrete]
// CHECK:STDOUT:   %EqWith.assoc_type.9c9: type = assoc_entity_type @EqWith, @EqWith(%Optional.0e7) [concrete]
// CHECK:STDOUT:   %assoc0.1f4: %EqWith.assoc_type.9c9 = assoc_entity element0, imports.%Core.import_ref.5ba2c [concrete]
// CHECK:STDOUT:   %complete_type.91e: <witness> = complete_type_witness %EqWith.type.240 [concrete]
// CHECK:STDOUT:   %facet_value.68c: %facet_type.342 = facet_value %i64, (%EqWith.impl_witness.932, %custom_witness.f8f, %OptionalStorage.impl_witness.ccf) [concrete]
// CHECK:STDOUT:   %EqWith.impl_witness.243: <witness> = impl_witness imports.%EqWith.impl_witness_table.978, @Optional.as.EqWith.impl(%facet_value.68c) [concrete]
// CHECK:STDOUT:   %Optional.as.EqWith.impl.Equal.type.a24: type = fn_type @Optional.as.EqWith.impl.Equal, @Optional.as.EqWith.impl(%facet_value.68c) [concrete]
// CHECK:STDOUT:   %Optional.as.EqWith.impl.Equal.05f: %Optional.as.EqWith.impl.Equal.type.a24 = struct_value () [concrete]
// CHECK:STDOUT:   %.f52: require_specific_def_type = require_specific_def @Optional.as.EqWith.impl(%facet_value.68c) [concrete]
// CHECK:STDOUT:   %EqWith.facet.967: %EqWith.type.240 = facet_value %Optional.0e7, (%EqWith.impl_witness.243) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.a5f: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%Optional.0e7, %EqWith.facet.967) [concrete]
// CHECK:STDOUT:   %.88b: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.a5f, %EqWith.facet.967 [concrete]
// CHECK:STDOUT:   %Optional.as.EqWith.impl.Equal.specific_fn.ae2: <specific function> = specific_function %Optional.as.EqWith.impl.Equal.05f, @Optional.as.EqWith.impl.Equal(%facet_value.68c) [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .Eq = %Core.Eq
// CHECK:STDOUT:     .Copy = %Core.Copy.e5d
// CHECK:STDOUT:     .BitAndWith = %Core.BitAndWith
// CHECK:STDOUT:     .Destroy = %Core.Destroy
// CHECK:STDOUT:     .Optional = %Core.Optional
// CHECK:STDOUT:     .Bool = %Core.Bool
// CHECK:STDOUT:     .EqWith = %Core.EqWith
// CHECK:STDOUT:     .Int = %Core.Int
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Eq: type = import_ref Core//prelude/operators/comparison, Eq, loaded [concrete = constants.%Eq.type]
// CHECK:STDOUT:   %Core.import_ref.725: @EqWith.WithSelf.%EqWith.assoc_type (%EqWith.assoc_type.85b) = import_ref Core//prelude/operators/comparison, loc{{\d+_\d+}}, loaded [symbolic = @EqWith.WithSelf.%assoc0 (constants.%assoc0.d00a4a.3)]
// CHECK:STDOUT:   %Core.import_ref.5ba2c: @EqWith.WithSelf.%EqWith.WithSelf.Equal.type (%EqWith.WithSelf.Equal.type.b82) = import_ref Core//prelude/operators/comparison, loc{{\d+_\d+}}, loaded [symbolic = @EqWith.WithSelf.%EqWith.WithSelf.Equal (constants.%EqWith.WithSelf.Equal.ae3)]
// CHECK:STDOUT:   %Core.Copy.e5d: type = import_ref Core//prelude/copy, Copy, loaded [concrete = constants.%Copy.type]
// CHECK:STDOUT:   %Core.BitAndWith: %BitAndWith.type.a06 = import_ref Core//prelude/operators/bitwise, BitAndWith, loaded [concrete = constants.%BitAndWith.generic]
// CHECK:STDOUT:   %Core.import_ref.05b = import_ref Core//prelude/operators/bitwise, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9c3: %type.as.BitAndWith.impl.Op.type = import_ref Core//prelude/operators/bitwise, loc{{\d+_\d+}}, loaded [concrete = constants.%type.as.BitAndWith.impl.Op]
// CHECK:STDOUT:   %BitAndWith.impl_witness_table = impl_witness_table (%Core.import_ref.05b, %Core.import_ref.9c3), @type.as.BitAndWith.impl [concrete]
// CHECK:STDOUT:   %Core.Destroy: type = import_ref Core//prelude/destroy, Destroy, loaded [concrete = constants.%Destroy.type]
// CHECK:STDOUT:   %Core.Optional: %Optional.type = import_ref Core//prelude/types/optional, Optional, loaded [concrete = constants.%Optional.generic]
// CHECK:STDOUT:   %Core.import_ref.f38: %Destroy.type = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @T.as_type.as.OptionalStorage.impl.%Destroy.facet (constants.%Destroy.facet.0de)]
// CHECK:STDOUT:   %Core.import_ref.f71 = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.f5a = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.e5a: @T.as_type.as.OptionalStorage.impl.%T.as_type.as.OptionalStorage.impl.Has.type (%T.as_type.as.OptionalStorage.impl.Has.type.62c) = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @T.as_type.as.OptionalStorage.impl.%T.as_type.as.OptionalStorage.impl.Has (constants.%T.as_type.as.OptionalStorage.impl.Has.7e4)]
// CHECK:STDOUT:   %Core.import_ref.9d5: @T.as_type.as.OptionalStorage.impl.%T.as_type.as.OptionalStorage.impl.Get.type (%T.as_type.as.OptionalStorage.impl.Get.type.7fb) = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @T.as_type.as.OptionalStorage.impl.%T.as_type.as.OptionalStorage.impl.Get (constants.%T.as_type.as.OptionalStorage.impl.Get.a96)]
// CHECK:STDOUT:   %Core.import_ref.007 = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %OptionalStorage.impl_witness_table.0d6 = impl_witness_table (%Core.import_ref.f38, %Core.import_ref.f71, %Core.import_ref.f5a, %Core.import_ref.e5a, %Core.import_ref.9d5, %Core.import_ref.007), @T.as_type.as.OptionalStorage.impl [concrete]
// CHECK:STDOUT:   %Core.Bool: type = import_ref Core//prelude/types/bool, Bool, loaded [concrete = bool]
// CHECK:STDOUT:   %Core.EqWith: %EqWith.type.f77 = import_ref Core//prelude/operators/comparison, EqWith, loaded [concrete = constants.%EqWith.generic]
// CHECK:STDOUT:   %Core.import_ref.2e55e8.3 = import_ref Core//prelude/operators/comparison, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.477: @Optional.as.EqWith.impl.%Optional.as.EqWith.impl.Equal.type (%Optional.as.EqWith.impl.Equal.type.d1a) = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @Optional.as.EqWith.impl.%Optional.as.EqWith.impl.Equal (constants.%Optional.as.EqWith.impl.Equal.384)]
// CHECK:STDOUT:   %Core.import_ref.06a = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.978 = impl_witness_table (%Core.import_ref.477, %Core.import_ref.06a), @Optional.as.EqWith.impl [concrete]
// CHECK:STDOUT:   %Core.Int: %Int.type = import_ref Core//prelude/types/int, Int, loaded [concrete = constants.%Int.generic]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.074: @Int.as.EqWith.impl.e9c.%Int.as.EqWith.impl.Equal.type (%Int.as.EqWith.impl.Equal.type.9a2) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.EqWith.impl.e9c.%Int.as.EqWith.impl.Equal (constants.%Int.as.EqWith.impl.Equal.792)]
// CHECK:STDOUT:   %Core.import_ref.449 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.09e = impl_witness_table (%Core.import_ref.074, %Core.import_ref.449), @Int.as.EqWith.impl.e9c [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl: %Destroy.WithSelf.SubobjectDestroy.type.dfc = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc10 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.f57 = ref_param_pattern [concrete = constants.%self.param_patt.108]
// CHECK:STDOUT:     %self.patt: %pattern_type.f57 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.5f4]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i64 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i64 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl: %Destroy.WithSelf.Op.type.ef0 = fn_decl @Destroy.WithSelf.Op.loc10 [concrete = constants.%Destroy.WithSelf.Op.403] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.f57 = ref_param_pattern [concrete = constants.%self.param_patt.108]
// CHECK:STDOUT:     %self.patt: %pattern_type.f57 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.5f4]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i64 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i64 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Same.decl: %Same.type = fn_decl @Same [concrete = constants.%Same] {
// CHECK:STDOUT:     %T.patt.loc5_10.1: %pattern_type.143af7.1 = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc5_10.2 (constants.%T.patt.256c82.1)]
// CHECK:STDOUT:     %a.param_patt.loc5_49.1: @Same.%pattern_type (%pattern_type.6d4) = value_param_pattern [symbolic = %a.param_patt.loc5_49.2 (constants.%a.param_patt.d75)]
// CHECK:STDOUT:     %a.patt.loc5_49.1: @Same.%pattern_type (%pattern_type.6d4) = wrapper_binding_pattern a, %a.param_patt.loc5_49.1 [symbolic = %a.patt.loc5_49.2 (constants.%a.patt.984)]
// CHECK:STDOUT:     %b.param_patt.loc6_49.1: @Same.%pattern_type (%pattern_type.6d4) = value_param_pattern [symbolic = %b.param_patt.loc6_49.2 (constants.%b.param_patt.5ec)]
// CHECK:STDOUT:     %b.patt.loc6_49.1: @Same.%pattern_type (%pattern_type.6d4) = wrapper_binding_pattern b, %b.param_patt.loc6_49.1 [symbolic = %b.patt.loc6_49.2 (constants.%b.patt.b97)]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.831 = out_param_pattern [concrete = constants.%return.param_patt.5a1]
// CHECK:STDOUT:     %return.patt: %pattern_type.831 = return_slot_pattern %return.param_patt, %.loc6_72.1 [concrete = constants.%return.patt.c0c]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc6_72.1: type = type_literal bool [concrete = bool]
// CHECK:STDOUT:     %.loc6_72.2: Core.Form = init_form %.loc6_72.1 [concrete = constants.%.f34]
// CHECK:STDOUT:     %.loc5_32.1: type = splice_block %.loc5_32.3 [concrete = constants.%facet_type.a1aaf9.1] {
// CHECK:STDOUT:       %.Self.frozen: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %Core.ref.loc5_12: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %Eq.ref: type = name_ref Eq, imports.%Core.Eq [concrete = constants.%Eq.type]
// CHECK:STDOUT:       %Core.ref.loc5_22: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %Copy.ref: type = name_ref Copy, imports.%Core.Copy.e5d [concrete = constants.%Copy.type]
// CHECK:STDOUT:       %impl.elem1.loc5_20: %.85c = impl_witness_access constants.%BitAndWith.impl_witness, element1 [concrete = constants.%type.as.BitAndWith.impl.Op]
// CHECK:STDOUT:       %bound_method.loc5_20: <bound method> = bound_method %Eq.ref, %impl.elem1.loc5_20 [concrete = constants.%type.as.BitAndWith.impl.Op.bound.7a5]
// CHECK:STDOUT:       %type.as.BitAndWith.impl.Op.call.loc5_20: init type = call %bound_method.loc5_20(%Eq.ref, %Copy.ref) [concrete = constants.%facet_type.bd0]
// CHECK:STDOUT:       %Core.ref.loc5_34: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %Destroy.ref: type = name_ref Destroy, imports.%Core.Destroy [concrete = constants.%Destroy.type]
// CHECK:STDOUT:       %impl.elem1.loc5_32: %.85c = impl_witness_access constants.%BitAndWith.impl_witness, element1 [concrete = constants.%type.as.BitAndWith.impl.Op]
// CHECK:STDOUT:       %bound_method.loc5_32: <bound method> = bound_method %type.as.BitAndWith.impl.Op.call.loc5_20, %impl.elem1.loc5_32 [concrete = constants.%type.as.BitAndWith.impl.Op.bound.e6a]
// CHECK:STDOUT:       %.loc5_20.1: type = value_of_initializer %type.as.BitAndWith.impl.Op.call.loc5_20 [concrete = constants.%facet_type.bd0]
// CHECK:STDOUT:       %.loc5_20.2: type = converted %type.as.BitAndWith.impl.Op.call.loc5_20, %.loc5_20.1 [concrete = constants.%facet_type.bd0]
// CHECK:STDOUT:       %type.as.BitAndWith.impl.Op.call.loc5_32: init type = call %bound_method.loc5_32(%.loc5_20.2, %Destroy.ref) [concrete = constants.%facet_type.a1aaf9.1]
// CHECK:STDOUT:       %.loc5_32.2: type = value_of_initializer %type.as.BitAndWith.impl.Op.call.loc5_32 [concrete = constants.%facet_type.a1aaf9.1]
// CHECK:STDOUT:       %.loc5_32.3: type = converted %type.as.BitAndWith.impl.Op.call.loc5_32, %.loc5_32.2 [concrete = constants.%facet_type.a1aaf9.1]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc5_10.2: %facet_type.a1aaf9.1 = symbolic_binding T, 0 [symbolic = %T.loc5_10.1 (constants.%T.dc4a5c.1)]
// CHECK:STDOUT:     %a.param: @Same.%Optional.loc5_66.1 (%Optional.4d3) = value_param call_param0
// CHECK:STDOUT:     %.loc5_66.2: type = splice_block %Optional.loc5_66.2 [symbolic = %Optional.loc5_66.1 (constants.%Optional.4d3)] {
// CHECK:STDOUT:       %Core.ref.loc5_51: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %Optional.ref.loc5: %Optional.type = name_ref Optional, imports.%Core.Optional [concrete = constants.%Optional.generic]
// CHECK:STDOUT:       %T.ref.loc5: %facet_type.a1aaf9.1 = name_ref T, %T.loc5_10.2 [symbolic = %T.loc5_10.1 (constants.%T.dc4a5c.1)]
// CHECK:STDOUT:       %T.as_type.loc5_66.2: type = facet_access_type %T.ref.loc5 [symbolic = %T.as_type.loc5_66.1 (constants.%T.as_type.5d6f3f.1)]
// CHECK:STDOUT:       %OptionalStorage.facet.loc5_66.2: %OptionalStorage.type = facet_value %T.as_type.loc5_66.2, (constants.%OptionalStorage.lookup_impl_witness.a98) [symbolic = %OptionalStorage.facet.loc5_66.1 (constants.%OptionalStorage.facet.463)]
// CHECK:STDOUT:       %.loc5_66.3: %OptionalStorage.type = converted %T.ref.loc5, %OptionalStorage.facet.loc5_66.2 [symbolic = %OptionalStorage.facet.loc5_66.1 (constants.%OptionalStorage.facet.463)]
// CHECK:STDOUT:       %Optional.loc5_66.2: type = class_type @Optional, @Optional(constants.%OptionalStorage.facet.463) [symbolic = %Optional.loc5_66.1 (constants.%Optional.4d3)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %a: @Same.%Optional.loc5_66.1 (%Optional.4d3) = wrapper_binding a, %a.param
// CHECK:STDOUT:     %b.param: @Same.%Optional.loc5_66.1 (%Optional.4d3) = value_param call_param1
// CHECK:STDOUT:     %.loc6_66.1: type = splice_block %Optional.loc6 [symbolic = %Optional.loc5_66.1 (constants.%Optional.4d3)] {
// CHECK:STDOUT:       %Core.ref.loc6: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %Optional.ref.loc6: %Optional.type = name_ref Optional, imports.%Core.Optional [concrete = constants.%Optional.generic]
// CHECK:STDOUT:       %T.ref.loc6: %facet_type.a1aaf9.1 = name_ref T, %T.loc5_10.2 [symbolic = %T.loc5_10.1 (constants.%T.dc4a5c.1)]
// CHECK:STDOUT:       %T.as_type.loc6: type = facet_access_type %T.ref.loc6 [symbolic = %T.as_type.loc5_66.1 (constants.%T.as_type.5d6f3f.1)]
// CHECK:STDOUT:       %OptionalStorage.facet.loc6: %OptionalStorage.type = facet_value %T.as_type.loc6, (constants.%OptionalStorage.lookup_impl_witness.a98) [symbolic = %OptionalStorage.facet.loc5_66.1 (constants.%OptionalStorage.facet.463)]
// CHECK:STDOUT:       %.loc6_66.2: %OptionalStorage.type = converted %T.ref.loc6, %OptionalStorage.facet.loc6 [symbolic = %OptionalStorage.facet.loc5_66.1 (constants.%OptionalStorage.facet.463)]
// CHECK:STDOUT:       %Optional.loc6: type = class_type @Optional, @Optional(constants.%OptionalStorage.facet.463) [symbolic = %Optional.loc5_66.1 (constants.%Optional.4d3)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %b: @Same.%Optional.loc5_66.1 (%Optional.4d3) = wrapper_binding b, %b.param
// CHECK:STDOUT:     %return.param: ref bool = out_param call_param2
// CHECK:STDOUT:     %return: ref bool = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %UseSame.decl: %UseSame.type = fn_decl @UseSame [concrete = constants.%UseSame] {
// CHECK:STDOUT:     %a.param_patt: %pattern_type.765 = value_param_pattern [concrete = constants.%a.param_patt.535]
// CHECK:STDOUT:     %a.patt: %pattern_type.765 = wrapper_binding_pattern a, %a.param_patt [concrete = constants.%a.patt.9e5]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.831 = out_param_pattern [concrete = constants.%return.param_patt.5a1]
// CHECK:STDOUT:     %return.patt: %pattern_type.831 = return_slot_pattern %return.param_patt, %.loc10_38.1 [concrete = constants.%return.patt.c0c]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc10_38.1: type = type_literal bool [concrete = bool]
// CHECK:STDOUT:     %.loc10_38.2: Core.Form = init_form %.loc10_38.1 [concrete = constants.%.f34]
// CHECK:STDOUT:     %a.param: %Optional.0e7 = value_param call_param0
// CHECK:STDOUT:     %.loc10_32.1: type = splice_block %Optional [concrete = constants.%Optional.0e7] {
// CHECK:STDOUT:       %Core.ref: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %Optional.ref: %Optional.type = name_ref Optional, imports.%Core.Optional [concrete = constants.%Optional.generic]
// CHECK:STDOUT:       %i64: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:       %OptionalStorage.facet: %OptionalStorage.type = facet_value %i64, (constants.%OptionalStorage.impl_witness.ccf) [concrete = constants.%OptionalStorage.facet.cbb]
// CHECK:STDOUT:       %.loc10_32.2: %OptionalStorage.type = converted %i64, %OptionalStorage.facet [concrete = constants.%OptionalStorage.facet.cbb]
// CHECK:STDOUT:       %Optional: type = class_type @Optional, @Optional(constants.%OptionalStorage.facet.cbb) [concrete = constants.%Optional.0e7]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %a: %Optional.0e7 = wrapper_binding a, %a.param
// CHECK:STDOUT:     %return.param: ref bool = out_param call_param1
// CHECK:STDOUT:     %return: ref bool = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @Same(%T.loc5_10.2: %facet_type.a1aaf9.1) {
// CHECK:STDOUT:   %T.patt.loc5_10.2: %pattern_type.143af7.1 = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc5_10.2 (constants.%T.patt.256c82.1)]
// CHECK:STDOUT:   %T.loc5_10.1: %facet_type.a1aaf9.1 = symbolic_binding T, 0 [symbolic = %T.loc5_10.1 (constants.%T.dc4a5c.1)]
// CHECK:STDOUT:   %T.as_type.loc5_66.1: type = facet_access_type %T.loc5_10.1 [symbolic = %T.as_type.loc5_66.1 (constants.%T.as_type.5d6f3f.1)]
// CHECK:STDOUT:   %Copy.lookup_impl_witness: <witness> = lookup_impl_witness %T.loc5_10.1, @Copy [symbolic = %Copy.lookup_impl_witness (constants.%Copy.lookup_impl_witness.fd8341.2)]
// CHECK:STDOUT:   %Destroy.lookup_impl_witness: <witness> = lookup_impl_witness %T.loc5_10.1, @Destroy [symbolic = %Destroy.lookup_impl_witness (constants.%Destroy.lookup_impl_witness.49108c.2)]
// CHECK:STDOUT:   %facet_value.loc5: %facet_type.a1aaf9.2 = facet_value %T.as_type.loc5_66.1, (%Copy.lookup_impl_witness, %Destroy.lookup_impl_witness) [symbolic = %facet_value.loc5 (constants.%facet_value.176)]
// CHECK:STDOUT:   %.loc5_66.1: require_specific_def_type = require_specific_def @T.as_type.as.OptionalStorage.impl(%facet_value.loc5) [symbolic = %.loc5_66.1 (constants.%.1c5)]
// CHECK:STDOUT:   %OptionalStorage.lookup_impl_witness: <witness> = lookup_impl_witness %T.loc5_10.1, @OptionalStorage [symbolic = %OptionalStorage.lookup_impl_witness (constants.%OptionalStorage.lookup_impl_witness.a98)]
// CHECK:STDOUT:   %OptionalStorage.facet.loc5_66.1: %OptionalStorage.type = facet_value %T.as_type.loc5_66.1, (%OptionalStorage.lookup_impl_witness) [symbolic = %OptionalStorage.facet.loc5_66.1 (constants.%OptionalStorage.facet.463)]
// CHECK:STDOUT:   %Optional.loc5_66.1: type = class_type @Optional, @Optional(%OptionalStorage.facet.loc5_66.1) [symbolic = %Optional.loc5_66.1 (constants.%Optional.4d3)]
// CHECK:STDOUT:   %pattern_type: type = pattern_type %Optional.loc5_66.1 [symbolic = %pattern_type (constants.%pattern_type.6d4)]
// CHECK:STDOUT:   %a.param_patt.loc5_49.2: @Same.%pattern_type (%pattern_type.6d4) = value_param_pattern [symbolic = %a.param_patt.loc5_49.2 (constants.%a.param_patt.d75)]
// CHECK:STDOUT:   %a.patt.loc5_49.2: @Same.%pattern_type (%pattern_type.6d4) = wrapper_binding_pattern a, %a.param_patt.loc5_49.2 [symbolic = %a.patt.loc5_49.2 (constants.%a.patt.984)]
// CHECK:STDOUT:   %b.param_patt.loc6_49.2: @Same.%pattern_type (%pattern_type.6d4) = value_param_pattern [symbolic = %b.param_patt.loc6_49.2 (constants.%b.param_patt.5ec)]
// CHECK:STDOUT:   %b.patt.loc6_49.2: @Same.%pattern_type (%pattern_type.6d4) = wrapper_binding_pattern b, %b.param_patt.loc6_49.2 [symbolic = %b.patt.loc6_49.2 (constants.%b.patt.b97)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc5: <witness> = require_complete_type %Optional.loc5_66.1 [symbolic = %require_complete.loc5 (constants.%require_complete.b69)]
// CHECK:STDOUT:   %EqWith.type.loc7_12.2: type = facet_type <@EqWith, @EqWith(%Optional.loc5_66.1)> [symbolic = %EqWith.type.loc7_12.2 (constants.%EqWith.type.330)]
// CHECK:STDOUT:   %require_complete.loc7: <witness> = require_complete_type %EqWith.type.loc7_12.2 [symbolic = %require_complete.loc7 (constants.%require_complete.2ce)]
// CHECK:STDOUT:   %EqWith.assoc_type: type = assoc_entity_type @EqWith, @EqWith(%Optional.loc5_66.1) [symbolic = %EqWith.assoc_type (constants.%EqWith.assoc_type.b51)]
// CHECK:STDOUT:   %assoc0: @Same.%EqWith.assoc_type (%EqWith.assoc_type.b51) = assoc_entity element0, imports.%Core.import_ref.5ba2c [symbolic = %assoc0 (constants.%assoc0.eed)]
// CHECK:STDOUT:   %EqWith.lookup_impl_witness: <witness> = lookup_impl_witness %T.loc5_10.1, @EqWith, @EqWith(%T.as_type.loc5_66.1) [symbolic = %EqWith.lookup_impl_witness (constants.%EqWith.lookup_impl_witness.781)]
// CHECK:STDOUT:   %facet_value.loc7_12.5: %facet_type.342 = facet_value %T.as_type.loc5_66.1, (%EqWith.lookup_impl_witness, %Destroy.lookup_impl_witness, %OptionalStorage.lookup_impl_witness) [symbolic = %facet_value.loc7_12.5 (constants.%facet_value.c84)]
// CHECK:STDOUT:   %.loc7_12.6: require_specific_def_type = require_specific_def @Optional.as.EqWith.impl(%facet_value.loc7_12.5) [symbolic = %.loc7_12.6 (constants.%.764)]
// CHECK:STDOUT:   %EqWith.impl_witness: <witness> = impl_witness imports.%EqWith.impl_witness_table.978, @Optional.as.EqWith.impl(%facet_value.loc7_12.5) [symbolic = %EqWith.impl_witness (constants.%EqWith.impl_witness.1e9)]
// CHECK:STDOUT:   %EqWith.facet: @Same.%EqWith.type.loc7_12.2 (%EqWith.type.330) = facet_value %Optional.loc5_66.1, (%EqWith.impl_witness) [symbolic = %EqWith.facet (constants.%EqWith.facet.0d1)]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%Optional.loc5_66.1, %EqWith.facet) [symbolic = %EqWith.WithSelf.Equal.type (constants.%EqWith.WithSelf.Equal.type.1f0)]
// CHECK:STDOUT:   %.loc7_12.7: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type, %EqWith.facet [symbolic = %.loc7_12.7 (constants.%.3e35)]
// CHECK:STDOUT:   %Optional.as.EqWith.impl.Equal.type: type = fn_type @Optional.as.EqWith.impl.Equal, @Optional.as.EqWith.impl(%facet_value.loc7_12.5) [symbolic = %Optional.as.EqWith.impl.Equal.type (constants.%Optional.as.EqWith.impl.Equal.type.d97)]
// CHECK:STDOUT:   %Optional.as.EqWith.impl.Equal: @Same.%Optional.as.EqWith.impl.Equal.type (%Optional.as.EqWith.impl.Equal.type.d97) = struct_value () [symbolic = %Optional.as.EqWith.impl.Equal (constants.%Optional.as.EqWith.impl.Equal.48b)]
// CHECK:STDOUT:   %Optional.as.EqWith.impl.Equal.specific_fn: <specific function> = specific_function %Optional.as.EqWith.impl.Equal, @Optional.as.EqWith.impl.Equal(%facet_value.loc7_12.5) [symbolic = %Optional.as.EqWith.impl.Equal.specific_fn (constants.%Optional.as.EqWith.impl.Equal.specific_fn.3b3)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%a.param: @Same.%Optional.loc5_66.1 (%Optional.4d3), %b.param: @Same.%Optional.loc5_66.1 (%Optional.4d3)) -> out %return.param: bool {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %a.ref: @Same.%Optional.loc5_66.1 (%Optional.4d3) = name_ref a, %a
// CHECK:STDOUT:     %b.ref: @Same.%Optional.loc5_66.1 (%Optional.4d3) = name_ref b, %b
// CHECK:STDOUT:     %EqWith.type.loc7_12.1: type = facet_type <@EqWith, @EqWith(constants.%Optional.4d3)> [symbolic = %EqWith.type.loc7_12.2 (constants.%EqWith.type.330)]
// CHECK:STDOUT:     %.loc7_12.1: @Same.%EqWith.assoc_type (%EqWith.assoc_type.b51) = specific_constant imports.%Core.import_ref.725, @EqWith.WithSelf(constants.%Optional.4d3, constants.%Self.d94) [symbolic = %assoc0 (constants.%assoc0.eed)]
// CHECK:STDOUT:     %Equal.ref: @Same.%EqWith.assoc_type (%EqWith.assoc_type.b51) = name_ref Equal, %.loc7_12.1 [symbolic = %assoc0 (constants.%assoc0.eed)]
// CHECK:STDOUT:     %impl.elem0: @Same.%.loc7_12.7 (%.3e35) = impl_witness_access constants.%EqWith.impl_witness.1e9, element0 [symbolic = %Optional.as.EqWith.impl.Equal (constants.%Optional.as.EqWith.impl.Equal.48b)]
// CHECK:STDOUT:     %bound_method.loc7_12.1: <bound method> = bound_method %a.ref, %impl.elem0
// CHECK:STDOUT:     %facet_value.loc7_12.1: %facet_type.342 = facet_value constants.%T.as_type.5d6f3f.1, (constants.%EqWith.lookup_impl_witness.781, constants.%Destroy.lookup_impl_witness.49108c.2, constants.%OptionalStorage.lookup_impl_witness.a98) [symbolic = %facet_value.loc7_12.5 (constants.%facet_value.c84)]
// CHECK:STDOUT:     %.loc7_12.2: %facet_type.342 = converted constants.%T.as_type.5d6f3f.1, %facet_value.loc7_12.1 [symbolic = %facet_value.loc7_12.5 (constants.%facet_value.c84)]
// CHECK:STDOUT:     %facet_value.loc7_12.2: %facet_type.342 = facet_value constants.%T.as_type.5d6f3f.1, (constants.%EqWith.lookup_impl_witness.781, constants.%Destroy.lookup_impl_witness.49108c.2, constants.%OptionalStorage.lookup_impl_witness.a98) [symbolic = %facet_value.loc7_12.5 (constants.%facet_value.c84)]
// CHECK:STDOUT:     %.loc7_12.3: %facet_type.342 = converted constants.%T.as_type.5d6f3f.1, %facet_value.loc7_12.2 [symbolic = %facet_value.loc7_12.5 (constants.%facet_value.c84)]
// CHECK:STDOUT:     %facet_value.loc7_12.3: %facet_type.342 = facet_value constants.%T.as_type.5d6f3f.1, (constants.%EqWith.lookup_impl_witness.781, constants.%Destroy.lookup_impl_witness.49108c.2, constants.%OptionalStorage.lookup_impl_witness.a98) [symbolic = %facet_value.loc7_12.5 (constants.%facet_value.c84)]
// CHECK:STDOUT:     %.loc7_12.4: %facet_type.342 = converted constants.%T.as_type.5d6f3f.1, %facet_value.loc7_12.3 [symbolic = %facet_value.loc7_12.5 (constants.%facet_value.c84)]
// CHECK:STDOUT:     %facet_value.loc7_12.4: %facet_type.342 = facet_value constants.%T.as_type.5d6f3f.1, (constants.%EqWith.lookup_impl_witness.781, constants.%Destroy.lookup_impl_witness.49108c.2, constants.%OptionalStorage.lookup_impl_witness.a98) [symbolic = %facet_value.loc7_12.5 (constants.%facet_value.c84)]
// CHECK:STDOUT:     %.loc7_12.5: %facet_type.342 = converted constants.%T.as_type.5d6f3f.1, %facet_value.loc7_12.4 [symbolic = %facet_value.loc7_12.5 (constants.%facet_value.c84)]
// CHECK:STDOUT:     %specific_fn: <specific function> = specific_function %impl.elem0, @Optional.as.EqWith.impl.Equal(constants.%facet_value.c84) [symbolic = %Optional.as.EqWith.impl.Equal.specific_fn (constants.%Optional.as.EqWith.impl.Equal.specific_fn.3b3)]
// CHECK:STDOUT:     %bound_method.loc7_12.2: <bound method> = bound_method %a.ref, %specific_fn
// CHECK:STDOUT:     %Optional.as.EqWith.impl.Equal.call: init bool = call %bound_method.loc7_12.2(%a.ref, %b.ref)
// CHECK:STDOUT:     return %Optional.as.EqWith.impl.Equal.call
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc10(%self.param: ref %i64) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc10(%self.param: ref %i64) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc10(%self.param: ref %i64) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @UseSame(%a.param: %Optional.0e7) -> out %return.param: bool {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Same.ref: %Same.type = name_ref Same, file.%Same.decl [concrete = constants.%Same]
// CHECK:STDOUT:   %a.ref.loc10_57: %Optional.0e7 = name_ref a, %a
// CHECK:STDOUT:   %a.ref.loc10_60: %Optional.0e7 = name_ref a, %a
// CHECK:STDOUT:   %facet_value.loc10_61.1: %facet_type.a1aaf9.1 = facet_value constants.%i64, (constants.%EqWith.impl_witness.932, constants.%Copy.impl_witness.8cc, constants.%custom_witness.f8f) [concrete = constants.%facet_value.c24]
// CHECK:STDOUT:   %.loc10_61.1: %facet_type.a1aaf9.1 = converted constants.%i64, %facet_value.loc10_61.1 [concrete = constants.%facet_value.c24]
// CHECK:STDOUT:   %facet_value.loc10_61.2: %facet_type.a1aaf9.1 = facet_value constants.%i64, (constants.%EqWith.impl_witness.932, constants.%Copy.impl_witness.8cc, constants.%custom_witness.f8f) [concrete = constants.%facet_value.c24]
// CHECK:STDOUT:   %.loc10_61.2: %facet_type.a1aaf9.1 = converted constants.%i64, %facet_value.loc10_61.2 [concrete = constants.%facet_value.c24]
// CHECK:STDOUT:   %facet_value.loc10_61.3: %facet_type.a1aaf9.1 = facet_value constants.%i64, (constants.%EqWith.impl_witness.932, constants.%Copy.impl_witness.8cc, constants.%custom_witness.f8f) [concrete = constants.%facet_value.c24]
// CHECK:STDOUT:   %.loc10_61.3: %facet_type.a1aaf9.1 = converted constants.%i64, %facet_value.loc10_61.3 [concrete = constants.%facet_value.c24]
// CHECK:STDOUT:   %facet_value.loc10_61.4: %facet_type.a1aaf9.1 = facet_value constants.%i64, (constants.%EqWith.impl_witness.932, constants.%Copy.impl_witness.8cc, constants.%custom_witness.f8f) [concrete = constants.%facet_value.c24]
// CHECK:STDOUT:   %.loc10_61.4: %facet_type.a1aaf9.1 = converted constants.%i64, %facet_value.loc10_61.4 [concrete = constants.%facet_value.c24]
// CHECK:STDOUT:   %Same.specific_fn: <specific function> = specific_function %Same.ref, @Same(constants.%facet_value.c24) [concrete = constants.%Same.specific_fn]
// CHECK:STDOUT:   %Same.call: init bool = call %Same.specific_fn(%a.ref.loc10_57, %a.ref.loc10_60)
// CHECK:STDOUT:   return %Same.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Same(constants.%T.dc4a5c.1) {
// CHECK:STDOUT:   %T.patt.loc5_10.2 => constants.%T.patt.256c82.1
// CHECK:STDOUT:   %T.loc5_10.1 => constants.%T.dc4a5c.1
// CHECK:STDOUT:   %T.as_type.loc5_66.1 => constants.%T.as_type.5d6f3f.1
// CHECK:STDOUT:   %Copy.lookup_impl_witness => constants.%Copy.lookup_impl_witness.fd8341.2
// CHECK:STDOUT:   %Destroy.lookup_impl_witness => constants.%Destroy.lookup_impl_witness.49108c.2
// CHECK:STDOUT:   %facet_value.loc5 => constants.%facet_value.176
// CHECK:STDOUT:   %.loc5_66.1 => constants.%.1c5
// CHECK:STDOUT:   %OptionalStorage.lookup_impl_witness => constants.%OptionalStorage.lookup_impl_witness.a98
// CHECK:STDOUT:   %OptionalStorage.facet.loc5_66.1 => constants.%OptionalStorage.facet.463
// CHECK:STDOUT:   %Optional.loc5_66.1 => constants.%Optional.4d3
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.6d4
// CHECK:STDOUT:   %a.param_patt.loc5_49.2 => constants.%a.param_patt.d75
// CHECK:STDOUT:   %a.patt.loc5_49.2 => constants.%a.patt.984
// CHECK:STDOUT:   %b.param_patt.loc6_49.2 => constants.%b.param_patt.5ec
// CHECK:STDOUT:   %b.patt.loc6_49.2 => constants.%b.patt.b97
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Same(constants.%facet_value.c24) {
// CHECK:STDOUT:   %T.patt.loc5_10.2 => constants.%T.patt.256c82.1
// CHECK:STDOUT:   %T.loc5_10.1 => constants.%facet_value.c24
// CHECK:STDOUT:   %T.as_type.loc5_66.1 => constants.%i64
// CHECK:STDOUT:   %Copy.lookup_impl_witness => constants.%Copy.impl_witness.8cc
// CHECK:STDOUT:   %Destroy.lookup_impl_witness => constants.%custom_witness.f8f
// CHECK:STDOUT:   %facet_value.loc5 => constants.%facet_value.b60
// CHECK:STDOUT:   %.loc5_66.1 => constants.%.8439
// CHECK:STDOUT:   %OptionalStorage.lookup_impl_witness => constants.%OptionalStorage.impl_witness.ccf
// CHECK:STDOUT:   %OptionalStorage.facet.loc5_66.1 => constants.%OptionalStorage.facet.cbb
// CHECK:STDOUT:   %Optional.loc5_66.1 => constants.%Optional.0e7
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.765
// CHECK:STDOUT:   %a.param_patt.loc5_49.2 => constants.%a.param_patt.535
// CHECK:STDOUT:   %a.patt.loc5_49.2 => constants.%a.patt.9e5
// CHECK:STDOUT:   %b.param_patt.loc6_49.2 => constants.%b.param_patt.d47
// CHECK:STDOUT:   %b.patt.loc6_49.2 => constants.%b.patt.9e8
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc5 => constants.%complete_type.dea
// CHECK:STDOUT:   %EqWith.type.loc7_12.2 => constants.%EqWith.type.240
// CHECK:STDOUT:   %require_complete.loc7 => constants.%complete_type.91e
// CHECK:STDOUT:   %EqWith.assoc_type => constants.%EqWith.assoc_type.9c9
// CHECK:STDOUT:   %assoc0 => constants.%assoc0.1f4
// CHECK:STDOUT:   %EqWith.lookup_impl_witness => constants.%EqWith.impl_witness.932
// CHECK:STDOUT:   %facet_value.loc7_12.5 => constants.%facet_value.68c
// CHECK:STDOUT:   %.loc7_12.6 => constants.%.f52
// CHECK:STDOUT:   %EqWith.impl_witness => constants.%EqWith.impl_witness.243
// CHECK:STDOUT:   %EqWith.facet => constants.%EqWith.facet.967
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type => constants.%EqWith.WithSelf.Equal.type.a5f
// CHECK:STDOUT:   %.loc7_12.7 => constants.%.88b
// CHECK:STDOUT:   %Optional.as.EqWith.impl.Equal.type => constants.%Optional.as.EqWith.impl.Equal.type.a24
// CHECK:STDOUT:   %Optional.as.EqWith.impl.Equal => constants.%Optional.as.EqWith.impl.Equal.05f
// CHECK:STDOUT:   %Optional.as.EqWith.impl.Equal.specific_fn => constants.%Optional.as.EqWith.impl.Equal.specific_fn.ae2
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- ordered_only.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %Rank: type = class_type @Rank [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %Int.type: type = generic_class_type @Int [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %Int.generic: %Int.type = struct_value () [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %Rank.elem: type = unbound_element_type %Rank, %i32 [concrete]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %Copy.impl_witness.d00: <witness> = impl_witness @Rank.as.Copy.impl.%Copy.impl_witness_table [concrete]
// CHECK:STDOUT:   %pattern_type.9ac: type = pattern_type %Rank [concrete]
// CHECK:STDOUT:   %struct_type.v: type = struct_type {.v: %i32} [concrete]
// CHECK:STDOUT:   %OrderedWith.type.ad8: type = generic_interface_type @OrderedWith [concrete]
// CHECK:STDOUT:   %OrderedWith.generic: %OrderedWith.type.ad8 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.831: type = pattern_type bool [concrete]
// CHECK:STDOUT:   %return.param_patt.5a1: %pattern_type.831 = out_param_pattern [concrete]
// CHECK:STDOUT:   %.f34: Core.Form = init_form bool [concrete]
// CHECK:STDOUT:   %OrderedWith.impl_witness.a72: <witness> = impl_witness @Rank.as.OrderedWith.impl.%OrderedWith.impl_witness_table [concrete]
// CHECK:STDOUT:   %return.patt.c0c: %pattern_type.831 = return_slot_pattern %return.param_patt.5a1, bool [concrete]
// CHECK:STDOUT:   %Optional.type: type = generic_class_type @Optional [concrete]
// CHECK:STDOUT:   %Optional.generic: %Optional.type = struct_value () [concrete]
// CHECK:STDOUT:   %OptionalStorage.type: type = facet_type <@OptionalStorage> [concrete]
// CHECK:STDOUT:   %Destroy.type: type = facet_type <@Destroy> [concrete]
// CHECK:STDOUT:   %facet_type.a1a: type = facet_type <@Copy & @Destroy> [concrete]
// CHECK:STDOUT:   %T.dc4: %facet_type.a1a = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %DefaultOptionalStorage.5e0: type = class_type @DefaultOptionalStorage, @DefaultOptionalStorage(%T.dc4) [symbolic]
// CHECK:STDOUT:   %T.as_type.as.OptionalStorage.impl.Get.type.7fb: type = fn_type @T.as_type.as.OptionalStorage.impl.Get, @T.as_type.as.OptionalStorage.impl(%T.dc4) [symbolic]
// CHECK:STDOUT:   %T.as_type.as.OptionalStorage.impl.Get.a96: %T.as_type.as.OptionalStorage.impl.Get.type.7fb = struct_value () [symbolic]
// CHECK:STDOUT:   %T.as_type.as.OptionalStorage.impl.Has.type.62c: type = fn_type @T.as_type.as.OptionalStorage.impl.Has, @T.as_type.as.OptionalStorage.impl(%T.dc4) [symbolic]
// CHECK:STDOUT:   %T.as_type.as.OptionalStorage.impl.Has.7e4: %T.as_type.as.OptionalStorage.impl.Has.type.62c = struct_value () [symbolic]
// CHECK:STDOUT:   %Destroy.lookup_impl_witness.597: <witness> = lookup_impl_witness %DefaultOptionalStorage.5e0, @Destroy [symbolic]
// CHECK:STDOUT:   %Destroy.facet.0de: %Destroy.type = facet_value %DefaultOptionalStorage.5e0, (%Destroy.lookup_impl_witness.597) [symbolic]
// CHECK:STDOUT:   %self.param_patt.705: %pattern_type.6b6 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.70d: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt.705 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc21_34.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.1: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.1: type = fn_type @Destroy.WithSelf.Op.loc21_34.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.1: %Destroy.WithSelf.Op.type.ef016f.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.1: type = fn_type @Destroy.WithSelf.SelfDestruct.loc21_34.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.1: %Destroy.WithSelf.SelfDestruct.type.fbceb5.1 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.25f: type = pattern_type %struct_type.v [concrete]
// CHECK:STDOUT:   %self.param_patt.f4d: %pattern_type.25f = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.326: %pattern_type.25f = wrapper_binding_pattern self, %self.param_patt.f4d [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc21_34.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.2: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.2: type = fn_type @Destroy.WithSelf.Op.loc21_34.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.2: %Destroy.WithSelf.Op.type.ef016f.2 = struct_value () [concrete]
// CHECK:STDOUT:   %self.param_patt.3c9: %pattern_type.9ac = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.de1: %pattern_type.9ac = wrapper_binding_pattern self, %self.param_patt.3c9 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc21_34.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.3: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.3: type = fn_type @Destroy.WithSelf.Op.loc21_34.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.3: %Destroy.WithSelf.Op.type.ef016f.3 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.3: type = fn_type @Destroy.WithSelf.SelfDestruct.loc21_34.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.3: %Destroy.WithSelf.SelfDestruct.type.fbceb5.3 = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.f8f19d.3: <witness> = custom_witness (%Destroy.WithSelf.Op.403171.3, %Destroy.WithSelf.SubobjectDestroy.d01daf.3, %Destroy.WithSelf.SelfDestruct.db3fdb.3), @Destroy [concrete]
// CHECK:STDOUT:   %facet_value.365: %facet_type.a1a = facet_value %Rank, (%Copy.impl_witness.d00, %custom_witness.f8f19d.3) [concrete]
// CHECK:STDOUT:   %OptionalStorage.impl_witness.809: <witness> = impl_witness imports.%OptionalStorage.impl_witness_table.0d6, @T.as_type.as.OptionalStorage.impl(%facet_value.365) [concrete]
// CHECK:STDOUT:   %OptionalStorage.facet.c56: %OptionalStorage.type = facet_value %Rank, (%OptionalStorage.impl_witness.809) [concrete]
// CHECK:STDOUT:   %Optional.fd5: type = class_type @Optional, @Optional(%OptionalStorage.facet.c56) [concrete]
// CHECK:STDOUT:   %pattern_type.802: type = pattern_type %Optional.fd5 [concrete]
// CHECK:STDOUT:   %a.param_patt: %pattern_type.802 = value_param_pattern [concrete]
// CHECK:STDOUT:   %a.patt: %pattern_type.802 = wrapper_binding_pattern a, %a.param_patt [concrete]
// CHECK:STDOUT:   %b.param_patt: %pattern_type.802 = value_param_pattern [concrete]
// CHECK:STDOUT:   %b.patt: %pattern_type.802 = wrapper_binding_pattern b, %b.param_patt [concrete]
// CHECK:STDOUT:   %RankLess.type: type = fn_type @RankLess [concrete]
// CHECK:STDOUT:   %RankLess: %RankLess.type = struct_value () [concrete]
// CHECK:STDOUT:   %OrderedWith.type.02e: type = facet_type <@OrderedWith, @OrderedWith(%Optional.fd5)> [concrete]
// CHECK:STDOUT:   %facet_type.a0b: type = facet_type <@OptionalStorage & @Destroy & @Ordered> [concrete]
// CHECK:STDOUT:   %T.203: %facet_type.a0b = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %Optional.as.OrderedWith.impl.Less.type.5d9: type = fn_type @Optional.as.OrderedWith.impl.Less, @Optional.as.OrderedWith.impl(%T.203) [symbolic]
// CHECK:STDOUT:   %Optional.as.OrderedWith.impl.Less.036: %Optional.as.OrderedWith.impl.Less.type.5d9 = struct_value () [symbolic]
// CHECK:STDOUT:   %facet_value.7b8: %facet_type.a0b = facet_value %Rank, (%OrderedWith.impl_witness.a72, %OptionalStorage.impl_witness.809, %custom_witness.f8f19d.3) [concrete]
// CHECK:STDOUT:   %OrderedWith.impl_witness.74a: <witness> = impl_witness imports.%OrderedWith.impl_witness_table.98f, @Optional.as.OrderedWith.impl(%facet_value.7b8) [concrete]
// CHECK:STDOUT:   %Optional.as.OrderedWith.impl.Less.type.fcb: type = fn_type @Optional.as.OrderedWith.impl.Less, @Optional.as.OrderedWith.impl(%facet_value.7b8) [concrete]
// CHECK:STDOUT:   %Optional.as.OrderedWith.impl.Less.d49: %Optional.as.OrderedWith.impl.Less.type.fcb = struct_value () [concrete]
// CHECK:STDOUT:   %OrderedWith.facet.02a: %OrderedWith.type.02e = facet_value %Optional.fd5, (%OrderedWith.impl_witness.74a) [concrete]
// CHECK:STDOUT:   %OrderedWith.WithSelf.Less.type.35e: type = fn_type @OrderedWith.WithSelf.Less, @OrderedWith.WithSelf(%Optional.fd5, %OrderedWith.facet.02a) [concrete]
// CHECK:STDOUT:   %.f6e: type = fn_type_with_self_type %OrderedWith.WithSelf.Less.type.35e, %OrderedWith.facet.02a [concrete]
// CHECK:STDOUT:   %Optional.as.OrderedWith.impl.Less.specific_fn: <specific function> = specific_function %Optional.as.OrderedWith.impl.Less.d49, @Optional.as.OrderedWith.impl.Less(%facet_value.7b8) [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .Int = %Core.Int
// CHECK:STDOUT:     .Copy = %Core.Copy.e5d
// CHECK:STDOUT:     .OrderedWith = %Core.OrderedWith
// CHECK:STDOUT:     .Bool = %Core.Bool
// CHECK:STDOUT:     .Optional = %Core.Optional
// CHECK:STDOUT:     .Destroy = %Core.Destroy
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Int: %Int.type = import_ref Core//prelude/types/int, Int, loaded [concrete = constants.%Int.generic]
// CHECK:STDOUT:   %Core.Copy.e5d: type = import_ref Core//prelude/copy, Copy, loaded [concrete = constants.%Copy.type]
// CHECK:STDOUT:   %Core.OrderedWith: %OrderedWith.type.ad8 = import_ref Core//prelude/operators/comparison, OrderedWith, loaded [concrete = constants.%OrderedWith.generic]
// CHECK:STDOUT:   %Core.Bool: type = import_ref Core//prelude/types/bool, Bool, loaded [concrete = bool]
// CHECK:STDOUT:   %Core.Optional: %Optional.type = import_ref Core//prelude/types/optional, Optional, loaded [concrete = constants.%Optional.generic]
// CHECK:STDOUT:   %Core.import_ref.f38: %Destroy.type = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @T.as_type.as.OptionalStorage.impl.%Destroy.facet (constants.%Destroy.facet.0de)]
// CHECK:STDOUT:   %Core.import_ref.f71 = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.f5a = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.e5aa: @T.as_type.as.OptionalStorage.impl.%T.as_type.as.OptionalStorage.impl.Has.type (%T.as_type.as.OptionalStorage.impl.Has.type.62c) = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @T.as_type.as.OptionalStorage.impl.%T.as_type.as.OptionalStorage.impl.Has (constants.%T.as_type.as.OptionalStorage.impl.Has.7e4)]
// CHECK:STDOUT:   %Core.import_ref.9d5: @T.as_type.as.OptionalStorage.impl.%T.as_type.as.OptionalStorage.impl.Get.type (%T.as_type.as.OptionalStorage.impl.Get.type.7fb) = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @T.as_type.as.OptionalStorage.impl.%T.as_type.as.OptionalStorage.impl.Get (constants.%T.as_type.as.OptionalStorage.impl.Get.a96)]
// CHECK:STDOUT:   %Core.import_ref.007 = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %OptionalStorage.impl_witness_table.0d6 = impl_witness_table (%Core.import_ref.f38, %Core.import_ref.f71, %Core.import_ref.f5a, %Core.import_ref.e5aa, %Core.import_ref.9d5, %Core.import_ref.007), @T.as_type.as.OptionalStorage.impl [concrete]
// CHECK:STDOUT:   %Core.Destroy: type = import_ref Core//prelude/destroy, Destroy, loaded [concrete = constants.%Destroy.type]
// CHECK:STDOUT:   %Core.import_ref.174: @Optional.as.OrderedWith.impl.%Optional.as.OrderedWith.impl.Less.type (%Optional.as.OrderedWith.impl.Less.type.5d9) = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @Optional.as.OrderedWith.impl.%Optional.as.OrderedWith.impl.Less (constants.%Optional.as.OrderedWith.impl.Less.036)]
// CHECK:STDOUT:   %Core.import_ref.808 = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.536 = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.175 = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %OrderedWith.impl_witness_table.98f = impl_witness_table (%Core.import_ref.174, %Core.import_ref.808, %Core.import_ref.536, %Core.import_ref.175), @Optional.as.OrderedWith.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.1: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc21_34.1 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.1] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6b6 = ref_param_pattern [concrete = constants.%self.param_patt.705]
// CHECK:STDOUT:     %self.patt: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.70d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i32 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i32 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.1: %Destroy.WithSelf.Op.type.ef016f.1 = fn_decl @Destroy.WithSelf.Op.loc21_34.1 [concrete = constants.%Destroy.WithSelf.Op.403171.1] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6b6 = ref_param_pattern [concrete = constants.%self.param_patt.705]
// CHECK:STDOUT:     %self.patt: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.70d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i32 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i32 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.2: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc21_34.2 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.2] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.25f = ref_param_pattern [concrete = constants.%self.param_patt.f4d]
// CHECK:STDOUT:     %self.patt: %pattern_type.25f = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.326]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %struct_type.v = ref_param call_param0
// CHECK:STDOUT:     %self: ref %struct_type.v = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.2: %Destroy.WithSelf.Op.type.ef016f.2 = fn_decl @Destroy.WithSelf.Op.loc21_34.2 [concrete = constants.%Destroy.WithSelf.Op.403171.2] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.25f = ref_param_pattern [concrete = constants.%self.param_patt.f4d]
// CHECK:STDOUT:     %self.patt: %pattern_type.25f = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.326]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %struct_type.v = ref_param call_param0
// CHECK:STDOUT:     %self: ref %struct_type.v = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.3: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc21_34.3 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.3] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.9ac = ref_param_pattern [concrete = constants.%self.param_patt.3c9]
// CHECK:STDOUT:     %self.patt: %pattern_type.9ac = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.de1]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %Rank = ref_param call_param0
// CHECK:STDOUT:     %self: ref %Rank = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.3: %Destroy.WithSelf.Op.type.ef016f.3 = fn_decl @Destroy.WithSelf.Op.loc21_34.3 [concrete = constants.%Destroy.WithSelf.Op.403171.3] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.9ac = ref_param_pattern [concrete = constants.%self.param_patt.3c9]
// CHECK:STDOUT:     %self.patt: %pattern_type.9ac = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.de1]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %Rank = ref_param call_param0
// CHECK:STDOUT:     %self: ref %Rank = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %RankLess.decl: %RankLess.type = fn_decl @RankLess [concrete = constants.%RankLess] {
// CHECK:STDOUT:     %a.param_patt: %pattern_type.802 = value_param_pattern [concrete = constants.%a.param_patt]
// CHECK:STDOUT:     %a.patt: %pattern_type.802 = wrapper_binding_pattern a, %a.param_patt [concrete = constants.%a.patt]
// CHECK:STDOUT:     %b.param_patt: %pattern_type.802 = value_param_pattern [concrete = constants.%b.param_patt]
// CHECK:STDOUT:     %b.patt: %pattern_type.802 = wrapper_binding_pattern b, %b.param_patt [concrete = constants.%b.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.831 = out_param_pattern [concrete = constants.%return.param_patt.5a1]
// CHECK:STDOUT:     %return.patt: %pattern_type.831 = return_slot_pattern %return.param_patt, %.loc21_64.1 [concrete = constants.%return.patt.c0c]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc21_64.1: type = type_literal bool [concrete = bool]
// CHECK:STDOUT:     %.loc21_64.2: Core.Form = init_form %.loc21_64.1 [concrete = constants.%.f34]
// CHECK:STDOUT:     %a.param: %Optional.fd5 = value_param call_param0
// CHECK:STDOUT:     %.loc21_34.1: type = splice_block %Optional.loc21_34 [concrete = constants.%Optional.fd5] {
// CHECK:STDOUT:       %Core.ref.loc21_16: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %Optional.ref.loc21_20: %Optional.type = name_ref Optional, imports.%Core.Optional [concrete = constants.%Optional.generic]
// CHECK:STDOUT:       %Rank.ref.loc21_30: type = name_ref Rank, file.%Rank.decl [concrete = constants.%Rank]
// CHECK:STDOUT:       %OptionalStorage.facet.loc21_34: %OptionalStorage.type = facet_value %Rank.ref.loc21_30, (constants.%OptionalStorage.impl_witness.809) [concrete = constants.%OptionalStorage.facet.c56]
// CHECK:STDOUT:       %.loc21_34.2: %OptionalStorage.type = converted %Rank.ref.loc21_30, %OptionalStorage.facet.loc21_34 [concrete = constants.%OptionalStorage.facet.c56]
// CHECK:STDOUT:       %Optional.loc21_34: type = class_type @Optional, @Optional(constants.%OptionalStorage.facet.c56) [concrete = constants.%Optional.fd5]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %a: %Optional.fd5 = wrapper_binding a, %a.param
// CHECK:STDOUT:     %b.param: %Optional.fd5 = value_param call_param1
// CHECK:STDOUT:     %.loc21_58.1: type = splice_block %Optional.loc21_58 [concrete = constants.%Optional.fd5] {
// CHECK:STDOUT:       %Core.ref.loc21_40: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %Optional.ref.loc21_44: %Optional.type = name_ref Optional, imports.%Core.Optional [concrete = constants.%Optional.generic]
// CHECK:STDOUT:       %Rank.ref.loc21_54: type = name_ref Rank, file.%Rank.decl [concrete = constants.%Rank]
// CHECK:STDOUT:       %OptionalStorage.facet.loc21_58: %OptionalStorage.type = facet_value %Rank.ref.loc21_54, (constants.%OptionalStorage.impl_witness.809) [concrete = constants.%OptionalStorage.facet.c56]
// CHECK:STDOUT:       %.loc21_58.2: %OptionalStorage.type = converted %Rank.ref.loc21_54, %OptionalStorage.facet.loc21_58 [concrete = constants.%OptionalStorage.facet.c56]
// CHECK:STDOUT:       %Optional.loc21_58: type = class_type @Optional, @Optional(constants.%OptionalStorage.facet.c56) [concrete = constants.%Optional.fd5]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %b: %Optional.fd5 = wrapper_binding b, %b.param
// CHECK:STDOUT:     %return.param: ref bool = out_param call_param2
// CHECK:STDOUT:     %return: ref bool = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc21_34.1(%self.param: ref %i32) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc21_34.1(%self.param: ref %i32) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc21_34.1(%self.param: ref %i32) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.1(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.1(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc21_34.2(%self.param: ref %struct_type.v) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %.loc21: ref %i32 = struct_access %self.param, element0
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound: <bound method> = bound_method %.loc21, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound(%.loc21)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc21_34.2(%self.param: ref %struct_type.v) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc21_34.2(%self.param: ref %struct_type.v) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.2(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.2(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc21_34.3(%self.param: ref %Rank) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %v.ref: %Rank.elem = name_ref v, @Rank.%field_decl [concrete = @Rank.%field_decl]
// CHECK:STDOUT:   %.loc21: ref %i32 = class_element_access %self.param, element0
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound: <bound method> = bound_method %.loc21, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound(%.loc21)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc21_34.3(%self.param: ref %Rank) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc21_34.3(%self.param: ref %Rank) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.3(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.3(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @RankLess(%a.param: %Optional.fd5, %b.param: %Optional.fd5) -> out %return.param: bool {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %a.ref: %Optional.fd5 = name_ref a, %a
// CHECK:STDOUT:   %b.ref: %Optional.fd5 = name_ref b, %b
// CHECK:STDOUT:   %impl.elem0: %.f6e = impl_witness_access constants.%OrderedWith.impl_witness.74a, element0 [concrete = constants.%Optional.as.OrderedWith.impl.Less.d49]
// CHECK:STDOUT:   %bound_method.loc22_12.1: <bound method> = bound_method %a.ref, %impl.elem0
// CHECK:STDOUT:   %facet_value.loc22_12.1: %facet_type.a0b = facet_value constants.%Rank, (constants.%OrderedWith.impl_witness.a72, constants.%OptionalStorage.impl_witness.809, constants.%custom_witness.f8f19d.3) [concrete = constants.%facet_value.7b8]
// CHECK:STDOUT:   %.loc22_12.1: %facet_type.a0b = converted constants.%Rank, %facet_value.loc22_12.1 [concrete = constants.%facet_value.7b8]
// CHECK:STDOUT:   %facet_value.loc22_12.2: %facet_type.a0b = facet_value constants.%Rank, (constants.%OrderedWith.impl_witness.a72, constants.%OptionalStorage.impl_witness.809, constants.%custom_witness.f8f19d.3) [concrete = constants.%facet_value.7b8]
// CHECK:STDOUT:   %.loc22_12.2: %facet_type.a0b = converted constants.%Rank, %facet_value.loc22_12.2 [concrete = constants.%facet_value.7b8]
// CHECK:STDOUT:   %facet_value.loc22_12.3: %facet_type.a0b = facet_value constants.%Rank, (constants.%OrderedWith.impl_witness.a72, constants.%OptionalStorage.impl_witness.809, constants.%custom_witness.f8f19d.3) [concrete = constants.%facet_value.7b8]
// CHECK:STDOUT:   %.loc22_12.3: %facet_type.a0b = converted constants.%Rank, %facet_value.loc22_12.3 [concrete = constants.%facet_value.7b8]
// CHECK:STDOUT:   %facet_value.loc22_12.4: %facet_type.a0b = facet_value constants.%Rank, (constants.%OrderedWith.impl_witness.a72, constants.%OptionalStorage.impl_witness.809, constants.%custom_witness.f8f19d.3) [concrete = constants.%facet_value.7b8]
// CHECK:STDOUT:   %.loc22_12.4: %facet_type.a0b = converted constants.%Rank, %facet_value.loc22_12.4 [concrete = constants.%facet_value.7b8]
// CHECK:STDOUT:   %specific_fn: <specific function> = specific_function %impl.elem0, @Optional.as.OrderedWith.impl.Less(constants.%facet_value.7b8) [concrete = constants.%Optional.as.OrderedWith.impl.Less.specific_fn]
// CHECK:STDOUT:   %bound_method.loc22_12.2: <bound method> = bound_method %a.ref, %specific_fn
// CHECK:STDOUT:   %Optional.as.OrderedWith.impl.Less.call: init bool = call %bound_method.loc22_12.2(%a.ref, %b.ref)
// CHECK:STDOUT:   return %Optional.as.OrderedWith.impl.Less.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- user_pointer.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %C: type = class_type @C [concrete]
// CHECK:STDOUT:   %Int.type: type = generic_class_type @Int [concrete]
// CHECK:STDOUT:   %Int.generic: %Int.type = struct_value () [concrete]
// CHECK:STDOUT:   %ptr.6b6: type = ptr_type %C [concrete]
// CHECK:STDOUT:   %EqWith.type.f77: type = generic_interface_type @EqWith [concrete]
// CHECK:STDOUT:   %EqWith.generic: %EqWith.type.f77 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.831: type = pattern_type bool [concrete]
// CHECK:STDOUT:   %return.param_patt.5a1: %pattern_type.831 = out_param_pattern [concrete]
// CHECK:STDOUT:   %.f34: Core.Form = init_form bool [concrete]
// CHECK:STDOUT:   %EqWith.impl_witness.8c5: <witness> = impl_witness @ptr.as.EqWith.impl.%EqWith.impl_witness_table [concrete]
// CHECK:STDOUT:   %return.patt.c0c: %pattern_type.831 = return_slot_pattern %return.param_patt.5a1, bool [concrete]
// CHECK:STDOUT:   %Optional.type: type = generic_class_type @Optional [concrete]
// CHECK:STDOUT:   %Optional.generic: %Optional.type = struct_value () [concrete]
// CHECK:STDOUT:   %OptionalStorage.type: type = facet_type <@OptionalStorage> [concrete]
// CHECK:STDOUT:   %Destroy.type: type = facet_type <@Destroy> [concrete]
// CHECK:STDOUT:   %T.67d: type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %ptr.e8f: type = ptr_type %T.67d [symbolic]
// CHECK:STDOUT:   %Destroy.lookup_impl_witness.781: <witness> = lookup_impl_witness %ptr.e8f, @Destroy [symbolic]
// CHECK:STDOUT:   %Destroy.facet.e46: %Destroy.type = facet_value %ptr.e8f, (%Destroy.lookup_impl_witness.781) [symbolic]
// CHECK:STDOUT:   %MaybeUnformed.ddb: type = class_type @MaybeUnformed, @MaybeUnformed(%Destroy.facet.e46) [symbolic]
// CHECK:STDOUT:   %ptr.as.OptionalStorage.impl.Get.type.015: type = fn_type @ptr.as.OptionalStorage.impl.Get, @ptr.as.OptionalStorage.impl(%T.67d) [symbolic]
// CHECK:STDOUT:   %ptr.as.OptionalStorage.impl.Get.972: %ptr.as.OptionalStorage.impl.Get.type.015 = struct_value () [symbolic]
// CHECK:STDOUT:   %ptr.as.OptionalStorage.impl.Has.type.0e1: type = fn_type @ptr.as.OptionalStorage.impl.Has, @ptr.as.OptionalStorage.impl(%T.67d) [symbolic]
// CHECK:STDOUT:   %ptr.as.OptionalStorage.impl.Has.05c: %ptr.as.OptionalStorage.impl.Has.type.0e1 = struct_value () [symbolic]
// CHECK:STDOUT:   %Destroy.lookup_impl_witness.ad0: <witness> = lookup_impl_witness %MaybeUnformed.ddb, @Destroy [symbolic]
// CHECK:STDOUT:   %Destroy.facet.270: %Destroy.type = facet_value %MaybeUnformed.ddb, (%Destroy.lookup_impl_witness.ad0) [symbolic]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1: type = fn_type @Destroy.WithSelf.SubobjectDestroy.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.1: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.1: type = fn_type @Destroy.WithSelf.Op.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.1: %Destroy.WithSelf.Op.type.ef016f.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.1: type = fn_type @Destroy.WithSelf.SelfDestruct.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.1: %Destroy.WithSelf.SelfDestruct.type.fbceb5.1 = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.f8f19d.1: <witness> = custom_witness (%Destroy.WithSelf.Op.403171.1, %Destroy.WithSelf.SubobjectDestroy.d01daf.1, %Destroy.WithSelf.SelfDestruct.db3fdb.1), @Destroy [concrete]
// CHECK:STDOUT:   %OptionalStorage.impl_witness.2e9: <witness> = impl_witness imports.%OptionalStorage.impl_witness_table.110, @ptr.as.OptionalStorage.impl(%C) [concrete]
// CHECK:STDOUT:   %OptionalStorage.facet.58b: %OptionalStorage.type = facet_value %ptr.6b6, (%OptionalStorage.impl_witness.2e9) [concrete]
// CHECK:STDOUT:   %Optional.bce: type = class_type @Optional, @Optional(%OptionalStorage.facet.58b) [concrete]
// CHECK:STDOUT:   %pattern_type.fe8: type = pattern_type %Optional.bce [concrete]
// CHECK:STDOUT:   %a.param_patt: %pattern_type.fe8 = value_param_pattern [concrete]
// CHECK:STDOUT:   %a.patt: %pattern_type.fe8 = wrapper_binding_pattern a, %a.param_patt [concrete]
// CHECK:STDOUT:   %b.param_patt: %pattern_type.fe8 = value_param_pattern [concrete]
// CHECK:STDOUT:   %b.patt: %pattern_type.fe8 = wrapper_binding_pattern b, %b.param_patt [concrete]
// CHECK:STDOUT:   %SameC.type: type = fn_type @SameC [concrete]
// CHECK:STDOUT:   %SameC: %SameC.type = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.type.5ea: type = facet_type <@EqWith, @EqWith(%Optional.bce)> [concrete]
// CHECK:STDOUT:   %facet_type.a0b: type = facet_type <@OptionalStorage & @Destroy & @Eq> [concrete]
// CHECK:STDOUT:   %T.203: %facet_type.a0b = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %Optional.as.EqWith.impl.Equal.type.ab4: type = fn_type @Optional.as.EqWith.impl.Equal, @Optional.as.EqWith.impl(%T.203) [symbolic]
// CHECK:STDOUT:   %Optional.as.EqWith.impl.Equal.455: %Optional.as.EqWith.impl.Equal.type.ab4 = struct_value () [symbolic]
// CHECK:STDOUT:   %facet_value: %facet_type.a0b = facet_value %ptr.6b6, (%EqWith.impl_witness.8c5, %OptionalStorage.impl_witness.2e9, %custom_witness.f8f19d.1) [concrete]
// CHECK:STDOUT:   %EqWith.impl_witness.c89: <witness> = impl_witness imports.%EqWith.impl_witness_table.3e4, @Optional.as.EqWith.impl(%facet_value) [concrete]
// CHECK:STDOUT:   %Optional.as.EqWith.impl.Equal.type.49e: type = fn_type @Optional.as.EqWith.impl.Equal, @Optional.as.EqWith.impl(%facet_value) [concrete]
// CHECK:STDOUT:   %Optional.as.EqWith.impl.Equal.e8b: %Optional.as.EqWith.impl.Equal.type.49e = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.310: %EqWith.type.5ea = facet_value %Optional.bce, (%EqWith.impl_witness.c89) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.9de: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%Optional.bce, %EqWith.facet.310) [concrete]
// CHECK:STDOUT:   %.34d: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.9de, %EqWith.facet.310 [concrete]
// CHECK:STDOUT:   %Optional.as.EqWith.impl.Equal.specific_fn: <specific function> = specific_function %Optional.as.EqWith.impl.Equal.e8b, @Optional.as.EqWith.impl.Equal(%facet_value) [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .Int = %Core.Int
// CHECK:STDOUT:     .EqWith = %Core.EqWith
// CHECK:STDOUT:     .Bool = %Core.Bool
// CHECK:STDOUT:     .Optional = %Core.Optional
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Int: %Int.type = import_ref Core//prelude/types/int, Int, loaded [concrete = constants.%Int.generic]
// CHECK:STDOUT:   %Core.EqWith: %EqWith.type.f77 = import_ref Core//prelude/operators/comparison, EqWith, loaded [concrete = constants.%EqWith.generic]
// CHECK:STDOUT:   %Core.Bool: type = import_ref Core//prelude/types/bool, Bool, loaded [concrete = bool]
// CHECK:STDOUT:   %Core.Optional: %Optional.type = import_ref Core//prelude/types/optional, Optional, loaded [concrete = constants.%Optional.generic]
// CHECK:STDOUT:   %Core.import_ref.809: %Destroy.type = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @ptr.as.OptionalStorage.impl.%Destroy.facet.2 (constants.%Destroy.facet.270)]
// CHECK:STDOUT:   %Core.import_ref.105 = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.c9a = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.575: @ptr.as.OptionalStorage.impl.%ptr.as.OptionalStorage.impl.Has.type (%ptr.as.OptionalStorage.impl.Has.type.0e1) = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @ptr.as.OptionalStorage.impl.%ptr.as.OptionalStorage.impl.Has (constants.%ptr.as.OptionalStorage.impl.Has.05c)]
// CHECK:STDOUT:   %Core.import_ref.008: @ptr.as.OptionalStorage.impl.%ptr.as.OptionalStorage.impl.Get.type (%ptr.as.OptionalStorage.impl.Get.type.015) = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @ptr.as.OptionalStorage.impl.%ptr.as.OptionalStorage.impl.Get (constants.%ptr.as.OptionalStorage.impl.Get.972)]
// CHECK:STDOUT:   %Core.import_ref.3e3 = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %OptionalStorage.impl_witness_table.110 = impl_witness_table (%Core.import_ref.809, %Core.import_ref.105, %Core.import_ref.c9a, %Core.import_ref.575, %Core.import_ref.008, %Core.import_ref.3e3), @ptr.as.OptionalStorage.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.c4b: @Optional.as.EqWith.impl.%Optional.as.EqWith.impl.Equal.type (%Optional.as.EqWith.impl.Equal.type.ab4) = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @Optional.as.EqWith.impl.%Optional.as.EqWith.impl.Equal (constants.%Optional.as.EqWith.impl.Equal.455)]
// CHECK:STDOUT:   %Core.import_ref.06a = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.3e4 = impl_witness_table (%Core.import_ref.c4b, %Core.import_ref.06a), @Optional.as.EqWith.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %SameC.decl: %SameC.type = fn_decl @SameC [concrete = constants.%SameC] {
// CHECK:STDOUT:     %a.param_patt: %pattern_type.fe8 = value_param_pattern [concrete = constants.%a.param_patt]
// CHECK:STDOUT:     %a.patt: %pattern_type.fe8 = wrapper_binding_pattern a, %a.param_patt [concrete = constants.%a.patt]
// CHECK:STDOUT:     %b.param_patt: %pattern_type.fe8 = value_param_pattern [concrete = constants.%b.param_patt]
// CHECK:STDOUT:     %b.patt: %pattern_type.fe8 = wrapper_binding_pattern b, %b.param_patt [concrete = constants.%b.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.831 = out_param_pattern [concrete = constants.%return.param_patt.5a1]
// CHECK:STDOUT:     %return.patt: %pattern_type.831 = return_slot_pattern %return.param_patt, %.loc16_57.1 [concrete = constants.%return.patt.c0c]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc16_57.1: type = type_literal bool [concrete = bool]
// CHECK:STDOUT:     %.loc16_57.2: Core.Form = init_form %.loc16_57.1 [concrete = constants.%.f34]
// CHECK:STDOUT:     %a.param: %Optional.bce = value_param call_param0
// CHECK:STDOUT:     %.loc16_29.1: type = splice_block %Optional.loc16_29 [concrete = constants.%Optional.bce] {
// CHECK:STDOUT:       %Core.ref.loc16_13: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %Optional.ref.loc16_17: %Optional.type = name_ref Optional, imports.%Core.Optional [concrete = constants.%Optional.generic]
// CHECK:STDOUT:       %C.ref.loc16_27: type = name_ref C, file.%C.decl [concrete = constants.%C]
// CHECK:STDOUT:       %ptr.loc16_28: type = ptr_type %C.ref.loc16_27 [concrete = constants.%ptr.6b6]
// CHECK:STDOUT:       %OptionalStorage.facet.loc16_29: %OptionalStorage.type = facet_value %ptr.loc16_28, (constants.%OptionalStorage.impl_witness.2e9) [concrete = constants.%OptionalStorage.facet.58b]
// CHECK:STDOUT:       %.loc16_29.2: %OptionalStorage.type = converted %ptr.loc16_28, %OptionalStorage.facet.loc16_29 [concrete = constants.%OptionalStorage.facet.58b]
// CHECK:STDOUT:       %Optional.loc16_29: type = class_type @Optional, @Optional(constants.%OptionalStorage.facet.58b) [concrete = constants.%Optional.bce]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %a: %Optional.bce = wrapper_binding a, %a.param
// CHECK:STDOUT:     %b.param: %Optional.bce = value_param call_param1
// CHECK:STDOUT:     %.loc16_51.1: type = splice_block %Optional.loc16_51 [concrete = constants.%Optional.bce] {
// CHECK:STDOUT:       %Core.ref.loc16_35: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %Optional.ref.loc16_39: %Optional.type = name_ref Optional, imports.%Core.Optional [concrete = constants.%Optional.generic]
// CHECK:STDOUT:       %C.ref.loc16_49: type = name_ref C, file.%C.decl [concrete = constants.%C]
// CHECK:STDOUT:       %ptr.loc16_50: type = ptr_type %C.ref.loc16_49 [concrete = constants.%ptr.6b6]
// CHECK:STDOUT:       %OptionalStorage.facet.loc16_51: %OptionalStorage.type = facet_value %ptr.loc16_50, (constants.%OptionalStorage.impl_witness.2e9) [concrete = constants.%OptionalStorage.facet.58b]
// CHECK:STDOUT:       %.loc16_51.2: %OptionalStorage.type = converted %ptr.loc16_50, %OptionalStorage.facet.loc16_51 [concrete = constants.%OptionalStorage.facet.58b]
// CHECK:STDOUT:       %Optional.loc16_51: type = class_type @Optional, @Optional(constants.%OptionalStorage.facet.58b) [concrete = constants.%Optional.bce]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %b: %Optional.bce = wrapper_binding b, %b.param
// CHECK:STDOUT:     %return.param: ref bool = out_param call_param2
// CHECK:STDOUT:     %return: ref bool = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @SameC(%a.param: %Optional.bce, %b.param: %Optional.bce) -> out %return.param: bool {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %a.ref: %Optional.bce = name_ref a, %a
// CHECK:STDOUT:   %b.ref: %Optional.bce = name_ref b, %b
// CHECK:STDOUT:   %impl.elem0: %.34d = impl_witness_access constants.%EqWith.impl_witness.c89, element0 [concrete = constants.%Optional.as.EqWith.impl.Equal.e8b]
// CHECK:STDOUT:   %bound_method.loc17_12.1: <bound method> = bound_method %a.ref, %impl.elem0
// CHECK:STDOUT:   %facet_value.loc17_12.1: %facet_type.a0b = facet_value constants.%ptr.6b6, (constants.%EqWith.impl_witness.8c5, constants.%OptionalStorage.impl_witness.2e9, constants.%custom_witness.f8f19d.1) [concrete = constants.%facet_value]
// CHECK:STDOUT:   %.loc17_12.1: %facet_type.a0b = converted constants.%ptr.6b6, %facet_value.loc17_12.1 [concrete = constants.%facet_value]
// CHECK:STDOUT:   %facet_value.loc17_12.2: %facet_type.a0b = facet_value constants.%ptr.6b6, (constants.%EqWith.impl_witness.8c5, constants.%OptionalStorage.impl_witness.2e9, constants.%custom_witness.f8f19d.1) [concrete = constants.%facet_value]
// CHECK:STDOUT:   %.loc17_12.2: %facet_type.a0b = converted constants.%ptr.6b6, %facet_value.loc17_12.2 [concrete = constants.%facet_value]
// CHECK:STDOUT:   %facet_value.loc17_12.3: %facet_type.a0b = facet_value constants.%ptr.6b6, (constants.%EqWith.impl_witness.8c5, constants.%OptionalStorage.impl_witness.2e9, constants.%custom_witness.f8f19d.1) [concrete = constants.%facet_value]
// CHECK:STDOUT:   %.loc17_12.3: %facet_type.a0b = converted constants.%ptr.6b6, %facet_value.loc17_12.3 [concrete = constants.%facet_value]
// CHECK:STDOUT:   %facet_value.loc17_12.4: %facet_type.a0b = facet_value constants.%ptr.6b6, (constants.%EqWith.impl_witness.8c5, constants.%OptionalStorage.impl_witness.2e9, constants.%custom_witness.f8f19d.1) [concrete = constants.%facet_value]
// CHECK:STDOUT:   %.loc17_12.4: %facet_type.a0b = converted constants.%ptr.6b6, %facet_value.loc17_12.4 [concrete = constants.%facet_value]
// CHECK:STDOUT:   %specific_fn: <specific function> = specific_function %impl.elem0, @Optional.as.EqWith.impl.Equal(constants.%facet_value) [concrete = constants.%Optional.as.EqWith.impl.Equal.specific_fn]
// CHECK:STDOUT:   %bound_method.loc17_12.2: <bound method> = bound_method %a.ref, %specific_fn
// CHECK:STDOUT:   %Optional.as.EqWith.impl.Equal.call: init bool = call %bound_method.loc17_12.2(%a.ref, %b.ref)
// CHECK:STDOUT:   return %Optional.as.EqWith.impl.Equal.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
