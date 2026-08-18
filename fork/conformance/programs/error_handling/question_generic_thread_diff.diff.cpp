// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// Differential C++17 equivalent of question_generic_thread_diff.carbon: a
// function TEMPLATE over a struct-shaped result (`{bool ok; T v; int e;}`)
// with explicit early returns — the control flow Carbon's generic postfix
// `?` desugars to — where each step's input is computed from the PREVIOUS
// step's threaded continue value (`a` -> `Combine(a)` -> `b`) and the
// final Ok payload IS the last threaded value (`b`, = 2 * seed on
// success). This mirrors the THREADING shape the Carbon side spells with
// `let a: T = ...?;` under its `final impl` (the W72b arbiter,
// fork/w072/plan.md §3) — not the sibling pair's discard/reconstruct
// shape. Instantiated at the same two type arguments (int and int64_t),
// with the same runtime-selected failure depth, the same runtime-computed
// seeds, and the same error-tagging bases (101/202); the int64_t leg
// compares the Ok payload against the same independently runtime-computed
// expectation the Carbon side uses. printf("%d\n", ...) mirrors
// Core.Print's lowering exactly (toolchain/lower/handle_call.cpp).

#include <cstdint>
#include <cstdio>

template <typename T>
struct Result {
  bool ok;
  T v;    // The continue payload; meaningful when `ok`.
  int e;  // The break payload; meaningful when `!ok`.
};

template <typename T>
static auto Ok(T v) -> Result<T> {
  return {true, v, 0};
}

template <typename T>
static auto Err(int e) -> Result<T> {
  return {false, T{}, e};
}

// The per-type transform of each threaded continue value (the Carbon
// side's `Combinable.Combine`): Combine(x) = x + x.
template <typename T>
static auto Combine(T x) -> T {
  return x + x;
}

template <typename T>
static auto Step(T x, bool fail, int tag) -> Result<T> {
  if (fail) {
    return Err<T>(tag);
  }
  return Ok(x);
}

template <typename T>
static auto Chain(T x, int fail_at) -> Result<T> {
  // The explicit spelling of `let a: T = Step(x, fail_at == 1, 101)?;`:
  // the break path early-returns with the converted payload; the continue
  // value is BOUND and threaded forward.
  Result<T> r1 = Step(x, fail_at == 1, 101);
  if (!r1.ok) {
    return Err<T>(r1.e);
  }
  T a = r1.v;
  // The explicit spelling of
  // `let b: T = Step(a.Combine(), fail_at == 2, 202)?;` — step 2's input
  // is computed from step 1's threaded output.
  Result<T> r2 = Step(Combine(a), fail_at == 2, 202);
  if (!r2.ok) {
    return Err<T>(r2.e);
  }
  T b = r2.v;
  // The threaded value IS the payload (2 * seed on success) — never
  // reconstructed from the seed.
  return Ok(b);
}

static auto ProbeI(int fail_at, int seed) -> void {
  Result<int> r = Chain(seed, fail_at);
  if (r.ok) {
    std::printf("%d\n", 0);
    std::printf("%d\n", r.v);
  } else {
    std::printf("%d\n", 1);
    std::printf("%d\n", r.e);
  }
}

static auto ProbeL(int fail_at, std::int64_t seed, std::int64_t expect)
    -> void {
  Result<std::int64_t> r = Chain(seed, fail_at);
  if (r.ok) {
    std::printf("%d\n", 0);
    std::printf("%d\n", r.v == expect ? 1 : 0);
  } else {
    std::printf("%d\n", 1);
    std::printf("%d\n", r.e);
  }
}

static auto RuntimeSeed(int x) -> int { return x + 20; }

static auto RuntimeSeedL(std::int64_t x) -> std::int64_t { return x + 20; }

auto main() -> int {
  ProbeI(RuntimeSeed(-20), RuntimeSeed(22));
  ProbeI(RuntimeSeed(-19), RuntimeSeed(22));
  ProbeI(RuntimeSeed(-18), RuntimeSeed(22));
  ProbeL(RuntimeSeed(-20), RuntimeSeedL(24), RuntimeSeedL(68));
  ProbeL(RuntimeSeed(-19), RuntimeSeedL(24), RuntimeSeedL(68));
  ProbeL(RuntimeSeed(-18), RuntimeSeedL(24), RuntimeSeedL(68));
  return 0;
}
