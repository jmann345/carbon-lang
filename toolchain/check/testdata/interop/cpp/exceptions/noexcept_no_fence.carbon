// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/none.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/exceptions/noexcept_no_fence.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/exceptions/noexcept_no_fence.carbon

// --- noexcept_no_fence.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
void cannot_throw() noexcept;
''';

// A `noexcept` callee needs no fence: the call stays direct, with no thunk,
// even with C++ exceptions enabled.
fn F() {
  //@dump-sem-ir-begin
  Cpp.cannot_throw();
  //@dump-sem-ir-end
}

// CHECK:STDOUT: --- noexcept_no_fence.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %cannot_throw.cpp_overload_set.type: type = cpp_overload_set_type @cannot_throw.cpp_overload_set [concrete]
// CHECK:STDOUT:   %cannot_throw.cpp_overload_set.value: %cannot_throw.cpp_overload_set.type = cpp_overload_set_value @cannot_throw.cpp_overload_set [concrete]
// CHECK:STDOUT:   %cannot_throw.type: type = fn_type @cannot_throw [concrete]
// CHECK:STDOUT:   %cannot_throw: %cannot_throw.type = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Cpp: <namespace> = namespace file.%Cpp.import_cpp, [concrete] {
// CHECK:STDOUT:     .cannot_throw = %cannot_throw.cpp_overload_set.value
// CHECK:STDOUT:     import Cpp//...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %cannot_throw.cpp_overload_set.value: %cannot_throw.cpp_overload_set.type = cpp_overload_set_value @cannot_throw.cpp_overload_set [concrete = constants.%cannot_throw.cpp_overload_set.value]
// CHECK:STDOUT:   %cannot_throw.decl: %cannot_throw.type = fn_decl @cannot_throw [concrete = constants.%cannot_throw] {} {}
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @F() {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Cpp.ref: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:   %cannot_throw.ref: %cannot_throw.cpp_overload_set.type = name_ref cannot_throw, imports.%cannot_throw.cpp_overload_set.value [concrete = constants.%cannot_throw.cpp_overload_set.value]
// CHECK:STDOUT:   %cannot_throw.call: init %empty_tuple.type = call imports.%cannot_throw.decl()
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT: }
// CHECK:STDOUT:
