// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Templates in the 0.1 toolchain", quote
// EXPECT-ERROR: semantics TODO: `match on unsupported scrutinee type`
// QUOTE: semantics TODO: `match on unsupported scrutinee type`
// Pins the page's limit on `match` over a template-dependent value: proposal
// 2200's "Use of dependent value is dependent" section makes each `case` body
// of such a `match` dependent, and the toolchain rejects the `match`. The
// plan's probe PR-D (section 4.3) is the same function with a `Run`. The
// upstream nightly has no `match` and reports a different `semantics TODO`.

fn Kind[template T: type](x: T) -> i32 {
  match (x) {
    case _: i32 => { return 32; }
    default => { return 0; }
  }
}

fn Use() -> i32 {
  return Kind(1 as i32);
}
