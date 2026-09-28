// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/class/import/union_init.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/class/import/union_init.carbon

// An imported C++ union is a Carbon union (docs/design/unions.md, "Importing
// C++ unions"; fork/unions/plan.md UN-2, §4.B). With `is_union` set on import,
// a struct literal takes the designated single-field initialization of a
// native union (`ConvertStructToUnion`: one `class_element_access` and a
// one-element `class_init`, never a `struct_value` of the union type), the
// copy keeps C++'s copy constructor (D-UN-5's `is_cpp_scope` exclusion), and
// by-value crossings in both directions follow function/import/union.carbon.
// The negative pins are in fail_union_init.carbon.

// --- pair.h

union Pair {
  int a;
  int b;
};

// --- designated_init.carbon

library "[[@TEST_NAME]]";

import Cpp library "pair.h";

fn F() -> i32 {
  //@dump-sem-ir-begin
  var u: Cpp.Pair = {.a = 1};
  return u.b;
  //@dump-sem-ir-end
}

// --- empty.h

union Bar {};

// --- empty_init.carbon

library "[[@TEST_NAME]]";

import Cpp library "empty.h";

// An empty aggregate keeps its landed `StructType{}` representation, so `{}`
// stays accepted: the union arm sits inside the `CustomLayoutType` branch.
fn F() {
  //@dump-sem-ir-begin
  var unused b: Cpp.Bar = {};
  //@dump-sem-ir-end
}

// --- copy.carbon

library "[[@TEST_NAME]]";

import Cpp library "pair.h";

// The copy of an imported union is C++'s (trivial) copy constructor through
// `BuildCopyWitness` (check/cpp/impl_lookup.cpp), not the primitive copy the
// native-union gate synthesizes.
fn F(a: Cpp.Pair) -> Cpp.Pair {
  //@dump-sem-ir-begin
  var b: Cpp.Pair = a;
  return b;
  //@dump-sem-ir-end
}

// --- by_value.h

union Pair {
  int a;
  int b;
};

inline int ReadA(Pair u) { return u.a; }

inline Pair MakePair(int v) {
  Pair p;
  p.a = v;
  return p;
}

// --- by_value.carbon

library "[[@TEST_NAME]]";

import Cpp library "by_value.h";

// Carbon passes the union by value into C++ and receives one by value back.
fn F() -> i32 {
  //@dump-sem-ir-begin
  var u: Cpp.Pair = {.a = 1};
  var m: Cpp.Pair = Cpp.MakePair(2);
  return Cpp.ReadA(u) + m.b;
  //@dump-sem-ir-end
}
