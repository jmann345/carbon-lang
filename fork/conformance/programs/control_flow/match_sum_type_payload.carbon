// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Control flow: matching — sum-type consumption incl. std::variant/std::optional interop
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   7
// SKIP: MISSING interop half — Carbon-side sum-type consumption landed at the match re-platform's S2c (W5 slice 2): a payload alternative pattern `case .Ok(value: i32)` destructures the payload and binds it (arbiter: control_flow/choice_payload_roundtrip_diff.carbon, un-SKIPped at S2c), so per the fork/w5-choice/plan.md §3.3 split this program now keeps only its interop half. Remaining blocker: no std::variant/std::optional interop mapping (check/cpp/custom_type_mapping.cpp has no variant/optional matcher; W5 slice 4) — `match (Cpp.MaybeSeven())` has no choice-typed view of std::optional, and Optional is a placeholder without pattern integration, so the post-S2c toolchain rejects the intended body at the scrutinee with "error: semantics TODO: `match on unsupported scrutinee type`" (the MatchCondition scrutinee gate in toolchain/check/handle_match.cpp), before any case pattern is reached. Un-SKIP (and uncomment the body) when W5 slice 4 lands the interop mapping.
//
// Write-tests-first stub. Intended future test: consume a
// `Cpp.std.optional` value imported from C++ through `match` alternative
// patterns, so sum-type consumption spans the interop boundary (`.Name`
// pattern shapes from docs/design/sum_types.md; first-match-wins semantics
// per docs/design/pattern_matching.md). The Carbon-choice half of this
// program's original sketch moved to choice_payload_roundtrip_diff.carbon
// at S2c.

import Core library "io";
// import Cpp inline '''c++
// #include <optional>
// inline std::optional<int> MaybeSeven() { return 7; }
// ''';

fn Run() -> i32 {
  // Intended body once the interop mapping lands:
  //   match (Cpp.MaybeSeven()) {
  //     case .Some(n: i32) => { Core.Print(n); }
  //     case .None => { return 1; }
  //     default => { return 1; }
  //   }
  //   return 0;
  // Guard: fails loudly (exit 1 vs EXPECT-EXIT 0) if un-SKIPped before
  // variant/optional interop lands.
  return 1;
}
