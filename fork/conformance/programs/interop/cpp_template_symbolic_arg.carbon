// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: C++ interop — importing C++ templates, instantiating on Carbon types
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   7
//
// Un-SKIPped 2026-10-06 (UA-2 probe, fork/upstream/plan.md §0.6 W-043 row
// and §8.5). The SKIP (nightly 2026.07.19) cited "error: semantics TODO:
// `unsupported type used as template argument`" at `var b: Cpp.Box(T);`, the
// TODO then pinned by toolchain/check/testdata/interop/cpp/template/
// generic_call.carbon's `fail_todo_generic_call` split. Upstream PR 7673
// ("Support using Carbon generic types as C++ template parameters") lifted
// that TODO — the instantiation became a deferred `CallCppTemplateAction` —
// and the split lost its `fail_todo` prefix at PR 7700 (after PR 7689's
// `TemplateInst`): upstream-trunk's generic_call.carbon pins exactly
// `fn F[T: type](unused x: T) { var unused v: Cpp.S(T); }` (:27-28) with no
// `fail_todo`, instantiated per specific (`specific_inst @F.%v.var, @F(%X)`).
// Pre-registered residual (plan §0.6, rev B B8): this program ALSO puts
// `Cpp.Box(T)` in the RETURN type and returns the instantiation by value
// (`fn Wrap[T: type](v: T) -> Cpp.Box(T)`), which upstream's pin does not
// cover; the fill decides (R10: a failure's measured diagnostic goes back
// into a SKIP line). Round-1 prediction: PASS, 7.
//
// Round 2 (2026-10-06): the round-1 probe COMPILE-FAILED on hosted conformance
// run 37407530104 with two diagnostics, both reproduced on upstream's own
// nightly 2026.09.28+1579d4e, so neither is a fork regression. (1) At the
// uninitialized `var b: Cpp.Box(T);`: "error: cannot convert type `<splice of
// <cannot stringify inst...: {kind: ConvertToValueAction, arg0: inst...,
// arg1: inst(TypeType), type: type(inst(InstType))}>>` into type implementing
// `Core.DefaultOrUnformed`" — an UPSTREAM limitation under the REAL prelude:
// upstream's pin passes only because the test prelude's
// toolchain/testing/testdata/min_prelude/parts/default.carbon:19 declares an
// unconstrained `impl forall [T: type] T as DefaultOrUnformed`, where
// core/prelude/default.carbon:52 requires `T: UnformedInit`, which cannot be
// decided for a type that is unknown until instantiation; upstream's exact pin
// shape (`var unused v: Cpp.S(T);`) fails identically under the real prelude.
// Pinned by check/testdata/interop/cpp/template/dependent_var_full_prelude
// .carbon. (2) "unable to monomorphize specific" with the notes "cannot copy
// value of type ..." / "does not implement interface `Core.Copy`" at the
// member assignment — a program bug: a Carbon class is not implicitly
// `Core.Copy`. Program edits, recorded here and in the decision log: the box
// is initialized through its C++ default constructor (`Cpp.Box(T).Box()`,
// upstream's pin shape check/testdata/interop/cpp/class/import/template.carbon
// :149 `var unused a: Cpp.A(T) = Cpp.A(T).A();`), and the Carbon class
// declares `impl as Core.Copy` (the lower/testdata/template/class.carbon
// spelling). The claim is unchanged: `Cpp.Box(T)` with symbolic `T` in the
// body and in the return type. Verified end to end on the 2026.09.28 nightly
// (compile, link, run: `7`, exit 0); the fork tip is measured by the next
// hosted run. Prediction: PASS, 7.
//
// The slice this program pins: using a Carbon checked generic's symbolic
// type parameter T as an argument to an imported C++ template (Cpp.Box(T))
// inside the generic's body. Concrete Carbon types in the same position
// worked at the 2026-07-19 cut (cpp_template_builtins.carbon,
// cpp_template_carbon_class.carbon); the symbolic case needed C++ template
// instantiation deferred until monomorphization.

import Core library "io";
import Cpp inline '''
template<typename T> struct Box {
  T value;
};
''';

class Point {
  var x: i32;

  impl as Core.Copy {
    fn Op(self) -> Self { return {.x = self.x}; }
  }
}

fn Wrap[T: type](v: T) -> Cpp.Box(T) {
  var b: Cpp.Box(T) = Cpp.Box(T).Box();
  b.value = v;
  return b;
}

fn Run() -> i32 {
  Core.Print(Wrap({.x = 7} as Point).value.x);
  return 0;
}
