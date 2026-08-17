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
// R-3): genuinely non-trivial Carbon classes — each declares a user
// `Core.Destroy` impl — into the same mock `std::atomic` triviality gate as
// the positive pin (trivially_copyable.carbon).
// `IsTriviallyCopyableForExport` (check/cpp/export.cpp) must answer false, so
// the exported class keeps the thunk-calling destructor and
// `__is_trivially_copyable(...)` stays false: the static_assert still fires,
// with the same diagnostic chain the F8a red baseline
// (fail_todo_trivially_copyable.carbon) pinned. FALSIFIER (plan §5 R-3):
// any probe here FAILING TO FAIL — the static_assert not firing — means the
// predicate over-widened (memory-unsafe atomic operations over a class that
// declares destruction work); a crash replacing the diagnostic is equally a
// defect. Three arms:
//   - fail_atomic_of_nontrivial_carbon_class: inline user Destroy impl in a
//     plain fields class;
//   - fail_atomic_of_user_destroy_adapter: out-of-line user Destroy impl on
//     an adapter of a scalar (the R-3 counterpart of the positive
//     adapter_of_scalar split);
//   - destroy_lib + fail_atomic_of_imported_user_destroy: the user Destroy
//     impl lives in the class's DEFINING library, not the importing file —
//     the F1 falsifier for `HasUserDestroyImpl`'s imported-IR scan
//     (check/custom_witness.cpp): a local-store-only scan would answer
//     "trivial" here and diverge the exported record across TUs.
// Every user `Destroy.Op` writes a package-scope var (plan-review strictness
// F5 rot-guard): a future "empty destructor body = trivial" cleverness
// cannot silently widen the predicate past these probes.
// Hand pins for the two NEW arms are best-effort shapes derived from the
// reconciled first arm; the runner's red-first autoupdate reconciliation is
// the arbiter (R15/R19), notably for the cross-file defined-here note
// placement in the imported arm.

// --- atomic.h

template <typename T> struct atomic {
  static_assert(__is_trivially_copyable(T),
                "atomic requires a trivially copyable type");
  T v;
};

// --- fail_atomic_of_nontrivial_carbon_class.carbon

library "[[@TEST_NAME]]";

import Cpp library "atomic.h";

