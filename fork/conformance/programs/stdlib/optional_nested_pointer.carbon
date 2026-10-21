// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Stdlib: Optional
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
// the objects (1). W-171 landed at OP-2 (fork/optional2/plan.md), and the
// body is unchanged.

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
