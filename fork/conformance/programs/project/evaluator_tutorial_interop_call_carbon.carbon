// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Project: basic evaluator documentation (getting started to FAQs)
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   14
//   100
//   20
//
// Transcribed from docs/guides/tutorial.md, section "Calling Carbon from C++": the
// code after this comment block is that page's code block byte for
// byte (fork/evaluator/check_samples.py, rulebook R27). Expected output
// derived by hand in fork/evaluator/plan.md section 4 (R16(d)). Runs
// on the upstream nightly and this fork's toolchain.

import Core library "io";
import Cpp;

// Carbon functions that the C++ code below calls.
fn Square(n: i32) -> i32 {
  return n * n;
}

fn Clamp(v: i32, lo: i32, hi: i32) -> i32 {
  if (v < lo) { return lo; }
  if (v > hi) { return hi; }
  return v;
}

// C++ code sees the Carbon functions in the `Carbon` namespace.
inline Cpp '''c++
inline int SumOfSquaresClamped(int n, int lo, int hi) {
  int total = 0;
  for (int i = 1; i <= n; ++i) {
    total += Carbon::Square(i);
  }
  return Carbon::Clamp(total, lo, hi);
}
''';

fn Run() -> i32 {
  Core.Print(Cpp.SumOfSquaresClamped(3, 0, 100));
  Core.Print(Cpp.SumOfSquaresClamped(10, 0, 100));
  Core.Print(Cpp.SumOfSquaresClamped(3, 20, 100));
  return 0;
}
