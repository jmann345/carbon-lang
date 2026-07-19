// CONFORMANCE-BULLET: Stdlib C++ interop: transparent iteration-abstraction mapping
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   2
//
// ADL flavor of the iteration-abstraction mapping: the C++ range exposes
// free `begin`/`end` hidden friends (found only by argument-dependent
// lookup, the C++ customization-point idiom) rather than members, and the
// element type is f64. A Carbon generic constrained only on
// `Core.Iterate where .ElementType = f64` still consumes it transparently:
// BuildCppRangeForIterateWitness (toolchain/check/cpp/impl_lookup.cpp)
// falls back from member lookup to ADL over the open overload set, and the
// blanket CppRange -> Iterate impl in core/prelude/iterate.carbon does the
// rest. Shape from check/testdata/interop/cpp/range_for.carbon
// (adl_return_same_types: `friend auto begin(const ConstRange&) -> Iterator`
// in a namespace, `Core.Iterate where .ElementType = f64`), with bodies
// filled in to link and run. Only the const-reference ADL form is used;
// `begin(Range&)` is still fail_todo (ValueForRefParam) in that testdata.

import Core library "io";
import Cpp inline '''c++
namespace geo {
class Halves {
 public:
  struct Iterator {
    const double* p;
    auto operator*() const -> const double& { return *p; }
    auto operator++() -> Iterator& {
      ++p;
      return *this;
    }
    friend auto operator==(Iterator a, Iterator b) -> bool { return a.p == b.p; }
    friend auto operator!=(Iterator a, Iterator b) -> bool { return a.p != b.p; }
  };

  static auto Make() -> Halves { return Halves(); }

  friend auto begin(const Halves& r) -> Iterator { return Iterator{r.data}; }
  friend auto end(const Halves& r) -> Iterator { return Iterator{r.data + 3}; }

 private:
  double data[3] = {0.5, 0.25, 0.125};
};
}  // namespace geo
''';

// Counts elements above the threshold: 0.5 and 0.25 qualify, 0.125 does not.
fn CountAbove[R: Core.Iterate where .ElementType = f64](r: R, threshold: f64)
    -> i32 {
  var n: i32 = 0;
  for (x: f64 in r) {
    if (x > threshold) {
      ++n;
    }
  }
  return n;
}

fn Run() -> i32 {
  var r: Cpp.geo.Halves = Cpp.geo.Halves.Make();
  var threshold: f64 = 0.2;
  Core.Print(CountAbove(r, threshold));
  return 0;
}
