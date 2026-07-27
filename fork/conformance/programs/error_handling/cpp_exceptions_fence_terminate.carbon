// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Error handling: C++ exception interop (-fno-except config, calling throwing C++, exporting Carbon errors as std::expected/exceptions)
// COMPILE-ARGS: --cpp-exceptions=catch
// EXPECT-EXIT: -6
//
// B0 slice, the fenced boundary (decision F-006 sub-decision f;
// docs/design/error_handling.md "The fenced boundary: terminate
// semantics"): in `catch` mode an exception escaping a C++ callee must hit
// a deterministic std::terminate AT the generated thunk — a defined,
// documented crash — instead of unwinding into Carbon frames (today's
// undefined behavior). std::terminate aborts, the runner's subprocess
// reports a signal-killed child as a negative returncode on POSIX, so
// SIGABRT (6) is asserted as an expected exit code of -6. There is
// deliberately no stdout expectation: abort() skips the stdio flush, so
// buffered stdout is lost (fork/b0-exc/plan.md risk 6); the exit code is
// the whole observable.
// The `return 1` guard makes a non-terminating fence fail loudly
// (exit 1 != -6 -> RUN-FAIL). Inline-C++ block shape from
// interop/cpp_operator_import_arithmetic.carbon.
//
// Tests-first status (written before B0 is implemented): COMPILE-FAIL
// today — the `--cpp-exceptions` option does not exist yet in
// toolchain/driver/compile_options.cpp, so the driver rejects the flag.
// Flips to PASS when the B0 fenced thunks land (toolchain/check/cpp/
// thunk.cpp routing potentially-throwing callees through a noexcept-fenced
// thunk). This is the documented-crash program: the same call built today
// without the flag would unwind through Carbon frames with no defined
// behavior at all.

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
