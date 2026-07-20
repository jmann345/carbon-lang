// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Project: detailed and concrete design for safe Carbon (type/init/spatial/temporal/mutation + safe-Rust-interop analysis)
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   42
// SKIP: MISSING documentation bullet — there is no document to review: temporal/mutation safety exists only as an explicitly "directional... provisional" section of proposals/p005914-updating-carbon-s-safety-strategy.md, there are no dedicated design docs or follow-up proposals for the per-category design (type/init/spatial/temporal/mutation), no safe-Rust-interop analysis exists anywhere, and docs/design/README.md's "Lifetime and move semantics" section is a bare TODO. Distinct from the (also-SKIPped) strategy bullet arbitrated by project/safety_strategy_doc.carbon: that one reviews the accepted p005914 strategy; this one requires the *detailed and concrete* follow-on design, which has not been written. Arbitrate by document review — un-SKIP when dedicated safe-Carbon design docs covering all five categories plus the Rust-interop analysis land, then morph the body per below.
//
// Write-tests-first stub. A documentation bullet has no direct runtime
// arbitration, but the future design will have a toolchain surface; the
// intended promoted body is a Strict-mode program exercising one rule from
// each designed category, e.g. (strawman syntax pending the design):
//
//   // package Main strict;                       // safety-mode syntax
//   // fn Run() -> i32 {
//   //   var x: i32 = 42;
//   //   let p: i32* = &x;
//   //   Core.Print(*p);                          // init + type safe: ok
//   //   // let q: i32* = p unsafe as i32*;       // must REQUIRE `unsafe`
//   //   // var a: array(i32, 2) = (1, 2); a[5];  // spatial: rejected
//   //   // temporal/mutation: borrow-checked default per the design
//   //   return 0;
//   // }

import Core library "io";

fn Run() -> i32 {
  // Guard: fails loudly (exit 1 vs EXPECT-EXIT 0) if un-SKIPped before the
  // concrete safe-Carbon design (and its checkable toolchain surface)
  // exists.
  return 1;
}
