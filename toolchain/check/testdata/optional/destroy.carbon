// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/optional/destroy.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/optional/destroy.carbon

// Fork (OP-2, fork/optional2/plan.md §4, W-170): a `Core.Optional(T)` owns the
// value it holds (fork design F-015). The default storage declares a `Destroy`
// that destroys the value when there is one, and the `Optional` adapter is
// destroyed as its storage (fork design F-016); the pointer niche declares
// none, so `Core.Optional(T*)` stays trivially destructible and a union may
// hold one. Only `Core.Optional(T*)` may be declared without an initializer.

// --- concrete.carbon

library "[[@TEST_NAME]]";

class Tracked {
  impl as Core.Copy {
    fn Op(unused self) -> Self { return {}; }
  }
  impl as Core.Destroy {
    fn Op(unused ref self) {}
  }
}

//@dump-sem-ir-begin
fn Hold(t: Tracked) {
  var unused o: Core.Optional(Tracked) = Core.Optional(Tracked).Some(t);
}
//@dump-sem-ir-end

// --- pointer.carbon

library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn HoldPointer(p: i32*) {
  var unused o: Core.Optional(i32*) = Core.Optional(i32*).Some(p);
}
//@dump-sem-ir-end

// --- generic.carbon

library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn HoldGeneric[T: Core.Copy & Core.Destroy](a: T) -> bool {
  let o: Core.Optional(T) = Core.Optional(T).Some(a);
  return o.HasValue();
}
//@dump-sem-ir-end

// --- union_pointer_field.carbon

library "[[@TEST_NAME]]";

union U {
  var o: Core.Optional(i32*);
  var n: i32;
}

// --- fail_union_value_field.carbon

library "[[@TEST_NAME]]";

// `Core.Optional(i32)`'s storage defines a destructor with a non-empty body, so
// it is not `TrivialDestructor` (docs/design/classes.md), and neither is the
// `Optional` adapter of it (fork design F-016): it is not a union field type
// (docs/design/unions.md).
union V {
  // CHECK:STDERR: fail_union_value_field.carbon:[[@LINE+4]]:7: error: union field `o` has type `Core.Optional(i32 as Core.OptionalStorage)`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var o: Core.Optional(i32);
  // CHECK:STDERR:       ^~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  var o: Core.Optional(i32);
  var n: i32;
}

// --- unformed_pointer.carbon

library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn DeclarePointer() {
  var unused o: Core.Optional(i32*);
}
//@dump-sem-ir-end

// --- fail_unformed_value.carbon

library "[[@TEST_NAME]]";

// Only `Core.Optional(T*)` is `UnformedInit`: the default storage's `Destroy`
// reads `has_value`, which an unformed Optional would leave uninitialized, so a
// non-pointer Optional needs an initializer, as a `Core.Buf` does.
fn DeclareValue() {
  // CHECK:STDERR: fail_unformed_value.carbon:[[@LINE+4]]:3: error: cannot convert type `Core.Optional(i32 as Core.OptionalStorage)` into type implementing `Core.DefaultOrUnformed` [ConversionFailureTypeToFacet]
  // CHECK:STDERR:   var unused o: Core.Optional(i32);
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  var unused o: Core.Optional(i32);
}

