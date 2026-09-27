// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Error handling: dedicated control flow constructs
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   1
//   10
//   0
//   0
//   6
//
// The EH-A `Optional as Try` arbiter (fork/eh/plan.md §5.A.2; decision D9 of
// docs/design/error_handling.md): postfix `?` over the prelude
// `Core.Optional(T)` through its `final impl forall [T: OptionalStorage]
// Optional(T) as Try where .ContinueType = T and .BreakType = ()`
// (core/prelude/types/optional.carbon), so absence propagates through `?`
// with the unit break type — the `Core.ControlFlow(T, ())` carrier whose
// `()` payload D-EH-2 admits. `Quarter` has two `?`-reachable absences: the
// first is PROPAGATED by `?` (Half(n) is None), the second is RETURNED
// (Half(h) is None). All inputs are runtime-computed (R16d). Expected output,
// hand-derived from the `std::optional`-with-explicit-early-return mental
// model: seed 40 → Half 20 → Half 10 → Some(10) → `1`, `10`; seed 42 →
// Half 21, odd → Quarter returns None → `0`; seed 41 → Half(41) is None →
// `?` propagates → `0`. The fourth probe applies `?` to the pointer-niche
// storage `Core.Optional(i32*)` (null is None): `Deref(.Some(&cell))` with
// `cell = RuntimeSeed(-14) = 6` prints the pointee → `6`. Exit-code belt:
// a missing pointee value exits 1 instead of printing.

import Core library "io";

fn Half(n: i32) -> Core.Optional(i32) {
  if ((n / 2) * 2 == n) { return Core.Optional(i32).Some(n / 2); }
  return Core.Optional(i32).None();
}

fn Quarter(n: i32) -> Core.Optional(i32) {
  // The dedicated propagation construct over `Optional`: on `None`, `?`
  // rebuilds `None` through `Core.Try.FromBreak(())` and returns it.
  let h: i32 = Half(n)?;
  return Half(h);
}

fn Deref(p: Core.Optional(i32*)) -> Core.Optional(i32) {
  return Core.Optional(i32).Some(*(p?));
}

// Prints `HasValue()` as 1/0 and, when present, `Get()`.
fn Probe(n: i32) {
  var q: Core.Optional(i32) = Quarter(n);
  if (q.HasValue()) {
    Core.Print(1);
    Core.Print(q.Get());
  } else {
    Core.Print(0);
  }
}

fn RuntimeSeed(x: i32) -> i32 { return x + 20; }

fn Run() -> i32 {
  Probe(RuntimeSeed(20));
  Probe(RuntimeSeed(22));
  Probe(RuntimeSeed(21));

  var cell: i32 = RuntimeSeed(-14);
  var d: Core.Optional(i32) = Deref(Core.Optional(i32*).Some(&cell));
  if (d.HasValue()) {
    Core.Print(d.Get());
  } else {
    return 1;
  }
  return 0;
}
