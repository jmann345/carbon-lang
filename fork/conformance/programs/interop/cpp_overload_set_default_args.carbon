// CONFORMANCE-BULLET: Functions: C++ interop — importing C++ overload sets
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   111
//   103
//   6
//   30
//   42
//
// Default arguments in imported C++ overload resolution: a free function
// with two defaulted parameters called with one, two, and three arguments,
// and a static member function with a defaulted parameter called with and
// without it — Clang Sema fills in the C++-side default values. Shapes from
// check/testdata/interop/cpp/function/import/default_arg.carbon
// (call_with_default: `Cpp.GlobalReturnInt(1, 2)` against
// `GlobalReturnInt(int, int, int c = 1, int d = 2)`, and static member
// `Cpp.X.C(1)` against `static void C(int a, int b = 1)`).

import Core library "io";
import Cpp inline '''c++

inline auto acc(int a, int b = 10, int c = 100) -> int { return a + b + c; }

struct Fmt {
  static auto Scale(int a, int b = 5) -> int { return a * b; }
};

''';

fn Run() -> i32 {
  Core.Print(Cpp.acc(1));
  Core.Print(Cpp.acc(1, 2));
  Core.Print(Cpp.acc(1, 2, 3));
  Core.Print(Cpp.Fmt.Scale(6));
  Core.Print(Cpp.Fmt.Scale(6, 7));
  return 0;
}
