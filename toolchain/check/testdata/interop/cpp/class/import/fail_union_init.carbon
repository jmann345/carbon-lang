// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/class/import/fail_union_init.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/class/import/fail_union_init.carbon

// Negative pins for imported unions (fork/unions/plan.md UN-2, §4.B): the
// designated-initialization diagnostics of a native union apply unchanged to
// an imported one (`UnionInitNotSingleField`, `UnionInitUnknownField`), and a
// union whose member has a non-trivial copy constructor keeps C++'s deleted
// copy constructor — the copy is never the synthesized primitive copy
// (D-UN-5's `is_cpp_scope` exclusion; the positive twin is union_init.carbon).

// --- pair.h

union Pair {
  int a;
  int b;
};

// --- fail_init_two_fields.carbon

library "[[@TEST_NAME]]";

import Cpp library "pair.h";

fn F() {
  var unused u: Cpp.Pair = {.a = 1, .b = 2};
}

// --- fail_init_unknown_field.carbon

library "[[@TEST_NAME]]";

import Cpp library "pair.h";

fn F() {
  var unused u: Cpp.Pair = {.nope = 1};
}

// --- nontrivial_member.h

struct NT {
  NT(const NT&);
  int x;
};

union U {
  NT nt;
  int i;
};

// --- fail_copy_nontrivial_member.carbon

library "[[@TEST_NAME]]";

import Cpp library "nontrivial_member.h";

fn F(a: Cpp.U) -> Cpp.U {
  return a;
}
