// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/interop/cpp/exceptions/catching_thunk.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/interop/cpp/exceptions/catching_thunk.carbon
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

// The catching thunk, lowered (docs/design/error_handling.md, "Catching
// imports"; fork/eh/plan.md §4.B): inside the still-`noexcept` thunk the
// callee is `invoke`d with a `landingpad ... catch ptr null` handler that
// stores `__cxa_current_primary_exception()` through the error out-pointer and
// returns the discriminant 1, while the success path stores the return value
// through the return out-pointer and returns 0; the Carbon caller compares
// the discriminant with 0 (`icmp`/`br`) and constructs the `Ok` or `Err`
// alternative of `Core.Result(i32, Cpp.Exception)` in each block into ONE
// shared `alloca` (no `phi`: both blocks store into the same slot, and the
// convergence block reads it). `G` is the
// `void` callee shape: no return out-pointer. `M` is the member-callee shape:
// the catching thunk takes the object (`const C&` / `C&`) as its first
// parameter and calls the method on it inside the `try`.

// --- catching_thunk.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
int may_throw_int();
void may_throw();
struct C {
  int get() const;
  int mutate();
};
''';

fn F() -> Core.Result(i32, Cpp.Exception) {
  return Core.Result(i32, Cpp.Exception).Ok(Cpp.may_throw_int()?);
}

fn G() -> Core.Result((), Cpp.Exception) {
  Cpp.may_throw()?;
  return Core.Result((), Cpp.Exception).Ok(());
}

fn M(c: Cpp.C, p: Cpp.C*) -> Core.Result(i32, Cpp.Exception) {
  var a: i32 = c.get()?;
  var b: i32 = p->mutate()?;
  return Core.Result(i32, Cpp.Exception).Ok(a + b);
}

