// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Control flow: matching — good switch equivalents
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   44
//   55
//   10
//   20
//
// Lands together with W4 slice 1 (fork/trial-w4/plan.md) and is expected to
// PASS; the scoreboard, not this comment, carries the before/after history
// (fork/process.md standing rule 2).
//
// Match position. (a) `Last`: the match is the function's LAST statement and
// every arm returns — no trailing `return` may be required, because the
// function end is unreachable, exactly as with an `if`/`else` where both
// branches return (working in-repo precedent:
// toolchain/check/testdata/eval/branch.carbon's if_statement F). (b) `Mid`:
// the match sits MID-function with non-returning arms; the arms write a
// local and control converges to the code after the match, which observes
// the value. `case <literal>` parses as an expression pattern
// (toolchain/parse/handle_pattern.cpp:43-55 default branch ->
// StateKind::ExprPattern; toolchain/parse/node_ids.h:109-110 AnyPatternId
// accepts Expr); `default =>` shape per
// toolchain/parse/testdata/match/match.carbon; first-match-then-default
// execution per docs/design/pattern_matching.md.

import Core library "io";

// (a) Match as the last statement; all arms return; no trailing return.
fn Last(n: i32) -> i32 {
  match (n) {
    case 4 => { return 44; }
    default => { return 55; }
  }
}

// (b) Match mid-function; arms assign; execution continues after the match.
fn Mid(n: i32) -> i32 {
  var r: i32 = 0;
  match (n) {
    case 4 => { r = 1; }
    default => { r = 2; }
  }
  return r * 10;
}

fn Run() -> i32 {
  Core.Print(Last(4));
  Core.Print(Last(9));
  Core.Print(Mid(4));
  Core.Print(Mid(9));
  return 0;
}