// CHECK:STDOUT: --- concrete.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %Tracked: type = class_type @Tracked [concrete]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %Copy.impl_witness.d7a: <witness> = impl_witness @Tracked.as.Copy.impl.%Copy.impl_witness_table [concrete]
// CHECK:STDOUT:   %pattern_type.47e: type = pattern_type %Tracked [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %Destroy.type: type = facet_type <@Destroy> [concrete]
// CHECK:STDOUT:   %Destroy.impl_witness.66d: <witness> = impl_witness @Tracked.as.Destroy.impl.%Destroy.impl_witness_table [concrete]
// CHECK:STDOUT:   %t.param_patt: %pattern_type.47e = value_param_pattern [concrete]
// CHECK:STDOUT:   %t.patt: %pattern_type.47e = wrapper_binding_pattern t, %t.param_patt [concrete]
// CHECK:STDOUT:   %Hold.type: type = fn_type @Hold [concrete]
// CHECK:STDOUT:   %Hold: %Hold.type = struct_value () [concrete]
// CHECK:STDOUT:   %Optional.type: type = generic_class_type @Optional [concrete]
// CHECK:STDOUT:   %Optional.generic: %Optional.type = struct_value () [concrete]
// CHECK:STDOUT:   %OptionalStorage.type: type = facet_type <@OptionalStorage> [concrete]
// CHECK:STDOUT:   %T.220: %OptionalStorage.type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %Optional.Some.type.304: type = fn_type @Optional.Some, @Optional(%T.220) [symbolic]
// CHECK:STDOUT:   %Optional.Some.2a0: %Optional.Some.type.304 = struct_value () [symbolic]
// CHECK:STDOUT:   %facet_type: type = facet_type <@Copy & @Destroy> [concrete]
// CHECK:STDOUT:   %T.dc4: %facet_type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %DefaultOptionalStorage.5e0: type = class_type @DefaultOptionalStorage, @DefaultOptionalStorage(%T.dc4) [symbolic]
// CHECK:STDOUT:   %T.as_type.as.OptionalStorage.impl.Some.type.818: type = fn_type @T.as_type.as.OptionalStorage.impl.Some, @T.as_type.as.OptionalStorage.impl(%T.dc4) [symbolic]
// CHECK:STDOUT:   %T.as_type.as.OptionalStorage.impl.Some.620: %T.as_type.as.OptionalStorage.impl.Some.type.818 = struct_value () [symbolic]
// CHECK:STDOUT:   %Destroy.lookup_impl_witness.597: <witness> = lookup_impl_witness %DefaultOptionalStorage.5e0, @Destroy [symbolic]
// CHECK:STDOUT:   %Destroy.facet.0de: %Destroy.type = facet_value %DefaultOptionalStorage.5e0, (%Destroy.lookup_impl_witness.597) [symbolic]
// CHECK:STDOUT:   %facet_value: %facet_type = facet_value %Tracked, (%Copy.impl_witness.d7a, %Destroy.impl_witness.66d) [concrete]
// CHECK:STDOUT:   %DefaultOptionalStorage.44d: type = class_type @DefaultOptionalStorage, @DefaultOptionalStorage(%facet_value) [concrete]
// CHECK:STDOUT:   %Destroy.impl_witness.6db: <witness> = impl_witness imports.%Destroy.impl_witness_table, @DefaultOptionalStorage.as.Destroy.impl(%T.dc4) [symbolic]
// CHECK:STDOUT:   %Destroy.facet.ffd: %Destroy.type = facet_value %DefaultOptionalStorage.5e0, (%Destroy.impl_witness.6db) [symbolic]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.916: type = fn_type @Destroy.WithSelf.SelfDestruct.1, @Destroy.WithSelf(%Destroy.facet.ffd) [symbolic]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.2ee: %Destroy.WithSelf.SelfDestruct.type.916 = struct_value () [symbolic]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.f12: type = fn_type @Destroy.WithSelf.SubobjectDestroy.1, @Destroy.WithSelf(%Destroy.facet.ffd) [symbolic]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.c1c: %Destroy.WithSelf.SubobjectDestroy.type.f12 = struct_value () [symbolic]
// CHECK:STDOUT:   %DefaultOptionalStorage.as.Destroy.impl.Op.type.c4d: type = fn_type @DefaultOptionalStorage.as.Destroy.impl.Op, @DefaultOptionalStorage.as.Destroy.impl(%T.dc4) [symbolic]
// CHECK:STDOUT:   %DefaultOptionalStorage.as.Destroy.impl.Op.d2e: %DefaultOptionalStorage.as.Destroy.impl.Op.type.c4d = struct_value () [symbolic]
// CHECK:STDOUT:   %Destroy.impl_witness.d99: <witness> = impl_witness imports.%Destroy.impl_witness_table, @DefaultOptionalStorage.as.Destroy.impl(%facet_value) [concrete]
// CHECK:STDOUT:   %Destroy.facet.7e1: %Destroy.type = facet_value %DefaultOptionalStorage.44d, (%Destroy.impl_witness.d99) [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.651: type = fn_type @Destroy.WithSelf.SelfDestruct.1, @Destroy.WithSelf(%Destroy.facet.7e1) [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.992: %Destroy.WithSelf.SelfDestruct.type.651 = struct_value () [concrete]
// CHECK:STDOUT:   %OptionalStorage.impl_witness.2cd: <witness> = impl_witness imports.%OptionalStorage.impl_witness_table.0d6, @T.as_type.as.OptionalStorage.impl(%facet_value) [concrete]
// CHECK:STDOUT:   %OptionalStorage.facet: %OptionalStorage.type = facet_value %Tracked, (%OptionalStorage.impl_witness.2cd) [concrete]
// CHECK:STDOUT:   %Optional.82b: type = class_type @Optional, @Optional(%OptionalStorage.facet) [concrete]
// CHECK:STDOUT:   %Optional.Some.type.da7: type = fn_type @Optional.Some, @Optional(%OptionalStorage.facet) [concrete]
// CHECK:STDOUT:   %Optional.Some.0e3: %Optional.Some.type.da7 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.cce: type = pattern_type %Optional.82b [concrete]
// CHECK:STDOUT:   %o.patt: %pattern_type.cce = ref_binding_pattern o [concrete]
// CHECK:STDOUT:   %o.var_patt: %pattern_type.cce = var_pattern %o.patt [concrete]
// CHECK:STDOUT:   %Optional.Some.specific_fn: <specific function> = specific_function %Optional.Some.0e3, @Optional.Some(%OptionalStorage.facet) [concrete]
// CHECK:STDOUT:   %self.param_patt.dc5: %pattern_type.cce = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.123: %pattern_type.cce = wrapper_binding_pattern self, %self.param_patt.dc5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfc: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc15 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01: %Destroy.WithSelf.SubobjectDestroy.type.dfc = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef0: type = fn_type @Destroy.WithSelf.Op.loc15 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403: %Destroy.WithSelf.Op.type.ef0 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbc: type = fn_type @Destroy.WithSelf.SelfDestruct.loc15 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3: %Destroy.WithSelf.SelfDestruct.type.fbc = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .Copy = %Core.Copy.e5d
// CHECK:STDOUT:     .Destroy = %Core.Destroy
// CHECK:STDOUT:     .Optional = %Core.Optional
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Copy.e5d: type = import_ref Core//prelude/copy, Copy, loaded [concrete = constants.%Copy.type]
// CHECK:STDOUT:   %Core.Destroy: type = import_ref Core//prelude/destroy, Destroy, loaded [concrete = constants.%Destroy.type]
// CHECK:STDOUT:   %Core.Optional: %Optional.type = import_ref Core//prelude/types/optional, Optional, loaded [concrete = constants.%Optional.generic]
// CHECK:STDOUT:   %Core.import_ref.48e: @Optional.%Optional.Some.type (%Optional.Some.type.304) = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @Optional.%Optional.Some (constants.%Optional.Some.2a0)]
// CHECK:STDOUT:   %Core.import_ref.f38: %Destroy.type = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @T.as_type.as.OptionalStorage.impl.%Destroy.facet (constants.%Destroy.facet.0de)]
// CHECK:STDOUT:   %Core.import_ref.f71 = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.712: @T.as_type.as.OptionalStorage.impl.%T.as_type.as.OptionalStorage.impl.Some.type (%T.as_type.as.OptionalStorage.impl.Some.type.818) = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @T.as_type.as.OptionalStorage.impl.%T.as_type.as.OptionalStorage.impl.Some (constants.%T.as_type.as.OptionalStorage.impl.Some.620)]
// CHECK:STDOUT:   %Core.import_ref.565 = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.c52 = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.007 = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %OptionalStorage.impl_witness_table.0d6 = impl_witness_table (%Core.import_ref.f38, %Core.import_ref.f71, %Core.import_ref.712, %Core.import_ref.565, %Core.import_ref.c52, %Core.import_ref.007), @T.as_type.as.OptionalStorage.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.8ac: @DefaultOptionalStorage.as.Destroy.impl.%DefaultOptionalStorage.as.Destroy.impl.Op.type (%DefaultOptionalStorage.as.Destroy.impl.Op.type.c4d) = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @DefaultOptionalStorage.as.Destroy.impl.%DefaultOptionalStorage.as.Destroy.impl.Op (constants.%DefaultOptionalStorage.as.Destroy.impl.Op.d2e)]
// CHECK:STDOUT:   %Core.import_ref.eae: @DefaultOptionalStorage.as.Destroy.impl.%Destroy.WithSelf.SubobjectDestroy.type (%Destroy.WithSelf.SubobjectDestroy.type.f12) = import_ref Core//prelude/types/optional, inst{{[0-9A-F]+}} [no loc], loaded [symbolic = @DefaultOptionalStorage.as.Destroy.impl.%Destroy.WithSelf.SubobjectDestroy (constants.%Destroy.WithSelf.SubobjectDestroy.c1c)]
// CHECK:STDOUT:   %Core.import_ref.6ffbd: @DefaultOptionalStorage.as.Destroy.impl.%Destroy.WithSelf.SelfDestruct.type (%Destroy.WithSelf.SelfDestruct.type.916) = import_ref Core//prelude/types/optional, inst{{[0-9A-F]+}} [no loc], loaded [symbolic = @DefaultOptionalStorage.as.Destroy.impl.%Destroy.WithSelf.SelfDestruct (constants.%Destroy.WithSelf.SelfDestruct.2ee)]
// CHECK:STDOUT:   %Destroy.impl_witness_table = impl_witness_table (%Core.import_ref.8ac, %Core.import_ref.eae, %Core.import_ref.6ffbd), @DefaultOptionalStorage.as.Destroy.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl: %Destroy.WithSelf.SubobjectDestroy.type.dfc = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc15 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.cce = ref_param_pattern [concrete = constants.%self.param_patt.dc5]
// CHECK:STDOUT:     %self.patt: %pattern_type.cce = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.123]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %Optional.82b = ref_param call_param0
// CHECK:STDOUT:     %self: ref %Optional.82b = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl: %Destroy.WithSelf.Op.type.ef0 = fn_decl @Destroy.WithSelf.Op.loc15 [concrete = constants.%Destroy.WithSelf.Op.403] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.cce = ref_param_pattern [concrete = constants.%self.param_patt.dc5]
// CHECK:STDOUT:     %self.patt: %pattern_type.cce = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.123]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %Optional.82b = ref_param call_param0
// CHECK:STDOUT:     %self: ref %Optional.82b = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Hold.decl: %Hold.type = fn_decl @Hold [concrete = constants.%Hold] {
// CHECK:STDOUT:     %t.param_patt: %pattern_type.47e = value_param_pattern [concrete = constants.%t.param_patt]
// CHECK:STDOUT:     %t.patt: %pattern_type.47e = wrapper_binding_pattern t, %t.param_patt [concrete = constants.%t.patt]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %t.param: %Tracked = value_param call_param0
// CHECK:STDOUT:     %Tracked.ref.loc14: type = name_ref Tracked, file.%Tracked.decl [concrete = constants.%Tracked]
// CHECK:STDOUT:     %t: %Tracked = wrapper_binding t, %t.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Hold(%t.param: %Tracked) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %o.var: ref %Optional.82b = var_storage %o.var_patt
// CHECK:STDOUT:   %Core.ref.loc15_42: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:   %Optional.ref.loc15_46: %Optional.type = name_ref Optional, imports.%Core.Optional [concrete = constants.%Optional.generic]
// CHECK:STDOUT:   %Tracked.ref.loc15_56: type = name_ref Tracked, file.%Tracked.decl [concrete = constants.%Tracked]
// CHECK:STDOUT:   %OptionalStorage.facet.loc15_63: %OptionalStorage.type = facet_value %Tracked.ref.loc15_56, (constants.%OptionalStorage.impl_witness.2cd) [concrete = constants.%OptionalStorage.facet]
// CHECK:STDOUT:   %.loc15_63: %OptionalStorage.type = converted %Tracked.ref.loc15_56, %OptionalStorage.facet.loc15_63 [concrete = constants.%OptionalStorage.facet]
// CHECK:STDOUT:   %Optional.loc15_63: type = class_type @Optional, @Optional(constants.%OptionalStorage.facet) [concrete = constants.%Optional.82b]
// CHECK:STDOUT:   %.loc15_64: %Optional.Some.type.da7 = specific_constant imports.%Core.import_ref.48e, @Optional(constants.%OptionalStorage.facet) [concrete = constants.%Optional.Some.0e3]
// CHECK:STDOUT:   %Some.ref: %Optional.Some.type.da7 = name_ref Some, %.loc15_64 [concrete = constants.%Optional.Some.0e3]
// CHECK:STDOUT:   %t.ref: %Tracked = name_ref t, %t
// CHECK:STDOUT:   %OptionalStorage.facet.loc15_71.1: %OptionalStorage.type = facet_value constants.%Tracked, (constants.%OptionalStorage.impl_witness.2cd) [concrete = constants.%OptionalStorage.facet]
// CHECK:STDOUT:   %.loc15_71.1: %OptionalStorage.type = converted constants.%Tracked, %OptionalStorage.facet.loc15_71.1 [concrete = constants.%OptionalStorage.facet]
// CHECK:STDOUT:   %OptionalStorage.facet.loc15_71.2: %OptionalStorage.type = facet_value constants.%Tracked, (constants.%OptionalStorage.impl_witness.2cd) [concrete = constants.%OptionalStorage.facet]
// CHECK:STDOUT:   %.loc15_71.2: %OptionalStorage.type = converted constants.%Tracked, %OptionalStorage.facet.loc15_71.2 [concrete = constants.%OptionalStorage.facet]
// CHECK:STDOUT:   %Optional.Some.specific_fn: <specific function> = specific_function %Some.ref, @Optional.Some(constants.%OptionalStorage.facet) [concrete = constants.%Optional.Some.specific_fn]
// CHECK:STDOUT:   %.loc15_3: ref %Optional.82b = splice_block %o.var {}
// CHECK:STDOUT:   %Optional.Some.call: init %Optional.82b to %.loc15_3 = call %Optional.Some.specific_fn(%t.ref)
// CHECK:STDOUT:   assign %o.var, %Optional.Some.call
// CHECK:STDOUT:   %.loc15_38.1: type = splice_block %Optional.loc15_38 [concrete = constants.%Optional.82b] {
// CHECK:STDOUT:     %Core.ref.loc15_17: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:     %Optional.ref.loc15_21: %Optional.type = name_ref Optional, imports.%Core.Optional [concrete = constants.%Optional.generic]
// CHECK:STDOUT:     %Tracked.ref.loc15_31: type = name_ref Tracked, file.%Tracked.decl [concrete = constants.%Tracked]
// CHECK:STDOUT:     %OptionalStorage.facet.loc15_38: %OptionalStorage.type = facet_value %Tracked.ref.loc15_31, (constants.%OptionalStorage.impl_witness.2cd) [concrete = constants.%OptionalStorage.facet]
// CHECK:STDOUT:     %.loc15_38.2: %OptionalStorage.type = converted %Tracked.ref.loc15_31, %OptionalStorage.facet.loc15_38 [concrete = constants.%OptionalStorage.facet]
// CHECK:STDOUT:     %Optional.loc15_38: type = class_type @Optional, @Optional(constants.%OptionalStorage.facet) [concrete = constants.%Optional.82b]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %o: ref %Optional.82b = wrapper_binding o, %o.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %o.patt: %pattern_type.cce = ref_binding_pattern o [concrete = constants.%o.patt]
// CHECK:STDOUT:     %o.var_patt: %pattern_type.cce = var_pattern %o.patt [concrete = constants.%o.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound: <bound method> = bound_method %o.var, constants.%Destroy.WithSelf.SelfDestruct.db3
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound(%o.var)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc15(%self.param: ref %Optional.82b) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %.loc15_3.1: ref %DefaultOptionalStorage.44d = as_compatible %self.param
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound: <bound method> = bound_method %.loc15_3.1, constants.%Destroy.WithSelf.SelfDestruct.992
// CHECK:STDOUT:   %Destroy.facet.loc15_3.1: %Destroy.type = facet_value constants.%DefaultOptionalStorage.44d, (constants.%Destroy.impl_witness.d99) [concrete = constants.%Destroy.facet.7e1]
// CHECK:STDOUT:   %.loc15_3.2: %Destroy.type = converted constants.%DefaultOptionalStorage.44d, %Destroy.facet.loc15_3.1 [concrete = constants.%Destroy.facet.7e1]
// CHECK:STDOUT:   %Destroy.facet.loc15_3.2: %Destroy.type = facet_value constants.%DefaultOptionalStorage.44d, (constants.%Destroy.impl_witness.d99) [concrete = constants.%Destroy.facet.7e1]
// CHECK:STDOUT:   %.loc15_3.3: %Destroy.type = converted constants.%DefaultOptionalStorage.44d, %Destroy.facet.loc15_3.2 [concrete = constants.%Destroy.facet.7e1]
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:   %bound_method: <bound method> = bound_method %.loc15_3.1, %Destroy.WithSelf.SelfDestruct.specific_fn
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call: init %empty_tuple.type = call %bound_method(%.loc15_3.1)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc15(%self.param: ref %Optional.82b) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc15(%self.param: ref %Optional.82b) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- pointer.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %Int.type: type = generic_class_type @Int [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %Int.generic: %Int.type = struct_value () [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %ptr.d08: type = ptr_type %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.f00: type = pattern_type %ptr.d08 [concrete]
// CHECK:STDOUT:   %p.param_patt: %pattern_type.f00 = value_param_pattern [concrete]
// CHECK:STDOUT:   %p.patt: %pattern_type.f00 = wrapper_binding_pattern p, %p.param_patt [concrete]
// CHECK:STDOUT:   %HoldPointer.type: type = fn_type @HoldPointer [concrete]
// CHECK:STDOUT:   %HoldPointer: %HoldPointer.type = struct_value () [concrete]
// CHECK:STDOUT:   %Optional.type: type = generic_class_type @Optional [concrete]
// CHECK:STDOUT:   %Optional.generic: %Optional.type = struct_value () [concrete]
// CHECK:STDOUT:   %OptionalStorage.type: type = facet_type <@OptionalStorage> [concrete]
// CHECK:STDOUT:   %Destroy.type: type = facet_type <@Destroy> [concrete]
// CHECK:STDOUT:   %T.220: %OptionalStorage.type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %Optional.Some.type.304: type = fn_type @Optional.Some, @Optional(%T.220) [symbolic]
// CHECK:STDOUT:   %Optional.Some.2a0: %Optional.Some.type.304 = struct_value () [symbolic]
// CHECK:STDOUT:   %T.67d: type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %ptr.e8f: type = ptr_type %T.67d [symbolic]
// CHECK:STDOUT:   %Destroy.lookup_impl_witness.781: <witness> = lookup_impl_witness %ptr.e8f, @Destroy [symbolic]
// CHECK:STDOUT:   %Destroy.facet.e46: %Destroy.type = facet_value %ptr.e8f, (%Destroy.lookup_impl_witness.781) [symbolic]
// CHECK:STDOUT:   %MaybeUnformed.ddb: type = class_type @MaybeUnformed, @MaybeUnformed(%Destroy.facet.e46) [symbolic]
// CHECK:STDOUT:   %ptr.as.OptionalStorage.impl.Some.type.71e: type = fn_type @ptr.as.OptionalStorage.impl.Some, @ptr.as.OptionalStorage.impl(%T.67d) [symbolic]
// CHECK:STDOUT:   %ptr.as.OptionalStorage.impl.Some.caa: %ptr.as.OptionalStorage.impl.Some.type.71e = struct_value () [symbolic]
// CHECK:STDOUT:   %Destroy.lookup_impl_witness.ad0: <witness> = lookup_impl_witness %MaybeUnformed.ddb, @Destroy [symbolic]
// CHECK:STDOUT:   %Destroy.facet.270: %Destroy.type = facet_value %MaybeUnformed.ddb, (%Destroy.lookup_impl_witness.ad0) [symbolic]
// CHECK:STDOUT:   %OptionalStorage.impl_witness.0ce: <witness> = impl_witness imports.%OptionalStorage.impl_witness_table.110, @ptr.as.OptionalStorage.impl(%i32) [concrete]
// CHECK:STDOUT:   %OptionalStorage.facet: %OptionalStorage.type = facet_value %ptr.d08, (%OptionalStorage.impl_witness.0ce) [concrete]
// CHECK:STDOUT:   %Optional.5b3: type = class_type @Optional, @Optional(%OptionalStorage.facet) [concrete]
// CHECK:STDOUT:   %Optional.Some.type.739: type = fn_type @Optional.Some, @Optional(%OptionalStorage.facet) [concrete]
// CHECK:STDOUT:   %Optional.Some.3dd: %Optional.Some.type.739 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.ef8: type = pattern_type %Optional.5b3 [concrete]
// CHECK:STDOUT:   %o.patt: %pattern_type.ef8 = ref_binding_pattern o [concrete]
// CHECK:STDOUT:   %o.var_patt: %pattern_type.ef8 = var_pattern %o.patt [concrete]
// CHECK:STDOUT:   %Optional.Some.specific_fn: <specific function> = specific_function %Optional.Some.3dd, @Optional.Some(%OptionalStorage.facet) [concrete]
// CHECK:STDOUT:   %self.param_patt.d96: %pattern_type.ef8 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.77d: %pattern_type.ef8 = wrapper_binding_pattern self, %self.param_patt.d96 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc6 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.4: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.4: type = fn_type @Destroy.WithSelf.Op.loc6 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.4: %Destroy.WithSelf.Op.type.ef016f.4 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.4: type = fn_type @Destroy.WithSelf.SelfDestruct.loc6 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.4: %Destroy.WithSelf.SelfDestruct.type.fbceb5.4 = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .Int = %Core.Int
// CHECK:STDOUT:     .Optional = %Core.Optional
// CHECK:STDOUT:     .Destroy = %Core.Destroy
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Int: %Int.type = import_ref Core//prelude/types/int, Int, loaded [concrete = constants.%Int.generic]
// CHECK:STDOUT:   %Core.Optional: %Optional.type = import_ref Core//prelude/types/optional, Optional, loaded [concrete = constants.%Optional.generic]
// CHECK:STDOUT:   %Core.import_ref.48e: @Optional.%Optional.Some.type (%Optional.Some.type.304) = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @Optional.%Optional.Some (constants.%Optional.Some.2a0)]
// CHECK:STDOUT:   %Core.import_ref.809: %Destroy.type = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @ptr.as.OptionalStorage.impl.%Destroy.facet.2 (constants.%Destroy.facet.270)]
// CHECK:STDOUT:   %Core.import_ref.105 = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.fa7: @ptr.as.OptionalStorage.impl.%ptr.as.OptionalStorage.impl.Some.type (%ptr.as.OptionalStorage.impl.Some.type.71e) = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @ptr.as.OptionalStorage.impl.%ptr.as.OptionalStorage.impl.Some (constants.%ptr.as.OptionalStorage.impl.Some.caa)]
// CHECK:STDOUT:   %Core.import_ref.a90 = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.306 = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.3e3 = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %OptionalStorage.impl_witness_table.110 = impl_witness_table (%Core.import_ref.809, %Core.import_ref.105, %Core.import_ref.fa7, %Core.import_ref.a90, %Core.import_ref.306, %Core.import_ref.3e3), @ptr.as.OptionalStorage.impl [concrete]
// CHECK:STDOUT:   %Core.Destroy: type = import_ref Core//prelude/destroy, Destroy, loaded [concrete = constants.%Destroy.type]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.4: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc6 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.4] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.ef8 = ref_param_pattern [concrete = constants.%self.param_patt.d96]
// CHECK:STDOUT:     %self.patt: %pattern_type.ef8 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.77d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %Optional.5b3 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %Optional.5b3 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.4: %Destroy.WithSelf.Op.type.ef016f.4 = fn_decl @Destroy.WithSelf.Op.loc6 [concrete = constants.%Destroy.WithSelf.Op.403171.4] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.ef8 = ref_param_pattern [concrete = constants.%self.param_patt.d96]
// CHECK:STDOUT:     %self.patt: %pattern_type.ef8 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.77d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %Optional.5b3 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %Optional.5b3 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %HoldPointer.decl: %HoldPointer.type = fn_decl @HoldPointer [concrete = constants.%HoldPointer] {
// CHECK:STDOUT:     %p.param_patt: %pattern_type.f00 = value_param_pattern [concrete = constants.%p.param_patt]
// CHECK:STDOUT:     %p.patt: %pattern_type.f00 = wrapper_binding_pattern p, %p.param_patt [concrete = constants.%p.patt]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %p.param: %ptr.d08 = value_param call_param0
// CHECK:STDOUT:     %.loc5: type = splice_block %ptr.loc5 [concrete = constants.%ptr.d08] {
// CHECK:STDOUT:       %i32.loc5: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %ptr.loc5: type = ptr_type %i32.loc5 [concrete = constants.%ptr.d08]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %p: %ptr.d08 = wrapper_binding p, %p.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @HoldPointer(%p.param: %ptr.d08) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %o.var: ref %Optional.5b3 = var_storage %o.var_patt
// CHECK:STDOUT:   %Core.ref.loc6_39: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:   %Optional.ref.loc6_43: %Optional.type = name_ref Optional, imports.%Core.Optional [concrete = constants.%Optional.generic]
// CHECK:STDOUT:   %i32.loc6_53: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %ptr.loc6_56: type = ptr_type %i32.loc6_53 [concrete = constants.%ptr.d08]
// CHECK:STDOUT:   %OptionalStorage.facet.loc6_57: %OptionalStorage.type = facet_value %ptr.loc6_56, (constants.%OptionalStorage.impl_witness.0ce) [concrete = constants.%OptionalStorage.facet]
// CHECK:STDOUT:   %.loc6_57: %OptionalStorage.type = converted %ptr.loc6_56, %OptionalStorage.facet.loc6_57 [concrete = constants.%OptionalStorage.facet]
// CHECK:STDOUT:   %Optional.loc6_57: type = class_type @Optional, @Optional(constants.%OptionalStorage.facet) [concrete = constants.%Optional.5b3]
// CHECK:STDOUT:   %.loc6_58: %Optional.Some.type.739 = specific_constant imports.%Core.import_ref.48e, @Optional(constants.%OptionalStorage.facet) [concrete = constants.%Optional.Some.3dd]
// CHECK:STDOUT:   %Some.ref: %Optional.Some.type.739 = name_ref Some, %.loc6_58 [concrete = constants.%Optional.Some.3dd]
// CHECK:STDOUT:   %p.ref: %ptr.d08 = name_ref p, %p
// CHECK:STDOUT:   %OptionalStorage.facet.loc6_65.1: %OptionalStorage.type = facet_value constants.%ptr.d08, (constants.%OptionalStorage.impl_witness.0ce) [concrete = constants.%OptionalStorage.facet]
// CHECK:STDOUT:   %.loc6_65.1: %OptionalStorage.type = converted constants.%ptr.d08, %OptionalStorage.facet.loc6_65.1 [concrete = constants.%OptionalStorage.facet]
// CHECK:STDOUT:   %OptionalStorage.facet.loc6_65.2: %OptionalStorage.type = facet_value constants.%ptr.d08, (constants.%OptionalStorage.impl_witness.0ce) [concrete = constants.%OptionalStorage.facet]
// CHECK:STDOUT:   %.loc6_65.2: %OptionalStorage.type = converted constants.%ptr.d08, %OptionalStorage.facet.loc6_65.2 [concrete = constants.%OptionalStorage.facet]
// CHECK:STDOUT:   %Optional.Some.specific_fn: <specific function> = specific_function %Some.ref, @Optional.Some(constants.%OptionalStorage.facet) [concrete = constants.%Optional.Some.specific_fn]
// CHECK:STDOUT:   %Optional.Some.call: init %Optional.5b3 = call %Optional.Some.specific_fn(%p.ref)
// CHECK:STDOUT:   assign %o.var, %Optional.Some.call
// CHECK:STDOUT:   %.loc6_35.1: type = splice_block %Optional.loc6_35 [concrete = constants.%Optional.5b3] {
// CHECK:STDOUT:     %Core.ref.loc6_17: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:     %Optional.ref.loc6_21: %Optional.type = name_ref Optional, imports.%Core.Optional [concrete = constants.%Optional.generic]
// CHECK:STDOUT:     %i32.loc6_31: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %ptr.loc6_34: type = ptr_type %i32.loc6_31 [concrete = constants.%ptr.d08]
// CHECK:STDOUT:     %OptionalStorage.facet.loc6_35: %OptionalStorage.type = facet_value %ptr.loc6_34, (constants.%OptionalStorage.impl_witness.0ce) [concrete = constants.%OptionalStorage.facet]
// CHECK:STDOUT:     %.loc6_35.2: %OptionalStorage.type = converted %ptr.loc6_34, %OptionalStorage.facet.loc6_35 [concrete = constants.%OptionalStorage.facet]
// CHECK:STDOUT:     %Optional.loc6_35: type = class_type @Optional, @Optional(constants.%OptionalStorage.facet) [concrete = constants.%Optional.5b3]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %o: ref %Optional.5b3 = wrapper_binding o, %o.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %o.patt: %pattern_type.ef8 = ref_binding_pattern o [concrete = constants.%o.patt]
// CHECK:STDOUT:     %o.var_patt: %pattern_type.ef8 = var_pattern %o.patt [concrete = constants.%o.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound: <bound method> = bound_method %o.var, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.4
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound(%o.var)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc6(%self.param: ref %Optional.5b3) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc6(%self.param: ref %Optional.5b3) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc6(%self.param: ref %Optional.5b3) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.4(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.4(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- generic.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %.Self.frozen: type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %Destroy.type: type = facet_type <@Destroy> [concrete]
// CHECK:STDOUT:   %BitAndWith.type.a06: type = generic_interface_type @BitAndWith [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %BitAndWith.generic: %BitAndWith.type.a06 = struct_value () [concrete]
// CHECK:STDOUT:   %BitAndWith.type.411: type = facet_type <@BitAndWith, @BitAndWith(type)> [concrete]
// CHECK:STDOUT:   %BitAndWith.impl_witness: <witness> = impl_witness imports.%BitAndWith.impl_witness_table [concrete]
// CHECK:STDOUT:   %BitAndWith.facet: %BitAndWith.type.411 = facet_value type, (%BitAndWith.impl_witness) [concrete]
// CHECK:STDOUT:   %BitAndWith.WithSelf.Op.type.0cf: type = fn_type @BitAndWith.WithSelf.Op, @BitAndWith.WithSelf(type, %BitAndWith.facet) [concrete]
// CHECK:STDOUT:   %.85c: type = fn_type_with_self_type %BitAndWith.WithSelf.Op.type.0cf, %BitAndWith.facet [concrete]
// CHECK:STDOUT:   %type.as.BitAndWith.impl.Op.type: type = fn_type @type.as.BitAndWith.impl.Op [concrete]
// CHECK:STDOUT:   %type.as.BitAndWith.impl.Op: %type.as.BitAndWith.impl.Op.type = struct_value () [concrete]
// CHECK:STDOUT:   %type.as.BitAndWith.impl.Op.bound: <bound method> = bound_method %Copy.type, %type.as.BitAndWith.impl.Op [concrete]
// CHECK:STDOUT:   %facet_type: type = facet_type <@Copy & @Destroy> [concrete]
// CHECK:STDOUT:   %pattern_type.143: type = pattern_type %facet_type [concrete]
// CHECK:STDOUT:   %T.patt.256: %pattern_type.143 = symbolic_binding_pattern T, 0 [symbolic]
// CHECK:STDOUT:   %T.dc4: %facet_type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %T.as_type.5d6: type = facet_access_type %T.dc4 [symbolic]
// CHECK:STDOUT:   %pattern_type.0e9: type = pattern_type %T.as_type.5d6 [symbolic]
// CHECK:STDOUT:   %a.param_patt: %pattern_type.0e9 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %a.patt: %pattern_type.0e9 = wrapper_binding_pattern a, %a.param_patt [symbolic]
// CHECK:STDOUT:   %.f34: Core.Form = init_form bool [concrete]
// CHECK:STDOUT:   %pattern_type.831: type = pattern_type bool [concrete]
// CHECK:STDOUT:   %return.param_patt.5a1: %pattern_type.831 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.c0c: %pattern_type.831 = return_slot_pattern %return.param_patt.5a1, bool [concrete]
// CHECK:STDOUT:   %HoldGeneric.type: type = fn_type @HoldGeneric [concrete]
// CHECK:STDOUT:   %HoldGeneric: %HoldGeneric.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete.091: <witness> = require_complete_type %T.as_type.5d6 [symbolic]
// CHECK:STDOUT:   %Optional.type: type = generic_class_type @Optional [concrete]
// CHECK:STDOUT:   %Optional.generic: %Optional.type = struct_value () [concrete]
// CHECK:STDOUT:   %OptionalStorage.type: type = facet_type <@OptionalStorage> [concrete]
// CHECK:STDOUT:   %T.220: %OptionalStorage.type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %Optional.HasValue.type.e9e: type = fn_type @Optional.HasValue, @Optional(%T.220) [symbolic]
// CHECK:STDOUT:   %Optional.HasValue.6cd: %Optional.HasValue.type.e9e = struct_value () [symbolic]
// CHECK:STDOUT:   %Optional.Some.type.304: type = fn_type @Optional.Some, @Optional(%T.220) [symbolic]
// CHECK:STDOUT:   %Optional.Some.2a0: %Optional.Some.type.304 = struct_value () [symbolic]
// CHECK:STDOUT:   %OptionalStorage.lookup_impl_witness.a98: <witness> = lookup_impl_witness %T.dc4, @OptionalStorage [symbolic]
// CHECK:STDOUT:   %.d7c: require_specific_def_type = require_specific_def @T.as_type.as.OptionalStorage.impl(%T.dc4) [symbolic]
// CHECK:STDOUT:   %OptionalStorage.facet: %OptionalStorage.type = facet_value %T.as_type.5d6, (%OptionalStorage.lookup_impl_witness.a98) [symbolic]
// CHECK:STDOUT:   %Optional.4d3: type = class_type @Optional, @Optional(%OptionalStorage.facet) [symbolic]
// CHECK:STDOUT:   %Optional.Some.type.087: type = fn_type @Optional.Some, @Optional(%OptionalStorage.facet) [symbolic]
// CHECK:STDOUT:   %Optional.Some.bff: %Optional.Some.type.087 = struct_value () [symbolic]
// CHECK:STDOUT:   %Optional.HasValue.type.b55: type = fn_type @Optional.HasValue, @Optional(%OptionalStorage.facet) [symbolic]
// CHECK:STDOUT:   %Optional.HasValue.da2: %Optional.HasValue.type.b55 = struct_value () [symbolic]
// CHECK:STDOUT:   %require_complete.b69: <witness> = require_complete_type %Optional.4d3 [symbolic]
// CHECK:STDOUT:   %pattern_type.6d4: type = pattern_type %Optional.4d3 [symbolic]
// CHECK:STDOUT:   %o.patt: %pattern_type.6d4 = value_binding_pattern o [symbolic]
// CHECK:STDOUT:   %Optional.Some.specific_fn: <specific function> = specific_function %Optional.Some.bff, @Optional.Some(%OptionalStorage.facet) [symbolic]
// CHECK:STDOUT:   %Optional.HasValue.specific_fn.7a3: <specific function> = specific_function %Optional.HasValue.da2, @Optional.HasValue(%OptionalStorage.facet) [symbolic]
// CHECK:STDOUT:   %Destroy.lookup_impl_witness.0cb: <witness> = lookup_impl_witness %Optional.4d3, @Destroy [symbolic]
// CHECK:STDOUT:   %Destroy.facet.7e4: %Destroy.type = facet_value %Optional.4d3, (%Destroy.lookup_impl_witness.0cb) [symbolic]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.c2f: type = fn_type @Destroy.WithSelf.SelfDestruct, @Destroy.WithSelf(%Destroy.facet.7e4) [symbolic]
// CHECK:STDOUT:   %.545: type = fn_type_with_self_type %Destroy.WithSelf.SelfDestruct.type.c2f, %Destroy.facet.7e4 [symbolic]
// CHECK:STDOUT:   %impl.elem2.407: %.545 = impl_witness_access %Destroy.lookup_impl_witness.0cb, element2 [symbolic]
// CHECK:STDOUT:   %specific_impl_fn.1c4: <specific function> = specific_impl_function %impl.elem2.407, @Destroy.WithSelf.SelfDestruct(%Destroy.facet.7e4) [symbolic]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .Copy = %Core.Copy.e5d
// CHECK:STDOUT:     .Destroy = %Core.Destroy
// CHECK:STDOUT:     .BitAndWith = %Core.BitAndWith
// CHECK:STDOUT:     .Bool = %Core.Bool
// CHECK:STDOUT:     .Optional = %Core.Optional
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Copy.e5d: type = import_ref Core//prelude/copy, Copy, loaded [concrete = constants.%Copy.type]
// CHECK:STDOUT:   %Core.Destroy: type = import_ref Core//prelude/destroy, Destroy, loaded [concrete = constants.%Destroy.type]
// CHECK:STDOUT:   %Core.BitAndWith: %BitAndWith.type.a06 = import_ref Core//prelude/operators/bitwise, BitAndWith, loaded [concrete = constants.%BitAndWith.generic]
// CHECK:STDOUT:   %Core.import_ref.05b = import_ref Core//prelude/operators/bitwise, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9c3: %type.as.BitAndWith.impl.Op.type = import_ref Core//prelude/operators/bitwise, loc{{\d+_\d+}}, loaded [concrete = constants.%type.as.BitAndWith.impl.Op]
// CHECK:STDOUT:   %BitAndWith.impl_witness_table = impl_witness_table (%Core.import_ref.05b, %Core.import_ref.9c3), @type.as.BitAndWith.impl [concrete]
// CHECK:STDOUT:   %Core.Bool: type = import_ref Core//prelude/types/bool, Bool, loaded [concrete = bool]
// CHECK:STDOUT:   %Core.Optional: %Optional.type = import_ref Core//prelude/types/optional, Optional, loaded [concrete = constants.%Optional.generic]
// CHECK:STDOUT:   %Core.import_ref.48e: @Optional.%Optional.Some.type (%Optional.Some.type.304) = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @Optional.%Optional.Some (constants.%Optional.Some.2a0)]
// CHECK:STDOUT:   %Core.import_ref.729: @Optional.%Optional.HasValue.type (%Optional.HasValue.type.e9e) = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @Optional.%Optional.HasValue (constants.%Optional.HasValue.6cd)]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %HoldGeneric.decl: %HoldGeneric.type = fn_decl @HoldGeneric [concrete = constants.%HoldGeneric] {
// CHECK:STDOUT:     %T.patt.loc5_17.1: %pattern_type.143 = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc5_17.2 (constants.%T.patt.256)]
// CHECK:STDOUT:     %a.param_patt.loc5_46.1: @HoldGeneric.%pattern_type.loc5 (%pattern_type.0e9) = value_param_pattern [symbolic = %a.param_patt.loc5_46.2 (constants.%a.param_patt)]
// CHECK:STDOUT:     %a.patt.loc5_46.1: @HoldGeneric.%pattern_type.loc5 (%pattern_type.0e9) = wrapper_binding_pattern a, %a.param_patt.loc5_46.1 [symbolic = %a.patt.loc5_46.2 (constants.%a.patt)]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.831 = out_param_pattern [concrete = constants.%return.param_patt.5a1]
// CHECK:STDOUT:     %return.patt: %pattern_type.831 = return_slot_pattern %return.param_patt, %.loc5_54.1 [concrete = constants.%return.patt.c0c]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc5_54.1: type = type_literal bool [concrete = bool]
// CHECK:STDOUT:     %.loc5_54.2: Core.Form = init_form %.loc5_54.1 [concrete = constants.%.f34]
// CHECK:STDOUT:     %.loc5_29.1: type = splice_block %.loc5_29.3 [concrete = constants.%facet_type] {
// CHECK:STDOUT:       %.Self.frozen: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %Core.ref.loc5_19: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %Copy.ref: type = name_ref Copy, imports.%Core.Copy.e5d [concrete = constants.%Copy.type]
// CHECK:STDOUT:       %Core.ref.loc5_31: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %Destroy.ref: type = name_ref Destroy, imports.%Core.Destroy [concrete = constants.%Destroy.type]
// CHECK:STDOUT:       %impl.elem1: %.85c = impl_witness_access constants.%BitAndWith.impl_witness, element1 [concrete = constants.%type.as.BitAndWith.impl.Op]
// CHECK:STDOUT:       %bound_method.loc5: <bound method> = bound_method %Copy.ref, %impl.elem1 [concrete = constants.%type.as.BitAndWith.impl.Op.bound]
// CHECK:STDOUT:       %type.as.BitAndWith.impl.Op.call: init type = call %bound_method.loc5(%Copy.ref, %Destroy.ref) [concrete = constants.%facet_type]
// CHECK:STDOUT:       %.loc5_29.2: type = value_of_initializer %type.as.BitAndWith.impl.Op.call [concrete = constants.%facet_type]
// CHECK:STDOUT:       %.loc5_29.3: type = converted %type.as.BitAndWith.impl.Op.call, %.loc5_29.2 [concrete = constants.%facet_type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc5_17.2: %facet_type = symbolic_binding T, 0 [symbolic = %T.loc5_17.1 (constants.%T.dc4)]
// CHECK:STDOUT:     %a.param: @HoldGeneric.%T.as_type.loc5_48.1 (%T.as_type.5d6) = value_param call_param0
// CHECK:STDOUT:     %.loc5_48.1: type = splice_block %.loc5_48.2 [symbolic = %T.as_type.loc5_48.1 (constants.%T.as_type.5d6)] {
// CHECK:STDOUT:       %T.ref.loc5: %facet_type = name_ref T, %T.loc5_17.2 [symbolic = %T.loc5_17.1 (constants.%T.dc4)]
// CHECK:STDOUT:       %T.as_type.loc5_48.2: type = facet_access_type %T.ref.loc5 [symbolic = %T.as_type.loc5_48.1 (constants.%T.as_type.5d6)]
// CHECK:STDOUT:       %.loc5_48.2: type = converted %T.ref.loc5, %T.as_type.loc5_48.2 [symbolic = %T.as_type.loc5_48.1 (constants.%T.as_type.5d6)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %a: @HoldGeneric.%T.as_type.loc5_48.1 (%T.as_type.5d6) = wrapper_binding a, %a.param
// CHECK:STDOUT:     %return.param: ref bool = out_param call_param1
// CHECK:STDOUT:     %return: ref bool = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @HoldGeneric(%T.loc5_17.2: %facet_type) {
// CHECK:STDOUT:   %T.patt.loc5_17.2: %pattern_type.143 = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc5_17.2 (constants.%T.patt.256)]
// CHECK:STDOUT:   %T.loc5_17.1: %facet_type = symbolic_binding T, 0 [symbolic = %T.loc5_17.1 (constants.%T.dc4)]
// CHECK:STDOUT:   %T.as_type.loc5_48.1: type = facet_access_type %T.loc5_17.1 [symbolic = %T.as_type.loc5_48.1 (constants.%T.as_type.5d6)]
// CHECK:STDOUT:   %pattern_type.loc5: type = pattern_type %T.as_type.loc5_48.1 [symbolic = %pattern_type.loc5 (constants.%pattern_type.0e9)]
// CHECK:STDOUT:   %a.param_patt.loc5_46.2: @HoldGeneric.%pattern_type.loc5 (%pattern_type.0e9) = value_param_pattern [symbolic = %a.param_patt.loc5_46.2 (constants.%a.param_patt)]
// CHECK:STDOUT:   %a.patt.loc5_46.2: @HoldGeneric.%pattern_type.loc5 (%pattern_type.0e9) = wrapper_binding_pattern a, %a.param_patt.loc5_46.2 [symbolic = %a.patt.loc5_46.2 (constants.%a.patt)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc5: <witness> = require_complete_type %T.as_type.loc5_48.1 [symbolic = %require_complete.loc5 (constants.%require_complete.091)]
// CHECK:STDOUT:   %.loc6_25.3: require_specific_def_type = require_specific_def @T.as_type.as.OptionalStorage.impl(%T.loc5_17.1) [symbolic = %.loc6_25.3 (constants.%.d7c)]
// CHECK:STDOUT:   %OptionalStorage.lookup_impl_witness: <witness> = lookup_impl_witness %T.loc5_17.1, @OptionalStorage [symbolic = %OptionalStorage.lookup_impl_witness (constants.%OptionalStorage.lookup_impl_witness.a98)]
// CHECK:STDOUT:   %OptionalStorage.facet.loc6_25.2: %OptionalStorage.type = facet_value %T.as_type.loc5_48.1, (%OptionalStorage.lookup_impl_witness) [symbolic = %OptionalStorage.facet.loc6_25.2 (constants.%OptionalStorage.facet)]
// CHECK:STDOUT:   %Optional.loc6_25.2: type = class_type @Optional, @Optional(%OptionalStorage.facet.loc6_25.2) [symbolic = %Optional.loc6_25.2 (constants.%Optional.4d3)]
// CHECK:STDOUT:   %require_complete.loc6: <witness> = require_complete_type %Optional.loc6_25.2 [symbolic = %require_complete.loc6 (constants.%require_complete.b69)]
// CHECK:STDOUT:   %pattern_type.loc6: type = pattern_type %Optional.loc6_25.2 [symbolic = %pattern_type.loc6 (constants.%pattern_type.6d4)]
// CHECK:STDOUT:   %o.patt.loc6_8.2: @HoldGeneric.%pattern_type.loc6 (%pattern_type.6d4) = value_binding_pattern o [symbolic = %o.patt.loc6_8.2 (constants.%o.patt)]
// CHECK:STDOUT:   %Optional.Some.type: type = fn_type @Optional.Some, @Optional(%OptionalStorage.facet.loc6_25.2) [symbolic = %Optional.Some.type (constants.%Optional.Some.type.087)]
// CHECK:STDOUT:   %Optional.Some: @HoldGeneric.%Optional.Some.type (%Optional.Some.type.087) = struct_value () [symbolic = %Optional.Some (constants.%Optional.Some.bff)]
// CHECK:STDOUT:   %Optional.Some.specific_fn.loc6_45.2: <specific function> = specific_function %Optional.Some, @Optional.Some(%OptionalStorage.facet.loc6_25.2) [symbolic = %Optional.Some.specific_fn.loc6_45.2 (constants.%Optional.Some.specific_fn)]
// CHECK:STDOUT:   %Optional.HasValue.type: type = fn_type @Optional.HasValue, @Optional(%OptionalStorage.facet.loc6_25.2) [symbolic = %Optional.HasValue.type (constants.%Optional.HasValue.type.b55)]
// CHECK:STDOUT:   %Optional.HasValue: @HoldGeneric.%Optional.HasValue.type (%Optional.HasValue.type.b55) = struct_value () [symbolic = %Optional.HasValue (constants.%Optional.HasValue.da2)]
// CHECK:STDOUT:   %Optional.HasValue.specific_fn.loc7_11.2: <specific function> = specific_function %Optional.HasValue, @Optional.HasValue(%OptionalStorage.facet.loc6_25.2) [symbolic = %Optional.HasValue.specific_fn.loc7_11.2 (constants.%Optional.HasValue.specific_fn.7a3)]
// CHECK:STDOUT:   %Destroy.lookup_impl_witness: <witness> = lookup_impl_witness %Optional.loc6_25.2, @Destroy [symbolic = %Destroy.lookup_impl_witness (constants.%Destroy.lookup_impl_witness.0cb)]
// CHECK:STDOUT:   %Destroy.facet.loc6_52.3: %Destroy.type = facet_value %Optional.loc6_25.2, (%Destroy.lookup_impl_witness) [symbolic = %Destroy.facet.loc6_52.3 (constants.%Destroy.facet.7e4)]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type: type = fn_type @Destroy.WithSelf.SelfDestruct, @Destroy.WithSelf(%Destroy.facet.loc6_52.3) [symbolic = %Destroy.WithSelf.SelfDestruct.type (constants.%Destroy.WithSelf.SelfDestruct.type.c2f)]
// CHECK:STDOUT:   %.loc6_52.8: type = fn_type_with_self_type %Destroy.WithSelf.SelfDestruct.type, %Destroy.facet.loc6_52.3 [symbolic = %.loc6_52.8 (constants.%.545)]
// CHECK:STDOUT:   %impl.elem2.loc6_52.2: @HoldGeneric.%.loc6_52.8 (%.545) = impl_witness_access %Destroy.lookup_impl_witness, element2 [symbolic = %impl.elem2.loc6_52.2 (constants.%impl.elem2.407)]
// CHECK:STDOUT:   %specific_impl_fn.loc6_52.2: <specific function> = specific_impl_function %impl.elem2.loc6_52.2, @Destroy.WithSelf.SelfDestruct(%Destroy.facet.loc6_52.3) [symbolic = %specific_impl_fn.loc6_52.2 (constants.%specific_impl_fn.1c4)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%a.param: @HoldGeneric.%T.as_type.loc5_48.1 (%T.as_type.5d6)) -> out %return.param: bool {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %Core.ref.loc6_29: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:     %Optional.ref.loc6_33: %Optional.type = name_ref Optional, imports.%Core.Optional [concrete = constants.%Optional.generic]
// CHECK:STDOUT:     %T.ref.loc6_43: %facet_type = name_ref T, %T.loc5_17.2 [symbolic = %T.loc5_17.1 (constants.%T.dc4)]
// CHECK:STDOUT:     %T.as_type.loc6_44: type = facet_access_type %T.ref.loc6_43 [symbolic = %T.as_type.loc5_48.1 (constants.%T.as_type.5d6)]
// CHECK:STDOUT:     %OptionalStorage.facet.loc6_44: %OptionalStorage.type = facet_value %T.as_type.loc6_44, (constants.%OptionalStorage.lookup_impl_witness.a98) [symbolic = %OptionalStorage.facet.loc6_25.2 (constants.%OptionalStorage.facet)]
// CHECK:STDOUT:     %.loc6_44: %OptionalStorage.type = converted %T.ref.loc6_43, %OptionalStorage.facet.loc6_44 [symbolic = %OptionalStorage.facet.loc6_25.2 (constants.%OptionalStorage.facet)]
// CHECK:STDOUT:     %Optional.loc6_44: type = class_type @Optional, @Optional(constants.%OptionalStorage.facet) [symbolic = %Optional.loc6_25.2 (constants.%Optional.4d3)]
// CHECK:STDOUT:     %.loc6_45: @HoldGeneric.%Optional.Some.type (%Optional.Some.type.087) = specific_constant imports.%Core.import_ref.48e, @Optional(constants.%OptionalStorage.facet) [symbolic = %Optional.Some (constants.%Optional.Some.bff)]
// CHECK:STDOUT:     %Some.ref: @HoldGeneric.%Optional.Some.type (%Optional.Some.type.087) = name_ref Some, %.loc6_45 [symbolic = %Optional.Some (constants.%Optional.Some.bff)]
// CHECK:STDOUT:     %a.ref: @HoldGeneric.%T.as_type.loc5_48.1 (%T.as_type.5d6) = name_ref a, %a
// CHECK:STDOUT:     %OptionalStorage.facet.loc6_52.1: %OptionalStorage.type = facet_value constants.%T.as_type.5d6, (constants.%OptionalStorage.lookup_impl_witness.a98) [symbolic = %OptionalStorage.facet.loc6_25.2 (constants.%OptionalStorage.facet)]
// CHECK:STDOUT:     %.loc6_52.1: %OptionalStorage.type = converted constants.%T.as_type.5d6, %OptionalStorage.facet.loc6_52.1 [symbolic = %OptionalStorage.facet.loc6_25.2 (constants.%OptionalStorage.facet)]
// CHECK:STDOUT:     %OptionalStorage.facet.loc6_52.2: %OptionalStorage.type = facet_value constants.%T.as_type.5d6, (constants.%OptionalStorage.lookup_impl_witness.a98) [symbolic = %OptionalStorage.facet.loc6_25.2 (constants.%OptionalStorage.facet)]
// CHECK:STDOUT:     %.loc6_52.2: %OptionalStorage.type = converted constants.%T.as_type.5d6, %OptionalStorage.facet.loc6_52.2 [symbolic = %OptionalStorage.facet.loc6_25.2 (constants.%OptionalStorage.facet)]
// CHECK:STDOUT:     %Optional.Some.specific_fn.loc6_45.1: <specific function> = specific_function %Some.ref, @Optional.Some(constants.%OptionalStorage.facet) [symbolic = %Optional.Some.specific_fn.loc6_45.2 (constants.%Optional.Some.specific_fn)]
// CHECK:STDOUT:     %.loc6_52.3: ref @HoldGeneric.%Optional.loc6_25.2 (%Optional.4d3) = temporary_storage
// CHECK:STDOUT:     %Optional.Some.call: init @HoldGeneric.%Optional.loc6_25.2 (%Optional.4d3) to %.loc6_52.3 = call %Optional.Some.specific_fn.loc6_45.1(%a.ref)
// CHECK:STDOUT:     %.loc6_52.4: ref @HoldGeneric.%Optional.loc6_25.2 (%Optional.4d3) = temporary %.loc6_52.3, %Optional.Some.call
// CHECK:STDOUT:     %.loc6_52.5: @HoldGeneric.%Optional.loc6_25.2 (%Optional.4d3) = acquire_value %.loc6_52.4
// CHECK:STDOUT:     %.loc6_25.1: type = splice_block %Optional.loc6_25.1 [symbolic = %Optional.loc6_25.2 (constants.%Optional.4d3)] {
// CHECK:STDOUT:       %Core.ref.loc6_10: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %Optional.ref.loc6_14: %Optional.type = name_ref Optional, imports.%Core.Optional [concrete = constants.%Optional.generic]
// CHECK:STDOUT:       %T.ref.loc6_24: %facet_type = name_ref T, %T.loc5_17.2 [symbolic = %T.loc5_17.1 (constants.%T.dc4)]
// CHECK:STDOUT:       %T.as_type.loc6_25: type = facet_access_type %T.ref.loc6_24 [symbolic = %T.as_type.loc5_48.1 (constants.%T.as_type.5d6)]
// CHECK:STDOUT:       %OptionalStorage.facet.loc6_25.1: %OptionalStorage.type = facet_value %T.as_type.loc6_25, (constants.%OptionalStorage.lookup_impl_witness.a98) [symbolic = %OptionalStorage.facet.loc6_25.2 (constants.%OptionalStorage.facet)]
// CHECK:STDOUT:       %.loc6_25.2: %OptionalStorage.type = converted %T.ref.loc6_24, %OptionalStorage.facet.loc6_25.1 [symbolic = %OptionalStorage.facet.loc6_25.2 (constants.%OptionalStorage.facet)]
// CHECK:STDOUT:       %Optional.loc6_25.1: type = class_type @Optional, @Optional(constants.%OptionalStorage.facet) [symbolic = %Optional.loc6_25.2 (constants.%Optional.4d3)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %o: @HoldGeneric.%Optional.loc6_25.2 (%Optional.4d3) = wrapper_binding o, %.loc6_52.5
// CHECK:STDOUT:     name_binding_decl {
// CHECK:STDOUT:       %o.patt.loc6_8.1: @HoldGeneric.%pattern_type.loc6 (%pattern_type.6d4) = value_binding_pattern o [symbolic = %o.patt.loc6_8.2 (constants.%o.patt)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %o.ref: @HoldGeneric.%Optional.loc6_25.2 (%Optional.4d3) = name_ref o, %o
// CHECK:STDOUT:     %.loc7: @HoldGeneric.%Optional.HasValue.type (%Optional.HasValue.type.b55) = specific_constant imports.%Core.import_ref.729, @Optional(constants.%OptionalStorage.facet) [symbolic = %Optional.HasValue (constants.%Optional.HasValue.da2)]
// CHECK:STDOUT:     %HasValue.ref: @HoldGeneric.%Optional.HasValue.type (%Optional.HasValue.type.b55) = name_ref HasValue, %.loc7 [symbolic = %Optional.HasValue (constants.%Optional.HasValue.da2)]
// CHECK:STDOUT:     %Optional.HasValue.bound: <bound method> = bound_method %o.ref, %HasValue.ref
// CHECK:STDOUT:     %Optional.HasValue.specific_fn.loc7_11.1: <specific function> = specific_function %HasValue.ref, @Optional.HasValue(constants.%OptionalStorage.facet) [symbolic = %Optional.HasValue.specific_fn.loc7_11.2 (constants.%Optional.HasValue.specific_fn.7a3)]
// CHECK:STDOUT:     %bound_method.loc7: <bound method> = bound_method %o.ref, %Optional.HasValue.specific_fn.loc7_11.1
// CHECK:STDOUT:     %Optional.HasValue.call: init bool = call %bound_method.loc7(%o.ref)
// CHECK:STDOUT:     %impl.elem2.loc6_52.1: @HoldGeneric.%.loc6_52.8 (%.545) = impl_witness_access constants.%Destroy.lookup_impl_witness.0cb, element2 [symbolic = %impl.elem2.loc6_52.2 (constants.%impl.elem2.407)]
// CHECK:STDOUT:     %bound_method.loc6_52.1: <bound method> = bound_method %.loc6_52.4, %impl.elem2.loc6_52.1
// CHECK:STDOUT:     %Destroy.facet.loc6_52.1: %Destroy.type = facet_value constants.%Optional.4d3, (constants.%Destroy.lookup_impl_witness.0cb) [symbolic = %Destroy.facet.loc6_52.3 (constants.%Destroy.facet.7e4)]
// CHECK:STDOUT:     %.loc6_52.6: %Destroy.type = converted constants.%Optional.4d3, %Destroy.facet.loc6_52.1 [symbolic = %Destroy.facet.loc6_52.3 (constants.%Destroy.facet.7e4)]
// CHECK:STDOUT:     %Destroy.facet.loc6_52.2: %Destroy.type = facet_value constants.%Optional.4d3, (constants.%Destroy.lookup_impl_witness.0cb) [symbolic = %Destroy.facet.loc6_52.3 (constants.%Destroy.facet.7e4)]
// CHECK:STDOUT:     %.loc6_52.7: %Destroy.type = converted constants.%Optional.4d3, %Destroy.facet.loc6_52.2 [symbolic = %Destroy.facet.loc6_52.3 (constants.%Destroy.facet.7e4)]
// CHECK:STDOUT:     %specific_impl_fn.loc6_52.1: <specific function> = specific_impl_function %impl.elem2.loc6_52.1, @Destroy.WithSelf.SelfDestruct(constants.%Destroy.facet.7e4) [symbolic = %specific_impl_fn.loc6_52.2 (constants.%specific_impl_fn.1c4)]
// CHECK:STDOUT:     %bound_method.loc6_52.2: <bound method> = bound_method %.loc6_52.4, %specific_impl_fn.loc6_52.1
// CHECK:STDOUT:     %Destroy.WithSelf.SelfDestruct.call: init %empty_tuple.type = call %bound_method.loc6_52.2(%.loc6_52.4)
// CHECK:STDOUT:     return %Optional.HasValue.call
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @HoldGeneric(constants.%T.dc4) {
// CHECK:STDOUT:   %T.patt.loc5_17.2 => constants.%T.patt.256
// CHECK:STDOUT:   %T.loc5_17.1 => constants.%T.dc4
// CHECK:STDOUT:   %T.as_type.loc5_48.1 => constants.%T.as_type.5d6
// CHECK:STDOUT:   %pattern_type.loc5 => constants.%pattern_type.0e9
// CHECK:STDOUT:   %a.param_patt.loc5_46.2 => constants.%a.param_patt
// CHECK:STDOUT:   %a.patt.loc5_46.2 => constants.%a.patt
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- unformed_pointer.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %DeclarePointer.type: type = fn_type @DeclarePointer [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %DeclarePointer: %DeclarePointer.type = struct_value () [concrete]
// CHECK:STDOUT:   %Optional.type: type = generic_class_type @Optional [concrete]
// CHECK:STDOUT:   %Optional.generic: %Optional.type = struct_value () [concrete]
// CHECK:STDOUT:   %OptionalStorage.type: type = facet_type <@OptionalStorage> [concrete]
// CHECK:STDOUT:   %Destroy.type: type = facet_type <@Destroy> [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %Int.type: type = generic_class_type @Int [concrete]
// CHECK:STDOUT:   %Int.generic: %Int.type = struct_value () [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %ptr.d08: type = ptr_type %i32 [concrete]
// CHECK:STDOUT:   %T.67d: type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %ptr.e8f: type = ptr_type %T.67d [symbolic]
// CHECK:STDOUT:   %Destroy.lookup_impl_witness.781: <witness> = lookup_impl_witness %ptr.e8f, @Destroy [symbolic]
// CHECK:STDOUT:   %Destroy.facet.e46: %Destroy.type = facet_value %ptr.e8f, (%Destroy.lookup_impl_witness.781) [symbolic]
// CHECK:STDOUT:   %MaybeUnformed.ddb: type = class_type @MaybeUnformed, @MaybeUnformed(%Destroy.facet.e46) [symbolic]
// CHECK:STDOUT:   %Destroy.lookup_impl_witness.ad0: <witness> = lookup_impl_witness %MaybeUnformed.ddb, @Destroy [symbolic]
// CHECK:STDOUT:   %Destroy.facet.270: %Destroy.type = facet_value %MaybeUnformed.ddb, (%Destroy.lookup_impl_witness.ad0) [symbolic]
// CHECK:STDOUT:   %OptionalStorage.impl_witness.0ce: <witness> = impl_witness imports.%OptionalStorage.impl_witness_table.110, @ptr.as.OptionalStorage.impl(%i32) [concrete]
// CHECK:STDOUT:   %OptionalStorage.facet.f91: %OptionalStorage.type = facet_value %ptr.d08, (%OptionalStorage.impl_witness.0ce) [concrete]
// CHECK:STDOUT:   %Optional.5b3: type = class_type @Optional, @Optional(%OptionalStorage.facet.f91) [concrete]
// CHECK:STDOUT:   %pattern_type.ef8: type = pattern_type %Optional.5b3 [concrete]
// CHECK:STDOUT:   %o.patt: %pattern_type.ef8 = ref_binding_pattern o [concrete]
// CHECK:STDOUT:   %o.var_patt: %pattern_type.ef8 = var_pattern %o.patt [concrete]
// CHECK:STDOUT:   %DefaultOrUnformed.type: type = facet_type <@DefaultOrUnformed> [concrete]
// CHECK:STDOUT:   %UnformedInit.type: type = facet_type <@UnformedInit> [concrete]
// CHECK:STDOUT:   %T.fef: %UnformedInit.type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %T.as_type.as.DefaultOrUnformed.impl.Op.type.215: type = fn_type @T.as_type.as.DefaultOrUnformed.impl.Op.2, @T.as_type.as.DefaultOrUnformed.impl.52f(%T.fef) [symbolic]
// CHECK:STDOUT:   %T.as_type.as.DefaultOrUnformed.impl.Op.f65: %T.as_type.as.DefaultOrUnformed.impl.Op.type.215 = struct_value () [symbolic]
// CHECK:STDOUT:   %UnformedInit.impl_witness.2d3: <witness> = impl_witness imports.%UnformedInit.impl_witness_table.bfc, @Optional.as.UnformedInit.impl(%i32) [concrete]
// CHECK:STDOUT:   %UnformedInit.facet: %UnformedInit.type = facet_value %Optional.5b3, (%UnformedInit.impl_witness.2d3) [concrete]
// CHECK:STDOUT:   %DefaultOrUnformed.impl_witness.31d: <witness> = impl_witness imports.%DefaultOrUnformed.impl_witness_table.8f5, @T.as_type.as.DefaultOrUnformed.impl.52f(%UnformedInit.facet) [concrete]
// CHECK:STDOUT:   %DefaultOrUnformed.facet: %DefaultOrUnformed.type = facet_value %Optional.5b3, (%DefaultOrUnformed.impl_witness.31d) [concrete]
// CHECK:STDOUT:   %self.param_patt.d96: %pattern_type.ef8 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.77d: %pattern_type.ef8 = wrapper_binding_pattern self, %self.param_patt.d96 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc6 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.4: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.4: type = fn_type @Destroy.WithSelf.Op.loc6 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.4: %Destroy.WithSelf.Op.type.ef016f.4 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.4: type = fn_type @Destroy.WithSelf.SelfDestruct.loc6 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.4: %Destroy.WithSelf.SelfDestruct.type.fbceb5.4 = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .Optional = %Core.Optional
// CHECK:STDOUT:     .Int = %Core.Int
// CHECK:STDOUT:     .DefaultOrUnformed = %Core.DefaultOrUnformed
// CHECK:STDOUT:     .Destroy = %Core.Destroy
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Optional: %Optional.type = import_ref Core//prelude/types/optional, Optional, loaded [concrete = constants.%Optional.generic]
// CHECK:STDOUT:   %Core.Int: %Int.type = import_ref Core//prelude/types/int, Int, loaded [concrete = constants.%Int.generic]
// CHECK:STDOUT:   %Core.import_ref.809: %Destroy.type = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @ptr.as.OptionalStorage.impl.%Destroy.facet.2 (constants.%Destroy.facet.270)]
// CHECK:STDOUT:   %Core.import_ref.105 = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.c9a = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.a90 = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.306 = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.3e3 = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %OptionalStorage.impl_witness_table.110 = impl_witness_table (%Core.import_ref.809, %Core.import_ref.105, %Core.import_ref.c9a, %Core.import_ref.a90, %Core.import_ref.306, %Core.import_ref.3e3), @ptr.as.OptionalStorage.impl [concrete]
// CHECK:STDOUT:   %Core.DefaultOrUnformed: type = import_ref Core//prelude/default, DefaultOrUnformed, loaded [concrete = constants.%DefaultOrUnformed.type]
// CHECK:STDOUT:   %Core.import_ref.083: @T.as_type.as.DefaultOrUnformed.impl.52f.%T.as_type.as.DefaultOrUnformed.impl.Op.type (%T.as_type.as.DefaultOrUnformed.impl.Op.type.215) = import_ref Core//prelude/default, loc{{\d+_\d+}}, loaded [symbolic = @T.as_type.as.DefaultOrUnformed.impl.52f.%T.as_type.as.DefaultOrUnformed.impl.Op (constants.%T.as_type.as.DefaultOrUnformed.impl.Op.f65)]
// CHECK:STDOUT:   %DefaultOrUnformed.impl_witness_table.8f5 = impl_witness_table (%Core.import_ref.083), @T.as_type.as.DefaultOrUnformed.impl.52f [concrete]
// CHECK:STDOUT:   %UnformedInit.impl_witness_table.bfc = impl_witness_table (), @Optional.as.UnformedInit.impl [concrete]
// CHECK:STDOUT:   %Core.Destroy: type = import_ref Core//prelude/destroy, Destroy, loaded [concrete = constants.%Destroy.type]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.4: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc6 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.4] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.ef8 = ref_param_pattern [concrete = constants.%self.param_patt.d96]
// CHECK:STDOUT:     %self.patt: %pattern_type.ef8 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.77d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %Optional.5b3 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %Optional.5b3 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.4: %Destroy.WithSelf.Op.type.ef016f.4 = fn_decl @Destroy.WithSelf.Op.loc6 [concrete = constants.%Destroy.WithSelf.Op.403171.4] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.ef8 = ref_param_pattern [concrete = constants.%self.param_patt.d96]
// CHECK:STDOUT:     %self.patt: %pattern_type.ef8 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.77d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %Optional.5b3 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %Optional.5b3 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %DeclarePointer.decl: %DeclarePointer.type = fn_decl @DeclarePointer [concrete = constants.%DeclarePointer] {} {}
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @DeclarePointer() {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %o.var: ref %Optional.5b3 = var_storage %o.var_patt
// CHECK:STDOUT:   %DefaultOrUnformed.facet: %DefaultOrUnformed.type = facet_value constants.%Optional.5b3, (constants.%DefaultOrUnformed.impl_witness.31d) [concrete = constants.%DefaultOrUnformed.facet]
// CHECK:STDOUT:   %.loc6_36.1: %DefaultOrUnformed.type = converted constants.%Optional.5b3, %DefaultOrUnformed.facet [concrete = constants.%DefaultOrUnformed.facet]
// CHECK:STDOUT:   %as_type: type = facet_access_type %.loc6_36.1 [concrete = constants.%Optional.5b3]
// CHECK:STDOUT:   %.loc6_36.2: type = converted %.loc6_36.1, %as_type [concrete = constants.%Optional.5b3]
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:   %T.as_type.as.DefaultOrUnformed.impl.Op.call: init %Optional.5b3 = call %T.as_type.as.DefaultOrUnformed.impl.Op.specific_fn()
// CHECK:STDOUT:   assign %o.var, %T.as_type.as.DefaultOrUnformed.impl.Op.call
// CHECK:STDOUT:   %.loc6_35.1: type = splice_block %Optional [concrete = constants.%Optional.5b3] {
// CHECK:STDOUT:     %Core.ref: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:     %Optional.ref: %Optional.type = name_ref Optional, imports.%Core.Optional [concrete = constants.%Optional.generic]
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %ptr: type = ptr_type %i32 [concrete = constants.%ptr.d08]
// CHECK:STDOUT:     %OptionalStorage.facet: %OptionalStorage.type = facet_value %ptr, (constants.%OptionalStorage.impl_witness.0ce) [concrete = constants.%OptionalStorage.facet.f91]
// CHECK:STDOUT:     %.loc6_35.2: %OptionalStorage.type = converted %ptr, %OptionalStorage.facet [concrete = constants.%OptionalStorage.facet.f91]
// CHECK:STDOUT:     %Optional: type = class_type @Optional, @Optional(constants.%OptionalStorage.facet.f91) [concrete = constants.%Optional.5b3]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %o: ref %Optional.5b3 = wrapper_binding o, %o.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %o.patt: %pattern_type.ef8 = ref_binding_pattern o [concrete = constants.%o.patt]
// CHECK:STDOUT:     %o.var_patt: %pattern_type.ef8 = var_pattern %o.patt [concrete = constants.%o.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound: <bound method> = bound_method %o.var, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.4
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound(%o.var)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc6(%self.param: ref %Optional.5b3) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc6(%self.param: ref %Optional.5b3) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc6(%self.param: ref %Optional.5b3) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.4(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.4(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
