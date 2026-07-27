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
// B0; docs/design/error_handling.md "The --cpp-exceptions compile option").
//
// What this program pins: the driver accepts `--cpp-exceptions=none`, and
// a value-reporting no-exceptions-style C++ helper builds and runs
// correctly under it. The helper deliberately contains no `throw` and
// reports failure by value, the idiomatic -fno-exceptions style; calls
// cross the boundary as plain calls. Expected values are derived by hand:
// 84/2 == 42, and a zero divisor returns the -1 sentinel.
//
// What this program does NOT pin: that `none` actually disables
// exceptions. With no `throw` in the C++ block, this program would pass
// even if the flag were parsed and ignored. The rejection of `throw`
// under `none` is pinned by the check golden
// toolchain/check/testdata/interop/cpp/exceptions/fail_throw_in_none.carbon,
// and the claim that `none` mode generates code byte-identical to an
// explicit -fno-exceptions build today is pinned by the four untouched
// -fno-exceptions sentinel goldens
// (toolchain/lower/testdata/interop/cpp/class/{virtual_fn,
// import/copy_vs_move,export/method,export/class}.carbon), not by this
// program.
//
// Inline-C++ block shape from interop/cpp_operator_import_arithmetic.carbon.

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
