// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Type system: Sum types (discriminated unions)
// EXPECT-EXIT: 0
//
// Differential pair — the W5 slice-1 discriminant lock (DIFF-1: the C++
// oracle is the only arbiter, no EXPECT-STDOUT). A Carbon `choice` with one
// payload alternative and two payload-free alternatives is classified by
// `match` over payload-free alternative patterns + `default`; the C++ side
// (choice_discriminant_diff.diff.cpp) holds the same three-state value in a
// `std::variant` and classifies via `index()`. The runner requires
// byte-identical exit code and stdout, so std::variant's discriminant
// semantics — construction selects exactly one alternative, observable as an
// index — are the oracle for the choice constructor writing the correct
// discriminant. Payload values stay unobserved on both sides (slice 2 binds
// them; the C++ side deliberately never calls std::get).
//
// Alternative order mirrors the variant's template-argument order, so the
// classification table (Stop -> 0, Wait -> 1, Go -> 2) is the same
// derivation on both sides.

import Core library "io";

choice Signal {
  Go(speed: i32),
  Stop,
  Wait
}

// C++ mirror: switch (s.index()) over std::variant<int, StopT, WaitT>.
fn Classify(s: Signal) -> i32 {
  match (s) {
    case .Stop => { return 0; }
    case .Wait => { return 1; }
    default => { return 2; }
  }
  return -1;
}

fn Run() -> i32 {
  // Runtime-computed payload argument, so constant folding cannot fake the
  // constructed value (R16d).
  var base: i32 = 55;
  var go: Signal = Signal.Go(base + 5);
  let stop: Signal = Signal.Stop;
  let wait: Signal = Signal.Wait;
  Core.Print(Classify(go));
  Core.Print(Classify(stop));
  Core.Print(Classify(wait));
  return 0;
}
