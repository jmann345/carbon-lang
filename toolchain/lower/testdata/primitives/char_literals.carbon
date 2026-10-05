// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/primitives/char_literals.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/primitives/char_literals.carbon
// CHECK:STDERR: {{.*}}/prelude/types/cpp/slice.carbon:69:9: error: cannot access member of interface `Destroy` in type `C.(CppContiguousRange.SizeType)` that does not implement that interface [MissingImplInMemberAccess]
// CHECK:STDERR:         self.Size().(ImplicitAs(u64).Convert)().(As(i64).Convert)());
// CHECK:STDERR:         ^~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: {{.*}}/prelude/types/cpp/slice.carbon:68:9: error: cannot access member of interface `Destroy` in type `C.(CppContiguousRange.DataType)` that does not implement that interface [MissingImplInMemberAccess]
// CHECK:STDERR:         self.Data().(CppDataPointer.Raw)(),
// CHECK:STDERR:         ^~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: {{.*}}/prelude/types/cpp/slice.carbon:64:1: error: orphan `impl` found; something in the self-type or constraint must be defined in the same file [ImplIsOrphan]
// CHECK:STDERR: impl forall [C: CppContiguous where .Element impls Copy & Destroy]
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:

class CharLike {
  impl as Core.ImplicitAs(char) {
    fn Convert(unused self) -> char { return 'x'; }
  }
}

fn Discard[T: type](unused x: T) {}

fn Convert() {
  Discard('x' as u8);
  Discard('x' as u16);
  Discard('x' as u32);
  Discard('x' as i8);
  Discard('x' as i16);
  Discard('x' as i32);
}

fn ConvertConstant() {
  Discard('x' as u8);
  Discard('x' as u16);
  Discard('x' as u32);
  Discard('x' as i16);
  Discard('x' as i32);
}

fn CompareChar(b: char) {
  // TODO: Should we support CharLiteral vs CharLiteral comparisons?

  Discard('x' == b);
  Discard('x' != b);
  Discard('x' < b);
  Discard('x' <= b);
  Discard('x' > b);
  Discard('x' >= b);

  Discard(b == 'x');
  Discard(b != 'x');
  Discard(b < 'x');
  Discard(b <= 'x');
  Discard(b > 'x');
  Discard(b >= 'x');
}

fn SubCharChar(c: char) {
  Discard('x' - 'y');
  Discard(c - 'x');
  Discard('x' - c);
}

fn AddSubIntLiteral() {
  // TODO: Should we support arithmetic with non-constant integers?
  // We currently require a cast to `char` first.

  Discard('x' + 1);
  Discard(1 + 'x');
  Discard('x' - 1);
}

fn AddSubInt8() {
  // TODO: Should we support arithmetic with non-constant integers?
  // We currently require a cast to `char` first.

  Discard('x' + (1 as i8));
  Discard((1 as i8) + 'x');
  Discard('x' - (1 as i8));
}

