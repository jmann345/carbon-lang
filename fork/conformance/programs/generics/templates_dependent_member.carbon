// CONFORMANCE-BULLET: Generics: Integrated templates
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   42
// SKIP: dependent member access `x.n` type-checks via deferred actions but compile aborts: FATAL failure at toolchain/lower/handle.cpp:363: Template lowering not implemented yet (SpliceInst; crash context "Lowering splice_inst" at the `x.n` line) — verified against this arbiter toolchain 2026-07-19
//
// The missing slice of the PARTIAL bullet: template-dependent member access.
// Shape verbatim from toolchain/check/testdata/generic/template/
// member_access.carbon (`fn F[template T: type](x: T) -> i32 { let n: i32 =
// x.n; ... }`), which passes *checking* — monomorphization of the specific
// succeeds and bad members are diagnosed ("unable to monomorphize specific")
// — but lowering of the resolved specific still hits the SpliceInst
// CARBON_FATAL. Dependent conversions (`let n: i32 = x;` from generic/
// template/convert.carbon) abort identically. Un-SKIP when template lowering
// (workstream W7) lands.

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
