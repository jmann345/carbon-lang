// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/named_constraint/template_constraint_import.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/named_constraint/template_constraint_import.carbon

// A `template constraint` declared in one library satisfies in another: the
// requirement block is imported with the constraint (fork decision F-010 /
// SC-1, fork/structural/plan.md D-SC-15, review fold A2).

// --- a.carbon
library "[[@TEST_NAME]]";

template constraint HasGet {
  fn Get(self) -> i32;
}

// --- b.carbon
library "[[@TEST_NAME]]";

import library "a";

class C {
  fn Get(unused self) -> i32 { return 1; }
}

fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }

fn Test(c: C) -> i32 { return CallGet(c); }

// --- requirement_type_a.carbon
library "[[@TEST_NAME]]";

// A requirement's type, an alias of a requirement and an impl for the type,
// exported for the two splits below (D-SC-20; fill round 6, both reviews'
// finding MINOR-2: the import of `StructuralRequirementType`,
// check/import_ref.cpp `TryResolveTypedInst`, had no golden).
template constraint HasN {
  fn N() -> i32;
}

template constraint Has(X: type) {
  fn N() -> X;
}

interface Z {
  fn F() -> i32;
}

alias A = HasN.N;

fn P(unused p: typeof(HasN.N)*) -> i32 { return 3; }

impl typeof(Has(i32).N) as Z {
  fn F() -> i32 { return 9; }
}

fn Take[T: type](unused f: T) -> i32 { return 1; }

// --- requirement_type_b.carbon
library "[[@TEST_NAME]]";

import library "requirement_type_a";

class C {
  fn N() -> i32 { return 5; }
}

// The imported alias's type is the imported `typeof(HasN.N)`; the imported
// impl is found for `typeof(Has(i32).N)`; `C.(A)` is `C`'s own `N` (D-SC-4).
//@dump-sem-ir-begin
fn Use(p: typeof(A)*) -> i32 {
  return P(p) + typeof(Has(i32).N).(Z.F)() + C.(A)();
}
//@dump-sem-ir-end

// --- fail_requirement_type_value.carbon
library "[[@TEST_NAME]]";

import library "requirement_type_a";

// An imported requirement is refused as a value as in its own library; an
// imported requirement's type prints as `<type of Has(i32).N>`.
fn TakeName() -> i32 { return Take(A); }

fn Mismatch(p: typeof(Has(i32).N)*) -> i32 { return P(p); }
