// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/interoperability/README.md, "Using Carbon from C++", block
// EXPECT-ERROR: semantics TODO: `binding maps to a non-type template parameter`

import Cpp;

fn Times[N: i32](x: i32) -> i32 { return N * x; }

inline Cpp '''c++
inline int UseTimes() { return Carbon::Times<3>(2); }
''';
