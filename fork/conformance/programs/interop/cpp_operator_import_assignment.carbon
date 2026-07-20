// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Type system: C++ interop — synthesizing Carbon overloads for imported C++ types
// SKIP: assignment-operator import is the bullet's known-missing slice (audit: fail_todo): C++ `operator=(int)` is not imported, so `c = 42;` fails to compile with: error: cannot implicitly convert expression of type `Core.IntLiteral` to `Cpp.Cell` / note: type `Core.IntLiteral` does not implement interface `Core.ImplicitAs(Cpp.Cell)` — exact error verified against this toolchain; matches upstream check/testdata/interop/cpp/operators/operators.carbon (fail_todo_import_assignment.carbon).
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   42
//
// Written ahead of the feature (process.md step 1): when C++ `operator=`
// import lands, Carbon assignment `c = 42` should route through the imported
// assignment operator and this program should print 42 and exit 0. Un-SKIP
// it then.

import Cpp inline '''c++
struct Cell {
  int value;

  static auto Make(int n) -> Cell { return Cell{n}; }

  auto operator=(int n) -> Cell& {
    value = n;
    return *this;
  }
};
''';

import Core library "io";

fn Run() -> i32 {
  var c: Cpp.Cell = Cpp.Cell.Make(1);
  c = 42;
  Core.Print(c.value);
  return 0;
}
