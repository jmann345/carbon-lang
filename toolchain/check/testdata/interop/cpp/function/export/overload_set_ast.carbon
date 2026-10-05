// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --dump-cpp-ast
// SET-CHECK-SUBSET
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/function/export/overload_set_ast.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/function/export/overload_set_ast.carbon

// The C++ AST an exported Carbon `overload fn` set produces (fork decision
// F-009; fork/overload/plan.md OV-3): C++ name lookup receives one declaration
// per member under the shared name — two `FunctionDecl`s in `namespace
// Carbon`, or two `CXXMethodDecl`s of the exported class, lvalue-ref-qualified
// (`&`) for `ref self` members — each an inline function whose body calls the
// member's own Carbon thunk (`F__carbon_thunk`, two same-named declarations
// told apart by their parameter types and by the asm labels
// `_CF__carbon_thunk:overload<N>...`). The sibling `overload_set.carbon` pins
// the Carbon side's selections; this file pins what Clang is handed.

// --- overload_set.carbon

library "[[@TEST_NAME]]";

import Cpp;

overload fn F(unused x: i64) -> i32 { return 1; }
overload fn F(unused b: bool) -> i32 { return 2; }

inline Cpp '''
inline int CallBool() { return Carbon::F(true); }
inline int CallWithLong() { return Carbon::F(7L); }
''';

fn Use() -> i32 { return Cpp.CallBool() + Cpp.CallWithLong(); }

// --- method_set.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Acc {
  var total: i32;
  fn Make() -> Acc { return {.total = 0}; }
  overload fn Add(ref self, x: i32) { self.total = self.total + x; }
  overload fn Add(ref self, flag: bool) {
    if (flag) { self.total = self.total + 100; }
  }
  fn Get(self) -> i32 { return self.total; }
}

inline Cpp '''
inline int Drive() {
  auto a = Carbon::Acc::Make();
  a.Add(1);
  a.Add(true);
  return a.Get();
}
''';

fn Use() -> i32 { return Cpp.Drive(); }
