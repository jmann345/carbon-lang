// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Error handling: C++ exception interop (-fno-except config, calling throwing C++, exporting Carbon errors as std::expected/exceptions)
// COMPILE-ARGS: --cpp-exceptions=catch
// EXPECT-EXIT: -6
//
// B0 slice, the fenced boundary (decision F-006 sub-decision f;
// docs/design/error_handling.md "The fenced boundary: terminate
// semantics").
//
// What this program pins: in `catch` mode, a throwing C++ callee compiles,
// and an exception escaping it produces the documented deterministic abort
// — std::terminate -> SIGABRT, which the runner's subprocess reports as
// returncode -6 on POSIX. There is deliberately no stdout expectation:
// abort() skips the stdio flush, so buffered stdout is lost
// (fork/b0-exc/plan.md risk 6); the exit code is the whole observable.
// The `return 1` guard makes a run that survives the call fail loudly
// (exit 1 != -6 -> RUN-FAIL).
//
// What this program does NOT pin: the presence of the fence itself. No
// handler exists anywhere in this program, so an uncaught C++ exception
// reaches std::terminate during the phase-1 handler search — BEFORE any
// frame unwinds — and an unfenced exceptions-on build therefore exits -6
// identically. Exit code alone cannot discriminate "terminated at the
// thunk" from "terminated by the ordinary uncaught-exception path". The
// fence semantics (terminate AT the thunk boundary; no unwinding into
// Carbon frames even where an outer handler could exist) are pinned at the
// golden layer instead:
// toolchain/lower/testdata/interop/cpp/exceptions/fenced_thunk.carbon
// (invoke + terminate landing pad inside the thunk; nounwind Carbon
// caller) and toolchain/check/testdata/interop/cpp/exceptions/
// {fail_throw_in_none,catch_overrides_clang_arg}.carbon (mode semantics).
//
// Inline-C++ block shape from interop/cpp_operator_import_arithmetic.carbon.

import Core library "io";
import Cpp inline '''c++
#include <stdexcept>

inline auto AlwaysThrows() -> int {
  throw std::runtime_error("exception escaping into Carbon");
}
''';

fn Run() -> i32 {
  // The exception must never reach this frame: the fenced thunk terminates
  // the program before the call returns.
  Core.Print(Cpp.AlwaysThrows());
  // Guard: reachable only if the fence failed to terminate at the boundary.
  return 1;
}
