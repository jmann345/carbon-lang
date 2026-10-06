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
// into a SKIP line). Prediction: PASS, 7.
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
}

fn Wrap[T: type](v: T) -> Cpp.Box(T) {
  var b: Cpp.Box(T);
  b.value = v;
  return b;
}

fn Run() -> i32 {
  Core.Print(Wrap({.x = 7} as Point).value.x);
  return 0;
}
