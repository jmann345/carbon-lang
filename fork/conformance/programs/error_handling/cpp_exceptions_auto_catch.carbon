// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Error handling: C++ exception interop (-fno-except config, calling throwing C++, exporting Carbon errors as std::expected/exceptions)
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   42
//   24
//
// B0 slice, `calling throwing C++` arm, default-mode behavior (decision
// F-006 sub-decision e: `--cpp-exceptions` defaults to `auto`;
// docs/design/error_handling.md decision D5).
//
// What this program pins: with no COMPILE-ARGS, the default build keeps
// C++ exceptions ENABLED — this program contains a literal `throw`, which
// is a Clang compile error with exceptions disabled ("cannot use 'throw'
// with exceptions disabled"), so merely compiling proves the default
// remains exceptions-on. The throwing path is never taken at runtime,
// locking the design's zero-cost-success-path claim: a potentially-throwing
// callee that does not throw behaves like a plain call.
//
// What this program does NOT pin: that `auto` RESOLVED to `catch` through
// the mode machinery. An exceptions-on outcome is observationally identical
// here whether it came from auto-resolution or from the embedded Clang's
// target default (toolchain/base/clang_invocation.cpp). The resolution
// logic itself is pinned by the check goldens
// toolchain/check/testdata/interop/cpp/exceptions/
// {auto_resolves_none,catch_overrides_clang_arg}.carbon.
//
// Expected values derived by hand: 84/2 == 42, 120/5 == 24. Inline-C++
// block shape from interop/cpp_operator_import_arithmetic.carbon;
// <stdexcept> include precedent from interop/string_view_cpp_to_str.carbon
// (<string_view>). The taken-throw case is exercised by
// cpp_exceptions_fence_terminate.carbon (see its comment for what that
// program does and does not pin).

import Core library "io";
import Cpp inline '''c++
#include <stdexcept>

inline auto CheckedDiv(int num, int den) -> int {
  if (den == 0) {
    throw std::runtime_error("division by zero");
  }
  return num / den;
}
''';

fn Run() -> i32 {
  // Both calls use nonzero divisors: the throw path is never taken.
  Core.Print(Cpp.CheckedDiv(84, 2));
  Core.Print(Cpp.CheckedDiv(120, 5));
  return 0;
}
