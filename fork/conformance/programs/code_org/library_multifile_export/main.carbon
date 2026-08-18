// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Code organization: Libraries
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   552
//   43

// The un-SKIP of the former single-file stub — the follow-up adjudicated
// at fork/w069/plan.md §8-A OQ-1 (the W69h multi-unit runner capability
// discharged the stub's "one file per program" harness limitation): a
// named library split across api + impl units (geo.carbon declares,
// geo.impl.carbon defines), consumed here directly via `import library
// "geo"` AND through an export chain — export.carbon's `export Rect;`
// then reexport.carbon's `export import library "export"`. Rect reaching
// this unit through both the direct import and the chain is COMPOSED
// from the individually golden-proven merge shapes of
// toolchain/check/testdata/packages/{export_name,export_mixed}.carbon
// (origin + one-hop name-export; name-export-then-export-import).
// Arbitration split honestly (review round): the api/impl HALF is
// runtime-load-bearing — RuntimeSeed's body exists only in the impl
// unit, so the expected literals require the impl object to compile,
// link, and run (a broken impl unit is a visible LINK-FAIL):
// w = RuntimeSeed(3) = 23, h = RuntimeSeed(4) = 24, Area = 23 * 24 =
// 552, and RuntimeSeed(w) = 23 + 20 = 43 (R16d). The export/reexport
// CHAIN half is COMPILE-arbitrated, not runtime-arbitrated: the merged
// Rect is one entity, so the printed values cannot attribute a route —
// the chain's coverage is that a diagnostic in `export Rect;`, the
// `export import`, or the route merge fails the program's per-unit
// compile visibly. No runtime `let` is exported anywhere in this
// program — `export x;` of a runtime `let` is the W-074 crash shape.

import Core library "io";
import library "geo";
import library "reexport";

fn Run() -> i32 {
  // Rect (one merged entity, reachable via both routes); the field values
  // and both prints route through the impl-unit function bodies.
  var r: Rect = {.w = RuntimeSeed(3), .h = RuntimeSeed(4)};
  Core.Print(Area(r));
  Core.Print(RuntimeSeed(r.w));
  return 0;
}
