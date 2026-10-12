// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: Template-style structural conformance to nominal constraints
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   7
//   0
//
// The interop payoff of structural conformance (F-010 / SC-1, D-SC-11): a
// C++ class with no Carbon declarations at all satisfies a Carbon
// `template constraint` through its imported method. Imported C++ methods
// take `ref self` (check/cpp/import.cpp: PassingMode::ByRef default; a
// non-`const` method's object parameter is `Self&`), so the requirement is
// spelled `fn Get(ref self) -> i32` and the template takes a pointer,
// calling through `->` on the dependent pointee. Construction shape from
// interop/cpp_type_import_class_enum.carbon (`Cpp.Vec2.Vec2(3, 4)`). The
// imported method name is a one-candidate C++ overload set, which the
// structural check looks through to the member (SC-1c; check golden
// interop/cpp/class/import/template_constraint.carbon `satisfy`).
//
// WHICH LINE PROVES THE CHECK (same device as generics/
// structural_conformance.carbon): `Pick` is a first-match overload set;
// `Counter` has `Get` and prints 7 through member 1, `Plain` has no `Get`
// and prints 0 through member 2. An ignored constraint fails to compile on
// `Plain`; an over-strict check prints `0` twice.
//
// The classes are DELIBERATELY defined in `import Cpp inline` rather than a
// header: both are still imported through Clang (check/cpp/import.cpp
// method import), which is what D-SC-11 claims, and a non-`const` method is
// used because a `const` accessor's `self` qualifier is D-SC-5's flagged
// break condition (check golden interop/cpp/class/import/
// template_constraint.carbon `fail_const_method` and
// `const_method_value_self` splits: a `const` method imports as value `self`
// and matches `fn Get(self)`, hand-traced, unfilled); a `const`-method
// sibling program is queued once those splits fill as predicted.
//
// MEASUREMENT: awaiting the fork toolchain run. The upstream nightly does not
// implement `template constraint` (SC-1 is fork-only), so this program has
// not been run; the EXPECT lines are hand-derived from each member's own body
// and the first-match rule (R16(d)), never from an implementation run. A NEW
// program may start without a measured PASS (R16(b) is about previously
// passing ones); the scoreboard count is EXPECTED, not of record, until the
// fork toolchain's conformance run (R9).

import Core library "io";
import Cpp inline '''
struct Counter {
  int value;
  Counter(int v) : value(v) {}
  int Get() { return value; }
};
struct Plain {
  int value;
  Plain(int v) : value(v) {}
};
''';

template constraint HasGet {
  fn Get(ref self) -> i32;
}

overload fn Pick[template T: HasGet](p: T*) -> i32 {
  return p->Get();
}
overload fn Pick[template T: type](unused p: T*) -> i32 {
  return 0;
}

fn Run() -> i32 {
  var c: Cpp.Counter = Cpp.Counter.Counter(7);
  var q: Cpp.Plain = Cpp.Plain.Plain(1);
  Core.Print(Pick(&c));
  Core.Print(Pick(&q));
  return 0;
}
