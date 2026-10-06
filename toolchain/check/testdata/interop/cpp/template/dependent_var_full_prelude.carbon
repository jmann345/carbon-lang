// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/template/dependent_var_full_prelude.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/template/dependent_var_full_prelude.carbon

// Fork (UA-2, fork/upstream/plan.md §0.6 W-043 row): generic_call.carbon's
// shape under the REAL prelude. generic_call.carbon passes under
// min_prelude/convert.carbon, whose parts/default.carbon:19 declares an
// unconstrained `impl forall [T: type] T as DefaultOrUnformed`; the real
// prelude's blanket impl requires `T: UnformedInit` (core/prelude/default
// .carbon:52), which cannot be decided for a template-dependent type, so an
// UNINITIALIZED dependent `var` fails at its default initialization. The
// conformance programs interop/cpp_template_symbolic_arg.carbon and
// cpp_template_on_carbon_generic.carbon measured this on hosted run
// 37407530104 and on upstream nightly 2026.09.28; this file pins both the
// failing shape and the shape that works (initialization through the C++
// default constructor, class/import/template.carbon's pin).

// --- header.h

struct X {};

template<typename T> struct S {};

// --- fail_unformed_dependent_var.carbon

library "[[@TEST_NAME]]";

import Cpp library "header.h";

// Predicted: `ConversionFailureTypeToFacet` "cannot convert type `<splice of
// ...>` into type implementing `Core.DefaultOrUnformed`" at the `var`.
fn F[T: type](unused x: T) {
  var unused v: Cpp.S(T);
}

fn G() {
  F({} as Cpp.X);
}

// --- ctor_init_dependent_var.carbon

library "[[@TEST_NAME]]";

import Cpp library "header.h";

// Predicted: no diagnostic; the constructor call and the return are
// template-dependent actions instantiated for `F(Cpp.X)`.
//@dump-sem-ir-begin
fn F[T: type](unused x: T) -> Cpp.S(T) {
  var v: Cpp.S(T) = Cpp.S(T).S();
  return v;
}
//@dump-sem-ir-end

fn G() -> Cpp.S(Cpp.X) {
  return F({} as Cpp.X);
}
