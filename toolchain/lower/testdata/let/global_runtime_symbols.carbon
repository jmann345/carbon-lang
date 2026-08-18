// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/int.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/let/global_runtime_symbols.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/let/global_runtime_symbols.carbon

// Symbol-identity falsifier for promoted file-scope runtime `let` bindings
// (W-069 risk R-1, the F8c `.N`-rename lesson): one defining file whose
// global is reached repeatedly (definition pass plus two same-file uses), two
// importing files, and a private-to-library binding taking the fingerprint
// suffix. Any `.N`-suffixed `_C...` symbol in the regenerated golden means a
// get-before-create miss silently split the initializing store from the
// loads — the same failure mode as the `_Ctotal.Main.2` incident this file
// is named after.

// --- def.carbon

library "[[@TEST_NAME]]";

fn Seed() -> i32 { return 7; }

let total: i32 = Seed();

// Two same-file readers: both loads and the ctor store must name one
// `_Ctotal.Main` global.
fn First() -> i32 { return total; }

fn Second() -> i32 { return total; }

// --- import_one.carbon

library "[[@TEST_NAME]]";

import library "def";

fn ImportedOnceA() -> i32 { return total; }

fn ImportedOnceB() -> i32 { return total; }

// --- import_two.carbon

library "[[@TEST_NAME]]";

import library "def";

fn ImportedTwice() -> i32 { return total; }

// --- private.carbon

library "[[@TEST_NAME]]";

fn PrivateSeed() -> i32 { return 9; }

// Private to this library: the mangled name takes the fingerprint suffix,
// exactly as `Mangler::MangleGlobalVariable` fingerprints private `var`s.
private let hidden: i32 = PrivateSeed();

fn UseHidden() -> i32 { return hidden; }
