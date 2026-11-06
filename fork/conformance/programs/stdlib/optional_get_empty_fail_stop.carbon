// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Stdlib: Optional
// EXPECT-EXIT: -6
//
// `Get()` on an empty `Core.Optional(T)` fails-stop (fork design F-015,
// docs/design/optional.md, the W-173 rule): one line on stderr
// (`carbon: Core.Optional.Get on an empty value; terminating`), then
// `abort()`, as a `Core.Slice` bounds violation does
// (stdlib/slices_bounds_fail_stop.carbon, D-SL-4). SIGABRT is 6 on Linux and
// macOS, and the runner reports death by signal N as -N, so -6 is the whole
// observable. Deliberately no `EXPECT-STDOUT`: `abort()` does not flush
// stdio. The `Core.Print(v)` after the read makes a run that survives the
// empty `Get()` fail loudly (exit 0 != -6 -> RUN-FAIL).
//
// Hand-derived expectation (R16(d)): `Pick(-1)` returns `None()` because
// `-1 > 0` is false, so `o.HasValue()` is false and `o.Get()` takes the
// fail-stop branch before any output.

import Core library "io";

fn Pick(x: i32) -> Core.Optional(i32) {
  if (x > 0) {
    return Core.Optional(i32).Some(x);
  }
  return Core.Optional(i32).None();
}

fn Run() -> i32 {
  let o: Core.Optional(i32) = Pick(-1);
  let v: i32 = o.Get();
  Core.Print(v);
  return 0;
}
