// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Error handling: C++ exception interop (-fno-except config, calling throwing C++, exporting Carbon errors as std::expected/exceptions)
// EXPECT-EXIT: 0
//
// Differential pair — the throw-path value lock that B0's
// cpp_exceptions_fence_value_diff.carbon deferred to B3 (fork/eh/plan.md
// §5.B.2). The C++ helper `CheckedScale(value, factor)` is byte-identical to
// the one in cpp_exception_catch_diff.diff.cpp and throws
// `std::invalid_argument` on `factor == 0`. This program calls it from Carbon
// through `?` in a `Core.Result(i32, Cpp.Exception)` helper (the catching
// thunk of docs/design/error_handling.md "Catching imports"), printing `1` and
// the value on success and `0`, `-1` when the exception was caught; the oracle
// wraps the same native call in `try { ... } catch (const
// std::invalid_argument&) { ... }`. Byte-identical stdout and exit code are
// required per DIFF-1; no EXPECT-STDOUT — C++ computes the expectation. The
// factor is runtime-selected (`RuntimeSeed(x) = x + 20`, R16d) so the throw
// cannot be folded away. Hand-derived, both sides: factor 3 → `1`, `63`;
// factor 0 → `0`, `-1`; value -7, factor 5 → `1`, `-35`.

import Core library "io";
import Cpp inline '''c++
#include <stdexcept>

// Throws on a zero factor; the runtime-selected probe below takes that path.
inline auto CheckedScale(int value, int factor) -> int {
  if (factor == 0) {
    throw std::invalid_argument("zero factor");
  }
  return value * factor;
}
''';

// `?` directly on the C++ call: the catching thunk turns a thrown exception
// into `.Err(Cpp.Exception)`.
fn Scale(value: i32, factor: i32) -> Core.Result(i32, Cpp.Exception) {
  return Core.Result(i32, Cpp.Exception).Ok(Cpp.CheckedScale(value, factor)?);
}

fn Probe(value: i32, factor: i32) {
  match (Scale(value, factor)) {
    case .Ok(v: i32) => {
      Core.Print(1);
      Core.Print(v);
    }
    case .Err(e: Cpp.Exception) => {
      e;
      Core.Print(0);
      Core.Print(0 - 1);
    }
  }
}

fn RuntimeSeed(x: i32) -> i32 { return x + 20; }

fn Run() -> i32 {
  Probe(21, RuntimeSeed(-17));
  Probe(21, RuntimeSeed(-20));
  Probe(RuntimeSeed(-27), 5);
  return 0;
}
