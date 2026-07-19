// CONFORMANCE-BULLET: Generics: C++ interop — exporting Carbon templates/checked generics as C++ templates
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   42
//
// Second working slice: C++ template-argument deduction on a C++ builtin
// type. The exported checked generic is constrained by a user interface that
// `i32` impls; C++ calls it with a literal `int` argument, Clang deduces
// `T = int`, and ExportFunctionSpecializationToCpp (check/cpp/export.cpp)
// maps the specialization back onto the Carbon generic instantiated at
// `T = i32`, dispatching through `impl i32 as Scalable`. Builtin-typed
// arguments to exported generics are the shape proven in
// check/testdata/interop/cpp/function/export/generic.carbon
// (generic_pointer / fail_generic_unsupported_type: plain `int` deduces,
// only `volatile int` is rejected). Result returns through an `i32*`
// out-param since only void-returning generics export on this nightly
// (see cpp_generic_export_interface_dispatch.carbon).

import Core library "io";
import Cpp;

interface Scalable {
  fn Twice(self) -> i32;
}

impl i32 as Scalable {
  fn Twice(self) -> i32 { return self * 2; }
}

fn StoreTwice[T: Scalable](x: T, out: i32*) {
  *out = x.Twice();
}

inline Cpp '''
auto UseTwice() -> int {
  int out = 0;
  Carbon::StoreTwice(21, &out);
  return out;
}
''';

fn Run() -> i32 {
  Core.Print(Cpp.UseTwice());
  return 0;
}
