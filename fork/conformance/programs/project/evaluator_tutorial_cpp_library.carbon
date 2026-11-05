// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Project: basic evaluator documentation (getting started to FAQs)
// BUILD-SCRIPT: fork/evaluator/cpp_library/build.sh
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   42
//
// Transcribed from docs/guides/tutorial.md, section "Linking your own C++ library": the
// code after this comment block is that page's code block byte for
// byte (fork/evaluator/check_samples.py, rulebook R27). Expected output
// derived by hand in fork/evaluator/plan.md section 4 (R16(d)). Runs
// on the upstream nightly and this fork's toolchain.
// fork/evaluator/cpp_library/build.sh builds this body's
// byte-identical copy fork/evaluator/cpp_library/main.carbon with
// rectangle.cpp by the section's commands; the runner never
// compiles this file itself.

import Core library "io";
import Cpp library "rectangle.h";

fn Run() -> i32 {
  Core.Print(Cpp.RectangleArea(6, 7));
  return 0;
}
