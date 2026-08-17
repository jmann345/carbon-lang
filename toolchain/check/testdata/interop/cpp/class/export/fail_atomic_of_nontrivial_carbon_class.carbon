// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/int.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/class/export/fail_atomic_of_nontrivial_carbon_class.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/class/export/fail_atomic_of_nontrivial_carbon_class.carbon

// The F8b NEGATIVE probe for defect TA-D2 (fork/f008/plan.md §3 F8b, §5
// R-3): a genuinely non-trivial Carbon class — it declares a user
// `Core.Destroy` impl — into the same mock `std::atomic` triviality gate as
// the positive pin (trivially_copyable.carbon).
// `IsTriviallyCopyableForExport` (check/cpp/export.cpp) must answer false, so
// the exported class keeps the thunk-calling destructor and
// `__is_trivially_copyable(Carbon::Tracked)` stays false: the static_assert
// still fires, with the same diagnostic chain the F8a red baseline
// (fail_todo_trivially_copyable.carbon) pinned. FALSIFIER (plan §5 R-3):
// this probe FAILING TO FAIL — the static_assert not firing for this class —
// means the predicate over-widened (memory-unsafe atomic operations over a
// class that declares destruction work); a crash replacing the diagnostic is
// equally a defect.

// --- atomic.h

template <typename T> struct atomic {
  static_assert(__is_trivially_copyable(T),
                "atomic requires a trivially copyable type");
  T v;
};

// --- fail_atomic_of_nontrivial_carbon_class.carbon

library "[[@TEST_NAME]]";

import Cpp library "atomic.h";

// A user `Core.Destroy` impl marks intended destruction work: the class
// must NOT qualify as trivially copyable for export.
class Tracked {
  var x: i32;
  impl as Core.Destroy {
    fn Op(unused ref self) {}
  }
}

fn F() {
  // CHECK:STDERR: fail_atomic_of_nontrivial_carbon_class.carbon:[[@LINE+23]]:17: error: binding pattern has incomplete type `Cpp.atomic` in name binding declaration [IncompleteTypeInBindingDecl]
  // CHECK:STDERR:   var unused a: Cpp.atomic(Tracked);
  // CHECK:STDERR:                 ^~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR: fail_atomic_of_nontrivial_carbon_class.carbon:[[@LINE-15]]:10: in file included here [InCppInclude]
  // CHECK:STDERR: ./atomic.h:3:17: note: static assertion failed due to requirement '__is_trivially_copyable(Carbon::Tracked)': atomic requires a trivially copyable type [CppInteropParseError]
  // CHECK:STDERR:     3 |   static_assert(__is_trivially_copyable(T),
  // CHECK:STDERR:       |                 ^~~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR: fail_atomic_of_nontrivial_carbon_class.carbon:[[@LINE-19]]:10: in file included here [InCppInclude]
  // CHECK:STDERR: ./atomic.h:2:30: note: in instantiation of template class 'atomic<Carbon::Tracked>' requested here [CppInteropParseNote]
  // CHECK:STDERR:     2 | template <typename T> struct atomic {
  // CHECK:STDERR:       |                              ^
  // CHECK:STDERR: fail_atomic_of_nontrivial_carbon_class.carbon:[[@LINE-23]]:10: in file included here [InCppInclude]
  // CHECK:STDERR: ./atomic.h:3:17: note: 'Carbon::Tracked' is not trivially copyable [CppInteropParseNote]
  // CHECK:STDERR:     3 |   static_assert(__is_trivially_copyable(T),
  // CHECK:STDERR:       |                 ^
  // CHECK:STDERR: fail_atomic_of_nontrivial_carbon_class.carbon:[[@LINE-27]]:10: in file included here [InCppInclude]
  // CHECK:STDERR: ./atomic.h:3:17: note: because it has a user-provided destructor [CppInteropParseNote]
  // CHECK:STDERR:     3 |   static_assert(__is_trivially_copyable(T),
  // CHECK:STDERR:       |                 ^
  // CHECK:STDERR: fail_atomic_of_nontrivial_carbon_class.carbon:[[@LINE-27]]:15: note: 'Tracked' defined here [CppInteropParseNote]
  // CHECK:STDERR:     8 | class Tracked {
  // CHECK:STDERR:       |               ^
  // CHECK:STDERR:
  var unused a: Cpp.atomic(Tracked);
}
