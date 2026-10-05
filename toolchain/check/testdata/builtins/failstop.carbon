// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/builtins/failstop.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/builtins/failstop.carbon
// CHECK:STDERR: {{.*}}/prelude/types/cpp/slice.carbon:69:9: error: cannot access member of interface `Destroy` in type `C.(CppContiguousRange.SizeType)` that does not implement that interface [MissingImplInMemberAccess]
// CHECK:STDERR:         self.Size().(ImplicitAs(u64).Convert)().(As(i64).Convert)());
// CHECK:STDERR:         ^~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: {{.*}}/prelude/types/cpp/slice.carbon:68:9: error: cannot access member of interface `Destroy` in type `C.(CppContiguousRange.DataType)` that does not implement that interface [MissingImplInMemberAccess]
// CHECK:STDERR:         self.Data().(CppDataPointer.Raw)(),
// CHECK:STDERR:         ^~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: {{.*}}/prelude/types/cpp/slice.carbon:64:1: error: orphan `impl` found; something in the self-type or constraint must be defined in the same file [ImplIsOrphan]
// CHECK:STDERR: impl forall [C: CppContiguous where .Element impls Copy & Destroy]
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:

// Fork (SL-1, fork/slices/plan.md §4.A): the `fail_stop` builtin. The file is
// named after the builtin without the `fail_` prefix, which file_test reserves
// for diagnosing files.

// --- call.carbon

library "[[@TEST_NAME]]";

fn Stop(message: str) = "fail_stop";

//@dump-sem-ir-begin
fn F() {
  Stop("x");
}
//@dump-sem-ir-end

// --- fail_returns_value.carbon

library "[[@TEST_NAME]]";

// Predicted: `InvalidBuiltinSignature` "invalid signature for builtin function
// \"fail_stop\"" — the builtin returns `()`.
// CHECK:STDERR: fail_returns_value.carbon:[[@LINE+4]]:1: error: invalid signature for builtin function "fail_stop" [InvalidBuiltinSignature]
// CHECK:STDERR: fn Bad(message: str) -> i32 = "fail_stop";
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn Bad(message: str) -> i32 = "fail_stop";

// CHECK:STDOUT: --- call.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %str.3d4: type = class_type @String [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %char: type = class_type @Char [concrete]
// CHECK:STDOUT:   %ptr.b46: type = ptr_type %char [concrete]
// CHECK:STDOUT:   %Stop.type: type = fn_type @Stop [concrete]
// CHECK:STDOUT:   %Stop: %Stop.type = struct_value () [concrete]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT:   %str.898: %ptr.b46 = string_literal "x" [concrete]
// CHECK:STDOUT:   %int_1: %i64 = int_value 1 [concrete]
// CHECK:STDOUT:   %String.val: %str.3d4 = struct_value (%str.898, %int_1) [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %F.decl: %F.type = fn_decl @F [concrete = constants.%F] {} {}
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @F() {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Stop.ref: %Stop.type = name_ref Stop, file.%Stop.decl [concrete = constants.%Stop]
// CHECK:STDOUT:   %str: %ptr.b46 = string_literal "x" [concrete = constants.%str.898]
// CHECK:STDOUT:   %int_1: %i64 = int_value 1 [concrete = constants.%int_1]
// CHECK:STDOUT:   %String.val: %str.3d4 = struct_value (%str, %int_1) [concrete = constants.%String.val]
// CHECK:STDOUT:   %Stop.call: init %empty_tuple.type = call %Stop.ref(%String.val)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
