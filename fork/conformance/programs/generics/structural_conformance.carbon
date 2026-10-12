// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: Template-style structural conformance to nominal constraints
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   42
//   7
//
// A `template constraint` (p000818 as landed in docs/design/generics/
// details.md:1071-1077; p002200 "Template constraints") is satisfied
// STRUCTURALLY: `StructuralOnly` declares no `impl` anywhere, its own
// member `Get` matches the requirement `fn Get(self) -> i32` modulo
// `Self := StructuralOnly` (fork decision F-010 / SC-1, D-SC-5), and
// `x.Get()` dispatches to that member at instantiation.
//
// WHICH LINE PROVES THE CHECK: `Pick` is an `overload fn` set resolved by
// declaration-order first-match (fork decision F-009, fork/overload/plan.md
// D-OV-4). Member 1 is viable only if the argument type satisfies `HasGet`
// structurally; member 2 accepts any type. `Pick(s)` must print 42 (member
// 1 chosen) and `Pick(l)` must print 7 (member 1 rejected silently, member
// 2 chosen). If the constraint were silently ignored, member 1 would take
// `Lacking` and `x.Get()` would fail to compile; if the check rejected
// everything, the output would be `7` twice; if a rejected probe leaked a
// diagnostic, compilation would fail. Only a correct check prints `42` then
// `7`. Binding spelling from generics/templates_type_param.carbon
// (`[template T: …]`); overload-set spelling from
// functions/overloading_generic.carbon (`unused x: T`); the value-`let`
// arguments avoid a copy (no `Core.Copy` requirement is stated or needed).
//
// MEASUREMENT: awaiting the fork toolchain run. The upstream nightly does not
// implement `template constraint` (SC-1 is fork-only), so this program has
// not been run; the EXPECT lines are hand-derived from each member's own body
// and the first-match rule (R16(d)), never from an implementation run. The
// SKIP line was removed at SC-1c (fork/structural/plan.md §5.A, commit-2
// landed note finding 2(b)); the scoreboard flip to PASS is EXPECTED, not of
// record, until the fork toolchain's conformance run (R9).

import Core library "io";

template constraint HasGet {
  fn Get(self) -> i32;
}

class StructuralOnly {
  // Deliberately NO `impl as …`: the member alone satisfies the constraint.
  fn Get(self) -> i32 { return 42; }
}

class Lacking {
  // No `Get` at all: must NOT satisfy `HasGet`.
  fn Other(self) -> i32 { return 0; }
}

overload fn Pick[template T: HasGet](x: T) -> i32 {
  return x.Get();
}
overload fn Pick[template T: type](unused x: T) -> i32 {
  return 7;
}

fn Run() -> i32 {
  let s: StructuralOnly = {};
  let l: Lacking = {};
  Core.Print(Pick(s));
  Core.Print(Pick(l));
  return 0;
}
