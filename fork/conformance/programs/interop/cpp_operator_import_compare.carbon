// CONFORMANCE-BULLET: Type system: C++ interop — synthesizing Carbon overloads for imported C++ types
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   1
//   0
//   1
//   0
//   1
//   0
//
// Imported C++ comparison operators synthesized into Carbon's Core.EqWith and
// Core.OrderedWith impls: `==`/`!=`/`<`/`<=`/`>`/`>=` on a C++ struct used
// directly from Carbon. Inline C++ + friend-operator shape verbatim from
// toolchain/lower/testdata/interop/cpp/operators.carbon (eq_with/ordered_with);
// direct non-generic use `c1 == c2` etc. from check/testdata/interop/cpp/
// operators/operators.carbon (import_binary_operators.carbon); static member
// call returning by value from check/testdata/interop/cpp/class/import/
// method.carbon.

import Cpp inline '''c++
struct Meters {
  int count;

  static auto Make(int n) -> Meters { return Meters{n}; }

  friend auto operator==(Meters x, Meters y) -> bool { return x.count == y.count; }
  friend auto operator!=(Meters x, Meters y) -> bool { return !(x == y); }
  friend auto operator<(Meters x, Meters y) -> bool { return x.count < y.count; }
  friend auto operator>(Meters x, Meters y) -> bool { return y < x; }
  friend auto operator<=(Meters x, Meters y) -> bool { return !(y < x); }
  friend auto operator>=(Meters x, Meters y) -> bool { return !(x < y); }
};
''';

import Core library "io";

fn PrintBool(b: bool) {
  if (b) {
    Core.Print(1);
  } else {
    Core.Print(0);
  }
}

fn Run() -> i32 {
  var a: Cpp.Meters = Cpp.Meters.Make(30);
  var a2: Cpp.Meters = Cpp.Meters.Make(30);
  var b: Cpp.Meters = Cpp.Meters.Make(42);

  PrintBool(a == a2);
  PrintBool(a != a2);
  PrintBool(a < b);
  PrintBool(b <= a);
  PrintBool(b > a);
  PrintBool(a >= b);
  return 0;
}
