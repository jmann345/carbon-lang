// CONFORMANCE-BULLET: Type system: Unions (un-discriminated) + C++ union mapping
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   42
//   42
// SKIP: un-discriminated unions are MISSING at every layer — no `union` token in toolchain/lex/token_kind.def (verified by grep), no parse/check support, and no design doc; C++ unions import only as opaque interop types, so neither a native Carbon union nor member access on an imported C++ union can be written today. Un-SKIP (and uncomment the body) when a union design + implementation land.
//
// Write-tests-first stub. Intended future test: declare a native Carbon
// un-discriminated union, write one member and read it back; then import a
// C++ union via `import Cpp inline` (block shape verbatim from
// interop/cpp_operator_import_arithmetic.carbon) and access its active
// member from Carbon, proving the C++ union mapping is more than opaque.
// The `union` declaration syntax below is a strawman pending the design.

import Core library "io";
// import Cpp inline '''c++
// union CppIntBytes {
//   int as_int;
//   unsigned char bytes[4];
// };
// ''';
//
// union IntOrFloat {
//   var i: i32;
//   var f: f64;
// }

fn Run() -> i32 {
  // Intended body once the feature lands:
  //   var u: IntOrFloat;
  //   u.i = 42;
  //   Core.Print(u.i);
  //   var c: Cpp.CppIntBytes;
  //   c.as_int = 42;
  //   Core.Print(c.as_int);
  //   return 0;
  // Guard: fails loudly (exit 1 vs EXPECT-EXIT 0) if un-SKIPped before
  // unions exist.
  return 1;
}
