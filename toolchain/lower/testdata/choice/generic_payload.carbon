// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/choice/generic_payload.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/choice/generic_payload.carbon

// Per-specific payload layout (W5-S3b, risk R-1's derived numbers): each
// specific's payload region lowers as its own `[N x i8]` byte array from the
// RECOMPUTED layout — `Pair(i32)` is `[8 x i8]` ((i32, i32), align 4) and
// `Pair(i64)` is `[16 x i8]` ((i64, i64), align 8). Equal regions, `[0 x i8]`
// (a leaked sentinel), or numbers off the derivation falsify the eval-time
// recompute. Both constructors called from one function must produce two
// distinct specific function bodies (risk R-3), each storing through its own
// specific's region type at byte offset zero (F-007k).

// --- two_sizes.carbon
library "[[@TEST_NAME]]";

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

fn Run() -> i32 {
  let a: Pair(i32) = Pair(i32).Both(1, 2);
  let b: Pair(i64) = Pair(i64).Both(3, 4);
  return Classify32(a) + Classify64(b) - 2;
}

// --- mixed.carbon
library "[[@TEST_NAME]]";

// The mixed-alternative max-of-fields flip: in `M(i8)` the concrete `(i32,)`
// payload is largest — `[4 x i8]` — and in `M(i64)` the substituted
// `(i64, i64)` payload is — `[16 x i8]`.
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

// --- destructure.carbon
library "[[@TEST_NAME]]";

// The check-side destructure subfile's lower counterpart: `case .Some(v: i32)`
// on a concrete specific extracts the payload tuple from the `[4 x i8]`
// region at offset zero (F-007k) after the discriminant test.
choice Opt(T: type) {
  Some(value: T),
  None
}

fn Get(o: Opt(i32)) -> i32 {
  match (o) {
    case .Some(v: i32) => { return v; }
    case .None => { return -1; }
  }
  // Unreachable: every arm returns.
  return -2;
}

fn Run() -> i32 {
  let s: Opt(i32) = Opt(i32).Some(42);
  return Get(s) - 42;
}

// --- optional.carbon
library "[[@TEST_NAME]]";

// The doc's `Optional` shape: `.None` and `.Some(42)` constructed at runtime
// and dispatched by discriminant; the payload region is `[4 x i8]`.
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
