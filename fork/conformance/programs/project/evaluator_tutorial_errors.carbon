// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Project: basic evaluator documentation (getting started to FAQs)
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   3
//   -7
//   3
//   0
//
// Transcribed from docs/guides/tutorial.md, section "Errors as values": the
// code after this comment block is that page's code block byte for
// byte (fork/evaluator/check_samples.py, rulebook R27). Expected output
// derived by hand in fork/evaluator/plan.md section 4 (R16(d)). Runs
// on this fork's toolchain only (the upstream nightly rejects it).

import Core library "io";

// Returns the quotient, or the dividend as the error when dividing by zero.
fn Divide(a: i32, b: i32) -> Core.Result(i32, i32) {
  if (b == 0) {
    return Core.Result(i32, i32).Err(a);
  }
  return Core.Result(i32, i32).Ok(a / b);
}

// `?` returns early with the error; otherwise it unwraps the value.
fn Average(total: i32, count: i32) -> Core.Result(i32, i32) {
  let mean: i32 = Divide(total, count)?;
  return Core.Result(i32, i32).Ok(mean);
}

fn Report(r: Core.Result(i32, i32)) {
  match (r) {
    case .Ok(v: i32) => { Core.Print(v); }
    case .Err(e: i32) => { Core.Print(-e); }
  }
}

fn Run() -> i32 {
  Report(Average(12, 4));
  Report(Average(7, 0));
  if (let .Ok(v: i32) = Divide(9, 3)) {
    Core.Print(v);
  }
  if (let .Ok(v: i32) = Divide(1, 0)) {
    Core.Print(v);
  } else {
    Core.Print(0);
  }
  return 0;
}
