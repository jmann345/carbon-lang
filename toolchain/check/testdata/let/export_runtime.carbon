// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/int.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/let/export_runtime.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/let/export_runtime.carbon

// `export <name>;` of file-scope `let` bindings (W-074, fixed at W74a): a
// RUNTIME `let` exported by name mints an `ExportDecl` whose constant
// forwards the exported value's NotConstant (eval_inst.cpp), and the
// importer's resolution peeks through it (import_ref.cpp,
// `TryResolveInstCanonical`'s non-constant branch) instead of tripping the
// `Is<AnyBinding>` CHECK. Pins: the export file's `export x, ...` and every
// importer's `import_ref ... loaded` carry NO `[concrete = ...]` — the same
// NotConstant signature as a direct import of the binding
// (let/global_runtime.carbon's import_scalar subfile) — while the
// constant-bound boundary chain keeps its `[concrete = ...]` constants (the
// untouched constant path, contrast check/testdata/var/export_name.carbon).
// Lowering's canonical chase supplies the one backing symbol
// (lower/testdata/let/global_runtime.carbon's export_name subfiles).

// ============================================================================
// P-0 boundary: a CONSTANT-bound `let` exported by name rides the constant
// path — the fix must not touch it.
// ============================================================================

// --- const.carbon

library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
let c: i32 = 42;
//@dump-sem-ir-end

// --- export_const.carbon

library "[[@TEST_NAME]]";

import library "const";

//@dump-sem-ir-begin
export c;
//@dump-sem-ir-end

// --- use_export_const.carbon

library "[[@TEST_NAME]]";

import library "export_const";

//@dump-sem-ir-begin
fn UseConst() -> i32 { return c; }
//@dump-sem-ir-end

// ============================================================================
// P-1 crash shape: A binds a RUNTIME `let`, B does `export x;`, main imports
// B and reads `x`. Pre-fix this CHECK-crashed in the importer's resolution.
// ============================================================================

// --- scalar.carbon

library "[[@TEST_NAME]]";

fn Seed() -> i32 { return 42; }

//@dump-sem-ir-begin
let x: i32 = Seed();
//@dump-sem-ir-end

// --- export_name.carbon

library "[[@TEST_NAME]]";

import library "scalar";

//@dump-sem-ir-begin
export x;
//@dump-sem-ir-end

// --- import_export_name.carbon

library "[[@TEST_NAME]]";

import library "export_name";

//@dump-sem-ir-begin
fn UseExportName() -> i32 { return x; }
//@dump-sem-ir-end

// ============================================================================
// P-4 ApiForImpl route: the exporting library's own impl file reads its
// api's `export x;` (mirrors packages/export_name.carbon's
// export_export.impl.carbon shape).
// ============================================================================

// --- export_name.impl.carbon

impl library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn UseFromImpl() -> i32 { return x; }
//@dump-sem-ir-end

// ============================================================================
// P-2 chain depth: C's `export x;` of B's exported name (mirrors
// packages/export_name.carbon's export_export subfile). Pre-fix the crash
// fired per hop — C's own check loads B's `ExportDecl`.
// ============================================================================

// --- export_export_name.carbon

library "[[@TEST_NAME]]";

import library "export_name";

//@dump-sem-ir-begin
export x;
//@dump-sem-ir-end

// --- import_export_export_name.carbon

library "[[@TEST_NAME]]";

import library "export_export_name";

//@dump-sem-ir-begin
fn UseExportExportName() -> i32 { return x; }
//@dump-sem-ir-end

// ============================================================================
// P-5 dual-route merge: main imports the DEFINING library and the EXPORTING
// library, and reads one merged `x` (extends packages/export_name.carbon's
// import_both pin from classes to runtime `let`s).
// ============================================================================

// --- import_both.carbon

library "[[@TEST_NAME]]";

import library "scalar";
import library "export_name";

//@dump-sem-ir-begin
fn UseBoth() -> i32 { return x; }
//@dump-sem-ir-end
