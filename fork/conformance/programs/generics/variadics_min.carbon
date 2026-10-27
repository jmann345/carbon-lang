// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: Definition-checked variadics
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   1
//   5
//   2
//   2
//   0
//   0
//
// The design's Min (docs/design/variadics.md, "Additional examples"), with
// the prelude's `Core.Ordered & Core.Copy & Core.Destroy` for the design's
// `Comparable & Value`: a statement expansion whose body is an `if`
// statement, executed once per element in order ("A statement of the form
// `...` statement is evaluated by executing statement N times"). Min(3, 1, 2)
// is 1, Min(5) is 5 with no iteration, and Min(4, 9, 2, 2, 7) is 2. Find
// returns the 1-based position of the first element equal to its target,
// leaving the function from an iteration's branch, and counts in the `else`
// branch: Find(2, 5, 2, 2) is 2 (the third element is never compared), and
// Find(9, 1, 2) and Find(1) are 0.

import Core library "io";

fn Min[T: Core.Ordered & Core.Copy & Core.Destroy](first: T, ... each next: T)
    -> T {
  var result: T = first;
  ... if (each next < result) {
    result = each next;
  }
  return result;
}

fn Find(target: i32, ... each x: i32) -> i32 {
  var pos: i32 = 0;
  ... if (each x == target) {
    return pos + 1;
  } else {
    pos = pos + 1;
  }
  return 0;
}

fn Run() -> i32 {
  Core.Print(Min(3 as i32, 1 as i32, 2 as i32));
  Core.Print(Min(5 as i32));
  Core.Print(Min(4 as i32, 9 as i32, 2 as i32, 2 as i32, 7 as i32));
  Core.Print(Find(2, 5, 2, 2));
  Core.Print(Find(9, 1, 2));
  Core.Print(Find(1));
  return 0;
}
