// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// Differential C++17 equivalent of choice_generic_roundtrip_diff.carbon:
// the docs/design/sum_types.md `Optional(T)` example held in std::optional
// (the doc example's semantics) — construction from empty, re-assignment
// with a runtime-computed payload, the return to empty via `.reset()`
// (mirroring the Carbon side's Some-to-None `.None` re-assignment, the
// W-075 restoration), and payload readback through the has_value/None
// split, mirroring the Carbon side's match arms. Same runtime seed
// arithmetic, same probe order over the two instantiations
// (`int` / `int64_t`, mirroring `Optional(i32)` / `Optional(i64)`,
// including the low-byte-1 collision payload 257), so byte-identical
// output pins the round-tripped payload values per specific.
// printf("%d\n", ...) mirrors Core.Print's lowering exactly
// (toolchain/lower/handle_call.cpp).

#include <cstdint>
#include <cstdio>
#include <optional>

auto RuntimeSeed(int x) -> int { return x + 20; }

auto RuntimeSeedL(int64_t x) -> int64_t { return x + 20; }

// The Carbon side's match: print the payload from the Some arm, -1 from
// the None arm.
static auto Inspect(const std::optional<int>& o) -> void {
  if (o.has_value()) {
    std::printf("%d\n", *o);
  } else {
    std::printf("%d\n", -1);
  }
}

static auto InspectL(const std::optional<int64_t>& o) -> void {
  if (o.has_value()) {
    std::printf("%d\n", static_cast<int>(*o));
  } else {
    std::printf("%d\n", -1);
  }
}

auto main() -> int {
  // Construction from empty on ONE variable, then the empty-to-engaged
  // transition (the Some-to-Some overwrite probe riding in front), then
  // engaged-to-empty via `.reset()` — the doc's round trip.
  std::optional<int> my_opt = std::nullopt;
  Inspect(my_opt);

  my_opt = RuntimeSeed(-18);
  my_opt = RuntimeSeed(22);
  Inspect(my_opt);

  my_opt.reset();
  Inspect(my_opt);

  // The collision payload: 237 + 20 = 257, low byte 1.
  std::optional<int64_t> wide = RuntimeSeedL(237);
  InspectL(wide);
  std::optional<int64_t> none_wide = std::nullopt;
  InspectL(none_wide);
  return 0;
}
