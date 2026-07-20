// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Functions: C++ interop — importing C++ overload sets
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   1
//   1
//   2
//   1
//   20
//
// Literal-driven overload resolution over imported C++ overload sets: an
// unsuffixed Carbon integer literal takes the smallest signed C++ type it
// fits (int up to i32-max, then long), a negative literal picks `int` over
// `long`, and a float literal picks `double` over `float`. All cases are
// taken from check/testdata/interop/cpp/function/import/overloads.carbon:
// import_int_literal (`Cpp.foo(2147483647)` -> int, `Cpp.foo(2147483648)`
// -> long), import_negative_int_literal (`Cpp.foo(-1)` selects
// `foo(int)` from a {long,int} set), and import_floating_point_literal
// (`Cpp.foo(1.0)` -> double from a {float,double} set).

import Core library "io";
import Cpp inline '''c++

inline auto pick(int a) -> int { return 1; }
inline auto pick(long a) -> int { return 2; }

inline auto fpick(float a) -> int { return 10; }
inline auto fpick(double a) -> int { return 20; }

''';

fn Run() -> i32 {
  Core.Print(Cpp.pick(100));
  Core.Print(Cpp.pick(2147483647));
  Core.Print(Cpp.pick(2147483648));
  Core.Print(Cpp.pick(-1));
  Core.Print(Cpp.fpick(1.5));
  return 0;
}
