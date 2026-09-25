// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Control flow: matching — sum-type consumption incl. std::variant/std::optional interop
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   1
//   7
//   0
//
// Runtime dispatch on a payload VALUE (W-008 W8a): `case .Some(42)` tests
// the discriminant AND the payload — the payload read must be dominated by
// the discriminant test, since a non-`.Some` value's payload region is
// uninitialized — and a non-matching payload falls through to the binding
// arm `.Some(n: i32)`, proving first-match-wins order
// (docs/design/pattern_matching.md, "Refutability, overlap, usefulness,
// and exhaustiveness": the refutable literal arm covers nothing, so the
// binding arm plus `.None` keep the match exhaustive without `default`).
// Payload values go through RuntimeSeed(x) = x + 20 so the dispatch is a
// real runtime compare, not a constant fold. The interop half of this
// bullet stays with match_sum_type_payload.carbon (W5 slice 4).

import Core library "io";

choice OptInt {
  Some(x: i32),
  None
}

fn RuntimeSeed(x: i32) -> i32 { return x + 20; }

fn Classify(o: OptInt) -> i32 {
  match (o) {
    case .Some(42) => { return 1; }
    case .Some(n: i32) => { return n; }
    case .None => { return 0; }
  }
  // Unreachable: the match is exhaustive and every arm returns. A
  // fall-through here would print -1 and fail the EXPECT-STDOUT block.
  return -1;
}

fn Run() -> i32 {
  // RuntimeSeed(22) = 42: the literal arm wins, NOT the later binding arm.
  Core.Print(Classify(OptInt.Some(RuntimeSeed(22))));
  // RuntimeSeed(-13) = 7: the literal arm fails on the payload value and
  // falls through to the binding arm, which returns the payload.
  Core.Print(Classify(OptInt.Some(RuntimeSeed(-13))));
  Core.Print(Classify(OptInt.None));
  return 0;
}
