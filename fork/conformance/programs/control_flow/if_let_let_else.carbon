// CONFORMANCE-BULLET: Control flow: matching — if-let / let-else combined match+declaration
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   42
//   0
// SKIP: MISSING and not even designed — absent at every layer (no tokens, parse states, or check support) and absent from docs/design/pattern_matching.md; there is no accepted syntax for a combined match+declaration, so the `if (let ...)` / `let ... else` forms below are strawmen to be replaced by the accepted design. Un-SKIP (and uncomment the body) when an if-let/let-else design is accepted and implemented (depends on W4 match semantics).
//
// Write-tests-first stub. Intended future test: (1) if-let — a refutable
// pattern in an `if` that binds on success and falls through on failure;
// (2) let-else — a refutable `let` whose `else` block must diverge,
// leaving the binding in scope afterwards. Both consume a payload-carrying
// choice (choice shape from docs/design/sum_types.md), the canonical
// motivating type for these forms.

import Core library "io";

// choice MaybeInt {
//   Some(value: i32),
//   None
// }

fn Run() -> i32 {
  // Intended body once the feature lands (strawman syntax):
  //   var m: MaybeInt = MaybeInt.Some(42);
  //   // if-let: bind and use only on pattern success.
  //   if (let .Some(let v: i32) = m) {
  //     Core.Print(v);
  //   }
  //   // let-else: bind or diverge; `w` is in scope after the statement.
  //   let .Some(let w: i32) = m else { return 1; }
  //   Core.Print(w - 42);
  //   return 0;
  // Guard: fails loudly (exit 1 vs EXPECT-EXIT 0) if un-SKIPped before
  // if-let/let-else exist.
  return 1;
}
