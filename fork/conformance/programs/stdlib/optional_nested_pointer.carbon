// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Stdlib: Optional
// SKIP: known-missing slice of this PARTIAL bullet (W-171): `Get()` and the copy of a `Core.Optional(Core.Optional(U*))` read the default storage's `MaybeUnformed` field as the inner `Core.Optional(U*)` (core/prelude/types/optional.carbon:169-171 and :172-178), and the lowered storage `Get` passes that field's address where the inner value is expected, with no load (`MaybeUnformed(T)` and `T` differ in value representation, toolchain/check/convert.cpp:1687-1704, the `Core.Optional(bool)` defect); both sides are a `ptr`, so nothing aborts: compiled with OP-1 this program exits 0 printing 1, 1, 1, 0, 0 where EXPECT is 1, 0, 0, 1, 1 (on trunk the four lines before the `==` print the same, and `a == b` is "cannot access member of interface `Core.EqWith(Core.Optional(Core.Optional(C* as Core.OptionalStorage) as Core.OptionalStorage))`")
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   1
//   0
//   0
//   1
//   1
//
// Write-tests-first program for an Optional whose payload is a pointer-niche
// Optional, which fork design F-015 (docs/design/optional.md) gives the same
// API, copy and comparison rules as every other `Core.Optional(T)`.
// Expected, from F-015's rules: `Some(None)` holds a value (1) whose own value
// is empty (0), and so does a copy of it (0); reading through both levels of
// `Some(Some(&n))` reaches `n`, which holds 7 (1); and `a == b` compares the
// two inner `Core.Optional(C*)` values, which hold pointers to different
// objects with equal `v`, so it is `C*`'s own `==` on them, which compares
// the objects (1). Un-SKIP when W-171 lands; the body then needs no change.

import Core library "io";

class C {
  var v: i32;
}

// `C` is local, so this library may give `C*` an `==`; it compares the
// objects the pointers refer to.
impl C* as Core.EqWith(C*) {
  fn Equal(self, other: C*) -> bool { return self->v == other->v; }
  fn NotEqual(self, other: C*) -> bool { return self->v != other->v; }
}

fn B(b: bool) -> i32 { return if b then 1 else 0; }

fn Run() -> i32 {
  let none: Core.Optional(i32*) = Core.Optional(i32*).None();
  let some_none: Core.Optional(Core.Optional(i32*)) =
      Core.Optional(Core.Optional(i32*)).Some(none);
  Core.Print(B(some_none.HasValue()));
  Core.Print(B(some_none.Get().HasValue()));
  var copy: Core.Optional(Core.Optional(i32*)) = some_none;
  Core.Print(B(copy.Get().HasValue()));

  var n: i32 = 7;
  let some_n: Core.Optional(i32*) = Core.Optional(i32*).Some(&n);
  let some_some_n: Core.Optional(Core.Optional(i32*)) =
      Core.Optional(Core.Optional(i32*)).Some(some_n);
  Core.Print(B(*some_some_n.Get().Get() == 7));

  var c1: C = {.v = 4};
  var c2: C = {.v = 4};
  let a: Core.Optional(Core.Optional(C*)) =
      Core.Optional(Core.Optional(C*)).Some(Core.Optional(C*).Some(&c1));
  let b: Core.Optional(Core.Optional(C*)) =
      Core.Optional(Core.Optional(C*)).Some(Core.Optional(C*).Some(&c2));
  Core.Print(B(a == b));
  return 0;
}
