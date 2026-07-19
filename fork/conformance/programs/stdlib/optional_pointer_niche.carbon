// CONFORMANCE-BULLET: Stdlib: Optional
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   42
//   -1
//   5
//   1
//
// Pointer-niche slice of the (PARTIAL) Optional bullet: `Optional(T*)` uses
// the null pointer as its `None` representation (`final impl forall
// [T: type] T* as OptionalStorage` with "pointer.make_null" /
// "pointer.is_null" builtins, core/prelude/types/optional.carbon:156-179),
// making it ABI-compatible with a C++ nullable pointer. Same shapes as
// toolchain/lower/testdata/primitives/optional.carbon (`fn Convert(o:
// Core.Optional(i32*))` with `*o.Get()`). Also mutates through the stored
// pointer and exercises the implicit `T* -> Optional(T*)` conversion.

import Core library "io";

fn DerefOr(o: Core.Optional(i32*), fallback: i32) -> i32 {
  if (o.HasValue()) {
    return *o.Get();
  }
  return fallback;
}

fn Run() -> i32 {
  var n: i32 = 42;
  var some: Core.Optional(i32*) = Core.Optional(i32*).Some(&n);
  var none: Core.Optional(i32*) = Core.Optional(i32*).None();
  Core.Print(DerefOr(some, -1));
  Core.Print(DerefOr(none, -1));

  // Write through the pointer held by the Optional.
  *some.Get() = 5;
  Core.Print(n);

  // Implicit conversion i32* -> Optional(i32*): non-null pointer => Some.
  var p: i32* = &n;
  var conv: Core.Optional(i32*) = p;
  Core.Print(if conv.HasValue() then 1 else 0);
  return 0;
}
