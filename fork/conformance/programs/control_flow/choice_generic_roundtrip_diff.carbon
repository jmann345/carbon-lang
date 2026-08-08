// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Control flow: matching — sum-type consumption incl. std::variant/std::optional interop
// EXPECT-EXIT: 0

// The W5-S3c arbiter (fork/w5-s3/plan.md §3 S3c): the docs/design/
// sum_types.md generic-choice example, constructed and DESTRUCTURED at
// runtime. The declaration (sum_types.md:63-66) and the match
// (sum_types.md:81-88) are the doc's shapes verbatim — the match without
// `default`, the S2e exhaustiveness discharge — with I/O adapted per
// rulebook R1 (`Core.PrintStr` does not link; the `.None` arm prints -1
// for the doc's `Print("None")`). The doc's construction (sum_types.md:74)
// initializes a `var` from the constant alternative `Optional(i32).None`;
// that line cannot compile in this fork — initializing a `var` from a
// class VALUE copies, and choice types implement no `Core.Copy` (SF-6
// scope; the types/choice_generic_diff.carbon precedent) — so the None
// value binds with `let` and the doc's RE-ASSIGNMENT shape
// (sum_types.md:75, `my_opt = Optional(i32).Some(42);`) runs verbatim on a
// `var` initialized in place. The doc's None-to-Some transition on the
// SAME variable is not exercised (assigning `.None` is also a value copy
// through the same path); the arbitrated transition is Some-to-Some, the
// closest achievable. Payloads are runtime-computed (R16d): the
// doc's 42 arrives as 22 + 20, so constant folding cannot fake the
// round-trip, and a failed re-assignment would leave the initial payload
// (2) visible in the output. Differential pair:
// choice_generic_roundtrip_diff.diff.cpp mirrors the example with
// std::optional (the doc example's semantics), so C++ is the oracle for
// every printed payload (DIFF-1; no EXPECT-STDOUT). Beyond the doc block,
// a second specific — `Optional(i64)`, including a payload whose low byte
// equals `None`'s discriminant value (237 + 20 = 257, the
// choice_generic_diff collision probe carried into payload READBACK) —
// pins per-specific payload extraction at runtime.

import Core library "io";

choice Optional(T: type) {
  Some(value: T),
  None
}

fn RuntimeSeed(x: i32) -> i32 { return x + 20; }

fn RuntimeSeedL(x: i64) -> i64 { return x + 20; }

fn Run() -> i32 {
  // sum_types.md:74, adapted to `let` (see the header comment): the None
  // value inspected through the doc's match shape prints the None arm.
  let start_opt: Optional(i32) = Optional(i32).None;
  match (start_opt) {
    case .Some(the_value: i32) => {
      Core.Print(the_value);
    }
    case .None => {
      Core.Print(-1);
    }
  }

  // sum_types.md:75's re-assignment shape, payload runtime-computed:
  // 22 + 20 = 42, the doc's `.Some(42)`. The initial in-place payload (2)
  // must be overwritten — the match below prints 42 only if the
  // re-initialization really lands.
  var my_opt: Optional(i32) = Optional(i32).Some(RuntimeSeed(-18));
  my_opt = Optional(i32).Some(RuntimeSeed(22));

  // sum_types.md:81-88 verbatim, I/O adapted (header comment).
  match (my_opt) {
    case .Some(the_value: i32) => {
      Core.Print(the_value);
    }
    case .None => {
      Core.Print(-1);
    }
  }

  // Beyond the doc block: a second specific destructured at runtime.
  // 237 + 20 = 257 — low byte 1, `None`'s discriminant value, so a
  // payload/discriminant overlap corrupts either the printed payload or
  // the dispatch, and the byte-identical-output requirement catches both.
  var wide: Optional(i64) = Optional(i64).Some(RuntimeSeedL(237));
  match (wide) {
    case .Some(v: i64) => {
      Core.Print(v as i32);
    }
    case .None => {
      Core.Print(-1);
    }
  }
  let none_wide: Optional(i64) = Optional(i64).None;
  match (none_wide) {
    case .Some(v: i64) => {
      Core.Print(v as i32);
    }
    case .None => {
      Core.Print(-1);
    }
  }
  return 0;
}
