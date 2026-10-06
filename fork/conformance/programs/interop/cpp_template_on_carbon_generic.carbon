// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Type system: C++ interop — importing C++ types / exporting Carbon types
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   7
//
// Un-SKIPped 2026-10-06 (UA-2 probe, fork/upstream/plan.md §0.6 W-043 row
// and §8.5). The SKIP (nightly 2026.07.19) cited "error: semantics TODO:
// `unsupported type used as template argument`" at both uses of
// `Cpp.Box(T)` below, the TODO then pinned by toolchain/check/testdata/
// interop/cpp/template/generic_call.carbon's `fail_todo_generic_call` split.
// Upstream PR 7673 lifted that TODO (the instantiation is a deferred
// `CallCppTemplateAction`) and the split lost its `fail_todo` prefix at PR
// 7700 (after PR 7689's `TemplateInst`): upstream-trunk's generic_call.carbon
// pins `fn F[T: type](unused x: T) { var unused v: Cpp.S(T); }` (:27-28) with
// no `fail_todo`. Pre-registered residual (plan §0.6, rev B B8): the RETURN
// type `-> Cpp.Box(T)` returned by value (`MakeBox`), which upstream's pin
// does not cover; the fill decides (R10). Concrete Carbon class types as
// template arguments are arbitrated by cpp_type_import_class_enum.carbon and
// cpp_template_carbon_class.carbon. Prediction: PASS, 7.
//
// Encodes the slice this program pins precisely: the audit evidence said
// "C++ templates cannot instantiate on Carbon class types", but already at
// the 2026-07-19 cut the concrete case (`var b: Cpp.Box(Pt);`) compiled,
// linked, and ran. What failed was naming `Cpp.Box(T)` with `T` a
// checked-generic parameter — instantiation was not deferred to
// monomorphization.

import Core library "io";
import Cpp inline '''

template <typename T> struct Box {
  T value;
};

''';

class Pt {
  var x: i32;
}

fn MakeBox[T: type](x: T) -> Cpp.Box(T) {
  var b: Cpp.Box(T);
  b.value = x;
  return b;
}

fn Run() -> i32 {
  var p: Pt = {.x = 7};
  var b: Cpp.Box(Pt) = MakeBox(p);
  Core.Print(b.value.x);
  return 0;
}
