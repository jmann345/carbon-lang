// CONFORMANCE-BULLET: Type system: Single inheritance
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   4
//   4
//   4
//   4
//   3
//
// Single (non-virtual) inheritance: `base class` + `extend base:`, unqualified
// access to inherited fields and methods through the derived class, explicit
// `.base` subobject access, and implicit derived-to-base pointer conversion.
// Shapes verbatim from toolchain/check/testdata/class/inheritance/
// base_field.carbon, base_method.carbon, derived_to_base.carbon and
// toolchain/lower/testdata/class/base.carbon.

import Core library "io";

base class Animal {
  var legs: i32;
  fn Legs(ref self) -> i32 { return self.legs; }
}

class Dog {
  extend base: Animal;
  var tricks: i32;
}

fn LegsViaBase(a: Animal*) -> i32 {
  return a->Legs();
}

fn Run() -> i32 {
  var d: Dog = {.base = {.legs = 4}, .tricks = 3};
  Core.Print(d.Legs());
  Core.Print(d.legs);
  Core.Print(d.base.legs);
  Core.Print(LegsViaBase(&d));
  Core.Print(d.tricks);
  return 0;
}
