// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Error handling: C++ exception interop (-fno-except config, calling throwing C++, exporting Carbon errors as std::expected/exceptions)
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   7
//   -1
// SKIP: MISSING (B3) — this body is the catching-import stage: designed FINAL as B3 in docs/design/error_handling.md#implementation-staging (decision F-006), but no `Core.Result` type exists under core/prelude/ (grep Result there hits only the arithmetic interfaces' `.Result` associated constants), toolchain/check/cpp/thunk.cpp has no catching/exception-capturing thunk path (its only exception-spec use is EST_BasicNoexcept on the placement-new helper, thunk.cpp:37), and nothing synthesizes `Cpp.Exception` anywhere in toolchain/check/cpp/. Un-SKIP (and uncomment the body) when B3's catching thunks + Core.Result + Cpp.Exception land. The B0 boundary contract (--cpp-exceptions flag, none mode, auto->catch, fenced terminate) is arbitrated by the sibling cpp_exceptions_*.carbon programs, not here.
//
// Write-tests-first stub. Intended future test: a throwing C++ function
// (imported via `import Cpp inline`, block shape from
// interop/cpp_operator_import_arithmetic.carbon) called from Carbon with
// the thrown exception surfaced as a Carbon-consumable error value
// (`Core.Result(T, Cpp.Exception)` per the catching-imports section of
// docs/design/error_handling.md) on the failure path and the plain value
// on the success path.

import Core library "io";
// import Cpp inline '''c++
// #include <stdexcept>
//
// inline int PositiveOrThrow(int n) {
//   if (n < 0) throw std::runtime_error("negative");
//   return n;
// }
// ''';

fn Run() -> i32 {
  // Intended body once B3 lands (catching-import shape and Ok/Err naming
  // per docs/design/error_handling.md "Catching imports:
  // Result(T, Cpp.Exception)" and decision F-006a):
  //   Core.Print(Cpp.PositiveOrThrow(7));
  //   let r: Core.Result(i32, Cpp.Exception) = Cpp.PositiveOrThrow(-2);
  //   match (r) {
  //     case .Ok(_) => { return 1; }
  //     case .Err(_) => { Core.Print(-1); }  // caught C++ exception
  //   }
  //   return 0;
  // Guard: fails loudly (exit 1 vs EXPECT-EXIT 0) if un-SKIPped before
  // C++ exception interop exists.
  return 1;
}
