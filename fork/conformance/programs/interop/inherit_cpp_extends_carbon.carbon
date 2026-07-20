// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Type system: C++ interop — bi-directional inheritance, hierarchy roots, abstract/final/virtual mapping
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   19
//   11
//
// C++-extends-Carbon direction: inline C++ derives a struct from an exported
// Carbon `base class` hierarchy root, instantiates the derived object in C++,
// calls the inherited Carbon methods (class function and by-value-self
// method) through the derived class, and converts derived-to-base to a
// `Carbon::Widget*`. Carbon observes the results via imported C++ functions.
// Shapes verbatim from toolchain/check/testdata/interop/cpp/class/export/
// base.carbon (name_lookup: C++ deriving from and calling into exported
// Carbon classes) and export/method.carbon (`Carbon::C c; c.M();`).

import Core library "io";
import Cpp;

base class Widget {
  fn Kind() -> i32 { return 7; }
  fn Tag(unused self) -> i32 { return 11; }
}

inline Cpp '''
struct Button : Carbon::Widget {
  auto pressed() -> int { return this->Tag() + 1; }
};

auto UseButton() -> int {
  Button b;
  return b.pressed() + Button::Kind();
}

auto TagViaBase(Carbon::Widget* w) -> int { return w->Tag(); }

auto UseButtonViaBase() -> int {
  Button b;
  return TagViaBase(&b);
}
''';

fn Run() -> i32 {
  Core.Print(Cpp.UseButton());
  Core.Print(Cpp.UseButtonViaBase());
  return 0;
}
