// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/none.carbon
// EXTRA-ARGS: --cpp-exceptions=none
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/exceptions/none_mode.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/exceptions/none_mode.carbon

// --- none_mode.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
void may_throw();
''';

// In `none` mode, the same callee that is fenced under `catch` is called
// directly, with no thunk — identical to the pre-fence behavior.
fn F() {
  //@dump-sem-ir-begin
  Cpp.may_throw();
  //@dump-sem-ir-end
}

// CHECK:STDOUT: --- none_mode.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %may_throw.cpp_overload_set.type: type = cpp_overload_set_type @may_throw.cpp_overload_set [concrete]
// CHECK:STDOUT:   %may_throw.cpp_overload_set.value: %may_throw.cpp_overload_set.type = cpp_overload_set_value @may_throw.cpp_overload_set [concrete]
// CHECK:STDOUT:   %may_throw.type: type = fn_type @may_throw [concrete]
// CHECK:STDOUT:   %may_throw: %may_throw.type = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Cpp: <namespace> = namespace file.%Cpp.import_cpp, [concrete] {
// CHECK:STDOUT:     .may_throw = %may_throw.cpp_overload_set.value
// CHECK:STDOUT:     import Cpp//...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %may_throw.cpp_overload_set.value: %may_throw.cpp_overload_set.type = cpp_overload_set_value @may_throw.cpp_overload_set [concrete = constants.%may_throw.cpp_overload_set.value]
// CHECK:STDOUT:   %may_throw.decl: %may_throw.type = fn_decl @may_throw [concrete = constants.%may_throw] {} {}
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @F() {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Cpp.ref: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:   %may_throw.ref: %may_throw.cpp_overload_set.type = name_ref may_throw, imports.%may_throw.cpp_overload_set.value [concrete = constants.%may_throw.cpp_overload_set.value]
// CHECK:STDOUT:   %may_throw.call: init %empty_tuple.type = call imports.%may_throw.decl()
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT: }
// CHECK:STDOUT:
