// CONFORMANCE-BULLET: Type system: C++ interop — bi-directional inheritance, hierarchy roots, abstract/final/virtual mapping
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   1
//   2
//
// Carbon-extends-C++ direction: a Carbon class uses an imported C++ class as
// its hierarchy root (`extend base: Cpp.Animal`), overrides the C++ virtual
// with `override fn` (signature adapted C++ `int` <-> Carbon `i32` by the
// interop thunk machinery), and a C++ function calls back through a C++
// base reference so dispatch must go through the vtable. Shapes verbatim
// from toolchain/lower/testdata/interop/cpp/class/import/dynamic.carbon
// (`{.base = Cpp.Base.Base()}` construction, `Cpp.Use(ref d)`) and
// toolchain/check/testdata/interop/cpp/class/import/abstract.carbon
// (`override fn f(unused ref self)` for a non-const C++ virtual).

import Core library "io";
import Cpp;

inline Cpp '''
struct Animal {
  virtual auto sound() -> int { return 1; }
};

auto SoundOf(Animal& a) -> int { return a.sound(); }
''';

class Dog {
  extend base: Cpp.Animal;
  override fn sound(unused ref self) -> i32 { return 2; }
}

fn Run() -> i32 {
  var a: Cpp.Animal = Cpp.Animal.Animal();
  var d: Dog = {.base = Cpp.Animal.Animal()};
  Core.Print(Cpp.SoundOf(ref a));
  Core.Print(Cpp.SoundOf(ref d));
  return 0;
}
