// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Stdlib: String and string-literal types
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   Hello, Carbon!
//   14
//   abcabc
//   6
//   field
//   1
//   Hello, Carbon!
//
// The owning string `Core.StringBuf` (core/prelude/types/string.carbon,
// fork/string/plan.md): a heap block freed by its declared `Destroy` impl,
// not copyable (a copy is `Core.StringBuf.Make(s)`), viewed as `str` through
// `ImplicitAs(str)`. What the expected lines observe: a string built in a
// callee leaves it through `returned var` with its bytes intact (a `return`
// of a plain `var` would copy, which `StringBuf` rejects); `s += s` appends
// the string's own bytes; a `StringBuf` held in a field reads back; and an
// explicit copy is independent of its source. That blocks are freed is not
// observable here: the destroy calls are pinned by
// toolchain/lower/testdata/string/string_buf.carbon, and the allocation
// balance is the plan's manual shim check (fork/string/plan.md §8). Expected
// lines: "Hello, " (7 bytes) + "Carbon" (6) + "!" (1) = 14 bytes; "abc" +
// "abc"; the field's bytes; the copy gained a "?" so it differs (1); the
// source is unchanged.

import Core library "io";

class Greeting {
  var text: Core.StringBuf;
}

fn PrintStr(s: str) {
  let n: i64 = s.Size();
  var i: i64 = 0;
  while (i < n) {
    Core.PrintChar(s[i]);
    ++i;
  }
  Core.PrintChar('\n');
}

fn MakeGreeting(who: str) -> Core.StringBuf {
  returned var g: Core.StringBuf = "Hello, " + who;
  g += "!";
  return var;
}

fn Run() -> i32 {
  var g: Core.StringBuf = MakeGreeting("Carbon");
  PrintStr(g);
  Core.Print(g.Size() as i32);

  var s: Core.StringBuf = Core.StringBuf.Make("abc");
  s += s;
  PrintStr(s);
  Core.Print(s.Size() as i32);

  var holder: Greeting = {.text = Core.StringBuf.Make("field")};
  PrintStr(holder.text);

  var copy: Core.StringBuf = Core.StringBuf.Make(g);
  copy += "?";
  Core.Print(if copy != g then 1 else 0);
  PrintStr(g);
  return 0;
}
