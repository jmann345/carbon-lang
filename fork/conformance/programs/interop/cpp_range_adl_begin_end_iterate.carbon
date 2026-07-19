// CONFORMANCE-BULLET: Functions: C++ interop — open overload sets as extension points (swap etc.)
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   2
//   4
//   6
//   8
//   20
//
// Working slice of this PARTIAL bullet, ADL flavor: free `begin`/`end`
// functions found only by argument-dependent lookup (hidden friends of a
// class in a C++ namespace) are imported as the range extension point.
// BuildCppRangeForIterateWitness in toolchain/check/cpp/impl_lookup.cpp
// falls back from member lookup to LookupCppUnqualified, which runs
// clang_sema.AddArgumentDependentLookupCandidates over the open overload
// set — exactly the C++ customization-point idiom. Shape verbatim from
// check/testdata/interop/cpp/impls/cpp_range_for_iterate.carbon
// (adl_return_same_types: `friend auto begin(const ConstRange&) -> Iterator`
// in `namespace N`), extended with runtime bodies and iterated by a Carbon
// `for` loop via the CppRange -> Core.Iterate blanket impl in
// core/prelude/iterate.carbon. Note only the const-reference ADL form works:
// `begin(MutableRange&)` is still fail_todo (ValueForRefParam) in that same
// testdata file.

import Core library "io";
import Cpp inline '''c++
namespace ext {
class Evens {
 public:
  struct Iterator {
    const int* p;
    auto operator*() const -> const int& { return *p; }
    auto operator++() -> Iterator& {
      ++p;
      return *this;
    }
    friend auto operator==(Iterator a, Iterator b) -> bool { return a.p == b.p; }
    friend auto operator!=(Iterator a, Iterator b) -> bool { return a.p != b.p; }
  };

  static auto Make() -> Evens { return Evens(); }

  friend auto begin(const Evens& r) -> Iterator { return Iterator{r.data}; }
  friend auto end(const Evens& r) -> Iterator { return Iterator{r.data + 4}; }

 private:
  int data[4] = {2, 4, 6, 8};
};
}  // namespace ext
''';

fn Run() -> i32 {
  var r: Cpp.ext.Evens = Cpp.ext.Evens.Make();
  var sum: i32 = 0;
  for (i: i32 in r) {
    Core.Print(i);
    sum += i;
  }
  Core.Print(sum);
  return 0;
}
