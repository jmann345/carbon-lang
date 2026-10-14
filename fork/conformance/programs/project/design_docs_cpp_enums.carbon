// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Type system: C++ interop — importing C++ types / exporting Carbon types
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   5
//   1
//   3
//
// Documentation-sync program (fork/designdocs/plan.md D-DD-5): the code after
// this comment block is the P15 code block of docs/design/README.md, section
// "Enums", byte for byte (fork/designdocs/check_samples.py, rulebook R27).
// Expected output derived by hand in fork/designdocs/plan.md section 4
// (R16(d)). Runs on this fork's toolchain and on the upstream nightly. A PASS
// shows that the documented sample runs as documented; the design-docs bullet
// itself is arbitrated by document review.

import Core library "io";

import Cpp inline '''c++
enum class Color : int { kRed, kGreen = 5, kBlue };
enum Level : int { kLow = 1, kHigh = 2 };
inline bool IsGreen(Color c) { return c == Color::kGreen; }
''';

fn Run() -> i32 {
  // Enumerators are members of the enumeration; `as` converts an
  // enumerator to its underlying integer type.
  let c: Cpp.Color = Cpp.Color.kGreen;
  Core.Print(c as i32);
  if (Cpp.IsGreen(c) and c == Cpp.Color.kGreen) {
    Core.Print(1);
  }
  // An unscoped enumeration's enumerators are also members of the enclosing
  // scope, as in C++.
  Core.Print((Cpp.kHigh as i32) + (Cpp.Level.kLow as i32));
  return 0;
}
