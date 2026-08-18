// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/int.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/let/global_runtime.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/let/global_runtime.carbon

// File-scope `let` bindings bound to RUNTIME values (W-069 half (a)): these
// check cleanly today — the binding lives in the file's top block, its bound
// value inside `__global_init` — and this golden pins that SemIR shape so the
// lowering-side promotion mechanism needs no check change. The slice's PR-diff
// audit obligation: every EXISTING check golden under toolchain/**/testdata
// stays byte-identical (constant-bound `let`s keep riding the constant path —
// see check/testdata/let/import.carbon's `[concrete = ...]` import pins).

// --- scalar.carbon

library "[[@TEST_NAME]]";

fn Seed() -> i32 { return 42; }

let x: i32 = Seed();

// A same-file cross-function reference: the bound value is a local of
// `__global_init`, not of `Use`, so this reference needs the same promotion
// mechanism as the cross-file case.
fn Use() -> i32 { return x; }

// --- import_scalar.carbon

library "[[@TEST_NAME]]";

import library "scalar";

// The importer's `import_ref` for `x` loads with no `[concrete = ...]`
// constant — the NotConstant signature of the W-069 residue (contrast the
// constant-bound pins in check/testdata/let/import.carbon).
fn UseImported() -> i32 { return x; }

// --- reexport.carbon

library "[[@TEST_NAME]]";

export import library "scalar";

// --- import_reexport.carbon

library "[[@TEST_NAME]]";

import library "reexport";

// A defines the runtime `let`, B re-exports it, this file imports B: the
// lowering-side canonical resolution (SemIR::GetCanonicalFileAndInstId) must
// land on A's defining binding so both sides mint one symbol.
fn UseReexported() -> i32 { return x; }

// --- tuple_pattern.carbon

library "[[@TEST_NAME]]";

fn MakePair() -> (i32, i32) { return (1, 2); }

// A runtime tuple-pattern `let`: each binding is promoted independently.
let (a: i32, b: i32) = MakePair();

fn UseA() -> i32 { return a; }

// --- import_tuple_pattern.carbon

library "[[@TEST_NAME]]";

import library "tuple_pattern";

fn UseB() -> i32 { return b; }

// --- empty.carbon

library "[[@TEST_NAME]]";

fn MakeEmpty() -> () { return (); }

// An empty-tuple-typed runtime `let`: the value representation is `None`, so
// no backing storage is ever minted; references are served as the empty
// value.
let e: () = MakeEmpty();

fn UseE() -> () { return e; }

// --- let_ref.carbon

library "[[@TEST_NAME]]";

var v: i32 = 1;

// A file-scope `let ref` is a REFERENCE-category binding, not a value
// binding: it is excluded from the runtime-`let` promotion predicate (its
// bound value is the variable's storage, a reference constant), and this
// subfile pins the shape the exclusion tests against.
let ref r: i32 = v;

fn UseR() -> i32 { return r; }
