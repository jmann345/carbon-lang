// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --target=x86_64-linux-gnu
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/interop/cpp/clang_code_generator_callbacks.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/interop/cpp/clang_code_generator_callbacks.carbon
// CHECK:STDERR: {{.*}}/prelude/try.carbon:20:1: error: name `Core.ImplicitAs` implicitly referenced here, but not found [CoreNameNotFound]
// CHECK:STDERR: choice ControlFlow(C: type, B: type) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: {{.*}}/prelude/try.carbon:20:1: error: name `Core.ImplicitAs` implicitly referenced here, but not found [CoreNameNotFound]
// CHECK:STDERR: choice ControlFlow(C: type, B: type) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:

library "[[@TEST_NAME]]";

import Cpp inline '''

// Clang uses an implementation of clang::ASTConsumer to implement code
// generation, it has a variety of callbacks that may be called throughout the
// process of parsing/semantically analyzing the source code. Below are test
// cases based on those callbacks to ensure that C++ code compiled as part of
// Carbon interop imports preserve Clang's behavior.

struct t1 {
  virtual void f1();
};
// HandleVTable - Emit a definition for `t1`'s vtable.
void t1::f1() { }

// CompleteExternalDeclaration - Only be related to the BPF target.

// CompleteTentativeDefinition - Only relevant to C code.

// AssignInheritanceModel - Only relevant to ms inheritance attribute

// HandleTagDeclRequiredDefinition - Only relevant to ms debug info (only
// fails clang/test/DebugInfo/CXX/dllimport-base-class.cpp)

// HandleTagDeclDefinition - updating previous IR when a definition for a type
// is provided.
struct S;
extern S a[10];
S(*b)[10] = &a;
struct S {
  int x;
};
int f() { return a[3].x; }
// without the callback, clang describes the type of 'a' as 10xi8, resulting in
// this:
//   load i32, ptr getelementptr inbounds ([10 x i8], ptr @a, i64 0, i64 3), align 4
// with the callback, the type gets updated and the result is:
//   load i32, ptr getelementptr inbounds ([10 x %struct.S], ptr @a, i64 0, i64 3), align 4

// HandleInlineFunctionDefinition+EmitDeferredDecls - Emit a definition of
// `func`.
struct t2 {
  __attribute__((used)) void func() {}
};

// HandleCXXStaticMemberVarInstantiation - Emit a definition for
// `t3<int>::i`.
template<typename T>
struct t3 {
  static int i;
};
template<typename T>
int t3<T>::i;
void f2() {
  t3<int>::i = 42;
}
''';

