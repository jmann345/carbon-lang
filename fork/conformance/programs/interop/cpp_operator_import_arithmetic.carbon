// CONFORMANCE-BULLET: Type system: C++ interop — synthesizing Carbon overloads for imported C++ types
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   42
//   84
//   114
//   114
//   -114
//
// Imported C++ arithmetic operators synthesized onto Carbon interfaces:
// binary `+`/`*` (Core.AddWith/MulWith), compound `+=` (Core.AddAssignWith),
// unary `-` (Core.Negate), plus the synthesized Core.Copy impl from the
// implicit C++ copy constructor (`var e: Cpp.Acc = d;`). Operator shapes from
// check/testdata/interop/cpp/operators/arithmetic_operators.carbon and
// operators.carbon (import_binary_operators.carbon: `c1 + c2`, `c1 += c2`);
// copy synthesis from check/testdata/interop/cpp/impls/copy.carbon; field
// read `d.total` from lower/testdata/interop/cpp/class/import/field.carbon.

import Cpp inline '''c++
struct Acc {
  int total;

  static auto Make(int n) -> Acc { return Acc{n}; }

  auto operator-() const -> Acc { return Acc{-total}; }

  friend auto operator+(Acc x, Acc y) -> Acc { return Acc{x.total + y.total}; }
  friend auto operator*(Acc x, Acc y) -> Acc { return Acc{x.total * y.total}; }
  friend auto operator+=(Acc& x, Acc y) -> Acc& {
    x.total = x.total + y.total;
    return x;
  }
};
''';

import Core library "io";

fn Run() -> i32 {
  var a: Cpp.Acc = Cpp.Acc.Make(30);
  var b: Cpp.Acc = Cpp.Acc.Make(12);

  var c: Cpp.Acc = a + b;
  Core.Print(c.total);

  var d: Cpp.Acc = c * Cpp.Acc.Make(2);
  Core.Print(d.total);

  d += a;
  Core.Print(d.total);

  // Synthesized Core.Copy impl from the implicit C++ copy constructor.
  var e: Cpp.Acc = d;
  Core.Print(e.total);

  var f: Cpp.Acc = -e;
  Core.Print(f.total);
  return 0;
}
