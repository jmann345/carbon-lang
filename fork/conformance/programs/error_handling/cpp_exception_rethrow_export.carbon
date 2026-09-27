// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Error handling: C++ exception interop (-fno-except config, calling throwing C++, exporting Carbon errors as std::expected/exceptions)
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   7
//   110
//
// The lossless round trip of a caught C++ exception (docs/design/
// error_handling.md "`Cpp.Exception`", design contract; decision D7;
// fork/eh/plan.md §5.B.4). C++ `Throws` throws `std::runtime_error("negative")`
// for a negative input; the Carbon function `Catching` calls it through `?`
// (the catching thunk stores the primary exception object pointer in
// `Cpp.Exception`) and is exported to C++ as
// `Carbon::expected<int, Carbon::Exception>` through the REAL
// `<carbon/expected.h>`. C++ `Recover` rethrows the stored exception with
// `Carbon::Exception::rethrow()` and catches it as `const std::runtime_error&`
// — the ORIGINAL object with its dynamic type — printing the first byte of
// its message: 'n' = 110. Inputs are runtime-selected (`RuntimeSeed(x) = x +
// 20`, R16d); hand-derived: `Recover(7)` → 7 (no throw); `Recover(-5)` →
// 110. The `return -1` after the handler is the belt: a rethrow that lost the
// dynamic type would fall through and print -1.

import Core library "io";
import Cpp inline '''c++
#include <stdexcept>

inline int Throws(int n) {
  if (n < 0) throw std::runtime_error("negative");
  return n;
}
''';

fn Catching(n: i32) -> Core.Result(i32, Cpp.Exception) {
  return Core.Result(i32, Cpp.Exception).Ok(Cpp.Throws(n)?);
}

inline Cpp '''
#include <carbon/expected.h>

#include <stdexcept>

inline int Recover(int n) {
  Carbon::expected<int, Carbon::Exception> r = Carbon::Catching(n);
  if (r) {
    return r.value();
  }
  try {
    r.error().rethrow();
  } catch (const std::runtime_error& e) {
    return e.what()[0];
  }
  return -1;
}
''';

fn RuntimeSeed(x: i32) -> i32 { return x + 20; }

fn Run() -> i32 {
  Core.Print(Cpp.Recover(RuntimeSeed(-13)));
  Core.Print(Cpp.Recover(RuntimeSeed(-25)));
  return 0;
}
