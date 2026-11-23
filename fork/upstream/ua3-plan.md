<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# UA-3 plan: upstream advance, cut c1e83b0b7 → 7a3608bab (196 conflicting files)

**Status:** rev 2 (2026-11-23; reviews A and B folded, 18 findings, see "Review
fold record (rev 2, 2026-11-23)" before the Sign-off; NOT signed off, the
re-review decides). Rev 1 (2026-11-17; measured 2026-11-16) was written by the
planner after the four audits (toolchain/check; lower, sem_ir, parse, lex, base,
diagnostics, driver, core; goldens and conformance; docs, records, utils,
.github) and after the prototype merge was built, filled, gated and measured by
the container arbiter (label `ua3-proto`, worktree /home/user/carbon-ua3-proto,
kept for the reviews). Every number below is measured on the prototype or by
`git` unless it is marked "predicted"; the prototype is evidence, not the
product: the implementer redoes the merge on `claude/carbon-fork-0-1-ua3` from
§2 and §3, and reads the prototype's resolutions.tsv and
resolution-vs-upstream.patch as the reference (hand-off note 1). Sibling of
fork/upstream/plan.md (UA-1, the merge 631f8fb → c1e83b0b7 of 2026-10-06, and
UA-2, its reconciliation), whose decisions D-UA-1 to D-UA-15 stand; this plan's
decisions are D-UA3-1 to D-UA3-18 (§1). Branch `claude/carbon-fork-0-1-ua3` in
the worktree /home/user/carbon-ua3, cut from trunk 701863aa5 (2026-11-16, "Merge
trunk 50357c591 into arb3-fix", no commit of its own before this plan); trunk
has since moved to a9892d4bb ("Land PR 71: records", TP-2 landed, 2026-11-16
21:16 UTC), the prototype's base, and on 2026-11-23 to cb7821735 ("Merge trunk
db7d28397 into arb5-fix": ARB-5's landing and the weekly check of 2026-11-23);
the merge's base is trunk as it stands at T (D-UA3-1; the dry run against
cb7821735 conflicts in the same 194 paths, §0.1; amended 2026-11-23, review
fold: A-m3 / B-B1 / B-M2). The upstream tip is
7a3608bab265e5716f174487ef7b18c134d728d2 (2026-11-14T07:06:28Z, "Bump
addressable from 2.9.0 to 2.9.1 in /website in the bundler group across 1
directory", PR 8132), the tip the weekly upstream checks of 2026-11-09 and
2026-11-16 anchored the direction register to, 197 commits past the cut. The
weekly check of 2026-11-23 (6bde6699d and db7d28397, on trunk since cb7821735)
re-anchored the register's quotes and L counts to upstream's tip of that day,
0072b2812, 21 commits past 7a3608bab (W-355's method: the register's anchor runs
ahead of the cut; D-UA3-15 reads the anchor from the latest weekly entry;
amended 2026-11-23, review fold: B-B1 / A-m3).

**The non-regression bar.** Trunk a9892d4bb's container-measured record (PR
71's landing, fork/ORCHESTRATION.md's Scoreboard paragraph): gate 2047 of
2047, conformance 226 PASS / 0 FAIL / 15 SKIP over 241 programs, 51 of 56
bullets. The task's bar, label tp2-base (gate 2047 passed, 0 failed;
conformance 228 / 0 / 13 over 241, 51 of 56), is trunk BEFORE TP-2's landing:
the two programs between the two lines, generics/templates_deduce_class_args
.carbon (W-396) and generics/templates_match_dependent_choice.carbon (W-397),
are TP-2's own SKIP withdrawals (D-TP2-2), present at a9892d4bb and absent at
701863aa5. The merge changes no program's status (§5).

**Items:** W-354, W-356, W-360 to W-363, W-372, W-394 (ORCHESTRATION's Next
actions item 6, "In UA-3's gate"), W-378 (kept or dropped), W-355's
re-anchoring of the register after the cut moves, and the audit tasks item 6
names (57bf903ef, 4abb6100e, c7de72757 and 9799a2326, 05a7ecbd3's
string.carbon:154 site, 4286832b4, c0b2cc592, 54728e47f, e67b6db91). Not
UA-3's: PR 53 (SAFE-1, held at 2407efa74 under R33 (c); it takes UA-3's trunk
afterwards by a merge commit — R32 (e): a held PR is amended by a new commit
on its branch, never by rewriting it — where W-395 and the C++ boundary
question resume; the citation added 2026-11-23, review fold: B-m6) and W-374
(TP-2, landed as PR 71 before this plan; its Landed note is
in fork/templates/tp2-plan.md). **Design authority, not reopened:** F-002
(the staging merge, built and measured by the container arbiter before it
lands), standing rules 5 and 7 of fork/process.md, R16 (goldens only by
autoupdate), R17, R26, R28, R30, R32 (no direction drift: upstream's spelling
is the design's), R33 (the owner's merge directive; (b) the arbiter's measured
lines; (c) no unfinished realignment is merged). Every decision below is an
R29 (a) implementation choice, veto-able after the fact.

## Sections

§0 audit (0.1 measurements, 0.2 the window by subsystem and the take-list,
0.3 the conflict classification, 0.4 the silent breakages, 0.5 the
prototype's measured lines, 0.6 the ledger items and gap rows the advance
moves, 0.7 the register at the tip, 0.8 the id re-scan); §1 design and the
decisions D-UA3-1 to D-UA3-18; §2 the spec, file by file; §3 the commits; §4
testdata; §5 conformance; §6 churn; §7 risks and rejected alternatives; §8
verification and discharge; hand-off notes; Appendix A the texts verbatim
(commit messages, the decision-log entry, ORCHESTRATION, ledger notes, the PR
text, LAND-1's texts with `<...>` placeholders, and A.12 the register and plan
lines the records commit edits); Appendix B the 123 goldens, one row each;
Appendix C the prototype's artefacts and rev 2's re-measurement (label
ua3-fixer); the review fold record (rev 2, 2026-11-23) before the Sign-off.
Risks are K-1 to K-16 (rev 1 called them R-1 to R-14, colliding with the
commits R-1 to R-5; renamed 2026-11-23, review fold: B-m7).

## §0 Audit: what the merge is made of

### §0.1 Measurements (git; verified 2026-11-16 at 701863aa5 and a9892d4bb)

