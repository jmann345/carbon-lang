// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/interoperability/README.md, "Accessing C++ classes, structs, and members", block
// EXPECT-ERROR: cannot access private member `v_` of type `Cpp.Box`

import Cpp inline '''c++
class Box {
 public:
  Box() : v_(1) {}

 private:
  int v_;
};
''';

fn F() -> i32 {
  var b: Cpp.Box = Cpp.Box.Box();
  return b.v_;
}
