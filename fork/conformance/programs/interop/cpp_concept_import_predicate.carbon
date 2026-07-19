// CONFORMANCE-BULLET: Generics: C++ interop — C++20 concepts <-> named predicates mapping
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   0
//   1
// SKIP: harness limitation, not a feature gap: `carbon compile` defaults the C++ importer to C++17 (probed on nightly 2026.07.19: `#if __cplusplus >= 202002L` is false, 201703L is picked), so the `concept` declaration below fails with: error: unknown type name 'concept' — it needs `--clang-arg=-std=c++20` (exactly what check/testdata/interop/cpp/template/concept.carbon passes via EXTRA-ARGS), and runner.py's fixed compile line (compile --output=... --output-last-input-only <file>) passes no clang args; this exact body was verified end-to-end by hand with that one flag added: compile + link + run prints 0 then 1 and exits 0 on this arbiter toolchain.
//
// The working slice of this PARTIAL bullet: a C++20 concept imports into
// Carbon as a named compile-time predicate. `Cpp.IsLarge(T)` is evaluated at
// compile time to a `bool` and used as an argument to a Carbon generic class
// (shape verbatim from check/testdata/interop/cpp/template/concept.carbon:
// `X(Cpp.IsLarge(Cpp.Small))` / `X(Cpp.IsLarge(Cpp.Large))`), then made
// observable at runtime by printing the selected specific's value: Small (1
// byte) fails the predicate -> 0, Large (8 bytes) satisfies it -> 1. Promote
// this program out of SKIP when the harness (or the importer's default
// standard) reaches C++20.

import Core library "io";
import Cpp inline '''
struct Small {};
struct Large { int a; int b; };
template<typename T> concept IsLarge = sizeof(T) > 4;
''';

class Tag(B: bool) {
  fn Value() -> i32 { if (B) { return 1; } return 0; }
}

fn Run() -> i32 {
  Core.Print(Tag(Cpp.IsLarge(Cpp.Small)).Value());
  Core.Print(Tag(Cpp.IsLarge(Cpp.Large)).Value());
  return 0;
}
