// CONFORMANCE-BULLET: Control flow: matching — sum-type consumption incl. std::variant/std::optional interop
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   42
//   7
// SKIP: MISSING end-to-end — after W5 slice 1, a choice-typed scrutinee is admitted and payload-free alternative patterns (`case .Err`) dispatch on the discriminant, but this program's remaining blockers are: (1) payload destructuring — a payload-alternative pattern like `.Ok(...)` is rejected at its `case` with "error: semantics TODO: `match case pattern destructuring a choice payload`" (the choice-scrutinee shape gate in `MatchCaseIntroducer`/`MatchCase`, toolchain/check/handle_match.cpp; W5 slice 2, whose choice-only arbiter is control_flow/choice_payload_roundtrip_diff.carbon — at slice 2 this program keeps only its interop half per the fork/w5-choice/plan.md §3.3 split), and (2) no std::variant/std::optional interop mapping (check/cpp/custom_type_mapping.cpp has no variant/optional matcher; W5 slice 4); Optional is a placeholder without pattern integration. Un-SKIP (and uncomment the body) when W5 slice 4 lands the interop mapping.
//
// Write-tests-first stub. Intended future test: consume a payload-carrying
// choice via `match` alternative patterns (choice-with-payload and `.Name`
// pattern shapes from docs/design/sum_types.md; `case ... => { }` statement
// shape from toolchain/parse/testdata/match/match.carbon), then do the same
// over a `Cpp.std.variant`/
// `Cpp.std.optional` value imported from C++ so sum-type consumption spans
// the interop boundary. First-match-wins semantics per
// docs/design/pattern_matching.md.

import Core library "io";
// import Cpp inline '''c++
// #include <optional>
// inline std::optional<int> MaybeSeven() { return 7; }
// ''';
//
// choice IntResult {
//   Ok(value: i32),
//   Err
// }
//
// fn Consume(r: IntResult) -> i32 {
//   match (r) {
//     case .Ok(let v: i32) => { return v; }
//     case .Err => { return -1; }
//   }
// }

fn Run() -> i32 {
  // Intended body once the features land:
  //   Core.Print(Consume(IntResult.Ok(42)));
  //   match (Cpp.MaybeSeven()) {
  //     case .Some(let n: i32) => { Core.Print(n); }
  //     case .None => { return 1; }
  //   }
  //   return 0;
  // Guard: fails loudly (exit 1 vs EXPECT-EXIT 0) if un-SKIPped before
  // match semantics, choice payloads, and variant/optional interop land.
  return 1;
}
