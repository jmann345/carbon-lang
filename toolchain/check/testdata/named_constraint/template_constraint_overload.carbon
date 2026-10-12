// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/named_constraint/template_constraint_overload.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/named_constraint/template_constraint_overload.carbon

// A `template T: HasGet` member of an `overload fn` set is probed without
// diagnostics; an unsatisfied structural member is skipped silently and
// first-match resolution is unchanged (fork decision F-010 / SC-1,
// fork/structural/plan.md D-SC-12; fork/overload/plan.md D-OV-4).

// --- overload.carbon
library "[[@TEST_NAME]]";

template constraint HasGet {
  fn Get(self) -> i32;
}

class C {
  fn Get(self) -> i32 { return 1; }
}

overload fn F[template T: HasGet](x: T) -> i32 { return x.Get(); }
overload fn F(unused x: i32) -> i32 { return 2; }

fn Test(c: C) -> i32 { return F(c) + F(3); }

// --- overload_catch_all.carbon
library "[[@TEST_NAME]]";

// The §5.A conformance shape (review fold B2): member 1 is viable only for a
// type that satisfies `HasGet`; member 2 accepts any type.
template constraint HasGet {
  fn Get(self) -> i32;
}

class C {
  fn Get(self) -> i32 { return 42; }
}

class Lacking {
  fn Other(self) -> i32 { return 0; }
}

overload fn Pick[template T: HasGet](x: T) -> i32 { return x.Get(); }
overload fn Pick[template T: type](unused x: T) -> i32 { return 7; }

//@dump-sem-ir-begin
fn Test(c: C, l: Lacking) -> i32 { return Pick(c) + Pick(l); }
//@dump-sem-ir-end
