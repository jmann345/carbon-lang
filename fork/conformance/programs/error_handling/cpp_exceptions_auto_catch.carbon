// CONFORMANCE-BULLET: Error handling: C++ exception interop (-fno-except config, calling throwing C++, exporting Carbon errors as std::expected/exceptions)
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   42
//   24
//
// B0 slice, `calling throwing C++` arm, default-mode resolution (decision
// F-006 sub-decision e: `--cpp-exceptions` defaults to `auto`;
// docs/design/error_handling.md decision D5): no COMPILE-ARGS, so the
// default `auto` mode must resolve to `catch` — this program contains a
// literal `throw`, which is a Clang compile error under `none`
// ("cannot use 'throw' with exceptions disabled"), so merely compiling
// proves the auto->catch arm. The throwing path is never taken at runtime,
// locking the design's zero-cost-success-path claim: a potentially-throwing
// callee that does not throw behaves exactly like a plain call. Expected
// values derived by hand: 84/2 == 42, 120/5 == 24. Inline-C++ block shape
// from interop/cpp_operator_import_arithmetic.carbon; <stdexcept> include
// precedent from interop/string_view_cpp_to_str.carbon (<string_view>).
//
// Tests-first status (written before B0 is implemented): today's default
// Clang invocation (toolchain/base/clang_invocation.cpp) inherits the
// target's exceptions-on default, so this program may already compile and
// pass — but only B0 pins that as a contract (`auto` resolving to `catch`)
// instead of an accident of the embedded Clang's defaults; the fence for
// the taken-throw case is arbitrated by cpp_exceptions_fence_terminate.carbon.

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
