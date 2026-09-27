// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/parse/testdata/union/basic.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/parse/testdata/union/basic.carbon

// The design's canonical declaration shape (docs/design/unions.md, "Declaring
// a union" and "Union members"): `var` fields and a method with `self`.
union IntOrBytes {
  var word: u32;
  var bytes: array(u8, 4);

  fn LowByte(self) -> u8 { return self.bytes[0]; }
}
