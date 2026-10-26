// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Stdlib: Slices
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   1
//   20
//   21
//   15
//   27
//
// Writes through `Core.Slice` and `Core.Buf` subscripts (DR-1 D-DR-7: `Ref`
// returns `ref T`, upstream 6d80ceb58 and 309d3d63c). Hand-derived: `a` is
// (1, 2, 3); `s[1] = 20` makes it (1, 20, 3); `s[2] = s[0] + s[1]` makes it
// (1, 20, 21); the `Buf` gets 7 at 0 by `b[0] = 7` and 8 at 1 by `Set`, and
// `b[2] = b[0] + b[1]` stores 15; `Fill` writes 9 into all three elements of
// `c`, whose sum is 27.

import Core library "io";

fn Fill[T: Core.Copy & Core.Destroy](s: Core.Slice(T), v: T) {
  var i: i64 = 0;
  while (i < s.Size()) {
    s[i] = v;
    ++i;
  }
}

fn Run() -> i32 {
  var a: array(i32, 3) = (1, 2, 3);
  let s: Core.Slice(i32) = Core.Slice(i32).FromArray(&a);
  s[1] = 20;
  let i: i64 = 2;
  s[i] = s[0] + s[1];
  Core.Print(a[0]);
  Core.Print(a[1]);
  Core.Print(a[2]);
  var b: Core.Buf(i32) = Core.Buf(i32).Make(3, 0);
  b[0] = 7;
  b.Set(1, 8);
  b[2] = b[0] + b[1];
  Core.Print(b[2]);
  var c: array(i32, 3) = (1, 2, 3);
  Fill(Core.Slice(i32).FromArray(&c), 9 as i32);
  Core.Print(c[0] + c[1] + c[2]);
  return 0;
}
