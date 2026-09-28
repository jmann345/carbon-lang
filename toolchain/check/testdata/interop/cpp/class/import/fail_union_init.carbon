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
// (D-UN-5's `is_cpp_scope` exclusion), and a union that is not a C++ aggregate
// (it declares a constructor) is not designated-initializable from Carbon, so
// Carbon never bypasses the constructor ("Carbon code is never more permitted
// than C++ code"; the same gate the `{}` path applies at import). The positive
// twin is union_init.carbon.

// --- pair.h

union Pair {
  int a;
  int b;
};

// --- fail_init_two_fields.carbon

library "[[@TEST_NAME]]";

import Cpp library "pair.h";

fn F() {
  // CHECK:STDERR: fail_init_two_fields.carbon:[[@LINE+4]]:28: error: initializer for union `Cpp.Pair` must designate exactly one field; found 2 [UnionInitNotSingleField]
  // CHECK:STDERR:   var unused u: Cpp.Pair = {.a = 1, .b = 2};
  // CHECK:STDERR:                            ^~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  var unused u: Cpp.Pair = {.a = 1, .b = 2};
}

// --- fail_init_unknown_field.carbon

library "[[@TEST_NAME]]";

import Cpp library "pair.h";

fn F() {
  // CHECK:STDERR: fail_init_unknown_field.carbon:[[@LINE+4]]:28: error: union `Cpp.Pair` has no field named `nope` [UnionInitUnknownField]
  // CHECK:STDERR:   var unused u: Cpp.Pair = {.nope = 1};
  // CHECK:STDERR:                            ^~~~~~~~~~~
  // CHECK:STDERR:
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
  // CHECK:STDERR: fail_copy_nontrivial_member.carbon:[[@LINE+8]]:10: error: attempt to use a deleted function [CppInteropParseError]
  // CHECK:STDERR:    15 |   return a;
  // CHECK:STDERR:       |          ^
  // CHECK:STDERR: fail_copy_nontrivial_member.carbon:[[@LINE-6]]:10: in file included here [InCppInclude]
  // CHECK:STDERR: ./nontrivial_member.h:8:6: note: copy constructor of 'U' is implicitly deleted because variant field 'nt' has a non-trivial copy constructor [CppInteropParseNote]
  // CHECK:STDERR:     8 |   NT nt;
  // CHECK:STDERR:       |      ^
  // CHECK:STDERR:
  return a;
}

// --- non_aggregate.h

union U {
  U() : a(0) {}
  int a;
  float f;
};

// --- fail_init_non_aggregate.carbon

library "[[@TEST_NAME]]";

import Cpp library "non_aggregate.h";

// Not an aggregate: the struct literal falls through to the imported-class
// bailout and the ordinary conversion failure, exactly as for a non-aggregate
// class (non_aggregate_init.carbon).
fn F() {
  // CHECK:STDERR: fail_init_non_aggregate.carbon:[[@LINE+7]]:3: error: cannot implicitly convert expression of type `{.a: Core.IntLiteral}` to `Cpp.U` [ConversionFailure]
  // CHECK:STDERR:   var unused u: Cpp.U = {.a = 1};
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR: fail_init_non_aggregate.carbon:[[@LINE+4]]:3: note: type `{.a: Core.IntLiteral}` does not implement interface `Core.ImplicitAs(Cpp.U)` [MissingImplInMemberAccessInContext]
  // CHECK:STDERR:   var unused u: Cpp.U = {.a = 1};
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  var unused u: Cpp.U = {.a = 1};
}
