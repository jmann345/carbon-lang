// CONFORMANCE-BULLET: Error handling: dedicated control flow constructs
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   42
//   -1
// SKIP: MISSING and undesigned — docs/design/README.md:3831: "Carbon does not have language features dedicated to error handling"; no try/throw tokens or parser states exist anywhere in the toolchain, so the error-propagation syntax below is a strawman to be replaced by the accepted design. Un-SKIP (and uncomment the body) when W2 delivers an accepted error-handling design and it is implemented.
//
// Write-tests-first stub. Intended future test: a fallible function whose
// error propagates through a dedicated construct (spelled `try` below as a
// strawman) rather than through manual sum-type plumbing, with both the
// success path and the propagated-error path observable at runtime. Today
// the only expressible pattern is hand-rolled choice/Optional returns
// (types/choice_basic.carbon, stdlib/optional_basic.carbon) with no
// language support for propagation.

import Core library "io";

// choice ParseError {
//   BadDigit
// }
//
// fn ParsePositive(n: i32) -> i32 or ParseError {
//   if (n < 0) { return error ParseError.BadDigit; }
//   return n;
// }
//
// fn Doubled(n: i32) -> i32 or ParseError {
//   // Dedicated propagation construct: on error, return it to the caller.
//   let v: i32 = try ParsePositive(n);
//   return v * 2;
// }

fn Run() -> i32 {
  // Intended body once the feature lands (strawman syntax):
  //   match (Doubled(21)) {
  //     case .ok(let v: i32) => { Core.Print(v); }         // 42
  //     case .error(_) => { return 1; }
  //   }
  //   match (Doubled(-3)) {
  //     case .ok(_) => { return 1; }
  //     case .error(_) => { Core.Print(-1); }              // propagated
  //   }
  //   return 0;
  // Guard: fails loudly (exit 1 vs EXPECT-EXIT 0) if un-SKIPped before
  // dedicated error-handling control flow exists.
  return 1;
}
