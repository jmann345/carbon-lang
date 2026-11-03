// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/metaprogramming.md, "Compile-time evaluation in the 0.1 toolchain", block
// EXPECT-ERROR: array bound is not a constant

fn Three() -> i32 { return 3; }

var a: array(i32, Three()) = (0, 1, 2);
