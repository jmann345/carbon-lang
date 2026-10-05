<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# Upstream-advance plan: cut 631f8fb → c1e83b0b7 (UA-1 merge, UA-2 reconciliation)

**Status:** rev 2 — folded; focused re-review pending (rev A REJECTed). The
two adversarial reviews of rev 1 (R29(c)) returned REJECT (rev A,
fork-mechanism fidelity: BLOCKER A1 — D-UA-9 as written crashes every destroy
of a payload-carrying choice under upstream's real `MakeSubobjectDestroyOpBody`;
MAJORs A2-A5; MINORs A6-A10) and APPROVE-WITH-AMENDMENTS (rev B,
mechanics/verification: MAJORs B1-B5; MINORs B6-B15). Every finding is folded
in place below, each marked "(amended 2026-10-05, review fold: rev A A<n> / rev
B B<n>)", and tabled in the Review fold record before Sign-off; the fixer
re-opened every cited source (the fork tree at HEAD 5f65f35ba, `git show
upstream-trunk:<path>`, and the merged tree f2c06b2ae from `git merge-tree
--write-tree HEAD upstream-trunk`) before folding, and no finding was declined.
Numbering note (rev B B14): this plan's decisions live at §0.7 (the sibling
plans put them at §0.3); discharge entries cite "§0.7 D-UA-n". Branch
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
| Upstream files changed | `git diff --name-only 631f8fb upstream-trunk \| wc -l` | **1533** (1091 under `testdata/` — amended 2026-10-05, review fold: rev B B1, `grep -c testdata/` reproduces 1091, not 1094; by directory: toolchain/check 877, toolchain/lower 264, toolchain/sem_ir 50, language_server 45, utils/textmate 28, parse 20, docs/design 17, driver 15, lex 14, base 14, .github/workflows 14) |
| Fork files changed | `git diff --name-only 631f8fb HEAD \| wc -l` | 762 (toolchain 482 — 237 new goldens, 94 modified goldens, 151 sources; fork/ 230; docs 15; core 9; utils 5) |
| Overlap | `comm -12 <(…upstream…\|sort) <(…fork…\|sort)` minus `fork/` and `.github/workflows/fork_*` | **202** files: 112 non-testdata (toolchain 91, .github/workflows 6, docs/design 6, utils 5, root configs 4) + 90 goldens |
| Dry-run conflicts | `git merge --no-commit --no-ff upstream-trunk; git diff --name-only --diff-filter=U; git merge --abort` | **105** files (amended 2026-10-05, review fold: rev B B1 — rev 1 miscounted 20/79): **31 non-testdata** = 25 toolchain sources (the §0.3 table's 22 rows name 25 files once eval.{h,cpp}, generic.cpp + sem_ir/generic.cpp and function.{h,cpp} are counted singly) + 1 design doc (lexical_conventions/words.md) + 5 editor-syntax files; **74 goldens** = 73 `UU` content conflicts + 1 `UD` (upstream deleted lower/interop/cpp/std_initializer_list.carbon, the fork re-filled it). Reproduced from `git merge-tree --write-tree HEAD upstream-trunk` (tree f2c06b2ae; 105 distinct conflicted paths, 93 + 221 stage entries) without touching the worktree |
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
upstream-trunk -- <file>`; amended 2026-10-05, review fold: rev B B3 — rev 1's
wrap had put `#7784` and `#7689` at line starts, which MD018 turned into two
H2 headings; the PR lists below are written as bare numbers so no wrap can
start a line with `#`): custom_witness.cpp 16 (all of group 2 plus PRs 7729,
7784, 7813, 7654, 7788 and 7789); cpp/thunk.cpp 2 (PRs 7787, 7788);
cpp/export.cpp 10; cpp/import.cpp 12; cpp/generate_ast.cpp 3; call.cpp 6 (PRs
7788, 7800, 7729, 7689, 7700, 7682); deduce.cpp 2 (PRs 7813, 7670 — the fork's
`diagnose` flag hunk is untouched); pattern_match.cpp 8 (default values, PR
7867); class.cpp 3 (PRs 7745, 7796, 7706); eval.cpp 13; lower/function_context.cpp 4;
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
| check/custom_witness.cpp | 5 | **B** | `CanDestroyClass` signature (fork: `SpecificInterfaceId` + `query_is_symbolic`; upstream: `SpecificInterface`), its two call sites, and one 600-line hunk where the fork's impl-population scans (`HasUserDestroyImpl`, `HasClassKeyedImpl`, `HasNonTrivialUserCopyImpl`, `IsTriviallyDestructible`, `HasTrivialClassShapeForExport`) and the fork's `CanDestroyType` `CustomLayoutType` arm (:343) sit against upstream's `DestroyStructFields`/`MakeSubobjectDestroyOpBody`/`MakeDestroySelfDestructFunction` | upstream's `SpecificInterface` parameter type and three-entry Destroy witness; the fork's predicates, `query_is_symbolic` threading, `CustomLayoutType` arm, choice-copy and union-unformed witnesses survive; the choice shape upstream has never destroyed gets an explicit `is_choice` clause (amended 2026-10-05, review fold: rev A A1); the two clean-merging `GetCanonicalFacetOrTypeValue` calls at merged :1557/:1613 are renamed (rev A A2); D-UA-9 |
| check/eval.cpp, eval.h | 3, 1 | **C** | fork's `TryEvalBlockForSpecific(..., publish_block_id) -> pair<InstBlockId,bool>` (S3b incremental publication) vs upstream's in-place value block (#7717) | take upstream; D-UA-10 |
| check/generic.cpp, sem_ir/generic.cpp | 1, 1 | **C** | fork's pre-sized placeholder + loud CHECKs in `GetConstantInSpecific` vs upstream's `NotConstant` for unreached entries | take upstream; D-UA-10 |
| check/function.cpp, function.h | 1, 1 | A | upstream's return-form fields (`return_form`, `param_kinds`) land where the fork's generated-function changes (W-075 return slot, overload index) sit | keep both |
| check/handle_class.cpp | 2 | **B** | fork deleted `BuildClassDecl`'s body (moved to class.cpp `BuildClassOrUnionDecl`, UN-1); upstream rewrote it onto `TryMergeRedecl<SemIR::Class>` (#7632) | keep the fork's deletion; port upstream's new body into class.cpp; the D-UN-6 `class`/`union` flip check moves INTO `TryMergeRedecl` as an `if constexpr (IsClass)` clause (amended 2026-10-05, review fold: rev A A5); D-UA-6 |
| check/handle_function.cpp | 3 | **B** | fork's `MergeFunctionRedecl(…, replace_prev_inst, prev_decl_override)` + `TryMergeIntoOverloadSet` + marker/gate diagnostics (OV-1/OV-2) vs upstream's deletion of `MergeFunctionRedecl` in favor of `TryMergeRedecl<SemIR::Function>` and the new `CheckDefaults` | upstream's template for plain functions; the fork's full set-path decision (incl. the D-OV-3 marker-mismatch rule and the `ErrorInst`-localized imported set) runs before it, and set members merge through the fork's `MergeFunctionRedecl` renamed `MergeOverloadMemberRedecl` (amended 2026-10-05, review fold: rev A A4); D-UA-6 |
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

**Goldens (74; amended 2026-10-05, review fold: rev B B1 — rev 1 said 79/77/32).**
Indentation-aware classification (`git diff 631f8fb HEAD -- <f> \| grep
'^[+-]' \| grep -v '^[+-] *// CHECK'`, re-run by the fixer over the 74 paths of
the merge-tree listing): **71** are refill-only on the fork side (every fork
change is a CHECK line, incl. the indented `// CHECK:STDERR:` lines inside
split files); upstream edited source lines in **33** of them (#7656 renames
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
    the caller in cpp/import.cpp:2061 (conflicting hunk) must move to
    upstream's. (Amended 2026-10-05, review fold: rev A A6: rev 1 cited
    thunk.cpp:1215 as a second caller — that line is a COMMENT inside
    `GetOrBuildCppCatchingThunkDecl`. The catching path's real dependencies
    are `BuildCppCatchingThunk` constructing `CalleeFunctionInfo
    callee_info(callee_function_decl, &signature)` at thunk.cpp:1146 — inside
    the conflict hunk, so it is rebuilt on upstream's struct — and the two
    decl-taking `IsCppThunkFenceRequired(context, <FunctionDecl*>)` calls at
    thunk.cpp:1110 (`BuildCppCatchingThunk`) and :1607 (`PerformCppThunkCall`
    through `GetCalleeClangDecl`), both clean hunks, which keep compiling only
    if the refactored predicate keeps a `FunctionDecl*`-taking overload; §2.4.)
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
    redeclare — upstream-intended, adopted by refill (R-11). (Amended
    2026-10-05, review fold: rev A A10: the assertion is now backed by a grep
    recorded in §8.4 — `grep -nE '^\s*(overload )?fn \w+\(.*\);'` over
    fork/conformance/programs/functions/overloading_cross_library/geometry.impl.carbon
    and code_org/library_multifile_export/geo.impl.carbon is empty at HEAD.)
11. **`GetCanonicalFacetOrTypeValue` → `GetCanonicalFacet` (#7813):** upstream
    type.h:161-163 declares only `GetCanonicalFacet` (plus
    `TryGetCanonicalFacet`); the fork calls the old name at
    custom_witness.cpp:249 (`CanDestroyType`, inside a conflict hunk — covered
    by D-UA-9), :1209 (`LookupChoiceCopyWitness`) and :1265
    (`LookupUnionUnformedInitWitness`). The latter two merge CLEANLY: in the
    merged tree f2c06b2ae they sit at custom_witness.cpp:1557 and :1613,
    outside all five conflict hunks (merged :224-247, :400-407, :428-435,
    :508-997, :1017-1117), so the dry run cannot show them and the compile
    would. The fork's other callers (type_completion.cpp:1030,
    impl_lookup.cpp:273/:435/:1130, deduce.cpp:318, type.cpp:292/:305) are
    upstream code that upstream renamed in place and merge as upstream's.
    Resolved by renaming both calls in the merge commit; §8.4 grep. (Added
    2026-10-05, review fold: rev A A2.)

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
| W-108 member-held `Core.Buf` not destroyed (SL-1 residue) | #7829 struct fields, #7840 class fields, #7842 tuples, #7844 arrays: the synthesized `SubobjectDestroy.Op` calls each field's `Destroy.SelfDestruct`, which for `Buf` resolves to its declared impl's `Op` (the D-SL-16 selection) | **uncertain; probe** (amended 2026-10-05, review fold: rev B B12 — rev 1 said "plausibly DISCHARGED"): #7773 states it "doesn't add support for objects with non-trivial destruction" and #7845 only PREPARES `MakeSubobjectDestroyOpBody` for it; upstream's prelude `Destroy.SelfDestruct` is `self.Op(); self.SubobjectDestroy();` (core/prelude/destroy.carbon at tip), so a `Buf` field's declared `Op` runs only if the synthesized body calls the field's `SelfDestruct` for non-trivial fields — the path rev A traced (`DestroyStructFields` → `BuildSelfDestructCall` → declared impl → `Op` → `HeapFree`) is plausible, not evidenced; R-3 decides, never an assertion. NOT discharged for classes whose own impl is user-declared (their `SubobjectDestroy` is the interface's `final` placeholder — #7773's stated limit) | a lower golden holding a `Buf` field shows `free` (no W-108 pin exists in testdata today — `grep -rn W-108 toolchain fork/conformance/programs` is empty — so UA-2 adds the pin golden first, then un-files on the fill) |
| W-014 W7 templates / gap row 52 (Integrated templates PARTIAL; SKIP generics/templates_dependent_member.carbon cites `lower/handle.cpp:363 Template lowering not implemented`) | #7727 template lowering, #7801, #7741, #7657; the `CARBON_FATAL` left is "Cross-file template lowering not implemented yet" (upstream handle.cpp:400); upstream deleted its last `fail_todo` in generic/template/ | the single-file SKIP program likely compiles | un-SKIP probe commit; row 52 evidence re-cited. (Amended 2026-10-05, review fold: rev B B12: W-014's evidence in fork/inventory/work-items.json:262 cites `check/testdata/generic/template/fail_todo_template_access_assoc_const.carbon:15` — one of the 13 upstream DELETIONS (§0.1) — and `lower/handle.cpp:359-364`, now the cross-file TODO at :400; the UA-2 ledger note re-cites to upstream's `generic/template/*.carbon` goldens and handle.cpp:400, and gap-analysis.md:52/:150 (`handle.cpp:363`) are re-cited with it.) |
| W-043 / gap rows 40 and 54 (SKIP interop/cpp_template_symbolic_arg.carbon and cpp_template_on_carbon_generic.carbon: "unsupported type used as template argument") | #7673 "Support using Carbon generic types as C++ template parameters" | likely lifted: upstream-trunk's check/testdata/interop/cpp/template/generic_call.carbon has NO `fail_todo` split and pins exactly `fn F[T: type](unused x: T) { var unused v: Cpp.S(T); }` (:27-28) — the SKIPs' cited blocker is gone. Caveat (amended 2026-10-05, review fold: rev B B8): both fork programs ALSO put `Cpp.Box(T)` in the RETURN type and return the instantiation by value (`fn Wrap[T: type](v: T) -> Cpp.Box(T)` :29; `fn MakeBox[T: type](x: T) -> Cpp.Box(T)` :33), which upstream's pin does not cover — pre-registered as the likely residual if a probe fails | un-SKIP probes; a failure's measured diagnostic goes into the SKIP line (R10) |
| W-046 / row 43 (SKIP interop/inherit_multiple_bases.carbon) | #7745 virtual-base lowering crash, #7783 derived-to-base SemIR fix | **stays SKIP** (amended 2026-10-05, review fold: rev B B8): upstream-trunk:toolchain/check/testdata/interop/cpp/class/import/base.carbon:152 still carries the split `fail_todo_use_multiple_inheritance.carbon` with the identical `cannot implicitly convert expression of type `C*` to `Cpp.A*` [ConversionFailure]` / `MissingImplInMemberAccessInContext` lines the SKIP quotes (:159-173); #7745 fixes a `BuildVtable` crash and #7783 reorders qualification vs derived-to-base conversion — neither adds non-zero base offsets | no probe; the W-046 note cites the tip pin (base.carbon:152) as the still-standing blocker |
| W-037 lambdas/positional params | #7651 lexing and parsing of positional params | parse half present; check still stubs | title note only |
| W-030 interface `default`/`final` members | #7817 eval block, #7773 `final fn` bodies in interfaces | partial | note; no un-SKIP |
| W-083 `Cpp.Exception` release-on-destroy | #7845 prepares non-trivial `SubobjectDestroy` | still open; the choice-payload destroy synthesis it waits on is closer, and D-UA-9's `is_choice` clause (rev A A1) now states the limit explicitly in code: a payload-carrying choice runs NO payload destructor, exactly as the fork's placeholder did | note; the D-UA-15 residue "choice-payload destroy synthesis" names it |
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
-   **D-UA-3 — Goldens.** The 71 refill-only conflicts (amended 2026-10-05,
    review fold: rev B B1; rev 1 said 77) take upstream's version
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
    --all-files` on the merged tree, with the §3 commit-2 procedure).
    (Amended 2026-10-05, review fold: rev B B2 / rev B B3; rev 1 said "≤2
    unfixable lines" and "token-neutral", both false.) **Residue (B2):** the
    fixer reproduced the reviewer's experiment on a copy of `fork/` plus the
    four fork-authored docs/design pages under upstream's `.rumdl.toml`
    (rumdl 0.2.58): pre-fix 607 issues / 605 "fixable" net of copy artifacts,
    but after `check --fix` (run twice) `rumdl check` still reports **30
    MD013 lines in 13 files and exits 1** — every one is a line whose
    over-length part is a single code span or link (`stern = true`,
    `code-spans = false`: rumdl will not break inside a span, so moving the
    span to its own line leaves it > 80 columns, and the `[*]` marker
    over-promises). The hosted gate's `uvx prek run --all-files` therefore
    stays RED until each is rewritten by hand (a shorter span, or the sentence
    split so the span starts a line): fork/ORCHESTRATION.md:13,121,240;
    fork/decision-log.md:1445,1486,4857,4864; fork/overload/plan.md:357,482,
    1028,1320; fork/unions/plan.md:161,287,289,308,472,688;
    fork/w5-s3/plan.md:60,197,307,574; fork/b1/plan.md:267,409,416;
    fork/b2/plan.md:248,250; fork/slices/plan.md:323; fork/w076/plan.md:205;
    this plan's own §8.4 grep line (rev 1 :875 — split in rev 2 so it no
    longer qualifies); docs/design/functions_overloading.md:646 (line numbers
    are post-reflow positions on the copy; re-measure on the merged tree).
    The 30 hand-rewrites are budgeted INSIDE the mechanical commit, and the
    pre-push gate is `uvx rumdl check` AFTER `--fix` (R-9's falsifier), never
    the pre-fix `[*]` count. **Token damage (B3):** the reflow is NOT
    token-neutral. `git diff --word-diff=porcelain -U0` on the copy shows 79
    non-whitespace token changes; most are blockquote `>` prefixes moving
    between lines (benign), but a paragraph of fork/ORCHESTRATION.md wrapped
    so that `#12/#13/#14: S3a (…)` began a line, and the second rumdl pass's
    MD018 "fix" (`No space after # in heading`) made it a new H2 heading
    reading "12/#13/#14: S3a (payload-free generic-choice specifics as match
    scrutinees)", after which every following H3 became an H4 (heading counts on the copy:
    H3 5 → 1, H4 0 → 5: `Branches`, `Scoreboard`, `CI on jmann345/carbon-lang`,
    `Toolchains in the container`, `Next actions`, `Standing user directives`).
    A probe file confirms the mechanism under upstream's config: a line
    beginning `#7784, #7813 more` → `[MD018]`; a line beginning with the cron
    tail (asterisk, space, asterisk, space, one) → MD004 and MD069
    list-marker fixes; and, while THIS paragraph was linted, a continuation
    line beginning with a plus sign became a list item that swallowed the
    rest of the paragraph — the hazard set is `#`, `*`, `+`, `-` and `N.` at
    a line start. The fork's own pipeline (prettier `proseWrap: always` and
    the R12 hook's rumdl) had ALREADY done this to rev 1 of this plan (two
    headings reading "7784, #7813, …" and "7689, #7700, …" in §0.2 and the
    weekly cron mangled into a list item in §8.3 — both repaired in rev 2)
    and to the decision log (decision-log.md:5562, a heading reading "7741
    template-dependent assignment, …" at HEAD — repaired by the reflow
    commit, which is the first commit allowed to touch that file). Fenced
    code blocks: a block-by-block comparison of the 34 reflowed files shows
    ZERO changed fences; tables: zero table lines touched. So the hazard is
    headings and list items manufactured from a list or heading marker at a
    line start, not code or tables. Procedure and falsifier: §3 commit 2 and
    R-9 (per-file heading count per level unchanged; no new list items; the
    `git diff -U0` grep for added lines that begin with a heading marker plus
    a digit, a list marker, or a digit plus a period is empty after
    rephrasing each hit). Rulebook rule R31 (allocated at this fold,
    fork/rulebook.md) carries the lesson. Rejected: a fork-local MD013 opt-out
    for `fork/` (a second lint regime, R21 parity). Break condition: a reflow
    that changes a token other than the enumerated benign classes — rev 1's
    "revert that file's reflow" is unworkable for ORCHESTRATION.md and the
    decision log, so the break action is: rephrase the offending line so the
    hazardous token no longer starts a line, re-run the reflow, re-count
    headings.
