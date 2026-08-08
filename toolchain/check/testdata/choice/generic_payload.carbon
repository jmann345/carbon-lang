// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/choice/generic_payload.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/choice/generic_payload.carbon

// Payload synthesis in generic choices (W5-S3b, fork/w5-s3/plan.md §2.2/§2.4):
// a symbolic payload type leaves the payload region's layout dependent at the
// definition — the `custom_layout_type` carries the zero-alignment sentinel —
// and monomorphization rebuilds it from the substituted field types by the
// max-of-fields rule (F-007k). Alternative constructors of a generic choice
// are themselves generic and resolve per specific. Matching is by
// discriminant here (`case` on constant alternatives plus `default`, the S1
// honesty minimum); payload destructuring on specifics is W5-S3c.

// --- optional.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
// The doc's shape (docs/design/sum_types.md): constructing and matching by
// discriminant. `Optional(i32)`'s payload region is 4 bytes ([4 x i8] in the
// lower golden): the single payload tuple `(i32,)`.
choice Optional(T: type) {
  Some(value: T),
  None
}

fn IsPresent(o: Optional(i32)) -> i32 {
  match (o) {
    case .None => { return 0; }
    default => { return 1; }
  }
}

fn Run() -> i32 {
  let n: Optional(i32) = Optional(i32).None;
  if (IsPresent(n) != 0) {
    return 1;
  }
  let s: Optional(i32) = Optional(i32).Some(42);
  return IsPresent(s) - 1;
}
//@dump-sem-ir-end

// --- destructure.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
// Payload destructuring on a CONCRETE specific became reachable at S3b — the
// parameterized alternative now has its table row, and `case .Some(v: i32)`
// resolves the payload tuple through `GetChoicePayloadInfo`'s
// specific-resolved reads (the S2c machinery under Option B) — so this
// minimal positive subfile pins the newly reachable surface. The full S3c
// scope — symbolic-payload destructuring inside a generic body, substituted
// binding conversions, imported pairs, and the sum_types.md example verbatim
// — stays S3c.
choice Opt(T: type) {
  Some(value: T),
  None
}

fn Get(o: Opt(i32)) -> i32 {
  match (o) {
    case .Some(v: i32) => { return v; }
    case .None => { return -1; }
  }
}

fn Run() -> i32 {
  let s: Opt(i32) = Opt(i32).Some(42);
  return Get(s) - 42;
}
//@dump-sem-ir-end

// --- two_sizes.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
// Two specifics of one generic choice with different payload sizes (risk
// R-1's derived numbers): `Pair(i32)`'s payload tuple is `(i32, i32)` — 8
// bytes, align 4 — and `Pair(i64)`'s is `(i64, i64)` — 16 bytes, align 8. The
// two `custom_layout_type` constants must carry distinct, recomputed numbers;
// equal or zero-sized regions (a leaked sentinel) falsify the recompute.
choice Pair(T: type) {
  Both(x: T, y: T),
  Neither
}

fn Classify32(p: Pair(i32)) -> i32 {
  match (p) {
    case .Neither => { return 0; }
    default => { return 1; }
  }
}

fn Classify64(p: Pair(i64)) -> i32 {
  match (p) {
    case .Neither => { return 0; }
    default => { return 1; }
  }
}

// Both specifics' constructors called from one function: each resolves,
// checks, and lowers per specific (risk R-3's falsifier is the pair of
// specific function bodies in the lower golden).
fn Run() -> i32 {
  let a: Pair(i32) = Pair(i32).Both(1, 2);
  let b: Pair(i64) = Pair(i64).Both(3, 4);
  return Classify32(a) + Classify64(b) - 2;
}
//@dump-sem-ir-end

// --- mixed.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
// The mixed-alternative max-of-fields pin: one concrete-payload alternative
// beside one symbolic-payload alternative. Which alternative is largest flips
// between the two pinned specifics: in `M(i8)` the concrete `(i32,)` wins — 4
// bytes, align 4 — and in `M(i64)` the substituted `(i64, i64)` wins — 16
// bytes, align 8. The constant alternative `None` adds no payload field.
choice M(T: type) {
  Small(a: i32),
  Big(x: T, y: T),
  None
}

fn F8(m: M(i8)) -> i32 {
  match (m) {
    case .None => { return 0; }
    default => { return 1; }
  }
}

fn F64(m: M(i64)) -> i32 {
  match (m) {
    case .None => { return 0; }
    default => { return 1; }
  }
}

fn Run() -> i32 {
  let s: M(i8) = M(i8).Small(1);
  let b: M(i64) = M(i64).Big(3, 4);
  return F8(s) + F64(b) - 2;
}
//@dump-sem-ir-end

// --- concrete_payload_in_generic.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
// A generic choice whose payload types are all concrete: the layout is
// computable at the definition — no sentinel — and SF-6 validates `(i32,)`
// there, exactly as in a non-generic choice. The zero-payload `Empty()`
// alternative of a payload-carrying generic choice covers the payload field
// with an uninitialized value, as in the concrete mixed_payload_alternatives
// shape.
choice P(T: type) {
  Tag(n: i32),
  Empty(),
  None
}

fn F(p: P(bool)) -> i32 {
  match (p) {
    case .None => { return 0; }
    default => { return 1; }
  }
}

fn Run() -> i32 {
  let t: P(bool) = P(bool).Tag(7);
  let e: P(bool) = P(bool).Empty();
  return F(t) + F(e) - 2;
}
//@dump-sem-ir-end
