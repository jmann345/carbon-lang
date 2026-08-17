// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/int.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/class/export/trivially_copyable.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/class/export/trivially_copyable.carbon

// The F8b POSITIVE pin for defect TA-D2 (fork/f008/plan.md §2.2, §3 F8b),
// flipped from the F8a red baseline fail_todo_trivially_copyable.carbon: a
// mock of libc++'s `std::atomic` triviality gate (stdlib mock-header
// convention, stdlib/string_view.carbon) instantiated on an all-scalar Carbon
// class with no user `Core.Destroy` impl. Lazy completion of the exported
// class (`CarbonExternalASTSource::CompleteType`, check/cpp/generate_ast.cpp)
// now consults `IsTriviallyCopyableForExport` (check/cpp/export.cpp) and
// exports the qualifying class WITHOUT the thunk-calling destructor, so
// Clang's implicitly-declared special members stay trivial and
// `__is_trivially_copyable(Carbon::Vec2)` is genuinely true — the
// static_assert instantiation succeeds. FALSIFIERS (plan §5 R-2): this pin
// passing while a destructor declaration is still attached would be a
// predicate bypass, not triviality — and the real-libc++ differential pair
// fork/conformance/programs/interop/cpp_atomic_carbon_class_diff.carbon is
// the arbiter against mock divergence. The negative probe (a genuinely
// non-trivial class must still fail the gate, plan §5 R-3) is
// fail_atomic_of_nontrivial_carbon_class.carbon.
//
// The adapter_of_scalar split pins the recorded F8b deviation (plan §2.2 is
// silent on `adapt`; the recursion follows `CanDestroyClass`'s identical
// adapted-type dispatch): an adapter of a scalar with no user `Core.Destroy`
// impl exports destructor-free too. The same R-2 falsifier applies to it —
// its static_assert succeeding while a destructor declaration is attached
// would be a predicate bypass, and the R-3 counterpart (an adapter WITH a
// user Destroy impl must keep the thunk) is
// fail_atomic_of_nontrivial_carbon_class.carbon's
// fail_atomic_of_user_destroy_adapter split.

// --- atomic.h

template <typename T> struct atomic {
  static_assert(__is_trivially_copyable(T),
                "atomic requires a trivially copyable type");
  T v;
};

// --- atomic_of_carbon_class.carbon

library "[[@TEST_NAME]]";

import Cpp library "atomic.h";

// All-scalar fields, no user Destroy: trivially copyable on the Carbon side,
// and now exported without a destructor, so trivially copyable in Clang too.
class Vec2 {
  var x: i32;
  var y: i32;
}

fn F() {
  var unused a: Cpp.atomic(Vec2);
}

// --- adapter_of_scalar.carbon

library "[[@TEST_NAME]]";

import Cpp library "atomic.h";

// An adapter of a scalar, no user Destroy: destroy-trivial through the
// adapted i32 (`IsTriviallyDestructible`'s adapted-type recursion —
// `CanDestroyClass`'s identical dispatch), so the export carries no
// destructor and the mock triviality gate accepts it.
class Meters {
  adapt i32;
}

fn G() {
  var unused m: Cpp.atomic(Meters);
}
