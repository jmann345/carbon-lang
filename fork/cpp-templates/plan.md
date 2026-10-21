# C++ templates on symbolic Carbon type arguments, instantiated per specific (CT-1)

<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

**Status:** rev 2, 2026-10-21 -- FOR RE-REVIEW, not signed off (plan reviews A
and B folded, 25 findings; the focused re-review decides; the fold record is
the last section before the appendices)

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
W-300..W-319 (§0.11), files W-300 to W-309, and mints fork design id F-021,
the checked-generic C++ rule (D-CT-16; amended 2026-10-21, review fold: A-M1).

The one-sentence summary: upstream already defers a C++ template named with a
symbolic argument to each specific (a `CallAction` over `TemplateInst`-wrapped
arguments, check/call.cpp:741-768), and nine defects in and around that path
keep it from working on this branch; CT-1 fixes the nine at their roots and
defers a C++ call whose argument has a checked generic's symbolic type (F-021),
in ten files and 265 added lines (13 removed), measured on a prototype (v12)
over 243 probes, the 1957 goldens, the 160 conformance programs and two
full-build composition mirrors (amended 2026-10-21, review fold: A-B1 / A-B2 /
A-B3 / B-m1; rev 1 said seven defects, seven files and 163 lines, whose
numstat was in fact +167/-11).

## §0 Audit: measurements with file:line evidence

### §0.1 Toolchains, probes and the result codes

Every probe was compiled, linked and run on four toolchains:

| Name | What | Where |
| --- | --- | --- |
| TP-1 | PR 61's head 5661a35c8 (toolchain eafca5cb9), the base of this branch | /home/user/carbon-build/carbon-tp/install (read-only) |
| trunk | the fork's trunk 6978a506e | /home/user/carbon-build/carbon-trunk/install |
| nightly | upstream's nightly 2026.10.12, the oracle for upstream behavior (R30) | /home/user/nightly/tc/carbon_toolchain-0.0.0-0.nightly.2026.10.12 |
| v11 | rev 1's prototype: TP-1 plus seven files | relinked over TP-1's objects into /dev/shm, deleted after use |
| v12 | rev 2's prototype: TP-1 plus the ten files of §2 (amended 2026-10-21, review fold: A-B1 / A-B2 / A-B3 / B-M1 / A-m3) | relinked over TP-1's objects into /dev/shm/ct1-fixer, deleted after use |
| mva | PR 61's head merged with PR 59 (VA-1, b0822a744), records conflicts taken from this branch, plus v12 (review fold: B-M3) | a scratch clone, built and installed by carbonbuild with `CB_BUILD_ROOT` in /dev/shm, deleted after use |
| msv | the same with PR 62 (SV-1, 3a6531157) (review fold: A-M3 / B-M3) | the same |

