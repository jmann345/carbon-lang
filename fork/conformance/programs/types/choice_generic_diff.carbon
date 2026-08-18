// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Type system: Sum types (discriminated unions)
// EXPECT-EXIT: 0
//
// Differential pair — the W5-S3b generic-payload arbiter (fork/w5-s3/plan.md
// §3 S3b). The C++ oracle in choice_generic_diff.diff.cpp is a class
// template over `std::variant<T, std::monostate>` probed via `index()`:
// alternative 0 is the payload (`Some`), alternative 1 is `std::monostate`
// (`None`, the payload-free arm — probed explicitly, exercising the S3a
// payload-free dispatch path beside the S3b payload path). This program
// mirrors it with a generic `choice` whose classification function returns
// the same index numbering by discriminant dispatch. Byte-identical exit
// code and stdout are required per DIFF-1; no EXPECT-STDOUT — C++ computes
// the expectation.
//
// What this differential arbitrates, at runtime: per-specific constructor
// synthesis (`Opt(i32).Some(...)` and `Opt(i64).Some(...)` are two distinct
// specific functions), discriminant dispatch through specifics, and one
// discriminant/payload COLLISION probe — `c64` below carries a
// runtime-computed payload whose LOW BYTE is 1, `None`'s discriminant value,
// so a payload store that aliases or overruns into a discriminant (a stale,
// zero-sized, or mis-offset payload region) flips a probed index from 0 to 1
// and breaks the byte-identical-output requirement. The other payload values
// (42, 64) cannot arbitrate that on their own: any discriminant they corrupt
// falls to `default`, which prints the same index as the correct `Some`
// dispatch. Layout NUMBERS — region size AND alignment — are NOT arbitrated
// here; they are pinned by the lower goldens
// (toolchain/lower/testdata/choice/generic_payload.carbon, plan §3/R-1).
// Payload argument values are runtime-computed (R16d), so constant folding
// cannot fake construction; payload READBACK is W5-S3c (destructuring), so
// the probe observes discriminants only. `var` for the call-initialized
// locals, `let` for constants — a workaround record now historical
// (retexted 2026-08-18): when this program landed, initializing a `var`
// from a class value required a `Copy` impl choices did not have (the
// types/choice_payload_construct.carbon precedent); W-075's synthesized
// choice `Core.Copy` witness lifted that, and the `let` spelling here is
// retained as landed — the doc-verbatim `var`-from-constant shape is
// arbitrated by control_flow/choice_generic_roundtrip_diff.carbon.

import Core library "io";

choice Opt(T: type) {
  Some(value: T),
  None
}

// Same index numbering as std::variant<T, std::monostate>: Some -> 0,
// None -> 1.
fn IndexI(o: Opt(i32)) -> i32 {
  match (o) {
    case .None => { return 1; }
    default => { return 0; }
  }
  return -1;
}

fn IndexL(o: Opt(i64)) -> i32 {
  match (o) {
    case .None => { return 1; }
    default => { return 0; }
  }
  return -1;
}

fn RuntimeSeed(x: i32) -> i32 { return x + 20; }

fn RuntimeSeedL(x: i64) -> i64 { return x + 20; }

fn Run() -> i32 {
  var s32: Opt(i32) = Opt(i32).Some(RuntimeSeed(22));
  let n32: Opt(i32) = Opt(i32).None;
  Core.Print(IndexI(s32));
  Core.Print(IndexI(n32));
  var s64: Opt(i64) = Opt(i64).Some(RuntimeSeedL(44));
  // The collision probe: 237 + 20 = 257, low byte 1 == `None`'s discriminant
  // value, so a discriminant/payload collision makes this print 1, not 0.
  var c64: Opt(i64) = Opt(i64).Some(RuntimeSeedL(237));
  let n64: Opt(i64) = Opt(i64).None;
  Core.Print(IndexL(s64));
  Core.Print(IndexL(c64));
  Core.Print(IndexL(n64));
  return 0;
}
