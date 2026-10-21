// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Control flow: matching — sum-type consumption incl. std::variant/std::optional interop
// EXPECT-EXIT: 0

// SV-1 (fork/sumtype-interop/plan.md D-SV-7, W-177): a `Core.Optional(T)`
// scrutinee is matched as its view `Core.CppCompat.StdOptional(T)`, the
// docs/design/sum_types.md `Optional(T)` choice, converted by value through
// `HasValue()` and `Get()`; the class itself is unchanged. Covered, every
// payload computed at run time (R16d): `Core.Optional(i32)` in both states,
// exhaustively and without `default`; `Core.Optional(i32*)`, whose `None` is
// the null pointer, so `.Some` binds a non-null `i32*`; `if`-`let`; and a
// second payload type, `Core.Optional(i64)`. A symbolic payload type is not
// matched in 0.1 (W-177, narrowed). Differential pair:
// match_core_optional_diff.diff.cpp, the same values in `std::optional`
// (DIFF-1).

import Core library "io";

fn Seed(x: i32) -> i32 { return x * 3 - 4; }

fn MaybePositive(n: i32) -> Core.Optional(i32) {
  if (n > 0) {
    return Core.Optional(i32).Some(n);
  }
  return Core.Optional(i32).None();
}

fn Show(o: Core.Optional(i32)) {
  match (o) {
    case .Some(value: i32) => {
      Core.Print(value);
    }
    case .None => {
      Core.Print(-1);
    }
  }
}

fn ShowPointer(p: Core.Optional(i32*)) {
  match (p) {
    case .Some(q: i32*) => {
      Core.Print(*q);
    }
    case .None => {
      Core.Print(0);
    }
  }
}

fn MaybeWide(n: i32) -> Core.Optional(i64) {
  if (n > 0) {
    return Core.Optional(i64).Some(n);
  }
  return Core.Optional(i64).None();
}

fn CountSome(o: Core.Optional(i64)) -> i32 {
  match (o) {
    case .Some(unused value: i64) => {
      return 1;
    }
    case .None => {
      return 0;
    }
  }
  return -1;
}

fn Run() -> i32 {
  Show(MaybePositive(Seed(5)));
  Show(MaybePositive(Seed(1)));
  var cell: i32 = Seed(7);
  ShowPointer(Core.Optional(i32*).Some(&cell));
  ShowPointer(Core.Optional(i32*).None());
  if (let .Some(value: i32) = MaybePositive(Seed(4))) {
    Core.Print(value + 100);
  }
  Core.Print(CountSome(MaybeWide(Seed(2))));
  Core.Print(CountSome(MaybeWide(Seed(-2))));
  return 0;
}
