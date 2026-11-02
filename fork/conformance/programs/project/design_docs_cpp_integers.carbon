// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Stdlib C++ interop: transparent fundamental-type mapping
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   9
//   20
//   15
//
// Documentation-sync program (fork/designdocs/plan.md D-DD-5): the code after
// this comment block is the P12 code block of
// docs/design/interoperability/README.md, section "Integers", byte for byte
// (fork/designdocs/check_samples.py, rulebook R27). Expected output derived by
// hand in fork/designdocs/plan.md section 4 (R16(d)). Runs on this fork's
// toolchain and on the upstream nightly. A PASS shows that the documented
// sample runs as documented; the design-docs bullet itself is arbitrated by
// document review.

import Core library "io";

import Cpp inline '''c++
#include <cstddef>
#include <cstdint>
inline int NextInt(int x) { return x + 1; }
inline long NextLong(long x) { return x + 1; }
inline long long NextLongLong(long long x) { return x + 1; }
inline unsigned NextUnsigned(unsigned x) { return x + 1; }
inline short NextShort(short x) { return x + 1; }
inline std::int64_t NextInt64(std::int64_t x) { return x + 1; }
inline std::size_t NextSize(std::size_t x) { return x + 1; }
inline unsigned char NextByte(unsigned char x) { return x + 1; }
''';

fn Run() -> i32 {
  // `int`, `short`, `unsigned`, and the fixed-width types are Carbon's
  // integer types; on this target `long` is `i64` and `size_t` is `u64`.
  let a: i32 = Cpp.NextInt(1);
  let b: i16 = Cpp.NextShort(2);
  let c: u32 = Cpp.NextUnsigned(3);
  let d: i64 = Cpp.NextLong(4);
  let e: i64 = Cpp.NextInt64(5);
  let f: u64 = Cpp.NextSize(6);
  let g: u8 = Cpp.NextByte(7);
  // `long long` is the distinct type `Cpp.long_long`; `as` converts it.
  let h: i64 = Cpp.NextLongLong(8) as i64;
  Core.Print(a + (b as i32) + (c as i32));
  Core.Print((d + e + h) as i32);
  Core.Print((f as i32) + (g as i32));
  return 0;
}
