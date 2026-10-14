<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# Design docs without placeholders: status notes, measured 0.1 behavior, the interop TODO sections, the F-008 threads page (DD-1, W-065)

**Status:** rev 4, 2026-10-14 -- SIGNED OFF FOR IMPLEMENTATION (the
[Sign-off](#sign-off) section at the end lists every review). The second
focused re-review, of rev 3 (15c719ddc; its own title is "round 1"), returned
APPROVE-WITH-AMENDMENTS with no BLOCKER open: A-1 RESOLVED, N-1 to N-4
VERIFIED, B-1 and B-2 RESOLVED on spot-check, and three new findings, RR2-1
(MAJOR), RR2-2 and RR2-3 (MINOR). A separate fixer (R11) folds all three into
rev 4, none rejected, and adds one finding of its own, RR2-FX-1; the
[rev-4 fold record](#focused-re-review-2-rev-4-2026-10-14) lists each
disposition. Rev-4 fold marks read "(amended 2026-10-14, review fold:
RR2-x)", where x is the re-review's own finding id. Rev 3 (15c719ddc) folded
the first focused re-review, of rev 2 (a1d96520a), which returned REJECT with
one BLOCKER, A-1 (rev 2 still called leads issue 686 open, but the leads
answered it on 2022-11-12), and four MINOR findings, N-1 to N-4; its fixer
folded all five, none rejected, A-1 with one cited wording deviation, and the
[re-review fold record](#focused-re-review-rev-3-2026-10-13) lists each
disposition. Rev-3 fold marks read "(amended 2026-10-13, review fold:
RR-x)", where x is that re-review's own finding id (RR-A-1, RR-N-1 to
RR-N-4). Rev 2 (a1d96520a) folded the
two plan reviews of R29(c) (A: fidelity to the toolchain and the accepted
proposals; B: process, records and Goodhart) by a separate fixer (R11), all
33 findings, none rejected; the
[review fold record](#review-fold-record-rev-2-2026-10-13) at the end lists
each disposition. Rev 1 (bed95d667) was the planner draft. Rev-2 fold marks
read "(amended 2026-10-13, review fold: A-n / B-n)"; reviewer B's majors and
minors, numbered M-n and m-n in its review, are marked B-M-n and B-m-n.
Branch `claude/carbon-fork-0-1-dd` in the
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
becomes a dated status note that names the accepted proposals, leads decision or
fork decision behind the page (amended 2026-10-13, review fold: RR-A-1) and the
toolchain's status, and the behavior is added in new sections whose every code
block is a complete file compile-verified on the fork toolchain (R3, R6) and on
the upstream nightly
`/home/user/nightly/tc/carbon_toolchain-0.0.0-0.nightly.2026.10.12/bin/carbon`
(`0.0.0-0.nightly.2026.10.12+62f1cc6`), labelled fork-only where the nightly
rejects it. No toolchain, prelude, golden, `.github/` or `toolchain/`/`core/`
file changes. The toolchain defects found while measuring are filed with their
exact evidence (R10) as residues W-182..W-185, W-188, W-189 and W-191 at
discharge (W-191 renumbered from rev 2's W-190; RR-FX-1), W-188 being the
assignment of a literal right-hand side that reads the target, whose result
differs from leads issue 686's answer, or folded into the existing items that
already own them: W-155 (EV-1, PR 54), W-167 (ST-1, PR 55), W-080, W-053 and
W-014 (D-DD-10; amended 2026-10-13, review fold: A-1 / A-4 / A-11 / B-M-1;
RR-A-1). **No fork design id is minted**: F-016 stays unallocated by this plan
(D-DD-3). **Id reservation** (recorded here and in the discharge's ORCHESTRATION
stamp; amended 2026-10-13, review fold: A-1 / A-4 / B-M-1; RR-FX-1; amended
2026-10-14, review fold: RR2-1): **DD-1's block is W-180..W-194, and W-190 in it
stays unused.** Rev 1 reserved W-180..W-189; rev 2 extended the block to W-194
because its folds needed one more id, and used W-190 for the template-export
crash. W-190 was then allocated on both branches in parallel, and both moved off
it: OP-1 held W-190 from its implementation-review fold (49e2cf2bf, "the first
id after DD-1's reserved W-180..W-189") until its discharge (379f20f67,
2026-10-14 00:14:57 UTC) re-allocated it to W-195, because DD-1's rev 2 reserves
W-180..W-194; meanwhile rev 3 (00:08:50 UTC), seeing OP-1's W-190, renumbered
DD-1's W-190 to W-191 (RR-FX-1). DD-1 keeps W-191, and W-190 stays unused under
the rule that a reserved id that goes unused stays unused; trunk's
fork/ORCHESTRATION.md (f67ab650d, "On 2026-10-14") records the same: W-190
"stays unused and is never reused". W-180, W-181 and W-186 were rev 1's ids for
defects that other items own and are withdrawn unused; W-187 is contingent
(D-DD-9); W-192..W-194 are spare. The ledger maximum over trunk and every live
branch is W-195 (OP-1, head 379f20f67, which filed W-170..W-179 and W-195);
SC-1's maximum is W-168 (head a9c887101) and W-169 is SC-1's reservation. The
rev-4 scan, `git grep -E 'W-1[89][0-9]'` outside this plan over 73 refs (trunk,
origin/trunk, upstream-trunk and the 70 local and origin
`claude/carbon-fork-0-1-*` refs), finds such ids on two commits only: OP-1's
379f20f67 (its W-195, its record of W-190's re-allocation, and its references to
DD-1's W-180..W-194) and trunk's f67ab650d (the ORCHESTRATION paragraph that
records both blocks). **Merge position:** last, after OP-1, which is PR 56: PR
53, PR 51, PR 52, SC-1, PR 54, PR 55, PR 56, then DD-1 (trunk's
fork/ORCHESTRATION.md at f67ab650d, "On 2026-10-14"). Trunk advanced from
162c7e839 to f67ab650d after rev 3 with that stamp alone (fork/ORCHESTRATION.md
only), so every other line number above stands (amended 2026-10-14, review fold:
RR2-FX-1).

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
| 5 | docs/design/pattern_matching.md:718-721 (in `### Pattern match control flow`, :716) | "`match` is a skeletal design ... Aside from guards, it should not be treated as accepted by the core team; rather, it is a placeholder" | the fork implements `match` (P06 RUNS on fork; the nightly reports "semantics TODO: `HandleMatchIntroducer`" for every `match`); exhaustiveness and usefulness errors (R15-R18); guards need parentheses (R19); an exhaustive `match` without `default` does not end control flow (R20, PR-L, W-155 on PR 54); four constant `(bool, bool)` arms are not exhaustive although :589-592 makes them so (PR-R, W-189); alternative patterns inside tuple patterns not recognized (R21, W-182); unsupported scrutinee types (R22, PR-D); the first example (:730-745) is rejected (X02); the page's own `var 5 = n;` (:684) crashes the checker (PR-B, W-080) (amended 2026-10-13, review fold: A-4 / A-9 / A-11 / B-M-1) | p002188 (patterns, guards, exhaustiveness), p005164 (objects; its "drive-by fix" wrote the placeholder note, p005164:44-45); F-011 / W-012 for the pattern-binding forms |
| 6 | docs/design/interoperability/README.md, 355 lines, 18 `TODO` lines: headings :156, :240, :242, :244, :246, :250, :275, :350 (seven empty, :275's body the note :277-278 "Incorporate proposal #6357"), their eight TOC entries :20, :27-30, :32, :35, :39, and :286 (prose naming a former TODO) | eight `TODO:` headings with no content | measured per section in §2.7: inline import (P07), constructors (P08, R23), struct literals (P09, R24), members (P10, R25, R26), globals (P11, R27), integers (P12, R28), pointers/references/`const` (P13, R29), operators (P14, R30); every RUNS sample runs on both toolchains except P09 (fork-only, UN-2's union initialization); the inline import needs an earlier `import Cpp` (R32); plus three sections for milestone interop items that had no design section (§0.1e): C++ templates (P17), C++ use of Carbon (P18, R33, PR-S), C++ ranges in `for` (P19, R34) (amended 2026-10-13, review fold: B-M-5 / A-14 / B-m-4) | p006358, p006254, p005448, p006357, p006668, p006177, p006710; fork F-007 (UN-2), F-009 (OV-3) |
| 7 | docs/design/README.md:143-149 "This document is provisional" | "includes much that is provisional or placeholder" (the stub's evidence, its known-missing slice) | a general disclosure; **in scope** (§2.9 item 6): a dated fork note after :149 says how the provisional parts are marked, and the W2 rule's clause (a) matches the phrase, so the disclosure is a qualified entry the checker ties to that note (amended 2026-10-13, review fold: A-5 / B-2) | — |

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
row 89 MISSING to DONE on review, D-SAFE-21/23, and keeps its program
safe_carbon_design.carbon SKIP with a refreshed R10 reason; EV-1 on PR 54 takes
row 90 to DONE on transcription plus review, D-EV-16). EV-1's programs are
"documentation-sync programs under a bullet that was already PASS (bullets
unchanged)" (claude/carbon-fork-0-1-ev:fork/evaluator/plan.md:562-567): its
bullet was PASS before EV-1 through evaluator_docs_getting_started.carbon, and
the stub it deleted, evaluator_docs_review.carbon, was a SKIP beside that PASS
program. No precedent turns a documentation bullet from SKIP to PASS. W-002's
note (3) records that the harness has no arbitration channel for
document-review bullets. D-DD-5 therefore takes the SAFE-1 shape for the stub
(it stays SKIP, its R10 reason refreshed) and the EV-1 shape for the
transcribed programs (documentation-sync programs, here under the feature
bullets they exercise, all already PASS) (amended 2026-10-13, review fold: A-2
/ B-1).

#### §0.1c The sweep of docs/design/ (every placeholder and TODO marker, classified)

The W2 rule of D-DD-2 was run as a script over docs/design/ at 162c7e839
(rule text in §2.12; prototype in the session scratchpad): **36 hits**, every
one classified below. The fixer re-ran it with an independent prototype for
rev 2 and found the same hit set (36 lines), and **37** once clause (a) gains
the phrase `provisional or placeholder`: the extra hit is README.md:145, class
D (amended 2026-10-13, review fold: A-5 / B-2). A marker that the rule does
not hit is an inline note beside existing content (category C); `grep -rcE
TODO --include=*.md docs/design` counts 110 `TODO` occurrences in 23 files,
the remainder of which are in category C. §0.1f classifies every
"provisional", "no design", "TBD" and "placeholder" occurrence the same way.

| Class | Location | Disposition |
| --- | --- | --- |
| A (boilerplate) | templates.md:24-27, metaprogramming.md:20-23, aliases.md:21-24, blocks_and_statements.md:20-23, pattern_matching.md:718-721 | **In scope**: status notes (§2.1-§2.6) |
| B (TODO heading) | templates.md:22, metaprogramming.md:18, aliases.md:19, blocks_and_statements.md:18 (`## TODO`) | **In scope**: become `## Status` |
| B | interoperability/README.md:156, :240, :242, :244, :246, :250, :275, :350 | **In scope**: real content (§2.7) |
| C' (TODO-only section) | README.md:3815 `### Enums` (body `> **TODO**`) | **In scope** (§2.9): C++ enums are a major C++ feature under milestones.md:73-75 |
| C' | README.md:3986 (Abstract machine and execution model) | **In scope** (§2.9 item 4): content, the 0.1 execution model as values.md, the statement pages, F-008's memory model and error_handling.md fix it, each cited; it has no milestone deferral (amended 2026-10-13, review fold: A-8 / B-M-4) |
| C' | README.md:3990, :3994 (Co-routines, Concurrency) | **In scope** (§2.9 item 4): the upstream `> **TODO:**` marker stays (D-DD-1, as in comparison_operators.md), and a dated status note after it cites the milestone deferral (milestones.md:268 and :271) and, for concurrency, the 0.1 contract on the threads page; listed in row 91 as not designed, by milestone deferral (amended 2026-10-13, review fold: RR-N-3) |
| C' | assignment.md:159-164 (`_TODO_: Describe the rules ...`) | **In scope** (§2.3): statements are core 0.1 components (milestones.md:65-67) |
| C' | expressions/comparison_operators.md:474-477 (Custom result types) | **In scope** (§2.10): the upstream `**TODO:**` marker stays, and a dated status note after it states the 0.1 behavior (`bool` results, core/prelude/operators/comparison.carbon:10-31; W-045 for C++ operators with other results); listed in row 91 as an extension not designed, beyond proposal 702's `bool` results (amended 2026-10-13, review fold: A-8 / B-M-4) |
| C' | README.md:3905 (Lifetime and move semantics) | **Closed by held PR 53** (SAFE-1 replaces :3905-3907); allowlisted at state T |
| C' | expressions/arithmetic.md:184 (Strings) | **Closed by held PR 55** (ST-1 adds its F-014 amendment after :188); allowlisted at state T |
| related | README.md:3909-3912 (Metaprogramming `> **TODO:** References need to be evolved ...`) | **In scope** with metaprogramming.md (§2.9) |
| related | README.md:2890 (`> **TODO:** The design for template constraints is still under development.`) | **In scope** (§2.9): F-010 decided it; state-T and state-L texts |
| related | README.md:812-814, :1038-1039, :3586-3587, :3659-3660, :3733-3734 ("provisional, no design ... has been through the proposal process yet") | **In scope as cohesion notes** (§2.9 item 5): stale against the accepted p003646 (tuples), p002188, p006358, p006254, and p005448 with p006357; one dated note each, upstream text kept; the :3733 note also covers the `T&` to `T*` sentence at :3757-3758 (amended 2026-10-13, review fold: A-3 / B-M-8 / B-m-5) |
| related | code_and_name_organization/README.md:762-772 (`#### Aliasing`: declares `struct TI.RawData` through an alias) | **In scope as a cohesion note** (§2.10): rejected by the toolchain (R03) |
| C (inline beside content) | README.md:1745, :2486, :2777, :2824, :3428-3430, :3442, :3695; classes.md:837, :2360; values.md:133, :738, :836, :983, :1135; generics/details.md (17 hits); variadics.md (7); functions.md:187, :239; expressions/README.md:249; expressions/arithmetic.md:167, :171; expressions/bitwise.md:148; expressions/comparison_operators.md:342, :383, :462; expressions/as_expressions.md:84; expressions/logical_operators.md:118; control_flow/return.md:164; sum_types.md:151; pattern_matching.md:151 | **Out of scope**: each sits beside normative content that is understandable without it and records a pending upstream refinement; the bullet asks for no placeholders, not for no maintenance notes. Not filed. |
| C | README.md:2180-2182 (`> **TODO:** The design for mixins is still under development.`) | **Out of scope**: beside the Mixins section's content, and mixins are deferred until at least 0.2 (milestones.md:273); named in row 91's list of deferred sections (amended 2026-10-13, review fold: B-M-8) |
| C (fork pages) | functions_overloading.md (17 hits: "semantics TODO" diagnostic names), error_handling.md and slices.md ("placeholder" describing `Core.Optional` / `buf`), unions.md:129 | **Out of scope**: they quote toolchain diagnostics or describe a prelude placeholder (OP-1's W-058) |
| D (README disclosure) | README.md:143-149 | **In scope** (§2.9 item 6): the stub's known-missing slice names it; a dated fork note after :149, and a qualified W2 entry tied to that note (amended 2026-10-13, review fold: A-5 / B-2; the two counts above amended 2026-10-13, review fold: A-15) |
| E (missing page) | the F-008 threads page named by gap row 91 and W-020 | **In scope by D-DD-7** (§2.8): docs/design/interoperability/threads_and_atomics.md |
| E | F-010's template constraints page | **Closed by held SC-1** (docs/design/generics/template_constraints.md on claude/carbon-fork-0-1-sc) |
| E | F-009 and F-011 pages | **Already landed**: functions_overloading.md (OV-1/OV-3) and pattern_matching.md "Refutable pattern bindings" (W-012) |

#### §0.1d The extra probes that shaped decisions (sources in §4.3)

| Probe | Fork outcome | Nightly | Consequence |
| --- | --- | --- | --- |
| PR-A cross-library template call (two files, compiled in both orders) | CRASH: "FATAL failure at .../toolchain/check/import_ref.cpp:5087: Missing case in TryResolveInstCanonical for instruction kind SpliceInst" | CRASH, both orders: "FATAL failure at toolchain/check/import_ref.cpp:4875: Missing case in TryResolveInstCanonical for instruction kind SpliceInst" (amended 2026-10-13, review fold: A-13) | W-014's evidence gains both sites in the integration commit (§8.5); the crash is shared with upstream; the page states the limit |
| PR-B `var 5 = n;` (the page's own pattern_matching.md:684) | CRASH rc 134: "CHECK failure at toolchain/sem_ir/pattern.cpp:81: entity_name_id.has_value(): Unhandled pattern inst kind {kind: ExprPattern, ...}"; `let 5 = n;` gives "semantics TODO: `expression pattern`" | the same CHECK, at pattern.cpp:77 | W-080's evidence (folded; amended 2026-10-13, review fold: A-11 / B-m-3) |
| PR-C unbounded `eval fn` recursion | CRASH rc 139 (stack overflow); testdata eval/recursion.carbon:28 "TODO: Diagnose infinite recursion" | crashed; the run hung in the crash handler and was terminated (an earlier run exited rc 139) | W-184 |
| PR-D `match` on a template-dependent value | "semantics TODO: `match on unsupported scrutinee type`" | no `match` | the `### Templates` rules of pattern_matching.md:530-572 are unimplemented; stated |
| PR-E `overload fn` set with a template member | RUNS, prints 1 then 2 | REJECTS: "unrecognized declaration introducer" (no `overload fn`; rev 1's "not run" here contradicted §4.3) | templates.md's Overloading note |
| PR-I struct literal initializing a class with a `private` field, outside the class | RUNS (accepted) | same | W-167 (ST-1, PR 55) already owns it; PR-I joins its evidence at integration (amended 2026-10-13, review fold: B-M-1) |
| PR-L exhaustive `match` with an irrefutable arm, no trailing `return` | "missing `return` at end of function with declared return type" | — | W-155 (EV-1, PR 54) already owns it and names the irrefutable `case x: i32` arm; R20 and PR-L join its evidence at integration (amended 2026-10-13, review fold: B-M-1) |
| PR-R four constant `(bool, bool)` arms, no `default` | REJECTS: "`match` on `(bool, bool)` has no `default` arm and no `case` arm that matches every value" | no `match` | W-189: pattern_matching.md:589-592 makes the set exhaustive; fork/w078b/plan.md:109-125 recorded the boundary (its R-6) with no owning item (amended 2026-10-13, review fold: A-4) |
| PR-S a Carbon function with a `template` parameter, called from C++ | CRASH rc 134: "CHECK failure at toolchain/sem_ir/generic.cpp:96: ... Queried generic_inst_in_def1 {kind: CallAction, ...} ... before it was resolved." (the same with `return x;`, `CompoundMemberAccessAction`; identical on OP-1's toolchain) | RUNS, prints `42` | W-191 (rev 2's W-190; RR-FX-1); the C++-use section states the limit (amended 2026-10-13, review fold: B-M-5) |
| PR-T a checked generic's symbolic type parameter as a C++ template argument (`var unused b: Cpp.Box(T);` in `fn MakeBox[T: type]`) | REJECTS: "cannot convert type `<splice of <cannot stringify inst...>>` into type implementing `Core.DefaultOrUnformed`" | the same shape | W-043 owns it; prose only, because the message names internal instruction ids (amended 2026-10-13, review fold: B-M-5) |
| PR-U tuple and struct swaps: `let u = (t.1, t.0); t = u;`, `s = {.a = s.b, .b = s.a};`, and `var old = t; t = (old.1, old.0);` | RUNS: `2 1`, `2 2`, `2 1` | the same | §2.3 states what was measured and leads issue 686's answer, under which both literal forms leave `(2, 1)`; W-188 (toolchain-defect) records the literal form's divergence from it (amended 2026-10-13, review fold: A-1; RR-A-1) |
| PR-G2 `import Cpp;` then `inline Cpp` | RUNS, prints `41` | the same | the inline rule: an `import Cpp` earlier in the file (amended 2026-10-13, review fold: A-14 / B-m-4) |
| SC-1 toolchains (`carbon-sc`: 0.0.0-0.dev+bc8b37290 at rev 1; ff490bd48 re-measured for rev 2; 18775fee3, the toolchain and prelude of the head a9c887101, re-measured for rev 4) | all 16 RUNS samples PASS; all 30 REJECTS diagnostics identical to trunk's; at ff490bd48 and at 18775fee3 every rev-1 page sample and fixture (47) and every rev-2 one gives trunk's result; PR-N runs on 18775fee3 | — | state L needs no sample change for SC-1; §8.10 names the build each head was measured on (amended 2026-10-14, review fold: RR2-2) |
| OP-1 toolchain (`carbon-op`, 0.0.0-0.dev+5d9edb3e0; the head 379f20f67 differs from it in toolchain/ and core/ by three testdata goldens only; re-measured for rev 4) | every rev-1 page sample and fixture (47) and every rev-2 one gives trunk's result | — | the same for OP-1 (amended 2026-10-13, review fold: A-12 / B-m-1; amended 2026-10-14, review fold: RR2-2) |
| UA-2 toolchain (`carbon-ua2`, 05a5c30f7) and ST-1 toolchain (`carbon-st`, 84ff63560) | all 16 RUNS samples PASS | — | same for PR 51 and PR 55 |

#### §0.1e Coverage of the milestone's language and interop items

(Added 2026-10-13, review fold: B-M-5.) Row 91's bullet stands for two
milestone goals that §0.1a quotes: the language design components
(milestones.md:55-71) and "Design for both Carbon use of C++ and C++ use of
Carbon, including all major C++ language features except for coroutines"
(:73-75). The items they cover are the 0.1 feature list, milestones.md:110-215.
Each maps below to the design section that documents it once DD-1 lands at
state T, and to its gap row (fork/gap-analysis.md line) and owning items. Both
document reviews receive this table in their brief (D-DD-11).

| Milestone lines | Item | Design section after DD-1 | 0.1 status (gap row, items) |
| --- | --- | --- | --- |
| :112-116 | packages, libraries, implementation files, importing, namespaces | code_and_name_organization/README.md, source_files.md | rows 36-40 DONE |
| :120 | user-defined types | classes.md | row 41 DONE; W-167 (PR 55) |
| :121-122 | importing C++ types, exporting Carbon types | interop README "Accessing C++ classes, structs, and members", "Constructors" and "Struct literals" (DD-1), "Using Carbon from C++" (DD-1, new); README.md "Importing and `#include`" (:3584) | row 42 PARTIAL; W-047..W-050 |
| :123-124 | single inheritance, virtual dispatch | classes.md (p000777) | rows 43-44 DONE |
| :125-128 | bi-directional inheritance, hierarchy roots, abstract/final/virtual mapping | README.md "Inheritance" (:3788, directional, p000777); interop README "Accessing C++ classes, structs, and members" gains one measured sentence (DD-1) | row 45 PARTIAL; W-046 |
| :129 | operator overloading | expressions/README.md; README.md "Operator overloading" (:3372) | row 46 DONE |
| :130-132 | synthesizing Carbon overloads for C++ types; exporting Carbon overloads | interop README "The operator interoperability model" (DD-1); README.md :3657 (directional) | row 47 PARTIAL (W-045); row 48 MISSING (W-054) |
| :133 | sum types | sum_types.md, pattern_matching.md, README.md "Choice types" | row 49 DONE |
| :134-135 | unions and C++ unions | unions.md (F-007) | row 50 DONE |
| :137-138 | generic functions and types, checked generics | generics/ | rows 51-52 DONE |
| :139 | definition-checked variadics | variadics.md (p002240) | row 53 DESIGN-ONLY (W-013) |
| :140 | integrated templates | templates.md (DD-1); README.md "Checked and template parameters" | row 54 PARTIAL (W-014, W-183) |
| :141-143 | template-style structural conformance | templates.md status and README.md :2890 note (state T, F-010); generics/template_constraints.md on SC-1 (held; linked at state L) | row 55 MISSING (SC-1, W-028) |
| :145 | importing C++ templates, instantiating on Carbon types | interop README "Using C++ templates" (DD-1, new, P17); README.md "Templates" (:3698, directional) | row 56 PARTIAL (W-043) |
| :146 | exporting Carbon templates | interop README "Using Carbon from C++" (DD-1, new: a call from C++ stops the compiler, PR-S); README.md "Templates" (:3698) | row 57 PARTIAL (W-044, W-191; RR-FX-1) |
| :147-148 | exporting checked generics as C++ templates | interop README "Using Carbon from C++" (P18, R33) | row 57 PARTIAL (W-044) |
| :149-150 | C++20 concepts and named predicates | interop README "Using C++ templates" (import pinned by testdata; export W-029); template_constraints.md "Mapping to and from C++20 concepts" on SC-1 (held; linked at state L) | row 58 PARTIAL (W-029) |
| :155-156 | separate declaration and definition; function overloading | functions.md; functions_overloading.md (F-009) | rows 59-60 DONE |
| :158 | importing C++ functions and methods | interop README "Function call syntax and semantics", "Overload resolution", "Constructors" (DD-1) | row 61 DONE |
| :159 | exporting Carbon functions and methods | interop README "Overload resolution" (exported overload sets, OV-3) and "Using Carbon from C++" (DD-1, new) | row 62 DONE |
| :160-161 | importing C++ overload sets | interop README "Overload resolution" | row 63 DONE |
| :162-164 | open overload sets as extension points | README.md :3681-3683 (`swap` "will correspond to a Carbon interface, on a case-by-case basis", directional); interop README "C++ ranges in `for` loops" (DD-1, new) for `begin` and `end` | row 64 PARTIAL (W-053) |
| :166-169 | conditions, loops | control_flow/, blocks_and_statements.md (DD-1) | rows 65-66 DONE |
| :171 | `switch` equivalents | pattern_matching.md "`match` in the 0.1 toolchain" (DD-1) | row 67 DONE; W-155, W-182, W-189 |
| :172-173 | sum types, `std::variant` and `std::optional` interop | pattern_matching.md, sum_types.md; interop README "Bi-directional type mapping: standard library types" (:282-286: other standard library types import as ordinary classes) | row 68 PARTIAL (W-011) |
| :174-175 | `if let` and `let else` | pattern_matching.md "Refutable pattern bindings" (F-011) | row 69 PARTIAL (W-080) |
| :176-177 | threading, atomics, memory model, synchronization | interoperability/threads_and_atomics.md (DD-1, new) | row 70 PARTIAL, DONE by D-DD-7 |
| :179-188 | error handling and C++ exception interop | error_handling.md (F-006) | rows 71-72 |
| :197-200 | fundamental types, tuple and array parts, pointers, operator interfaces | README.md "Primitive types" and "Tuples", tuples.md, values.md "Pointers", expressions/ | rows 73-76 |
| :202-204 | strings, Optional, slices | README.md "String types" (strings.md on PR 55, state L); README.md :858-860 (optional.md on OP-1, state L); slices.md (SL-1) | rows 77-79 PARTIAL |
| :206 | fundamental-type mapping | interop README "Integers" (DD-1), "Literals", "Character types"; README.md "Standard types" with DD-1's note | row 80 DONE |
| :207-213 | non-owning string and contiguous-container mapping | interop README "`std::string_view` and `str`", "`std::span` and `Core.Slice`" | rows 81-82 DONE |
| :214 | iteration-abstraction mapping | interop README "C++ ranges in `for` loops" (DD-1, new, P19, R34) | row 83 DONE |

Before DD-1, three interop items had no design section that a reader could
use: C++ templates used from Carbon (:145, :149-150), C++ use of Carbon beyond
exported overload sets (:146-148, :159), and C++ ranges in Carbon `for` loops
(:214). DD-1 adds a measured section for each (§2.7), so no item is left at
"none". The items whose design text is still directional upstream text (rows
45, 48, 64) or lives on a held branch (rows 55, 58, 77, 78) keep that text,
and DD-1's sections state the 0.1 behavior beside it.

#### §0.1f Every "provisional", "no design", "TBD" and "placeholder" occurrence

(Added 2026-10-13, review fold: B-M-8.) `grep -rniE 'provisional|no
design|TBD|placeholder' --include=*.md docs/design` at 162c7e839 finds 64
lines. Each is classified; "out" lines stay, and row 91's text states that
inline notes of this kind remain by design (§5).

| Class | Lines | Disposition |
| --- | --- | --- |
| placeholder boilerplate (5) | aliases.md:22, blocks_and_statements.md:21, templates.md:25, metaprogramming.md:21, pattern_matching.md:720 | **In**: status notes (§2.1-§2.6) |
| the README disclosure (4) | README.md:17 (TOC entry), :143 (heading), :145, :149 | **In**: the fork note after :149 (§2.9 item 6) |
| stale "no design ... through the proposal process" notes (5) | README.md:812 (tuples, p003646), :1038 (patterns, p002188), :3586 (importing, p006358), :3659 (operators, p006254), :3733 (standard types, p005448 and p006357) | **In**: one dated cohesion note each (§2.9 item 5) |
| string types (2) | README.md:624; expressions/literals.md:251 | **Held PR 55**: F-014's amendment follows README.md :633 on that branch; DD-1 adds a pointer to strings.md after literals.md:251 at state L (§2.13). Both stay true at state T, where no string design exists |
| inline provisional notes beside content (14) | README.md:765, :1257, :2167, :2181 (mixins, deferred by milestones.md:273), :2777, :3322, :3324, :3442, :3835 (the "Unfinished tales" disclosure, whose subsections DD-1 annotates one by one); code_and_name_organization/README.md:985; expressions/type_operators.md:47; classes.md:851, :2179; generics/terminology.md:557 | **Out**: category C, each qualifies the content beside it |
| notes that say "no longer provisional" (2) | README.md:3922, :3946 | **Out**: already resolved by OV-1/OV-3 and F-006 |
| placeholder syntax and open table cells (9) | values.md:1374, :1505 (`value_rep`, an open question); generics/details.md:562, :602 ("Syntax TBD" comments in examples); generics/appendix-witness.md:208, :222 (pseudo-code in an appendix); interoperability/literals.md:116, :117, :119 (TBD cells copied from accepted p006668:285-288, C++23 suffixes) | **Out**: category C; each is the accepted text's own open question, beside designed content |
| "placeholder" as a technical term or a description (23) | pattern_matching.md:276, :295 (`auto`); generics/details.md:738 (archetypes), :2509 (link text), :4271 and classes.md:1933 (proposal 1154's anchor); generics/terminology.md:614; sum_types.md:205; error_handling.md:422, :423, :430, :439, :757, :799, :894, :905 (the prelude's `Optional` class and an RTTI fallback); slices.md:48, :226, :229, :380, :389, :431 (the name `Buf`); functions_overloading.md:921 | **Out**: not markers |

### §0.2 Held PRs and branches that touch the same files (collision table)

Measured with `git diff --name-only 0bdce60a5...<branch> -- docs/` and the
fork-record paths; re-measured for rev 2 from each branch head with `git diff
162c7e839...<branch>` (heads then: SC-1 77838fdd5, PR 53 adaae4e35, PR 55
21307851a, PR 54 cb3ef2e74, PR 51 f96fe8a7a, OP-1 1fc03110e) (amended
2026-10-13, review fold: A-1 / A-12 / B-M-6 / B-m-1); re-measured for rev 4 at
the current heads, SC-1 a9c887101 and OP-1 379f20f67, the others unchanged
(PR 52 ea573f672): SC-1's file list and its templates.md hunk are unchanged,
and OP-1's discharge adds only the fork records of the "all of the above" row
(amended 2026-10-14, review fold: RR2-2). The writer re-reads every head at
discharge with `git for-each-ref`.

| Branch (PR) | Files DD-1 also edits | Their hunk | Expected effect at DD-1's integration |
| --- | --- | --- | --- |
| claude/carbon-fork-0-1-sc (SC-1) | docs/design/templates.md | replaces :109-111 (the last paragraph) with a dated F-010 amendment (unchanged at the head); its template_constraints.md has a "Mapping to and from C++20 concepts" section | conflict with DD-1's appended section (adjacent hunks): keep SC-1's paragraph, then DD-1's section; apply the state-L texts of §2.4 and §2.7's C++ templates section (§2.13) |
| claude/carbon-fork-0-1-safe (PR 53) | docs/design/README.md | insertions after :2150 and :2170 (hunk headers :2148 and :2168), and :3900-3910 (the Lifetime section, ending at `### Metaprogramming`, :3909) | conflict with DD-1's :3911 replacement (three lines below): keep both; README :3905 drops out of the W2 allowlist |
| PR 53, pages DD-1 does not edit at state T | docs/design/values.md (insertions after :137, :477 and :599: F-013 D-SAFE-7, D-SAFE-8, D-SAFE-17, the last pinned at :485 on the branch), docs/design/safety/mutation_safety.md (new: M7 "Data races" :257-270, M8 "Value bindings" :272-283, EX-M-4a :615-635, the `Core.Send`/`Core.Sync`/`Core.Freeze` facets :364-371), docs/design/expressions/arithmetic.md (insertion after :167; DD-1 only allowlists :184), slices.md, unions.md | — | cohesion at state L: assignment.md's swap paragraph cites D-SAFE-17 for the `let` form; the threads page cites M7 and D-SAFE-16 and disambiguates `Core.Sync`; M7 links the threads page (§2.13) |
| claude/carbon-fork-0-1-st (PR 55) | docs/design/README.md, docs/design/interoperability/README.md | README :633 note (after the provisional string-types note at :624); interop README note after :300 (the `std::string_view` section); arithmetic.md insertion after :188 | none expected (no shared hunk, no heading change); arithmetic.md:184 drops out of the allowlist; literals.md:251 gains DD-1's state-L pointer to strings.md |
| claude/carbon-fork-0-1-ev (PR 54) | docs/guides/tutorial.md:476-478, docs/guides/evaluator_faq.md:372-373 (state L only) | EV-1 creates these files | DD-1's state-L sentences replace "whose design sections are still placeholders" and "the design documents note their own placeholders" (§2.13) |
| claude/carbon-fork-0-1-ua2 (PR 51) | none in docs/design/ (it edits functions_overloading.md and slices.md); fork/conformance/programs/generics/templates_dependent_member.carbon (un-SKIP); fork/gap-analysis.md row 91's evidence cell (rewritten: re-read line numbers, 8 TODO headings) and W-014's notes | — | no docs conflict; row 91's cell conflicts with DD-1's rewrite, and DD-1's text replaces it at integration (it supersedes PR 51's re-read); W-014's evidence line is added to PR 51's text then (§8.5) |
| claude/carbon-fork-0-1-cmake (PR 52) | none in docs/design/ | — | none |
| claude/carbon-fork-0-1-op (PR 56, OP-1: discharged at 379f20f67 (W-058; W-170..W-179 and W-195 filed); amended 2026-10-14, review fold: RR2-2) | docs/design/README.md (insertion after :860, the `Optional(T*)` paragraph), docs/design/control_flow/loops.md (after :115), docs/design/error_handling.md (after :445), docs/design/optional.md (new) | no shared hunk with DD-1 | none expected; the W2 rule finds no hit in OP-1's docs tree that trunk lacks (fixer's runs over the head's docs/design/, for rev 2 and at 379f20f67 for rev 4); at state L the interop pointer section links optional.md (§2.13) |
| all of the above | fork/decision-log.md (every entry inserted after "### Full autonomy and the throughput protocol", :2843), fork/inventory/work-items.json, fork/gap-analysis.md (header and rows), fork/ORCHESTRATION.md, fork/conformance/README.md (generated table) | — | mechanical: DD-1's entry goes first in the landed region; ids disjoint; the gap header is recomputed from the merged rows; the table is regenerated with `runner.py --update-readme-table` |
| origin/claude/carbon-fork-0-1-7mwfb7-design-docs (stranded, 481e08c24) | holds a 2026-07-19 draft docs/design/interoperability/threading.md (628 lines, seven open sub-forks) and one inline-import paragraph | — | **not used as a source** (D-DD-7): D-DD-7 disposes of each of its seven sub-forks with the record that settles it, and leaves one open on the page; the page of §2.8 is written from F-008, fork/design-sprint/threading-atomics.md:184-224 and measurements (amended 2026-10-13, review fold: A-10) |

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
Counts are taken outside fenced blocks (a fence-aware count; a raw `grep -c`
also counts `#include` lines and list-like lines inside the new samples), and
heading sets are collected with `grep -nE '^#{1,6} '` on the same fence-masked
text (amended 2026-10-13, review fold: B-m-5). The files DD-1 edits only at
state L (expressions/literals.md, safety/mutation_safety.md, docs/guides/
tutorial.md and evaluator_faq.md) get their baselines in the integration
commit, measured on the merged trunk. Trunk's f67ab650d, after rev 3, changes
fork/ORCHESTRATION.md only: 534 lines, the same heading and list counts, and
the line cited above as :437 is :452 there (amended 2026-10-14, review fold:
RR2-FX-1).

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
    eight). The stub stays SKIP (D-DD-5), and commit 1 rewrites its SKIP text
    with current evidence (§2.11) (amended 2026-10-13, review fold: A-2 /
    B-1).
4.  fork/conformance/programs/generics/templates_dependent_member.carbon is SKIP
    on trunk with a 2026-07-19 reason ("Template lowering not implemented yet")
    that no longer holds: the program PASSes when run on the fork toolchain
    (P04's member access is the same shape). PR 51 removes the SKIP; DD-1 does
    not touch the program (it is PR 51's).
5.  W-080's notes say a refutable `var` root "stays behind TODOs"; `var 5 = n;`
    crashes instead (PR-B), on the fork and the nightly. The crash is in
    W-080's lane (the `var` spelling of a refutable root, which its fix
    diagnoses), so W-080's evidence gains the CHECK line and the probe; no
    separate item is filed (amended 2026-10-13, review fold: A-11 / B-m-3).
6.  W-014's notes on the UA-2 branch name "the cross-file template lowering
    CARBON_FATAL (lower/handle.cpp:513)" as the remaining cross-file blocker;
    a cross-library call crashes earlier, in check (PR-A), on the fork
    (import_ref.cpp:5087) and on the nightly (:4875). W-014's evidence gains
    both sites in the integration commit, after PR 51 is on trunk, so the edit
    applies to PR 51's text (amended 2026-10-13, review fold: A-13 / B-m-2).
7.  The workstream context describes "the operator interoperability model as
    OV-3/UN-2 landed it". Neither touched operators: OV-3 exported overload sets
    and UN-2 mapped unions. The operator model's 0.1 state is the upstream
    import direction (p006254 "Operator calls") with W-045 (missing imports)
    and W-054 (no export); §2.7 documents exactly that.
8.  Gap row 56 says "Carbon class types as template args error 'unsupported
    type used as template argument'". P17 instantiates `Cpp.Box(Point)` on a
    Carbon class and runs on the fork and the nightly, and the testdata the
    row cites (template/type_param.carbon `fail_unsupported_type.carbon`) uses
    `{}`, an empty struct type; W-043's own notes already ask to "re-check
    which sub-case is live". W-043's notes gain the measured answer (concrete
    Carbon classes work; the symbolic case PR-T does not); the row's status
    is W-043's to re-arbitrate, so DD-1 does not edit row 56 (added
    2026-10-13, review fold: B-M-5).
9.  W-044's notes say that export of a Carbon `template` function, as distinct
    from a checked generic, "exists at all only after template lowering
    (W-014)". The nightly exports and runs
    one (PR-S prints `42`); the fork's toolchain stops at a CHECK. W-191
    records it (added 2026-10-13, review fold: B-M-5; renumbered from W-190,
    RR-FX-1; W-190 stays unused, amended 2026-10-14, review fold: RR2-1).

### §0.5 Decisions this plan auto-adopts (R29(a), each with a break condition)

-   **D-DD-1 Editing posture.** On upstream pages every original paragraph and
    example stays. Only placeholder markers are replaced: the boilerplate
    paragraph and its `## TODO` heading become `## Status` with one dated
    status blockquote; a `TODO:` heading loses its prefix and gains content; a
    TODO-only body that has something to document becomes content (with a
    dated status note before it where no accepted proposal states the rules,
    as in assignment.md); a TODO note beside content becomes a dated note
    only where that note supplies what the marker asks for (README.md :2890,
    settled by F-010; :3911, an inline summary and the updated reference). New
    behavior goes in
    new sections titled "_topic_ in the 0.1 toolchain" (or under the formerly
    empty heading), after the original content. Where an original example is
    rejected by the toolchain, a dated "Fork note" directly after it quotes the
    measured diagnostic and points to the working form. A marker is never
    relabelled or replaced to get past the W2 rule: where a section has nothing
    to document beyond a future extension or a milestone deferral
    (comparison_operators.md "Custom result types"; README.md "Co-routines"
    and "Concurrency", deferred by milestones.md:268 and :271), the upstream
    marker stays and a dated note beside it states the 0.1 status (amended
    2026-10-13, review fold: A-8 / B-M-4; RR-N-3: rev 2's §2.9 item 4
    replaced the Co-routines and Concurrency markers, which this rule now
    forbids, and item 4 keeps them). Break: a
    reviewer shows that a note changes the meaning of accepted proposal text;
    that note is withdrawn and the divergence becomes a residue (D-DD-3).
-   **D-DD-2 Scope and the W2 arbiter.** The arbiter is a script rule over all
    of docs/design/ (§2.12): (a) no line matches the placeholder boilerplate
    (`skeletal design`, `it is a placeholder`, `should not be treated as
    accepted`, `Please feel welcome to rewrite`, and `provisional or
    placeholder`, whitespace-tolerant); (b) no heading's text starts with
    `TODO`; (c) no section's body consists only of TODO-marker paragraphs
    (optionally with "See ..." or "References" paragraphs); and (d) no section
    is empty without a subsection. Every clause matches regardless of case,
    clause (a) also across blockquote line breaks, and clause (c)'s markers
    include TBD and the list-item and HTML-comment forms (clause (d) and these
    extensions amended 2026-10-14, document-review fold: DR2-2 / DR2-8, under
    this decision's break condition: document review 2 showed placeholder
    forms the rule missed). Inline notes beside
    content (category C of §0.1c, §0.1f) are out of scope. Two lists qualify
    the result. `QUALIFIED` holds hits that stay by design because a DD-1 note
    in the same section answers them, and the checker requires that note's
    quoted text there: one entry, README.md "This document is provisional"
    (the upstream disclosure, kept under D-DD-1). `ALLOWLIST` holds hits that a
    later commit or a held PR removes, and it shrinks commit by commit (§2.12
    item 5): at commit 3 it holds exactly the two held-PR-owned hits of
    §0.1c (PR 53's Lifetime section, PR 55's arithmetic Strings section), and
    at state L it is empty. An allowlisted hit that no longer hits is itself an
    error (amended 2026-10-13, review fold: A-5 / B-2 / B-M-2 / B-M-3).
    **Deviation from W-065's arbiter, recorded:** W-065's notes call its
    arbiter "grep-verifiable ('no TODO/placeholder markers')"; this rule is
    narrower. Inline TODO, TBD and provisional notes beside content stay
    (category C: 110 `TODO` occurrences in 23 files at 162c7e839, less the
    ones DD-1 replaces), and DD-1's pages add quoted toolchain diagnostics
    that contain `semantics TODO`. The discharge records the before and after
    `TODO` counts per file in the decision-log entry, and row 91's text says
    that the remaining inline notes stay by design (amended 2026-10-13,
    review fold: B-M-4). Break: a document review finds a section a reader
    cannot understand that the rule misses, or a replaced marker that is a
    placeholder under another name; it joins the scope in the fold and the
    rule gains a clause.
-   **D-DD-3 Documentation, not design; F-016 not minted.** Each page states
    what an accepted proposal, a leads decision, or a fork decision fixes,
    what the toolchain does, and where they differ (both cited). A leads
    decision is the answer the leads record on a closed question-for-leads
    issue, which docs/project/evolution.md:425-428 makes "where the leads
    signal how it is resolved"; the page cites the issue and says when no
    proposal incorporates the answer yet. Toolchain defects, including a
    divergence from a leads decision, are residues; open questions stay open
    on the page, and a question is called open only after its issue's status
    has been checked. A behavior that none of these sources rules on is
    stated as measured, never as a rule. Rev 1's assignment text asserted an
    operation order for leads issue 686 without citing the leads' answer; rev
    2 reduced it to the measurements and called the question open; rev 3
    states the answer the leads gave on 2022-11-12 (issue 686's closing
    comment; issue 2489 tracks the proposal that is to incorporate it), which
    gives `(2, 1)` for both literal swaps, and the toolchain's `(2, 2)` as
    W-188 (§2.3, §8.10; amended 2026-10-13, review fold: A-1; RR-A-1). Break:
    if a page cannot be written without choosing a rule that neither a
    proposal, a leads decision, a fork decision, nor the toolchain fixes, the
    page names the open question and a residue is filed; minting F-016 needs
    the orchestrator.
-   **D-DD-4 Sample policy.** Every new code block is a complete Carbon file
    compile-verified on the fork toolchain and on the nightly. A RUNS sample is
    transcribed byte for byte into a conformance program (D-DD-5); a REJECTS
    sample is a fixture whose header pins the first error message, quoted in
    the page prose; a note on an unchanged upstream example quotes its measured
    diagnostic, pinned by a quote fixture (R11 for templates.md, X02 for
    pattern_matching.md's first `match` example; amended 2026-10-13, review
    fold: A-9). Fork-only samples say so in the
    sentence after them. Break: if a re-measure at state L changes an outcome,
    the page and fixture follow the toolchain, never the reverse.
-   **D-DD-5 The stub stays SKIP; the samples become documentation-sync
    programs under their feature bullets.** (Rewritten 2026-10-13, review
    fold: A-2 / B-1.) design_docs_placeholders.carbon stays SKIP, as row 88's
    program and SAFE-1's safe_carbon_design.carbon do, with its R10 reason
    refreshed (§2.11): what DD-1 changed, the checker's W2 rule as the grep
    arbiter, and the document reviews as the bullet's arbitration. The
    nineteen transcribed programs (P01-P19) are filed under the feature
    bullets they exercise, every one of which is already PASS on trunk
    (fork/conformance/out/scoreboard.json), so they are EV-1's
    "documentation-sync programs under a bullet that was already PASS"
    (D-EV-16) and change no rollup: bullets stay 48/56. A sample program
    cannot fail on the property the design-docs bullet names, so it never
    feeds that bullet. Break: if the orchestrator rejects the programs, they
    are dropped and the checker's `--toolchain` mode runs the RUNS samples in
    the land sequence instead.
-   **D-DD-6 The checker.** fork/designdocs/check_samples.py (§2.12), in the
    EV-1 style: R27 byte diffs of page blocks against programs and fixtures,
    quote checks, the W2 rule, and an optional `--toolchain` mode that compiles
    every fixture and checks its first error (or runs it and checks its
    stdout). It runs by hand per commit and in the land sequence, against the
    allowlist that commit sets (§2.12 item 5), and each commit message records
    the expected and the actual W2 output (amended 2026-10-13, review fold:
    B-M-2); at state L,
    if trunk's runner.py calls EV-1's checker from `--self-test`, DD-1's
    toolchain-free checks join it the same way. Break: if joining makes
    `--self-test` depend on a toolchain or exceed its budget, only the diff,
    quote and W2 checks join.
-   **D-DD-7 W-020's documentation half is absorbed.** A new page
    docs/design/interoperability/threads_and_atomics.md (the path F-008's paper
    names, threading-atomics.md:186-187) states F-008's seven-point contract
    with re-verified citations and one measured sample (P16); the interop README
    gains a short section pointing to it. W-020 is discharged and gap row 70
    goes PARTIAL → DONE (expected). This departs from fork/ORCHESTRATION.md:437,
    which says the F-008 portion of the stranded design-docs branch is ported
    "by [its] own workstream" by reconstructing the stranded draft: F8a-F8d
    finished without porting it, and the draft's seven open sub-forks are
    disposed of here, each with the record that settles it (amended 2026-10-13,
    review fold: A-10). (1) C++ language mode for examples and conformance:
    settled by practice; the F8 programs compile the Carbon side in Clang's
    default mode and the C++ oracle side at `-std=c++17`
    (fork/f008/plan.md:213-215), and the page's sample uses no C++20-only API.
    (2) Upstreaming policy for the fixes: not a design-page question; F-008
    calls the fixes "upstreamable" (fork/decision-log.md:1036), and the page
    states no policy. (3) `volatile` and C `_Atomic`: settled by F-008's
    contract, which the decision signed off "with any option"
    (threading-atomics.md:189-190), points 3 and 7 (:201-204, :221-224): no
    `volatile` and no `_Atomic` interop in 0.1, stated as non-goals on the page
    with no new diagnostics (the paper's open question 6, :514-517, asked only
    whether to call them out). (4) Reserving `Core.Thread`, `Core.Atomic` and
    `Core.MemoryOrder`: held PR 53 (F-013, D-SAFE-16, W-149) names
    `Core.Thread` and `Core.Atomic(T)` for its stage 5, which the page states;
    no record settles `Core.MemoryOrder`, so that part stays open, stated on
    the page (D-DD-3), and is not filed because no 0.1 behavior depends on it
    (amended 2026-10-14, document-review fold: DR1-3). (5)
    Memory-model arbitration depth: settled by F8a's six programs (W-020's
    notes: "all six F-008 conformance programs landed"), among them the
    exact-total counter cpp_atomic_global_counter_diff.carbon; no TSan run is in
    the scoreboard. (6) Whether L1's fix is 0.1-blocking: overtaken; F8d landed
    the fix (fork/decision-log.md:1247, F8d landing note), and
    cpp_thread_carbon_fn_diff.carbon PASSes. (7) The filename: settled by
    threading-atomics.md:186-187 (the paper names `threads_and_atomics.md`),
    W-020's title, and gap row 70. Break: if the orchestrator assigns W-020's
    documentation half to another workstream before commit 2 is written, the
    page and the pointer section are dropped and rows 70 and 91 stay PARTIAL,
    bounded by W-020.
-   **D-DD-8 Cohesion notes are bounded.** Beyond the placeholders, DD-1 adds
    only the notes listed in §0.1c (five stale "provisional" notes, the
    :3733 one also covering the `T&` to `T*` sentence at :3757-3758; the
    template-constraints TODO; the code-organization aliasing example; the
    comparison custom-result note beside its kept marker; the README
    disclosure note after :149), the measured sentence on inheritance in the
    interop members section, the three interop sections of §0.1e for
    milestone items that had no design section, and the state-L texts of
    §2.13 (the two EV-1 sentences, the expressions/literals.md:251 pointer to
    strings.md, the F-013 citations on assignment.md and the threads page, and
    the link from SAFE-1's M7 to the threads page) (amended 2026-10-13, review
    fold: A-3 / A-5 / A-12 / B-2 / B-M-5 / B-M-6 / B-M-8). Break: a reviewer
    judges a note to be design rather than documentation; it is reworded to
    cite its source or removed.
-   **D-DD-9 Two states.** State T is this branch (trunk 162c7e839, every PR
    above unmerged). State L is the integration commit, which merges trunk
    after OP-1 lands (never a rebase of submitted commits, AGENTS.md), resolves
    §0.2's expected conflicts, applies the state-L texts of §2 and §2.13
    (templates.md status, README :2890 note, the C++ templates section's
    concept link, the EV-1 sentences, the PR 53 citations and link, the
    strings pointer, the optional.md link, an empty W2 `ALLOWLIST`), adds
    F-013's scope to W-188's notes, applies the ledger amendments that land on
    held PRs' text (W-014, W-155, W-167), writes row 91 DONE when §5's
    condition holds, and re-runs
    every sample, fixture and the full suite on a toolchain built from the
    merged trunk. Break: if DD-1 must merge before any of SC-1, PR 51, PR 53,
    PR 54 or PR 55, it merges in state T, row 91 stays PARTIAL bounded by the
    missing state-L items (for PR 53 and PR 55, the TODO-only sections they
    replace, README.md "Lifetime and move semantics" and arithmetic.md
    "Strings"), and W-187 is filed to apply the state-L texts and ledger
    amendments and flip row 91 when those PRs land (amended 2026-10-13, review
    fold: B-M-3).
-   **D-DD-10 Residues.** W-182 to W-185, W-188, W-189 and W-191 (§8.5; W-191
    is rev 2's W-190, renumbered at rev 3 while OP-1 held W-190, RR-FX-1; OP-1
    has since moved to W-195 and W-190 stays unused, amended 2026-10-14,
    review fold: RR2-1) are filed
    at discharge with kind, bullet, evidence and the measured probe. W-188 is a
    toolchain-defect: a tuple or struct assignment whose literal right-hand
    side reads the target is assigned in place, element by element, and
    leaves `(2, 2)`, where the answer the leads gave on issue 686 (initialize
    a temporary from the right-hand side, destroy the destination, move the
    temporary into it; §8.10) gives `(2, 1)`; the upstream nightly behaves the
    same. F-013 D-SAFE-17 (claude/carbon-fork-0-1-safe:docs/design/values.md
    :485, "a value binding of a `Core.Plain` type acquires eagerly";
    safety/mutation_safety.md:415-416 lists `let`, by-value parameters and
    by-value `self`) rules on value bindings only; it gives the `let` form's
    `(2, 1)`, which agrees with issue 686's answer, and the integration commit
    adds that to W-188's notes (amended 2026-10-13, review fold: RR-A-1: rev
    2 filed W-188 as design-needed on the premise that issue 686 was
    unanswered, which the online check of §8.10 refutes; that deviation from
    review A's fix is withdrawn). Existing items
    are amended only where a finding sits inside their stated scope: W-080 (the
    `var 5 = n;` crash), W-053 (ranges whose iterators are raw pointers), W-043
    (its open "verify" note answered) at discharge; W-014 (PR-A's two crash
    sites), W-155 (R20 and PR-L) and W-167 (PR-I) in the integration commit,
    since the second and third exist only on PR 54 and PR 55 and PR 51 rewrites
    W-014's notes. Before filing, §8.5 scans titles and evidence across trunk
    and every live branch head for the same defect, not only the id maximum. Rev
    1's W-180 (W-155's defect), W-181 (inside W-080's lane) and W-186 (W-167's
    defect) are withdrawn by this break and stay unused (amended 2026-10-13,
    review fold: A-1 / A-4 / A-11 / B-M-1 / B-m-2 / B-m-3). Break: if review
    shows a residue is inside an existing item's scope, it is folded there and
    its id stays unused.
-   **D-DD-11 Reviews.** Two plan reviews (R29(c)) then a separate fixer (R11);
    a focused re-review of the fold and a separate fixer, repeated until a
    re-review returns a verdict other than REJECT, which the Status line
    records as the sign-off (amended 2026-10-13, review fold: RR-A-1);
    the writer; two document reviews of the landed pages by fresh agents
    (review A: contradictions with accepted proposals, sibling pages and fork
    decisions, including the held PRs' pages DD-1 meets at state L, and, for
    every replaced marker, a judgment whether the replacement is real content
    or a placeholder under another name; review B: every §4 row re-run with
    the checker's `--toolchain` mode and the runner, every citation opened).
    Both receive the bullet text, milestones.md:55-75 and :110-215 with
    §0.1e's coverage table, and read every touched page as an evaluator would
    ("understandable by evaluators", milestones.md:55-56) (amended
    2026-10-13, review fold: B-M-4 / B-M-5). Then a separate fixer, whose
    fold commit lands before the discharge commit (§3); one implementation
    review of programs, fixtures, checker and records (R29(c)); a separate
    fixer. A review silent for over an hour is relaunched (R29(e)); findings
    cite (R8); dispositions cite, not narrate (R17). Break: a document review
    returning REJECT triggers a second round of both.
-   **D-DD-12 Local gate (R28; a stated deviation from R23).** GitHub Actions
    on the repository is disabled and the owner's runner is never used, so the
    gate is local: prek to a fixpoint with R31 counts, `runner.py --self-test`,
    the checker with `--toolchain`, a full local conformance run on the
    container-built fork toolchain (private `--out`, R5) and a nightly run of
    the nineteen programs; each commit message records the results and
    §8.10's "Not run" list verbatim, as do the decision-log entry, the
    evidence of rows 91 and 70, and the PR body (§3) (amended 2026-10-13,
    review fold: B-M-7). Break: if a hosted or owner-dispatched conformance
    run becomes available before merge, it is the record (R9) and the local
    runs are corroboration.
-   **D-DD-13 Gap-row effect.** Row 70 PARTIAL → DONE by D-DD-7, written by
    the discharge commit after the document-review fold. Row 91 PARTIAL →
    DONE on document review (the rows 88-90 precedent), written only by the
    integration commit at state L, when PR 53 and PR 55 are on trunk, the W2
    `ALLOWLIST` is empty, and the document-review fold has landed; until then
    the discharge commit writes row 91 PARTIAL, bounded by "pending state L:
    PR 53's and PR 55's sections". Header: DONE plus one and PARTIAL minus one
    at the discharge, the same again at integration. Both are "expected, not
    of record" until the conformance run of record (amended 2026-10-13, review
    fold: B-M-3 / B-m-8). Break: if a document review leaves an in-scope
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
    measured content; new H2 sections "Using C++ templates" and "Using Carbon
    from C++" follow "Accessing global variables", a new H3 "C++ ranges in
    `for` loops" follows the `std::span` section, and a new H2 "Threads,
    atomics, and the memory model" points to the new page;
    the TOC is regenerated by the markdown-toc hook (amended 2026-10-13,
    review fold: B-M-5).
-   **interoperability/threads_and_atomics.md (new):** Overview, the contract,
    "In the 0.1 toolchain", Alternatives considered, References.
-   **README.md:** a fork note after the "This document is provisional"
    disclosure; `### Enums` content; Abstract machine content; a Metaprogramming
    note; Co-routines and Concurrency notes beside their kept upstream markers
    (amended 2026-10-13, review fold: RR-N-3); the template-constraints note;
    five "Fork note" blockquotes after stale provisional notes (amended
    2026-10-13, review fold: A-5 / A-8 / B-2 / B-M-8).
-   **Two more pages:** code_and_name_organization/README.md and
    expressions/comparison_operators.md, one note each; the comparison note
    follows the kept upstream marker (amended 2026-10-13, review fold: A-8).
-   **State L only:** expressions/literals.md (a pointer to strings.md),
    safety/mutation_safety.md (M7 links the threads page), docs/guides/
    tutorial.md and evaluator_faq.md (§2.13).

### §1.2 Samples, programs, fixtures

Each RUNS sample (P01-P19) is one fenced `carbon` block, a whole program with
`fn Run() -> i32`, transcribed byte for byte into
fork/conformance/programs/project/design_docs_<topic>.carbon after the header of
§2.11, which names the feature bullet the program is filed under. Each REJECTS
sample (R01-R30 except R11, and R32-R34; the id R31 is skipped so that it
never reads as the rulebook rule) is one fenced block equal to the body of
fork/designdocs/samples/<id>.carbon, whose header carries `// EXPECT-ERROR:
<message>`; the message is quoted in the page prose of the same section. R11
and X01 to X06 are quote fixtures: their header carries `// QUOTE: <text>`
that must appear in the named section, and `EXPECT-ERROR` or
`EXPECT-STDOUT`; only X02 has a page block, pattern_matching.md's unchanged
first `match` example (amended 2026-10-13, review fold: A-9 / A-14 / B-M-5 /
B-m-4; amended 2026-10-14, document-review fold: DR1-16 / DR1-8 / DR-FX-1,
which add X04 to X06). Probe-only facts (PR-A..PR-Z, PR-G2) are not on any
page as code; the page cites the residue, testdata or quote fixture that pins
them, and §4.3 keeps their sources for the reviewers.

### §1.3 The checker (summary; spec in §2.12)

One table in the script maps (page, section heading, block index) to a program
or fixture. The default run needs no toolchain: diffs, quotes, the W2 rule, and
an indented-fence check. `--toolchain PATH` adds the compile and run checks
for fixtures. Exit status 1 on any error, with every error listed.

### §1.4 Residue policy

A toolchain behavior is filed when it is a crash, or a divergence from an
accepted proposal, a leads decision or a fork decision that blocks a 0.1
bullet's documented behavior (W-182..W-185, W-188, W-189, W-191), unless an
existing
item already owns it, in which case that item's evidence gains the finding
(W-080, W-053, W-155, W-167, W-014; D-DD-10) (amended 2026-10-13, review fold:
A-1 / A-4 / B-M-1; RR-A-1).
A divergence that does not block a bullet (the parenthesized guard of R19,
constant-value aliases) is documented on the page with both citations and not
filed, because upstream owns both the text and the parser. Every filed
residue is cited on the page where the behavior is documented; a residue on a
held PR is cited at state T as "fork work item W-nnn (held PR nn)" and
without the parenthesis at state L.

## §2 Specification, page by page

Conventions for every text below: the fenced `markdown` blocks are the exact
page text to insert (the writer replaces `2026-10-DD` with the commit date and
otherwise copies byte for byte; prek may re-wrap prose but never code). Each
`carbon` block inside them is the sample file named in the line before the
block, already verified (§4). The table-of-contents marker pair that each page
carries is regenerated by the markdown-toc hook and is never written by hand.
A dated note has one of two labels: `**Fork status (2026-10-DD).**` for a note
that replaces a placeholder or opens a section DD-1 wrote, and
`**Fork note (2026-10-DD).**` for every other annotation (amended 2026-10-14,
document-review fold: DR2-3). The texts below are the pages as the
document-review fold left them; each changed passage carries its fold mark
after the block.

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
file-scope variable, or, unlike the language overview's rule (below), a
constant value. Every use of the alias is a use of the
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
is rejected:

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

(The first paragraph's constant-value clause and the runtime-value sentence
are amended 2026-10-14, document-review fold: DR1-10: the opening list
qualifies the constant value against the overview's rule, and the sentence no
longer gives a rationale that the constant-value alias contradicts.)

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
> does not accept a block on its own as a statement, which proposal 162's
> grammar allows, so the overview's second example is rejected. How a leading
> `{` is told apart from a struct literal is an open question of the
> [struct literal design](classes.md#literals), and one option it lists would
> keep this behavior.
````

(The last two sentences are amended 2026-10-14, document-review fold: DR1-4:
classes.md:563-570, the struct literal design of proposal 561, records how a
leading `{` is disambiguated as an open question, and one listed option is
the toolchain's behavior, so the page no longer presumes that bare blocks
become statements.)

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
arm (fork work item W-155, on held PR 54).

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
How a `{` at the start of a statement is told apart from a struct literal is an
open question of the [struct literal design](classes.md#literals), and one of
the options it lists, allowing `{` to start a compound statement only after a
keyword that requires one, is what the toolchain does. In 0.1, a nested scope
needs a statement that has a block, such as `if (true) { ... }`.
````

(The last paragraph is amended 2026-10-14, document-review fold: DR1-4:
"Until that is resolved" is dropped, the classes.md open question is cited,
and W-185 is filed as design-needed, §8.5.)

Counts after: H2 3 → 4, dash items 2 → 10 (TOC plus seven list items), no
ordered items. Samples: P02 (design_docs_statements.carbon), R05, R06, R04.

### §2.3 docs/design/assignment.md

Edit 1 replaces line 161 (`_TODO_: Describe the rules for assignment in these
cases.`) with the text below; lines 163-164 (the "See leads issue" line and
its link to issue 686) stay after it (amended 2026-10-14, review fold: RR2-3).

(The text below is amended 2026-10-13, review fold: A-1 / B-M-1 / B-m-7: the
status note no longer calls issue 686 open, and the last paragraph states only
measurements; amended 2026-10-13, review fold: RR-A-1: the last paragraph
states the answer the leads gave on issue 686, checked online (§8.10), and the
toolchain's divergence from it, W-188, and the status note says that no
proposal incorporates that answer yet.)

````markdown
> **Fork status (2026-10-DD).** No accepted proposal states these rules:
> proposal 2511 leaves the semantics of assignment for these types to leads
> issue 686, below, whose answer no proposal incorporates yet. The 0.1
> toolchain implements the following.

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
``cannot copy value of type `Light` ``, and it does not implement `match`
([`match` in the 0.1 toolchain](pattern_matching.md#match-in-the-01-toolchain)).

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
[construction rule](classes.md#access-control-for-construction) forbids (fork
work item W-167, on held PR 55).

When the right-hand side reads the object being assigned, the result depends
on how the statement is written. With `t` holding `(1, 2)`, `t = (t.1, t.0);`
assigns element by element from the literal and leaves `(2, 2)`, and
`s = {.a = s.b, .b = s.a};` does the same to a struct holding `.a = 1` and
`.b = 2`. Binding the right-hand side first,
`let u: (i32, i32) = (t.1, t.0); t = u;`, or copying into a `var` first, as
the last lines of the example do, leaves `(2, 1)`. Leads issue 686, linked
below, was answered in 2022: by default, assignment initializes a temporary
from the right-hand side, destroys the destination, and moves the temporary
into it, and a type may customize assignment where a different approach is
more efficient. No proposal incorporates that answer yet (proposal 2511 does
not; [issue 2489](https://github.com/carbon-language/carbon-lang/issues/2489)
tracks one). Under it, both literal forms leave `(2, 1)`; the 0.1 toolchain's
`(2, 2)` differs (fork work item W-188).
````

(Amended 2026-10-14, document-review fold: DR2-6: the fork-only sentence also
names the nightly's missing `match`, its third error on P03 after the two
copy errors; DR1-11: W-167's behavior violates classes.md's "Access control
for construction" (:2156-2159), not the private-access paragraph, so the link
names that rule.)

At state L (PR 53 merged), this sentence follows the last one (amended
2026-10-13, review fold: RR-A-1: rev 2's state-L text called the literal
form's result an open question):

````markdown
Fork decision F-013 (D-SAFE-17,
[Value expressions](values.md#value-expressions)) makes a value binding of a
`Core.Plain` type, such as `i32` or a tuple of `i32`, acquire eagerly, which
gives the `let` form's `(2, 1)`; F-013 and the answer to issue 686 agree on
that result.
````

**The issue 686 record, checked online on 2026-10-13** (added 2026-10-13,
review fold: RR-A-1). Issue 686, "Operation order in struct/class
assignment/initialization"
(https://github.com/carbon-language/carbon-lang/issues/686), opened by josh11b
on 2021-07-28, was closed as completed by chandlerc on 2022-11-12. The
closing comment reads "Confirmed with leads and we're good with the correct
thing @zygoloid describes here:", then zygoloid's three steps, "initialize a
temporary object from the right-hand side", "destroy the destination", and
"move the right-hand side into the left-hand side", then "And then allow
customizing assignment when a different approach would be more efficient",
and "Marking as closed with this answer, but this one we do still need a
proposal for (and I think for assignment more generally)". On 2023-06-02
josh11b wrote that proposal 2511 "implements assignment statements, but did
not incorporate the decision of this issue", and that issue 2489 "is tracking
that work". Issue 2489, "Create assignment order proposal"
(https://github.com/carbon-language/carbon-lang/issues/2489), opened by
josh11b on 2022-12-21, is open and says that issue 686 "has a decision for
how assignment works for classes by default". The page's clause on
customizing follows the closing comment's own wording; the re-review's
suggested "where reinitializing in place is safe" is not what the comment
says, which is the one cited wording deviation of the RR-A-1 fold.

Counts after: unchanged (no heading, no list item). Samples: P03
(design_docs_assignment.carbon, fork-only), R07, X01 (quote fixture for the
`(2, 2)` claims), X03 (quote fixture for the `let` form's `(2, 1)`), PR-I
(W-167), PR-M (field order), PR-U.

### §2.4 docs/design/templates.md

Edit 1 replaces lines 22-27 with the **state T** text:

````markdown
## Status

> **Fork status (2026-10-DD).** Template generics are accepted: proposal 2200
> makes them part of Carbon, with the terminology of proposal 2138 and the
> name-lookup rules of question-for-leads issue 949 and proposal 989, and the
> [language overview](README.md#checked-and-template-parameters) summarizes the
> accepted design. The [overview](#overview) below is an older sketch, kept
> unchanged. The fork notes in it mark the three places where it and the 0.1
> toolchain differ (the illustrative `buf(T)`, the `Convert(i, f32)` example,
> and specialization). The sketch also differs from proposal 2200 itself:
> proposal 2200 lets a specialization change only an implementation and
> rejects ad hoc API specialization (its "Alternatives considered"), which the
> sketch's Overloading section anticipates, and its template constraints,
> below, answer the open question of the sketch's last section. Where the 0.1
> toolchain differs from proposal 2200 is listed under "Limits of the 0.1
> toolchain" in
> [Templates in the 0.1 toolchain](#templates-in-the-01-toolchain) (fork work
> items W-183 and W-014, and `match` on template-dependent values). Template
> constraints are accepted: proposal 818 introduced `template constraint`
> declarations, whose member requirements proposal 2200 specifies, and fork
> decision F-010 adds `require` validity blocks and boolean predicates. Member
> requirements are implemented on a held fork branch (SC-1), and `require`
> blocks and predicates are fork work item W-028; none of them is in the
> toolchain this page describes. What the 0.1 toolchain implements is
> documented, with examples that compile, in
> [Templates in the 0.1 toolchain](#templates-in-the-01-toolchain).
````

(Amended 2026-10-13, review fold: A-6 / B-m-6: the differences are listed,
and the F-010 sentence no longer says SC-1 implements all three forms.
Amended 2026-10-14, document-review fold: DR1-1: rev 4's "no other
difference from proposal 2200 is known" was false under either reading, since
the page's own W-183 limit and `match` limit are toolchain divergences from
proposal 2200, and the sketch's anticipated specialization is what
p002200:218-225 and :935-1000 reject; the note states both comparisons.
DR1-2: `template constraint` declarations and their member requirements are
accepted design (p002200:127-129 and :348-357, proposal 818), which F-010
adopts and extends with `require` blocks and predicates
(fork/decision-log.md:1357-1362), so the note attributes each. DR2-4: "the
SC-1 workstream" is now "a held fork branch (SC-1)".)

At **state L** (SC-1 merged), the sentences "Member requirements are
implemented ... describes." become:

````markdown
> [Template constraints](generics/template_constraints.md) specifies all
> three, and the toolchain implements member requirements; `require` blocks
> and predicates are fork work item W-028.
````

(re-wrapped inside the status blockquote; amended 2026-10-14,
document-review fold: DR1-2).

Edit 2 inserts after line 58 (the paragraph after the `Stack` example):

````markdown
> **Fork note (2026-10-DD).** `buf(T)` is illustrative; Carbon has no `buf`
> type, and the fork's heap buffer is `Core.Buf(T)` ([Slices](slices.md)). A
> class with a `template` parameter compiles and runs in the 0.1 toolchain, as
> `Holder` does in
> [Templates in the 0.1 toolchain](#templates-in-the-01-toolchain).
````

(Amended 2026-10-13, review fold: A-14 / B-m-4: the claim is now pinned by
P04's `Holder`.)

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
(`class Holder(template T: type)`). A function with a template parameter is
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

// A class with a template parameter; its members are checked for each
// argument.
class Holder(template T: type) {
  var item: T;
  fn Get(self) -> T { return self.item; }
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
  let h: Holder(i32) = {.item = 8};
  Core.Print(h.Get());
  return 0;
}
```

This prints `3`, `70`, `12`, `7`, `42`, and `8`.

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

Limits of the 0.1 toolchain:

-   Member lookup into a template parameter does not consult the parameter's
    constraint. Proposal 2200 looks a name up both in the argument type and in
    the interface constraint; the toolchain looks only in the argument type, so
    a member that the type provides only through an `impl` without `extend` is
    not found (fork work item W-183). Declaring it with
    `extend impl as HasArea` makes the last example below compile.
-   A template function defined in one library and called from another stops
    the compiler during checking, as it does in the upstream nightly (W-014).
-   A `match` on a template-dependent value is not supported (it reports
    ``semantics TODO: `match on unsupported scrutinee type` ``), so the
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

As the accepted design specifies, an interface constraint is satisfied only by
types that implement the interface: for a class `Circle` with an `Area` method
and no `impl`, a call `Report(c)` is rejected with
``cannot convert type `Circle` into type implementing `HasArea` ``. A
constraint on the members a type declares is a `template constraint`
(proposals 818 and 2200; see [Status](#status)).
````

(The limits list is amended 2026-10-14, document-review fold: DR1-7: the list
header no longer says each item is a filed work item; the nominal-interface
item, which is accepted design and no limit, becomes the last paragraph; the
`match` item quotes its `semantics TODO`. DR2-5: the W-183 item points to
"the last example below", and the `Circle` paragraph says what `Circle` is.
DR1-2: the paragraph's last sentence cites proposals 818 and 2200. Fixer
finding DR-FX-1: quote fixture X05 pins the `Circle` diagnostic, which no
fixture pinned.)

At state L the paragraph's last sentence becomes (amended 2026-10-14,
document-review fold: DR1-2 / DR1-7):

````markdown
constraint on the members a type declares is a `template constraint`
([Template constraints](generics/template_constraints.md)).
````

Counts after: H2 3 → 4, H3 4, dash items 6 → 10 (TOC plus three list items;
amended 2026-10-14, document-review fold: DR1-7), no ordered items. Samples:
P04 (design_docs_templates.carbon, under "Generics: Integrated templates";
rev 2 adds `Holder`, amended 2026-10-13, review fold: A-14 / B-m-4), R08,
R10, R09; quote fixtures R11 (edit 3) and X05 (the `Circle` paragraph); probes
PR-A, PR-D, PR-E, PR-J, PR-K, PR-N.

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
argument. Two function modifiers extend this to calls. Accepted proposals 7140
and 7697 and [function types](functions.md#function-types-and-values) use
`musteval fn` in examples, no proposal and no other design page shows
`eval fn` in an example, and no proposal designs either modifier yet:

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

with ``non-constant call to compile-time-only function``. A plain `fn` with a
body is not evaluated during compilation (only `eval` and `musteval`
functions, and builtin functions such as the prelude's operator functions,
are):

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
Samples: P05 (design_docs_compile_time.carbon, under "Generics: generic
functions and types"), R12, R13, R14; probe PR-C. (The modifier sentence is
amended 2026-10-13, review fold: A-7; amended 2026-10-14, document-review
fold: DR2-5: it no longer says `eval fn` appears on no design page, which
this page contradicts. The plain-`fn` sentence is amended 2026-10-14,
document-review fold: DR1-6: a builtin `fn`, such as an `Add` whose body is
`= "int.sadd"`, is evaluated in an array bound on the fork and the nightly,
probe PR-W, §4.3.)

### §2.6 docs/design/pattern_matching.md

Edit 1 replaces lines 718-721 (the placeholder paragraph) with:

````markdown
> **Fork status (2026-10-DD).** Accepted proposal 5164 marks the `match`
> statement design of this section, apart from [guards](#guards), as not yet
> accepted; this note replaces the placeholder paragraph that proposal wrote.
> Proposal 2188 accepts the pattern, exhaustiveness, and guard rules the
> section relies on, and proposal 5164 their object semantics. The prose and
> first example below are kept unchanged. The fork implements `match`, and
> [`match` in the 0.1 toolchain](#match-in-the-01-toolchain) documents what
> compiles today. The first example does not: the toolchain rejects it with
> ``semantics TODO: `match on unsupported scrutinee type` ``, because a `match`
> on a tuple holding `f32` values is not supported (and `Pi` is not declared).
````

(Amended 2026-10-13, review fold: A-9: the note keeps proposal 5164's own
statement, p005164:44-45, and quotes the first example's measured diagnostic,
pinned by quote fixture X02, whose body is that example, :730-745.)

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
``expected `(` after `if` ``. A `match` is a statement: proposal 2188 leaves
`match` expressions to future work, and the toolchain does not parse them.

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
block; `default` matches every value. The toolchain checks exhaustiveness and
usefulness by the rules
[specified above](#refutability-overlap-usefulness-and-exhaustiveness), with
one difference listed under "Not in the 0.1 toolchain" below: a `match`
without an unguarded `default` arm must cover every alternative of a choice,
both `bool` values, or have an unguarded irrefutable arm; for integer, tuple,
and struct scrutinees only an irrefutable arm counts, because the toolchain
never treats a set of expression patterns as exhaustive, even constant tuples
of `bool` or choice values that the rules above make exhaustive. A guarded arm
never counts toward coverage; an arm that can never match is an error.

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
    is rejected (fork work item W-155, on held PR 54).
-   A set of tuple patterns never counts as exhaustive unless one arm is
    irrefutable: the four arms `case (false, false)`, `case (false, true)`,
    `case (true, false)` and `case (true, true)` on a `(bool, bool)`
    scrutinee are rejected with
    `` `match` on `(bool, bool)` has no `default` arm and no `case` arm that
    matches every value ``, and so are the two arms `case (true, x: i32)` and
    `case (false, y: i32)` on a `(bool, i32)` scrutinee, although each set
    covers every value by the rules above, which treat a constant tuple as a
    tuple pattern and `bool` like a choice type; a `default` or an irrefutable
    arm is needed (W-189; pinned by `fail_bool_pair_enumeration.carbon` in
    `toolchain/check/testdata/match/fail_int_nonexhaustive.carbon`).
-   An alternative pattern inside a tuple pattern or a payload subpattern is
    read as an expression, so the usefulness example above cannot be written
    yet (W-182).
-   An alternative pattern written with its choice type's name, such as
    `Opt.None` or `Opt.Some(n: i32)` for a choice `Opt`: the first reports
    ``semantics TODO: `qualified alternative pattern in match case` `` (pinned
    by `fail_todo_qualified_pattern.carbon` in
    `toolchain/check/testdata/match/fail_choice_alternative_pattern.carbon`),
    and the second is not parsed as a pattern and reports
    ``name `n` not found``; the leading-dot forms `.None` and `.Some(n: i32)`
    work.
-   A scrutinee of any other type, including floating-point types, `str`,
    classes, and template-dependent types, so the [Templates](#templates)
    rules do not apply yet; expression patterns that are not constants, such
    as a variable; and compile-time bindings in a `case`.
-   A refutable pattern in a plain `var` declaration, such as `var 5 = n;`
    above, stops the compiler instead of being diagnosed (W-080).

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

(The limits list is amended 2026-10-13, review fold: A-4 / A-11 / B-M-1 /
B-m-3: the tuple-exhaustiveness item and W-189 are added, W-180 becomes
W-155, and W-181 becomes W-080. Amended 2026-10-14, document-review fold:
DR1-8: `match` expressions, which p002188:1173-1191 leaves to future work and
nothing designs, leave the list for a sentence after the grammar; the W-189
item covers every tuple-pattern set without an irrefutable arm, probe PR-X
(`(bool, i32)`); and an item for alternative patterns written with the
choice type's name is added, the `Opt.None` form pinned by the testdata
`semantics TODO` and the `Opt.Some(n: i32)` form by quote fixture X06. The
grammar's `[...]?` stays, as DR2-5's last item is rejected: it is the
notation of the upstream guard production at pattern_matching.md:816, which
the 0.1 grammar mirrors.)

Counts after: H4 10 → 11, dash items 112 → 122 (TOC plus nine list items;
amended 2026-10-14, document-review fold: DR1-8), ordered items unchanged.
Samples: P06 (design_docs_match.carbon, fork-only, under "Control flow:
matching — good switch equivalents"), R15-R22; quote fixtures X02 (edit 1)
and X06; probes PR-B, PR-D, PR-F, PR-L, PR-P, PR-R, PR-X, PR-Y, PR-Z.

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
`inline Cpp` declaration may instead appear among Carbon declarations, and its
C++ code can call the Carbon declarations above it through the `Carbon`
namespace; it requires an `import Cpp` declaration earlier in the file, such
as `import Cpp;` or the `import Cpp inline` above.

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
`toolchain/check/testdata/interop/cpp/basics/inline/` pin them. Without an
earlier `import Cpp`, the `inline Cpp` declaration is an error:

```carbon
fn Twice(n: i32) -> i32 { return n * 2; }

inline Cpp '''c++
inline int CallTwice(int n) { return Carbon::Twice(n) + 1; }
''';
```

The toolchain reports ``name `Cpp` not found``.
````

(Amended 2026-10-13, review fold: A-14 / B-m-4: "after any `import Cpp`" read
as "regardless of any import"; the rule is stated, and R32 pins the
rejection, which is probe PR-G as a page block; PR-G2 shows a bare
`import Cpp;` is enough. Amended 2026-10-14, document-review fold: DR1-16:
quote fixture X04 pins the escape-sequence sentence with both working forms,
and probe PR-V, §4.3, the unescaped form's rejection; the page text is
unchanged. DR1-12, the leads question on where `import Cpp inline` may
appear, is not folded: its status could not be checked online in the fold's
session, and D-DD-3 calls a question open only after that check; it is on
the list for commit 4/4.)

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
toolchain reports `no matching function for call to 'Inc'`.

Inheritance works across the boundary in both directions with a single base: a
Carbon class can `extend base` a C++ class, using it as its hierarchy root, and
override its virtual functions, and C++ code can derive a class from an
exported Carbon base class (the fork's conformance programs
`fork/conformance/programs/interop/inherit_carbon_extends_cpp.carbon` and
`fork/conformance/programs/interop/inherit_cpp_extends_carbon.carbon`).
Multiple, virtual, and diamond
inheritance, and exporting an abstract class whose destructor is not virtual,
are fork work item W-046.
````

(The program paths are amended 2026-10-14, document-review fold: DR2-4: they
are written from the repository root, as the page's "Overload resolution"
section writes its program path.)

(Amended 2026-10-13, review fold: B-M-5: the inheritance sentence covers
milestones.md:125-128, pinned by the two PASSing programs, §4.2.)

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
is `Core.Optional(Core.CppCompat.VoidBase*)`. No accepted proposal maps C++
references yet: proposal 5434, which introduces Carbon's `ref` parameters,
leaves the modeling of C++ references to a future proposal. The 0.1 toolchain
maps them onto Carbon's parameter forms: a parameter of type `T&` is a `ref`
parameter, whose argument is marked `ref`; a `const T&` parameter takes a
value; a function returning `T&` returns a durable reference expression, which
can be assigned; and a field of reference type is reached through a pointer
(`*s.r`, pinned by
`toolchain/check/testdata/interop/cpp/class/import/field.carbon`). C++
references are therefore not translated to `T*`, as the
[language overview's standard types](../README.md#standard-types) section
once planned. A `const` member function can be called on a value
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
  // `const int* _Nonnull` is `const i32*`, and `i32*` converts to it.
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

(Amended 2026-10-13, review fold: A-3: proposal 5434 defers C++ references,
p005434:897-900, so the mapping is attributed to the toolchain, and the
section says that references are not the `T*` of README.md:3757-3758.
Amended 2026-10-14, document-review fold: DR1-9: the sample's comment names
`const int* _Nonnull`, the parameter type `ReadThrough` declares; a plain
`const int*` is `Core.Optional(const i32*)`, as the prose says; P13 is
regenerated from the page block, and only that comment line changes.)

**New sections**, inserted after the "Accessing global variables" section
(line 246) and before "Bi-directional type mapping: primitives and core types"
(line 248), for the milestone items of §0.1e that had no design section
(added 2026-10-13, review fold: B-M-5):

````markdown
## Using C++ templates

A C++ template is used from Carbon as C++ code uses it. A function template is
called like a function, and C++ deduces its template arguments from the Carbon
arguments. A class template is named with its template arguments in
parentheses, `Cpp.Box(i32)` for `Box<int>`, and each argument list names a
distinct type; the standard library's templates work the same way, such as
`Cpp.std.vector(i32)`. A template argument can be a Carbon class type, so a
C++ template can be instantiated on a Carbon type.

```carbon
import Core library "io";

import Cpp inline '''c++
template <typename T>
T Larger(T a, T b) { return a < b ? b : a; }

template <typename T>
struct Box {
  T value;
  T Get() const { return value; }
  static Box Make(T v) { return Box{v}; }
};
''';

class Point {
  var x: i32;
  var y: i32;
}

fn Run() -> i32 {
  // C++ deduces a function template's arguments from the Carbon arguments.
  Core.Print(Cpp.Larger(3, 7));
  // A class template takes its template arguments in parentheses, and each
  // argument list names a distinct type.
  let b: Cpp.Box(i32) = Cpp.Box(i32).Make(5);
  Core.Print(b.Get());
  // A C++ template can be instantiated on a Carbon class type.
  let p: Point = {.x = 3, .y = 4};
  let boxed: Cpp.Box(Point) = Cpp.Box(Point).Make(p);
  Core.Print(boxed.Get().y);
  return 0;
}
```

This prints `7`, `5`, and `4`. Limits in 0.1: a checked generic's symbolic
type parameter cannot yet be a C++ template argument, so `Cpp.Box(T)` in the
body of a function with a parameter `[T: type]` does not compile (fork work
item W-043). A C++20 concept applied to types is a compile-time `bool`, so
`Cpp.IsLarge(Cpp.Small)` can be a generic argument
(`toolchain/check/testdata/interop/cpp/template/concept.carbon`); Carbon
constraints are not exported as C++ concepts (W-029). Using Carbon generics
from C++ is described in [Using Carbon from C++](#using-carbon-from-c).

## Using Carbon from C++

C++ code names Carbon declarations through the `Carbon` namespace:
`Carbon::Twice(7)` calls the Carbon function `Twice`, and `Carbon::Counter` is
the Carbon class `Counter`, whose fields, methods, and class functions C++ uses
as its members. A method declared with `ref self` can be called only on a
non-`const` object that is not a temporary, and one declared with `self` on
any object (`toolchain/check/testdata/interop/cpp/class/export/method.carbon`).
C++ code in the same file reaches Carbon this way from an `inline Cpp`
declaration, placed after the Carbon declarations it names as in the sample
below. A checked generic function
whose generic parameters are types is a C++ function template, and C++ deduces
its arguments; an exported [overload set](#overload-resolution) is resolved by
C++'s rules.

```carbon
import Core library "io";
import Cpp;

class Counter {
  var n: i32;
  fn Make(start: i32) -> Counter { return {.n = start}; }
  fn Get(self) -> i32 { return self.n; }
  fn Add(ref self, k: i32) { self.n += k; }
}

fn Twice(n: i32) -> i32 { return n * 2; }

interface Doubler {
  fn Double(self) -> Self;
}

class Meters {
  var n: i32;
  fn Make(v: i32) -> Meters { return {.n = v}; }
  fn Value(self) -> i32 { return self.n; }
  impl as Doubler {
    fn Double(self) -> Self { return {.n = self.n * 2}; }
  }
}

// A checked generic is exported as a C++ function template.
fn DoubleIt[T: Doubler](x: T) -> T { return x.Double(); }

// C++ code names Carbon declarations through the `Carbon` namespace.
inline Cpp '''c++
inline int UseCarbon(int start) {
  Carbon::Counter c = Carbon::Counter::Make(start);
  c.Add(3);
  return Carbon::Twice(c.Get());
}

inline int UseGeneric() {
  return Carbon::DoubleIt(Carbon::Meters::Make(21)).Value();
}
''';

fn Run() -> i32 {
  Core.Print(Cpp.UseCarbon(4));
  Core.Print(Cpp.UseGeneric());
  return 0;
}
```

This prints `14` and `42`. A generic parameter that is not a type is not
exported:

```carbon
import Cpp;

fn Times[N: i32](x: i32) -> i32 { return N * x; }

inline Cpp '''c++
inline int UseTimes() { return Carbon::Times<3>(2); }
''';
```

The toolchain reports
``semantics TODO: `binding maps to a non-type template parameter` `` (fork work
item W-044). A Carbon function with a `template` parameter cannot yet be
called from C++: the call stops the compiler (fork work item W-191). Carbon
operator implementations are not exported as C++ operators
([The operator interoperability model](#the-operator-interoperability-model)),
and inheritance across the boundary is described in
[Accessing C++ classes, structs, and members](#accessing-c-classes-structs-and-members).
````

**New section**, an H3 inserted at the end of "Bi-directional type mapping:
standard library types", after the `std::span` section, which ends at line
348, and before the threads section below (added 2026-10-13, review fold:
B-M-5):

````markdown
### C++ ranges in `for` loops

A C++ range can be the range of a Carbon `for` loop. For a C++ class whose
`begin` and `end` are found as members or by argument-dependent lookup and
return an iterator of class type, the toolchain implements `Core.Iterate`, and
the loop calls `begin` and `end` and dereferences and increments the iterator,
as a C++ range-based `for` does (the fork's conformance programs
`fork/conformance/programs/interop/cpp_range_member_begin_end_iterate.carbon`
and `fork/conformance/programs/interop/cpp_range_adl_begin_end_iterate.carbon`).
Standard library containers are ranges this way.

```carbon
import Core library "io";

import Cpp inline '''c++
#include <vector>

inline std::vector<int> MakeVector() { return {2, 4, 6}; }
''';

fn Run() -> i32 {
  // A C++ range is a Carbon `for` range: the loop calls its `begin` and
  // `end`, and dereferences and increments the iterator.
  var v: Cpp.std.vector(i32) = Cpp.MakeVector();
  var sum: i32 = 0;
  for (n: i32 in v) {
    sum += n;
  }
  Core.Print(sum);
  v.push_back(8);
  var count: i32 = 0;
  for (unused n: i32 in v) {
    ++count;
  }
  Core.Print(count);
  return 0;
}
```

This prints `12` and `4`. A class whose `begin` and `end` return raw pointers
is not yet a range:

```carbon
import Core library "io";

import Cpp inline '''c++
struct Digits {
  int values[3] = {1, 2, 3};
  int* begin() { return values; }
  int* end() { return values + 3; }
};
''';

fn Run() -> i32 {
  var d: Cpp.Digits = Cpp.Digits.Digits();
  var product: i32 = 1;
  for (n: i32 in d) {
    product *= n;
  }
  Core.Print(product);
  return 0;
}
```

The toolchain reports
``cannot access member of interface `Core.Iterate` in type `Cpp.Digits` that does not implement that interface``
(fork work item W-053).
````

(The program paths are amended 2026-10-14, document-review fold: DR2-4.)

**New section**, inserted before the operator section (after the section on
`std::span` and `Core.Slice`, which ends at line 348, and after the ranges
section above):

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
`<=>`), operators whose result is not `bool` where Carbon needs a `bool`, and a
set of several `operator*` overloads. Some C++ operators have no Carbon
operator to map to, by design: unary `+`, postfix `++` and `--`, `!`, `&&`,
`||`, and the comma operator, since Carbon's logical operators are `not`,
`and`, and `or` on `bool`; the
[language overview](../README.md#operator-overloading-1) keeps operators like
these C++-only. Assignment from an `int` fails:

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

(Amended 2026-10-13, review fold: A-14: the operator list is split into the
W-045 import gaps, pinned by the operators/ and deref.carbon `fail_todo`
splits, and the operators with no Carbon spelling, which README.md:3685-3687
keeps C++-only.)

The design README has two `### Operator overloading` headings: :3372 (Carbon's
own operators, anchor `operator-overloading`) and :3657 (the interoperability
subsection that describes the two-way mapping, anchor
`operator-overloading-1`, as check-links computes duplicate anchors). Both
links target the second.

Counts after: H2 13 → 16 (the threads section, "Using C++ templates", "Using
Carbon from C++"), H3 16 → 17 ("C++ ranges in `for` loops"), dash items 37 →
41 (TOC entries for the four new headings; TODO entries renamed, not added),
ordered 3; the 18 `TODO` lines of §0.1 row 6 drop to 1 (the prose at :286,
category C) (amended 2026-10-13, review fold: B-M-5). Samples:
P07-P14 (programs design_docs_cpp_inline, _constructors, _struct_literals,
_members, _globals, _integers, _pointers, _operators; P09 fork-only), P17
(design_docs_cpp_templates), P18 (design_docs_carbon_from_cpp), P19
(design_docs_cpp_ranges), R23-R30, R32-R34;
probes PR-G, PR-G2, PR-H, PR-O, PR-Q, PR-S, PR-T.

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
    handlers; C `_Atomic` interop. F-008 leaves the exception behavior of
    threading APIs to the exception-interop design, which fork decision F-006
    fixes: a C++ exception, including one thrown by a threading API, never
    unwinds a Carbon frame
    ([Interoperating with C++ exceptions](../error_handling.md#interoperating-with-c-exceptions),
    with the `--cpp-exceptions` option of fork work item W-016).

Held PR 53 (fork decision F-013, D-SAFE-16) names `Core.Thread` and
`Core.Atomic(T)`, a Carbon signature over `Cpp.std.atomic(T)`, for the fifth
stage of its safety design (fork work item W-149). Whether to reserve
`Core.MemoryOrder` is an open question. Nothing in 0.1 declares any of the
three.

## In the 0.1 toolchain

This program exercises points 3 to 6 of the contract:

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
conformance programs in `fork/conformance/programs/interop/`,
`cpp_threading_atomics.carbon`, `cpp_thread_carbon_fn_diff.carbon` (a
`std::thread` constructed on a Carbon function),
`cpp_atomic_carbon_class_diff.carbon` (a `std::atomic` of an exported Carbon
class with only scalar fields), `cpp_atomic_global_counter_diff.carbon` (a
Carbon global of type `Cpp.std.atomic(i64)` bumped from threads that C++
started), `cpp_thread_mutex_raii.carbon`, and `cpp_thread_condvar_diff.carbon`,
exercise the contract; all six pass.

## Alternatives considered

F-008 compared four options (the design paper's "Options"): Option A,
"Document-and-conform - adopt the C++ memory model, fix nothing", which
documents the contract and leaves three toolchain defects unfixed; Option B,
"Option A + targeted toolchain fixes for the three verified defects", the
choice (`std::thread` on a Carbon function, a Carbon global of a C++ template
specialization type, and `std::atomic` of a Carbon class, all fixed in the
fork's toolchain, fork work items W-021 to W-023); Option C, "Option B + a
`Core.Sync` veneer library", which adds a `Core.Sync` library veneer over the
C++ types; and Option D, "Carbon-native atomics
lowered directly to LLVM". The veneer and native atomics were rejected for 0.1
as new design ahead of the 0.2 concurrency work.

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
dash 3 plus the TOC's. Sample: P16 (design_docs_cpp_threads.carbon, under "C++
interop: threading, atomics, memory model, synchronization"). (Amended
2026-10-13, review fold: A-10: point 7's exception sentence is attributed to
F-006 and W-016, since F-008 deferred it (threading-atomics.md:221-224), and
the name-reservation question, sub-fork 4 of the stranded draft, is stated
open after the list; the page's state-L texts for PR 53 are in §2.13, review
fold A-12 / B-M-6.) (The Alternatives paragraph above is the page's text,
with the option names the writer corrected at commit 2 from
threading-atomics.md:228, :279, :351 and :401; amended 2026-10-14,
document-review fold: DR1-14 / DR2-5: Option C's description reads "which
adds a `Core.Sync` library veneer over the C++ types" instead of repeating
the name, which keeps §2.13's anchor phrase; DR2-4: "all fixed in the F8
slices" names the fork's toolchain and W-021 to W-023, and the six program
paths are given from the repository root; DR2-5: a lead-in sentence precedes
the sample. Amended 2026-10-14, document-review fold: DR1-3: the
name-reservation paragraph says that held PR 53 names `Core.Thread` and
`Core.Atomic(T)` for its stage 5
(claude/carbon-fork-0-1-safe:docs/design/safety/mutation_safety.md:84-86 and
:399-402), and only `Core.MemoryOrder` is left open; D-DD-7 sub-fork (4) is
amended to match. Counts unchanged: H2 6 with the TOC heading, ordered 7.)

### §2.9 docs/design/README.md

**Item 1, `### Enums` (:3815-3817).** The body `> **TODO**` becomes:

````markdown
> **Fork status (2026-10-DD).** No accepted proposal covers C++ enumerations;
> this section documents the 0.1 toolchain's behavior, pinned by
> `toolchain/check/testdata/interop/cpp/enum/`.

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

This prints `5`, `1`, and `3`.
````

(Amended 2026-10-14, document-review fold: DR2-3: the dated statement moves
from the sentence after the sample, "(fork, 2026-10-DD)", into a status note
at the start of the section.)

**Item 2, `### Metaprogramming` (:3909-3916).** The note at :3911-3912 becomes
the block below; the paragraph at :3914-3916 and the References line stay.

````markdown
> **Fork note (2026-10-DD).** No accepted proposal designs metaprogramming
> yet. Compile-time evaluation is implemented in 0.1, with the `eval fn` and
> `musteval fn` forms; [Metaprogramming](metaprogramming.md) gives its status.
````

(Amended 2026-10-14, document-review fold: DR1-13: the note keeps what the
replaced marker said, that no design exists; DR2-3: the label.)

**Item 3, the template-constraints note (:2890).** State T:

````markdown
> **Fork note (2026-10-DD).** Template constraints are accepted: proposal 818
> introduced `template constraint` declarations, whose member requirements
> proposal 2200 specifies
> ([named constraints](generics/details.md#named-constraints)); fork decision
> [F-010](/fork/decision-log.md) adds `require` validity blocks and boolean
> predicates; [Templates](templates.md#status) gives their status.
````

(Amended 2026-10-14, document-review fold: DR1-2: the declarations and their
member requirements are attributed to proposals 818 and 2200, and F-010 to
its two extensions; DR2-3: the label.)

State L replaces the last clause, from "[Templates]", with
`[Template constraints](generics/template_constraints.md) specifies them.`

**Item 4, the three `> **TODO:**` bodies at :3988, :3992 and :3996.** The
first, Abstract machine and execution model, becomes the content below (it has
no milestone deferral, and the designs it cites fix the 0.1 model). The other
two, Co-routines and Concurrency, keep their upstream `> **TODO:**` line, as
comparison_operators.md's "Custom result types" keeps its marker (D-DD-1),
and its dated note below (the second block for Co-routines, the third for
Concurrency) follows the marker after a blank line, citing the milestone's
deferral (amended 2026-10-13, review fold: A-8 / B-M-4; RR-N-3:
rev 2 replaced these two markers with the notes). Each of the two sections
then holds its marker and a statement of the 0.1 status, so rule (c) does
not hit it, as for comparison_operators.md (§2.10):

````markdown
> **Fork status (2026-10-DD).** In 0.1 there is no separate abstract-machine
> specification.

The execution model is the one these designs fix together:
[Values, variables, and pointers](values.md) gives the expression categories,
when objects are created and destroyed, the storage they occupy, and which
uses of a value are erroneous; a function body's statements run in order
([Blocks and statements](blocks_and_statements.md)); Carbon code runs under the
C++ memory model, with C++'s threads, atomics, and synchronization
([Threads, atomics, and the memory model](interoperability/threads_and_atomics.md),
fork decision F-008); and an unrecoverable failure terminates the program
without unwinding ([Error handling](error_handling.md#unrecoverable-errors)).
````

````markdown
> **Fork note (2026-10-DD).** Coroutines, async, and generators are deferred
> until at least 0.2
> ([milestones](/docs/project/milestones.md#features-explicitly-deferred-until-at-least-02),
> [why](/docs/project/milestones.md#why-are-coroutines-and-async-in-this-milestone));
> there is no design and no toolchain support.
````

````markdown
> **Fork note (2026-10-DD).** Carbon-native threading is deferred until at
> least 0.2
> ([milestones](/docs/project/milestones.md#features-explicitly-deferred-until-at-least-02)).
> In 0.1, concurrency is C++'s; see
> [Threads, atomics, and the memory model](interoperability/threads_and_atomics.md).
````

(The three labels are amended 2026-10-14, document-review fold: DR2-3; the
abstract-machine text's dated parenthetical becomes a status note before it.)

**Item 5, five cohesion notes**, each a new blockquote directly after an
existing provisional note, which stays (amended 2026-10-13, review fold: A-3 /
B-M-8 / B-m-5: the tuples note is added, the Patterns anchor corrected, and the
Standard types note rewritten). After :812-814 (Tuples):

````markdown
> **Fork note (2026-10-DD).** Proposal 3646 has since accepted the tuple
> design; see [Tuples](tuples.md).
````

After :1038-1039 (Patterns):

````markdown
> **Fork note (2026-10-DD).** Proposal 2188 has since accepted the pattern
> design; see [Pattern matching](pattern_matching.md).
````

After :3586-3587 (Importing and `#include`):

````markdown
> **Fork note (2026-10-DD).** Proposal 6358 has since accepted the import
> design; see
> [Importing C++ APIs into Carbon](interoperability/README.md#importing-c-apis-into-carbon).
````

After :3659-3660 (the interop Operator overloading section):

````markdown
> **Fork note (2026-10-DD).** Proposal 6254 fixes how a call to a C++ operator
> is resolved; the 0.1 status of both directions is in
> [The operator interoperability model](interoperability/README.md#the-operator-interoperability-model).
````

After :3733-3734 (Standard types; the note covers the table and the `T&`
sentence at :3757-3758):

````markdown
> **Fork note (2026-10-DD).** Proposal 5448 has since accepted the
> primitive-type mapping (see [Integers](interoperability/README.md#integers))
> and proposal 6357 the pointer mapping. C++ references are not translated to
> `T*` in 0.1; see
> [Advanced type mapping](interoperability/README.md#advanced-type-mapping-pointers-references-and-const).
````

(The five labels are amended 2026-10-14, document-review fold: DR2-3, each
note's first word capitalized after the new label.)

**Item 6, the disclosure "This document is provisional" (:143-149)** (added
2026-10-13, review fold: A-5 / B-2). The upstream paragraph stays (D-DD-1); a
dated note follows :149. State T:

````markdown
> **Fork note (2026-10-DD).** In this fork, what is provisional is marked in
> place. Each former placeholder page or section now carries content that
> documents the 0.1 toolchain's behavior, or a dated status note: the pages
> that described themselves as placeholders ([Templates](templates.md),
> [Metaprogramming](metaprogramming.md), [Aliases](aliases.md),
> [Blocks and statements](blocks_and_statements.md), and the `match` section
> of [Pattern matching](pattern_matching.md#pattern-match-control-flow)), the
> interoperability README's former `TODO` sections, this document's
> [Enums](#enums) and [Execution abstractions](#execution-abstractions)
> sections, and the rules for
> [assigning tuples, structs, and data classes](assignment.md#tuples-structs-choice-types-and-data-classes).
> Two sections stay empty until held work lands:
> [Lifetime and move semantics](#lifetime-and-move-semantics) (held PR 53) and
> the [Strings](expressions/arithmetic.md#strings) section of arithmetic
> (held PR 55). The provisional notes that remain qualify the text beside
> them. `fork/designdocs/check_samples.py` reports any placeholder
> self-description, `TODO` heading, `TODO`-only section, or empty section that
> returns. On the design pages, "the 0.1 toolchain" is this fork's toolchain, a
> "fork decision F-nnn" is an entry of the
> [fork's decision log](/fork/decision-log.md), a "fork work item W-nnn" is an
> item of the [fork's work-item ledger](/fork/inventory/work-items.json), and a
> "held PR" is a fork pull request that has not merged yet.
````

(The note is amended 2026-10-13, review fold: RR-N-2: rev 2 said that every
former placeholder page or section carries a dated status note, which is
false for the interop README's sections, Enums, and the abstract machine,
which receive measured content, and it did not name the pages. Amended
2026-10-14, document-review fold: DR1-5: at state T the note names the two
sections that stay empty, the two ALLOWLIST entries, so it no longer implies
that no placeholder remains; DR2-4: "measured 0.1 content" becomes content
that documents the 0.1 toolchain's behavior, and a last sentence defines the
fork vocabulary the design pages use; DR2-2 / DR2-8: the checker's list
gains the empty section of W2 clause (d); DR2-3: the label.) State L (PR 53
and PR 55 merged, the W2 `ALLOWLIST` empty) replaces the sentence "Two
sections stay empty ... (held PR 55)." with "No section under docs/design/ is
an empty placeholder." (amended 2026-10-13, review fold: RR-N-2: rev 2's
sentence also covered every page the README links, among them docs/project/
and proposals/, which the W2 rule does not read; amended 2026-10-14,
document-review fold: DR1-5: the state-L sentence replaces the state-T one
instead of being added before the last sentence), and drops the clause that
defines "held PR" once no design page cites a held PR (§2.13; amended
2026-10-14, document-review fold: DR2-4). The note's first sentence is the
`QUALIFIED` entry's quote (§2.12 item 5), and it spans a blockquote line
break, which the matcher handles (§2.12 item 3).

Counts after: no heading or list change in README.md (the notes are
blockquotes; the Enums sample is a fenced block). Sample: P15
(design_docs_cpp_enums.carbon, under "Type system: C++ interop — importing
C++ types / exporting Carbon types").

### §2.10 code_and_name_organization/README.md and expressions/comparison_operators.md

After code_and_name_organization/README.md line 772 (the end of the
`#### Aliasing` example):

````markdown
> **Fork note (2026-10-DD).** The 0.1 toolchain does not accept a declaration
> through an alias, such as `TI.RawData` above; see
> [Aliases in the 0.1 toolchain](/docs/design/aliases.md#aliases-in-the-01-toolchain).
````

In expressions/comparison_operators.md, the upstream `**TODO:**` paragraph at
:476-477 stays unchanged, and this note follows it (amended 2026-10-13, review
fold: A-8 / B-M-4: rev 1 renamed the marker to "Future work", which only got
the section past the W2 rule):

````markdown
> **Fork note (2026-10-DD).** No design exists yet for comparison results
> other than `bool`. In 0.1, the comparison interfaces' functions return `bool`
> (`core/prelude/operators/comparison.carbon`), as the rules above specify, and
> a C++ comparison operator whose result is not `bool` is not usable where
> Carbon needs a `bool` (fork work item W-045).
````

The section then holds the upstream marker and a statement of the 0.1
behavior, so rule (c) does not hit it; row 91's text names it among the
extensions that are not designed (§5).

(Both labels are amended 2026-10-14, document-review fold: DR2-3; the
comparison note sits beside a kept marker and replaces nothing, so it is a
"Fork note".)

Counts after: unchanged in both files.

### §2.11 Conformance programs (commit 1 and commit 2)

(Rewritten 2026-10-13, review fold: A-2 / B-1: the stub stays SKIP, and the
programs are documentation-sync programs under feature bullets.)

**The stub stays.**
fork/conformance/programs/project/design_docs_placeholders.carbon keeps its
bullet, its body and its SKIP directive; commit 1 replaces the SKIP reason (its
line 6) with this text (R10: exact evidence, current line numbers):

```text
// SKIP: documentation/goal bullet, arbitrated by document review of docs/design/ (gap row 91), not by a runnable program, as row 88 is (and row 89 on held PR 53). DD-1 (fork/designdocs/plan.md, W-065) replaced the placeholder self-descriptions of templates.md, metaprogramming.md, aliases.md, blocks_and_statements.md and pattern_matching.md's `match` section with dated status notes and measured sections, wrote the interoperability README's eight former TODO sections and three new ones, added docs/design/interoperability/threads_and_atomics.md, and qualified docs/design/README.md's "provisional or placeholder" disclosure (:143-149) with a dated note. The grep arbiter is `python3 fork/designdocs/check_samples.py`: its W2 rule reports placeholder boilerplate (including "provisional or placeholder"), TODO headings, TODO-only sections and empty sections under docs/design/ that its allowlist and qualified list do not name. The documented samples run as documentation-sync programs under their feature bullets (fork/conformance/programs/project/design_docs_*.carbon). No runnable program can distinguish a cohesive design doc from a placeholder one, so this program stays SKIP; the bullet's status is gap row 91's, set by the two document reviews.
```

(The SKIP text is amended 2026-10-14, document-review fold: DR1-15: row 89
is arbitrated by document review only on held PR 53, not on trunk; DR2-10:
the qualified README disclosure passes through `QUALIFIED`, not the
allowlist; DR2-2 / DR2-8: the W2 rule gains clause (d), empty sections. The
fold applies it to the stub's line 6 as a new commit, since commit 1 exists.
The text still describes, from commit 1 on, what commits 2 and 3 land, as
this section placed it; the PR lands as one unit, and commit 4/4's landed
notes record it.)

**The programs.** Add the nineteen programs below, each: the three-line
license comment, a blank line, then

```text
// CONFORMANCE-BULLET: <the feature bullet in the table below>
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   <one line per expected output line>
//
// Documentation-sync program (fork/designdocs/plan.md D-DD-5): the code
// after this comment block is the <Pnn> code block of docs/design/<page>,
// section "<heading>", byte for byte (fork/designdocs/check_samples.py,
// rulebook R27). Expected output derived by hand in fork/designdocs/plan.md
// section 4 (R16(d)). <Runs on this fork's toolchain and on the upstream
// nightly. | Fork-only: the upstream nightly rejects it (the plan's section
// 4).> A PASS shows that the documented sample runs as documented; the
// design-docs bullet itself is arbitrated by document review.
```

followed by a blank line and the sample body. Three programs whose bullet fits
loosely (P05, P11, P13) carry one more header paragraph, after a `//` line, that
starts "Why this bullet:" and names the page section a FAIL points to first
(amended 2026-10-14, document-review fold: DR2-9). The headers were generated
and the nineteen programs run through the real runner in a scratch mirror of
fork/conformance/programs (stub kept) for rev 2 (§4.1): `--self-test` parses 169
programs with every bullet valid (its one error is the README table the mirror
does not regenerate); on the fork toolchain all nineteen PASS and the stub
SKIPs; on the nightly sixteen PASS and the three fork-only programs fail to
compile, as labelled. Every bullet below is already PASS on trunk
(fork/conformance/out/scoreboard.json), so no rollup changes.

| Program | Sample | Page, section | Bullet (CONFORMANCE-BULLET) | EXPECT-STDOUT | Nightly |
| --- | --- | --- | --- | --- | --- |
| design_docs_aliases.carbon | P01 | aliases.md, Aliases in the 0.1 toolchain | Code organization: Namespaces | 3 7 304 20 6 | runs |
| design_docs_statements.carbon | P02 | blocks_and_statements.md, Statements in the 0.1 toolchain | Control flow: loops incl. range-based and C/C++ loop equivalents | 13 0 12 11 | runs |
| design_docs_assignment.carbon | P03 | assignment.md, Tuples, structs, choice types, and data classes | Type system: User-defined types (classes) | 7 11 15 1 4 | fork-only |
| design_docs_templates.carbon | P04 | templates.md, Templates in the 0.1 toolchain | Generics: Integrated templates | 3 70 12 7 42 8 | runs |
| design_docs_compile_time.carbon | P05 | metaprogramming.md, Compile-time evaluation in the 0.1 toolchain | Generics: generic functions and types | 25 10 42 1 | runs |
| design_docs_match.carbon | P06 | pattern_matching.md, `match` in the 0.1 toolchain | Control flow: matching — good switch equivalents | 12 0 -1 1 45 | fork-only |
| design_docs_cpp_inline.carbon | P07 | interoperability/README.md, Importing C++ code (inline) | Code organization: Importing | 42 41 | runs |
| design_docs_cpp_constructors.carbon | P08 | interoperability/README.md, Constructors | Functions: C++ interop — importing/calling C++ functions and methods | 113 4 5 | runs |
| design_docs_cpp_struct_literals.carbon | P09 | interoperability/README.md, Struct literals | Type system: C++ interop — importing C++ types / exporting Carbon types | 42 | fork-only |
| design_docs_cpp_members.carbon | P10 | interoperability/README.md, Accessing C++ classes, structs, and members | Type system: C++ interop — importing C++ types / exporting Carbon types | 9 36 4 6 5 | runs |
| design_docs_cpp_globals.carbon | P11 | interoperability/README.md, Accessing global variables | Type system: C++ interop — importing C++ types / exporting Carbon types | 42 107 3 | runs |
| design_docs_cpp_integers.carbon | P12 | interoperability/README.md, Integers | Stdlib C++ interop: transparent fundamental-type mapping | 9 20 15 | runs |
| design_docs_cpp_pointers.carbon | P13 | interoperability/README.md, Advanced type mapping: pointers, references, and `const` | Stdlib: pointer types | 2 2 0 12 12 8 | runs |
| design_docs_cpp_operators.carbon | P14 | interoperability/README.md, The operator interoperability model | Type system: C++ interop — synthesizing Carbon overloads for imported C++ types | 42 -72 1 | runs |
| design_docs_cpp_enums.carbon | P15 | README.md, Enums | Type system: C++ interop — importing C++ types / exporting Carbon types | 5 1 3 | runs |
| design_docs_cpp_threads.carbon | P16 | interoperability/threads_and_atomics.md, In the 0.1 toolchain | C++ interop: threading, atomics, memory model, synchronization | 2 10 100 | runs |
| design_docs_cpp_templates.carbon | P17 | interoperability/README.md, Using C++ templates | Generics: C++ interop — importing C++ templates, instantiating on Carbon types | 7 5 4 | runs |
| design_docs_carbon_from_cpp.carbon | P18 | interoperability/README.md, Using Carbon from C++ | Functions: C++ interop — exporting Carbon functions/methods to C++ | 14 42 | runs |
| design_docs_cpp_ranges.carbon | P19 | interoperability/README.md, C++ ranges in `for` loops | Stdlib C++ interop: transparent iteration-abstraction mapping | 12 4 | runs |

Then `python3 fork/conformance/runner.py --update-readme-table` (nineteen rows
come; the stub's row stays with its new reason) and `--self-test` (R7: each
bullet string above is character-for-character the gap table's). No other
program changes.

### §2.12 Fixtures and the checker (commit 1, extended in commit 2)

**Fixtures** live in fork/designdocs/samples/<id>.carbon: the license comment, a
blank line, `// DESIGN-DOCS-SAMPLE: <page>, "<section>", <block|quote>`, then
`// EXPECT-ERROR: <message>` (the text after `error:` on the first error line)
or `// EXPECT-STDOUT:` lines in the runner's format, then for a quote fixture
`// QUOTE: <text>`, a blank line, and the body. The thirty-nine fixtures and
their pinned messages are the R and X rows of §4.1 (R01-R30, R32-R34,
X01-X06; amended 2026-10-13, review fold: A-1 / A-9 / A-14 / B-M-5 / B-m-4;
amended 2026-10-14, document-review fold: DR1-16 / DR1-8 / DR-FX-1, which add
X04, X06 and X05). R11 and X01 to X06 are the quote fixtures. X04's QUOTE is
the interop README's escape-sequence sentence, in "Importing C++ code
(inline)", and its EXPECT-STDOUT pins both working forms; X05's QUOTE is its
EXPECT-ERROR message, the `Circle` diagnostic of templates.md's "Templates in
the 0.1 toolchain"; X06's QUOTE is its EXPECT-ERROR message, the
`Opt.Some(n: i32)` diagnostic of pattern_matching.md's "`match` in the 0.1
toolchain". R11's QUOTE is its own
EXPECT-ERROR message, which the edit 3 note of §2.4 quotes in templates.md's
"Functions with template parameters". X01's QUOTE is "assigns element by
element from the literal and leaves `(2, 2)`" and X03's is "`let u: (i32,
i32) = (t.1, t.0); t = u;`", both in assignment.md's "Tuples, structs, choice
types, and data classes". X02's body is pattern_matching.md's first `match`
example (:730-745), unchanged, and its QUOTE is its EXPECT-ERROR message,
which the status note of §2.6 quotes in "Pattern match control flow". X01's
header says what it pins (amended 2026-10-13, review fold: B-m-7; RR-A-1):
"Pins the 0.1 toolchain's current result for a tuple and a struct swap
written as a literal, `(2, 2)`, which differs from the answer the leads gave
on issue 686 (a temporary from the right-hand side, then the destination
destroyed and the temporary moved in, which gives `(2, 1)`). The expected
lines restate the page's measured sentence, not a design rule: this fixture
keeps the page honest about current behavior and changes, with the page,
when the toolchain defect W-188 is fixed." (W-188 is filed under §1.4's rule
as a divergence from a leads decision.) The bodies of R11, X01 and X03:

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
  var s: {.a: i32, .b: i32} = {.a = 1, .b = 2};
  s = {.a = s.b, .b = s.a};
  Core.Print(s.a);
  Core.Print(s.b);
  return 0;
}
```

```carbon
import Core library "io";

fn Run() -> i32 {
  var t: (i32, i32) = (1, 2);
  let u: (i32, i32) = (t.1, t.0);
  t = u;
  Core.Print(t.0);
  Core.Print(t.1);
  return 0;
}
```

**fork/designdocs/check_samples.py** (license docstring as in
fork/evaluator/check_samples.py; ruff-clean; `main()` returns the status):

1.  `SAMPLES`: an ordered table of (page, section heading, kind, target) for
    every mapped block and quote, in page order, covering §2.1-§2.9 (the three
    new interop sections included) and the README disclosure note. A section
    is the text between a heading line whose text equals the table's heading
    and the next heading of any level; blocks are fenced `carbon` blocks at
    the first column.
2.  Program check: each `program` block equals the target program's text
    after its leading comment block (EV-1's `strip_leading_comments`), and
    the backticked values of the first "This prints ..." sentence of its
    section, up to the first `.`, `:` or `;` outside a code span and read
    after item 3's normalization, equal the program's EXPECT-STDOUT lines
    (amended 2026-10-14, document-review fold: DR2-7: a changed EXPECT line
    can no longer leave the page's stated output stale with every check
    green).
3.  Fixture check: each `block` fixture's body equals the page block; every
    fixture's EXPECT-ERROR message (or QUOTE) occurs in its section's prose
    after normalizing both sides: first each prose line loses its leading
    blockquote markers (the regular expression `^\s*>\s?`, applied
    repeatedly, so a nested quote loses every level), then all whitespace
    runs collapse to one space. A quote that spans a blockquote line break,
    as the README note's `QUALIFIED` quote does, then matches (amended
    2026-10-13, review fold: RR-N-1: rev 2 collapsed whitespace only, which
    left the `>` marker inside that quote).
4.  Count check: the number of `carbon` blocks in each mapped section equals
    the number the table maps there (no unmapped block in a DD-1 section).
5.  W2 rule over docs/design/ (fence-aware): (a) the boilerplate regex
    `skeletal\s+design|it\s+is\s+a\s+placeholder|should\s+not\s+be\s+treated\s+as\s+accepted|Please\s+feel\s+welcome\s+to\s+rewrite|provisional\s+or\s+placeholder`
    over each file's whole text; (b) a heading whose text starts with `TODO`;
    (c) a section whose paragraphs (split on blank or bare `>` lines) all start
    with a TODO marker (`^(>\s*)?[*_]*TODO`) or with `See` or `> References`, at
    least one being a TODO marker. The document-review fold hardens the rule
    (amended 2026-10-14, document-review fold: DR2-2 / DR2-8, D-DD-2's break
    condition): every clause matches without regard to case; clause (a) runs
    over the text after the leading blockquote markers of each line are
    stripped, keeping the line breaks, so a phrase wrapped across blockquote
    lines hits and is still attributed to its section; clause (c)'s marker is
    `^(>\s*)*([-*+]\s+|[0-9]+[.)]\s+)?(<!--\s*)?[*_]*(TODO|TBD)`, so a TODO or
    TBD paragraph in a list item or an HTML comment is a marker too; and a new
    clause (d) hits a section with no body and no subsection (the next heading,
    if any, is at the same or a higher level). Over docs/design/ at the fold
    commit, trunk 162c7e839 and f67ab650d, and the held heads (PR 53 adaae4e35,
    PR 55 21307851a, SC-1 4bc4802ae, OP-1 379f20f67, PR 54 cb3ef2e74, PR 51
    f96fe8a7a, PR 52 ea573f672), the hardened rule hits no section the commit-3
    rule missed: at the fold commit it finds the same three hits, and on trunk
    and the held heads clause (d) adds only the twin of each empty interop
    `TODO:` heading that clause (b) already hits. Hits are keyed by (file,
    section heading, clause). `QUALIFIED` holds (README.md, "This document is
    provisional", a) with the quote "In this fork, what is provisional is marked
    in place"; the entry passes only while that quote occurs in the same
    section, matched after item 3's normalization (blockquote markers stripped,
    then whitespace collapsed; amended 2026-10-13, review fold: RR-N-1), and it
    stays at state L. `ALLOWLIST` is set per commit and shrinks (amended
    2026-10-13, review fold: A-5 / B-2 / B-M-2): after commit 1 it holds the
    sixteen hits that commits 2 and 3 and the held PRs remove (interop README:
    eight `TODO:` headings and the :275 TODO-only body; README.md: Enums,
    Lifetime and move semantics, Abstract machine and execution model,
    Co-routines, Concurrency, and the disclosure, which commit 3 moves to
    `QUALIFIED`; arithmetic.md: Strings); after commit 2, six (README.md's
    Lifetime, Abstract machine, Co-routines, Concurrency and disclosure,
    arithmetic.md's Strings); after commit 3, two ((README.md, "Lifetime and
    move semantics", PR 53) and (expressions/arithmetic.md, "Strings", PR 55));
    in the integration commit, none. An allowlisted entry that no longer hits is
    itself an error (so the list cannot go stale), and so the checker exits 0 at
    every commit with the expected list and only then.
6.  `--toolchain PATH`: for each fixture, `PATH compile --output=<tmp>
    --output-last-input-only <fixture>`; an EXPECT-ERROR fixture must exit
    non-zero with its first `error:` line's message equal to the pin; an
    EXPECT-STDOUT fixture must compile, link (`PATH link`), run with exit 0,
    and print exactly the pinned lines. `XDG_CACHE_HOME` is honored from the
    environment.
7.  Output: one line per error, then a summary (`N program blocks, M fixtures,
    W2 hits`); exit 1 on any error.
8.  Matcher self-check (commit 1; added 2026-10-13, review fold: RR-N-1):
    `--self-check`, which every default run also performs first, runs item
    3's quote matcher over built-in texts and exits 1 on any wrong answer. A
    two-line blockquote whose lines are `> In this fork, what is provisional
    is marked in` and `> place. Each former placeholder` must contain the
    `QUALIFIED` quote; the same two lines with a nested `> >` prefix must
    contain it too; a one-line prose sentence must contain a quote taken from
    its middle, as R11's and X02's are; and a quote that is absent must not
    match. Commit 1's message records the self-check's output. The fold adds
    thirteen built-in W2 cases, each a small page with the exact hits it must
    give (amended 2026-10-14, document-review fold: DR2-2): a boilerplate
    phrase wrapped across plain lines, across blockquote lines, and in another
    case; a `Todo:` heading; sections holding only `> **TODO:**`, only
    `_TODO_` with a "See" paragraph, only a list-item TODO, only an HTML-comment
    TODO, or only "TBD."; an empty section followed by a heading of its level;
    and three that must not hit: an empty section followed by a subsection, a
    marker followed by a dated note, and content followed by a marker. The
    output reads `self-check: 4 quote cases, 13 W2 cases, 0 wrong`.

The W2 rule as specified found the 36 hits of §0.1c at 162c7e839 (prototype run
for this plan), 37 with clause (a)'s added phrase. Expected results, which each
commit message records beside the actual output: after commit 1, sixteen
allowlisted hits and no other; after commit 2, six; after commit 3, the two
held-PR hits plus the one `QUALIFIED` entry; after the integration commit, the
`QUALIFIED` entry only. Run over the docs/design/ trees of the held branch
heads (PR 53, PR 55, SC-1, PR 54, PR 51, OP-1), the rule finds no hit that
trunk lacks (fixer's run for rev 2; re-run for rev 4 at SC-1 a9c887101, OP-1
379f20f67 and trunk f67ab650d, with the same result; amended 2026-10-14,
review fold: RR2-2), so the state-L list depends only on PR 53 and PR 55
landing.

### §2.13 State-L texts (integration commit)

(Retitled and extended 2026-10-13, review fold: A-1 / A-12 / B-M-1 / B-M-6 /
B-m-1 / B-M-8: rev 1 listed only the EV-1 sentences.) The integration commit
applies, after merging trunk with every held PR on it:

-   **Held-PR citations.** "(fork work item W-155, on held PR 54)" in
    blocks_and_statements.md and pattern_matching.md, and "(fork work item
    W-167, on held PR 55)" in assignment.md, lose ", on held PR nn".
-   **assignment.md** (PR 53): the swap paragraph gains the state-L sentence
    of §2.3 (F-013 D-SAFE-17 for the `let` form, which agrees with issue 686's
    answer), and W-188's notes gain D-SAFE-17's scope (§8.5) (amended
    2026-10-13, review fold: RR-A-1).
-   **threads_and_atomics.md** (PR 53): contract item 2's last sentence becomes
    the block below; the Alternatives sentence's "a `Core.Sync` library veneer
    over the C++ types" gains ", a set of wrapper types unrelated to the
    `Core.Sync` facet that fork decision F-013 later defined" followed by the
    link `([Data races and the
    facets](../safety/mutation_safety.md#data-races-and-the-facets))`; and the
    paragraph after the contract, "Held PR 53 (fork decision F-013, D-SAFE-16)
    names", becomes "Fork decision F-013 (D-SAFE-16," followed by the link
    `[Data races and the
    facets](../safety/mutation_safety.md#data-races-and-the-facets)` and ")
    names" (amended 2026-10-14, document-review fold: DR1-3).
-   **safety/mutation_safety.md** (PR 53): M7's parenthesized link to the
    design-sprint paper gains `[Threads, atomics, and the memory
    model](../interoperability/threads_and_atomics.md)` before it, so the 0.1
    contract M7 refers to is linked from the safety design.
-   **expressions/literals.md** (PR 55): after :251 ("No design for string
    types has been through the proposal process yet."), the blockquote note
    "**Fork note (2026-10-DD).** Fork decision F-014 designs the string types;
    see" and the link `[Strings](../strings.md)` (the label amended
    2026-10-14, document-review fold: DR2-3).
-   **interoperability/README.md**: the pointer section's "`Core.Optional(T*)`
    in Carbon" gains the link `([Optional](../optional.md), fork decision
    F-015)` (OP-1); the C++ templates section's "Carbon constraints are not
    exported as C++ concepts (W-029)" gains "; the design of both directions is
    in" and the link `[Template
    constraints](../generics/template_constraints.md#mapping-to-and-from-c20-concepts)`
    (SC-1).
-   **README.md**: the disclosure note's sentence on the two empty sections
    is replaced by its state-L sentence, and its "held PR" definition is
    dropped (item 6 of §2.9; amended 2026-10-14, document-review fold: DR1-5
    / DR2-4), the :2890 note gains its state-L clause (item 3 of §2.9);
    templates.md its state-L status sentences and the `Circle` paragraph's
    last sentence (§2.4) (amended 2026-10-13, review fold: RR-N-4: rev 2's
    wrap put "6)" at a continuation line's start; amended 2026-10-14,
    document-review fold: DR1-2 / DR1-7).

The threads page's contract item 2, from "The 0.1 toolchain does not detect
data races", at state L:

````markdown
    The 0.1 toolchain does not detect data races. Fork decision F-013
    (D-SAFE-16) stages the prevention of data races between Carbon-spawned
    threads in Strict Carbon
    ([M7: Data races](../safety/mutation_safety.md#m7-data-races)); until that
    stage, and for Permissive code and C++ threads after it, the C++ rule
    above applies.
````

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

### §2.14 Fork records (discharge commit and integration commit; §8.5 spells them)

Discharge commit: fork/inventory/work-items.json, fork/gap-analysis.md (row 70
DONE, row 91 PARTIAL pending state L, header), fork/decision-log.md (one
entry), fork/ORCHESTRATION.md (stamp, branch row, id reservation), and this
plan's "Landed notes". Integration commit: row 91 DONE when §5's condition
holds (its cell replaces PR 51's rewrite of the same cell), W-188's notes, the
W-014, W-155 and W-167 evidence amendments, and the header recomputed (amended
2026-10-13, review fold: B-M-3 / B-m-1 / B-m-2 / B-m-8).

## §3 Commits (one PR, R29(b): "DD-1: design docs without placeholders")

(The order and the PR body are amended 2026-10-13, review fold: B-M-2 /
B-M-3 / B-M-7 / B-m-8.)

-   **Plan:** "DD-1 plan (rev 1): ..." (bed95d667), then "DD-1 plan (rev 2):
    reviews A and B folded, ..." (a1d96520a), then "DD-1 plan (rev 3):
    focused re-review folded, NOT signed off" (15c719ddc; amended 2026-10-13,
    review fold: RR-A-1), then "DD-1 plan (rev 4): focused re-review 1
    folded, sign-off" (this revision). The focused re-review of rev 3
    returned a verdict other than REJECT and the Status line records the
    sign-off, so implementation starts at rev 4 (amended 2026-10-14, at
    sign-off).
-   **DD-1 (1/4): language pages** — §2.1-§2.6 and §2.10, programs P01-P06,
    their fixtures, the checker with the language-page table and the commit-1
    `ALLOWLIST` (sixteen entries), the stub's SKIP reason refreshed (§2.11), the
    conformance README table regenerated.
-   **DD-1 (2/4): interoperability** — §2.7 (the three new sections included),
    §2.8, item 1 of §2.9, programs P07-P19, their fixtures, the checker table
    extended, the `ALLOWLIST` down to six.
-   **DD-1 (3/4): design README notes** — items 2-6 of §2.9; the `ALLOWLIST`
    down to the two held-PR hits and the disclosure in `QUALIFIED`.
-   **Document reviews** (D-DD-11), then **the document-review fold**, its own
    commit with the dispositions in its message, before the discharge. Its
    title is "DD-1: document-review fold"; the
    [document-review fold record](#document-review-fold-2026-10-14) lists each
    disposition (amended 2026-10-14, document-review fold).
-   **DD-1 (4/4): discharge** — §2.14 and §8.5-§8.9: row 70 DONE (expected),
    row 91 PARTIAL pending state L, the ledger, the decision log, the
    ORCHESTRATION stamp.
-   **Implementation review**, then **its fold**, its own commit.
-   **Integration (state L)** — merge trunk after OP-1; §0.2's conflicts; the
    state-L texts of §2.3, §2.4, §2.9 items 3 and 6, and §2.13; the empty
    `ALLOWLIST`; W-188's notes and the W-014, W-155 and W-167 amendments; row 91
    DONE when §5's condition holds; the re-measure of §8.1.

Every commit: author `jmann345 <jerrymannstan@gmail.com>`, committer `Claude
<noreply@anthropic.com>`, explicit paths only (R20), the session trailers; the
message records the prek fixpoint, the R31 counts, `--self-test`, the checker
(with `--toolchain`) with its expected and actual W2 output, the local
conformance totals, and §8.10's "Not run" list verbatim.

**PR body** (the one PR, R29(b)): title "DD-1: design docs without
placeholders"; sections, in order: Summary (the bullet verbatim, what changed
page by page); Programs and fixtures (the nineteen documentation-sync
programs with their bullets, the thirty-nine fixtures, the checker); Residues
and ledger amendments (§8.5's list, with the withdrawn rev-1 ids named);
Verification (prek fixpoint and R31 counts per file, the checker with and
without `--toolchain`, `--self-test`, the local conformance totals on the fork
toolchain, the nineteen programs on the nightly with the three fork-only
labels); Not run (§8.10 verbatim); State L and merge position (the integration
items above, after OP-1); the attribution line the session specifies.

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
| P04 (`P04_templates.carbon`) | templates.md, Templates in the 0.1 toolchain (rev 2 adds `Holder`) | RUNS, exit 0, prints `3 70 12 7 42 8` | RUNS, exit 0, prints `3 70 12 7 42 8` |
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
| P17 (`P17_cpp_templates.carbon`) | interop README, Using C++ templates | RUNS, exit 0, prints `7 5 4` | RUNS, exit 0, prints `7 5 4` |
| P18 (`P18_carbon_from_cpp.carbon`) | interop README, Using Carbon from C++ | RUNS, exit 0, prints `14 42` | RUNS, exit 0, prints `14 42` |
| P19 (`P19_cpp_ranges.carbon`) | interop README, C++ ranges in `for` loops | RUNS, exit 0, prints `12 4` | RUNS, exit 0, prints `12 4` |
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
| R20 (`R20_match_exhaustive_return.carbon`) | pattern_matching.md (W-155) | REJECTS: `` missing `return` at end of function with declared return type `` | REJECTS: `` semantics TODO: `HandleMatchIntroducer` `` |
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
| R32 (`R32_cpp_inline_no_import.carbon`) | interop README, Importing C++ code (inline) | REJECTS: `` name `Cpp` not found `` | REJECTS: `` name `Cpp` not found `` |
| R33 (`R33_cpp_export_nontype_generic.carbon`) | interop README, Using Carbon from C++ (W-044) | REJECTS: `` semantics TODO: `binding maps to a non-type template parameter` `` | REJECTS: `` semantics TODO: `binding maps to a non-type template parameter` `` |
| R34 (`R34_cpp_pointer_range.carbon`) | interop README, C++ ranges in `for` loops (W-053) | REJECTS: `` cannot access member of interface `Core.Iterate` in type `Cpp.Digits` that does not implement that interface `` | REJECTS: the same |
| X01 (`X01_swap_literal.carbon`) | assignment.md (quote fixture; rev 2 adds the struct swap) | RUNS, exit 0, prints `2 2 2 2` | RUNS, exit 0, prints `2 2 2 2` |
| X02 (`X02_match_first_example.carbon`) | pattern_matching.md, Pattern match control flow (quote fixture; the page's first `match` example) | REJECTS: `` semantics TODO: `match on unsupported scrutinee type` `` | REJECTS: `` semantics TODO: `HandleMatchIntroducer` `` |
| X03 (`X03_swap_let.carbon`) | assignment.md (quote fixture) | RUNS, exit 0, prints `2 1` | RUNS, exit 0, prints `2 1` |
| X04 (`X04_cpp_inline_escapes.carbon`) | interop README, Importing C++ code (inline) (quote fixture; DR1-16) | RUNS, exit 0, prints `3 1 1` | RUNS, exit 0, prints `3 1 1` |
| X05 (`X05_template_structural_circle.carbon`) | templates.md, Templates in the 0.1 toolchain (quote fixture; DR-FX-1) | REJECTS: `` cannot convert type `Circle` into type implementing `HasArea` `` | REJECTS: the same |
| X06 (`X06_match_qualified_alternative.carbon`) | pattern_matching.md, `match` in the 0.1 toolchain (quote fixture; DR1-8) | REJECTS: `` name `n` not found `` | REJECTS: `` semantics TODO: `choice alternatives with parameters are not yet supported` `` |

(Rows X04 to X06 are added 2026-10-14, document-review fold: DR1-16 / DR1-8 /
DR-FX-1; measured by the fold's fixer on the fork toolchain and the nightly,
and on the OP-1 (5d9edb3e0), SC-1 (fb12f63cb), UA-2 (05a5c30f7) and ST-1
(84ff63560) builds, where each gives the fork's result.)

(Rows P17-P19, R32-R34, X02 and X03, the new P04 and X01 bodies, and the R20
item are amended 2026-10-13, review fold: A-1 / A-9 / A-14 / B-M-1 / B-M-5 /
B-m-4; measured by the fixer in its own scratch on the fork toolchain and the
nightly, and on the OP-1 (5d9edb3e0), SC-1 (ff490bd48), UA-2 (05a5c30f7) and
ST-1 (84ff63560) toolchains, where every row gives the fork's result.)

**Hand derivation of the EXPECT values (R16(d)).** Each line of a program's
expected output, derived from the sample's source alone:

| Sample | Derivation |
| --- | --- |
| P01 | `p.horizontal` is `x`, `3`; `Total` is `Sum`, 3 + 4 = `7`; `PrintToScreen` prints 3 × 100 + 4 = `304`; `Geo.Scale() + Scale()` = 10 + 10 = `20`; `b.item + calls` = 5 + 1 = `6` |
| P02 | the loop adds `i` for `i` in 1, 3, 4, 5 (2 is skipped, 6 breaks) = `13`; `Classify(-7)` is minus one, then `++` gives `0`; 1 + 2 + 3 plus 0 + 1 + 2 + 3 = `12`; `Add` gives 2 + 3 and `MakeSix` gives 6, so `11` |
| P03 | `t` = (3, 4) gives `7`; `s` = `other` gives 5 + 6 = `11`; `p` = (7, 8) gives `15`; `Green` gives `1`; `old` = (3, 4) swapped puts 4 in `t.0`, so `4` |
| P04 | 1 + 2 = `3`; 30 + 40 = `70`; 6 + 6 = `12`; `Convert(7, i64)` is `7`; 3 × 14 = `42`; `h.Get()` returns `item`, `8` |
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
| P17 | `Larger(3, 7)` is `7`; `Box(i32).Make(5).Get()` is `5`; the boxed `Point`'s `y` is `4` |
| P18 | `Make(4)` holds 4, `Add(3)` makes 7, `Twice(7)` is `14`; `Make(21)` doubled by `Double` holds 42, so `Value()` is `42` |
| P19 | 2 + 4 + 6 = `12`; after `push_back(8)` the vector has four elements, so `4` |
| X01 | the toolchain's measured behavior, element by element from the literal: from (1, 2), `t.0` becomes `t.1`, 2, then `t.1` becomes the new `t.0`, 2: `2`, `2`; the struct the same: `2`, `2`. Not a design derivation: issue 686's answer gives `2`, `1` for both, and W-188 is the defect (X01's header, §2.12; amended 2026-10-13, review fold: RR-A-1) |
| X03 | `u` is bound to (2, 1) before `t` changes, so `t` becomes (2, 1): `2`, `1` |
| X04 | Carbon turns `\\n` in a block string literal into `\n` before C++ sees it, so `strlen("a\nb")` is 3 characters: `3`; `"\n"[0]` is the newline, 10: `1`; the raw block string passes `"\n"` unchanged, the same: `1` (added 2026-10-14, document-review fold: DR1-16) |

**Runner runs (2026-10-13, private `--out`):** rev 1 ran the sixteen
generated programs in a scratch mirror of fork/conformance/programs (stub
removed): `--filter project/design_docs` on the fork toolchain 16 PASS; on the
nightly 13 PASS, 3 COMPILE-FAIL (design_docs_assignment,
design_docs_cpp_struct_literals, design_docs_match, the labelled fork-only
three); on the SC-1, UA-2 and ST-1 toolchains 16 PASS each. Rev 2 regenerated
the nineteen programs with their feature bullets in a fresh mirror with the
stub kept: on the fork toolchain 19 PASS and the stub SKIP, every one of the 16
bullets touched PASS; on the nightly 16 PASS and the same 3 COMPILE-FAIL;
`--self-test` parses 169 programs and validates every bullet (amended
2026-10-13, review fold: A-2 / B-1 / B-M-5). Trunk floor on the fork
toolchain: 128 / 0 / 22 over 150, 48/56 bullets PASS.

### §4.2 Prose claims backed by testdata or programs (no page block)

| Claim (page) | Evidence |
| --- | --- |
| alias exports, `private alias`, alias spelling in diagnostics (aliases.md) | toolchain/check/testdata/alias/import_access.carbon (``name `A` not found`` outside the library), export_name.carbon (`export D;` of an alias; `C` not visible), import.carbon, preserve_in_type_printing.carbon (``type `A*` does not support qualified expressions``) |
| constant-value alias accepted (aliases.md) | alias/builtins.carbon split `bool_value.carbon` (`alias a = false;` checks clean); P01's `alias Limit = 4;` |
| declaring through an alias rejected (aliases.md, code organization note) | namespace/fail_decl_in_alias.carbon:18-26; R03 |
| `musteval` calling `musteval` with a parameter is a TODO (metaprogramming.md) | function/call/eval_musteval.carbon split `fail_todo_musteval_calls_musteval.carbon` |
| control-flow expressions outside functions (metaprogramming.md) | W-036 evidence; eval/branch.carbon split `fail_todo_if_expression_direct.carbon` |
| `^x` calls `operator~`; prefix `++`/`--`; the W-045 import gaps (interop README) | interop/cpp/operators/operators.carbon splits `import_unary_operators.carbon`, `import_binary_operators.carbon`, `fail_todo_import_assignment.carbon`, `fail_todo_rewrite_spaceship.carbon`, `fail_todo_rewrite_equal.carbon`; eq_with.carbon `fail_todo_returns_boolish.carbon`; deref.carbon `fail_todo_multi_deref.carbon` (``semantics TODO: `operator* overload sets not implemented yet` ``) |
| operators with no Carbon spelling (interop README) | operators.carbon `fail_todo_import_unsupported_unary_operators.carbon` (unary `+`, postfix `++`/`--`, `~` spelled `^`, `operator!`) and `fail_todo_import_unsupported_binary_operators.carbon` (`operator&&`, `operator||`, the comma operator), each a parse error, not an import; docs/design/README.md:3685-3687 keeps logical and comma operators C++-only (amended 2026-10-13, review fold: A-14) |
| single-base inheritance across the boundary; W-046's gaps (interop README, members) | fork/conformance/programs/interop/inherit_carbon_extends_cpp.carbon and inherit_cpp_extends_carbon.carbon (PASS in scoreboard.json); inherit_multiple_bases.carbon (SKIP, W-046) (added 2026-10-13, review fold: B-M-5) |
| a C++20 concept applied to types is a compile-time `bool` (interop README, C++ templates) | interop/cpp/template/concept.carbon split `use_concept.carbon` (`X(Cpp.IsLarge(Cpp.Small))`); W-029 for export (added 2026-10-13, review fold: B-M-5) |
| a symbolic generic parameter is not a C++ template argument (interop README, C++ templates) | W-043; probe PR-T; fork/conformance/programs/interop/cpp_template_symbolic_arg.carbon (SKIP) (added 2026-10-13, review fold: B-M-5) |
| `ref self` and `self` methods called from C++ (interop README, C++ use of Carbon) | interop/cpp/class/export/method.carbon splits `ref_method_lvalue.carbon`, `fail_ref_method_rvalue.carbon`, `fail_ref_method_const_lvalue.carbon`, `method_rvalue.carbon`, `method_const_lvalue.carbon` (added 2026-10-13, review fold: B-M-5) |
| a Carbon `template` function called from C++ stops the compiler (interop README, C++ use of Carbon) | W-191 (rev 2's W-190; RR-FX-1); probe PR-S (added 2026-10-13, review fold: B-M-5) |
| member and argument-dependent `begin`/`end` make a C++ range (interop README, ranges) | fork/conformance/programs/interop/cpp_range_member_begin_end_iterate.carbon and cpp_range_adl_begin_end_iterate.carbon (PASS); gap row 83 (added 2026-10-13, review fold: B-M-5) |
| the abstract-machine content (README.md) | values.md "Expression categories" (:71) and "Value expressions" (:440, use after mutation erroneous :455-468); blocks_and_statements.md; F-008's contract (threads page); error_handling.md "Unrecoverable errors" (:873-882) (added 2026-10-13, review fold: A-8) |
| reference-typed fields read through `*` (interop README) | interop/cpp/class/import/field.carbon `use_struct_fields.carbon` (`*s.r`); probe PR-O |
| `{}` initializes an empty aggregate, not a class with a constructor (interop README) | interop/cpp/class/import/non_aggregate_init.carbon; P09 |
| union designated initialization (interop README) | interop/cpp/class/import/union_init.carbon; P09 |
| the six threading programs pass (threads page) | local floor run 2026-10-13 (all six PASS); fork/gap-analysis.md:70 |
| single LLVM module for Carbon and C++ (threads page) | toolchain/lower/context.cpp:42-46 (`llvm_module_` is `cpp_code_generator_->GetModule()` when a C++ code generator exists) |
| C++ exceptions never unwind Carbon frames (threads page item 7) | fork decision F-006 and W-016, not F-008 (F-008 deferred it, threading-atomics.md:221-224): docs/design/README.md:3969-3972; error_handling.md "Interoperating with C++ exceptions" (:560) (amended 2026-10-13, review fold: A-10) |
| `match` needs at least one arm (pattern_matching.md) | probe PR-F (`expected cases`); W-068's recorded decision |
| C++ `"\n"` in a plain block string literal is broken by Carbon's escape processing; `"\\n"` and a raw block string work (interop README, inline) | X04 (both working forms, `3 1 1` on the fork and the nightly); probe PR-V (the unescaped form: first error `expected '}'`, after Clang's "missing terminating '"' character" warnings, on both) (added 2026-10-14, document-review fold: DR1-16) |
| a builtin `fn` is evaluated during compilation; a plain `fn` with a body is not (metaprogramming.md) | probe PR-W (RUNS, prints `2`, on both); R13 (added 2026-10-14, document-review fold: DR1-6) |
| an interface constraint is satisfied only by an `impl` (templates.md) | X05 (added 2026-10-14, document-review fold: DR-FX-1) |
| tuple patterns with bindings and `bool` constants are not exhaustive without an irrefutable arm (pattern_matching.md, W-189) | probe PR-X (fork: `` `match` on `(bool, i32)` has no `default` arm and no `case` arm that matches every value ``) (added 2026-10-14, document-review fold: DR1-8) |
| `match` is a statement; no `match` expression parses (pattern_matching.md) | p002188:1173-1191 (future work); probe PR-Y (`expected expression` on both) (added 2026-10-14, document-review fold: DR1-8) |
| an alternative pattern written with the choice type's name is not supported (pattern_matching.md) | match/fail_choice_alternative_pattern.carbon split `fail_todo_qualified_pattern.carbon`; probe PR-Z (`Opt.None`: the same `semantics TODO`); X06 (`Opt.Some(n: i32)`) (added 2026-10-14, document-review fold: DR1-8) |
| a `match` on a template-dependent value reports a `semantics TODO` (templates.md) | probe PR-D (`` semantics TODO: `match on unsupported scrutinee type` ``), re-run by the fold (added 2026-10-14, document-review fold: DR1-7) |

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

Fork: CRASH rc=134: Stack dump:. Nightly: CRASH rc=134: Stack dump:. The
CHECK line (re-measured for rev 2, review fold A-11): fork "CHECK failure at
toolchain/sem_ir/pattern.cpp:81: entity_name_id.has_value(): Unhandled pattern
inst kind {kind: ExprPattern, arg0: region59000001, type: type(inst5900001F)}";
nightly the same at pattern.cpp:77.

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

**Probes added for rev 2** (2026-10-13, by the fixer, in its own scratch;
review fold: A-1 / A-4 / A-13 / A-14 / B-M-5). PR-A on the nightly: both
input orders CRASH rc 134 with "FATAL failure at
toolchain/check/import_ref.cpp:4875: Missing case in TryResolveInstCanonical
for instruction kind SpliceInst". PR-E on the nightly: REJECTS
``unrecognized declaration introducer``.

`PR-R_bool_pair.carbon`:

```carbon
fn F(a: bool, b: bool) -> i32 {
  match ((a, b)) {
    case (true, true) => { return 3; }
    case (true, false) => { return 2; }
    case (false, true) => { return 1; }
    case (false, false) => { return 0; }
  }
  return -1;
}
```

Fork, OP-1 and SC-1 toolchains: REJECTS: `` `match` on `(bool, bool)` has no
`default` arm and no `case` arm that matches every value ``. Nightly: REJECTS:
`` semantics TODO: `HandleMatchIntroducer` ``.

`PR-S_template_export.carbon`:

```carbon
import Core library "io";
import Cpp;

fn Twice[template T: type](x: T) -> T { return x + x; }

inline Cpp '''c++
inline int UseTwice() { return Carbon::Twice(21); }
''';

fn Run() -> i32 {
  Core.Print(Cpp.UseTwice());
  return 0;
}
```

Fork and OP-1 toolchains: CRASH rc 134, "CHECK failure at
toolchain/sem_ir/generic.cpp:96: specific_ir.generics().GetSelfSpecific(
specific_ir.specifics().Get(specific_id).generic_id) == specific_id: Queried
generic_inst_in_def1 {kind: CallAction, ...} in specific5900000A for generic
{kind: FunctionDecl, ...} before it was resolved." The same file with `return
x;` as the body stops at the same CHECK with `CompoundMemberAccessAction`.
Nightly: RUNS, exit 0, prints `42` (both files). The nightly is a later
upstream than the fork's cut (c1e83b0b7), so whether the fork changed or
upstream fixed the path after the cut is not determined.

`PR-T_symbolic_arg.carbon`:

```carbon
import Cpp inline '''c++
template <typename T>
struct Box {
  T value;
};
''';

fn MakeBox[T: type](unused x: T) {
  var unused b: Cpp.Box(T);
}
```

Fork: REJECTS: ``cannot convert type `<splice of <cannot stringify
inst59000041: {kind: ConvertToValueAction, ...}>>` into type implementing
`Core.DefaultOrUnformed` ``. Nightly: the same shape with other instruction
ids. Not a page fixture, because the message names internal instruction ids.

`PR-U` (three files, each `import Core library "io";` and a `Run` that prints
both elements): `var t: (i32, i32) = (1, 2); let u: (i32, i32) = (t.1, t.0);
t = u;` prints `2 1`; `var s: {.a: i32, .b: i32} = {.a = 1, .b = 2}; s = {.a
= s.b, .b = s.a};` prints `2 2`; `var t: (i32, i32) = (1, 2); var old: (i32,
i32) = t; t = (old.1, old.0);` prints `2 1`; the same on the fork, the nightly
and the OP-1 toolchain. X01 and X03 pin the first two forms on the page.

`PR-G2_bare_import.carbon`: PR-G with `import Cpp;` added after the `Core`
import. Fork and nightly: RUNS, exit 0, prints `41`.

**Probes added by the document-review fold** (2026-10-14, by its fixer, in
its own scratch `.../scratchpad/dd1-impl/fixer/probes/`, with
`XDG_CACHE_HOME` there; each also run on the OP-1 (5d9edb3e0), SC-1
(fb12f63cb), UA-2 (05a5c30f7) and ST-1 (84ff63560) builds, which give the
fork's result).

`PR-V_escape_bad.carbon` (DR1-16):

```carbon
import Cpp inline '''c++
inline const char* Newline() { return "\n"; }
''';
```

Fork and nightly: REJECTS: `` expected '}' `` (in `<carbon Cpp imports>`),
after Clang's warnings "missing terminating '"' character" at the two halves
of the broken string literal.

`PR-W_builtin_plain_fn.carbon` (DR1-6):

```carbon
import Core library "io";

fn Add(a: i32, b: i32) -> i32 = "int.sadd";

var a: array(i32, Add(1, 2)) = (0, 1, 2);

fn Run() -> i32 {
  Core.Print(a[2]);
  return 0;
}
```

Fork and nightly: RUNS, exit 0, prints `2`.

`PR-X_tuple_mixed.carbon` (DR1-8):

```carbon
fn F(p: (bool, i32)) -> i32 {
  match (p) {
    case (true, x: i32) => { return x; }
    case (false, y: i32) => { return -y; }
  }
  return 0;
}
```

Fork: REJECTS: `` `match` on `(bool, i32)` has no `default` arm and no
`case` arm that matches every value ``. Nightly: REJECTS:
`` semantics TODO: `HandleMatchIntroducer` ``.

`PR-Y_match_expression.carbon` (DR1-8):

```carbon
fn F(n: i32) -> i32 {
  let r: i32 = match (n) {
    case 0 => 1,
    default => 2
  };
  return r;
}
```

Fork and nightly: REJECTS: `` expected expression ``.

`PR-Z_qualified_none.carbon` (DR1-8): the X06 file with
`case Opt.None => { return 1; }` as the first arm instead. Fork: REJECTS:
`` semantics TODO: `qualified alternative pattern in match case` ``.
Nightly: REJECTS: `` semantics TODO: `choice alternatives with parameters are
not yet supported` ``.

## §5 Gap-row effect and scoreboard delta

(Rewritten 2026-10-13, review fold: A-2 / B-1 / B-M-3 / B-M-4 / B-M-7 /
B-M-8 / B-m-8; row 91's cell amended 2026-10-13, review fold: RR-N-3, for
the kept Co-routines and Concurrency markers.)

-   **Conformance (state T, expected, not of record):** programs 150 plus
    nineteen: 169; PASS 128 plus nineteen: 147; SKIP 22 (the stub stays);
    FAIL 0; bullets PASS 48/56, unchanged (every program goes under a bullet
    that is already PASS; the design-docs bullet stays SKIP). The of-record
    run is the first hosted or owner-dispatched conformance run (R9, R28);
    until then the evidence is the local run of §4.1.
-   **Row 91** (`Goal: design docs documented, cohesive, understandable
    without placeholders`), discharge commit: stays **PARTIAL**, evidence cell
    "DD-1 landed (fork/designdocs/plan.md; commits <shas>); pending state L:
    PR 53's README.md 'Lifetime and move semantics' and PR 55's arithmetic.md
    'Strings' sections, the two W2 allowlist entries. Not run: <§8.10
    verbatim>." This text is the whole cell: it replaces the stale evidence
    of §0.1a ("9 'TODO:' section headings", "the F-008..F-011 pages ... have
    not landed", the self-described placeholders), which commits 1 to 3
    disprove, and does not prefix it (amended 2026-10-14, document-review
    fold: DR2-11; D-DD-12 requires the Not-run list in row 91's evidence).
    Integration commit, when
    both PRs are on trunk, the `ALLOWLIST` is empty and the document-review
    fold has landed: PARTIAL → **DONE** (expected), the cell rewritten to (it
    replaces PR 51's rewrite of the same cell): "DD-1
    (fork/designdocs/plan.md): templates.md, metaprogramming.md, aliases.md,
    blocks_and_statements.md and the `match` section of pattern_matching.md
    carry dated status notes in place of their placeholder self-descriptions
    and document the 0.1 toolchain's behavior with compile-verified examples;
    the interop README's eight TODO sections are written from measured
    behavior, and three sections are added for the milestone's interop items
    that had none (C++ templates, C++ use of Carbon, C++ ranges); every
    milestone language and interop item maps to a design section (plan
    §0.1e); docs/design/interoperability/threads_and_atomics.md states the
    F-008 contract; the design README's Enums and abstract-machine sections
    and assignment.md's TODO-only section are written from measured behavior
    and the records that fix it, the upstream markers of the README's
    Co-routines and Concurrency sections and of comparison_operators.md's
    custom result types are kept, each beside a dated statement of the 0.1
    status, and the README's 'provisional or placeholder' disclosure is
    qualified by a dated note.
    fork/designdocs/check_samples.py's W2 rule finds no placeholder
    self-description, TODO heading or TODO-only section under docs/design/
    beyond that one qualified disclosure. Not designed, by milestone deferral
    or as an extension: Co-routines (milestones.md:268), Concurrency beyond
    C++'s (:271), metaprogramming beyond compile-time evaluation (:272), mixins
    (:273), and comparison results other than `bool` (beyond proposal 702).
    Inline TODO, TBD and provisional notes beside content stay by design (N
    `TODO` occurrences in M files, measured at the commit; plan §0.1c and
    §0.1f). Nineteen documentation-sync programs PASS under their feature
    bullets (expected; local run 2026-10-DD). DONE on two document reviews
    (rows 88-90 precedent); toolchain defects found are filed under their own
    bullets (W-182..W-184, W-188, W-189, W-191) or added to the items that
    own them (W-080, W-053, W-155, W-167, W-014), and the bare-block
    question is filed as design-needed (W-185). Not run: <§8.10
    verbatim>." (W-185's place in this text amended 2026-10-14,
    document-review fold: DR1-4.)
-   **Row 70** (`C++ interop: threading, atomics, memory model,
    synchronization`), discharge commit, after the document-review fold:
    PARTIAL → **DONE** (expected); the cell's "Missing: ..." sentence becomes
    "The memory-model contract is
    docs/design/interoperability/threads_and_atomics.md (DD-1; W-020
    DISCHARGED). Not run: <§8.10 verbatim>."
-   **Header:** DONE plus one and PARTIAL minus one at the discharge (row 70),
    the same again at integration (row 91), against whatever trunk reads then
    (at 162c7e839: 30 / 21 / 4 / 1 → 31 / 20 / 4 / 1 → 32 / 19 / 4 / 1). The
    discharge writes it in the shape of the precedent header
    (claude/carbon-fork-0-1-ev cb3ef2e74:fork/gap-analysis.md:18-24): the
    counts, then "(row 70 PARTIAL → DONE <date> on document review, DD-1 /
    W-020's documentation half, with the expected conformance scoreboard 147
    PASS / 0 FAIL / 22 SKIP over 169 programs, 48/56, expected, not of record
    (Actions disabled); ...)", the totals re-measured at the discharge
    (amended 2026-10-14, document-review fold: DR2-11).
-   Bullet text untouched (R7).

## §6 Churn and collision analysis

No toolchain, prelude, golden, `.github/` or `runner.py` change (D-DD-6's
`--self-test` join is a state-L option, one call). Markdown touched (state T):
aliases.md, blocks_and_statements.md, assignment.md, templates.md,
metaprogramming.md, pattern_matching.md, interoperability/README.md,
interoperability/threads_and_atomics.md (new), README.md,
code_and_name_organization/README.md, expressions/comparison_operators.md,
fork/conformance/README.md (generated table), fork/gap-analysis.md,
fork/decision-log.md, fork/ORCHESTRATION.md, fork/designdocs/plan.md, and the
stub's SKIP line (fork/conformance/programs/project/
design_docs_placeholders.carbon). New files: nineteen programs, thirty-nine
fixtures (thirty-six until the document-review fold added X04 to X06; amended
2026-10-14, document-review fold), the checker. Deleted: nothing. State L adds
docs/guides/tutorial.md and evaluator_faq.md (EV-1's), expressions/literals.md,
and safety/mutation_safety.md (SAFE-1's) (amended 2026-10-13, review fold: A-2 /
B-1 / B-M-5 / B-M-6). The held PRs' overlaps and their resolutions are §0.2's
table; name collisions: no held branch adds a `design_docs_*` program or a
fork/designdocs/ path (`git ls-tree` on each branch head, re-run for rev 4), and
the residue block W-180..W-194 is DD-1's with W-190 unused, which trunk's
ORCHESTRATION records at f67ab650d and the discharge stamp restates (§8.8);
OP-1's residue is W-195 (amended 2026-10-14, review fold: RR2-1). Upstream
convergence: every DD-1 edit to an upstream page is a dated blockquote or a new
section after the original text, so a weekly upstream merge that rewrites a page
conflicts only where upstream replaced the same placeholder, and the fork side
is dropped there in favor of upstream's accepted text.

## §7 Risks and rejected alternatives

-   **R-1 Documentation drifts from the toolchain.** Mitigation: the nineteen
    programs run in every conformance run, and the fixtures run under the
    checker's `--toolchain` mode in the land sequence; a toolchain change that
    breaks a documented sample fails the suite. Falsifier: a sample on a page
    whose program or fixture is not in the checker table (check 4 catches it).
-   **R-2 Status notes read as placeholders by another name.** A note that says
    "not accepted" might be judged a placeholder. Mitigation: each note says
    what is accepted, what the toolchain does, and links the measured section;
    no marker is relabelled (D-DD-1); document review A judges every replaced
    marker and reads each touched page as an evaluator (D-DD-11); D-DD-2's
    break condition (amended 2026-10-13, review fold: B-M-4). Falsifier: a
    document review finding citing the bullet text.
-   **R-3 rumdl reflow breaks quotes or manufactures list items.** Negative
    numbers and `+` stay inside code spans; quotes are compared with collapsed
    whitespace; R31 counts per §0.3. Falsifier: a count delta not listed in §2.
-   **R-4 Program growth under a documentation bullet games the scoreboard.**
    Retired by D-DD-5's rewrite (amended 2026-10-13, review fold: A-2 / B-1):
    no program goes under the design-docs bullet, which stays SKIP; the
    nineteen programs go under feature bullets that are already PASS, so no
    rollup changes. Falsifier: a bullet count other than 48/56 in the local
    run. Rejected alternatives: rev 1's stub deletion with the programs under
    the design-docs bullet (a vacuous PASS for that bullet); keeping the stub
    SKIP and adding no programs (loses R27 enforcement in the suite).
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
-   **Rejected: porting the stranded threading.md** — written before F8a-F8d;
    D-DD-7 disposes of its seven open sub-forks one by one, and the new page is
    written from F-008 and measurements (amended 2026-10-13, review fold:
    A-10).
-   **Rejected: folding the toolchain defects into W-065** — they belong to
    their feature bullets, and W-065 closes with the documentation.

## §8 Verification and discharge

1.  **Per commit:** (1) record the §0.3 counts and the heading lines (`grep -nE
    '^#{1,6} ' <f> > before` over the fence-masked text, so `#include` lines in
    samples never count; amended 2026-10-13, review fold: B-m-5) of every
    touched markdown file; (2) run
    `SKIP=fix-cc-deps,check-build-graph,check-bazel-mod-deps,forbid-llvm-googletest
    uvx prek run --files <touched>` until a run changes nothing; (3) `git diff
    -U0 | grep -nE '^\+\s*#{1,6} [0-9]|^\+#[0-9]'` is empty; (4) re-count and
    `comm -13` the heading sets: only §2's listed deltas; (5) `python3
    fork/designdocs/check_samples.py` and the same with `--toolchain
    /home/user/carbon-build/carbon-trunk/install/bin/carbon` exit 0 against that
    commit's `ALLOWLIST` (§2.12 item 5), the message recording the expected and
    actual W2 output (amended 2026-10-13, review fold: B-M-2); (6) `python3
    fork/conformance/runner.py --self-test` exits 0; (7) a full local
    conformance run with a private `--out` gives the §5 totals for the commits
    so far; (8) the nineteen programs on the nightly give the §2.11 labels; (9)
    the message carries §8.10's list verbatim. R25: edits by the editor tools,
    never shell appends to committed markdown. Commands whose text contains a
    word that check-google-doc-style rewrites are quoted between its ignore and
    resume markers.
2.  **Plan reviews:** two (R29(c)); fixer separate (R11); fold marks
    "(amended <date>, review fold: A-n / B-n)" and a fold record; then
    focused re-reviews, each folded by a separate fixer with "RR-x" marks,
    until one returns a verdict other than REJECT (amended 2026-10-13,
    review fold: RR-A-1).
3.  **Document reviews:** two fresh agents after commit 3 (D-DD-11, with the
    milestone list and §0.1e in the brief); the fixer separate, and its fold
    commit lands before the discharge commit; then one implementation review
    after the discharge commit (amended 2026-10-13, review fold: B-M-4 /
    B-M-5 / B-m-8).
4.  **Conformance:** `--self-test` clean; the stub's row present with its new
    reason, and nineteen rows added to fork/conformance/README.md (amended
    2026-10-13, review fold: A-2 / B-1).
5.  **Ledger (fork/inventory/work-items.json)** (rewritten 2026-10-13, review
    fold: A-1 / A-4 / A-11 / A-13 / B-M-1 / B-M-5 / B-m-2 / B-m-3).
    **Discharge commit.** W-065 notes prefixed "DISCHARGED
    (fork/designdocs/plan.md DD-1, 2026-10-DD; commits <shas>): ..." with
    evidence re-pinned to the new sections and D-DD-2's deviation from its
    stated arbiter recorded; W-020 notes gain "DOC HALF DISCHARGED at DD-1:
    docs/design/interoperability/threads_and_atomics.md" and the item is
    discharged; W-080 evidence gains "toolchain/sem_ir/pattern.cpp:81 CHECK
    'entity_name_id.has_value(): Unhandled pattern inst kind {kind:
    ExprPattern, ...}': the `var` spelling of a refutable root (`var 5 = n;`,
    pattern_matching.md:685) crashes check on the fork, and at pattern.cpp:77
    on the nightly 2026.10.12 (DD-1 probe PR-B, 2026-10-13)", and its notes'
    "Today both spellings stay behind TODOs" gains "(the `var` root crashes;
    see the evidence)"; W-053 evidence gains "a C++ class whose `begin` and
    `end` return raw pointers is not a range: ``cannot access member of
    interface `Core.Iterate` in type `Cpp.Digits` that does not implement that
    interface`` (DD-1 fixture R34)"; W-043 notes gain "DD-1 (2026-10-13)
    answers the verify note: a concrete Carbon class as a C++ template argument
    compiles and runs (P17, `Cpp.Box(Point)`); the symbolic case fails (probe
    PR-T); gap row 56's sentence on class types is stale (plan §0.4 item 8)";
    W-044 notes gain one pointer, "export of a Carbon `template` function:
    see W-191 (the nightly runs it; the fork stops at a CHECK, DD-1 probe
    PR-S)" (amended 2026-10-14, document-review fold: DR2-12: §0.4 item 9 is
    otherwise corrected only in W-191's text, and W-044 would keep the claim
    the nightly refutes).
    **Line numbers** (amended 2026-10-14, document-review fold: DR2-1): the
    page cites in this item were taken at 162c7e839, and commits 1 to 3 moved
    them (pattern_matching.md gained a TOC line, blocks_and_statements.md a
    status note). The texts above and below give them as re-pinned at the
    document-review fold, where `var 5 = n;` is pattern_matching.md:685, the
    `IsTrue` example's body comments :613-618, the usefulness example's
    function :639-650, the constant-tuple rule :590-593, and the bare-block
    example of blocks_and_statements.md, from its lead-in sentence to its
    closing fence, :50-60. The discharge re-opens each at its own commit
    before filing and records the pins in its message and the landed notes;
    the integration commit re-measures W-155's cite after the state-L edits.
    **Integration commit.** W-014 evidence gains "check/import_ref.cpp:5087
    FATAL, TryResolveInstCanonical on SpliceInst (nightly 2026.10.12:
    import_ref.cpp:4875): a template function called from another library
    crashes check (DD-1 probe PR-A, 2026-10-13)", written into PR 51's text;
    W-155 evidence gains "DD-1 fixture R20 (`IsTrue`, pattern_matching.md
    :613-618) and probe PR-L (an irrefutable `case x: i32` arm and an
    irrefutable struct arm, both rejected)"; W-167 evidence gains "DD-1 probe
    PR-I: `var s: Secret = {.x = 1}; s = {.x = 2};` for a class whose one field
    is `private`, outside the class, accepted on the fork and the nightly";
    W-188's notes gain "F-013 D-SAFE-17 (docs/design/values.md:485) makes a
    `Plain` value binding acquire eagerly, which gives the `let` form's
    `(2, 1)` and agrees with issue 686's answer; it does not rule on a
    literal's elements, which issue 686's answer covers" (amended 2026-10-13,
    review fold: RR-A-1).
    **Duplicate scan before filing** (B-M-1): for each residue, search the
    titles, evidence and notes of trunk's ledger and of every live branch
    head's (`git show <head>:fork/inventory/work-items.json`) for its defining
    terms (the crash site, the diagnostic, the design citation), and record
    the result per head in the commit message; ids are confirmed free by `grep
    -o '"W-[0-9]*"'` over the same heads. The rev-2 scan found W-155 and W-167
    (withdrawing W-180 and W-186) and W-080's lane (withdrawing W-181), and
    nothing for the residues below. Residues:
    -   **W-182** (missing-feature; bullet "Control flow: matching — sum-type
        consumption incl. std::variant/std::optional interop"): alternative
        patterns inside tuple patterns and payload subpatterns are checked as
        designator expressions (``name `.Self` not found``); evidence R21,
        match/fail_choice_alternative_pattern.carbon
        `fail_nested_designator_subpattern.carbon`, pattern_matching.md:639-650.
    -   **W-183** (language-gap; bullet "Generics: Integrated templates"):
        member lookup into a constrained template parameter ignores the
        constraint (p002200:433-441, :200-202); evidence R09, PR-K; the
        nightly agrees.
    -   **W-184** (toolchain-defect, a crash and not a TODO site; bullet
        "Project: toolchain implements most 0.1 language features incl. C++
        interop without undermining evaluation"): unbounded compile-time
        recursion overflows the compiler's stack (PR-C: rc 139 on the fork;
        the nightly crashed, and the run hung in its crash handler;
        eval/recursion.carbon:28 "TODO: Diagnose infinite recursion").
    -   **W-185** (design-needed; bullet "Control flow: conditions"; amended
        2026-10-14, document-review fold: DR1-4: rev 4 filed it as a
        language-gap, which presumed bare blocks become statements): whether a
        block on its own is a statement. Proposal 162's grammar (p000162:65)
        includes it, and classes.md:563-570 records how a leading `{` is told
        apart from a struct literal as an open question, one listed option
        being to allow `{` to start a compound statement only after a keyword,
        which is the toolchain's behavior; evidence R04,
        blocks_and_statements.md:50-60; the nightly agrees.
    -   **W-188** (toolchain-defect; bullet "Type system: User-defined types
        (classes)") (amended 2026-10-13, review fold: RR-A-1: rev 2 filed it
        design-needed on the false premise that issue 686 was unanswered): a
        tuple or struct assignment whose literal right-hand side reads the
        target is assigned in place, element by element (`t = (t.1, t.0);`
        and `s = {.a = s.b, .b = s.a};` leave `(2, 2)`; the `let` and `var`
        forms `(2, 1)`), which diverges from the answer the leads gave on
        issue 686 on 2022-11-12 (initialize a temporary from the right-hand
        side, destroy the destination, move the temporary into it; both
        literal forms then leave `(2, 1)`); the upstream nightly 2026.10.12
        behaves the same. No proposal incorporates the answer yet
        (p002511:104-107 says that the issue's rules are not part of proposal
        2511; open issue 2489, "Create assignment order proposal", tracks
        one). Evidence:
        X01, X03, PR-U, the issue 686 closing comment and issue 2489 (§8.10),
        assignment.md "Tuples, structs, choice types, and data classes".
    -   **W-189** (missing-feature; bullet "Control flow: matching — good
        switch equivalents"): a set of tuple patterns never counts as
        exhaustive unless one arm is irrefutable, although
        pattern_matching.md:590-593 treats constant tuples as tuple patterns
        and `bool` like a choice type; evidence PR-R (four constant
        `(bool, bool)` arms), PR-X (`case (true, x: i32)` and
        `case (false, y: i32)` on `(bool, i32)`; added 2026-10-14,
        document-review fold: DR1-8),
        toolchain/check/testdata/match/fail_int_nonexhaustive.carbon:120
        (`fail_bool_pair_enumeration.carbon`), fork/w078b/plan.md:109-125 (its
        R-6, the W-076 root-only record, which no open item owns).
    -   **W-191** (toolchain-defect; bullet "Generics: C++ interop — exporting
        Carbon templates/checked generics as C++ templates") (renumbered from
        rev 2's W-190 at rev 3, while OP-1 held W-190; amended 2026-10-13,
        review fold: RR-FX-1; amended 2026-10-14, review fold: RR2-1): calling
        a Carbon
        function with a `template` parameter from C++ stops check at
        "CHECK failure at toolchain/sem_ir/generic.cpp:96: ... before it was
        resolved." (PR-S, both bodies; identical on the OP-1 toolchain); the
        nightly 2026.10.12 runs the same file and prints `42`; W-044's note
        that Carbon template export exists only after template lowering is
        stale.
    -   **W-187** only under D-DD-9's break condition. **W-180, W-181, W-186**
        withdrawn at rev 2 (owned by W-155, W-080 and W-167), never filed.
        **W-190** stays unused and is never filed: OP-1 held it from
        49e2cf2bf until its discharge (379f20f67) re-allocated it to W-195,
        and DD-1 moved off it at rev 3. **W-192..W-194** spare for later
        folds (amended 2026-10-13, review fold: RR-FX-1; amended 2026-10-14,
        review fold: RR2-1).
6.  **Gap analysis:** §5's row texts and header delta.
7.  **Decision log:** heading `### DD-1: design docs without placeholders
    (2026-10-DD)` inserted directly after the "### Full autonomy and the
    throughput protocol" entry (so first in the landed region at merge time).
    Contents: the bullet verbatim; what landed, page by page; D-DD-1..13 with
    their break conditions; the stale claims of §0.4; the residues by title,
    with the withdrawn rev-1 ids; D-DD-2's deviation from W-065's arbiter and
    the before and after `TODO` counts per file; the sections that stay not
    designed, each with its milestone line (§5); "F-016 not minted"; the
    local-gate statement (D-DD-12) and §8.10's list verbatim (amended
    2026-10-13, review fold: B-M-4 / B-M-7). The `TODO` counts are line
    counts (`git grep -c TODO <commit> -- 'docs/design/*.md'
    'docs/design/**/*.md'`), re-measured at the discharge commit and called
    lines, per file: at the document-review fold, 110 lines in 23 files at
    162c7e839 and 90 lines in 20 files after it (README.md 17 → 15, aliases.md
    2 → 0, assignment.md 1 → 0, blocks_and_statements.md 2 → 0,
    interoperability/README.md 18 → 2, metaprogramming.md 2 → 1,
    pattern_matching.md 1 → 6 and templates.md 2 → 1, the added lines all
    quoted `semantics TODO` diagnostics) (amended 2026-10-14, document-review
    fold: DR2-11). Count check: H3
    +1, every other count unchanged; its lists are dash items, and the new dash
    count equals the old plus the items the entry adds.
8.  **ORCHESTRATION:** the "Last updated" paragraph, the branch row
    `claude/carbon-fork-0-1-dd` (trunk has one since f67ab650d; the discharge
    rewrites it, and a merge keeps one row with the discharge's text), the id
    reservation, verbatim: "W-180..W-194 (W-180, W-181, W-186 withdrawn;
    W-187 contingent; W-190 unused; W-192..W-194 spare); OP-1's residue is
    W-195", which agrees with OP-1's record (379f20f67) and trunk's
    (f67ab650d), and the merge position, after PR 56 (OP-1) (amended
    2026-10-13, review fold: RR-FX-1; amended 2026-10-14, review fold: RR2-1
    / RR2-FX-1). The stamp also amends the row of the stranded design-docs
    branch (`claude/carbon-fork-0-1-7mwfb7-design-docs`, at
    fork/ORCHESTRATION.md:452 in f67ab650d, "Reconstruct per the recipe"): its
    F-008 portion is superseded by
    docs/design/interoperability/threads_and_atomics.md (DD-1, D-DD-7) and
    must not be ported, F-010 remains on SC-1, and F-011 has landed; the
    discharge message lists that row and W-044's pointer (§8.5) (amended
    2026-10-14, document-review fold: DR2-12).
9.  **Landed notes** appended to this plan: commits, deviations (R17: one
    sentence each), measured totals.
10. **Not run** (added 2026-10-13, review fold: B-M-7). Copied verbatim into
    every commit message, the decision-log entry, the evidence of rows 91 and
    70, and the PR body; the writer extends it, never shortens it:
    -   no conformance run of record: GitHub Actions on the repository is
        disabled and the owner's runner is not used (R28), so every total is a
        local run on the container-built toolchain;
    -   no bazel and no file_test: the container has no bazel, and DD-1
        changes no golden;
    -   no platform other than Linux x86-64; the integer mapping on the
        interop page (`long` is `i64`, `size_t` is `u64`) is stated for 64-bit
        Linux;
    -   PR-C on the nightly did not finish: the run hung in the crash handler
        and was terminated (an earlier run exited rc 139);
    -   no build of a branch-head commit itself (amended 2026-10-14, review
        fold: RR2-2): the heads at rev 4 are trunk f67ab650d, SC-1 a9c887101
        and OP-1 379f20f67 (PR 53 adaae4e35, PR 51 f96fe8a7a, PR 52
        ea573f672, PR 54 cb3ef2e74 and PR 55 21307851a unchanged). SC-1 was
        measured on its builds at bc8b37290 (rev 1), ff490bd48 (rev 2) and
        18775fee3 (rev 4), the last with the head's toolchain and prelude
        (`git diff --stat 18775fee3 a9c887101 -- toolchain core` is empty);
        OP-1 on its build at 5d9edb3e0, whose toolchain/ and core/ differ from
        the head's by three testdata goldens only. The writer re-reads the
        heads at discharge with `git for-each-ref` and names the build each
        was measured on;
    -   no state-L toolchain (trunk with every held PR merged) exists until
        the integration commit builds one;
    -   online status checks, made on 2026-10-13, cover four records only;
        no other issue or PR the pages cite was checked online (amended
        2026-10-13, review fold: RR-A-1: rev 2 checked none). Issue 686
        (https://github.com/carbon-language/carbon-lang/issues/686) was
        closed as completed on 2022-11-12 with the leads' answer: "initialize
        a temporary object from the right-hand side", "destroy the
        destination", "move the right-hand side into the left-hand side"
        (the full record is under §2.3). Issue 2489
        (https://github.com/carbon-language/carbon-lang/issues/2489), which
        tracks the proposal for that answer, is open. Issue 749 was closed
        as completed on 2021-08-25, and PR 89 was closed unmerged on
        2021-08-29, as the aliases.md and metaprogramming.md status notes
        say;
    -   the document-review fold could not check leads issue 6830 online
        (the GitHub API and github.com refused carbon-language/carbon-lang in
        its session, and no record of the issue is in the repository), so
        DR1-12 is not folded (amended 2026-10-14, document-review fold);
    -   SC-1's head moved after rev 4 to 4bc4802ae; the fold measured its new
        fixtures and probes on the carbon-sc build at fb12f63cb, whose
        toolchain and prelude equal the head's (`git diff --stat fb12f63cb
        4bc4802ae -- toolchain core` is empty), and ran the W2 rule over the
        head's docs/design/ (amended 2026-10-14, document-review fold).

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
    program change other than the stub's SKIP line and the nineteen new
    programs (amended 2026-10-13, review fold: A-2 / B-1).
8.  Dates: replace every `2026-10-DD` with the commit date.
9.  Never rename or replace a marker to get past the W2 rule (D-DD-1), and
    never state a rule that no proposal, leads decision or fork decision
    states; write what was measured, and call a question open only after
    checking its issue's status (D-DD-3; added 2026-10-13, review fold: A-1 /
    A-8 / B-M-4; amended 2026-10-13, review fold: RR-A-1 / RR-N-3).

## Review fold record (rev 2, 2026-10-13)

Plan review A (fidelity to the toolchain and the accepted proposals: REJECT, one
BLOCKER, four MAJOR, ten MINOR) and plan review B (process, records and
Goodhart: REJECT, two BLOCKER, eight MAJOR, eight MINOR) were folded by a
separate fixer (R11) into rev 2. All 33 findings are folded and none is
rejected. A-1 is folded with one cited deviation from its suggested fix, given
in its row (withdrawn at rev 3; amended 2026-10-13, review fold: RR-A-1). Every
measurement a finding is about was re-run in the fixer's own scratch
(`.../scratchpad/dd1-fixer/`, with `XDG_CACHE_HOME` there): all 47 rev-1 page
samples and fixtures on the fork toolchain, the nightly, and the OP-1
(5d9edb3e0) and SC-1 (ff490bd48) toolchains, each identical to §4.1; the rev-2
samples and probes on those four plus UA-2 and ST-1; the nineteen programs
through the runner on the fork toolchain and the nightly; the W2 rule over trunk
and every held branch's docs/design/; the id and duplicate scans over every live
branch head. Reviewer B's majors and minors are written B-M-n and B-m-n in the
marks.

| Finding | Severity | Disposition | Where |
| --- | --- | --- | --- |
| A-1 | BLOCKER | Folded. The paragraph states only measurements (literal form `(2, 2)`, `let` and `var` forms `(2, 1)`, PR-U), the status note no longer calls issue 686 open (p002511:104-107), X01 quotes the measured sentence and gains the struct swap, X03 pins the `let` form, PR 53's values.md and mutation_safety.md hunks join §0.2, and a state-L text cites D-SAFE-17. Rev 2 also deviated from the suggested fix by filing W-188 as design-needed on the premise that issue 686 was unanswered; the focused re-review refuted that premise (issue 686 was closed with the leads' answer on 2022-11-12), and rev 3 withdraws the deviation: W-188 is a toolchain-defect filed at discharge, and the page states the answer (amended 2026-10-13, review fold: RR-A-1) | §2.3, §2.12, §2.13, §0.2, §0.1d, D-DD-3, D-DD-10, §8.5 |
| A-2 | MAJOR | Folded with B-1: the stub stays SKIP with a refreshed R10 reason; the nineteen programs go under already-PASS feature bullets; bullets stay 48/56; §0.1b states EV-1's precedent correctly | D-DD-5, §0.1b, §0.4 item 3, §2.11, §4.1, §5, R-4 |
| A-3 | MAJOR | Folded: the reference mapping is the toolchain's, proposal 5434 defers it (p005434:897-900); the README :3733 note covers primitives (5448), pointers (6357), and the `T&` sentence at :3757-3758 | §2.7 pointers section, §2.9 item 5, §0.1c, D-DD-8 |
| A-4 | MAJOR | Folded: "as specified above" is qualified; a "Not in the 0.1 toolchain" item states the tuple-exhaustiveness difference; W-189 filed; probe PR-R | §2.6, §0.1, §0.1d, §4.3, §8.5 |
| A-5 | MAJOR | Folded with B-2: a dated note after README :149 (state T, plus a state-L sentence); clause (a) gains `provisional or placeholder`; the disclosure is a `QUALIFIED` W2 entry tied to the note | §2.9 item 6, D-DD-2, §2.12, §0.1, §0.1c, §2.11 stub text |
| A-6 | MINOR | Folded: the state-T status says SC-1 implements member requirements and W-028 owns `require` blocks and predicates | §2.4 |
| A-7 | MINOR | Folded: only `musteval fn` appears in proposals 7140 and 7697 and in functions.md | §2.5 |
| A-8 | MINOR | Folded with B-M-4: the comparison marker stays with a 0.1 note beside it; the abstract machine gets content with citations | §2.10, §2.9 item 4, D-DD-1, §0.1c, §4.2 |
| A-9 | MINOR | Folded: the note keeps proposal 5164's own statement and quotes the first example's diagnostic, pinned by quote fixture X02 | §2.6, D-DD-4, §1.2, §2.12, §4.1 |
| A-10 | MINOR | Folded: D-DD-7 disposes of the seven sub-forks with records; name reservation stays open on the page; point 7's exception sentence is attributed to F-006 and W-016 | D-DD-7, §2.8, §0.2, §4.2, R-rejected list |
| A-11 | MINOR | Folded with B-m-3: the `var 5` crash joins W-080's evidence with the exact CHECK line (pattern.cpp:81; nightly :77); W-181 withdrawn; W-184 is toolchain-defect; W-186 withdrawn (B-M-1) | §0.1d, §0.4 item 5, §4.3, §8.5, D-DD-10 |
| A-12 | MINOR | Folded: OP-1, PR 53 and SC-1 rows rebuilt from the heads; every page sample re-measured on the OP-1 and current SC-1 toolchains (identical); state-L texts for the threads page and M7 | §0.2, §0.1d, §2.13 |
| A-13 | MINOR | Folded: the nightly crashes too (import_ref.cpp:4875); both sites in W-014's evidence | §0.1d, §0.4 item 6, §4.3, §8.5 |
| A-14 | MINOR | Folded with B-m-4: P04 gains a class with a template parameter (re-derived: `8`); the inline rule says an earlier `import Cpp` is required, pinned by R32 (PR-G as a page block); the operator list is split | §2.4, §2.7, §4.1, §4.2 |
| A-15 | MINOR | Folded: both counts are 17 | §0.1c |
| B-1 | BLOCKER | Folded with A-2 | as A-2 |
| B-2 | BLOCKER | Folded with A-5; the stub's SKIP text records how its known-missing slice was handled, and so will the row text and the decision log | as A-5, §5, §8.7 |
| M-1 | MAJOR | Folded: W-180 and W-186 withdrawn for W-155 and W-167; R20, PR-L and PR-I join their evidence at integration; pages cite them as on held PRs at state T; §8.5 gains a duplicate scan | header, §0.1d, D-DD-10, §1.4, §2.2, §2.3, §2.6, §2.13, §8.5 |
| M-2 | MAJOR | Folded: a per-commit `ALLOWLIST` (sixteen, six, two, none) with expected W2 output in each message | D-DD-2, D-DD-6, §2.12, §3, §8.1 |
| M-3 | MAJOR | Folded: row 91 is written DONE only by the integration commit once PR 53 and PR 55 are on trunk; D-DD-9's break covers PR 53, PR 54 and PR 55 | D-DD-9, D-DD-13, §2.14, §3, §5 |
| M-4 | MAJOR | Folded: no relabelled marker (D-DD-1); review A judges each replaced marker and both reviews read as evaluators; row 91 lists the not-designed sections with milestone lines; D-DD-2 records its narrowing of W-065's arbiter | D-DD-1, D-DD-2, D-DD-11, §2.9, §2.10, §5, R-2 |
| M-5 | MAJOR | Folded: §0.1e maps every milestone item; three measured sections added (C++ templates P17, C++ use of Carbon P18 and R33, C++ ranges P19 and R34) and a measured inheritance sentence; W-190 filed for the template-export crash (PR-S; renumbered W-191 at rev 3, RR-FX-1); both document reviews get the milestone list | §0.1e, §2.7, §2.11, §4.1-§4.3, §8.5, D-DD-11 |
| M-6 | MAJOR | Folded: state-L texts link M7 and D-SAFE-16 from contract item 2 and disambiguate `Core.Sync`; PR 53's safety pages join §0.2 | §2.13, §0.2 |
| M-7 | MAJOR | Folded: §8.10 "Not run", required verbatim in commits, the decision log, rows 91 and 70, and the PR body; a PR body spec in §3 | §8.10, D-DD-12, §3, §5 |
| M-8 | MAJOR | Folded: §0.1f classifies all 64 occurrences; the tuples note joins the cohesion notes; the mixins TODO is classified (deferred by milestones.md:273); row 91 says inline notes stay by design, with the count | §0.1c, §0.1f, §2.9 item 5, D-DD-8, §5 |
| m-1 | MINOR | Folded: OP-1, PR 51 and PR 53 rows filled; optional.md linked at state L; DD-1's row-91 text replaces PR 51's | §0.2, §2.13, §2.14, §5 |
| m-2 | MINOR | Folded: the W-014 amendment moves to the integration commit | §0.4 item 6, D-DD-10, §8.5 |
| m-3 | MINOR | Folded with A-11 | as A-11 |
| m-4 | MINOR | Folded with A-14 | as A-14 |
| m-5 | MINOR | Folded: the anchor is :1038-1039; heading sets use `grep -nE '^#{1,6} '` over fence-masked text | §2.9 item 5, §0.1c, §0.3, §8.1 |
| m-6 | MINOR | Folded: the status note lists the differences and says no other is known | §2.4 |
| m-7 | MINOR | Folded with A-1: X01's header says what it pins and why it is not a design derivation; W-188 is the residue (at rev 3, the header says the pinned result differs from issue 686's answer; amended 2026-10-13, review fold: RR-A-1) | §2.12, §4.1 |
| m-8 | MINOR | Folded: the document-review fold commit precedes the discharge, which writes row 91 PARTIAL | §3, D-DD-11, D-DD-13, §8.3 |

### Focused re-review (rev 3, 2026-10-13)

The focused re-review of rev 2 (a1d96520a) returned **REJECT**: A-1 NOT
RESOLVED (BLOCKER), B-1 and B-2 RESOLVED, and four new MINOR findings, N-1 to
N-4. Its consistency checks passed: the W2 allowlist counts per commit (16, 6,
then 2), D-DD-13 against §5 and §3, B-1's sixteen bullets against
fork/conformance/out/scoreboard.json (every one PASS, so bullets stay 48/56),
§0.1b against EV-1's plan (fork/evaluator/plan.md:562-567 on PR 54), and the
id reservation as of its scan. A separate fixer (R11) folds all five findings
into rev 3, none rejected, and adds one finding of its own, RR-FX-1. Marks
read "RR-" followed by the re-review's own finding id. Because the verdict was
REJECT, the Status line read "rev 3 -- NOT signed off: A-1", and no Sign-off
section was written until a further focused re-review returned a verdict
other than REJECT (it did; see the next section and the Sign-off).

The fixer's verification, in its own scratch (`.../scratchpad/dd1/rr3/`,
with `XDG_CACHE_HOME` there): X01 and X03 on the fork toolchain (0bdce60a5)
and the nightly 2026.10.12, where X01 prints `2 2 2 2` and X03 `2 1` on both,
as the re-review measured; issue 686, issue 2489, issue 749 and PR 89 read
online (§2.3's record, §8.10); the blockquote-aware quote matcher prototyped
over the note of §2.9 item 6, where the `QUALIFIED` quote matches once the
markers are stripped and fails with whitespace collapsing alone, which
reproduces N-1, while X01's and X03's quotes still match the amended §2.3
text; the id scan over trunk and every live branch head (RR-FX-1); and the
R31 scan of this file at every indent, outside fences and inside the
page-text fences (counts in the commit message).

| Finding | Severity | Disposition | Where |
| --- | --- | --- | --- |
| RR-A-1 (A-1) | BLOCKER | Folded. Issue 686 checked online: closed as completed on 2022-11-12 with the leads' answer; issue 2489, which tracks the proposal, is open. §2.3's state-T paragraph states the answer, that no proposal incorporates it yet (proposal 2511 does not; issue 2489 tracks one), that both literal forms leave `(2, 1)` under it, and that the toolchain's `(2, 2)` differs (W-188); the status note says the answer is not yet in a proposal; the state-L sentence cites D-SAFE-17 for the `let` form and says that F-013 and issue 686 agree on `(2, 1)`. W-188 is a toolchain-defect filed at discharge, with the issue 686 closing comment and issue 2489 beside X01, X03 and PR-U as evidence; X01's header says it pins the current result, which differs from the answer, and changes when W-188 is fixed. "Open question" is gone from the header, §0.1d, D-DD-10, §2.3, §2.12, §8.5 and the rev-2 A-1 row, and rev 2's deviation from review A's fix is withdrawn. D-DD-3 and §1.4 add leads decisions as a source, and §8.10 records the check. One cited wording deviation: the page's clause on customizing follows the closing comment ("allow customizing assignment when a different approach would be more efficient"), not the suggested "where reinitializing in place is safe", which the comment does not say | header, §0.1d, D-DD-3, D-DD-10, D-DD-11, §1.4, §2.3, §2.12, §2.13, §3, §4.1, §8.2, §8.5, §8.10, hand-off note 9, rev-2 A-1 and m-7 rows |
| RR-N-1 (N-1) | MINOR | Folded: §2.12 items 3 and 5 strip leading blockquote markers (`^\s*>\s?`, repeated) from each prose line before collapsing whitespace; item 8 adds a matcher self-check with a two-line and a nested blockquote text, which every default run performs first and commit 1's message records | §2.12 items 3, 5 and 8; §2.9 item 6 |
| RR-N-2 (N-2) | MINOR | Folded: the note says that each former placeholder page or section now carries measured 0.1 content or a dated status note, and names them; the state-L sentence is limited to docs/design/ | §2.9 item 6 |
| RR-N-3 (N-3) | MINOR | Folded, first option: the Co-routines and Concurrency markers stay, each followed by its dated deferral note, as comparison_operators.md's marker does; D-DD-1 states one rule for future extensions and milestone deferrals; §0.1c, §1.1 and row 91's cell follow. Rule (c) does not hit a section that holds a marker and a note, so the allowlist counts per commit (16, 6, 2, 0) are unchanged | D-DD-1, §0.1c, §1.1, §2.9 item 4, §5, hand-off note 9 |
| RR-N-4 (N-4) | MINOR | Folded: §2.13 reads "(item 6 of §2.9)" and "(item 3 of §2.9)". Rev 2's count matched only digit-and-period markers and could not see a "6)" continuation, so its commit message's R31 claim was incomplete; rev 3 scans `^\s*[0-9]+[.)]` at every indent, outside fences and inside the page-text fences, before and after prek | §2.13 |
| RR-FX-1 (fixer) | — | Added: OP-1's implementation-review fold (49e2cf2bf, 2026-10-13 23:53 UTC, after rev 2, and not in the re-review's scan, which found no W-18x or W-19x id on any head; OP-1 head aa89cd7cd) took W-190 for its own lowering defect as "the first id after DD-1's reserved W-180..W-189" and wrote it into docs/design/optional.md (:302 and :505) on its branch, which merges before DD-1. Rev 2's W-190 is renumbered W-191; the reservation is W-180..W-189 and W-191..W-194, with W-192..W-194 spare. Superseded in part at rev 4: OP-1's discharge (379f20f67) re-allocated its W-190 to W-195, so W-190 is unused, not OP-1's; DD-1 keeps W-191 (amended 2026-10-14, review fold: RR2-1) | header, §0.1d, §0.1e, §0.4 item 9, D-DD-10, §1.4, §2.7, §4.2, §5, §6, §8.5, §8.8, rev-2 M-5 row |

### Focused re-review 2 (rev 4, 2026-10-14)

The focused re-review of rev 3 (15c719ddc; its own title is "round 1")
returned **APPROVE-WITH-AMENDMENTS** with no BLOCKER open. A-1 is RESOLVED:
issue 686 and issue 2489 were re-fetched online on 2026-10-14 and match §2.3's
record and §8.10; §2.3's page text documents rather than decides; it is
consistent with F-013 D-SAFE-17 on PR 53 (values.md:485 and
mutation_safety.md:313 and :415-416 there); W-188 is filed as a
toolchain-defect; and X01, X03 and the `var` and struct-`let` forms were
re-measured on the fork toolchain and the nightly 2026.10.12 with the plan's
results. N-1 to N-4 are VERIFIED (the blockquote-aware matcher prototyped, the
README note's places and anchors, the marker rule, and the R31 counts outside
and inside the page-text fences). B-1 and B-2 are RESOLVED on spot-check, and
§3's commit structure and PR body spec are present. It raised three new
findings, one MAJOR and two MINOR. A separate fixer (R11) folds all three into
rev 4, none rejected, and adds one finding of its own, RR2-FX-1. Marks read
"(amended 2026-10-14, review fold: RR2-x)".

The fixer's verification, in its own scratch (`.../scratchpad/dd1-rr2/fix4/`,
with `XDG_CACHE_HOME` under `.../dd1-rr2/`): OP-1's head 379f20f67 read at
fork/ORCHESTRATION.md:118-120, fork/decision-log.md:2961-2966 and :3286-3293,
docs/design/optional.md:302 and :505 (both W-195) and its ledger (maximum
W-195), which reproduces RR2-1; the id scan over the 73 refs the header names,
with its result there; the toolchain/ and core/ diff from 18775fee3 to a9c887101
empty, the container's `carbon-sc` install at `0.0.0-0.dev+18775fee3`, and the
same diff from 5d9edb3e0 to 379f20f67 listing three testdata goldens only, which
with §0.2 and §8.10 naming 77838fdd5 and 1fc03110e reproduces RR2-2; the 67
sample, fixture and probe files of revs 1 and 2 (the 47 of rev 1 and the 20 of
rev 2) re-run on the fork, nightly, SC-1 (18775fee3) and OP-1 (5d9edb3e0)
builds, where the SC-1 and OP-1 builds give the fork's result for every file
(the first error line, the CHECK line of each crash, as at pattern.cpp:81 and
generic.cpp:96, or the program's output), X01 prints `2 2 2 2`, X03 `2 1` and
PR-U's three files `2 1`, `2 2` and `2 1` on the fork and the nightly, and PR-N
runs on 18775fee3 (prints `12`) and is rejected on the fork; the W2 rule of
§2.12 item 5, prototyped, over docs/design/ at trunk 162c7e839 and f67ab650d,
SC-1 a9c887101 and OP-1 379f20f67, which finds the same hits at every head
(keyed by file, section and clause); `git ls-tree` on every held head (no new
`design_docs_*` program or fork/designdocs/ path); and `grep -nE '(^| )#[0-9]'`
over this file, whose one prose hit outside fences and tables was §2.3's
lead-in, which reproduces RR2-3. The R31 counts before and after prek, at every
indent outside fences and inside the page-text fences, are in the commit
message.

| Finding | Severity | Disposition | Where |
| --- | --- | --- | --- |
| RR2-1 | MAJOR | Folded as suggested. W-191 is kept; the reservation is restated as the block W-180..W-194 with W-190 unused, recorded once in the header (OP-1 held W-190 from 49e2cf2bf until its discharge 379f20f67 re-allocated it to W-195; DD-1 moved off it at rev 3), which trunk's f67ab650d also records; every "W-190 is OP-1's" is replaced; §8.8 gives the stamp's reservation text verbatim; the ledger maximum is W-195 (OP-1, 379f20f67); the id scan is re-run over every live ref and its result recorded with the new heads | header, §0.4 item 9, D-DD-10, §6, §8.5, §8.8, RR-FX-1 row |
| RR2-2 | MINOR | Folded. §0.2, §0.1d and §8.10 name the current heads (trunk f67ab650d, SC-1 a9c887101, OP-1 379f20f67) and the build each was measured on: SC-1 on 18775fee3, the head's toolchain and prelude, re-measured for rev 4; OP-1 on 5d9edb3e0, whose toolchain/ and core/ differ from the head's by three testdata goldens only. The OP-1 row reads "PR 56, OP-1: discharged at 379f20f67 (W-058; W-170..W-179 and W-195 filed)". The writer refreshes the heads at discharge from `git for-each-ref` | §0.1d, §0.2, §2.12, §8.10 |
| RR2-3 | MINOR | Folded: §2.3's lead-in names the kept lines without a hash ("the 'See leads issue' line and its link to issue 686"); no other prose line outside fences and tables has a space-preceded `#` and digit | §2.3 |
| RR2-FX-1 (fixer) | — | Added: trunk advanced from 162c7e839 to f67ab650d (2026-10-14 00:20:59 UTC, after the re-review's scan; fork/ORCHESTRATION.md only). That stamp makes OP-1 PR 56, held open, sets the queue to PR 53, PR 51, PR 52, SC-1, PR 54, PR 55, PR 56, then DD-1, adds a `claude/carbon-fork-0-1-dd` branch row, and records W-190 as unused. The header's merge position cites it; §8.8 rewrites that row instead of adding a second; §0.3 records that the file's heading and list counts are unchanged there (534 lines; :437 is :452). No docs, toolchain, prelude or program changed, so the floor and every other line number stand | header, §0.3, §6, §8.8 |

## Sign-off

Signed off for implementation on 2026-10-14 at rev 4 by the orchestrator under
R29(a). The focused re-review of rev 3 returned APPROVE-WITH-AMENDMENTS with no
BLOCKER open, and rev 4 folds its three findings, none rejected, so no further
re-review is owed. Every review of this plan:

| Review | Of | Verdict | Findings | Folded in |
| --- | --- | --- | --- | --- |
| Plan review A (fidelity to the toolchain and the accepted proposals) | rev 1 (bed95d667) | REJECT | 15: one BLOCKER (A-1), four MAJOR, ten MINOR | rev 2 (a1d96520a): all folded, none rejected |
| Plan review B (process, records and Goodhart) | rev 1 (bed95d667) | REJECT | 18: two BLOCKER (B-1, B-2), eight MAJOR (B-M-1 to B-M-8), eight MINOR (B-m-1 to B-m-8) | rev 2 (a1d96520a): all folded, none rejected |
| Focused re-review 1, of rev 2 | rev 2 (a1d96520a) | REJECT: A-1 NOT RESOLVED; B-1 and B-2 RESOLVED | 5: A-1 (BLOCKER, still open) and four new MINOR (N-1 to N-4) | rev 3 (15c719ddc): all folded, none rejected; the fixer added RR-FX-1 |
| Focused re-review 2, of rev 3 (its own title: "round 1") | rev 3 (15c719ddc) | APPROVE-WITH-AMENDMENTS: A-1 RESOLVED; N-1 to N-4 VERIFIED; B-1 and B-2 RESOLVED on spot-check | 3 new: one MAJOR (RR2-1), two MINOR (RR2-2, RR2-3) | rev 4 (this revision): all folded, none rejected; the fixer added RR2-FX-1 |

The three original BLOCKERs, each RESOLVED:

| BLOCKER | Finding | Status | Verified by |
| --- | --- | --- | --- |
| A-1 | the assignment.md text decided leads issue 686 and contradicted F-013 D-SAFE-17 on PR 53 | RESOLVED | focused re-review 2 (rev 3's fold: §2.3 documents the measured results and the leads' 2022-11-12 answer, cites issue 686 and issue 2489, and files W-188 as a toolchain-defect); focused re-review 1 had found rev 2's fold NOT RESOLVED |
| B-1 | D-DD-5 made the documentation bullet PASS with programs that cannot test it | RESOLVED | focused re-review 1 (the stub stays SKIP; the nineteen programs sit under sixteen bullets that are already PASS, so bullets stay 48/56); spot-checked again by focused re-review 2 |
| B-2 | the design README's "provisional or placeholder" sentence was left untouched | RESOLVED | focused re-review 1 (clause (a) matches the phrase; the dated note after README :149; the `QUALIFIED` entry tied to it); spot-checked again by focused re-review 2 |

Ids: DD-1's block is W-180..W-194. W-182..W-185, W-188, W-189 and W-191 are
filed at discharge (§8.5); W-180, W-181 and W-186 are withdrawn unused; W-187
is contingent (D-DD-9); W-190 stays unused and is never filed (OP-1's residue
is W-195); W-192..W-194 are spare. No fork design id is minted: F-016 stays
unallocated (D-DD-3).

Merge position: last, after OP-1 (PR 56): PR 53, PR 51, PR 52, SC-1, PR 54, PR
55, PR 56, then DD-1 (trunk's fork/ORCHESTRATION.md at f67ab650d).
Implementation follows §3: commits 1/4 to 3/4, the document reviews and their
fold, the discharge (4/4), the implementation review and its fold, then the
integration commit at state L after OP-1 lands.

## Document-review fold (2026-10-14)

The two document reviews of D-DD-11 read commits 1/4 to 3/4 (3ff319642,
a32421433, 4287fe0c0). Review 1 (fidelity) returned **REJECT**, with one
BLOCKER (DR1-1), four MAJOR (DR1-2 to DR1-5) and eleven MINOR (DR1-6 to
DR1-16) findings. Review 2 (readability, cohesion, Goodhart,
records-readiness) returned **APPROVE-WITH-AMENDMENTS**, with two MAJOR
(DR2-1, DR2-2) and ten MINOR (DR2-3 to DR2-12) findings. A separate fixer
(R11) reproduced every finding in its own scratch
(`.../scratchpad/dd1-impl/fixer/`, `XDG_CACHE_HOME` there) and folds them in
one commit, "DD-1: document-review fold", with one finding of its own,
DR-FX-1. Of the 28 findings, 27 are folded and one, DR1-12, is deferred to
commit 4/4; DR1-14 and DR2-4 are folded with a cited deviation, and
DR1-10's optional part and one item of DR2-5 are declined with the evidence
in their rows. Fold marks read
"(amended 2026-10-14, document-review fold: <id>)". Because review 1
returned REJECT, D-DD-11's break condition applies: a second round of both
document reviews reads this fold before the discharge.

The fixer's reproductions: p002200 (:127-129, :200-225, :348-357, :433-441,
:935-1000) against templates.md's status note (DR1-1, DR1-2);
claude/carbon-fork-0-1-safe's mutation_safety.md (:84-86, :257-270,
:399-402) and the W-149 title (DR1-3); classes.md:563-570 (DR1-4); README.md
:3976-3978 and arithmetic.md:184-188 at 4287fe0c0 (DR1-5); probes PR-W,
PR-D, PR-X, PR-Y, PR-Z and PR-V and the `Circle` and `Opt.Some` files on the
fork toolchain, the nightly and the OP-1, SC-1 (fb12f63cb), UA-2 and ST-1
builds (DR1-6, DR1-7, DR1-8, DR1-16, DR-FX-1); the nightly's three errors on
P03 (DR2-6); the old W2 rule over scratch pages with a blockquote-wrapped
phrase and a lowercase `Todo:` heading, both missed (DR2-2), and with
list-item, HTML-comment, TBD-only and empty sections, all missed (DR2-8);
and the moved line numbers of §8.5 (DR2-1). The online check that DR1-12
needs could not be made (§8.10).

| Finding | Severity | Disposition | Where |
| --- | --- | --- | --- |
| DR1-1 | BLOCKER | Folded. The status note states both comparisons: the sketch against proposal 2200 (ad hoc API specialization rejected, template constraints answering the last section) and the toolchain against proposal 2200 (the Limits list: W-183, W-014, `match`) | templates.md; §2.4 |
| DR1-2 | MAJOR | Folded. `template constraint` and member requirements are attributed to proposals 818 and 2200, F-010 to `require` blocks and predicates, on templates.md (status and the `Circle` paragraph) and in the README note; the state-L texts follow | templates.md, README.md; §2.4, §2.9 item 3, §2.13 |
| DR1-3 | MAJOR | Folded. The threads page says held PR 53 names `Core.Thread` and `Core.Atomic(T)` for its stage 5 (W-149) and leaves only `Core.MemoryOrder` open; D-DD-7 (4) and a state-L text follow | threads_and_atomics.md; D-DD-7, §2.8, §2.13 |
| DR1-4 | MAJOR | Folded. Both places cite the open question of classes.md:563-570, "Until that is resolved" is gone, and W-185 is filed as design-needed | blocks_and_statements.md; §2.2, §8.5, §5 |
| DR1-5 | MAJOR | Folded. The README note names the two sections that stay empty (PR 53, PR 55); state L replaces that sentence; the `QUALIFIED` quote still matches | README.md; §2.9 item 6, §2.13 |
| DR1-6 | MINOR | Folded: a plain `fn` with a body; builtin functions are evaluated (probe PR-W) | metaprogramming.md; §2.5, §4.2, §4.3 |
| DR1-7 | MINOR | Folded: the list header drops "each a filed fork work item", the nominal-interface item becomes a paragraph after the example, and the `match` item quotes its `semantics TODO` | templates.md; §2.4, §4.2 |
| DR1-8 | MINOR | Folded: `match` expressions leave the list (a sentence says proposal 2188 leaves them to future work), an item for alternative patterns written with the type's name is added (X06, testdata TODO), and the W-189 item and W-189's evidence cover tuple patterns with bindings (PR-X) | pattern_matching.md; §2.6, §8.5, §4.1-§4.3 |
| DR1-9 | MINOR | Folded: the comment names `const int* _Nonnull`; P13 regenerated from the page block | interop README, design_docs_cpp_pointers.carbon; §2.7 |
| DR1-10 | MINOR | Folded: the constant value is qualified in the opening list and the runtime-value sentence drops its rationale. The optional sample comment is declined: the paragraph after the sample states the divergence, and P01 stays unchanged | aliases.md; §2.1 |
| DR1-11 | MINOR | Folded: the link names classes.md's construction rule | assignment.md; §2.3 |
| DR1-12 | MINOR | Deferred to commit 4/4: leads issue 6830's status could not be checked online in this session, and D-DD-3 calls a question open only after that check | §2.7 note, §8.10 |
| DR1-13 | MINOR | Folded: the README note keeps that no accepted proposal designs metaprogramming | README.md; §2.9 item 2 |
| DR1-14 | MINOR | Folded with DR2-5's wording, "which adds a `Core.Sync` library veneer over the C++ types" (cited deviation: it keeps §2.13's anchor phrase, so no state-L text changes) | threads_and_atomics.md; §2.8 |
| DR1-15 | MINOR | Folded: "as row 88 is (and row 89 on held PR 53)". The anticipatory wording at commits 1 and 2 is accepted as plan-mandated (§2.11) and goes to commit 4/4's landed notes | stub line 6; §2.11 |
| DR1-16 | MINOR | Folded: quote fixture X04 pins both working forms; probe PR-V the rejected one; a §4.2 row | X04; §2.7 note, §2.12, §4.1-§4.3 |
| DR2-1 | MAJOR | Folded into §8.5: every page cite is re-pinned at the fold (pattern_matching.md:685, :613-618, :639-650, :590-593; blocks_and_statements.md:50-60), and the discharge re-opens each at its own commit | §8.5 |
| DR2-2 | MAJOR | Folded: clause (a) runs over blockquote-stripped text, every clause ignores case, and `--self-check` gains thirteen W2 cases; mutation tests on a scratch tree fail as they should | check_samples.py; D-DD-2, §2.12 items 5 and 8 |
| DR2-3 | MINOR | Folded: two labels, "Fork status" for a note that replaces a placeholder or opens a section DD-1 wrote (now also Enums and the abstract machine) and "Fork note" for every other annotation; counts unchanged | README.md, comparison_operators.md, code_and_name_organization/README.md; §2 conventions, §2.9, §2.10 |
| DR2-4 | MINOR | Folded: the README note defines the 0.1 toolchain, fork decisions, fork work items and held PRs, with links; "measured 0.1 content", "the SC-1 workstream" and "the F8 slices" are reworded; program paths are given from the root. Cited deviation: "held PR" is defined, not renamed "pending PR", because §1.4 and §2.13 edit that phrase at state L | README.md, templates.md, threads_and_atomics.md, interop README; §2.4, §2.7-§2.9 |
| DR2-5 | MINOR | Folded except one item: the `Circle` paragraph and "the last example below" (templates.md), the `eval fn` sentence (metaprogramming.md), the threads page's lead-in and Option C. Rejected: the `[...]?` of the 0.1 grammar mirrors the upstream guard production, pattern_matching.md:816 | templates.md, metaprogramming.md, threads_and_atomics.md; §2.4, §2.5, §2.6, §2.8 |
| DR2-6 | MINOR | Folded: the fork-only sentence names the nightly's missing `match` | assignment.md; §2.3 |
| DR2-7 | MINOR | Folded: each program's section's "This prints ..." values must equal its EXPECT-STDOUT lines; a changed EXPECT line and a changed sentence each fail on a scratch tree | check_samples.py; §2.12 item 2 |
| DR2-8 | MINOR | Folded by extending the rule rather than recording gaps: clause (c) also takes TBD, list-item and HTML-comment markers, and a new clause (d) hits an empty section with no subsection; no new hit on this branch, trunk or any held head | check_samples.py; D-DD-2, §2.12 item 5, stub line 6 |
| DR2-9 | MINOR | Folded: P05, P11 and P13 carry a "Why this bullet" header paragraph | three programs; §2.11 |
| DR2-10 | MINOR | Folded: "its allowlist and qualified list do not name", applied to the stub and to §2.11 identically, so no deviation from §2.11 remains; the forward-looking wording goes to commit 4/4's landed notes | stub line 6; §2.11 |
| DR2-11 | MINOR | Folded into §5 and §8.7: row 91's discharge text replaces the whole cell and carries the Not-run list; the header follows the precedent shape; the `TODO` counts are lines, measured at the fold and re-measured at the discharge | §5, §8.7 |
| DR2-12 | MINOR | Folded into §8.5 and §8.8: the stranded-branch row of fork/ORCHESTRATION.md and W-044's notes are amended at the discharge | §8.5, §8.8 |
| DR-FX-1 (fixer) | — | Added: the `Circle` diagnostic on templates.md had no fixture and no §4.2 row; quote fixture X05 pins it | X05; §2.4, §2.12, §4.1, §4.2 |

**For commit 4/4** (findings deliberately not fixed here, or fixed in the plan
for the discharge to carry out):

-   DR1-12: check leads issue 6830 online; if it is open, append to the
    interop README's inline section "Where `import Cpp inline` may appear is
    open question-for-leads issue 6830." and record the check in §8.10; if it
    is closed, state its answer instead.
-   DR1-10's optional sample comment: declined, the paragraph after P01
    states the divergence.
-   DR2-5's grammar item: rejected (pattern_matching.md:816).
-   DR2-4's "pending PR": not adopted; "held PR" is defined on the README
    note and drops at state L.
-   DR1-15 / DR2-10: the stub's SKIP text describes, from commit 1, what
    commits 2 and 3 land; record it in the landed notes.
-   DR2-1, DR2-11, DR2-12, DR1-4 and DR1-8: the discharge re-pins the
    ledger cites at its own commit, replaces row 91's whole cell, writes the
    header in the precedent shape with the `TODO` line counts, amends the
    stranded-branch row and W-044, files W-185 as design-needed, and adds
    PR-X to W-189's evidence.

**Verification** (each in the fold commit's message): prek to a fixpoint;
R31 counts before and after for every touched markdown file, with the only
list deltas templates.md dash 11 → 10 (DR1-7) and pattern_matching.md dash
121 → 122 (DR1-8), and this file's new H2; the checker with and without
`--toolchain` on the fork toolchain (19 program blocks, 39 fixtures, 3 W2
hits, 2 allowlisted, 1 qualified, 0 errors); `--self-test`; a full local
conformance run on the fork toolchain (147 PASS / 0 FAIL / 22 SKIP over 169
programs, bullets 48/56); and the nineteen programs on the nightly (16 PASS,
3 COMPILE-FAIL as labelled, the stub SKIP).
