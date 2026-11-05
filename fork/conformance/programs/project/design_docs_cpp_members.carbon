// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Type system: C++ interop — importing C++ types / exporting Carbon types
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   9
//   36
//   4
//   6
//   5
//
// Documentation-sync program (fork/designdocs/plan.md D-DD-5): the code after
// this comment block is the P10 code block of
// docs/design/interoperability/README.md, section "Accessing C++ classes,
// structs, and members", byte for byte (fork/designdocs/check_samples.py,
// rulebook R27). Expected output derived by hand in fork/designdocs/plan.md
// section 4 (R16(d)). Runs on this fork's toolchain and on the upstream
// nightly. A PASS shows that the documented sample runs as documented; the
// design-docs bullet itself is arbitrated by document review.

import Core library "io";

import Cpp inline '''c++
namespace geo {
class Rect {
 public:
  Rect(int w, int h) : w_(w), h_(h) {}
  static Rect Square(int s) { return Rect(s, s); }
  int Area() const { return w_ * h_; }
  void Scale(int k) { w_ *= k; h_ *= k; }
  struct Corner {
    int x;
    int y;
  };
  int tag = 7;

 private:
  int w_;
  int h_;
};

struct Shape {
  int id = 5;
  int Id() const { return id; }
};
struct Circle : Shape {
  int radius = 1;
};
inline int IdOf(const Shape& s) { return s.id; }
}  // namespace geo
''';

fn Run() -> i32 {
  // Namespaces, classes, and static member functions are members of `Cpp`.
  var r: Cpp.geo.Rect = Cpp.geo.Rect.Square(3);
  // Member functions and public fields use member access.
  Core.Print(r.Area());
  r.Scale(2);
  r.tag = r.Area();
  Core.Print(r.tag);
  // A nested class is a member of its enclosing class.
  var corner: Cpp.geo.Rect.Corner = Cpp.geo.Rect.Corner.Corner();
  corner.x = 4;
  Core.Print(corner.x);
  // Base-class members are found through a derived object, and a derived
  // object converts to a reference to its base.
  let c: Cpp.geo.Circle = Cpp.geo.Circle.Circle();
  Core.Print(c.Id() + c.radius);
  Core.Print(Cpp.geo.IdOf(c));
  return 0;
}
