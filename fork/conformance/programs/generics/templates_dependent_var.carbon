// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: Integrated templates
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   5
//   6
//   11
//   0
//   1
//
// Proposal 2200 (p002200:198-199: impl lookup waits for the template
// arguments) and "Use of dependent value is dependent": a `var` of a template
// parameter's type, with or without an initializer (TP-1; DD-1 fixtures X20
// and X23, fork work item W-127). Swap(4, 5) assigns its second argument into
// y and returns 5; Peek returns top = 6. Keep(d) copies d into y with
// D's Copy, which adds 10 (n = 11), and y's destructor prints 11 when Keep
// returns, before Run prints Keep's result 0; d itself is destroyed when Run
// returns and prints 1. The same functions with D written out print the same
// lines.

import Core library "io";

class D {
  var n: i32;
  impl as Core.Copy {
    fn Op(self) -> Self { return {.n = self.n + 10}; }
  }
  impl as Core.Destroy {
    fn Op(ref self) { Core.Print(self.n); }
  }
}

fn Swap[template T: type](unused a: T, b: T) -> T {
  var y: T;
  y = b;
  return y;
}

class Stack(template T: type) {
  var top: T;
  fn Peek(self) -> T {
    var y: T;
    y = self.top;
    return y;
  }
}

fn Keep[template T: type](x: T) -> i32 {
  var unused y: T = x;
  return 0;
}

fn Run() -> i32 {
  Core.Print(Swap(4 as i32, 5 as i32));
  let s: Stack(i32) = {.top = 6};
  Core.Print(s.Peek());
  let d: D = {.n = 1};
  Core.Print(Keep(d));
  return 0;
}
