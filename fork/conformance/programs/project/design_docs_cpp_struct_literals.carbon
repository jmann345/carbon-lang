// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Type system: C++ interop — importing C++ types / exporting Carbon types
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   42
//
// Documentation-sync program (fork/designdocs/plan.md D-DD-5): the code after
// this comment block is the P09 code block of
// docs/design/interoperability/README.md, section "Struct literals", byte for
// byte (fork/designdocs/check_samples.py, rulebook R27). Expected output
// derived by hand in fork/designdocs/plan.md section 4 (R16(d)). Fork-only: the
// upstream nightly rejects it (the plan's section 4). A PASS shows that the
// documented sample runs as documented; the design-docs bullet itself is
// arbitrated by document review.

import Core library "io";

import Cpp inline '''c++
struct Empty {};
struct Pair {
  int first;
  int second;
};
union Number {
  int as_int;
  float as_float;
};
inline Pair MakePair(int a, int b) { return {a, b}; }
''';

fn Run() -> i32 {
  // An empty aggregate initializes from an empty struct literal.
  var unused e: Cpp.Empty = {};
  // A C++ union initializes from a one-field struct literal naming the
  // active member.
  var n: Cpp.Number = {.as_int = 41};
  // A non-empty aggregate is built in C++ and then used field by field.
  var p: Cpp.Pair = Cpp.MakePair(1, 2);
  p.second = n.as_int;
  Core.Print(p.first + p.second);
  return 0;
}
