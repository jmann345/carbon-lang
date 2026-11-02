// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: C++ interop — importing C++ templates, instantiating on Carbon types
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   42
//   10
//   9
//   8
//   2
//   12
//
// Imported C++ function templates called with a symbolic Carbon type argument
// in a checked generic and in a template (CT-1, fork/cpp-templates/plan.md):
// the call is resolved by Clang for each specific, once T is known.
// DoubleIt(21) is Twice<int>(21) = 21 + 21 = 42; DoubleExplicit(5) names the
// template argument, Twice<int>(5) = 10; Larger(3, 9) is Max<int>(3, 9) = 9;
// Size(i64) and Size(i16) are SizeOfFn<long>() = 8 and SizeOfFn<short>() = 2
// (x86-64 Linux, where i64 maps to long and i16 to short); TwiceTemplate(6),
// with a template binding, is Twice<int>(6) = 12.

import Core library "io";
import Cpp inline '''
template<typename T> T Twice(T x) { return x + x; }
template<typename T> T Max(T a, T b) { return a < b ? b : a; }
template<typename T> int SizeOfFn() { return sizeof(T); }
''';

fn DoubleIt[T: type](v: T) -> T {
  return Cpp.Twice(v);
}

fn DoubleExplicit[T: type](v: T) -> T {
  return Cpp.Twice(T, v);
}

fn Larger[T: type](a: T, b: T) -> T {
  return Cpp.Max(a, b);
}

fn Size[T: type](unused v: T) -> i32 {
  return Cpp.SizeOfFn(T);
}

fn TwiceTemplate[template T: type](v: T) -> T {
  return Cpp.Twice(v);
}

fn Run() -> i32 {
  Core.Print(DoubleIt(21 as i32));
  Core.Print(DoubleExplicit(5 as i32));
  Core.Print(Larger(3 as i32, 9 as i32));
  Core.Print(Size(1 as i64));
  Core.Print(Size(1 as i16));
  Core.Print(TwiceTemplate(6 as i32));
  return 0;
}