-   **D-UA-5 — Editor grammars.** Upstream's restructured grammars win; `union`
    joins each introducer list and `overload` each modifier list in upstream's
    new positions; tree-sitter entries stay commented (W-091). Break: none.
-   **D-UA-6 — Redeclaration unification.** `TryMergeRedecl<EntityT>` is the
    only merge path for PLAIN entities (amended 2026-10-05, review fold: rev A
    A4 / rev A A5 — rev 1's "two optional fields" design was not implementable
    and dropped two fork rules). **Class half (A5):** class.cpp's
    `BuildClassOrUnionDecl` drops its copied `MergeClassRedecl`/`MergeOrAddName`
    and calls `TryMergeRedecl<SemIR::Class>` with `LookupOrAddName`'s result,
    the `is_union` and `decl_kind` facts kept around the call. The D-UN-6
    `class`/`union` flip check (fork class.cpp:137-144: `prev.is_union !=
    class_info.is_union → DiagnoseDuplicateName`) has NO home outside the
    template: upstream's `TryMergeRedecl<Class>` sets `prev_entity_id` for any
    `ClassDecl` or imported class and merges (merge.cpp:745-770), the
    prev-class resolution for imports lives in the `static` `FillPrevEntityInfo`
    (merge.cpp:596-624) so the check cannot run BEFORE the call without
    duplicating it, and after the call `class_decl.class_id` already points at
    the previous class with `MergeDefinition`/`ReplacePrevInstForMerge` done,
    so it cannot run AFTER. So the check moves INTO the template: a fork-local
    `if constexpr (IsClass)` clause right after `prev_entity` is obtained
    (the lambda at merge.cpp:811-823 in upstream's numbering) — `if
    (prev_entity.is_union !=
    entity_info.new_entity.is_union) { DiagnoseDuplicateName(context,
    name_context.name_id, name_context.loc_id, SemIR::LocId(prev_id)); return
    false; }` — four lines commented "Fork (D-UN-6)". Pin:
    check/testdata/union/fail_modifiers_and_redecl.carbon, splits
    `fail_class_then_union` (`class C;` :60 … `union C {` :69) and
    `fail_redefinition` (the `union D` pair :76/:87). **Function half (A4):**
    rev 1's break-condition branch is now the PRIMARY design. The fork's
    `MergeFunctionRedecl` (handle_function.cpp:168-210) already IS the
    template's function body (`CheckFunctionTypeMatches` →
    `DiagnoseIfInvalidRedecl` → `MergeDefinition` → `ReplacePrevInstForMerge`)
    with the four knobs a set member needs — an explicit prev entity id (the
    MEMBER `member_function_id`, a local `FunctionDecl` of the localized set,
    never the name's prev inst), an explicit `prev_import_ir_id`
    (`member_source.import_ir_id`, :383), `prev_decl_override` (the API
    file's facts for a localized member) and `replace_prev_inst = false` — and
    upstream's template cannot take them: it `CARBON_CHECK`s `!lookup_result`
    for functions (merge.cpp:707), derives `prev_id` from
    `name_context.prev_inst_id()` (:735) and fills `prev_import_ir_id` only from
    an `ImportRefLoaded` prev inst (:782-797). Threading four overrides and a
    bypass of its prev-inst derivation through the template is a second code
    path inside it — R17's defect signal. So: `MergeFunctionRedecl` is KEPT,
    renamed `MergeOverloadMemberRedecl`, called only from
    `TryMergeIntoOverloadSet`, with a header comment naming the divergence
    ("mirrors `TryMergeRedecl<Function>`'s body for a set member merged against
    a specific member, not the name's prev inst"); no `MergeRedeclEntityInfo`
    fields are added. The pre-step in `BuildFunctionDecl` runs the fork's FULL
    decision from its `TryMergeRedecl` (handle_function.cpp:448-573) minus the
    plain-function tail (:562-572), that is in order: (1) prev inst is a local
    `OverloadSetValue` (:470-477) → set path; (2) prev inst is `ImportRefLoaded`
    whose import-IR inst is an `OverloadSetValue` (:497-522) → set path through
    `GetImportedOverloadSetSource`, or SILENT return when the localized constant
    is not an `OverloadSetValue` (`ErrorInst`: a member could not be localized,
    already diagnosed) — rev 1's "or its loaded import constant" keyed on the
    wrong inst and would have let upstream's template `DiagnoseDuplicateName`
    it (W-107's shape); (3) `is_overload` against anything else (:551-559) →
    `DiagnoseOverloadMarkerMismatch`, NO merge, the declaration gets its own
    function and is not added to name lookup (D-OV-3: "a marked declaration
    against a plain function is not merged") — rev 1's pre-step would have
    sent `fn F(x: i32)` then `overload fn F(b: bool)` into the template, where
    `CheckFunctionTypeMatches` fails on the parameter types and upstream's
    redeclaration diagnostics replace the fork's; (4) otherwise upstream's
    `TryMergeRedecl(context, name_context, std::nullopt,
    MergeRedeclEntityInfo<SemIR::Function>{…}, is_definition)` unchanged. Pins:
    check/testdata/function/overload/fail_marker_mismatch.carbon — splits
    `fail_unmarked_second` (:17-31, the set-path direction of the diagnostic),
    `fail_marked_second` (:35-49: `fn F(unused x: i32)` then `overload fn
    F(unused b: bool)`) and `fail_plain_redecl_unchanged` (:51, the template
    direction); the OV-2 api/impl and cross-library goldens for (2). Break
    condition: upstream's `TryMergeRedecl<Function>` later grows a
    member-targeted entry point → `MergeOverloadMemberRedecl` is deleted in
    favor of it at that merge (recorded as a V-3a convergence).
-   **D-UA-7 — Thunks.** Upstream's public `CalleeFunctionInfo` (thunk.h) is
    the base; `BuildCppThunk(context, callee_info)` keeps upstream's signature;
    `BuildCppCatchingThunk`/`GetOrBuildCppCatchingThunkDecl` take a
    `CalleeFunctionInfo` built from the callee's `ClangDecl`; the `_catch`
    mangling marker and `is_catching` naming stay. (Amended 2026-10-05, review
    fold: rev A A3 / rev A A7 — rev 1 named only the predicate clause and the
    body wrapper and omitted the fence itself.) **The fence has three
    components, and the first is the fence:** (1) the `noexcept` exception
    spec on the thunk DECLARATION — fork thunk.cpp:666-671,
    `CreateThunkFunctionDecl`: `ext_proto_info.ExceptionSpec.Type =
    clang::EST_BasicNoexcept` under `CXXExceptions` (decision-log EH-B ledger
    correction [4]: "the fence is the `noexcept` exception spec, not a
    `try`/`catch`"). Upstream's `CreateThunkFunctionDecl` (thunk.cpp:429-475)
    builds a default `ExtProtoInfo` with NO exception spec, and the function
    is inside a conflict hunk, so the implementer re-adds the spec by hand on
    upstream's version, for BOTH the decl path and the `FunctionPointer`
    constructor path (one function serves both). (2) `WrapInBoundaryDiagnostic`
    (fork :904-957, `try { … } catch (...) { write; throw; }`) applied in
    `BuildThunkBody` under `IsCppThunkFenceRequired(callee_info.function_type,
    callee_info.decl_or_null)` — its rethrow reaches `terminate` ONLY because
    the enclosing thunk is `noexcept`; without (1) the catch-all + rethrow
    still emits a `personality` line while `__clang_call_terminate` disappears
    and the terminate contract (error_handling.md, "the fenced boundary") is
    gone with zero diagnostics. (3) the `IsCppThunkRequired(context,
    callee_info)` clause (decl path only) so a fence-required callee gets a
    thunk even when its ABI would not need one. The fence predicate is
    refactored to `IsCppThunkFenceRequired(Context&, const
    clang::FunctionProtoType*, const clang::FunctionDecl* decl_or_null)` (the
    decl, when present, for `ResolveExceptionSpec`) and KEEPS a
    `FunctionDecl*`-taking overload for the two clean-hunk callers
    (thunk.cpp:1110, :1607 — rev A A6, §0.4 item 7). **Function-pointer path
    (A7):** upstream's `ImportFunctionPointerInvoke` (import.cpp:2127-2160)
    never calls `IsCppThunkRequired` — it calls `DefineAsThunkCall`
    unconditionally (:2157), so component (3) fences nothing there; only (1)
    and (2) do, through `CreateThunkFunctionDecl`/`BuildThunkBody`, and they
    key on `callee_info.function_type` with `decl == nullptr`. When that
    `DefineAsThunkCall` fails, upstream still records `result.function_id` and
    lowering (lower/handle_call.cpp:784-789) calls the pointer DIRECTLY for a
    `CppFunctionPointerThunk` function — an unfenced call of a
    potentially-throwing pointer type, the shape EH-B forbids ("never an
    unfenced call", fail_fence_thunk_unbuildable.carbon). Decision: the same
    fence-unbuildable check as the decl path runs after
    `ImportFunctionPointerInvoke`'s `DefineAsThunkCall`, keyed on
    `IsCppThunkFenceRequired(callee_info.function_type, nullptr)` and on the
    thunk not having been attached → `context.TODO(loc_id, "Unsupported:
    fenced thunk for potentially-throwing C++ function pointer could not be
    built")` and `result.decl_id = ErrorInst` (fence, never an unfenced call;
    §2.4). A catching (`?`) thunk over a function-pointer callee is TODO-gated
    ("catching thunk for a C++ function pointer") and filed as a residue. The
    constant-function-argument plumbing (`num_constant_params`,
    `is_constant_param`, `GetThunkParamIndex`) is deleted with D-UA-8. Break
    condition: upstream's function_ptr goldens show the fence
    (`invoke`/landingpad/`__clang_call_terminate`) — EXPECTED churn, accepted;
    the FAILURE is a fenced-thunk lower golden losing `__clang_call_terminate`
    (30 lower goldens carry it today: `grep -rl __clang_call_terminate
    toolchain/lower/testdata | wc -l` = 30), with `personality` only a
    secondary signal since it survives the loss of (1) (R-5).
-   **D-UA-8 — F8d retirement.** Upstream's Carbon-function → C++-function-
    pointer conversion (#7789) replaces F8d's constant-function-argument
    embedding: delete `ClangDeclSignature::constant_function_args` and its
    hashing/equality (sem_ir/clang_decl.{h,cpp}), `InventConstantFunctionArg`
    and `TryMapFunctionType` (type_mapping.cpp), the `HasConstantFunctionArgs`
    branches (cpp/call.cpp:85, constant.cpp:320, overload_resolution.cpp:264),
    the thunk's constant-param plumbing, and `GetOrExportFunctionDeclToCpp`.
    The W-023 ledger note records the replacement; the F8d conformance programs
    (interop/cpp_thread_carbon_fn_diff.carbon and the other three thread
    programs) are the pins. (Amended 2026-10-05, review fold: rev B B13 / rev A
    A8.) **Revertible deletion (B13):** #7789's own goldens (check+lower
    interop/cpp/function/import/function_ptr.carbon, decayed_param.carbon)
    convert to a NAMED pointer type (`using CallbackType = int (*)(float);`
    function_ptr.carbon:15) and none passes a Carbon function to a
    template-deduced parameter (`std::thread(F&&)`), which is the only shape
    W-023/cpp_thread_carbon_fn_diff.carbon needs — so the replacement is
    evidenced only indirectly before the conformance run. The F8d deletion
    therefore lands as its OWN commit 1b immediately after the merge commit
    (§3), so the break action is `git revert`, not a re-implementation inside
    the merge; the duplicate-`case` fix (§0.4 item 1) stays in the merge
    commit proper (the tree must compile), which means commit 1 deletes only
    the fork's `case SemIR::FunctionType::Kind:` arm and commit 1b deletes the
    rest of the embedding. R29(b) is unaffected (same PR). **Narrower break
    condition (A8):** the deduction is more decidable than rev 1 said. The
    program calls `Cpp.std.thread.thread(Work)` (cpp_thread_carbon_fn_diff
    .carbon), deducing `thread<void(*)()>(void(*&&)())`; upstream handles each
    piece of that shape: type_mapping.cpp:287-305 maps a `FunctionType`
    argument to a `_Nonnull`-attributed pointer type for deduction (member
    pointer for methods), overload_resolution.cpp:134-150
    (`ComputePassingModeForReferenceBinding`) passes a non-const rvalue
    reference `ByVar`, thunk.cpp:476-506 (`BuildThunkParamRef`) casts the
    thunk parameter to an xvalue when the callee parameter is an rvalue
    reference, and convert.cpp:505-520 (`ConvertFunctionToCppPointer` →
    `ExportFunctionToCppPointerConversion` + `CppAddrOfFunction`) performs the
    `var` parameter's conversion. The residual unknown is only whether the
    `_Nonnull` attribute perturbs deduction. Break condition:
    cpp_thread_carbon_fn_diff.carbon fails under upstream's mechanism with a
    signature in THAT residual (a deduction failure naming `_Nonnull` or the
    `void (*&&)()` parameter) → `git revert` commit 1b and file the residue;
    any other red on the four thread programs is a merge defect fixed at its
    root, never by re-adding the embedding — never both paths for one shape.
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
    (Amended 2026-10-05, review fold: rev A A1 BLOCKER / rev A A2.) **The
    choice shape (A1):** rev 1 pre-registered the OPPOSITE of what the tree
    says. A payload-carrying choice's object representation (fork
    handle_choice.cpp:796-838) is a struct of two `StructTypeField`s,
    `NameId::ChoiceDiscriminant` and `NameId::ChoicePayload`, the latter typed
    as the `CustomLayoutType` payload region; no `FieldDecl` enters the class
    scope (upstream's handle_choice.cpp:276 has only the discriminant, likewise
    scope-less), and no `member_access.cpp` arm on either side resolves those
    names. The fork never crashed because its `MakeDestroyOpBody`
    (custom_witness.cpp:882-905) accepted `ClassType`/`CustomLayoutType`/… and
    emitted NOTHING; and its `CanDestroyType` `CustomLayoutType` arm (:343-368)
    answers `NonTrivial`/`NoDestroy`, never `Trivial` for a non-empty field
    list, so rev 1's "the `Trivial` format short-circuits first" is false for
    the fork's own arm. Upstream's `MakeSubobjectDestroyOpBody`
    (custom_witness.cpp:410-511) is REAL: its `ClassType` arm runs
    `DestroyStructFields(class_info.GetStructTypeFields(…))` (sem_ir/class.cpp:55-72
    returns the repr struct's fields for a non-adapter class, so a choice's
    `[ChoiceDiscriminant, ChoicePayload]`), which calls
    `PerformMemberAccess(context, loc_id, self, field.name_id)` then
    `BuildSelfDestructCall` per field; its `default` is
    `CARBON_FATAL("Unexpected type for MakeSubobjectDestroyOpBody")` with no
    `CustomLayoutType` arm; and `AddCleanups` (control_flow.cpp:151-158) calls
    `BuildSelfDestructCall` for every `var`. Path for `var r: Core.Result(i32,
    E) = …;` under rev 1: `BuildSelfDestructCall` → `LookupDestroyWitness` →
    `CanDestroyClass` (`NonTrivial`: the repr fields are non-empty) →
    `BuildCarbonDestroyWitness(NonTrivial)` → `MakeSubobjectDestroyOpBody
    (ClassType)` → `DestroyStructFields` → (a) `PerformMemberAccess(self,
    ChoiceDiscriminant)` fails name lookup inside a synthesized function
    (`QualifiedExprNameNotFound`-class error, member_access.cpp:649), or (b) if
    it resolved, `BuildSelfDestructCall` on the payload → `CanDestroyType
    (CustomLayoutType)` → `NonTrivial` → `MakeSubobjectDestroyOpBody
    (CustomLayoutType)` → `CARBON_FATAL`. Upstream never exercises this: NO
    upstream golden under check/testdata/choice or lower/testdata/choice
    declares a `var` (checked every file at upstream-trunk) and none mentions
    `SubobjectDestroy`; the fork has seven. The autoupdate's stack-dump gate
    would fail on the first such file and hide the rest of the fill behind it
    (the "decidable from the tree" planning-miss class the SL-1 entry names).
    **Decision:** `MakeSubobjectDestroyOpBody`'s `ClassType` arm returns early
    for `class_info.is_choice` — one clause, commented "Fork (D-UA-9, W-083):
    a choice's repr fields are not scope members; payload destructors do not
    run — placeholder semantics preserved; TODO: choice-payload destroy
    synthesis (D-UA-15 residue)" — so a choice's `SubobjectDestroy.Op` is an
    empty body, exactly the fork's placeholder behavior (W-083 and the W-071
    note already record this limit; the S1 admitted-exception adapter payload
    keeps its declared-impl `Op` through `SelfDestruct` as before). The
    alternative (ii), `CanDestroyClass` answering `Trivial` for an `is_choice`
    whose repr fields all pass `IsBuiltinWithTrivialDestruction`, is rejected
    for UA-1: it needs a second walk over the payload region and still needs
    (i) for the `NonTrivial` case — two clauses where one suffices (R17); it
    is recorded as the UA-2 refinement if the fill shows empty
    `SubobjectDestroy` defines are noisier than `NoOp`. In the same hunk the
    fork's `CanDestroyType` `CustomLayoutType` arm (:343-368) MUST survive
    (upstream's `CanDestroyType` has no such arm and `CARBON_FATAL`s at :388
    on the payload field during the witness query). **Pins:** the seven
    choice goldens with `var`s — check/testdata/choice/{alternative_copy,
    payload_construct, fail_generic_payload, fail_todo_nontrivial_payload}
    .carbon, lower/testdata/choice/{alternative_copy, payload_layout,
    single_payload_alternative}.carbon; the nine match/ goldens with `var`s
    (check + lower); every EH-A/EH-B golden that holds a `Core.Result` value
    (12 files: check+lower interop/cpp/exceptions/catching_thunk.carbon,
    check interop/cpp/exceptions/{fail_catching, fail_catching_none_mode}
    .carbon, check+lower interop/cpp/function/export/result_expected.carbon,
    check+lower operators/question_result.carbon, check
    operators/question_optional.carbon, check+lower main_run/return_result
    .carbon, check main_run/fail_mismatch_return.carbon — the `?` desugar's
    temporaries and `Run`'s result are cleanup-scoped storage, so each reaches
    `AddCleanups`); and the 31 conformance programs referencing `Core.Result` or
    `choice` (`grep -rlE 'Core\.Result|\bchoice\b' fork/conformance/programs
    | wc -l` = 31). Pre-registered golden shape: every `_COp.<hash>:core
    .Destroy.Core` define in lower/testdata/choice/payload_layout.carbon
    (:127-174 today) is replaced by upstream's `SubobjectDestroy`/`SelfDestruct`
    pair with an empty subobject body — a rename-and-reshape, not a
    disappearance (R-2). §8.4 grep: `grep -n 'is_choice'
    toolchain/check/custom_witness.cpp` → a hit inside
    `MakeSubobjectDestroyOpBody`. Risk ranking: this is now R-17, the
    top-ranked risk of §7. **Rename (A2):** the two clean-merging
    `GetCanonicalFacetOrTypeValue` calls (`LookupChoiceCopyWitness`,
    `LookupUnionUnformedInitWitness`; §0.4 item 11) become `GetCanonicalFacet`
    in the merge commit. Break condition: the slice/buf lower golden or
    stdlib/slices_heap_buf.carbon no longer shows exactly one `free` per `Buf`
    (double free through `SelfDestruct` + a field walk, or none) — fixed at
    the root before merge; AND any choice or match golden's fill carrying a
    `SubobjectDestroy`-related diagnostic or stack dump — fixed at the root
    (the `is_choice` clause or the surviving `CustomLayoutType` arm), never
    by editing the golden.
