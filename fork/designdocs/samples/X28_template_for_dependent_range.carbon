// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Templates in the 0.1 toolchain", quote
// EXPECT-CRASH: Checking ForHeader
// QUOTE: stops the compiler where the function is defined, whether or not the function is called
// Pins the page's limit on a `for` loop whose range depends on a template
// parameter: the compiler stops while it checks the loop's header in the
// definition, here with no call of `Sum` at all, on the fork toolchain and
// the nightly (fork work item W-014). The same loop over an `array(i32, 3)`
// parameter in a function without a template parameter runs and prints 6.

fn Sum[template T: type](a: T) -> i32 {
  var s: i32 = 0;
  for (x: i32 in a) {
    s += x;
  }
  return s;
}
