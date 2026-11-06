// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/interoperability/README.md, "Integers", block
// EXPECT-ERROR: cannot implicitly convert expression of type `Cpp.long_long` to `i64`

import Cpp inline '''c++
inline long long NextLongLong(long long x) { return x + 1; }
''';

fn F() -> i64 {
  let h: i64 = Cpp.NextLongLong(8);
  return h;
}
