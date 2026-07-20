// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Functions: C++ interop — importing/calling C++ functions and methods
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   Hello from Carbon
//
// Imports a C++ standard library header and calls a C++ member operator
// (std::ostream::operator<<) on a C++ global (std::cout) from Carbon.
// This program is copied verbatim from the end-to-end installed-toolchain
// test toolchain/install/install_test.py (test_carbon_end_to_end), which
// compiles it with `carbon compile`, links with `carbon link`, executes the
// binary, and asserts this exact stdout.

import Cpp library "<iostream>";

fn Run() -> i32 {
  Cpp.std.cout << "Hello from Carbon\n";
  return 0;
}
