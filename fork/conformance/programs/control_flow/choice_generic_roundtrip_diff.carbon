// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Control flow: matching — sum-type consumption incl. std::variant/std::optional interop
// EXPECT-EXIT: 0

// The W5-S3c arbiter (fork/w5-s3/plan.md §3 S3c): the docs/design/
// sum_types.md generic-choice example, constructed and DESTRUCTURED at
// runtime. The declaration (sum_types.md:63-66), the construction
// (sum_types.md:74, `var my_opt: Optional(i32) = Optional(i32).None;`),
// the re-assignment (sum_types.md:75), and the match (sum_types.md:81-88)
// are the doc's shapes verbatim — the match without `default`, the S2e
// exhaustiveness discharge — with I/O adapted per rulebook R1
// (`Core.PrintStr` does not link; the `.None` arm prints -1 for the doc's
// `Print("None")`). HISTORICAL deviation record (restored 2026-08-18 per
// W-075, fork/w075/plan.md §4.3): as landed, the doc's line 74 could not
// compile — initializing a `var` from a class VALUE copies, and choice
// types implemented no `Core.Copy` — so the None value bound with `let`
// and the None-to-Some transition on the SAME variable went unexercised.
// W-075's synthesized choice `Core.Copy` witness lifted that; this program
// now runs the doc's lines verbatim, including the full
// None-to-Some(-to-None) transition on one variable, mirrored in the
// oracle by `std::optional` assignment and `.reset()`. Payloads are
// runtime-computed (R16d): the doc's 42 arrives as 22 + 20, so constant
// folding cannot fake the round-trip, and the Some-to-Some overwrite
// probe (payload 2 first) keeps a failed re-assignment visible in the
// output. Differential pair: choice_generic_roundtrip_diff.diff.cpp
// mirrors the example with std::optional (the doc example's semantics), so
// C++ is the oracle for every printed payload (DIFF-1; no EXPECT-STDOUT).
// Beyond the doc block, a second specific — `Optional(i64)`, including a
// payload whose low byte equals `None`'s discriminant value (237 + 20 =
// 257, the choice_generic_diff collision probe carried into payload
// READBACK) — pins per-specific payload extraction at runtime.

import Core library "io";

choice Optional(T: type) {
  Some(value: T),
  None
}

fn RuntimeSeed(x: i32) -> i32 { return x + 20; }

fn RuntimeSeedL(x: i64) -> i64 { return x + 20; }

fn Run() -> i32 {
  // sum_types.md:74 VERBATIM (W-075 restoration): the `var` initialized
  // from the constant alternative — a value copy through the synthesized
  // choice `Core.Copy` witness — inspected through the doc's match shape,
  // printing the None arm.
  var my_opt: Optional(i32) = Optional(i32).None;
  match (my_opt) {
    case .Some(the_value: i32) => {
      Core.Print(the_value);
    }
    case .None => {
      Core.Print(-1);
    }
  }

  // sum_types.md:75's re-assignment shape ON THE SAME VARIABLE — the doc's
  // None-to-Some transition — payload runtime-computed: 22 + 20 = 42, the
  // doc's `.Some(42)`. The Some-to-Some overwrite probe rides in front
  // (payload 2 first), so a failed re-assignment leaves 2 visible.
  my_opt = Optional(i32).Some(RuntimeSeed(-18));
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

  // The transition back — Some-to-None by assigning the `.None` constant
  // (the same copy path; `.reset()` in the oracle) — closes the doc's
  // round trip on one variable.
  my_opt = Optional(i32).None;
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
