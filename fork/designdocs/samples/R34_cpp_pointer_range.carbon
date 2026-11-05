// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/interoperability/README.md, "C++ ranges in `for` loops", block
// EXPECT-ERROR: cannot access member of interface `Core.Iterate` in type `Cpp.Digits` that does not implement that interface

import Core library "io";

import Cpp inline '''c++
struct Digits {
  int values[3] = {1, 2, 3};
  int* begin() { return values; }
  int* end() { return values + 3; }
};
''';

fn Run() -> i32 {
  var d: Cpp.Digits = Cpp.Digits.Digits();
  var product: i32 = 1;
  for (n: i32 in d) {
    product *= n;
  }
  Core.Print(product);
  return 0;
}
