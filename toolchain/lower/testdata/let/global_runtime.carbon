// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/int.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/let/global_runtime.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/let/global_runtime.carbon

// File-scope `let` bindings bound to RUNTIME values (W-069 half (a)): the
// bound value's copy-of-object-representation (scalar) value is promoted to a
// named backing global — `_C<name>.<package>` — that `__global_init` stores
// once, mirroring how `var` exports `VarStorage` globals
// (lower/testdata/var/import.carbon). Same-file cross-function references and
// importing files both load from that one symbol. The slice's PR-diff audit
// obligation: every OTHER existing `let` golden stays byte-identical —
// constant-bound `let`s keep riding the constant path, never these globals.

// --- scalar.carbon

library "[[@TEST_NAME]]";

fn Seed() -> i32 { return 42; }

let x: i32 = Seed();

fn Use() -> i32 { return x; }

// --- import_scalar.carbon

library "[[@TEST_NAME]]";

import library "scalar";

fn UseImported() -> i32 { return x; }

// --- reexport.carbon

library "[[@TEST_NAME]]";

export import library "scalar";

// --- import_reexport.carbon

library "[[@TEST_NAME]]";

import library "reexport";

// A defines the runtime `let`, B re-exports it, this file imports B: the
// canonical resolution (SemIR::GetCanonicalFileAndInstId) must land on A's
// defining binding — ONE `_Cx.Main` symbol across the whole chain, never a
// symbol mangled against B's IR.
fn UseReexported() -> i32 { return x; }

// --- tuple_pattern.carbon

library "[[@TEST_NAME]]";

fn MakePair() -> (i32, i32) { return (1, 2); }

// Both bindings are promoted independently (per-binding globals), fed from
// one tuple temporary in `__global_init`.
let (a: i32, b: i32) = MakePair();

fn UseA() -> i32 { return a; }

// --- import_tuple_pattern.carbon

library "[[@TEST_NAME]]";

import library "tuple_pattern";

fn UseB() -> i32 { return b; }

// --- empty.carbon

library "[[@TEST_NAME]]";

fn MakeEmpty() -> () { return (); }

// Empty value representation: NO `_Ce` global may appear in this module;
// references are served as the empty value.
let e: () = MakeEmpty();

fn UseE() -> () { return e; }

// --- let_ref.carbon

library "[[@TEST_NAME]]";

var v: i32 = 1;

// A `let ref` is a reference-category binding: excluded from promotion — no
// `_Cr` global may appear; the reference rides the variable's own storage.
let ref r: i32 = v;

fn UseR() -> i32 { return r; }
