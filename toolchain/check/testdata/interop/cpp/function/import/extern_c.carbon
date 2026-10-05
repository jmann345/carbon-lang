// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/int.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/function/import/extern_c.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/function/import/extern_c.carbon

// --- extern_c_function.carbon

library "[[@TEST_NAME]]";

import Cpp inline '''
extern "C" void foo_c_fn();
''';

fn MyF() {
  //@dump-sem-ir-begin
  Cpp.foo_c_fn();
  //@dump-sem-ir-end
}

// --- extern_c_function_with_cpp_overload_set.carbon

library "[[@TEST_NAME]]";

import Cpp inline '''
extern "C" void foo_c_overloaded();
void foo_c_overloaded(int x);
''';

fn MyF() {
  //@dump-sem-ir-begin
  Cpp.foo_c_overloaded();
  Cpp.foo_c_overloaded(5);
  //@dump-sem-ir-end
}

// --- extern_c_variable.carbon

library "[[@TEST_NAME]]";

import Cpp inline '''
extern "C" int foo_c_var;
''';

fn MyF() -> i32 {
  //@dump-sem-ir-begin
  return Cpp.foo_c_var;
  //@dump-sem-ir-end
}

// --- extern_c_with_special_name.carbon

library "[[@TEST_NAME]]";

import Cpp inline '''
struct X {};
extern "C" X operator+(X, X);
''';

fn MyF(a: Cpp.X, b: Cpp.X) -> Cpp.X {
  //@dump-sem-ir-begin
  return a + b;
  //@dump-sem-ir-end
}
