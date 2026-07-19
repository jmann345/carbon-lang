// CONFORMANCE-BULLET: Functions: C++ interop — importing C++ overload sets
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   16
//   32
//   64
//   -1
//   42
//   -40
//
// Imports a C++ free-function overload set and a member-function overload
// set, and resolves each call by the Carbon argument's type via real Clang
// Sema overload resolution: i16 -> short, i32 -> int, i64 -> long,
// f64 -> double, all through one imported name. Overload-set shapes from
// check/testdata/interop/cpp/function/import/overloads.carbon
// (import_overloaded_functions: `Cpp.foo(1 as i32)` vs `foo(short)`/
// `foo(int)`); inline-import syntax from check/testdata/interop/cpp/basics/
// inline/import.carbon; static factory + method-call pattern from
// check/testdata/interop/cpp/class/import/method.carbon and the existing
// interop/cpp_operator_import_arithmetic.carbon (`Cpp.Acc.Make(30)`).

import Core library "io";
import Cpp inline '''c++

inline auto width(short a) -> int { return 16; }
inline auto width(int a) -> int { return 32; }
inline auto width(long a) -> int { return 64; }
inline auto width(double a) -> int { return -1; }

struct Box {
  int v;
  static auto Make(int n) -> Box { return Box{n}; }
  auto tag(int a) -> int { return v + a; }
  auto tag(double a) -> int { return -v; }
};

''';

fn Run() -> i32 {
  var s: i16 = 7;
  var i: i32 = 7;
  var l: i64 = 7;
  var d: f64 = 7.5;
  Core.Print(Cpp.width(s));
  Core.Print(Cpp.width(i));
  Core.Print(Cpp.width(l));
  Core.Print(Cpp.width(d));

  // Member-function overload set on an imported C++ class.
  var b: Cpp.Box = Cpp.Box.Make(40);
  Core.Print(b.tag(2));
  Core.Print(b.tag(1.5));
  return 0;
}
