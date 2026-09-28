// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Type system: Unions (un-discriminated) + C++ union mapping
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   42
//   5
//   7
//   5
//   11
//
// C++ unions imported into Carbon (fork/unions/plan.md UN-2, W-015; design
// docs/design/unions.md, "Importing C++ unions"): an imported union is a
// Carbon union, so it is constructed by designated single-field
// initialization exactly like a native one, its fields are read under
// Carbon's byte-reinterpretation rule, an anonymous-union member is flattened
// into the enclosing struct, and values cross the boundary by pointer and by
// value in both directions (the "Round-trip guarantee"). Runtime inputs go
// through `RuntimeSeed` so nothing constant-folds (R16d). EXPECT values are
// hand-derived on the little-endian V-1 targets: `{.a = 42}` read back through
// the other `int` member `b` is 42 (the same four bytes); C++ writes `a` = 5
// through a pointer and Carbon reads 5; `MakeTagged(7)` sets the anonymous
// union's `i` and Carbon reads 7 through the flattened member; Carbon passes
// `u` by value to `ReadA`, which reads `a` = 5; `MakePair(11)` returns by value
// with `a` = 11, read through `b` as 11. The `static_assert` is C++'s own
// check that the union has the layout the importer copies.
//
// This is the `Cpp.CppIntBytes` half of the original union_basic stub,
// relocated here per its un-SKIP disclosure.

import Core library "io";

import Cpp inline '''c++
union Pair {
  int a;
  int b;
  int* p;
};

struct Tagged {
  int kind;
  union {
    int i;
    float f;
  };
};

inline void WriteA(Pair* u, int v) { u->a = v; }

inline Tagged MakeTagged(int v) {
  Tagged t;
  t.kind = 1;
  t.i = v;
  return t;
}

inline int ReadA(Pair u) { return u.a; }

inline Pair MakePair(int v) {
  Pair p;
  p.a = v;
  return p;
}

static_assert(sizeof(Pair) == 8, "layout");
''';

fn RuntimeSeed(x: i32) -> i32 { return x + 20; }

fn Run() -> i32 {
  // Designated init of an imported union (the UN-2 deliverable), read back
  // through the other `int` member: defined by Carbon's read rule.
  var u: Cpp.Pair = {.a = RuntimeSeed(22)};
  Core.Print(u.b);
  // C++ writes through a pointer, Carbon reads.
  Cpp.WriteA(&u, RuntimeSeed(-15));
  Core.Print(u.a);
  // An anonymous union member, flattened on import.
  var t: Cpp.Tagged = Cpp.MakeTagged(RuntimeSeed(-13));
  Core.Print(t.i);
  // Carbon passes the union by value into C++.
  Core.Print(Cpp.ReadA(u));
  // C++ returns a union by value; Carbon reads the other member.
  var m: Cpp.Pair = Cpp.MakePair(RuntimeSeed(-9));
  Core.Print(m.b);
  return 0;
}
