// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Functions: C++ interop — importing/calling C++ functions and methods
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   113
//   4
//   5
//
// Documentation-sync program (fork/designdocs/plan.md D-DD-5): the code after
// this comment block is the P08 code block of
// docs/design/interoperability/README.md, section "Constructors", byte for byte
// (fork/designdocs/check_samples.py, rulebook R27). Expected output derived by
// hand in fork/designdocs/plan.md section 4 (R16(d)). Runs on this fork's
// toolchain and on the upstream nightly. A PASS shows that the documented
// sample runs as documented; the design-docs bullet itself is arbitrated by
// document review.

import Core library "io";

import Cpp inline '''c++
inline int destroyed = 0;

struct Point {
  int x;
  int y;
  Point() : x(0), y(0) {}
  Point(int px, int py = 10) : x(px), y(py) {}
  ~Point() { ++destroyed; }
};

struct Meters {
  int n;
  Meters(int v) : n(v) {}
};

inline int Length(Meters m) { return m.n; }
''';

fn Make() -> i32 {
  // A constructor is called by its C++ name, as a member of its class; C++
  // overload resolution picks the constructor and fills default arguments.
  var a: Cpp.Point = Cpp.Point.Point(1, 2);
  var b: Cpp.Point = Cpp.Point.Point(3);
  // A `var` with no initializer runs the default constructor.
  var c: Cpp.Point;
  // Initializing from another object runs the copy constructor.
  var d: Cpp.Point = a;
  d.x = 100;
  return a.x + a.y + b.y + c.x + d.x;
}

fn Run() -> i32 {
  Core.Print(Make());
  // The four objects were destroyed when `Make` returned.
  Core.Print(Cpp.destroyed);
  // A non-`explicit` converting constructor is an implicit conversion.
  Core.Print(Cpp.Length(5));
  return 0;
}
