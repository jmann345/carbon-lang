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

// The catching thunk, lowered (docs/design/error_handling.md, "Catching
// imports"; fork/eh/plan.md §4.B): inside the still-`noexcept` thunk the
// callee is `invoke`d with a `landingpad ... catch ptr null` handler that
// stores `__cxa_current_primary_exception()` through the error out-pointer and
// returns the discriminant 1, while the success path stores the return value
// through the return out-pointer and returns 0; the Carbon caller compares
// the discriminant with 0 (`icmp`/`br`) and constructs the `Ok` or `Err`
// alternative of `Core.Result(i32, Cpp.Exception)` in each block. `G` is the
// `void` callee shape: no return out-pointer.

// --- catching_thunk.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
int may_throw_int();
void may_throw();
''';

fn F() -> Core.Result(i32, Cpp.Exception) {
  return Core.Result(i32, Cpp.Exception).Ok(Cpp.may_throw_int()?);
}

fn G() -> Core.Result((), Cpp.Exception) {
  Cpp.may_throw()?;
  return Core.Result((), Cpp.Exception).Ok(());
}
