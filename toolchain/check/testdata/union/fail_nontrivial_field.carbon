// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/union/fail_nontrivial_field.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/union/fail_nontrivial_field.carbon

// The 0.1 field rules (docs/design/unions.md, "Union fields"): every field
// must be trivially destructible and trivially copyable. All offending fields
// are reported.

// --- fail_destroy_impl_field.carbon
library "[[@TEST_NAME]]";

class Boxy {
  var n: i32;
  impl as Core.Destroy {
    fn Op(unused ref self) {}
  }
}

union U {
  var b: Boxy;
  var w: i32;
}

// --- fail_choice_field.carbon
library "[[@TEST_NAME]]";

// A choice-typed field is conservatively rejected in 0.1 although the design
// permits choices whose payloads are trivial (residue "union fields of
// choice type").
choice Signal {
  Go(speed: i32),
  Stop
}

union U {
  var s: Signal;
  var w: i32;
}

// --- fail_user_copy_field.carbon
library "[[@TEST_NAME]]";

// A `Core.Copy` impl declared outside package `Core` is a user-provided copy
// operation; the package is the boundary, whatever the body.
class Counted {
  var n: i32;
  impl as Core.Copy {
    fn Op(self) -> Self { return {.n = self.n + 1}; }
  }
}

union U {
  var c: Counted;
  var w: i32;
}

// --- fail_two_bad_fields.carbon
library "[[@TEST_NAME]]";

class Boxy {
  var n: i32;
  impl as Core.Destroy {
    fn Op(unused ref self) {}
  }
}

union U {
  var b1: Boxy;
  var b2: Boxy;
}

// --- point.h

struct Point {
  int x;
  int y;
};

union CppU {
  int a;
  float f;
};

// --- fail_cpp_class_field.carbon
library "[[@TEST_NAME]]";

import Cpp library "point.h";

// An imported C++ class or union is conservatively rejected in 0.1: the
// predicate never assumes triviality for a C++-owned class (residue "union
// fields of imported C++ type").
union U {
  var p: Cpp.Point;
  var u: Cpp.CppU;
  var w: i32;
}
