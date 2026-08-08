// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/primitives/char.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/primitives/char.carbon
// CHECK:STDERR: {{.*}}/prelude/try.carbon:20:1: error: name `Core.ImplicitAs` implicitly referenced here, but not found [CoreNameNotFound]
// CHECK:STDERR: choice ControlFlow(C: type, B: type) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: {{.*}}/prelude/try.carbon:20:1: error: name `Core.ImplicitAs` implicitly referenced here, but not found [CoreNameNotFound]
// CHECK:STDERR: choice ControlFlow(C: type, B: type) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:

class CharLike {
  impl as Core.ImplicitAs(char) {
    fn Convert(unused self) -> char { return 'x'; }
  }
}

fn Discard[T: type](unused x: T) {}

fn Convert(c: char, u: u8) {
  Discard(c as u8);
  Discard(c as u16);
  Discard(c as u32);
  // Note, no conversion to i8 as u8 doesn't implicitly convert to i8.
  Discard(c as i16);
  Discard(c as i32);
  Discard(u as char);
}

fn ConvertConstant() {
  Discard(('x' as char) as u8);
  Discard(('x' as char) as u16);
  Discard(('x' as char) as u32);
  Discard(('x' as char) as i16);
  Discard(('x' as char) as i32);
  Discard((123 as u8) as char);
}

fn CompareCharChar(a: char, b: char) {
  Discard(a == b);
  Discard(a != b);
  Discard(a < b);
  Discard(a <= b);
  Discard(a > b);
  Discard(a >= b);
}

fn CompareCharCharLike(a: char, b: CharLike) {
  Discard(a == b);
  Discard(a != b);
  Discard(a < b);
  Discard(a <= b);
  Discard(a > b);
  Discard(a >= b);

  Discard(b == a);
  Discard(b != a);
  Discard(b < a);
  Discard(b <= a);
  Discard(b > a);
  Discard(b >= a);
}

fn SubCharChar(c: char, d: CharLike) {
  Discard(c - c);
  Discard(c - d);
  Discard(d - c);
}

fn AddSubInt8(c: char, i: i8) {
  Discard(c + i);
  Discard(i + c);
  Discard(c - i);
}

fn AddSubInt16(c: char, i: i16) {
  Discard(c + i);
  Discard(i + c);
  Discard(c - i);
}

fn AddSubInt32(c: char, i: i32) {
  Discard(c + i);
  Discard(i + c);
  Discard(c - i);
}

fn AddSubUInt8(c: char, i: u8) {
  Discard(c + i);
  Discard(i + c);
  Discard(c - i);
}

fn AddSubUInt16(c: char, i: u16) {
  Discard(c + i);
  Discard(i + c);
  Discard(c - i);
}

fn AddSubUInt32(c: char, i: u32) {
  Discard(c + i);
  Discard(i + c);
  Discard(c - i);
}

