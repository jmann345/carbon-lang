// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Type system: Unions (un-discriminated) + C++ union mapping
// EXPECT-EXIT: 0
//
// Differential pair (DIFF-1: no EXPECT-STDOUT, the C++ oracle in
// union_pun_diff.diff.cpp arbitrates). The Carbon side type-puns through a
// native `union` (docs/design/unions.md, "Reads": a read is defined byte
// reinterpretation of the first `size(T)` bytes): all four bytes of a seeded
// `i32` written through `word` are read through `bytes`, and a seeded `i64`
// written through `both` is split as `lo` and `halves[1]`. The C++ oracle
// holds the same values in `int`/`long long` and reads them back with
// `std::memcpy` into the read types (defined C++; it must not itself lean on
// union-member UB). `halves[1]` is the layout arbiter of this program
// (fork/unions/plan.md §5): it is wrong unless `both` and `halves` overlap at
// offset 0 in an 8-byte region. Runtime inputs go through `RuntimeSeed` so
// nothing constant-folds (R16d). Independent derivation: 4 3 2 1, then 9 and
// 7.

import Core library "io";

union IntOrBytes {
  var word: i32;
  var bytes: array(i8, 4);
}

union Wide {
  var lo: i32;
  var both: i64;
  var halves: array(i32, 2);
}

fn RuntimeSeed(x: i32) -> i32 { return x + 20; }

fn Run() -> i32 {
  // word = 0x01020304.
  var v: IntOrBytes = {.word = RuntimeSeed(16909040)};
  Core.Print(v.bytes[0] as i32);
  Core.Print(v.bytes[1] as i32);
  Core.Print(v.bytes[2] as i32);
  Core.Print(v.bytes[3] as i32);
  // both = 7 << 32 | 9.
  var w: Wide;
  w.both = (RuntimeSeed(-13) as i64) * 4294967296 + (RuntimeSeed(-11) as i64);
  Core.Print(w.lo);
  Core.Print(w.halves[1]);
  return 0;
}
