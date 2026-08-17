// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/int.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/interop/cpp/globals_carbon_defined.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/interop/cpp/globals_carbon_defined.carbon

// The F8a mechanism probe for defect TA-D3 (fork/f008/plan.md §2.1/§2.3):
// CARBON-defined file-scope globals of imported C++ class types — the
// SPECIALIZATION-typed shape that was measured to compile but link with
// `undefined symbol: _Cgcount.Main.1` (real `<atomic>`,
// fork/design-sprint/threading-atomics.md:103), next to the plain
// imported-class control that links fine (matrix row 14). The autoupdated
// IR dump shows, in a reviewed diff, whether `g`'s global is one defined
// object, a bare declaration missed by the definition walk, or a duplicate
// `.1`-suffixed pair — distinguishing fix-site hypotheses H1-H3. Dump-only:
// this golden never LINKS, so it cannot adjudicate H0 ("fixed upstream");
// H0 is settled by F8c's first-step runner run of the real-header pair
// cpp_atomic_global_counter_diff (plan §2.3, adjudication D). The imported
// direction (C++-owned globals, no Carbon-side definition emitted) is
// covered by globals.carbon and must not move (plan §5 R-5).

// --- box.h

template <typename T> struct Box {
  T value;
};

struct Plain {
  int n;
};

// --- carbon_defined_globals.carbon

library "[[@TEST_NAME]]";

import Cpp library "box.h";

// The defect shape: a file-scope Carbon var typed by an imported C++
// template specialization.
var g: Cpp.Box(i32);

// The control: a plain imported-class-typed Carbon global.
var m: Cpp.Plain;

fn ReadSpecialized() -> i32 {
  return g.value;
}

fn ReadPlain() -> i32 {
  return m.n;
}
