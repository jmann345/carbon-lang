// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Functions: C++ interop — exporting Carbon functions/methods to C++
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   30
//   9
//
// Reverse interop for free functions: Carbon functions are exported into the
// `Carbon::` namespace of an `inline Cpp` block, where C++ code calls them
// (including composing two Carbon calls); Carbon then calls the C++ wrapper
// back through `Cpp.` so the round trip is observable at runtime. Shapes
// verbatim from toolchain/lower/testdata/interop/cpp/function/export/
// function.carbon (single_file split: `import Cpp;` + `fn F() {}` +
// `inline Cpp ''' inline void G1() { Carbon::F(); } '''` + `fn H() {
// Cpp.G2(); }`) and toolchain/check/testdata/interop/cpp/function/export/
// function.carbon (return_int/args splits: C++ passing arguments to and
// returning the result of a Carbon function).

import Core library "io";
import Cpp;

fn Add(a: i32, b: i32) -> i32 {
  return a + b;
}

fn Triple(n: i32) -> i32 {
  return 3 * n;
}

inline Cpp '''
inline int CombineInCpp() {
  return Carbon::Add(Carbon::Triple(8), 6);
}

inline int TripleOf3InCpp() {
  return Carbon::Triple(3);
}
''';

fn Run() -> i32 {
  Core.Print(Cpp.CombineInCpp());
  Core.Print(Cpp.TripleOf3InCpp());
  return 0;
}
