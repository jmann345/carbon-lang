// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Stdlib: Slices
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   3
//   7
//   12
//   33
//
// `Core.Buf(T)` (SL-1, fork/slices/plan.md §5.A.2; D-SL-6): heap storage
// over `malloc`/`free`, viewed and read through the slice API and mutated
// through `Buf.Set`. Shapes from core/prelude/types/buf.carbon (`Make(size,
// fill)`, `Size`, `Set`, `AsSlice`) and core/prelude/types/slice.carbon.
// `b` is passed to `Fill` by value without a copy: `Buf` has no `Copy` impl,
// a by-value parameter binding is not an initializer target (convert.cpp,
// `Convert` takes the `Done` path), and `Set` writes through the shared heap
// block — the third output line is the proof. `Destroy` frees at `Run`'s
// exit; a leak is not observable here, a double free would abort, so exit 0
// is the check. No program attaches to a heap-allocation bullet of its own
// (none exists in the gap-analysis table); the arbiter is a slice over heap
// storage, which is this bullet's.
//
// Hand-derived expectations (R16(d)): `RuntimeSeed(-17)` is 3, so `b` holds
// three 7s: `s.Size()` is 3 and `s[1]` is 7. `Fill(b, RuntimeSeed(-10))`
// writes 10 + i for i in 0..3, that is 10, 11, 12, so `s[2]` is 12 and the
// loop sums 10 + 11 + 12 = 33.

import Core library "io";

fn RuntimeSeed(x: i32) -> i32 { return x + 20; }

fn Fill(b: Core.Buf(i32), v: i32) {
  var i: i64 = 0;
  while (i < b.Size()) {
    b.Set(i, v + (i as i32));
    ++i;
  }
}

fn Run() -> i32 {
  var b: Core.Buf(i32) = Core.Buf(i32).Make(RuntimeSeed(-17) as i64, 7);
  let s: Core.Slice(i32) = b.AsSlice();
  Core.Print(s.Size() as i32);
  Core.Print(s[1]);
  Fill(b, RuntimeSeed(-10));
  Core.Print(s[2]);
  var total: i32 = 0;
  for (x: i32 in s) {
    total += x;
  }
  Core.Print(total);
  return 0;
}
