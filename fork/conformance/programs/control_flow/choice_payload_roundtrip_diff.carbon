// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Control flow: matching — sum-type consumption incl. std::variant/std::optional interop
// EXPECT-EXIT: 0

// The W5 slice-2 arbiter (fork/w5-choice/plan.md §3.3): construct a
// payload-carrying choice with a runtime-computed argument, extract the
// payload via a match alternative pattern binding, and print it — the
// payload value round-trips through the F-007k overlapping storage.
// Differential pair: choice_payload_roundtrip_diff.diff.cpp holds the same
// sum in a std::variant and extracts via std::get_if, so C++ is the oracle
// for the round-tripped value (DIFF-1; no EXPECT-STDOUT). Binding spelling
// is bare `name: type` per SF-5. The arms cover both alternatives, so no
// `default` arm is needed: choice exhaustiveness landed at re-platform
// S2e (SF-7), dropping the never-taken `default` the S2c landing recorded.

import Core library "io";

choice IntResult {
  Ok(value: i32),
  Err
}

fn Consume(r: IntResult) -> i32 {
  match (r) {
    case .Ok(value: i32) => { return value; }
    case .Err => { return -1; }
  }
  return -1;
}

fn Run() -> i32 {
  var seed: i32 = 40;
  Core.Print(Consume(IntResult.Ok(seed + 2)));
  Core.Print(Consume(IntResult.Err));
  return 0;
}
