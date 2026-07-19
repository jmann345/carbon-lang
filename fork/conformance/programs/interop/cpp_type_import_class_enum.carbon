// CONFORMANCE-BULLET: Type system: C++ interop — importing C++ types / exporting Carbon types
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   25
//   14
//   2
//   7
//
// The import direction of the bullet: C++ types used as first-class Carbon
// types. A C++ struct is constructed from Carbon via its C++ constructor
// (`Cpp.Vec2.Vec2(3, 4)` — form verbatim from check/testdata/interop/cpp/
// class/import/constructor.carbon `Cpp.C.C()`), a const member function is
// called, fields are read and written, a scoped `enum class` constant is
// named and converted to its underlying type via `as` (check/testdata/
// interop/cpp/enum/scoped.carbon + convert.carbon: conversion is to the
// exact underlying type, here `int` -> i32), and an imported C++ class
// template is instantiated on a *Carbon* class type (`Cpp.Box(Pt)`), which
// works for concrete types on this toolchain (the audit's "cannot
// instantiate on Carbon class types" only reproduces for symbolic generic
// parameters — see cpp_template_on_carbon_generic.carbon).

import Core library "io";
import Cpp inline '''

struct Vec2 {
  int x;
  int y;
  Vec2(int px, int py) : x(px), y(py) {}
  int Norm2() const { return x * x + y * y; }
};

enum class Color : int { kRed, kGreen, kBlue };

template <typename T> struct Box {
  T value;
};

''';

class Pt {
  var x: i32;
}

fn Run() -> i32 {
  var v: Cpp.Vec2 = Cpp.Vec2.Vec2(3, 4);
  Core.Print(v.Norm2());
  v.x = 10;
  Core.Print(v.x + v.y);
  Core.Print(Cpp.Color.kBlue as i32);
  var b: Cpp.Box(Pt);
  b.value.x = 7;
  Core.Print(b.value.x);
  return 0;
}
