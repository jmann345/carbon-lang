// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --dump-sem-ir-ranges=only
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/function/overload/generic_class_method_set.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/function/overload/generic_class_method_set.carbon

// An `overload fn` set declared inside a generic class (fork/overload/plan.md
// §1.B.5; D-OV-6 gate (ii) lifted at OV-2). The set's type records the class's
// self specific exactly as a member function's type does, and naming the set
// through `Box(i64)` substitutes that specific, so the bound set names the
// `Box(i64)` set value and each committed callee is a specific function of the
// selected member. The members are effectively non-generic within the
// specific: the enclosing specific supplies the class's bindings.
//
// Spelling per R3: the class parameter is `T: Core.Copy` (the plan's
// `T: type`) because `Make` copies its `t: T` parameter into the `tag` field,
// as toolchain/check/testdata/class/generic/member_type.carbon does.

// --- generic_class.carbon

library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
class Box(T: Core.Copy) {
  var tag: T;
  var total: i32;
  fn Make(x: i32, t: T) -> Box(T) { return {.tag = t, .total = x}; }
  overload fn Add(ref self, n: i32) { self.total = self.total + n; }
  overload fn Add(ref self, b: bool) { if (b) { self.total = self.total + 100; } }
  fn Get(self) -> i32 { return self.total; }
}

fn Use() -> i32 {
  var b: Box(i64) = Box(i64).Make(1, 0 as i64);
  b.Add(1);
  b.Add(true);
  return b.Get();
}
//@dump-sem-ir-end

