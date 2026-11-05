// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/string/compare.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/string/compare.carbon

// Fork (ST-1, fork/string/plan.md §4): byte-wise `EqWith` and `OrderedWith`
// on `str` and `Core.StringBuf`, all four operand pairs (D-ST-2, D-ST-3,
// D-ST-8).

// --- str_str.carbon

library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn Eq(a: str, b: str) -> bool { return a == b; }
fn Ne(a: str, b: str) -> bool { return a != b; }
fn Lt(a: str, b: str) -> bool { return a < b; }
fn Ge(a: str, b: str) -> bool { return a >= b; }
//@dump-sem-ir-end

// --- mixed.carbon

library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn EqBufStr(a: Core.StringBuf, b: str) -> bool { return a == b; }
fn LtStrBuf(a: str, b: Core.StringBuf) -> bool { return a < b; }
fn GtBufBuf(a: Core.StringBuf, b: Core.StringBuf) -> bool { return a > b; }
//@dump-sem-ir-end

// --- generic.carbon

library "[[@TEST_NAME]]";

fn Min[T: Core.Ordered & Core.Copy](a: T, b: T) -> T {
  return if a < b then a else b;
}

//@dump-sem-ir-begin
fn UseMin() -> str { return Min("pear", "apple"); }
//@dump-sem-ir-end

