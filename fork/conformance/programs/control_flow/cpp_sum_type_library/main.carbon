// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Control flow: matching — sum-type consumption incl. std::variant/std::optional interop
// EXPECT-EXIT: 0

// SV-1 (fork/sumtype-interop/plan.md, fork decision F-020), through a Carbon
// library: source.carbon converts the C++ `std::optional<int>` and
// `std::variant<int, bool>` it imports to `Core.CppCompat.StdOptional(i32)`
// and `StdVariant2(i32, bool)` at its API, and this unit, which imports no
// C++ (an imported C++ class does not cross a Carbon library, W-047), matches
// the Carbon sum types, exhaustively and without `default`. Payloads are
// computed at run time (R16d). Differential pair: main.diff.cpp (DIFF-1).

import library "source";
import Core library "io";

fn Seed(x: i32) -> i32 { return x - 3; }

fn Run() -> i32 {
  match (Fetch(Seed(9))) {
    case .Some(value: i32) => {
      Core.Print(value);
    }
    case .None => {
      Core.Print(-1);
    }
  }
  match (Fetch(Seed(1))) {
    case .Some(value: i32) => {
      Core.Print(value);
    }
    case .None => {
      Core.Print(-1);
    }
  }
  match (Classify(Seed(10))) {
    case .Alt0(count: i32) => {
      Core.Print(count);
    }
    case .Alt1(flag: bool) => {
      if (flag) {
        Core.Print(1);
      } else {
        Core.Print(0);
      }
    }
  }
  match (Classify(Seed(3))) {
    case .Alt0(count: i32) => {
      Core.Print(count);
    }
    case .Alt1(flag: bool) => {
      if (flag) {
        Core.Print(-2);
      } else {
        Core.Print(-3);
      }
    }
  }
  return 0;
}
