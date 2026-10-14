// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/interoperability/README.md, "Importing C++ code (inline)", block
// EXPECT-ERROR: name `Cpp` not found

fn Twice(n: i32) -> i32 { return n * 2; }

inline Cpp '''c++
inline int CallTwice(int n) { return Carbon::Twice(n) + 1; }
''';
