// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/let/import_choice.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/let/import_choice.carbon

// The POINTER-value-rep arm of the file-scope runtime `let` promotion
// (W-069 W69b): for classes, choices, and multi-element tuples the backing
// global holds the OBJECT representation, `__global_init` fills it once with
// a memcpy from the bound value's pointer (the as-if copy license,
// docs/design/values.md), and every reference — same-file cross-function or
// cross-file — is served the global's ADDRESS as the value representation
// (the same shape a by-value parameter's pointer takes). The plib subfiles
// are the lower-side pin of the RESTORED W-069 ledger acceptance split
// (check/testdata/match/choice_generic_payload_scrutinee.carbon): the
// importer's `match (g)` reads the discriminant through the external
// object-rep global. The constant-bound sibling `gc` keeps riding the
// constant path (half (b)) — no `_Cgc` global may appear. (A CHECK-less
// golden cannot assert absence: that claim is enforced by the reviewer
// audit over this file's filled content, named here per the W69b fix
// round.)

// --- plib.carbon

library "[[@TEST_NAME]]";

choice P(T: type) {
  Both(x: T, y: T),
  Neither
}

fn MakeRuntime() -> P(i64) { return P(i64).Both(1, 2); }

// Runtime-bound: promoted to an object-rep global + ctor memcpy.
let g: P(i64) = MakeRuntime();

// Constant-bound: imports as the alternative's constant, never promoted.
let gc: P(i64) = P(i64).Neither;

// The same-file cross-function half of the pointer arm: the scrutinee value
// is the global's address.
fn SameFile() -> i32 {
  match (g) {
    case .Neither => { return 0; }
    default => { return 1; }
  }
}

// --- imported_global.carbon

library "[[@TEST_NAME]]";

import library "plib";

// The restored ledger acceptance split's importing side: the discriminant
// load rides the external `_Cg.Main` object-rep global's address.
fn F() -> i32 {
  match (g) {
    case .Neither => { return 0; }
    default => { return 1; }
  }
}

// --- imported_global_constant.carbon

library "[[@TEST_NAME]]";

import library "plib";

// The half-(b) boundary: `gc` imports as a constant and lowers through the
// constant path — no external `_Cgc` symbol.
fn G() -> i32 {
  match (gc) {
    case .Neither => { return 0; }
    default => { return 1; }
  }
}

// --- pt.carbon

library "[[@TEST_NAME]]";

class Pt {
  var x: i32;
  var y: i32;
}

fn MakePt() -> Pt { return {.x = 30, .y = 40}; }

// A class-typed (non-choice) runtime `let`, so the pointer arm is pinned
// independent of choice machinery.
let origin: Pt = MakePt();

// Same-file FIELD READ through the promoted global's address.
fn SameFileX() -> i32 { return origin.x; }

// --- import_pt.carbon

library "[[@TEST_NAME]]";

import library "pt";

// Cross-file FIELD READ consumption of the class-typed binding.
fn ReadX() -> i32 { return origin.x; }

// --- pair.carbon

library "[[@TEST_NAME]]";

fn MakePair() -> (i32, i32) { return (50, 60); }

// P-10: a WHOLE-tuple-typed runtime `let` (contrast the tuple-PATTERN
// elementwise promotion in let/global_runtime.carbon): one object-rep
// global for the whole tuple.
let t: (i32, i32) = MakePair();

// --- import_pair.carbon

library "[[@TEST_NAME]]";

import library "pair";

// P-10 cross-file consumption, both shapes: an element read...
fn First() -> i32 { return t.0; }

// ...and the whole tuple.
fn Whole() -> (i32, i32) { return t; }
