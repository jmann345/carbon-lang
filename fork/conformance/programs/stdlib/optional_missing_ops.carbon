// CONFORMANCE-BULLET: Stdlib: Optional
// SKIP: known-missing slice of this PARTIAL bullet: Core.Optional is an unapproved placeholder API ("We don't have an approved design for an `Optional` type yet... The API here is a placeholder", core/prelude/types/optional.carbon:27-28) with no comparison support; on the arbiter toolchain `a == b` on two Optional(i32) values fails with "error: cannot access member of interface `Core.EqWith(Core.Optional(i32 as Core.OptionalStorage))` in type `Core.Optional(i32 as Core.OptionalStorage)` that does not implement that interface"
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   1
//
// Write-tests-first program for the missing slice of the Optional bullet
// (working slices: optional_basic.carbon, optional_pointer_niche.carbon).
// Un-SKIP once an approved Optional design lands with equality (an
// `Optional(T) as EqWith(Optional(T))` impl in
// core/prelude/types/optional.carbon). The error above was captured verbatim
// from carbon_toolchain-0.0.0-0.nightly.2026.07.19 `carbon compile`.

import Core library "io";

fn Run() -> i32 {
  var a: Core.Optional(i32) = Core.Optional(i32).Some(1);
  var b: Core.Optional(i32) = Core.Optional(i32).Some(1);
  // Missing: `Optional(T) as EqWith(Optional(T))`.
  Core.Print(if a == b then 1 else 0);
  return 0;
}
