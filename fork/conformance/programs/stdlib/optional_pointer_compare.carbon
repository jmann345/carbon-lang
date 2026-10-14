// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Stdlib: Optional
// SKIP: known-missing slice of W-174 (filed under "Stdlib: pointer types"; it does not bound this bullet's row, fork/optional/plan.md D-OP-13): `Core.Optional(T*)` compares exactly when `T*` is `Core.Eq` (the conditional `Optional(T) as EqWith(Optional(T))` impl, core/prelude/types/optional.carbon, OP-1), and the prelude gives the built-in pointer type `i32*` no `==` (no `T* as EqWith(T*)` impl in core/prelude, and docs/design/expressions/comparison_operators.md:479-505 gives no pointer comparison); `a == b` on two Core.Optional(i32*) values fails with "error: cannot access member of interface `Core.EqWith(Core.Optional(i32* as Core.OptionalStorage))` in type `Core.Optional(i32* as Core.OptionalStorage)` that does not implement that interface" (W-174)
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   1
//   0
//   1
//   0
//
// Write-tests-first program for the pointer-niche slice of the Optional
// bullet (working slices: optional_pointer_niche.carbon,
// optional_compare_diff.carbon). A user library can already make
// `Core.Optional(C*)` compare for its own class `C` by implementing
// `C* as Core.EqWith(C*)`; `i32*` belongs to no user library, so only the
// prelude can give it `==`. Un-SKIP when W-174 gives `T*` an `EqWith(T*)` impl
// that compares addresses; the body then needs no change.
// Expected, from F-015's rules with address equality: two `Some` values
// holding the address of `n` are equal (1); `Some(&n)` and `Some(&m)` differ
// although `n` and `m` hold the same value (0); two empty values are equal
// (1); an empty value differs from `Some(&n)` (0).

import Core library "io";

fn B(b: bool) -> i32 { return if b then 1 else 0; }

fn Run() -> i32 {
  var n: i32 = 1;
  var m: i32 = 1;
  let some_n: Core.Optional(i32*) = Core.Optional(i32*).Some(&n);
  let some_n_again: Core.Optional(i32*) = Core.Optional(i32*).Some(&n);
  let some_m: Core.Optional(i32*) = Core.Optional(i32*).Some(&m);
  let none: Core.Optional(i32*) = Core.Optional(i32*).None();
  Core.Print(B(some_n == some_n_again));
  Core.Print(B(some_n == some_m));
  Core.Print(B(none == Core.Optional(i32*).None()));
  Core.Print(B(none == some_n));
  return 0;
}
