// CONFORMANCE-BULLET: Generics: C++ interop — C++20 concepts <-> named predicates mapping
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   5
// SKIP: known-missing slice — the export direction (Carbon named predicates usable as C++20 concepts in C++ code) is unimplemented: naming the Carbon interface from the inline Cpp block fails on nightly 2026.07.19 (even with `--clang-arg=-std=c++20` added by hand to rule out the C++17 importer default) with: error: semantics TODO: `interop with unsupported type` and: error: no member named 'HasGet' in namespace 'Carbon' at `requires Carbon::HasGet<T>` — interfaces are not exported to C++ at all, matching the gap-analysis audit ("the export direction (Carbon predicates as C++20 concepts) has no trace").
//
// The missing slice of this PARTIAL bullet: a Carbon interface (the named
// predicate) used as a C++20 concept in a `requires` clause of C++ code that
// consumes Carbon types. Carbon classes and their members DO export
// (Carbon::Tally in cpp_type_export_carbon_class.carbon, same mid-file
// `inline Cpp '''...'''` form from check/testdata/interop/cpp/class/export/),
// so the constrained function call below is the first thing that should
// start passing once interface export lands: UseGet's `requires
// Carbon::HasGet<T>` would be satisfied by `impl Val as HasGet` and return
// 5.

import Core library "io";
import Cpp;

interface HasGet {
  fn Get(self: Self) -> i32;
}

class Val {
  var v: i32;
}
impl Val as HasGet {
  fn Get(self: Self) -> i32 { return self.v; }
}

inline Cpp '''
template<typename T> requires Carbon::HasGet<T>
int UseGet(T t) { return t.Get(); }
''';

fn Run() -> i32 {
  var x: Val = {.v = 5};
  Core.Print(Cpp.UseGet(x));
  return 0;
}
