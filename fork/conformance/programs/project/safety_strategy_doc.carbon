// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Project: detailed safety strategy
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   42
// SKIP: documentation/strategy bullet — arbitrated by document review, not by a runnable program. The strategy is docs/design/safety/README.md, rewritten via the accepted proposals/p005914-updating-carbon-s-safety-strategy.md and covering: safe vs. unsafe code with three narrowness principles for `unsafe` constructs; Strict Carbon and Permissive Carbon safety modes configurable per file (package declaration) or per function; a per-category memory safety model (spatial, type, initialization enforced statically/dynamically; temporal via a Rust-style borrow-checked default with fallbacks; data-race safety deferred behind unsynchronized temporal safety); a safe library ecosystem plan including reuse of the Rust crate ecosystem; hardened/debug/optimized build-mode interaction; and constraints on probabilistic mitigations — supported by docs/design/safety/terminology.md. Toolchain state: one `unsafe` construct IS fully implemented and runnable today — the `unsafe as` conversion operator (Core.UnsafeAs; checked as ExplicitUnsafeAs in toolchain/check/convert.h, diagnostic-tested in toolchain/check/testdata/as/unsafe_as.carbon, lowered in toolchain/lower/testdata/pointer/convert.carbon) — and this file's body demonstrates it (hand-verified compile+link+run+output on the arbiter toolchain; EXPECT directives above describe that run). But `unsafe as` predates p005914 and exercises only narrowness principle 3 (a way to include the `unsafe` keyword in the operation's syntax); it cannot arbitrate this bullet, because what the strategy document adds — the Strict/Permissive safety modes, per-category enforcement, borrow-checked temporal default — has no toolchain surface: the doc itself marks the safety-mode syntax and the soundness model as "Future work" (three such blocks in docs/design/safety/README.md), so no program can yet distinguish a toolchain that follows the strategy from one that ignores it, and letting the `unsafe as` demo alone flip a documentation bullet to PASS would overclaim. Residual gaps per the gap-analysis note: soundness model and mode syntax undefined, and docs/project/principles/safety_strategy.md is a stale conflicting doc still describing the older build-mode-centric strategy ("Using build modes to manage safety checks"). Un-SKIP only when p005914's follow-on mode-syntax proposals land: then drop this directive and morph the body into a Strict-mode file where the `unsafe as` below is required to carry its `unsafe` keyword.
//
// Body: a real `unsafe as` pointer conversion (shape verbatim from
// toolchain/lower/testdata/pointer/convert.carbon `p unsafe as i64*` and
// toolchain/check/testdata/as/unsafe_as.carbon), the one strategy-adjacent
// construct that runs today. Kept valid and self-checking so this file is
// promotable the day safety-mode syntax exists.

import Core library "io";

fn Run() -> i32 {
  var x: i32 = 42;
  let p: i32* = &x;
  // Narrowness principle 3 of the safety strategy, live in the toolchain:
  // the unsafe operation itself carries the `unsafe` keyword.
  let q: i32* = p unsafe as i32*;
  Core.Print(*q);
  if (*q != 42) { return 1; }
  return 0;
}
