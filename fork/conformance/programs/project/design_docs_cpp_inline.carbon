// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Code organization: Importing
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   42
//   41
//
// Documentation-sync program (fork/designdocs/plan.md D-DD-5): the code after
// this comment block is the P07 code block of
// docs/design/interoperability/README.md, section "Importing C++ code
// (inline)", byte for byte (fork/designdocs/check_samples.py, rulebook R27).
// Expected output derived by hand in fork/designdocs/plan.md section 4
// (R16(d)). Runs on this fork's toolchain and on the upstream nightly. A PASS
// shows that the documented sample runs as documented; the design-docs bullet
// itself is arbitrated by document review.

import Core library "io";

// C++ source in an import: its declarations join the `Cpp` package like a
// header's.
import Cpp inline '''c++
inline int Triple(int x) { return 3 * x; }
''';

fn Twice(n: i32) -> i32 { return n * 2; }

// An `inline Cpp` declaration may follow Carbon declarations, and its C++
// code can call them through the `Carbon` namespace.
inline Cpp '''c++
inline int TwicePlusOne(int n) { return Carbon::Twice(n) + 1; }
''';

fn Run() -> i32 {
  Core.Print(Cpp.Triple(14));
  Core.Print(Cpp.TwicePlusOne(20));
  return 0;
}
