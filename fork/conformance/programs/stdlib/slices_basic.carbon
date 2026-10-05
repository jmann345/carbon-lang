// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Stdlib: Slices
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   2
//   3
//   30
//   32
//
// `Core.Slice(T)` (SL-1, fork/slices/plan.md §5.A.1; D-SL-1..4, 7): a
// non-owning view over the middle of a stack array, read through the view,
// mutated through the array, and iterated. Shapes from
// core/prelude/types/slice.carbon (`FromArray(&a)`, `Subslice`, `Size`, the
// blanket `IndexWith` impl) and core/prelude/iterate.carbon (the
// `Slice(T) as Iterate` impl driving `for`). Un-SKIPped from the
// write-tests-first stub: its strawman `Core.Slice(i32).Make(&a, 1, 3)`
// became `FromArray(&a).Subslice(1, 3)` (views are formed from a POINTER to
// the array, D-SL-2), and two lines were added to prove aliasing and
// iteration.
//
// Hand-derived expectations (R16(d)): `a` is {1, 2, 3, 4}; `s` views
// a[1..3) = {2, 3}, so `s.Size()` is 2 and `s[1]` is `a[2]` = 3. Then
// `a[2] = RuntimeSeed(10)` = 30, and `s[1]` read through the view is 30 (no
// copy was made). The loop sums 2 + 30 = 32.

import Core library "io";

fn RuntimeSeed(x: i32) -> i32 { return x + 20; }

fn Run() -> i32 {
  var a: array(i32, 4) = (1, 2, 3, 4);
  // A view of a[1..3): {2, 3}.
  let s: Core.Slice(i32) = Core.Slice(i32).FromArray(&a).Subslice(1, 3);
  Core.Print(s.Size() as i32);
  Core.Print(s[1]);
  // Writes to the array are visible through the view: no copy.
  a[2] = RuntimeSeed(10);
  Core.Print(s[1]);
  var total: i32 = 0;
  for (x: i32 in s) {
    total += x;
  }
  Core.Print(total);
  return 0;
}
