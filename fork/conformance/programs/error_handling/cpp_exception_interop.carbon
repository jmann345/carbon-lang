// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Error handling: C++ exception interop (-fno-except config, calling throwing C++, exporting Carbon errors as std::expected/exceptions)
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   7
//   -1
//
// The B3 catching-import arbiter (docs/design/error_handling.md "Catching
// imports: `Result(T, Cpp.Exception)`"; decision F-006; fork/eh/plan.md
// §5.B.1), un-SKIPped at EH-B. A throwing C++ function is called from Carbon
// twice: plainly (the fenced thunk, success path — prints `7`) and through
// `?` in a `Core.Result(i32, Cpp.Exception)` helper, where the runtime input
// `RuntimeSeed(-22)` = -2 makes it throw; the catching thunk turns the
// exception into the `.Err` alternative, which `match` observes (prints `-1`).
// Exit-code belt: the `.Ok` arm returns 1, so a `?` that wrongly continued
// with a value fails by exit code, not just stdout.
//
// Mechanical repair of the write-tests-first stub, disclosed per R6: the
// stub's intended body used the ANNOTATED-BINDING context
// (`let r: Core.Result(i32, Cpp.Exception) = Cpp.PositiveOrThrow(-2);`),
// which is the residue item "catching-import selection in binding/argument
// contexts" (fork/eh/plan.md D-EH-4: the checker has no expected-type
// channel); the 0.1 selection surface is `?` applied directly to the call,
// so the call is routed through the one-line `Checked` helper. The
// leading-period `.Ok(...)` shorthand of the stub is spelled
// `Core.Result(T, E).Ok(...)` as in every EH-A program.

import Core library "io";
import Cpp inline '''c++
#include <stdexcept>

inline int PositiveOrThrow(int n) {
  if (n < 0) throw std::runtime_error("negative");
  return n;
}
''';

// `?` directly on the C++ call selects the catching thunk: a thrown exception
// becomes `.Err(Cpp.Exception)` and propagates; a returned value continues.
fn Checked(n: i32) -> Core.Result(i32, Cpp.Exception) {
  return Core.Result(i32, Cpp.Exception).Ok(Cpp.PositiveOrThrow(n)?);
}

fn RuntimeSeed(x: i32) -> i32 { return x + 20; }

fn Run() -> i32 {
  // Success path, fenced call: 7.
  Core.Print(Cpp.PositiveOrThrow(RuntimeSeed(-13)));
  // Failure path: -2 throws; the exception is caught into `.Err`.
  match (Checked(RuntimeSeed(-22))) {
    case .Ok(v: i32) => { v; return 1; }
    case .Err(e: Cpp.Exception) => { e; Core.Print(-1); }  // caught C++ exception
  }
  return 0;
}