// CHECK:STDOUT: --- generic_class.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %.Self.frozen.e58: type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %pattern_type.e81: type = pattern_type %Copy.type [concrete]
// CHECK:STDOUT:   %T.patt.fe6: %pattern_type.e81 = symbolic_binding_pattern T, 0 [symbolic]
// CHECK:STDOUT:   %T.f84: %Copy.type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %Box.type: type = generic_class_type @Box [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %Box.generic: %Box.type = struct_value () [concrete]
// CHECK:STDOUT:   %Box.fc8: type = class_type @Box, @Box(%T.f84) [symbolic]
// CHECK:STDOUT:   %T.as_type.c1c: type = facet_access_type %T.f84 [symbolic]
// CHECK:STDOUT:   %require_complete.d83: <witness> = require_complete_type %T.as_type.c1c [symbolic]
// CHECK:STDOUT:   %pattern_type.2c66b4.2: type = pattern_type %T.as_type.c1c [symbolic]
// CHECK:STDOUT:   %Box.elem.159: type = unbound_element_type %Box.fc8, %T.as_type.c1c [symbolic]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %Int.type: type = generic_class_type @Int [concrete]
// CHECK:STDOUT:   %Int.generic: %Int.type = struct_value () [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %Int.67af24.1: type = class_type @Int, @Int(%N) [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %Box.elem.adb: type = unbound_element_type %Box.fc8, %i32 [symbolic]
// CHECK:STDOUT:   %x.param_patt: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %x.patt: %pattern_type.6b6 = wrapper_binding_pattern x, %x.param_patt [concrete]
// CHECK:STDOUT:   %t.param_patt.adf: %pattern_type.2c66b4.2 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %t.patt.035: %pattern_type.2c66b4.2 = wrapper_binding_pattern t, %t.param_patt.adf [symbolic]
// CHECK:STDOUT:   %.7dc: Core.Form = init_form %Box.fc8 [symbolic]
// CHECK:STDOUT:   %pattern_type.72a: type = pattern_type %Box.fc8 [symbolic]
// CHECK:STDOUT:   %return.param_patt.318: %pattern_type.72a = out_param_pattern [symbolic]
// CHECK:STDOUT:   %return.patt.f28: %pattern_type.72a = return_slot_pattern %return.param_patt.318, %Box.fc8 [symbolic]
// CHECK:STDOUT:   %Box.Make.type.fef: type = fn_type @Box.Make, @Box(%T.f84) [symbolic]
// CHECK:STDOUT:   %Box.Make.22d: %Box.Make.type.fef = struct_value () [symbolic]
// CHECK:STDOUT:   %self.param_patt.99e: %pattern_type.72a = ref_param_pattern [symbolic]
// CHECK:STDOUT:   %self.patt.0ce: %pattern_type.72a = wrapper_binding_pattern self, %self.param_patt.99e [symbolic]
// CHECK:STDOUT:   %n.param_patt: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %n.patt: %pattern_type.6b6 = wrapper_binding_pattern n, %n.param_patt [concrete]
// CHECK:STDOUT:   %Box.Add.type.1628b5.1: type = fn_type @Box.Add.loc9, @Box(%T.f84) [symbolic]
// CHECK:STDOUT:   %Box.Add.b04003.1: %Box.Add.type.1628b5.1 = struct_value () [symbolic]
// CHECK:STDOUT:   %Box.Add.overload_set.type.e92: type = overload_set_type @Box.Add.overload_set, @Box(%T.f84) [symbolic]
// CHECK:STDOUT:   %Box.Add.overload_set.value.cd4: %Box.Add.overload_set.type.e92 = overload_set_value @Box.Add.overload_set [symbolic]
// CHECK:STDOUT:   %pattern_type.831: type = pattern_type bool [concrete]
// CHECK:STDOUT:   %b.param_patt: %pattern_type.831 = value_param_pattern [concrete]
// CHECK:STDOUT:   %b.patt.d80: %pattern_type.831 = wrapper_binding_pattern b, %b.param_patt [concrete]
// CHECK:STDOUT:   %Box.Add.type.1628b5.2: type = fn_type @Box.Add.loc10, @Box(%T.f84) [symbolic]
// CHECK:STDOUT:   %Box.Add.b04003.2: %Box.Add.type.1628b5.2 = struct_value () [symbolic]
// CHECK:STDOUT:   %self.param_patt.283: %pattern_type.72a = value_param_pattern [symbolic]
// CHECK:STDOUT:   %self.patt.a4c: %pattern_type.72a = wrapper_binding_pattern self, %self.param_patt.283 [symbolic]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %Box.Get.type.b71: type = fn_type @Box.Get, @Box(%T.f84) [symbolic]
// CHECK:STDOUT:   %Box.Get.c3a: %Box.Get.type.b71 = struct_value () [symbolic]
// CHECK:STDOUT:   %struct_type.tag.total.9eb: type = struct_type {.tag: %T.as_type.c1c, .total: %i32} [symbolic]
// CHECK:STDOUT:   %complete_type.081: <witness> = complete_type_witness %struct_type.tag.total.9eb [symbolic]
// CHECK:STDOUT:   %require_complete.f3c: <witness> = require_complete_type %Box.fc8 [symbolic]
// CHECK:STDOUT:   %Copy.lookup_impl_witness.d9c: <witness> = lookup_impl_witness %T.f84, @Copy [symbolic]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.c85f21.2: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%T.f84) [symbolic]
// CHECK:STDOUT:   %.c29: type = fn_type_with_self_type %Copy.WithSelf.Op.type.c85f21.2, %T.f84 [symbolic]
// CHECK:STDOUT:   %impl.elem0.bd2: %.c29 = impl_witness_access %Copy.lookup_impl_witness.d9c, element0 [symbolic]
// CHECK:STDOUT:   %specific_impl_fn.e2a: <specific function> = specific_impl_function %impl.elem0.bd2, @Copy.WithSelf.Op(%T.f84) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet.1e1: %Copy.type = facet_value %i32, (%Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.381: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.1e1) [concrete]
// CHECK:STDOUT:   %.737: type = fn_type_with_self_type %Copy.WithSelf.Op.type.381, %Copy.facet.1e1 [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn.287: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %AddWith.type.2ef: type = generic_interface_type @AddWith [concrete]
// CHECK:STDOUT:   %AddWith.generic: %AddWith.type.2ef = struct_value () [concrete]
// CHECK:STDOUT:   %AddWith.type.be9: type = facet_type <@AddWith, @AddWith(%i32)> [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.610: type = fn_type @Int.as.AddWith.impl.Op.1, @Int.as.AddWith.impl.3af(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.732: %Int.as.AddWith.impl.Op.type.610 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.type.0ff: type = generic_interface_type @ImplicitAs [concrete]
// CHECK:STDOUT:   %ImplicitAs.generic: %ImplicitAs.type.0ff = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.f7de31.1: type = facet_type <@ImplicitAs, @ImplicitAs(%Int.67af24.1)> [symbolic]
// CHECK:STDOUT:   %U.4e6: %ImplicitAs.type.f7de31.1 = symbolic_binding U, 1 [symbolic]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.1eac76.1: type = fn_type @Int.as.AddWith.impl.Op.2, @Int.as.AddWith.impl.155(%N, %U.4e6) [symbolic]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.978dbc.1: %Int.as.AddWith.impl.Op.type.1eac76.1 = struct_value () [symbolic]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.1eac76.2: type = fn_type @Int.as.AddWith.impl.Op.3, @Int.as.AddWith.impl.155(%N, %U.4e6) [symbolic]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.978dbc.2: %Int.as.AddWith.impl.Op.type.1eac76.2 = struct_value () [symbolic]
// CHECK:STDOUT:   %AddWith.type.832: type = facet_type <@AddWith, @AddWith(Core.IntLiteral)> [concrete]
// CHECK:STDOUT:   %AddWith.impl_witness.833: <witness> = impl_witness imports.%AddWith.impl_witness_table.6b4, @Int.as.AddWith.impl.3af(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.056: type = fn_type @Int.as.AddWith.impl.Op.1, @Int.as.AddWith.impl.3af(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.365: %Int.as.AddWith.impl.Op.type.056 = struct_value () [concrete]
// CHECK:STDOUT:   %AddWith.facet.76a: %AddWith.type.be9 = facet_value %i32, (%AddWith.impl_witness.833) [concrete]
// CHECK:STDOUT:   %AddWith.WithSelf.Op.type.02a: type = fn_type @AddWith.WithSelf.Op, @AddWith.WithSelf(%i32, %AddWith.facet.76a) [concrete]
// CHECK:STDOUT:   %.d47: type = fn_type_with_self_type %AddWith.WithSelf.Op.type.02a, %AddWith.facet.76a [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.specific_fn.f25: <specific function> = specific_function %Int.as.AddWith.impl.Op.365, @Int.as.AddWith.impl.Op.1(%int_32) [concrete]
// CHECK:STDOUT:   %int_100.44f: Core.IntLiteral = int_value 100 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %To.fe9: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %AddWith.impl_witness.aa4: <witness> = impl_witness imports.%AddWith.impl_witness_table.b21, @Int.as.AddWith.impl.155(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.bddb3c.1: type = fn_type @Int.as.AddWith.impl.Op.3, @Int.as.AddWith.impl.155(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.1fd531.1: %Int.as.AddWith.impl.Op.type.bddb3c.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.bddb3c.2: type = fn_type @Int.as.AddWith.impl.Op.2, @Int.as.AddWith.impl.155(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.1fd531.2: %Int.as.AddWith.impl.Op.type.bddb3c.2 = struct_value () [concrete]
// CHECK:STDOUT:   %AddWith.facet.3de: %AddWith.type.832 = facet_value %i32, (%AddWith.impl_witness.aa4) [concrete]
// CHECK:STDOUT:   %AddWith.WithSelf.Op.type.b60: type = fn_type @AddWith.WithSelf.Op, @AddWith.WithSelf(Core.IntLiteral, %AddWith.facet.3de) [concrete]
// CHECK:STDOUT:   %.fbe: type = fn_type_with_self_type %AddWith.WithSelf.Op.type.b60, %AddWith.facet.3de [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.specific_fn.273a3e.1: <specific function> = specific_function %Int.as.AddWith.impl.Op.1fd531.2, @Int.as.AddWith.impl.Op.2(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.specific_fn.273a3e.2: <specific function> = specific_function %Int.as.AddWith.impl.Op.1fd531.1, @Int.as.AddWith.impl.Op.3(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.2f5: <bound method> = bound_method %int_100.44f, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.565: <bound method> = bound_method %int_100.44f, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_100.d3c: %i32 = int_value 100 [concrete]
// CHECK:STDOUT:   %Use.type: type = fn_type @Use [concrete]
// CHECK:STDOUT:   %Use: %Use.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %Copy.impl_witness.8cc: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_64) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.494: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_64) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.d73: %Int.as.Copy.impl.Op.type.494 = struct_value () [concrete]
// CHECK:STDOUT:   %i64.builtin: type = int_type signed, %int_64 [concrete]
// CHECK:STDOUT:   %complete_type.4a1: <witness> = complete_type_witness %i64.builtin [concrete]
// CHECK:STDOUT:   %Copy.facet.4e9: %Copy.type = facet_value %i64, (%Copy.impl_witness.8cc) [concrete]
// CHECK:STDOUT:   %Box.ecf: type = class_type @Box, @Box(%Copy.facet.4e9) [concrete]
// CHECK:STDOUT:   %Box.elem.e42: type = unbound_element_type %Box.ecf, %i64 [concrete]
// CHECK:STDOUT:   %Box.elem.269: type = unbound_element_type %Box.ecf, %i32 [concrete]
// CHECK:STDOUT:   %Box.Make.type.75b: type = fn_type @Box.Make, @Box(%Copy.facet.4e9) [concrete]
// CHECK:STDOUT:   %Box.Make.a2e: %Box.Make.type.75b = struct_value () [concrete]
// CHECK:STDOUT:   %Box.Add.type.0225c6.1: type = fn_type @Box.Add.loc9, @Box(%Copy.facet.4e9) [concrete]
// CHECK:STDOUT:   %Box.Add.a2595a.1: %Box.Add.type.0225c6.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Box.Add.overload_set.type.e34: type = overload_set_type @Box.Add.overload_set, @Box(%Copy.facet.4e9) [concrete]
// CHECK:STDOUT:   %Box.Add.overload_set.value.a4e: %Box.Add.overload_set.type.e34 = overload_set_value @Box.Add.overload_set [concrete]
// CHECK:STDOUT:   %Box.Add.type.0225c6.2: type = fn_type @Box.Add.loc10, @Box(%Copy.facet.4e9) [concrete]
// CHECK:STDOUT:   %Box.Add.a2595a.2: %Box.Add.type.0225c6.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Box.Get.type.10a: type = fn_type @Box.Get, @Box(%Copy.facet.4e9) [concrete]
// CHECK:STDOUT:   %Box.Get.7c5: %Box.Get.type.10a = struct_value () [concrete]
// CHECK:STDOUT:   %struct_type.tag.total.f3f: type = struct_type {.tag: %i64, .total: %i32} [concrete]
// CHECK:STDOUT:   %complete_type.84e: <witness> = complete_type_witness %struct_type.tag.total.f3f [concrete]
// CHECK:STDOUT:   %pattern_type.60e: type = pattern_type %Box.ecf [concrete]
// CHECK:STDOUT:   %b.patt.931: %pattern_type.60e = ref_binding_pattern b [concrete]
// CHECK:STDOUT:   %b.var_patt: %pattern_type.60e = var_pattern %b.patt.931 [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %As.type.116: type = generic_interface_type @As [concrete]
// CHECK:STDOUT:   %As.generic: %As.type.116 = struct_value () [concrete]
// CHECK:STDOUT:   %As.type.998: type = facet_type <@As, @As(%i64)> [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.type.c5d: type = fn_type @Core.IntLiteral.as.As.impl.Convert, @Core.IntLiteral.as.As.impl.f25(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.6ee: %Core.IntLiteral.as.As.impl.Convert.type.c5d = struct_value () [symbolic]
// CHECK:STDOUT:   %As.impl_witness.0fe: <witness> = impl_witness imports.%As.impl_witness_table.d22, @Core.IntLiteral.as.As.impl.f25(%int_64) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.type.1a1: type = fn_type @Core.IntLiteral.as.As.impl.Convert, @Core.IntLiteral.as.As.impl.f25(%int_64) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.3d9: %Core.IntLiteral.as.As.impl.Convert.type.1a1 = struct_value () [concrete]
// CHECK:STDOUT:   %As.facet: %As.type.998 = facet_value Core.IntLiteral, (%As.impl_witness.0fe) [concrete]
// CHECK:STDOUT:   %As.WithSelf.Convert.type.7f7: type = fn_type @As.WithSelf.Convert, @As.WithSelf(%i64, %As.facet) [concrete]
// CHECK:STDOUT:   %.8fd: type = fn_type_with_self_type %As.WithSelf.Convert.type.7f7, %As.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.bound: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.As.impl.Convert.3d9 [concrete]
// CHECK:STDOUT:   %pattern_type.f57: type = pattern_type %i64 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.As.impl.Convert.3d9, @Core.IntLiteral.as.As.impl.Convert(%int_64) [concrete]
// CHECK:STDOUT:   %bound_method.585: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.As.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_0.2e4: %i64 = int_value 0 [concrete]
// CHECK:STDOUT:   %t.param_patt.682: %pattern_type.f57 = value_param_pattern [concrete]
// CHECK:STDOUT:   %t.patt.079: %pattern_type.f57 = wrapper_binding_pattern t, %t.param_patt.682 [concrete]
// CHECK:STDOUT:   %.c50: Core.Form = init_form %Box.ecf [concrete]
// CHECK:STDOUT:   %return.param_patt.c17: %pattern_type.60e = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.016: %pattern_type.60e = return_slot_pattern %return.param_patt.c17, %Box.ecf [concrete]
// CHECK:STDOUT:   %Box.Make.specific_fn: <specific function> = specific_function %Box.Make.a2e, @Box.Make(%Copy.facet.4e9) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.953: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT:   %self.param_patt.359: %pattern_type.60e = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.453: %pattern_type.60e = wrapper_binding_pattern self, %self.param_patt.359 [concrete]
// CHECK:STDOUT:   %Box.Add.specific_fn.784a5d.1: <specific function> = specific_function %Box.Add.a2595a.1, @Box.Add.loc9(%Copy.facet.4e9) [concrete]
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete]
// CHECK:STDOUT:   %Box.Add.specific_fn.784a5d.2: <specific function> = specific_function %Box.Add.a2595a.2, @Box.Add.loc10(%Copy.facet.4e9) [concrete]
// CHECK:STDOUT:   %self.param_patt.e92: %pattern_type.60e = value_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.692: %pattern_type.60e = wrapper_binding_pattern self, %self.param_patt.e92 [concrete]
// CHECK:STDOUT:   %Box.Get.specific_fn: <specific function> = specific_function %Box.Get.7c5, @Box.Get(%Copy.facet.4e9) [concrete]
// CHECK:STDOUT:   %Destroy.type: type = facet_type <@Destroy> [concrete]
// CHECK:STDOUT:   %self.param_patt.108: %pattern_type.f57 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.5f4: %pattern_type.f57 = wrapper_binding_pattern self, %self.param_patt.108 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc15_3.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.1: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.1: type = fn_type @Destroy.WithSelf.Op.loc15_3.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.1: %Destroy.WithSelf.Op.type.ef016f.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.1: type = fn_type @Destroy.WithSelf.SelfDestruct.loc15_3.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.1: %Destroy.WithSelf.SelfDestruct.type.fbceb5.1 = struct_value () [concrete]
// CHECK:STDOUT:   %self.param_patt.705: %pattern_type.6b6 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.70d: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt.705 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc15_3.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.2: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.2: type = fn_type @Destroy.WithSelf.Op.loc15_3.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.2: %Destroy.WithSelf.Op.type.ef016f.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.2: type = fn_type @Destroy.WithSelf.SelfDestruct.loc15_3.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.2: %Destroy.WithSelf.SelfDestruct.type.fbceb5.2 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.5ec: type = pattern_type %struct_type.tag.total.f3f [concrete]
// CHECK:STDOUT:   %self.param_patt.10e: %pattern_type.5ec = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.549: %pattern_type.5ec = wrapper_binding_pattern self, %self.param_patt.10e [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc15_3.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.3: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.3: type = fn_type @Destroy.WithSelf.Op.loc15_3.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.3: %Destroy.WithSelf.Op.type.ef016f.3 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc15_3.4 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.4: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.4: type = fn_type @Destroy.WithSelf.Op.loc15_3.4 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.4: %Destroy.WithSelf.Op.type.ef016f.4 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.4: type = fn_type @Destroy.WithSelf.SelfDestruct.loc15_3.4 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.4: %Destroy.WithSelf.SelfDestruct.type.fbceb5.4 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.5c1: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.4e9) [concrete]
// CHECK:STDOUT:   %.826: type = fn_type_with_self_type %Copy.WithSelf.Op.type.5c1, %Copy.facet.4e9 [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn.b95: <specific function> = specific_function %Int.as.Copy.impl.Op.d73, @Int.as.Copy.impl.Op(%int_64) [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .Copy = %Core.Copy
// CHECK:STDOUT:     .Int = %Core.Int
// CHECK:STDOUT:     .Bool = %Core.Bool
// CHECK:STDOUT:     .AddWith = %Core.AddWith
// CHECK:STDOUT:     .ImplicitAs = %Core.ImplicitAs
// CHECK:STDOUT:     .As = %Core.As
// CHECK:STDOUT:     .Destroy = %Core.Destroy
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Copy: type = import_ref Core//prelude/copy, Copy, loaded [concrete = constants.%Copy.type]
// CHECK:STDOUT:   %Core.Int: %Int.type = import_ref Core//prelude/types/int, Int, loaded [concrete = constants.%Int.generic]
// CHECK:STDOUT:   %Core.Bool: type = import_ref Core//prelude/types/bool, Bool, loaded [concrete = bool]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.AddWith: %AddWith.type.2ef = import_ref Core//prelude/operators/arithmetic, AddWith, loaded [concrete = constants.%AddWith.generic]
// CHECK:STDOUT:   %Core.import_ref.b4fd3a.1 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.684: @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op.type (%Int.as.AddWith.impl.Op.type.610) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op (constants.%Int.as.AddWith.impl.Op.732)]
// CHECK:STDOUT:   %AddWith.impl_witness_table.6b4 = impl_witness_table (%Core.import_ref.b4fd3a.1, %Core.import_ref.684), @Int.as.AddWith.impl.3af [concrete]
// CHECK:STDOUT:   %Core.import_ref.b4fd3a.2 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.8a3a: @Int.as.AddWith.impl.155.%Int.as.AddWith.impl.Op.type.2 (%Int.as.AddWith.impl.Op.type.1eac76.1) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.AddWith.impl.155.%Int.as.AddWith.impl.Op.2 (constants.%Int.as.AddWith.impl.Op.978dbc.1)]
// CHECK:STDOUT:   %AddWith.impl_witness_table.b21 = impl_witness_table (%Core.import_ref.b4fd3a.2, %Core.import_ref.8a3a), @Int.as.AddWith.impl.155 [concrete]
// CHECK:STDOUT:   %Core.Op.410: @Int.as.AddWith.impl.155.%Int.as.AddWith.impl.Op.type.1 (%Int.as.AddWith.impl.Op.type.1eac76.2) = import_ref Core//prelude/types/int, Op, loaded [symbolic = @Int.as.AddWith.impl.155.%Int.as.AddWith.impl.Op.1 (constants.%Int.as.AddWith.impl.Op.978dbc.2)]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.ImplicitAs: %ImplicitAs.type.0ff = import_ref Core//prelude/operators/as, ImplicitAs, loaded [concrete = constants.%ImplicitAs.generic]
// CHECK:STDOUT:   %Core.As: %As.type.116 = import_ref Core//prelude/operators/as, As, loaded [concrete = constants.%As.generic]
// CHECK:STDOUT:   %Core.import_ref.64b: @Core.IntLiteral.as.As.impl.f25.%Core.IntLiteral.as.As.impl.Convert.type (%Core.IntLiteral.as.As.impl.Convert.type.c5d) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.As.impl.f25.%Core.IntLiteral.as.As.impl.Convert (constants.%Core.IntLiteral.as.As.impl.Convert.6ee)]
// CHECK:STDOUT:   %As.impl_witness_table.d22 = impl_witness_table (%Core.import_ref.64b), @Core.IntLiteral.as.As.impl.f25 [concrete]
// CHECK:STDOUT:   %Core.Destroy: type = import_ref Core//prelude/destroy, Destroy, loaded [concrete = constants.%Destroy.type]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.1: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc15_3.1 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.1] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.f57 = ref_param_pattern [concrete = constants.%self.param_patt.108]
// CHECK:STDOUT:     %self.patt: %pattern_type.f57 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.5f4]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i64 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i64 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.1: %Destroy.WithSelf.Op.type.ef016f.1 = fn_decl @Destroy.WithSelf.Op.loc15_3.1 [concrete = constants.%Destroy.WithSelf.Op.403171.1] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.f57 = ref_param_pattern [concrete = constants.%self.param_patt.108]
// CHECK:STDOUT:     %self.patt: %pattern_type.f57 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.5f4]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i64 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i64 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.2: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc15_3.2 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.2] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6b6 = ref_param_pattern [concrete = constants.%self.param_patt.705]
// CHECK:STDOUT:     %self.patt: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.70d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i32 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i32 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.2: %Destroy.WithSelf.Op.type.ef016f.2 = fn_decl @Destroy.WithSelf.Op.loc15_3.2 [concrete = constants.%Destroy.WithSelf.Op.403171.2] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6b6 = ref_param_pattern [concrete = constants.%self.param_patt.705]
// CHECK:STDOUT:     %self.patt: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.70d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i32 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i32 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.3: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc15_3.3 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.3] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.5ec = ref_param_pattern [concrete = constants.%self.param_patt.10e]
// CHECK:STDOUT:     %self.patt: %pattern_type.5ec = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.549]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %struct_type.tag.total.f3f = ref_param call_param0
// CHECK:STDOUT:     %self: ref %struct_type.tag.total.f3f = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.3: %Destroy.WithSelf.Op.type.ef016f.3 = fn_decl @Destroy.WithSelf.Op.loc15_3.3 [concrete = constants.%Destroy.WithSelf.Op.403171.3] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.5ec = ref_param_pattern [concrete = constants.%self.param_patt.10e]
// CHECK:STDOUT:     %self.patt: %pattern_type.5ec = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.549]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %struct_type.tag.total.f3f = ref_param call_param0
// CHECK:STDOUT:     %self: ref %struct_type.tag.total.f3f = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.4: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc15_3.4 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.4] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.60e = ref_param_pattern [concrete = constants.%self.param_patt.359]
// CHECK:STDOUT:     %self.patt: %pattern_type.60e = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.453]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %Box.ecf = ref_param call_param0
// CHECK:STDOUT:     %self: ref %Box.ecf = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.4: %Destroy.WithSelf.Op.type.ef016f.4 = fn_decl @Destroy.WithSelf.Op.loc15_3.4 [concrete = constants.%Destroy.WithSelf.Op.403171.4] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.60e = ref_param_pattern [concrete = constants.%self.param_patt.359]
// CHECK:STDOUT:     %self.patt: %pattern_type.60e = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.453]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %Box.ecf = ref_param call_param0
// CHECK:STDOUT:     %self: ref %Box.ecf = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Box.decl: %Box.type = class_decl @Box [concrete = constants.%Box.generic] {
// CHECK:STDOUT:     %T.patt.loc5_12.1: %pattern_type.e81 = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc5_12.2 (constants.%T.patt.fe6)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc5: type = splice_block %Copy.ref [concrete = constants.%Copy.type] {
// CHECK:STDOUT:       %.Self.frozen: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen.e58]
// CHECK:STDOUT:       %Core.ref: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %Copy.ref: type = name_ref Copy, imports.%Core.Copy [concrete = constants.%Copy.type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc5_12.2: %Copy.type = symbolic_binding T, 0 [symbolic = %T.loc5_12.1 (constants.%T.f84)]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Use.decl: %Use.type = fn_decl @Use [concrete = constants.%Use] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc14: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param0
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic class @Box(%T.loc5_12.2: %Copy.type) {
// CHECK:STDOUT:   %T.patt.loc5_12.2: %pattern_type.e81 = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc5_12.2 (constants.%T.patt.fe6)]
// CHECK:STDOUT:   %T.loc5_12.1: %Copy.type = symbolic_binding T, 0 [symbolic = %T.loc5_12.1 (constants.%T.f84)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %T.as_type.loc6_12.2: type = facet_access_type %T.loc5_12.1 [symbolic = %T.as_type.loc6_12.2 (constants.%T.as_type.c1c)]
// CHECK:STDOUT:   %require_complete: <witness> = require_complete_type %T.as_type.loc6_12.2 [symbolic = %require_complete (constants.%require_complete.d83)]
// CHECK:STDOUT:   %Box: type = class_type @Box, @Box(%T.loc5_12.1) [symbolic = %Box (constants.%Box.fc8)]
// CHECK:STDOUT:   %Box.elem.loc6: type = unbound_element_type %Box, %T.as_type.loc6_12.2 [symbolic = %Box.elem.loc6 (constants.%Box.elem.159)]
// CHECK:STDOUT:   %Box.elem.loc7: type = unbound_element_type %Box, constants.%i32 [symbolic = %Box.elem.loc7 (constants.%Box.elem.adb)]
// CHECK:STDOUT:   %Box.Make.type: type = fn_type @Box.Make, @Box(%T.loc5_12.1) [symbolic = %Box.Make.type (constants.%Box.Make.type.fef)]
// CHECK:STDOUT:   %Box.Make: @Box.%Box.Make.type (%Box.Make.type.fef) = struct_value () [symbolic = %Box.Make (constants.%Box.Make.22d)]
// CHECK:STDOUT:   %Box.Add.type.loc9: type = fn_type @Box.Add.loc9, @Box(%T.loc5_12.1) [symbolic = %Box.Add.type.loc9 (constants.%Box.Add.type.1628b5.1)]
// CHECK:STDOUT:   %Box.Add.loc9: @Box.%Box.Add.type.loc9 (%Box.Add.type.1628b5.1) = struct_value () [symbolic = %Box.Add.loc9 (constants.%Box.Add.b04003.1)]
// CHECK:STDOUT:   %Box.Add.overload_set.type: type = overload_set_type @Box.Add.overload_set, @Box(%T.loc5_12.1) [symbolic = %Box.Add.overload_set.type (constants.%Box.Add.overload_set.type.e92)]
// CHECK:STDOUT:   %Box.Add.overload_set.value.loc9_37.2: @Box.%Box.Add.overload_set.type (%Box.Add.overload_set.type.e92) = overload_set_value @Box.Add.overload_set [symbolic = %Box.Add.overload_set.value.loc9_37.2 (constants.%Box.Add.overload_set.value.cd4)]
// CHECK:STDOUT:   %Box.Add.type.loc10: type = fn_type @Box.Add.loc10, @Box(%T.loc5_12.1) [symbolic = %Box.Add.type.loc10 (constants.%Box.Add.type.1628b5.2)]
// CHECK:STDOUT:   %Box.Add.loc10: @Box.%Box.Add.type.loc10 (%Box.Add.type.1628b5.2) = struct_value () [symbolic = %Box.Add.loc10 (constants.%Box.Add.b04003.2)]
// CHECK:STDOUT:   %Box.Get.type: type = fn_type @Box.Get, @Box(%T.loc5_12.1) [symbolic = %Box.Get.type (constants.%Box.Get.type.b71)]
// CHECK:STDOUT:   %Box.Get: @Box.%Box.Get.type (%Box.Get.type.b71) = struct_value () [symbolic = %Box.Get (constants.%Box.Get.c3a)]
// CHECK:STDOUT:   %struct_type.tag.total: type = struct_type {.tag: @Box.%T.as_type.loc6_12.2 (%T.as_type.c1c), .total: %i32} [symbolic = %struct_type.tag.total (constants.%struct_type.tag.total.9eb)]
// CHECK:STDOUT:   %complete_type.loc12_1.2: <witness> = complete_type_witness %struct_type.tag.total [symbolic = %complete_type.loc12_1.2 (constants.%complete_type.081)]
// CHECK:STDOUT:
// CHECK:STDOUT:   class {
// CHECK:STDOUT:     %field_decl.loc6: @Box.%Box.elem.loc6 (%Box.elem.159) = field_decl tag, element0, %.loc6 in [concrete] {
// CHECK:STDOUT:       %T.ref: %Copy.type = name_ref T, %T.loc5_12.2 [symbolic = %T.loc5_12.1 (constants.%T.f84)]
// CHECK:STDOUT:       %T.as_type.loc6_12.1: type = facet_access_type %T.ref [symbolic = %T.as_type.loc6_12.2 (constants.%T.as_type.c1c)]
// CHECK:STDOUT:       %.loc6: type = converted %T.ref, %T.as_type.loc6_12.1 [symbolic = %T.as_type.loc6_12.2 (constants.%T.as_type.c1c)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %field_decl.loc7: @Box.%Box.elem.loc7 (%Box.elem.adb) = field_decl total, element1, %i32 in [concrete] {
// CHECK:STDOUT:       %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %Box.Make.decl: @Box.%Box.Make.type (%Box.Make.type.fef) = fn_decl @Box.Make [symbolic = @Box.%Box.Make (constants.%Box.Make.22d)] {
// CHECK:STDOUT:       %x.param_patt: %pattern_type.6b6 = value_param_pattern [concrete = constants.%x.param_patt]
// CHECK:STDOUT:       %x.patt: %pattern_type.6b6 = wrapper_binding_pattern x, %x.param_patt [concrete = constants.%x.patt]
// CHECK:STDOUT:       %t.param_patt.loc8_20.1: @Box.Make.%pattern_type.loc8_20 (%pattern_type.2c66b4.2) = value_param_pattern [symbolic = %t.param_patt.loc8_20.2 (constants.%t.param_patt.adf)]
// CHECK:STDOUT:       %t.patt.loc8_20.1: @Box.Make.%pattern_type.loc8_20 (%pattern_type.2c66b4.2) = wrapper_binding_pattern t, %t.param_patt.loc8_20.1 [symbolic = %t.patt.loc8_20.2 (constants.%t.patt.035)]
// CHECK:STDOUT:       %return.param_patt.loc8_33.1: @Box.Make.%pattern_type.loc8_33 (%pattern_type.72a) = out_param_pattern [symbolic = %return.param_patt.loc8_33.2 (constants.%return.param_patt.318)]
// CHECK:STDOUT:       %return.patt.loc8_25.1: @Box.Make.%pattern_type.loc8_33 (%pattern_type.72a) = return_slot_pattern %return.param_patt.loc8_33.1, %Box.loc8_33.2 [symbolic = %return.patt.loc8_25.2 (constants.%return.patt.f28)]
// CHECK:STDOUT:     } {
// CHECK:STDOUT:       %Box.ref: %Box.type = name_ref Box, file.%Box.decl [concrete = constants.%Box.generic]
// CHECK:STDOUT:       %T.ref.loc8_32: %Copy.type = name_ref T, @Box.%T.loc5_12.2 [symbolic = %T (constants.%T.f84)]
// CHECK:STDOUT:       %Box.loc8_33.2: type = class_type @Box, @Box(constants.%T.f84) [symbolic = %Box.loc8_33.1 (constants.%Box.fc8)]
// CHECK:STDOUT:       %.loc8_33.2: Core.Form = init_form %Box.loc8_33.2 [symbolic = %.loc8_33.1 (constants.%.7dc)]
// CHECK:STDOUT:       %x.param: %i32 = value_param call_param0
// CHECK:STDOUT:       %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %x: %i32 = wrapper_binding x, %x.param
// CHECK:STDOUT:       %t.param: @Box.Make.%T.as_type.loc8_22.1 (%T.as_type.c1c) = value_param call_param1
// CHECK:STDOUT:       %.loc8_22.1: type = splice_block %.loc8_22.2 [symbolic = %T.as_type.loc8_22.1 (constants.%T.as_type.c1c)] {
// CHECK:STDOUT:         %T.ref.loc8_22: %Copy.type = name_ref T, @Box.%T.loc5_12.2 [symbolic = %T (constants.%T.f84)]
// CHECK:STDOUT:         %T.as_type.loc8_22.2: type = facet_access_type %T.ref.loc8_22 [symbolic = %T.as_type.loc8_22.1 (constants.%T.as_type.c1c)]
// CHECK:STDOUT:         %.loc8_22.2: type = converted %T.ref.loc8_22, %T.as_type.loc8_22.2 [symbolic = %T.as_type.loc8_22.1 (constants.%T.as_type.c1c)]
// CHECK:STDOUT:       }
// CHECK:STDOUT:       %t: @Box.Make.%T.as_type.loc8_22.1 (%T.as_type.c1c) = wrapper_binding t, %t.param
// CHECK:STDOUT:       %return.param: ref @Box.Make.%Box.loc8_33.1 (%Box.fc8) = out_param call_param2
// CHECK:STDOUT:       %return: ref @Box.Make.%Box.loc8_33.1 (%Box.fc8) = return_slot %return.param
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %Box.Add.decl.loc9: @Box.%Box.Add.type.loc9 (%Box.Add.type.1628b5.1) = fn_decl @Box.Add.loc9 [symbolic = @Box.%Box.Add.loc9 (constants.%Box.Add.b04003.1)] {
// CHECK:STDOUT:       %self.param_patt.loc9_23.1: @Box.Add.loc9.%pattern_type (%pattern_type.72a) = ref_param_pattern [symbolic = %self.param_patt.loc9_23.2 (constants.%self.param_patt.99e)]
// CHECK:STDOUT:       %self.patt.loc9_23.1: @Box.Add.loc9.%pattern_type (%pattern_type.72a) = wrapper_binding_pattern self, %self.param_patt.loc9_23.1 [symbolic = %self.patt.loc9_23.2 (constants.%self.patt.0ce)]
// CHECK:STDOUT:       %n.param_patt: %pattern_type.6b6 = value_param_pattern [concrete = constants.%n.param_patt]
// CHECK:STDOUT:       %n.patt: %pattern_type.6b6 = wrapper_binding_pattern n, %n.param_patt [concrete = constants.%n.patt]
// CHECK:STDOUT:     } {
// CHECK:STDOUT:       %self.param: ref @Box.Add.loc9.%Box (%Box.fc8) = ref_param call_param0
// CHECK:STDOUT:       %.loc9_23.1: type = splice_block %Self.ref [symbolic = %Box (constants.%Box.fc8)] {
// CHECK:STDOUT:         %.loc9_23.2: type = specific_constant constants.%Box.fc8, @Box(constants.%T.f84) [symbolic = %Box (constants.%Box.fc8)]
// CHECK:STDOUT:         %Self.ref: type = name_ref Self, %.loc9_23.2 [symbolic = %Box (constants.%Box.fc8)]
// CHECK:STDOUT:       }
// CHECK:STDOUT:       %self: ref @Box.Add.loc9.%Box (%Box.fc8) = wrapper_binding self, %self.param
// CHECK:STDOUT:       %n.param: %i32 = value_param call_param1
// CHECK:STDOUT:       %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %n: %i32 = wrapper_binding n, %n.param
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %Box.Add.overload_set.value.loc9_37.1: @Box.%Box.Add.overload_set.type (%Box.Add.overload_set.type.e92) = overload_set_value @Box.Add.overload_set [symbolic = %Box.Add.overload_set.value.loc9_37.2 (constants.%Box.Add.overload_set.value.cd4)]
// CHECK:STDOUT:     %Box.Add.decl.loc10: @Box.%Box.Add.type.loc10 (%Box.Add.type.1628b5.2) = fn_decl @Box.Add.loc10 [symbolic = @Box.%Box.Add.loc10 (constants.%Box.Add.b04003.2)] {
// CHECK:STDOUT:       %self.param_patt.loc10_23.1: @Box.Add.loc10.%pattern_type (%pattern_type.72a) = ref_param_pattern [symbolic = %self.param_patt.loc10_23.2 (constants.%self.param_patt.99e)]
// CHECK:STDOUT:       %self.patt.loc10_23.1: @Box.Add.loc10.%pattern_type (%pattern_type.72a) = wrapper_binding_pattern self, %self.param_patt.loc10_23.1 [symbolic = %self.patt.loc10_23.2 (constants.%self.patt.0ce)]
// CHECK:STDOUT:       %b.param_patt: %pattern_type.831 = value_param_pattern [concrete = constants.%b.param_patt]
// CHECK:STDOUT:       %b.patt: %pattern_type.831 = wrapper_binding_pattern b, %b.param_patt [concrete = constants.%b.patt.d80]
// CHECK:STDOUT:     } {
// CHECK:STDOUT:       %self.param: ref @Box.Add.loc10.%Box (%Box.fc8) = ref_param call_param0
// CHECK:STDOUT:       %.loc10_23.1: type = splice_block %Self.ref [symbolic = %Box (constants.%Box.fc8)] {
// CHECK:STDOUT:         %.loc10_23.2: type = specific_constant constants.%Box.fc8, @Box(constants.%T.f84) [symbolic = %Box (constants.%Box.fc8)]
// CHECK:STDOUT:         %Self.ref: type = name_ref Self, %.loc10_23.2 [symbolic = %Box (constants.%Box.fc8)]
// CHECK:STDOUT:       }
// CHECK:STDOUT:       %self: ref @Box.Add.loc10.%Box (%Box.fc8) = wrapper_binding self, %self.param
// CHECK:STDOUT:       %b.param: bool = value_param call_param1
// CHECK:STDOUT:       %.loc10_32: type = type_literal bool [concrete = bool]
// CHECK:STDOUT:       %b: bool = wrapper_binding b, %b.param
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %Box.Get.decl: @Box.%Box.Get.type (%Box.Get.type.b71) = fn_decl @Box.Get [symbolic = @Box.%Box.Get (constants.%Box.Get.c3a)] {
// CHECK:STDOUT:       %self.param_patt.loc11_10.1: @Box.Get.%pattern_type (%pattern_type.72a) = value_param_pattern [symbolic = %self.param_patt.loc11_10.2 (constants.%self.param_patt.283)]
// CHECK:STDOUT:       %self.patt.loc11_10.1: @Box.Get.%pattern_type (%pattern_type.72a) = wrapper_binding_pattern self, %self.param_patt.loc11_10.1 [symbolic = %self.patt.loc11_10.2 (constants.%self.patt.a4c)]
// CHECK:STDOUT:       %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:       %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:     } {
// CHECK:STDOUT:       %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %.loc11_19: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:       %self.param: @Box.Get.%Box (%Box.fc8) = value_param call_param0
// CHECK:STDOUT:       %.loc11_10.1: type = splice_block %Self.ref [symbolic = %Box (constants.%Box.fc8)] {
// CHECK:STDOUT:         %.loc11_10.2: type = specific_constant constants.%Box.fc8, @Box(constants.%T.f84) [symbolic = %Box (constants.%Box.fc8)]
// CHECK:STDOUT:         %Self.ref: type = name_ref Self, %.loc11_10.2 [symbolic = %Box (constants.%Box.fc8)]
// CHECK:STDOUT:       }
// CHECK:STDOUT:       %self: @Box.Get.%Box (%Box.fc8) = wrapper_binding self, %self.param
// CHECK:STDOUT:       %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:       %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %complete_type.loc12_1.1: <witness> = complete_type_witness constants.%struct_type.tag.total.9eb [symbolic = %complete_type.loc12_1.2 (constants.%complete_type.081)]
// CHECK:STDOUT:     complete_type_witness = %complete_type.loc12_1.1
// CHECK:STDOUT:
// CHECK:STDOUT:   !members:
// CHECK:STDOUT:     .Self = constants.%Box.fc8
// CHECK:STDOUT:     .T = <poisoned>
// CHECK:STDOUT:     .tag = %field_decl.loc6
// CHECK:STDOUT:     .total = %field_decl.loc7
// CHECK:STDOUT:     .Box = <poisoned>
// CHECK:STDOUT:     .Make = %Box.Make.decl
// CHECK:STDOUT:     .Add = %Box.Add.overload_set.value.loc9_37.1
// CHECK:STDOUT:     .Get = %Box.Get.decl
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @Box.Make(@Box.%T.loc5_12.2: %Copy.type) {
// CHECK:STDOUT:   %T: %Copy.type = symbolic_binding T, 0 [symbolic = %T (constants.%T.f84)]
// CHECK:STDOUT:   %T.as_type.loc8_22.1: type = facet_access_type %T [symbolic = %T.as_type.loc8_22.1 (constants.%T.as_type.c1c)]
// CHECK:STDOUT:   %pattern_type.loc8_20: type = pattern_type %T.as_type.loc8_22.1 [symbolic = %pattern_type.loc8_20 (constants.%pattern_type.2c66b4.2)]
// CHECK:STDOUT:   %t.param_patt.loc8_20.2: @Box.Make.%pattern_type.loc8_20 (%pattern_type.2c66b4.2) = value_param_pattern [symbolic = %t.param_patt.loc8_20.2 (constants.%t.param_patt.adf)]
// CHECK:STDOUT:   %t.patt.loc8_20.2: @Box.Make.%pattern_type.loc8_20 (%pattern_type.2c66b4.2) = wrapper_binding_pattern t, %t.param_patt.loc8_20.2 [symbolic = %t.patt.loc8_20.2 (constants.%t.patt.035)]
// CHECK:STDOUT:   %Box.loc8_33.1: type = class_type @Box, @Box(%T) [symbolic = %Box.loc8_33.1 (constants.%Box.fc8)]
// CHECK:STDOUT:   %.loc8_33.1: Core.Form = init_form %Box.loc8_33.1 [symbolic = %.loc8_33.1 (constants.%.7dc)]
// CHECK:STDOUT:   %pattern_type.loc8_33: type = pattern_type %Box.loc8_33.1 [symbolic = %pattern_type.loc8_33 (constants.%pattern_type.72a)]
// CHECK:STDOUT:   %return.param_patt.loc8_33.2: @Box.Make.%pattern_type.loc8_33 (%pattern_type.72a) = out_param_pattern [symbolic = %return.param_patt.loc8_33.2 (constants.%return.param_patt.318)]
// CHECK:STDOUT:   %return.patt.loc8_25.2: @Box.Make.%pattern_type.loc8_33 (%pattern_type.72a) = return_slot_pattern %return.param_patt.loc8_33.2, %Box.loc8_33.1 [symbolic = %return.patt.loc8_25.2 (constants.%return.patt.f28)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc8_20: <witness> = require_complete_type %T.as_type.loc8_22.1 [symbolic = %require_complete.loc8_20 (constants.%require_complete.d83)]
// CHECK:STDOUT:   %require_complete.loc8_25: <witness> = require_complete_type %Box.loc8_33.1 [symbolic = %require_complete.loc8_25 (constants.%require_complete.f3c)]
// CHECK:STDOUT:   %struct_type.tag.total: type = struct_type {.tag: @Box.Make.%T.as_type.loc8_22.1 (%T.as_type.c1c), .total: %i32} [symbolic = %struct_type.tag.total (constants.%struct_type.tag.total.9eb)]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%T) [symbolic = %Copy.WithSelf.Op.type (constants.%Copy.WithSelf.Op.type.c85f21.2)]
// CHECK:STDOUT:   %.loc8_52.3: type = fn_type_with_self_type %Copy.WithSelf.Op.type, %T [symbolic = %.loc8_52.3 (constants.%.c29)]
// CHECK:STDOUT:   %Copy.lookup_impl_witness: <witness> = lookup_impl_witness %T, @Copy [symbolic = %Copy.lookup_impl_witness (constants.%Copy.lookup_impl_witness.d9c)]
// CHECK:STDOUT:   %impl.elem0.loc8_52.2: @Box.Make.%.loc8_52.3 (%.c29) = impl_witness_access %Copy.lookup_impl_witness, element0 [symbolic = %impl.elem0.loc8_52.2 (constants.%impl.elem0.bd2)]
// CHECK:STDOUT:   %specific_impl_fn.loc8_52.2: <specific function> = specific_impl_function %impl.elem0.loc8_52.2, @Copy.WithSelf.Op(%T) [symbolic = %specific_impl_fn.loc8_52.2 (constants.%specific_impl_fn.e2a)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%x.param: %i32, %t.param: @Box.Make.%T.as_type.loc8_22.1 (%T.as_type.c1c)) -> out %return.param: @Box.Make.%Box.loc8_33.1 (%Box.fc8) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %t.ref: @Box.Make.%T.as_type.loc8_22.1 (%T.as_type.c1c) = name_ref t, %t
// CHECK:STDOUT:     %x.ref: %i32 = name_ref x, %x
// CHECK:STDOUT:     %.loc8_65.1: @Box.Make.%struct_type.tag.total (%struct_type.tag.total.9eb) = struct_literal (%t.ref, %x.ref)
// CHECK:STDOUT:     %impl.elem0.loc8_52.1: @Box.Make.%.loc8_52.3 (%.c29) = impl_witness_access constants.%Copy.lookup_impl_witness.d9c, element0 [symbolic = %impl.elem0.loc8_52.2 (constants.%impl.elem0.bd2)]
// CHECK:STDOUT:     %bound_method.loc8_52.1: <bound method> = bound_method %t.ref, %impl.elem0.loc8_52.1
// CHECK:STDOUT:     %.loc8_52.1: %Copy.type = converted constants.%T.as_type.c1c, constants.%T.f84 [symbolic = %T (constants.%T.f84)]
// CHECK:STDOUT:     %.loc8_52.2: %Copy.type = converted constants.%T.as_type.c1c, constants.%T.f84 [symbolic = %T (constants.%T.f84)]
// CHECK:STDOUT:     %specific_impl_fn.loc8_52.1: <specific function> = specific_impl_function %impl.elem0.loc8_52.1, @Copy.WithSelf.Op(constants.%T.f84) [symbolic = %specific_impl_fn.loc8_52.2 (constants.%specific_impl_fn.e2a)]
// CHECK:STDOUT:     %bound_method.loc8_52.2: <bound method> = bound_method %t.ref, %specific_impl_fn.loc8_52.1
// CHECK:STDOUT:     %.loc8_65.2: ref @Box.Make.%T.as_type.loc8_22.1 (%T.as_type.c1c) = class_element_access %return.param, element0
// CHECK:STDOUT:     %Copy.WithSelf.Op.call: init @Box.Make.%T.as_type.loc8_22.1 (%T.as_type.c1c) to %.loc8_65.2 = call %bound_method.loc8_52.2(%t.ref)
// CHECK:STDOUT:     %.loc8_65.3: init @Box.Make.%T.as_type.loc8_22.1 (%T.as_type.c1c) to %.loc8_65.2 = in_place_init %Copy.WithSelf.Op.call
// CHECK:STDOUT:     %impl.elem0.loc8_64: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:     %bound_method.loc8_64.1: <bound method> = bound_method %x.ref, %impl.elem0.loc8_64
// CHECK:STDOUT:     %specific_fn: <specific function> = specific_function %impl.elem0.loc8_64, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn.287]
// CHECK:STDOUT:     %bound_method.loc8_64.2: <bound method> = bound_method %x.ref, %specific_fn
// CHECK:STDOUT:     %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc8_64.2(%x.ref)
// CHECK:STDOUT:     %.loc8_65.4: ref %i32 = class_element_access %return.param, element1
// CHECK:STDOUT:     %.loc8_65.5: init %i32 to %.loc8_65.4 = in_place_init %Int.as.Copy.impl.Op.call
// CHECK:STDOUT:     %.loc8_65.6: init @Box.Make.%Box.loc8_33.1 (%Box.fc8) to %return.param = class_init (%.loc8_65.3, %.loc8_65.5)
// CHECK:STDOUT:     %.loc8_66: init @Box.Make.%Box.loc8_33.1 (%Box.fc8) = converted %.loc8_65.1, %.loc8_65.6
// CHECK:STDOUT:     return %.loc8_66 to %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @Box.Add.loc9(@Box.%T.loc5_12.2: %Copy.type) {
// CHECK:STDOUT:   %T: %Copy.type = symbolic_binding T, 0 [symbolic = %T (constants.%T.f84)]
// CHECK:STDOUT:   %Box: type = class_type @Box, @Box(%T) [symbolic = %Box (constants.%Box.fc8)]
// CHECK:STDOUT:   %pattern_type: type = pattern_type %Box [symbolic = %pattern_type (constants.%pattern_type.72a)]
// CHECK:STDOUT:   %self.param_patt.loc9_23.2: @Box.Add.loc9.%pattern_type (%pattern_type.72a) = ref_param_pattern [symbolic = %self.param_patt.loc9_23.2 (constants.%self.param_patt.99e)]
// CHECK:STDOUT:   %self.patt.loc9_23.2: @Box.Add.loc9.%pattern_type (%pattern_type.72a) = wrapper_binding_pattern self, %self.param_patt.loc9_23.2 [symbolic = %self.patt.loc9_23.2 (constants.%self.patt.0ce)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete: <witness> = require_complete_type %Box [symbolic = %require_complete (constants.%require_complete.f3c)]
// CHECK:STDOUT:   %Box.elem: type = unbound_element_type %Box, constants.%i32 [symbolic = %Box.elem (constants.%Box.elem.adb)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%self.param: ref @Box.Add.loc9.%Box (%Box.fc8), %n.param: %i32) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %self.ref.loc9_39: ref @Box.Add.loc9.%Box (%Box.fc8) = name_ref self, %self
// CHECK:STDOUT:     %total.ref.loc9_43: @Box.Add.loc9.%Box.elem (%Box.elem.adb) = name_ref total, @Box.%field_decl.loc7 [concrete = @Box.%field_decl.loc7]
// CHECK:STDOUT:     %.loc9_43: ref %i32 = class_element_access %self.ref.loc9_39, element1
// CHECK:STDOUT:     %self.ref.loc9_52: ref @Box.Add.loc9.%Box (%Box.fc8) = name_ref self, %self
// CHECK:STDOUT:     %total.ref.loc9_56: @Box.Add.loc9.%Box.elem (%Box.elem.adb) = name_ref total, @Box.%field_decl.loc7 [concrete = @Box.%field_decl.loc7]
// CHECK:STDOUT:     %.loc9_56.1: ref %i32 = class_element_access %self.ref.loc9_52, element1
// CHECK:STDOUT:     %n.ref: %i32 = name_ref n, %n
// CHECK:STDOUT:     %impl.elem1: %.d47 = impl_witness_access constants.%AddWith.impl_witness.833, element1 [concrete = constants.%Int.as.AddWith.impl.Op.365]
// CHECK:STDOUT:     %bound_method.loc9_63.1: <bound method> = bound_method %.loc9_56.1, %impl.elem1
// CHECK:STDOUT:     %specific_fn: <specific function> = specific_function %impl.elem1, @Int.as.AddWith.impl.Op.1(constants.%int_32) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.f25]
// CHECK:STDOUT:     %bound_method.loc9_63.2: <bound method> = bound_method %.loc9_56.1, %specific_fn
// CHECK:STDOUT:     %.loc9_56.2: %i32 = acquire_value %.loc9_56.1
// CHECK:STDOUT:     %Int.as.AddWith.impl.Op.call: init %i32 = call %bound_method.loc9_63.2(%.loc9_56.2, %n.ref)
// CHECK:STDOUT:     assign %.loc9_43, %Int.as.AddWith.impl.Op.call
// CHECK:STDOUT:     return
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @Box.Add.loc10(@Box.%T.loc5_12.2: %Copy.type) {
// CHECK:STDOUT:   %T: %Copy.type = symbolic_binding T, 0 [symbolic = %T (constants.%T.f84)]
// CHECK:STDOUT:   %Box: type = class_type @Box, @Box(%T) [symbolic = %Box (constants.%Box.fc8)]
// CHECK:STDOUT:   %pattern_type: type = pattern_type %Box [symbolic = %pattern_type (constants.%pattern_type.72a)]
// CHECK:STDOUT:   %self.param_patt.loc10_23.2: @Box.Add.loc10.%pattern_type (%pattern_type.72a) = ref_param_pattern [symbolic = %self.param_patt.loc10_23.2 (constants.%self.param_patt.99e)]
// CHECK:STDOUT:   %self.patt.loc10_23.2: @Box.Add.loc10.%pattern_type (%pattern_type.72a) = wrapper_binding_pattern self, %self.param_patt.loc10_23.2 [symbolic = %self.patt.loc10_23.2 (constants.%self.patt.0ce)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete: <witness> = require_complete_type %Box [symbolic = %require_complete (constants.%require_complete.f3c)]
// CHECK:STDOUT:   %Box.elem: type = unbound_element_type %Box, constants.%i32 [symbolic = %Box.elem (constants.%Box.elem.adb)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%self.param: ref @Box.Add.loc10.%Box (%Box.fc8), %b.param: bool) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %b.ref: bool = name_ref b, %b
// CHECK:STDOUT:     if %b.ref br !if.then else br !if.else
// CHECK:STDOUT:
// CHECK:STDOUT:   !if.then:
// CHECK:STDOUT:     %self.ref.loc10_49: ref @Box.Add.loc10.%Box (%Box.fc8) = name_ref self, %self
// CHECK:STDOUT:     %total.ref.loc10_53: @Box.Add.loc10.%Box.elem (%Box.elem.adb) = name_ref total, @Box.%field_decl.loc7 [concrete = @Box.%field_decl.loc7]
// CHECK:STDOUT:     %.loc10_53: ref %i32 = class_element_access %self.ref.loc10_49, element1
// CHECK:STDOUT:     %self.ref.loc10_62: ref @Box.Add.loc10.%Box (%Box.fc8) = name_ref self, %self
// CHECK:STDOUT:     %total.ref.loc10_66: @Box.Add.loc10.%Box.elem (%Box.elem.adb) = name_ref total, @Box.%field_decl.loc7 [concrete = @Box.%field_decl.loc7]
// CHECK:STDOUT:     %.loc10_66.1: ref %i32 = class_element_access %self.ref.loc10_62, element1
// CHECK:STDOUT:     %int_100: Core.IntLiteral = int_value 100 [concrete = constants.%int_100.44f]
// CHECK:STDOUT:     %impl.elem1: %.fbe = impl_witness_access constants.%AddWith.impl_witness.aa4, element1 [concrete = constants.%Int.as.AddWith.impl.Op.1fd531.2]
// CHECK:STDOUT:     %bound_method.loc10_73.1: <bound method> = bound_method %.loc10_66.1, %impl.elem1
// CHECK:STDOUT:     %specific_fn.loc10_73: <specific function> = specific_function %impl.elem1, @Int.as.AddWith.impl.Op.2(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.273a3e.1]
// CHECK:STDOUT:     %bound_method.loc10_73.2: <bound method> = bound_method %.loc10_66.1, %specific_fn.loc10_73
// CHECK:STDOUT:     %.loc10_66.2: %i32 = acquire_value %.loc10_66.1
// CHECK:STDOUT:     %.loc10_73: %Int.as.AddWith.impl.Op.type.bddb3c.1 = specific_constant imports.%Core.Op.410, @Int.as.AddWith.impl.155(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%Int.as.AddWith.impl.Op.1fd531.1]
// CHECK:STDOUT:     %Op.ref: %Int.as.AddWith.impl.Op.type.bddb3c.1 = name_ref Op, %.loc10_73 [concrete = constants.%Int.as.AddWith.impl.Op.1fd531.1]
// CHECK:STDOUT:     %Int.as.AddWith.impl.Op.bound: <bound method> = bound_method %.loc10_66.2, %Op.ref
// CHECK:STDOUT:     %Int.as.AddWith.impl.Op.specific_fn: <specific function> = specific_function %Op.ref, @Int.as.AddWith.impl.Op.3(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.273a3e.2]
// CHECK:STDOUT:     %bound_method.loc10_73.3: <bound method> = bound_method %.loc10_66.2, %Int.as.AddWith.impl.Op.specific_fn
// CHECK:STDOUT:     %impl.elem0: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:     %bound_method.loc10_75.1: <bound method> = bound_method %int_100, %impl.elem0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.2f5]
// CHECK:STDOUT:     %specific_fn.loc10_75: <specific function> = specific_function %impl.elem0, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:     %bound_method.loc10_75.2: <bound method> = bound_method %int_100, %specific_fn.loc10_75 [concrete = constants.%bound_method.565]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %i32 = call %bound_method.loc10_75.2(%int_100) [concrete = constants.%int_100.d3c]
// CHECK:STDOUT:     %.loc10_75.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_100.d3c]
// CHECK:STDOUT:     %.loc10_75.2: %i32 = converted %int_100, %.loc10_75.1 [concrete = constants.%int_100.d3c]
// CHECK:STDOUT:     %Int.as.AddWith.impl.Op.call: init %i32 = call %bound_method.loc10_73.3(%.loc10_66.2, %.loc10_75.2)
// CHECK:STDOUT:     assign %.loc10_53, %Int.as.AddWith.impl.Op.call
// CHECK:STDOUT:     br !if.else
// CHECK:STDOUT:
// CHECK:STDOUT:   !if.else:
// CHECK:STDOUT:     return
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @Box.Get(@Box.%T.loc5_12.2: %Copy.type) {
// CHECK:STDOUT:   %T: %Copy.type = symbolic_binding T, 0 [symbolic = %T (constants.%T.f84)]
// CHECK:STDOUT:   %Box: type = class_type @Box, @Box(%T) [symbolic = %Box (constants.%Box.fc8)]
// CHECK:STDOUT:   %pattern_type: type = pattern_type %Box [symbolic = %pattern_type (constants.%pattern_type.72a)]
// CHECK:STDOUT:   %self.param_patt.loc11_10.2: @Box.Get.%pattern_type (%pattern_type.72a) = value_param_pattern [symbolic = %self.param_patt.loc11_10.2 (constants.%self.param_patt.283)]
// CHECK:STDOUT:   %self.patt.loc11_10.2: @Box.Get.%pattern_type (%pattern_type.72a) = wrapper_binding_pattern self, %self.param_patt.loc11_10.2 [symbolic = %self.patt.loc11_10.2 (constants.%self.patt.a4c)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete: <witness> = require_complete_type %Box [symbolic = %require_complete (constants.%require_complete.f3c)]
// CHECK:STDOUT:   %Box.elem: type = unbound_element_type %Box, constants.%i32 [symbolic = %Box.elem (constants.%Box.elem.adb)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%self.param: @Box.Get.%Box (%Box.fc8)) -> out %return.param: %i32 {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %self.ref: @Box.Get.%Box (%Box.fc8) = name_ref self, %self
// CHECK:STDOUT:     %total.ref: @Box.Get.%Box.elem (%Box.elem.adb) = name_ref total, @Box.%field_decl.loc7 [concrete = @Box.%field_decl.loc7]
// CHECK:STDOUT:     %.loc11_36.1: ref %i32 = class_element_access %self.ref, element1
// CHECK:STDOUT:     %.loc11_36.2: %i32 = acquire_value %.loc11_36.1
// CHECK:STDOUT:     %impl.elem0: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:     %bound_method.loc11_36.1: <bound method> = bound_method %.loc11_36.2, %impl.elem0
// CHECK:STDOUT:     %specific_fn: <specific function> = specific_function %impl.elem0, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn.287]
// CHECK:STDOUT:     %bound_method.loc11_36.2: <bound method> = bound_method %.loc11_36.2, %specific_fn
// CHECK:STDOUT:     %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc11_36.2(%.loc11_36.2)
// CHECK:STDOUT:     return %Int.as.Copy.impl.Op.call
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Use() -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %b.var: ref %Box.ecf = var_storage %b.var_patt
// CHECK:STDOUT:   %Box.ref.loc15_21: %Box.type = name_ref Box, file.%Box.decl [concrete = constants.%Box.generic]
// CHECK:STDOUT:   %i64.loc15_25: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:   %Copy.facet.loc15_28: %Copy.type = facet_value %i64.loc15_25, (constants.%Copy.impl_witness.8cc) [concrete = constants.%Copy.facet.4e9]
// CHECK:STDOUT:   %.loc15_28: %Copy.type = converted %i64.loc15_25, %Copy.facet.loc15_28 [concrete = constants.%Copy.facet.4e9]
// CHECK:STDOUT:   %Box.loc15_28: type = class_type @Box, @Box(constants.%Copy.facet.4e9) [concrete = constants.%Box.ecf]
// CHECK:STDOUT:   %.loc15_29: %Box.Make.type.75b = specific_constant @Box.%Box.Make.decl, @Box(constants.%Copy.facet.4e9) [concrete = constants.%Box.Make.a2e]
// CHECK:STDOUT:   %Make.ref: %Box.Make.type.75b = name_ref Make, %.loc15_29 [concrete = constants.%Box.Make.a2e]
// CHECK:STDOUT:   %int_1.loc15: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %i64.loc15_43: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:   %impl.elem0.loc15_40: %.8fd = impl_witness_access constants.%As.impl_witness.0fe, element0 [concrete = constants.%Core.IntLiteral.as.As.impl.Convert.3d9]
// CHECK:STDOUT:   %bound_method.loc15_40.1: <bound method> = bound_method %int_0, %impl.elem0.loc15_40 [concrete = constants.%Core.IntLiteral.as.As.impl.Convert.bound]
// CHECK:STDOUT:   %specific_fn.loc15_40: <specific function> = specific_function %impl.elem0.loc15_40, @Core.IntLiteral.as.As.impl.Convert(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.As.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc15_40.2: <bound method> = bound_method %int_0, %specific_fn.loc15_40 [concrete = constants.%bound_method.585]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.call: init %i64 = call %bound_method.loc15_40.2(%int_0) [concrete = constants.%int_0.2e4]
// CHECK:STDOUT:   %.loc15_40.1: %i64 = value_of_initializer %Core.IntLiteral.as.As.impl.Convert.call [concrete = constants.%int_0.2e4]
// CHECK:STDOUT:   %.loc15_40.2: %i64 = converted %int_0, %.loc15_40.1 [concrete = constants.%int_0.2e4]
// CHECK:STDOUT:   %Copy.facet.loc15_46.1: %Copy.type = facet_value constants.%i64, (constants.%Copy.impl_witness.8cc) [concrete = constants.%Copy.facet.4e9]
// CHECK:STDOUT:   %.loc15_46.1: %Copy.type = converted constants.%i64, %Copy.facet.loc15_46.1 [concrete = constants.%Copy.facet.4e9]
// CHECK:STDOUT:   %Copy.facet.loc15_46.2: %Copy.type = facet_value constants.%i64, (constants.%Copy.impl_witness.8cc) [concrete = constants.%Copy.facet.4e9]
// CHECK:STDOUT:   %.loc15_46.2: %Copy.type = converted constants.%i64, %Copy.facet.loc15_46.2 [concrete = constants.%Copy.facet.4e9]
// CHECK:STDOUT:   %Box.Make.specific_fn: <specific function> = specific_function %Make.ref, @Box.Make(constants.%Copy.facet.4e9) [concrete = constants.%Box.Make.specific_fn]
// CHECK:STDOUT:   %.loc15_3: ref %Box.ecf = splice_block %b.var {}
// CHECK:STDOUT:   %impl.elem0.loc15_35: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc15_35.1: <bound method> = bound_method %int_1.loc15, %impl.elem0.loc15_35 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc15_35: <specific function> = specific_function %impl.elem0.loc15_35, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc15_35.2: <bound method> = bound_method %int_1.loc15, %specific_fn.loc15_35 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc15: init %i32 = call %bound_method.loc15_35.2(%int_1.loc15) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc15_35.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc15 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc15_35.2: %i32 = converted %int_1.loc15, %.loc15_35.1 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %Box.Make.call: init %Box.ecf to %.loc15_3 = call %Box.Make.specific_fn(%.loc15_35.2, %.loc15_40.2)
// CHECK:STDOUT:   assign %b.var, %Box.Make.call
// CHECK:STDOUT:   %.loc15_17.1: type = splice_block %Box.loc15_17 [concrete = constants.%Box.ecf] {
// CHECK:STDOUT:     %Box.ref.loc15_10: %Box.type = name_ref Box, file.%Box.decl [concrete = constants.%Box.generic]
// CHECK:STDOUT:     %i64.loc15_14: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:     %Copy.facet.loc15_17: %Copy.type = facet_value %i64.loc15_14, (constants.%Copy.impl_witness.8cc) [concrete = constants.%Copy.facet.4e9]
// CHECK:STDOUT:     %.loc15_17.2: %Copy.type = converted %i64.loc15_14, %Copy.facet.loc15_17 [concrete = constants.%Copy.facet.4e9]
// CHECK:STDOUT:     %Box.loc15_17: type = class_type @Box, @Box(constants.%Copy.facet.4e9) [concrete = constants.%Box.ecf]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %b: ref %Box.ecf = wrapper_binding b, %b.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %b.patt: %pattern_type.60e = ref_binding_pattern b [concrete = constants.%b.patt.931]
// CHECK:STDOUT:     %b.var_patt: %pattern_type.60e = var_pattern %b.patt [concrete = constants.%b.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %b.ref.loc16: ref %Box.ecf = name_ref b, %b
// CHECK:STDOUT:   %.loc16_4: %Box.Add.overload_set.type.e34 = specific_constant @Box.%Box.Add.overload_set.value.loc9_37.1, @Box(constants.%Copy.facet.4e9) [concrete = constants.%Box.Add.overload_set.value.a4e]
// CHECK:STDOUT:   %Add.ref.loc16_4: %Box.Add.overload_set.type.e34 = name_ref Add, %.loc16_4 [concrete = constants.%Box.Add.overload_set.value.a4e]
// CHECK:STDOUT:   %bound_method.loc16_4: <bound method> = bound_method %b.ref.loc16, %Add.ref.loc16_4
// CHECK:STDOUT:   %int_1.loc16: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %.loc16_10: %Box.Add.type.0225c6.1 = specific_constant @Box.%Box.Add.decl.loc9, @Box(constants.%Copy.facet.4e9) [concrete = constants.%Box.Add.a2595a.1]
// CHECK:STDOUT:   %Add.ref.loc16_10: %Box.Add.type.0225c6.1 = name_ref Add, %.loc16_10 [concrete = constants.%Box.Add.a2595a.1]
// CHECK:STDOUT:   %Box.Add.bound.loc16: <bound method> = bound_method %b.ref.loc16, %Add.ref.loc16_10
// CHECK:STDOUT:   %Box.Add.specific_fn.loc16: <specific function> = specific_function %Add.ref.loc16_10, @Box.Add.loc9(constants.%Copy.facet.4e9) [concrete = constants.%Box.Add.specific_fn.784a5d.1]
// CHECK:STDOUT:   %bound_method.loc16_10: <bound method> = bound_method %b.ref.loc16, %Box.Add.specific_fn.loc16
// CHECK:STDOUT:   %impl.elem0.loc16: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc16_9.1: <bound method> = bound_method %int_1.loc16, %impl.elem0.loc16 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc16: <specific function> = specific_function %impl.elem0.loc16, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc16_9.2: <bound method> = bound_method %int_1.loc16, %specific_fn.loc16 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16: init %i32 = call %bound_method.loc16_9.2(%int_1.loc16) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc16_9.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc16_9.2: %i32 = converted %int_1.loc16, %.loc16_9.1 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %Box.Add.call.loc16: init %empty_tuple.type = call %bound_method.loc16_10(%b.ref.loc16, %.loc16_9.2)
// CHECK:STDOUT:   %b.ref.loc17: ref %Box.ecf = name_ref b, %b
// CHECK:STDOUT:   %.loc17_4: %Box.Add.overload_set.type.e34 = specific_constant @Box.%Box.Add.overload_set.value.loc9_37.1, @Box(constants.%Copy.facet.4e9) [concrete = constants.%Box.Add.overload_set.value.a4e]
// CHECK:STDOUT:   %Add.ref.loc17_4: %Box.Add.overload_set.type.e34 = name_ref Add, %.loc17_4 [concrete = constants.%Box.Add.overload_set.value.a4e]
// CHECK:STDOUT:   %bound_method.loc17_4: <bound method> = bound_method %b.ref.loc17, %Add.ref.loc17_4
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:   %.loc17_13: %Box.Add.type.0225c6.2 = specific_constant @Box.%Box.Add.decl.loc10, @Box(constants.%Copy.facet.4e9) [concrete = constants.%Box.Add.a2595a.2]
// CHECK:STDOUT:   %Add.ref.loc17_13: %Box.Add.type.0225c6.2 = name_ref Add, %.loc17_13 [concrete = constants.%Box.Add.a2595a.2]
// CHECK:STDOUT:   %Box.Add.bound.loc17: <bound method> = bound_method %b.ref.loc17, %Add.ref.loc17_13
// CHECK:STDOUT:   %Box.Add.specific_fn.loc17: <specific function> = specific_function %Add.ref.loc17_13, @Box.Add.loc10(constants.%Copy.facet.4e9) [concrete = constants.%Box.Add.specific_fn.784a5d.2]
// CHECK:STDOUT:   %bound_method.loc17_13: <bound method> = bound_method %b.ref.loc17, %Box.Add.specific_fn.loc17
// CHECK:STDOUT:   %Box.Add.call.loc17: init %empty_tuple.type = call %bound_method.loc17_13(%b.ref.loc17, %true)
// CHECK:STDOUT:   %b.ref.loc18: ref %Box.ecf = name_ref b, %b
// CHECK:STDOUT:   %.loc18_11: %Box.Get.type.10a = specific_constant @Box.%Box.Get.decl, @Box(constants.%Copy.facet.4e9) [concrete = constants.%Box.Get.7c5]
// CHECK:STDOUT:   %Get.ref: %Box.Get.type.10a = name_ref Get, %.loc18_11 [concrete = constants.%Box.Get.7c5]
// CHECK:STDOUT:   %Box.Get.bound: <bound method> = bound_method %b.ref.loc18, %Get.ref
// CHECK:STDOUT:   %Box.Get.specific_fn: <specific function> = specific_function %Get.ref, @Box.Get(constants.%Copy.facet.4e9) [concrete = constants.%Box.Get.specific_fn]
// CHECK:STDOUT:   %bound_method.loc18: <bound method> = bound_method %b.ref.loc18, %Box.Get.specific_fn
// CHECK:STDOUT:   %.loc18_10: %Box.ecf = acquire_value %b.ref.loc18
// CHECK:STDOUT:   %Box.Get.call: init %i32 = call %bound_method.loc18(%.loc18_10)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound: <bound method> = bound_method %b.var, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.4
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound(%b.var)
// CHECK:STDOUT:   return %Box.Get.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc15_3.1(%self.param: ref %i64) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc15_3.1(%self.param: ref %i64) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc15_3.1(%self.param: ref %i64) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.1(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.1(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc15_3.2(%self.param: ref %i32) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc15_3.2(%self.param: ref %i32) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc15_3.2(%self.param: ref %i32) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.2(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.2(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc15_3.3(%self.param: ref %struct_type.tag.total.f3f) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %.loc15_3.1: ref %i32 = struct_access %self.param, element1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc15_3.1: <bound method> = bound_method %.loc15_3.1, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc15_3.1: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc15_3.1(%.loc15_3.1)
// CHECK:STDOUT:   %.loc15_3.2: ref %i64 = struct_access %self.param, element0
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc15_3.2: <bound method> = bound_method %.loc15_3.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc15_3.2: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc15_3.2(%.loc15_3.2)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc15_3.3(%self.param: ref %struct_type.tag.total.f3f) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc15_3.3(%self.param: ref %struct_type.tag.total.f3f) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.3(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.3(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc15_3.4(%self.param: ref %Box.ecf) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %total.ref: %Box.elem.269 = name_ref total, @Box.%field_decl.loc7 [concrete = @Box.%field_decl.loc7]
// CHECK:STDOUT:   %.loc15_3.1: ref %i32 = class_element_access %self.param, element1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc15_3.1: <bound method> = bound_method %.loc15_3.1, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc15_3.1: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc15_3.1(%.loc15_3.1)
// CHECK:STDOUT:   %tag.ref: %Box.elem.e42 = name_ref tag, @Box.%field_decl.loc6 [concrete = @Box.%field_decl.loc6]
// CHECK:STDOUT:   %.loc15_3.2: ref %i64 = class_element_access %self.param, element0
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc15_3.2: <bound method> = bound_method %.loc15_3.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc15_3.2: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc15_3.2(%.loc15_3.2)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc15_3.4(%self.param: ref %Box.ecf) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc15_3.4(%self.param: ref %Box.ecf) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.4(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.4(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Box(constants.%T.f84) {
// CHECK:STDOUT:   %T.patt.loc5_12.2 => constants.%T.patt.fe6
// CHECK:STDOUT:   %T.loc5_12.1 => constants.%T.f84
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %T.as_type.loc6_12.2 => constants.%T.as_type.c1c
// CHECK:STDOUT:   %require_complete => constants.%require_complete.d83
// CHECK:STDOUT:   %Box => constants.%Box.fc8
// CHECK:STDOUT:   %Box.elem.loc6 => constants.%Box.elem.159
// CHECK:STDOUT:   %Box.elem.loc7 => constants.%Box.elem.adb
// CHECK:STDOUT:   %Box.Make.type => constants.%Box.Make.type.fef
// CHECK:STDOUT:   %Box.Make => constants.%Box.Make.22d
// CHECK:STDOUT:   %Box.Add.type.loc9 => constants.%Box.Add.type.1628b5.1
// CHECK:STDOUT:   %Box.Add.loc9 => constants.%Box.Add.b04003.1
// CHECK:STDOUT:   %Box.Add.overload_set.type => constants.%Box.Add.overload_set.type.e92
// CHECK:STDOUT:   %Box.Add.overload_set.value.loc9_37.2 => constants.%Box.Add.overload_set.value.cd4
// CHECK:STDOUT:   %Box.Add.type.loc10 => constants.%Box.Add.type.1628b5.2
// CHECK:STDOUT:   %Box.Add.loc10 => constants.%Box.Add.b04003.2
// CHECK:STDOUT:   %Box.Get.type => constants.%Box.Get.type.b71
// CHECK:STDOUT:   %Box.Get => constants.%Box.Get.c3a
// CHECK:STDOUT:   %struct_type.tag.total => constants.%struct_type.tag.total.9eb
// CHECK:STDOUT:   %complete_type.loc12_1.2 => constants.%complete_type.081
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Box.Make(constants.%T.f84) {
// CHECK:STDOUT:   %T => constants.%T.f84
// CHECK:STDOUT:   %T.as_type.loc8_22.1 => constants.%T.as_type.c1c
// CHECK:STDOUT:   %pattern_type.loc8_20 => constants.%pattern_type.2c66b4.2
// CHECK:STDOUT:   %t.param_patt.loc8_20.2 => constants.%t.param_patt.adf
// CHECK:STDOUT:   %t.patt.loc8_20.2 => constants.%t.patt.035
// CHECK:STDOUT:   %Box.loc8_33.1 => constants.%Box.fc8
// CHECK:STDOUT:   %.loc8_33.1 => constants.%.7dc
// CHECK:STDOUT:   %pattern_type.loc8_33 => constants.%pattern_type.72a
// CHECK:STDOUT:   %return.param_patt.loc8_33.2 => constants.%return.param_patt.318
// CHECK:STDOUT:   %return.patt.loc8_25.2 => constants.%return.patt.f28
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Box.Add.loc9(constants.%T.f84) {
// CHECK:STDOUT:   %T => constants.%T.f84
// CHECK:STDOUT:   %Box => constants.%Box.fc8
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.72a
// CHECK:STDOUT:   %self.param_patt.loc9_23.2 => constants.%self.param_patt.99e
// CHECK:STDOUT:   %self.patt.loc9_23.2 => constants.%self.patt.0ce
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Box.Add.loc10(constants.%T.f84) {
// CHECK:STDOUT:   %T => constants.%T.f84
// CHECK:STDOUT:   %Box => constants.%Box.fc8
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.72a
// CHECK:STDOUT:   %self.param_patt.loc10_23.2 => constants.%self.param_patt.99e
// CHECK:STDOUT:   %self.patt.loc10_23.2 => constants.%self.patt.0ce
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Box.Get(constants.%T.f84) {
// CHECK:STDOUT:   %T => constants.%T.f84
// CHECK:STDOUT:   %Box => constants.%Box.fc8
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.72a
// CHECK:STDOUT:   %self.param_patt.loc11_10.2 => constants.%self.param_patt.283
// CHECK:STDOUT:   %self.patt.loc11_10.2 => constants.%self.patt.a4c
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Box(constants.%Copy.facet.4e9) {
// CHECK:STDOUT:   %T.patt.loc5_12.2 => constants.%T.patt.fe6
// CHECK:STDOUT:   %T.loc5_12.1 => constants.%Copy.facet.4e9
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %T.as_type.loc6_12.2 => constants.%i64
// CHECK:STDOUT:   %require_complete => constants.%complete_type.4a1
// CHECK:STDOUT:   %Box => constants.%Box.ecf
// CHECK:STDOUT:   %Box.elem.loc6 => constants.%Box.elem.e42
// CHECK:STDOUT:   %Box.elem.loc7 => constants.%Box.elem.269
// CHECK:STDOUT:   %Box.Make.type => constants.%Box.Make.type.75b
// CHECK:STDOUT:   %Box.Make => constants.%Box.Make.a2e
// CHECK:STDOUT:   %Box.Add.type.loc9 => constants.%Box.Add.type.0225c6.1
// CHECK:STDOUT:   %Box.Add.loc9 => constants.%Box.Add.a2595a.1
// CHECK:STDOUT:   %Box.Add.overload_set.type => constants.%Box.Add.overload_set.type.e34
// CHECK:STDOUT:   %Box.Add.overload_set.value.loc9_37.2 => constants.%Box.Add.overload_set.value.a4e
// CHECK:STDOUT:   %Box.Add.type.loc10 => constants.%Box.Add.type.0225c6.2
// CHECK:STDOUT:   %Box.Add.loc10 => constants.%Box.Add.a2595a.2
// CHECK:STDOUT:   %Box.Get.type => constants.%Box.Get.type.10a
// CHECK:STDOUT:   %Box.Get => constants.%Box.Get.7c5
// CHECK:STDOUT:   %struct_type.tag.total => constants.%struct_type.tag.total.f3f
// CHECK:STDOUT:   %complete_type.loc12_1.2 => constants.%complete_type.84e
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Box.Make(constants.%Copy.facet.4e9) {
// CHECK:STDOUT:   %T => constants.%Copy.facet.4e9
// CHECK:STDOUT:   %T.as_type.loc8_22.1 => constants.%i64
// CHECK:STDOUT:   %pattern_type.loc8_20 => constants.%pattern_type.f57
// CHECK:STDOUT:   %t.param_patt.loc8_20.2 => constants.%t.param_patt.682
// CHECK:STDOUT:   %t.patt.loc8_20.2 => constants.%t.patt.079
// CHECK:STDOUT:   %Box.loc8_33.1 => constants.%Box.ecf
// CHECK:STDOUT:   %.loc8_33.1 => constants.%.c50
// CHECK:STDOUT:   %pattern_type.loc8_33 => constants.%pattern_type.60e
// CHECK:STDOUT:   %return.param_patt.loc8_33.2 => constants.%return.param_patt.c17
// CHECK:STDOUT:   %return.patt.loc8_25.2 => constants.%return.patt.016
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc8_20 => constants.%complete_type.4a1
// CHECK:STDOUT:   %require_complete.loc8_25 => constants.%complete_type.84e
// CHECK:STDOUT:   %struct_type.tag.total => constants.%struct_type.tag.total.f3f
// CHECK:STDOUT:   %Copy.WithSelf.Op.type => constants.%Copy.WithSelf.Op.type.5c1
// CHECK:STDOUT:   %.loc8_52.3 => constants.%.826
// CHECK:STDOUT:   %Copy.lookup_impl_witness => constants.%Copy.impl_witness.8cc
// CHECK:STDOUT:   %impl.elem0.loc8_52.2 => constants.%Int.as.Copy.impl.Op.d73
// CHECK:STDOUT:   %specific_impl_fn.loc8_52.2 => constants.%Int.as.Copy.impl.Op.specific_fn.b95
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Box.Add.loc9(constants.%Copy.facet.4e9) {
// CHECK:STDOUT:   %T => constants.%Copy.facet.4e9
// CHECK:STDOUT:   %Box => constants.%Box.ecf
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.60e
// CHECK:STDOUT:   %self.param_patt.loc9_23.2 => constants.%self.param_patt.359
// CHECK:STDOUT:   %self.patt.loc9_23.2 => constants.%self.patt.453
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete => constants.%complete_type.84e
// CHECK:STDOUT:   %Box.elem => constants.%Box.elem.269
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Box.Add.loc10(constants.%Copy.facet.4e9) {
// CHECK:STDOUT:   %T => constants.%Copy.facet.4e9
// CHECK:STDOUT:   %Box => constants.%Box.ecf
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.60e
// CHECK:STDOUT:   %self.param_patt.loc10_23.2 => constants.%self.param_patt.359
// CHECK:STDOUT:   %self.patt.loc10_23.2 => constants.%self.patt.453
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete => constants.%complete_type.84e
// CHECK:STDOUT:   %Box.elem => constants.%Box.elem.269
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Box.Get(constants.%Copy.facet.4e9) {
// CHECK:STDOUT:   %T => constants.%Copy.facet.4e9
// CHECK:STDOUT:   %Box => constants.%Box.ecf
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.60e
// CHECK:STDOUT:   %self.param_patt.loc11_10.2 => constants.%self.param_patt.e92
// CHECK:STDOUT:   %self.patt.loc11_10.2 => constants.%self.patt.692
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete => constants.%complete_type.84e
// CHECK:STDOUT:   %Box.elem => constants.%Box.elem.269
// CHECK:STDOUT: }
// CHECK:STDOUT:
