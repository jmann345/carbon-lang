// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// Differential C++17 equivalent of result_prelude_diff.carbon: a
// struct-shaped result (`{bool ok; int v;}`) with explicit early returns —
// the control flow Carbon's postfix `?` desugars to over the prelude
// `Core.Result` — over the same 3-deep call chain (Top → Mid → Leaf), the
// same runtime-selected failure depth, the same runtime-computed seed, and
// the same single error-conversion layer: every error code crosses `ToErrB`
// (+1000) exactly once, where `Top` propagates. printf("%d\n", ...) mirrors
// Core.Print's lowering exactly (toolchain/lower/handle_call.cpp).

#include <cstdio>

struct Result {
  bool ok;
  int v;
};

static auto Ok(int v) -> Result { return {true, v}; }
static auto Err(int e) -> Result { return {false, e}; }

// The `ErrA -> ErrB` `ImplicitAs` layer of the Carbon program.
static auto ToErrB(int a) -> int { return a + 1000; }

static auto Fail(int code) -> Result { return Err(code); }

static auto Leaf(int n, int fail_at) -> Result {
  if (fail_at == 3) {
    return Err(303);
  }
  return Ok(n * 2);
}

static auto Mid(int n, int fail_at) -> Result {
  // The explicit spelling of `Leaf(n, fail_at)?` (same error type).
  Result r = Leaf(n, fail_at);
  if (!r.ok) {
    return Err(r.v);
  }
  int v = r.v;
  if (fail_at == 2) {
    return Err(202);
  }
  return Ok(v);
}

static auto Top(int n, int fail_at) -> Result {
  // `Mid(n, fail_at)?` with the `ErrA -> ErrB` conversion in `FromBreak`.
  Result r = Mid(n, fail_at);
  if (!r.ok) {
    return Err(ToErrB(r.v));
  }
  int v = r.v;
  if (fail_at == 1) {
    // `Fail(101)?;` in statement position, converting likewise.
    Result f = Fail(101);
    if (!f.ok) {
      return Err(ToErrB(f.v));
    }
  }
  return Ok(v);
}

static auto Probe(int fail_at, int seed) -> void {
  Result r = Top(seed, fail_at);
  if (r.ok) {
    std::printf("%d\n", 0);
    std::printf("%d\n", r.v);
  } else {
    std::printf("%d\n", 1);
    std::printf("%d\n", r.v);
  }
}

static auto RuntimeSeed(int x) -> int { return x + 20; }

auto main() -> int {
  Probe(RuntimeSeed(-20), RuntimeSeed(22));
  Probe(RuntimeSeed(-19), RuntimeSeed(22));
  Probe(RuntimeSeed(-18), RuntimeSeed(22));
  Probe(RuntimeSeed(-17), RuntimeSeed(22));
  return 0;
}
