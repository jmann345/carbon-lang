// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/template/template_constraint.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/template/template_constraint.carbon

// A dependent method call through a `template constraint` binding lowers as an
// ordinary call to the type's own method: a satisfied conversion adds no
// witnesses, so nothing under toolchain/lower/ changes (fork decision F-010 /
// SC-1, fork/structural/plan.md §1.E; the merging.carbon `InitAndCallF`
// precedent).

// --- call_method.carbon
library "[[@TEST_NAME]]";

template constraint HasGet {
  fn Get(self) -> i32;
}

class StructuralOnly {
  fn Get(self) -> i32 { return 42; }
}

fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }

fn Run() -> i32 {
  let s: StructuralOnly = {};
  return CallGet(s);
}
