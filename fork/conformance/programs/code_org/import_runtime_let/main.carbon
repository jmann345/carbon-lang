// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Code organization: Importing
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   23
//   24

// The W-069 split-file CROSS-FILE runtime arbiter (fork/w069/plan.md §4
// W69b) — the first multi-unit conformance program, riding the W69h
// directory convention: the "seeds" library unit binds file-scope `let`s to
// RUNTIME values (a scalar and a choice-typed one), and this main unit
// imports the library and consumes both bindings at runtime — the ledger
// acceptance shape (a cross-file runtime `let` reference) arbitrated by
// observable output, not just golden pins. Expectations derive from seed
// arithmetic (RuntimeSeed(x) = x + 20) independent of the binding chain
// under test: the library binds the scalar from RuntimeSeed(3) = 23 and the
// choice payload from RuntimeSeed(4) = 24. A zeroinit read (the defining
// unit's ctor never ran, or the importer resolved a wrong symbol) prints 0
// and fails loudly; `llvm.global_ctors` run before `main`, so the readers
// here are ordering-safe by construction.

import Core library "io";
import library "seeds";

fn Run() -> i32 {
  // The imported scalar binding: an external-global load in this unit.
  Core.Print(scalar_from_lib);
  // The imported choice-typed binding matched directly: the external
  // object-rep global's address is the scrutinee value, and the payload
  // rides back out.
  match (opt_from_lib) {
    case .Some(value: i32) => { Core.Print(value); }
    case .Nothing => { return 1; }
  }
  return 0;
}
