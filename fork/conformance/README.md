# Execution-conformance harness (the 0.1 arbiter)

<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

This directory is the **arbiter** defined in step 1 of
[`fork/process.md`](../process.md): an executable definition of "done" for the
0.1 milestone. Programs here must **compile, link, and run** with the expected
exit code and output — not just pass golden-dump checks. The scoreboard this
harness emits is the project's progress number.

> **The rule:** a milestone bullet (and any feature work behind it) is only
> "done" when its conformance programs PASS here, on a real toolchain, at
> runtime. No feature is done by assertion — only by scoreboard
> (`fork/process.md`, standing rule 2).

## Running

```sh
# Full run against an installed toolchain tree's `carbon` busybox binary
# (for example an extracted nightly carbon_toolchain tarball):
python3 fork/conformance/runner.py \
    --toolchain /path/to/carbon_toolchain-*/bin/carbon

# Subset by path substring:
python3 fork/conformance/runner.py --toolchain ... --filter types/

# Custom output directory (default: fork/conformance/out):
python3 fork/conformance/runner.py --toolchain ... --out /tmp/conformance-out

# Validate program headers + bullet names without a toolchain:
python3 fork/conformance/runner.py --self-test
```

Pure python3 stdlib; no bazel, no network. Exit code is 1 if any non-SKIP
program fails.

Outputs under `--out`:

