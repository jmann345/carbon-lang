// CONFORMANCE-BULLET: Stdlib: interfaces powering language syntax (operators, conversions)
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   37
//   100
//   212
//   98
//   42
//
// Core conversion interfaces powering conversion syntax
// (core/prelude/operators/as.carbon): implicit argument/initializer
// conversion via a user impl of Core.ImplicitAs (impl shape verbatim from
// toolchain/check/testdata/operators/overloaded/implicit_as.carbon,
// `impl i32 as Core.ImplicitAs(X)`), explicit `as` via a user impl of
// Core.As (toolchain/check/testdata/as/basics.carbon), `as` reaching an
// ImplicitAs impl through the prelude's "ImplicitAs extends As" blanket-impl
// workaround (as.carbon:27), and `unsafe as` pointer casts via the prelude's
// `T* as UnsafeAs(U*)` impl (use shape verbatim from
// examples/interop/cpp/socket.carbon `&address unsafe as Cpp.sockaddr*`).

import Core library "io";

class Celsius {
  var deg: i32;
}

class Fahrenheit {
  var deg: i32;
}

impl i32 as Core.ImplicitAs(Celsius) {
  fn Convert(self: i32) -> Celsius { return {.deg = self}; }
}

impl Celsius as Core.As(Fahrenheit) {
  fn Convert(self: Celsius) -> Fahrenheit {
    return {.deg = (self.deg * 9) / 5 + 32};
  }
}

fn DegreesC(c: Celsius) -> i32 {
  return c.deg;
}

fn Run() -> i32 {
  let body: i32 = 37;
  Core.Print(DegreesC(body));

  let hundred: i32 = 100;
  let boiling: Celsius = hundred;
  Core.Print(boiling.deg);

  let f: Fahrenheit = boiling as Fahrenheit;
  Core.Print(f.deg);

  let g: Fahrenheit = (body as Celsius) as Fahrenheit;
  Core.Print(g.deg);

  var n: i32 = 42;
  let u: u32* = &n unsafe as u32*;
  Core.Print((*u) as i32);
  return 0;
}
