// Differential C++17 equivalent of operator_overloading_diff.carbon: a
// value-wrapping class with overloaded homogeneous + and heterogeneous
// (by-int) *. printf("%d\n", ...) mirrors Core.Print's lowering exactly
// (toolchain/lower/handle_call.cpp).

#include <cstdio>

class Cents {
 public:
  explicit Cents(int value) : value_(value) {}
  auto operator+(Cents other) const -> Cents {
    return Cents(value_ + other.value_);
  }
  auto operator*(int n) const -> Cents { return Cents(value_ * n); }
  auto Value() const -> int { return value_; }

 private:
  int value_;
};

auto main() -> int {
  Cents price(150);
  Cents tip(27);
  Cents total = price + tip;
  std::printf("%d\n", total.Value());
  Cents tripled = total * 3;
  std::printf("%d\n", tripled.Value());
  return 0;
}
