// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/int.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/class/export/fail_todo_trivially_copyable.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/class/export/fail_todo_trivially_copyable.carbon

// The F8a red baseline for defect TA-D2 (fork/f008/plan.md §2.1): a mock of
// libc++'s `std::atomic` triviality gate (stdlib mock-header convention,
// stdlib/string_view.carbon), instantiated on an all-scalar Carbon class
// with no user Destroy. Lazy completion of the exported class
// (`CarbonExternalASTSource::CompleteType`, check/cpp/generate_ast.cpp)
// unconditionally adds a destructor with a thunk-calling body (the
// "Import any special member functions that affect class properties" TODO),
// so `__is_trivially_copyable(Carbon::Vec2)` is false and the static_assert
// fires — the mock of the libc++ failure measured in
// fork/design-sprint/threading-atomics.md:102. This golden's flip (the
// static_assert instantiation succeeding on the qualifying class) is the
// F8b discharge test; F8b also adds the non-trivial-class negative probe
// (plan §5 R-2/R-3).

// --- atomic.h

template <typename T> struct atomic {
  static_assert(__is_trivially_copyable(T),
                "atomic requires a trivially copyable type");
  T v;
};

// --- fail_todo_atomic_of_carbon_class.carbon

library "[[@TEST_NAME]]";

import Cpp library "atomic.h";

// All-scalar fields, no user Destroy: trivially copyable on the Carbon
// side, but the exported CXXRecordDecl still gets a destructor today.
class Vec2 {
  var x: i32;
  var y: i32;
}

fn F() {
  // CHECK:STDERR: fail_todo_atomic_of_carbon_class.carbon:[[@LINE+7]]:17: error: static assertion failed due to requirement '__is_trivially_copyable(Carbon::Vec2)': atomic requires a trivially copyable type [CppInteropParseError]
  // CHECK:STDERR:     4 |   static_assert(__is_trivially_copyable(T),
  // CHECK:STDERR:       |   ^             ~~~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR: fail_todo_atomic_of_carbon_class.carbon:[[@LINE+4]]:17: note: in instantiation of template class 'atomic<Carbon::Vec2>' requested here [CppInteropParseNote]
  // CHECK:STDERR:   var unused a: Cpp.atomic(Vec2);
  // CHECK:STDERR:                 ^
  // CHECK:STDERR:
  var unused a: Cpp.atomic(Vec2);
}
