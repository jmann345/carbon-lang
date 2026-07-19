// CONFORMANCE-BULLET: Generics: Definition-checked variadics
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   6
//   0
// SKIP: DESIGN-ONLY — a complete 964-line accepted design exists (docs/design/variadics.md, proposal p002240) but there is zero implementation: no `...`/`each` tokens exist in toolchain/lex/token_kind.def (verified by grep), so any pack expansion fails at the lexer. Un-SKIP (and uncomment the body) when W6 (definition-checked variadics implementation) lands.
//
// Write-tests-first stub. Intended future test: a definition-checked
// variadic Sum whose parameter list binds a pack (`... each n: i64`) and
// whose body statement-expands it (`... total += each n;`) — syntax taken
// directly from the accepted design's pack-expansion forms
// (docs/design/variadics.md "Basics": `...` in a tuple-literal pattern
// iteratively matches, `...` in statement context iteratively executes).
// Called with three arguments and with zero arguments to prove both the
// n-ary and empty expansions execute.

import Core library "io";

// fn Sum(... each n: i64) -> i64 {
//   var total: i64 = 0;
//   ... total += each n;
//   return total;
// }

fn Run() -> i32 {
  // Intended body once the feature lands:
  //   Core.Print(Sum(1, 2, 3));
  //   Core.Print(Sum());
  //   return 0;
  // Guard: fails loudly (exit 1 vs EXPECT-EXIT 0) if un-SKIPped before
  // variadics are implemented.
  return 1;
}