// CHECK:STDOUT: --- str_str.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %str: type = class_type @String [concrete]
// CHECK:STDOUT:   %pattern_type.adf: type = pattern_type %str [concrete]
// CHECK:STDOUT:   %a.param_patt: %pattern_type.adf = value_param_pattern [concrete]
// CHECK:STDOUT:   %a.patt: %pattern_type.adf = wrapper_binding_pattern a, %a.param_patt [concrete]
// CHECK:STDOUT:   %b.param_patt: %pattern_type.adf = value_param_pattern [concrete]
// CHECK:STDOUT:   %b.patt: %pattern_type.adf = wrapper_binding_pattern b, %b.param_patt [concrete]
// CHECK:STDOUT:   %.f34: Core.Form = init_form bool [concrete]
// CHECK:STDOUT:   %pattern_type.831: type = pattern_type bool [concrete]
// CHECK:STDOUT:   %return.param_patt.5a1: %pattern_type.831 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.c0c: %pattern_type.831 = return_slot_pattern %return.param_patt.5a1, bool [concrete]
// CHECK:STDOUT:   %Eq.type: type = fn_type @Eq [concrete]
// CHECK:STDOUT:   %Eq: %Eq.type = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.type.ca1: type = facet_type <@EqWith, @EqWith(%str)> [concrete]
// CHECK:STDOUT:   %EqWith.impl_witness.c84: <witness> = impl_witness imports.%EqWith.impl_witness_table.bc8 [concrete]
// CHECK:STDOUT:   %EqWith.facet.70b: %EqWith.type.ca1 = facet_value %str, (%EqWith.impl_witness.c84) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.e64: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%str, %EqWith.facet.70b) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.NotEqual.type.f39: type = fn_type @EqWith.WithSelf.NotEqual, @EqWith.WithSelf(%str, %EqWith.facet.70b) [concrete]
// CHECK:STDOUT:   %.58b: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.e64, %EqWith.facet.70b [concrete]
// CHECK:STDOUT:   %str.as.EqWith.impl.Equal.type: type = fn_type @str.as.EqWith.impl.Equal [concrete]
// CHECK:STDOUT:   %str.as.EqWith.impl.Equal: %str.as.EqWith.impl.Equal.type = struct_value () [concrete]
// CHECK:STDOUT:   %Ne.type: type = fn_type @Ne [concrete]
// CHECK:STDOUT:   %Ne: %Ne.type = struct_value () [concrete]
// CHECK:STDOUT:   %.44b: type = fn_type_with_self_type %EqWith.WithSelf.NotEqual.type.f39, %EqWith.facet.70b [concrete]
// CHECK:STDOUT:   %str.as.EqWith.impl.NotEqual.type: type = fn_type @str.as.EqWith.impl.NotEqual [concrete]
// CHECK:STDOUT:   %str.as.EqWith.impl.NotEqual: %str.as.EqWith.impl.NotEqual.type = struct_value () [concrete]
// CHECK:STDOUT:   %Lt.type: type = fn_type @Lt [concrete]
// CHECK:STDOUT:   %Lt: %Lt.type = struct_value () [concrete]
// CHECK:STDOUT:   %OrderedWith.type.ad2: type = facet_type <@OrderedWith, @OrderedWith(%str)> [concrete]
// CHECK:STDOUT:   %OrderedWith.impl_witness.3fd: <witness> = impl_witness imports.%OrderedWith.impl_witness_table.11c [concrete]
// CHECK:STDOUT:   %OrderedWith.facet.5bd: %OrderedWith.type.ad2 = facet_value %str, (%OrderedWith.impl_witness.3fd) [concrete]
// CHECK:STDOUT:   %OrderedWith.WithSelf.Less.type.1a7: type = fn_type @OrderedWith.WithSelf.Less, @OrderedWith.WithSelf(%str, %OrderedWith.facet.5bd) [concrete]
// CHECK:STDOUT:   %OrderedWith.WithSelf.GreaterOrEquivalent.type.c57: type = fn_type @OrderedWith.WithSelf.GreaterOrEquivalent, @OrderedWith.WithSelf(%str, %OrderedWith.facet.5bd) [concrete]
// CHECK:STDOUT:   %.013: type = fn_type_with_self_type %OrderedWith.WithSelf.Less.type.1a7, %OrderedWith.facet.5bd [concrete]
// CHECK:STDOUT:   %str.as.OrderedWith.impl.Less.type: type = fn_type @str.as.OrderedWith.impl.Less [concrete]
// CHECK:STDOUT:   %str.as.OrderedWith.impl.Less: %str.as.OrderedWith.impl.Less.type = struct_value () [concrete]
// CHECK:STDOUT:   %Ge.type: type = fn_type @Ge [concrete]
// CHECK:STDOUT:   %Ge: %Ge.type = struct_value () [concrete]
// CHECK:STDOUT:   %.f77: type = fn_type_with_self_type %OrderedWith.WithSelf.GreaterOrEquivalent.type.c57, %OrderedWith.facet.5bd [concrete]
// CHECK:STDOUT:   %str.as.OrderedWith.impl.GreaterOrEquivalent.type: type = fn_type @str.as.OrderedWith.impl.GreaterOrEquivalent [concrete]
// CHECK:STDOUT:   %str.as.OrderedWith.impl.GreaterOrEquivalent: %str.as.OrderedWith.impl.GreaterOrEquivalent.type = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.a87: %str.as.EqWith.impl.Equal.type = import_ref Core//prelude/types/string, loc{{\d+_\d+}}, loaded [concrete = constants.%str.as.EqWith.impl.Equal]
// CHECK:STDOUT:   %Core.import_ref.adc9: %str.as.EqWith.impl.NotEqual.type = import_ref Core//prelude/types/string, loc{{\d+_\d+}}, loaded [concrete = constants.%str.as.EqWith.impl.NotEqual]
// CHECK:STDOUT:   %EqWith.impl_witness_table.bc8 = impl_witness_table (%Core.import_ref.a87, %Core.import_ref.adc9), @str.as.EqWith.impl.cf4 [concrete]
// CHECK:STDOUT:   %Core.import_ref.0e8: %str.as.OrderedWith.impl.Less.type = import_ref Core//prelude/types/string, loc{{\d+_\d+}}, loaded [concrete = constants.%str.as.OrderedWith.impl.Less]
// CHECK:STDOUT:   %Core.import_ref.714 = import_ref Core//prelude/types/string, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.6ed = import_ref Core//prelude/types/string, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.381: %str.as.OrderedWith.impl.GreaterOrEquivalent.type = import_ref Core//prelude/types/string, loc{{\d+_\d+}}, loaded [concrete = constants.%str.as.OrderedWith.impl.GreaterOrEquivalent]
// CHECK:STDOUT:   %OrderedWith.impl_witness_table.11c = impl_witness_table (%Core.import_ref.0e8, %Core.import_ref.714, %Core.import_ref.6ed, %Core.import_ref.381), @str.as.OrderedWith.impl.868 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Eq.decl: %Eq.type = fn_decl @Eq [concrete = constants.%Eq] {
// CHECK:STDOUT:     %a.param_patt: %pattern_type.adf = value_param_pattern [concrete = constants.%a.param_patt]
// CHECK:STDOUT:     %a.patt: %pattern_type.adf = wrapper_binding_pattern a, %a.param_patt [concrete = constants.%a.patt]
// CHECK:STDOUT:     %b.param_patt: %pattern_type.adf = value_param_pattern [concrete = constants.%b.param_patt]
// CHECK:STDOUT:     %b.patt: %pattern_type.adf = wrapper_binding_pattern b, %b.param_patt [concrete = constants.%b.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.831 = out_param_pattern [concrete = constants.%return.param_patt.5a1]
// CHECK:STDOUT:     %return.patt: %pattern_type.831 = return_slot_pattern %return.param_patt, %.loc5_26.1 [concrete = constants.%return.patt.c0c]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc5_26.1: type = type_literal bool [concrete = bool]
// CHECK:STDOUT:     %.loc5_26.2: Core.Form = init_form %.loc5_26.1 [concrete = constants.%.f34]
// CHECK:STDOUT:     %a.param: %str = value_param call_param0
// CHECK:STDOUT:     %str.loc5_10: type = type_literal constants.%str [concrete = constants.%str]
// CHECK:STDOUT:     %a: %str = wrapper_binding a, %a.param
// CHECK:STDOUT:     %b.param: %str = value_param call_param1
// CHECK:STDOUT:     %str.loc5_18: type = type_literal constants.%str [concrete = constants.%str]
// CHECK:STDOUT:     %b: %str = wrapper_binding b, %b.param
// CHECK:STDOUT:     %return.param: ref bool = out_param call_param2
// CHECK:STDOUT:     %return: ref bool = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Ne.decl: %Ne.type = fn_decl @Ne [concrete = constants.%Ne] {
// CHECK:STDOUT:     %a.param_patt: %pattern_type.adf = value_param_pattern [concrete = constants.%a.param_patt]
// CHECK:STDOUT:     %a.patt: %pattern_type.adf = wrapper_binding_pattern a, %a.param_patt [concrete = constants.%a.patt]
// CHECK:STDOUT:     %b.param_patt: %pattern_type.adf = value_param_pattern [concrete = constants.%b.param_patt]
// CHECK:STDOUT:     %b.patt: %pattern_type.adf = wrapper_binding_pattern b, %b.param_patt [concrete = constants.%b.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.831 = out_param_pattern [concrete = constants.%return.param_patt.5a1]
// CHECK:STDOUT:     %return.patt: %pattern_type.831 = return_slot_pattern %return.param_patt, %.loc6_26.1 [concrete = constants.%return.patt.c0c]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc6_26.1: type = type_literal bool [concrete = bool]
// CHECK:STDOUT:     %.loc6_26.2: Core.Form = init_form %.loc6_26.1 [concrete = constants.%.f34]
// CHECK:STDOUT:     %a.param: %str = value_param call_param0
// CHECK:STDOUT:     %str.loc6_10: type = type_literal constants.%str [concrete = constants.%str]
// CHECK:STDOUT:     %a: %str = wrapper_binding a, %a.param
// CHECK:STDOUT:     %b.param: %str = value_param call_param1
// CHECK:STDOUT:     %str.loc6_18: type = type_literal constants.%str [concrete = constants.%str]
// CHECK:STDOUT:     %b: %str = wrapper_binding b, %b.param
// CHECK:STDOUT:     %return.param: ref bool = out_param call_param2
// CHECK:STDOUT:     %return: ref bool = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Lt.decl: %Lt.type = fn_decl @Lt [concrete = constants.%Lt] {
// CHECK:STDOUT:     %a.param_patt: %pattern_type.adf = value_param_pattern [concrete = constants.%a.param_patt]
// CHECK:STDOUT:     %a.patt: %pattern_type.adf = wrapper_binding_pattern a, %a.param_patt [concrete = constants.%a.patt]
// CHECK:STDOUT:     %b.param_patt: %pattern_type.adf = value_param_pattern [concrete = constants.%b.param_patt]
// CHECK:STDOUT:     %b.patt: %pattern_type.adf = wrapper_binding_pattern b, %b.param_patt [concrete = constants.%b.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.831 = out_param_pattern [concrete = constants.%return.param_patt.5a1]
// CHECK:STDOUT:     %return.patt: %pattern_type.831 = return_slot_pattern %return.param_patt, %.loc7_26.1 [concrete = constants.%return.patt.c0c]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc7_26.1: type = type_literal bool [concrete = bool]
// CHECK:STDOUT:     %.loc7_26.2: Core.Form = init_form %.loc7_26.1 [concrete = constants.%.f34]
// CHECK:STDOUT:     %a.param: %str = value_param call_param0
// CHECK:STDOUT:     %str.loc7_10: type = type_literal constants.%str [concrete = constants.%str]
// CHECK:STDOUT:     %a: %str = wrapper_binding a, %a.param
// CHECK:STDOUT:     %b.param: %str = value_param call_param1
// CHECK:STDOUT:     %str.loc7_18: type = type_literal constants.%str [concrete = constants.%str]
// CHECK:STDOUT:     %b: %str = wrapper_binding b, %b.param
// CHECK:STDOUT:     %return.param: ref bool = out_param call_param2
// CHECK:STDOUT:     %return: ref bool = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Ge.decl: %Ge.type = fn_decl @Ge [concrete = constants.%Ge] {
// CHECK:STDOUT:     %a.param_patt: %pattern_type.adf = value_param_pattern [concrete = constants.%a.param_patt]
// CHECK:STDOUT:     %a.patt: %pattern_type.adf = wrapper_binding_pattern a, %a.param_patt [concrete = constants.%a.patt]
// CHECK:STDOUT:     %b.param_patt: %pattern_type.adf = value_param_pattern [concrete = constants.%b.param_patt]
// CHECK:STDOUT:     %b.patt: %pattern_type.adf = wrapper_binding_pattern b, %b.param_patt [concrete = constants.%b.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.831 = out_param_pattern [concrete = constants.%return.param_patt.5a1]
// CHECK:STDOUT:     %return.patt: %pattern_type.831 = return_slot_pattern %return.param_patt, %.loc8_26.1 [concrete = constants.%return.patt.c0c]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc8_26.1: type = type_literal bool [concrete = bool]
// CHECK:STDOUT:     %.loc8_26.2: Core.Form = init_form %.loc8_26.1 [concrete = constants.%.f34]
// CHECK:STDOUT:     %a.param: %str = value_param call_param0
// CHECK:STDOUT:     %str.loc8_10: type = type_literal constants.%str [concrete = constants.%str]
// CHECK:STDOUT:     %a: %str = wrapper_binding a, %a.param
// CHECK:STDOUT:     %b.param: %str = value_param call_param1
// CHECK:STDOUT:     %str.loc8_18: type = type_literal constants.%str [concrete = constants.%str]
// CHECK:STDOUT:     %b: %str = wrapper_binding b, %b.param
// CHECK:STDOUT:     %return.param: ref bool = out_param call_param2
// CHECK:STDOUT:     %return: ref bool = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Eq(%a.param: %str, %b.param: %str) -> out %return.param: bool {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %a.ref: %str = name_ref a, %a
// CHECK:STDOUT:   %b.ref: %str = name_ref b, %b
// CHECK:STDOUT:   %impl.elem0: %.58b = impl_witness_access constants.%EqWith.impl_witness.c84, element0 [concrete = constants.%str.as.EqWith.impl.Equal]
// CHECK:STDOUT:   %bound_method: <bound method> = bound_method %a.ref, %impl.elem0
// CHECK:STDOUT:   %str.as.EqWith.impl.Equal.call: init bool = call %bound_method(%a.ref, %b.ref)
// CHECK:STDOUT:   return %str.as.EqWith.impl.Equal.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Ne(%a.param: %str, %b.param: %str) -> out %return.param: bool {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %a.ref: %str = name_ref a, %a
// CHECK:STDOUT:   %b.ref: %str = name_ref b, %b
// CHECK:STDOUT:   %impl.elem1: %.44b = impl_witness_access constants.%EqWith.impl_witness.c84, element1 [concrete = constants.%str.as.EqWith.impl.NotEqual]
// CHECK:STDOUT:   %bound_method: <bound method> = bound_method %a.ref, %impl.elem1
// CHECK:STDOUT:   %str.as.EqWith.impl.NotEqual.call: init bool = call %bound_method(%a.ref, %b.ref)
// CHECK:STDOUT:   return %str.as.EqWith.impl.NotEqual.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Lt(%a.param: %str, %b.param: %str) -> out %return.param: bool {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %a.ref: %str = name_ref a, %a
// CHECK:STDOUT:   %b.ref: %str = name_ref b, %b
// CHECK:STDOUT:   %impl.elem0: %.013 = impl_witness_access constants.%OrderedWith.impl_witness.3fd, element0 [concrete = constants.%str.as.OrderedWith.impl.Less]
// CHECK:STDOUT:   %bound_method: <bound method> = bound_method %a.ref, %impl.elem0
// CHECK:STDOUT:   %str.as.OrderedWith.impl.Less.call: init bool = call %bound_method(%a.ref, %b.ref)
// CHECK:STDOUT:   return %str.as.OrderedWith.impl.Less.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Ge(%a.param: %str, %b.param: %str) -> out %return.param: bool {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %a.ref: %str = name_ref a, %a
// CHECK:STDOUT:   %b.ref: %str = name_ref b, %b
// CHECK:STDOUT:   %impl.elem3: %.f77 = impl_witness_access constants.%OrderedWith.impl_witness.3fd, element3 [concrete = constants.%str.as.OrderedWith.impl.GreaterOrEquivalent]
// CHECK:STDOUT:   %bound_method: <bound method> = bound_method %a.ref, %impl.elem3
// CHECK:STDOUT:   %str.as.OrderedWith.impl.GreaterOrEquivalent.call: init bool = call %bound_method(%a.ref, %b.ref)
// CHECK:STDOUT:   return %str.as.OrderedWith.impl.GreaterOrEquivalent.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- mixed.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %StringBuf: type = class_type @StringBuf [concrete]
// CHECK:STDOUT:   %pattern_type.5d2: type = pattern_type %StringBuf [concrete]
// CHECK:STDOUT:   %a.param_patt.627: %pattern_type.5d2 = value_param_pattern [concrete]
// CHECK:STDOUT:   %a.patt.f1f: %pattern_type.5d2 = wrapper_binding_pattern a, %a.param_patt.627 [concrete]
// CHECK:STDOUT:   %str: type = class_type @String [concrete]
// CHECK:STDOUT:   %pattern_type.adf: type = pattern_type %str [concrete]
// CHECK:STDOUT:   %b.param_patt.303: %pattern_type.adf = value_param_pattern [concrete]
// CHECK:STDOUT:   %b.patt.42c: %pattern_type.adf = wrapper_binding_pattern b, %b.param_patt.303 [concrete]
// CHECK:STDOUT:   %.f34: Core.Form = init_form bool [concrete]
// CHECK:STDOUT:   %pattern_type.831: type = pattern_type bool [concrete]
// CHECK:STDOUT:   %return.param_patt.5a1: %pattern_type.831 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.c0c: %pattern_type.831 = return_slot_pattern %return.param_patt.5a1, bool [concrete]
// CHECK:STDOUT:   %EqBufStr.type: type = fn_type @EqBufStr [concrete]
// CHECK:STDOUT:   %EqBufStr: %EqBufStr.type = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.type.f77: type = generic_interface_type @EqWith [concrete]
// CHECK:STDOUT:   %EqWith.generic: %EqWith.type.f77 = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.type.ca1: type = facet_type <@EqWith, @EqWith(%str)> [concrete]
// CHECK:STDOUT:   %EqWith.impl_witness.db3: <witness> = impl_witness imports.%EqWith.impl_witness_table.71d [concrete]
// CHECK:STDOUT:   %EqWith.facet.1bf: %EqWith.type.ca1 = facet_value %StringBuf, (%EqWith.impl_witness.db3) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.72c: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%str, %EqWith.facet.1bf) [concrete]
// CHECK:STDOUT:   %.d30: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.72c, %EqWith.facet.1bf [concrete]
// CHECK:STDOUT:   %StringBuf.as.EqWith.impl.Equal.type: type = fn_type @StringBuf.as.EqWith.impl.Equal [concrete]
// CHECK:STDOUT:   %StringBuf.as.EqWith.impl.Equal: %StringBuf.as.EqWith.impl.Equal.type = struct_value () [concrete]
// CHECK:STDOUT:   %a.param_patt.300: %pattern_type.adf = value_param_pattern [concrete]
// CHECK:STDOUT:   %a.patt.f11: %pattern_type.adf = wrapper_binding_pattern a, %a.param_patt.300 [concrete]
// CHECK:STDOUT:   %b.param_patt.973: %pattern_type.5d2 = value_param_pattern [concrete]
// CHECK:STDOUT:   %b.patt.0e7: %pattern_type.5d2 = wrapper_binding_pattern b, %b.param_patt.973 [concrete]
// CHECK:STDOUT:   %LtStrBuf.type: type = fn_type @LtStrBuf [concrete]
// CHECK:STDOUT:   %LtStrBuf: %LtStrBuf.type = struct_value () [concrete]
// CHECK:STDOUT:   %OrderedWith.type.ad8: type = generic_interface_type @OrderedWith [concrete]
// CHECK:STDOUT:   %OrderedWith.generic: %OrderedWith.type.ad8 = struct_value () [concrete]
// CHECK:STDOUT:   %OrderedWith.type.a9e: type = facet_type <@OrderedWith, @OrderedWith(%StringBuf)> [concrete]
// CHECK:STDOUT:   %OrderedWith.impl_witness.aa6: <witness> = impl_witness imports.%OrderedWith.impl_witness_table.f43 [concrete]
// CHECK:STDOUT:   %OrderedWith.facet.177: %OrderedWith.type.a9e = facet_value %str, (%OrderedWith.impl_witness.aa6) [concrete]
// CHECK:STDOUT:   %OrderedWith.WithSelf.Less.type.8b6: type = fn_type @OrderedWith.WithSelf.Less, @OrderedWith.WithSelf(%StringBuf, %OrderedWith.facet.177) [concrete]
// CHECK:STDOUT:   %.9ae: type = fn_type_with_self_type %OrderedWith.WithSelf.Less.type.8b6, %OrderedWith.facet.177 [concrete]
// CHECK:STDOUT:   %str.as.OrderedWith.impl.Less.type: type = fn_type @str.as.OrderedWith.impl.Less [concrete]
// CHECK:STDOUT:   %str.as.OrderedWith.impl.Less: %str.as.OrderedWith.impl.Less.type = struct_value () [concrete]
// CHECK:STDOUT:   %GtBufBuf.type: type = fn_type @GtBufBuf [concrete]
// CHECK:STDOUT:   %GtBufBuf: %GtBufBuf.type = struct_value () [concrete]
// CHECK:STDOUT:   %OrderedWith.impl_witness.8a1: <witness> = impl_witness imports.%OrderedWith.impl_witness_table.da7 [concrete]
// CHECK:STDOUT:   %OrderedWith.facet.226: %OrderedWith.type.a9e = facet_value %StringBuf, (%OrderedWith.impl_witness.8a1) [concrete]
// CHECK:STDOUT:   %OrderedWith.WithSelf.Greater.type.b4d: type = fn_type @OrderedWith.WithSelf.Greater, @OrderedWith.WithSelf(%StringBuf, %OrderedWith.facet.226) [concrete]
// CHECK:STDOUT:   %.14c: type = fn_type_with_self_type %OrderedWith.WithSelf.Greater.type.b4d, %OrderedWith.facet.226 [concrete]
// CHECK:STDOUT:   %StringBuf.as.OrderedWith.impl.Greater.type: type = fn_type @StringBuf.as.OrderedWith.impl.Greater [concrete]
// CHECK:STDOUT:   %StringBuf.as.OrderedWith.impl.Greater: %StringBuf.as.OrderedWith.impl.Greater.type = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .StringBuf = %Core.StringBuf
// CHECK:STDOUT:     .String = %Core.String
// CHECK:STDOUT:     .Bool = %Core.Bool
// CHECK:STDOUT:     .EqWith = %Core.EqWith
// CHECK:STDOUT:     .OrderedWith = %Core.OrderedWith
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.StringBuf: type = import_ref Core//prelude/types/string, StringBuf, loaded [concrete = constants.%StringBuf]
// CHECK:STDOUT:   %Core.String: type = import_ref Core//prelude/types/string, String, loaded [concrete = constants.%str]
// CHECK:STDOUT:   %Core.Bool: type = import_ref Core//prelude/types/bool, Bool, loaded [concrete = bool]
// CHECK:STDOUT:   %Core.EqWith: %EqWith.type.f77 = import_ref Core//prelude/operators/comparison, EqWith, loaded [concrete = constants.%EqWith.generic]
// CHECK:STDOUT:   %Core.import_ref.a87: %StringBuf.as.EqWith.impl.Equal.type = import_ref Core//prelude/types/string, loc{{\d+_\d+}}, loaded [concrete = constants.%StringBuf.as.EqWith.impl.Equal]
// CHECK:STDOUT:   %Core.import_ref.e3a = import_ref Core//prelude/types/string, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.71d = impl_witness_table (%Core.import_ref.a87, %Core.import_ref.e3a), @StringBuf.as.EqWith.impl.c69 [concrete]
// CHECK:STDOUT:   %Core.OrderedWith: %OrderedWith.type.ad8 = import_ref Core//prelude/operators/comparison, OrderedWith, loaded [concrete = constants.%OrderedWith.generic]
// CHECK:STDOUT:   %Core.import_ref.0e8: %str.as.OrderedWith.impl.Less.type = import_ref Core//prelude/types/string, loc{{\d+_\d+}}, loaded [concrete = constants.%str.as.OrderedWith.impl.Less]
// CHECK:STDOUT:   %Core.import_ref.714485.1 = import_ref Core//prelude/types/string, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.6ed6 = import_ref Core//prelude/types/string, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.cba3d9.1 = import_ref Core//prelude/types/string, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %OrderedWith.impl_witness_table.f43 = impl_witness_table (%Core.import_ref.0e8, %Core.import_ref.714485.1, %Core.import_ref.6ed6, %Core.import_ref.cba3d9.1), @str.as.OrderedWith.impl.db8 [concrete]
// CHECK:STDOUT:   %Core.import_ref.255 = import_ref Core//prelude/types/string, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.714485.2 = import_ref Core//prelude/types/string, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.c32c: %StringBuf.as.OrderedWith.impl.Greater.type = import_ref Core//prelude/types/string, loc{{\d+_\d+}}, loaded [concrete = constants.%StringBuf.as.OrderedWith.impl.Greater]
// CHECK:STDOUT:   %Core.import_ref.cba3d9.2 = import_ref Core//prelude/types/string, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %OrderedWith.impl_witness_table.da7 = impl_witness_table (%Core.import_ref.255, %Core.import_ref.714485.2, %Core.import_ref.c32c, %Core.import_ref.cba3d9.2), @StringBuf.as.OrderedWith.impl.c8d [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %EqBufStr.decl: %EqBufStr.type = fn_decl @EqBufStr [concrete = constants.%EqBufStr] {
// CHECK:STDOUT:     %a.param_patt: %pattern_type.5d2 = value_param_pattern [concrete = constants.%a.param_patt.627]
// CHECK:STDOUT:     %a.patt: %pattern_type.5d2 = wrapper_binding_pattern a, %a.param_patt [concrete = constants.%a.patt.f1f]
// CHECK:STDOUT:     %b.param_patt: %pattern_type.adf = value_param_pattern [concrete = constants.%b.param_patt.303]
// CHECK:STDOUT:     %b.patt: %pattern_type.adf = wrapper_binding_pattern b, %b.param_patt [concrete = constants.%b.patt.42c]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.831 = out_param_pattern [concrete = constants.%return.param_patt.5a1]
// CHECK:STDOUT:     %return.patt: %pattern_type.831 = return_slot_pattern %return.param_patt, %.loc5_43.1 [concrete = constants.%return.patt.c0c]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc5_43.1: type = type_literal bool [concrete = bool]
// CHECK:STDOUT:     %.loc5_43.2: Core.Form = init_form %.loc5_43.1 [concrete = constants.%.f34]
// CHECK:STDOUT:     %a.param: %StringBuf = value_param call_param0
// CHECK:STDOUT:     %.loc5_20: type = splice_block %StringBuf.ref [concrete = constants.%StringBuf] {
// CHECK:STDOUT:       %Core.ref: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %StringBuf.ref: type = name_ref StringBuf, imports.%Core.StringBuf [concrete = constants.%StringBuf]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %a: %StringBuf = wrapper_binding a, %a.param
// CHECK:STDOUT:     %b.param: %str = value_param call_param1
// CHECK:STDOUT:     %str: type = type_literal constants.%str [concrete = constants.%str]
// CHECK:STDOUT:     %b: %str = wrapper_binding b, %b.param
// CHECK:STDOUT:     %return.param: ref bool = out_param call_param2
// CHECK:STDOUT:     %return: ref bool = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %LtStrBuf.decl: %LtStrBuf.type = fn_decl @LtStrBuf [concrete = constants.%LtStrBuf] {
// CHECK:STDOUT:     %a.param_patt: %pattern_type.adf = value_param_pattern [concrete = constants.%a.param_patt.300]
// CHECK:STDOUT:     %a.patt: %pattern_type.adf = wrapper_binding_pattern a, %a.param_patt [concrete = constants.%a.patt.f11]
// CHECK:STDOUT:     %b.param_patt: %pattern_type.5d2 = value_param_pattern [concrete = constants.%b.param_patt.973]
// CHECK:STDOUT:     %b.patt: %pattern_type.5d2 = wrapper_binding_pattern b, %b.param_patt [concrete = constants.%b.patt.0e7]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.831 = out_param_pattern [concrete = constants.%return.param_patt.5a1]
// CHECK:STDOUT:     %return.patt: %pattern_type.831 = return_slot_pattern %return.param_patt, %.loc6_43.1 [concrete = constants.%return.patt.c0c]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc6_43.1: type = type_literal bool [concrete = bool]
// CHECK:STDOUT:     %.loc6_43.2: Core.Form = init_form %.loc6_43.1 [concrete = constants.%.f34]
// CHECK:STDOUT:     %a.param: %str = value_param call_param0
// CHECK:STDOUT:     %str: type = type_literal constants.%str [concrete = constants.%str]
// CHECK:STDOUT:     %a: %str = wrapper_binding a, %a.param
// CHECK:STDOUT:     %b.param: %StringBuf = value_param call_param1
// CHECK:STDOUT:     %.loc6_28: type = splice_block %StringBuf.ref [concrete = constants.%StringBuf] {
// CHECK:STDOUT:       %Core.ref: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %StringBuf.ref: type = name_ref StringBuf, imports.%Core.StringBuf [concrete = constants.%StringBuf]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %b: %StringBuf = wrapper_binding b, %b.param
// CHECK:STDOUT:     %return.param: ref bool = out_param call_param2
// CHECK:STDOUT:     %return: ref bool = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %GtBufBuf.decl: %GtBufBuf.type = fn_decl @GtBufBuf [concrete = constants.%GtBufBuf] {
// CHECK:STDOUT:     %a.param_patt: %pattern_type.5d2 = value_param_pattern [concrete = constants.%a.param_patt.627]
// CHECK:STDOUT:     %a.patt: %pattern_type.5d2 = wrapper_binding_pattern a, %a.param_patt [concrete = constants.%a.patt.f1f]
// CHECK:STDOUT:     %b.param_patt: %pattern_type.5d2 = value_param_pattern [concrete = constants.%b.param_patt.973]
// CHECK:STDOUT:     %b.patt: %pattern_type.5d2 = wrapper_binding_pattern b, %b.param_patt [concrete = constants.%b.patt.0e7]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.831 = out_param_pattern [concrete = constants.%return.param_patt.5a1]
// CHECK:STDOUT:     %return.patt: %pattern_type.831 = return_slot_pattern %return.param_patt, %.loc7_54.1 [concrete = constants.%return.patt.c0c]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc7_54.1: type = type_literal bool [concrete = bool]
// CHECK:STDOUT:     %.loc7_54.2: Core.Form = init_form %.loc7_54.1 [concrete = constants.%.f34]
// CHECK:STDOUT:     %a.param: %StringBuf = value_param call_param0
// CHECK:STDOUT:     %.loc7_20: type = splice_block %StringBuf.ref.loc7_20 [concrete = constants.%StringBuf] {
// CHECK:STDOUT:       %Core.ref.loc7_16: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %StringBuf.ref.loc7_20: type = name_ref StringBuf, imports.%Core.StringBuf [concrete = constants.%StringBuf]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %a: %StringBuf = wrapper_binding a, %a.param
// CHECK:STDOUT:     %b.param: %StringBuf = value_param call_param1
// CHECK:STDOUT:     %.loc7_39: type = splice_block %StringBuf.ref.loc7_39 [concrete = constants.%StringBuf] {
// CHECK:STDOUT:       %Core.ref.loc7_35: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %StringBuf.ref.loc7_39: type = name_ref StringBuf, imports.%Core.StringBuf [concrete = constants.%StringBuf]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %b: %StringBuf = wrapper_binding b, %b.param
// CHECK:STDOUT:     %return.param: ref bool = out_param call_param2
// CHECK:STDOUT:     %return: ref bool = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @EqBufStr(%a.param: %StringBuf, %b.param: %str) -> out %return.param: bool {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %a.ref: %StringBuf = name_ref a, %a
// CHECK:STDOUT:   %b.ref: %str = name_ref b, %b
// CHECK:STDOUT:   %impl.elem0: %.d30 = impl_witness_access constants.%EqWith.impl_witness.db3, element0 [concrete = constants.%StringBuf.as.EqWith.impl.Equal]
// CHECK:STDOUT:   %bound_method: <bound method> = bound_method %a.ref, %impl.elem0
// CHECK:STDOUT:   %StringBuf.as.EqWith.impl.Equal.call: init bool = call %bound_method(%a.ref, %b.ref)
// CHECK:STDOUT:   return %StringBuf.as.EqWith.impl.Equal.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @LtStrBuf(%a.param: %str, %b.param: %StringBuf) -> out %return.param: bool {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %a.ref: %str = name_ref a, %a
// CHECK:STDOUT:   %b.ref: %StringBuf = name_ref b, %b
// CHECK:STDOUT:   %impl.elem0: %.9ae = impl_witness_access constants.%OrderedWith.impl_witness.aa6, element0 [concrete = constants.%str.as.OrderedWith.impl.Less]
// CHECK:STDOUT:   %bound_method: <bound method> = bound_method %a.ref, %impl.elem0
// CHECK:STDOUT:   %str.as.OrderedWith.impl.Less.call: init bool = call %bound_method(%a.ref, %b.ref)
// CHECK:STDOUT:   return %str.as.OrderedWith.impl.Less.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @GtBufBuf(%a.param: %StringBuf, %b.param: %StringBuf) -> out %return.param: bool {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %a.ref: %StringBuf = name_ref a, %a
// CHECK:STDOUT:   %b.ref: %StringBuf = name_ref b, %b
// CHECK:STDOUT:   %impl.elem2: %.14c = impl_witness_access constants.%OrderedWith.impl_witness.8a1, element2 [concrete = constants.%StringBuf.as.OrderedWith.impl.Greater]
// CHECK:STDOUT:   %bound_method: <bound method> = bound_method %a.ref, %impl.elem2
// CHECK:STDOUT:   %StringBuf.as.OrderedWith.impl.Greater.call: init bool = call %bound_method(%a.ref, %b.ref)
// CHECK:STDOUT:   return %StringBuf.as.OrderedWith.impl.Greater.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- generic.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %facet_type: type = facet_type <@Copy & @Ordered> [concrete]
// CHECK:STDOUT:   %Min.type: type = fn_type @Min [concrete]
// CHECK:STDOUT:   %Min: %Min.type = struct_value () [concrete]
// CHECK:STDOUT:   %str.3d4: type = class_type @String [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %char: type = class_type @Char [concrete]
// CHECK:STDOUT:   %ptr.b46: type = ptr_type %char [concrete]
// CHECK:STDOUT:   %.8e1: Core.Form = init_form %str.3d4 [concrete]
// CHECK:STDOUT:   %pattern_type.adf: type = pattern_type %str.3d4 [concrete]
// CHECK:STDOUT:   %return.param_patt.59a: %pattern_type.adf = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.156: %pattern_type.adf = return_slot_pattern %return.param_patt.59a, %str.3d4 [concrete]
// CHECK:STDOUT:   %UseMin.type: type = fn_type @UseMin [concrete]
// CHECK:STDOUT:   %UseMin: %UseMin.type = struct_value () [concrete]
// CHECK:STDOUT:   %str.714: %ptr.b46 = string_literal "pear" [concrete]
// CHECK:STDOUT:   %int_4: %i64 = int_value 4 [concrete]
// CHECK:STDOUT:   %String.val.0b5: %str.3d4 = struct_value (%str.714, %int_4) [concrete]
// CHECK:STDOUT:   %str.112: %ptr.b46 = string_literal "apple" [concrete]
// CHECK:STDOUT:   %int_5: %i64 = int_value 5 [concrete]
// CHECK:STDOUT:   %String.val.5ec: %str.3d4 = struct_value (%str.112, %int_5) [concrete]
// CHECK:STDOUT:   %OrderedWith.impl_witness.3fd: <witness> = impl_witness imports.%OrderedWith.impl_witness_table.11c [concrete]
// CHECK:STDOUT:   %Copy.impl_witness.e29: <witness> = impl_witness imports.%Copy.impl_witness_table.e53 [concrete]
// CHECK:STDOUT:   %facet_value: %facet_type = facet_value %str.3d4, (%OrderedWith.impl_witness.3fd, %Copy.impl_witness.e29) [concrete]
// CHECK:STDOUT:   %Min.specific_fn: <specific function> = specific_function %Min, @Min(%facet_value) [concrete]
// CHECK:STDOUT:   %str.as.OrderedWith.impl.Less.type: type = fn_type @str.as.OrderedWith.impl.Less [concrete]
// CHECK:STDOUT:   %str.as.OrderedWith.impl.Less: %str.as.OrderedWith.impl.Less.type = struct_value () [concrete]
// CHECK:STDOUT:   %str.as.Copy.impl.Op.type: type = fn_type @str.as.Copy.impl.Op [concrete]
// CHECK:STDOUT:   %str.as.Copy.impl.Op: %str.as.Copy.impl.Op.type = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.0e8: %str.as.OrderedWith.impl.Less.type = import_ref Core//prelude/types/string, loc{{\d+_\d+}}, loaded [concrete = constants.%str.as.OrderedWith.impl.Less]
// CHECK:STDOUT:   %Core.import_ref.714 = import_ref Core//prelude/types/string, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.6ed = import_ref Core//prelude/types/string, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.cba = import_ref Core//prelude/types/string, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %OrderedWith.impl_witness_table.11c = impl_witness_table (%Core.import_ref.0e8, %Core.import_ref.714, %Core.import_ref.6ed, %Core.import_ref.cba), @str.as.OrderedWith.impl.868 [concrete]
// CHECK:STDOUT:   %Core.import_ref.283: %str.as.Copy.impl.Op.type = import_ref Core//prelude/types/string, loc{{\d+_\d+}}, loaded [concrete = constants.%str.as.Copy.impl.Op]
// CHECK:STDOUT:   %Copy.impl_witness_table.e53 = impl_witness_table (%Core.import_ref.283), @str.as.Copy.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %UseMin.decl: %UseMin.type = fn_decl @UseMin [concrete = constants.%UseMin] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.adf = out_param_pattern [concrete = constants.%return.param_patt.59a]
// CHECK:STDOUT:     %return.patt: %pattern_type.adf = return_slot_pattern %return.param_patt, %str.loc9_16 [concrete = constants.%return.patt.156]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %str.loc9_16: type = type_literal constants.%str.3d4 [concrete = constants.%str.3d4]
// CHECK:STDOUT:     %.loc9_16.2: Core.Form = init_form %str.loc9_16 [concrete = constants.%.8e1]
// CHECK:STDOUT:     %return.param: ref %str.3d4 = out_param call_param0
// CHECK:STDOUT:     %return: ref %str.3d4 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @UseMin() -> out %return.param: %str.3d4 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Min.ref: %Min.type = name_ref Min, file.%Min.decl [concrete = constants.%Min]
// CHECK:STDOUT:   %str.loc9_33: %ptr.b46 = string_literal "pear" [concrete = constants.%str.714]
// CHECK:STDOUT:   %int_4: %i64 = int_value 4 [concrete = constants.%int_4]
// CHECK:STDOUT:   %String.val.loc9_33: %str.3d4 = struct_value (%str.loc9_33, %int_4) [concrete = constants.%String.val.0b5]
// CHECK:STDOUT:   %str.loc9_41: %ptr.b46 = string_literal "apple" [concrete = constants.%str.112]
// CHECK:STDOUT:   %int_5: %i64 = int_value 5 [concrete = constants.%int_5]
// CHECK:STDOUT:   %String.val.loc9_41: %str.3d4 = struct_value (%str.loc9_41, %int_5) [concrete = constants.%String.val.5ec]
// CHECK:STDOUT:   %facet_value.loc9_48.1: %facet_type = facet_value constants.%str.3d4, (constants.%OrderedWith.impl_witness.3fd, constants.%Copy.impl_witness.e29) [concrete = constants.%facet_value]
// CHECK:STDOUT:   %.loc9_48.1: %facet_type = converted constants.%str.3d4, %facet_value.loc9_48.1 [concrete = constants.%facet_value]
// CHECK:STDOUT:   %facet_value.loc9_48.2: %facet_type = facet_value constants.%str.3d4, (constants.%OrderedWith.impl_witness.3fd, constants.%Copy.impl_witness.e29) [concrete = constants.%facet_value]
// CHECK:STDOUT:   %.loc9_48.2: %facet_type = converted constants.%str.3d4, %facet_value.loc9_48.2 [concrete = constants.%facet_value]
// CHECK:STDOUT:   %facet_value.loc9_48.3: %facet_type = facet_value constants.%str.3d4, (constants.%OrderedWith.impl_witness.3fd, constants.%Copy.impl_witness.e29) [concrete = constants.%facet_value]
// CHECK:STDOUT:   %.loc9_48.3: %facet_type = converted constants.%str.3d4, %facet_value.loc9_48.3 [concrete = constants.%facet_value]
// CHECK:STDOUT:   %facet_value.loc9_48.4: %facet_type = facet_value constants.%str.3d4, (constants.%OrderedWith.impl_witness.3fd, constants.%Copy.impl_witness.e29) [concrete = constants.%facet_value]
// CHECK:STDOUT:   %.loc9_48.4: %facet_type = converted constants.%str.3d4, %facet_value.loc9_48.4 [concrete = constants.%facet_value]
// CHECK:STDOUT:   %Min.specific_fn: <specific function> = specific_function %Min.ref, @Min(constants.%facet_value) [concrete = constants.%Min.specific_fn]
// CHECK:STDOUT:   %.loc9_16.1: ref %str.3d4 = splice_block %return.param {}
// CHECK:STDOUT:   %Min.call: init %str.3d4 to %.loc9_16.1 = call %Min.specific_fn(%String.val.loc9_33, %String.val.loc9_41)
// CHECK:STDOUT:   return %Min.call to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
