// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// Differential C++17 equivalent of question_generic_diff.carbon: a function
// TEMPLATE over a struct-shaped result (`{bool ok; T v; int e;}`) with
// explicit early returns — the control flow Carbon's generic postfix `?`
// desugars to — instantiated at the same two type arguments (int and
// int64_t), with the same runtime-selected failure depth, the same
// runtime-computed seeds, and the same error-tagging bases (101/202), so
// byte-identical output pins where propagation stopped inside the template
// body and what the break payload was. The int64_t leg compares the
// continue payload against the same runtime-computed expectation the
// Carbon side uses. printf("%d\n", ...) mirrors Core.Print's lowering
// exactly (toolchain/lower/handle_call.cpp).

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

template <typename T>
static auto Step(T x, bool fail, int tag) -> Result<T> {
  if (fail) {
    return Err<T>(tag);
  }
  return Ok(x);
}

template <typename T>
static auto Chain(T x, int fail_at) -> Result<T> {
  // The explicit spelling of `Step(x, fail_at == 1, 101)?`.
  Result<T> r1 = Step(x, fail_at == 1, 101);
  if (!r1.ok) {
    return Err<T>(r1.e);
  }
  T a = r1.v;
  // The explicit spelling of `Step(a, fail_at == 2, 202)?`.
  Result<T> r2 = Step(a, fail_at == 2, 202);
  if (!r2.ok) {
    return Err<T>(r2.e);
  }
  T b = r2.v;
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

static auto RuntimeSeed(int x) -> int { return x + 40; }

static auto RuntimeSeedL(std::int64_t x) -> std::int64_t { return x + 40; }

auto main() -> int {
  ProbeI(RuntimeSeed(-40), RuntimeSeed(2));
  ProbeI(RuntimeSeed(-39), RuntimeSeed(2));
  ProbeI(RuntimeSeed(-38), RuntimeSeed(2));
  ProbeL(RuntimeSeed(-40), RuntimeSeedL(4), RuntimeSeedL(4));
  ProbeL(RuntimeSeed(-39), RuntimeSeedL(4), RuntimeSeedL(4));
  ProbeL(RuntimeSeed(-38), RuntimeSeedL(4), RuntimeSeedL(4));
  return 0;
}
