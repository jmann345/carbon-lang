// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Type system: Unions (un-discriminated) + C++ union mapping
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   42
//   4
//   1
//   5
//   5
//
// Native `union` end to end (fork/unions/plan.md UN-1, W-009; design
// docs/design/unions.md, decision F-007): unformed-then-assign (F-007d),
// designated single-field initialization (F-007d), whole-union copy of all
// `size(U)` bytes, and a method reading the low half of an `i64` write.
// Runtime inputs go through `RuntimeSeed` so nothing constant-folds (R16d).
// EXPECT values are hand-derived from the design's byte-reinterpretation rule
// on little-endian targets: 22 + 20 = 42; the bytes of 0x01020304 at offsets
// 0 and 3 are 4 and 1; after copying `v` into `w` and writing byte 0 of `w`
// to 9, `w.word - v.word` is 0x01020309 - 0x01020304 = 5 (a partial copy
// would not give 5); the low 32 bits of the i64 value 5 are 5.
//
// Un-SKIP disclosure (R6/F8d template): the stub's second half — the imported
// `Cpp.CppIntBytes` union — moves to the UN-2 programs (fork/unions/plan.md
// §5.B), where the importer's field mapping is verified.

import Core library "io";

union IntOrBytes {
  var word: i32;
  var bytes: array(i8, 4);
}

union Wide {
  var lo: i32;
  var both: i64;
  fn Low(self) -> i32 { return self.lo; }
}

fn RuntimeSeed(x: i32) -> i32 { return x + 20; }

fn Run() -> i32 {
  // Unformed-then-assign (F-007d).
  var u: IntOrBytes;
  u.word = RuntimeSeed(22);
  Core.Print(u.word);
  // Designated single-field init (F-007d); word = 0x01020304.
  var v: IntOrBytes = {.word = RuntimeSeed(16909040)};
  Core.Print(v.bytes[0] as i32);
  Core.Print(v.bytes[3] as i32);
  // Whole-union copy is all size(U) bytes (unions.md:271-276).
  var w: IntOrBytes = v;
  w.bytes[0] = 9;
  Core.Print(w.word - v.word);
  // Method; i64 write, i32 read of the low half.
  var x: Wide;
  x.both = RuntimeSeed(-15) as i64;
  Core.Print(x.Low());
  return 0;
}
