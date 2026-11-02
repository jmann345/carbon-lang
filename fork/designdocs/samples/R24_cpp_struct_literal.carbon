// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/interoperability/README.md, "Struct literals", block
// EXPECT-ERROR: cannot implicitly convert expression of type `{.first: Core.IntLiteral, .second: Core.IntLiteral}` to `Cpp.Pair`

import Cpp inline '''c++
struct Pair {
  int first;
  int second;
};
''';

fn F() -> i32 {
  var p: Cpp.Pair = {.first = 1, .second = 2};
  return p.first;
}
