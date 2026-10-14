// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/interoperability/README.md, "Advanced type mapping: pointers, references, and `const`", block
// EXPECT-ERROR: argument to `ref` parameter not marked with `ref`

import Cpp inline '''c++
inline void AddTen(int& r) { r += 10; }
''';

fn F() -> i32 {
  var n: i32 = 1;
  Cpp.AddTen(n);
  return n;
}
