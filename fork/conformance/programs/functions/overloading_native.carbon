// CONFORMANCE-BULLET: Functions: function overloading (Carbon-native)
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   1
//   2
// SKIP: MISSING with no design — docs/design/pattern_matching.md:696: "We do not yet have an approved design for overloaded functions"; there is no design and no implementation of Carbon-side overloading, so a second `fn Describe` with a different signature is rejected as a redeclaration today (only imported C++ overload sets work, per interop/cpp_overload_set_by_type.carbon). Un-SKIP (and uncomment the body) when an overloading design is accepted and implemented.
//
// Write-tests-first stub. Intended future test: two Carbon-native overloads
// of the same function name distinguished by parameter type, with call-site
// selection observable at runtime. The declaration shape below is the
// natural strawman; replace it with the accepted design's syntax when that
// exists.

import Core library "io";

// fn Describe(n: i32) -> i32 { return 1; }
// fn Describe(b: bool) -> i32 { return 2; }

fn Run() -> i32 {
  // Intended body once the feature lands:
  //   Core.Print(Describe(7));
  //   Core.Print(Describe(true));
  //   return 0;
  // Guard: fails loudly (exit 1 vs EXPECT-EXIT 0) if un-SKIPped before
  // Carbon-native overloading exists.
  return 1;
}
