// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Stdlib C++ interop: transparent fundamental-type mapping
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   42
//   42
//   123
//
// The width-ambiguous C++ integer types map through the Core.CppCompat
// adapters (core/prelude/types/cpp/int.carbon): `long long` is
// Core.CppCompat.LongLong64 (adapts i64) and `unsigned long long` is
// Core.CppCompat.ULongLong64 (adapts u64); the adapter values convert to
// their adapted Carbon type with `as`. On this LP64 Linux target, C++ `long`
// is 64-bit and maps directly to i64 (Core.CppCompat.Long32 is the LLP64
// adapter and does not apply here). Syntax evidence:
// check/testdata/interop/cpp/primitive_types/long_and_long_long.lp64.carbon
// (`let x: Cpp.long_long = 1;` binding as Core.CppCompat.LongLong64,
// `cpp_long_long as i64`, and i64 <-> Cpp.long directly).

import Core library "io";

import Cpp inline '''
auto TripleLL(long long x) -> long long { return x * 3; }
auto SumULL(unsigned long long a, unsigned long long b) -> unsigned long long { return a + b; }
auto AddOneLong(long x) -> long { return x + 1; }
''';

fn Run() -> i32 {
  // Cpp.long_long names the Core.CppCompat.LongLong64 adapter; an integer
  // literal initializes it and it passes to a C++ `long long` parameter
  // unchanged. The result converts to i64 with `as`.
  let x: Cpp.long_long = 14;
  let tripled: Core.CppCompat.LongLong64 = Cpp.TripleLL(x);
  Core.Print((tripled as i64) as i32);

  // unsigned long long -> Core.CppCompat.ULongLong64, which adapts u64.
  let s: Core.CppCompat.ULongLong64 = Cpp.SumULL(40, 2);
  Core.Print((s as u64) as i32);

  // On LP64, C++ `long` maps directly to i64: an i64 argument passes with no
  // adapter and the `long` return binds straight back to i64.
  let l: i64 = 122;
  let l2: i64 = Cpp.AddOneLong(l);
  Core.Print(l2 as i32);

  return 0;
}
