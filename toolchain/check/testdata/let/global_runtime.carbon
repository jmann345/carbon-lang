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
// check cleanly — the binding lives in the file's top block, its bound value
// inside `__global_init` — and the `//@dump-sem-ir-begin`/`end` ranges
// (added at W69b, discharging the W69a fill-audit residue) pin that SemIR
// shape, not just clean checking: the binding wrapping a
// `@__global_init.`-qualified bound value, and the importer's
// `import_ref ... loaded` with NO `[concrete = ...]` constant. The slice's
// PR-diff audit obligation: every EXISTING check golden under
// toolchain/**/testdata stays byte-identical (constant-bound `let`s keep
// riding the constant path — see check/testdata/let/import.carbon's
// `[concrete = ...]` import pins).

// --- scalar.carbon

library "[[@TEST_NAME]]";

fn Seed() -> i32 { return 42; }

//@dump-sem-ir-begin
let x: i32 = Seed();
//@dump-sem-ir-end

// A same-file cross-function reference: the bound value is a local of
// `__global_init`, not of `Use`, so this reference needs the same promotion
// mechanism as the cross-file case.
//@dump-sem-ir-begin
fn Use() -> i32 { return x; }
//@dump-sem-ir-end

// --- import_scalar.carbon

library "[[@TEST_NAME]]";

import library "scalar";

// The importer's `import_ref` for `x` loads with no `[concrete = ...]`
// constant — the NotConstant signature of the W-069 residue (contrast the
// constant-bound pins in check/testdata/let/import.carbon).
//@dump-sem-ir-begin
fn UseImported() -> i32 { return x; }
//@dump-sem-ir-end

// --- reexport.carbon

library "[[@TEST_NAME]]";

export import library "scalar";

// --- import_reexport.carbon

library "[[@TEST_NAME]]";

import library "reexport";

// A defines the runtime `let`, B re-exports it, this file imports B: the
// lowering-side canonical resolution (SemIR::GetCanonicalFileAndInstId) must
// land on A's defining binding so both sides mint one symbol.
//@dump-sem-ir-begin
fn UseReexported() -> i32 { return x; }
//@dump-sem-ir-end

// --- tuple_pattern.carbon

library "[[@TEST_NAME]]";

fn MakePair() -> (i32, i32) { return (1, 2); }

// A runtime tuple-pattern `let`: each binding is promoted independently.
//@dump-sem-ir-begin
let (a: i32, b: i32) = MakePair();
//@dump-sem-ir-end

//@dump-sem-ir-begin
fn UseA() -> i32 { return a; }
//@dump-sem-ir-end

// --- import_tuple_pattern.carbon

library "[[@TEST_NAME]]";

import library "tuple_pattern";

//@dump-sem-ir-begin
fn UseB() -> i32 { return b; }
//@dump-sem-ir-end

// --- empty.carbon

library "[[@TEST_NAME]]";

fn MakeEmpty() -> () { return (); }

// An empty-tuple-typed `let`: the initializer runs at runtime, but the bound
// VALUE folds to the concrete empty tuple at check time, so references ride
// the constant path and no backing storage is ever minted.
//@dump-sem-ir-begin
let e: () = MakeEmpty();
//@dump-sem-ir-end

//@dump-sem-ir-begin
fn UseE() -> () { return e; }
//@dump-sem-ir-end

// --- let_ref.carbon

library "[[@TEST_NAME]]";

var v: i32 = 1;

// A file-scope `let ref` is a REFERENCE-category binding, not a value
// binding: it is excluded from the runtime-`let` promotion predicate (its
// bound value is the variable's storage, a reference constant), and this
// subfile pins the shape the exclusion tests against.
//@dump-sem-ir-begin
let ref r: i32 = v;
//@dump-sem-ir-end

//@dump-sem-ir-begin
fn UseR() -> i32 { return r; }
//@dump-sem-ir-end
