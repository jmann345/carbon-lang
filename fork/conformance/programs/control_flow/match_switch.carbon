// CONFORMANCE-BULLET: Control flow: matching — good switch equivalents
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   10
//   20
//   30
// SKIP: match parses but has no semantics — every `match` statement fails compile with "error: semantics TODO: `HandleMatchIntroducer`" (all check handlers in toolchain/check/handle_match.cpp are context.TODO stubs; this file passes `carbon compile --phase=parse` with exit 0, which is the entire working slice of this PARTIAL bullet). Un-SKIP when W4 (match check + lowering) lands.
//
// The C/C++ `switch` equivalent: `match` over an i32 with a literal-expression
// case, a binding pattern with an `if` guard, and `default`. Case shapes are
// verbatim from toolchain/parse/testdata/match/match.carbon (the parse golden:
// `case a: i32 if (a != x) => { ... }`, `default => { ... }`), which is the
// only in-repo evidence for match — there is no check or lower testdata.
// EXPECT-STDOUT/EXPECT-EXIT encode the designed first-match-wins semantics
// (docs/design/pattern_matching.md) so this becomes a real execution test the
// moment the SKIP line is removed.

import Core library "io";

// switch (n) { case 0: return 10; ... default: return 30; }
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
