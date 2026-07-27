// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/none.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/exceptions/fail_fence_thunk_unbuildable.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/exceptions/fail_fence_thunk_unbuildable.carbon

// --- fail_fence_thunk_unbuildable.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
struct NoCopy {
  NoCopy();
  NoCopy(const NoCopy&) = delete;
  NoCopy(NoCopy&&) = delete;
};
NoCopy make();
void consume(NoCopy nc);
''';

// `consume` is potentially-throwing, so the fenced-boundary contract
// (docs/design/error_handling.md#the-fenced-boundary-terminate-semantics)
// requires calling it through a fenced thunk — and it also needs an ABI
// thunk, since `NoCopy` is not a simple ABI type. The thunk body cannot be
// built: forwarding the by-value parameter needs a copy or move constructor
// the class deletes, while importing the declaration only checks that the
// types map. A silent unfenced fallback would break the boundary contract,
// so this must fail closed with the fence-unbuildable diagnostic.
fn F() {
  Cpp.consume(Cpp.make());
}
