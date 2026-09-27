// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/int.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/function/export/carbon_namespace_cpp_class.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/function/export/carbon_namespace_cpp_class.carbon

// A C++-declared class nested in `namespace Carbon` — the toolchain's export
// namespace, whose name lookup is answered by the Carbon external AST source
// (toolchain/check/cpp/generate_ast.cpp) — with an inline member function and
// a constructor. Their declarators run Clang's unqualified redeclaration
// lookup up through the namespace, so the external source is asked about the
// NAMESPACE with a constructor name (not a class) and with member names no
// Carbon entity has; it must answer "no external declarations", never crash
// (the shape `<carbon/expected.h>`'s `unexpected(E)` reaches, EH-B conformance
// run 36311899697). Prediction: the file compiles cleanly; the dumped SemIR is
// the plain call `Cpp.Use()` through `Use`'s fenced thunk, and `Carbon::F` is
// exported and called from inside the same block.

// --- carbon_namespace_cpp_class.carbon

library "[[@TEST_NAME]]";

import Cpp;

fn F(n: i32) -> i32 { return n; }

inline Cpp '''
namespace Carbon {
struct Holder {
  int v;
  int get() const { return v; }
  Holder(int n) : v(n) {}
};
}  // namespace Carbon

inline int Use() { return Carbon::Holder(Carbon::F(1)).get(); }
''';

//@dump-sem-ir-begin
fn G() -> i32 { return Cpp.Use(); }
//@dump-sem-ir-end
