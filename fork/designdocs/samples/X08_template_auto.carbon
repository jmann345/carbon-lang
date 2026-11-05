// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Templates in the 0.1 toolchain", quote
// EXPECT-ERROR: semantics TODO: `HandleAutoTypeLiteral`
// QUOTE: semantics TODO: `HandleAutoTypeLiteral`
// Pins the page's limit on `auto`, which proposal 2200 calls a shortcut for an
// unnamed templated type: proposal 2200's own `let x: auto = F();` is rejected
// at `auto` (fork work item W-039). `fn F() -> auto` reports the same (the
// plan's probe PR-AB, section 4.3).

fn F() -> i32 { return 3; }

fn G() -> i32 {
  let x: auto = F();
  return x;
}