// User Destroy impl = declared destruction work; F5 rot-guard var (header).
var destroy_count: i32 = 0;
class Tracked {
  var x: i32;
  impl as Core.Destroy {
    fn Op(unused ref self) { destroy_count = 1; }
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

// --- fail_atomic_of_user_destroy_adapter.carbon

library "[[@TEST_NAME]]";

import Cpp library "atomic.h";

// The R-3 adapter arm: adapting a scalar does not excuse declared
// destruction work — the out-of-line user `Core.Destroy` impl keeps the
// adapter out of the trivially-destructible set even though the adapted
// i32 is trivial (counterpart of trivially_copyable.carbon's positive
// adapter_of_scalar split). Same F5 rot-guard: the op writes a
// package-scope var.
var adapter_destroy_count: i32 = 0;
class Guarded {
  adapt i32;
}

impl Guarded as Core.Destroy {
  fn Op(unused ref self) { adapter_destroy_count = 1; }
}

fn G() {
  // CHECK:STDERR: fail_atomic_of_user_destroy_adapter.carbon:[[@LINE+23]]:17: error: binding pattern has incomplete type `Cpp.atomic` in name binding declaration [IncompleteTypeInBindingDecl]
  // CHECK:STDERR:   var unused g: Cpp.atomic(Guarded);
  // CHECK:STDERR:                 ^~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR: fail_atomic_of_user_destroy_adapter.carbon:[[@LINE-21]]:10: in file included here [InCppInclude]
  // CHECK:STDERR: ./atomic.h:3:17: note: static assertion failed due to requirement '__is_trivially_copyable(Carbon::Guarded)': atomic requires a trivially copyable type [CppInteropParseError]
  // CHECK:STDERR:     3 |   static_assert(__is_trivially_copyable(T),
  // CHECK:STDERR:       |                 ^~~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR: fail_atomic_of_user_destroy_adapter.carbon:[[@LINE-25]]:10: in file included here [InCppInclude]
  // CHECK:STDERR: ./atomic.h:2:30: note: in instantiation of template class 'atomic<Carbon::Guarded>' requested here [CppInteropParseNote]
  // CHECK:STDERR:     2 | template <typename T> struct atomic {
  // CHECK:STDERR:       |                              ^
  // CHECK:STDERR: fail_atomic_of_user_destroy_adapter.carbon:[[@LINE-29]]:10: in file included here [InCppInclude]
  // CHECK:STDERR: ./atomic.h:3:17: note: 'Carbon::Guarded' is not trivially copyable [CppInteropParseNote]
  // CHECK:STDERR:     3 |   static_assert(__is_trivially_copyable(T),
  // CHECK:STDERR:       |                 ^
  // CHECK:STDERR: fail_atomic_of_user_destroy_adapter.carbon:[[@LINE-33]]:10: in file included here [InCppInclude]
  // CHECK:STDERR: ./atomic.h:3:17: note: because it has a user-provided destructor [CppInteropParseNote]
  // CHECK:STDERR:     3 |   static_assert(__is_trivially_copyable(T),
  // CHECK:STDERR:       |                 ^
  // CHECK:STDERR: fail_atomic_of_user_destroy_adapter.carbon:[[@LINE-28]]:15: note: 'Guarded' defined here [CppInteropParseNote]
  // CHECK:STDERR:    13 | class Guarded {
  // CHECK:STDERR:       |               ^
  // CHECK:STDERR:
  var unused g: Cpp.atomic(Guarded);
}

// --- destroy_lib.carbon

library "[[@TEST_NAME]]";

// The defining library of the imported-impl arm's class: the user
// `Core.Destroy` impl lives HERE, in the class's defining IR. Same F5
// rot-guard: the op writes a package-scope var.
var lib_destroy_count: i32 = 0;
class Remote {
  var x: i32;
  impl as Core.Destroy {
    fn Op(unused ref self) { lib_destroy_count = 1; }
  }
}

// --- fail_atomic_of_imported_user_destroy.carbon

library "[[@TEST_NAME]]";

import library "destroy_lib";
import Cpp library "atomic.h";

// The F1 falsifier (fork/f008/plan.md §2.2; check/custom_witness.cpp
// `HasUserDestroyImpl`): this file declares NO `Core.Destroy` impl — the
// impl is in `Remote`'s defining library only, so it is found by scanning
// the imported IR's impl store, never the local store. The class must STILL
// keep the thunk destructor here, or the exported record's triviality would
// diverge between the defining and importing TUs. Pins are best-effort: the
// defined-here note points into destroy_lib.carbon, and the autoupdate
// reconciliation owns its exact placement and rendering.
fn H() {
  // CHECK:STDERR: fail_atomic_of_imported_user_destroy.carbon:[[@LINE+23]]:17: error: binding pattern has incomplete type `Cpp.atomic` in name binding declaration [IncompleteTypeInBindingDecl]
  // CHECK:STDERR:   var unused r: Cpp.atomic(Remote);
  // CHECK:STDERR:                 ^~~~~~~~~~~~~~~~~~
  // CHECK:STDERR: fail_atomic_of_imported_user_destroy.carbon:[[@LINE-14]]:10: in file included here [InCppInclude]
  // CHECK:STDERR: ./atomic.h:3:17: note: static assertion failed due to requirement '__is_trivially_copyable(Carbon::Remote)': atomic requires a trivially copyable type [CppInteropParseError]
  // CHECK:STDERR:     3 |   static_assert(__is_trivially_copyable(T),
  // CHECK:STDERR:       |                 ^~~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR: fail_atomic_of_imported_user_destroy.carbon:[[@LINE-18]]:10: in file included here [InCppInclude]
  // CHECK:STDERR: ./atomic.h:2:30: note: in instantiation of template class 'atomic<Carbon::Remote>' requested here [CppInteropParseNote]
  // CHECK:STDERR:     2 | template <typename T> struct atomic {
  // CHECK:STDERR:       |                              ^
  // CHECK:STDERR: fail_atomic_of_imported_user_destroy.carbon:[[@LINE-22]]:10: in file included here [InCppInclude]
  // CHECK:STDERR: ./atomic.h:3:17: note: 'Carbon::Remote' is not trivially copyable [CppInteropParseNote]
  // CHECK:STDERR:     3 |   static_assert(__is_trivially_copyable(T),
  // CHECK:STDERR:       |                 ^
  // CHECK:STDERR: fail_atomic_of_imported_user_destroy.carbon:[[@LINE-26]]:10: in file included here [InCppInclude]
  // CHECK:STDERR: ./atomic.h:3:17: note: because it has a user-provided destructor [CppInteropParseNote]
  // CHECK:STDERR:     3 |   static_assert(__is_trivially_copyable(T),
  // CHECK:STDERR:       |                 ^
  // CHECK:STDERR: destroy_lib.carbon:8:14: note: 'Remote' defined here [CppInteropParseNote]
  // CHECK:STDERR:     8 | class Remote {
  // CHECK:STDERR:       |              ^
  // CHECK:STDERR:
  var unused r: Cpp.atomic(Remote);
}
