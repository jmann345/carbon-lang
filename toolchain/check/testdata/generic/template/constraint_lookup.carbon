// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/generic/template/constraint_lookup.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/generic/template/constraint_lookup.carbon

// --- constraint_only.carbon
library "[[@TEST_NAME]]";

interface HasArea {
  fn Area(self) -> i32;
}

class Square {
  var side: i32;
  impl as HasArea {
    fn Area(self) -> i32 { return self.side * self.side; }
  }
}

fn Report[template T: HasArea](s: T) -> i32 {
  return s.Area();
}

fn Use(q: Square) -> i32 {
  return Report(q);
}

// --- extend_impl_same_entity.carbon
library "[[@TEST_NAME]]";

interface HasArea {
  fn Area(self) -> i32;
}

class Rect {
  var w: i32;
  var h: i32;
  extend impl as HasArea {
    fn Area(self) -> i32 { return self.w * self.h; }
  }
}

fn Report[template T: HasArea](s: T) -> i32 {
  return s.Area();
}

fn Use(r: Rect) -> i32 {
  return Report(r);
}

// --- type_only_member.carbon
library "[[@TEST_NAME]]";

interface A {
  fn F(self) -> i32;
}

class C {
  var v: i32;
  fn G(unused self) -> i32 { return 7; }
  impl as A {
    fn F(unused self) -> i32 { return 2; }
  }
}

fn H[template T: A](x: T) -> i32 {
  return x.G() * 10 + x.F();
}

fn Use(c: C) -> i32 {
  return H(c);
}

// --- field_not_in_constraint.carbon
library "[[@TEST_NAME]]";

interface A {
  fn F(self) -> i32;
}

class C {
  var n: i32;
  impl as A {
    fn F(unused self) -> i32 { return 2; }
  }
}

fn H[template T: A](x: T) -> i32 {
  return x.n;
}

fn Use(c: C) -> i32 {
  return H(c);
}

// --- round_widget_alias.carbon
library "[[@TEST_NAME]]";

interface Renderable {
  fn Draw(self) -> i32;
}

class RoundWidget {
  var n: i32;
  impl as Renderable {
    fn Draw(self) -> i32 { return self.n; }
  }
  alias Draw = Renderable.Draw;
}

fn DrawTemplate[template T: Renderable](c: T) -> i32 {
  return c.Draw();
}

fn Use(r: RoundWidget) -> i32 {
  return DrawTemplate(r);
}

// --- square_widget_impl_alias.carbon
library "[[@TEST_NAME]]";

interface Renderable {
  fn Draw(self) -> i32;
}

class SquareWidget {
  var n: i32;
  fn Draw(self) -> i32 { return self.n * 2; }
}

impl SquareWidget as Renderable {
  alias Draw = SquareWidget.Draw;
}

fn DrawTemplate[template T: Renderable](c: T) -> i32 {
  return c.Draw();
}

fn Use(s: SquareWidget) -> i32 {
  return DrawTemplate(s);
}

// --- fail_different_entities.carbon
library "[[@TEST_NAME]]";

interface A {
  fn F(self) -> i32;
}

class C {
  var v: i32;
  fn F(unused self) -> i32 { return 1; }
  impl as A {
    fn F(unused self) -> i32 { return 2; }
  }
}

fn G[template T: A](x: T) -> i32 {
  return x.(A.F)() * 10 + x.F();
}

fn Use(c: C) -> i32 {
  // CHECK:STDERR: fail_different_entities.carbon:[[@LINE+7]]:10: error: unable to monomorphize specific `G(C as A)` [ResolvingSpecificHere]
  // CHECK:STDERR:   return G(c);
  // CHECK:STDERR:          ^
  // CHECK:STDERR: fail_different_entities.carbon:[[@LINE-7]]:27: note: member name `F` names different entities in type `C` and in its constraint `A` [TemplateMemberLookupAmbiguous]
  // CHECK:STDERR:   return x.(A.F)() * 10 + x.F();
  // CHECK:STDERR:                           ^~~
  // CHECK:STDERR:
  return G(c);
}

// --- fail_cowboy.carbon
library "[[@TEST_NAME]]";

interface Renderable {
  fn Draw(self) -> i32;
}

class Cowboy {
  var n: i32;
  fn Draw(unused self) -> i32 { return 1; }
}

impl Cowboy as Renderable {
  fn Draw(unused self) -> i32 { return 2; }
}

fn DrawTemplate[template T: Renderable](c: T) -> i32 {
  return c.Draw();
}

fn Use(c: Cowboy) -> i32 {
  // CHECK:STDERR: fail_cowboy.carbon:[[@LINE+7]]:10: error: unable to monomorphize specific `DrawTemplate(Cowboy as Renderable)` [ResolvingSpecificHere]
  // CHECK:STDERR:   return DrawTemplate(c);
  // CHECK:STDERR:          ^~~~~~~~~~~~
  // CHECK:STDERR: fail_cowboy.carbon:[[@LINE-7]]:10: note: member name `Draw` names different entities in type `Cowboy` and in its constraint `Renderable` [TemplateMemberLookupAmbiguous]
  // CHECK:STDERR:   return c.Draw();
  // CHECK:STDERR:          ^~~~~~
  // CHECK:STDERR:
  return DrawTemplate(c);
}

// --- fail_field_vs_constraint_method.carbon
library "[[@TEST_NAME]]";

interface A {
  fn F(self) -> i32;
}

class C {
  var F: i32;
  impl as A {
    fn F(unused self) -> i32 { return 2; }
  }
}

fn H[template T: A](x: T) -> i32 {
  return x.F;
}

fn Use(c: C) -> i32 {
  // CHECK:STDERR: fail_field_vs_constraint_method.carbon:[[@LINE+7]]:10: error: unable to monomorphize specific `H(C as A)` [ResolvingSpecificHere]
  // CHECK:STDERR:   return H(c);
  // CHECK:STDERR:          ^
  // CHECK:STDERR: fail_field_vs_constraint_method.carbon:[[@LINE-7]]:10: note: member name `F` names different entities in type `C` and in its constraint `A` [TemplateMemberLookupAmbiguous]
  // CHECK:STDERR:   return x.F;
  // CHECK:STDERR:          ^~~
  // CHECK:STDERR:
  return H(c);
}

// --- fail_todo_field_of_template_class.carbon
library "[[@TEST_NAME]]";

interface A {
  fn F(self) -> i32;
}

class C {
  var n: i32;
  impl as A {
    fn F(self) -> i32 { return self.n; }
  }
}

class W(template T: A) {
  var c: T;
  fn Go(self) -> i32 { return self.c.F(); }
}

fn Use(w: W(C)) -> i32 {
  return w.Go();
}
