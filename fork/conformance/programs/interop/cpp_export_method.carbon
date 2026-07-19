// CONFORMANCE-BULLET: Functions: C++ interop — exporting Carbon functions/methods to C++
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   123
//   7
//
// Reverse interop for methods: C++ code in an `inline Cpp` block constructs a
// Carbon class via its exported static factory, mutates it through a
// `ref self` method with an argument, reads it back through a value-`self`
// method, and calls a class (static) function — all through the exported
// `Carbon::Counter` type and its thunks. Shapes verbatim from
// toolchain/check/testdata/interop/cpp/class/export/field.carbon
// (fail_private_field split: `auto c = Carbon::C::Make();`),
// toolchain/check/testdata/interop/cpp/class/export/method.carbon
// (ref_method_lvalue + static_method splits), and toolchain/lower/testdata/
// interop/cpp/class/export/method.carbon (method_with_args_and_return split:
// `fn CallCallF() -> i32 { return Cpp.CallF(); }`).

import Core library "io";
import Cpp;

class Counter {
  fn Make() -> Counter {
    return {.count = 0};
  }

  fn Bump(ref self, n: i32) {
    self.count += n;
  }

  fn Get(self) -> i32 {
    return self.count;
  }

  fn StaticValue() -> i32 {
    return 123;
  }

  var count: i32;
}

inline Cpp '''
inline int StaticThroughCpp() {
  return Carbon::Counter::StaticValue();
}

inline int DriveCounterInCpp() {
  auto c = Carbon::Counter::Make();
  c.Bump(3);
  c.Bump(4);
  return c.Get();
}
''';

fn Run() -> i32 {
  Core.Print(Cpp.StaticThroughCpp());
  Core.Print(Cpp.DriveCounterInCpp());
  return 0;
}
