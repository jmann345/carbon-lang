// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Project: toolchain implements most 0.1 language features incl. C++ interop without undermining evaluation
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   10
//   20
//   30
//
// The program a "most 0.1 language features" toolchain must run: a C/C++
// `switch` equivalent via `match` with a literal case, a guarded binding
// pattern, and `default`. The guarded-binding and `default` shapes are
// verbatim from toolchain/parse/testdata/match/match.carbon:16-17
// (`case a: i32 if (a != x) =>`, `default =>`). Expected semantics per
// docs/design/pattern_matching.md: first matching case wins, the binding
// is in scope in the guard, and a failed guard falls through to the next
// arm. Un-SKIPped at S2d (match re-platform, fork/match-replatform/plan.md
// §3.4), which discharged this PARTIAL bullet's former reproducible
// representative — match-beyond-guards. Remaining siblings of the PARTIAL
// bullet keep their own SKIP evidence in their own programs:
// template-dependent lowering CARBON_FATALs at lower/handle.cpp
// splice_inst (generics/templates_dependent_member.carbon), and variadics
// (generics/variadics_each.carbon).

import Core library "io";

fn Classify(n: i32) -> i32 {
  match (n) {
    case 0 => { return 10; }
    case a: i32 if (a < 0) => { return 20; }
    default => { return 30; }
  }
  return -1;
}

fn Run() -> i32 {
  Core.Print(Classify(0));
  Core.Print(Classify(-7));
  Core.Print(Classify(42));
  return 0;
}
