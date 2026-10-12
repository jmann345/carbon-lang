// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Project: detailed and concrete design for safe Carbon (type/init/spatial/temporal/mutation + safe-Rust-interop analysis)
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   42
// SKIP: documentation bullet with no toolchain surface — the design EXISTS and is arbitrated by document review: docs/design/safety/README.md (rewritten, soundness model + mode syntax), type_safety.md, initialization_safety.md, spatial_safety.md, temporal_safety.md, mutation_safety.md and rust_interop.md landed under fork decision F-013 (fork/decision-log.md "SAFE-1 / F-013", fork/safe/plan.md), closing p005914's provisional section and docs/design/README.md's "Lifetime and move semantics" TODO; gap row 89 is DONE on that review. This program stays SKIP because no 0.1 toolchain surface can observe the design: `exclusive`, `permissive`, `bound`, `addr` are not tokens (toolchain/lex/token_kind.def has `unsafe` :243, `ref` :226 only), `unsafe` parses only before `as` (toolchain/parse/handle_expr.cpp:391-399), and no Strict diagnostic exists in toolchain/check. The earlier un-SKIP clause ("when dedicated safe-Carbon design docs ... land") is superseded by the body guard below. Un-SKIP when SAFE-1 stage 1 (ledger item W-129: mode spellings, `unsafe fn`, the `unsafe` prefix parsed and recorded) lands: then drop this directive and morph the body per below.
//
// Write-tests-first stub. A documentation bullet has no direct runtime
// arbitration, but the design has a toolchain surface from stage 1 on; the
// intended promoted body is a default-mode (Strict) program exercising one
// rule from each designed category, in the syntax F-013 fixes (comments only:
// R6 cannot apply to syntax no toolchain parses, so these lines are not
// compile-verified):
//
//   // fn Run() -> i32 {                          // Strict is the default: no mode line
//   //   var x: i32 = 42;
//   //   let p: i32* = &x;
//   //   let q: i32* = p unsafe as i32*;          // the keyword is REQUIRED (D-SAFE-5)
//   //   Core.Print(*q);                          // init + type safe: ok
//   //   // var a: array(i32, 2) = (1, 2); a[2];  // spatial: rejected at compile time
//   //   // let r: i32 = unsafe *q;               // temporal audit point (T6), stage 1 spelling
//   //   return 0;
//   // }

import Core library "io";

fn Run() -> i32 {
  // Guard: fails loudly (exit 1 vs EXPECT-EXIT 0) if un-SKIPped before the
  // concrete safe-Carbon design (and its checkable toolchain surface)
  // exists.
  return 1;
}
