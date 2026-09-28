// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Type system: Unions (un-discriminated) + C++ union mapping
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   42
//   9
//   7
//   12
//   13
//
// A Carbon `union` exported to C++ (fork/unions/plan.md UN-2, W-015; design
// docs/design/unions.md, "Exporting Carbon unions to C++" and "Round-trip
// guarantee"): C++ sees a genuine union with Carbon's layout, constructs one,
// writes its fields, calls the exported method, and values cross the boundary
// by pointer and by value in both directions. The `static_assert`s are the
// compile-time layout arbiter (D-UN-8): they run in the embedded Clang while
// this program compiles, so a wrong tag kind fails `__is_union` and a layout
// disagreement fails `sizeof`/`alignof` as a COMPILE-FAIL of this program.
// Runtime inputs go through `RuntimeSeed` so nothing constant-folds (R16d).
// EXPECT values are hand-derived on the little-endian V-1 targets: C++ sets
// `lo` = 42 and the exported method returns it; C++ writes `both` =
// (7 << 32) | 9 (hi = 7, lo = 9), and Carbon reads the low half through
// `lo` (9, by the byte-reinterpretation rule) and the high half
// arithmetically (7); C++ returns a `Wide` by value with `lo` = 12; Carbon
// passes it by value into `SumLo`, which returns `lo` + 1 = 13.

import Core library "io";
import Cpp;

union Wide {
  var lo: i32;
  var both: i64;
  fn Low(self) -> i32 { return self.lo; }
}

inline Cpp '''
static_assert(__is_union(Carbon::Wide), "kind");
static_assert(sizeof(Carbon::Wide) == 8 && alignof(Carbon::Wide) == 8,
              "layout");

int RoundTrip(int v) {
  Carbon::Wide w;
  w.lo = v;
  return w.Low();
}

void WriteBoth(Carbon::Wide* w, int hi, int lo) {
  w->both = (static_cast<long long>(hi) << 32) | static_cast<unsigned>(lo);
}

Carbon::Wide MakeWide(int v) {
  Carbon::Wide w;
  w.lo = v;
  return w;
}

int SumLo(Carbon::Wide w) { return w.lo + 1; }
''';

fn RuntimeSeed(x: i32) -> i32 { return x + 20; }

fn Run() -> i32 {
  // C++ constructs the exported union, writes a field and calls the method.
  Core.Print(Cpp.RoundTrip(RuntimeSeed(22)));
  // C++ writes the 64-bit member through a pointer; Carbon reads the low half
  // through `lo` and the high half arithmetically.
  var w: Wide;
  Cpp.WriteBoth(&w, RuntimeSeed(-13), RuntimeSeed(-11));
  Core.Print(w.lo);
  Core.Print((w.both / 4294967296) as i32);
  // C++ returns a Carbon union by value.
  var m: Wide = Cpp.MakeWide(RuntimeSeed(-8));
  Core.Print(m.lo);
  // Carbon passes it by value into C++.
  Core.Print(Cpp.SumLo(m));
  return 0;
}
