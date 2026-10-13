<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# Design docs without placeholders: status notes, measured 0.1 behavior, the interop TODO sections, the F-008 threads page (DD-1, W-065)

**Status:** rev 1, 2026-10-13, planner draft for the two plan reviews of
R29(c); nothing in it is folded yet. Branch `claude/carbon-fork-0-1-dd` in the
worktree `/home/user/carbon-dd`, cut from trunk 162c7e839 ("ORCHESTRATION:
repair the R31 heading manufactured by the previous stamp"), whose toolchain,
prelude and docs/design/ sources are identical to 0bdce60a5 (`git diff --stat
0bdce60a5 162c7e839 -- toolchain core docs` is empty; the four commits between
them touch fork/ORCHESTRATION.md only). Every docs, proposal, toolchain and fork
line number in this plan was opened at 162c7e839 for this plan. Trunk's
conformance floor is **128 PASS / 0 FAIL / 22 SKIP over 150 programs, 48/56
bullets** (fork/conformance/out/scoreboard.json `totals`, generated
2026-10-06), and this plan re-measured it locally on the container-built fork
toolchain (`/home/user/carbon-build/carbon-trunk/install/bin/carbon`, version
`0.0.0-0.dev+0bdce60a5`): the same 128 / 0 / 22 over 150, 48/56 (`runner.py
--toolchain <that path> --out <private scratch dir>`, R5). The gap-analysis
header reads **30 DONE / 21 PARTIAL / 4 MISSING / 1 DESIGN-ONLY** over 56
(fork/gap-analysis.md:18).

**Item and bullet.** W-065 ("DOCS-1: replace skeletal/placeholder design docs
not covered by the six sprint deliverables (templates, metaprogramming, match,
interop TODO sections)", kind design-needed, size L, blocked_by none,
fork/inventory/work-items.json) is the owning item. Its bullet, verbatim from
the gap table and the conformance header (R7, not touched): "Goal: design docs
documented, cohesive, understandable without placeholders" (fork/gap-analysis.md
:91, PARTIAL; fork/conformance/programs/project/design_docs_placeholders.carbon
:5). W-065's notes name the work: the four pages that self-describe as
placeholders, the `match` section's own placeholder note, and the interop
README's empty TODO headings, "documentation-of-existing-behavior work.
Document-review arbitration only; W2's arbiter is grep-verifiable ('no
TODO/placeholder markers')". This plan also discharges the documentation half
of **W-020** (TA-0, the F-008 memory-model page), which §0.4 item 1 shows has
never landed although the workstream context assumed it had (D-DD-7).

