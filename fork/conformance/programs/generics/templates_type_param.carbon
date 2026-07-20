// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: Integrated templates
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   42
//   1
//   7
//
// Working slice of integrated templates: a `template T` type binding checked
// and monomorphized at two different argument types (i32, bool), plus the
// template binding flowing into a generic-class return type `Box(T)`.
// Binding syntax verbatim from toolchain/check/testdata/generic/template/
// member_access.carbon (`fn F[template T: type](x: T)`); the Box shape from
// toolchain/lower/testdata/class/generic.carbon. Bodies deliberately avoid
// template-dependent member access and conversions, which type-check but
// still CARBON_FATAL at lowering (lower/handle.cpp:363, splice_inst) — see
// templates_dependent_member.carbon for that missing slice.

import Core library "io";

class Box(T: type) {
  var item: T;
}

fn Identity[template T: Core.Copy & Core.Destroy](x: T) -> T {
  return x;
}

fn MakeBox[template T: Core.Copy & Core.Destroy](x: T) -> Box(T) {
  return {.item = x};
}

fn Run() -> i32 {
  let v: i32 = 41;
  Core.Print(Identity(v) + 1);
  let b: bool = Identity(true);
  if (b) {
    Core.Print(1);
  }
  let s: i32 = 7;
  var boxed: Box(i32) = MakeBox(s);
  Core.Print(boxed.item);
  return 0;
}
