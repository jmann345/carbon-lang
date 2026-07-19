// CONFORMANCE-BULLET: Control flow: matching — good switch equivalents
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   100
//   999
//   200
//   999
//   300
//   999
//
// Lands together with W4 slice 1 (fork/trial-w4/plan.md) and is expected to
// PASS; the scoreboard, not this comment, carries the before/after history
// (fork/process.md standing rule 2).
//
// Fallthrough absence. In C, `switch (0) { case 0: puts("100"); case 1:
// puts("200"); default: puts("300"); }` prints all three lines because
// control falls through case bodies unless `break`s. Carbon `match` has no
// fallthrough and no `break`: docs/design/pattern_matching.md — it "will
// find the _first_ `case` that matches this value, and execute that block.
// If none match, then it executes the default block." Exactly one arm's
// block runs, then control resumes after the match. The arms here
// deliberately do NOT return, so each call must print exactly one arm value
// followed by the after-match marker 999 — under C fallthrough Select(0)
// would print 100 200 300 999 and break the EXPECT-STDOUT above.
// `case <literal>` parses as an expression pattern
// (toolchain/parse/handle_pattern.cpp:43-55 default branch ->
// StateKind::ExprPattern; toolchain/parse/node_ids.h:109-110 AnyPatternId
// accepts Expr); `default =>` shape per
// toolchain/parse/testdata/match/match.carbon.

import Core library "io";

fn Select(n: i32) {
  match (n) {
    case 0 => { Core.Print(100); }
    case 1 => { Core.Print(200); }
    default => { Core.Print(300); }
  }
  // Reached exactly once per call, whichever arm ran.
  Core.Print(999);
}

fn Run() -> i32 {
  Select(0);
  Select(1);
  Select(7);
  return 0;
}
