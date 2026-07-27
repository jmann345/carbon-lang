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
  // CHECK:STDERR: fail_fence_thunk_unbuildable.carbon:[[@LINE+24]]:3: error: semantics TODO: `Unsupported: fenced thunk for potentially-throwing C++ function could not be built` [SemanticsTodo]
  // CHECK:STDERR:   Cpp.consume(Cpp.make());
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR: fail_fence_thunk_unbuildable.carbon:[[@LINE+21]]:3: note: in thunk for C++ function used here [InCppThunk]
  // CHECK:STDERR:   Cpp.consume(Cpp.make());
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  // CHECK:STDERR: fail_fence_thunk_unbuildable.carbon:[[@LINE-19]]:6: error: call to deleted constructor of 'NoCopy' [CppInteropParseError]
  // CHECK:STDERR:    13 | void consume(NoCopy nc);
  // CHECK:STDERR:       |      ^~~~~~~
  // CHECK:STDERR: fail_fence_thunk_unbuildable.carbon:[[@LINE-26]]:3: note: 'NoCopy' has been explicitly marked deleted here [CppInteropParseNote]
  // CHECK:STDERR:     9 |   NoCopy(const NoCopy&) = delete;
  // CHECK:STDERR:       |   ^
  // CHECK:STDERR: fail_fence_thunk_unbuildable.carbon:[[@LINE-25]]:21: note: passing argument to parameter 'nc' here [CppInteropParseNote]
  // CHECK:STDERR:    13 | void consume(NoCopy nc);
  // CHECK:STDERR:       |                     ^
  // CHECK:STDERR: fail_fence_thunk_unbuildable.carbon:[[@LINE+8]]:3: note: in thunk for C++ function used here [InCppThunk]
  // CHECK:STDERR:   Cpp.consume(Cpp.make());
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  // CHECK:STDERR: fail_fence_thunk_unbuildable.carbon:[[@LINE+4]]:15: error: `Core.Destroy` implicitly referenced here, but package `Core` not found [CoreNotFound]
  // CHECK:STDERR:   Cpp.consume(Cpp.make());
  // CHECK:STDERR:               ^~~~~~~~~~
  // CHECK:STDERR:
  Cpp.consume(Cpp.make());
}
