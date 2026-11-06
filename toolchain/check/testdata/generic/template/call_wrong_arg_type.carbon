// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/convert.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/generic/template/call_wrong_arg_type.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/generic/template/call_wrong_arg_type.carbon

// --- fail_dependent_call_nonconst_arg_wrong_type.carbon
library "[[@TEST_NAME]]";

class X {}
class Y {}
fn F[template G: type](H: G, x: X) {
  H(x);
}
fn TakeY(unused y: Y) {}

// CHECK:STDERR: fail_dependent_call_nonconst_arg_wrong_type.carbon:[[@LINE+13]]:20: error: unable to monomorphize specific `F(<type of TakeY>)` [ResolvingSpecificHere]
// CHECK:STDERR: fn BadCall(x: X) { F(TakeY, x); }
// CHECK:STDERR:                    ^
// CHECK:STDERR: fail_dependent_call_nonconst_arg_wrong_type.carbon:[[@LINE-7]]:5: note: cannot implicitly convert expression of type `X` to `Y` [ConversionFailure]
// CHECK:STDERR:   H(x);
// CHECK:STDERR:     ^
// CHECK:STDERR: fail_dependent_call_nonconst_arg_wrong_type.carbon:[[@LINE-10]]:5: note: type `X` does not implement interface `Core.ImplicitAs(Y)` [MissingImplInMemberAccessInContext]
// CHECK:STDERR:   H(x);
// CHECK:STDERR:     ^
// CHECK:STDERR: fail_dependent_call_nonconst_arg_wrong_type.carbon:[[@LINE-11]]:17: note: initializing function parameter [InCallToFunctionParam]
// CHECK:STDERR: fn TakeY(unused y: Y) {}
// CHECK:STDERR:                 ^~~~
// CHECK:STDERR:
fn BadCall(x: X) { F(TakeY, x); }