-   `scoreboard.json` — machine-readable results: per-program statuses and the
    per-bullet rollup (including `NOT-WRITTEN` for every gap-analysis bullet
    that has no program yet, per process.md's scoreboard definition).
-   `logs/<name>.log` — command line, stdout, stderr for each failure.
-   `obj/`, `bin/` — kept compile/link artifacts for debugging.

### Toolchain invocation

For each program the runner executes:

```sh
<carbon> compile [COMPILE-ARGS...] --output=<out>/obj/<name>.o --output-last-input-only <prog>.carbon
<carbon> link --output=<out>/bin/<name> <out>/obj/<name>.o
<out>/bin/<name>     # 30s timeout; exit code + stdout captured
```

This mirrors `toolchain/install/install_test.py` (`run_carbon_test`), the one
upstream test that exercises an installed tree end-to-end. Details that
matter:

-   `--include-carbon-core` is the compile default
    (`toolchain/driver/compile_driver.cpp`), which is what resolves
    `import Core library "io"` against the install tree. Because that adds the
    prelude + Core files as extra compilation units, we pass
    `--output-last-input-only` (as `bazel/carbon_rules/defs.bzl` does) so only
    the program's own object is written, warning-free.
-   `carbon link` builds the Carbon **prelude** runtimes on demand and links
    them automatically (`toolchain/driver/link_driver.cpp`) — but _not_ the
    rest of the Core objects (explicit TODO there). Programs therefore print
    with `Core.Print`/`Core.PrintChar`, which lower inline to
    `printf`/`putchar` (`toolchain/lower/handle_call.cpp`), and avoid
    `Core.PrintStr`, whose body lives in `core/io.impl.carbon` and is only
    linked by the bazel `carbon_binary` rule or the `carbon build` subcommand.
-   The **first** link on a fresh machine builds runtimes (compiler-rt, libc++,
    prelude objects) on demand and can take many minutes; later links hit the
    runtimes cache. Hence the generous default `--link-timeout=1800`.

## Program format

Programs live at `programs/**/*.carbon`. Each is a single self-contained
`Main//default` file (no `package`/`library` declaration) with a `Run` entry
point, 10–40 lines, arbitrating **one** concept. Directives sit in the
leading comment block:

```carbon
// CONFORMANCE-BULLET: <exact bullet text from the table in fork/gap-analysis.md>
// COMPILE-ARGS: <args>        (optional; extra `carbon compile` flags)
// EXPECT-EXIT: <int>          (optional; default 0)
// EXPECT-STDOUT:              (optional; if absent, stdout is unchecked)
//   <literal line 1>
//   <literal line 2>
// SKIP: <reason>              (optional; marks a not-yet-runnable program)
```

-   `CONFORMANCE-BULLET` is **required** and must match a first-column cell of
    the "Per-bullet status" table in [`fork/gap-analysis.md`](../gap-analysis.md)
    character-for-character (`--self-test` enforces this).
-   `EXPECT-STDOUT` continuation lines are `//` + three spaces + the literal
    expected line; the captured stdout must equal the lines joined with
    newlines (each line newline-terminated). Note `Core.Print(x)` prints
    `<int>\n`.
-   `COMPILE-ARGS` is whitespace-split and inserted into the `carbon compile`
    command line right after `compile` (before the runner's own `--output` /
    `--output-last-input-only` flags). Programs use it to pin a per-program
    compile configuration — for example `--cpp-exceptions=none` for the
    error-handling boundary programs. A program whose flags the driver rejects
    is an honest `COMPILE-FAIL` (write-tests-first: red until the flag lands).
-   `SKIP` exists for programs written ahead of their feature
    (write-tests-first, per process.md step 1). Keep SKIPs rare; prefer
    writing programs against constructs that already work.

### Differential Carbon-vs-C++ programs

A program `<name>.carbon` may have a sibling file `<name>.diff.cpp`: an
equivalent plain C++17 program. When present, the runner — after the Carbon
binary runs and passes its EXPECT-* checks (which stay authoritative) —
additionally compiles the C++ file with the toolchain's **own** clang++
(`<root>/lib/carbon/llvm/bin/clang++`, the busybox symlink next to
`bin/carbon`; it builds runtimes on demand like `carbon link`, so the C++
compile gets the link timeout), runs it, and requires:

-   C++ exit code == Carbon exit code, and
-   C++ stdout byte-identical to Carbon stdout.

Any divergence (including a C++-side compile failure or timeout) is the
`DIFF-MISMATCH` status. This makes real clang-compiled C++ the oracle for
output values instead of hand-authored `EXPECT-STDOUT` alone — for an
interop-first language, "the Carbon program and the equivalent C++ program
produce byte-identical output" is the honest arbiter, and it catches
wrong-value expectations a program author could bake into `EXPECT-STDOUT`
(fork/ORCHESTRATION.md next-action 6). Differential programs therefore
deliberately omit `EXPECT-STDOUT` and let the C++ side compute the
expectation. Mirror `Core.Print`'s exact lowering in the C++ side:
`printf("%d\n", x)` with the argument as `int`
(toolchain/lower/handle_call.cpp). `--self-test` validates that every
`*.diff.cpp` sits next to its matching `*.carbon` program.

Statuses per program: `PASS`, `COMPILE-FAIL`, `LINK-FAIL`, `RUN-FAIL`
(crash, timeout, or wrong exit code), `OUTPUT-MISMATCH`, `DIFF-MISMATCH`
(Carbon and differential C++ diverge, or the C++ side fails to build/run),
`SKIP`.

## Bullet mapping and rollup

Every program names the milestone bullet it arbitrates. The rollup rule:

-   A bullet **PASSes** only if _all_ of its programs pass (skips don't count
    against it, but a bullet with only SKIPs is `SKIP`, not `PASS`).
-   Any program failure makes its bullet **FAIL**.
-   Bullets in the gap-analysis table with no programs are **NOT-WRITTEN** —
    visible debt: growing this suite is a permanent first-class workstream.

Current programs (auto-generated; regenerate with
`python3 fork/conformance/runner.py --update-readme-table` — `--self-test`
fails if this table is stale):

<!-- BEGIN PROGRAM TABLE (generated by runner.py --update-readme-table) -->

| Program | Bullet | Kind |
| --- | --- | --- |
| `code_org/impl_files_impl_defined_fn.carbon` | Code organization: Implementation files | SKIP |
| `code_org/impl_files_pair_in_compile.carbon` | Code organization: Implementation files | run |
| `code_org/importing_core_library.carbon` | Code organization: Importing | run |
| `code_org/importing_cpp_header.carbon` | Code organization: Importing | run |
| `code_org/importing_cpp_inline.carbon` | Code organization: Importing | run |
| `code_org/library_multifile_export.carbon` | Code organization: Libraries | SKIP |
| `code_org/library_named_import.carbon` | Code organization: Libraries | run |
| `code_org/namespaces.carbon` | Code organization: Namespaces | run |
| `code_org/packages_cross_import.carbon` | Code organization: Packages | run |
| `code_org/packages_restricted_names.carbon` | Code organization: Packages | run |
| `code_org/packages_scope_expr.carbon` | Code organization: Packages | run |
| `control_flow/choice_payload_roundtrip_diff.carbon` | Control flow: matching — sum-type consumption incl. std::variant/std::optional interop | differential |
| `control_flow/conditions.carbon` | Control flow: conditions | run |
| `control_flow/if_let_let_else.carbon` | Control flow: matching — if-let / let-else combined match+declaration | SKIP |
| `control_flow/loops.carbon` | Control flow: loops incl. range-based and C/C++ loop equivalents | run |
| `control_flow/match_guard_binding.carbon` | Control flow: matching — good switch equivalents | SKIP |
| `control_flow/match_no_fallthrough.carbon` | Control flow: matching — good switch equivalents | run |
| `control_flow/match_position.carbon` | Control flow: matching — good switch equivalents | run |
| `control_flow/match_sum_type_payload.carbon` | Control flow: matching — sum-type consumption incl. std::variant/std::optional interop | SKIP |
| `control_flow/match_switch.carbon` | Control flow: matching — good switch equivalents | run |
| `control_flow/match_switch_diff.carbon` | Control flow: matching — good switch equivalents | differential |
| `control_flow/range_iter_diff.carbon` | Control flow: loops incl. range-based and C/C++ loop equivalents | differential |
| `error_handling/control_flow_constructs.carbon` | Error handling: dedicated control flow constructs | SKIP |
| `error_handling/cpp_exception_interop.carbon` | Error handling: C++ exception interop (-fno-except config, calling throwing C++, exporting Carbon errors as std::expected/exceptions) | SKIP |
| `error_handling/cpp_exceptions_auto_catch.carbon` | Error handling: C++ exception interop (-fno-except config, calling throwing C++, exporting Carbon errors as std::expected/exceptions) | run |
| `error_handling/cpp_exceptions_fence_terminate.carbon` | Error handling: C++ exception interop (-fno-except config, calling throwing C++, exporting Carbon errors as std::expected/exceptions) | run |
| `error_handling/cpp_exceptions_none_mode.carbon` | Error handling: C++ exception interop (-fno-except config, calling throwing C++, exporting Carbon errors as std::expected/exceptions) | run |
| `functions/forward_decl.carbon` | Functions: separate declaration and definition | run |
| `functions/overloading_native.carbon` | Functions: function overloading (Carbon-native) | SKIP |
| `generics/checked_generics.carbon` | Generics: Checked generics | run |
| `generics/generic_class.carbon` | Generics: generic functions and types | run |
| `generics/structural_conformance.carbon` | Generics: Template-style structural conformance to nominal constraints | SKIP |
| `generics/templates_dependent_member.carbon` | Generics: Integrated templates | SKIP |
| `generics/templates_type_param.carbon` | Generics: Integrated templates | run |
| `generics/templates_value_param.carbon` | Generics: Integrated templates | run |
| `generics/variadics_each.carbon` | Generics: Definition-checked variadics | SKIP |
| `interop/cpp_adl_swap_extension_point.carbon` | Functions: C++ interop — open overload sets as extension points (swap etc.) | SKIP |
| `interop/cpp_compat_long_adapters.carbon` | Stdlib C++ interop: transparent fundamental-type mapping | run |
| `interop/cpp_concept_export_predicate.carbon` | Generics: C++ interop — C++20 concepts <-> named predicates mapping | SKIP |
| `interop/cpp_concept_import_predicate.carbon` | Generics: C++ interop — C++20 concepts <-> named predicates mapping | SKIP |
| `interop/cpp_export_function.carbon` | Functions: C++ interop — exporting Carbon functions/methods to C++ | run |
| `interop/cpp_export_method.carbon` | Functions: C++ interop — exporting Carbon functions/methods to C++ | run |
| `interop/cpp_fundamental_types.carbon` | Stdlib C++ interop: transparent fundamental-type mapping | run |
| `interop/cpp_generic_export_deduced_builtin.carbon` | Generics: C++ interop — exporting Carbon templates/checked generics as C++ templates | run |
| `interop/cpp_generic_export_interface_dispatch.carbon` | Generics: C++ interop — exporting Carbon templates/checked generics as C++ templates | run |
| `interop/cpp_generic_export_nontype_param.carbon` | Generics: C++ interop — exporting Carbon templates/checked generics as C++ templates | SKIP |
| `interop/cpp_iostream.carbon` | Functions: C++ interop — importing/calling C++ functions and methods | run |
| `interop/cpp_iterate_generic_adl_range.carbon` | Stdlib C++ interop: transparent iteration-abstraction mapping | run |
| `interop/cpp_iterate_generic_member_range.carbon` | Stdlib C++ interop: transparent iteration-abstraction mapping | run |
| `interop/cpp_iterate_sentinel_range_for.carbon` | Stdlib C++ interop: transparent iteration-abstraction mapping | run |
| `interop/cpp_operator_export.carbon` | Type system: C++ interop — exporting Carbon operator overloads into C++ | SKIP |
| `interop/cpp_operator_import_arithmetic.carbon` | Type system: C++ interop — synthesizing Carbon overloads for imported C++ types | run |
| `interop/cpp_operator_import_assignment.carbon` | Type system: C++ interop — synthesizing Carbon overloads for imported C++ types | SKIP |
| `interop/cpp_operator_import_compare.carbon` | Type system: C++ interop — synthesizing Carbon overloads for imported C++ types | run |
| `interop/cpp_overload_set_by_type.carbon` | Functions: C++ interop — importing C++ overload sets | run |
| `interop/cpp_overload_set_default_args.carbon` | Functions: C++ interop — importing C++ overload sets | run |
| `interop/cpp_overload_set_literals.carbon` | Functions: C++ interop — importing C++ overload sets | run |
| `interop/cpp_range_adl_begin_end_iterate.carbon` | Functions: C++ interop — open overload sets as extension points (swap etc.) | run |
| `interop/cpp_range_member_begin_end_iterate.carbon` | Functions: C++ interop — open overload sets as extension points (swap etc.) | run |
| `interop/cpp_span_view.carbon` | Stdlib C++ interop: transparent non-owning contiguous container mapping (incl. owning->view) | SKIP |
| `interop/cpp_template_builtins.carbon` | Generics: C++ interop — importing C++ templates, instantiating on Carbon types | run |
| `interop/cpp_template_carbon_class.carbon` | Generics: C++ interop — importing C++ templates, instantiating on Carbon types | run |
| `interop/cpp_template_on_carbon_generic.carbon` | Type system: C++ interop — importing C++ types / exporting Carbon types | SKIP |
| `interop/cpp_template_symbolic_arg.carbon` | Generics: C++ interop — importing C++ templates, instantiating on Carbon types | SKIP |
| `interop/cpp_threading_atomics.carbon` | C++ interop: threading, atomics, memory model, synchronization | SKIP |
| `interop/cpp_type_export_carbon_class.carbon` | Type system: C++ interop — importing C++ types / exporting Carbon types | run |
| `interop/cpp_type_import_class_enum.carbon` | Type system: C++ interop — importing C++ types / exporting Carbon types | run |
| `interop/inherit_carbon_extends_cpp.carbon` | Type system: C++ interop — bi-directional inheritance, hierarchy roots, abstract/final/virtual mapping | run |
| `interop/inherit_cpp_extends_carbon.carbon` | Type system: C++ interop — bi-directional inheritance, hierarchy roots, abstract/final/virtual mapping | run |
| `interop/inherit_multiple_bases.carbon` | Type system: C++ interop — bi-directional inheritance, hierarchy roots, abstract/final/virtual mapping | SKIP |
| `interop/string_view_cpp_to_str.carbon` | Stdlib C++ interop: transparent non-owning string mapping | run |
| `interop/string_view_str_to_cpp.carbon` | Stdlib C++ interop: transparent non-owning string mapping | run |
| `project/cmake_build_integration.carbon` | Project: CMake build-system integration plus Make documentation | SKIP |
| `project/design_docs_placeholders.carbon` | Goal: design docs documented, cohesive, understandable without placeholders | SKIP |
| `project/dropin_clang_cpp_toolchain.carbon` | Project: toolchain drop-in usage as Clang C++ toolchain with common Make/CMake build systems | run |
| `project/dropin_clang_make_cmake.carbon` | Project: toolchain drop-in usage as Clang C++ toolchain with common Make/CMake build systems | SKIP |
| `project/evaluator_docs_getting_started.carbon` | Project: basic evaluator documentation (getting started to FAQs) | run |
| `project/evaluator_docs_review.carbon` | Project: basic evaluator documentation (getting started to FAQs) | SKIP |
| `project/most_features_interop_matrix.carbon` | Project: toolchain implements most 0.1 language features incl. C++ interop without undermining evaluation | run |
| `project/most_features_language_matrix.carbon` | Project: toolchain implements most 0.1 language features incl. C++ interop without undermining evaluation | run |
| `project/most_features_missing_match.carbon` | Project: toolchain implements most 0.1 language features incl. C++ interop without undermining evaluation | SKIP |
| `project/run_exit_code.carbon` | Project: installs on Windows, macOS, and Linux and builds working programs | run |
| `project/safe_carbon_design.carbon` | Project: detailed and concrete design for safe Carbon (type/init/spatial/temporal/mutation + safe-Rust-interop analysis) | SKIP |
| `project/safety_strategy_doc.carbon` | Project: detailed safety strategy | SKIP |
| `stdlib/arith_widths_diff.carbon` | Stdlib: fundamental types (bool, iN, fN) | differential |
| `stdlib/conversion_interfaces.carbon` | Stdlib: interfaces powering language syntax (operators, conversions) | run |
| `stdlib/fundamental_types.carbon` | Stdlib: fundamental types (bool, iN, fN) | run |
| `stdlib/iterate_interface.carbon` | Stdlib: interfaces powering language syntax (operators, conversions) | run |
| `stdlib/operator_interfaces.carbon` | Stdlib: interfaces powering language syntax (operators, conversions) | run |
| `stdlib/optional_basic.carbon` | Stdlib: Optional | run |
| `stdlib/optional_missing_ops.carbon` | Stdlib: Optional | SKIP |
| `stdlib/optional_pointer_niche.carbon` | Stdlib: Optional | run |
| `stdlib/pointers.carbon` | Stdlib: pointer types | run |
| `stdlib/slices_basic.carbon` | Stdlib: Slices | SKIP |
| `stdlib/string_basic.carbon` | Stdlib: String and string-literal types | run |
| `stdlib/string_missing_ops.carbon` | Stdlib: String and string-literal types | SKIP |
| `stdlib/tuples_arrays_structs.carbon` | Stdlib: tuple/array library parts | run |
| `types/choice_basic.carbon` | Type system: Sum types (discriminated unions) | run |
| `types/choice_discriminant_diff.carbon` | Type system: Sum types (discriminated unions) | differential |
| `types/choice_payload_construct.carbon` | Type system: Sum types (discriminated unions) | run |
| `types/classes.carbon` | Type system: User-defined types (classes) | run |
| `types/inheritance.carbon` | Type system: Single inheritance | run |
| `types/operator_overloading.carbon` | Type system: Operator overloading | run |
| `types/operator_overloading_diff.carbon` | Type system: Operator overloading | differential |
| `types/union_basic.carbon` | Type system: Unions (un-discriminated) + C++ union mapping | SKIP |
| `types/virtual_dispatch.carbon` | Type system: Virtual dispatch | run |
| `types/virtual_dispatch_diff.carbon` | Type system: Virtual dispatch | differential |

<!-- END PROGRAM TABLE -->

Known intentional limitation: `types/choice_basic.carbon` arbitrates only the
working slice of its (PARTIAL) bullet — parameterless choice declaration and
binding. `match` over a choice is 100% stubbed in `check/handle_match.cpp`
and choice types have no `==`; the program's header documents this. Extend it
when match semantics (workstream W4) and choice payloads (W5) land.

## Adding programs

1.  Copy the bullet text exactly from the gap-analysis table.
2.  Derive syntax from working code in the repository (`examples/advent2024/`,
    `examples/*.carbon`, `toolchain/*/testdata/`,
    `toolchain/install/install_test.py`) — never from design docs alone.
3.  Keep one concept per program; make output observable by way of
    `Core.Print`/`Core.PrintChar`/exit codes (or `Cpp.std.cout` for interop
    programs).
4.  For already-working behavior with a natural C++ counterpart, prefer a
    differential pair: add `<name>.diff.cpp` next to the program and omit
    `EXPECT-STDOUT` so the C++ side is the oracle (see "Differential
    Carbon-vs-C++ programs" above).
5.  Run `python3 fork/conformance/runner.py --self-test`, then a full run.
