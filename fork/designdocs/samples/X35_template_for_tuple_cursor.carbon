// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Templates in the 0.1 toolchain", quote
// EXPECT-CRASH: Lowering function Sum(Counter)
// QUOTE: a range whose cursor is a tuple or a class
// Pins the page's limit, measured after TP-1, on a `for` loop whose range
// depends on a template parameter and whose cursor type is initialized in
// place: the compiler stops while it lowers `Sum(Counter)`. The cursor's
// storage is allocated after the call that initializes it, which the
// toolchain's own TODO in toolchain/check/handle_loop_statement.cpp records;
// a loop over an array or a `Core.Range`, whose cursor is an integer, runs
// (fork work item W-264). The same loop in a function without a template
// parameter runs and prints 6.

class Counter {
  var n: i32;
  impl as Core.Iterate where .CursorType = (i32, i32) and .ElementType = i32 {
    fn NewCursor(self) -> (i32, i32) { return (0, self.n); }
    fn Next(unused self, ref cursor: (i32, i32)) -> Core.Optional(i32) {
      if (cursor.0 >= cursor.1) {
        return Core.Optional(i32).None();
      }
      let v: i32 = cursor.0;
      cursor.0 = v + 1;
      return Core.Optional(i32).Some(v);
    }
  }
}

fn Sum[template T: type](c: T) -> i32 {
  var s: i32 = 0;
  for (x: i32 in c) {
    s += x;
  }
  return s;
}

fn Use() -> i32 {
  let c: Counter = {.n = 4};
  return Sum(c);
}
