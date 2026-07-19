// CONFORMANCE-BULLET: Error handling: C++ exception interop (-fno-except config, calling throwing C++, exporting Carbon errors as std::expected/exceptions)
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   7
//   -1
// SKIP: MISSING — toolchain/base/clang_invocation.cpp contains no exception-handling configuration (no -fno-exceptions plumbing or per-TU exception mode), no design exists for calling throwing C++ from Carbon or exporting Carbon errors as std::expected/exceptions, and the interop philosophy doc disclaims seamless exception interop. Un-SKIP (and uncomment the body) when an exception-interop design + driver configuration land.
//
// Write-tests-first stub. Intended future test: a throwing C++ function
// (imported via `import Cpp inline`, block shape from
// interop/cpp_operator_import_arithmetic.carbon) called from Carbon with
// the thrown exception surfaced as a Carbon-consumable error value on the
// failure path and the plain value on the success path — plus, in a
// harness extension, the same program built under a -fno-except
// configuration where the throwing path is rejected or trapped per the
// accepted design.

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
  // Intended body once the feature lands (error-mapping syntax is a
  // strawman pending the design):
  //   Core.Print(Cpp.PositiveOrThrow(7));
  //   match (try Cpp.PositiveOrThrow(-2)) {
  //     case .ok(_) => { return 1; }
  //     case .error(_) => { Core.Print(-1); }  // caught C++ exception
  //   }
  //   return 0;
  // Guard: fails loudly (exit 1 vs EXPECT-EXIT 0) if un-SKIPped before
  // C++ exception interop exists.
  return 1;
}
