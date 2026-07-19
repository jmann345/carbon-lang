// CONFORMANCE-BULLET: Project: toolchain implements most 0.1 language features incl. C++ interop without undermining evaluation
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   10
//   20
//   30
// SKIP: the missing slice of this PARTIAL bullet — the gap-analysis names match, variadics, template-dependent lowering, error handling, and unions as absent 0.1 features; this file's reproducible representative is match-beyond-slice-1: W4 slice 1 checks and lowers only integer scrutinees with integer-literal cases plus `default`, so the `case a: i32 if (a < 0)` arm below is rejected at its `case` token with "error: semantics TODO: `match `case` pattern other than an integer literal, or a case guard`" (the `MatchCaseIntroducer` slice gate in toolchain/check/handle_match.cpp; fork/trial-w4/plan.md H5) (siblings: template-dependent lowering CARBON_FATALs at lower/handle.cpp splice_inst — see generics/templates_dependent_member.carbon; choice payloads/`==` are absent — see types/choice_basic.carbon). Un-SKIP when guards + binding patterns land (post-slice-1 W4 work); the directives above already encode the designed first-match-wins semantics. Kept as the guarded-binding representative rather than narrowed to slice-1 arms (which slice-1 coverage match_switch.carbon already provides) — scope trade recorded in fork/decision-log.md.
//
// The program a "most 0.1 language features" toolchain must run: a C/C++
// `switch` equivalent via `match` with a literal case, a guarded binding
// pattern, and `default`. The guarded-binding and `default` shapes are
// verbatim from toolchain/parse/testdata/match/match.carbon:16-17
// (`case a: i32 if (a != x) =>`, `default =>`); `case <literal>` parses as
// an expression pattern (toolchain/parse/handle_pattern.cpp:43-55;
// toolchain/parse/node_ids.h:109-110) — parse succeeds; check is where it
// dies. Expected semantics per docs/design/pattern_matching.md.

import Core library "io";

fn Classify(n: i32) -> i32 {
  match (n) {
    case 0 => { return 10; }
    case a: i32 if (a < 0) => { return 20; }
    default => { return 30; }
  }
  return -1;
}

fn Run() -> i32 {
  Core.Print(Classify(0));
  Core.Print(Classify(-7));
  Core.Print(Classify(42));
  return 0;
}
