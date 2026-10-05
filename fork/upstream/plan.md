<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# Upstream-advance plan: cut 631f8fb → c1e83b0b7 (UA-1 merge, UA-2 reconciliation)

**Status:** DRAFT rev 1 awaiting two adversarial reviews (R29(c)). Branch
`claude/carbon-fork-0-1-upstream-advance` in the worktree
`/home/user/carbon-upstream`, cut from trunk 923c2f2af (post-PR #48: OV-3
landed). The local ref `upstream-trunk` is upstream `trunk` at
c1e83b0b78b6bf648661f4c448c01f11d74af115 (2026-10-05, "Use the plain
identifier for Carbon names in C++ (#7897)"), fetched from
https://github.com/carbon-language/carbon-lang.git. Trunk's floor, quoted from
fork/conformance/out/scoreboard.json (generated 2026-10-05T18:52:59Z, run
37357609478): `totals.PASS = 126`, every fail class 0, `totals.SKIP = 23`, 149
programs, **47/56 bullets** — the non-regression bar for every landed step of
this workstream. Gap-analysis header (fork/gap-analysis.md:18): 29 DONE / 21
PARTIAL / 5 MISSING / 1 DESIGN-ONLY; ledger max id W-118. The container cannot
build the toolchain (clang 18 < the clang 21 minimum upstream raised in #7779),
so every build-time claim below is pre-registered for the hosted compile and
autoupdate runs to confirm or refute (R28(b)); the measurements in §0 are from
`git` alone and are exact.

**Items:** W-001 ("INFRA-1: operationalize the F-002 upstream-merge staging
flow", size M — this plan is that flow for the first non-weekly-sized merge);
the standing rule 5 obligation (fork/process.md: "Upstream is a moving asset")
that the seven weekly entries (decision-log "Weekly upstream merge 2026-08-24"
through "2026-10-05") deferred to "an upstream advance workstream with its own
plan and two reviews". **Design authority, not reopened:** F-002 (Bun-style
merge gating: "merge upstream into a staging branch, re-run the suite, land
only when green"), standing rule 7 / V-3a (upstream intent is the default
preference; fork spellings live on the divergence-risk register "reviewed at
every upstream merge" — ten register blocks in the decision log), R16 (goldens
only by way of autoupdate), R26/R28(d) (autoupdate fixpoint proven by the
gate), R29(b) (one PR per landed step). Every decision below is an
implementation choice auto-adopted under R29(a) and veto-able after the fact.

## §0 Audit: what the merge is made of

### §0.1 Measurements (verified at 923c2f2af; every number reproducible)

| Quantity | Command | Value |
| --- | --- | --- |
| Merge base | `git merge-base HEAD upstream-trunk` | 631f8fb6d24d07d8f071497cdda6dea1bba5d871 (2026-08-20, "Modularize driver subcommands and prune unused dependencies (#7658)") — the cut the weekly entries record |
| Deferred upstream commits | `git rev-list --count 631f8fb..upstream-trunk` | **183** (the 10-05 weekly entry counted 181 at d31a8b67d; #7889 and #7897 landed since) |
| Upstream files changed | `git diff --name-only 631f8fb upstream-trunk \| wc -l` | **1533** (1094 under `testdata/`; by directory: toolchain/check 877, toolchain/lower 264, toolchain/sem_ir 50, language_server 45, utils/textmate 28, parse 20, docs/design 17, driver 15, lex 14, base 14, .github/workflows 14) |
| Fork files changed | `git diff --name-only 631f8fb HEAD \| wc -l` | 762 (toolchain 482 — 237 new goldens, 94 modified goldens, 151 sources; fork/ 230; docs 15; core 9; utils 5) |
| Overlap | `comm -12 <(…upstream…\|sort) <(…fork…\|sort)` minus `fork/` and `.github/workflows/fork_*` | **202** files: 112 non-testdata (toolchain 91, .github/workflows 6, docs/design 6, utils 5, root configs 4) + 90 goldens |
| Dry-run conflicts | `git merge --no-commit --no-ff upstream-trunk; git diff --name-only --diff-filter=U; git merge --abort` | **105** files: 20 toolchain sources, 1 design doc (lexical_conventions/words.md), 5 editor-syntax files, 79 goldens (78 content conflicts + 1 `UD`: upstream deleted lower/interop/cpp/std_initializer_list.carbon, the fork re-filled it). The tree was left clean (`git status --porcelain` empty; HEAD 923c2f2af) |
| Upstream deletions | `git diff --name-only --diff-filter=D 631f8fb upstream-trunk` | 13: two llvm patches, 3 goldens (std_initializer_list.carbon; check/generic/template_dependence.carbon and generic/template/fail_todo_template_access_assoc_const.carbon — both untouched by the fork), 8 textmate sample `.jpg`s |
| Upstream renames | `git diff --name-status -M --diff-filter=R` | 1: toolchain/install/bazel/make_include_copts.bzl → bazel/cc_toolchains/make_include_copts.bzl (toolchain/install/BUILD's `load` line moves with it; the fork's two BUILD hunks — `support_hdrs` for `<carbon/expected.h>` — are disjoint and merged cleanly in the dry run) |
| Markdown under upstream's new lint | `uvx rumdl@0.2.58 check --config <upstream .rumdl.toml> fork/ docs/design/{error_handling,unions,slices,functions_overloading}.md` | **607 issues in 34/47 files, 605 auto-fixable** (all MD013: upstream #7667 enabled line-length enforcement with `reflow = true`; the fork's tree still has MD013 disabled) |

### §0.2 The 183 deferred commits by subsystem (from `git log --oneline 631f8fb..upstream-trunk`)

1.  **Templates (the series the cut was taken before):** #7657 compound member
    access action, #7662 templated conversions, #7663 actions read the
    specific, #7671 constant InstActions, #7682 CallAction, #7689 TemplateInst,
    #7700 splice-stepping for bound methods, #7710 call-action operands, #7726
    SpecificInst, #7727 **template lowering**, #7735/#7736 tests, #7741
    dependent assignment, #7772, #7780 protected members from template-derived
    classes, #7801 dependent initialization, #7879 **SpliceInst storage-arg
    crash fix**, #7880 **SpecificInst lowering crash fix** (§0.5).
2.  **Destruction (`Destroy.SubobjectDestroy`):** #7773 (interface reshaped:
    `Op`, `final fn SubobjectDestroy`, `final fn SelfDestruct`; prelude
    destroy.carbon; core_identifier.def; custom_witness.cpp), #7824
    `BuildSelfDestructCall`, #7829 struct fields, #7842 tuples, #7844 arrays,
    #7848 constants, #7840 class fields, #7845 non-trivial preparation,
    #7846/#7847 triviality classification, #7855 desugared LocIds.
3.  **C++ function pointers and the thunk refactor:** #7787 `CalleeFunctionInfo`
    generalized and moved to cpp/thunk.h, #7788 function pointers, #7789
    Carbon function → C++ function pointer conversion, #7881 pointers to
    Carbon methods, #7865 NRVO export, #7891, #7897 plain identifiers.
4.  **Redeclarations and default values:** #7632 **unified `TryMergeRedecl`**
    (handle_function.cpp/handle_class.cpp bodies moved into merge.cpp), #7695
    redundant impl-file redeclarations diagnosed, #7631/#7649/#7665/#7737/
    #7800/#7810/#7837 pattern default values, #7716 nested tuple-pattern crash,
    #7654 `MakeGeneratedFunctionDecl` parameter forms, #7786.
5.  **Specifics and facets:** #7717 **specifics initialized in place**, #7729
    canonical generated functions, #7784 `SpecificInterface` through witness
    generation, #7813 `TypeType` as empty `FacetType`, #7866, #7819, #7817.
6.  **Prelude and language:** #7713/#7711/#7712 `match_first` in the prelude,
    #7714 `Eq`/`Ordered` named constraints, #7858 `typeof`, #7651 positional
    params lexing/parsing, #7889 `friend` parsing, #7861 words.md keywords.
7.  **Diagnostics and SemIR text:** #7768/#7804 type sugar preserved, #7827/
    #7833/#7867 stringify, #7771 SSA verifier, #7860, #7882, #7706.
8.  **Infrastructure:** #7779 **clang 21 minimum + CI**, #7781/#7856 llvm
    rolls, ~20 clang-tidy-24 NOLINT/disable commits, #7667 **rumdl line
    length**, #7692/#7742/#7809/#7877 autoupdate script, #7803 LSP SemIR,
    #7746/#7762/#7885 editor grammars, benchmarks, jj scripts, AGENTS skills.
9.  **Interop misc:** #7673 **Carbon generic types as C++ template
    parameters**, #7745 virtual-base lowering crash, #7783 derived-to-base
    SemIR fix, #7792 imported class/vtable instantiation, #7763 indirect C++
    dependency domains, #7740.

Upstream commits touching the fork's load-bearing files (`git log 631f8fb..
upstream-trunk -- <file>`): custom_witness.cpp 16 (all of group 2 plus #7729,

## 7784, #7813, #7654, #7788/#7789); cpp/thunk.cpp 2 (#7787, #7788); cpp/export.cpp

10; cpp/import.cpp 12; cpp/generate_ast.cpp 3; call.cpp 6 (#7788, #7800, #7729,

## 7689, #7700, #7682); deduce.cpp 2 (#7813, #7670 — the fork's `diagnose` flag

hunk is untouched); pattern_match.cpp 8 (default values, #7867); class.cpp 3
(#7745, #7796, #7706); eval.cpp 13; lower/function_context.cpp 4;
lower/handle.cpp 6; import_ref.cpp 12; handle_function.cpp 8;
handle_pattern_list.cpp 7; impl_lookup.cpp 4; core/prelude 3 (destroy.carbon,
float.carbon, operators/comparison.carbon — none of the fork's nine prelude
files); **zero** on handle_match.cpp, refutable_binding.cpp, handle_index.cpp,
builtin_function_kind.{def,cpp}. file_test: #7877 (autoupdate reports tests
that would still fail), #7803 (LSP in testdata) — the fork's one file_test.cpp
hunk (Clang declaration id at end of line, OV-3) merged cleanly in the dry run.

### §0.3 Conflict classification (file → class → strategy)

Classes: **A** trivially adjacent (both sides inserted at one anchor; keep
both); **B** fork mechanism vs upstream refactor (upstream's structure wins,
the fork mechanism is re-expressed inside it); **C** upstream superseded the
fork mechanism (adopt upstream's, delete the fork's, the fork's goldens and
programs stay as pins); **D** upstream removed something the fork relies on
(none found among textual conflicts; the two _silent_ instances are §0.4).
Marker counts are from the dry run (`++<<<<<<<` per file).

| File | Markers | Class | What collides | Resolution (details §2) |
| --- | --- | --- | --- | --- |
| check/call.cpp | 1 | A | fork's `PerformCallToOverloadSet` block (OV-1/OV-2, +393) and upstream's `IsCppTemplateCallPerformable` inserted after `PerformCallToFunction` | keep both; verify the `PerformCall` dispatch has both the `CalleeOverloadSet` arm (:756) and upstream's `CalleeCppFunctionPointer` arm |
| check/convert.cpp | 1 | A | include lines (`cpp/import.h` fork, `cpp/export.h` upstream) | keep both |
| check/core_identifier.def | 1 | A | `Exception`/`Result`/`Slice`… (fork) vs `SelfDestruct`/`SubobjectDestroy` (upstream) | keep both, alphabetical |
| check/cpp/export.cpp | 1 | **C** | fork's F8d `GetOrExportFunctionDeclToCpp` (W-023) vs upstream's `GetOrExportFunctionToCpp` + `ExportFunctionToCppPointerConversion` (#7789) | take upstream; delete the fork helper and its export.h declaration (:86); D-UA-8 |
| check/cpp/import.cpp | 2 | **B/C** | `MakeParamPatterns` loop (fork skips constant-function params; upstream builds `self` first and indexes by `CalleeFunctionInfo` offsets); `ImportFunctionDecl` thunk attachment (fork's fence-unbuildable `SemanticsTodo` block vs upstream's `DefineAsThunkCall`) | take upstream's loop (the constant-param skip retires with D-UA-8); take `DefineAsThunkCall` and re-add the fence-unbuildable check after it (D-UA-7) |
| check/cpp/import.h | 1 | A | fork's `NoteInCppThunk`/`ImportCppThunkFunctionDecl` vs upstream's `ImportFunctionPointerInvoke` | keep both |
| check/cpp/thunk.cpp | 12 | **B** | fork's anonymous-namespace `CalleeFunctionInfo` (+constant params, `is_catching`, fence, `BuildCatchingThunkBody`, `WrapInBoundaryDiagnostic`, `IsCppThunkFenceRequired`) vs upstream's public `CalleeFunctionInfo` with `SelfParamKind` (incl. `FunctionPointer`) and `BuildCppThunk(context, callee_info)` | upstream's struct and signatures; fork's fence/catching machinery re-expressed on them; D-UA-7 |
| check/cpp/thunk.h | 1 | **B** | same | upstream's struct; fork's `IsCppThunkFenceRequired`, `BuildCppCatchingThunk`, `GetOrBuildCppCatchingThunkDecl` declared beside it |
| check/custom_witness.cpp | 5 | **B** | `CanDestroyClass` signature (fork: `SpecificInterfaceId` + `query_is_symbolic`; upstream: `SpecificInterface`), its two call sites, and one 600-line hunk where the fork's impl-population scans (`HasUserDestroyImpl`, `HasClassKeyedImpl`, `HasNonTrivialUserCopyImpl`, `IsTriviallyDestructible`, `HasTrivialClassShapeForExport`) sit against upstream's `DestroyStructFields`/`MakeSubobjectDestroyOpBody`/`MakeDestroySelfDestructFunction` | upstream's `SpecificInterface` parameter type and three-entry Destroy witness; the fork's predicates, `query_is_symbolic` threading, choice-copy and union-unformed witnesses survive; D-UA-9 |
| check/eval.cpp, eval.h | 3, 1 | **C** | fork's `TryEvalBlockForSpecific(..., publish_block_id) -> pair<InstBlockId,bool>` (S3b incremental publication) vs upstream's in-place value block (#7717) | take upstream; D-UA-10 |
| check/generic.cpp, sem_ir/generic.cpp | 1, 1 | **C** | fork's pre-sized placeholder + loud CHECKs in `GetConstantInSpecific` vs upstream's `NotConstant` for unreached entries | take upstream; D-UA-10 |
| check/function.cpp, function.h | 1, 1 | A | upstream's return-form fields (`return_form`, `param_kinds`) land where the fork's generated-function changes (W-075 return slot, overload index) sit | keep both |
| check/handle_class.cpp | 2 | **B** | fork deleted `BuildClassDecl`'s body (moved to class.cpp `BuildClassOrUnionDecl`, UN-1); upstream rewrote it onto `TryMergeRedecl<SemIR::Class>` (#7632) | keep the fork's deletion; port upstream's new body into class.cpp; D-UA-6 |
| check/handle_function.cpp | 3 | **B** | fork's `MergeFunctionRedecl(…, replace_prev_inst, prev_decl_override)` + `TryMergeIntoOverloadSet` + marker/gate diagnostics (OV-1/OV-2) vs upstream's deletion of `MergeFunctionRedecl` in favor of `TryMergeRedecl<SemIR::Function>` and the new `CheckDefaults` | upstream's template for plain functions; the overload-set path runs before it; D-UA-6 |
| check/handle_pattern_list.cpp | 1 | A | includes | keep both |
| check/import_ref.cpp | 1 | A | includes (`overload_set.h` vs `singleton_insts.h`) | keep both |
| check/member_access.cpp | 1 | A | `GetSelfIfInstanceMethod` arms (`CalleeOverloadSet` fork, `CalleeCppFunctionPointer` upstream) | keep both |
| lower/function_context.cpp | 1 | A | fork's `TryEmitGlobalLetValue` (W-069) before the `is_concrete` CHECK; upstream's `require_value` (#7880) around it | keep both: the fork's early return first, then upstream's conditional CHECK and `nullptr` return; D-UA-11 |
| lower/type.cpp | 1 | A | placeholder-type list: fork adds `OverloadSetType`, upstream removes `FacetType` (#7734) | upstream's list plus `OverloadSetType` |
| sem_ir/expr_info.cpp | 1 | A | callee-category arms | keep both |
| sem_ir/function.h | 1 | A | `Callee` variant members | six alternatives; every `CARBON_KIND_SWITCH` over `Callee` gains the missing arm (§8.4 grep) |
| sem_ir/stringify.cpp | 1 | A | `StringifyInst` overloads (`OverloadSetType` vs `CppFunctionPointerType`) | keep both |
| docs/design/lexical_conventions/words.md | 1 | A | `union` (fork) vs `typeof`/`unused`/`val` (upstream #7861) in the keyword list | keep all, alphabetical (`overload` is a modifier the fork's page already lists; add it only if upstream's list carries modifiers — it does: `static`, `val`) |
| utils/textmate/Syntaxes/carbon.tmLanguage, utils/vscode/carbon.tmLanguage.json | 2, 2 | **B** | upstream's grammar overhaul (#7746) restructured the keyword classes (`misc-keywords` dissolved into `storage.modifier`) where the fork added `union`/`overload` | upstream's structure; `union` joins the introducer alternation, `overload` the `storage.modifier` alternation; D-UA-5 |
| utils/textmate/Samples/keywords.carbon | 2 | **B** | same | upstream's sample lines plus the two keywords; regenerate renderings only if upstream's generator (#7762) is run in CI (it is not) |
| utils/vim/syntax/carbon.vim | 3 | **B** | upstream renamed `destructor`→`destroy`, added `carbonOtherDeclaration`/`carbonDeclarationMod` | upstream's lines; `overload` appended to `carbonClassMethodDeclarationMod`; `carbonUnionDeclaration` kept |
| utils/tree_sitter/queries/highlights.scm | 2 | A | fork's commented `; "overload"`/`; "union"` (W-091: grammar.js lacks the tokens) vs upstream's new entries | keep both; the fork lines stay commented (W-091 unchanged; #7885's grammar still has no `union`) |

**Goldens (79).** Indentation-aware classification (`git diff 631f8fb HEAD --
<f> \| grep -v '^[+-] *// CHECK'`): **77** are refill-only on the fork side
(every fork change is a CHECK line, incl. the indented `// CHECK:STDERR:` lines
inside split files); upstream edited source lines in 32 of them (#7656 renames
entities to avoid name reuse; #7788/#7789 restructure function_ptr/
decayed_param). **2** carry fork source edits: check/let/fail_generic_import
.carbon (split file `fail_implicit.impl.carbon` → `implicit.impl.carbon` —
W-074 made it pass) and lower/var/import.carbon (`fn X() -> i32 { return x; }`
— W-069's cross-file runtime `let`). **1** is upstream-deleted (std_initializer
_list.carbon, fork side refill-only). Resolution D-UA-3.

#### §0.4 Semantic conflicts the dry run does NOT show (textually clean merges that break)

Each is a build or behavior break the hosted compile would be the first to
report; the plan pre-registers them so the merge commit already resolves them.

1.  **Duplicate `case` in `TryMapType`:** the fork's `case SemIR::FunctionType::
    Kind:` (cpp/type_mapping.cpp:437, F8d's call-argument-only mapping through
    `TryMapFunctionType`) and upstream's `case CARBON_KIND(SemIR::FunctionType
    function_type):` (#7789, upstream type_mapping.cpp:287) land in ONE switch —
    ill-formed. Resolved by D-UA-8 (the fork case goes).
2.  **`BuildClassOrUnionDecl` calls deleted API:** class.cpp (fork, UN-1) carries
    copies of `MergeClassRedecl` and `MergeOrAddName` (class.cpp:46, :86) written
    against the pre-#7632 merge.h; upstream's merge.h replaces that surface with
    `MergeRedeclEntityInfo<EntityT>` + `TryMergeRedecl<EntityT>`, and
    `DiagnoseIfInvalidRedecl`/`CheckRedeclParamsMatch` keep their names. The
    copied helpers compile only by accident if at all; D-UA-6 ports them.
3.  **Destroy witness arity:** upstream's `Destroy` interface has THREE
    associated entities (`Op`, `SubobjectDestroy`, `SelfDestruct`; prelude
    destroy.carbon) and `BuildDestroyWitness` CHECKs `assoc_entities.size() ==
    3`; the fork's `BuildDestroyWitness(format)` builds a one-entry witness
    (`{op_id}`) and the fork's `MakeDestroyOpBody(format)` is the placeholder
    upstream replaced with `MakeSubobjectDestroyOpBody`. Every fork-built
    Destroy witness (`LookupDestroyWitness`, `BuildTrivialDestroyWitness`, the
    B2a symbolic-choice path through `CanDestroyType`) must build upstream's
    three-entry shape. D-UA-9.
4.  **`SpecificInterfaceId` → `SpecificInterface`:** #7784 changed the witness
    builders' query parameter type; the fork's `LookupChoiceCopyWitness`,
    `LookupUnionUnformedInitWitness`, `BuildPrimitiveCopyWitness` (W-075
    return-slot form), `MakeBuiltinOperatorFunction` callers and
    custom_witness.h declarations (fork `+3` decls, upstream signature changes
    on the shared ones — merged cleanly because the hunks differ) must agree.
5.  **`Callee` variant exhaustiveness:** six alternatives after the merge
    (`CalleeCppFunctionPointer`, `CalleeCppOverloadSet`, `CalleeError`,
    `CalleeFunction`, `CalleeNonFunction`, `CalleeOverloadSet`). Upstream
    switches over `Callee` at call.cpp:408/:455, cpp/call.cpp:84, eval.cpp:2897,
    member_access.cpp:82, expr_info.cpp:107, sem_ir/function.cpp:69; the fork's
    are call.cpp:751-756, cpp/call.cpp:97-100, member_access.cpp:73-83,
    expr_info.cpp:92-96, sem_ir/function.cpp:66-75. Two of these pairs conflict
    textually (kept both); the other four (call.cpp dispatch, cpp/call.cpp,
    eval.cpp, sem_ir/function.cpp) merge cleanly and must be checked by hand
    for the missing arm (§8.4).
6.  **`SelfParamKind::FunctionPointer`:** a new callee kind the fork's fence
    predicate never saw. `IsCppThunkFenceRequired` takes a `FunctionDecl*`; a
    function-pointer callee has none (`CalleeFunctionInfo::decl == nullptr`,
    thunk.h comment). D-UA-7 decides.
7.  **`IsCppThunkRequired` callers:** fork signature `(Context&, const
    SemIR::Function&)` vs upstream `(Context&, const CalleeFunctionInfo&)`;
    callers in cpp/import.cpp:2061 (conflicting hunk) and thunk.cpp:1215
    (catching-thunk import path, clean hunk) must move to upstream's.
8.  **rumdl MD013:** upstream's `.rumdl.toml` (not fork-modified, so it arrives
    verbatim) enables line-length enforcement with reflow; the gate's `uvx prek
    run --all-files` would reflow 34 fork-authored documents and fail on the
    modification. 605 of the 607 findings are auto-fixable (§0.1). D-UA-4.
9.  **x-macro order and sorted-list tests:** token_kind.def (fork `union`,
    `overload`, upstream `typeof`), parse/node_kind.def (+17 fork, +12
    upstream), diagnostics/kind.def (+59 fork, +14/-3 upstream; #7660 added the
    registered-vs-declared check), parse/state.def, sem_ir/inst_kind.def and
    typed_insts.h (+58 fork, +217 upstream) merged cleanly; the gate's typed-
    node and kind tests arbitrate ordering.
10. **#7695 redundant impl-file redeclarations:** a forward declaration in an
    impl file that repeats the api file's is now diagnosed. The fork's two
    multi-unit conformance programs define, not redeclare (`overload fn Dist
    (…) -> i32 {` in overloading_cross_library/geometry.impl.carbon; the
    library_multifile_export impl likewise), so no program is expected to
    move; OV-2's api/impl goldens may gain the diagnostic where they
    redeclare — upstream-intended, adopted by refill (R-11).

#### §0.5 The two A/B regressions the weekly entries record

-   **09-21 signature** (`FATAL at lower/handle.cpp:294: Unexpected category 9
    for return expression {kind: SpliceInst}` on generics/templates_type_param
    .carbon): upstream f1bf78948 "Fix crash when getting the storage arg for a
    SpliceInst (#7879)", 2026-10-01, edits exactly sem_ir/expr_info.cpp's
    category computation (+11) and adds check/generic/template/convert.carbon.
-   **09-28 signature** (`CHECK failure at lower/function_context.cpp:198:
    const_id.is_concrete(): Missing value … {kind: StructLiteral, … symbolic}`
    on the same program): upstream 3dadff7d0 "Fix lowering crash when a
    SpecificInst's inst_id doesn't emit a value (#7880)", 2026-10-01, edits that
    very CHECK (function_context.cpp +17: the `require_value` parameter in the
    conflicting hunk of §0.3) and adds lower/template/class.carbon.

Both fixes are inside the deferred range, so the merged tip CAN pass both
probes; whether it DOES is unknowable without a run (§8.2). The fork's
`templates_value_param.carbon` was already clean at the 09-14 tip. The
mirrored arbiters available to the container predate the fixes (the fork's
newest mirror release is `arbiter-v0.0.0-0.nightly.2026.09.28`; `gh api` to
the upstream repository is not enabled for this session — 403 — so no newer
nightly could be fetched here).

#### §0.6 Ledger items and gap rows upstream may have moved (UA-2 verifies each)

| Item / row | Upstream commit(s) | Expected state after the merge | How UA-2 verifies |
| --- | --- | --- | --- |
| W-023 TA-D1 (`std::thread(carbon_fn)`; DISCHARGED by F8d) | #7788/#7789 function pointers; #7881 pointers to Carbon methods | mechanism replaced (D-UA-8): upstream converts a Carbon function value to a C++ function pointer end to end (`convert.cpp` → `ExportFunctionToCppPointerConversion`, lowering in constant.cpp/handle.cpp) | interop/cpp_thread_carbon_fn_diff.carbon PASS with the F8d embedding deleted |
| W-108 member-held `Core.Buf` not destroyed (SL-1 residue) | #7829 struct fields, #7840 class fields, #7842 tuples, #7844 arrays: the synthesized `SubobjectDestroy.Op` calls each field's `Destroy.SelfDestruct`, which for `Buf` resolves to its declared impl's `Op` (the D-SL-16 selection) | plausibly DISCHARGED for aggregates without a user `Destroy` impl; NOT for classes whose own impl is user-declared (their `SubobjectDestroy` is the interface's `final` placeholder — #7773's stated limit) | a lower golden holding a `Buf` field shows `free` (no W-108 pin exists in testdata today — `grep -rn W-108 toolchain fork/conformance/programs` is empty — so UA-2 adds the pin golden first, then un-files on the fill) |
| W-014 W7 templates / gap row 52 (Integrated templates PARTIAL; SKIP generics/templates_dependent_member.carbon cites `lower/handle.cpp:363 Template lowering not implemented`) | #7727 template lowering, #7801, #7741, #7657; the `CARBON_FATAL` left is "Cross-file template lowering not implemented yet" (upstream handle.cpp:400); upstream deleted its last `fail_todo` in generic/template/ | the single-file SKIP program likely compiles | un-SKIP probe commit; row 52 evidence re-cited |
| W-043 / gap rows 40 and 54 (SKIP interop/cpp_template_symbolic_arg.carbon and cpp_template_on_carbon_generic.carbon: "unsupported type used as template argument") | #7673 "Support using Carbon generic types as C++ template parameters" | likely lifted | un-SKIP probes |
| W-046 / row 43 (SKIP interop/inherit_multiple_bases.carbon) | #7745 virtual-base lowering crash, #7783 derived-to-base SemIR fix | uncertain (the SKIP cites two-base derived-to-base conversion, not virtual bases) | un-SKIP probe; revert on failure |
| W-037 lambdas/positional params | #7651 lexing and parsing of positional params | parse half present; check still stubs | title note only |
| W-030 interface `default`/`final` members | #7817 eval block, #7773 `final fn` bodies in interfaces | partial | note; no un-SKIP |
| W-083 `Cpp.Exception` release-on-destroy | #7845 prepares non-trivial `SubobjectDestroy` | still open; the choice-payload destroy synthesis it waits on is closer | note |
| W-091 tree-sitter `union` | #7885 grammar update | unchanged (no `union` token) | grep grammar.js |
| W-065 DOCS-1 / row 89 | #7823 member access, #7839 redeclaration, #7875 generics, #7869 tracked updates | upstream closed placeholders the row's evidence may cite | re-read the row |
| Divergence-risk register (ten blocks) | #7897 (names in C++ no longer use `GetFormatted`), #7773 (interface shape), #7714 (`Eq`/`Ordered` constraints beside `EqWith`, which `Core.Result` imports — still present at upstream comparison.carbon:12) | each entry re-checked; the `_CF__carbon_thunk:overload<N>` asm label (D-OV-17) is a Carbon mangled name, untouched by #7897 | the decision-log entry lists every register entry with HOLDS / MOVED |

#### §0.7 Decisions this plan auto-adopts (R29(a); each with its break condition)

-   **D-UA-1 — Target and shape.** The cut advances to the full tip c1e83b0b7 in
    ONE staged merge PR (UA-1), followed by one reconciliation PR (UA-2). An
    intermediate cut is rejected: any cut before 3dadff7d0/f1bf78948 (10-01)
    lands the template-probe crash the seven weekly entries refused, and the
    three heaviest refactors (#7632 08-25, #7717 09-03, #7773 09-24, #7787-#7789
    09-29/30) are spread across the range, so no earlier commit isolates them;
    the five commits after 10-01 are small. Break condition: the hosted
    conformance at the merged tip fails a template probe for an upstream-
    attributable reason that cannot be fixed fork-side in one round — then the
    cut is 3dadff7d0's parent is NOT an option either (same crash), so the
    advance is held and recorded, exactly as the weekly entries did.
-   **D-UA-2 — Conflict-class policy.** A: keep both. B: upstream's structure
    wins and the fork mechanism is re-expressed inside it, never upstream hunks
    grafted into the fork's structure (V-3a: the next merge must conflict less,
    not more). C: adopt upstream's mechanism, delete the fork's, keep every fork
    golden and conformance program as the pin that the behavior survived. D:
    none textual; the §0.4 silent cases follow B or C as listed. Break
    condition per file: a class-B re-expression that needs a multi-paragraph
    justification (R17) becomes a class-C deletion with a residue item, or the
    file's fork mechanism is TODO-gated and filed — never a half-merged hunk.
-   **D-UA-3 — Goldens.** The 77 refill-only conflicts take upstream's version
    (`git checkout --theirs`), so upstream's source edits (#7656 renames) are
    kept and the hosted autoupdate re-fills the fork's CHECK lines (R15/R16);
    the 2 fork-source-edited goldens take upstream's version with the fork's
    source edit re-applied by hand and their CHECK lines cleared for refill;
    the upstream-deleted std_initializer_list.carbon is deleted (the fork's
    change was refill-only). Rule for the future: a fork-source-edited golden
    that upstream deletes moves to a fork-named sibling. Break condition: a
    refill-only golden whose `--theirs` version drops a fork-landed split file
    (none found: the two with fork splits are the two source-edited ones).
-   **D-UA-4 — rumdl reflow.** Upstream's `.rumdl.toml` is adopted unchanged;
    one mechanical commit reflows the fork-authored markdown (`uvx prek run
    --all-files` on the merged tree, then `git diff --word-diff` must show only
    whitespace/line-break changes; the ≤2 unfixable MD013 lines are wrapped by
    hand). Rejected: a fork-local MD013 opt-out for `fork/` (a second lint
    regime, R21 parity). Break condition: a reflow that changes a token — that
    file's reflow is reverted and wrapped by hand.
-   **D-UA-5 — Editor grammars.** Upstream's restructured grammars win; `union`
    joins each introducer list and `overload` each modifier list in upstream's
    new positions; tree-sitter entries stay commented (W-091). Break: none.
-   **D-UA-6 — Redeclaration unification.** `TryMergeRedecl<EntityT>` is the
    only merge path. class.cpp's `BuildClassOrUnionDecl` drops its copied
    `MergeClassRedecl`/`MergeOrAddName` and calls `TryMergeRedecl<SemIR::Class>`
    with `LookupOrAddName`'s result, the `is_union` and `decl_kind` facts kept
    around the call. handle_function.cpp runs the overload-set path FIRST: when
    the previous inst (or the loaded import constant) is an `OverloadSetValue`,
    `TryMergeIntoOverloadSet` (D-OV-3 identity scan) handles the declaration and
    `TryMergeRedecl` is not called; a plain function falls through to upstream's
    template. The two facts the fork threaded through `MergeFunctionRedecl`
    (`replace_prev_inst = false` for a set member; `prev_decl_override` carrying
    the API file's facts for a localized member) become two optional fields on
    `MergeRedeclEntityInfo<SemIR::Function>` consumed under `if constexpr
    (IsFunction)` — four lines in merge.cpp, documented as fork-local. Break
    condition: the template's fixed sequence (`CheckFunctionTypeMatches` →
    `DiagnoseIfInvalidRedecl` → `MergeDefinition` → `ReplacePrevInstForMerge`)
    cannot express the api-member override → keep a fork-local
    `MergeOverloadMemberRedecl` for set members only, mirroring the template
    body, with a comment naming the divergence.
-   **D-UA-7 — Thunks.** Upstream's public `CalleeFunctionInfo` (thunk.h) is
    the base; `IsCppThunkRequired(context, callee_info)` gains the fork's fence
    clause; `BuildCppThunk(context, callee_info)` keeps upstream's signature and
    wraps the body through `WrapInBoundaryDiagnostic` when the fence is
    required; `BuildCppCatchingThunk`/`GetOrBuildCppCatchingThunkDecl` take a
    `CalleeFunctionInfo` built from the callee's `ClangDecl`; the `_catch`
    mangling marker and `is_catching` naming stay. The fence predicate is
    refactored to take the callee's `FunctionProtoType` (plus the decl when
    there is one, for `ResolveExceptionSpec`), so `SelfParamKind::
    FunctionPointer` callees are fenced when the pointer's function type is not
    `noexcept` — the terminate semantics (error_handling.md, "the fenced
    boundary") hold for pointer calls too. A catching (`?`) thunk over a
    function-pointer callee is TODO-gated ("catching thunk for a C++ function
    pointer") and filed as a residue. The constant-function-argument plumbing
    (`num_constant_params`, `is_constant_param`, `GetThunkParamIndex`) is
    deleted with D-UA-8. Break condition: upstream's function_ptr goldens show
    the fence (`invoke`/landingpad/`__clang_call_terminate`) — EXPECTED churn,
    accepted; a fenced-thunk golden LOSING its `personality` line is the
    failure (R-5).
-   **D-UA-8 — F8d retirement.** Upstream's Carbon-function → C++-function-
    pointer conversion (#7789) replaces F8d's constant-function-argument
    embedding: delete `ClangDeclSignature::constant_function_args` and its
    hashing/equality (sem_ir/clang_decl.{h,cpp}), `InventConstantFunctionArg`
    and `TryMapFunctionType` (type_mapping.cpp), the `HasConstantFunctionArgs`
    branches (cpp/call.cpp:85, constant.cpp:320, overload_resolution.cpp:264),
    the thunk's constant-param plumbing, and `GetOrExportFunctionDeclToCpp`.
    The W-023 ledger note records the replacement; the F8d conformance programs
    (interop/cpp_thread_carbon_fn_diff.carbon and the other three thread
    programs) are the pins. Break condition: cpp_thread_carbon_fn_diff.carbon
    fails under upstream's mechanism (COMPILE-FAIL on the `std::thread(Carbon::
    Work)` deduction, or DIFF-MISMATCH) — then the embedding is re-added for the
    deduction-only shape with a one-paragraph note, never both paths for one
    shape.
-   **D-UA-9 — Destruction.** Upstream's `Destroy` shape (three associated
    entities; `SubobjectDestroy.Op` synthesized per aggregate; `SelfDestruct`
    calling `Op` then `SubobjectDestroy`) is adopted whole: the fork's
    `MakeDestroyOpBody(format)` and one-entry `BuildDestroyWitness(format)` are
    deleted in favor of `BuildCarbonDestroyWitness(format)`; the fork's
    `CanDestroyClass(…, query_is_symbolic)` threading, `HasClassKeyedImpl`
    (D-SL-16: declared impls win), `HasUserDestroyImpl` (export/union
    predicate), `IsTriviallyDestructible` with its `CustomLayoutType` arm,
    `HasNonTrivialUserCopyImpl`, `LookupChoiceCopyWitness`,
    `LookupUnionUnformedInitWitness` and the return-slot
    `BuildPrimitiveCopyWitness` survive on `SpecificInterface` parameters.
    Break condition: the slice/buf lower golden or stdlib/slices_heap_buf
    .carbon no longer shows exactly one `free` per `Buf` (double free through
    `SelfDestruct` + a field walk, or none) — fixed at the root before merge.
-   **D-UA-10 — Specific resolution.** Upstream's in-place value block (#7717)
    replaces the fork's S3b incremental publication; the `publish_block_id`
    parameter, the pre-sized placeholder in `ResolveSpecificDefinition` and the
    two loud CHECKs in `GetConstantInSpecific` go. Upstream's TODO ("distinguish
    parts not yet reached from `NotConstant`") is the acknowledged gap the
    fork's CHECK guarded; V-3a says follow upstream. Break condition: a
    generic-choice golden (check/choice/generic_*.carbon, lower/choice/
    generic_*.carbon — the S3b family) crashing, or changing structurally rather
    than by `.loc` renumbering, in the fill — then the forward-reference CHECK
    is re-added as a fork-local assertion only (no publish plumbing).
-   **D-UA-11 — `GetValue`.** Keep both: the fork's `TryEmitGlobalLetValue`
    early return for non-concrete constants (W-069) runs before upstream's
    `require_value`-conditional CHECK and `nullptr` return. Break: none.
-   **D-UA-12 — Un-SKIPs are UA-2's.** No conformance program changes status in
    UA-1 (the merge is judged by non-regression alone); UA-2 probes the §0.6
    candidates by un-SKIP commits on its branch, one hosted conformance run per
    round, reverting any that fail (R10/R16(b) are satisfied: a SKIP is removed
    only when its cited blocker demonstrably landed).
-   **D-UA-13 — Weekly Routine baseline.** After UA-1 lands, the weekly check's
    "cut" is c1e83b0b7 and its deferred set is empty; the Routine's prompt needs
    no edit (it measures from `git merge-base`), but ORCHESTRATION's cut line
    and the decision-log entry (§8.3) record the new base.
-   **D-UA-14 — Arbiter of the advance.** The hosted conformance of the MERGED
    fork toolchain is the gate; the mirrored-nightly A/B (§8.2) is diagnostic,
    attributing a failure to upstream or to the merge, never a substitute.
-   **D-UA-15 — Residues filed, not fixed, in UA-1:** the function-pointer
    catching-thunk gate (D-UA-7), any fork golden whose fill shows an upstream-
    intended diagnostic the fork's design did not anticipate (R-11), and the
    F8d retirement note. Each gets a W-item at UA-2 with file:line evidence.

#### §0.8 The split: UA-1 one staged merge PR, UA-2 one reconciliation PR

A git merge is atomic: "the non-overlapping 90%" cannot land as a PR while
the twenty conflicting sources are unresolved, because the tree would not
build (§0.4 items 1-7 are build breaks). So the three slices the brief
sketched are the three COMMIT groups inside UA-1 (merge with every textual
and semantic resolution; the mechanical reflow; the hosted fills and the
fixes they expose), and the separable work — status changes, ledger and
gap-analysis moves, pins for upstream-discharged items — is UA-2, which is
judged by its own scoreboard delta. R29(b): one PR per landed step; the
landed steps are "trunk at c1e83b0b7" and "trunk reconciled to it".

### §1 Design: how each conflict class is merged

1.  **Textual resolution order (sources first):** core_identifier.def →
    sem_ir/function.h (`Callee`) → sem_ir/generic.cpp, generic.cpp, eval.{h,cpp}
    (D-UA-10, take theirs) → custom_witness.cpp (D-UA-9) → handle_class.cpp +
    class.cpp, handle_function.cpp + merge.{h,cpp} (D-UA-6) → cpp/thunk.{h,cpp},
    cpp/import.{h,cpp}, cpp/export.cpp (+export.h, type_mapping.cpp,
    constant.cpp, overload_resolution.cpp, cpp/call.cpp, sem_ir/clang_decl.
    {h,cpp}: D-UA-7/8) → the eight class-A files → words.md and the five
    grammars (D-UA-5) → goldens (D-UA-3).
2.  **Re-expression discipline (class B):** each fork mechanism is located by
    its decision-log name (D-OV-n, D-EH-n, D-UN-n, D-SL-n, W-069, W-075) and
    re-implemented against upstream's new types with the SAME observable
    behavior, which the fork's existing goldens and programs pin; no fork test
    is edited to make a re-expression pass (R16(b)). Where behavior must change
    (D-UA-7's function-pointer fence; the new `SubobjectDestroy` entries in
    every Destroy witness), the change is upstream-intended and the fill is
    its evidence.
3.  **Deletion discipline (class C):** the deleted fork code is named in the
    merge commit message with the upstream commit that supersedes it, and the
    ledger note (W-023, W-069/S3b landing notes) gains a dated "superseded by
    upstream #n" line at UA-2.
4.  **Compile before fill:** the first hosted run is `compile` (18 min), not
    `autoupdate`, because the container cannot build and §0.4 predicts build
    breaks; a red compile returns to the implementer with the error text,
    never to a fill.

### §2 Implementation spec (file by file)

#### §2.1 Class A files (keep both; verify the enumerated switches)

-   **check/call.cpp:** both inserted blocks stay in the order fork-then-
    upstream after `PerformCallToFunction`; `PerformCall`'s `CARBON_KIND_SWITCH`
    carries `CalleeCppFunctionPointer` (upstream :408) AND `CalleeOverloadSet`
    (fork :756); upstream's new `TryGetCalleeAsBoundMethod` (sem_ir/function.h)
    is used where the fork's `GetCalleeAsFunction` commit path re-wraps a
    `BoundMethod` (D-OV-4) only if the fill shows a divergence — otherwise the
    fork's `BuildNameRef` + `BoundMethod` commit stays.
-   **check/convert.cpp, handle_pattern_list.cpp, import_ref.cpp:** both
    include lines, sorted.
-   **check/core_identifier.def:** both identifier sets, alphabetical; the
    `#7660` registered-kind check does not apply here.
-   **check/member_access.cpp, sem_ir/expr_info.cpp, sem_ir/stringify.cpp,
    sem_ir/function.h:** both arms/overloads; the `Callee` alias lists six
    alternatives alphabetically.
-   **check/function.{cpp,h}:** upstream's `return_form`/`param_kinds` fields
    and the `AddReturnPattern` call join the fork's `FunctionDeclArgs` additions;
    `MakeFunctionSignature` keeps the fork's return-slot handling for generated
    copy functions (W-075).
-   **lower/function_context.cpp:** per D-UA-11.
-   **lower/type.cpp:** upstream's `requires` list with `OverloadSetType` added
    (and `FacetType` absent, #7734).

#### §2.2 check/custom_witness.{h,cpp} (D-UA-9)

-   `CanDestroyClass(Context&, LocId, ClassType, const CompleteTypeInfo&,
    SpecificInterface query_specific_interface, bool is_partial, bool
    query_is_symbolic)`: upstream's parameter type, the fork's extra parameter;
    both call sites in `CanDestroyType` pass `query_self_const_id.is_symbolic()`.
    The body keeps the fork's D-SL-16 clause (`HasClassKeyedImpl(…, Destroy,
    /*outside_core_only=*/false)` → `NoDestroy`, a declared impl wins) and the
    B2a symbolic deferral.
-   Delete the fork's `MakeDestroyOpBody`, `MakeDestroyOpFunction(…, format)`
    and `BuildDestroyWitness(…, format)`; route `LookupDestroyWitness` and
    `BuildTrivialDestroyWitness` through upstream's `BuildCarbonDestroyWitness`.
    Upstream's `IsBuiltinWithTrivialDestruction` (#7847) and the fork's
    `IsTriviallyDestructible` coexist: the former feeds `CanDestroyType`, the
    latter the union field rule and the export predicate; a `CustomLayoutType`
    arm is added to upstream's `MakeSubobjectDestroyOpBody` only if the fill
    reaches its `CARBON_FATAL("Unexpected type …")` for a union (a union's
    fields are trivially destructible by D-UN-2, so the `Trivial` format should
    short-circuit first — pre-registered expectation).
-   `LookupChoiceCopyWitness`, `LookupUnionUnformedInitWitness`,
    `BuildPrimitiveCopyWitness`, `LookupCustomWitness`: `SpecificInterface`
    parameters; `MakeBuiltinOperatorFunction` callers pass upstream's new
    `loc_id` first argument and drop the fork's `parent_scope_id` default
    (upstream canonicalizes generated functions, #7729 — the fork's
    mangling-hint scope is subsumed; verify the fork's `_C…` symbol goldens for
    choice copy/destroy move only by the fill's renaming, R-2).
-   custom_witness.h: the three fork declarations (`HasTrivialClassShapeForExport`,
    `IsTriviallyDestructible`, `HasNonTrivialUserCopyImpl`) stay; the shared
    declarations take upstream's signatures.

#### §2.3 Redeclarations (D-UA-6)

-   **check/handle_class.cpp:** resolve to the fork side (the body lives in
    class.cpp); upstream's `friend` handlers (#7889) are already merged cleanly.
-   **check/class.cpp `BuildClassOrUnionDecl`:** replace the copied
    `MergeClassRedecl`/`MergeOrAddName` with upstream's sequence from the new
    `BuildClassDecl` (`LookupOrAddName` → `TryMergeRedecl<SemIR::Class>` →
    `is_new_class` branch → `ReplaceInstBeforeConstantUse` → `SetClassSelfType`),
    parameterized by `decl_kind` for the modifier limits and `is_union` on the
    `ClassFields`. `DiagnoseIfGenericMissingExplicitParameters` (upstream) is
    called for unions too (D-UN-3 gates generic unions later, at definition).
-   **check/handle_function.cpp:** delete the fork's `MergeFunctionRedecl`;
    keep `DiagnoseOverloadMarkerMismatch`, `MakeApiMemberRedeclInfo`,
    `GetImportedOverloadSetSource`, `TryMergeIntoOverloadSet`,
    `IsEntryPointResultReturnType`, `DiagnoseOverloadInInterfaceOrImpl`,
    `DiagnoseOverloadGates`. In `BuildFunctionDecl`, after upstream's
    `CheckDefaults` and `DiagnosePositionalParams`: if the name's previous inst
    (or its loaded import constant) is an `OverloadSetValue`, or the new
    declaration carries the `overload` modifier, run the set path
    (`TryMergeIntoOverloadSet`, which performs the member merge through the
    template with the two optional fields) and skip the plain `TryMergeRedecl`;
    otherwise call upstream's `TryMergeRedecl(context, name_context,
    std::nullopt, MergeRedeclEntityInfo<SemIR::Function>{…}, is_definition)`
    unchanged.
-   **check/merge.{h,cpp}:** `MergeRedeclEntityInfo<SemIR::Function>` gains
    `bool replace_prev_inst_on_import = true;` and `std::optional<RedeclInfo>
    prev_decl_override;`; `TryMergeRedecl`'s function branch uses them at the
    `DiagnoseIfInvalidRedecl` call and the `replace_prev_inst` computation.
    The fork's `CheckRedeclExplicitParamsAfterSelfMatch` (merge.h:110) stays.

#### §2.4 Thunks, import, export (D-UA-7, D-UA-8)

-   **sem_ir/clang_decl.{h,cpp}:** delete `constant_function_args`,
    `HasConstantFunctionArgs`, `GetConstantFunctionArg` and their hash/equality
    lines; upstream's `ClangFunctionPointerTypeInfo`/`LookupId` arrive clean.
-   **check/cpp/type_mapping.{h,cpp}:** delete `TryMapFunctionType`,
    `InventConstantFunctionArg`, `LookupCppClassTemplate`'s F8d-only uses if
    any remain (keep the helper if F8c's specialization-global path uses it —
    `grep -n LookupCppClassTemplate` decides), the `case SemIR::FunctionType::
    Kind:` at :437 and the FormInfo branch at :586-594; keep the fork's
    `LookupCppDecl` refactor (used by `LookupCppType` and EH-B's
    `Carbon::expected` lookup).
-   **check/cpp/overload_resolution.cpp, constant.cpp, cpp/call.cpp:** delete
    the constant-function-arg branches (:264, :320, :85); keep EH-B's
    `PerformCppThunkCall` catching selection and F8c's global dedup.
-   **check/cpp/export.{h,cpp}:** take upstream's hunk (`GetOrExportFunctionToCpp`,
    `ExportFunctionToCppPointerConversion`); delete the fork's
    `GetOrExportFunctionDeclToCpp` and its export.h declaration; the fork's
    other six hunks (union `TagTypeKind::Union`, `IsTriviallyCopyableForExport`
    destructor-thunk predicate, `BuildCarbonToCarbonThunk`'s `overload_index`
    (D-OV-17), the `Carbon::expected` return mapping, the UN-2 return-address
    thunk, `HasAnyAbstractMethods`) merged cleanly and stay. Note #7897: thunk
    names now come from `GetIdentifier`; the fork's `extra_name` suffix for
    `_catch` thunks is unaffected.
-   **check/cpp/thunk.{h,cpp}, import.{h,cpp}:** per D-UA-7. Concretely:
    `IsCppThunkFenceRequired(Context&, const clang::FunctionProtoType*, const
    clang::FunctionDecl* decl_or_null)`; `IsCppThunkRequired(context,
    callee_info)` returns true when `IsCppThunkFenceRequired(callee_info.
    function_type, callee_info.decl)`; `BuildThunkBody(…, callee_info)` wraps
    through `WrapInBoundaryDiagnostic` under the same predicate (the message
    names `callee_info.decl_name` when `decl` is null); `BuildCatchingThunkBody`
    reuses upstream's `BuildCalleeCallExpr`/`BuildReturnValueStore`; the
    `GetThunkReturnParamIndex` arithmetic becomes upstream's `num_callee_params
    -   callee_param_to_carbon_param_offset()`. In `ImportFunctionDecl`, after
        upstream's `DefineAsThunkCall`, the fork's check stays: if the callee is
        fence-required and the imported function has no C++ thunk attached
        (`!imported_function.cpp_thunk_decl_id().has_value()` or the equivalent
        upstream accessor), `context.TODO(loc_id, "Unsupported: fenced thunk for
        potentially-throwing C++ function could not be built")` — the
        fail_fence_thunk_unbuildable.carbon pin stays red-line.
-   **check/cpp/generate_ast.cpp, impl_lookup.cpp:** clean merges; verify the
    OV-3 `OverloadSetValue` arm in `MapInstIdToClangDeclOrType` coexists with
    upstream's #7789 changes to the same function (upstream -46 lines there).

#### §2.5 Specifics (D-UA-10)

`git checkout --theirs` for check/eval.{h,cpp}, check/generic.cpp,
sem_ir/generic.cpp, then re-apply the fork's NON-conflicting hunks in those
files (eval.cpp: the SL-1 runtime-only builtin arms at :2648-2651 and the
choice-payload eval hooks; eval.h: nothing else; generic.cpp: the S3b
`ResolveSpecificDefinition` comment block goes with the mechanism). The
fork's generic-choice goldens are the pins (R-8).

#### §2.6 Grammars and words.md (D-UA-5)

Upstream's lists with `union` in each introducer alternation
(`\b(adapt|alias|choice|class|constraint|fn|import|inline|interface|let|
library|match_first|namespace|observe|require|union|var)\b`) and `overload`
in each `storage.modifier` alternation; vim: `carbonClassMethodDeclarationMod
… impl overload` and `carbonUnionDeclaration` kept; keywords.carbon sample
lines extended; highlights.scm keeps the two commented fork lines in
upstream's sorted positions; words.md keyword list gains `union` between
`type` and `typeof`, and `overload` between `override` and `package`.

#### §2.7 Goldens (D-UA-3)

`git checkout --theirs -- <77 refill-only files>`; `git rm` std_initializer
_list.carbon; for check/let/fail_generic_import.carbon take theirs then rename
the split `// --- fail_implicit.impl.carbon` to `// --- implicit.impl.carbon`
and clear its CHECK lines; for lower/var/import.carbon take theirs then
re-add `fn X() -> i32 { return x; }` (after the `import library "import"` of
the `use.carbon` split, where the fork had it) and clear the CHECK lines
below it. The 237 fork-new and 94 fork-modified goldens are not touched by
hand; the fill moves them.

#### §2.8 Non-toolchain files

-   `.rumdl.toml`, `.pre-commit-config.yaml` (rumdl v0.2.58): upstream's.
-   `.github/workflows/*`: upstream's hunks merge cleanly; the fork's
    `if: github.repository == 'carbon-language/carbon-lang'` guards
    (nightly_release.yaml:40, check_dependent_pr.yaml:26) must survive — verify
    by grep after the merge. fork_hosted.yaml's `build-setup-common` now
    installs LLVM 21.1.8 (upstream's action change); no fork edit needed.
-   `AGENTS.md`, `.agents/skills/*`: upstream's.
-   `toolchain/install/BUILD`: upstream's `load("//bazel/cc_toolchains:
    make_include_copts.bzl", …)` plus the fork's `support_hdrs` target.

### §3 Commit structure (UA-1; UA-2 in §8.5)

1.  **Merge commit** `Merge upstream trunk c1e83b0b7 into the fork (183
    commits since 631f8fb)` — every textual AND semantic resolution of §2, so
    the merge commit itself is meant to build; its message lists the class-C
    deletions with the superseding upstream commits (D-UA-8, D-UA-10) and the
    class-B re-expressions by decision id.
2.  **Reflow commit** `Reflow fork markdown to upstream's MD013 line length` —
    mechanical, `uvx prek run --all-files` output only (D-UA-4).
3.  **Hosted fill commit(s)** — authored by the workflow ("Autoupdate testdata
    goldens on a GitHub-hosted runner"); expect pass 1 (fill) and pass 2
    (`.loc` convergence), R26.
4.  **Fix commits** — one per defect the compile or fill exposes, each message
    naming the root cause and the §0.4/§7 item it confirms or refutes.
5.  **Scoreboard commit** — authored by the workflow (conformance mode).
6.  **Discharge commit** `Upstream advance 2026-10: cut 631f8fb → c1e83b0b7` —
    decision-log entry, ORCHESTRATION stamp, ledger notes (§8.3).

Author/committer rules: `git -c user.name=jmann345 -c
user.email=jerrymannstan@gmail.com commit --author="jmann345
<jerrymannstan@gmail.com>"` with `GIT_COMMITTER_NAME=Claude
GIT_COMMITTER_EMAIL=noreply@anthropic.com` and the standing trailers.

### §4 Testdata expectations (R16: no hand-written goldens)

-   **Fill magnitude:** upstream moved 1094 goldens; the fork carries 237 new
    and 94 modified goldens whose CHECK lines were produced by the pre-merge
    compiler. Expect the pass-1 fill to touch most of the fork's 331 goldens
    (upstream's `Destroy` reshaping alone adds `SubobjectDestroy`/`SelfDestruct`
    entries to every `destroy` dump; #7768/#7804 change diagnostic type text;
    #7897 changes exported C++ names only for keyword-named functions — none in
    fork tests) plus the 77 taken-theirs conflicts (which re-acquire the fork's
    thunk/`Cpp.Exception`/overload lines). A fill touching a golden with NO
    fork mechanism and NO upstream change in its directory is the R-12
    falsifier.
-   **Pre-registered shapes:** fenced-thunk goldens keep `personality ptr
    @__gxx_personality_v0` and `__clang_call_terminate` (30 lower goldens carry
    the former today — R-5); upstream's function_ptr goldens GAIN them (D-UA-7);
    slice/buf lower golden keeps exactly one `free` per `Buf` (R-3); the OV
    mangling `:overload<N>` and `_CF__carbon_thunk:overload<N>` lines are
    unchanged; the S3b generic-choice goldens move by `.loc` only (R-8);
    fail_fence_thunk_unbuildable.carbon stays a `fail_` with the SemanticsTodo.
-   **Autoupdate script:** upstream's `--build-mode` and "tests that would
    still fail" report (#7809/#7877) are informational; fork_hosted.yaml's grep
    for `Stack dump:|CHECK failure|CARBON_FATAL` stays the crash gate.

### §5 Conformance

-   **Bar (UA-1):** exactly `126 PASS / 0 FAIL / 23 SKIP over 149`, 47/56
    bullets — no program changes status in UA-1 (D-UA-12). Any program leaving
    PASS is a regression to be root-caused and fixed before merge; a fix that
    edits a PROGRAM is allowed only when the edit removes a construct upstream
    now rejects by design (R-11's redundant redeclaration), recorded in the
    decision-log entry with the upstream commit.
-   **Expected UA-2 delta** (each a probe, each reverted on failure): SKIP → PASS
    candidates generics/templates_dependent_member.carbon, interop/
    cpp_template_symbolic_arg.carbon, interop/cpp_template_on_carbon_generic
    .carbon, interop/inherit_multiple_bases.carbon — up to **130 / 0 / 19 over
    149**; bullets 47 → up to 48 (row 54 "importing C++ templates, instantiating
    on Carbon types" flips if both template probes pass; row 52 stays PARTIAL
    — dependent conversions still have residue). No new program in UA-1; UA-2
    adds the W-108 pin program/golden (§0.6) if the field-destroy claim holds.
-   **R7:** no bullet text changes; `runner.py --self-test` at every commit.

### §6 Churn inventory

-   Sources resolved by hand: 20 toolchain files (§0.3) + 6 class-C/semantic
    files that merged cleanly but lose code (export.h, type_mapping.{h,cpp},
    constant.cpp, overload_resolution.cpp, cpp/call.cpp, sem_ir/clang_decl.
    {h,cpp}) + merge.{h,cpp} (D-UA-6 fields) + class.cpp (D-UA-6 port).
-   Goldens: 77 `--theirs`, 2 hand-merged, 1 deleted; ~331 fork goldens
    refilled; upstream's 1094 arrive as-is.
-   Markdown: 34 fork-authored files reflowed (605 fixes), ≤2 hand-wrapped.
-   Deleted fork code (class C): F8d embedding (~150 lines across six files),
    S3b publication (~90 lines across four files), `MergeFunctionRedecl`/
    `MergeClassRedecl`/`MergeOrAddName` copies (~120 lines), fork
    `MakeDestroyOpBody`/`BuildDestroyWitness` (~60 lines).
-   Diagnostics: no new kinds in UA-1 except the D-UA-7 TODO string (a
    `SemanticsTodo`, not a kind).

### §7 Risks and rejected alternatives (each with its falsifier)

-   **R-1 Build breaks the dry run cannot see** (§0.4 items 1-7, 9). Falsifier:
    the first hosted `compile` run. Mitigation: §2 resolves each before the
    push; the implementer greps §8.4 before pushing.
-   **R-2 Destroy witness reshaping changes fork symbols/goldens structurally**
    (`SubobjectDestroy`/`SelfDestruct` functions appear for every type the fork
    destroys; #7729 canonicalizes generated functions, so the fork's
    mangling-hint scope is gone). Falsifier: a fork lower golden's choice-copy
    or destroy `define` disappearing (not renaming) in the fill.
-   **R-3 Double or missing `free` for `Core.Buf`** (D-SL-16's declared-impl
    selection composed with `SelfDestruct` → `Op` + field walk). Falsifier:
    stdlib/slices_heap_buf.carbon status and the buf lower golden's `free`
    count; fix at the root (the selection or the field walk), never the test.
-   **R-4 F8d retirement breaks `std::thread(Carbon::Work)`** (upstream maps the
    argument to a `_Nonnull` function-pointer type; `std::thread`'s constructor
    template must deduce from it). Falsifier: interop/cpp_thread_carbon_fn_diff
    .carbon; break condition in D-UA-8.
-   **R-5 A fork mechanism silently disabled by a renamed hook.** The three
    places this can happen without a build error: (a) `IsCppThunkRequired`
    losing the fence clause (every throwing callee called directly; terminate
    semantics gone, zero diagnostics) — falsifier: the 30 `personality` goldens
    and error_handling/cpp_exception_*.carbon programs; (b) the overload-set
    pre-step not reached because `BuildFunctionDecl`'s new `TryMergeRedecl`
    call runs first (a second `overload fn F` becomes a redeclaration error) —
    falsifier: check/overload/*.carbon goldens and functions/overloading_*
    programs; (c) `HasClassKeyedImpl` no longer consulted by upstream's
    `CanDestroyClass` (a `Buf` leaks again) — falsifier: R-3's. Each is a
    grep in §8.4 plus a fill/scoreboard pin.
-   **R-6 `MergeRedeclEntityInfo` fields rejected by review as fork creep in
    merge.cpp.** Alternative (D-UA-6 break): a fork-local member-merge function
    for set members only. Falsifier: reviewer finding citing R17.
-   **R-7 Union declarations regress under the ported `TryMergeRedecl<Class>`**
    (`is_union` lost on redeclaration; `union`/`class` cross-redeclaration not
    diagnosed). Falsifier: check/union/redecl*.carbon goldens.
-   **R-8 Generic-choice specifics (S3b) misbehave under upstream's in-place
    initialization** (the recursion the fork's placeholder guarded now reads
    `NotConstant`). Falsifier: S3b goldens crash or change structurally; break
    condition in D-UA-10.
-   **R-9 rumdl reflow alters content** (tables, nested lists, the decision
    log's 5730 lines). Falsifier: `git diff --word-diff` showing a token
    change; `uvx rumdl check` not at zero after `fmt`.
-   **R-10 x-macro ordering tests** (typed-node categorization, kind.def
    registration #7660, keyword sort). Falsifier: gate failures in parse/lex/
    diagnostics unit tests.
-   **R-11 Upstream's new diagnostics hit fork tests and programs** (#7695
    redundant impl-file redeclarations; #7651 positional-parameter diagnostics
    on `fn F;` shapes; #7813 facet changes on EH-A's "non-`type` facet carries
    only declared interfaces" rule). Falsifier: new STDERR lines in the fill on
    fork goldens, or a COMPILE-FAIL in conformance. Disposition: upstream-
    intended → adopt (golden) or remove the redundant construct (program) with
    the commit cited; unintended → fork-side fix.
-   **R-12 Fill churn beyond the explained set / non-converging pass 2.**
    Falsifier: a pass-2 diff with structural changes (R26 says stop and
    diagnose).
-   **R-13 The template probes still crash at tip.** Falsifier: the A/B (§8.2)
    or the hosted conformance; disposition D-UA-1.
-   **R-14 Triviality reclassification (#7846/#7847) moves the union field rule
    or F8b's export triviality** (an exported class gaining/losing its C++
    destructor thunk; `std::atomic<CarbonClass>` no longer trivially copyable).
    Falsifier: interop/cpp_threading_atomics.carbon and the union goldens.
-   **R-15 clang 21 toolchain on the hosted runner** (build-setup-common now
    installs 21.1.8 on ubuntu-22.04; upstream CI uses it, so the cache keys
    match). Falsifier: the compile run's setup step.
-   **R-16 Upstream's `TryGetCalleeAsBoundMethod` and splice-stepping (#7700)
    interact with the overload probe's bound-receiver commit** (D-OV-4 re-wraps
    a `BoundMethod` by hand). Falsifier: check/overload/method*.carbon goldens.
-   **Rejected alternatives:** (i) chronological two-step merge (lands a known
    crash, §0.8); (ii) keeping both F8d and #7789 (two paths for one shape; the
    duplicate `case` makes it ill-formed anyway); (iii) fork-local MD013
    opt-out (R21 parity); (iv) resolving goldens by hand-merging CHECK lines
    (R16(a) forbids it; autoupdate is the only author of CHECK lines).

### §8 Verification and discharge

#### §8.1 Hosted sequence (R28; GitHub-hosted only; dispatched by the orchestrator)

1.  Push the staging branch with commits 1-2 of §3.
2.  `Fork: hosted verification` mode `compile` (~18 min). Red → fix commits
    until green; every red is a §0.4/§7 confirmation recorded in the commit.
3.  Mode `autoupdate` (~13 min; fails on any stack dump). Expect a large pass-1
    fill pushed back to the branch; dispatch a second `autoupdate` and expect
    a `.loc`-only pass 2 (or "No testdata changes"). A pass-2 structural diff
    stops the line (R26).
4.  Mode `gate` (~25 min: `uvx prek run --all-files` + `bazel test
    //toolchain/...`), dispatched only after the last autoupdate push (a
    queued run pins its SHA).
5.  Mode `conformance` (~20 min): commits scoreboard.json; the bar is §5. Every
    non-PASS outside the 23 SKIPs is explained AND fixed (or program-edited
    under R-11's rule) before merge.
6.  Merge into trunk with a merge commit (never squash); stamp ORCHESTRATION;
    the UA-2 branch is cut from the new trunk.

#### §8.2 A/B probe plan for the two template programs

-   **Instrument:** `.github/workflows/fork_mirror_nightly.yaml` (workflow_
    dispatch, or a push to `claude/**` touching the workflow or
    fork/conformance/arbiter-request.txt — so a request-file bump on the
    staging branch is a legitimate trigger) runs on ubuntu-22.04 with the
    repository `GITHUB_TOKEN`: it downloads the latest upstream release's
    `carbon_toolchain-*.tar.gz` (`gh release list --repository carbon-language/
    carbon-lang --limit 1`) and publishes it as the fork prerelease
    `arbiter-<TAG>` (uploading with `--clobber` if the tag exists). Not
    dispatched by this plan; the orchestrator runs it when a nightly ≥
    `v0.0.0-0.nightly.2026.10.02` exists (the fixes landed 10-01).
-   **In the container:** `gh api repositories/jmann345/carbon-lang/releases/tags/
    arbiter-<TAG>` → asset id → download with `gh api -H "Accept: application/
    octet-stream" repositories/jmann345/carbon-lang/releases/assets/<id> > tc.tar.gz`
    (the fork repository IS reachable from this session; the fork's release
    list already shows `arbiter-v0.0.0-0.nightly.2026.09.28`), extract under
    /home/user/arbiter/, then `python3 fork/conformance/runner.py --toolchain
    <dir>/bin/carbon --filter generics/templates_ --out <scratch>/ab-<tag>` and
    the same against `/home/user/arbiter/carbon_toolchain-0.0.0-0.nightly.2026.
    07.19/bin/carbon` (both PASS at the cut; the baseline).
-   **Reading the matrix:** pure-upstream PASS + merged-fork PASS → the cut
    advances; pure-upstream PASS + merged-fork FAIL → a merge defect (fix in
    UA-1); pure-upstream FAIL + merged-fork FAIL with the same signature → an
    upstream bug (D-UA-1's break condition; record the signature as the
    weekly entries did; filing upstream remains the owner's call); pure-
    upstream FAIL + merged-fork PASS → a fork mechanism masks an upstream bug
    (record in the decision-log entry; the advance proceeds, since the fork's
    arbiter is the merged toolchain, D-UA-14).

#### §8.3 Discharge (UA-1)

-   **Decision-log entry** "Upstream advance 2026-10: cut 631f8fb → c1e83b0b7
    (2026-10-NN)" placed above the 10-05 weekly entry, recording: the §0.1
    numbers; the conflict classification as landed (every class-B
    re-expression and class-C deletion by decision id, with the upstream
    commit); the A/B matrix reading; the fill statistics (files per pass); the
    scoreboard at fixpoint quoted from scoreboard.json; the divergence-risk
    register review (each of the ten register blocks' entries: HOLDS, or MOVED
    with the upstream commit); the residues filed (D-UA-15); the review fold.
-   **ORCHESTRATION.md:** the header's "upstream advance" sentence becomes the
    outcome; a new "Upstream advance (2026-10)" paragraph replaces the "Weekly
    upstream-merge outcome" slot's cut statement (cut c1e83b0b7, deferred set
    empty); the Branches table gains the staging branch as MERGED; the
    Toolchains list gains the newest mirrored arbiter.
-   **Weekly Routine** (`Weekly upstream-merge check (carbon fork)`, cron `0 14
    -   1`, next 2026-10-12): no prompt edit (D-UA-13); its first post-advance
        firing should report a small deferred set and no fork-modified overlap
        beyond the usual check-core files.
-   **Ledger:** W-001 gains a landed note (this flow); W-023 the superseded-
    mechanism note; the S3b/W-069 notes the D-UA-10 line; new residues per
    D-UA-15.
-   **Gap analysis:** header unchanged by UA-1; rows 52/54/40/43 re-cited in
    UA-2 (§0.6).

#### §8.4 Verification greps (before the first push, and at discharge)

-   `grep -rn 'constant_function_args\|HasConstantFunctionArgs\|InventConstantFunctionArg\|GetOrExportFunctionDeclToCpp\|TryMapFunctionType' toolchain` → empty (D-UA-8).
-   `grep -rn 'publish_block_id\|MergeFunctionRedecl\|MergeClassRedecl\|MergeOrAddName\|MakeDestroyOpBody' toolchain/check` → empty (D-UA-6/9/10).
-   `grep -rn 'CalleeCppFunctionPointer' toolchain --include=*.cpp -l` and `grep -rn 'CalleeOverloadSet' toolchain --include=*.cpp -l` → the same file set (§0.4 item 5).
-   `grep -n 'IsCppThunkFenceRequired' toolchain/check/cpp/thunk.cpp` → called from `IsCppThunkRequired` AND `BuildThunkBody` (R-5a).
-   `grep -n 'TryMergeIntoOverloadSet\|TryMergeRedecl' toolchain/check/handle_function.cpp` → the set path precedes the template call (R-5b).
-   `grep -n 'HasClassKeyedImpl' toolchain/check/custom_witness.cpp` → called inside `CanDestroyClass` (R-5c).
-   `grep -n "github.repository == 'carbon-language/carbon-lang'" .github/workflows/nightly_release.yaml .github/workflows/check_dependent_pr.yaml` → both present.
-   `grep -c 'personality ptr @__gxx_personality_v0' -r toolchain/lower/testdata | grep -v ':0' | wc -l` → ≥ 30 after the fill (R-5a).
-   `uvx prek run --all-files` → clean; `python3 fork/conformance/runner.py --self-test` → OK.

#### §8.5 UA-2 (reconciliation PR) in one paragraph

Branch off the new trunk; per §0.6: un-SKIP probe commits for the four
candidates (one hosted conformance per round; revert failures with the
measured diagnostic written into the SKIP line, R10); the W-108 pin golden
(+ lower twin) and, if green, the W-108 discharge; ledger notes for W-023,
W-014, W-043, W-046, W-037, W-030, W-083, W-091, W-065; gap rows 40/43/52/54/
89 re-cited; residues from D-UA-15 filed with file:line; the decision-log
entry "Upstream reconciliation 2026-10 (UA-2)". Bar: non-regression from the
UA-1 floor; expected up to 130 / 0 / 19 over 149 (§5). Two plan reviews are
not repeated for UA-2 (R29(c): its plan is this section); one implementation
review once hosted verification is green.

### Hand-off notes for the implementer

1.  **Setup.** Work only in `/home/user/carbon-upstream` on
    `claude/carbon-fork-0-1-upstream-advance` (HEAD 923c2f2af; `upstream-trunk`
    = c1e83b0b7). Never touch `/home/user/carbon-lang`, `/home/user/carbon-sl2`
    or `/home/user/carbon-trunk`. Do not dispatch any workflow (the
    orchestrator does; R28). The container cannot build: your evidence before
    the push is `git`, reading, and the §8.4 greps.
2.  **Merge mechanics.** `git merge --no-ff upstream-trunk` (expect the 105
    conflicts of §0.3; `git status --porcelain | grep -E '^(UU|UD)'` lists
    them). Resolve sources in the §1 order with `git merge-file`-free hand
    edits (open each file; the markers are `<<<<<<< HEAD` fork / `>>>>>>>
    upstream-trunk` upstream). Goldens: `git checkout --theirs -- $(git diff
    --name-only --diff-filter=U | grep testdata | grep -v
    'let/fail_generic_import\|lower/testdata/var/import')`, then the two
    hand-merges of §2.7, then `git rm toolchain/lower/testdata/interop/cpp/
    std_initializer_list.carbon`. Then the §0.4 semantic edits in the files
    that merged cleanly (export.h, type_mapping.{h,cpp}, constant.cpp,
    overload_resolution.cpp, cpp/call.cpp, clang_decl.{h,cpp}, merge.{h,cpp},
    class.cpp, cpp/call.cpp and eval.cpp `Callee` switches). Run the §8.4
    greps. `uvx prek run --files <every touched non-testdata file>` to a
    fixpoint (clang-format 21.1.8 is the pin; the container's distro
    clang-format is NOT the arbiter, R18 — prek fetches the pinned one).
    Commit the merge with the §3 author/committer rules and trailers.
3.  **Reflow.** `uvx prek run --all-files` (rumdl now reflows); inspect `git
    diff --word-diff --stat` and spot-check the decision log's tables; commit.
4.  **Push** `git push -u origin claude/carbon-fork-0-1-upstream-advance` and
    hand the orchestrator the list of §7 falsifiers to watch in the compile
    log first (§0.4 items), then in the fill.
5.  **Traps.** (a) `CARBON_KIND_SWITCH` over `Callee` in eval.cpp:2897 and
    cpp/call.cpp:84 are upstream's — add the `CalleeOverloadSet` arm there, do
    not move the fork's arms. (b) upstream's `MakeBuiltinOperatorFunction` has
    a `loc_id` first parameter now; every fork call site (choice copy, union
    unformed-init, primitive copy) must pass one. (c) `GetOrExportFunctionToCpp`
    returns `clang::NamedDecl*` (a `FunctionTemplateDecl` for generics) — the
    OV-3 arm in generate_ast.cpp casts to `FunctionDecl` per member; keep the
    `dyn_cast` and skip null. (d) The fork's `fail_fence_thunk_unbuildable
    .carbon` pin depends on the fence check surviving `DefineAsThunkCall`; if
    upstream's path now diagnoses the unbuildable thunk itself, the fork's
    TODO becomes unreachable — then delete the TODO AND keep the pin, letting
    the fill show upstream's diagnostic (record it). (e) Do not "fix" a fork
    golden by editing CHECK lines (R16(a)); clear them and let the fill write
    them. (f) R17: if a resolution needs a paragraph to justify, it is a
    class-C deletion with a residue, not a clever merge.
6.  **What this plan could not determine without a toolchain build:** whether
    the merged tip passes the two template probes (§0.5); whether `std::thread`
    deduces from upstream's `_Nonnull` function-pointer type (R-4); whether
    `SelfDestruct` + D-SL-16 yields exactly one `free` (R-3); the exact fill
    size; whether any x-macro order test fails (R-10); whether the W-108
    field-destroy claim holds (§0.6). Each is pre-registered with its
    falsifier so the hosted runs answer it, not an agent's assertion.

### Review fold record

_(empty — rev 1 awaits two adversarial reviews per R29(c): one correctness
("find the input that breaks a re-expression; name the golden"), one
strictness ("find the rule/invariant violation; check every citation above
against the tree at 923c2f2af and upstream-trunk").)_

### Sign-off

-   Correctness review (rev 1): _pending_
-   Strictness review (rev 1): _pending_
-   Coordinator sign-off for implementation: _pending_
