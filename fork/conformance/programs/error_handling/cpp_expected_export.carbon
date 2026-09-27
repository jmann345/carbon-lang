// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Error handling: C++ exception interop (-fno-except config, calling throwing C++, exporting Carbon errors as std::expected/exceptions)
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   10
//   3
//   1
//   9
//
// The `Carbon::expected` export arbiter (docs/design/error_handling.md
// "Exporting fallible Carbon functions: `Carbon::expected`"; decisions F-006h
// and D8; fork/eh/plan.md §5.B.3). Carbon functions returning
// `Core.Result(i32, i32)` and `Core.Result((), i32)` are exported into the
// `Carbon::` namespace and consumed by C++ that includes the REAL support
// header `<carbon/expected.h>` from the toolchain install tree
// (`lib/carbon/include`, added to the system include path by
// toolchain/base/clang_invocation.cpp) as `Carbon::expected<int, int>` and
// `Carbon::expected<void, int>`. The header mirrors the choice layout, so
// reading `value()`/`error()` in C++ observes exactly the bytes Carbon wrote
// — a wrong offset would print garbage, never these values (fork/eh/plan.md
// §7 R-7). Inputs are runtime-selected (`RuntimeSeed(x) = x + 20`, R16d);
// hand-derived: `Parse(5)` = Ok(5) → 10; `Parse(-3)` = Err(3) → 3;
// `Check(4)` = Ok(()) → 1; `Check(9)` = Err(9) → 9. Export shape from
// interop/cpp_export_function.carbon.

import Core library "io";
import Cpp;

// `.Err(-n)` for a negative input.
fn Parse(n: i32) -> Core.Result(i32, i32) {
  if (n < 0) { return Core.Result(i32, i32).Err(0 - n); }
  return Core.Result(i32, i32).Ok(n);
}

// `.Ok(())` for an even input, `.Err(n)` for an odd one.
fn Check(n: i32) -> Core.Result((), i32) {
  if ((n / 2) * 2 == n) { return Core.Result((), i32).Ok(()); }
  return Core.Result((), i32).Err(n);
}

inline Cpp '''
#include <carbon/expected.h>

inline int Consume(int n) {
  Carbon::expected<int, int> r = Carbon::Parse(n);
  return r.has_value() ? r.value() * 2 : r.error();
}

inline int ConsumeUnit(int n) {
  Carbon::expected<void, int> r = Carbon::Check(n);
  return r ? 1 : r.error();
}
''';

fn RuntimeSeed(x: i32) -> i32 { return x + 20; }

fn Run() -> i32 {
  Core.Print(Cpp.Consume(RuntimeSeed(-15)));
  Core.Print(Cpp.Consume(RuntimeSeed(-23)));
  Core.Print(Cpp.ConsumeUnit(RuntimeSeed(-16)));
  Core.Print(Cpp.ConsumeUnit(RuntimeSeed(-11)));
  return 0;
}
