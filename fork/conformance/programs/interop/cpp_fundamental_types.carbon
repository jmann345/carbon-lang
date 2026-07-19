// CONFORMANCE-BULLET: Stdlib C++ interop: transparent fundamental-type mapping
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   1
//   B
//   42
//   255
//   1
//   2
//
// Carbon fundamental types cross the C++ call boundary transparently, with no
// adapter or cast at the boundary: bool -> bool, char -> char, i32/i16 ->
// int/short, u32/u8 -> unsigned int/unsigned char, f64 -> double, f32 ->
// float, and each C++ return type binds directly to the matching Carbon type.
// Mapping evidence: check/cpp/type_mapping.cpp (CharTy at type_mapping.cpp:180)
// and check/testdata/interop/cpp/primitive_types/arithmetic.carbon
// (supported_types.carbon: Cpp.int is i32, Cpp.unsigned_char is u8, ...).
// `import Cpp inline` definitions are emitted into the program's own module
// (lower/testdata/interop/cpp/function/import/import_inline.carbon), so this
// links without any sibling C++ object file. Call shapes follow
// check/testdata/interop/cpp/function/import/arithmetic_types_direct.carbon.

import Core library "io";

import Cpp inline '''
auto Negate(bool b) -> bool { return !b; }
auto NextChar(char c) -> char { return static_cast<char>(c + 1); }
auto AddInt(int a, short b) -> int { return a + b; }
auto MixUnsigned(unsigned int a, unsigned char b) -> unsigned int { return a + b; }
auto Halve(double x) -> double { return x / 2.0; }
auto Truncate(float f) -> int { return static_cast<int>(f); }
''';

fn Run() -> i32 {
  // bool -> bool -> bool round trip.
  let flag: bool = Cpp.Negate(false);
  if (flag) { Core.Print(1); } else { Core.Print(0); }

  // char -> char -> char round trip; result printed via inline putchar.
  Core.PrintChar(Cpp.NextChar('A'));
  Core.PrintChar('\n');

  // i32 -> int, i16 -> short; int result binds to i32 (Core.Print's param).
  let a: i32 = 40;
  let b: i16 = 2;
  Core.Print(Cpp.AddInt(a, b));

  // u32 -> unsigned int, u8 -> unsigned char; result binds to u32.
  let ua: u32 = 250;
  let ub: u8 = 5;
  Core.Print(Cpp.MixUnsigned(ua, ub) as i32);

  // f64 -> double -> f64 round trip (exact in binary floating point).
  let h: f64 = Cpp.Halve(9.0);
  if (h == (4.5 as f64)) { Core.Print(1); } else { Core.Print(0); }

  // f32 -> float; int result binds to i32.
  let f: f32 = 2.75;
  Core.Print(Cpp.Truncate(f));

  return 0;
}
