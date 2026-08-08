// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Error handling: C++ exception interop (-fno-except config, calling throwing C++, exporting Carbon errors as std::expected/exceptions)
// EXPECT-EXIT: 0
//
// Differential pair — the B0 boundary-contract value lock. The C++ helpers
// here are byte-identical to the ones in
// cpp_exceptions_fence_value_diff.diff.cpp; the oracle calls them natively
// (plain calls, no fence anywhere) while this program calls them from
// Carbon across the B0 boundary under the default mode (no COMPILE-ARGS:
// `--cpp-exceptions` defaults to `auto`, resolving to `catch` /
// exceptions-on here — the same exceptions-on default the runner's bare
// `clang++ -std=c++17` oracle compile gets). Byte-identical exit code and
// stdout are required per DIFF-1; no EXPECT-STDOUT — C++ computes the
// expectation.
//
// What this differential arbitrates: that int argument and return values —
// including negative values and both i32 range extremes — cross the B0
// boundary exactly, on BOTH call paths the boundary contract distinguishes
// (toolchain/check/cpp/thunk.cpp):
//   - `CheckedScale` is potentially-throwing (a literal `throw` on a
//     guarded path the probe values never take), so per
//     `IsCppThunkFenceRequired` its calls route through the FENCED thunk —
//     the noexcept exception-spec of B0 SF-1 (`CreateThunkFunctionDecl`,
//     EST_BasicNoexcept; lowered as invoke + terminate landing pad per
//     toolchain/lower/testdata/interop/cpp/exceptions/fenced_thunk.carbon).
//   - `SaturatingAdd` is `noexcept` (canThrow() == CT_Cannot), so the
//     fence predicate exempts it: a plain unfenced call.
// Agreement with the native oracle pins the design's claim that the fence
// is value-transparent when nothing throws — a potentially-throwing callee
// that does not throw behaves exactly like the same call without a fence
// (docs/design/error_handling.md zero-cost success path).
//
// What it does NOT arbitrate (deferred to B3): any taken-throw
// differential. Pre-B3 a thrown exception's only observable is the fence
// terminate — SIGABRT / exit -6 with abort-truncated stdout — which exit
// codes cannot distinguish from the oracle's own ordinary
// uncaught-exception terminate (see cpp_exceptions_fence_terminate.carbon,
// which pins that path non-differentially). A throw-path differential
// needs the exception to become a comparable VALUE, i.e. B3's catching
// thunks into Core.Result — it rides B3 alongside the un-SKIP of
// cpp_exception_interop.carbon. Nor does value agreement prove the fence
// EXISTS (an unfenced build computes the same values); fence presence is
// pinned by the lower golden above.
//
// Values derived by hand: 21*2 == 42; -42*5 == -210; 2147483647+42
// saturates to 2147483647; (-2147483647-1)+(-1) saturates to -2147483648;
// (42+8)*2 == 100. Inline-C++ block shape from
// interop/cpp_operator_import_arithmetic.carbon; <stdexcept> include
// precedent from cpp_exceptions_auto_catch.carbon.

import Core library "io";
import Cpp inline '''c++
#include <stdexcept>

// Potentially throwing: `throw` on a guarded path the probe values never
// take. Calls from Carbon cross the fenced (noexcept) thunk.
inline auto CheckedScale(int value, int factor) -> int {
  if (factor == 0) {
    throw std::invalid_argument("zero factor");
  }
  return value * factor;
}

// noexcept: exempt from the fence (IsCppThunkFenceRequired); plain call.
inline auto SaturatingAdd(int a, int b) noexcept -> int {
  long long sum = static_cast<long long>(a) + b;
  if (sum > 2147483647LL) {
    return 2147483647;
  }
  if (sum < -2147483648LL) {
    return -2147483647 - 1;
  }
  return static_cast<int>(sum);
}
''';

fn Run() -> i32 {
  // Fenced path: runtime-computed chain through the potentially-throwing
  // callee; the throw is never taken. Negative value pins sign extension.
  var acc: i32 = Cpp.CheckedScale(21, 2);
  Core.Print(acc);
  Core.Print(Cpp.CheckedScale(0 - acc, 5));
  // Unfenced path: noexcept callee at both i32 range extremes.
  Core.Print(Cpp.SaturatingAdd(2147483647, acc));
  Core.Print(Cpp.SaturatingAdd(0 - 2147483647 - 1, 0 - 1));
  // Composed: a value round-trips through the unfenced then the fenced
  // thunk in one expression.
  Core.Print(Cpp.CheckedScale(Cpp.SaturatingAdd(acc, 8), 2));
  return 0;
}
