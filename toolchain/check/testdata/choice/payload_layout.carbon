// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/uint.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/choice/payload_layout.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/choice/payload_layout.carbon

// --- payload_layout.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
// Payload tuples of different sizes: per the F-007k storage contract
// (docs/design/unions.md, "Relationship to choice types"), the payload region
// is sized and aligned by the max-of-fields rule with every payload tuple at
// offset zero: (i64, i32) is 12 bytes with 8-byte alignment, (i32) is 4 bytes
// — the region must be 16 bytes (12 rounded up to alignment 8), not their
// sum.
choice Sized {
  Small(a: i32),
  Large(a: i64, b: i32),
  None
}

fn MakeSmall(n: i32) -> Sized {
  return Sized.Small(n);
}

fn MakeLarge(a: i64, b: i32) -> Sized {
  return Sized.Large(a, b);
}
//@dump-sem-ir-end
