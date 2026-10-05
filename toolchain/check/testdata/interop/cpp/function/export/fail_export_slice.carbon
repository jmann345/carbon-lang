// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/function/export/fail_export_slice.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/function/export/fail_export_slice.carbon

// Fork (SL-2, fork/slices/plan.md §4.B `fail_no_span_header`; §1.B.2): the
// same `Sum` as slice.carbon referenced from inline C++ in a TU that declares
// no `std::span`. `LookupCppClassTemplate({"std", "span"})` finds nothing, the
// parameter maps to the null type, and the EXISTING parameter-site TODO
// reports it: predicted `SemanticsTodo` "semantics TODO: `failed to map Carbon
// type to C++`" (export.cpp, `BuildCppFunctionDeclForNonGenericCarbonFn`),
// followed by Clang's "no member named 'Sum' in namespace 'Carbon'". No new
// diagnostic kind.

// --- fail_no_span_header.carbon

library "[[@TEST_NAME]]";

import Cpp;

// CHECK:STDERR: fail_no_span_header.carbon:[[@LINE+4]]:1: error: semantics TODO: `failed to map C++ type to Carbon` [SemanticsTodo]
// CHECK:STDERR: fn Sum(s: Core.Slice(const i32)) -> i32 {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn Sum(s: Core.Slice(const i32)) -> i32 {
  var total: i32 = 0;
  var i: i64 = 0;
  while (i < s.Size()) {
    total += s[i];
    ++i;
  }
  return total;
}

inline Cpp '''
inline int F() {
  int a[2] = {1, 2};
  // CHECK:STDERR: fail_no_span_header.carbon:[[@LINE+4]]:18: error: no member named 'Sum' in namespace 'Carbon' [CppInteropParseError]
  // CHECK:STDERR:    27 |   return Carbon::Sum(a);
  // CHECK:STDERR:       |                  ^~~
  // CHECK:STDERR:
  return Carbon::Sum(a);
}
''';