Rev 1 measured two intermediate states for the commit split (§3): c1 (v11
without check/call.cpp and check/action.cpp) and c1b (c1 plus
check/action.cpp). Rev 2's commit C1 is c1v12, v12 without check/call.cpp
(§3). TP-1, c1b, v11, v12 and c1v12 were also relinked with a file_test whose
manifest lists the two new goldens (§0.7; the rev 2 states are v12g and
c1v12g).

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
that `MapToCppType` cannot map. Of W-043's other evidence, call.cpp:127 is
stale in the same way, call.cpp:252's non-type restriction is live (W-302),
and type_mapping.cpp:560's TODO is live at :733-736 (``Support passing
form-dependent args to C++ functions.``): a C++ call with a `:?`
form-dependent argument, `fn F(generic Fm: Core.Form, x:? Fm) -> i32 { return
Cpp.TakeInt(x); }`, reports it where `F` is defined on TP-1, v11's deferral
moves it to an instantiation note (E-MONO for `F(form(val i32), v)`, and an
uncalled `F` compiles), and v12 keeps it where `F` is defined (new/n01 to n03,
§0.12; W-307; amended 2026-10-21, review fold: B-M1). Measured with each SKIP
line removed and nothing else changed:

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
among them the narrow-integer return shapes (`y_`, `z_short`). The rev 2
prototype v12 prints and reports exactly what v11 does on all 148 (re-run
2026-10-21, `$X/mx_main.tsv` with `$X` the fixer's scratch
`ct1/fixer/`), so the table's v11 column is v12's too.

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
| fixture/X34_cpp_template_symbolic_uninit (rev 1's number and `[T: Core.Copy]`; rev 2's X37 with `[T: type]` prints the same on v12 and fails on TP-1 with E-DU under PR 58's checker, Appendix C.1) | E-DU, then E-ARG | not run | not run | 42, 10 |
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
8.  A class-scope alias of a template-dependent type, `alias B = T.Inner;` in
    `class C(template T: type)` or `alias B = Cpp.Box(T);` in `class C(T:
    type)`, is checked in its own generic declaration region, which
    `HandleParseNode(AliasId)` (handle_alias.cpp:49) discards with
    `DiscardGenericDecl` (generic.cpp:453-465): the region's dependent
    instructions are unattached, so the action that the alias's expression
    formed refers to an operand, `T`'s name reference, whose constant belongs
    to no generic, and in `C(X)`'s specific the action is evaluated with `T`
    itself. Every use of `B` in a member then stays a `SpliceInst`: STOP
    lower/file_context.h:187 (``Lowering symbolic type ... SpliceInst``) for
    `var b: B = 5;` on TP-1, trunk and the nightly (f07), and E-DU for `var b:
    B;` there, which D-CT-5 turns into that stop (f06, review A's B1). **(H8)**:
    handle_alias.cpp and generic.cpp `DiscardGenericDecl` (amended
    2026-10-21, review fold: A-B1 / A-B2).
9.  A member function's declaration that names such an alias, `fn Make() -> B`
    or `fn Get(b: B)`, rebuilds the alias's constant in its own generic's eval
    block (`RebuildGenericConstantInEvalBlockCallbacks`, generic.cpp:70-176,
    through `SubstInst`); D-CT-7 leaves an action's operand that is a body
    instruction as it is, and once H8 attaches `T`'s name reference to `C`, that
    operand belongs to `C`, not to the member: STOP sem_ir/generic.cpp:84
    (``Given a specific for the wrong generic``) when the member's declaration
    is evaluated (ret_alias, c04, d01, a11, and lower/type.cpp:459 for d03 and
    d04 on TP-1, trunk, the nightly and v11). **(H9)**: subst.cpp
    `IsSubstitutedActionOperand` (amended 2026-10-21, review fold: A-B1 /
    A-B2).

The SemIR of a specialization in a checked generic, from generic_call.carbon's
dump on TP-1 (the shape v11 keeps, §0.7): `%.loc8_25.N: <instruction> =
call_action (...)`, `type_of_inst`, `splice_inst`, then `initialize_action`
over the spliced type, all `[template]`, and in the specific `%.loc8_25.N =>
constants.%inst.splice_block...` with the instantiated `S<X>` as the splice's
value. No instruction kind is added or changed (D-CT-1).

### §0.5 Root causes, measured

Over the 148 probes of §0.3, v11 (and v12) changes no probe that runs on TP-1
(39 run on both and print the same) and moves 88 from a rejection or a stop to
running (39 + 88 + 21 = 148; rev 1 said 89; amended 2026-10-21, review fold:
A-m1 / B-m1).
Of TP-1's 15 stops, 10 run on v11, 2 become Clang's own error in the
instantiated C++ (E-CXX, the right answer: `Point` has no `operator+`), and 3
remain, a concrete C++ class `var` in a template's body (W-304, §1.11). The 21
probes that do not run on v11 are each accounted for in §1.11: 5 E-MONO
(c_member_missing and t_member_missing, the right answer; g_facet_constrained
and g_facet_constrained_member, W-305; g_nontype_i64, the right answer with a
note that has no line, W-306), 2 E-UNMAPPED (W-300), 5 E-CXX (the right
answer), 1 E-TT (W-301), 1 E-COPY (the checked generic's own rule), 2 E-AS and
2 E-PARSE (the probes' own errors), and the 3 stops.

Ten root causes, each fixed where it is (R17), with the probes it stops on
TP-1 and the state that first runs them (R8 to R10 added 2026-10-21, review
fold: A-B1 / A-B2; v11's deferral of a C++ call whose argument is a symbolic
value of a concrete type, `Cpp.TakeInt(N)` for `generic N: i32`, was rev 1's
own defect, not TP-1's, and D-CT-3's narrowed predicate removes it, review
fold: A-B3):

| Root | Hook | Cause | Stops on TP-1 (trunk, nightly alike) | Fix | First runs at |
| --- | --- | --- | --- | --- | --- |
| R1 | H2 | impl lookup on a C++ specialization of a symbolic argument is resolved where the generic is defined, because `NamesTemplateBinding` (impl_lookup.cpp:578-634) neither treats a `TemplateInst` as template-dependent nor follows an action's `MetaInstId`/`MetaInstBlockId` operands | E-DU: 55 probes (49 run on v11), every uninitialized `var` of `Cpp.Box(T)`, `Cpp.Pair(Cpp.Box(T))`, `Cpp.Box(List(T))`, `Cpp.Array(i32, N)`, `Cpp.Loud(T)`, and TP-1's own W-268 (`var e: T.Elem;`, g_w268, w268_d03_var_elem) | D-CT-5 | c1 (v1 measured it alone: the E-DU class runs) |
| R2 | H3 | `ActionIsPerformable` (action.cpp:180-213) performs a C++ call or specialization whose arguments are a checked generic's symbolic values, in a template's specific evaluated for a symbolic argument | STOP generic_region_stack.h:98 (t_box_in_generic_caller), E-MONO with E-ARG's note (t_symbolic_call_in_generic_caller) | D-CT-6 | c1b (c1 still stops and rejects) |
| R3 | H4 | `SubstInst` (subst.cpp:93-260) does not substitute into an action's `MetaInstId`/`MetaInstBlockId` operands, so an action formed for a symbolic specific keeps its symbolic operands in a concrete one | STOP custom_witness.cpp:487 (s1_class_field_in_generic, s1c_construct_only; :401 on the nightly), STOP handle_expr_category.cpp:20 (s1b_param, s1d_field_var, s1e_return_box, s1f_method) | D-CT-7 | c1 |
| R4 | H7 | `PerformAction(InitializeAction)` (convert.cpp:2993-3060) hands a `return`'s initializer the function's return slot whatever the specific's return type, and a return type that is not initialized in place has no slot | STOP lower/handle_call.cpp:984 (y_E_only, y_E_nontemplate_fn; :783 on the nightly), both an `i16` through `Cpp.Twice` | D-CT-8 | c1 (v10, without it, still stops) |
| R5 | H5 | `BuildTemplateId` (cpp/call.cpp:317-324) uses the declaration form of `CheckVarTemplateId`, which leaves a specialization nothing declared at `TSK_Undeclared`, so its definition is never instantiated | L-UNDEF: c_var_template, t_var_template, z_sizeof_var, z_var_template_runtime, cpp_var_template_runtime; concrete uses too | D-CT-9 | c1 (v8) |
| R6 | H6 | `IsMoveEquivalentToCopy` (overload_resolution.cpp:157-190) reads the special members of an exported Carbon class whose definition the external AST source has not produced yet | STOP clang assertion (DeclCXX.h:464): z_id_point_lit (concrete: `Cpp.Id({.x = 6} as Point)`), c_bad_inst, t_bad_inst; a segfault on the nightly | D-CT-10 | c1 (v3) |
| R7 | H1 | a call to an imported C++ function with an argument of a checked generic's symbolic type is performed where the generic is defined, and `T` has no C++ type there | E-ARG: 22 probes that run on v11 (c_fn_template_call, c_fn_template_explicit, c_method_call, c_pass_to_cpp, c_return_spec, the `y_` and gen3 call programs, ...) | D-CT-3 | v11 (c1b still rejects) |
| R8 | H8 | an alias's value in a generic is checked in the alias's own generic declaration region, which `DiscardGenericDecl` discards, so the instructions an action of the alias's expression refers to are attached to no generic and are not evaluated in the enclosing generic's specific (added 2026-10-21, review fold: A-B1 / A-B2) | E-DU (f06, d07, a11, c04, cls_alias_var, n14, n16, fn_alias), STOP lower/file_context.h:187 for the initialized form (f07, cls_alias_init) and STOP custom_witness.cpp:487 for an alias field (d08, cls_alias_field_generic_use), on TP-1, trunk and the nightly; TP-1's own W-273 (deduce_class_args.carbon's `fail_todo_class_template_field_of_where_alias`, n13); with v11's D-CT-5 the E-DU forms stop at file_context.h:187 or sem_ir/generic.cpp:84 | D-CT-17 | v12 |
| R9 | H9 | an action formed in an enclosing generic and rebuilt in a member's eval block keeps an operand that belongs to the enclosing generic, which the member's specific cannot evaluate (added 2026-10-21, review fold: A-B1 / A-B2) | STOP lower/file_context.h:187 or lower/type.cpp:459 on TP-1, trunk and the nightly for an alias in a member's signature (ret_alias, n15, d03, d04); after D-CT-17 alone, STOP sem_ir/generic.cpp:84 (c04, d01, a11) | D-CT-7 (amended) | v12 |
| R10 | H2 | a name reference to an alias is a body instruction whose operands do not reach what the alias names, so `NamesTemplateBinding` does not see the specialization's `TemplateInst` through `var b: B;` for `alias B = Cpp.Box(T)` in a checked class (added 2026-10-21, review fold: A-B2) | E-DU on every toolchain and on v11 (a11, cls_alias_var) | D-CT-5 (amended) | v12 |

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

### §0.7 Prototype v12 and its gate

Rewritten 2026-10-21 (review fold: A-B1 / A-B2 / A-B3 / B-M1 / B-M2 / A-M5 /
A-m3 / B-m1). v12 is TP-1 plus the ten-file diff of §2 (265 lines added, 13
removed; rev 1's v11 was seven files, +167/-11, its convert.cpp +18/-6). The
gate, file_test over this tree's 1957 goldens with TP-1's runfiles (the
container arbiter's gate.sh shape), on TP-1: 1957 of 1957. On v12 and on the C1
state c1v12: 1951 of 1957 (rev 1's v11, c1 and c1b: 1953, the first four rows
below), the red set exactly:

| Golden | Why it changes | The change (autoupdate on a scratch mirror, a fixpoint: a second run changes nothing) |
| --- | --- | --- |
| check/interop/cpp/template/generic_call.carbon | D-CT-5: `var unused v: Cpp.S(T);`'s `DefaultOrUnformed` lookup is formed in the specific, not where `F` is defined | `require_specific_def @T.as.DefaultOrUnformed.impl(%.537) [template]` and its specific's `%.e53` leave the definition; the prelude's `T.as_type.as.DefaultOrUnformed.impl` constants move to the specific's block; the `loc8_25` instruction numbers shift by one; +26/-30 lines |
| check/interop/cpp/template/non_type_param.carbon | D-CT-9: `Cpp.X(i32, i32).n(1, 2)` now instantiates `X<int, int>::n<1, 2>`, which has no definition | split dependent_parameter_pack gains Clang's warning ``instantiation of variable 'X<int, int>::n<1, 2>' required here, but no definition is available [CppInteropParseWarning]`` with its two notes, the same as clang++ (§0.3); +10 lines |
| check/interop/cpp/template/var_template.carbon | D-CT-9: `struct Wrap { template<typename T> static T var = {}; };` is ill-formed C++ once instantiated (clang++ rejects it identically, §0.3) | the header becomes `static inline T var = {};` (valid C++, the test's intent: read a static member template), and a new split pins the ill-formed form (Appendix A.3); +25/-1 lines (rev 1 said +18/-1) |
| lower/interop/cpp/globals.carbon | D-CT-9: the variable template specializations are defined | the header's `static T static_tmpl = T();` becomes `static inline T static_tmpl = T();` for the same reason; `@_Z4tmplIiE` and `@_Z4tmplI1YE` change from `external global` to `linkonce_odr dso_local global` with a guard variable and `__cxx_global_var_init`, and the same for `StaticTmplX::static_tmpl`; debug metadata numbers shift; +220/-160 lines |
| check/generic/template/deduce_class_args.carbon | D-CT-17: the class-scope alias `alias FT = HasItem where .Item = T.Item;` of `class D(template T: HasItem)` is attached to `D`, so `D(Holder)`'s object representation is concrete and the literal converts; TP-1's W-273 | the split `fail_todo_class_template_field_of_where_alias` succeeds, so its source line is renamed `class_template_field_of_where_alias` (Appendix A.6) and the fill drops its seven STDERR lines; +1/-8 lines |
| check/interop/cpp/range_for.carbon | D-CT-17: the prelude's `alias ValueType = Self.(Iterator).(CppIterator.ValueType);` (core/prelude/iterate.carbon:63) is attached to its interface, so the deleted-`begin` and deleted-`end` notes it reaches on instantiation are located at the expression, column 25, not at the alias's name, column 9 | four notes move from `iterate.carbon:63:9` to `:63:25` and their carets from `^~~~~~~~~` to `^`; no diagnostic is added or removed; +8/-8 lines |

The two new goldens (Appendix A.1 and A.2) and the two default_init.carbon
splits of Appendix A.5 were filled the same way, with a file_test relinked over
a copy of the build's generated manifest
(gen/toolchain/testing/file_test_autogen_manifest.cpp) that lists the two new
files, on a scratch mirror of this tree's testdata with the source edits of
Appendix A.3 to A.6 applied (`$X/gm`): the first autoupdate run fills, the
second moves quoted line numbers once, and a third changes nothing (1129 and
1578 lines for A.1 and A.2; rev 1's 911 and 1339). In test mode the nine changed
or new goldens pass on v12g, and every check and lower golden of the mirror
passes (1478 of 1478; the mirror holds no other testdata). The refills
are +26/-30 (generic_call), +10 (non_type_param), +25/-1
(var_template), +220/-160 (globals), +1/-8 (deduce_class_args), +8/-8
(range_for) and +45 source lines with no CHECK line (default_init). On c1v12g
the C1 subset of A.1 and A.2 (fourteen and six splits, 804 and 1211 lines)
reaches the same fixpoint, and its every split fills identically to v12g's fill
of the full files, except the lower file's debug metadata numbers, which depend
on the modules compiled beside each split; the other seven goldens fill
byte-identically; so C2 changes nothing that C1 pins. On TP-1 the file_test
process stops on A.1 and A.2 (the clang assertion of R6 and STOP
generic_region_stack.h:98), so the two files fail as a whole without CT-1, and
default_init.carbon and deduce_class_args.carbon fail on their new and renamed
splits; §8's mutants name the split that kills each change (amended 2026-10-21,
review fold: A-B1 / A-B2 / A-B3 / A-M1 / A-M5 / B-M1 / B-M6 / B-m6).

Two rejected prototype states: v2 converted every value argument to a
`TemplateInst`-typed value (STOP type_completion.cpp:348 on its first probe),
and v9 substituted into every action operand (25 goldens changed, among them
check/array/init_dependent_bound.carbon, class/destroy_calls.carbon,
eval/call.carbon, generic/template/convert.carbon and default_init.carbon,
because an action that refers to an instruction of the generic's body must keep
referring to it); v10 restricts the substitution to operands that are
themselves constant instructions and changes no golden beyond the four. v12
widens v10's rule by one case, an operand that belongs to another generic than
the one whose eval block is being built (D-CT-7, H9), and the gate shows no
change beyond the six rows above.
v4 to v6 tried to instantiate the variable template's definition elsewhere
(ineffective: the specialization kind stayed `TSK_Undeclared`); v7 is D-CT-9.

### §0.8 Conformance under rows 56 and 42

The runner (fork/conformance/runner.py, `--toolchain` the install's busybox,
`--programs` a scratch copy, `--out` scratch) over this tree's 160 programs on
TP-1: 138 PASS / 0 FAIL / 22 SKIP, 48 of 56 bullets PASS and 8 SKIP. On v11 with
the programs of §1.14 (the two un-SKIPped, seven new): 147 / 0 / 20 over 167, 48
of 56 bullets; on v12, with the differential program's values changed to wrap in
`short` (Appendix B; review fold: B-m7), the same 147 / 0 / 20 over 167 and 48
of 56 bullets (re-run 2026-10-21, `$X/conf_out_v12`), the differential pair
printing `60000`, `-5536`, `3` on both sides. Both bullets were already PASS (a
SKIP does not count against a bullet) and stay PASS; their program lists grow:

| Bullet (gap row) | TP-1 programs | v11 programs |
| --- | --- | --- |
| Generics: C++ interop — importing C++ templates, instantiating on Carbon types (56) | cpp_template_builtins, cpp_template_carbon_class, cpp_template_symbolic_arg (SKIP) | the same three, cpp_template_symbolic_arg PASS, and cpp_template_carbon_generic_spec, cpp_template_fn_symbolic, cpp_template_nested_symbolic, cpp_template_spec_roundtrip, cpp_template_symbolic_diff (differential), cpp_template_two_specifics, cpp_var_template_runtime |
| Type system: C++ interop — importing C++ types / exporting Carbon types (42) | cpp_template_on_carbon_generic (SKIP), cpp_type_export_carbon_class, cpp_type_import_class_enum | the same, cpp_template_on_carbon_generic PASS |

Relative to the trunk floor of record (128 / 0 / 22 over 150), this branch's
tree is +19 PASS, -2 SKIP, +17 programs: TP-1's ten programs and CT-1's nine
changes.

### §0.9 Collisions with the held PRs

Rewritten 2026-10-21 (review fold: A-M3 / B-M3). Each held PR's own diff
(merge-base with trunk 6978a506e to its head) over toolchain/check/cpp and
CT-1's ten files, from `git diff --numstat`, was applied to a `git archive` of
this branch's toolchain/check and v12's diff then dry-run onto the result
(`$X/dry/<pr>/`); rev 1 dry-ran onto TP-1's and v11's files only. No held PR
touches generic.h, generic.cpp, handle_alias.cpp, subst.cpp, action.cpp,
cpp/call.cpp or cpp/overload_resolution.cpp. The two PRs whose semantics meet
CT-1's, PR 59 and PR 62, were composed as full-build mirrors (mva and msv,
§0.1) and gated over their own testdata; PR 60's composition is predicted,
because TP-1's own resolution of PR 60 at its merge M (commit S of
fork/templates/plan.md §0.9) is not yet written:

| Held PR (head) | check/cpp and CT-1's files (numstat) | PR onto TP-1, then v12 | Composed and gated | Rule at CT-1's merge |
| --- | --- | --- | --- | --- |
| PR 51 (UA-2, f96fe8a7a) | none; the two SKIP programs (C-1) and dependent_var_full_prelude.carbon (C-2) | n/a | not composed | C-1, C-2 |
| PR 52, 53, 54, 56 | none | n/a | not composed | none |
| PR 55 (ST-1, 21307851a) | cpp/export.cpp +5 (the null check of §0.6) | applies; v12 has no export.cpp hunk | not composed | textual only |
| PR 57 (OP-2, 628273444) | convert.cpp +5/-2 | applies; v12's convert.cpp hunk at offset 3 | not composed (no shared function) | textual only |
| PR 58 (DD-1, fcee90d9b) | none in the toolchain; the interop design page, W-043's notes, gap rows | n/a | the land-time L measured on a PR 58 mirror (C-3, Appendix C.1) | C-3 |
| PR 59 (VA-1, b0822a744) | call.cpp +194, convert.cpp +114, cpp/export.cpp +12 | applies; v12's call.cpp hunk at offset 184, convert.cpp at 114 | mva: 1969 of 1975, the red set exactly CT-1's six goldens of §0.7; probes va1 to va5 below | the land-time code commit S-VA (§3 item 13): D-CT-3 refuses a pack expansion argument |
| PR 60 (SC-1, 40a76ab81) | call.cpp +14, convert.cpp +94/-7, impl_lookup.cpp +44/-13 | two of PR 60's convert.cpp hunks fail on TP-1 (TP-1's own conflict, which its M resolves), then v12 applies with offsets 1 to 20 | predicted (below) | TP-1's M resolution, unchanged; prediction re-measured at CT-1's M |
| PR 61 (TP-1) | the base | n/a | n/a | CT-1 is stacked on it |
| PR 62 (SV-1, 3a6531157) | convert.cpp +23/-7, cpp/custom_type_mapping.{h,cpp} +81, cpp/sum_type.{h,cpp} +1128 (new), cpp/type_mapping.{h,cpp} +20/-2 | applies; v12's convert.cpp hunk at offset 16 | msv: 1959 of 1965, the red set exactly CT-1's six goldens; probes sv1 to sv8 below | textual only; the sum-type forms are OUT rows of §1.11 (W-279, W-252) |

**PR 59 (VA-1), measured on mva** (`$X/probes/va`; TP-1 and v12 do not parse
the pack syntax, ``expected identifier or `Self` after `.` ``, so the
comparison is VA-1's own build, vab). D-CT-3 runs before
`PerformCallHelper`, whose VA-1 check reports a pack expansion argument to a
non-Carbon callee (``pack expansion argument is not matched by a pack
expansion parameter``, D-VA-5): `Cpp.Sum(... each x)` in `fn F[T: type](...
each x: T)` and `Cpp.TakeInt(... each x)` in `fn F(... each x: i32)` are that
error on vab, and on mva without S-VA they are deferred, an uncalled `F`
compiles and a call is E-MONO with the note ``call argument of type `«i32; 2»`
is not supported`` (va1, va2, va5). With S-VA's refusal (Appendix C.11's hunk,
measured on mva) the three report VA-1's error again, where the call is
written. A C++ call inside an expansion body, `... Cpp.Add(each x);` with `x:
T`, is deferred per element and prints 7 for `F(3 as i32, 4 as i32)` (va3), and
`Cpp.Twice(x)` prints 42 (va4), with and without S-VA.

**PR 62 (SV-1), measured on msv** (`$X/probes/sv`; svb is SV-1's own build).
A `Cpp.std.optional(T)` of a checked generic is IN on msv as on v12:
`has_value()` after `make_optional` prints 1 (sv1, e08), the default `var o:
Cpp.std.optional(T);` prints 0 (sv2, e09), and a C++ function template
returning `std::optional<T>` prints 1 (sv6); svb rejects each where the generic
is defined (E-ARG or E-DU). Converting that value to a Carbon type is SV-1's
conversion, which runs only inside a function body that is not instantiated
later: `return o;` into `Core.Optional(i32)` from `fn F[T: type]`, or into
`Core.Optional(T)` from `fn F[template T: type]`, is E-MONO with SV-1's note
``semantics TODO: `conversion of a C++ `std::optional` or `std::variant`
outside a function body (at file scope, or deferred to a template's
instantiation)` `` (W-279; sv3b, sv3c; an uncalled `F` compiles, sv8), and
`match (o)` is TP-1's ``semantics TODO: `match on unsupported scrutinee type` ``
where `F` is defined (W-252; sv4). `Core.Optional(T)` for a checked `T` is
rejected where it is written on every build, because `T` does not implement
SV-1's private `OptionalStorage` (sv3). The concrete `std::optional<int>` to
`Core.Optional(i32)` prints 1 on svb and msv (sv5). Nothing stops.

**PR 60 (SC-1), predicted.** SC-1's template constraints (`template constraint`
with member requirements, W-027, /home/user/carbon-sc's fork/structural/plan.md)
are checked on instantiation of a template binding; a checked generic's `T` is
not a template binding, so CT-1's deferred C++ forms in checked generics do not
meet them. In a template constrained by a template constraint, D-CT-6 and D-CT-7
change only when a C++ call or specialization of the template's specific is
performed (TR-22's form), not how SC-1 checks the requirement. Predicted: the
composed mirror's red set is TP-1's red set at its M with SC-1 (scv13b's,
fork/templates/plan.md §0.9) plus CT-1's six goldens, and SC-1's
template-constraint goldens are unchanged. _Break condition:_ a golden of SC-1
changes in that mirror, or a probe of a template constraint over `Cpp.Box(T)`
(`fn F[template T: C](x: T)` with `C` a template constraint and `var b:
Cpp.Box(T);`) behaves differently on the mirror from TP-1 plus SC-1 without CT-1
(§8 item 9 measures both).

No held PR touches the six goldens CT-1 refills or the two whose sources CT-1
edits (default_init.carbon, deduce_class_args.carbon). Three content
collisions:

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
2026-10-21). Rev 1 said that none touches check/testdata/interop/cpp/template
and that only two touch CT-1's code; both claims were false (amended
2026-10-21, review fold: A-M2 / B-m3). `git log c1e83b0b7..upstream/trunk --
<path>` per file CT-1 changes, with an overlap verdict for each:

| File (CT-1's decisions) | Upstream commits since the cut | Verdict |
| --- | --- | --- |
| check/impl_lookup.cpp (D-CT-5) | 77fc0a3ef, f0b030f2c, 2c9739799, 831a2aee9, 5402b4c56, 24766e213, 46e7eacba, b1de0e037 | adjacent: none touches `NamesTemplateBinding`, which is TP-1's (D-TP-12); the textual merge is TP-1's |
| check/action.cpp (D-CT-6) | 0d3b606a5 (PR 7981), 4a8993af2 (PR 7900) | overlapping: 4a8993af2 adds a `None` guard to `OperandDependenceInSpecific(MetaInstId)`, which D-CT-6 calls with an argument that always has a value, and to `RefineTypedOperand(MetaInstId)`; compatible |
| check/subst.cpp (D-CT-7) | 24766e213 (PR 7930), eb66bebc3 (PR 8003) | overlapping in the same switch: both change `PopOperand`'s `SpecificId` case (the `identified` flag), beside D-CT-7's new `MetaInstId` and `MetaInstBlockId` cases; a textual conflict is likely, the semantics independent |
| check/convert.cpp (D-CT-8) | 7beb29f8b (PR 7967), 2c9739799, 230227264 (PR 7886), 059ee7b9e, 4a8993af2 (PR 7900), 947c1eb52 | overlapping: 4a8993af2 adds a storage access block to `InitializeAction` (typed_insts.h) and rewrites how `PerformAction(InitializeAction)` places storage, the code D-CT-8 conditions and TP-1's D-TP-2/D-TP-3 own; 230227264 decides the caller side of return storage |
| check/cpp/call.cpp (D-CT-9) | 2c9739799, 62f1cc6a3 (PR 7953) | adjacent: a rename and diagnostic rendering, not `BuildTemplateId` |
| check/cpp/overload_resolution.cpp (D-CT-10) | 2c9739799 | adjacent |
| check/call.cpp (D-CT-3) | 0d3b606a5, 3af25cc1b, 7beb29f8b, 2c9739799, bf5d2a2ac, 62f1cc6a3, 230227264 | adjacent: all in `PerformCallToFunction` and its callers' return storage, none in `PerformCall`'s C++ path |
| check/generic.cpp, generic.h (D-CT-17) | eb66bebc3, 2b2a78ca1 (PR 7932), 24766e213 | adjacent: 2b2a78ca1 changes `RebuildGenericConstantInEvalBlockCallbacks` and `AddGenericConstantInstToEvalBlock`, which `AttachDependentInstToCurrentGeneric` uses; none changes `DiscardGenericDecl` |
| check/handle_alias.cpp (D-CT-17) | none | none |
| testdata interop/cpp/template | 2c9739799 (argument_count, non_type_param, template_template_param, type_param), 24766e213 (argument_count, concept, generic_call, non_type_param, template_template_param, type_param), 62f1cc6a3 (concept, non_type_param), 4a8993af2 (generic_call) | overlapping: generic_call.carbon and non_type_param.carbon are CT-1 refills; var_template.carbon is not touched |
| testdata interop/cpp/range_for.carbon | 4441c5340 (PR 8005, 214 lines), 7beb29f8b, 2c9739799, 5402b4c56, 24766e213, 62f1cc6a3, df3cf9294 | overlapping: a CT-1 refill; 4441c5340 also rewrites eval.cpp's `GetConstantValue`, whose `MetaInstId` overload TP-1's actions and CT-1 rely on |
| lower testdata interop/cpp/globals.carbon | none | none |

7beb29f8b ("Use a fallback loc for diagnostics generated on canonical insts",
upstream PR 7967) is the class W-306 belongs to. Nothing in CT-1 contradicts an
accepted proposal or a leads decision (V-3); F-021 (D-CT-16) records where the
fork goes beyond them.

V-3a divergence-risk register entries (reviewed at each upstream merge; the
merge rule of each entry is what the merge does when upstream's side lands):

-   `NamesTemplateBinding` treats a `TemplateInst` as naming a template binding,
    walks `MetaInstId`/`MetaInstBlockId` operands, and follows each operand's
    constant value (D-CT-5). Upstream has no `NamesTemplateBinding` (it is
    TP-1's D-TP-12); on an upstream merge that lands its own deferral of
    template-dependent impl lookup, keep upstream's and re-measure E-DU's probes
    and A.1's `alias_of_specialization`.
-   `DeferCppCallOnSymbolicArgs` in check/call.cpp (D-CT-3, F-021) and the
    C++-callee clause of `ActionIsPerformable` (D-CT-6): upstream diagnoses
    E-ARG today; if upstream lands deferral of C++ calls on symbolic arguments,
    keep upstream's, drop these, and re-decide F-021 against upstream's rule.
-   The `MetaInstId`/`MetaInstBlockId` cases of `SubstInst` (D-CT-7), a fix to
    upstream code that upstream may land differently (trunk and the nightly
    stop the same way); on merge keep whichever substitutes an action formed
    for a symbolic specific and an operand of another generic and leaves body
    operands; 24766e213 and eb66bebc3 edit `PopOperand` beside these cases:
    take upstream's `SpecificId` case and keep CT-1's two cases after it.
-   `PerformAction(InitializeAction)`'s return-slot condition (D-CT-8), in
    TP-1's code. 4a8993af2 (upstream PR 7900) adds a storage access block to
    `InitializeAction` and places storage through it: at that merge take
    upstream's block, re-apply D-CT-8's condition (the return slot only when
    the specific's type `MightBeInPlace`) to the storage upstream places,
    and re-measure A.2's `narrow_return_template`, `narrow_return_checked` and
    `class_return`; 230227264 decides the caller side and stays upstream's.
-   The `TSK_ImplicitInstantiation` marking in `BuildTemplateId` (D-CT-9), a fix
    to upstream code for upstream's L-UNDEF.
-   The completion and the `CARBON_CHECK` in `IsMoveEquivalentToCopy`
    (D-CT-10), a fix to upstream code for an assertion trunk and the nightly
    share.
-   `DiscardGenericDeclIntoEnclosingGeneric` and its call in handle_alias.cpp
    (D-CT-17), a fix to upstream code (trunk and the nightly stop on f07): if
    upstream lands its own attachment of an alias's value, keep upstream's and
    re-measure deduce_class_args.carbon, range_for.carbon and A.1, A.2.
-   The source edits of two upstream goldens, the `static inline` headers of
    check/interop/cpp/template/var_template.carbon (A.3, with its new split
    `fail_non_inline_static_member_template`) and
    lower/interop/cpp/globals.carbon (A.4), and the refills of upstream's
    generic_call.carbon, non_type_param.carbon and range_for.carbon: at an
    upstream merge take upstream's file, re-apply A.3's and A.4's source lines
    if upstream's headers are still ill-formed C++, and refill with autoupdate
    (an upstream change to these files, 24766e213, 4a8993af2, 62f1cc6a3,
    2c9739799 and 4441c5340 above, is never merged by hand).

### §0.11 Id allocation and re-scan

CT-1 reserves W-300..W-319 and files W-300..W-309 (§1.12), leaving W-310..W-319
unused and never reused (rev 1 filed W-300..W-306; amended 2026-10-21, review
fold: A-M4 / B-M1). The re-scan, run before writing this plan and again
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

Result on 2026-10-21 (67 origin refs, 16 worktrees), and again for rev 2 on
2026-10-21 without the fetch: no W-300..W-319 anywhere outside this plan; the
highest id in any ledger is W-298 (TP-1's, PR 61), W-299 being TP-1's reserved
and unused id. F-021 is not used in any tree's fork/decision-log.md (a grep of
every worktree's log for `F-02[1-9]` finds none); rev 2 mints it (D-CT-16).

### §0.12 Rev 2's probes (the plan reviews' and the fold's)

Added 2026-10-21 (review fold: A-B1 / A-B2 / A-B3 / A-M1 / A-M3 / A-M4 / A-m4 /
B-M1 / B-M3 / B-M6). Each probe was compiled, linked and run on TP-1, trunk,
the nightly, v11 and v12 by `$X/bin/one.sh` (`$X` is the fixer's scratch
directory, scratchpad/ct1/fixer; review A's sources are `$X/probes/ra`, the
fold's are `$X/probes/new`, `al`, `w`, `va` and `sv`; the tables are
`$X/mx2.tsv`, `$X/mx_form.tsv` and `$X/mx_v12final.tsv`). Codes are §0.1's;
E-DU covers trunk's and the nightly's spelling of the same diagnostic. Review
A's 73 probes and the fold's 22 run on v12 as below or as on v11; every other
review probe prints or reports the same on v11 and v12.

<!-- google-doc-style-ignore -->

| Probe (what it is) | TP-1 | trunk | nightly | v11 | v12 |
| --- | --- | --- | --- | --- | --- |
| ra/f06 (`alias B = T.Inner;` in `class C(template T: type)`, `var b: B; b = 5;` in a member) | E-DU | E-DU | E-DU | STOP lower/file_context.h:187 | 5 |
| ra/f07 (the same, `var b: B = 5;`) | STOP lower/file_context.h:187 | the same | STOP file_context.h:127 | STOP file_context.h:187 | 5 |
| ra/d07 (`alias B = Cpp.Box(T);` in a class template, `var b: B;` in a member) | E-DU | E-DU | E-DU | STOP file_context.h:187 | 17 |
| ra/c04 (the same, `-> B` and `var b: B;`) | E-DU | E-DU | E-DU | STOP file_context.h:187 | 11 |
| ra/a11 (`alias B = Cpp.Box(T);` in `class C(T: type)`, `-> B` and `var b: B;`) | E-DU | E-DU | E-DU | E-DU | 11 |
| al/cls_alias_var (the same, `var b: B;` only) | E-DU | E-DU | E-DU | E-DU | 2 |
| ra/d01 (the checked alias as a return type, `return Cpp.MakeBoxCpp(v);`) | E-ARG | E-ARG | E-ARG | STOP file_context.h:187 | 11 |
| ra/d08 (the checked alias as a field's type) | STOP custom_witness.cpp:487 | the same | STOP custom_witness.cpp:401 | ``cannot implicitly convert ... `{.b: Cpp.Box}` to `C(i32)` `` | 18 |
| ra/d03, ra/d04 (the alias as a parameter's type, checked and template class) | STOP lower/type.cpp:459 | the same | STOP lower/type.cpp:452 | STOP lower/type.cpp:459 | 13, 14 |
| misc/ret_alias (pure Carbon: `alias B = T.Inner;`, `fn Make() -> B`) | STOP file_context.h:187 | the same | STOP file_context.h:127 | STOP file_context.h:187 | 5 |
| new/n15 (pure Carbon: `alias E = T.Elem;`, `fn Make(v: E) -> E`) | STOP file_context.h:187 | the same | STOP file_context.h:127 | STOP file_context.h:187 | 17 |
| new/n14 (pure Carbon: `alias E = T.Elem;`, `var e: E;` in a member) | E-DU | E-DU | E-DU | STOP file_context.h:187 | 16 |
| al/fn_alias, new/n16 (`alias B = Cpp.Box(T);` in a checked function's body) | E-DU | E-DU | E-DU | STOP sem_ir/generic.cpp:84 | 1, 18 |
| al/cls_alias_init (`var b: B = Cpp.Box(T).Box();` through the checked alias) | STOP file_context.h:187 | the same | STOP file_context.h:127 | STOP file_context.h:187 | 3 |
| al/cls_alias_field_generic_use (a field of the alias's type read in a checked generic) | STOP custom_witness.cpp:487 | the same | STOP custom_witness.cpp:401 | ``cannot implicitly convert ... `{.b: Cpp.Box}` `` | 5 |
| new/n13 (TP-1's W-273 shape k14, deduce_class_args.carbon's split) | W-273's ``cannot implicitly convert`` | STOP custom_witness.cpp:487 | STOP custom_witness.cpp:401 | W-273's | 3 |
| ra/f01 (`alias B = T.Inner;` for a Carbon class `Inner` without a default, `var b: B;`) | E-DU | E-DU | E-DU | STOP file_context.h:187 | E-MONO, ``cannot access member of interface `Core.DefaultOrUnformed` in type `Inner` ``, as its function twins ra/f02 and ra/f04 on every toolchain |
| ra/b01 (`return Cpp.TakeInt(N, N);` for `generic N: i32`, never called) | ``no matching function for call to 'TakeInt'`` | the same | the same | 1 | the same as TP-1 |
| ra/b02 (`let b: bool = Cpp.TakeInt(N);`, never called) | ``cannot implicitly convert ... `i32` to `bool` `` | the same | the same | 1 | the same as TP-1 |
| ra/b03 (b01, called) | ``no matching function`` | the same | the same | E-MONO | the same as TP-1 |
| new/n09 (`Cpp.TakeInt(N)`, called) | 113 | 113 | 113 | 113 | 113 |
| new/n07 (`Cpp.GetN(N)` for `template<int N> int GetN()`) | E-NOMATCH | E-NOMATCH | E-NOMATCH | E-MONO | E-NOMATCH; the concrete `Cpp.GetN(12)` is E-NOMATCH on every toolchain (n08) |
| new/n01, n02 (`Cpp.TakeInt(x)` for `x:? Fm`, called with `form(val i32)` and `form(var i32)`) | the form-dependent TODO | the same | the same | E-MONO with the TODO as a note | the TODO, where `F` is defined |
| new/n03 (the same, never called) | the TODO | the same | the same | 7 | the TODO |
| ra/g01, new/n10 (`let b: bool = G(Cpp.TakeInt(Cpp.Twice(x)));` for `x: T`, never called) | E-ARG | E-ARG | E-ARG | 1, 14 | 1, 14 |
| new/n11 (the same, called) | E-ARG | E-ARG | E-ARG | E-MONO, ``cannot implicitly convert ... `i32` to `bool` `` | the same as v11 |
| new/n12 (its concrete twin, `x: i32`) | ``cannot implicitly convert ... `i32` to `bool` `` | the same | the same | the same | the same |
| ra/a03 (`Cpp.Over(x)` for a non-template overload set on `i32`, `f64`, `i64`) | E-ARG | E-ARG | E-ARG | 1 2 3 | 1 2 3 |
| new/n04 (`b.value = v;` into `Cpp.Box(T)` with `T` = a class without `Core.Copy`) | E-DU | E-DU | E-DU | E-MONO, ``cannot copy value of type `NoCopy` `` | the same as v11 |
| new/n05 (the same body, never called) | E-DU | E-DU | E-DU | 9 | 9 |
| new/n06 (the same with `[T: Core.Copy]`) | E-DU | E-DU | E-DU | 10 | 10 |
| ra/e02e (`choice Ch(T: type) { A(b: Cpp.Box(T)), B }`, declared only) | STOP sem_ir/generic.cpp:84 | the same | a choice TODO | STOP generic.cpp:84 | 2 |
| ra/e02 (that choice's `A` used in a checked generic) | STOP generic.cpp:84 | the same | a choice TODO | STOP generic.cpp:84 | E-MONO, ``choice alternative payload type `Cpp.Box` is not trivially copyable and destructible in this specific`` |
| ra/e02f (`Ch(i32).B`) | STOP generic.cpp:84 | the same | a choice TODO | STOP generic.cpp:84 | ``binding pattern has incomplete type `Ch(i32)` `` with that note |
| ra/e02b (the concrete payload `Cpp.Box(i32)`) | ``semantics TODO: `choice alternative payload that is not trivially copyable and destructible` `` | the same | a choice TODO | the same | the same |
| ra/c09 (`impl forall [T: type] Cpp.Box(T) as Size`) | STOP generic.cpp:84 | the same | the same | the same | `` `impl` with unused generic binding `` |
| ra/a06, c06, c07 (a tuple, struct or array of `Cpp.Box(T)` as a `var`) | E-DU | E-DU | E-DU | E-MONO | E-MONO; the concrete twin c01 is E-DU on every toolchain |
| ra/a07 (a tuple of `Cpp.Box(T)` returned) | E-DU | E-DU | E-DU | 7 4 | 7 4 |
| w/w6, w/w9 (a temporary of `Cpp.Loud(T)` from `Cpp.MakeLoud(v)`, discarded or `let`-bound, in a template) | 0, 3 0 | not run | 0, 3 0 | 0, 3 0 | 0, 3 0 |
| w/w7 (the discarded temporary in a checked generic) | E-ARG | not run | E-ARG | not run | 0 |
| w/w5, w/w8 (their concrete twins) | 1, 3 1 | not run | 1, 3 1 | not run | 1, 3 1 |
| w/w10 (a `var` of `Cpp.Loud(T)` from the call, in a checked generic) | E-ARG | not run | E-ARG | not run | 3 1 |
| w/w274_n01i, w274_x04 (TP-1's W-274 shapes) | STOP sem_ir/generic.cpp:96, E-MONO | not run | not run | not run | the same as TP-1 |
| ra/e08, e09 (`Cpp.std.optional(T)`, `has_value()` after an initializer, and default-initialized) | 1, E-DU | 1, E-DU | 1, E-DU | 1, 0 | 1, 0 |
| ra/h01 (PR 51's W-127 split shape) | E-DU | E-DU | E-DU | 1 | 1 |

<!-- google-doc-style-resume -->

Two facts from the table that no rev 1 row showed. The alias rows stop or
report E-DU on TP-1, trunk and the nightly with no C++ in them (ret_alias,
n14, n15, f07): the defect is upstream's alias handling (R8, R9), which TP-1's
actions expose, and v11 only removed the E-DU that hid it. And a temporary of a
C++ class with a destructor that a deferred C++ call returns is never destroyed
when it is discarded or `let`-bound, in a template on TP-1 and on the nightly
(w6, w9 print 0 where their twins print 1), and so in a checked generic on v12
(w7); a `var` is destroyed (w10). That is the template lane's defect, filed as
W-309 (§1.11), not caused by CT-1.

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

### §1.2 The checked-generic rule (D-CT-2, F-021)

Restated 2026-10-21 (review fold: A-M1 / B-M6). Rev 1 called this upstream's
rule with no design choice in it, and its break condition was falsified: review
A's g01 defers a Carbon-only operation, `G(...)` and the conversion to `bool`,
that TP-1, trunk and the nightly diagnose where the generic is defined (E-ARG
there; v11 and v12 accept the uncalled body). Proposal 2200 lists a checked
generic calling a template as future work (p002200:1089-1096, which points to
leads issue 2153), leads issue 2153 decided only that it may
(appendix-witness.md:149-155; overview.md:375-379), and upstream itself
diagnoses a C++ function call with a symbolic argument (E-ARG). So the rule is
the fork's, F-021 (D-CT-16).

**D-CT-2 (F-021). In a checked generic, three kinds of expression are checked
for each specific, as a template's dependent expressions are (TP-1's TR-3):
a C++ template named with a symbolic argument (`Cpp.Box(T)`), a call to an
imported C++ function with an argument whose type is a checked generic's
symbolic type or that is such a type (`Cpp.Twice(x)`, `Cpp.SizeOfFn(T)`;
D-CT-3), and every operation on a value of a type the first forms or that the
second returns, Carbon operations included (TR-4). Every other expression of
the generic is checked where the generic is defined (TR-2), with the generic's
constraints. An error found for a specific is reported on instantiation, at
the call that names the specific, with a note at the operation.** C++ declares
nothing a definition could be checked against: a member of `Box<T>` and the
result type of `Twice<T>` exist only for a known `T`. The cost of the rule is
that a library author sees an error in such an expression only when a caller
instantiates it, and that it reaches the Carbon operations that consume the
expression's value (the contagion of review A's g01: `let b: bool =
G(Cpp.TakeInt(Cpp.Twice(x)));` is reported on instantiation, n11, where its
concrete twin n12 is rejected where it is written). Each operation and the
rule it rides:

| Operation (on `b: Cpp.Box(T)` or a C++ call's result, `T` checked) | Checked | TP-1 rule it rides | Pinned by |
| --- | --- | --- | --- |
| name the specialization, `Cpp.Box(T)`, `Cpp.Pair(Cpp.Box(T))`, `Cpp.Box(List(T))` | per specific (upstream's `CallAction`, D-CT-1) | TR-3 | A.1 `uninitialized_var` (dump), `nested_and_generic_class_args` |
| declare without an initializer, `var b: Cpp.Box(T);` | per specific: the `Core.DefaultOrUnformed` lookup is deferred (D-CT-5) | TR-10 (D-TP-12 as amended) | A.1 `uninitialized_var` |
| initialize from, assign, copy or pass a value of the same specialization (`var c: Cpp.Box(T) = b;`, `a = b;`, a parameter `b: Cpp.Box(T)`) | per specific | TR-4 (`InitializeAction`, D-TP-2) | probes c_assign_spec 28, c_param_copy 10, g_eval_order 51 |
| store a `T` into a member, `b.value = v;` | per specific, the copy of `T` included: a `T` without `Core.Copy` is E-MONO with ``cannot copy value of type `NoCopy` `` | TR-4, TR-8 (`value` found in `Box<T>` on instantiation) | A.1 `copy_into_specialization_uncalled`, `fail_copy_into_specialization_on_instantiation` |
| simple member access, `b.value`, `b.Get()` | per specific; a missing member is E-MONO | TR-8 (the IN half: a value whose type in the definition is template dependent), TR-7 for the call of `b.Get` | A.1 `member_missing_uncalled`, `fail_member_missing_on_instantiation` |
| a member found only through `T`'s constraint on a member's value, `b.value.Get()` for `T: Show` | OUT (W-305) | TR-8's OUT half (TP-1's W-266 shape) | A.1 `fail_todo_member_through_constraint` |
| compound member access, `b.value.(Show.Get)()` | per specific | TR-9 | A.1 `fail_todo_member_through_constraint`'s `Compound` |
| address and arrow, `&b`, `p->value` | per specific | TR-5 | probe c_ptr_spec 29 |
| pass to and return from C++ functions whose signatures name the specialization, `Cpp.Unbox(b)`, `return Cpp.MakeBox(v);` | per specific | D-CT-3 (F-021); TR-7 and D-TP-11 (`IsCallPerformable`) when an argument is template dependent | A.1 `generic_class_field`, A.2 `class_return`; probes c_pass_to_cpp 9, c_return_spec 11 |
| return the specialization, `return b;` | per specific; the return slot only for an in-place type (D-CT-8) | TR-4 (D-TP-2/D-TP-3's return storage) | A.2 `class_return`, `narrow_return_template`, `narrow_return_checked` |
| destroy a `var` at the end of its scope | per specific | TR-4 (the destroy's deferred member access) | gen2/c_destroy 25, cpp_template_two_specifics |
| destroy a temporary of such a type, discarded or `let`-bound | never: the destructor does not run, as in a template (W-309) | TP-1's lane, unchanged | probes w6, w7, w9 (§0.12) |
| call a C++ function with an argument of type `T`, `Cpp.Twice(v)`, or with `T`, `Cpp.Twice(T, v)` | per specific (D-CT-3) | F-021; the call action is TP-1's `CallAction`, performed under D-CT-6 | A.1 `function_template_call`, `explicit_type_argument` |
| a Carbon operation on such a call's result, `G(Cpp.Twice(x))` | per specific (the contagion) | TR-4 | A.1 `cpp_result_contagion_uncalled`, `fail_cpp_result_contagion_on_instantiation` |
| a Carbon operation on `T` or `x: T` that involves none of the above, `var r: T = v;` | where the generic is defined | TR-2 | A.1 `fail_copy_symbolic_value_in_definition` |
| a C++ call whose arguments' types are concrete, `Cpp.TakeInt(N)` for `generic N: i32` | where the generic is defined | TR-2 | A.1 `fail_symbolic_value_cpp_call_in_definition` |

With a template binding (`template T: type`) every row is TP-1's own lane and
CT-1 adds only D-CT-5 to D-CT-8 and D-CT-17 under it (D-CT-4). A body that is
never instantiated is not diagnosed in the rows checked per specific
(c_member_missing_uncalled prints 33, new/n05 prints 9), as a template's is
not. _Break condition:_ an expression in none of the three kinds is deferred
in a checked generic (falsifiers: A.1's `fail_copy_symbolic_value_in_definition`
and `fail_symbolic_value_cpp_call_in_definition`, facet/period_self.carbon), or
an expression of the three kinds is checked where the generic is defined and
rejects a program that a specific could run.

### §1.3 C++ calls on checked-symbolic arguments (D-CT-3)

**D-CT-3. A call to an imported C++ function (an overload set, a function
template or a member function) is deferred as a `CallAction`, with a symbolic
facet-typed argument wrapped in `TemplateInst` as `PerformCallToNonFunction`
wraps a C++ template's, and performed for each specific, when one of its
arguments has a type whose dependence is `Checked` (a value `x: T`) or is a
facet-typed value whose dependence is `Checked` (the type `T` itself); a call
with a form-dependent argument (a reference to `x:? Fm`) is not deferred, and
after PR 59 lands neither is a call with a pack expansion argument (S-VA, §3
item 13).** It is the function-call half of F-021: Clang resolves the overload
set and deduces the template's arguments only from C++ types, and E-ARG
(type_mapping.cpp:593-599) is what the definition can say today. Rev 1 deferred
every argument whose own dependence, the maximum of its type's and its value's
(action.cpp:49-60), was `Checked`, so `Cpp.TakeInt(N, N)` for `generic N: i32`,
whose C++ type is known, lost the definition's ``no matching function for call
to 'TakeInt'`` (review A's b01 to b03, an uncalled body compiling on v11); a
value of a concrete type is now resolved where the generic is defined, as on
TP-1 (b01 to b03 report TP-1's diagnostics on v12, n09 prints 113; amended
2026-10-21, review fold: A-B3). A form-dependent argument has no form a specific
could give it either (expr_info.cpp:406-417), so rev 1's deferral only moved
type_mapping.cpp:733-736's TODO into an instantiation note and let an uncalled
body compile (n01 to n03); the call is left to `PerformCallHelper`, which
reports the TODO where the call is written, W-307 (amended 2026-10-21, review
fold: B-M1). A pack expansion argument has no C++ parameter to match, and VA-1
reports that in `PerformCallHelper` (D-VA-5); deferring it skipped the report
(va1, va2, va5 on mva), so S-VA refuses it the same way at PR 59's merge
(amended 2026-10-21, review fold: B-M3). A call whose arguments are all
concrete, or template-dependent (TP-1's lane, which already defers on
`IsCallPerformable`), is unchanged. Measured: the 22 E-ARG probes run
(`Cpp.Twice(v)` 42, `Cpp.Twice(T, v)` 42, `Cpp.Max(a, b)` 9, `Cpp.Unbox(b)` 9, a
member call `b.Get()` 8, `Cpp.SameBox(b, b)` 12), c_sizeof, whose explicit type
argument TP-1 dropped (E-NOMATCH), prints 35, a non-template overload set is
resolved per specific (`Cpp.Over(x)` prints 1 2 3 for `i32`, `f64`, `i64`,
review A's a03), and a callee that is not a template (`Cpp.UnboxInt(b)` for
`Box<int>`, c_param_unbox_int 24) is unchanged. A non-type argument of a
function template, `Cpp.GetN(N)` for `template<int N> int GetN()`, is E-NOMATCH
on every toolchain, concrete or not (n07, n08), and is not a D-CT-3 form. The
`TemplateInst` wrapping of a facet-typed argument changes no measured result:
its mutant M12 passes the nine changed or new goldens and prints what v12 prints
on all 243 probes of §0.3 and §0.12 (`$X/mx_m12.tsv`), because a type argument
`T` already makes the call deferred and its action waits for `T` in the specific
(D-CT-6). It is kept as the form upstream gives a symbolic argument of a C++
template name (call.cpp:749-750), so that both deferred C++ calls have the same
operands (amended 2026-10-21, found by the fold's mutants). _Break condition:_ a
C++ call whose arguments' types are all concrete changes (falsifiers: A.1's
`fail_symbolic_value_cpp_call_in_definition`, any golden of a concrete C++ call;
the gate shows none), a call with an argument of a checked-symbolic type is
still diagnosed where the generic is defined, a form-dependent or pack expansion
argument reaches a deferred call, or a review asks for the wrapping to go, which
M12 shows is a removal with no measured effect (C2 then drops it, a plan
amendment).

### §1.4 The template rule rides TP-1 (D-CT-4)

**D-CT-4. With a template binding, CT-1 changes nothing of TP-1's rules but
D-TP-12 (D-CT-5) and TR-22's C++ forms, and adds D-CT-6 to D-CT-8 and D-CT-17,
which a template's C++ uses and aliases need as much as a checked generic's.**
TP-1's TR-3 and TR-4 (a template-dependent expression is checked on
instantiation; a use of a dependent value is dependent), TR-5 (pointer
operators on a dependent operand), TR-7 (calling a value of dependent type),
TR-8 (simple member access, PARTIAL, the rule W-305 meets), TR-9, TR-10,
D-TP-11 (`IsCallPerformable`), D-TP-12 as amended, and D-TP-14 (cross-library
generics resolved per instantiation are a `semantics TODO` at the `import`,
W-250) stand: xlib/x1, x2 and x5 report D-TP-14's TODO on TP-1 and v12 where
trunk and the nightly stop at import_ref.cpp. **TR-22 is amended, not left
unchanged** (amended 2026-10-21, review fold: A-M1; rev 1 said TR-22 stays OUT
while D-CT-6 made two of its forms run): TR-22 (a checked generic's symbolic
argument passed to a template parameter) stays OUT for TP-1's own forms (n02's
`N + 1` and the three `fail_checked_generic_` splits of deduce_class_args.carbon
keep the note ``value of type `<bound method>` is not callable``, and W-274's
shapes keep their stop and E-MONO, w274_n01i and w274_x04 on v12, §0.12), and
is IN for a template's C++ template name or C++ call: the template's specific
evaluated for the symbolic argument leaves the C++ action unperformed (D-CT-6)
and the caller's specific performs it after substitution (D-CT-7), so
t_box_in_generic_caller (STOP generic_region_stack.h:98 on every toolchain) and
t_symbolic_call_in_generic_caller (E-MONO) print 31 and 30, pinned by A.1's
`template_called_from_checked_generic`. The dated line that records this in
TP-1's TR-22 is Appendix C.11's. The template forms of the probe matrix that
run on TP-1 run unchanged on v12 (39 of 39). _Break condition:_ a golden of
TP-1's template lane changes other than the six of §0.7, or a TR-22 form of
TP-1's own changes.

### §1.5 Deferred impl lookup on a C++ specialization (D-CT-5, amends D-TP-12)

**D-CT-5. An impl lookup whose query reaches a `TemplateInst`, or an action's
operand that names a template binding, is deferred to the specific:
`NamesTemplateBinding` returns true at a `TemplateInst`, follows `MetaInstId`
and `MetaInstBlockId` operands as it follows `InstId` and `InstBlockId`, and
follows each symbolic operand's constant value as well as its operands.**
D-TP-12 (fork/templates/plan.md §1.7) deferred only queries that name a
template binding and kept a checked generic's lookup for a C++ template self;
D-CT-5 amends it for that self, because the self is a `TemplateInst`-wrapped
specialization that upstream means to be "treated as templates", and its
`DefaultOrUnformed` impl (`impl forall [T: UnformedInit]`, or the `final impl
forall [T: Default]` with a C++ class's custom `Default` witness) can be decided
only when `T` is known: `Box<Point>` with a Carbon class field and `Box<int>`
differ. The constant-value step is rev 2's (amended 2026-10-21, review fold:
A-B2): the self of `var b: B;` for `alias B = Cpp.Box(T);` in a checked class
is a splice of a conversion of `B`'s name reference, a body instruction whose
operands, a `specific_constant` of the alias, do not reach the specialization;
its constant value does (R10; a11 and cls_alias_var print 11 and 2 on v12, E-DU
on every other toolchain). The `MetaInstId` walk is the removal condition W-268
names for its `var e: T.Elem;` shape (g_w268 52 and w268_d03_var_elem ``6 4``
on v12, E-DU on TP-1), and A.5 adds the default_init.carbon splits W-268's
removal asks for, the function shape `var_uninit_associated_type` and the
class shape `class_alias_var_uninit`; W-268's third evidence shape, `var a:
x.0;` for a runtime `x` (index.carbon's
`fail_tuple_index_as_var_type_on_instantiation`), is still looked up where the
function is defined, because the walk follows symbolic constants and `x` is
not one, so W-268 is narrowed to that shape and stays open, not discharged
(Appendix C.5; amended 2026-10-21, review fold: A-M5 / B-M2). D-TP-12's named
falsifier changes as intended: generic_call.carbon's `require_specific_def`
leaves the definition (§0.7); facet/period_self.carbon, its other falsifier,
is unchanged. PR 51's W-127 split shape runs (C-2). The dated line that records
the amendment in TP-1's D-TP-12 is Appendix C.11's. _Break condition:_
facet/period_self.carbon changes, or a checked generic's query that reaches
neither a `TemplateInst` nor a template binding, by operands or constant
values, is deferred.

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
operand that is itself a constant instruction, or whose constant belongs to
another generic than the one whose eval block is being built, and leaves an
operand that is an instruction of the current generic's body or eval block.** An
action formed while another generic's eval block was evaluated for a symbolic
specific (a field type `Cpp.Box(T)` of `Holder(T)` formed for `Holder(U)` inside
a generic over `U`, or a C++ call in `F(U)`) is a constant whose operands are
symbolic in `U`; without the substitution its splice survives into the concrete
specific (R3). An operand that is an instruction of the current generic's body
is what the action refers to in every specific of that generic, and substituting
it rewrites the action into a different one: v9, which substituted every
operand, changed 25 goldens. The other-generic case is rev 2's (amended
2026-10-21, review fold: A-B1 / A-B2): an action of a class's alias, rebuilt in
the eval block of a member's declaration (`fn Make() -> B`), refers to the
class's name reference of `T`, which the member's specific cannot evaluate (R9:
STOP sem_ir/generic.cpp:84 once D-CT-17 attaches it, and a stop in lowering
before); it is substituted with the member's own constant, through the rebuild's
map from constants to eval-block instructions. Measured: the six s1 probes run
on v12 (54, 60 to 64); ret_alias, c04, d01, d03, d04, n15 and A.1's
`alias_of_specialization` (`fn Get(b: B) -> T`, `fn Make(v: T) -> B`) run, and
the gate shows no golden beyond §0.7's six. _Break condition:_ a golden whose
actions refer to body instructions of their own generic changes (v9's 25), or an
action keeps an operand that its generic's specifics cannot evaluate.

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
in-place pins) is unchanged. D-CT-8 is commit C1's, and C1 now carries its
pin: A.2's narrow_return is split into `narrow_return_template` (C1, the
template binding, which needs no D-CT-3) and `narrow_return_checked` (C2), so
mutant M6 is killed in C1 by the template split (measured: STOP
lower/handle_call.cpp:984; amended 2026-10-21, review fold: B-m6). _Break
condition:_ a class-typed dependent return loses its in-place storage
(falsifier: lower/testdata/template/initialize.carbon or A.2's `class_return`
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
(export.cpp:169-174) already do, and then `CARBON_CHECK`s that the class has a
definition.** An argument of an exported class type reaches overload
resolution before anything completed the record (R6); the concrete
`Cpp.Id({.x = 6} as Point)` stops the compiler on TP-1, trunk and the nightly.
Measured: z_id_point_lit prints 6; c_bad_inst and t_bad_inst report Clang's
E-CXX for `Twice<Carbon::Point>`. Rev 1 returned `false` (pass by `var`) for a
record still incomplete after the completion, an unpinned branch that would
silently pick a passing mode for a class no argument can have; the argument
is an xvalue of the class type, which a class without a definition cannot
have, so rev 2 states that as a `CARBON_CHECK` and records it as defensive:
no measured input reaches it, and mutant M10 (dropping the check) is
expected to survive (amended 2026-10-21, review fold: A-m3).
`clang::Sema::isCompleteType`, review A's alternative, needs a `Sema` and a
location that `IsMoveEquivalentToCopy`'s signature does not have, and would
also instantiate a class template's specialization, which an xvalue argument's
type already is. _Break condition:_ a golden that exports a Carbon class
changes (the gate: none), another query of an exported record still stops, or
the `CARBON_CHECK` fires.

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
template `h.Id(v)` (36). The same on v12, which adds (amended 2026-10-21,
review fold: A-B2 / A-M4 / A-M3): a class-scope or function-scope alias of a
specialization or of a type the template parameter names, used as a `var`'s,
field's, parameter's or return type (`alias B = Cpp.Box(T);` in a checked
class: a11 11, cls_alias_var 2, d01 11, d03 13, d08 18; in a class template:
d07 17, c04 11, d04 14; in a checked function's body: n16 18; `alias B =
T.Inner;` and `alias E = T.Elem;`, pure Carbon: f06 5, f07 5, ret_alias 5, n14
16, n15 17; A.1's `alias_of_specialization`, A.2's `alias_of_member_type`,
A.5's `class_alias_var_uninit`); `Cpp.std.optional(T)` used through its C++
members (e08 1, e09 0, sv6 1); a tuple of the specialization returned from the
generic (a07 ``7 4``); and a choice declared with a payload of the
specialization (e02e 2), whose use is OUT below.

| OUT form | Measured on v12 (TP-1, trunk, nightly; v11 where it differs) | Filed |
| --- | --- | --- |
| a struct or tuple type as `T` (`{.a: i32}`, `(i32, i32)`), or a Carbon class that cannot be exported (in a generic class's scope) | E-MONO ``unable to monomorphize specific `F({.a: i32})` `` with ``note: semantics TODO: `unsupported type used as template argument` `` (no line); for the class, first the export's ``non-class non-namespace name scope`` TODO; the concrete twin reports the same TODO at the argument (TP-1 and the nightly add E-DU first) | W-300 |
| a Carbon generic class as a template template argument (`Cpp.Apply(List, i32)`) | E-TT at the argument, on every toolchain (cpp/call.cpp:157-159 passes a placeholder that Clang rejects) | W-301 |
| a non-type argument that is a pointer to a Carbon variable (`Cpp.PtrBox(&n)`), or of a kind `MapConstantToAPValue` does not map | ``semantics TODO: `unsupported argument type for non-type template parameter` `` (cpp/call.cpp:246, :256-259), on every toolchain; a `double` argument works (res/w302_double_nttp, 52) | W-302 |
| deducing a Carbon generic parameter through a C++ specialization in a parameter's type (`fn Get[T: type](b: Cpp.Box(T))` called with a `Box<int>`) | E-DEDUCE with ``note: while deducing parameters of generic declared here``, on every toolchain; the programs pass `T` through another parameter instead | W-303 |
| a concrete C++ class `var` in a template's body (`var unused h: Cpp.Holder;` in `fn F[template T: type]`) | STOP lower/function_context.cpp:264 (``const_id.is_concrete()``: a `SpliceInst` left non-concrete in the specific), unchanged on v12; trunk :223, the nightly sem_ir/constant.cpp:36; the checked twin c_class_member_template runs (36) | W-304 |
| a simple member access to an interface member through `T`'s constraint, on a value read from a specialization's member (`b.value.Get()` for `T: Show` with `impl as Show` not `extend`) | E-MONO with ``member name `Get` not found in `S2` ``; `v.Get()` on `v: T` runs (49), and the compound `b.value.(Show.Get)()` runs (s3_compound_member, 56); TP-1's W-266 shape | W-305 |
| (diagnostic quality) a note from a template argument converted for a specific has no line, and a type argument that fails twice reports E-MONO twice | E-UNMAPPED's note and g_nontype_i64's ``cannot implicitly convert expression of type `i64` to `i32` `` print `file.carbon: note:`; ox/nested_generic_scope reports two E-MONO | W-306 |
| a generic from another library whose definition holds a C++ template use, a C++ call deferred by D-CT-3 or an alias of either: CT-1's forms work within one library only | D-TP-14's TODO at the `import` (xlib/x1, x2, x5) | W-250 (TP-1's; no new id) |
| a C++ function call with a form-dependent argument (`Cpp.TakeInt(x)` for `x:? Fm`; added 2026-10-21, review fold: B-M1) | ``semantics TODO: `Support passing form-dependent args to C++ functions.` `` where the call is written (type_mapping.cpp:733-736), as on TP-1, trunk and the nightly; v11 moved it into an E-MONO note and compiled an uncalled body (new/n01 to n03) | W-307 |
| a specialization as a choice alternative's payload (`choice Ch(T: type) { A(b: Cpp.Box(T)), B }`; added 2026-10-21, review fold: A-M4) | the declaration compiles (e02e 2); a use is E-MONO with ``choice alternative payload type `Cpp.Box` is not trivially copyable and destructible in this specific`` (eval_inst.cpp:265, e02, e02f), the concrete payload's TODO ``choice alternative payload that is not trivially copyable and destructible`` (handle_choice.cpp:762, e02b) on every toolchain; TP-1, trunk and v11 stop at sem_ir/generic.cpp:84 on the declaration, the nightly reports a choice TODO | W-308 |
| an impl for every specialization, `impl forall [T: type] Cpp.Box(T) as Size` (added 2026-10-21, review fold: A-M4) | `` `impl` with unused generic binding `` at `T`: `T` cannot be deduced through `Box<T>`; TP-1, trunk, the nightly and v11 stop at sem_ir/generic.cpp:84 (c09) | W-303 (its impl shape) |
| a discarded or `let`-bound temporary of a C++ class with a destructor that a deferred C++ call returns (`Cpp.MakeLoud(v);` with `v: T`; added 2026-10-21, found by the fold) | the destructor does not run: w7 prints 0 where the concrete twin w5 prints 1; the same in a template on TP-1 and the nightly (w6, w9); a `var` of it is destroyed (w10 ``3 1``) | W-309 |
| a tuple, struct or array of the specialization as an uninitialized `var` (`var t: (Cpp.Box(T), i32);`; added 2026-10-21, review fold: A-m4) | E-MONO at the specific, the note that the aggregate does not implement `Core.DefaultOrUnformed` (a06, c06, c07); the concrete twin `(Cpp.Box(i32), i32)` is E-DU on every toolchain (c01), so "an uninitialized `var` of the specialization" in §1.2 means the specialization itself, not an aggregate holding it | none: the concrete form's own limit, unchanged |
| converting a `Cpp.std.optional(T)` to a Carbon type, or matching on it (with PR 62, measured on msv; added 2026-10-21, review fold: A-M3 / B-M3) | E-MONO with SV-1's ``conversion of a C++ `std::optional` or `std::variant` outside a function body`` TODO (sv3b, sv3c; an uncalled body compiles, sv8), and TP-1's ``match on unsupported scrutinee type`` TODO where the generic is defined (sv4) | W-279 (SV-1's), W-252 (TP-1's); no new id |
| a pack expansion argument to a C++ function, `Cpp.Sum(... each x)` (with PR 59, measured on mva; added 2026-10-21, review fold: B-M3) | after S-VA, VA-1's ``pack expansion argument is not matched by a pack expansion parameter`` where the call is written, as on VA-1 (va1, va2, va5); without S-VA it was deferred, an uncalled body compiled and a call was E-MONO | VA-1's D-VA-5; no new id |

Not OUT, though they do not run, because they are right: c_member_missing and
t_member_missing (the member does not exist), the five E-CXX probes (Clang's
error in the instantiated C++), g_nontype_i64 (an `i64` does not implicitly
convert to the parameter's `int`; the concrete `Cpp.Array(i32, 49 as i64)` is
rejected the same way), c_result_in_var (D-CT-2), and the probes' own E-AS and
E-PARSE. _Break condition:_ an IN form that a probe shows rejected or stopped,
or an OUT form whose filed diagnostic changes without a decision (the OUT
table's last eight rows were added by the fold, so a form the reviews did not
probe may still stop; §8's re-review loop is the check).

### §1.12 Residues filed (W-300..W-309)

Ten items, filed in the discharge commit D, each a `missing-feature` or
`toolchain-defect` entry with the evidence above (Appendix C.3 holds the texts):
W-300 unmappable Carbon types as template arguments; W-301 Carbon generics as
template template arguments; W-302 non-type template argument kinds; W-303
deduction through a C++ specialization, a parameter's type and an impl's
self (`impl forall [T: type] Cpp.Box(T) as Size`; amended 2026-10-21, review
fold: A-M4); W-304 the template-body stop for a concrete C++ class `var`
(trunk and the nightly share it); W-305 interface member access through a
constraint on a specialization's member (TP-1's W-266 shape for C++
specializations); W-306 instantiation notes without a line and the repeated
E-MONO (removal: upstream's 7beb29f8b, upstream PR 7967, at the next upstream
merge, then pass the action's location); W-307 a form-dependent argument to a
C++ function, the live half of W-043's type_mapping.cpp evidence (added
2026-10-21, review fold: B-M1); W-308 a C++ class type as a choice
alternative's payload, concrete or a specialization of a symbolic argument
(added 2026-10-21, review fold: A-M4); W-309 a temporary of a C++ class with a
destructor that a deferred C++ call returns is not destroyed, in a template
and in a checked generic (added 2026-10-21, found by the fold's probes).
W-310..W-319 are unused. Review A's other two compiler stops are not filed
because v12 fixes them: the alias as a parameter's type (d03, d04, R9) and the
generic choice's declaration (e02e, which v12 compiles and whose use is
W-308's).

### §1.13 Goldens (D-CT-12)

**D-CT-12. Goldens (§4, Appendix A): a new check golden
interop/cpp/template/symbolic_arg.carbon under the real prelude and a new lower
golden interop/cpp/template_symbolic_arg.carbon pin the IN forms, the OUT
forms' diagnostics and the stops fixed; the six goldens of §0.7 are refilled,
two of them with the header fixes D-CT-9 requires and one,
deduce_class_args.carbon, with TP-1's W-273 split renamed now that it succeeds;
generic/template/default_init.carbon gains two splits (A.5); every CHECK line
comes from autoupdate (R16(a)).** Rev 2 adds to A.1 the splits
`alias_of_specialization`, `copy_into_specialization_uncalled`,
`fail_copy_into_specialization_on_instantiation`,
`fail_symbolic_value_cpp_call_in_definition`, `cpp_result_contagion_uncalled`,
`fail_cpp_result_contagion_on_instantiation`, `fail_todo_form_dependent_arg`,
`fail_todo_impl_forall_specialization` and
`fail_todo_choice_payload_specialization`, renames rev 1's
`fail_template_template_carbon_generic` to
`fail_todo_template_template_carbon_generic` because it pins residue W-301,
splits A.2's `narrow_return` into `narrow_return_template` (C1) and
`narrow_return_checked` (C2), and adds A.2's `alias_of_member_type` (amended
2026-10-21, review fold: A-B1 / A-B2 / A-B3 / A-M1 / A-M4 / A-M5 / B-M1 / B-M6
/ B-m6 / B-m7). _Break condition:_ a golden whose change is not explained by a
decision above.

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
| cpp_template_symbolic_diff (+ .diff.cpp) | the oracle's output | `SumThree<int>(20000, 20000, 20000)` = 60000; `SumThree<short>` of the same accumulates in a `short` total, `a->total + v` computed in `int` and converted back: the second addition's 40000 wraps to -25536 and the third gives -5536 (C++17's implementation-defined conversion, modular in Clang; both sides use the same Clang), so the specializations differ where rev 1's 6 and 60 did not; `CountThree<int>` counts 3; the oracle prints `60000`, `-5536`, `3` (amended 2026-10-21, review fold: B-m7) |
| cpp_var_template_runtime | 5, 8, 20, 9 | `Plain<int>` = 4 + 1; `SizeOf<long>` = 8; `Holder::count<short>` = 2 * 10; `Plain<long>` through the generic = 8 + 1 |

All nine run on v11 and on v12 and print their EXPECT lines; the differential
program's oracle, compiled with the toolchain's clang++ -std=c++17, prints the
same three lines. The generic parameter is `[T: type]` in every program, the
programs' original claim: a store of `T` into the specialization is checked on
instantiation (D-CT-2's table), so `[T: type]` is what the programs pin; the
design-docs fixture X37 of Appendix C.1 uses `[T: type]` too, where rev 1's
fixture used `[T: Core.Copy]` (amended 2026-10-21, review fold: B-M6). Where a
program's form has a `t_` probe that already runs on TP-1 (t_fn_template_call,
t_fn_template_explicit, t_pass_to_cpp, t_return_spec, t_sizeof), that probe
prints the value the derivation gives. Before CT-1 every one fails on TP-1,
trunk and the nightly (the gen3 rows of §0.3: E-DU, E-ARG or L-UNDEF). _Break
condition:_ a program passes on TP-1 (it would pin nothing), or an EXPECT
disagrees with its derivation.

### §1.15 Docs and records (D-CT-14)

**D-CT-14. The design page's "Using C++ templates" section is edited at land
time against DD-1's text (commit L, a dated paragraph replacing DD-1's "One
limit in 0.1" sentence, R27-diffed against the programs' spelling, with design
docs fixture X37 registered in PR 58's check_samples.py); the records discharge
W-043 with its residues filed, discharge TP-1's W-273, narrow TP-1's W-268,
add one dated line each to TP-1's D-TP-12, TR-22 and W-274, keep rows 56 and
42 PARTIAL with corrected text, and add the decision-log entry "CT-1" with
F-021.** The texts are Appendix C. Row 56 stays PARTIAL on W-300..W-303, W-305
and W-307 to W-309 (the OUT kinds) and on the one-library limit (W-250), and
row 42 on its own export cases (its template clause is replaced, qualified by
W-300); W-043's disposition is DISCHARGED because its blocker, a symbolic
Carbon type as a C++ template argument, is IN, and what remains of its
evidence is filed: call.cpp:252 as W-302 and type_mapping.cpp:560's TODO, now
:733-736, as W-307 (amended 2026-10-21, review fold: B-M1 / B-M5 / B-M2 /
B-m2). The TP-1 records CT-1 edits are exactly these: W-268 (narrowed), W-273
(discharged), and the dated lines on D-TP-12, TR-22 and W-274 in
fork/templates/plan.md (Appendix C.5, C.11); nothing else of TP-1's changes.
Records commits on this branch (before PR 58 lands) write rows 56 and 42 at
their line numbers here; the land-time records commit finds them by their
bullet text after M, not by number, because the held PRs between move them
(ST-1's, SC-1's, VA-1's and OP-2's rows land at 60 to 63 and DD-1 shifts the
table by six, so rev 1's "PR 58's 62 and 48" is not the merged position;
amended 2026-10-21, review fold: B-m4). _Break condition:_ a row, page or
ledger text claims a form that a probe shows rejected, or omits a limit
(W-250) that a probe shows.

### §1.16 Merge position and held state (D-CT-15)

**D-CT-15. CT-1 is one PR stacked on PR 61, its base TP-1's branch until PR 61
merges, held like PR 51 to PR 62, and merged last, after PR 62.** Its land-time
items: M, a records-only merge of the trunk that holds PR 51 to PR 62, which
resolves W-043's entry by taking DD-1's text (PR 58 amends W-043's notes and
evidence) and leaves CT-1's discharge to the land-time records commit, which
reapplies Appendix C.2 over it (a "keep both sides" merge cannot resolve one
JSON entry that two branches edit; amended 2026-10-21, review fold: B-m4);
S-VA, the land-time code commit right after M that makes D-CT-3 refuse a pack
expansion argument (Appendix C.11's hunk, one new split; M itself adds no
code; added 2026-10-21, review fold: B-M3); L-F, the refill of what M and S-VA
change, including PR 51's split renamed `unformed_dependent_var` (C-2, moved
from TP-1's F6) and the two programs' merged text (C-1); L, the design page
edit over PR 58's text with fixture X37 (C-3); the second id re-scan; the
land-time records commit (rows found by bullet text, DD-1's W-043 notes merged
into the discharge text, W-127's discharge naming CT-1 for the checked shape).
If PR 61 changes before CT-1 lands, CT-1 rebases nothing (a submitted PR's
history is never rewritten, AGENTS.md); it merges PR 61's new head into its
branch in a records-only merge commit and refills. If PR 61 lands with its F6
rename of PR 51's split unchanged (H-1 not taken), the split
`unformed_dependent_var` reaches CT-1's M already renamed and failing on TP-1's
toolchain: CT-1's L-F then refills it with CT-1's toolchain, which makes it
pass, and the C-2 rule shrinks to that refill and W-127's sentence (added
2026-10-21, review fold: B-m6). _Break condition:_ a held PR's merge changes
one of CT-1's ten files' hunks beyond the offsets of §0.9, or a composition
mirror's red set differs from §0.9's.

### §1.17 F-021, the checked-generic C++ rule (D-CT-16)

Rewritten 2026-10-21 (review fold: A-M1). Rev 1's D-CT-16 minted no fork
design id because "every rule CT-1 implements is upstream's"; its own break
condition is met: upstream diagnoses a C++ function call with a checked
generic's symbolic argument (E-ARG), proposal 2200 leaves a checked generic
calling a template to future work (p002200:1089-1096) and leads issue 2153
decided only that it may, so deferring such a call, and with it every Carbon
operation on its result, is a language rule no upstream source states.

**D-CT-16. F-021 is minted: D-CT-2's rule, with D-CT-3 as its function-call
half.** Its text for fork/decision-log.md is Appendix C.7's. What upstream
does state, the `TemplateInst` deferral of a C++ template named with a
symbolic argument (call.cpp:749-750) and proposal 2200's delayed impl lookup
(D-CT-5), F-021 extends and does not replace; Clang's rules (instantiation,
completion, the variable template's specialization kind; D-CT-9, D-CT-10)
need no id. _Break condition:_ upstream lands a rule for a checked generic's
C++ calls (definition-checked through constraints, or deferred as here) that
differs from F-021, which then is re-decided against it at the upstream merge
(§0.10's register).

### §1.18 An alias in a generic belongs to the generic (D-CT-17)

Added 2026-10-21 (review fold: A-B1 / A-B2). **D-CT-17. A non-generic
declaration nested in a generic whose generic declaration region is discarded,
an alias, attaches that region's dependent instructions to the enclosing
generic instead of leaving them unattached:
`DiscardGenericDeclIntoEnclosingGeneric` (generic.cpp) re-derives each
instruction's dependence (a template action is its own constant; otherwise a
symbolic type or constant value) and calls
`AttachDependentInstToCurrentGeneric` for it in the order the region added
them; handle_alias.cpp calls it unless the alias's name had generic parameters,
which are diagnosed and whose bindings must stay out of the enclosing
generic.** An alias is never generic, but its value is an expression of the
enclosing generic, evaluated for each specific of it, as a field's type is; the
upstream code discards the region because the alias has no generic of its own,
and loses the attachment that every other expression of the enclosing scope
gets (R8). A non-template alias's value is rebuilt from the alias binding's
constant, so the lost attachment was unobservable until TP-1's actions, whose
operands are those instructions, appeared in such an expression. Review A's
other remedy, not deferring a query whose splice belongs to an enclosing
generic's eval block, would keep E-DU for f06 and d07 and leave f07, ret_alias,
d03, d04, d08 and TP-1's W-273 stopping or rejected on TP-1 and upstream, a
guard over a root cause (R17), and is rejected. Measured on v12: §0.12's alias
rows run; TP-1's W-273 split succeeds (deduce_class_args.carbon, renamed); the
prelude's interface alias `ValueType` moves four notes of range_for.carbon to
the expression's column; no other golden changes. The other callers of
`DiscardGenericDecl` (custom_witness.cpp's lookup scaffolding, namespaces,
`export`, `require` on error, `BuildGeneric` with no bindings,
`FinishGenericDefinition` without a generic) keep discarding, because their
regions are either scaffolding whose instructions nothing later evaluates or
have no enclosing generic. _Break condition:_ a golden whose alias is not
template dependent changes beyond a diagnostic's location, or an alias's
instruction is attached to a generic whose specific cannot evaluate it.

### §1.19 Decision index

Amended 2026-10-21 (review fold: A-B1 / A-B2 / A-B3 / A-M1 / A-M5 / B-M1 /
B-M2 / B-M3).

-   D-CT-1, the deferral model: upstream's `CallAction` over `TemplateInst`,
    performed per specific, no new SemIR.
-   D-CT-2 (F-021), the checked-generic rule: a C++ specialization of a
    symbolic argument, a C++ call with a checked-symbolic argument and every
    operation on their values are checked for each specific; everything else
    where the generic is defined.
-   D-CT-3, C++ calls with an argument of a checked-symbolic type, or that is
    such a type, are deferred; a form-dependent and (after PR 59) a pack
    expansion argument are not.
-   D-CT-4, the template lane rides TP-1; TR-22 amended for its C++ forms.
-   D-CT-5, impl lookup on a C++ specialization is deferred, the walk following
    constant values too (D-TP-12 amended, W-268 narrowed).
-   D-CT-6, a C++ callee's action waits for concrete arguments.
-   D-CT-7, action operands that are constants or belong to another generic
    are substituted.
-   D-CT-8, a deferred `return` uses the return slot only in place.
-   D-CT-9, variable template specializations are implicitly instantiated.
-   D-CT-10, an exported class is completed before overload resolution reads
    it, and checked complete.
-   D-CT-11, the admitted kinds and the OUT table.
-   D-CT-12, goldens: two new files, six refills, two header fixes, a renamed
    TP-1 split, two default_init.carbon splits.
-   D-CT-13, nine programs.
-   D-CT-14, docs at land time with fixture X37, records, the TP-1 record
    edits.
-   D-CT-15, stacked on PR 61, merged after PR 62, with S-VA after M.
-   D-CT-16, F-021 minted.
-   D-CT-17, an alias's dependent instructions belong to the enclosing generic
    (TP-1's W-273 discharged).

## §2 Spec, file by file

### §2.0 Conventions

The diffs are v12's, against this branch's head (TP-1's 5661a35c8), as
measured; the implementer applies them as written, and a change to them is a
plan amendment. Commit C1 holds §2.1 to §2.6 and §2.12, commit C2 §2.7 (§3).
Line numbers are this branch's. No X-macro, `inst_kind.def`, `typed_insts.h` or
diagnostic kind changes, so no generated file changes and no new diagnostic
kind is added (D-CT-1, D-CT-11: the OUT forms keep their existing messages);
generic.h gains one function declaration, which a full build of the mva and
msv mirrors compiled (§0.1). Rev 2's ten files total 265 lines added and 13
removed (amended 2026-10-21, review fold: A-B1 / A-B2 / A-B3 / B-M1 / A-m3 /
B-m1).

### §2.1 toolchain/check/impl_lookup.cpp (C1, D-CT-5)

`NamesTemplateBinding` (:578-634) gains four clauses: a `TemplateInst` names a
template binding; a `MetaInstId` or `MetaInstBlockId` operand is followed as an
`InstId` or `InstBlockId` is; and `push` follows each symbolic instruction's
constant value as well as its operands (rev 2; amended 2026-10-21, review fold:
A-B2). `push` already follows only symbolic constants (:587-589), so the walk
stays inside the query's symbolic operands and their constants. Review points:
the `TemplateInst` clause returns before the operand loop, as the
`SymbolicBinding` clause above it does; the constant-value step reaches the
specialization through a name reference to an alias, `B` for `alias B =
Cpp.Box(T);`, whose operands do not; `QueryNamesTemplateBinding` (:636-660) and
its two callers (:1170, :1353) are unchanged. +26 / -1 lines.

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/check/impl_lookup.cpp
+++ b/toolchain/check/impl_lookup.cpp
@@ -583,11 +583,20 @@
     if (!id.has_value() || llvm::is_contained(visited, id)) {
       return;
     }
-    if (!context.constant_values().Get(id).is_symbolic()) {
+    auto const_id = context.constant_values().Get(id);
+    if (!const_id.is_symbolic()) {
       return;
     }
     visited.push_back(id);
     worklist.push_back(id);
+    // An instruction of a generic's body, such as a name reference to an
+    // alias, `B` for `alias B = Cpp.Box(T);`, reaches what it names through
+    // its constant value, not through its operands.
+    auto const_inst_id = context.constant_values().GetInstId(const_id);
+    if (!llvm::is_contained(visited, const_inst_id)) {
+      visited.push_back(const_inst_id);
+      worklist.push_back(const_inst_id);
+    }
   };
   auto push_specific = [&](SemIR::SpecificId specific_id) {
     if (specific_id.has_value()) {
@@ -604,15 +613,31 @@
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
operand is pushed with `skip` set unless `IsSubstitutedActionOperand` holds for
it: it is its own constant instruction, or (rev 2) its attached symbolic
constant belongs to another generic than the pending one whose eval block is
being built (`generic_region_stack().PeekPendingGeneric()`); so a body or
eval-block instruction of the current generic is popped unchanged and only a
constant action, or an enclosing generic's operand, is rebuilt (amended
2026-10-21, review fold: A-B1 / A-B2). Review points: `Worklist::Push`'s `skip`
parameter exists (:72; the field is at :47-48) and is how the worklist already
leaves an operand alone (amended 2026-10-21, review fold: A-m2); a `None`
`MetaInstId` is returned unchanged, as the `InstId` case does; with no pending
generic the other-generic case does not apply. +47 lines.

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/check/subst.cpp
+++ b/toolchain/check/subst.cpp
@@ -89,6 +89,30 @@

 }  // namespace

+// Returns whether an action's operand is substituted into: only an operand
+// that is itself a constant instruction is, such as the C++ template call
+// that an action formed while another generic's eval block was evaluated for
+// a symbolic specific. An instruction of a generic's body or eval block is
+// the operand the action refers to in each specific, and stays.
+static auto IsSubstitutedActionOperand(Context& context, SemIR::InstId inst_id)
+    -> bool {
+  if (context.constant_values().GetConstantInstId(inst_id) == inst_id) {
+    return true;
+  }
+  // An instruction of another generic, such as an enclosing class's
+  // `T.Inner` that an alias of the class names, is not evaluated in this
+  // generic's specifics, so it is substituted with this generic's constant
+  // when the action is added to this generic's eval block.
+  auto const_id = context.constant_values().GetAttached(inst_id);
+  if (!const_id.is_symbolic() ||
+      !context.constant_values().IsAttached(const_id) ||
+      context.generic_region_stack().Empty()) {
+    return false;
+  }
+  return context.constant_values().GetSymbolicConstant(const_id).generic_id !=
+         context.generic_region_stack().PeekPendingGeneric().generic_id;
+}
+
 // Pushes the specified operand onto the worklist.
 static auto PushOperand(Context& context, Worklist& worklist,
                         SemIR::IdAndKind arg) -> void {
@@ -122,6 +146,20 @@
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
@@ -223,6 +261,15 @@
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
`InPlaceInitializing` kind now also requires storage. +18 / -6 lines (rev 1
said +16 / -4; the diff is unchanged; amended 2026-10-21, review fold: B-m1).

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
then checks that the record has a definition: its callers (:199, :223) pass the
type of an xvalue argument, which an incomplete class cannot have, so rev 1's
defensive `return false` was an unreachable branch that would have hidden a
defect, and is a `CARBON_CHECK` (amended 2026-10-21, review fold: A-m3).
`clang_sema().isCompleteType()`, which would also instantiate a C++ class
template specialization, is not used: the function takes only the
`clang::QualType` (no `Context`, so no `Sema`), and no golden or probe reaches
the check with an incomplete record (its mutant M10 is expected to survive,
§8), so the narrower completion plus the check states the precondition. Review
points: only an exported Carbon class has external lexical storage
(export.cpp:94, :215); C++ classes are complete or not by C++'s rules and reach
the unchanged code. +12 lines.

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/check/cpp/overload_resolution.cpp
+++ b/toolchain/check/cpp/overload_resolution.cpp
@@ -161,6 +161,18 @@
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
+  // The argument is an xvalue of the class type, which a class without a
+  // definition cannot have.
+  CARBON_CHECK(record_decl->hasDefinition(),
+               "Incomplete class type of an xvalue argument");

   // - The move constructor is defaulted and deleted or non-existent, in
   //   which case overload resolution for a move will call the copy
```

<!-- google-doc-style-resume -->

### §2.7 toolchain/check/call.cpp (C2, D-CT-3)

`PerformCall` (:899-927) defers, after `IsCallPerformable` and before
`PerformCallHelper`, a call to a `CalleeCppOverloadSet` any of whose arguments
has a type of `Checked` dependence or is a facet-typed value of `Checked`
dependence (`IsCheckedSymbolicCppArg`), and none of whose arguments is
form-dependent: `DeferCppCallOnSymbolicArgs` builds the same `CallAction` that
`PerformCallToNonFunction` (:741-768) builds for a C++ template name, wrapping
a symbolic facet-typed argument (`type` is the empty `FacetType`,
typed_insts.h:870) in `TemplateInst`. Rev 1's predicate, the argument's own
dependence, also held for a value of a concrete type such as `N` of `generic N:
i32` (`OperandDependence` is the maximum of the type's and the value's
dependence, action.cpp:49-60), and deferred a call whose C++ types were known
(b01, b02: TP-1's and the nightly's ``no matching function for call to
'TakeInt'`` lost); rev 2 reads the type (amended 2026-10-21, review fold: A-B3).
A form-dependent argument (`x:? Fm`) is refused before any wrapping, so
`PerformCallHelper` reports type_mapping.cpp:733-736's TODO where the call is
written, as TP-1 does (W-307; amended 2026-10-21, review fold: B-M1); the
include of toolchain/sem_ir/expr_info.h is for `GetExprCategory`. Review
points: a value argument `x: T` is not wrapped (v2 wrapped values and stopped
at type_completion.cpp:348); a template-dependent argument never reaches this
code, because `IsCallPerformable` already returned false for it; `is_desugared`
is carried, as `PerformCallHelper` uses it. At land time, after PR 59, S-VA
adds the pack expansion refusal of §2.11. +73 lines.

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/check/call.cpp
+++ b/toolchain/check/call.cpp
@@ -31,6 +31,7 @@
 #include "toolchain/diagnostics/format_providers.h"
 #include "toolchain/sem_ir/builtin_function_kind.h"
 #include "toolchain/sem_ir/entity_with_params_base.h"
+#include "toolchain/sem_ir/expr_info.h"
 #include "toolchain/sem_ir/function.h"
 #include "toolchain/sem_ir/ids.h"
 #include "toolchain/sem_ir/inst.h"
@@ -896,10 +897,82 @@
   }
 }

+// Returns whether a call argument has a symbolic type that is not
+// template-dependent, as a value `x: T` of a checked generic has, or is such a
+// type, as the `T` of `Cpp.Twice(T, x)` is. A value of a concrete type is not,
+// even when the value is symbolic, as `N` of `generic N: i32` is: its C++ type
+// is known where the generic is defined, and so is the call.
+static auto IsCheckedSymbolicCppArg(Context& context, SemIR::InstId arg_id)
+    -> bool {
+  auto type_id = context.insts().Get(arg_id).type_id();
+  if (OperandDependence(context, type_id) ==
+      SemIR::ConstantDependence::Checked) {
+    return true;
+  }
+  return context.types().Is<SemIR::FacetType>(type_id) &&
+         OperandDependence(context, arg_id) ==
+             SemIR::ConstantDependence::Checked;
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
+  // A form-dependent argument, such as a reference to `x:? Fm`, has no form
+  // that the call could take in a specific either, so the call is left to
+  // `PerformCallHelper`, which reports that where the call is written.
+  if (llvm::any_of(arg_ids, [&](SemIR::InstId arg_id) {
+        return SemIR::GetExprCategory(context.sem_ir(), arg_id) ==
+               SemIR::ExprCategory::Dependent;
+      })) {
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
CHECK lines: autoupdate writes them (R16(a)). C1 adds A.1's and A.2's C1 splits,
A.3's and A.4's header changes, A.5's two default_init.carbon splits and A.6's
rename; C2 adds the C2 splits (§4 names each split's commit). The fills F1 and
F2 are autoupdate runs to a fixpoint and nothing else.

### §2.9 Conformance programs

Appendix B holds the nine programs and the oracle as committed. Commit P also
regenerates fork/conformance/README.md's program table with
`python3 fork/conformance/runner.py --update-readme-table` (the two rows lose
SKIP, seven rows are added; Appendix C.9) and runs `--self-test`.

### §2.10 Records

Appendix C holds the records texts with `<...>` placeholders for what the
discharge measures: the ledger (W-043's discharge, W-268's narrowing, W-273's
discharge, W-300 to W-309), TP-1's dated record lines (C.11), gap rows 56 and
42, the decision-log entry "CT-1" with F-021, the ORCHESTRATION paragraph and
branch row, and the land-time texts (the design page paragraph and fixture X37,
the merged program header, W-127's sentence, S-VA's hunk).

### §2.11 Land-time integration (commits M, S-VA, L-F, L and the land-time records commit)

Rewritten 2026-10-21 (review fold: B-M3 / B-M4 / B-M5 / B-m4 / B-m6). After
PR 62 merges, in this order, each its own commit:

1.  **M** merges the trunk that holds PR 51 to PR 62 into this branch, records
    only: the two programs by C-1's rule (PR 51's header with Appendix C.6's
    paragraph appended, CT-1's body); W-043's ledger entry is taken from
    DD-1's side whole (PR 58 amends its notes and evidence), because a merge
    cannot keep both sides of one JSON entry, and CT-1's discharge is
    reapplied over it by the land-time records commit; every other ledger
    entry, the gap rows and the decision log keep both sides, CT-1's after
    the others.
2.  **S-VA** (code): Appendix C.11's call.cpp hunk, which makes
    `DeferCppCallOnSymbolicArgs` refuse a pack expansion argument as it
    refuses a form-dependent one, so VA-1's D-VA-5 diagnostic is reported
    where the call is written (measured on mva: va1, va2 and va5 report it),
    and C.11's split, which pins it; built and filled to a fixpoint before
    L-F.
3.  **L-F** refills what M and S-VA change, predicted: S-VA's split; PR 51's
    dependent_var_full_prelude.carbon split `fail_todo_unformed_dependent_var`
    renamed `unformed_dependent_var` and refilled (C-2), or, if PR 61 landed
    its own rename, that split refilled (§1.16's fallback); any golden of a
    held PR that the merged toolchain changes (the composition mirrors of §8
    predict none).
4.  **L** edits docs/design/interoperability/README.md's "Using C++
    templates" over PR 58's text (Appendix C.1), adds fixture
    X37_cpp_template_symbolic_uninit.carbon with its `SAMPLES` entry after
    X09's, and updates X09's limit comment, checked by PR 58's
    fork/designdocs/check_samples.py with `--toolchain` (measured on a PR 58
    mirror: X37 passes on v12 and fails on TP-1).
5.  **The land-time records commit** rewrites rows 56 and 42, found by their
    bullet text after M, not by number (the held PRs between move them); merges
    DD-1's W-043 notes into the discharge text of Appendix C.2; adds W-127's
    sentence (C.10); and re-runs the id re-scan.

### §2.12 toolchain/check/generic.h, generic.cpp and handle_alias.cpp (C1, D-CT-17)

Added 2026-10-21 (review fold: A-B1 / A-B2). generic.h declares
`DiscardGenericDeclIntoEnclosingGeneric` after `DiscardGenericDecl` (:67-68);
generic.cpp defines it after `DiscardGenericDecl` (:453-465): it copies the
region's dependent instructions (`PeekDependentInsts`,
generic_region_stack.h:84) before discarding the region, and, when an enclosing
generic region remains (`Empty`, :54), attaches each to it with
`AttachDependentInstToCurrentGeneric` (:333) in the order the region added them,
re-deriving the kind: `Template` for an instruction that is its own constant
(`AddTemplateConstantInstToEvalBlock`'s result), otherwise `SymbolicType` and
`SymbolicConstant` from the instruction's type and value. handle_alias.cpp (:49)
calls it instead of `DiscardGenericDecl` unless the alias's name had generic
parameters (`diagnosed_params`, :38-42). Review points: the copy is needed
because `DiscardGenericDecl` pops the region whose list `PeekDependentInsts`
returns; with diagnosed parameters the alias's value is an error and its
bindings must not enter the enclosing generic; at file scope nothing is
attached, as before. +8 lines (generic.h), +37 (generic.cpp), +9 / -1
(handle_alias.cpp).

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/check/generic.h
+++ b/toolchain/check/generic.h
@@ -67,6 +67,14 @@
 // would not actually be used, or when recovering from an error.
 auto DiscardGenericDecl(Context& context) -> void;

+// Discards the generic declaration region of a declaration that is never
+// generic itself but can be nested in a generic, such as an alias. The
+// instructions that depend on a generic parameter belong to the enclosing
+// generic, as an expression elsewhere in its scope does, and are attached to
+// it; with no enclosing generic, they are left unattached, as
+// `DiscardGenericDecl` leaves them.
+auto DiscardGenericDeclIntoEnclosingGeneric(Context& context) -> void;
+
 // Finish processing a potentially generic declaration and produce a
 // corresponding generic object. Returns SemIR::GenericId::None if this
 // declaration is not actually generic.
--- a/toolchain/check/generic.cpp
+++ b/toolchain/check/generic.cpp
@@ -464,6 +464,43 @@
   context.generic_region_stack().Pop();
 }

+auto DiscardGenericDeclIntoEnclosingGeneric(Context& context) -> void {
+  llvm::SmallVector<SemIR::InstId> dependent_inst_ids(
+      context.generic_region_stack().PeekDependentInsts());
+  DiscardGenericDecl(context);
+  if (context.generic_region_stack().Empty()) {
+    return;
+  }
+  // Attach them in the order they were added, so that an instruction's
+  // operands are in the eval block before it. An action that refers to one of
+  // them, such as `T.Inner` or a C++ template call in `alias B = T.Inner;`,
+  // then evaluates its operand in each specific of the enclosing generic.
+  for (auto inst_id : dependent_inst_ids) {
+    if (context.constant_values().GetConstantInstId(inst_id) == inst_id) {
+      // A template action, or an element of its result: its own constant
+      // (`AddTemplateConstantInstToEvalBlock`).
+      AttachDependentInstToCurrentGeneric(
+          context,
+          {.inst_id = inst_id, .kind = DependentInstKind::Template});
+      continue;
+    }
+    DependentInstKind kind = DependentInstKind::None;
+    if (context.constant_values().DependsOnGenericParameter(
+            context.types().GetConstantId(
+                context.insts().Get(inst_id).type_id()))) {
+      kind.Add(DependentInstKind::SymbolicType);
+    }
+    if (context.constant_values().DependsOnGenericParameter(
+            context.constant_values().Get(inst_id))) {
+      kind.Add(DependentInstKind::SymbolicConstant);
+    }
+    if (!kind.empty()) {
+      AttachDependentInstToCurrentGeneric(context,
+                                          {.inst_id = inst_id, .kind = kind});
+    }
+  }
+}
+
 auto BuildGeneric(Context& context, SemIR::InstId decl_id) -> SemIR::GenericId {
   auto all_bindings =
       context.scope_stack().compile_time_binding_stack().PeekAllValues();
--- a/toolchain/check/handle_alias.cpp
+++ b/toolchain/check/handle_alias.cpp
@@ -46,7 +46,15 @@
     expr_id = SemIR::ErrorInst::InstId;
   }

-  DiscardGenericDecl(context);
+  // An alias is never generic, but in a generic its value is part of that
+  // generic: `alias B = T.Inner;` in `class C(template T: type)` is evaluated
+  // for each specific of `C`. With diagnosed parameters, the value is an error
+  // and the parameters' bindings stay out of the enclosing generic.
+  if (diagnosed_params) {
+    DiscardGenericDecl(context);
+  } else {
+    DiscardGenericDeclIntoEnclosingGeneric(context);
+  }

   auto introducer =
       context.decl_introducer_state_stack().Pop<Lex::TokenKind::Alias>();
```

<!-- google-doc-style-resume -->

## §3 Commits (one PR, "CT-1: C++ templates on symbolic Carbon type arguments", R29(b))

Each commit message ends with the two trailers the conventions name; author
jmann345, committer Claude; explicit paths only (R20). Rewritten 2026-10-21
for rev 2 (review fold: A-B1 / A-B2 / A-B3 / A-M5 / B-M1 / B-M3 / B-M6 / B-m5 /
B-m6).

1.  **P0** "CT-1 plan (rev 1): C++ templates on symbolic Carbon type
    arguments, instantiated per specific" (this file), then "CT-1 plan (rev
    2): reviews A and B folded, 25 findings" and each later revision in its
    own commit; implementation starts at the revision the re-review signs
    off.
2.  **C1** "CT-1 (1): C++ specializations of symbolic arguments are formed and
    used for each specific": impl_lookup.cpp, action.cpp, subst.cpp,
    convert.cpp, cpp/call.cpp, cpp/overload_resolution.cpp, generic.h,
    generic.cpp and handle_alias.cpp (§2.1 to §2.6 and §2.12, the c1v12
    state); the fourteen C1 splits of A.1 and the six of A.2 (Appendix A
    marks them); A.3's and A.4's header changes and A.3's new split; A.5's two
    default_init.carbon splits; A.6's rename of TP-1's W-273 split.
3.  **F1** "CT-1 (1) fill": autoupdate to a fixpoint. Predicted exactly, as
    measured on c1v12g: the six refills of §0.7 (generic_call, non_type_param,
    var_template, globals, deduce_class_args, range_for) and the C1 subsets of
    A.1 (804 lines, fourteen splits) and A.2 (1211 lines, six splits);
    default_init.carbon gains no CHECK line (its new splits succeed and are
    not dumped); the gate passes all 1959 goldens.
4.  **C2** "CT-1 (2): C++ calls with a checked generic's symbolic arguments are
    deferred to each specific": call.cpp (§2.7); the nine C2 splits of A.1 and
    A.2's `narrow_return_checked` and `class_return`.
5.  **F2** "CT-1 (2) fill": autoupdate; predicted: A.1 to 1129 lines and A.2
    to 1578, nothing else (c1v12g's fill of the other seven goldens is
    byte-identical to v12g's); the gate 1959 of 1959.
6.  **P** "CT-1 (3): conformance programs": the two un-SKIPs, seven programs,
    the oracle, the README table; predicted 147 / 0 / 20 over 167.
7.  **Implementation reviews A and B** (R29(c)), on the head after P; not
    commits.
8.  **Fix commits**, at most three, each with its fill. The shrink line: if a
    review finding needs a fourth fix commit, the slice shrinks instead,
    dropping the form at issue to OUT with a residue in W-310..W-319 and its
    golden split renamed `fail_todo_`, never by a guard that hides an IN form
    (R17).
9.  **Focused re-review loop** (added 2026-10-21, review fold: B-m6): CT-1
    edits the machinery TP-1 needed eleven review rounds to settle (actions,
    substitution, impl lookup, generic regions), so after the fix commits two
    fresh reviews read the fix commits' diff and every function of §2 that
    they touch, with the gate, the mutants of §8 item 5 that cover those
    functions and the §0.12 probes re-run; a fixer folds each round's findings
    under item 8's shrink line. The loop ends when a round is dry (no BLOCKER
    or MAJOR) and is capped at three rounds: if the third is not dry, every
    form a remaining finding names goes OUT under the shrink line and the loop
    ends. The PR opens held after the last round.
10. **Held-state measurements** (not commits): §8's mutants, the composition
    mirrors over PR 51, PR 57, PR 59, PR 60 and PR 62 with the predicted red
    sets, clang-tidy, the id re-scan.
11. **R** "CT-1 records: gap rows 56 and 42": Appendix C.4.
12. **D** "CT-1 discharge": the ledger (Appendix C.2, C.3, C.5), the TP-1
    record lines (C.11), the decision log (C.7), fork/ORCHESTRATION.md (C.8),
    the re-scan's result; last on the branch.
13. **Land-time** (after PR 62), each its own commit: M (records only:
    W-043's entry taken from DD-1, rows and decision log keeping both sides,
    C-1's program merge); S-VA (code: Appendix C.11's call.cpp hunk and its
    split, the only land-time code); L-F (the refill of what M and S-VA
    change, PR 51's split renamed by C-2's rule or its fallback, §1.16); L
    (the design page and fixture X37, Appendix C.1); the land-time records
    commit (§2.11). There is no docs commit on the branch: the design page's
    "Using C++ templates" section exists only on PR 58, so its edit is L
    (D-CT-14).

## §4 Testdata matrix (autoupdate fills; the fill must reproduce these lines)

Rewritten 2026-10-21 for rev 2 (review fold: A-B1 / A-B2 / A-B3 / A-M1 / A-M4 /
A-M5 / B-M1 / B-M6 / B-m6 / B-m7). The fills are v12g's, and c1v12g's for the
C1 splits, which fill identically (§0.7).

check/testdata/interop/cpp/template/symbolic_arg.carbon (A.1), under the full
prelude, twenty-three splits:

| Split | Commit | Pins | Fill (measured on v12g; on c1v12g for C1 splits) |
| --- | --- | --- | --- |
| uninitialized_var | C1 | R1, D-CT-5: `var b: Cpp.Box(T);` in a checked generic | no diagnostic; the dump of `F` holds the `call_action`, `splice_inst` and `initialize_action` over the spliced type, `[template]` |
| nested_and_generic_class_args | C1 | D-CT-11: `Cpp.Pair(Cpp.Box(T))`, `Cpp.Box(List(T))`, `Cpp.Apply(Cpp.Box, T)` | no diagnostic |
| function_template_call | C2 | R7, D-CT-3: `Cpp.Twice(v)` | no diagnostic; the dump of `F` holds the deferred `call_action` over `Twice`'s overload set; the specific `F(i32)` calls `Twice__carbon_thunk` |
| explicit_type_argument | C2 | D-CT-3: `Cpp.Twice(T, v)`, `Cpp.SizeOfFn(T)`, the variable template `Cpp.Plain(T)` | no diagnostic |
| template_called_from_checked_generic | C1 | R2, D-CT-6: a template with `Cpp.Box(T)` and one with `Cpp.Twice(v)`, each called from a checked generic with its symbolic `U` | no diagnostic (TP-1: STOP generic_region_stack.h:98) |
| generic_class_field | C2 | R3, D-CT-7: `Holder(T)` with a `Cpp.Box(T)` field, read in `Get` and made in `Make` (which calls `Cpp.MakeBox(v)`) | no diagnostic |
| alias_of_specialization | C1 | R8, R9, R10, D-CT-17, D-CT-7's other-generic case, D-CT-5's constant-value step: `alias B = Cpp.Box(T);` in a checked class (a field, `fn Get(b: B) -> T`, `fn Make(v: T) -> B` with `var b: B;`), in a class template and in a checked function's body | no diagnostic (TP-1: E-DU at `var b: B;`) |
| member_missing_uncalled | C1 | D-CT-2: an uninstantiated body is not diagnosed | no diagnostic |
| copy_into_specialization_uncalled | C1 | D-CT-2's copy row: `b.value = v;` with `v: T` and no `Core.Copy` | no diagnostic |
| fail_member_missing_on_instantiation | C1 | D-CT-2 | ``unable to monomorphize specific `F(i32)` [ResolvingSpecificHere]`` at the call, ``note: member name `nope` not found in `Cpp.Box` [MemberNameNotFoundInInstScope]`` at `b.nope` |
| fail_copy_into_specialization_on_instantiation | C1 | D-CT-2's copy row on instantiation, a class without `Core.Copy` | ``unable to monomorphize specific `F(NoCopy)` [ResolvingSpecificHere]`` at the call, with ``note: cannot copy value of type `NoCopy` [CopyOfUncopyableType]`` and ``note: type `NoCopy` does not implement interface `Core.Copy` [MissingImplInMemberAccessInContext]`` at `v` in `b.value = v;` |
| fail_cpp_error_on_instantiation | C2 | D-CT-2, D-CT-10 | ``./box.h:8:46: error: invalid operands to binary expression ('Carbon::Point' and 'Carbon::Point') [CppInteropParseError]`` and ``note: in instantiation of function template specialization 'Twice<Carbon::Point>' requested here [CppInteropParseNote]``, each under `in file included here [InCppInclude]` |
| fail_copy_symbolic_value_in_definition | C2 | D-CT-2: the checked generic's own rules where it is defined | ``cannot copy value of type `T` [CopyOfUncopyableType]`` with its `Core.Copy` note and ``cannot access member of interface `Core.Destroy` in type `T` that does not implement that interface [MissingImplInMemberAccess]``, where `F` is defined |
| fail_symbolic_value_cpp_call_in_definition | C2 | D-CT-3's predicate: `Cpp.TakeInt(N, N)` for `generic N: i32` is resolved where `F` is defined | ``no matching function for call to 'TakeInt' [CppInteropParseError]`` at the call with ``./box.h:12:12: note: candidate function not viable: requires single argument 'x', but 2 arguments were provided [CppInteropParseNote]``, as on TP-1 and the nightly (rev 1's predicate: no diagnostic) |
| cpp_result_contagion_uncalled | C2 | F-021's contagion: `let b: bool = G(Cpp.TakeInt(Cpp.Twice(x)));` in an uninstantiated body | no diagnostic (TP-1: E-ARG where `F` is defined) |
| fail_cpp_result_contagion_on_instantiation | C2 | F-021's contagion on instantiation | ``unable to monomorphize specific `F(i32)` [ResolvingSpecificHere]`` at the call, with ``note: cannot implicitly convert expression of type `i32` to `bool` [ConversionFailure]`` and ``note: type `i32` does not implement interface `Core.ImplicitAs(bool)` [MissingImplInMemberAccessInContext]`` at the initializer |
| fail_todo_form_dependent_arg | C2 | W-307: `Cpp.TakeInt(x)` for `x:? Fm` | ``semantics TODO: `Support passing form-dependent args to C++ functions.` [SemanticsTodo]`` at `x`, where the call is written, as on TP-1 |
| fail_todo_struct_arg | C1 | W-300, W-306 | ``unable to monomorphize specific `F({.a: i32})` `` with ``fail_todo_struct_arg.carbon: note: semantics TODO: `unsupported type used as template argument` [SemanticsTodo]`` (no line) |
| fail_todo_template_template_carbon_generic | C1 | W-301 (renamed from rev 1's `fail_template_template_carbon_generic`) | ``error: template argument for template template parameter must be a class template or type alias template [CppInteropParseError]`` at `List` |
| fail_todo_deduce_through_specialization | C1 | W-303 | ``cannot deduce value for generic parameter `T` [DeductionIncomplete]`` with ``note: while deducing parameters of generic declared here [DeductionGenericHere]`` |
| fail_todo_impl_forall_specialization | C1 | W-303's impl shape: `impl forall [T: type] Cpp.Box(T) as Size` | `` `impl` with unused generic binding [ImplUnusedBinding]`` at `T` (TP-1, trunk and the nightly: STOP sem_ir/generic.cpp:84) |
| fail_todo_choice_payload_specialization | C1 | W-308: `choice Holder(T: type) { Full(b: Cpp.Box(T)), Empty }`, used in `F(i32)` | two ``unable to monomorphize specific `F(i32)` `` (W-306's repetition): the first with ``note: `Holder(T)` evaluates to incomplete type `Holder(i32)` [IncompleteTypeInMonomorphization]`` and ``note: choice alternative payload type `Cpp.Box` is not trivially copyable and destructible in this specific [ChoicePayloadNotTrivialInSpecific]`` at the choice, the second with the same payload note at `Holder(T).Empty` (TP-1: STOP sem_ir/generic.cpp:84 at the declaration) |
| fail_todo_member_through_constraint | C1 | W-305; `Direct` and `Compound` compile | ``unable to monomorphize specific `Simple(S as Show)` `` with ``note: member name `Get` not found in `S` [MemberNameNotFoundInInstScope]`` |

box.h gains `inline int TakeInt(int x) { return x + 100; }` for the three
`TakeInt` splits.

lower/testdata/interop/cpp/template_symbolic_arg.carbon (A.2), under the full
prelude, eight splits:

| Split | Commit | Pins | Fill (measured) |
| --- | --- | --- | --- |
| two_specifics | C1 | D-CT-1: `Loud<int>` and `Loud<Carbon::Point>` | both specializations' constructors' thunks and destructors (`@_ZN4LoudIiED2Ev`, `@_ZN4LoudIN6Carbon5PointEED2Ev`), and the two specifics of `Keep`: `void @_CKeep.Main.<hash>(ptr sret({ i32 }) %return, ptr %v)` and `i32 @_CKeep.Main.<hash>(i32 %v)` |
| narrow_return_template | C1 | R4, D-CT-8 in a template, pinned in C1 (review fold: B-m6) | `i16 @_CTemplate.Main.<hash>(i16 %v)`, no return slot, calling `@_Z5TwiceIsET_S0_.carbon_thunk._` |
| narrow_return_checked | C2 | R4, D-CT-8 in a checked generic | `i16 @_CChecked.Main.<hash>(i16 %v)`, the same call |
| class_return | C2 | D-CT-8's in-place side | `void @_CMake.Main.<hash>(ptr sret([4 x i8]) %return, i32 %v)` |
| alias_of_member_type | C1 | R8, D-CT-17, pure Carbon: `alias B = T.Inner;` of `class C(template T: type)` in `Make`'s signature and body | `i32 @_CMake.C.Main.<hash>(i32 %v)` (TP-1 and trunk: E-DU; without D-CT-17, STOP lower/file_context.h:187) |
| generic_class_field | C1 | R3, D-CT-7 | `i32 @_CGet.Main.<hash>(ptr %h)` |
| var_template | C1 | R5, D-CT-9 | `@_Z5PlainIiE = linkonce_odr dso_local global i32 5` and `@_Z5PlainIlE = linkonce_odr dso_local global i32 9` |
| exported_class_argument | C1 | R6, D-CT-10 | `@_Z2IdIN6Carbon5PointEET_S2_` and its thunk (TP-1: the clang assertion) |

check/testdata/generic/template/default_init.carbon (A.5), two new splits in
C1, both pure Carbon and both without a diagnostic or dump (TP-1: E-DU at the
`var`): `var_uninit_associated_type` (W-268's function shape, `var e:
T.Elem;` in `fn F[template T: Container]`) and `class_alias_var_uninit`
(W-268's class shape, review A's B1 form: `var b: B;` for `alias B =
T.Inner;` in `class C(template T: type)`).

Refills (§0.7): check/interop/cpp/template/generic_call.carbon (F1),
non_type_param.carbon (F1), var_template.carbon (C1's source change, F1's fill:
A.3's new split `fail_non_inline_static_member_template` with
``./non_inline_static.h:5:33: error: non-const static data member must be
initialized out of line [CppInteropParseError]`` and ``note: in instantiation
of static data member 'Wrap::var<A>' requested here [CppInteropParseNote]``),
lower/interop/cpp/globals.carbon (C1's source change, F1's fill),
check/generic/template/deduce_class_args.carbon (A.6's rename in C1, F1 drops
the split's seven STDERR lines) and check/interop/cpp/range_for.carbon (F1:
four notes move to the alias's expression). No other golden changes; the gate
after F1 and after F2 is 1959 of 1959.

## §5 Conformance delta (from 138 / 0 / 22 over 160)

| State | PASS | FAIL | SKIP | Programs | Bullets PASS |
| --- | --- | --- | --- | --- | --- |
| TP-1 (this branch's base) | 138 | 0 | 22 | 160 | 48 of 56 |
| after P (measured on v11, and on v12 with rev 2's differential values) | 147 | 0 | 20 | 167 | 48 of 56 |
| trunk, the floor of record | 128 | 0 | 22 | 150 | n/a |

The +9 PASS are the two un-SKIPped programs and the seven new ones; no program
changes status otherwise (the runner's scoreboards on TP-1 and v12 differ only
in those nine rows). Relative to trunk the tree is +19 PASS, -2 SKIP and +17
programs, TP-1's ten programs included.

## §6 Churn and collisions

Ten toolchain files, 265 lines added and 13 removed (rev 1: seven
files, +167/-11, which rev 1 misstated as +163/-11; amended 2026-10-21, review
fold: B-m1); two new goldens (2707 lines filled, 631 of them source); six
refills (+290/-207 CHECK and source lines) and default_init.carbon's 45 source
lines; nine programs and an oracle; the records. At land time S-VA adds 4 and
removes 2 lines of call.cpp with one split. No generated file, X-macro or
diagnostic kind changes. Collisions are §0.9's: textual offsets with PR 57, PR
59, PR 60 (TP-1's own two convert.cpp hunks, resolved by TP-1's M) and PR 62;
the semantic compositions with PR 59 (S-VA) and PR 62 (OUT rows); the content
rules C-1 (PR 51's programs), C-2 (PR 51's split and TP-1's F6) and C-3 (PR 58's
page and records).

## §7 Risks and rejected alternatives (falsifiable)

### §7.1 Risks

1.  D-CT-5 defers more impl lookups in checked generics than D-TP-12 did: any
    query whose self or interface arguments reach a `TemplateInst`, by
    operands or (rev 2) by a symbolic operand's constant value. Measured: the
    gate changes only generic_call.carbon among such files, and
    facet/period_self.carbon (D-TP-12's other falsifier) is unchanged.
    Falsified by a golden outside the six of §0.7 changing in F1.
2.  D-CT-2 (F-021) moves errors on a C++ specialization in a checked generic,
    and on every Carbon operation on a deferred C++ call's result, from the
    definition to the instantiation (A.1's contagion splits): a library author
    no longer sees them until a caller instantiates, and `let b: bool =
    G(Cpp.TakeInt(Cpp.Twice(x)));` compiles in a body that is never
    instantiated (n10). Upstream has no rule here (proposal 2200 leaves a
    checked generic's template use to future work), which is why F-021 is a
    fork decision; leads issue 2153 chose this behavior for templates, and C++
    gives the same. Falsified by an operation that the definition could check
    and does not: a Carbon operation whose operands do not reach a deferred
    C++ form (the gate and n12 show none), or a C++ call whose argument types
    are concrete (A.1's `fail_symbolic_value_cpp_call_in_definition`).
3.  D-CT-7 substitutes into constant action operands and (rev 2) into
    operands of another generic; an action that is a constant and also refers
    to a body instruction of its own generic would be rewritten. v10's
    restriction kept every golden, and v12's widening changes none; falsified
    by v9's class of change reappearing in F1 or F2.
4.  D-CT-9 makes ill-formed variable template definitions errors on use. Two
    goldens had such C++ (A.3, A.4); user code with the same C++ is rejected
    by clang++ too. Falsified by a well-formed variable template that now
    fails.
5.  D-CT-3 builds `CallAction`s for every C++ call in a checked generic with an
    argument of a checked-symbolic type, which increases eval-block size.
    Measured cost: no golden's runtime moved by more than noise in the gate
    (1957 tests, 4 threads: 27.7 s wall and 103.9 s across threads on TP-1,
    27.2 s and 104.9 s on v11, 28.7 s and 110.9 s on v12); the nine changed
    or new goldens run in 0.7 s on v12g.
6.  The C-2 finding means TP-1's land-time F6, as written, would leave a
    `unformed_dependent_var` split that still reports an error, a red golden
    at TP-1's land. Hand-off note H-1 routes it; CT-1's L-F takes the rename,
    or refills TP-1's rename if PR 61 keeps it (§1.16's fallback).
7.  D-CT-17 attaches an alias's dependent instructions to the enclosing
    generic, which every alias in a generic now does, CT-1's or not (added
    2026-10-21, review fold: A-B1 / A-B2). Measured: one golden outside CT-1's
    own changes, range_for.carbon, moves four notes from the prelude alias's
    name to its expression (§0.7), and deduce_class_args.carbon's W-273 split
    succeeds; no alias of a non-template-dependent value changes. Falsified by
    a golden whose alias is not template-dependent changing in F1 beyond a
    diagnostic's location, or a stop at sem_ir/generic.cpp:84 in any probe.
8.  The fold added eight OUT rows to §1.11 from the reviews' probes; a form
    neither review probed may still stop (the class of A-M4). Mitigation: the
    focused re-review loop (§3 item 9) re-runs the §0.12 probes and asks each
    reviewer for new probes in the slice's domain; falsified by a stop that a
    re-review finds in an IN form.

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
    body references are rewritten. Rejected for v10's rule, which v12 widens
    by the other-generic case only.
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
12. **Do not defer an impl lookup whose splice belongs to an enclosing
    generic's eval block** (review A's second remedy for A-B1; added
    2026-10-21): a guard over R8, which would keep E-DU for f06, d07 and A.5's
    class shape and leave the stops of f07, ret_alias, n15, d03 and d04 on
    every toolchain (R17). Rejected for D-CT-17.
13. **Defer on the argument's own dependence** (rev 1's predicate; added
    2026-10-21, review fold: A-B3): defers a call whose C++ types are known,
    for a symbolic value of a concrete type, and loses the definition's
    diagnostics (b01, b02). Rejected for the type's dependence.
14. **Keep definition checking of Carbon operations on a deferred C++ call's
    result** (added 2026-10-21, review fold: A-M1): the result has no type
    until Clang resolves the call in a specific, so there is nothing to check
    against; a fixed result type would be a guess that a specific can
    falsify. Rejected; F-021 records the contagion as the rule.
15. **Defer a form-dependent argument's call too** (rev 1's behavior; added
    2026-10-21, review fold: B-M1): a specific gives the argument no form
    either, so the deferral only moved the TODO into an instantiation note and
    let an uncalled body compile. Rejected; W-307.
16. **`clang::Sema::isCompleteType` in D-CT-10** (review A's alternative;
    added 2026-10-21, review fold: A-m3): needs a `Sema` and a location the
    function does not have, for a case no input reaches. Rejected for the
    `CARBON_CHECK`.
17. **Extend D-CT-5's walk to W-268's runtime-operand shape** (`var a: x.0;`
    for a runtime `x`; B-M2's other option; added 2026-10-21): the walk would
    have to follow a runtime value's type to a template binding, deferring
    every lookup whose query mentions such a value, for a split that fails on
    instantiation anyway (``expression is runtime; expected constant``).
    Rejected; W-268 is narrowed to that shape and stays open.
18. **Attach every discarded generic region to its enclosing generic** (all
    callers of `DiscardGenericDecl`; added 2026-10-21): custom_witness.cpp's
    scaffolding, namespaces and `export` have no expression a specific
    evaluates, and a region discarded on error must not leak its bindings.
    Rejected for the alias-only change of D-CT-17.

## §8 Verification and discharge

Rewritten 2026-10-21 (review fold: B-m5 / B-m6 / A-m3). All of it is
container-local, EXPECTED and not of record (R9, R28): every number this
section's runs produce is recorded with that label, in the plan's landed notes,
the PR's first comment and Appendix C's texts. `$CB` is the carbonbuild scripts'
directory,
`/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/carbonbuild/`
(fork/tools/carbonbuild does not exist on this branch); `$X` is the
implementer's scratch directory; CT-1's own build directory is
/home/user/carbon-build/carbon-ct.

**Stop-and-amend rule.** If a fill (F1, F2, a fix commit's fill, L-F), the gate
or P differs from its prediction here or in §4 (another golden changes, a line
count or a diagnostic's text differs, a total differs), the implementer stops
before committing that step, records the difference with its log, and the plan
is amended (a new revision, reviewed under §3 item 9's loop) before the step is
committed; a second autoupdate pass that only renumbers `[[@LINE+N]]` offsets
is not a difference.

1.  **Build and install** after each code commit (C1, C2, each fix commit, S-VA
    on its mirror), a full build, not a relink: `$CB/build.sh
    /home/user/carbon-ct && $CB/install.sh /home/user/carbon-ct`; `carbon
    version` prints the head's hash. The build regenerates file_test's manifest
    from the tree's globs, so new goldens need no manifest copy (H-3).
2.  **Autoupdate to a fixpoint** after each code commit: `$CB/autoupdate.sh
    /home/user/carbon-ct <the commit's goldens>` (F1: A.1, A.2, the six
    refills and default_init.carbon; F2: A.1 and A.2) until a pass writes
    nothing; the fill commit is exactly the passes' output.
3.  **Gate**: `$CB/gate.sh /home/user/carbon-ct`: 1959 of 1959 after F1, F2
    and each fix commit's fill, 0 autoupdate-would-change marks.
4.  **Conformance**: `mkdir -p $X/xdg && XDG_CACHE_HOME=$X/xdg
    $CB/conformance.sh /home/user/carbon-ct $X/conf`: 147 / 0 / 20 over 167
    after P, 48 of 56 bullets; the differential program's oracle prints
    `60000`, `-5536`, `3`; then `python3 fork/conformance/runner.py
    --update-readme-table` and `--self-test`.
5.  **Mutants**, each relinked over CT-1's build with the translation unit it
    edits recompiled (into /dev/shm, deleted after use), and run over the whole
    gate and the programs; each must turn something red, and the record names
    what. Measured for rev 2 on v12g over the nine changed or new goldens
    (EXPECTED, not of record; `$X/mut/<m>.py` holds each edit and
    `$X/logs/mut_<m>.log` its run, `$X` here the fixer's scratch):

    | Mutant | Reverts | Measured on v12g (2026-10-21) | Killed |
    | --- | --- | --- | --- |
    | M1 | D-CT-5's `TemplateInst` clause | A.1 stops file_test: FATAL custom_witness.cpp:487 ``Unexpected type for CanDestroyType: SpliceInst`` at generic_class_field's `return` | yes |
    | M2 | D-CT-5's `MetaInstId`/`MetaInstBlockId` walk | the same stop | yes |
    | M3 | D-CT-6 | A.1 stops: CHECK generic_region_stack.h:98 at template_called_from_checked_generic | yes |
    | M4 | D-CT-7's `PushOperand`/`PopOperand` cases | A.1 stops: CHECK sem_ir/generic.cpp:84 (``Given a specific for the wrong generic``) at alias_of_specialization's `-> B` | yes |
    | M5 | D-CT-7's restriction (substitute every operand) | 25 goldens (v9, measured for rev 1) | yes |
    | M6 | D-CT-8 | A.2 stops: CHECK lower/handle_call.cpp:984 at narrow_return_template; the same on c1v12g, so C1 pins D-CT-8 (review fold: B-m6) | yes |
    | M7 | D-CT-8's `has_storage` in the kind only | not run; predicted A.2 class_return or narrow_return_template | at implementation |
    | M8 | D-CT-9 | red: non_type_param.carbon, var_template.carbon, globals.carbon, A.2 | yes |
    | M9 | D-CT-10's completion | A.2 stops: the clang assertion at exported_class_argument | yes |
    | M10 | D-CT-10's `CARBON_CHECK` only | not run: removing a check that no input fires changes nothing, so it survives by construction; recorded as defensive (review fold: A-m3) | no (defensive) |
    | M11 | D-CT-3 | red: A.1 (E-ARG at function_template_call, explicit_type_argument, generic_class_field, fail_cpp_error_on_instantiation, fail_copy_symbolic_value_in_definition) and A.2 | yes |
    | M12 | D-CT-3's `TemplateInst` wrapping of a type argument | nothing: the nine goldens pass and the 243 probes print what v12 prints (§1.3) | no: survives, kept for upstream parity |
    | M13 | D-CT-17 (handle_alias.cpp calls `DiscardGenericDecl` again) | A.2 stops: CHECK lower/file_context.h:187 at alias_of_member_type | yes |
    | M14 | D-CT-7's other-generic case | A.1 stops: CHECK sem_ir/generic.cpp:84 at alias_of_specialization's `-> B` | yes |
    | M15 | D-CT-5's constant-value step | red: A.1 alias_of_specialization, ``cannot convert type `B` into type implementing `Core.DefaultOrUnformed` `` at `var b: B;` | yes |
    | M16 | D-CT-3's predicate back to rev 1's | red: A.1 fail_symbolic_value_cpp_call_in_definition loses both diagnostics | yes |
    | M17 | D-CT-3's form-dependent refusal | red: A.1 fail_todo_form_dependent_arg loses the TODO | yes |
    | M18 | S-VA's pack expansion refusal (on the PR 59 mirror after S-VA) | predicted: S-VA's split compiles with no diagnostic | at land time |

6.  **clang-tidy**: the carbonbuild builds write no compile database, so
    after item 1 `ninja -C /home/user/carbon-build/carbon-ct -t compdb >
    $X/compile_commands.json`, then `/home/user/llvm/bin/clang-tidy -p $X
    --checks=-modernize-use-trailing-return-type <file>` (TP-1's and SV-1's
    exclusion) on the ten files; no new finding on a changed line. If the
    database cannot be generated, the step moves to item 11's not-run list
    with that reason.
7.  **prek** on every changed path, to a fixpoint, with R31's heading and
    list-item counts before and after each markdown edit:

    <!-- google-doc-style-ignore -->

    ```sh
    SKIP=fix-cc-deps,check-build-graph,check-bazel-mod-deps,forbid-llvm-googletest \
      uvx prek run --files <paths>
    ```

    <!-- google-doc-style-resume -->
8.  **runner.py --self-test** after P (the README table regenerated).
9.  **Composition mirrors**, each a scratch clone of the branch head after D
    (`git clone --shared /home/user/carbon-ct $X/m-<pr>`), the held PR's head
    merged with records conflicts taken from this branch, built with
    `CB_BUILD_ROOT=/dev/shm/ct1-impl/builds $CB/build.sh $X/m-<pr> &&
    CB_BUILD_ROOT=/dev/shm/ct1-impl/builds $CB/install.sh $X/m-<pr>`, gated and
    run over the programs and the §0.12 probes. Predicted red sets: PR 59
    (b0822a744), none before S-VA beyond what S-VA's split adds after it (mva
    measured the code with the refills absent: exactly CT-1's six goldens
    red); PR 62 (3a6531157), none (msv: the same six only); PR 60
    (40a76ab81), with TP-1's M resolution of PR 60's two convert.cpp hunks as
    TP-1's plan writes it, SC-1's goldens unchanged and the template
    constraint probe of §0.9 behaving as on the same mirror without CT-1;
    PR 57 (628273444), none; PR 51 (f96fe8a7a), its
    `fail_todo_unformed_dependent_var` red (it now succeeds: C-2's rename) and
    the two programs passing with C-1's merged text.
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

Measured for rev 2 (2026-10-21, EXPECTED, not of record): review A's 73 probes
and the fold's on TP-1, trunk, the nightly, v11 and v12 (§0.12), 243 in the
final v12 matrix; v12's and c1v12's gates (1951 of 1957, the six rows of §0.7)
and the six refills autoupdated to a fixpoint; A.1, A.2 and A.5 filled to a
fixpoint on v12g and their C1 subsets on c1v12g, identical; conformance on v12
with the new differential values (147 / 0 / 20); full builds of the PR 59 and
PR 62 compositions (mva, msv) gated (1969 of 1975 and 1959 of 1965, the red
set exactly CT-1's six) with their probes, and S-VA on mva; the held PRs'
numstats and dry-runs onto v12; the land-time paragraph and fixture X37 under
PR 58's check_samples.py on a PR 58 mirror (Appendix C.1); mutants M1 to M4,
M6, M8, M9 and M11 to M17 on v12g and M6 on c1v12g; the upstream log over
CT-1's ten files; the id re-scan.

Not measured: a full build.sh/install.sh of this branch's own state (relinks of
the changed objects over TP-1's build for v12, and full builds of the two
mirrors, which compiled the ten files and generic.h's includers); M7, M10 and
M18; clang-tidy; prek on anything but this file; runner.py --self-test with
the new README table; the PR 51, PR 57 and PR 60 mirrors (PR 60 predicted,
§0.9); the C-2 rename on PR 51's own golden (its split could not be run here:
it is not in TP-1's manifest, and the probe of its shape stands in); S-VA's
split's fill; hosted CI.

## Hand-off notes for the implementer

-   **H-1 (for the orchestrator, PR 61).** TP-1's plan predicts that PR 51's
    split `fail_todo_unformed_dependent_var` succeeds with TP-1 and renames it
    in TP-1's land-time F6; on TP-1's toolchain the split's shape is still
    rejected (w127/w127_unformed and ra/h01, E-DU). TP-1's F6 should drop that
    rename, and its W-127 discharge text should not claim the checked shape;
    CT-1's L-F takes the rename (§0.9 C-2). CT-1 cannot edit PR 61. If PR 61
    lands with the rename, §1.16's fallback applies: CT-1's L-F refills the
    renamed split with CT-1's toolchain, which makes it pass (added
    2026-10-21, review fold: B-m6).
-   **H-2.** The diffs of §2 are measured; apply them verbatim. If a reviewer
    asks for a different structure, measure it against the same gate before
    changing the plan.
-   **H-3.** New goldens are listed in file_test's manifest by the full build
    (`$CB/build.sh` regenerates it from the globs); the relinked manifest copy
    of §0.7 was the prototype's workaround, not a step.
-   **H-4.** The two programs' bodies differ from PR 51's; do not take PR 51's
    text on this branch (C-1's rule applies at M).
-   **H-5.** Keep the probe scripts and matrices out of the repository: they
    are scratch evidence; the plan's tables are the record.
-   **H-6.** Never hand-write a CHECK line; never edit a golden's CHECK lines;
    the two header fixes (A.3, A.4), A.5's splits and A.6's rename are source
    edits that autoupdate then fills.
-   **H-7 (S-VA).** S-VA is the only land-time code: Appendix C.11's call.cpp
    hunk, measured on mva, and its split; it lands right after M, with its own
    fill, and before L-F's other refills (added 2026-10-21, review fold:
    B-M3).
-   **H-8 (TP-1's records).** CT-1 edits exactly these TP-1 records: W-268
    (narrowed), W-273 (discharged), and one dated line each on D-TP-12, TR-22
    and W-274 in fork/templates/plan.md (Appendix C.5, C.11); nothing else of
    TP-1's (added 2026-10-21, review fold: B-m2).

## Review fold record (rev 2, 2026-10-21)

Plan reviews A (REJECT, twelve findings) and B (APPROVE-WITH-AMENDMENTS,
thirteen findings) of rev 1 (7865787a7) were folded into rev 2 by the fixer.
Each finding was reproduced or checked at its cited location before it was
folded; the measurements are the fixer's own (`$X`, the fixer's scratch
directory; binaries under /dev/shm/ct1-fixer, deleted after use; EXPECTED, not
of record, R9). All 25 are folded; none is rejected. The prototype changed
from v11 to v12 (ten files, +265/-13), and every measurement that the change
touches was re-run on v12 (§0.7, §0.8, §0.12, §8 item 5).

| Finding | Severity | Reproduced | Disposition | Where |
| --- | --- | --- | --- | --- |
| A-B1 | BLOCKER | yes: f06, d07 and c04 are E-DU on TP-1, trunk and the nightly and STOP lower/file_context.h:187 on v11; the initialized f07 and the pure-Carbon ret_alias stop on every toolchain, so the E-DU hid a defect that was already there | Folded at the root: the alias's generic region was discarded with its dependent instructions unattached (R8), and a member's action kept the class's operand (R9); D-CT-17 attaches the region to the enclosing generic and D-CT-7 substitutes an operand of another generic; v12 runs f06, f07, d07, c04, ret_alias, n14, n15 (5, 5, 17, 11, 5, 16, 17); review A's guard alternative is rejected (R17); pinned by A.5's `class_alias_var_uninit` (pure Carbon), A.1's `alias_of_specialization`, A.2's `alias_of_member_type`, mutants M13 and M14 | §0.4 H8, H9; §0.5 R8, R9; §0.7; §0.12; §1.7; §1.18; §2.3; §2.12; §4; §7.2 item 12; A.1, A.2, A.5 |
| A-B2 | BLOCKER | yes: d01 is E-ARG on TP-1 and STOP file_context.h:187 on v11, a11 E-DU everywhere, d08 the ``{.b: Cpp.Box}`` conversion error on v11 | Folded with A-B1 plus R10: a name reference to the alias reaches the specialization only through its constant value, which D-CT-5's walk now follows; v12: d01 11, a11 11, cls_alias_var 2, d08 18, d03 13, d04 14; the alias forms are IN in D-CT-11 and pinned by A.1's `alias_of_specialization` (field, `Get`, `Make`, class template, function body) and mutant M15 | §0.5 R10; §1.5; §1.11; §2.1; §4; A.1 |
| A-B3 | BLOCKER | yes: b01 and b02 compile on v11 where TP-1 and the nightly report ``no matching function for call to 'TakeInt'`` and the `bool` conversion | Folded as review A proposed: D-CT-3 defers on the argument's type's dependence, or a facet-typed value's own; v12 reports TP-1's diagnostics for b01 to b03 and n09 prints 113; pinned by A.1's `fail_symbolic_value_cpp_call_in_definition` and mutant M16 | §1.3; §2.7; §4; §7.2 item 13; A.1 |
| A-M1 | MAJOR | yes: g01 is accepted uncalled on v11 and diagnosed on TP-1; a03 prints 1 2 3 | Folded: F-021 minted for the checked-generic C++ rule with its contagion and the lost definition checks; D-CT-2 restated with a per-operation table and a new break condition; TR-22 amended (D-CT-4, Appendix C.11's dated line); the contagion pinned by `cpp_result_contagion_uncalled` and `fail_cpp_result_contagion_on_instantiation` | §1.2; §1.4; §1.17; §7.1 item 2; §7.2 item 14; C.7; C.11; A.1 |
| A-M2 | MAJOR | yes: `git log c1e83b0b7..upstream/trunk` per file shows 4a8993af2, 24766e213, 2c9739799 and 62f1cc6a3 in interop/cpp/template and eighteen commits on rev 1's seven files | Folded: §0.10 lists every CT-1 file with its commits and an overlap verdict; register entries with merge rules for 4a8993af2 (D-CT-8), 24766e213 and eb66bebc3 (D-CT-7) and the two upstream goldens' header edits (A.3, A.4) | §0.10; C.7 |
| A-M3 | MAJOR | yes: e08 and e09 run on v11 (1, 0) | Folded: the PR 62 composition built in full (msv), gated (1959 of 1965, CT-1's six only) and probed (sv1 to sv8): `std::optional(T)` IN, its conversion OUT under W-279 and its `match` OUT under W-252; the PR 60 composition predicted with a break condition and a probe for the template-constraint form, measured at implementation (§8 item 9) | §0.1; §0.9; §1.11; §8 item 9 |
| A-M4 | MAJOR | yes: e02e and c09 stop at sem_ir/generic.cpp:84 on TP-1, trunk and v11, d03 at lower/type.cpp:459 on all four | Folded: d03 and d04 run on v12 (R9); the choice declaration compiles and its use is W-308; the impl shape is `` `impl` with unused generic binding `` and extends W-303; pinned by `fail_todo_choice_payload_specialization` and `fail_todo_impl_forall_specialization` | §0.12; §1.11; §1.12; C.3; A.1 |
| A-M5 | MAJOR | yes: no default_init.carbon split in rev 1; the class shape stopped on v11 (A-B1) | Folded: A.5 adds `var_uninit_associated_type` and `class_alias_var_uninit` to default_init.carbon, both passing on v12; with B-M2, W-268 is narrowed, not discharged | §1.5; A.5; C.5 |
| A-m1 | MINOR | yes: 39 + 88 + 21 = 148 | Folded: 88 | preamble; §0.5 |
| A-m2 | MINOR | yes: `Worklist::Push` is at subst.cpp:72, the field at :47-48 | Folded | §2.3 |
| A-m3 | MINOR | yes: no measured input reached rev 1's `return false` | Folded: a `CARBON_CHECK`, recorded as defensive (mutant M10); `isCompleteType` rejected because the function has no `Sema` | §1.10; §2.6; §7.2 item 16; §8 item 5 |
| A-m4 | MINOR | yes: a06, c06, c07 E-MONO on v11 and v12, the concrete c01 E-DU everywhere | Folded: an OUT note says that the uninitialized-`var` rule is the specialization's, not an aggregate's | §1.11 |
| B-M1 | MAJOR | yes: type_mapping.cpp:733-736's TODO fires for `x:? Fm` on TP-1, trunk and the nightly; v11 moved it into an E-MONO note and compiled an uncalled body (n01 to n03) | Folded: D-CT-3 refuses a form-dependent argument, so the TODO is reported where the call is written; W-307 filed; §0.2's "stale in the same way" corrected; pinned by `fail_todo_form_dependent_arg` and mutant M17 | §0.2; §1.3; §1.11; §1.12; §2.7; C.2; C.3; A.1 |
| B-M2 | MAJOR | yes: index.carbon's `fail_tuple_index_as_var_type_on_instantiation` is unchanged by v12 (not in the gate's red set) | Folded: W-268 narrowed to the runtime-operand shape (title, evidence, removal); extending the walk to runtime operands is rejected | §1.5; §7.2 item 17; C.5 |
| B-M3 | MAJOR | yes: on mva (PR 59 composed, built in full) without S-VA, va1, va2 and va5 are deferred and VA-1's diagnostic is lost | Folded: each held PR's numstat listed; the PR 59 and PR 62 compositions built and gated (1969 of 1975 and 1959 of 1965, CT-1's six only); S-VA, a land-time code commit after M that refuses a pack expansion argument, measured on mva (va1, va2, va5 report VA-1's error again); the sum-type disposition is OUT under W-279 and W-252 with break conditions | §0.9; §1.3; §1.11; §1.16; §2.11; §3 item 13; C.11; H-7 |
| B-M4 | MAJOR | yes: the QUOTE's lowercase `a` does not occur in the prose, X34 is TP-1's, and no `SAMPLES` entry was given | Folded: the QUOTE is the sentence verbatim, the fixture is X37 with its `SAMPLES` entry after X09's and X09's comment updated; PR 58's check_samples.py with `--toolchain`, run on a PR 58 mirror, passes X37 on v12 and fails it on TP-1 | §1.15; §2.11; C.1 |
| B-M5 | MAJOR | yes: xlib x1, x2 and x5 report D-TP-14's TODO on v11 and v12 | Folded: row 56 and the page paragraph say "within one library (W-250)" and name W-305; row 42's clause is qualified with W-300 | §1.15; C.1; C.4 |
| B-M6 | MAJOR | yes: `b.value = v` with `T` without `Core.Copy` is E-MONO on v11 and unpinned | Folded: §1.2's per-operation table names the TP-1 rule each operation rides; `copy_into_specialization_uncalled` and `fail_copy_into_specialization_on_instantiation` pin the copy; programs and fixture both use `[T: type]` | §1.2; §1.14; A.1; C.1 |
| B-m1 | MINOR | yes: rev 1's numstat is +167/-11 and convert.cpp +18/-6 | Folded: rev 1's and rev 2's counts stated | preamble; §0.5; §0.7; §2.4; §6 |
| B-m2 | MINOR | yes: TP-1's D-TP-12, TR-22 and W-274 say what CT-1 changes | Folded: one dated line each, and a statement that these, W-268 and W-273 are CT-1's only TP-1 record edits | §1.15; C.11; H-8 |
| B-m3 | MINOR | yes: subst.cpp (24766e213, eb66bebc3), action.cpp (0d3b606a5, 4a8993af2), impl_lookup.cpp (eight commits) | Folded with A-M2: the per-file table and the D-CT-7 register entry | §0.10 |
| B-m4 | MINOR | yes: the held PRs put the rows elsewhere than PR 58's 62 and 48 | Folded: rows are found by bullet text after M; M takes DD-1's W-043 entry and the records commit reapplies C.2 | §1.15; §1.16; §2.11; C.2; C.4 |
| B-m5 | MINOR | yes: rev 1's §8 named no commands | Folded: `$CB` commands for build, autoupdate, gate, conformance, mutants, clang-tidy and mirrors; a stop-and-amend rule; R9 labels | §8; C.2 |
| B-m6 | MINOR | yes: rev 1 had no re-review loop, D-CT-8's only pin was C2's, and no fallback for PR 61's F6 | Folded: a capped focused re-review loop (§3 item 9); `narrow_return_template` in C1 (M6 on c1v12g stops in it); the C-2 fallback | §1.8; §1.16; §3 item 9; §4; H-1 |
| B-m7 | MINOR | yes: 6, 60 and 3 print the same under `Acc<int>` and `Acc<short>` | Folded: three 20000s give 60000 and -5536 (v12 and the oracle agree); the W-301 split is `fail_todo_template_template_carbon_generic`, and W-301's removal names it | §1.14; §4; Appendix B; A.1; C.3 |

Also changed by the fold, outside the findings: W-309 filed (a deferred C++
call's temporary is not destroyed, in a template on TP-1 and the nightly too;
w6, w7, w9); mutant M12 (the `TemplateInst` wrapping of a type argument)
survives every measured input and is kept for upstream parity with a break
condition (§1.3); W-308's citation is handle_choice.cpp:762; var_template's
refill is +25/-1. Rev 1's decisions D-CT-1, D-CT-6, D-CT-8, D-CT-9, D-CT-12
and D-CT-13 stand with amended evidence; D-CT-17 is new.

## Appendix A: golden sources

Every new or changed golden source, without CHECK lines (R16(a)). A.1 and A.2
are new files; their C2 splits (§4: nine of A.1's twenty-three, two of A.2's
eight) are added by commit C2 and the rest by C1, so C1's files are these with
the C2 splits left out (measured as c1v12g's sources). Rewritten 2026-10-21
for rev 2 (review fold: A-B1 / A-B2 / A-B3 / A-M1 / A-M4 / A-M5 / B-M1 / B-M6 /
B-m6 / B-m7): A.1 gains nine splits and `TakeInt` in box.h and renames
`fail_template_template_carbon_generic`; A.2 splits `narrow_return` and gains
`alias_of_member_type`; A.3's second hunk header is the exact one (rev 1's
`@@ -34,4 +34,20 @@` applied only with fuzz); A.5 and A.6 are new.

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
inline int TakeInt(int x) { return x + 100; }

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

// --- alias_of_specialization.carbon

library "[[@TEST_NAME]]";

import Cpp library "box.h";

// A class-scope alias of a specialization of the class's parameter, used in a
// member's signature, as a field's type and as a `var`'s type, in a checked
// generic class and in a class template; and an alias in a function's body.
class Checked(T: type) {
  alias B = Cpp.Box(T);
  var b: B;
  fn Get(b: B) -> T { return b.value; }
  fn Make(v: T) -> B {
    var b: B;
    b.value = v;
    return b;
  }
}

class Template(template T: type) {
  alias B = Cpp.Box(T);
  fn Make(v: T) -> T {
    var b: B;
    b.value = v;
    return b.value;
  }
}

fn InFunction[T: type](v: T) -> T {
  alias B = Cpp.Box(T);
  var b: B;
  b.value = v;
  return b.value;
}

fn G() -> i32 {
  var c: Checked(i32) = {.b = Cpp.MakeBox(1 as i32)};
  return c.b.value + Checked(i32).Get(Checked(i32).Make(2)) +
         Template(i32).Make(3) + InFunction(4 as i32);
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

// --- copy_into_specialization_uncalled.carbon

library "[[@TEST_NAME]]";

import Cpp library "box.h";

// Storing a `T` in the specialization copies it, which needs `T` to be
// copyable; that is checked on instantiation, as the store is, so a body that
// is never instantiated is not diagnosed.
fn F[T: type](v: T) -> Cpp.Box(T) {
  var b: Cpp.Box(T);
  b.value = v;
  return b;
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

// --- fail_copy_into_specialization_on_instantiation.carbon

library "[[@TEST_NAME]]";

import Cpp library "box.h";

class NoCopy {
  var x: i32;
}

fn F[T: type](v: T) -> Cpp.Box(T) {
  var b: Cpp.Box(T);
  b.value = v;
  return b;
}

fn G() -> i32 { return F({.x = 8} as NoCopy).value.x; }

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

// --- fail_symbolic_value_cpp_call_in_definition.carbon

library "[[@TEST_NAME]]";

import Cpp library "box.h";

// A symbolic value of a concrete type maps to C++ where the generic is
// defined, so the call is resolved there and its error reported there, as on
// a function that is never instantiated.
fn F(generic N: i32) -> i32 {
  return Cpp.TakeInt(N, N);
}

// --- cpp_result_contagion_uncalled.carbon

library "[[@TEST_NAME]]";

import Cpp library "box.h";

fn G(n: i32) -> i32 { return n; }

// The result of a C++ call deferred to each specific has no type where `F`
// is defined, so the Carbon operations on it are checked on instantiation
// too; this one is never instantiated and not diagnosed.
fn F[T: type](x: T) -> i32 {
  let b: bool = G(Cpp.TakeInt(Cpp.Twice(x)));
  return if b then 1 else 0;
}

// --- fail_cpp_result_contagion_on_instantiation.carbon

library "[[@TEST_NAME]]";

import Cpp library "box.h";

fn G(n: i32) -> i32 { return n; }

fn F[T: type](x: T) -> i32 {
  let b: bool = G(Cpp.TakeInt(Cpp.Twice(x)));
  return if b then 1 else 0;
}

fn H() -> i32 { return F(1 as i32); }

// --- fail_todo_form_dependent_arg.carbon

library "[[@TEST_NAME]]";

import Core library "prelude/types/form";
import Cpp library "box.h";

fn F(generic Fm: Core.Form, x:? Fm) -> i32 {
  return Cpp.TakeInt(x);
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

// --- fail_todo_template_template_carbon_generic.carbon

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

// --- fail_todo_impl_forall_specialization.carbon

library "[[@TEST_NAME]]";

import Cpp library "box.h";

interface Size {
  fn Get(self) -> i32;
}

// `T` cannot be deduced through `Box<T>` (W-303), so the impl's parameter is
// not used in a way that identifies it.
impl forall [T: type] Cpp.Box(T) as Size {
  fn Get(self) -> i32 { return self.value * 0 + 5; }
}

// --- fail_todo_choice_payload_specialization.carbon

library "[[@TEST_NAME]]";

import Cpp library "box.h";

choice Holder(T: type) {
  Full(b: Cpp.Box(T)),
  Empty
}

fn F[T: type](unused v: T) -> i32 {
  let unused h: Holder(T) = Holder(T).Empty;
  return 2;
}

fn G() -> i32 { return F(1 as i32); }

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

// --- narrow_return_template.carbon

library "[[@TEST_NAME]]";

import Cpp library "templates.h";

fn Template[template T: type](v: T) -> T {
  return Cpp.Twice(v);
}

fn Use() -> i16 {
  return Template(8 as i16);
}

// --- narrow_return_checked.carbon

library "[[@TEST_NAME]]";

import Cpp library "templates.h";

fn Checked[T: type](v: T) -> T {
  return Cpp.Twice(v);
}

fn Use() -> i16 {
  return Checked(7 as i16);
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

// --- alias_of_member_type.carbon

library "[[@TEST_NAME]]";

class X {
  alias Inner = i32;
}

// A class template's alias of a type its parameter names, used in a member
// function's body and signature, is formed for each specific of the class.
class C(template T: type) {
  alias B = T.Inner;
  fn Make(v: B) -> B {
    var b: B;
    b = v;
    return b;
  }
}

fn Use() -> i32 {
  return C(X).Make(5);
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
@@ -34,6 +34,22 @@
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
 // CHECK:STDOUT:
 // CHECK:STDOUT: constants {
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

The refills of generic_call.carbon, non_type_param.carbon and range_for.carbon
change no source line.

### A.5 toolchain/check/testdata/generic/template/default_init.carbon (C1, two splits)

Added 2026-10-21 (review fold: A-M5 / B-M2 / A-B1): W-268's function shape and
the class shape of review A's B1, both pure Carbon, inserted before
`fail_var_uninit_tuple_on_instantiation.carbon`; neither has a diagnostic or a
dump, so F1 adds no CHECK line to the file.

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/check/testdata/generic/template/default_init.carbon
+++ b/toolchain/check/testdata/generic/template/default_init.carbon
@@ -41,6 +41,51 @@
   return s.Peek();
 }

+// --- var_uninit_associated_type.carbon
+library "[[@TEST_NAME]]";
+
+interface Container {
+  let Elem: type;
+  fn Get(self) -> Elem;
+}
+
+class Ints {
+  var n: i32;
+  impl as Container where .Elem = i32 {
+    fn Get(self) -> i32 { return self.n; }
+  }
+}
+
+fn F[template T: Container](x: T) -> i32 {
+  var e: T.Elem;
+  e = x.Get();
+  return e + 1;
+}
+
+fn Use(n: Ints) -> i32 {
+  return F(n);
+}
+
+// --- class_alias_var_uninit.carbon
+library "[[@TEST_NAME]]";
+
+class X {
+  alias Inner = i32;
+}
+
+class C(template T: type) {
+  alias B = T.Inner;
+  fn Make() -> i32 {
+    var b: B;
+    b = 5;
+    return b;
+  }
+}
+
+fn Use() -> i32 {
+  return C(X).Make();
+}
+
 // --- fail_var_uninit_tuple_on_instantiation.carbon
 library "[[@TEST_NAME]]";
```

<!-- google-doc-style-resume -->

### A.6 toolchain/check/testdata/generic/template/deduce_class_args.carbon (C1, a rename)

Added 2026-10-21 (review fold: A-B1): TP-1's W-273 split succeeds with D-CT-17
(§0.7), so its `fail_todo_` prefix goes; F1 then drops its seven STDERR lines.

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/check/testdata/generic/template/deduce_class_args.carbon
+++ b/toolchain/check/testdata/generic/template/deduce_class_args.carbon
@@ -432,7 +432,7 @@
   return Make(M, x);
 }

-// --- fail_todo_class_template_field_of_where_alias.carbon
+// --- class_template_field_of_where_alias.carbon
 library "[[@TEST_NAME]]";

 interface HasItem {
```

<!-- google-doc-style-resume -->

## Appendix B: conformance programs

The nine programs and the oracle of commit P, as measured on v11 and on v12
(each prints its EXPECT lines; the oracle prints `60000`, `-5536`, `3`, where
rev 1's values printed `6`, `60`, `3` under `Acc<int>` and `Acc<short>`
alike; amended 2026-10-21, review fold: B-m7). The two un-SKIPped
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
// function templates of the same shape (no EXPECT-STDOUT). SumThree of three
// 20000s accumulates 60000 in an Acc<int>; on i16 the same sum wraps in an
// Acc<short>'s `short` total (C++'s conversion, -5536 with Clang), so the two
// specializations differ; CountThree, with a template binding, reads the
// accumulator's member n, 3.

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
  Core.Print(SumThree(20000 as i32, 20000 as i32, 20000 as i32));
  Core.Print(SumThree(20000 as i16, 20000 as i16, 20000 as i16));
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
  std::printf("%d\n", SumThree<int>(20000, 20000, 20000));
  std::printf("%d\n", SumThree<short>(20000, 20000, 20000));
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

Rewritten 2026-10-21 (review fold: B-M4 / B-M5 / B-M6 / A-M1). In
docs/design/interoperability/README.md, "Using C++ templates", the sentence
from "One limit in 0.1:" to "(fork work item W-043, and W-127 on held PR 51)."
is replaced by:

<!-- google-doc-style-ignore -->

```markdown
A `var` of such a specialization can be declared without an initializer,
`var b: Cpp.Box(T);`, and a C++ function template can be called with an
argument of type `T`, as `Cpp.Twice(x)`. Each is checked when the generic is
instantiated for a specific, as a template's body is, and so is an operation
on what such a call returns; an error in one, such as a member that `Box<T>`
does not have, is reported where the specific is named (updated <YYYY-MM-DD>,
fork work item W-043). This holds within one library: a generic whose body
uses a C++ template this way cannot yet be used from another library (W-250).
A Carbon struct or tuple type cannot yet be a template argument (W-300), nor a
Carbon generic class a template template argument (W-301), and a member found
only through `T`'s constraint, as `b.value.Get()` for `T: Show`, is not found
on instantiation (W-305).
```

<!-- google-doc-style-resume -->

R27: `var b: Cpp.Box(T);` is the programs' spelling (in
interop/cpp_template_symbolic_arg.carbon and
cpp_template_on_carbon_generic.carbon) and the fixture's; `Cpp.Twice(x)` is the
fixture's. The fixture is
fork/designdocs/samples/X37_cpp_template_symbolic_uninit.carbon: TP-1's plan
names X34 to X36 for its own land-time fixtures (fork/templates/plan.md, its
land-time L), so rev 1's X34 was taken, and X37 is free in every tree measured
(PR 58's samples end at X33). Its QUOTE is the paragraph's first sentence
verbatim, capital A included, because check_samples.py matches a QUOTE
case-sensitively after collapsing whitespace (:743-750); its generic parameter
is `[T: type]`, as the programs' is (D-CT-13).
fork/designdocs/check_samples.py's `SAMPLES` gains, right after X09's entry:

<!-- google-doc-style-ignore -->

```python
    (
        INTEROP,
        "Using C++ templates",
        QUOTE,
        "X37_cpp_template_symbolic_uninit.carbon",
    ),
```

<!-- google-doc-style-resume -->

and in X09_cpp_template_symbolic_arg.carbon the comment's last sentence, "The
form the page states as the limit, `var b: Cpp.Box(T);` with no initializer,
is the plan's probe PR-T (section 4.3; fork work item W-043).", becomes "The
uninitialized form, `var b: Cpp.Box(T);`, is fixture X37's (fork work item
W-043)."
Measured on a PR 58 mirror (`$X/m/dd`, PR 58's page, checker and samples with
this paragraph, the entry and the fixture; 2026-10-21, EXPECTED, not of
record): `python3 fork/designdocs/check_samples.py --toolchain <v12's busybox>`
reports no error for X37 (it prints `42` and `10`) and its QUOTE matches; with
TP-1's toolchain X37 fails with E-DU, and the checker's other 19 errors are the
same on both toolchains (PR 58's fixtures that TP-1's toolchain now compiles,
which TP-1's own land-time L updates). The fixture:

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/interoperability/README.md, "Using C++ templates", quote
// EXPECT-STDOUT:
//   42
//   10
// QUOTE: A `var` of such a specialization can be declared without an initializer, `var b: Cpp.Box(T);`
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

fn G[T: type](x: T) -> T {
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

### C.2 W-043's discharge (commit D; reapplied over DD-1's entry at land time)

Rewritten 2026-10-21 (review fold: B-M1 / B-M5 / B-m4 / B-m5). At the land-time
records commit, the entry M took from DD-1 (PR 58's notes and evidence) is the
base: DD-1's evidence entries are kept after the original seven, DD-1's notes
after the original notes, and this text's additions follow them.

<!-- google-doc-style-ignore -->

```json
{
 "id": "W-043",
 "title": "C++ templates instantiated on Carbon types / symbolic Carbon generic parameters as C++ template arguments (DISCHARGED at CT-1, <YYYY-MM-DD>)",
 "evidence": [
  "<the original seven entries, kept, then DD-1's at land time>",
  "toolchain/check/impl_lookup.cpp `NamesTemplateBinding` (D-CT-5: a `TemplateInst` names a template binding; `MetaInstId`/`MetaInstBlockId` operands and symbolic operands' constant values are followed)",
  "toolchain/check/action.cpp `ActionIsPerformable` (D-CT-6), toolchain/check/subst.cpp `PushOperand`/`PopOperand` and `IsSubstitutedActionOperand` (D-CT-7), toolchain/check/convert.cpp `PerformAction(InitializeAction)` (D-CT-8), toolchain/check/cpp/call.cpp `BuildTemplateId` (D-CT-9), toolchain/check/cpp/overload_resolution.cpp `IsMoveEquivalentToCopy` (D-CT-10), toolchain/check/generic.cpp `DiscardGenericDeclIntoEnclosingGeneric` and toolchain/check/handle_alias.cpp (D-CT-17), toolchain/check/call.cpp `DeferCppCallOnSymbolicArgs` (D-CT-3)",
  "toolchain/check/testdata/interop/cpp/template/symbolic_arg.carbon, toolchain/lower/testdata/interop/cpp/template_symbolic_arg.carbon and toolchain/check/testdata/generic/template/default_init.carbon (`var_uninit_associated_type`, `class_alias_var_uninit`)",
  "fork/conformance/programs/interop/cpp_template_symbolic_arg.carbon and cpp_template_on_carbon_generic.carbon (un-SKIPped, PASS), cpp_template_fn_symbolic, cpp_template_spec_roundtrip, cpp_template_nested_symbolic, cpp_template_carbon_generic_spec, cpp_template_two_specifics, cpp_template_symbolic_diff (differential), cpp_var_template_runtime",
  "fork/designdocs/samples/X37_cpp_template_symbolic_uninit.carbon (at land time)",
  "fork/cpp-templates/plan.md; fork/decision-log.md \"CT-1\" (F-021)"
 ],
 "notes": "<the original notes, kept, then DD-1's at land time>. DISCHARGED at CT-1 (<YYYY-MM-DD>, fork/cpp-templates/plan.md): the blocker the item names, a symbolic Carbon type as a C++ template argument, had been lifted upstream (PRs 7673, 7689 and 7700: a deferred `CallAction` over `TemplateInst`-wrapped arguments); nine defects in and around that path kept it from working (impl lookup on the specialization resolved where the generic is defined, so an uninitialized `var` of it was rejected; C++ actions performed for a symbolic specific; action operands not substituted; a narrow scalar `return` given a return slot; variable template specializations never instantiated; an exported Carbon class queried before it was complete; an alias's value detached from its enclosing generic; an enclosing generic's operand kept in a member's action; an alias's name reference not followed to its value), each fixed at its root, and a C++ call with a checked generic's symbolic argument is deferred to each specific, a fork rule (F-021). The two SKIP programs run without their SKIP lines and with the `Core.Copy` impl each needs, keeping the uninitialized `var b: Cpp.Box(T);`. Measured in the container (EXPECTED, not of record, R9): <gate N of N>, conformance <P / F / S over N>. The evidence's type_mapping.cpp TODO (:560 when filed, :733-736 at CT-1) is live and filed as W-307, and call.cpp:252's non-type restriction as W-302. Residues: W-300 (struct, tuple and unexportable class types), W-301 (Carbon generics as template template arguments), W-302 (non-type argument kinds), W-303 (deduction through a C++ specialization, in a parameter's type or an impl's self), W-304 (a concrete C++ class `var` in a template's body stops lowering), W-305 (interface member access through a constraint on a specialization's member), W-306 (instantiation notes without a line, repeated E-MONO), W-307 (form-dependent arguments to C++ functions), W-308 (C++ classes as choice payloads), W-309 (a deferred call's C++ temporary not destroyed); CT-1's forms work within one library, and a use from another library stays W-250's."
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
   "toolchain/check/testdata/interop/cpp/template/symbolic_arg.carbon `fail_todo_template_template_carbon_generic` (``template argument for template template parameter must be a class template or type alias template``)"
  ],
  "blocked_by": [],
  "notes": "Filed at CT-1's discharge (<YYYY-MM-DD>). A C++ class template as the argument works (`Cpp.Apply(Cpp.Box, T)`, nested_and_generic_class_args). Removal: export a Carbon generic class as a C++ class template; the split `fail_todo_template_template_carbon_generic` (renamed from rev 1's `fail_template_template_carbon_generic`, review fold: B-m7) loses its `fail_todo_` prefix."
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
  "title": "CT-1 residue: a Carbon generic parameter cannot be deduced through a C++ class template specialization, in a parameter's type or in an impl's self type",
  "subsystem": "toolchain/check (deduce.cpp, impl.cpp)",
  "size": "M",
  "bullet": "Generics: C++ interop \u2014 importing C++ templates, instantiating on Carbon types",
  "evidence": [
   "toolchain/check/deduce.cpp:513 (``cannot deduce value for generic parameter `T` ``)",
   "toolchain/check/testdata/interop/cpp/template/symbolic_arg.carbon `fail_todo_deduce_through_specialization`",
   "toolchain/check/impl.cpp:238-246 (`ImplUnusedBinding`) and toolchain/check/testdata/interop/cpp/template/symbolic_arg.carbon `fail_todo_impl_forall_specialization` (`impl forall [T: type] Cpp.Box(T) as Size`: `` `impl` with unused generic binding `` at `T`; TP-1, trunk and the nightly stop at sem_ir/generic.cpp:84 on it, probe ra/c09)"
  ],
  "blocked_by": [],
  "notes": "Filed at CT-1's discharge (<YYYY-MM-DD>). `fn Get[T: type](b: Cpp.Box(T))` called with a `Box<int>`; the programs pass `T` through another parameter. The impl shape was added by the plan review fold (2026-10-21, review A's M4). Removal: deduce `T` from the C++ specialization's template arguments; both splits lose their `fail_todo_` prefix."
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
 },
 {
  "id": "W-307",
  "kind": "missing-feature",
  "title": "CT-1 residue: a form-dependent argument to a C++ function (a reference to `x:? Fm`) is a `semantics TODO` where the call is written",
  "subsystem": "toolchain/check/cpp (type_mapping.cpp)",
  "size": "M",
  "bullet": "Generics: C++ interop \u2014 importing C++ templates, instantiating on Carbon types",
  "evidence": [
   "toolchain/check/cpp/type_mapping.cpp:733-736 (``semantics TODO: `Support passing form-dependent args to C++ functions.` ``; W-043's type_mapping.cpp:560 evidence when W-043 was filed)",
   "toolchain/sem_ir/expr_info.cpp:406-417 (a form-dependent reference's category is `Dependent`)",
   "toolchain/check/testdata/interop/cpp/template/symbolic_arg.carbon `fail_todo_form_dependent_arg`",
   "fork/cpp-templates/plan.md \u00a70.12 (probes new/n01 to n03)"
  ],
  "blocked_by": [],
  "notes": "Filed at CT-1's discharge (<YYYY-MM-DD>); the live half of W-043's evidence (plan review fold, review B's M1). `fn F(generic Fm: Core.Form, x:? Fm) -> i32 { return Cpp.TakeInt(x); }` reports the TODO where `F` is defined, as on TP-1, trunk and the nightly; D-CT-3 does not defer the call, because the deferred action's operand keeps the `Dependent` category in every specific, so rev 1's deferral only moved the TODO into an instantiation note. Removal: pass a form-dependent argument to a C++ parameter by its form in each specific; the split loses its `fail_todo_` prefix."
 },
 {
  "id": "W-308",
  "kind": "missing-feature",
  "title": "CT-1 residue: a C++ class type as a choice alternative's payload is a `semantics TODO` when concrete, and a specialization of a symbolic argument as the payload is rejected in each specific as not trivially copyable and destructible",
  "subsystem": "toolchain/check (handle_choice.cpp, eval_inst.cpp)",
  "size": "M",
  "bullet": "Generics: C++ interop \u2014 importing C++ templates, instantiating on Carbon types",
  "evidence": [
   "toolchain/check/handle_choice.cpp:762 (``semantics TODO: `choice alternative payload that is not trivially copyable and destructible` ``)",
   "toolchain/check/eval_inst.cpp:263-265 (``choice alternative payload type `Cpp.Box` is not trivially copyable and destructible in this specific``)",
   "toolchain/check/testdata/interop/cpp/template/symbolic_arg.carbon `fail_todo_choice_payload_specialization`",
   "fork/cpp-templates/plan.md \u00a70.12 (probes ra/e02, e02b, e02e, e02f)"
  ],
  "blocked_by": [],
  "notes": "Filed at CT-1's discharge (<YYYY-MM-DD>; plan review fold, review A's M4). `choice Holder(T: type) { Full(b: Cpp.Box(T)), Empty }` compiles with CT-1 (TP-1, trunk and v11 stopped at sem_ir/generic.cpp:84 on the declaration; the nightly reports a choice TODO), and a use in `F(i32)` is two E-MONO with that note. Removal: decide a C++ class payload's triviality from Clang's, or admit non-trivial payloads; the split loses its `fail_todo_` prefix."
 },
 {
  "id": "W-309",
  "kind": "toolchain-defect",
  "title": "Found by CT-1's plan review fold: a temporary of a C++ class with a non-trivial destructor that a deferred C++ call returns is not destroyed when it is discarded or `let`-bound, in a template and in a checked generic",
  "subsystem": "toolchain/check (the destroy of a template action's result temporary)",
  "size": "M",
  "bullet": "Generics: C++ interop \u2014 importing C++ templates, instantiating on Carbon types",
  "evidence": [
   "fork/cpp-templates/plan.md \u00a70.12 (probes w/w6 and w/w9 in a template print 0 and `3 0` on TP-1 and the nightly, w/w7 in a checked generic prints 0 with CT-1; their concrete twins w/w5 and w/w8 print 1 and `3 1`; a `var` of it, w/w10, prints `3 1`)"
  ],
  "blocked_by": [],
  "notes": "Filed at CT-1's discharge (<YYYY-MM-DD>). `Cpp.MakeLoud(v);` for `template<typename T> Loud<T> MakeLoud(T)` whose destructor counts: the counter stays 0. Not caused by CT-1: TP-1 and the nightly behave the same in a template. Removal: destroy a deferred call's result temporary in the specific, as a concrete call's is. Break condition: w6 and w7 print 1."
 }
]
```

<!-- google-doc-style-resume -->

In the JSON, `\u2014` stands for the em dash of the bullet's name; the
writer keeps the ledger's own escaping (the file is written by `json.dump`, as
TP-1's D commit did).

### C.4 Gap rows (commit R here; at land time found by bullet text after M)

Rewritten 2026-10-21 (review fold: B-M5 / B-m4). Commit R replaces the two rows
at their line numbers on this branch; the land-time records commit replaces
them again on the merged trunk, finding each by its bullet text (the first
cell), because the held PRs between move them.

<!-- google-doc-style-ignore -->

```markdown
| Generics: C++ interop — importing C++ templates, instantiating on Carbon types | PARTIAL | Class/function/alias/variable templates import and instantiate on C++ types, Carbon builtins and Carbon classes, concrete or a checked generic's or a template's symbolic arguments, each specialization and C++ call formed for each specific, within one library (CT-1, <YYYY-MM-DD>; a use from another library is W-250); struct and tuple types as arguments (W-300), Carbon generics as template template arguments (W-301), some non-type argument kinds (W-302), deduction through a specialization (W-303), member access through a constraint on a specialization's member (W-305), form-dependent arguments to C++ functions (W-307) and C++ classes as choice payloads (W-308) are missing, and a deferred call's C++ temporary is not destroyed (W-309). |
| Type system: C++ interop — importing C++ types / exporting Carbon types | PARTIAL | Classes/enums/unions/templates import and Carbon classes export (125 check + 38 lower interop tests), C++ templates instantiate on Carbon class types, symbolic ones included (struct and tuple types not yet, W-300; CT-1, <YYYY-MM-DD>), but several export cases are fail_todo. |
```

<!-- google-doc-style-resume -->

### C.5 W-268 narrowed (commit D)

Rewritten 2026-10-21 (review fold: A-M5 / B-M2): W-268 is narrowed to its third
evidence shape and stays open; rev 1's "discharged" claimed a removal that
index.carbon's split does not show.

<!-- google-doc-style-ignore -->

```text
title: TP-1 residue: `var a: x.0;` for a runtime `x` of a template type is rejected where the function is defined, because the deferral of impl lookup follows only symbolic operands (narrowed at CT-1, <YYYY-MM-DD>)
evidence, replacing the first two entries and keeping the third:
  toolchain/check/impl_lookup.cpp `NamesTemplateBinding` (its `push` follows symbolic constants; `x` is a runtime parameter, so `x.0` reaches no template binding)
  toolchain/check/testdata/generic/template/index.carbon `fail_tuple_index_as_var_type_on_instantiation` (the definition-time lookup for `var a: x.0;`)
  fork/cpp-templates/plan.md D-CT-5 (the splice shapes, which run since CT-1)
notes, appended: Narrowed at CT-1 (<YYYY-MM-DD>, fork/cpp-templates/plan.md D-CT-5): `NamesTemplateBinding` follows `MetaInstId` and `MetaInstBlockId` operands and symbolic operands' constant values, so the function shape `var e: T.Elem;` (d03 and w268_d03_var_elem print 6 and 4, g_w268 prints 52) and the class shape `var b: B;` for `alias B = T.Inner;` in a class template run, pinned by default_init.carbon's `var_uninit_associated_type` and `class_alias_var_uninit`. The runtime-operand shape stays. Removal: defer the lookup when a runtime operand's type names a template binding, so index.carbon's split reports only its instantiation error. Break condition: that split's definition-time error disappears.
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

Rewritten 2026-10-21 (review fold: A-M1 / A-M2 / B-m2).

<!-- google-doc-style-ignore -->

```markdown
### CT-1: C++ templates on symbolic Carbon type arguments (<YYYY-MM-DD>)

Context: W-043 (gap row 56, "Generics: C++ interop — importing C++ templates,
instantiating on Carbon types", PARTIAL, with its second program under row 42),
fork/cpp-templates/plan.md, rev <N> after <the plan reviews>, implemented and
folded with two implementation reviews and <the re-review rounds> (<their
verdicts and finding counts>). Every decision auto-adopted under V-2/V-3
(R29(a)) and open to veto. Options considered (plan §7.2): instantiating
eagerly on every possible argument, treating C++ templates as Carbon templates
only, requiring `template T` for all uses, diagnosing member access where a
checked generic is defined, a new instruction kind, wrapping every value
argument, substituting into every action operand, instantiating a variable
template from the import, completing every exported class when mapped,
keeping PR 51's constructor-initialized programs, a definition-time TODO for
the OUT kinds, not deferring a lookup whose splice belongs to an enclosing
generic, deferring on an argument's own dependence, keeping definition checks
on a deferred call's result, deferring form-dependent arguments,
`Sema::isCompleteType`, extending the lookup walk to runtime operands, and
attaching every discarded generic region. Decisions: D-CT-1, upstream's
deferred `CallAction` over `TemplateInst`, performed per specific, no new
SemIR; D-CT-2 and D-CT-3, F-021 (below); D-CT-4, the template lane rides TP-1,
TR-22 stays OUT for Carbon forms while its C++ forms run; D-CT-5, impl lookup
on a C++ specialization is deferred, the walk following action operands and
constant values (D-TP-12 amended, W-268 narrowed); D-CT-6, a C++ callee's
action waits for concrete arguments; D-CT-7, constant action operands and
another generic's operands are substituted; D-CT-8, a deferred `return` uses
the return slot only in place; D-CT-9, variable template specializations are
implicitly instantiated; D-CT-10, an exported class is completed before
overload resolution reads it, and checked complete; D-CT-11, the admitted
kinds and the OUT table; D-CT-12, goldens; D-CT-13, nine programs; D-CT-14,
docs at land time with fixture X37, records and TP-1's dated lines; D-CT-15,
stacked on PR 61, merged after PR 62, with S-VA after M; D-CT-16, F-021
minted; D-CT-17, an alias's dependent instructions belong to the enclosing
generic (TP-1's W-273 discharged).

**F-021 (the checked-generic C++ rule).** In a checked generic, a C++
template's specialization of a symbolic argument, a call to a C++ function
with an argument of a checked-symbolic type (or that is such a type), and
every operation on their values, Carbon operations on a deferred call's
result included, are checked for each specific when the generic is
instantiated, and an error in one is reported where the specific is named;
every other expression of the generic is checked where it is defined. A call
whose arguments' C++ types are known (a symbolic value of a concrete type), a
form-dependent argument and a pack expansion argument are not deferred.
Upstream states the `TemplateInst` deferral of a C++ template name and delays
impl lookup until template arguments are known (proposal 2200); it leaves a
checked generic's use of a template to future work (p002200:1089-1096, leads
issue 2153), so the rule is the fork's. Break condition: upstream lands a rule
for a checked generic's C++ calls that differs, re-decided at that upstream
merge.

Consequences: rows 56 and 42 stay PARTIAL with corrected text; W-043
discharged, W-268 narrowed, TP-1's W-273 discharged; W-300 to W-309 filed (CT-1
reserved W-300..W-319; W-310 to W-319 unused); F-021 minted; the TP-1 records
CT-1 edits are W-268, W-273 and one dated line each on D-TP-12, TR-22 and
W-274.

_V-3a divergence-risk register entries (reviewed at each upstream merge):_ the
eight of plan §0.10, with their merge rules. Veto-able.
```

<!-- google-doc-style-resume -->

### C.8 fork/ORCHESTRATION.md (commit D; the held-state stamp on trunk is the orchestrator's)

<!-- google-doc-style-ignore -->

```markdown
| `claude/carbon-fork-0-1-ct` | <state, e.g. HELD OPEN as PR NN> -- CT-1 C++ templates on symbolic Carbon type arguments at <head>, stacked on PR 61 (W-043 and TP-1's W-273 discharged, W-268 narrowed; W-300..W-309 filed, W-310..W-319 unused; F-021 minted; expected <gate> and <P / F / S over N>, not of record; rows 56 and 42 PARTIAL); merges after PR 62 through its land-time items M, S-VA, L-F, L and the land-time records commit. |
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

### C.11 TP-1's record lines (commit D) and S-VA (land time)

Added 2026-10-21 (review fold: B-m2 / B-M3 / A-B1 / A-M1). These, with W-268
(C.5), are the only TP-1 records CT-1 edits. In fork/templates/plan.md, one
dated line is appended to each of two paragraphs:

<!-- google-doc-style-ignore -->

```text
after D-TP-12's paragraph (§1.7, "**D-TP-12 (rewritten 2026-10-14).**"):
  Amended <YYYY-MM-DD> by CT-1 (fork/cpp-templates/plan.md D-CT-5): a checked generic's query that reaches a `TemplateInst`, or a template binding through an action's `MetaInstId` operands or a symbolic operand's constant value, is deferred too, so generic_call.carbon's `require_specific_def` moves to the specific; facet/period_self.carbon is unchanged.
after TR-22's item (§1.1, "TR-22. Passing a symbolic constant"):
  Amended <YYYY-MM-DD> by CT-1 (fork/cpp-templates/plan.md D-CT-4, D-CT-6, F-021): TR-22 stays OUT for its Carbon forms; a template's C++ specialization or C++ call performed for a checked generic's symbolic argument now runs in the specific that names a concrete argument.
```

<!-- google-doc-style-resume -->

In fork/inventory/work-items.json, W-273 and W-274:

<!-- google-doc-style-ignore -->

```text
W-273 title: <the title> (DISCHARGED at CT-1, <YYYY-MM-DD>)
W-273 notes, appended: DISCHARGED at CT-1 (<YYYY-MM-DD>, fork/cpp-templates/plan.md D-CT-17): the class-scope alias's dependent instructions are attached to `D`, so `D(Holder)`'s field type is concrete and the literal converts; k14 (CT-1's n13) prints 3, and deduce_class_args.carbon's split is renamed `class_template_field_of_where_alias`.
W-274 notes, appended: <YYYY-MM-DD>, CT-1 (fork/cpp-templates/plan.md D-CT-6): unchanged on CT-1's toolchain (n01i stops at sem_ir/generic.cpp:96 and x04 is E-MONO, as on TP-1); CT-1 runs TR-22's C++ forms, not this Carbon form.
```

<!-- google-doc-style-resume -->

**S-VA** (land-time code commit after M; §2.11, D-CT-3). The hunk, measured on
mva (PR 61's head merged with PR 59, plus v12; line numbers are that tree's):

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/check/call.cpp
+++ b/toolchain/check/call.cpp
@@ -1120,10 +1120,13 @@
   }
   // A form-dependent argument, such as a reference to `x:? Fm`, has no form
   // that the call could take in a specific either, so the call is left to
-  // `PerformCallHelper`, which reports that where the call is written.
+  // `PerformCallHelper`, which reports that where the call is written. So is
+  // a pack expansion argument, which a C++ function has no pack expansion
+  // parameter to match (D-VA-5).
   if (llvm::any_of(arg_ids, [&](SemIR::InstId arg_id) {
         return SemIR::GetExprCategory(context.sem_ir(), arg_id) ==
-               SemIR::ExprCategory::Dependent;
+                   SemIR::ExprCategory::Dependent ||
+               IsPackExpansionArg(context, arg_id);
       })) {
     return SemIR::InstId::None;
   }
```

<!-- google-doc-style-resume -->

Its split, appended to A.1's file on the merged tree, with box.h's `TakeInt`;
predicted fill, from va2 on mva after the hunk: ``pack expansion argument is
not matched by a pack expansion parameter [PackExpansionArgWithoutPackParam]``
at `... each x`, where `F` is defined (without the hunk, an uncalled `F`
compiles, M18):

<!-- google-doc-style-ignore -->

```carbon
// --- fail_pack_expansion_cpp_call_in_definition.carbon

library "[[@TEST_NAME]]";

import Cpp library "box.h";

// A C++ function has no pack expansion parameter, so the call is diagnosed
// where the generic is defined, as for a non-generic callee (VA-1's D-VA-5).
fn F(... each x: i32) -> i32 {
  return Cpp.TakeInt(... each x);
}
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

### D.7 Rev 2's probes (the fold's own)

Added 2026-10-21 (review fold: all findings). The fold's probes, one block per
directory of `$X/probes` (the fixer's scratch), each file after a `// ===`
line with its name; review A's 72 sources are review A's (its scratch
`probes/`, copied to `$X/probes/ra`), and §0.12 names each by its id. A
probe's `Run` is the program's entry point, as in D.4.

`.`:

<!-- google-doc-style-ignore -->

```carbon
// === a11r.carbon
import Core library "io";
import Cpp inline '''
template<typename T> struct Box { T value; };
''';
//@dump-sem-ir-begin
class C(T: type) { alias B = Cpp.Box(T); fn Make(v: T) -> i32 { var b: B; b.value = v; return 1; } }
//@dump-sem-ir-end
fn Run() -> i32 { Core.Print(C(i32).Make(11)); return 0; }

// === cls_ref.carbon
//@dump-sem-ir-begin
class C(template T: type) {
  alias B = T;
  var x: T;
}
class D(U: type) {
  alias B = U;
  var x: U;
}
//@dump-sem-ir-end

// === f06b.carbon
class X { alias Inner = i32; }
class C(template T: type) {
  alias B = T.Inner;
  fn Make() -> i32 { var b: B; b = 5; return b; }
}
fn Run() -> i32 { return C(X).Make(); }

// === f06c.carbon
//@dump-sem-ir-begin
class X { alias Inner = i32; }
class C(template T: type) {
  alias B = T.Inner;
  fn Make() -> i32 { var b: B; b = 5; return b; }
}
fn Run() -> i32 { return C(X).Make(); }
//@dump-sem-ir-end

// === ret_alias.carbon
import Core library "io";
class X { alias Inner = i32; }
class C(template T: type) { alias B = T.Inner; fn Make() -> B { return 5; } }
fn Run() -> i32 { Core.Print(C(X).Make()); return 0; }

// === ret_alias_d.carbon
//@dump-sem-ir-begin
import Core library "io";
class X { alias Inner = i32; }
class C(template T: type) { alias B = T.Inner; fn Make() -> B { return 5; } }
fn Run() -> i32 { Core.Print(C(X).Make()); return 0; }
//@dump-sem-ir-end
```

<!-- google-doc-style-resume -->

`new`:

<!-- google-doc-style-ignore -->

```carbon
// === new/n01_form_val.carbon
import Core library "io";
import Core library "prelude/types/form";
import Cpp inline '''
inline int TakeInt(int x) { return x + 100; }
''';
fn F(generic Fm: Core.Form, x:? Fm) -> i32 { return Cpp.TakeInt(x); }
fn Run() -> i32 { let v: i32 = 5; Core.Print(F(form(val i32), v)); return 0; }

// === new/n02_form_var.carbon
import Core library "io";
import Core library "prelude/types/form";
import Cpp inline '''
inline int TakeInt(int x) { return x + 100; }
''';
fn F(generic Fm: Core.Form, x:? Fm) -> i32 { return Cpp.TakeInt(x); }
fn Run() -> i32 { var v: i32 = 6; Core.Print(F(form(var i32), v)); return 0; }

// === new/n03_form_uncalled.carbon
import Core library "io";
import Core library "prelude/types/form";
import Cpp inline '''
inline int TakeInt(int x) { return x + 100; }
''';
fn F(generic Fm: Core.Form, x:? Fm) -> i32 { return Cpp.TakeInt(x); }
fn Run() -> i32 { Core.Print(7); return 0; }

// === new/n04_copy_into_spec_called.carbon
import Core library "io";
import Cpp inline '''
template<typename T> struct Box { T value; };
''';
class NoCopy { var x: i32; }
fn F[T: type](v: T) -> Cpp.Box(T) { var b: Cpp.Box(T); b.value = v; return b; }
fn Run() -> i32 { Core.Print(F({.x = 8} as NoCopy).value.x); return 0; }

// === new/n05_copy_into_spec_uncalled.carbon
import Core library "io";
import Cpp inline '''
template<typename T> struct Box { T value; };
''';
fn F[T: type](v: T) -> Cpp.Box(T) { var b: Cpp.Box(T); b.value = v; return b; }
fn Run() -> i32 { Core.Print(9); return 0; }

// === new/n06_copy_into_spec_constrained.carbon
import Core library "io";
import Cpp inline '''
template<typename T> struct Box { T value; };
''';
class P { var x: i32; impl as Core.Copy { fn Op(self) -> Self { return {.x = self.x}; } } }
fn F[T: Core.Copy](v: T) -> Cpp.Box(T) { var b: Cpp.Box(T); b.value = v; return b; }
fn Run() -> i32 { Core.Print(F({.x = 10} as P).value.x); return 0; }

// === new/n07_nttp_fn_symbolic.carbon
import Core library "io";
import Cpp inline '''
template<int N> int GetN() { return N; }
''';
fn F(generic N: i32) -> i32 { return Cpp.GetN(N); }
fn Run() -> i32 { Core.Print(F(11)); return 0; }

// === new/n08_nttp_fn_concrete.carbon
import Core library "io";
import Cpp inline '''
template<int N> int GetN() { return N; }
''';
fn Run() -> i32 { Core.Print(Cpp.GetN(12)); return 0; }

// === new/n09_symval_called_ok.carbon
import Core library "io";
import Cpp inline '''
inline int TakeInt(int x) { return x + 100; }
''';
fn F(generic N: i32) -> i32 { return Cpp.TakeInt(N); }
fn Run() -> i32 { Core.Print(F(13)); return 0; }

// === new/n10_contagion_uncalled.carbon
import Core library "io";
import Cpp inline '''
template<typename T> T Twice(T x) { return x + x; }
inline int TakeInt(int x) { return x + 100; }
''';
fn G(n: i32) -> i32 { return n; }
fn F[T: type](x: T) -> i32 {
  let b: bool = G(Cpp.TakeInt(Cpp.Twice(x)));
  return if b then 1 else 0;
}
fn Run() -> i32 { Core.Print(14); return 0; }

// === new/n11_contagion_called.carbon
import Core library "io";
import Cpp inline '''
template<typename T> T Twice(T x) { return x + x; }
inline int TakeInt(int x) { return x + 100; }
''';
fn G(n: i32) -> i32 { return n; }
fn F[T: type](x: T) -> i32 {
  let b: bool = G(Cpp.TakeInt(Cpp.Twice(x)));
  return if b then 1 else 0;
}
fn Run() -> i32 { Core.Print(F(1 as i32)); return 0; }

// === new/n12_contagion_concrete_twin.carbon
import Core library "io";
import Cpp inline '''
template<typename T> T Twice(T x) { return x + x; }
inline int TakeInt(int x) { return x + 100; }
''';
fn G(n: i32) -> i32 { return n; }
fn F(x: i32) -> i32 {
  let b: bool = G(Cpp.TakeInt(Cpp.Twice(x)));
  return if b then 1 else 0;
}
fn Run() -> i32 { Core.Print(15); return 0; }

// === new/n13_where_alias_k14.carbon
import Core library "io";
interface HasItem { let Item: type; }
class Holder { impl as HasItem where .Item = i32 {} }
class Tag(U: type) { var x: i32; }
class D(template T: HasItem) {
  alias FT = HasItem where .Item = T.Item;
  var c: Tag({.a: FT});
  var k: i32;
}
fn G() -> i32 { var d: D(Holder) = {.c = {.x = 1}, .k = 2}; return d.c.x + d.k; }
fn Run() -> i32 { Core.Print(G()); return 0; }

// === new/n14_alias_tp_member_uninit.carbon
import Core library "io";
interface Container { let Elem: type; }
class V { var n: i32; }
impl V as Container where .Elem = i32 {}
class C(template T: Container) {
  alias E = T.Elem;
  fn Make() -> i32 { var e: E; e = 16; return e; }
}
fn Run() -> i32 { Core.Print(C(V).Make()); return 0; }

// === new/n15_alias_tp_member_ret.carbon
import Core library "io";
interface Container { let Elem: type; }
class V { var n: i32; }
impl V as Container where .Elem = i32 {}
class C(template T: Container) {
  alias E = T.Elem;
  fn Make(v: E) -> E { return v; }
}
fn Run() -> i32 { Core.Print(C(V).Make(17)); return 0; }

// === new/n16_alias_checked_fn_body.carbon
import Core library "io";
import Cpp inline '''
template<typename T> struct Box { T value; };
''';
fn F[T: type](v: T) -> T { alias B = Cpp.Box(T); var b: B; b.value = v; return b.value; }
fn Run() -> i32 { Core.Print(F(18 as i32)); return 0; }

// === new/n17_alias_interface_member.carbon
import Core library "io";
interface I { let X: type; fn Get[self: Self]() -> X; }
class W { var v: i32; impl as I where .X = i32 { fn Get[self: Self]() -> i32 { return self.v; } } }
fn H[T: I](t: T) -> T.X { alias Y = T.X; let y: Y = t.Get(); return y; }
fn Run() -> i32 { Core.Print(H({.v = 19} as W)); return 0; }
```

<!-- google-doc-style-resume -->

`al`:

<!-- google-doc-style-ignore -->

```carbon
// === al/cls_alias_field_generic_use.carbon
import Core library "io";
import Cpp inline '''
template<typename T> struct Box { T value; };
''';
class C(T: type) { alias B = Cpp.Box(T); var b: B; }
fn G[T: type](c: C(T)) -> T { return c.b.value; }
fn Run() -> i32 { var c: C(i32) = {.b = Cpp.Box(i32).Box()}; c.b.value = 5; Core.Print(G(c)); return 0; }

// === al/cls_alias_init.carbon
import Core library "io";
import Cpp inline '''
template<typename T> struct Box { T value; };
''';
class C(T: type) { alias B = Cpp.Box(T); fn Make() -> i32 { var unused b: B = Cpp.Box(T).Box(); return 3; } }
fn Run() -> i32 { Core.Print(C(i32).Make()); return 0; }

// === al/cls_alias_var.carbon
import Core library "io";
import Cpp inline '''
template<typename T> struct Box { T value; };
''';
class C(T: type) { alias B = Cpp.Box(T); fn Make() -> i32 { var unused b: B; return 2; } }
fn Run() -> i32 { Core.Print(C(i32).Make()); return 0; }

// === al/cls_noalias_var.carbon
import Core library "io";
import Cpp inline '''
template<typename T> struct Box { T value; };
''';
class C(T: type) { alias B = Cpp.Box(T); fn Make[self: Self]() -> i32 { var unused b: Cpp.Box(T); return 4; } }
fn Run() -> i32 { Core.Print(C(i32).Make()); return 0; }

// === al/fn_alias.carbon
import Core library "io";
import Cpp inline '''
template<typename T> struct Box { T value; };
''';
fn F[T: type](unused v: T) -> i32 { alias B = Cpp.Box(T); var unused b: B; return 1; }
fn Run() -> i32 { Core.Print(F(1 as i32)); return 0; }
```

<!-- google-doc-style-resume -->

`w`:

<!-- google-doc-style-ignore -->

```carbon
// === w/w10_var_loud_checked.carbon
import Core library "io";
import Cpp inline '''
inline int destroyed = 0;
template<typename T> struct Loud { T v; ~Loud() { ++destroyed; } };
template<typename T> Loud<T> MakeLoud(T v) { Loud<T> l; l.v = v; return l; }
inline int Destroyed() { return destroyed; }
''';
fn F[T: type](v: T) -> i32 { var unused l: Cpp.Loud(T) = Cpp.MakeLoud(v); return 3; }
fn Run() -> i32 { Core.Print(F(1 as i32)); Core.Print(Cpp.Destroyed()); return 0; }

// === w/w1_discard_explicit.carbon
import Core library "io";
import Cpp inline '''
template<typename T> struct Box { T value; };
template<typename T> Box<T> MakeBox(T v) { Box<T> b; b.value = v; return b; }
inline int destroyed = 0;
template<typename T> struct Loud { T v; ~Loud() { ++destroyed; } };
template<typename T> Loud<T> MakeLoud(T v) { Loud<T> l; l.v = v; return l; }
inline int Destroyed() { return destroyed; }
''';
fn F[T: type](v: T) -> i32 { Cpp.MakeBox(T, v); return 1; }
fn Run() -> i32 { Core.Print(F(1 as i32)); return 0; }

// === w/w274_n01i.carbon
import Core library "io";
class D(template T: type) { var a: i32; var k: T = 7; }
fn Make(template T: type) -> i32 { var d: D(T) = {.a = 4}; return d.a; }
fn H(generic U: type) -> i32 { return Make(U); }
fn Run() -> i32 { Core.Print(H(i32)); return 0; }

// === w/w274_x04.carbon
import Core library "io";
class D(template N: i32) { var a: i32; var k: i32 = 5; }
fn Make(template N: i32) -> i32 { let d: D(N) = {.a = 4}; return d.a + d.k; }
fn H(generic M: i32) -> i32 { return Make(M); }
fn Run() -> i32 { Core.Print(H(3)); return 0; }

// === w/w2_discard_loud_explicit.carbon
import Core library "io";
import Cpp inline '''
template<typename T> struct Box { T value; };
template<typename T> Box<T> MakeBox(T v) { Box<T> b; b.value = v; return b; }
inline int destroyed = 0;
template<typename T> struct Loud { T v; ~Loud() { ++destroyed; } };
template<typename T> Loud<T> MakeLoud(T v) { Loud<T> l; l.v = v; return l; }
inline int Destroyed() { return destroyed; }
''';
fn F[T: type](v: T) -> i32 { Cpp.MakeLoud(T, v); return Cpp.Destroyed(); }
fn Run() -> i32 { Core.Print(F(1 as i32)); return 0; }

// === w/w3_let_loud_explicit.carbon
import Core library "io";
import Cpp inline '''
template<typename T> struct Box { T value; };
template<typename T> Box<T> MakeBox(T v) { Box<T> b; b.value = v; return b; }
inline int destroyed = 0;
template<typename T> struct Loud { T v; ~Loud() { ++destroyed; } };
template<typename T> Loud<T> MakeLoud(T v) { Loud<T> l; l.v = v; return l; }
inline int Destroyed() { return destroyed; }
''';
fn F[T: type](v: T) -> i32 { let unused l: Cpp.Loud(T) = Cpp.MakeLoud(T, v); return 3; }
fn Run() -> i32 { Core.Print(F(1 as i32)); Core.Print(Cpp.Destroyed()); return 0; }

// === w/w4_member_of_explicit.carbon
import Core library "io";
import Cpp inline '''
template<typename T> struct Box { T value; };
template<typename T> Box<T> MakeBox(T v) { Box<T> b; b.value = v; return b; }
inline int destroyed = 0;
template<typename T> struct Loud { T v; ~Loud() { ++destroyed; } };
template<typename T> Loud<T> MakeLoud(T v) { Loud<T> l; l.v = v; return l; }
inline int Destroyed() { return destroyed; }
''';
fn F[T: type](v: T) -> T { return Cpp.MakeBox(T, v).value; }
fn Run() -> i32 { Core.Print(F(4 as i32)); return 0; }

// === w/w5_discard_loud_concrete.carbon
import Core library "io";
import Cpp inline '''
inline int destroyed = 0;
template<typename T> struct Loud { T v; ~Loud() { ++destroyed; } };
template<typename T> Loud<T> MakeLoud(T v) { Loud<T> l; l.v = v; return l; }
inline int Destroyed() { return destroyed; }
''';
fn F(v: i32) -> i32 { Cpp.MakeLoud(v); return Cpp.Destroyed(); }
fn Run() -> i32 { Core.Print(F(1 as i32)); return 0; }

// === w/w6_discard_loud_template.carbon
import Core library "io";
import Cpp inline '''
inline int destroyed = 0;
template<typename T> struct Loud { T v; ~Loud() { ++destroyed; } };
template<typename T> Loud<T> MakeLoud(T v) { Loud<T> l; l.v = v; return l; }
inline int Destroyed() { return destroyed; }
''';
fn F[template T: type](v: T) -> i32 { Cpp.MakeLoud(v); return Cpp.Destroyed(); }
fn Run() -> i32 { Core.Print(F(1 as i32)); return 0; }

// === w/w7_discard_loud_checked.carbon
import Core library "io";
import Cpp inline '''
inline int destroyed = 0;
template<typename T> struct Loud { T v; ~Loud() { ++destroyed; } };
template<typename T> Loud<T> MakeLoud(T v) { Loud<T> l; l.v = v; return l; }
inline int Destroyed() { return destroyed; }
''';
fn F[T: type](v: T) -> i32 { Cpp.MakeLoud(v); return Cpp.Destroyed(); }
fn Run() -> i32 { Core.Print(F(1 as i32)); return 0; }

// === w/w8_let_loud_concrete.carbon
import Core library "io";
import Cpp inline '''
inline int destroyed = 0;
template<typename T> struct Loud { T v; ~Loud() { ++destroyed; } };
template<typename T> Loud<T> MakeLoud(T v) { Loud<T> l; l.v = v; return l; }
inline int Destroyed() { return destroyed; }
''';
fn F(v: i32) -> i32 { let unused l: Cpp.Loud(i32) = Cpp.MakeLoud(v); return 3; }
fn Run() -> i32 { Core.Print(F(1 as i32)); Core.Print(Cpp.Destroyed()); return 0; }

// === w/w9_let_loud_template.carbon
import Core library "io";
import Cpp inline '''
inline int destroyed = 0;
template<typename T> struct Loud { T v; ~Loud() { ++destroyed; } };
template<typename T> Loud<T> MakeLoud(T v) { Loud<T> l; l.v = v; return l; }
inline int Destroyed() { return destroyed; }
''';
fn F[template T: type](v: T) -> i32 { let unused l: Cpp.Loud(T) = Cpp.MakeLoud(v); return 3; }
fn Run() -> i32 { Core.Print(F(1 as i32)); Core.Print(Cpp.Destroyed()); return 0; }
```

<!-- google-doc-style-resume -->

`va`:

<!-- google-doc-style-ignore -->

```carbon
// === va/va1_cpp_variadic_template_each_T.carbon
import Core library "io";
import Cpp inline '''
template<typename... Ts> int Sum(Ts... xs) { return (0 + ... + xs); }
''';
fn F[T: type](... each x: T) -> i32 { return Cpp.Sum(... each x); }
fn Run() -> i32 { Core.Print(F(1 as i32, 2 as i32)); return 0; }

// === va/va2_cpp_fn_each_i32.carbon
import Core library "io";
import Cpp inline '''
inline int TakeInt(int x) { return x + 100; }
''';
fn F(... each x: i32) -> i32 { return Cpp.TakeInt(... each x); }
fn Run() -> i32 { Core.Print(F(1)); return 0; }

// === va/va3_cpp_call_in_expansion_body.carbon
import Core library "io";
import Cpp inline '''
inline int total = 0;
template<typename T> void Add(T x) { total += x; }
inline int Total() { return total; }
''';
fn F[T: type](... each x: T) { ... Cpp.Add(each x); }
fn Run() -> i32 { F(3 as i32, 4 as i32); Core.Print(Cpp.Total()); return 0; }

// === va/va4_baseline_twice.carbon
import Core library "io";
import Cpp inline '''
template<typename T> T Twice(T x) { return x + x; }
''';
fn G[T: type](x: T) -> T { return Cpp.Twice(x); }
fn Run() -> i32 { Core.Print(G(21 as i32)); return 0; }

// === va/va5_cpp_variadic_template_each_T_uncalled.carbon
import Core library "io";
import Cpp inline '''
template<typename... Ts> int Sum(Ts... xs) { return (0 + ... + xs); }
''';
fn F[T: type](... each x: T) -> i32 { return Cpp.Sum(... each x); }
fn Run() -> i32 { Core.Print(5); return 0; }
```

<!-- google-doc-style-resume -->

`sv`:

<!-- google-doc-style-ignore -->

```carbon
// === sv/sv1_optional_T_has_value.carbon
import Core library "io";
import Cpp inline '''
#include <optional>
''';
fn F[T: type](v: T) -> bool { var o: Cpp.std.optional(T) = Cpp.std.make_optional(v); return o.has_value(); }
fn Run() -> i32 { Core.Print(if F(1 as i32) then 1 else 0); return 0; }

// === sv/sv2_optional_T_default.carbon
import Core library "io";
import Cpp inline '''
#include <optional>
''';
fn F[T: type](unused v: T) -> bool { var o: Cpp.std.optional(T); return o.has_value(); }
fn Run() -> i32 { Core.Print(if F(1 as i32) then 1 else 0); return 0; }

// === sv/sv3_optional_T_to_core_optional.carbon
import Core library "io";
import Cpp inline '''
#include <optional>
''';
fn F[T: type](v: T) -> Core.Optional(T) { var o: Cpp.std.optional(T) = Cpp.std.make_optional(v); return o; }
fn Run() -> i32 { Core.Print(if F(2 as i32).HasValue() then 1 else 0); return 0; }

// === sv/sv3b_optional_T_to_core_optional_template.carbon
import Core library "io";
import Cpp inline '''
#include <optional>
''';
fn F[template T: type](v: T) -> Core.Optional(T) { var o: Cpp.std.optional(T) = Cpp.std.make_optional(v); return o; }
fn Run() -> i32 { Core.Print(if F(2 as i32).HasValue() then 1 else 0); return 0; }

// === sv/sv3c_optional_T_to_core_optional_concrete_target.carbon
import Core library "io";
import Cpp inline '''
#include <optional>
''';
fn F[T: type](v: T) -> Core.Optional(i32) { var o: Cpp.std.optional(T) = Cpp.std.make_optional(v); return o; }
fn Run() -> i32 { Core.Print(if F(2 as i32).HasValue() then 1 else 0); return 0; }

// === sv/sv4_optional_T_match.carbon
import Core library "io";
import Cpp inline '''
#include <optional>
''';
fn F[T: type](v: T) -> i32 {
  var o: Cpp.std.optional(T) = Cpp.std.make_optional(v);
  match (o) {
    case .Some(_: T) => { return 1; }
    default => { return 0; }
  }
}
fn Run() -> i32 { Core.Print(F(3 as i32)); return 0; }

// === sv/sv5_optional_concrete_to_core.carbon
import Core library "io";
import Cpp inline '''
#include <optional>
''';
fn F(v: i32) -> Core.Optional(i32) { var o: Cpp.std.optional(i32) = Cpp.std.make_optional(v); return o; }
fn Run() -> i32 { Core.Print(if F(4).HasValue() then 1 else 0); return 0; }

// === sv/sv6_cpp_call_returning_optional_T.carbon
import Core library "io";
import Cpp inline '''
#include <optional>
template<typename T> std::optional<T> Wrap(T v) { return v; }
''';
fn F[T: type](v: T) -> bool { let o: Cpp.std.optional(T) = Cpp.Wrap(v); return o.has_value(); }
fn Run() -> i32 { Core.Print(if F(5 as i32) then 1 else 0); return 0; }

// === sv/sv8_optional_T_to_core_optional_uncalled.carbon
import Core library "io";
import Cpp inline '''
#include <optional>
''';
fn F[T: type](v: T) -> Core.Optional(i32) { var o: Cpp.std.optional(T) = Cpp.std.make_optional(v); return o; }
fn Run() -> i32 { Core.Print(8); return 0; }
```

<!-- google-doc-style-resume -->
