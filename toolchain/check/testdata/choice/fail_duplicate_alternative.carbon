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
  // CHECK:STDERR: fail_two_constants.carbon:[[@LINE+7]]:3: error: duplicate name `A` being declared in the same scope [NameDeclDuplicate]
  // CHECK:STDERR:   A
  // CHECK:STDERR:   ^
  // CHECK:STDERR: fail_two_constants.carbon:[[@LINE-4]]:3: note: name is previously declared here [NameDeclPrevious]
  // CHECK:STDERR:   A,
  // CHECK:STDERR:   ^
  // CHECK:STDERR:
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
  // CHECK:STDERR: fail_constant_then_function.carbon:[[@LINE+7]]:3: error: duplicate name `B` being declared in the same scope [NameDeclDuplicate]
  // CHECK:STDERR:   B(x: i32)
  // CHECK:STDERR:   ^
  // CHECK:STDERR: fail_constant_then_function.carbon:[[@LINE-4]]:3: note: name is previously declared here [NameDeclPrevious]
  // CHECK:STDERR:   B,
  // CHECK:STDERR:   ^
  // CHECK:STDERR:
  B(x: i32)
}

// --- fail_function_then_constant.carbon
library "[[@TEST_NAME]]";

// The reverse order: the constructor for the first alternative is built and
// registered, and the duplicate constant alternative is dropped. The
// reference below resolves to the constructor function.
choice E {
  B(x: i32),
  // CHECK:STDERR: fail_function_then_constant.carbon:[[@LINE+7]]:3: error: duplicate name `B` being declared in the same scope [NameDeclDuplicate]
  // CHECK:STDERR:   B
  // CHECK:STDERR:   ^
  // CHECK:STDERR: fail_function_then_constant.carbon:[[@LINE-4]]:3: note: name is previously declared here [NameDeclPrevious]
  // CHECK:STDERR:   B(x: i32),
  // CHECK:STDERR:   ^
  // CHECK:STDERR:
  B
}

fn F(n: i32) -> E {
  return E.B(n);
}

// --- fail_function_duplicate_then_function.carbon
library "[[@TEST_NAME]]";

// The alignment-critical shape (landing-review advisory): a duplicate
// FUNCTION-like alternative followed by a later function-like alternative.
// The duplicate is skipped in both the classify and build loops, so the
// constructor list must stay index-aligned for `C` past the skipped `B`.
choice X {
  B(x: i32),
  // CHECK:STDERR: fail_function_duplicate_then_function.carbon:[[@LINE+7]]:3: error: duplicate name `B` being declared in the same scope [NameDeclDuplicate]
  // CHECK:STDERR:   B(y: i32),
  // CHECK:STDERR:   ^
  // CHECK:STDERR: fail_function_duplicate_then_function.carbon:[[@LINE-4]]:3: note: name is previously declared here [NameDeclPrevious]
  // CHECK:STDERR:   B(x: i32),
  // CHECK:STDERR:   ^
  // CHECK:STDERR:
  B(y: i32),
  C(z: i32)
}

fn G(n: i32) -> X {
  return X.C(n);
}

// --- fail_triple_occurrence.carbon
library "[[@TEST_NAME]]";

// Three occurrences: one diagnostic per extra occurrence, each noting the
// FIRST declaration (the map keeps the first value).
choice T {
  A,
  // CHECK:STDERR: fail_triple_occurrence.carbon:[[@LINE+7]]:3: error: duplicate name `A` being declared in the same scope [NameDeclDuplicate]
  // CHECK:STDERR:   A,
  // CHECK:STDERR:   ^
  // CHECK:STDERR: fail_triple_occurrence.carbon:[[@LINE-4]]:3: note: name is previously declared here [NameDeclPrevious]
  // CHECK:STDERR:   A,
  // CHECK:STDERR:   ^
  // CHECK:STDERR:
  A,
  // CHECK:STDERR: fail_triple_occurrence.carbon:[[@LINE+7]]:3: error: duplicate name `A` being declared in the same scope [NameDeclDuplicate]
  // CHECK:STDERR:   A
  // CHECK:STDERR:   ^
  // CHECK:STDERR: fail_triple_occurrence.carbon:[[@LINE-12]]:3: note: name is previously declared here [NameDeclPrevious]
  // CHECK:STDERR:   A,
  // CHECK:STDERR:   ^
  // CHECK:STDERR:
  A
}
