// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --dump-sem-ir-ranges=only
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/function/overload/import.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/function/overload/import.carbon

// `overload fn` sets reached through an import (fork/overload/plan.md OV-2,
// §1.B.1-3, §1.B.7). The import resolver localizes a set whole, with its
// member list in the declared order, so a set is never partially imported and
// every member keeps its set-relative index (`:overload<N>`, D-OV-5). A set is
// closed (p000998): the implementation file of its library may only DEFINE
// members, an importing library may only redeclare them (which is how `extern`
// ownership works), and a declaration that matches no member by parameter
// types is `OverloadSetFrozen`. Every member an API file declares must be
// defined by the API file or its implementation file (`MissingDefinitionInImpl`
// at the member's API declaration), which is what makes a marked-signature
// typo across the two files loud (§1.B.7).

// --- lib.carbon

library "[[@TEST_NAME]]";

overload fn F(unused x: i32) -> i32 { return 1; }
overload fn F(unused b: bool) -> i32 { return 2; }

// --- use.carbon

library "[[@TEST_NAME]]";

import library "lib";

// The imported set value is the name lookup result; each call commits to the
// selected imported member, as for a same-file set.
//@dump-sem-ir-begin
fn Use() -> i32 { return F(7) + F(true); }
//@dump-sem-ir-end

// --- api_impl.carbon

library "[[@TEST_NAME]]";

overload fn G(x: i32) -> i32;
overload fn G(b: bool) -> i32;

// --- api_impl.impl.carbon

impl library "[[@TEST_NAME]]";

// Each definition merges into its API-declared member (the `ApiForImpl`
// import); the name stays bound to the set value, so the call resolves over
// the imported set. Both members are defined, so §1.B.7's check is quiet.
//@dump-sem-ir-begin
overload fn G(x: i32) -> i32 { return x; }
overload fn G(b: bool) -> i32 { if (b) { return 1; } return 0; }

fn Use() -> i32 { return G(3) + G(true); }
//@dump-sem-ir-end

// --- frozen.carbon

library "[[@TEST_NAME]]";

overload fn H(x: i32) -> i32;
overload fn H(b: bool) -> i32;

// --- fail_frozen.impl.carbon

impl library "[[@TEST_NAME]]";

overload fn H(x: i32) -> i32 { return x; }
overload fn H(b: bool) -> i32 { if (b) { return 1; } return 0; }

// An implementation file may only define members, never add one.
overload fn H(unused x: i32, unused y: i32) -> i32 { return 3; }

// --- fail_cross_library_adds_member.carbon

library "[[@TEST_NAME]]";

import library "lib";

// No library may add a member to another library's set.
overload fn F(unused x: i32, unused y: i32) -> i32 { return 3; }

// --- unmarked.carbon

library "[[@TEST_NAME]]";

overload fn K(x: i32) -> i32;
overload fn K(b: bool) -> i32;

// --- fail_unmarked.impl.carbon

impl library "[[@TEST_NAME]]";

// The marker is all-or-none across the library too: an unmarked definition
// against the imported set is diagnosed and then recovers as marked, so it
// still defines its member.
fn K(x: i32) -> i32 { return x; }

overload fn K(b: bool) -> i32 { if (b) { return 1; } return 0; }

// --- extern_lib.carbon

library "[[@TEST_NAME]]";

extern library "extern_owner" overload fn E(x: i32) -> i32;
extern library "extern_owner" overload fn E(b: bool) -> i32;

// --- extern_owner.carbon

library "[[@TEST_NAME]]";

import library "extern_lib";

// The owning library's `extern overload fn` declarations each name an existing
// member of the imported set; the cross-library `extern` rules then apply per
// member (§1.B.3).
extern overload fn E(x: i32) -> i32 { return x; }
extern overload fn E(b: bool) -> i32 { if (b) { return 1; } return 0; }

fn Use() -> i32 { return E(1) + E(true); }

// --- fail_extern_non_member.carbon

library "[[@TEST_NAME]]";

import library "extern_lib";

extern overload fn E(x: i32, y: i32) -> i32;

// --- undefined.carbon

library "[[@TEST_NAME]]";

overload fn M(x: i32) -> i32;
overload fn M(b: bool) -> i32;

// --- fail_undefined.impl.carbon

impl library "[[@TEST_NAME]]";

// Only the first member is defined; the second is diagnosed at its API
// declaration when this implementation file is checked (§1.B.7).
overload fn M(x: i32) -> i32 { return x; }

// --- impl_local_set.carbon

library "[[@TEST_NAME]]";

// --- impl_local_set.impl.carbon

impl library "[[@TEST_NAME]]";

// A set declared wholly inside an implementation file involves no import, so
// the same-file path applies.
overload fn L(unused x: i32) -> i32 { return 1; }
overload fn L(unused b: bool) -> i32 { return 2; }

fn Use() -> i32 { return L(true); }
