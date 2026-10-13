// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/named_constraint/template_constraint.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/named_constraint/template_constraint.carbon

// --- decl.carbon
library "[[@TEST_NAME]]";
//@include-in-dumps

// A `template constraint` declares structural member requirements: a method
// requirement and an associated-function requirement (fork decision F-010 /
// SC-1, D-SC-1, D-SC-2). `Self` is a template-phase binding here (D-SC-10).
template constraint HasGet {
  fn Get(self) -> i32;
  fn Make() -> Self;
}

// --- forward.carbon
library "[[@TEST_NAME]]";
//@include-in-dumps

// A forward declaration and its definition agree on `template` (D-SC-16).
template constraint F;

template constraint F {
  fn G(ref self);
}

// --- compose.carbon
library "[[@TEST_NAME]]";
//@include-in-dumps

// Nominal requirements still compose with structural ones.
template constraint Both {
  fn Get(self) -> i32;
  require impls Core.Destroy;
}

// --- generic.carbon
library "[[@TEST_NAME]]";
//@include-in-dumps

// A generic template constraint: the with-self generic is over `(T, Self)`.
template constraint Has(T: type) {
  fn Get(self) -> T;
}

// CHECK:STDOUT: --- decl.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %HasGet.type: type = facet_type <@HasGet> [concrete]
// CHECK:STDOUT:   %Self: %HasGet.type = symbolic_binding Self, 0, template [template]
// CHECK:STDOUT:   %Self.as_type: type = facet_access_type %Self [template]
// CHECK:STDOUT:   %pattern_type.9c6: type = pattern_type %Self.as_type [template]
// CHECK:STDOUT:   %self.param_patt: %pattern_type.9c6 = value_param_pattern [template]
// CHECK:STDOUT:   %self.patt: %pattern_type.9c6 = wrapper_binding_pattern self, %self.param_patt [template]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %Int.type: type = generic_class_type @Int [concrete]
// CHECK:STDOUT:   %Int.generic: %Int.type = struct_value () [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %.795: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %HasGet.WithSelf.Get.type: type = fn_type @HasGet.WithSelf.Get, @HasGet.WithSelf(%Self) [template]
// CHECK:STDOUT:   %HasGet.WithSelf.Get: %HasGet.WithSelf.Get.type = struct_value () [template]
// CHECK:STDOUT:   %.9e4: Core.Form = init_form %Self.as_type [template]
// CHECK:STDOUT:   %return.param_patt.d28: %pattern_type.9c6 = out_param_pattern [template]
// CHECK:STDOUT:   %return.patt.c85: %pattern_type.9c6 = return_slot_pattern %return.param_patt.d28, %Self.as_type [template]
// CHECK:STDOUT:   %HasGet.WithSelf.Make.type: type = fn_type @HasGet.WithSelf.Make, @HasGet.WithSelf(%Self) [template]
// CHECK:STDOUT:   %HasGet.WithSelf.Make: %HasGet.WithSelf.Make.type = struct_value () [template]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .Int = %Core.Int
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Int: %Int.type = import_ref Core//prelude/types/int, Int, loaded [concrete = constants.%Int.generic]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   package: <namespace> = namespace [concrete] {
// CHECK:STDOUT:     .Core = imports.%Core
// CHECK:STDOUT:     .HasGet = %HasGet.decl
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.import = import Core
// CHECK:STDOUT:   %HasGet.decl: type = constraint_decl @HasGet [concrete = constants.%HasGet.type] {} {}
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: constraint @HasGet {
// CHECK:STDOUT:   %Self: %HasGet.type = symbolic_binding Self, 0, template [template = constants.%Self]
// CHECK:STDOUT:   %HasGet.WithSelf.decl = constraint_with_self_decl @HasGet [concrete]
// CHECK:STDOUT:
// CHECK:STDOUT: !with Self:
// CHECK:STDOUT:   %HasGet.WithSelf.Get.decl: @HasGet.WithSelf.%HasGet.WithSelf.Get.type (%HasGet.WithSelf.Get.type) = fn_decl @HasGet.WithSelf.Get [template = @HasGet.WithSelf.%HasGet.WithSelf.Get (constants.%HasGet.WithSelf.Get)] {
// CHECK:STDOUT:     %self.param_patt.loc8_10.1: @HasGet.WithSelf.Get.%pattern_type (%pattern_type.9c6) = value_param_pattern [template = %self.param_patt.loc8_10.2 (constants.%self.param_patt)]
// CHECK:STDOUT:     %self.patt.loc8_10.1: @HasGet.WithSelf.Get.%pattern_type (%pattern_type.9c6) = wrapper_binding_pattern self, %self.param_patt.loc8_10.1 [template = %self.patt.loc8_10.2 (constants.%self.patt)]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc8_19: Core.Form = init_form %i32 [concrete = constants.%.795]
// CHECK:STDOUT:     %self.param: @HasGet.WithSelf.Get.%Self.as_type.loc8_10.1 (%Self.as_type) = value_param call_param0
// CHECK:STDOUT:     %.loc8_10.1: type = splice_block %.loc8_10.2 [template = %Self.as_type.loc8_10.1 (constants.%Self.as_type)] {
// CHECK:STDOUT:       %Self.ref: %HasGet.type = name_ref Self, @HasGet.%Self [template = %Self (constants.%Self)]
// CHECK:STDOUT:       %Self.as_type.loc8_10.2: type = facet_access_type %Self.ref [template = %Self.as_type.loc8_10.1 (constants.%Self.as_type)]
// CHECK:STDOUT:       %.loc8_10.2: type = converted %Self.ref, %Self.as_type.loc8_10.2 [template = %Self.as_type.loc8_10.1 (constants.%Self.as_type)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %self: @HasGet.WithSelf.Get.%Self.as_type.loc8_10.1 (%Self.as_type) = wrapper_binding self, %self.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %HasGet.WithSelf.Make.decl: @HasGet.WithSelf.%HasGet.WithSelf.Make.type (%HasGet.WithSelf.Make.type) = fn_decl @HasGet.WithSelf.Make [template = @HasGet.WithSelf.%HasGet.WithSelf.Make (constants.%HasGet.WithSelf.Make)] {
// CHECK:STDOUT:     %return.param_patt.loc9_16.1: @HasGet.WithSelf.Make.%pattern_type (%pattern_type.9c6) = out_param_pattern [template = %return.param_patt.loc9_16.2 (constants.%return.param_patt.d28)]
// CHECK:STDOUT:     %return.patt.loc9_13.1: @HasGet.WithSelf.Make.%pattern_type (%pattern_type.9c6) = return_slot_pattern %return.param_patt.loc9_16.1, %.loc9_16.2 [template = %return.patt.loc9_13.2 (constants.%return.patt.c85)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %Self.ref: %HasGet.type = name_ref Self, @HasGet.%Self [template = %Self (constants.%Self)]
// CHECK:STDOUT:     %Self.as_type.loc9_16.2: type = facet_access_type %Self.ref [template = %Self.as_type.loc9_16.1 (constants.%Self.as_type)]
// CHECK:STDOUT:     %.loc9_16.2: type = converted %Self.ref, %Self.as_type.loc9_16.2 [template = %Self.as_type.loc9_16.1 (constants.%Self.as_type)]
// CHECK:STDOUT:     %.loc9_16.3: Core.Form = init_form %.loc9_16.2 [template = %.loc9_16.1 (constants.%.9e4)]
// CHECK:STDOUT:     %return.param: ref @HasGet.WithSelf.Make.%Self.as_type.loc9_16.1 (%Self.as_type) = out_param call_param0
// CHECK:STDOUT:     %return: ref @HasGet.WithSelf.Make.%Self.as_type.loc9_16.1 (%Self.as_type) = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:
// CHECK:STDOUT: !members:
// CHECK:STDOUT:   .Self = %Self
// CHECK:STDOUT:   .Get = @HasGet.WithSelf.%HasGet.WithSelf.Get.decl
// CHECK:STDOUT:   .Make = @HasGet.WithSelf.%HasGet.WithSelf.Make.decl
// CHECK:STDOUT:
// CHECK:STDOUT: !requires:
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @HasGet.WithSelf.Get(@HasGet.%Self: %HasGet.type) {
// CHECK:STDOUT:   %Self: %HasGet.type = symbolic_binding Self, 0, template [template = %Self (constants.%Self)]
// CHECK:STDOUT:   %Self.as_type.loc8_10.1: type = facet_access_type %Self [template = %Self.as_type.loc8_10.1 (constants.%Self.as_type)]
// CHECK:STDOUT:   %pattern_type: type = pattern_type %Self.as_type.loc8_10.1 [template = %pattern_type (constants.%pattern_type.9c6)]
// CHECK:STDOUT:   %self.param_patt.loc8_10.2: @HasGet.WithSelf.Get.%pattern_type (%pattern_type.9c6) = value_param_pattern [template = %self.param_patt.loc8_10.2 (constants.%self.param_patt)]
// CHECK:STDOUT:   %self.patt.loc8_10.2: @HasGet.WithSelf.Get.%pattern_type (%pattern_type.9c6) = wrapper_binding_pattern self, %self.param_patt.loc8_10.2 [template = %self.patt.loc8_10.2 (constants.%self.patt)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%self.param: @HasGet.WithSelf.Get.%Self.as_type.loc8_10.1 (%Self.as_type)) -> out %return.param: %i32;
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @HasGet.WithSelf.Make(@HasGet.%Self: %HasGet.type) {
// CHECK:STDOUT:   %Self: %HasGet.type = symbolic_binding Self, 0, template [template = %Self (constants.%Self)]
// CHECK:STDOUT:   %Self.as_type.loc9_16.1: type = facet_access_type %Self [template = %Self.as_type.loc9_16.1 (constants.%Self.as_type)]
// CHECK:STDOUT:   %.loc9_16.1: Core.Form = init_form %Self.as_type.loc9_16.1 [template = %.loc9_16.1 (constants.%.9e4)]
// CHECK:STDOUT:   %pattern_type: type = pattern_type %Self.as_type.loc9_16.1 [template = %pattern_type (constants.%pattern_type.9c6)]
// CHECK:STDOUT:   %return.param_patt.loc9_16.2: @HasGet.WithSelf.Make.%pattern_type (%pattern_type.9c6) = out_param_pattern [template = %return.param_patt.loc9_16.2 (constants.%return.param_patt.d28)]
// CHECK:STDOUT:   %return.patt.loc9_13.2: @HasGet.WithSelf.Make.%pattern_type (%pattern_type.9c6) = return_slot_pattern %return.param_patt.loc9_16.2, %Self.as_type.loc9_16.1 [template = %return.patt.loc9_13.2 (constants.%return.patt.c85)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn() -> out %return.param: @HasGet.WithSelf.Make.%Self.as_type.loc9_16.1 (%Self.as_type);
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @HasGet.WithSelf(constants.%Self) {}
// CHECK:STDOUT:
// CHECK:STDOUT: specific @HasGet.WithSelf.Get(constants.%Self) {
// CHECK:STDOUT:   %Self => constants.%Self
// CHECK:STDOUT:   %Self.as_type.loc8_10.1 => constants.%Self.as_type
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.9c6
// CHECK:STDOUT:   %self.param_patt.loc8_10.2 => constants.%self.param_patt
// CHECK:STDOUT:   %self.patt.loc8_10.2 => constants.%self.patt
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @HasGet.WithSelf.Make(constants.%Self) {
// CHECK:STDOUT:   %Self => constants.%Self
// CHECK:STDOUT:   %Self.as_type.loc9_16.1 => constants.%Self.as_type
// CHECK:STDOUT:   %.loc9_16.1 => constants.%.9e4
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.9c6
// CHECK:STDOUT:   %return.param_patt.loc9_16.2 => constants.%return.param_patt.d28
// CHECK:STDOUT:   %return.patt.loc9_13.2 => constants.%return.patt.c85
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- forward.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %F.type: type = facet_type <@F> [concrete]
// CHECK:STDOUT:   %Self: %F.type = symbolic_binding Self, 0, template [template]
// CHECK:STDOUT:   %Self.as_type: type = facet_access_type %Self [template]
// CHECK:STDOUT:   %pattern_type: type = pattern_type %Self.as_type [template]
// CHECK:STDOUT:   %self.param_patt: %pattern_type = ref_param_pattern [template]
// CHECK:STDOUT:   %self.patt: %pattern_type = wrapper_binding_pattern self, %self.param_patt [template]
// CHECK:STDOUT:   %F.WithSelf.G.type: type = fn_type @F.WithSelf.G, @F.WithSelf(%Self) [template]
// CHECK:STDOUT:   %F.WithSelf.G: %F.WithSelf.G.type = struct_value () [template]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   package: <namespace> = namespace [concrete] {
// CHECK:STDOUT:     .Core = imports.%Core
// CHECK:STDOUT:     .F = %F.decl.loc5
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.import = import Core
// CHECK:STDOUT:   %F.decl.loc5: type = constraint_decl @F [concrete = constants.%F.type] {} {}
// CHECK:STDOUT:   %F.decl.loc7: type = constraint_decl @F [concrete = constants.%F.type] {} {}
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: constraint @F {
// CHECK:STDOUT:   %Self: %F.type = symbolic_binding Self, 0, template [template = constants.%Self]
// CHECK:STDOUT:   %F.WithSelf.decl = constraint_with_self_decl @F [concrete]
// CHECK:STDOUT:
// CHECK:STDOUT: !with Self:
// CHECK:STDOUT:   %F.WithSelf.G.decl: @F.WithSelf.%F.WithSelf.G.type (%F.WithSelf.G.type) = fn_decl @F.WithSelf.G [template = @F.WithSelf.%F.WithSelf.G (constants.%F.WithSelf.G)] {
// CHECK:STDOUT:     %self.param_patt.loc8_12.1: @F.WithSelf.G.%pattern_type (%pattern_type) = ref_param_pattern [template = %self.param_patt.loc8_12.2 (constants.%self.param_patt)]
// CHECK:STDOUT:     %self.patt.loc8_12.1: @F.WithSelf.G.%pattern_type (%pattern_type) = wrapper_binding_pattern self, %self.param_patt.loc8_12.1 [template = %self.patt.loc8_12.2 (constants.%self.patt)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref @F.WithSelf.G.%Self.as_type.loc8_12.1 (%Self.as_type) = ref_param call_param0
// CHECK:STDOUT:     %.loc8_12.1: type = splice_block %.loc8_12.2 [template = %Self.as_type.loc8_12.1 (constants.%Self.as_type)] {
// CHECK:STDOUT:       %Self.ref: %F.type = name_ref Self, @F.%Self [template = %Self (constants.%Self)]
// CHECK:STDOUT:       %Self.as_type.loc8_12.2: type = facet_access_type %Self.ref [template = %Self.as_type.loc8_12.1 (constants.%Self.as_type)]
// CHECK:STDOUT:       %.loc8_12.2: type = converted %Self.ref, %Self.as_type.loc8_12.2 [template = %Self.as_type.loc8_12.1 (constants.%Self.as_type)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %self: ref @F.WithSelf.G.%Self.as_type.loc8_12.1 (%Self.as_type) = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:
// CHECK:STDOUT: !members:
// CHECK:STDOUT:   .Self = %Self
// CHECK:STDOUT:   .G = @F.WithSelf.%F.WithSelf.G.decl
// CHECK:STDOUT:
// CHECK:STDOUT: !requires:
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @F.WithSelf.G(@F.%Self: %F.type) {
// CHECK:STDOUT:   %Self: %F.type = symbolic_binding Self, 0, template [template = %Self (constants.%Self)]
// CHECK:STDOUT:   %Self.as_type.loc8_12.1: type = facet_access_type %Self [template = %Self.as_type.loc8_12.1 (constants.%Self.as_type)]
// CHECK:STDOUT:   %pattern_type: type = pattern_type %Self.as_type.loc8_12.1 [template = %pattern_type (constants.%pattern_type)]
// CHECK:STDOUT:   %self.param_patt.loc8_12.2: @F.WithSelf.G.%pattern_type (%pattern_type) = ref_param_pattern [template = %self.param_patt.loc8_12.2 (constants.%self.param_patt)]
// CHECK:STDOUT:   %self.patt.loc8_12.2: @F.WithSelf.G.%pattern_type (%pattern_type) = wrapper_binding_pattern self, %self.param_patt.loc8_12.2 [template = %self.patt.loc8_12.2 (constants.%self.patt)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%self.param: ref @F.WithSelf.G.%Self.as_type.loc8_12.1 (%Self.as_type));
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @F.WithSelf(constants.%Self) {}
// CHECK:STDOUT:
// CHECK:STDOUT: specific @F.WithSelf.G(constants.%Self) {
// CHECK:STDOUT:   %Self => constants.%Self
// CHECK:STDOUT:   %Self.as_type.loc8_12.1 => constants.%Self.as_type
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type
// CHECK:STDOUT:   %self.param_patt.loc8_12.2 => constants.%self.param_patt
// CHECK:STDOUT:   %self.patt.loc8_12.2 => constants.%self.patt
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- compose.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %Both.type: type = facet_type <@Both> [concrete]
// CHECK:STDOUT:   %Self.d87: %Both.type = symbolic_binding Self, 0, template [template]
// CHECK:STDOUT:   %Self.as_type.138: type = facet_access_type %Self.d87 [template]
// CHECK:STDOUT:   %pattern_type.9c6: type = pattern_type %Self.as_type.138 [template]
// CHECK:STDOUT:   %self.param_patt.491: %pattern_type.9c6 = value_param_pattern [template]
// CHECK:STDOUT:   %self.patt.118: %pattern_type.9c6 = wrapper_binding_pattern self, %self.param_patt.491 [template]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %Int.type: type = generic_class_type @Int [concrete]
// CHECK:STDOUT:   %Int.generic: %Int.type = struct_value () [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %.795: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete]
// CHECK:STDOUT:   %Both.WithSelf.Get.type: type = fn_type @Both.WithSelf.Get, @Both.WithSelf(%Self.d87) [template]
// CHECK:STDOUT:   %Both.WithSelf.Get: %Both.WithSelf.Get.type = struct_value () [template]
// CHECK:STDOUT:   %Destroy.type: type = facet_type <@Destroy> [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .Int = %Core.Int
// CHECK:STDOUT:     .Destroy = %Core.Destroy
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Int: %Int.type = import_ref Core//prelude/types/int, Int, loaded [concrete = constants.%Int.generic]
// CHECK:STDOUT:   %Core.Destroy: type = import_ref Core//prelude/destroy, Destroy, loaded [concrete = constants.%Destroy.type]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   package: <namespace> = namespace [concrete] {
// CHECK:STDOUT:     .Core = imports.%Core
// CHECK:STDOUT:     .Both = %Both.decl
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.import = import Core
// CHECK:STDOUT:   %Both.decl: type = constraint_decl @Both [concrete = constants.%Both.type] {} {}
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: constraint @Both {
// CHECK:STDOUT:   %Self: %Both.type = symbolic_binding Self, 0, template [template = constants.%Self.d87]
// CHECK:STDOUT:   %Both.WithSelf.decl = constraint_with_self_decl @Both [concrete]
// CHECK:STDOUT:
// CHECK:STDOUT: !with Self:
// CHECK:STDOUT:   %Both.WithSelf.Get.decl: @Both.WithSelf.%Both.WithSelf.Get.type (%Both.WithSelf.Get.type) = fn_decl @Both.WithSelf.Get [template = @Both.WithSelf.%Both.WithSelf.Get (constants.%Both.WithSelf.Get)] {
// CHECK:STDOUT:     %self.param_patt.loc6_10.1: @Both.WithSelf.Get.%pattern_type (%pattern_type.9c6) = value_param_pattern [template = %self.param_patt.loc6_10.2 (constants.%self.param_patt.491)]
// CHECK:STDOUT:     %self.patt.loc6_10.1: @Both.WithSelf.Get.%pattern_type (%pattern_type.9c6) = wrapper_binding_pattern self, %self.param_patt.loc6_10.1 [template = %self.patt.loc6_10.2 (constants.%self.patt.118)]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc6_19: Core.Form = init_form %i32 [concrete = constants.%.795]
// CHECK:STDOUT:     %self.param: @Both.WithSelf.Get.%Self.as_type.loc6_10.1 (%Self.as_type.138) = value_param call_param0
// CHECK:STDOUT:     %.loc6_10.1: type = splice_block %.loc6_10.2 [template = %Self.as_type.loc6_10.1 (constants.%Self.as_type.138)] {
// CHECK:STDOUT:       %Self.ref: %Both.type = name_ref Self, @Both.%Self [template = %Self (constants.%Self.d87)]
// CHECK:STDOUT:       %Self.as_type.loc6_10.2: type = facet_access_type %Self.ref [template = %Self.as_type.loc6_10.1 (constants.%Self.as_type.138)]
// CHECK:STDOUT:       %.loc6_10.2: type = converted %Self.ref, %Self.as_type.loc6_10.2 [template = %Self.as_type.loc6_10.1 (constants.%Self.as_type.138)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %self: @Both.WithSelf.Get.%Self.as_type.loc6_10.1 (%Self.as_type.138) = wrapper_binding self, %self.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Both.WithSelf.Self.as_type.impls.Destroy.type.require.decl = require_decl @Both.WithSelf.Self.as_type.impls.Destroy.type.require [concrete] {
// CHECK:STDOUT:     require %Self.as_type.loc7_11.1 impls %Destroy.ref
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %Self.as_type.loc7_11.1: type = facet_access_type @Both.%Self [template = %Self.as_type.loc7_11.2 (constants.%Self.as_type.138)]
// CHECK:STDOUT:     %Core.ref: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:     %Destroy.ref: type = name_ref Destroy, imports.%Core.Destroy [concrete = constants.%Destroy.type]
// CHECK:STDOUT:   }
// CHECK:STDOUT:
// CHECK:STDOUT: !members:
// CHECK:STDOUT:   .Self = %Self
// CHECK:STDOUT:   .Get = @Both.WithSelf.%Both.WithSelf.Get.decl
// CHECK:STDOUT:
// CHECK:STDOUT: !requires:
// CHECK:STDOUT:   @Both.WithSelf.Self.as_type.impls.Destroy.type.require {
// CHECK:STDOUT:     require @Both.WithSelf.Self.as_type.impls.Destroy.type.require.%Self.as_type.loc7_11.1 impls @Both.WithSelf.Self.as_type.impls.Destroy.type.require.%Destroy.ref
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic require @Both.WithSelf.Self.as_type.impls.Destroy.type.require(@Both.%Self: %Both.type) {
// CHECK:STDOUT:   %Self: %Both.type = symbolic_binding Self, 0, template [template = %Self (constants.%Self.d87)]
// CHECK:STDOUT:   %Self.as_type.loc7_11.2: type = facet_access_type %Self [template = %Self.as_type.loc7_11.2 (constants.%Self.as_type.138)]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @Both.WithSelf.Get(@Both.%Self: %Both.type) {
// CHECK:STDOUT:   %Self: %Both.type = symbolic_binding Self, 0, template [template = %Self (constants.%Self.d87)]
// CHECK:STDOUT:   %Self.as_type.loc6_10.1: type = facet_access_type %Self [template = %Self.as_type.loc6_10.1 (constants.%Self.as_type.138)]
// CHECK:STDOUT:   %pattern_type: type = pattern_type %Self.as_type.loc6_10.1 [template = %pattern_type (constants.%pattern_type.9c6)]
// CHECK:STDOUT:   %self.param_patt.loc6_10.2: @Both.WithSelf.Get.%pattern_type (%pattern_type.9c6) = value_param_pattern [template = %self.param_patt.loc6_10.2 (constants.%self.param_patt.491)]
// CHECK:STDOUT:   %self.patt.loc6_10.2: @Both.WithSelf.Get.%pattern_type (%pattern_type.9c6) = wrapper_binding_pattern self, %self.param_patt.loc6_10.2 [template = %self.patt.loc6_10.2 (constants.%self.patt.118)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%self.param: @Both.WithSelf.Get.%Self.as_type.loc6_10.1 (%Self.as_type.138)) -> out %return.param: %i32;
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Both.WithSelf(constants.%Self.d87) {}
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Both.WithSelf.Get(constants.%Self.d87) {
// CHECK:STDOUT:   %Self => constants.%Self.d87
// CHECK:STDOUT:   %Self.as_type.loc6_10.1 => constants.%Self.as_type.138
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.9c6
// CHECK:STDOUT:   %self.param_patt.loc6_10.2 => constants.%self.param_patt.491
// CHECK:STDOUT:   %self.patt.loc6_10.2 => constants.%self.patt.118
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Both.WithSelf.Self.as_type.impls.Destroy.type.require(constants.%Self.d87) {
// CHECK:STDOUT:   %Self => constants.%Self.d87
// CHECK:STDOUT:   %Self.as_type.loc7_11.2 => constants.%Self.as_type.138
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- generic.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %.Self.frozen: type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %pattern_type.9a5: type = pattern_type type [concrete]
// CHECK:STDOUT:   %T.patt: %pattern_type.9a5 = symbolic_binding_pattern T, 0 [symbolic]
// CHECK:STDOUT:   %T: type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %Has.type.9ba: type = generic_named_constaint_type @Has [concrete]
// CHECK:STDOUT:   %empty_struct: %Has.type.9ba = struct_value () [concrete]
// CHECK:STDOUT:   %Has.type.d68: type = facet_type <@Has, @Has(%T)> [symbolic]
// CHECK:STDOUT:   %Self: %Has.type.d68 = symbolic_binding Self, 1, template [template]
// CHECK:STDOUT:   %Self.as_type: type = facet_access_type %Self [template]
// CHECK:STDOUT:   %pattern_type.a15: type = pattern_type %Self.as_type [template]
// CHECK:STDOUT:   %self.param_patt: %pattern_type.a15 = value_param_pattern [template]
// CHECK:STDOUT:   %self.patt: %pattern_type.a15 = wrapper_binding_pattern self, %self.param_patt [template]
// CHECK:STDOUT:   %.184: Core.Form = init_form %T [symbolic]
// CHECK:STDOUT:   %pattern_type.51d: type = pattern_type %T [symbolic]
// CHECK:STDOUT:   %return.param_patt: %pattern_type.51d = out_param_pattern [symbolic]
// CHECK:STDOUT:   %return.patt: %pattern_type.51d = return_slot_pattern %return.param_patt, %T [symbolic]
// CHECK:STDOUT:   %Has.WithSelf.Get.type: type = fn_type @Has.WithSelf.Get, @Has.WithSelf(%T, %Self) [template]
// CHECK:STDOUT:   %Has.WithSelf.Get: %Has.WithSelf.Get.type = struct_value () [template]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   package: <namespace> = namespace [concrete] {
// CHECK:STDOUT:     .Core = imports.%Core
// CHECK:STDOUT:     .Has = %Has.decl
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.import = import Core
// CHECK:STDOUT:   %Has.decl: %Has.type.9ba = constraint_decl @Has [concrete = constants.%empty_struct] {
// CHECK:STDOUT:     %T.patt.loc5_26.1: %pattern_type.9a5 = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc5_26.2 (constants.%T.patt)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc5_28.1: type = splice_block %.loc5_28.2 [concrete = type] {
// CHECK:STDOUT:       %.Self.frozen: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %.loc5_28.2: type = type_literal type [concrete = type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc5_26.2: type = symbolic_binding T, 0 [symbolic = %T.loc5_26.1 (constants.%T)]
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic constraint @Has(%T.loc5_26.2: type) {
// CHECK:STDOUT:   %T.patt.loc5_26.2: %pattern_type.9a5 = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc5_26.2 (constants.%T.patt)]
// CHECK:STDOUT:   %T.loc5_26.1: type = symbolic_binding T, 0 [symbolic = %T.loc5_26.1 (constants.%T)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %Has.type: type = facet_type <@Has, @Has(%T.loc5_26.1)> [symbolic = %Has.type (constants.%Has.type.d68)]
// CHECK:STDOUT:   %Self.loc5_34.2: @Has.%Has.type (%Has.type.d68) = symbolic_binding Self, 1, template [template = %Self.loc5_34.2 (constants.%Self)]
// CHECK:STDOUT:
// CHECK:STDOUT:   constraint {
// CHECK:STDOUT:     %Self.loc5_34.1: @Has.%Has.type (%Has.type.d68) = symbolic_binding Self, 1, template [template = %Self.loc5_34.2 (constants.%Self)]
// CHECK:STDOUT:     %Has.WithSelf.decl = constraint_with_self_decl @Has [concrete]
// CHECK:STDOUT:
// CHECK:STDOUT:   !with Self:
// CHECK:STDOUT:     %Has.WithSelf.Get.decl: @Has.WithSelf.%Has.WithSelf.Get.type (%Has.WithSelf.Get.type) = fn_decl @Has.WithSelf.Get [template = @Has.WithSelf.%Has.WithSelf.Get (constants.%Has.WithSelf.Get)] {
// CHECK:STDOUT:       %self.param_patt.loc6_10.1: @Has.WithSelf.Get.%pattern_type.loc6_10 (%pattern_type.a15) = value_param_pattern [template = %self.param_patt.loc6_10.2 (constants.%self.param_patt)]
// CHECK:STDOUT:       %self.patt.loc6_10.1: @Has.WithSelf.Get.%pattern_type.loc6_10 (%pattern_type.a15) = wrapper_binding_pattern self, %self.param_patt.loc6_10.1 [template = %self.patt.loc6_10.2 (constants.%self.patt)]
// CHECK:STDOUT:       %return.param_patt.loc6_19.1: @Has.WithSelf.Get.%pattern_type.loc6_19 (%pattern_type.51d) = out_param_pattern [symbolic = %return.param_patt.loc6_19.2 (constants.%return.param_patt)]
// CHECK:STDOUT:       %return.patt.loc6_16.1: @Has.WithSelf.Get.%pattern_type.loc6_19 (%pattern_type.51d) = return_slot_pattern %return.param_patt.loc6_19.1, %T.ref [symbolic = %return.patt.loc6_16.2 (constants.%return.patt)]
// CHECK:STDOUT:     } {
// CHECK:STDOUT:       %T.ref: type = name_ref T, @Has.%T.loc5_26.2 [symbolic = %T (constants.%T)]
// CHECK:STDOUT:       %.loc6_19.2: Core.Form = init_form %T.ref [symbolic = %.loc6_19.1 (constants.%.184)]
// CHECK:STDOUT:       %self.param: @Has.WithSelf.Get.%Self.as_type.loc6_10.1 (%Self.as_type) = value_param call_param0
// CHECK:STDOUT:       %.loc6_10.1: type = splice_block %.loc6_10.3 [template = %Self.as_type.loc6_10.1 (constants.%Self.as_type)] {
// CHECK:STDOUT:         %.loc6_10.2: @Has.WithSelf.Get.%Has.type (%Has.type.d68) = specific_constant @Has.%Self.loc5_34.1, @Has(constants.%T) [template = %Self (constants.%Self)]
// CHECK:STDOUT:         %Self.ref: @Has.WithSelf.Get.%Has.type (%Has.type.d68) = name_ref Self, %.loc6_10.2 [template = %Self (constants.%Self)]
// CHECK:STDOUT:         %Self.as_type.loc6_10.2: type = facet_access_type %Self.ref [template = %Self.as_type.loc6_10.1 (constants.%Self.as_type)]
// CHECK:STDOUT:         %.loc6_10.3: type = converted %Self.ref, %Self.as_type.loc6_10.2 [template = %Self.as_type.loc6_10.1 (constants.%Self.as_type)]
// CHECK:STDOUT:       }
// CHECK:STDOUT:       %self: @Has.WithSelf.Get.%Self.as_type.loc6_10.1 (%Self.as_type) = wrapper_binding self, %self.param
// CHECK:STDOUT:       %return.param: ref @Has.WithSelf.Get.%T (%T) = out_param call_param1
// CHECK:STDOUT:       %return: ref @Has.WithSelf.Get.%T (%T) = return_slot %return.param
// CHECK:STDOUT:     }
// CHECK:STDOUT:
// CHECK:STDOUT:   !members:
// CHECK:STDOUT:     .Self = %Self.loc5_34.1
// CHECK:STDOUT:     .T = <poisoned>
// CHECK:STDOUT:     .T = <poisoned>
// CHECK:STDOUT:     .Get = @Has.WithSelf.%Has.WithSelf.Get.decl
// CHECK:STDOUT:
// CHECK:STDOUT:   !requires:
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @Has.WithSelf.Get(@Has.%T.loc5_26.2: type, @Has.%Self.loc5_34.1: @Has.%Has.type (%Has.type.d68)) {
// CHECK:STDOUT:   %T: type = symbolic_binding T, 0 [symbolic = %T (constants.%T)]
// CHECK:STDOUT:   %Has.type: type = facet_type <@Has, @Has(%T)> [symbolic = %Has.type (constants.%Has.type.d68)]
// CHECK:STDOUT:   %Self: @Has.WithSelf.Get.%Has.type (%Has.type.d68) = symbolic_binding Self, 1, template [template = %Self (constants.%Self)]
// CHECK:STDOUT:   %Self.as_type.loc6_10.1: type = facet_access_type %Self [template = %Self.as_type.loc6_10.1 (constants.%Self.as_type)]
// CHECK:STDOUT:   %pattern_type.loc6_10: type = pattern_type %Self.as_type.loc6_10.1 [template = %pattern_type.loc6_10 (constants.%pattern_type.a15)]
// CHECK:STDOUT:   %self.param_patt.loc6_10.2: @Has.WithSelf.Get.%pattern_type.loc6_10 (%pattern_type.a15) = value_param_pattern [template = %self.param_patt.loc6_10.2 (constants.%self.param_patt)]
// CHECK:STDOUT:   %self.patt.loc6_10.2: @Has.WithSelf.Get.%pattern_type.loc6_10 (%pattern_type.a15) = wrapper_binding_pattern self, %self.param_patt.loc6_10.2 [template = %self.patt.loc6_10.2 (constants.%self.patt)]
// CHECK:STDOUT:   %.loc6_19.1: Core.Form = init_form %T [symbolic = %.loc6_19.1 (constants.%.184)]
// CHECK:STDOUT:   %pattern_type.loc6_19: type = pattern_type %T [symbolic = %pattern_type.loc6_19 (constants.%pattern_type.51d)]
// CHECK:STDOUT:   %return.param_patt.loc6_19.2: @Has.WithSelf.Get.%pattern_type.loc6_19 (%pattern_type.51d) = out_param_pattern [symbolic = %return.param_patt.loc6_19.2 (constants.%return.param_patt)]
// CHECK:STDOUT:   %return.patt.loc6_16.2: @Has.WithSelf.Get.%pattern_type.loc6_19 (%pattern_type.51d) = return_slot_pattern %return.param_patt.loc6_19.2, %T [symbolic = %return.patt.loc6_16.2 (constants.%return.patt)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%self.param: @Has.WithSelf.Get.%Self.as_type.loc6_10.1 (%Self.as_type)) -> out %return.param: @Has.WithSelf.Get.%T (%T);
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Has(constants.%T) {
// CHECK:STDOUT:   %T.patt.loc5_26.2 => constants.%T.patt
// CHECK:STDOUT:   %T.loc5_26.1 => constants.%T
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Has.WithSelf(constants.%T, constants.%Self) {}
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Has.WithSelf.Get(constants.%T, constants.%Self) {
// CHECK:STDOUT:   %T => constants.%T
// CHECK:STDOUT:   %Has.type => constants.%Has.type.d68
// CHECK:STDOUT:   %Self => constants.%Self
// CHECK:STDOUT:   %Self.as_type.loc6_10.1 => constants.%Self.as_type
// CHECK:STDOUT:   %pattern_type.loc6_10 => constants.%pattern_type.a15
// CHECK:STDOUT:   %self.param_patt.loc6_10.2 => constants.%self.param_patt
// CHECK:STDOUT:   %self.patt.loc6_10.2 => constants.%self.patt
// CHECK:STDOUT:   %.loc6_19.1 => constants.%.184
// CHECK:STDOUT:   %pattern_type.loc6_19 => constants.%pattern_type.51d
// CHECK:STDOUT:   %return.param_patt.loc6_19.2 => constants.%return.param_patt
// CHECK:STDOUT:   %return.patt.loc6_16.2 => constants.%return.patt
// CHECK:STDOUT: }
// CHECK:STDOUT:
