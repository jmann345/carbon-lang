// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// Differential C++17 equivalent of question_propagation_diff.carbon: a
// struct-shaped result (`{bool ok; int v;}`) with explicit early returns —
// the control flow Carbon's postfix `?` desugars to — over the same 3-deep
// call chain (Top → Mid → Leaf), the same runtime-selected failure depth,
// the same runtime-computed seeds, and the same error-tagging bases
// (10/20/30), so byte-identical output pins where propagation stopped and
// what the break payload was after crossing one or two propagation
// boundaries. printf("%d\n", ...) mirrors Core.Print's lowering exactly
// (toolchain/lower/handle_call.cpp).

#include <cstdio>

struct Result {
  bool ok;
  int v;
};

static auto Ok(int v) -> Result { return {true, v}; }
static auto Err(int e) -> Result { return {false, e}; }

static auto Leaf(int n, int fail_at) -> Result {
  if (fail_at == 3) {
    return Err(30 + n);
  }
  return Ok(n + 1);
}

static auto Mid(int n, int fail_at) -> Result {
  // The explicit spelling of `Leaf(n, fail_at)?`.
  Result r = Leaf(n, fail_at);
  if (!r.ok) {
    return Err(r.v);
  }
  int v = r.v;
  if (fail_at == 2) {
    return Err(20 + v);
  }
  return Ok(v + 1);
}

static auto Top(int n, int fail_at) -> Result {
  Result r = Mid(n, fail_at);
  if (!r.ok) {
    return Err(r.v);
  }
  int v = r.v;
  if (fail_at == 1) {
    return Err(10 + v);
  }
  return Ok(v + 1);
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

static auto RuntimeSeed(int x) -> int { return x + 40; }

auto main() -> int {
  Probe(RuntimeSeed(-40), RuntimeSeed(2));
  Probe(RuntimeSeed(-39), RuntimeSeed(2));
  Probe(RuntimeSeed(-38), RuntimeSeed(2));
  Probe(RuntimeSeed(-37), RuntimeSeed(2));
  return 0;
}
