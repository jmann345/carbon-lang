// CONFORMANCE-BULLET: Project: toolchain implements most 0.1 language features incl. C++ interop without undermining evaluation
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   10
//   20
//   30
// SKIP: the missing slice of this PARTIAL bullet — the gap-analysis names match, variadics, template-dependent lowering, error handling, and unions as absent 0.1 features; `match` is the reproducible representative: this file fails `carbon compile` on this exact arbiter tree (nightly 2026.07.19) with "error: semantics TODO: `HandleMatchIntroducer`" at the `match (n)` line, because every check handler in toolchain/check/handle_match.cpp is a context.TODO stub (siblings: template-dependent lowering CARBON_FATALs at lower/handle.cpp splice_inst — see generics/templates_dependent_member.carbon; choice payloads/`==` are absent — see types/choice_basic.carbon). Un-SKIP when W4 (match check + lowering) lands; the directives above already encode the designed first-match-wins semantics.
//
// The program a "most 0.1 language features" toolchain must run: a C/C++
// `switch` equivalent via `match` with a literal case, a guarded binding
// pattern, and `default`. Case shapes are verbatim from
// toolchain/parse/testdata/match/match.carbon (`case a: i32 if (a != x) =>`,
// `default =>`), the only in-repo match evidence — parse succeeds; check is
// where it dies. Expected semantics per docs/design/pattern_matching.md.

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
