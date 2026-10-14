// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Stdlib: Optional
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   2
//   0
//   3
//   0
//   1
//   0
//   1
//   0
//   1
//   3
//   0
//
// The ownership rule of fork design F-015 (docs/design/optional.md) on the
// paths that optional_destroys_value.carbon does not take, with a C++17
// `std::optional` oracle (optional_destroy_diff.diff.cpp): an Optional owns the
// value it holds, as `std::optional` does, so live-object counts agree at every
// point printed. `Tracked` counts its live objects through a pointer: `Make`
// and `Copy` add one, `Destroy` removes one, and two of them are equal when
// their `id`s are. Each helper prints the count while its locals are alive, and
// the caller prints it again after the helper returns. No count is printed
// while a temporary is alive: the design leaves the lifetime of temporaries
// open (docs/design/values.md, "Temporary materialization"), and the toolchain
// keeps one made in a `let` initializer, such as a `Get()` copy, to the end of
// the scope, where C++ destroys it at the end of its full-expression (M-23 of
// fork/optional2/plan.md). Expected, from F-015's rules (`Some(v)` stores
// one copy of `v`, copying an Optional copies its value, destroying a non-empty
// Optional destroys its value): an Optional in a class field is destroyed with
// the object (2, then 0); an Optional of an Optional built from a named inner
// value holds a copy of that value's copy (3, then 0); a checked generic's
// local `Core.Optional(T)` is destroyed when the generic returns (1, then 0);
// an Optional returned by value keeps the one copy `Some` made (1, then 0); and
// `a == b` on two non-empty values compares equal (1) and leaves only the three
// objects it had (3, then 0).

import Core library "io";

class Tracked {
  var id: i32;
  var live: i32*;
  impl as Core.Copy {
    fn Op(self) -> Self {
      ++*self.live;
      return {.id = self.id, .live = self.live};
    }
  }
  impl as Core.Destroy {
    fn Op(ref self) {
      --*self.live;
    }
  }
}

impl Tracked as Core.EqWith(Tracked) {
  fn Equal(self, other: Tracked) -> bool { return self.id == other.id; }
  fn NotEqual(self, other: Tracked) -> bool { return self.id != other.id; }
}

fn Make(live: i32*) -> Tracked {
  ++*live;
  return {.id = 1, .live = live};
}

fn B(b: bool) -> i32 { return if b then 1 else 0; }

class Box {
  var o: Core.Optional(Tracked);
}

fn HoldField(live: i32*) {
  var t: Tracked = Make(live);
  var unused b: Box = {.o = Core.Optional(Tracked).Some(t)};
  Core.Print(*live);
}

fn HoldNested(live: i32*) {
  var t: Tracked = Make(live);
  var inner: Core.Optional(Tracked) = Core.Optional(Tracked).Some(t);
  var unused outer: Core.Optional(Core.Optional(Tracked)) =
      Core.Optional(Core.Optional(Tracked)).Some(inner);
  Core.Print(*live);
}

fn HoldGeneric[T: Core.Copy & Core.Destroy](a: T) {
  var unused o: Core.Optional(T) = Core.Optional(T).Some(a);
}

fn CallGeneric(live: i32*) {
  var t: Tracked = Make(live);
  HoldGeneric(t);
  Core.Print(*live);
}

fn MakeSome(live: i32*) -> Core.Optional(Tracked) {
  var t: Tracked = Make(live);
  return Core.Optional(Tracked).Some(t);
}

fn HoldReturned(live: i32*) {
  var unused o: Core.Optional(Tracked) = MakeSome(live);
  Core.Print(*live);
}

fn HoldCompared(live: i32*) {
  var t: Tracked = Make(live);
  var a: Core.Optional(Tracked) = Core.Optional(Tracked).Some(t);
  var b: Core.Optional(Tracked) = Core.Optional(Tracked).Some(t);
  Core.Print(B(a == b));
  Core.Print(*live);
}

fn Run() -> i32 {
  var in_field: i32 = 0;
  HoldField(&in_field);
  Core.Print(in_field);
  var in_nested: i32 = 0;
  HoldNested(&in_nested);
  Core.Print(in_nested);
  var in_generic: i32 = 0;
  CallGeneric(&in_generic);
  Core.Print(in_generic);
  var in_returned: i32 = 0;
  HoldReturned(&in_returned);
  Core.Print(in_returned);
  var in_compared: i32 = 0;
  HoldCompared(&in_compared);
  Core.Print(in_compared);
  return 0;
}
