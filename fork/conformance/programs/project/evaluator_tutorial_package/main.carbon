// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Project: basic evaluator documentation (getting started to FAQs)
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   12
//   14
//
// Transcribed from docs/guides/tutorial.md, section "A multi-file package": the
// code after this comment block is that page's code block byte for
// byte (fork/evaluator/check_samples.py, rulebook R27). Expected output
// derived by hand in fork/evaluator/plan.md section 4 (R16(d)). Runs
// on the upstream nightly and this fork's toolchain.

import Core library "io";
import Geometry;

fn Run() -> i32 {
  let r: Geometry.Rect = {.width = 3, .height = 4};
  Core.Print(Geometry.Area(r));
  Core.Print(Geometry.Perimeter(r));
  return 0;
}
