// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Stdlib: String and string-literal types
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   Carbon 0.1
//   10
//   1024
//   1
//   abcabcabc!
//
// Concatenation in loops (core/prelude/types/string.carbon,
// fork/string/plan.md). `acc += w` appends: each append allocates the joined
// block and frees the previous one (string.carbon's `AddAssignWith(str)`; the
// allocation balance is not observable here and is the plan's manual shim
// check, fork/string/plan.md §8). Expected lines: "Car" + "bon" + " " + "0.1"
// (10 bytes); ten self-appends double one byte to 2^10 = 1024 bytes, every one
// 'z' (1); a chained `+` builds "abc" three times plus "!" left to right.
// Loops append with `+=`, never `acc = acc + w;`: assignment does not yet
// destroy the value it overwrites (check/handle_operator.cpp TODO), so that
// spelling would leak the previous block (fork/string/plan.md residue W-160).

import Core library "io";

fn PrintStr(s: str) {
  let n: i64 = s.Size();
  var i: i64 = 0;
  while (i < n) {
    Core.PrintChar(s[i]);
    ++i;
  }
  Core.PrintChar('\n');
}

fn Run() -> i32 {
  let words: array(str, 4) = ("Car", "bon", " ", "0.1");
  var acc: Core.StringBuf = Core.StringBuf.Make("");
  for (w: str in words) {
    acc += w;
  }
  PrintStr(acc);
  Core.Print(acc.Size() as i32);

  var big: Core.StringBuf = Core.StringBuf.Make("z");
  var k: i32 = 0;
  while (k < 10) {
    big += big;
    ++k;
  }
  Core.Print(big.Size() as i32);
  let view: str = big;
  var all_z: bool = true;
  var i: i64 = 0;
  while (i < view.Size()) {
    if (view[i] != 'z') {
      all_z = false;
    }
    ++i;
  }
  Core.Print(if all_z then 1 else 0);

  let piece: str = "abc";
  var chained: Core.StringBuf = piece + piece + piece + "!";
  PrintStr(chained);
  return 0;
}
