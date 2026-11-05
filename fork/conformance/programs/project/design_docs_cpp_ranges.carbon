// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Stdlib C++ interop: transparent iteration-abstraction mapping
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   12
//   4
//
// Documentation-sync program (fork/designdocs/plan.md D-DD-5): the code after
// this comment block is the P19 code block of
// docs/design/interoperability/README.md, section "C++ ranges in `for` loops",
// byte for byte (fork/designdocs/check_samples.py, rulebook R27). Expected
// output derived by hand in fork/designdocs/plan.md section 4 (R16(d)). Runs on
// this fork's toolchain and on the upstream nightly. A PASS shows that the
// documented sample runs as documented; the design-docs bullet itself is
// arbitrated by document review.

import Core library "io";

import Cpp inline '''c++
#include <vector>

inline std::vector<int> MakeVector() { return {2, 4, 6}; }
''';

fn Run() -> i32 {
  // A C++ range is a Carbon `for` range: the loop calls its `begin` and
  // `end`, and dereferences and increments the iterator.
  var v: Cpp.std.vector(i32) = Cpp.MakeVector();
  var sum: i32 = 0;
  for (n: i32 in v) {
    sum += n;
  }
  Core.Print(sum);
  v.push_back(8);
  var count: i32 = 0;
  for (unused n: i32 in v) {
    ++count;
  }
  Core.Print(count);
  return 0;
}
