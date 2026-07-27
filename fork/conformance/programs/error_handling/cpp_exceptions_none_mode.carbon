// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Error handling: C++ exception interop (-fno-except config, calling throwing C++, exporting Carbon errors as std::expected/exceptions)
// COMPILE-ARGS: --cpp-exceptions=none
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   42
//   -1
//
// B0 slice, `-fno-except config` arm of the bullet (decision F-006 stage
// B0; docs/design/error_handling.md "The --cpp-exceptions compile option"):
// `--cpp-exceptions=none` compiles imported C++ with
// `-fno-exceptions -fno-cxx-exceptions`, so a no-exceptions C++ dialect is
// a supported first-class configuration. The helper deliberately contains
// no `throw` (it would be a Clang compile error in this mode) and reports
// failure by value, the idiomatic -fno-exceptions style; calls cross the
// boundary as plain calls with zero added machinery. Expected values are
// derived by hand: 84/2 == 42, and a zero divisor returns the -1 sentinel.
// Inline-C++ block shape from interop/cpp_operator_import_arithmetic.carbon.
//
// Tests-first status (written before B0 is implemented): COMPILE-FAIL
// today — the `--cpp-exceptions` option does not exist yet in
// toolchain/driver/compile_options.cpp, so the driver rejects the flag.
// Flips to PASS when the B0 driver option lands.

import Core library "io";
import Cpp inline '''c++
inline auto SafeDiv(int num, int den) -> int {
  return den == 0 ? -1 : num / den;
}
''';

fn Run() -> i32 {
  Core.Print(Cpp.SafeDiv(84, 2));
  Core.Print(Cpp.SafeDiv(7, 0));
  return 0;
}
