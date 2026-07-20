// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Project: toolchain implements most 0.1 language features incl. C++ interop without undermining evaluation
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   interop total 25
//   50
//
// Working slice of this PARTIAL bullet, "incl. C++ interop" half: C++ interop
// composed with Carbon language features in one program. A C++ struct is
// constructed from Carbon via its C++ constructor and a const member function
// is called on it (shapes verbatim from
// interop/cpp_type_import_class_enum.carbon, itself from
// check/testdata/interop/cpp/class/import/constructor.carbon); the result
// flows through a Carbon checked-generic function (binding shape from
// generics/checked_generics.carbon / examples/advent2024/sort.carbon) and
// back into a C++ function that streams to std::cout (inline-import block
// with a std header, verbatim pattern from
// project/dropin_clang_cpp_toolchain.carbon and
// toolchain/install/install_test.py's run_cpp_test), while the Carbon side
// prints via Core.Print. Round trip Carbon -> C++ ctor/method -> Carbon
// generic -> C++ iostream proves the interop boundary is crossed in both
// directions without undermining evaluation of either language's half.

import Core library "io";

import Cpp inline '''
#include <iostream>

struct Vec2 {
  int x;
  int y;
  Vec2(int px, int py) : x(px), y(py) {}
  int Norm2() const { return x * x + y * y; }
};

inline void Announce(int n) {
  std::cout << "interop total " << n << std::endl;
}
''';

fn Identity[T: Core.Copy & Core.Destroy](x: T) -> T {
  return x;
}

fn Run() -> i32 {
  var v: Cpp.Vec2 = Cpp.Vec2.Vec2(3, 4);
  let norm: i32 = v.Norm2();
  Cpp.Announce(Identity(norm));
  Core.Print(norm * 2);
  return 0;
}
