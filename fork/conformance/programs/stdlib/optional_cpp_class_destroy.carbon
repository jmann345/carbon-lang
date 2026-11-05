// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Stdlib: Optional
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   1
//   2
//   0
//   1
//   1
//   0
//
// A `Core.Optional` of an imported C++ class owns its value (fork design
// F-015, docs/design/optional.md): `Some(r)` stores one copy, made by the
// class's copy constructor (its `Core.Copy`), and destroying a non-empty
// Optional runs the class's C++ destructor on that copy (its `Core.Destroy`;
// toolchain/check/cpp/impl_lookup.cpp, `BuildCopyWitness` and
// `BuildCppDestroyWitness`). `Res` counts its live objects in `live`.
//
// Hand-derived expectation (R16(d)): `MakeRes` returns the prvalue `Res(x)`,
// which initializes `r` with no copy (C++17 guaranteed copy elision), so
// `Hold` prints 1, then 2 once `Some(r)` holds its copy; when `Hold` returns,
// the Optional destroys its copy and `r` is destroyed, so `Run` prints 0.
// `HoldNone` prints 1 for `r`, and 1 again beside an empty Optional, which
// holds nothing; when it returns only `r` is destroyed, so `Run` prints 0.

import Core library "io";

import Cpp inline '''c++
inline int live = 0;
struct Res {
  int v;
  Res(int x) : v(x) { ++live; }
  Res(const Res& other) : v(other.v) { ++live; }
  ~Res() { --live; }
};
inline int Live() { return live; }
inline Res MakeRes(int x) { return Res(x); }
''';

fn Hold() {
  var r: Cpp.Res = Cpp.MakeRes(3);
  Core.Print(Cpp.Live());
  var unused o: Core.Optional(Cpp.Res) = Core.Optional(Cpp.Res).Some(r);
  Core.Print(Cpp.Live());
}

fn HoldNone() {
  var unused r: Cpp.Res = Cpp.MakeRes(4);
  Core.Print(Cpp.Live());
  var unused o: Core.Optional(Cpp.Res) = Core.Optional(Cpp.Res).None();
  Core.Print(Cpp.Live());
}

fn Run() -> i32 {
  Hold();
  Core.Print(Cpp.Live());
  HoldNone();
  Core.Print(Cpp.Live());
  return 0;
}
