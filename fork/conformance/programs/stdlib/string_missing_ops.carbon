// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Stdlib: String and string-literal types
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   1
//   4
//
// Written test-first for the String bullet and un-SKIPped at ST-1
// (fork/string/plan.md; working slice: string_basic.carbon). `a == b` is the
// byte-wise `String as EqWith(String)` impl and `a + b` is `String as
// AddWith(String)`, whose result is the owning `Core.StringBuf`, so `c` is a
// `var` that owns it; both are in core/prelude/types/string.carbon. At the
// un-SKIP the test-first `let c: str = a + b;` became
// `var c: Core.StringBuf = a + b;`, the EXPECT unchanged: a `str` view of that
// temporary would be used after its full-expression, which the fork's design
// rejects (F-013 D-SAFE-12) and which this toolchain allows only because it
// destroys a declaration's temporaries at the end of the block.

import Core library "io";

fn Run() -> i32 {
  let a: str = "hi";
  let b: str = "hi";
  // `String as EqWith(String)`: byte-wise.
  Core.Print(if a == b then 1 else 0);
  // `String as AddWith(String)`: concatenation into a `Core.StringBuf`.
  var c: Core.StringBuf = a + b;
  Core.Print(c.Size() as i32);
  return 0;
}
