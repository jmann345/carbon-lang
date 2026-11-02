// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/interoperability/README.md, "The operator interoperability model", block
// EXPECT-ERROR: cannot implicitly convert expression of type `Core.IntLiteral` to `Cpp.Cell`

import Cpp inline '''c++
struct Cell {
  int value;
  static Cell Make(int n) { return Cell{n}; }
  Cell& operator=(int n) {
    value = n;
    return *this;
  }
};
''';

fn F() -> i32 {
  var c: Cpp.Cell = Cpp.Cell.Make(1);
  c = 42;
  return c.value;
}
