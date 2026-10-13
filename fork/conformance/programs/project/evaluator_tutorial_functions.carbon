// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Project: basic evaluator documentation (getting started to FAQs)
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   30
//   3
//   2
//   1
//   0
//   1
//
// Transcribed from docs/guides/tutorial.md, section "Values, variables and functions": the
// code after this comment block is that page's code block byte for
// byte (fork/evaluator/check_samples.py, rulebook R27). Expected output
// derived by hand in fork/evaluator/plan.md section 4 (R16(d)). Runs
// on the upstream nightly and this fork's toolchain.

import Core library "io";

fn Square(x: i32) -> i32 {
  return x * x;
}

fn SumOfSquares(n: i32) -> i32 {
  var total: i32 = 0;
  for (i: i32 in Core.InclusiveRange(1, n)) {
    total += Square(i);
  }
  return total;
}

fn Run() -> i32 {
  let limit: i32 = 4;
  Core.Print(SumOfSquares(limit));

  var countdown: i32 = 3;
  while (countdown > 0) {
    Core.Print(countdown);
    --countdown;
  }

  let parity: i32 = if limit % 2 == 0 then 0 else 1;
  Core.Print(parity);
  Core.Print(if (limit + 1) % 2 == 0 then 0 else 1);
  return 0;
}
