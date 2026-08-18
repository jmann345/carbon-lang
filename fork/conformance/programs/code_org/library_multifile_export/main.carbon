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
// this unit through both the direct import and the chain is the
// import_both / use_both merge shape of
// toolchain/check/testdata/packages/{export_name,export_mixed}.carbon.
// Runtime arbitration per R16d: inputs are runtime-computed seeds
// (RuntimeSeed(x) = x + 20, its body existing only in the impl unit), so
// the expected literals hold only if all five units compiled, linked, and
// the cross-unit definitions actually ran: w = RuntimeSeed(3) = 23,
// h = RuntimeSeed(4) = 24, Area = 23 * 24 = 552, and
// RuntimeSeed(w) = 23 + 20 = 43. No runtime `let` is exported anywhere in
// this program — `export x;` of a runtime `let` is the W-074 crash shape.

import Core library "io";
import library "geo";
import library "reexport";

fn Run() -> i32 {
  // Rect spelled through the two-spelling export chain; its field values
  // and both prints route through the impl-unit function bodies.
  var r: Rect = {.w = RuntimeSeed(3), .h = RuntimeSeed(4)};
  Core.Print(Area(r));
  Core.Print(RuntimeSeed(r.w));
  return 0;
}
