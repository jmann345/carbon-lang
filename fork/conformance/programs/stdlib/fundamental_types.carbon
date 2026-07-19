// CONFORMANCE-BULLET: Stdlib: fundamental types (bool, iN, fN)
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   42
//   18
//   360
//   2
//   6
//   42
//   255
//   1
//
// bool, i32/i64/u8 arithmetic and conversions, f64 arithmetic + comparison.
// `as` conversions between integer widths: core/prelude/types/int.carbon
// (`Int(From) as As(Int(To))`) and uint.carbon (`UInt(From) as As(Int(To))`).
// `and`/`not` as in examples/advent2024 (day13_common.carbon, day14_common).
// Core.Print lowers inline to printf("%d\n", x)
// (toolchain/lower/handle_call.cpp), so no core io objects are needed at link.

import Core library "io";

fn Run() -> i32 {
  let a: i32 = 30;
  let b: i32 = 12;
  Core.Print(a + b);
  Core.Print(a - b);
  Core.Print(a * b);
  Core.Print(a / b);
  Core.Print(a % b);

  let big: i64 = 5000000000;
  let offset: i64 = 4999999958;
  Core.Print((big - offset) as i32);

  let byte: u8 = 200;
  Core.Print((byte as i32) + 55);

  let x: f64 = 1.5;
  let three: f64 = 3.0;
  if (x + x == three and not (a < b)) {
    Core.Print(1);
  } else {
    Core.Print(0);
  }
  return 0;
}
