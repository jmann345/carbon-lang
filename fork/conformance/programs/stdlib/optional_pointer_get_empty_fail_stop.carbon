// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Stdlib: Optional
// EXPECT-EXIT: -6
//
// `Get()` on an empty `Core.Optional(T*)`, the null-niche Optional that a
// nullable C++ pointer imports as, fails-stop instead of returning the null
// pointer (fork design F-015, docs/design/optional.md, the W-173 rule), so a
// `T*` obtained from an Optional is never null and dereferencing it needs no
// null check: the rule F-013's TY4 ("null is never a hole") states. One line
// on stderr, then `abort()`; -6 is SIGABRT as the runner reports it (the
// stdlib/slices_bounds_fail_stop.carbon precedent). No `EXPECT-STDOUT`:
// `abort()` does not flush stdio, and the `Core.Print` after the read makes a
// run that survives fail loudly (exit 0 != -6 -> RUN-FAIL).
//
// Hand-derived expectation (R16(d)): `Pick(-1)` returns `None()`, the null
// pointer, because `-1 > 0` is false, so `o.Get()` takes the fail-stop branch
// before the dereference and before any output.

import Core library "io";

fn Pick(x: i32, p: i32*) -> Core.Optional(i32*) {
  if (x > 0) {
    return Core.Optional(i32*).Some(p);
  }
  return Core.Optional(i32*).None();
}

fn Run() -> i32 {
  var n: i32 = 7;
  let o: Core.Optional(i32*) = Pick(-1, &n);
  let p: i32* = o.Get();
  Core.Print(*p);
  return 0;
}
