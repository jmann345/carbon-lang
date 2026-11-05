// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/interoperability/README.md, "Accessing global variables", block
// EXPECT-ERROR: expression is not assignable

import Cpp inline '''c++
inline const int kLimit = 100;
''';

fn F() {
  Cpp.kLimit = 3;
}
