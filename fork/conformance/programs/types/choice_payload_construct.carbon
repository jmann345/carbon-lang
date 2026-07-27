// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Type system: Sum types (discriminated unions)
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   2
//   0
//   1
//   0
//   1
//
// W5 slice 1 arbiter: payload-alternative construction is runtime-observable
// through the discriminant. `Signal.Go(...)` is a function-like payload
// alternative (docs/design/sum_types.md:69-76); constructing it must write a
// discriminant distinct from the payload-free constants `Stop`/`Wait`, which
// `match` observes via leading-dot payload-free alternative patterns
// (`case .Stop`, SF-4: leading-dot only) plus `default` (exhaustiveness
// arrives in slice 2 per SF-7). Payload *values* are not observable until
// slice 2 binding patterns land; the payload argument is runtime-computed
// anyway so a constant-folding shortcut cannot fake construction (R16d).
// Expected prints derive from the source: Classify returns 0 for Stop,
// 1 for Wait, 2 otherwise (Go); IsOff returns 1 for Off, 0 otherwise (On) —
// per docs/design/pattern_matching.md first-match semantics.
//
// `Toggle.On()` additionally pins the SF-3 outcome: a zero-payload
// alternative declared with `()` is function-like — constructed by calling.

import Core library "io";

choice Signal {
  Go(speed: i32),
  Stop,
  Wait
}

choice Toggle {
  On(),
  Off
}

fn Classify(s: Signal) -> i32 {
  match (s) {
    case .Stop => { return 0; }
    case .Wait => { return 1; }
    default => { return 2; }
  }
  // Unreachable: every arm returns.
  return -1;
}

fn IsOff(t: Toggle) -> i32 {
  match (t) {
    case .Off => { return 1; }
    default => { return 0; }
  }
  return -1;
}

fn RuntimeSpeed(x: i32) -> i32 { return x + 40; }

fn Run() -> i32 {
  // `go` is a call-initialized local `var`: it initializes in place and its
  // scope exit executes the destroy-witness path for a payload-carrying
  // choice repr (plan risk R-5). The constant-initialized locals use `let`:
  // initializing a `var` from a class *value* would require a `Copy` impl,
  // which choices do not have.
  var go: Signal = Signal.Go(RuntimeSpeed(2));
  let stop: Signal = Signal.Stop;
  let wait: Signal = Signal.Wait;
  Core.Print(Classify(go));
  Core.Print(Classify(stop));
  Core.Print(Classify(wait));
  Core.Print(IsOff(Toggle.On()));
  Core.Print(IsOff(Toggle.Off));
  return 0;
}
