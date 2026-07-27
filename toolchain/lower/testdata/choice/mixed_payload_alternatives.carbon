// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/choice/mixed_payload_alternatives.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/choice/mixed_payload_alternatives.carbon

// A zero-parameter function alternative (`None()`) of a payload-carrying
// choice: its constructor's class_init must carry an element for the payload
// region (an uninitialized value, lowered as poison), so the constant folded
// from it has the same field count as the LLVM struct type. Constructing all
// three alternative forms pins the constructor bodies and the constant for
// the parenless alternative.

choice MaybeInt {
  None(),
  Missing,
  Some(x: i64)
}

fn MakeNone() -> MaybeInt {
  return MaybeInt.None();
}

let missing: MaybeInt = MaybeInt.Missing;

fn MakeSome(x: i64) -> MaybeInt {
  return MaybeInt.Some(x);
}

let none: MaybeInt = MakeNone();
let some: MaybeInt = MakeSome(42);
