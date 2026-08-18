// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Control flow: matching — sum-type consumption incl. std::variant/std::optional interop
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   21
//   22

// The W-069 single-file runtime arbiter (fork/w069/plan.md §4 W69b): file-
// scope `let`s bound to RUNTIME values — one of a generic-choice specific,
// one scalar — are consumed across functions at runtime, arbitrating the
// whole promotion chain (backing global + `__global_init` store/memcpy
// ordering + readback) with observable output. Expectations derive from
// seed arithmetic (RuntimeSeed(x) = x + 20), independent of the binding
// chain under test: the payload seeds from RuntimeSeed(1) = 21 and the
// scalar from RuntimeSeed(2) = 22. A zeroinit read (ctor never ran, or a
// misrouted global) prints 0 and fails loudly; `llvm.global_ctors` run
// before `main`, so function-body readers are ordering-safe by
// construction.

import Core library "io";

choice Box(T: type) {
  Full(value: T),
  Empty
}

fn RuntimeSeed(x: i32) -> i32 { return x + 20; }

// Choice-typed runtime `let`: promoted to an object-representation global
// filled by a ctor memcpy (the W69b pointer-value-rep arm).
let boxed: Box(i32) = Box(i32).Full(RuntimeSeed(1));

// Scalar runtime `let`: promoted to a store/load global (the W69a arm).
let bias: i32 = RuntimeSeed(2);

// A cross-function scalar consumer: `bias` is initialized in
// `__global_init` and read here.
fn ReadBias() -> i32 { return bias; }

fn Run() -> i32 {
  // The payload readback: matching directly on the file-scope binding makes
  // the promoted global's address the scrutinee value.
  match (boxed) {
    case .Full(value: i32) => { Core.Print(value); }
    case .Empty => { return 1; }
  }
  Core.Print(ReadBias());
  return 0;
}
