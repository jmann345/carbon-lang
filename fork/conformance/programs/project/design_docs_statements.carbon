// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Control flow: loops incl. range-based and C/C++ loop equivalents
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   13
//   0
//   12
//   11
//
// Documentation-sync program (fork/designdocs/plan.md D-DD-5): the code after
// this comment block is the P02 code block of
// docs/design/blocks_and_statements.md, section "Statements in the 0.1
// toolchain", byte for byte (fork/designdocs/check_samples.py, rulebook R27).
// Expected output derived by hand in fork/designdocs/plan.md section 4
// (R16(d)). Runs on this fork's toolchain and on the upstream nightly. A PASS
// shows that the documented sample runs as documented; the design-docs bullet
// itself is arbitrated by document review.

import Core library "io";

fn Classify(n: i32) -> i32 {
  if (n < 0) {
    return -1;
  } else if (n == 0) {
    return 0;
  } else {
    return 1;
  }
}

fn MakeSix() -> i32 {
  // `returned var` names the object a later `return var;` returns.
  returned var result: i32 = 1;
  result *= 6;
  return var;
}

fn Run() -> i32 {
  // Declarations are statements: `var`, `let`, and local types and functions.
  var total: i32 = 0;
  let limit: i32 = 5;
  class Pair {
    var a: i32;
    var b: i32;
  }
  fn Add(p: Pair) -> i32 { return p.a + p.b; }

  // A `while` loop with `continue` and `break`.
  var i: i32 = 0;
  while (true) {
    i += 1;
    if (i == 2) {
      continue;
    }
    if (i > limit) {
      break;
    }
    total += i;
  }
  // Expression statements, assignment, and increment.
  Core.Print(total);
  total = Classify(-7);
  ++total;
  Core.Print(total);

  // `for` loops over an array and over a range.
  var sum: i32 = 0;
  let values: array(i32, 3) = (1, 2, 3);
  for (v: i32 in values) {
    sum += v;
  }
  for (k: i32 in Core.Range(4)) {
    sum += k;
  }
  Core.Print(sum);
  Core.Print(Add({.a = 2, .b = 3}) + MakeSix());
  return 0;
}