| Quantity | Command | Value |
| --- | --- | --- |
| The cut | `git merge-base 701863aa5 7a3608bab` | c1e83b0b78b6bf648661f4c448c01f11d74af115 (2026-10-05, PR 7897; UA-1's tip) |
| Commits since the cut | `git rev-list --count c1e83b0b7..7a3608bab` | **197** |
| Commits since each weekly tip | `git rev-list --count c1e83b0b7..<tip>` for 62f1cc6a3 (10-12), 3056e7e31 (10-19), 21c825a3f (10-26), 68569d234 (11-02), ca1898506 (11-09), 7a3608bab (11-16) | 36, 85, 117, 150, 176, 197 past the cut; so 161, 112, 80, 47, 21 and 0 commits past each weekly tip |
| Fork commits since the cut | `git rev-list --count c1e83b0b7..701863aa5` | 399 (392 at f54ddc64d, the 11-16 weekly's trunk) |
| Upstream files changed | `git diff --name-only c1e83b0b7 7a3608bab \| wc -l` | **2140** (1451 under testdata/) |
| Fork files changed | `git diff --name-only c1e83b0b7 701863aa5 \| wc -l` | 1251 |
| Upstream deletions | `git diff --name-only --diff-filter=D c1e83b0b7 7a3608bab` | 11: .github/workflows/proposal_labeled.yaml and proposal_ready.yaml; bazel/llvm_project patches 0002, 0004, 0005, 0006; toolchain/check/testdata/interface/fail_incorrect_destroy_method_declarations.carbon (fork-untouched); toolchain/diagnostics/consumer.cpp and diagnostic.cpp; toolchain/sem_ir/identified_facet_type.{cpp,h} (fork-modified: the two modify/delete conflicts) |
| Upstream renames | `git diff --name-status -M --diff-filter=R c1e83b0b7 7a3608bab \| wc -l` | 0 |
| Dry run at 701863aa5 | `git merge-tree --write-tree --merge-base=c1e83b0b7 7a3608bab 701863aa5` | exit 1, tree 13718d872, **196** conflicting paths: 73 sources and records (69 toolchain, 2 editor grammars, 1 docs page, 1 workflow) and 123 goldens (check 69, lower 50, parse 3, driver 1: Appendix B's rows; rev 1 wrote 77 and 42, corrected 2026-11-23, review fold: B-m1); the 2026-11-16 weekly's set against f54ddc64d (tree d96b49e25, records-only commits between) |
| Dry run at a9892d4bb (the prototype's base) | same command against a9892d4bb | exit 1, tree 1b3b1e00d, **194** paths: the 196 minus check/testdata/generic/template/convert.carbon and lower/testdata/template/class.carbon, which TP-2's refill brought to upstream's text (`diff` of the two listings) |
| Dry run at cb7821735 (trunk on 2026-11-23: ARB-5's landing and the weekly check of 2026-11-23, both records and fork/tools only) | same command against cb7821735 | exit 1, tree eac60b2d3, the same **194** paths (`diff` of the sorted path lists empty; the weekly check's own dry run against a9892d4bb read 194 too, tree 98b2c04d2) (added 2026-11-23, review fold: B-B1) |
| Marker counts | `++<<<<<<<` per file in the dry-run tree | 1085 in the goldens; per source file in §0.3 |
| Test manifest | gen_ninja.py's `file_test manifest: N test files` in the build logs | 2047 at a9892d4bb (label tp2-base), **2114** on the prototype (`+67`: upstream's new test files minus its one deleted golden; .carbon files under toolchain/*/testdata: 2074 → 2143) |
| LLVM pin | `MODULE.bazel` | 6ec87e7ec4b3 at the cut and at a9892d4bb; **c744694c6ae1** at 7a3608bab (9a4d4b332 then a567040d7); the arbiter's second LLVM build (ARB-4) is at that pin |

The clone is shallow for upstream history (no merge base is found for
701863aa5 and 7a3608bab without `--merge-base=c1e83b0b7`); every dry run
passes it. The upstream remote `upstream` was fetched at the audits' start
(2026-11-16 17:12 UTC) and the tip was unchanged at the prototype's merge
(21:52 UTC).

### §0.2 The 197 commits by subsystem, and the take-list

By the directory each commit touches most (`git log --name-only`, one key
per commit; the full list is the planner's window-subsystem.txt): check 55,
check testdata 41, benchmarking 15, .github 13, lex 9, parse 8, sem_ir 8,
lower testdata 6, common 6, docs/design 5, proposals 4, utils/textmate 4,
utils/vscode 3, base 3, docs/project 2, github_tools 2, and one each for
website, autoupdate_testdata.py, MODULE.bazel, utils/vim, parse testdata,
testing, language_server testdata, driver, utils/nvim, scripts, lower,
toolchain/docs. In the fork's terms:

1.  **Destruction (W-354):** 05a7ecbd3 moves `SubobjectDestroy` and
    `SelfDestruct` out of interface `Destroy` (PR 7942): `Destroy` is a
    constraint `SubobjectDestroy & DestroyImpl`, the declared destructor
    interface is `DestroyImpl`, `SelfDestruct` is a free function, the custom
    witness serves `SubobjectDestroy` only; f396762e2 destroys function-local
    `var`s of choice types (PR 7941); 947c1eb52 adds the `Core.Array` class
    (PR 7892, `array(T, N)` an alias) with `CanDestroyArray` for adapters of
    arrays.
2.  **Struct patterns and global `let`s (W-372, W-069):** c6b54b57e (PR 7876,
    the check layer for `let`/`var`), 5ae3dcaa9 (PR 8074, `,`? after `_` and
    the `PatternListUnderscoreField` node), d50576ca1 (PR 8061, references to
    global `let`s and enclosing locals: `GlobalRef`, `ClassScopeLetDecl`, an
    `AliasBinding` for a parameterless choice alternative, `LocalState::in_
    global_init`, `FileContext::GetOrCreateGlobalBinding` and
    `Mangler::MangleGlobalBinding`, which supersede W-069's lane a1), 19f1bf94d
    (PR 8101, one `GlobalVariable` per lowered variable across files).
3.  **Templates and actions (W-394, W-258, TP-2's context):** dbf02ad10
    (PR 8122, upstream's `AddrOfAction` under TP-1's name), 4286832b4 (PR 8106,
    `OperandDependence` on `const SemIR::File&`), 4a8993af2 (PR 7900,
    `InitializeAction::Target::storage_access_block_id`), 230227264 (PR 7886,
    return storage only for a return parameter), 57bf903ef (PR 7957, the
    resolution loop: `CheckRequiredDefinitions` returns `bool`,
    `ResolveSpecificDefinition` returns `DefinitionResolution`), 9fb428d71
    (PR 8040, `RequireSpecificDefinition` removed), 04f456ddd and 559602b9e
    (PRs 8010 and 7920, `FindStorageArgForInitializerInSpecific`), be0f11be9
    (PR 8062, a generic scope around `where` expressions), 73c247f1e
    (PR 7925, `ImportIncompleteClass` moved), 62f1cc6a3 (PR 7953,
    `GenericClassType` renamed `ParameterizedClassType`), 30318f87f (PR 8055,
    `StableStack`).
4.  **Default values and return forms (W-360 to W-363, W-037):** 503f09037
    (PR 8011, defaults for non-generic parameters of generic functions),
    9799a2326, c7de72757 and 8fdc8ebc3 (PRs 7988, 8019, 8025, default values
    exported to C++), 1b0a5709e, b766aa4d1 and f83518bfd (PRs 7893, 7895,
    7894, fn expressions and terse `=>` bodies; `CheckDefaults` moved to
    function.cpp), bf5d2a2ac, 3af25cc1b, 0d3b606a5, 9fd28f730, e588469fd,
    1c69fe344, 14a3de9ff, 059ee7b9e, 1429d1566 (deduced and value return
    forms, lowering's `ReturnKind`).
5.  **Facets and impls (SC-1's ground):** fb7eff130 and ac31fd198 (PRs 8004,
    8008, `IdentifiedFacetType` moved to check/ with a new API; the sem_ir
    pair deleted), b1de0e037 (PR 7926, `TypeId` to the identify functions),
    a83e1d837, 5402b4c56, e39bdb7af, e41862d55, f0bae9637, 24766e213,
    eb66bebc3, 2b5f90cd7, f44cfa578, f0e3d04d0, 77fc0a3ef, fea77fe59,
    3a1db6633, f0b030f2c, 46e7eacba, 6a0a1f3e8, 71af20740, 831a2aee9,
    bf91a8b4d, 505c4ae30, 6c1d2a86e, 4441c5340, e1c8c1f85, 893cce070 (the
    `require`/witness-table series; `CheckRequireDeclsSatisfied` rewritten on
    `Check::IdentifiedFacetType`, `SubstImplSelfWitnesses` deleted).
6.  **C++ interop:** 54728e47f (PR 8123, `ExportNameScopeToCpp` handles a
    parameterized class; the class-export functions moved), 4abb6100e
    (PR 8060, exported thunks defined in Clang's LLVM function), 5c9ab26d7
    (PR 8022, `linkonce_odr` thunks), d99b767dd (PR 8021, fields exported),
    66f03aecb, 6f6a01f85, 56d9bbc40, ca1898506, bb6486b55, 54f37b35b,
    2e2125585, 3dbf76af0, e476a2bd3, f9c21d769, 09b79784d, d08805f1a,
    4ab46d448, 11b5c2924, 72abc7a46, ae5d1efd1 (PR 7899,
    `CppCalleeFunctionInfo`), 66a250ad9 (PR 7958, importing
    `CustomLayoutType`), 08b752e88, 04443a9a1.
7.  **Diagnostics and textual SemIR:** 2c9739799 (PR 7683, rendering through
    the terminal library: `Note` and `Context` levels removed, `CARBON_
    DIAGNOSTIC_LABEL`/`CARBON_DIAGNOSTIC_CONTEXT` and `Attach`), c608c35e1,
    fda41783e, d0badecd2 (PR 8070, tests use the rendered form), 68569d234
    (PR 7990, lexer and parser locations), 7beb29f8b, d87891f3a, e67b6db91
    (PR 8104, shorthand file names in textual SemIR), 92534a0e0 (PR 8105,
    `InstNamer`s cached), 72068410c, 5b587a885.
8.  **Prelude and language:** df3cf9294 (PR 7381, `ref` in `Core.Iterate.
    Next`; DR-1a adopted it), 6d80ceb58 and 309d3d63c (PRs 7974, 7975,
    `IndirectIndexWith`; DR-1b adopted them), 2ec4bab59 (PR 7832, lex and
    parse for `...` statements and `expand`; VA-1 cherry-picked it), 5fed32a9a
    (PR 7890, `friend`), c0b2cc592 (PR 8136, `where` assignments in impl
    definitions), a045da8e6, 72e425fe5, bd116f5e8 (PR 8110, `bound` removed;
    W-395, SAFE-1's), f21c62524 and db87a84b6 (design text).
9.  **Infrastructure:** a567040d7 and 9a4d4b332 (PRs 8096, 7960, the LLVM
    roll to c744694c6ae1: `IRBuilder(Module&)`, `PassBuilder(LLVMContext&,
    ...)`, `getGetElementPtr(DataLayout, ...)`), 0546b48a7 (PR 7903,
    `--target-cpu`), e6fddcf97 (PR 8050), 13ecad24b (PR 7871, the hash seed
    removed), the lexer optimizations (4a46ea888, 7cc1d0898, 5f1dd4941,
    8779d15e1, 0421bf3b4, 9192ee003, 07718a832, 22f3cd353, 4c5734a8c,
    bfd7f7ae5, 21c825a3f), the benchmarking series (0b9d0c704, 600fd55ba,
    33863ed07, 9319bb036, 3f5c18755, 57ba07a97, 789f582eb, c3877cf70,
    70c696e78, c50e21695, c57808584, 46b750bf9, 39e69f0b4, ebc155734), the
    editor grammars (65a3c2b36, 25b77cd3d, fccb349af, a5912b8b8, 8fc87ebf7,
    3056e7e31), b7ea32c3a (PR 8120, the PR dependency check), e2603996e,
    a50feb64c, the dependency bumps and CI commits (4e4b35e6e, 5b1a9311a,
    3741e72c8, a1305604f, 0b7059a36, 45ed77af3, 28d15a6e7, 05de707c4,
    9f2f906b8, 80a4a4d00, 5af3b7c47, b7919e8f5, a7e2f3418, 611e6a210,
    c0eee3e0b, 5a614167c, 3ee012b86, dd30c7655, 224a22ef3, 7601be966,
    66bf1415a, 86e6f4282, 7a3608bab), and the rest (d64969968, d4f1ec203,
    e9d8d06f9, c008bec1a, f27a977d8, a45002667, 9887d23b3, 5d442a5b0,
    06b3c69b7, 59d53ab0a, 071c5dadd, cb628110c, bf64992af, bc45989b2,
    690a05055, 2f808e0d0, 51e2c76a8, 2b2a78ca1, ff0d3ff10, 5aa7f35a1,
    bcb236e6c, 2c39bd57d, 427c448dc, 6d5142779, e8ffeef7b, 434c564a9,
    71a125a4c).

**The take-list.** The weekly entries of 2026-10-26, 11-02, 11-09 and 11-16
classify their windows commit by commit (45 table rows: 23 "advance,
mechanism", 14 "advance, fix", 2 "advance, design text", and six drift rows:
W-341 (503f09037, landed as OV-4 with the residues W-360 to W-363), W-372
(c6b54b57e, and 5ae3dcaa9's row "DRIFT already filed (W-372)"), W-354
(05a7ecbd3), W-394 (dbf02ad10), W-395 (bd116f5e8); 23 + 14 + 2 + 6 = 45,
recounted 2026-11-23, review fold: B-m1); the
2026-10-12 and 10-19 entries list their 36 and 49 commits in prose. The
union of the ADVANCE and DRIFT-AND-ADVANCE rows, with the 10-12 and 10-19
commits named by subject, is what UA-3 takes; W-395's bd116f5e8 arrives with
the merge (p008110, indexing.md, values.md merge clean) but its realignment
is PR 53's. Each named commit, the item it discharges and what UA-3 does:

| Commit | Item | What UA-3 does (the section that specifies it) |
| --- | --- | --- |
| 05a7ecbd3 | W-354; D-RG-16's string.carbon:154 site | The fork's three-entry `Destroy` witness builders and the `CoreInterface::Destroy` case go; upstream's `SubobjectDestroy` witness is taken; D-SL-16's yield and D-SL-19's class keying dropped, the surviving predicates re-keyed on `DestroyImpl` by identifier string across IRs; prelude `impl as Destroy` at buf.carbon:58, string.carbon:154, optional.carbon:354 and the `SelfDestruct` call at optional.carbon:357 take upstream's spellings; 16 fork goldens and 5 programs re-spelled `impl as Core.DestroyImpl` (§2.2, D-UA3-5) |
| c6b54b57e, 5ae3dcaa9, d50576ca1 | W-372 | Upstream's struct-pattern layer, diagnostics and parse nodes; the fork's `_` discard rebased on `PatternListUnderscoreField` for the refutable contexts (upstream's TODO elsewhere, W-079's residue); `has_trailing_discard` kept; `struct_pattern_names_stack` and the two fork duplicate diagnostics retired; let/fail_todo_struct_pattern.carbon renamed let/struct_pattern.carbon with a `_` parameter pin added (§2.3, D-UA3-6; amended 2026-11-23, review fold: A-M2 / A-M4) |
| dbf02ad10 | W-394 | Upstream's `AddrOfAction` inst (`ExprCategory::Dependent`) and handler; TP-1's `PerformAddrOf` and `PerformAction(AddrOfAction)` retired; D-TP-23's two stringify cases kept (watch row T13.9); TP-1's `&` goldens refilled (§2.4, D-UA3-7; amended 2026-11-23, review fold: A-M3) |
| d50576ca1, 19f1bf94d | W-069 lane a1 (new finding: superseded) | The fork's global-`let` lowering retired for upstream's `GlobalRef`; pins refilled (§2.5, D-UA3-8) |
| 503f09037 | W-360 | deduce.cpp's default-appending hunk merges clean; `fail_todo_generic_member_default` passes and is renamed (R-1); the selection change recorded in D-UA3-9 |
| 9799a2326, c7de72757, 8fdc8ebc3 | W-361 | export.cpp merges clean; the overload_set_default pair refilled; `fail_cpp_omitted` passes and is renamed (R-2); the C++ selection change recorded in D-UA3-9 (R30 (c)) |
| 1b0a5709e | W-362; W-037 | W-362's trailing-default count carried into function.cpp's `CheckDefaults`; the pin `fail_default_not_trailing` kept (§2.7, D-UA3-9) |
| none (tip call.cpp:73 unchanged) | W-363 | Stays open: the `CHECK` is still at the tip; the ledger note is updated with the tip's line (D-UA3-9) |
| 92534a0e0 | W-378 | Kept: upstream still copies `UnitAndImports` out of `map_range` (check.cpp:431-435 at 7a3608bab); the arbiter's GATE line reads `landed` (D-UA3-10) |
| none (a probe) | W-356 | refget.carbon on the prototype: exit 1, the diagnostic, no CHECK failure; discharged (§0.5, D-UA3-15) |
| 57bf903ef | item 6's audit task | check_unit.cpp: OV-2's definition check inside upstream's `bool`-returning `CheckRequiredDefinitions` under a once-flag; generic.cpp: upstream's `DefinitionResolution` body with its recursive-resolution TODO, VA-2's pack-iteration eval after `TryEvalBlockForSpecific` (§2.7) |
| 4abb6100e, 5c9ab26d7 | item 6's audit task | export.cpp merges clean; OV-3's export goldens refilled through Clang's LLVM function: lower overload_set.carbon's `linkonce_odr` count 9 → 17, no CHECK failure (§4) |
| 4286832b4 | item 6's audit task | Every fork `OperandDependence(context, ...)` line takes `context.sem_ir()` (nine after TP-2: call.cpp, convert.cpp, handle_index.cpp, pointer_dereference.cpp, action.cpp's `InSpecific` call); grep 0 after (§8.2) |
| c0b2cc592 | item 6's audit task | Two parse conflicts, class A beside UN-1's `UnionContext` and VA-1's `...` statement (§2.12) |
| 54728e47f, 72abc7a46 | item 6's audit task; register row H4.4 | export.cpp's moved class-export functions taken; ST-1's D-ST-12 null check re-inserted in the moved `ExportClassToCpp`; OV-3's `generate_ast.cpp` passes `lookup.specific_id` (§2.6) |
| 54f37b35b | the 2026-11-02 entry's touchpoint: "OV-3's overload thunks take the same mapping at UA-3" | export.cpp merges clean and upstream's `SetCppClassMemberAccess` sits on `BuildCppToCarbonThunkDecl`'s path (export.cpp:1504-1507 on the prototype, "Map Carbon access to C++ access"), which every exported Carbon method takes, OV-3's per-member thunks included, so the mapping is upstream's with nothing re-expressed; no overload export golden declares a `private` member (grep over check and lower interop/cpp/function/export/overload_set*.carbon: none), so the fill shows no access change and a pin split for a private overload member is a follow-on, not UA-3's (added 2026-11-23, review fold: B-m4) |
| 2e2125585 | the 2026-11-02 entry's touchpoint: "gap row 45 is updated after the merge" | upstream retires class.cpp's `generic class deriving from C++ virtual class` TODO (trunk class.cpp:554; its pin export/override.carbon's `fail_todo_generic` split refills to upstream's narrower TODO "generic class overriding methods from a C++ virtual class", generate_ast.cpp:568 at the tip, measured on the prototype's fill); gap row 45 (Type system: C++ interop — bi-directional inheritance, hierarchy roots, abstract/final/virtual mapping, PARTIAL) is re-cited in D with that split and TODO text beside its base.carbon cites (§0.6, A.11) (added 2026-11-23, review fold: B-m4) |
| e67b6db91, 92534a0e0, d0badecd2, 68569d234, 2c9739799, c608c35e1 | item 6's audit task | Fill churn only (no fork tool parses textual SemIR or diagnostic text); the fork's 23 Note/Context declarations and 27 call sites converted to `LABEL`/`CONTEXT` + `Attach` (§2.11, D-UA3-11); the two checkers read the rendered form (D-UA3-14) |
| 62f1cc6a3, ae5d1efd1, fb7eff130, ac31fd198, b1de0e037, 9fb428d71, 4a8993af2, 230227264, 04f456ddd, 559602b9e, 73c247f1e, 30318f87f, be0f11be9 | silent breaks (§0.4) | The renames, the moved types and the changed signatures applied at every fork site; the `where` region discarded into the enclosing generic (§2.7) |
| 947c1eb52 | 10-26 entry's "absorb" | handle_index.cpp: `TryGetAsArrayType` inside TP-1's `PerformIndex`; custom_witness.cpp: `CanDestroyArray` and the array-adapter arm beside OP-2's; slice.carbon imports prelude/types/array; mixed_constant_init.carbon's INCLUDE-FILE (§2.2, §2.14) |
| a567040d7, 9a4d4b332 | the arbiter (ARB-4, ARB-5) | Built at the tip pin with the three LLVM variables and the MLIR/CIR archives (D-UA3-4) |
| 2ec4bab59, df3cf9294, 6d80ceb58, 309d3d63c | VA-1, DR-1a, DR-1b (already on trunk) | Byte-identical sources on both sides: `--theirs`, refill; recorded as V-3a convergences (§2.14) |
| b7ea32c3a | the one .github conflict | Upstream's whole file; the fork's repository guard in it is lost (D-UA3-16, W-402) |
| 65a3c2b36, 25b77cd3d, fccb349af, a5912b8b8 | D-UA-5 re-applied | Upstream's grammar structure; `union` and `overload` re-expressed; the plist regenerated by the prek hook (§2.15) |
| bd116f5e8 | W-395 (SAFE-1, not UA-3) | p008110, indexing.md and values.md arrive clean; strings.md:225 and :359 are PR 53's to re-word |
| f21c62524, db87a84b6, 71a125a4c, 0b7059a36 | design text | Merge only; the five docs pages both sides edited auto-merge with the fork's dated amendments intact (§2.15) |

### §0.3 Conflict classification (file → class → strategy)

Classes, as UA-1 defined them: **A** adjacent (both sides inserted at one
anchor; keep both); **B** fork mechanism vs upstream refactor (upstream's
structure wins, the fork mechanism is re-expressed inside it); **C** upstream
superseded the fork mechanism (upstream's is adopted, the fork's deleted, the
fork's goldens and programs kept as pins); **D** upstream removed something
the fork relies on (none textual; the silent instances are §0.4); **X** a
file the fork does not maintain (.github: upstream's whole file); **G** a
golden (the side whose SOURCE lines win, then autoupdate). Marker counts are
the dry run's (`++<<<<<<<` per file at 701863aa5). The class is the
prototype's as landed (resolutions.tsv); where the audit's letter differed it
is named in the row. 73 rows: A 34, B 33, C 5, X 1; the 123 goldens are
Appendix B (107 theirs, 13 ours, 1 hand; 2 of the 123 merge clean at
a9892d4bb).

| File | Markers | Class | What collides | Resolution (details §2) |
| --- | --- | --- | --- | --- |
| toolchain/check/BUILD | 2 | A | upstream's struct.cpp/struct.h (c6b54b57e) vs SC-1's structural_conformance.{cpp,h} at one alphabetical anchor in `srcs` and `hdrs` | both lines in each list, `struct.*` before `structural_conformance.*` |
| toolchain/check/action.cpp | 2 | B | hunk 1: SC-1/CT-1's `CallAction` wait-for-concrete-C++-args block and `OperandDependenceInSpecific(context, ...)` vs 4286832b4's `context.sem_ir()`; hunk 2: upstream's `StartGenericDecl(context)` in `BeginPerformDelayedAction` vs the fork's `++context.delayed_action_depth()` (W-139) | the fork's block with every call on `context.sem_ir()`; upstream's `StartGenericDecl` AND the fork's depth increment (the decrement is outside the hunk) |
| toolchain/check/call.cpp | 3 (2 at a9892d4bb) | B | hunk 1: `ConvertCallArgs` gains `loc_id` vs SL-1's `RequireBuiltinCallPointeeComplete` after it; hunk 2: 62f1cc6a3's `ParameterizedClassType` case vs SC-1's `StructuralRequirementType` case; hunk 3 (gone after TP-2): `IsCallPerformable` | upstream's `ConvertCallArgs(context, loc_id, ...)` then the fork's builtin-completeness call; both cases; the two clean-merged `OperandDependence` lines on `context.sem_ir()`; `GenericClassType` renamed in the `IsOneOf` list |
| toolchain/check/check_unit.cpp | 1 | B | 57bf903ef's `new_resolution_occurred` loop (`CheckRequiredDefinitions` returns `bool`) vs OV-2's API-file overload-member definition check at the same point | upstream's loop; OV-2's check inside `CheckRequiredDefinitions` with its `MissingDefinitionInImpl` declaration, run once under a `CheckUnit` flag `overload_set_definitions_checked_` (prek's check-toolchain-diagnostics rejects a second declaration of the kind, and the loop would re-emit it) |
| toolchain/check/class.h | 1 | A | include blocks: d99b767dd's `<optional>`, name_scope.h, struct_type_field.h, typed_insts.h vs UN-1's `<tuple>`, decl_introducer_state.h, name_component.h, token_kind.h, node_ids.h | both sets, sorted |
| toolchain/check/context.cpp | 1 | A | `VerifyOnFinish`: upstream's `eval_impl_lookup_to_identified_witness_ == 0` vs SC-1's `deferred_structural_requires_.empty()` | both CHECKs; W-077's `struct_pattern_names_stack` CHECK dropped (W-372) |
| toolchain/check/context.h | 2 | A | `toolchain/base/stable_stack.h` (30318f87f) vs `toolchain/base/int.h`; `eval_impl_lookup_to_identified_witness()` vs SC-1's `DeferredStructuralRequire`, `structural_check_deferrals()`, `delayed_action_depth()` | both includes and member groups; W-077's match stacks stay `SmallVector`; `struct_pattern_names_stack` retired (W-372) |
| toolchain/check/convert.cpp | 4 | B | hunks 1-3: 4a8993af2's `InitializeAction::Target::storage_access_block_id` (from `PendingBlock::TakeAsInstBlock`) vs TP-1's `CloneStorageAccessChain` in `storage_id` and the `has_storage`/`OutParam` return-slot rule (D-TP-2, D-TP-3); hunk 4: upstream's `GetInstLocationOrFallback` loc vs the fork's `GetTypeOfInstInSpecific` type for the `TemporaryStorage` | W-258: TP-1's cloned chain rides in upstream's `storage_access_block_id` (`storage_id = target.storage_id`); the copy rule and D-TP-2's `has_storage` rule inside upstream's `PerformAction(InitializeAction)`; hunk 4 upstream's loc with the fork's in-specific type; the four clean-merged `OperandDependence` lines converted; `MaterializeIfInitializer` takes `loc_id`; the `FindStorageArgForInitializer` caller takes the 2-argument form |
| toolchain/check/core_identifier.def | 1 | A | EH-A's `Result` after 309d3d63c's `Ref`; upstream renames `Destroy` to `DestroyImpl` and adds `Array`, `IndirectIndexWith` outside the hunk | ours (`Result` after `Ref`); upstream's lines merge clean |
| toolchain/check/cpp/export.cpp | 1 | B | 54728e47f moved `ExportClassSpecificToCpp`/`ExportClassToCpp`/`ExportAndCompleteClassToCpp` below `ExportNameScopeToCpp` (new `class_template_decl` parameter); the fork's copies carry ST-1's D-ST-12 `if (!decl_context) return nullptr;` and `GenericClassType` names | upstream's moved functions; D-ST-12's null check re-inserted after `ExportNameScopeToCpp` in the moved `ExportClassToCpp` (the site H4.4 watches) |
| toolchain/check/cpp/import.cpp | 1 | A | upstream's inline `CARBON_DIAGNOSTIC_LABEL(InCppThunk, Info)`/`Attach` vs EH-B's `NoteInCppThunk(builder, loc_id)` helper in `ImportFunctionDecl` | the fork's helper kept with its body converted to `LABEL`/`Attach`; the fence-unbuildable TODO after `DefineAsThunkCall` stays (D-UA-7); `CppCalleeFunctionInfo` and `ParameterizedClassType` renames |
| toolchain/check/cpp/thunk.cpp | 3 | B | ae5d1efd1 renames `CalleeFunctionInfo` to `CppCalleeFunctionInfo` in `IsCppThunkRequired`/`BuildThunkBody`/`BuildCppThunk`; EH-B's fence and catching machinery sits in the same hunks | upstream's name throughout; the fork's three fence components (D-UA-7) and the catching builders kept; §8.2's greps measured on the prototype: `EST_BasicNoexcept` 4, awk 1 |
| toolchain/check/custom_witness.cpp | 4 | **C** (audit: C/B) | 05a7ecbd3: the custom witness serves `SubobjectDestroy` only (`BuildSubobjectDestroyWitness`, `LookupSubobjectDestroyWitness`, `BuildTrivialSubobjectDestroyWitness`, `CanDestroyArray`) vs the fork's three-entry `BuildDestroyWitness`, `BuildCarbonDestroyWitness`, `LookupDestroyWitness`, `BuildTrivialDestroyWitness`, `MakeDestroyOpFunction`, `MakeDestroySelfDestructFunction`, the `case CoreInterface::Destroy`, OP-2's `AdapterHasDestroyWork`, D-UA-9's `is_choice` return; upstream's array-adapter arm vs the fork's adapter arms | upstream's `SubobjectDestroy` builders; the six fork `Destroy` builders and the `Destroy` case deleted (W-354); `LookupChoiceCopyWitness`/`LookupUnionUnformedInitWitness` and their cases kept; in `MakeSubobjectDestroyOpBody` upstream's array arm, then D-UA-9's `is_choice` return and OP-2's adapter arm; D-SL-16's yield dropped from `CanDestroyClass` and `CanDestroyType`; `HasUserDestroyImpl`/`HasClassKeyedImpl`/`IsTriviallyDestructible`/`HasNonTrivialUserCopyImpl` re-keyed on `Core.DestroyImpl` by identifier string through each IR's own store (`IsCoreDestroyImplInFile`), the local loop skipping import-materialized impls (§2.2) |
| toolchain/check/deduce.cpp | 1 | A | includes: upstream's pattern.h (503f09037) vs SC-1's inst.h and structural_conformance.h; 503f09037's default-appending in `DeduceGenericCallArguments` merges clean beside OV-2's `diagnose` and SC-1's deferrals | all includes sorted; W-360 discharged by the clean hunk and the refill |
| toolchain/check/eval_inst.cpp | 2 | B | hunk 1: the diagnostics API; hunk 2: VA-2's `TupleType`/`TupleValue`/`PackFacetValue`/`PackType`/`PackElement` evaluators and the cut's `EvalConstantInst(RequireSpecificDefinition)` vs 9fb428d71's deletion of that kind | upstream's `CONTEXT`/`Attach`; VA-2's evaluators kept; the `RequireSpecificDefinition` evaluator dropped |
| toolchain/check/full_pattern_stack.cpp | 1 | B | upstream's `IsAnyNameBindingDeclKind(kind_stack_.back())` CHECK (d50576ca1) vs the fork's explicit list with `Kind::MatchCaseArm` (W-077) | `CARBON_CHECK(IsAnyNameBindingDeclKind(k) \|\| k == Kind::MatchCaseArm)` with the fork's comment |
| toolchain/check/full_pattern_stack.h | 1 | A | upstream's `ClassScopeLetDecl` enumerator vs the fork's `MatchCaseArm` at one anchor | both (`ClassScopeLetDecl` then `MatchCaseArm`); upstream's helpers kept |
| toolchain/check/generic.cpp | 2 | B | 57bf903ef: `ResolveSpecificDefinition` returns `DefinitionResolution` with the recursive-resolution TODO and the `PreviouslyResolved` return vs the fork's `-> bool` body calling `TryEvalBlockForSpecific` then VA-2's `TryEvalPackIterationsForSpecific` | upstream's signature, TODO and `PreviouslyResolved`/`NotDefinedYet` structure; `TryEvalPackIterationsForSpecific` right after `TryEvalBlockForSpecific` in the `NewlyResolved` path; generic.h's clean-merged declaration is upstream's |
| toolchain/check/handle_binding_pattern.cpp | 2 | A | case labels `ClassScopeLetDecl` vs `MatchCaseArm`; `StructPatternFieldVarBindingPattern` in upstream's var condition vs VA-2's `is_each` block | `MatchCaseArm`'s TODO then fallthrough into upstream's three labels; the `is_each` block before upstream's two-kind var condition |
| toolchain/check/handle_choice.cpp | 3 | B | d50576ca1's `MakeBinding` emits an `AliasBinding` for a parameterless alternative vs the fork's `MakeLetBinding` (`WrapperBinding` + payload-region fill), `MakeDiscriminantLiteral`, `TypeContainsChoice`, `ChoiceAlternativeFunctionInfo`, `BuildAlternativeConstructor` (B1/B2, F-007); hunk 3 the per-alternative loop | upstream's `AliasBinding` `MakeBinding` (its body merged clean) with the fork's `MakeDiscriminantLiteral` and payload comment; `MakeLetBinding` deleted; the function-alternative machinery and loop kept; the match lane resolves an `AliasBinding` alternative the same way (the seven choice and 17 match goldens pass on the prototype) |
| toolchain/check/handle_class.cpp | 1 | B | upstream's `BuildClassDecl` body (`GetParameterizedClassType`, 62f1cc6a3) vs the fork's one-line delegation to class.cpp's `BuildClassOrUnionDecl` (UN-1, D-UA-6) | the fork's delegation; the rename applied inside class.cpp:120 (clean-merged, a silent break); upstream's `friend_scopes_stack` push/pop merges clean, and handle_union.cpp (fork-only, clean) gains the same `PushArray` in `UnionDefinitionStart` and the same copy-and-`PopArray` in `UnionDefinition`: a union is a `ClassType`, so 5fed32a9a's `FriendDecl` handler accepts it and appends to an array no union handler pushed — a crash the prototype's gate did not cover (§0.4 item 23; amended 2026-11-23, review fold: A-M1) |
| toolchain/check/handle_function.cpp | 1 | B | upstream's deduced-return checks (bf5d2a2ac, 3af25cc1b) and its move of `CheckDefaults` to function.cpp (1b0a5709e, `CheckFunctionParams`) vs the fork's positional-param tail, `DiagnoseOverloadInInterfaceOrImpl`, `DiagnoseOverloadGates` (OV-1/OV-2/VA-1) and its `CheckDefaults` copy carrying W-362 | upstream's deduced-return code; the fork's `CheckDefaults` copy and positional tail dropped (both moved to function.cpp upstream); the two overload gates re-inserted; W-362's trailing-default count carried into function.cpp's `CheckDefaults`; `BuildFunctionDecl` keeps `TryMergeOverloadDecl` before `TryMergeRedecl` and calls upstream's `CheckFunctionParams` |
| toolchain/check/handle_index.cpp | 3 | B | hunks 1-2: `PerformIndexOperator`'s `node_id` vs TP-1's `LocId`; hunk 3: 947c1eb52's `TryGetAsArrayType(context, node_id, type)` Core.Array-adapter dispatch vs TP-1's `PerformIndex` switch with the `IndexAction` deferral, DR-1's `IndirectIndexWith` probe and SL-1's literal-subscript rule | TP-1's `PerformIndex`/`PerformAction` structure on `LocId`; its `case ArrayType` replaced by upstream's `TryGetAsArrayType` probe ahead of the default branch; the two `OperandDependence` lines converted |
| toolchain/check/handle_operator.cpp | 2 | **C** | dbf02ad10's `PerformAction(AddrOfAction)` and `HandleParseNode(PrefixOperatorAmp)` through `HandleAction<AddrOfAction>` vs TP-1's `PerformAddrOf` (pointer_dereference.cpp:108-146); hunk 2: upstream's diagnostic form of `PerformPointerDereference` vs TP-1's `PointerDereferenceKind::Star` | W-394: upstream's handler whole; `PerformAddrOf` and the fork's `PerformAction(AddrOfAction)` deleted from pointer_dereference.{cpp,h}; hunk 2 keeps the fork's `PointerDereferenceKind` form with the moved `DerefOfType` note converted to `LABEL`/`Attach` |
| toolchain/check/handle_pack_expansion.cpp | 2 | B | add/add: upstream's three TODO stubs (2ec4bab59) vs VA-1/VA-2's implementation of those three node kinds plus `PackExpansionExpr`/`Pattern`, `EachBindingName`, `EachNameExpr` | the fork's file whole; its two notes and one context converted |
| toolchain/check/handle_pattern_list.cpp | 4 | B | c6b54b57e/5ae3dcaa9/d50576ca1's struct-pattern layer (`struct_type_fields_stack`, `PopStructFieldNameNodes`, `DiagnoseDuplicateNames(StructKind::StructPattern)`, `InNonStaticFieldDecl`, the `PatternListUnderscoreField` TODO) vs W-077's match-only layer (the `MatchCaseArm` gate, `struct_pattern_names_stack`, `UnderscoreName`-keyed `has_trailing_discard`, `StructPatternNameDuplicate`/`Previous`, the designated-field re-push) | W-372: upstream's layer and diagnostics in all four hunks; `_` recorded by the `PatternListUnderscoreField` handler as a solo node and read by the `StructPattern` end handler into `has_trailing_discard`; the `_`-without-fields diagnostic moved there; the gate, the names stack and the two fork duplicate diagnostics retired; the match pre-work in pattern_match.cpp reads the flag; outside the refutable contexts (`FullPatternStack::Kind::MatchCaseArm`) the `_` handler returns upstream's TODO ("Struct pattern underscore field"), because upstream's `let`/`var`/parameter lane converts the initializer to the pattern's own type and reads no discard (§0.4 item 24; amended 2026-11-23, review fold: A-M2) |
| toolchain/check/impl.cpp | 2 | B | upstream rewrote `CheckRequireDeclsSatisfied` on `Check::IdentifiedFacetType` (the `identified_id` parameter, `RequiredImpl{self_facet, interface}` with `SubstIdentifiedWitnesses`, the equivalents loop; a83e1d837/5402b4c56/e39bdb7af) and deleted `SubstImplSelfWitnesses`; the fork keeps the cut's `SubstImplSelfWitnesses` plus SC-1's `GetRequireSelfClassBeingDefined`, `LookupRequireInterfaces`, `CheckInterfaceRequire`, `GetInterfaceWithSelfSpecific` | upstream's body and equivalents loop; `SubstImplSelfWitnesses` dropped; SC-1's four helpers on the new `RequiredImpl` fields and `TryToIdentifyFacetType`'s `TypeId`; upstream's inline require loop replaced by the fork's `CheckInterfaceRequire(..., ImplDefinition)` loop |
| toolchain/check/impl_lookup.cpp | 3 | B | includes (sem_ir/function.h and sem_ir/identified_facet_type.h vs check/identified_facet_type.h); the fork's `GetIdentifiedFacetTypeForQuery` helper vs upstream's inline `RequireIdentifiedFacetType(..., TypeId, CONTEXT/Attach)`; SC-1's `CheckStructuralRequirements` step vs upstream's `required_impls`/equivalents prologue | sem_ir/function.h kept, the sem_ir facet include replaced by check/'s; the helper folded into upstream's inline call; SC-1's structural step between identification and `req_impls`, upstream's empty-requirements CHECKs preserved |
| toolchain/check/import_ref.cpp | 2 | B | hunk 1: upstream's `GetLocalIncompleteSpecificData` vs the fork's `GetLocalSpecificData` plus the per-instantiation-resolved block (TP-1/CT-1); hunk 2: 73c247f1e moved `ImportIncompleteClass` while the fork's copy carries `.is_union` (UN-1) and `GetGenericClassType` | upstream's incomplete-specific accessor with the fork's `resolved_per_instantiation` rule; the fork copy deleted and `.is_choice`/`.is_union` added to upstream's moved initializer; the fork's duplicate `TryResolveTypedInst(CustomLayoutType)` resolver deleted (upstream imports the kind since 66a250ad9) |
| toolchain/check/inst.cpp | 1 | B | upstream's split of the symbolic case into `SpecificConstant` and `SpecificInst` vs CT-1's `AddAliasUseCheckToCurrentGeneric` after the `SpecificConstant` | upstream's split; the alias-use check in the `SpecificConstant` branch |
| toolchain/check/member_access.cpp | 1 | A | d50576ca1's `TryGetLookupResultInCurrentScope` vs SC-1's `MakeStructuralRequirementName` return (D-SC-20) at one point of `LookupMemberNameInScope` | upstream's lexical-scope check first, then the fork's return |
| toolchain/check/merge.cpp | 2 | B | `CheckRedeclParam`: upstream's `LABEL(RedeclParamPrevious, Info)`/`Attach` vs the fork's `new_specific_id, bool* found_error` parameters and `new_param_type_id` (W-233) | upstream's form with the fork's two parameters and argument; the D-UN-6 clauses in `TryMergeRedecl` are outside the hunks and stay |
| toolchain/check/name_lookup.h | 1 | A | `LookupResult`: upstream's `lexical_scope_index` vs SC-1's `prohibited_access_kind` | both fields |
| toolchain/check/node_stack.h | 1 | A | the fork's `PatternConditionInitializer`/`Introducer` solo-node cases beside upstream-touched lines | the fork's two cases |
| toolchain/check/pattern_match.cpp | 4 | B | includes; `LocalState`: upstream's `in_global_init` vs W-077's `in_match_case_bind`; `LocalState* _` vs the fork's `local_state` with `UseGlobalInit(context_)` and on-demand `VarStorage`; the `StructPattern` pre-work comment | all includes; both fields; upstream's `in_global_init` instead of `UseGlobalInit` with the fork's on-demand `VarStorage` under `in_match_case_bind`; one `DoPreWork(StructPattern)` body with the `MatchContext` `loc_id`; the three `LocalPatternMatch` callers in refutable_binding.cpp pass `loc_id` |
| toolchain/check/pending_block.h | 1 | A | upstream's `AddInstId`/`TakeAsInstBlock` (4a8993af2) vs the fork's documented `AddInstId` and `insts()` accessor | upstream's members and the fork's accessor (its caller `CloneStorageAccessChain` survives under W-258) |
| toolchain/check/return.cpp | 2 | B | upstream's static `LABEL`/`Attach` notes plus the deduced-return machinery (`NoteReturnTypeIsDeduced`, `ConvertReturnExpr`, `BuildPendingReturn`, `CompletePendingReturns`) vs the fork's exported `NoteNoReturnTypeProvided`/`NoteReturnType`/`NoteReturnForm`/`NoteReturnedVar` (return.h; EH-A's handle_question.cpp); hunk 2 upstream inlines `ReturnFormHereNote` with a deduced-form location | upstream's machinery; the fork's exported helpers rewritten on `LABEL`/`Attach`, `NoteReturnForm` taking upstream's deduced-form location, so handle_question.cpp:238 and return.h:27 compile |
| toolchain/check/type_completion.cpp | 3 | B | `BuildInfoForInst`'s requires list (`ParameterizedClassType` vs `OverloadSetType`, `StructuralRequirementType`); `IdentifyFacetType` outputs: `Check::IdentifiedFacetType` with `equivalents` vs SC-1's `structural` vector (D-SC-15); the `Add({...})` initializer | the renamed list plus the two fork types; upstream's `Check::` types with `equivalents` and the fork's structural vector as the seventh constructor argument (`StructuralRequirement` moved into check/identified_facet_type.h) |
| toolchain/diagnostics/kind.def | 6 | B | upstream's note/context model (c608c35e1, 2c9739799, d0badecd2: labels and contexts declare no kind; about 110 note/context kinds deleted; `CppInteropParseNote` becomes a `CppInteropStrayNote` warning plus a label) vs the fork's kinds (EH-B/CT-1 `Cpp*`, VA-1, TP-1, the `IncompleteTypeIn*` contexts, W-077's `StructPattern*`, EH-A's `Question*`), the fork sides also carrying 17 cut lines upstream deleted | upstream's side of every hunk; the cut lines dropped; the fork's Error/Warning kinds re-added (hunk 1 the six `Cpp*`, hunk 2 the three pack-call kinds, hunk 3 `TemplateMemberLookupAmbiguous`, hunk 4 `ChoicePayloadNotTrivialInSpecific`, hunk 5 `StructPatternDiscardWithoutFields` and `StructPatternNameDuplicate`, hunk 6 the six `Question*`); the fork's 20 Note and 7 Context kinds removed as their declarations become `LABEL`/`CONTEXT`; 18 kinds no longer declared removed after the conversion (coverage_test and prek's check-toolchain-diagnostics arbitrate; 502 kinds on the prototype) |
| toolchain/driver/compile_options.cpp | 1 | A | 0546b48a7's `codegen_options->GetClangArgs()` block vs EH-B's `switch (cpp_exceptions)` appending `-f[no-]exceptions` last | upstream's block, then the fork's switch appended to `all_clang_args` after `append(clang_args...)` |
| toolchain/lower/aggregate.cpp | 1 | B | 559602b9e/04f456ddd's `FindStorageArgForInitializerInSpecific(sem_ir, ref_id, specific_sem_ir, specific_id)` + `CARBON_CHECK(&sem_ir == dest_sem_ir)` vs TP-1's `context.IsConstant(ref_id)` test and the fork's 4-argument call | upstream's call and CHECK under the fork's `if (context.IsConstant(ref_id))` condition with its comment |
| toolchain/lower/file_context.cpp | 2 | **C** | hunk 1: upstream's `.return_kind` (9fd28f730) vs EH-A's `.entry_point_result_type_id`; hunk 2: d50576ca1's `GetOrCreateGlobalBinding` (`global_bindings_`, `MangleGlobalBinding`, `let.anon` names) vs W-069 lane a1 (`RegisterGlobalLetBindings`, `LookupGlobalLetBinding`, `GetOrCreateGlobalLetVariable`, `PrepareGlobalLetDefinitions`, `EmitGlobalLetStores`) | hunk 1 both fields; hunk 2 upstream's whole; the three clean-merging W-069 call sites (`RegisterGlobalLetBindings();`, `PrepareGlobalLetDefinitions();`, the `global_let_stores_emitted_` CHECK) deleted; EH-A's entry-point code kept |
| toolchain/lower/file_context.h | 2 | **C** | upstream's `GetOrCreateGlobalBinding` and `global_bindings_` vs W-069's declarations and four `global_let_*` members | upstream's; `struct GlobalLetBinding` and the two private declarations deleted outside the hunks; `entry_point_result_type_id` kept |
| toolchain/lower/function_context.cpp | 2 | A (C outside the hunks) | both sides added `CopyObject(TypeInFile, llvm::Value*, llvm::Value*)` beside VA-2's `CopyValueReprToObject` | one `CopyObject` pair in upstream's order, `CopyValueReprToObject` kept; outside the hunks `TryEmitGlobalLetValue`, its `GetValue` hook and the `is_global_ctor_` hook deleted (W-069); `GetValueServesConstantValueRep` and the `pack_index_` argument kept; the `InitializeStorage` caller moved to `...InSpecific` |
| toolchain/lower/function_context.h | 2 | A | `CopyObject(Value*)` declared on both sides plus the fork's `CopyValue`; `CopyValueReprToObject`, `TryEmitGlobalLetValue`, `AddGlobalToCurrentFingerprint` vs upstream's (which already declares the last) | exactly one declaration each; `TryEmitGlobalLetValue` and `is_global_ctor_` dropped |
| toolchain/lower/handle.cpp | 2 | B | hunk 1 (`NameRef`): upstream's `SetLocal(inst_id, GetValue(inst.value_id))` (the peek-through removed; `GlobalRef` carries global lets) vs W-069's peek; hunk 2 (`ReturnExpr`): upstream's `ReturnKind` switch with a `CARBON_FATAL` `EntryPointInt32` arm vs EH-A's D10 epilogue in the old `InitRepr::InPlace` arm | hunk 1 upstream's; hunk 2 upstream's switch with EH-A's D10 epilogue first in the `EntryPointInt32` arm (`GetEntryPointResultTypeId(...).has_value()` → `InitializeStorage`, `EmitEntryPointResultEpilogue`, return) then upstream's FATAL; the `inits` caller moved to `...InSpecific` |
| toolchain/lower/type.cpp | 3 | A | `return_kind_`/`.return_kind` vs EH-A's `entry_point_result_type_id_`/`.entry_point_result_type_id`; the placeholder list: `ParameterizedClassType` vs `OverloadSetType`, the cut's `RequireSpecificDefinitionType`, `StructuralRequirementType` | both fields in both hunks; upstream's list plus `OverloadSetType` and `StructuralRequirementType`; `RequireSpecificDefinitionType` dropped (9fb428d71) |
| toolchain/parse/context.cpp | 1 | A | upstream's `VlogPushState`/`VlogPopState` (22f3cd353), `OpeningBracketInsertionPoint`, `DiagnoseExpectedOpenCurlyBrace` (68569d234) vs EH-A's `ReplaceIntroducerNode` (let-else) at one anchor | upstream's four helpers, then the fork's `ReplaceIntroducerNode` |
| toolchain/parse/handle_decl_scope_loop.cpp | 1 | A | c0b2cc592's `set(Where, ...)` vs UN-1's `UnionContext` block | both; no `unset(Where, UnionContext)` (check diagnoses a `where` in a union body) |
| toolchain/parse/handle_match.cpp | 1 | B | 68569d234 emits `ExpectedMatchCaseGuardOpenParen` at `OpeningBracketInsertionPoint()` inside the inline guard parse vs the fork's shared `HandleMatchGuard` helper (`case` and `default if` guards) | the fork's call; `HandleMatchGuard` emits at `context.OpeningBracketInsertionPoint()` |
| toolchain/parse/handle_statement.cpp | 1 | A | `case Lex::TokenKind::Union` (UN-1) vs `case Where` (c0b2cc592) | both cases (`Union`, `Var`, `Where`) |
| toolchain/parse/node_ids.h | 1 | A | upstream's `AnyFunctionDeclId` gains terse/lambda ids and `AnyFunctionDefinitionStartId` vs UN-1's union ids in `AnyClassDeclId` plus `AnyUnionDeclId` | upstream's two aliases plus the fork's union members and `AnyUnionDeclId` |
| toolchain/parse/node_kind.def | 1 | A | both added `PackExpansionStart`/`PackExpansionStatement` identically; the fork's `PackExpansionExpr`, `PackExpansionPattern`, `EachNameExpr`, `EachBindingName` follow | ours (NodeKind count 320, 16-bit) |
| toolchain/parse/state.def | 17 | A | comment-only state docs: upstream's rewrites (six hunks: friend caret, fn return forms, terse `=>`, binding-pattern forms, `[ref] self`, Pattern) vs the fork's (union, `expr ?`, pack patterns, tuple elements, union variants, match alternatives, `MatchGuardedDefaultStart` with its `CARBON_PARSE_STATE` line) | upstream's text in the six hunks it authored, the fork's in the other eleven; every `CARBON_PARSE_STATE*` line merges clean but `MatchGuardedDefaultStart`, which stays |
| toolchain/parse/typed_nodes.h | 1 | A | adjacency after the shared `PackExpansionStatement` struct: the fork's `PackExpansionExpr`, `PackExpansionPattern`, `EachNameExpr` | ours |
| toolchain/sem_ir/core_interface_kind.def | 1 | A | `SubobjectDestroy` (05a7ecbd3) vs `UnformedInit` (UN-1) | both, sorted |
| toolchain/sem_ir/expr_info.cpp | 2 | B | upstream's `FindStorageArgForInitializer(sem_ir, init_id, allow_transitive)` and `...InSpecific(.., specific_sem_ir, specific_id, allow_transitive) -> pair<const File*, InstId>` vs TP-1's 4-argument form whose `SpliceInst` arm returns `None` when the specific's constant is not concrete | upstream's two functions and expr_info.h declarations; the fork's guard inside `...InSpecific`'s `SpliceInst` arm (`!const_id.is_concrete() \|\| const_id == ErrorInst::ConstantId` → `{ir, InstId::None}`, the fork's comment); the callers lower/function_context.cpp, lower/handle.cpp and check/convert.cpp moved; the `init.dest_id` return as a pair |
| toolchain/sem_ir/file.cpp | 1 | A | `CollectMemUsage`: upstream's `generated_functions_`, `cpp_overload_sets_` (e6fddcf97) vs OV-1's `overload_sets_` | all three |
| toolchain/sem_ir/function.h | 1 | A | `Function::Print`: `deduced_return_kind` (bf5d2a2ac) vs OV-1's `overload_set_id`/`overload_index` | both print clauses |
| toolchain/sem_ir/identified_facet_type.cpp | 0 (modify/delete) | B | fb7eff130 moved the type to check/identified_facet_type.{h,cpp}; SC-1 (D-SC-15) added a sixth constructor parameter `ArrayRef<StructuralRequirement> structural` and a dedup loop | `git rm`; the parameter ported as a seventh, `= {}`, after upstream's `ArrayRef<Equivalent> equivalents`, with the loop, into check/identified_facet_type.cpp |
| toolchain/sem_ir/identified_facet_type.h | 0 (modify/delete) | B | the same move; SC-1's `struct StructuralRequirement`, `structural_requirements()`, the member and its include | `git rm`; ported into check/identified_facet_type.h; `Check::IdentifiedFacetType(Id)` spelled in SC-1's files |
| toolchain/sem_ir/inst_kind.def | 1 | A | `ParameterizedClassType` (62f1cc6a3) vs OV-1's `OverloadSetType`/`OverloadSetValue` and VA-1/VA-2's eleven `Pack*` kinds; `AddrOfAction`'s line shared | both, sorted (199 kinds) |
| toolchain/sem_ir/inst_namer.cpp | 1 | A | the rename vs the fork's `OverloadSetValue`/`OverloadSetType`/`StructuralRequirementType` cases | the fork's three cases plus `ParameterizedClassType` sharing the `.type` body |
| toolchain/sem_ir/mangler.cpp | 1 | A | 1b0a5709e mangles an unnamed fn expression as `fn` vs D-OV-5's `:overload<N>` suffix with its CHECK | upstream's if/else with the fork's overload block inside the named branch; `MangleGlobalLetBinding` deleted outside the hunk (W-069) |
| toolchain/sem_ir/mangler.h | 1 | **C** | upstream's `MangleGlobalBinding(EntityNameId, InstId)` (d50576ca1) vs W-069's `MangleGlobalLetBinding(InstId)` | upstream's; lower/testdata/let/global_runtime_symbols.carbon re-pins the names by refill (`%total.ref` → `%total.global_ref`) |
| toolchain/sem_ir/stringify.cpp | 1 | A | upstream's `StringifyInst(FunctionDecl)` vs OV-1's `OverloadSetType` | both overloads; TP-1's two `AddrOfAction` cases KEPT and marked Fork (D-TP-23: a diagnostic prints a template-dependent action as the expression it performs, for every action kind; upstream stringifies no action and falls back to `<cannot stringify ...>`): rev 1's deletion is reversed (D-UA3-7; amended 2026-11-23, review fold: A-M3) |
| toolchain/sem_ir/type_info.cpp | 2 | A | `RecognizedTypeInfo`: upstream's `Array` (947c1eb52) vs EH-A's `Result` and SL-1's `Slice` | `ExpectsArgs` = Optional \|\| Array \|\| Result \|\| Slice; both case groups |
| toolchain/sem_ir/type_iterator.cpp | 1 | A | `ParameterizedClassType::Kind` vs the fork's `OverloadSetType::Kind`, the cut's `RequireSpecificDefinitionType::Kind`, `StructuralRequirementType::Kind` | upstream's plus `OverloadSetType` and `StructuralRequirementType`; `RequireSpecificDefinitionType` dropped |
| toolchain/sem_ir/typed_insts.h | 4 | B | hunk 1: upstream's `AddrOfAction` (`ExprCategory::Dependent`) vs TP-1's (`Value`), same fields; hunk 2: `ParameterizedClassType` vs the fork's `OverloadSetType`, `OverloadSetValue` and eleven `Pack*` structs; hunks 3-4: upstream's `StructPattern` (c6b54b57e) vs W-077's with `BoolValue has_trailing_discard` | hunk 1 upstream's (W-394); hunk 2 both; hunks 3-4 upstream's struct and comment plus the fork's `has_trailing_discard` field marked Fork (W-077, W-372) |
| .github/workflows/check_dependent_pr.yaml | 1 | **X** | the fork's six-line `if: github.repository == 'carbon-language/carbon-lang'` guard vs b7ea32c3a's label-event `if:` block at the same job key; upstream rewrote triggers and steps outside the hunk | `git checkout 7a3608bab -- .github/workflows/check_dependent_pr.yaml`; the guard grep then expects five hits (D-UA3-16) |
| docs/design/control_flow/loops.md | 1 | A | the fork's blockquote "Fork amendment (2026-10-21, DR-1a)" against an empty upstream side (df3cf9294's rewrite is already in the fork verbatim) | ours; the resolved file equals trunk's |
| utils/vscode/carbon.tmLanguage.json | 1 | B | the fork's `union` in the introducer alternation and `overload` in the modifier alternation vs upstream's rebuilt `keywords` block (65a3c2b36 and successors) | upstream's block; `union` re-added to the introducer alternation and the three `impl` look-around lists; `overload` merges clean into the modifier alternation (D-UA-5 re-applied) |
| utils/textmate/Syntaxes/carbon.tmLanguage | 1 | B | the same collision in the generated plist | never hand-edited: regenerated from the json by the prek hook build-textmate-grammar (scripts/update_tm_language.py), then added |

**Goldens (123 at 701863aa5, 121 at a9892d4bb).** The rule is a source-only
three-way (CHECK lines stripped; reader 3's golden-src.tsv): **107 theirs**
(97 whose fork source equals upstream's, five of them add/add files the fork
cherry-picked byte-identical and four where both sides made the same edit;
plus 7 where the fork changed only CHECK lines and upstream edited source;
plus the three "theirs, upstream superset" cases for/actual.carbon and the two
function/call/form.carbon, and reference.carbon and share_ast.carbon whose
fork delta is one blank line), **13 ours** (TP-1's eval/symbolic, template/
call, member_out_of_line, unimplemented; CT-1's var_template and
lower/globals; SC-1's invalid_members and parse template_constraint; W-078b's
patterns/unused; W5-S3b's choice/params; W-069's two let/*generic_import split
renames; VA-1's variadics/pack_expansion with its split name), **1 hand**
(eval/call.carbon: upstream's file plus the fork's appended split
`symbolic_eval_fn_class_literal_with_field_default`, no CHECK lines written).
Appendix B lists every file with its markers and side; resolution D-UA3-3.

### §0.4 Semantic conflicts the dry run does NOT show

Each was a build break, a crash or a behavior change the prototype met;
the merge commit resolves every one (§2), so none is a fix commit of the
product.

1.  **Diagnostics API (2c9739799):** `Diagnostics::Builder::Note` and
    `Context` are gone with the `Note` and `Context` levels; a note is
    `CARBON_DIAGNOSTIC_LABEL(X, Info, ...)` attached by `.Attach(loc, X)`, a
    context `CARBON_DIAGNOSTIC_CONTEXT`, neither with a kind.def entry. The
    fork's clean-merged lines: 20 `.Note(` calls, 7 `.Context(` calls, 23
    declarations in call.cpp, cpp/import.cpp, cpp/sum_type.cpp,
    handle_function.cpp, handle_match.cpp, merge.cpp, pointer_dereference.cpp,
    structural_conformance.cpp, eval_inst.cpp, handle_choice.cpp,
    handle_question.cpp, refutable_binding.cpp (reader 1's
    merged-outside-conflict-hits.txt), plus the fork-added uses of seven kinds
    upstream relabelled (`InCppThunk`, `RedeclPrevDecl`, `DerefOfType`,
    `IncompleteTypeInBindingDecl`, `IncompleteTypeInFunctionReturnType`,
    `IncompleteTypeInMonomorphization`, `ReturnFormHereNote`). Converted in
    11 files (D-UA3-11); kind.def loses the fork's 27 Note/Context kinds.
2.  **62f1cc6a3's rename:** four fork lines outside hunks keep
    `GenericClassType`/`GetGenericClassType` (call.cpp's `IsOneOf` list,
    class.cpp:120, cpp/import.cpp:1331, decl_name_stack.cpp:492); renamed.
3.  **ae5d1efd1's rename:** `CalleeFunctionInfo` at cpp/import.cpp:2148 and
    thunk.cpp:832/:1123 (`WrapInBoundaryDiagnostic`, `BuildCppCatchingThunk`);
    renamed `CppCalleeFunctionInfo` (grep for the bare name: 0 after).
4.  **4286832b4:** `OperandDependence`/`OperandDependenceInSpecific` take
    `const SemIR::File&`; nine fork lines after TP-2 (call.cpp 2, convert.cpp
    4, handle_index.cpp 2, pointer_dereference.cpp 1) plus action.cpp's
    `InSpecific` call pass `context.sem_ir()` (grep 0 after).
5.  **05a7ecbd3:** `CoreInterface::Destroy` and `CoreIdentifier::Destroy` no
    longer exist (`DestroyImpl`, `SubobjectDestroy`); the fork's clean-merged
    custom_witness.cpp:307 (D-SL-16's yield), :416, :636, :674 (the keying)
    cannot compile; `impl as Destroy {` is `ImplOfNotOneInterface` at the tip
    (`Destroy` is a two-interface constraint): the prelude's buf.carbon:58,
    string.carbon:154, optional.carbon:354 and the `.(Destroy.SelfDestruct)()`
    call at optional.carbon:357, and 16 fork goldens and 5 conformance
    programs (reader 3's destroy-spelling-nonconflict.txt; the list is §2.13).
    The merged prelude's `SelfDestruct` takes a `ref` argument:
    `SelfDestruct(ref (self.value unsafe as T))` (fix 3 on the prototype).
6.  **fb7eff130/ac31fd198:** `IdentifiedFacetType` moved to check/ with a
    new API; sem_ir's pair deleted (the modify/delete conflicts) while SC-1's
    `StructuralRequirement` lives there; seven SC-1 lines
    (structural_conformance.cpp:37, :304, :409, :539, :544, :661;
    structural_conformance.h:45) spell `SemIR::IdentifiedFacetType`. Ported.
7.  **b1de0e037:** `TryToIdentifyFacetType`/`RequireIdentifiedFacetType` take
    `SemIR::TypeId`; four fork callers passed `GetTypeInstId` (two in
    structural_conformance.cpp, impl.cpp's `LookupRequireInterfaces`,
    impl_lookup.cpp's helper). Converted.
8.  **d50576ca1's `LocalPatternMatch(..., loc_id, ...)`:** three callers in
    refutable_binding.cpp (:539, :583, :617) passed three arguments; the
    pattern's `LocId` inserted.
9.  **1b0a5709e moved `CheckDefaults`** into function.cpp
    (`CheckFunctionParams`), still returning the level's full count after
    diagnosing a missing default (tip function.cpp:688-820, :816); W-362's
    trailing-default count is carried there (the pin `fail_default_not_
    trailing` crashed at pattern_match.cpp:1275/:1805 before OV-4's fix).
10. **9fb428d71** removed `RequireSpecificDefinition` and its type: the fork
    side of eval_inst.cpp hunk 2 carries the cut's evaluator, lower/type.cpp
    and type_iterator.cpp the cut's placeholder lines. Dropped.
11. **d50576ca1's `AliasBinding`** for a parameterless choice alternative
    replaces the fork's `WrapperBinding`-based `MakeLetBinding`; the match
    lane (handle_match.cpp's two `WrapperBinding` sites, member_access.cpp's
    `TryGetAs<WrapperBinding>` arm, pattern_match.cpp's comment) resolves an
    `AliasBinding` constant the same way: the seven choice, 17 match and 12
    `Core.Result` goldens pass on the prototype with no new STDERR.
12. **57bf903ef:** `CheckRequiredDefinitions` returns `bool` and runs in a
    cycle; the fork callers convert.cpp:1709 and refutable_binding.cpp ignore
    the result (no edit); OV-2's definition check inside it must run once
    (the once-flag; the prototype's fix 1 and fix 5).
13. **W-069 lane a1 is superseded** by d50576ca1 and 19f1bf94d: `GlobalRef`,
    `GetOrCreateGlobalBinding`, `MangleGlobalBinding`, covering Copy, Pointer
    and None value reprs, class-scope statics and cross-file references
    through `GetCanonicalFileAndInstId`, with `Custom` a FATAL TODO exactly
    as the fork's Declined; the 2026-11-09 weekly row named only the
    `GlobalRef` inst. The fork's sites: the two conflict hunks plus eleven
    clean-merging ones (file_context.cpp:115, :127, :196-205;
    function_context.cpp:260-267, :316-323, :344-409; handle.cpp:288-310;
    mangler.cpp:370-399; mangler.h:55; the `GlobalLetBinding` struct and four
    members). Retired (D-UA3-8); the pins stay.
14. **TP-1's 4-argument `FindStorageArgForInitializer`:** three clean-merging
    callers (lower/function_context.cpp:547, lower/handle.cpp:88,
    check/convert.cpp:3751) do not compile against upstream's expr_info.h;
    moved to `...InSpecific` and the 2-argument form.
15. **EH-A's `Main.Run` returning `Core.Result`** already routes through
    upstream's `SetEntryPointReturnInt32` (lower/type.cpp), which under
    9fd28f730's `ReturnKind` lands in the `CARBON_FATAL` `EntryPointInt32` arm
    of upstream's `ReturnExpr` handler: every EH-A main_run golden and program
    would abort in lowering; the D10 epilogue is re-expressed in that arm.
16. **Duplicate declarations after a naive keep-both:** `CopyObject(TypeInFile,
    llvm::Value*, llvm::Value*)` and `AddGlobalToCurrentFingerprint` on both
    sides of lower/function_context.{h,cpp}; `TryResolveTypedInst(
    CustomLayoutType)` in import_ref.cpp (upstream imports the kind since
    66a250ad9); `DoPreWork(StructPattern)` in pattern_match.cpp. One of each.
17. **W-372's parse half is silent:** upstream's parse/handle_pattern_list.cpp
    merges clean and emits `PatternListUnderscoreField` (not `UnderscoreName`)
    for `_` with the `,`? grammar; the fork's check `_` discard keyed on
    `UnderscoreName` never fires after a clean merge. Rekeyed, for the
    refutable contexts only (item 24; amended 2026-11-23, review fold: A-M2).
18. **The LLVM pin:** MODULE.bazel moves to c744694c6ae1 and three merged
    lines use APIs the old LLVM lacks (driver/compile_driver.cpp's
    `PassBuilder(module_->getContext(), ...)`, lower/constant.cpp's
    `IRBuilder<>(context.llvm_module())`, lower/function_context.cpp's
    `builder_(file_context.llvm_module(), ...)`); the tip pin's clang is
    built with `CLANG_ENABLE_CIR=ON`, so the link needs the MLIR and CIR
    archives (ARB-5). The arbiter's second LLVM build (ARB-4) and the three
    variables (D-UA3-4).
19. **947c1eb52's `Core.Array`:** SL-1's slice.carbon:21 names `array(T, N)`
    without importing prelude/types/array (`name Core.Array implicitly
    referenced here, but not found`, poisoning every test); lower/testdata/
    array/mixed_constant_init.carbon (SL-2's, fork-only) includes
    min_prelude/int.carbon where upstream's array goldens take
    min_prelude/array.carbon; the designdocs sample X11 (templates.md:590-596)
    pins `cannot initialize array with dependent bound from a list of
    initializers`, which the tip accepts (D-UA3-14).
20. **Found by the prototype's gate, not by reading:** (a) upstream's
    throwaway generic region around a `where` expression (be0f11be9,
    handle_where.cpp's `StartGenericDecl`/`DiscardGenericDecl`) swallowed
    TP-1's `T.Item` access action in `alias FT = HasItem where .Item = T.Item`
    inside a template class, so a field `c: Tag({.a: FT})` stayed
    template-dependent in the specific and `CanDestroyType` met a
    `SpliceInst` (FATAL custom_witness.cpp:515; generic/template/
    deduce_class_args.carbon split `class_template_field_of_where_alias`);
    the region is discarded with the fork's
    `DiscardGenericDeclIntoEnclosingGeneric` (TP-1/CT-1, handle_alias.cpp's).
    (b) 54728e47f's `ExportNameScopeToCpp` requires the specialization's
    specific (`CHECK scope_specific_id.has_value()`, export.cpp:462) which
    OV-3's per-member export in cpp/generate_ast.cpp did not pass
    (interop/cpp/function/export/overload_set.carbon split
    `fail_todo_generic_class_set`); it passes `lookup.specific_id`. (c)
    VA-1's `IdentifierNameExpr` handler (D-VA-11's pack-name check) re-did the
    lookup with `LookupUnqualifiedName` and `BuildNameRef` and never reached
    d50576ca1's `TryGetLookupResultInCurrentScope`, so a non-constant global
    `let` reference was a `WrapperBinding` with no value (CHECK
    lower/function_context.cpp:309; lower/let/global_runtime.carbon); the
    pack-name check now sits inside `HandleNameAsExpr`. (d) The merge's
    `IsCoreDestroyImplInFile` compared an imported IR's interface `NameId`
    against the check unit's `CoreIdentifierCache` id; a `NameId` indexes its
    own unit's stores, so the prelude's IRs matched `AnyInt`, `UnsafeAs`,
    `MulAssignWith`, ... and `HasUserDestroyImpl` covered `Int(N)`, `UInt(N)`
    and `Array(T, N)` (27 fork splits failing: every union golden, the
    exported union, `atomic_of_carbon_class`, `union_scope_set`,
    `union_pointer_field`); the name is compared as a string through the
    IR's own identifier store and the local loop skips import-materialized
    impls. (e) Nine compile sites from the keep-going build:
    `MaterializeIfInitializer` takes `loc_id`; `PerformCppOverloadResolution`
    takes `callee_expr_id` (cpp/sum_type.cpp); eval.cpp's `SaveAndRestore`
    and `SetAccessContext` became `CheckedSaveAndRestore` and
    `FindAccessContext`; scope_stack.cpp's `NonConstantAccess::Disallowed`
    argument; expr_info.cpp's pair return; handle_pattern_list.cpp's missing
    `return true`. (f) prek's check-toolchain-diagnostics rejects a second
    declaration of `MissingDefinitionInImpl` (the audit's "move the OV-2 check
    before the loop with its own diagnostic" is not available).
21. **Checked and not breaking:** kind-count limits (TokenKind 164, NodeKind
    320, InstKind 199 < 256); the removed hash seed (13ecad24b) meets no
    fork-added `CarbonHashValue`; `LowerToLLVM`'s new `GetInstNamerFn`
    arrives through upstream's unmodified driver caller; `cc_fuzz_test`
    predates the cut; `ConvertCallArgs`, `GetOrExportFunctionToCpp`'s
    defaulted fourth argument, `PushForSameRegion`, `AddReturnInstWithCleanups`,
    `PerformCall`, merge.h, `StableStack` (no fork-added `where_stack` use);
    no fork tool parses textual SemIR or diagnostic text (runner.py matches
    `EXPECT-EXIT`/`EXPECT-STDOUT` only; gate.sh parses gtest lines; the
    register reads upstream's goldens); W-378's in-place construction
    survives the clean check.cpp merge (`landed`).
22. **One fork mechanism the merge breaks and does not re-express:** OP-2
    item 10 / D-FO1-1 (`fn Next(self) -> Core.Optional(Self)` inside a class
    with its own `Copy` and `Destroy` impls). Since 05a7ecbd3 `Core.Destroy`
    is `SubobjectDestroy & DestroyImpl`; the class's declared `DestroyImpl`
    answers its half without completing the class, but the `SubobjectDestroy`
    half is a synthesized witness whose `Op` body needs the class's fields,
    so forming `Core.Optional(Self)` inside the definition fails: `cannot
    convert type `Self` into type implementing `Core.OptionalStorage``
    (the planner's probe on the prototype's install, exit 1; the same shape
    with `Core.Destroy` checks on tp2-base's; out of line, after the class,
    it checks on the prototype's). Two splits fail: named_constraint/
    template_constraint.carbon `self_facet_in_signature_required` and
    optional/destroy.carbon `incomplete_self_signature`. D-UA3-13.
23. **Found by review A, not by the prototype's gate: `friend` in a union
    body crashes** (added 2026-11-23, review fold: A-M1). Upstream 5fed32a9a's
    `HandleParseNode(FriendDecl)` accepts a `ClassType` or
    `ParameterizedClassType` access scope and appends the friend's constant
    with `context.friend_scopes_stack().AppendToTop(...)`; handle_class.cpp
    pushes that array in `ClassDefinitionStart` and moves it into
    `class_info.friend_scopes` in `ClassDefinition`. The fork's union IS a
    `ClassType`, the parser admits `friend` in a union body
    (parse/handle_decl_scope_loop.cpp's `set(Friend, ...)` applies to
    `UnionContext`; the `unset` list for unions names `adapt`, `base` and the
    nested types only), and handle_union.cpp's two definition handlers (UN-1,
    fork-only, clean-merged) push and pop `field_decls_stack` and
    `vtable_stack` but not `friend_scopes_stack`. Measured: the probe
    `class C {} union U { friend C; var a: i32; var b: f64; }` on the
    prototype's install aborts with `CHECK failure at common/array_stack.h:71:
    !array_offsets_.empty(): Must call PushArray before AppendToTop` (stack
    `HandleParseNode(FriendDecl)`); on tp2-base it is a clean `error:
    semantics TODO: `friend decl not supported in check``, exit 1. No golden
    covered the shape, so the prototype's green gate hid a regression R33 (a)
    would have landed. Resolution in M (class B, UN-1 mirrors the class
    handlers): `UnionDefinitionStart` pushes the array after
    `vtable_stack().Push()` and `UnionDefinition` copies it into
    `class_info.friend_scopes` and pops it exactly as handle_class.cpp:434-441
    does; the fork golden check/testdata/union/friend.carbon (three splits:
    `friend_class`, a friend class reading a private union field;
    `fail_non_friend`; `fail_friend_var`, upstream's `FriendNotNameScope`
    shape) is added in M with no CHECK lines and filled by F (§2.7, §4). The
    rev 2 re-measurement (label ua3-fixer, §0.5) runs the probe and the
    union-body sweep of §8.1 step 9 on the amended tree.
24. **Found by review A: the `_` discard was dead in every non-match lane**
    (added 2026-11-23, review fold: A-M2). The prototype's
    `PatternListUnderscoreField` handler recorded the `_` for every struct
    pattern, but only the match pre-work (`DoMatchCaseStructPreWork`, reached
    under `MatchCaseState` or `in_match_case_bind`) reads
    `has_trailing_discard`; upstream's `let`/`var`/parameter lane converts
    the initializer to the pattern's own struct type, so `let {.a = x: i32,
    _} = {.a = 1, .b = ()};` diagnosed ``struct `{.a: i32}` has no field named
    `b` `` (`StructInitUnexpectedFieldInLiteral`; also `var ... _,` and a
    class-scope `let`; measured on the prototype's install) where upstream's
    patterns/struct.carbon split `fail_todo_underscore` and tp2-base print a
    TODO, and docs/design/pattern_matching.md says the program is valid. Rev 1
    had recorded the refill as "the fork implements upstream's TODO" (R16
    (b)/R17: a wrong diagnostic adopted by refill with a rationalization).
    Resolution in M: the `PatternListUnderscoreField` handler returns
    upstream's `context.TODO(node_id, "Struct pattern underscore field")`
    unless `context.full_pattern_stack().CurrentKindIs(FullPatternStack::Kind::
    MatchCaseArm)` (the refutable contexts W-077 implements the discard for);
    `fail_todo_underscore` keeps upstream's TODO and name, and the `_`
    outside the match lane stays W-079's residue, pinned by let/
    struct_pattern.carbon's new split `fail_todo_underscore_param` (§2.3,
    D-UA3-6, §0.6).

### §0.5 The prototype's measured lines (label ua3-proto; verbatim)

Worktree /home/user/carbon-ua3-proto, detached, base a9892d4bb; merge
08be343f7 ("UA-3 prototype merge of upstream 7a3608bab into 701863aa5"),
then 696579ae4 fix 1, 111b09e0e fix 2, cf61d095e fix 3, 7f50ff1ab fix 4,
06c469e15 fill, 95df37622 fix 5 = HEAD; `git status` clean. Artefacts under
the session scratchpad's ua3/proto/ directory (the literal path is in
Appendix C; commits.txt, resolutions.tsv with 197 rows,
resolution-vs-upstream.patch =
`git diff 7a3608bab HEAD -- . ':(exclude)*testdata*'`, 759 files; the
messages msg-merge.txt and msg-fix1..5.txt, msg-fill.txt; the probes).

<!-- google-doc-style-ignore -->

```text
gen_ninja.py: LLVM 24.0.0git: LLVM_SRC=/home/user/llvm-project-c744694 LLVM_BUILD=/home/user/llvm-build-c744694 LLVM_OVERLAY=/home/user/arb/deps/llvm-overlay-c744694/utils/bazel/llvm-project-overlay
gen_ninja.py: file_test manifest: 2114 test files
=== build.sh done status=0 2026-11-16T22:50:25Z
GATE ua3-proto: 1660 passed, 454 failed (454 per-test FAILED line(s) counted; binary exit 1)   [cf61d095e, before fix 4]
GATE ua3-proto: 1666 passed, 448 failed (448 per-test FAILED line(s) counted; binary exit 1)   [7f50ff1ab, before the fill]
Ran 2114 tests in 14913 ms wall time, 56285 ms across threads
AUTOUPDATE ua3-proto: 448 file(s) changed by this run; 0 pre-existing local change(s) untouched (binary exit 0)   [pass 1]
AUTOUPDATE ua3-proto: 28 file(s) changed by this run; 420 pre-existing local change(s) untouched   [pass 2]
AUTOUPDATE ua3-proto: 0 file(s) changed by this run; 448 pre-existing local change(s) untouched   [pass 3, the fixpoint]
AUTOUPDATE ua3-proto: 0 file(s) changed by this run; 0 pre-existing local change(s) untouched   [after fix 5's rebuild]
GATE ua3-proto: 2108 passed, 6 failed (6 per-test FAILED line(s) counted; binary exit 1)   [HEAD 95df37622]
Ran 2114 tests in 13321 ms wall time, 50234 ms across threads
gate ua3-proto: source patches ...: 0001-check-unit-infos-in-place.diff landed toolchain/check/check.cpp
CONFORMANCE ua3-proto: PASS 226 / FAIL 0 / SKIP 15 over 241 programs; bullets 51 PASS, 0 FAIL, 5 SKIP, 0 NOT-WRITTEN (of 56 in the gap-analysis table) (runner exit 0)
checked 294 quotes, 0 failed            [check_quotes.sh <proto> 7a3608bab rg1-quotes.tsv]
checked 96 silence checks, 0 failed     [check_greps.sh <proto> 7a3608bab rg1-checks.tsv, default cut c1e83b0b7]
checked 96 silence checks, 7 failed     [the same with cut 7a3608bab: H4.5, H8.5, H8.7, H10.4, H10.8, H11.4, H11.10 read 0]
self-test: 241 programs parsed, 56 bullets in table, OK
check_samples: 19 program blocks, 70 fixtures (compiled), 2 W2 hits (1 allowlisted, 1 qualified); 15 errors
check_faq: 13 reproducers run, 2 errors
```

<!-- google-doc-style-resume -->

The three earlier gate runs aborted (exit 134) on the crashes fix 3 removed.
The six gate failures at HEAD: four files of `fail_` pins that upstream's
window made succeed (function/overload/default_values.carbon, W-360;
interop/cpp/function/export/overload_set_default.carbon, W-361;
lambda/lambda.carbon's `fail_todo_as_non_constant_template_argument`;
let/fail_todo_struct_pattern.carbon whole with its four splits, W-372) and
two of §0.4 item 22. The manual-fix list after pass 1 (unchanged by passes 2
and 3) names exactly those: eight `fail_` splits that now succeed and two
splits that now fail. The fill commit changes CHECK lines only: for every
one of its 448 files the non-CHECK lines before and after are identical
(re-verified by the planner: 0 of 448 differ). The conformance line ran
twice (at 7f50ff1ab and at HEAD, identical; scoreboard generated
2026-11-16T22:53:04Z); the two SKIPs beyond tp2-base's 13 are TP-2's W-396
and W-397 (the SKIP sets differ by exactly those two paths). W-356's probe
on the prototype: inplace.carbon exit 0; refget.carbon exit 1 with "value
expression passed to reference parameter" for both operands and no CHECK
failure; valget.carbon exit 0 (upstream's `-> val T`). The checkers'
errors: 14 are the renderer's wrap of the message the checker reads as
the first error line, 1 (X11) compiles where an error was expected
(947c1eb52); check_faq's two (match-return, no-c-headers) print the same
text under the renderer's prefix. Greps on the prototype (§8.2): `EST_
BasicNoexcept` 4 with awk 1; `__clang_call_terminate` in 40 lower goldens
(floor 35); `is_choice` 6; `OperandDependence(context,` 0; `GenericClassType`
0; bare `CalleeFunctionInfo` 0; `MangleGlobalLetBinding`,
`TryEmitGlobalLetValue`,
`PerformAddrOf`, `struct_pattern_names_stack`, `builder.Note(`, `.Context(`,
`SemIR::IdentifiedFacetType`, `RequireSpecificDefinition`,
`SubstImplSelfWitnesses`, `MakeLetBinding`, `BuildCarbonDestroyWitness`,
`CoreInterface::Destroy` all 0; the .github guard 5; check.cpp:437-439
`reserve`/`emplace_back` (W-378). lower/slice/buf.carbon: 3 `free` before and
after (D-UA3-5's pin; rev 1 wrote "(R-3)", an ambiguous cite, corrected
2026-11-23, review fold: B-m7). generic/template/pointer.carbon: 1
`addr_of_action` before and after.

**Rev 2's re-measurement (label ua3-fixer, 2026-11-23; verbatim).** The
fixer's detached worktree /home/user/carbon-ua3-fixer at the prototype's HEAD
95df37622 plus the amendments the review fold makes to the resolutions (§0.4
items 23 and 24, A-m2's comments) and the five retriages R-1 to R-5 in their
rev 2 form (R-3 renames; §3), built first by the prototype's scratch build.sh
(the arbiter of record had not yet synced ARB-5 when the build started) and
then by /home/user/arb/carbonbuild/build.sh itself, which regenerated the same
build.ninja ("ninja: no work to do"); every other line is the arbiter of
record's script (install.py, gate.sh, autoupdate.sh). The lines are in
Appendix C's rev 2 paragraph and summarized here:

<!-- google-doc-style-ignore -->

```text
gen_ninja.py: LLVM 24.0.0git: LLVM_SRC=/home/user/llvm-project-c744694 LLVM_BUILD=/home/user/llvm-build-c744694 LLVM_OVERLAY=/home/user/arb/deps/llvm-overlay-c744694/utils/bazel/llvm-project-overlay
gen_ninja.py: file_test manifest: 2115 test files
=== build.sh done status=0 2026-11-23T14:50:52Z          [the prototype's scratch build.sh]
ninja: no work to do.                                      [/home/user/arb/carbonbuild/build.sh, ARB-5 synced]
=== build.sh done status=0 2026-11-23T14:52:21Z
installed 2106 copied, 133 generated, 36 symlinked files under /home/user/arb/install/ua3-fixer/lib/carbon
GATE ua3-fixer: 2109 passed, 6 failed (6 per-test FAILED line(s) counted; binary exit 1)   [before the refill: default_values, let/struct_pattern, template_constraint, optional/destroy, patterns/struct, union/friend; 0 crash lines]
gate ua3-fixer: source patches ...: 0001-check-unit-infos-in-place.diff landed toolchain/check/check.cpp
AUTOUPDATE ua3-fixer: 6 file(s) changed by this run; 7 pre-existing local change(s) untouched (binary exit 0)   [pass 1]
AUTOUPDATE ua3-fixer: 0 file(s) changed by this run; 13 pre-existing local change(s) untouched (binary exit 0)  [pass 2; pass 3 the same]
GATE ua3-fixer: 2114 passed, 1 failed (1 per-test FAILED line(s) counted; binary exit 1)   [union/friend.carbon: its `u8` needs Core.UInt, absent from min_prelude/int.carbon; the source line became `var other: i32;`]
AUTOUPDATE ua3-fixer: 1 file(s) changed by this run; 12 pre-existing local change(s) untouched (binary exit 0)   [pass 4]
AUTOUPDATE ua3-fixer: 0 file(s) changed by this run; 13 pre-existing local change(s) untouched (binary exit 0)   [pass 5, the fixpoint]
GATE ua3-fixer: 2115 passed, 0 failed
Ran 2115 tests in 14559 ms wall time, 55185 ms across threads
CONFORMANCE ua3-fixer: PASS 226 / FAIL 0 / SKIP 15 over 241 programs; bullets 51 PASS, 0 FAIL, 5 SKIP, 0 NOT-WRITTEN (of 56 in the gap-analysis table) (runner exit 0)
```

Probes on /home/user/arb/install/ua3-fixer/bin/carbon (`compile
--phase=check`): `union U { friend C; ... }` exit 0 (the prototype: `CHECK
failure at common/array_stack.h:71`); `let {.a = x: i32, _} = ...` and `var
{.a = x: i32, _,} = ...` and `fn F({x: i32, _});` exit 1 with ``semantics
TODO: `Struct pattern underscore field` `` (the prototype: ``struct `{.a:
i32}` has no field named `b` ``); `match (v) { case {.a = x: i32, _} => ...
}` exit 0 (the discard still works in the match lane); the other refutable
contexts, `if (let {.a = x: i32, _} = v)` and `let {.a = x: i32, _} = v
else {...}`, exit 0 on the re-measurement and on the prototype alike (the
lane gate and the pre-work key on the same `MatchCaseArm` kind; K-16). The
union-body sweep
(§8.1 step 9; each shape run on ua3-fixer, ua3-proto and tp2-base): a
class-scope `let` (d50576ca1) exit 0 on all three; a `static var` exit 0 on
all three; a terse-body method with a return type diagnoses "cannot specify a
return type with `=>`" (tp2-base: the `HandleTerseBodyArrow` TODO); `-> auto`
exit 0 (tp2-base: the `HandleAutoTypeLiteral` TODO); a `where` assignment in
the body diagnoses "`where` assignment declaration found in invalid scope"
plus upstream's invalid-parse-tree TODO (tp2-base: "unrecognized declaration
introducer"); a `private fn` called from outside diagnoses "cannot access
private member `Make` of type `U`" on all three; `impl as Core.DestroyImpl`
in a union body exit 0 (tp2-base: no `DestroyImpl`); no crash line in any
shape on any install. The manual-fix list after pass 1 names one entry,
union/friend.carbon's `friend_class` (the `u8` line), none after pass 4. The
amendments are one commit on the fixer's worktree (its diff against
95df37622, 13 files, is Appendix C's amendments.patch); the worktree and the
label are removed when the fold is committed.

<!-- google-doc-style-resume -->

### §0.6 Ledger items and gap rows the advance moves

| Item or row | Upstream commit(s) | State after the merge | How UA-3 shows it |
| --- | --- | --- | --- |
| W-354 | 05a7ecbd3 | DISCHARGED: the yield and keying dropped, the predicates on `DestroyImpl`, the prelude spellings, buf.carbon's three `free` (3 before, 3 after) | the custom_witness.cpp diff, the union and export-triviality goldens, SL-1's records note (§2.2, A.7) |
| W-356 | none (the probe) | DISCHARGED: refget.carbon diagnoses and exits 1 with no CHECK failure on the prototype (and on tp2-base) | the run's output quoted in the note (A.7) |
| W-360 | 503f09037 | DISCHARGED: `fail_todo_generic_member_default` passes; renamed by R-1; the selection change recorded (D-UA3-9) | default_values.carbon's fill |
| W-361 | 9799a2326, c7de72757, 8fdc8ebc3 | DISCHARGED: `fail_cpp_omitted` passes (C++ selects the defaulted member); renamed by R-2; recorded before the golden moves (D-UA3-9, R30 (c)); the per-member export still carries `_CF__carbon_thunk:overload<N>` | the overload_set_default pair's fill |
| W-362 | 1b0a5709e | DISCHARGED on the fork (the fix lives in function.cpp's `CheckDefaults`); still owed upstream | the pin `fail_default_not_trailing` passing |
| W-363 | none | OPEN: tip call.cpp:73 still has the CHECK; the note re-cites the tip's line | the ledger note |
| W-372 | c6b54b57e, 5ae3dcaa9, d50576ca1 | DISCHARGED: upstream's layer taken whole; the fork's `_` discard re-expressed on `PatternListUnderscoreField` for the refutable contexts only; let/fail_todo_struct_pattern.carbon renamed let/struct_pattern.carbon with its splits' `fail_todo_` dropped (R-3, a rename, not a deletion); the `_` outside the match lane keeps upstream's TODO (amended 2026-11-23, review fold: A-M2 / A-M4 / B-M1) | match/struct_pattern.carbon's fill (the `_` splits keep their behavior); patterns/struct.carbon's `fail_todo_underscore` keeps upstream's TODO and name; let/struct_pattern.carbon's four splits pass and its `fail_todo_underscore_param` pins the TODO |
| W-079 (W-077's residue: the `let`/`var`/parameter lane) | c6b54b57e, d50576ca1 | DISCHARGED for the lane (upstream's conversion-first layer checks `let`, `var`, parameter and class-scope struct patterns; the four W-077 pins pass); its `_` clause stays OPEN as the residue: the `_` field outside the refutable contexts is upstream's TODO (added 2026-11-23, review fold: A-M2 / B-M1) | let/struct_pattern.carbon (the renamed pins plus `fail_todo_underscore_param`), patterns/struct.carbon's `fail_todo_underscore`; the ledger note (A.7) |
| W-378 | 92534a0e0 | KEPT (still DISCHARGED; upstream did not fix it): GATE reads `landed` | the gate line |
| W-394 | dbf02ad10 | DISCHARGED: upstream's `AddrOfAction` inst and handler; TP-1's `PerformAddrOf` deleted; TP-1's two stringify cases KEPT (D-TP-23's rendering of every action kind, upstream renders none); register row H10.1 ALIGNED (amended 2026-11-23, review fold: A-M3) | pointer.carbon's fill; generic/template/index.carbon:332 and :337 still print `D(&p.n)` and `D(&p.m)` |
| W-069 (DISCHARGED) | d50576ca1, 19f1bf94d | a dated "superseded by upstream PR 8061" note; the pins stay | the lower/let goldens' fill |
| W-125 (open) | 05a7ecbd3 | unchanged in substance: the `is_choice` clause now sits in `MakeSubobjectDestroyOpBody`'s `ClassType` arm after upstream's array arm; a dated note | `is_choice` 6 |
| W-355 | the cut moves; the weekly check of 2026-11-23 re-anchored the register to 0072b2812 | check_greps.sh's default cut becomes 7a3608bab; the seven L rows' expected counts are MEASURED at D as `git log 7a3608bab..<anchor> -- <paths> \| wc -l`, `<anchor>` being the tip the latest weekly entry anchored (today 0072b2812: H4.5 1, H8.5 0, H8.7 0, H10.4 0, H10.8 1, H11.4 0, H11.10 1); check_quotes.sh runs at `<anchor>` (amended 2026-11-23, review fold: B-B1 / A-m3) | the two scripts' lines at the records commit, both "0 failed" at `<anchor>` |
| W-037 | 1b0a5709e, b766aa4d1 | note only: fn expressions and terse bodies arrive; the lambda split `fail_todo_as_non_constant_template_argument` passes and is renamed (R-4) because TP-1 performs `f(42)` as a `CallAction` in the specific — upstream 7a3608bab still rejects the split ("value of type ... is not callable"), so this is a convergence candidate, recorded in the register (amended 2026-11-23, review fold: A-m1) | lambda.carbon's fill; the probe's LLVM IR (`_CPassToTemplate...` calling the enclosed fn) |
| gap row 45 (Type system: C++ interop — bi-directional inheritance ..., PARTIAL) | 2e2125585 | re-cited: export/override.carbon's `fail_todo_generic` now pins upstream's narrower TODO "generic class overriding methods from a C++ virtual class" (generate_ast.cpp:568) in place of class.cpp's "generic class deriving from C++ virtual class" (added 2026-11-23, review fold: B-m4) | the row's text (A.11) |
| W-401 (new) | 05a7ecbd3 | FILED: OP-2 item 10 re-opened for the `SubobjectDestroy` half (D-UA3-13); the two splits `fail_todo_` | the two splits' fill |
| W-402 (new) | b7ea32c3a | FILED: the fork's repository guard in check_dependent_pr.yaml dropped with upstream's whole file; the owner's call when Actions returns (D-UA3-16) | the five-hit grep |
| gap row 81 (Stdlib: Slices, DONE) | 05a7ecbd3 | the evidence's "the class's declared `Destroy` impl over the synthesized witness, D-SL-16" re-cited to upstream's `SelfDestruct` calling the declared `DestroyImpl.Op` (W-354) | the row's text |
| gap row 80 (Stdlib: Optional, DONE) | 05a7ecbd3 | the evidence's custom_witness.cpp adapter arm cite re-read (it survives); a W-401 note appended for item 10 | the row's text |
| gap row 70 (matching, PARTIAL) | none | its match goldens refilled; no text change | the fill |
| the gap header's first sentence | the landing | A.8's form with the landing's figures | the records commit |

### §0.7 The register at 7a3608bab, and its anchor (rewritten 2026-11-23, review fold: B-B1 / A-m3)

Both scripts read upstream's tree at the sha they are given (`git show
$tip:$path`), so the merge itself moves no quotes row and no G or T count. Rev 1
measured the prototype at 7a3608bab: `check_quotes.sh` "checked 294 quotes, 0
failed" and `check_greps.sh` "checked 96 silence checks, 0 failed" with the
default cut c1e83b0b7, and "7 failed" with cut 7a3608bab (the L rows H4.5, H8.5,
H8.7, H10.4, H10.8, H11.4, H11.10 read 0, because `git log cut..tip` is empty
when the cut is the tip), and wrote the seven rows' new counts as 0. That was
wrong at execution time: W-355's method anchors the register to the weekly
check's tip, which runs AHEAD of the cut, and the weekly check of 2026-11-23
(6bde6699d, db7d28397; on trunk since cb7821735) re-anchored rg1-quotes.tsv
(H6.2, H11.2, T5.6, T2.8, H10.8's lines) and the L rows H4.5 to 9, H10.8 to 10
and H11.10 to 14 at upstream's tip 0072b2812, 21 commits past 7a3608bab.
Measured 2026-11-23 on trunk's tables: `check_quotes.sh <repository> 0072b2812
rg1-quotes.tsv` prints "checked 294 quotes, 0 failed" and `check_greps.sh
<repository> 0072b2812 rg1-checks.tsv` "checked 96 silence checks, 0 failed"
(default cut), and with cut 7a3608bab "7 failed": H4.5 got 1, H8.5 0, H8.7 0,
H10.4 0, H10.8 1, H11.4 0, H11.10 1 (`git log --oneline 7a3608bab..0072b2812 --
<paths>`: 0072b2812 itself, the diagnostics-model commit, touches
operators.carbon, call.cpp and range_for.carbon). So the records commit D
(D-UA3-15): reads `<anchor>`, the tip the latest weekly entry anchored
(0072b2812 today; a later weekly's tip if one lands before D); changes
check_greps.sh's default `cut=${4:-c1e83b0b7}` and its comment to 7a3608bab;
writes each of the seven L rows' expected count as the MEASURED `git log
--oneline 7a3608bab..<anchor> -- <paths> | wc -l` (0 only where no commit in
7a3608bab..<anchor> touches the paths), under a "#" line naming both shas;
leaves rg1-quotes.tsv as the weekly left it; and runs both scripts at
`<anchor>`, expecting "0 failed" from each. A weekly records commit landing
between M and D moves `<anchor>` and the rows: T is re-made onto that trunk
(D-UA3-1) and the register step is re-measured, never copied. Rows whose
classification UA-3 changes: H10.1 (TP-1; DRIFT for `AddrOfAction`, W-394)
becomes ALIGNED; DR-0's register entry (vi) (W-372) becomes ALIGNED; D-RG-16's
block (W-354) and D-RG-18 (W-356) gain their discharge notes; every other NONE
and ALIGNED entry holds (the scripts' pass is the evidence). The T12 rows (fork
code inside upstream functions) stay 0 at the tip: T12.3's `is_choice` is still
absent from upstream's rewritten custom_witness.cpp.

### §0.8 The id re-scan (2026-11-16, read-only)

`git grep -ohE 'W-[0-9]{3}'` over fork/ at trunk a9892d4bb finds W-400 the
highest id (TP-2 filed W-396 to W-400; 71 mentions of W-400, all TP-2's);
701863aa5, origin's claude/carbon-fork-0-1-safe-wip, -safe and -ehc reach
W-399 (as range bounds) or lower; -tp2 reaches W-400. W-381 to W-385 are
EH-C's reserved ids, unused; W-386 to W-393 are SAFE-3's reserved ids,
unfiled; no W-4xx but W-400 appears anywhere (the prototype's fork/ and this
worktree's fork/ included). **W-401 and W-402 are the next free ids** and
are filed by this plan's records commit (§0.6); the implementer repeats the
scan before the records commit (§8.3) and takes the next free ids if the
scan has moved.

## §1 Design: the decisions, each with its break condition

Every decision is auto-adopted under R29 (a) and veto-able after the fact.
The prototype measured each one that could be measured; where a decision
departs from the prototype it says so and names the fill that re-measures
it.

-   **D-UA3-1 — Target, base and shape.** The cut advances to the full tip
    7a3608bab, the sha the weekly checks of 2026-11-09 and 2026-11-16 anchored
    the direction register to, in ONE merge commit M on top of trunk as it
    stands when T is made — cb7821735 on 2026-11-23 (ARB-5's landing and the
    weekly check of 2026-11-23 on top of a9892d4bb, TP-2's landing, the
    prototype's base) — which the branch takes first by a merge commit T
    ("merge trunk <sha> into claude/carbon-fork-0-1-ua3 before M", TP-2's
    949a8f574 precedent; the branch holds only this plan, so T conflicts in
    nothing). No rebase, ever (R33 (a)'s "never a rewrite of the PR's
    history" and UA-1's D-UA-1; rev 1 cited R32 (e), which is the held-PR
    amendment clause — re-cited 2026-11-23, review fold: B-m6); no
    intermediate cut (every weekly tip is an ancestor of 7a3608bab, so a
    shorter advance would take a strict subset of the same window for no
    gain); no newer tip (the register's anchor is NOT the cut: W-355's method
    re-anchors the quotes and L counts to each weekly check's tip, which runs
    ahead of the cut — 0072b2812 since the 2026-11-23 check — and D-UA3-15
    reads that anchor from the latest weekly entry; a newer cut is the next
    advance's, measured by its own audit and prototype). Trunk moving before
    T or M is the NORMAL case, not a break: records-only landings (weekly
    checks, ARB-n syncs) land weekly; T takes the trunk of the day, the dry
    run is re-run, and the same 194-path set is expected (measured at
    cb7821735: the same 194; a9892d4bb → cb7821735 touches no toolchain, core
    or docs/design file). Break condition: a conflict set other than Appendix
    B's 194 at that trunk (a landing that touched toolchain, core or
    docs/design) — a new finding, recorded in M's message as "not in the dry
    run" and resolved by §0.3's class rules; a weekly records commit landing
    between M and D moves `<anchor>`: T is re-made onto that trunk (a second
    merge of trunk, never a rewrite) and the register step (§8.1 step 5) is
    re-measured (amended 2026-11-23, review fold: B-B1 / A-m3).
-   **D-UA3-2 — Conflict-class policy and where a retirement lives.** A: keep
    both. B: upstream's structure wins and the fork mechanism is re-expressed
    inside it (never upstream hunks grafted into the fork's structure). C:
    upstream's mechanism is adopted, the fork's code is deleted IN M (the
    tree must compile: a class-C conflict cannot keep both sides, UA-1's
    D-UA-2 and its F8d exception show the only separable deletion is one no
    conflict forces), and the fork's goldens and programs stay as pins. X:
    .github takes upstream's whole file. G: the golden's source side by
    §0.3's rule, CHECK lines by autoupdate only. The separable half of each
    retirement — the golden retriages (prefix renames), the let pin's rename
    (no fork golden is deleted: rev 1's "file retirement" reversed
    2026-11-23, review fold: A-M4 / B-M1), the ledger discharge — is its own
    commit R-n after the fill (§3), so the
    merge commit is one atomic resolution and each item's evidence is one
    diff. R17: a class-B re-expression needing a multi-paragraph
    justification becomes a class-C deletion with a residue item (D-UA3-13
    is the one instance). Break condition per file: a resolution the
    implementation review cannot read as one of the five classes.
-   **D-UA3-3 — Goldens.** 107 take upstream's source (`git checkout
    7a3608bab -- <path>`), 13 keep the fork's (their fork source edits are
    the mechanism's: `git checkout HEAD -- <path>` after the merge, which is
    the fork's side), eval/call.carbon is hand-merged in M (upstream's file
    plus the fork's appended split, no CHECK lines written); the 21 goldens
    and programs re-spelled `impl as Core.DestroyImpl` and
    mixed_constant_init.carbon's INCLUDE-FILE line are non-CHECK source
    edits made in M, cited to 05a7ecbd3 and 947c1eb52 (K-11's precedent:
    upstream-intended, never a CHECK line by hand); the new fork golden
    union/friend.carbon is written in M as source lines only (§2.7; its
    CHECK lines are F's; added 2026-11-23, review fold: A-M1). The fill F
    writes CHECK
    lines only: the prototype's fill differs from its pre-fill tree in no
    non-CHECK line over 448 files, and §8 re-verifies that on the product.
    Clearing CHECK lines before the fill is unnecessary with the container
    arbiter (autoupdate rewrites them). Break condition: a theirs-side golden
    whose fork source differs from upstream's by more than CHECK lines (none
    found by the stripped-file diff); a fill touching a non-CHECK line.
-   **D-UA3-4 — The arbiter at the tip pin.** Every arbiter command for a
    merged tree carries `LLVM_SRC=/home/user/llvm-project-c744694
    LLVM_BUILD=/home/user/llvm-build-c744694 LLVM_OVERLAY=/home/user/arb/deps/
    llvm-overlay-c744694/utils/bazel/llvm-project-overlay` (ARB-4; the build
    log's gen_ninja line names the pin, and a build at the old pin fails on
    §0.4 item 18's three lines and would not measure the tree the PR carries,
    R33 (a)). The link at that pin needs the MLIR and CIR archives: ARB-5
    landed on trunk on 2026-11-23 (38ff1b5c5, 7fedf1609, merged as
    cb7821735) and is synced into /home/user/arb/carbonbuild (`grep -c
    libCIR gen_ninja.py` → 2 in both copies; the running instance's
    gen_ninja.py is byte-identical to the record's), so every build runs
    through the arbiter of record and the prototype's scratch copy is
    retired (rev 1 routed build.sh through it; rev 2's re-measurement built
    once through it before the sync and then re-ran the arbiter's build.sh,
    which regenerated the same build.ninja: "ninja: no work to do"; amended
    2026-11-23, review fold: B-M2). A landing precondition (D-UA3-17, §8.4):
    the arbiter of record's `grep -c libCIR` non-zero and `diff -r
    /home/user/arb/carbonbuild /home/user/carbon-trunk/fork/tools/carbonbuild`
    clean, or each difference named in the landing's record (measured
    2026-11-23: gen_ninja.py identical; build.sh differs by the record's
    four-line license header; absl_link_order.py, bzl_eval.py and deps.sh
    differ and env.sh exists only in the instance — the arbiter's owner
    syncs them before L; none of them changes a measured line). The prelude
    at the tip and W-378's fix in the tree: the GATE line must read `landed`,
    never `applied`. Break condition: the gen_ninja line names
    /home/user/llvm-project (the old pin), or the GATE line reads `applied`
    — the build is discarded and re-run; neither is a merge defect.
-   **D-UA3-5 — W-354: destruction under 05a7ecbd3 (class C).** Upstream's
    custom witness serves `SubobjectDestroy` only; `Destroy` is the constraint
    `SubobjectDestroy & DestroyImpl`; `SelfDestruct[T: Destroy](ref t)` calls
    `t.(DestroyImpl.Op)()` then `t.(SubobjectDestroy.Op)()`, so a declared
    `impl as DestroyImpl` runs for every cleanup by impl selection, the
    blanket `impl forall [T: SubobjectDestroy] T as DestroyImpl` with the
    `no_op` `Op` otherwise. The fork's six `Destroy` witness builders and its
    `case CoreInterface::Destroy` are deleted; D-SL-16's declared-impl yield
    (`CanDestroyClass` and `CanDestroyType` answering `NoDestroy` for a class
    with a declared impl) and D-SL-19's class keying are dropped, SL-1's own
    register break condition having fired ("if upstream's destroy-op
    synthesis starts calling declared impls, D-SL-16's yield and D-SL-19's
    keying are dropped in favor of it"); the surviving predicates
    `HasUserDestroyImpl` (the union field rule, the export triviality rule),
    `HasClassKeyedImpl`, `IsTriviallyDestructible` and
    `HasNonTrivialUserCopyImpl` key on a user `impl as DestroyImpl` whose `Op`
    is not the blanket `no_op`, identified by the interface's identifier
    STRING through each IR's own identifier store (`IsCoreDestroyImplInFile`;
    a `NameId` indexes its own unit — §0.4 item 20 (d)), the local store's
    loop skipping import-materialized impls as `HasClassKeyedImpl` does.
    `MakeSubobjectDestroyOpBody` keeps upstream's array arm first, then
    D-UA-9's `is_choice` return and OP-2's adapter arm; the `CustomLayoutType`
    arm and `CanDestroyType`'s `CustomLayoutType` arm stay (D-UA-9, W-125).
    The prelude takes upstream's interim spellings only as far as the merged
    prelude requires: buf.carbon:58, string.carbon:154 (D-RG-16's site) and
    optional.carbon:354 `impl ... as DestroyImpl`, optional.carbon:357
    `SelfDestruct(ref (self.value unsafe as T))`, slice.carbon importing
    prelude/types/array; 16 goldens and 5 programs re-spelled (§2.13). Pins:
    lower/slice/buf.carbon's exactly three `free` (3 before, 3 after,
    measured), stdlib/slices_heap_buf.carbon, the nine union, seven choice,
    17 match and 12 `Core.Result` goldens of D-UA-9, the union and
    export-triviality goldens (the 27 splits fix 4 restored), the five
    re-spelled programs' EXPECT lines unchanged. Break condition: a `free`
    count other than three, a union field rule rejecting `i32`/`u8`/`array`
    (the NameId class), a declared `DestroyImpl.Op` not called from
    `_CSelfDestruct` in a lower golden, or a new STDERR line in the pins —
    fixed at the root, never by editing a golden. Mutant M1 (measured on the
    prototype as fix 4's pre-state): the `NameId` comparison instead of the
    string → 27 union/export splits red.
-   **D-UA3-6 — W-372: struct patterns under c6b54b57e, 5ae3dcaa9, d50576ca1
    (class B).** Upstream's check layer (`struct_type_fields_stack`,
    `PopStructFieldNameNodes`, `DiagnoseDuplicateNames(StructKind::
    StructPattern)`, `InNonStaticFieldDecl`, its `let`/`var` lane and
    `StructName*` diagnostics) is taken whole in handle_pattern_list.cpp's
    four hunks; the fork's match-only gate, `struct_pattern_names_stack`
    (context.h/.cpp) and `StructPatternNameDuplicate`/`Previous` go. The
    fork's `_` discard is re-expressed on upstream's `PatternListUnderscore
    Field` node: its handler (upstream's TODO site) records the `_` as a solo
    node, the `StructPattern` end handler reads it into the fork's
    `has_trailing_discard` field (kept on upstream's `SemIR::StructPattern`,
    marked Fork), the `_`-without-fields diagnostic
    (`StructPatternDiscardWithoutFields`) is emitted there, and a trailing
    comma after `_` is upstream's `,`? grammar; the match pre-work in
    pattern_match.cpp reads the flag. The discard is the REFUTABLE contexts'
    only (a `match` arm's pattern, a pattern condition, `let`-`else`:
    `FullPatternStack::Kind::MatchCaseArm`, whose pre-work walks the
    scrutinee's own type); in every other lane (`let`, `var`, parameters,
    class-scope `let`) upstream's conversion-first layer converts the
    initializer to the pattern's own struct type and reads no discard, so the
    `PatternListUnderscoreField` handler returns upstream's TODO ("Struct
    pattern underscore field") there — rev 1 recorded the `_` as recorded for
    every lane and let the refill turn upstream's `fail_todo_underscore` TODO
    into a false ``no field named `b` `` error (§0.4 item 24; amended
    2026-11-23, review fold: A-M2). The fork-only golden
    let/fail_todo_struct_pattern.carbon (whole file and four splits now
    passing) is RENAMED by R-3 to let/struct_pattern.carbon with the four
    splits' `fail_todo_` prefix dropped and a fifth split
    `fail_todo_underscore_param` (`fn F({x: i32, _});`, upstream's TODO),
    because upstream's patterns/struct.carbon pins `let`/`var`/class forms
    only (no file at the tip has a struct pattern in a parameter list or a
    `let` struct pattern inside a match arm body) and a passing fork pin is
    never deleted (D-UA3-2, R16 (b)) — rev 1's deletion reversed 2026-11-23,
    review fold: A-M4 / B-M1. Upstream's `fail_todo_underscore` split keeps
    its TODO and its name. W-079: the `let`/`var`/parameter lane is
    discharged by upstream's layer; its `_` clause stays open as the residue
    (§0.6). Pins: match/struct_pattern.carbon's `_` splits (the discard),
    patterns/struct.carbon (the TODO and upstream's lane),
    let/struct_pattern.carbon (the fork-only shapes and the TODO). Break
    condition: a `_` split losing its discard (the field walked or diagnosed
    as missing), `has_trailing_discard` never set, or a non-match `_` lane
    diagnosing anything but the TODO. Mutant M2 (predicted): the end handler
    never sets the flag → match/struct_pattern.carbon's discard splits red;
    its let-lane twin M2b (measured as the prototype's state): the handler
    records the `_` in every lane → patterns/struct.carbon's
    `fail_todo_underscore` and let/struct_pattern.carbon's
    `fail_todo_underscore_param` print ``no field named `b` `` instead of the
    TODO (the rev 2 re-measurement, §0.5: with the clause, `let {.a = x: i32,
    _} = ...` and `fn F({x: i32, _});` print `semantics TODO: `Struct pattern
    underscore field``, and the match-lane discard probe still exits 0).
-   **D-UA3-7 — W-394: `AddrOfAction` (class C).** Upstream's inst
    (`ExprCategory::Dependent`, dbf02ad10) and its handler in
    handle_operator.cpp are taken whole; TP-1's `PerformAddrOf` and
    `PerformAction(AddrOfAction)` are deleted from pointer_dereference.{cpp,h};
    `PerformPointerDereference` keeps the fork's `PointerDereferenceKind` form
    with its `DerefOfType` note converted. TP-1's two `StringifyInst` cases
    for the inst (stringify.cpp:766 `IsPrefixAction`/`PushPostfix` and :914
    the case) are KEPT, marked Fork (D-TP-23, W-394): rev 1 decided to delete
    them as "a second spelling of upstream's inst (R32 (d))", which misread
    the rule — upstream designs no stringification for ANY action kind
    (7a3608bab's stringify.cpp:355-372 falls back to `<cannot stringify
    ...>`, zero `*Action` overloads), and D-TP-23 renders every action
    (`AccessMemberAction`, `ConvertAction`, `CallAction`,
    `CompoundMemberAccessAction`, `IndexAction`, `PointerDereferenceAction`,
    `TupleIndexAction`) as the expression it performs; the `AddrOfAction`
    case is that same fork mechanism applied to the inst upstream now owns,
    not a rendering upstream designed differently. Deleting it alone would
    print a dependent `&x` as `<cannot stringify %N: {kind: AddrOfAction,
    ...}>` beside `*p` and `x.n` printed as expressions, drop the
    parenthesization rule (`(&p).n` vs `&p.n`), and regress
    generic/template/index.carbon:332 and :337, which pin ``previously
    declared with return type `D(&p.n)` `` and ``return type is `D(&p.m)` ``
    (the planner's falsifier grep covered pointer.carbon only) — rev 1's own
    break condition would have fired by construction and cost a fix round
    (reversed 2026-11-23, review fold: A-M3). Pins: TP-1's `&` goldens
    (generic/template/pointer.carbon: one `addr_of_action` before and after;
    index.carbon's two `D(&p.n)`/`D(&p.m)` lines, pre-registered in §4).
    Break condition: upstream adds `StringifyInst` support for its actions —
    then upstream's rendering replaces the fork's cases (watch row T13.9).
-   **D-UA3-8 — W-069 lane a1 is superseded (class C).** Upstream d50576ca1
    with 19f1bf94d covers what lane a1 did (`GlobalRef`,
    `GetOrCreateGlobalBinding`, `MangleGlobalBinding`; Copy, Pointer and
    None value reprs; class-scope statics; cross-file references through
    `GetCanonicalFileAndInstId`; `Custom` a FATAL TODO, the fork's Declined).
    Retired: `RegisterGlobalLetBindings`, `LookupGlobalLetBinding`,
    `GetOrCreateGlobalLetVariable`, `PrepareGlobalLetDefinitions`,
    `EmitGlobalLetStores`, `TryEmitGlobalLetValue`, `MangleGlobalLetBinding`,
    the `GlobalLetBinding` struct and four members, the `NameRef` peek, the
    `is_global_ctor_` hook, and the three clean-merging call sites. Pins,
    refilled: check and lower testdata/let/global_runtime.carbon, lower
    let/global_runtime_symbols.carbon (`%total.ref` → `%total.global_ref`,
    the symbol `@_Ctotal.Main` unchanged), global_runtime_specifics.carbon,
    import_choice.carbon, lower/var/import.carbon's `fn X` (W-069's hand-merge
    is now upstream's text, a V-3a convergence). W-069's ledger gains a
    dated "superseded by upstream PR 8061" note; the decision-log entry
    records the retirement. Break condition: a pin's fill showing the
    `TODO: Support global binding with custom value repr` FATAL — then the
    retirement keeps a fork arm for that repr, filed.
-   **D-UA3-9 — The OV-4 residues.** W-360: 503f09037's default-appending in
    `DeduceGenericCallArguments` merges clean beside OV-2's `diagnose` flag
    and SC-1's deferrals; `fail_todo_generic_member_default` passes and is
    renamed `generic_member_default` by R-1. The selection change this
    records before the golden moves (W-360's note): in that split `F(true)`
    moves from the later member `F(b: bool)` to the generic member with the
    defaulted parameter, the first match once deduction appends the default.
    W-361: with 9799a2326, c7de72757 and 8fdc8ebc3 each exported member's
    C++ declaration carries its defaults, so in overload_set_default.carbon
    the C++ side of `fail_cpp_omitted` (`Carbon::F(1)`) now selects the
    defaulted member `F(i32, i32 = 2)` where it was rejected ("no matching
    function for call to 'F'", the pre-fill CHECK lines); the split passes
    and is renamed `cpp_omitted` by R-2, and `divergence_omitted`'s two
    sides are re-read on the fill — this paragraph is R30 (c)'s record,
    made before the fill (the plan commit precedes F). W-362: W-362's
    trailing-default count is carried into function.cpp's `CheckDefaults`
    (1b0a5709e moved it; tip :816 still returns the full count after
    diagnosing), the pin `fail_default_not_trailing` kept; still owed
    upstream. W-363: tip call.cpp:73 still has the CHECK; stays open with
    the tip's line in its note. Break condition: `divergence_omitted`'s
    Carbon side changing (it must not: Carbon's first match is unchanged), or
    `fail_default_not_trailing` crashing.
-   **D-UA3-10 — W-378 kept.** Upstream's check.cpp at 7a3608bab still copies
    `UnitAndImports` out of `map_range` (:431-435); the clean merge keeps
    trunk's in-place construction (`reserve`/`emplace_back`), and the GATE
    line reads `landed`. Break condition: `applied` — the merge dropped the
    fix; re-apply it in M.
-   **D-UA3-11 — The diagnostics conversion (silent class).** Every fork
    `Note`/`Context` declaration and call becomes `CARBON_DIAGNOSTIC_LABEL(X,
    Info, ...)` + `Attach` or `CARBON_DIAGNOSTIC_CONTEXT` + `Attach` in M (11
    files); kind.def keeps only the fork-ADDED Error/Warning kinds, drops the
    fork's 27 Note/Context kinds, the 17 cut lines riding the fork sides, and
    the 18 kinds no longer declared after the conversion; the coverage test
    and prek's check-toolchain-diagnostics arbitrate (502 kinds on the
    prototype). The fork's four parse diagnostics emitting at
    `*context.position()` stay but `HandleMatchGuard`, which emits at
    upstream's `OpeningBracketInsertionPoint()`. Break condition: a fork
    note lost in the fill (a diagnostic losing its note line) — re-attach.
-   **D-UA3-12 — The class-B re-expressions, each with its probe.** convert.
    cpp: TP-1's cloned storage chain rides in upstream's `storage_access_
    block_id` with the copy rule and D-TP-2's `has_storage` rule inside
    upstream's `PerformAction(InitializeAction)` (W-258; probe: TP-1's
    initialization and return goldens, 230227264's return-storage rule agrees
    on the prototype). check_unit.cpp: OV-2's API-file definition check runs
    once inside upstream's `CheckRequiredDefinitions` under
    `overload_set_definitions_checked_` (probe: OV-2's api/impl goldens).
    generic.cpp: upstream's `DefinitionResolution` with its recursive-
    resolution TODO and VA-2's `TryEvalPackIterationsForSpecific` in the
    `NewlyResolved` path (probe: VA-2's goldens). handle_choice.cpp: upstream's
    `AliasBinding` for a parameterless alternative with the fork's
    `MakeDiscriminantLiteral`; `MakeLetBinding` deleted (probe: the choice and
    match goldens). handle_function.cpp and function.cpp: upstream's deduced-
    return checks and `CheckFunctionParams`, the two overload gates
    re-inserted, `TryMergeOverloadDecl` before `TryMergeRedecl` (probe:
    OV-1's gate goldens). handle_index.cpp: upstream's `TryGetAsArrayType`
    probe inside TP-1's `PerformIndex` (probe: the array and index goldens).
    impl.cpp and impl_lookup.cpp: SC-1's helpers and structural step on
    upstream's `Check::IdentifiedFacetType` and `RequiredImpl` (probe: SC-1's
    goldens and the `.Self` goldens of f0e3d04d0). import_ref.cpp:
    `.is_choice` and `.is_union` in upstream's moved `ImportIncompleteClass`
    (probe: union/import.carbon). return.cpp: EH-A's exported note helpers on
    `LABEL`/`Attach`. lower/handle.cpp: EH-A's D10 epilogue in the
    `EntryPointInt32` arm (probe: main_run/return_result.carbon, the
    entry-point programs). expr_info.cpp: TP-1's non-concrete guard inside
    `...InSpecific`. type_completion.cpp: the structural vector as the seventh
    constructor argument. thunk.cpp: the fence on `CppCalleeFunctionInfo`
    (probe: `EST_BasicNoexcept` 4, awk 1, `__clang_call_terminate` ≥ 35).
    export.cpp: D-ST-12 in the moved `ExportClassToCpp` (probe: ST-1's
    export goldens; H4.4). handle_where.cpp: the throwaway region discarded
    into the enclosing generic (probe: deduce_class_args.carbon). generate_
    ast.cpp: `lookup.specific_id` (probe: overload_set.carbon). handle_name.
    cpp: the pack-name check inside `HandleNameAsExpr` (probe:
    global_runtime.carbon, VA-1's goldens). Break condition for each: its
    probe's fill changing structurally or diagnosing, fixed at the root.
-   **D-UA3-13 — OP-2 item 10 re-opened (W-401; class C for the
    `SubobjectDestroy` half).** D-FO1-1 declined the custom witness for a
    class with a declared destroy impl before completing the class, so
    `Core.Optional(Self)` could be formed inside the class's own definition;
    under 05a7ecbd3 that answers the `DestroyImpl` half only, and the
    `SubobjectDestroy` half is a witness whose synthesized `Op` body needs
    the class's fields — a deferred witness built at the class's end would
    be a new mechanism in the destroy lookup (R17: a design, not a merge
    resolution), and upstream's own prelude TODO ("rename to `Destroy` when
    `require impls` adds a witness table entry") says the shape is still
    moving. Decision: the two splits take the `fail_todo_` prefix by R-5
    (`fail_todo_self_facet_in_signature_required`,
    `fail_todo_incomplete_self_signature`), their comments naming W-401 and
    the measured diagnostic; the out-of-line form (`fn Next(s: S) ->
    Core.Optional(S)` after the class) checks on the prototype and is the
    workaround the comments cite; no conformance program uses the in-class
    form (the prototype's 226 are the base's 226). W-401 is filed, owner the
    next optional or destroy workstream, with the break condition "upstream
    lands `require impls` in the witness table, or a one-clause
    re-expression passes both splits with no new deferral mechanism". Break
    condition of this decision: a reviewer showing that one clause (an
    existing deferral path, not a new one) passes both splits — then class
    B, inside the fix budget.
-   **D-UA3-14 — The two checkers and the X11 sample.** fork/designdocs/
    check_samples.py and fork/evaluator/check_faq.py read a diagnostic's
    first error line; upstream's renderer (2c9739799, d0badecd2) wraps the
    message, so 14 and 2 of their checks fail on text alone. Commit C-2
    teaches both checkers the rendered form (join the wrapped message lines
    of one diagnostic before matching; upstream's direction, R32), with
    their self-checks extended by one rendered case each. The one real
    change, X11 (`X11_template_dependent_bound.carbon` compiles where
    templates.md:590-596 pins `cannot initialize array with dependent bound
    from a list of initializers`): 947c1eb52's `Core.Array` accepts the
    bound, so commit P amends templates.md's bullet with a dated note citing
    947c1eb52 and the checker's expectation for X11 becomes "compiles"
    (DD-1's rule: the page and the checker move together). Both are
    predicted (not prototyped); the falsifier is each checker printing 0
    errors on the merged install. Break condition: a checker error that is
    not the renderer's wrap and not X11 — a toolchain regression, root-caused.
-   **D-UA3-15 — The register after the merge, and W-356** (rewritten
    2026-11-23, review fold: B-B1 / A-m3). W-355's method anchors the
    register to the weekly check's tip, not to the cut. D reads `<anchor>`,
    the tip the latest weekly entry in fork/decision-log.md anchored
    (0072b2812 by the 2026-11-23 entry; the entry's heading and its "W-355
    re-anchored" paragraph name it), and: changes check_greps.sh's default
    `cut=${4:-c1e83b0b7}` and its comment to 7a3608bab; writes each of the
    seven L rows (H4.5, H8.5, H8.7, H10.4, H10.8, H11.4, H11.10) with the
    expected count MEASURED as `git -C <repository> log --oneline
    7a3608bab..<anchor> -- <paths> | wc -l` at D time (measured 2026-11-23 at
    0072b2812: 1, 0, 0, 0, 1, 0, 1, every 1 being 0072b2812 itself, the
    diagnostics-model commit) under a "#" line naming UA-3, the cut 7a3608bab
    and `<anchor>` (A.9) — never 0 by assertion; leaves rg1-quotes.tsv as the
    weekly check left it (its lines are anchored at `<anchor>`); runs both
    scripts at `<anchor>` (`check_quotes.sh <wt> <anchor> rg1-quotes.tsv` and
    `check_greps.sh <wt> <anchor> rg1-checks.tsv`), expecting "checked 294
    quotes, 0 failed" and "checked 96 silence checks, 0 failed"; H10.1's row
    reads ALIGNED (W-394 discharged; its expected count stays 5, upstream's
    `AddrOfAction` now the fork's; the fork's two stringify cases are a T13.9
    watch, D-UA3-7); DR-0's entry (vi) reads ALIGNED for the lane and the
    match-lane `_`, with the non-match `_` named as W-079's residue (W-372;
    A.12); D-RG-16's block gains the W-354 discharge note; D-RG-18 (W-356) is
    discharged with the probe's output ("value expression passed to reference
    parameter", exit 1, no CHECK failure on the prototype's install;
    tp2-base's install exits 1 too, so the crash RG-1 found on 0bdce60a5 and
    PR 57's install was already gone on trunk before the advance — recorded
    as such, not as UA-3's fix); the lambda split's pass (R-4) is recorded as
    a convergence candidate (A-m1). Rev 1 wrote the seven counts as 0 and
    "the next weekly check re-anchors after the landing": both false once the
    2026-11-23 check landed (it anchored 0072b2812 before D; measured on
    trunk's tables, "7 failed" with cut 7a3608bab at 0072b2812 and "9 failed"
    for check_quotes at 0072b2812 on the pre-weekly table). Break condition:
    either script printing a failure at `<anchor>` after D — re-measure, never
    re-anchor to a wanted number; a weekly records commit landing between M
    and D — T re-made, the step re-measured (D-UA3-1).
-   **D-UA3-16 — .github.** check_dependent_pr.yaml takes upstream's whole
    file (the fork does not maintain .github; the file is `X`); the fork's
    six-line `if: github.repository == 'carbon-language/carbon-lang'` guard
    in it is lost, so UA-1's §8.4 guard grep expects five hits
    (auto_label_prs 1, gh_pages_ci 1, gh_pages_deploy 2, nightly_release 1;
    measured 5 on the prototype) and the dependency scan would run unguarded
    on the fork when Actions returns — the owner's call, filed as W-402. The
    eight fork_*.yaml workflows and the other five guards merge clean
    untouched. Break condition: a guard count other than five.
-   **D-UA3-17 — Reviews, the fix budget, the landing, the shrink line.**
    Two implementation reviews (fork-mechanism fidelity; mechanics and
    verification) of the branch after F and R-1 to R-5, then up to three fix
    rounds, each with its fill (R26 to the fixpoint) and gate; the PR with
    base trunk in Appendix A.10's form; the landing by LAND-1's D-LAND-6 (the
    merge of the PR into trunk is a second merge commit; the land tree's
    gate and conformance by the arbiter; the records commit with Appendix
    A.11's texts). Landing preconditions (added 2026-11-23, review fold:
    B-M2): the arbiter of record carries ARB-5 (`grep -c libCIR
    /home/user/arb/carbonbuild/gen_ninja.py` non-zero, as it does since
    2026-11-23) and `diff -r` against fork/tools/carbonbuild at trunk is
    clean or its differences are named in the landing's record; the
    reviews' final §8.1 re-run and the land tree's build, gate and
    conformance come from /home/user/arb/carbonbuild only; A.2 and A.10 say
    which script measured each line. Shrink line (rewritten 2026-11-23,
    review fold: B-M3; rev 1 said R-1 to R-5 could follow as their own PRs,
    which §3 contradicted): R-1 to R-5 are NOT deferrable — after F the
    manual-fix list names eight `fail_` splits that pass and two that fail,
    the arbiter's gate counts every one as FAILED, and a PR with a red gate
    is not merged (R33 (c)); R-5's two `fail_todo_` renames require W-401
    filed in the same PR (D files it; an un-filed `fail_todo_` is a hidden
    failure). What CAN shrink is C-2 and P: if they do not fit the review and
    fix budget, the PR carries T + M + F + R-1 to R-5 (+ fix commits) + D,
    with D-UA3-14 re-filed as an open item carrying the two checkers'
    measured error counts, and C-2/P follow as their own PR. Break
    condition: a fourth fix round needed — the orchestrator rules.
-   **D-UA3-18 — What UA-3 does NOT take: nothing.** Every upstream change in
    the window is taken; the fork keeps only what upstream has not designed
    (its own mechanisms: `union`, `overload`, `match`, `Core.Result`, packs,
    structural conformance, the fence, the templates' deferral actions
    besides `&`) and the fork-local clauses already on the V-3a watch list
    (UA-1's: T12.1 `is_union` in merge.cpp, T12.2 `TryMergeOverloadDecl`,
    T12.3 `is_choice` in custom_witness.cpp, T12.4 `return_type_id`, T12.5
    `BeginConditionalExprOperand`, T12.6 the type_mapping guard, T12.7 the
    export null guard — each still 0 at the tip), plus the new fork-inside-
    upstream clauses this merge adds, which the records commit appends to
    that watch list as rows (D-UA3-15): `has_trailing_discard` on
    `SemIR::StructPattern`, the `PatternListUnderscoreField` discard, the
    `overload_set_definitions_checked_` flag, `IsCoreDestroyImplInFile`,
    the EH-A arm in lower/handle.cpp's `ReturnKind` switch, the
    `DiscardGenericDeclIntoEnclosingGeneric` call in handle_where.cpp,
    `insts()` on `PendingBlock` (T13.7 watches the fork accessor's
    distinctive text `auto insts() const`, not the literal `insts()`, which
    upstream's pending_block.h itself contains twice at the tip — corrected
    2026-11-23, review fold: B-m3), plus the rows rev 2 adds (review fold:
    A-M1 / A-M2 / A-M3 / A-m1): T13.8 upstream's TODO "Struct pattern
    underscore field" (expected 1 at the tip; its disappearance means
    upstream implemented the discard — take it, retire the fork's clause),
    T13.9 `AddrOfAction` in upstream's stringify.cpp (expected 0; non-zero
    means upstream stringifies actions — take it, retire D-TP-23's cases),
    T13.10 `friend_scopes_stack` in upstream's handle_class.cpp (expected 3:
    the push, the append, the pop; a change is re-mirrored in
    handle_union.cpp), and the convergence candidate lambda.carbon's
    `fail_todo_as_non_constant_template_argument` (expected 1 split header
    at the tip; 0 means upstream made it pass and the fork's R-4 rename is
    upstream's). Break condition: none (the list is the register's; a
    reviewer naming an upstream change the merge left untaken is a finding
    against M).

### §1.1 Resolution order (sources first), as the prototype did it

core_identifier.def and core_interface_kind.def; then the x-macro files
(inst_kind.def, node_kind.def, state.def, kind.def); then typed_insts.h,
node_ids.h, typed_nodes.h; then sem_ir (expr_info, file, function.h,
inst_namer, mangler, stringify, type_info, type_iterator; `git rm` the
identified_facet_type pair and port SC-1's struct into check/'s); then the
check class-A files (BUILD, class.h, context.{h,cpp}, deduce.cpp,
full_pattern_stack.h, handle_binding_pattern.cpp, member_access.cpp,
name_lookup.h, node_stack.h, pending_block.h, cpp/import.cpp); then the check
class-B and class-C files in this order: custom_witness.cpp (D-UA3-5);
handle_pattern_list.cpp with pattern_match.cpp (D-UA3-6); handle_operator.cpp
with pointer_dereference.{cpp,h} (D-UA3-7); handle_choice.cpp;
handle_function.cpp with function.cpp; generic.cpp with check_unit.cpp;
impl.cpp, impl_lookup.cpp, type_completion.cpp and
structural_conformance.{cpp,h} together; convert.cpp; handle_index.cpp;
import_ref.cpp; inst.cpp; merge.cpp; return.cpp; action.cpp; call.cpp;
eval_inst.cpp; handle_pack_expansion.cpp; handle_class.cpp with class.cpp;
cpp/export.cpp, cpp/thunk.cpp and cpp/generate_ast.cpp; handle_where.cpp;
handle_name.cpp. Then lower (file_context.{h,cpp} and mangler.h (D-UA3-8),
function_context.{h,cpp}, handle.cpp, aggregate.cpp, type.cpp); then parse
and driver; then the silent-fix sweep (§0.4 items 1-9, 14, 16, 20 (e)); then
the prelude and the 21 re-spellings; then .github, loops.md and the two
grammars; then the goldens (D-UA3-3). Then prek on every touched
non-testdata file to a fixpoint (its clang-format changes are part of M: the
prototype's fix 5 reformatted 19 files), the §8.2 greps, and the build.

### §1.2 Re-expression and deletion discipline

Each fork mechanism is located by its decision name (D-OV-n, D-EH-n, D-UN-n,
D-SL-n, D-TP-n, D-SC-n, D-VA-n, D-OP2-n, W-069, W-077) and re-implemented
against upstream's new types with the SAME observable behavior, which the
fork's goldens and programs pin; no fork test is edited to make a
re-expression pass (R16 (b)); where behavior must change the change is
upstream-intended and the fill is its evidence (D-UA3-5's `SelfDestruct`
calls, D-UA3-9's selections, D-UA3-13's two splits; rev 1 also listed
"D-UA3-6's `_` field", which the fold showed was no upstream-intended change
but a dead discard — the `_` keeps its behavior in the match lane and
upstream's TODO elsewhere, review fold A-M2).
Deleted fork code is named in M's message with the upstream commit that
supersedes it, and each item's ledger note gains the dated "superseded by
upstream PR n" line at the records commit.

## §2 Implementation spec (file by file)

The §0.3 table is the per-file instruction for every conflicting source; this
section gives the exact form where the resolution is more than "keep both",
quotes the prototype's code where the text is load-bearing (the prototype's
resolution-vs-upstream.patch is the diff of record for each), and lists the
silent fixes by file. Nothing below writes a CHECK line.

### §2.1 Class A files (keep both; verify)

BUILD, class.h, context.{h,cpp}, core_identifier.def, cpp/import.cpp,
deduce.cpp, full_pattern_stack.h, handle_binding_pattern.cpp,
member_access.cpp, name_lookup.h, node_stack.h, pending_block.h, driver/
compile_options.cpp, lower/function_context.{h,cpp}, lower/type.cpp,
parse/context.cpp, handle_decl_scope_loop.cpp, handle_statement.cpp,
node_ids.h, node_kind.def, state.def, typed_nodes.h, sem_ir/core_interface_
kind.def, file.cpp, function.h, inst_kind.def, inst_namer.cpp, mangler.cpp,
stringify.cpp, type_info.cpp, type_iterator.cpp, docs/design/control_flow/
loops.md: each as its §0.3 row says. The verifications that go with them:
context.{h,cpp} lose `struct_pattern_names_stack` and its CHECK (D-UA3-6);
lower/function_context.{h,cpp} lose `TryEmitGlobalLetValue`, its `GetValue`
hook and the `is_global_ctor_` hook outside the hunks (D-UA3-8) and end with
exactly one declaration each of `CopyObject(Value*, Value*)`,
`CopyObject(InstId, InstId)`, `CopyValue`, `CopyValueReprToObject` and
`AddGlobalToCurrentFingerprint`; mangler.cpp loses `MangleGlobalLetBinding`
outside the hunk; stringify.cpp KEEPS TP-1's two `AddrOfAction` cases, each
marked `// Fork (TP-1, D-TP-23; W-394: upstream's inst, the fork's
rendering)` (D-UA3-7, amended 2026-11-23, review fold: A-M3); lower/type.cpp
and type_iterator.cpp drop
`RequireSpecificDefinitionType`; cpp/import.cpp's `NoteInCppThunk` body
becomes `CARBON_DIAGNOSTIC_LABEL(InCppThunk, Info, ...)` + `Attach`, and its
`CalleeFunctionInfo` and `GenericClassType` uses are renamed; loops.md's
resolved text equals trunk's byte for byte.

### §2.2 custom_witness.cpp and the prelude (D-UA3-5, W-354)

1.  Take upstream's file for every hunk, then re-insert the fork's
    surviving functions where the prototype has them: `HasUserDestroyImpl`,
    `HasClassKeyedImpl`, `IsTriviallyDestructible`, `HasNonTrivialUserCopyImpl`,
    `HasTrivialClassShapeForExport`, `AdapterHasDestroyWork` (OP-2),
    `LookupChoiceCopyWitness`, `LookupUnionUnformedInitWitness`, the
    `CanDestroyClass(..., is_partial, query_is_symbolic)` threading with the
    W-071 symbolic-choice clause, the `CanDestroyType` `CustomLayoutType` arm,
    and in `LookupCustomWitness` the `Copy` and `UnformedInit` cases. Delete
    `BuildDestroyWitness`, `BuildCarbonDestroyWitness`, `LookupDestroyWitness`,
    `BuildTrivialDestroyWitness`, `MakeDestroyOpFunction`,
    `MakeDestroySelfDestructFunction`, the `case CoreInterface::Destroy`, and
    D-SL-16's yield (the `HasClassKeyedImpl(..., Destroy, ...) → NoDestroy`
    clause in `CanDestroyClass` and its twin in `CanDestroyType`).
2.  `MakeSubobjectDestroyOpBody`: upstream's array-adapter arm first
    (947c1eb52),
    then D-UA-9's `if (class_info.is_choice) { return; }` and OP-2's adapter
    arm; the `CustomLayoutType` arm stays beside the `default`.
3.  The predicate keying. Replace every `CoreInterface::Destroy` key with the
    identifier comparison (the prototype's text):

<!-- google-doc-style-ignore -->

```cpp
static auto IsCoreDestroyImplInFile(const SemIR::File& sem_ir,
                                    SemIR::InterfaceId interface_id) -> bool {
  if (!interface_id.has_value()) {
    return false;
  }
  const auto& interface = sem_ir.interfaces().Get(interface_id);
  if (!sem_ir.name_scopes().IsCorePackage(interface.parent_scope_id)) {
    return false;
  }
  auto identifier_id = interface.name_id.AsIdentifierId();
  return identifier_id.has_value() && sem_ir.identifiers().Get(identifier_id) ==
                                          CoreIdentifier::DestroyImpl.name();
}
```

<!-- google-doc-style-resume -->

The function is called with the check unit's IR for the local impl store
(where the loop skips an impl whose `GetImportSource` has a value: an
import-materialized impl is classified by its defining file, as
`HasClassKeyedImpl` does) and with each import IR (`import_sem_ir`) for the
imported stores. A user `impl as DestroyImpl` counts only when its `Op` is
not the blanket `no_op` builtin (the fork's existing `IsNoOp` test on the
witness's `Op`).

4.  core/prelude: destroy.carbon, array.carbon, prelude.carbon merge clean as
    upstream's; buf.carbon:58 and string.carbon:154 `impl as Destroy {` →
    `impl as DestroyImpl {`; optional.carbon:354 `impl forall [T: Copy &
    Destroy] DefaultOptionalStorage(T) as Destroy {` → `as DestroyImpl {`;
    optional.carbon:357 `(self.value unsafe as T).(Destroy.SelfDestruct)();`
    → `SelfDestruct(ref (self.value unsafe as T));`; slice.carbon gains
    `import library "prelude/types/array";` beside its other imports (as
    upstream's iterate.carbon has it). `[T: Core.Destroy]` bounds stay (a
    constraint is a facet type).
5.  custom_witness.h: the fork's three declarations stay; the shared ones
    take upstream's signatures; the `Destroy` builders' declarations go.
6.  Comments (added 2026-11-23, review fold: A-m2): the fork comments that
    name the deleted functions are re-worded in M — custom_witness.cpp:259
    and :292 (`LookupDestroyWitness` → `LookupSubobjectDestroyWitness`), :927
    (`BuildDestroyWitness` in cpp/impl_lookup.cpp →
    `BuildCppSubobjectDestroyWitness`), :1026 and :1060
    (`self.<field>.(Destroy.SelfDestruct)` → `SelfDestruct(ref self.<field>)`,
    `Destroy.SelfDestruct` → `SelfDestruct`), :1476 and :1533
    (`LookupDestroyWitness` → `LookupSubobjectDestroyWitness`);
    custom_witness.h:61 (the same, and `Destroy.Op` → `SubobjectDestroy.Op`);
    member_access.cpp:427 (a choice's payload-free alternative is an
    `AliasBinding` since d50576ca1; the `WrapperBinding` arm is the match
    lane's). §8.2 greps the retired names over comments too (expected 0; the
    rev 2 re-measurement reads 1, a `BuildDestroyWitness`-free line that
    matches the pattern's `Destroy\.SelfDestruct` nowhere — re-check at M).

### §2.3 Struct patterns (D-UA3-6, W-372)

handle_pattern_list.cpp: upstream's four hunks whole (the `struct_type_
fields_stack` push/pop, `PopStructFieldNameNodes`, `DiagnoseDuplicateNames(
StructKind::StructPattern)`, `InNonStaticFieldDecl` and its
`FieldWithStructPattern`); replace upstream's `PatternListUnderscoreField`
TODO handler by the fork's recorder and read it in the `StructPattern` end
handler (the prototype's text):

<!-- google-doc-style-ignore -->

```cpp
auto HandleParseNode(Context& context,
                     Parse::PatternListUnderscoreFieldId node_id) -> bool {
  // Fork (W-077, W-372): the `_` field discard is not an element. It is left
  // on the node stack for the enclosing struct pattern's end handler, which
  // records it on the `StructPattern` (`has_trailing_discard`); the element
  // region the preceding comma (or the start) opened stays pending and empty.
  context.node_stack().Push(node_id);
  return true;
}
```

```cpp
  bool has_trailing_discard = false;
  if (context.node_stack().PeekIs(
          Parse::NodeKind::PatternListUnderscoreField)) {
    has_trailing_discard = true;
    context.node_stack()
        .PopAndDiscardSoloNodeId<Parse::NodeKind::PatternListUnderscoreField>();
    EndEmptyExprRegionForPattern(context);
  } else if (context.node_stack().PeekIs(Parse::NodeKind::StructPatternStart)) {
```

<!-- google-doc-style-resume -->

then, after upstream's `FieldWithStructPattern` branch, `else if
(has_trailing_discard && fields.empty())` emits the fork's
`StructPatternDiscardWithoutFields`, and the `AddInst<SemIR::StructPattern>`
carries `.has_trailing_discard = SemIR::BoolValue::From(has_trailing_discard)`.
The fork's `MatchCaseArm` gate TODO, `struct_pattern_names_stack` and the
`StructPatternNameDuplicate`/`StructPatternNamePrevious` pair are deleted
(upstream's `DiagnoseDuplicateNames` diagnoses the duplicate). The
`PatternListUnderscoreField` handler above gains, before the push, the lane
gate (the rev 2 re-measurement's text; added 2026-11-23, review fold: A-M2):

<!-- google-doc-style-ignore -->

```cpp
  // ... Every other lane (`let`, `var`, parameters, class-scope `let`) is
  // upstream's conversion-first lane, which converts the initializer to the
  // pattern's own struct type and would read no discard, so it keeps
  // upstream's TODO (W-079; UA-3 review fold A-M2).
  if (!context.full_pattern_stack().CurrentKindIs(
          FullPatternStack::Kind::MatchCaseArm)) {
    return context.TODO(node_id, "Struct pattern underscore field");
  }
  context.node_stack().Push(node_id);
  return true;
```

<!-- google-doc-style-resume -->

typed_insts.h: upstream's `StructPattern` struct plus the field:

<!-- google-doc-style-ignore -->

```cpp
  // Fork (W-077, W-372): `_` as the last field licenses unmentioned scrutinee
  // fields (docs/design/pattern_matching.md, "Struct patterns").
  BoolValue has_trailing_discard;
```

<!-- google-doc-style-resume -->

pattern_match.cpp: one `DoPreWork(StructPattern)` body (upstream's, with the
fork's match pre-work reading `has_trailing_discard` under
`in_match_case_bind`), the `MatchContext` carrying `loc_id`; `LocalState`
keeps upstream's `in_global_init` and the fork's `in_match_case_bind`; the
`UseGlobalInit(context_)` resume goes. kind.def: `StructPatternDiscardWithout
Fields` and `StructPatternNameDuplicate` stay (Errors), `StructPatternName
Previous` goes (a label now). R-3 RENAMES check/testdata/let/fail_todo_
struct_pattern.carbon to let/struct_pattern.carbon (`git mv`), drops the
`fail_todo_` prefix of its four splits (`let`, `var`, `param`,
`let_in_match_arm_body`), rewrites its header ("the `let`/`var`/parameter lane
is upstream's, c6b54b57e; the two fork-only shapes pinned nowhere upstream; the
`_` field outside the match lane is W-079's residue") and adds the split
`fail_todo_underscore_param` (`fn F({x: i32, _});`); autoupdate refills the
file in the same commit (its CHECK lines, the TIP lines' path) — the rev 2
re-measurement's text is the reference (Appendix C) (amended 2026-11-23,
review fold: A-M4 / B-M1 / A-M2).

### §2.4 `AddrOfAction` (D-UA3-7, W-394)

handle_operator.cpp: upstream's `PerformAction(Context&, SemIR::LocId,
SemIR::AddrOfAction)` and `HandleParseNode(PrefixOperatorAmpId)` through
`HandleAction<SemIR::AddrOfAction>` whole; hunk 2 keeps the fork's
`PerformPointerDereference(context, loc_id, PointerDereferenceKind::Star, ...)`
call. pointer_dereference.cpp: delete `PerformAddrOf` (:108-146) and the
fork's `PerformAction(AddrOfAction)`; convert the moved `DerefOfType` note to
`CARBON_DIAGNOSTIC_LABEL(DerefOfType, Info, ...)` + `Attach`; the
`OperandDependence(context, ...)` line at :24 takes `context.sem_ir()`.
pointer_dereference.h: drop the two declarations. typed_insts.h hunk 1:
upstream's struct (`ActionExprCategory(ExprCategory::Dependent)`).
stringify.cpp: KEEP the fork's two `AddrOfAction` cases as the prototype has
them (`IsPrefixAction`/`PushPostfix` at :766 and the `case` at :914), each
marked Fork with D-TP-23 and W-394 (D-UA3-7; rev 1's deletion reversed
2026-11-23, review fold: A-M3); the fill re-measures generic/template/
pointer.carbon (one `addr_of_action`) and index.carbon:332/:337 (`D(&p.n)`,
`D(&p.m)`), both unchanged on the prototype and the rev 2 re-measurement.

### §2.5 W-069 lane a1 (D-UA3-8)

lower/file_context.cpp: hunk 1 keeps `.return_kind` and
`.entry_point_result_type_id`; hunk 2 takes upstream's
`GetOrCreateGlobalBinding` region whole; delete the clean-merging lines
`RegisterGlobalLetBindings();` (:115), `PrepareGlobalLetDefinitions();`
(:127) and the `global_let_stores_emitted_` CHECK (:196-205) by the
prototype's numbering. lower/file_context.h: upstream's hunks; delete
`struct GlobalLetBinding` (:60-100) and the private declarations
`RegisterGlobalLetBindings` (:305) and `PrepareGlobalLetDefinitions` (:310).
lower/function_context.cpp: delete `TryEmitGlobalLetValue` (:344-409), its
call in `GetValue` (:316-323) and the `is_global_ctor_` hook
`file_context_->EmitGlobalLetStores(*this, inst_id)` (:260-267); keep
`GetValueServesConstantValueRep`. lower/handle.cpp hunk 1: upstream's
`NameRef` handler (`SetLocal(inst_id, GetValue(inst.value_id))`).
sem_ir/mangler.{h,cpp}: upstream's `MangleGlobalBinding`; delete
`MangleGlobalLetBinding`. check/handle_name.cpp (silent, §0.4 item 20 (c)):
VA-1's pack-name check (`context.TODO(node_id, "use of a pack's name without
`each`")`) moves inside `HandleNameAsExpr` so the `IdentifierNameExpr`
handler takes upstream's path to `TryGetLookupResultInCurrentScope` and the
`GlobalRef` it builds.

### §2.6 Thunks, import, export (D-UA-7 on the renamed struct; §0.4 items 3 and 20 (b))

cpp/thunk.cpp: `CppCalleeFunctionInfo` in `IsCppThunkRequired`,
`BuildThunkBody`, `BuildCppThunk`, `WrapInBoundaryDiagnostic`,
`BuildCppCatchingThunk`; the three fence components unchanged in substance
(`EST_BasicNoexcept` in `CreateThunkFunctionDecl`, `WrapInBoundaryDiagnostic`
under `IsCppThunkFenceRequired`, the `IsCppThunkRequired` clause); the
catching builders on the renamed struct. cpp/import.cpp: as §2.1; the
fence-unbuildable TODO after `DefineAsThunkCall` stays. cpp/export.cpp: take
upstream's moved `ExportClassSpecificToCpp`/`ExportClassToCpp`/
`ExportAndCompleteClassToCpp` (the fork-side block at :232-346 deleted), and
in the moved `ExportClassToCpp`, after `ExportNameScopeToCpp(context, loc_id,
class_info.parent_scope_id)`:

<!-- google-doc-style-ignore -->

```cpp
  // Fork (ST-1, fork/string/plan.md D-ST-12): the parent scope could not be
  // exported and that has been diagnosed, as the other callers check.
  if (!decl_context) {
    return nullptr;
  }
```

<!-- google-doc-style-resume -->

OV-3's `overload_index` assignment in `BuildCarbonToCarbonThunk` and the
union, `IsTriviallyCopyableForExport`, `Carbon::expected` and UN-2 hunks
merge clean. cpp/generate_ast.cpp (clean merge, silent): the three
`ExportNameScopeToCpp` calls of OV-3's per-member export pass
`lookup.specific_id` (:244, :255, :289 on the prototype). cpp/sum_type.cpp:
`PerformCppOverloadResolution` takes `callee_expr_id`; its notes converted.

### §2.7 Generics, impls, facets, defaults (§0.3's B rows; §0.4 items 6, 7, 9, 12, 20 (a))

-   generic.cpp: upstream's `ResolveSpecificDefinition -> DefinitionResolution`
    with its TODO ("recursive resolution ...") and `PreviouslyResolved`/
    `NotDefinedYet`; in the `NewlyResolved` path, after
    `TryEvalBlockForSpecific(...)`: `TryEvalPackIterationsForSpecific(context,
    loc_id, specific_id);` with VA-2's comment, then `return
    DefinitionResolution::NewlyResolved;`.
-   check_unit.cpp and .h: OV-2's API-file definition check stays inside
    `CheckRequiredDefinitions` with its `CARBON_DIAGNOSTIC(MissingDefinition
    InImpl, ...)` declaration, wrapped in `if (!overload_set_definitions_
    checked_) { overload_set_definitions_checked_ = true; ... }`; the member
    `bool overload_set_definitions_checked_ = false;` in `CheckUnit`.
-   function.cpp (`CheckDefaults`, moved by 1b0a5709e): `PatternLevelState`
    gains `int32_t trailing_default_count = 0;` with W-362's comment, the
    level's walk counts it after its last pattern without a default, and the
    extraction reads `default_count = state->patterns_missing_defaults.empty()
    ? state->default_count : state->trailing_default_count;` (the prototype's
    :791-793, :893-899). handle_function.cpp: upstream's deduced-return checks
    and `CheckFunctionParams` call; the fork's `CheckDefaults` copy and
    positional-param tail deleted; `DiagnoseOverloadInInterfaceOrImpl` and
    `DiagnoseOverloadGates` re-inserted at their call sites; `TryMergeOverload
    Decl` before `TryMergeRedecl`.
-   impl.cpp: upstream's `CheckRequireDeclsSatisfied(context, identified_id,
    ...)` with `RequiredImpl{self_facet, interface}`, `SubstIdentifiedWitnesses`
    and the equivalents loop; `SubstImplSelfWitnesses` deleted; SC-1's
    `GetRequireSelfClassBeingDefined`, `LookupRequireInterfaces` (on `TypeId`),
    `CheckInterfaceRequire` and `GetInterfaceWithSelfSpecific` rewritten to
    read the evaluated `RequiredImpl` fields; upstream's inline require loop
    replaced by `CheckInterfaceRequire(..., InterfaceRequirePhase::
    ImplDefinition)` over the same list.
-   impl_lookup.cpp: includes sem_ir/function.h and check/identified_facet_
    type.h; the fork's `GetIdentifiedFacetTypeForQuery` folded into upstream's
    inline `RequireIdentifiedFacetType(..., TypeId, CARBON_DIAGNOSTIC_CONTEXT
    /Attach)`; SC-1's `CheckStructuralRequirements` step between
    identification and `req_impls`, upstream's empty-requirements CHECKs kept.
-   check/identified_facet_type.{h,cpp}: SC-1's `struct StructuralRequirement`,
    `structural_requirements()`, `structural_requirements_` and the
    `specific_named_constraint.h` include ported from the deleted sem_ir pair;
    the constructor gains a seventh parameter `llvm::ArrayRef<Structural
    Requirement> structural = {}` after upstream's `llvm::ArrayRef<Equivalent>
    equivalents`, with the fork's dedup loop. type_completion.cpp passes the
    fork's `structural` vector as that argument; structural_conformance.{cpp,h}
    spell `Check::IdentifiedFacetType` and pass `TypeId` to
    `TryToIdentifyFacetType` (:674, :715).
-   inst.cpp: upstream's `SpecificConstant`/`SpecificInst` split; CT-1's
    `AddAliasUseCheckToCurrentGeneric` in the `SpecificConstant` branch.
-   import_ref.cpp: hunk 1 upstream's `GetLocalIncompleteSpecificData` with the
    fork's `resolved_per_instantiation` rule kept; hunk 2 upstream's moved
    `ImportIncompleteClass` with `.is_choice = import_class.is_choice,` and
    `.is_union = import_class.is_union,` beside `.is_dynamic`; the fork's
    duplicate `TryResolveTypedInst(CustomLayoutType)` deleted.
-   merge.cpp: upstream's `CARBON_DIAGNOSTIC_LABEL(RedeclParamPrevious, Info)`
    form in `CheckRedeclParam` with the fork's `new_specific_id, bool*
    found_error` parameters and `new_param_type_id` argument; its other note
    converted; the D-UN-6 clauses stay.
-   eval.cpp (clean merge, silent): `SaveAndRestore` →
    `CheckedSaveAndRestore`,
    `SetAccessContext` → `FindAccessContext` at :3847-3848; scope_stack.cpp
    passes `NonConstantAccess::Disallowed`.
-   handle_where.cpp (clean merge, §0.4 item 20 (a)): replace upstream's
    `DiscardGenericDecl(context)` at the end of the `where` region by:

<!-- google-doc-style-ignore -->

```cpp
  // Fork (TP-1, UA-3): a template action created inside the `where`, such as
  // the `T.Item` of `HasItem where .Item = T.Item` in a template class, must
  // be performed in each specific of the enclosing generic, so the region's
  // generic-dependent instructions are re-attached there instead of being
  // discarded (`DiscardGenericDeclIntoEnclosingGeneric` keeps the
  // period-self-only ones out, as this discard does).
  DiscardGenericDeclIntoEnclosingGeneric(context);
```

<!-- google-doc-style-resume -->

-   action.cpp and call.cpp: the §0.3 rows; every `OperandDependence` and
    `OperandDependenceInSpecific` call on `context.sem_ir()`.
-   eval_inst.cpp: upstream's `CARBON_DIAGNOSTIC_CONTEXT`/`Attach` in hunk 1;
    VA-2's five evaluators kept, the `RequireSpecificDefinition` evaluator
    dropped.
-   handle_pack_expansion.cpp: the fork's file whole; its three
    `EnclosingPackExpansion`/`PreviousPackExpansionPattern` notes and the
    `IncompleteTypeInPackExpansion` context converted.
-   full_pattern_stack.cpp: `CARBON_CHECK(IsAnyNameBindingDeclKind(k) || k ==
    Kind::MatchCaseArm)` with the fork's comment.
-   handle_class.cpp: the fork's delegation; class.cpp:120
    `GetParameterizedClassType`; decl_name_stack.cpp:492 and
    cpp/import.cpp:1331 `TryGetAs<SemIR::ParameterizedClassType>`.
-   handle_union.cpp (clean merge; §0.4 item 23; added 2026-11-23, review
    fold: A-M1): in `HandleParseNode(UnionDefinitionStartId)`, after
    `context.vtable_stack().Push();`, the rev 2 re-measurement's text:

<!-- google-doc-style-ignore -->

```cpp
  // Fork (UN-1; UA-3, review fold A-M1): `friend` declarations in a union
  // body (upstream 5fed32a9a) follow the class rules; `HandleParseNode(
  // FriendDecl)` appends to this array and the end handler moves it into the
  // class, as handle_class.cpp does.
  context.friend_scopes_stack().PushArray();
```

```cpp
  auto& class_info = context.classes().Get(class_id);
  class_info.friend_scopes.GrowForInsertCount(
      context.friend_scopes_stack().PeekArray().size());
  for (auto friend_scope_id : context.friend_scopes_stack().PeekArray()) {
    class_info.friend_scopes.Insert(friend_scope_id);
  }
  context.friend_scopes_stack().PopArray();

  FinishGenericDefinition(context, class_info.generic_id);
```

<!-- google-doc-style-resume -->

The second block replaces `UnionDefinition`'s
`FinishGenericDefinition(context, context.classes().Get(class_id)
.generic_id);` after the three pops. The new fork golden
check/testdata/union/friend.carbon (three splits: `friend_class`, a
friend class reading a `private` union field; `fail_non_friend`, "cannot
access private member `word` of type `U`"; `fail_friend_var`, "friend
declaration names entity that is not a name scope"; INCLUDE-FILE
min_prelude/int.carbon, so no `u8`) is added in M with no CHECK lines and
filled by F; the probe `class C {} union U { friend C; var a: i32; var b:
f64; }` exits 0 on the re-measurement's install.

### §2.8 Storage and lowering (W-258, §0.4 items 14, 15; §0.3's lower rows)

-   convert.cpp hunks 1-3: in the fork's `InitializeAction` creation,
    `auto action_storage_id = CloneStorageAccessChain(context, loc_id,
    target);` and `storage_access_block_id` = the cloned chain's block when
    `action_storage_id` differs from `target.storage_id`, else upstream's
    `PendingBlock::TakeAsInstBlock` result; the action's `storage_id` stays
    `target.storage_id`; `PerformAction(InitializeAction)` reads the chain
    from `storage_access_block_id` (the prototype's :3222-3237, :3444-3449)
    and keeps the copy rule and D-TP-2's `has_storage`/`OutParam` rule; hunk
    4 upstream's `GetInstLocationOrFallback` loc with the fork's
    `GetTypeOfInstInSpecific` type; `MaterializeIfInitializer(..., loc_id,
    ...)`; the `FindStorageArgForInitializer` caller at :3751 takes the
    2-argument form; the four `OperandDependence` lines on `context.sem_ir()`.
-   sem_ir/expr_info.cpp: upstream's two functions and expr_info.h
    declarations; in `...InSpecific`'s `SpliceInst` arm, after
    `GetConstantValueInSpecific`:

<!-- google-doc-style-ignore -->

```cpp
        if (!const_id.is_concrete() || const_id == ErrorInst::ConstantId) {
          // Fork (TP-1): the action that produces the spliced instruction has
          // not been performed: in a template's definition, the initializer
          // and its storage argument are known only on instantiation.
          return {ir, InstId::None};
        }
```

<!-- google-doc-style-resume -->

The `Call` arm's fork return is `{ir, init.dest_id}`.

-   lower/aggregate.cpp: upstream's `FindStorageArgForInitializerInSpecific`
    call and `CARBON_CHECK(&sem_ir == dest_sem_ir)` under `if
    (context.IsConstant(ref_id))`; lower/function_context.cpp:547 and
    lower/handle.cpp:88 call `...InSpecific(sem_ir, id, specific_sem_ir,
    specific_id)`.
-   lower/handle.cpp hunk 2: upstream's `ReturnKind` switch; its
    `EntryPointInt32` arm begins with EH-A's D10 epilogue:

<!-- google-doc-style-ignore -->

```cpp
    case ReturnKind::EntryPointInt32: {
      // Fork (EH-A, D10): a `Result`-returning `Main.Run` initializes its
      // result in place and returns the exit code it encodes.
      if (GetEntryPointResultTypeId(context.specific_sem_ir(),
                                    context.specific_sem_ir_function_id())
              .has_value()) {
        auto result_type = context.GetTypeIdOfInst(inst.expr_id);
        context.InitializeStorage(result_type, inst.dest_id, inst.expr_id);
        EmitEntryPointResultEpilogue(context, result_type,
                                     context.GetValue(inst.dest_id));
        return;
      }
      CARBON_FATAL(
          "`return` with expression in entry point without a return "
          "type");
```

<!-- google-doc-style-resume -->

`EmitEntryPointResultEpilogue` and lower/type.cpp's
`entry_point_result_type_id` stay beside `return_kind`.

-   lower/function_context.cpp's `builder_(file_context.llvm_module(), ...)`,
    lower/constant.cpp's `IRBuilder<>(context.llvm_module())` and
    driver/compile_driver.cpp's `PassBuilder(module_->getContext(), ...)` are
    upstream's lines and compile only at the tip pin (D-UA3-4).

### §2.9 Choices and the match lane (§0.3's handle_choice.cpp row; §0.4 item 11)

handle_choice.cpp: upstream's `MakeBinding` (an `AliasBinding` for a
parameterless alternative; its body merged clean) with the fork's
`MakeDiscriminantLiteral` and the payload comment; `MakeLetBinding` deleted;
`TypeContainsChoice`, `ChoiceAlternativeFunctionInfo`,
`BuildAlternativeConstructor` and the per-alternative loop (with
`is_duplicate_alternative` and `choice_alternatives`) kept; its notes
converted. handle_match.cpp, member_access.cpp:440's `TryGetAs<Wrapper
Binding>` arm and pattern_match.cpp's comment are unchanged in M (the
prototype shows the match lane resolving an `AliasBinding` alternative's
constant the same way: every choice and match golden passes with no new
STDERR); a reviewer who finds a shape that does not is a fix-budget item.
refutable_binding.cpp: `LocalPatternMatch(context, SemIR::LocId(pattern_id),
...)` at its three calls; its notes converted.

### §2.10 EH-A's return notes and `?`

return.cpp: upstream's machinery (`NoteReturnTypeIsDeduced`,
`ConvertReturnExpr`, `BuildPendingReturn`, `CompletePendingReturns`, the
static `LABEL`/`Attach` notes); the fork's exported `NoteNoReturnTypeProvided`,
`NoteReturnType`, `NoteReturnedVar` rewritten on `CARBON_DIAGNOSTIC_LABEL(X,
Info, ...)` + `Attach`, and `NoteReturnForm` added taking upstream's
deduced-form location (hunk 2 calls it), so return.h:27 and
handle_question.cpp:238 compile; handle_question.cpp's `QuestionOperandNotTry`
and `QuestionCppCatchingImportNote` contexts/notes converted.

### §2.11 kind.def and the diagnostics conversion (D-UA3-11)

kind.def: upstream's side of each of the six hunks; drop the 17 cut lines on
the fork sides (`CppInteropParseNote`, `NoPeriodSelfForDesignator`, the 11
`IncompleteTypeIn*`, `InCopy`, `StructNamePrevious`, `ConversionFailure`,
`ConversionFailureNonTypeToFacet`); re-add the fork-added Error/Warning kinds
(hunk 1: `CppReservedNameShadowed`, `CppCatchingImportNonScalarSuccess`,
`CppExportResultNeedsExpectedHeader`, `CppSumTypeNotMapped`,
`CppSumTypeMismatch`, `CppSumTypeReverseMismatch`; hunk 2:
`CallArgCountTooFewForPack`, `PackExpansionArgForSingularParam`,
`PackExpansionArgWithoutPackParam`; hunk 3: `TemplateMemberLookupAmbiguous`;
hunk 4: `ChoicePayloadNotTrivialInSpecific`; hunk 5:
`StructPatternDiscardWithoutFields`, `StructPatternNameDuplicate`; hunk 6:
the six `Question*`); remove the fork's 20 Note kinds (`Match{Case,Default}
NeverMatches{FullCoverage,PriorArm}`, `EnclosingPackExpansion`,
`PreviousPackExpansionPattern`, `CppSumType{TooManyAlternatives,
NotTriviallyCopyable,QualifiedAlternative,AlternativeNotAdmitted}`,
`OverloadMarkerPrevious`, `OverloadSetDeclaredHere`,
`InCallToVariadicFunction`, `OverloadCandidateRejected`,
`StructuralMember{IsRequirement,Mismatch,Missing,Inaccessible}`,
`StructuralRequirement{Here,NeedsConcreteType}`, `StructPatternNamePrevious`)
and 7 Context kinds (`IncompleteTypeIn{PackExpansion,MatchScrutinee,
BuiltinCall,ChoicePayload}`, `StructuralRequirementIncompleteType`,
`QuestionOperandNotTry`, `QuestionCppCatchingImportNote`), each declared at
its use site as a `CARBON_DIAGNOSTIC_LABEL(X, Info, "...")` or
`CARBON_DIAGNOSTIC_CONTEXT(X, "...")` and attached with `.Attach(loc, X,
args...)`; after the conversion remove the 18 kinds no longer declared
anywhere (prek's check-toolchain-diagnostics and the coverage test name
them). The conversion's files: call.cpp, cpp/import.cpp, cpp/sum_type.cpp,
handle_function.cpp, handle_match.cpp, merge.cpp, pointer_dereference.cpp,
structural_conformance.cpp, eval_inst.cpp, handle_choice.cpp,
handle_question.cpp, refutable_binding.cpp, return.cpp,
handle_pack_expansion.cpp, handle_pattern_list.cpp (the prototype's 11 files
plus the hunk-internal ones). The fork's parse diagnostics keep
`*context.position()` except `HandleMatchGuard` (§0.3).

### §2.12 Parse, sem_ir and driver class-A files

As §0.3: handle_decl_scope_loop.cpp and handle_statement.cpp keep UN-1's and
c0b2cc592's cases; node_ids.h, node_kind.def, typed_nodes.h keep the fork's
union and pack entries beside upstream's; state.def takes upstream's text in
the six hunks it authored and the fork's in the other eleven; parse/context.
cpp puts `ReplaceIntroducerNode` after upstream's four helpers; handle_match.
cpp's `HandleMatchGuard` emits at `context.OpeningBracketInsertionPoint()`;
compile_options.cpp appends EH-B's switch after upstream's codegen args;
sem_ir's x-macro and store files keep both sides sorted.

### §2.13 The prelude's dependents: 21 re-spellings and one INCLUDE-FILE

Non-CHECK source lines edited in M, each cited to 05a7ecbd3 (K-11's
precedent): `impl as Core.Destroy {` → `impl as Core.DestroyImpl {` (and
`impl Guarded as Core.DestroyImpl {`) in check/testdata/class/adapter/
destroy.carbon, function/overload/basic.carbon, generic/template/
initialize.carbon, interop/cpp/class/export/fail_atomic_of_nontrivial_
carbon_class.carbon (:111), named_constraint/template_constraint.carbon,
optional/destroy.carbon, slice/buf_field.carbon, union/fail_nontrivial_
field.carbon, variadics/fail_todo_cleanup.carbon, variadics/fail_todo_
slice.carbon; lower/testdata/function/overload/basic.carbon,
operators/question_generic.carbon, optional/destroy.carbon,
slice/buf_field.carbon, template/initialize.carbon,
variadics/tuple_segment_destroy.carbon; fork/conformance/programs/stdlib/
optional_compare_in_place.carbon, optional_compare_payload.carbon,
optional_destroy_diff.carbon, optional_destroys_value.carbon,
generics/templates_dependent_var.carbon (the EXPECT lines unchanged). The
three conflicting goldens with the same spelling (var/destroy_control_flow
x2, var/param) take upstream's text. lower/testdata/array/mixed_constant_
init.carbon: `// INCLUDE-FILE: toolchain/testing/min_prelude/int.carbon` →
`min_prelude/array.carbon` (947c1eb52; upstream's array goldens' choice).

### §2.14 Goldens (D-UA3-3; Appendix B)

By directory (Appendix B's rows; rev 1's 77/42 corrected 2026-11-23, review
fold: B-m1): check 69 (56 theirs; 11 ours: choice/params, eval/symbolic,
generic/template/call, member_out_of_line, unimplemented,
interop/cpp/template/var_template, let/fail_generic_import,
let/generic_import, named_constraint/invalid_members, patterns/unused,
variadics/pack_expansion; 1 hand: eval/call; 1 clean at a9892d4bb:
generic/template/convert), lower 50 (48 theirs; 1 ours: interop/cpp/globals;
1 clean at a9892d4bb: template/class), parse 3 (2 theirs, 1 ours:
generics/named_constraint/template_constraint), driver 1 (theirs): 123. The
hand merge: `git checkout 7a3608bab -- toolchain/check/testdata/eval/
call.carbon`, then append the fork's split `// --- symbolic_eval_fn_class_
literal_with_field_default.carbon` (its 20 source lines, from `git show
a9892d4bb:<path>`) at the end with no CHECK lines. The other hand-written
testdata in M: union/friend.carbon's source (§2.7) and the §2.13 lines.
Nothing else is touched by hand; the fill moves 320 of the 354 fork-added
goldens (`git diff --name-only --diff-filter=A c1e83b0b7 a9892d4bb` over
toolchain/*/testdata; rev 1 wrote 352) and 106 of the 133 fork-modified ones
(§4).

### §2.15 Non-toolchain files

.github/workflows/check_dependent_pr.yaml: `git checkout 7a3608bab -- <path>`
(D-UA3-16). docs/design/control_flow/loops.md: the fork side (the amendment
blockquote; the file equals trunk's). utils/vscode/carbon.tmLanguage.json:
upstream's `keywords` block; `union` added to the introducer alternation
(`...|require|union|var`) and to the three `impl` look-around lists;
`overload` in the modifier alternation between `musteval` and `override`
(it merges clean there). utils/textmate/Syntaxes/carbon.tmLanguage:
regenerated by `SKIP=... uvx prek run build-textmate-grammar --files
utils/vscode/carbon.tmLanguage.json` and added; the samples' .svg renderings
are upstream's (render_sample.py is not run). MODULE.bazel, .pre-commit-
config.yaml, AGENTS.md, scripts/, utils/nvim, website: upstream's, clean.
docs/design: assignment.md, classes.md, generics/details.md,
pattern_matching.md (its :419-420 take 5ae3dcaa9's `,`? grammar),
variadics.md auto-merge with the fork's dated amendments intact; p008110,
expressions/indexing.md and values.md arrive clean (W-395's realignment is
PR 53's; strings.md:225 and :359 are not edited). Two fork design pages the
advance leaves behind are edited by P (added 2026-11-23, review fold: B-m5):
docs/design/functions_overloading.md:310 and :394 say destructors are `impl
as Core.Destroy` bodies — each gains a dated note "(UA-3, 2026-11-NN: since
upstream 05a7ecbd3 the declared destructor interface is `Core.DestroyImpl`
and `Core.Destroy` is the constraint `SubobjectDestroy & DestroyImpl`; the
gate (xiii) rule is unchanged)"; docs/design/templates.md:593-595 says the
X11 limitation is "pinned by `fail_todo_init_template_dependent_bound.carbon`
in toolchain/check/testdata/array/init_dependent_bound.carbon", a split
upstream renamed `init_template_dependent_bound.carbon` when 947c1eb52 lifted
the limitation — D-UA3-14's note rewrites the bullet to say the program
compiles since 947c1eb52 and names upstream's split.

### §2.16 Records (the commit D; texts in Appendix A)

fork/decision-log.md: the entry "Upstream advance 2026-11: cut c1e83b0b7 →
7a3608bab (2026-11-NN)" directly above "Upstream reconciliation 2026-10
(UA-2)" (the upstream entries newest first, as the weekly entries are), in
UA-1's entry's form (A.5); "resolved by UA-3" lines appended to the six
weekly entries (A.8). fork/ORCHESTRATION.md: the header's first clause, a
dated paragraph, the Branches row, Next actions item 6 rewritten, the
Scoreboard paragraph (A.6). fork/inventory/work-items.json: the discharges
and notes of §0.6 (A.7; the ledger has no status field, so each discharged
item's TITLE gains the prefix W-378 uses, "(DISCHARGED at UA-3, <date>)",
and the status words of rev 1's A.7 are not written anywhere — corrected
2026-11-23, review fold: B-m7); W-079's note; W-401 and W-402 filed.
fork/gap-analysis.md: the header's first sentence (A.11's A.8 form), rows 80
and 81, and row 45 (B-m4; A.12). fork/register: rg1-checks.tsv's seven L
rows with their MEASURED counts at `<anchor>` under a "#" comment line naming
the cut and the anchor (D-UA3-15), check_greps.sh's default cut and comment,
rg1-plan.md's H10.1 row ALIGNED, DR-0's (vi) ALIGNED for the lane and the
match-lane `_`, the D-RG-16 and D-RG-18 notes, the ten new T13 watch rows and
the convergence-candidate row (D-UA3-18), each text verbatim in A.12.
fork/upstream/plan.md: a pointer note under its Status ("UA-3, the advance to
7a3608bab: fork/upstream/ua3-plan.md"). fork/slices/plan.md, fork/w077/
plan.md, fork/templates/plan.md, fork/followon/fo1-plan.md, fork/eh/plan.md
and fork/unions/plan.md: a dated "UA-3" line where their decisions moved
(D-SL-16/D-SL-19 dropped, W-077's `_` on upstream's node for the match lane,
TP-1's `&` on upstream's action with D-TP-23's rendering kept, D-FO1-1's
reach narrowed to the `DestroyImpl` half, EH-A's D10 epilogue in upstream's
`ReturnKind` arm, UN-1's union handlers collecting friend scopes), the texts
in A.12 (added 2026-11-23, review fold: B-m7 / A-M1).

## §3 Commit structure (one PR, base trunk; R29 (b))

1.  **P0, the plan** (this commit and its revisions): fork/upstream/
    ua3-plan.md only.
2.  **T, the base**: `git merge --no-ff trunk` at a9892d4bb into the branch
    ("UA-3 (T): merge trunk a9892d4bb into claude/carbon-fork-0-1-ua3 before
    M", A.1); no conflict (the branch holds only P0). If trunk has moved, T
    takes the new trunk and D-UA3-1's break condition applies.
3.  **M, the merge**: `git merge --no-ff --no-commit 7a3608bab`; every
    textual resolution of §0.3 (Appendix B for the goldens, D-UA3-3's checkout
    commands), every silent fix of §0.4 (items 1-20, 23 and 24: the union
    handlers' friend-scope push and pop, the `_` handler's lane gate), the
    comment re-wordings of §2.2 item 6, the prelude edits and the 22
    non-CHECK source edits of §2.13, the new golden union/friend.carbon
    (source only, no CHECK lines), the §2.15 files, prek on every touched
    non-testdata file to a fixpoint (clang-format's changes are M's), the
    §8.2 greps, then the build, then `git add -- <paths>` by explicit path
    and `git commit -F` with A.2's message (the §0.3 table's class summary as
    its body, UA-1's commit 1 form). M is meant to build and to pass the gate
    but for the goldens the fill rewrites: the prototype's five fix commits
    and the rev 2 re-measurement's amendments are folded into it (their
    content is §0.4's), so no C-n commit is planned between M and F; the gate
    before F is expected at about 1666 passed / 449 failed of 2115 (the
    prototype's 448 plus union/friend.carbon, the failing set being the
    fill's), with NO crash line. A build error or a crash at M is a defect of
    the resolution (R17): fixed in M before it is committed (M is not yet a
    PR commit; once committed, by a fix commit, never an amend) (amended
    2026-11-23, review fold: A-M1 / A-M2 / A-m2).
4.  **F, the fill**: §8.1's command form with `autoupdate.sh` to the fixpoint
    (pass 1 about 448 files, pass 2 about 28 location-only files, pass 3 none;
    R26), then `git add -- <the changed goldens>` (the paths from the autoupdate
    log, never `-A`) and A.3's message. F's non-CHECK diff is empty (§8.1
    verifies it by the stripped comparison of every file). The manual-fix list
    after pass 1 is expected to name exactly the ten entries of §0.5 (eight
    succeeding `fail_` splits, two failing splits); any other entry is a finding
    (§7). The gate after F: 2109 passed, 6 failed of 2115 (the six files of
    §0.5; union/friend.carbon passes once filled).
5.  **R-1 to R-5, the retirements' separable halves** (each a golden commit
    with A.4's message, each leaving its own file passing; the gate after
    R-5 is expected 2115 of 2115 — the manifest is 2114 plus union/
    friend.carbon, and R-3 deletes nothing; rev 1's 2113 corrected
    2026-11-23, review fold: A-M4 / B-M1): R-1 (W-360) renames
    default_values.carbon's split `fail_todo_generic_member_default` to
    `generic_member_default` and rewrites its TODO comment to the record of
    D-UA3-9; R-2 (W-361) renames overload_set_default.carbon's split
    `fail_cpp_omitted` to `cpp_omitted` in the check golden (the lower
    twin's split carries no prefix) with D-UA3-9's record in its comment;
    R-3 (W-372, W-079) RENAMES check/testdata/let/fail_todo_struct_pattern.
    carbon to let/struct_pattern.carbon (`git mv`), drops its four splits'
    `fail_todo_` prefix, rewrites its header as §2.3 says and adds the split
    `fail_todo_underscore_param` (`fn F({x: i32, _});`), autoupdate
    refilling the file in the same commit; it deletes nothing, because the
    parameter and let-in-match-arm-body shapes are pinned nowhere upstream
    (a passing fork pin is never deleted: D-UA3-2, R16 (b)); R-4 (W-037's
    note) renames lambda.carbon's `fail_todo_as_non_constant_template_
    argument` to `as_non_constant_template_argument` and replaces upstream's
    TODO line by a Fork note: the split passes because TP-1 performs `f(42)`
    as a `CallAction` in each specific of `PassToTemplate` — upstream
    7a3608bab itself still rejects it ("value of type `<type of function
    expression>` is not callable", its CHECK lines at the tip), so this is a
    fork mechanism making an upstream `fail_todo` pass, a convergence
    candidate for the register, not 1b0a5709e's doing (rev 1's attribution
    corrected 2026-11-23, review fold: A-m1); R-5 (W-401) renames
    `self_facet_in_signature_required` to `fail_todo_self_facet_in_signature_
    required` and `incomplete_self_signature` to `fail_todo_incomplete_self_
    signature`, their comments naming W-401, the diagnostic and the
    out-of-line workaround (D-UA3-13); W-401 MUST be filed in D in the same
    PR (an un-filed `fail_todo_` is a hidden failure; B-M3). A rename changes
    no CHECK line by hand; the refill autoupdate writes after a rename (a
    split header's line offsets, a renamed file's TIP lines) is part of the
    same R-n commit, from autoupdate. The rev 2 re-measurement made all five
    in this form on the prototype's tree: gate 2115 passed, 0 failed (§0.5).
6.  **C-2, the checkers** and **P, the page**: C-2 teaches
    fork/designdocs/check_samples.py and fork/evaluator/check_faq.py the
    rendered diagnostic form (D-UA3-14) with one self-check case each; P
    amends docs/design/templates.md's bullet at :590-596 with a dated note
    (947c1eb52; the X11 sample now compiles) and the checker's expectation
    for X11. Both predicted; the falsifier is 0 errors from each checker on
    the merged install.
7.  **Two implementation reviews** of the branch (fidelity; mechanics), then
    **fix commits**, at most three rounds, each with its fill and gate.
8.  **D, the records**: §2.16's texts (A.5 to A.9, A.11's rows), the ledger
    (A.7), W-401 and W-402 filed, prek to a fixpoint, R31's counts before and
    after on each markdown file (`r31.py`), `json.load` of the ledger,
    `runner.py --self-test`, the model-identifier grep of the branch's diff
    (0 hits), the id re-scan repeated.
9.  **The PR** (A.10's text; base trunk; never pushed or opened by the
    implementer: the orchestrator does) and **the landing** by LAND-1's
    D-LAND-6 (the merge of the PR into trunk is a second merge commit L; the
    land tree built, gated and conformance-run by the arbiter at the tip
    pin; the land records commit with A.11's texts, placeholders filled from
    `pull_request_read`).

Author and committer rules: `git -c user.name=Claude -c
user.email=noreply@anthropic.com commit --author='jmann345
<jerrymannstan@gmail.com>' -F <message file>`; the message ends after a
blank line with the session's two trailers; explicit paths only; a new
commit every time (never an amend, rebase or force-push once a commit is on
the branch); no push, no PR, no dispatch by the implementer.

**The shrink line (D-UA3-17; rewritten 2026-11-23, review fold: B-M3).**
R-1 to R-5 are not deferrable: after F the manual-fix list names eight
`fail_` splits that pass and two that fail, the arbiter counts each as
FAILED, and a red gate is not merged (R33 (c)); R-5's two `fail_todo_`
renames require W-401 filed in D in the same PR. The shrink line applies to
C-2 and P only: if they do not fit the review and fix budget, the PR carries
T + M + F + R-1 to R-5 (+ the fix commits) + D, D re-files D-UA3-14 as OPEN
with the two checkers' measured error counts, and C-2/P follow as their own
PR with that item.

## §4 Testdata expectations (R16: no hand-written goldens)

-   **The gate count.** 2047 test files at a9892d4bb; upstream adds 68 test
    files and deletes one (interface/fail_incorrect_destroy_method_
    declarations.carbon) → 2114 on the prototype (its build log; reader 3's
    "+65 −1 = 2111" undercounted upstream's non-golden test files); M adds
    union/friend.carbon → the manifest reads **2115** after M (the rev 2
    re-measurement's build log) and stays 2115 after R-3, which renames and
    deletes nothing. Expected gate lines: before F "1666 passed, 449 failed"
    (the prototype's 448 plus union/friend.carbon; a crash line is a
    defect), after F "2109 passed, 6 failed" (the six files of §0.5), after
    R-5 "2115 passed, 0 failed" (measured on the re-measurement: `GATE
    ua3-fixer: 2115 passed, 0 failed`) (amended 2026-11-23, review fold:
    A-M1 / A-M4 / B-M1).
-   **The fill's composition (measured):** 448 files in pass 1 = 320 of the
    fork's 354 added goldens + 106 of its 133 modified goldens (92 of them
    among the 107 taken-theirs conflicts) + 22 upstream-only goldens; pass 2
    28 files, every change location-only (`loc` inst names, `[[@LINE]]`
    offsets, `DILocation` and clang AST line numbers, the renderer's gap
    markers collapsing in patterns/unused.carbon once pass 1's inserted lines
    made two snippets adjacent); pass 3 none. On the product M's new
    union/friend.carbon joins pass 1 (449 files). The 22 upstream-only
    goldens the fill touches, each explained (K-2's class, none a defect): the
    fence on upstream's new import/export thunks (lower interop/cpp/class/
    import/inherit.carbon, function/export/macho_asm_label.carbon:
    `__clang_call_terminate` and the "exception escaped" string, D-UA-7's
    expected churn); the fork's prelude in upstream's lowering goldens (lower
    let/global.carbon: `Core.Optional.Get`'s fail-stop string from OP-2,
    `SubobjectDestroy` defines renamed; interop/cpp/class/export/
    field_imported.carbon: the fork's export destroy thunk no longer emitted
    for a type with no destroy work, −80 lines); SC-1's identification step
    adding `require_complete_type` witnesses, IR only, no STDERR, to
    upstream's new `.Self`/rewrite-constraint goldens (facet/period_self,
    generic/dot_self_symbolic_type, interface/final, interface/observe,
    interface/require, named_constraint/require, impl/period_self,
    impl/lookup/lookup_interface_with_enclosing_generic_inside_rewrite_
    constraint, impl/lookup/specialization_with_symbolic_rewrite,
    where_expr/dot_self_index, function/deduced_return/template); TP-1's
    deferral in array/init_dependent_bound.carbon (the X11 shape); EH-A's
    entry-point message in function/definition/terse.carbon and
    main_run/fail_mismatch_return_auto.carbon; the fork's thunk snippet in
    class/access/inheritance_access.carbon's rendered C++ line; W-372's
    patterns/struct.carbon (the renderer's form only: `fail_todo_underscore`
    keeps upstream's TODO, D-UA3-6 as amended — rev 1's "fails on the field
    name" was the dead-discard defect, review fold A-M2); lambda.carbon's
    split passing (R-4: TP-1's `CallAction`, A-m1); and OP-2's
    adapter rule adding an earlier diagnostic in interop/cpp/impls/
    destroy.carbon's `fail_no_destroy` split (an adapter of a C++ type with a
    deleted destructor is queried for its adapted type's witness at the
    `var`; the program is ill-formed either way; recorded as a convergence
    candidate). A 23rd file outside this list is the K-2 falsifier.
-   **Design-reason changes, hand-traced on the prototype's fill** (the
    rest is shorthand names, rendered diagnostics and `DestroyImpl`): the
    TP-1 goldens on upstream's `AddrOfAction` (generic/template/
    pointer.carbon: one `addr_of_action` before and after, +147 −123, the
    inst printed under upstream's `Dependent` category); the struct-pattern
    goldens (match/struct_pattern.carbon +1208 −1153, the `_` splits keep
    their behavior, the diagnostics re-rendered; patterns/struct.carbon as
    above; let/fail_todo_struct_pattern.carbon's four splits pass, then R-3
    renames the file and its splits and adds the `_` parameter pin);
    the destroy goldens (class/destroy_calls.carbon theirs; union/basic.carbon
    +1421 −2202 with `SelfDestruct` mentions 203 → 55 as the fork's
    three-entry witness gives way to one `SubobjectDestroy.Op` per type and
    `_CSelfDestruct` calls; lower/choice/payload_layout.carbon +167 −202;
    lower/slice/buf.carbon +383 −413 with exactly 3 `free`); the default-
    value export goldens (check overload_set_default.carbon +98 −98:
    `fail_cpp_omitted`'s "no matching function for call to 'F'" lines gone;
    its lower twin +44 −28; default_values.carbon +823 −736 with the generic
    member selected for `F(true)`); the export.cpp goldens of 54728e47f and
    4abb6100e (lower overload_set.carbon +252 −249, `linkonce_odr` 9 → 17:
    every member thunk now defined in Clang's function; overload_set_ast
    .carbon and the ST-1 export goldens re-rendered, D-ST-12's pin split
    intact); W-069's pins (lower/let/global_runtime_symbols.carbon:
    `%total.ref` → `%total.global_ref`, `@_Ctotal.Main` unchanged, a `!dbg`
    on the store).
-   **Pre-registered shapes:** `__clang_call_terminate` in at least 35 lower
    goldens (40 on the prototype); `personality ptr @__gxx_personality_v0`
    the same; lower/slice/buf.carbon exactly 3 `free`; every union golden
    with a `var` destroys through one `SubobjectDestroy.Op` for the class
    and the `CustomLayoutType` repr (D-UA-9's shapes under upstream's new
    names); the OV mangling `:overload<N>` and `_CF__carbon_thunk:overload<N>`
    unchanged; fail_fence_thunk_unbuildable.carbon stays a `fail_` with the
    SemanticsTodo; union/fail_modifiers_and_redecl.carbon keeps
    `DuplicateName` and "redefinition of `union D`";
    function/overload/fail_marker_mismatch.carbon keeps
    `OverloadMarkerMismatch` on both directions; `fail_default_not_trailing`
    keeps its count mismatches without a crash. Added 2026-11-23 (review fold:
    A-M3 / A-M1 / A-M2): generic/template/index.carbon:332 and :337 keep
    ``previously declared with return type `D(&p.n)` `` and ``return type is
    `D(&p.m)` `` (D-TP-23's rendering of `AddrOfAction`; `grep -c 'D(&p\.[nm])'`
    → 6 on the re-measurement, two source lines and four CHECK mentions);
    union/friend.carbon's three splits: `friend_class` passes,
    `fail_non_friend` "cannot access private member `word` of type `U`",
    `fail_friend_var` "friend declaration names entity that is not a name
    scope"; patterns/struct.carbon's `fail_todo_underscore` and
    let/struct_pattern.carbon's `fail_todo_underscore_param` print
    ``semantics TODO: `Struct pattern underscore field` `` and nothing else
    (measured on the re-measurement's fill).
-   **The manual-fix list** (upstream's autoupdate prints "Problems that
    require manual fixes:" per split whose `fail_` prefix no longer matches):
    expected exactly the ten entries of §0.5; each becomes R-1 to R-5. The
    arbiter's gate counts them as FAILED, so an un-retriaged entry is a red
    gate, never a crash.

## §5 Conformance

-   **Bar:** trunk a9892d4bb's 226 PASS / 0 FAIL / 15 SKIP over 241, 51 of
    56 bullets (equal to tp2-base's 228 / 0 / 13 but for TP-2's two SKIPs
    W-396 and W-397; trunk cb7821735's toolchain and programs are
    a9892d4bb's). No program changes status in UA-3 (the prototype's
    line: `CONFORMANCE ua3-proto: PASS 226 / FAIL 0 / SKIP 15 over 241
    programs; bullets 51 PASS, 0 FAIL, 5 SKIP, 0 NOT-WRITTEN`, run twice,
    scoreboard generated 2026-11-16T22:53:04Z; its SKIP set is tp2-base's 13
    plus exactly the two TP-2 paths; the rev 2 re-measurement's line is the
    same with the label ua3-fixer, §0.5).
-   **Programs whose source the advance changes:** the five re-spelled
    `impl as Core.DestroyImpl` programs (stdlib/optional_compare_in_place,
    optional_compare_payload, optional_destroy_diff, optional_destroys_value,
    generics/templates_dependent_var), their EXPECT-EXIT and EXPECT-STDOUT
    lines unchanged (05a7ecbd3's `ImplOfNotOneInterface` would otherwise
    reject them). W-354's string.carbon:154 is a prelude prerequisite of
    every program (the prelude compiles for each). The R30 pair
    (cpp_export_overload_set.carbon and cpp_export_overload_set_
    divergence.carbon) keeps its lines: 9799a2326 exports defaults, which
    those programs do not use.
-   **None of the 13 SKIPs cites a window feature;** no un-SKIP probe is
    UA-3's (D-UA-12's rule holds: the merge is judged by non-regression).
-   **R7:** no bullet text changes; `python3 -I fork/conformance/runner.py
    --self-test` prints "self-test: 241 programs parsed, 56 bullets in table,
    OK" at every commit.

## §6 Churn inventory (measured on the prototype)

-   Conflicting sources resolved by hand: 73 (34 A, 33 B, 5 C, 1 X), two of
    them `git rm`; silent-fix sites outside the hunks in 16 more files
    (§0.4); the prelude (4 files) and 22 non-CHECK golden/program lines.
-   M against a9892d4bb: 2149 files, +180960 −146866 (upstream's own window
    included); non-testdata 696 files, +32241 −9292.
-   The fork's carried delta over upstream, sources only (`git diff
    --numstat <upstream> <fork> -- toolchain ':(exclude)*testdata*'`): 196
    files, +26121 −1388 at the cut (c1e83b0b7 → a9892d4bb); **195 files,
    +24690 −934** after the advance (7a3608bab → the prototype's HEAD): the
    retirements take 1431 added lines off the fork's carry. Goldens: 487
    files +206414 −10820 before; 492 files +198616 −8712 after (348 added,
    144 modified over upstream's).
-   The fill: 448 goldens, +95429 −93651 (pass 1 and 2 together); pass 2 28
    files.
-   The five prototype fix commits folded into M: 37 file edits, +249 −274
    (fix 5 being clang-format over 19 resolved files plus the once-flag).
-   Deleted fork code (class C): the six `Destroy` builders and the yield
    (about 330 lines of custom_witness.cpp), `PerformAddrOf` and its action
    (about 45 lines), W-069 lane a1 (about 420 lines across six files),
    W-077's names stack and gate (about 60 lines), `MakeLetBinding`,
    `SubstImplSelfWitnesses`, the `RequireSpecificDefinition` evaluator.
-   Added fork-local clauses inside upstream code: `IsCoreDestroyImplInFile`
    and the predicates' re-keying, the `PatternListUnderscoreField` recorder
    with its lane gate and the `has_trailing_discard` field, the
    `overload_set_definitions_checked_` flag, the `EntryPointInt32` arm's
    epilogue, the `where` region's discard, the expr_info guard, the
    storage-chain carriage, D-ST-12's check, `lookup.specific_id`, the
    pack-name check's new home (each marked Fork and named in D-UA3-18's
    watch rows); in fork code, the union handlers' friend-scope push and pop
    (eleven lines mirroring handle_class.cpp) and the two kept stringify
    cases (rev 2: +11 lines, −0 deleted, one new golden of 60 source lines,
    one golden renamed with a 5-line split added; the comment re-wordings
    change no code; review fold A-M1 / A-M2 / A-M3 / A-m2).
-   Per-mechanism cost (the conflicting files each owns): overloads 6
    (call.cpp, check_unit.cpp, handle_function.cpp, file.cpp, function.h,
    mangler.cpp), unions 6, variadics 7, templates 9 (action, convert,
    handle_index, handle_operator, pointer_dereference, import_ref, inst,
    expr_info, aggregate), structural 8, sum types and match 8 (handle_choice,
    pattern_match, full_pattern_stack.{h,cpp}, handle_binding_pattern,
    handle_pattern_list, node_stack.h, parse/handle_match), optional 1
    (custom_witness.cpp's adapter arm), slices 2, strings 1 (export.cpp),
    error handling 7 (return.cpp, kind.def, compile_options.cpp, thunk.cpp,
    cpp/import.cpp, lower/handle.cpp, lower/type.cpp), cpp-templates 2,
    W-069 4; the diagnostics conversion touches 15 files across every
    mechanism.
-   Records: the decision-log entry, six weekly notes, ORCHESTRATION's four
    regions, 15 ledger items (two new; W-079 added at rev 2), three gap rows
    (45 added at rev 2) and the header, the register's tsv (seven measured L
    rows, eleven watch rows) and script, rg1-plan.md's rows, six plans' dated
    lines, fork/upstream/plan.md's pointer, templates.md's bullet and
    functions_overloading.md's two notes (rev 2), the two checkers.

## §7 Risks and rejected alternatives (each with its falsifier)

Risks are K-1 to K-16 (rev 1 named them R-1 to R-14, colliding with the
commits R-1 to R-5; renamed 2026-11-23, review fold: B-m7; K-4 and K-14
rewritten, K-15 and K-16 added by the fold). Ranking: K-1 (a resolution the
prototype did not need and the product does, because M is redone by hand) >
K-2 (the 22 upstream-only goldens and the fill's manual-fix list differing
from the prototype's) > K-15 (another window-added class-body feature inside
a union body, the A-M1 class) > K-14 (the register's anchor moving between M
and D) > K-3 (the arbiter: the pin, the archives, `applied`) > K-5 (D-UA3-13's
decision) > the rest.

-   **K-1 The merge redone by hand diverges from the prototype.** Falsifier:
    the build log's first error, a crash line in the gate, or a gate before
    F other than "1666 passed, 449 failed" with the prototype's failing set
    (gate-prefill2-failed.txt's 448 plus union/friend.carbon); `diff` of the
    product's `resolution-vs-upstream.patch` against the prototype's over
    the 73 conflicting sources plus handle_union.cpp (expected: exactly the
    rev 2 amendments of Appendix C's amendments.patch — the union handlers'
    friend-scope push and pop, the `_` handler's lane gate, the comment
    re-wordings — and nothing else; amended 2026-11-23, review fold: A-M1 /
    A-M2 / A-M3). Mitigation: resolutions.tsv, the patch and
    amendments.patch are the reference; the §8.2 greps before the build.
-   **K-2 Fill churn beyond the explained set.** Falsifier: a pass-1 file not
    among the prototype's 448 (fill-paths.txt) plus union/friend.carbon, a
    23rd upstream-only golden, a manual-fix entry beyond the ten, a pass-2
    change that is not location-only (R26 says stop and diagnose).
-   **K-3 The arbiter.** Falsifier: the gen_ninja line naming the old pin;
    a link error naming `mlir::` or `cir::` symbols (ARB-5 missing from the
    arbiter of record: `grep -c libCIR gen_ninja.py` 0); the GATE line
    reading `applied`. Mitigation: D-UA3-4; none is a merge defect.
-   **K-4 Upstream adds stringification for its actions** (rev 1's K-4,
    "deleting TP-1's stringify cases degrades a diagnostic", is retired: the
    cases are kept, D-UA3-7, review fold A-M3). Falsifier: T13.9 non-zero
    (`AddrOfAction` in upstream's stringify.cpp), or any `StringifyInst(...
    Action)` overload at a later tip; disposition: upstream's rendering
    replaces D-TP-23's cases at the next advance.
-   **K-5 OP-2 item 10's retriage hides a reachable program shape.**
    Falsifier: a conformance program or a fork golden outside the two splits
    forming `Core.Optional(Self)` or `Core.Slice(Self)` inside a class
    definition (grep `Optional\(Self\)|Slice\(Self\)` over fork/conformance/
    programs and toolchain/*/testdata: the two splits only, measured on the
    prototype's unchanged 226 PASS); disposition D-UA3-13.
-   **K-6 The `DestroyImpl` identity across IRs.** Falsifier: the union field
    rule rejecting `i32`/`u8`/`array` (the 27 splits of fix 4); mutant M1.
-   **K-7 The fence after the rename.** Falsifier: `EST_BasicNoexcept` other
    than 4 with awk 1; `__clang_call_terminate` in fewer than 35 lower
    goldens; the error_handling/cpp_exception_* programs.
-   **K-8 `has_trailing_discard` never set, set from the wrong node, or read
    in a lane that converts.** Falsifier: match/struct_pattern.carbon's
    discard splits; mutants M2 and M2b (D-UA3-6); patterns/struct.carbon's
    `fail_todo_underscore` printing anything but the TODO.
-   **K-9 W-362's count lost in the move to function.cpp.** Falsifier:
    `fail_default_not_trailing` crashing at pattern_match.cpp's CHECK (the
    OV-4 signature); mutant M3 (predicted): `default_count = state->
    default_count` unconditionally → the split crashes.
-   **K-10 The match lane on `AliasBinding` alternatives.** Falsifier: a
    choice or match golden's fill carrying a new diagnostic or a structural
    change beyond renaming (the prototype: none).
-   **K-11 Upstream's new diagnostics on fork tests and programs.**
    Instance found: interop/cpp/impls/destroy.carbon's `fail_no_destroy`
    (§4; rev 1 also listed patterns/struct.carbon's `fail_todo_underscore`,
    which was the dead discard, A-M2, not an upstream diagnostic);
    disposition: upstream-intended → adopt by refill with the record; a
    COMPILE-FAIL in conformance → fork-side fix.
-   **K-12 The checkers' fix (C-2) misreads a rendered diagnostic.**
    Falsifier: a checker error on the merged install that is not X11;
    the self-check cases.
-   **K-13 W-069's retirement loses a repr upstream's `GlobalRef` lacks.**
    Falsifier: a pin's fill showing the `custom value repr` FATAL; break
    condition in D-UA3-8.
-   **K-14 The register's anchor moves, or a measured L count differs from
    the row written** (rewritten 2026-11-23, review fold: B-B1 / A-m3): a
    weekly records commit lands between M and D (its tip becomes `<anchor>`
    and its rows re-anchor the quotes), or D's L counts were written by
    assertion. Falsifier: either script printing a failure at `<anchor>`
    after D; `git log 7a3608bab..<anchor> -- <paths> | wc -l` differing from
    a row's count. Disposition: D-UA3-15 (re-measure; T re-made onto the
    moved trunk, D-UA3-1).
-   **K-15 Another window-added class-body feature misbehaves inside a union
    body** (added 2026-11-23, review fold: A-M1): 5fed32a9a's `friend` was
    one (item 23); the re-measurement probed d50576ca1's class-scope `let`
    and `static var`, b766aa4d1's terse body, bf5d2a2ac's `-> auto`,
    c0b2cc592's `where` assignment, upstream's `private` rules and
    05a7ecbd3's `impl as Core.DestroyImpl` in a union body: no crash, each
    diagnosing or checking as its class twin does (§0.5). Falsifier: §8.1
    step 9's sweep printing a crash line, or a union golden's fill diagnosing
    where the class twin does not. Disposition: the union handler mirrors the
    class handler (class B, UN-1's rule), a pin split in union/friend.carbon
    or union/basic.carbon.
-   **K-16 The `_` lane gate misclassifies a refutable context** (added
    2026-11-23, review fold: A-M2): a pattern condition or a `let`-`else`
    with a struct pattern ending in `_` would print the TODO instead of
    discarding. The gate keys on `FullPatternStack::Kind::MatchCaseArm`, the
    kind W-077 pushes for exactly the contexts whose pre-work walks the
    scrutinee (`in_match_case_bind`), so the two lanes agree by construction;
    the re-measurement's probes `if (let {.a = x: i32, _} = v)` and `let
    {.a = x: i32, _} = v else {...}` are in §0.5. Falsifier: a refutable
    `_` shape printing the TODO; disposition: the gate reads the same
    predicate the pre-work does.
-   **Rejected alternatives:** (i) advancing to a newer tip than 7a3608bab —
    the audit, the prototype and the fill were made for 7a3608bab, the
    register's anchor is the weekly check's and runs ahead of the cut under
    W-355 (D-UA3-15), and a later tip is the next advance's (its 21 commits
    include f81d32706's LLVM roll past the arbiter's tip pin, which needs
    ARB-6 first — the 2026-11-23 weekly entry); falsifier: none; (ii) a
    rebase of the fork onto upstream — never (R33 (a)'s "never a rewrite of
    the PR's history", UA-1's D-UA-1, 399 fork commits); (iii) taking the
    fork's side in a class-C conflict (keeping `PerformAddrOf` beside
    upstream's handler, the three-entry `Destroy` witness, lane a1) — a drift
    under R32 (d), and the tree would not compile for two of the three; (iv)
    keeping W-378's fix if upstream had fixed the construction — upstream did
    not (check.cpp:431-435 at the tip), so the fix stays; had it, the fix
    would be dropped for upstream's; (v) landing the retirements before the
    merge — impossible for the class-C halves (they are conflict
    resolutions) and pointless for the retriages (the splits pass only on
    the merged toolchain); (vi) a deferred `SubobjectDestroy` witness for
    item 10 inside the merge — R17 (D-UA3-13); (vii) deleting TP-1's two
    stringify cases as "a second spelling of upstream's inst" (rev 1's
    choice) — rejected at rev 2: upstream designs no action rendering,
    D-TP-23 covers every action kind, and index.carbon:332/:337 pin the text
    (A-M3); (viii) building at the old LLVM pin with an arbiter-only source
    overlay — not a measurement of the tree the PR carries (R33 (a)); (ix)
    deleting let/fail_todo_struct_pattern.carbon (rev 1's R-3) — rejected at
    rev 2: a passing fork pin of two shapes upstream does not pin (A-M4,
    B-M1, R16 (b)); (x) implementing the `_` discard for upstream's
    `let`/`var` lane inside the merge — rejected: W-079 records the lane's
    conversion-or-walk question as a design decision (R17), and upstream's
    TODO stands until upstream or that item answers it (A-M2).

## §8 Verification and discharge

### §8.1 The arbiter sequence (container-measured; R28, R33 (b))

Label `ua3-impl` on the branch's worktree /home/user/carbon-ua3; every
command takes this form (the arbiter's checkout variable, the label, the
three LLVM variables of D-UA3-4, then the script; the arbiter is
/home/user/arb/carbonbuild for every script — ARB-5 is synced into it since
2026-11-23, `grep -c libCIR gen_ninja.py` → 2, so rev 1's scratch-copy route
for build.sh is retired; amended 2026-11-23, review fold: B-M2):

<!-- google-doc-style-ignore -->

```text
REPO=/home/user/carbon-ua3 SHA=ua3-impl LLVM_SRC=/home/user/llvm-project-c744694 LLVM_BUILD=/home/user/llvm-build-c744694 LLVM_OVERLAY=/home/user/arb/deps/llvm-overlay-c744694/utils/bazel/llvm-project-overlay /home/user/arb/carbonbuild/<script>
```

<!-- google-doc-style-resume -->

Check `pgrep -fa 'ninja -C|file_test|runner.py'` first; run a build with
`run_in_background` and a 7200000 ms timeout, and wait for it with
`until [ -f <marker> ]; do sleep 20; done` loops of at most 9 minutes.

1.  After M (uncommitted or committed): `build.sh` (the log's gen_ninja line
    names /home/user/llvm-project-c744694 and "file_test manifest: 2115 test
    files"; `=== build.sh done status=0`), `install.py`, `gate.sh --threads 4`
    → "GATE ua3-impl: 1666 passed, 449 failed" (about; no crash line; the
    source-patch word `landed`) (counts amended 2026-11-23, review fold:
    A-M1).
2.  `autoupdate.sh` to the fixpoint (two passes expected, a third empty);
    the manual-fix list read and compared with §0.5's ten; the stripped
    comparison of every changed file (non-CHECK lines identical before and
    after: `grep -vE '^\s*//\s*CHECK'` on both versions, `0 of N differ`);
    commit F; `gate.sh` → "2109 passed, 6 failed" (the six files).
3.  R-1 to R-5; `gate.sh` → "2115 passed, 0 failed" (R-3 renames, so the
    manifest is unchanged and no rebuild is needed between F and this gate;
    amended 2026-11-23, review fold: A-M4 / B-M1).
4.  `CACHE_HOME=/home/user/arb/cache-ua3-impl conformance.sh --background`;
    wait for /home/user/arb/conformance/ua3-impl/.done; the CONFORMANCE line
    must read "PASS 226 / FAIL 0 / SKIP 15 over 241 programs; bullets 51
    PASS, 0 FAIL, 5 SKIP, 0 NOT-WRITTEN".
5.  The register scripts from the worktree root, at `<anchor>` (D-UA3-15; the
    tip the latest weekly entry anchored, 0072b2812 today; rewritten
    2026-11-23, review fold: B-B1): `bash fork/register/check_quotes.sh
    /home/user/carbon-ua3 <anchor> fork/register/rg1-quotes.tsv` → "checked
    294 quotes, 0 failed"; `bash fork/register/check_greps.sh
    /home/user/carbon-ua3 <anchor> fork/register/rg1-checks.tsv` (no fourth
    argument; after D its default is 7a3608bab, and before D the measured L
    counts are written into the rows first) → "checked 96 silence checks, 0
    failed"; the seven L counts themselves by `git -C /home/user/carbon-ua3
    log --oneline 7a3608bab..<anchor> -- <paths> | wc -l` per row, written
    into rg1-checks.tsv as measured. `python3 -I fork/conformance/runner.py
    --self-test` → OK. `python3 -I fork/designdocs/check_samples.py
    --toolchain /home/user/arb/install/ua3-impl/bin/carbon`, the same without
    `--toolchain`, `python3 -I fork/evaluator/check_samples.py` and `python3
    -I fork/evaluator/check_faq.py --toolchain <the same> --which fork` → 0
    errors after C-2 and P (15 and 2 before for the two that read the
    rendered form; B-m6 names all four as D-LAND-6 step 8 does).
6.  The mutants, each an incremental rebuild and a `gate.sh --filter`: M1
    (W-354; measured on the prototype as fix 4's pre-state, re-run optional)
    `--filter union` red on 27 splits; M2 (W-372; predicted) `--filter
    struct_pattern` red; M2b (W-372's lane gate; measured as the prototype's
    state, A-M2) `--filter patterns/struct` red with ``no field named `b` ``
    in place of the TODO; M3 (W-362; predicted) `--filter default_values`
    red with the CHECK at pattern_match.cpp; M4 (D-UA3-7's kept stringify
    cases; measured on the re-measurement, Appendix C) `--filter
    generic/template/index` red with `<cannot stringify` in place of
    `D(&p.n)`. The mutant commits are never committed; the worktree is
    restored by `git checkout -- <path>`.
7.  After the reviews' fixes: steps 1-5 again on the branch tip; the
    autoupdate line "0 file(s) changed" is the R26 fixpoint proof.
8.  Clean-up: `rm -rf /home/user/arb/build/ua3-impl /home/user/arb/install/
    ua3-impl /home/user/arb/conformance/ua3-impl /home/user/arb/cache-ua3-impl`
    (literal paths) when the PR is handed over; the prototype's label stays
    for the reviews.
9.  The union-body sweep (added 2026-11-23, review fold: A-M1), run on the
    install after M with `carbon compile --phase=check` on one-file probes
    under the implementer's scratch, each a window-added class-body feature
    inside `union U { ... }`: `friend C;` (exit 0 expected), a class-scope
    `let N: i32 = 1;`, a `static var`, a terse-body method (`fn Get(self) =>
    self.a;`), `fn Get(self) -> auto`, a `where` assignment, a `private fn`
    called from outside, `impl as Core.DestroyImpl`; the criterion is NO
    crash line (`Stack dump`, `CHECK failure`, `FATAL`) and the same
    diagnostic the class twin gives (the re-measurement's outputs are §0.5's;
    a difference from them is a K-15 finding). The W-372 probes beside them:
    `let {.a = x: i32, _} = ...`, `var {.a = x: i32, _,} = ...` and `fn
    F({x: i32, _});` print the TODO; `match`, `if (let ...)` and `let ...
    else` with a trailing `_` exit 0.

Not run, and why: clang-tidy (no binary in the container); the hosted gate
(Actions disabled since 2026-10-08; owed when it returns, R33 (b)); Bazel
(never installed; the three bazel-backed prek hooks and forbid-llvm-googletest
skipped, the hosted gate their authority); the owner's machine (R28);
upstream's own toolchain at 7a3608bab (none exists; the nightly 2026.10.12
predates 05a7ecbd3 and is an oracle only, R30).

### §8.2 Verification greps (before the build, at D, and at the landing)

All over the worktree; the expected values are the prototype's as re-measured
on 2026-11-23 (rev 1's "about" counts for `has_trailing_discard`,
`PatternListUnderscoreField`, `trailing_default_count` and
`storage_access_block_id` did not match the prototype; corrected, review fold:
B-m3) and the rev 2 re-measurement's for the amended files.

-   `grep -rn 'OperandDependence(context,' toolchain` → empty; `grep -rn
    GenericClassType toolchain` → empty; `grep -rn CalleeFunctionInfo
    toolchain | grep -v CppCalleeFunctionInfo` → empty.
-   `grep -rn 'builder.Note(\|\.Context(' toolchain/check` → empty; `grep -rn
    'CARBON_DIAGNOSTIC(.*, Note,\|CARBON_DIAGNOSTIC(.*, Context,' toolchain`
    → empty.
-   `grep -rn 'SemIR::IdentifiedFacetType\|RequireSpecificDefinition\|
    SubstImplSelfWitnesses' toolchain` → empty; `ls toolchain/sem_ir/
    identified_facet_type.*` → no such file.
-   D-UA3-5: `grep -rn 'CoreInterface::Destroy\b\|BuildCarbonDestroyWitness\|
    MakeDestroySelfDestructFunction\|LookupDestroyWitness' toolchain/check`
    → empty (code AND comments: the comment-inclusive form `grep -rn
    'LookupDestroyWitness\|BuildDestroyWitness\b\|Destroy\.SelfDestruct\|
    MangleGlobalLetBinding\|PerformAddrOf\|struct_pattern_names_stack\|
    MakeLetBinding\|SubstImplSelfWitnesses' toolchain --exclude-dir=testdata`
    → empty, the retired names gone from prose too; the prototype read 9
    hits in custom_witness.cpp/.h, the re-measurement's re-wording leaves 0
    of those; added 2026-11-23, review fold: A-m2); `grep -c
    IsCoreDestroyImplInFile toolchain/check/custom_witness.cpp` → 3; `grep -c
    is_choice toolchain/check/custom_witness.cpp` → 6; `grep -n
    'as DestroyImpl' core/prelude/types/buf.carbon core/prelude/types/
    string.carbon core/prelude/types/optional.carbon` → three hits; `grep -rn
    'as Core\.Destroy\s*{' toolchain/*/testdata fork/conformance/programs` →
    empty.
-   D-UA3-6: `grep -rn struct_pattern_names_stack toolchain` → empty; `grep
    -c has_trailing_discard toolchain/check/handle_pattern_list.cpp
    toolchain/sem_ir/typed_insts.h toolchain/check/pattern_match.cpp` → 6,
    1, 1 (the prototype's and the re-measurement's; rev 1 wrote 5, 1, 2);
    `grep -c PatternListUnderscoreField toolchain/check/handle_pattern_list.
    cpp` → 5 (rev 1 wrote 3) and `toolchain/check/node_stack.h` → 1; `grep
    -c 'Struct pattern underscore field' toolchain/check/handle_pattern_list.
    cpp` → 1 (the lane gate's TODO; added 2026-11-23, review fold: A-M2 /
    B-m3).
-   D-UA3-7: `grep -rn PerformAddrOf toolchain` → empty; `grep -c AddrOfAction
    toolchain/sem_ir/stringify.cpp` → 2 (the kept cases; rev 1 expected 0,
    reversed 2026-11-23, review fold: A-M3); `grep -n
    'HandleAction<SemIR::AddrOfAction>' toolchain/check/handle_operator.cpp`
    → 1.
-   §0.4 item 23: `grep -c friend_scopes_stack toolchain/check/
    handle_union.cpp` → 4 (the push, the two peeks, the pop; 0 on the
    prototype) and `toolchain/check/handle_class.cpp` → 5 (upstream's, the
    T13.10 row counts its three distinct sites at the tip) (added 2026-11-23,
    review fold: A-M1).
-   D-UA3-8: `grep -rn 'GlobalLet\|TryEmitGlobalLetValue\|
    MangleGlobalLetBinding\|is_global_ctor_' toolchain` → empty; `grep -c
    GetOrCreateGlobalBinding toolchain/lower/file_context.cpp` → non-zero.
-   D-UA-7 on the rename: `grep -c EST_BasicNoexcept toolchain/check/cpp/
    thunk.cpp` → 4 and `awk '/^static auto CreateThunkFunctionDecl/,/^}/'
    toolchain/check/cpp/thunk.cpp | grep -c EST_BasicNoexcept` → 1.
-   D-UA3-10: `grep -n 'reserve\|emplace_back' toolchain/check/check.cpp` →
    the in-place construction at about :437-439; the GATE line `landed`.
-   D-UA3-12: `grep -c overload_set_definitions_checked_ toolchain/check/
    check_unit.cpp toolchain/check/check_unit.h` → 2, 1; `grep -c
    DiscardGenericDeclIntoEnclosingGeneric toolchain/check/handle_where.cpp` →
    1; `grep -c 'lookup.specific_id' toolchain/check/cpp/generate_ast.cpp` →
    3; `grep -c trailing_default_count toolchain/check/function.cpp` → 4
    (rev 1 wrote 3); `grep -c TryEvalPackIterationsForSpecific toolchain/check/
    generic.cpp` → 1 call; `grep -n 'D-ST-12' toolchain/check/cpp/export.cpp`
    → inside the moved `ExportClassToCpp`; `grep -c storage_access_block_id
    toolchain/check/convert.cpp` → 5 (rev 1 wrote 4) (the two counts
    corrected 2026-11-23, review fold: B-m3).
-   D-UA3-16: `grep -c "github.repository == 'carbon-language/carbon-lang'"
    .github/workflows/*.yaml | awk -F: '{s+=$2} END {print s}'` → 5.
-   After the fill: `grep -rl __clang_call_terminate toolchain/lower/testdata
    | wc -l` ≥ 35 (40); `grep -c '@free(' toolchain/lower/testdata/slice/
    buf.carbon` → 3; `grep -c addr_of_action toolchain/check/testdata/generic/
    template/pointer.carbon` → 1; `grep -c 'D(&p\.[nm])' toolchain/check/
    testdata/generic/template/index.carbon` → 6 (A-M3); `grep -c 'semantics
    TODO: `Struct pattern underscore field`' toolchain/check/testdata/
    patterns/struct.carbon toolchain/check/testdata/let/struct_pattern.carbon`
    → 1, 1 (A-M2); `grep -c 'error:' toolchain/check/testdata/union/
    friend.carbon` → 2 (the two `fail_` splits; A-M1).
-   Records: `grep -rn 'model-id-pattern' ...` is the harness's
    model-identifier grep of the branch's diff → 0 hits; `python3 -I
    <scratch>/sv1-fixer5/bin/r31.py <file>` before and after each markdown
    edit; `python3 -I -c 'import json; json.load(open("fork/inventory/
    work-items.json"))'`.

### §8.3 Discharge (the records commit D; texts in Appendix A)

-   The decision-log entry "Upstream advance 2026-11: cut c1e83b0b7 →
    7a3608bab (2026-11-NN)" in UA-1's entry's form, placed directly above
    "Upstream reconciliation 2026-10 (UA-2)" (A.5).
-   ORCHESTRATION: the header's first clause, the dated paragraph before the
    last one, the Branches row for `claude/carbon-fork-0-1-ua3`, Next actions
    item 6 rewritten (the "In UA-3's gate" paragraph becomes the discharges
    and the two filings), the Scoreboard paragraph (A.6).
-   The ledger (A.7): W-354, W-356, W-360, W-361, W-362, W-372, W-394 and
    W-079 (its lane) DISCHARGED with evidence, each by the title prefix
    "(DISCHARGED at UA-3, <date>)" in W-378's form (the schema has no status
    field); W-363 re-noted; W-378, W-069, W-125, W-037, W-355 noted; W-401
    and W-402 filed; the id re-scan repeated first (the 2026-11-23 weekly
    check found W-401 and W-402 reserved by rev 1 and W-403 the next free)
    (amended 2026-11-23, review fold: B-m7 / B-M1).
-   The gap analysis: rows 80, 81 and 45 re-cited (A.12), the header's first
    sentence at the landing (A.11).
-   The register: rg1-checks.tsv (the seven L rows with their counts MEASURED
    at `<anchor>`, under a "#" line naming UA-3, the cut 7a3608bab and
    `<anchor>`; D-UA3-15), check_greps.sh's default and comment,
    rg1-plan.md's H10.1 ALIGNED, DR-0's (vi) ALIGNED for the lane and the
    match-lane `_`, the D-RG-16 and D-RG-18 notes, the ten watch rows of
    D-UA3-18 as T13.1 to T13.10 with silence checks (each a `git grep -c` of
    the clause's distinctive text over upstream's tree at the tip, expected
    0, 1 or the measured count the row states) and the convergence-candidate
    row for lambda.carbon's split; every text in A.9 and A.12 (amended
    2026-11-23, review fold: B-B1 / B-m3 / A-m1).
-   The six weekly entries' "resolved by UA-3" lines (A.8);
    fork/upstream/plan.md's pointer; the plans' dated lines (§2.16, A.12).
-   The weekly Routine needs no edit (D-UA-13): its next firing measures
    from the new cut; after the landing it reports 0 commits since the cut
    and re-anchors the register at whatever tip it reads.

### §8.4 The landing (LAND-1, D-LAND-6)

The orchestrator opens the PR (A.10) with base trunk; the implementer of the
landing follows D-LAND-6's twelve steps in /home/user/carbon-trunk
(amended 2026-11-23, review fold: B-M2 / B-m6): preconditions — the arbiter
of record /home/user/arb/carbonbuild carries ARB-5 (`grep -c libCIR
gen_ninja.py` non-zero) and `diff -r` against trunk's fork/tools/carbonbuild
is clean or each difference is named in the landing's record (R33 (a)'s
amendment: the record and the running instance synchronised); the land tree
is built, gated and run only by that arbiter, never by a scratch copy. Then:
step 1 the head and base checks; step 2 the dry run of the PR's head onto the
pushed trunk (expected: no conflict beyond the records regions LAND-1's rules
decide, since trunk after cb7821735 moves only by records commits until this
lands); step 3 `git merge --no-ff --no-commit` and the resolutions; step 4
the arbiter at the tip pin (build, install, gate 2115 of 2115, conformance
226/0/15, 51/56); step 5 the merge commit with A.1's message of LAND-1
(A.11); steps 6 and 7 none and no refill expected (the land tree equals the
head's but for records); step 8 conformance on the final tree and ALL FOUR
checker runs at 0 errors — `python3 -I fork/designdocs/check_samples.py`
with and without `--toolchain <the land install>`, `python3 -I
fork/evaluator/check_samples.py` and `fork/evaluator/check_faq.py --which
fork` — plus `runner.py --self-test`; step 9 the records texts (A.11: the
Branches row, the dated paragraph and header, the Landed paragraph in this
plan, the decision-log sentence, the PR description's Landed line, the gap
header's first sentence, the Scoreboard paragraph) with prek, R31's counts,
`json.load`, the model-identifier grep and the gap-row check `python3 -I
$F/bin/rowcheck.py <trunk before> H WORKTREE <rows>` over rows 80, 81 and 45
plus the header (0 missing); step 10 the review; step 11 phase 1, `git push
origin trunk` and `git push origin trunk:claude/carbon-fork-0-1-7mwfb7` (the
mirror; fast-forwards) and `pull_request_read` for `merged: true`,
`merged_at` and `merge_commit_sha`; step 12 phase 2, the two values filled,
prek, the records commit ("records written <date> <hh:mm> UTC, committed
<now> UTC") pushed to trunk and the mirror. After the landing: the arbiter's
old-pin LLVM build is no longer needed for trunk (ARB-4's note), PR 53's
branch takes the new trunk by a merge commit (item 14; R32 (e): a held PR is
amended by a new commit on its branch, never rewritten), and the next weekly
check runs at the new cut and re-anchors the register at its own tip
(W-355).

## Hand-off notes for the implementer

1.  **Setup and the reference.** Work only in /home/user/carbon-ua3 on
    `claude/carbon-fork-0-1-ua3` (HEAD = this plan's commit on 701863aa5).
    Never touch /home/user/carbon-lang's checkout, /home/user/carbon-trunk,
    /home/user/carbon-ua3-proto (read it; the prototype is evidence, not the
    product), or any other worktree. The prototype's artefacts are the
    reference for every resolution: its resolutions.tsv (one row per path),
    resolution-vs-upstream.patch (the fork's delta over 7a3608bab at its
    HEAD, sources only), msg-merge.txt and msg-fix1..5.txt (what each fix
    found), gate-prefill2-failed.txt (449 paths: the 448 files the fill
    rewrites plus basics/dump_prelude.carbon, which failed in that gate and
    passed after the fill untouched — gate-prefill-failed.txt and au1.out are
    the DISCARDED pre-fix-4 run, 454 files and a 41-entry manual-fix list;
    au2.out's lines 8-17 are the ten entries; corrected 2026-11-23, review
    fold: B-m2), fill-paths.txt and pass2-files.txt, all under the scratchpad
    path §0.5 names; and the rev 2 re-measurement's amendments.patch under
    scratchpad/ua3/fixer/ (Appendix C), the reference for §0.4 items 23 and
    24, A-m2's comments and the R-n texts. Do not copy either tree; redo the
    merge from §2 and compare your delta against the patch plus
    amendments.patch (K-1's falsifier). First `git -C /home/user/carbon-lang
    fetch -q upstream trunk` and confirm the tip is STILL 7a3608bab for this
    plan whatever upstream/trunk reads (0072b2812 and moving: merge the sha,
    not the ref); read trunk (`git -C /home/user/carbon-lang log -1
    origin/trunk`; cb7821735 on 2026-11-23) for T — trunk having moved past
    the prototype's a9892d4bb by records and fork/tools commits is the
    expected case (D-UA3-1), and the dry run against it must read the same
    194 paths.
2.  **The arbiter at the tip pin.** Every command in §8.1's command form
    (the checkout variable set to this worktree, the label `ua3-impl`, the
    three LLVM variables of D-UA3-4 at their c744694 values; the arbiter's
    paths.sh comment lists them), every script the arbiter of record's
    (/home/user/arb/carbonbuild; ARB-5 is synced into it since 2026-11-23 —
    confirm `grep -c libCIR gen_ninja.py` is non-zero before the first
    build; the prototype's scratch copy is retired, review fold B-M2). Check
    for a running build first (the `pgrep` of §8.1); wait for it. Read the
    log's gen_ninja line (the pin) and "file_test manifest: 2115 test files"
    before anything else.
3.  **Merge mechanics (FORM).** `git -C /home/user/carbon-ua3 merge --no-ff
    --no-commit 7a3608bab` (expect the 194 conflicts of Appendix B plus the
    §0.3 sources; `git status --porcelain | grep -E '^(UU|UD|DU|AA)'` lists
    them). Goldens: write the theirs list and the ours list to files under
    your scratch, then `git checkout 7a3608bab -- <paths>` and `git checkout
    HEAD -- <paths>` by explicit paths (no `$(...)` around git, no git inside
    a loop body); the hand merge of eval/call.carbon as §2.14. Sources in the
    §1.1 order, by hand (the markers are `<<<<<<< HEAD` fork /
    `>>>>>>> 7a3608bab` upstream); the modify/delete pair by `git rm`. The
    silent sweep (§0.4). prek: `SKIP=fix-cc-deps,check-build-graph,
    check-bazel-mod-deps,forbid-llvm-googletest XDG_CACHE_HOME=<your scratch>/
    xdg uvx prek run --files <every touched non-testdata file>` to a
    fixpoint (delete that cache directory when done); the plist by the
    build-textmate-grammar hook. The §8.2 greps. The build. Then `git add --
    <paths>` by explicit path (never `-A`), the message written with the
    Write tool to a file, `git -c user.name=Claude -c
    user.email=noreply@anthropic.com commit --author='jmann345
    <jerrymannstan@gmail.com>' -F <file>` in its own command. `rm -rf` only
    on literal paths; dates from `date -u`.
4.  **Traps.** (a) `NameId`s are per compilation unit: compare an imported
    IR's names as strings through that IR's identifier store (§0.4 item 20
    (d)); the symptom is the union field rule rejecting `i32`. (b) The
    `where` region: upstream's `DiscardGenericDecl` swallows a template
    action; use the fork's `DiscardGenericDeclIntoEnclosingGeneric` (item 20
    (a)); the symptom is `FATAL custom_witness.cpp: Unexpected type for
    CanDestroyType: SpliceInst` in deduce_class_args.carbon. (c) Upstream's
    `ExportNameScopeToCpp` CHECKs the specific: pass `lookup.specific_id` in
    generate_ast.cpp (item 20 (b)). (d) VA-1's name handler must reach
    upstream's `TryGetLookupResultInCurrentScope` (item 20 (c)); the symptom
    is `CHECK function_context.cpp: Missing value: WrapperBinding` on
    global_runtime.carbon. (e) prek's check-toolchain-diagnostics rejects a
    kind declared twice: the OV-2 check stays inside `CheckRequiredDefinitions`
    under the once-flag. (f) `SelfDestruct` takes a `ref` argument:
    `SelfDestruct(ref (self.value unsafe as T))`. (g) slice.carbon must import
    prelude/types/array or every test fails on `Core.Array`. (h) Never "fix"
    a golden by editing CHECK lines (R16): the 22 non-CHECK edits of §2.13
    and the eval/call.carbon split are the only hand edits under testdata.
    (i) R17: a resolution needing a paragraph is a class-C deletion with a
    residue, not a clever merge. (j) The gate before the fill counts the
    fill's files as failures; a CRASH line (`Stack dump`, `CHECK failure`,
    `CARBON_FATAL`) is the defect signal, not the count. (k) A union is a
    `ClassType`: every class-body feature upstream adds reaches
    handle_union.cpp's scope, and a stack the class handlers push must be
    pushed there too (`friend_scopes_stack`, §0.4 item 23; the sweep of §8.1
    step 9). (l) The `_` discard is the refutable contexts' only: the
    `PatternListUnderscoreField` handler returns upstream's TODO when the
    full pattern's kind is not `MatchCaseArm` (item 24); a golden printing
    ``no field named `b` `` for a `_` is the dead-discard symptom. (m) A new
    fork golden needs its INCLUDE-FILE's types only (`u8` needs
    `Core.UInt`, absent from min_prelude/int.carbon: the re-measurement's one
    manual-fix entry). (added 2026-11-23, review fold: A-M1 / A-M2)
5.  **The reviews and the fix budget.** After F and R-1 to R-5 (and C-2, P),
    hand the orchestrator: the branch's commits, the measured lines of §8.1
    verbatim with the script that produced each, the `diff` of your delta
    against the prototype's patch plus amendments.patch over the 73 sources
    and handle_union.cpp, the manual-fix list, the 22 upstream-only goldens'
    list compared with §4's, the union-body sweep's outputs, and the
    register scripts' lines at `<anchor>`. Fix rounds: at most three, each a
    commit with its fill (autoupdate to the fixpoint) and gate.
6.  **What this plan could not measure, and why.** (1) The product's own
    build: the prototype was built from the audits' resolutions, the product
    is redone by hand (K-1). (2) Rev 1's item, D-UA3-7's deletion of the
    stringify cases, is withdrawn: the cases are kept and M4 measures what
    deleting them does (A-M3). (3) C-2 and P: predicted; the checkers' 0
    errors is the falsifier. (4) M2 and M3: predicted mutants (M1, M2b and
    M4 measured). (5) The landing's dry run against a moved trunk: trunk is
    cb7821735 now and moves weekly by records commits; T takes the trunk of
    the day (D-UA3-1; the 194-path set re-verified at cb7821735). (6)
    Upstream's own behavior at 7a3608bab for item 10: no upstream toolchain
    at the tip exists in the container; §0.4 item 22's reasoning is from
    upstream's custom_witness.cpp (`TryToCompleteType` at :315, returning
    `NoDestroy` for any incomplete type, review A's reading) and the
    prototype's probe. (7) The hosted gate and clang-tidy (not available).
    (8) The product's register step: `<anchor>` is read at D time; the
    counts this plan quotes are 2026-11-23's at 0072b2812 (D-UA3-15).
    Everything else is measured (amended 2026-11-23, review fold: A-M3 /
    B-B1 / B-M2).

## Appendix A: the texts, verbatim, with `<...>` placeholders

The fields: `<date>` from `date -u +%F`; `<sha>`s from `git rev-parse
--short`; the measured lines copied from the arbiter's logs; `<N>` the PR
number the orchestrator assigns.

### A.1 T, the base merge

<!-- google-doc-style-ignore -->

```text
UA-3 (T): merge trunk a9892d4bb into claude/carbon-fork-0-1-ua3 before M

Trunk a9892d4bb holds TP-2's landing (PR 71, W-374 discharged: trunk's
IsCallPerformable is upstream's) and its records. The branch holds only
fork/upstream/ua3-plan.md, so nothing conflicts; M's base is this trunk,
as the prototype's was (fork/upstream/ua3-plan.md D-UA3-1).

<trailers>
```

<!-- google-doc-style-resume -->

### A.2 M, the merge commit

<!-- google-doc-style-ignore -->

```text
Merge upstream trunk 7a3608bab into the fork (197 commits since c1e83b0b7)

UA-3 commit M (fork/upstream/ua3-plan.md rev <n>, §3): every textual and
semantic resolution of §2. The dry run's <194> conflicting paths against
trunk <T's trunk sha> reproduced exactly (73 sources and records, <121>
goldens); <none> not in the dry run.

Class A (keep both), 34 files: check BUILD, class.h, context.{h,cpp},
core_identifier.def, cpp/import.cpp, deduce.cpp, full_pattern_stack.h,
handle_binding_pattern.cpp, member_access.cpp, name_lookup.h,
node_stack.h, pending_block.h; driver/compile_options.cpp;
lower/function_context.{h,cpp}, lower/type.cpp; parse/context.cpp,
handle_decl_scope_loop.cpp, handle_statement.cpp, node_ids.h,
node_kind.def, state.def, typed_nodes.h; sem_ir/core_interface_kind.def,
file.cpp, function.h, inst_kind.def, inst_namer.cpp, mangler.cpp,
stringify.cpp (TP-1's two AddrOfAction cases kept, D-TP-23), type_info.cpp,
type_iterator.cpp; docs/design/control_flow/loops.md.

Class B (upstream's structure, the fork mechanism re-expressed), 33 files:
action.cpp, call.cpp, check_unit.cpp (OV-2's check once under a flag),
convert.cpp (W-258: TP-1's cloned storage chain in
storage_access_block_id), cpp/export.cpp (D-ST-12 in the moved
ExportClassToCpp), cpp/thunk.cpp (CppCalleeFunctionInfo; the fence's
three components), eval_inst.cpp, full_pattern_stack.cpp, generic.cpp
(DefinitionResolution with VA-2's pack-iteration eval), handle_choice.cpp
(AliasBinding alternatives), handle_class.cpp, handle_function.cpp with
function.cpp (W-362 carried into CheckDefaults), handle_index.cpp
(TryGetAsArrayType inside TP-1's PerformIndex), handle_pack_expansion.cpp,
handle_pattern_list.cpp (W-372: upstream's layer; the `_` discard on
PatternListUnderscoreField for the refutable contexts, upstream's TODO in
every other lane), impl.cpp, impl_lookup.cpp, import_ref.cpp
(.is_choice and .is_union in the moved initializer), inst.cpp, merge.cpp,
pattern_match.cpp, return.cpp, type_completion.cpp, diagnostics/kind.def,
lower/aggregate.cpp, lower/handle.cpp (EH-A's D10 epilogue in the
EntryPointInt32 arm), parse/handle_match.cpp, sem_ir/expr_info.cpp,
sem_ir/identified_facet_type.{h,cpp} (deleted; SC-1's
StructuralRequirement ported into check/identified_facet_type.{h,cpp}),
sem_ir/typed_insts.h, the two TextMate grammars.

Class C (upstream's; the fork's mechanism retired, its goldens and
programs kept as pins), 5 files: custom_witness.cpp (W-354, upstream
05a7ecbd3: the SubobjectDestroy witness; D-SL-16's yield and D-SL-19's
keying dropped, the predicates on Core.DestroyImpl by identifier string
across IRs), handle_operator.cpp with pointer_dereference.{h,cpp} (W-394,
dbf02ad10: upstream's AddrOfAction; TP-1's PerformAddrOf deleted, its two
stringify cases kept under D-TP-23), lower/file_context.{h,cpp} and
sem_ir/mangler.h (W-069 lane a1 superseded by d50576ca1's GlobalRef
lowering, PR 8061).

Class X: .github/workflows/check_dependent_pr.yaml takes upstream's file
(its repository guard is lost; W-402).

Goldens: <107> take upstream's source, <13> keep the fork's,
eval/call.carbon is hand-merged (upstream's file plus the fork's appended
split); check/testdata/union/friend.carbon added (source only; the pin of
the union friend-scope fix below); 21 fork goldens and programs and the
prelude's three declared destructors re-spelled `impl as Core.DestroyImpl`
and optional.carbon's SelfDestruct call (05a7ecbd3);
mixed_constant_init.carbon's INCLUDE-FILE to min_prelude/array.carbon
(947c1eb52); slice.carbon imports prelude/types/array. CHECK lines are the
fill commit's (R16).

Silent fixes: Note/Context diagnostics converted to LABEL/CONTEXT +
Attach in <11> files and kind.def reduced to upstream's model plus the
fork's Error/Warning kinds; GenericClassType and CalleeFunctionInfo
renames; OperandDependence on context.sem_ir() at <nine> sites;
TryToIdentifyFacetType on TypeId; LocalPatternMatch's loc_id;
FindStorageArgForInitializerInSpecific callers; the `where` region
discarded into the enclosing generic; generate_ast passes the specific;
VA-1's pack-name check inside HandleNameAsExpr; handle_union.cpp pushes
and pops friend_scopes_stack as handle_class.cpp does (5fed32a9a's friend
handler reaches a union body: a crash without it); the `_` handler returns
upstream's TODO outside the refutable contexts; comments naming the
retired destroy builders and the WrapperBinding alternative re-worded;
W-378's in-place UnitAndImports construction kept.

Container-measured on this tree at the tip LLVM pin by
/home/user/arb/carbonbuild's scripts (ARB-4 and ARB-5; build.sh,
install.py, gate.sh): build ok (<the === build.sh done line>; manifest
2115); gate <g0> passed, <g1> failed before the fill, no crash line;
source patch `landed`. prek clean on the resolved files
(SKIP=fix-cc-deps,check-build-graph,check-bazel-mod-deps,
forbid-llvm-googletest).

<trailers>
```

<!-- google-doc-style-resume -->

### A.3 F, the fill

<!-- google-doc-style-ignore -->

```text
UA-3 (F): refill the goldens on the merge (autoupdate)

Autoupdate (carbonbuild autoupdate.sh at the tip LLVM pin, R16) to its
fixpoint on the merge commit <M sha>: pass 1 <n1> files, pass 2 <n2>
(location-only), pass 3 0. CHECK lines only (every changed file's
non-CHECK lines identical before and after: 0 of <n1> differ). Gate after:
<g> passed, <f> failed: the <six> files whose `fail_` pins upstream's
window made succeed or fail, retriaged by R-1 to R-5.

Manual-fix list: <the ten entries verbatim>.

<trailers>
```

<!-- google-doc-style-resume -->

### A.4 R-n, C-2 and P

<!-- google-doc-style-ignore -->

```text
UA-3 (R-<n>): <item>: <split or file> renamed to <...>

<Why it flips: the upstream commit and the mechanism, one paragraph; for
R-1 and R-2 the selection-change record of D-UA3-9; for R-3 the rename of
let/fail_todo_struct_pattern.carbon to let/struct_pattern.carbon, its four
splits' prefix dropped, the new fail_todo_underscore_param split and the
header (W-372, W-079; nothing deleted); for R-4 TP-1's CallAction
performing f(42) in the specific, where upstream 7a3608bab still rejects
the split (a convergence candidate); for R-5 the W-401 diagnostic and the
out-of-line workaround.> No CHECK line is written by hand<; autoupdate's
refill after the rename: <files or none>>. Gate after: <g> passed, <f>
failed.

<trailers>
```

```text
UA-3 (C-2): the two sample checkers read the rendered diagnostic form

Upstream 2c9739799 and d0badecd2 render a diagnostic's message wrapped
under its snippet; fork/designdocs/check_samples.py and
fork/evaluator/check_faq.py compared the first error line's text and
reported <15> and <2> errors on the merged install. Both now join the
wrapped message lines of one diagnostic before matching, with one
rendered self-check case each. Errors after: 0 and 0 (X11 by P).

<trailers>
```

```text
UA-3 (P): templates.md's dependent-bound bullet re-pinned (947c1eb52)

docs/design/templates.md:590-596 pinned `cannot initialize array with
dependent bound from a list of initializers`; upstream 947c1eb52's
Core.Array accepts the bound, so the bullet gains a dated note and
check_samples.py's X11 expectation becomes "compiles" (DD-1's rule: the
page and the checker move together). R31 counts unchanged but for the
note's lines.

<trailers>
```

<!-- google-doc-style-resume -->

### A.5 The decision-log entry (placed directly above "Upstream reconciliation 2026-10 (UA-2)")

<!-- google-doc-style-ignore -->

```markdown
### Upstream advance 2026-11: cut c1e83b0b7 → 7a3608bab (<date>)

The fork's upstream cut advances from c1e83b0b78b6bf648661f4c448c01f11d74af115
(2026-10-05, "Use the plain identifier for Carbon names in C++", PR 7897,
UA-1's tip, the cut the six weekly entries below held) to upstream trunk
7a3608bab265e5716f174487ef7b18c134d728d2 (2026-11-14, "Bump addressable
from 2.9.0 to 2.9.1 in /website in the bundler group across 1 directory",
PR 8132), in ONE staged merge PR per fork/upstream/ua3-plan.md rev <n>
(F-002's flow, built and measured by the container arbiter before it lands;
D-UA3-1). Landed on claude/carbon-fork-0-1-ua3, cut from trunk 701863aa5 and
merged with trunk a9892d4bb (PR 71, TP-2) before the merge: <P0 sha> the
plan; <T sha> the base merge; <M sha> the merge commit (§3 M: every
resolution of §2, the prototype's five compile and gate fixes folded in);
<F sha> the fill; <R-1..R-5 shas> the retirements' separable halves; <C-2
sha>, <P sha>; <fix shas>; <D sha> the records. §0.1 numbers, as measured
and as they reproduced at the merge: 197 upstream commits since the cut
(36, 85, 117, 150, 176 and 197 at the six weekly tips); 2140 upstream files
changed (1451 goldens); 1251 fork files changed since the cut (399 fork
commits at 701863aa5); 196 dry-run conflicts at 701863aa5 (73 sources and
records, 123 goldens; tree 13718d872), 194 at a9892d4bb (TP-2's refill
cleared two; the same 194 at <T's trunk sha>); 11 upstream deletions, 0
renames; the test manifest 2047 → 2115 (upstream's 67 net, plus the fork's
union/friend.carbon; R-3 renames and deletes nothing). Design authority not
reopened: F-002, standing rules 5 and 7,
R16, R17, R26, R28, R30, R32, R33; every D-UA3 decision is an R29 (a)
implementation choice recorded for after-the-fact veto.

CONFLICT CLASSIFICATION AS LANDED (§0.3 classes; the upstream commit that
forced each class-B re-expression or class-C deletion). Class A, keep both
(34 files): <the list of A.2>. Class B, upstream's structure with the fork
mechanism re-expressed (33 files): <each file with its decision and
upstream commit, from A.2 and §2>. Class C, upstream's mechanism with the
fork goldens and programs kept as pins (5 files): D-UA3-5 custom_witness.cpp
against 05a7ecbd3 (W-354: the fork's three-entry Destroy witness builders
and the CoreInterface::Destroy case deleted; D-SL-16's declared-impl yield
and D-SL-19's class keying dropped, SL-1's register break condition having
fired; HasUserDestroyImpl, HasClassKeyedImpl, IsTriviallyDestructible and
HasNonTrivialUserCopyImpl keyed on Core.DestroyImpl by identifier string
through each IR's own store; the prelude's three declared destructors and
optional.carbon's SelfDestruct call on upstream's spellings; 21 goldens and
programs re-spelled); D-UA3-7 handle_operator.cpp with
pointer_dereference.{h,cpp} against dbf02ad10 (W-394: upstream's
AddrOfAction, TP-1's PerformAddrOf deleted; D-TP-23's two stringify cases
kept under watch row T13.9, since upstream renders no action); D-UA3-8
lower/file_context.{h,cpp} and sem_ir/mangler.h against d50576ca1 and
19f1bf94d (W-069 lane a1 superseded by GlobalRef, PR 8061: nine fork sites
retired, the pins refilled). Class X: .github/workflows/
check_dependent_pr.yaml takes upstream's whole file (b7ea32c3a); the fork's
repository guard in it is lost (W-402). Goldens (D-UA3-3): 107 took
upstream's source, 13 the fork's, eval/call.carbon hand-merged, one fork
golden added (union/friend.carbon, the pin of the union friend-scope fix),
CHECK lines by the fill only (the fill's non-CHECK diff empty: 0 of <n1>
files differ). The silent class (§0.4): <the 24 items by one clause each;
items 23 (friend in a union body crashed: the union handlers now collect
friend scopes as the class handlers do) and 24 (the `_` discard was dead
outside the match lane: upstream's TODO kept there) were review A's
findings on rev 1, measured on the prototype's install>. Deviations from
the plan as written: <each, or none>.

FILL STATISTICS (container autoupdate at the tip LLVM pin, files per pass):
pass 1 <n1> (<fork-added> fork-added goldens, <fork-modified> fork-modified,
<upstream-only> upstream-only, each of the last explained in the plan's §4);
pass 2 <n2>, location-only; pass 3 0. Manual-fix list: <the ten entries>,
retriaged by R-1 to R-5. Gate: <g0>/<g1> before the fill, <g2>/<g3> after,
<g4> of <g4> after R-5. Fix rounds after the reviews: <n or none>.

SCOREBOARD AT FIXPOINT. Container-measured (R33 (b)) on <final sha>:
<p> PASS / <f> FAIL / <s> SKIP over 241 programs, <b>/56 bullets (the bar,
trunk a9892d4bb's 226/0/15 and 51/56; no program changed status; the five
re-spelled programs' EXPECT lines unchanged; W-354's string.carbon:154 site
compiled by every program).

DIVERGENCE-RISK REGISTER REVIEW (W-355's method; the register's anchor is
the latest weekly check's tip, <anchor> = <sha> from the entry of <weekly
date>, <k> commits past the cut 7a3608bab): check_quotes at <anchor>
"checked 294 quotes, 0 failed"; check_greps at <anchor> "checked 96 silence
checks, 0 failed" with the new default cut 7a3608bab, the seven L rows
(H4.5, H8.5, H8.7, H10.4, H10.8, H11.4, H11.10) carrying the MEASURED counts
`git log 7a3608bab..<anchor>` gives over their paths (<the seven counts>;
0072b2812's were 1, 0, 0, 0, 1, 0, 1 on 2026-11-23); H10.1 (AddrOfAction)
DRIFT → ALIGNED (W-394 discharged; D-TP-23's two stringify cases a watch,
T13.9); DR-0's entry (vi) DRIFT → ALIGNED for upstream's lane and the
match-lane `_` (W-372 discharged; the non-match `_` is W-079's residue,
upstream's TODO); D-RG-16's block notes W-354's discharge; D-RG-18 (W-356)
discharged by the probe's run; every other NONE and ALIGNED entry HOLDS;
UA-1's T12 watch rows still 0 at the tip; ten new watch rows T13.1 to
T13.10 for the clauses this merge adds inside or beside upstream functions
(has_trailing_discard, the PatternListUnderscoreField discard,
overload_set_definitions_checked_, IsCoreDestroyImplInFile, the
EntryPointInt32 epilogue, the `where` region's discard, PendingBlock's
`auto insts() const`, upstream's underscore TODO, AddrOfAction in
upstream's stringify.cpp, friend_scopes_stack in handle_class.cpp) and one
convergence-candidate row (lambda.carbon's
fail_todo_as_non_constant_template_argument: upstream still rejects it, the
fork's TP-1 passes it). V-3a convergences recorded: lower/var/import.carbon's
`fn X` (W-069's hand-merge is upstream's text), the for/*,
indirect_index_with and parse variadics goldens (byte-identical sources).

RESIDUES FILED. W-401: OP-2 item 10 (D-FO1-1) re-opened for the
SubobjectDestroy half of Core.Destroy (05a7ecbd3): `fn Next(self) ->
Core.Optional(Self)` inside a class with its own Copy and DestroyImpl impls
is `cannot convert type `Self` into type implementing
`Core.OptionalStorage``; pins the two fail_todo_ splits; the out-of-line
form checks. W-402: the dependency-check workflow runs unguarded on the
fork when Actions returns (the owner's call). W-079: its let/var/parameter
lane discharged by upstream's layer; its `_` clause (the discard outside
the refutable contexts) stays open as the residue, pinned by
let/struct_pattern.carbon's fail_todo_underscore_param and upstream's
fail_todo_underscore. W-363 stays open (tip call.cpp:73). The K-11 class
produced no new item: interop/cpp/impls/destroy.carbon's fail_no_destroy
changed its diagnostic for a recorded reason (patterns/struct.carbon's
fail_todo_underscore keeps upstream's TODO).

REVIEW FOLD. Plan: <the reviews of rev 1 and their folds>. Implementation:
<the two reviews and their folds>. Fill-caught misses (R28 (d)): <each fix
round's root cause and why review did not see it, or none>.

_V-3a divergence-risk register entries (reviewed at each upstream merge):_
this entry retires three fork mechanisms (W-354's yield and keying, W-394's
PerformAddrOf, W-069's lane a1), renames one golden (W-372's let pin, kept
as the pin of two shapes upstream does not cover), re-expresses the rest on
upstream's structures (D-UA3-12), and adds the T13 watch rows and one
convergence-candidate row. Veto-able.
```

<!-- google-doc-style-resume -->

### A.6 ORCHESTRATION

<!-- google-doc-style-ignore -->

```text
[header, the new first clause before the current "Last updated:" text]
Last updated: <date> (UA-3 LANDED: the upstream cut advanced from c1e83b0b7
to 7a3608bab by PR <N>'s merge <L sha> under R33 and LAND-1; W-354, W-356,
W-360 to W-362, W-372 and W-394 discharged, W-401 and W-402 filed; <landed>
PRs landed, 1 held; see the paragraph dated <date> (<hh:mm> UTC) below; the
earlier <prev> text follows).

[the dated paragraph, directly before the last dated paragraph]
<date> (<hh:mm> UTC): PR <N> (UA-3, the upstream advance to 7a3608bab)
LANDED on trunk by merge <L sha> under R33 (fork/upstream/ua3-plan.md §8.4
and LAND-1's D-LAND-6), GitHub merged_at <merged_at>; the cut is 7a3608bab
(197 commits taken; the next weekly check measures from it and re-anchors
the register at the tip it reads); container-measured at the tip LLVM pin
(R33 (b)): gate <g> of <g>, conformance <p>/<f>/<s> over 241, <b>/56
bullets, gap tally <tally>; id re-scans: <rescan>; <landed> PRs landed,
<held> held. Next: PR 53's branch takes this trunk by a merge commit (item
14, W-395; R32 (e)); the next weekly check at the new cut; ARB-4's old-pin
LLVM build no longer needed for trunk.

[the Branches row, replacing none (a new row before `trunk`'s)]
| `claude/carbon-fork-0-1-ua3` | LANDED as PR <N> by merge <L sha> (<date>, LAND-1, R33; GitHub merged_at <merged_at>, merge_commit_sha <api sha>) — UA-3: the upstream advance c1e83b0b7 → 7a3608bab (197 commits; 194 conflicts resolved, 34 A / 33 B / 5 C / 1 X and 121 goldens); W-354, W-356, W-360, W-361, W-362, W-372, W-394 discharged, W-401 and W-402 filed; land-time commits <land-time shas>; container-measured (R33 (b)): gate <g> of <g>, conformance <p>/<f>/<s> over 241, <b>/56 bullets; moved to follow-ons: W-401 to the next optional/destroy workstream, W-402 to the owner; R21's hosted gate owed when Actions returns (R33 (b)). |

[Next actions item 6: the paragraph beginning "In UA-3's gate, because they
need the advance:" is replaced by]
UA-3 (the upstream advance to 7a3608bab) landed on trunk <date> as PR <N>
by merge <L sha> (LAND-1): W-354 (D-SL-16's yield and D-SL-19's keying
dropped for upstream's SelfDestruct; the predicates on DestroyImpl), W-356
(the probe diagnoses cleanly), W-360 and W-361 (503f09037's and 9799a2326's
defaults; the selection changes recorded in D-UA3-9), W-362 (carried into
function.cpp), W-372 (upstream's struct-pattern layer; the `_` discard on
PatternListUnderscoreField for the match lane, upstream's TODO elsewhere;
let/fail_todo_struct_pattern.carbon renamed let/struct_pattern.carbon) and
W-394 (upstream's AddrOfAction; D-TP-23's rendering kept) are discharged,
and W-079's let/var/parameter lane with them (its `_` clause the residue);
W-363 stays open (tip call.cpp:73); W-069's lane a1 is superseded by
upstream's GlobalRef (d50576ca1); W-378's fix is kept (upstream did not fix
it); W-401 (OP-2 item 10's SubobjectDestroy half) and W-402 (the
dependency-check guard) are filed. The audit tasks of this item (57bf903ef,
4abb6100e, c7de72757 and 9799a2326, 05a7ecbd3's string.carbon:154,
4286832b4, c0b2cc592, 54728e47f, e67b6db91, 30318f87f, b7ea32c3a,
92534a0e0) are answered in the plan's §0.2 table. The cut is 7a3608bab;
check_greps.sh's default cut is 7a3608bab and the register's anchor is the
latest weekly check's tip (W-355).

[the Scoreboard paragraph, in A.9's form of LAND-1]
Container-measured at PR <N>'s landing (<date>, LAND-1, R33 (b)): <p> PASS
/ <s> SKIP / <f> FAIL programs (241 total); **<b>/56 bullets green**; gate
<g> of <g>. R21's hosted run is owed when Actions returns; the paragraph
below is the hosted history; the last hosted scoreboard is
fork/conformance/out/scoreboard.json's (D-LAND-17).
```

<!-- google-doc-style-resume -->

### A.7 The ledger notes (appended to each item's `notes`; the title prefix where named)

fork/inventory/work-items.json has no status field (its keys: id, kind,
title, subsystem, size, bullet, evidence, blocked_by, notes), so a
discharge is recorded as W-378's is: the item's `title` gains the prefix
`UA-3 (DISCHARGED at UA-3, <date>):` (for W-362 `UA-3 (DISCHARGED on the
fork at UA-3, <date>; owed upstream):`), and the note below is appended to
`notes`; rev 1's "(status DISCHARGED)" words are written nowhere
(corrected 2026-11-23, review fold: B-m7).

<!-- google-doc-style-ignore -->

```text
W-354 (title prefix "UA-3 (DISCHARGED at UA-3, <date>): "): Discharged <date> by UA-3 (fork/upstream/ua3-plan.md D-UA3-5): at the merge of upstream 7a3608bab (05a7ecbd3) the fork's three-entry Destroy witness builders and the CoreInterface::Destroy case were deleted, D-SL-16's declared-impl yield dropped from CanDestroyClass and CanDestroyType and D-SL-19's class keying dropped; HasUserDestroyImpl, HasClassKeyedImpl, IsTriviallyDestructible and HasNonTrivialUserCopyImpl key on a user `impl as DestroyImpl` whose Op is not the blanket no_op, by identifier string through each IR's own store (a NameId is per unit; the first keying covered Int(N), UInt(N) and Array(T, N) through unrelated prelude impls and failed 27 union and export splits); the prelude's buf.carbon, string.carbon:154 (D-RG-16's site) and optional.carbon declare DestroyImpl and optional.carbon calls SelfDestruct(ref ...); 16 goldens and 5 programs re-spelled; lower/slice/buf.carbon shows exactly three `free` before and after (D-UA3-5's pin); the union and export-triviality goldens refilled with no new STDERR; conformance <p>/<f>/<s> unchanged. Recorded in SL-1's records by the UA-3 decision-log entry. Break condition unchanged (upstream reverts 05a7ecbd3 or SelfDestruct stops calling DestroyImpl.Op).

W-356 (title prefix "UA-3 (DISCHARGED at UA-3, <date>): "): Discharged <date> by UA-3 (D-UA3-15): refget.carbon on the merged install (/home/user/arb/install/<label>) exits 1 with "error: value expression passed to reference parameter" for both operands and no CHECK failure; inplace.carbon and valget.carbon exit 0 (valget's `-> val T` is upstream's since 1c69fe344). The same probe on tp2-base's install (trunk before the advance) also exits 1 without the CHECK, so the crash RG-1 found on 0bdce60a5 and PR 57's install was already gone on trunk a9892d4bb; recorded, not attributed to the advance.

W-360 (title prefix "UA-3 (DISCHARGED at UA-3, <date>): "): Discharged <date> by UA-3 (D-UA3-9): upstream 503f09037's default-appending in DeduceGenericCallArguments merged clean beside OV-2's `diagnose` flag; fail_todo_generic_member_default passed on the fill and was renamed generic_member_default (R-1, <sha>); the selection change (F(true) moves from F(b: bool) to the generic member) was recorded in the plan (D-UA3-9) before the golden moved.

W-361 (title prefix "UA-3 (DISCHARGED at UA-3, <date>): "): Discharged <date> by UA-3 (D-UA3-9, R30 (c)): with 9799a2326, c7de72757 and 8fdc8ebc3 each exported member's C++ declaration carries its defaults; overload_set_default.carbon's fail_cpp_omitted passed (Carbon::F(1) selects F(i32, i32 = 2)) and was renamed cpp_omitted (R-2, <sha>); divergence_omitted's two sides re-read on the fill; the per-member export still carries _CF__carbon_thunk:overload<N>; the change recorded in the plan before the golden moved.

W-362 (title prefix "UA-3 (DISCHARGED on the fork at UA-3, <date>; owed upstream): "): <date>, UA-3 (D-UA3-9): the trailing-default count carried into toolchain/check/function.cpp's CheckDefaults (1b0a5709e moved it; tip :816 still returns the full count after diagnosing); the pin fail_default_not_trailing passes; both crash sites (pattern_match.cpp's CHECKs) still present at 7a3608bab, still owed upstream.

W-363: <date>, UA-3: upstream 7a3608bab's call.cpp:73 still has the CHECK and function.cpp:35-37 the error recovery; the advance takes no fix; stays open, owed upstream.

W-372 (title prefix "UA-3 (DISCHARGED at UA-3, <date>): "): Discharged <date> by UA-3 (D-UA3-6): upstream's struct-pattern check layer (c6b54b57e, 5ae3dcaa9, d50576ca1) taken whole in handle_pattern_list.cpp; the fork's `_` discard re-expressed on PatternListUnderscoreField for the refutable contexts (FullPatternStack::Kind::MatchCaseArm: the handler records the node, the StructPattern end handler reads it into has_trailing_discard, kept on upstream's SemIR::StructPattern marked Fork, and the match pre-work walks the scrutinee's type); outside them the handler returns upstream's TODO `Struct pattern underscore field`, because upstream's conversion-first lane reads no discard (W-079's residue); the match-only gate, struct_pattern_names_stack and the StructPatternNameDuplicate/Previous pair retired; check/testdata/let/fail_todo_struct_pattern.carbon renamed let/struct_pattern.carbon with its four splits' fail_todo_ dropped and a fail_todo_underscore_param split added (R-3, <sha>; the parameter and let-in-match-arm-body shapes are pinned nowhere upstream). Register entry (vi) of DR-0's block ALIGNED for the lane and the match-lane `_`.

W-079 (title prefix "UA-3 (DISCHARGED at UA-3 for the let/var/parameter lane, <date>; the `_` clause open): "): <date>, UA-3 (D-UA3-6): upstream's layer (c6b54b57e, d50576ca1) checks `let`, `var`, parameter and class-scope struct patterns by converting the initializer to the pattern's own struct type; the four W-077 pins pass and are let/struct_pattern.carbon's `let`, `var`, `param` and `let_in_match_arm_body` splits. The `_` field outside the refutable contexts stays this item's residue: upstream's TODO (handle_pattern_list.cpp's PatternListUnderscoreField handler at the tip, kept by the fork's lane gate), pinned by let/struct_pattern.carbon's fail_todo_underscore_param and upstream's patterns/struct.carbon fail_todo_underscore; the conversion-or-walk question the notes record is still the lane's first decision (R17). Watch row T13.8 (the TODO's text at upstream's tip) fires when upstream implements it.

W-394 (title prefix "UA-3 (DISCHARGED at UA-3, <date>): "): Discharged <date> by UA-3 (D-UA3-7): upstream's AddrOfAction inst (ExprCategory::Dependent) and handler taken; TP-1's PerformAddrOf and PerformAction(AddrOfAction) deleted; D-TP-23's two stringify cases for the inst kept, marked Fork (upstream renders no action; generic/template/index.carbon:332 and :337 pin `D(&p.n)` and `D(&p.m)`; watch row T13.9); generic/template/pointer.carbon refilled (one addr_of_action before and after). Register row H10.1 ALIGNED.

W-378: <date>, UA-3 (D-UA3-10): upstream 92534a0e0's check.cpp merged clean; 7a3608bab:431-435 still copies UnitAndImports out of map_range; the in-place construction kept; the arbiter's GATE line read `landed` on the merged tree.

W-069: <date>, UA-3 (D-UA3-8): lane a1 (the file-scope runtime `let` lowering: RegisterGlobalLetBindings, LookupGlobalLetBinding, GetOrCreateGlobalLetVariable, PrepareGlobalLetDefinitions, EmitGlobalLetStores, TryEmitGlobalLetValue, MangleGlobalLetBinding) is superseded by upstream PR 8061 (d50576ca1: GlobalRef, FileContext::GetOrCreateGlobalBinding, Mangler::MangleGlobalBinding, with 19f1bf94d's one GlobalVariable per variable) and retired at the merge; the pins (check and lower let/global_runtime.carbon, lower let/global_runtime_symbols.carbon, global_runtime_specifics.carbon, import_choice.carbon, lower/var/import.carbon's `fn X`, now upstream's own text) refilled; the Custom value repr stays a FATAL TODO upstream, as the fork's Declined.

W-125: <date>, UA-3: the is_choice clause now sits in MakeSubobjectDestroyOpBody's ClassType arm after upstream's array-adapter arm (947c1eb52) and before OP-2's adapter arm; the CustomLayoutType arm unchanged; `is_choice` count 6.

W-037: <date>, UA-3: 1b0a5709e's fn expressions and b766aa4d1's terse bodies arrive with the advance; lambda.carbon's fail_todo_as_non_constant_template_argument passed and was renamed (R-4, <sha>) because TP-1 performs `f(42)` as a CallAction in each specific of PassToTemplate — upstream 7a3608bab still rejects the split ("value of type `<type of function expression>` is not callable"), so the pass is the fork's, recorded as a convergence candidate in the register; the check-side stubs the title lists are otherwise unchanged.

W-355: <date>, UA-3: the cut moved to 7a3608bab; check_greps.sh's default cut is 7a3608bab; the register's anchor stays the latest weekly check's tip (<anchor>, the <weekly date> entry), ahead of the cut, as this item's method says; the seven L rows (H4.5, H8.5, H8.7, H10.4, H10.8, H11.4, H11.10) carry the counts measured as `git log 7a3608bab..<anchor>` over their paths (<the seven counts>); both scripts print 0 failed at <anchor> at the records commit.

W-401 (new; title: "UA-3 residue (D-UA3-13; OP-2 item 10, D-FO1-1 re-opened by upstream 05a7ecbd3): `Core.Optional(Self)` or `Core.Slice(Self)` in a method's signature inside a class with its own `Copy` and `DestroyImpl` impls fails to form -- `Core.Destroy` is `SubobjectDestroy & DestroyImpl` and the `SubobjectDestroy` half is a synthesized witness that needs the complete class"): evidence the two fail_todo_ splits (named_constraint/template_constraint.carbon fail_todo_self_facet_in_signature_required, optional/destroy.carbon fail_todo_incomplete_self_signature), the diagnostic `cannot convert type `Self` into type implementing `Core.OptionalStorage``, upstream core/prelude/destroy.carbon's TODO at 7a3608bab ("rename to `Destroy` when `require impls` adds a witness table entry"), fork/followon/fo1-plan.md D-FO1-1; notes: filed <date> by UA-3; the out-of-line form `fn Next(s: S) -> Core.Optional(S)` after the class checks; no conformance program uses the in-class form; owner the next optional or destroy workstream; break condition: upstream lands `require impls` in the witness table, or a one-clause re-expression (an existing deferral path) passes both splits.

W-402 (new; title: "UA-3 residue (D-UA3-16): the fork's repository guard in .github/workflows/check_dependent_pr.yaml was dropped when the advance took upstream's whole file (b7ea32c3a); the PR dependency check would run unguarded on the fork when Actions returns"): evidence the five remaining guards (auto_label_prs, gh_pages_ci, gh_pages_deploy x2, nightly_release), UA-1's §2.8 and §8.4 six-guard rule; notes: filed <date> by UA-3; the fork does not maintain .github, so the decision is the owner's (re-add the guard, or accept the check); owner: the owner; break condition: Actions returns.
```

<!-- google-doc-style-resume -->

### A.8 The weekly entries' notes (one line appended to each of the six)

<!-- google-doc-style-ignore -->

```text
_Resolved by UA-3 (<date>):_ the advance to 7a3608bab landed as PR <N> by merge <L sha> (the entry "Upstream advance 2026-11: cut c1e83b0b7 → 7a3608bab"); this entry's deferred set and conflict list are taken whole, its audit tasks answered in fork/upstream/ua3-plan.md §0.2.
```

<!-- google-doc-style-resume -->

### A.9 The register rows

<!-- google-doc-style-ignore -->

```text
[rg1-checks.tsv: one "#" line above each re-anchored L row; the count is MEASURED at D as `git log --oneline 7a3608bab..<anchor> -- <paths> | wc -l` (D-UA3-15); the values shown are 2026-11-23's at <anchor> = 0072b2812]
# UA-3 (<date>): the cut is 7a3608bab (check_greps.sh's default); the register's anchor is the weekly check of <weekly date>'s tip <anchor>, so this L count is the window 7a3608bab..<anchor> (W-355's method), re-measured by each weekly check.
H4.5	L	-	-	toolchain/check/testdata/interop/cpp/operators/operators.carbon	1
H8.5	L	-	-	toolchain/check/testdata/variadics/pack_expansion.carbon	0
H8.7	L	-	-	toolchain/check/handle_pack_expansion.cpp	0
H10.4	L	-	-	toolchain/lower/handle.cpp	0
H10.8	L	-	-	toolchain/check/call.cpp	1
H11.4	L	-	-	toolchain/check/action.cpp	0
H11.10	L	-	-	toolchain/check/testdata/interop/cpp/template/var_template.carbon toolchain/lower/testdata/interop/cpp/globals.carbon toolchain/check/testdata/interop/cpp/template/generic_call.carbon toolchain/check/testdata/interop/cpp/template/non_type_param.carbon toolchain/check/testdata/interop/cpp/range_for.carbon	1

[new watch rows, after T12.7]
# UA-3 (<date>): fork clauses inside or beside upstream functions added by the advance (fork/upstream/ua3-plan.md D-UA3-18); each expected as written at the tip, re-read by the weekly checks.
T13.1	G	-	has_trailing_discard	toolchain/sem_ir/typed_insts.h toolchain/check/handle_pattern_list.cpp	0
T13.2	G	-	PatternListUnderscoreField	toolchain/check/handle_pattern_list.cpp	<upstream's own count at the tip, measured>
T13.3	G	-	overload_set_definitions_checked_	toolchain/check/check_unit.h	0
T13.4	G	-	IsCoreDestroyImplInFile	toolchain/check/custom_witness.cpp	0
T13.5	G	-	EmitEntryPointResultEpilogue	toolchain/lower/handle.cpp	0
T13.6	G	-	DiscardGenericDeclIntoEnclosingGeneric	toolchain/check/handle_where.cpp	0
T13.7	G	-F	auto insts() const	toolchain/check/pending_block.h	0
# T13.8: upstream's own TODO for the `_` field outside the fork's match lane (W-079's residue); 0 means upstream implemented the discard: take it, retire the fork's lane gate.
T13.8	G	-F	Struct pattern underscore field	toolchain/check/handle_pattern_list.cpp	1
# T13.9: upstream renders no action in stringify.cpp (D-TP-23's two AddrOfAction cases are the fork's); non-zero means upstream stringifies actions: take it (W-394, D-UA3-7).
T13.9	G	-	AddrOfAction	toolchain/sem_ir/stringify.cpp	0
# T13.10: the friend-scope array the class handlers push, append to and pop (5fed32a9a); handle_union.cpp mirrors it (ua3-plan.md §0.4 item 23); a change is re-mirrored.
T13.10	G	-	friend_scopes_stack	toolchain/check/handle_class.cpp	5
# Convergence candidate (UA-3 R-4): upstream's split still fails at the tip; the fork's TP-1 passes it. 0 means upstream made it pass too: the fork's rename is upstream's.
T13.11	G	-F	// --- fail_todo_as_non_constant_template_argument.carbon	toolchain/check/testdata/lambda/lambda.carbon	1

[check_greps.sh]
# <cut-sha> defaults to 7a3608bab, the fork's cut since UA-3 (2026-11); after an advance, pass the advance's base.
repo=$1; tip=$2; tsv=$3; cut=${4:-7a3608bab}; n=0; bad=0
```

<!-- google-doc-style-resume -->

T13.2's expected count is upstream's own use of the node name in that file
(the handler's TODO at the tip), measured at the records commit, so the row
watches a change, not a presence. T13.7's pattern is the fork accessor's
distinctive text with `-F`: rev 1's literal `insts()` reads 2 at the tip
(upstream's `context_->insts().Get...` at pending_block.h:103 and :144), so
the row as rev 1 wrote it would have failed at D (corrected 2026-11-23,
review fold: B-m3). T13.8 to T13.11 added 2026-11-23 (review fold: A-M2 /
A-M3 / A-M1 / A-m1); T13.10's 5 and T13.11's 1 are the tip's counts
measured 2026-11-23 (`git grep -c friend_scopes_stack 7a3608bab --
toolchain/check/handle_class.cpp` → 5; the split header once). The L rows'
seven counts are 2026-11-23's at 0072b2812 and are re-measured at D.

### A.10 The PR text

Title: `UA-3: upstream advance c1e83b0b7 → 7a3608bab (197 commits; W-354,
W-372, W-394)`. Base: trunk. Body:

<!-- google-doc-style-ignore -->

```markdown
The fork's third upstream advance (ORCHESTRATION item 6; F-002's staging
merge, built and measured by the container arbiter at the tip's LLVM pin
before it lands): upstream trunk 7a3608bab (2026-11-14, PR 8132), 197
commits past the cut c1e83b0b7, merged into trunk a9892d4bb in one merge
commit resolving 194 conflicting paths (73 sources and records: 34 kept
both sides, 33 re-expressed the fork's mechanism inside upstream's
refactor, 5 took upstream's mechanism and retired the fork's, 1 took
upstream's workflow file; 121 goldens: 107 upstream's source, 13 the
fork's, 1 hand-merged; CHECK lines by autoupdate only). Retired for
upstream's: the fork's three-entry `Destroy` witness and D-SL-16's
declared-impl yield (W-354, upstream 05a7ecbd3: `SelfDestruct` calls the
declared `DestroyImpl.Op`), TP-1's `AddrOfAction` (W-394, dbf02ad10), the
file-scope runtime `let` lowering of W-069 (d50576ca1's `GlobalRef`), and
the match-only struct-pattern layer's duplicates (W-372, c6b54b57e:
upstream's layer with the fork's `_` discard on
`PatternListUnderscoreField` for the match lane, upstream's TODO for the
`_` elsewhere; W-079's lane discharged, its `_` clause the residue; TP-1's
rendering of `&` in diagnostics kept, D-TP-23). Taken: the OV-4 residues'
upstream halves
(W-360 by 503f09037, W-361 by 9799a2326; W-362 carried into function.cpp;
W-363 stays open), the diagnostics model (2c9739799: every fork note and
context on `LABEL`/`CONTEXT` + `Attach`), the LLVM roll (a567040d7), and
everything else in the window. One fork mechanism is narrowed and filed:
OP-2 item 10's in-class `Core.Optional(Self)` (W-401, two `fail_todo_`
splits).

Plan: fork/upstream/ua3-plan.md (rev <n>, two adversarial reviews,
<folds>). Commits: <T> base merge of trunk a9892d4bb, <M> merge, <F> fill
(<n1> files, pass 2 <n2>, fixpoint), <R-1..R-5> retriages, <C-2>, <P>,
<fixes>, <D> records. Container-measured at the tip LLVM pin by
/home/user/arb/carbonbuild (ARB-4, ARB-5; R33 (b)): gate <g> of <g> (after
the fill and retriages; <g0>/<g1> before the fill, no crash), conformance
<p>/<f>/<s> over 241, <b>/56 bullets, byte for byte trunk's; register
scripts 294 quotes and 96 silence checks, 0 failed at the register's anchor
<anchor> (the latest weekly check's tip; check_greps.sh's default cut is
now 7a3608bab and the seven L rows carry measured counts); both sample
checkers, the evaluator's and check_faq.py 0 errors; mutants: M1 (the NameId
keying) 27 union/export splits red and M2b (the `_` recorded in every
lane) the false `no field named b` (both measured on the prototype), M4
(the stringify cases deleted) index.carbon's `D(&p.n)` → `<cannot
stringify ...>` (measured on rev 2's re-measurement), <M2, M3>. Records:
W-354, W-356, W-360, W-361, W-362, W-372, W-394 and W-079's lane
DISCHARGED, W-401 and W-402 filed, the decision-log entry "Upstream advance
2026-11", the six weekly entries' notes, register rows measured at the
anchor, H10.1 and DR-0 (vi) ALIGNED, gap rows 45, 80 and 81, ORCHESTRATION.
Not run: clang-tidy (no binary), the hosted gate (Actions disabled, owed),
Bazel, upstream's own toolchain at the tip.

Lands by LAND-1's D-LAND-6 (fork/land/land1-plan.md) when correct (R33);
PR 53's branch takes the new trunk by a merge commit afterwards (W-395;
R32 (e): a held PR is amended by a new commit, never rewritten).

<the harness's two attribution lines for pull-request descriptions>
```

<!-- google-doc-style-resume -->

### A.11 The land-time texts (LAND-1 Appendix A, with `<...>`)

The fields: `<N>` the PR number; `<head>` the branch's head; `<trunk
before>` trunk at the landing; `<merge sha>`, `<merged_at>`, `<api sha>`
from `pull_request_read`; `<g>` the gate (2115 of 2115 expected; rev 1's
2113 corrected 2026-11-23, review fold: A-M4 / B-M1 / A-M1); `<p>/<f>/
<s>` over 241 (226/0/15 expected); `<b>` (51 expected); `<tally>` (37/17/2/0
unless a landing before this one moves it); `<spec>` "fork/upstream/
ua3-plan.md §8.4 and Appendix A.11"; `<land-time shas>` M-L and F-L when
trunk moved, else "none"; `<landed>` the header's count after this landing
(21 when PR 71's is the last before it); `<rescan>` the id re-scan's
sentence (W-401 and W-402 UA-3's, W-381 to W-385 and W-386 to W-393
reserved, no W-4xx above W-402).

<!-- google-doc-style-ignore -->

```text
[A.1 the land merge's message]
Land PR <N>: UA-3: upstream advance c1e83b0b7 → 7a3608bab

Merges claude/carbon-fork-0-1-ua3 at <head> (PR <N>, base trunk) into
trunk <trunk before> under R33, as fork/upstream/ua3-plan.md §8.4 and
Appendix A.11 specify.

Conflicts and rules: <conflicts, expected none outside the records
regions LAND-1's rules decide>.

Container-measured on the merge's tree at the tip LLVM pin (R33 (b)):
build ok; gate <g0> of <gn> before any refill; conformance <p>/<f>/<s>
over 241, bullets <b> of 56. prek clean on the resolved files
(SKIP=fix-cc-deps,check-build-graph,check-bazel-mod-deps,
forbid-llvm-googletest).

<trailers>

[A.2 the refill, only if the gate names a file]
Land PR <N>: goldens refilled after the merge

Autoupdate (carbonbuild autoupdate.sh at the tip LLVM pin, R16) on the
files the merged toolchain changes: <refilled>. CHECK lines only. Gate
after: <g> of <g>.

<trailers>

[A.3 the Branches row]  (A.6's row above, with the land fields filled)

[A.4 the dated paragraph and the header]  (A.6's paragraph and header
clause above)

[A.5 the Landed paragraph, appended to this plan under a heading
"### Landed notes (UA-3, <date>)"]
UA-3 landed on trunk (LAND-1, <date>): merged as PR <N> by <merge sha>
(head <head>, trunk before <trunk before>; GitHub merged_at <merged_at>)
under R33, fork/upstream/ua3-plan.md §8.4 and Appendix A.11; land-time
commits <land-time shas>; container-measured at the tip LLVM pin (R33
(b)): gate <g> of <g>, conformance <p> PASS, <f> FAIL, <s> SKIP over 241,
<b> of 56 bullets; id re-scans: <rescan>; moved to follow-ons: W-401 to
the next optional or destroy workstream, W-402 to the owner.

[A.6 the decision-log sentence, the last paragraph of A.5's entry]
_Landed (<date>, LAND-1, R33):_ merged into trunk as PR <N> by <merge sha>
(GitHub merged_at <merged_at>); container-measured (R33 (b)): gate <g> of
<g>, conformance <p>/<f>/<s> over 241; id re-scans: <rescan>; moved to
follow-ons: W-401, W-402.

[A.7 the PR description's Landed line (the orchestrator's)]
**Landed** on trunk <date> by merge <merge sha> (LAND-1, R33; GitHub
merged_at <merged_at>): container-measured gate <g> of <g>, conformance
<p>/<f>/<s> over 241, <b>/56 bullets; moved to follow-ons: W-401, W-402.
Record: fork/ORCHESTRATION.md's paragraph dated <date> (<hh:mm> UTC).

[A.8 the gap header's first sentence]
**<t1> DONE / <t2> PARTIAL / <t3> MISSING / <t4> DESIGN-ONLY** across 56
milestone bullets (reconciled <date> at PR <N>'s landing, LAND-1, against
that landing's container-measured conformance scoreboard, R33 (b) — <p>
PASS / <f> FAIL / <s> SKIP over 241 programs, <b>/56 bullets PASS — and the
fork/inventory/work-items.json ledger;

[A.9 the Scoreboard paragraph]  (A.6's last block above)
```

<!-- google-doc-style-resume -->

### A.12 The register and plan lines the records commit edits (verbatim; added 2026-11-23, review fold: B-m7 / B-m4 / B-m5 / A-M1)

Each is appended to the named text as one sentence or one dated line, in the
form the file already uses; `<date>` and `<N>` as above.

<!-- google-doc-style-ignore -->

```text
[fork/decision-log.md, DR-0's register block, the end of entry (vi) at :255-258]
Realigned at UA-3 (<date>, PR <N>, fork/upstream/ua3-plan.md D-UA3-6): upstream's struct-pattern layer (c6b54b57e, 5ae3dcaa9, d50576ca1) is the fork's for `let`, `var`, parameters and class scope; the fork's `_` discard is re-expressed on `PatternListUnderscoreField` for the refutable contexts only, and the `_` outside them keeps upstream's TODO (W-079's residue, watch row T13.8). ALIGNED.

[fork/register/rg1-plan.md, the H10.1 row's last cell]
ALIGNED at UA-3 (<date>, PR <N>): upstream's `AddrOfAction` (dbf02ad10) is the fork's; TP-1's `PerformAddrOf` is deleted; D-TP-23's two stringify cases for the inst are kept under watch row T13.9 (W-394 discharged; the other four forms stay NONE at 0).

[fork/register/rg1-plan.md, D-RG-16's block, after "D-SL-19 against 05a7ecbd3, D-RG-16)"]
UA-3 (<date>, PR <N>): the break condition fired at 05a7ecbd3 — `SelfDestruct` calls the declared `DestroyImpl.Op` — so D-SL-16's yield and D-SL-19's class keying are dropped and the fork's declared destructors spell `impl as DestroyImpl` (string.carbon:154 included); W-354 discharged (ua3-plan.md D-UA3-5).

[fork/register/rg1-plan.md, D-RG-18's paragraph, after "filed by R1."]
UA-3 (<date>, PR <N>): W-356 discharged — refget.carbon on the merged install exits 1 with "value expression passed to reference parameter" for both operands and no CHECK failure; tp2-base's install (trunk before the advance) exits 1 the same way, so the stop was already gone on trunk a9892d4bb, not UA-3's fix (ua3-plan.md D-UA3-15).

[fork/gap-analysis.md, row 45 (Type system: C++ interop — bi-directional inheritance, hierarchy roots, abstract/final/virtual mapping), appended inside the evidence cell]
Re-cited at UA-3 (<date>, PR <N>, against upstream 7a3608bab): export/override.carbon's `fail_todo_generic` now pins upstream 2e2125585's narrower TODO `generic class overriding methods from a C++ virtual class` (cpp/generate_ast.cpp:568) in place of class.cpp's `generic class deriving from C++ virtual class`; the base.carbon cites are unchanged.

[fork/slices/plan.md, after the Landed note "Declared `Destroy` impls win destroy lookup (D-SL-16) and `HasUserDestroyImpl` is class-keyed (D-SL-19)"]
_UA-3 (<date>):_ the break condition fired — upstream 05a7ecbd3's `SelfDestruct` calls the declared `DestroyImpl.Op` — so D-SL-16's yield and D-SL-19's class keying are dropped; `HasUserDestroyImpl` keys on a user `impl as Core.DestroyImpl` by identifier string across IRs (fork/upstream/ua3-plan.md D-UA3-5; W-354 discharged); lower/slice/buf.carbon keeps exactly three `free`.

[fork/w077/plan.md, after the `has_trailing_discard` field's paragraph]
_UA-3 (<date>):_ the `_` discard rides on upstream's `PatternListUnderscoreField` node (5ae3dcaa9) for the refutable contexts (`FullPatternStack::Kind::MatchCaseArm`); upstream's `let`/`var` layer (c6b54b57e) is the fork's for the other lanes, where `_` keeps upstream's TODO (W-079's residue); `has_trailing_discard` stays on upstream's `SemIR::StructPattern`, marked Fork (fork/upstream/ua3-plan.md D-UA3-6; W-372 discharged).

[fork/templates/plan.md, after D-TP-23's paragraph]
_UA-3 (<date>):_ `&` defers through upstream's own `AddrOfAction` (dbf02ad10, `ExprCategory::Dependent`); TP-1's `PerformAddrOf` and its `PerformAction(AddrOfAction)` are deleted; this decision's rendering of the action (`&x`, the parenthesization rule) is kept, marked Fork, under register watch row T13.9 (fork/upstream/ua3-plan.md D-UA3-7; W-394 discharged).

[fork/followon/fo1-plan.md, after D-FO1-1's paragraph]
_UA-3 (<date>):_ narrowed to the `DestroyImpl` half of `Core.Destroy` (upstream 05a7ecbd3: `Destroy` is `SubobjectDestroy & DestroyImpl`, and the `SubobjectDestroy` half is a synthesized witness that needs the complete class), so `Core.Optional(Self)` inside the class's definition no longer forms; the two splits are `fail_todo_` and W-401 carries the question (fork/upstream/ua3-plan.md D-UA3-13).

[fork/eh/plan.md, after D10's paragraph]
_UA-3 (<date>):_ the D10 epilogue lives in the `ReturnKind::EntryPointInt32` arm of upstream's `ReturnExpr` handler (lower/handle.cpp; 9fd28f730), before upstream's FATAL; `entry_point_result_type_id` stays beside `return_kind` (fork/upstream/ua3-plan.md D-UA3-12).

[fork/unions/plan.md, after item 9 ("Modifiers on the declaration")]
_UA-3 (<date>):_ `friend` in a union body (upstream 5fed32a9a) follows the class rules; `UnionDefinitionStart` pushes `friend_scopes_stack` and `UnionDefinition` moves it into the class's `friend_scopes`, as the class handlers do (the prototype aborted without it); pinned by check/testdata/union/friend.carbon (fork/upstream/ua3-plan.md §0.4 item 23).
```

<!-- google-doc-style-resume -->

## Appendix B: the 123 conflicting goldens, one row each

The markers are the dry run's at 701863aa5; the side is the SOURCE side
(D-UA3-3): "theirs" is `git checkout 7a3608bab -- <path>`, "ours" is `git
checkout HEAD -- <path>` after the merge starts (the fork's side), "hand"
is §2.14's hand merge; the two rows "clean at a9892d4bb" conflict at
701863aa5 only (TP-2's refill brought them to upstream's text) and need no
command. Every row's CHECK lines are the fill's.

| Golden | Markers | Side |
| --- | --- | --- |
| toolchain/check/testdata/basics/raw_sem_ir/cpp_interop.carbon | 2 | theirs |
| toolchain/check/testdata/builtins/bool/eq.carbon | 3 | theirs |
| toolchain/check/testdata/builtins/bool/neq.carbon | 3 | theirs |
| toolchain/check/testdata/choice/params.carbon | 4 | ours |
| toolchain/check/testdata/class/destroy_calls.carbon | 6 | theirs |
| toolchain/check/testdata/eval/call.carbon | 2 | hand |
| toolchain/check/testdata/eval/symbolic.carbon | 1 | ours |
| toolchain/check/testdata/for/actual.carbon | 24 | theirs |
| toolchain/check/testdata/for/basic.carbon | 3 | theirs |
| toolchain/check/testdata/for/pattern.carbon | 12 | theirs |
| toolchain/check/testdata/function/call/form.carbon | 9 | theirs |
| toolchain/check/testdata/generic/template/call.carbon | 2 | ours |
| toolchain/check/testdata/generic/template/convert.carbon | 12 | clean at a9892d4bb (theirs by TP-2) |
| toolchain/check/testdata/generic/template/member_out_of_line.carbon | 3 | ours |
| toolchain/check/testdata/generic/template/unimplemented.carbon | 10 | ours |
| toolchain/check/testdata/index/fail_invalid_base.carbon | 1 | theirs |
| toolchain/check/testdata/interop/cpp/basics/import/indirect.carbon | 4 | theirs |
| toolchain/check/testdata/interop/cpp/class/import/field.carbon | 1 | theirs |
| toolchain/check/testdata/interop/cpp/class/import/method.carbon | 7 | theirs |
| toolchain/check/testdata/interop/cpp/enum/anonymous.carbon | 2 | theirs |
| toolchain/check/testdata/interop/cpp/function/export/generic.carbon | 7 | theirs |
| toolchain/check/testdata/interop/cpp/function/import/arithmetic_types_bridged.carbon | 2 | theirs |
| toolchain/check/testdata/interop/cpp/function/import/arithmetic_types_direct.carbon | 24 | theirs |
| toolchain/check/testdata/interop/cpp/function/import/class.carbon | 7 | theirs |
| toolchain/check/testdata/interop/cpp/function/import/decayed_param.carbon | 10 | theirs |
| toolchain/check/testdata/interop/cpp/function/import/default_arg.carbon | 6 | theirs |
| toolchain/check/testdata/interop/cpp/function/import/extern_c.carbon | 2 | theirs |
| toolchain/check/testdata/interop/cpp/function/import/full_semir.carbon | 4 | theirs |
| toolchain/check/testdata/interop/cpp/function/import/function.carbon | 5 | theirs |
| toolchain/check/testdata/interop/cpp/function/import/function_ptr.carbon | 15 | theirs |
| toolchain/check/testdata/interop/cpp/function/import/in_template.carbon | 2 | theirs |
| toolchain/check/testdata/interop/cpp/function/import/inline.carbon | 4 | theirs |
| toolchain/check/testdata/interop/cpp/function/import/method_ptr.carbon | 15 | theirs |
| toolchain/check/testdata/interop/cpp/function/import/pointer.carbon | 44 | theirs |
| toolchain/check/testdata/interop/cpp/function/import/qualified_param.carbon | 2 | theirs |
| toolchain/check/testdata/interop/cpp/function/import/reference.carbon | 3 | theirs |
| toolchain/check/testdata/interop/cpp/function/import/return.carbon | 3 | theirs |
| toolchain/check/testdata/interop/cpp/function/import/struct.carbon | 4 | theirs |
| toolchain/check/testdata/interop/cpp/function/import/union.carbon | 2 | theirs |
| toolchain/check/testdata/interop/cpp/function/import/variadic.carbon | 6 | theirs |
| toolchain/check/testdata/interop/cpp/function/import/void_pointer.carbon | 19 | theirs |
| toolchain/check/testdata/interop/cpp/macros/macros.carbon | 4 | theirs |
| toolchain/check/testdata/interop/cpp/operators/arithmetic_operators.carbon | 4 | theirs |
| toolchain/check/testdata/interop/cpp/operators/deref.carbon | 4 | theirs |
| toolchain/check/testdata/interop/cpp/operators/eq_with.carbon | 12 | theirs |
| toolchain/check/testdata/interop/cpp/operators/operators.carbon | 7 | theirs |
| toolchain/check/testdata/interop/cpp/operators/ordered_with.carbon | 16 | theirs |
| toolchain/check/testdata/interop/cpp/operators/spaceship.carbon | 7 | theirs |
| toolchain/check/testdata/interop/cpp/primitive_types/arithmetic.carbon | 1 | theirs |
| toolchain/check/testdata/interop/cpp/primitive_types/long_and_long_long.darwin.carbon | 3 | theirs |
| toolchain/check/testdata/interop/cpp/primitive_types/long_and_long_long.llp64.carbon | 5 | theirs |
| toolchain/check/testdata/interop/cpp/primitive_types/long_and_long_long.lp64.carbon | 3 | theirs |
| toolchain/check/testdata/interop/cpp/range_for.carbon | 143 | theirs |
| toolchain/check/testdata/interop/cpp/stdlib/initializer_list.carbon | 7 | theirs |
| toolchain/check/testdata/interop/cpp/template/generic_call.carbon | 7 | theirs |
| toolchain/check/testdata/interop/cpp/template/var_template.carbon | 1 | ours |
| toolchain/check/testdata/let/fail_generic_import.carbon | 3 | ours |
| toolchain/check/testdata/let/generic_import.carbon | 5 | ours |
| toolchain/check/testdata/let/import.carbon | 2 | theirs |
| toolchain/check/testdata/let/import_access.carbon | 1 | theirs |
| toolchain/check/testdata/main_run/fail_mismatch_return.carbon | 1 | theirs |
| toolchain/check/testdata/named_constraint/invalid_members.carbon | 2 | ours |
| toolchain/check/testdata/operators/overloaded/index.carbon | 7 | theirs |
| toolchain/check/testdata/operators/overloaded/index_with_prelude.carbon | 25 | theirs |
| toolchain/check/testdata/operators/overloaded/indirect_index_with.carbon | 34 | theirs |
| toolchain/check/testdata/operators/overloaded/string_indexing.carbon | 4 | theirs |
| toolchain/check/testdata/patterns/unused.carbon | 1 | ours |
| toolchain/check/testdata/var/destroy_control_flow.carbon | 20 | theirs |
| toolchain/check/testdata/variadics/pack_expansion.carbon | 2 | ours |
| toolchain/driver/testdata/compile/optimize/clang_no_optimize_twice.carbon | 2 | theirs |
| toolchain/lower/testdata/array/iterate.carbon | 6 | theirs |
| toolchain/lower/testdata/builtins/cpp.carbon | 4 | theirs |
| toolchain/lower/testdata/choice/basic.carbon | 2 | theirs |
| toolchain/lower/testdata/class/static.carbon | 3 | theirs |
| toolchain/lower/testdata/class/virtual.carbon | 1 | theirs |
| toolchain/lower/testdata/for/bindings.carbon | 6 | theirs |
| toolchain/lower/testdata/for/break_continue.carbon | 9 | theirs |
| toolchain/lower/testdata/for/for.carbon | 9 | theirs |
| toolchain/lower/testdata/function/call/form.carbon | 1 | theirs |
| toolchain/lower/testdata/index/indirect_index_with.carbon | 9 | theirs |
| toolchain/lower/testdata/interop/cpp/class/export/class.carbon | 15 | theirs |
| toolchain/lower/testdata/interop/cpp/class/export/destroy_from_thunk.carbon | 4 | theirs |
| toolchain/lower/testdata/interop/cpp/class/export/method.carbon | 13 | theirs |
| toolchain/lower/testdata/interop/cpp/class/import/alignment.carbon | 7 | theirs |
| toolchain/lower/testdata/interop/cpp/class/import/base.carbon | 2 | theirs |
| toolchain/lower/testdata/interop/cpp/class/import/constructor.carbon | 16 | theirs |
| toolchain/lower/testdata/interop/cpp/class/import/conversion.carbon | 5 | theirs |
| toolchain/lower/testdata/interop/cpp/class/import/dynamic.carbon | 10 | theirs |
| toolchain/lower/testdata/interop/cpp/class/import/method.carbon | 12 | theirs |
| toolchain/lower/testdata/interop/cpp/class/import/virtual_base.carbon | 1 | theirs |
| toolchain/lower/testdata/interop/cpp/debug_info.carbon | 2 | theirs |
| toolchain/lower/testdata/interop/cpp/enum.carbon | 19 | theirs |
| toolchain/lower/testdata/interop/cpp/extern_c.carbon | 12 | theirs |
| toolchain/lower/testdata/interop/cpp/function/export/constructor.carbon | 5 | theirs |
| toolchain/lower/testdata/interop/cpp/function/export/function.carbon | 6 | theirs |
| toolchain/lower/testdata/interop/cpp/function/export/generic.carbon | 8 | theirs |
| toolchain/lower/testdata/interop/cpp/function/import/function_decl.carbon | 18 | theirs |
| toolchain/lower/testdata/interop/cpp/function/import/function_ptr.carbon | 31 | theirs |
| toolchain/lower/testdata/interop/cpp/function/import/import_inline.carbon | 1 | theirs |
| toolchain/lower/testdata/interop/cpp/function/import/method_ptr.carbon | 9 | theirs |
| toolchain/lower/testdata/interop/cpp/function/import/parameters.carbon | 8 | theirs |
| toolchain/lower/testdata/interop/cpp/function/import/return.carbon | 13 | theirs |
| toolchain/lower/testdata/interop/cpp/globals.carbon | 23 | ours |
| toolchain/lower/testdata/interop/cpp/issue7142.carbon | 5 | theirs |
| toolchain/lower/testdata/interop/cpp/nullptr.carbon | 9 | theirs |
| toolchain/lower/testdata/interop/cpp/operators.carbon | 4 | theirs |
| toolchain/lower/testdata/interop/cpp/pointer.carbon | 10 | theirs |
| toolchain/lower/testdata/interop/cpp/reference.carbon | 25 | theirs |
| toolchain/lower/testdata/interop/cpp/share_ast.carbon | 7 | theirs |
| toolchain/lower/testdata/interop/cpp/std_initializer_list_pointer_pointer.carbon | 12 | theirs |
| toolchain/lower/testdata/interop/cpp/std_initializer_list_pointer_size.carbon | 12 | theirs |
| toolchain/lower/testdata/interop/cpp/template.carbon | 8 | theirs |
| toolchain/lower/testdata/interop/cpp/thunks.carbon | 5 | theirs |
| toolchain/lower/testdata/interop/cpp/void.carbon | 10 | theirs |
| toolchain/lower/testdata/primitives/optional.carbon | 11 | theirs |
| toolchain/lower/testdata/template/class.carbon | 1 | clean at a9892d4bb (theirs by TP-2) |
| toolchain/lower/testdata/template/merging.carbon | 3 | theirs |
| toolchain/lower/testdata/var/destroy_control_flow.carbon | 28 | theirs |
| toolchain/lower/testdata/var/import.carbon | 2 | theirs |
| toolchain/lower/testdata/var/param.carbon | 7 | theirs |
| toolchain/parse/testdata/generics/named_constraint/template_constraint.carbon | 2 | ours |
| toolchain/parse/testdata/variadics/expand.carbon | 2 | theirs |
| toolchain/parse/testdata/variadics/pack_expansion_statement.carbon | 2 | theirs |

## Appendix C: the prototype's artefacts (the reference, not the product)

Worktree /home/user/carbon-ua3-proto (detached at 95df37622; base a9892d4bb;
kept for the reviews, removed after the landing by `git -C
/home/user/carbon-lang worktree remove --force /home/user/carbon-ua3-proto`);
label ua3-proto: /home/user/arb/build/ua3-proto, /home/user/arb/install/
ua3-proto (`bin/carbon`), /home/user/arb/conformance/ua3-proto
(CONFORMANCE.txt, scoreboard.json), /home/user/arb/cache-ua3-proto (kept,
17 MB). Under the scratchpad directory

<!-- google-doc-style-ignore -->

```text
/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/ua3/proto/
```

<!-- google-doc-style-resume -->

are commits.txt (`git log --oneline 701863aa5..HEAD`, 219 lines),
resolutions.tsv (197 rows: path, class, choice), resolution-vs-upstream.patch
(759 files, 17.5 MB), msg-merge.txt, msg-fix1.txt to msg-fix5.txt,
msg-fill.txt, gate-prefill-failed.txt (454 paths: the DISCARDED pre-fix-4
gate at cf61d095e), gate-prefill2-failed.txt (449 paths: the 448 the fill
rewrote plus basics/dump_prelude.carbon, which failed in that gate and
passed after the fill untouched), gate-postfill-failed.txt (the 6),
fill-paths.txt (the 448), pass2-files.txt, pass2-delta.diff, au1.out to
au7.out (the autoupdate logs: au1.out is the discarded 454-file pass with a
41-entry manual-fix list; au2.out's lines 8-17 are the ten entries of §0.5;
rev 1 cited au1.out, corrected 2026-11-23, review fold: B-m2), build1.out
to build11.out, gate1.out to gate7.out (gate5.out the 1666/448 line,
gate6.out and gate7.out the 2108/6 lines), destroy-respell.txt (the 21),
carbonbuild-cir/ (the scratch arbiter copy with the MLIR/CIR archive filter;
retired by ARB-5's landing and sync on 2026-11-23, kept as the record of
the prototype's build), probe/ (the W-356 probes, the union and where-alias
probes). The planner's own measurements are under scratchpad/ua3/planner/
(window-log.txt, window-subsystem.txt, weekly-rows.txt, the fill
composition lists, probe/item10*.carbon and their outputs, appendixB.md).
The four audits' outputs are under scratchpad/ua3/reader1/ to reader4/
(reader 3's golden-matrix.tsv and golden-src.tsv are Appendix B's source).
Review A's probes are under scratchpad/ua3/reviewA/probe/ (union_friend,
class_let_discard, lambda_template).

**Rev 2's re-measurement (label ua3-fixer, 2026-11-23; the worktree and the
label removed when the fold was committed).** Under scratchpad/ua3/fixer/:
amendments.patch (`git diff 95df37622 6e26f9a38`, the fixer's one commit on
a detached worktree at the prototype's HEAD: 14 files, +256 −165 — the
union handlers' friend-scope push and pop, the `_` handler's lane gate, the
comment re-wordings, union/friend.carbon, the renamed let/struct_pattern.
carbon and the five retriage splits, their CHECK lines autoupdate's;
msg-amend.txt its message), bin/edits.py (the exact source edits),
build1.out (the scratch build.sh, status 0, manifest 2115), build2.out (the
arbiter of record's build.sh after ARB-5's sync: "ninja: no work to do"),
install.out, gate1.out (2109/6 before the refill), au1.out to au3.out (6, 0,
0 files), gate2.out (2114/1: friend.carbon's `u8`), au4.out and au5.out (1,
0), gate3.out (`GATE ua3-fixer: 2115 passed, 0 failed`), conf-launch.out
and /home/user/arb/logs/conformance-ua3-fixer.log (the CONFORMANCE line of
§0.5; the conformance directory itself is deleted with the label),
build-m4.out, install-m4.out and gate-m4.out (mutant M4: the two stringify
cases deleted, `--filter generic/template` → `GATE ua3-fixer: 19 passed, 1
failed`, index.carbon printing ``D(<cannot stringify inst430003BB: {kind:
AddrOfAction, arg0: inst430003B7, type: type(inst(InstType))}>)`` where
``D(&p.n)`` is pinned; stringify.cpp restored afterwards), probe/ (the
union-body sweep, the discard probes and their .fixer/.proto/.base outputs,
probe-summary.txt), dryrun.txt and mt-cb7821735.txt with their path lists
(the 194-path set at 701863aa5 and cb7821735), rg1-checks-weekly.tsv and
rg1-quotes-weekly.tsv (the 2026-11-23 weekly's tables, read before they
reached trunk). The prek XDG cache used for the fold is deleted.

The prototype's commits: 08be343f7 the merge (the audits' resolutions);
696579ae4 fix 1 (`MissingDefinitionInImpl` declared at the moved OV-2 check;
superseded by fix 5); 111b09e0e fix 2 (nine sites from the keep-going build,
§0.4 item 20 (e)); cf61d095e fix 3 (slice.carbon's import, the `ref`
argument, the `where` region's discard, generate_ast's specific, the
pack-name check's home); 7f50ff1ab fix 4 (`IsCoreDestroyImplInFile` by
string, the local loop skipping imports; mixed_constant_init's min_prelude);
06c469e15 the fill (448 files, +95429 −93651); 95df37622 fix 5 (the once-flag
in `CheckRequiredDefinitions`; clang-format on 19 files). Every one of
their source changes is folded into this plan's M; their messages are the
fastest reading of why each resolution has the form it has.

## Review fold record (rev 2, 2026-11-23)

Review A (merge correctness, fork-mechanism fidelity, R32) returned
APPROVE-WITH-AMENDMENTS with four MAJORs and three MINORs; review B
(mechanics, records, verification) returned REJECT with one BLOCKER, three
MAJORs and seven MINORs. Every finding is folded; none is rejected. Where a
finding changed a resolution (A-M1, A-M2, A-m2) or a retriage's form (A-M4
/ B-M1), the fixer re-measured it on a detached worktree at the prototype's
HEAD under the label ua3-fixer (§0.5's second block; Appendix C), so rev 2
quotes measured code and lines: the crash probe, the discard probes, the
union-body sweep, the gate `2115 passed, 0 failed`, the conformance line
unchanged at 226/0/15, and mutant M4. The register findings (B-B1, A-m3)
were re-measured on trunk's tables at 0072b2812 and the weekly's. Trunk
moved during the fold (cb7821735: ARB-5 and the weekly check of
2026-11-23), which B-B1 and B-M2 had predicted; the dry run against it reads
the same 194 paths.

| Finding | Severity | Disposition | Where folded |
| --- | --- | --- | --- |
| A-M1 `friend` in a union body crashes (5fed32a9a vs UN-1) | MAJOR | FOLDED; reproduced on the prototype's install (`CHECK failure at common/array_stack.h:71`), fixed in the re-measurement (exit 0), the sweep of eight union-body shapes crash-free | §0.3 handle_class.cpp row, §0.4 item 23, §0.5, §2.7, §3 M, §4, §8.1 steps 1 and 9, §8.2, D-UA3-18 (T13.10), K-15, hand-off 4 (k), A.2, A.5, A.9, A.12, C |
| A-M2 the `_` discard dead in every non-match lane; W-372/W-079 records wrong | MAJOR | FOLDED; reproduced (`no field named b` on the prototype), the lane gate measured (the TODO in let/var/param, the discard in match, `if (let`, `let`-`else`) | §0.3 handle_pattern_list.cpp row, §0.4 items 17 and 24, §0.5, §0.6 W-372 and W-079, D-UA3-6, §2.3, §4, §8.1 step 6 (M2b) and 9, §8.2, K-8, K-11, K-16, D-UA3-18 (T13.8), A.5, A.6, A.7, A.9, A.10, A.12, rejected alternative (x) |
| A-M3 deleting TP-1's stringify cases misreads R32 (d), contradicts D-TP-23, regresses index.carbon:332/:337 | MAJOR | FOLDED; the cases kept (as the prototype); mutant M4 measured: `D(<cannot stringify ... AddrOfAction ...>)` in place of `D(&p.n)` | §0.3 stringify.cpp row, §0.6 W-394, D-UA3-7, §2.1, §2.4, §4 pre-registered shapes, §8.1 step 6 (M4), §8.2, K-4 rewritten, rejected alternative (vii) reversed, D-UA3-18 (T13.9), hand-off 6, A.2, A.5, A.7, A.9, A.10, A.12 |
| A-M4 R-3 deletes the only pins of the parameter and let-in-match-arm-body lanes | MAJOR | FOLDED (with B-M1): R-3 renames, drops the splits' prefix, adds the `_` parameter pin; measured gate 2115 of 2115 | D-UA3-6, §0.6, §2.3, §3 item 5, §4, §8.1 step 3, A.4, A.5, A.6, A.7, A.11, rejected alternative (ix) |
| A-m1 R-4 attributes the lambda split's pass to the wrong mechanism | MINOR | FOLDED: TP-1's `CallAction`; upstream still rejects the split; a convergence-candidate row T13.11 | §0.6 W-037, §3 item 5, D-UA3-15, D-UA3-18, A.4, A.7, A.9 |
| A-m2 comments still name retired functions and the `WrapperBinding` alternative | MINOR | FOLDED in the re-measurement's commit; a comment-inclusive grep added | §2.2 item 6, §2.9 (member_access.cpp), §8.2, A.2 |
| A-m3 the seven L rows re-anchored to 0 collide with the 2026-11-23 weekly | MINOR | FOLDED with B-B1 | see B-B1 |
| B-B1 register rows asserted at a tip the register is no longer anchored to | BLOCKER | FOLDED: the register step is parametrized on `<anchor>` (the latest weekly entry's tip); the L counts measured (1, 0, 0, 0, 1, 0, 1 at 0072b2812); check_quotes at `<anchor>`; D-UA3-1's false clause dropped; a break condition for a weekly commit between M and D | header, §0.1, §0.6 W-355, §0.7 rewritten, D-UA3-1, D-UA3-15, §2.16, §8.1 step 5, §8.3, K-14, hand-off 1 and 6, A.5, A.7, A.9, A.10 |
| B-M1 R-3 deletes a now-passing fork golden; W-079's discharge unrecorded | MAJOR | FOLDED with A-M4; W-079 row, note and title prefix added | §0.6 W-079, §3 item 5, §8.3, A.5 residues, A.7, A.10 |
| B-M2 the landing names no ARB-5 precondition | MAJOR | FOLDED: ARB-5 landed (cb7821735) and synced (`libCIR` 2); the scratch route retired; preconditions in D-UA3-4, D-UA3-17 and §8.4; each measured line names its script; the running instance's `diff -r` against the record measured (gen_ninja.py identical; four files differ, the owner's to sync) | header, D-UA3-4, D-UA3-17, §8.1 preamble, §8.4, hand-off 2 and 5, A.2, A.10, C |
| B-M3 the shrink line contradicts §3 | MAJOR | FOLDED: R-1 to R-5 not deferrable; W-401 filed in the same PR; the shrink line covers C-2 and P only | D-UA3-17, §3 shrink line, §3 item 5 |
| B-m1 golden directory counts contradict Appendix B; 352 vs 354; 44 vs 45 | MINOR | FOLDED: 69/50; 354; six drift rows | §0.1, §0.2, §2.14 |
| B-m2 Appendix C and hand-off note 1 name the discarded artefacts | MINOR | FOLDED: au2.out, gate-prefill2-failed.txt (449: 448 plus dump_prelude), the discarded run labelled | hand-off 1, C |
| B-m3 §8.2 counts do not match the prototype; T13.7's pattern reads 2 at the tip | MINOR | FOLDED: 6/1/1, 5, 4, 5 re-measured; T13.7 on `auto insts() const` with `-F` | §8.2, D-UA3-18, A.9 |
| B-m4 two weekly ADVANCE rows' touchpoints not carried (54f37b35b, 2e2125585) | MINOR | FOLDED: the access mapping is upstream's on the per-member thunk path, no pin exists (a follow-on); gap row 45 re-cited with override.carbon's narrower TODO | §0.2 table, §0.6, §2.16, §8.3, A.12 |
| B-m5 fork design-page spellings and P's pin reference left behind | MINOR | FOLDED: functions_overloading.md:310/:394 notes and templates.md's split name in P | §2.15, §6 |
| B-m6 landing text omits D-LAND-6 steps 8, 9, 11, 12 and R32 (e) for PR 53 | MINOR | FOLDED: the four steps named (both evaluator checkers, rowcheck rows 45/80/81 and the header, the mirror push); R32 (e) cited on PR 53's rule in the header, A.6 and A.10; the no-rebase rule re-cited to R33 (a) and D-UA-1 | header, D-UA3-1, §8.1 step 5, §8.4, §7 (ii), A.6, A.10 |
| B-m7 R-n namespace collision; no ledger status field; records texts named not given | MINOR | FOLDED: risks K-1 to K-16; A.7's title-prefix form; A.12's verbatim texts; "(R-3)" cites corrected | Sections, §0.5, §7, A.7, A.12 |

Fold-time measurements not in rev 1 (all on 2026-11-23): the dry run at
cb7821735 (tree eac60b2d3, the same 194 paths); the register scripts on
trunk's tables at 0072b2812 (quotes 9 failed on the pre-weekly table, 0 on
the weekly's; greps 0 failed at the default cut, 7 failed at cut 7a3608bab
with H4.5, H10.8, H11.10 reading 1); `grep -c libCIR
/home/user/arb/carbonbuild/gen_ninja.py` 2; the arbiter's `diff -r` against
trunk's record (gen_ninja.py identical, build.sh's header and three helper
scripts differ, env.sh instance-only); the re-measurement's lines of §0.5
and Appendix C; the prototype-install probes for A-M1 and A-M2; the
class-twin outputs of the union-body sweep on tp2-base and the prototype.

## Sign-off

-   Correctness review (rev 1): APPROVE-WITH-AMENDMENTS (review A; four
    MAJORs, three MINORs), folded into rev 2.
-   Strictness review (rev 1): REJECT (review B; one BLOCKER, three MAJORs,
    seven MINORs), folded into rev 2.
-   Re-reviews of rev 2: pending.
-   Coordinator sign-off for implementation: pending (R29 (c): two
    adversarial reviews, the fold, re-reviews to sign-off).
