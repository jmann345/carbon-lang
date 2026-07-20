// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Type system: Virtual dispatch
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   0
//   3
//   4
//
// Virtual dispatch through a base-class pointer: two derived classes override
// a virtual method and the call site sees the dynamic type. Shapes verbatim
// from toolchain/lower/testdata/class/virtual.carbon (`virtual fn`/
// `override fn`, `{.base = {}}` construction, calls through a base pointer
// `v->Fn()`) and derived-to-base pointer conversion from
// toolchain/lower/testdata/class/base.carbon.

import Core library "io";

base class Shape {
  virtual fn Sides(self) -> i32 { return 0; }
}

class Triangle {
  extend base: Shape;
  override fn Sides(self) -> i32 { return 3; }
}

class Quad {
  extend base: Shape;
  override fn Sides(self) -> i32 { return 4; }
}

fn PrintSides(s: Shape*) {
  Core.Print(s->Sides());
}

fn Run() -> i32 {
  var base_shape: Shape = {};
  var tri: Triangle = {.base = {}};
  var quad: Quad = {.base = {}};
  PrintSides(&base_shape);
  PrintSides(&tri);
  PrintSides(&quad);
  return 0;
}