**What this workstream does and does not do.** It documents the existing
behavior of the fork toolchain; it decides nothing. Every replaced placeholder
becomes a dated status note that names the accepted proposals or fork decision
behind the page and the toolchain's status, and the behavior is added in new
sections whose every code block is a complete file compile-verified on the fork
toolchain (R3, R6) and on the upstream nightly
`/home/user/nightly/tc/carbon_toolchain-0.0.0-0.nightly.2026.10.12/bin/carbon`
(`0.0.0-0.nightly.2026.10.12+62f1cc6`), labelled fork-only where the nightly
rejects it. No toolchain, prelude, golden, `.github/` or `toolchain/`/`core/`
file changes; seven toolchain defects found while measuring are filed as
residues W-180..W-186 with their exact evidence (R10). **No fork design id is
minted**: F-016 stays unallocated by this plan (D-DD-3). **Id reservation**
(recorded here and in the discharge's ORCHESTRATION stamp): the ledger maximum
over trunk and every live branch is W-167 (ST-1); W-168/W-169 are SC-1's;
W-170..W-179 are OP-1's; **DD-1 reserves W-180..W-189** — W-180..W-186 filed at
discharge, W-187 contingent (D-DD-9), W-188/W-189 for review folds; a reserved
id that goes unused stays unused. **Merge position:** after OP-1, the last of
the current queue (PR 53, PR 51, PR 52, SC-1, PR 54, PR 55, OP-1, then DD-1;
fork/ORCHESTRATION.md "Later on 2026-10-13").

## §0 Audit: what the pages say, what the toolchain does, what is stale

### §0.1 The named pages, measured

Toolchain columns: "fork" is the container-built fork toolchain above, "nightly"
the upstream nightly; outcomes are from the probe and sample runs recorded in
§4 (every sample id in this table is a file listed there).

| # | Page and lines (at 162c7e839) | What the page says now | What the toolchain does (measured) | Upstream basis |
| --- | --- | --- | --- | --- |
| 1 | docs/design/templates.md:22-27 (`## TODO`, 111 lines in all) | "This is a skeletal design ... it is a placeholder until we have more time to examine this detail" | `template` bindings in deduced, explicit and class parameter lists; dependent member access, conversion and operators resolved per instantiation (P04 RUNS on fork and nightly); errors at the call as "unable to monomorphize specific" (R08); the page's own `Convert(i, f32)` is rejected (R11, implicit-conversion rules); constrained lookup ignores the constraint (R09, W-183); cross-file use crashes check (PR-A, W-014); `template constraint` absent on trunk (PR-N rejected on fork, RUNS on SC-1's toolchain) | p002200 (accepted), p002138, issue 949, p000989 |
| 2 | docs/design/metaprogramming.md:18-26 (32 lines) | same boilerplate, plus "See proposal PR 89 for context -- that proposal may replace this" | `eval fn` and `musteval fn` (lex/token_kind.def:200 and :216); compile-time evaluation of array bounds, types, recursion (P05 RUNS on both); `musteval` with a runtime argument rejected (R12); plain `fn` in a constant context rejected (R13); local compile-time `let` TODO (R14, W-031); unbounded recursion segfaults the compiler (PR-C, W-184) | no proposal: PR 89 has no file under proposals/ (`ls proposals/p000089*` empty); `musteval` appears only as illustration in p007140:323-346, p007697:504 and functions.md:645; milestones.md:272 defers "Long tail of metaprogramming features" |
| 3 | docs/design/aliases.md:19-24 (49 lines) | same boilerplate | `alias` at file, namespace, class and function scope, of types, specifics, namespaces, functions, members, variables and constants (P01 RUNS on both); runtime value rejected (R01); parameters rejected (R02); declaring through a namespace alias rejected (R03, testdata namespace/fail_decl_in_alias.carbon); constant-value aliases accepted although README.md:2663-2665 says they are not (testdata alias/builtins.carbon `bool_value.carbon`) | none: p003938:81-82 "`alias` is not fully designed; it's modeled on informal discussions"; README.md:2655-2708 cites p000107, issue 749, p000553, p000989 |
| 4 | docs/design/blocks_and_statements.md:18-23 (51 lines) | same boilerplate; its second example (:44-51) uses a bare nested block | every statement form of P02 RUNS on both; a bare `{ ... }` statement is rejected as a struct literal (R04, W-185) although p000162:65 lists blocks as statements | p000162, p002665, p000285, p000339, p000340, p000353, p001885, p000415, p000538, p002511, p000257 (`returned var`) |
| 5 | docs/design/pattern_matching.md:718-721 (in `### Pattern match control flow`, :716) | "`match` is a skeletal design ... Aside from guards, it should not be treated as accepted by the core team; rather, it is a placeholder" | the fork implements `match` (P06 RUNS on fork; the nightly reports "semantics TODO: `HandleMatchIntroducer`" for every `match`); exhaustiveness and usefulness errors (R15-R18); guards need parentheses (R19); an exhaustive `match` without `default` does not end control flow (R20, PR-L, W-180); alternative patterns inside tuple patterns not recognized (R21, W-182); unsupported scrutinee types (R22, PR-D); the page's own `var 5 = n;` (:684) crashes the checker (PR-B, W-181) | p002188 (patterns, guards, exhaustiveness), p005164 (objects; its "drive-by fix" wrote the placeholder note, p005164:44-45); F-011 / W-012 for the pattern-binding forms |
| 6 | docs/design/interoperability/README.md, 355 lines, 18 `TODO` lines: headings :156, :240, :242, :244, :246, :250, :275, :350 (seven empty, :275's body the note :277-278 "Incorporate proposal #6357"), their eight TOC entries :20, :27-30, :32, :35, :39, and :286 (prose naming a former TODO) | eight `TODO:` headings with no content | measured per section in §2.7: inline import (P07), constructors (P08, R23), struct literals (P09, R24), members (P10, R25, R26), globals (P11, R27), integers (P12, R28), pointers/references/`const` (P13, R29), operators (P14, R30); every RUNS sample runs on both toolchains except P09 (fork-only, UN-2's union initialization) | p006358, p006254, p005448, p006357, p006668, p006177, p006710; fork F-007 (UN-2), F-009 (OV-3) |
| 7 | docs/design/README.md:143-149 "This document is provisional" | "includes much that is provisional or placeholder" (the stub's evidence) | a general disclosure, accurate | — |

#### §0.1a The milestone wording and the gap row, verbatim

docs/project/milestones.md:55-56 and :73-75: "Language design components are
documented, cohesive, and understandable by evaluators without placeholders."
and "Design for both Carbon use of C++ and C++ use of Carbon, including all
major C++ language features except for coroutines, is documented, cohesive, and
understandable by evaluators without placeholders." The 0.1 milestone defers
"Coroutines, async, generators, etc.", "Carbon-native threading" and "Long tail
of metaprogramming features" (:268-272).

fork/gap-analysis.md:91, evidence cell: "Generics/variadics/pattern-matching/
classes designs are mature, and the fork landed docs/design/error_handling.md
(F-006) and docs/design/unions.md (F-007); but templates.md,
metaprogramming.md, and the `match` section of pattern_matching.md still
self-describe as skeletal placeholders, the interop README has 9 'TODO:' section
headings, and the F-008..F-011 pages (threads/atomics, overloading, structural
conformance, if-let) have not landed (W-065 open)."

#### §0.1b The stub's un-SKIP condition, verbatim

design_docs_placeholders.carbon:6 (the SKIP line) ends: "No runnable program can
distinguish a cohesive design doc from a placeholder one, so this bullet has no
executable surface; the features those docs describe are arbitrated separately
by the generics/, types/, control_flow/, and interop/ programs in this suite.
Re-audit by document review when the skeletal docs and empty interop sections
are replaced by accepted proposals." Its body (:11-13) returns `0`. The
condition "replaced by accepted proposals" cannot be met by a fork documentation
workstream (upstream accepts proposals); the precedents rows 88, 89 and 90
arbitrate a documentation bullet by **document review by two fresh agents** (row
88 DONE "by way of accepted p5914" with its program SKIP; SAFE-1 on PR 53 takes
row 89 MISSING to DONE on review, D-SAFE-21/23; EV-1 on PR 54 takes row 90 to
DONE on transcription plus review, D-EV-16, deleting its stub and adding
transcribed programs). W-002's note (3) records that the harness has no
arbitration channel for document-review bullets. D-DD-5 takes the EV-1 shape.

#### §0.1c The sweep of docs/design/ (every placeholder and TODO marker, classified)

The W2 rule of D-DD-2 was run as a script over docs/design/ at 162c7e839
(rule text in §2.12; prototype in the session scratchpad): **36 hits**, every
one classified below. A marker that the rule does not hit is an inline note
beside existing content (category C); `grep -rcE TODO --include=*.md
docs/design` counts 110 `TODO` occurrences in 23 files, the remainder of which
are in category C.

| Class | Location | Disposition |
| --- | --- | --- |
| A (boilerplate) | templates.md:24-27, metaprogramming.md:20-23, aliases.md:21-24, blocks_and_statements.md:20-23, pattern_matching.md:718-721 | **In scope**: status notes (§2.1-§2.6) |
| B (TODO heading) | templates.md:22, metaprogramming.md:18, aliases.md:19, blocks_and_statements.md:18 (`## TODO`) | **In scope**: become `## Status` |
| B | interoperability/README.md:156, :240, :242, :244, :246, :250, :275, :350 | **In scope**: real content (§2.7) |
| C' (TODO-only section) | README.md:3815 `### Enums` (body `> **TODO**`) | **In scope** (§2.9): C++ enums are a major C++ feature under milestones.md:73-75 |
| C' | README.md:3986, :3990, :3994 (Abstract machine, Co-routines, Concurrency) | **In scope** (§2.9): one dated status note each, no design text |
| C' | assignment.md:159-164 (`_TODO_: Describe the rules ...`) | **In scope** (§2.3): statements are core 0.1 components (milestones.md:65-67) |
| C' | expressions/comparison_operators.md:474-477 (Custom result types) | **In scope** (§2.10): the marker becomes "Future work" plus a status note |
| C' | README.md:3905 (Lifetime and move semantics) | **Closed by held PR 53** (SAFE-1 replaces :3905-3907); allowlisted at state T |
| C' | expressions/arithmetic.md:184 (Strings) | **Closed by held PR 55** (ST-1 adds its F-014 amendment after :188); allowlisted at state T |
| related | README.md:3909-3912 (Metaprogramming `> **TODO:** References need to be evolved ...`) | **In scope** with metaprogramming.md (§2.9) |
| related | README.md:2890 (`> **TODO:** The design for template constraints is still under development.`) | **In scope** (§2.9): F-010 decided it; state-T and state-L texts |
| related | README.md:1036-1039, :3584-3587, :3657-3660, :3731-3734 ("provisional, no design ... has been through the proposal process yet") | **In scope as cohesion notes** (§2.9): stale against the accepted p002188, p006358, p006254 and p005448; one dated note each, upstream text kept |
| related | code_and_name_organization/README.md:762-772 (`#### Aliasing`: declares `struct TI.RawData` through an alias) | **In scope as a cohesion note** (§2.10): rejected by the toolchain (R03) |
| C (inline beside content) | README.md:1745, :2486, :2777, :2824, :3428-3430, :3442, :3695; classes.md:837, :2360; values.md:133, :738, :836, :983, :1135; generics/details.md (20 hits); variadics.md (7); functions.md:187, :239; expressions/README.md:249; expressions/arithmetic.md:167, :171; expressions/bitwise.md:148; expressions/comparison_operators.md:342, :383, :462; expressions/as_expressions.md:84; expressions/logical_operators.md:118; control_flow/return.md:164; sum_types.md:151; pattern_matching.md:151 | **Out of scope**: each sits beside normative content that is understandable without it and records a pending upstream refinement; the bullet asks for no placeholders, not for no maintenance notes. Not filed. |
| C (fork pages) | functions_overloading.md (19 hits: "semantics TODO" diagnostic names), error_handling.md and slices.md ("placeholder" describing `Core.Optional` / `buf`), unions.md:129 | **Out of scope**: they quote toolchain diagnostics or describe a prelude placeholder (OP-1's W-058) |
| D (README disclosure) | README.md:143-149 | **Out of scope**: an accurate general disclosure; the cohesion notes fix the stale specific ones |
| E (missing page) | the F-008 threads page named by gap row 91 and W-020 | **In scope by D-DD-7** (§2.8): docs/design/interoperability/threads_and_atomics.md |
| E | F-010's template constraints page | **Closed by held SC-1** (docs/design/generics/template_constraints.md on claude/carbon-fork-0-1-sc) |
| E | F-009 and F-011 pages | **Already landed**: functions_overloading.md (OV-1/OV-3) and pattern_matching.md "Refutable pattern bindings" (W-012) |

#### §0.1d The extra probes that shaped decisions (sources in §4.3)

| Probe | Fork outcome | Nightly | Consequence |
| --- | --- | --- | --- |
| PR-A cross-library template call (two files, compiled in both orders) | CRASH: "FATAL failure at .../toolchain/check/import_ref.cpp:5087: Missing case in TryResolveInstCanonical for instruction kind SpliceInst" | not run | W-014's evidence gains the check-side site (§8.5); the page states the limit |
| PR-B `var 5 = n;` (the page's own pattern_matching.md:684) | CRASH rc 134 in `EvalConstantInst` on `VarStorage` (from `GetOrAddVarStorage`, `HandleParseNode(VariablePattern)`); `let 5 = n;` gives "semantics TODO: `expression pattern`" | same crash | W-181 |
| PR-C unbounded `eval fn` recursion | CRASH rc 139 (stack overflow); testdata eval/recursion.carbon:28 "TODO: Diagnose infinite recursion" | same | W-184 |
| PR-D `match` on a template-dependent value | "semantics TODO: `match on unsupported scrutinee type`" | no `match` | the `### Templates` rules of pattern_matching.md:530-572 are unimplemented; stated |
| PR-E `overload fn` set with a template member | RUNS, prints 1 then 2 | not run | templates.md's Overloading note |
| PR-I struct literal initializing a class with a `private` field, outside the class | RUNS (accepted) | same | W-186: classes.md:2068-2072 says `private` members are accessible only to the class |
| PR-L exhaustive `match` with an irrefutable arm, no trailing `return` | "missing `return` at end of function with declared return type" | — | W-180 covers irrefutable arms, not only choices and `bool` |
| SC-1 toolchain (`carbon-sc`, 0.0.0-0.dev+bc8b37290) | all 16 RUNS samples PASS; all 30 REJECTS diagnostics identical to trunk's | — | state L needs no sample change for SC-1 |
| UA-2 toolchain (`carbon-ua2`, 05a5c30f7) and ST-1 toolchain (`carbon-st`, 84ff63560) | all 16 RUNS samples PASS | — | same for PR 51 and PR 55 |

### §0.2 Held PRs and branches that touch the same files (collision table)

Measured with `git diff --name-only 0bdce60a5...<branch> -- docs/` and the
fork-record paths.

| Branch (PR) | Files DD-1 also edits | Their hunk | Expected effect at DD-1's integration |
| --- | --- | --- | --- |
| claude/carbon-fork-0-1-sc (SC-1) | docs/design/templates.md | replaces :109-111 (the last paragraph) with a dated F-010 amendment | conflict with DD-1's appended section (adjacent hunks): keep SC-1's paragraph, then DD-1's section; apply the state-L status sentence (§2.4) |
| claude/carbon-fork-0-1-safe (PR 53) | docs/design/README.md | hunks at :2148, :2168 and :3900-3907 (the Lifetime note ends at `### Metaprogramming`, :3909) | conflict with DD-1's :3911 replacement (three lines below): keep both; README :3905 drops out of the W2 allowlist |
| claude/carbon-fork-0-1-st (PR 55) | docs/design/README.md, docs/design/interoperability/README.md | README :633 note; interop README note after :300 (the `std::string_view` section) | none expected (no shared hunk, no heading change); arithmetic.md:184 drops out of the allowlist |
| claude/carbon-fork-0-1-ev (PR 54) | docs/guides/tutorial.md:476-478, docs/guides/evaluator_faq.md:372-373 (state L only) | EV-1 creates these files | DD-1's state-L sentences replace "whose design sections are still placeholders" and "the design documents note their own placeholders" (§2.13) |
| claude/carbon-fork-0-1-ua2 (PR 51) | none in docs/design/ (it edits functions_overloading.md and slices.md); fork/conformance/programs/generics/templates_dependent_member.carbon (un-SKIP) | — | none: no DD-1 page cites the program, and P04 measures the same member-access shape |
| claude/carbon-fork-0-1-cmake (PR 52) | none in docs/design/ | — | none |
| claude/carbon-fork-0-1-op (OP-1) | unknown (in planning; no docs diff yet) | — | re-check with the same command at integration |
| all of the above | fork/decision-log.md (every entry inserted after "### Full autonomy and the throughput protocol", :2843), fork/inventory/work-items.json, fork/gap-analysis.md (header and rows), fork/ORCHESTRATION.md, fork/conformance/README.md (generated table) | — | mechanical: DD-1's entry goes first in the landed region; ids disjoint; the gap header is recomputed from the merged rows; the table is regenerated with `runner.py --update-readme-table` |
| origin/claude/carbon-fork-0-1-7mwfb7-design-docs (stranded, 481e08c24) | holds a 2026-07-19 draft docs/design/interoperability/threading.md (628 lines, seven open sub-forks) and one inline-import paragraph | — | **not used as a source** (D-DD-7): its open sub-forks were decided or overtaken by F8a-F8d; the page of §2.8 is written from F-008, fork/design-sprint/threading-atomics.md:184-224 and measurements |

### §0.3 R31 baselines (recorded before any edit; re-checked after every prek run)

Heading counts per level and list-item counts (`grep -c '^## '` and so on;
`grep -cE '^\s*-   '`; `grep -cE '^\s*[0-9]+\. '`), at 162c7e839:

| File | H1 | H2 | H3 | H4 | H5 | dash items | ordered items | lines |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| docs/design/aliases.md | 1 | 3 | 1 | 0 | 0 | 3 | 0 | 49 |
| docs/design/blocks_and_statements.md | 1 | 3 | 0 | 0 | 0 | 2 | 0 | 51 |
| docs/design/assignment.md | 1 | 10 | 4 | 0 | 0 | 46 | 0 | 356 |
| docs/design/templates.md | 1 | 3 | 4 | 0 | 0 | 6 | 0 | 111 |
| docs/design/metaprogramming.md | 1 | 3 | 0 | 0 | 0 | 2 | 0 | 32 |
| docs/design/pattern_matching.md | 1 | 8 | 15 | 10 | 1 | 112 | 6 | 1099 |
| docs/design/interoperability/README.md | 1 | 13 | 16 | 0 | 0 | 37 | 3 | 355 |
| docs/design/README.md | 1 | 18 | 63 | 28 | 5 | 341 | 3 | 3996 |
| docs/design/code_and_name_organization/README.md | 1 | 8 | 17 | 17 | 0 | 196 | 3 | 1085 |
| docs/design/expressions/comparison_operators.md | 1 | 6 | 5 | 6 | 0 | 53 | 4 | 531 |
| fork/gap-analysis.md | 1 | 5 | 23 | 0 | 0 | 0 | 0 | 594 |
| fork/decision-log.md | 1 | 2 | 44 | 1 | 6 | 23 | 0 | 6803 |
| fork/ORCHESTRATION.md | 1 | 1 | 5 | 0 | 0 | 8 | 4 | 519 |

The expected deltas are spelled per page in §2 ("Counts after"); any other
delta is a manufactured heading or list item, repaired by rephrasing (R31(b)).

### §0.4 Stale claims found (each corrected at discharge, §8.5)

1.  **threads_and_atomics.md never landed.** The workstream context and W-065's
    notes ("TA-0 (W-020) adds threads_and_atomics.md") treat it as landed;
    `find . -name 'threads_and_atomics*'` is empty, W-020 is open ("Doc half
    stays GATED on the design-docs veto digest", work-items.json), gap row 70
    says "Missing: the memory-model design doc", and fork/ORCHESTRATION.md:437
    records that the digest gate "dissolved under R29" and that the F-008
    portion is "ported by [its] own workstream", which finished (F8a-F8d)
    without porting it. D-DD-7 absorbs it.
2.  Gap row 91 says the interop README "has 9 'TODO:' section headings"; OV-3
    retired `TODO: Overload resolution`, so there are 8 (§0.1 row 6). It also
    says the F-008..F-011 pages "have not landed": F-009 (functions_overloading
    .md) and F-011 (pattern_matching.md "Refutable pattern bindings") have;
    F-010 is on the held SC-1 branch; F-008 is the first item of this list.
3.  W-065's evidence pins `pattern_matching.md:712-714` (now :718-721) and
    `fork/gap-analysis.md:73` (now :91). The stub's SKIP text pins
    pattern_matching.md "lines 712-714" and interop README "lines 210-218" with
    "nine" headings including "TODO: Overload resolution" (now :156-:350,
    eight). The stub is deleted (D-DD-5), so its text is not repaired.
4.  fork/conformance/programs/generics/templates_dependent_member.carbon is SKIP
    on trunk with a 2026-07-19 reason ("Template lowering not implemented yet")
    that no longer holds: the program PASSes when run on the fork toolchain
    (P04's member access is the same shape). PR 51 removes the SKIP; DD-1 does
    not touch the program (it is PR 51's).
5.  W-080's notes say a refutable `var` root "stays behind TODOs"; `var 5 = n;`
    crashes instead (PR-B). W-181 is filed; W-080's notes gain one
    cross-reference sentence.
6.  W-014's notes on the UA-2 branch name "the cross-file template lowering
    CARBON_FATAL (lower/handle.cpp:513)" as the remaining cross-file blocker;
    a cross-library call crashes earlier, in check (PR-A). W-014's evidence
    gains the site at discharge (after PR 51 lands, so the edit applies to
    PR 51's text).
7.  The workstream context describes "the operator interoperability model as
    OV-3/UN-2 landed it". Neither touched operators: OV-3 exported overload sets
    and UN-2 mapped unions. The operator model's 0.1 state is the upstream
    import direction (p006254 "Operator calls") with W-045 (missing imports)
    and W-054 (no export); §2.7 documents exactly that.

### §0.5 Decisions this plan auto-adopts (R29(a), each with a break condition)

-   **D-DD-1 Editing posture.** On upstream pages every original paragraph and
    example stays. Only placeholder markers are replaced: the boilerplate
    paragraph and its `## TODO` heading become `## Status` with one dated
    status blockquote; a `TODO:` heading loses its prefix and gains content; a
    TODO-only body becomes content or a dated status note. New behavior goes in
    new sections titled "_topic_ in the 0.1 toolchain" (or under the formerly
    empty heading), after the original content. Where an original example is
    rejected by the toolchain, a dated "Fork note" directly after it quotes the
    measured diagnostic and points to the working form. Break: a reviewer shows
    that a note changes the meaning of accepted proposal text; that note is
    withdrawn and the divergence becomes a residue (D-DD-3).
-   **D-DD-2 Scope and the W2 arbiter.** The arbiter is a script rule over all
    of docs/design/ (§2.12): (a) no line matches the placeholder boilerplate
    (`skeletal design`, `it is a placeholder`, `should not be treated as
    accepted`, `Please feel welcome to rewrite`, whitespace-tolerant); (b) no
    heading's text starts with `TODO`; (c) no section's body consists only of
    TODO-marker paragraphs (optionally with "See ..." or "References"
    paragraphs). Inline notes beside content (category C of §0.1c) are out of
    scope. At state T the rule allowlists exactly the two held-PR-owned hits of
    §0.1c; at state L the allowlist is empty. Break: a document review finds a
    section a reader cannot understand that the rule misses; it joins the scope
    in the fold and the rule gains a clause.
-   **D-DD-3 Documentation, not design; F-016 not minted.** Each page states
    what an accepted proposal or fork decision fixes, what the toolchain does,
    and where they differ (both cited). Toolchain defects are residues; open
    questions stay open on the page. Break: if a page cannot be written without
    choosing a rule that neither a proposal, a fork decision, nor the toolchain
    fixes, the page names the open question and a residue is filed; minting
    F-016 needs the orchestrator.
-   **D-DD-4 Sample policy.** Every new code block is a complete Carbon file
    compile-verified on the fork toolchain and on the nightly. A RUNS sample is
    transcribed byte for byte into a conformance program (D-DD-5); a REJECTS
    sample is a fixture whose header pins the first error message, quoted in
    the page prose; a note on an unchanged upstream example quotes its measured
    diagnostic, pinned by a quote fixture. Fork-only samples say so in the
    sentence after them. Break: if a re-measure at state L changes an outcome,
    the page and fixture follow the toolchain, never the reverse.
-   **D-DD-5 Programs replace the stub.** The stub is deleted and sixteen
    transcribed programs are added under the bullet, as EV-1 did for row 90
    (D-EV-16). The bullet rolls up SKIP → PASS; a PASS means "every documented
    RUNS sample runs as documented", not "the bullet is done": DONE comes from
    the two document reviews and the W2 rule, and every program header says so.
    Break: if the orchestrator rejects program growth under a documentation
    bullet, the programs are dropped, the stub stays SKIP with an R10 reason
    naming the checker, and the checker's `--toolchain` mode runs the RUNS
    samples.
-   **D-DD-6 The checker.** fork/designdocs/check_samples.py (§2.12), in the
    EV-1 style: R27 byte diffs of page blocks against programs and fixtures,
    quote checks, the W2 rule, and an optional `--toolchain` mode that compiles
    every fixture and checks its first error (or runs it and checks its
    stdout). It runs by hand per commit and in the land sequence; at state L,
    if trunk's runner.py calls EV-1's checker from `--self-test`, DD-1's
    toolchain-free checks join it the same way. Break: if joining makes
    `--self-test` depend on a toolchain or exceed its budget, only the diff,
    quote and W2 checks join.
-   **D-DD-7 W-020's documentation half is absorbed.** A new page
    docs/design/interoperability/threads_and_atomics.md (the path F-008's paper
    names, threading-atomics.md:186-187) states F-008's seven-point contract
    with re-verified citations and one measured sample (P16); the interop README
    gains a short section pointing to it. W-020 is discharged and gap row 70
    goes PARTIAL → DONE (expected). Break: if the orchestrator assigns W-020's
    documentation half to another workstream before commit 2 is written, the
    page and the pointer section are dropped and rows 70 and 91 stay PARTIAL,
    bounded by W-020.
-   **D-DD-8 Cohesion notes are bounded.** Beyond the placeholders, DD-1 adds
    only the notes listed in §0.1c (four stale "provisional" notes, the
    template-constraints TODO, the code-organization aliasing example, the
    comparison custom-result marker) and the two EV-1 sentences at state L.
    Break: a reviewer judges a note to be design rather than documentation; it
    is reworded to cite its source or removed.
-   **D-DD-9 Two states.** State T is this branch (trunk 162c7e839, every PR
    above unmerged). State L is the integration commit, which merges trunk
    after OP-1 lands (never a rebase of submitted commits, AGENTS.md), resolves
    §0.2's expected conflicts, applies the state-L texts of §2 (templates.md
    status, README :2890 note, EV-1 sentences, an empty W2 allowlist), and
    re-runs every sample, fixture and the full suite on a toolchain built from
    the merged trunk. Break: if DD-1 must merge before SC-1 or PR 51, it merges
    in state T and W-187 is filed to apply the state-L texts when they land.
-   **D-DD-10 Residues.** W-180 to W-186 (§8.5) are filed at discharge with
    kind, bullet, evidence and the measured probe; existing items are amended
    only where a finding sits inside their stated scope (W-014 evidence, W-080
    cross-reference). Break: if review shows a residue is inside an existing
    item's scope, it is folded there and its id stays unused.
-   **D-DD-11 Reviews.** Two plan reviews (R29(c)) then a separate fixer (R11);
    the writer; two document reviews of the landed pages by fresh agents
    (review A: contradictions with accepted proposals, sibling pages and fork
    decisions; review B: every §4 row re-run with the checker's `--toolchain`
    mode and the runner, every citation opened); a separate fixer; one
    implementation review of programs, fixtures, checker and records (R29(c));
    a separate fixer. A review silent for over an hour is relaunched
    (R29(e)); findings cite (R8); dispositions cite, not narrate (R17). Break:
    a document review returning REJECT triggers a second round of both.
-   **D-DD-12 Local gate (R28; a stated deviation from R23).** GitHub Actions
    on the repository is disabled and the owner's runner is never used, so the
    gate is local: prek to a fixpoint with R31 counts, `runner.py --self-test`,
    the checker with `--toolchain`, a full local conformance run on the
    container-built fork toolchain (private `--out`, R5) and a nightly run of
    the sixteen programs; each commit message records the results. Break: if a
    hosted or owner-dispatched conformance run becomes available before merge,
    it is the record (R9) and the local runs are corroboration.
-   **D-DD-13 Gap-row effect.** Row 91 PARTIAL → DONE on document review (the
    rows 88-90 precedent), row 70 PARTIAL → DONE by D-DD-7; header DONE plus
    two, PARTIAL minus two. Both are "expected, not of record" until the
    conformance run of record. Break: if a document review leaves an in-scope
    placeholder or an unmeasured claim unresolved after the fold, the row stays
    PARTIAL with that finding as its bound.

## §1 Design

### §1.1 Page outline (after DD-1)

-   **templates.md:** `## Status` (accepted p002200; this page an older sketch;
    F-010 and SC-1) → `## Overview` unchanged, plus three fork notes (the
    illustrative `buf(T)`, the rejected `Convert(i, f32)`, specialization by
    overload sets) → new `## Templates in the 0.1 toolchain`.
-   **metaprogramming.md:** `## Status` (no proposal; PR 89; 0.2 deferral) →
    `## Overview` unchanged → new `## Compile-time evaluation in the 0.1
    toolchain`.
-   **aliases.md:** `## Status` (no proposal; p003938) → `## Overview` and its
    `### Alternatives` unchanged → new `## Aliases in the 0.1 toolchain`.
-   **blocks_and_statements.md:** `## Status` (p000162, p002665; the bare-block
    exception) → `## Overview` unchanged → new `## Statements in the 0.1
    toolchain`.
-   **assignment.md:** the `_TODO_` line of `## Tuples, structs, choice types,
    and data classes` becomes a status note plus the measured rules and one
    sample; the leads-issue paragraph stays.
-   **pattern_matching.md:** the note at :718-721 becomes a status note; a new
    H4 "`match` in the 0.1 toolchain" goes after `#### Guards`.
-   **interoperability/README.md:** the eight headings lose `TODO:` and gain
    measured content; a new `## Threads, atomics, and the memory model` section
    points to the new page; the TOC is regenerated by the markdown-toc hook.
-   **interoperability/threads_and_atomics.md (new):** Overview, the contract,
    "In the 0.1 toolchain", Alternatives considered, References.
-   **README.md:** `### Enums` content; Metaprogramming, Abstract machine,
    Co-routines and Concurrency notes; the template-constraints note; four
    "Fork note" blockquotes after stale provisional notes.
-   **Two more pages:** code_and_name_organization/README.md and
    expressions/comparison_operators.md, one note each.

### §1.2 Samples, programs, fixtures

Each RUNS sample (P01-P16) is one fenced `carbon` block, a whole program with
`fn Run() -> i32`, transcribed byte for byte into
fork/conformance/programs/project/design_docs_<topic>.carbon after the header of
§2.11. Each REJECTS sample (R01-R30 except R11) is one fenced block equal to the
body of fork/designdocs/samples/<id>.carbon, whose header carries `//
EXPECT-ERROR: <message>`; the message is quoted in the page prose of the same
section. R11 and X01 are quote fixtures: no page block, their header carries `//
QUOTE: <text>` that must appear in the named section, and `EXPECT-ERROR` or
`EXPECT-STDOUT`. Probe-only facts (PR-A..PR-P) are not on any page as code;
the page cites the residue or testdata that pins them, and §4.3 keeps their
sources for the reviewers.

### §1.3 The checker (summary; spec in §2.12)

One table in the script maps (page, section heading, block index) to a program
or fixture. The default run needs no toolchain: diffs, quotes, the W2 rule, and
an indented-fence check. `--toolchain PATH` adds the compile and run checks
for fixtures. Exit status 1 on any error, with every error listed.

### §1.4 Residue policy

A toolchain behavior is filed when it is a crash, or a divergence from an
accepted proposal or fork decision that blocks a 0.1 bullet's documented
behavior (W-180..W-186). A divergence that does not block a bullet (the
parenthesized guard of R19, constant-value aliases) is documented on the page
with both citations and not filed, because upstream owns both the text and the
parser. Every filed residue is cited on the page where the behavior is
documented.

## §2 Specification, page by page

Conventions for every text below: the fenced `markdown` blocks are the exact
page text to insert (the writer replaces `2026-10-DD` with the commit date and
otherwise copies byte for byte; prek may re-wrap prose but never code). Each
`carbon` block inside them is the sample file named in the line before the
block, already verified (§4). The table-of-contents marker pair that each page
carries is regenerated by the markdown-toc hook and is never written by hand.

### §2.1 docs/design/aliases.md

Edit 1 replaces lines 19-24 (from `## TODO` through "update as appropriate.")
with:

````markdown
## Status

> **Fork status (2026-10-DD).** No accepted proposal specifies `alias` yet:
> the [overview](#overview) below is the original sketch, kept unchanged, and
> proposal 3938 records that `alias` "is not fully designed". The syntax that
> the [language overview](README.md#aliases) uses comes from proposal 107 and
> question-for-leads issue 749. What the 0.1 toolchain implements is
> documented, with examples that compile, in
> [Aliases in the 0.1 toolchain](#aliases-in-the-01-toolchain).
````

Edit 2 appends after line 49 (the end of `### Alternatives`):

````markdown
## Aliases in the 0.1 toolchain

An `alias` declaration gives a second name to something that already has one:
`alias` _name_ `=` _expression_ `;`. The toolchain accepts it at file scope, in
a namespace (`alias NS.Name = ...;`), in a class, and in a function body. The
expression may name a type, a specific of a generic type, a namespace, a
function, a class member (a field, a method, or an interface member), a
file-scope variable, or a constant value. Every use of the alias is a use of the
original entity: a member alias of a field reads and writes that field, and an
alias of a variable names the same storage.

```carbon
import Core library "io";

namespace Geometry;
fn Geometry.Scale() -> i32 { return 10; }

interface Printable {
  fn Print(self);
}

class Point {
  var x: i32;
  var y: i32;
  // A member alias: `p.horizontal` names the field `p.x`.
  alias horizontal = x;
  fn Sum(self) -> i32 { return self.x + self.y; }
  alias Total = Sum;
  // An alias can surface an interface member under a class-member name.
  impl as Printable {
    fn Print(self) { Core.Print(self.x * 100 + self.y); }
  }
  alias PrintToScreen = Printable.Print;
}

// File-scope aliases of a type, a namespace, a function, a constant value,
// and a specific of a generic class.
alias Coord = Point;
alias Geo = Geometry;
alias Scale = Geometry.Scale;
alias Limit = 4;

class Box(T: type) {
  var item: T;
}
alias IntBox = Box(i32);

var calls: i32 = 0;

fn Run() -> i32 {
  // A local alias of a file-scope variable names the same storage.
  alias count = calls;
  count += 1;
  let p: Coord = {.x = 3, .y = Limit};
  Core.Print(p.horizontal);
  Core.Print(p.Total());
  p.PrintToScreen();
  Core.Print(Geo.Scale() + Scale());
  let b: IntBox = {.item = 5};
  Core.Print(b.item + calls);
  return 0;
}
```

This prints `3`, `7`, `304`, `20`, and `6`.

Unlike the [language overview](README.md#aliases)'s rule that the right-hand
side is a name and not a value, the toolchain accepts an alias of a constant
value, such as `alias Limit = 4;` above (pinned by
`toolchain/check/testdata/alias/builtins.carbon`). An alias of a runtime value
is rejected, because an alias names an entity and holds no value of its own:

```carbon
fn Run() -> i32 {
  var a: i32 = 1;
  alias b = a;
  return b;
}
```

The toolchain reports `alias refers to a runtime value`. An alias has no
parameters, so it cannot stand for a family of types:

```carbon
alias Ptr(T: type) = T*;
```

This is rejected with `` `alias` declaration cannot have parameters ``.

An alias of a namespace names the namespace's members, as `Geo.Scale()` does
above, but cannot be used to declare new members:

```carbon
namespace Timezones;
alias TZ = Timezones;
fn TZ.Offset() -> i32 { return 0; }
```

This is rejected with
`name qualifiers are only allowed for entities that provide a scope` (pinned by
`toolchain/check/testdata/namespace/fail_decl_in_alias.carbon`), so the
declaration through an alias in
[Code and name organization](code_and_name_organization/README.md#aliasing) is
not accepted in 0.1; declare members through the namespace's own name.

Aliases follow the access and export rules of other declarations: a
`private alias` is visible only where a `private` member would be, an alias is
exported from its library like any other name and can be re-exported with
`export`, and a diagnostic names a type by the alias that spelled it (testdata
in `toolchain/check/testdata/alias/`: `import_access.carbon`,
`export_name.carbon`, `import.carbon`, `preserve_in_type_printing.carbon`).
````

Counts after: H2 3 → 4 (`## TODO` renamed, one H2 added), H3 1, dash items 3 →
4 (the TOC gains one entry), no ordered items. Samples: P01 (program
design_docs_aliases.carbon), R01, R02, R03.

### §2.2 docs/design/blocks_and_statements.md

Edit 1 replaces lines 18-23 with:

````markdown
## Status

> **Fork status (2026-10-DD).** The [overview](#overview) below is the
> original sketch, kept unchanged. Its rules are those of accepted proposal 162
> (basic syntax), whose grammar makes a block one kind of statement, and of
> proposal 2665 (semicolons terminate statements); each statement has its own
> accepted proposal, cited in
> [Statements in the 0.1 toolchain](#statements-in-the-01-toolchain), which
> documents what the 0.1 toolchain implements. One difference: the toolchain
> does not accept a block on its own as a statement, so the overview's second
> example is rejected.
````

Edit 2 appends after line 51:

````markdown
## Statements in the 0.1 toolchain

A function body is a block: statements between `{` and `}`, run in order. In
the 0.1 toolchain a statement is one of:

-   an expression statement, such as a call, ending in `;`;
-   a declaration: `var` (proposal 339), `let`, `returned var` (proposal 257),
    or a local `alias`, `class`, or `fn`;
-   an assignment `=`, a compound assignment such as `+=` or `%=`, or `++` and
    `--` ([Assignment](assignment.md), proposal 2511);
-   `if`, with `else if` and `else` (proposal 285);
-   `while` (proposal 340), and `for` over an array, a range such as
    `Core.Range(4)`, or another type that implements `Core.Iterate` (proposals
    353 and 1885), with `break` and `continue` in either;
-   `return` with or without a value (proposals 415 and 538), and `return var;`
    for a `returned var`;
-   `match`, and the pattern forms `if (let ...)`, `while (let ...)`, and
    `let ... else`, which only the fork's toolchain implements
    ([`match` in the 0.1 toolchain](pattern_matching.md#match-in-the-01-toolchain),
    [Refutable pattern bindings](pattern_matching.md#refutable-pattern-bindings)).

The body of each `if`, `while`, `for`, and `match` arm is a block and a scope:
a name declared in it is visible from its declaration to the end of the block.

```carbon
import Core library "io";

fn Classify(n: i32) -> i32 {
  if (n < 0) {
    return -1;
  } else if (n == 0) {
    return 0;
  } else {
    return 1;
  }
}

fn MakeSix() -> i32 {
  // `returned var` names the object a later `return var;` returns.
  returned var result: i32 = 1;
  result *= 6;
  return var;
}

fn Run() -> i32 {
  // Declarations are statements: `var`, `let`, and local types and functions.
  var total: i32 = 0;
  let limit: i32 = 5;
  class Pair {
    var a: i32;
    var b: i32;
  }
  fn Add(p: Pair) -> i32 { return p.a + p.b; }

  // A `while` loop with `continue` and `break`.
  var i: i32 = 0;
  while (true) {
    i += 1;
    if (i == 2) {
      continue;
    }
    if (i > limit) {
      break;
    }
    total += i;
  }
  // Expression statements, assignment, and increment.
  Core.Print(total);
  total = Classify(-7);
  ++total;
  Core.Print(total);

  // `for` loops over an array and over a range.
  var sum: i32 = 0;
  let values: array(i32, 3) = (1, 2, 3);
  for (v: i32 in values) {
    sum += v;
  }
  for (k: i32 in Core.Range(4)) {
    sum += k;
  }
  Core.Print(sum);
  Core.Print(Add({.a = 2, .b = 3}) + MakeSix());
  return 0;
}
```

This prints `13`, `0`, `12`, and `11`.

A name declared in a nested block is not visible after it:

```carbon
fn F(b: bool) -> i32 {
  if (b) {
    var inner: i32 = 1;
    inner += 1;
  }
  return inner;
}
```

The toolchain reports ``name `inner` not found``. A function with a return
type must not let control reach the end of its body:

```carbon
fn F(b: bool) -> i32 {
  if (b) {
    return 1;
  }
}
```

This is rejected with
``missing `return` at end of function with declared return type``. In 0.1 the
same rule also applies after a `match` that is exhaustive without a `default`
arm (fork work item W-180).

A block on its own is not accepted as a statement, although the grammar of
proposal 162 includes it and the overview's second example uses it:

```carbon
fn Bar() {}
fn Baz() {}
fn Foo() {
  Bar();
  {
    Baz();
  }
}
```

The parser reads the `{` as the start of a struct literal and reports
``expected `.field: field_type` or `.field = value` `` (fork work item W-185).
Until that is resolved, a nested scope needs a statement that has a block, such
as `if (true) { ... }`.
````

Counts after: H2 3 → 4, dash items 2 → 10 (TOC plus seven list items), no
ordered items. Samples: P02 (design_docs_statements.carbon), R05, R06, R04.

### §2.3 docs/design/assignment.md

Edit 1 replaces line 161 (`_TODO_: Describe the rules for assignment in these
cases.`) with the text below; lines 163-164 ("See leads issue ... #686 ...")
stay after it.

````markdown
> **Fork status (2026-10-DD).** No accepted proposal yet states these rules,
> and leads issue 686 below is open. The 0.1 toolchain implements the
> following.

A tuple or a struct assigns element by element from a value of the same type,
including a tuple or struct literal; struct fields are matched by name, so
`s = {.b = 6, .a = 5};` assigns `.a` from `5`. A class whose fields are all
accessible assigns from a struct literal that names every field. A choice value
assigns as a whole.

```carbon
import Core library "io";

choice Light {
  Red,
  Green
}

class Point {
  var x: i32;
  var y: i32;
}

fn Run() -> i32 {
  // Tuples and structs assign element by element, from a literal or from
  // another object of the same type.
  var t: (i32, i32) = (1, 2);
  t = (3, 4);
  var s: {.a: i32, .b: i32} = {.a = 1, .b = 2};
  let other: {.a: i32, .b: i32} = {.a = 5, .b = 6};
  s = other;
  // A class assigns from a struct literal naming every field.
  var p: Point = {.x = 0, .y = 0};
  p = {.x = 7, .y = 8};
  // A choice value assigns as a whole.
  var light: Light = Light.Red;
  light = Light.Green;
  Core.Print(t.0 + t.1);
  Core.Print(s.a + s.b);
  Core.Print(p.x + p.y);
  match (light) {
    case .Red => { Core.Print(0); }
    case .Green => { Core.Print(1); }
  }
  // To exchange elements, copy the old value first.
  var old: (i32, i32) = t;
  t = (old.1, old.0);
  Core.Print(t.0);
  return 0;
}
```

This prints `7`, `11`, `15`, `1`, and `4`. It compiles only with the fork's
toolchain, where choice values are copyable; the upstream nightly reports
``cannot copy value of type `Light` ``.

Assigning one class object from another copies it, so the class must implement
`Core.Copy`, which a class does not do by default:

```carbon
class Point {
  var x: i32;
  var y: i32;
}

fn Reset(ref p: Point, q: Point) {
  p = q;
}
```

The toolchain reports ``cannot copy value of type `Point` ``. It also accepts a
struct literal for a class with `private` fields outside the class, which the
[`private` rule](classes.md#private-access) forbids (fork work item W-186).

The right-hand side is not copied before the assignment starts. In
`t = (t.1, t.0);` the literal's elements are
[value expressions](values.md#value-expressions) that still refer to `t`;
assigning `t.0` ends the lifetime of the value read from it, so its later use is
erroneous under the values design. The toolchain does not diagnose this: with
`t` holding `(1, 2)`, the statement leaves `(2, 2)`. Copy into a `var` first, as
the last lines of the example do.
````

Counts after: unchanged (no heading, no list item). Samples: P03
(design_docs_assignment.carbon, fork-only), R07, X01 (quote fixture for the
`(2, 2)` claim), PR-I (W-186), PR-M (field order).

### §2.4 docs/design/templates.md

Edit 1 replaces lines 22-27 with the **state T** text:

````markdown
## Status

> **Fork status (2026-10-DD).** Template generics are accepted: proposal 2200
> makes them part of Carbon, with the terminology of proposal 2138 and the
> name-lookup rules of question-for-leads issue 949 and proposal 989, and the
> [language overview](README.md#checked-and-template-parameters) summarizes the
> accepted design. The [overview](#overview) below is an older sketch, kept
> unchanged; where it and proposal 2200 differ, the proposal governs. Template
> constraints are fixed by fork decision F-010 (`template constraint`
> declarations, `require` validity blocks, and boolean predicates); the SC-1
> workstream implements them, and they are not in the toolchain this page
> describes. What the 0.1 toolchain implements is documented, with examples
> that compile, in [Templates in the 0.1 toolchain](#templates-in-the-01-toolchain).
````

At **state L** (SC-1 merged), the sentence "Template constraints are fixed ...
describes." becomes:

````markdown
> constraints are fixed by fork decision F-010 and specified in
> [Template constraints](generics/template_constraints.md), whose member
> requirements the toolchain implements.
````

(the block shows the sentence from its second word, re-wrapped inside the
status blockquote).

Edit 2 inserts after line 58 (the paragraph after the `Stack` example):

````markdown
> **Fork note (2026-10-DD).** `buf(T)` is illustrative; Carbon has no `buf`
> type, and the fork's heap buffer is `Core.Buf(T)` ([Slices](slices.md)). A
> class with a `template` parameter compiles in the 0.1 toolchain.
````

Edit 3 inserts after line 88 (the paragraph after the `Convert` example):

````markdown
> **Fork note (2026-10-DD).** Under the accepted
> [implicit conversion rules](expressions/implicit_conversions.md), `i32` does
> not implicitly convert to `f32`, so the toolchain rejects this instantiation
> with ``unable to monomorphize specific `Convert(i32, f32)` ``. The same
> function with an `i64` target compiles and runs, as in
> [Templates in the 0.1 toolchain](#templates-in-the-01-toolchain).
````

Edit 4 inserts after line 98 (the end of `### Overloading`):

````markdown
> **Fork note (2026-10-DD).** The 0.1 toolchain does not specialize templates
> by pattern matching. An [overload set](functions_overloading.md) can combine
> members for specific types with a member that has a template parameter; the
> set is resolved in declaration order (fork decision F-009).
````

Edit 5 appends after line 111 (at state L, after SC-1's replacement paragraph):

````markdown
## Templates in the 0.1 toolchain

The toolchain implements template parameters: a binding marked `template` in a
deduced parameter list (`[template T: type]`), in an explicit parameter list
(`template N: i32`), or in a class's parameter list
(`class Stack(template T: type)`). A function with a template parameter is
type-checked when it is called, once for each distinct template argument: member
access, conversions, and operators whose meaning depends on a template
parameter are resolved for the argument that the call supplies.

```carbon
import Core library "io";

class Point {
  var x: i32;
  var y: i32;
}

class Size {
  var x: i32;
  var y: i32;
  var depth: i32;
}

class Meters {
  var n: i32;
  impl as Core.ImplicitAs(i32) {
    fn Convert(self) -> i32 { return self.n; }
  }
}

// `p.x` and `p.y` are looked up in the type `T` that each call supplies,
// when the call is instantiated, not when `Sum` is defined.
fn Sum[template T: type](p: T) -> i32 {
  return p.x + p.y;
}

// The conversion and the operator are resolved per instantiation.
fn ToInt[template T: type](x: T) -> i32 {
  let n: i32 = x;
  return n + n;
}

// A deduced template parameter and an explicit one, as in the overview.
fn Convert[template T: type](source: T, template U: type) -> U {
  var converted: U = source;
  return converted;
}

// A template parameter of non-type type.
fn Scale(template N: i32, x: i32) -> i32 {
  return N * x;
}

fn Run() -> i32 {
  let a: Point = {.x = 1, .y = 2};
  let b: Size = {.x = 30, .y = 40, .depth = 0};
  Core.Print(Sum(a));
  Core.Print(Sum(b));
  let m: Meters = {.n = 6};
  Core.Print(ToInt(m));
  let wide: i64 = Convert(7 as i32, i64);
  Core.Print(wide as i32);
  Core.Print(Scale(3, 14));
  return 0;
}
```

This prints `3`, `70`, `12`, `7`, and `42`.

An instantiation that does not type-check is reported at the call, with the
reason as a note:

```carbon
class Empty {}

fn GetX[template T: type](p: T) -> i32 {
  return p.x;
}

fn Use(e: Empty) -> i32 {
  return GetX(e);
}
```

The toolchain reports ``unable to monomorphize specific `GetX(Empty)` ``, with
the note ``member name `x` not found in `Empty` ``. A checked parameter, without
`template`, is rejected at the function's definition instead, because a checked
generic's members come only from its constraint:

```carbon
fn GetX[T: type](p: T) -> i32 {
  return p.x;
}
```

This reports ``type `T` does not support qualified expressions``.

Limits of the 0.1 toolchain, each a filed fork work item:

-   Member lookup into a template parameter does not consult the parameter's
    constraint. Proposal 2200 looks a name up both in the argument type and in
    the interface constraint; the toolchain looks only in the argument type, so
    a member that the type provides only through an `impl` without `extend` is
    not found (W-183). Declaring it with `extend impl as HasArea` makes the
    call below compile.
-   A template function defined in one library and called from another stops
    the compiler during checking (W-014).
-   An interface constraint is satisfied only by types that implement the
    interface; a type with matching members but no `impl` is rejected with
    ``cannot convert type `Circle` into type implementing `HasArea` ``.
    Structural constraints are F-010's template constraints (see Status).
-   A `match` on a template-dependent value is not supported, so the
    [`match`-based rules](pattern_matching.md#templates) of pattern matching do
    not apply yet.

```carbon
interface HasArea {
  fn Area(self) -> i32;
}

class Square {
  var side: i32;
  impl as HasArea {
    fn Area(self) -> i32 { return self.side * self.side; }
  }
}

fn Report[template T: HasArea](s: T) -> i32 {
  return s.Area();
}

fn Use(q: Square) -> i32 {
  return Report(q);
}
```

This reports ``unable to monomorphize specific `Report(Square as HasArea)` ``
with the note ``member name `Area` not found in `Square` ``.
````

At state L the fourth list item stays and the third item's last sentence
becomes:

````markdown
    Structural constraints are F-010's
    [template constraints](generics/template_constraints.md).
````

Counts after: H2 3 → 4, H3 4, dash items 6 → 11 (TOC plus four list items), no
ordered items. Samples: P04 (design_docs_templates.carbon), R08, R10, R09; quote
fixture R11 (edit 3); probes PR-A, PR-D, PR-E, PR-J, PR-K, PR-N.

### §2.5 docs/design/metaprogramming.md

Edit 1 replaces lines 18-26 (the `## TODO` section including the PR 89
sentence) with:

````markdown
## Status

> **Fork status (2026-10-DD).** No accepted proposal designs Carbon
> metaprogramming. This page used to point to
> [proposal PR 89](https://github.com/carbon-language/carbon-lang/pull/89),
> which has no accepted record in this repository, and the 0.1 milestone
> defers the
> [long tail of metaprogramming features](/docs/project/milestones.md#features-explicitly-deferred-until-at-least-02)
> to at least 0.2. The [overview](#overview) below states the direction,
> unchanged. What the 0.1 toolchain provides is compile-time evaluation,
> documented in
> [Compile-time evaluation in the 0.1 toolchain](#compile-time-evaluation-in-the-01-toolchain);
> [templates](templates.md) are its other compile-time facility.
````

Edit 2 appends after line 32:

````markdown
## Compile-time evaluation in the 0.1 toolchain

The toolchain evaluates constant expressions during compilation wherever the
language needs a constant, such as an array bound, a type, or a template
argument. Two function modifiers extend this to calls; accepted proposals 7140
and 7697 and [function types](functions.md#function-types-and-values) use them
in examples, and no proposal of their own designs them yet:

-   an `eval fn` may be called during compilation when its arguments are
    constants, and may also be called at run time;
-   a `musteval fn` may only be called with constant arguments, so its result is
    always computed during compilation.

Compile-time evaluation runs ordinary function bodies, with control flow and
recursion, and can compute types, so an `eval fn` that returns `type` acts as a
type function:

```carbon
import Core library "io";

// An `eval fn` may be called during compilation, here for an array bound.
eval fn Square(n: i32) -> i32 { return n * n; }

var table: array(i32, Square(2)) = (1, 2, 3, 4);

// Compile-time evaluation can compute types, and may recurse.
eval fn IntOfWidth(wide: bool) -> type {
  if (wide) {
    return i64;
  }
  return i32;
}

eval fn Factorial(n: i32) -> i32 {
  if (n <= 1) {
    return 1;
  }
  return n * Factorial(n - 1);
}

var slots: array(i32, Factorial(3)) = (0, 0, 0, 0, 0, 6);

// A `musteval fn` may only be called with constant arguments.
musteval fn Twice(n: i32) -> i32 { return n * 2; }

fn Run() -> i32 {
  // An `eval fn` can also be called at run time.
  var n: i32 = 5;
  Core.Print(Square(n));
  Core.Print(table[3] + slots[5]);
  var big: IntOfWidth(true) = 1;
  big = big << 40;
  let small: IntOfWidth(false) = Twice(21);
  // `typeof` names the type of an expression.
  let copy: typeof(small) = small;
  Core.Print(copy);
  if (big > 1000) {
    Core.Print(1);
  }
  return 0;
}
```

This prints `25`, `10`, `42`, and `1`. A `musteval fn` with a runtime argument is
rejected:

```carbon
musteval fn Twice(n: i32) -> i32 { return n * 2; }

fn F(x: i32) -> i32 {
  return Twice(x);
}
```

with ``non-constant call to compile-time-only function``. A plain `fn` is never
evaluated during compilation:

```carbon
fn Three() -> i32 { return 3; }

var a: array(i32, Three()) = (0, 1, 2);
```

reports `array bound is not a constant`. A local compile-time binding is not yet
supported:

```carbon
fn F() -> i32 {
  let template N: i32 = 3;
  return N;
}
```

reports ``semantics TODO: `local generic `let` bindings are currently unsupported` ``
(fork work item W-031).

Other limits of the 0.1 toolchain: a `musteval fn` cannot yet pass its own
parameters to another `musteval fn` (pinned by
`toolchain/check/testdata/function/call/eval_musteval.carbon`); compile-time
recursion with no base case is not diagnosed, and the compiler runs out of stack
(fork work item W-184); `if` expressions and `and`/`or` are not supported
outside a function body (W-036). There is no syntax for reflection or code
generation, and no textual macros: the only macros are C++ object-like macros,
imported as constants ([Importing C/C++ macros](interoperability/macros.md)).
````

Counts after: H2 3 → 4, dash items 2 → 5 (TOC plus two items), no ordered items.
Samples: P05 (design_docs_compile_time.carbon), R12, R13, R14; probe PR-C.

### §2.6 docs/design/pattern_matching.md

Edit 1 replaces lines 718-721 (the placeholder paragraph) with:

````markdown
> **Fork status (2026-10-DD).** Proposal 2188 accepted the pattern rules that
> this section relies on and the [guard](#guards) syntax, and proposal 5164
> accepted their object semantics; the introductory prose and first example
> below are older and were not part of either proposal, and are kept unchanged.
> The fork implements `match`, and
> [`match` in the 0.1 toolchain](#match-in-the-01-toolchain) documents what
> compiles today. The first example does not: a `match` on a tuple holding `f32`
> values is not supported, and `Pi` is not declared.
````

Edit 2 inserts before line 823 (`### Refutable pattern bindings`), after the
`#### Guards` section:

````markdown
#### `match` in the 0.1 toolchain

The fork's toolchain implements the `match` statement. The upstream nightly does
not (it reports ``semantics TODO: `HandleMatchIntroducer` `` for any `match`), so
every example here needs the fork's toolchain. The implemented grammar is:

-   `match` `(` _expression_ `)` `{` _arm_ ... `}`, with at least one arm;
-   _arm_ ::= `case` _pattern_ [`if` `(` _expression_ `)`]? `=>` _block_
-   _arm_ ::= `default` [`if` `(` _expression_ `)`]? `=>` _block_

A guard's condition is parenthesized, as an `if` statement's is; the
unparenthesized guard of [Guards](#guards) is rejected with
``expected `(` after `if` ``.

The scrutinee may be of an integer type, `bool`, a choice type (including a
specific of a generic choice and an imported choice such as
`Core.Result(T, E)`), a tuple of those, or a struct type. Patterns are constant
integer and `bool` expressions; bindings `x: T`, `var x: T`, and, for a
reference scrutinee, `ref x: T`; `_`; tuple patterns; struct patterns with
designated fields (`.w = 0`, `.w = w: i32`) or shorthand fields (`w: i32`) and a
trailing `_` that discards the rest; and alternative patterns `.Name` and
`.Name(...)`, whose payload subpatterns are constants or bindings.

Arms are tried in order: the first arm whose pattern matches and whose guard, if
any, is true runs, with the pattern's bindings in scope in the guard and the
block; `default` matches every value. Exhaustiveness and usefulness are checked
as [specified above](#refutability-overlap-usefulness-and-exhaustiveness): a
`match` without an unguarded `default` arm must cover every alternative of a
choice, both `bool` values, or have an unguarded irrefutable arm (integer,
tuple, and struct scrutinees, whose expression patterns are never exhaustive);
a guarded arm never counts toward coverage; an arm that can never match is an
error.

```carbon
import Core library "io";

choice Shape {
  Circle(radius: i32),
  Rect(width: i32, height: i32),
  Empty
}

fn Area(s: Shape) -> i32 {
  // The arms cover every alternative, so no `default` is needed.
  match (s) {
    case .Circle(r: i32) => { return 3 * r * r; }
    case .Rect(w: i32, h: i32) => { return w * h; }
    case .Empty => { return 0; }
  }
  // Still required in 0.1; see the note on exhaustive `match` below.
  return -1;
}

fn Classify(n: i32) -> i32 {
  // Constant cases, a guarded binding, and the `default` an `i32` needs.
  match (n) {
    case 0 => { return 0; }
    case x: i32 if (x < 0) => { return -1; }
    default => { return 1; }
  }
}

fn Quadrant(p: (i32, i32)) -> i32 {
  match (p) {
    case (0, 0) => { return 0; }
    case (x: i32, y: i32) if (x > 0 and y > 0) => { return 1; }
    default => { return 2; }
  }
}

fn Width(r: {.w: i32, .h: i32}) -> i32 {
  // Struct patterns name fields; `_` discards the rest.
  match (r) {
    case {.w = 0, _} => { return -1; }
    case {.w = w: i32, .h = h: i32} => { return w * 10 + h; }
  }
  return -2;
}

fn Run() -> i32 {
  Core.Print(Area(Shape.Rect(3, 4)));
  Core.Print(Area(Shape.Empty));
  Core.Print(Classify(-5));
  Core.Print(Quadrant((2, 3)));
  Core.Print(Width({.w = 4, .h = 5}));
  return 0;
}
```

This prints `12`, `0`, `-1`, `1`, and `45`. The checks, each an error:

```carbon
choice Signal { Stop, Go, Wait }

fn F(s: Signal) -> i32 {
  match (s) {
    case .Stop => { return 0; }
    case .Go => { return 1; }
  }
  return 2;
}
```

reports
`` `match` on choice `Signal` has no `default` arm and does not cover alternative `.Wait` ``;

```carbon
fn F(n: i32) -> i32 {
  match (n) {
    case 0 => { return 0; }
    case 1 => { return 1; }
  }
  return 2;
}
```

reports
`` `match` on `i32` has no `default` arm and no `case` arm that matches every value ``;

```carbon
fn F(n: i32) -> i32 {
  match (n) {
    case x: i32 => { return x; }
    case 0 => { return 0; }
  }
  return 1;
}
```

reports
`` `case` pattern never matches; every value it can match is matched by a prior arm ``;

```carbon
fn F(b: bool) -> i32 {
  match (b) {
    case true => { return 1; }
    case false => { return 0; }
    default => { return 2; }
  }
  return 3;
}
```

reports
`` `default` arm never matches; every value of the scrutinee is matched by prior arms ``;
and the unparenthesized guard

```carbon
fn F(x: (i32, i32)) -> i32 {
  match (x) {
    case (m: i32, n: i32) if m + n < 5 => { return m - n; }
    default => { return 0; }
  }
}
```

reports ``expected `(` after `if` ``.

Not in the 0.1 toolchain, each a filed fork work item or a pinned
`semantics TODO` in `toolchain/check/testdata/match/`:

-   An exhaustive `match` without a `default` arm does not end control flow:
    the code after it is treated as reachable, which is why `Area` above ends
    with a `return`, and why `IsTrue` in
    [Refutability, overlap, usefulness, and exhaustiveness](#refutability-overlap-usefulness-and-exhaustiveness)
    is rejected (W-180).
-   An alternative pattern inside a tuple pattern or a payload subpattern is
    read as an expression, so the usefulness example above cannot be written
    yet (W-182).
-   A scrutinee of any other type, including floating-point types, `str`,
    classes, and template-dependent types, so the [Templates](#templates)
    rules do not apply yet; expression patterns that are not constants, such
    as a variable; compile-time bindings in a `case`; and `match` expressions.
-   A refutable pattern in a plain `var` declaration, such as `var 5 = n;`
    above, stops the compiler instead of being diagnosed (W-181).

```carbon
fn IsTrue(b: bool) -> bool {
  match (b) {
    case false => { return false; }
    case true => { return true; }
  }
}
```

reports ``missing `return` at end of function with declared return type``, and

```carbon
choice Flag { Off, On }

fn Both(a: Flag, b: Flag) -> bool {
  match ((a, b)) {
    case (.On, .On) => { return true; }
    default => { return false; }
  }
}
```

reports ``name `.Self` not found``; a `match` on `f64`

```carbon
fn F(x: f64) -> i32 {
  match (x) {
    default => { return 0; }
  }
}
```

reports ``semantics TODO: `match on unsupported scrutinee type` ``.
````

A diagnostic that starts or ends with a backtick is quoted in a double-backtick
span with one space inside each end, as above; the checker compares the
fixture's EXPECT-ERROR text with the page after collapsing whitespace.

Counts after: H4 10 → 11, dash items 112 → 120 (TOC plus seven list items),
ordered items unchanged. Samples: P06 (design_docs_match.carbon, fork-only),
R15-R22; probes PR-B, PR-D, PR-F, PR-L, PR-P.

### §2.7 docs/design/interoperability/README.md

Each `TODO:` heading keeps its level and loses the prefix; the TOC is
regenerated. Section texts:

**Line 156**, `### Importing C++ code (inline)`:

````markdown
### Importing C++ code (inline)

C++ source can also be written in a Carbon file. `import Cpp inline` followed by
a string literal, usually a block string literal `'''...'''` tagged `c++`,
compiles that source as if it were a header: its declarations join the `Cpp`
package exactly as a header's do, and it may `#include` headers itself. It is an
`import`, so it comes with the other imports, before any other declaration. The
`inline Cpp` declaration may instead appear among Carbon declarations, after any
`import Cpp`, and its C++ code can call the Carbon declarations above it through
the `Carbon` namespace.

```carbon
import Core library "io";

// C++ source in an import: its declarations join the `Cpp` package like a
// header's.
import Cpp inline '''c++
inline int Triple(int x) { return 3 * x; }
''';

fn Twice(n: i32) -> i32 { return n * 2; }

// An `inline Cpp` declaration may follow Carbon declarations, and its C++
// code can call them through the `Carbon` namespace.
inline Cpp '''c++
inline int TwicePlusOne(int n) { return Carbon::Twice(n) + 1; }
''';

fn Run() -> i32 {
  Core.Print(Cpp.Triple(14));
  Core.Print(Cpp.TwicePlusOne(20));
  return 0;
}
```

This prints `42` and `41`. The string literal's escape sequences are Carbon's
and are processed before C++ sees the text, so a C++ `"\n"` is written `"\\n"`,
or the whole block is written as a raw block string literal `#'''...'''#`. No
accepted proposal covers the inline forms; the toolchain parses both
(`toolchain/parse/handle_inline_decl.cpp`) and the tests in
`toolchain/check/testdata/interop/cpp/basics/inline/` pin them.
````

**Line 240**, `### Constructors`:

````markdown
### Constructors

A C++ constructor is a member of its class with the class's name, as in C++, and
is called with call syntax: `Cpp.Point.Point(1, 2)`. C++ overload resolution
chooses among the constructors and supplies default arguments
([Overload resolution](#overload-resolution)). A `var` with no initializer runs
the default constructor; initializing from another object of the class runs its
copy constructor; a constructor that is not `explicit` is an implicit
conversion from its parameter type; and the class's destructor runs when a
Carbon object of the class goes out of scope.

```carbon
import Core library "io";

import Cpp inline '''c++
inline int destroyed = 0;

struct Point {
  int x;
  int y;
  Point() : x(0), y(0) {}
  Point(int px, int py = 10) : x(px), y(py) {}
  ~Point() { ++destroyed; }
};

struct Meters {
  int n;
  Meters(int v) : n(v) {}
};

inline int Length(Meters m) { return m.n; }
''';

fn Make() -> i32 {
  // A constructor is called by its C++ name, as a member of its class; C++
  // overload resolution picks the constructor and fills default arguments.
  var a: Cpp.Point = Cpp.Point.Point(1, 2);
  var b: Cpp.Point = Cpp.Point.Point(3);
  // A `var` with no initializer runs the default constructor.
  var c: Cpp.Point;
  // Initializing from another object runs the copy constructor.
  var d: Cpp.Point = a;
  d.x = 100;
  return a.x + a.y + b.y + c.x + d.x;
}

fn Run() -> i32 {
  Core.Print(Make());
  // The four objects were destroyed when `Make` returned.
  Core.Print(Cpp.destroyed);
  // A non-`explicit` converting constructor is an implicit conversion.
  Core.Print(Cpp.Length(5));
  return 0;
}
```

This prints `113`, `4`, and `5`. An `explicit` constructor is not an implicit
conversion:

```carbon
import Cpp inline '''c++
struct Meters {
  int n;
  explicit Meters(int v) : n(v) {}
};
inline int Length(Meters m) { return m.n; }
''';

fn F() -> i32 {
  return Cpp.Length(5);
}
```

C++ overload resolution finds no viable `Length`, and the toolchain reports
`no matching function for call to 'Length'`.
````

**Line 242**, `### Struct literals`:

````markdown
### Struct literals

A Carbon struct literal initializes two kinds of C++ class in 0.1: an empty
struct literal `{}` initializes an aggregate with no fields, and a one-field
struct literal initializes a C++ union, naming the member to make active
([Unions](../unions.md), fork decision F-007). A C++ aggregate with fields is
built in C++, by a function or a constructor, and then used field by field.

```carbon
import Core library "io";

import Cpp inline '''c++
struct Empty {};
struct Pair {
  int first;
  int second;
};
union Number {
  int as_int;
  float as_float;
};
inline Pair MakePair(int a, int b) { return {a, b}; }
''';

fn Run() -> i32 {
  // An empty aggregate initializes from an empty struct literal.
  var unused e: Cpp.Empty = {};
  // A C++ union initializes from a one-field struct literal naming the
  // active member.
  var n: Cpp.Number = {.as_int = 41};
  // A non-empty aggregate is built in C++ and then used field by field.
  var p: Cpp.Pair = Cpp.MakePair(1, 2);
  p.second = n.as_int;
  Core.Print(p.first + p.second);
  return 0;
}
```

This prints `42`; the union initialization needs the fork's toolchain. A
struct literal with fields does not yet initialize a C++ aggregate:

```carbon
import Cpp inline '''c++
struct Pair {
  int first;
  int second;
};
''';

fn F() -> i32 {
  var p: Cpp.Pair = {.first = 1, .second = 2};
  return p.first;
}
```

The toolchain reports
``cannot implicitly convert expression of type `{.first: Core.IntLiteral, .second: Core.IntLiteral}` to `Cpp.Pair` ``
(fork work items W-048 and W-051).
````

**Line 244**, `## Accessing C++ classes, structs, and members`:

````markdown
## Accessing C++ classes, structs, and members

C++ classes and structs are Carbon types in the `Cpp` package, nested in `Cpp`
namespaces as in C++ (`Cpp.geo.Rect`). Their members use Carbon member access:
fields and member functions through an object (`r.Area()`, `r.tag`), and static
member functions and nested types through the class
(`Cpp.geo.Rect.Square(3)`, `Cpp.geo.Rect.Corner`). Members of a public base
class are found through a derived object, and a derived object converts to a
reference to its base.

```carbon
import Core library "io";

import Cpp inline '''c++
namespace geo {
class Rect {
 public:
  Rect(int w, int h) : w_(w), h_(h) {}
  static Rect Square(int s) { return Rect(s, s); }
  int Area() const { return w_ * h_; }
  void Scale(int k) { w_ *= k; h_ *= k; }
  struct Corner {
    int x;
    int y;
  };
  int tag = 7;

 private:
  int w_;
  int h_;
};

struct Shape {
  int id = 5;
  int Id() const { return id; }
};
struct Circle : Shape {
  int radius = 1;
};
inline int IdOf(const Shape& s) { return s.id; }
}  // namespace geo
''';

fn Run() -> i32 {
  // Namespaces, classes, and static member functions are members of `Cpp`.
  var r: Cpp.geo.Rect = Cpp.geo.Rect.Square(3);
  // Member functions and public fields use member access.
  Core.Print(r.Area());
  r.Scale(2);
  r.tag = r.Area();
  Core.Print(r.tag);
  // A nested class is a member of its enclosing class.
  var corner: Cpp.geo.Rect.Corner = Cpp.geo.Rect.Corner.Corner();
  corner.x = 4;
  Core.Print(corner.x);
  // Base-class members are found through a derived object, and a derived
  // object converts to a reference to its base.
  let c: Cpp.geo.Circle = Cpp.geo.Circle.Circle();
  Core.Print(c.Id() + c.radius);
  Core.Print(Cpp.geo.IdOf(c));
  return 0;
}
```

This prints `9`, `36`, `4`, `6`, and `5`. C++ access control applies:

```carbon
import Cpp inline '''c++
class Box {
 public:
  Box() : v_(1) {}

 private:
  int v_;
};
''';

fn F() -> i32 {
  var b: Cpp.Box = Cpp.Box.Box();
  return b.v_;
}
```

reports ``cannot access private member `v_` of type `Cpp.Box` ``. A `const`
member function can be called on any object, including a value; a member
function that is not `const` needs a reference expression, such as a `var`:

```carbon
import Cpp inline '''c++
struct Counter {
  int n = 1;
  void Inc() { ++n; }
};
''';

fn F() {
  let c: Cpp.Counter = Cpp.Counter.Counter();
  c.Inc();
}
```

Called on the value `c`, C++ overload resolution finds no viable `Inc`, and the
toolchain reports `no matching function for call to 'Inc'`. Multiple and virtual
inheritance are fork work item W-046.
````

**Line 246**, `## Accessing global variables`:

````markdown
## Accessing global variables

A C++ variable at namespace scope, such as an `inline` variable or an `extern`
declaration with its definition, is a durable reference expression in Carbon,
named through the `Cpp` package: it can be read, assigned, and updated in place.
A `const` variable can only be read.

```carbon
import Core library "io";

import Cpp inline '''c++
inline int counter = 40;
inline const int kLimit = 100;
extern int total;
int total = 7;
namespace config {
inline int verbosity = 1;
}
''';

fn Run() -> i32 {
  // A C++ variable is a durable reference: it can be read, assigned, and
  // updated in place.
  Cpp.counter += 2;
  Core.Print(Cpp.counter);
  Core.Print(Cpp.kLimit + Cpp.total);
  Cpp.config.verbosity = 3;
  Core.Print(Cpp.config.verbosity);
  return 0;
}
```

This prints `42`, `107`, and `3`. Assigning a `const` variable

```carbon
import Cpp inline '''c++
inline const int kLimit = 100;
''';

fn F() {
  Cpp.kLimit = 3;
}
```

reports `expression is not assignable`. C++ `thread_local` variables are
covered in [Threads, atomics, and the memory model](threads_and_atomics.md).
````

**Line 250**, `### Integers`:

````markdown
### Integers

Proposal 5448 fixes the mapping, and the toolchain implements it: C++ `intN_t`
and `uintN_t` are Carbon's `iN` and `uN`, and a C++ integer type that is the same
type as one of them on the target is that Carbon type. On 64-bit Linux,
`signed char`, `short`, `int`, and `long` are `i8`, `i16`, `i32`, and `i64`, the
unsigned types are the matching `uN`, and `size_t` is `u64`. `long long` and
`unsigned long long`, the same width as `long` but different C++ types, are the
distinct Carbon types `Cpp.long_long` and `Cpp.unsigned_long_long`, which `as`
converts to and from `i64` and `u64`. Every C++ integer type is also named in
the `Cpp` package, such as `Cpp.int` and `Cpp.long`.

```carbon
import Core library "io";

import Cpp inline '''c++
#include <cstddef>
#include <cstdint>
inline int NextInt(int x) { return x + 1; }
inline long NextLong(long x) { return x + 1; }
inline long long NextLongLong(long long x) { return x + 1; }
inline unsigned NextUnsigned(unsigned x) { return x + 1; }
inline short NextShort(short x) { return x + 1; }
inline std::int64_t NextInt64(std::int64_t x) { return x + 1; }
inline std::size_t NextSize(std::size_t x) { return x + 1; }
inline unsigned char NextByte(unsigned char x) { return x + 1; }
''';

fn Run() -> i32 {
  // `int`, `short`, `unsigned`, and the fixed-width types are Carbon's
  // integer types; on this target `long` is `i64` and `size_t` is `u64`.
  let a: i32 = Cpp.NextInt(1);
  let b: i16 = Cpp.NextShort(2);
  let c: u32 = Cpp.NextUnsigned(3);
  let d: i64 = Cpp.NextLong(4);
  let e: i64 = Cpp.NextInt64(5);
  let f: u64 = Cpp.NextSize(6);
  let g: u8 = Cpp.NextByte(7);
  // `long long` is the distinct type `Cpp.long_long`; `as` converts it.
  let h: i64 = Cpp.NextLongLong(8) as i64;
  Core.Print(a + (b as i32) + (c as i32));
  Core.Print((d + e + h) as i32);
  Core.Print((f as i32) + (g as i32));
  return 0;
}
```

This prints `9`, `20`, and `15`. A `Cpp.long_long` does not implicitly convert
to `i64`:

```carbon
import Cpp inline '''c++
inline long long NextLongLong(long long x) { return x + 1; }
''';

fn F() -> i64 {
  let h: i64 = Cpp.NextLongLong(8);
  return h;
}
```

reports ``cannot implicitly convert expression of type `Cpp.long_long` to `i64` ``.
````

**Line 275**, the H2 "Advanced type mapping: pointers, references, and
`const`" (its `TODO:` prefix dropped); its body, the TODO note at :277-278, is
replaced by:

````markdown
Proposal 6357 maps C++ object pointers, and the toolchain implements its table:
a C++ pointer that may be null, `T*`, is `Core.Optional(T*)` in Carbon, with
null as an empty `Optional`; a pointer annotated `_Nonnull` is a Carbon pointer
`T*`, which is never null; `const T*` is `Core.Optional(const T*)`; and `void*`
is `Core.Optional(Core.CppCompat.VoidBase*)`. References follow Carbon's
parameter forms (proposal 5434): a parameter of type `T&` is a `ref` parameter,
whose argument is marked `ref`; a `const T&` parameter takes a value; a function
returning `T&` returns a durable reference expression, which can be assigned;
and a field of reference type is reached through a pointer (`*s.r`, pinned by
`toolchain/check/testdata/interop/cpp/class/import/field.carbon`). A `const`
member function can be called on a value
([Accessing C++ classes, structs, and members](#accessing-c-classes-structs-and-members)).

```carbon
import Core library "io";

import Cpp inline '''c++
inline void Bump(int* _Nonnull p) { *p += 1; }
inline int* Find(bool found, int* p) { return found ? p : nullptr; }
inline void AddTen(int& r) { r += 10; }
inline int Read(const int& r) { return r; }
inline int ReadThrough(const int* _Nonnull p) { return *p; }

struct Holder {
  int v = 3;
  int& Ref() { return v; }
  int Get() const { return v; }
};
''';

fn Run() -> i32 {
  var n: i32 = 1;
  // `int* _Nonnull` is `i32*`.
  Cpp.Bump(&n);
  Core.Print(n);
  // A pointer that may be null is `Core.Optional(i32*)`.
  let found: Core.Optional(i32*) = Cpp.Find(true, &n);
  if (found.HasValue()) {
    Core.Print(*found.Get());
  }
  let missing: Core.Optional(i32*) = Cpp.Find(false, &n);
  if (not missing.HasValue()) {
    Core.Print(0);
  }
  // A non-`const` reference parameter takes a `ref` argument; a `const`
  // reference parameter takes a value.
  Cpp.AddTen(ref n);
  Core.Print(Cpp.Read(n));
  // `const int*` is `const i32*`, and `i32*` converts to it.
  Core.Print(Cpp.ReadThrough(&n));
  // A returned non-`const` reference is a durable reference expression.
  var h: Cpp.Holder = Cpp.Holder.Holder();
  h.Ref() = 8;
  Core.Print(h.Get());
  return 0;
}
```

This prints `2`, `2`, `0`, `12`, `12`, and `8`. A `T&` argument must be marked:

```carbon
import Cpp inline '''c++
inline void AddTen(int& r) { r += 10; }
''';

fn F() -> i32 {
  var n: i32 = 1;
  Cpp.AddTen(n);
  return n;
}
```

reports ``argument to `ref` parameter not marked with `ref` ``.
````

**New section**, inserted before the operator section (after the section on
`std::span` and `Core.Slice`, which ends at line 348):

````markdown
## Threads, atomics, and the memory model

Carbon 0.1 uses C++'s threads, atomics, and synchronization, through interop,
under the C++ memory model: a Carbon function runs on a `std::thread`, a Carbon
variable can have a `std::atomic` type, and C++ locks order Carbon accesses as
they order C++ ones. The contract is specified in
[Threads, atomics, and the memory model](threads_and_atomics.md) (fork decision
F-008).
````

**Line 350**, `## The operator interoperability model`:

````markdown
## The operator interoperability model

Carbon defines operators by implementing interfaces, and C++ defines them as
functions. The [language overview](../README.md#operator-overloading-1) describes
a mapping in both directions: a C++ operator overload makes the type usable with
the corresponding Carbon operator, and a Carbon interface implementation makes
the C++ operator available. The 0.1 toolchain implements the first direction:
a Carbon operator expression with a C++ operand looks up the C++ operator
functions, members and non-members, and resolves among them with C++ overload
resolution (proposal 6254, "Operator calls"). Imported this way are the binary
arithmetic, bitwise, shift, and relational operators, `==` and `!=`, compound
assignment, indexing, unary `-`, prefix `++` and `--`, and `^x` for C++'s
`operator~` (pinned by `toolchain/check/testdata/interop/cpp/operators/`).

```carbon
import Core library "io";

import Cpp inline '''c++
struct Money {
  int cents;
  static Money Make(int c) { return Money{c}; }
  Money operator-() const { return Money{-cents}; }
  friend Money operator+(Money a, Money b) { return Money{a.cents + b.cents}; }
  friend Money& operator+=(Money& a, Money b) {
    a.cents += b.cents;
    return a;
  }
  friend bool operator==(Money a, Money b) { return a.cents == b.cents; }
  friend bool operator<(Money a, Money b) { return a.cents < b.cents; }
};
''';

fn Run() -> i32 {
  var a: Cpp.Money = Cpp.Money.Make(30);
  let b: Cpp.Money = Cpp.Money.Make(12);
  // Carbon operator syntax calls the C++ operators that C++ overload
  // resolution selects.
  var c: Cpp.Money = a + b;
  Core.Print(c.cents);
  c += a;
  Core.Print((-c).cents);
  if (a == Cpp.Money.Make(30) and b < a) {
    Core.Print(1);
  }
  return 0;
}
```

This prints `42`, `-72`, and `1`. Not imported in 0.1 (fork work item W-045):
`operator=`, C++20's rewritten comparisons (`!=` from `==`, ordering from
`<=>`), operators whose result is not `bool` where Carbon needs a `bool`, unary
`+` and `!`, `->`, unary `*` and `&`, `&&`, and `||`. Assignment from an
`int` therefore fails:

```carbon
import Cpp inline '''c++
struct Cell {
  int value;
  static Cell Make(int n) { return Cell{n}; }
  Cell& operator=(int n) {
    value = n;
    return *this;
  }
};
''';

fn F() -> i32 {
  var c: Cpp.Cell = Cpp.Cell.Make(1);
  c = 42;
  return c.value;
}
```

with ``cannot implicitly convert expression of type `Core.IntLiteral` to `Cpp.Cell` ``.
The other direction is not implemented: a Carbon type's operator interface
implementations are not exported as C++ operators (fork work item W-054).
````

The design README has two `### Operator overloading` headings: :3372 (Carbon's
own operators, anchor `operator-overloading`) and :3657 (the interoperability
subsection that describes the two-way mapping, anchor
`operator-overloading-1`, as check-links computes duplicate anchors). The link
targets the second.

Counts after: H2 13 → 14 (the threads section), H3 16, dash items 37 → 38 (TOC
entry for the new H2; TODO entries renamed, not added), ordered 3; the 18
`TODO` lines of §0.1 row 6 drop to 1 (the prose at :286, category C). Samples:
P07-P14 (programs design_docs_cpp_inline, _constructors, _struct_literals,
_members, _globals, _integers, _pointers, _operators; P09 fork-only), R23-R30;
probes PR-G, PR-H, PR-O, PR-Q.

### §2.8 docs/design/interoperability/threads_and_atomics.md (new page)

The page carries the license comment and the table-of-contents marker lines of
its sibling interoperability/README.md (copied from that file, lines 3-7 and the
two marker lines around its table; the hook fills the table). Its text after
the title:

````markdown
## Overview

Carbon 0.1 has no threads, atomics, or synchronization of its own. A Carbon
program uses C++'s: `std::thread`, `std::atomic`, `std::mutex`, and the rest of
the C++ standard library's threading support are imported like any other C++
API, and they apply to Carbon code with their C++ meaning. This page states that
contract. It is fixed by fork decision F-008 (2026-07-19,
[decision log](/fork/decision-log.md)), whose design paper is
[fork/design-sprint/threading-atomics.md](/fork/design-sprint/threading-atomics.md);
Carbon-native threading is deferred to at least 0.2
([milestones](/docs/project/milestones.md#features-explicitly-deferred-until-at-least-02)).

## The memory-model contract

1.  Carbon 0.1 adopts the C++ memory model unchanged (C++20 `[intro.races]`
    and `[atomics.order]`). The interoperability goals require compatibility
    with it
    ([Compatibility with the C++ memory model](philosophy_and_goals.md#compatibility-with-the-c-memory-model)),
    and the [FAQ](/docs/project/faq.md#what-is-carbons-memory-model) commits
    Carbon to matching it closely.
2.  Ordinary Carbon accesses are C++ non-atomic accesses. Two conflicting
    accesses from different threads, at least one a write and not both atomic,
    with no happens-before ordering between them, are a data race, and a data
    race is undefined behavior, as in C++. The 0.1 toolchain does not detect
    data races; data-race safety belongs to the [safety design](../safety/README.md).
3.  Atomicity is a property of an object's type, and the atomic types come from
    C++: `Cpp.std.atomic(T)` is `std::atomic<T>`. Carbon 0.1 has no per-access
    atomic syntax and no `volatile`.
4.  Synchronization composes across the language boundary: a happens-before
    edge established by a C++ atomic operation, mutex, or condition variable
    orders Carbon accesses exactly as it orders C++ accesses. In a compilation
    that imports C++, the toolchain lowers the Carbon code into the same LLVM
    module as the C++ code (`toolchain/lower/context.cpp`, the `llvm_module_`
    initializer), so both use the same atomic instructions.
5.  Any thread may run Carbon code. Carbon functions are ordinary native
    functions with no thread affinity: a `std::thread` can run a Carbon function
    directly, and C++ code can call Carbon functions from threads it started.
    C++ `thread_local` variables are usable from Carbon, each thread seeing its
    own; Carbon has no thread-local storage class of its own in 0.1.
6.  C++ destructors run at Carbon scope exit, so the guards `std::lock_guard`
    and `std::unique_lock` lock and unlock as they do in C++, and are the
    intended locking style.
7.  Not in 0.1: Carbon-native threads, atomics, and async; guarantees for signal
    handlers; C `_Atomic` interop. A C++ exception thrown by a threading API
    never unwinds a Carbon frame ([Error handling](../error_handling.md)).

## In the 0.1 toolchain

```carbon
import Core library "io";
import Cpp library "<atomic>";
import Cpp library "<mutex>";
import Cpp library "<thread>";

import Cpp inline '''c++
inline thread_local int per_thread = 0;
''';

// Atomicity is a property of the object's type, an imported C++ type.
var hits: Cpp.std.atomic(i32);
// An ordinary Carbon variable, protected by a C++ mutex.
var total: i32 = 0;
var total_mutex: Cpp.std.mutex;

fn Work() {
  hits.fetch_add(1);
  Cpp.per_thread += 5;
  // The guard's C++ destructor unlocks the mutex at Carbon scope exit.
  var unused lock: Cpp.std.lock_guard(Cpp.std.mutex) =
      Cpp.std.lock_guard(Cpp.std.mutex).lock_guard(ref total_mutex);
  total += Cpp.per_thread;
}

fn Run() -> i32 {
  Cpp.per_thread = 100;
  // A `std::thread` runs a Carbon function directly.
  var a: Cpp.std.thread = Cpp.std.thread.thread(Work);
  var b: Cpp.std.thread = Cpp.std.thread.thread(Work);
  a.join();
  b.join();
  // Each thread saw its own `per_thread`, starting at zero.
  Core.Print(hits.load());
  Core.Print(total);
  Core.Print(Cpp.per_thread);
  return 0;
}
```

This prints `2`, `10`, and `100`: both threads ran `Work`, each saw its own
`per_thread` starting at zero, and the main thread's copy kept `100`. The fork's
conformance programs `interop/cpp_threading_atomics.carbon`,
`interop/cpp_thread_carbon_fn_diff.carbon` (a `std::thread` constructed on a
Carbon function), `interop/cpp_atomic_carbon_class_diff.carbon` (a
`std::atomic` of an exported Carbon class with only scalar fields),
`interop/cpp_atomic_global_counter_diff.carbon` (a Carbon global of type
`Cpp.std.atomic(i64)` bumped from threads that C++ started),
`interop/cpp_thread_mutex_raii.carbon`, and
`interop/cpp_thread_condvar_diff.carbon` exercise the contract; all six pass.

## Alternatives considered

F-008 compared four options (the design paper's "Options"): documenting the
contract while leaving three toolchain defects unfixed; fixing the defects (the
choice: `std::thread` on a Carbon function, a Carbon global of a C++ template
specialization type, and `std::atomic` of a Carbon class, all fixed in the F8
slices); a `Core.Sync` library veneer over the C++ types; and native Carbon
atomics. The veneer and native atomics were rejected for 0.1 as new design ahead
of the 0.2 concurrency work.

## References

-   Fork decision F-008, [decision log](/fork/decision-log.md)
-   [fork/design-sprint/threading-atomics.md](/fork/design-sprint/threading-atomics.md)
-   Proposal
    [#175: C++ interoperability goals](/proposals/p000175-c-interoperability-goals.md)
````

The title line is `# Threads, atomics, and the memory model`. Before writing
"Alternatives considered", the writer opens fork/design-sprint/threading-
atomics.md's "Options" section and the F-008 entry (fork/decision-log.md
:1034-1041) and corrects the four-option summary to their exact names; the
ordered list keeps exactly seven items. Counts: new file; H1 1, H2 5, ordered 7,
dash 3 plus the TOC's. Sample: P16 (design_docs_cpp_threads.carbon).

### §2.9 docs/design/README.md

**Item 1, `### Enums` (:3815-3817).** The body `> **TODO**` becomes:

````markdown
C++ enumerations are imported as Carbon types in the `Cpp` package. An
enumerator is a member of its enumeration (`Cpp.Color.kGreen`); an unscoped
enumeration's enumerators are also members of the enclosing scope, as in C++
(`Cpp.kHigh`); values compare with `==`; and `as` converts an enumerator of an
enumeration with a fixed underlying type to that integer type. Carbon's own
enumerated types are [choice types](#choice-types) without payloads.

```carbon
import Core library "io";

import Cpp inline '''c++
enum class Color : int { kRed, kGreen = 5, kBlue };
enum Level : int { kLow = 1, kHigh = 2 };
inline bool IsGreen(Color c) { return c == Color::kGreen; }
''';

fn Run() -> i32 {
  // Enumerators are members of the enumeration; `as` converts an
  // enumerator to its underlying integer type.
  let c: Cpp.Color = Cpp.Color.kGreen;
  Core.Print(c as i32);
  if (Cpp.IsGreen(c) and c == Cpp.Color.kGreen) {
    Core.Print(1);
  }
  // An unscoped enumeration's enumerators are also members of the enclosing
  // scope, as in C++.
  Core.Print((Cpp.kHigh as i32) + (Cpp.Level.kLow as i32));
  return 0;
}
```

This prints `5`, `1`, and `3`. No accepted proposal covers C++ enumerations;
this is the 0.1 toolchain's behavior (fork, 2026-10-DD), pinned by
`toolchain/check/testdata/interop/cpp/enum/`.
````

**Item 2, `### Metaprogramming` (:3909-3916).** The note at :3911-3912 becomes
the block below; the paragraph at :3914-3916 and the References line stay.

````markdown
> **Note (fork, 2026-10-DD):** Compile-time evaluation is implemented in 0.1,
> with the `eval fn` and `musteval fn` forms; [Metaprogramming](metaprogramming.md)
> gives its status.
````

**Item 3, the template-constraints note (:2890).** State T:

````markdown
> **Note (fork, 2026-10-DD):** Template constraints are fixed by fork decision
> [F-010](/fork/decision-log.md): `template constraint` declarations with
> member requirements, `require` validity blocks, and boolean predicates;
> [Templates](templates.md#status) gives their status.
````

State L replaces the last clause, from "[Templates]", with
`[Template constraints](generics/template_constraints.md) specifies them.`

**Item 4, the three `> **TODO:**` bodies at :3988, :3992 and :3996** become,
in order:

````markdown
> **Note (fork, 2026-10-DD):** No abstract-machine design exists yet. In 0.1,
> Carbon code runs under the C++ memory model; see
> [Threads, atomics, and the memory model](interoperability/threads_and_atomics.md).
````

````markdown
> **Note (fork, 2026-10-DD):** Coroutines are outside the 0.1 milestone
> ([why](/docs/project/milestones.md#why-are-coroutines-and-async-in-this-milestone));
> there is no design and no toolchain support.
````

````markdown
> **Note (fork, 2026-10-DD):** Carbon-native threading is deferred to at least
> 0.2. In 0.1, concurrency is C++'s; see
> [Threads, atomics, and the memory model](interoperability/threads_and_atomics.md).
````

**Item 5, four cohesion notes**, each a new blockquote directly after an
existing provisional note, which stays. After :1037-1038 (Patterns):

````markdown
> **Fork note (2026-10-DD):** proposal 2188 has since accepted the pattern
> design; see [Pattern matching](pattern_matching.md).
````

After :3586-3587 (Importing and `#include`):

````markdown
> **Fork note (2026-10-DD):** proposal 6358 has since accepted the import
> design; see
> [Importing C++ APIs into Carbon](interoperability/README.md#importing-c-apis-into-carbon).
````

After :3659-3660 (the interop Operator overloading section):

````markdown
> **Fork note (2026-10-DD):** proposal 6254 fixes how a call to a C++ operator
> is resolved; the 0.1 status of both directions is in
> [The operator interoperability model](interoperability/README.md#the-operator-interoperability-model).
````

After :3733-3734 (Standard types):

````markdown
> **Fork note (2026-10-DD):** proposal 5448 has since accepted this mapping;
> see [Integers](interoperability/README.md#integers).
````

Counts after: no heading or list change in README.md (the notes are
blockquotes; the Enums sample is a fenced block). Sample: P15
(design_docs_cpp_enums.carbon).

### §2.10 code_and_name_organization/README.md and expressions/comparison_operators.md

After code_and_name_organization/README.md line 772 (the end of the
`#### Aliasing` example):

````markdown
> **Fork note (2026-10-DD):** The 0.1 toolchain does not accept a declaration
> through an alias, such as `TI.RawData` above; see
> [Aliases in the 0.1 toolchain](/docs/design/aliases.md#aliases-in-the-01-toolchain).
````

In expressions/comparison_operators.md:476-477, `**TODO:**` becomes
`**Future work:**` (the sentence stays), followed by:

````markdown
> **Fork status (2026-10-DD):** Not designed. In 0.1, the comparison
> interfaces' functions return `bool`
> (`core/prelude/operators/comparison.carbon`), and a C++ comparison operator
> whose result is not `bool` is not usable from Carbon (fork work item W-045).
````

Counts after: unchanged in both files.

### §2.11 Conformance programs (commit 1 and commit 2)

Delete fork/conformance/programs/project/design_docs_placeholders.carbon. Add
the sixteen programs below, each: the three-line license comment, a blank line,
then

```text
// CONFORMANCE-BULLET: Goal: design docs documented, cohesive, understandable without placeholders
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   <one line per expected output line>
//
// Transcribed from <page>, section "<heading>": the code after this comment
// block is that page's code block byte for byte
// (fork/designdocs/check_samples.py, rulebook R27). Expected output derived by
// hand in fork/designdocs/plan.md section 4 (R16(d)). <Runs on this fork's
// toolchain and on the upstream nightly. | Fork-only: the upstream nightly
// rejects it (see the plan's section 4).> A PASS shows the documented sample
// runs as documented; the bullet itself is arbitrated by document review.
```

followed by a blank line and the sample body. The header was generated and run
through the real runner for this plan (§4.1): all sixteen PASS on the fork
toolchain; on the nightly, thirteen PASS and the three fork-only programs fail
to compile, as labelled.

| Program | Sample | Page, section | EXPECT-STDOUT | Nightly |
| --- | --- | --- | --- | --- |
| design_docs_aliases.carbon | P01 | aliases.md, Aliases in the 0.1 toolchain | 3 7 304 20 6 | runs |
| design_docs_statements.carbon | P02 | blocks_and_statements.md, Statements in the 0.1 toolchain | 13 0 12 11 | runs |
| design_docs_assignment.carbon | P03 | assignment.md, Tuples, structs, choice types, and data classes | 7 11 15 1 4 | fork-only |
| design_docs_templates.carbon | P04 | templates.md, Templates in the 0.1 toolchain | 3 70 12 7 42 | runs |
| design_docs_compile_time.carbon | P05 | metaprogramming.md, Compile-time evaluation in the 0.1 toolchain | 25 10 42 1 | runs |
| design_docs_match.carbon | P06 | pattern_matching.md, `match` in the 0.1 toolchain | 12 0 -1 1 45 | fork-only |
| design_docs_cpp_inline.carbon | P07 | interoperability/README.md, Importing C++ code (inline) | 42 41 | runs |
| design_docs_cpp_constructors.carbon | P08 | interoperability/README.md, Constructors | 113 4 5 | runs |
| design_docs_cpp_struct_literals.carbon | P09 | interoperability/README.md, Struct literals | 42 | fork-only |
| design_docs_cpp_members.carbon | P10 | interoperability/README.md, Accessing C++ classes, structs, and members | 9 36 4 6 5 | runs |
| design_docs_cpp_globals.carbon | P11 | interoperability/README.md, Accessing global variables | 42 107 3 | runs |
| design_docs_cpp_integers.carbon | P12 | interoperability/README.md, Integers | 9 20 15 | runs |
| design_docs_cpp_pointers.carbon | P13 | interoperability/README.md, Advanced type mapping: pointers, references, and `const` | 2 2 0 12 12 8 | runs |
| design_docs_cpp_operators.carbon | P14 | interoperability/README.md, The operator interoperability model | 42 -72 1 | runs |
| design_docs_cpp_enums.carbon | P15 | README.md, Enums | 5 1 3 | runs |
| design_docs_cpp_threads.carbon | P16 | interoperability/threads_and_atomics.md, In the 0.1 toolchain | 2 10 100 | runs |

Then `python3 fork/conformance/runner.py --update-readme-table` (the stub's
row goes, sixteen rows come) and `--self-test` (R7: the bullet string above is
character-for-character the gap table's). No other program changes.

### §2.12 Fixtures and the checker (commit 1, extended in commit 2)

**Fixtures** live in fork/designdocs/samples/<id>.carbon: the license comment, a
blank line, `// DESIGN-DOCS-SAMPLE: <page>, "<section>", <block|quote>`, then
`// EXPECT-ERROR: <message>` (the text after `error:` on the first error line)
or `// EXPECT-STDOUT:` lines in the runner's format, then for a quote fixture
`// QUOTE: <text>`, a blank line, and the body. The thirty-one fixtures and
their pinned messages are the R and X rows of §4.1. R11 and X01 are the quote
fixtures: R11's QUOTE is its own EXPECT-ERROR message, which the edit 3 note of
§2.4 quotes in templates.md's "Functions with template parameters"; X01's QUOTE
is the statement it runs, which §2.3 quotes in assignment.md's "Tuples,
structs, choice types, and data classes". Their bodies:

```carbon
fn Convert[template T: type](source: T, template U: type) -> U {
  var converted: U = source;
  return converted;
}

fn Foo(i: i32) -> f32 {
  return Convert(i, f32);
}
```

```carbon
import Core library "io";

fn Run() -> i32 {
  var t: (i32, i32) = (1, 2);
  t = (t.1, t.0);
  Core.Print(t.0);
  Core.Print(t.1);
  return 0;
}
```

**fork/designdocs/check_samples.py** (license docstring as in
fork/evaluator/check_samples.py; ruff-clean; `main()` returns the status):

1.  `SAMPLES`: an ordered table of (page, section heading, kind, target) for
    every mapped block and quote, in page order, covering §2.1-§2.9. A section
    is the text between a heading line whose text equals the table's heading
    and the next heading of any level; blocks are fenced `carbon` blocks at
    the first column.
2.  Program check: each `program` block equals the target program's text
    after its leading comment block (EV-1's `strip_leading_comments`).
3.  Fixture check: each `block` fixture's body equals the page block; every
    fixture's EXPECT-ERROR message (or QUOTE) occurs in its section's prose
    after collapsing all whitespace runs to one space on both sides.
4.  Count check: the number of `carbon` blocks in each mapped section equals
    the number the table maps there (no unmapped block in a DD-1 section).
5.  W2 rule over docs/design/ (fence-aware): (a) the boilerplate regex
    `skeletal\s+design|it\s+is\s+a\s+placeholder|should\s+not\s+be\s+treated\s+as\s+accepted|Please\s+feel\s+welcome\s+to\s+rewrite`
    over each file's whole text; (b) a heading whose text starts with `TODO`;
    (c) a section whose paragraphs (split on blank or bare `>` lines) all start
    with a TODO marker (`^(>\s*)?[*_]*TODO`) or with `See` or `> References`, at
    least one being a TODO marker. `ALLOWLIST` holds (README.md, "Lifetime and
    move semantics", PR 53) and (expressions/arithmetic.md, "Strings", PR 55) at
    state T and is empty at state L; an allowlisted entry that no longer hits is
    itself an error (so the list cannot go stale).
6.  `--toolchain PATH`: for each fixture, `PATH compile --output=<tmp>
    --output-last-input-only <fixture>`; an EXPECT-ERROR fixture must exit
    non-zero with its first `error:` line's message equal to the pin; an
    EXPECT-STDOUT fixture must compile, link (`PATH link`), run with exit 0,
    and print exactly the pinned lines. `XDG_CACHE_HOME` is honored from the
    environment.
7.  Output: one line per error, then a summary (`N program blocks, M fixtures,
    W2 hits`); exit 1 on any error.

The W2 rule as specified found the 36 hits of §0.1c at 162c7e839 (prototype run
for this plan); after commit 3 it must find exactly the two allowlisted ones.

### §2.13 State-L texts outside docs/design (integration commit)

In docs/guides/tutorial.md (EV-1's, PR 54), the sentence at :476-478 "The
constructor call, C++ method calls and `import Cpp inline` are toolchain
behavior whose design sections are still placeholders." becomes:

````markdown
The constructor call, C++ member access, and `import Cpp inline` are
documented, with the 0.1 toolchain's behavior, in the interoperability design's
[Constructors](/docs/design/interoperability/README.md#constructors),
[Accessing C++ classes, structs, and members](/docs/design/interoperability/README.md#accessing-c-classes-structs-and-members),
and [Importing C++ code (inline)](/docs/design/interoperability/README.md#importing-c-code-inline)
sections.
````

In docs/guides/evaluator_faq.md (PR 54) :372-373, "and the design documents
note their own placeholders" becomes "and the design documents state their own
status". EV-1's fork/evaluator/check_samples.py compares tutorial code blocks
only, so neither sentence affects it; the writer runs it after the edit.

### §2.14 Fork records (discharge commit; §8.5 spells them)

fork/inventory/work-items.json, fork/gap-analysis.md (rows 70 and 91, header),
fork/decision-log.md (one entry), fork/ORCHESTRATION.md (stamp, branch row, id
reservation), and this plan's "Landed notes".

## §3 Commits (one PR, R29(b): "DD-1: design docs without placeholders")

-   **Plan:** "DD-1 plan (rev 1): ..." (this commit), then the review folds as
    revision two.
-   **DD-1 (1/4): language pages** — §2.1-§2.6 and §2.10, programs P01-P06,
    their fixtures, the checker with the language-page table, the stub deleted,
    the conformance README table regenerated.
-   **DD-1 (2/4): interoperability** — §2.7, §2.8, item 1 of §2.9, programs
    P07-P16, their fixtures, the checker table extended.
-   **DD-1 (3/4): design README notes** — items 2-5 of §2.9; the W2 rule now
    finds only the two allowlisted hits.
-   **DD-1 (4/4): discharge** — §2.14 and §8.5-§8.9.
-   **Review folds** (document reviews, implementation review), each its own
    commit with the dispositions in its message.
-   **Integration (state L)** — merge trunk after OP-1; §0.2's conflicts; the
    state-L texts of §2.4, §2.9 item 3 and §2.13; the empty allowlist; the
    re-measure of §8.1.

Every commit: author `jmann345 <jerrymannstan@gmail.com>`, committer `Claude
<noreply@anthropic.com>`, explicit paths only (R20), the session trailers; the
message records the prek fixpoint, the R31 counts, `--self-test`, the checker
(with `--toolchain`), and the local conformance totals.

## §4 The checklist, executed against the toolchain

### §4.1 Samples and fixtures (one row per claim; measured 2026-10-13)

Command for every row (the probe harness used for this plan, equivalent to the
runner's single-file steps): `carbon compile --output=<o>
--output-last-input-only <file>`, then for RUNS `carbon link --output=<bin> <o>`
and run `<bin>`, with `XDG_CACHE_HOME` set to a scratch directory. "fork" is
`0.0.0-0.dev+0bdce60a5`, "nightly" is `0.0.0-0.nightly.2026.10.12+62f1cc6`. A
REJECTS cell shows the message after `error:` on the first error line.

| Id | Page, section | Fork | Nightly |
| --- | --- | --- | --- |
| P01 (`P01_aliases.carbon`) | aliases.md, Aliases in the 0.1 toolchain | RUNS, exit 0, prints `3 7 304 20 6` | RUNS, exit 0, prints `3 7 304 20 6` |
| P02 (`P02_statements.carbon`) | blocks_and_statements.md, Statements in the 0.1 toolchain | RUNS, exit 0, prints `13 0 12 11` | RUNS, exit 0, prints `13 0 12 11` |
| P03 (`P03_assignment.carbon`) | assignment.md, Tuples, structs, choice types, and data classes | RUNS, exit 0, prints `7 11 15 1 4` | REJECTS: `` cannot copy value of type `Light` `` |
| P04 (`P04_templates.carbon`) | templates.md, Templates in the 0.1 toolchain | RUNS, exit 0, prints `3 70 12 7 42` | RUNS, exit 0, prints `3 70 12 7 42` |
| P05 (`P05_compile_time.carbon`) | metaprogramming.md, Compile-time evaluation in the 0.1 toolchain | RUNS, exit 0, prints `25 10 42 1` | RUNS, exit 0, prints `25 10 42 1` |
| P06 (`P06_match.carbon`) | pattern_matching.md, `match` in the 0.1 toolchain | RUNS, exit 0, prints `12 0 -1 1 45` | REJECTS: `` semantics TODO: `choice alternatives with parameters are not yet supported` `` |
| P07 (`P07_cpp_inline.carbon`) | interop README, Importing C++ code (inline) | RUNS, exit 0, prints `42 41` | RUNS, exit 0, prints `42 41` |
| P08 (`P08_cpp_constructors.carbon`) | interop README, Constructors | RUNS, exit 0, prints `113 4 5` | RUNS, exit 0, prints `113 4 5` |
| P09 (`P09_cpp_struct_literals.carbon`) | interop README, Struct literals | RUNS, exit 0, prints `42` | REJECTS: `` cannot implicitly convert expression of type `{.as_int: Core.IntLiteral}` to `Cpp.Number` `` |
| P10 (`P10_cpp_members.carbon`) | interop README, Accessing C++ classes, structs, and members | RUNS, exit 0, prints `9 36 4 6 5` | RUNS, exit 0, prints `9 36 4 6 5` |
| P11 (`P11_cpp_globals.carbon`) | interop README, Accessing global variables | RUNS, exit 0, prints `42 107 3` | RUNS, exit 0, prints `42 107 3` |
| P12 (`P12_cpp_integers.carbon`) | interop README, Integers | RUNS, exit 0, prints `9 20 15` | RUNS, exit 0, prints `9 20 15` |
| P13 (`P13_cpp_pointers.carbon`) | interop README, Advanced type mapping | RUNS, exit 0, prints `2 2 0 12 12 8` | RUNS, exit 0, prints `2 2 0 12 12 8` |
| P14 (`P14_cpp_operators.carbon`) | interop README, The operator interoperability model | RUNS, exit 0, prints `42 -72 1` | RUNS, exit 0, prints `42 -72 1` |
| P15 (`P15_cpp_enums.carbon`) | README.md, Enums | RUNS, exit 0, prints `5 1 3` | RUNS, exit 0, prints `5 1 3` |
| P16 (`P16_cpp_threads.carbon`) | threads_and_atomics.md, In the 0.1 toolchain | RUNS, exit 0, prints `2 10 100` | RUNS, exit 0, prints `2 10 100` |
| R01 (`R01_alias_runtime.carbon`) | aliases.md | REJECTS: `` alias refers to a runtime value `` | REJECTS: `` alias refers to a runtime value `` |
| R02 (`R02_alias_params.carbon`) | aliases.md | REJECTS: `` `alias` declaration cannot have parameters `` | REJECTS: `` `alias` declaration cannot have parameters `` |
| R03 (`R03_alias_decl_scope.carbon`) | aliases.md (and the code-organization note) | REJECTS: `` name qualifiers are only allowed for entities that provide a scope `` | REJECTS: `` name qualifiers are only allowed for entities that provide a scope `` |
| R04 (`R04_nested_block.carbon`) | blocks_and_statements.md (W-185) | REJECTS: `` expected `.field: field_type` or `.field = value` `` | REJECTS: `` expected `.field: field_type` or `.field = value` `` |
| R05 (`R05_scope_end.carbon`) | blocks_and_statements.md | REJECTS: `` name `inner` not found `` | REJECTS: `` name `inner` not found `` |
| R06 (`R06_missing_return.carbon`) | blocks_and_statements.md | REJECTS: `` missing `return` at end of function with declared return type `` | REJECTS: `` missing `return` at end of function with declared return type `` |
| R07 (`R07_class_copy.carbon`) | assignment.md | REJECTS: `` cannot copy value of type `Point` `` | REJECTS: `` cannot copy value of type `Point` `` |
| R08 (`R08_template_missing_member.carbon`) | templates.md | REJECTS: `` unable to monomorphize specific `GetX(Empty)` `` | REJECTS: `` unable to monomorphize specific `GetX(Empty)` `` |
| R09 (`R09_template_constraint_lookup.carbon`) | templates.md (W-183) | REJECTS: `` unable to monomorphize specific `Report(Square as HasArea)` `` | REJECTS: `` unable to monomorphize specific `Report(Square as HasArea)` `` |
| R10 (`R10_checked_member.carbon`) | templates.md | REJECTS: `` type `T` does not support qualified expressions `` | REJECTS: `` type `T` does not support qualified expressions `` |
| R11 (`R11_template_f32.carbon`) | templates.md, Functions with template parameters (quote fixture) | REJECTS: `` unable to monomorphize specific `Convert(i32, f32)` `` | REJECTS: `` unable to monomorphize specific `Convert(i32, f32)` `` |
| R12 (`R12_musteval_runtime.carbon`) | metaprogramming.md | REJECTS: `` non-constant call to compile-time-only function `` | REJECTS: `` non-constant call to compile-time-only function `` |
| R13 (`R13_not_eval.carbon`) | metaprogramming.md | REJECTS: `` array bound is not a constant `` | REJECTS: `` array bound is not a constant `` |
| R14 (`R14_local_template_let.carbon`) | metaprogramming.md (W-031) | REJECTS: `` semantics TODO: `local generic `let` bindings are currently unsupported` `` | REJECTS: `` semantics TODO: `local generic `let` bindings are currently unsupported` `` |
| R15 (`R15_match_nonexhaustive_choice.carbon`) | pattern_matching.md | REJECTS: `` `match` on choice `Signal` has no `default` arm and does not cover alternative `.Wait` `` | REJECTS: `` semantics TODO: `HandleMatchIntroducer` `` |
| R16 (`R16_match_int_no_default.carbon`) | pattern_matching.md | REJECTS: `` `match` on `i32` has no `default` arm and no `case` arm that matches every value `` | REJECTS: `` semantics TODO: `HandleMatchIntroducer` `` |
| R17 (`R17_match_never_matches.carbon`) | pattern_matching.md | REJECTS: `` `case` pattern never matches; every value it can match is matched by a prior arm `` | REJECTS: `` semantics TODO: `HandleMatchIntroducer` `` |
| R18 (`R18_match_dead_default.carbon`) | pattern_matching.md | REJECTS: `` `default` arm never matches; every value of the scrutinee is matched by prior arms `` | REJECTS: `` semantics TODO: `HandleMatchIntroducer` `` |
| R19 (`R19_match_guard_parens.carbon`) | pattern_matching.md | REJECTS: `` expected `(` after `if` `` | REJECTS: `` semantics TODO: `HandleMatchIntroducer` `` |
| R20 (`R20_match_exhaustive_return.carbon`) | pattern_matching.md (W-180) | REJECTS: `` missing `return` at end of function with declared return type `` | REJECTS: `` semantics TODO: `HandleMatchIntroducer` `` |
| R21 (`R21_match_tuple_alternatives.carbon`) | pattern_matching.md (W-182) | REJECTS: `` name `.Self` not found `` | REJECTS: `` semantics TODO: `HandleMatchIntroducer` `` |
| R22 (`R22_match_scrutinee_type.carbon`) | pattern_matching.md | REJECTS: `` semantics TODO: `match on unsupported scrutinee type` `` | REJECTS: `` semantics TODO: `HandleMatchIntroducer` `` |
| R23 (`R23_cpp_explicit_ctor.carbon`) | interop README, Constructors | REJECTS: `` no matching function for call to 'Length' `` | REJECTS: `` no matching function for call to 'Length' `` |
| R24 (`R24_cpp_struct_literal.carbon`) | interop README, Struct literals (W-048, W-051) | REJECTS: `` cannot implicitly convert expression of type `{.first: Core.IntLiteral, .second: Core.IntLiteral}` to `Cpp.Pair` `` | REJECTS: `` cannot implicitly convert expression of type `{.first: Core.IntLiteral, .second: Core.IntLiteral}` to `Cpp.Pair` `` |
| R25 (`R25_cpp_private.carbon`) | interop README, members | REJECTS: `` cannot access private member `v_` of type `Cpp.Box` `` | REJECTS: `` cannot access private member `v_` of type `Cpp.Box` `` |
| R26 (`R26_cpp_nonconst_on_value.carbon`) | interop README, members | REJECTS: `` no matching function for call to 'Inc' `` | REJECTS: `` no matching function for call to 'Inc' `` |
| R27 (`R27_cpp_const_global.carbon`) | interop README, globals | REJECTS: `` expression is not assignable `` | REJECTS: `` expression is not assignable `` |
| R28 (`R28_cpp_long_long.carbon`) | interop README, Integers | REJECTS: `` cannot implicitly convert expression of type `Cpp.long_long` to `i64` `` | REJECTS: `` cannot implicitly convert expression of type `Cpp.long_long` to `i64` `` |
| R29 (`R29_cpp_ref_marker.carbon`) | interop README, pointers and references | REJECTS: `` argument to `ref` parameter not marked with `ref` `` | REJECTS: `` argument to `ref` parameter not marked with `ref` `` |
| R30 (`R30_cpp_assign_operator.carbon`) | interop README, operators (W-045) | REJECTS: `` cannot implicitly convert expression of type `Core.IntLiteral` to `Cpp.Cell` `` | REJECTS: `` cannot implicitly convert expression of type `Core.IntLiteral` to `Cpp.Cell` `` |
| X01 (`X01_swap_alias.carbon`) | assignment.md (quote fixture) | RUNS, exit 0, prints `2 2` | RUNS, exit 0, prints `2 2` |

**Hand derivation of the EXPECT values (R16(d)).** Each line of a program's
expected output, derived from the sample's source alone:

| Sample | Derivation |
| --- | --- |
| P01 | `p.horizontal` is `x`, `3`; `Total` is `Sum`, 3 + 4 = `7`; `PrintToScreen` prints 3 × 100 + 4 = `304`; `Geo.Scale() + Scale()` = 10 + 10 = `20`; `b.item + calls` = 5 + 1 = `6` |
| P02 | the loop adds `i` for `i` in 1, 3, 4, 5 (2 is skipped, 6 breaks) = `13`; `Classify(-7)` is minus one, then `++` gives `0`; 1 + 2 + 3 plus 0 + 1 + 2 + 3 = `12`; `Add` gives 2 + 3 and `MakeSix` gives 6, so `11` |
| P03 | `t` = (3, 4) gives `7`; `s` = `other` gives 5 + 6 = `11`; `p` = (7, 8) gives `15`; `Green` gives `1`; `old` = (3, 4) swapped puts 4 in `t.0`, so `4` |
| P04 | 1 + 2 = `3`; 30 + 40 = `70`; 6 + 6 = `12`; `Convert(7, i64)` is `7`; 3 × 14 = `42` |
| P05 | `Square(5)` = `25`; `table[3]` is 4 and `slots[5]` is 6, so `10`; `Twice(21)` = `42`; 2 to the 40th exceeds 1000, so `1` |
| P06 | `Rect(3, 4)` gives `12`; `Empty` gives `0`; `Classify(-5)` takes the guarded arm, `-1`; (2, 3) takes the guarded tuple arm, `1`; 4 × 10 + 5 = `45` |
| P07 | 3 × 14 = `42`; 20 × 2 + 1 = `41` |
| P08 | 1 + 2 + 10 + 0 + 100 = `113`; `a`, `b`, `c` and `d` are destroyed when `Make` returns, so `4`; `Length(5)` converts through the constructor, `5` |
| P09 | `first` is 1 and `second` is set to `as_int`, 41, so `42` |
| P10 | `Square(3)` has area `9`; scaled by 2 the area is `36`, stored in `tag`; `corner.x` is `4`; `Id()` 5 plus `radius` 1 = `6`; `IdOf` gives `5` |
| P11 | 40 + 2 = `42`; 100 + 7 = `107`; `3` |
| P12 | 2 + 3 + 4 = `9`; 5 + 6 + 9 = `20`; 7 + 8 = `15` |
| P13 | `Bump` gives `2`; found gives `2`; missing gives `0`; `AddTen` gives 12, so `Read` prints `12` and `ReadThrough` prints `12`; `h.Ref() = 8` then `Get` prints `8` |
| P14 | 30 + 12 = `42`; 42 + 30 = 72, negated, `-72`; `a == Make(30)` and `12 < 30` hold, so `1` |
| P15 | `kGreen` is `5`; `IsGreen` and `==` hold, so `1`; `kHigh` 2 plus `kLow` 1 = `3` |
| P16 | two `fetch_add(1)` give `2`; each thread's `per_thread` starts at 0 and becomes 5, so `total` = 5 + 5 = `10`; the main thread's `per_thread` stays `100` |
| X01 | from (1, 2), `t.0` becomes `t.1`, 2; then `t.1` becomes the new `t.0`, 2: `2` then `2` |

**Runner runs (2026-10-13, private `--out`):** the sixteen generated programs
in a scratch mirror of fork/conformance/programs (stub removed):
`--filter project/design_docs` on the fork toolchain 16 PASS; on the nightly 13
PASS, 3 COMPILE-FAIL (design_docs_assignment, design_docs_cpp_struct_literals,
design_docs_match, the labelled fork-only three); on the SC-1, UA-2 and ST-1
toolchains 16 PASS each. Trunk floor on the fork toolchain: 128 / 0 / 22 over
150, 48/56 bullets PASS.

### §4.2 Prose claims backed by testdata or programs (no page block)

| Claim (page) | Evidence |
| --- | --- |
| alias exports, `private alias`, alias spelling in diagnostics (aliases.md) | toolchain/check/testdata/alias/import_access.carbon (``name `A` not found`` outside the library), export_name.carbon (`export D;` of an alias; `C` not visible), import.carbon, preserve_in_type_printing.carbon (``type `A*` does not support qualified expressions``) |
| constant-value alias accepted (aliases.md) | alias/builtins.carbon split `bool_value.carbon` (`alias a = false;` checks clean); P01's `alias Limit = 4;` |
| declaring through an alias rejected (aliases.md, code organization note) | namespace/fail_decl_in_alias.carbon:18-26; R03 |
| `musteval` calling `musteval` with a parameter is a TODO (metaprogramming.md) | function/call/eval_musteval.carbon split `fail_todo_musteval_calls_musteval.carbon` |
| control-flow expressions outside functions (metaprogramming.md) | W-036 evidence; eval/branch.carbon split `fail_todo_if_expression_direct.carbon` |
| `^x` calls `operator~`; prefix `++`/`--`; the unsupported operator list (interop README) | interop/cpp/operators/operators.carbon splits `import_unary_operators.carbon`, `import_binary_operators.carbon`, `fail_todo_import_assignment.carbon`, `fail_todo_rewrite_spaceship.carbon`, `fail_todo_rewrite_equal.carbon`, `fail_todo_import_unsupported_unary_operators.carbon`, `fail_todo_import_unsupported_binary_operators.carbon`; eq_with.carbon `fail_todo_returns_boolish.carbon` |
| reference-typed fields read through `*` (interop README) | interop/cpp/class/import/field.carbon `use_struct_fields.carbon` (`*s.r`); probe PR-O |
| `{}` initializes an empty aggregate, not a class with a constructor (interop README) | interop/cpp/class/import/non_aggregate_init.carbon; P09 |
| union designated initialization (interop README) | interop/cpp/class/import/union_init.carbon; P09 |
| the six threading programs pass (threads page) | local floor run 2026-10-13 (all six PASS); fork/gap-analysis.md:70 |
| single LLVM module for Carbon and C++ (threads page) | toolchain/lower/context.cpp:42-46 (`llvm_module_` is `cpp_code_generator_->GetModule()` when a C++ code generator exists) |
| C++ exceptions never unwind Carbon frames (threads page item 7) | docs/design/README.md:3969-3972; error_handling.md "C++ interoperability" |
| `match` needs at least one arm (pattern_matching.md) | probe PR-F (`expected cases`); W-068's recorded decision |

### §4.3 Probe sources (for the reviewers; not page samples)

Each was run with the §4.1 command on the fork toolchain (and the nightly where
§0.1d says so).

**PR-A.**

`PR-A_lib.carbon`:

```carbon
library "tlib";
fn GetX[template T: type](p: T) -> i32 {
  return p.x;
}
```

`PR-A_main.carbon`:

```carbon
import library "tlib";
import Core library "io";
class Point { var x: i32; }
fn Run() -> i32 {
  let p: Point = {.x = 5};
  Core.Print(GetX(p));
  return 0;
}
```

Two files compiled together, `lib.carbon` (library `tlib`) and `main.carbon`, in
both orders (`carbon compile --output-last-input-only main.carbon lib.carbon`
and `... lib.carbon main.carbon`): both CRASH with "FATAL failure at
/home/user/carbon-trunk/toolchain/check/import_ref.cpp:5087: Missing case in
TryResolveInstCanonical for instruction kind SpliceInst". (Alone, `main.carbon`
is rejected with ``imported API 'Main//tlib' not found``.)

**PR-B.**

`PR-B_let5.carbon`:

```carbon
fn F(n: i32) {
  let 5 = n;
}
fn Run() -> i32 { F(5); return 0; }
```

Fork: REJECTS: `` semantics TODO: `expression pattern` ``. Nightly: REJECTS: `` semantics TODO: `expression pattern` ``.

`PR-B_var5.carbon`:

```carbon
fn F(n: i32) {
  var 5 = n;
}
fn Run() -> i32 { F(5); return 0; }
```

Fork: CRASH rc=134: Stack dump:. Nightly: CRASH rc=134: Stack dump:.

**PR-C.**

`PR-C_recursion.carbon`:

```carbon
eval fn Forever(n: i32) -> i32 { return Forever(n + 1); }
var a: array(i32, Forever(0)) = ();
fn Run() -> i32 { return 0; }
```

Fork: CRASH rc 139 (segmentation fault, stack overflow). Nightly: crashed with a
stack dump; an earlier run exited with rc 139, the run for this table hung in
the crash handler and was terminated (rc 143).

**PR-D.**

`PR-D_template_match.carbon`:

```carbon
fn Kind[template T: type](x: T) -> i32 {
  match (x) {
    case _: i32 => { return 32; }
    default => { return 0; }
  }
}
fn Run() -> i32 { return Kind(1 as i32) - 32; }
```

Fork: REJECTS: `` semantics TODO: `match on unsupported scrutinee type` ``. Nightly: REJECTS: `` semantics TODO: `HandleMatchIntroducer` ``.

**PR-E.**

`PR-E_overload_template.carbon`:

```carbon
import Core library "io";
overload fn Describe(x: i32) -> i32 { return 1; }
overload fn Describe[template T: type](unused x: T) -> i32 { return 2; }
fn Run() -> i32 {
  Core.Print(Describe(5 as i32));
  Core.Print(Describe(true));
  return 0;
}
```

Fork: RUNS, exit 0, prints `1 2`. Nightly: REJECTS: `` unrecognized declaration introducer ``.

**PR-F.**

`PR-F_zero_arms.carbon`:

```carbon
fn F(n: i32) { match (n) {} }
```

Fork: REJECTS: `` expected cases ``. Nightly: REJECTS: `` semantics TODO: `HandleMatchIntroducer` ``.

**PR-G.**

`PR-G_inline_noimport.carbon`:

```carbon
import Core library "io";
fn Twice(n: i32) -> i32 { return n * 2; }
inline Cpp '''c++
inline int CallTwice(int n) { return Carbon::Twice(n) + 1; }
''';
fn Run() -> i32 {
  Core.Print(Cpp.CallTwice(20));
  return 0;
}
```

Fork: REJECTS: `` name `Cpp` not found ``. Nightly: REJECTS: `` name `Cpp` not found ``.

**PR-H.**

`PR-H_escape.carbon`:

```carbon
import Cpp inline '''c++
#include <cstdio>
inline void Hello() { std::printf("hi\n"); }
''';
fn Run() -> i32 { Cpp.Hello(); return 0; }
```

Fork: REJECTS: `` <carbon Cpp imports>:1:2: error: expected '}' ``. Nightly: REJECTS: `` <carbon Cpp imports>:1:2: error: expected '}' ``.

`PR-H_escape_doubled.carbon`:

```carbon
import Cpp inline '''c++
#include <cstdio>
inline void Hello() { std::printf("hi\\n"); }
''';
fn Run() -> i32 { Cpp.Hello(); return 0; }
```

Fork: RUNS, exit 0, prints `hi`. Nightly: RUNS, exit 0, prints `hi`.

`PR-H_escape_raw.carbon`:

```carbon
import Cpp inline #'''c++
#include <cstdio>
inline void Hello() { std::printf("hi\n"); }
'''#;
fn Run() -> i32 { Cpp.Hello(); return 0; }
```

Fork: RUNS, exit 0, prints `hi`. Nightly: RUNS, exit 0, prints `hi`.

**PR-I.**

`PR-I_private_init.carbon`:

```carbon
class Secret { private var x: i32; }
fn Run() -> i32 {
  var s: Secret = {.x = 1};
  s = {.x = 2};
  return 0;
}
```

Fork: RUNS, exit 0, prints (nothing). Nightly: RUNS, exit 0, prints (nothing).

**PR-J.**

`PR-J_structural.carbon`:

```carbon
interface HasArea {
  fn Area(self) -> i32;
}
class Circle {
  var r: i32;
  fn Area(self) -> i32 { return 3 * self.r * self.r; }
}
fn Report[template T: HasArea](s: T) -> i32 {
  return s.Area();
}
fn Run() -> i32 {
  let c: Circle = {.r = 1};
  return Report(c);
}
```

Fork: REJECTS: `` cannot convert type `Circle` into type implementing `HasArea` ``. Nightly: REJECTS: `` cannot convert type `Circle` into type implementing `HasArea` ``.

**PR-K.**

`PR-K_extend.carbon`:

```carbon
import Core library "io";
interface HasArea {
  fn Area(self) -> i32;
}
class Square {
  var side: i32;
  extend impl as HasArea {
    fn Area(self) -> i32 { return self.side * self.side; }
  }
}
fn Report[template T: HasArea](s: T) -> i32 {
  return s.Area();
}
fn Run() -> i32 {
  let q: Square = {.side = 5};
  Core.Print(Report(q));
  return 0;
}
```

Fork: RUNS, exit 0, prints `25`. Nightly: RUNS, exit 0, prints `25`.

**PR-L.**

`PR-L_irrefutable_return.carbon`:

```carbon
fn F(n: i32) -> i32 {
  match (n) {
    case 0 => { return 0; }
    case x: i32 => { return x; }
  }
}
fn G(r: {.w: i32, .h: i32}) -> i32 {
  match (r) {
    case {.w = 0, _} => { return -1; }
    case {.w = w: i32, .h = h: i32} => { return w * 10 + h; }
  }
}
fn Run() -> i32 { return F(0) + G({.w = 0, .h = 1}) + 1; }
```

Fork: REJECTS: `` missing `return` at end of function with declared return type ``. Nightly: REJECTS: `` semantics TODO: `HandleMatchIntroducer` ``.

**PR-M.**

`PR-M_struct_order.carbon`:

```carbon
import Core library "io";
fn Run() -> i32 {
  var s: {.a: i32, .b: i32} = {.a = 1, .b = 2};
  s = {.b = 6, .a = 5};
  Core.Print(s.a);
  Core.Print(s.b);
  return 0;
}
```

Fork: RUNS, exit 0, prints `5 6`. Nightly: RUNS, exit 0, prints `5 6`.

**PR-N.**

`PR-N_template_constraint.carbon`:

```carbon
import Core library "io";

template constraint HasArea {
  fn Area(self) -> i32;
}

class Circle {
  var r: i32;
  fn Area(self) -> i32 { return 3 * self.r * self.r; }
}

fn Report[template T: HasArea](s: T) -> i32 {
  return s.Area();
}

fn Run() -> i32 {
  let c: Circle = {.r = 2};
  Core.Print(Report(c));
  return 0;
}
```

Fork and nightly: REJECTS ``unrecognized declaration introducer``. SC-1's
toolchain (`carbon-sc`, 0.0.0-0.dev+bc8b37290): RUNS, prints 12; and the same
file with a type lacking `Area` is rejected with ``cannot convert type `Blob`
into type implementing `HasArea` ``.

**PR-O.**

`PR-O_ref_field.carbon`:

```carbon
import Core library "io";
import Cpp inline '''c++
struct View { int& r; };
inline View MakeView(int& x) { return View{x}; }
''';
fn Run() -> i32 {
  var n: i32 = 3;
  let v: Cpp.View = Cpp.MakeView(ref n);
  *v.r = 9;
  Core.Print(n);
  return 0;
}
```

Fork: RUNS, exit 0, prints `9`. Nightly: RUNS, exit 0, prints `9`.

`PR-O_void_ptr.carbon`:

```carbon
import Core library "io";
import Cpp inline '''c++
inline void* Identity(void* p) { return p; }
''';
fn Run() -> i32 {
  var n: i32 = 4;
  let p: Core.Optional(Core.CppCompat.VoidBase*) = Cpp.Identity(&n as Core.CppCompat.VoidBase*);
  if (p.HasValue()) { Core.Print(1); }
  return 0;
}
```

Fork: RUNS, exit 0, prints `1`. Nightly: RUNS, exit 0, prints `1`.

**PR-P.**

`PR-P_ref_binding.carbon`:

```carbon
import Core library "io";
fn Bump(ref n: i32) {
  match (n) {
    case ref m: i32 => { m += 1; }
  }
}
fn Run() -> i32 {
  var x: i32 = 41;
  Bump(ref x);
  Core.Print(x);
  return 0;
}
```

Fork: RUNS, exit 0, prints `42`. Nightly: REJECTS: `` semantics TODO: `HandleMatchIntroducer` ``.

`PR-P_result.carbon`:

```carbon
import Core library "io";
fn Run() -> i32 {
  let r: Core.Result(i32, bool) = Core.Result(i32, bool).Ok(3);
  match (r) {
    case .Ok(v: i32) => { Core.Print(v); }
    case .Err(_: bool) => { Core.Print(0); }
  }
  return 0;
}
```

Fork: RUNS, exit 0, prints `3`. Nightly: REJECTS: `` member name `Result` not found in `Core` ``.

**PR-Q.**

`PR-Q_unsigned_long_long.carbon`:

```carbon
import Core library "io";
import Cpp inline '''c++
inline unsigned long long NextULL(unsigned long long x) { return x + 1; }
''';
fn Run() -> i32 {
  let n: u64 = 4;
  let a: Cpp.unsigned_long_long = Cpp.NextULL(n);
  let b: u64 = a as u64;
  Core.Print(b as i32);
  return 0;
}
```

Fork: RUNS, exit 0, prints `5` (a `u64` argument reaches the C++ `unsigned long
long` parameter, and `as u64` converts the result). The same call bound directly
to a `u64` is rejected with ``cannot implicitly convert expression of type
`Cpp.unsigned_long_long` to `u64` ``.

## §5 Gap-row effect and scoreboard delta

-   **Conformance (state T, expected, not of record):** programs 150, less the
    stub, plus sixteen: 165; PASS 128 plus sixteen: 144; SKIP 22 less the stub:
    21; FAIL 0; bullets PASS 48 → 49 (the design-docs bullet SKIP → PASS). The
    of-record run is the first hosted or owner-dispatched conformance run (R9,
    R28); until then the evidence is the local run of §4.1.
-   **Row 91** (`Goal: design docs documented, cohesive, understandable
    without placeholders`): PARTIAL → **DONE** (expected), evidence cell
    rewritten to: "DD-1 (fork/designdocs/plan.md): templates.md,
    metaprogramming.md, aliases.md, blocks_and_statements.md and the `match`
    section of pattern_matching.md carry dated status notes in place of their
    placeholder self-descriptions and document the 0.1 toolchain's behavior
    with compile-verified examples; the interop README's eight TODO sections
    are written from measured behavior; docs/design/interoperability/
    threads_and_atomics.md states the F-008 contract; the design README's
    TODO-only sections, assignment.md's and comparison_operators.md's are
    replaced; fork/designdocs/check_samples.py's W2 rule finds no placeholder
    self-description, TODO heading or TODO-only section under docs/design/,
    and sixteen transcribed programs PASS (expected; local run 2026-10-DD).
    DONE on two document reviews (rows 88-90 precedent); toolchain defects
    found are filed under their own bullets (W-180..W-186)."
-   **Row 70** (`C++ interop: threading, atomics, memory model,
    synchronization`): PARTIAL → **DONE** (expected); the cell's "Missing: ..."
    sentence becomes "The memory-model contract is
    docs/design/interoperability/threads_and_atomics.md (DD-1; W-020
    DISCHARGED)."
-   **Header:** DONE plus two, PARTIAL minus two, against whatever trunk reads
    at integration (at 162c7e839: 30 / 21 / 4 / 1 → 32 / 19 / 4 / 1).
-   Bullet text untouched (R7).

## §6 Churn and collision analysis

No toolchain, prelude, golden, `.github/` or `runner.py` change (D-DD-6's
`--self-test` join is a state-L option, one call). Markdown touched (state T):
aliases.md, blocks_and_statements.md, assignment.md, templates.md,
metaprogramming.md, pattern_matching.md, interoperability/README.md,
interoperability/threads_and_atomics.md (new), README.md,
code_and_name_organization/README.md, expressions/comparison_operators.md,
fork/conformance/README.md (generated table), fork/gap-analysis.md,
fork/decision-log.md, fork/ORCHESTRATION.md, fork/designdocs/plan.md. New
files: sixteen programs, thirty-one fixtures, the checker. Deleted: the stub.
State L adds docs/guides/tutorial.md and evaluator_faq.md (EV-1's). The held
PRs' overlaps and their resolutions are §0.2's table; name collisions: no held
branch adds a `design_docs_*` program or a fork/designdocs/ path (`git
ls-tree` on each branch head), and the residue ids W-180..W-189 are reserved
(§0.4 of ORCHESTRATION at discharge). Upstream convergence: every DD-1 edit to
an upstream page is a dated blockquote or a new section after the original
text, so a weekly upstream merge that rewrites a page conflicts only where
upstream replaced the same placeholder, and the fork side is dropped there in
favor of upstream's accepted text.

## §7 Risks and rejected alternatives

-   **R-1 Documentation drifts from the toolchain.** Mitigation: the sixteen
    programs run in every conformance run, and the fixtures run under the
    checker's `--toolchain` mode in the land sequence; a toolchain change that
    breaks a documented sample fails the suite. Falsifier: a sample on a page
    whose program or fixture is not in the checker table (check 4 catches it).
-   **R-2 Status notes read as placeholders by another name.** A note that says
    "not accepted" might be judged a placeholder. Mitigation: each note says
    what is accepted, what the toolchain does, and links the measured section;
    D-DD-2's break condition. Falsifier: a document review finding citing the
    bullet text.
-   **R-3 rumdl reflow breaks quotes or manufactures list items.** Negative
    numbers and `+` stay inside code spans; quotes are compared with collapsed
    whitespace; R31 counts per §0.3. Falsifier: a count delta not listed in §2.
-   **R-4 Program growth under a documentation bullet games the scoreboard.**
    Mitigation: D-DD-5's wording in every header and in row 91; EV-1 precedent.
    Rejected alternative: keep the stub SKIP and add no programs (loses R27
    enforcement in the suite).
-   **R-5 W-020 absorption overlaps another plan.** D-DD-7's break condition.
-   **R-6 Nightly labels age.** Labels name the nightly date; the checker does
    not run the nightly. Falsifier: a newer nightly accepting a fork-only
    sample (harmless; the label is dated).
-   **R-7 State-L conflicts larger than §0.2 predicts.** The integration commit
    re-runs `git diff --name-only` per merged PR and records any extra
    conflict in its message.
-   **Rejected: rewriting the placeholder pages into full designs** — that is
    design work needing proposals or fork decisions (F-016), out of a
    documentation workstream (D-DD-3).
-   **Rejected: deleting the placeholder pages** — the language overview links
    them (README.md:1393, :2697, :2905, :3918); deleting loses the upstream
    sketches the status notes qualify.
-   **Rejected: one-line "not implemented" bodies for the interop TODO
    headings** — fails "documented"; every implemented behavior is shown
    instead.
-   **Rejected: marker comments in pages for the checker** — they would litter
    upstream pages; the checker maps by heading instead.
-   **Rejected: porting the stranded threading.md** — written before F8a-F8d
    fixed its open sub-forks; the new page is written from F-008 and
    measurements.
-   **Rejected: folding the toolchain defects into W-065** — they belong to
    their feature bullets, and W-065 closes with the documentation.

## §8 Verification and discharge

1.  **Per commit:** (1) record the §0.3 counts and the heading lines (`grep -n
    '^#' <f> > before`) of every touched markdown file; (2) run
    `SKIP=fix-cc-deps,check-build-graph,check-bazel-mod-deps,forbid-llvm-googletest
    uvx prek run --files <touched>` until a run changes nothing; (3) `git diff
    -U0 | grep -nE '^\+\s*#{1,6} [0-9]|^\+#[0-9]'` is empty; (4) re-count and
    `comm -13` the heading sets: only §2's listed deltas; (5) `python3
    fork/designdocs/check_samples.py` and the same with `--toolchain
    /home/user/carbon-build/carbon-trunk/install/bin/carbon` exit 0; (6)
    `python3 fork/conformance/runner.py --self-test` exits 0; (7) a full local
    conformance run with a private `--out` gives the §5 totals for the commits
    so far; (8) the sixteen programs on the nightly give the §2.11 labels. R25:
    edits by the editor tools, never shell appends to committed markdown.
    Commands whose text contains a word that check-google-doc-style rewrites are
    quoted between its ignore and resume markers.
2.  **Plan reviews:** two (R29(c)); fixer separate (R11); fold marks
    "(amended <date>, review fold: A-n / B-n)" and a fold record.
3.  **Document reviews:** two fresh agents after commit 3 (D-DD-11); the
    fixer separate; then one implementation review after the fourth commit.
4.  **Conformance:** `--self-test` clean; the stub's row gone from
    fork/conformance/README.md and sixteen rows present.
5.  **Ledger (fork/inventory/work-items.json):** W-065 notes prefixed
    "DISCHARGED (fork/designdocs/plan.md DD-1, 2026-10-DD; commits <shas>): ..."
    with evidence re-pinned to the new sections; W-020 notes gain "DOC HALF
    DISCHARGED at DD-1: docs/design/interoperability/threads_and_atomics.md"
    and the item is discharged; W-014 evidence gains "check/import_ref.cpp
    (TryResolveInstCanonical, SpliceInst): a template function called from
    another library crashes check (DD-1 probe PR-A, 2026-10-13)"; W-080 notes
    gain "A `var` root (`var 5 = n;`) crashes instead: W-181." Residues, ids
    confirmed free at discharge by `grep -o '"W-[0-9]*"'` over trunk and every
    live branch head (the result per head recorded in the commit message):
    -   **W-180** (todo-stub; bullet "Control flow: matching — good switch
        equivalents"): a `match` with no `default` arm that is exhaustive (all
        alternatives, both `bool` values, or an irrefutable arm) does not end
        control flow; evidence R20, PR-L, pattern_matching.md:611-618 (IsTrue,
        "Code here is considered to be unreachable"), p002188:1031-1034,
        toolchain/check/testdata/match/exhaustive_choice.carbon (the trailing
        `return -1;` and its comment).
    -   **W-181** (todo-stub; bullet "Control flow: matching — if-let / let-else
        combined match+declaration", beside W-080): `var 5 = n;` crashes check
        in `EvalConstantInst` on `VarStorage` (PR-B), on the fork and the
        nightly; pattern_matching.md:684.
    -   **W-182** (missing-feature; bullet "Control flow: matching — sum-type
        consumption incl. std::variant/std::optional interop"): alternative
        patterns inside tuple patterns and payload subpatterns are checked as
        designator expressions (``name `.Self` not found``); evidence R21,
        match/fail_choice_alternative_pattern.carbon
        `fail_nested_designator_subpattern.carbon`, pattern_matching.md:638-649.
    -   **W-183** (language-gap; bullet "Generics: Integrated templates"):
        member lookup into a constrained template parameter ignores the
        constraint (p002200:433-441, :200-202); evidence R09, PR-K; the
        nightly agrees.
    -   **W-184** (todo-stub; bullet "Project: toolchain implements most 0.1
        language features incl. C++ interop without undermining evaluation"):
        unbounded compile-time recursion overflows the compiler's stack
        (PR-C; eval/recursion.carbon:28 TODO); nightly agrees.
    -   **W-185** (language-gap; bullet "Control flow: conditions"): a block is
        not accepted as a statement (R04; p000162:65;
        blocks_and_statements.md:44-51); nightly agrees.
    -   **W-186** (todo-stub; bullet "Type system: User-defined types
        (classes)"): a struct literal initializes or assigns a class's
        `private` fields outside the class (PR-I; classes.md:2068-2072);
        nightly agrees.
    -   **W-187** only under D-DD-9's break condition; W-188/W-189 for folds.
6.  **Gap analysis:** §5's row texts and header delta.
7.  **Decision log:** heading `### DD-1: design docs without placeholders
    (2026-10-DD)` inserted directly after the "### Full autonomy and the
    throughput protocol" entry (so first in the landed region at merge time).
    Contents: the bullet verbatim; what landed, page by page; D-DD-1..13 with
    their break conditions; the stale claims of §0.4; the residues by title;
    "F-016 not minted"; the local-gate statement (D-DD-12). Count check: H3
    +1, every other count unchanged; its lists are dash items, and the new dash
    count equals the old plus the items the entry adds.
8.  **ORCHESTRATION:** the "Last updated" paragraph, a branch row
    `claude/carbon-fork-0-1-dd`, the id reservation W-180..W-189, and the merge
    position.
9.  **Landed notes** appended to this plan: commits, deviations (R17: one
    sentence each), measured totals.

## Hand-off notes for the writer

1.  Read §0.5 and §2 first. The texts in §2 are exact; where prek re-wraps
    prose, leave its wrapping. Do not wrap code.
2.  Re-open every cited line before committing; the line numbers are against
    162c7e839 and move as you edit (work bottom-up in each file).
3.  R31: never let a line start with `#` and a digit, `*`, `+`, `-` or a digit
    and a period outside a real list; negative numbers and `+` stay inside code
    spans; write "PR 53" and "proposal 2188". Record §0.3's counts before and
    after every prek run.
4.  check-google-doc-style rewrites the Latin abbreviations, the three-letter
    synonym of "by way of", the short forms of "repository", and the two short
    words for advantages and disadvantages, in code too; none appear in §2.
5.  Never write the table-of-contents marker pair in prose; on the new page,
    copy it from a sibling page's file.
6.  Generate each program from its sample file plus §2.11's header, then run
    the checker; never retype a sample.
7.  Nothing under toolchain/, core/, .github/ or proposals/; no golden; no
    program other than the stub and the sixteen.
8.  Dates: replace every `2026-10-DD` with the commit date.
