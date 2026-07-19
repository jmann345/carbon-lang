// Differential C++17 equivalent of virtual_dispatch_diff.carbon: the same
// two-derived-class hierarchy with dispatch through a base pointer.
// printf("%d\n", ...) mirrors Core.Print's lowering exactly
// (toolchain/lower/handle_call.cpp).

#include <cstdio>

class Instrument {
 public:
  virtual ~Instrument() = default;
  virtual auto Strings() const -> int { return 0; }
};

class Guitar : public Instrument {
 public:
  auto Strings() const -> int override { return 6; }
};

class Cello : public Instrument {
 public:
  auto Strings() const -> int override { return 4; }
};

static auto PrintStrings(const Instrument* inst) -> void {
  std::printf("%d\n", inst->Strings());
}

auto main() -> int {
  Instrument plain;
  Guitar guitar;
  Cello cello;
  PrintStrings(&plain);
  PrintStrings(&guitar);
  PrintStrings(&cello);
  return 0;
}
