// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/pattern_matching.md, "`match` in the 0.1 toolchain", quote
// EXPECT-ERROR: name `n` not found
// QUOTE: name `n` not found
// Pins the page's sentence on alternative patterns written with the choice
// type's name: `Opt.Some(n: i32)` is not parsed as a pattern, so `n: i32` is
// read as an expression and its name is not found. The upstream nightly
// rejects the file earlier, at the choice's payload.

choice Opt {
  None,
  Some(v: i32)
}

fn F(o: Opt) -> i32 {
  match (o) {
    case Opt.Some(n: i32) => { return n; }
    default => { return 0; }
  }
  return -1;
}
