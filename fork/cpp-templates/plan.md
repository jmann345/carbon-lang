# C++ templates on symbolic Carbon type arguments, instantiated per specific (CT-1)

<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

**Status:** rev 1, 2026-10-21 -- FOR PLAN REVIEW

Workstream CT-1 takes ledger item W-043 ("C++ templates instantiated on Carbon
types / symbolic Carbon generic parameters as C++ template arguments"), whose
owning bullet is gap row 56 ("Generics: C++ interop — importing C++ templates,
instantiating on Carbon types", PARTIAL), with its second scoreboard entry under
gap row 42 ("Type system: C++ interop — importing C++ types / exporting Carbon
types", PARTIAL). The task text names "row 45" for the second entry; row 45 is
the inheritance bullet in every tree measured (this branch, trunk, PR 51, PR 58
and PR 62), and the second SKIP program,
interop/cpp_template_on_carbon_generic.carbon, names row 42's bullet
(fork/conformance/README.md:336), so this plan says row 42 throughout.

Branch claude/carbon-fork-0-1-ct, cut from PR 61's head 5661a35c8 (TP-1,
integrated templates, held open after its dry round 11). CT-1 is stacked on
PR 61 and merges after PR 62 (SV-1), last of the held PRs (§1.16). It reserves
W-300..W-319 (§0.11) and mints no fork design id (D-CT-16).

The one-sentence summary: upstream already defers a C++ template named with a
symbolic argument to each specific (a `CallAction` over `TemplateInst`-wrapped
arguments, check/call.cpp:741-768), and seven defects in and around that path
keep it from working on this branch; CT-1 fixes the seven at their roots, in
seven files and 163 added lines, measured on a prototype (v11) over 174 probes,
the 1957 goldens and the 160 conformance programs.

## §0 Audit: measurements with file:line evidence

### §0.1 Toolchains, probes and the result codes

Every probe was compiled, linked and run on four toolchains:

| Name | What | Where |
| --- | --- | --- |
| TP-1 | PR 61's head 5661a35c8 (toolchain eafca5cb9), the base of this branch | /home/user/carbon-build/carbon-tp/install (read-only) |
| trunk | the fork's trunk 6978a506e | /home/user/carbon-build/carbon-trunk/install |
| nightly | upstream's nightly 2026.10.12, the oracle for upstream behavior (R30) | /home/user/nightly/tc/carbon_toolchain-0.0.0-0.nightly.2026.10.12 |
| v11 | TP-1 plus the prototype of §2 (seven files) | relinked over TP-1's objects into /dev/shm, deleted after use |

Two intermediate states were measured for the commit split (§3): c1 (v11 without
check/call.cpp and check/action.cpp) and c1b (c1 plus check/action.cpp, which
is commit C1). TP-1, c1b and v11 were also relinked with a file_test whose
manifest lists the two new goldens (§0.7).

The probes are generated from one C++ header and two Carbon classes (Appendix
D): each form is written once in a checked generic (`c_` prefix, `[T: type]`)
and once with a template binding (`t_` prefix, `[template T: type]`), with a
concrete twin (`z_` prefix) where the form's concrete spelling is in question.
Results are coded:

| Code | Meaning (exact text, first diagnostic) |
| --- | --- |
| a number | compiled, linked, ran, exit 0, printed that |
| E-DU | ``cannot convert type `Box(<cannot stringify inst...: {kind: TemplateInst, ...}>)` into type implementing `Core.DefaultOrUnformed` `` at an uninitialized `var` of the specialization (TP-1; trunk and the nightly print the type as `<splice of <cannot stringify inst...: {kind: ConvertToValueAction, ...}>>`), `ConversionFailureTypeToFacet` |
| E-ARG | ``call argument of type `T` is not supported`` at a C++ call with an argument of symbolic type (check/cpp/type_mapping.cpp:593-599, `CppCallArgTypeNotSupported`) |
| E-MONO | ``unable to monomorphize specific `F(...)` `` at the call that names the specific, with a note at the failing operation (§1.11 gives each note) |
| E-DEDUCE | ``cannot deduce value for generic parameter `T` `` (check/deduce.cpp:513) |
| E-TT | Clang's ``template argument for template template parameter must be a class template or type alias template`` |
| E-CXX | Clang's own error in the instantiated C++, such as ``invalid operands to binary expression ('Carbon::Point' and 'Carbon::Point')`` with the note ``in instantiation of function template specialization 'Twice<Carbon::Point>' requested here`` |
| E-UNMAPPED | E-MONO with the note ``semantics TODO: `unsupported type used as template argument` `` printed without a line (check/cpp/call.cpp:133) |
| E-COPY | ``cannot copy value of type `T` `` (the checked generic's own rule: its Carbon twin is rejected the same way, §0.5) |
| E-AS | ``cannot convert expression of type `f64` to `i32` with `as` `` (the probe's own conversion; no C++ in it) |
| E-NOMATCH | Clang's ``no matching function for call to 'SizeOfFn'`` (the explicit type argument dropped) |
| E-PARSE | ``expected `.field: field_type` or `.field = value` `` (a probe's bare block; the gen2 destroy probes replace it) |
| L-UNDEF | the link fails: ``ld.lld: error: undefined symbol: SizeOf<int>`` (or `Plain<int>`) |
| STOP f:l | the compiler stopped: a CHECK or FATAL failure at f:l, "clang assertion" (`DD && "queried property of class with no definition"`, clang/AST/DeclCXX.h:464) or a segfault (signal 11) |

### §0.2 The two SKIP programs and the stale premise

Both programs' SKIP lines quote nightly 2026.07.19's ``semantics TODO:
`unsupported type used as template argument` `` at `var b: Cpp.Box(T);`. That
TODO is gone for symbolic types: upstream PRs 7673, 7689 and 7700 made the
specialization a deferred `CallAction` whose symbolic arguments are wrapped in
`TemplateInst` (check/call.cpp:741-768 on this branch, the comment at :749-750:
"Wrap symbolic template args in a `TemplateInst` so that all symbolic arguments
are treated as templates"), and call.cpp:133 is reached only for a concrete type
that `MapToCppType` cannot map. W-043's evidence (call.cpp:127, :252,
type_mapping.cpp:560) is stale in the same way. Measured with each SKIP line
removed and nothing else changed:

| Program | TP-1 | trunk | nightly | v11 |
| --- | --- | --- | --- | --- |
| cpp_template_symbolic_arg | E-DU at :29 `var b: Cpp.Box(T);`, then E-MONO ``Wrap(Point)`` with ``cannot copy value of type `Point` `` at :30 | the same two errors | the same two errors | E-MONO ``Wrap(Point)``, ``cannot copy value of type `Point` `` at :30 |
| cpp_template_on_carbon_generic | E-DU at :33, then E-MONO ``MakeBox(Pt)`` with ``cannot copy value of type `Pt` `` at :34 | the same | the same | E-MONO ``MakeBox(Pt)``, ``cannot copy value of type `Pt` `` at :34 |

So each program fails for two reasons today: the uninitialized `var` of the
specialization (E-DU, a toolchain defect, §0.5 R1) and the program's own bug
(`b.value = v;` copies a Carbon class value, and a Carbon class is not
implicitly `Core.Copy`; the concrete body with `Cpp.Box(Point)` is rejected the
same way on every toolchain). PR 51 (UA-2) found both at its round 2 and
un-SKIPped the two programs by initializing the box through its C++ default
constructor (`var b: Cpp.Box(T) = Cpp.Box(T).Box();`) and adding `impl as
Core.Copy`; those versions print 7 on TP-1 and on v11, and the uninitialized
form fails on TP-1 and prints 7 on v11 (§0.9 C-1). PR 58 (DD-1) amends W-043's
notes with the same finding. CT-1's versions keep the programs' original claim,
the uninitialized `var b: Cpp.Box(T);`, and add only the `Core.Copy` impl
(Appendix B).

### §0.3 The probe matrix

148 probes, TP-1 / trunk / nightly / v11. The gen probes (Appendix D) use the
header's `Box`, `BoxAlias`, `Pair`, `Twice`, `Unbox`, `MakeBoxCpp`, `SameBox`,
`Array`, `Loud`, `SizeOf` and `Holder`; gen3 holds the programs of Appendix B
and the concrete twins; gen4 holds the forms that the first three sets raised,
among them the narrow-integer return shapes (`y_`, `z_short`).

<!-- google-doc-style-ignore -->

| Probe | TP-1 | trunk | nightly | v11 |
| --- | --- | --- | --- | --- |
| gen/c_alias_template | E-DU | E-DU | E-DU | 17 |
| gen/c_carbon_generic_class | E-DU | E-DU | E-DU | 15 |
| gen/c_carbon_generic_class_field | E-DU | E-DU | E-DU | 15 |
| gen/c_compare_addr | E-ARG | E-ARG | E-ARG | 12 |
| gen/c_decl | E-DU | E-DU | E-DU | 1 |
| gen/c_decl_point | E-DU | E-DU | E-DU | 1 |
| gen/c_destroy | E-PARSE | E-PARSE | E-PARSE | E-PARSE |
| gen/c_exported_class | E-DU | E-DU | E-DU | 16 |
| gen/c_field_assign_read | E-DU | E-DU | E-DU | 7 |
| gen/c_fn_template_call | E-ARG | E-ARG | E-ARG | 42 |
| gen/c_fn_template_explicit | E-ARG | E-ARG | E-ARG | 42 |
| gen/c_init_from_cpp_call | E-ARG | E-ARG | E-ARG | 2 |
| gen/c_method_call | E-ARG | E-ARG | E-ARG | 8 |
| gen/c_nested | E-DU | E-DU | E-DU | 14 |
| gen/c_nested_decl | E-DU | E-DU | E-DU | 14 |
| gen/c_nontype_symbolic | E-DU | E-DU | E-DU | 3 |
| gen/c_nontype_symbolic_decl | E-DU | E-DU | E-DU | 3 |
| gen/c_param_copy | 10 | 10 | 10 | 10 |
| gen/c_pass_to_cpp | E-ARG | E-ARG | E-ARG | 9 |
| gen/c_return_spec | E-ARG | E-ARG | E-ARG | 11 |
| gen/c_return_var | E-DU | E-DU | E-DU | 11 |
| gen/c_two_specifics | E-DU | E-DU | E-DU | 19 |
| gen/c_var_template | L-UNDEF | L-UNDEF | L-UNDEF | 18 |
| gen/t_alias_template | E-DU | E-DU | E-DU | 17 |
| gen/t_carbon_generic_class | E-DU | E-DU | E-DU | 15 |
| gen/t_carbon_generic_class_field | E-DU | E-DU | E-DU | 15 |
| gen/t_compare_addr | 12 | 12 | 12 | 12 |
| gen/t_decl | E-DU | E-DU | E-DU | 1 |
| gen/t_decl_point | E-DU | E-DU | E-DU | 1 |
| gen/t_destroy | E-PARSE | E-PARSE | E-PARSE | E-PARSE |
| gen/t_exported_class | E-DU | E-DU | E-DU | 16 |
| gen/t_field_assign_read | E-DU | E-DU | E-DU | 7 |
| gen/t_fn_template_call | 42 | 42 | 42 | 42 |
| gen/t_fn_template_explicit | 42 | 42 | 42 | 42 |
| gen/t_init_from_cpp_call | 2 | 2 | 2 | 2 |
| gen/t_method_call | 8 | 8 | 8 | 8 |
| gen/t_nested | E-DU | E-DU | E-DU | 14 |
| gen/t_nested_decl | E-DU | E-DU | E-DU | 14 |
| gen/t_nontype_symbolic | E-DU | E-DU | E-DU | 3 |
| gen/t_nontype_symbolic_decl | E-DU | E-DU | E-DU | 3 |
| gen/t_param_copy | 10 | 10 | 10 | 10 |
| gen/t_pass_to_cpp | 9 | 9 | 9 | 9 |
| gen/t_return_spec | 11 | 11 | 11 | 11 |
| gen/t_return_var | E-DU | E-DU | E-DU | 11 |
| gen/t_two_specifics | E-DU | E-DU | E-DU | 19 |
| gen/t_var_template | L-UNDEF | L-UNDEF | L-UNDEF | 18 |
| gen2/c_assign_spec | E-DU | E-DU | E-DU | 28 |
| gen2/c_bad_inst | STOP clang assertion | STOP clang assertion | STOP segfault | E-CXX |
| gen2/c_bad_inst_generic | E-ARG | E-ARG | E-ARG | E-CXX |
| gen2/c_box_in_generic_caller | E-DU | E-DU | E-DU | 31 |
| gen2/c_carbon_generic_spec_arg | E-DU | E-DU | E-DU | 39 |
| gen2/c_class_member_template | E-ARG | E-ARG | STOP constant.cpp:36 | 36 |
| gen2/c_destroy | E-DU | E-DU | E-DU | 25 |
| gen2/c_destroy_copy | 25 | 25 | 25 | 25 |
| gen2/c_float_arg | E-ARG | E-ARG | E-ARG | E-AS |
| gen2/c_member_missing | E-DU | E-DU | E-DU | E-MONO |
| gen2/c_member_missing_uncalled | E-DU | E-DU | E-DU | 33 |
| gen2/c_nested_fn | E-ARG | E-ARG | E-ARG | 26 |
| gen2/c_operator_on_result | E-ARG | E-ARG | E-ARG | 42 |
| gen2/c_param_field | 21 | 21 | 21 | 21 |
| gen2/c_param_method | 22 | 22 | 22 | 22 |
| gen2/c_param_unbox | 23 | 23 | 23 | 23 |
| gen2/c_param_unbox_int | 24 | 24 | 24 | 24 |
| gen2/c_ptr_spec | E-ARG | E-ARG | E-ARG | 29 |
| gen2/c_result_in_var | E-ARG | E-ARG | E-ARG | E-COPY |
| gen2/c_sizeof | E-NOMATCH | E-NOMATCH | E-NOMATCH | 35 |
| gen2/c_static_member | 37 | 37 | 37 | 37 |
| gen2/c_symbolic_call_in_generic_caller | E-ARG | E-ARG | E-ARG | 30 |
| gen2/c_twice_twice | E-ARG | E-ARG | E-ARG | 27 |
| gen2/c_type_alias_member | 38 | 38 | 38 | 38 |
| gen2/t_assign_spec | E-DU | E-DU | E-DU | 28 |
| gen2/t_bad_inst | STOP clang assertion | STOP clang assertion | STOP segfault | E-CXX |
| gen2/t_bad_inst_generic | E-CXX | E-CXX | E-CXX | E-CXX |
| gen2/t_box_in_generic_caller | STOP generic_region_stack.h:98 | STOP generic_region_stack.h:98 | STOP generic_region_stack.h:98 | 31 |
| gen2/t_carbon_generic_spec_arg | E-DU | E-DU | E-DU | 39 |
| gen2/t_class_member_template | STOP function_context.cpp:264 | STOP function_context.cpp:223 | STOP constant.cpp:36 | STOP function_context.cpp:264 |
| gen2/t_destroy | E-DU | E-DU | E-DU | 25 |
| gen2/t_destroy_copy | 25 | 25 | 25 | 25 |
| gen2/t_float_arg | E-AS | E-AS | E-AS | E-AS |
| gen2/t_member_missing | E-DU | E-DU | E-DU | E-MONO |
| gen2/t_member_missing_uncalled | E-DU | E-DU | E-DU | 33 |
| gen2/t_nested_fn | 26 | 26 | 26 | 26 |
| gen2/t_operator_on_result | 42 | 42 | 42 | 42 |
| gen2/t_param_field | 21 | 21 | 21 | 21 |
| gen2/t_param_method | 22 | 22 | 22 | 22 |
| gen2/t_param_unbox | 23 | 23 | 23 | 23 |
| gen2/t_param_unbox_int | 24 | 24 | 24 | 24 |
| gen2/t_ptr_spec | 29 | 29 | 29 | 29 |
| gen2/t_result_in_var | 42 | 42 | 42 | 42 |
| gen2/t_sizeof | 35 | 35 | 35 | 35 |
| gen2/t_static_member | 37 | 37 | 37 | 37 |
| gen2/t_symbolic_call_in_generic_caller | E-MONO | E-MONO | E-MONO | 30 |
| gen2/t_twice_twice | 27 | 27 | 27 | 27 |
| gen2/t_type_alias_member | 38 | 38 | 38 | 38 |
| gen3/cpp_template_carbon_generic_spec | E-DU | E-DU | E-DU | 6 64 65 |
| gen3/cpp_template_fn_symbolic | E-ARG | E-ARG | E-ARG | 42 10 9 8 2 12 |
| gen3/cpp_template_nested_symbolic | E-DU | E-DU | E-DU | 34 9 |
| gen3/cpp_template_on_carbon_generic | E-DU | E-DU | E-DU | 7 |
| gen3/cpp_template_spec_roundtrip | E-ARG | E-ARG | E-ARG | 42 7 7 |
| gen3/cpp_template_symbolic_arg | E-DU | E-DU | E-DU | 7 |
| gen3/cpp_template_symbolic_diff | E-ARG | E-ARG | E-ARG | 6 60 3 |
| gen3/cpp_template_two_specifics | E-DU | E-DU | E-DU | 5 12 2 |
| gen3/cpp_var_template_runtime | L-UNDEF | L-UNDEF | L-UNDEF | 5 8 20 9 |
| gen3/z_array_nontype | 3 | 3 | 3 | 3 |
| gen3/z_box_point_then_id | 9 | 9 | 9 | 9 |
| gen3/z_id_point | 5 | 5 | 5 | 5 |
| gen3/z_id_point_lit | STOP clang assertion | STOP clang assertion | STOP segfault | 6 |
| gen3/z_makebox_point | 7 | 7 | 7 | 7 |
| gen3/z_sizeof_fn | 4 | 4 | 4 | 4 |
| gen3/z_sizeof_var | L-UNDEF | L-UNDEF | L-UNDEF | 4 |
| gen3/z_twice_point | E-CXX | E-CXX | E-CXX | E-CXX |
| gen3/z_var_template_runtime | L-UNDEF | L-UNDEF | L-UNDEF | 5 9 4 |
| gen4/g_class_field_checked | 40 | 40 | 40 | 40 |
| gen4/g_class_field_template | 41 | 41 | 41 | 41 |
| gen4/g_cpp_generic_class_spec | E-DU | E-DU | E-DU | 53 |
| gen4/g_eval_order | E-ARG | E-ARG | E-ARG | 51 |
| gen4/g_facet_constrained | E-DU | E-DU | E-DU | E-MONO |
| gen4/g_facet_constrained_member | E-ARG | E-ARG | E-ARG | E-MONO |
| gen4/g_nontype_i64 | E-DU | E-DU | E-DU | E-MONO |
| gen4/g_point_nocopy | E-DU | E-DU | E-DU | 42 |
| gen4/g_point_nocopy_return | E-DU | E-DU | E-DU | 43 |
| gen4/g_ptr_arg | E-DU | E-DU | E-DU | 48 |
| gen4/g_struct_arg | E-DU | E-DU | E-DU | E-UNMAPPED |
| gen4/g_template_template | E-TT | E-TT | E-TT | E-TT |
| gen4/g_template_template_cpp | E-DU | E-DU | E-DU | 45 |
| gen4/g_tuple_arg | E-DU | E-DU | E-DU | E-UNMAPPED |
| gen4/g_w268 | E-DU | E-DU | E-DU | 52 |
| gen4/s1_class_field_in_generic | STOP custom_witness.cpp:487 | STOP custom_witness.cpp:487 | STOP custom_witness.cpp:401 | 54 |
| gen4/s1b_param | STOP handle_expr_category.cpp:20 | STOP handle_expr_category.cpp:20 | STOP handle_expr_category.cpp:20 | 60 |
| gen4/s1c_construct_only | STOP custom_witness.cpp:487 | STOP custom_witness.cpp:487 | STOP custom_witness.cpp:401 | 61 |
| gen4/s1d_field_var | STOP handle_expr_category.cpp:20 | STOP handle_expr_category.cpp:20 | STOP handle_expr_category.cpp:20 | 62 |
| gen4/s1e_return_box | STOP handle_expr_category.cpp:20 | STOP handle_expr_category.cpp:20 | STOP handle_expr_category.cpp:20 | 63 |
| gen4/s1f_method | STOP handle_expr_category.cpp:20 | STOP handle_expr_category.cpp:20 | STOP handle_expr_category.cpp:20 | 64 |
| gen4/s2_class_field_in_template | 55 | 55 | 55 | 55 |
| gen4/s3_compound_member | E-DU | E-DU | E-DU | 56 |
| gen4/s4_extend_member | E-DU | E-DU | E-DU | 57 |
| gen4/s5_tm6_concrete_cpp_var_in_template | STOP function_context.cpp:264 | STOP function_context.cpp:223 | STOP constant.cpp:36 | STOP function_context.cpp:264 |
| gen4/s6_concrete_cpp_var_in_template | STOP function_context.cpp:264 | STOP function_context.cpp:223 | STOP constant.cpp:36 | STOP function_context.cpp:264 |
| gen4/w268_d03_var_elem | E-DU | E-DU | E-DU | 6 4 |
| gen4/y_D | E-ARG | E-ARG | E-ARG | 14 |
| gen4/y_E | E-ARG | E-ARG | E-ARG | 16 |
| gen4/y_E_nontemplate_fn | STOP handle_call.cpp:984 | STOP handle_call.cpp:984 | STOP handle_call.cpp:783 | 16 |
| gen4/y_E_only | STOP handle_call.cpp:984 | STOP handle_call.cpp:984 | STOP handle_call.cpp:783 | 16 |
| gen4/y_F | E-ARG | E-ARG | E-ARG | 9 |
| gen4/y_G | E-ARG | E-ARG | E-ARG | 10 |
| gen4/y_short_twice | E-ARG | E-ARG | E-ARG | 14 16 9 10 |
| gen4/z_short_return | 10 10 | 10 10 | 10 10 | 10 10 |
| gen4/z_short_return2 | 11 11 | 11 11 | 11 11 | 11 11 |

<!-- google-doc-style-resume -->

The 26 probes measured on 2026-10-21 for §0.2, §0.6, §0.9, §1.11 and Appendix
C.1 (the cross-library pairs compile both units on the command line, target
last):

<!-- google-doc-style-ignore -->

| Probe | TP-1 | trunk | nightly | v11 |
| --- | --- | --- | --- | --- |
| noskip/cpp_template_symbolic_arg (SKIP line removed) | E-DU, E-MONO (`Point` not `Core.Copy`) | the same | the same | E-MONO (`Point` not `Core.Copy`) |
| noskip/cpp_template_on_carbon_generic (SKIP line removed) | E-DU, E-MONO (`Pt` not `Core.Copy`) | the same | the same | E-MONO (`Pt` not `Core.Copy`) |
| w127/w127_unformed (PR 51's split shape, real prelude) | E-DU | E-DU | not run | 1 |
| pr51/cpp_template_symbolic_arg (PR 51's text) | 7 | not run | not run | 7 |
| pr51/cpp_template_on_carbon_generic (PR 51's text) | 7 | not run | not run | 7 |
| pr51/cpp_template_symbolic_arg_uninit (PR 51's text, initializer removed) | E-DU | not run | not run | 7 |
| pr51/cpp_template_on_carbon_generic_uninit (the same) | E-DU | not run | not run | 7 |
| ox/nested_generic_scope (a class in a generic class's scope as `T`) | E-DU, E-MONO (``non-class non-namespace name scope``), E-MONO (E-UNMAPPED) | not run | the same as TP-1 | E-MONO (``non-class non-namespace name scope``), E-MONO (E-UNMAPPED) |
| ox/nested_generic_scope_concrete | ``semantics TODO: `non-class non-namespace name scope` `` and ``semantics TODO: `unsupported type used as template argument` `` | not run | the same | the same |
| res/w300_struct (`T` = `{.a: i32}`) | E-DU, E-UNMAPPED | not run | the same | E-UNMAPPED |
| res/w300_tuple (`T` = `(i32, i32)`) | E-DU, E-UNMAPPED | not run | the same | E-UNMAPPED |
| res/w300_struct_concrete (`Cpp.Box({.a: i32})`) | ``semantics TODO: `unsupported type used as template argument` `` at the argument | not run | the same | the same |
| res/w302_ptr_nttp (`Cpp.PtrBox(&n)`, `n` a Carbon `var`) | ``semantics TODO: `unsupported argument type for non-type template parameter` `` | not run | the same | the same |
| res/w302_double_nttp (C++20, `Cpp.DBox(52.0)`) | 52 | not run | 52 | 52 |
| res/w303_deduce (`Get[T: type](b: Cpp.Box(T))` called with a `Box<int>`) | E-DEDUCE | not run | E-DEDUCE | E-DEDUCE |
| res/w305_member (`b.value.Get()` for `T: Show`) | E-DU, E-MONO (``member name `Get` not found in `S2` ``) | not run | the same | E-MONO (``member name `Get` not found in `S2` ``) |
| res/w305_twin (`v.Get()` for `T: Show`) | 49 | not run | 49 | 49 |
| res/nontype_i64_concrete (`Cpp.Array(i32, 49 as i64)`) | ``cannot implicitly convert expression of type `i64` to `i32` `` at the argument | not run | not run | the same |
| fixture/X34_cpp_template_symbolic_uninit (Appendix C.1) | E-DU, then E-ARG | not run | not run | 42, 10 |
| twin/concrete_box_point_nocopy (`b.value = v;` into a `Cpp.Box(Point)`, `Point` without `Core.Copy`) | ``cannot copy value of type `Point` `` | the same | the same | the same |
| twin/result_in_var_twin (`var r: T = v;` in a checked generic) | E-COPY and ``cannot access member of interface `Core.Destroy` in type `T` `` | not run | not run | the same |
| xlib/x1 (checked `Wrap` in a library, called from another) | ``semantics TODO: `using a generic from another library whose definition is resolved for each instantiation, such as a template` `` at the `import`, and E-DU | E-DU, then STOP import_ref.cpp:5087 (``Missing case in TryResolveInstCanonical for instruction kind SpliceInst``) | E-DU, then STOP import_ref.cpp:4875 | the TODO at the `import` |
| xlib/x2 (the same with a template binding) | the TODO at the `import`, and E-DU | E-DU, then STOP import_ref.cpp:5087 | E-DU, then STOP import_ref.cpp:4875 | the TODO at the `import` |
| xlib/x3 (a generic class with a `Cpp.Box(T)` field, made in a library) | ``cannot convert type `Holder(T)` into type implementing `Core.DefaultOrUnformed` `` and ``cannot copy value of type `Holder(T)` `` (the probe's own: `Holder` has neither) | the same | the same | the TODO at the `import`, and the same two |
| xlib/x4 (a concrete `Cpp.Box(i32)` returned across libraries) | ``semantics TODO: `indirect import of C++ declaration with no direct Cpp import` `` | the same | the same | the same |
| xlib/x5 (a generic class with a `Cpp.Box(T)` field, used in another library) | the TODO at the `import` | STOP import_ref.cpp:5087 | STOP import_ref.cpp:4875 | the TODO at the `import` |

<!-- google-doc-style-resume -->

Two C++ facts were checked with the nightly's clang, invoked as
`carbon clang -- -std=c++17 -fsyntax-only`. First, `struct Wrap {
template<typename T> static T var = {}; };` with `&Wrap::var<A>` is ``error:
non-const static data member must be initialized out of line`` with the note
``in instantiation of static data member 'Wrap::var<A>' requested here``.
Second, `template<T... N> static int n;` read as `X<int, int>::n<1, 2>` is the
warning ``instantiation of variable 'X<int, int>::n<1, 2>' required here, but
no definition is available`` (`-Wundefined-var-template`) with its two notes.
Both reappear in goldens (§0.7).

### §0.4 The code path and its hook points

A use of `Cpp.Box(T)` with `T` symbolic goes through these steps, with the hook
points CT-1 touches marked **(H1)** to **(H7)**:

1.  `PerformCall` (check/call.cpp:899-927) asks `IsCallPerformable`
    (:821-849, TP-1's D-TP-11 rule) and, for a callee whose type is
    `CppTemplateNameType`, `PerformCallToNonFunction` (:733-786) asks
    `IsCppTemplateCallPerformable` (:716-729). With a symbolic argument it is
    not, and :746-768 builds `call_action (%Box, %T.template_inst)` over
    `TemplateInst`-wrapped symbolic arguments, spliced into the definition by
    `AddDependentActionSplice`. The splice's constant is template-dependent.
    A call to an imported C++ function (`CalleeCppOverloadSet`) with a symbolic
    argument takes the other branch, `PerformCallHelper` (:851-897) to
    `PerformCallToCppFunction` (check/cpp/call.cpp:54-93), whose argument
    mapping (type_mapping.cpp:574-599) has no C++ type for a symbolic `T` and
    emits E-ARG in the definition. **(H1)**: check/call.cpp, before
    `PerformCallHelper`.
2.  The specialization's uses in the definition (`var b: Cpp.Box(T);`,
    `b.value = v`, `return b;`) are TP-1's deferred actions
    (`InitializeAction`, `AccessMemberAction`, `ConvertToValueAction`), and the
    default initialization asks impl lookup for `Core.DefaultOrUnformed` on the
    splice's type (handle_let_and_var.cpp:278-305 `MakeDefaultInit`).
    `LookupImplWitness` defers a query only if `QueryNamesTemplateBinding`
    (impl_lookup.cpp:636-660) finds a template binding; `NamesTemplateBinding`
    (:578-634) follows `InstId`, `TypeInstId`, `InstBlockId` and `SpecificId`
    operands, so it stops at the `SpliceInst`'s `MetaInstId` action operand and
    at the `TemplateInst`, and the query is resolved in the definition, where
    the real prelude's `impl forall [T: UnformedInit] T as DefaultOrUnformed`
    (core/prelude/default.carbon:52) cannot be shown to apply: E-DU. **(H2)**:
    impl_lookup.cpp `NamesTemplateBinding`.
3.  Each specific evaluates the generic's eval block. `ActionIsPerformable`
    (check/action.cpp:180-213) performs an action whose type and two operands
    have a dependence below `Template` in the specific. When a checked generic
    `H[U: type]` calls `F[template T: type]` with `U`, the specific `F(U)` is
    evaluated with `U` symbolic, whose dependence is `Checked`, so the C++ call
    or specialization in `F`'s eval block is performed with a symbolic
    argument: E-MONO with E-ARG's note, or STOP generic_region_stack.h:98.
    **(H3)**: action.cpp `ActionIsPerformable`.
4.  An action formed that way is a constant instruction of `F(U)`'s eval block;
    when `H(i32)` is evaluated, `SubstInst` (check/subst.cpp:93-260) does not
    look into `MetaInstId` or `MetaInstBlockId` operands (`PushOperand` and
    `PopOperand` have no case for them), so the action is not substituted and
    its splice stays symbolic in a concrete specific: STOP
    custom_witness.cpp:487 (``Unexpected type for CanDestroyType:
    SpliceInst``) or handle_expr_category.cpp:20 (``Value acquisition for type
    with dependent value representation``) for a Carbon generic class with a
    `Cpp.Box(T)` field. **(H4)**: subst.cpp `PushOperand`/`PopOperand`.
5.  `PerformCallToCppTemplateName` (cpp/call.cpp:350-365) converts each
    argument (`ConvertArgsToTemplateArgs`, :267-308, `ConvertArgToTemplateArg`,
    :119-265): a type through `MapToCppType` (type_mapping.cpp:504), which for a
    Carbon class calls `ExportClassToCpp` (:366, check/cpp/export.cpp); then
    `BuildTemplateId` (:310-348) forms the specialization with
    `CheckTemplateIdType` and imports it (`ImportCppType`, import.cpp, the
    layout through `CustomLayoutType`, import.cpp:700-708 and :884). For a
    variable template, `BuildTemplateId` calls the declaration form of
    `CheckVarTemplateId` (:317-324), which leaves a specialization that nothing
    declared with `TSK_Undeclared`; the reference the import makes then never
    instantiates its definition: L-UNDEF. **(H5)**: cpp/call.cpp
    `BuildTemplateId`.
6.  A C++ function template called for a specific (`Cpp.Twice(v)` with `v: i32`)
    goes through overload resolution; an argument of an exported Carbon class
    type reaches `IsMoveEquivalentToCopy` (cpp/overload_resolution.cpp:157-190),
    which reads the record's special members; the exported record is defined on
    demand by the external AST source (export.cpp:94
    `setHasExternalLexicalStorage`) and nothing completed it on this path: STOP
    clang assertion (a segfault on the nightly), for the concrete
    `Cpp.Twice({.x = 1} as Point)` too. **(H6)**: overload_resolution.cpp
    `IsMoveEquivalentToCopy`.
7.  A `return` of a template-dependent type is TP-1's storage-carrying
    `InitializeAction` whose storage is the function's return slot (`OutParam`);
    `PerformAction(InitializeAction)` (check/convert.cpp:2993-3060) hands the
    slot to the specific's initializer even when the specific's return type is
    not initialized in place (an `i16` from `Cpp.Twice`), and lowering builds a
    thunk call with a return-slot argument that the thunk does not take: STOP
    lower/handle_call.cpp:984 (``Argument mismatch: call ptr
    @_Z5TwiceIsET_S0_.carbon_thunk._(ptr %temp, i16 poison)``; :783 on the
    nightly). **(H7)**: convert.cpp `PerformAction(InitializeAction)`.

The SemIR of a specialization in a checked generic, from generic_call.carbon's
dump on TP-1 (the shape v11 keeps, §0.7): `%.loc8_25.N: <instruction> =
call_action (...)`, `type_of_inst`, `splice_inst`, then `initialize_action`
over the spliced type, all `[template]`, and in the specific `%.loc8_25.N =>
constants.%inst.splice_block...` with the instantiated `S<X>` as the splice's
value. No instruction kind is added or changed (D-CT-1).

### §0.5 Root causes, measured

Over the 148 probes of §0.3, v11 changes no probe that runs on TP-1 (39 run on
both and print the same) and moves 89 from a rejection or a stop to running.
Of TP-1's 15 stops, 10 run on v11, 2 become Clang's own error in the
instantiated C++ (E-CXX, the right answer: `Point` has no `operator+`), and 3
remain, a concrete C++ class `var` in a template's body (W-304, §1.11). The 21
probes that do not run on v11 are each accounted for in §1.11: 5 E-MONO
(c_member_missing and t_member_missing, the right answer; g_facet_constrained
and g_facet_constrained_member, W-305; g_nontype_i64, the right answer with a
note that has no line, W-306), 2 E-UNMAPPED (W-300), 5 E-CXX (the right
answer), 1 E-TT (W-301), 1 E-COPY (the checked generic's own rule), 2 E-AS and
2 E-PARSE (the probes' own errors), and the 3 stops.

Seven root causes, each fixed where it is (R17), with the probes it stops on
TP-1 and the state that first runs them:

| Root | Hook | Cause | Stops on TP-1 (trunk, nightly alike) | Fix | First runs at |
| --- | --- | --- | --- | --- | --- |
| R1 | H2 | impl lookup on a C++ specialization of a symbolic argument is resolved where the generic is defined, because `NamesTemplateBinding` (impl_lookup.cpp:578-634) neither treats a `TemplateInst` as template-dependent nor follows an action's `MetaInstId`/`MetaInstBlockId` operands | E-DU: 55 probes (49 run on v11), every uninitialized `var` of `Cpp.Box(T)`, `Cpp.Pair(Cpp.Box(T))`, `Cpp.Box(List(T))`, `Cpp.Array(i32, N)`, `Cpp.Loud(T)`, and TP-1's own W-268 (`var e: T.Elem;`, g_w268, w268_d03_var_elem) | D-CT-5 | c1 (v1 measured it alone: the E-DU class runs) |
| R2 | H3 | `ActionIsPerformable` (action.cpp:180-213) performs a C++ call or specialization whose arguments are a checked generic's symbolic values, in a template's specific evaluated for a symbolic argument | STOP generic_region_stack.h:98 (t_box_in_generic_caller), E-MONO with E-ARG's note (t_symbolic_call_in_generic_caller) | D-CT-6 | c1b (c1 still stops and rejects) |
| R3 | H4 | `SubstInst` (subst.cpp:93-260) does not substitute into an action's `MetaInstId`/`MetaInstBlockId` operands, so an action formed for a symbolic specific keeps its symbolic operands in a concrete one | STOP custom_witness.cpp:487 (s1_class_field_in_generic, s1c_construct_only; :401 on the nightly), STOP handle_expr_category.cpp:20 (s1b_param, s1d_field_var, s1e_return_box, s1f_method) | D-CT-7 | c1 |
| R4 | H7 | `PerformAction(InitializeAction)` (convert.cpp:2993-3060) hands a `return`'s initializer the function's return slot whatever the specific's return type, and a return type that is not initialized in place has no slot | STOP lower/handle_call.cpp:984 (y_E_only, y_E_nontemplate_fn; :783 on the nightly), both an `i16` through `Cpp.Twice` | D-CT-8 | c1 (v10, without it, still stops) |
| R5 | H5 | `BuildTemplateId` (cpp/call.cpp:317-324) uses the declaration form of `CheckVarTemplateId`, which leaves a specialization nothing declared at `TSK_Undeclared`, so its definition is never instantiated | L-UNDEF: c_var_template, t_var_template, z_sizeof_var, z_var_template_runtime, cpp_var_template_runtime; concrete uses too | D-CT-9 | c1 (v8) |
| R6 | H6 | `IsMoveEquivalentToCopy` (overload_resolution.cpp:157-190) reads the special members of an exported Carbon class whose definition the external AST source has not produced yet | STOP clang assertion (DeclCXX.h:464): z_id_point_lit (concrete: `Cpp.Id({.x = 6} as Point)`), c_bad_inst, t_bad_inst; a segfault on the nightly | D-CT-10 | c1 (v3) |
| R7 | H1 | a call to an imported C++ function with an argument of a checked generic's symbolic type is performed where the generic is defined, and `T` has no C++ type there | E-ARG: 22 probes that run on v11 (c_fn_template_call, c_fn_template_explicit, c_method_call, c_pass_to_cpp, c_return_spec, the `y_` and gen3 call programs, ...) | D-CT-3 | v11 (c1b still rejects) |

The forms with a template binding (`t_`) already run on TP-1 wherever their
checked twin's only problem is R7: TP-1's template lane defers every operation
on a template-dependent operand. They are the twins that fix each `c_` form's
expected output (R16(d)).

### §0.6 Exported Carbon classes as template arguments

A Carbon class as a C++ template argument is exported by `ExportClassToCpp`
(type_mapping.cpp:366 calling check/cpp/export.cpp), at the specific for a
symbolic `T`, exactly as for the concrete `Cpp.Box(Point)` that
cpp_template_carbon_class.carbon already runs; CT-1 adds no export mechanism.
Three requirements were checked:

-   **OX-1's lesson** (its plan was parked because exporting operator impls
    leaked into Carbon's own resolution, fork/ORCHESTRATION.md branch table):
    CT-1 changes nothing that Carbon-side lookup reads. The only export-side
    change, D-CT-10, completes a Clang record that Clang is about to query; the
    gate shows no golden outside interop/cpp/template and
    lower/interop/cpp/globals.carbon changing (§0.7), and the 39 probes that
    run on TP-1 print the same on v11.
-   **PR 55's null check** (ST-1, export.cpp:293-300 on PR 55:
    `ExportClassToCpp` returns null when the parent scope cannot be exported, as
    the other callers check). The path CT-1 exercises at a specific reaches it
    for a class in a generic class's scope: ox/nested_generic_scope is rejected
    on TP-1, the nightly and v11 with ``semantics TODO: `non-class non-namespace
    name scope` `` and then E-UNMAPPED, the same TODOs as the concrete twin
    ox/nested_generic_scope_concrete, and nothing stops. CT-1 has no hunk in
    export.cpp, so PR 55's check composes textually (§0.9).
-   **Layout.** A specialization on an exported class is imported with its
    Clang layout through `CustomLayoutType` (import.cpp:700-708, :884), as the
    concrete case is; v11's runs of `Cpp.Box(Point)`, `Cpp.Loud(Point)` and
    `Cpp.Box(List(i32))` through a checked generic read back every field
    (cpp_template_symbolic_arg 7, cpp_template_two_specifics 12,
    cpp_template_carbon_generic_spec 6), and the differential program's
    `Acc<short>` (a `short` total and an `int` count) matches its C++ oracle.

### §0.7 Prototype v11 and its gate

v11 is TP-1 plus the seven-file diff of §2 (163 lines added, 11 removed). The
gate, file_test over this tree's 1957 goldens with TP-1's runfiles (the
container arbiter's gate.sh shape), on TP-1: 1957 of 1957. On v11 (and on c1 and
c1b): 1953 of 1957, the red set exactly:

| Golden | Why it changes | The change (autoupdate on a scratch mirror, a fixpoint: a second run changes nothing) |
| --- | --- | --- |
| check/interop/cpp/template/generic_call.carbon | D-CT-5: `var unused v: Cpp.S(T);`'s `DefaultOrUnformed` lookup is formed in the specific, not where `F` is defined | `require_specific_def @T.as.DefaultOrUnformed.impl(%.537) [template]` and its specific's `%.e53` leave the definition; the prelude's `T.as_type.as.DefaultOrUnformed.impl` constants move to the specific's block; the `loc8_25` instruction numbers shift by one; +26/-30 lines |
| check/interop/cpp/template/non_type_param.carbon | D-CT-9: `Cpp.X(i32, i32).n(1, 2)` now instantiates `X<int, int>::n<1, 2>`, which has no definition | split dependent_parameter_pack gains Clang's warning ``instantiation of variable 'X<int, int>::n<1, 2>' required here, but no definition is available [CppInteropParseWarning]`` with its two notes, the same as clang++ (§0.3); +10 lines |
| check/interop/cpp/template/var_template.carbon | D-CT-9: `struct Wrap { template<typename T> static T var = {}; };` is ill-formed C++ once instantiated (clang++ rejects it identically, §0.3) | the header becomes `static inline T var = {};` (valid C++, the test's intent: read a static member template), and a new split pins the ill-formed form (Appendix A.3); +18/-1 lines |
| lower/interop/cpp/globals.carbon | D-CT-9: the variable template specializations are defined | the header's `static T static_tmpl = T();` becomes `static inline T static_tmpl = T();` for the same reason; `@_Z4tmplIiE` and `@_Z4tmplI1YE` change from `external global` to `linkonce_odr dso_local global` with a guard variable and `__cxx_global_var_init`, and the same for `StaticTmplX::static_tmpl`; debug metadata numbers shift; +220/-160 lines |

The two new goldens (Appendix A.1 and A.2) were filled the same way, with a
file_test relinked over a copy of the build's generated manifest
(gen/toolchain/testing/file_test_autogen_manifest.cpp) that lists them:
autoupdate reaches a fixpoint at its second run (911 and 1339 lines; the first
run's line numbers in quoted source move once), and in test mode both pass on
v11. On c1b their C1 subset (nine and four splits) fills identically to v11's
fill of the same subset and passes, and the C2 splits report E-ARG, so C2
changes nothing that C1 pins. On TP-1 the file_test process stops (the clang
assertion of R6 and STOP generic_region_stack.h:98), so the two files fail as
a whole without CT-1; §8's mutants name the split that kills each change.

Two rejected prototype states: v2 converted every value argument to a
`TemplateInst`-typed value (STOP type_completion.cpp:348 on its first probe),
and v9 substituted into every action operand (25 goldens changed, among them
check/array/init_dependent_bound.carbon, class/destroy_calls.carbon,
eval/call.carbon, generic/template/convert.carbon and default_init.carbon,
because an action that refers to an instruction of the generic's body must keep
referring to it); v10 restricts the substitution to operands that are
themselves constant instructions and changes no golden beyond the four.
v4 to v6 tried to instantiate the variable template's definition elsewhere
(ineffective: the specialization kind stayed `TSK_Undeclared`); v7 is D-CT-9.

### §0.8 Conformance under rows 56 and 42

The runner (fork/conformance/runner.py, `--toolchain` the install's busybox,
`--programs` a scratch copy, `--out` scratch) over this tree's 160 programs on
TP-1: 138 PASS / 0 FAIL / 22 SKIP, 48 of 56 bullets PASS and 8 SKIP. On v11
with the programs of §1.14 (the two un-SKIPped, seven new): 147 / 0 / 20 over
167, 48 of 56 bullets. Both bullets were already PASS (a SKIP does not count
against a bullet) and stay PASS; their program lists grow:

| Bullet (gap row) | TP-1 programs | v11 programs |
| --- | --- | --- |
| Generics: C++ interop — importing C++ templates, instantiating on Carbon types (56) | cpp_template_builtins, cpp_template_carbon_class, cpp_template_symbolic_arg (SKIP) | the same three, cpp_template_symbolic_arg PASS, and cpp_template_carbon_generic_spec, cpp_template_fn_symbolic, cpp_template_nested_symbolic, cpp_template_spec_roundtrip, cpp_template_symbolic_diff (differential), cpp_template_two_specifics, cpp_var_template_runtime |
| Type system: C++ interop — importing C++ types / exporting Carbon types (42) | cpp_template_on_carbon_generic (SKIP), cpp_type_export_carbon_class, cpp_type_import_class_enum | the same, cpp_template_on_carbon_generic PASS |

Relative to the trunk floor of record (128 / 0 / 22 over 150), this branch's
tree is +19 PASS, -2 SKIP, +17 programs: TP-1's ten programs and CT-1's nine
changes.

### §0.9 Collisions with the held PRs

Each held PR's own diff (merge-base with trunk to its head) over CT-1's seven
files was dry-run onto TP-1's files and onto v11's (patch --dry-run); the
results are identical, so CT-1 adds no textual conflict to any held PR's
merge:

| Held PR | Touches CT-1's files | Onto TP-1 | Onto v11 | Rule at CT-1's merge |
| --- | --- | --- | --- | --- |
| PR 51 (UA-2, f96fe8a7a) | none of the seven; the two SKIP programs (C-1) and dependent_var_full_prelude.carbon (C-2) | n/a | n/a | C-1, C-2 |
| PR 52, 53, 54 | none | n/a | n/a | none |
| PR 55 (ST-1, 21307851a) | none of the seven (export.cpp only) | n/a | n/a | textual only |
| PR 56 (OP-1, 379f20f67) | none | n/a | n/a | none |
| PR 57 (OP-2, 628273444) | convert.cpp, one hunk | applies, offset | applies, offset | textual only |
| PR 58 (DD-1, fcee90d9b) | none in the toolchain; the interop design page, W-043's notes, gap rows (shifted +6) | n/a | n/a | C-3 |
| PR 59 (VA-1, b0822a744) | call.cpp, convert.cpp | applies, one hunk with fuzz 1 | the same | textual only |
| PR 60 (SC-1, 40a76ab81) | call.cpp, convert.cpp, impl_lookup.cpp | convert.cpp hunks 5 and 6 fail (TP-1's own conflict, which its land-time M resolves) | the same two, no other | TP-1's M resolution, unchanged |
| PR 61 (TP-1) | the base | n/a | n/a | CT-1 is stacked on it |
| PR 62 (SV-1, 3a6531157) | convert.cpp | applies, one hunk with fuzz 1 | the same | textual only |

No held PR touches the four goldens CT-1 refills. Three content collisions:

-   **C-1 (PR 51, the two programs).** PR 51 un-SKIPs both programs with a
    constructor initializer and `impl as Core.Copy` and a long dated header
    (its round-1 and round-2 history); CT-1's versions un-SKIP them with the
    `Core.Copy` impl only, keeping the uninitialized `var b: Cpp.Box(T);`.
    PR 51 merges first. Rule: the merged file is PR 51's header with one
    dated paragraph appended (Appendix C.6) and CT-1's body, the
    uninitialized `var`, which v11 runs (pr51/*_uninit print 7) and TP-1
    rejects (E-DU), so the program again pins its original claim; the
    constructor initializer was the workaround for W-127.
-   **C-2 (PR 51's dependent_var_full_prelude.carbon, and TP-1's F6).** PR 51
    pins `fn F[T: type](unused x: T) { var unused v: Cpp.S(T); }` under the
    real prelude as split `fail_todo_unformed_dependent_var` (W-127). TP-1's
    plan predicts that its C4 makes that split succeed and renames it in its
    land-time fill F6 (fork/templates/plan.md §0.9 PR 51 row, §1.9, §3 item 8,
    Appendix A's F6 line, and the W-127 discharge texts in its landed notes and
    Appendix E). Measured: the split's shape (w127/w127_unformed) is rejected
    on TP-1 with E-DU, because D-TP-12 keeps a checked generic's lookup (TP-1's
    own W-127 text says so: "checked generics keep their lookup"), and it runs
    on v11.
    So TP-1's F6 rename would leave a split without the `fail_` prefix that
    still reports an error; CT-1's D-CT-5 is what makes it succeed. Rule: the
    rename and refill move to CT-1's land-time fill (§3, L-F), TP-1's F6
    drops that item, and W-127's discharge text names CT-1 for the checked
    shape (hand-off note H-1; this plan cannot edit PR 61).
-   **C-3 (PR 58, the design page and records).** DD-1 rewrites
    docs/design/interoperability/README.md's "Using C++ templates" with the
    sentence "One limit in 0.1: a `var` of such a specialization cannot be
    declared without an initializer, because `var b: Cpp.Box(T);` reports that
    the type does not implement `Core.DefaultOrUnformed` (fork work item W-043,
    and W-127 on held PR 51)" (DD-1's README.md:691-694), adds fixture X09 for
    the symbolic argument, amends W-043's notes and evidence, and shifts the
    gap rows by six (row 56 is row 62 and row 42 is row 48 on PR 58). Rule:
    the design page edit is a land-time commit L after PR 58 against DD-1's
    text (Appendix C.1), and the land-time records commit merges DD-1's W-043
    notes into CT-1's discharge text (Appendix C.2).

### §0.10 Upstream direction and the V-3a register

Upstream's direction is per-specific instantiation: the deferral CT-1 completes
is upstream's own (PRs 7673, 7689 and 7700; the `TemplateInst` comment at
check/call.cpp:749-750 "so that all symbolic arguments are treated as
templates"), and leads issue 2153 decided that a checked generic may call a
template, "relies on monomorphization"
(docs/design/generics/appendix-witness.md:149-155; overview.md:375-379 records
the decision and leaves its design as future work). Proposal 2200 delays impl
lookup until template arguments are known (p002200:198-199), which D-CT-5
applies to a C++ specialization of a symbolic argument. Since the fork's cut
(c1e83b0b7, 2026-10-05) upstream trunk has 94 commits (to 0546b48a7,
2026-10-21); none touches check/testdata/interop/cpp/template, and the two that
touch the same code are adjacent, not overlapping: 230227264 ("Only allocate
return storage when the callee has a return parameter", upstream PR 7886, the
caller side of return storage in call.cpp, beside D-CT-8's callee side) and
7beb29f8b ("Use a fallback loc for diagnostics generated on canonical insts",
upstream PR 7967), which is the class W-306 belongs to. Nothing in CT-1
contradicts an accepted proposal or a leads decision (V-3).

V-3a divergence-risk register entries (reviewed at each upstream merge):

-   `NamesTemplateBinding` treats a `TemplateInst` as naming a template binding
    and walks `MetaInstId`/`MetaInstBlockId` operands (D-CT-5). Upstream has
    no `NamesTemplateBinding` (it is TP-1's D-TP-12); on an upstream merge that
    lands its own deferral of template-dependent impl lookup, keep upstream's
    and re-measure E-DU's probes.
-   `DeferCppCallOnSymbolicArgs` in check/call.cpp (D-CT-3) and the C++-callee
    clause of `ActionIsPerformable` (D-CT-6): upstream diagnoses E-ARG today;
    if upstream lands deferral of C++ calls on symbolic arguments, keep
    upstream's and drop these.
-   The `MetaInstId`/`MetaInstBlockId` cases of `SubstInst` (D-CT-7), a fix to
    upstream code that upstream may land differently (trunk and the nightly
    stop the same way); on merge keep whichever substitutes an action formed
    for a symbolic specific and leaves body operands.
-   `PerformAction(InitializeAction)`'s return-slot condition (D-CT-8), in
    TP-1's code; beside upstream's 230227264, which decides the caller side.
-   The `TSK_ImplicitInstantiation` marking in `BuildTemplateId` (D-CT-9), a fix
    to upstream code for upstream's L-UNDEF.
-   The completion in `IsMoveEquivalentToCopy` (D-CT-10), a fix to upstream
    code for an assertion trunk and the nightly share.

### §0.11 Id allocation and re-scan

CT-1 reserves W-300..W-319 and files W-300..W-306 (§1.12), leaving W-307..W-319
unused and never reused. The re-scan, run before writing this plan and again
before the discharge commit D (and at land time), over every origin ref's and
every worktree's ledger, widened to W-319:

<!-- google-doc-style-ignore -->

```sh
cd /home/user/carbon-ct && git fetch -q origin
( for r in $(git for-each-ref --format='%(refname)' refs/remotes/origin refs/heads); do
    git show "$r:fork/inventory/work-items.json" 2>/dev/null; done
  for w in $(git worktree list --porcelain | sed -n 's/^worktree //p'); do
    cat "$w/fork/inventory/work-items.json" 2>/dev/null; done ) |
  grep -o '"W-3[01][0-9]"' | sort | uniq -c
git grep -n 'W-3[01][0-9]' $(git for-each-ref --format='%(refname)' refs/remotes/origin) -- fork
```

<!-- google-doc-style-resume -->

Result on 2026-10-21 (67 origin refs, 16 worktrees): no W-300..W-319 anywhere;
the highest id in any ledger is W-298 (TP-1's, PR 61), W-299 being TP-1's
reserved and unused id. F-021 is not reserved (D-CT-16).

## §1 Design

Every decision is auto-adopted under V-2/V-3 (R29(a)) and open to veto; each
ends with its break condition, the one observation that would falsify it.

### §1.1 The deferral model (D-CT-1)

**D-CT-1. A C++ template use with a symbolic argument stays upstream's deferred
`CallAction`, performed for each specific; CT-1 adds no instruction kind, no
SemIR field and no new action.** The specialization is formed by
`PerformCallToCppTemplateName` when a specific's arguments are known, which is
the only place Clang can form it: Clang has no representation of a Carbon
symbolic type (`TryMapSymbolicType`, type_mapping.cpp:372-381, maps only a
symbolic type that C++ itself declared). The SemIR is the one §0.4 shows:
`call_action` over the callee and the `TemplateInst`-wrapped arguments,
`type_of_inst`, `splice_inst`, and TP-1's `initialize_action`,
`access_member_action` and `convert_to_value_action` over the spliced type, each
`[template]`; each specific's block holds the instantiated specialization as
the splice's value. Two specifics form two specializations (`Loud<int>` and
`Loud<Point>`, cpp_template_two_specifics prints `5`, `12` and a destructor
count of `2`). _Break condition:_ a form of the admitted kinds (§1.11) that
needs a new instruction kind or SemIR field to be formed per specific.

### §1.2 The checked-generic rule (D-CT-2)

**D-CT-2. In a checked generic, a C++ specialization of a symbolic argument and
every operation on a value of it are checked for each specific, as a template's
operations are; an error is reported on instantiation, at the call that names
the specific, with a note at the operation.** This is upstream's own rule: the
specialization's arguments are wrapped "so that all symbolic arguments are
treated as templates" (call.cpp:749-750), and leads issue 2153's decision that a
checked generic may call a template "relies on monomorphization"
(appendix-witness.md:149-155). C++ declares nothing a definition could be
checked against, so nothing else is possible: a member access on `Cpp.Box(T)`
is a member of `Box<T>`, which Clang forms only for a known `T`. What stays
definition-checked is everything that does not involve the specialization:
`var r: T = v;` in the same checked generic is rejected where it is defined
(E-COPY and ``cannot access member of interface `Core.Destroy` in type `T` ``),
on TP-1 and v11 alike (twin/result_in_var_twin), and c_result_in_var, which
initializes a `T` from `Cpp.Twice(v)`, is rejected the same way. The note texts
on instantiation are Carbon's and Clang's existing ones (§1.11): ``member name
`nope` not found in `Cpp.Box` `` (c_member_missing), Clang's E-CXX with its
"in instantiation of" note (c_bad_inst_generic). A body that is never
instantiated is not diagnosed (c_member_missing_uncalled prints 33), as a
template's is not. _Break condition:_ an operation that involves no C++
specialization or C++ call in a checked generic is deferred instead of checked
where the generic is defined (falsifiers: facet/period_self.carbon or
twin/result_in_var_twin changes).

### §1.3 C++ calls on checked-symbolic arguments (D-CT-3)

**D-CT-3. A call to an imported C++ function (an overload set, a function
template or a member function) with an argument whose dependence is `Checked`
(a value `x: T` or the type `T` of a checked generic) is deferred as a
`CallAction`, with a symbolic facet-typed argument wrapped in `TemplateInst` as
`PerformCallToNonFunction` wraps a C++ template's, and performed for each
specific.** It is the function-call half of D-CT-2: Clang resolves the overload
set and deduces the template's arguments only from C++ types, and E-ARG
(type_mapping.cpp:593-599) is what the definition can say today. A call whose
arguments are all concrete, or template-dependent (TP-1's lane, which already
defers on `IsCallPerformable`), is unchanged. Measured: the 22 E-ARG probes run
(`Cpp.Twice(v)` 42, `Cpp.Twice(T, v)` 42, `Cpp.Max(a, b)` 9, `Cpp.Unbox(b)` 9,
a member call `b.Get()` 8, `Cpp.SameBox(b, b)` 12), c_sizeof, whose explicit
type argument TP-1 dropped (E-NOMATCH), prints 35, and a callee that is not a
template (`Cpp.UnboxInt(b)` for `Box<int>`, c_param_unbox_int 24) is
unchanged. _Break condition:_ a C++ call whose arguments are all
concrete changes (falsifier: any golden of a concrete C++ call; the gate shows
none), or a call with a checked-symbolic argument is still diagnosed where the
generic is defined.

### §1.4 The template rule rides TP-1 (D-CT-4)

**D-CT-4. With a template binding, CT-1 changes nothing of TP-1's rules but
D-TP-12 (D-CT-5) and adds D-CT-6 to D-CT-8, which a template's C++ uses need as
much as a checked generic's.** TP-1's TR-3 and TR-4 (a template-dependent
expression is checked on instantiation; a use of a dependent value is
dependent), TR-5 (pointer operators on a dependent operand), TR-7 (calling a
value of dependent type), TR-8 (simple member access, PARTIAL, the rule W-305
meets), D-TP-11 (`IsCallPerformable`), D-TP-12 as amended, and D-TP-14
(cross-library generics resolved per instantiation are a `semantics TODO` at
the `import`, W-250) stand: xlib/x1, x2 and x5 report D-TP-14's TODO on TP-1 and
v11 where trunk and the nightly stop at import_ref.cpp. TR-22 (a checked
generic's symbolic argument passed to a template parameter) stays OUT: CT-1
extends its "a form whose actions can be performed for it runs" to C++ uses, by
D-CT-6 and D-CT-7, so t_box_in_generic_caller (STOP generic_region_stack.h:98
on every toolchain) and t_symbolic_call_in_generic_caller (E-MONO) print 31 and
30; TP-1's TR-22 pins are unchanged (the gate). The template forms of the probe
matrix that run on TP-1 run unchanged on v11 (39 of 39). _Break condition:_ a
golden of TP-1's template lane changes other than the four of §0.7.

### §1.5 Deferred impl lookup on a C++ specialization (D-CT-5, amends D-TP-12)

**D-CT-5. An impl lookup whose query reaches a `TemplateInst`, or an action's
operand that names a template binding, is deferred to the specific:
`NamesTemplateBinding` returns true at a `TemplateInst` and follows `MetaInstId`
and `MetaInstBlockId` operands as it follows `InstId` and `InstBlockId`.**
D-TP-12 (fork/templates/plan.md §1.7) deferred only queries that name a
template binding and kept a checked generic's lookup for a C++ template self;
D-CT-5 amends it for that self, because the self is a `TemplateInst`-wrapped
specialization that upstream means to be "treated as templates", and its
`DefaultOrUnformed` impl (`impl forall [T: UnformedInit]`, or the `final impl
forall [T: Default]` with a C++ class's custom `Default` witness) can be decided
only when `T` is known: `Box<Point>` with a Carbon class field and `Box<int>`
differ. The `MetaInstId` walk is W-268's removal condition, so W-268
(`var e: T.Elem;`, g_w268 and w268_d03_var_elem, ``6 4``) is discharged.
D-TP-12's named falsifier changes as intended: generic_call.carbon's
`require_specific_def` leaves the definition (§0.7); facet/period_self.carbon,
its other falsifier, is unchanged. PR 51's W-127 split shape runs (C-2).
_Break condition:_ facet/period_self.carbon changes, or a checked generic's
query that reaches neither a `TemplateInst` nor a template binding is deferred.

### §1.6 C++ callee performability (D-CT-6)

**D-CT-6. A `CallAction` whose callee is a C++ template name or a C++ overload
set is performable in a specific only when each argument's dependence there is
`None`.** `ActionIsPerformable`'s general rule (below `Template`) is right for
Carbon callees, which a checked generic's symbolic arguments can be checked
against; a C++ callee needs concrete arguments (D-CT-1). The case it decides is
a template's specific evaluated for a checked generic's symbolic argument
(TR-22): the action waits in `F(U)` and is performed in `H(i32)`'s
substitution (D-CT-7). _Break condition:_ an action of a C++ callee whose
arguments are concrete in the specific is not performed (falsifiers:
cpp_template_fn_symbolic's `TwiceTemplate` and the `t_` probes with a C++
call), or a Carbon callee's action waits.

### §1.7 Substitution into action operands (D-CT-7)

**D-CT-7. `SubstInst` substitutes into a `MetaInstId` or `MetaInstBlockId`
operand that is itself a constant instruction, and leaves an operand that is an
instruction of a generic's body or eval block.** An action formed while another
generic's eval block was evaluated for a symbolic specific (a field type
`Cpp.Box(T)` of `Holder(T)` formed for `Holder(U)` inside a generic over `U`, or
a C++ call in `F(U)`) is a constant whose operands are symbolic in `U`; without
the substitution its splice survives into the concrete specific (R3). An
operand that is an instruction of a body is what the action refers to in every
specific, and substituting it rewrites the action into a different one: v9,
which substituted every operand, changed 25 goldens. Measured: the six s1
probes run on v11 (54, 60 to 64); on c1, which lacks D-CT-3 and D-CT-6,
s1b_param, which calls no C++ function with a symbolic argument, runs (60).
_Break condition:_ a golden whose actions refer to
body instructions changes (v9's 25), or an action formed for a symbolic
specific keeps a symbolic operand in a concrete specific.

### §1.8 Return-slot storage of a deferred initializer (D-CT-8)

**D-CT-8. `PerformAction(InitializeAction)` gives a `return`'s initializer the
function's return slot only when the specific's return type might be
initialized in place (`InitRepr::MightBeInPlace`), and otherwise lets the
initializer make its own storage, as the same `return` does when its type is
not dependent.** The return slot exists only for an in-place return type, so a
template-dependent `return Cpp.Twice(v);` that is an `i16` in the specific had
storage that the callee does not take (R4); a class type keeps its in-place
storage. Measured: y_E_only and y_E_nontemplate_fn print 16 (STOP on TP-1,
trunk, nightly, and on v10, which lacks D-CT-8), z_short_return's concrete
twins print the same, and lower/testdata/template/initialize.carbon (TP-1's
in-place pins) is unchanged. _Break condition:_ a class-typed dependent return
loses its in-place storage (falsifier: lower/testdata/template/initialize.carbon
or lower/testdata/interop/cpp/template_symbolic_arg.carbon's class split
changes), or a scalar dependent return still passes a slot.

### §1.9 Variable templates (D-CT-9)

**D-CT-9. A variable template specialization that nothing declared is marked
`TSK_ImplicitInstantiation` when Carbon names it, as Clang's expression form of
`CheckVarTemplateId` does before it builds a reference, so its definition is
instantiated and emitted.** The declaration form leaves it `TSK_Undeclared`,
and the reference the import makes never instantiates it (R5): L-UNDEF for
`Cpp.SizeOf(i32)`, concrete or symbolic. Clang's own consequences follow, as
clang++ shows them (§0.3): an ill-formed member template is now an error on
use, and an undefined one a warning; the two goldens whose C++ headers were
ill-formed C++ get valid headers and a split that pins the ill-formed form
(§0.7, Appendix A.3, A.4). A specialization C++ declared (an explicit
specialization or instantiation) keeps its kind. _Break condition:_ a
specialization that C++ declared changes its specialization kind, or a
variable template use still link-fails.

### §1.10 Exported-class completion (D-CT-10)

**D-CT-10. `IsMoveEquivalentToCopy` completes an exported Carbon class through
the external AST source before it reads the class's special members, as
`ExportAndCompleteClassToCpp` (export.cpp:313-320) and the name-scope export
(export.cpp:169-174) already do, and treats a class that is still incomplete as
not movable by copy.** An argument of an exported class type reaches overload
resolution before anything completed the record (R6); the concrete
`Cpp.Id({.x = 6} as Point)` stops the compiler on TP-1, trunk and the nightly.
Measured: z_id_point_lit prints 6; c_bad_inst and t_bad_inst report Clang's
E-CXX for `Twice<Carbon::Point>`. _Break condition:_ a golden that exports a
Carbon class changes (the gate: none), or another query of an exported record
still stops.

### §1.11 Admitted argument kinds and the OUT forms (D-CT-11)

**D-CT-11. IN: a symbolic or concrete type argument that maps to C++ (a
builtin, an exported Carbon class, a specific of a Carbon generic class, a C++
type or specialization, a pointer to one), a symbolic integer argument of a
non-type parameter whose type it converts to, a C++ template name as a template
template argument, and a variable template; the OUT forms keep the diagnostics
below, each filed (§1.12).** IN forms measured on v11: `Cpp.Box(T)` for `i32`,
`Point`, `List(i32)`, `Wrap2(i32)`, `i32*` (7, 16, 15, 53, 48);
`Cpp.Pair(Cpp.Box(T))` (14); `Cpp.BoxAlias(T)` (17); `Cpp.Array(i32, N)` with
`generic N: i32` (3); `Cpp.Apply(Cpp.Box, T)` (45); `Cpp.SizeOf(T)` (18);
`Cpp.Box(T).Kind()` and `Cpp.Box(T).value_type` (37, 38); a member function
template `h.Id(v)` (36).

| OUT form | Measured on v11 (TP-1, trunk, nightly) | Filed |
| --- | --- | --- |
| a struct or tuple type as `T` (`{.a: i32}`, `(i32, i32)`), or a Carbon class that cannot be exported (in a generic class's scope) | E-MONO ``unable to monomorphize specific `F({.a: i32})` `` with ``note: semantics TODO: `unsupported type used as template argument` `` (no line); for the class, first the export's ``non-class non-namespace name scope`` TODO; the concrete twin reports the same TODO at the argument (TP-1 and the nightly add E-DU first) | W-300 |
| a Carbon generic class as a template template argument (`Cpp.Apply(List, i32)`) | E-TT at the argument, on every toolchain (cpp/call.cpp:157-159 passes a placeholder that Clang rejects) | W-301 |
| a non-type argument that is a pointer to a Carbon variable (`Cpp.PtrBox(&n)`), or of a kind `MapConstantToAPValue` does not map | ``semantics TODO: `unsupported argument type for non-type template parameter` `` (cpp/call.cpp:246, :256-259), on every toolchain; a `double` argument works (res/w302_double_nttp, 52) | W-302 |
| deducing a Carbon generic parameter through a C++ specialization in a parameter's type (`fn Get[T: type](b: Cpp.Box(T))` called with a `Box<int>`) | E-DEDUCE with ``note: while deducing parameters of generic declared here``, on every toolchain; the programs pass `T` through another parameter instead | W-303 |
| a concrete C++ class `var` in a template's body (`var unused h: Cpp.Holder;` in `fn F[template T: type]`) | STOP lower/function_context.cpp:264 (``const_id.is_concrete()``: a `SpliceInst` left non-concrete in the specific); trunk :223, the nightly sem_ir/constant.cpp:36; the checked twin c_class_member_template runs (36) | W-304 |
| a simple member access to an interface member through `T`'s constraint, on a value read from a specialization's member (`b.value.Get()` for `T: Show` with `impl as Show` not `extend`) | E-MONO with ``member name `Get` not found in `S2` ``; `v.Get()` on `v: T` runs (49), and the compound `b.value.(Show.Get)()` runs (s3_compound_member, 56); TP-1's W-266 shape | W-305 |
| (diagnostic quality) a note from a template argument converted for a specific has no line, and a type argument that fails twice reports E-MONO twice | E-UNMAPPED's note and g_nontype_i64's ``cannot implicitly convert expression of type `i64` to `i32` `` print `file.carbon: note:`; ox/nested_generic_scope reports two E-MONO | W-306 |
| a generic from another library whose definition holds a C++ template use | D-TP-14's TODO at the `import` (xlib/x1, x2, x5) | W-250 (TP-1's; no new id) |

Not OUT, though they do not run, because they are right: c_member_missing and
t_member_missing (the member does not exist), the five E-CXX probes (Clang's
error in the instantiated C++), g_nontype_i64 (an `i64` does not implicitly
convert to the parameter's `int`; the concrete `Cpp.Array(i32, 49 as i64)` is
rejected the same way), c_result_in_var (D-CT-2), and the probes' own E-AS and
E-PARSE. _Break condition:_ an IN form that a probe shows rejected or stopped,
or an OUT form whose filed diagnostic changes without a decision.

### §1.12 Residues filed (W-300..W-306)

Seven items, filed in the discharge commit D, each a `missing-feature` or
`toolchain-defect` entry with the evidence above (Appendix C.3 holds the texts):
W-300 unmappable Carbon types as template arguments; W-301 Carbon generics as
template template arguments; W-302 non-type template argument kinds; W-303
deduction through a C++ specialization; W-304 the template-body stop for a
concrete C++ class `var` (trunk and the nightly share it); W-305 interface
member access through a constraint on a specialization's member (TP-1's W-266
shape for C++ specializations); W-306 instantiation notes without a line and the
repeated E-MONO (removal: upstream's 7beb29f8b, upstream PR 7967, at the next
upstream merge, then pass the action's location). W-307..W-319 are unused.

### §1.13 Goldens (D-CT-12)

**D-CT-12. Goldens (§4, Appendix A): a new check golden
interop/cpp/template/symbolic_arg.carbon under the real prelude and a new lower
golden interop/cpp/template_symbolic_arg.carbon pin the IN forms, the OUT
forms' diagnostics and the stops fixed; the four goldens of §0.7 are refilled,
two of them with the header fixes D-CT-9 requires; every CHECK line comes from
autoupdate (R16(a)).** _Break condition:_ a golden whose change is not
explained by a decision above.

### §1.14 Conformance programs (D-CT-13)

**D-CT-13. Two programs un-SKIPped with the `Core.Copy` impl each needs and no
other change to the claim; seven new programs under the owning bullet, one of
them a differential pair; every EXPECT derived by hand from C++ and Carbon
semantics (R16(d)) and checked against the template twin where one exists.**

| Program | EXPECT | Derivation |
| --- | --- | --- |
| cpp_template_symbolic_arg (un-SKIPped) | 7 | `Wrap({.x = 7} as Point)` stores 7 in a `Box<Point>` and returns it; `.value.x` is 7 |
| cpp_template_on_carbon_generic (un-SKIPped, row 42) | 7 | `MakeBox(p)` with `p.x == 7` returns a `Box<Pt>`; `b.value.x` is 7 |
| cpp_template_fn_symbolic | 42, 10, 9, 8, 2, 12 | `Twice<int>(21)` = 42; `Twice<int>(5)` = 10; `Max<int>(3, 9)` = 9; `SizeOfFn<long>()` = 8 and `SizeOfFn<short>()` = 2 on x86-64 Linux; `Twice<int>(6)` = 12 |
| cpp_template_spec_roundtrip | 42, 7, 7 | `MakeBox<int>(41)`, `Bump` adds 1, `Unbox` returns 42; `Make(7)` returns `MakeBox<int>(7)`, `UnboxInt` and `Get()` read 7 |
| cpp_template_nested_symbolic | 34, 9 | `Both(3, 4)` stores 3 and 4 in a `Pair<Box<int>>`, 3 * 10 + 4 = 34; `Sum` adds 4 + 5 = 9 |
| cpp_template_carbon_generic_spec | 6, 64, 65 | `Wrap(5)` stores `{.head = 5, .count = 1}` in a `Box<List(i32)>`, 5 + 1 = 6; `Holder(i32)`'s box holds 64; `Next` adds 1, 65 |
| cpp_template_two_specifics | 5, 12, 2 | `Keep(5)` is 5; `Keep` of `{.x = 1, .y = 2}` is printed 1 * 10 + 2 = 12; each call destroys its local `Loud` once, 2 |
| cpp_template_symbolic_diff (+ .diff.cpp) | the oracle's output | `SumThree<int>(1, 2, 3)` = 6, `SumThree<short>(10, 20, 30)` = 60, `CountThree<int>` counts 3; the oracle prints `6`, `60`, `3` |
| cpp_var_template_runtime | 5, 8, 20, 9 | `Plain<int>` = 4 + 1; `SizeOf<long>` = 8; `Holder::count<short>` = 2 * 10; `Plain<long>` through the generic = 8 + 1 |

All nine run on v11 and print their EXPECT lines; the differential program's
oracle, compiled with the toolchain's clang++ -std=c++17, prints the same three
lines. Where a program's form has a `t_` probe that already runs on TP-1
(t_fn_template_call, t_fn_template_explicit, t_pass_to_cpp, t_return_spec,
t_sizeof), that probe prints the value the derivation gives. Before CT-1 every
one fails on TP-1, trunk and the nightly (the gen3 rows of §0.3:
E-DU, E-ARG or L-UNDEF). _Break condition:_ a program passes on TP-1 (it would
pin nothing), or an EXPECT disagrees with its derivation.

### §1.15 Docs and records (D-CT-14)

**D-CT-14. The design page's "Using C++ templates" section is edited at land
time against DD-1's text (commit L, a dated paragraph replacing DD-1's "One
limit in 0.1" sentence, R27-diffed against the programs' spelling); the records
discharge W-043 with its residues filed and W-268, keep rows 56 and 42 PARTIAL
with corrected text, and add the decision-log entry "CT-1".** The texts are
Appendix C. Row 56 stays PARTIAL on W-300..W-303 (the OUT kinds) and row 42 on
its own export cases (its template clause is replaced); W-043's disposition is
DISCHARGED because its blocker, a symbolic Carbon type as a C++ template
argument, is IN, and what remains is filed. Records commits on this branch
(before PR 58 lands) write rows 56 and 42 at their line numbers here; the
land-time records commit rewrites them at PR 58's (62 and 48). _Break
condition:_ a row or ledger text claims a form that a probe shows rejected.

### §1.16 Merge position and held state (D-CT-15)

**D-CT-15. CT-1 is one PR stacked on PR 61, its base TP-1's branch until PR 61
merges, held like PR 51 to PR 62, and merged last, after PR 62.** Its land-time
items: M, a records-only merge of the trunk that holds PR 51 to PR 62; L-F, the
refill of what M changes, including PR 51's split renamed
`unformed_dependent_var` (C-2, moved from TP-1's F6) and the two programs'
merged text (C-1); L, the design page edit over PR 58's text (C-3); the second
id re-scan; the land-time records commit (rows at PR 58's line numbers, DD-1's
W-043 notes merged into the discharge text, W-127's discharge naming CT-1 for
the checked shape). If PR 61 changes before CT-1 lands, CT-1 rebases nothing (a
submitted PR's history is never rewritten, AGENTS.md); it merges PR 61's new
head into its branch in a records-only merge commit and refills. _Break
condition:_ a held PR's merge changes one of CT-1's seven files' hunks (the
dry-runs of §0.9 say no).

### §1.17 No fork design id (D-CT-16)

**D-CT-16. No F-021: every rule CT-1 implements is upstream's (the
`TemplateInst` deferral, leads issue 2153's monomorphization, proposal 2200's
delayed impl lookup) or Clang's (instantiation, completion, the variable
template's specialization kind).** _Break condition:_ a review identifies a
language rule here that no upstream source states, which then becomes F-021.

### §1.18 Decision index

-   D-CT-1, the deferral model: upstream's `CallAction` over `TemplateInst`,
    performed per specific, no new SemIR.
-   D-CT-2, the checked-generic rule: operations on a C++ specialization are
    checked for each specific and diagnosed on instantiation.
-   D-CT-3, C++ calls with a checked-symbolic argument are deferred.
-   D-CT-4, the template lane rides TP-1, TR-22 stays OUT.
-   D-CT-5, impl lookup on a C++ specialization is deferred (D-TP-12 amended,
    W-268 discharged).
-   D-CT-6, a C++ callee's action waits for concrete arguments.
-   D-CT-7, action operands that are constants are substituted.
-   D-CT-8, a deferred `return` uses the return slot only in place.
-   D-CT-9, variable template specializations are implicitly instantiated.
-   D-CT-10, an exported class is completed before overload resolution reads it.
-   D-CT-11, the admitted kinds and the OUT table.
-   D-CT-12, goldens: two new files, four refills, two header fixes.
-   D-CT-13, nine programs.
-   D-CT-14, docs at land time, records.
-   D-CT-15, stacked on PR 61, merged after PR 62.
-   D-CT-16, no F-021.

## §2 Spec, file by file

### §2.0 Conventions

The diffs are v11's, against this branch's head (TP-1's 5661a35c8), as
measured; the implementer applies them as written, and a change to them is a
plan amendment. Commit C1 holds §2.1 to §2.6 and commit C2 §2.7 (§3). Line
numbers are this branch's. No X-macro, `inst_kind.def`, `typed_insts.h` or
diagnostic kind changes, so no generated file changes and no new diagnostic
kind is added (D-CT-1, D-CT-11: the OUT forms keep their existing messages).

### §2.1 toolchain/check/impl_lookup.cpp (C1, D-CT-5)

`NamesTemplateBinding` (:578-634) gains three clauses: a `TemplateInst` names a
template binding, and a `MetaInstId` or `MetaInstBlockId` operand is followed as
an `InstId` or `InstBlockId` is. `push` already follows only symbolic constants
(:587-589), so the walk stays inside the query's symbolic operands. Review
points: the `TemplateInst` clause returns before the operand loop, as the
`SymbolicBinding` clause above it does; `QueryNamesTemplateBinding` (:636-660)
and its two callers (:1170, :1353) are unchanged. +16 lines.

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/check/impl_lookup.cpp
+++ b/toolchain/check/impl_lookup.cpp
@@ -604,15 +604,31 @@
         return true;
       }
     }
+    // A symbolic argument of a C++ template name, which
+    // `PerformCallToNonFunction` (call.cpp) wraps so that it is evaluated as a
+    // template: the specialization it names is formed only on instantiation.
+    if (inst.Is<SemIR::TemplateInst>()) {
+      return true;
+    }
     for (auto arg : {inst.arg0_and_kind(), inst.arg1_and_kind()}) {
       if (auto id = arg.TryAs<SemIR::InstId>()) {
         push(*id);
+      } else if (auto id = arg.TryAs<SemIR::MetaInstId>()) {
+        // An action's operand: a type that an action forms, such as a C++
+        // template's specialization or a member of a template parameter.
+        push(*id);
       } else if (auto id = arg.TryAs<SemIR::TypeInstId>()) {
         push(*id);
       } else if (auto id = arg.TryAs<SemIR::InstBlockId>()) {
         if (id->has_value()) {
           for (auto elem_id : context.inst_blocks().Get(*id)) {
             push(elem_id);
+          }
+        }
+      } else if (auto id = arg.TryAs<SemIR::MetaInstBlockId>()) {
+        if (id->has_value()) {
+          for (auto elem_id : context.inst_blocks().Get(*id)) {
+            push(elem_id);
           }
         }
       } else if (auto id = arg.TryAs<SemIR::SpecificId>()) {
```

<!-- google-doc-style-resume -->

### §2.2 toolchain/check/action.cpp (C1, D-CT-6)

`ActionIsPerformable` (:180-213) gains a clause before its general rule: a
`CallAction` whose first operand (the callee, which call.cpp puts first in
both builders) is a C++ template name or a `CalleeCppOverloadSet` is performable
only when every argument's dependence in the specific is `None`. The include of
toolchain/sem_ir/function.h is for `SemIR::GetCallee` and
`SemIR::CalleeCppOverloadSet`. Review points: a `CallAction` of a Carbon callee
falls through to the unchanged rule; `OperandDependenceInSpecific` of a
`MetaInstId` (:67-80) reads the argument's constant in the specific. +21 lines.

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/check/action.cpp
+++ b/toolchain/check/action.cpp
@@ -12,6 +12,7 @@
 #include "toolchain/check/type.h"
 #include "toolchain/sem_ir/constant.h"
 #include "toolchain/sem_ir/copy_on_write_block.h"
+#include "toolchain/sem_ir/function.h"
 #include "toolchain/sem_ir/generic.h"
 #include "toolchain/sem_ir/id_kind.h"
 #include "toolchain/sem_ir/inst.h"
@@ -204,6 +205,26 @@
     }
   }

+  // A call to an imported C++ function or a C++ template name is resolved by
+  // Clang, which needs the arguments, or their types, to be concrete: it waits
+  // for them even when they are only symbolic, as a checked generic's `T` and
+  // `x: T` are (`PerformCall`, `PerformCallToNonFunction`).
+  if (auto call = action_inst.TryAs<SemIR::CallAction>()) {
+    auto inst_ids = context.inst_blocks().Get(call->inst_block_id);
+    if (context.types().Is<SemIR::CppTemplateNameType>(
+            context.insts().Get(inst_ids.front()).type_id()) ||
+        std::holds_alternative<SemIR::CalleeCppOverloadSet>(
+            SemIR::GetCallee(context.sem_ir(), inst_ids.front()))) {
+      for (auto arg_id : inst_ids.drop_front()) {
+        if (OperandDependenceInSpecific(context, specific_id,
+                                        SemIR::MetaInstId(arg_id)) >
+            SemIR::ConstantDependence::None) {
+          return false;
+        }
+      }
+    }
+  }
+
   return OperandDependenceInSpecific(context, specific_id,
                                      action_inst.type_id()) <
              SemIR::ConstantDependence::Template &&
```

<!-- google-doc-style-resume -->

### §2.3 toolchain/check/subst.cpp (C1, D-CT-7)

`PushOperand` and `PopOperand` gain `MetaInstId` and `MetaInstBlockId` cases. An
operand is pushed with `skip` set unless it is its own constant instruction
(`IsSubstitutedActionOperand`), so a body or eval-block instruction is popped
unchanged and only a constant action (one formed for a symbolic specific) is
rebuilt. Review points: `Worklist::Push`'s `skip` parameter exists (:53-60) and
is how the worklist already leaves an operand alone; a `None` `MetaInstId` is
returned unchanged, as the `InstId` case does. +33 lines.

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/check/subst.cpp
+++ b/toolchain/check/subst.cpp
@@ -89,6 +89,16 @@

 }  // namespace

+// Returns whether an action's operand is substituted into: only an operand
+// that is itself a constant instruction is, such as the C++ template call
+// that an action formed while another generic's eval block was evaluated for
+// a symbolic specific. An instruction of a generic's body or eval block is
+// the operand the action refers to in each specific, and stays.
+static auto IsSubstitutedActionOperand(Context& context, SemIR::InstId inst_id)
+    -> bool {
+  return context.constant_values().GetConstantInstId(inst_id) == inst_id;
+}
+
 // Pushes the specified operand onto the worklist.
 static auto PushOperand(Context& context, Worklist& worklist,
                         SemIR::IdAndKind arg) -> void {
@@ -122,6 +132,20 @@
       push_block(inst_block_id);
       break;
     }
+    case CARBON_KIND(SemIR::MetaInstId inst_id): {
+      if (inst_id.has_value()) {
+        worklist.Push(inst_id,
+                      /*skip=*/!IsSubstitutedActionOperand(context, inst_id));
+      }
+      break;
+    }
+    case CARBON_KIND(SemIR::MetaInstBlockId inst_block_id): {
+      for (auto inst_id : context.inst_blocks().Get(inst_block_id)) {
+        worklist.Push(inst_id,
+                      /*skip=*/!IsSubstitutedActionOperand(context, inst_id));
+      }
+      break;
+    }
     case CARBON_KIND(SemIR::StructTypeFieldsId fields_id): {
       for (auto field : context.struct_type_fields().Get(fields_id)) {
         worklist.Push(field.type_inst_id);
@@ -223,6 +247,15 @@
     case CARBON_KIND(SemIR::InstBlockId inst_block_id): {
       return pop_block_id(inst_block_id).index;
     }
+    case CARBON_KIND(SemIR::MetaInstId inst_id): {
+      if (!inst_id.has_value()) {
+        return arg.value();
+      }
+      return worklist.Pop().index;
+    }
+    case CARBON_KIND(SemIR::MetaInstBlockId inst_block_id): {
+      return pop_block_id(inst_block_id).index;
+    }
     case CARBON_KIND(SemIR::StructTypeFieldsId old_fields_id): {
       auto old_fields = context.struct_type_fields().Get(old_fields_id);
       SemIR::CopyOnWriteStructTypeFieldsBlock new_fields(&context.sem_ir(),
```

<!-- google-doc-style-resume -->

### §2.4 toolchain/check/convert.cpp (C1, D-CT-8)

In `PerformAction(InitializeAction)` (:2993-3060, TP-1's D-TP-2/D-TP-3 code),
the storage is placed in the specific only when it is not the return slot or
the target type might be initialized in place; otherwise the target is
`Initializing` with no storage, which is what a non-dependent `return` of the
same type builds. Review points: `target_type_id` was computed in the
initializer of `ConversionTarget` and is hoisted, not changed; the
`InPlaceInitializing` kind now also requires storage. +16 / -4 lines.

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/check/convert.cpp
+++ b/toolchain/check/convert.cpp
@@ -3017,14 +3017,26 @@
     }
     storage_id = splice_block.result_id;
   }
+  auto target_type_id =
+      context.types().GetTypeIdForTypeInstId(target_bundle.target_type_inst_id);
+  // A `return` of a template-dependent type initializes the function's return
+  // slot (`InitializeExisting`), which a specific has only when the returned
+  // type is initialized in place; for any other type the initializer makes its
+  // own storage, as the same `return` does where the type is not dependent.
+  bool has_storage =
+      !context.insts().Is<SemIR::OutParam>(storage_id) ||
+      SemIR::InitRepr::ForType(context.sem_ir(), target_type_id)
+          .MightBeInPlace();
   auto specific_storage_id =
-      AddSpecificInstToPendingBlock(target_block, storage_id, specific_id);
+      has_storage
+          ? AddSpecificInstToPendingBlock(target_block, storage_id, specific_id)
+          : SemIR::InstId::None;
   ConversionTarget target = {
-      .kind = ConversionTarget::Kind(target_bundle.in_place.ToBool()
-                                         ? ConversionTarget::InPlaceInitializing
-                                         : ConversionTarget::Initializing),
-      .type_id = context.types().GetTypeIdForTypeInstId(
-          target_bundle.target_type_inst_id),
+      .kind = ConversionTarget::Kind(
+          target_bundle.in_place.ToBool() && has_storage
+              ? ConversionTarget::InPlaceInitializing
+              : ConversionTarget::Initializing),
+      .type_id = target_type_id,
       .storage_id = specific_storage_id,
       .storage_access_block = &target_block,
       .template_storage_args = result_ids};
```

<!-- google-doc-style-resume -->

### §2.5 toolchain/check/cpp/call.cpp (C1, D-CT-9)

`BuildTemplateId`'s variable-template branch (:317-324) marks a specialization
whose kind is still `TSK_Undeclared` as `TSK_ImplicitInstantiation` at the use's
location before importing it, which is what Sema's expression form of
`CheckVarTemplateId` does (clang/lib/Sema/SemaTemplate.cpp:4817-4837 in the
pinned LLVM source: `setTemplateSpecializationKind(TSK_ImplicitInstantiation,
...)` when the kind is unset, then `BuildDeclarationNameExpr`); Clang then
instantiates the definition when the reference is marked used. Review
points: an explicit specialization or instantiation already has a kind and is
untouched; `cast<clang::VarDecl>` holds
because `CheckVarTemplateId` returns a variable declaration. +14 / -5 lines.

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/check/cpp/call.cpp
+++ b/toolchain/check/cpp/call.cpp
@@ -317,11 +317,20 @@
     auto decl_result = context.clang_sema().CheckVarTemplateId(
         var_template_decl, /*TemplateLoc=*/clang::SourceLocation(), loc,
         arg_list, /*SetWrittenArgs=*/false);
-    return decl_result.isInvalid()
-               ? SemIR::ErrorInst::InstId
-               : ImportCppDecl(context, loc_id,
-                               SemIR::ClangDeclKey::ForNonFunctionDecl(
-                                   decl_result.get()));
+    if (decl_result.isInvalid()) {
+      return SemIR::ErrorInst::InstId;
+    }
+    // A specialization that nothing declared is implicitly instantiated, as
+    // Clang's own expression form of `CheckVarTemplateId` marks it before
+    // building a reference to it; otherwise the reference that the import
+    // makes never instantiates its definition.
+    auto* var_decl = cast<clang::VarDecl>(decl_result.get());
+    if (!var_decl->getTemplateSpecializationKind()) {
+      var_decl->setTemplateSpecializationKind(
+          clang::TSK_ImplicitInstantiation, loc);
+    }
+    return ImportCppDecl(context, loc_id,
+                         SemIR::ClangDeclKey::ForNonFunctionDecl(var_decl));
   }

   if (auto* concept_decl = dyn_cast<clang::ConceptDecl>(template_decl)) {
```

<!-- google-doc-style-resume -->

### §2.6 toolchain/check/cpp/overload_resolution.cpp (C1, D-CT-10)

`IsMoveEquivalentToCopy` (:157-190) completes a record that has external
lexical storage and no definition through the AST's external source, the
`CarbonExternalASTSource::CompleteType` that export.cpp:173 and :318 call, and
returns false for a record that is still incomplete (the conservative answer:
pass by `var`). Review points: only an exported Carbon class has external
lexical storage (export.cpp:94, :215); C++ classes are complete or not by C++'s
rules and reach the unchanged code. +11 lines.

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/check/cpp/overload_resolution.cpp
+++ b/toolchain/check/cpp/overload_resolution.cpp
@@ -161,6 +161,17 @@
   if (!record_decl) {
     return true;
   }
+  // An exported Carbon class is defined on demand by the external AST source,
+  // and an xvalue argument of its type completes nothing in overload
+  // resolution, so complete it before reading its special members.
+  if (!record_decl->hasDefinition() &&
+      record_decl->hasExternalLexicalStorage()) {
+    record_decl->getASTContext().getExternalSource()->CompleteType(
+        record_decl);
+  }
+  if (!record_decl->hasDefinition()) {
+    return false;
+  }

   // - The move constructor is defaulted and deleted or non-existent, in
   //   which case overload resolution for a move will call the copy
```

<!-- google-doc-style-resume -->

### §2.7 toolchain/check/call.cpp (C2, D-CT-3)

`PerformCall` (:899-927) defers, after `IsCallPerformable` and before
`PerformCallHelper`, a call to a `CalleeCppOverloadSet` any of whose arguments
has `Checked` dependence: `DeferCppCallOnSymbolicArgs` builds the same
`CallAction` that `PerformCallToNonFunction` (:741-768) builds for a C++
template name, wrapping a symbolic facet-typed argument (`type` is the empty
`FacetType`, typed_insts.h:870) in `TemplateInst`. Review points: a value
argument `x: T` is not wrapped (v2 wrapped values and stopped at
type_completion.cpp:348); a template-dependent argument never reaches this
code, because `IsCallPerformable` already returned false for it; `is_desugared`
is carried, as `PerformCallHelper` uses it. +54 lines.

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/check/call.cpp
+++ b/toolchain/check/call.cpp
@@ -896,10 +896,64 @@
   }
 }

+// Returns whether a call argument is, or has, a symbolic type that is not
+// template-dependent, such as a checked generic's `T` or a value `x: T`.
+static auto IsCheckedSymbolicCppArg(Context& context, SemIR::InstId arg_id)
+    -> bool {
+  return OperandDependence(context, arg_id) ==
+         SemIR::ConstantDependence::Checked;
+}
+
+// A call to an imported C++ function whose argument is a value of a symbolic
+// type that is not template-dependent, such as a checked generic's `x: T`, or
+// is such a type, as the `T` of `Cpp.Twice(T, x)`, cannot be resolved by Clang
+// until the type is known. As for a C++ template name applied to a symbolic
+// argument (`PerformCallToNonFunction`), the call is deferred as a `CallAction`
+// that each specific performs once its arguments' types are concrete
+// (`ActionIsPerformable`); a type argument is wrapped in a `TemplateInst`, as
+// there. Returns `None` if the call is not such a call.
+static auto DeferCppCallOnSymbolicArgs(Context& context, SemIR::LocId loc_id,
+                                       SemIR::InstId callee_id,
+                                       llvm::ArrayRef<SemIR::InstId> arg_ids,
+                                       bool is_desugared) -> SemIR::InstId {
+  if (llvm::none_of(arg_ids,
+                    [&](SemIR::InstId arg_id) {
+                      return IsCheckedSymbolicCppArg(context, arg_id);
+                    }) ||
+      !std::holds_alternative<SemIR::CalleeCppOverloadSet>(
+          GetCallee(context.sem_ir(), callee_id))) {
+    return SemIR::InstId::None;
+  }
+  llvm::SmallVector<SemIR::InstId> inst_ids = {callee_id};
+  for (auto arg_id : arg_ids) {
+    auto arg = context.insts().Get(arg_id);
+    if (IsCheckedSymbolicCppArg(context, arg_id) &&
+        context.constant_values().Get(arg_id).is_symbolic() &&
+        context.types().Is<SemIR::FacetType>(arg.type_id())) {
+      inst_ids.push_back(AddInst(
+          context, SemIR::LocId(arg_id),
+          SemIR::TemplateInst{.type_id = arg.type_id(), .inst_id = arg_id}));
+    } else {
+      inst_ids.push_back(arg_id);
+    }
+  }
+  return AddDependentActionSplice(
+      context, loc_id,
+      SemIR::CallAction{.type_id = SemIR::InstType::TypeId,
+                        .inst_block_id = context.inst_blocks().Add(inst_ids),
+                        .is_desugared = SemIR::BoolValue::From(is_desugared)},
+      SemIR::TypeInstId::None);
+}
+
 auto PerformCall(Context& context, SemIR::LocId loc_id, SemIR::InstId callee_id,
                  llvm::ArrayRef<SemIR::InstId> arg_ids, bool is_desugared)
     -> SemIR::InstId {
   if (IsCallPerformable(context, callee_id, arg_ids)) {
+    if (auto deferred_id = DeferCppCallOnSymbolicArgs(
+            context, loc_id, callee_id, arg_ids, is_desugared);
+        deferred_id.has_value()) {
+      return deferred_id;
+    }
     return PerformCallHelper(context, loc_id, callee_id, arg_ids, is_desugared);
   }

```

<!-- google-doc-style-resume -->

### §2.8 Golden sources (AUTOUPDATE, no CHECK lines)

Appendix A holds every new or changed golden source as committed, with no
CHECK lines: autoupdate writes them (R16(a)). C1 adds A.1's and A.2's C1 splits
and A.3's and A.4's header changes; C2 adds the C2 splits (§4 names each
split's commit). The fills F1 and F2 are autoupdate runs to a fixpoint and
nothing else.

### §2.9 Conformance programs

Appendix B holds the nine programs and the oracle as committed. Commit P also
regenerates fork/conformance/README.md's program table with
`python3 fork/conformance/runner.py --update-readme-table` (the two rows lose
SKIP, seven rows are added; Appendix C.9) and runs `--self-test`.

### §2.10 Records

Appendix C holds the records texts with `<...>` placeholders for what the
discharge measures: the ledger (W-043's discharge, W-268's discharge, W-300 to
W-306), gap rows 56 and 42, the decision-log entry "CT-1", the ORCHESTRATION
paragraph and branch row, and the land-time texts (the design page paragraph
and fixture, the merged program header, W-127's sentence).

### §2.11 Land-time integration (commits M, L-F, L and the land-time records commit)

After PR 62 merges: M merges the trunk that holds PR 51 to PR 62 into this
branch, records only, with these resolutions and no new code: the two programs
by C-1's rule (PR 51's header with Appendix C.6's paragraph appended, CT-1's
body); the ledger, gap rows and decision log keep both sides' entries, CT-1's
after the others. L-F refills what M changes, predicted: PR 51's
dependent_var_full_prelude.carbon's split `fail_todo_unformed_dependent_var`
is renamed `unformed_dependent_var` and refilled (C-2), and any golden of a
held PR that the merged toolchain changes is refilled (the composition mirrors
of §8 predict the set). L edits docs/design/interoperability/README.md's
"Using C++ templates" over PR 58's text (Appendix C.1) and adds a design-docs
fixture for the new sentence (Appendix C.1), checked by PR 58's
fork/designdocs/check_samples.py with `--toolchain`. The land-time records
commit rewrites rows 56 and 42 at PR 58's line numbers (62 and 48), merges
DD-1's W-043 notes into the discharge text, adds W-127's sentence, and
re-runs the id re-scan.

## §3 Commits (one PR, "CT-1: C++ templates on symbolic Carbon type arguments", R29(b))

Each commit message ends with the two trailers the conventions name; author
jmann345, committer Claude; explicit paths only (R20).

1.  **P0** "CT-1 plan (rev 1): C++ templates on symbolic Carbon type
    arguments, instantiated per specific" (this file). Plan reviews fold into
    rev 2 and later in their own commits.
2.  **C1** "CT-1 (1): C++ specializations of symbolic arguments are formed and
    used for each specific": impl_lookup.cpp, action.cpp, subst.cpp,
    convert.cpp, cpp/call.cpp, cpp/overload_resolution.cpp (§2.1 to §2.6, the
    c1b state); the C1 splits of A.1 and A.2; A.3's and A.4's header changes
    and A.3's new split.
3.  **F1** "CT-1 (1) fill": autoupdate to a fixpoint. Predicted exactly: the
    four refills of §0.7 and the C1 subsets of A.1 (663 lines, nine splits)
    and A.2 (946 lines, four splits), as measured on c1b; the gate passes
    all 1959 goldens.
4.  **C2** "CT-1 (2): C++ calls with a checked generic's symbolic arguments are
    deferred to each specific": call.cpp (§2.7); the C2 splits of A.1 and
    A.2.
5.  **F2** "CT-1 (2) fill": autoupdate; predicted: A.1 to 911 lines and A.2 to
    1339, nothing else (v11's gate equals c1b's); the gate 1959 of 1959.
6.  **P** "CT-1 (3): conformance programs": the two un-SKIPs, seven programs,
    the oracle, the README table; predicted 147 / 0 / 20 over 167.
7.  **Implementation reviews A and B** (R29(c)), on the head after P; not
    commits.
8.  **Fix commits**, at most three, each with its fill. The shrink line: if a
    review finding needs a fourth fix commit, the slice shrinks instead,
    dropping the form at issue to OUT with a residue in W-307..W-319 and its
    golden split renamed `fail_todo_`, never by a guard that hides an IN form
    (R17).
9.  **Held-state measurements** (not commits): §8's mutants, the composition
    mirrors over PR 57, PR 59, PR 60 and PR 62 with the predicted red sets,
    clang-tidy, the id re-scan.
10. **R** "CT-1 records: gap rows 56 and 42": Appendix C.4.
11. **D** "CT-1 discharge": the ledger (Appendix C.2, C.3), the decision log
    (C.7), fork/ORCHESTRATION.md (C.8), the re-scan's result; last on the
    branch.
12. **Land-time** (after PR 62): M, L-F, L and the land-time records commit
    (§2.11), each its own commit. There is no docs commit on the branch: the
    design page's "Using C++ templates" section exists only on PR 58, so its
    edit is L (D-CT-14).

## §4 Testdata matrix (autoupdate fills; the fill must reproduce these lines)

check/testdata/interop/cpp/template/symbolic_arg.carbon (A.1), under the full
prelude:

| Split | Commit | Pins | Fill (measured on v11; on c1b for C1 splits) |
| --- | --- | --- | --- |
| uninitialized_var | C1 | R1, D-CT-5: `var b: Cpp.Box(T);` in a checked generic | no diagnostic; the dump of `F` holds the `call_action`, `splice_inst` and `initialize_action` over the spliced type, `[template]` |
| nested_and_generic_class_args | C1 | D-CT-11: `Cpp.Pair(Cpp.Box(T))`, `Cpp.Box(List(T))`, `Cpp.Apply(Cpp.Box, T)` | no diagnostic |
| function_template_call | C2 | R7, D-CT-3: `Cpp.Twice(v)` | no diagnostic; the dump of `F` holds the deferred `call_action` over `Twice`'s overload set; the specific `F(i32)` calls `Twice__carbon_thunk` |
| explicit_type_argument | C2 | D-CT-3: `Cpp.Twice(T, v)`, `Cpp.SizeOfFn(T)`, the variable template `Cpp.Plain(T)` | no diagnostic |
| template_called_from_checked_generic | C1 | R2, D-CT-6: a template with `Cpp.Box(T)` and one with `Cpp.Twice(v)`, each called from a checked generic with its symbolic `U` | no diagnostic (TP-1: STOP generic_region_stack.h:98) |
| generic_class_field | C2 | R3, D-CT-7: `Holder(T)` with a `Cpp.Box(T)` field, read in `Get` and made in `Make` (which calls `Cpp.MakeBox(v)`) | no diagnostic |
| member_missing_uncalled | C1 | D-CT-2: an uninstantiated body is not diagnosed | no diagnostic |
| fail_member_missing_on_instantiation | C1 | D-CT-2 | ``unable to monomorphize specific `F(i32)` [ResolvingSpecificHere]`` at the call, ``note: member name `nope` not found in `Cpp.Box` [MemberNameNotFoundInInstScope]`` at `b.nope` |
| fail_cpp_error_on_instantiation | C2 | D-CT-2, D-CT-10 | ``./box.h:8:46: error: invalid operands to binary expression ('Carbon::Point' and 'Carbon::Point') [CppInteropParseError]`` and ``note: in instantiation of function template specialization 'Twice<Carbon::Point>' requested here [CppInteropParseNote]``, each under `in file included here [InCppInclude]` |
| fail_copy_symbolic_value_in_definition | C2 | D-CT-2's break condition | ``cannot copy value of type `T` [CopyOfUncopyableType]`` with its `Core.Copy` note and ``cannot access member of interface `Core.Destroy` in type `T` that does not implement that interface [MissingImplInMemberAccess]``, where `F` is defined |
| fail_todo_struct_arg | C1 | W-300, W-306 | ``unable to monomorphize specific `F({.a: i32})` `` with ``fail_todo_struct_arg.carbon: note: semantics TODO: `unsupported type used as template argument` [SemanticsTodo]`` (no line) |
| fail_template_template_carbon_generic | C1 | W-301 | ``error: template argument for template template parameter must be a class template or type alias template [CppInteropParseError]`` at `List` |
| fail_todo_deduce_through_specialization | C1 | W-303 | ``cannot deduce value for generic parameter `T` [DeductionIncomplete]`` with ``note: while deducing parameters of generic declared here [DeductionGenericHere]`` |
| fail_todo_member_through_constraint | C1 | W-305; `Direct` and `Compound` compile | ``unable to monomorphize specific `Simple(S as Show)` `` with ``note: member name `Get` not found in `S` [MemberNameNotFoundInInstScope]`` |

lower/testdata/interop/cpp/template_symbolic_arg.carbon (A.2), under the full
prelude:

| Split | Commit | Pins | Fill (measured) |
| --- | --- | --- | --- |
| two_specifics | C1 | D-CT-1: `Loud<int>` and `Loud<Carbon::Point>` | both specializations' constructors' thunks and destructors (`@_ZN4LoudIiED2Ev`, `@_ZN4LoudIN6Carbon5PointEED2Ev`), and the two specifics of `Keep`: `void @_CKeep.Main.<hash>(ptr sret({ i32 }) %return, ptr %v)` and `i32 @_CKeep.Main.<hash>(i32 %v)` |
| narrow_return | C2 | R4, D-CT-8 | `i16 @_CChecked.Main.<hash>(i16 %v)` and `i16 @_CTemplate.Main.<hash>(i16 %v)`, no return slot, calling `@_Z5TwiceIsET_S0_.carbon_thunk._` |
| class_return | C2 | D-CT-8's in-place side | `void @_CMake.Main.<hash>(ptr sret([4 x i8]) %return, i32 %v)` |
| generic_class_field | C1 | R3, D-CT-7 | `i32 @_CGet.Main.<hash>(ptr %h)` |
| var_template | C1 | R5, D-CT-9 | `@_Z5PlainIiE = linkonce_odr dso_local global i32 5` and `@_Z5PlainIlE = linkonce_odr dso_local global i32 9` |
| exported_class_argument | C1 | R6, D-CT-10 | `@_Z2IdIN6Carbon5PointEET_S2_` and its thunk (TP-1: the clang assertion) |

Refills (§0.7): check/interop/cpp/template/generic_call.carbon (F1),
non_type_param.carbon (F1), var_template.carbon (C1's source change, F1's fill:
A.3's new split `fail_non_inline_static_member_template` with
``./non_inline_static.h:5:33: error: non-const static data member must be
initialized out of line [CppInteropParseError]`` and ``note: in instantiation
of static data member 'Wrap::var<A>' requested here [CppInteropParseNote]``),
and
lower/interop/cpp/globals.carbon (C1's source change, F1's fill). No other
golden changes; the gate after F2 is 1959 of 1959.

## §5 Conformance delta (from 138 / 0 / 22 over 160)

| State | PASS | FAIL | SKIP | Programs | Bullets PASS |
| --- | --- | --- | --- | --- | --- |
| TP-1 (this branch's base) | 138 | 0 | 22 | 160 | 48 of 56 |
| after P (measured on v11) | 147 | 0 | 20 | 167 | 48 of 56 |
| trunk, the floor of record | 128 | 0 | 22 | 150 | n/a |

The +9 PASS are the two un-SKIPped programs and the seven new ones; no program
changes status otherwise (the runner's scoreboards on TP-1 and v11 differ only
in those nine rows). Relative to trunk the tree is +19 PASS, -2 SKIP and +17
programs, TP-1's ten programs included.

## §6 Churn and collisions

Seven toolchain files, 163 lines added and 11 removed; two new goldens (2250
lines filled, 433 of them source); four refills (+274/-191 CHECK and source
lines); nine programs and an oracle (483 lines); the records. No generated
file, X-macro or diagnostic kind changes. Collisions are §0.9's: textual
offsets with PR 57, PR 59, PR 60 (TP-1's own two convert.cpp hunks, resolved by
TP-1's M) and PR 62; the content rules C-1 (PR 51's programs), C-2 (PR 51's
split and TP-1's F6) and C-3 (PR 58's page and records).

## §7 Risks and rejected alternatives (falsifiable)

### §7.1 Risks

1.  D-CT-5 defers more impl lookups in checked generics than D-TP-12 did: any
    query whose self or interface arguments reach a `TemplateInst`. Measured:
    the gate changes only generic_call.carbon among such files, and
    facet/period_self.carbon (D-TP-12's other falsifier) is unchanged.
    Falsified by a golden outside the four of §0.7 changing in F1.
2.  D-CT-2 moves errors on a C++ specialization in a checked generic from the
    definition to the instantiation. A library author no longer sees them
    until a caller instantiates; this is the template behavior leads issue
    2153 chose, and C++ gives the same. Falsified by an operation on a C++
    specialization that the definition could check and does not (none is
    known: Clang has no type to check against).
3.  D-CT-7 substitutes into constant action operands; an action that is a
    constant and also refers to a body instruction would be rewritten. v10's
    restriction kept every golden; falsified by v9's class of change
    reappearing in F1 or F2.
4.  D-CT-9 makes ill-formed variable template definitions errors on use. Two
    goldens had such C++ (A.3, A.4); user code with the same C++ is rejected
    by clang++ too. Falsified by a well-formed variable template that now
    fails.
5.  D-CT-3 builds `CallAction`s for every C++ call in a checked generic with a
    symbolic argument, which increases eval-block size. Measured cost: the new
    check golden's 14 splits run in 386 ms under the full prelude; no golden's
    runtime moved by more than noise in the gate (1957 tests, 4 threads: 27.7 s
    wall and 103.9 s across threads on TP-1, 27.2 s and 104.9 s on v11).
6.  The C-2 finding means TP-1's land-time F6, as written, would leave a
    `unformed_dependent_var` split that still reports an error, a red golden
    at TP-1's land. Hand-off note H-1 routes it; CT-1's L-F takes the rename.

### §7.2 Rejected alternatives

1.  **Instantiate eagerly on every possible argument** (form `Box<X>` for each
    type the program might pass): unbounded, and wrong for a library generic
    whose callers are elsewhere. Rejected; the specific is the only place the
    argument is known.
2.  **Treat C++ templates as Carbon templates only** (require the user to write
    `template T` to use a C++ template on `T`): contradicts upstream, whose
    `TemplateInst` wrapping exists so that a checked generic's symbolic
    argument is "treated as templates", and leads issue 2153's decision that
    checked generics may call templates. Rejected by V-3.
3.  **Require `template T` for all uses** (diagnose a C++ template use in a
    checked generic): the same contradiction, and a regression: the
    `c_param_field`, `c_param_method`, `c_param_unbox`, `c_param_unbox_int`,
    `c_param_copy`, `c_static_member`, `c_type_alias_member`, `c_destroy_copy`
    probes run on TP-1, trunk and the nightly today (21, 22, 23, 24, 10, 37, 38,
    25). Rejected.
4.  **Diagnose member access on a C++ specialization where a checked generic is
    defined** (only constraint-visible members): regresses the same probes
    (`b.value` on a `Cpp.Box(T)` parameter, 21) and has nothing to check
    against. Rejected.
5.  **A new instruction kind for a "C++ template specialization of symbolic
    arguments"**: duplicates upstream's `CallAction`/`TemplateInst` pair and
    diverges from upstream's SemIR. Rejected by D-CT-1.
6.  **Wrap every symbolic value argument in `TemplateInst`** (v2): stops at
    type_completion.cpp:348 on the first probe; a value of type `T` is not a
    template-dependent value, its type is what Clang needs. Rejected.
7.  **Substitute into every action operand** (v9): 25 goldens change because
    body references are rewritten. Rejected for v10's rule.
8.  **Instantiate a variable template's definition from the import** (v4 to
    v6, three placements): ineffective while the specialization kind is
    `TSK_Undeclared`; the kind is the root cause. Rejected for D-CT-9.
9.  **Complete every exported class when it is mapped** (call
    `ExportAndCompleteClassToCpp` in `MapToCppType`): not measured; it moves
    completion for every mapped class, including one only named through a
    pointer, where the query site completes only what is read. Rejected for
    D-CT-10; its break condition would reopen it.
10. **Keep the two programs' PR 51 form (constructor initializer)**: it passes
    on TP-1 already (§0.9 C-1) and so pins nothing CT-1 adds; the
    uninitialized form is the programs' original claim. Rejected.
11. **A `semantics TODO` for the OUT kinds at the definition** (diagnose a
    struct type argument where the generic is defined): the argument is a
    symbolic `T` there, and which `T` is unmappable is known only at the
    specific. Rejected; W-300 keeps upstream's TODO at the specific.

## §8 Verification and discharge

Run by the implementer at each fill and at the discharge, and recorded in the
plan's landed notes with numbers:

1.  **Build.** No bazel in this environment: the container arbiter's
    build.sh and install.sh (fork/tools/carbonbuild, or relinking over the
    TP-1 build's objects as this plan's prototypes did; the TP-1 build
    directory is read-only, so a relink goes to /dev/shm and is deleted after
    use). A full build.sh/install.sh of the branch at C2 and at P.
2.  **Autoupdate fixpoint.** After each of C1 and C2 (and each fix commit):
    autoupdate twice; the second run changes nothing; the fill commit is
    exactly the first run's output plus nothing.
3.  **Gate.** file_test over every golden: 1959 of 1959 after F1 and after F2.
4.  **Conformance.** runner.py over the programs: 147 / 0 / 20 over 167 after
    P, 48 of 56 bullets; the differential program's oracle matches.
5.  **Mutants.** Each reverts one hunk and must turn a pin red (predicted
    killers, from the c1, c1b, v10 and TP-1 measurements):

    | Mutant | Reverts | Killed by (predicted) |
    | --- | --- | --- |
    | M1 | D-CT-5's `TemplateInst` clause | A.1 uninitialized_var (E-DU), the four E-DU-class programs |
    | M2 | D-CT-5's `MetaInstId`/`MetaInstBlockId` walk | generic_call.carbon's refill, A.1 nested_and_generic_class_args |
    | M3 | D-CT-6 | A.1 template_called_from_checked_generic (STOP generic_region_stack.h:98, measured on c1) |
    | M4 | D-CT-7's `PushOperand` cases | A.1 and A.2 generic_class_field (STOP custom_witness.cpp:487 or handle_expr_category.cpp:20) |
    | M5 | D-CT-7's restriction (substitute every operand) | 25 goldens (v9, measured) |
    | M6 | D-CT-8 | A.2 narrow_return (STOP lower/handle_call.cpp:984, measured on v10) |
    | M7 | D-CT-8's `has_storage` in the kind only | A.2 class_return or narrow_return |
    | M8 | D-CT-9 | A.2 var_template (`external global`), globals.carbon, cpp_var_template_runtime (L-UNDEF) |
    | M9 | D-CT-10's completion | A.2 exported_class_argument (the clang assertion, measured on TP-1) |
    | M10 | D-CT-10's incomplete-record `return false` only | none predicted (defensive: no measured record stays incomplete after completion); recorded as defensive if it survives |
    | M11 | D-CT-3 | A.1 function_template_call (E-ARG, measured on c1b) |
    | M12 | D-CT-3's `TemplateInst` wrapping of a type argument | A.1 explicit_type_argument |

6.  **clang-tidy** on the seven files (the arbiter's config); no new findings.
7.  **prek** on every changed path, to a fixpoint, with R31's heading and
    list-item counts before and after each markdown edit:

    <!-- google-doc-style-ignore -->

    ```sh
    SKIP=fix-cc-deps,check-build-graph,check-bazel-mod-deps,forbid-llvm-googletest \
      uvx prek run --files <paths>
    ```

    <!-- google-doc-style-resume -->
8.  **runner.py --self-test** after P (the README table regenerated).
9.  **Composition mirrors.** The branch merged (scratch only) with each held PR
    that touches CT-1's files (PR 57, PR 59, PR 60, PR 62) and with PR 51 for
    C-1 and C-2; each built and gated with the predicted red set (the held PR's
    own pins only), and the C-2 rename measured on the PR 51 mirror.
10. **Id re-scan** (§0.11) before D and at land time.
11. **Not run, and why** (recorded in the PR's first comment): the hosted
    gate and conformance (GitHub Actions is disabled on the fork); bazel
    targets (bazel is not installed, and is not to be). The arbiter's LLVM
    is built with assertions (R6's stop is a clang assertion), so every
    measurement here already ran under them.

### §8.1 What this plan measured and what it did not

Measured for rev 1: the 174 probes on four toolchains; v11's gate (1953 of
1957, the four refills autoupdated to a fixpoint on a mirror); c1's and c1b's
gates (the same four); the two new goldens filled to a fixpoint and passing on
v11, their C1 subset identical on c1b, and TP-1 stopping on them; conformance
on TP-1 and v11; the collision dry-runs; the id re-scan; the upstream log.
Not measured: a full build.sh/install.sh of a branch state (relinks of the
changed objects over TP-1's build sufficed, as no X-macro or generated file
changes); the mutants M1 to M12 individually (the c1, c1b, v9 and v10 states
measure M3, M5, M6 and M11's classes); clang-tidy; prek on anything but this
file; runner.py --self-test with the new README table; the composition
mirrors (only patch dry-runs); the C-2 rename on PR 51's own golden (its
split could not be run here: it is not in TP-1's manifest, and the probe of
its shape stands in); hosted CI.

## Hand-off notes for the implementer

-   **H-1 (for the orchestrator, PR 61).** TP-1's plan predicts that PR 51's
    split `fail_todo_unformed_dependent_var` succeeds with TP-1 and renames it
    in TP-1's land-time F6; on TP-1's toolchain the split's shape is still
    rejected (w127/w127_unformed, E-DU). TP-1's F6 should drop that rename, and
    its W-127 discharge text should not claim the checked shape; CT-1's L-F
    takes the rename (§0.9 C-2). CT-1 cannot edit PR 61.
-   **H-2.** The diffs of §2 are measured; apply them verbatim. If a reviewer
    asks for a different structure, measure it against the same gate before
    changing the plan.
-   **H-3.** New goldens need a file_test whose manifest lists them; with
    bazel absent, relink file_test over a copy of
    gen/toolchain/testing/file_test_autogen_manifest.cpp with the two paths
    added in sorted order, as §0.7 did.
-   **H-4.** The two programs' bodies differ from PR 51's; do not take PR 51's
    text on this branch (C-1's rule applies at M).
-   **H-5.** Keep the probe scripts and matrices out of the repository: they
    are scratch evidence; the plan's tables are the record.
-   **H-6.** Never hand-write a CHECK line; never edit a golden's CHECK lines;
    the two header fixes (A.3, A.4) are source edits that autoupdate then
    fills.

## Appendix A: golden sources

Every new or changed golden source, without CHECK lines (R16(a)). A.1 and A.2
are new files; their C2 splits (§4) are added by commit C2 and the rest by C1.

### A.1 toolchain/check/testdata/interop/cpp/template/symbolic_arg.carbon

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/template/symbolic_arg.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/template/symbolic_arg.carbon

// C++ templates used with symbolic Carbon arguments in checked generics and
// templates: each specialization and each C++ call is formed for each
// specific. The full prelude is used so that an uninitialized `var` of a
// specialization resolves the real `Core.DefaultOrUnformed` impls.

// --- box.h

template<typename T> struct Box {
  T value;
  T Get() const { return value; }
};
template<typename T> struct Pair { T first; T second; };
template<typename T> Box<T> MakeBox(T v) { Box<T> b; b.value = v; return b; }
template<typename T> T Twice(T x) { return x + x; }
template<typename T> int SizeOfFn() { return sizeof(T); }
template<typename T> int Plain = sizeof(T) + 1;
template<template<typename> class F, typename T> struct Apply { F<T> f; };

// --- uninitialized_var.carbon

library "[[@TEST_NAME]]";

import Cpp library "box.h";

//@dump-sem-ir-begin
fn F[T: type](v: T) -> T {
  var b: Cpp.Box(T);
  b.value = v;
  return b.value;
}
//@dump-sem-ir-end

fn G() -> i32 { return F(7 as i32); }

// --- nested_and_generic_class_args.carbon

library "[[@TEST_NAME]]";

import Cpp library "box.h";

class List(T: type) {
  var head: T;
}

fn Nested[T: type](v: T) -> T {
  var p: Cpp.Pair(Cpp.Box(T));
  p.first.value = v;
  return p.first.value;
}

fn OfGenericClass[T: type](v: T) -> T {
  var b: Cpp.Box(List(T));
  b.value = {.head = v};
  return b.value.head;
}

fn TemplateTemplate[T: type](unused v: T) {
  var unused a: Cpp.Apply(Cpp.Box, T);
}

fn G() -> i32 {
  TemplateTemplate(1 as i32);
  return Nested(14 as i32) + OfGenericClass(15 as i32);
}

// --- function_template_call.carbon

library "[[@TEST_NAME]]";

import Cpp library "box.h";

//@dump-sem-ir-begin
fn F[T: type](v: T) -> T {
  return Cpp.Twice(v);
}
//@dump-sem-ir-end

fn G() -> i32 { return F(21 as i32); }

// --- explicit_type_argument.carbon

library "[[@TEST_NAME]]";

import Cpp library "box.h";

fn Explicit[T: type](v: T) -> T {
  return Cpp.Twice(T, v);
}

fn SizeOfType[T: type](unused v: T) -> i32 {
  return Cpp.SizeOfFn(T) + Cpp.Plain(T);
}

fn G() -> i32 { return Explicit(21 as i32) + SizeOfType(1 as i64); }

// --- template_called_from_checked_generic.carbon

library "[[@TEST_NAME]]";

import Cpp library "box.h";

fn Store[template T: type](v: T) -> T {
  var b: Cpp.Box(T);
  b.value = v;
  return b.value;
}

fn Double[template T: type](v: T) -> T {
  return Cpp.Twice(v);
}

fn Caller[U: type](u: U) -> U {
  return Store(u);
}

fn DoubleCaller[U: type](u: U) -> U {
  return Double(u);
}

fn G() -> i32 { return Caller(31 as i32) + DoubleCaller(15 as i32); }

// --- generic_class_field.carbon

library "[[@TEST_NAME]]";

import Cpp library "box.h";

class Holder(T: type) {
  var b: Cpp.Box(T);
}

fn Get[T: type](h: Holder(T)) -> T {
  return h.b.value;
}

fn Make[T: type](v: T) -> T {
  var h: Holder(T) = {.b = Cpp.MakeBox(v)};
  return h.b.value;
}

fn G() -> i32 {
  var h: Holder(i32) = {.b = Cpp.MakeBox(60 as i32)};
  return Get(h) + Make(54 as i32);
}

// --- member_missing_uncalled.carbon

library "[[@TEST_NAME]]";

import Cpp library "box.h";

// Never instantiated, so never diagnosed, as a template's body is not.
fn F[T: type](v: T) -> T {
  var b: Cpp.Box(T);
  b.value = v;
  return b.nope;
}

// --- fail_member_missing_on_instantiation.carbon

library "[[@TEST_NAME]]";

import Cpp library "box.h";

fn F[T: type](v: T) -> T {
  var b: Cpp.Box(T);
  b.value = v;
  return b.nope;
}

fn G() -> i32 { return F(1 as i32); }

// --- fail_cpp_error_on_instantiation.carbon

library "[[@TEST_NAME]]";

import Cpp library "box.h";

class Point {
  var x: i32;
}

fn F[T: type](v: T) -> T {
  return Cpp.Twice(v);
}

fn G() -> i32 { return F({.x = 1} as Point).x; }

// --- fail_copy_symbolic_value_in_definition.carbon

library "[[@TEST_NAME]]";

import Cpp library "box.h";

// The checked generic's own rules still apply where it is defined: `T` has no
// `Core.Copy` or `Core.Destroy`, whatever initializes the `var`.
fn F[T: type](v: T) -> T {
  var r: T = Cpp.Twice(v);
  return r;
}

// --- fail_todo_struct_arg.carbon

library "[[@TEST_NAME]]";

import Cpp library "box.h";

fn F[T: type](v: T) -> T {
  var b: Cpp.Box(T);
  b.value = v;
  return b.value;
}

fn G() -> i32 {
  let s: {.a: i32} = {.a = 46};
  return F(s).a;
}

// --- fail_template_template_carbon_generic.carbon

library "[[@TEST_NAME]]";

import Cpp library "box.h";

class List(T: type) {
  var head: T;
}

fn G() {
  var unused a: Cpp.Apply(List, i32);
}

// --- fail_todo_deduce_through_specialization.carbon

library "[[@TEST_NAME]]";

import Cpp library "box.h";

fn Get[T: type](b: Cpp.Box(T)) -> T {
  return b.value;
}

fn G() -> i32 { return Get(Cpp.MakeBox(50 as i32)); }

// --- fail_todo_member_through_constraint.carbon

library "[[@TEST_NAME]]";

import Cpp library "box.h";

interface Show {
  fn Get(self) -> i32;
}

class S {
  var v: i32;
  impl as Show {
    fn Get(self) -> i32 { return self.v; }
  }
  impl as Core.Copy {
    fn Op(self) -> Self { return {.v = self.v}; }
  }
}

fn Direct[T: Show](v: T) -> i32 {
  return v.Get();
}

fn Compound[T: Show](v: T) -> i32 {
  var b: Cpp.Box(T);
  b.value = v;
  return b.value.(Show.Get)();
}

fn Simple[T: Show](v: T) -> i32 {
  var b: Cpp.Box(T);
  b.value = v;
  return b.value.Get();
}

fn G() -> i32 {
  let s: S = {.v = 49};
  return Direct(s) + Compound(s) + Simple(s);
}
```

<!-- google-doc-style-resume -->

### A.2 toolchain/lower/testdata/interop/cpp/template_symbolic_arg.carbon

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/interop/cpp/template_symbolic_arg.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/interop/cpp/template_symbolic_arg.carbon

// C++ templates used with symbolic Carbon arguments, lowered for each
// specific: two specifics form two specializations, a narrow scalar returned
// through a template-dependent `return` has no return slot, and a class
// returned that way keeps its in-place storage.

// --- templates.h

inline int destroyed = 0;
template<typename T> struct Loud {
  T value;
  ~Loud() { ++destroyed; }
};
template<typename T> struct Box {
  T value;
};
template<typename T> Box<T> MakeBox(T v) { Box<T> b; b.value = v; return b; }
template<typename T> T Twice(T x) { return x + x; }
template<typename T> T Id(T x) { return x; }
template<typename T> int Plain = sizeof(T) + 1;

// --- two_specifics.carbon

library "[[@TEST_NAME]]";

import Cpp library "templates.h";

class Point {
  var x: i32;
  impl as Core.Copy {
    fn Op(self) -> Self { return {.x = self.x}; }
  }
}

fn Keep[T: type](v: T) -> T {
  var l: Cpp.Loud(T);
  l.value = v;
  return l.value;
}

fn Use() -> i32 {
  let p: Point = Keep({.x = 2} as Point);
  return Keep(5 as i32) + p.x;
}

// --- narrow_return.carbon

library "[[@TEST_NAME]]";

import Cpp library "templates.h";

fn Checked[T: type](v: T) -> T {
  return Cpp.Twice(v);
}

fn Template[template T: type](v: T) -> T {
  return Cpp.Twice(v);
}

fn Use() -> i16 {
  return Checked(7 as i16) + Template(8 as i16);
}

// --- class_return.carbon

library "[[@TEST_NAME]]";

import Cpp library "templates.h";

fn Make[T: type](v: T) -> Cpp.Box(T) {
  return Cpp.MakeBox(v);
}

fn Use() -> i32 {
  return Make(11 as i32).value;
}

// --- generic_class_field.carbon

library "[[@TEST_NAME]]";

import Cpp library "templates.h";

class Holder(T: type) {
  var b: Cpp.Box(T);
}

fn Get[T: type](h: Holder(T)) -> T {
  return h.b.value;
}

fn Use() -> i32 {
  var h: Holder(i32) = {.b = Cpp.MakeBox(60 as i32)};
  return Get(h);
}

// --- var_template.carbon

library "[[@TEST_NAME]]";

import Cpp library "templates.h";

fn PlainOf[T: type](unused v: T) -> i32 {
  return Cpp.Plain(T);
}

fn Use() -> i32 {
  return Cpp.Plain(i32) + PlainOf(1 as i64);
}

// --- exported_class_argument.carbon

library "[[@TEST_NAME]]";

import Cpp library "templates.h";

class Point {
  var x: i32;
  impl as Core.Copy {
    fn Op(self) -> Self { return {.x = self.x}; }
  }
}

fn Use() -> i32 {
  return Cpp.Id({.x = 6} as Point).x;
}
```

<!-- google-doc-style-resume -->

### A.3 toolchain/check/testdata/interop/cpp/template/var_template.carbon (C1, source lines)

The member template's header becomes valid C++, and a new split pins the
ill-formed form that D-CT-9 now instantiates (clang++ rejects it identically,
§0.3). Inserted after use_var_template.carbon's `//@dump-sem-ir-end` line;
autoupdate places the CHECK lines.

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/check/testdata/interop/cpp/template/var_template.carbon
+++ b/toolchain/check/testdata/interop/cpp/template/var_template.carbon
@@ -18,7 +18,7 @@
 template<typename T> T var = {};

 struct Wrap {
-  template<typename T> static T var = {};
+  template<typename T> static inline T var = {};
 };

 // --- use_var_template.carbon
@@ -34,4 +34,20 @@
 let pwb: Cpp.B* = &Cpp.Wrap.r#var(Cpp.B);
 //@dump-sem-ir-end

+// --- non_inline_static.h
+
+struct A {};
+
+struct Wrap {
+  template<typename T> static T var = {};
+};
+
+// --- fail_non_inline_static_member_template.carbon
+
+library "[[@TEST_NAME]]";
+
+import Cpp library "non_inline_static.h";
+
+let pwa: Cpp.A* = &Cpp.Wrap.r#var(Cpp.A);
+
 // CHECK:STDOUT: --- use_var_template.carbon
```

<!-- google-doc-style-resume -->

### A.4 toolchain/lower/testdata/interop/cpp/globals.carbon (C1, source line)

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/lower/testdata/interop/cpp/globals.carbon
+++ b/toolchain/lower/testdata/interop/cpp/globals.carbon
@@ -133,7 +133,7 @@
 // --- static_template.h

 struct StaticTmplX {
-  template<typename T> static T static_tmpl = T();
+  template<typename T> static inline T static_tmpl = T();
 };

 struct Y {
```

<!-- google-doc-style-resume -->

The refills of generic_call.carbon and non_type_param.carbon change no source
line.

## Appendix B: conformance programs

The nine programs and the oracle of commit P, as measured on v11 (each prints
its EXPECT lines; the oracle prints `6`, `60`, `3`). The two un-SKIPped
programs differ from this branch's text only in the header comment, the SKIP
line's removal and the `impl as Core.Copy` block.

### B: interop/cpp_template_symbolic_arg.carbon

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: C++ interop — importing C++ templates, instantiating on Carbon types
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   7
//
// A Carbon checked generic's symbolic type parameter T as the argument of an
// imported C++ class template, Cpp.Box(T), in the generic's body: the
// specialization is formed for each specific when T is known (here Box<Point>,
// Point exported to C++), and its default initialization, the assignment to
// its field and its copy on return are performed there (CT-1,
// fork/cpp-templates/plan.md). Wrap({.x = 7} as Point).value.x reads back 7.
// Point implements Core.Copy because `b.value = v` copies a Point value: the
// same body without the generic, with Cpp.Box(Point), is rejected by every
// toolchain without it ("cannot copy value of type `Point`"), so the program
// before CT-1 could not have passed for that reason either.

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
  var b: Cpp.Box(T);
  b.value = v;
  return b;
}

fn Run() -> i32 {
  Core.Print(Wrap({.x = 7} as Point).value.x);
  return 0;
}
```

<!-- google-doc-style-resume -->

### B: interop/cpp_template_on_carbon_generic.carbon

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Type system: C++ interop — importing C++ types / exporting Carbon types
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   7
//
// An imported C++ class template instantiated on a symbolic Carbon generic
// parameter and, at the specific, on an exported Carbon class: MakeBox's
// Cpp.Box(T) becomes Box<Pt> for MakeBox(p), with Pt exported to C++ as the
// argument (CT-1, fork/cpp-templates/plan.md). b.value.x reads back 7. Pt
// implements Core.Copy because `b.value = x` copies a Pt value, which the same
// body written with Cpp.Box(Pt) and no generic needs on every toolchain.

import Core library "io";
import Cpp inline '''

template <typename T> struct Box {
  T value;
};

''';

class Pt {
  var x: i32;
  impl as Core.Copy {
    fn Op(self) -> Self { return {.x = self.x}; }
  }
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
```

<!-- google-doc-style-resume -->

### B: interop/cpp_template_fn_symbolic.carbon

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: C++ interop — importing C++ templates, instantiating on Carbon types
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   42
//   10
//   9
//   8
//   2
//   12
//
// Imported C++ function templates called with a symbolic Carbon type argument
// in a checked generic and in a template (CT-1, fork/cpp-templates/plan.md):
// the call is resolved by Clang for each specific, once T is known.
// DoubleIt(21) is Twice<int>(21) = 21 + 21 = 42; DoubleExplicit(5) names the
// template argument, Twice<int>(5) = 10; Larger(3, 9) is Max<int>(3, 9) = 9;
// Size(i64) and Size(i16) are SizeOfFn<long>() = 8 and SizeOfFn<short>() = 2
// (x86-64 Linux, where i64 maps to long and i16 to short); TwiceTemplate(6),
// with a template binding, is Twice<int>(6) = 12.

import Core library "io";
import Cpp inline '''
template<typename T> T Twice(T x) { return x + x; }
template<typename T> T Max(T a, T b) { return a < b ? b : a; }
template<typename T> int SizeOfFn() { return sizeof(T); }
''';

fn DoubleIt[T: type](v: T) -> T {
  return Cpp.Twice(v);
}

fn DoubleExplicit[T: type](v: T) -> T {
  return Cpp.Twice(T, v);
}

fn Larger[T: type](a: T, b: T) -> T {
  return Cpp.Max(a, b);
}

fn Size[T: type](unused v: T) -> i32 {
  return Cpp.SizeOfFn(T);
}

fn TwiceTemplate[template T: type](v: T) -> T {
  return Cpp.Twice(v);
}

fn Run() -> i32 {
  Core.Print(DoubleIt(21 as i32));
  Core.Print(DoubleExplicit(5 as i32));
  Core.Print(Larger(3 as i32, 9 as i32));
  Core.Print(Size(1 as i64));
  Core.Print(Size(1 as i16));
  Core.Print(TwiceTemplate(6 as i32));
  return 0;
}
```

<!-- google-doc-style-resume -->

### B: interop/cpp_template_spec_roundtrip.carbon

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: C++ interop — importing C++ templates, instantiating on Carbon types
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   42
//   7
//   7
//
// A specialization of an imported C++ class template on a symbolic Carbon type
// passed to and returned from C++ functions whose signatures name it (CT-1,
// fork/cpp-templates/plan.md). RoundTrip(41): MakeBox<int>(41) returns a
// Box<int> holding 41, Bump<int>(&b) adds 1 through a pointer, Unbox<int>(b)
// takes it by value and returns 42. Make(7) returns MakeBox<int>(7) from the
// generic; the non-template UnboxInt(Box<int>) reads 7 from it, and its
// member function Get() returns 7.

import Core library "io";
import Cpp inline '''
template<typename T> struct Box {
  T value;
  T Get() const { return value; }
};
template<typename T> Box<T> MakeBox(T v) { Box<T> b; b.value = v; return b; }
template<typename T> T Unbox(Box<T> b) { return b.value; }
template<typename T> void Bump(Box<T>* b) { b->value = b->value + 1; }
inline int UnboxInt(Box<int> b) { return b.value; }
''';

fn RoundTrip[T: type](v: T) -> T {
  var b: Cpp.Box(T) = Cpp.MakeBox(v);
  Cpp.Bump(&b);
  return Cpp.Unbox(b);
}

fn Make[T: type](v: T) -> Cpp.Box(T) {
  return Cpp.MakeBox(v);
}

fn Run() -> i32 {
  Core.Print(RoundTrip(41 as i32));
  var b: Cpp.Box(i32) = Make(7 as i32);
  Core.Print(Cpp.UnboxInt(b));
  Core.Print(b.Get());
  return 0;
}
```

<!-- google-doc-style-resume -->

### B: interop/cpp_template_nested_symbolic.carbon

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: C++ interop — importing C++ templates, instantiating on Carbon types
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   34
//   9
//
// A nested specialization, Cpp.Pair(Cpp.Box(T)), named in a checked generic
// with a symbolic T and formed for each specific (CT-1,
// fork/cpp-templates/plan.md). Both(3, 4) stores 3 and 4 in the two boxes of a
// Pair<Box<int>>, read back as 3 * 10 + 4 = 34; Sum(p) adds the two values
// read through the generic, 4 + 5 = 9.

import Core library "io";
import Cpp inline '''
template<typename T> struct Box {
  T value;
};
template<typename T> struct Pair {
  T first;
  T second;
};
''';

fn Both[T: type](a: T, b: T) -> Cpp.Pair(Cpp.Box(T)) {
  var p: Cpp.Pair(Cpp.Box(T));
  p.first.value = a;
  p.second.value = b;
  return p;
}

fn Sum[T: type](unused w: T, p: Cpp.Pair(Cpp.Box(T))) -> T {
  return p.first.value + p.second.value;
}

fn Run() -> i32 {
  var p: Cpp.Pair(Cpp.Box(i32)) = Both(3 as i32, 4 as i32);
  Core.Print(p.first.value * 10 + p.second.value);
  Core.Print(Sum(0 as i32, Both(4 as i32, 5 as i32)));
  return 0;
}
```

<!-- google-doc-style-resume -->

### B: interop/cpp_template_carbon_generic_spec.carbon

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: C++ interop — importing C++ templates, instantiating on Carbon types
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   6
//   64
//   65
//
// A specific of a Carbon generic class as the argument of an imported C++
// class template, Cpp.Box(List(T)), and a Carbon generic class whose field is
// a C++ specialization of its parameter, Holder(T) with Cpp.Box(T), each
// formed for the specific (CT-1, fork/cpp-templates/plan.md). Wrap(5) stores
// {.head = 5, .count = 1} in a Box<List(i32)>, read back as 5 + 1 = 6;
// Holder(i32).Get() returns the 64 its box holds, and Next(h) reads it in a
// checked generic and adds 1, 65.

import Core library "io";
import Cpp inline '''
template<typename T> struct Box {
  T value;
};
template<typename T> Box<T> MakeBox(T v) { Box<T> b; b.value = v; return b; }
''';

class List(T: type) {
  var head: T;
  var count: i32;
}

class Holder(T: type) {
  var b: Cpp.Box(T);
  fn Get(self) -> T { return self.b.value; }
}

fn Wrap[T: type](v: T) -> Cpp.Box(List(T)) {
  var b: Cpp.Box(List(T));
  b.value = {.head = v, .count = 1};
  return b;
}

fn Next[T: type](h: Holder(T), one: T) -> T {
  return h.b.value + one;
}

fn Run() -> i32 {
  var b: Cpp.Box(List(i32)) = Wrap(5 as i32);
  Core.Print(b.value.head + b.value.count);
  var h: Holder(i32) = {.b = Cpp.MakeBox(64 as i32)};
  Core.Print(h.Get());
  Core.Print(Next(h, 1 as i32));
  return 0;
}
```

<!-- google-doc-style-resume -->

### B: interop/cpp_template_two_specifics.carbon

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: C++ interop — importing C++ templates, instantiating on Carbon types
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   5
//   12
//   2
//
// One checked generic naming Cpp.Loud(T), instantiated twice in one program,
// on i32 and on the exported Carbon class Point: each specific forms its own
// specialization, Loud<int> and Loud<Point>, with its own destructor (CT-1,
// fork/cpp-templates/plan.md). Keep(5) returns 5; Keep of {.x = 1, .y = 2}
// returns a Point printed as 1 * 10 + 2 = 12; each call destroys its local
// Loud once, so the C++ counter reads 2.

import Core library "io";
import Cpp inline '''
inline int destroyed = 0;
template<typename T> struct Loud {
  T value;
  ~Loud() { ++destroyed; }
};
inline int Destroyed() { return destroyed; }
''';

class Point {
  var x: i32;
  var y: i32;
  impl as Core.Copy {
    fn Op(self) -> Self { return {.x = self.x, .y = self.y}; }
  }
}

fn Keep[T: type](v: T) -> T {
  var l: Cpp.Loud(T);
  l.value = v;
  return l.value;
}

fn Run() -> i32 {
  Core.Print(Keep(5 as i32));
  let p: Point = Keep({.x = 1, .y = 2} as Point);
  Core.Print(p.x * 10 + p.y);
  Core.Print(Cpp.Destroyed());
  return 0;
}
```

<!-- google-doc-style-resume -->

### B: interop/cpp_template_symbolic_diff.carbon

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: C++ interop — importing C++ templates, instantiating on Carbon types
// EXPECT-EXIT: 0
//
// C++ class and function templates used from a Carbon checked generic and a
// Carbon template with symbolic type arguments (CT-1,
// fork/cpp-templates/plan.md). Differential pair:
// cpp_template_symbolic_diff.diff.cpp runs the same templates from C++
// function templates of the same shape (no EXPECT-STDOUT). SumThree(1, 2, 3)
// accumulates 6 in an Acc<int>; on i16 it accumulates 60 in an Acc<short>;
// CountThree, with a template binding, reads the accumulator's member n, 3.

import Core library "io";
import Cpp inline '''
template<typename T> struct Acc {
  T total;
  int n;
};
template<typename T> Acc<T> Start(T v) { Acc<T> a; a.total = v; a.n = 1; return a; }
template<typename T> void Add(Acc<T>* a, T v) { a->total = a->total + v; a->n = a->n + 1; }
template<typename T> T Total(const Acc<T>& a) { return a.total; }
''';

fn SumThree[T: type](a: T, b: T, c: T) -> T {
  var acc: Cpp.Acc(T) = Cpp.Start(a);
  Cpp.Add(&acc, b);
  Cpp.Add(&acc, c);
  return Cpp.Total(acc);
}

fn CountThree[template T: type](a: T, b: T, c: T) -> i32 {
  var acc: Cpp.Acc(T) = Cpp.Start(a);
  Cpp.Add(&acc, b);
  Cpp.Add(&acc, c);
  return acc.n;
}

fn Run() -> i32 {
  Core.Print(SumThree(1 as i32, 2 as i32, 3 as i32));
  Core.Print(SumThree(10 as i16, 20 as i16, 30 as i16));
  Core.Print(CountThree(4 as i32, 5 as i32, 6 as i32));
  return 0;
}
```

<!-- google-doc-style-resume -->

### B: interop/cpp_template_symbolic_diff.diff.cpp

<!-- google-doc-style-ignore -->

```cpp
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// Differential oracle for cpp_template_symbolic_diff.carbon: the Carbon
// generic and template written as C++ function templates over the same C++
// templates, printing as Core.Print does (printf "%d\n").

#include <cstdio>

template <typename T>
struct Acc {
  T total;
  int n;
};
template <typename T>
Acc<T> Start(T v) {
  Acc<T> a;
  a.total = v;
  a.n = 1;
  return a;
}
template <typename T>
void Add(Acc<T>* a, T v) {
  a->total = a->total + v;
  a->n = a->n + 1;
}
template <typename T>
T Total(const Acc<T>& a) {
  return a.total;
}

template <typename T>
T SumThree(T a, T b, T c) {
  Acc<T> acc = Start(a);
  Add(&acc, b);
  Add(&acc, c);
  return Total(acc);
}

template <typename T>
int CountThree(T a, T b, T c) {
  Acc<T> acc = Start(a);
  Add(&acc, b);
  Add(&acc, c);
  return acc.n;
}

auto main() -> int {
  std::printf("%d\n", SumThree<int>(1, 2, 3));
  std::printf("%d\n", SumThree<short>(10, 20, 30));
  std::printf("%d\n", CountThree<int>(4, 5, 6));
  return 0;
}
```

<!-- google-doc-style-resume -->

### B: interop/cpp_var_template_runtime.carbon

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: C++ interop — importing C++ templates, instantiating on Carbon types
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   5
//   8
//   20
//   9
//
// Imported C++ variable templates and a static data member template read at
// run time, on concrete and on symbolic Carbon type arguments: each
// specialization is instantiated and defined when Carbon names it (CT-1,
// fork/cpp-templates/plan.md). Plain<int> is sizeof(int) + 1 = 5;
// SizeOf<long> is 8 (i64 maps to long on x86-64 Linux); Holder::count<short>
// is sizeof(short) * 10 = 20; PlainOf(1 as i64) reads Plain<long> in a checked
// generic, 8 + 1 = 9.

import Core library "io";
import Cpp inline '''
template<typename T> int Plain = sizeof(T) + 1;
template<typename T> constexpr int SizeOf = sizeof(T);
struct Holder {
  template<typename T> static inline int count = sizeof(T) * 10;
};
''';

fn PlainOf[T: type](unused v: T) -> i32 {
  return Cpp.Plain(T);
}

fn Run() -> i32 {
  Core.Print(Cpp.Plain(i32));
  Core.Print(Cpp.SizeOf(i64));
  Core.Print(Cpp.Holder.count(i16));
  Core.Print(PlainOf(1 as i64));
  return 0;
}
```

<!-- google-doc-style-resume -->

## Appendix C: records texts

Verbatim, with `<...>` placeholders for what the discharge measures. Dates are
the UTC date of the commit that writes them.

### C.1 Design page and fixture (land-time commit L, over PR 58's text)

In docs/design/interoperability/README.md, "Using C++ templates", the sentence
from "One limit in 0.1:" to "(fork work item W-043, and W-127 on held PR 51)."
is replaced by:

<!-- google-doc-style-ignore -->

```markdown
A `var` of such a specialization can be declared without an initializer,
`var b: Cpp.Box(T);`, and a C++ function template can be called with an
argument of type `T`, as `Cpp.Twice(x)`. Each is checked when the generic is
instantiated for a specific, as a template's body is, so an error in it, such
as a member that `Box<T>` does not have, is reported where the specific is
named (updated <YYYY-MM-DD>, fork work item W-043). A Carbon struct or tuple
type cannot yet be a template argument (W-300), nor a Carbon generic class a
template template argument (W-301).
```

<!-- google-doc-style-resume -->

R27: `var b: Cpp.Box(T);` is the programs' spelling (in
interop/cpp_template_symbolic_arg.carbon and
cpp_template_on_carbon_generic.carbon) and the fixture's; `Cpp.Twice(x)` is the
fixture's. The fixture, added as
fork/designdocs/samples/X34_cpp_template_symbolic_uninit.carbon (the next free X
number after PR 58's X33), measured on v11 (prints `42` and `10`; TP-1 rejects
it with E-DU and E-ARG):

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/interoperability/README.md, "Using C++ templates", quote
// EXPECT-STDOUT:
//   42
//   10
// QUOTE: a `var` of such a specialization can be declared without an initializer, `var b: Cpp.Box(T);`
// Pins the page's sentence on an uninitialized `var` of a C++ specialization
// of a checked generic's type parameter and a C++ function template called
// with an argument of that type: `G(21 as i32)` stores `Twice<int>(21)` in a
// `Box<int>` and returns 42, and `G(5 as i16)` does the same with `Box<short>`
// and returns 10.

import Core library "io";

import Cpp inline '''c++
template <typename T>
struct Box {
  T value;
};

template <typename T>
T Twice(T x) { return x + x; }
''';

fn G[T: Core.Copy](x: T) -> T {
  var b: Cpp.Box(T);
  b.value = Cpp.Twice(x);
  return b.value;
}

fn Run() -> i32 {
  Core.Print(G(21 as i32));
  Core.Print(G(5 as i16));
  return 0;
}
```

<!-- google-doc-style-resume -->

### C.2 W-043's discharge (commit D; merged with PR 58's notes at land time)

<!-- google-doc-style-ignore -->

```json
{
 "id": "W-043",
 "title": "C++ templates instantiated on Carbon types / symbolic Carbon generic parameters as C++ template arguments (DISCHARGED at CT-1, <YYYY-MM-DD>)",
 "evidence": [
  "<the original seven entries, kept>",
  "toolchain/check/impl_lookup.cpp `NamesTemplateBinding` (D-CT-5: a `TemplateInst` names a template binding; `MetaInstId`/`MetaInstBlockId` operands are followed)",
  "toolchain/check/action.cpp `ActionIsPerformable` (D-CT-6), toolchain/check/subst.cpp `PushOperand`/`PopOperand` (D-CT-7), toolchain/check/convert.cpp `PerformAction(InitializeAction)` (D-CT-8), toolchain/check/cpp/call.cpp `BuildTemplateId` (D-CT-9), toolchain/check/cpp/overload_resolution.cpp `IsMoveEquivalentToCopy` (D-CT-10), toolchain/check/call.cpp `DeferCppCallOnSymbolicArgs` (D-CT-3)",
  "toolchain/check/testdata/interop/cpp/template/symbolic_arg.carbon and toolchain/lower/testdata/interop/cpp/template_symbolic_arg.carbon",
  "fork/conformance/programs/interop/cpp_template_symbolic_arg.carbon and cpp_template_on_carbon_generic.carbon (un-SKIPped, PASS), cpp_template_fn_symbolic, cpp_template_spec_roundtrip, cpp_template_nested_symbolic, cpp_template_carbon_generic_spec, cpp_template_two_specifics, cpp_template_symbolic_diff (differential), cpp_var_template_runtime",
  "fork/cpp-templates/plan.md"
 ],
 "notes": "<the original notes, kept>. DISCHARGED at CT-1 (<YYYY-MM-DD>, fork/cpp-templates/plan.md): the blocker the item names, a symbolic Carbon type as a C++ template argument, had been lifted upstream (PRs 7673, 7689 and 7700: a deferred `CallAction` over `TemplateInst`-wrapped arguments); seven defects in that path kept it from working (an uninitialized `var` of the specialization, impl lookup resolved where the generic is defined; a C++ call with an argument of symbolic type; C++ actions performed for a symbolic specific; action operands not substituted; a narrow scalar `return` given a return slot; variable template specializations never instantiated; an exported Carbon class queried before it was complete), each fixed at its root. The two SKIP programs run without their SKIP lines and with the `Core.Copy` impl each needs, keeping the uninitialized `var b: Cpp.Box(T);`. Measured: <gate N of N>, conformance <P / F / S over N>. Residues: W-300 (struct, tuple and unexportable class types), W-301 (Carbon generics as template template arguments), W-302 (non-type argument kinds), W-303 (deduction through a C++ specialization), W-304 (a concrete C++ class `var` in a template's body stops lowering), W-305 (interface member access through a constraint on a specialization's member), W-306 (instantiation notes without a line); cross-library uses stay W-250's."
}
```

<!-- google-doc-style-resume -->

### C.3 The residues (commit D)

<!-- google-doc-style-ignore -->

```json
[
 {
  "id": "W-300",
  "kind": "missing-feature",
  "title": "CT-1 residue: a Carbon struct or tuple type, or a Carbon class that cannot be exported (a class in a generic class's scope), as a C++ template argument is a `semantics TODO`, at the argument when concrete and on instantiation when it is a symbolic argument's value",
  "subsystem": "toolchain/check/cpp (call.cpp, type_mapping.cpp, export.cpp)",
  "size": "M",
  "bullet": "Generics: C++ interop \u2014 importing C++ templates, instantiating on Carbon types",
  "evidence": [
   "toolchain/check/cpp/call.cpp:130-136 (`MapToCppType` returns a null type; ``semantics TODO: `unsupported type used as template argument` ``)",
   "toolchain/check/cpp/export.cpp (``semantics TODO: `non-class non-namespace name scope` `` for a class in a generic class's scope)",
   "toolchain/check/testdata/interop/cpp/template/symbolic_arg.carbon `fail_todo_struct_arg`",
   "fork/cpp-templates/plan.md \u00a71.11 (probes res/w300_struct, res/w300_tuple, res/w300_struct_concrete, ox/nested_generic_scope)"
  ],
  "blocked_by": [],
  "notes": "Filed at CT-1's discharge (<YYYY-MM-DD>). Removal: map a struct or tuple type to a C++ type (an exported aggregate), and export a class nested in a generic class; the split loses its `fail_todo_` prefix."
 },
 {
  "id": "W-301",
  "kind": "missing-feature",
  "title": "CT-1 residue: a Carbon generic class as a C++ template template argument is rejected by Clang, because a placeholder expression is passed for it",
  "subsystem": "toolchain/check/cpp (call.cpp)",
  "size": "M",
  "bullet": "Generics: C++ interop \u2014 importing C++ templates, instantiating on Carbon types",
  "evidence": [
   "toolchain/check/cpp/call.cpp:157-159 (TODO: Carbon generics as template template arguments; `MakePlaceholderTemplateArg`)",
   "toolchain/check/testdata/interop/cpp/template/symbolic_arg.carbon `fail_template_template_carbon_generic` (``template argument for template template parameter must be a class template or type alias template``)"
  ],
  "blocked_by": [],
  "notes": "Filed at CT-1's discharge (<YYYY-MM-DD>). A C++ class template as the argument works (`Cpp.Apply(Cpp.Box, T)`, nested_and_generic_class_args). Removal: export a Carbon generic class as a C++ class template."
 },
 {
  "id": "W-302",
  "kind": "missing-feature",
  "title": "CT-1 residue: a non-type template argument that is a pointer to a Carbon variable, or of a kind `MapConstantToAPValue` does not map, is a `semantics TODO`",
  "subsystem": "toolchain/check/cpp (call.cpp)",
  "size": "S",
  "bullet": "Generics: C++ interop \u2014 importing C++ templates, instantiating on Carbon types",
  "evidence": [
   "toolchain/check/cpp/call.cpp:246 (TODO: pointers to variables declared in Carbon) and :256-259 (``semantics TODO: `unsupported argument type for non-type template parameter` ``)",
   "fork/cpp-templates/plan.md \u00a71.11 (probe res/w302_ptr_nttp; a `double` argument works, res/w302_double_nttp)"
  ],
  "blocked_by": [],
  "notes": "Filed at CT-1's discharge (<YYYY-MM-DD>); carries the non-type half of W-043's evidence (call.cpp:252 at filing). A symbolic integer argument of a matching type works (`Cpp.Array(i32, N)` with `generic N: i32`)."
 },
 {
  "id": "W-303",
  "kind": "missing-feature",
  "title": "CT-1 residue: a Carbon generic parameter cannot be deduced through a C++ class template specialization in a parameter's type",
  "subsystem": "toolchain/check (deduce.cpp)",
  "size": "M",
  "bullet": "Generics: C++ interop \u2014 importing C++ templates, instantiating on Carbon types",
  "evidence": [
   "toolchain/check/deduce.cpp:513 (``cannot deduce value for generic parameter `T` ``)",
   "toolchain/check/testdata/interop/cpp/template/symbolic_arg.carbon `fail_todo_deduce_through_specialization`"
  ],
  "blocked_by": [],
  "notes": "Filed at CT-1's discharge (<YYYY-MM-DD>). `fn Get[T: type](b: Cpp.Box(T))` called with a `Box<int>`; the programs pass `T` through another parameter. Removal: deduce `T` from the C++ specialization's template arguments."
 },
 {
  "id": "W-304",
  "kind": "toolchain-defect",
  "title": "Found by CT-1's audit: a `var` of a concrete C++ class in a template's body stops lowering, as on trunk and the nightly",
  "subsystem": "toolchain/lower (function_context.cpp) + toolchain/check (the class's witnesses in a template's eval block)",
  "size": "M",
  "bullet": "Generics: Integrated templates",
  "evidence": [
   "toolchain/lower/function_context.cpp:264 (CHECK `const_id.is_concrete()`: a `SpliceInst` in the specific has a non-concrete value; trunk :223, the nightly sem_ir/constant.cpp:36)",
   "fork/cpp-templates/plan.md \u00a70.3 (probes gen4/s6_concrete_cpp_var_in_template, gen4/s5_tm6_concrete_cpp_var_in_template, gen2/t_class_member_template; the checked twins run)"
  ],
  "blocked_by": [],
  "notes": "Filed at CT-1's discharge (<YYYY-MM-DD>). `fn F[template T: type](unused v: T) -> i32 { var unused h: Cpp.Holder; return 1; }` with `struct Holder { int Take(int v) { return v; } };`. Not caused by CT-1 (TP-1, trunk and the nightly stop the same way) and not in W-043's path."
 },
 {
  "id": "W-305",
  "kind": "missing-feature",
  "title": "CT-1 residue: a simple member access to an interface member through a checked generic's constraint, on a value read from a C++ specialization's member, is looked up in the specific's concrete type and not found",
  "subsystem": "toolchain/check (member_access.cpp)",
  "size": "M",
  "bullet": "Generics: C++ interop \u2014 importing C++ templates, instantiating on Carbon types",
  "evidence": [
   "toolchain/check/testdata/interop/cpp/template/symbolic_arg.carbon `fail_todo_member_through_constraint` (``unable to monomorphize specific `Simple(S as Show)` `` with ``member name `Get` not found in `S` ``; `Direct` and `Compound` compile)",
   "fork/templates/plan.md W-266 (the same shape for a field of a template parameter)"
  ],
  "blocked_by": [],
  "notes": "Filed at CT-1's discharge (<YYYY-MM-DD>). `b.value.Get()` for `T: Show` and `var b: Cpp.Box(T)`, where `S` has `impl as Show` without `extend`; `v.Get()` on `v: T` and the compound `b.value.(Show.Get)()` work. Removal: look an instantiated member access up through the constraint of the type it had where the generic is defined."
 },
 {
  "id": "W-306",
  "kind": "toolchain-defect",
  "title": "CT-1 residue: a note from a C++ template argument converted for a specific has no line, and a type argument that fails in two deferred actions reports E-MONO twice",
  "subsystem": "toolchain/check (cpp/call.cpp, eval of a specific)",
  "size": "S",
  "bullet": "Generics: C++ interop \u2014 importing C++ templates, instantiating on Carbon types",
  "evidence": [
   "toolchain/check/testdata/interop/cpp/template/symbolic_arg.carbon `fail_todo_struct_arg` (``fail_todo_struct_arg.carbon: note: semantics TODO: ...``, no line)",
   "fork/cpp-templates/plan.md \u00a71.11 (probes gen4/g_nontype_i64, ox/nested_generic_scope)",
   "upstream 7beb29f8b (upstream PR 7967, `GetInstLocationOrFallback` for diagnostics on canonical instructions, after the fork's cut)"
  ],
  "blocked_by": [],
  "notes": "Filed at CT-1's discharge (<YYYY-MM-DD>). The argument is a canonical constant in the specific and has no location; removal: take upstream's fallback location at the next upstream merge and pass the action's location to `ConvertArgToTemplateArg`."
 }
]
```

<!-- google-doc-style-resume -->

In the JSON, `\u2014` stands for the em dash of the bullet's name; the
writer keeps the ledger's own escaping (the file is written by `json.dump`, as
TP-1's D commit did).

### C.4 Gap rows (commit R; at PR 58's line numbers at land time)

<!-- google-doc-style-ignore -->

```markdown
| Generics: C++ interop — importing C++ templates, instantiating on Carbon types | PARTIAL | Class/function/alias/variable templates import and instantiate on C++ types, Carbon builtins and Carbon classes, concrete or a checked generic's or a template's symbolic arguments, each specialization formed for each specific (CT-1, <YYYY-MM-DD>); struct and tuple types as arguments (W-300), Carbon generics as template template arguments (W-301), some non-type argument kinds (W-302) and deduction through a specialization (W-303) are missing. |
| Type system: C++ interop — importing C++ types / exporting Carbon types | PARTIAL | Classes/enums/unions/templates import and Carbon classes export (125 check + 38 lower interop tests), C++ templates instantiate on Carbon class types, symbolic ones included (CT-1, <YYYY-MM-DD>), but several export cases are fail_todo. |
```

<!-- google-doc-style-resume -->

### C.5 W-268's discharge (commit D)

<!-- google-doc-style-ignore -->

```text
title: <the title> (DISCHARGED at CT-1, <YYYY-MM-DD>)
notes, appended: DISCHARGED at CT-1 (<YYYY-MM-DD>, fork/cpp-templates/plan.md D-CT-5): `NamesTemplateBinding` follows `MetaInstId` and `MetaInstBlockId` operands, the removal this item names; d03 (`var e: T.Elem;` for a template `T: Container`) prints 6 and 4, and g_w268 prints 52.
```

<!-- google-doc-style-resume -->

### C.6 The merged programs' header paragraph (land-time M, C-1)

Appended to PR 51's header in both programs, which keep CT-1's body:

<!-- google-doc-style-ignore -->

```carbon
// CT-1 (<YYYY-MM-DD>, fork/cpp-templates/plan.md): the uninitialized
// `var b: Cpp.Box(T);` compiles, so the box is declared without the
// constructor initializer the round-2 edit added for W-127; `impl as
// Core.Copy` stays, because `b.value = v` copies a Carbon class value.
```

<!-- google-doc-style-resume -->

### C.7 Decision-log entry (commit D)

<!-- google-doc-style-ignore -->

```markdown
### CT-1: C++ templates on symbolic Carbon type arguments (<YYYY-MM-DD>)

Context: W-043 (gap row 56, "Generics: C++ interop — importing C++ templates,
instantiating on Carbon types", PARTIAL, with its second program under row 42),
fork/cpp-templates/plan.md, rev <N> after <the plan reviews>, implemented and
folded with two implementation reviews (<their verdicts and finding counts>).
Every decision auto-adopted under V-2/V-3 (R29(a)) and open to veto. Options
considered (plan §7.2): instantiating eagerly on every possible argument,
treating C++ templates as Carbon templates only, requiring `template T` for
all uses, diagnosing member access where a checked generic is defined, a new
instruction kind, wrapping every value argument, substituting into every
action operand, instantiating a variable template from the import, completing
every exported class when mapped, keeping PR 51's constructor-initialized
programs, and a definition-time TODO for the OUT kinds. Decisions: D-CT-1,
upstream's deferred `CallAction` over `TemplateInst`, performed per specific,
no new SemIR; D-CT-2, operations on a C++ specialization in a checked generic
are checked per specific and diagnosed on instantiation; D-CT-3, C++ calls
with a checked-symbolic argument are deferred; D-CT-4, the template lane rides
TP-1, TR-22 stays OUT; D-CT-5, impl lookup on a C++ specialization is deferred
(D-TP-12 amended, W-268 discharged); D-CT-6, a C++ callee's action waits for
concrete arguments; D-CT-7, constant action operands are substituted; D-CT-8,
a deferred `return` uses the return slot only in place; D-CT-9, variable
template specializations are implicitly instantiated; D-CT-10, an exported
class is completed before overload resolution reads it; D-CT-11, the admitted
kinds and the OUT table; D-CT-12, goldens; D-CT-13, nine programs; D-CT-14,
docs at land time and records; D-CT-15, stacked on PR 61, merged after PR 62;
D-CT-16, no fork design id. Consequences: rows 56 and 42 stay PARTIAL with
corrected text; W-043 and W-268 discharged; W-300 to W-306 filed (CT-1
reserved W-300..W-319; W-307 to W-319 unused); F-021 not minted.

_V-3a divergence-risk register entries (reviewed at each upstream merge):_ the
six of plan §0.10. Veto-able.
```

<!-- google-doc-style-resume -->

### C.8 fork/ORCHESTRATION.md (commit D; the held-state stamp on trunk is the orchestrator's)

<!-- google-doc-style-ignore -->

```markdown
| `claude/carbon-fork-0-1-ct` | <state, e.g. HELD OPEN as PR NN> -- CT-1 C++ templates on symbolic Carbon type arguments at <head>, stacked on PR 61 (W-043 and W-268 discharged; W-300..W-306 filed, W-307..W-319 unused; F-021 not minted; expected <gate> and <P / F / S over N>; rows 56 and 42 PARTIAL); merges after PR 62 through its land-time items M, L-F, L and the land-time records commit. |
```

<!-- google-doc-style-resume -->

### C.9 fork/conformance/README.md program table (commit P, generated)

<!-- google-doc-style-ignore -->

```markdown
| `interop/cpp_template_carbon_generic_spec.carbon` | Generics: C++ interop — importing C++ templates, instantiating on Carbon types | run |
| `interop/cpp_template_fn_symbolic.carbon` | Generics: C++ interop — importing C++ templates, instantiating on Carbon types | run |
| `interop/cpp_template_nested_symbolic.carbon` | Generics: C++ interop — importing C++ templates, instantiating on Carbon types | run |
| `interop/cpp_template_on_carbon_generic.carbon` | Type system: C++ interop — importing C++ types / exporting Carbon types | run |
| `interop/cpp_template_spec_roundtrip.carbon` | Generics: C++ interop — importing C++ templates, instantiating on Carbon types | run |
| `interop/cpp_template_symbolic_arg.carbon` | Generics: C++ interop — importing C++ templates, instantiating on Carbon types | run |
| `interop/cpp_template_symbolic_diff.carbon` | Generics: C++ interop — importing C++ templates, instantiating on Carbon types | differential |
| `interop/cpp_template_two_specifics.carbon` | Generics: C++ interop — importing C++ templates, instantiating on Carbon types | run |
| `interop/cpp_var_template_runtime.carbon` | Generics: C++ interop — importing C++ templates, instantiating on Carbon types | run |
```

<!-- google-doc-style-resume -->

### C.10 W-127 (land-time records commit, PR 51's item)

<!-- google-doc-style-ignore -->

```text
notes, appended: The checked-generic shape of this item's split (`fn F[T: type](unused x: T) { var unused v: Cpp.S(T); }` under the real prelude) is accepted since CT-1 (<YYYY-MM-DD>, fork/cpp-templates/plan.md D-CT-5), whose land-time fill renamed the split `unformed_dependent_var`; TP-1's discharge covers the template shape (`var y: T;`).
```

<!-- google-doc-style-resume -->

## Appendix D: probe sources

The probes live in scratch, not in the repository (H-5); these are their
sources, so that every row of §0.3 can be regenerated. gen and gen2 are
generated: each form below is written as `fn F[T: type]...` (`c_`) and
`fn F[template T: type]...` (`t_`), after the shared header, with
`fn Run() -> i32 { Core.Print(<call>); return 0; }`. gen2, gen3's twins and
gen4 use the header below; gen uses the same header without `value_type`,
`Kind`, `UnboxInt`, `Loud`'s constructors, `MakeLoud`, `SizeOfFn` and
`Holder`.

### D.1 The shared header

<!-- google-doc-style-ignore -->

```carbon
import Core library "io";
import Cpp inline '''
template<typename T> struct Box {
  using value_type = T;
  T value;
  T Get() const { return value; }
  static int Kind() { return 37; }
};
template<typename T> using BoxAlias = Box<T>;
template<typename T> struct Pair { T first; T second; };
template<typename T> T Twice(T x) { return x + x; }
template<typename T> T Unbox(Box<T> b) { return b.value; }
inline int UnboxInt(Box<int> b) { return b.value; }
template<typename T> Box<T> MakeBoxCpp(T v) { Box<T> b; b.value = v; return b; }
template<typename T> bool SameBox(const Box<T>& a, const Box<T>& b) { return &a == &b; }
template<typename T, int N> struct Array { T data[N]; int Size() const { return N; } };
inline int destroyed = 0;
template<typename T> struct Loud { T v; Loud() : v() {} Loud(const Loud& o) : v(o.v) {} ~Loud() { ++destroyed; } };
template<typename T> Loud<T> MakeLoud(T v) { Loud<T> l; l.v = v; return l; }
inline int Destroyed() { return destroyed; }
template<typename T> constexpr int SizeOf = sizeof(T);
template<typename T> int SizeOfFn() { return sizeof(T); }
struct Holder { template<typename T> T Id(T v) { return v; } };
''';
class Point {
  var x: i32;
  impl as Core.Copy {
    fn Op(self) -> Self { return {.x = self.x}; }
  }
}
class List(T: type) {
  var head: T;
}
```

<!-- google-doc-style-resume -->

### D.2 gen: the forms (name: signature, body, call)

<!-- google-doc-style-ignore -->

```python
F = {
 "decl": ("[@K@T: type](unused v: T) -> i32", "var unused b: Cpp.Box(T);\n  return 1;", "F(5 as i32)"),
 "decl_point": ("[@K@T: type](unused v: T) -> i32", "var unused b: Cpp.Box(T);\n  return 1;", "F({.x = 5} as Point)"),
 "init_from_cpp_call": ("[@K@T: type](v: T) -> i32", "var unused b: Cpp.Box(T) = Cpp.MakeBoxCpp(v);\n  return 2;", "F(5 as i32)"),
 "fn_template_call": ("[@K@T: type](v: T) -> T", "return Cpp.Twice(v);", "F(21 as i32)"),
 "fn_template_explicit": ("[@K@T: type](v: T) -> T", "return Cpp.Twice(T, v);", "F(21 as i32)"),
 "field_assign_read": ("[@K@T: type](v: T) -> T", "var b: Cpp.Box(T);\n  b.value = v;\n  return b.value;", "F(7 as i32)"),
 "method_call": ("[@K@T: type](v: T) -> T", "var b: Cpp.Box(T) = Cpp.MakeBoxCpp(v);\n  return b.Get();", "F(8 as i32)"),
 "pass_to_cpp": ("[@K@T: type](v: T) -> T", "var b: Cpp.Box(T) = Cpp.MakeBoxCpp(v);\n  return Cpp.Unbox(b);", "F(9 as i32)"),
 "param_copy": ("[@K@T: type](unused v: T, b: Cpp.Box(T)) -> Cpp.Box(T)", "return b;", "F(1 as i32, Cpp.MakeBoxCpp(10 as i32)).value"),
 "return_spec": ("[@K@T: type](v: T) -> Cpp.Box(T)", "return Cpp.MakeBoxCpp(v);", "F(11 as i32).value"),
 "return_var": ("[@K@T: type](unused v: T) -> Cpp.Box(T)", "var b: Cpp.Box(T);\n  return b;", "F(11 as i32).value * 0 + 11"),
 "compare_addr": ("[@K@T: type](v: T) -> bool", "var b: Cpp.Box(T) = Cpp.MakeBoxCpp(v);\n  return Cpp.SameBox(b, b);", "(if F(1 as i32) then 12 else 0)"),
 "destroy": ("[@K@T: type](unused v: T) -> i32", "{ var unused l: Cpp.Loud(T); }\n  return Cpp.Destroyed() + 12;", "F(1 as i32)"),
 "nested": ("[@K@T: type](v: T) -> T", "var p: Cpp.Pair(Cpp.Box(T));\n  p.first = Cpp.MakeBoxCpp(v);\n  return p.first.value;", "F(14 as i32)"),
 "nested_decl": ("[@K@T: type](unused v: T) -> i32", "var unused p: Cpp.Pair(Cpp.Box(T));\n  return 14;", "F(14 as i32)"),
 "carbon_generic_class": ("[@K@T: type](unused v: T) -> i32", "var unused b: Cpp.Box(List(T));\n  return 15;", "F(1 as i32)"),
 "carbon_generic_class_field": ("[@K@T: type](v: T) -> T", "var b: Cpp.Box(List(T));\n  b.value = {.head = v};\n  return b.value.head;", "F(15 as i32)"),
 "exported_class": ("[@K@T: type](v: T) -> T", "var b: Cpp.Box(T);\n  b.value = v;\n  return b.value;", "F({.x = 16} as Point).x"),
 "alias_template": ("[@K@T: type](v: T) -> T", "var b: Cpp.BoxAlias(T);\n  b.value = v;\n  return b.value;", "F(17 as i32)"),
 "var_template": ("[@K@T: type](unused v: T) -> i32", "return Cpp.SizeOf(T);", "F(1 as i32) + 14"),
 "two_specifics": ("[@K@T: type](v: T) -> T", "var b: Cpp.Box(T);\n  b.value = v;\n  return b.value;", "F(18 as i32) + F({.x = 1} as Point).x"),
 "nontype_symbolic": ("(@K@N: i32) -> i32", "var a: Cpp.Array(i32, N);\n  return a.Size();", "F(3)"),
 "nontype_symbolic_decl": ("(@K@N: i32) -> i32", "var unused a: Cpp.Array(i32, N);\n  return 3;", "F(3)"),
}
```

<!-- google-doc-style-resume -->

### D.3 gen2: the forms (name: signature, body, extra declarations, call)

<!-- google-doc-style-ignore -->

```python
F = {
 # (sig, body, extra decls, run expr)
 "param_field": ("[@K@T: type](unused v: T, b: Cpp.Box(T)) -> T", "return b.value;", "", "F(1 as i32, Cpp.MakeBoxCpp(21 as i32))"),
 "param_method": ("[@K@T: type](unused v: T, b: Cpp.Box(T)) -> T", "return b.Get();", "", "F(1 as i32, Cpp.MakeBoxCpp(22 as i32))"),
 "param_unbox": ("[@K@T: type](unused v: T, b: Cpp.Box(T)) -> T", "return Cpp.Unbox(b);", "", "F(1 as i32, Cpp.MakeBoxCpp(23 as i32))"),
 "param_unbox_int": ("[@K@T: type](unused v: T, b: Cpp.Box(T)) -> i32", "return Cpp.UnboxInt(b);", "", "F(1 as i32, Cpp.MakeBoxCpp(24 as i32))"),
 "destroy": ("[@K@T: type](v: T) -> i32", "G(v);\n  G(v);\n  return Cpp.Destroyed();", "fn G[@K@T: type](unused v: T) {\n  var unused l: Cpp.Loud(T);\n}\n", "F(1 as i32) + 23"),
 "destroy_copy": ("[@K@T: type](unused v: T, l: Cpp.Loud(T)) -> i32", "var unused c: Cpp.Loud(T) = l;\n  return Cpp.Destroyed();", "", "F(1 as i32, Cpp.MakeLoud(1 as i32)) + 25"),
 "nested_fn": ("[@K@T: type](v: T) -> T", "return Cpp.Unbox(Cpp.MakeBoxCpp(v));", "", "F(26 as i32)"),
 "twice_twice": ("[@K@T: type](v: T) -> T", "return Cpp.Twice(Cpp.Twice(v));", "", "F(7 as i32) - 1"),
 "assign_spec": ("[@K@T: type](v: T) -> T", "var a: Cpp.Box(T);\n  var b: Cpp.Box(T) = Cpp.MakeBoxCpp(v);\n  a = b;\n  return a.value;", "", "F(28 as i32)"),
 "ptr_spec": ("[@K@T: type](v: T) -> T", "var b: Cpp.Box(T) = Cpp.MakeBoxCpp(v);\n  var p: Cpp.Box(T)* = &b;\n  return p->value;", "", "F(29 as i32)"),
 "symbolic_call_in_generic_caller": ("[@K@T: type](v: T) -> T", "return Cpp.Twice(v);", "fn H[U: type](u: U) -> U { return F(u); }\n", "H(15 as i32)"),
 "box_in_generic_caller": ("[@K@T: type](v: T) -> T", "var b: Cpp.Box(T);\n  b.value = v;\n  return b.value;", "fn H[U: type](u: U) -> U { return F(u); }\n", "H(31 as i32)"),
 "float_arg": ("[@K@T: type](v: T) -> T", "return Cpp.Twice(v);", "", "(F(16.0 as f64) as i32)"),
 "member_missing": ("[@K@T: type](v: T) -> T", "var b: Cpp.Box(T);\n  b.value = v;\n  return b.nope;", "", "F(1 as i32)"),
 "member_missing_uncalled": ("[@K@T: type](v: T) -> T", "var b: Cpp.Box(T);\n  b.value = v;\n  return b.nope;", "", "33"),
 "bad_inst": ("[@K@T: type](v: T) -> T", "return Cpp.Twice(v);", "", "Cpp.Twice({.x = 1} as Point).x"),
 "bad_inst_generic": ("[@K@T: type](v: T) -> T", "return Cpp.Twice(v);", "", "F({.x = 1} as Point).x"),
 "sizeof": ("[@K@T: type](unused v: T) -> i32", "return Cpp.SizeOfFn(T);", "", "F(1 as i32) + 31"),
 "class_member_template": ("[@K@T: type](v: T) -> T", "var h: Cpp.Holder;\n  return h.Id(v);", "", "F(36 as i32)"),
 "static_member": ("[@K@T: type](unused v: T) -> i32", "return Cpp.Box(T).Kind();", "", "F(1 as i32)"),
 "type_alias_member": ("[@K@T: type](v: T) -> T", "var x: Cpp.Box(T).value_type = v;\n  return x;", "", "F(38 as i32)"),
 "operator_on_result": ("[@K@T: type](v: T) -> T", "return Cpp.Twice(v) + v;", "", "F(14 as i32)"),
 "result_in_var": ("[@K@T: type](v: T) -> T", "var r: T = Cpp.Twice(v);\n  return r;", "", "F(21 as i32)"),
 "carbon_generic_spec_arg": ("[@K@T: type](v: T) -> T", "var b: Cpp.Box(List(T));\n  b.value = {.head = v};\n  return Cpp.Unbox(b).head;", "", "F(39 as i32)"),
}
```

<!-- google-doc-style-resume -->

### D.4 gen4: the bodies after the shared header

<!-- google-doc-style-ignore -->

```carbon
// g_class_field_checked
class Holder(T: type) { var b: Cpp.Box(T); }
fn Run() -> i32 { var h: Holder(i32) = {.b = Cpp.MakeBoxCpp(40 as i32)}; Core.Print(h.b.value); return 0; }

// g_class_field_template
class Holder(template T: type) { var b: Cpp.Box(T); }
fn Run() -> i32 { var h: Holder(i32) = {.b = Cpp.MakeBoxCpp(41 as i32)}; Core.Print(h.b.value); return 0; }

// g_cpp_generic_class_spec
class Wrap2(T: type) { var x: T; }
fn F[T: type](v: T) -> T { var b: Cpp.Box(Wrap2(T)); b.value = {.x = v}; return Cpp.Unbox(b).x; }
fn Run() -> i32 { Core.Print(F(53 as i32)); return 0; }

// g_eval_order
fn F[T: type](v: T) -> T { var b: Cpp.Box(T) = Cpp.MakeBoxCpp(v); var c: Cpp.Box(T) = b; c.value = Cpp.Twice(c.value); return c.value + b.value; }
fn Run() -> i32 { Core.Print(F(17 as i32)); return 0; }

// g_facet_constrained
interface Show { fn Get(self) -> i32; }
class S2 { var v: i32; impl as Show { fn Get(self) -> i32 { return self.v; } } impl as Core.Copy { fn Op(self) -> Self { return {.v = self.v}; } } }
fn F[T: Show](v: T) -> i32 { var b: Cpp.Box(T); b.value = v; return b.value.Get(); }
fn Run() -> i32 { Core.Print(F({.v = 50} as S2)); return 0; }

// g_facet_constrained_member
interface Show { fn Get(self) -> i32; }
class S2 { var v: i32; impl as Show { fn Get(self) -> i32 { return self.v; } } impl as Core.Copy { fn Op(self) -> Self { return {.v = self.v}; } } }
fn F[T: Show](v: T) -> i32 { return v.Get() + Cpp.Unbox(Cpp.MakeBoxCpp(v)).Get(); }
fn Run() -> i32 { Core.Print(F({.v = 25} as S2)); return 0; }

// g_nontype_i64
fn F(generic N: i64) -> i32 { var a: Cpp.Array(i32, N); return a.Size(); }
fn Run() -> i32 { Core.Print(F(49)); return 0; }

// g_point_nocopy
class NC { var x: i32; }
fn F[T: type](unused v: T) -> i32 { var b: Cpp.Box(T); b.value.x = 42; return b.value.x; }
fn Run() -> i32 { Core.Print(F({.x = 1} as NC)); return 0; }

// g_point_nocopy_return
class NC { var x: i32; }
fn F[T: type](unused v: T) -> Cpp.Box(T) { var b: Cpp.Box(T); b.value.x = 43; return b; }
fn Run() -> i32 { Core.Print(F({.x = 1} as NC).value.x); return 0; }

// g_ptr_arg
fn F[T: type](v: T) -> T { var b: Cpp.Box(T); b.value = v; return b.value; }
fn Run() -> i32 { var n: i32 = 48; Core.Print(*F(&n)); return 0; }

// g_struct_arg
fn F[T: type](v: T) -> T { var b: Cpp.Box(T); b.value = v; return b.value; }
fn Run() -> i32 { Core.Print(F({.a = 46}).a); return 0; }

// g_template_template
fn Run() -> i32 { var unused a: Cpp.Apply(List, i32); Core.Print(44); return 0; }

// g_template_template_cpp
fn F[T: type](unused v: T) -> i32 { var unused a: Cpp.Apply(Cpp.Box, T); return 45; }
fn Run() -> i32 { Core.Print(F(1 as i32)); return 0; }

// g_tuple_arg
fn F[T: type](v: T) -> T { var b: Cpp.Box(T); b.value = v; return b.value; }
fn Run() -> i32 { Core.Print(F((47, 1)).0); return 0; }

// g_w268
interface Container { let Elem: type; }
class V { var n: i32; } impl V as Container where .Elem = i32 {}
fn F[template T: Container](unused t: T) -> i32 { var e: T.Elem; e = 52; return e; }
fn Run() -> i32 { Core.Print(F({.n = 1} as V)); return 0; }

// s1_class_field_in_generic
class Holder(T: type) { var b: Cpp.Box(T); }
fn Make[T: type](v: T) -> T { var h: Holder(T) = {.b = Cpp.MakeBoxCpp(v)}; return h.b.value; }
fn Run() -> i32 { Core.Print(Make(54 as i32)); return 0; }

// s1b_param
class Holder(T: type) { var b: Cpp.Box(T); }
fn Get[T: type](h: Holder(T)) -> T { return h.b.value; }
fn Run() -> i32 { var h: Holder(i32) = {.b = Cpp.MakeBoxCpp(60 as i32)}; Core.Print(Get(h)); return 0; }

// s1c_construct_only
class Holder(T: type) { var b: Cpp.Box(T); }
fn Make[T: type](v: T) -> i32 { var unused h: Holder(T) = {.b = Cpp.MakeBoxCpp(v)}; return 61; }
fn Run() -> i32 { Core.Print(Make(1 as i32)); return 0; }

// s1d_field_var
class Holder(T: type) { var b: Cpp.Box(T); }
fn Get[T: type](h: Holder(T)) -> i32 { var unused c: Cpp.Box(T) = h.b; return 62; }
fn Run() -> i32 { var h: Holder(i32) = {.b = Cpp.MakeBoxCpp(60 as i32)}; Core.Print(Get(h)); return 0; }

// s1e_return_box
class Holder(T: type) { var b: Cpp.Box(T); }
fn Get[T: type](h: Holder(T)) -> Cpp.Box(T) { return h.b; }
fn Run() -> i32 { var h: Holder(i32) = {.b = Cpp.MakeBoxCpp(63 as i32)}; Core.Print(Get(h).value); return 0; }

// s1f_method
class Holder(T: type) { var b: Cpp.Box(T); fn Get(self) -> T { return self.b.value; } }
fn Run() -> i32 { var h: Holder(i32) = {.b = Cpp.MakeBoxCpp(64 as i32)}; Core.Print(h.Get()); return 0; }

// s2_class_field_in_template
class Holder(T: type) { var b: Cpp.Box(T); }
fn Make[template T: type](v: T) -> T { var h: Holder(T) = {.b = Cpp.MakeBoxCpp(v)}; return h.b.value; }
fn Run() -> i32 { Core.Print(Make(55 as i32)); return 0; }

// s3_compound_member
interface Show { fn Get(self) -> i32; }
class S2 { var v: i32; impl as Show { fn Get(self) -> i32 { return self.v; } } impl as Core.Copy { fn Op(self) -> Self { return {.v = self.v}; } } }
fn F[T: Show](v: T) -> i32 { var b: Cpp.Box(T); b.value = v; return b.value.(Show.Get)(); }
fn Run() -> i32 { Core.Print(F({.v = 56} as S2)); return 0; }

// s4_extend_member
interface Show { fn Get(self) -> i32; }
class S2 { var v: i32; extend impl as Show { fn Get(self) -> i32 { return self.v; } } impl as Core.Copy { fn Op(self) -> Self { return {.v = self.v}; } } }
fn F[T: Show](v: T) -> i32 { var b: Cpp.Box(T); b.value = v; return b.value.Get(); }
fn Run() -> i32 { Core.Print(F({.v = 57} as S2)); return 0; }

// s5_tm6_concrete_cpp_var_in_template
fn F[template T: type](unused v: T) -> i32 { var unused h: Cpp.Pair(i32); return 58; }
fn Run() -> i32 { Core.Print(F(1 as i32)); return 0; }
```

<!-- google-doc-style-resume -->

### D.5 gen4: the probes with their own headers

Probe `s6_concrete_cpp_var_in_template`:

<!-- google-doc-style-ignore -->

```carbon
import Cpp inline '''
struct Holder { int Take(int v) { return v; } };
''';
fn F[template T: type](unused v: T) -> i32 {
  //@dump-sem-ir-begin
  var unused h: Cpp.Holder;
  //@dump-sem-ir-end
  return 1;
}
fn Run() -> i32 { return F(36 as i32); }
```

<!-- google-doc-style-resume -->

Probe `w268_d03_var_elem`:

<!-- google-doc-style-ignore -->

```carbon
import Core library "io";
interface Container {
  let Elem: type;
  fn Get(self) -> Elem;
}
class Ints {
  var n: i32;
  impl as Container where .Elem = i32 {
    fn Get(self) -> i32 { return self.n; }
  }
}
fn E5[template T: Container](x: T) -> i32 { var e: T.Elem; e = x.Get(); return e + 1; }
fn E5b[template T: type](unused x: T) -> i32 { var e: T; e = 3; return e + 1; }
fn Run() -> i32 {
  let n: Ints = {.n = 5};
  Core.Print(E5(n));
  Core.Print(E5b(1 as i32));
  return 0;
}
```

<!-- google-doc-style-resume -->

Probe `y_D`:

<!-- google-doc-style-ignore -->

```carbon
import Core library "io";
import Cpp inline '''
template<typename T> T Twice(T x) { return x + x; }
template<typename T> struct Acc { T total; int n; };
template<typename T> T Total(const Acc<T>& a) { return a.total; }
template<typename T> Acc<T> Start(T v) { Acc<T> a; a.total = v; a.n = 1; return a; }
''';
fn D[T: type](v: T) -> T { return Cpp.Twice(v); }
fn E[template T: type](v: T) -> T { return Cpp.Twice(v); }
fn F[T: type](v: T) -> T { var acc: Cpp.Acc(T) = Cpp.Start(v); return Cpp.Total(acc); }
fn G[template T: type](v: T) -> T { var acc: Cpp.Acc(T) = Cpp.Start(v); return Cpp.Total(acc); }
fn Run() -> i32 {
  Core.Print(D(7 as i16));

  return 0;
}
```

<!-- google-doc-style-resume -->

Probe `y_E`:

<!-- google-doc-style-ignore -->

```carbon
import Core library "io";
import Cpp inline '''
template<typename T> T Twice(T x) { return x + x; }
template<typename T> struct Acc { T total; int n; };
template<typename T> T Total(const Acc<T>& a) { return a.total; }
template<typename T> Acc<T> Start(T v) { Acc<T> a; a.total = v; a.n = 1; return a; }
''';
fn D[T: type](v: T) -> T { return Cpp.Twice(v); }
fn E[template T: type](v: T) -> T { return Cpp.Twice(v); }
fn F[T: type](v: T) -> T { var acc: Cpp.Acc(T) = Cpp.Start(v); return Cpp.Total(acc); }
fn G[template T: type](v: T) -> T { var acc: Cpp.Acc(T) = Cpp.Start(v); return Cpp.Total(acc); }
fn Run() -> i32 {
  Core.Print(E(8 as i16));

  return 0;
}
```

<!-- google-doc-style-resume -->

Probe `y_E_nontemplate_fn`:

<!-- google-doc-style-ignore -->

```carbon
import Core library "io";
import Cpp inline '''
template<typename T> T Twice(T x) { return x + x; }
inline short TwiceS(short x) { return x + x; }
''';
fn E[template T: type](v: T) -> T { return Cpp.TwiceS(v); }
fn Run() -> i32 {
  Core.Print(E(8 as i16));
  return 0;
}
```

<!-- google-doc-style-resume -->

Probe `y_E_only`:

<!-- google-doc-style-ignore -->

```carbon
import Core library "io";
import Cpp inline '''
template<typename T> T Twice(T x) { return x + x; }
inline short TwiceS(short x) { return x + x; }
''';
fn E[template T: type](v: T) -> T { return Cpp.Twice(v); }
fn Run() -> i32 {
  Core.Print(E(8 as i16));
  return 0;
}
```

<!-- google-doc-style-resume -->

Probe `y_F`:

<!-- google-doc-style-ignore -->

```carbon
import Core library "io";
import Cpp inline '''
template<typename T> T Twice(T x) { return x + x; }
template<typename T> struct Acc { T total; int n; };
template<typename T> T Total(const Acc<T>& a) { return a.total; }
template<typename T> Acc<T> Start(T v) { Acc<T> a; a.total = v; a.n = 1; return a; }
''';
fn D[T: type](v: T) -> T { return Cpp.Twice(v); }
fn E[template T: type](v: T) -> T { return Cpp.Twice(v); }
fn F[T: type](v: T) -> T { var acc: Cpp.Acc(T) = Cpp.Start(v); return Cpp.Total(acc); }
fn G[template T: type](v: T) -> T { var acc: Cpp.Acc(T) = Cpp.Start(v); return Cpp.Total(acc); }
fn Run() -> i32 {
  Core.Print(F(9 as i32));

  return 0;
}
```

<!-- google-doc-style-resume -->

Probe `y_G`:

<!-- google-doc-style-ignore -->

```carbon
import Core library "io";
import Cpp inline '''
template<typename T> T Twice(T x) { return x + x; }
template<typename T> struct Acc { T total; int n; };
template<typename T> T Total(const Acc<T>& a) { return a.total; }
template<typename T> Acc<T> Start(T v) { Acc<T> a; a.total = v; a.n = 1; return a; }
''';
fn D[T: type](v: T) -> T { return Cpp.Twice(v); }
fn E[template T: type](v: T) -> T { return Cpp.Twice(v); }
fn F[T: type](v: T) -> T { var acc: Cpp.Acc(T) = Cpp.Start(v); return Cpp.Total(acc); }
fn G[template T: type](v: T) -> T { var acc: Cpp.Acc(T) = Cpp.Start(v); return Cpp.Total(acc); }
fn Run() -> i32 {
  Core.Print(G(10 as i16));

  return 0;
}
```

<!-- google-doc-style-resume -->

Probe `y_short_twice`:

<!-- google-doc-style-ignore -->

```carbon
import Core library "io";
import Cpp inline '''
template<typename T> T Twice(T x) { return x + x; }
template<typename T> struct Acc { T total; int n; };
template<typename T> T Total(const Acc<T>& a) { return a.total; }
template<typename T> Acc<T> Start(T v) { Acc<T> a; a.total = v; a.n = 1; return a; }
''';
fn D[T: type](v: T) -> T { return Cpp.Twice(v); }
fn E[template T: type](v: T) -> T { return Cpp.Twice(v); }
fn F[T: type](v: T) -> T { var acc: Cpp.Acc(T) = Cpp.Start(v); return Cpp.Total(acc); }
fn G[template T: type](v: T) -> T { var acc: Cpp.Acc(T) = Cpp.Start(v); return Cpp.Total(acc); }
fn Run() -> i32 {
  Core.Print(D(7 as i16));
  Core.Print(E(8 as i16));
  Core.Print(F(9 as i32));
  Core.Print(G(10 as i16));

  return 0;
}
```

<!-- google-doc-style-resume -->

Probe `z_short_return`:

<!-- google-doc-style-ignore -->

```carbon
import Core library "io";
import Cpp inline '''
template<typename T> struct Acc { T total; int n; };
template<typename T> Acc<T> Start(T v) { Acc<T> a; a.total = v; a.n = 1; return a; }
template<typename T> T Total(const Acc<T>& a) { return a.total; }
inline short TotalS(const Acc<short>& a) { return a.total; }
''';
fn Run() -> i32 {
  var acc: Cpp.Acc(i16) = Cpp.Start(10 as i16);
  Core.Print(Cpp.TotalS(acc));
  Core.Print(Cpp.Total(acc));
  return 0;
}
```

<!-- google-doc-style-resume -->

Probe `z_short_return2`:

<!-- google-doc-style-ignore -->

```carbon
import Core library "io";
import Cpp inline '''
inline short Get(const short& a) { return a; }
inline short Get2(short a) { return a; }
''';
fn Run() -> i32 {
  var s: i16 = 11;
  Core.Print(Cpp.Get2(s));
  Core.Print(Cpp.Get(s));
  return 0;
}
```

<!-- google-doc-style-resume -->

### D.6 gen3: the concrete twins (after the shared header)

<!-- google-doc-style-ignore -->

```carbon
// z_array_nontype
fn Run() -> i32 { var a: Cpp.Array(i32, 3); Core.Print(a.Size()); return 0; }

// z_box_point_then_id
fn Run() -> i32 { var b: Cpp.Box(Point); b.value = {.x = 9}; Core.Print(Cpp.Id(b.value).x); return 0; }

// z_id_point
fn Run() -> i32 { var p: Point = {.x = 5}; Core.Print(Cpp.Id(p).x); return 0; }

// z_id_point_lit
fn Run() -> i32 { Core.Print(Cpp.Id({.x = 6} as Point).x); return 0; }

// z_makebox_point
fn Run() -> i32 { var p: Point = {.x = 7}; Core.Print(Cpp.Unbox(Cpp.MakeBoxCpp(p)).x); return 0; }

// z_sizeof_fn
fn Run() -> i32 { Core.Print(Cpp.SizeOfFn(i32)); return 0; }

// z_sizeof_var
fn Run() -> i32 { Core.Print(Cpp.SizeOf(i32)); return 0; }

// z_twice_point
fn Run() -> i32 { var p: Point = {.x = 8}; Core.Print(Cpp.Twice(p).x); return 0; }

// z_var_template_runtime
import Core library "io";
import Cpp inline '''
template<typename T> constexpr int SizeOf = sizeof(T);
template<typename T> int Plain = sizeof(T) + 1;
inline int UseIt() { return Plain<long>; }
''';
fn Run() -> i32 { Core.Print(Cpp.Plain(i32)); Core.Print(Cpp.Plain(i64)); Core.Print(Cpp.SizeOf(i32)); return 0; }
```

<!-- google-doc-style-resume -->

gen3's other rows are the programs of Appendix B; their TP-1, trunk and
nightly columns were measured before the two un-SKIPped programs gained their
`Core.Copy` impls, which does not change the first diagnostic (E-DU, §0.2).
gen5 repeats gen4's `y_` and `z_short` probes to record the full diagnostic
texts.
