// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: C++ interop — importing C++ templates, instantiating on Carbon types
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   5
//   12
//   2
//
// One checked generic naming Cpp.Loud(T), instantiated twice in one program,
// on i32 and on the exported Carbon class Point: each specific forms its own
// specialization, Loud<int> and Loud<Point>, with its own destructor (CT-1,
// fork/cpp-templates/plan.md). Keep(5) returns 5; Keep of {.x = 1, .y = 2}
// returns a Point printed as 1 * 10 + 2 = 12; each call destroys its local
// Loud once, so the C++ counter reads 2.

import Core library "io";
import Cpp inline '''
inline int destroyed = 0;
template<typename T> struct Loud {
  T value;
  ~Loud() { ++destroyed; }
};
inline int Destroyed() { return destroyed; }
''';

class Point {
  var x: i32;
  var y: i32;
  impl as Core.Copy {
    fn Op(self) -> Self { return {.x = self.x, .y = self.y}; }
  }
}

fn Keep[T: type](v: T) -> T {
  var l: Cpp.Loud(T);
  l.value = v;
  return l.value;
}

fn Run() -> i32 {
  Core.Print(Keep(5 as i32));
  let p: Point = Keep({.x = 1, .y = 2} as Point);
  Core.Print(p.x * 10 + p.y);
  Core.Print(Cpp.Destroyed());
  return 0;
}
