// CONFORMANCE-BULLET: Generics: C++ interop — exporting Carbon templates/checked generics as C++ templates
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   3
// SKIP: known-missing slice — a non-type generic parameter cannot be exported as a C++ non-type template parameter on nightly 2026.07.19: this file fails to compile with `error: semantics TODO: `binding maps to a non-type template parameter`` at the `fn Constant[N: i32]` declaration, followed by `error: no member named 'Constant' in namespace 'Carbon'` at the C++ call site (verified against this arbiter toolchain; same TODO as check/testdata/interop/cpp/function/export/generic.carbon, fail_todo_non_type_generic). The related missing slices — generics inside an enclosing generic scope (fail_todo_enclosing_generic) and Carbon `template` export (template lowering itself is CARBON_FATAL, see generics/templates_dependent_member.carbon) — are TODO in the same file. Enable when export.cpp maps value bindings to clang NonTypeTemplateParmDecls.
//
// Known-missing slice of the bullet, written ahead of the feature per
// process.md step 1. Shape from check/testdata/interop/cpp/function/export/
// generic.carbon (fail_todo_non_type_generic: `fn F[unused N: i32]()` +
// `Carbon::F<3>()`), made runtime-observable for when it lands.

import Core library "io";
import Cpp;

fn Constant[N: i32]() -> i32 {
  return N;
}

inline Cpp '''
auto UseConstant() -> int {
  return Carbon::Constant<3>();
}
''';

fn Run() -> i32 {
  Core.Print(Cpp.UseConstant());
  return 0;
}
