// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/uint.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/choice/single_payload_alternative.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/choice/single_payload_alternative.carbon

// --- single_payload_alternative.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
// A single payload-carrying alternative (review F-A1): with fewer than two
// alternatives there are no discriminant bits, so the discriminant field is
// the empty tuple, and the composed constructor pairs a zero-bit `()`
// discriminant initialization with the payload-region store.
choice OneShot {
  Only(x: i32)
}

fn Make(x: i32) -> OneShot {
  return OneShot.Only(x);
}

// A constructor call bound directly, and one through a function call.
let direct: OneShot = OneShot.Only(3);
let made: OneShot = Make(7);
//@dump-sem-ir-end
