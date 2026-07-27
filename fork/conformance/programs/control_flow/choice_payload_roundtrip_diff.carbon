// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Control flow: matching — sum-type consumption incl. std::variant/std::optional interop
// EXPECT-EXIT: 0
// SKIP: payload destructuring is W5 slice 2 — after slice 1, a choice-typed scrutinee is admitted and payload-free alternative patterns (`case .Err`) work, but a payload-alternative pattern `.Ok(...)` (or bare `.Ok`, which names the payload alternative's constructor) is rejected at its `case` with "error: semantics TODO: `match case pattern destructuring a choice payload`" (the choice-scrutinee shape gate in `MatchCaseIntroducer`/`MatchCase`, toolchain/check/handle_match.cpp), and `case .Ok(v: i32)` does not parse at all (parse/handle_pattern.cpp routes leading-`.` patterns to ExprPattern, where a binding is not an expression — slice 2 adds the alternative-pattern parse form). Un-SKIP (and uncomment the body) when W5 slice 2 lands binding patterns in choice case arms.
//
// Write-tests-first stub for the W5 slice-2 arbiter (fork/w5-choice/plan.md
// §3.3): construct a payload-carrying choice with a runtime-computed argument,
// extract the payload via a match binding pattern, and print it — the payload
// value round-trips through the F-007k overlapping storage. Differential pair:
// choice_payload_roundtrip_diff.diff.cpp holds the same sum in a std::variant
// and extracts via std::get_if, so C++ is the oracle for the round-tripped
// value (DIFF-1; no EXPECT-STDOUT). Binding spelling is bare `name: type` per
// SF-5; exhaustive alternative coverage replaces `default` per SF-7.

import Core library "io";

// choice IntResult {
//   Ok(value: i32),
//   Err
// }
//
// fn Consume(r: IntResult) -> i32 {
//   match (r) {
//     case .Ok(value: i32) => { return value; }
//     case .Err => { return -1; }
//   }
// }

fn Run() -> i32 {
  // Intended body once slice 2 lands:
  //   var base: i32 = 40;
  //   Core.Print(Consume(IntResult.Ok(base + 2)));
  //   Core.Print(Consume(IntResult.Err));
  //   return 0;
  // Guard: fails loudly (exit 1 vs EXPECT-EXIT 0) if un-SKIPped before
  // payload destructuring lands.
  return 1;
}
