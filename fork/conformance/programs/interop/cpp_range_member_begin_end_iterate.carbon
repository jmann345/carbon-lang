// CONFORMANCE-BULLET: Functions: C++ interop — open overload sets as extension points (swap etc.)
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   7
//   11
//   13
//   31
//
// Working slice of this PARTIAL bullet: the C++ `begin`/`end` overload set is
// the one open overload set the toolchain heuristically imports as a Carbon
// extension point. Member `begin()`/`end()` on a C++ class are synthesized
// into the prelude's private `CppRangeForIterate` interface
// (toolchain/check/cpp/impl_lookup.cpp, BuildCppRangeForIterateWitness),
// which the blanket `impl forall [T: CppRange ...] T as Iterate` in
// core/prelude/iterate.carbon turns into `Core.Iterate` — so a Carbon
// range-based `for` loop consumes the C++ range directly. Shapes verbatim
// from check/testdata/interop/cpp/range_for.carbon
// (methods_return_same_type: iterator with operator*/operator++/==/!=,
// member begin/end, `for (i: i32 in m)`), with bodies filled in so the
// program links and runs.

import Core library "io";
import Cpp inline '''c++
class Triple {
 public:
  struct Iterator {
    int* p;
    auto operator*() const -> int& { return *p; }
    auto operator++() -> Iterator& {
      ++p;
      return *this;
    }
    friend auto operator==(Iterator a, Iterator b) -> bool { return a.p == b.p; }
    friend auto operator!=(Iterator a, Iterator b) -> bool { return a.p != b.p; }
  };

  static auto Make() -> Triple { return Triple(); }

  auto begin() -> Iterator { return Iterator{data}; }
  auto end() -> Iterator { return Iterator{data + 3}; }

 private:
  int data[3] = {7, 11, 13};
};
''';

fn Run() -> i32 {
  var r: Cpp.Triple = Cpp.Triple.Make();
  var sum: i32 = 0;
  for (i: i32 in r) {
    Core.Print(i);
    sum += i;
  }
  Core.Print(sum);
  return 0;
}
