// CONFORMANCE-BULLET: Generics: Template-style structural conformance to nominal constraints
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   42
// SKIP: MISSING at both layers — "structural conformance" appears nowhere in the toolchain, and the templates design doc does not concretely design it: neither design nor implementation exists, so today a `template T:! I` parameter still requires the argument type to nominally `impl as I`. Un-SKIP (and uncomment the body) when W7 (integrated templates completion + structural conformance) lands.
//
// Write-tests-first stub. Intended future test: a class that provides a
// method with the right name/signature but declares NO nominal `impl as` for
// the interface, passed to a template-parameterized function constrained on
// that interface (template parameter shape from
// generics/templates_type_param.carbon). Template-style structural
// conformance means the call must be accepted — the structure of the type
// satisfies the nominal constraint — and dispatch to the structural method
// at runtime.

import Core library "io";

// interface HasGet {
//   fn Get[self: Self]() -> i32;
// }
//
// class StructuralOnly {
//   // Note: deliberately NO `impl as HasGet` — the method alone must
//   // satisfy the constraint for a template parameter.
//   fn Get[self: Self]() -> i32 { return 42; }
// }
//
// fn CallGet[template T:! HasGet](x: T) -> i32 {
//   return x.Get();
// }

fn Run() -> i32 {
  // Intended body once the feature lands:
  //   var s: StructuralOnly = {};
  //   Core.Print(CallGet(s));
  //   return 0;
  // Guard: fails loudly (exit 1 vs EXPECT-EXIT 0) if un-SKIPped before
  // structural conformance exists.
  return 1;
}
