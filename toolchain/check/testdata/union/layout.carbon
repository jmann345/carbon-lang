// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/union/layout.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/union/layout.carbon

// The layout rule (docs/design/unions.md, "Layout"): every field at offset
// 0, alignment the maximum field alignment, size the maximum field size
// rounded up to that alignment.

//@dump-sem-ir-begin
union Wide {
  // CHECK:STDERR: layout.carbon:[[@LINE+4]]:7: error: union field `lo` has type `i32`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var lo: i32;
  // CHECK:STDERR:       ^~~~~~~
  // CHECK:STDERR:
  var lo: i32;
  // CHECK:STDERR: layout.carbon:[[@LINE+4]]:7: error: union field `both` has type `i64`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var both: i64;
  // CHECK:STDERR:       ^~~~~~~~~
  // CHECK:STDERR:
  var both: i64;
}

union Odd {
  // CHECK:STDERR: layout.carbon:[[@LINE+4]]:7: error: union field `a` has type `i8`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var a: i8;
  // CHECK:STDERR:       ^~~~~
  // CHECK:STDERR:
  var a: i8;
  // CHECK:STDERR: layout.carbon:[[@LINE+4]]:7: error: union field `b` has type `i16`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var b: i16;
  // CHECK:STDERR:       ^~~~~~
  // CHECK:STDERR:
  var b: i16;
  // CHECK:STDERR: layout.carbon:[[@LINE+4]]:7: error: union field `c` has type `array(i8, 3)`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var c: array(i8, 3);
  // CHECK:STDERR:       ^~~~~~~~~~~~~~~
  // CHECK:STDERR:
  var c: array(i8, 3);
}

union OneByte {
  var b: bool;
}

union Ptr {
  var p: i32*;
  // CHECK:STDERR: layout.carbon:[[@LINE+4]]:7: error: union field `n` has type `i64`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var n: i64;
  // CHECK:STDERR:       ^~~~~~
  // CHECK:STDERR:
  var n: i64;
}
//@dump-sem-ir-end

// CHECK:STDOUT: --- layout.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %Wide: type = class_type @Wide [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %Wide.elem.9fb: type = unbound_element_type %Wide, %i32 [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %Wide.elem.98e: type = unbound_element_type %Wide, %i64 [concrete]
// CHECK:STDOUT:   %Odd: type = class_type @Odd [concrete]
// CHECK:STDOUT:   %int_8: Core.IntLiteral = int_value 8 [concrete]
// CHECK:STDOUT:   %i8: type = class_type @Int, @Int(%int_8) [concrete]
// CHECK:STDOUT:   %Odd.elem.808: type = unbound_element_type %Odd, %i8 [concrete]
// CHECK:STDOUT:   %int_16: Core.IntLiteral = int_value 16 [concrete]
// CHECK:STDOUT:   %i16: type = class_type @Int, @Int(%int_16) [concrete]
// CHECK:STDOUT:   %Odd.elem.2b6: type = unbound_element_type %Odd, %i16 [concrete]
// CHECK:STDOUT:   %int_3: Core.IntLiteral = int_value 3 [concrete]
// CHECK:STDOUT:   %array_type: type = array_type %int_3, %i8 [concrete]
// CHECK:STDOUT:   %Odd.elem.b4a: type = unbound_element_type %Odd, %array_type [concrete]
// CHECK:STDOUT:   %OneByte: type = class_type @OneByte [concrete]
// CHECK:STDOUT:   %OneByte.elem: type = unbound_element_type %OneByte, bool [concrete]
// CHECK:STDOUT:   %.b2d: type = custom_layout_type {size=1, align=1, .b@0: bool} [concrete]
// CHECK:STDOUT:   %complete_type.17b: <witness> = complete_type_witness %.b2d [concrete]
// CHECK:STDOUT:   %Ptr: type = class_type @Ptr [concrete]
// CHECK:STDOUT:   %ptr.d08: type = ptr_type %i32 [concrete]
// CHECK:STDOUT:   %Ptr.elem.b01: type = unbound_element_type %Ptr, %ptr.d08 [concrete]
// CHECK:STDOUT:   %Ptr.elem.98a: type = unbound_element_type %Ptr, %i64 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Wide.decl: type = class_decl @Wide [concrete = constants.%Wide] {} {}
// CHECK:STDOUT:   %Odd.decl: type = class_decl @Odd [concrete = constants.%Odd] {} {}
// CHECK:STDOUT:   %OneByte.decl: type = class_decl @OneByte [concrete = constants.%OneByte] {} {}
// CHECK:STDOUT:   %Ptr.decl: type = class_decl @Ptr [concrete = constants.%Ptr] {} {}
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: class @Wide {
// CHECK:STDOUT:   %.loc19: %Wide.elem.9fb = field_decl lo, element0 [concrete]
// CHECK:STDOUT:   %.loc20: %Wide.elem.98e = field_decl both, element1 [concrete]
// CHECK:STDOUT:   complete_type_witness = <error>
// CHECK:STDOUT:
// CHECK:STDOUT: !members:
// CHECK:STDOUT:   .Self = constants.%Wide
// CHECK:STDOUT:   .lo = %.loc19
// CHECK:STDOUT:   .both = %.loc20
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: class @Odd {
// CHECK:STDOUT:   %.loc24: %Odd.elem.808 = field_decl a, element0 [concrete]
// CHECK:STDOUT:   %.loc25: %Odd.elem.2b6 = field_decl b, element1 [concrete]
// CHECK:STDOUT:   %.loc26: %Odd.elem.b4a = field_decl c, element2 [concrete]
// CHECK:STDOUT:   complete_type_witness = <error>
// CHECK:STDOUT:
// CHECK:STDOUT: !members:
// CHECK:STDOUT:   .Self = constants.%Odd
// CHECK:STDOUT:   .a = %.loc24
// CHECK:STDOUT:   .b = %.loc25
// CHECK:STDOUT:   .c = %.loc26
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: class @OneByte {
// CHECK:STDOUT:   %.loc30: %OneByte.elem = field_decl b, element0 [concrete]
// CHECK:STDOUT:   %.loc31: type = custom_layout_type {size=1, align=1, .b@0: bool} [concrete = constants.%.b2d]
// CHECK:STDOUT:   %complete_type: <witness> = complete_type_witness %.loc31 [concrete = constants.%complete_type.17b]
// CHECK:STDOUT:   complete_type_witness = %complete_type
// CHECK:STDOUT:
// CHECK:STDOUT: !members:
// CHECK:STDOUT:   .Self = constants.%OneByte
// CHECK:STDOUT:   .b = %.loc30
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: class @Ptr {
// CHECK:STDOUT:   %.loc34: %Ptr.elem.b01 = field_decl p, element0 [concrete]
// CHECK:STDOUT:   %.loc35: %Ptr.elem.98a = field_decl n, element1 [concrete]
// CHECK:STDOUT:   complete_type_witness = <error>
// CHECK:STDOUT:
// CHECK:STDOUT: !members:
// CHECK:STDOUT:   .Self = constants.%Ptr
// CHECK:STDOUT:   .p = %.loc34
// CHECK:STDOUT:   .n = %.loc35
// CHECK:STDOUT: }
// CHECK:STDOUT:
