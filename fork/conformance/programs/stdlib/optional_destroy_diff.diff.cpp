// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// C++17 oracle for optional_destroy_diff.carbon: the same live-object counts
// over std::optional<Tracked>, printed as printf("%d\n", x). `Tracked` has a
// user-declared copy constructor, so it has no move constructor and every
// copy or move of it is counted the same way as the Carbon `Copy`.

#include <cstdio>
#include <optional>

struct Tracked {
  explicit Tracked(int* l) : id(1), live(l) { ++*live; }
  Tracked(const Tracked& other) : id(other.id), live(other.live) { ++*live; }
  auto operator=(const Tracked&) -> Tracked& = delete;
  ~Tracked() { --*live; }
  int id;
  int* live;
};

static auto operator==(const Tracked& a, const Tracked& b) -> bool {
  return a.id == b.id;
}

static auto B(bool b) -> int { return b ? 1 : 0; }

struct Box {
  std::optional<Tracked> o;
};

static auto HoldField(int* live) -> void {
  Tracked t(live);
  Box b{std::optional<Tracked>(t)};
  std::printf("%d\n", *live);
}

static auto HoldNested(int* live) -> void {
  Tracked t(live);
  std::optional<Tracked> inner(t);
  std::optional<std::optional<Tracked>> outer(inner);
  std::printf("%d\n", *live);
}

template <typename T>
static auto HoldGeneric(const T& a) -> void {
  std::optional<T> o(a);
}

static auto CallGeneric(int* live) -> void {
  Tracked t(live);
  HoldGeneric(t);
  std::printf("%d\n", *live);
}

static auto MakeSome(int* live) -> std::optional<Tracked> {
  Tracked t(live);
  return std::optional<Tracked>(t);
}

static auto HoldReturned(int* live) -> void {
  std::optional<Tracked> o = MakeSome(live);
  std::printf("%d\n", *live);
}

static auto HoldCompared(int* live) -> void {
  Tracked t(live);
  std::optional<Tracked> a(t);
  std::optional<Tracked> b(t);
  std::printf("%d\n", B(a == b));
  std::printf("%d\n", *live);
}

auto main() -> int {
  int field = 0;
  HoldField(&field);
  std::printf("%d\n", field);
  int nested = 0;
  HoldNested(&nested);
  std::printf("%d\n", nested);
  int generic = 0;
  CallGeneric(&generic);
  std::printf("%d\n", generic);
  int returned = 0;
  HoldReturned(&returned);
  std::printf("%d\n", returned);
  int compared = 0;
  HoldCompared(&compared);
  std::printf("%d\n", compared);
  return 0;
}
