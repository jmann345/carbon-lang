// CONFORMANCE-BULLET: Generics: Checked generics
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   40
//
// A user-defined interface, an impl of it for i32, and a generic function
// that is checked against the interface and calls through the witness with
// the compound member-access syntax. All shapes verbatim from
// examples/advent2024/sort.carbon (interface Ordered; impl i32 as Ordered;
// `fn Partition[T: Core.Copy & Core.Destroy & Ordered]...` with
// `a[from].(Ordered.LessOrEquivalent)(pivot)` witness calls and
// `let pivot: T = ...` under a Core.Copy constraint).

import Core library "io";

interface Scalable {
  fn Scale(self, factor: i32) -> Self;
}

impl i32 as Scalable {
  fn Scale(self, factor: i32) -> Self { return self * factor; }
}

fn ScaleTwice[T: Core.Copy & Core.Destroy & Scalable](x: T, factor: i32) -> T {
  let once: T = x.(Scalable.Scale)(factor);
  return once.(Scalable.Scale)(factor);
}

fn Run() -> i32 {
  let v: i32 = 10;
  Core.Print(ScaleTwice(v, 2));
  return 0;
}
