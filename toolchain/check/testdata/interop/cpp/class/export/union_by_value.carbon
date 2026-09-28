// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/class/export/union_by_value.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/class/export/union_by_value.carbon

// PROBE (fork/unions/plan.md §4.B, rev B F-5): an exported Carbon union passed
// BY VALUE into a C++ function. No landed golden exercises a C++ function
// taking an exported Carbon class by value; the hand trace says it works
// (`Carbon::Wide` maps back to the Carbon class through `MapTagType`'s
// `clang_decls` lookup exactly as the by-pointer parameter and the by-value
// return of union.carbon do, and `IsCppThunkRequired` routes the non-simple
// parameter through the same thunk an imported union takes in
// function/import/union.carbon, the callee argument passed by address). If
// the fill instead shows a `SemanticsTodo`, this file is renamed with the
// `fail_` prefix, the residue "exported union passed by value into C++" is
// filed and the gap row stays PARTIAL (§8.6).

// --- by_value_param.carbon
library "[[@TEST_NAME]]";
import Cpp;

union Wide {
  var lo: i32;
  var both: i64;
}

inline Cpp '''
int SumLo(Carbon::Wide w) { return w.lo + 1; }
''';

fn F(w: Wide) -> i32 {
  //@dump-sem-ir-begin
  return Cpp.SumLo(w);
  //@dump-sem-ir-end
}
