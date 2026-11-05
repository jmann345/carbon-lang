// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: Integrated templates
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   42
//
// Un-SKIPped 2026-10-06 (UA-2 probe, fork/upstream/plan.md §0.6 W-014 row
// and §8.5). The SKIP (2026-07-19) cited `FATAL failure at
// toolchain/lower/handle.cpp:363: Template lowering not implemented yet`
// (SpliceInst; crash context "Lowering splice_inst" at the `x.n` line).
// Upstream PR 7727 landed template lowering: the resolved specific's
// instructions are lowered per specific (upstream goldens
// toolchain/lower/testdata/template/{convert,operator,class}.carbon), and the
// only `CARBON_FATAL` left in lower/handle.cpp is "Cross-file template
// lowering not implemented yet" (:513), which this program does not reach —
// `GetN` is instantiated in the file that defines it. Prediction: PASS, 42.
// Measured 2026-10-06: PASS on hosted conformance run 37407530104 (UA-2
// round 1) — the W-014 probe flipped.
//
// The slice this program pins: template-dependent member access. Shape
// verbatim from toolchain/check/testdata/generic/template/member_access.carbon
// (`simple_member_access.carbon`: `fn F[template T: type](x: T) -> i32 { let
// n: i32 = x.n; ... }` called on a class with a field `n`), which passed
// *checking* at the 2026-07-19 cut — monomorphization of the specific
// succeeded and bad members were diagnosed ("unable to monomorphize
// specific") — while lowering of the resolved specific hit the SpliceInst
// CARBON_FATAL; dependent conversions (`let n: i32 = x;` from generic/
// template/convert.carbon) aborted identically.

import Core library "io";

class Point {
  var n: i32;
}

fn GetN[template T: type](x: T) -> i32 {
  let n: i32 = x.n;
  return n;
}

fn Run() -> i32 {
  var p: Point = {.n = 42};
  Core.Print(GetN(p));
  return 0;
}
