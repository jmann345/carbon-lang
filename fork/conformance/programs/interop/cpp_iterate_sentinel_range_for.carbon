// CONFORMANCE-BULLET: Stdlib C++ interop: transparent iteration-abstraction mapping
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   1
//   2
//   3
//   4
//   10
//
// C++20 sentinel-style ranges map transparently too: `begin()` and `end()`
// return *different* types (Iterator vs. Sentinel, compared by heterogeneous
// operator==/!=), and the iterator's operator* yields a value rather than a
// reference. A plain Carbon range-based `for` consumes the range with no
// adapter code — the prelude's CppRangeForIterate interface carries distinct
// `Iterator`/`Sentinel` associated types and its CursorType is the pair
// `(T.Iterator, T.Sentinel)` (core/prelude/iterate.carbon), exactly to
// support this shape. Shape from check/testdata/interop/cpp/range_for.carbon
// (methods_return_different_types: begin -> Iterator, end -> Sentinel,
// heterogeneous friend operator==(Iterator, Sentinel)), with bodies filled
// in: a counting range yielding 1..4, then the sum 10.

import Core library "io";
import Cpp inline '''c++
class CountUp {
 public:
  struct Sentinel {
    int limit;
  };
  struct Iterator {
    int cur;
    auto operator*() const -> int { return cur; }
    auto operator++() -> Iterator& {
      ++cur;
      return *this;
    }
    friend auto operator==(Iterator i, Sentinel s) -> bool { return i.cur == s.limit; }
    friend auto operator!=(Iterator i, Sentinel s) -> bool { return i.cur != s.limit; }
  };

  static auto Make() -> CountUp { return CountUp(); }

  auto begin() const -> Iterator { return Iterator{1}; }
  auto end() const -> Sentinel { return Sentinel{5}; }
};
''';

fn Run() -> i32 {
  var r: Cpp.CountUp = Cpp.CountUp.Make();
  var sum: i32 = 0;
  for (i: i32 in r) {
    Core.Print(i);
    sum += i;
  }
  Core.Print(sum);
  return 0;
}
