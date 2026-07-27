// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/uint.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/choice/mixed_payload_alternatives.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/choice/mixed_payload_alternatives.carbon

// --- mixed_payload_alternatives.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
choice MaybeInt {
  None(),
  Missing,
  Some(x: i64)
}

// A zero-parameter function alternative of a payload-carrying choice: its
// constructor must cover the payload region with an uninitialized value so
// the class_init's element count matches the object representation.
fn MakeNone() -> MaybeInt {
  return MaybeInt.None();
}

// A parenless constant alternative: the conversion covers the payload field.
let missing: MaybeInt = MaybeInt.Missing;

// A payload-carrying alternative.
fn MakeSome(x: i64) -> MaybeInt {
  return MaybeInt.Some(x);
}

let none: MaybeInt = MakeNone();
let some: MaybeInt = MakeSome(42);
//@dump-sem-ir-end
