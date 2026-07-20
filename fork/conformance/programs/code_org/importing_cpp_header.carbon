// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Code organization: Importing
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   65
//
// The `import Cpp library "<header>"` form of the import declaration,
// alongside a plain Carbon `import Core library "io"` in the same file. The
// C++ standard header <cctype> is imported as the `Cpp` package
// (check/testdata/interop/cpp/basics and the install_test.py end-to-end
// program use this exact form with <iostream>); `Cpp.std.toupper` is a C++
// function with int parameter and int return, which map directly to Carbon
// i32 (check/testdata/interop/cpp/function/import/
// arithmetic_types_direct.carbon), so its result feeds straight into the
// Core.Print imported from Core//io. toupper(97 = 'a') == 65 = 'A'.

import Core library "io";
import Cpp library "<cctype>";

fn Run() -> i32 {
  Core.Print(Cpp.std.toupper(97));
  return 0;
}