-   **D-UA-10 — Specific resolution.** Upstream's in-place value block (#7717)
    replaces the fork's S3b incremental publication; the `publish_block_id`
    parameter, the pre-sized placeholder in `ResolveSpecificDefinition` and the
    two loud CHECKs in `GetConstantInSpecific` go. Upstream's TODO ("distinguish
    parts not yet reached from `NotConstant`") is the acknowledged gap the
    fork's CHECK guarded; V-3a says follow upstream. Confirmed sound (rev A
    A9, no finding): upstream's `TryEvalBlockForSpecific` (eval.cpp:3530-3575)
    allocates the value block and `SetValueBlock`s it on the specific BEFORE
    evaluating — S3b's incremental publication is upstream's mechanism now;
    only the fork's forward-reference CHECK is lost (sem_ir/generic.cpp:102-109
    returns `NotConstant`). Break condition: a generic-choice golden crashing,
    or changing structurally rather than by `.loc` renumbering, in the fill —
    then the forward-reference CHECK is re-added as a fork-local assertion
    only (no publish plumbing). Pin family (amended 2026-10-05, review fold:
    rev A A9 — rev 1's `generic_*` glob missed three): check/testdata/choice/
    {generic, generic_payload, fail_generic_payload}.carbon,
    lower/testdata/choice/{generic_payload, generic_payload_imported}.carbon,
    and the S3c match pair check+lower
    match/choice_generic_payload_pattern.carbon (plus
    match/choice_generic_payload_scrutinee.carbon and
    match/choice_generic_scrutinee.carbon, check + lower).
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
    catching-thunk gate (D-UA-7), the function-pointer fence-unbuildable TODO
    (D-UA-7, rev A A7), choice-payload destroy synthesis under upstream's real
    `SubobjectDestroy` walk (D-UA-9's `is_choice` clause, rev A A1 — the
    W-083 dependency made explicit), any fork golden whose fill shows an
    upstream-intended diagnostic the fork's design did not anticipate (R-11),
    and the F8d retirement note. Each gets a W-item at UA-2 with file:line
    evidence. (Amended 2026-10-05, review fold: rev A A1 / rev A A7.)

#### §0.8 The split: UA-1 one staged merge PR, UA-2 one reconciliation PR

A git merge is atomic: "the non-overlapping 90%" cannot land as a PR while
the twenty-five conflicting sources are unresolved, because the tree would not
build (§0.4 items 1-7 and 11 are build breaks; amended 2026-10-05, review
fold: rev B B1 / rev A A2). One decomposition rev 1 did not consider (rev A,
"items checked", optional): a pre-merge fork-side refactor landing
`MergeOverloadMemberRedecl` and the `is_choice` destroy clause on trunk BEFORE
the merge would shrink the merge commit; it is not taken here because each
would need its own hosted round (R28) for no change in observable behavior,
but it is the recorded alternative if the merge commit's review finds the
hand-resolved hunks too large to read. So the three slices the brief
sketched are the three COMMIT groups inside UA-1 (merge with every textual
and semantic resolution; the mechanical reflow; the hosted fills and the
fixes they expose), and the separable work — status changes, ledger and
gap-analysis moves, pins for upstream-discharged items — is UA-2, which is
judged by its own scoreboard delta. R29(b): one PR per landed step; the
landed steps are "trunk at c1e83b0b7" and "trunk reconciled to it".

### §1 Design: how each conflict class is merged

1.  **Textual resolution order (sources first):** core_identifier.def →
    sem_ir/function.h (`Callee`) → sem_ir/generic.cpp, generic.cpp, eval.{h,cpp}
    (D-UA-10, take theirs) → custom_witness.cpp (D-UA-9, incl. the `is_choice`
    clause and the two `GetCanonicalFacet` renames outside the hunks — rev A
    A1/A2) → handle_class.cpp +
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
    latter the union field rule and the export predicate. (Amended 2026-10-05,
    review fold: rev A A1 — rev 1's "a `CustomLayoutType` arm is added to
    `MakeSubobjectDestroyOpBody` only if the fill reaches its `CARBON_FATAL`
    for a union; the `Trivial` format should short-circuit first" was wrong on
    both counts, see D-UA-9.) Concretely in this file: (a) the fork's
    `CanDestroyType` `CustomLayoutType` arm (:343-368, inside the big hunk)
    is kept verbatim on upstream's `SpecificInterface` parameter — upstream's
    `CanDestroyType` has no arm for it and would `CARBON_FATAL` at its `default`
    (:388) on a choice's payload field or a native union's repr; (b) upstream's
    `MakeSubobjectDestroyOpBody` `ClassType` arm gains, before
    `DestroyStructFields`, `if (class_info.is_choice) { return; }` with the
    D-UA-9 comment; its `default: CARBON_FATAL` stays — a native `union`'s repr
    is a `CustomLayoutType` too, but unions are classes with `is_union` whose
    repr fields are trivially destructible by D-UN-2, so a union reaches the
    `ClassType` arm and walks ITS repr fields; if the fill shows that walk
    reaching the `CustomLayoutType` `default` for a union, the same early
    return is extended to `is_union` (pre-registered second clause, pins
    check/union/*.carbon and lower/union/*.carbon with `var`s); (c)
    `CanDestroyClass` keeps upstream's `GetStructTypeFields(…).empty() →
    Trivial` short-circuit (fires for no choice: the discriminant field is
    always present).
-   `LookupChoiceCopyWitness`, `LookupUnionUnformedInitWitness`,
    `BuildPrimitiveCopyWitness`, `LookupCustomWitness`: `SpecificInterface`
    parameters; the two `GetCanonicalFacetOrTypeValue(context,
    query_self_const_id)` calls in the first two (fork :1209/:1265; merged
    :1557/:1613, outside every hunk) become `GetCanonicalFacet` (§0.4 item 11,
    rev A A2); `MakeBuiltinOperatorFunction` callers pass upstream's new
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
    The D-UN-6 flip check is NOT here — it lives inside the template (next
    bullet but one; amended 2026-10-05, review fold: rev A A5).
-   **check/handle_function.cpp** (amended 2026-10-05, review fold: rev A A4):
    RENAME the fork's `MergeFunctionRedecl` → `MergeOverloadMemberRedecl`,
    keep its signature `(Context&, Parse::AnyFunctionDeclId, SemIR::Function&
    new_function, bool new_is_definition, SemIR::FunctionId prev_function_id,
    SemIR::ImportIRId prev_import_ir_id, bool replace_prev_inst,
    std::optional<RedeclInfo> prev_decl_override)` and body, drop the now-dead
    `replace_prev_inst` parameter only if its single caller
    (`TryMergeIntoOverloadSet`) always passes `false` (it does — then hard-code
    `false` and say so in the comment); keep `DiagnoseOverloadMarkerMismatch`,
    `MakeApiMemberRedeclInfo`, `GetImportedOverloadSetSource`,
    `TryMergeIntoOverloadSet`, `IsEntryPointResultReturnType`,
    `DiagnoseOverloadInInterfaceOrImpl`, `DiagnoseOverloadGates`. The fork's
    file-local `TryMergeRedecl` (:448-573) becomes `TryMergeOverloadDecl`
    returning `bool handled`: its poisoned-name check is dropped (upstream's
    template does it), and its body is the four-step decision of D-UA-6 —
    local `OverloadSetValue` → set path, return true; `ImportRefLoaded` over an
    import-IR `OverloadSetValue` → set path or silent return on a non-set
    localized constant, return true; `is_overload` against anything else →
    `DiagnoseOverloadMarkerMismatch`, return true (no merge, not added to name
    lookup — the existing behavior); otherwise return false. In
    `BuildFunctionDecl`, after upstream's `CheckDefaults` and
    `DiagnosePositionalParams`: `if (!TryMergeOverloadDecl(…)) {
    TryMergeRedecl(context, name_context, std::nullopt,
    MergeRedeclEntityInfo<SemIR::Function>{…}, is_definition); }` — upstream's
    call unchanged. A new `overload fn F` with NO previous inst takes the
    template's early return (`!prev_id.has_value()`) and continues as the
    fork's new-set creation does today.
-   **check/merge.{h,cpp}:** NO `MergeRedeclEntityInfo<SemIR::Function>` fields
    (rev 1's two fields are withdrawn, rev A A4). One fork-local clause in
    `TryMergeRedecl` (rev A A5), immediately after the `prev_entity` lambda
    (upstream merge.cpp:811-823): `if constexpr (IsClass) { if
    (prev_entity.is_union != entity_info.new_entity.is_union) {
    DiagnoseDuplicateName(context, name_context.name_id, name_context.loc_id,
    SemIR::LocId(prev_id)); return false; } }` commented "Fork (D-UN-6): a
    redeclaration that changes between `class` and `union` is a duplicate
    name, not a merge" — before `CheckRedeclParamsMatch` so no parameter
    diagnostic precedes it (the fork's `MergeOrAddName` order). The fork's
    `CheckRedeclExplicitParamsAfterSelfMatch` (merge.h:110) stays.

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
-   **check/cpp/thunk.{h,cpp}, import.{h,cpp}:** per D-UA-7 (amended
    2026-10-05, review fold: rev A A3 / A6 / A7). Concretely, in order of the
    fence components: (1) `CreateThunkFunctionDecl` (upstream :429-475, inside
    a conflict hunk) re-gains the fork's `if
    (ast_context.getLangOpts().CXXExceptions) {
    ext_proto_info.ExceptionSpec.Type = clang::EST_BasicNoexcept; }` (fork
    :666-671) before `getFunctionType`, plus the fork's `is_catching`
    parameter (catching thunks return `int` and carry the `_catch` name) — the
    §8.4 grep `grep -n EST_BasicNoexcept toolchain/check/cpp/thunk.cpp` → one
    hit inside `CreateThunkFunctionDecl`. (2) `IsCppThunkFenceRequired(Context&,
    const clang::FunctionProtoType*, const clang::FunctionDecl* decl_or_null)`
    is the primary predicate, and a thin `IsCppThunkFenceRequired(Context&,
    const clang::FunctionDecl*)` overload (`decl->getType()->getAs<
    clang::FunctionProtoType>(), decl`) stays declared in thunk.h for the two
    clean-hunk callers (thunk.cpp:1110 in `BuildCppCatchingThunk`, :1607 in
    `PerformCppThunkCall` through `GetCalleeClangDecl`) and import.cpp:2125;
    `BuildThunkBody(…, callee_info)` wraps through `WrapInBoundaryDiagnostic`
    under `IsCppThunkFenceRequired(callee_info.function_type, callee_info.decl)`
    (the message names `callee_info.decl_name` when `decl` is null —
    `WrapInBoundaryDiagnostic`'s `decl->getQualifiedNameAsString()` at fork
    :912-914 is the one line that dereferences `decl`). (3)
    `IsCppThunkRequired(context, callee_info)` returns true when (2)'s
    predicate holds (decl path; upstream import.cpp:2071). `BuildCatchingThunkBody`
    reuses upstream's `BuildCalleeCallExpr`/`BuildReturnValueStore`; the
    `GetThunkReturnParamIndex` arithmetic becomes upstream's `num_callee_params`
    minus `callee_param_to_carbon_param_offset()`. In `ImportFunctionDecl`,
    after upstream's `DefineAsThunkCall` (:2078), the fork's check stays: if
    the callee is fence-required and the imported function has no C++ thunk
    attached (`!imported_function.cpp_thunk_decl_id().has_value()` or the
    equivalent upstream accessor), `context.TODO(loc_id, "Unsupported: fenced
    thunk for potentially-throwing C++ function could not be built")` — the
    fail_fence_thunk_unbuildable.carbon pin stays red-line. In
    `ImportFunctionPointerInvoke` (upstream :2127-2160), after its
    `DefineAsThunkCall` (:2157): the same check keyed on
    `IsCppThunkFenceRequired(context, callee_info.function_type, nullptr)`
    and the thunk's absence → the TODO with "C++ function pointer" in the
    message and `result.decl_id = SemIR::ErrorInst::InstId` /
    `result.function_id = None` so lowering's direct `CreateCall` on the
    pointer (lower/handle_call.cpp:784-789) is never reached for a
    fence-required pointer type (rev A A7). A new check golden
    check/testdata/interop/cpp/function/import/fail_fence_function_ptr_unbuildable
    .carbon is NOT added in UA-1 (no hand-written goldens, and the shape that
    makes `DefineAsThunkCall` fail is not known for pointer types); the branch
    is covered by the D-UA-15 residue and its first fill.
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

`git checkout --theirs -- <71 refill-only files>` (amended 2026-10-05, review
fold: rev B B1); `git rm` std_initializer
_list.carbon; for check/let/fail_generic_import.carbon take theirs then rename
the split `// --- fail_implicit.impl.carbon` to `// --- implicit.impl.carbon`
and clear its CHECK lines; for lower/var/import.carbon take theirs then
re-add `fn X() -> i32 { return x; }` (after the `import library "import"` of
the `use.carbon` split, where the fork had it) and clear the CHECK lines
below it. The 237 fork-new and 94 fork-modified goldens are not touched by
hand; the fill moves them.

#### §2.8 Non-toolchain files

-   `.rumdl.toml`, `.pre-commit-config.yaml` (rumdl v0.2.58): upstream's.
-   `.github/workflows/*`: upstream's hunks merge cleanly; the fork's SIX
    `if: github.repository == 'carbon-language/carbon-lang'` guards
    (auto_label_prs.yaml:22, check_dependent_pr.yaml:26, gh_pages_ci.yaml:25,
    gh_pages_deploy.yaml:27 and :76, nightly_release.yaml:40 — none exists at
    upstream-trunk, and upstream touched all five files in the range) must
    survive — verify by the §8.4 grep after the merge, expecting six hits
    (amended 2026-10-05, review fold: rev B B9; rev 1 named two). LLVM bump
    (rev B B10): the 19.1.7/20.1.8 → 21.1.8 change is in
    `.github/actions/build-setup-ubuntu/action.yml` (`LLVM_RELEASE=21.1.8`,
    :30/:32; macOS to `llvm@21` in build-setup-macos), NOT in
    build-setup-common (`git diff 631f8fb upstream-trunk --
    .github/actions/build-setup-common` is empty); fork_hosted.yaml uses the
    checked-out branch's action through `build-setup-common` → ubuntu, so the
    merged branch installs 21.1.8 with no fork edit; `CACHE_VERSION: 1` and
    `BAZEL_REMOTE_CACHE_KEY=github-action-ubuntu-22.04` are unchanged and
    upstream tests.yaml still runs `ubuntu-22.04`, so the read-only remote
    cache keys match. The fork's actions/cache key
    `LLVM-21.1.8-Cache-ubuntu-X64` is COLD on the fork: the first hosted run
    downloads the LLVM tarball (minutes beyond the 18-minute cache-hit budget
    of §8.1).
-   `AGENTS.md`, `.agents/skills/*`: upstream's.
-   `toolchain/install/BUILD`: upstream's `load("//bazel/cc_toolchains:
    make_include_copts.bzl", …)` plus the fork's `support_hdrs` target.

### §3 Commit structure (UA-1; UA-2 in §8.5)

1.  **Merge commit** `Merge upstream trunk c1e83b0b7 into the fork (183
    commits since 631f8fb)` — every textual AND semantic resolution of §2
    EXCEPT the F8d embedding's deletion, so the merge commit itself is meant to
    build (it deletes the fork's duplicate `case SemIR::FunctionType::Kind:`
    arm, §0.4 item 1, and nothing else of F8d); its message lists the class-C
    deletions with the superseding upstream commits (D-UA-10; D-UA-8 is
    deferred to 1b) and the class-B re-expressions by decision id, incl. the
    `is_choice` clause (D-UA-9), `MergeOverloadMemberRedecl` and the D-UN-6
    template clause (D-UA-6), the three fence components (D-UA-7) and the
    `GetCanonicalFacet` renames (§0.4 item 11).
    1b. **F8d retirement commit** `Retire the F8d constant-function-argument
    embedding (superseded by upstream #7789)` — the rest of D-UA-8's deletion
    list (`constant_function_args`, `InventConstantFunctionArg`,
    `TryMapFunctionType`, the `HasConstantFunctionArgs` branches, the thunk's
    constant-param plumbing, `GetOrExportFunctionDeclToCpp`), separately
    revertible per R-4's break condition (amended 2026-10-05, review fold: rev
    B B13). Must build on its own: the compile run is dispatched on the branch
    tip, so commit 1 alone is never compiled hosted — the implementer keeps
    commit 1 buildable by inspection (the fork's F8d code compiles against the
    merged tree only where it does not reference deleted upstream API; where
    it does, that reference moves into commit 1 with a note).
2.  **Reflow commit** `Reflow fork markdown to upstream's MD013 line length` —
    mechanical (D-UA-4), with this procedure (amended 2026-10-05, review fold:
    rev B B2 / B3 / B5): (a) record per-file heading counts per level for
    every `*.md` under fork/ and the four docs/design pages (`for l in 1 2 3
    4 5 6; do grep -c "^$(printf '#%.0s' $(seq 1 $l)) " <f>; done`) and the
    list-item count (`grep -c '^-   '`); (b) run the markdown hooks by id
    first — `SKIP=fix-cc-deps,check-build-graph,check-bazel-mod-deps uvx prek
    run rumdl prettier markdown-toc check-google-doc-style --all-files` — to a
    fixpoint; (c) `git diff -U0 | grep -nE '^\+#{1,6} [0-9]|^\+-   |^\+[0-9]+\.
    '` → each hit is rephrased so no line begins with `#NNNN` or a bare `*`
    (for example "PRs 12/13/14" or the reference moved after a word), and the
    pre-existing decision-log.md:5562 `## 7741 …` heading is repaired the same
    way; (d) re-run (b); (e) re-count (a) and diff — every file's heading
    counts per level and list-item count must be unchanged (the one allowed
    change is a count that the repair in (c) deliberately restores); (f) `uvx
    rumdl check` (post-fix, the R-9 falsifier) → the ~30 MD013 residue lines
    of D-UA-4 are rewritten by hand, then (d)-(f) again until `rumdl check`
    exits 0; (g) the full `SKIP=… uvx prek run --all-files`; (h) commit. The
    message records the hooks skipped locally (R22: the hosted gate is the
    authority for the bazel-backed ones) and the heading-count check's
    result.
3.  **Hosted fill commit(s)** — authored by the workflow ("Autoupdate testdata
    goldens on a GitHub-hosted runner"); expect pass 1 (fill) and pass 2
    (`.loc` convergence), R26.
    3b. **Retriage commit(s)** (amended 2026-10-05, review fold: rev B B4) —
    after EACH fill, before the gate is dispatched: read the autoupdate log
    for `Problems that require manual fixes:` (upstream #7877,
    testing/file_test/file_test_base.cpp:586; `GetFailPrefixProblems` :134,
    `noautoupdate_differs` :487) and turn every entry into a rename commit —
    the `fail_`/`fail_todo_` prefix added or removed on the file or split,
    with the upstream commit that flipped it in the message (R16(b) is
    satisfied: the cited cause is upstream's change, and the CHECK lines come
    from the fill, never by hand). fork_hosted.yaml's crash grep (`Stack
    dump:|CHECK failure|CARBON_FATAL`) does NOT catch these; in gate mode the
    same mismatch is an `ADD_FAILURE()`, so an un-retriaged `?` is a red gate
    round.
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

-   **Fill magnitude:** upstream moved 1091 goldens (amended 2026-10-05,
    review fold: rev B B1); the fork carries 237 new
    and 94 modified goldens whose CHECK lines were produced by the pre-merge
    compiler. Expect the pass-1 fill to touch most of the fork's 331 goldens
    (upstream's `Destroy` reshaping alone adds `SubobjectDestroy`/`SelfDestruct`
    entries to every `destroy` dump; #7768/#7804 change diagnostic type text;
    #7897 changes exported C++ names only for keyword-named functions — none in
    fork tests) plus the 71 taken-theirs conflicts (which re-acquire the fork's
    thunk/`Cpp.Exception`/overload lines). A fill touching a golden with NO
    fork mechanism and NO upstream change in its directory is the R-12
    falsifier.
-   **Pre-registered shapes:** fenced-thunk lower goldens keep
    `__clang_call_terminate` — the PRIMARY fence signal, 30 lower goldens
    carry it today (`grep -rl __clang_call_terminate toolchain/lower/testdata
    | wc -l` = 30) — and `personality ptr @__gxx_personality_v0` (also 30,
    secondary: it survives the loss of the `noexcept` spec; amended
    2026-10-05, review fold: rev A A3; R-5); upstream's function_ptr goldens
    GAIN them (D-UA-7); slice/buf lower golden keeps exactly one `free` per
    `Buf` (R-3); every choice golden with a `var` (D-UA-9's seven) gains an
    EMPTY `SubobjectDestroy.Op` define and a `SelfDestruct` call in place of
    its `_COp.<hash>:core.Destroy.Core` define — no stack dump, no new STDERR
    (R-17; rev A A1); the OV mangling `:overload<N>` and
    `_CF__carbon_thunk:overload<N>` lines are unchanged; the S3b
    generic-choice goldens (D-UA-10's pin family) move by `.loc` only (R-8);
    fail_fence_thunk_unbuildable.carbon stays a `fail_` with the SemanticsTodo;
    check/union/fail_modifiers_and_redecl.carbon keeps `DuplicateName` on
    `fail_class_then_union` and the `union D` pair (rev A A5);
    check/function/overload/fail_marker_mismatch.carbon keeps
    `OverloadMarkerMismatch` on both `fail_unmarked_second` and
    `fail_marked_second` (rev A A4).
-   **Autoupdate script** (amended 2026-10-05, review fold: rev B B4):
    upstream's `--build-mode` flag (#7809) is informational, but #7877's
    "Problems that require manual fixes:" list is NOT — autoupdate prints a
    `?` per test whose `fail_` prefix or NOAUTOUPDATE state no longer matches
    its result and does not fix them, fork_hosted.yaml's crash grep does not
    see them, and the subsequent gate fails on each. §3 commit 3b retriages
    them after each fill. Exposure is fork-side only (upstream added no new
    `fail_todo` golden or split in the range; it deleted two
    generic/template fail_todos because they now pass): the fork carries 14
    fork-added `fail_todo_*.carbon` goldens (check/testdata/choice/
    fail_todo_nontrivial_payload, function/overload/fail_todo_gates,
    let/fail_todo_{alternative_root, struct_pattern}, nine under match/,
    union/fail_todo_generic) and 45 fork-added `// --- fail_todo_*` splits.
    Pre-registered likely flips — the ones whose gate is an upstream
    mechanism that landed in the range: `fail_todo_template_dependent`
    (overload gate (xi); #7727 template lowering and the template-action
    series), `fail_todo_ref_param`/`fail_todo_param` (positional params and
    default values, #7651/#7837), `fail_todo_entry_point` (if #7800's default
    values reach `Run`), `fail_todo_generic_fn_as_callable`/
    `fail_todo_method_as_callable` (#7881 pointers to Carbon methods, #7789),
    and any split whose TODO text cites a `TryMergeRedecl` behavior (#7632/

    #7695). A flip to passing is retriaged by dropping the prefix; a flip
    the other way (a positive turning `fail_`) is a regression to root-cause
    first (R16(b)).

### §5 Conformance

-   **Bar (UA-1):** exactly `126 PASS / 0 FAIL / 23 SKIP over 149`, 47/56
    bullets — no program changes status in UA-1 (D-UA-12). Any program leaving
    PASS is a regression to be root-caused and fixed before merge; a fix that
    edits a PROGRAM is allowed only when the edit removes a construct upstream
    now rejects by design (R-11's redundant redeclaration), recorded in the
    decision-log entry with the upstream commit.
-   **Expected UA-2 delta** (each a probe, each reverted on failure; amended
    2026-10-05, review fold: rev B B8): SKIP → PASS candidates
    generics/templates_dependent_member.carbon, interop/
    cpp_template_symbolic_arg.carbon, interop/cpp_template_on_carbon_generic
    .carbon — three plausible probes, up to **129 / 0 / 20 over 149**;
    interop/inherit_multiple_bases.carbon STAYS SKIP (its cited blocker is
    unchanged at the tip, §0.6 W-046 row) and is not probed; the two Box(T)
    probes carry the return-type caveat of §0.6. Bullets 47 → up to 48 (row
    54 "importing C++ templates, instantiating on Carbon types" flips if both
    template probes pass; row 52 stays PARTIAL — dependent conversions still
    have residue). No new program in UA-1; UA-2 adds the W-108 pin
    program/golden (§0.6) and un-files W-108 only if the fill shows the field
    `free` (rev B B12: "uncertain; probe").
-   **R7:** no bullet text changes; `runner.py --self-test` at every commit.

### §6 Churn inventory

-   Sources resolved by hand (amended 2026-10-05, review fold: rev B B1 / rev
    A A2 / A4 / A5): 25 toolchain files (§0.3) + 6 class-C/semantic files that
    merged cleanly but lose code (export.h, type_mapping.{h,cpp},
    constant.cpp, overload_resolution.cpp, cpp/call.cpp, sem_ir/clang_decl.
    {h,cpp}; commit 1b) + merge.cpp (the D-UN-6 `if constexpr (IsClass)`
    clause, four lines) + class.cpp (D-UA-6 port) + custom_witness.cpp's two
    clean-hunk `GetCanonicalFacet` renames.
-   Goldens: 71 `--theirs`, 2 hand-merged, 1 deleted; ~331 fork goldens
    refilled; upstream's 1091 arrive as-is; plus the §3 commit-3b renames
    (expected: a handful of `fail_todo_` prefixes dropped).
-   Markdown: 34 fork-authored files reflowed (605 fixes), **~30 lines
    hand-rewritten** (D-UA-4's list; rev B B2), plus the `#NNNN`/`*`
    line-start rephrasings the heading-count check demands (rev B B3; at
    least ORCHESTRATION.md's `#12/#13/#14` paragraph and decision-log.md:5562).
-   Kept fork code rev 1 would have deleted (rev A A4): `MergeFunctionRedecl`
    → `MergeOverloadMemberRedecl` (~45 lines, handle_function.cpp).
-   Deleted fork code (class C): F8d embedding (~150 lines across six files;
    commit 1b), S3b publication (~90 lines across four files),
    `MergeClassRedecl`/`MergeOrAddName` copies (~100 lines), fork
    `MakeDestroyOpBody`/`BuildDestroyWitness` (~60 lines).
-   Added fork-local clauses in upstream code: `is_choice` early return in
    `MakeSubobjectDestroyOpBody` (D-UA-9), `is_union` flip check in
    `TryMergeRedecl` (D-UA-6), `EST_BasicNoexcept` + fence wrap + fence
    clause in thunk.cpp (D-UA-7), the function-pointer fence-unbuildable TODO
    in import.cpp (D-UA-7).
-   Diagnostics: no new kinds in UA-1 except the D-UA-7 TODO string (a
    `SemanticsTodo`, not a kind).

### §7 Risks and rejected alternatives (each with its falsifier)

Ranking (amended 2026-10-05, review fold: rev A A1): R-17 (choice destroy
under upstream's real subobject walk — decidable from the tree, and a
predictable crash costs a full hosted round while hiding the rest of the fill
behind the stack-dump gate) > R-1 (build breaks, now incl. §0.4 item 11) >
R-5 (silently disabled mechanisms, now incl. the `noexcept` spec) > R-3 >
R-4 > the rest. The pattern R-17 instances — an upstream mechanism becoming
REAL where the fork depended on it being inert — is re-checked for every
class-B item before the merge commit (rev A's "riskiest assumption"): the
implementer lists, per D-UA-6/7/9, which upstream function now DOES something
the fork's replaced code did not, and names the fork shape it first meets.

-   **R-17 Choice destroy under upstream's `MakeSubobjectDestroyOpBody`**
    (D-UA-9; rev A A1): without the `is_choice` clause every destroy of a
    payload-carrying choice — `Core.Result` included — hits a name-lookup
    error on `ChoiceDiscriminant` or the `CustomLayoutType` `CARBON_FATAL`.
    Falsifier: the fill on the seven choice goldens with `var`s, the nine
    match goldens, the 12 `Core.Result` goldens and the 31 conformance
    programs of D-UA-9; `grep -n is_choice toolchain/check/custom_witness.cpp`
    hits inside `MakeSubobjectDestroyOpBody` before the push. Mitigation: the
    clause is in the merge commit, not a fix commit.
-   **R-1 Build breaks the dry run cannot see** (§0.4 items 1-7, 9, 11).
    Falsifier: the first hosted `compile` run. Mitigation: §2 resolves each
    before the push; the implementer greps §8.4 before pushing. Note (rev B
    B11): `compile` mode builds only `-c opt //toolchain:carbon`; the
    merged toolchain/testing/file_test.cpp (OV-3 hunk beside upstream's
    file_test_base.cpp rework), toolchain/install/BUILD (`support_hdrs`
    beside the make_include_copts move) and every `_test.cpp` are first
    compiled by the autoupdate (fastbuild `//toolchain/testing:file_test`)
    and conformance (`//toolchain/install:carbon_toolchain_tar`) runs — a
    green `compile` does not prove them.
-   **R-2 Destroy witness reshaping changes fork symbols/goldens structurally**
    (`SubobjectDestroy`/`SelfDestruct` functions appear for every type the fork
    destroys; #7729 canonicalizes generated functions, so the fork's
    mangling-hint scope is gone). Falsifier: a fork lower golden's choice-copy
    or destroy `define` disappearing (not renaming) in the fill.
-   **R-3 Double or missing `free` for `Core.Buf`** (D-SL-16's declared-impl
    selection composed with `SelfDestruct` → `Op` + field walk). Falsifier:
    stdlib/slices_heap_buf.carbon status and the buf lower golden's `free`
    count; fix at the root (the selection or the field walk), never the test.
-   **R-4 F8d retirement breaks `std::thread(Carbon::Work)`** (amended
    2026-10-05, review fold: rev A A8 / rev B B13). Decidable parts, cited
    from the tree: type_mapping.cpp:287-305 maps the `FunctionType` argument
    to a `_Nonnull` pointer type for deduction; overload_resolution.cpp:134-150
    passes the non-const rvalue reference `ByVar`; thunk.cpp:476-506 casts the
    thunk parameter to an xvalue for an rvalue-reference callee parameter;
    convert.cpp:505-520 converts the `var` argument through
    `ExportFunctionToCppPointerConversion`. Residual unknown: the `_Nonnull`
    attribute's effect on `thread<void(*)()>(void(*&&)())` deduction.
    Falsifier: interop/cpp_thread_carbon_fn_diff.carbon (and the three
    sibling thread programs); break condition in D-UA-8 — `git revert` of
    commit 1b on a deduction signature in the residual, root-cause fix on
    anything else; the implementer does not re-add F8d on the first unrelated
    red.
-   **R-5 A fork mechanism silently disabled by a renamed hook.** The places
    this can happen without a build error (amended 2026-10-05, review fold:
    rev A A3 / A4): (a) the thunk declaration losing `EST_BasicNoexcept` in
    `CreateThunkFunctionDecl` — the catch-all + rethrow still emits a
    `personality` line, so the fence is gone with zero diagnostics and only
    `__clang_call_terminate` disappears — falsifier: `grep -rl
    __clang_call_terminate toolchain/lower/testdata | wc -l` ≥ 30 after the
    fill (the `personality` count is secondary), the `EST_BasicNoexcept` grep
    before the push, and the error_handling/cpp_exception_*.carbon programs;
    (a') `IsCppThunkRequired` losing the fence clause (a fence-required callee
    with a simple ABI gets no thunk at all) — falsifier: the same goldens and
    the §8.4 predicate grep; (b) the overload-set pre-step not reached because
    `BuildFunctionDecl`'s new `TryMergeRedecl` call runs first (a second
    `overload fn F` becomes a redeclaration error), or reached but missing
    the D-OV-3 marker-mismatch arm or the `ErrorInst` silent return —
    falsifier: check/function/overload/*.carbon goldens (fail_marker_mismatch
    .carbon's `fail_marked_second` in particular) and functions/overloading_*
    programs; (c) `HasClassKeyedImpl` no longer consulted by upstream's
    `CanDestroyClass` (a `Buf` leaks again) — falsifier: R-3's. Each is a
    grep in §8.4 plus a fill/scoreboard pin.
-   **R-6 `MergeOverloadMemberRedecl` rejected by review as a duplicate of
    `TryMergeRedecl<Function>`'s body** (amended 2026-10-05, review fold: rev
    A A4 — the inverse of rev 1's R-6, whose "two optional fields" design is
    withdrawn). Justification in one sentence: the member merge targets a
    specific set MEMBER with an explicit import IR id, which the template's
    prev-inst derivation cannot express (merge.cpp:707/:735/:782-797).
    Falsifier: a reviewer showing a template entry point that takes those
    four facts without a second code path — then D-UA-6's break condition
    applies and the function is deleted.
-   **R-7 Union declarations regress under the ported `TryMergeRedecl<Class>`**
    (`is_union` lost on redeclaration; `union`/`class` cross-redeclaration not
    diagnosed). Falsifier (amended 2026-10-05, review fold: rev A A5):
    check/testdata/union/fail_modifiers_and_redecl.carbon's
    `fail_class_then_union` and `fail_redefinition` splits keep their
    `DuplicateName`/redefinition diagnostics in the fill, and `grep -n
    is_union toolchain/check/merge.cpp` hits inside `TryMergeRedecl` before the
    push.
-   **R-8 Generic-choice specifics (S3b) misbehave under upstream's in-place
    initialization** (the recursion the fork's placeholder guarded now reads
    `NotConstant`). Falsifier: S3b goldens crash or change structurally; break
    condition in D-UA-10.
-   **R-9 rumdl reflow alters content** (amended 2026-10-05, review fold: rev
    B B2 / B3): measured on a copy — tables and fences untouched, but
    `#NNNN`/`*` tokens wrapped to a line start become headings/list items
    through MD018/MD004 on the second rumdl pass, and ~30 MD013 lines stay
    unfixable. Falsifier: per-file heading count per level or list-item
    count changed after the reflow (§3 commit 2 step (e)); `git diff -U0 |
    grep -nE '^\+#{1,6} [0-9]|^\+-   |^\+[0-9]+\. '` non-empty; `uvx rumdl
    check` not exiting 0 AFTER `--fix`. Each hit is rephrased, never
    reverted wholesale (D-UA-4).
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
-   **R-15 clang 21 toolchain on the hosted runner** (build-setup-ubuntu —
    not build-setup-common, amended 2026-10-05, review fold: rev B B10 — now
    installs 21.1.8 on ubuntu-22.04; upstream CI uses it, so the remote-cache
    keys match; the fork's LLVM tarball cache is cold on the first run).
    Falsifier: the compile run's setup step and its wall time.
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

1.  Push the staging branch with commits 1, 1b and 2 of §3. The staging
    branch must not touch fork/conformance/arbiter-request.txt or
    .github/workflows/fork_mirror_nightly.yaml unless the §8.2 A/B is intended
    (a push to `claude/**` touching either triggers the mirror; rev B B15).
2.  `Fork: hosted verification` mode `compile` (~18 min on a warm LLVM cache;
    longer the first time, R-15). Red → fix commits until green; every red is
    a §0.4/§7 confirmation recorded in the commit. Expectation only (amended
    2026-10-05, review fold: rev B B11): `compile` is `bazel build -c opt
    //toolchain:carbon` — a separate opt build that does not cover
    `//toolchain/testing:file_test`, `//toolchain/install:…` or any `_test`
    target, so the autoupdate run (fastbuild) and the conformance run (the
    install tarball) each compile new code; a red in THEIR build steps is
    still a §0.4 class of defect, not a fill defect.
3.  Mode `autoupdate` (~13 min; fails on any stack dump). Expect a large pass-1
    fill pushed back to the branch; then (amended 2026-10-05, review fold: rev
    B B4 / B15) read the run log for `Problems that require manual fixes:` and
    land the §3 commit-3b renames; dispatch a second `autoupdate` and expect a
    `.loc`-only pass 2 (or "No testdata changes"). A pass-2 structural diff
    stops the line (R26). **Push race:** the workflow pushes its fill with
    `git push origin HEAD:refs/heads/${GITHUB_REF_NAME}` from the dispatched
    SHA with no rebase, so NO push to the staging branch is made while an
    autoupdate or conformance run is queued or running — an interleaved push
    makes the workflow's push non-fast-forward and the fill is lost.
4.  Mode `gate` (~25 min: `uvx prek run --all-files` + `bazel test
    //toolchain/...`), dispatched only after the last autoupdate push and the
    retriage commits (a queued run pins its SHA).
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
    `v0.0.0-0.nightly.2026.10.02` exists (the fixes landed 10-01: #7879 at
    19:13Z, #7880 at 19:17Z).
-   **In the container** (amended 2026-10-05, review fold: rev B B6 — rev 1's
    `repositories/…` path is refused by the session's proxy with HTTP 403
    "Numeric-ID repository paths are not supported"; `repositories/{owner}/{repository}/…`
    works and lists `arbiter-v0.0.0-0.nightly.2026.09.28` as the newest
    mirror): `gh api repositories/jmann345/carbon-lang/releases/tags/arbiter-<TAG>` →
    asset id → `gh api -H "Accept: application/octet-stream"
    repositories/jmann345/carbon-lang/releases/assets/<id> > tc.tar.gz`, extract
    under /home/user/arbiter/, RECORD `<dir>/bin/carbon version` (the
    nightly's commit) in the matrix, then `python3 fork/conformance/runner.py
    --toolchain <dir>/bin/carbon --filter generics/templates_ --out
    <scratch>/ab-<tag>` and the same against
    `/home/user/arbiter/carbon_toolchain-0.0.0-0.nightly.2026.07.19/bin/carbon`
    (both PASS at the cut; the baseline).
-   **Nightly ≠ cut** (amended 2026-10-05, review fold: rev B B7): upstream's
    nightly builds at `cron: '0 2 * * *'` UTC and the mirror takes `gh release
    list --limit 1`; c1e83b0b7 (#7897) landed 2026-10-05 17:44Z and 8f258eaaa
    (#7889) 17:30Z, both after that day's 02:00Z build, so the 2026.10.05
    nightly is two commits short of the cut and any later nightly is past it.
    The weekly precedent already records the nightly's commit (decision-log
    .md:5612 "version f519ccc"); the matrix is read against THAT commit.
-   **Reading the matrix:** pure-upstream PASS + merged-fork PASS → the cut
    advances; pure-upstream PASS + merged-fork FAIL → a merge defect (fix in
    UA-1) — unless the nightly commit ≠ c1e83b0b7 and `git log
    c1e83b0b7..<nightly commit>` (or the reverse range) contains a fix for the
    signature, which reads "fixed after the cut" and is recorded, not fixed;
    pure-upstream FAIL likewise admits "regressed after the cut" when the
    nightly is past the cut; pure-upstream FAIL + merged-fork FAIL with the same signature → an
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
-   **Weekly Routine** (`Weekly upstream-merge check (carbon fork)`, which
    fires Mondays at 14:00 UTC — cron minute 0, hour 14, day-of-week 1; the
    expression is spelled out because rev 1's wrap split its code span and
    the `* * 1` tail became a list item, amended 2026-10-05, review fold: rev B
    B3 — next 2026-10-12): no prompt edit (D-UA-13); its first post-advance
    firing should report a small deferred set and no fork-modified overlap
    beyond the usual check-core files.
-   **Ledger:** W-001 gains a landed note (this flow); W-023 the superseded-
    mechanism note; the S3b/W-069 notes the D-UA-10 line; new residues per
    D-UA-15.
-   **Gap analysis:** header unchanged by UA-1; rows 52/54/40/43 re-cited in
    UA-2 (§0.6).

#### §8.4 Verification greps (before the first push, and at discharge)

(Amended 2026-10-05, review fold: rev A A1 / A2 / A3 / A4 / A5 / A10, rev B
B3 / B5 / B9; the long grep lines are split so none exceeds MD013's limit.)

-   D-UA-8 (after commit 1b): `grep -rn 'constant_function_args' toolchain`,
    `grep -rn 'HasConstantFunctionArgs' toolchain`, `grep -rn
    'InventConstantFunctionArg' toolchain`, `grep -rn
    'GetOrExportFunctionDeclToCpp' toolchain`, `grep -rn 'TryMapFunctionType'
    toolchain` → each empty.
-   D-UA-10/9/6: `grep -rn 'publish_block_id' toolchain/check`, `grep -rn
    'MergeClassRedecl' toolchain/check`, `grep -rn 'MergeOrAddName'
    toolchain/check`, `grep -rn 'MakeDestroyOpBody' toolchain/check` → each
    empty. `grep -rn 'MergeFunctionRedecl' toolchain/check` → empty, while
    `grep -n 'MergeOverloadMemberRedecl' toolchain/check/handle_function.cpp`
    → the definition plus exactly one call inside `TryMergeIntoOverloadSet`
    (rev A A4; rev 1's grep would have deleted the correct solution).
-   D-UA-9 (rev A A1): `grep -n 'is_choice' toolchain/check/custom_witness.cpp`
    → a hit inside `MakeSubobjectDestroyOpBody` (and the surviving W-071
    clause in `CanDestroyClass`); `grep -n 'CustomLayoutType'
    toolchain/check/custom_witness.cpp` → the `CanDestroyType` arm present.
-   §0.4 item 11 (rev A A2): `grep -rn GetCanonicalFacetOrTypeValue toolchain`
    → empty.
-   `grep -rn 'CalleeCppFunctionPointer' toolchain --include=*.cpp -l` and
    `grep -rn 'CalleeOverloadSet' toolchain --include=*.cpp -l` → the same
    file set (§0.4 item 5).
-   D-UA-7 (rev A A3): `grep -n EST_BasicNoexcept toolchain/check/cpp/thunk.cpp`
    → one hit inside `CreateThunkFunctionDecl`; `grep -n
    'IsCppThunkFenceRequired' toolchain/check/cpp/thunk.cpp` → called from
    `IsCppThunkRequired`, `BuildThunkBody`, `BuildCppCatchingThunk` and
    `PerformCppThunkCall`, with the `FunctionDecl*` overload declared in
    thunk.h; `grep -n 'fenced thunk' toolchain/check/cpp/import.cpp` → two
    TODO sites (`ImportFunctionDecl`, `ImportFunctionPointerInvoke`) (R-5a).
-   D-UA-6 (rev A A4 / A5): `grep -n 'TryMergeOverloadDecl\|TryMergeRedecl'
    toolchain/check/handle_function.cpp` → the overload decision precedes the
    template call (R-5b); `grep -n 'DiagnoseOverloadMarkerMismatch'
    toolchain/check/handle_function.cpp` → the definition plus two emit sites
    (set-path direction in `TryMergeIntoOverloadSet`, plain-direction in
    `TryMergeOverloadDecl`); `grep -n 'is_union' toolchain/check/merge.cpp` →
    the D-UN-6 clause inside `TryMergeRedecl` (R-7).
-   `grep -n 'HasClassKeyedImpl' toolchain/check/custom_witness.cpp` → called
    inside `CanDestroyClass` (R-5c).
-   `grep -n "github.repository == 'carbon-language/carbon-lang'"
    .github/workflows/*.yaml` → exactly six hits (auto_label_prs:22,
    check_dependent_pr:26, gh_pages_ci:25, gh_pages_deploy:27 and :76,
    nightly_release:40) (rev B B9).
-   §0.4 item 10 (rev A A10): `grep -nE '^\s*(overload )?fn \w+\(.*\);'
    fork/conformance/programs/functions/overloading_cross_library/geometry.impl.carbon
    fork/conformance/programs/code_org/library_multifile_export/geo.impl.carbon`
    → empty (no declaration-only `fn` in an impl file).
-   After the fill (R-5a; rev A A3): `grep -rl __clang_call_terminate
    toolchain/lower/testdata` lists ≥ 30 files (primary); `grep -rl
    'personality ptr @__gxx_personality_v0' toolchain/lower/testdata` lists
    ≥ 30 files (secondary).
-   Reflow (rev B B3): per-file heading counts per level and list-item counts
    unchanged before/after the reflow commit (§3 commit 2 step (e)).
-   `SKIP=fix-cc-deps,check-build-graph,check-bazel-mod-deps uvx prek run
    --all-files` → clean in the container (rev B B5; the three skipped hooks
    are the hosted gate's); `uvx rumdl check` → exit 0; `python3
    fork/conformance/runner.py --self-test` → OK.

#### §8.5 UA-2 (reconciliation PR) in one paragraph

Branch off the new trunk; per §0.6: un-SKIP probe commits for the three
plausible candidates (inherit_multiple_bases stays SKIP with the tip pin
cited in its W-046 note; amended 2026-10-05, review fold: rev B B8; one
hosted conformance per round; revert failures with the measured diagnostic
written into the SKIP line, R10); the W-108 pin golden (+ lower twin) and,
only if the fill shows the field `free`, the W-108 discharge (rev B B12);
ledger notes for W-023, W-014 (re-cited to upstream's generic/template
goldens and handle.cpp:400, rev B B12), W-043, W-046, W-037, W-030, W-083,
W-091, W-065; gap rows 40/43/52/54/89 re-cited; residues from D-UA-15 filed
with file:line (incl. the function-pointer fence TODO and the choice-payload
destroy synthesis); the decision-log entry "Upstream reconciliation 2026-10
(UA-2)". Bar: non-regression from the UA-1 floor; expected up to 129 / 0 /
20 over 149 (§5). Two plan reviews are
not repeated for UA-2 (R29(c): its plan is this section); one implementation
review once hosted verification is green.

### Hand-off notes for the implementer

1.  **Setup.** Work only in `/home/user/carbon-upstream` on
    `claude/carbon-fork-0-1-upstream-advance` (HEAD = this plan's rev 2
    commit on top of trunk 923c2f2af; `upstream-trunk` = c1e83b0b7). Never touch `/home/user/carbon-lang`, `/home/user/carbon-sl2`
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
    that merged cleanly (merge.cpp's D-UN-6 clause, class.cpp, custom_witness
    .cpp's two `GetCanonicalFacet` renames, cpp/call.cpp and eval.cpp `Callee`
    switches; the F8d files — export.h, type_mapping.{h,cpp}, constant.cpp,
    overload_resolution.cpp, cpp/call.cpp, clang_decl.{h,cpp} — are commit
    1b's, except the duplicate `case`). Run the §8.4 greps. Local prek
    (amended 2026-10-05, review fold: rev B B5): upstream's
    `.pre-commit-config.yaml` arrives with three bazel-backed hooks —
    `fix-cc-deps` (`files: ^.*/(BUILD|[^/]+\.(h|cpp))$`, runs `bazel query`),
    `check-build-graph` (`bazel build --nobuild //...`) and
    `check-bazel-mod-deps` — all through `scripts_utils.locate_bazel()` →
    `run_bazelisk.py` (no bazelisk on PATH; `/root/.cache/bazel` holds the
    OLD llvm pin), and the merge moves MODULE.bazel's llvm-project commit
    a6b0af7 → 6ec87e7 and adds `libxml2`/`xz`, so the first such hook run
    would fetch a multi-GB external repository into the 30 GB container. The
    touched set necessarily includes BUILD, .h and .cpp files, so: always
    `SKIP=fix-cc-deps,check-build-graph,check-bazel-mod-deps uvx prek run
    --files <every touched non-testdata file>` to a fixpoint (R22: the hosted
    gate is the authority for those three); clang-format 21.1.8 is the pin
    (the container's distro clang-format is NOT the arbiter, R18 — prek
    fetches the pinned one). Commit the merge with the §3 author/committer
    rules and trailers; record the skipped hooks in the message. Then commit
    1b (F8d) with its own §8.4 greps.
3.  **Reflow.** Follow §3 commit 2's procedure (a)-(h) exactly: heading and
    list counts before, markdown hooks by id with the SKIP list, the
    `#NNNN`/`*` line-start grep and rephrasings, re-count, the ~30 MD013
    hand-rewrites measured by `uvx rumdl check` AFTER `--fix`, then the full
    `SKIP=… uvx prek run --all-files`; inspect `git diff --word-diff --stat`
    and spot-check the decision log's tables; commit (amended 2026-10-05,
    review fold: rev B B2 / B3 / B5).
4.  **Push** `git push -u origin claude/carbon-fork-0-1-upstream-advance` and
    hand the orchestrator the list of §7 falsifiers to watch in the compile
    log first (§0.4 items), then in the fill. After the push, no further push
    while a hosted run is queued or in progress (§8.1 push race, rev B B15).
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
    the merged tip passes the two template probes (§0.5); whether the
    `_Nonnull` attribute perturbs `std::thread`'s deduction — the only
    residual of R-4 after rev A A8's citations (amended 2026-10-05); whether
    `SelfDestruct` + D-SL-16 yields exactly one `free` (R-3); the exact fill
    size and which `fail_todo` splits flip (§4); whether any x-macro order
    test fails (R-10); whether the W-108 field-destroy claim holds (§0.6).
    Each is pre-registered with its falsifier so the hosted runs answer it,
    not an agent's assertion. What rev 1 wrongly filed here and rev 2 decided
    from the tree: the choice-destroy crash (D-UA-9, rev A A1), the four knobs
    of the member merge (D-UA-6, rev A A4), the fence's `noexcept` spec
    (D-UA-7, rev A A3) and the reflow's heading damage (D-UA-4, rev B B3).

### Review fold record (rev 2, 2026-10-05)

Every finding of the two rev 1 reviews (rev A: fork-mechanism fidelity,
REJECT — 1 BLOCKER, 4 MAJOR, 5 MINOR; rev B: mechanics/verification,
APPROVE-WITH-AMENDMENTS — 5 MAJOR, 10 MINOR) and where it was folded. The
fixer re-opened every cited location (fork tree at HEAD 5f65f35ba, `git show
upstream-trunk:<path>`, the merged tree f2c06b2ae from `git merge-tree
--write-tree HEAD upstream-trunk`; the rumdl experiment re-run on a copy
under the scratchpad) before folding; every finding reproduced, so none is
declined. One extra instance of B3's damage was found while verifying and is
recorded for the reflow commit (decision-log.md:5562 at HEAD).

| Finding | Disposition |
| --- | --- |
| rev A A1 (BLOCKER): D-UA-9 as written crashes/mis-diagnoses every destroy of a payload-carrying choice (`Core.Result` incl.) — upstream's `MakeSubobjectDestroyOpBody` walks `[ChoiceDiscriminant, ChoicePayload]` through `PerformMemberAccess`, has no `CustomLayoutType` arm; the fork's `CanDestroyType` arm never answers `Trivial` | folded: D-UA-9 rewritten (path traced with citations; `is_choice` early return in the `ClassType` arm as the single clause, alternative (ii) rejected under R17 and parked for UA-2; the fork's `CanDestroyType` `CustomLayoutType` arm named as a must-survive; pins: 7 choice goldens with `var`s, 9 match goldens, 12 `Core.Result` goldens, 31 conformance programs; payload_layout.carbon `_COp` defines → `SubobjectDestroy`/`SelfDestruct` pre-registered), §0.3 row, §2.2 (a)-(c) incl. the `is_union` second-clause contingency, §4 shapes, §6, §7 ranking + new R-17 at the top, §8.4 `is_choice`/`CustomLayoutType` greps, D-UA-15 residue, §0.6 W-083 row, hand-off 6 |
| rev A A2 (MAJOR): `GetCanonicalFacetOrTypeValue` → `GetCanonicalFacet` (#7813) survives in two clean-merging fork functions (merged :1557/:1613, outside all five hunks) | folded: §0.4 item 11, §0.3 row, §1 order, §2.2, §6, R-1, §8.4 grep, §3 commit-1 message, hand-off 2 |
| rev A A3 (MAJOR): the fence IS the `EST_BasicNoexcept` spec on `CreateThunkFunctionDecl` (fork :666-671; upstream :429-475 has none, inside a conflict hunk); the `personality` falsifier cannot see its loss; `ImportFunctionPointerInvoke` never calls `IsCppThunkRequired` | folded: D-UA-7 rewritten as three fence components with (1) the spec first and the function-pointer analysis; §2.4; §4 shapes (`__clang_call_terminate` primary, `personality` secondary); R-5 (a)/(a'); §8.4 `EST_BasicNoexcept` grep and the `__clang_call_terminate` ≥ 30 count |
| rev A A4 (MAJOR): D-UA-6's function half not implementable (four knobs, member-targeted merge vs the template's prev-inst derivation, merge.cpp:707/:735/:782-797) and drops D-OV-3's marker-mismatch rule and the `ErrorInst`-localized set's silent return | folded: D-UA-6 function half rewritten with the break-condition branch primary — `MergeFunctionRedecl` kept as `MergeOverloadMemberRedecl`, the fork's full four-step decision as `TryMergeOverloadDecl` before upstream's template, no `MergeRedeclEntityInfo` fields; pins fail_marker_mismatch.carbon `fail_unmarked_second`/`fail_marked_second`/`fail_plain_redecl_unchanged`; §0.3 row, §2.3, §4 shapes, §6, R-5(b), R-6 inverted, §8.4 greps fixed (`MergeFunctionRedecl` → empty but `MergeOverloadMemberRedecl` → def + one call; `DiagnoseOverloadMarkerMismatch` → two emit sites) |
| rev A A5 (MAJOR): the `class`/`union` flip check (fork class.cpp:137-144) has no home — upstream's `TryMergeRedecl<Class>` merges any `ClassDecl`/imported class; import resolution is in the `static` `FillPrevEntityInfo`; post-hoc is too late | folded: D-UA-6 class half — an `if constexpr (IsClass)` clause after the `prev_entity` lambda (merge.cpp:811-823), four lines commented D-UN-6; pin fail_modifiers_and_redecl.carbon `fail_class_then_union` + `fail_redefinition`; §0.3 row, §2.3, §4 shapes, §6, R-7, §8.4 `is_union` grep |
| rev A A6 (MINOR): §0.4 item 7 cites thunk.cpp:1215 (a comment); real deps :1146 (`CalleeFunctionInfo` ctor, in-hunk) and the decl-taking `IsCppThunkFenceRequired` calls at :1110/:1607 | folded: §0.4 item 7 rewritten; D-UA-7 and §2.4 keep a `FunctionDecl*` overload; §8.4 predicate grep lists four callers |
| rev A A7 (MINOR): fence-unbuildable TODO not carried to the function-pointer path (upstream import.cpp:2157 `DefineAsThunkCall` unconditional; lower/handle_call.cpp:784-789 calls the pointer directly) | folded: D-UA-7 decision (TODO + `ErrorInst` on the pointer path, keyed on `IsCppThunkFenceRequired(function_type, nullptr)`), §2.4, D-UA-15 residue, §8.4 "fenced thunk" two-site grep |
| rev A A8 (MINOR): R-4 is decidable — cite type_mapping.cpp:287-305, overload_resolution.cpp:134-150, thunk.cpp:476-506, convert.cpp:505-520 | folded: D-UA-8 narrower break condition (revert only on a `_Nonnull`/`void (*&&)()` deduction signature), R-4 rewritten, hand-off 6 |
| rev A A9 (MINOR): D-UA-10's pin glob misses generic.carbon, fail_generic_payload.carbon and the match/ pair; `TryEvalBlockForSpecific` (eval.cpp:3530-3575) confirmed sound | folded: D-UA-10 pin family enumerated (plus the two other S3c match goldens), soundness note recorded; §4 |
| rev A A10 (MINOR): §0.4 item 10's grep should be recorded | folded: §0.4 item 10 note, §8.4 grep (empty at HEAD, verified) |
| rev A "items checked and found correct" (§0.1/§0.2 counts, §0.5, D-UA-3, D-UA-11, `Callee` switches, W-108 trace, scoreboard, min_prelude, R28, the optional pre-merge refactor) | recorded; the pre-merge fork-side refactor is named in §0.8 as the one decomposition not taken, with the reason |
| rev B B1 (MAJOR): golden conflicts are 74 (73 UU + 1 UD), not 79; 71 refill-only, not 77; 31 non-testdata = 25 sources + words.md + 5 editor files; upstream source-edited 33; upstream testdata 1091 | folded (reproduced from merge-tree + the indentation-aware diff over the 74 paths): §0.1 two rows, §0.3 goldens paragraph, D-UA-3, §0.8, §2.7, §4, §6 |
| rev B B2 (MAJOR): after `rumdl --fix` ~30 MD013 lines in 13 files remain and `rumdl check` exits 1 | folded (reproduced exactly: 30 lines, 13 files + functions_overloading.md:646, exit 1): D-UA-4 residue list and budget, §3 commit 2 step (f), §6, R-9, §8.4, hand-off 3; this plan's own offending §8.4 line split in rev 2 |
| rev B B3 (MAJOR): reflow manufactures headings/list items from `#NNNN`/`*` at line start (ORCHESTRATION.md H3 5 → 1, H4 0 → 5; plan.md's own `## 7784…`/`## 7689…` and the cron `* * 1`) | folded: plan.md §0.2 and §8.3 repaired (PR refs as bare numbers; cron spelled out); D-UA-4 token-damage paragraph with the probe result; §3 commit 2 steps (a)/(c)/(e) heading-count-per-level check; R-9 falsifier extended; §8.4; decision-log.md:5562 `## 7741 …` found at HEAD and assigned to the reflow commit; rulebook **R31** allocated (fork/rulebook.md) |
| rev B B4 (MAJOR): #7877's "Problems that require manual fixes" (`fail_` prefix / NOAUTOUPDATE mismatches) are not caught by fork_hosted.yaml's crash grep; the gate fails on them | folded: §3 commit 3b retriage step before each gate dispatch (R16(b) satisfied by citing the upstream cause), §4 autoupdate paragraph with the fork's 14 fail_todo goldens / 45 splits and the pre-registered likely flips, §8.1 step 3 |
| rev B B5 (MAJOR): `uvx prek run` in the container triggers bazel-backed hooks against the new llvm pin | folded: hand-off 2/3 `SKIP=fix-cc-deps,check-build-graph,check-bazel-mod-deps`, markdown hooks by id for the reflow commit, skipped hooks recorded in the message; §3 commit 2 (b)/(g); §8.4 |
| rev B B6 (MINOR): `gh api repositories/...` is refused (403 Numeric-ID) | folded (reproduced): §8.2 uses `repositories/jmann345/carbon-lang/...` |
| rev B B7 (MINOR): nightly ≠ cut (02:00Z build; #7889/#7897 landed 17:30Z/17:44Z) | folded: §8.2 records `carbon version`, "nightly ≠ cut" paragraph, matrix reading admits "fixed/regressed after the cut" |
| rev B B8 (MINOR): inherit_multiple_bases un-SKIP speculative (base.carbon:152 unchanged at tip); Box(T) return-type caveat | folded: §0.6 W-046 and W-043 rows, §5 (129/0/20, three probes), §8.5 |
| rev B B9 (MINOR): guard grep covers two of six | folded: §2.8 lists all six; §8.4 expects six hits |
| rev B B10 (MINOR): LLVM bump is in build-setup-ubuntu, not build-setup-common; cold tarball cache | folded: §2.8, R-15, §8.1 step 2 |
| rev B B11 (MINOR): `compile` mode is a separate opt build of `//toolchain:carbon` only | folded: R-1 note, §8.1 step 2 (expectation only; no CI change) |
| rev B B12 (MINOR): W-014 evidence cites a deleted file; W-108 "plausibly discharged" overstated | folded: §0.6 both rows, §5, §8.5 |
| rev B B13 (MINOR): F8d deleted before its replacement is evidenced | folded: §3 commit 1b (separately revertible), D-UA-8, R-4, §6, hand-off 2 |
| rev B B14 (MINOR): decisions at §0.7 vs the template's §0.3 | folded as the one-line note in the header (renumbering rejected: §0.3 is cited as the conflict table throughout) |
| rev B B15 (MINOR): push race with the workflow's un-rebased push; arbiter-request.txt trigger | folded: §8.1 steps 1 and 3, hand-off 4 |
| rev B "checks that passed" (measurements except B1, §0.4 spot checks, `--dump-sem-ir-ranges`, `.rumdl.toml` verbatim, gate runtime, scoreboard/SKIP list, runner flags) | recorded |

### Sign-off

-   Correctness review (rev 1, rev A): REJECT — folded as rev 2; focused
    re-review of rev 2 _pending_ (R29(c): a REJECT requires it)
-   Strictness review (rev 1, rev B): APPROVE-WITH-AMENDMENTS — folded as rev 2
-   Coordinator sign-off for implementation: _pending_
