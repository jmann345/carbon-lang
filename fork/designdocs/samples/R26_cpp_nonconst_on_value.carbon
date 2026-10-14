// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/interoperability/README.md, "Accessing C++ classes, structs, and members", block
// EXPECT-ERROR: no matching function for call to 'Inc'

import Cpp inline '''c++
struct Counter {
  int n = 1;
  void Inc() { ++n; }
};
''';

fn F() {
  let c: Cpp.Counter = Cpp.Counter.Counter();
  c.Inc();
}
