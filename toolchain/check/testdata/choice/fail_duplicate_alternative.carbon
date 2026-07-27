// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/uint.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/choice/fail_duplicate_alternative.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/choice/fail_duplicate_alternative.carbon

// --- fail_two_constants.carbon
library "[[@TEST_NAME]]";

// Two constant alternatives with the same name: the second is diagnosed as a
// duplicate and dropped. A later reference to the name resolves to the first
// alternative, so the use below produces no further diagnostic.
choice C {
  A,
  A
}

let c: C = C.A;

// --- fail_constant_then_function.carbon
library "[[@TEST_NAME]]";

// A constant alternative followed by a function-like alternative with the
// same name: still a duplicate — a parameter list does not overload the
// alternative name. The duplicate is dropped before payload validation, so
// no payload region is built for it.
choice D {
  B,
  B(x: i32)
}

// --- fail_function_then_constant.carbon
library "[[@TEST_NAME]]";

// The reverse order: the constructor for the first alternative is built and
// registered, and the duplicate constant alternative is dropped. The
// reference below resolves to the constructor function.
choice E {
  B(x: i32),
  B
}

fn F(n: i32) -> E {
  return E.B(n);
}
