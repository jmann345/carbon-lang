// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/interoperability/README.md, "Importing C++ code (inline)", quote
// EXPECT-STDOUT:
//   3
//   1
//   1
// QUOTE: so a C++ `"\n"` is written `"\\n"`, or the whole block is written as a raw block string literal `#'''...'''#`
// Pins the page's escape-sequence sentence. Carbon processes the escape
// sequences of a block string literal before C++ sees the text, so `"a\\nb"`
// reaches C++ as a three-character string whose middle character is a
// newline, and `"\\n"[0]` is 10; a raw block string literal passes `"\n"` to
// C++ unchanged, so its `"\n"[0]` is 10 too. The unescaped form, `"\n"` in a
// plain block string literal, ends the C++ line inside the string literal and
// does not compile (the plan's probe PR-V, section 4.3).

import Core library "io";

import Cpp inline '''c++
#include <cstring>
inline int NewlineLength() { return std::strlen("a\\nb"); }
inline int IsNewline() { return "\\n"[0] == 10; }
''';

import Cpp inline #'''c++
inline int RawIsNewline() { return "\n"[0] == 10; }
'''#;

fn Run() -> i32 {
  Core.Print(Cpp.NewlineLength());
  Core.Print(Cpp.IsNewline());
  Core.Print(Cpp.RawIsNewline());
  return 0;
}
