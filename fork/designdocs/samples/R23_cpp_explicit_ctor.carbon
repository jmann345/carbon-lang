// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/interoperability/README.md, "Constructors", block
// EXPECT-ERROR: no matching function for call to 'Length'

import Cpp inline '''c++
struct Meters {
  int n;
  explicit Meters(int v) : n(v) {}
};
inline int Length(Meters m) { return m.n; }
''';

fn F() -> i32 {
  return Cpp.Length(5);
}
