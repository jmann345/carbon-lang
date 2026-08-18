// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/let/global_runtime_specifics.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/let/global_runtime_specifics.carbon

// The W-069 risk R-2 falsifier (specific coalescing vs promoted-let
// globals), in its nearest EXPRESSIBLE form [W69b deviation record, see the
// plan]: the literal R-2 shape — two specifics of ONE generic each reading a
// DIFFERENT imported runtime `let` — is structurally inexpressible, because
// a file-scope name reference in a generic body resolves statically to one
// binding, so every specific of a generic references the SAME `let` set
// (the only specific-dependent value channel in `GetValue` is the constant
// path, and a runtime `let` is NotConstant by definition). Pinned instead:
// (1) `G`'s two specifics reach DIFFERENT imported runtime lets through
// per-type impl readers — if `CoalesceEquivalentSpecifics` merged them, one
// `_CG` specific symbol would serve both call sites and one binding's value
// would leak to the other's reader: THAT coalesced output is the alarm;
// (2) `H`'s two specifics read the SAME imported runtime let directly —
// the direct promoted-global load inside specific-function lowering, the
// path whose `AddGlobalToCurrentFingerprint` call R-2 mandates; these two
// bodies are identical, so the coalescer may legitimately merge them, and
// this golden records what the tree does.

// --- def.carbon

library "[[@TEST_NAME]]";

fn SeedA() -> i32 { return 3; }

fn SeedB() -> i32 { return 4; }

let la: i32 = SeedA();

let lb: i32 = SeedB();

// --- use.carbon

library "[[@TEST_NAME]]";

import library "def";

interface Reader {
  fn Get() -> i32;
}

class UseA {}
impl UseA as Reader {
  fn Get() -> i32 { return la; }
}

class UseB {}
impl UseB as Reader {
  fn Get() -> i32 { return lb; }
}

// Two specifics of ONE generic whose witness calls reach different promoted
// lets: must NOT coalesce.
fn G(generic T: Reader) -> i32 { return T.Get(); }

fn CallA() -> i32 { return G(UseA); }

fn CallB() -> i32 { return G(UseB); }

// Two specifics of ONE generic reading the SAME promoted let directly: the
// promoted-global load lands in each specific's fingerprint.
fn H(generic T: type) -> i32 { return la; }

fn CallHA() -> i32 { return H(bool); }

fn CallHB() -> i32 { return H(i32); }
